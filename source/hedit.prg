
/*
 *$Id: hedit.prg,v 1.105 2008-10-23 12:42:00 lfbasso Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HEdit class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

STATIC lColorinFocus := .F.

#include "windows.ch" 
#include "hbclass.ch"
#include "hblang.ch"
#include "guilib.ch"

#ifndef GWL_STYLE
   #define GWL_STYLE           - 16
#endif

CLASS HEdit INHERIT HControl

CLASS VAR winclass   INIT "EDIT"
   DATA bColorOld
   DATA lMultiLine   INIT .F.
   DATA cType        INIT "C"
   DATA bSetGet
   DATA bValid
   DATA bkeydown, bkeyup, bchange
   DATA cPicFunc, cPicMask
   DATA lPicComplex    INIT .F.
   DATA lFirst         INIT .T.
   DATA lChanged       INIT .F.
   DATA nMaxLength     INIT Nil
   DATA nColorinFocus  INIT vcolor( 'CCFFFF' )

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
               oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, tcolor, bcolor, cPicture, lNoBorder, nMaxLength )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Redefine( oWnd, nId, vari, bSetGet, oFont, bInit, bSize, bDraw, bGfocus, ;
                    bLfocus, ctooltip, tcolor, bcolor, cPicture, nMaxLength, lMultiLine )
   METHOD Init()
   METHOD SetGet( value ) INLINE Eval( ::bSetGet, value, Self )
   METHOD Refresh()
   METHOD SetText( c )
   METHOD ParsePict( cPicture, vari ) 
   
   METHOD VarPut( value ) INLINE ::SetGet( value )
   METHOD VarGet() INLINE ::SetGet()

   METHOD IsEditable( nPos ) PROTECTED
   METHOD KeyRight( nPos ) PROTECTED
   METHOD KeyLeft( nPos ) PROTECTED
   METHOD DeleteChar( lBack ) PROTECTED
   METHOD Input( cChar, nPos ) PROTECTED
   METHOD GetApplyKey( cKey ) PROTECTED
   METHOD Valid() //PROTECTED BECAUSE IS CALL IN HDIALOG
   METHOD When() PROTECTED
   METHOD Change() PROTECTED
   METHOD IsBadDate( cBuffer ) PROTECTED
   METHOD Untransform( cBuffer ) PROTECTED
   METHOD FirstEditable() PROTECTED
   METHOD FirstNotEditable( nPos ) PROTECTED
   METHOD LastEditable() PROTECTED
   METHOD SetGetUpdated() PROTECTED

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
            oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, ;
            tcolor, bcolor, cPicture, lNoBorder, nMaxLength, lPassword, bKeyDown, bChange ) CLASS HEdit

   nStyle := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), ;
                        WS_TABSTOP + IIf( lNoBorder == Nil .OR. ! lNoBorder, WS_BORDER, 0 ) + ;
                        IIf( lPassword == Nil .or. ! lPassword, 0, ES_PASSWORD )  )

*   IF owndParent:oParent != Nil
      bPaint := {|o,p| o:paint(p)}
*   ENDIF

   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, IIf( bcolor == Nil, GetSysColor( COLOR_BTNHIGHLIGHT ), bcolor ) )

   IF vari != Nil
      ::cType   := ValType( vari )
   ENDIF
   IF bSetGet == Nil
      ::title := vari
   ENDIF
   ::bSetGet := bSetGet
   ::bKeyDown := bKeyDown
   IF Hwg_BitAnd( nStyle, ES_MULTILINE ) != 0
      ::style := Hwg_BitOr( ::style, ES_WANTRETURN )
      ::lMultiLine := .T.
   ENDIF
   IF ! Empty( cPicture ) .or. cPicture == Nil .And. nMaxLength != Nil .or. ! Empty( nMaxLength )
      ::nMaxLength := nMaxLength
   ENDIF
   IF ::cType == "N" .and. Hwg_BitAnd( nStyle, ES_LEFT + ES_CENTER ) == 0
      ::style := Hwg_BitOr( ::style, ES_RIGHT + ES_NUMBER )
      cPicture := IIF( cPicture == Nil.and.::nMaxLength != Nil,replicate("9",::nMaxLength),cPicture)
   ENDIF
   //IF ! Empty( cPicture ) .or. cPicture == Nil .And. nMaxLength != Nil .or. ! Empty( nMaxLength )
   //   ::nMaxLength := nMaxLength
   //ENDIF

   ::ParsePict( cPicture, vari )
   ::Activate()

   IF bSetGet != Nil
      ::bGetFocus := bGfocus
      ::bLostFocus := bLfocus
      IF bGfocus != Nil
         ::lnoValid := .T.
         ::oParent:AddEvent( EN_SETFOCUS, self, { | | ::When( ) },,"onGotFocus"  )
      ENDIF
      ::oParent:AddEvent( EN_KILLFOCUS, self, { | | ::Valid( ) },,"onLostFocus" )
      ::bValid := { | o | ::Valid( o ) }
   ELSE
      IF bGfocus != Nil
         ::oParent:AddEvent( EN_SETFOCUS, self, { | | ::When( ) },,"onGotFocus"  )
      ENDIF
      IF bLfocus != Nil
         ::oParent:AddEvent( EN_KILLFOCUS, self, { | | ::Valid( ) },,"onLostFocus" )
         ::bValid := { | o | ::Valid( o ) }
      ENDIF
   ENDIF
   IF bChange != Nil
      ::bChange := bChange
      ::oParent:AddEvent( EN_CHANGE, self,{| | ::Change( )},,"onChange"  )
   ENDIF
   ::bColorOld := ::bColor

   RETURN Self

METHOD Activate CLASS HEdit
   IF !empty( ::oParent:handle )
      ::handle := CreateEdit( ::oParent:handle, ::id, ;
                              ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF
   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HEdit
   LOCAL oParent := ::oParent, nPos, nctrl
   LOCAL nextHandle
   LOCAL cClipboardText := ""

   IF ::bOther != Nil
      IF Eval( ::bOther,Self,msg,wParam,lParam ) != -1
         RETURN 0
      ENDIF
   ENDIF

   IF ! ::lMultiLine

      IF ::bSetGet != Nil
         IF msg == WM_CHAR

            IF wParam == VK_BACK
               ::lFirst := .F.
               ::SetGetUpdated()
               ::DeleteChar( .T. )
               RETURN 0
            ELSEIF wParam == VK_RETURN .OR. wParam == VK_ESCAPE
               RETURN - 1
            ELSEIF wParam == VK_TAB
               RETURN 0
            ENDIF
            IF ! IsCtrlShift( , .F. )
               RETURN ::GetApplyKey( Chr( wParam ) )
            ENDIF
         ELSEIF msg == WM_PASTE
            cClipboardText := GetClipboardText()
            FOR nPos := 1 to len( cClipboardText )
                ::GetApplyKey( substr( cClipboardText, nPos, 1 ) )
            NEXT
            RETURN 0

         ELSEIF msg == WM_KEYDOWN
            IF ::bKeyDown != Nil .and. ValType( ::bKeyDown ) == 'B'
              ::oparent:lSuspendMsgsHandling := .T.              
              IF !Eval( ::bKeyDown, Self, wParam )
                  ::oparent:lSuspendMsgsHandling := .F.
                  RETURN 0
               ENDIF
               ::oparent:lSuspendMsgsHandling := .F.
            ENDIF

            IF wParam == 40     // KeyDown
               IF ! IsCtrlShift()
                  GetSkip( oParent, ::handle, , 1 )
                  RETURN 0
               ENDIF
            ELSEIF wParam == 38     // KeyUp
               IF ! IsCtrlShift()
                  GetSkip( oParent, ::handle, , -1 )
                  RETURN 0
               ENDIF
            ELSEIF wParam == 39     // KeyRight
               IF ! IsCtrlShift()
                  ::lFirst := .F.
                  RETURN ::KeyRight()
               ENDIF
            ELSEIF wParam == 37     // KeyLeft
               IF ! IsCtrlShift()
                  ::lFirst := .F.
                  RETURN ::KeyLeft()
               ENDIF
            ELSEIF wParam == 35     // End
               IF ! IsCtrlShift()
					   ::lFirst := .F.
                  IF ::cType == "C"
                     nPos := Len( Trim( ::title ) )
                     SendMessage( ::handle, EM_SETSEL, nPos, nPos )
                     RETURN 0
                  ENDIF
               ENDIF
            ELSEIF wParam == 45     // Insert
               IF ! IsCtrlShift()
                  SET( _SET_INSERT, ! SET( _SET_INSERT ) )
               ENDIF
            ELSEIF wParam == 46     // Del
               ::lFirst := .F.
               ::SetGetUpdated()
               ::DeleteChar( .F. )
               RETURN 0
            ELSEIF wParam == VK_TAB     // Tab
               GetSkip( oParent, ::handle, , ;
					        iif( IsCtrlShift(.f., .t.), -1, 1) )
               RETURN 0
            ELSEIF wParam == VK_RETURN  // Enter
               *GetSkip( oParent, ::handle, .T., 1 )
               RETURN 0
            ENDIF

         ELSEIF msg == WM_LBUTTONDOWN
            IF GetFocus() != ::handle
               SetFocus(::handle)
               RETURN 0
            ENDIF

         ELSEIF msg == WM_LBUTTONUP
            IF Empty( GetEditText( oParent:handle, ::id ) )
               SendMessage( ::handle, EM_SETSEL, 0, 0 )
            ENDIF

         ENDIF
      ELSE
         IF msg == WM_KEYDOWN
            IF wParam == VK_TAB     // Tab
               nexthandle := GetNextDlgTabItem ( GetActiveWindow(), GetFocus(), ;
					                                  IsCtrlShift(.f., .t.) )
               SetFocus( nexthandle )
               RETURN 0
            ENDIF
         ENDIF
      ENDIF
      IF lColorinFocus
         IF msg == WM_SETFOCUS
//            ::bColorOld := ::bcolor
            ::SetColor( ::tcolor , ::nColorinFocus, .T. )
         ELSEIF msg == WM_KILLFOCUS
            ::SetColor( ::tcolor, ::bColorOld, .t. )
         ENDIF
      ENDIF
   ELSE

      IF msg == WM_MOUSEWHEEL
         nPos := HIWORD( wParam )
         nPos := IIf( nPos > 32768, nPos - 65535, nPos )
         SendMessage( ::handle, EM_SCROLL, IIf( nPos > 0, SB_LINEUP, SB_LINEDOWN ), 0 )
         SendMessage( ::handle, EM_SCROLL, IIf( nPos > 0, SB_LINEUP, SB_LINEDOWN ), 0 )
      ENDIF
      IF msg == WM_KEYDOWN
         IF wParam == VK_ESCAPE
            return 0
         ENDIF
         IF wParam == VK_TAB     // Tab
            GetSkip( oParent, ::handle, , ;
				         iif( IsCtrlShift(.f., .t.), -1, 1) )
            RETURN 0
         ENDIF
      ENDIF
   ENDIF

   //IF msg == WM_KEYDOWN
   IF msg == WM_KEYUP .OR. msg == WM_SYSKEYUP     /* BETTER FOR DESIGNER */

            IF ::bKeyUp != Nil
              ::oparent:lSuspendMsgsHandling := .T.
              IF !Eval( ::bKeyUp,Self,wParam )
                  ::oparent:lSuspendMsgsHandling := .F.
                  RETURN -1
               ENDIF
            ENDIF
            ::oparent:lSuspendMsgsHandling := .F.
      IF wParam != 16 .AND. wParam != 17 .AND. wParam != 18
         DO WHILE oParent != Nil .AND. ! __ObjHasMsg( oParent, "GETLIST" )
            oParent := oParent:oParent
         ENDDO
         IF oParent != Nil .AND. ! Empty( oParent:KeyList )
            nctrl := IIf( IsCtrlShift(.t., .f.), FCONTROL, iif(IsCtrlShift(.f., .t.), FSHIFT, 0 ) )
            IF ( nPos := AScan( oParent:KeyList, { | a | a[ 1 ] == nctrl.AND.a[ 2 ] == wParam } ) ) > 0
               Eval( oParent:KeyList[ nPos, 3 ], Self )
            ENDIF
         ENDIF
      ENDIF
   ELSEIF msg == WM_GETDLGCODE
      IF ! ::lMultiLine
         RETURN DLGC_WANTARROWS + DLGC_WANTTAB + DLGC_WANTCHARS
      ENDIF
   ELSEIF msg == WM_DESTROY
      ::END()
   ENDIF

   RETURN - 1

