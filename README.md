# Thermal Photobooth

## Capture images on a web cam and print them with an Epson receipt printer
As seen at Open Sauce 2024

Requires the following:

* fswebcam
* inotify
* feh, with inotify support
* lpr
* Epson receipt printer, with working drivers, set as default

Works well with a USB 10-key keypad, ideally with key repeat disabled in xset.  Defaults to using /dev/video0 as the input device.  Change the constant near the beginning of the file, to select a different device.

Key bindings:

* 'q': quit
* '0' or 'Enter': print
* '+': reprint
* '*': zoom in
* '/': zoom out
* '5': default zoom

Usage: download photobooth.sh, edit it if necessay, mark it as executible, disable key repeat with xset, and execute it, without any arguments.

If the image isn't updating, inotify may not be working or feh may not be compiled to use it.  Also, even when working, feh doesn't update very quickly; there's probably a better solution.

