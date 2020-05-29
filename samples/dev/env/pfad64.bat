@echo off
REM Pfad fuer HWGUI  + Harbour setzen
REM Set Path for HWGUI and Harbour compile
REM (MinGW 64 bit)
REM (c) Copyright 2020 DF7BE
REM  License: GPL V2 
REM 
REM Version fuer folgende Konstellation
REM MinGW64
REM Harbour neu erstellen in C:\harbour64\core-master (letzte eingecheckte Version )
REM SET PATH=%PATH%;C:\MINGW\bin;C:\GTK3\bin;C:\make\bin
REM Windows 7
REM SET PATH=%PATH%;C:\hmg.3.3.1\MINGW\bin;C:\GTK\bin;C:\hmg.3.3.1\HARBOUR\bin;C:\make\bin;C:\hwgui\hwgui\bin
REM SET HB_PATH=C:\hmg.3.3.1\HARBOUR
REM Windows 10
SET PATH=C:\Program Files (x86)\Intel\TXE Components\TCS\;C:\Program Files\Intel\TXE Components\TCS\;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Program Files\Intel\TXE Components\DAL\;C:\Program Files (x86)\Intel\TXE Components\DAL\;C:\Program Files\Intel\TXE Components\IPT\;C:\Program Files (x86)\Intel\TXE Components\IPT\;C:\cmake\bin;C:\MINGW64\bin;C:\harbour64\core-master\bin\win\mingw64;C:\make\bin;C:\hwgui\hwgui64\bin   
SET HB_PATH=C:\harbour64\core-master
SET HRB_EXE=%HB_PATH%\bin\win\mingw64\harbour.exe
SET HB_COMPILER=mingw64
SET HB_PLATFORM=win
REM
 
