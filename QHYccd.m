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
% Reliable: Like the chinese fire drill
%--------------------------------------------------------------------------

classdef QHYccd < handle
    properties (SetAccess = public)
        % generic fields
        Flag         = false;                         % false - readings are unreliable, true - ok
        
        % what is the intended use of this?
        Data           @ stack                          % Stack object containing data history
        DataCol        = {'JD','WindSpeed','WindAz'};   % Stack object columns
        DataUnits      = {'day','km/h','deg'};          % Stack object column units
        
        
        % specific fields
        WindSpeed      = NaN;                        % last wind speed
        WindSpeedUnits = 'km/h';                     % wind speed units
        WindAz         = NaN;                        % last wind Az
        WindAzUnits    = 'deg';                      % wind Az units
        LastJD             = NaN;                    % JD of last sucessful reading
        
    end
    
    properties (Constant = true)
        
    end
    
    properties (Hidden = true)
            
     camhandle
     
    end
    
    
    % Constructor
    methods
        
        function QC=QHYccd
            % QHYccd class constructor

        end
    end
    
    % Do we need a Destructor ?
    
    % getters/setters
    methods
%         function WC=get.Data(WC)
%             % update the Data field (stack)
%             
%             getWind(WC);
%             
%         end
      
    end
    
    
    % static methods
    methods (Static)
       
        
    end
    
    methods 
        function Flag=open(QHYccd)
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
            [~,id]=GetQHYCCDId(num-1);
            
            QHYccd.camhandle=OpenQHYCCD(id);
            
            InitQHYCCD(QHYccd.camhandle);
            
            [ret,chipw,chiph,w,h,pixelw,pixelh,bp]=GetQHYCCDChipInfo(QHYccd.camhandle);
            %fprintf('%.3fx%.3fmm chip, %dx%d %.2fx%.2fµm pixels, %dbp\n',...
            %    chipw,chiph,w,h,pixelw,pixelh,bp)
            
            [ret,x1,y1,sx,sy]=GetQHYCCDEffectiveArea(QHYccd.camhandle);
            %fprintf(' effective chip area: (%d,%d)+(%d,%d)\n',x1,y1,sx,sy);
            
            [ret,x1o,y1o,sox,soy]=GetQHYCCDOverScanArea(QHYccd.camhandle);
            %fprintf(' overscan area: (%d,%d)+(%d,%d)\n',x1,y1,sx,sy);
            
            Status = (ret==0);
            
            ret=IsQHYCCDControlAvailable(QHYccd.camhandle, qhyccdControl.CAM_COLOR);
            colorAvailable=(ret>0 & ret<5);
            
            % put here also some plausible parameter settings which are
            %  not likely to be changed
            SetQHYCCDParam(QHYccd.camhandle,qhyccdControl.CONTROL_USBTRAFFIC,30);
            SetQHYCCDParam(QHYccd.camhandle,qhyccdControl.CONTROL_OFFSET,0);
            
            color=false;
            
            if color
                SetQHYCCDResolution(QHYccd.camhandle,0,0,w,h);
            else
                % this is problematic in color mode
                SetQHYCCDParam(QHYccd.camhandle,qhyccdControl.CAM_IGNOREOVERSCAN_INTERFACE,1);
                SetQHYCCDResolution(QHYccd.camhandle,x1,y1,sx,sy);
            end
            
        end
        
        function Flag=close(QHYccd)

            % check this status, which may fail
            Flag=(CloseQHYCCD(QHYccd.camhandle)==0);

            % not this, which always succeeded in my tests
            ReleaseQHYCCDResource;
            
            % consider whether the library must be unloaded, if
            %  that deserves a separate call, or if it can remain loaded
            %  for the rest of the Matlab session
            
            % unloadlibrary('libqhyccd')
            
        end
        
        function Flag=set_temp(QHYccd,Temp)
            % set the target sensor temperature in Celsius
            Flag=ControlQHYCCDTemp(QHYccd.camhandle,Temp);
        end
        
        function [Temp,Flag]=get_temp(QHYccd)
            Temp=GetQHYCCDParam(QHYccd.camhandle,qhyccdControl.CAM_CHIPTEMPERATURESENSOR_INTERFACE);
            % I guess that error is Temp=FFFFFFFF, check
            Flag = (Temp>-100 & Temp<100);
        end
        
        function Flag=set_exptime(QHYccd,ExpTime)
            % ExpTime in seconds
            Flag=SetQHYCCDParam(QHYccd.camhandle,qhyccdControl.CONTROL_EXPOSURE,ExpTime*1e6);            
        end
        
        function Flag=set_gain(QHYccd,Gain)
            Flag=SetQHYCCDParam(QHYccd.camhandle,qhyccdControl.CONTROL_GAIN,Gain);          
        end
        
        function [Gain,Flag]=get_gain(QHYccd)
              Gain=GetQHYCCDParam(QHYccd.camhandle,qhyccdControl.CONTROL_GAIN,Gain);
              % check whether err=double(FFFFFFFF)...
              Flag=(Gain<0 | Gain>2e6);
        end
        
        function Flag=set_binning(QHYccd,Binning)
            % default is 1x1
            % for the QHY367, 1x1 and 2x2 seem to work; NxN with N>2 gives error,
            %  NxM gives no error, but all are uneffective and fall back to 1x1
            if SetQHYCCDBinMode(QHYccd.camhandle,Binning,Binning)==0
                xb=Binning; yb=Binning;
                Flag=true;
            else
                Flag=false;
            end
            
        end
        
        function Flag=set_bitdepth(QHYccd,BitDepth)
            % default has to be 16bit
            SetQHYCCDParam(QHYccd.camhandle,qhyccdControl.CONTROL_TRANSFERBIT,BitDepth);
            Flag=(SetQHYCCDBitsMode(QHYccd.camhandle,BitDepth)==0);            
        end
        
        function Flag=set_color(QHYccd,ColorMode)
            % default has to be bw
             Flag=(SetQHYCCDDebayerOnOff(QHYccd.camhandle,ColorMode)==0);           
        end
        
        
        function [ImageArray,Flag]=take_live(QHYccd,Nimages)
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
            if bp==16
                ImageArray=zeros(w,h,Nimages,'uint16');
            else
                ImageArray=zeros(w,h,Nimages,'uint8');
            end
            
            j=0;
            while j<Nimages
                ret=-1; i=0;
                while ret ~=0 % add here a timeout
                    % problem: both "image not ready" and "framebuffer overrun"
                    %  return FFFFFFFF. Like this, the while exits only
                    %  only if t_exp>t_transfer and no other error happens
                    [Flag,w,h,bp,channels]=...
                        GetQHYCCDLiveFrame(QHYccd.camhandle,w,h,bp,Pimg);
                    i=i+1;
                end
                j=j+1;
                
                ImageArray(:,:,j)=unpackImgBuffer(Pimg,w,h,color,bp,xb,yb);
                
            end
            
            StopQHYCCDLive(QHYccd.camhandle);

        end
            
    end
    
    % Private methods (is there such a thing?)
    methods
        function img=unpackImgBuffer(Pimg,w,h,color,bp,xb,yb)
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

            
