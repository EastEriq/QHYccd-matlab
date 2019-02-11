function [ret,id,model]=GetQHYCCDExposureRemaining(camhandle)
% undocumented, guessed
    Pid=libpointer('cstring',id);
    Pmod=libpointer('cstring',char(65*ones(1,32)));
    [ret,id,model]=calllib('libqhyccd','GetQHYCCDExposureRemaining',Pid,Pmod);
