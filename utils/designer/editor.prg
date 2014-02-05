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

Static oDlg, oEdit, cIniName
Static nTextLength

Memvar oDesigner, cCurDir

CLASS HDTheme

   CLASS VAR aThemes  INIT {}
   CLASS VAR nSelected
   CLASS VAR oFont
   CLASS VAR lChanged INIT .F.
   CLASS VAR aKeyWords
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
      ELSEIF oOptDesc:aItems[i]:title == "keywords"
         HDTheme():aKeyWords := hwg_hfrm_Str2Arr( oOptDesc:aItems[i]:aItems[1] )
      ELSEIF oOptDesc:aItems[i]:title == "themes"
         cTheme := oOptDesc:aItems[i]:GetAttribute( "selected" )
         FOR j := 1 TO Len( oOptDesc:aItems[i]:aItems )
            oThemeXML := oOptDesc:aItems[i]:aItems[j]
            oTheme := HDTheme():Add( oThemeXML:GetAttribute( "name" ) )
            IF oTheme:name == cTheme
               HDTheme():nSelected := j
            ENDIF
            FOR j1 := 1 TO Len( oThemeXML:aItems )
               arr := { oThemeXML:aItems[j1]:GetAttribute("tcolor"), ;
                        oThemeXML:aItems[j1]:GetAttribute("bcolor"), ;
                        oThemeXML:aItems[j1]:GetAttribute("bold"),   ;
                        oThemeXML:aItems[j1]:GetAttribute("italic") }
               IF arr[1] != Nil
                  arr[1] := Val( arr[1] )
               ENDIF
               IF arr[2] != Nil
                  arr[2] := Val( arr[2] )
               ENDIF
               arr[3] := ( arr[3] != Nil )
               arr[4] := ( arr[4] != Nil )
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

         aAttr := { {"tcolor",Ltrim(Str(HDTheme():aThemes[i]:command[1]))} }
         IF HDTheme():aThemes[i]:command[3]
            Aadd( aAttr, { "bold","True" } )
         ENDIF
         IF HDTheme():aThemes[i]:command[4]
            Aadd( aAttr, { "italic","True" } )
         ENDIF
         oThemeDesc:Add( HXMLNode():New( "command",HBXML_TYPE_SINGLE,aAttr ) )

         aAttr := { {"tcolor",Ltrim(Str(HDTheme():aThemes[i]:comment[1]))} }
         IF HDTheme():aThemes[i]:comment[3]
            Aadd( aAttr, { "bold","True" } )
         ENDIF
         IF HDTheme():aThemes[i]:comment[4]
            Aadd( aAttr, { "italic","True" } )
         ENDIF
         oThemeDesc:Add( HXMLNode():New( "comment",HBXML_TYPE_SINGLE,aAttr ) )

         aAttr := { {"tcolor",Ltrim(Str(HDTheme():aThemes[i]:quote[1]))} }
         IF HDTheme():aThemes[i]:quote[3]
            Aadd( aAttr, { "bold","True" } )
         ENDIF
         IF HDTheme():aThemes[i]:quote[4]
            Aadd( aAttr, { "italic","True" } )
         ENDIF
         oThemeDesc:Add( HXMLNode():New( "quote",HBXML_TYPE_SINGLE,aAttr ) )

         aAttr := { {"tcolor",Ltrim(Str(HDTheme():aThemes[i]:number[1]))} }
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
Local i, lRes := .F.
Local oFont := HDTheme():oFont
Local cParamString

   i := Ascan( oDesigner:aMethDef, {|a|a[1]==Lower(cMethName)} )
   cParamString := Iif( i == 0, "", oDesigner:aMethDef[i,2] )
   INIT DIALOG oDlg TITLE "Edit '"+cMethName+"' method"          ;
      AT 100,240  SIZE 600,300  FONT oDesigner:oMainWnd:oFont    ;
      STYLE WS_POPUP+WS_VISIBLE+WS_CAPTION+WS_SYSMENU+WS_MAXIMIZEBOX+WS_SIZEBOX ;
      ON INIT {||hwg_Movewindow(oDlg:handle,100,240,600,310)}        ;
      ON EXIT {||Iif(lRes:=(oEdit:lChanged.AND.hwg_Msgyesno("Code was changed! Save it?", "Designer")),cMethod:=oEdit:GetText(),.F.),.T.}

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
      MENUITEM "&Parameters" ACTION Iif(!Empty(cParamString).and.Upper(Left(oEdit:Gettext(),10))!="PARAMETERS",(editShow("Parameters "+cParamString+Chr(10)+oEdit:Gettext()),oEdit:lChanged:=.T.),.F.)
      MENUITEM "&Exit" ACTION oDlg:Close()
   ENDMENU

   @ 0,0 RICHEDIT oEdit TEXT cMethod SIZE 400,oDlg:nHeight            ;
       STYLE ES_MULTILINE+ES_AUTOVSCROLL+ES_AUTOHSCROLL+ES_WANTRETURN ;
       ON INIT {||ChangeTheme( HDTheme():nSelected )}                 ;
       ON GETFOCUS {||Iif(oEdit:cargo,(hwg_Sendmessage(oEdit:handle,EM_SETSEL,0,0),oEdit:cargo:=.F.),.F.)} ;
       ON SIZE {|o,x,y|o:Move(,,x,y)}                                 ;
       FONT oFont
   oEdit:cargo := .T.

   ACTIVATE DIALOG oDlg

   IF lRes
      Return cMethod
   ENDIF
