/*
 * $Id: editor.prg,v 1.3 2004-06-24 05:44:36 alkresin Exp $
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

Static oDlg, oEdit

CLASS HDTheme

   CLASS VAR aThemes  INIT {}
   CLASS VAR nSelected
   CLASS VAR oFont
   CLASS VAR lChanged INIT .F.
   DATA name
   DATA normal
   DATA command
   DATA comment
   DATA quote
   DATA number

   METHOD New( name )  INLINE ( ::name:=name,Aadd(::aThemes,Self),Self )
ENDCLASS

Function LoadEdOptions( oOptDesc )
Local i, j, j1, cTheme, oTheme, oThemeXML, arr

   FOR i := 1 TO Len( oOptDesc:aItems )
      IF oOptDesc:aItems[i]:title == "font"
         HDTheme():oFont := FontFromXML( oOptDesc:aItems[i] )
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
Local oIni := HXMLDoc():Read( "Designer.iml" )
Local i, j, oNode, nStart

   FOR i := 1 TO Len( oIni:aItems[1]:aItems )
      oNode := oIni:aItems[1]:aItems[i]
      IF oNode:title == "editor"
         nStart := 1
         IF oNode:Find( "font",@nStart ) == Nil
            oNode:Add( Font2XML( HDTheme():oFont ) )
         ELSE
            oNode:aItems[nStart] := Font2XML( HDTheme():oFont )
         ENDIF
      ENDIF
   NEXT
   oIni:Save( "Designer.iml" )

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
       ON GETFOCUS {||SendMessage(oEdit:handle,EM_SETSEL,0,0)}        ;
       FONT oFont

   // oEdit:oParent:AddEvent( EN_CHANGE,oEdit:id,{|o,id|EnChange(o,id,2)} )
   // oEdit:oParent:AddEvent( EN_SELCHANGE,oEdit:id,{|o,id|EnChange(o,id,1)},.T. )

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
   editShow()
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

// Just to remind:
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
   re_SetDefault( oEdit:handle,Val(oTheme:normal[1]) )
   SendMessage( oEdit:handle,EM_SETBKGNDCOLOR,0,Val(oTheme:normal[2]) )
   /*
   IF !Empty( arrHi := CreateHiLight( arr[1],aRules  ) )
      re_SetCharFormat( oEditNote:handle,arrHi )
   ENDIF
   */
   SendMessage( oEdit:handle, EM_SETEVENTMASK, 0, ENM_CHANGE + ENM_SELCHANGE )

Return Nil

Static Function EnChange( o,id,nEvent )
Local pos := SendMessage( oEditNote:handle, EM_GETSEL, 0, 0 )
Local nLength, pos1 := Loword(pos)+1, pos2 := Hiword(pos)+1
Local cBuffer, nStart, nPos, nAdd:=0, aWords[3,3], arrHi, i

   IF nEvent == 1        // EN_SELCHANGE
      nEditPos1 := pos1
      nEditPos2 := pos2
   ELSE                  // EN_CHANGE
      SendMessage( oEditNote:handle, EM_SETEVENTMASK, 0, 0 )
      nLength := SendMessage( oEditNote:handle, WM_GETTEXTLENGTH, 0, 0 )
      IF nLength - nTextLength > 2 
         // writelog( "1: "+str(nLength,5)+" "+str(nTextLength,5) )
      ELSE
         nPos := Max( pos1,1 )
         cBuffer := re_GetTextRange( oEditNote:handle, Max( nPos-80,1 ), nPos+80 )
         IF nPos > 81
            nAdd := nPos - 81
            nPos := 81
         ENDIF
         // writelog( "2: "+str(nLength,5)+" "+str(nTextLength,5)+" "+str(nPos,5)+" "+str(nAdd,5) )
         aWords[2,3] := ThisWord( cBuffer,@nPos,@nStart )
         aWords[2,1] := nStart
         aWords[2,2] := nPos
         IF nStart > 3
            nPos := nStart - 1
            aWords[1,3] := PrevWord( cBuffer,@nPos,@nStart )
            aWords[1,1] := nStart
            aWords[1,2] := nPos
         ELSE
            aWords[1,1] := aWords[1,2] := -1
         ENDIF
         nPos := aWords[2,2]
         aWords[3,3] := NextWord( cBuffer,@nPos,@nStart )
         aWords[3,1] := nStart
         aWords[3,2] := nPos
         re_SetCharFormat( oEditNote:handle,Iif(aWords[1,1]<0,aWords[2,1],aWords[1,1])+nAdd,nPos+nAdd,aNoteClr[1],,,.F.,.F.,.F. )
         // writelog( str(aWords[1,1],4)+str(nPos,4)+" "+str(nAdd,4) )
         arrhi := {}
         FOR i := 1 TO 3
            IF aWords[i,1] >= 0
               // writelog( str(aWords[i,1],4)+str(aWords[i,2],4)+" "+aWords[i,3] )
            ENDIF
            IF aWords[i,1] >= 0 .AND. Eval( aRules[1,1],aWords[i,3] )
               Aadd( arrhi, { aWords[i,1]+nAdd,aWords[i,2]+nAdd,aRules[1,2],aRules[1,3],aRules[1,4],aRules[1,5],aRules[1,6],aRules[1,7]} )
            ENDIF
         NEXT
         IF !Empty( arrHi )
            re_SetCharFormat( oEditNote:handle,arrHi )
         ENDIF
      ENDIF
      IF nTextLength != nLength
         oEditNote:lChanged := .T.
      ENDIF
      nTextLength := nLength
      SendMessage( oEditNote:handle, EM_SETEVENTMASK, 0, ENM_CHANGE + ENM_SELCHANGE )     
   ENDIF
   // writelog( "EnChange "+str(pos1)+" "+str(pos2) ) // +" Length: "+str(nLength) )
