/*
 *$Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HEdit class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hbclass.ch"
#include "hblang.ch"

#define WM_IME_CHAR      646

STATIC lColorinFocus := .F.
STATIC tColorinFocus := 0
STATIC bColorinFocus := 16777164

CLASS HEdit INHERIT HControl

   CLASS VAR winclass  INIT "EDIT"
   DATA lMultiLine     INIT .F.
   DATA cType INIT "C"
   DATA bSetGet
   DATA oPicture
   DATA bValid
   DATA lFirst         INIT .T.
   DATA lChanged       INIT .F.
   DATA lNoPaste       INIT .F.
   DATA nMaxLength     INIT Nil
   DATA bkeydown, bkeyup, bchange
   DATA aColorOld      INIT { 0,0 }
   DATA bColorBlock

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bGfocus, bLfocus, ctooltip, ;
      tcolor, bcolor, cPicture, lNoBorder, nMaxLength, lPassword, bKeyDown, bChange )
   METHOD Activate()
   METHOD Init()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Redefine( oWndParent, nId, vari, bSetGet, oFont, bInit, bSize, bGfocus, ;
      bLfocus, ctooltip, tcolor, bcolor, cPicture, nMaxLength )
   METHOD SetGet( value ) INLINE Eval( ::bSetGet, value, self )
   METHOD Refresh()
   METHOD Value ( xValue ) SETGET
   METHOD SelStart( nStart ) SETGET
   METHOD SelLength( nLength ) SETGET

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bGfocus, bLfocus, ctooltip, ;
      tcolor, bcolor, cPicture, lNoBorder, nMaxLength, lPassword, bKeyDown, bChange ) CLASS HEdit

   nStyle := Hwg_BitOr( iif( nStyle == Nil,0,nStyle ), ;
      WS_TABSTOP + iif( lNoBorder == Nil .OR. !lNoBorder, WS_BORDER, 0 ) + ;
      iif( lPassword == Nil .OR. !lPassword, 0, ES_PASSWORD )  )

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize,, ctooltip, Iif(tcolor==Nil,0,tcolor), Iif(bcolor==Nil,hwg_Getsyscolor(COLOR_BTNHIGHLIGHT),bcolor) )

   ::cType := ValType( vari )
   ::title := vari
   ::bSetGet := bSetGet
   ::bKeyDown := bKeyDown

   IF Hwg_BitAnd( nStyle, ES_MULTILINE ) != 0
      ::style := Hwg_BitOr( ::style, ES_WANTRETURN )
      ::lMultiLine := .T.
   ENDIF

   IF !Empty( cPicture ) .OR. ::cType != "C" .OR. !Empty( bSetGet )
      ::oPicture := HPicture():New( cPicture, vari, nMaxLength )
      ::nMaxLength := ::oPicture:nMaxLength
   ENDIF

/*
   IF !Empty( cPicture ) .OR. ::cType != "C"
      ::oPicture := HPicture():New( cPicture, vari )
      ::nMaxLength := ::oPicture:nMaxLength
   ENDIF
   IF Empty( ::nMaxLength ) .AND. !Empty( ::bSetGet ) .AND. Valtype( vari ) == "C"
      ::nMaxLength := hwg_Len( vari )
   ENDIF
   IF nMaxLength != Nil
      ::nMaxLength := nMaxLength
   ENDIF
*/
   ::Activate()

   IF bSetGet != Nil
      ::bGetFocus := bGFocus
      ::bLostFocus := bLFocus
      ::oParent:AddEvent( EN_SETFOCUS, ::id, { |o, id|__When( o:FindControl(id ) ) }  )
      ::oParent:AddEvent( EN_KILLFOCUS, ::id, { |o, id|__Valid( o:FindControl(id ) ) } )
      ::bValid := { |o|__Valid( o ) }
   ELSE
      IF bGfocus != Nil
         ::oParent:AddEvent( EN_SETFOCUS, ::id, bGfocus )
      ENDIF
      IF bLfocus != Nil
         ::oParent:AddEvent( EN_KILLFOCUS, ::id, bLfocus )
      ENDIF
   ENDIF
   ::bChange := bChange

   ::aColorOld[1] := iif( tcolor = Nil, 0, ::tcolor )
   ::aColorOld[2] := ::bcolor

   RETURN Self