Return Nil

Static Function ChangeTheme( nTheme )

   IF HDTheme():nSelected != Nil
      hwg_Checkmenuitem( oDlg:handle,1020+HDTheme():nSelected, .F. )
   ENDIF
   hwg_Checkmenuitem( oDlg:handle,1020+nTheme, .T. )
   HDTheme():nSelected := nTheme
   editShow( ,.T. )
Return Nil

Static Function editChgFont()
Local oFont

   IF ( oFont := HFont():Select( oEdit:oFont ) ) != Nil
       oEdit:oFont := oFont
       hwg_Setwindowfont( oEdit:handle,oFont:handle )
       editShow( ,.T. )
       HDTheme():oFont := oFont
       HDTheme():lChanged := .T.
   ENDIF
Return Nil

Static Function editShow( cText,lRedraw )
Local arrHi, oTheme := HDTheme():aThemes[HDTheme():nSelected]

   IF lRedraw != Nil .AND. lRedraw
      // cText := oEdit:Gettext()
      nTextLength := hwg_Sendmessage( oEdit:handle, WM_GETTEXTLENGTH, 0, 0 ) + 1
      cText := hwg_Re_gettextrange( oEdit:handle,1,nTextLength )
   ELSE
      IF cText == Nil
         cText := oEdit:title
      ENDIF
      nTextLength := Len( cText )
   ENDIF
   hwg_Sendmessage( oEdit:handle, EM_SETEVENTMASK, 0, 0 )
   hwg_Re_setdefault( oEdit:handle,oTheme:normal[1],oEdit:oFont:name,,oTheme:normal[3],oTheme:normal[4],,oEdit:oFont:charset )
   hwg_Sendmessage( oEdit:handle,EM_SETBKGNDCOLOR,0,oTheme:normal[2] )
   oEdit:SetText( cText )
   cText := hwg_Re_gettextrange( oEdit:handle,1,nTextLength )
   IF !Empty( arrHi := CreateHiLight( cText ) )
      hwg_Re_setcharformat( oEdit:handle,arrHi )
   ENDIF
   hwg_Sendmessage( oEdit:handle, EM_SETEVENTMASK, 0, ENM_CHANGE + ENM_SELCHANGE )
   oEdit:oParent:AddEvent( EN_CHANGE,oEdit:id,{||EnChange(2)} )

Return Nil

