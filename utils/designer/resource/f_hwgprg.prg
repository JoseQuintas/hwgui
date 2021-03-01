#script WRITE
#debug

FUNCTION Font2Str

   PARAMETERS oFont

   RETURN " ;" + hb_OsNewline() + Space( 8 ) + ;
      "FONT HFont():Add( '" + oFont:name + "'," + LTrim( Str( oFont:width,5 ) ) + "," + ;
      LTrim( Str( oFont:height,5 ) ) + "," + iif( oFont:weight != 0, LTrim( Str(oFont:weight,5 ) ), "" ) + "," + ;
      iif( oFont:charset != 0, LTrim( Str(oFont:charset,5 ) ), "" ) + "," + ;
      iif( oFont:italic != 0, LTrim( Str(oFont:italic,5 ) ), "" ) + "," + ;
      iif( oFont:underline != 0, LTrim( Str(oFont:underline,5 ) ), "" ) + ")"

   ENDFUNC

FUNCTION Menu2Prg

   PARAMETERS oCtrl, alMenu

   PRIVATE stroka := "",  i, j, cName, temp, cMethod
   PRIVATE oNode //,almenu

   //            [ ACCELERATOR <flag>, <key> ] ;
   //            [<lDisabled: DISABLED>]       ;

   i := 1
   IF ValType( aLMenu[i,1] ) == "A"
      stroka := Space( 2 ) + "  MENU TITLE '" + aLMenu[i,2] + "' ID " + Str( aLMenu[i,3] ) + " "
      FWrite( han, hb_OsNewline() + stroka )
   ENDIF

   DO WHILE i <=  Len( aLMenu )

      IF ValType( aLMenu[i,1] ) == "A"
         //BuildTree( oNode, aMenu[i,1] )
         stroka := Space( 2 * nMaxid ) + "  MENU TITLE '" + aLMenu[i,2] + "' ID " + Str( aLMenu[i,3] ) + " "
         FWrite( han, hb_OsNewline() + stroka )
         nMaxId += 1
         CallFunc( "Menu2Prg", { oCtrl , alMenu[i,1] } )
         nMaxId -= 1
         stroka := Space( 2 * nmaxid ) + "  ENDMENU  "
         FWrite( han, hb_OsNewline() + stroka )
      ELSE
         IF alMenu[i,2] != "-"
            stroka := Space( 2 * nMaxId + 2 ) + "MENUITEM '" + alMenu[i,2] + "' ID " + LTrim( Str( alMenu[i,3] ) ) + "  "
            IF !Empty( alMenu[i,4] )
               // Methods ( events ) for the control
               cMethod := "ACTION ( "
               temp := StrTran( alMenu[i,4], Chr( 10 ), ", " )
               temp := StrTran( temp, Chr( 13 ), "" )
               stroka := stroka + cMethod + temp + " ) "
            ELSE
               stroka := stroka + 'ACTION ""'
            ENDIF
         ELSE
            stroka := Space( 4 + nMaxId ) + "SEPARATOR"
         ENDIF
         FWrite( han, hb_OsNewline() + stroka + " " )
      ENDIF
      i ++
   ENDDO

   RETURN

   ENDFUNC

FUNCTION Tool2Prg

   PARAMETERS oCtrl
   LOCAL nLocalParamPos := 0
   LOCAL lsubParameter := .F.
   PRIVATE cLocalParam := ""
   PRIVATE cFormParameters := ""


   PRIVATE cName := "", cTool := "", cId := "", temp , i, j, k, cTip
   PRIVATE   oCtrl1, aMethods

   //Private crelexpr, clink, cfilter, cKey

   cName := Trim( oCtrl:GetProp( "Name" ) )
   //cTool += "    *- " + cname + hb_OsNewline()+ "    *- SCRIPT GERADO AUTOMATICAMENTE PELO DESIGNER" + hb_OsNewline()+"    *-  " + hb_OsNewline()
   IF cName = Nil .OR. Empty( cName )
      RETURN cTool
   ENDIF

   cId := Val( iif( (temp := oCtrl:GetProp("Id" ) ) != Nil .AND. !Empty(temp ),temp ,"700" ) )
   FWrite( han, " ID " + LTrim( Str(cid ) ) )
   //<O>:AddButton(<nBitIp>,<nId>,<bstate>,<bstyle>,<ctext>,<bclick>,<c>,<d>)
   IF Len( oCtrl:aControls ) > 0
      FWrite( han, hb_OsNewline() + cTool )
      i := 1
      DO WHILE i <= Len( oCtrl:aControls )
         cName := Trim( oCtrl:GetProp( "Name" ) )
         oCtrl1 := oCtrl:aControls[i]
         cTool += Space( 4 ) + cname + ":AddButton("
         cTool += iif( ( temp := oCtrl1:GetProp("Bitmap" ) ) != Nil .AND. !Empty( temp ), temp , "1" ) + ", "
         cTool += LTrim( Str( cId + i ) ) + ", "
         cTool += iif( ( temp := oCtrl1:GetProp("State" ) ) != Nil .AND. !Empty( temp ), temp , "4" ) + ", "
         cTool += iif( ( temp := oCtrl1:GetProp("Style" ) ) != Nil .AND. !Empty( temp ), temp , "0" ) + ", "
         cTool += iif( ( temp := oCtrl1:GetProp("Caption" ) ) != Nil .AND. !Empty( temp ), '"' + temp + '"', '" "' ) + " "
         cTip  := iif( ( temp := oCtrl1:GetProp("ToolTip" ) ) != Nil .AND. !Empty( temp ), "'" + temp + "'", "" )
         // Methods ( events ) for the control
         k := 1
         aMethods := {}
         DO WHILE k <= Len( oCtrl1:aMethods )
            IF oCtrl1:aMethods[ k, 2 ] != Nil .AND. ! Empty( oCtrl1:aMethods[ k, 2 ] )

               IF Lower( Left( oCtrl1:aMethods[ k, 2 ],10 ) ) == "parameters"
                  // Note, do we look for a CR or a LF??
                  j := At( _Chr( 13 ), oCtrl1:aMethods[ k, 2 ] )
                  temp := SubStr( oCtrl1:aMethods[ k, 2 ], 12, j - 12 )

               ELSEIF Lower( Left( oCtrl1:aMethods[ k, 2 ],1 ) ) == "("
                  // Note, do we look for a CR or a LF??
                  j := At( ")", oCtrl1:aMethods[ k, 2 ] )
                  cLocalParam := SubStr( oCtrl1:aMethods[ k, 2 ], 1, j  )
                  temp := ""
                  lsubParameter := .T.

               ELSE
                  temp := ""
               ENDIF
               IF !Empty( oCtrl1:GetProp( "LocalOnClickParam" ) )
                  cFormParameters := oCtrl1:GetProp( "LocalOnClickParam" )
               ENDIF

               //cMethod := " " + Upper(Substr(oCtrl:aMethods[i,1],1))
               IF ValType( cName := Callfunc( "FUNC_NAME", { oCtrl1, k } ) ) == "C"
                  IF !Empty( cLocalParam )
                     // Substr( oCtrl1:aMethods[ k, 2 ], 1, j  )
                     IF lsubParameter
                        temp :=  " {|" + temp + "| " +  cName + "(" + cFormParameters + ")  }"
                     ELSE
                        temp :=  " {|" + temp + "| " +  cName + cLocalParam + "  }"
                     ENDIF
                     IF lsubParameter
                        lsubParameter := .F.
                     ENDIF
                  ELSE
                     temp :=  " {|" + temp + "| " +  cName + "( " + temp + " ) }"
                  ENDIF
               ELSE
                  temp := " {|" + temp + "| " + iif( Len( cName ) == 1, cName[ 1 ], cName[ 2 ] ) + " }"
               ENDIF
               AAdd( aMethods, { Lower( oCtrl1:aMethods[k,1] ), temp } )
            ENDIF
            k ++
         ENDDO
         //IF  k > 1
         //        if !empty(cFormParameters)
         //                          cTool += ",{||"+ cFormParameters +"}")
         //        else
         cTool += "," + CallFunc( "Bloco2Prg", { aMethods, "onClick" } )
         //        endif
         //ELSE
         //  cTool += ",{|| .T. }"
         //ENDIF
         cTool += "," + cTip + ",''"
         FWrite( han, cTool + ")" + hb_OsNewline() )
         cTool := ""
         i ++
      ENDDO
      //cTool := "    *- FIM DE " + cname + hb_OsNewline()
      cTool := ""  //hb_OsNewline()
   ENDIF

   RETURN cTool

   ENDFUNC

FUNCTION Browse2Prg

   PARAMETERS oCtrl
#define BRW_ARRAY 1
#define BRW_DATABASE 2

   PRIVATE cName := "", cBrowser := "", cAdd := "", temp , i, j, k, nColumns, caArray, cAlias, cTmpAlias, oCtrl1
   PRIVATE crelexpr, clink, cfilter, cKey, nType
   PRIVATE aTypes, cType, nLength, aWidths , nDec , lOpen := .F. , nColunas, cHeader, cCampo, aMethods

   PRIVATE aBrwXml :=  { "Alias", "ColumnsCount" , "HeadRows", "FooterRows", "ShowHeader", ;
      "ShowGridLinesSep", "GridLinesSep3D", "HeadTextColor", "GridLinesSepColor", ;
      "LeftCol", "ColumnsFreeze", "AdjRight" }

   PRIVATE aBrwProp :=  { "alias", "nColumns", "nHeadRows", "nFootRows", "lDispHead", "lDispSep", ;
      "lSep3d", "headColor", "sepColor", "nLeftCol", "freeze", "lAdjRight" }

   cName := Trim( oCtrl:GetProp( "Name" ) )

