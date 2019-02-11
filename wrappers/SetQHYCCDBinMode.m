function ret = SetQHYCCDBinMode(camhandle,cambinx,cambiny)
    ret = calllib('libqhyccd','SetQHYCCDBinMode',camhandle,cambinx,cambiny);