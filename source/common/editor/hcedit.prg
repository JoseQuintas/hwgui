/*
 * $Id$
 */

/*
 * HWGUI - Harbour Win32 GUI library source code:
 * The Edit control
 *
 * Copyright 2013 Alexander Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version, with one exception:
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA (or visit the web site http://www.gnu.org/).
 *
 * As a special exception, the Harbour Project gives permission for
 * additional uses of the text contained in its release of Harbour.
 *
 * The exception is that, if you link the Harbour libraries with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the Harbour library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the Harbour
 * Project under the name Harbour.  If you copy code from other
 * Harbour Project or Free Software Foundation releases into a copy of
 * Harbour, as the General Public License permits, the exception does
 * not apply to the code that you add in this way.  To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for Harbour, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 *
 */

#include "hbclass.ch"
#include "hwgui.ch"
#include "hxml.ch"

#define WM_MOUSEACTIVATE    33  // 0x0021
#define MA_ACTIVATE          1

#define P_LENGTH             2
#define P_X                  1
#define P_Y                  2

#define SETC_COORS           1
#define SETC_RIGHT           2
#define SETC_LEFT            3
#define SETC_XY              4
#define SETC_POS             5

#define AL_LENGTH            5
#define AL_X1                1
#define AL_Y1                2
#define AL_X2                3
#define AL_Y2                4
#define AL_NCHARS            5

#define X_FIRST             -1
#define X_CURR              -2
#define X_LAST              -3

#define HILIGHT_GROUPS  4
#define HILIGHT_KEYW    1
#define HILIGHT_FUNC    2
#define HILIGHT_QUOTE   3
#define HILIGHT_COMM    4

Static cNewLine := e"\r\n"

CLASS HCEdit INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"
   DATA   hEdit
   DATA   cFileName
   DATA   aText, nTextLen
   DATA   aDop, nDopChecked

   DATA   lShowNumbers INIT .F.
   DATA   lReadOnly    INIT .F.
   DATA   lUpdated     INIT .F.
   DATA   lInsert      INIT .T.

   DATA   nMarginL     INIT 2
   DATA   nMarginR     INIT 2
   DATA   n4Number     INIT 0
   DATA   n4Separ      INIT 0
   DATA   bColorCur    INIT 16449510
   DATA   tcolorSel    INIT 16777215
   DATA   bcolorSel    INIT 16744448

   DATA   nLineF       INIT 1
   DATA   nPosF        INIT 0
   DATA   aLines, nLines, nLineC, nPosC

   DATA   aFonts       INIT {}
   DATA   aFontsPrn    INIT {}
   DATA   nFontH
   DATA   oPenNum

   DATA   nCaret       INIT 0
   DATA   lChgCaret    INIT .F.
   DATA   bChangePos, bKeyDown, bClickDoub

   DATA   lMDown       INIT .F.
   DATA   nXPosM, nYPosM
   DATA   aPointC, aPointM1, aPointM2

   DATA   nTabLen      INIT 8
   DATA   lStripSpaces INIT .T.
   DATA   lWrap        INIT .F.
   DATA   lVScroll
   DATA   nClientWidth

   DATA   oHili, aHili
#ifdef __PLATFORM__UNIX
   DATA area
   DATA hScrollV  INIT Nil
   DATA hScrollH  INIT Nil
   DATA nScrollV  INIT 0
   DATA nScrollH  INIT 0
#endif

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont, ;
                  bInit,bSize,bPaint,tcolor,bcolor,bGfocus,bLfocus,lNoVScroll,lNoBorder )
   METHOD Open( cFileName )
   METHOD Activate()
   METHOD Init()
   METHOD SetHili( nGroup, oFont, tColor, bColor )
   METHOD onEvent( msg, wParam, lParam )
   METHOD Paint( lReal )
   METHOD PaintLine( hDC, yPos, nLine )
   METHOD MarkLine( nLine )
   METHOD End()
   METHOD SetText( cText )
   METHOD Save( cFileName )
   METHOD CloseText()
   METHOD AddFont( oFont, name, width, height , weight, ;
            CharSet, Italic, Underline, StrikeOut )
   METHOD SetFont( oFont )
   METHOD Line4Pos( yPos )
   METHOD SetCaretPos( nType, p1, p2 )
   METHOD onKeyDown( nKeyCode )
   METHOD PutChar( nKeyCode )
   METHOD LineDown()
   METHOD LineUp()
   METHOD PageDown()
   METHOD PageUp()
   METHOD Top()
   METHOD Bottom()
   METHOD Goto( nLine )
   METHOD onVScroll( wParam )
   METHOD PCopy( Psource, Pdest )
   METHOD PCmp( P1, P2 )
   METHOD GetText( P1, P2 )
   METHOD AddLine( nLine )
   METHOD DelLine( nLine )
   METHOD Refresh()
ENDCLASS

METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont, ;
               bInit,bSize,bPaint,tcolor,bcolor,bGfocus,bLfocus,lNoVScroll,lNoBorder )  CLASS HCEdit

   ::lVScroll := ( lNoVScroll == Nil .OR. !lNoVScroll )
   //lNoBorder := .T.
   nStyle := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), WS_CHILD+WS_VISIBLE+  ;
                    Iif(lNoBorder=Nil.OR.!lNoBorder,WS_BORDER,0)+          ;
                    Iif(::lVScroll,WS_VSCROLL,0) )

   ::Super:New( oWndParent,nId,nStyle,nLeft,nTop,Iif( nWidth==Nil,0,nWidth ), ;
             Iif( nHeight==Nil,0,nHeight ),oFont,bInit,bSize,bPaint,, ;
             Iif( tcolor==Nil,0,tcolor ),Iif( bcolor==Nil,16777215,bcolor ) )

   ::nClientWidth := ::nWidth

   IF ::oFont == Nil
      IF ::oParent:oFont == Nil
         PREPARE FONT ::oFont NAME "Courier New" WIDTH 0 HEIGHT -17
      ELSE
         ::oFont := ::oParent:oFont
      ENDIF
   ENDIF

   ::bGetFocus  := bGFocus
   ::bLostFocus := bLFocus

   ::aLines   := Array( 64,AL_LENGTH )
   ::aPointC  := Array( P_LENGTH )
   ::PCopy( ,::aPointC )
   ::aPointM1 := Array( P_LENGTH )
   ::PCopy( ,::aPointM1 )
   ::aPointM2 := Array( P_LENGTH )
   ::PCopy( ,::aPointM2 )

   ::nTextLen := ::nLines := 0
   ::aHili := Array( HILIGHT_GROUPS, 3 )

   hced_InitTextEdit()

   ::Activate()

