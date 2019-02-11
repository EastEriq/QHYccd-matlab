function ret=ControlQHYCCDTemp(camhandle,T)
    ret=calllib('libqhyccd','ControlQHYCCDTemp',camhandle,T);