Return Nil

Static Function CreateHiLight( stroka,aR  )
Local arr := {}, i, nRules := Len( aR )
Local nStart, nPos := 1, sLen := Len( stroka ), cWord

   DO WHILE nPos < sLen
      cWord := NextWord( stroka,@nPos,@nStart )
      FOR i := 1 TO nRules
         IF Eval( aR[i,1],cWord )
            Aadd( arr, { nStart,nPos,aR[i,2],aR[i,3],aR[i,4],aR[i,5],aR[i,6],aR[i,7]} )
            EXIT
         ENDIF
      NEXT
   ENDDO

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
   char *cSep = " \t\n\r";
   char * cStr  = hb_parc( 1 );
   char * ptr;
   int nPos = hb_parni( 2 ) - 1;

   ptr = cStr + nPos;
   while( *ptr && ( *ptr == cSep[0] || *ptr == cSep[1] || *ptr == cSep[2] || *ptr == cSep[3] ) )
   {
      ptr++;
      nPos++;
   }
   if( At_Any( cSep,cStr,&nPos ) )
      hb_retclen( ptr,nPos-(ptr-cStr) );
   else
      hb_retc( ptr );
   hb_storni( nPos+1,2 );
   hb_storni( ptr-cStr+1,3 );
}

HB_FUNC( THISWORD )
{
   char *cSep = " \t\n\r";
   char * cStr  = hb_parc( 1 );
   char * ptr;
   int nPos = hb_parni( 2 ) - 1;

   ptr = cStr + nPos;
   while( ptr>cStr && *ptr != cSep[0] && *ptr != cSep[1] && *ptr != cSep[2] && *ptr != cSep[3] )
   {
      ptr--;
      nPos--;
   }
   if( *ptr == cSep[0] || *ptr == cSep[1] || *ptr == cSep[2] || *ptr == cSep[3] )
   {
      ptr++;
      nPos++;
   }
   if( At_Any( cSep,cStr,&nPos ) )
      hb_retclen( ptr,nPos-(ptr-cStr) );
   else
      hb_retc( ptr );
   hb_storni( nPos+1,2 );
   hb_storni( ptr-cStr+1,3 );
}

HB_FUNC( PREVWORD )
{
   char *cSep = " \t\n\r";
   char * cStr  = hb_parc( 1 );
   char * ptr;
   int nPos = hb_parni( 2 ) - 1;

   ptr = cStr + nPos;
   while( ptr>cStr && ( *ptr == cSep[0] || *ptr == cSep[1] || *ptr == cSep[2] || *ptr == cSep[3] ) )
   {
      ptr--;
      nPos--;
   }
   while( ptr>cStr && *ptr != cSep[0] && *ptr != cSep[1] && *ptr != cSep[2] && *ptr != cSep[3] )
   {
      ptr--;
      nPos--;
   }
   if( *ptr == cSep[0] || *ptr == cSep[1] || *ptr == cSep[2] || *ptr == cSep[3] )
   {
      ptr++;
      nPos++;
   }
   if( At_Any( cSep,cStr,&nPos ) )
      hb_retclen( ptr,nPos-(ptr-cStr) );
   else
      hb_retc( ptr );
   hb_storni( nPos+1,2 );
   hb_storni( ptr-cStr+1,3 );
}

#pragma ENDDUMP