METHOD Redefine( oWndParent, nId, vari, bSetGet, oFont, bInit, bSize, bPaint, ;
                 bGfocus, bLfocus, ctooltip, tcolor, bcolor, cPicture, nMaxLength, lMultiLine, bKeyDown, bChange )  CLASS HEdit


   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, IIf( bcolor == Nil, GetSysColor( COLOR_BTNHIGHLIGHT ), bcolor ) )
   ::bKeyDown := bKeyDown
   IF ValType( lMultiLine ) == "L"
      ::lMultiLine := lMultiLine
   ENDIF

   IF vari != Nil
      ::cType   := ValType( vari )
   ENDIF
   ::bSetGet := bSetGet

   IF ! Empty( cPicture ) .or. cPicture == Nil .And. nMaxLength != Nil .or. ! Empty( nMaxLength )
      ::nMaxLength := nMaxLength
   ENDIF

   ::ParsePict( cPicture, vari )

   IF bSetGet != Nil
      ::bGetFocus := bGfocus
      ::bLostFocus := bLfocus
      ::oParent:AddEvent( EN_SETFOCUS, self, { | | ::When( ) },,"onGotFocus" )
      ::oParent:AddEvent( EN_KILLFOCUS, self, { | | ::Valid( ) },,"onLostFocus" )
      ::bValid := { | | ::Valid() }
   ELSE
      IF bGfocus != Nil
         ::oParent:AddEvent( EN_SETFOCUS, self, bGfocus,,"onGotFocus"  )
      ENDIF
      IF bLfocus != Nil
         ::oParent:AddEvent( EN_KILLFOCUS, self, bLfocus,,"onLostFocus" )
      ENDIF
   ENDIF
   IF bChange != Nil
      ::oParent:AddEvent( EN_CHANGE, self, bChange,,"onChange"  )
   ENDIF
   ::bColorOld := ::bColor

   RETURN Self