METHOD Activate() CLASS HEdit

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createedit( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF

   RETURN Nil

METHOD Init()  CLASS HEdit

   IF !::lInit
      ::Super:Init()
      ::nHolder := 1
      hwg_Setwindowobject( ::handle, Self )
      Hwg_InitEditProc( ::handle )
      ::Refresh()
      IF ::bChange != Nil
         ::oParent:AddEvent( EN_CHANGE, ::id, ::bChange  )
      ENDIF
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HEdit

   LOCAL oParent := ::oParent, nPos, cText, cClipboardText
   LOCAL nexthandle, i

   IF ::bOther != Nil .AND. ( nPos := Eval( ::bOther, Self, msg, wParam, lParam ) ) != - 1
      RETURN nPos
   ENDIF
   wParam := hwg_PtrToUlong( wParam )
   IF !::lMultiLine

      IF ::bSetGet != Nil .OR. !Empty( ::oPicture )
         IF msg == WM_CHAR
            IF wParam == VK_BACK
               ::lFirst := .F.
               hwg_SetGetUpdated( Self )
               IF !Empty( ::oPicture ) .AND. ::oPicture:lPicComplex
                  nPos := hwg_edit_GetPos( ::handle ) - 1
                  IF nPos > 0
                     cText := ::oPicture:Delete( hwg_Getedittext( ::oParent:handle, ::id ), @nPos )
                     IF nPos > 0
                        hwg_Setwindowtext( ::handle, ::title := cText )
                        hwg_edit_Setpos( ::handle, nPos )
                     ENDIF
                  ENDIF
                  RETURN 0
               ENDIF
               Return - 1
            ELSEIF wParam == VK_RETURN .OR. wParam == VK_ESCAPE
               Return - 1
            ELSEIF wParam == VK_TAB
               RETURN 0
            ENDIF
            IF !hwg_IsCtrlShift( , .F. )
               DeleteSel( Self )
               nPos := i := hwg_edit_Getpos( ::handle )
               ::title := cText := hwg_Getedittext( ::oParent:handle, ::id )
               cText := ::oPicture:GetApplyKey( cText, @nPos, hwg_Chr(wParam), ::lFirst, Set( _SET_INSERT ) )
               ::lFirst := .F.
               IF !( cText == ::title )
                  hwg_Setwindowtext( ::handle, ::title := cText )
                  hwg_SetGetUpdated( Self )
               ENDIF
               hwg_edit_SetPos( ::handle, nPos )
               IF ::cType != "N" .AND. !Set( _SET_CONFIRM ) .AND. ;
                  i == ::nMaxLength .AND. !Empty( ::bSetGet )
                  IF !hwg_GetSkip( oParent := ::oParent, ::handle, 1 )
                     DO WHILE oParent != Nil .AND. !__ObjHasMsg( oParent, "GETLIST" )
                        oParent := oParent:oParent
                     ENDDO
                     hwg_DlgCommand( oParent, hwg_MakeWParam( IDOK, 0 ) )
                  ENDIF
               ENDIF
               RETURN 0
            ENDIF

         ELSEIF msg == WM_IME_CHAR
            DeleteSel( Self )
            nPos := hwg_edit_Getpos( ::handle )
            ::title := cText := hwg_Getedittext( oParent:handle, ::id )
            cText := ::oPicture:GetApplyKey( cText, @nPos, hwg_Chr(wParam), ::lFirst, Set( _SET_INSERT ) )
            ::lFirst := .F.
            IF !( cText == ::title )
               hwg_Setwindowtext( ::handle, ::title := cText )
               hwg_SetGetUpdated( Self )
            ENDIF
            hwg_edit_SetPos( ::handle, nPos )
            RETURN 0

         ELSEIF msg == WM_KEYDOWN

            IF ::bKeyDown != Nil .AND. ( nPos := Eval( ::bKeyDown, Self, wParam, lParam ) ) != -1
               RETURN nPos
            ENDIF
            IF wParam == 40     // KeyDown
               IF !hwg_IsCtrlShift()
                  hwg_GetSkip( oParent, ::handle, 1 )
                  RETURN 0
               ENDIF
            ELSEIF wParam == 38     // KeyUp
               IF !hwg_IsCtrlShift()
                  hwg_GetSkip( oParent, ::handle, - 1 )
                  RETURN 0
               ENDIF
            ELSEIF wParam == 39     // KeyRight
               IF !hwg_IsCtrlShift()
                  ::lFirst := .F.
                  IF !Empty( ::oPicture )
                     IF ( nPos := ::oPicture:KeyRight( hwg_edit_Getpos( ::handle ) ) ) > 0
                        hwg_edit_Setpos( ::handle, nPos )
                     ENDIF
                     RETURN 0
                  ENDIF
               ENDIF
            ELSEIF wParam == 37     // KeyLeft
               IF !hwg_IsCtrlShift()
                  ::lFirst := .F.
                  IF !Empty( ::oPicture )
                     IF ( nPos := ::oPicture:KeyLeft( hwg_edit_Getpos( ::handle ) ) ) > 0
                        hwg_edit_Setpos( ::handle, nPos )
                     ENDIF
                     RETURN 1
                  ENDIF
               ENDIF
            ELSEIF wParam == 35     // End
               IF !hwg_IsCtrlShift()
                  ::lFirst := .F.
                  IF ::cType == "C"
                     nPos := hwg_Len( Trim( ::title ) ) + 1
                     hwg_edit_SetPos( ::handle, nPos )
                     RETURN 0
                  ENDIF
               ENDIF
            ELSEIF wParam == 45     // Insert
               IF !hwg_IsCtrlShift()
                  SET( _SET_INSERT, ! Set( _SET_INSERT ) )
               ENDIF
            ELSEIF wParam == 46     // Del
               ::lFirst := .F.
               hwg_SetGetUpdated( Self )
               IF !Empty( ::oPicture ) .AND. ::oPicture:lPicComplex
                  nPos := hwg_edit_GetPos( ::handle )
                  cText := ::oPicture:Delete( hwg_Getedittext( ::oParent:handle, ::id ), @nPos )
                  IF nPos > 0
                     hwg_Setwindowtext( ::handle, ::title := cText )
                     hwg_edit_Setpos( ::handle, nPos )
                  ENDIF
                  RETURN 0
               ENDIF
            ELSEIF wParam == VK_TAB     // Tab
               //****   Paulo Flecha
               IF Asc( SubStr( hwg_Getkeyboardstate(), VK_SHIFT + 1, 1 ) ) >= 128
                  IF !hwg_GetSkip( oParent, ::handle, - 1 ) // First Get
                     nextHandle := hwg_Getnextdlgtabitem ( (oParent := hwg_getParentForm(Self)):handle, ::handle, .T. )
                     IF oParent:Classname() == "HDIALOG"
                        hwg_Postmessage( oParent:handle, WM_NEXTDLGCTL, nextHandle , 1 )
                     ELSE
                        hwg_Setfocus( nextHandle )
                     ENDIF
                  ENDIF
               ELSE
                  IF !hwg_GetSkip( oParent, ::handle, 1 ) // Last Get
                     nextHandle := hwg_Getnextdlgtabitem ( (oParent := hwg_getParentForm(Self)):handle, ::handle, .F. )
                     IF oParent:Classname() == "HDIALOG"
                        hwg_Postmessage( oParent:handle, WM_NEXTDLGCTL, nextHandle , 1 )
                     ELSE
                        hwg_Setfocus( nextHandle )
                     ENDIF
                  ENDIF
               ENDIF
               RETURN 0
               //**     End
            ELSEIF wParam == VK_RETURN  // Enter
               hwg_GetSkip( oParent, ::handle, 1, .T. )
               RETURN 0
            ENDIF

         ELSEIF msg == WM_LBUTTONUP

            IF Empty( hwg_Getedittext( oParent:handle, ::id ) )
               hwg_Sendmessage( ::handle, EM_SETSEL, 0, 0 )
            ENDIF
         ELSEIF msg = WM_COPY .OR. msg = WM_CUT
            nPos := hwg_Sendmessage( ::handle, EM_GETSEL, 0, 0 )
            cClipboardText := hwg_Getedittext( ::oParent:handle, ::id )
            IF hwg_Hiword( nPos ) > hwg_Loword( nPos ) .AND. hwg_Hiword( nPos ) - hwg_Loword( nPos ) < hwg_Len( cClipboardText )
               hwg_Copystringtoclipboard( hwg_SubStr( cClipboardText, hwg_Loword(nPos)+1, hwg_Hiword(nPos)-hwg_Loword(nPos) ) )
            ELSE
               hwg_Copystringtoclipboard( Iif( Empty(::oPicture), cClipboardText, ::oPicture:UnTransform( cClipboardText ) ) )
            ENDIF
            RETURN 0

         ELSEIF msg = WM_PASTE .AND. ! ::lNoPaste
            ::lFirst := iif( ::cType = "N" .AND. "E" $ ::cPicFunc, .T. , .F. )
            cClipboardText := hwg_Getclipboardtext()
            IF ! Empty( cClipboardText )
               DeleteSel( Self )
               cText := hwg_Getedittext( ::oParent:handle, ::id )
               nPos := hwg_edit_Getpos( ::handle )
               FOR i := 1 TO hwg_Len( cClipboardText )
                  cText := ::oPicture:GetApplyKey( cText, @nPos, hwg_SubStr( cClipboardText,i,1 ), ::lFirst, Set( _SET_INSERT ) )
                  ::lFirst := .F.
               NEXT
               ::title := Iif( Empty(::oPicture), cText, ::oPicture:UnTransform( cText ) )
               hwg_Setwindowtext( ::handle, ::title )
               hwg_edit_SetPos( ::handle, nPos )
               hwg_SetGetUpdated( Self )
            ENDIF
            RETURN 0

         ENDIF
         /* Added by Sauli */
      ELSE
         IF msg == WM_KEYDOWN
            IF ::bKeyDown != Nil .AND. ( nPos := Eval( ::bKeyDown, Self, wParam, lParam ) ) != -1
               RETURN nPos
            ENDIF

            IF wParam == VK_TAB     // Tab
               nextHandle := hwg_Getnextdlgtabitem ( hwg_getParentForm(Self):handle, ::handle, ;
                     (Asc( SubStr( hwg_Getkeyboardstate(), VK_SHIFT + 1, 1 ) ) >= 128) )
               hwg_Setfocus( nextHandle )
               RETURN 0
            ENDIF
         ENDIF
         /* Sauli */
      ENDIF

   ELSE

      IF msg == WM_MOUSEWHEEL
         nPos := hwg_Hiword( wParam )
         nPos := iif( nPos > 32768, nPos - 65535, nPos )
         hwg_Sendmessage( ::handle, EM_SCROLL, iif( nPos > 0,SB_LINEUP,SB_LINEDOWN ), 0 )
         hwg_Sendmessage( ::handle, EM_SCROLL, iif( nPos > 0,SB_LINEUP,SB_LINEDOWN ), 0 )
      ENDIF
      //******  Tab  MULTILINE - Paulo Flecha
      IF msg == WM_KEYDOWN
         IF ::bKeyDown != Nil .AND. ( nPos := Eval( ::bKeyDown, Self, wParam, lParam ) ) != -1
            RETURN nPos
         ENDIF
         IF wParam == VK_ESCAPE .AND. !__ObjHasMsg( ::oParent, "GETLIST" )
            RETURN 0
         ENDIF
         IF wParam == VK_TAB     // Tab
            IF Asc( SubStr( hwg_Getkeyboardstate(), VK_SHIFT + 1, 1 ) ) >= 128
               IF !hwg_GetSkip( oParent, ::handle, - 1 ) // First Get
                  nextHandle := hwg_Getnextdlgtabitem ( hwg_getParentForm(Self):handle, ::handle, .T. )
                  hwg_Postmessage( hwg_getParentForm(Self):handle, WM_NEXTDLGCTL, nextHandle , 1 )
               ENDIF
            ELSE
               IF !hwg_GetSkip( oParent, ::handle, 1 ) // Last Get
                  nextHandle := hwg_Getnextdlgtabitem ( hwg_getParentForm(Self):handle, ::handle , .F. )
                  hwg_Postmessage( hwg_getParentForm(Self):handle, WM_NEXTDLGCTL, nextHandle , 1 )
               ENDIF
            ENDIF
            RETURN 0
         ENDIF
      ENDIF
      //******  End Tab  MULTILINE
   ENDIF

   IF msg == WM_KEYUP .OR. msg == WM_SYSKEYUP
      IF ::bKeyUp != Nil .AND. ( nPos := Eval( ::bKeyUp, Self, msg, wParam, lParam ) ) != -1
         RETURN nPos
      ENDIF
   ELSEIF msg == WM_GETDLGCODE
      IF !::lMultiLine
         RETURN DLGC_WANTARROWS + DLGC_WANTTAB + DLGC_WANTCHARS
      ENDIF
   ELSEIF msg == WM_DESTROY
      ::End()
   ENDIF

   IF msg == WM_SETFOCUS
      oParent := hwg_getParentForm( Self )
      IF lColorinFocus .OR. oParent:tColorinFocus >= 0 .OR. oParent:bColorinFocus >= 0 .OR. ::bColorBlock != Nil
         ::aColorOld[1] := ::tcolor
         ::aColorOld[2] := ::bcolor
         IF ::bColorBlock != Nil
            Eval( ::bColorBlock, Self )
         ELSE
            ::Setcolor( Iif( oParent:tColorinFocus >= 0, oParent:tColorinFocus, tColorinFocus ), ;
                  Iif( oParent:bColorinFocus >= 0, oParent:bColorinFocus, bColorinFocus ), .T. )
         ENDIF
      ENDIF
   ELSEIF msg == WM_KILLFOCUS
      oParent := hwg_getParentForm( Self )
      IF lColorinFocus .OR. oParent:tColorinFocus >= 0 .OR. oParent:bColorinFocus >= 0 .OR. ::bColorBlock != Nil
         ::Setcolor( ::aColorOld[1], ::aColorOld[2], .T. )
      ENDIF
   ENDIF

   RETURN -1

METHOD Redefine( oWndParent, nId, vari, bSetGet, oFont, bInit, bSize, ;
      bGfocus, bLfocus, ctooltip, tcolor, bcolor, cPicture, nMaxLength )  CLASS HEdit

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
      bSize,, ctooltip, tcolor, iif( bcolor == Nil, hwg_Getsyscolor( COLOR_BTNHIGHLIGHT ), bcolor ) )

   IF vari != Nil
      ::cType := ValType( vari )
   ENDIF
   ::bSetGet := bSetGet

   ::ParsePict( cPicture, vari )
   IF nMaxLength != Nil
      ::nMaxLength := nMaxLength
   ENDIF

   IF bSetGet != Nil
      ::bGetFocus := bGFocus
      ::bLostFocus := bLFocus
      ::oParent:AddEvent( EN_SETFOCUS, ::id, { |o, id|__When( o:FindControl(id ) ) } )
      ::oParent:AddEvent( EN_KILLFOCUS, ::id, { |o, id|__Valid( o:FindControl(id ) ) } )
      ::bValid := { |o|__Valid( o ) }
   ELSE
      IF bGfocus != Nil
         ::oParent:AddEvent( EN_SETFOCUS, ::id, bGfocus )
      ENDIF
      IF bLfocus != Nil
         ::oParent:AddEvent( EN_KILLFOCUS, ::id, bLfocus )
      ENDIF
   ENDIF

   RETURN Self

