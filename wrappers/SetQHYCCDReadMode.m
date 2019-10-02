function ret = SetQHYCCDReadMode(camhandle,modeNumber)
    ret = calllib('libqhyccd','SetQHYCCDReadMode',camhandle,modeNumber);