METHOD Init()  CLASS HEdit

   IF ! ::lInit
      Super:Init()
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      Hwg_InitEditProc( ::handle )
      ::Refresh()
   ENDIF

   RETURN Nil

METHOD Refresh()  CLASS HEdit
   LOCAL vari

   IF ::bSetGet != Nil
      vari := Eval( ::bSetGet,, Self )
      IF ! Empty( ::cPicFunc ) .OR. ! Empty( ::cPicMask )
         vari := Transform( vari, ::cPicFunc + IIf( Empty( ::cPicFunc ), "", " " ) + ::cPicMask )
      ELSE
         vari := IIf( ::cType == "D", DToC( vari ), IIf( ::cType == "N", Str( vari ), IIf( ::cType == "C" .and. ValType(vari) == "C", Trim(vari), "" ) ) )
      ENDIF
      ::title := vari
      SetDlgItemText( ::oParent:handle, ::id, vari )
   ELSE
      SetDlgItemText( ::oParent:handle, ::id, ::title )
   ENDIF

   RETURN Nil

METHOD SetText( c ) CLASS HEdit

   IF c != Nil
      IF ValType( c ) = "O"
         //in run time return object
         RETURN nil
      ENDIF
      IF ! Empty( ::cPicFunc ) .OR. ! Empty( ::cPicMask )
         ::title := Transform( c, ::cPicFunc + IIf( Empty( ::cPicFunc ), "", " " ) + ::cPicMask )
      ELSE
         ::title := c
      ENDIF
      Super:SetText( ::title )
      IF ::bSetGet != Nil
         Eval( ::bSetGet, c, Self )
      ENDIF
   ENDIF
   ::REFRESH()

   RETURN NIL

FUNCTION IsCtrlShift( lCtrl, lShift )
   LOCAL cKeyb := GetKeyboardState()

   IF lCtrl == Nil ; lCtrl := .T. ; ENDIF
   IF lShift == Nil ; lShift := .T. ; ENDIF
   RETURN ( lCtrl .AND. ( Asc( SubStr( cKeyb, VK_CONTROL + 1, 1 ) ) >= 128 ) ) .OR. ;
   ( lShift .AND. ( Asc( SubStr( cKeyb, VK_SHIFT + 1, 1 ) ) >= 128 ) )

