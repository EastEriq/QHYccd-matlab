## QHY SDK Incongruences / Bugs / Missing essential documentation

Tests have been done via the Matlab wrappers in this project, with the combination
QHY367c/USB2/Matlab 2015b/Ubuntu16/SDK v19.1.22.0.

+ `SetQHYCCDBinMode(camhandle,xb,yb)` returns error `0xFFFFFFFF` only for a few incongrous modes
  with xb=yb (e.g., 3,3). It returns 0 for any other combination of xb and yb, e.g.
  `SetQHYCCDBinMode(camhandle,1672,433)==0`.

+  `GetQHYCCDParam(camhandle,param)` returns error `0xFFFFFFFF` for all four
   binning modes, i.e. `qhyccdControl.CAM_BIN1X1MODE`, `qhyccdControl.CAM_BIN2X2MODE`,
   `qhyccdControl.CAM_BIN3X3MODE`, `qhyccdControl.CAM_BIN4X4MODE`

+ The dimensions reported by `GetQHYCCDOverScanArea()` are unclear. In fact the numbers returned
  are actually the same as those of `GetQHYCCDEffectiveArea()` (but once I saw something even
  less logical -- probably depending on some other mode-setting call).

+ If color mode is set (that is `SetQHYCCDDebayerOnOff(camhandle,true)`),
  acquisition can crash with a segfault in `_ZN7QHYBASE14QHYCCDDemosaicEPvjjjS0_h`,
  depending on I don't know what, maybe when `CONTROL_TRANSFERBIT` is 16,
  maybe attempting to set/ignore overscan
  (`SetQHYCCDParam(camhandle,qhyccdControl.CAM_IGNOREOVERSCAN_INTERFACE,0 or 1)`),
  maybe based on the previous history of the camera since connected.

+ The organization of pixels in the image buffer, when in 8bit/color mode is different from images
  returned in single frame and in live mode. So far I'm able to make sense only of the latter.

+ In bw mode, overscan ignored, the buffer still has black bands -- only, instead of a single
  vertical band on the left of the image, the black is half at the left and half at the right
  (in live mode but not in single exp mode).
  The upper four black lines are not removed though.

+ The return value of `GetQHYCCDParamMinMaxStep(camhandle,parameter)` may be 0 even for non supported parameters.

+ The functional difference between
  `SetQHYCCDParam(camhandle,qhyccdControl.CONTROL_TRANSFERBIT,bp)` and
  `SetQHYCCDBitsMode(camhandle,bp)` is not explained. Moreover neither function
  returns errors if `bp` is any number different than 8 or 16. It is not clear
  which one of the two if not both have to be set consistently for a correct acquisition,
  and I suspect that `ExpQHYCCDSingleFrame` crashes if they are not.

+ `GetQHYCCDMemLength(camhandle)` returns always 110023200 no matter binning,
   color mode, ROI, overscan, resolution set (`SetQHYCCDResolution`) no matter whether
   called before or after acquisition
   is started. Unreasonable, and doesn't help dimensioning correctly the image buffer.

+ There is no function like a `GetQHYCCDResolution()`. "Resolution" (in fact ROI) can only be set. But
  without a way to read it back, there is no basis for allocating correctlythe image buffer for image
  transfers. Recipe for segfaults. The fact that `GetQHYCCDSingleFrame()` and `GetQHYCCDLiveFrame()`
  return the image size is irrelevant because the buffer has to be allocated before their call.

+ `GetQHYCCDSingleFrame()` often hangs, I suppose if called after a change in one parameter
   which affects the image buffer size

+ if T<sub>exp</sub>&lt;T<sub>transfer</sub>, `GetQHYCCDLiveFrame()` returns all the time error
 `0xFFFFFFFF` after the second frame. That looks as if, by bad design, `GetQHYCCDLiveFrame()` is
 supposed to return the same return code both for "image not yet fully transfered into framebuffer",
 and "framebuffer full". Ideally that should not happen, the framebuffer should be circular, and
 the last available frame should be returned even if intermediate frames are lost.

