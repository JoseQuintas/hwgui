/*
 * $Id: editor.prg,v 1.6 2004-06-27 14:43:30 alkresin Exp $
 *
 * Designer
 * Simple code editor
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "HBClass.ch"
#include "windows.ch"
#include "guilib.ch"

#define ES_SAVESEL 0x00008000

Static oDlg, oEdit, cIniName
Static nTextLength

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

   METHOD New( name )  INLINE ( ::name:=name,Aadd(::aThemes,Self),Self )
ENDCLASS

Function LoadEdOptions( cFileName )
Local oIni := HXMLDoc():Read( cFileName )
Local i, j, j1, cTheme, oTheme, oThemeXML, arr

   cIniName := cFileName
   oOptDesc := oIni:aItems[1]
   FOR i := 1 TO Len( oOptDesc:aItems )
      IF oOptDesc:aItems[i]:title == "font"
         HDTheme():oFont := hfrm_FontFromxml( oOptDesc:aItems[i] )
      ELSEIF oOptDesc:aItems[i]:title == "keywords"
         HDTheme():aKeyWords := hfrm_Str2Arr( oOptDesc:aItems[i]:aItems[1] )
      ELSEIF oOptDesc:aItems[i]:title == "themes"
         cTheme := oOptDesc:aItems[i]:GetAttribute( "selected" )
         FOR j := 1 TO Len( oOptDesc:aItems[i]:aItems )
            oThemeXML := oOptDesc:aItems[i]:aItems[j]
            oTheme := HDTheme():New( oThemeXML:GetAttribute( "name" ) )
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

Function SaveEdOptions( oOptDesc )
Local oIni := HXMLDoc():Read( cCurDir+cIniName )
Local i, j, oNode, nStart

   oNode := oIni:aItems[1]
   nStart := 1
   IF oNode:Find( "font",@nStart ) == Nil
      oNode:Add( Font2XML( HDTheme():oFont ) )
   ELSE
      oNode:aItems[nStart] := Font2XML( HDTheme():oFont )
   ENDIF
   oIni:Save( cCurDir+cIniName )

Return Nil

Function EditMethod( cMethName, cMethod )
Local i, lRes := .T.
Local oFont := HDTheme():oFont
Local cParamString

   i := Ascan( aMethDef, {|a|a[1]==Lower(cMethName)} )
   cParamString := Iif( i == 0, "", aMethDef[i,2] )
   INIT DIALOG oDlg TITLE "Edit '"+cMethName+"' method" ;
      AT 300,240  SIZE 400,300  FONT oMainWnd:oFont            ;
      ON INIT {||MoveWindow(oDlg:handle,300,240,400,310)}

   MENU OF oDlg
      MENU TITLE "&Options"
         MENUITEM "&Font" ACTION editChgFont()
         MENU TITLE "&Select theme"
            FOR i := 1 TO Len( HDTheme():aThemes )
               Hwg_DefineMenuItem( HDTheme():aThemes[i]:name, 1020+i, &( "{||ChangeTheme("+LTrim(Str(i,2))+")}" ) )
            NEXT
         ENDMENU
      ENDMENU
      MENUITEM "&Parameters" ACTION Iif(!Empty(cParamString),editShow("Parameters "+cParamString+Chr(10)+oEdit:Gettext()),.F. )
   ENDMENU

   @ 0,0 RICHEDIT oEdit TEXT "" SIZE 400,oDlg:nHeight-45              ;
       STYLE ES_MULTILINE+ES_AUTOVSCROLL+ES_AUTOHSCROLL+ES_WANTRETURN ;
       ON SIZE {|o,x,y|o:Move(,,x,y-45)}                              ;
       ON INIT {||ChangeTheme( HDTheme():nSelected )}                 ;
       ON GETFOCUS {||Iif(oEdit:cargo,(SendMessage(oEdit:handle,EM_SETSEL,0,0),oEdit:cargo:=.F.),.F.)} ;
       FONT oFont
   oEdit:cargo := .T.

   // oEdit:oParent:AddEvent( EN_SELCHANGE,oEdit:id,{||EnChange(1)},.T. )

   oEdit:title := cMethod  

   @ 60,265 BUTTON "Ok" SIZE 100, 32     ;
       ON SIZE {|o,x,y|o:Move(,y-35,,)}  ;
       ON CLICK {||cMethod:=oEdit:GetText(),lRes:=.T.,EndDialog()}
   @ 240,265 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32 ;
       ON SIZE {|o,x,y|o:Move(,y-35,,)}

   ACTIVATE DIALOG oDlg

   IF lRes
      Return cMethod
   ENDIF
Return Nil

Function ChangeTheme( nTheme )

   IF HDTheme():nSelected != Nil
      CheckMenuItem( oDlg:handle,1020+HDTheme():nSelected, .F. )
   ENDIF
   CheckMenuItem( oDlg:handle,1020+nTheme, .T. )
   HDTheme():nSelected := nTheme
   editShow( ,.T. )
Return Nil

Static Function editChgFont()
Local oFont

   IF ( oFont := HFont():Select( oEdit:oFont ) ) != Nil
       oEdit:oFont := oFont
       SetWindowFont( oEdit:handle,oFont:handle )
       editShow( ,.T. )
       // RedrawWindow( oEdit:handle, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW )
       HDTheme():oFont := oFont
       HDTheme():lChanged := .T.
   ENDIF
Return Nil

// re_SetDefault( hCtrl, nColor, cName, nHeight, nCharset )
// re_SetCharFormat( hCtrl, n1, n2, nColor, cName, nHeight, lBold, lItalic, lUnderline )

Static Function editShow( cText,lRedraw )
Local arrHi, oTheme := HDTheme():aThemes[HDTheme():nSelected]

   IF lRedraw != Nil .AND. lRedraw
      cText := oEdit:Gettext()
   ELSE
      IF cText == Nil
         cText := oEdit:title
      ENDIF
   ENDIF
   SendMessage( oEdit:handle, EM_SETEVENTMASK, 0, 0 )
   oEdit:SetText( cText )
   nTextLength := Len( cText )
   re_SetDefault( oEdit:handle,oTheme:normal[1],,,oTheme:normal[3],oTheme:normal[4] )
   SendMessage( oEdit:handle,EM_SETBKGNDCOLOR,0,oTheme:normal[2] )
   IF !Empty( arrHi := CreateHiLight( cText ) )
      /*
      writelog( "re_SetCharFormat "+Str(Len(arrhi)) )
      for i := 1 to len( arrhi )
         writelog( str(arrhi[i,1])+" "+str(arrhi[i,2])+": "+str(arrhi[i,3])+iif(arrhi[i,6]!=Nil.AND.arrhi[i,6]," T","") )
      next
      */
      re_SetCharFormat( oEdit:handle,arrHi )
   ENDIF
   SendMessage( oEdit:handle, EM_SETEVENTMASK, 0, ENM_CHANGE + ENM_SELCHANGE )
   oEdit:oParent:AddEvent( EN_CHANGE,oEdit:id,{||EnChange(2)} )

