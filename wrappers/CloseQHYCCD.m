function ret = CloseQHYCCD(camhandle)
    ret = calllib('libqhyccd','CloseQHYCCD',camhandle);