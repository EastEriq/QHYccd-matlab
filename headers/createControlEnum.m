% quick & dirty parsing script to parse the qhyccdstruct.h
%  file and generate a matlab enumeration
fid1=fopen('/usr/include/qhyccd/qhyccdstruct.h');
fid2=fopen('../wrappers/qhyccdControl.m','w');

l=''; controlblock=false; inum=-1;
while ischar(l)
    l=fgetl(fid1);
    if controlblock
        if strfind(l,'}')>0
            controlblock=false;
            fprintf(fid2,'\n    end\nend\n');
        end
        controlword=strrep(strtok(l),',','');
        if ~isempty(controlword) && controlblock
            if inum>=0
                fprintf(fid2,',\n');
            end
            inum=inum+1;
            fprintf(fid2,'        %s (%d)',controlword,inum);
        end
    end
    if strfind(l,'typedef enum CONTROL_ID')
        controlblock=true;
        fgetl(fid1); % skip {
        fprintf(fid2,'classdef qhyccdControl < uint16\n    enumeration\n');
    end
end
fclose(fid1);
fclose(fid2);
