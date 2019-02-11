function ret = CancelQHYCCDExposingAndReadout(camhandle)
    ret = calllib('libqhyccd','CancelQHYCCDExposingAndReadout',camhandle);