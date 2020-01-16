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
        readMode=0;        

        % these don't have getters yet, no SDK function,
        %  could perhaps use a hidden property to store the last set value
        color = false; % whether to acquire images as 3x8bit, with debayer
        binning = 1;
        ROI =[0,0,0,0];
    end
    
    properties
        % class properties affecting the behavior of methods, default
        %   values
        
        % for image sequences:
        sequence_frames = 1; % number of live images to acquire in a sequence 
        save_path = ''; % path where to save images if required
        grabbing_GUI = true; % show a GUI for e.g. aborting a sequence acquisition
        save_images = false; % save images to files as they are taken
        memory_images = true; % store all the images in a structure array
       % it would be nice if there was a way to understand whether the camera
        %  is connected via USB2 or USB3, to get the current image
        %  acquisition weight, and to compute the estimated transfer time,
        %  for timeouts
        timeout=2.8;

        
        verbose = ~false; % if true, printout of debug information
    end
    
    properties (GetAccess = public, SetAccess = private)
        % Read only fields, results of the methods
        success  = false;   % true if method worked ok
        progressive_frame = 0; % image of a sequence already available
        physical_size=struct('chipw',[],'chiph',[],'pixelw',[],'pixelh',[],...
                             'nx',[],'ny',[]);
        effective_area=struct('x1Eff',[],'y1Eff',[],'sxEff',[],'syEff',[]);
        overscan_area=struct('x1Over',[],'y1Over',[],'sxOver',[],'syOver',[]);
        readModesList=struct('name',[],'resx',[],'resy',[]);
       
        % readonly replies from the camera
        id  = ''; % literal camera id; cannot be set, it might be useful to
                  % open a specific camera, scanning all the names
        expTimeLeft = NaN;
    end
    
    properties (Constant = true)        
        % this is sort of a typedef
        ImageStructPrototype = struct('img',[],'datetime_readout',[],'exp',[],...
                                      'gain',[],'offset',[]);
    end
        
    properties (Hidden = true)        
        camhandle   % handle to the camera talked to - no need for the external
                    % consumer to know it
        pImg  % pointer to the image buffer (can we gain anything in going
              %  to a double buffer model?)
              % Shall we allocate it only once on open(QC), or, like now,
              %  every time we start an acquisition?
        GUI % auxiliary GUI, e.g. for aborting a sequence acquisition. A hidden
            %  property so that it can be passed along functions
    end
        
    
    %% class Constructor and Destructor
    methods
        % (Connecting and disconnecting with the library could be static methods?
        %    As for delete(), it cannot)
     
        % Constructor
        function QC=QHYccd(cameranum)
            %  cameranum: int, number of the camera to open (as enumerated by the SDK)
            %     May be omitted. In that case the last camera is referred to

            % Load the library if needed (this is global?)           
            if ~libisloaded('libqhyccd')
                classpath=fileparts(mfilename('fullpath'));
                loadlibrary('libqhyccd',...
                     fullfile(classpath,'headers/qhyccd_matlab.h'));
            end

            % this can be called harmlessly multiple times?
            InitQHYCCDResource;
            
            % the constructor tries also to open the camera
            if exist('cameranum','var')
                open_camera(QC,cameranum);
            else
                open_camera(QC);
            end
        end
        
        % Destructor
        function delete(QC)
            
            % it shouldn't harm to try to stop the acquisition for good,
            %  even if already stopped - and delete the image pointer QC.pImg
            stop_sequence_take(QC)
            
            % make sure we close the communication, if not done already
            if (close_camera(QC)==0)
                if QC.verbose, fprintf('Succesfully closed camera\n'), end
            else
                if QC.verbose, fprintf('Failed to close camera\n'), end
            end
            
            % clear QC.pImg
            
            % but:
            % don't release the SDK, other QC objects may be using it
            % ReleaseQHYCCDResource
            
            % nor unload the library,
            %  which at least with libqhyccd 6.0.5 even crashes Matlab
            %  with multiple errors traced into libpthread.so
            % unloadlibrary('libqhyccd')
        end
        
    end
    
    
    %% Open and close the communication with the camera
    methods

        function open_camera(QC,cameranum)
            % Open the connection with a specific camera, and
            %  read from it some basic information like color capability,
            %  physical dimensions, etc.
            %  cameranum: int, number of the camera to open (as enumerated by the SDK)
            %     May be omitted. In that case the last camera is referred to
             
            num=ScanQHYCCD;
            if QC.verbose
                fprintf('%d QHY cameras found\n',num);
            end
            
            if ~exist('cameranum','var')
                cameranum=num; % and thus open the last camera
                                 % (TODO, if possible, the first not
                                 %  already open)
            end
            [ret,QC.id]=GetQHYCCDId(max(min(cameranum,num)-1,0));
            
            if ret, return; end
            
            QC.camhandle=OpenQHYCCD(QC.id);
            if QC.verbose
                fprintf('Opened camera "%s"\n',QC.id);
            end
           
            InitQHYCCD(QC.camhandle);
            
            % query the camera and populate the QC structures with some
            %  characteristic values
            
            [ret1,QC.physical_size.chipw,QC.physical_size.chiph,...
                QC.physical_size.nx,QC.physical_size.ny,...
                QC.physical_size.pixelw,QC.physical_size.pixelh,...
                         bp_supported]=GetQHYCCDChipInfo(QC.camhandle);
            
            [ret2,QC.effective_area.x1Eff,QC.effective_area.y1Eff,...
                QC.effective_area.sxEff,QC.effective_area.syEff]=...
                         GetQHYCCDEffectiveArea(QC.camhandle);
            
            % warning: this returns strange numbers, which at some point
            %  I've also seen to change (maybe depending on other calls'
            %  order?)
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
                fprintf(' effective chip area: (%d,%d)+(%dx%d)\n',...
                    QC.effective_area.x1Eff,QC.effective_area.y1Eff,...
                    QC.effective_area.sxEff,QC.effective_area.syEff);
                fprintf(' overscan area: (%d,%d)+(%dx%d)\n',...
                    QC.overscan_area.x1Over,QC.overscan_area.y1Over,...
                    QC.overscan_area.sxOver,QC.overscan_area.syOver);
                if colorAvailable, fprintf(' Color camera\n'); end
            end
            
            [ret5,Nmodes]=GetQHYCCDNumberOfReadModes(QC.camhandle);
            if QC.verbose, fprintf('Read modes:\n'); end
            for mode=1:Nmodes
                [~,QC.readModesList(mode).name]=...
                    GetQHYCCDReadModeName(QC.camhandle,mode-1);
                [~,QC.readModesList(mode).resx,QC.readModesList(mode).resy]=...
                    GetQHYCCDReadModeResolution(QC.camhandle,mode-1);
                if QC.verbose
                    fprintf('(%d) %s: %dx%d\n',mode-1,QC.readModesList(mode).name,...
                        QC.readModesList(mode).resx,QC.readModesList(mode).resy);
                end
            end
            
            QC.success = (ret1==0 & ret2==0 & ret3==0);
                        
            % put here also some plausible parameter settings which are
            %  not likely to be changed
            
            QC.offset=0;
            colormode=false; % (local variable because no getter)
            QC.color=colormode;

            % USBtraffic value is said to affect glow. 30 is the value
            %   normally found in demos, it may need to be changed, also
            %   depending on USB2/3
            % The SDK manual says:
            %  Used to set camera traffic,the bandwidth setting is only valid
            %  for continuous mode, and the larger the bandwidth setting, the
            %  lower the frame rate, which can reduce the load of the
            %  computer.
            SetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_USBTRAFFIC,3);

            % from https://www.qhyccd.com/bbs/index.php?topic=6861
            %  this is said to affect speed, annd accepting 0,1,2
            % The SDK manual says:
            %  USB transfer speed,but part of cameras not support
            %  this function.
            SetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_SPEED,2);
            
            % set full area as ROI (?) -- wishful
            if colormode
                QC.ROI=[0,0,QC.physical_size.nx,QC.physical_size.ny];
            else
                % this is problematic in color mode
                SetQHYCCDParam(QC.camhandle,qhyccdControl.CAM_IGNOREOVERSCAN_INTERFACE,1);
                QC.ROI=[QC.effective_area.x1Eff,QC.effective_area.y1Eff,...
                        QC.effective_area.sxEff,QC.effective_area.syEff];
            end
            
        end
        
        function ret=close_camera(QC)
            % Close the connection with the camera registered in the
            %  current camera object
 
            % don't try co lose an invalid camhandle, it would crash matlab
            if ~isempty(QC.camhandle)
                % check this status, which may fail
                ret=CloseQHYCCD(QC.camhandle);
                QC.success=(ret==0);
            else
                ret=1;
            end
            % null the handle so that other methods can't talk anymore to it
            QC.camhandle=[];
            
        end
    end

    %% camera parameters setters/getters
    methods
        
        function set.temperature(QC,Temp)
            % set the target sensor temperature in Celsius
            QC.success=ControlQHYCCDTemp(QC.camhandle,Temp);
        end
        
        function Temp=get.temperature(QC)
            Temp=GetQHYCCDParam(QC.camhandle,qhyccdControl.CAM_CHIPTEMPERATURESENSOR_INTERFACE);
            % I guess that error is Temp=FFFFFFFF, check
            QC.success = (Temp>-100 & Temp<100);
        end
        
        function set.expTime(QC,ExpTime)
            % ExpTime in seconds
            if QC.verbose, fprintf('setting exposure time to %f sec.\n',ExpTime); end
            QC.success=...
                (SetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_EXPOSURE,ExpTime*1e6)==0);            
        end
        
        function ExpTime=get.expTime(QC)
            % ExpTime in seconds
            ExpTime=GetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_EXPOSURE)/1e6;
            % if QC.verbose, fprintf('Exposure time is %f sec.\n',ExpTime); end
            QC.success=(ExpTime~=1e6*hex2dec('FFFFFFFF'));            
        end
        
        function ExpTimeLeft=get.expTimeLeft(QC)
            % ExpTime in seconds? (with sdk 4.0 it was in usec?)
            ExpTimeLeft=GetQHYCCDExposureRemaining(QC.camhandle)/1e6;
            % if QC.verbose, fprintf('Exposure time left is %f sec.\n',ExpTimeLeft); end
            QC.success=(ExpTimeLeft~=1e6*hex2dec('FFFFFFFF'));            
        end
        
        function set.gain(QC,Gain)
            % for an explanation of gain & offset vs. dynamics, see
            %  https://www.qhyccd.com/bbs/index.php?topic=6281.msg32546#msg32546
            %  https://www.qhyccd.com/bbs/index.php?topic=6309.msg32704#msg32704
            QC.success=(SetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_GAIN,Gain)==0);          
        end
        
        function Gain=get.gain(QC)
            Gain=GetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_GAIN);
            % check whether err=double(FFFFFFFF)...
            QC.success=(Gain>0 & Gain<2e6);
        end
        
        function set.offset(QC,offset)
            QC.success=(SetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_OFFSET,offset)==0);          
        end
        
        function offset=get.offset(QC)
            % Offset seems to be a sort of bias, black level
            offset=GetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_OFFSET);
            % check whether err=double(FFFFFFFF)...
            QC.success=(offset>0 & offset<2e6);
        end
        
        function set.bitDepth(QC,BitDepth)
            % BitDepth: 8 or 16 (bit). My understanding is that this is in
            %  first place a communication setting, which however implies
            %  the scaling of the raw ADC readout. IIUC, e.g. a 14bit ADC
            %  readout is upshifted to full 16 bit range in 16bit mode.
            % Constrain BitDepth to 8|16, the functions wouldn't give any
            %  error anyway for different values.
            BitDepth=max(min(round(BitDepth/8)*8,16),8);
            if QC.verbose; fprintf('Setting depth to %dbit\n',BitDepth); end
            SetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_TRANSFERBIT,BitDepth);
            % There is also a second SDK function for setting this. I don't
            %  know if they are *really* equivalent. In doubt call both.
            QC.success=(SetQHYCCDBitsMode(QC.camhandle,BitDepth)==0);

            % ensure that color is set off if 16 bit (otherwise segfault!)
            if BitDepth==16; QC.color=false; end
        end

        function bitDepth=get.bitDepth(QC)
            bitDepth=GetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_TRANSFERBIT);
            % check whether err=double(FFFFFFFF)...
            QC.success=(bitDepth==8 | bitDepth==16);
        end
        
        function set.readMode(QC,readMode)
            QC.success=(SetQHYCCDReadMode(QC.camhandle,readMode)==0);
            if QC.verbose && ~ QC.success
                fprintf('Invalid read mode! Legal is %d:%d\n',0,...
                    numel(QC.readModesList)-1);
            end
        end
        
        function currentReadMode=get.readMode(QC)
            [ret,currentReadMode]=GetQHYCCDReadMode(QC.camhandle);
            QC.success= ret==0 & (currentReadMode>0 & currentReadMode<2e6);
        end
        
        function set.binning(QC,binning)
            % default is 1x1
            % for the QHY367, 1x1 and 2x2 seem to work; NxN with N>2 gives error,
            %  NxM gives no error, but all are uneffective and fall back to 1x1
            if SetQHYCCDBinMode(QC.camhandle,binning,binning)==0
                QC.success=true;
            else
                QC.success=false;
            end
        end
        
        % The SDK doesn't provide a function for getting the current
        %  binning, go figure
                  
        function set.color(QC,ColorMode)
            % default has to be bw
             QC.success=(SetQHYCCDDebayerOnOff(QC.camhandle,ColorMode)==0);
             if ColorMode
                 QC.bitDepth=8; % segfault in buffer -> image otherwise
             end
        end
                
        % ROI - assuming that this is what the SDK calls "Resolution"
        function set.ROI(QC,resolution)
            % resolution is [x1,y1,sizex,sizey]
            %  I highly suspect that this setting is very problematic
            %   especially in color mode.
            %  Safe values should be [0,0,physical_size.nx,physical_size.ny]
            x1=resolution(1); y1=resolution(2); sx=resolution(3); sy=resolution(4);
            
            % try to clip unreasonable values
            x1=max(min(x1,QC.physical_size.nx-1),0);
            y1=max(min(y1,QC.physical_size.ny-1),0);
            sx=max(min(sx,QC.physical_size.nx-x1),1);
            sy=max(min(sy,QC.physical_size.ny-y1),1);
            
            QC.success=(SetQHYCCDResolution(QC.camhandle,x1,y1,sx,sy)==0);
            if QC.verbose
                if QC.success
                    fprintf('ROI successfully set to (%d,%d)+(%dx%d)\n',x1,y1,sx,sy);
                else
                    fprintf('set ROI to (%d,%d)+(%dx%d) FAILED\n',x1,y1,sx,sy);
                end
            end
        end
        
        % there is no SDK reader of the "resolution", go figure
        
    end
    
    %% methods applying to a specific camera once communication with it is open
    methods
        
        function ImageStruct=take_single_exposure(QC)
        % Take one image in single exposure mode, monolithic
        %  If called after Live mode, it returns often a messed up image.
        %  It seems that color mode and bit depth need to be set again, but
        %   I don't always understand in which order

            start_single_exposure(QC)
        
            ImageStruct=collect_single_exposure(QC);

        end
        
        function start_single_exposure(QC)
        % set up the scenes for taking a single exposure
            QC.progressive_frame=0;
            
            QC.allocate_image_buffer(QC)
            
            SetQHYCCDStreamMode(QC.camhandle,0);
            
            ret=ExpQHYCCDSingleFrame(QC.camhandle);
            if ret==hex2dec('2001') % "QHYCCD_READ_DIRECTLY". No idea but
                                    %   it is like that in the demoes
                pause(0.1)
            end
            
            QC.success=(ret==0);

        end
        
        function ImageStruct=collect_single_exposure(QC)
        % collect the exposed frame
            
            [ret,w,h,bp,channels]=...
                GetQHYCCDSingleFrame(QC.camhandle,QC.pImg);

            if ret==0
                t_readout=now;
                QC.progressive_frame=1;
            else
                t_readout=[];
            end
            
            ImageStruct=struct(QC.ImageStructPrototype);
            ImageStruct.datetime_readout=t_readout;
            ImageStruct.exp=QC.expTime;
            ImageStruct.gain=QC.gain;
            ImageStruct.offset=QC.offset;
            ImageStruct.img=QC.unpackImgBuffer(QC.pImg,w,h,channels,bp);

            % if write to a file
            if QC.save_images
                QC.writeImageFile(QC,ImageStruct)
            end
            
            QC.deallocate_image_buffer(QC)
            
            QC.success=(ret==0);

        end
        
        % main image taking function (live mode, via FIFO (?) framebuffer)
        function ImageArray=take_sequence_blocking(QC)
            % take N live images. N=1 is admitted, and actually
            %  more reliable that setting the camera in single shot mode
            % The camera workings require that for Nimages>1,
            %   t_exp > t_readout. The latter is about 2sec on USB2, 0.2sec on USB3
             
            % cell structure for the array of images
            ImageArray=struct(QC.ImageStructPrototype);

            start_sequence_take(QC)

            aborting=false; ret=-1;
            while QC.progressive_frame<QC.sequence_frames && ~aborting

                [ImageArray,ret,aborting]=poll_live_image(QC,ImageArray);
 
            end
            
            stop_sequence_take(QC)
            
            QC.success=(QC.progressive_frame==QC.sequence_frames & ret==0);

        end
        
        % Setting the scenes for taking a sequence of images
        function start_sequence_take(QC)
            
            QC.allocate_image_buffer(QC);
                                    
            if QC.grabbing_GUI
                 QC.GUI.fn=figure('Position',[200,200,240,60],'menubar','none',...
                     'name','QHY acquisition control','numberTitle','off');
                 QC.GUI.btn=uicontrol('Style','Togglebutton','Position',[20 20 180 30],...
                     'String','abort grabbing');
            end

            QC.progressive_frame=0;
            
            SetQHYCCDStreamMode(QC.camhandle,1);

            BeginQHYCCDLive(QC.camhandle);
           
         end
           
        % Cleaning up after taking a sequence of images
        function stop_sequence_take(QC)
                                   
            StopQHYCCDLive(QC.camhandle);

            % delete objects, release pImg, but check first that they
            %  exist. This to suppress warnings if this function is called twice,
            %  or when acquisition hasn't been started at all
            if QC.grabbing_GUI
                if isa(QC.GUI,'struct')
                     delete(QC.GUI.fn);
                end
            end
            
            QC.deallocate_image_buffer(QC)
            
        end
        
        
        % Polling for a single live image ready
        function [ImageArray,ret,aborting]=poll_live_image(QC,ImageArray)
        % (blocking), monolithic function filling ImageArray and eventually
        %  writing output files; in provision for being called periodically
        %  by a timer or a callback, if ever possible within the limitation
        %  of the framebuffer which must be read timely
        
            % contemplate the call without an initial ImageArray
            if ~exist('ImageArray','var')
                ImageArray=struct(QC.ImageStructPrototype);
            end
            
            % Create an additional scalar image structure. This is done so that
            %  the copy, eventually filled with image data, can be passed
            %  to the file saving function, while the data itself may not
            %  be stored in ImageArray, which is kept in memory.
            ImageStruct=struct(QC.ImageStructPrototype);

            texp=QC.expTime; % local variable; dont call SDK at every iteartion!
            
            ret=-1; i=0; aborting=false; tic;
            while ret ~=0 && toc<(texp+QC.timeout) && ~aborting
                if QC.grabbing_GUI, aborting=get(QC.GUI.btn,'Value'); end
                
                % problem: both "image not ready" and "framebuffer overrun"
                %  return FFFFFFFF. Like this, the while exits only
                %  only if t_exp>t_transfer and no other error happens
                [ret,w,h,bp,channels]=...
                    GetQHYCCDLiveFrame(QC.camhandle,QC.pImg);
                % I presume that, in case of binning or ROI, the transfer of
                %  much less than physical_size.nx*ny could be asked,
                %  but the SDK doesn't tell that to us a priori. Relying
                %  on values which have been attemped to be set (but
                %  maybe not accepted) is dangerous.
                if ret~=0
                    pause(0.1);
                    t_readout=NaN;
                else
                    t_readout=now;
                end
                i=i+1;
                if QC.verbose
                    fprintf([' check live image %d, exp. time left %f,'...
                             ' t elapsed %.3f sec., code %s\n'],...
                        QC.progressive_frame+1,QC.expTimeLeft,toc,dec2hex(ret));
                end
            end
            
            if ~aborting
                QC.progressive_frame=QC.progressive_frame+1;
            end
            
            ImageStruct.datetime_readout=t_readout;
            ImageStruct.exp=texp;
            ImageStruct.gain=QC.gain;
            ImageStruct.offset=QC.offset;
            ImageStruct.img=[];
            
            if nargin>1
                % grow ImageArray
                N=QC.progressive_frame;
            else
                % return a scalar ImageArray with the image polled
                N=1;
            end
            ImageArray(N)=ImageStruct;
                
            % try not to copy around too many buffers if not necessary
            if ret==0 && QC.save_images
                ImageStruct.img=QC.unpackImgBuffer(QC.pImg,w,h,channels,bp);
            end
            
            if ret==0 && QC.memory_images
                if QC.save_images
                    ImageArray(N).img=ImageStruct.img;
                else
                    ImageArray(N).img=...
                        QC.unpackImgBuffer(QC.pImg,w,h,channels,bp);
                end
            end
            
            % if write to a file
            if QC.save_images
                QC.writeImageFile(QC,ImageStruct)
            end
            
        end
    end
    
    %% Private methods
    methods (Access = private, Static)
        
        function allocate_image_buffer(QC)
            % Allocate the image buffer. The maximal length is in fact only
            %  needed only for full frame color images including overscan
            %  areas; for all other cases (notably when only a ROI, or binning
            %  is requested) it probably could be smaller, making transfer
            %  time much shorter. However, the SDK doesn't provide a safe way
            %  to determine this size, and hence we allocate a lot to stay
            %  safe from segfaults.
            imlength=GetQHYCCDMemLength(QC.camhandle);
            QC.pImg=libpointer('uint8Ptr',zeros(imlength,1,'uint8'));
        end

        function deallocate_image_buffer(QC)
            % check if the buffer is defined, so that the function can
            %  be called harmlessly multiple times
            if isa(QC.pImg,'lib.pointer')
                delete(QC.pImg)
            end
        end
        
        function img=unpackImgBuffer(pImg,w,h,channels,bp)
            % Conversion of an image buffer to a matlab image
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
        
        function writeImageFile(QC,ImgStruct)
            % Save the image QC.progressive_frame
            % For the very beginning in a .mat file, in future in a
            %  format TBD
            % The file name is derived from fields of QC
            save([QC.save_path,num2str(QC.progressive_frame),'.mat'],'ImgStruct');
        end
    end
    
end

            