//   cBrowser += "    // " + cname + "    *- SCRIPT GERADO AUTOMATICAMENTE PELO DESIGNER" + hb_OsNewline() + "    //  " + hb_OsNewline()
   nType := iif( oCtrl:GetProp( "BrwType" ) != "dbf" , BRW_ARRAY, BRW_DATABASE )
   IF cName = Nil .OR. Empty( cName ) .OR. ( ( cAlias := oCtrl:GetProp("FileDbf" ) )  = Nil .AND. nType = BRW_DATABASE )
      RETURN cBrowser
   ENDIF

   nColumns := iif( ( temp := oCtrl:GetProp("ColumnsCount" ) ) != Nil .AND. !Empty( temp ), Val( temp ) , 0 )
   nColunas := nColumns
   cBrowser += Space( 4 ) + cname + ":aColumns := {}" + hb_OsNewline()

   j := 3
   DO WHILE j < Len( aBrwProp )
      temp := oCtrl:GetProp( aBrwXml[j] )
      IF temp  != Nil .AND. !Empty( temp )
         cBrowser += Space( 4 ) + cname + ":" + aBrwProp[j] + ":= " + ;
            iif( temp = "True", '.T.', iif( temp = "False",'.F.',temp ) ) + hb_OsNewline()
      ENDIF
      j ++
   ENDDO

   IF nType = BRW_DATABASE
      cAlias := Left( CutPath( cAlias ), At( ".",CutPath( cAlias ) ) - 1 )
      cAlias := Lower( Trim( iif( (temp := oCtrl:GetProp("alias" ) ) != Nil .AND. !Empty(temp ),temp , calias ) ) )
      cBrowser += Space( 4 ) + cname + ":alias := '" + calias + "'" + hb_OsNewline()
      // abrir tablea
      //     IF (temp:=oCtrl:GetProp("filedbf")) != Nil //.AND. !EMPTY(temp)
      //      cTmpAlias := Lower(LEFT(CutPath( temp ),AT(".",CutPath( temp ))-1))
      //      IF select(cTmpalias) = 0
      //        USE (value) NEW SHARED ALIAS (cTmpAlias) VIA "DBFCDX" //ftmp
      //SET INDEX TO (cTmpAlias)
      //hwg_Msginfo(ALIAS())
      //        lopen := .T.
      //      ENDIF
      //USE (temp) NEW ALIAS ftmp SHARED
      //      SELECT (cTmpAlias)
      //     ELSE
      //       RETURN  ""
      //     ENDIF
      //calias := alias()
      nColumns := iif( nColumns = 0, iif( Len( oCtrl:aControls ) = 0,&cTmpalias -> (FCount() ),Len( oCtrl:aControls ) ), nColumns )
      cBrowser += Space( 4 ) + cname + ":nColumns := " + LTrim( Str( nColumns ) ) + hb_OsNewline()
      cBrowser += Space( 4 ) + "IF select(" + cname + ":alias) = 0 ; USE ('" + temp + "') NEW ALIAS (" + cname + ":alias) SHARED ;ENDIF" + hb_OsNewline()
      cBrowser += Space( 4 ) + "SELECT (" + cname + ":alias) " + hb_OsNewline()
      //
      aTypes := &cTmpalias -> ( dbStruct() )

      // CRIAR AS RELA€OES E O LINK
      temp := iif( ( temp := oCtrl:GetProp("childorder" ) ) != Nil .AND. !Empty( temp ), Trim( temp ), "" )
      cKey := ""
      IF !Empty( temp )
         cBrowser += Space( 4 ) + calias + "->(DBSETORDER('" + temp + "'))" + hb_OsNewline()
         &calias -> ( dbSetOrder( temp ) )
         cKey := &calias -> ( OrdKey( temp ) )
         ckey := iif( At( '+',ckey ) > 0, Left( ckey, At('+',ckey ) - 1 ), ckey )
      ENDIF
      crelexpr := iif( ( temp := oCtrl:GetProp("relationalexpr" ) ) != Nil .AND. !Empty( temp ), Trim( temp ), cKey )
      clink := iif( ( temp := oCtrl:GetProp("linkmaster" ) ) != Nil .AND. !Empty( temp ), Trim( temp ), "" )
      IF !Empty( crelexpr ) .AND. !Empty( clink )
         cBrowser += "    *-  LINK --> RELACIONAMENTO E FILTER " + hb_OsNewline()
         cBrowser += Space( 4 ) + clink + "->(DBSETRELATION('" + calias + "', {|| " + crelexpr + "},'" + crelexpr + "')) " + hb_OsNewline()
         cfilter := crelexpr + "=" + clink + "->(" + crelexpr + ")"
         cBrowser += Space( 4 ) + calias + "->(DBSETFILTER( {|| " + cfilter + "}, '" + cfilter + "' ))" + hb_OsNewline() + "    *-" + hb_OsNewline()
      ENDIF
      // fim dos relacionamentos
   ELSE
      caArray := Trim( iif( (temp := oCtrl:GetProp("aarray" ) ) != Nil .AND. !Empty(temp ),temp , "{}" ) )
      cBrowser += Space( 4 ) + cname + ":aArray := " + caArray + "" + hb_OsNewline()
      nColumns := iif( nColumns = 0, 1, nColumns )
   ENDIF

   IF Len( oCtrl:aControls ) = 0 //nColunas = 0 // gerar automaticamente o BROWSE completo
      i := 1
      DO WHILE i <= nColumns
         IF nType = BRW_DATABASE
            cBrowser += Space( 4 ) + cname + ":AddColumn( HColumn():New(FieldName(" + LTrim( Str( i ) ) + ") ,FieldBlock(FieldName(" + LTrim( Str( i ) ) + "))," + ;
               "'" + aTypes[i,2] + "'," + LTrim( Str( aTypes[i,3] + 1 ) ) + "," + LTrim( Str( aTypes[i,4] ) ) + "))" + hb_OsNewline() //,,,,,,,,,{|| .t.}))
         ELSE
            cBrowser += Space( 4 ) + cname + ":AddColumn( HColumn():New( ,{|v,o|Iif(v!=Nil,o:aArray[o:nCurrent]:=v,o:aArray[o:nCurrent])},'C',100,0))" + hb_OsNewline()
         ENDIF
         i ++
      ENDDO
      cBrowser :=  hb_OsNewline() + cBrowser + "    *- FIM DE " + cname
   ELSE
      FWrite( han, hb_OsNewline() + hb_OsNewline() + cbrowser )
      i := 1
      DO WHILE i <= Len( oCtrl:aControls )
         cName := Trim( oCtrl:GetProp( "Name" ) )
         oCtrl1 := oCtrl:aControls[i]
         cHeader := iif( ( temp := oCtrl1:GetProp("Heading" ) ) != Nil, "'" + temp + "'" , "" )
         cCampo  := Lower( iif( (temp := oCtrl1:GetProp("FieldName" ) ) != Nil .AND. !Empty(temp ),"" + temp + "" ,FieldName(i ) ) )
         cCampo  := Lower( iif( (temp := oCtrl1:GetProp("FieldExpr" ) ) != Nil .AND. !Empty(temp ),"" + temp + "" ,ccampo ) )
         m -> nLength := iif( ( temp := oCtrl1:GetProp("Length" ) ) != Nil, Val( temp ), temp )
         IF nType = BRW_DATABASE
            cType  := Type( "&cCampo" )
            IF !( cAlias == cTmpAlias ) .AND. cTmpAlias $ cCampo
               cCampo := StrTran( cCampo, cTmpAlias, cAlias )
            ENDIF
            temp := StrTran( Upper( cCampo ), Upper( cAlias ) + "->", "" )
            // verificar se tem mais de um campo
            temp := SubStr( temp, 1, iif( At('+',temp ) > 0,At('+',temp ) - 1,Len(temp ) ) )
            j := {}
            AEval( aTypes, { |aField| AAdd( j,aField[1] ) } )
            cHeader  := iif( cHeader == Nil .OR. Empty( cHeader ) , '"' + temp + '"', '' + cHeader + '' )
            IF m -> nLength = Nil
               m -> nLength := &cTmpAlias -> ( fieldlen( AScan(j,temp ) ) )
               m -> nLength := iif( m -> nLength = 0 , iif( Type("&cCampo" ) = "C",Len(&cCampo ),10 ), m -> nLength )
            ENDIF
            m -> nDec := &cTmpAlias -> ( FIELDDEC( AScan(j,temp ) ) )
            cCampo := "{|| " + cCampo + " }"
            //cBrowser := SPACE(4)+cname+":AddColumn( HColumn():New("+cHeader+",{|| "+cCampo+" },"+ "'"+aTypes[i]+"',"+;
            //      iif((temp:=oCtrl1:GetProp("Length"))!= Nil,LTRIM(STR(VAL(temp))),"10")+", "+;
            //      Ltrim(Str(aDecimals[i]))+" "
         ELSE
            cCampo := iif( cCampo = Nil, ".T.", cCampo )
            cCampo := iif( Type( "&cCampo" ) = "B", cCampo, "{|| " + cCampo + " }" )
            cType  := Type( "&cCampo" )
            m -> nLength := iif( m -> nLength = Nil , 10, m -> nLength )
            m -> nDec := 0
         ENDIF
         IF ( temp := oCtrl1:GetProp( "Picture" ) ) != Nil .AND. At( ".9", temp ) > 0
            m -> nDec := Len( SubStr( temp,At(".9",temp ) + 1 ) )
            //cType := "N"
         ENDIF
         //cBrowser := SPACE(4)+cname+":AddColumn( HColumn():New("+cHeader+",{|| "+cCampo+" },"+ "'"+TYPE("&cCampo")+"',"+
         cBrowser := Space( 4 ) + cname + ":AddColumn( HColumn():New(" + cHeader + ", " + cCampo + " ," + "'" + cTYPE + "'," + ;
            LTrim( Str( m -> nLength ) ) + ", " + LTrim( Str( m -> nDec ) ) + " "
         cbrowser += "," + iif( ( temp := oCtrl1:GetProp("Editable" ) ) != Nil, iif( temp = "True",".T.",".F." ), ".T." )
         cbrowser += "," + iif( ( temp := oCtrl1:GetProp("JustifyHeader" ) ) != Nil, LTrim( Str(Val(temp ) ) ), "" )
         cbrowser += "," + iif( ( temp := oCtrl1:GetProp("JustifyLine" ) ) != Nil, LTrim( Str(Val(temp ) ) ), "" )
         cbrowser += "," + iif( ( temp := oCtrl1:GetProp("Picture" ) ) != Nil .AND. !Empty( temp ), "'" + Trim( temp ) + "'", "" )
         //Fwrite( han, +hb_OsNewline() + cbrowser)

         // Methods ( events ) for the control
         k := 1
         aMethods := {}
         DO WHILE k <= Len( oCtrl1:aMethods )
            IF oCtrl1:aMethods[ k, 2 ] != Nil .AND. ! Empty( oCtrl1:aMethods[ k, 2 ] )
               IF Lower( Left( oCtrl1:aMethods[ k, 2 ],10 ) ) == "parameters"
                  // Note, do we look for a CR or a LF??
                  j := At( _Chr( 13 ), oCtrl1:aMethods[ k, 2 ] )
                  temp := SubStr( oCtrl1:aMethods[ k, 2 ], 12, j - 12 )
               ELSE
                  temp := ""
               ENDIF
               //cMethod := " " + Upper(Substr(oCtrl:aMethods[i,1],1))
               IF ValType( cName := Callfunc( "FUNC_NAME", { oCtrl1, k } ) ) == "C"
                  temp :=  " {|" + temp + "| " +  cName + "( " + temp + " ) }"
               ELSE
                  temp := " {|" + temp + "| " + iif( Len( cName ) == 1, cName[ 1 ], cName[ 2 ] ) + " }"
               ENDIF
               AAdd( aMethods, { Lower( oCtrl1:aMethods[k,1] ), temp } )
            ENDIF
            k ++
         ENDDO
         cbrowser += "," + CallFunc( "Bloco2Prg", { aMethods, "onLostFocus" } )
         cbrowser += "," + CallFunc( "Bloco2Prg", { aMethods, "onGetFocus" } )
         cbrowser += "," + iif( ( temp := oCtrl1:GetProp("Items" ) ) != Nil, temp, "" )
         cbrowser += "," + CallFunc( "Bloco2Prg", { aMethods, "ColorBlock" } )
         cbrowser += "," + CallFunc( "Bloco2Prg", { aMethods, "HeadClick" } )
         //cbrowser += "))"
         FWrite( han, cbrowser + "))" + hb_OsNewline() )
         //( <cHeader>,<block>,<cType>,<nLen>,<nDec>,<.lEdit.>,<nJusHead>, <nJusLine>, <cPict>, <{bValid}>, <{bWhen}>, <aItem>, <{bClrBlck}>, <{bHeadClick}> ) )
         i ++
      ENDDO
      cBrowser := "    *- FIM DE " + cname + hb_OsNewline()
   ENDIF
   IF nType = BRW_DATABASE .AND.  lOpen
      USE
   ENDIF

   RETURN cBrowser

   ENDFUNC

