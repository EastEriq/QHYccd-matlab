function [ret,chipw,chiph,w,h,pixelw,pixelh,bp]=...
                                        GetQHYCCDChipInfo(camhandle)

Pchipw=libpointer('doublePtr',0);
Pchiph=libpointer('doublePtr',0);
Pw=libpointer('uint32Ptr',0);
Ph=libpointer('uint32Ptr',0);
Ppixelw=libpointer('doublePtr',0);
Ppixelh=libpointer('doublePtr',0);
Pbp=libpointer('uint32Ptr',0);
[ret,~,chipw,chiph,w,h,pixelw,pixelh,bp]=...
    calllib('libqhyccd','GetQHYCCDChipInfo',camhandle,...
             Pchipw,Pchiph,Pw,Ph,Ppixelw,Ppixelh,Pbp);
