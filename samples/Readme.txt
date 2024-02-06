List of HWGUI sample programs for WinAPI
========================================

$Id$

Created by DF7BE

1.) Learn more about HWGUI with this sample programs.

For beginners:

1.1.) Read the Article of Alexander Kresin
      "Harbour for Beginners",
      it is a very good introduction
      into Harbour programming language: 
       http://www.kresin.ru/en/hrbfaq.html
      Hint for offline reading:
      Download the *.chm file with complete manual
      and extract it with 7zip. Now you can open the
      HTML files with your preferred browser. 

1.2.) Compile and run the editorial in directory utils\tutorial
      Interactive - because you
      can not only read the code and comments, but execute it. Moreover,
      you can edit the code and then execute it immediately to see the
      results of your changes.

2.) List of build scripts for several compiler:

    bld.bat           Borland C
    bld4dll.bat       Borland C, build program which uses harbour.dll
    bldmingw.bat      GCC(MinGW), 32 bit
    bldmingw64.bat    GCC(MinGW), 64 bit
    bldgw.bat         GCC(MinGW), alternative script 
    bldpc.bat         Pelles C Compiler 
    bldvc.bat         Microsoft Visual C  
    hbmk.bat          Using hbmk2 utility
    sample.hbp        Sample skript for hbmk2 utility, modify to your own needs
                      (works for Windows and LINUX)
    hwmingnw-gtk.bat  Only for Cross Development Environment for GTK on Windows, GCC(MinGW), 32 bit

    For Compiler support look into text files of directory:
     samples/dev/compiler
     samples/dev/env        (Environment scripts for Windows)
     samples/dev/MinGW64
     samples/dev/MingW-GTK  (Cross Development Environment for GTK on Windows)

    Start compile using *.hbp files:
     hbmk2 <filename>.hbp


     <prgname>.hbp   For hbmk2 utility, one file for every sample program.

     allhbp.hbp      All builds:
                     Builds on one call:
                     - HWGUI basic libraries
                     - Contrib libraries (directory "contrib")
                     - Utilities (directory "utils")
                     - Sample programs (directory "samples" and "samples/gtk_samples")



3.) Sample Database
    Contains 150 records with fields every type, open with a.prg or dbview.prg
     sample.dbf
     sample.dbt

    Record Nr. 2 contains signs for codepage IBM858DE with german Umlaute (ÄÖÜäöü),
    sharp "S" (ß), Euro currency sign (€) and greek mue (µ) for SI system as prefix for
    parts per million. Select this codepage as data CP in dbview.prg. Select 
    DEWIN or UTF-8 for Linux as Local codepage for correct display. Do this
    before opening a dbf file ! (data codepage was set at open time of dbf).


4.) List of sample programs

    Special sample programs for GTK in directory "gtk_samples".
    The list contains only the main programs.

    Some of the programs are also ready for GTK, they are marked in the GTK column with "Y".
    If the program is marked with "R", the "Windows only" functions are deactived by compiler
    switch "#ifdef __GTK__", so the program runs also on GTK.
    Read the inline comments of this sample to get information of the reduced feature set.

    Mark "S" mentioned a "Windows only" sample program, which have a
    multiplatform sample with available substitute(s) of the Windows only 
    function.

    Mark "P" (planned) means, that the port to GTK is under construction.

    "N": Port is not possible yet or make no sense,
    because of "Windows only" functions and commands.


    If sample program also ready for GTK (Mark "Y" or "R"):

    Compile forever with
     hbmk2 <prefix>.hbp

    Some samples could not be compiled or are crashing, hope that we can fix the bugs if we have time,
    see remarks in "Purpose" column, marked with # sign (Test with MingW, recent Harbour Code snapshot).

    NLS: National language support could be possible (P) or is implemented, activate it with
    little modifications (Y).

    MinGW64: Successfull tested 64 bit support with MinGW.
    Use only script "bldmingw64.bat" for building sample and environment settings of file "pfad64.bat".
    Y: Run OK, W: compiled with warnings, -: not (yet) tested ,
    C: can not be compiled , N: error at runtime

    Special marks for column "GTK3":
    Space: Not yet tested.
    "X"  : runs with no errors at runtime.
    "E"  : Compilable, but errors at runtime.
    "-"  : Not compatible.



