function EnableQHYCCDLogFile(enable)
% argument is true or false
    calllib('libqhyccd','EnableQHYCCDLogFile',enable);