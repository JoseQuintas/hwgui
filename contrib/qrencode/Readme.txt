QR encode library ready for integration into HWGUI
--------------------------------------------------


"QR-Code-generator"


Corrections:    2024-12-12
First creation: 2022-09-07

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
- Borland C with DLL, see extra instructions

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

- Extract the archive "QR-Code-generator-master.zip" in an temporary directory.

-  Change to build directory:
  cd QR-Code-generator-master
  cd c
  
- All Windows platforms:
  Copy the desired build script from HWGUI environment
  in directory "contrib\qrencode" into the temporary directory
  above.
  For example: Makefile.mingw

- Start build process:
  
  MinGW: make -f Makefile.mingw *)
  LINUX: make (usage of the Makefile delivered by archive of QR code generator)
  
  *) Build script only builds  the library and the demo program in C, but not the
   sample and demo program of HWGUI.  

- Copy header file "qrcodegen.h" to contrib\qrencode\include 
  
- copy library "libqrcodegen.a" or "libqrcodegen.lib"
  to the HWGUI "lib" directory.
  The file extension depends of the used compiler.

- Optional: the temporary build directory is not needed any more,
  delete it.


2.3) Steps to build HWGUI interface module:
     - Change to HWGUI directory "contrib/qrencode"
     - hbmk2 qrencode.hbp
     - Check, that the library for the HWGUI interface module
       "libqrcodegen.<ext> "is created in the HWGUI "lib" directory.
       <ext>: a, or lib or ? (depends of the used compiler)

2.4) Test with sample program
   
     cd samples
     hbmk2 qrencode.hbp
     qrencode.exe or ./qrencode
     Press button "Test":
     At first, the size of the QR code image is displayed, press "OK".
     Read the generated QR code with the smart (mobile) phone,
     the HWGUI project site must be opened.
     Quit by "OK", if ready.

    

2.5) Final instructions.

Be shure, that the following options are inserted in 
the *.hbp file or Makefile of your application:

-L../lib

-lqrcodegen
-lhbqrencode

Copy also the generated libraries and the header file
to reach the path's by compile or running task.


2.6) Extra instructions for non C99 standard compiler.

    In this case, the library "contrib\qrencode\qrencode.c"
	cannot be compiled with the compiler not supporting
	the C99 standard.
	Instead the use of a DLL (qrcodegen.dll) is the
	only way to get a running QR code generator.
	The ready to use DLL (compiled with MinGW32)
	can be downloaded from the files section of
	the HWGUI project site a sourceforge.net.
	
	The sample program "qrencodedll.prg"
	demonstrates the usage of the DLL.
    
2.6.1) Borland C	

   - Download the DLL (location see above)
   - Set environment for Borland C, for example:
      C:\hwgui\hwgui-bcc\samples\dev\env\pfad_bc.bat 
   - Compile the sample qrencodedll.prg:
      hbmk2 qrencodedll.hbp
   - Copy the DLL into the sample directory	  
     and run the sample program.
   - Copy the DLL into the directory running your HWGUI application.   
 


=============== EOF of Readme.txt ======================== 
