/*
 *$Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HEdit class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

STATIC bColorOld
STATIC lColorinFocus := .F.

#include "windows.ch"
#include "hbclass.ch"
#include "hblang.ch"
#include "guilib.ch"

CLASS HEdit INHERIT HControl

   CLASS VAR winclass   INIT "EDIT"
   DATA lMultiLine   INIT .F.
   DATA cType INIT "C"
   DATA bSetGet
   DATA bValid
   DATA cPicFunc, cPicMask
   DATA lPicComplex  INIT .F.
   DATA lFirst       INIT .T.
   DATA lChanged     INIT .F.
   DATA lMaxLength   INIT Nil
   DATA nColorinFocus INIT hwg_VColor( 'CCFFFF' )
   DATA bkeydown, bkeyup, bchange

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, ;
      tcolor, bcolor, cPicture, lNoBorder, lMaxLength, lPassword, bKeyDown, bChange )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Redefine( oWnd, nId, vari, bSetGet, oFont, bInit, bSize, bDraw, bGfocus, ;
      bLfocus, ctooltip, tcolor, bcolor, cPicture, lMaxLength )
   METHOD Init()
   METHOD SetGet( value ) INLINE Eval( ::bSetGet, value, self )
   METHOD Refresh()
   METHOD SetText( c )

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, ;
      tcolor, bcolor, cPicture, lNoBorder, lMaxLength, lPassword, bKeyDown, bChange ) CLASS HEdit

   nStyle := Hwg_BitOr( iif( nStyle == Nil,0,nStyle ), ;
      WS_TABSTOP + iif( lNoBorder == Nil .OR. !lNoBorder, WS_BORDER, 0 ) + ;
      iif( lPassword == Nil .OR. !lPassword, 0, ES_PASSWORD )  )

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, iif( bcolor == Nil, hwg_Getsyscolor( COLOR_BTNHIGHLIGHT ), bcolor ) )

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

   IF !Empty( cPicture ) .OR. cPicture == Nil .AND. lMaxLength != Nil .OR. !Empty( lMaxLength )
      ::lMaxLength := lMaxLength
   ENDIF

   ParsePict( Self, cPicture, vari )
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
   IF bChange != Nil
      ::oParent:AddEvent( EN_CHANGE, ::id, bChange  )
   ENDIF

   RETURN Self

METHOD Activate CLASS HEdit

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createedit( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HEdit
   LOCAL oParent := ::oParent, nPos, nctrl, cKeyb
   LOCAL nexthandle

   IF ::bOther != Nil .AND. ( nPos := Eval( ::bOther, Self, msg, wParam, lParam ) ) != - 1
      RETURN nPos
   ENDIF
   wParam := hwg_PtrToUlong( wParam )
   // WriteLog( "Edit: "+Str(msg,10)+"|"+Str(wParam,10)+"|"+Str(lParam,10) )
   IF !::lMultiLine

      IF ::bSetGet != Nil
         IF msg == WM_CHAR
            IF ::bKeyDown != Nil .AND. ( nPos := Eval( ::bKeyDown, Self, wParam, lParam ) ) != -1
               RETURN nPos
            ENDIF
            IF wParam == VK_BACK
               ::lFirst := .F.
               hwg_SetGetUpdated( Self )
               IF ::lPicComplex
                  DeleteChar( Self, .T. )
                  RETURN 0
               ENDIF
               Return - 1
            ELSEIF wParam == VK_RETURN .OR. wParam == VK_ESCAPE
               Return - 1
            ELSEIF wParam == VK_TAB
               RETURN 0
            ENDIF
            // ------- Change by NightWalker - Check HiBit -------
            // If (wParam <129).or.!Empty( ::cPicFunc ).OR.!Empty( ::cPicMask )
            IF !hwg_IsCtrlShift( , .F. )
               RETURN GetApplyKey( Self, Chr( wParam ) )
            ENDIF
            // Endif

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
                  RETURN KeyRight( Self )
               ENDIF
            ELSEIF wParam == 37     // KeyLeft
               IF !hwg_IsCtrlShift()
                  ::lFirst := .F.
                  RETURN KeyLeft( Self )
               ENDIF
            ELSEIF wParam == 35     // End
               ::lFirst := .F.
               IF ::cType == "C"
                  nPos := Len( Trim( ::title ) )
                  hwg_Sendmessage( ::handle, EM_SETSEL, nPos, nPos )
                  RETURN 0
               ENDIF
            ELSEIF wParam == 45     // Insert
               IF !hwg_IsCtrlShift()
                  SET( _SET_INSERT, ! Set( _SET_INSERT ) )
               ENDIF
            ELSEIF wParam == 46     // Del
               ::lFirst := .F.
               hwg_SetGetUpdated( Self )
               IF ::lPicComplex
                  DeleteChar( Self, .F. )
                  RETURN 0
               ENDIF
            ELSEIF wParam == VK_TAB     // Tab
/*               IF Asc( Substr( hwg_Getkeyboardstate(), VK_SHIFT+1, 1 ) ) >= 128
                  hwg_GetSkip( oParent,::handle,-1 )
               ELSE
                  hwg_GetSkip( oParent,::handle,1 )
               ENDIF
               Return 0   */
               //****   Paulo Flecha
               IF Asc( SubStr( hwg_Getkeyboardstate(), VK_SHIFT + 1, 1 ) ) >= 128
                  IF !hwg_GetSkip( oParent, ::handle, - 1 ) // First Get
                     nextHandle := hwg_Getnextdlgtabitem ( hwg_Getactivewindow() , hwg_Getfocus() , .T. )
                     hwg_Postmessage( hwg_ParentGetDialog( Self ):handle, WM_NEXTDLGCTL, nextHandle , 1 )
                  ENDIF
               ELSE
                  IF !hwg_GetSkip( oParent, ::handle, 1 ) // Last Get
                     nextHandle := hwg_Getnextdlgtabitem ( hwg_Getactivewindow() , hwg_Getfocus() , .F. )
                     hwg_Postmessage( hwg_ParentGetDialog( Self ):handle, WM_NEXTDLGCTL, nextHandle , 1 )
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

         ENDIF
         /* Added by Sauli */
      ELSE
         IF msg == WM_KEYDOWN
            IF ::bKeyDown != Nil .AND. ( nPos := Eval( ::bKeyDown, Self, wParam, lParam ) ) != -1
               RETURN nPos
            ENDIF

            IF wParam == VK_TAB     // Tab
               IF Asc( SubStr( hwg_Getkeyboardstate(), VK_SHIFT + 1, 1 ) ) >= 128
                  nextHandle := hwg_Getnextdlgtabitem ( hwg_Getactivewindow() , hwg_Getfocus() , .T. )
                  hwg_Setfocus( nextHandle )
               ELSE
                  nextHandle := hwg_Getnextdlgtabitem ( hwg_Getactivewindow() , hwg_Getfocus() , .F. )
                  hwg_Setfocus( nextHandle )
               ENDIF
               RETURN 0
            end
         end
         /* Sauli */
      ENDIF

      IF lColorinFocus
         IF msg == WM_SETFOCUS
            bColorOld := ::bcolor
            ::Setcolor( ::tcolor , ::nColorinFocus, .T. )
         ELSEIF msg == WM_KILLFOCUS
            ::Setcolor( ::tcolor, bColorOld, .T. )
         ENDIF
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
         IF wParam == VK_TAB     // Tab
            IF Asc( SubStr( hwg_Getkeyboardstate(), VK_SHIFT + 1, 1 ) ) >= 128
               IF !hwg_GetSkip( oParent, ::handle, - 1 ) // First Get
                  nextHandle := hwg_Getnextdlgtabitem ( hwg_Getactivewindow() , hwg_Getfocus() , .T. )
                  hwg_Postmessage( hwg_ParentGetDialog( Self ):handle, WM_NEXTDLGCTL, nextHandle , 1 )
               ENDIF
            ELSE
               IF !hwg_GetSkip( oParent, ::handle, 1 ) // Last Get
                  nextHandle := hwg_Getnextdlgtabitem ( hwg_Getactivewindow() , hwg_Getfocus() , .F. )
                  hwg_Postmessage( hwg_ParentGetDialog( Self ):handle, WM_NEXTDLGCTL, nextHandle , 1 )
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
      /*
      IF wParam != 16 .AND. wParam != 17 .AND. wParam != 18
         DO WHILE oParent != Nil .AND. !__ObjHasMsg( oParent, "GETLIST" )
            oParent := oParent:oParent
         ENDDO
         IF oParent != Nil .AND. !Empty( oParent:KeyList )
            cKeyb := hwg_Getkeyboardstate()
            nctrl := iif( Asc( SubStr(cKeyb,VK_CONTROL + 1,1 ) ) >= 128, FCONTROL, iif( Asc(SubStr(cKeyb,VK_SHIFT + 1,1 ) ) >= 128,FSHIFT,0 ) )
            IF ( nPos := Ascan( oParent:KeyList,{ |a|a[1] == nctrl .AND. a[2] == wParam } ) ) > 0
               Eval( oParent:KeyList[ nPos,3 ], Self )
            ENDIF
         ENDIF
      ENDIF
      */
   ELSEIF msg == WM_GETDLGCODE
      IF !::lMultiLine
         RETURN DLGC_WANTARROWS + DLGC_WANTTAB + DLGC_WANTCHARS
      ENDIF
   ELSEIF msg == WM_DESTROY
      ::End()
   ENDIF

   Return - 1

