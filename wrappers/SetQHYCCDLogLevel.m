function SetQHYCCDLogLevel(level)
% level is declared as integer. No idea how much verbosity is controlled
%  by each level. Testing, 4 is more verbose than 3.
    calllib('libqhyccd','SetQHYCCDLogLevel',level);