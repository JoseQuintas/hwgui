#SCRIPT WRITE
#DEBUG
FUNCTION Style2Prg
PARAMETERS oCtrl
Private cStyle := ""

   IF oCtrl:cClass == "label"
   ELSEIF oCtrl:cClass == "editbox"
   ENDIF
Return cStyle
ENDFUNC

FUNCTION Func_name
Parameters oCtrl,nMeth
Private cName, arr := ParseMethod( oCtrl:aMethods[nMeth,2] )
   IF Len( arr ) == 1 .OR. ( Len( arr ) == 2 .AND. Lower( Left(arr[1],11) ) == "parameters " )
      Return arr
   ELSE
      IF ( cName := oCtrl:GetProp( "Name" ) ) == Nil .OR. Empty(cName)
        cName := oCtrl:cClass+"_"+Ltrim(Str(oCtrl:id-34000))
      ENDIF
      cName += "_" + oCtrl:aMethods[nMeth,1]
   ENDIF
Return cName
ENDFUNC

FUNCTION Ctrl2Prg
PARAMETERS oCtrl
PRIVATE stroka := "   @ ", classname, cStyle, i, j, cName, temp, varname, cMethod

  i := Ascan( aClass, oCtrl:cClass )
  IF i != 0
    varname := oCtrl:GetProp( "varName" )
    stroka += Ltrim( Str(oCtrl:nLeft) ) + "," + Ltrim( Str(oCtrl:nTop) ) + " "
    temp := oCtrl:GetProp( "Caption" )
    IF ( cName := oCtrl:GetProp( "Name" ) ) == Nil
      cName := ""
    ENDIF
    IF varname == Nil
      stroka += aName[i,1] + " " + cName + ;
            Iif( temp!=Nil,Iif( !Empty(cName),' CAPTION "'+temp,' "'+temp )+'"',"" ) + " "
    ELSE
      stroka += aName[i,2] + Iif( !Empty(cName), cName+" VAR "," " ) + varname + " "
    ENDIF
    IF oCtrl:oContainer != Nil
      stroka += "OF " + oCtrl:oContainer:GetProp( "Name" ) + " "
    ENDIF
   stroka +=  "SIZE " + Ltrim( Str(oCtrl:nWidth) ) + "," + Ltrim( Str(oCtrl:nHeight) ) + " "
    stroka += CallFunc( "Style2Prg", { oCtrl } ) + " "
    IF oCtrl:GetProp( "Textcolor",@j ) != Nil .AND. !IsDefault( oCtrl,oCtrl:aProp[j] )
      stroka += Iif( Empty(cStyle),"",";" + _Chr(10) + Space(8) ) + ;
            "COLOR " + Ltrim( Str(oCtrl:tcolor) ) + " "
    ENDIF
    IF oCtrl:GetProp( "Backcolor",@j ) != Nil .AND. !IsDefault( oCtrl,oCtrl:aProp[j] )
      stroka += "BACKCOLOR " + Ltrim( Str(oCtrl:bcolor) )
    ENDIF
  ENDIF
  Fwrite( han, stroka )

  // Methods ( events ) for the control
  i := 1
  DO WHILE i <= Len( oCtrl:aMethods )
    IF oCtrl:aMethods[i,2] != Nil .AND. !Empty(oCtrl:aMethods[i,2])
      IF Lower( Left( oCtrl:aMethods[i,2],10 ) ) == "parameters"
        j := At( _Chr(10),oCtrl:aMethods[i,2] )
        temp := Substr( oCtrl:aMethods[i,2],12,j-12 )
      ELSE
        temp := ""
      ENDIF
      IF varname != Nil .AND. ( Lower(oCtrl:aMethods[i,1]) == "ongetfocus" ;
                           .OR. Lower(oCtrl:aMethods[i,1]) == "onlostfocus" )
         cMethod := Iif( Lower(oCtrl:aMethods[i,1]) == "ongetfocus","WHEN ","VALID " )
      ELSE
        cMethod := "ON " + Upper(Substr(oCtrl:aMethods[i,1],3))
      ENDIF
      IF Valtype( cName := Callfunc( "FUNC_NAME",{ oCtrl,i } ) ) == "C"
        Fwrite( han, " ;" + _Chr(10) + Space(8) + cMethod + " {|" + ;
             temp + "|" + cName + "(" + temp + ")}" )
      ELSE
        Fwrite( han, " ;" + _Chr(10) + Space(8) + cMethod + " {|" + ;
             temp + "|" + Iif(Len(cName)==1,cName[1],cName[2]) + "}" )
      ENDIF
    ENDIF
    i ++
  ENDDO

  Fwrite( han, _Chr(10) )

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
Private aControls := oForm:oDlg:aControls, alen := Len( aControls ), i, j, j1
Private cName := oForm:GetProp( "Name" ), temp
Private aClass := { "label", "button", "checkbox", "radiobutton", "editbox", ;
  "group", "datepicker", "updown", "combobox", "line", "toolbar", "ownerbutton", ;
  "browse" }
