function ret=GetQHYCCDExposureRemaining(camhandle)
% undocumented, guessed
    ret=calllib('libqhyccd','GetQHYCCDExposureRemaining',camhandle);
