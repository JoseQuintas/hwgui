*
* Readme for HWGUI contrib
*
* $Id$
*
* Additional programs and libraries for HWGUI.
*
* For detailed instructions read 
* HWGUI documentation doc/hwgdoc_misc.htm, "8. Contrib"
*

Contents
========

1.  Directories
2.  Build scripts
2.1 Build instructions



1. Directories
--------------
 
activex:
 Source code for ActiveX control library "libhwg_activex".
 The usage of this library is not recommended, because
 ActiveX is out of support.
 Substituted by HTML5 and Java.
 Detailed description in text file "doc/activex.txt".
 (Windows only)


misc:
  Source code for library "libhwg_misc".
  Additional Functions for:
  - Convert arrays to string
  - Encryption/Decryption functions, using BlowFish algorithm
  - Misc functions:
     ADDMETHOD()
     ADDPROPERTY()
     REMOVEPROPERTY()
     hwg_SetAll()
  - System for generating simple RTF files
  - Functions for "Say Money":
      English   :  SayDollar(nDollar)
      Indonesia :  SayRupiah(nRupiah)
    (It seems, that the function SayDollar() could be also used for
     other currencies like Euro's or british pounds sterling).  
  No detailed description available.
  
 
qhtm:
 Source code for library "libhwg_qhtm".
 Is an interface library for QHTM from GipsySoft.
 For details read HWGUI document:
 doc/hwgdoc_misc.htm, "8.2. Qhtm integration".
 (Windows only)

 
ext_controls:
  Source code for library "libhwg_extctrl".
  Extended class implementations:
  - "HBrowseEx"
  - "HComboBoxEx"
  - "HStaticEx"
  - "HButtonX"
  - "HButtonEX"
  - "HGroupEx"
  - "HStatusEx"
  - "HGridEX"
  - "HContainerEx"
  No detailed description available.
  (Windows only)

  
hwmake:
 Utility to create build files for Borland C (BCC55)
 Build scripts:
   bld.bat  
 Build program with:
   bld.bat hwmake
 (Windows and Borland C Compiler only) 
  


hwreport:
 Visual Report Builder by Alexander S. Kresin.
 Create report forms for following using in
 HWGUI applications. It a substitute for
 the report functions of Clipper (RL.EXE).
 
 For build and usage instructions see file
 "contrib\hwreport\hwreport.txt".

 The usage together with the WinPrn class will be checked as soon as possible
 for validation with modern computers without (outdated) parallel printer interface
 and platforms Windows and Linux.

gthwg:
 GT library, based on HwGUI. Currently it is for winapi version only,
 Linux GTK version will be later.
 
2. Build scripts
----------------

build.sh:
 Build script for LINUX, uses makefile.linux
 
 makemngw.bat    GCC(MinGW)
 make_b32.bat    Borland C
 make_pc.bat     Pelles C Compiler
 make_vc.bat     Microsoft Visual C
 make_w32.bat    Open-Watcom

 
Harbour make files: 
 hbactivex.hbp
 hwg_extctrl.hbp
 hwg_qhtm.hbp
 gthwg.hbp

 
Other makefiles:
 makefile.bc     Borland C
 makefile.gcc    GCC(MinGW)
 makefile.pc     Pelles C Compiler
 makefile.vc     Microsoft Visual C
 makefile.wc     Open-Watcom



2.1 Build instructions
----------------------

Prerequisite is the successful build of Harbour and HWGUI
(or working binary installations).

Only these 4 libraries added in the "lib" directory:
 libhwg_extctrl.a
 libhwg_misc.a
 libhwg_qhtm.a
 libgthwg.a
 (file extension depends of the used compiler , e.g. ".lib")


LINUX:
______

Only "libhwg_misc" can be build.

makefile.linux: configure path to Harbour installation:

# Modify path to Harbour to your own needs 
# HRB_DIR = $(HB_PATH)
HRB_DIR = $(HOME)/Harbour/core-master

HRB_EXE = $(HRB_DIR)/bin/linux/gcc/harbour


Then start build process:
chmod 755
./build.sh



Windows:
________

See special instructions for your C Compiler in directory
  samples\dev
and sub directories (for example valid environment settings).

Start the batch file for your compiler.




* ================== EOF of Readme.txt ====================