METHOD Redefine( oWndParent, nId, vari, bSetGet, oFont, bInit, bSize, bPaint, ;
      bGfocus, bLfocus, ctooltip, tcolor, bcolor, cPicture, lMaxLength )  CLASS HEdit

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, iif( bcolor == Nil, hwg_Getsyscolor( COLOR_BTNHIGHLIGHT ), bcolor ) )

   IF vari != Nil
      ::cType   := ValType( vari )
   ENDIF
   ::bSetGet := bSetGet

   IF !Empty( cPicture ) .OR. cPicture == Nil .AND. lMaxLength != Nil .OR. !Empty( lMaxLength )
      ::lMaxLength := lMaxLength
   ENDIF

   ParsePict( Self, cPicture, vari )

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

METHOD Init()  CLASS HEdit

   IF !::lInit
      ::Super:Init()
      ::nHolder := 1
      hwg_Setwindowobject( ::handle, Self )
      Hwg_InitEditProc( ::handle )
      ::Refresh()
   ENDIF

   RETURN Nil

METHOD Refresh()  CLASS HEdit
   LOCAL vari

   IF ::bSetGet != Nil
      vari := Eval( ::bSetGet, , self )

      IF !Empty( ::cPicFunc ) .OR. !Empty( ::cPicMask )
         vari := Transform( vari, ::cPicFunc + iif( Empty(::cPicFunc ),""," " ) + ::cPicMask )
      ELSE
         vari := iif( ::cType == "D", Dtoc( vari ), iif( ::cType == "N",Str(vari ),iif(::cType == "C",vari,"" ) ) )
      ENDIF
      ::title := vari
      hwg_Setdlgitemtext( ::oParent:handle, ::id, vari )
   ELSE
      hwg_Setdlgitemtext( ::oParent:handle, ::id, ::title )
   ENDIF

   RETURN Nil

