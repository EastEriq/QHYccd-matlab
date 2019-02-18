% QHYccd class  
% Package: +obs/+?
% Description: A class for controlling the QHYccd cameras
% 
%     The class calls individual functions from the QHY SDK (v20190122_0)
%     linked in matlab with loadlibrary(). The SDK must be installed!
%
%     http://www.qhyccd.com/file/repository/latestSoftAndDirver/SDK/V4.0.12/LINUX_qhyccd_V20190122_0.tgz
%     (see also 
%         https://www.qhyccd.com/index.php?m=content&c=index&a=show&catid=127&id=163
%      and https://www.qhyccd.com/html/test_version/ for other SDKs)
%
% Tested : Matlab R2014b Ubuntu16, Matlab R2018b Ubuntu18
%     By : Enrico Segre                    Feb 2019
%    URL : https://github.com/EastEriq/QHYccd-matlab
% Example: % 
%
% Reliable: Like a chinese fire drill
%--------------------------------------------------------------------------

classdef QHYccd < handle
    
    %%

    properties (Dependent = true)
        % read/write properties, settings of the camera, for which
        %  hardware query is involved.
        %  We use getters/setters, even though instantiation
        %   order is not guaranteed. In particular, all parameters
        %   of the camera require that camhandle is obtained first.
        %  Values set here as default won't likely be passed to the camera
        %   when the object is created
        expTime = 2;
        gain = 0;
        offset = 0;
        bitDepth= 16;
        temperature = NaN;

        % these two don't have getters yet, no SDK function,
        %  could perhaps use a hidden property to store the last set value
        color = false; % whether to acquire images as 3x8bit, with debayer
        binning = 1;
    end
    
    properties
        % class properties affecting the behavior of methods, default
        %   values
        sequence_frames = 1;
        verbose = false; % true prints out debug information
    end
    
    properties (GetAccess = public, SetAccess = private)
        % Read only fields, results of the methods
        Success  = false;   % true if method worked ok
        progressive_frame = 0; % image of a sequence already available
        id  = ''; % literal camera id; cannot be set, it might be useful to
                  % open a specific camera, scanning all the names
        physical_size=struct('chipw',[],'chiph',[],'pixelw',[],'pixelh',[],...
                             'nx',[],'ny',[]);
        effective_area=struct('x1Eff',[],'y1Eff',[],'sxEff',[],'syEff',[]);
        overscan_area=struct('x1Over',[],'y1Over',[],'sxOver',[],'syOver',[]);
    end
    
    properties (Constant = true)
        % it would be nice if there was a way to understand if the camera
        %  is connected via USB2 or USB3, to get the current image
        %  acquisition weight, and to compute the estimated transfer time,
        %  for timeouts
        timeout=2.8;
    end
        
    properties (Hidden = true)        
        camhandle   % handle to the camera talked to - no need for the external
                    % consumer to know it
        %pImg  % pointer to the image buffer (can we gain anything in going
              %  to a double buffer model?)
    end
    
    
    %% Connecting and disconnecting with the library could be static methods?
    %    As for delete(), not
    methods
        
        % Constructor
        function QC=QHYccd(camera)
            % Load the library if needed (this is global?)           
            if ~libisloaded('libqhyccd')
                loadlibrary('libqhyccd','headers/qhyccd_matlab.h',...
                    'includepath','headers');
            end

            % this can be called harmlessly multiple times?
            InitQHYCCDResource;
            
            % the constructor tries also to open the camera
            if exist('camera','var')
                open(QC,camera);
            else
                open(QC);
            end
        end
        
        % Destructor
        function delete(QC)
            
            % make sure we close the communication, if not done already
            close(QC); % ignore result, may be closed already
            
            % clear QC.pImg
            
            % but:
            % don't release the SDK, other QC objects may be using it
            % ReleaseQHYCCDResource
            
            % nor unload the library
            % unloadlibrary('libqhyccd')
        end
        
    end
    
    
    %% Open and close the communication with the camera
    methods
        function open(QC,cameranum)
            
            num=ScanQHYCCD;
            if QC.verbose
                fprintf('%d QHY cameras found\n',num);
            end
            
            if ~exist('cameranum','var')
                cameranum=num; % and thus open the last camera
                                 % (TODO, if possible, the first not
                                 %  already open)
            end
            [~,QC.id]=GetQHYCCDId(min(cameranum,num)-1);
            
            QC.camhandle=OpenQHYCCD(QC.id);
            if QC.verbose
                fprintf('Opened camera "%s"\n',QC.id);
            end
           
            InitQHYCCD(QC.camhandle);
            
            [ret1,QC.physical_size.chipw,QC.physical_size.chiph,...
                QC.physical_size.nx,QC.physical_size.ny,...
                QC.physical_size.pixelw,QC.physical_size.pixelh,...
                         bp_supported]=GetQHYCCDChipInfo(QC.camhandle);
            
            [ret2,QC.effective_area.x1Eff,QC.effective_area.y1Eff,...
                QC.effective_area.sxEff,QC.effective_area.syEff]=...
                         GetQHYCCDEffectiveArea(QC.camhandle);
            
            [ret3,QC.overscan_area.x1Over,QC.overscan_area.y1Over,...
                QC.overscan_area.sxOver,QC.overscan_area.syOver]=...
                              GetQHYCCDOverScanArea(QC.camhandle);

            ret4=IsQHYCCDControlAvailable(QC.camhandle, qhyccdControl.CAM_COLOR);
            colorAvailable=(ret4>0 & ret4<5);

            if QC.verbose
                fprintf('%.3fx%.3fmm chip, %dx%d %.2fx%.2fµm pixels, %dbp\n',...
                    QC.physical_size.chipw,QC.physical_size.chiph,...
                    QC.physical_size.nx,QC.physical_size.ny,...
                    QC.physical_size.pixelw,QC.physical_size.pixelh,...
                     bp_supported)
                fprintf(' effective chip area: (%d,%d)+(%d,%d)\n',...
                    QC.effective_area.x1Eff,QC.effective_area.y1Eff,...
                    QC.effective_area.sxEff,QC.effective_area.syEff);
                fprintf(' overscan area: (%d,%d)+(%d,%d)\n',...
                    QC.overscan_area.x1Over,QC.overscan_area.y1Over,...
                    QC.overscan_area.sxOver,QC.overscan_area.syOver);
                if colorAvailable, fprintf(' Color camera\n'); end
            end
            
            QC.Success = (ret1==0 & ret2==0 & ret3==0);
                        
            % put here also some plausible parameter settings which are
            %  not likely to be changed
            SetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_USBTRAFFIC,30);
            SetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_OFFSET,0);
            
            % ROI -- TODO
            QC.color=false;
            
            if QC.color
                SetQHYCCDResolution(QC.camhandle,0,0,...
                    QC.physical_size.nx,QC.physical_size.ny);
            else
                % this is problematic in color mode
                SetQHYCCDParam(QC.camhandle,qhyccdControl.CAM_IGNOREOVERSCAN_INTERFACE,1);
                SetQHYCCDResolution(QC.camhandle,...
                    QC.effective_area.x1Eff,QC.effective_area.y1Eff,...
                    QC.effective_area.sxEff,QC.effective_area.syEff);
            end
            
        end
        
        function close(QC)
 
            % don't try co lose an invalid camhandle, it would crash matlab
            if ~isempty(QC.camhandle)
                % check this status, which may fail
                QC.Success=(CloseQHYCCD(QC.camhandle)==0);
            end
            % null the handle so that other methods can't talk anymore to it
            QC.camhandle=[];
            
        end

        %% camera parameters setters/getters 
        
        function set.temperature(QC,Temp)
            % set the target sensor temperature in Celsius
            QHYccd.Success=ControlQHYCCDTemp(QC.camhandle,Temp);
        end
        
        function Temp=get.temperature(QC)
            Temp=GetQHYCCDParam(QC.camhandle,qhyccdControl.CAM_CHIPTEMPERATURESENSOR_INTERFACE);
            % I guess that error is Temp=FFFFFFFF, check
            QC.Success = (Temp>-100 & Temp<100);
        end
        
        function set.expTime(QC,ExpTime)
            % ExpTime in seconds
            if QC.verbose, fprintf('setting exposure time = %f\n',ExpTime); end
            QC.Success=...
                (SetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_EXPOSURE,ExpTime*1e6)==0);            
        end
        
        function ExpTime=get.expTime(QC)
            % ExpTime in seconds
            ExpTime=GetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_EXPOSURE)/1e6;
            if QC.verbose, fprintf('read exposure time = %f\n',ExpTime); end
            QC.Success=(ExpTime~=1e6*hex2dec('FFFFFFFF'));            
        end
        
        function set.gain(QC,Gain)
            QC.Success=(SetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_GAIN,Gain)==0);          
        end
        
        function Gain=get.gain(QC)
            Gain=GetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_GAIN);
            % check whether err=double(FFFFFFFF)...
            QC.Success=(Gain>0 & Gain<2e6);
        end
        
        function set.offset(QC,offset)
            QC.Success=(SetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_OFFSET,offset)==0);          
        end
        
        function offset=get.offset(QC)
            offset=GetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_OFFSET);
            % check whether err=double(FFFFFFFF)...
            QC.Success=(offset>0 & offset<2e6);
        end
        
        function set.bitDepth(QC,BitDepth)
            % default has to be 16bit
            SetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_TRANSFERBIT,BitDepth);
            QC.Success=(SetQHYCCDBitsMode(QC.camhandle,BitDepth)==0);
        end

        function bitDepth=get.bitDepth(QC)
            bitDepth=GetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_TRANSFERBIT);
            % check whether err=double(FFFFFFFF)...
            QC.Success=(bitDepth==8 | bitDepth==16);
        end

        
        function set.binning(QC,binning)
            % default is 1x1
            % for the QHY367, 1x1 and 2x2 seem to work; NxN with N>2 gives error,
            %  NxM gives no error, but all are uneffective and fall back to 1x1
            if SetQHYCCDBinMode(QC.camhandle,binning,binning)==0
                QC.Success=true;
            else
                QC.Success=false;
            end
        end
        
        % The SDK doesn't provide a function for getting the current
        %  binning, go figure
                  
        function set.color(QC,ColorMode)
            % default has to be bw
             QC.Success=(SetQHYCCDDebayerOnOff(QC.camhandle,ColorMode)==0);
             if ColorMode
                 QC.bitDepth=8; % segfault in buffer -> image otherwise
             end
        end
        
        function color=get.color(QC)
            color=false; % placeholder
        end
        
        %% main image taking function
        
        function ImageArray=take_sequence_blocking(QC)
            % take N live images. N=1 is admitted, and actually
            %  more reliable that setting the camera in single shot mode
            % The camera workings require that for Nimages>1,
            %   t_exp > t_readout. The latter is about 2sec on USB2, 0.2sec on USB3
            % ImageArray cell of images of size [X, Y]
            
            imlength=GetQHYCCDMemLength(QC.camhandle);
            
            pImg=libpointer('uint8Ptr',zeros(imlength,1,'uint8'));
            
            texp=QC.expTime; % local variable; dont call SDK every time!
            
            SetQHYCCDStreamMode(QC.camhandle,1);

            BeginQHYCCDLive(QC.camhandle);
           
            % allocate the output array. The problem is that we don't
            %  really know whether w and h returned by GetQHYCCDLiveFrame()
            %  correspond to the sensor resolution, w/o overscan or what
            ImageArray=cell(QC.sequence_frames,1);
            
            QC.progressive_frame=0;
            while QC.progressive_frame<QC.sequence_frames
                ret=-1; i=0; tic;
                while ret ~=0 && toc<(texp+QC.timeout)% add here a timeout
                    % problem: both "image not ready" and "framebuffer overrun"
                    %  return FFFFFFFF. Like this, the while exits only
                    %  only if t_exp>t_transfer and no other error happens
                    [ret,w,h,bp,channels]=...
                        GetQHYCCDLiveFrame(QC.camhandle,...
                            QC.physical_size.nx,QC.physical_size.ny,...
                            QC.bitDepth,pImg);
                    % (what sizes exactly should be passed for a ROI, instead?)
                    if ret~=0, pause(0.1); end
                    i=i+1;
                    if QC.verbose
                        fprintf(' check live image %d, attempt %d, code %s\n',...
                                 QC.progressive_frame+1,i,dec2hex(ret));
                    end
                end
                QC.progressive_frame=QC.progressive_frame+1;
                
                if ret==0
                    ImageArray{QC.progressive_frame}=...
                        QC.unpackImgBuffer(pImg,w,h,channels,bp);
                else
                    ImageArray{QC.progressive_frame}=[];
                end

            end
                       
            StopQHYCCDLive(QC.camhandle);
            
            clear pImg
            
            QC.Success=(QC.progressive_frame==QC.sequence_frames & ret==0);

        end
            
    end
    
    %% Private methods
    methods (Access = private, Static)
        function img=unpackImgBuffer(pImg,w,h,channels,bp)
            % trying to make this work for color/bw, 8/16bit, binning
            
            % IIUC https://www.qhyccd.com/bbs/index.php?topic=6038.msg31725#msg31725
            %  color images should always be 3x8bit
            if channels==3
                img=reshape([pImg.Value(3:3:3*w*h);...
                             pImg.Value(2:3:3*w*h);...
                             pImg.Value(1:3:3*w*h)],w,h,3);
            else
                % for 2D we could perhaps just reshape the pointer
                if bp==8
                    img=reshape(pImg.Value(1:w*h),w,h);
                else
                    img=reshape(uint16(pImg.Value(1:2:2*w*h))+...
                        bitshift(uint16(pImg.Value(2:2:2*w*h)),8),w,h);
                end
            end
        end
    end
    
    
end

            
