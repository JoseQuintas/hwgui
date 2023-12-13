/*
 * $Id$
 *
 * Binary container manager
 *
 * Copyright 2014 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 */

#include "hwgui.ch"
#include "hbclass.ch"
#include "fileio.ch"

#define APP_VERSION  "1.1"

#define OBJ_NAME      1
#define OBJ_TYPE      2

STATIC oBrw, oContainer
STATIC cHead := "hwgbc"

FUNCTION Main( cContainer )

   LOCAL oMainW, oMainFont, oMenuBrw
   LOCAL oStyle := HStyle():New( { 0xffffff, 0xbbbbbb } )
   LOCAL bRClick := {|o,nCol,nLine|
      LOCAL n := nLine, nRec := Eval( o:bRecno,o )
      IF n != nRec
         DO WHILE n != nRec
            IF n < nRec
               o:LineUp()
               n ++
            ELSE
               o:LineDown()
               n --
            ENDIF
         ENDDO
      ENDIF
      oMenuBrw:Show( HWindow():GetMain() )
      RETURN Nil
   }


   PREPARE FONT oMainFont NAME "Georgia" WIDTH 0 HEIGHT - 17 CHARSET 4

   INIT WINDOW oMainW MAIN TITLE "Binary container manager" ;
      AT 200, 0 SIZE 600, 540 FONT oMainFont

   MENU OF oMainW
      MENU TITLE "&File"
         MENUITEM "&Create" ACTION CntCreate()
         MENUITEM "&Open" ACTION CntOpen()
         SEPARATOR
         MENUITEM "&Exit" ACTION oMainW:Close()
      ENDMENU
      MENU TITLE "&Container" ID 1001
         MENUITEM "&Add item" ACTION CntAdd()
         MENUITEM "&Import from folder" ACTION CntImport()
         MENUITEM "&Delete item" ACTION CntDel()
         SEPARATOR
         MENUITEM "&Save item as" ACTION CntSave()
         MENUITEM "&View item" ACTION CntView()
         SEPARATOR
         MENUITEM "&Pack" ACTION CntPack()
         MENUITEM "In&fo" ACTION CntInfo()
      ENDMENU
      MENU TITLE "&Help"
         MENUITEM "&About" ACTION About()
      ENDMENU
   ENDMENU

   CONTEXT MENU oMenuBrw
      MENUITEM "&Delete item" ACTION CntDel()
      SEPARATOR
      MENUITEM "&Save item as" ACTION CntSave()
      SEPARATOR
      MENUITEM "&View item" ACTION CntView()
   ENDMENU

   @ 0, 0 BROWSE oBrw ARRAY            ;
      SIZE 600, 510                    ;
      STYLE WS_VSCROLL                 ;
      FONT oMainFont                   ;
      ON SIZE { |o, x, y|o:Move( , , x, y - 32 ) }

   oBrw:aArray := {}
   oBrw:AddColumn( HColumn():New( "Name",{ |value,o|o:aArray[o:nCurrent,1] },"C",32 ) )
   oBrw:AddColumn( HColumn():New( "Type",{ |value,o|o:aArray[o:nCurrent,2] },"C",8 ) )
   oBrw:AddColumn( HColumn():New( "Size",{ |value,o|o:aArray[o:nCurrent,4] },"N",14,0 ) )

   oBrw:oStyleHead := oStyle
   oBrw:bcolorSel := oBrw:htbcolor := 0xeeeeee
   oBrw:tcolorSel := oBrw:httcolor := 0
   oBrw:aHeadPadding[2] := oBrw:aHeadPadding[4] := 4
   oBrw:lInFocus := .T.

   oBrw:bRClick := bRClick
   oBrw:bEnter := {||CntView()}

   ADD STATUS PANEL TO oMainW HEIGHT 30 FONT oMainW:oFont ;
      HSTYLE oStyle PARTS 200, 120, 0

   hwg_Enablemenuitem( , 1001, .F. , .T. )

   IF cContainer != Nil
      CntOpen( cContainer )
   ENDIF

   ACTIVATE WINDOW oMainW

   IF !Empty( oContainer )
      oContainer:Close()
   ENDIF

   RETURN Nil

STATIC FUNCTION CntCreate()

   LOCAL fname

#ifdef __GTK__

   fname := hwg_Selectfile( "( *.* )", "*.*", CurDir() )
#else
   fname := hwg_Savefile( "*.*", "( *.* )", "*.*", CurDir() )
