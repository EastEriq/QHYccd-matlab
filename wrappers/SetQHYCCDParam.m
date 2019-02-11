function ret = SetQHYCCDParam(camhandle,control,value)
   ret=calllib('libqhyccd','SetQHYCCDParam',camhandle,uint16(control),value);