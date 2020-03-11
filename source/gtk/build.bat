@echo off
REM
REM $Id$
REM
REM create gtk+-Libraries of hwgui for Win32
REM (Cross develop environment on Windows for GTK)
REM
REM Created by DF7BE
REM
REM Warning:
REM For normal use on Windows it is strictly recommended to build only the WinAPI
REM edition of HWGUI and your application. The WinAPI functions are quite stable and
REM effective.
REM Take the GTK build only for test- and development purposes ! 
REM Also it is strictly recommended to check the modified GTK sources
REM on Linux or another *NIX operating system before checking in into
REM a source repository.
REM For details read instructions in file
REM samples\dev\MingW-GTK\Readme.txt

REM Configure PATH of Harbour compiler to your own needs
REM Default setting by Makefile.mingw:
REM C:/harbour/core-master/bin/win/mingw
REM set HB_ROOT=C:\hmg.3.3.1\HARBOUR

if not exist ..\..\bin md ..\..\bin
if not exist ..\..\lib md ..\..\lib
if not exist ..\..\obj md ..\..\obj

REM  -d  Print lots of debugging information.
make -fMakefile.mingw
REM ============ EOF of build.bat =================

