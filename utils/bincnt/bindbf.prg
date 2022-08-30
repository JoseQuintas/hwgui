*
* bindbf.prg
*
* $Id$
*
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 * Binary container manager for
 * DBF files used as binary container
 *
 * Copyright 2022 Wilfried Brunken, DF7BE 
 * https://sourceforge.net/projects/cllog/
 */
 
 
    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  No

* All entries (file name and type) are always stored in lower case,
* so handle exchange from LINUX/UNIX <==> Windows
 
#include "hwgui.ch"
#ifdef __GTK__
#include "gtk.ch"
#endif


Memvar oBrw, oFont , oSay1, oSay2 , oMenuBrw , nrp

Function Main
LOCAL oWndMain , oPanel 

Private oBrw, oFont,  currFname , oSay1, oSay2 , oMenuBrw

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
       MENUITEM "&Add/Replace File" ACTION bindbf_addfile()
       MENUITEM "&Export File" ACTION bindbf_expfile()
       MENUITEM "&Delete" ACTION  bindbf_delete()
       MENUITEM "&Recall" ACTION  bindbf_recall()
       MENUITEM "&Search"  ACTION dbfcnt_dlgsea()
       MENUITEM "&Export all" ACTION bindbf_expall()
       SEPARATOR
       MENUITEM "&Pack"  ACTION dbfcnt_pack()
       MENUITEM "&Zap database" ACTION dbfcnt_zap()
     ENDMENU      
     MENU TITLE "&Help"
       MENUITEM "&About" ACTION hwg_Msginfo("Dbf Binary Container Sample" + Chr(10) + "2022" )
     ENDMENU
   ENDMENU

   
   CONTEXT MENU oMenuBrw
       MENUITEM "&Delete"   ACTION  bindbf_delete()
       MENUITEM "&Recall"   ACTION  bindbf_recall()
       MENUITEM "&Add/Replace File" ACTION bindbf_addfile()
       MENUITEM "&Export File" ACTION bindbf_expfile()
       MENUITEM "Show &Bitmap" ACTION bindbf_shbitmap()   
   ENDMENU
   

  @ 0,0 BROWSE oBrw                 ;
      SIZE 300,272                   ;
      STYLE WS_VSCROLL + WS_HSCROLL  ;
      FONT oFont                     ;
      ON SIZE {|o,x,y|o:Move(,,x-1,y-28)} ;
      ON RIGHTCLICK { |o, nrow, ncol| SUBMNU_BRW( ncol, nrow ) }
   
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
LOCAL cdirSep , mypath , fname , cType , cfileful , lreplace
cdirSep := hwg_GetDirSep()
mypath := cdirSep + CURDIR() + IIF( EMPTY( CURDIR() ), "", cdirSep )

fname := hwg_Selectfile( "All files( *.* )", "*.*", mypath )

IF EMPTY(fname)
 RETURN NIL
ENDIF
* Process file name
     cfileful := fname
     cType := Lower(FilExten( fname ))
     fname := Lower(CutExten(CutPath(fname)))

IF EMPTY(cType)
 hwg_MsgStop("File name must have an extension","Add file")
 RETURN NIL
ENDIF

lreplace := .F.
 
IF dbfcnt_exist(fname,cType,.F.)
  // hwg_MsgStop("File entry exist, not added","Add file")
  lreplace := hwg_MsgYesNo("File entry exist, replace","Add/Replace file")
  IF .NOT. lreplace
    RETURN NIL
  ENDIF
  * Seek to entry to replace
  dbfcnt_seek(fname,cType,.F.,.F.)
ELSE 
* Add new
 APPEND BLANK
 IF DELETED()
  RECALL
 ENDIF 
ENDIF
*
* Now copy selected file into memo field
REPLACE BIN_CITEM WITH fname
REPLACE BIN_CTYPE WITH cType
REPLACE BIN_MITEM WITH bindbf_RDFILE(cfileful)

IF lreplace
 hwg_MsgInfo("File replaced : " + fname + "." + cType)
ELSE
 hwg_MsgInfo("File added : " + fname + "." + cType)
ENDIF 

bindbf_brwref()

RETURN NIL


* ==============================================
FUNCTION bindbf_delete()
* ==============================================
IF .NOT. DELETED()
  DELETE
ELSE
  hwg_MsgInfo("Record always deleted")
ENDIF
bindbf_brwref()
RETURN NIL

* ==============================================
FUNCTION bindbf_recall()
* ==============================================
IF  DELETED()
  RECALL
ELSE
  hwg_MsgInfo("Records always recalled")
ENDIF
bindbf_brwref()
RETURN NIL

