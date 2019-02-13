Matlab bindings for the QHYccd SDK
==================================

For cameras produced by [QHYccd](https://www.qhyccd.com/).
 
This package is being tested with the combination
Matlab 2015b/Ubuntu16/SDK v19.1.22.0 and a QHY367c camera connected on USB2,
as well as on Matlab 2018b/Ubuntu18/SDK v19.1.22.0, QHY367c camera connected on USB3.

### Instructions:

+ install the SDK. See the file InstallingQHYsdk.md for specific experiences

+ in matlab, `addpath()` this directory and `wrappers`

### Directory contents:

+  `.md` files: ramblings and rants about usage

+  `QHYccd.m` Matlab ***class***, for integration with [MAAT](https://webhome.weizmann.ac.il/home/eofek/matlab/index.html)
   (*in development, not yet up*)

+ `headers/`: modified qhy headers, so that Matlab's `loadlibrary()` is happy with them

+ `wrappers/`: bindings for calling QHYccd SDK functions with Matlab syntax, and definition
   of the enumeration `qhyccdControl` (QHY names of the controllable parameters).

+ `DirectCalls/`: a set of demo scripts for acquiring images in Matlab, vaguely reproducing the
   calling sequences of the `.cpp` examples provided by QHY. Entry points are
   `singleFrameTest.m` and `LiveTest.m`.

+ `mex-demo/`: a trimmed down and adapted version of the Matlab demo provided by QHY,
  so that it compiles on Linux. This is added here for reference, but is not part of the bindings
  project.

### Examples:

In matlab, sequence script way:

    addpath(genpath('.'));cd DirectCalls/
    LiveTest

Class usage:

    ....