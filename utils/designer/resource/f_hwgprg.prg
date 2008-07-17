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

FUNCTION Menu2Prg
	PARAMETERS oCtrl, alMenu

  PRIVATE stroka := "",  i, j, cName, temp, cMethod
  PRIVATE oNode //,almenu

//            [ ACCELERATOR <flag>, <key> ] ;
//            [<lDisabled: DISABLED>]       ;
   
   	i := 1
 	  IF Valtype( aLMenu[i,1] ) == "A"
  	 	stroka := space(2) + "  MENU TITLE '" + aLMenu[i,2] + "' ID " + str(aLMenu[i,3]) + " "
	 		Fwrite( han, _Chr(10) + stroka )
    ENDIF

    DO WHILE i <=  Len( aLMenu )
    
      IF Valtype( aLMenu[i,1] ) == "A"
         //BuildTree( oNode, aMenu[i,1] )
       	stroka := space(2*nMaxid) + "  MENU TITLE '" + aLMenu[i,2] + "' ID " + str(aLMenu[i,3]) + " "
     		Fwrite( han, _Chr(10) + stroka )
        nMaxId += 1 
  	    CallFunc( "Menu2Prg", { oCtrl ,alMenu[i,1] } )
  	    nMaxId -= 1 
        stroka := space(2*nmaxid) + "  ENDMENU  "
    		Fwrite( han, _Chr(10) + stroka )
  		ELSE   
  		  IF alMenu[i,2] != "-"
  		  	stroka := space(2*nMaxId+2) + "MENUITEM '" + alMenu[i,2] + "' ID " + ltrim(str(alMenu[i,3])) +"  " 
	  		  IF !EMPTY(alMenu[i,4])
  		       // Methods ( events ) for the control
    	       cMethod := "ACTION ( "  
      	     temp := STRTRAN(alMenu[i,4],CHR(10),", ")
        	   temp := STRTRAN(temp,CHR(13),"")
     				 stroka := stroka + cMethod + temp +" ) "
	    		ELSE
	 					stroka := stroka + 'ACTION ""'
   		 		ENDIF	
   		 	ELSE
   		 	  stroka := space(4+nMaxId) + "SEPARATOR"
				ENDIF	
     		Fwrite( han, _Chr(10) + stroka + " ")
     	ENDIF   
      i ++
    ENDDO
RETURN
ENDFUNC

FUNCTION Tool2Prg
   PARAMETERS oCtrl

   Private cName := "", cTool := "", cId :="", temp ,i,j,k, cTip
	 Private   oCtrl1, aMethods
   //Private crelexpr, clink, cfilter, cKey
   
   cName := TRIM(oCtrl:GetProp( "Name" ))
   //cTool += "    *- " + cname + _CHR(10)+ "    *- SCRIPT GERADO AUTOMATICAMENTE PELO DESIGNER" + _CHR(10)+"    *-  " + _CHR(10)
   IF cName = Nil .OR. empty(cName) 
   		RETURN cTool
   ENDIF	

   cId := VAL(IIF((temp := oCtrl:GetProp("Id")) != Nil .AND. !empty(temp),temp ,"700"))
   Fwrite( han, " ID "+LTRIM(STR(cid)))
   //<O>:AddButton(<nBitIp>,<nId>,<bstate>,<bstyle>,<ctext>,<bclick>,<c>,<d>)
   IF Len( oCtrl:aControls ) > 0 
      Fwrite( han, _CHR(10) + cTool)
      i := 1
      DO WHILE i <= Len( oCtrl:aControls )
        cName := Trim(oCtrl:GetProp( "Name" ) )
        oCtrl1 := oCtrl:aControls[i]
        cTool += SPACE(4)+cname+":AddButton("
        cTool += IIF((temp := oCtrl1:GetProp("Bitmap")) != Nil .AND. !empty(temp),temp ,"1")+", "
        cTool += LTRIM(STR(cId+i))+", "
        cTool += IIF((temp := oCtrl1:GetProp("State")) != Nil .AND. !empty(temp),temp ,"4")+", "
        cTool += IIF((temp := oCtrl1:GetProp("Style")) != Nil .AND. !empty(temp),temp ,"0")+", "
        cTool += IIF((temp := oCtrl1:GetProp("Caption")) != Nil .AND. !empty(temp),'"'+temp+'"','" "')+" "
        cTip  := Iif((temp:=oCtrl1:GetProp("ToolTip")) != Nil .AND. !empty(temp),"'"+temp+"'","")
        // Methods ( events ) for the control
        k := 1
        aMethods := {}
        DO WHILE k <= Len( oCtrl1:aMethods )
          IF oCtrl1:aMethods[ k, 2 ] != Nil .AND. ! Empty( oCtrl1:aMethods[ k, 2 ] )
            IF Lower( Left( oCtrl1:aMethods[ k, 2 ],10 ) ) == "parameters"
               // Note, do we look for a CR or a LF??
               j := At( _Chr(13), oCtrl1:aMethods[ k, 2 ] )
               temp := Substr( oCtrl1:aMethods[ k, 2 ], 12, j - 12 )
            ELSE
               temp := ""
            ENDIF
            //cMethod := " " + Upper(Substr(oCtrl:aMethods[i,1],1))
            IF Valtype( cName := Callfunc( "FUNC_NAME", { oCtrl1, k } ) ) == "C"
               temp :=  " {|" + temp + "| " +  cName + "( " + temp + " ) }" 
            ELSE
              temp := " {|" + temp + "| " + Iif( Len( cName ) == 1, cName[ 1 ], cName[ 2 ] ) + " }" 
	          ENDIF
	          AADD(aMethods,{lower(oCtrl1:aMethods[k,1]),temp})
          ENDIF
          k ++
        ENDDO
        //IF  k > 1
			  cTool += ","+CallFunc( "Bloco2Prg", { aMethods, "onClick" })
        //ELSE
   			//  cTool += ",{|| .T. }"
        //ENDIF
			  cTool += "," + cTip + ",''"
        Fwrite( han,cTool + ")" + _CHR(10))
        cTool := ""
        i ++
     ENDDO
		 //cTool := "    *- FIM DE " + cname + _CHR(10)
		 cTool := ""  //_CHR(10)
	 ENDIF  
   Return cTool
ENDFUNC