METHOD ParsePict( cPicture, vari ) CLASS HEdit
   LOCAL nAt, i, masklen, cChar

   IF ::bSetGet == Nil
      RETURN Nil
   ENDIF
   ::cPicFunc := ::cPicMask := ""
   IF cPicture != Nil
      IF Left( cPicture, 1 ) == "@"
         nAt := At( " ", cPicture )
         IF nAt == 0
            ::cPicFunc := Upper( cPicture )
            ::cPicMask := ""
         ELSE
            ::cPicFunc := Upper( SubStr( cPicture, 1, nAt - 1 ) )
            ::cPicMask := SubStr( cPicture, nAt + 1 )
         ENDIF
         IF ::cPicFunc == "@"
            ::cPicFunc := ""
         ENDIF
      ELSE
         ::cPicFunc   := ""
         ::cPicMask   := cPicture
      ENDIF
   ENDIF

   IF Empty( ::cPicMask )
      IF ::cType == "D"
         ::cPicMask := StrTran( DToC( CToD( Space( 8 ) ) ), ' ', '9' )
      ELSEIF ::cType == "N"
         vari := Str( vari )
         IF ( nAt := At( ".", vari ) ) > 0
            ::cPicMask := Replicate( '9', nAt - 1 ) + "." + ;
                              Replicate( '9', Len( vari ) - nAt )
         ELSE
            ::cPicMask := Replicate( '9', Len( vari ) )
         ENDIF
      ENDIF
   ENDIF

   IF ! Empty( ::cPicMask )
      masklen := Len( ::cPicMask )
      FOR i := 1 TO masklen
         cChar := SubStr( ::cPicMask, i, 1 )
         IF ! cChar $ "!ANX9#"
            ::lPicComplex := .T.
            EXIT
         ENDIF
      NEXT
   ENDIF
   RETURN Nil

METHOD IsEditable( nPos ) CLASS HEdit
   LOCAL cChar

   IF Empty( ::cPicMask )
      RETURN .T.
   ENDIF
   IF nPos > Len( ::cPicMask )
      RETURN .F.
   ENDIF

   cChar := SubStr( ::cPicMask, nPos, 1 )

   IF ::cType == "C"
      RETURN cChar $ "!ANX9#"
   ELSEIF ::cType == "N"
      RETURN cChar $ "9#$*"
   ELSEIF ::cType == "D"
      RETURN cChar == "9"
   ELSEIF ::cType == "L"
      RETURN cChar $ "TFYN"
   ENDIF

   RETURN .F.

METHOD KeyRight( nPos ) CLASS HEdit
   LOCAL masklen, newpos

   IF nPos == Nil
      nPos := HIWORD( SendMessage( ::handle, EM_GETSEL, 0, 0 ) ) + 1
   ENDIF
   IF ::cPicMask == Nil .OR. Empty( ::cPicMask )
      SendMessage( ::handle, EM_SETSEL, nPos, nPos )
   ELSE
      masklen := Len( ::cPicMask )
      DO WHILE nPos <= masklen
         IF ::IsEditable( ++ nPos )
            SendMessage( ::handle, EM_SETSEL, nPos - 1, nPos - 1 )
            EXIT
         ENDIF
      ENDDO
   ENDIF

   //Added By Sandro Freire

   IF ! Empty( ::cPicMask )
      newpos := Len( ::cPicMask )
      //writelog( "KeyRight-2 "+str(nPos) + " " +str(newPos) )
      IF nPos > newpos .and. ! Empty( Trim( ::Title ) )
         SendMessage( ::handle, EM_SETSEL, newpos, newpos )
      ENDIF
   ENDIF

   RETURN 0

METHOD KeyLeft( nPos ) CLASS HEdit

   IF nPos == Nil
      nPos := HIWORD( SendMessage( ::handle, EM_GETSEL, 0, 0 ) ) + 1
   ENDIF
   IF ::cPicMask == Nil .OR. Empty( ::cPicMask )
      SendMessage( ::handle, EM_SETSEL, nPos - 2, nPos - 2 )
   ELSE
      DO WHILE nPos >= 1
         IF ::IsEditable( -- nPos )
            SendMessage( ::handle, EM_SETSEL, nPos - 1, nPos - 1 )
            EXIT
         ENDIF
      ENDDO
   ENDIF
   RETURN 0

METHOD DeleteChar( lBack ) CLASS HEdit
   LOCAL nSel := SendMessage( ::handle, EM_GETSEL, 0, 0 )
   LOCAL nPosEnd   := HIWORD( nSel )
   LOCAL nPosStart := LOWORD( nSel )
   LOCAL nGetLen := Len( ::cPicMask )
   LOCAL cBuf, nPosEdit

   IF Hwg_BitAnd( GetWindowLong( ::handle, GWL_STYLE ), ES_READONLY ) != 0
      RETURN Nil
   ENDIF
   IF nGetLen == 0
      nGetLen := Len( ::title )
   ENDIF
   IF nPosEnd == nPosStart
      nPosEnd += IIf( lBack, 1, 2 )
      nPosStart -= IIf( lBack, 1, 0 )
   ELSE
      nPosEnd += 1
   ENDIF
   IF Empty(SendMessage(::handle, EM_GETPASSWORDCHAR, 0, 0))
      cBuf := PadR( Left( ::title, nPosStart ) + SubStr( ::title, nPosEnd ), nGetLen )
   ELSE
      cBuf := Left( ::title, nPosStart ) + SubStr( ::title, nPosEnd )
   ENDIF
   IF ::lPicComplex .AND. ::cType <> "N" .and. ;
      ( nPosStart + nPosEnd > 0 )
      IF lBack .or. nPosStart <> ( nPosEnd - 2 )
         cBuf := Left( ::title, nPosStart ) + Space( nPosEnd - nPosStart - 1 ) + SubStr( ::title, nPosEnd )
      ELSE
         nPosEdit := ::FirstNotEditable( nPosStart + 1 )
         IF nPosEdit > 0
            cBuf := Left( ::title, nPosStart ) + if(::IsEditable(nposStart+2),SubStr( ::title, nPosStart + 2, 1 ) + "  " ,"  ")+ SubStr( ::title, nPosEdit + 1 )
         ELSE
            cBuf := Left( ::title, nPosStart ) + SubStr( ::title, nPosStart + 2 ) + Space( nPosEnd - nPosStart - 1 )
         ENDIF
      ENDIF
      cBuf := Transform( cBuf, ::cPicMask )
   ENDIF

   ::title := cBuf
   SetDlgItemText( ::oParent:handle, ::id, ::title )
   SendMessage( ::handle, EM_SETSEL, nPosStart, nPosStart )
   RETURN Nil


