@echo off

set HRB_DIR=\harbour
set HWGUI_INSTALL=..\..

set path=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\\Extensions\Microsoft\IntelliCode\CLI;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.29.30133\bin\HostX86\x86;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\VC\VCPackages;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\CommonExtensions\Microsoft\TestWindow;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\bin\Roslyn;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\Tools\devinit;C:\Windows Kits\10\bin\10.0.19041.0\x86;C:\Windows Kits\10\bin\x86;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\\MSBuild\Current\Bin;C:\Windows\Microsoft.NET\Framework\v4.0.30319;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\Tools\;C:\Program Files (x86)\Common Files\Oracle\Java\javapath;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\;c:\softools\git\usr\bin;c:\tools;c:\tools\arh;c:\harbour\bin;d:\softools\mingw_w64\mingw32\bin;c:\borland\bcc55\bin;c:\softools\git\cmd;c:\softools\subversion\bin;C:\Program Files\OpenVPN\bin;C:\softools\Go\bin;C:\softools\Python\Scripts\;C:\softools\Python\;C:\Users\SYSADMIN\AppData\Local\Microsoft\WindowsApps;c:\softools\go\bin;d:\svn;c:\Program Files\Java\jdk1.8.0_231\bin;C:\Users\SYSADMIN\go\bin;c:\softools\cmake\bin;;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja
set include=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.29.30133\ATLMFC\include;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.29.30133\include;C:\Windows Kits\10\include\10.0.19041.0\ucrt;C:\Windows Kits\10\include\10.0.19041.0\shared;C:\Windows Kits\10\include\10.0.19041.0\um;C:\Windows Kits\10\include\10.0.19041.0\winrt;C:\Windows Kits\10\include\10.0.19041.0\cppwinrt
set lib=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.29.30133\ATLMFC\lib\x86;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.29.30133\lib\x86;C:\Windows Kits\10\lib\10.0.19041.0\ucrt\x86;C:\Windows Kits\10\lib\10.0.19041.0\um\x86
set LIBPATH=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.29.30133\ATLMFC\lib\x86;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.29.30133\lib\x86;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.29.30133\lib\x86\store\references;C:\Windows Kits\10\UnionMetadata\10.0.19041.0;C:\Windows Kits\10\References\10.0.19041.0;C:\Windows\Microsoft.NET\Framework\v4.0.30319

%HRB_DIR%\bin\harbour %1.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include %2 %3

cl /c /TP /W3 /nologo /Fo -I%HRB_DIR%\include -I%HWGUI_INSTALL%\include %1.c

echo %HWGUI_INSTALL%\lib\vc\hwgui.lib  > b32.vc
echo %HWGUI_INSTALL%\lib\vc\procmisc.lib  >> b32.vc
echo %HWGUI_INSTALL%\lib\vc\hbxml.lib  >> b32.vc

echo %HRB_DIR%\lib\win\msvc\hbdebug.lib >> b32.vc
echo %HRB_DIR%\lib\win\msvc\hbrtl%HB_MT%.lib >> b32.vc
echo %HRB_DIR%\lib\win\msvc\hbvm%HB_MT%.lib >> b32.vc
echo %HRB_DIR%\lib\win\msvc\gtwin.lib >> b32.vc
echo %HRB_DIR%\lib\win\msvc\gtgui.lib >> b32.vc
echo %HRB_DIR%\lib\win\msvc\hblang.lib >> b32.vc
echo %HRB_DIR%\lib\win\msvc\hbcpage.lib >> b32.vc
echo %HRB_DIR%\lib\win\msvc\hbmacro%HB_MT%.lib >> b32.vc
echo %HRB_DIR%\lib\win\msvc\hbrdd%HB_MT%.lib >> b32.vc
echo %HRB_DIR%\lib\win\msvc\rddntx%HB_MT%.lib >> b32.vc
echo %HRB_DIR%\lib\win\msvc\rddcdx%HB_MT%.lib >> b32.vc
echo %HRB_DIR%\lib\win\msvc\rddfpt%HB_MT%.lib >> b32.vc
echo %HRB_DIR%\lib\win\msvc\hbcommon.lib >> b32.vc
echo %HRB_DIR%\lib\win\msvc\hbpp.lib >> b32.vc
echo %HRB_DIR%\lib\win\msvc\hbhsx.lib >> b32.vc
echo %HRB_DIR%\lib\win\msvc\hbsix.lib >> b32.vc
echo %HRB_DIR%\lib\win\msvc\hbcplr.lib >> b32.vc
echo %HRB_DIR%\lib\win\msvc\hbzlib.lib >> b32.vc
if exist %HRB_DIR%\lib\win\msvc\hbpcre.lib echo %HRB_DIR%\lib\win\msvc\hbpcre.lib >> b32.vc
if exist %HRB_DIR%\lib\win\msvc\hbwin.lib echo %HRB_DIR%\lib\win\msvc\hbwin.lib >> b32.vc

echo user32.lib >> b32.vc
echo gdi32.lib >> b32.vc
echo comdlg32.lib >> b32.vc
echo shell32.lib  >> b32.vc
echo comctl32.lib >> b32.vc
echo winspool.lib >> b32.vc
echo advapi32.lib >> b32.vc
echo winmm.lib >> b32.vc
echo ws2_32.lib >> b32.vc
echo iphlpapi.lib >> b32.vc
echo OleAut32.Lib >> b32.vc
echo Ole32.Lib >> b32.vc

link -SUBSYSTEM:WINDOWS %1.obj @b32.vc
del %1.c
del %1.obj
del b32.vc
