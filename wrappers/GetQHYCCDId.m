function [ret,id]=GetQHYCCDId(num)
    Pid=libpointer('cstring',char(65*ones(1,32)));
    [ret,id]=calllib('libqhyccd','GetQHYCCDId',num,Pid);
