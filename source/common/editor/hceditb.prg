/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * The Basic edit control
 *
 * Copyright 2023 Alexander Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 */

#include "hbclass.ch"
#include "hwgui.ch"

#define SETC_COORS           1
#define SETC_RIGHT           2
#define SETC_LEFT            3
#define SETC_XY              4
#define SETC_XFIRST          5
#define SETC_XCURR           6
#define SETC_XLAST           7
#define SETC_XYPOS           8

#ifdef __GTK__
#define GDK_CONTROL_MASK  2
#define GDK_MOD1_MASK     4
#endif

static hCursorEdi, hCursorCommon

CLASS HCEditBasic INHERIT HBoard

   CLASS VAR winclass  INIT "HBOARD"

   DATA   oDrawn

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, bPaint, tcolor, bcolor, bGfocus, bLfocus, xInitVal, cPicture )
   METHOD SetText( cText )
   METHOD Value( xValue ) SETGET

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, bPaint, tcolor, bcolor, bGfocus, bLfocus, xInitVal, cPicture )  CLASS HCEditBasic

   ::oDrawn := HDrawnEdit():New( Self, 0, 0, nWidth, nHeight, tcolor, bcolor, ;
      oFont, xInitVal, cPicture, bPaint )

   ::bGetFocus  := ::oDrawn:bGetFocus  := bGFocus
   ::bLostFocus := ::oDrawn:bLostFocus := bLFocus

   oWndParent := iif( oWndParent == NIL, ::oDefaultParent, oWndParent )

   ::Super:New( oWndParent, nId, nLeft, nTop, nWidth, ;
      nHeight, oFont, bInit, bSize, bPaint, , ;
      Iif( tcolor == Nil, 0, tcolor ), Iif( bcolor == Nil, 16777215, bcolor ) )

   RETURN Self

METHOD SetText( cText ) CLASS HCEditBasic

   RETURN ::oDrawn:SetText( cText )

METHOD Value( xValue ) CLASS HCEditBasic

   RETURN ::oDrawn:Value( xValue )

CLASS HDrawnEdit INHERIT HDrawn

   DATA   hEdit

   DATA   lUtf8        INIT .F.
   DATA   lReadOnly    INIT .F.
   DATA   lUpdated     INIT .F.
   DATA   lInsert      INIT .T.
   DATA   lNoPaste     INIT .F.

   DATA   nBoundL      INIT 2
   DATA   nBoundR      INIT 2
   DATA   nBoundT      INIT 2

   DATA   oPenBorder
   DATA   nBorder       INIT 0
   DATA   nBorderColor  INIT 0

   DATA   tcolorSel    INIT 16777215
   DATA   bcolorSel    INIT 16744448

   DATA   cType, oPicture

   DATA   nAlign       INIT 0
   DATA   nPosF        INIT 1
   DATA   nPosC        INIT 1
   DATA   bKeyDown, bRClick
   DATA   bGetFocus, bLostFocus
   DATA   bSetGet

   DATA   nInit        INIT 0  PROTECTED

   METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, ;
               tcolor, bcolor, oFont, xInitVal, cPicture, bPaint, bChgState )
   METHOD Paint( hDC )
   METHOD Value( xValue ) SETGET
   METHOD DelText( nPos1, nPos2 )
   METHOD InsText( nPosC, cText, lOver )
   METHOD SetCaretPos( nType, p1 )
   METHOD PutChar( wParam )
   METHOD onKey( msg, wParam, lParam )
   METHOD onMouseMove( xPos, yPos )
   METHOD onMouseLeave()
   METHOD onButtonDown( msg, xPos, yPos )
   METHOD SetFocus()
   METHOD onKillFocus()
   METHOD Skip( n )
   METHOD End()

ENDCLASS

METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bcolor, ;
   oFont, xInitVal, cPicture, bPaint, bChgState ) CLASS HDrawnEdit

   ::Super:New( oWndParent, nLeft, nTop, nWidth, nHeight, Iif( tcolor == Nil, 0, tcolor ), ;
      Iif( bcolor == Nil, 16777215, bcolor ),, ' ', oFont, bPaint,, bChgState )

   ::hEdit := hced_InitTextEdit()
   IF Empty( hCursorEdi )
      hCursorEdi := hwg_Loadcursor( IDC_IBEAM )
#ifdef __GTK__
      hCursorCommon := hwg_Loadcursor( IDC_ARROW )
#endif
   ENDIF
   IF hwg__isUnicode()
      ::lUtf8 := .T.
   ENDIF

   ::cType := ValType( xInitVal )
   ::xValue := xInitVal
   IF !Empty( cPicture ) .OR. ( xInitVal != Nil .AND. Valtype( xInitVal ) != "C" )
      ::oPicture := HPicture():New( cPicture, xInitVal )
      ::title := ::oPicture:Transform( xInitVal )
   ELSEIF !Empty( xInitVal )
      ::title := xInitVal
   ELSE
      ::title  := ""
   ENDIF

   RETURN Self

METHOD Paint( hDC ) CLASS HDrawnEdit

   LOCAL x1 := ::nLeft+::nBoundL+::nBorder, x2 := ::nLeft+::nWidth-1-::nBorder, cLine

   IF ::nInit < 2
      hced_SetHandle( ::hEdit, ::GetParentBoard():handle )
      IF ::oFont == Nil
         IF ::oParent:oFont == Nil
            PREPARE FONT ::oFont NAME "Courier New" WIDTH 0 HEIGHT - 17
         ELSE
            ::oFont := ::oParent:oFont
         ENDIF
      ENDIF
      hced_SetFont( ::hEdit, ::oFont:handle, 1 )
      IF Empty( ::oPenBorder) .AND. ::nBorder > 0
         ::oPenBorder := HPen():Add( PS_SOLID, ::nBorder, ::nBorderColor )
      ENDIF
      IF ::nInit == 1
         ::SetFocus()
      ENDIF
      ::nInit := 2
   ENDIF

   hced_Setcolor( ::hEdit, ::tcolor, ::bColor )
   hced_SetPaint( ::hEdit, hDC,, ::nLeft+::nWidth-::nBoundR-::nBorder, .F.,, ::nLeft+::nWidth-::nBoundR-::nBorder )
   hced_FillRect( ::hEdit, ::nLeft, ::nTop, ::nLeft+::nWidth-1, ::nTop+::nHeight-1 )

   IF !Empty( ::oPenBorder )
      hwg_Rectangle( hDC, ::nLeft, ::nTop, ::nLeft+::nWidth-1, ::nTop+::nHeight-1, ::oPenBorder:handle )
   ENDIF

   IF ::bPaint != Nil
      Eval( ::bPaint, Self, hDC )
   ENDIF

   cLine := Iif( ::nPosF == 1, ::title, hced_Substr( Self, ::title,::nPosF ) )
   hced_LineOut( ::hEdit, @x1, ::nTop+::nBoundT+::nBorder, @x2, cLine, hced_Len( Self, cLine ), ::nAlign, ::nLeft+::nWidth-::nBoundR-1 )

   RETURN Nil

METHOD Value( xValue ) CLASS HDrawnEdit

   IF xValue != Nil
      ::xValue := xValue
      IF !Empty( ::oPicture )
         ::title := ::oPicture:Transform( xValue )
      ELSE
         ::title := xValue
      ENDIF
      ::Refresh()
      IF !Empty( ::bSetGet )
         Eval( ::bSetGet, xValue, Self )
      ENDIF
      RETURN xValue
   ELSE
      IF !Empty( ::oPicture )
         ::xValue := ::oPicture:UnTransform( ::title )
      ELSE
         ::xValue := ::title
      ENDIF
      IF ::cType == "D"
         ::xValue := CToD( ::xValue )
      ELSEIF ::cType == "N"
         ::xValue := Val( LTrim( ::xValue ) )
      ENDIF
      IF !Empty( ::bSetGet )
         Eval( ::bSetGet, ::xValue, Self )
      ENDIF
   ENDIF

   RETURN ::xValue