METHOD Input( cChar, nPos ) CLASS HEdit
   LOCAL cPic

   IF ! Empty( ::cPicMask ) .AND. nPos > Len( ::cPicMask )
      RETURN Nil
   ENDIF
   IF ::cType == "N"
      IF cChar == "-"
         IF nPos != 1
            RETURN Nil
         ENDIF
      ELSEIF ! ( cChar $ "0123456789" )
         RETURN Nil
      ENDIF

   ELSEIF ::cType == "D"

      IF ! ( cChar $ "0123456789" )
         RETURN Nil
      ENDIF

   ELSEIF ::cType == "L"

      IF ! ( Upper( cChar ) $ "YNTF" )
         RETURN Nil
      ENDIF

   ENDIF

   IF ! Empty( ::cPicFunc )
      cChar := Transform( cChar, ::cPicFunc )
   ENDIF

   IF ! Empty( ::cPicMask )
      cPic  := SubStr( ::cPicMask, nPos, 1 )

      cChar := Transform( cChar, cPic )
      IF cPic == "A"
         IF ! IsAlpha( cChar )
            cChar := Nil
         ENDIF
      ELSEIF cPic == "N"
         IF ! IsAlpha( cChar ) .and. ! IsDigit( cChar )
            cChar := Nil
         ENDIF
      ELSEIF cPic == "9"
         IF ! IsDigit( cChar ) .and. cChar != "-"
            cChar := Nil
         ENDIF
      ELSEIF cPic == "#"
         IF ! IsDigit( cChar ) .and. ! ( cChar == " " ) .and. ! ( cChar $ "+-" )
            cChar := Nil
         ENDIF
      ELSE
         cChar:= Transform( cChar, cPic )
      ENDIF
   ENDIF

   RETURN cChar

METHOD GetApplyKey( cKey ) CLASS HEdit
   LOCAL nPos, nGetLen, nLen, vari, i, x, newPos
   LOCAL nDecimals

   /* AJ: 11-03-2007 */
   IF Hwg_BitAnd( GetWindowLong( ::handle, GWL_STYLE ), ES_READONLY ) != 0
      RETURN 0
   ENDIF

   x := SendMessage( ::handle, EM_GETSEL, 0, 0 )
   IF HIWORD( x ) != LOWORD( x )
      ::DeleteChar( .f. )
   ENDIF

   ::title := GetEditText( ::oParent:handle, ::id )
   IF ::cType == "N" .and. cKey $ ".," .AND. ;
      ( nPos := At( ".", ::cPicMask ) ) != 0
      IF ::lFirst
         vari := 0
      ELSE
         vari := Trim( ::title )
         FOR i := 2 TO Len( vari )
            IF ! IsDigit( SubStr( vari, i, 1 ) )
               vari := Left( vari, i - 1 ) + SubStr( vari, i + 1 )
            ENDIF
         NEXT
         vari := Val( vari )
      ENDIF
      IF ! Empty( ::cPicFunc ) .OR. ! Empty( ::cPicMask )
         ::title := Transform( vari, ::cPicFunc + IIf( Empty( ::cPicFunc ), "", " " ) + ::cPicMask )
      ENDIF
      SetDlgItemText( ::oParent:handle, ::id, ::title )
      ::KeyRight( nPos - 1 )
   ELSE

      IF ::cType == "N" .AND. ::lFirst
         nGetLen := Len( ::cPicMask )
         IF ( nPos := At( ".", ::cPicMask ) ) == 0
            ::title := Space( nGetLen )
         ELSE
            ::title := Space( nPos - 1 ) + "." + Space( nGetLen - nPos )
         ENDIF
         nPos := 1
      ELSE
         nPos := HIWORD( SendMessage( ::handle, EM_GETSEL, 0, 0 ) ) + 1
      ENDIF
      cKey := ::Input( cKey, nPos )
      IF cKey != Nil
         ::SetGetUpdated()
         IF SET( _SET_INSERT ) .or. HIWORD( x ) != LOWORD( x )
            IF ::lPicComplex
               nGetLen := Len( ::cPicMask )
               FOR nLen := 0 TO nGetLen
                  IF ! ::IsEditable( nPos + nLen )
                     EXIT
                  ENDIF
               NEXT
               ::title := Left( ::title, nPos - 1 ) + cKey + ;
                              SubStr( ::title, nPos, nLen - 1 ) + SubStr( ::title, nPos + nLen )
            ELSE
               ::title := Left( ::title, nPos - 1 ) + cKey + ;
                              SubStr( ::title, nPos )
            ENDIF

            IF ! Empty( ::cPicMask ) .AND. Len( ::cPicMask ) < Len( ::title )
               ::title := Left( ::title, nPos - 1 ) + cKey + SubStr( ::title, nPos + 1 )
            ENDIF
         ELSE
            ::title := Left( ::title, nPos - 1 ) + cKey + SubStr( ::title, nPos + 1 )
         ENDIF
         IF !Empty(SendMessage(::handle, EM_GETPASSWORDCHAR, 0, 0))
          ::title := Left( ::title, nPos - 1 ) + cKey + Trim( SubStr( ::title, nPos + 1 ) )
         ELSEIF !Empty(::nMaxLength)
            ::title := PadR( ::title, ::nMaxLength )
         ENDIF
         SetDlgItemText( ::oParent:handle, ::id, ::title )
         ::KeyRight( nPos )
         //Added By Sandro Freire
         IF ::cType == "N"

            IF ! Empty( ::cPicMask )

               nDecimals := Len( SubStr(  ::cPicMask, At( ".", ::cPicMask ), Len( ::cPicMask ) ) )

               IF nDecimals <= 0
                  nDecimals := 3
               ENDIF
               newPos := Len( ::cPicMask ) - nDecimals

               IF "E" $ ::cPicFunc .AND. nPos == newPos
                  ::GetApplyKey( "," )
               ENDIF
            ENDIF

         ENDIF

      ENDIF
   ENDIF
   ::lFirst := .F.

   RETURN 0

