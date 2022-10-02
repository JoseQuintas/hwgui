@echo off
REM
REM bcc_comp.bat
REM
REM $Id$
REM
REM Compile a single C program with Borland C
REM Usage: bcc_comp.bat <C program name with extension .c>
REM
SET BCCINSTDIR=C:\bcc
bcc32 -I%BCCINSTDIR%\include -L%BCCINSTDIR%\lib %1
REM
REM =========================== EOF of bcc_comp.bat ==================================

