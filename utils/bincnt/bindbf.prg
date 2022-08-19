*
* bindbf.prg
*
* $Id$
*
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 * Sample program for usage of images from
 * a DBF file used as Binary container
 *
 * Copyright 2020 Wilfried Brunken, DF7BE 
 * https://sourceforge.net/projects/cllog/
 */
 
 
    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  No

 
#include "hwgui.ch"
#ifdef __GTK__
#include "gtk.ch"
#endif

Memvar oBrw, oFont , oSay1, oSay2

Function Main
LOCAL oWndMain , oPanel

Private oBrw, oFont,  currFname , oSay1, oSay2

  INIT WINDOW oWndMain MAIN TITLE "Dbf binary container" AT 200,100 SIZE 300,300

   oFont := HFont():Add( "Courier",0,-14, , 0 )

  MENU OF oWndMain
     MENU TITLE "&Quit"
       MENUITEM "&Exit" ACTION oWndMain:Close()
     ENDMENU
     MENU TITLE "&File" ID 31000
       MENUITEM "&New" ACTION bindbf_CreateDbf()
       MENUITEM "&Open"+Chr(9)+"Alt+O" ACTION FileOpen() ACCELERATOR FALT,Asc("O")
     ENDMENU
     MENU TITLE "&Edit" ID 31001
       MENUITEM "&Add File" ACTION bindbf_addfile()
       MENUITEM "&Export File" ACTION bindbf_expfile()
     ENDMENU      
     MENU TITLE "&Help"
       MENUITEM "&About" ACTION hwg_Msginfo("Dbf Binary Container Sample" + Chr(10) + "2022" )
     ENDMENU
   ENDMENU

  @ 0,0 BROWSE oBrw                 ;
      SIZE 300,272                   ;
      STYLE WS_VSCROLL + WS_HSCROLL  ;
      FONT oFont                     ;
      ON SIZE {|o,x,y|o:Move(,,x-1,y-28)}
   
      oBrw:nHCCharset := 0 

   @ 0,272 PANEL oPanel SIZE 0,26 ON SIZE {|o,x,y|o:Move(0,y-26,x-1)}
   @ 5,4 SAY oSay1 CAPTION "" OF oPanel SIZE 150,22 FONT oFont
   @ 160,4 SAY oSay2 CAPTION "" OF oPanel SIZE 100,22 FONT oFont

      hwg_Enablemenuitem( ,31001,.F. )  

     ACTIVATE WINDOW oWndMain

Return Nil

* ==============================================
Static Function FileOpen( fname )
* ==============================================

LOCAL cdirSep , mypath

Memvar oBrw, currFname , oSay1, oSay2

cdirSep := hwg_GetDirSep()
mypath := cdirSep + CURDIR() + IIF( EMPTY( CURDIR() ), "", cdirSep )


   IF Empty( fname )
      fname := hwg_Selectfile( "xBase files( *.dbf )", "*.dbf", mypath )
   ENDIF
   IF !Empty( fname )
      close all
       use (fname)

      currFname := CutExten( fname )
 * Start BROWSE
      oBrw:InitBrw( 2 )
      oBrw:active := .F.
      hwg_CreateList( oBrw,.T. )
      Aadd( oBrw:aColumns,Nil )
      Ains( oBrw:aColumns,1 )
      oBrw:aColumns[1] := HColumn():New( "*",{|v,o|Iif(Deleted(),'*',' ')},"C",1,0 )
      oBrw:active := .T.
      oBrw:nHCCharset := 0 
      oBrw:Refresh()
      oSay1:SetText( "Records: "+Ltrim(Str(Eval(oBrw:bRcou,oBrw))) )
      oSay2:SetText( "" )
 //     dbv_cLocate := dbv_cSeek := ""
 //     dbv_nRec := 0

      hwg_Enablemenuitem( ,31000,.F. ) 
      hwg_Enablemenuitem( ,31001,.T. )	  

   ENDIF

RETURN NIL

* ==============================================
FUNCTION bindbf_addfile()
* ==============================================
LOCAL cdirSep , mypath , fname , cType , cfileful
cdirSep := hwg_GetDirSep()
mypath := cdirSep + CURDIR() + IIF( EMPTY( CURDIR() ), "", cdirSep )

fname := hwg_Selectfile( "All files( *.* )", "*.*", mypath )