METHOD When() CLASS HEdit
  LOCAL res := .t., oParent, nSkip

	IF !CheckFocus(self, .f.)
	   RETURN .F.
	ENDIF
  ::lFirst := .T.
  IF ::bGetFocus != Nil
      ::oparent:lSuspendMsgsHandling := .T.
      ::lnoValid := .T.
      res := Eval( ::bGetFocus, ::title, Self )
      res := IIF(VALTYPE(res) == "L", res, .T.)
      ::lnoValid := ! res
      IF ! res
         oParent := ParentGetDialog(self)
         IF Self == ATail(oParent:GetList)
            nSkip := -1
         ELSEIF Self == oParent:getList[1]
            nSkip := 1
         ENDIF
         GetSkip( ::oParent, ::handle, , nSkip )
      ENDIF
      ::oparent:lSuspendMsgsHandling := .F.
   ENDIF
RETURN res

METHOD Valid( ) CLASS HEdit
  LOCAL res, vari, oDlg

	IF ::bLostFocus != Nil .AND. (::lNoValid .OR. !CheckFocus(Self, .T.))
	   RETURN .t.
	ENDIF
   IF ::bSetGet != Nil
      IF ( oDlg := ParentGetDialog( Self ) ) == Nil .OR. oDlg:nLastKey != 27
         vari := ::UnTransform( GetEditText( ::oParent:handle, ::id ) )
         ::title := vari
         IF ::cType == "D"
            IF ::IsBadDate( vari )
               SetFocus( ::handle )
               RETURN .F.
            ENDIF
            vari := CToD( vari )
         ELSEIF ::cType == "N"
            vari := Val( LTrim( vari ) )
            ::title := Transform( vari, ::cPicFunc + IIf( Empty( ::cPicFunc ), "", " " ) + ::cPicMask )
            SetDlgItemText( ::oParent:handle, ::id, ::title )
         ENDIF
         Eval( ::bSetGet, vari, self )
         IF oDlg != Nil
            oDlg:nLastKey := 27
         ENDIF
         IF ::bLostFocus != Nil
            ::oparent:lSuspendMsgsHandling := .T.
            res := Eval( ::bLostFocus, vari, Self )
            if VALTYPE(res) = "L" .AND. ! res
               IF oDlg != Nil
                  oDlg:nLastKey := 0
               ENDIF
               ::SetFocus()
               ::oparent:lSuspendMsgsHandling := .F.
               RETURN .F.
            endif
         ENDIF
         IF oDlg != Nil
            oDlg:nLastKey := 0
         ENDIF
       IF empty(GetFocus())
		   GetSkip( ::oParent, ::handle,,::nGetSkip)
		 ENDIF
      ENDIF
   ELSEIF ::bLostFocus != Nil
      ::oparent:lSuspendMsgsHandling := .T.
      res := Eval( ::bLostFocus, vari, Self )
      IF ! res
         ::SetFocus()
         ::oparent:lSuspendMsgsHandling := .F.
         RETURN .F.
      ENDIF
      IF emptY(GetFocus())
	      GetSkip( ::oParent, ::handle,,::nGetSkip)
		ENDIF
   ENDIF
   ::oparent:lSuspendMsgsHandling := .F.
   RETURN .T.
   
METHOD Change( ) CLASS HEdit
LOCAL  nPos := HIWORD( SendMessage( ::handle, EM_GETSEL, 0, 0 ) ) + 1

 	 IF !CheckFocus(self, .T.)
	    RETURN .t.
 	 ENDIF

   ::oparent:lSuspendMsgsHandling := .T.
   Eval( ::bChange, ::title, Self )
   ::oparent:lSuspendMsgsHandling := .F.
   
   SendMessage( ::handle,  EM_SETSEL, 0, nPos )

RETURN Nil
   

