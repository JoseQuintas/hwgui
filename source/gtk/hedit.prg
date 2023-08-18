/*
 *$Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HEdit class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hbclass.ch"
#include "hblang.ch"
#include "hwgui.ch"

STATIC lColorinFocus := .F.
STATIC tColorinFocus := 0
STATIC bColorinFocus := 16777164

CLASS HEdit INHERIT HControl

   CLASS VAR winclass   INIT "EDIT"
   DATA lMultiLine   INIT .F.
   DATA cType INIT "C"
   DATA bSetGet
   DATA oPicture
   DATA bValid
   DATA bAnyEvent
   DATA lFirst       INIT .T.
   DATA lChanged     INIT .F.
   DATA nMaxLength   INIT Nil
   DATA nLastKey     INIT 0
   DATA lMouse       INIT .F.
   DATA aColorOld      INIT { 0,0 }
   DATA bColorBlock
   DATA bkeydown

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bGfocus, bLfocus, ctoolt, tcolor, bcolor, cPicture, lNoBorder, nMaxLength, lPassword )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD SetGet( value ) INLINE Eval( ::bSetGet, value, self )
   METHOD Refresh()
   METHOD Value ( xValue ) SETGET
   METHOD SetText( value ) INLINE hwg_edit_SetText( ::handle, ::title := value )
   METHOD GetText() INLINE hwg_edit_GetText( ::handle )

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bGfocus, bLfocus, ctoolt, ;
      tcolor, bcolor, cPicture, lNoBorder, nMaxLength, lPassword ) CLASS HEdit

   nStyle := Hwg_BitOr( iif( nStyle == Nil,0,nStyle ), ;
      WS_TABSTOP + iif( lNoBorder == Nil .OR. !lNoBorder, WS_BORDER, 0 ) + ;
      iif( lPassword == Nil .OR. !lPassword, 0, ES_PASSWORD )  )

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize,, ctoolt, Iif(tcolor==Nil,0,tcolor), Iif(bcolor==Nil,0xffffff,bcolor) )

   ::cType := ValType( vari )
   ::title := vari
   ::bSetGet := bSetGet
   //::bKeyDown := bKeyDown

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
      ::nMaxLength := Len( vari )
   ENDIF
   IF nMaxLength != Nil
      ::nMaxLength := nMaxLength
   ENDIF
*/
   ::Activate()

   ::bGetFocus := bGFocus
   ::bLostFocus := bLFocus
   hwg_SetEvent( ::handle, "focus_in_event", WM_SETFOCUS, 0, 0 )
   hwg_SetEvent( ::handle, "focus_out_event", WM_KILLFOCUS, 0, 0 )
   hwg_SetEvent( ::handle, "key_press_event", 0, 0, 0 )
   IF ::bSetGet != Nil
      hwg_SetSignal( ::handle, "paste-clipboard", WM_PASTE, 0, 0 )
      hwg_SetSignal( ::handle, "copy-clipboard", WM_COPY, 0, 0 )
   ENDIF

   RETURN Self

