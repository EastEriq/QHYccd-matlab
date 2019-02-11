function [ret,min,max,step]=GetQHYCCDParamMinMaxStep(camhandle,control)
Pmin=libpointer('doublePtr',0);
Pmax=libpointer('doublePtr',0);
Pstep=libpointer('doublePtr',0);
[ret,~,min,max,step]=...
    calllib('libqhyccd','GetQHYCCDParamMinMaxStep',camhandle,...
             uint16(control),Pmin,Pmax,Pstep);
