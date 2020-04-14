List of HWGUI sample programs for WinAPI
========================================

$Id$

Created by DF7BE

1.) Learn more about HWGUI with this sample programs.

For beginners:

1.1.) Read the Article of Alexander Kresin "Harbour for Beginners", it is a very good introduction
      into Harbour programming language: 
      http://www.kresin.ru/en/hrbfaq.html

1.2.) Compile and run the editorial in directory utils\tutorial
      Interactive - because you
      can not only read the code and comments, but execute it. Moreover,
      you can edit the code and then execute it immedeately to see the
      results of your changes.

2.) List of build scripts for several compiler:

    bld.bat       Borland C
    bld4dll.bat   Borland C, build program which uses harbour.dll
    bldmingw.bat  GCC(MinGW)
    bldgw.bat     GCC(MinGW), alternative script 
    bldpc.bat     Pelles C Compiler 
    bldvc.bat     Microsoft Visual C  
    hbmk.bat      Using hbmk2 utility


3.) Sample Database
    Contains 150 records with fields every type, open with a.prg or dbview.prg
     sample.dbf
     sample.dbt

4.) List of sample programs

    Special sample programs for GTK in directory "gtk_samples".
    The list contains only the main programs.
    Some of the programs are also ready for GTK, they are marked in the GTK column with "Y".

    Some samples could not be compiled or are crashing, hope that we can fix the bugs if we have time,
    see remarks in "Purpose" column, marked with # sign (Test with MingW, recent Harbour Code snapshot).

 Sample program     GTK   Purpose
 =================  ===   =====
 a.prg              N     Some HWGUI basics (Open DBF's, GET's, ...)
 buildpelles.prg    N     Build APP using Pelles C Compiler (*.bld file)
 colrbloc.prg       Y     BROWSE: arrays and DBF's with colored lines and columns
 dbview.prg         Y     DBF access (Browse, Indexing, Codepages, Structure, ... )
 demodbf.prg        Y     Demo for Edit using command NOEXIT
 demohlist.prg      N     Demo for listbox
 getupdown.prg      Y     Usage of @ <x> <y> GET UPDOWN ..
 graph.prg          Y     Paint graphs (Sinus, Bar diagram)
 grid_1.prg         N     Grid demo (HGrid class)
 grid_2.prg 2)      N     Grid demo, use Postgres Library, you need to link libpq.lib and libhbpg.lib
 grid_3.prg 2)      N     Grid demo, use Postgres Library, you need to link libpq.lib and libhbpg.lib
 grid_4.prg         N     File Viewer
 grid_5.prg         N  #  Grid Editor  (crashes, if click on button "Change") 
 hello.prg          N     Some elements: Edit field, tabs, tree view, combobox, ...
 helpdemo.prg       N     Context help using windows help (Shellexecute crashes)
 hole.prg   2) 4)   N     MS Agent Control  
 iesample.prg 2) 5) N     Sample of ActiveX container for the IE browser object. 
 modtitle.prg       N     Sample for modifying a main window title in HWGUI
 nice.prg           N     Demo of NICEBUTTON
 nice2.prg          N  #  Seems to be outdated, starts only in background, kill with Task Manager
 progbars.prg       N     Progress bar
 propsh.prg	        N     Property sheet, INIT DIALOG aDlg1 FROM RESOURCE not working.
 pseudocm.prg       Y     Pseudo context menu
 shadebtn.prg       N     Shade buttons
 tab.prg            N  #  missing function(s): hb_enumIndex(), resource DIALOG_1 not working
 test_bot.prg       N     bOther Test: Press key, after key up the scan code is displayed.
 testbrw.prg        N     Another BROWSE test
 testchild.prg      N  #  Create a child windows; child window not created ! command seems to be outdated.
 testget1.prg       N     Get system: Edit field, Checkboxes, Radio buttons, Combo box, Datepicker 
 testget2.prg       N     Get system: Colored edit fields, time display, Tooltip ballon, HD serial number 
 testhmonth.prg     Y     Calendar, Datepicker, TOOLTIP
 testini.prg        N     Use INI file: create and read 
 testmenubitmap.prg N     Menu with bitmaps
 testrtf.prg  1)    N     Create Rich text files.
 testsdi.prg        Y     Tree control
 testspli.prg       Y     Split windows
 testtray.prg       N  #  Tray Message: No exported method: HANDLE
 testtree.prg       Y     Tree view control
 testxml.prg        N     reading/writing XML file and handling menu items while run-time (testxml.xml)
 trackbar.prg       N     Trackbar demo, horizontal und vertical.
 tstcombo.prg       N     Test Combobox (crashes on GTK)
 tstprdos.prg  3)   N     Print on LPT, outdated, see 3)
 tstscrlbar.prg     N     Scrollbar (GTK: Compilable, but no scroll function)
 tstsplash.prg 	    N     SPLASH Demo, displays image at start as logo for n millisecs: OK with WinAPI, compilable for GTK, but splash window is empty. 
 winprn.prg  3)     Y     Printing via Windows GDI Interface (same sample in gtk_samples)
 xmltree.prg        Y  #  Show XML-Tree: compiles with warning , crashes with "No exported method: AITEMS".
 
 1) Sample program needs extra libraries of HWGUI, build them in directory "contrib".

 2) Sample program needs external prerequisites.
 
 3) Because recent computer systems have no printer interfaces any more, it is strictly recommended,
    to use the Winprn class for Windows and Linux/GTK for all printing actions. The Winprn class contains a good
    print preview dialog. If you have a valid printer driver for your printer model installed,
    your printing job is done easy (printer connection via USB or LAN).

 4) Sample program needs MS Agent, outdated.
    Not contained in Windows 7 and higher, support ended.

 5) Sample program needs ActiveX and contrib library "libhbactivex.a".
    Support for ActiveX ended, substituted by HTML5 and Java. Sample is outdated. 
