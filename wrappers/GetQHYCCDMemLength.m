function ret = GetQHYCCDMemLength(camhandle)
    ret = calllib('libqhyccd','GetQHYCCDMemLength',camhandle);