@echo off
REM
REM $Id$
REM
REM HWGUI source code
REM Set path for MingW + Harbour
REM Pfad fuer MingW + Harbour setzen
REM Created by DF7BE
REM
REM Usable for WinAPI and GTK edition of HWGUI 
REM 
REM Diese Datei  fuer folgende Konstellation:
REM This file for following environment:
REM GCC in C:\MinGW32
REM Harbour created from recent code snapshot (last checked in version, target path see following line)
REM Harbour neu erstellen in C:\harbour\core-master (letzte eingecheckte Version )
REM SET PATH=%PATH%;C:\MINGW\bin;C:\GTK3\bin;C:\make\bin
REM Windows 7
REM SET PATH=%PATH%;C:\hmg.3.3.1\MINGW\bin;C:\GTK\bin;C:\hmg.3.3.1\HARBOUR\bin;C:\make\bin;C:\hwgui\hwgui\bin
REM SET HB_PATH=C:\hmg.3.3.1\HARBOUR
REM Windows 10
SET PATH=C:\Program Files (x86)\Intel\TXE Components\TCS\;C:\Program Files\Intel\TXE Components\TCS\;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Program Files\Intel\TXE Components\DAL\;C:\Program Files (x86)\Intel\TXE Components\DAL\;C:\Program Files\Intel\TXE Components\IPT\;C:\Program Files (x86)\Intel\TXE Components\IPT\;C:\MinGW32\bin;C:\GTK\bin;C:\harbour\core-master\bin\win\mingw;C:\make\bin;C:\cmake\bin;C:\hwgui\hwgui\bin   
SET HB_PATH=C:\harbour\core-master
REM
REM Path extension for Subversion command line client
REM installed in:
REM C:\Apache-Subversion
REM (or use TortoiseSVN)
REM
REM For svn+ssh needed: Putty
REM https://www.putty.org/
REM  Variable: SVN_SSH
REM  Value: C:\\Program Files (x86)\\PuTTY\\plink.exe
SET SVN_SSH=C:\\Program Files\\PuTTY\\plink.exe
PATH=%PATH%;C:\Apache-Subversion\bin;C:\Program Files\PuTTY
REM
REM To connect to Subversion repository via svn+ssh protocol you should explicitly
REM provide SSH tunnel settings in the Subversion configuration file.
REM Please add the following line to the [tunnels] section of the Subversion configuration file
REM %APPDATA%\Subversion\config: 
REM
REM find out setting of this environment variable:
REM C:\svnwork>echo %APPDATA%
REM C:\Users\<user>\AppData\Roaming
REM
REM [tunnels]
REM ssh = "C:/Program Files/TortoiseSVN/bin/TortoisePlink.exe"
REM ==> ssh = "C:/Program Files/PuTTY/plink.exe"
REM 
REM The directory is not visible in the Windows explorer.
REM Open the cmd app an cd to this directory and type:
REM  notepad config
REM
REM If you have trouble to create the tunnel: 
REM via https (works also at best):
REM 
REM C:\svnwork>svn checkout --username=df7be https://svn.code.sf.net/p/cllog/code/ cllog-code
REM Error validating server certificate for 'https://svn.code.sf.net:443':
REM  - The certificate is not issued by a trusted authority. Use the
REM    fingerprint to validate the certificate manually!
REM Certificate information:
REM  - Hostname: code.sourceforge.net
REM  - Valid: from <date+time> GMT until <date+time> GMT
REM  - Issuer: R3, Let's Encrypt, US
REM  - Fingerprint: 6E:28: ...
REM (R)eject, accept (t)emporarily or accept (p)ermanently? p
REM
REM
REM  Error appeared:
REM Repeat the checkout command.
REM Now the repository is checked out.
REM
REM ========================= EOF of pfad.bat ==================================
REM 
