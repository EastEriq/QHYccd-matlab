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