METHOD SetText( c ) CLASS HEdit

   IF c != Nil
      IF ValType( c ) = "O"
         //in run time return object
         RETURN nil
      ENDIF
      IF !Empty( ::cPicFunc ) .OR. !Empty( ::cPicMask )
         ::title := Transform( c, ::cPicFunc + iif( Empty(::cPicFunc ),""," " ) + ::cPicMask )
      ELSE
         ::title := c
      ENDIF
      ::Super:SetText( ::title )
      IF ::bSetGet != Nil
         Eval( ::bSetGet, c, self )
      ENDIF
   ENDIF

   RETURN NIL

FUNCTION hwg_IsCtrlShift( lCtrl, lShift )
   LOCAL cKeyb := hwg_Getkeyboardstate()

   IF lCtrl == Nil; lCtrl := .T. ; ENDIF
   IF lShift == Nil; lShift := .T. ; ENDIF

   RETURN ( lCtrl .AND. ( Asc(SubStr(cKeyb,VK_CONTROL + 1,1 ) ) >= 128 ) ) .OR. ;
      ( lShift .AND. ( Asc(SubStr(cKeyb,VK_SHIFT + 1,1 ) ) >= 128 ) )

STATIC FUNCTION ParsePict( oEdit, cPicture, vari )
   LOCAL nAt, i, masklen, cChar

   IF oEdit:bSetGet == Nil
      RETURN Nil
   ENDIF
   oEdit:cPicFunc := oEdit:cPicMask := ""
   IF cPicture != Nil
      IF Left( cPicture, 1 ) == "@"
         nAt := At( " ", cPicture )
         IF nAt == 0
            oEdit:cPicFunc := Upper( cPicture )
            oEdit:cPicMask := ""
         ELSE
            oEdit:cPicFunc := Upper( SubStr( cPicture, 1, nAt - 1 ) )
            oEdit:cPicMask := SubStr( cPicture, nAt + 1 )
         ENDIF
         IF oEdit:cPicFunc == "@"
            oEdit:cPicFunc := ""
         ENDIF
      ELSE
         oEdit:cPicFunc   := ""
         oEdit:cPicMask   := cPicture
      ENDIF
   ENDIF

   IF Empty( oEdit:cPicMask )
      IF oEdit:cType == "D"
         oEdit:cPicMask := StrTran( Dtoc( CToD( Space(8 ) ) ), ' ', '9' )
      ELSEIF oEdit:cType == "N"
         vari := Str( vari )
         IF ( nAt := At( ".", vari ) ) > 0
            oEdit:cPicMask := Replicate( '9', nAt - 1 ) + "." + ;
               Replicate( '9', Len( vari ) - nAt )
         ELSE
            oEdit:cPicMask := Replicate( '9', Len( vari ) )
         ENDIF
      ENDIF
   ENDIF

   IF !Empty( oEdit:cPicMask )
      masklen := Len( oEdit:cPicMask )
      FOR i := 1 TO masklen
         cChar := SubStr( oEdit:cPicMask, i, 1 )
         IF !cChar $ "!ANX9#"
            oEdit:lPicComplex := .T.
            EXIT
         ENDIF
      NEXT
   ENDIF

   //                                         ------------ added by Maurizio la Cecilia

   IF oEdit:lMaxLength != Nil .AND. !Empty( oEdit:lMaxLength ) .AND. Len( oEdit:cPicMask ) < oEdit:lMaxLength
      oEdit:cPicMask := PadR( oEdit:cPicMask, oEdit:lMaxLength, "X" )
   ENDIF

   //                                         ------------- end of added code

   RETURN Nil