FUNCTION Bloco2Prg

   PARAMETERS aMetodos, cmetodo

   // Methods ( events ) for the control
   PRIVATE z , temp

   z := AScan( aMetodos, { |aVal| aVal[1] == Lower( cmetodo ) } )
   temp := iif( z > 0, aMetodos[z,2] , "" )

   RETURN TEMP

   ENDFUNC

FUNCTION Imagem2Prg

   PARAMETERS oCtrl

   PRIVATE cImagem := ""
   PRIVATE temp := ""

   IF oCtrl:cClass == "form"
      temp := oCtrl:GetProp( "icon" )
      IF !Empty( temp )
         //cImagem += IIF(oCtrl:GetProp("lResource") := "True"," ICON HIcon():AddResource('"+temp+"') "," ICON "+temp +" ")
         cImagem += " ICON " + iif( At( ".",temp ) != 0 , "HIcon():AddFile('" + temp + "') ", "HIcon():AddResource('" + temp + "') " )
      ENDIF
      temp := oCtrl:GetProp( "bitmap" )
      IF !Empty( temp )
         //cImagem += " BACKGROUND BITMAP HBitmap():AddFile('"+temp+"') "
         cImagem += " BACKGROUND BITMAP " + iif( At( ".",temp ) != 0 , "HBitmap():AddFile('" + temp + "') ", "HBitmap():AddResource('" + temp + "') " )
      ENDIF

   ELSEIF oCtrl:cClass == "editbox" .OR. oCtrl:cClass == "richedit"

   ELSEIF oCtrl:cClass == "updown"

   ELSEIF oCtrl:cClass == "button" .OR. oCtrl:cClass == "ownerbutton"

   ENDIF

   IF Len( cImagem ) > 0
      cImagem := ";" + hb_OsNewline() + Space( 8 ) + cImagem
   ENDIF

   RETURN cImagem

   ENDFUNC

FUNCTION Color2Prg

   PARAMETERS oCtrl

   PRIVATE cColor := ""
   PRIVATE xProperty := ""

   IF oCtrl:GetProp( "Textcolor", @j ) != Nil .AND. !IsDefault( oCtrl, oCtrl:aProp[j] )
      cColor += iif( Empty( cStyle ), "", ";" + hb_OsNewline() + Space( 8 ) ) + ;
         " COLOR " + LTrim( Str( oCtrl:tcolor ) ) + " "
   ENDIF
   IF oCtrl:GetProp( "Backcolor", @j ) != Nil .AND. !IsDefault( oCtrl, oCtrl:aProp[j] )
      cColor += " BACKCOLOR " + LTrim( Str( oCtrl:bcolor ) )
   ENDIF
   IF oCtrl:cClass == "link"
      IF oCtrl:GetProp( "VisitColor", @j ) != Nil .AND. !IsDefault( oCtrl, oCtrl:aProp[j] )
         cColor += iif( Empty( cStyle ), "", ";" + hb_OsNewline() + Space( 8 ) ) + ;
            " VISITCOLOR " + LTrim( Str( oCtrl:tcolor ) ) + " "
      ENDIF
      IF oCtrl:GetProp( "LinkColor", @j ) != Nil .AND. !IsDefault( oCtrl, oCtrl:aProp[j] )
         cColor += " LINKCOLOR " + LTrim( Str( oCtrl:bcolor ) )
      ENDIF
      IF oCtrl:GetProp( "HoverColor", @j ) != Nil .AND. !IsDefault( oCtrl, oCtrl:aProp[j] )
         cColor += " HOVERCOLOR " + LTrim( Str( oCtrl:bcolor ) )
      ENDIF
   ENDIF
   IF Len( Trim( cColor ) ) > 0
      cColor := ";" + hb_OsNewline() + Space( 8 )  + cColor //substr(cStyle,2)
   ENDIF

   RETURN cColor

   ENDFUNC

