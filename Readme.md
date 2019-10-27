Matlab bindings for the QHYccd SDK
==================================

For cameras produced by [QHYccd](https://www.qhyccd.com/).

This package has been tested with the combinations

+ Matlab 2015b/Ubuntu16/SDK v19.1.22.0 and a QHY367c camera connected on USB2,
+ Matlab 2018b/Ubuntu16/SDK 6.0.1 and QHY600 camera connected on USB2,
+ Matlab 2018b/Ubuntu16/SDK 6.0.1 and QHY600 camera connected on USB2,
+ Matlab 2018b/Ubuntu18/SDK v19.1.22.0, QHY367c camera connected on USB3.
+ a forum user has reported success with QHY163M under Matlab2018a/Deepin15.11.

### Instructions:

+ install the SDK. See the file [InstallingQHYsdk.md](InstallingQHYsdk.md) for specific experiences

+ in matlab, `addpath()` this directory and `wrappers`

### Directory contents:

+  `.md` files: ramblings and rants about usage

+  `QHYccd.m` Matlab ***class***, for integration with [MAAT](https://webhome.weizmann.ac.il/home/eofek/matlab/index.html)
   (*in development*)

+ `headers/`: modified qhy headers, so that Matlab's `loadlibrary()` is happy with them

+ `wrappers/`: bindings for calling QHYccd SDK functions with Matlab syntax, and definition
   of the enumeration `qhyccdControl` (QHY names of the controllable parameters).

+ `Examples/`: a set of demo scripts for acquiring images in Matlab, vaguely reproducing the
   calling sequences of the `.cpp` examples provided by QHY.

+ `mex-demo/`: a trimmed down and adapted version of the Matlab demo provided by QHY,
  so that it compiles on Linux. This is added here for reference, but is not part of the bindings
  project.

### Examples:

See the contents of the folder `Examples`. In short: sequence script way:

    addpath(genpath('.')); cd Examples/DirectCalls/
    LiveTest

Class usage:

    addpath wrappers
    QC=QHYccd(1);
    QC.temperature=-10;
    QC.expTime=2;
    QC.gain=1000;
    QC.color=true;
    QC.sequence_frames=5;
    ImgStruct=take_sequence_blocking(QC)
    imagesc(ImgStruct(3).img)

### Typical class program flow:

    QC=QHYccd  %instantiate the class object and open the camera
    % set camera parameters (don't rely on the defaults - they are wrong!)

Then either:

+ Blocking acquisition of a single frame:

        ImageStruct=take_single_exposure(QC);

    this way the prompt is available only after `QC.expTime + t_readout`. On the other hand,
    there is no limitation on short `expTime`, and no framebuffer pipeline involved

+ Split acquisition of a single frame

        start_single_exposure(QC)
         % do something else inbetween
        ImageStruct=collect_single_exposure(QC);

+ Blocking aqcquisition of a live sequence:

        ImageArray=take_sequence_blocking(QC)

    the prompt will be available only approximately after `QC.sequence_images*QC.expTime + t_readout`.
    However, `QC.expTime` must be larger than `t_readout` (otherwise only the first two images
    can be retrieved, the following ones overfill the framebuffer); and moreover, acquisition
    goes through a framebuffer which acts as a FIFO (capacity ~ two full frame images). The
    first images retrieved may be old ones still in buffer.

+ Split acquisition of a live sequence

        start_sequence_take(QC)
        % do something else, then periodically, for QC.sequence_images times
        ImageArray=poll_live_image(QC,ImageArray);
        % finally,
        stop_sequence_take(QC)

    This has the same limitations as the previous, but leaves the prompt free inbetween, for
    tasks which don't last more than `QC.expTime` (some tolerance permitted by the presence
    of the framebuffer).
    An example of this pattern, by means of a timed callback, is in `Examples/Class/timed_acquisition_example.m`.

At the end,

    close_camera(QC)

or all together `clear QC`.

__Note__: by quirks of the SDK, it seems that single exposure images are messed up if acquired after
acquisition in live mode. Better `close_camera(QC); open_camera(QC);` when changing mode.
Take care also not to `open_camera(QC)` more than once without closing, that can hang or crash matlab.