METHOD DelText( nPos1, nPos2 ) CLASS HDrawnEdit

   ::title := hced_Left( Self, ::title, nPos1-1 ) + hced_Substr( Self, ::title, nPos2+1 )
   ::lUpdated := .T.
   ::Refresh()

   RETURN Nil

METHOD InsText( nPosC, cText, lOver ) CLASS HDrawnEdit

   LOCAL nPos, nLen := hced_Len( Self, cText ), i

   IF nPosC == Nil; nPosC := ::nPosC; ENDIF

   FOR i := 1 TO nLen
      nPos := ::nPosF + nPosC - 1
      IF !Empty( ::oPicture )
         ::title := ::oPicture:GetApplyKey( ::title, @nPos, hced_Substr( Self, cText,i,1 ), .F., !lOver )
         ::nPosC := nPos - ::nPosF + 1
      ELSE
         IF Empty( lOver )
            ::title := hced_Left( Self, ::title, nPos-1 ) + hced_Substr( Self, cText,i,1 ) + hced_Substr( Self, ::title, nPos )
         ELSE
            ::title := hced_Left( Self, ::title, nPos-1 ) + hced_Substr( Self, cText,i,1 ) + hced_Substr( Self, ::title, nPos + nLen )
         ENDIF
         ::nPosC += 1
         nPos += 1
      ENDIF

      ::SetCaretPos( SETC_XY )
      IF ::nPosC < nPos - ::nPosF + 1
         ::nPosF += nPos - ::nPosF + 1 - ::nPosC
      ENDIF
   NEXT
   ::lUpdated := .T.
   ::Refresh()

   RETURN Nil

METHOD SetCaretPos( nType, p1 ) CLASS HDrawnEdit

   LOCAL lSet := .T. , x1, xPos, yPos := ::nTop + ::nBoundT + ::nBorder, cLine

   IF Empty( nType )
      hced_SetCaretPos( ::hEdit, ::nLeft+::nBoundL, ::nTop+::nBoundT+::nBorder )
      RETURN Nil
   ENDIF
   IF nType > 100
      nType -= 100
      lSet := .F.
   ENDIF
   IF nType == SETC_COORS
      xPos := p1
   ELSEIF nType == SETC_RIGHT
      x1 := ::nPosC
   ELSEIF nType == SETC_LEFT
      x1 := ::nPosC - 2
   ELSEIF nType == SETC_XY
      x1 := ::nPosC - 1
   ELSEIF nType == SETC_XYPOS
      x1 := p1 - 1
   ELSEIF nType == SETC_XFIRST
      x1 := 0
   ELSEIF nType == SETC_XCURR
      xPos := hced_GetXCaretPos( ::hEdit )
   ELSEIF nType == SETC_XLAST
      xPos := ::nLeft + ::nWidth
   ENDIF
   cLine := Iif( ::nPosF == 1, ::title, hced_Substr( Self, ::title,::nPosF ) )

   IF x1 == Nil
      x1 := hced_ExactCaretPos( ::hEdit, cLine, ::nLeft+::nBoundL, ;
         Iif(Empty(xPos),0,xPos), yPos, lSet, 0 )
   ELSE
      x1 := hced_ExactCaretPos( ::hEdit, ;
            Iif( hced_Len( Self, cLine ) <= x1, cLine, hced_Left( Self, cLine, x1 ) ), ;
            ::nLeft+::nBoundL, -1, yPos, lSet, 0 )
   ENDIF
   //hwg_writelog( "scp " + ltrim(str(ntype)) + ": " + ltrim(str(hced_getxcaretpos(::hEdit))) + " " + ltrim(str(hced_getycaretpos(::hEdit))))
   ::nPosC := x1
