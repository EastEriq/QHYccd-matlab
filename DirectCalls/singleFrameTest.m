InitializeCamera

SetCameraParameters

SetQHYCCDStreamMode(camhandle,0);

ret=ExpQHYCCDSingleFrame(camhandle);
if ret==hex2dec('2001')
    pause(0.1)
end

fprintf('  now I will read the frame...\n')
tic
[ret,w,h,bp,channels]=...
    GetQHYCCDSingleFrame(camhandle,floor(w/xb),floor(h/yb),bp,Pimg);
toc

% it seems that Single Frame is always bw 16bit,
%  no matter parameter settings (why?)
img=unpackImgBuffer(Pimg,w,h,color,bp,xb,yb);

ShowImage

CancelQHYCCDExposing(camhandle);

CloseCamera