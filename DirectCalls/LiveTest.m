InitializeCamera

SetCameraParameters

SetQHYCCDStreamMode(camhandle,1);

BeginQHYCCDLive(camhandle);

figure(1)
btn=uicontrol('Style','Togglebutton','Position',[20 20 50 20],...
              'String','stop');
j=0;
while ~get(btn,'Value')
    ret=-1; i=0;
    while ret ~=0 && ~get(btn,'Value')
        % problem: both "image not ready" and "framebuffer overrun"
        %  return FFFFFFFF. Like this, it will work steadily
        %  only if t_exp>t_transfer
        [ret,w,h,bp,channels]=...
            GetQHYCCDLiveFrame(camhandle,w,h,bp,Pimg);
        i=i+1;
        title(sprintf('waiting image # %d, %d repeats, code %X',j,i,ret))
        drawnow
    end
    j=j+1;

    img=unpackImgBuffer(Pimg,w,h,color,bp);
    
    ShowImage
    
    title(sprintf('image # %d, %d repeats',j,i))
    drawnow
end

StopQHYCCDLive(camhandle);

delete(btn)

CloseCamera