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
        % read/write properties, settings of the camera, 
        %  Can we use getters/setters? Probably not because instantiation
        %   order is not guaranteed. In particular, all parameters
        %   of the camera require that camhandle is obtained first
        binning = 1;
        expTime = 2;
        gain = 0;
        offset = 0;
        color = false; % whether to acquire images as 3x8bit, with debayer
        bitDepth= 16;
        temperature = NaN;
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
        chipw;
        chiph;
        pixelw;
        pixelh;
        nx; ny; x1Eff; y1Eff; sxEff; syEff; x1Over; y1Over; sxOver; syOver;
    end
        
    properties (Hidden = true)        
        camhandle   % handle to the camera talked to - no need for the external
                    % consumer to know it
    end
    
    
    %% Connecting and disconnecting with the library can be static methods?
    methods (Static)
        
        % Constructor
        function QC=QHYccd
            % Load the library if needed (this is global?)           
            if ~libisloaded('libqhyccd')
                loadlibrary('libqhyccd','headers/qhyccd_matlab.h',...
                    'includepath','headers');
            end

            % this can be called harmlessly multiple times?
            InitQHYCCDResource;
        end
        
        % Destructor
        function delete(QC)
            
            % make sure we close the communication, if not done already
            close(QC); % ignore result, may be closed already
            
            % but:
            % don't release the SDK, other QC objects may be using it
            % ReleaseQHYCCDResource
            
            % nor unload the library
            % unloadlibrary('libqhyccd')
        end
        
    end
    
    
    
    
    %% Open and close the communication with the camera
    methods
        function Success=open(QHYccd)
            % Load the library if needed, open link to the camera,
            %  initialize the camera and store its capabilities
            %  (e.g. resolution, bit depth)
                       
            if ~libisloaded('libqhyccd')
                loadlibrary('libqhyccd','headers/qhyccd_matlab.h',...
                    'includepath','headers');
            end
        
            InitQHYCCDResource;
            
            num=ScanQHYCCD;
            % open the last camera of the list (TODO, selectable by input
            %   argument)
            [~,QHYccd.id]=GetQHYCCDId(num-1);
            
            QHYccd.camhandle=OpenQHYCCD(QHYccd.id);
            
            InitQHYCCD(QHYccd.camhandle);
            
            [ret,QHYccd.chipw,QHYccd.chiph,QHYccd.nx,QHYccd.ny,...
                QHYccd.pixelw,QHYccd.pixelh,bp_supported]=GetQHYCCDChipInfo(QHYccd.camhandle);
            
            [ret,QHYccd.x1Eff,QHYccd.y1Eff,QHYccd.sxEff,QHYccd.syEff]=...
                         GetQHYCCDEffectiveArea(QHYccd.camhandle);
            
            [ret,QHYccd.x1Over,QHYccd.y1Over,QHYccd.sxOver,QHYccd.syOver]=...
                              GetQHYCCDOverScanArea(QHYccd.camhandle);

            ret=IsQHYCCDControlAvailable(QHYccd.camhandle, qhyccdControl.CAM_COLOR);
            colorAvailable=(ret>0 & ret<5);

            if QHYccd.verbose
                fprintf('%.3fx%.3fmm chip, %dx%d %.2fx%.2fµm pixels, %dbp\n',...
                    QHYccd.chipw,QHYccd.chiph,QHYccd.nx,QHYccd.ny,...
                    QHYccd.pixelw,QHYccd.pixelh,bp_supported)
                fprintf(' effective chip area: (%d,%d)+(%d,%d)\n',...
                    QHYccd.x1Eff,QHYccd.y1Eff,QHYccd.sxEff,QHYccd.syEff);
                fprintf(' overscan area: (%d,%d)+(%d,%d)\n',...
                    QHYccd.x1Over,QHYccd.y1Over,QHYccd.sxOver,QHYccd.syOver);
                if colorAvailable, fprintf(' Color camera\n'); end
            end
            
            Success = (ret==0);
                        
            % put here also some plausible parameter settings which are
            %  not likely to be changed
            SetQHYCCDParam(QHYccd.camhandle,qhyccdControl.CONTROL_USBTRAFFIC,30);
            SetQHYCCDParam(QHYccd.camhandle,qhyccdControl.CONTROL_OFFSET,0);
            
            % ROI -- TODO
            QHYccd.color=false;
            
            if QHYccd.color
                SetQHYCCDResolution(QHYccd.camhandle,0,0,QHYccd.nx,QHYccd.ny);
            else
                % this is problematic in color mode
                SetQHYCCDParam(QHYccd.camhandle,qhyccdControl.CAM_IGNOREOVERSCAN_INTERFACE,1);
                SetQHYCCDResolution(QHYccd.camhandle,...
                    QHYccd.x1Eff,QHYccd.y1Eff,QHYccd.sxEff,QHYccd.syEff);
            end
            
        end
        
        function Success=close(QC)

            % check this status, which may fail
            Success=(CloseQHYCCD(QC.camhandle)==0);            
            
        end

        %% camera parameters setters/getters 
        
        function set.temperature(QC,Temp)
            % set the target sensor temperature in Celsius
            QHYccd.Success=ControlQHYCCDTemp(QC.camhandle,Temp);
        end
        
        function Temp=get.temperature(QHYccd)
            Temp=GetQHYCCDParam(QHYccd.camhandle,qhyccdControl.CAM_CHIPTEMPERATURESENSOR_INTERFACE);
            % I guess that error is Temp=FFFFFFFF, check
            QHYccd.Success = (Temp>-100 & Temp<100);
        end
        
        function set.expTime(QHYccd,ExpTime)
            % ExpTime in seconds
            QHYccd.Success=...
                (SetQHYCCDParam(QHYccd.camhandle,qhyccdControl.CONTROL_EXPOSURE,ExpTime*1e6)==0);            
        end
        
        function set.gain(QHYccd,Gain)
            QHYccd.Success=(SetQHYCCDParam(QHYccd.camhandle,qhyccdControl.CONTROL_GAIN,Gain)==0);          
        end
        
        function Gain=get.gain(QHYccd)
            Gain=GetQHYCCDParam(QHYccd.camhandle,qhyccdControl.CONTROL_GAIN);
            % check whether err=double(FFFFFFFF)...
            QHYccd.Success=(Gain<0 | Gain>2e6);
        end
        
        function set.binning(QHYccd,binning)
            % default is 1x1
            % for the QHY367, 1x1 and 2x2 seem to work; NxN with N>2 gives error,
            %  NxM gives no error, but all are uneffective and fall back to 1x1
            if SetQHYCCDBinMode(QHYccd.camhandle,binning,binning)==0
                QHYccd.Success=true;
            else
                QHYccd.Success=false;
            end
            
        end
        
        function set.bitDepth(QHYccd,BitDepth)
            % default has to be 16bit
            SetQHYCCDParam(QHYccd.camhandle,qhyccdControl.CONTROL_TRANSFERBIT,BitDepth);
            QHYccd.Success=(SetQHYCCDBitsMode(QHYccd.camhandle,BitDepth)==0);            
        end
        
        function set.color(QHYccd,ColorMode)
            % default has to be bw
             QHYccd.Success=(SetQHYCCDDebayerOnOff(QHYccd.camhandle,ColorMode)==0);           
        end
        
        %% main image taking function
        
        function [ImageArray,Success]=take_live(QHYccd,Nimages)
            % take N live images. N=1 is admitted, and actually
            %  more reliable that setting the camera in single shot mode
            % The camera workings require that for Nimages>1,
            %   t_exp > t_readout. The latter is about 2sec on USB2, 0.2sec on USB3
            % Nimages default is 10.
            % ImageArray of size [X, Y, N]
            
            BeginQHYCCDLive(QHYccd.camhandle);
            
            imlength=GetQHYCCDMemLength(QHYccd.camhandle);
            
            Pimg=libpointer('uint8Ptr',zeros(imlength,1,'uint8'));
            
            % allocate the output array. The problem is that we don't
            %  really know whether w and h returned by GetQHYCCDLiveFrame()
            %  correspond to the sensor resolution, w/o overscan or what
            if QHYccd.bitDepth==16
                ImageArray=zeros(QHYccd.nx,QHYccd.ny,Nimages,'uint16');
            else
                ImageArray=zeros(QHYccd.nx,QHYccd.ny,Nimages,'uint8');
            end
            
            j=0;
            while j<Nimages
                ret=-1; i=0;
                while ret ~=0 % add here a timeout
                    % problem: both "image not ready" and "framebuffer overrun"
                    %  return FFFFFFFF. Like this, the while exits only
                    %  only if t_exp>t_transfer and no other error happens
                    [Success,w,h,bp,channels]=...
                        GetQHYCCDLiveFrame(QHYccd.camhandle,w,h,bp,Pimg);
                    i=i+1;
                end
                j=j+1;
                
                ImageArray(:,:,j)=unpackImgBuffer(Pimg,w,h,QHYccd.color,bp,xb,yb);
                
            end
            
            StopQHYCCDLive(QHYccd.camhandle);

        end
            
    end
    
    %% Private methods
    methods (Access = private)
        function img=unpackImgBuffer(Pimg,w,h,color,bp)
            % trying to make this work for color/bw, 8/16bit, binning
            
            % IIUC https://www.qhyccd.com/bbs/index.php?topic=6038.msg31725#msg31725
            %  color images should always be 3x8bit
            if color
                img=reshape([Pimg.Value(3:3:3*w*h);...
                                Pimg.Value(2:3:3*w*h);...
                                Pimg.Value(1:3:3*w*h)],w,h,3);
            else
                % for 2D we could perhaps just reshape the pointer
                if bp==8
                    img=reshape(Pimg.Value(1:w*h),w,h);
                else
                    img=reshape(uint16(Pimg.Value(1:2:2*w*h))+...
                        bitshift(uint16(Pimg.Value(2:2:2*w*h)),8),w,h);
                end
            end
        end
    end
    
    
end

            