* ==============================================
FUNCTION bindbf_WRFILE(cfilename,mm,cdir)
* Returns .T., if file is written
* cdir : Directory to write file
* If NIL, current directory (default)
* ==============================================
IF cdir == NIL
  cdir := ""
ELSE
  cdir := cdir + hwg_GetDirSep()
ENDIF  
* Debug
// LOCAL nbytes := 0 ,  binmm
// binmm := hwg_cHex2Bin(mm)
// hwg_MsgInfo("Bytes written : " + ALLTRIM(STR(LEN(binmm))) )

RETURN hb_MemoWrit(cdir + cfilename, hwg_cHex2Bin(mm) )



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
FUNCTION bindbf_expfile(lmsg,cdir)
* cdir : directory to export.
* IF NIL: Export in current directory (default)
* lmsg: Set to .F., to supress all messages
* Default is .T.
* Returns .T., if file is exported
* ==============================================
LOCAL citem, ctype , lsucc
FIELD BIN_CITEM,  BIN_CTYPE , BIN_MITEM

IF lmsg == NIL
 lmsg := .T.
ENDIF

IF cdir == NIL
 cdir := ""
ENDIF

lsucc := .F.

 citem := ALLTRIM(BIN_CITEM)
 ctype := ALLTRIM(BIN_CTYPE)
 
  IF EMPTY(citem)
   IF lmsg
     hwg_MsgStop("File name is empty","File export")
   ENDIF
   RETURN .F.
  ENDIF 
 
  IF EMPTY(ctype)
   IF lmsg
    hwg_MsgStop("File extension is empty","File export")
   ENDIF
   RETURN .F.
  ENDIF 

  IF EMPTY(cdir)
    lsucc := bindbf_WRFILE ( citem  + "." + ctype , BIN_MITEM )
  ELSE
    lsucc := bindbf_WRFILE ( citem  + "." + ctype , BIN_MITEM , cdir )
  ENDIF

  IF lsucc
   IF lmsg  
     hwg_msgInfo("File " + citem  + "." + ctype + " written")
   ENDIF
  ELSE
   IF lmsg  
     hwg_MsgStop("Error writing file " + citem  + "." + ctype)
   ENDIF
  ENDIF  

RETURN lsucc

* ==============================================
FUNCTION bindbf_expall()
* Export all files in an selected directory
* ==============================================
LOCAL nexp, ndel , nerr , cdir , noldrecno

nexp := 0
ndel := 0
nerr := 0

* 
cdir := hwg_SelectFolder("Select directory to export files")
IF EMPTY(cdir)
 RETURN NIL
ENDIF

noldrecno := RECNO()

GO TOP

DO WHILE .NOT. EOF()
 IF DELETED()
  ndel := ndel + 1
 ELSE
   IF bindbf_expfile(.F.,cdir)
    nexp := nexp + 1
   ELSE
    nerr := nerr + 1
   ENDIF 
 ENDIF 
 SKIP
ENDDO

hwg_MsgInfo("Files exported : " + ALLTRIM(STR(nexp)) ;
 + CHR(10) + "Deleted files not exported : " + ALLTRIM(STR(ndel)) + CHR(10) + ;
 + "Errors : " +  ALLTRIM(STR(nerr)) )

GO noldrecno 


RETURN NIL


* ============================================== 
FUNCTION dbfcnt_pack()
* ==============================================

IF hwg_MsgYesNo("Remove all as deleted marked" + CHR(10) + ;
   "records unrecoverable")
 PACK
 hwg_MsgInfo("All as deleted marked records removed") 

bindbf_brwref()
ENDIF
 
RETURN NIL


* ============================================== 
FUNCTION dbfcnt_zap()
* ============================================== 

IF hwg_MsgYesNo("Are you sure to remove all" + CHR(10) + ;
   "records unrecoverable")
 ZAP
 hwg_MsgInfo("All records removed" + CHR(10) + "Database is now empty") 
 bindbf_brwref()
ENDIF 
 
RETURN NIL


* ============================================== 
FUNCTION dbfcnt_exist(cfile,ctype,lmsg)
* Returns .T., if file exists
* in DBF binary container
* Set lmsg to .F. to suppress message
* Default is .T.
* ==============================================
LOCAL lfound
FIELD BIN_CITEM,  BIN_CTYPE

IF lmsg == NIL
 lmsg := .T.
ENDIF 

GO TOP

IF LASTREC() == 0
 RETURN .F.
ENDIF 

 IF INDEXORD() == 0
*  Without index
  LOCATE FOR ( ALLTRIM(cfile) == ALLTRIM(BIN_CITEM)  ) .AND. ;
             ( ALLTRIM(ctype) == ALLTRIM(BIN_CTYPE)  )
 ELSE
