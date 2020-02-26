# Modifications made to the original headers so that they work with Matlab: #

The stock headers of the SDK are installed in `/usr/include/qhyccd`.

Currently working with v6.0.5.

The set of alternate headers for working in conjunction of SDK v4.0.1 included more
modifications, see previous versions of this file in [QHYccd-Matlab](https://github.com/EastEriq/QHYccd-matlab).

## `qhyccd.h`:

- excluded `SetQHYCCDLogFunction` if not C++; it is probably not usable by matlab becauses it uses function handles
- prototype `SetQHYCCDQuit` changed to `QHYCCDQuit`, since the latter is exported by `libqhyccd.so`.  
  What the function does is unknown, but calling it when deleting the QHYccd object, **I got rid
  of matlab crashes** upon subsequent `unloadlibrary('libqhyccd')`
- commented prototype `SetQHYCCDCallBack`, which is probably not usable by matlab becauses it uses function handles