STATIC FUNCTION IsEditable( oEdit, nPos )
   LOCAL cChar

   IF Empty( oEdit:cPicMask )
      RETURN .T.
   ENDIF
   IF nPos > Len( oEdit:cPicMask )
      RETURN .F.
   ENDIF

   cChar := SubStr( oEdit:cPicMask, nPos, 1 )

   IF oEdit:cType == "C"
      RETURN cChar $ "!ANX9#"
   ELSEIF oEdit:cType == "N"
      RETURN cChar $ "9#$*"
   ELSEIF oEdit:cType == "D"
      RETURN cChar == "9"
   ELSEIF oEdit:cType == "L"
      RETURN cChar $ "TFYN"
   ENDIF

   RETURN .F.

STATIC FUNCTION KeyRight( oEdit, nPos )
   LOCAL i, masklen, newpos, vari

   IF oEdit == Nil
      Return - 1
   ENDIF
   IF nPos == Nil
      nPos := hwg_Hiword( hwg_Sendmessage( oEdit:handle, EM_GETSEL, 0, 0 ) ) + 1
   ENDIF
   IF oEdit:cPicMask == Nil .OR. Empty( oEdit:cPicMask )
      hwg_Sendmessage( oEdit:handle, EM_SETSEL, nPos, nPos )
   ELSE
      masklen := Len( oEdit:cPicMask )
      DO WHILE nPos <= masklen
         IF IsEditable( oEdit, ++ nPos )
            // writelog( "KeyRight-2 "+str(nPos) )
            hwg_Sendmessage( oEdit:handle, EM_SETSEL, nPos - 1, nPos - 1 )
            EXIT
         ENDIF
      ENDDO
   ENDIF

   //Added By Sandro Freire

   IF !Empty( oEdit:cPicMask )
      newPos := Len( oEdit:cPicMask )
      //writelog( "KeyRight-2 "+str(nPos) + " " +str(newPos) )
      IF nPos > newPos .AND. !Empty( Trim( oEdit:Title ) )
         hwg_Sendmessage( oEdit:handle, EM_SETSEL, newPos, newPos )
      ENDIF
   ENDIF

   RETURN 0