FUNCTION Style2Prg

   PARAMETERS oCtrl

   PRIVATE cStyle := ""
   PRIVATE xProperty := ""

   cStyle := cStyle + iif( oCtrl:GetProp( "multiline" ) = "True" .OR. oCtrl:GetProp( "wordwrap" ) = "True" , "+ES_MULTILINE " , "" )
   IF oCtrl:cClass == "label"
      cStyle := cStyle + iif( oCtrl:GetProp( "Justify" ) = "Center" , "+SS_CENTER " , "" )
      cStyle := cStyle + iif( oCtrl:GetProp( "Justify" ) = "Right" , "+SS_RIGHT " , "" )
      cStyle += iif( oCtrl:oContainer != Nil .AND. oCtrl:oContainer:cclass != NIL .AND. oCtrl:oContainer:cclass = "page" , "+SS_OWNERDRAW ", "" )
   ELSE  //IF oCtrl:cClass == "editbox" .OR. oCtrl:cClass == "richedit"
      cStyle := cStyle + iif( oCtrl:GetProp( "Justify" ) = "Center" , "+ES_CENTER " , "" )
      cStyle := cStyle + iif( oCtrl:GetProp( "Justify" ) = "Right" , "+ES_RIGHT " , "" )
   ENDIF
   //ELSEIF oCtrl:cClass == "updown"
   IF oCtrl:cClass = "button" .OR. oCtrl:cClass == "ownerbutton" .OR. oCtrl:cClass == "shadebutton"
      cStyle := cStyle + "+WS_TABSTOP"
      cStyle := cStyle + iif( oCtrl:GetProp( "3DLook" ) = "False" , "+BS_FLAT " , "" )
   ELSE
      cStyle := cStyle + iif( oCtrl:GetProp( "Enabled" ) = "False" , "+WS_DISABLED " , "" )
   ENDIF

   IF oCtrl:cClass == "checkbox"
      cStyle := cStyle + iif( oCtrl:GetProp( "alignment" ) = "Top", "+BS_TOP ", ;
         iif( oCtrl:GetProp( "alignment" ) = "Bottom", "+BS_BOTTOM ", " " ) )
      cStyle := cStyle + iif( "Right" $ oCtrl:GetProp( "alignment" ), "+BS_RIGHTBUTTON ", " " )
      cStyle := cStyle + iif( oCtrl:GetProp( "3DLook" ) = "True", "+BS_PUSHLIKE ", " " )
   ENDIF
   cStyle := cStyle + iif( oCtrl:GetProp( "autohscroll" ) = "True" , "+ES_AUTOHSCROLL " , "" )
   cStyle := cStyle + iif( oCtrl:GetProp( "autovscroll" ) = "True" , "+ES_AUTOVSCROLL " , "" )
   cStyle := cStyle + iif( oCtrl:GetProp( "barshscroll" ) = "True" , "+WS_HSCROLL " , "" )
   cStyle := cStyle + iif( oCtrl:GetProp( "barsvscroll" ) = "True" , "+WS_VSCROLL " , "" )
   cStyle := cStyle + iif( oCtrl:GetProp( "VSCROLL" ) = "True" , "+WS_VSCROLL " , "" )
   cStyle := cStyle + iif( oCtrl:GetProp( "Border" ) = "True" .AND. oCtrl:cClass != "browse", "+WS_BORDER " , "" )
   cStyle := cStyle + iif( oCtrl:GetProp( "readonly" ) = "True" , "+ES_READONLY " , "" )
   cStyle := cStyle + iif( oCtrl:GetProp( "autohscroll" ) = "True" .AND. oCtrl:cClass == "browse", "+WS_HSCROLL " , "" )
   IF oCtrl:cClass == "page"
      cStyle := cStyle + iif( ( xproperty := oCtrl:GetProp("TabOrientation" ) ) != Nil, "+" + LTrim( Str(Val(xProperty ) ) ) + " ", " " )
      cStyle := cStyle + iif( ( xproperty := oCtrl:GetProp("TabStretch" ) ) != Nil, "+" + LTrim( Str(Val(xProperty ) ) ) + " ", " " )
   ENDIF
   IF oCtrl:cClass == "datepicker"
      cStyle := cStyle + iif( ( xproperty := oCtrl:GetProp("Layout" ) ) != Nil, "+" + LTrim( Str(Val(xProperty ) ) ) + " ", " " )
      cStyle := cStyle + iif( oCtrl:GetProp( "checked" ) = "True", "+DTS_SHOWNONE ", " " )
   ENDIF
   IF oCtrl:cClass == "trackbar"
      cStyle := cStyle + iif( oCtrl:GetProp( "TickStyle" ) = "Auto" , "+ 1 " , ;
         iif( oCtrl:GetProp( "TickStyle" ) = "None" , "+ 16", "+ 0" ) )
      cStyle := cStyle + iif( oCtrl:GetProp( "TickMarks" ) = "Both" , "+ 8 " , ;
         iif( oCtrl:GetProp( "TickMarks" ) = "Top" , "+ 4", "+ 0" ) )
   ENDIF
   IF Len( Trim( cStyle ) ) > 0  //.AND. VAL(&(substr(cStyle,1)))>0
      cStyle := ";" + hb_OsNewline() + Space( 8 ) +  "STYLE " + SubStr( cStyle, 2 )
   ELSE
      cStyle := ""
   ENDIF

   RETURN cStyle

   ENDFUNC

FUNCTION Func_name

   PARAMETERS oCtrl, nMeth

   PRIVATE cName, arr := ParseMethod( oCtrl:aMethods[ nMeth, 2 ] )

   IF Len( arr ) == 1 .OR. ( Len( arr ) == 2 .AND. ;
         Lower( Left( arr[ 1 ], 11 ) ) == "parameters " )

      RETURN arr

   ELSE
      IF ( cName := Trim( oCtrl:GetProp( "Name" ) ) ) == Nil .OR. Empty( cName )
         cName := oCtrl:cClass + "_" + LTrim( Str( oCtrl:id - 34000 ) )
      ENDIF

      cName += "_" + oCtrl:aMethods[ nMeth, 1 ]

   ENDIF

   RETURN cName

   ENDFUNC

