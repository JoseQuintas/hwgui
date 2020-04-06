@echo off
REM
REM clean.bat
REM
REM $Id$
REM
REM Extended clean
REM this BAT
REM removes all *.o,  *.a and *.exe
REM of a HWGUI build with samples and utils.
REM
REM Created by DF7BE
REM
REM === Remove all libraries ===
REM Do not delete libpcre.a (GTK cross development environment) 
del lib\libhbxml.a 2> NUL
del lib\libhwgdebug.a 2> NUL
del lib\libhwgui.a 2> NUL
del lib\libprocmisc.a 2> NUL
REM === Remove all obj files ===
del obj\*.o 2> NUL
REM === Remove EXE, C, O ===
REM Using build script for MinGW or hbmk2: *.c and *.o 
REM are removed, if compiled with success. 
REM 1. Samples
del samples\*.exe 2> NUL
REM 2. GTK samples
del samples\gtk_samples\*.exe 2> NUL
REM 3. Utils
del utils\tutorial\*.exe 2> NUL
REM del utils\tutorial\*.c
REM del utils\tutorial\*.o
del utils\bincnt\*.exe 2> NUL
del utils\dbc\*.exe 2> NUL
del utils\debugger\*.exe 2> NUL
del utils\designer\*.exe 2> NUL
del utils\editor\*.exe 2> NUL
REM
REM ===== EOF of clean.bat =====
