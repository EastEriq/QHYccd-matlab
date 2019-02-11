InitializeCamera

SetCameraParameters

SetQHYCCDStreamMode(camhandle,0);

ret=ExpQHYCCDSingleFrame(camhandle);
if ret==hex2dec('2001')
    pause(0.1)
end

if ret~=hex2dec('FFFFFFFF')
    imlength=GetQHYCCDMemLength(camhandle);
    
    Pimg=libpointer('uint8Ptr',zeros(imlength,1,'uint8'));
    
    tic
    [ret,w,h,bp,channels]=...
        GetQHYCCDSingleFrame(camhandle,floor(w/xb),floor(h/yb),bp,Pimg);
    toc
    
    % it seems that Single Frame is always bw 16bit,
    %  no matter parameter settings (why?)
    color=false;
    img=unpackImgBuffer(Pimg,w,h,color,bp,xb,yb);

    imagesc(img)
    if ~color
        colormap gray; colorbar
    else
        colorbar off
    end
    
    clear Pimg
end

CancelQHYCCDExposing(camhandle);

CloseCamera