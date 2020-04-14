List of HWGUI sample programs for GTK
=====================================

$Id$

Created by DF7BE

1.) Learn more about HWGUI with this sample programs.
    Read also instriction in file (WinAPI):
     samples\Readme.txt


2.) Build-Scripts:
     - build.sh      LINUX
     - bldgw.bat     old version for MinGW, better use hwmingnw.bat !
     - hwmingnw.bat  GTK/Windows (Cross development environment,
       read instructions for use in file samples\dev\MingW-GTK\Readme.txt)

3.) List of GTK sample programs

    The list contains only the main programs.
    Some of the programs are also ready for WinAPI, they are marked in the WinAPI column with "Y".

    Some samples could not be compiled or are crashing, hope that we can fix the bugs if we have time,
    see remarks in "Purpose" column, marked with # sign (Test with MingW, recent Harbour Code snapshot).


 Sample program     GTK/LINUX GTK/Win  WinAPI    Purpose
 =================  ========= =======  ======    ===================
   
   
a.prg    2)         Y         Y        N         Some HWGUI basics (Open DBF's, GET's, ...) 
dbview.prg          Y         Y        N         DBF access (Browse, Indexing, Codepages, Structure, ... )
escrita.prg 3)      Y         Y        N         "Teste da Acentuação", tool buttons with bitmaps
example.prg         Y         Y        Y         HFormTmpl: Load forms from xml file.                   
graph.prg           Y         Y        Y         Paint graphs (Sinus, Bar diagram)
progbars.prg 4)     Y         N        Y         Progress bar: compilable, but progress bar not appreared
pseudocm.prg        Y         Y        Y         Pseudo context menu
testget2.prg        Y         Y        Y         Get system: several edit fields (date, password, ...), time display 
winprn.prg   1)     Y         N        Y         Printing via Windows GDI Interface

1)  Because recent computer systems have no printer interfaces any more, it is strictly recommended,
    to use the Winprn class for Windows and Linux/GTK for all printing actions. The Winprn class contains a good
    print preview dialog. If you have a valid printer driver for your printer model installed,
    your printing job is done easy (printer connection via USB or LAN).

2)  a.prg: Browse problem with Char field

3)  escrita.prg: Text in toolbuttons not visible

4)  progbars.prg: LINUX: Progbar create ok, but press button "Step" the progbar disappeared.

