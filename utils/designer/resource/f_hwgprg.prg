#SCRIPT WRITE
#DEBUG


FUNCTION Font2Str

   PARAMETERS oFont

   Return " ;" + _Chr(10) + Space(8) + ;
          "FONT HFont():Add( '" + oFont:name + "'," + Ltrim(Str(oFont:width,5)) + "," + ;
          Ltrim(Str(oFont:height,5)) + "," + Iif(oFont:weight!=0,Ltrim(Str(oFont:weight,5)),"") + "," + ;
          Iif(oFont:charset!=0,Ltrim(Str(oFont:charset,5)),"") + "," + ;
          Iif(oFont:italic!=0,Ltrim(Str(oFont:italic,5)),"") + "," + ;
          Iif(oFont:underline!=0,Ltrim(Str(oFont:underline,5)),"") + ")"

ENDFUNC



FUNCTION Style2Prg
   PARAMETERS oCtrl

   Private cStyle := ""

   IF oCtrl:cClass == "label"

   ELSEIF oCtrl:cClass == "editbox"

   ENDIF

   Return cStyle
ENDFUNC



FUNCTION Func_name

   PARAMETERS oCtrl, nMeth

   Private cName, arr := ParseMethod( oCtrl:aMethods[ nMeth, 2 ] )

   IF Len( arr ) == 1 .OR. ( Len( arr ) == 2 .AND.;
      Lower( Left( arr[ 1 ], 11 ) ) == "parameters " )

      Return arr

   ELSE
      IF ( cName := oCtrl:GetProp( "Name" ) ) == Nil .OR. Empty( cName )
        cName := oCtrl:cClass + "_" + Ltrim( Str( oCtrl:id-34000 ) )
      ENDIF

      cName += "_" + oCtrl:aMethods[ nMeth, 1 ]

   ENDIF

   Return cName

ENDFUNC