Return Nil

Static Function EnChange( nEvent )
Local pos := SendMessage( oEdit:handle, EM_GETSEL, 0, 0 )
Local nLength, pos1 := Loword(pos)+1, pos2 := Hiword(pos)+1
Local cBuffer, nLine, arr := {}, nLinePos
Local oTheme := HDTheme():aThemes[HDTheme():nSelected]

   IF nEvent == 1        // EN_SELCHANGE
      nEditPos1 := pos1
      nEditPos2 := pos2
   ELSE                  // EN_CHANGE
      SendMessage( oEdit:handle, EM_SETEVENTMASK, 0, 0 )
      nLength := SendMessage( oEdit:handle, WM_GETTEXTLENGTH, 0, 0 )
      IF nLength - nTextLength > 2 
         // writelog( "1: "+str(nLength,5)+" "+str(nTextLength,5) )
      ELSE
         nLine := SendMessage( oEdit:handle, EM_LINEFROMCHAR, pos1, 0 )
         cBuffer := re_getline( oEdit:handle,nLine )
         // writelog( str(nline)+" "+Str(Len(cBuffer))+"/"+cBuffer )
         nLinePos := SendMessage( oEdit:handle, EM_LINEINDEX, nLine, 0 ) + 1
         Aadd( arr, { nLinePos,nLinePos+Len(cBuffer), ;
            oTheme:normal[1],,,oTheme:normal[3],oTheme:normal[4], } )
         HiLightString( cBuffer, arr, nLinePos )
         /*
         writelog( "re_SetCharFormat "+Str(Len(arr)) )
         for i := 1 to len( arr )
            writelog( str(arr[i,1])+" "+str(arr[i,2])+": "+str(arr[i,3])+iif(arr[i,6]!=Nil.AND.arr[i,6]," T","") )
         next
         */
         IF !Empty( arr )
            re_SetCharFormat( oEdit:handle,arr )
         ENDIF
      ENDIF
      IF nTextLength != nLength
         oEdit:lChanged := .T.
      ENDIF
      nTextLength := nLength
      SendMessage( oEdit:handle, EM_SETEVENTMASK, 0, ENM_CHANGE + ENM_SELCHANGE )     
   ENDIF
   // writelog( "EnChange "+str(pos1)+" "+str(pos2) ) // +" Length: "+str(nLength) )
Return Nil

Static Function CreateHilight( cText )
Local arr := {}, stroka, nPos, nLinePos := 1

   DO WHILE .T.
      IF ( nPos := At( Chr(10), cText, nLinePos ) ) != 0
         HiLightString( SubStr( cText,nLinePos,nPos-nLinePos ), arr, nLinePos )
         nLinePos := nPos + 1
      ELSE
         HiLightString( SubStr( cText,nLinePos ), arr, nLinePos )
         EXIT
      ENDIF
   ENDDO
Return arr

Static Function HiLightString( stroka, arr, nLinePos )
Local nStart, nPos := 1, sLen := Len( stroka ), cWord
Local oTheme := HDTheme():aThemes[HDTheme():nSelected]

   IF Left( Ltrim( stroka ), 2 ) == "//"
      Aadd( arr, { nLinePos,nLinePos+Len(stroka), ;
          oTheme:comment[1],,,oTheme:comment[3],oTheme:comment[4], } )
      Return arr
   ENDIF
   SET EXACT ON
   DO WHILE nPos < sLen
      cWord := NextWord( stroka,@nPos,@nStart )
      // writelog( "-->"+str(nStart)+" "+str(nPos)+" "+str(len(cword))+" "+ str(asc(cword)))
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
