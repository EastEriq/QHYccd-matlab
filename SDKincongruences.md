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
  are actually the same as those of `GetQHYCCDEffectiveArea()` (but at cold boot I see something even
  less logical, like (348,6)+(3000,20)).

+ The functional difference between
  `SetQHYCCDParam(camhandle,qhyccdControl.CONTROL_TRANSFERBIT,bp)` and
  `SetQHYCCDBitsMode(camhandle,bp)` is not explained. Moreover neither function
  returns errors if `bp` is any number different than 8 or 16. It is not clear
  which one of the two if not both have to be set consistently for a correct acquisition,
  and I suspect that `ExpQHYCCDSingleFrame` crashes if they are not.

+ If color mode is set (that is `SetQHYCCDDebayerOnOff(camhandle,true)`) and transfer
  mode is 16 bit,
  acquisition segfaults in `_ZN7QHYBASE14QHYCCDDemosaicEPvjjjS0_h`. Ok, it is stated in
  [here](https://www.qhyccd.com/bbs/index.php?topic=6038.msg31762#msg31762) and
  [here](https://www.qhyccd.com/bbs/index.php?topic=5903.msg31631#msg31631),
  but seriously, it should be handled more gracefully.

+ The organization of pixels in the image buffer, when in 8bit/color mode w/o binning,
  is different from images returned in single frame and in live mode. I'm not always able
  to make sense of it. In single frame in particular, the organization seems to be
  differently wrong (e.g. image split and reinterleaved, buffer only partially filled)
  when the mode is changed.

+ In bw mode, overscan ignored, the buffer still has black bands -- only, instead of a single
  vertical band on the left of the image, the black is half at the left and half at the right
  (in live mode but not in single exp mode).
  The upper four black lines are not removed though.

+ The return value of `GetQHYCCDParamMinMaxStep(camhandle,parameter)` may be 0 even for non supported parameters.

+ `GetQHYCCDMemLength(camhandle)` returns always 110023200 no matter binning,
   color mode, ROI, overscan, resolution set (`SetQHYCCDResolution`) no matter whether
   called before or after acquisition
   is started. Ok, said [here](https://www.qhyccd.com/bbs/index.php?topic=5903.msg31621#msg31621).
   But alas, that is unreasonable, and doesn't help dimensioning correctly the image buffer.
   Setting always max can turn out wasteful.

+ There is no function like a `GetQHYCCDResolution()`. "Resolution" (in fact ROI) can only be set. But
  without a way to read it back, there is no basis for allocating correctly the image buffer for image
  transfers. Recipe for segfaults. The fact that `GetQHYCCDSingleFrame()` and `GetQHYCCDLiveFrame()`
  return the image size is irrelevant because the buffer has to be allocated before their call.

+ `GetQHYCCDSingleFrame()` often hangs, I suppose if called after a change in one parameter
   which affects the image buffer size

+ if T<sub>exp</sub>&lt;T<sub>transfer</sub>, `GetQHYCCDLiveFrame()` returns all the time error
 `0xFFFFFFFF` after the second frame. That looks as if, by bad design, `GetQHYCCDLiveFrame()` is
 supposed to return the same return code both for "image not yet fully transfered into framebuffer",
 and "framebuffer full". Ideally that should not happen, the framebuffer should be circular, and
 the last available frame should be returned even if intermediate frames are lost.

