function ret = BeginQHYCCDLive(camhandle)
  ret=calllib('libqhyccd','BeginQHYCCDLive',camhandle);