FUNCTION Browse2Prg
 PARAMETERS oCtrl
   #DEFINE BRW_ARRAY 1
	 #DEFINE BRW_DATABASE 2
	    
  Private cName := "", cBrowser := "", cAdd :="", temp ,i, j, k, nColumns, caArray, cAlias, cTmpAlias, oCtrl1
  Private crelexpr, clink, cfilter, cKey, nType
  Private aTypes, cType, nLength, aWidths , nDec ,lOpen := .F., nColunas,cHeader,cCampo,aMethods
   
  Private aBrwXml :=  { "Alias", "ColumnsCount" , "HeadRows", "FooterRows", "ShowHeader",;
											"ShowGridLinesSep", "GridLinesSep3D", "HeadTextColor", "GridLinesSepColor",;
											"LeftCol", "ColumnsFreeze", "AdjRight" }
											
  Private aBrwProp :=  { "alias", "nColumns", "nHeadRows", "nFootRows", "lDispHead", "lDispSep",;
                       "lSep3d", "headColor","sepColor", "nLeftCol","freeze", "lAdjRight" }

 
  cName := TRIM(oCtrl:GetProp( "Name" ))

  cBrowser += "    // " + cname + "    *- SCRIPT GERADO AUTOMATICAMENTE PELO DESIGNER" + _CHR(10)+"    //  " + _CHR(10)
  nType := IIF(oCtrl:GetProp( "BrwType") != "dbf" ,BRW_ARRAY,BRW_DATABASE)   
  IF cName = Nil .OR. empty(cName) .OR. ((cAlias:=oCtrl:GetProp("FileDbf"))  = Nil .AND. nType = BRW_DATABASE)
 		RETURN cBrowser
  ENDIF	
   
  nColumns := iif( (temp:=oCtrl:GetProp("ColumnsCount")) != Nil .AND. !empty(temp),val(temp) , 0)
  nColunas := nColumns
  cBrowser += space(4)+cname+":aColumns := {}" + _chr(10)

  j := 3
  DO WHILE j < LEN(aBrwProp) 
    temp := oCtrl:GetProp(aBrwXml[j])
 		IF temp  != Nil .AND. !empty(temp)
		   cBrowser += space(4)+cname+":"+aBrwProp[j]+ ":= "+ ;
 		   iif(temp = "True",'.T.',iif(temp="False",'.F.',temp)) +_chr(10)
		ENDIF
		j ++
  ENDDO		
  
  IF nType = BRW_DATABASE
    cAlias := LEFT(CutPath( cAlias ),AT(".",CutPath( cAlias ))-1)
    cAlias := Lower(Trim(iif( (temp:=oCtrl:GetProp("alias")) != Nil .AND. !empty(temp),temp , calias)))
	  cBrowser += space(4)+cname+":alias := '" + calias +"'"+ _chr(10)  
	  // abrir tablea
	  IF (temp:=oCtrl:GetProp("filedbf")) != Nil //.AND. !EMPTY(temp)
      cTmpAlias := Lower(LEFT(CutPath( temp ),AT(".",CutPath( temp ))-1))
      IF select(cTmpalias) = 0
        USE (value) NEW SHARED ALIAS (cTmpAlias) VIA "DBFCDX" //ftmp
        //SET INDEX TO (cTmpAlias)
        //MSGINFO(ALIAS())
        lopen := .T.
      ENDIF
	    //USE (temp) NEW ALIAS ftmp SHARED
	  	SELECT (cTmpAlias)
	  ELSE
	    RETURN	""
 	  ENDIF	
    //calias := alias()
    nColumns := IIF(nColumns = 0, IIF(Len( oCtrl:aControls ) = 0,&cTmpalias->(FCOUNT()),Len( oCtrl:aControls ) ),nColumns)
    cBrowser += space(4)+cname+":nColumns := "+Ltrim(Str(nColumns)) + _chr(10)
    cBrowser += SPACE(4)+"IF select("+cname+":alias) = 0 ; USE ('"+temp+"') NEW ALIAS ("+cname+":alias) SHARED ;ENDIF" + _CHR(10)
    cBrowser += SPACE(4)+"SELECT ("+cname+":alias) "+ _CHR(10)
    //  
    aTypes := &cTmpalias->(DBSTRUCT())  

    // CRIAR AS RELA€OES E O LINK
    temp := IIF((temp:=oCtrl:GetProp("childorder")) != Nil .AND. !empty(temp),trim(temp),"")
    cKey := ""
    IF !empty(temp)
      cBrowser += SPACE(4) + calias+"->(DBSETORDER('"+temp+"'))" + _chr(10)
      &calias->(DBSETORDER(temp))
   		cKey := &calias->(ordkey(temp))
   		ckey := IIF(At('+',ckey) > 0,LEFT(ckey, At('+',ckey)-1),ckey)
    ENDIF		
    crelexpr := IIF((temp:=oCtrl:GetProp("relationalexpr")) != Nil .AND. !empty(temp),trim(temp), cKey )   
    clink := IIF((temp:=oCtrl:GetProp("linkmaster")) != Nil .AND. !empty(temp),trim(temp),"")    
    IF !EMPTY(crelexpr) .AND. !EMPTY(clink)
      cBrowser += "    *-  LINK --> RELACIONAMENTO E FILTER " + _CHR(10)
      cBrowser += SPACE(4) + clink+"->(DBSETRELATION('"+calias+"', {|| "+crelexpr+"},'"+crelexpr+"')) " + _chr(10)
   	  cfilter := crelexpr + "=" + clink + "->(" + crelexpr + ")"
   	  cBrowser += SPACE(4) + calias+"->(DBSETFILTER( {|| "+cfilter+"}, '"+cfilter+"' ))" + _chr(10)+"    *-"+_CHR(10)
 	  ENDIF
	  // fim dos relacionamentos
	ELSE
    caArray := Trim(iif( (temp:=oCtrl:GetProp("aarray")) != Nil .AND. !empty(temp),temp , "{}" ))
 	  cBrowser += space(4)+cname+":aArray := " + caArray +""+ _chr(10)  
    nColumns := IIF(nColumns = 0, 1,nColumns)
	ENDIF
	  
  IF Len( oCtrl:aControls ) = 0 //nColunas = 0 // gerar automaticamente o BROWSE completo
	 	 i:=1
   	 DO WHILE i <= nColumns 
  		 IF nType = BRW_DATABASE   	   
    	   cBrowser += SPACE(4)+cname+":AddColumn( HColumn():New(FieldName("+ltrim(str(i))+") ,FieldBlock(FieldName("+ltrim(str(i))+")),"+;
  	  	  "'"+aTypes[i,2]+"',"+Ltrim(Str(aTypes[i,3]+1))+","+Ltrim(Str(aTypes[i,4]))+"))" + _chr(10) //,,,,,,,,,{|| .t.}))
  	   ELSE
  	     cBrowser += SPACE(4)+cname+":AddColumn( HColumn():New( ,{|v,o|Iif(v!=Nil,o:aArray[o:nCurrent]:=v,o:aArray[o:nCurrent])},'C',100,0))" + _CHR(10)
			 ENDIF	 
       i++        
	   ENDDO
	   cBrowser :=  _CHR(10) + cBrowser + "    *- FIM DE " + cname
	 ELSE	  
     Fwrite( han, _chr(10)+_CHR(10) + cbrowser)
     i := 1
     DO WHILE i <= Len( oCtrl:aControls )
       cName := Trim(oCtrl:GetProp( "Name" ) )
       oCtrl1 := oCtrl:aControls[i]
       cHeader := IIF((temp:=oCtrl1:GetProp("Heading")) != Nil,"'"+temp+"'" ,"")
       cCampo  := Lower(Iif( (temp:=oCtrl1:GetProp("FieldName")) != Nil .AND. !empty(temp),""+temp+"" ,FieldName(i)))
       cCampo  := Lower(Iif( (temp:=oCtrl1:GetProp("FieldExpr")) != Nil .AND. !empty(temp),""+temp+"" ,ccampo))
       m->nLength :=	IIF((temp:=oCtrl1:GetProp("Length")) != Nil, VAL(temp),temp)
       IF nType = BRW_DATABASE   	    
       	 cType  := TYPE("&cCampo")
         IF !(cAlias == cTmpAlias) .AND. cTmpAlias $ cCampo  
          	cCampo := STRTRAN(cCampo,cTmpAlias,cAlias)
				 ENDIF        
         temp := strtran(UPPER(cCampo),upper(cAlias)+"->","")
         // verificar se tem mais de um campo
         temp := substr(temp,1,IIF(at('+',temp)>0,at('+',temp)-1,LEN(temp)))
         j:={}
         AEVAL( aTypes, {|aField| aadd(j,aField[1])} )
         cHeader  := Iif( cHeader == Nil .OR. EMPTY(cHeader) ,'"'+temp+'"',''+cHeader+'')
         IF m->nLength = Nil
 	         m->nLength := &cTmpAlias->(fieldlen(ascan(j,temp)))
           m->nLength := IIF(m->nLength = 0 ,IIF(type("&cCampo") = "C",LEN(&cCampo),10),m->nLength)
         ENDIF  
 	       m->nDec := &cTmpAlias->(FIELDDEC(ascan(j,temp)))
         cCampo := "{|| " + cCampo + " }"
     	   //cBrowser := SPACE(4)+cname+":AddColumn( HColumn():New("+cHeader+",{|| "+cCampo+" },"+ "'"+aTypes[i]+"',"+;
   			 //		iif((temp:=oCtrl1:GetProp("Length"))!= Nil,LTRIM(STR(VAL(temp))),"10")+", "+;
	  		 //		Ltrim(Str(aDecimals[i]))+" " 
     	 ELSE
 	       cCampo := IIF(cCampo = Nil,".T.",cCampo)
         cCampo := IIF(TYPE("&cCampo")="B",cCampo,"{|| "+ cCampo +" }")  
         cType  := TYPE("&cCampo")
         m->nLength := IIF(m->nLength = Nil ,10,m->nLength)
     	   m->nDec := 0
			 ENDIF       
   	   IF (temp:=oCtrl1:GetProp("Picture")) != Nil .AND. AT(".9",temp) > 0
		       m->nDec := LEN(SUBSTR(temp,AT(".9",temp)+1))
		       //cType := "N"
			 ENDIF    
			 //cBrowser := SPACE(4)+cname+":AddColumn( HColumn():New("+cHeader+",{|| "+cCampo+" },"+ "'"+TYPE("&cCampo")+"',"+
  	   cBrowser := SPACE(4)+cname+":AddColumn( HColumn():New("+cHeader+", "+cCampo+" ,"+ "'"+cTYPE+"',"+;
     	       LTRIM(STR(m->nLength))+", "+Ltrim(Str(m->nDec))+" " 
        cbrowser += ","+iif((temp:=oCtrl1:GetProp("Editable"))!= Nil,IIF(temp="True",".T.",".F."),".T.")
				cbrowser += ","+iif((temp:=oCtrl1:GetProp("JustifyHeader"))!= Nil,LTRIM(STR(VAL(temp))),"")
				cbrowser += ","+iif((temp:=oCtrl1:GetProp("JustifyLine"))!= Nil,LTRIM(STR(VAL(temp))),"")
			  cbrowser += ","+iif((temp:=oCtrl1:GetProp("Picture"))!= Nil .and. !empty(temp),"'"+trim(temp)+"'","")
        //Fwrite( han, +_CHR(10) + cbrowser)
        
        // Methods ( events ) for the control
        k := 1
        aMethods := {}
        DO WHILE k <= Len( oCtrl1:aMethods )
          IF oCtrl1:aMethods[ k, 2 ] != Nil .AND. ! Empty( oCtrl1:aMethods[ k, 2 ] )
            IF Lower( Left( oCtrl1:aMethods[ k, 2 ],10 ) ) == "parameters"
               // Note, do we look for a CR or a LF??
               j := At( _Chr(13), oCtrl1:aMethods[ k, 2 ] )
               temp := Substr( oCtrl1:aMethods[ k, 2 ], 12, j - 12 )
            ELSE
               temp := ""
            ENDIF
            //cMethod := " " + Upper(Substr(oCtrl:aMethods[i,1],1))
            IF Valtype( cName := Callfunc( "FUNC_NAME", { oCtrl1, k } ) ) == "C"
               temp :=  " {|" + temp + "| " +  cName + "( " + temp + " ) }" 
            ELSE
              temp := " {|" + temp + "| " + Iif( Len( cName ) == 1, cName[ 1 ], cName[ 2 ] ) + " }" 
	          ENDIF
	          AADD(aMethods,{lower(oCtrl1:aMethods[k,1]),temp})
          ENDIF
          k ++
       ENDDO
			 cbrowser += ","+CallFunc( "Bloco2Prg", { aMethods, "onLostFocus" })
			 cbrowser += ","+CallFunc( "Bloco2Prg", { aMethods, "onGetFocus" })
       cbrowser += "," + iif((temp:=oCtrl1:GetProp("Items"))!= Nil,temp,"")				 
       cbrowser += ","+CallFunc( "Bloco2Prg", { aMethods, "ColorBlock" })
       cbrowser += ","+CallFunc( "Bloco2Prg", { aMethods, "HeadClick" })
       //cbrowser += "))"
       Fwrite( han,cbrowser + "))" + _CHR(10))
       //( <cHeader>,<block>,<cType>,<nLen>,<nDec>,<.lEdit.>,<nJusHead>, <nJusLine>, <cPict>, <{bValid}>, <{bWhen}>, <aItem>, <{bClrBlck}>, <{bHeadClick}> ) )
        i ++
     ENDDO
		 cBrowser := "    *- FIM DE " + cname + _CHR(10)
	 ENDIF  
   IF nType = BRW_DATABASE .AND.  lOpen
     USE
   ENDIF
  
   Return cBrowser