#ifdef __GTK__
   ::Refresh()
#endif
   //::PCopy( { ::nPosF + x1 - 1, ::nLineF + ::nLineC - 1 }, ::aPointC )

   RETURN Nil

#define FBITCTRL   4
#define FBITSHIFT  3
#define FBITALT    9
#define FBITALTGR  65027

METHOD PutChar( wParam ) CLASS HDrawnEdit

   LOCAL nPos, oParent, cTemp

   //hwg_writelog( "putchar: " + str(hwg_PtrToUlong(wParam)) )
   IF ::lReadOnly
      RETURN Nil
   ENDIF

   IF wParam == VK_RETURN
      hwg_DlgCommand( hwg_getParentForm( ::GetParentBoard() ), IDOK, 0 )

   ELSEIF wParam == VK_ESCAPE
      oParent := hwg_getParentForm( ::GetParentBoard() )
      IF __ObjHasMsg( oParent, "LEXITONESC" )
         hwg_DlgCommand( oParent, IDCANCEL, 0 )
      ENDIF

   ELSEIF wParam == VK_BACK .OR. wParam == 7
      nPos := ::nPosF + ::nPosC - 1
      IF nPos > 1 .OR. wParam == 7
         IF !Empty( ::oPicture ) .AND. ::oPicture:lPicComplex
            IF wParam == VK_BACK
               nPos --
            ENDIF
            cTemp := ::oPicture:Delete( ::title, @nPos )
            IF nPos > 0
               ::title := cTemp
               ::nPosC := nPos - ::nPosF + 1
               ::SetCaretPos( SETC_XY )
            ENDIF
         ELSE
            nPos := Iif( wParam == VK_BACK, nPos - 1, nPos )
            ::DelText( nPos, nPos )
            IF wParam == VK_BACK
               ::SetCaretPos( SETC_LEFT )
            ENDIF
         ENDIF
         ::Refresh()
      ENDIF
   ELSE        // Insert or overwrite any character
      ::InsText( , hced_Chr( Self,wParam ), !::lInsert )
   ENDIF

   RETURN Nil

METHOD onKey( msg, wParam, lParam ) CLASS HDrawnEdit

   LOCAL cLine, nCtrl, nPos, n

#ifndef __GTK__
   wParam := hwg_PtrToUlong( wParam )
