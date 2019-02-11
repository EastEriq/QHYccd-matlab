function ret = SetQHYCCDStreamMode(camhandle,mode)
  ret=calllib('libqhyccd','SetQHYCCDStreamMode',camhandle,mode);