STATIC FUNCTION KeyLeft( oEdit, nPos )
   LOCAL i

   IF oEdit == Nil
      Return - 1
   ENDIF
   IF nPos == Nil
      nPos := hwg_Hiword( hwg_Sendmessage( oEdit:handle, EM_GETSEL, 0, 0 ) ) + 1
   ENDIF
   IF oEdit:cPicMask == Nil .OR. Empty( oEdit:cPicMask )
      hwg_Sendmessage( oEdit:handle, EM_SETSEL, nPos - 2, nPos - 2 )
   ELSE
      DO WHILE nPos >= 1
         IF IsEditable( oEdit, -- nPos )
            hwg_Sendmessage( oEdit:handle, EM_SETSEL, nPos - 1, nPos - 1 )
            EXIT
         ENDIF
      ENDDO
   ENDIF

   RETURN 0

STATIC FUNCTION DeleteChar( oEdit, lBack )
   LOCAL nPos := hwg_Hiword( hwg_Sendmessage( oEdit:handle, EM_GETSEL, 0, 0 ) ) + iif( !lBack, 1, 0 )
   LOCAL nGetLen := Len( oEdit:cPicMask ), nLen

   FOR nLen := 0 TO nGetLen
      IF !IsEditable( oEdit, nPos + nLen )
         EXIT
      ENDIF
   NEXT
   IF nLen == 0
      DO WHILE nPos >= 1
         nPos --
         nLen ++
         IF IsEditable( oEdit, nPos )
            EXIT
         ENDIF
      ENDDO
   ENDIF
   IF nPos > 0
      oEdit:title := PadR( Left( oEdit:title, nPos - 1 ) + ;
         SubStr( oEdit:title, nPos + 1, nLen - 1 ) + " " + ;
         SubStr( oEdit:title, nPos + nLen ), nGetLen )
      hwg_Setdlgitemtext( oEdit:oParent:handle, oEdit:id, oEdit:title )
      hwg_Sendmessage( oEdit:handle, EM_SETSEL, nPos - 1, nPos - 1 )
   ENDIF

   RETURN Nil

