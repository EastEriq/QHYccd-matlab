function [ret,version,major,minor,build]=GetQHYCCDSDKVersion()
% undocumented, guessed
    Pver=libpointer('uint32Ptr',0);
    Pmaj=libpointer('uint32Ptr',0);
    Pmin=libpointer('uint32Ptr',0);
    Pbld=libpointer('uint32Ptr',0);
    [ret,version,major,minor,build]=calllib('libqhyccd','GetQHYCCDSDKVersion',...
                                             Pver,Pmaj,Pmin,Pbld);
