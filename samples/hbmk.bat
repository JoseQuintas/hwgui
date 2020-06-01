REM @echo off
REM
REM hbmk.bat
REM
REM $Id$
REM
REM Compile sample program with hbmk2 utility.
REM
rem set path=c:\hb30\bin;c:\hb30\comp\mingw\bin
rem set path=c:\hb30\bin;c:\borland\bcc55\bin
hbmk2 %1 hwgui_xp.rc -i..\include -L..\lib -lhwgui -lprocmisc -lhbxml -lhwgdebug -gui
REM
REM ====================== EOF of hbmk.bat ============================