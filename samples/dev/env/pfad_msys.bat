@echo off
REM
REM pfad_msys.bat
REM
REM Path to HWHUI is C:\Msys64\hwgui\hwgui
SET HB_PATH=C:\Msys64\harbour\core-master
SET HRB_EXE=%HB_PATH%\bin\win\mingw64\harbour.exe
SET PATH=%PATH%;C:\msys64\mingw64\bin;C:\Msys64\usr\bin;C:\Msys64\harbour\core-master\bin\win\mingw64;C:\Msys64\make\bin;C:\Msys64\cmake\bin
REM GTK 3
SET PKG_CONFIG_PATH="C:\msys64\mingw64\lib\pkgconfig;C:\Msys64\usr\lib\pkgconfig;C:\Msys64\usr\share\pkgconfig;C:\Msys64\lib\pkgconfig"
REM =========== EOF of pfad_msys.bat ===========