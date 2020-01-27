## QHY SDK Incongruences part 2

Addendum of complaints and note of possible workarounds when there are. This time the main
test platform is QHY600/USB3/Matlab 2019b/Ubuntu18/SDK 6.0.5 (packaged by James Fidell).

+ `unloadlibrary('libqhyccd')` segfaults Matlab, the trace hints at `libpthread.so`. To reproduce:
```
  loadlibrary('libqhyccd','QHYccd-matlab/headers/qhyccd_matlab.h')
  calllib('libqhyccd','InitQHYCCDResource')
  calllib('libqhyccd','ReleaseQHYCCDResource')
  unloadlibrary('libqhyccd')
```
On the platform I'm using now, this pops up 17 crash dialogs, even. If that indicates the number
of threads involved. I don't remember that something the like was happening with earlier versions.

+ debug output on `stdout` is not squelched. It is of minimal utility and mostly a nuisance.

+ Looking at the debug output, I note that `InitQHYCCDResource` calls `ScanQHYCCD` and says 
something about creating image queues. Maybe they are not deallocated on exit and that is the reason
for the crash.

+`QHYCCD|QHY5IIIBASE.CPP|ReadImageInDDR_...` (?, check) can get stuck with poor USB communication
(e.g., long cable) and there is no way to abort the attempt but to kill Matlab.

+ Live mode doesn't seem to work for the QHY600. That is, with the calling sequence
```
  SetQHYCCDStreamMode(QC.camhandle,1);
  BeginQHYCCDLive(QC.camhandle);

    GetQHYCCDLiveFrame(QC.camhandle,QC.pImg)
```
`GetQHYCCDLiveFrame` returns all the time `0xFFFFFFFF`. Btw I have already complained earlier that
it is bad that `0xFFFFFFFF` flags both errors and image not yet available.
