HwGUI rich text Editor
----------------------

 $Id$

Program Author: Alexander S. Kresin


1. Introduction
_______________

The main goal of this project is testing of a class HCEdiExt,
which is intended to be used for an embedded rich text editor in applications,
written on Harbour + HwGUI.

I need an editor with a limited set of features,
which are really needed to create a well-formatted content,
an editor without excess stuff, redundant possibilities,
which are rarely used, but makes the application large and slow.
Besides, I want the file format was similar to html to make it
easy to view and edit it in any plain text editor and to convert
it to html. And, finally, I want to have few special features,
such as embedded calculator, access control to certain parts of the document,
which I find useful and plan to use in my applications.

Read more information in file "editor.hwge", open it with the editor in the
"File / Open" menu.


2. Building editor
__________________

Build the editor with the following build scripts:

bld.bat      Borland C    
bldedgw.bat  MinGW32
bldow.bat    Open Watcom C
build.sh     gcc, GTK/LINUX 
bldgtk.bat   GTK cross development environment on Windows
             (only for test and development purposes)
hbmk.sh      For hbmk2 utility on GTK/LINUX (alternative)

For prerequisites read the file "install.txt" in the base directory of the HWGUI package.


3. Files
________


editor.hwge  Documentation file 

Source code:

  editor.prg
  calc.prg
  hcediext.prg
  hcedit.ch



editor.hbp        Makefile for hbmk2 utility
editor_linux.hbp  Makefile for hbmk2 utility on GTK/LINUX


-------------------------- EOF of Readme.txt -------------------------


 


