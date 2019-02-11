function ret = StopQHYCCDLive(camhandle)
    ret = calllib('libqhyccd','StopQHYCCDLive',camhandle);