IF EMPTY(fname)
 RETURN NIL
ENDIF
* Process file name
     cfileful := fname
     cType := FilExten( fname )
     fname := CutExten(CutPath(fname))

IF EMPTY(cType)
 hwg_MsgStop("File name must have an extension","Add file")
 RETURN NIL
ENDIF 

* Now copy selected file into memo field
APPEND BLANK
IF DELETED()
 RECALL
ENDIF 
REPLACE BIN_CITEM WITH fname
REPLACE BIN_CTYPE WITH cType
REPLACE BIN_MITEM WITH bindbf_RDFILE(cfileful)

bindbf_brwref()

RETURN NIL


* ==============================================
FUNCTION bindbf_WRFILE(cfilename,mm)
* ==============================================

* Debug
// LOCAL nbytes := 0 ,  binmm
// binmm := hwg_cHex2Bin(mm)
// hwg_MsgInfo("Bytes written : " + ALLTRIM(STR(LEN(binmm))) )

hb_MemoWrit(cfilename, hwg_cHex2Bin(mm) )

RETURN NIL


* ==============================================
FUNCTION bindbf_RDFILE(cfilename)
* ==============================================

* Debug
// LOCAL mm
// mm := hwg_HEX_DUMP(MEMOREAD(cfilename), 4 )
// hwg_MsgInfo("Bytes read :  " + ALLTRIM(STR(LEN(mm))) )
// RETURN mm

RETURN hwg_HEX_DUMP(MEMOREAD(cfilename), 4 )


* ==============================================
FUNCTION bindbf_expfile()
* Export in current directory
* ==============================================
LOCAL citem, ctype
FIELD BIN_CITEM,  BIN_CTYPE , BIN_MITEM

 citem := ALLTRIM(BIN_CITEM)
 ctype := ALLTRIM(BIN_CTYPE)
 
  IF EMPTY(citem)
   hwg_MsgStop("File name is empty","File export")
   RETURN NIL
  ENDIF 
 
  IF EMPTY(ctype)
   hwg_MsgStop("File extension is empty","File export")
   RETURN NIL
  ENDIF 

  bindbf_WRFILE ( citem  + "." + ctype , BIN_MITEM )
  
  hwg_msgInfo("File " + citem  + "." + ctype + " written")

RETURN NIL

* ==============================================
FUNCTION bindbf_brwref
* ==============================================
 Memvar oBrw
 oBrw:Refresh()
RETURN NIL

* ==============================================
FUNCTION bindbf_CreateDbf()
* Creates the DBF collecting binaries,
* if not exists
* Returns:
* 0 : database exists
* 1 : Empty database created
* ==============================================
LOCAL cName , frm_newDBFname , lcancel

LOCAL oLabel1, oEditbox1, oButton1, oButton2

cName := SPACE(25)
lcancel := .T. 

  INIT DIALOG frm_newDBFname TITLE "Enter name of new DBF file" ;
    AT 647,171 SIZE 516,252 ;
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE

   @ 26,24 SAY oLabel1 CAPTION "Enter name of new DBF file without extension .dbf"  SIZE 415,22   
   @ 34,65 GET oEditbox1 VAR cName SIZE 401,24 ;
        STYLE WS_BORDER     
   @ 39,119 BUTTON oButton1 CAPTION "OK"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| lcancel := .F. , frm_newDBFname:Close() }
   @ 324,119 BUTTON oButton2 CAPTION "Cancel"   SIZE 105,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| frm_newDBFname:Close() }

   ACTIVATE DIALOG frm_newDBFname


  IF lcancel
   RETURN NIL
  ENDIF 
  
  cName := ALLTRIM(cName)

// cName := "sample"

   IF hb_vfExists( cName + ".dbf" )
      hwg_MsgStop("File " + cName + ".dbf already exist !", "Create new DBF file")
      RETURN NIL
   ENDIF

   dbCreate( cName, { ;
      { "BIN_CITEM"    ,  "C",  25, 0  } , ;
      { "BIN_CTYPE"    ,  "C",  10, 0  } , ;
      { "BIN_MITEM"    ,  "M",  10, 0  } ;     && Memo field contains the contents of the binary file
      } )

   hwg_MsgInfo("Database " + cName +  ".dbf created !", "Create new DBF file")  

RETURN 1

* ======================== EOF of bindbf.prg ====================== 