FUNCTION Ctrl2Prg

   PARAMETERS oCtrl
   LOCAL nLocalParamPos := 0, lAddVar := .f.
   LOCAL lsubParameter := .F.

   PRIVATE cLocalParam := ""
   PRIVATE cFormParameters := ""

   PRIVATE stroka := "   @ ", classname, cStyle, i, j, cName, temp, varname, cMethod
   PRIVATE nLeft, nTop, nWidth, nHeight, lGroup

   i := AScan( aClass, oCtrl:cClass )

   IF i  != 0
      varname := oCtrl:GetProp( "varName" )

      nLeft := oCtrl:nLeft
      nTop := oCtrl:nTop
      temp := oCtrl:oContainer
      DO WHILE temp != Nil
         lGroup := iif( temp:GetProp( "NoGroup" ) != Nil .AND. temp:GetProp( "NoGroup" ) == "True", .F. , .T. )
         IF temp:lContainer
            nLeft -= temp:nLeft
            nTop -= temp:nTop
            lgroup := .T.
         ENDIF
         temp := temp:oContainer
      ENDDO
      IF !Empty( oCtrl:GetProp( "LocalOnClickParam" ) )
         cFormParameters := oCtrl:GetProp( "LocalOnClickParam" )
      ENDIF

      stroka += LTrim( Str( nLeft ) ) + "," + LTrim( Str( nTop ) ) + " "

      IF oCtrl:cClass == "editbox" .OR. oCtrl:cClass == "richedit"
         temp := oCtrl:GetProp( "cInitValue" )
      ELSEIF oCtrl:cClass != "ownerbutton" .AND. oCtrl:cClass != "shadebutton"
         temp := oCtrl:GetProp( "Caption" )
      ENDIF
      IF ( cName := Trim( oCtrl:GetProp( "Name" ) ) ) == Nil .OR. oCtrl:cClass = "radiogroup"
         cName := ""
      ENDIF

      // verificar se o combo tem check
      //IF oCtrl:cClass == "combobox"
      // aName[i] := IIF(oCtrl:GetProp("check") != Nil,{"GET COMBOBOXEX","GET COMBOBOXEX"}, {"COMBOBOX","GET COMBOBOX"})
      //ENDIF

      IF oCtrl:cClass != "radiogroup"      // NANDO
         IF varname == Nil .OR. Empty( varName )
            stroka += aName[i,1] + " " + iif( oCtrl:cClass != "timer" .AND. oCtrl:cClass != "listbox", cName, "" )       //+
            IF oCtrl:cClass != "richedit"
               stroka += iif( temp != Nil, iif( !Empty(cName ),' CAPTION "' + temp,' "' + temp ) + '"', "" ) + " "
            ELSE
               stroka += iif( temp != Nil, iif( !Empty(cName ),' TEXT "' + temp,' "' + temp ) + '"', "" ) + " "
            ENDIF
            IF oCtrl:cClass == "browse"
               stroka += iif( oCtrl:GetProp( "BrwType" ) != "dbf" , "ARRAY ", "DATABASE " )
            ENDIF

         ELSE
            IF oCtrl:cClass != "richedit"
               stroka += aName[i,2] + " " + iif( !Empty( cName ), cName + iif( oCtrl:cClass != "listbox",  " VAR " + varname + " "," " ), " " )
            ELSE
               stroka += aName[i,2] + " " + iif( !Empty( cName ), cName + " TEXT ", " " ) + varname + " "
            ENDIF
         ENDIF
      ELSE
         // NANDO
         stroka +=  aName[i,1] + " " + iif( temp != Nil, '"' + temp + '"', "" ) + " "
      ENDIF

      IF oCtrl:cClass = "checkbox" .AND. varname != Nil
         stroka +=  iif( temp != Nil, iif( !Empty(cName ),' CAPTION "' + temp,' "' + temp ) + '"', "" ) + " "
      ENDIF
      // butoes
      IF oCtrl:cClass == "button" .OR. oCtrl:cClass == "ownerbutton" .OR. oCtrl:cClass == "shadebutton"
         stroka += iif( ( temp := oCtrl:GetProp("Id" ) ) != Nil .AND. !Empty( temp ), " ID " + temp, "" ) + " "
      ENDIF
      //
      nHeight := 1
      IF oCtrl:cClass == "combobox" .OR. oCtrl:cClass == "listbox"
         cStyle := iif( ( temp := oCtrl:GetProp("aSort" ) ) != Nil .AND. temp = "True", "ASORT(", "" )
         IF ( temp := oCtrl:GetProp( "VarItems" ) ) != Nil .AND. !Empty( temp )
            stroka += "ITEMS " + cStyle + Trim( temp ) + iif( cStyle == "", " ", ") " )
         ELSEIF ( temp := oCtrl:GetProp( "Items" ) ) != Nil .AND. !Empty( temp )
            stroka += ";" + hb_OsNewline() + Space( 8 ) + "ITEMS " + cStyle + "{" + '"' + temp[1] + '"'
            j := 2
            DO WHILE j <= Len( temp )
               stroka += ',"' + temp[j] + '"'
               j ++
            ENDDO
            stroka += "}" + iif( cStyle == "", " ", ") " )
         ELSE
            stroka += " ITEMS {}"
         ENDIF
         IF oCtrl:cClass == "listbox"
            stroka += "INIT " + iif( varName != Nil, Trim( varname ) + " ", "1 " )
         ENDIF
      ENDIF

      IF oCtrl:cClass == "page"
         stroka += "ITEMS {} "
      ENDIF
      // != "Group"
      IF oCtrl:cClass == "bitmap"
         IF ( temp := oCtrl:GetProp( "Bitmap" ) ) != Nil
            // cImagem += " BACKGROUND BITMAP " + Iif( At(".",temp) !=0 ,"HBitmap():AddFile('" + temp+"') ","HBitmap():AddResource('" + temp + "') ")
            stroka += " ;" + hb_OsNewline() + Space( 8 ) + "SHOW " + iif( At( ".",Trim(temp ) ) != 0 , "HBitmap():AddFile('" + temp + "') ", "'" + temp + "' " )
            IF ( temp := oCtrl:GetProp( "lResource" ) ) != Nil .AND. temp = "True"
               stroka += " FROM RESOURCE "
            ENDIF
            stroka += " ;" + hb_OsNewline() + Space( 8 )
         ENDIF
      ENDIF

      IF oCtrl:oContainer != Nil
         //if oCtrl:cClass != "group" .OR. (oCtrl:cClass == "group" .AND.(temp:=oCtrl:GetProp("NoGroup" )) != Nil .AND. temp == "False") //nando pos condicao do OR->
         IF ( oCtrl:cClass != "group" .AND.  Empty( cofGroup ) ) .OR. Empty( cofGroup ) // nando pos
            IF ( temp := oCtrl:oContainer:GetProp( "Name" ) ) == Nil .OR. Empty( temp )
               IF oCtrl:oContainer:oContainer != Nil
                  temp := oCtrl:oContainer:oContainer:GetProp( "Name" )
               ENDIF
            ENDIF
            cofGroup := iif( Empty( cofGroup ), temp, cofGroup )
         ELSE
            temp := cofGroup
         ENDIF
         stroka += iif( lGroup, "OF " + temp + " ", "" )
         //endif
      ELSE
         // colocar o group para depois dos demais objetos
         IF !Empty( cGroup )
            FWrite( han, hb_OsNewline() + cGroup )
         ENDIF
         cofgroup := ""
         cGroup := ""
      ENDIF
      // ANTES DO SIZE
      // BASSO
      IF oCtrl:cClass == "link"
         IF ( temp := oCtrl:GetProp( "Link" ) ) != Nil .AND. !Empty( temp )
            stroka += " ;" + hb_OsNewline() + Space( 8 ) + "LINK '" + Trim( temp ) + "' "
         ENDIF
      ENDIF
      stroka += iif( oCtrl:GetProp( "Transparent" ) = "True", " TRANSPARENT ", " " )
      //oCtrl:cClass == "label" .OR.
      //
      IF oCtrl:cClass == "updown"
         stroka += "RANGE "
         temp := oCtrl:GetProp( "nLower" ) //) != Nil
         stroka += LTrim( Str( iif(temp = Nil, - 2147483647,Val(temp ) ),11 ) ) + ","
         temp := oCtrl:GetProp( "nUpper" ) //) != Nil
         stroka += LTrim( Str( iif(temp = Nil,2147483647,Val(temp ) ),11 ) ) + " "
      ENDIF
      //
      IF oCtrl:cClass == "combobox"
         IF ( temp := oCtrl:GetProp( "checkEX" ) ) != Nil
            stroka += ";" + hb_OsNewline() + Space( 8 ) + "CHECK {" + '"' + temp[1] + '"'
            j := 2
            DO WHILE j <= Len( temp )
               stroka += ',"' + temp[j] + '"'
               j ++
            ENDDO
            stroka += "} "
         ENDIF
         IF ( temp := oCtrl:GetProp( "nMaxLines" ) ) != Nil
            nHeight :=  Val( temp )
         ELSE
            nHeight := 4
         ENDIF
         IF oCtrl:GetProp( "lEdit" ) = "True"
            stroka += " EDIT ;" + hb_OsNewline() + Space( 8 )
         ENDIF
         IF oCtrl:GetProp( "lText" ) = "True"
            stroka += " TEXT "
         ENDIF
      ENDIF
      //

      IF oCtrl:cClass == "line"
         IF ( temp := oCtrl:GetProp( "lVertical" ) ) != Nil .AND. temp == "True"
            stroka += "LENGTH " + LTrim( Str( oCtrl:nHeight ) ) + " VERTICAL "
         ELSE
            stroka += "LENGTH " + LTrim( Str( oCtrl:nWidth ) ) + " "
         ENDIF
      ELSE
         // aqui que esta o SIZE
         stroka += "SIZE " + LTrim( Str( oCtrl:nWidth ) ) + "," + LTrim( Str( oCtrl:nHeight * nHeight ) ) + " "
      ENDIF

      stroka += CallFunc( "Style2Prg", { oCtrl } ) + " "
      // barraprogress
      IF ( temp := oCtrl:GetProp( "BarWidth" ) ) != Nil //.AND. temp == "True"
         stroka += " BARWIDTH " + temp
      ENDIF
      IF ( temp := oCtrl:GetProp( "Range" ) ) != Nil
         stroka += " QUANTITY " + temp
      ENDIF
      // TRACKBALL
      IF  oCtrl:cClass == "trackbar"
         nLeft   := oCtrl:GetProp( "Lower" )
         nTop    := oCtrl:GetProp( "Upper" )
         IF nLeft != Nil .AND. nTop != Nil
            stroka += " ;" + hb_OsNewline() + Space( 8 ) + "RANGE " + LTrim( nLeft ) + ", " + LTrim( nTop )
         ENDIF
         IF ( temp := oCtrl:GetProp( "lVertical" ) ) != Nil .AND. temp == "True"
            stroka += " VERTICAL "
         ENDIF
      ENDIF
      //
      IF oCtrl:cClass != "ownerbutton" .AND. oCtrl:cClass != "shadebutton"

         stroka += CallFunc( "Color2Prg", { oCtrl } ) + " "

      ENDIF
      //
      IF oCtrl:cClass == "ownerbutton" .OR. oCtrl:cClass == "shadebutton"
         IF ( temp := oCtrl:GetProp( "Flat" ) ) != Nil .AND. temp == "True"
            stroka += " FLAT "
         ENDIF
         IF ( temp := oCtrl:GetProp( "lCheck" ) ) != Nil .AND. temp == "True"
            stroka += " CHECK "
         ENDIF
         IF ( temp := oCtrl:GetProp( "enabled" ) ) != Nil .AND. temp == "False"
            stroka += " DISABLED "
         ENDIF

         IF oCtrl:cClass == "shadebutton"
            //temp := ""
            stroka += " ;" + hb_OsNewline() + Space( 8 )
            stroka += iif( ( temp := oCtrl:GetProp( "Effect" ) ) != Nil , " EFFECT " + temp + " ", "" )
            stroka += iif( ( temp := oCtrl:GetProp( "Palette" ) ) != Nil , " PALETTE " + temp + " ", "" )
            stroka += iif( ( temp := oCtrl:GetProp( "Granularity" ) ) != Nil , " GRANULARITY " + temp + " ", "" )
            stroka += iif( ( temp := oCtrl:GetProp( "Highlight" ) ) != Nil , " HIGHLIGHT " + temp + " ", "" )
            //stroka += Iif( !empty(temp)," ;" + hb_OsNewline() + Space(8),"")
         ENDIF

         IF ( temp := oCtrl:GetProp( "Caption" ) ) != Nil //.AND. !EMPTY(caption)
            stroka += " ;" + hb_OsNewline() + Space( 8 ) + "TEXT '" + Trim( temp ) + "' "

            IF oCtrl:GetProp( "Textcolor", @j ) != Nil .AND. !IsDefault( oCtrl, oCtrl:aProp[j] )
               stroka += "COLOR " + LTrim( Str( oCtrl:tcolor ) ) + " "
            ENDIF
            // VERIFICAR COORDENADAS
            nLeft   := oCtrl:GetProp( "TextLeft" )
            nTop    := oCtrl:GetProp( "TextTop" )
            nHeight := '0'
            nWidth  := '0'
            IF nLeft != Nil .AND. nTop != Nil
               stroka += " ;" + hb_OsNewline() + Space( 8 ) + "COORDINATES " + LTrim( nLeft ) + ", " + LTrim( nTop ) + ;
                  iif( oCtrl:cClass != "shadebutton", ", " + LTrim( nHeight ) + ", " + LTrim( nWidth ) + " ", " " )
            ENDIF
         ENDIF
         // VERIFICAR BMP
         IF ( temp := oCtrl:GetProp( "BtnBitmap" ) ) != Nil .AND. !Empty( temp )
            nLeft   := oCtrl:GetProp( "BmpLeft" )
            nTop    := oCtrl:GetProp( "BmpTop" )
            nHeight := '0'
            nWidth  := '0'
            //IF nLeft != Nil .AND. nTop != Nil
            stroka += " ;" + hb_OsNewline() + Space( 8 ) + "BITMAP " + "HBitmap():AddFile('" + temp + "') "
            IF oCtrl:GetProp( "lResource" ) = "True"
               stroka += " FROM RESOURCE "
            ENDIF
            stroka +=  iif( oCtrl:cClass != "shadebutton", " TRANSPARENT ", "" )
            stroka += " ;" + hb_OsNewline() + Space( 8 ) + "COORDINATES " + ;
               LTrim( nLeft ) + ", " + LTrim( nTop ) + ", " + LTrim( nHeight ) + ", " + LTrim( nWidth ) + " "
         ENDIF
         //ENDIF
      ENDIF

      IF oCtrl:cClass == "buttonex"
         IF !Empty( ( temp := oCtrl:GetProp("bitmap" ) ) )
            //cImagem += " BACKGROUND BITMAP HBitmap():AddFile('"+temp+"') "
            stroka += " ;" + hb_OsNewline() + Space( 8 ) + "BITMAP " + "(HBitmap():AddFile('" + temp + "')):handle "
            IF !Empty( ( temp := oCtrl:GetProp("pictureposition" ) ) )
               stroka += " ;" + hb_OsNewline() + Space( 8 ) + "BSTYLE " + Left( temp, 1 )
            ENDIF
         ENDIF
      ENDIF

      IF oCtrl:cClass == "editbox" .OR. oCtrl:cClass == "updown"
         IF ( cName := oCtrl:GetProp( "cPicture" ) ) != Nil .AND. !Empty( cName )
            stroka += "PICTURE '" + AllTrim( oCtrl:GetProp( "cPicture" ) ) + "' "
         ENDIF
         IF ( cName := oCtrl:GetProp( "nMaxLength" ) ) != Nil
            stroka += "MAXLENGTH " + LTrim( oCtrl:GetProp( "nMaxLength" ) ) + " "
         ENDIF
         IF oCtrl:cClass == "editbox"
            stroka += iif( oCtrl:GetProp( "password" ) = "True", " PASSWORD ", " " )
            stroka += iif( oCtrl:GetProp( "border" ) = "False", " NOBORDER ", " " )
         ENDIF
      ENDIF
      IF oCtrl:cClass == "browse"
         stroka += iif( oCtrl:GetProp( "Append" ) = "True", "APPEND ", " " )
         stroka += iif( oCtrl:GetProp( "Autoedit" ) = "True", "AUTOEDIT ", " " )
         stroka += iif( oCtrl:GetProp( "MultiSelect" ) = "True", "MULTISELECT ", " " )
         stroka += iif( oCtrl:GetProp( "Descend" ) = "True", "DESCEND ", " " )
         stroka += iif( oCtrl:GetProp( "NoVScroll" ) = "True", "NO VSCROLL ", " " )
         stroka += iif( oCtrl:GetProp( "border" ) = "False", "NOBORDER ", " " )
      ENDIF

      IF ( temp := oCtrl:GetProp( "Font" ) ) != Nil
         stroka += CallFunc( "FONT2STR", { temp } )
      ENDIF

      // tooltip
      IF oCtrl:cClass != "label"
         IF ( temp := oCtrl:GetProp( "ToolTip" ) ) != Nil .AND. !Empty( temp )
            stroka += "; " + hb_OsNewline() + Space( 8 ) + "TOOLTIP '" + temp + "'"
         ENDIF
      ENDIF

      // BASSO
      IF oCtrl:cClass == "animation"
         stroka += " OF " + cFormName
         //Fwrite( han, hb_OsNewline() + "   ADD STATUS " + cName + " TO " + cFormName + " ")
         IF ( temp := oCtrl:GetProp( "Filename" ) ) != Nil
            stroka += " ;" + hb_OsNewline() + Space( 8 ) + "FILE '" + Trim( temp ) + "' "
            stroka += " ;" + hb_OsNewline() + Space( 8 )
            stroka += iif( oCtrl:GetProp( "autoplay" ) = "True", "AUTOPLAY ", "" )
            stroka += iif( oCtrl:GetProp( "center" ) = "True", "CENTER ", "" )
            stroka += iif( oCtrl:GetProp( "transparent" ) = "True", "TRANSPARENT ", "" )
         ENDIF
      ENDIF
      //
      IF oCtrl:cClass == "status"
         stroka := ""
         cname := oCtrl:GetProp( "Name" )
         FWrite( han, hb_OsNewline() + "   ADD STATUS " + cName + " TO " + cFormName + " " )
         IF ( temp := oCtrl:GetProp( "aParts" ) ) != Nil
            FWrite( han, " ; " )
            stroka += Space( 8 ) + "PARTS " + temp[1]
            j := 2
            DO WHILE j <= Len( temp )
               stroka += ', ' + temp[j]
               j ++
            ENDDO
         ENDIF
      ENDIF
      IF oCtrl:cClass == "group" .AND. oCtrl:oContainer == Nil  //.AND. Empty( oCtrl:aControls )
         // enviar para tras
         cGroup += stroka
      ELSE
         FWrite( han, hb_OsNewline() )
         FWrite( han, stroka )
      ENDIF
      // Methods ( events ) for the control
      i := 1
      DO WHILE i <= Len( oCtrl:aMethods )
         // NANDO POS PARA TIRAR COISAS QUE NÇO TEM EM GETS
         IF Upper( SubStr( oCtrl:aMethods[i,1],3 ) ) = "INIT" .AND. ( oCtrl:cClass == "combobox" )
            i ++
            LOOP
         ENDIF
         //
         IF oCtrl:aMethods[ i, 2 ] != Nil .AND. ! Empty( oCtrl:aMethods[ i, 2 ] )
            IF Lower( Left( oCtrl:aMethods[ i, 2 ],10 ) ) == "parameters"

               // Note, do we look for a CR or a LF??
               j := At( _Chr( 10 ), oCtrl:aMethods[ i, 2 ] )

               temp := SubStr( oCtrl:aMethods[ i, 2 ], 12, j - 13 )
            ELSEIF Lower( Left( oCtrl:aMethods[ i, 2 ],1 ) ) == "("
               // Note, do we look for a CR or a LF??
               j := At( ")", oCtrl:aMethods[ i, 2 ] )
               cLocalParam := SubStr( oCtrl:aMethods[ i, 2 ], 1, j  )
               temp := ""
               lsubParameter := .T.
            ELSE
               temp := ""
            ENDIF

            IF varname != Nil .AND. ( Lower( oCtrl:aMethods[i,1] ) == "ongetfocus" ;
                  .OR. Lower( oCtrl:aMethods[i,1] ) == "onlostfocus" )

               cMethod := iif( Lower( oCtrl:aMethods[ i, 1 ] ) == "ongetfocus", "WHEN ", "VALID " )

            ELSE

               cMethod := "ON " + Upper( SubStr( oCtrl:aMethods[i,1],3 ) )

            ENDIF

            IF ValType( cName := Callfunc( "FUNC_NAME", { oCtrl, i } ) ) == "C"
               //
               IF oCtrl:cClass == "timer"
                  stroka := " {|" + temp + "| " + cName + "( " + temp + " ) }"
                  cname := oCtrl:GetProp( "Name" )
                  temp := oCtrl:GetProp( "interval" ) //) != Nil
                  stroka := "ON INIT {|| " + cName + " := HTimer():New( " + cFormName + ",," + iif( temp != Nil, temp, '0' ) + "," + stroka + " )}"
                  FWrite( han, " ; //OBJECT TIMER " + hb_OsNewline() + Space( 8 ) + stroka )
               ELSE
                  IF lsubParameter
                     //temp :=  " {|" + temp + "| " +  cName +"("+ cFormParameters + ")  }"
                     FWrite( han, " ;" + hb_OsNewline() + Space( 8 ) + cMethod + "{ ||" + cName + "(" + cFormParameters + ")  }"  )
                  ELSE

                     FWrite( han, " ; " + hb_OsNewline() + Space( 8 ) + cMethod + " {|" + temp + "| " + ;
                        cName + "( " + temp + " ) }" )
                  ENDIF
               ENDIF
            ELSE
               //
               IF oCtrl:cClass == "timer"
                  stroka := iif( cName != Nil, " {|" + temp + "| " + ;
                     iif( Len( cName ) == 1, cName[ 1 ], cName[ 2 ] ) + " }" , " " )
                  cname := oCtrl:GetProp( "Name" )
                  temp := oCtrl:GetProp( "value" ) //) != Nil
                  //ON INIT {|| oTimer1 := HTimer():New( otESTE,,5000,{|| OtIMER1:END(),hwg_Msginfo('oi'),hwg_EndDialog() } )}
                  stroka := "ON INIT {|| " + cName + " := HTimer():New( " + cFormName + ",," + temp + "," + stroka + " )}"
                  FWrite( han, " ; //OBJECT TIMER " + hb_OsNewline() + Space( 8 ) + stroka )
               ELSE

                  IF lsubParameter
                     //temp :=  " {|" + temp + "| " +  cName +"("+ cFormParameters + ")  }"
                     FWrite( han, " ;" + hb_OsNewline() + Space( 8 ) + cMethod + "{ ||" + cName + "(" + cFormParameters + ")  }"  )
                  ELSE
                     FWrite( han, " ;" + hb_OsNewline() + Space( 8 ) + cMethod + " {|" + temp + "| " +  iif( Len( cName ) == 1, cName[ 1 ], cName[ 2 ] ) + " }" )
                  ENDIF

               ENDIF
            ENDIF

         ENDIF
         i ++
      ENDDO

   ENDIF
   // gerar o codigo da TOOLBAR
   IF oCtrl:cClass == "toolbar"
      stroka := CallFunc( "Tool2Prg", { oCtrl } )
      FWrite( han, hb_OsNewline() + stroka )
   ENDIF

   // gerar o codigo do browse
   IF oCtrl:cClass == "browse"
      stroka := CallFunc( "Browse2Prg", { oCtrl } )
      FWrite( han, hb_OsNewline() + stroka )
   ENDIF

   IF !Empty( oCtrl:aControls )

      IF oCtrl:cClass == "page" .AND. ;
            ( temp := oCtrl:GetProp( "Tabs" ) ) != Nil .AND. !Empty( temp )
         //stroka := CallFunc( "Style2Prg", { oCtrl } ) + " "
         //Fwrite( han, stroka)
         j := 1
         DO WHILE j <= Len( temp )
            FWrite( han, hb_OsNewline() + "  BEGIN PAGE '" + temp[j] + "' OF " + oCtrl:GetProp( "Name" ) )

            i := 1
            DO WHILE i <= Len( oCtrl:aControls )
               IF oCtrl:aControls[i]:nPage == j
                  CallFunc( "Ctrl2Prg", { oCtrl:aControls[i] } )
               ENDIF
               i ++
            ENDDO

            FWrite( han, hb_OsNewline() + "  END PAGE OF " + oCtrl:GetProp( "Name" ) + hb_OsNewline() )
            j ++
         ENDDO
         RETURN
      ELSEIF oCtrl:cClass == "radiogroup"
         varname := oCtrl:GetProp( "varName" )
         IF varname == Nil
            FWrite( han, hb_OsNewline() + "  RADIOGROUP" )
         ELSE
            FWrite( han, hb_OsNewline() + "  GET RADIOGROUP " + varname )
         ENDIF
      ENDIF

      i := 1
      DO WHILE i <= Len( oCtrl:aControls )
         CallFunc( "Ctrl2Prg", { oCtrl:aControls[i] } )
         i ++
      ENDDO

      IF oCtrl:cClass == "radiogroup"
         temp := oCtrl:GetProp( "nInitValue" )
         FWrite( han, hb_OsNewline() + "  END RADIOGROUP SELECTED " + iif( temp == Nil,"1",temp ) + hb_OsNewline() )
      ENDIF
   ENDIF

   RETURN

   ENDFUNC



   // Entry point into interpreted code ------------------------------------


   PRIVATE han, fname := oForm:path + oForm:filename, stroka, oCtrl

   PRIVATE aControls := oForm:oDlg:aControls, alen := Len( aControls ), i, j, j1

   PRIVATE cName := oForm:GetProp( "Name" ), temp, cofGroup := "", cGroup := ""

   PRIVATE aClass := { "label", "button", "buttonex", "shadebutton", "checkbox", "radiobutton", ;
      "editbox", "group", "datepicker", "updown", "combobox", "line", "panel", ;
      "toolbar", "ownerbutton", "browse", "page" , "radiogroup" , "bitmap", "animation", ;
      "richedit", "monthcalendar", "tree", "trackbar", "progressbar", "status" , ;
      "timer", "listbox", "gridex", "menu", "link" }

   PRIVATE aName :=  { { "SAY" }, { "BUTTON" }, { "BUTTONEX" }, { "SHADEBUTTON" }, { "CHECKBOX","GET CHECKBOX" }, { "RADIOBUTTON" }, ;
      { "EDITBOX", "GET" }, { "GROUPBOX" }, { "DATEPICKER", "GET DATEPICKER" }, ;
      { "UPDOWN", "GET UPDOWN" }, { "COMBOBOX", "GET COMBOBOX" }, { "LINE" }, ;
      { "PANEL" }, { "TOOLBAR" }, { "OWNERBUTTON" }, { "BROWSE" }, { "TAB" }, { "GROUPBOX" }, { "BITMAP" }, ;
      { "ANIMATION" }, { "RICHEDIT", "RICHEDIT" }, { "MONTHCALENDAR" }, { "TREE" }, { "TRACKBAR" }, ;
      { "PROGRESSBAR" }, { "ADD STATUS" }, { "SAY ''" }, { "LISTBOX", "GET LISTBOX" }, ;
      { "GRIDEX" }, { "MENU" }, { "SAY" } }

   // NANDO POS
   PRIVATE nMaxId := 0
   PRIVATE cFormName := ""
   PRIVATE cStyle := "", cFunction
   PRIVATE cTempParameter, aParameters
   cFunction := StrTran( oForm:filename, ".prg", "" )
   //

   cName := iif( Empty( cName ), Nil, Trim( cName ) )
   han := FCreate( fname )

   //Add the lines to include
   //Fwrite( han,'#include "windows.ch"'+ hb_OsNewline()  )
   //Fwrite( han,'#include "guilib.ch"' + hb_OsNewline()+ hb_OsNewline() )
   FWrite( han, '#include "hwgui.ch"' + hb_OsNewline() )
   FWrite( han, '#include "common.ch"' + hb_OsNewline() )
   FWrite( han, '#ifdef __XHARBOUR__' + hb_OsNewline() )
   FWrite( han, '   #include "ttable.ch"' + hb_OsNewline() )
   FWrite( han, '#endif' + hb_OsNewline() + hb_OsNewline() )

   //Fwrite( han, "FUNCTION " + "_" + Iif( cName != Nil, cName, "Main" ) + hb_OsNewline()  )
   FWrite( han, "FUNCTION " + "_" + iif( cName != Nil, cFunction, cFunction ) + hb_OsNewline()  )

   // Declare 'Private' variables
   IF cName != Nil
      //    Fwrite( han, "PRIVATE " + cName + hb_OsNewline() )
      FWrite( han, "Local " + cName + hb_OsNewline() )
   ENDIF

   i := 1
   stroka := ""
   DO WHILE i <= aLen
      IF ( temp := aControls[i]:GetProp( "Name" ) ) != Nil .AND. ! Empty( temp )
         //       stroka += Iif( Empty(stroka), "PRIVATE ", ", " ) + temp
         stroka += iif( Empty( stroka ), "LOCAL ", ", " ) + temp
      ENDIF
      i ++
   ENDDO

   IF ! Empty( stroka )

      //Fwrite( han, stroka )
      aParameters := hb_atokens( stroka, ", " )

      stroka := ""
      i := 1
      WHILE i <= Len(  aParameters )
         IF Len( stroka ) < 76
            stroka += aParameters[i] + ", "
         ELSE
            FWrite( han, hb_OsNewline() + SubStr( stroka,1,Len(stroka ) - 2 ) )
            stroka := "LOCAL "
         ENDIF
         i ++
      ENDDO

      //  stroka := "LOCAL " + stroka
      Stroka += hb_OsNewline() //+ "PUBLIC oDlg"

      FWrite( han, hb_OsNewline() + SubStr( stroka,1,RAt(',',stroka ) - 1 ) )

   ENDIF

   stroka := ""
   i := 1
   DO WHILE i <= aLen
      IF ( temp := aControls[i]:GetProp( "VarName" ) ) != Nil .AND. ! Empty( temp )
         stroka += iif( ! Empty( stroka ), ", ", "" ) + temp
      ENDIF
      i ++
   ENDDO

   IF ! Empty( stroka )
      //    stroka := " PRIVATE " + stroka
      aParameters := hb_atokens( stroka, ", " )

      stroka := "LOCAL "
      i := 1
      WHILE i <= Len(  aParameters )
         //      para testar se variavel tem : no nome

         IF Len( stroka ) < 76
            IF At( ":", aParameters[i] ) == 0
               stroka += aParameters[i] + ", "
            ENDIF
         ELSE
            IF Upper( AllTrim( stroka ) ) == "LOCAL" .AND. Len( Upper( AllTrim(stroka ) ) ) > 5
               FWrite( han, hb_OsNewline() + SubStr( stroka,1,RAt(',',stroka ) - 1 ) )
            ENDIF
            stroka := "LOCAL "
         ENDIF
         i ++
      ENDDO

      //  stroka := " LOCAL " + stroka
      Stroka += hb_OsNewline() //+ "PUBLIC oDlg"
      IF Upper( SubStr(AllTrim( stroka ),1,5) ) == "LOCAL" .AND. Len( AllTrim(stroka ) ) > 5
         FWrite( han, hb_OsNewline() + SubStr( stroka,1,RAt(',',stroka ) - 1 ) )
      ENDIF
   ENDIF

   // DEFINIR AS VARIVEIS DE VARIABLES
   IF ( temp := oForm:GetProp( "Variables" ) ) != Nil
      j := 1
      stroka :=  hb_OsNewline()
      DO WHILE j <= Len( temp )
         // nando adicionu o PRIVATE PARA EVITAR ERROS NO CODIGO
         stroka += "PRIVATE "+temp[j] + hb_OsNewline()
         //stroka += "LOCAL " + temp[j] + hb_OsNewline()
         j ++
      ENDDO
      FWrite( han, hb_OsNewline() + stroka )
   ENDIF


   i := 1
   DO WHILE i <= Len( oForm:aMethods )
      IF oForm:aMethods[ i, 2 ] != Nil .AND. ! Empty( oForm:aMethods[ i, 2 ] )

         IF Lower( oForm:aMethods[i,1] ) == "onforminit"
            FWrite( han, hb_OsNewline() + hb_OsNewline() )
            FWrite( han, oForm:aMethods[i,2] )
         ENDIF

      ENDIF

      i ++
   ENDDO

   //cName := oForm:GetProp( "Name" )

   IF "DLG" $ Upper(  oForm:GetProp( "FormType" ) )
      // 'INIT DIALOG' command
      IF cName == Nil
         cName := "oDlg"
      ENDIF

      FWrite( han, hb_OsNewline() + hb_OsNewline() + '  INIT DIALOG ' + cname + ' TITLE "' + oForm:oDlg:title + '" ;' + hb_OsNewline() )

   ELSE
      // 'INIT WINDOW' command
      IF cName == Nil
         cName := "oWin"
      ENDIF
      FWrite( han, hb_OsNewline() + hb_OsNewline() + '  INIT WINDOW ' + cName + ' TITLE "' + oForm:oDlg:title + '" ;' + hb_OsNewline() )

   ENDIF

   //CallFunc( "Imagem2Prg", { oForm } )
   // Imagens
   cStyle := ""
   temp := oForm:GetProp( "icon" )
   IF !Empty( temp )
      cStyle += iif( oForm:GetProp( "lResource" ) = "True", "ICON HIcon():AddResource('" + temp + "') ", "ICON HIcon():AddFile('" + temp + "') " )
   ENDIF
   temp := oForm:GetProp( "bitmap" )
   IF !Empty( temp )
      cStyle += "BACKGROUND BITMAP HBitmap():AddFile('" + temp + "') "
   ENDIF
   IF Len( cStyle ) > 0
      FWrite( han,  Space( 4 ) + cStyle + " ;" + hb_OsNewline() )
   ENDIF

   cFormName := cName
   //
   // STYLE DO FORM
   //
   cStyle := ""
   IF oForm:GetProp( "AlwaysOnTop" ) = "True"
      cStyle += "+DS_SYSMODAL "
   ENDIF
   IF oForm:GetProp( "AutoCenter" ) = "True"
      cStyle += "+DS_CENTER "
   ENDIF
   //IF oForm:GetProp("FromStyle") = "Popup"
   //  cStyle += "+WS_POPUP"
   //ENDIF
   // IF oForm:GetProp("Modal") = .F.
   // endif
   IF oForm:GetProp( "SystemMenu" ) = "True"
      cStyle += "+WS_SYSMENU"
   ENDIF
   IF oForm:GetProp( "Minimizebox" ) = "True"
      cStyle += "+WS_MINIMIZEBOX"
   ENDIF
   IF oForm:GetProp( "Maximizebox" ) = "True"
      cStyle += "+WS_MAXIMIZEBOX"
   ENDIF
   IF oForm:GetProp( "SizeBox" ) = "True"
      cStyle += "+WS_SIZEBOX"
   ENDIF
   IF oForm:GetProp( "Visible" ) = "True"
      cStyle += "+WS_VISIBLE"
   ENDIF
   IF oForm:GetProp( "NoIcon" ) = "True"
      cStyle += "+MB_USERICON"
   ENDIF

   temp := 0
   IF Len( cStyle ) > 6
      temp := 26
      //cStyle := ";"+hb_OsNewline()+SPACE(8) +  "STYLE " + substr(cStyle,2)
      cStyle :=  Space( 1 ) + "STYLE " + SubStr( cStyle, 2 )
   ENDIF
   FWrite( han, Space( 4 ) + "AT " + LTrim( Str( oForm:oDlg:nLeft ) ) + "," ;
      + LTrim( Str( oForm:oDlg:nTop ) ) + ;
      " SIZE " + LTrim( Str( oForm:oDlg:nWidth ) ) + "," + ;
      LTrim( Str( oForm:oDlg:nHeight + temp ) ) )

   IF ( temp := oForm:GetProp( "Font" ) ) != Nil
      FWrite( han, CallFunc( "FONT2STR",{ temp } ) )
   ENDIF


   // NANDO POS
   IF oForm:GetProp( "lClipper" ) = "True"
      FWrite( han, ' CLIPPER '  )
   ENDIF
   IF oForm:GetProp( "lExitOnEnter" ) = "True"
      //-Fwrite( han,  ' ;' + hb_OsNewline() + SPACE(8) + 'NOEXIT'  )
      FWrite( han, ' NOEXIT '  )
   ENDIF
   //

   IF Len( cStyle ) > 6
      FWrite( han,  ' ;' + hb_OsNewline() + Space( 4 ) + cStyle )
   ENDIF

   i := 1
   DO WHILE i <= Len( oForm:aMethods )

      IF ! ( "ONFORM" $ Upper( oForm:aMethods[ i, 1 ] ) ) .AND. ;
            ! ( "COMMON" $ Upper( oForm:aMethods[ i, 1 ] ) ) .AND. oForm:aMethods[ i, 2 ] != Nil .AND. ! Empty( oForm:aMethods[ i, 2 ] )

         // NANDO POS faltam os parametros
         IF Lower( Left( oForm:aMethods[ i, 2 ],10 ) ) == "parameters"

            // Note, do we look for a CR or a LF??
            j := At( hb_OsNewline(), oForm:aMethods[ i, 2 ] )

            temp := SubStr( oForm:aMethods[ i, 2 ], 12, j - 13 )
         ELSE
            temp := ""
         ENDIF
         // fim
         // all methods are onSomething so, strip leading "on"
         FWrite( han, " ;" + + hb_OsNewline() + Space( 8 ) + "ON " + ;
            StrTran( StrTran( Upper( SubStr( oForm:aMethods[ i, 1 ], 3 ) ), "DLG", "" ), "FORM", "" ) + ;
            " {|" + temp + "| " + oForm:aMethods[ i, 1 ] + "( " + temp + " ) }" )

         // Dialog and Windows methods can have little different name, should be fixed

      ENDIF

      i ++
   ENDDO
   FWrite( han, hb_OsNewline() + hb_OsNewline() )

   // Controls initialization
   i := 1
   DO WHILE i <= aLen
      IF aControls[i]:cClass != "menu"
         IF aControls[i]:oContainer == Nil
            CallFunc( "Ctrl2Prg", { aControls[ i ] } )
         ENDIF
      ELSE
         nMaxId := 0
         FWrite( han, hb_OsNewline() + " MENU OF " + cformname + " " )
         CallFunc( "Menu2Prg", { aControls[ i ] , getmenu() } )
         FWrite( han, hb_OsNewline() + " ENDMENU" + " " + hb_OsNewline() + hb_OsNewline() )
      ENDIF
      i ++
   ENDDO
   temp := ""
   IF "DLG" $ Upper(  oForm:GetProp( "FormType" ) )
      // colocar uma expressao para retornar na FUNCAO
      IF ( temp := oForm:GetProp( "ReturnExpr" ) ) != Nil .AND. !Empty( temp )
         temp := "" + TEMP  // nando pos  return
      ELSE
         temp := cname + ":lresult"  // nando pos  return
      ENDIF
      FWrite( han, hb_OsNewline() + hb_OsNewline() + "   ACTIVATE DIALOG " + cname + hb_OsNewline() )
   ELSE
      FWrite( han, hb_OsNewline() + hb_OsNewline() + "   ACTIVATE WINDOW " + cname + hb_OsNewline() )
   ENDIF

   i := 1
   DO WHILE i <= Len( oForm:aMethods )

      IF oForm:aMethods[ i, 2 ] != Nil .AND. ! Empty( oForm:aMethods[ i, 2 ] )

         IF Lower( oForm:aMethods[ i, 1 ] ) == "onformexit"
            FWrite( han, oForm:aMethods[ i, 2 ] )
            FWrite( han, hb_OsNewline() + hb_OsNewline() )
         ENDIF

      ENDIF
      i ++
   ENDDO


   FWrite( han, "RETURN " + temp + hb_OsNewline() + hb_OsNewline() )

   // "common" Form/Dialog methods
   i := 1
   DO WHILE i <= Len( oForm:aMethods )

      IF oForm:aMethods[i,2] != Nil .AND. !Empty( oForm:aMethods[i,2] )

         IF ( cName := Lower( oForm:aMethods[i,1] ) ) == "common"
            j1 := 1
            temp := .F.

            DO WHILE .T.

               stroka := RdStr( , oForm:aMethods[i,2], @j1 )

               IF Len( stroka ) == 0
                  EXIT
               ENDIF

               IF Lower( Left( stroka,8 ) ) == "function"
                  FWrite( han, "STATIC " + stroka + hb_OsNewline() )
                  temp := .F.

               ELSEIF Lower( Left( stroka,6 ) ) == "return"
                  FWrite( han, stroka + hb_OsNewline() )
                  temp := .T.

               ELSEIF Lower( Left( stroka,7 ) ) == "endfunc"
                  IF !temp
                     FWrite( han, "Return Nil" +  hb_OsNewline() )
                  ENDIF
                  temp := .F.

               ELSE
                  FWrite( han, stroka + hb_OsNewline() )
                  temp := .F.
               ENDIF

            ENDDO

         ELSEIF cName != "onforminit" .AND. cName != "onformexit"

            FWrite( han, "STATIC FUNCTION " + oForm:aMethods[i,1] + hb_OsNewline() + _Chr( 13 ) )
            FWrite( han, oForm:aMethods[i,2] )

            j1 := RAt( hb_OsNewline(), oForm:aMethods[i,2] )

            IF j1 == 0 .OR. Lower( Left( LTrim( SubStr( oForm:aMethods[i,2],j1 + 1 ) ),6 ) ) != "return"
               FWrite( han, hb_OsNewline() + "RETURN Nil" )
            ENDIF

            FWrite( han, hb_OsNewline() + hb_OsNewline() )

         ENDIF

      ENDIF
      i ++

   ENDDO

   // Control's methods
   j := 1
   DO WHILE j <= aLen
      oCtrl := aControls[j]

      //hwg_Msginfo( oCtrl:GetProp("Name") )

      i := 1
      DO WHILE i <= Len( oCtrl:aMethods )

         //hwg_Msginfo( oCtrl:aMethods[ i, 1 ] + " / " + oCtrl:aMethods[ i, 2 ] )

         IF oCtrl:aMethods[ i, 2 ] != Nil .AND. ! Empty( oCtrl:aMethods[ i, 2 ] )

            IF ValType( cName := Callfunc( "FUNC_NAME", { oCtrl, i } ) ) == "C"

               FWrite( han, "STATIC FUNCTION " + cName + hb_OsNewline() )
               FWrite( han, oCtrl:aMethods[ i, 2 ] )

               j1 := RAt( hb_OsNewline(), oCtrl:aMethods[i,2] )

               IF j1 == 0 .OR. ;
                     Lower( Left( LTrim( SubStr( oCtrl:aMethods[ i, 2 ], j1 + 1 ) ), 6 ) ) != "return"

                  FWrite( han, hb_OsNewline() + "RETURN Nil" )

               ENDIF

               FWrite( han, hb_OsNewline() + hb_OsNewline() )

            ENDIF

         ENDIF

         i ++
      ENDDO

      j ++
   ENDDO
   FClose( han )

#endscript

