function EnableQHYCCDMessage(enable)
% argument is true or false
    calllib('libqhyccd','EnableQHYCCDMessage',enable);