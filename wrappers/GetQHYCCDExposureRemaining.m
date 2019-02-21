function t_left=GetQHYCCDExposureRemaining(camhandle)
% According to the qhyccd.h deep inside the Qt demo, a return value
%  of 100 or less means that the exposure is over.
    t_left=calllib('libqhyccd','GetQHYCCDExposureRemaining',camhandle);
