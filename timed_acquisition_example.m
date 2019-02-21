% This example runs the camera in live mode, makes the last transferred
%  image always available in the ImageStruct, and leaves the matlab prompt
%  free for other (not too demanding) tasks

QC=QHYccd(1);
QC.temperature=-10;
QC.expTime=4; % expTime has to be longer than transfer time, to work in live video mode
QC.gain=10;
QC.color=true;
QC.sequence_frames=Inf;
QC.grabbing_GUI=false;


timed_acquisition=timer( ...
    'ExecutionMode', 'fixedSpacing',...
    'Period',QC.expTime, ...
    'StartDelay',QC.expTime,....
    'StartFcn', 'start_sequence_take(QC)',...
    'TimerFcn', 'ImageStruct=poll_live_image(QC);',...
    'StopFcn', 'stop_sequence_take(QC)' ...
    )

start(timed_acquisition)

% stop(timed_acquisition) and delete(QC) at the end