#endif
   IF !Empty( fname )
      IF !Empty( oContainer := HBinC():Create( fname ) )
         hwg_WriteStatus( HWindow():GetMain(), 1, hb_fnameNameExt( fname ) )
         hwg_WriteStatus( HWindow():GetMain(), 2, "Items: " + LTrim( Str(oContainer:nItems ) ) )
         hwg_Enablemenuitem( , 1001, .T. , .T. )
         hwg_Drawmenubar( HWindow():GetMain():handle )
         oBrw:aArray := oContainer:aObjects
         oBrw:Refresh()
      ELSE
         hwg_WriteStatus( HWindow():GetMain(), 1, "" )
         hwg_WriteStatus( HWindow():GetMain(), 2, "" )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION CntOpen( fname )

   IF Empty( fname )
      fname := hwg_Selectfile( { "All files" }, { "*.*" }, "" )
   ENDIF
   IF !Empty( fname )
      IF !Empty( oContainer := HBinC():Open( fname, .T. ) )
         hwg_WriteStatus( HWindow():GetMain(), 1, hb_fnameNameExt( fname ) )
         hwg_WriteStatus( HWindow():GetMain(), 2, "Items: " + LTrim( Str(oContainer:nItems ) ) )
         hwg_Enablemenuitem( , 1001, .T. , .T. )
         hwg_Drawmenubar( HWindow():GetMain():handle )
         oBrw:aArray := oContainer:aObjects
         oBrw:Refresh()
      ELSE
         hwg_WriteStatus( HWindow():GetMain(), 1, "" )
         hwg_WriteStatus( HWindow():GetMain(), 2, "" )
         hwg_MsgStop( "Error opening container" )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION CntAdd()
   LOCAL oDlg, oEdit1, oEdit2, oEdit3, cFileName := "", cObjName := "", cType := ""
   LOCAL bFile := { ||
   LOCAL cFile := hwg_Selectfile( "All files( *.* )", "*.*" )

   IF !Empty( cFile )
      oEdit1:value := cFile
      oEdit2:value := Left( CutExten( CutPath(cFile ) ), 32 )
      oEdit3:value := Left( FilExten( cFile ), 4 )
      hwg_WriteStatus( HWindow():GetMain(), 2, "Items: " + LTrim( Str(oContainer:nItems ) ) )
   ENDIF

   RETURN .T.

   }
   LOCAL bOk := { ||
   IF Empty( cFileName ) .OR. Empty( cObjName ) .OR. Empty( cType )
      hwg_MsgStop( "Fill all fields!" )
      RETURN .F.
   ENDIF
   oContainer:Add( cObjName, cType, MemoRead( cFileName ) )
   hwg_EndDialog()
   oBrw:Refresh()

   RETURN .T.

   }

   INIT DIALOG oDlg TITLE "Add binary object" ;
      AT 50, 100 SIZE 310, 250 FONT HWindow():GetMain():oFont

   @ 10, 20 GET oEdit1 VAR cFileName STYLE ES_AUTOHSCROLL SIZE 200, 26 MAXLENGTH 0
   @ 210, 20 BUTTON "Browse" SIZE 80, 26 ON CLICK bFile

   @ 10, 70 SAY "Object name:" SIZE 120, 22
   @ 130, 70 GET oEdit2 VAR cObjName SIZE 160, 26 PICTURE Replicate( 'X', 32 ) MAXLENGTH 0

   @ 10, 100 SAY "Type:" SIZE 120, 22
   @ 10, 100 GET oEdit3 VAR cType SIZE 80, 26 PICTURE "XXXX" MAXLENGTH 0

   @ 20, 200 BUTTON "Ok" SIZE 100, 32 ON CLICK bOk
   @ 180, 200 BUTTON "Cancel" ID IDCANCEL  SIZE 100, 32

   oDlg:Activate()

   RETURN Nil

STATIC FUNCTION CntImport()

   LOCAL cDir := hwg_SelectFolder(), arr, i, n := 0

   IF Empty( cDir )
      RETURN Nil
   ENDIF

   cDir += hb_ps()
   arr := Directory( cDir + "*.*" )
   FOR i := 1 TO Len( arr )
      IF oContainer:Add( hb_fnameName( arr[i,1] ), Substr( hb_fnameExt( arr[i,1] ), 2 ), ;
         MemoRead( cDir + arr[i,1] ) )
         n ++
      ENDIF
   NEXT

   hwg_MsgInfo( Ltrim(Str(n)) + " files added" )

   oBrw:Refresh()

   RETURN Nil

STATIC FUNCTION CntDel()
   LOCAL n := oBrw:nCurrent

   IF hwg_MsgYesNo( "Really delete " + oContainer:aObjects[n,1] + "?" )
      oContainer:Del( oContainer:aObjects[n,1] )
      oBrw:Refresh()
   ENDIF

   RETURN Nil

STATIC FUNCTION CntSave()
   LOCAL n := oBrw:nCurrent
   LOCAL fname

#ifdef __GTK__
   fname := hwg_Selectfile( "( *.* )", "*.*", CurDir() )
#else
   fname := hwg_Savefile( "*.*", "( *.* )", "*.*", CurDir() )
