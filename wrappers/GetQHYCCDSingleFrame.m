function [ret,w,h,bp,channels]=...
               GetQHYCCDSingleFrame(camhandle,w,h,bp,Pimg)

Pw=libpointer('uint32Ptr',w);
Ph=libpointer('uint32Ptr',h);
Pbp=libpointer('uint32Ptr',bp);
Pchannels=libpointer('uint32Ptr',0);

[ret,~,w,h,bp,channels]=...
    calllib('libqhyccd','GetQHYCCDSingleFrame',camhandle,...
             Pw,Ph,Pbp,Pchannels,Pimg);