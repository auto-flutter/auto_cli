# Auto Cli

A command line tool that can play back `Auto` files and output test reports, and can be integrated with automation systems (e.g. Jenkins)

## Installation

#### 1. Install Auto Cli
```
dart pub global activate auto_cli   #(Need dart sdk and sdk>=2.12.0-0)
```
or

[Releases Node](https://github.com/auto-flutter/auto_cli/releases)

#### 2. Install Auto Util
See [Auto Util](https://github.com/auto-flutter/auto_util)

## Usage

```
auto_cli --help
```
```
exitCode: 0(OK) 2(ERROR)
-a, --auto=<test/test.auto>                     Path of auto file
-o, --out=<test/test.autor>                     The output path
-h, --host=<127.0.0.1>                          Host
-p, --port=<7001>                               Port
                                                (defaults to "7001")
    --android-package=<com.example.auto>        Android package
    --[no-]android-restart                      Restart the application before playback (Need adb)
    --android-serialno=<emulator-5554>          use device with given serial
-f, --[no-]force                                Force start playback
-t, --threshold=<0.8>                           Image matching threshold
                                                (defaults to "0.8")
```
