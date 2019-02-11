function ret = CancelQHYCCDExposing(camhandle)
    ret = calllib('libqhyccd','CancelQHYCCDExposing',camhandle);