Static Function EnChange( nEvent )
Local pos := hwg_Sendmessage( oEdit:handle, EM_GETSEL, 0, 0 )
Local nLength, pos1 := hwg_Loword(pos)+1, pos2 := hwg_Hiword(pos)+1
Local cBuffer, nLine, arr := {}, nLinePos
Local oTheme := HDTheme():aThemes[HDTheme():nSelected]

   IF nEvent == 1        // EN_SELCHANGE
      //nEditPos1 := pos1
      //nEditPos2 := pos2
   ELSE                  // EN_CHANGE
      hwg_Sendmessage( oEdit:handle, EM_SETEVENTMASK, 0, 0 )
      nLength := hwg_Sendmessage( oEdit:handle, WM_GETTEXTLENGTH, 0, 0 )
      IF nLength - nTextLength > 2 
      ELSE
         nLine := hwg_Sendmessage( oEdit:handle, EM_LINEFROMCHAR, -1, 0 )
         cBuffer := hwg_Re_getline( oEdit:handle,nLine )
         nLinePos := hwg_Sendmessage( oEdit:handle, EM_LINEINDEX, nLine, 0 ) + 1
         Aadd( arr, { nLinePos,nLinePos+Len(cBuffer), ;
            oTheme:normal[1],,,oTheme:normal[3],oTheme:normal[4], } )
         HiLightString( cBuffer, arr, nLinePos )
         IF !Empty( arr )
            hwg_Re_setcharformat( oEdit:handle,arr )
         ENDIF
      ENDIF
      IF nTextLength != nLength
         oEdit:lChanged := .T.
      ENDIF
      nTextLength := nLength
      hwg_Sendmessage( oEdit:handle, EM_SETEVENTMASK, 0, ENM_CHANGE + ENM_SELCHANGE )     
   ENDIF
Return Nil

Static Function CreateHilight( cText,oTheme )
Local arr := {}, stroka, nPos, nLinePos := 1

   DO WHILE .T.
      IF ( nPos := hb_At( Chr(10), cText, nLinePos ) ) != 0 .OR. ( nPos := hb_At( Chr(13), cText, nLinePos ) ) != 0
         HiLightString( SubStr( cText,nLinePos,nPos-nLinePos ), arr, nLinePos,oTheme )
         nLinePos := nPos + 1
      ELSE
         HiLightString( SubStr( cText,nLinePos ), arr, nLinePos,oTheme )
         EXIT
      ENDIF
   ENDDO
Return arr

Static Function HiLightString( stroka, arr, nLinePos, oTheme )
Local nStart, nPos := 1, sLen := Len( stroka ), cWord

   IF oTheme == Nil
      oTheme := HDTheme():aThemes[HDTheme():nSelected]
   ENDIF

   IF Left( Ltrim( stroka ), 2 ) == "//"
      Aadd( arr, { nLinePos,nLinePos+Len(stroka), ;
          oTheme:comment[1],,,oTheme:comment[3],oTheme:comment[4], } )
      Return arr
   ENDIF
   SET EXACT ON
   DO WHILE nPos < sLen
      cWord := NextWord( stroka,@nPos,@nStart )
      IF !Empty( cWord )
         IF Left( cWord,1 ) == '"' .OR. Left( cWord,1 ) == "'"
            Aadd( arr, { nLinePos+nStart-1,nLinePos+nPos-1, ;
               oTheme:quote[1],,,oTheme:quote[3],oTheme:quote[4], } )
         ELSEIF Ascan( HDTheme():aKeyWords,Upper(cWord) ) != 0
            Aadd( arr, { nLinePos+nStart-1,nLinePos+nPos-1, ;
               oTheme:command[1],,,oTheme:command[3],oTheme:command[4], } )
         ELSEIF IsDigit( cWord )
            Aadd( arr, { nLinePos+nStart-1,nLinePos+nPos-1, ;
               oTheme:number[1],,,oTheme:number[3],oTheme:number[4], } )
         ENDIF
      ENDIF
   ENDDO
   SET EXACT OFF

Return arr

