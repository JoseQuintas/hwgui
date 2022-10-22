QR encode library ready for integration into HWGUI
--------------------------------------------------

<under construction>

"QR-Code-generator"

Date: 2022-09-07

1.) Copyright of this library

"QR-Code-generator-master.zip"

Copyright (c) Project Nayuki. (MIT License)

The version in the "Files" section is tested with HWGUI.
Optional get recent version from:


https://www.nayuki.io/page/qr-code-generator-library

https://github.com/nayuki/QR-Code-generator

The QR code was returned as pure text and 
it is converted to a bitmap with extra HWGUI functions.

2.) Installation instructions.

2.1) Supported compiler

At this time only the following compiler are supported:
- MinGW32
- MinGW64 (also with Msys2 environment)
- GTK/LINUX with gcc

Build scripts for other compilers are delivered 
as soon as possible.
 
2.2) Steps to install
 
- On Windows, start path script concerning the used compiler,
  for example:
  pfad.bat
 
- make command reachable ?
  make --version
  GNU Make 3.81
  Copyright (C) 2006  Free Software Foundation, Inc.
  This is free software; see the source for copying conditions.
  There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A
  PARTICULAR PURPOSE.

  If not, see HWGUI installation instruction for Windows.
  
- Compile Harbour and HWGUI with the desired compiler.  

- Extract the archive in an temporary directory.

- 
  



copy library "libqrcodegen.a" to the HWGUI "lib" directory.


=============== EOF of Readme.txt ======================== 