STATIC FUNCTION INPUT( oEdit, cChar, nPos )
   LOCAL cPic

   IF !Empty( oEdit:cPicMask ) .AND. nPos > Len( oEdit:cPicMask )
      RETURN Nil
   ENDIF
   IF oEdit:cType == "N"
      IF cChar == "-"
         IF nPos != 1
            RETURN Nil
         ENDIF
         // ::minus := .t.
      ELSEIF !( cChar $ "0123456789" )
         RETURN Nil
      ENDIF

   ELSEIF oEdit:cType == "D"

      IF !( cChar $ "0123456789" )
         RETURN Nil
      ENDIF

   ELSEIF oEdit:cType == "L"

      IF !( Upper( cChar ) $ "YNTF" )
         RETURN Nil
      ENDIF

   ENDIF

   IF !Empty( oEdit:cPicFunc )
      cChar := Transform( cChar, oEdit:cPicFunc )
   ENDIF

   IF !Empty( oEdit:cPicMask )
      cPic  := SubStr( oEdit:cPicMask, nPos, 1 )

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

   RETURN cChar

STATIC FUNCTION GetApplyKey( oEdit, cKey )
   LOCAL nPos, nGetLen, nLen, vari, i, x, newPos
   LOCAL nDecimals, nTmp

   x := hwg_Sendmessage( oEdit:handle, EM_GETSEL, 0, 0 )
   IF hwg_Hiword( x ) != hwg_Loword( x )
      hwg_Sendmessage( oEdit:handle, WM_CLEAR, hwg_Loword( x ), hwg_Hiword( x ) - 1 )
   ENDIF

   // writelog( "GetApplyKey "+str(asc(ckey)) )
   oEdit:title := hwg_Getedittext( oEdit:oParent:handle, oEdit:id )
   IF oEdit:cType == "N" .AND. cKey $ ".," .AND. ;
         ( nPos := At( ".",oEdit:cPicMask ) ) != 0
      IF oEdit:lFirst
         vari := 0
      ELSE
         vari := Trim( oEdit:title )
         FOR i := 2 TO Len( vari )
            IF !IsDigit( SubStr( vari,i,1 ) )
               vari := Left( vari, i - 1 ) + SubStr( vari, i + 1 )
            ENDIF
         NEXT
         vari := Val( vari )
      ENDIF
      IF !Empty( oEdit:cPicFunc ) .OR. !Empty( oEdit:cPicMask )
         oEdit:title := Transform( vari, oEdit:cPicFunc + iif( Empty(oEdit:cPicFunc ),""," " ) + oEdit:cPicMask )
      ENDIF
      hwg_Setdlgitemtext( oEdit:oParent:handle, oEdit:id, oEdit:title )
      KeyRight( oEdit, nPos - 1 )
   ELSE

      IF oEdit:cType == "N" .AND. oEdit:lFirst
         // hwg_Setdlgitemtext( oEdit:oParent:handle, oEdit:id, "" )
         nGetLen := Len( oEdit:cPicMask )
         IF ( nPos := At( ".",oEdit:cPicMask ) ) == 0
            oEdit:title := Space( nGetLen )
         ELSE
            oEdit:title := Space( nPos - 1 ) + "." + Space( nGetLen - nPos )
         ENDIF
         nPos := 1
      ELSE
         nPos := hwg_Hiword( hwg_Sendmessage( oEdit:handle, EM_GETSEL, 0, 0 ) ) + 1
      ENDIF
      cKey := Input( oEdit, cKey, nPos )
      IF cKey != Nil
         hwg_SetGetUpdated( oEdit )
         IF SET( _SET_INSERT ) .OR. hwg_Hiword( x ) != hwg_Loword( x )
            IF oEdit:lPicComplex
               nGetLen := Len( oEdit:cPicMask )
               FOR nLen := 0 TO nGetLen
                  IF !IsEditable( oEdit, nPos + nLen )
                     EXIT
                  ENDIF
               NEXT
               oEdit:title := Left( oEdit:title, nPos - 1 ) + cKey + ;
                  SubStr( oEdit:title, nPos, nLen - 1 ) + SubStr( oEdit:title, nPos + nLen )
            ELSE
               oEdit:title := Left( oEdit:title, nPos - 1 ) + cKey + ;
                  SubStr( oEdit:title, nPos )
            ENDIF

            IF !Empty( oEdit:cPicMask ) .AND. Len( oEdit:cPicMask ) < Len( oEdit:title )
               //oEdit:title := Left( oEdit:title,nGetLen ) + cKey //Bug fixed
               oEdit:title := Left( oEdit:title, nPos - 1 ) + cKey + SubStr( oEdit:title, nPos + 1 )
            ENDIF
         ELSE
            oEdit:title := Left( oEdit:title, nPos - 1 ) + cKey + SubStr( oEdit:title, nPos + 1 )
         ENDIF
         hwg_Setdlgitemtext( oEdit:oParent:handle, oEdit:id, oEdit:title )
         // writelog( "GetApplyKey "+oEdit:title+str(nPos-1) )
         KeyRight( oEdit, nPos )
         //Added By Sandro Freire
         IF oEdit:cType == "N"

            IF !Empty( oEdit:cPicMask )

               nDecimals := Len( SubStr(  oEdit:cPicMask, At( ".", oEdit:cPicMask ), Len( oEdit:cPicMask ) ) )

               IF nDecimals <= 0
                  nDecimals := 3
               ENDIF
               newPos := Len( oEdit:cPicMask ) - nDecimals

               IF "E" $ oEdit:cPicFunc .AND. nPos == newPos
                  GetApplyKey( oEdit, "," )
               ENDIF
            ENDIF

         ENDIF

      ENDIF
   ENDIF
   oEdit:lFirst := .F.

   RETURN 0

