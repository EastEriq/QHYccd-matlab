function [ret,id]=GetQHYCCDId(num)
    Pid=libpointer('cstring',repmat('X',1,32));
    [ret,id]=calllib('libqhyccd','GetQHYCCDId',num,Pid);