Static Function EditColors()
Local oDlg, i, j, temp, oBtn2
Local cText := "// The code sample" + Chr(10) + ;
               "do while ++nItem < 120"+ Chr(10) + ;
               "  if aItems[ nItem ] == 'scheme'"+ Chr(10) + ;
               "    nFactor := 22.5"+ Chr(10) + ;
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
   @ 20,130 RADIOBUTTON "Normal" SIZE 120,24 ON CLICK {||nType:=2,UpdSample(),oBtn2:Show()}
   @ 20,154 RADIOBUTTON "Keyword" SIZE 120,24 ON CLICK {||nType:=3,UpdSample(),oBtn2:Hide()}
   @ 20,178 RADIOBUTTON "Comment" SIZE 120,24 ON CLICK {||nType:=4,UpdSample(),oBtn2:Hide()}
   @ 20,202 RADIOBUTTON "Quote" SIZE 120,24 ON CLICK {||nType:=5,UpdSample(),oBtn2:Hide()}
   @ 20,226 RADIOBUTTON "Number" SIZE 120,24 ON CLICK {||nType:=6,UpdSample(),oBtn2:Hide()}
   END RADIOGROUP SELECTED 1

   @ 170,110 GROUPBOX "" SIZE 250,75
   @ 180,127 SAY "Text color" SIZE 100,24
   @ 280,125 SAY oSayT CAPTION "" SIZE 24,24
   @ 305,127 BUTTON "..." SIZE 20,20 ON CLICK {||Iif((temp:=Hwg_ChooseColor(aSchemes[nScheme,nType][1],.F.))!=Nil,(aSchemes[nScheme,nType][1]:=temp,UpdSample()),.F.)}
   @ 180,152 SAY "Background" SIZE 100,24
   @ 280,150 SAY oSayB CAPTION "" SIZE 24,24
   @ 305,152 BUTTON oBtn2 CAPTION "..." SIZE 20,20 ON CLICK {||Iif((temp:=Hwg_ChooseColor(aSchemes[nScheme,nType][2],.F.))!=Nil,(aSchemes[nScheme,nType][2]:=temp,UpdSample()),.F.)}
   @ 350,125 CHECKBOX oCheckB CAPTION "Bold" SIZE 60,24 ON CLICK {||aSchemes[nScheme,nType][3]:=hwg_Isdlgbuttonchecked(oCheckB:oParent:handle,oCheckB:id),UpdSample(),.t.}
   @ 350,150 CHECKBOX oCheckI CAPTION "Italic" SIZE 60,24 ON CLICK {||aSchemes[nScheme,nType][4]:=hwg_Isdlgbuttonchecked(oCheckI:oParent:handle,oCheckI:id),UpdSample(),.t.}

   @ 170,190 RICHEDIT oEditC TEXT cText SIZE 250,100 STYLE ES_MULTILINE

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

Static Function UpdSample( nAction )
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

   oSayT:SetColor( ,aSchemes[nScheme,nType][1],.T. )
   oSayB:SetColor( ,aSchemes[nScheme,nType][2],.T. )
   hwg_Checkdlgbutton( oCheckB:oParent:handle,oCheckB:id,aSchemes[nScheme,nType][3] )
   hwg_Checkdlgbutton( oCheckI:oParent:handle,oCheckI:id,aSchemes[nScheme,nType][4] )

   oTheme:normal  := aSchemes[nScheme,2]
   oTheme:command := aSchemes[nScheme,3]
   oTheme:comment := aSchemes[nScheme,4]
   oTheme:quote   := aSchemes[nScheme,5]
   oTheme:number  := aSchemes[nScheme,6]
   hwg_Re_setdefault( oEditC:handle,oTheme:normal[1],,,oTheme:normal[3],oTheme:normal[4] )
   hwg_Sendmessage( oEditC:handle,EM_SETBKGNDCOLOR,0,oTheme:normal[2] )
   hwg_Re_setcharformat( oEditC:handle,CreateHiLight(oEditC:GetText(),oTheme) )
Return Nil

#pragma BEGINDUMP

   #include "hbapi.h"
   #include <windows.h>
   #include <string.h>

int At_Any( char* cFind, char* cStr, int* nPos)
{
   char c;
   int i;
   int iLen = strlen( cFind );

   while( ( c = *( cStr+(*nPos) ) ) != 0 )
   {
      for( i = 0; i < iLen; i ++ )
         if( c == *( cFind+i ) )
            break;
      if( i < iLen )
         break;
      (*nPos) ++;
   }

   return ( (c)? 1:0 );
}

HB_FUNC( NEXTWORD )
{
   char *cSep = " \t,.()[]+-/%";
   char * cStr  = hb_parc( 1 );
   char * ptr, * ptr1;
   int nPos = hb_parni( 2 ) - 1;

   ptr = cStr + nPos;
   while( *ptr && strchr( cSep,*ptr ) )
   {
      ptr++;
      nPos++;
   }
   if( *ptr == '\'' || *ptr == '\"' )
   {
      ptr1 = strchr( ptr+1,*ptr );
      if( ptr1 )
      {
         nPos = ptr1 - cStr + 1;
         hb_retclen( ptr,ptr1-ptr+1 );
      }
      else
      {
         nPos = strlen( cStr );
         hb_retc( ptr );
      }
   }
   else if( At_Any( cSep,cStr,&nPos ) )
      hb_retclen( ptr,nPos-(ptr-cStr) );
   else
      hb_retc( ptr );
   hb_storni( nPos+1,2 );
   hb_storni( ptr-cStr+1,3 );
}

#pragma ENDDUMP
