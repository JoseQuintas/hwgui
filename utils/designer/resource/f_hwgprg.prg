#SCRIPT WRITE
FUNCTION Style2Prg( oCtrl )
Local cStyle := ""

   IF oCtrl:cClass == "label"
   ELSEIF oCtrl:cClass == "editbox"
   ENDIF
Return cStyle
ENDFUNC

FUNCTION Ctrl2Prg
PARAMETERS oCtrl
PRIVATE stroka := "   @ ", classname, cStyle, i, cName, temp

   i := Ascan( aClass, oCtrl:cClass )
   IF i != 0
      stroka += Ltrim( Str(oCtrl:nLeft) ) + "," + Ltrim( Str(oCtrl:nTop) ) + " " + aName[i] + " "
      temp := oCtrl:GetProp( "Caption" )
      IF ( cName := oCtrl:GetProp( "Name" ) ) != Nil .AND. !Empty( cName )
         stroka += cName + Iif( temp != Nil," CAPTION ", " " )
      ENDIF
      IF temp != Nil
         stroka += '"' + temp + '" '
      ENDIF
      IF oCtrl:oContainer != Nil
         stroka += "OF " + oCtrl:oContainer:GetProp( "Name" ) + " "
      ENDIF
      stroka +=  "SIZE " + Ltrim( Str(oCtrl:nWidth) ) + "," + Ltrim( Str(oCtrl:nHeight) ) + " "
      stroka += CallFunc( "Style2Prg", { oCtrl } ) + " "
      IF oCtrl:tcolor != Nil .AND. oCtrl:tcolor != 0
         stroka += Iif( Empty(cStyle),"",";" + _Chr(10) + Space(8) ) + &&
              "COLOR " + Ltrim( Str(oCtrl:tcolor) ) + " "
      ENDIF
      IF oCtrl:bcolor != Nil
         stroka += "BACKCOLOR " + Ltrim( Str(oCtrl:bcolor) )
      ENDIF
   ENDIF
   Fwrite( han, stroka + _Chr(10) )
   IF !Empty( oCtrl:aControls )
      i := 1
      DO WHILE i <= Len( oCtrl:aControls )
         CallFunc( "Ctrl2Prg", { oCtrl:aControls[i] } )
         i ++
      ENDDO
   ENDIF
Return
ENDFUNC

Private han, fname := oForm:path + oForm:filename, stroka, oCtrl
Private aControls := oForm:oDlg:aControls, alen := Len( aControls ), i
Private cName := oForm:GetProp( "Name" ), temp
Private aClass := { "label", "button", "checkbox", "radiobutton", "editbox", &&
  "group", "datepicker", "updown", "combobox", "line", "toolbar", "ownerbutton", &&
  "browse" }
Private aName :=  { "SAY", "BUTTON", "CHECKBOX", "RADIOBUTTON", "EDITBOX", &&
  "GROUP", "DATEPICKER", "UPDOWN", "COMBOBOX", "LINE", "PANEL", "OWNERBUTTON", &&
  "BROWSE" }

   han := Fcreate( fname )

   Fwrite( han, "FUNCTION " + oForm:name + _Chr(10)  )
   Fwrite( han, "LOCAL " + cName )
   i := 1
   DO WHILE i <= aLen
      IF ( temp := aControls[i]:GetProp( "Name" ) ) != Nil .AND. !Empty( temp )
         Fwrite( han, ", " + temp )
      ENDIF
      i ++
   ENDDO
   Fwrite( han, _Chr(10) + _Chr(10) + '   INIT DIALOG oDlg TITLE "' + oForm:oDlg:title + '" ;' + _Chr(10) )
   Fwrite( han, Space(8) + "AT " + Ltrim( Str(oForm:oDlg:nLeft) ) + "," &&
      + Ltrim( Str(oForm:oDlg:nTop) ) + " SIZE " + &&
        Ltrim( Str(oForm:oDlg:nHeight) ) + "," + Ltrim( Str(oForm:oDlg:nWidth) ) + _Chr(10) + _Chr(10) )

   i := 1
   DO WHILE i <= aLen
      IF aControls[i]:oContainer == Nil
         CallFunc( "Ctrl2Prg", { aControls[i] } )
      ENDIF
      i ++
   ENDDO

   Fwrite( han, _Chr(10) + "   ACTIVATE DIALOG oDlg" + _Chr(10) )
   Fwrite( han, "RETURN" )
   Fclose( han )
#ENDSCRIPT