FUNCTION Ctrl2Prg

   PARAMETERS oCtrl

   PRIVATE stroka := "   @ ", classname, cStyle, i, j, cName, temp, varname, cMethod
   PRIVATE nLeft, nTop

   i := Ascan( aClass, oCtrl:cClass )

   IF i  != 0
      varname := oCtrl:GetProp( "varName" )

      nLeft := oCtrl:nLeft
      nTop := oCtrl:nTop
      temp := oCtrl:oContainer

      DO WHILE temp != Nil
         IF temp:lContainer
            nLeft -= temp:nLeft
            nTop -= temp:nTop
         ENDIF
         temp := temp:oContainer
      ENDDO

      stroka += Ltrim( Str(nLeft) ) + "," + Ltrim( Str(nTop) ) + " "

      IF oCtrl:cClass == "editbox"
         temp := oCtrl:GetProp( "cInitValue" )

      ELSEIF oCtrl:cClass != "ownerbutton"
         temp := oCtrl:GetProp( "Caption" )

      ENDIF

      IF ( cName := oCtrl:GetProp( "Name" ) ) == Nil
         cName := ""
      ENDIF

      IF varname == Nil
         stroka += aName[i,1] + " " + cName + ;
                   Iif( temp!=Nil,Iif( !Empty(cName),' CAPTION "'+temp,' "'+temp )+'"',"" ) + " "
      ELSE
         stroka += aName[i,2] + " " + Iif( !Empty(cName), cName+" VAR "," " ) + varname + " "
      ENDIF

      IF oCtrl:cClass == "page"
         stroka += "ITEMS {} "
      ENDIF

      IF oCtrl:oContainer != Nil
         IF ( temp := oCtrl:oContainer:GetProp( "Name" ) ) == Nil .OR. Empty( temp )
            IF oCtrl:oContainer:oContainer != Nil
               temp := oCtrl:oContainer:oContainer:GetProp( "Name" )
            ENDIF
         ENDIF

         stroka += "OF " + temp + " "

      ENDIF

      IF oCtrl:cClass == "line"
         IF ( temp := oCtrl:GetProp( "lVertical" ) ) != Nil .AND. temp == "True"
            stroka += "LENGTH " + Ltrim( Str(oCtrl:nHeight) ) + " VERTICAL "
         ELSE
            stroka += "LENGTH " + Ltrim( Str(oCtrl:nWidth) ) + " "
         ENDIF
      ELSE
         stroka += "SIZE " + Ltrim( Str(oCtrl:nWidth) ) + "," + Ltrim( Str(oCtrl:nHeight) ) + " "
      ENDIF

      stroka += CallFunc( "Style2Prg", { oCtrl } ) + " "

      IF oCtrl:cClass != "ownerbutton"
         IF oCtrl:GetProp( "Textcolor",@j ) != Nil .AND. !IsDefault( oCtrl,oCtrl:aProp[j] )
            stroka += Iif( Empty(cStyle),"",";" + _Chr(10) + Space(8) ) + ;
            "COLOR " + Ltrim( Str(oCtrl:tcolor) ) + " "
         ENDIF

         IF oCtrl:GetProp( "Backcolor",@j ) != Nil .AND. !IsDefault( oCtrl,oCtrl:aProp[j] )
            stroka += "BACKCOLOR " + Ltrim( Str(oCtrl:bcolor) )
         ENDIF
      ENDIF

      IF oCtrl:cClass == "ownerbutton"

         IF ( temp := oCtrl:GetProp( "Flat" ) ) != Nil .AND. temp == "True"
            stroka += " FLAT "
         ENDIF

         IF ( temp := oCtrl:GetProp( "Caption" ) ) != Nil
            stroka += " ;" + _Chr(10) + Space(8) + "TEXT '" + temp + "' "

            IF oCtrl:GetProp( "Textcolor",@j ) != Nil .AND. !IsDefault( oCtrl,oCtrl:aProp[j] )
               stroka += "COLOR " + Ltrim( Str(oCtrl:tcolor) ) + " "
            ENDIF
         ENDIF
      ENDIF


      IF oCtrl:cClass == "editbox"
         IF ( cName := oCtrl:GetProp( "cPicture" ) ) != Nil
            stroka += "PICTURE '" + Ltrim( oCtrl:GetProp( "cPicture" )) + "' "
         ENDIF
      ENDIF

      IF ( temp := oCtrl:GetProp( "Font" ) ) != Nil
         stroka += CallFunc( "FONT2STR",{temp} )
      ENDIF

      Fwrite( han, _Chr(10) )
      Fwrite( han, stroka )

      // Methods ( events ) for the control
      i := 1
      DO WHILE i <= Len( oCtrl:aMethods )

         IF oCtrl:aMethods[ i, 2 ] != Nil .AND. ! Empty( oCtrl:aMethods[ i, 2 ] )
            IF Lower( Left( oCtrl:aMethods[ i, 2 ],10 ) ) == "parameters"

               // Note, do we look for a CR or a LF??
               j := At( _Chr(13), oCtrl:aMethods[ i, 2 ] )

               temp := Substr( oCtrl:aMethods[ i, 2 ], 12, j - 12 )
            ELSE
               temp := ""
            ENDIF

            IF varname != Nil .AND. ( Lower(oCtrl:aMethods[i,1]) == "ongetfocus" ;
                              .OR. Lower(oCtrl:aMethods[i,1]) == "onlostfocus")

               cMethod := Iif( Lower(oCtrl:aMethods[ i, 1 ] ) == "ongetfocus", "WHEN ", "VALID " )

            ELSE
               cMethod := "ON " + Upper(Substr(oCtrl:aMethods[i,1],3))

            ENDIF

            IF Valtype( cName := Callfunc( "FUNC_NAME", { oCtrl, i } ) ) == "C"
               Fwrite( han, " ;" + _Chr(10) + Space(8) + cMethod + " {|" + temp + "| " + ;
                            cName + "( " + temp + " ) }" )
            ELSE
               Fwrite( han, " ;" + _Chr(10) + Space(8) + cMethod + " {|" + temp + "| " +;
                            Iif( Len( cName ) == 1, cName[ 1 ], cName[ 2 ] ) + " }" )
            ENDIF
         ENDIF
         i ++
      ENDDO

   ENDIF


   IF !Empty( oCtrl:aControls )
      IF oCtrl:cClass == "page" .AND. ;
         ( temp := oCtrl:GetProp("Tabs") ) != Nil .AND. !Empty( temp )

         j := 1
         DO WHILE j <= Len( temp )
            Fwrite( han, _Chr(10) + "  BEGIN PAGE '" + temp[j] + "' OF " + oCtrl:GetProp( "Name" ) )

            i := 1
            DO WHILE i <= Len( oCtrl:aControls )
               IF oCtrl:aControls[i]:nPage == j
                  CallFunc( "Ctrl2Prg", { oCtrl:aControls[i] } )
               ENDIF
               i ++
            ENDDO

            Fwrite( han, _Chr(10) + "  END PAGE OF " + oCtrl:GetProp( "Name" ) + _Chr(10) )
            j ++
         ENDDO
         RETURN

      ELSEIF oCtrl:cClass == "radiogroup"
         Fwrite( han, _Chr(10) + "  RADIOGROUP" )
      ENDIF

      i := 1
      DO WHILE i <= Len( oCtrl:aControls )
         CallFunc( "Ctrl2Prg", { oCtrl:aControls[i] } )
         i ++
      ENDDO

      IF oCtrl:cClass == "radiogroup"
         temp := oCtrl:GetProp("nInitValue")
         Fwrite( han, _Chr(10) + "  END RADIOGROUP SELECTED " + Iif( temp==Nil,"1",temp ) + _Chr(10) )
      ENDIF
   ENDIF

   RETURN

