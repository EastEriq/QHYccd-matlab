function [ret,Nmodes]=GetQHYCCDNumberOfReadModes(camhandle)
% undocumented, guessed
    Pn=libpointer('uint32Ptr',0);
    [ret,~,Nmodes]=calllib('libqhyccd','GetQHYCCDNumberOfReadModes',...
                                             camhandle,Pn);
