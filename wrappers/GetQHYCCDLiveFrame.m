function [ret,w,h,bp,channels]=...
               GetQHYCCDLiveFrame(camhandle,Pimg)

Pw=libpointer('uint32Ptr',0);
Ph=libpointer('uint32Ptr',0);
Pbp=libpointer('uint32Ptr',0);
Pchannels=libpointer('uint32Ptr',0);

[ret,~,w,h,bp,channels]=...
    calllib('libqhyccd','GetQHYCCDLiveFrame',camhandle,...
             Pw,Ph,Pbp,Pchannels,Pimg);