METHOD Refresh()  CLASS HEdit

   LOCAL vari

   IF hb_isBlock( ::bSetGet )
      vari := Eval( ::bSetGet, , self )
   ELSE
      vari := ::title
   ENDIF

   IF vari == Nil
      vari := ""
   ENDIF

   IF !Empty( ::oPicture )
      vari := ::oPicture:Transform( vari )
   ELSE
      vari := iif( ::cType == "D", Dtoc( vari ), iif( ::cType == "N",Str(vari ),iif(::cType == "C",vari,"" ) ) )
   ENDIF
   ::title := vari
   hwg_Setdlgitemtext( ::oParent:handle, ::id, vari )

   IF ::bColorBlock != Nil .AND. hwg_Isptreq( ::handle, hwg_Getfocus() )
      Eval( ::bColorBlock, Self )
   ENDIF

   RETURN Nil

METHOD Value( xValue ) CLASS HEdit

   LOCAL vari

   IF xValue != Nil
      IF !Empty( ::oPicture )
         ::title := ::oPicture:Transform( xValue )
      ELSE
         ::title := xValue
      ENDIF
      hwg_Setwindowtext( ::handle, ::title  )
      IF ::bSetGet != Nil
         Eval( ::bSetGet, xValue, Self )
      ENDIF
      RETURN xValue
   ENDIF

   vari := iif( Empty( ::handle ), ::title, hwg_Getedittext( ::oParent:handle, ::id ) )
   IF !Empty( ::oPicture )
      vari := ::oPicture:UnTransform( vari )
   ENDIF
   IF ::cType == "D"
      vari := CToD( vari )
   ELSEIF ::cType == "N"
      vari := Val( LTrim( vari ) )
   ELSEIF ::cType == "C" .AND. !Empty( ::nMaxLength )
      vari := PadR( vari, ::nMaxLength )
   ENDIF

   RETURN vari

