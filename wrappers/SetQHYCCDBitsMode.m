function ret = SetQHYCCDBitsMode(camhandle,cambits)
    ret = calllib('libqhyccd','SetQHYCCDBitsMode',camhandle,cambits);