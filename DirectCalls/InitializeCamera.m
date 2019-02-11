if ~libisloaded('libqhyccd'), loadLibqhyccd; end

InitQHYCCDResource;

[ret,version,major,minor,build]=GetQHYCCDSDKVersion();
fprintf('Using SDK v%d.%d.%d.%d\n',version,major,minor,build);

num=ScanQHYCCD;
fprintf('Found %d QHYCCD cameras\n',num)

[~,id]=GetQHYCCDId(num-1);
fprintf('Opening camera %s\n',id)

camhandle=OpenQHYCCD(id);

InitQHYCCD(camhandle);

[ret,chipw,chiph,w,h,pixelw,pixelh,bp]=GetQHYCCDChipInfo(camhandle);
fprintf('%.3fx%.3fmm chip, %dx%d %.2fx%.2fµm pixels, %dbp\n',...
         chipw,chiph,w,h,pixelw,pixelh,bp)

[ret,x1,y1,sx,sy]=GetQHYCCDEffectiveArea(camhandle);
fprintf(' effective chip area: (%d,%d)+(%d,%d)\n',x1,y1,sx,sy);

[ret,x1o,y1o,sox,soy]=GetQHYCCDOverScanArea(camhandle);
fprintf(' overscan area: (%d,%d)+(%d,%d)\n',x1,y1,sx,sy);
     
ret=IsQHYCCDControlAvailable(camhandle, qhyccdControl.CAM_COLOR);
if ret>0 && ret<5
    fprintf('This is a color camera\n')
else
end

fprintf('current chip temperature: %.2f°C\n',...
    GetQHYCCDParam(camhandle,qhyccdControl.CAM_CHIPTEMPERATURESENSOR_INTERFACE));