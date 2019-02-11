### Modifications made to the original headers so that they work with Matlab: ###

- removed includes of `config.h` and `<functional>` in `qhyccd.h`
- added a dummy `config.h`, to avoid modification of `qhyccdcamdef.h` and
  `qhyccderr.h`
- excluded `SetQHYCCDLogFunction` if not C++ in `qhyccd.h`
- excluded three `OSX..`. prototypes if not macintosh in `qhyccd.h`
- empty defines of `EXPORTFUNC` and `EXPORTC` if not C++ in `qhyccdstruct.h`
- typedef'd enum CONTROL_ID in `qhyccdstruct.h`

Note that the headers define a `SetQHYCCDQuit` which is absent in the compiled library.