ENDFUNC

FUNCTION Bloco2Prg
PARAMETERS aMetodos,cmetodo 
   // Methods ( events ) for the control
  Private z ,temp
  
	z := ASCAN(aMetodos, {|aVal| aVal[1] == lower(cmetodo)})    
	temp := IIF( z > 0, aMetodos[z,2] ,"" )
  //Fwrite( han, "," + temp)
	Return TEMP
	
ENDFUNC
		 

FUNCTION Imagem2Prg
   PARAMETERS oCtrl

   Private cImagem := ""
   Private temp := ""
   

   IF oCtrl:cClass == "form"
     temp := oCtrl:GetProp("icon")
     IF !EMPTY(temp)
	     //cImagem += IIF(oCtrl:GetProp("lResource") := "True"," ICON HIcon():AddResource('"+temp+"') "," ICON "+temp +" ")
	     cImagem += " ICON "+Iif( At(".",temp) !=0 , "HIcon():AddFile('" + temp + "') ","HIcon():AddResource('" + temp +"') ")
		 ENDIF
     temp := oCtrl:GetProp("bitmap")
     IF !EMPTY(temp)
	     //cImagem += " BACKGROUND BITMAP HBitmap():AddFile('"+temp+"') "
 	     cImagem += " BACKGROUND BITMAP " + Iif( At(".",temp) !=0 ,"HBitmap():AddFile('" + temp+"') ","HBitmap():AddResource('" + temp + "') ")
		 ENDIF
       
   ELSEIF oCtrl:cClass == "editbox" .OR. oCtrl:cClass == "richedit"
       
   ELSEIF oCtrl:cClass == "updown"
       
   ELSEIF oCtrl:cClass == "button" .OR. oCtrl:cClass == "ownerbutton"

   ENDIF

   IF Len( cImagem ) > 0
       cImagem := ";"+_CHR(10)+SPACE(8) + cImagem
   ENDIF

   Return cImagem
   
ENDFUNC