METHOD Untransform( cBuffer ) CLASS HEdit
   LOCAL xValue, cChar, nFor, minus

   IF ::cType == "C"

      IF "R" $ ::cPicFunc
         FOR nFor := 1 TO Len( ::cPicMask )
            cChar := SubStr( ::cPicMask, nFor, 1 )
            IF ! cChar $ "ANX9#!"
               cBuffer := SubStr( cBuffer, 1, nFor - 1 ) + Chr( 1 ) + SubStr( cBuffer, nFor + 1 )
            ENDIF
         NEXT
         cBuffer := StrTran( cBuffer, Chr( 1 ), "" )
      ENDIF

      xValue := cBuffer

   ELSEIF ::cType == "N"
      minus := ( Left( LTrim( cBuffer ), 1 ) == "-" )
      cBuffer := Space( ::FirstEditable() - 1 ) + SubStr( cBuffer, ::FirstEditable(), ::LastEditable() - ::FirstEditable() + 1 )

      IF "D" $ ::cPicFunc
         FOR nFor := ::FirstEditable() TO ::LastEditable()
            IF ! ::IsEditable( nFor )
               cBuffer = Left( cBuffer, nFor - 1 ) + Chr( 1 ) + SubStr( cBuffer, nFor + 1 )
            ENDIF
         NEXT
      ELSE
         IF "E" $ ::cPicFunc
            cBuffer := Left( cBuffer, ::FirstEditable() - 1 ) +           ;
                       StrTran( SubStr( cBuffer, ::FirstEditable(),      ;
                                        ::LastEditable() - ::FirstEditable() + 1 ), ;
                                ".", " " ) + SubStr( cBuffer, ::LastEditable() + 1 )
            cBuffer := Left( cBuffer, ::FirstEditable() - 1 ) +           ;
                       StrTran( SubStr( cBuffer, ::FirstEditable(),      ;
                                        ::LastEditable() - ::FirstEditable() + 1 ), ;
                                ",", "." ) + SubStr( cBuffer, ::LastEditable() + 1 )
         ELSE
            cBuffer := Left( cBuffer, ::FirstEditable() - 1 ) +        ;
                       StrTran( SubStr( cBuffer, ::FirstEditable(),   ;
                                        ::LastEditable() - ::FirstEditable() + 1 ), ;
                                ",", " " ) + SubStr( cBuffer, ::LastEditable() + 1 )
         ENDIF

         FOR nFor := ::FirstEditable() TO ::LastEditable()
            IF ! ::IsEditable( nFor ) .and. SubStr( cBuffer, nFor, 1 ) != "."
               cBuffer = Left( cBuffer, nFor - 1 ) + Chr( 1 ) + SubStr( cBuffer, nFor + 1 )
            ENDIF
         NEXT
      ENDIF

      cBuffer := StrTran( cBuffer, Chr( 1 ), "" )

      cBuffer := StrTran( cBuffer, "$", " " )
      cBuffer := StrTran( cBuffer, "*", " " )
      cBuffer := StrTran( cBuffer, "-", " " )
      cBuffer := StrTran( cBuffer, "(", " " )
      cBuffer := StrTran( cBuffer, ")", " " )

      cBuffer := PadL( StrTran( cBuffer, " ", "" ), Len( cBuffer ) )

      IF minus
         FOR nFor := 1 TO Len( cBuffer )
            IF IsDigit( SubStr( cBuffer, nFor, 1 ) )
               EXIT
            ENDIF
         NEXT
         nFor --
         IF nFor > 0
            cBuffer := Left( cBuffer, nFor - 1 ) + "-" + SubStr( cBuffer, nFor + 1 )
         ELSE
            cBuffer := "-" + cBuffer
         ENDIF
      ENDIF

      xValue := cBuffer

   ELSEIF ::cType == "L"

      cBuffer := Upper( cBuffer )
      xValue := "T" $ cBuffer .or. "Y" $ cBuffer .or. hb_langmessage( HB_LANG_ITEM_BASE_TEXT + 1 ) $ cBuffer

   ELSEIF ::cType == "D"

      IF "E" $ ::cPicFunc
         cBuffer := SubStr( cBuffer, 4, 3 ) + SubStr( cBuffer, 1, 3 ) + SubStr( cBuffer, 7 )
      ENDIF
      xValue := cBuffer

   ENDIF

   RETURN xValue

METHOD FirstEditable( ) CLASS HEdit
   LOCAL nFor, nMaxLen := Len( ::cPicMask )

   IF ::IsEditable( 1 )
      RETURN 1
   ENDIF

   FOR nFor := 2 TO nMaxLen
      IF ::IsEditable( nFor )
         RETURN nFor
      ENDIF
   NEXT

   RETURN 0

METHOD FirstNotEditable( nPos ) CLASS HEdit
   LOCAL nFor, nMaxLen := Len( ::cPicMask )

   FOR nFor := ++ nPos TO nMaxLen
      IF ! ::IsEditable( nFor )
         RETURN nFor
      ENDIF
   NEXT

   RETURN 0

METHOD LastEditable() CLASS HEdit
   LOCAL nFor, nMaxLen := Len( ::cPicMask )

   FOR nFor := nMaxLen TO 1 STEP - 1
      IF ::IsEditable( nFor )
         RETURN nFor
      ENDIF
   NEXT

   RETURN 0

METHOD IsBadDate( cBuffer ) CLASS HEdit
   LOCAL i, nLen

   IF ! Empty( CToD( cBuffer ) )
      RETURN .F.
   ENDIF
   nLen := Len( cBuffer )
   FOR i := 1 TO nLen
      IF IsDigit( SubStr( cBuffer, i, 1 ) )
         RETURN .T.
      ENDIF
   NEXT
   RETURN .F.

FUNCTION CreateGetList( oDlg )
   LOCAL i, j, aLen1 := Len( oDlg:aControls ), aLen2

   FOR i := 1 TO aLen1
      IF __ObjHasMsg( oDlg:aControls[ i ], "BSETGET" ) .AND. oDlg:aControls[ i ]:bSetGet != Nil
         AAdd( oDlg:GetList, oDlg:aControls[ i ] )
      ELSEIF ! Empty( oDlg:aControls[ i ]:aControls )
         aLen2 := Len( oDlg:aControls[ i ]:aControls )
         FOR j := 1 TO aLen2
            IF __ObjHasMsg( oDlg:aControls[ i ]:aControls[ j ], "BSETGET" ) .AND. oDlg:aControls[ i ]:aControls[ j ]:bSetGet != Nil
               AAdd( oDlg:GetList, oDlg:aControls[ i ]:aControls[ j ] )
            ENDIF
         NEXT
      ENDIF
   NEXT
   RETURN Nil

