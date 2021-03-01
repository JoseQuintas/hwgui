@echo off
REM
REM hbmk64.bat
REM
REM $Id$
REM
REM Compile a sample with hbmk2 utility with MinGW64
REM Call script "pfad64.bat" for setting environment variables before usage.
REM
REM =============================================================
REM Only experimental release !
REM Use for compiling a sample "bldmingw64.bat" !!!
REM Because of a bug in utility hbmk2 the created exe-file
REM is corrupt:
REM At start the error "0xc000007b" occured,
REM see image "starterr7b.png" (in german).
REM =============================================================
REM 
REM
REM remove file extension
SET PRGNAME=%~n1
REM
REM SET MINGW_ARCH=-march=x86-64
REM
SET HB_USER_CFLAGS=-march=x86-64 -mwindows -Wl,--allow-multiple-definition
SET HB_USER_LDFLAGS=-march=x86-64 -mwindows -Wl,--allow-multiple-definition
SET HB_CPU=x86_64

REM -trace : see commands for debugging
hbmk2 %PRGNAME% hwgui_xp.rc -trace -gui -i..\include -L..\lib -lhwgui -lprocmisc -lhbxml -lhwgdebug

REM ======================== EOF of hbmk64.bat ==========================
