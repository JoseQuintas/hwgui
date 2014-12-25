/*
 * Repbuild - Visual Report Builder
 * Open/save functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "guilib.ch"
#include "repbuild.h"
#include "repmain.h"
#include "fileio.ch"

#define SB_VERT         1

Memvar aPaintRep , mypath,aitemtypes

Function FileDlg( lOpen )
Local oDlg

   IF !lOpen .AND. ( aPaintRep == Nil .OR. Empty( aPaintRep[FORM_ITEMS] ) )
      hwg_Msgstop( "Nothing to save" )
      Return Nil
   ELSEIF lOpen
      CloseReport()
   ENDIF

   INIT DIALOG oDlg FROM RESOURCE "DLG_FILE" ON INIT {|| InitOpen(lOpen) }
   DIALOG ACTIONS OF oDlg ;
        ON 0,IDOK         ACTION {|| EndOpen(lOpen)}  ;
        ON BN_CLICKED,IDC_RADIOBUTTON1 ACTION {||hwg_Setdlgitemtext(oDlg:handle,IDC_TEXT1,"Report Name:")} ;
        ON BN_CLICKED,IDC_RADIOBUTTON2 ACTION {||hwg_Setdlgitemtext(oDlg:handle,IDC_TEXT1,"Function Name:")} ;
        ON BN_CLICKED,IDC_BUTTONBRW ACTION {||BrowFile(lOpen)}
   oDlg:Activate()

Return Nil

Static Function InitOpen( lOpen )
Local hDlg := hwg_GetModalHandle()
   hwg_Checkradiobutton( hDlg,IDC_RADIOBUTTON1,IDC_RADIOBUTTON3,IDC_RADIOBUTTON1 )
   hwg_Setwindowtext( hDlg, Iif( lOpen,"Open report","Save report" ) )
   hwg_Setfocus( hwg_Getdlgitem( hDlg, IDC_EDIT1 ) )
Return .T.

Static Function BrowFile( lOpen )
Local hDlg := hwg_GetModalHandle()
Local fname, s1, s2
   IF hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON1 )
      s1 := "Report files( *.rpt )"
      s2 := "*.rpt"
   ELSE
      s1 := "Program files( *.prg )"
      s2 := "*.prg"
   ENDIF
   IF lOpen
      fname := hwg_SelectFile( s1, s2,mypath )
   ELSE
      fname := hwg_SaveFile( s2,s1,s2,mypath )
   ENDIF
   hwg_Setdlgitemtext( hDlg, IDC_EDIT1, fname )
   hwg_Setfocus( hwg_Getdlgitem( hDlg, IDC_EDIT2 ) )
Return Nil

Static Function EndOpen( lOpen )
Local hDlg := hwg_GetModalHandle()
Local fname, repName
Local res := .T.

   fname := hwg_Getedittext( hDlg, IDC_EDIT1 )
   IF !Empty( fname )
      repName := hwg_Getedittext( hDlg, IDC_EDIT2 )

      IF lOpen
         IF ( res := OpenFile( fname,@repName ) )
            aPaintRep[FORM_Y] := 0
            hwg_Enablemenuitem( ,1, .T., .F. )
            hwg_Redrawwindow( Hwindow():GetMain():handle, RDW_ERASE + RDW_INVALIDATE )
         ELSE
            aPaintRep := Nil
            hwg_Enablemenuitem( ,1, .F., .F. )
         ENDIF
      ELSE
         res := SaveRFile( fname,repName )
         aPaintRep[FORM_FILENAME] := fname
         aPaintRep[FORM_REPNAME] := repName
      ENDIF

      IF res
         hwg_EndDialog( hDlg )
      ENDIF
   ELSE
      hwg_Setfocus( hwg_Getdlgitem( hDlg, IDC_EDIT1 ) )
   ENDIF
Return .T.

Function CloseReport
Local i, aItem
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
      hwg_Showscrollbar( Hwindow():GetMain():handle,SB_VERT,.F. )
      hwg_Redrawwindow( Hwindow():GetMain():handle, RDW_ERASE + RDW_INVALIDATE )
      hwg_Enablemenuitem( ,1, .F., .F. )
   ENDIF
Return .T.

Function SaveReport
Local fname

   IF ( aPaintRep == Nil .OR. Empty( aPaintRep[FORM_ITEMS] ) )
      hwg_Msgstop( "Nothing to save" )
      Return Nil
   ENDIF
   IF Empty( aPaintRep[FORM_FILENAME] )
      FileDlg( .F. )
   ELSE
      SaveRFile( aPaintRep[FORM_FILENAME], aPaintRep[FORM_REPNAME] )
   ENDIF

Return Nil

Static Function OpenFile( fname,repName )
LOCAL strbuf := Space(512), poz := 513, stroka, nMode := 0
Local han := FOPEN( fname, FO_READ + FO_SHARED )
Local i, itemName, aItem, res := .T., sFont
Local lPrg := ( Upper(FilExten(fname))=="PRG" ), cSource := "", vDummy, nFormWidth
   IF han <> - 1
      DO WHILE .T.
         stroka := RDSTR( han,@strbuf,@poz,512 )
         IF LEN( stroka ) = 0
            EXIT
         ENDIF
         IF Left( stroka,1 ) == ";"
            LOOP
         ENDIF
         IF nMode == 0
            IF lPrg
               IF Upper( Left( stroka,8 ) ) == "FUNCTION" .AND. ;
                   Upper( Ltrim( Substr( stroka,10 ) ) ) == Upper( repname )
                  nMode := 10
               ENDIF
            ELSE
               IF Left( stroka,1 ) == "#"
                  IF Upper( Substr( stroka,2,6 ) ) == "REPORT"
                     stroka := Ltrim( Substr( stroka,9 ) )
                     IF Empty( repName ) .OR. Upper( stroka ) == Upper( repName )
                        IF Empty( repName )
                           repName := stroka
                        ENDIF
                        nMode := 1
                        aPaintRep := { 0,0,0,0,0,{},fname,repName,.F.,0,Nil }
                     ENDIF
                  ENDIF
               ENDIF
            ENDIF
         ELSEIF nMode == 1
            IF Left( stroka,1 ) == "#"
               IF Upper( Substr( stroka,2,6 ) ) == "ENDREP"
                  Exit
               ELSEIF Upper( Substr( stroka,2,6 ) ) == "SCRIPT"
                  nMode := 2
                  IF aItem != Nil
                     aItem[ITEM_SCRIPT] := ""
                  ELSE
                     aPaintRep[FORM_VARS] := ""
                  ENDIF
               ENDIF
            ELSE
               IF ( itemName := NextItem( stroka,.T. ) ) == "FORM"
                  aPaintRep[FORM_WIDTH] := Val( NextItem( stroka ) )
                  aPaintRep[FORM_HEIGHT] := Val( NextItem( stroka ) )
                  nFormWidth := Val( NextItem( stroka ) )
               ELSEIF itemName == "TEXT"
                  Aadd( aPaintRep[FORM_ITEMS], { 1,NextItem(stroka),Val(NextItem(stroka)), ;
                           Val(NextItem(stroka)), Val(NextItem(stroka)), ;
                           Val(NextItem(stroka)),Val(NextItem(stroka)),Nil,NextItem(stroka), ;
                           Val(NextItem(stroka)),0,Nil,0 } )
                  aItem := Atail( aPaintRep[FORM_ITEMS] )
                  aItem[ITEM_FONT] := HFont():Add( NextItem( aItem[ITEM_FONT],.T.,"," ), ;
                    Val(NextItem( aItem[ITEM_FONT],,"," )),Val(NextItem( aItem[ITEM_FONT],,"," )), ;
                    Val(NextItem( aItem[ITEM_FONT],,"," )),Val(NextItem( aItem[ITEM_FONT],,"," )), ;
                    Val(NextItem( aItem[ITEM_FONT],,"," )),Val(NextItem( aItem[ITEM_FONT],,"," )), ;
                    Val(NextItem( aItem[ITEM_FONT],,"," )) )
                  IF aItem[ITEM_X1] == Nil .OR. aItem[ITEM_X1] == 0 .OR. ;
                     aItem[ITEM_Y1] == Nil .OR. aItem[ITEM_Y1] == 0 .OR. ;
                     aItem[ITEM_WIDTH] == Nil .OR. aItem[ITEM_WIDTH] == 0 .OR. ;
                     aItem[ITEM_HEIGHT] == Nil .OR. aItem[ITEM_HEIGHT] == 0
                     hwg_Msgstop( "Error: "+stroka )
                     res := .F.
                     EXIT
                  ENDIF
               ELSEIF itemName == "HLINE" .OR. itemName == "VLINE" .OR. itemName == "BOX"
                  Aadd( aPaintRep[FORM_ITEMS], { Iif(itemName=="HLINE",2,Iif(itemName=="VLINE",3,4)), ;
                           "",Val(NextItem(stroka)), ;
                           Val(NextItem(stroka)), Val(NextItem(stroka)), ;
                           Val(NextItem(stroka)),0,NextItem(stroka),Nil,0,0,Nil,0 } )
                  aItem := Atail( aPaintRep[FORM_ITEMS] )
                  aItem[ITEM_PEN] := HPen():Add( Val(NextItem( aItem[ITEM_PEN],.T.,"," )), ;
                          Val(NextItem( aItem[ITEM_PEN],,"," )),Val(NextItem( aItem[ITEM_PEN],,"," )) )
                  IF aItem[ITEM_X1] == Nil .OR. aItem[ITEM_X1] == 0 .OR. ;
                     aItem[ITEM_Y1] == Nil .OR. aItem[ITEM_Y1] == 0 .OR. ;
                     aItem[ITEM_WIDTH] == Nil .OR. aItem[ITEM_WIDTH] == 0 .OR. ;
                     aItem[ITEM_HEIGHT] == Nil .OR. aItem[ITEM_HEIGHT] == 0
                     hwg_Msgstop( "Error: "+stroka )
                     res := .F.
                     EXIT
                  ENDIF
               ELSEIF itemName == "BITMAP"
                  Aadd( aPaintRep[FORM_ITEMS], { 5, NextItem(stroka), ;
                           Val(NextItem(stroka)), ;
                           Val(NextItem(stroka)), Val(NextItem(stroka)), ;
                           Val(NextItem(stroka)),0,Nil,Nil,0,0,Nil,0 } )
                  aItem := Atail( aPaintRep[FORM_ITEMS] )
                  aItem[ITEM_BITMAP] := HBitmap():AddFile( aItem[ITEM_CAPTION] )
                  IF aItem[ITEM_X1] == Nil .OR. aItem[ITEM_X1] == 0 .OR. ;
                     aItem[ITEM_Y1] == Nil .OR. aItem[ITEM_Y1] == 0 .OR. ;
                     aItem[ITEM_WIDTH] == Nil .OR. aItem[ITEM_WIDTH] == 0 .OR. ;
                     aItem[ITEM_HEIGHT] == Nil .OR. aItem[ITEM_HEIGHT] == 0
                     hwg_Msgstop( "Error: "+stroka )
                     res := .F.
                     EXIT
                  ENDIF
               ELSEIF itemName == "MARKER"
                  Aadd( aPaintRep[FORM_ITEMS], { 6, NextItem(stroka),Val(NextItem(stroka)), ;
                           Val(NextItem(stroka)), Val(NextItem(stroka)), ;
                           Val(NextItem(stroka)), Val(NextItem(stroka)), ;
                           Nil,Nil,0,0,Nil,0 } )
                  aItem := Atail( aPaintRep[FORM_ITEMS] )
               ENDIF
            ENDIF
         ELSEIF nMode == 2
            IF Left( stroka,1 ) == "#" .AND. Upper( Substr( stroka,2,6 ) ) == "ENDSCR"
               nMode := 1
            ELSE
               IF aItem != Nil
                  aItem[ITEM_SCRIPT] += stroka+Chr(13)+chr(10)
               ELSE
                  aPaintRep[FORM_VARS] += stroka+Chr(13)+chr(10)
               ENDIF
            ENDIF
         ELSEIF nMode == 10
            IF UPPER( Left( stroka,15 ) ) == "LOCAL APAINTREP"
               nMode := 11
            ELSE
               hwg_Msgstop( "Wrong function "+repname )
               Fclose( han )
               Return .F.
            ENDIF
         ELSEIF nMode == 11
            IF UPPER( Left( stroka,6 ) ) == "RETURN"
               Exit
            ELSE
               IF Right( stroka,1 ) == ";"
                  cSource += Ltrim( Rtrim( Left( stroka,Len(stroka)-1 ) ) )
               ELSE
                  cSource += Ltrim( Rtrim( stroka ) )
                  // Writelog( cSource )
                  vDummy := &cSource
                  cSource := ""
               ENDIF
            ENDIF
         ENDIF
      ENDDO
      Fclose( han )
   ELSE
      hwg_Msgstop( "Can't open "+fname )
      Return .F.
   ENDIF
   IF aPaintRep == Nil .OR. Empty( aPaintRep[FORM_ITEMS] )
      hwg_Msgstop( repname+" not found or empty!" )
      res := .F.
   ELSE
      hwg_Enablemenuitem( ,IDM_CLOSE, .T., .T. )
      hwg_Enablemenuitem( ,IDM_SAVE, .T., .T. )
      hwg_Enablemenuitem( ,IDM_SAVEAS, .T., .T. )
      hwg_Enablemenuitem( ,IDM_PRINT, .T., .T. )
      hwg_Enablemenuitem( ,IDM_PREVIEW, .T., .T. )
      hwg_Enablemenuitem( ,IDM_FOPT, .T., .T. )

      aPaintRep[FORM_ITEMS] := Asort( aPaintRep[FORM_ITEMS],,, {|z,y|z[ITEM_Y1]<y[ITEM_Y1].OR.(z[ITEM_Y1]==y[ITEM_Y1].AND.z[ITEM_X1]<y[ITEM_X1]).OR.(z[ITEM_Y1]==y[ITEM_Y1].AND.z[ITEM_X1]==y[ITEM_X1].AND.(z[ITEM_WIDTH]<y[ITEM_WIDTH].OR.z[ITEM_HEIGHT]<y[ITEM_HEIGHT]))} )
      IF !lPrg
         hwg_RecalcForm( aPaintRep,nFormWidth )
      ENDIF

      hwg_WriteStatus( Hwindow():GetMain(),2,Ltrim(Str(aPaintRep[FORM_WIDTH],4))+"x"+ ;
                 Ltrim(Str(aPaintRep[FORM_HEIGHT],4))+"  Items: "+Ltrim(Str(Len(aPaintRep[FORM_ITEMS]))) )
   ENDIF
Return res

Static Function SaveRFile( fname,repName )
LOCAL strbuf := Space(512), poz := 513, stroka, nMode := 0
Local han, hanOut, isOut := .F., res := .F.
Local lPrg := ( Upper(FilExten(fname))=="PRG" )

   IF File( fname )
      han := FOPEN( fname, FO_READWRITE + FO_EXCLUSIVE )
      IF han <> - 1
         hanOut := FCREATE( mypath+"__rpt.tmp" )
         IF hanOut <> - 1
            DO WHILE .T.
               stroka := RDSTR( han,@strbuf,@poz,512 )
               IF LEN( stroka ) = 0
                  EXIT
               ENDIF
               IF nMode == 0
                  IF ( lPrg .AND. Upper( Left( stroka,8 ) ) == "FUNCTION" ) ;
                        .OR. ( !lPrg .AND. Left( stroka,1 ) == "#" .AND. ;
                           Upper( Substr( stroka,2,6 ) ) == "REPORT" )
                     IF Upper( Ltrim( Substr( stroka,9 ) ) ) == Upper( repName )
                        nMode := 1
                        isOut := .T.
                        LOOP
                     ENDIF
                  ENDIF
                  Fwrite( hanOut,stroka+Iif(Asc(Right(stroka,1))<20,"",Chr(10)) )
               ELSEIF nMode == 1
                  IF ( lPrg .AND. Left( stroka,6 ) == "RETURN" ) ;
                      .OR. ( !lPrg .AND. Left( stroka,1 ) == "#" .AND. ;
                       Upper( Substr( stroka,2,6 ) ) == "ENDREP" )
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
               Fclose( hanOut )
               Fclose( han )
               IF Ferase( fname ) == -1 .OR. Frename( mypath+"__rpt.tmp",fname ) == -1
                  hwg_Msgstop( "Can't rename __rpt.tmp" )
               ELSE
                  res := .T.
               ENDIF
            ELSE
               Fseek( han,0,FS_END )
               Fwrite( han, Chr(10 ) )
               IF lPrg
                  WriteToPrg( han, repName )
               ELSE
                  WriteRep( hanOut, repName )
               ENDIF
               Fclose( hanOut )
               Fclose( han )
               res := .T.
            ENDIF
         ELSE
            hwg_Msgstop( "Can't create __rpt.tmp" )
            Fclose( han )
         ENDIF
      ELSE
         hwg_Msgstop( "Can't open "+fname )
      ENDIF
   ELSE
      han := Fcreate( fname )
      IF lPrg
         WriteToPrg( han, repName )
      ELSE
         WriteRep( han, repName )
      ENDIF
      Fclose( han )
      res := .T.
   ENDIF
   IF res
      aPaintRep[FORM_CHANGED] := .F.
   ENDIF

Return res

Static Function WriteRep( han, repName )
Local i, aItem, oPen, oFont, hDCwindow, aMetr

   hDCwindow := hwg_Getdc( Hwindow():GetMain():handle )
   aMetr := hwg_GetDeviceArea( hDCwindow )
   hwg_Releasedc( Hwindow():GetMain():handle,hDCwindow )

   Fwrite( han, "#REPORT "+repName+Chr(10) )
   Fwrite( han, "FORM;"+ Ltrim(Str(aPaintRep[FORM_WIDTH])) + ";" + ;
                         Ltrim(Str(aPaintRep[FORM_HEIGHT])) + ";" + ;
                         Ltrim(Str(aMetr[1]-XINDENT)) + Chr(10) )
   WriteScript( han,aPaintRep[FORM_VARS] )

   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      aItem := aPaintRep[FORM_ITEMS,i]
      IF aItem[ITEM_TYPE] == TYPE_TEXT
         oFont := aItem[ITEM_FONT]
         Fwrite( han, aItemTypes[aItem[ITEM_TYPE]] + ";" + aItem[ITEM_CAPTION] + ";" + ;
             Ltrim(Str(aItem[ITEM_X1],4)) + ";" + Ltrim(Str(aItem[ITEM_Y1],4)) + ";" + ;
             Ltrim(Str(aItem[ITEM_WIDTH],4)) + ";" + Ltrim(Str(aItem[ITEM_HEIGHT],4)) +;
             ";" + Str(aItem[ITEM_ALIGN],1) + ";" + oFont:name ;
             + "," + Ltrim(Str(oFont:width)) + "," + Ltrim(Str(oFont:height)) ;
             + "," + Ltrim(Str(oFont:weight)) + "," + Ltrim(Str(oFont:charset)) ;
             + "," + Ltrim(Str(oFont:italic)) + "," + Ltrim(Str(oFont:underline)) ;
             + "," + Ltrim(Str(oFont:strikeout)) + ";" + Str(aItem[ITEM_VAR],1) + Chr(10) )
         WriteScript( han,aItem[ITEM_SCRIPT] )
      ELSEIF aItem[ITEM_TYPE] == TYPE_HLINE .OR. aItem[ITEM_TYPE] == TYPE_VLINE .OR. aItem[ITEM_TYPE] == TYPE_BOX
         oPen := aItem[ITEM_PEN]
         Fwrite( han, aItemTypes[aItem[ITEM_TYPE]] + ";" + ;
             Ltrim(Str(aItem[ITEM_X1],4)) + ";" + Ltrim(Str(aItem[ITEM_Y1],4)) + ";" + ;
             Ltrim(Str(aItem[ITEM_WIDTH],4)) + ";" + Ltrim(Str(aItem[ITEM_HEIGHT],4)) + ;
             ";" + Ltrim(Str(oPen:style)) + "," + Ltrim(Str(oPen:width)) + "," + Ltrim(Str(oPen:color)) ;
             + Chr(10) )
      ELSEIF aItem[ITEM_TYPE] == TYPE_BITMAP
         Fwrite( han, aItemTypes[aItem[ITEM_TYPE]] + ";" + aItem[ITEM_CAPTION] + ";" + ;
             Ltrim(Str(aItem[ITEM_X1],4)) + ";" + Ltrim(Str(aItem[ITEM_Y1],4)) + ";" + ;
             Ltrim(Str(aItem[ITEM_WIDTH],4)) + ";" + Ltrim(Str(aItem[ITEM_HEIGHT],4)) + ;
             + Chr(10) )
      ELSEIF aItem[ITEM_TYPE] == TYPE_MARKER
         Fwrite( han, aItemTypes[aItem[ITEM_TYPE]] + ";" + aItem[ITEM_CAPTION] + ";" + ;
             Ltrim(Str(aItem[ITEM_X1],4)) + ";" + Ltrim(Str(aItem[ITEM_Y1],4)) + ";" + ;
             Ltrim(Str(aItem[ITEM_WIDTH],4)) + ";" + Ltrim(Str(aItem[ITEM_HEIGHT],4)) + ;
             ";" + Str(aItem[ITEM_ALIGN],1) + Chr( 10 ) )
         WriteScript( han,aItem[ITEM_SCRIPT] )
      ENDIF
   NEXT
   Fwrite( han, "#ENDREP "+Chr(10) )
Return Nil

Static Function WriteToPrg( han, repName )
Local i, aItem, oPen, oFont, hDCwindow, aMetr, cItem, cQuote, cPen, cFont

   hDCwindow := hwg_Getdc( Hwindow():GetMain():handle )
   aMetr := hwg_GetDeviceArea( hDCwindow )
   hwg_Releasedc( Hwindow():GetMain():handle,hDCwindow )

   Fwrite( han, "FUNCTION " + repName + Chr(10) + ;
         "LOCAL aPaintRep" + Chr(10) )
   Fwrite( han, "   cEnd:=Chr(13)+Chr(10)" + Chr(10) )
   Fwrite( han, "   aPaintRep := { "+Ltrim(Str(aPaintRep[FORM_WIDTH]))+","+ ;
         Ltrim(Str(aPaintRep[FORM_HEIGHT]))+',0,0,0,{},,"'+repName+'",.F.,0,Nil }'+Chr(10) )
   IF aPaintRep[FORM_VARS] != Nil .AND. !Empty( aPaintRep[FORM_VARS] )
      Fwrite( han, "   aPaintRep[11] := ;"+Chr(10) )
      WriteScript( han,aPaintRep[FORM_VARS],.T. )
   ENDIF

   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      aItem := aPaintRep[FORM_ITEMS,i]

      cItem := Ltrim(Str(aItem[ITEM_TYPE],1)) + ","
      IF aItem[ITEM_TYPE]==TYPE_TEXT.OR.aItem[ITEM_TYPE]==TYPE_BITMAP ;
              .OR.aItem[ITEM_TYPE]==TYPE_MARKER
         cQuote := Iif(!( '"' $ aItem[ITEM_CAPTION]),'"', ;
                     Iif(!( "'" $ aItem[ITEM_CAPTION]),"'","["))
         cItem += cQuote + aItem[ITEM_CAPTION] + cQuote
      ENDIF
      cItem += ","+Ltrim(Str(aItem[ITEM_X1],4)) + "," + Ltrim(Str(aItem[ITEM_Y1],4)) + "," + ;
               Ltrim(Str(aItem[ITEM_WIDTH],4)) + "," + Ltrim(Str(aItem[ITEM_HEIGHT],4)) + ;
               "," + Str(aItem[ITEM_ALIGN],1)
      IF aItem[ITEM_TYPE] == TYPE_HLINE .OR. aItem[ITEM_TYPE] == TYPE_VLINE ;
              .OR. aItem[ITEM_TYPE] == TYPE_BOX
         oPen := aItem[ITEM_PEN]
         cItem += ",HPen():Add(" + Ltrim(Str(oPen:style)) + "," + ;
                 Ltrim(Str(oPen:width)) + "," + Ltrim(Str(oPen:color)) + ")"
      ELSE
         cItem += ",0"
      ENDIF
      IF aItem[ITEM_TYPE] == TYPE_TEXT
         oFont := aItem[ITEM_FONT]
         cItem += ',HFont():Add( "' + oFont:name + ;
             + '",' + Ltrim(Str(oFont:width)) + "," + Ltrim(Str(oFont:height)) ;
             + "," + Ltrim(Str(oFont:weight)) + "," + Ltrim(Str(oFont:charset)) ;
             + "," + Ltrim(Str(oFont:italic)) + "," + Ltrim(Str(oFont:underline)) ;
             + "," + Ltrim(Str(oFont:strikeout)) + " )," + Str(aItem[ITEM_VAR],1)
      ELSE
         cItem += ",0,0"
      ENDIF
      cItem += ",0,Nil,0"
      Fwrite( han, "   Aadd( aPaintRep[6], { " + cItem + " } )" + Chr(10) )

      IF aItem[ITEM_SCRIPT] != Nil .AND. !Empty( aItem[ITEM_SCRIPT] )
         Fwrite( han, "   aPaintRep[6,Len(aPaintRep[6]),12] := ;"+Chr(10) )
         WriteScript( han,aItem[ITEM_SCRIPT],.T. )
      ENDIF
   NEXT
   Fwrite( han, "   hwg_RecalcForm( aPaintRep,"+Ltrim(Str(aMetr[1]-XINDENT))+" )"+Chr(10) )
   Fwrite( han, "RETURN hwg_SetPaintRep( aPaintRep )"+Chr(10) )
Return Nil

Static Function WriteScript( han,cScript,lPrg )
Local poz := 0, stroka, i
Local lastC := Chr(10), cQuote, lFirst := .T.

   IF lPrg == Nil; lPrg := .F.; ENDIF
   IF cScript != Nil .AND. !Empty( cScript )
      IF !lPrg
         Fwrite( han,"#SCRIPT"+Chr(10) )
      ENDIF
      DO WHILE .T.
         stroka := RDSTR( , cScript, @poz )
         IF LEN( stroka ) = 0
            IF lPrg
               Fwrite( han,Chr(10) )
            ENDIF
            EXIT
         ENDIF
         IF Left( stroka,1 ) != Chr(10)
            IF lPrg
               cQuote := Iif(!( '"' $ stroka),'"', ;
                           Iif(!( "'" $ stroka),"'","["))
               Fwrite( han,Iif(lFirst,"",";"+Chr(10))+Space(5)+;
                     Iif(lFirst,"","+ ")+cQuote+stroka+cQuote+"+cEnd" )
               lFirst := .F.
            ELSE
               Fwrite( han,Iif( Asc(lastC)<20,"",Chr(10) )+stroka )
               lastC := Right( stroka,1 )
            ENDIF
         ENDIF
      ENDDO
      IF !lPrg
         Fwrite( han, Iif( Asc(lastC)<20,"",Chr(10) )+"#ENDSCRIPT"+Chr(10) )
      ENDIF
   ENDIF
Return Nil
