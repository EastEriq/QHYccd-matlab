function ret = SetQHYCCDResolution(camhandle,x1,y1,x2,y2)
    ret=calllib('libqhyccd','SetQHYCCDResolution',camhandle,x1,y1,x2,y2);