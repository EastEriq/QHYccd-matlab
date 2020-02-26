% stupid recovery actions, may be needed for repeted calls,
% otherwise cameras may not be found
try
    clear camhandle 
catch
end
try
    unloadlibrary('libqhyccd')
catch
end

if ~libisloaded('libqhyccd'), loadLibqhyccd; end

EnableQHYCCDMessage(false)

InitQHYCCDResource;

[ret,version,major,minor,build]=GetQHYCCDSDKVersion();
fprintf('Using SDK v%d.%d.%d.%d\n',version,major,minor,build);

num=ScanQHYCCD;
fprintf('Found %d QHYCCD cameras\n',num)

if num==1
  [~,id]=GetQHYCCDId(0);
end
if num>1
    fprintf('\n choose the camera in the menu on the figure:\n',num)
    ids={};
    for i=1:num
        [~,ids{i}]=GetQHYCCDId(i-1);
    end
    clf
    chosen=false;
    mm=uicontrol('Style','popupmenu','Position',[15 15 300 30],...
        'string',ids,'callback','chosen=true;');
    while ~chosen
        pause(0.1)
    end
    id=ids{get(mm,'value')};
    delete(mm)
end

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