METHOD SelStart( nStart ) CLASS HEdit

   IF nStart != Nil
      hwg_Sendmessage( ::handle, EM_SETSEL, nStart , nStart )
   ELSE
      nStart := hwg_Loword( hwg_Sendmessage( ::handle, EM_GETSEL, 0, 0 ) )
   ENDIF

   RETURN nStart

METHOD SelLength( nLength ) CLASS HEdit

   LOCAL nStart

   IF nLength != Nil
      nStart := hwg_Loword( hwg_Sendmessage( ::handle, EM_GETSEL, 0, 0 ) )
      hwg_Sendmessage( ::handle, EM_SETSEL, nStart, nStart + nLength  )
   ELSE
      nStart := hwg_Sendmessage( ::handle, EM_GETSEL, 0, 0 )
      nLength := hwg_Hiword( nStart ) - hwg_Loword( nStart )
   ENDIF

   RETURN nLength

CLASS HPicture INHERIT HObject

   DATA cPicFunc, cPicMask
   DATA lPicComplex    INIT .F.
   DATA cType
   DATA nMaxLength     INIT Nil

   METHOD New( cPicture, vari, nMaxLength )
   METHOD IsEditable( nPos )
   METHOD FirstEditable()
   METHOD LastEditable()
   METHOD KeyRight( nPos )
   METHOD KeyLeft( nPos )
   METHOD Delete( cText, nPos )
   METHOD Input( cChar, nPos )
   METHOD GetApplyKey( cText, nPos, cKey, lFirst, lIns )
   METHOD Transform( vari )
   METHOD UnTransform( cBuffer )

   ENDCLASS

