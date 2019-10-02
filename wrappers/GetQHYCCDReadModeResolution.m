function [ret,nx,ny]=GetQHYCCDReadModeResolution(camhandle,mode)
% undocumented, guessed
    Pnx=libpointer('uint32Ptr',0);
    Pny=libpointer('uint32Ptr',0);
    [ret,~,nx,ny]=calllib('libqhyccd','GetQHYCCDReadModeResolution',...
                                             camhandle,mode,Pnx,Pny);
