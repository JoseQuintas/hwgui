Cross develop environment on Windows for GTK
============================================

  $Id$
  
Created by DF7BE  

Warning:
For normal use on Windows it is strictly recommended to build only the WinAPI
edition of HWGUI and your application. The WinAPI functions are quite stable and
effective.
Take the GTK build only for test- and development purposes ! 
Also it is strictly recommended to check the modified GTK sources
on Linux or another *NIX operating system before checking in into
a source repository.
For details read instructions in file
samples\dev\MingW-GTK\Readme.txt


Introduction: Purpose of this file set
______________________________________

With this file set you can create an GTK edition of HWGUI and
your application to develop and test it on Windows for an "*NIX" target
operating system. 

With the compiler switch:

#ifdef __GTK__
...
#else
...
#endif
you are able to create or edit only one file for all targets.

The same for: 

#ifdef __LINUX__
...
#else
...
#endif


Installing the two HWGUI editions (WinAPI and GTK) in different directories,
you can switch from WinAPI to GTK and back very easy.
You need only use two different make scripts.
Enjoy and many success !


Instructions
____________

1.) Prerequisites
-----------------

You need some files and binary packages from the internet for Win32
(Works well on Windows 10 64bit).
Consult your preferred internet search engine.

1.1) Suggested useful tools for development
     (Preferred by me, always you can use your own preferred tools)

   - Notepad++ : Editor with a lot of functions.
      Search for file "xbase.xml" or "harbour.xml" and import the programming language for
      syntax highlightning of Harbour source code.
      (Supports UTF-8, line endings for Windows/Dos, UNIX and MacOs)

   - 7zip      : Archiver for many formats, e.g. ZIP, tar.gz ...

   - WinMerge  : A mighty diff and merge tool.
 
 1.2.) MingW compiler bundle
      
       Install the bundle concerning to the instructions of MinGW.
       
       Alternative is HMG.3.3.1 or later (easy to intall).
        It has an MinGW compiler and an old Harbour release inside.
        This old Harbour is not used.
        Default installation path is C:\hmg.3.3.1.
 
 1.3.) libpcre.a
 
  It is an old version, but is working well.
   17.03.2007  10:56            19.068 libpcre.a
 
 1.4.) pcre3.dll
 
 It is an old version too, but is also working well.
   17.03.2007  10:56           140.288 pcre3.dll
 
 1.5.) GTK2 Bundle:

  gtk+-bundle_2.24.10-20120208_win32.zip
  
  Create new directory C:\GTK and extract the contents of the archive here.
  
  In this directory you must find this sub directories:

     bin
     etc
     include
     lib
     man
     manifest
     share
     src
  

  
 1.6.) GNU make tool:
 
   make-3.81-bin.zip
   make-3.81-dep.zip
 
  Create new directory C:\make and extract the contents of the archive here.
  
    In this directory you must find this sub directories:

     bin
     contrib
     man
     manifest
     share
 
 
 
 2.) Pre tasks:
 --------------

  Before buiding HWGUI the followings task must be done.

 2.1.) Set PATH
 
  There are two ways to set a PATH:
   - The System Admin dialog 
   - Using a .bat:
     I used this, because no modification of the System is necessary.
     You find a sample scripte here:
       samples\dev\MingW-GTK\pfad.bat
     Modify this script to your own needs:
      1.) Say in a command window:
           echo %PATH%
          Catch the output and paste it after the SET command:
        SET PATH=C:\Program Files ...
      2.) At the end of line add the new entry:
           ;C:\hmg.3.3.1\MINGW\bin;C:\GTK\bin;C:\harbour\core-master\bin\win\mingw; ...
            (Modify the values if necessary) 
          Attention: The command must be written into only one line !
      3.) Modify the value of HB_PATH

  Start the batch.
  (necessary for all following steps)  

 2.2.) Check prerequisites
 
  GTK2:
    pkg-config --cflags gtk+-2.0
     Are all options displayed ?
    gtk-demo
     Is the "GTK+ Code Demos" application running ?

  Make tool:
  C:\make>make --version
     GNU Make 3.81
     Copyright (C) 20...

  MinGW:
   C:\make>gcc --version
     gcc (GCC) 4.6.2
     Copyright (C) 2011 Free Software Foundation, Inc.
     ...
  
  2.3.) Build Harbour
     Install the recent code snapshot of Harbour.
     See build instructions of Harbour:
      Goto to base directory of Harbour (for example C:\harbour\core-master)
      and enter "make"      
 

 
  3.) Build HWGUI for GTK 
  -----------------------
  
      cd C:\hwgui\hwgui-gtk\hwgui\source\gtk (Sample install path)
      build.bat

      After build, look into directory "lib" for creating these 4 libraries:
       libhbxml.a
       libhwgdebug.a
       libhwgui.a
       libprocmisc.a  
 
     copy  libpcre.a into lib dir of HWGUI:
       C:\hwgui\hwgui-gtk\hwgui\lib (Sample path)
 

     copy  pcre3.dll into the run time path of your application
       (for example: C:\cltest) or into another
      directory set in PATH environment variable:
      A possible directory is:
        C:\gtk\bin
      (I think, this is the best location)
 
  4.) Build and test a HWGUI example:
       cd C:\hwgui\hwgui-gtk\hwgui\samples\gtk_samples
       hwmingnw.bat a
       a.exe
  
  5.) Copy 2 files to compile environment of your application
        samples\gtk_samples\hwmingnw.bat
        samples\gtk_samples\sleep.c

        Compile your application with "hwmingnw.bat"

     Hints:
      - You must see the icon of GTK in the top left corner of the main window
        of the running application.
      - Using the term "SET PROCEDURE TO ..." you need no makefile.
        All components (*.prg modules) of your application are compiled complete,
        if they are placed in the current directory.
      - Don't forget, that file names on *NIX operations systems are
        case sensitive. I suggest to write all file names in lower case.

  6.) Use your Script for WinAPI edition of your application
      for build the final release for Windows.

  7.) Copy your source code to the *NIX system and test it there.

  
Have fun an many success

With reagards 

Wilfried Brunken, DF7BE

  
  

 
 