ENDFUNC



// Entry point into interpreted code ------------------------------------


Private han, fname := oForm:path + oForm:filename, stroka, oCtrl

Private aControls := oForm:oDlg:aControls, alen := Len( aControls ), i, j, j1

Private cName := oForm:GetProp( "Name" ), temp

Private aClass := { "label", "button", "checkbox", "radiobutton", "editbox", ;
                    "group", "datepicker", "updown", "combobox", "line", "toolbar", ;
                    "ownerbutton", "browse","page" }

Private aName :=  { {"SAY"}, {"BUTTON"}, {"CHECKBOX","GET CHECKBOX"}, {"RADIOBUTTON"},;
                    {"EDITBOX","GET"}, {"GROUPBOX"}, {"DATEPICKER","GET DATEPICKER"},;
                    {"UPDOWN","GET UPDOWN"}, {"COMBOBOX","GET COMBOBOX"}, {"LINE"},;
                    {"PANEL"}, {"OWNERBUTTON"}, {"BROWSE"},{"TAB"} }

  han := Fcreate( fname )

  //Add the lines to include
  //Fwrite( han,'#include "windows.ch"'+ _Chr(10)  )
  //Fwrite( han,'#include "guilib.ch"' + _Chr(10)+ _Chr(10) )
  Fwrite( han,'#include "hwgui.ch"' + _Chr(10)+ _Chr(10) )

  Fwrite( han, "FUNCTION " + "_" + Iif( cName != Nil, cName, "Main" ) + _Chr(10)  )

  // Declare 'Private' variables
  IF cName != Nil
    Fwrite( han, "PRIVATE " + cName + _Chr(10) )
  ENDIF

  i := 1
  stroka := ""
  DO WHILE i <= aLen
    IF ( temp := aControls[i]:GetProp( "Name" ) ) != Nil .AND. ! Empty( temp )
       stroka += Iif( Empty(stroka), "PRIVATE ", ", " ) + temp
    ENDIF
    i ++
  ENDDO

  IF ! Empty( stroka )
     Fwrite( han, stroka )
  ENDIF

  stroka := ""
  i := 1
  DO WHILE i <= aLen
    IF ( temp := aControls[i]:GetProp( "VarName" ) ) != Nil .AND. ! Empty( temp )
       stroka += Iif( ! Empty(stroka),", ","" ) + temp
    ENDIF
    i ++
  ENDDO

  IF ! Empty( stroka )
    stroka := "PRIVATE " + stroka
    Stroka += _Chr(10) + "PUBLIC oDlg"

    Fwrite( han, _Chr(10) + stroka )
  ENDIF

  i := 1
  DO WHILE i <= Len( oForm:aMethods )
      IF oForm:aMethods[ i, 2 ] != Nil .AND. ! Empty( oForm:aMethods[ i, 2 ] )

         IF Lower( oForm:aMethods[i,1] ) == "onforminit"
            Fwrite( han, _Chr(10)+_Chr(10) )
            Fwrite( han, oForm:aMethods[i,2] )
         ENDIF

      ENDIF

      i ++
   ENDDO

   IF "DLG" $ Upper(  oForm:GetProp("FormType") )
      // 'INIT DIALOG' command
      Fwrite( han, _Chr(10) + _Chr(10) + '   INIT DIALOG oDlg TITLE "' + oForm:oDlg:title + '" ;' + _Chr(10) )

   ELSE
      // 'INIT WINDOW' command
      Fwrite( han, _Chr(10) + _Chr(10) + '   INIT WINDOW oWin TITLE "' + oForm:oDlg:title + '" ;' + _Chr(10) )

   ENDIF

   Fwrite( han, Space(8) + "AT " + Ltrim( Str( oForm:oDlg:nLeft ) ) + "," ;
                                 + Ltrim( Str( oForm:oDlg:nTop ) ) + ;
                           " SIZE " + Ltrim( Str( oForm:oDlg:nWidth ) ) + "," +;
                                      Ltrim( Str( oForm:oDlg:nHeight ) ) )

   IF ( temp := oForm:GetProp( "Font" ) ) != Nil
      Fwrite( han, CallFunc( "FONT2STR",{temp} ) )
   ENDIF

   i := 1
   DO WHILE i <= Len( oForm:aMethods )

      IF ! ("ONFORM" $ Upper( oForm:aMethods[ i, 1 ] ) ) .AND. ;
         ! ("COMMON" $ Upper( oForm:aMethods[ i, 1 ] ) ) .AND. oForm:aMethods[ i, 2 ] != Nil .AND. ! Empty( oForm:aMethods[ i, 2 ] )

         // all methods are onSomething so, strip leading "on"
         fWrite( han, " ;" + + _Chr(10) + Space(8) + "ON " + ;
                      StrTran( StrTran( Upper( SubStr( oForm:aMethods[ i, 1 ], 3 ) ), "DLG", "" ), "FORM", "" ) + ;
                      " {|| " + oForm:aMethods[ i, 1 ] + " }" )

         // Dialog and Windows methods can have little different name, should be fixed

      ENDIF

      i ++
  ENDDO
  Fwrite( han, _Chr(10) + _Chr(10) )

   // Controls initialization
   i := 1
   DO WHILE i <= aLen

      IF aControls[i]:oContainer == Nil
         CallFunc( "Ctrl2Prg", { aControls[ i ] } )
      ENDIF

      i ++
   ENDDO

   IF "DLG" $ Upper(  oForm:GetProp("FormType") )
      Fwrite( han, _Chr(10) + "   ACTIVATE DIALOG oDlg" + _Chr(10) )
   ELSE
      Fwrite( han, _Chr(10) + "   ACTIVATE WINDOW oWin" + _Chr(10) )
   ENDIF

   i := 1
   DO WHILE i <= Len( oForm:aMethods )

      IF oForm:aMethods[ i, 2 ] != Nil .AND. ! Empty( oForm:aMethods[ i, 2 ] )

         IF Lower( oForm:aMethods[ i, 1 ] ) == "onformexit"
            Fwrite( han, oForm:aMethods[ i, 2 ] )
            Fwrite( han, _Chr(10) + _Chr(10) )
         ENDIF

      ENDIF
      i ++
  ENDDO

  Fwrite( han, "RETURN" + _Chr(10) + _Chr(10) )

  // "common" Form/Dialog methods
  i := 1
  DO WHILE i <= Len( oForm:aMethods )

    IF oForm:aMethods[i,2] != Nil .AND. !Empty(oForm:aMethods[i,2])

      IF ( cName := Lower( oForm:aMethods[i,1] ) ) == "common"
        j1 := 1
        temp := .F.

        DO WHILE .T.

          stroka := RdStr( ,oForm:aMethods[i,2],@j1 )

          IF Len(stroka) == 0
            EXIT
          ENDIF

          IF Lower(Left(stroka,8)) == "function"
            Fwrite( han, "STATIC " + stroka + _Chr(10) )
            temp := .F.

          ELSEIF Lower(Left(stroka,6)) == "return"
            Fwrite( han, stroka + _Chr(10) )
            temp := .T.

          ELSEIF Lower(Left(stroka,7)) == "endfunc"
            IF !temp
              Fwrite( han, "Return Nil" +  _Chr(10) )
            ENDIF
            temp := .F.

          ELSE
            Fwrite( han, stroka + _Chr(10) )
            temp := .F.
          ENDIF

        ENDDO

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

    //MsgInfo( oCtrl:GetProp("Name") )

    i := 1
    DO WHILE i <= Len( oCtrl:aMethods )

      //MsgInfo( oCtrl:aMethods[ i, 1 ] + " / " + oCtrl:aMethods[ i, 2 ] )

      IF oCtrl:aMethods[ i, 2 ] != Nil .AND. ! Empty( oCtrl:aMethods[ i, 2 ] )

        IF Valtype( cName := Callfunc( "FUNC_NAME", { oCtrl, i } ) ) == "C"

          Fwrite( han, "STATIC FUNCTION " + cName + _Chr(10) )
          Fwrite( han, oCtrl:aMethods[ i, 2 ] )

          j1 := Rat( _Chr(10),oCtrl:aMethods[i,2] )

          IF j1 == 0 .OR.;
             Lower( Left( Ltrim( Substr( oCtrl:aMethods[ i, 2 ], j1 + 1 ) ), 6 ) ) != "return"

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
