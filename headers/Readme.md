# Modifications made to the original headers so that they work with Matlab: #

## In `qhyccd.h`:

- excluded `SetQHYCCDLogFunction` if not C++; it is probably not usable by matlab becauses it uses function handles
- commented prototype `SetQHYCCDQuit`, which is missing in `libqhyccd.so`
- commented prototype `SetQHYCCDCallBack`, which is probably not usable by matlab becauses it uses function handles

The set of alternate headers for working in conjunction of SDK v4.0.1 included more
modifications, see previous versions of this file.