#endif
   IF !Empty( fname )
      fname := hb_FNameExtSetDef( fname, oContainer:aObjects[n,2] )
      hb_MemoWrit( fname, oContainer:Get( oContainer:aObjects[n,1] ) )
   ENDIF

   RETURN Nil

STATIC FUNCTION CntPack()

   oContainer:Pack()
   hwg_WriteStatus( HWindow():GetMain(), 2, "Items: " + LTrim( Str(oContainer:nItems ) ) )
   oBrw:aArray := oContainer:aObjects
   oBrw:Top()
   oBrw:Refresh()

   RETURN Nil

STATIC FUNCTION CntView()

   LOCAL oDlg, oBoa
   LOCAL name := oContainer:aObjects[oBrw:nCurrent,1], type := Trim( oContainer:aObjects[oBrw:nCurrent,2] )
   LOCAL cBuf, handle, aBmpSize

   IF !( Trim( type ) $ "bmp;jpg;png;gif;ico" )
      RETURN Nil
   ENDIF
   IF !Empty( cBuf := oContainer:Get( name ) ) .AND. !Empty( handle := hwg_OpenImage( cBuf, .T. ) )
      aBmpSize := hwg_Getbitmapsize( handle )
   ELSE
      RETURN Nil
   ENDIF

   INIT DIALOG oDlg TITLE  name + " " + ;
      Ltrim(Str(aBmpSize[1])) + "x" + Ltrim(Str(aBmpSize[2])) ;
      AT 0, 0 SIZE Max( aBmpSize[1] + 20, 220 ), aBmpSize[2] + 70 FONT HWindow():GetMain():oFont ;
      ON EXIT {||hwg_Deleteobject(handle),.T.}

   @ 0, 0 BOARD oBoa SIZE oDlg:nWidth, oDlg:nHeight-50 ;
      ON SIZE {|o,x,y|o:Move(,,x,y-50)} ON PAINT {|o,h|FPaint(o,h,handle)}

   @ Int((oDlg:nWidth-100)/2), oDlg:nHeight - 50 BUTTON "Close" ON CLICK {|| oDlg:Close() } SIZE 100,32

   ACTIVATE DIALOG oDlg CENTER

   RETURN Nil

STATIC FUNCTION FPaint( o, hDC, handle )

   hwg_Drawbitmap( hDC, handle,, 10, 10 )

   RETURN -1

STATIC FUNCTION CntInfo()

   LOCAL oDlg

   INIT DIALOG oDlg TITLE "Info" ;
      AT 0, 0 SIZE 280, 320 FONT HWindow():GetMain():oFont

   @ 20, 40 SAY "Items:" SIZE 140,26 STYLE SS_LEFT
   @ 160, 40 SAY Ltrim(Str( oContainer:nItems )) SIZE 100,26 STYLE SS_RIGHT

   @ 20, 80 SAY "Content length:" SIZE 140,26 STYLE SS_LEFT
   @ 160, 80 SAY Ltrim(Str( oContainer:nCntLen )) SIZE 100,26 STYLE SS_RIGHT

   @ 20, 120 SAY "Content blocks:" SIZE 140,26 STYLE SS_LEFT
   @ 160, 120 SAY Ltrim(Str( oContainer:nCntBlocks )) SIZE 100,26 STYLE SS_RIGHT

   @ 60, 250 BUTTON "Close" ON CLICK {|| oDlg:Close() } SIZE 160,36

   ACTIVATE DIALOG oDlg CENTER

   RETURN Nil

#define  CLR_VDBLUE  10485760
#define  CLR_LBLUE0  12164479

STATIC FUNCTION About()

   LOCAL oDlg

   INIT DIALOG oDlg TITLE "About" ;
      AT 0, 0 SIZE 400, 320 FONT HWindow():GetMain():oFont COLOR hwg_colorC2N("CCCCCC")

   @ 20, 40 SAY "Binary container manager" SIZE 360,26 STYLE SS_CENTER COLOR CLR_VDBLUE TRANSPARENT
   @ 20, 64 SAY "Version "+APP_VERSION SIZE 360,26 STYLE SS_CENTER COLOR CLR_VDBLUE TRANSPARENT
   @ 10, 100 SAY "Copyright 2014 Alexander S.Kresin" SIZE 380,26 STYLE SS_CENTER COLOR CLR_VDBLUE TRANSPARENT
   @ 20, 124 SAY "http://www.kresin.ru" LINK "http://www.kresin.ru" SIZE 360,26 STYLE SS_CENTER
   @ 20, 160 LINE LENGTH 360
   @ 20, 180 SAY hwg_version() SIZE 360,26 STYLE SS_CENTER COLOR CLR_LBLUE0 TRANSPARENT

   @ 120, 250 BUTTON "Close" ON CLICK {|| hwg_EndDialog()} SIZE 160,36

   ACTIVATE DIALOG oDlg CENTER

   RETURN Nil
