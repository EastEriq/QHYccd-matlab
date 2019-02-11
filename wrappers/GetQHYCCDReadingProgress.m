function progress=GetQHYCCDReadingProgress(camhandle)
% undocumented (short desc in Qt tool .h), guessed
    progress=calllib('libqhyccd','GetQHYCCDReadingProgress',camhandle);
