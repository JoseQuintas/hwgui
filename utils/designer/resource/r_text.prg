#SCRIPT READ
FUNCTION STR2FONT
PARAMETERS cFont
PRIVATE oFont
  IF !Empty( cFont )
    oFont := HFont():Add( NextItem( cFont,.T.,"," ), ;
       Val(NextItem( cFont,,"," )),Val(NextItem( cFont,,"," )), ;
       Val(NextItem( cFont,,"," )),Val(NextItem( cFont,,"," )), ;
       Val(NextItem( cFont,,"," )),Val(NextItem( cFont,,"," )), ;
       Val(NextItem( cFont,,"," )) )
  ENDIF
Return oFont
ENDFUNC

Private strbuf := Space(512), poz := 513, stroka, nMode := 0, itemName, i, j
Private han := FOPEN( oForm:path+oForm:filename ), arr := {}, oArea, oCtrl
Private cCaption, x, y, nWidth, nHeight, x2, y2, nAlign, oFont, cFont, nVar, xKoef, cm
Private cWidth, aVars

  IF han == - 1
    hwg_Msgstop( "Can't open "+oForm:path+oForm:filename )
    Return
  ENDIF
  DO WHILE .T.
    stroka := RDSTR( han,@strbuf,@poz,512 )
    IF LEN( stroka ) == 0
      EXIT
    ENDIF
    IF Left( stroka,1 ) == ";"
      LOOP
    ENDIF
    stroka := Ltrim( stroka )
    IF nMode == 0
      IF Left( stroka,1 ) == "#"
        IF Upper( Substr( stroka,2,6 ) ) == "REPORT"
          stroka := Ltrim( Substr( stroka,9 ) )
          IF Empty( oForm:name ) .OR. Upper( stroka ) == Upper( oForm:name )
            nMode := 1
          ENDIF
        ENDIF
      ENDIF
    ELSEIF nMode == 1
      IF Left( stroka,1 ) == "#"
        IF Upper( Substr( stroka,2,6 ) ) == "ENDREP"
          Exit
        ELSEIF Upper( Substr( stroka,2,6 ) ) == "SCRIPT"
          nMode := 2
          cCaption := ""
          IF itemName == "FORM"
            aVars := {}
          ENDIF
        ENDIF
      ELSE
        IF ( itemName := NextItem( stroka,.T. ) ) == "FORM"
          cWidth := NextItem( stroka )
          nWidth := Val( cWidth )
          nHeight:= Val( NextItem( stroka ) )
          xKoef := nWidth / Val( NextItem( stroka ) )
          oForm:CreateDialog( { {"Left","300"}, {"Top","120"}, ;
              {"Width","500"},{"Height","400"},{"Caption",itemName}, ;
              {"Paper Size","A4"},{"Orientation",Iif(nWidth>nHeight,"Landscape","Portrait")} } )
        ELSEIF itemName == "TEXT"
          itemName := "label"
          cCaption := NextItem( stroka )
          x := Val( NextItem( stroka ) )
          y := Val( NextItem( stroka ) )
          nWidth := Val( NextItem( stroka ) )
          nHeight := Val( NextItem( stroka ) )
          nAlign := Val( NextItem( stroka ) )
          cFont := NextItem( stroka )
          nVar := Val( NextItem( stroka ) )

          oFont := CallFunc( "Str2Font", { cFont } )
          Aadd( arr,{ itemName,x,y,nWidth,nHeight,Nil,cCaption,oFont,nAlign,nVar } )

        ELSEIF itemName == "HLINE" .OR. itemName == "VLINE" .OR. itemName == "BOX"
          itemName := Lower( itemName )
          x := Val( NextItem( stroka ) )
          y := Val( NextItem( stroka ) )
          nWidth := Val( NextItem( stroka ) )
          nHeight:= Val( NextItem( stroka ) )
          cFont  := NextItem( stroka )
          nAlign := Val( NextItem( cFont,.T.,"," ) ) + 1
          nVar   := Val( NextItem( cFont,,"," ) )

          Aadd( arr,{ itemName,x,y,nWidth,nHeight,Nil,nAlign,nVar } )

        ELSEIF itemName == "BITMAP"
          itemName := Lower( itemName )
          cCaption := NextItem( stroka )
          x := Val( NextItem( stroka ) )
          y := Val( NextItem( stroka ) )
          nWidth := Val( NextItem( stroka ) )
          nHeight := Val( NextItem( stroka ) )

          Aadd( arr,{ itemName,x,y,nWidth,nHeight,Nil,cCaption } )

        ELSEIF itemName == "MARKER"
          itemName := "area"
          cm := cCaption := NextItem( stroka )
          x := Val( NextItem( stroka ) )
          y := Val( NextItem( stroka ) )
          nHeight := 0
          IF cCaption == "EPF"
            IF ( i := Ascan( arr,{|a|a[1]=="area".AND.a[7]=="PF"} ) ) != 0
              arr[i,5] := y - arr[i,3]
            ENDIF
          ELSEIF cCaption == "EL"
          ELSE
            IF cCaption == "SL"
              IF ( i := Ascan( arr,{|a|a[1]=="area".AND.a[7]=="PH"} ) ) != 0
                arr[i,5] := y - arr[i,3]
              ENDIF
            ELSEIF cCaption == "PF"
              IF ( i := Ascan( arr,{|a|a[1]=="area".AND.a[7]=="SL"} ) ) != 0
                arr[i,5] := y - arr[i,3]
              ENDIF
            ELSEIF cCaption == "DF"
              IF ( i := Ascan( arr,{|a|a[1]=="area".AND.a[7]=="SL"} ) ) != 0 .AND. arr[i,5] == 0
                arr[i,5] := y - arr[i,3]
              ENDIF
              nHeight := Round( oForm:nPHeight*oForm:nKoeff,0 ) - y
            ENDIF
            Aadd( arr,{ itemName,0,y,9999,nHeight,Nil,cCaption,Nil } )
          ENDIF
        ENDIF
      ENDIF
    ELSEIF nMode == 2
      IF Left( stroka,1 ) == "#" .AND. Upper( Substr( stroka,2,6 ) ) == "ENDSCR"
         nMode := 1
         IF itemName == "area"
           IF cm == "SL"
             arr[Len(arr),6] := cCaption
           ELSE
             IF ( i := Ascan( arr,{|a|a[1]=="area".AND.a[7]=="SL"} ) ) != 0
               arr[i,8] := cCaption
             ENDIF
           ENDIF
         ELSEIF itemName == "label"
           arr[Len(arr),6] := cCaption
         ELSE
           IF ( j := Ascan( oForm:aMethods,{|a|a[1]=="onRepInit"} ) ) != 0
              oForm:aMethods[j,2] := cCaption
           ENDIF
         ENDIF
      ELSE
        cCaption += stroka+Chr(13)+chr(10)
        IF itemName == "FORM"
          DO WHILE !Empty( cFont := getNextVar( @stroka ) )
            Aadd( aVars,cFont )
          ENDDO
        ENDIF
      ENDIF
    ENDIF
  ENDDO
  Fclose( han )
  arr := Asort( arr,,, {|z,y|z[3]<y[3].OR.(z[3]==y[3].AND.z[2]<y[2]).OR.(z[3]==y[3].AND.z[2]==y[2].AND.(z[4]>y[4].OR.z[5]>y[5]))} )
  IF ( j := Ascan( arr,{|a|a[1]=="area".AND.a[7]=="PH"} ) ) > 1
    Aadd( arr,Nil )
    Ains( arr, 1 )
    arr[1] := { "area",0,0,9999,arr[j+1,3]-1,Nil,"DH",Nil }
  ENDIF
  i := 1
  DO WHILE i <= Len( arr )
    oArea := Nil
    j := i - 1
    DO WHILE j > 0      
       IF arr[i,2] >= arr[j,2] .AND. arr[i,2]+arr[i,4] <= arr[j,2]+arr[j,4] .AND. ;
          arr[i,3] >= arr[j,3] .AND. arr[i,3]+arr[i,5] <= arr[j,3]+arr[j,5]
         oArea := oForm:oDlg:aControls[1]:aControls[1]:aControls[j]
         EXIT
       ENDIF
       j --
    ENDDO
    x       := Round( arr[i,2] * xKoef,2 )
    y       := Round( arr[i,3] * xKoef,2 )
    nWidth  := Round( arr[i,4] * xKoef,2 )
    nHeight := Round( arr[i,5] * xKoef,2 )
    x2      := Round( ( arr[i,2]+arr[i,4]-1 ) * xKoef,2 )
    y2      := Round( ( arr[i,3]+arr[i,5]-1 ) * xKoef,2 )
    IF arr[i,1] == "area"
      cCaption := Iif( arr[i,7]=="PH","PageHeader",Iif( arr[i,7]=="SL", ;
          "Table",Iif( arr[i,7]=="PF","PageFooter",Iif( arr[i,7]=="DH","DocHeader","DocFooter" ) ) ) )
      oArea := HControlGen():New( oForm:oDlg:aControls[1]:aControls[1],"area",  ;
       { { "Left","0" }, { "Top",Ltrim(Str(y)) }, { "Width",cWidth }, ;
       { "Height",Ltrim(Str(nHeight)) }, { "Right",cWidth }, { "Bottom",Ltrim(Str(y2)) }, { "AreaType",cCaption } } )
      IF arr[i,6] != Nil
        j := Ascan( oArea:aMethods,{|a|a[1]=="onBegin"} )
        oArea:aMethods[j,2] := arr[i,6]
      ENDIF
      IF arr[i,8] != Nil
        j := Ascan( oArea:aMethods,{|a|a[1]=="onNextLine"} )
        oArea:aMethods[j,2] := arr[i,8]
      ENDIF
    ELSEIF arr[i,1] == "label"
      oCtrl := HControlGen():New( oForm:oDlg:aControls[1]:aControls[1],arr[i,1], ;
       { { "Left",Ltrim(Str(x)) }, { "Top",Ltrim(Str(y)) }, { "Width",Ltrim(Str(nWidth)) }, ;
       { "Height",Ltrim(Str(nHeight)) }, { "Right",Ltrim(Str(x2)) }, { "Bottom",Ltrim(Str(y2)) }, ;
       { "Caption",Iif(arr[i,10]==1,"",arr[i,7]) }, ;
       { "Justify",Iif(arr[i,9]=0,"Left",Iif(arr[i,9]=2,"Center","Right")) }, ;
       {"Font",arr[i,8]} } )
      IF oArea != Nil
        oArea:AddControl( oCtrl )
        oCtrl:oContainer := oArea
      ENDIF
      IF arr[i,10] == 1
        j := Ascan( oCtrl:aMethods,{|a|a[1]=="Expression"} )
        oCtrl:aMethods[j,2] := "Return "+arr[i,7]
      ENDIF
      IF arr[i,6] != Nil
        j := Ascan( oCtrl:aMethods,{|a|a[1]=="onBegin"} )
        oCtrl:aMethods[j,2] := arr[i,6]
      ENDIF
    ELSEIF arr[i,1] == "bitmap"
      oCtrl := HControlGen():New( oForm:oDlg:aControls[1]:aControls[1],arr[i,1], ;
       { { "Left",Ltrim(Str(x)) }, { "Top",Ltrim(Str(y)) }, { "Width",Ltrim(Str(nWidth)) }, ;
       { "Height",Ltrim(Str(nHeight)) }, { "Right",Ltrim(Str(x2)) }, { "Bottom",Ltrim(Str(y2)) }, { "Bitmap",arr[i,7] } } )
      IF oArea != Nil
        oArea:AddControl( oCtrl )
        oCtrl:oContainer := oArea
      ENDIF
    ELSE
      oCtrl := HControlGen():New( oForm:oDlg:aControls[1]:aControls[1],arr[i,1], ;
       { { "Left",Ltrim(Str(x)) }, { "Top",Ltrim(Str(y)) }, { "Width",Ltrim(Str(nWidth)) }, ;
       { "Height",Ltrim(Str(nHeight)) }, { "Right",Ltrim(Str(x2)) }, { "Bottom",Ltrim(Str(y2)) }, ;
       {"PenType",{"SOLID","DASH","DOT","DASHDOT","DASHDOTDOT"}[arr[i,7]]}, ;
       { "PenWidth",Ltrim(Str(arr[i,8])) } } )
      IF oArea != Nil
        oArea:AddControl( oCtrl )
        oCtrl:oContainer := oArea
      ENDIF
    ENDIF
    i ++
  ENDDO
  IF aVars != Nil .AND. !Empty(aVars)
    oForm:SetProp( "Variables",aVars )
  ENDIF

Return
#ENDSCRIPT

