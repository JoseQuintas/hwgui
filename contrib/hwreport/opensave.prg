/*
 * Repbuild - Visual Report Builder
 * Open/save functions
 *
 * Copyright 2001-2021 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

   // Modifications by DF7BE:
   // Port of Borland C resources to HWGUI commands

#include "hwgui.ch"
#include "repbuild.h"
#include "repmain.h"
#include "fileio.ch"
#ifdef __XHARBOUR__
#include "ttable.ch"
#endif
#ifdef __GTK__
#include "gtk.ch"
#endif

   // Removed
   // #define SB_VERT         1

MEMVAR aPaintRep , mypath, aitemtypes
STATIC oDlg

FUNCTION FileDlg( lOpen )

   LOCAL oRb1, oRb2,  oEdit1, oLabel1, oEdit2

   IF !lOpen .AND. ( aPaintRep == Nil .OR. Empty( aPaintRep[FORM_ITEMS] ) )
      hwg_Msgstop( "Nothing to save" )
      RETURN Nil
   ELSEIF lOpen
      CloseReport()
   ENDIF

   INIT DIALOG oDlg TITLE "" ;
      AT 100, 100 SIZE 426, 250 ON INIT { || InitOpen( lOpen ) }

   @ 29, 8 GROUPBOX ""  SIZE 153, 72
   RADIOGROUP
   @ 36, 23 RADIOBUTTON oRb1  ;
      CAPTION "Report file"     SIZE 136, 22 ON CLICK {||oLabel1:SetText( "Report Name:" )}
   @ 36, 47 RADIOBUTTON oRb2  ;
      CAPTION "Program source"  SIZE 137, 22 ON CLICK {||oLabel1:SetText( "Function Name:" )}
   END RADIOGROUP SELECTED 1

   @ 24, 91 EDITBOX oEdit1 CAPTION ""  SIZE 269, 24 ;
      STYLE ES_AUTOHSCROLL + WS_TABSTOP

   @ 28, 126 SAY oLabel1 CAPTION "Report name:"  SIZE 144, 22
   @ 61, 153 EDITBOX oEdit2 CAPTION ""  SIZE 96, 24

   @ 309, 89 BUTTON "Browse" SIZE 80, 27 ;
      STYLE WS_TABSTOP ON CLICK { ||BrowFile( lOpen ) }

   @ 26, 200 BUTTON "OK"  SIZE 80, 32 STYLE WS_TABSTOP ON CLICK { || EndOpen( lOpen ) }
   @ 298, 200 BUTTON "Cancel"  SIZE 80, 32 STYLE WS_TABSTOP ON CLICK { || oDlg:Close() }

   oDlg:Activate()

   RETURN Nil

STATIC FUNCTION InitOpen( lOpen )

   oDlg:SetTitle( Iif( lOpen,"Open report","Save report" ) )
   hwg_Setfocus( oDlg:oEdit1:handle )

   RETURN .T.

STATIC FUNCTION BrowFile( lOpen )
   LOCAL fname, s1, s2

   IF oDlg:oRb1:Value
      s1 := "Report files( *.rpt )"
      s2 := "*.rpt"
   ELSE
      s1 := "Program files( *.prg )"
      s2 := "*.prg"
   ENDIF

   IF lOpen
      fname := hwg_SelectFile( s1, s2, mypath )
   ELSE
#ifdef __GTK__
      fname := hwg_Selectfile( s1, s2, mypath )
#else
      fname := hwg_SaveFile( s2, s1, s2, mypath )
#endif
   ENDIF

   oDlg:oEdit1:Value := fname
   hwg_Setfocus( oDlg:oEdit2:handle )

   RETURN Nil

STATIC FUNCTION EndOpen( lOpen )
   LOCAL fname, repName
   LOCAL res := .T.

   fname := oDlg:oEdit1:Value
   IF !Empty( fname )
      repName := oDlg:oEdit2:Value

      IF lOpen
         IF ( res := OpenFile( fname,@repName ) )
            aPaintRep[FORM_Y] := 0
            hwg_Enablemenuitem( ,IDM_VIEW1, .T., .T. )
            hwg_Enablemenuitem( ,1, .T., .F. )
            Hwindow():GetMain():Refresh()
         ELSE
            aPaintRep := Nil
            hwg_Enablemenuitem( ,IDM_VIEW1, .F., .T. )
            hwg_Enablemenuitem( ,1, .F., .F. )
         ENDIF
      ELSE
         res := SaveRFile( fname, repName )
         aPaintRep[FORM_FILENAME] := fname
         aPaintRep[FORM_REPNAME] := repName
      ENDIF

      IF res
         oDlg:Close()
      ENDIF
   ELSE
      hwg_Setfocus( oDlg:oEdit1:handle )
   ENDIF

   RETURN .T.

FUNCTION CloseReport
   LOCAL i, aItem

   IF aPaintRep != Nil
      IF aPaintRep[FORM_CHANGED] == .T.
         IF hwg_Msgyesno( "Report was changed. Are you want to save it ?" )
            SaveReport()
         ENDIF
      ENDIF
      FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
         aItem := aPaintRep[FORM_ITEMS,i]
         IF aItem[ITEM_PEN] != Nil
            aItem[ITEM_PEN]:Release()
         ENDIF
      NEXT
      aPaintRep := Nil
      //hwg_Showscrollbar( Hwindow():GetMain():handle, SB_VERT, .F. )
      Hwindow():GetMain():Refresh()
      hwg_Enablemenuitem( , 1, .F. , .F. )
   ENDIF

   RETURN .T.

FUNCTION SaveReport

   IF ( aPaintRep == Nil .OR. Empty( aPaintRep[FORM_ITEMS] ) )
      hwg_Msgstop( "Nothing to save" )
      RETURN Nil
   ENDIF
   IF Empty( aPaintRep[FORM_FILENAME] )
      FileDlg( .F. )
   ELSE
      SaveRFile( aPaintRep[FORM_FILENAME], aPaintRep[FORM_REPNAME] )
   ENDIF

   RETURN Nil

STATIC FUNCTION OpenFile( fname, repName )
   LOCAL strbuf := Space( 512 ), poz := 513, stroka, nMode := 0
   LOCAL han := FOpen( fname, FO_READ + FO_SHARED )
   LOCAL itemName, aItem, res := .T.
   LOCAL lPrg := ( Upper( FilExten(fname ) ) == "PRG" ), cSource := "", vDummy, nFormWidth

   IF han <> - 1
      DO WHILE .T.
         stroka := RDSTR( han, @strbuf, @poz, 512 )
         IF Len( stroka ) = 0
            EXIT
         ENDIF
         IF Left( stroka, 1 ) == ";"
            LOOP
         ENDIF
         IF nMode == 0
            IF lPrg
               IF Upper( Left( stroka,8 ) ) == "FUNCTION" .AND. ;
                     Upper( LTrim( SubStr( stroka,10 ) ) ) == Upper( repname )
                  nMode := 10
               ENDIF
            ELSE
               IF Left( stroka, 1 ) == "#"
                  IF Upper( SubStr( stroka,2,6 ) ) == "REPORT"
                     stroka := LTrim( SubStr( stroka,9 ) )
                     IF Empty( repName ) .OR. Upper( stroka ) == Upper( repName )
                        IF Empty( repName )
                           repName := stroka
                        ENDIF
                        nMode := 1
                        aPaintRep := { 0, 0, 0, 0, 0, {}, fname, repName, .F. , 0, Nil }
                     ENDIF
                  ENDIF
               ENDIF
            ENDIF
         ELSEIF nMode == 1
            IF Left( stroka, 1 ) == "#"
               IF Upper( SubStr( stroka,2,6 ) ) == "ENDREP"
                  EXIT
               ELSEIF Upper( SubStr( stroka,2,6 ) ) == "SCRIPT"
                  nMode := 2
                  IF aItem != Nil
                     aItem[ITEM_SCRIPT] := ""
                  ELSE
                     aPaintRep[FORM_VARS] := ""
                  ENDIF
               ENDIF
            ELSE
               IF ( itemName := NextItem( stroka, .T. ) ) == "FORM"
                  aPaintRep[FORM_WIDTH] := Val( NextItem( stroka ) )
                  aPaintRep[FORM_HEIGHT] := Val( NextItem( stroka ) )
                  nFormWidth := Val( NextItem( stroka ) )
               ELSEIF itemName == "TEXT"
                  AAdd( aPaintRep[FORM_ITEMS], { 1, NextItem( stroka ), Val( NextItem(stroka ) ), ;
                     Val( NextItem( stroka ) ), Val( NextItem( stroka ) ), ;
                     Val( NextItem( stroka ) ), Val( NextItem( stroka ) ), Nil, NextItem( stroka ), ;
                     Val( NextItem( stroka ) ), 0, Nil, 0 } )
                  aItem := Atail( aPaintRep[FORM_ITEMS] )
                  aItem[ITEM_FONT] := HFont():Add( NextItem( aItem[ITEM_FONT], .T. ,"," ), ;
                     Val( NextItem( aItem[ITEM_FONT],,"," ) ), Val( NextItem( aItem[ITEM_FONT],,"," ) ), ;
                     Val( NextItem( aItem[ITEM_FONT],,"," ) ), Val( NextItem( aItem[ITEM_FONT],,"," ) ), ;
                     Val( NextItem( aItem[ITEM_FONT],,"," ) ), Val( NextItem( aItem[ITEM_FONT],,"," ) ), ;
                     Val( NextItem( aItem[ITEM_FONT],,"," ) ) )
                  IF aItem[ITEM_X1] == Nil .OR. aItem[ITEM_X1] == 0 .OR. ;
                        aItem[ITEM_Y1] == Nil .OR. aItem[ITEM_Y1] == 0 .OR. ;
                        aItem[ITEM_WIDTH] == Nil .OR. aItem[ITEM_WIDTH] == 0 .OR. ;
                        aItem[ITEM_HEIGHT] == Nil .OR. aItem[ITEM_HEIGHT] == 0
                     hwg_Msgstop( "Error: " + stroka )
                     res := .F.
                     EXIT
                  ENDIF
               ELSEIF itemName == "HLINE" .OR. itemName == "VLINE" .OR. itemName == "BOX"
                  AAdd( aPaintRep[FORM_ITEMS], { iif( itemName == "HLINE",2,iif(itemName == "VLINE",3,4 ) ), ;
                     "", Val( NextItem( stroka ) ), ;
                     Val( NextItem( stroka ) ), Val( NextItem( stroka ) ), ;
                     Val( NextItem( stroka ) ), 0, NextItem( stroka ), Nil, 0, 0, Nil, 0 } )
                  aItem := Atail( aPaintRep[FORM_ITEMS] )
                  aItem[ITEM_PEN] := HPen():Add( Val( NextItem( aItem[ITEM_PEN], .T. ,"," ) ), ;
                     Val( NextItem( aItem[ITEM_PEN],,"," ) ), Val( NextItem( aItem[ITEM_PEN],,"," ) ) )
                  IF aItem[ITEM_X1] == Nil .OR. aItem[ITEM_X1] == 0 .OR. ;
                        aItem[ITEM_Y1] == Nil .OR. aItem[ITEM_Y1] == 0 .OR. ;
                        aItem[ITEM_WIDTH] == Nil .OR. aItem[ITEM_WIDTH] == 0 .OR. ;
                        aItem[ITEM_HEIGHT] == Nil .OR. aItem[ITEM_HEIGHT] == 0
                     hwg_Msgstop( "Error: " + stroka )
                     res := .F.
                     EXIT
                  ENDIF
               ELSEIF itemName == "BITMAP"
                  AAdd( aPaintRep[FORM_ITEMS], { 5, NextItem( stroka ), ;
                     Val( NextItem( stroka ) ), ;
                     Val( NextItem( stroka ) ), Val( NextItem( stroka ) ), ;
                     Val( NextItem( stroka ) ), 0, Nil, Nil, 0, 0, Nil, 0 } )
                  aItem := Atail( aPaintRep[FORM_ITEMS] )
                  aItem[ITEM_BITMAP] := HBitmap():AddFile( aItem[ITEM_CAPTION] )
                  IF aItem[ITEM_X1] == Nil .OR. aItem[ITEM_X1] == 0 .OR. ;
                        aItem[ITEM_Y1] == Nil .OR. aItem[ITEM_Y1] == 0 .OR. ;
                        aItem[ITEM_WIDTH] == Nil .OR. aItem[ITEM_WIDTH] == 0 .OR. ;
                        aItem[ITEM_HEIGHT] == Nil .OR. aItem[ITEM_HEIGHT] == 0
                     hwg_Msgstop( "Error: " + stroka )
                     res := .F.
                     EXIT
                  ENDIF
               ELSEIF itemName == "MARKER"
                  AAdd( aPaintRep[FORM_ITEMS], { 6, NextItem( stroka ), Val( NextItem(stroka ) ), ;
                     Val( NextItem( stroka ) ), Val( NextItem( stroka ) ), ;
                     Val( NextItem( stroka ) ), Val( NextItem( stroka ) ), ;
                     Nil, Nil, 0, 0, Nil, 0 } )
                  aItem := Atail( aPaintRep[FORM_ITEMS] )
               ENDIF
            ENDIF
         ELSEIF nMode == 2
            IF Left( stroka, 1 ) == "#" .AND. Upper( SubStr( stroka,2,6 ) ) == "ENDSCR"
               nMode := 1
            ELSE
               IF aItem != Nil
                  aItem[ITEM_SCRIPT] += stroka + Chr( 13 ) + Chr( 10 )
               ELSE
                  aPaintRep[FORM_VARS] += stroka + Chr( 13 ) + Chr( 10 )
               ENDIF
            ENDIF
         ELSEIF nMode == 10
            IF Upper( Left( stroka,15 ) ) == "LOCAL APAINTREP"
               nMode := 11
            ELSE
               hwg_Msgstop( "Wrong function " + repname )
               FClose( han )
               RETURN .F.
            ENDIF
         ELSEIF nMode == 11
            IF Upper( Left( stroka,6 ) ) == "RETURN"
               EXIT
            ELSE
               IF Right( stroka, 1 ) == ";"
                  cSource += LTrim( RTrim( Left( stroka,Len(stroka ) - 1 ) ) )
               ELSE
                  cSource += LTrim( RTrim( stroka ) )
                  // Writelog( cSource )
                  vDummy := &cSource
                  cSource := ""
               ENDIF
            ENDIF
         ENDIF
      ENDDO
      FClose( han )
   ELSE
      hwg_Msgstop( "Can't open " + fname )
      RETURN .F.
   ENDIF
   IF aPaintRep == Nil .OR. Empty( aPaintRep[FORM_ITEMS] )
      hwg_Msgstop( repname + " not found or empty!" )
      res := .F.
   ELSE
      hwg_Enablemenuitem( , IDM_CLOSE, .T. , .T. )
      hwg_Enablemenuitem( , IDM_SAVE, .T. , .T. )
      hwg_Enablemenuitem( , IDM_SAVEAS, .T. , .T. )
      hwg_Enablemenuitem( , IDM_PRINT, .T. , .T. )
      hwg_Enablemenuitem( , IDM_PREVIEW, .T. , .T. )
      hwg_Enablemenuitem( , IDM_FOPT, .T. , .T. )

      aPaintRep[FORM_ITEMS] := ASort( aPaintRep[FORM_ITEMS], , , { |z, y|z[ITEM_Y1] < y[ITEM_Y1] .OR. ( z[ITEM_Y1] == y[ITEM_Y1] .AND. z[ITEM_X1] < y[ITEM_X1] ) .OR. ( z[ITEM_Y1] == y[ITEM_Y1] .AND. z[ITEM_X1] == y[ITEM_X1] .AND. (z[ITEM_WIDTH] < y[ITEM_WIDTH] .OR. z[ITEM_HEIGHT] < y[ITEM_HEIGHT] ) ) } )
      IF !lPrg
         hwg_RecalcForm( aPaintRep, nFormWidth )
      ENDIF

      hwg_WriteStatus( Hwindow():GetMain(), 2, LTrim( Str(aPaintRep[FORM_WIDTH],4 ) ) + "x" + ;
         LTrim( Str( aPaintRep[FORM_HEIGHT],4 ) ) + "  Items: " + LTrim( Str( Len(aPaintRep[FORM_ITEMS] ) ) ) )
   ENDIF

   RETURN res

STATIC FUNCTION SaveRFile( fname, repName )
   LOCAL strbuf := Space( 512 ), poz := 513, stroka, nMode := 0
   LOCAL han, hanOut, isOut := .F. , res := .F.
   LOCAL lPrg := ( Upper( FilExten(fname ) ) == "PRG" )

   IF File( fname )
      han := FOpen( fname, FO_READWRITE + FO_EXCLUSIVE )
      IF han <> - 1
         hanOut := FCreate( mypath + "__rpt.tmp" )
         IF hanOut <> - 1
            DO WHILE .T.
               stroka := RDSTR( han, @strbuf, @poz, 512 )
               IF Len( stroka ) = 0
                  EXIT
               ENDIF
               IF nMode == 0
                  IF ( lPrg .AND. Upper( Left( stroka,8 ) ) == "FUNCTION" ) ;
                        .OR. ( !lPrg .AND. Left( stroka,1 ) == "#" .AND. ;
                        Upper( SubStr( stroka,2,6 ) ) == "REPORT" )
                     IF Upper( LTrim( SubStr( stroka,9 ) ) ) == Upper( repName )
                        nMode := 1
                        isOut := .T.
                        LOOP
                     ENDIF
                  ENDIF
                  FWrite( hanOut, stroka + iif( Asc(Right(stroka,1 ) ) < 20,"",Chr(10 ) ) )
               ELSEIF nMode == 1
                  IF ( lPrg .AND. Left( stroka,6 ) == "RETURN" ) ;
                        .OR. ( !lPrg .AND. Left( stroka,1 ) == "#" .AND. ;
                        Upper( SubStr( stroka,2,6 ) ) == "ENDREP" )
                     nMode := 0
                     IF lPrg
                        WriteToPrg( hanOut, repName )
                     ELSE
                        WriteRep( hanOut, repName )
                     ENDIF
                  ENDIF
               ENDIF
            ENDDO
            IF isOut
               FClose( hanOut )
               FClose( han )
               IF FErase( fname ) == - 1 .OR. FRename( mypath + "__rpt.tmp", fname ) == - 1
                  hwg_Msgstop( "Can't rename __rpt.tmp" )
               ELSE
                  res := .T.
               ENDIF
            ELSE
               FSeek( han, 0, FS_END )
               FWrite( han, Chr( 10 ) )
               IF lPrg
                  WriteToPrg( han, repName )
               ELSE
                  WriteRep( hanOut, repName )
               ENDIF
               FClose( hanOut )
               FClose( han )
               res := .T.
            ENDIF
         ELSE
            hwg_Msgstop( "Can't create __rpt.tmp" )
            FClose( han )
         ENDIF
      ELSE
         hwg_Msgstop( "Can't open " + fname )
      ENDIF
   ELSE
      han := FCreate( fname )
      IF lPrg
         WriteToPrg( han, repName )
      ELSE
         WriteRep( han, repName )
      ENDIF
      FClose( han )
      res := .T.
   ENDIF
   IF res
      aPaintRep[FORM_CHANGED] := .F.
   ENDIF

   RETURN res

STATIC FUNCTION WriteRep( han, repName )
   LOCAL i, aItem, oPen, oFont, hDCwindow, aMetr

   hDCwindow := hwg_Getdc( Hwindow():GetMain():handle )
   aMetr := hwg_GetDeviceArea( hDCwindow )
   hwg_Releasedc( Hwindow():GetMain():handle, hDCwindow )

   FWrite( han, "#REPORT " + repName + Chr( 10 ) )
   FWrite( han, "FORM;" + LTrim( Str(aPaintRep[FORM_WIDTH] ) ) + ";" + ;
      LTrim( Str( aPaintRep[FORM_HEIGHT] ) ) + ";" + ;
      LTrim( Str( aMetr[1] - XINDENT ) ) + Chr( 10 ) )
   WriteScript( han, aPaintRep[FORM_VARS] )

   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      aItem := aPaintRep[FORM_ITEMS,i]
      IF aItem[ITEM_TYPE] == TYPE_TEXT
         oFont := aItem[ITEM_FONT]
         FWrite( han, aItemTypes[aItem[ITEM_TYPE]] + ";" + aItem[ITEM_CAPTION] + ";" + ;
            LTrim( Str( aItem[ITEM_X1],4 ) ) + ";" + LTrim( Str( aItem[ITEM_Y1],4 ) ) + ";" + ;
            LTrim( Str( aItem[ITEM_WIDTH],4 ) ) + ";" + LTrim( Str( aItem[ITEM_HEIGHT],4 ) ) + ;
            ";" + Str( aItem[ITEM_ALIGN], 1 ) + ";" + oFont:name ;
            + "," + LTrim( Str( oFont:width ) ) + "," + LTrim( Str( oFont:height ) ) ;
            + "," + LTrim( Str( oFont:weight ) ) + "," + LTrim( Str( oFont:charset ) ) ;
            + "," + LTrim( Str( oFont:italic ) ) + "," + LTrim( Str( oFont:underline ) ) ;
            + "," + LTrim( Str( oFont:strikeout ) ) + ";" + Str( aItem[ITEM_VAR], 1 ) + Chr( 10 ) )
         WriteScript( han, aItem[ITEM_SCRIPT] )
      ELSEIF aItem[ITEM_TYPE] == TYPE_HLINE .OR. aItem[ITEM_TYPE] == TYPE_VLINE .OR. aItem[ITEM_TYPE] == TYPE_BOX
         oPen := aItem[ITEM_PEN]
         FWrite( han, aItemTypes[aItem[ITEM_TYPE]] + ";" + ;
            LTrim( Str( aItem[ITEM_X1],4 ) ) + ";" + LTrim( Str( aItem[ITEM_Y1],4 ) ) + ";" + ;
            LTrim( Str( aItem[ITEM_WIDTH],4 ) ) + ";" + LTrim( Str( aItem[ITEM_HEIGHT],4 ) ) + ;
            ";" + LTrim( Str( oPen:style ) ) + "," + LTrim( Str( oPen:width ) ) + "," + LTrim( Str( oPen:color ) ) ;
            + Chr( 10 ) )
      ELSEIF aItem[ITEM_TYPE] == TYPE_BITMAP
         FWrite( han, aItemTypes[aItem[ITEM_TYPE]] + ";" + aItem[ITEM_CAPTION] + ";" + ;
            LTrim( Str( aItem[ITEM_X1],4 ) ) + ";" + LTrim( Str( aItem[ITEM_Y1],4 ) ) + ";" + ;
            LTrim( Str( aItem[ITEM_WIDTH],4 ) ) + ";" + LTrim( Str( aItem[ITEM_HEIGHT],4 ) ) + ;
            + Chr( 10 ) )
      ELSEIF aItem[ITEM_TYPE] == TYPE_MARKER
         FWrite( han, aItemTypes[aItem[ITEM_TYPE]] + ";" + aItem[ITEM_CAPTION] + ";" + ;
            LTrim( Str( aItem[ITEM_X1],4 ) ) + ";" + LTrim( Str( aItem[ITEM_Y1],4 ) ) + ";" + ;
            LTrim( Str( aItem[ITEM_WIDTH],4 ) ) + ";" + LTrim( Str( aItem[ITEM_HEIGHT],4 ) ) + ;
            ";" + Str( aItem[ITEM_ALIGN], 1 ) + Chr( 10 ) )
         WriteScript( han, aItem[ITEM_SCRIPT] )
      ENDIF
   NEXT
   FWrite( han, "#ENDREP " + Chr( 10 ) )

   RETURN Nil

STATIC FUNCTION WriteToPrg( han, repName )
   LOCAL i, aItem, oPen, oFont, hDCwindow, aMetr, cItem, cQuote

   hDCwindow := hwg_Getdc( Hwindow():GetMain():handle )
   aMetr := hwg_GetDeviceArea( hDCwindow )
   hwg_Releasedc( Hwindow():GetMain():handle, hDCwindow )

   FWrite( han, "FUNCTION " + repName + Chr( 10 ) + ;
      "LOCAL aPaintRep" + Chr( 10 ) )
   FWrite( han, "   cEnd:=Chr(13)+Chr(10)" + Chr( 10 ) )
   FWrite( han, "   aPaintRep := { " + LTrim( Str(aPaintRep[FORM_WIDTH] ) ) + "," + ;
      LTrim( Str( aPaintRep[FORM_HEIGHT] ) ) + ',0,0,0,{},,"' + repName + '",.F.,0,Nil }' + Chr( 10 ) )
   IF aPaintRep[FORM_VARS] != Nil .AND. !Empty( aPaintRep[FORM_VARS] )
      FWrite( han, "   aPaintRep[11] := ;" + Chr( 10 ) )
      WriteScript( han, aPaintRep[FORM_VARS], .T. )
   ENDIF

   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      aItem := aPaintRep[FORM_ITEMS,i]

      cItem := LTrim( Str( aItem[ITEM_TYPE],1 ) ) + ","
      IF aItem[ITEM_TYPE] == TYPE_TEXT .OR. aItem[ITEM_TYPE] == TYPE_BITMAP ;
            .OR. aItem[ITEM_TYPE] == TYPE_MARKER
         cQuote := iif( !( '"' $ aItem[ITEM_CAPTION] ), '"', ;
            iif( !( "'" $ aItem[ITEM_CAPTION] ), "'", "[" ) )
         cItem += cQuote + aItem[ITEM_CAPTION] + cQuote
      ENDIF
      cItem += "," + LTrim( Str( aItem[ITEM_X1],4 ) ) + "," + LTrim( Str( aItem[ITEM_Y1],4 ) ) + "," + ;
         LTrim( Str( aItem[ITEM_WIDTH],4 ) ) + "," + LTrim( Str( aItem[ITEM_HEIGHT],4 ) ) + ;
         "," + Str( aItem[ITEM_ALIGN], 1 )
      IF aItem[ITEM_TYPE] == TYPE_HLINE .OR. aItem[ITEM_TYPE] == TYPE_VLINE ;
            .OR. aItem[ITEM_TYPE] == TYPE_BOX
         oPen := aItem[ITEM_PEN]
         cItem += ",HPen():Add(" + LTrim( Str( oPen:style ) ) + "," + ;
            LTrim( Str( oPen:width ) ) + "," + LTrim( Str( oPen:color ) ) + ")"
      ELSE
         cItem += ",0"
      ENDIF
      IF aItem[ITEM_TYPE] == TYPE_TEXT
         oFont := aItem[ITEM_FONT]
         cItem += ',HFont():Add( "' + oFont:name + ;
            + '",' + LTrim( Str( oFont:width ) ) + "," + LTrim( Str( oFont:height ) ) ;
            + "," + LTrim( Str( oFont:weight ) ) + "," + LTrim( Str( oFont:charset ) ) ;
            + "," + LTrim( Str( oFont:italic ) ) + "," + LTrim( Str( oFont:underline ) ) ;
            + "," + LTrim( Str( oFont:strikeout ) ) + " )," + Str( aItem[ITEM_VAR], 1 )
      ELSE
         cItem += ",0,0"
      ENDIF
      cItem += ",0,Nil,0"
      FWrite( han, "   Aadd( aPaintRep[6], { " + cItem + " } )" + Chr( 10 ) )

      IF aItem[ITEM_SCRIPT] != Nil .AND. !Empty( aItem[ITEM_SCRIPT] )
         FWrite( han, "   aPaintRep[6,Len(aPaintRep[6]),12] := ;" + Chr( 10 ) )
         WriteScript( han, aItem[ITEM_SCRIPT], .T. )
      ENDIF
   NEXT
   FWrite( han, "   hwg_RecalcForm( aPaintRep," + LTrim( Str(aMetr[1] - XINDENT ) ) + " )" + Chr( 10 ) )
   FWrite( han, "RETURN hwg_SetPaintRep( aPaintRep )" + Chr( 10 ) )

   RETURN Nil

STATIC FUNCTION WriteScript( han, cScript, lPrg )
   LOCAL poz := 0, stroka
   LOCAL lastC := Chr( 10 ), cQuote, lFirst := .T.

   IF lPrg == Nil; lPrg := .F. ; ENDIF
   IF cScript != Nil .AND. !Empty( cScript )
      IF !lPrg
         FWrite( han, "#SCRIPT" + Chr( 10 ) )
      ENDIF
      DO WHILE .T.
         stroka := RDSTR( , cScript, @poz )
         IF Len( stroka ) = 0
            IF lPrg
               FWrite( han, Chr( 10 ) )
            ENDIF
            EXIT
         ENDIF
         IF Left( stroka, 1 ) != Chr( 10 )
            IF lPrg
               cQuote := iif( !( '"' $ stroka ), '"', ;
                  iif( !( "'" $ stroka ), "'", "[" ) )
               FWrite( han, iif( lFirst,"",";" + Chr(10 ) ) + Space( 5 ) + ;
                  iif( lFirst, "", "+ " ) + cQuote + stroka + cQuote + "+cEnd" )
               lFirst := .F.
            ELSE
               FWrite( han, iif( Asc(lastC ) < 20,"",Chr(10 ) ) + stroka )
               lastC := Right( stroka, 1 )
            ENDIF
         ENDIF
      ENDDO
      IF !lPrg
         FWrite( han, iif( Asc(lastC ) < 20,"",Chr(10 ) ) + "#ENDSCRIPT" + Chr( 10 ) )
      ENDIF
   ENDIF

   RETURN Nil

   // ================================= EOF of opensave.prg ===================================