METHOD New( cPicture, vari, nMaxLength ) CLASS HPicture

   LOCAL nAt, i, masklen

   ::cType := Valtype( vari )
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
      IF Empty( ::nMaxLength ) .AND. !Empty( ::cPicMask ) .AND. !( ::cPicFunc == "@R")
         ::nMaxLength := Len( ::cPicMask )
      ENDIF
   ENDIF

   IF Empty( ::cPicMask )
      IF ::cType == "D"
         ::cPicMask := StrTran( Dtoc( CToD( Space(8) ) ), ' ', '9' )
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

   IF !Empty( ::cPicMask )
      masklen := Len( ::cPicMask )
      FOR i := 1 TO masklen
         IF !( SubStr( ::cPicMask, i, 1 ) $ "!ANX9#" )
            ::lPicComplex := .T.
            EXIT
         ENDIF
      NEXT
   ENDIF

   IF Empty( ::nMaxLength ) .AND. ::cType == "C"
      ::nMaxLength := hwg_Len( vari )
   ENDIF
   IF nMaxLength != Nil
      ::nMaxLength := nMaxLength
   ENDIF

   //  ------------ added by Maurizio la Cecilia
   IF !Empty( ::nMaxLength ) .AND. Len( ::cPicMask ) < ::nMaxLength
      ::cPicMask := PadR( ::cPicMask, ::nMaxLength, "X" )
   ENDIF
   //  ------------- end of added code

   RETURN Self

METHOD IsEditable( nPos ) CLASS HPicture

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

METHOD FirstEditable() CLASS HPicture

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

METHOD LastEditable() CLASS HPicture

   LOCAL nFor, nMaxLen := Len( ::cPicMask )

   FOR nFor := nMaxLen TO 1 step - 1
      IF ::IsEditable( nFor )
         RETURN nFor
      ENDIF
   NEXT

   RETURN 0

METHOD KeyRight( nPos ) CLASS HPicture

   LOCAL masklen, newpos

   IF Empty( ::cPicMask )
      RETURN nPos + 1
   ELSE
      masklen := Len( ::cPicMask )
      DO WHILE nPos < masklen
         nPos ++
         IF ::IsEditable( nPos )
            RETURN nPos
         ENDIF
      ENDDO
   ENDIF

   //Added By Sandro Freire

   IF !Empty( ::cPicMask )
      newPos := Len( ::cPicMask )
      IF nPos > newPos //.AND. !Empty( Trim( ::Title ) )
         RETURN newPos
      ENDIF
   ENDIF

   RETURN -1

METHOD KeyLeft( nPos ) CLASS HPicture

   IF ::cPicMask == Nil .OR. Empty( ::cPicMask )
      RETURN nPos - 1
   ELSE
      DO WHILE nPos > 1
         nPos --
         IF ::IsEditable( nPos )
            RETURN nPos
         ENDIF
      ENDDO
   ENDIF

   RETURN -1

METHOD Delete( cText, nPos ) CLASS HPicture

   LOCAL nGetLen := Len( ::cPicMask ), nLen

   FOR nLen := 0 TO nGetLen
      IF !::IsEditable( nPos + nLen )
         EXIT
      ENDIF
   NEXT
   IF nLen == 0
      DO WHILE nPos >= 1
         nPos --
         nLen ++
         IF ::IsEditable( nPos )
            EXIT
         ENDIF
      ENDDO
   ENDIF
   cText := PadR( Left( cText, nPos - 1 ) + ;
      SubStr( cText, nPos + 1, nLen - 1 ) + " " + ;
      SubStr( cText, nPos + nLen ), nGetLen )

   RETURN cText

METHOD Input( cChar, nPos ) CLASS HPicture

   LOCAL cPic

   IF !Empty( ::cPicMask ) .AND. nPos > Len( ::cPicMask )
      RETURN Nil
   ENDIF
   IF ::cType == "N"
      IF cChar == "-"
         IF nPos != 1
            RETURN Nil
         ENDIF
      ELSEIF !( cChar $ "0123456789" )
         RETURN Nil
      ENDIF

   ELSEIF ::cType == "D"

      IF !( cChar $ "0123456789" )
         RETURN Nil
      ENDIF

   ELSEIF ::cType == "L"

      IF !( Upper( cChar ) $ "YNTF" )
         RETURN Nil
      ENDIF

   ENDIF

   IF Len( cChar ) > 1
      IF !Empty( ::cPicMask ) .AND. SubStr( ::cPicMask, nPos, 1 ) $ "N9#"
         cChar := Nil
      ENDIF
   ELSE
      IF !Empty( ::cPicFunc )
         cChar := Transform( cChar, ::cPicFunc )
      ENDIF

      IF !Empty( ::cPicMask )
         cPic  := SubStr( ::cPicMask, nPos, 1 )

         cChar := Transform( cChar, cPic )
         IF cPic == "A"
            IF ! IsAlpha( cChar )
               cChar := Nil
            ENDIF
         ELSEIF cPic == "N"
            IF ! IsAlpha( cChar ) .AND. ! IsDigit( cChar )
               cChar := Nil
            ENDIF
         ELSEIF cPic == "9"
            IF ! IsDigit( cChar ) .AND. cChar != "-"
               cChar := Nil
            ENDIF
         ELSEIF cPic == "#"
            IF ! IsDigit( cChar ) .AND. !( cChar == " " ) .AND. !( cChar $ "+-" )
               cChar := Nil
            ENDIF
         ENDIF
      ENDIF
   ENDIF

   RETURN cChar

