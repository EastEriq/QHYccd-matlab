function ret = ExpQHYCCDSingleFrame(camhandle)
    ret = calllib('libqhyccd','ExpQHYCCDSingleFrame',camhandle);