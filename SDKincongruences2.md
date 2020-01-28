## QHY SDK Incongruences part 2

Addendum of complaints and note of possible workarounds when there are. This time the main
test platform is QHY600/USB3/Matlab 2019b/Ubuntu18/SDK 6.0.5 (packaged by James Fidell).

+ `unloadlibrary('libqhyccd')` segfaults Matlab, and the trace hints at `libpthread.so`. To reproduce:
```
  loadlibrary('libqhyccd','QHYccd-matlab/headers/qhyccd_matlab.h')
  calllib('libqhyccd','InitQHYCCDResource')
  calllib('libqhyccd','ReleaseQHYCCDResource')
  unloadlibrary('libqhyccd')
```
On the platform I'm using now, this pops up 17 crash dialogs, even, if that indicates the number
of threads involved. I don't remember that something the like was happening with earlier versions.

+ debug output on `stdout` is not squelched. It is of minimal utility and mostly a nuisance.

+ Looking at the debug output, I note that `InitQHYCCDResource` calls `ScanQHYCCD` and says 
something about creating image queues. Maybe they are not deallocated on exit and that is the reason
for the crash.

+ With poor USB communication (e.g., long cable), the SDK process can get stuck in a phase 
flagged by repeated `QQHYCCD|QHY5IIIBASE.CPP|ReadImageInDDR_Titan| readusb failure` debug
messages on stdout. There is no way to abort the attempt but to kill Matlab. This is Bad.

+ Live mode doesn't seem to work for the QHY600. That is, with the calling sequence
```
  SetQHYCCDStreamMode(QC.camhandle,1);
  BeginQHYCCDLive(QC.camhandle);

    GetQHYCCDLiveFrame(QC.camhandle,QC.pImg)
```
`GetQHYCCDLiveFrame` returns all the time `0xFFFFFFFF`. Btw I have already complained earlier that
it is bad that `0xFFFFFFFF` flags both errors and image not yet available. Still,
`IsQHYCCDControlAvailable()` says that `CAM_LIVEVIDEOMODE` is supported on the QHY600.

+ The image transfer is WAY slower than it should be according to fps specs and USB bandwidth. With
 the call sequence
```
   SetQHYCCDStreamMode(QC.camhandle,0);
   ExpQHYCCDSingleFrame(QC.camhandle);
   GetQHYCCDSingleFrame(QC.camhandle,QC.pImg);
```
I get at best wall times of 2.8sec+texp with the QHY600 and 1.9sec+texp with the QHY367. The split-out
is ~100ms in `SetQHYCCDStreamMode`, ~1ms in `ExpQHYCCDSingleFrame` and over 2500ms in `GetQHYCCDSingleFrame` for the QHY600, e.g. This is with the cameras directly connected to USB3.2 ports of a fast motherboard with short cables.

Now there should be
two control parameters affecting the transfer speed, `CONTROL_SPEED` (9) and `CONTROL_USBTRAFFIC`
(12). `IsQHYCCDControlAvailable()` says that only the second is available in the two cameras. However,
it turns out that even that could be set to a value different from 0 only on the QHY600, and has no effect on the timing.