Experiences and attempts while installing QHY software
======================================================

+ QHY has an [user forum](https://www.qhyccd.com/bbs/index.php) with a lot of information
 and semiconstant company support. It took me a bit to register
 on it and start pestering, because of registration captcha idiosyncracies. Note that there are also complaints on
 the forum, especially about the sloppy linux support. Btw, the SDK is closed source, only the compiled libraries are
 provided.

+ All I could find describing the API to the SDK is
 [this](https://www.qhyccd.com/index.php?m=content&c=index&a=show&catid=127&id=167).
 Information is to be digged out in the fora, in files in the
 windows version of the SDK, etc. (for instance, `qhyccd.h` from the
 [Qt demo](https://www.qhyccd.com/file/repository/latestSoftAndDirver/Soft/SDKDemo%20for%20Qt%20Creator%20MinGW%205.6.3.zip)
 is somehow commented). What comes closest to a "manual" is
 [this set of foum posts](https://www.qhyccd.com//bbs/index.php?topic=5903.0) (one post - one function). Ridicolous.

+ The publication state of a low level API of raw USB commands to QHY cameras is unclear.
 [Some partial information](https://www.qhyccd.com/index.php?m=content&c=index&a=show&catid=127&id=168)
 is out there, but a general API is
 ["announced"](https://github.com/qhyccd-lzr/QhyCmosCamera).

Making that work:
-----------------

+ got what is said to be the
 [latest SDK](http://www.qhyccd.com/file/repository/latestSoftAndDirver/SDK/V4.0.12/LINUX_qhyccd_V20190122_0.tgz)
 as per [this announcement](https://www.qhyccd.com/index.php?m=content&c=index&a=show&catid=127&id=163).
The [version on github](https://github.com/qhyccd-lzr/QHYCCD_Linux_New)
seems less up to date.
The latest SDK comes in the form of a `.tgz` which has to be extracted in `/` __(!!!)__.
Remember to clean it up someday at the end with something like

        sudo rm -rf `tar -tf LINUX_qhyccd_V20190122_0.tgz`

    It includes installation instructions in `/usr/local/doc/` which might(?) be still relevant.

+ Plugging in the camera in the SS-USB port, if all goes well the relevant firmware is downloaded and the camera is registrered so that the QHY sdk can find it. According to: [this post](https://www.qhyccd.com/bbs/index.php?topic=5781.0]) there used to be a missing step if the camera is plugged into an USB-3 port. My experience is a bit inconclusive. On my
 office computer the backpanel has two USB-SS ports, but plugging the camera there, with one cable I couldn't get it recognized, with another yes but apparently only at USB-2 speed. To check, if all goes well, `dmesg` would report

        [182031.652088] usb 3-2: new high-speed USB device number 38 using xhci_hcd
        [182031.782879] usb 3-2: New USB device found, idVendor=1618, idProduct=c367
        [182031.782886] usb 3-2: New USB device strings: Mfr=1, Product=2, SerialNumber=3
        [182031.782891] usb 3-2: Product: WestBridge 
        [182031.782895] usb 3-2: Manufacturer: Cypress
        [182031.782899] usb 3-2: SerialNumber: 0000000004BE
        [182032.420093] usb 3-2: USB disconnect, device number 38
        [182032.788072] usb 3-2: new high-speed USB device number 39 using xhci_hcd
        [182032.919343] usb 3-2: New USB device found, idVendor=1618, idProduct=c368
        [182032.919350] usb 3-2: New USB device strings: Mfr=1, Product=2, SerialNumber=0
        [182032.919354] usb 3-2: Product: Q367-Cool
        [182032.919358] usb 3-2: Manufacturer: QHYCCD
    `lsusb` would say `Bus 003 Device 039: ID 1618:c368` (the camera model is actually 36**7**c, boh),
    but `lsusb -t` reports it as connected at 480Mbs and not at 5000Mbs

        /:  Bus 04.Port 1: Dev 1, Class=root_hub, Driver=xhci_hcd/2p, 5000M
        /:  Bus 03.Port 1: Dev 1, Class=root_hub, Driver=xhci_hcd/2p, 480M
            |__ Port 2: Dev 39, If 0, Class=Vendor Specific Class, Driver=, 480M

    If the process doesn't complete, after the `USB disconnect` there would be no reconnection
    as device+1 with `Manufacturer: QHYCCD`. In this condition `dmesg` will also periodically report

        [32848.904044] usb usb4-port2: Cannot enable. Maybe the USB cable is bad?

    However all is fine, like this, for another (USB-2) port:

        [46366.484024] usb 1-1.4: new high-speed USB device number 14 using ehci-pci
        [46366.576913] usb 1-1.4: New USB device found, idVendor=1618, idProduct=c367
        [46366.576916] usb 1-1.4: New USB device strings: Mfr=1, Product=2, SerialNumber=3
        [46366.576917] usb 1-1.4: Product: WestBridge 
        [46366.576918] usb 1-1.4: Manufacturer: Cypress
        [46366.576919] usb 1-1.4: SerialNumber: 0000000004BE
        [46366.799145] usb 1-1.4: USB disconnect, device number 14
        [46366.996027] usb 1-1.4: new high-speed USB device number 15 using ehci-pci
        [46367.090147] usb 1-1.4: New USB device found, idVendor=1618, idProduct=c368
        [46367.090150] usb 1-1.4: New USB device strings: Mfr=1, Product=2, SerialNumber=0
        [46367.090151] usb 1-1.4: Product: Q367-Cool
        [46367.090153] usb 1-1.4: Manufacturer: QHYCCD

    and a `Bus 001 Device 015: ID 1618:c368`.

    In contrast, the camera plugged in the USB-SS port of my ubuntu18 laptop was correctly recognized
    (Cypress, disconnect, QHYCCD) and the camera worked out of the box at 5Gbs. No `fxload` step needed, as the
    forum says, thus. Probably that was necessary only with former SDK.

    To add to the ambiguity, the camera kept working (but at 480Mbs) when plugged (without turning off) back
    into the USB-SS port of the desktop computer. It stopped working when turned off and on again. I presume
    that this depends on the persistence of the formerly downloaded firmware.

+ Got [EZCAP for ubuntu16](https://www.dropbox.com/s/e9i0vntj14dgmh0/EZCAP_Qt-for-Ubuntu-x86_64-0.1.51.2.deb?dl=0)
  linked at https://www.qhyccd.com/bbs/index.php?topic=6333.0
  ([also here](https://www.qhyccd.com/file/repository/latestSoftAndDirver/Soft/EZCAP_QTLatestEdition.deb.zip)).
  An EZCAP-Qt shortcut ends out being
  installed in Applications/Programming, the program is launched with `/usr/bin/EZCAP/EZCAP.sh`.

+ Surprisingly, EZCAP finds the camera, even without having asked `fx3load` to download specific firmware
(which I thought was the one found in `/usr/local/lib/qhy/firmware/`). It runs
a bit clunky, but works and shows things.

+ The other demos in https://www.qhyccd.com/index.php?m=content&c=index&a=show&catid=127&id=166
 are for windows :(

As for interfacing with Matlab
------------------------------

+  Note that `libqhyccd.so` (v.20190122 but apparently also earlier) "forgets" to declare its dependency
   from `libusb-1.0,` as can be seen from
   `readelf -d /usr/local/lib/libqhyccd.so`. The intended use seems to have been only that of building
   executables, linked at compile time with the system version of libusb found by a Cmake script.
   Several symbols from `libusb` are thus needed and undefined, as clear from
   `nm -D /usr/local/lib/libqhyccd.so | grep "U libusb"`. Matlab interfacing (mex or `loadlibrary`)
   would give ultimately the error `/usr/local/lib/libqhyccd.so: undefined symbol: libusb_open`.
   A possible workaround is to start matlab from shell with `LD_PRELOAD=/lib/x86_64-linux-gnu/libusb-1.0.so.0 matlab`
   but there may be more elegant solutions.

+ I could compile the
[Matlab demo](http://qhyccd.com/file/repository/latestSoftAndDirver/SDK/MatlabSDKdemo.zip),
(which is intended for windows) on Linux, with a couple of tweaks. However, it is just a
single c++ program which gets built as mex, not a way to interface directly with the SDK library.

+ A more flexible way seems to me to use `loadlibrary('libqhyccd')`, because it gives
  granular access to the SDK functions at matlab prompt. To succeed in this, the header
  files have to be tweaked a little in order to be made more C like so that matlab parses them.

+ See [here](https://www.qhyccd.com/bbs/index.php?topic=6038.msg31725#msg31725) for explanations
  why a color image is 3x8bit wnen a camera is capable of 16bit.

+ On a windows 10 machine with Visual Studio 2017 I haven't yet been able neither to run the mex-demo,
  nor to loadlib the dll. The former gives compilation errors, with the latter the showstopper seems
  the inclusion of CyAPI.h which is pure C++.
