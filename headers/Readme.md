### Modifications made to the original headers so that they work with Matlab: ###

- excluded `SetQHYCCDLogFunction` if not C++ in `qhyccd.h`
- excluded three `OSX..`. prototypes if not macintosh in `qhyccd.h`
- commented prototype `SetQHYCCDQuit` in `qhyccd.h`, which is missing in `libqhyccd.so`

The set of alternate headers for working in conjunction of SDK v4.0.1 included more
modifications, see previous versions of this file.