5.) Further Versions of this samples used resource files (*.rc) from the Borland Resource Workshop.
    The port of this files to HWGUI commands for multi platform usage is completed.
    It is strictly recommended, for new applications avoiding the usage of any resource files.
    But for complete iconification the usage of a resource compiler is necessary, more
    information see documentation "doc/hwgdoc.html", chapter "3.11. Handling resources".
 
    Creating and editing forms use the HWGUI utility "Designer"
    in directory "utils/designer".

6.) Resources compiled into exe files:
    To avoid trouble with missing resource files, use the conversion of them
    into hex value.
    See instructions in utils/bincnt/Readme.txt
    An alternative method is to use the "Binary Container Manager" to collect
    all resource files in one database.
    See sample programs "hello.prg" and "bincnts.prg".

7.) GTK3
    The port to GTK3 is under construction yet.
    Some of these samples are crashing at run time.
    The cross development environment on Windows does only work for GTK2.
    Compile the sample program with GTK3 with the concerning *.hbp
    file, but edit it like this:

     {win}../hwgui.hbc
     # GTK2
     {linux}../hwgui.hbc
     # GTK3: Deactivate previous line
     # and activate following line
     #{linux}../hwguiGTK3.hbc

    so modify to:
      # {linux}../hwgui.hbc
       ...
      {linux}../hwguiGTK3.hbc
      
    Ignore warning at build time:
      Unknown option -e



 Sample program     GTK2    GTK3  NLS MinGW64 Purpose
 =================   ====   ====  === ======= =======
 a.prg   +) 9)       R       N    CN          Some HWGUI basics (Open DBF's, GET's, ...)
 arraybrowse.prg     Y                        Array BROWSE avoiding crashes because of bugs (see inline comments)
 bindbf.prg 10)      Y                        Usage of images from Binary DBF container
 bincnts.prg 10) +)  Y                        Usage of images from Binary container
 bitmapbug.prg       Y                        Handle of bug in command @<x>,<y> BITMAP ... SHOW (Class HBITMAP) 
 buildpelles.prg     N       N         Y      Build APP using Pelles C Compiler (*.bld file)
 checkbox.prg        Y                        Checkboxes and tabs
 colrbloc.prg        Y                 Y      BROWSE: arrays and DBF's with colored lines and columns
 datepicker.prg      Y                        Multiplatform substitute of Windows only DATEPICKER
 dbview.prg          Y       Y         Y      DBF access (Browse, Indexing, Codepages, Structure, ... )
 demodbf.prg         Y                 Y      Demo for Edit using command NOEXIT
 demohlist.prg       S       S         Y      Demo for listbox
 demohlistsub.prg    Y                 Y      Multi platform substitute for listbox by BROWSE.
 Dialogboxes.prg     Y                        Demonstrates few ready to use dialog boxes (extract from tutor)
 escrita.prg   +)    Y       Y                Tool buttons with bitmaps ("Accent Test")
 fileselect.prg      Y                        Sample for file selection menues
 getupdown.prg       Y                        Usage of @ <x> <y> GET UPDOWN ..
 GetWinVers.prg      Y                        Functions for get recent hwg_SaveFile() Windows version
 graph.prg           Y                        Paint graphs (Sinus, Bar diagram)
 grid_1.prg     +)   N       N         Y      Grid demo (HGrid class)
 grid_2.prg 2)  +)   N       N         -      Grid demo, use Postgres Library, you need to link libpq.lib and libhbpg.lib
 grid_3.prg 2)  +)   N       N         -      Grid demo, use Postgres Library, you need to link libpq.lib and libhbpg.lib
 grid_4.prg     +)   N       N         Y      File Viewer
 grid_5.prg     +)   N       N         -      Grid Editor
 hello.prg      +)   R                        Some elements: Edit field, tabs, tree view, combobox, ...
 helpdemo.prg 6) 7)  N       N                Context help using windows help (Shellexecute crashes)
 helpstatic.prg      Y                        Static help text
 hexbincnt.prg 11)   Y                        Handling of binary resources with hex values.
 hole.prg   2) 4)    N       N                MS Agent Control
 htrack.prg          Y                        Demo of HTRACK class as substitute for Windows only HTRACKBAR
 icons.prg           Y                        Icons and background bitmaps
 icons2.prg          Y                        Icons and bitmaps using hex values
 iesample.prg 2) 5)  N       N                Sample of ActiveX container for the IE browser object.
 menumod.prg         Y                        Handling menu items while run-time in dialogs.
 modtitle.prg        Y                        Sample for modifying a main window title in HWGUI
 nice.prg            N       N                Demo of NICEBUTTON
 nice2.prg           N  #    N         -      Demo of NICEBUTTON (2), starts only in background, kill with Task Manager
 night.prg           Y                        "ADD HEADER PANEL" for a night mode application
 progbars.prg  12)   Y                        Progress bar
 propsh.prg +)       N  #    N                Property sheet, freezes at hwg_PropertySheet()
 pseudocm.prg        Y                        Pseudo context menu
 qrencode.prg 1) 2)  Y                        Encode QR code from string an convert to monochrome bitmap.
 qrencodedll.prg 1)  N       N                Encode QR code like qrencode.prg by using a DLL
 shadebtn.prg        N       N                Shade buttons
 simpleedit.prg      Y                        Simple text editor demonstrating hwg_Memoedit() and hwg_MemoCmp()
 stretch.prg         Y  #                     Sample for resizing bitmaps (background), some bugs (as test program)
 tab.prg             Y  #              -      Sample for Tabs
 Testado.prg         N       N                Test program sample for ADO Browse (TNX Itamar M. Lins Jr.)
 testalert.prg       N       N                Clipper style Alert() replacement, delivered by Alex Strickland (TNX !)
 test_bot.prg        P                        bOther Test: Press key, after key up the scan code is displayed.
 testbrw.prg         Y  #                     Another BROWSE test (bug on GTK see docu)
 testchild.prg       N  #    N         -      Create a child windows; child window not created ! command seems to be outdated.
 testget1.prg        Y                        Get system: Edit field, Checkboxes, Radio buttons, Combo box, Datepicker 
 testget2.prg        Y       Y                Get system: Colored edit fields, time display, Tooltip ballon, HD serial number
 testfunc.prg        Y       Y         Y      Test and demo of standalone HWGUI (hwg_*) functions, enable/disable button. 
 testhgt.prg         N       N                class HGT for combined usage of HWGUI control elements in Harbour gtwvg programs in multithread mode.
 testhmonth.prg      Y                 Y      Calendar, Datepicker, TOOLTIP
 testimage.prg       Y       Y                Displaying images and usage of FreeImage library (IMAGE, BITMAP).
 testini.prg         P                        Use INI file: create and read
 testmenubitmap.prg  P                        Menu with bitmaps
 testrtf.prg  1)     Y  #    N          -      Create Rich text files. Need some work, the created RTFs are not compatible with newest specifications. (TO-DO for Alexander Kresin) 
 testsdi.prg         Y                        Tree control
 testspli.prg        Y                        Split windows
 testtray.prg        Y                 Y      Tray Message : Be care of different behavior between WinAPI and GTK
 testtree.prg        Y                        Tree view control
 testxml.prg         Y                        reading/writing XML file and handling menu items while run-time (testxml.xml)
 trackbar.prg        P                        Trackbar demo, horizontal und vertical.
 tstcombo.prg        Y                        Test Combobox, with preset and refresh.
 tstprdos.prg 3)     N       N                Print on LPT, outdated, see 3)
 tstscrlbar.prg      P                        Scrollbar (GTK: Compilable, but no scroll function)
 tstsplash.prg       P                        SPLASH Demo, displays image at start as logo for n millisecs: OK with WinAPI, compilable for GTK, but splash window is empty.
 TwoListbox.prg      S       S                Sample for select and move items between two listboxes.
 TwoLstSub.prg       Y                        Multi platform substitute for two listboxes by BROWSE windows.
 winprn.prg  3) 8)   Y            Y    Y      Printing via Windows GDI Interface (same sample in gtk_samples)
 xmltree.prg         Y                 YW     Show XML-Tree: Open "testxml.xml" for test.