METHOD GetApplyKey( cText, nPos, cKey, lFirst, lIns ) CLASS HPicture

   LOCAL nGetLen, nLen, vari, x, newPos, oParent
   LOCAL nDecimals, lMinus := .F.

   IF ::cType == "N" .AND. cKey $ ".," .AND. ( nPos := At( ".",::cPicMask ) ) != 0
      IF lFirst
         vari := 0
      ELSE
         vari := Val( LTrim( ::UnTransform( Trim( cText ) ) ) )
         lMinus := Iif( Left( Ltrim(vari),1 ) == "-", .T., .F. )
      ENDIF
      cText := ::Transform( vari )
      IF ( x := ::KeyRight( nPos - 1 ) ) > 0
         nPos := x
      ENDIF
      IF !Empty( ::cPicFunc ) .OR. !Empty( ::cPicMask )
         IF lMinus .AND. vari == 0
            nLen := Len( cText )
            cText := Padl( "-" + Ltrim( cText ), nLen )
         ENDIF
      ENDIF
   ELSE

      IF ::cType == "N" .AND. lFirst
         nGetLen := Len( ::cPicMask )
         IF ( nPos := At( ".", ::cPicMask ) ) == 0
            cText := Space( nGetLen )
         ELSE
            cText := Space( nPos - 1 ) + "." + Space( nGetLen - nPos )
         ENDIF
         nPos := 1
      ENDIF
      cKey := ::Input( cKey, nPos )
      IF cKey != Nil
         IF lIns
            IF ::lPicComplex
               nGetLen := Len( ::cPicMask )
               FOR nLen := 0 TO nGetLen
                  IF !::IsEditable( nPos + nLen )
                     EXIT
                  ENDIF
               NEXT
               cText := hwg_Left( cText, nPos - 1 ) + cKey + ;
                  hwg_SubStr( cText, nPos, nLen - 1 ) + hwg_SubStr( cText, nPos + nLen )
            ELSE
               cText := hwg_Left( cText, nPos - 1 ) + cKey + ;
                  hwg_SubStr( cText, nPos )
            ENDIF

            IF !Empty( ::cPicMask ) .AND. Len( ::cPicMask ) < hwg_Len( cText )
               cText := hwg_Left( cText, nPos - 1 ) + cKey + hwg_SubStr( cText, nPos + 1 )
            ENDIF
         ELSE
            cText := hwg_Left( cText, nPos - 1 ) + cKey + hwg_SubStr( cText, nPos + 1 )
         ENDIF
         IF !Empty( ::nMaxLength )
            nGetLen := Max( Len( ::cPicMask ), ::nMaxLength )
            nLen := hwg_Len( cText )
            IF nGetLen > nLen
               cText += Space( nGetLen-nLen )
            ELSEIF nGetLen < nLen
               cText := hwg_Left( cText, nGetLen )
            ENDIF
         ENDIF
         IF ( x := ::KeyRight( nPos ) ) > 0
            nPos := x
         ENDIF
         //Added By Sandro Freire
         IF ::cType == "N"
            IF !Empty( ::cPicMask )
               nDecimals := Len( SubStr(  ::cPicMask, At( ".", ::cPicMask ), Len( ::cPicMask ) ) )
               IF nDecimals <= 0
                  nDecimals := 3
               ENDIF
               newPos := Len( ::cPicMask ) - nDecimals
               IF "E" $ ::cPicFunc .AND. nPos == newPos
                  cText := ::GetApplyKey( cText, nPos, ",", .F., lIns )
               ENDIF
            ENDIF
         ENDIF
      ENDIF
   ENDIF

   RETURN cText

METHOD Transform( vari ) CLASS HPicture
   RETURN Transform( vari, ::cPicFunc + iif( Empty(::cPicFunc ),""," " ) + ::cPicMask )

