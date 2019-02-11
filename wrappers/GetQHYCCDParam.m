function value = GetQHYCCDParam(camhandle,control)
   value = calllib('libqhyccd','GetQHYCCDParam',camhandle,uint16(control));