#endif

   cLine := hwg_Getkeyboardstate( lParam )
   nCtrl := Iif( Asc( SubStr(cLine,0x12,1 ) ) >= 128, FCONTROL, 0 ) + ;
         Iif( Asc(SubStr(cLine,0x11,1 ) ) >= 128,FSHIFT,0 )
   //hwg_writelog( "onkey: " + str( wParam ) + str( nCtrl ) )
   IF ::bKeyDown != Nil .AND. ( n := Eval( ::bKeyDown, Self, wParam, nCtrl, 0 ) ) != -1
      RETURN n
   ENDIF

   IF msg == WM_CHAR
      IF nCtrl != FCONTROL
         ::putChar( wParam )
      ENDIF

   ELSEIF msg == WM_KEYDOWN

      hced_ShowCaret( ::hEdit )

      IF wParam == VK_RIGHT

         IF ( nPos := (::nPosC + ::nPosF - 1) ) <= hced_Len( Self, ::title )
            IF !Empty( ::oPicture )
               IF ( nPos := ::oPicture:KeyRight( nPos ) ) < 0
                  RETURN Nil
               ENDIF
               ::nPosC := nPos - ::nPosF + 1
            ELSE
               ::nPosC ++
               nPos := ::nPosC + ::nPosF - 1
            ENDIF
            ::SetCaretPos( SETC_XY )
            IF ::nPosC < nPos - ::nPosF + 1
               ::nPosF += nPos - ::nPosF + 1 - ::nPosC
               ::Refresh()
            ENDIF
         ENDIF

      ELSEIF wParam == VK_LEFT

         IF ( nPos := (::nPosC + ::nPosF - 1) ) > 1
            IF !Empty( ::oPicture )
               IF ( n := ::oPicture:KeyLeft( nPos ) ) < 0
                  RETURN Nil
               ENDIF
               n := nPos - n
            ELSE
               n := 1
            ENDIF
            DO WHILE n > 0
              IF ::nPosF > 1 .AND. ::nPosC == 1
                 ::nPosF --
                 ::Refresh()
              ELSE
                 ::SetCaretPos( SETC_LEFT )
              ENDIF
              n --
            ENDDO
         ENDIF

      ELSEIF wParam == VK_HOME  // Home
         ::nPosC := Iif( !Empty( ::oPicture ), ::oPicture:KeyRight( 0 ), 1 )
         IF ::nPosF > 1
            ::nPosF := 1
            ::Refresh()
         ENDIF
         ::SetCaretPos( SETC_XY )

      ELSEIF wParam == VK_END
         nPos := hced_Len( Self, ::title ) + 1
         ::nPosC := nPos - ::nPosF + 1
         ::SetCaretPos( SETC_XY )
         IF ::nPosC < nPos - ::nPosF + 1
            ::nPosF += nPos - ::nPosF + 1 - ::nPosC
            ::Refresh()
         ENDIF

      ELSEIF wParam == VK_TAB
         ::Skip( Iif( hwg_checkBit( nctrl,FBITSHIFT ), -1, 1 ) )

      ELSEIF wParam == VK_DOWN
         ::Skip( 1 )

      ELSEIF wParam == VK_UP
         ::Skip( -1 )

      ELSEIF wParam == VK_DELETE   // Delete
         ::putChar( 7 )   // for to not interfere with '.'

      ELSEIF wParam == VK_INSERT   // Insert
         IF nCtrl == 0
            ::lInsert := !::lInsert

         ELSEIF hwg_checkBit( nctrl,FBITCTRL )
            hwg_Copystringtoclipboard( ::Value )

         ELSEIF hwg_checkBit( nctrl,FBITSHIFT )
            IF !::lReadOnly .AND. !::lNoPaste
               cLine := hwg_Getclipboardtext()
               IF Chr(9) $ cLine
                  cLine := Strtran( cLine, Chr(9), Space(::nTablen) )
               ENDIF
               ::InsText( , cLine )
               ::Refresh()
            ENDIF
         ENDIF

      ELSEIF ( wParam == 67 .OR. wParam == 99 ) .AND. hwg_checkBit( nctrl,FBITCTRL )   // 'C'
            hwg_Copystringtoclipboard( ::Value )

      ELSEIF ( wParam == 86 .OR. wParam == 118 ) .AND. hwg_checkBit( nctrl,FBITCTRL )  // 'V'
         IF !::lReadOnly .AND. !::lNoPaste
            cLine := hwg_Getclipboardtext()
            IF Chr(9) $ cLine
               cLine := Strtran( cLine, Chr(9), " " )
            ENDIF
            ::InsText( , cLine )
            hwg_Invalidaterect( ::handle, 0 )
         ENDIF

      ELSEIF ( wParam == 88 .OR. wParam == 120 ) .AND. hwg_checkBit( nctrl,FBITCTRL )  // 'X'
         hwg_Copystringtoclipboard( ::Value )
         ::nPosF := ::nPosC := 1
         ::SetCaretPos( SETC_XY )
         ::Value := ""
         ::Refresh()

#ifdef __GTK__
      ELSEIF wParam < 0xFE00 .OR. ( wParam >= GDK_KP_Multiply .AND. wParam <= GDK_KP_9 ) ;
            .OR. wParam == VK_RETURN .OR. wParam == VK_BACK .OR. wParam == VK_TAB .OR. wParam == VK_ESCAPE
         IF hwg_bitand( lParam, GDK_CONTROL_MASK+GDK_MOD1_MASK ) == 0
            IF wParam >= GDK_KP_0
               wParam -= ( GDK_KP_0 - 48 )
            ENDIF
            ::putChar( wParam )
         ENDIF