Directories:
============


 doc                                  Because this file is a summary,
                                      this directory contains additional information about
                                      these sample program, here we report all facts about
                                      state of port to LINUX/GTK and known and bugfixing
                                      and many more hints (for example older sample source code
                                      only for Borland C).
                                      Subdirectory "image" may contain screen shots and other
                                      images.
                                      Extra information for usage of a sample may often
                                      written in the inline comments of the source code.
                                      If extra information is availabe for a sample programm,
                                      it is marked in this file with "+)"

 MariaDb     2)     ?                 Sample CRUD DBF and MariaDb
                                      Delivered by Itamar M. Lins Jr. (TNX !)
                                      Attention, sample not checked by HWGUI developer team.


 +) Additional information for this sample program available in subdirectory "doc".

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

 6) Sample is outdated.
    Shellexecute crashes because of this:
    Following the article in the magazine "Funkamateur", issue May 2020,
    page 417, "Winhelp unter Windows 10 - die zweite Version" by Dr. Thomas Baier, DG8SAQ:
    The files of the Windows help system are automatically removed at every Windows update.
    Alan Rowe, M0PUB, has delivered a special installation package to recover the function
    of the old help system on Windows 10. Download from:
     https://www.funkamateur.de/downloads-zum-heft.html
     File: dg8saq_winhelp2.zip (273 KB)
    Be care of the installation archive, store it at a secure place, because you need it at every
    greater Windows update.
    Instructions:
    - Extract the archive
    - click with right mouse button to file "Install.cmd" and say
      "Als Administrator ausführen" (Execute as Administrator).
    - Compile and run sample "helpdemo.prg", Press F1 and the help program starts in an
      extra window.

 7) We suggest to create an own help system in your application to be independent of
    a foreign help system. There are several possibilities for storing:
    - As an XML file: There are classes in HWGUI supporting XML.
      Could be edited with a normal text editor.
      But for lot of help info it is not easy to handle.
    - As a normal textfile: It could content topic marks like
      the man format of UNIX to find the desired help text of a help topic.
    - Use of a help database (like old Clipper feature "SET KEY F1 TO HELP").
      For editing it could be handled easier. Also an index for quick access can be used.
      Get a sample from application CLLOG:
       https://sourceforge.net/projects/cllog/
      Look for source file "hilfew.prg" and "helpedit.prg" (Console app), also 
      help Database "hilfe.dbf/dbt" (sub directory "hilfe").
      A big inline comment block (english and german) in "hilfew.prg"
      explains the usage of this help system.
      The same help database could be used in HWGUI and Harbour console applications.
      The best way to call a help topic is to create a "Help" button in every
      dialog of your application.

  8) A "Y" mark in column "GTK" says, that this sample also runs best on LINUX.
     Samples with this footmark may have a misfunction on GTK Windows cross development environment.
     They are compilable, but some functions do not work correct.
     Because this environment is not recommended for normal use on windows, this/these misfunction(s)
     is/are irrelevant. In future, we try to describe the bugs in the inline comments of the sample program.
     
  9) MinGW64: Syntax error in rc file, hex values not allowed any more, must be following:
     <name> BITMAP "<file.bmp>"

 10) Binary container manager: See instructions in inline comment. For this sample a
     sample binary container is stored here: image/sample.bin.
     It contains all images needed for this sample.
     For creating and editing binary container you find the utility "Binary container manager"
     in directory "utils/bincnt".
     Binary DBF container manager: See instructions in inline comment.
     Sample container:  bindbf.dbf and bindbf.dbt
     For creating and editing binary DBF container you find the utility "Binary container manager"
     in directory "utils/bincnt".

 11) Read more about the handling of hex value resources in file "utils/bincnt/Readme.txt".

 12) Little modifications for GTK needed (use compiler switch "#ifdef __GTK__").
     Extra sample program with same filename in subdirectory "gtk_samples"

* =================== EOF of Readme.txt ========================


