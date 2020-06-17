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

#define APP_VERSION  "1.0"

STATIC oBrw, oContainer
STATIC cHead := "hwgbc"

FUNCTION Main( cContainer )

   LOCAL oMainW, oMainFont
   LOCAL oStyle := HStyle():New( { 0xffffff, 0xbbbbbb } )

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
         MENUITEM "&Delete item" ACTION CntDel()
         SEPARATOR
         MENUITEM "&Save item as" ACTION CntSave()
         SEPARATOR
         MENUITEM "&Pack" ACTION CntPack()
      ENDMENU
      MENU TITLE "&Help"
         MENUITEM "&About" ACTION About()
      ENDMENU
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
