
  $Id$

Extra information about HWGUI sample programs
=============================================  
  
This directory contains additional information about
sample programs.

It is recommended to delete files or information,
if the program is successfully ported or
a bug is fixed.
Then put the description about the way of fix or port as 
inline comment into the source code,
if this information is helpful for the user.

The subdirectory "image" contains screenshots of
sample programs.


1.) propsh.prg: (to be continued)   
    Property sheet, freezes at hwg_PropertySheet(),
    the sheet is not visible.
    The property sheet feature is Windows only,
    so a special solution for LINUX/GTK is necessary.
    The resources are only build with the
    Borland C resource workshop, so
    the port of this resources is done.
    The line with hwg_PropertySheet() is deactived
    by commenting out and the two dialog windows 
    are activated with ACTIVATE DIALOG in sequence
    to check the design of the Borland resources.
    The subdirectory contains 4 files with
    screen snapshot of the design,
    2 compiled with Borland, the other ones
    with MinGW and ported HWGUI commands.
     propsh_bcc_c1.png  propsh_bcc_c2.png
     propsh_mingw_c1.png  propsh_mingw_c2.png
     
    The recent sample program contains now the
    port of Borland resources to HWGUI commands,
    so the bugfixing process can be continued
    on all compilers, preferred is MinGW.
    The contents of the old rc file was preserved
    as inline comment. 
    
2.) bincnts.prg
    The images of the binary container do not appear.
    A special solution is write the resources from the
    container into temporary files and load then from
    there.
    The handling of resources does not work in the way like Windows.
    
    The icon appears OK.
    
3.) grid_5.prg 
    Grid Editor (crashes, if click on button "Insert","Change","Delete")         



Some information for port to GTK/LINUX
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    
 
- grid_1.prg  grid_2.prg  grid_3.prg  grid_4.prg  grid_5.prg
     The grid feature is available with GTK4,
     first released in 2020. Port of HWGUI to GTK4 needed.
     
a.prg : Need for full port TO GTK: 
       HWG_GETCURRENTDIR(), HMDICHILDWINDOW(), HDATEPICKER(), HRECT(),
       HWG_RECT()
       Program gtk_samples/a.prg is a reduced version:
       Removed calls of "Windows only" functions by
       compiler switch
      
hello.prg : Need for full port TO GTK: 
       HRICHEDIT(),
       HWG_RE_SETCHARFORMAT(), HWG_SETTABSIZE(), HWG_MSGTEMP(),
       HWG_GETEDITTEXT(), HWG_SETDLGITEMTEXT(), HWG_PROPERTYSHEET() 
       State: removed calls of "Windows only" functions by
       compiler switch
       screenshots:
        samples/doc/image/Hello_InfoDlg_Win.png
        samples/doc/image/Hello_main_Win.png       

   
    
List of sample programs with bugs
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
(Handle it as a "TO-DO list")
    
bincnts.prg
grid_5.prg 
nice2.prg
stretch.prg
tab.prg
testbrw.prg
testchild.prg
testrtf.prg    
    
    
====================== EOF of Readme.txt =======================================
    
       