FUNCTION Color2Prg
   PARAMETERS oCtrl

   Private cColor := ""
   Private xProperty := ""

    IF oCtrl:GetProp( "Textcolor",@j ) != Nil .AND. !IsDefault( oCtrl,oCtrl:aProp[j] )
         cColor += Iif( Empty(cStyle),"",";" + _Chr(10) + Space(8) ) + ;
        " COLOR " + Ltrim( Str(oCtrl:tcolor) ) + " "
    ENDIF
    IF oCtrl:GetProp( "Backcolor",@j ) != Nil .AND. !IsDefault( oCtrl,oCtrl:aProp[j] )
        cColor += " BACKCOLOR " + Ltrim( Str(oCtrl:bcolor) )
    ENDIF
    IF oCtrl:cClass == "link"
	    IF oCtrl:GetProp( "VisitColor",@j ) != Nil .AND. !IsDefault( oCtrl,oCtrl:aProp[j] )
         cColor += Iif( Empty(cStyle),"",";" + _Chr(10) + Space(8) ) + ;
        " VISITCOLOR " + Ltrim( Str(oCtrl:tcolor) ) + " "
    	ENDIF
    	IF oCtrl:GetProp( "LinkColor",@j ) != Nil .AND. !IsDefault( oCtrl,oCtrl:aProp[j] )
        cColor += " LINKCOLOR " + Ltrim( Str(oCtrl:bcolor) )
    	ENDIF
    	IF oCtrl:GetProp( "HoverColor",@j ) != Nil .AND. !IsDefault( oCtrl,oCtrl:aProp[j] )
        cColor += " HOVERCOLOR " + Ltrim( Str(oCtrl:bcolor) )
    	ENDIF
	 ENDIF
   IF Len( trim(cColor) ) > 0
       cColor := ";"+_CHR(10)+SPACE(8)  + cColor //substr(cStyle,2)
   ENDIF

   Return cColor
ENDFUNC

FUNCTION Style2Prg
   PARAMETERS oCtrl

   Private cStyle := ""
   Private xProperty := ""

	 cStyle := cStyle + iif( oCtrl:GetProp("multiline") = "True" .OR. oCtrl:GetProp("wordwrap") = "True" , "+ES_MULTILINE " , "" )
   IF oCtrl:cClass == "label"
       cStyle := cStyle + iif( oCtrl:GetProp("Justify") = "Center" , "+SS_CENTER " , "" )   
       cStyle := cStyle + iif( oCtrl:GetProp("Justify") = "Right" , "+SS_RIGHT " , "" )   
       cStyle += IIF(oCtrl:oContainer != Nil .AND. oCtrl:oContainer:cclass !=NIL .AND. oCtrl:oContainer:cclass = "page" ,"+SS_OWNERDRAW ","")
   ELSE  //IF oCtrl:cClass == "editbox" .OR. oCtrl:cClass == "richedit"
       cStyle := cStyle + iif( oCtrl:GetProp("Justify") = "Center" , "+ES_CENTER " , "" )   
       cStyle := cStyle + iif( oCtrl:GetProp("Justify") = "Right" , "+ES_RIGHT " , "" )   
   ENDIF     
   //ELSEIF oCtrl:cClass == "updown"
   IF oCtrl:cClass = "button" .OR. oCtrl:cClass == "ownerbutton" .OR. oCtrl:cClass == "shadebutton"
       cStyle := cStyle + "+WS_TABSTOP"   
       cStyle := cStyle + iif( oCtrl:GetProp("3DLook") = "False" , "+BS_FLAT " , "" )   
   ELSE    
      cStyle := cStyle + iif( oCtrl:GetProp("Enabled") = "False" , "+WS_DISABLED " , "" )          
   ENDIF
   
   IF oCtrl:cClass == "checkbox"
      cStyle := cStyle + iif( oCtrl:GetProp("alignment") = "Top","+BS_TOP ",;
        iif( oCtrl:GetProp("alignment") = "Bottom","+BS_BOTTOM "," " ) )
      cStyle := cStyle + Iif( "Right"$oCtrl:GetProp("alignment"),"+BS_RIGHTBUTTON "," " )
      cStyle := cStyle + iif( oCtrl:GetProp("3DLook") = "True", "+BS_PUSHLIKE "," ")
   ENDIF
   cStyle := cStyle + iif( oCtrl:GetProp("autohscroll") = "True" , "+ES_AUTOHSCROLL " , "" )
   cStyle := cStyle + iif( oCtrl:GetProp("autovscroll") = "True" , "+ES_AUTOVSCROLL " , "" )
   cStyle := cStyle + iif( oCtrl:GetProp("barshscroll") = "True" , "+WS_HSCROLL " , "" )
   cStyle := cStyle + iif( oCtrl:GetProp("barsvscroll") = "True" , "+WS_VSCROLL " , "" )       
   cStyle := cStyle + iif( oCtrl:GetProp("VSCROLL") = "True" , "+WS_VSCROLL " , "" )       
   cStyle := cStyle + iif( oCtrl:GetProp("Border") = "True" .AND.oCtrl:cClass != "browse", "+WS_BORDER " , "" )   
   cStyle := cStyle + iif( oCtrl:GetProp("readonly") = "True" , "+ES_READONLY " , "" )   
   cStyle := cStyle + iif( oCtrl:GetProp("autohscroll") = "True" .AND.oCtrl:cClass == "browse", "+WS_HSCROLL " , "" )   
   IF oCtrl:cClass == "page"
		  cStyle := cStyle + IiF((xproperty:=oCtrl:GetProp("TabOrientation")) != Nil,"+"+LTRIM(STR(val(xProperty)))+" "," ")
		  cStyle := cStyle + IiF((xproperty:=oCtrl:GetProp("TabStretch")) != Nil,"+"+LTRIM(STR(val(xProperty)))+" "," ")		  		  
	 ENDIF  
   IF oCtrl:cClass == "datepicker"
 		  cStyle := cStyle + IiF((xproperty:=oCtrl:GetProp("Layout")) != Nil,"+"+LTRIM(STR(val(xProperty)))+" "," ")
	 		cStyle := cStyle + IiF(oCtrl:GetProp("checked") = "True","+DTS_SHOWNONE "," ")
   ENDIF 
   IF oCtrl:cClass == "trackbar" 
     cStyle := cStyle + iif( oCtrl:GetProp("TickStyle") = "Auto" , "+ 1 " ,;
		                    iif( oCtrl:GetProp("TickStyle") = "None" , "+ 16", "+ 0" ) )
     cStyle := cStyle + iif( oCtrl:GetProp("TickMarks") = "Both" , "+ 8 " ,;
		                    iif( oCtrl:GetProp("TickMarks") = "Top" , "+ 4", "+ 0" ) )
	 ENDIF	                    
   IF Len( trim(cStyle) ) > 0  //.AND. VAL(&(substr(cStyle,1)))>0
       cStyle := ";"+_CHR(10)+SPACE(8) +  "STYLE " + substr(cStyle,2)
   ELSE
	    cStyle := ""    
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
      IF ( cName := Trim(oCtrl:GetProp( "Name" )) ) == Nil .OR. Empty( cName )
        cName := oCtrl:cClass + "_" + Ltrim( Str( oCtrl:id-34000 ) )
      ENDIF

      cName += "_" + oCtrl:aMethods[ nMeth, 1 ]

   ENDIF

   Return cName

ENDFUNC


