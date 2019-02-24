% For comments, see the Readme files in the relevant directories.

% Remember that this so far works only starting matlab as
%    LD_PRELOAD=/lib/x86_64-linux-gnu/libusb-1.0.so.0 matlab

if libisloaded('libqhyccd')
    unloadlibrary('libqhyccd')
end
[notfound,warnings]=loadlibrary('libqhyccd','../../headers/qhyccd_matlab.h',...
    'includepath','../../headers');

%qhyfuns=libfunctions('libqhyccd','-full');
%libfunctionsview('libqhyccd')

addpath('../../wrappers')

%quick way to look up the prototypes of imported functions:
% WRONG % qhyfuns{cell2mat(strfind(qhyfuns,'Open'))>0}