* With  index
  SET SOFTSEEK OFF
 * Exakt seek
  SEEK PADR(cfile + ctype,LEN(cfile + ctype ))
 ENDIF

 
 IF FOUND()
  lfound := .T.
  IF lmsg
    hwg_MsgInfo("Record for file " + ALLTRIM(cfile) + "." + ALLTRIM(ctype) + " found, record number : "  + ;
     ALLTRIM(STR(RECNO() )), ;
     "Duplicate record found" )
  ENDIF  
 ELSE
  lfound := .F.
 ENDIF
 
 bindbf_brwref()
 
 RETURN lfound
 
 
 
 * ============================================== 
FUNCTION dbfcnt_seek(cfile,ctype,lrefresh,lmsg)
* Search for binary element
* and seek to this position 
* Returns .T., if entry exists
* in DBF binary container.
* The records pointer show than
* to the matched entry
* Set lrefresh to .F., if the browse list
* is refreshed later in the calling function
* (Default is .T.)
* lmsg : Suppress message, if set to .F.
* Default is .T.    
* ==============================================
LOCAL lfound
FIELD BIN_CITEM,  BIN_CTYPE

IF lmsg == NIL
 lmsg := .T.
ENDIF

IF lrefresh == NIL
 lrefresh := .T.
ENDIF 

GO TOP

IF LASTREC() == 0
 * DBF is empty
 RETURN .F.
ENDIF 

 IF INDEXORD() == 0
*  Without index
  LOCATE FOR ( ALLTRIM(cfile) == ALLTRIM(BIN_CITEM)  ) .AND. ;
             ( ALLTRIM(ctype) == ALLTRIM(BIN_CTYPE)  )
 ELSE
* With  index
  SET SOFTSEEK OFF
 * Exakt seek
  SEEK PADR(cfile + ctype,LEN(cfile + ctype ))
 ENDIF

 
 IF FOUND()
  lfound := .T.
  IF lmsg
    hwg_MsgInfo("Record for file " + ALLTRIM(cfile) + "." + ALLTRIM(ctype) + " found, record number : "  + ;
     ALLTRIM(STR(RECNO() )), ;
     "Duplicate record found" )
  ENDIF
 ELSE
  lfound := .F.
 ENDIF
 
 * Optional: Refresh browse list
 IF lrefresh
  bindbf_brwref()
 ENDIF 
 
 RETURN lfound
 
 
* ============================================== 
FUNCTION dbfcnt_dlgsea()
* The Dialog for searching an element
* ============================================== 
LOCAL asrc , nmatch

 asrc := _frm_elein()
 
 IF EMPTY(asrc[1]) .OR. EMPTY(asrc[2])
   RETURN NIL
 ENDIF

* Start search 
nmatch := dbfcnt_search(asrc[1],asrc[2])

IF nmatch < 1
 hwg_MsgStop("Element not found : " +  asrc[1] + "." + asrc[2] )
ELSE
 hwg_MsgInfo("Element found : " +  asrc[1] + "." + asrc[2] )
ENDIF
 
 bindbf_brwref()

RETURN NIL 
 
* ============================================== 
FUNCTION dbfcnt_search(cfile,ctype)
* Searches element in an binary container DBF
* Returns the number of the record with match
* 0, if not found. 
* ==============================================
LOCAL noldrec
FIELD BIN_CITEM,  BIN_CTYPE

noldrec := RECNO()

GO TOP

* Database empty: no match
IF LASTREC() == 0
 RETURN 0
ENDIF 

 IF INDEXORD() == 0
*  Without index
  LOCATE FOR ( ALLTRIM(cfile) == ALLTRIM(BIN_CITEM)  ) .AND. ;
             ( ALLTRIM(ctype) == ALLTRIM(BIN_CTYPE)  )
 ELSE
* With  index
  SET SOFTSEEK OFF
 * Exakt seek
  SEEK PADR(cfile + ctype,LEN(cfile + ctype ))
 ENDIF

 
 IF FOUND()
   RETURN RECNO()
 ENDIF

 GO noldrec

RETURN 0

* ============================================= 
FUNCTION _frm_elein()
* Query for element to search, 
* returns an array with 2 elements:
* 1 : Name
* 2 : Type (Extension)
* If cancelled, both elements are filled
*    with empty string "".
* =============================================
LOCAL frm_elein , lname , ltype , aret , lcancel

LOCAL oLabel1, oEditbox1, oLabel2, oEditbox2, oLabel3, oButton1, oButton2