FUNCTION Ctrl2Prg

   PARAMETERS oCtrl

   PRIVATE stroka := "   @ ", classname, cStyle, i, j, cName, temp, varname, cMethod
   PRIVATE nLeft, nTop, nWidth, nHeight, lGroup 

   i := Ascan( aClass, oCtrl:cClass )
	
   IF i  != 0
      varname := oCtrl:GetProp( "varName" )

      nLeft := oCtrl:nLeft
      nTop := oCtrl:nTop
      temp := oCtrl:oContainer
      DO WHILE temp != Nil
         lGroup := IIF(temp:GetProp("NoGroup" ) != Nil .AND. temp:GetProp("NoGroup" ) == "True",.F.,.T.)  			
         IF temp:lContainer
            nLeft -= temp:nLeft
            nTop -= temp:nTop
            lgroup := .T.
         ENDIF
         temp := temp:oContainer
      ENDDO
			
      stroka += Ltrim( Str(nLeft) ) + "," + Ltrim( Str(nTop) ) + " "
			
      IF oCtrl:cClass == "editbox" .OR. oCtrl:cClass == "richedit"
         temp := oCtrl:GetProp( "cInitValue" )
      ELSEIF oCtrl:cClass != "ownerbutton" .AND. oCtrl:cClass != "shadebutton"
         temp := oCtrl:GetProp( "Caption" )
      ENDIF
      IF ( cName := Trim(oCtrl:GetProp( "Name" ) )) == Nil .OR. oCtrl:cClass = "radiogroup"
         cName := ""
      ENDIF
      
      // verificar se o combo tem check
		  //IF oCtrl:cClass == "combobox"
      //	aName[i] := IIF(oCtrl:GetProp("check") != Nil,{"GET COMBOBOXEX","GET COMBOBOXEX"}, {"COMBOBOX","GET COMBOBOX"})
      //ENDIF

      IF oCtrl:cClass != "radiogroup"      // NANDO
	      IF varname == Nil .OR. Empty(varName) 
  	       stroka += aName[i,1] + " " + IIF( oCtrl:cClass != "timer" .AND. oCtrl:cClass != "listbox", cName, "")		 //+ 
 	         IF oCtrl:cClass != "richedit"  
              stroka += Iif( temp!=Nil,Iif( !Empty(cName),' CAPTION "'+temp,' "'+temp )+'"',"" ) + " "
           ELSE
              stroka += Iif( temp!=Nil,Iif( !Empty(cName),' TEXT "'+temp,' "'+temp )+'"',"" ) + " "
					 ENDIF   
 		       IF oCtrl:cClass == "browse"
		       		stroka += IIF(oCtrl:GetProp( "BrwType") != "dbf" ,"ARRAY ","DATABASE ")
					 ENDIF

    		ELSE
 	        IF oCtrl:cClass != "richedit" 
	        	 stroka += aName[i,2] + " " + Iif( !Empty(cName), cName + Iif(oCtrl:cClass != "listbox",  " VAR " + varname + " "," " )," ")
	        ELSE 
  		        stroka += aName[i,2] + " " + Iif( !Empty(cName), cName+" TEXT "," " ) + varname + " "
	        ENDIF
      	ENDIF
      ELSE
      	// NANDO
        stroka +=  aName[i,1] + " " + Iif( temp!=Nil,'"'+temp+'"',"" ) + " "      	
      ENDIF
      
      IF oCtrl:cClass = "checkbox" .AND. varname != Nil 
         stroka +=  Iif( temp!=Nil,Iif( !Empty(cName),' CAPTION "'+temp,' "'+temp )+'"',"" ) + " "
			ENDIF
			// butoes
			IF oCtrl:cClass == "button" .OR. oCtrl:cClass == "ownerbutton" .OR. oCtrl:cClass == "shadebutton"
			   stroka += IiF((temp := oCtrl:GetProp("Id")) != Nil .AND. !Empty(temp)," ID "+temp,"")+" "
			ENDIF
      //
   		nHeight := 1
 			IF oCtrl:cClass == "combobox" .OR. oCtrl:cClass == "listbox"
 			  cStyle := IIF((temp:=oCtrl:GetProp("aSort"))!= Nil .AND. temp="True","ASORT(","")
 				IF (temp := oCtrl:GetProp("VarItems")) != Nil .AND. !Empty(temp)
 				  stroka += "ITEMS "+cStyle+trim(temp) + iif(cStyle==""," ",") ")
 			  ELSEIF (temp := oCtrl:GetProp("Items")) != Nil .AND. !Empty(temp)
		 		  stroka += ";"+_chr(10)+space(8)+"ITEMS "+cStyle+"{"+'"'+temp[1]+'"'
		 		  j := 2
		 		  DO WHILE j <= len(temp)
   	 			  stroka += ',"'+temp[j]+'"'
   	 			  j ++
		 		  ENDDO
					stroka += "}" + iif(cStyle==""," ",") ")
				ELSE	
				  stroka += " ITEMS {}"
				ENDIF	
				IF oCtrl:cClass == "listbox" 
				    stroka += "INIT " + IIF(varName != Nil,trim(varname) + " ","1 ")
				ENDIF
			ENDIF

      IF oCtrl:cClass == "page"
         stroka += "ITEMS {} "
      ENDIF
      // != "Group"
 			IF oCtrl:cClass == "bitmap"
			  IF ( temp := oCtrl:GetProp( "Bitmap" ) ) != Nil
	   	    // cImagem += " BACKGROUND BITMAP " + Iif( At(".",temp) !=0 ,"HBitmap():AddFile('" + temp+"') ","HBitmap():AddResource('" + temp + "') ")
	       	stroka += " ;" + _Chr(10) + Space(8) + "SHOW " + Iif( At(".",TRIM(temp)) !=0 ,"HBitmap():AddFile('" + temp+"') ","'" + temp + "' ")
				  IF (temp := oCtrl:GetProp( "lResource" )) != Nil .AND. temp = "True"
         		stroka += " FROM RESOURCE "
         	ENDIF	
         	stroka += " ;" + _Chr(10) + Space(8)
				ENDIF
			ENDIF	

      IF oCtrl:oContainer != Nil
			 //if oCtrl:cClass != "group" .OR. (oCtrl:cClass == "group" .AND.(temp:=oCtrl:GetProp("NoGroup" )) != Nil .AND. temp == "False") //nando pos condicao do OR->
         IF (oCtrl:cClass != "group" .AND.  empty(cofGroup)) .OR. empty(cofGroup) // nando pos
         	 IF ( temp := oCtrl:oContainer:GetProp( "Name" ) ) == Nil .OR. Empty( temp )
             IF oCtrl:oContainer:oContainer != Nil
               temp := oCtrl:oContainer:oContainer:GetProp( "Name" )
             ENDIF
        	 ENDIF
           cofGroup := IIF(empty(cofGroup),temp,cofGroup)
         ELSE
        	  temp := cofGroup
				 ENDIF 
         stroka += IIF(lGroup,"OF " + temp + " ","")
       //endif 
      ELSE
        // colocar o group para depois dos demais objetos
			  IF !EMPTY(cGroup)
			     Fwrite( han, _Chr(10)+cGroup )
        ENDIF
 			  cofgroup := ""   
				cGroup := ""
      ENDIF
      // ANTES DO SIZE
      // BASSO
      IF oCtrl:cClass == "link" 
      	IF (temp := oCtrl:GetProp("Link" ) ) != Nil .AND. !EMPTY(temp)
    			stroka += " ;" + _Chr(10) + Space(8) + "LINK '" + TRIM(temp) + "' "      	
      	ENDIF
      ENDIF
     	stroka += IIF(oCtrl:GetProp("Transparent" ) ="True", " TRANSPARENT "," ")
      //oCtrl:cClass == "label" .OR. 
      //
			IF oCtrl:cClass == "updown"
				stroka += "RANGE "
				temp := oCtrl:GetProp("nLower" ) //) != Nil
				stroka += Ltrim(Str( IIF(temp = Nil,-2147483647,val(temp)),11 )) + ","
				temp := oCtrl:GetProp("nUpper" ) //) != Nil
				stroka += Ltrim(Str( IIF(temp = Nil,2147483647,val(temp)),11)) + " "
			ENDIF
 			//
			IF oCtrl:cClass == "combobox" 
 			  IF (temp := oCtrl:GetProp("checkEX")) != Nil
		 		  stroka += ";"+_chr(10)+space(8)+"CHECK {"+'"'+temp[1]+'"'
		 		  j := 2
		 		  DO WHILE j <= len(temp)
   	 			  stroka += ',"'+temp[j]+'"'
   	 			  j ++
		 		  ENDDO
					stroka += "} "
				ENDIF	
				IF (temp := oCtrl:GetProp("nMaxLines" )) != Nil
				  nHeight :=  val(temp)
				ELSE
					nHeight := 4
				ENDIF	
        IF oCtrl:GetProp( "lEdit" ) = "True"
       		stroka += " EDIT ;" + _CHR(10) + SPACE(8)
       	ENDIF	
        IF oCtrl:GetProp( "lText" ) = "True"
       		stroka += " TEXT "
       	ENDIF	
			ENDIF
			//
			
      IF oCtrl:cClass == "line"
         IF ( temp := oCtrl:GetProp( "lVertical" ) ) != Nil .AND. temp == "True"
            stroka += "LENGTH " + Ltrim( Str(oCtrl:nHeight) ) + " VERTICAL "
         ELSE
            stroka += "LENGTH " + Ltrim( Str(oCtrl:nWidth) ) + " "
         ENDIF
      ELSE
        // aqui que esta o SIZE
         stroka += "SIZE " + Ltrim( Str(oCtrl:nWidth) ) + "," + Ltrim( Str(oCtrl:nHeight * nHeight) ) + " "
      ENDIF

      stroka += CallFunc( "Style2Prg", { oCtrl } ) + " "
      // barraprogress
      IF ( temp := oCtrl:GetProp( "BarWidth" ) ) != Nil //.AND. temp == "True"
         stroka += " BARWIDTH "+temp
      ENDIF 
      IF ( temp := oCtrl:GetProp( "Range" ) ) != Nil 
         stroka += " QUANTITY "+temp
      ENDIF
      // TRACKBALL
      IF  oCtrl:cClass == "trackbar"
          nLeft   := oCtrl:GetProp( "Lower" ) 
          nTop    := oCtrl:GetProp( "Upper" )  
          IF nLeft != Nil .AND. nTop != Nil
   		      stroka += " ;" + _Chr(10) + Space(8) + "RANGE " + ltrim(nLeft)+", "+lTRIM(nTop) 
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
  					stroka += " ;" + _Chr(10) + Space(8)
  					stroka += Iif( (temp:=oCtrl:GetProp( "Effect" )) != Nil ," EFFECT "+temp + " ","")
 						stroka += Iif( (temp:=oCtrl:GetProp( "Palette" )) != Nil ," PALETTE "+temp + " ","")  
     				stroka += Iif( (temp:=oCtrl:GetProp( "Granularity" )) != Nil ," GRANULARITY "+temp + " ","")    
        		stroka += Iif( (temp:=oCtrl:GetProp( "Highlight" )) != Nil ," HIGHLIGHT "+temp + " ","")    
        		//stroka += Iif( !empty(temp)," ;" + _Chr(10) + Space(8),"")
				 ENDIF
				 
         IF ( temp := oCtrl:GetProp( "Caption" ) ) != Nil //.AND. !EMPTY(caption)
            stroka += " ;" + _Chr(10) + Space(8) + "TEXT '" + TRIM(temp) + "' "

            IF oCtrl:GetProp( "Textcolor",@j ) != Nil .AND. !IsDefault( oCtrl,oCtrl:aProp[j] )
               stroka += "COLOR " + Ltrim( Str(oCtrl:tcolor) ) + " "
            ENDIF
            // VERIFICAR COORDENADAS
            nLeft   := oCtrl:GetProp( "TextLeft" ) 
            nTop    := oCtrl:GetProp( "TextTop" )  
            nHeight := '0'
            nWidth  := '0'
            IF nLeft != Nil .AND. nTop != Nil
            	stroka += " ;" + _Chr(10) + Space(8) + "COORDINATES " + ltrim(nLeft)+", "+lTRIM(nTop) + ;
 					    IIF( oCtrl:cClass != "shadebutton",", "+ltrim(nHeight)+", "+lTRIM(nWidth) + " "," ")
						ENDIF
				 ENDIF		
					// VERIFICAR BMP
 					IF ( temp := oCtrl:GetProp( "BtnBitmap" ) ) != Nil .AND. !EMPTY(temp)
	            nLeft   := oCtrl:GetProp( "BmpLeft" ) 
  	          nTop    := oCtrl:GetProp( "BmpTop" )  
    	        nHeight := '0'
      	      nWidth  := '0'
	            //IF nLeft != Nil .AND. nTop != Nil
	            stroka += " ;" + _Chr(10) + Space(8) + "BITMAP " + "HBitmap():AddFile('" + temp+"') "
	            IF oCtrl:GetProp( "lResource" ) = "True"
            		stroka += " FROM RESOURCE "
            	ENDIF	
            	stroka +=  IIF(oCtrl:cClass != "shadebutton"," TRANSPARENT ","")
             	stroka += " ;" + _Chr(10) + Space(8) + "COORDINATES " + ;
    					  ltrim(nLeft)+", "+lTRIM(nTop) +", "+ltrim(nHeight)+", "+lTRIM(nWidth) + " "
					ENDIF
         //ENDIF
      ENDIF
      
			IF oCtrl:cClass == "buttonex" 
        IF !EMPTY((temp := oCtrl:GetProp("bitmap")))
         //cImagem += " BACKGROUND BITMAP HBitmap():AddFile('"+temp+"') "
           stroka += " ;" + _Chr(10) + Space(8) + "BITMAP " + "(HBitmap():AddFile('" + temp+"')):handle "
           IF !EMPTY((temp := oCtrl:GetProp("pictureposition")))
             stroka += " ;" + _Chr(10) + Space(8) + "BSTYLE "+left(temp,1)
           ENDIF   
	      ENDIF
			ENDIF

      IF oCtrl:cClass == "editbox" .OR. oCtrl:cClass == "updown"
         IF ( cName := oCtrl:GetProp( "cPicture" ) ) != Nil .AND. !EMPTY(cName)
            stroka += "PICTURE '" + ALLtrim( oCtrl:GetProp( "cPicture" )) + "' "
         ENDIF
				 IF ( cName := oCtrl:GetProp( "nMaxLength" ) ) != Nil
            stroka += "MAXLENGTH " + Ltrim( oCtrl:GetProp( "nMaxLength" )) + " "
         ENDIF		  
         IF oCtrl:cClass == "editbox"
           	stroka += IIF(oCtrl:GetProp("password") = "True", " PASSWORD "," ") 
   	      	stroka += IIF(oCtrl:GetProp("border") = "False", " NOBORDER "," ")
   	     ENDIF 	
      ENDIF
      IF oCtrl:cClass == "browse"
         	stroka += IIF(oCtrl:GetProp("Append") = "True", "APPEND "," ")
         	stroka += IIF(oCtrl:GetProp("Autoedit") = "True", "AUTOEDIT "," ")
         	stroka += IIF(oCtrl:GetProp("MultiSelect") = "True", "MULTISELECT "," ")
         	stroka += IIF(oCtrl:GetProp("Descend") = "True", "DESCEND "," ")
        	stroka += IIF(oCtrl:GetProp("NoVScroll") = "True", "NO VSCROLL "," ")
        	stroka += IIF(oCtrl:GetProp("border") = "False", "NOBORDER "," ")
			ENDIF

      IF ( temp := oCtrl:GetProp( "Font" ) ) != Nil
         stroka += CallFunc( "FONT2STR",{temp} )
      ENDIF
      
      // tooltip
      IF oCtrl:cClass != "label"
      	IF (temp := oCtrl:GetProp("ToolTip")) != Nil .AND. !EMPTY(temp)
        	stroka += "; "+ _chr(10) + SPACE(8)+ "TOOLTIP '" + temp + "'"
				ENDIF
			ENDIF	
			
			// BASSO
			IF oCtrl:cClass == "animation"
				stroka += " OF " + cFormName
				//Fwrite( han, _Chr(10) + "   ADD STATUS " + cName + " TO " + cFormName + " ")
			  IF ( temp := oCtrl:GetProp( "Filename" ) ) != Nil
	       	stroka += " ;" + _Chr(10) + Space(8) + "FILE '" + TRIM(temp) + "' "
	       	stroka += " ;" + _Chr(10) + Space(8)
         	stroka += IIF(oCtrl:GetProp( "autoplay" ) = "True","AUTOPLAY ","")
         	stroka += IIF(oCtrl:GetProp( "center" ) = "True","CENTER ","")
         	stroka += IIF(oCtrl:GetProp( "transparent" ) = "True","TRANSPARENT ","")
				ENDIF
			ENDIF	
			//
			IF oCtrl:cClass == "status"
				stroka := ""
			  cname := oCtrl:GetProp( "Name" )
			  Fwrite( han, _Chr(10) + "   ADD STATUS " + cName + " TO " + cFormName + " ")
				IF (temp := oCtrl:GetProp("aParts")) != Nil
    		  Fwrite( han, " ; ")
  	 		 	stroka += space(8)+"PARTS "+temp[1]
		 		  j := 2
		 		  DO WHILE j <= len(temp)
   	 			  stroka += ', '+temp[j]
   	 			  j ++
		 	    ENDDO
		 	  ENDIF 
      ENDIF
      IF oCtrl:cClass == "group" .AND.oCtrl:oContainer == Nil  //.AND. Empty( oCtrl:aControls )
        // enviar para tras
        cGroup += stroka
      ELSE
        Fwrite( han, _Chr(10) )
        Fwrite( han, stroka )
			ENDIF
      // Methods ( events ) for the control
      i := 1
      DO WHILE i <= Len( oCtrl:aMethods )
				 // NANDO POS PARA TIRAR COISAS QUE NÇO TEM EM GETS
				 IF Upper(Substr(oCtrl:aMethods[i,1],3)) = "INIT" .AND. (oCtrl:cClass == "combobox")
						i ++
						LOOP
				 ENDIF		 
				 //
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
              //
           		IF oCtrl:cClass == "timer"
           			stroka := " {|" + temp + "| " + cName + "( " + temp + " ) }" 
			          cname := oCtrl:GetProp( "Name" )
				        temp := oCtrl:GetProp("interval") //) != Nil
           		  stroka := "ON INIT {|| " + cName + " := HTimer():New( " + cFormName + ",," + IIF(temp != Nil,temp,'0') + "," + stroka + " )}"
                Fwrite( han, " ; //OBJECT TIMER " + _Chr(10) + space(8) + stroka)
           		ELSE
               Fwrite( han, " ; " + _Chr(10) + Space(8) + cMethod + " {|" + temp + "| " + ;
                            cName + "( " + temp + " ) }" )
              ENDIF              
            ELSE
              //
           		IF oCtrl:cClass == "timer"
        				stroka := IIF(cName != Nil," {|" + temp + "| " +;
                            Iif( Len( cName ) == 1, cName[ 1 ], cName[ 2 ] ) + " }" ," ")
			          cname := oCtrl:GetProp( "Name" )
				        temp := oCtrl:GetProp("value") //) != Nil
	  			      //ON INIT {|| oTimer1 := HTimer():New( otESTE,,5000,{|| OtIMER1:END(),msginfo('oi'),enddialog() } )}
	              stroka := "ON INIT {|| " + cName + " := HTimer():New( " + cFormName + ",," + temp + "," + stroka + " )}"
                Fwrite( han, " ; //OBJECT TIMER " + _Chr(10) + space(8) + stroka)
       	  		ELSE
              	Fwrite( han, " ;" + _Chr(10) + Space(8) + cMethod + " {|" + temp + "| " +;
                            Iif( Len( cName ) == 1, cName[ 1 ], cName[ 2 ] ) + " }" )
							ENDIF                            
           ENDIF

         ENDIF
         i ++
      ENDDO

   ENDIF
	// gerar o codigo da TOOLBAR
  IF oCtrl:cClass == "toolbar"
     stroka := CallFunc( "Tool2Prg", { oCtrl } )
     Fwrite( han, _chr(10)+stroka)
  ENDIF
   
	// gerar o codigo do browse
  IF oCtrl:cClass == "browse"
     stroka := CallFunc( "Browse2Prg", { oCtrl } )
     Fwrite( han, _chr(10)+stroka)
  ENDIF

   IF !Empty( oCtrl:aControls )

      IF oCtrl:cClass == "page" .AND. ;
         ( temp := oCtrl:GetProp("Tabs") ) != Nil .AND. !Empty( temp )
                  //stroka := CallFunc( "Style2Prg", { oCtrl } ) + " "
         //Fwrite( han, stroka)
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
        varname := oCtrl:GetProp( "varName" )
      	IF varname == Nil
         	Fwrite( han, _Chr(10) + "  RADIOGROUP" )
        ELSE
        	Fwrite( han, _Chr(10) + "  GET RADIOGROUP "+varname )
				ENDIF 
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

