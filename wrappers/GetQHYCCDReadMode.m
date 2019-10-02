function [ret,mode]=GetQHYCCDReadMode(camhandle)
% undocumented, guessed
    Pn=libpointer('uint32Ptr',0);
    [ret,~,mode]=calllib('libqhyccd','GetQHYCCDReadMode',camhandle,Pn);