Private aName :=  { {"SAY"}, {"BUTTON"}, {"CHECKBOX","GET CHECKBOX"}, {"RADIOBUTTON"}, {"EDITBOX","GET"}, ;
  {"GROUPBOX"}, {"DATEPICKER","GET DATEPICKER"}, {"UPDOWN","GET UPDOWN"}, ;
  {"COMBOBOX","GET COMBOBOX"}, {"LINE"}, {"PANEL"}, {"OWNERBUTTON"}, ;
  {"BROWSE"} }

//  Group subtituido por GroupBox
//  {"GROUP"}, {"DATEPICKER","GET DATEPICKER"}, {"UPDOWN","GET UPDOWN"}, ;

  han := Fcreate( fname )

  //Add the lines to include
  Fwrite( han,'#include "windows.ch"'+ _Chr(10)  )
  Fwrite( han,'#include "guilib.ch"' + _Chr(10)+ _Chr(10) )

  Fwrite( han, "FUNCTION " + "_"+Iif(cName!=Nil,cName,"Padrao") + _Chr(10)  )
  // Declare 'Private' variables
  IF cName != Nil
    Fwrite( han, "PRIVATE " + cName )
  ENDIF
  i := 1
  stroka := ""
  DO WHILE i <= aLen
    IF ( temp := aControls[i]:GetProp( "Name" ) ) != Nil .AND. !Empty( temp )
       stroka += Iif( Empty(stroka),"PRIVATE ",", " ) + temp
    ENDIF
    i ++
  ENDDO
  IF !Empty( stroka )
     Fwrite( han, stroka )
  ENDIF
  stroka := ""
  i := 1
  DO WHILE i <= aLen
    IF ( temp := aControls[i]:GetProp( "VarName" ) ) != Nil .AND. !Empty( temp )
       stroka += Iif( !Empty(stroka),", ","" ) + temp
    ENDIF
    i ++
  ENDDO
  IF ! Empty( stroka )
    stroka := "PRIVATE " + stroka
    Fwrite( han, _Chr(10) + stroka )
  ENDIF

  i := 1
  DO WHILE i <= Len( oForm:aMethods )
    IF oForm:aMethods[i,2] != Nil .AND. !Empty(oForm:aMethods[i,2])
      IF Lower( oForm:aMethods[i,1] ) == "onforminit"
        Fwrite( han, _Chr(10)+_Chr(10) )
        Fwrite( han, oForm:aMethods[i,2] )
      ENDIF
    ENDIF
    i ++
  ENDDO

  // 'INIT DIALOG' command
  Fwrite( han, _Chr(10) + _Chr(10) + '   INIT DIALOG oDlg TITLE "' + oForm:oDlg:title + '" ;' + _Chr(10) )
  Fwrite( han, Space(8) + "AT " + Ltrim( Str(oForm:oDlg:nLeft) ) + "," ;
     + Ltrim( Str(oForm:oDlg:nTop) ) + " SIZE " + ;
       Ltrim( Str(oForm:oDlg:nWidth) ) + "," + Ltrim( Str(oForm:oDlg:nHeight) ) )

