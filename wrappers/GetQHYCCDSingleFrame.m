function [ret,w,h,bp,channels]=...
               GetQHYCCDSingleFrame(camhandle,Pimg)

Pw=libpointer('uint32Ptr',0);
Ph=libpointer('uint32Ptr',0);
Pbp=libpointer('uint32Ptr',0);
Pchannels=libpointer('uint32Ptr',0);

[ret,~,w,h,bp,channels]=...
    calllib('libqhyccd','GetQHYCCDSingleFrame',camhandle,...
             Pw,Ph,Pbp,Pchannels,Pimg);
