#SCRIPT TABLE
aCtrlTable := { { "STATIC","label" }, { "BUTTON","button" }, &&
    { "CHECKBOX","checkbox" }, { "RADIOBUTTON","radiobutton" },   &&
    { "EDITBOX","editbox" }, { "GROUPBOX","group" }, { "DATEPICKER","datepicker" }, &&
    { "UPDOWN","updown" }, { "COMBOBOX","combobox" }, { "HLINE","line" }, &&
    { "PANEL","toolbar" }, { "OWNERBUTTON","ownerbutton" }, &&
    { "BROWSE","browse" } }
#ENDSCRIPT

#SCRIPT READ
FUNCTION STR2FONT
PARAMETERS cFont
PRIVATE oFont
   IF !Empty( cFont )
      oFont := HFont():Add( NextItem( cFont,.T.,"," ), &&
            Val(NextItem( cFont,,"," )),Val(NextItem( cFont,,"," )), &&
            Val(NextItem( cFont,,"," )),Val(NextItem( cFont,,"," )), &&
            Val(NextItem( cFont,,"," )),Val(NextItem( cFont,,"," )), &&
            Val(NextItem( cFont,,"," )) )
   ENDIF
Return oFont
ENDFUNC

Private strbuf := Space(512), poz := 513, stroka, nMode := 0, itemName, i
Private han := FOPEN( oForm:path+oForm:filename )
Private cCaption, x, y, nWidth, nHeight, nStyle, lClipper, oFont, tColor, bColor, cFont

   IF han == - 1
      hwg_Msgstop( "Can't open "+oForm:path+oForm:filename )
      Return
   ENDIF
   DO WHILE .T.
      stroka := RDSTR( han,@strbuf,@poz,512 )
      IF LEN( stroka ) == 0
         EXIT
      ENDIF
      stroka := Ltrim( stroka )
      IF nMode == 0
         IF Left( stroka,1 ) == "#"
            IF Upper( Substr( stroka,2,4 ) ) == "FORM"
               stroka := Ltrim( Substr( stroka,7 ) )
               itemName := NextItem( stroka,.T. )
               IF Empty( oForm:name ) .OR. Upper( itemName ) == Upper( oForm:name )
                  x := NextItem( stroka )
                  y := NextItem( stroka )
                  nWidth := NextItem( stroka )
                  nHeight := NextItem( stroka )
                  nStyle := Val( NextItem( stroka ) )
                  oForm:lGet := ( Upper( NextItem( stroka) ) == "T" )
                  lClipper := ( Upper( NextItem( stroka ) ) == "T" )
                  cFont := NextItem( stroka )
                  oFont := CallFunc( "Str2Font", { cFont } )
                  oForm:CreateDialog( { {"Left",x}, {"Top",y},{"Width",nWidth},{"Height",nHeight},{"Caption",itemName},{"Font",oFont} } )
                  nMode := 1
               ENDIF
            ENDIF
         ENDIF
      ELSEIF nMode == 1
         IF Left( stroka,1 ) == "#"
            IF Upper( Substr( stroka,2,7 ) ) == "ENDFORM"
               Exit
            ENDIF
         ELSE           
            itemName := CnvCtrlName( NextItem( stroka,.T. ) )
            IF itemName == Nil
               hwg_Msgstop( "Wrong item name: " + NextItem( stroka,.T. ) )
               Return
            ENDIF
            cCaption := NextItem( stroka )
            NextItem( stroka )
            x := NextItem( stroka )
            y := NextItem( stroka )
            nWidth := NextItem( stroka )
            nHeight := NextItem( stroka )
            nStyle := Val( NextItem( stroka ) )
            cFont := NextItem( stroka )
            tColor := NextItem( stroka )
            bColor := NextItem( stroka )
            oFont := CallFunc( "Str2Font", { cFont } )
            HControlGen():New( oForm:oDlg,itemName, &&
             { { "Left",x }, { "Top",y }, { "Width",nWidth }, &&
             { "Height",nHeight }, { "Caption",cCaption }, &&
             { "TextColor",tColor }, { "BackColor",bColor },{"Font",oFont} } )
         ENDIF
      ENDIF
   ENDDO
   Fclose( han )
Return
#ENDSCRIPT

#SCRIPT WRITE
Private han, fname := oForm:path + oForm:filename, stroka, oCtrl
Private aControls := oForm:oDlg:aControls, alen := Len( aControls ), i

   han := Fcreate( fname )
   Fwrite( han, "#FORM " + oForm:name &&
       + ";" + Ltrim( Str(oForm:oDlg:nLeft) )    &&
       + ";" + Ltrim( Str(oForm:oDlg:nTop) )     &&
       + ";" + Ltrim( Str(oForm:oDlg:nWidth) )   &&
       + ";" + Ltrim( Str(oForm:oDlg:nHeight ) ) &&
       + ";" + Ltrim( Str(oForm:oDlg:style) )    &&
       + ";" + Iif(oForm:lGet,"T","F")           &&
       + ";" + Iif(oForm:oDlg:lClipper,"T","F")  &&
       + ";" + Iif(oForm:oDlg:oFont!=Nil,        &&
       oForm:oDlg:oFont:name + "," + Ltrim(Str(oForm:oDlg:oFont:width)) &&
       + "," + Ltrim(Str(oForm:oDlg:oFont:height)) + "," + Ltrim(Str(oForm:oDlg:oFont:weight)) &&
       + "," + Ltrim(Str(oForm:oDlg:oFont:charset)) + "," + Ltrim(Str(oForm:oDlg:oFont:italic)) &&
       + "," + Ltrim(Str(oForm:oDlg:oFont:underline)) + "," + Ltrim(Str(oForm:oDlg:oFont:strikeout)) &&
       ,"") &&
       + _Chr(10) )
   i := 1
   DO WHILE i <= alen
      oCtrl := aControls[i]
      stroka := CnvCtrlName( oCtrl:cClass,.T. ) + ";" + Rtrim( oCtrl:title) &&
          + ";" + Ltrim( Str(Iif(oCtrl:id<34000,oCtrl:id,0)) ) &&
          + ";" + Ltrim( Str(oCtrl:nLeft) )    &&
          + ";" + Ltrim( Str(oCtrl:nTop) )     &&
          + ";" + Ltrim( Str(oCtrl:nWidth) )   &&
          + ";" + Ltrim( Str(oCtrl:nHeight ) ) &&
          + ";" + Ltrim( Str(oCtrl:style) )    &&
          + ";" + Iif(oCtrl:oFont!=Nil,        &&
          oCtrl:oFont:name + "," + Ltrim(Str(oCtrl:oFont:width)) &&
          + "," + Ltrim(Str(oCtrl:oFont:height)) + "," + Ltrim(Str(oCtrl:oFont:weight)) &&
          + "," + Ltrim(Str(oCtrl:oFont:charset)) + "," + Ltrim(Str(oCtrl:oFont:italic)) &&
          + "," + Ltrim(Str(oCtrl:oFont:underline)) + "," + Ltrim(Str(oCtrl:oFont:strikeout)) &&
          ,"")  &&
          + ";" + Iif(oCtrl:tcolor!=Nil.AND.oCtrl:tcolor!=0,Ltrim(Str(oCtrl:tcolor)),"") &&
          + ";" + Iif(oCtrl:bcolor!=Nil,Ltrim(Str(oCtrl:bcolor)),"")
      Fwrite( han, stroka + _Chr(10) )
      i++
   ENDDO
   Fwrite( han, "#ENDFORM " )
   Fwrite( han, _Chr(10 ) )
   Fclose( han )
#ENDSCRIPT