STATIC FUNCTION __When( oCtrl )
   LOCAL res

   oCtrl:Refresh()
   oCtrl:lFirst := .T.
   IF oCtrl:bGetFocus != Nil
      res := Eval( oCtrl:bGetFocus, oCtrl:title, oCtrl )
      IF !res
         hwg_GetSkip( oCtrl:oParent, oCtrl:handle, 1 )
      ENDIF
      RETURN res
   ENDIF

   RETURN .T.

STATIC FUNCTION __valid( oCtrl )
   LOCAL vari, oDlg

   IF oCtrl:bSetGet != Nil
      IF ( oDlg := hwg_ParentGetDialog( oCtrl ) ) == Nil .OR. oDlg:nLastKey != 27
         vari := UnTransform( oCtrl, hwg_Getedittext( oCtrl:oParent:handle, oCtrl:id ) )
         oCtrl:title := vari
         IF oCtrl:cType == "D"
            IF IsBadDate( vari )
               hwg_Setfocus( oCtrl:handle )
               RETURN .F.
            ENDIF
            vari := CToD( vari )
         ELSEIF oCtrl:cType == "N"
            vari := Val( LTrim( vari ) )
            oCtrl:title := Transform( vari, oCtrl:cPicFunc + iif( Empty(oCtrl:cPicFunc ),""," " ) + oCtrl:cPicMask )
            hwg_Setdlgitemtext( oCtrl:oParent:handle, oCtrl:id, oCtrl:title )
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