aret := { "" , "" }
lcancel := .T.

lname := SPACE(25)
lname := hwg_GET_Helper(lname,25)
ltype := SPACE(10)
lname := hwg_GET_Helper(lname,10)


  INIT DIALOG frm_elein TITLE "Test: Search element" ;
    AT 336,280 SIZE 382,230 ;
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE


   @ 31,18 SAY oLabel1 CAPTION "Enter name of element"  SIZE 198,22   
   @ 205,41 GET oEditbox1 VAR lname  SIZE 114,24 ;
        STYLE WS_BORDER     
   @ 34,45 SAY oLabel2 CAPTION "Name :"  SIZE 80,22   
   @ 205,77 GET oEditbox2 VAR ltype  SIZE 84,24 ;
        STYLE WS_BORDER

   @ 32,79 SAY oLabel3 CAPTION "Type (Extension) :"  SIZE 135,22   
   @ 44,118 BUTTON oButton1 CAPTION "OK"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| lcancel := .F. , frm_elein:Close() }
   @ 208,118 BUTTON oButton2 CAPTION "Cancel"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| frm_elein:Close() }

   ACTIVATE DIALOG frm_elein
* RETURN frm_elein:lresult
  IF .NOT. lcancel
   aret[1] := ALLTRIM(lname)
   aret[2] := ALLTRIM(ltype) 
  ENDIF

RETURN aret 

* ==============================================
FUNCTION bindbf_brwref()
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


* ==============================================
FUNCTION bindbf_shbitmap()
* Shows a bitmap, if type = "bmp"
* ==============================================
LOCAL obmp , oldsel
LOCAL frm_bitmap , oButton1 , nx , ny , oBitmap
LOCAL oLabel1, oLabel2, oLabel3, oLabel4

FIELD BIN_CITEM , BIN_CTYPE , BIN_MITEM

oldsel := SELECT()

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// SELECT 2   && Modify to your own needs
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


IF ALLTRIM(BIN_CTYPE) != "bmp"
  hwg_MsgStop("This element is not a bitmap")
  RETURN NIL
ENDIF  

obmp := bindbf_obitmap(BIN_CITEM , BIN_CTYPE , BIN_MITEM)

* Return to previos area
SELECT (oldsel)

IF obmp == NIL
  hwg_MsgStop("Bitmap is corrupted" + CHR(10) + "(Returned object is NIL)" )
  RETURN NIL
ENDIF 

* Display the bitmap in an extra window
* Max size : 1277,640

* Get current size
nx := hwg_GetBitmapWidth ( obmp:handle )
ny := hwg_GetBitmapHeight( obmp:handle )

IF nx > 1277
  nx := 1277
ENDIF 

IF ny > 640
  ny := 640
ENDIF  

  INIT DIALOG frm_bitmap TITLE "Bitmap Image" ;
    AT 20,20 SIZE 1324,772 ;
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE

   @ 747,667 SAY oLabel1 CAPTION "Size:  x:"  SIZE 87,22 ;
        STYLE SS_RIGHT   
   @ 866,667 SAY oLabel2 CAPTION ALLTRIM(STR(nx))  SIZE 80,22   
   @ 988,667 SAY oLabel3 CAPTION "y:"  SIZE 80,22 ;
        STYLE SS_RIGHT   
   @ 1130,667 SAY oLabel4 CAPTION ALLTRIM(STR(ny))  SIZE 80,22    



   @ 17,12 BITMAP oBitmap  ;
        SHOW obmp  OF frm_bitmap  ;
        SIZE nx, ny 

 
   @ 590,663 BUTTON oButton1 CAPTION "OK"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK { || frm_bitmap:Close() }

   ACTIVATE DIALOG frm_bitmap

RETURN NIL


* ==============================================
FUNCTION bindbf_obitmap(citem,ctype,mitem)
* Get a bitmap opject from container
* The record pointer must show to the
* record with the element to extract.
* ==============================================
LOCAL obmp,mm

citem := ALLTRIM(citem)
ctype := ALLTRIM(ctype)
IF ctype  != "bmp"
 RETURN NIL
ENDIF 

mm := hwg_cHex2Bin(mitem)

obmp := HBitmap():AddString( citem, mm  )

RETURN obmp



* ==============================================
FUNCTION SUBMNU_BRW( nCol, nRow )
* ==============================================

MEMVAR oMenuBrw, nrp , oBrw

   IF nCol > 0 .AND. nCol <= oBrw:rowCount
      nrp := ncol
      oMenuBrw:Show( HWindow():GetMain() )
   ENDIF
RETURN NIL
   

* ======================== EOF of bindbf.prg ====================== 