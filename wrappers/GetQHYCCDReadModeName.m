function [ret,name]=GetQHYCCDReadModeName(camhandle,mode)
% undocumented, guessed
    Pname=libpointer('cstring',char(65*ones(1,32)));
    [ret,~,name]=calllib('libqhyccd','GetQHYCCDReadModeName',...
                                             camhandle,mode,Pname);