#endif
      ENDIF

   ENDIF

   RETURN Nil

METHOD onMouseMove( xPos, yPos ) CLASS HDrawnEdit

   Hwg_SetCursor( hCursorEdi, ::GetParentBoard():handle )

   RETURN ::Super:onMouseMove( xPos, yPos )

METHOD onMouseLeave() CLASS HDrawnEdit

#ifdef __GTK__
   Hwg_SetCursor( hCursorCommon, ::GetParentBoard():handle )
#endif
   RETURN ::Super:onMouseLeave()

METHOD onButtonDown( msg, xPos, yPos ) CLASS HDrawnEdit

   LOCAL nPos

   ::Super:onButtonDown( msg, xPos, yPos )

   ::SetFocus()
   Hwg_SetCursor( hCursorEdi, ::GetParentBoard():handle )
   ::SetCaretPos( SETC_COORS, xPos, yPos )
   IF !Empty( ::oPicture ) .AND. !::oPicture:IsEditable( ::nPosC )
      IF ( nPos := ::oPicture:KeyRight( ::nPosC ) ) >= 0
         ::nPosC := nPos - ::nPosF + 1
         ::SetCaretPos( SETC_XY )
      ENDIF
   ENDIF

   IF msg == WM_RBUTTONDOWN .AND. !Empty( ::bRClick )
      Eval( ::bRClick, Self )
   ENDIF

   RETURN Nil

METHOD SetFocus() CLASS HDrawnEdit

   LOCAL oBoard

   IF ::nInit == 0
      ::nInit := 1
      RETURN Nil
   ENDIF

   oBoard := ::GetParentBoard()
   hwg_SetFocus( oBoard:handle )
   oBoard:oInFocus := Self

   IF ::bGetFocus != Nil
      Eval( ::bGetFocus, Self )
   ENDIF

   hced_InitCaret( ::hEdit )
   ::SetCaretPos( SETC_XY )
   //hced_ShowCaret( ::hEdit )

   RETURN Nil

METHOD onKillFocus() CLASS HDrawnEdit

   ::Value()
   IF ::bLostFocus != Nil
      Eval( ::bLostFocus, Self )
   ENDIF

   hced_KillCaret( ::hEdit )

   RETURN Nil

METHOD Skip( n ) CLASS HDrawnEdit

   LOCAL oBoard := ::GetParentBoard(), i, l, l1

   n := Iif( n == Nil, 1, n )
   i := Iif( n > 0, 1, Len( oBoard:aDrawn ) )
   l := .F.
   DO WHILE ( n > 0 .AND. i <= Len( oBoard:aDrawn ) ) .OR. ( n < 0 .AND. i > 0 )
      l1 := .F.
      IF !l .AND. ( oBoard:aDrawn[i] == Self .OR. ;
         ( __objHasMsg( oBoard:aDrawn[i], "OEDIT" ) .AND. oBoard:aDrawn[i]:oEdit == Self ) )
         l := .T.
      ELSEIF l .AND. ( __objHasMsg( oBoard:aDrawn[i], "OPICTURE" ) .OR. ;
         ( l1 := __objHasMsg( oBoard:aDrawn[i], "OEDIT" ) ) )
         ::onKillFocus()
         IF l1
            oBoard:aDrawn[i]:oEdit:SetFocus()
         ELSE
            oBoard:aDrawn[i]:SetFocus()
         ENDIF
         EXIT
      ENDIF
      i += n
   ENDDO

   RETURN Nil

METHOD End() CLASS HDrawnEdit

   IF !Empty( ::hEdit )
      hced_KillCaret( ::hEdit )
      hced_Release( ::hEdit )
      ::hEdit := Nil
   ENDIF

   RETURN Nil