// The line is inverted
//       Ltrim( Str(oForm:oDlg:nHeight) ) + "," + Ltrim( Str(oForm:oDlg:nWidth) ) )

  i := 1
  DO WHILE i <= Len( oForm:aMethods )
    IF oForm:aMethods[i,2] != Nil .AND. !Empty(oForm:aMethods[i,2])
      IF Lower( oForm:aMethods[i,1] ) == "ondlginit"
        Fwrite( han, " ;" + _Chr(10) + Space(8) + "ON INIT {||onDlgInit()}" )
      ELSEIF Lower( oForm:aMethods[i,1] ) == "onpaint"
        Fwrite( han, " ;" + _Chr(10) + Space(8) + "ON PAINT {||onPaint()}" )
      ELSEIF Lower( oForm:aMethods[i,1] ) == "ondlgexit"
        Fwrite( han, " ;" + _Chr(10) + Space(8) + "ON EXIT {||onDlgExit()}" )
      ENDIF
    ENDIF
    i ++
  ENDDO
  Fwrite( han, _Chr(10) + _Chr(10) )

  // Controls initialization
  i := 1
  DO WHILE i <= aLen
    IF aControls[i]:oContainer == Nil
       CallFunc( "Ctrl2Prg", { aControls[i] } )
    ENDIF
    i ++
  ENDDO

  Fwrite( han, _Chr(10) + "   ACTIVATE DIALOG oDlg" + _Chr(10) )

  i := 1
  DO WHILE i <= Len( oForm:aMethods )
    IF oForm:aMethods[i,2] != Nil .AND. !Empty(oForm:aMethods[i,2])
      IF Lower( oForm:aMethods[i,1] ) == "onformexit"
        Fwrite( han, oForm:aMethods[i,2] )
        Fwrite( han, _Chr(10) + _Chr(10) )
      ENDIF
    ENDIF
    i ++
  ENDDO

  Fwrite( han, "RETURN" + _Chr(10) + _Chr(10) )

  // Dialog methods
  i := 1
  DO WHILE i <= Len( oForm:aMethods )
    IF oForm:aMethods[i,2] != Nil .AND. !Empty(oForm:aMethods[i,2])
      IF ( cName := Lower( oForm:aMethods[i,1] ) ) == "common"
      ELSEIF cName != "onforminit" .AND. cName != "onformexit"
        Fwrite( han, "STATIC FUNCTION " + oForm:aMethods[i,1] + _Chr(10) )
        Fwrite( han, oForm:aMethods[i,2] )
        j1 := Rat( _Chr(10),oForm:aMethods[i,2] )
        IF j1 == 0 .OR. Lower( Left( Ltrim( Substr( oForm:aMethods[i,2],j1+1 ) ),6 ) ) != "return"
          Fwrite( han, _Chr(10)+"RETURN Nil" )
        ENDIF
        Fwrite( han, _Chr(10) + _Chr(10) )
      ENDIF
    ENDIF
    i ++
  ENDDO

  // Control's methods
  j := 1
  DO WHILE j <= aLen
    oCtrl := aControls[j]
    i := 1
    DO WHILE i <= Len( oCtrl:aMethods )
      IF oCtrl:aMethods[i,2] != Nil .AND. !Empty(oCtrl:aMethods[i,2])
        IF Valtype( cName := Callfunc( "FUNC_NAME",{ oCtrl,i } ) ) == "C"
          Fwrite( han, "STATIC FUNCTION " + cName + _Chr(10) )
          Fwrite( han, oCtrl:aMethods[i,2] )
          j1 := Rat( _Chr(10),oCtrl:aMethods[i,2] )
          IF j1 == 0 .OR. Lower( Left( Ltrim( Substr( oCtrl:aMethods[i,2],j1+1 ) ),6 ) ) != "return"
            Fwrite( han, _Chr(10)+"RETURN Nil" )
          ENDIF
          Fwrite( han, _Chr(10) + _Chr(10) )
        ENDIF
      ENDIF
      i ++
    ENDDO
    j ++
  ENDDO
  Fclose( han )
#ENDSCRIPT