Private cName := oForm:GetProp( "Name" ), temp, cofGroup := "", cGroup :=""

Private aClass := { "label", "button", "buttonex", "shadebutton","checkbox", "radiobutton",;
                    "editbox", "group", "datepicker", "updown", "combobox", "line", "panel",;
										"toolbar", "ownerbutton", "browse","page" , "radiogroup" ,"bitmap", "animation",;
										"richedit", "monthcalendar", "tree", "trackbar", "progressbar", "status" ,;
										"timer","listbox","gridex", "menu", "link"}

Private aName :=  { {"SAY"}, {"BUTTON"}, {"BUTTONEX"}, {"SHADEBUTTON"}, {"CHECKBOX","GET CHECKBOX"}, {"RADIOBUTTON"},;
                    {"EDITBOX","GET"}, {"GROUPBOX"}, {"DATEPICKER","GET DATEPICKER"},;
                    {"UPDOWN","GET UPDOWN"}, {"COMBOBOX","GET COMBOBOX"}, {"LINE"},;
                    {"PANEL"}, {"TOOLBAR"}, {"OWNERBUTTON"}, {"BROWSE"},{"TAB"},{"GROUPBOX"}, {"BITMAP"},;
										{"ANIMATION"}, {"RICHEDIT","RICHEDIT"}, {"MONTHCALENDAR"}, {"TREE"}, {"TRACKBAR"},;
										{"PROGRESSBAR"}, {"ADD STATUS"}, {"SAY ''" }, {"LISTBOX","GET LISTBOX" },;
										{"GRIDEX"}, {"MENU"}, {"SAY"} }
										
