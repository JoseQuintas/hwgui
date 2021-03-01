*
* Readme.txt
*
* $Id$
*

Welcome to HWGUI.
HwGUI is a cross-platform GUI library for Harbour, it is written on C and Harbour.

Get newest version from the project page on Sourceforge:
https://sourceforge.net/projects/hwgui/

Supported platforms:
- Windows 32, runs also best on Windows 64, using WinAPI function calls.
- LINUX with gcc and GTK V2.
  (GTK V3 is under construction)

Not supported yet on other platforms:
Try to make experiments, if
a suitable C compiler, GTK 2 and Harbour
is available for your platform.
If you have success, please create a support ticket
and post us your description (appended as a text file).
We are interested in running HWGUI applications on
Android an MacOS. 


First steps
~~~~~~~~~~~

- License information see file
  "license.txt".

- Release notes in file
  "whatsnew.txt".

- Installations instructions:
  Read file "install.txt".
  Need to install a suitable C compiler,
  GTK 2 (only for LINUX) and Harbour as prerequisites.

- Documentation:
  You find the full documentation in HTML format
  in directory "doc".
  Start with "hwgdoc.html".

- Learn more about Harbour and HWGUI:
  1.) Compile the editorial in directory "utils/tutorial",
      modify and run the programs in the tutorial application.
  2.) Sample programs in directory "samples".
      Read file "Readme.txt" for compile and run the samples.
      This file contains also advanced information
      for beginners.
  Based on this, now you can start with your own HWGUI application.

- HWGUI Designer
  In directory "utils/designer" compile and run this
  utility to create and edit forms for HWGUI.
  The forms are stored in XML files.
  The function for creating HWGUI source code
  is outdated and works not perfect. The generated
  HWGUI code needs some work before it is
  ready for insert in your source code.
  Creating a checkbox, the designer crashes, if
  writing form to *.prg file.
  A suitable workaround is, to create a static text element
  starting with "X ..." and modify the generated source code,
  so it is now a checkbox command (for example):
  @ <x>,<y> SAY olabel1 CAPTION "X ... abcdef" SIZE <x>,<y>
  to
  @ <x>,<y> GET CHECKBOX oCheckbox1 "abcdef" SIZE <x>,<y> 
    
  But there are samples enough to use this xml files
  in your application to display forms.
  


Lead old Clipper programs into the future
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Before starting the port to HWGUI,
it is recommended to compile the old Clipper application with Harbour
to detect incompatible code sequences (for example assembler modules).
Only a few lines must be added in the main section to have a working
console or terminal program, if the old program is written in pure Clipper. 
The Syntax of old Clipper Summer 1987 is understood 
by the Harbour compiler.

In the last step, start the port to HWGUI to get a modern style GUI program.

Read file "doc/port.txt" for details.


===================== EOF of Readme.txt ===============================




  

- 
  