FUNCTION GetSkip( oParent, hCtrl, lClipper, nSkip )
   LOCAL i, nextHandle, oCtrl 

   DEFAULT nSkip := 1

   IF oParent == Nil .OR. ( lClipper != Nil .AND. lClipper .AND. ! oParent:lClipper )
      RETURN .F.
   ENDIF
   i := AScan( oparent:acontrols, { | o | o:handle == hCtrl } )
   oCtrl := IIF( i > 0, oparent:acontrols[i], oParent)
   nextHandle := iif(oParent:className == "HTAB", NextFocusTab(oParent, hCtrl, nSkip), ;
	                                               NextFocus(oParent, hCtrl, nSkip))
	 IF i > 0
	   oCtrl:nGetSkip := nSkip
	 ENDIF  
   IF !empty(nextHandle)
	   IF oParent:classname == "HDIALOG"
	       PostMessage( oParent:handle, WM_NEXTDLGCTL, nextHandle, 1 )
	   ELSE
       IF oParent:handle == getfocus()
          PostMessage( GetActiveWindow(), WM_NEXTDLGCTL, nextHandle, 1 )
       ELSE
			 PostMessage( oParent:handle, WM_NEXTDLGCTL, nextHandle, 1 )
       ENDIF
     ENDIF 
   ENDIF

RETURN .T.

STATIC FUNCTION NextFocusTab(oParent, hCtrl, nSkip)
   Local nextHandle := 0, i, nPage, nFirst , nLast , k := 0
   
   IF LEN(oParent:aPages) > 0
      //SETFOCUS(oParent:handle)
      oParent:SETFOCUS()
      nPage := oParent:GetActivePage(@nFirst, @nLast)
      IF !oParent:lResourceTab  && TAB without RC
      	i :=  AScan( oParent:acontrols, { | o | o:handle == hCtrl } )
      	i += IIF( i == 0, nFirst, nSkip) //nLast, nSkip)
      	IF i >= nFirst .and. i <= nLast
           nexthandle := GetNextDlgTabItem ( oParent:handle , hctrl, ( nSkip < 0 ) )
          IF  i != AScan( oParent:acontrols, { | o | o:handle == NEXTHANDLE } ) .AND. oParent:acontrols[ i ]:CLASSNAME = "HRADIO"
             nexthandle := GetNextDlgGroupItem( oParent:handle , hctrl,( nSkip < 0 ) )
          ENDIF
          k := AScan( oParent:acontrols, { | o | o:handle == NEXTHANDLE } )
      	ENDIF
      ELSE
      	SETFOCUS(oParent:aPages[nPage,1]:aControls[1]:Handle)
        RETURN 0
			ENDIF	
      IF (nSkip < 0 .AND. ( k > i .OR. k == 0)) .OR. (nSkip > 0 .AND. i > k)
        nexthandle := GetNextDlgTabItem ( GetActiveWindow(), hctrl, (nSkip < 0) )
      ENDIF
   ENDIF
RETURN nextHandle

STATIC FUNCTION NextFocus(oParent,hCtrl,nSkip)
Local nextHandle :=0,  i

   IF oParent:Type == WND_DLG_RESOURCE
      nexthandle := GetNextDlgGroupItem( oParent:handle , hctrl,( nSkip < 0 ) )
      RETURN nextHandle
   ENDIF

   i := AScan( oparent:acontrols, { | o | o:handle == hCtrl } )
   IF i > 0 .AND. oParent:acontrols[ i ]:CLASSNAME = "HRADIO"
       nexthandle := GetNextDlgGroupItem( oParent:handle , hctrl,( nSkip < 0 ) )
	ELSE
       nextHandle := GetNextDlgTabItem ( GetActiveWindow() , hctrl, ( nSkip < 0 ) )
   ENDIF
//    i := AScan( oparent:acontrols, { | o | o:handle == nexthandle } )

RETURN nextHandle

METHOD SetGetUpdated() CLASS HEdit

   LOCAL oParent

   ::lChanged := .T.
   IF ( oParent := ParentGetDialog( Self ) ) != Nil
      oParent:lUpdated := .T.
   ENDIF

   RETURN Nil

FUNCTION ParentGetDialog( o )
   DO WHILE ( o := o:oParent ) != Nil .and. ! __ObjHasMsg( o, "GETLIST" )
   ENDDO
   RETURN o

FUNCTION SetColorinFocus( lDef )
   IF ValType( lDef ) <> "L"
      RETURN .F.
   ENDIF
   lColorinFocus := lDef
   RETURN .T.

/*
Luis Fernando Basso contribution
*/

/** CheckFocus
* check focus of controls before calling events
*/
FUNCTION CheckFocus(oCtrl, nInside)
Local oParent := ParentGetDialog(oCtrl)

  IF (oParent  != Nil .AND. !IsWindowVisible(oParent:handle)) .OR. empty(GetActiveWindow()) // == 0 
    IF !nInside .and. empty(oParent:nInitFocus) // = 0
       oParent:Show()
       SetFocus(oParent:handle)
       SetFocus(GetFocus()) 
	  ENDIF
    RETURN .F.
  ENDIF
  IF oParent  != Nil .AND. nInside 
     IF GETFOCUS() = oCtrl:oParent:Handle .AND. oParent:handle = oCtrl:oParent:Handle 
       RETURN .F.
     ENDIF   
  ENDIF
RETURN .T.

