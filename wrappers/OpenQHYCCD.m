function [camhandle,id]=OpenQHYCCD(id)
    [camhandle,id]=calllib('libqhyccd','OpenQHYCCD',id); % note id, not Pid
