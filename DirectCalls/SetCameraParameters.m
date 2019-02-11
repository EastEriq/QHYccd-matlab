SetQHYCCDParam(camhandle,qhyccdControl.CONTROL_USBTRAFFIC,30);
SetQHYCCDParam(camhandle,qhyccdControl.CONTROL_GAIN,4000);
SetQHYCCDParam(camhandle,qhyccdControl.CONTROL_OFFSET,0);
SetQHYCCDParam(camhandle,qhyccdControl.CONTROL_EXPOSURE,2000000);

% SetQHYCCDParam(camhandle,qhyccdControl.CONTROL_WBR,0000),...
% SetQHYCCDParam(camhandle,qhyccdControl.CONTROL_WBB,0000),...
% SetQHYCCDParam(camhandle,qhyccdControl.CONTROL_WBG,4000);

ControlQHYCCDTemp(camhandle,-18);

% these two are the same if 8 or 16 (at least in Live mode -- in
%  single frame -- oddities happen)
%  any other value is silently interpreted as 16
bp=16;
SetQHYCCDParam(camhandle,qhyccdControl.CONTROL_TRANSFERBIT,bp);
SetQHYCCDBitsMode(camhandle,bp);

GetQHYCCDParam(camhandle,qhyccdControl.CONTROL_TRANSFERBIT);

fprintf('current white balance: %f/%f/%f\n',...
    GetQHYCCDParam(camhandle,qhyccdControl.CONTROL_WBR),...
    GetQHYCCDParam(camhandle,qhyccdControl.CONTROL_WBB),...
    GetQHYCCDParam(camhandle,qhyccdControl.CONTROL_WBG) );

%[~,min,max,step]=GetQHYCCDParamMinMaxStep(camhandle,qhyccdControl.CONTROL_EXPOSURE)

color=false;
SetQHYCCDDebayerOnOff(camhandle,color);

if color
    SetQHYCCDResolution(camhandle,0,0,w,h);
else
    % this is problematic in color mode
    SetQHYCCDParam(camhandle,qhyccdControl.CAM_IGNOREOVERSCAN_INTERFACE,1);
    SetQHYCCDResolution(camhandle,x1,y1,sx,sy);
end

% for the QHY367, 1x1 and 2x2 seem to work; NxN with N>2 gives error,
%  NxM gives no error, but all are uneffective and fall back to 1x1
xb=1; yb=1;
if SetQHYCCDBinMode(camhandle,xb,yb)==0
    fprintf('binning mode %dx%d apparently set correctly\n',xb,yb);
else
    fprintf('binning mode %dx%d not accepted\n',xb,yb)
end

%[ret,humidity]=GetQHYCCDHumidity(camhandle)