Return Self

METHOD Open( cFileName ) CLASS HCEdit

   ::SetText( MemoRead( cFileName ) )
   ::cFileName := cFileName
Return Nil

METHOD Activate() CLASS HCEdit

   IF !Empty( ::oParent:handle )
#ifdef __PLATFORM__UNIX
      ::hEdit := hced_CreateTextEdit( Self )
#else
      ::hEdit := hced_CreateTextEdit( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
#endif
      ::handle := hced_GetHandle( ::hEdit )
      ::Init()

      ::AddFont( ::oFont )
      ::SetHili( HILIGHT_KEYW, ::oFont:SetFontStyle( .T. ), 8388608, ::bColor )  // 8388608
      ::SetHili( HILIGHT_FUNC, -1, 8388608, 16777215 )   // Blue on White // 8388608
      ::SetHili( HILIGHT_QUOTE, -1, 16711680, 16777215 )     // Green on White  // 4227072
      ::SetHili( HILIGHT_COMM, ::oFont:SetFontStyle( ,,.T. ), 32768, 16777215 )    // Green on White //4176740
      ::SetText()
      hced_Setcolor( ::hEdit, ::tcolor, ::bcolor )
      ::oPenNum := HPen():Add( , 2, 7135852 )
   ENDIF
Return Nil

METHOD Init() CLASS HCEdit

   IF !::lInit
      ::Super:Init()
#ifndef __PLATFORM__UNIX
      ::nHolder := 1
#endif
      hwg_Setwindowobject( ::handle,Self )
   ENDIF

Return Nil

METHOD SetHili( nGroup, oFont, tColor, bColor ) CLASS HCEdit

   IF nGroup <= HILIGHT_GROUPS
      IF oFont != Nil
         ::aHili[ nGroup,1 ] := Iif( Valtype( oFont ) == "O", ::AddFont( oFont ), -1 )
      ENDIF
      IF tColor != Nil
         ::aHili[ nGroup,2 ] := tColor
      ENDIF
      IF bColor != Nil
         ::aHili[ nGroup,3 ] := bColor
      ENDIF
   ENDIF
Return Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HCEdit
Local n, nPages, arr, lRes := -1

   //HWG_WriteLog( str(Seconds())+" tedit: "+Str(::handle,10)+"|"+Str(msg,6)+"|"+Str(wParam,10)+"|"+Str(lParam,10) )
   IF msg == WM_MOUSEMOVE .OR. msg == WM_LBUTTONDOWN .OR. msg == WM_RBUTTONDOWN
      ::nXPosM := hwg_LoWord( lParam )
      ::nYPosM := hwg_HiWord( lParam )
   ENDIF
   IF ::bOther != Nil
      IF ( n := Eval( ::bOther,Self,msg,wParam,lParam ) ) != -1
         RETURN n
      ENDIF
   ENDIF

   IF msg == WM_PAINT
      ::Paint()
      lRes := 0

   ELSEIF msg == WM_GETDLGCODE
      lRes := DLGC_WANTALLKEYS

   ELSEIF msg == WM_CHAR
      // If not readonly mode and Ctrl key isn't pressed
      IF !(Asc(Substr(hwg_GetKeyboardState(),VK_CONTROL+1,1)) >= 128)
         ::putChar( hwg_PtrToUlong( wParam ) )
      ENDIF

   ELSEIF msg == WM_KEYDOWN
      lRes := ::onKeyDown( hwg_PtrToUlong( wParam ) )

   ELSEIF msg == WM_LBUTTONDOWN
      IF !Empty( ::aPointM2[1] )
         ::PCopy( ,::aPointM2 )
         hwg_Invalidaterect( ::handle, 0, 0, 0, ::nClientWidth, ::nHeight )
      ENDIF
      hced_ShowCaret( ::hEdit )
      IF ::nCaret > 0
         IF ::nLines > 0
            ::SetCaretPos( SETC_COORS, hwg_LoWord( lParam ), hwg_HiWord( lParam ) )
            ::lMDown := .T.
            ::PCopy( ::aPointC, ::aPointM1 )
         ENDIF
      ENDIF
      IF ::nCaret <= 0
         ::nCaret ++
      ENDIF

   ELSEIF msg == WM_LBUTTONUP
      ::lMDown := .F.
      IF Empty( ::aPointM2[1] ) .OR. ::PCmp( ::aPointM1, ::aPointM2 ) == 0
         hced_ShowCaret( ::hEdit )
      ENDIF

   ELSEIF msg == WM_MOUSEMOVE     
      IF ::lMDown
         IF ::nCaret > 0
            //::nCaret := 0
            //hced_HideCaret( ::hEdit )
         ENDIF
         n := ::nLineC
         ::SetCaretPos( SETC_COORS+100, hwg_LoWord( lParam ), hwg_HiWord( lParam ) )
         IF ::PCmp( ::aPointM1, ::aPointC ) != 0
            ::PCopy( ::aPointC, ::aPointM2 )
         ENDIF
         IF ::nLineC >= n
            hwg_InvalidateRect( ::handle, 0, 0, ::aLines[n,AL_Y1], ::nClientWidth, ;
               ::aLines[::nLineC,AL_Y2] )
         ELSE
            hwg_InvalidateRect( ::handle, 0, 0, ::aLines[::nLineC,AL_Y1], ::nClientWidth, ;
               ::aLines[n,AL_Y2] )
         ENDIF
      ENDIF
      
   ELSEIF msg == WM_MOUSEWHEEL
      n := Iif( ( n := hwg_HiWord( wParam ) ) > 32768, n - 65535, n )
      IF Hwg_BitAnd( hwg_LoWord( wParam ), MK_MBUTTON ) != 0
         IF n > 0
            ::PageUp()
         ELSE
            ::PageDown()
         ENDIF
      ELSE
         IF n > 0
            ::SetCaretPos( SETC_COORS, hced_GetXCaretPos( ::hEdit ), 2 )
            ::LineUp()
         ELSE
            ::SetCaretPos( SETC_COORS, hced_GetXCaretPos( ::hEdit ), ::nHeight-2 )
            ::LineDown()
         ENDIF
      ENDIF

   ELSEIF msg == WM_VSCROLL
      RETURN ::onVScroll( wParam )

   ELSEIF msg == WM_MOUSEACTIVATE
      hwg_SetFocus( ::handle )
      lRes := MA_ACTIVATE

   ELSEIF msg == WM_SETFOCUS
      IF ::bGetFocus != Nil
         Eval( ::bGetFocus, Self )
      ENDIF
      hced_InitCaret( ::hEdit )
      ::nCaret ++
      ::SetCaretPos( SETC_XY )
      lRes := 0

   ELSEIF msg == WM_KILLFOCUS
      IF ::bLostFocus != Nil
         Eval( ::bLostFocus, Self )
      ENDIF
      hced_KillCaret( ::hEdit )
      ::nCaret := 0
      lRes := 0

   ELSEIF msg == WM_MOUSEWHEEL

   ELSEIF msg == WM_LBUTTONDBLCLK
      IF ::bClickDoub == Nil .OR. Empty( Eval( ::bClickDoub,Self ) )
         //::getWord( hwg_LoWord( lParam ), hwg_HiWord( lParam ),,.T. )         
      ENDIF

   ELSEIF msg == WM_SIZE
      arr := hwg_GetClientRect( ::handle )
      ::nClientWidth := arr[3] - arr[1]

   ELSEIF msg == WM_DESTROY
      ::End()
   ENDIF

   IF ::lChgCaret
      IF ::lVScroll
         n := Iif( ::nLines > 0, Int( ::nHeight/(::aLines[1,AL_Y2]-::aLines[1,AL_Y1]) ), 0 )
         IF n > 0 .AND. ( nPages := Int( ::nTextLen/n ) + 1 ) > 1
            hced_SetVScroll( ::hEdit, Min( Int( (::nLineF+::nLineC-1)*4/n ) - 1, (nPages-1)*4 ), 4, nPages )
         ENDIF
      ENDIF
      IF ::bChangePos != Nil
         Eval( ::bChangePos, Self )
      ENDIF
      ::lChgCaret := .F.
   ENDIF

RETURN lRes

METHOD Paint( lReal ) CLASS HCEdit
Local pps, hDCReal, hDC, nLine := 0, yPos := 0, yNew, i, lComm  // , hBitmap

   IF !Empty( ::oHili ) .AND. ::nLineF > 1 .AND. ::nDopChecked < ::nLineF-1
      lComm := ( Iif( ::nDopChecked > 0, ::aDop[::nDopChecked], 0 ) == 1 )
      FOR i := ::nDopChecked + 1 TO ::nLineF - 1
         ::oHili:Do( ::aText[i],lComm,.T. )
         ::aDop[i] := Iif( ::oHili:lMultiComm, 1, 0 )
         lComm := ::oHili:lMultiComm
      NEXT
      ::nDopChecked := ::nLineF - 1
   ENDIF

   IF lReal == Nil .OR. lReal
      pps := hwg_DefinePaintStru()
#ifdef __PLATFORM__UNIX
      hDCReal := hwg_BeginPaint( ::area, pps )
#else
      hDCReal := hwg_BeginPaint( ::handle, pps )
#endif
      lReal := .T.
   ELSE
#ifdef __PLATFORM__UNIX
      hDCReal := hwg_Getdc( ::area )
#else
      hDCReal := hwg_Getdc( ::handle )
#endif
   ENDIF

   //hdc := hwg_CreateCompatibleDC( hDCReal )
   //hBitmap := hwg_CreateCompatibleBitmap( hDCReal, ::nClientWidth, ::nHeight )
   //hwg_Selectobject( hDC, hBitmap )
   hDC := hDCReal

   hced_Setcolor( ::hEdit, ::tcolor, ::bColor )

   hced_SetPaint( ::hEdit, hDC,, ::nClientWidth, ::lWrap )

   IF lReal 
      hced_FillRect( ::hEdit, 0, 0, ::nClientWidth, ::nHeight )
   ENDIF

   IF ::lShowNumbers
      ::n4Number := hwg_GetTextSize(hDC,"55555")[1]
      ::n4Separ := ::n4Number + 8
   ELSE
      ::n4Number := ::n4Separ := 0
   ENDIF
   IF ::bPaint != Nil
      Eval( ::bPaint, Self, hDC )
   ENDIF

   IF lReal 
      IF ::n4Separ > 0
         hwg_Selectobject( hDC, ::oPenNum:handle )
         hwg_Drawline( hDC, ::nMarginL+::n4Separ-4, 4, ::nMarginL+::n4Separ-4, ::nHeight-8 )
      ENDIF
   ENDIF

   IF !Empty( ::aText )
      DO WHILE ( ++nLine+::nLineF-1 ) <= ::nTextLen

         IF nLine >= Len( ::aLines )
            ::aLines := ASize( ::aLines, Len( ::aLines ) + 16 )
            FOR i := 0 TO 15
               ::aLines[Len(::aLines)-i] := Array( AL_LENGTH )
            NEXT
         ENDIF

         yNew := ::PaintLine( hDC, yPos, nLine )
         //yNew := ::PaintLine( Iif( lReal, hDC, Nil ), yPos, nLine )

         IF lReal .AND. ::lShowNumbers
            hwg_Selectobject( hDC, ::oFont:handle )
            hced_SetColor( ::hEdit, ::tcolor )
            hwg_Settransparentmode( hDC, .T. )
            hwg_Drawtext( hDC, Str(nLine+::nLineF-1,4), ::nMarginL, ;
                  ::aLines[nLine,AL_Y1], ::nMarginL+::n4Number, ;
                  ::aLines[nLine,AL_Y2], DT_RIGHT )
            hwg_Settransparentmode( hDC, .F. )
         ENDIF
         IF yNew + ( yNew-yPos ) > ::nHeight
            nLine ++
            EXIT
         ENDIF
         yPos := yNew
      ENDDO
   ENDIF

   ::nLines := nLine - 1

   //hwg_Bitblt( hDCReal, 0, 0, ::nClientWidth, ::nHeight, hDC, 0, 0, SRCCOPY )
   //hwg_DeleteDC( hDC )
   //hwg_DeleteObject( hBitmap )

   IF lReal
      hwg_EndPaint( ::handle, pps )
   ELSE
      hwg_Releasedc( ::handle,hDCReal )
   ENDIF

Return Nil

METHOD PaintLine( hDC, yPos, nLine ) CLASS HCEdit
Local nPrinted, x1, x2, cLine, aLine := ::aLines[nLine]

   x1 := ::nMarginL + ::n4Separ
   x2 := ::nClientWidth - ::nMarginR //- ::n4Separ
   aLine[AL_Y1] := yPos
   cLine := Iif( ::nPosF==0,::aText[::nLineF+nLine-1], Substr(::aText[::nLineF+nLine-1],::nPosF+1) )

   IF nLine == ::nLineC .AND. ::bColorCur != ::bColor
      hced_SetColor( ::hEdit, ::tcolor, ::bColorCur )
   ENDIF

   ::MarkLine( nLine )
   nPrinted := hced_LineOut( ::hEdit, @x1, @yPos, @x2, cLine, Len(cLine), 0, Empty(hDC) )
   IF ::bPaint != Nil .AND. !Empty( hDC )
      Eval( ::bPaint, Self, hDC, ::nLineF+nLine-1, aLine[AL_Y1], yPos  )
   ENDIF
   IF nLine == ::nLineC .AND. ::bColorCur != ::bColor
      hced_SetColor( ::hEdit, ::tcolor, ::bColor )
   ENDIF

   aLine[AL_X1] := x1
   aLine[AL_X2] := x2
   aLine[AL_NCHARS] := nPrinted
   aLine[AL_Y2] := yPos
   //hwg_writelog( hb_ntos(nline)+": "+hb_ntos(aLine[AL_Y1])+" "+hb_ntos(aLine[AL_Y2]) )

Return yPos

METHOD MarkLine( nLine ) CLASS HCEdit
Local x1, x2, bColor, i, aStru, nL := ::nLineF+nLine-1, P1, P2

   hced_ClearAttr( ::hEdit )

   IF !Empty( ::oHili )
      /*
      IF nL < 1 .OR. nL > Len( ::aText ) .OR. nL > Len( ::aDop )
         hwg_writelog( ": "+Str(nL)+" "+Str(Len(::aText))+" "+Str(Len(::aDop)) )
         Return Nil
      ENDIF
      */
      ::oHili:Do( ::aText[nL], ( nL>1 .AND. ::aDop[nL-1]==1 ) )
      ::aDop[nL] := Iif( ::oHili:lMultiComm, 1, 0 )
      IF ::nDopChecked < nL
         ::nDopChecked := nL
      ENDIF
      IF ::oHili:nItems > 0
         aStru := ::oHili:aLineStru
         FOR i := 1 TO ::oHili:nItems
            IF aStru[i,2] >= ::nPosF .AND. aStru[i,3] <= HILIGHT_GROUPS
               x1 := Max( ::nPosF+1, aStru[i,1] ) - ::nPosF
               x2 := aStru[i,2] - ::nPosF
               bColor := Iif( nLine == ::nLineC .AND. ::bColorCur != ::bColor, ;
                  ::bColorCur, ::aHili[aStru[i,3],3] )

               hced_setAttr( ::hEdit, x1, x2-x1+1, ::aHili[aStru[i,3],1], ;
                     ::aHili[aStru[i,3],2], bColor )
            ENDIF
         NEXT
      ENDIF
   ENDIF

   IF !Empty( ::aPointM2[1] )
      IF ( ::aPointM1[P_Y] == ::aPointM2[P_Y] )
         IF ::aPointM1[P_Y] == nL
            x1 := Min( ::aPointM1[P_X], ::aPointM2[P_X] ) - ::nPosF
            x2 := Max( ::aPointM1[P_X], ::aPointM2[P_X] ) - ::nPosF
         ELSE
            Return Nil
         ENDIF
      ELSE
         P1 := Iif( ::aPointM1[P_Y] < ::aPointM2[P_Y], ::aPointM1, ::aPointM2[P_Y] )
         P2 := Iif( ::aPointM1[P_Y] < ::aPointM2[P_Y], ::aPointM2, ::aPointM1[P_Y] )
         IF P1[P_Y] == nL
            x1 := P1[P_X] - ::nPosF
            x2 := Len( ::aText[nL] ) - ::nPosF + 1
         ELSEIF P2[P_Y] == nL
            x1 := 1
            x2 := P2[P_X] - ::nPosF
         ELSEIF P2[P_Y] > nL .AND. nl > P1[P_Y]
            x1 := 1
            x2 := Len( ::aText[nL] ) - ::nPosF + 1
         ELSE
            Return Nil
         ENDIF
      ENDIF
      hced_setAttr( ::hEdit, x1, x2-x1, -1, ::tColorSel, ::bColorSel )
   ENDIF
Return Nil

METHOD End() CLASS HCEdit
Return Nil

METHOD SetText( cText ) CLASS HCEdit

   ::CloseText()
   ::aDop := Nil
   ::nDopChecked := ::nLines := 0

   IF Empty( cText )
      ::aText := { "" }
   ELSE
      ::aText := hb_aTokens( cText, cNewLine )
   ENDIF
   ::nTextLen := Len( ::aText )
   ::aDop := Array( ::nTextLen )
   Afill( ::aDop, 0 )

   ::nLineC := 1
   ::nPosF := ::nPosC := 0
   ::PCopy( { ::nPosC+1, ::nLineC }, ::aPointC )
   hwg_Invalidaterect( ::handle, 0 )
   hwg_Setfocus( ::handle )

Return Nil

METHOD Save( cFileName ) CLASS HCEdit
Local nHand, i

   IF Empty( cFileName )
      cFileName := ::cFileName
   ELSE
      ::cFileName := cFileName
   ENDIF

   IF !Empty( cFileName )
      nHand := Fcreate( ::cFileName := cFileName )
      IF Ferror() != 0
         RETURN .F.
      ENDIF

      FOR i := 1 TO ::nTextLen
         FWrite( nHand, Iif( ::lStripSpaces, Trim(::aText[i]), ::aText[i] ) + cNewLine )
      NEXT
      FClose( nHand )
   ENDIF

RETURN Nil

METHOD CloseText() CLASS HCEdit
RETURN Nil

METHOD AddFont( oFont, name, width, height , weight, ;
            CharSet, Italic, Underline, StrikeOut ) CLASS HCEdit
Local i

   IF oFont == Nil
      IF Charset == Nil .AND. Len(::aFonts)>0; Charset := ::aFonts[1]:CharSet; ENDIF
      FOR i := 1 TO Len(::aFonts)
         IF ::aFonts[i]:name == name .AND.           ;
            ::aFonts[i]:width == width .AND.         ;
            ::aFonts[i]:height == height .AND.       ;
            ( ::aFonts[i]:weight > 500 ) == ( weight > 500 ) .AND.       ;
            ::aFonts[i]:CharSet == CharSet .AND.     ;
            ::aFonts[i]:Italic == Italic .AND.       ;
            ::aFonts[i]:Underline == Underline .AND. ;
            ::aFonts[i]:StrikeOut == StrikeOut
            RETURN i
         ENDIF
      NEXT
      oFont := HFont():Add( name, width, height , weight, ;
                  CharSet, Italic, Underline, StrikeOut )
   ENDIF
   i := hced_AddFont( ::hEdit, oFont:handle )
   IF Empty( ::aFonts )
      ::nFontH := i
   ENDIF
   Aadd( ::aFonts, oFont )
RETURN Len( ::aFonts )

METHOD SetFont( oFont ) CLASS HCEdit
Local i, oFont1

   IF Len( ::aFonts ) > 1
      FOR i := 2 TO Len( ::aFonts )
         oFont1 := HFont():Add( oFont:name, ::aFonts[i]:width, oFont:height , ::aFonts[i]:weight, ;
                     ::aFonts[i]:CharSet, ::aFonts[i]:Italic, ::aFonts[i]:Underline, ::aFonts[i]:StrikeOut )
         ::aFonts[i]:Release()
         ::aFonts[i] := oFont1
         hced_SetFont( ::hEdit, oFont1:handle, i )
      NEXT
   ENDIF
   ::aFonts[1]:Release()
   ::aFonts[1] := oFont
   hced_SetFont( ::hEdit, oFont:handle, 1 )
   ::Refresh()

Return Nil

METHOD Line4Pos( yPos ) CLASS HCEdit
Local y1

   FOR y1 := 1 TO ::nLines
      IF yPos < ::aLines[ y1,AL_Y2 ]
         EXIT
      ENDIF
   NEXT
   IF y1 > ::nLines
      y1 --
   ENDIF

RETURN y1

METHOD SetCaretPos( nType, p1, p2 ) CLASS HCEdit
Local lSet := .T., x1, y1, xPos, cLine, nLinePrev := ::nLineC

   ::lChgCaret := .T.
   IF Empty(nType) .OR. Empty( ::nLines )
      hced_SetCaretPos( ::hEdit, ::nMarginL+::n4Separ, 0 )
      RETURN Nil
   ENDIF
   IF nType > 100
      nType -= 100
      lSet := .F.
   ENDIF
   IF nType == SETC_COORS
      xPos := p1
      IF ( y1 := ::Line4Pos( p2 ) ) == 0
         Return Nil
      ENDIF
      ::nLineC := y1
   ELSEIF nType == SETC_RIGHT
      x1 := ::nPosC + 1
   ELSEIF nType == SETC_LEFT
      x1 := ::nPosC - 1
   ELSEIF nType == SETC_XY
      IF p1 == Nil
         x1 := ::nPosC
      ELSEIF p1 == X_FIRST
         x1 := 0
      ELSEIF p1 == X_CURR
         y1 := ::nLineC
         xPos := hced_GetXCaretPos( ::hEdit )
      ELSEIF p1 == X_LAST
         y1 := ::nLineC
         xPos := ::nWidth
      ENDIF
   ENDIF

   ::MarkLine( ::nLineC )
   IF x1 == Nil
      cLine := ::aText[ ::nLineF+y1-1 ]
      IF ::nPosF > 0
         cLine := Substr( cLine, ::nPosF+1 )
      ENDIF
      x1 := hced_ExactCaretPos( ::hEdit, cLine, ::aLines[::nLineC,AL_X1], ;
                     xPos, ::aLines[::nLineC,AL_Y1], lSet )
   ELSE
      cLine := Iif( x1 == 0, "", Substr( ::aText[::nLineF+::nLineC-1],::nPosF+1,x1+1 ) )
      x1 := hced_ExactCaretPos( ::hEdit, ;
            Iif( Len(cLine)<=x1, cLine, Left(cLine,Len(cLine)-1) ), ;
            ::aLines[::nLineC,AL_X1], -1, ::aLines[::nLineC,AL_Y1], lSet )
   ENDIF
   ::nPosC := x1 - 1
   ::PCopy( { ::nPosF+x1, ::nLineF+::nLineC-1 }, ::aPointC )
   
   IF nLinePrev != ::nLineC
      IF nLinePrev <= ::nLines
         hwg_Invalidaterect( ::handle, 0, 0, ::aLines[nLinePrev,AL_Y1], ::nClientWidth, ;
            ::aLines[nLinePrev,AL_Y2] )
      ENDIF
      hwg_Invalidaterect( ::handle, 0, 0, ::aLines[::nLineC,AL_Y1], ::nClientWidth, ;
         ::aLines[::nLineC,AL_Y2] )
   ENDIF
   
RETURN Nil

METHOD onKeyDown( nKeyCode ) CLASS HCEdit
Local cKeyb := hwg_Getkeyboardstate(), cLine, lUnsel := .T.
Local nCtrl := Iif( Asc(Substr(cKeyb,VK_CONTROL+1,1))>=128,FCONTROL,Iif( Asc(Substr(cKeyb,VK_SHIFT+1,1))>=128,FSHIFT,0 ) )
Local nLine

   //hwg_writelog( "onKeyDown: " + str(nKeyCode) )
   IF ::bKeyDown != Nil
      Eval( ::bKeyDown, Self, nKeyCode )
   ENDIF
   IF ::nLines <= 0
      RETURN 0
   ENDIF
   nLine := ::nLineC
   IF ::nCaret <= 0
      ::nCaret := 1
      hced_ShowCaret( ::hEdit )
   ENDIF
   IF nCtrl == FSHIFT .AND. Empty( ::aPointM2[1] ) .AND. ;
          Ascan( {VK_RIGHT,VK_LEFT,VK_HOME,VK_END,VK_DOWN,VK_UP,33,34}, nKeyCode ) != 0
      ::PCopy( ::aPointC, ::aPointM1 )
   ENDIF
   IF nKeyCode == VK_RIGHT
      IF ::nPosC < ::aLines[nLine,AL_NCHARS]
      ELSE
         ::nPosF ++
         ::Paint( .F. )
         hwg_Invalidaterect( ::handle, 0, 0, ::aLines[nLine,AL_Y1], ::nClientWidth, ;
            ::aLines[nLine,AL_Y2] )
      ENDIF
      ::SetCaretPos( SETC_RIGHT )
      IF nCtrl == FSHIFT
         ::PCopy( ::aPointC, ::aPointM2 )
         lUnSel := .F.
         hwg_Invalidaterect( ::handle, 0, 0, ::aLines[nLine,AL_Y1], ::nClientWidth, ;
            ::aLines[nLine,AL_Y2] )
      ENDIF
   ELSEIF nKeyCode == VK_LEFT
      IF ::nPosC > 0
         ::SetCaretPos( SETC_LEFT )
      ELSEIF ::nPosF > 0
         ::nPosF --
         ::Paint( .F. )
      ENDIF
      IF nCtrl == FSHIFT
         ::PCopy( ::aPointC, ::aPointM2 )
         lUnSel := .F.
         hwg_Invalidaterect( ::handle, 0, 0, ::aLines[nLine,AL_Y1], ::nClientWidth, ;
            ::aLines[nLine,AL_Y2] )
      ENDIF
   ELSEIF nKeyCode == VK_HOME
      IF ::nPosF > 0
         ::nPosF := 0
         ::Paint( .F. )
      ENDIF
      ::SetCaretPos( SETC_XY, X_FIRST )
      IF nCtrl == FSHIFT
         ::PCopy( ::aPointC, ::aPointM2 )
            lUnSel := .F.
         hwg_Invalidaterect( ::handle, 0, 0, ::aLines[nLine,AL_Y1], ::nClientWidth, ;
            ::aLines[nLine,AL_Y2] )
      ENDIF
   ELSEIF nKeyCode == VK_END
      IF ::aLines[nLine,AL_NCHARS] < Len( ::aText[::nLineF+nLine-1] )
         ::nPosF := Int( ( ( Len( ::aText[::nLineF+nLine-1] ) - ;
               ::aLines[nLine,AL_NCHARS] ) ) * 7 / 6 )
         ::Paint( .F. )
      ENDIF
      ::SetCaretPos( SETC_XY, X_LAST )
      IF nCtrl == FSHIFT
         ::PCopy( ::aPointC, ::aPointM2 )
         lUnSel := .F.
         hwg_Invalidaterect( ::handle, 0, 0, ::aLines[nLine,AL_Y1], ::nClientWidth, ;
            ::aLines[nLine,AL_Y2] )
      ENDIF
   ELSEIF nKeyCode == VK_UP
      ::LineUp()
      IF nCtrl == FSHIFT
         ::PCopy( ::aPointC, ::aPointM2 )
         lUnSel := .F.
         hwg_Invalidaterect( ::handle, 0, 0, ::aLines[::nLineC+::nLineF-1,AL_Y1], ::nClientWidth, ;
               ::aLines[::nLineC+::nLineF,AL_Y2] )
      ENDIF
   ELSEIF nKeyCode == VK_DOWN
      ::LineDown()
      IF nCtrl == FSHIFT
         ::PCopy( ::aPointC, ::aPointM2 )
         lUnSel := .F.
         hwg_Invalidaterect( ::handle, 0, 0, ::aLines[::nLineC+::nLineF-2,AL_Y1], ::nClientWidth, ;
               ::aLines[::nLineC+::nLineF-1,AL_Y2] )
      ENDIF
   ELSEIF nKeyCode == 34    // Page Down
      IF nCtrl == FCONTROL
         ::Bottom()
      ELSE
         ::PageDown()
      ENDIF
      IF nCtrl == FSHIFT
         ::PCopy( ::aPointC, ::aPointM2 )
         lUnSel := .F.
         hwg_Invalidaterect( ::handle, 0 )
      ENDIF
   ELSEIF nKeyCode == 33    // Page Up
      IF nCtrl == FCONTROL
         ::Top()
      ELSE
         ::PageUp()
      ENDIF
      IF nCtrl == FSHIFT
         ::PCopy( ::aPointC, ::aPointM2 )
         lUnSel := .F.
         hwg_Invalidaterect( ::handle, 0 )
      ENDIF
   ELSEIF nKeyCode == 46    // Delete
      IF nCtrl == FSHIFT .AND. !Empty( ::aPointM2[1] )
         cLine := ::GetText( ::aPointM1, ::aPointM2 )
         hwg_Copystringtoclipboard( cLine )
      ENDIF
      ::putChar( 7 )

   ELSEIF nKeyCode == VK_INSERT
      IF nCtrl == 0
         ::lInsert := !::lInsert
         lUnSel := .F.

      ELSEIF nCtrl == FCONTROL
         cLine := ::GetText( ::aPointM1, ::aPointM2 )
         hwg_Copystringtoclipboard( cLine )
         lUnSel := .F.

      ELSEIF nCtrl == FSHIFT
         IF !::lReadOnly
            cLine := hwg_Getclipboardtext()
            hced_InsText( Self, ::aPointC, cLine )
            hwg_Invalidaterect( ::handle, 0, 0, ::aLines[nLine,AL_Y1], ::nClientWidth, ;
                  ::nHeight )
         ENDIF
      ENDIF
   ELSEIF nKeyCode == 65
      IF nCtrl == FCONTROL
         ::Pcopy( { 1, 1 }, ::aPointM1 )
         ::Pcopy( { Len(::aText[::nTextLen])+1, ::nTextLen }, ::aPointM2 )
         lUnSel := .F.
         hwg_Invalidaterect( ::handle, 0, 0, 0, ::nClientWidth, ::nHeight )
      ENDIF
   ENDIF
   IF !Empty( ::aPointM2[1] ) .AND. nKeyCode >= 32 .AND. lUnSel
      hwg_Invalidaterect( ::handle, 0, 0, ::aLines[::aPointM1[P_Y]-::nLineF+1,AL_Y1], ;
            ::nClientWidth, ::aLines[::aPointM2[P_Y]-::nLineF+1,AL_Y1] )
      ::Pcopy( ,::aPointM2 )
   ENDIF

RETURN 0

METHOD PutChar( nKeyCode ) CLASS HCEdit
Local nLine, lInvAll := .F.

   //hwg_writelog( "putchar: " + str(nKeyCode) )
   IF ::lReadOnly
      RETURN Nil
   ENDIF
   nLine := ::nLineC + ::nLineF - 1

   IF nKeyCode == VK_RETURN
      ::AddLine( nLine+1 )
      ::aText[nLine+1] := Substr( ::aText[nLine], ::nPosF+::nPosC+1 )
      ::aText[nLine] := Left( ::aText[nLine], ::nPosF+::nPosC )
      ::nPosF := ::nPosC := 0
      IF ::nLineC < ::nHeight/(::aLines[1,AL_Y2]-::aLines[1,AL_Y1]) - 2
         ::nLineC ++
      ELSE
         ::nLineF ++
         lInvAll := .T.
      ENDIF
      ::nDopChecked := nLine - 1
      ::Paint( .F. )
      hwg_Invalidaterect( ::handle, 0, 0, Iif( lInvAll, 0, ::aLines[::nLineC-1,AL_Y1] ), ;
            ::nClientWidth, ::nHeight )
      ::SetCaretPos( SETC_XY )
      ::lUpdated := .T.
      RETURN Nil

   ELSEIF nKeyCode == VK_TAB
      IF ::lInsert
         ::aText[nLine] := Stuff( ::aText[nLine],::nPosF+::nPosC+1,0,Space(::nTabLen) )
      ENDIF
      ::nPosC += ::nTabLen

   ELSEIF nKeyCode == VK_ESCAPE
      RETURN Nil

   ELSE
      IF nKeyCode == VK_BACK .OR. nKeyCode == 7
         IF !Empty( ::aPointM2[1] )
            // there is text selected
            hced_DelText( Self, ::aPointM1, ::aPointM2 )
            ::nLineC := ::aPointM1[P_Y] - ::nLineF + 1
            ::nPosC :=  ::aPointM1[P_X] - ::nPosF - 1
            IF ::aPointM1[P_Y] != ::aPointM2[P_Y]
               hwg_Invalidaterect( ::handle, 0, 0, ::aLines[::nLineC,AL_Y1], ;
                     ::nClientWidth, ::nHeight )
            ENDIF
            ::Pcopy( ,::aPointM2 )
         ELSE
            IF nKeyCode == VK_BACK
               IF ::nPosC == 0
                  // If this is a beginning of a line, merge it with previous
                  IF nLine > 1
                     ::nPosC := Len( ::aText[nLine-1] )
                     ::aText[nLine-1] += ::aText[nLine]
                     ::DelLine( nLine )
                     IF ::nLineC == 1
                        ::nLineF --
                     ELSE
                        ::nLineC --
                     ENDIF
                     ::nDopChecked := nLine - 2
                     ::Paint( .F. )
                     hwg_Invalidaterect( ::handle, 0, 0, ::aLines[::nLineC,AL_Y1], ;
                           ::nClientWidth, ::nHeight )
                     ::SetCaretPos( SETC_XY )
                     ::lUpdated := .T.
                     RETURN Nil
                  ENDIF
               ELSE
                  // Move one char left and process like the Del button
                  ::nPosC --
               ENDIF
            ENDIF
            ::aText[nLine] := Stuff( ::aText[nLine],::nPosF+::nPosC+1,1,"" )
         ENDIF
      ELSEIF ::lInsert
         ::aText[nLine] := Stuff( ::aText[nLine],::nPosF+::nPosC+1,0,Chr(nKeyCode) )
         ::nPosC ++
      ELSE
         ::aText[nLine] := Stuff( ::aText[nLine],::nPosF+::nPosC+1,1,Chr(nKeyCode) )
         ::nPosC ++
      ENDIF
      ::nDopChecked := nLine - 1
   ENDIF

   hwg_Invalidaterect( ::handle, 0, 0, ::aLines[::nLineC,AL_Y1], ;
         ::nClientWidth, ::aLines[::nLineC,AL_Y2] )

   ::SetCaretPos( SETC_XY )
   ::lUpdated := .T.

RETURN Nil


METHOD LineDown() CLASS HCEdit
Local y

   IF ::nLineC < ::nLines
      ::SetCaretPos( SETC_COORS, hced_GetXCaretPos( ::hEdit ), ::aLines[::nLineC,AL_Y2]+4 )
   ELSEIF ::nLineF + ::nLines - 1 < ::nTextLen
      y := ::aLines[::nLineC,AL_Y2]-4
      ::nLineF ++
      ::Paint( .F. )

      ::SetCaretPos( SETC_COORS, hced_GetXCaretPos( ::hEdit ), y )
      hwg_Invalidaterect( ::handle, 0 )
   ENDIF
RETURN Nil

METHOD LineUp() CLASS HCEdit
Local y

   IF ::nLineC > 1
      ::SetCaretPos( SETC_COORS, hced_GetXCaretPos( ::hEdit ), ::aLines[::nLineC,AL_Y1]-4 )
   ELSEIF ::nLineF > 1
      y := ::aLines[::nLineC,AL_Y2]-4
      ::nLineF --
      ::Paint( .F. )

      ::SetCaretPos( SETC_COORS, hced_GetXCaretPos( ::hEdit ), y )
      hwg_Invalidaterect( ::handle, 0 )
   ENDIF
RETURN Nil

METHOD PageDown() CLASS HCEdit
Local y, n

   n := Int( ::nHeight/(::aLines[1,AL_Y2]-::aLines[1,AL_Y1]) )
   IF ::nLineF + n - 2 < ::nTextLen
      y := ::aLines[::nLineC,AL_Y2]-4
      ::nLineF := ::nLineF + n - 2
      ::Paint( .F. )

      ::SetCaretPos( SETC_COORS, hced_GetXCaretPos( ::hEdit ), y )
      hwg_Invalidaterect( ::handle, 0 )
   ELSE
      ::Bottom()
   ENDIF
RETURN Nil

METHOD PageUp() CLASS HCEdit
Local y, n

   IF ::nLineF > 1
      y := ::aLines[::nLineC,AL_Y2]-4
      n := Int( ::nHeight/(::aLines[1,AL_Y2]-::aLines[1,AL_Y1]) )
      ::nLineF -= ( Min( n, ::nTextLen ) - 1 )
      IF ::nLineF <= 0
         ::nLineF := 1
      ENDIF
      ::Paint( .F. )

      ::SetCaretPos( SETC_COORS, hced_GetXCaretPos( ::hEdit ), y )
      hwg_Invalidaterect( ::handle, 0 )
   ELSE
      ::Top()
   ENDIF
RETURN Nil

METHOD Top() CLASS HCEdit

   IF ::nLineF != 1 .OR. ::nLineC != 1 .OR. ::nPosC != 0 .OR. ::nPosF != 0
      ::nLineF := ::nLineC := 1
      ::nPosC := ::nPosF := 0

      ::Paint( .F. )

      ::SetCaretPos( SETC_COORS, 0, 0 )
      hwg_Invalidaterect( ::handle, 0 )
   ENDIF
RETURN Nil

METHOD Bottom() CLASS HCEdit
Local nNewF := Max( 1, ::nTextLen - ::nLines ), nNewC := ::nTextLen - ::nLineF + 1

   IF ::nLineF != nNewF .OR. ::nLineC != nNewC
      ::nLineF := nNewF
      ::nLineC := nNewC

      ::Paint( .F. )

      ::SetCaretPos( SETC_COORS, ::nWidth, ::nHeight )
      hwg_Invalidaterect( ::handle, 0 )
   ENDIF
RETURN Nil

METHOD Goto( nLine ) CLASS HCEdit
Local n

   IF ::nLines <= 0 .AND. ::nTextLen > 2
      ::Paint( .F. )
   ENDIF
   IF ( n := Iif( ::nLines > 0, Int( ::nHeight/(::aLines[1,AL_Y2]-::aLines[1,AL_Y1]) ), 0 ) ) > 0
      IF nLine > ::nLineF .AND. nLine - ::nLineF + 1 < n
         hwg_Invalidaterect( ::handle, 0, 0, ::aLines[::nLineC,AL_Y1], ;
               ::nClientWidth, ::aLines[::nLineC,AL_Y2] )
         ::nLineC := nLine - ::nLineF + 1
         hwg_Invalidaterect( ::handle, 0, 0, ::aLines[::nLineC,AL_Y1], ;
               ::nClientWidth, ::aLines[::nLineC,AL_Y2] )
      ELSE
         ::nLineC := Min( Int( n/2 ), nLine )
         ::nLineF := nLine - ::nLineC + 1
         hwg_Invalidaterect( ::handle, 0 )
      ENDIF
      ::SetCaretPos( SETC_XY )
   ENDIF

RETURN Nil

METHOD onVScroll( wParam ) CLASS HCEdit
Local nCode := hwg_Loword( wParam ), nPos := hwg_Hiword( wParam )
Local n, nPages

   IF ::nLines <= 0
      RETURN 0
   ENDIF
   IF nCode == SB_TOP
      ::Top()
   ELSEIF nCode == SB_BOTTOM
      ::Bottom()
   ELSEIF nCode == SB_LINEDOWN
      ::LineDown()
   ELSEIF nCode == SB_LINEUP
      ::LineUp()
   ELSEIF nCode == SB_PAGEDOWN
      ::PageDown()
   ELSEIF nCode == SB_PAGEUP
      ::PageUp()
   ELSEIF nCode = SB_THUMBPOSITION .OR. nCode = SB_THUMBTRACK
      n := Iif( ::nLines > 0, Int( ::nHeight/(::aLines[1,AL_Y2]-::aLines[1,AL_Y1]) ), 0 )
      IF n > 0
         nPages := Int( ::nTextLen/n ) + 1
         ::nLineF := Min( Max( Int( nPos / ((nPages-1)*4) * ::nTextLen ) -::nLineC + 1, 1 ), ::nTextLen )
         ::Paint( .F. )

         ::SetCaretPos( SETC_COORS, hced_GetXCaretPos( ::hEdit ), hced_GetYCaretPos( ::hEdit ) )
         hwg_Invalidaterect( ::handle, 0 )
      ENDIF
   ENDIF
RETURN 0

METHOD PCopy( Psource, Pdest ) CLASS HCEdit

   IF !Empty( Psource )
      Pdest[P_X] := Psource[P_X]
      Pdest[P_Y] := Psource[P_Y]
   ELSE
      Pdest[P_X] := Pdest[P_Y] := 0
   ENDIF
RETURN Nil

METHOD PCmp( P1, P2 ) CLASS HCEdit

   IF P2[P_Y] > P1[P_Y] .OR. ( P2[P_Y] == P1[P_Y] .AND. P2[P_X] > P1[P_X] )
      RETURN -1
   ELSEIF P1[P_Y] > P2[P_Y] .OR. ( P1[P_Y] == P2[P_Y] .AND. P1[P_X] > P2[P_X] )
      RETURN 1
   ENDIF
RETURN 0

METHOD GetText( P1, P2 ) CLASS HCEdit
Local cText := "", Pstart := Array( P_LENGTH ), Pend := Array( P_LENGTH ), i, nPos1

   IF ::Pcmp( P1, P2 ) < 0
      ::PCopy( P1, Pstart )
      ::PCopy( P2, Pend )
   ELSE
      ::PCopy( P2, Pstart )
      ::PCopy( P1, Pend )
   ENDIF
   FOR i := Pstart[P_Y] TO Pend[P_Y]
      cText += Substr( ::aText[i], ;
            nPos1 := Iif( i==Pstart[P_Y],Pstart[P_X],1 ), ;
            Iif( i==Pend[P_Y],Pend[P_X],Len(::aText[i]) ) - nPos1 + 1 )
      IF i != Pend[P_Y]
         cText += cNewLine
      ENDIF
   NEXT
RETURN cText

METHOD AddLine( nLine ) CLASS HCEdit

   IF ::nTextLen == Len( ::aText )
      Asize( ::aText, Len( ::aText ) + 32 )
      Asize( ::aDop, Len( ::aText ) )
   ENDIF
   ::nTextLen ++
   Ains( ::aText, nLine )

RETURN Nil

METHOD DelLine( nLine ) CLASS HCEdit

   Adel( ::aText, nLine )
   ::nTextLen --

RETURN Nil

METHOD Refresh() CLASS HCEdit

   hwg_Invalidaterect( ::handle, 0, 0, 0, ::nClientWidth, ::nHeight )
RETURN Nil


Function hced_DelText( oEdit, P1, P2 )
Local i, Pstart := Array( P_LENGTH ), Pend := Array( P_LENGTH )

   IF oEdit:Pcmp( P1, P2 ) < 0
      oEdit:PCopy( P1, Pstart )
      oEdit:PCopy( P2, Pend )
   ELSE
      oEdit:PCopy( P2, Pstart )
      oEdit:PCopy( P1, Pend )
   ENDIF

   oEdit:nDopChecked := Pstart[P_Y] - 1
   IF Pstart[P_Y] == Pend[P_Y]
      i := Pstart[P_Y]
      oEdit:aText[i] := Left( oEdit:aText[i], Pstart[P_X]-1 ) + Substr( oEdit:aText[i], Pend[P_X] )
   ELSE
      FOR i := Pend[P_Y] TO Pstart[P_Y] STEP -1
         IF i == Pstart[P_Y]
            oEdit:aText[i] := Left( oEdit:aText[i], Pstart[P_X]-1 )
         ELSEIF i == Pend[P_Y]
            oEdit:aText[i] := Substr( oEdit:aText[i], Pend[P_X] )
         ELSE
            oEdit:DelLine( i )
         ENDIF
      NEXT
   ENDIF

Return Nil

Function hced_InsText( oEdit, aPoint, cText )
Local aText := hb_aTokens( cText, cNewLine ), nLine := aPoint[P_Y], cRest, i

   oEdit:nDopChecked := nLine - 1
   IF Len( aText ) == 1
      oEdit:aText[nLine] := Stuff( oEdit:aText[nLine], oEdit:nPosF+oEdit:nPosC+1,0,cText )
   ELSE
      cRest := Substr( oEdit:aText[nLine], oEdit:nPosF+oEdit:nPosC+1 )
      oEdit:aText[nLine] := Left( oEdit:aText[nLine], oEdit:nPosF+oEdit:nPosC ) + ;
            aText[1]
      FOR i := 2 TO Len( aText )
         oEdit:AddLine( nLine + i - 1 )
         oEdit:aText[nLine+i-1] := aText[i]
         IF i == Len( aText )
            oEdit:aText[nLine+i-1] += cRest
         ENDIF
      NEXT
   ENDIF
Return Nil
