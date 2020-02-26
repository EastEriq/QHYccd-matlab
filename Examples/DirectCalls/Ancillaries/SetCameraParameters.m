SetQHYCCDParam(camhandle,qhyccdControl.CONTROL_USBTRAFFIC,30);
SetQHYCCDParam(camhandle,qhyccdControl.CONTROL_GAIN,1);
SetQHYCCDParam(camhandle,qhyccdControl.CONTROL_OFFSET,0);
SetQHYCCDParam(camhandle,qhyccdControl.CONTROL_EXPOSURE,0.2e6);

% SetQHYCCDParam(camhandle,qhyccdControl.CONTROL_WBR,0000),...
% SetQHYCCDParam(camhandle,qhyccdControl.CONTROL_WBB,0000),...
% SetQHYCCDParam(camhandle,qhyccdControl.CONTROL_WBG,4000);

ControlQHYCCDTemp(camhandle,-18);

% these two are the same if 8 or 16 (at least in Live mode -- in
%  single frame -- oddities happen)
%  any other value is silently interpreted as 16
% Don't set color and 16 bit - the SDK is known for not supporting,
%  and will segfault when acquiring
bp=16;
SetQHYCCDParam(camhandle,qhyccdControl.CONTROL_TRANSFERBIT,bp);
SetQHYCCDBitsMode(camhandle,bp);

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

if GetQHYCCDParam(camhandle,qhyccdControl.CAM_BIN1X1MODE)==0
    fprintf(' camera says it can bin 1x1\n')
end
if GetQHYCCDParam(camhandle,qhyccdControl.CAM_BIN2X2MODE)==0
    fprintf(' camera says it can bin 2x2\n')
end
if GetQHYCCDParam(camhandle,qhyccdControl.CAM_BIN3X3MODE)==0
    fprintf(' camera says it can bin 3x3\n')
end
if GetQHYCCDParam(camhandle,qhyccdControl.CAM_BIN4X4MODE)==0
    fprintf(' camera says it can bin 4x4\n')
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

% Allocate one image buffer here

imlength=GetQHYCCDMemLength(camhandle);
%imlength results always 3*7400*4956. This sounds fishy. It should
% rather depend on bp, color, binning, ROI, overscan

% Allocate the buffer. Question if it could be smaller than 3*7400*4956
Pimg=libpointer('uint8Ptr',zeros(imlength,1,'uint8'));


