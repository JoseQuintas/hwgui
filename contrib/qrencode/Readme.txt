QR encode library ready for integration into HWGUI
--------------------------------------------------


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


*) Build script only build the library, not the
   sample and demo program. 

Build scripts for other compilers are delivered 
as soon as possible.

 
2.2) Steps to install QR-Code-generator
 
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

-  Change to build directory:
  cd QR-Code-generator-master
  cd c
  
- Copy the desired build script from HWGUI environment
  in directory "contrib\qrencode".  

- Start build process:
  
  MinGW: make -f Makefile.mingw
  LINUX: make (usage of the Makefile delivered by archive of QR code generator)

- Copy header file "qrcodegen.h" to contrib\qrencode\include 
  
- copy library "libqrcodegen.a" or "libqrcodegen.lib"
  to the HWGUI "lib" directory.
  The file extensions depends of the used compiler.

- Optional: the temporary build directory is not needed any more,
  delete it.


2.3) Steps to build HWGUI interface module:
     - hbmk2 qrencode.hbp
     - Check, that the library for the HWGUI interface module
       "libqrcodegen.<ext> "is created in the HWGUI "lib" directory.
       <ext>: a, or lib or ?

2.4) Test with sample program
   
     cd samples
     hbmk2 qrencode.hbp
     qrencode.exe

     Read the generated QR code with the smart phone,
     the HWGUI porject site must be opened.

    

2.5) Final instructions.

Be shure, that the following options are inserted in 
your *.hbp or Makefile:

-L../lib

-lqrcodegen
-lhbqrencode 


=============== EOF of Readme.txt ======================== 