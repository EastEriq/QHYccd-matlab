% clear the image buffer here
clear Pimg

CloseQHYCCD(camhandle);

ReleaseQHYCCDResource;

%added for cleaner exit
QHYCCDQuit