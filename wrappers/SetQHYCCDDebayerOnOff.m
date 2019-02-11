function ret = SetQHYCCDDebayerOnOff(camhandle,on)
    ret=calllib('libqhyccd','SetQHYCCDDebayerOnOff',camhandle,on);