STATIC FUNCTION Untransform( oEdit, cBuffer )
   LOCAL xValue, cChar, nFor, minus

   IF oEdit:cType == "C"

      IF "R" $ oEdit:cPicFunc
         FOR nFor := 1 TO Len( oEdit:cPicMask )
            cChar := SubStr( oEdit:cPicMask, nFor, 1 )
            IF !cChar $ "ANX9#!"
               cBuffer := SubStr( cBuffer, 1, nFor - 1 ) + Chr( 1 ) + SubStr( cBuffer, nFor + 1 )
            ENDIF
         NEXT
         cBuffer := StrTran( cBuffer, Chr( 1 ), "" )
      ENDIF

      xValue := cBuffer

   ELSEIF oEdit:cType == "N"
      minus := ( Left( LTrim( cBuffer ),1 ) == "-" )
      cBuffer := Space( FirstEditable( oEdit ) - 1 ) + SubStr( cBuffer, FirstEditable( oEdit ), LastEditable( oEdit ) - FirstEditable( oEdit ) + 1 )

      IF "D" $ oEdit:cPicFunc
         FOR nFor := FirstEditable( oEdit ) TO LastEditable( oEdit )
            IF !IsEditable( oEdit, nFor )
               cBuffer = Left( cBuffer, nFor - 1 ) + Chr( 1 ) + SubStr( cBuffer, nFor + 1 )
            ENDIF
         NEXT
      ELSE
         IF "E" $ oEdit:cPicFunc
            cBuffer := Left( cBuffer, FirstEditable( oEdit ) - 1 ) +           ;
               StrTran( SubStr( cBuffer, FirstEditable(oEdit ),      ;
               LastEditable( oEdit ) - FirstEditable( oEdit ) + 1 ), ;
               ".", " " ) + SubStr( cBuffer, LastEditable( oEdit ) + 1 )
            cBuffer := Left( cBuffer, FirstEditable( oEdit ) - 1 ) +           ;
               StrTran( SubStr( cBuffer, FirstEditable(oEdit ),      ;
               LastEditable( oEdit ) - FirstEditable( oEdit ) + 1 ), ;
               ",", "." ) + SubStr( cBuffer, LastEditable( oEdit ) + 1 )
         ELSE
            cBuffer := Left( cBuffer, FirstEditable( oEdit ) - 1 ) +        ;
               StrTran( SubStr( cBuffer, FirstEditable(oEdit ),   ;
               LastEditable( oEdit ) - FirstEditable( oEdit ) + 1 ), ;
               ",", " " ) + SubStr( cBuffer, LastEditable( oEdit ) + 1 )
         ENDIF

         FOR nFor := FirstEditable( oEdit ) TO LastEditable( oEdit )
            IF !IsEditable( oEdit, nFor ) .AND. SubStr( cBuffer, nFor, 1 ) != "."
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

   ELSEIF oEdit:cType == "L"

      cBuffer := Upper( cBuffer )
      xValue := "T" $ cBuffer .OR. "Y" $ cBuffer .OR. hb_langmessage( HB_LANG_ITEM_BASE_TEXT + 1 ) $ cBuffer

   ELSEIF oEdit:cType == "D"

      IF "E" $ oEdit:cPicFunc
         cBuffer := SubStr( cBuffer, 4, 3 ) + SubStr( cBuffer, 1, 3 ) + SubStr( cBuffer, 7 )
      ENDIF
      xValue := cBuffer

   ENDIF

   RETURN xValue

STATIC FUNCTION FirstEditable( oEdit )
   LOCAL nFor, nMaxLen := Len( oEdit:cPicMask )

   IF IsEditable( oEdit, 1 )
      RETURN 1
   ENDIF

   FOR nFor := 2 TO nMaxLen
      IF IsEditable( oEdit, nFor )
         RETURN nFor
      ENDIF
   NEXT

   RETURN 0

STATIC FUNCTION  LastEditable( oEdit )
   LOCAL nFor, nMaxLen := Len( oEdit:cPicMask )

   FOR nFor := nMaxLen TO 1 step - 1
      IF IsEditable( oEdit, nFor )
         RETURN nFor
      ENDIF
   NEXT

   RETURN 0

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
   IF ( o := hwg_ParentGetDialog( o ) ) != Nil
      o:lUpdated := .T.
   ENDIF

   RETURN Nil

FUNCTION hwg_ParentGetDialog( o )

   DO WHILE .T.
      o := o:oParent
      IF o == Nil
         EXIT
      ELSE
         IF __ObjHasMsg( o, "GETLIST" )
            EXIT
         ENDIF
      ENDIF
   ENDDO

   RETURN o

FUNCTION hwg_SetColorinFocus( lDef )

   IF ValType( lDef ) <> "L"
      RETURN .F.
   ENDIF
   lColorinFocus := lDef

   RETURN .T.