METHOD Activate() CLASS HEdit

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createedit( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      hwg_Setwindowobject( ::handle, Self )
      ::Init()
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HEdit

   LOCAL oParent
   LOCAL nPos, cText

   // hwg_WriteLog( "Edit: "+Str(msg,10)+"|"+Str(wParam,10)+"|"+Str(lParam,10) )

   IF ::bAnyEvent != Nil .AND. Eval( ::bAnyEvent, Self, msg, wParam, lParam ) != 0
      RETURN 0
   ENDIF

   IF msg == WM_SETFOCUS   && msg = 7
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
      IF ::lMouse
         ::lFirst := .F.
         ::lMouse := .F.
      ENDIF
      hwg_edit_set_Overmode( ::handle, !Set( _SET_INSERT ) )
      IF ::bSetGet == Nil
         IF ::bGetFocus != Nil
            Eval( ::bGetFocus, hwg_Edit_GetText( ::handle ), Self )
         ENDIF
      ELSE
         __When( Self )
      ENDIF
   ELSEIF msg == WM_KILLFOCUS
      oParent := hwg_getParentForm( Self )
      IF lColorinFocus .OR. oParent:tColorinFocus >= 0 .OR. oParent:bColorinFocus >= 0 .OR. ::bColorBlock != Nil
         ::Setcolor( ::aColorOld[1], ::aColorOld[2], .T. )
      ENDIF
      IF ::bSetGet == Nil
         IF ::bLostFocus != Nil
            Eval( ::bLostFocus, hwg_Edit_GetText( ::handle ), Self )
         ENDIF
      ELSE
         __Valid( Self )
      ENDIF
   ELSEIF msg == WM_LBUTTONDOWN .OR. msg == WM_RBUTTONDOWN
      ::lMouse := .T.
   ELSEIF msg == WM_DESTROY
      ::End()
   ELSEIF msg == WM_PASTE
      DoPaste( Self )
      Eval( ::bSetGet, ::title, Self )
      RETURN 1
   ELSEIF msg == WM_COPY
      DoCopy( Self )
      RETURN 1
   ENDIF

   IF ::bSetGet == Nil
      ::Title := hwg_Edit_GetText( ::handle )
      RETURN 0
   ENDIF

   oParent := ::oParent
   IF !::lMultiLine
      IF msg == WM_KEYDOWN
         ::nLastKey := wParam
         IF wParam == GDK_BackSpace
            ::lFirst := .F.
            hwg_SetGetUpdated( Self )
            IF !Empty( ::oPicture ) .AND. ::oPicture:lPicComplex
               nPos := hwg_edit_GetPos( ::handle ) - 1
               IF nPos > 0
                  cText := ::oPicture:Delete( hwg_edit_GetText( ::handle ), @nPos )
                  IF nPos > 0
                     hwg_edit_Settext( ::handle, ::title := cText )
                     hwg_edit_Setpos( ::handle, nPos )
                  ENDIF
               ENDIF
               RETURN 1
            ENDIF
            RETURN 0
         ELSEIF wParam == GDK_Down     // KeyDown
            IF lParam == 0
               hwg_GetSkip( oParent, ::handle, 1 )
               RETURN 1
            ENDIF
         ELSEIF wParam == GDK_Up     // KeyUp
            IF lParam == 0
               hwg_GetSkip( oParent, ::handle, - 1 )
               RETURN 1
            ENDIF
         ELSEIF wParam == GDK_Right
            IF lParam == 0
               ::lFirst := .F.
               IF !Empty( ::oPicture )
                  IF ( nPos := ::oPicture:KeyRight( hwg_edit_Getpos( ::handle ) ) ) > 0
                     hwg_edit_Setpos( ::handle, nPos )
                  ENDIF
                  RETURN 1
               ENDIF
            ENDIF
         ELSEIF wParam == GDK_Left
            IF lParam == 0
               ::lFirst := .F.
               IF !Empty( ::oPicture )
                  IF ( nPos := ::oPicture:KeyLeft( hwg_edit_Getpos( ::handle ) ) ) > 0
                     hwg_edit_Setpos( ::handle, nPos )
                  ENDIF
                  RETURN 1
               ENDIF
            ENDIF
         ELSEIF wParam == GDK_Home     // Home
            IF lParam == 0
               ::lFirst := .F.
               IF !Empty( ::oPicture )
                  nPos := ::oPicture:KeyRight( 0 )
               ELSE
                  nPos := 1
               ENDIF
               hwg_edit_SetPos( ::handle, nPos )
               RETURN 1
            ENDIF
         ELSEIF wParam == GDK_End     // End
            IF lParam == 0
               ::lFirst := .F.
               IF ::cType == "C"
                  nPos := Len( Trim( ::title ) ) + 1
                  hwg_edit_SetPos( ::handle, nPos )
                  RETURN 1
               ENDIF
            ENDIF
         ELSEIF wParam == GDK_Delete     // Del
            ::lFirst := .F.
            hwg_SetGetUpdated( Self )
            IF !Empty( ::oPicture ) .AND. ::oPicture:lPicComplex
               nPos := hwg_edit_GetPos( ::handle )
               cText := ::oPicture:Delete( hwg_edit_GetText( ::handle ), @nPos )
               IF nPos > 0
                  hwg_edit_Settext( ::handle, ::title := cText )
                  hwg_edit_Setpos( ::handle, nPos )
               ENDIF
               RETURN 1
            ENDIF
         ELSEIF wParam == GDK_Tab     // Tab
            IF hwg_Checkbit( lParam, 1 )
               hwg_GetSkip( oParent, ::handle, - 1 )
            ELSE
               hwg_GetSkip( oParent, ::handle, 1 )
            ENDIF
            RETURN 1
         ELSEIF wParam == GDK_ISO_Left_Tab
            IF hwg_Checkbit( lParam, 1 )
               hwg_GetSkip( oParent, ::handle, - 1 )
            ENDIF
            RETURN 1
         ELSEIF wParam == GDK_Return .OR. wParam == GDK_KP_Enter  // Enter
            IF !hwg_GetSkip( oParent, ::handle, 1, .T. ) .AND. ::bSetGet != Nil
               __Valid( Self )
            ENDIF
            RETURN 1
         ELSEIF ( hwg_checkBit( lParam,1 ) .AND. wParam == GDK_Insert ) .OR. ;
               ( hwg_checkBit( lParam,2 ) .AND. ( wParam == 86 .OR. wParam == 118 ) )
            // Paste
            IF ::bSetGet != Nil
               DoPaste( Self )
               RETURN 1
            ENDIF
         ELSEIF hwg_checkBit( lParam, 2 ) .AND. wParam == GDK_Insert .OR. ;
               ( hwg_checkBit( lParam,2 ) .AND. ( wParam == 67 .OR. wParam == 99 ) )
            // Copy
            IF ::bSetGet != Nil
               DoCopy( Self )
               RETURN 1
            ENDIF
         ELSEIF wParam == GDK_Insert     // Insert
            IF lParam == 0
               SET( _SET_INSERT, ! Set( _SET_INSERT ) )
            ENDIF
         ELSEIF ( (wParam >= 32 .AND. wParam < 65000) .OR. (wParam >= GDK_KP_0 .AND. wParam <= GDK_KP_9) ) ;
               .AND. !hwg_Checkbit( lParam, 2 )
            IF wParam >=  GDK_KP_0
               wParam -= ( GDK_KP_0 - 48 )
            ENDIF
            IF !Empty( ::oPicture )
               nPos := hwg_edit_Getpos( ::handle )
               ::title := cText := hwg_edit_Gettext( ::handle )
               cText := ::oPicture:GetApplyKey( cText, @nPos, hwg_Chr(wParam), ::lFirst, Set( _SET_INSERT ) )
               ::lFirst := .F.
               IF !( cText == ::title )
                  hwg_edit_Settext( ::handle, ::title := cText )
                  hwg_SetGetUpdated( Self )
               ENDIF
               hwg_edit_SetPos( ::handle, nPos )
               RETURN 1
            ENDIF
         ELSE
            RETURN 0
         ENDIF
      ENDIF
   ENDIF

   RETURN 0

METHOD Init()  CLASS HEdit

   IF !::lInit
      ::Super:Init()

      ::Refresh()
   ENDIF

   RETURN Nil

METHOD Refresh()  CLASS HEdit

   LOCAL vari

   IF ::bSetGet != Nil
      vari := Eval( ::bSetGet, , self )
   ELSE
      vari := ::title
   ENDIF
   IF !Empty( ::oPicture )
      vari := ::oPicture:Transform( vari )
   ELSE
      vari := iif( ::cType == "D", Dtoc( vari ), iif( ::cType == "N",Str(vari ),iif(::cType == "C",vari,"" ) ) )
   ENDIF
   ::title := vari
   hwg_Edit_SetText( ::handle, vari )
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
      hwg_Edit_SetText( ::handle, ::title )
      IF ::bSetGet != Nil
         Eval( ::bSetGet, xValue, Self )
      ENDIF
      RETURN xValue
   ENDIF

   vari := iif( Empty( ::handle ), ::title, hwg_Edit_GetText( ::handle ) )
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

   LOCAL nGetLen, nLen, vari, x, newPos
   LOCAL nDecimals, lMinus := .F.

   IF lFirst
      nPos := ::KeyRight( 0 )
   ENDIF

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

   LOCAL res := .T.

   oCtrl:Refresh()
   oCtrl:lFirst := .T.
   IF oCtrl:bGetFocus != Nil
      res := Eval( oCtrl:bGetFocus, oCtrl:title, oCtrl )
      IF !res
         hwg_GetSkip( oCtrl:oParent, oCtrl:handle, 1 )
      ENDIF
   ENDIF
   IF res .AND. !Empty( oCtrl:oPicture )
      oCtrl:oPicture:KeyRight( 0 )
   ENDIF

   RETURN res

STATIC FUNCTION __valid( oCtrl )

   LOCAL vari, oDlg

   IF oCtrl:bSetGet != Nil
      IF ( oDlg := hwg_getParentForm( oCtrl ) ) == Nil .OR. oDlg:nLastKey != 27
         vari := hwg_Edit_GetText( oCtrl:handle )
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
            hwg_edit_Settext( oCtrl:handle, oCtrl:title )
         ELSEIF oCtrl:cType == "C" .AND. !Empty( oCtrl:nMaxLength )
            oCtrl:title := vari := PadR( vari, oCtrl:nMaxLength )
         ENDIF
         Eval( oCtrl:bSetGet, vari, oCtrl )

         IF oDlg != Nil
            oDlg:nLastKey := 27
         ENDIF
         IF oCtrl:bLostFocus != Nil .AND. !Eval( oCtrl:bLostFocus, vari, oCtrl )
            hwg_Setfocus( oCtrl:handle )
            hwg_edit_SetPos( oCtrl:handle, 1 )
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

STATIC FUNCTION DoCopy( oEdit )

   LOCAL cText := hwg_Edit_GetText( oEdit:handle )
   LOCAL aPos := hwg_Edit_GetSelPos( oEdit:handle )
   IF aPos != Nil .AND. aPos[2] > aPos[1] .AND.aPos[2] - aPos[1] < hwg_Len( cText )
      hwg_Copystringtoclipboard( hwg_SubStr( cText, aPos[1]+1, aPos[2]-aPos[1] ) )
   ELSE
      hwg_Copystringtoclipboard( Iif( Empty(oEdit:oPicture), cText, ;
         oEdit:oPicture:UnTransform( oEdit, cText ) ) )
   ENDIF

   RETURN Nil

STATIC FUNCTION DoPaste( oEdit )

   LOCAL cClipboardText := hwg_Getclipboardtext(), i, nPos, cText, nLen := hwg_Len( cClipboardText )

   IF ! Empty( cClipboardText )
      cText := hwg_edit_Gettext( oEdit:handle )
      nPos := hwg_edit_Getpos( oEdit:handle )
      FOR i := 1 TO nLen
         //GetApplyKey( oEdit, hwg_SubStr( cClipboardText , nPos, 1 ) )
         cText := oEdit:oPicture:GetApplyKey( cText, @nPos, hwg_SubStr( cClipboardText,i,1 ), oEdit:lFirst, Set( _SET_INSERT ) )
         oEdit:lFirst := .F.
      NEXT
      oEdit:title := Iif( Empty(oEdit:oPicture), cText, oEdit:oPicture:UnTransform( cText ) )
      hwg_edit_Settext( oEdit:handle, oEdit:title )
      hwg_SetGetUpdated( oEdit )
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
      IF ( aLen := Len( oParent:Getlist ) ) > 1
         IF nSkip > 0
            DO WHILE ( i := i + nSkip ) <= aLen
               IF !oParent:Getlist[i]:lHide .AND. hwg_Iswindowenabled( oParent:Getlist[i]:Handle ) // Now tab and enter goes trhow the check, combo, etc...
                  IF oParent:Getlist[i]:winclass == "EDIT"
                     oParent:Getlist[i]:lFirst := .T.
                  ENDIF
                  hwg_Setfocus( oParent:Getlist[i]:handle )
                  RETURN .T.
               ENDIF
            ENDDO
         ELSE
            DO WHILE ( i := i + nSkip ) > 0
               IF !oParent:Getlist[i]:lHide .AND. hwg_Iswindowenabled( oParent:Getlist[i]:Handle )
                  IF oParent:Getlist[i]:winclass == "EDIT"
                     oParent:Getlist[i]:lFirst := .T.
                  ENDIF
                  hwg_Setfocus( oParent:Getlist[i]:handle )
                  RETURN .T.
               ENDIF
            ENDDO
         ENDIF
      ENDIF
   ENDIF

   RETURN .F.

FUNCTION hwg_SetGetUpdated( o )

   o:lChanged := .T.
   IF ( o := hwg_getParentForm( o ) ) != Nil
      o:lUpdated := .T.
   ENDIF

   RETURN Nil

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

   RETURN Iif( hb_cdpSelect()=="UTF8", hwg_keyToUtf8( nCode ), Chr( nCode ) )

FUNCTION hwg_Substr( cString, nPos, nLen )

   RETURN Iif( hb_cdpSelect()=="UTF8", ;
      Iif( nLen==Nil, hb_utf8Substr( cString, nPos ), hb_utf8Substr( cString, nPos, nLen ) ), ;
      Iif( nLen==Nil, Substr( cString, nPos ), Substr( cString, nPos, nLen ) ) )

FUNCTION hwg_Left( cString, nLen )

   RETURN Iif( hb_cdpSelect()=="UTF8", hb_utf8Left( cString, nLen ), Left( cString, nLen ) )

FUNCTION hwg_Len( cString )

   RETURN Iif( hb_cdpSelect()=="UTF8", hb_utf8Len( cString ), Len( cString ) )


FUNCTION hwg_GET_Helper(cp_get,nlen)

   LOCAL c_get

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
