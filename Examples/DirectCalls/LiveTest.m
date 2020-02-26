InitializeCamera

if contains(id,'QHY600')
    SetQHYCCDStreamMode(camhandle,1);
    InitQHYCCD(camhandle);
    SetCameraParameters
else
    SetCameraParameters
    SetQHYCCDStreamMode(camhandle,1);
end

BeginQHYCCDLive(camhandle);

figure(1)
btn=uicontrol('Style','Togglebutton','Position',[5 5 80 30],...
              'String','stop','BackgroundColor','r',...
              'fontweight','bold','FontSize',16);
j=0;
while ~get(btn,'Value')
    ret=-1; i=0;
    while ret ~=0 && ~get(btn,'Value')
        % problem: both "image not ready" and "framebuffer overrun"
        %  return FFFFFFFF. Like this, it will work steadily
        %  only if t_exp>t_transfer
        [ret,w,h,bp,channels]=...
            GetQHYCCDLiveFrame(camhandle,Pimg);
        i=i+1;
        xlabel(id)
        title(sprintf('waiting image # %d, %d repeats, code %X',j,i,ret))
        drawnow
    end
    j=j+1;

    img=unpackImgBuffer(Pimg,w,h,color,bp);
    
    ShowImage
    
    xlabel(id)
    title(sprintf('image # %d, %d repeats',j,i))
    drawnow
end

CancelQHYCCDExposingAndReadout(camhandle);

StopQHYCCDLive(camhandle);

delete(btn)

CloseCamera