METHOD UnTransform( cBuffer ) CLASS HPicture

   LOCAL xValue, cChar, nFor, minus

   IF ::cType == "C"

      IF "R" $ ::cPicFunc
         FOR nFor := 1 TO Len( ::cPicMask )
            cChar := SubStr( ::cPicMask, nFor, 1 )
            IF !cChar $ "ANX9#!"
               cBuffer := SubStr( cBuffer, 1, nFor - 1 ) + Chr( 1 ) + SubStr( cBuffer, nFor + 1 )
            ENDIF
         NEXT
         cBuffer := StrTran( cBuffer, Chr( 1 ), "" )
      ENDIF

      xValue := cBuffer

   ELSEIF ::cType == "N"
      minus := ( Left( LTrim( cBuffer ),1 ) == "-" )
      cBuffer := Space( ::FirstEditable() - 1 ) + SubStr( cBuffer, ::FirstEditable(), ::LastEditable() - ::FirstEditable() + 1 )

      IF "D" $ ::cPicFunc
         FOR nFor := ::FirstEditable() TO ::LastEditable()
            IF !::IsEditable( nFor )
               cBuffer = Left( cBuffer, nFor - 1 ) + Chr( 1 ) + SubStr( cBuffer, nFor + 1 )
            ENDIF
         NEXT
      ELSE
         IF "E" $ ::cPicFunc
            cBuffer := Left( cBuffer, ::FirstEditable() - 1 ) +  ;
               StrTran( SubStr( cBuffer, ::FirstEditable(),      ;
               ::LastEditable() - ::FirstEditable() + 1 ),       ;
               ".", " " ) + SubStr( cBuffer, ::LastEditable() + 1 )
            cBuffer := Left( cBuffer, ::FirstEditable() - 1 ) +  ;
               StrTran( SubStr( cBuffer, ::FirstEditable(),      ;
               ::LastEditable() - ::FirstEditable() + 1 ),  ;
               ",", "." ) + SubStr( cBuffer, ::LastEditable() + 1 )
         ELSE
            cBuffer := Left( cBuffer, ::FirstEditable() - 1 ) + ;
               StrTran( SubStr( cBuffer, ::FirstEditable(),     ;
               ::LastEditable() - ::FirstEditable() + 1 ), ;
               ",", " " ) + SubStr( cBuffer, ::LastEditable() + 1 )
         ENDIF

         FOR nFor := ::FirstEditable() TO ::LastEditable()
            IF !::IsEditable( nFor ) .AND. SubStr( cBuffer, nFor, 1 ) != "."
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
      xValue := "T" $ cBuffer .OR. "Y" $ cBuffer .OR. hb_langmessage( HB_LANG_ITEM_BASE_TEXT + 1 ) $ cBuffer

   ELSEIF ::cType == "D"

      IF "E" $ ::cPicFunc
         cBuffer := SubStr( cBuffer, 4, 3 ) + SubStr( cBuffer, 1, 3 ) + SubStr( cBuffer, 7 )
      ENDIF
      xValue := cBuffer

   ENDIF

   RETURN xValue

STATIC FUNCTION __When( oCtrl )

   LOCAL res := .T., n := 0

   oCtrl:Refresh()
   oCtrl:lFirst := .T.
   IF oCtrl:bGetFocus != Nil
      res := Eval( oCtrl:bGetFocus, oCtrl:title, oCtrl )
      IF !res
         hwg_GetSkip( oCtrl:oParent, oCtrl:handle, 1 )
      ENDIF
   ENDIF
   IF res .AND. !Empty( oCtrl:oPicture ) .AND. ( n := oCtrl:oPicture:KeyRight( 0 ) ) > 0
      hwg_edit_Setpos( oCtrl:handle, n )
   ENDIF

   RETURN res

STATIC FUNCTION __Valid( oCtrl )

   LOCAL vari, oDlg, nLen

   IF oCtrl:bSetGet != Nil
      IF ( oDlg := hwg_getParentForm( oCtrl ) ) == Nil .OR. oDlg:nLastKey != 27
         vari := hwg_Getedittext( oCtrl:oParent:handle, oCtrl:id )
         oCtrl:title := vari := Iif( !Empty( oCtrl:oPicture ), oCtrl:oPicture:UnTransform( vari ), vari )
         IF oCtrl:cType == "D"
            IF IsBadDate( vari )
               hwg_Setfocus( oCtrl:handle )
               hwg_edit_SetPos( oCtrl:handle, 1 )
               RETURN .F.
            ENDIF
            vari := CToD( vari )
         ELSEIF oCtrl:cType == "N"
            vari := Val( LTrim( vari ) )
            oCtrl:title := Iif( Empty( oCtrl:oPicture), vari, oCtrl:oPicture:Transform( vari ) )
            hwg_Setdlgitemtext( oCtrl:oParent:handle, oCtrl:id, oCtrl:title )
         ELSEIF oCtrl:cType == "C" .AND. !Empty( oCtrl:nMaxLength )
            nLen := hwg_Len( vari )
            IF oCtrl:nMaxLength > nLen
               vari += Space( oCtrl:nMaxLength-nLen )
            ELSEIF oCtrl:nMaxLength < nLen
               vari := hwg_Left( vari, oCtrl:nMaxLength )
            ENDIF
            oCtrl:title := vari
         ENDIF
         Eval( oCtrl:bSetGet, vari, oCtrl )

         IF oDlg != Nil
            oDlg:nLastKey := 27
         ENDIF
         IF oCtrl:bLostFocus != Nil .AND. !Eval( oCtrl:bLostFocus, vari, oCtrl )
            hwg_Setfocus( oCtrl:handle )
            IF oDlg != Nil
               oDlg:nLastKey := 0
            ENDIF
            RETURN .F.
         ENDIF
         IF oDlg != Nil
            oDlg:nLastKey := 0
         ENDIF
      ENDIF
   ENDIF

   RETURN .T.

STATIC FUNCTION IsBadDate( cBuffer )

   LOCAL i, nLen

   IF !Empty( CToD( cBuffer ) )
      RETURN .F.
   ENDIF
   nLen := Len( cBuffer )
   FOR i := 1 TO nLen
      IF IsDigit( SubStr( cBuffer,i,1 ) )
         RETURN .T.
      ENDIF
   NEXT

   RETURN .F.

STATIC FUNCTION DeleteSel( oEdit )

   LOCAL x := hwg_Sendmessage( oEdit:handle, EM_GETSEL, 0, 0 )

   IF hwg_Hiword( x ) != hwg_Loword( x )
      hwg_Sendmessage( oEdit:handle, WM_CLEAR, hwg_Loword( x ), hwg_Hiword( x ) - 1 )
   ENDIF

   RETURN Nil

