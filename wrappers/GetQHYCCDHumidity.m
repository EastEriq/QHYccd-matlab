function [ret,humidity]=GetQHYCCDHumidity(camhandle)
% undocumented, guessed
    Phum=libpointer('doublePtr',NaN);
    [ret,~,humidity]=calllib('libqhyccd','GetQHYCCDHumidity',camhandle,Phum);
