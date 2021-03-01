/*
 * $Id$
 *
 * Designer
 * Simple code editor
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hbclass.ch"
#include "windows.ch"
#include "guilib.ch"
#include "hxml.ch"

#define ES_SAVESEL 0x00008000

#define HILIGHT_KEYW    1
#define HILIGHT_FUNC    2
#define HILIGHT_QUOTE   3
#define HILIGHT_COMM    4

Static oDlg, oEdit, cIniName
Static nTextLength
Static cNewLine := e"\r\n"

Memvar oDesigner, cCurDir

CLASS HDTheme

   CLASS VAR aThemes  INIT {}
   CLASS VAR nSelected
   CLASS VAR oFont
   CLASS VAR lChanged INIT .F.
   CLASS VAR oHili
   DATA name
   DATA normal
   DATA command
   DATA comment
   DATA quote
   DATA number

   METHOD New( name )  INLINE ( ::name:=name, Self )
   METHOD Add( name )  INLINE ( ::name:=name,Aadd(::aThemes,Self),Self )
ENDCLASS

Function LoadEdOptions( cFileName )
Local oIni := HXMLDoc():Read( cFileName ), oOptDesc
Local i, j, j1, cTheme, oTheme, oThemeXML, arr

   cIniName := cFileName
   oOptDesc := oIni:aItems[1]
   FOR i := 1 TO Len( oOptDesc:aItems )
      IF oOptDesc:aItems[i]:title == "font"
         HDTheme():oFont := hwg_hfrm_FontFromXML( oOptDesc:aItems[i] )
      ELSEIF oOptDesc:aItems[i]:title == "hilight"
         HDTheme():oHili := Hilight():New( oOptDesc:aItems[i] )
      ELSEIF oOptDesc:aItems[i]:title == "themes"
         cTheme := oOptDesc:aItems[i]:GetAttribute( "selected" )
         FOR j := 1 TO Len( oOptDesc:aItems[i]:aItems )
            oThemeXML := oOptDesc:aItems[i]:aItems[j]
            oTheme := HDTheme():Add( oThemeXML:GetAttribute( "name" ) )
            IF oTheme:name == cTheme
               HDTheme():nSelected := j
            ENDIF
            FOR j1 := 1 TO Len( oThemeXML:aItems )
               arr := { oThemeXML:aItems[j1]:GetAttribute("tcolor","N",0), ;
                        oThemeXML:aItems[j1]:GetAttribute("bcolor","N",16777215), ;
                        oThemeXML:aItems[j1]:GetAttribute("bold","L",.F.),   ;
                        oThemeXML:aItems[j1]:GetAttribute("italic","L",.F.) }
               IF oThemeXML:aItems[j1]:title == "normal"
                  oTheme:normal := arr
               ELSEIF oThemeXML:aItems[j1]:title == "command"
                  oTheme:command := arr
               ELSEIF oThemeXML:aItems[j1]:title == "comment"
                  oTheme:comment := arr
               ELSEIF oThemeXML:aItems[j1]:title == "quote"
                  oTheme:quote := arr
               ELSEIF oThemeXML:aItems[j1]:title == "number"
                  oTheme:number := arr
               ENDIF
            NEXT
         NEXT
      ENDIF
   NEXT
Return Nil

Function SaveEdOptions()
Local oIni := HXMLDoc():Read( cCurDir+cIniName )
Local i, j, oNode, nStart, oThemeDesc, aAttr

   oNode := oIni:aItems[1]
   nStart := 1
   IF oNode:Find( "font",@nStart ) == Nil
      oNode:Add( hwg_Font2XML( HDTheme():oFont ) )
   ELSE
      oNode:aItems[nStart] := hwg_Font2XML( HDTheme():oFont )
   ENDIF
   IF oNode:Find( "themes",@nStart ) != Nil
      oNode := oNode:aItems[nStart]
      oNode:SetAttribute( "selected", HDTheme():aThemes[HDTheme():nSelected]:name )
      oNode:aItems := {}
      FOR i := 1 TO Len( HDTheme():aThemes )
         oThemeDesc := oNode:Add( HXMLNode():New( "theme",,{ {"name",HDTheme():aThemes[i]:name} } ) )
         aAttr := { {"tcolor",Ltrim(Str(HDTheme():aThemes[i]:normal[1]))}, ;
                    {"bcolor",Ltrim(Str(HDTheme():aThemes[i]:normal[2]))} }
         IF HDTheme():aThemes[i]:normal[3]
            Aadd( aAttr, { "bold","True" } )
         ENDIF
         IF HDTheme():aThemes[i]:normal[4]
            Aadd( aAttr, { "italic","True" } )
         ENDIF
         oThemeDesc:Add( HXMLNode():New( "normal",HBXML_TYPE_SINGLE,aAttr ) )

         aAttr := { {"tcolor",Ltrim(Str(HDTheme():aThemes[i]:command[1]))}, ;
                    {"bcolor",Ltrim(Str(HDTheme():aThemes[i]:command[2]))} }
         IF HDTheme():aThemes[i]:command[3]
            Aadd( aAttr, { "bold","True" } )
         ENDIF
         IF HDTheme():aThemes[i]:command[4]
            Aadd( aAttr, { "italic","True" } )
         ENDIF
         oThemeDesc:Add( HXMLNode():New( "command",HBXML_TYPE_SINGLE,aAttr ) )

         aAttr := { {"tcolor",Ltrim(Str(HDTheme():aThemes[i]:comment[1]))}, ;
                    {"bcolor",Ltrim(Str(HDTheme():aThemes[i]:comment[2]))} }
         IF HDTheme():aThemes[i]:comment[3]
            Aadd( aAttr, { "bold","True" } )
         ENDIF
         IF HDTheme():aThemes[i]:comment[4]
            Aadd( aAttr, { "italic","True" } )
         ENDIF
         oThemeDesc:Add( HXMLNode():New( "comment",HBXML_TYPE_SINGLE,aAttr ) )

         aAttr := { {"tcolor",Ltrim(Str(HDTheme():aThemes[i]:quote[1]))}, ;
                    {"bcolor",Ltrim(Str(HDTheme():aThemes[i]:quote[2]))} }
         IF HDTheme():aThemes[i]:quote[3]
            Aadd( aAttr, { "bold","True" } )
         ENDIF
         IF HDTheme():aThemes[i]:quote[4]
            Aadd( aAttr, { "italic","True" } )
         ENDIF
         oThemeDesc:Add( HXMLNode():New( "quote",HBXML_TYPE_SINGLE,aAttr ) )

         aAttr := { {"tcolor",Ltrim(Str(HDTheme():aThemes[i]:number[1]))}, ;
                    {"bcolor",Ltrim(Str(HDTheme():aThemes[i]:number[2]))} }
         IF HDTheme():aThemes[i]:number[3]
            Aadd( aAttr, { "bold","True" } )
         ENDIF
         IF HDTheme():aThemes[i]:number[4]
            Aadd( aAttr, { "italic","True" } )
         ENDIF
         oThemeDesc:Add( HXMLNode():New( "number",HBXML_TYPE_SINGLE,aAttr ) )

      NEXT
   ENDIF
   oIni:Save( cCurDir+cIniName )

Return Nil

Function EditMethod( cMethName, cMethod )
Local i
Local oFont := HDTheme():oFont
Local cParamString
Local bKeyDown := {|o,nKey|
   IF nKey == VK_ESCAPE .AND. oDlg != Nil
      oDlg := Nil
      o:oParent:Close()
      Return -1
   ENDIF
   Return -1
   }

   i := Ascan( oDesigner:aMethDef, {|a|a[1]==Lower(cMethName)} )
   cParamString := Iif( i == 0, "", oDesigner:aMethDef[i,2] )
   INIT DIALOG oDlg TITLE "Edit '"+cMethName+"' method"          ;
      AT 100,240  SIZE 600,300  FONT oDesigner:oMainWnd:oFont    ;
      STYLE WS_POPUP+WS_VISIBLE+WS_CAPTION+WS_SYSMENU+WS_MAXIMIZEBOX+WS_SIZEBOX ;
      ON INIT {||ChangeTheme(HDTheme():nSelected),hwg_Movewindow(oDlg:handle,100,240,600,310)} ;
      ON EXIT {||Iif(oEdit:lUpdated.AND.hwg_Msgyesno("Code was changed! Save it?", "Designer"),(cMethod:=oEdit:GetText(),.T.),.T.)}

   MENU OF oDlg
      MENU TITLE "&Options"
         MENUITEM "&Font" ACTION editChgFont()
         MENU TITLE "&Select theme"
            FOR i := 1 TO Len( HDTheme():aThemes )
               Hwg_DefineMenuItem( HDTheme():aThemes[i]:name, 1020+i, &( "{||ChangeTheme("+LTrim(Str(i,2))+"),HDTheme():lChanged:=.T.}" ) )
            NEXT
         ENDMENU
         MENUITEM "&Configure" ACTION EditColors()
      ENDMENU
      MENU TITLE "&Edit"
         MENUITEM "&Undo"+Chr(9)+"Ctrl+Z" ACTION oEdit:Undo()
         SEPARATOR
         MENUITEM "&Cut"+Chr(9)+"Ctrl+X" ACTION oEdit:onKeyDown( Asc('X'),,FCONTROL )
         MENUITEM "&Copy"+Chr(9)+"Ctrl+C" ACTION oEdit:onKeyDown( Asc('C'),,FCONTROL )
         MENUITEM "&Paste"+Chr(9)+"Ctrl+V" ACTION oEdit:onKeyDown( Asc('V'),,FCONTROL )
         SEPARATOR
         MENUITEM "&Select all"+Chr(9)+"Ctrl+A" ACTION oEdit:onKeyDown( Asc('A'),,FCONTROL )
      ENDMENU
      MENUITEM "&Parameters" ACTION Iif(!Empty(cParamString).and.Upper(Left(oEdit:Gettext(),10))!="PARAMETERS",oEdit:InsText({1,1},"Parameters "+cParamString+cNewLine),.F.)
      MENUITEM "&Exit" ACTION oDlg:Close()
   ENDMENU

   oEdit := HCEdit():New( ,,, 0, 0, 400, oDlg:nHeight, oFont,, {|o,x,y|o:Move(,,x,y)} )
   IF hwg__isUnicode()
      oEdit:lUtf8 := .T.
   ENDIF
   oEdit:bKeyDown := bKeyDown
   oEdit:HighLighter( HDTheme():oHili )
   IF !Empty( cMethod )
      oEdit:SetText( cMethod )
   ENDIF
   cMethod := Nil

   ACTIVATE DIALOG oDlg

Return cMethod

Function ChangeTheme( nTheme )
Local oTheme, oFont

   IF HDTheme():nSelected != Nil
      hwg_Checkmenuitem( oDlg:handle,1020+HDTheme():nSelected, .F. )
   ENDIF
   hwg_Checkmenuitem( oDlg:handle,1020+nTheme, .T. )
   HDTheme():nSelected := nTheme
   oTheme := HDTheme():aThemes[HDTheme():nSelected]
   oFont := HDTheme():oFont
   oEdit:tColor := oTheme:normal[1]
   oEdit:bColorCur := oEdit:bColor := oTheme:normal[2]

   oEdit:SetHili( HILIGHT_KEYW, Iif( oTheme:command[3].OR.oTheme:command[4], oFont:SetFontStyle(oTheme:command[3],,oTheme:command[4]), ;
         Iif( oTheme:command[4], oFont:SetFontStyle(,,.T.), -1 ) ), oTheme:command[1], oTheme:command[2] )
   oEdit:SetHili( HILIGHT_QUOTE, Iif( oTheme:quote[3].OR.oTheme:quote[4], oFont:SetFontStyle(oTheme:quote[3],,oTheme:quote[4]), ;
         Iif( oTheme:quote[4], oFont:SetFontStyle(,,.T.), -1 ) ), oTheme:quote[1], oTheme:quote[2] )
   oEdit:SetHili( HILIGHT_COMM, Iif( oTheme:comment[3].OR.oTheme:comment[4], oFont:SetFontStyle(oTheme:comment[3],,oTheme:comment[4]), ;
         Iif( oTheme:comment[4], oFont:SetFontStyle(,,.T.), -1 ) ), oTheme:comment[1], oTheme:comment[2] )

   oEdit:Refresh()
Return Nil

Static Function editChgFont()
Local oFont

   IF ( oFont := HFont():Select( oEdit:oFont ) ) != Nil
       oEdit:SetFont( oFont )
       oEdit:Refresh()
       HDTheme():oFont := oFont
       HDTheme():lChanged := .T.
   ENDIF
Return Nil


Static Function EditColors()
Local oDlg, i, j, temp, oBtn2
Local cText := "// The code sample" + cNewLine + ;
               "do while ++nItem < 120"+ cNewLine + ;
               "  if aItems[ nItem ] == 'scheme'"+ cNewLine + ;
               "    nFactor := 22.5"+ cNewLine + ;
               "  endif"

Memvar oBrw, oEditC, oSayT, oCheckB, oCheckI, oSayB, aSchemes
Memvar nScheme, nType, oTheme, cScheme
Private oBrw, oEditC, oSayT, oCheckB, oCheckI, oSayB, aSchemes := Array( Len( HDTheme():aThemes ) )
Private nScheme, nType := 2, oTheme := HDTheme():New(), cScheme := ""

   FOR i := 1 TO Len( aSchemes )
      aSchemes[i] := { HDTheme():aThemes[i]:name, HDTheme():aThemes[i]:normal, ;
          HDTheme():aThemes[i]:command, HDTheme():aThemes[i]:comment,          ;
          HDTheme():aThemes[i]:quote, HDTheme():aThemes[i]:number }
   NEXT

   INIT DIALOG oDlg TITLE "Color schemes" ;
      AT 200,140 SIZE 440,355  FONT oDesigner:oMainWnd:oFont ;
      ON INIT {||UpdSample()}

   @ 10,10 BUTTON "Delete scheme" SIZE 110,30 ON CLICK {||UpdSample(1)}

   @ 140,10 BROWSE oBrw ARRAY SIZE 130,80
   oBrw:bPosChanged := {||nScheme:=oBrw:nCurrent,UpdSample()}
   oBrw:aArray := aSchemes
   oBrw:AddColumn( HColumn():New( ,{|v,o|o:aArray[o:nCurrent,1]},"C",15,0,.T. ) )
   oBrw:lDispHead := .F.
   nScheme := oBrw:nCurrent := oBrw:rowPos := HDTheme():nSelected

   @ 290,10 GET cScheme SIZE 110,26
   @ 290,40 BUTTON "Add scheme" SIZE 110,30 ON CLICK {||UpdSample(2)}

   @ 10,120 GROUPBOX "" SIZE 140,140
   RADIOGROUP
   @ 20,130 RADIOBUTTON "Normal" SIZE 120,24 ON CLICK {||UpdSample(,2)}
   @ 20,154 RADIOBUTTON "Keyword" SIZE 120,24 ON CLICK {||UpdSample(,3)}
   @ 20,178 RADIOBUTTON "Comment" SIZE 120,24 ON CLICK {||UpdSample(,4)}
   @ 20,202 RADIOBUTTON "Quote" SIZE 120,24 ON CLICK {||UpdSample(,5)}
   @ 20,226 RADIOBUTTON "Number" SIZE 120,24 ON CLICK {||UpdSample(,6)}
   END RADIOGROUP SELECTED 1

   @ 170,110 GROUPBOX "" SIZE 250,75
   @ 180,127 SAY "Text color" SIZE 100,24
   @ 280,125 SAY oSayT CAPTION "" SIZE 24,24
   @ 305,127 BUTTON "..." SIZE 20,20 ON CLICK {||Iif((temp:=Hwg_ChooseColor(aSchemes[nScheme,nType][1],.F.))!=Nil,(aSchemes[nScheme,nType][1]:=temp,UpdSample()),.F.)}
   @ 180,152 SAY "Background" SIZE 100,24
   @ 280,150 SAY oSayB CAPTION "" SIZE 24,24
   @ 305,152 BUTTON oBtn2 CAPTION "..." SIZE 20,20 ON CLICK {||Iif((temp:=Hwg_ChooseColor(aSchemes[nScheme,nType][2],.F.))!=Nil,(aSchemes[nScheme,nType][2]:=temp,UpdSample()),.F.)}
   @ 350,125 CHECKBOX oCheckB CAPTION "Bold" SIZE 60,24 ON CLICK {||aSchemes[nScheme,nType][3]:=oCheckB:Value,UpdSample(),.t.}
   @ 350,150 CHECKBOX oCheckI CAPTION "Italic" SIZE 60,24 ON CLICK {||aSchemes[nScheme,nType][4]:=oCheckI:Value,UpdSample(),.t.}

   oEditC := HCEdit():New( ,,, 170, 190, 250, 100 )
   oEditC:HighLighter( HDTheme():oHili )
   oEditC:SetText( cText )

   @ 60,310 BUTTON "Ok" SIZE 100,32 ON CLICK {||oDlg:lResult:=.T.,hwg_EndDialog()}
   @ 200,310 BUTTON "Cancel" ID IDCANCEL SIZE 100,32

   oDlg:Activate()

   IF oDlg:lResult
      FOR i := 1 TO Len( HDTheme():aThemes )
         IF Ascan( aSchemes,{|a|Lower(a[1])==Lower(HDTheme():aThemes[i]:name)} ) == 0
            Adel( HDTheme():aThemes,i )
            Asize( HDTheme():aThemes,Len(HDTheme():aThemes)-1 )
         ENDIF
      NEXT
      FOR i := 1 TO Len( aSchemes )
         j := Ascan( HDTheme():aThemes,{|o|Lower(o:name)==Lower(aSchemes[i,1])} )
         IF j == 0
            HDTheme():Add( aSchemes[i,1] )
            j := Len( HDTheme():aThemes )
         ENDIF
         HDTheme():aThemes[j]:normal  := aSchemes[i,2]
         HDTheme():aThemes[j]:command := aSchemes[i,3]
         HDTheme():aThemes[j]:comment := aSchemes[i,4]
         HDTheme():aThemes[j]:quote   := aSchemes[i,5]
         HDTheme():aThemes[j]:number  := aSchemes[i,6]
      NEXT
      HDTheme():lChanged := .T.
   ENDIF

Return Nil

Static Function UpdSample( nAction, nT )
Local oFont
Memvar oBrw, oEditC, oSayT, oCheckB, oCheckI, oSayB, aSchemes
Memvar nScheme, nType, oTheme, cScheme

   IF nAction != Nil
      IF nAction == 1
         IF Len( aSchemes ) == 1
            hwg_Msgstop( "Can't delete the only theme !", "Designer" )
            Return Nil
         ENDIF
         IF hwg_Msgyesno( "Really delete the '" + aSchemes[nScheme,1] + "' theme ?", "Designer" )
            Adel( aSchemes,nScheme )
            Asize( aSchemes,Len(aSchemes)-1 )
            nScheme := oBrw:nCurrent := oBrw:rowPos := 1
            oBrw:Refresh()
         ELSE
            Return Nil
         ENDIF
      ELSEIF nAction == 2
         IF Empty( cScheme )
            hwg_Msgstop( "You must specify the theme name !", "Designer" )
            Return Nil
         ENDIF
         IF Ascan( aSchemes,{|a|Lower(a[1])==Lower(cScheme)} ) == 0
            Aadd( aSchemes,{ cScheme, AClone(aSchemes[nScheme,2]), ;
                AClone(aSchemes[nScheme,3]), AClone(aSchemes[nScheme,4]), ;
                AClone(aSchemes[nScheme,5]), AClone(aSchemes[nScheme,6]) } )
            oBrw:Refresh()
         ELSE
            hwg_Msgstop( "The " + cScheme + " theme exists already !", "Designer" )
            Return Nil
         ENDIF
      ENDIF
   ENDIF

   IF nT != Nil
      nType := nT
   ENDIF
   oSayT:SetColor( ,aSchemes[nScheme,nType][1],.T. )
   oSayB:SetColor( ,aSchemes[nScheme,nType][2],.T. )
   oCheckB:Value := aSchemes[nScheme,nType][3]
   oCheckI:Value := aSchemes[nScheme,nType][4]

   oTheme:normal  := aSchemes[nScheme,2]
   oTheme:command := aSchemes[nScheme,3]
   oTheme:comment := aSchemes[nScheme,4]
   oTheme:quote   := aSchemes[nScheme,5]
   oTheme:number  := aSchemes[nScheme,6]

   IF nT == Nil
      oFont := oEditC:oFont
      oEditC:tColor := oTheme:normal[1]
      oEditC:bColorCur := oEditC:bColor := oTheme:normal[2]

      oEditC:SetHili( HILIGHT_KEYW, Iif( oTheme:command[3].OR.oTheme:command[4], oFont:SetFontStyle(oTheme:command[3],,oTheme:command[4]),-1 ), oTheme:command[1], oTheme:command[2] )
      oEditC:SetHili( HILIGHT_QUOTE, Iif( oTheme:quote[3].OR.oTheme:quote[4], oFont:SetFontStyle(oTheme:quote[3],,oTheme:quote[4]), -1 ), oTheme:quote[1], oTheme:quote[2] )
      oEditC:SetHili( HILIGHT_COMM, Iif( oTheme:comment[3].OR.oTheme:comment[4], oFont:SetFontStyle(oTheme:comment[3],,oTheme:comment[4]), -1 ), oTheme:comment[1], oTheme:comment[2] )

      oEditC:Refresh()
   ENDIF
Return Nil