FUNCTION hwg_CreateGetList( oDlg )

   LOCAL i, j, aLen1 := Len( oDlg:aControls ), aLen2

   FOR i := 1 TO aLen1
      IF __ObjHasMsg( oDlg:aControls[i], "BSETGET" ) .AND. oDlg:aControls[i]:bSetGet != Nil
         AAdd( oDlg:GetList, oDlg:aControls[i] )
      ELSEIF !Empty( oDlg:aControls[i]:aControls )
         aLen2 := Len( oDlg:aControls[i]:aControls )
         FOR j := 1 TO aLen2
            IF __ObjHasMsg( oDlg:aControls[i]:aControls[j], "BSETGET" ) .AND. oDlg:aControls[i]:aControls[j]:bSetGet != Nil
               AAdd( oDlg:GetList, oDlg:aControls[i]:aControls[j] )
            ENDIF
         NEXT
      ENDIF
   NEXT

   RETURN Nil

FUNCTION hwg_GetSkip( oParent, hCtrl, nSkip, lClipper )

   LOCAL i, aLen

   DO WHILE oParent != Nil .AND. !__ObjHasMsg( oParent, "GETLIST" )
      oParent := oParent:oParent
   ENDDO
   IF oParent == Nil .OR. ( lClipper != Nil .AND. lClipper .AND. !oParent:lClipper )
      RETURN .F.
   ENDIF
   IF hCtrl == Nil
      i := 0
   ENDIF
   IF hCtrl == Nil .OR. ( i := Ascan( oParent:Getlist,{ |o|o:handle == hCtrl } ) ) != 0
      IF i > 0 .AND. __ObjHasMsg( oParent:Getlist[i], "LFIRST" )
         oParent:Getlist[i]:lFirst := .T.
      ENDIF
      IF nSkip > 0
         aLen := Len( oParent:Getlist )
         DO WHILE ( i := i + nSkip ) <= aLen
            IF !oParent:Getlist[i]:lHide .AND. hwg_Iswindowenabled( oParent:Getlist[i]:Handle ) // Now tab and enter goes trhow the check, combo, etc...
               hwg_Setfocus( oParent:Getlist[i]:handle )
               RETURN .T.
            ENDIF
         ENDDO
      ELSE
         DO WHILE ( i := i + nSkip ) > 0
            IF !oParent:Getlist[i]:lHide .AND. hwg_Iswindowenabled( oParent:Getlist[i]:Handle )
               hwg_Setfocus( oParent:Getlist[i]:handle )
               RETURN .T.
            ENDIF
         ENDDO
      ENDIF
   ENDIF

   RETURN .F.

FUNCTION hwg_SetGetUpdated( o )

   o:lChanged := .T.
   IF ( o := hwg_getParentForm( o ) ) != Nil
      o:lUpdated := .T.
   ENDIF

   RETURN Nil

FUNCTION hwg_IsCtrlShift( lCtrl, lShift )

   LOCAL cKeyb := hwg_Getkeyboardstate()

   IF lCtrl == Nil; lCtrl := .T. ; ENDIF
   IF lShift == Nil; lShift := .T. ; ENDIF

   RETURN ( lCtrl .AND. ( Asc(SubStr(cKeyb,VK_CONTROL + 1,1 ) ) >= 128 ) ) .OR. ;
      ( lShift .AND. ( Asc(SubStr(cKeyb,VK_SHIFT + 1,1 ) ) >= 128 ) )

FUNCTION hwg_SetColorinFocus( lDef, tColor, bColor )

   IF ValType( lDef ) ==  "O"
      IF tColor != Nil
         lDef:tColorinFocus := tColor
      ENDIF
      IF bColor != Nil
         lDef:bColorinFocus := bColor
      ENDIF
   ELSEIF ValType( lDef ) == "L"
      lColorinFocus := lDef
      IF tColor != Nil
         tColorinFocus := tColor
      ENDIF
      IF bColor != Nil
         bColorinFocus := bColor
      ENDIF
   ENDIF

   RETURN .T.

FUNCTION hwg_Chr( nCode )
#ifndef UNICODE
   RETURN Chr( nCode )
#else
   RETURN Iif( hb_cdpSelect()=="UTF8", hb_utf8Chr( nCode ), Chr( nCode ) )
#endif

FUNCTION hwg_Substr( cString, nPos, nLen )
#ifndef UNICODE
   RETURN Iif( nLen==Nil, Substr( cString, nPos ), Substr( cString, nPos, nLen ) )
#else
   RETURN Iif( hb_cdpSelect()=="UTF8", ;
      Iif( nLen==Nil, hb_utf8Substr( cString, nPos ), hb_utf8Substr( cString, nPos, nLen ) ), ;
      Iif( nLen==Nil, Substr( cString, nPos ), Substr( cString, nPos, nLen ) ) )
#endif

FUNCTION hwg_Left( cString, nLen )
#ifndef UNICODE
   RETURN Left( cString, nLen )
#else
   RETURN Iif( hb_cdpSelect()=="UTF8", hb_utf8Left( cString, nLen ), Left( cString, nLen ) )
#endif

FUNCTION hwg_Len( cString )
#ifndef UNICODE
   RETURN Len( cString )
#else
   RETURN Iif( hb_cdpSelect()=="UTF8", hb_utf8Len( cString ), Len( cString ) )
#endif

FUNCTION hwg_GET_Helper(cp_get,nlen)

   LOCAL c_get

#ifndef __GTK__
   HB_SYMBOL_UNUSED(nlen)
#endif

   c_get := cp_get

#ifdef __GTK__
   IF EMPTY(c_get)
      c_get := ""
   ELSE
      IF nlen == NIL
         c_get := RTRIM(c_get)
      ELSE
         c_get := PADR(c_get,nlen)
      ENDIF
   ENDIF
#endif

   RETURN c_get
