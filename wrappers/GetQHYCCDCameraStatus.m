function [ret,status]=GetQHYCCDCameraStatus(camhandle)
    Pstat=libpointer('uint8Ptr',zeros(1,256));
    [ret,~,buf]=calllib('libqhyccd','GetQHYCCDCameraStatus',camhandle,Pstat);
    status=char(buf);
