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

% After a mode change, it seems that Single Frames pixels are
% organized differently than Live Frames. Why?
img=unpackImgBuffer(Pimg,w,h,color,bp);

ShowImage

CancelQHYCCDExposing(camhandle);

CloseCamera