// NANDO POS
Private nMaxId := 0
Private cFormName := ""
Private cStyle := "", cFunction

  cFunction := STRTRAN(oForm:filename,".prg","")
  //  

  cName := IIF( EMPTY(cName),Nil,TRIM(cName) )
  han := Fcreate( fname )

  //Add the lines to include
  //Fwrite( han,'#include "windows.ch"'+ _Chr(10)  )
  //Fwrite( han,'#include "guilib.ch"' + _Chr(10)+ _Chr(10) )
  Fwrite( han,'#include "hwgui.ch"' + _Chr(10)+ _Chr(10) )
  
  //Fwrite( han, "FUNCTION " + "_" + Iif( cName != Nil, cName, "Main" ) + _Chr(10)  )
  Fwrite( han, "FUNCTION " + "_" + Iif( cName != Nil, cFunction, cFunction ) + _Chr(10)  )

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
    stroka := " PRIVATE " + stroka
    Stroka += _Chr(10) //+ "PUBLIC oDlg"

    Fwrite( han, _Chr(10) + stroka )
  ENDIF
  
  // DEFINIR AS VARIVEIS DE VARIABLES
   IF ( temp := oForm:GetProp( "Variables" ) ) != Nil
      j:=1
      stroka :=  _chr(10)
      DO WHILE j <= len(temp)
        // nando adicionu o PRIVATE PARA EVITAR ERROS NO CODIGO
      	stroka += "PRIVATE "+temp[j] + _chr(10)
      	j ++
      ENDDO	
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

   //cName := oForm:GetProp( "Name" )
   
   IF "DLG" $ Upper(  oForm:GetProp("FormType") )
      // 'INIT DIALOG' command
      IF cName == Nil
         cName := "oDlg"
      ENDIF

      Fwrite( han, _Chr(10) + _Chr(10) + '  INIT DIALOG '+cname+' TITLE "' + oForm:oDlg:title + '" ;' + _Chr(10) )

   ELSE
      // 'INIT WINDOW' command
      IF cName == Nil
         cName := "oWin"
      ENDIF
      Fwrite( han, _Chr(10) + _Chr(10) + '  INIT WINDOW '+cName+' TITLE "' + oForm:oDlg:title + '" ;' + _Chr(10) )

   ENDIF

   //CallFunc( "Imagem2Prg", { oForm } )   
   // Imagens
   cStyle := ""  
   temp := oForm:GetProp("icon")
   IF !EMPTY(temp)
	     cStyle += IIF(oForm:GetProp("lResource") = "True","ICON HIcon():AddResource('"+temp+"') ","ICON HIcon():AddFile('"+temp+"') ")
	 ENDIF
   temp := oForm:GetProp("bitmap")
   IF !EMPTY(temp)
	    cStyle += "BACKGROUND BITMAP HBitmap():AddFile('"+temp+"') "
	 ENDIF
   IF Len( cStyle ) > 0
       Fwrite( han,  SPACE(4) + cStyle +" ;"+_CHR(10))
   ENDIF

   cFormName := cName
   	 //
   // STYLE DO FORM
   //
   cStyle := ""  
   IF oForm:GetProp("AlwaysOnTop") = "True"
 	 		cStyle += "+DS_SYSMODAL "  
 	 ENDIF		
   IF oForm:GetProp("AutoCenter") = "True"
 	 		cStyle += "+DS_CENTER "  
 	 ENDIF		
  //IF oForm:GetProp("FromStyle") = "Popup"
  //  cStyle += "+WS_POPUP"
  //ENDIF
  // IF oForm:GetProp("Modal") = .F.
  // endif
  IF oForm:GetProp("SystemMenu") = "True"
     cStyle += "+WS_SYSMENU"
  ENDIF
  IF oForm:GetProp("Minimizebox") = "True"
     cStyle += "+WS_MINIMIZEBOX"
  ENDIF
  IF oForm:GetProp("Maximizebox") = "True"
     cStyle += "+WS_MAXIMIZEBOX"
	ENDIF
  IF oForm:GetProp("SizeBox") = "True"
  	cStyle += "+WS_SIZEBOX"
  ENDIF	
  IF oForm:GetProp("Visible") = "True"
		cStyle += "+WS_VISIBLE"
	ENDIF
	IF oForm:GetProp("NoIcon") = "True"
		cStyle += "+MB_USERICON"
	ENDIF

  temp := 0	
 	IF len(cStyle) > 6
 	  temp := 26
    //cStyle := ";"+_CHR(10)+SPACE(8) +  "STYLE " + substr(cStyle,2)
    cStyle :=  SPACE(1)+"STYLE " + substr(cStyle,2)
	ENDIF
  Fwrite( han, Space(4) + "AT " + Ltrim( Str( oForm:oDlg:nLeft ) ) + "," ;
                                 + Ltrim( Str( oForm:oDlg:nTop ) ) + ;
                           " SIZE " + Ltrim( Str( oForm:oDlg:nWidth ) ) + "," +;
                                      Ltrim( Str( oForm:oDlg:nHeight + temp ) ) )

   IF ( temp := oForm:GetProp( "Font" ) ) != Nil
      Fwrite( han, CallFunc( "FONT2STR",{temp} ) )
   ENDIF

	 
	 // NANDO POS
   IF oForm:GetProp("lClipper") = "True"
      Fwrite( han, ' CLIPPER '  )   
   ENDIF   
   IF oForm:GetProp("lExitOnEnter") = "True"
      //-Fwrite( han,  ' ;' + _Chr(10) + SPACE(8) + 'NOEXIT'  )   
      Fwrite( han, ' NOEXIT '  )   
   ENDIF 
	 //
	
	IF len(cStyle) > 6
     Fwrite( han,  ' ;' + _Chr(10) + SPACE(4) + cStyle )   
  ENDIF 
	 
   i := 1
   DO WHILE i <= Len( oForm:aMethods )

      IF ! ("ONFORM" $ Upper( oForm:aMethods[ i, 1 ] ) ) .AND. ;
         ! ("COMMON" $ Upper( oForm:aMethods[ i, 1 ] ) ) .AND. oForm:aMethods[ i, 2 ] != Nil .AND. ! Empty( oForm:aMethods[ i, 2 ] )

				  // NANDO POS faltam os parametros
          IF Lower( Left( oForm:aMethods[ i, 2 ],10 ) ) == "parameters"

              // Note, do we look for a CR or a LF??
              j := At( _Chr(13), oForm:aMethods[ i, 2 ] )

              temp := Substr( oForm:aMethods[ i, 2 ], 12, j - 12 )
           ELSE
              temp := ""
           ENDIF
				  // fim 
         // all methods are onSomething so, strip leading "on"
         fWrite( han, " ;" + + _Chr(10) + Space(8) + "ON " + ;
                      StrTran( StrTran( Upper( SubStr( oForm:aMethods[ i, 1 ], 3 ) ), "DLG", "" ), "FORM", "" ) + ;
                      " {|" + temp + "| " + oForm:aMethods[ i, 1 ] + "( "+ temp +" ) }" )

         // Dialog and Windows methods can have little different name, should be fixed

      ENDIF

      i ++
  ENDDO
  Fwrite( han, _Chr(10) + _Chr(10) )

   // Controls initialization
   i := 1
   DO WHILE i <= aLen
  		IF aControls[i]:cClass != "menu"
      	IF aControls[i]:oContainer == Nil
        	CallFunc( "Ctrl2Prg", { aControls[ i ] } )
      	ENDIF
      ELSE	
        nMaxId := 0
		   	Fwrite( han, _Chr(10) + " MENU OF " + cformname + " ")
		  	CallFunc( "Menu2Prg", { aControls[ i ] ,getmenu() } )
		   	Fwrite( han, _Chr(10) + " ENDMENU" + " " + _chr(10)+_chr(10))
      ENDIF	
      i ++
   ENDDO
	 temp := ""
   IF "DLG" $ Upper(  oForm:GetProp("FormType") )
      // colocar uma expressao para retornar na FUNCAO
      IF (temp:=oForm:GetProp("ReturnExpr")) != Nil .AND. !EMPTY(temp)
        temp := ""+TEMP  // nando pos  return
      ELSE  
      	temp := cname+":lresult"  // nando pos  return
      ENDIF
      Fwrite( han, _Chr(10) + _Chr(10) + "   ACTIVATE DIALOG "+cname + _Chr(10) )
   ELSE
      Fwrite( han, _Chr(10) + _Chr(10) + "   ACTIVATE WINDOW "+cname + _Chr(10) )
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

  
  Fwrite( han, "RETURN " + temp+ _Chr(10) + _Chr(10) )

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
