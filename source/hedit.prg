
/*
 *$Id: hedit.prg,v 1.151 2009-11-19 13:43:08 lfbasso Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HEdit class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

STATIC lColorinFocus := .F.
STATIC lFixedColor   := .T.
STATIC tColorSelect  := 0
STATIC bColorSelect  := 13434879 //vcolor( 'CCFFFF' )

#include "windows.ch"
#include "hbclass.ch"
#include "hblang.ch"
#include "guilib.ch"

#define VK_C  67
#define VK_V  86
#define VK_X  87

CLASS HEdit INHERIT HControl

CLASS VAR winclass   INIT "EDIT"
   DATA tColorOld, bColorOld
   DATA lMultiLine   INIT .F.
   DATA lWantReturn  INIT .F.  HIDDEN
   DATA cType        INIT "C"
   DATA bSetGet
   DATA bValid
   DATA bkeydown, bkeyup, bchange
   DATA cPicture, cPicFunc, cPicMask
   DATA lPicComplex    INIT .F.
   DATA lFirst         INIT .T.
   DATA lChanged       INIT .F.
   DATA nMaxLength     INIT Nil
   //DATA nColorinFocus  INIT vcolor( 'CCFFFF' )
   DATA lFocu          INIT .F.
   DATA lReadOnly      INIT .F.
   DATA oUpDown
   DATA lCopy  INIT .F.  HIDDEN

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
               oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, tcolor, bcolor, cPicture, ;
               lNoBorder, nMaxLength, lPassword, bKeyDown, bChange, bOther )
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
   METHOD When() //PROTECTED
   METHOD onChange() //PROTECTED
   METHOD IsBadDate( cBuffer ) PROTECTED
   METHOD Untransform( cBuffer ) PROTECTED
   METHOD FirstEditable() PROTECTED
   METHOD FirstNotEditable( nPos ) PROTECTED
   METHOD LastEditable() PROTECTED
   METHOD SetGetUpdated() PROTECTED
   METHOD ReadOnly( lreadOnly ) SETGET

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
            oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, tcolor, bcolor, ;
            cPicture, lNoBorder, nMaxLength, lPassword, bKeyDown, bChange, bOther ) CLASS HEdit


   nStyle := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), ;
                        WS_TABSTOP + IIf( lNoBorder == Nil .OR. ! lNoBorder, WS_BORDER, 0 ) + ;
                        IIf( lPassword == Nil .or. ! lPassword, 0, ES_PASSWORD )  )

*   IF owndParent:oParent != Nil
   bPaint := { | o, p | o:paint( p ) }
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
   ::bChange := bChange
   ::bOther := bOther
   IF Hwg_BitAnd( nStyle, ES_MULTILINE ) != 0
      //IF Hwg_BitAnd( nStyle, ES_WANTRETURN ) != 0
       ::lMultiLine := .T.
       ::lWantReturn := Hwg_BitAnd( nStyle, ES_WANTRETURN ) != 0
      //ENDIF
   ENDIF
   IF ( ! Empty( cPicture ) .or. cPicture == Nil) .And. ( nMaxLength != Nil .AND. ! Empty( nMaxLength ) )
      ::nMaxLength := nMaxLength
   ENDIF
   IF ::cType == "N" .AND. Hwg_BitAnd( nStyle, ES_LEFT + ES_CENTER ) == 0
      ::style := Hwg_BitOr( ::style, ES_RIGHT + ES_NUMBER )
      cPicture := IIf( cPicture == Nil.and.::nMaxLength != Nil, Replicate( "9", ::nMaxLength ), cPicture )
   ENDIF
   IF ::cType == "D" .AND. bSetGet != Nil
      ::nMaxLength := LEN( DTOC( vari ) ) //IIF( SET( _SET_CENTURY ), 10, 8 )
   ENDIF
   //IF ! Empty( cPicture ) .or. cPicture == Nil .And. nMaxLength != Nil .or. ! Empty( nMaxLength )
   //   ::nMaxLength := nMaxLength
   //ENDIF
   ::ParsePict( cPicture, vari )

   ::Activate()

   IF ::bSetGet != Nil
      ::bGetFocus := bGfocus
      ::bLostFocus := bLfocus
      IF bGfocus != Nil
         ::lnoValid := .T.
         ::oParent:AddEvent( EN_SETFOCUS, Self, { | | ::When( ) },, "onGotFocus"  )
      ENDIF
      ::oParent:AddEvent( EN_KILLFOCUS, Self, { | | ::Valid( ) },, "onLostFocus" )
      ::bValid := { | | ::Valid( ) }
   ELSE
      IF bGfocus != Nil
         ::oParent:AddEvent( EN_SETFOCUS, Self, { | | ::When( ) },, "onGotFocus"  )
      ENDIF
      IF bLfocus != Nil
         ::oParent:AddEvent( EN_KILLFOCUS, Self, { | | ::Valid( ) },, "onLostFocus" )
         ::bValid := { | | ::Valid( ) }
      ENDIF
   ENDIF
   ::bColorOld := ::bcolor
   ::tColorOld := IIf( tcolor = Nil, 0, ::tcolor )

   IF ::cType != "D"
       SET( _SET_INSERT, .T. )
    ENDIF

   RETURN Self

METHOD Activate CLASS HEdit
   IF ! Empty( ::oParent:handle )
      ::handle := CreateEdit( ::oParent:handle, ::id, ;
                              ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF
   RETURN Nil

METHOD Init()  CLASS HEdit

   IF ! ::lInit
      Super:Init()
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      Hwg_InitEditProc( ::handle )
      ::Refresh()
      IF ::bChange != Nil .OR. ::lMultiLine
         ::oParent:AddEvent( EN_CHANGE, Self, { | | ::onChange( ) },, "onChange"  )
      ENDIF
   ENDIF
   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HEdit
   LOCAL oParent := ::oParent, nPos
   LOCAL nextHandle, nShiftAltCtrl
   LOCAL cClipboardText := ""

   IF ::bOther != Nil
      IF Eval( ::bOther, Self, msg, wParam, lParam ) != - 1
         RETURN 0
      ENDIF
   ENDIF

   IF ! ::lMultiLine

      IF ::bSetGet != Nil

         IF msg = WM_COPY .OR. msg = WM_CUT
            ::lcopy := .T.
            RETURN - 1
         ELSEIF ::lCopy .AND. ( msg = WM_MOUSELEAVE .OR. ( msg = WM_KEYUP .AND. ( wParam = VK_C .OR. wParam = VK_X ) ) )
            ::lcopy := .F.
            COPYSTRINGTOCLIPBOARD( ::UnTransform( GETCLIPBOARDTEXT() ) )
            RETURN -1
         ELSEIF msg = WM_PASTE
              ::lFirst := .F.
                cClipboardText :=  GETCLIPBOARDTEXT()
            IF ! EMPTY( cClipboardText )
                 nPos := HIWORD( SendMessage( ::handle, EM_GETSEL, 0, 0 ) ) + 1
               SendMessage(  ::handle, EM_SETSEL, nPos-1 , nPos -1  )
               FOR nPos = 1 to Len( cClipboardText )
                     ::GetApplyKey( SUBSTR( cClipboardText , nPos, 1 ) )
               NEXT
               nPos := HIWORD( SendMessage( ::handle, EM_GETSEL, 0, 0 ) ) + 1
               ::title := ::UnTransform( GetEditText( ::oParent:handle, ::id ) )
               SendMessage(  ::handle, EM_SETSEL, nPos - 1 , nPos - 1 )
              ENDIF
            RETURN 0
         ELSEIF msg == WM_CHAR

            IF ! CheckBit( lParam, 32 ) .AND.::bKeyDown != Nil .and. ValType( ::bKeyDown ) == 'B'
               nShiftAltCtrl := IIF( IsCtrlShift( .F., .T. ), 1 , 0 )
               nShiftAltCtrl += IIF( IsCtrlShift( .T., .F. ), 2 , 0 )
               nShiftAltCtrl += IIF( Checkbit( lParam, 28 ), 4, 0 )
               IF ! Eval( ::bKeyDown, Self, wParam, nShiftAltCtrl  )
                  RETURN 0
               ENDIF
            ENDIF
            IF wParam == VK_BACK
               ::lFirst := .F.
               ::lFocu := .F.
               ::SetGetUpdated()
               ::DeleteChar( .T. )
               RETURN 0
            ELSEIF wParam == VK_RETURN
                     IF ( ::GetParentForm( Self ):Type < WND_DLG_RESOURCE.OR.;
                   ! ::GetParentForm( Self ):lModal )
                   GetSkip( oParent, ::handle, , 1 )
                  RETURN 0
               ENDIF
               RETURN -1
            ELSEIF wParam == VK_TAB
                     IF ( ::GetParentForm( Self ):Type < WND_DLG_RESOURCE.OR.;
                   ! ::GetParentForm( Self ):lModal )
                  GetSkip( oParent, ::handle, , iif( IsCtrlShift(.f., .t.), -1, 1) )
               ENDIF
               RETURN 0
            ELSEIF wParam == VK_ESCAPE
               //sendmessage( ::handle, WM_KILLFOCUS, 0,  0)
               RETURN 0 //-1
            ENDIF
            //
            IF ::lFocu
               IF ::cType = "N" .AND. SET( _SET_INSERT )
                  ::lFirst := .T.
               ENDIF
               IF ! lFixedColor
                  ::SetColor( ::tcolorOld, ::bColorOld, .t. )
                  SendMessage( ::handle, WM_MOUSEMOVE, 0, MAKELPARAM( 1, 1 ) )
               ENDIF
               ::lFocu := .F.
            ENDIF
            //
            IF ! IsCtrlShift( , .F. )
               RETURN ::GetApplyKey( Chr( wParam ) )
            ENDIF

         ELSEIF msg == WM_KEYDOWN
            IF ( CheckBit( lParam, 25 ) .OR. wParam > 111 ) .AND. ::bKeyDown != Nil .and. ValType( ::bKeyDown ) == 'B'
               nShiftAltCtrl := IIF( IsCtrlShift( .F., .T. ), 1 , 0 )
               nShiftAltCtrl += IIF( IsCtrlShift( .T., .F. ), 2 , 0 )
               nShiftAltCtrl += IIF( Checkbit( lParam, 28 ), 4, 0 )
               IF !Eval( ::bKeyDown, Self, wParam, nShiftAltCtrl  )
                  RETURN 0
               ENDIF
            ENDIF
            IF wParam == 40 .AND. ::oUpDown != Nil // KeyDown
               RETURN - 1
            ELSEIF wParam == 40 .OR. ( wParam == 39 .AND. ::oUpDown != Nil )   // KeyDown
               IF ! IsCtrlShift()
                  GetSkip( oParent, ::handle, , 1 )
                  RETURN 0
               ENDIF
            ELSEIF wParam == 38 .AND. ::oUpDown != Nil   // KeyUp
               RETURN - 1
            ELSEIF wParam == 38 .OR.( wParam == 37 .AND. ::oUpDown != Nil )   // KeyUp
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
                        IIf( IsCtrlShift( .f., .t. ), - 1, 1 ) )
               RETURN 0
            ELSEIF wParam == VK_RETURN  // Enter
               *GetSkip( oParent, ::handle, .T., 1 )
               RETURN 0
            ENDIF

         ELSEIF msg == WM_LBUTTONDOWN
            IF GetFocus() != ::handle
               SetFocus( ::handle )
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
               nextHandle := GetNextDlgTabItem ( GetActiveWindow(), GetFocus(), ;
                                                 IsCtrlShift( .f., .t. ) )
               SetFocus( nextHandle )
               RETURN 0
            ELSEIF wParam == VK_RETURN .AND. ::GetParentForm():Type < WND_DLG_RESOURCE
               GetSkip( oParent, ::handle, , 1 )
               RETURN 0
            ENDIF
         ENDIF
      ENDIF
      IF msg == WM_SETFOCUS //.AND. ::cType = "N"
         ::lFocu := .T.
         IF ::oUpDown != Nil  // necessary because fail event in opdown if used command SETFOCUS() directly
             ::when()
         ENDIF
      ENDIF
      IF lColorinFocus
         IF msg == WM_SETFOCUS
//            ::bColorOld := ::bcolor
            ::SetColor( tcolorselect, bcolorselect )
            //::SetColor( ::tcolor , ::nColorinFocus, .T. )
         ELSEIF msg == WM_KILLFOCUS
            //::SetColor( ::tcolor, ::bColorOld, .t. )
            ::SetColor( ::tcolorOld, ::bColorOld, .t. )
            SendMessage( ::handle, WM_MOUSEMOVE, 0, MAKELPARAM( 1, 1 ) )
         ENDIF
      ENDIF
   ELSE
     // multiline
        IF msg = WM_SETFOCUS
         //nPos := HIWORD( SendMessage( ::handle, EM_GETSEL, 0, 0 ) ) + 1
         PostMessage( ::handle, EM_SETSEL, 0, 0 )
      ELSEIF msg == WM_MOUSEWHEEL
         nPos := HIWORD( wParam )
         nPos := IIf( nPos > 32768, nPos - 65535, nPos )
         SendMessage( ::handle, EM_SCROLL, IIf( nPos > 0, SB_LINEUP, SB_LINEDOWN ), 0 )
         //SendMessage( ::handle, EM_SCROLL, IIf( nPos > 0, SB_LINEUP, SB_LINEDOWN ), 0 )
      ELSEIF msg == WM_CHAR
         IF wParam == VK_TAB
               GetSkip( oParent, ::handle, , ;
                      iif( IsCtrlShift(.f., .t.), -1, 1) )
            RETURN 0
         ELSEIF wParam == VK_ESCAPE
            RETURN 0
         ELSEIF wParam == VK_RETURN .AND. ! ::lWantReturn .AND. ::bSetGet != Nil
                //IF ( ::GetParentForm():Type < WND_DLG_RESOURCE.OR.;
            //     ! ::GetParentForm():lModal )
                 GetSkip( oParent, ::handle, , 1 )
                 RETURN 0
            //ENDIF
            //RETURN -1
         ENDIF
      ELSEIF msg == WM_KEYDOWN
         IF wParam == VK_ESCAPE
            RETURN -1
         ENDIF
         IF wParam == VK_TAB     // Tab
        //    GetSkip( oParent, ::handle, , ;
        //             IIf( IsCtrlShift( .f., .t. ), - 1, 1 ) )
            RETURN 0
         ENDIF
         IF ::bKeyDown != Nil .and. ValType( ::bKeyDown ) == 'B'
             IF !Eval( ::bKeyDown, Self, wParam )
                RETURN 0
             ENDIF
         ENDIF
      ENDIF
      // END multiline
   ENDIF

   //IF msg == WM_KEYDOWN
   IF msg == WM_KEYUP .OR. msg == WM_SYSKEYUP     /* BETTER FOR DESIGNER */

      IF ! ProcKeyList( Self, wParam )
         IF ::bKeyUp != Nil
            IF ! Eval( ::bKeyUp, Self, wParam )
               RETURN - 1
            ENDIF
         ENDIF
      ENDIF

      /*
      IF wParam != 16 .AND. wParam != 17 .AND. wParam != 18
         DO WHILE oParent != Nil .AND. ! __ObjHasMsg( oParent, "GETLIST" )
            oParent := oParent:oParent
         ENDDO
         IF oParent != Nil .AND. ! Empty( oParent:KeyList )
            nctrl := IIf( IsCtrlShift( .t., .f. ), FCONTROL, IIf( IsCtrlShift( .f., .t. ), FSHIFT, 0 ) )
            IF ( nPos := AScan( oParent:KeyList, { | a | a[ 1 ] == nctrl.AND.a[ 2 ] == wParam } ) ) > 0
               Eval( oParent:KeyList[ nPos, 3 ], Self )
            ENDIF
         ENDIF
      ENDIF
      */
   ELSEIF msg == WM_GETDLGCODE
      IF ! ::lMultiLine .OR. wParam = VK_ESCAPE
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
      ::oParent:AddEvent( EN_SETFOCUS, Self, { | | ::When( ) },, "onGotFocus" )
      ::oParent:AddEvent( EN_KILLFOCUS, Self, { | | ::Valid( ) },, "onLostFocus" )
      ::bValid := { | | ::Valid() }
   ELSE
      IF bGfocus != Nil
         ::oParent:AddEvent( EN_SETFOCUS, Self, bGfocus,, "onGotFocus"  )
      ENDIF
      IF bLfocus != Nil
         ::oParent:AddEvent( EN_KILLFOCUS, Self, bLfocus,, "onLostFocus" )
      ENDIF
   ENDIF
   IF bChange != Nil
      ::oParent:AddEvent( EN_CHANGE, Self, bChange,, "onChange"  )
   ENDIF
   ::bColorOld := ::bcolor

   RETURN Self


METHOD Refresh()  CLASS HEdit
   LOCAL vari

   IF ::bSetGet != Nil
      vari := Eval( ::bSetGet,, Self )
      IF ! Empty( ::cPicFunc ) .OR. ! Empty( ::cPicMask )
         vari := Transform( vari, ::cPicFunc + IIf( Empty( ::cPicFunc ), "", " " ) + ::cPicMask )
      ELSE
         vari := IIf( ::cType == "D", DToC( vari ), IIf( ::cType == "N", Str( vari ), IIf( ::cType == "C" .and. ValType( vari ) == "C", Trim( vari ), "" ) ) )
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

   ::cPicture := cPicture
   ::cPicFunc := ::cPicMask := ""
   IF ::bSetGet == Nil
      RETURN Nil
   ENDIF

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
   IF Empty( SendMessage( ::handle, EM_GETPASSWORDCHAR, 0, 0 ) )
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
            cBuf := Left( ::title, nPosStart ) + IF( ::IsEditable( nPosStart + 2 ), SubStr( ::title, nPosStart + 2, 1 ) + "  " , "  " ) + SubStr( ::title, nPosEdit + 1 )
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

   IF ! Empty( ::cPicFunc )  .AND. !::cType == "N"
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
         cChar := Transform( cChar, cPic )
      ENDIF
   ENDIF

   RETURN cChar

METHOD GetApplyKey( cKey ) CLASS HEdit
   LOCAL nPos, nGetLen, nLen, vari, i, x, newPos
   LOCAL nDecimals, lSignal := .F.

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
         // vari := 0
         vari := StrTran( Trim( ::title )," ",IIF("E" $ ::cPicFunc, ",", "." ))
         vari := Val( vari )
      ELSE
         vari := Trim( ::title )
         lSignal := IIF( LEFT( vari, 1) = "-", .T., .F. )
         FOR i := 2 TO Len( vari )
            IF ! IsDigit( SubStr( vari, i, 1 ) )
               vari := Left( vari, i - 1 ) + SubStr( vari, i + 1 )
            ENDIF
         NEXT
         vari := StrTran( vari, " ", IIF( "E" $ ::cPicFunc, ",", "." ) )
         vari := Val( vari )
         lSignal := IIF( lSignal .AND. vari != 0, .F., lSignal )
      ENDIF
      IF ! Empty( ::cPicFunc ) .OR. ! Empty( ::cPicMask )
         ::title := Transform( vari, ::cPicFunc + IIf( Empty( ::cPicFunc ), "", " " ) + ::cPicMask )
         IF lSignal
           ::title := "-" + substr( ::title, 2 )
         ENDIF

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

            //IF ! Empty( ::cPicMask ) .AND. Len( ::cPicMask ) < Len( ::title )
            IF ( ! Empty( ::cPicFunc ) .OR. ! Empty( ::cPicMask ) ) .AND. ;
                  ( ! cKey $ ",." .OR. RIGHT( TRIM( ::title ), 1 ) = '.' )
               ::title := Left( ::title, nPos - 1 ) + cKey + SubStr( ::title, nPos + 1 )
            ENDIF
         ELSE
            ::title := Left( ::title, nPos - 1 ) + cKey + SubStr( ::title, nPos + 1 )
         ENDIF
         IF ! Empty( SendMessage( ::handle, EM_GETPASSWORDCHAR, 0, 0 ) )
            ::title := Left( ::title, nPos - 1 ) + cKey + Trim( SubStr( ::title, nPos + 1 ) )
            IF  !empty( ::nMaxLength ) .AND. LEN( TRIM( ::GetText() ) ) = ::nMaxLength
                  ::title := PadR( ::title, ::nMaxLength )
            ENDIF
            nLen := LEN( TRIM( ::GetText() ) )
         ELSEIF ! Empty( ::nMaxLength )
            nLen := LEN( TRIM( ::GetText() ) )
            ::title := PadR( ::title, ::nMaxLength )
         ELSEIF ! Empty( ::cPicMask ) .AND. !"@" $ ::cPicMask
            ::title := PadR( ::title, LEN( ::cPicMask ) )
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
         ELSEIF ! SET( _SET_CONFIRM )
             IF ( ::cType != "D" .AND. !"@"$::cPicFunc .and. EMPTY(::cPicMask) .AND. !Empty(::nMaxLength) .AND. nLen >= ::nMaxLength-1 ) .OR.;
                    ( !Empty(::nMaxLength) .AND. nPos = ::nMaxLength) .OR. nPos = Len( ::cPicMask )
                 GetSkip( ::oParent, ::handle, , 1 )
             ENDIF
         ENDIF
      ENDIF
   ENDIF
   ::lFirst := .F.

   RETURN 0

METHOD ReadOnly( lreadOnly )

   IF lreadOnly != Nil
      IF ! EMPTY( SENDMESSAGE( ::handle,  EM_SETREADONLY, IIF( lReadOnly, 1, 0 ), 0 ) )
          ::lReadOnly := lReadOnly
      ENDIF
   ENDIF
   RETURN ::lReadOnly

METHOD When() CLASS HEdit
   LOCAL res := .t., oParent, nSkip, vari

   IF ! CheckFocus( Self, .f. )
      RETURN .F.
   ENDIF
   ::lFirst := .T.
   nSkip := IIf( GetKeyState( VK_UP ) < 0 .or. ( GetKeyState( VK_TAB ) < 0 ;
                                                 .and. GetKeyState( VK_SHIFT ) < 0 ), - 1, 1 )
   IF ::bGetFocus != Nil
      ::lnoValid := .T.
      IF ::cType == "D"
         vari := CToD( vari )
      ELSEIF ::cType == "N"
         vari := Val( LTrim( ::title ) )
      ELSE
        vari := ::title
      ENDIF
      ::oParent:lSuspendMsgsHandling := .T.
        res := Eval( ::bGetFocus, vari, Self )
      res := IIf( ValType( res ) == "L", res, .T. )
      ::lnoValid := ! res
      IF ! res
         oParent := ParentGetDialog( Self )
         /*
         IF Self == ATail(oParent:GetList)
            nSkip := -1
         ELSEIF Self == oParent:getList[1]
            nSkip := 1
         ENDIF
         */
         GetSkip( ::oParent, ::handle, , nSkip )
      ENDIF
      ::oParent:lSuspendMsgsHandling := .F.
   ENDIF
   RETURN res

METHOD Valid( ) CLASS HEdit
   LOCAL res := .T., vari, oDlg

   IF ::bLostFocus != Nil .AND. ( ::lNoValid .OR. ! CheckFocus( Self, .T. ) )
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
         ELSEIF ::lMultiLine
              vari := ::GetText()
              ::title := vari
         ENDIF
         Eval( ::bSetGet, vari, Self )
         IF oDlg != Nil
            oDlg:nLastKey := 27
         ENDIF
         IF ::bLostFocus != Nil .OR. ::oUpDown != Nil
            ::oparent:lSuspendMsgsHandling := .T.
            IF ::bLostFocus != Nil
               res := Eval( ::bLostFocus, vari, Self )
               res := IIF( ValType( res ) == "L", res, .T. )
            ENDIF
            IF res .AND. ::oUpDown != Nil // updown control
               res := ::oUpDown:Valid()
            ENDIF
            IF ValType( res ) = "L" .AND. ! res
               IF oDlg != Nil
                  oDlg:nLastKey := 0
               ENDIF
               ::SetFocus()
               ::oparent:lSuspendMsgsHandling := .F.
               RETURN .F.
            ENDIF
            IF Empty( GetFocus() )
               GetSkip( ::oParent, ::handle,, ::nGetSkip )
            ENDIF
         ENDIF
         IF oDlg != Nil
            oDlg:nLastKey := 0
         ENDIF
      ENDIF
   ELSE
     IF ::lMultiLine
            ::title := ::GetText()
     ENDIF
       IF ::bLostFocus != Nil .OR. ::oUpDown != Nil
        ::oparent:lSuspendMsgsHandling := .T.
        IF ::bLostFocus != Nil
             res := Eval( ::bLostFocus, vari, Self )
           res := IIF( ValType(res) == "L", res, .T. )
        ENDIF
        IF res .AND. ::oUpDown != Nil // updown control
           res := ::oUpDown:Valid()
        ENDIF
        IF ! res
           ::SetFocus()
           ::oparent:lSuspendMsgsHandling := .F.
           RETURN .F.
        ENDIF
        IF Empty( GetFocus() )
           GetSkip( ::oParent, ::handle,, ::nGetSkip )
        ENDIF
     ENDIF
   ENDIF
   ::oparent:lSuspendMsgsHandling := .F.
   RETURN .T.

METHOD onChange( ) CLASS HEdit
   LOCAL  nPos := HIWORD( SendMessage( ::handle, EM_GETSEL, 0, 0 ) ) + 1

    /*
   IF ! CheckFocus( Self, .T. )
      RETURN .t.
   ENDIF
    */
    ::title := ::GetText()
   IF ::lMultiLine
      IF ::bSetGet != Nil
      //   Eval( ::bSetGet,, Self )
     ENDIF
   ENDIF
   IF ::bChange != Nil
      ::oparent:lSuspendMsgsHandling := .T.
      Eval( ::bChange, ::title, Self, nPos )
      ::oparent:lSuspendMsgsHandling := .F.
    ENDIF
   //SendMessage( ::handle,  EM_SETSEL, 0, nPos )

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

/*
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
*/

FUNCTION CreateGetList( oDlg, oCnt )
   LOCAL i,oCtrl, aLen1

   IF oCnt = Nil
     aLen1 := Len( oDlg:aControls )
     oCtrl := oDlg
   ELSE
     aLen1 := Len( oCnt:aControls )
     oCtrl := oCnt
   ENDIF
   FOR i := 1 TO aLen1
      IF LEN( oCtrl:aControls[ i ]:aControls ) > 0
         CreateGetList( oDlg, oCtrl:aControls[ i ] )
      ENDIF
      IF __ObjHasMsg( oCtrl:aControls[ i ], "BSETGET" ) .AND. oCtrl:aControls[ i ]:bSetGet != Nil
         AAdd( oDlg:GetList, oCtrl:aControls[ i ] )
      ENDIF
   NEXT
   RETURN oCtrl

FUNCTION GetSkip( oParent, hCtrl, lClipper, nSkip )
   LOCAL i, nextHandle, oCtrl
   LOCAL oForm := IIF( ( oForm := oParent:GetParentForm() ) = Nil, oParent, oForm )

   DEFAULT nSkip := 1
   IF oParent == Nil .OR. ( lClipper != Nil .AND. lClipper .AND. ! oParent:lClipper )
      RETURN .F.
   ENDIF
   i := AScan( oParent:acontrols, { | o | o:handle == hCtrl } )
   oCtrl := IIf( i > 0, oParent:acontrols[ i ], oParent )

   nextHandle := IIF( oParent:className == "HTAB", NextFocusTab( oParent, hCtrl, nSkip), ;
                 IIF( oParent:className == oForm:ClassName, NextFocus( oParent, hCtrl, nSkip ),;
                      NextFocuscontainer( oParent, hCtrl, nSkip ) ) )

   //nextHandle := IIf( oParent:className == "HTAB", NextFocusTab( oParent, hCtrl, nSkip ), ;
   //                   NextFocus( oParent, hCtrl, nSkip ) )

   IF i > 0
      oCtrl:nGetSkip := nSkip
   ENDIF
   IF ! Empty( nextHandle )
       i := AScan( oparent:acontrols, { | o | o:handle == nextHandle } )
      oCtrl := IIF( i > 0, oparent:acontrols[i], oParent)
       IF oForm:classname == oParent:classname //!= "HTAB"
         IF oParent:Type < WND_DLG_RESOURCE
                SetFocus( nextHandle )
         ELSE
             PostMessage( oParent:handle, WM_NEXTDLGCTL, nextHandle , 1 )
         ENDIF
      ELSE
          IF oForm:Type < WND_DLG_RESOURCE  //oParent:oParent:Type < WND_DLG_RESOURCE
             SetFocus( nextHandle )
         ELSEIF oParent:handle = getFocus()
            PostMessage( GetActiveWindow(), WM_NEXTDLGCTL, nextHandle , 1 )
         ELSE
                PostMessage( oParent:handle, WM_NEXTDLGCTL, nextHandle , 1 )
         ENDIF
      ENDIF
   ENDIF
   IF hCtrl == nextHandle
       SendMessage( nexthandle, WM_KILLFOCUS, 0,  0)
    ENDIF
   RETURN .T.

STATIC FUNCTION NextFocusTab( oParent, hCtrl, nSkip )
   LOCAL nextHandle := 0, i, nPage, nFirst , nLast , k := 0

   IF Len( oParent:aPages ) > 0
      oParent:SetFocus()
      nPage := oParent:GetActivePage( @nFirst, @nLast )
      IF ! oParent:lResourceTab  && TAB without RC
         i :=  AScan( oParent:acontrols, { | o | o:handle == hCtrl } )
         i += IIf( i == 0, nFirst, nSkip ) //nLast, nSkip)
         IF i >= nFirst .and. i <= nLast
            nextHandle := GetNextDlgTabItem ( oParent:handle , hCtrl, ( nSkip < 0 ) )
            IF  i != AScan( oParent:aControls, { | o | o:handle == nextHandle } ) .AND. oParent:aControls[ i ]:CLASSNAME = "HRADIOB"
               nextHandle := GetNextDlgGroupItem( oParent:handle , hCtrl, ( nSkip < 0 ) )
            ENDIF
            k := AScan( oParent:acontrols, { | o | o:Handle == nextHandle } )
            IF LEN( oParent:aControls[ k ]:aControls ) > 0 .AND. hCtrl != nextHandle .AND. oParent:aControls[ k ]:classname != "HTAB"
               nextHandle := NextFocusContainer( oParent:aControls[ k ], oParent:aControls[ k ]:Handle, nSkip )
               RETURN IIF( nextHandle > 0, nextHandle, NextFocusTab( oParent, oParent:aControls[ k ]:Handle, nSkip ) )
            ENDIF
         ENDIF
      ELSE
         SETFOCUS( oParent:aPages[ nPage, 1 ]:aControls[ 1 ]:Handle )
         RETURN 0
      ENDIF
      IF ( nSkip < 0 .AND. ( k > i .OR. k == 0 ) ) .OR. ( nSkip > 0 .AND. i > k )
         IF oParent:oParent:classname = "HTAB" .AND. oParent:oParent:classname != oParent:classname
                  NextFocusTab( oParent:oParent, nextHandle, nSkip )
         ENDIF
         IF TYPE( "oParent:oParent:Type" ) = "N" .AND. oParent:oParent:Type < WND_DLG_RESOURCE
             nextHandle := GetNextDlgTabItem ( oParent:oParent:handle , hctrl, ( nSkip < 0 ) )
         ELSE
             nextHandle := GetNextDlgTabItem ( GetActiveWindow(), hCtrl, ( nSkip < 0 ) )
         ENDIF
         IF AScan( oParent:oParent:acontrols, { | o | o:handle == hCtrl } ) = 0
             RETURN IIF( nSkip > 0, NextFocus( oParent:oParent, oParent:Handle, nSkip ), oParent:Handle )
             /*
             nexthandle :=  oParent:handle
             i := AScan( oParent:oparent:acontrols, { | o | o:handle == oParent:handle } ) + nSkip
             IF i > 0 .AND. i <= LEN( oParent:oParent:acontrols )
                 i := ASCAN( oParent:oParent:acontrols, {|o| Hwg_BitaND( HWG_GETWINDOWSTYLE( o:handle ), WS_TABSTOP ) != 0 }, i)
                 nexthandle := oParent:oParent:acontrols[ IIF( i = 0, ASCAN( oParent:oParent:acontrols,;
                          {|o| Hwg_BitaND( HWG_GETWINDOWSTYLE( o:handle ), WS_TABSTOP ) != 0 }, i), i ) ]:handle
                  ENDIF
                  */
         ELSE
            PostMessage( GetActiveWindow(), WM_NEXTDLGCTL, nextHandle , 1 )
         ENDIF
         IF nexthandle > 0 .AND. Hwg_BitaND( HWG_GETWINDOWSTYLE( nextHandle ), WS_TABSTOP ) = 0
            NextFocusTab( oParent, nextHandle, nSkip )
         ENDIF
      ENDIF
   ENDIF
   RETURN nextHandle

STATIC FUNCTION NextFocus( oParent, hCtrl, nSkip )
   Local nextHandle := 0,  i, nWindow
   Local lGroup := Hwg_BitAND( HWG_GETWINDOWSTYLE(  hctrl ), WS_GROUP ) != 0
   Local lHradio := .F.
   Local lnoTabStop := .T.

   oParent := IIF( oParent:Type = Nil, oParent:GetParentForm(), oParent )
   nWindow := IIF( oParent:Type < WND_DLG_RESOURCE, oParent:Handle, GetActiveWindow() )

   i := AScan( oparent:acontrols, { | o | o:Handle == hCtrl } )
   IF i > 0 .and. Len( oParent:acontrols[ i ]:aControls ) > 0 .AND.;
      oParent:aControls[ i ]:className != "HTAB" .AND. ( hCtrl != nextHandle )
      nextHandle := NextFocusContainer( oParent:aControls[ i ], hCtrl , nSkip )
      IF nextHandle > 0
         RETURN nextHandle
      ENDIF
   ENDIF
    lHradio :=  i > 0 .AND. oParent:acontrols[ i ]:CLASSNAME = "HRADIOB"
      // TABs DO resource
   IF oParent:Type = WND_DLG_RESOURCE
      nextHandle := GetNextDlgGroupItem( oParent:handle , hctrl,( nSkip < 0 ) )
   ELSE
      IF  lHradio .OR.  lGroup
         nexthandle := GetNextDlgGroupItem( nWindow , hctrl,( nSkip < 0 ) )
         i := AScan( oParent:aControls, { | o | o:Handle == nextHandle } )
         lnoTabStop := !( i > 0 .AND. oParent:aControls[ i ]:CLASSNAME = "HRADIOB")
      ENDIF
      IF ( lGroup .AND. nSkip < 0 ) .OR. lnoTabStop
         nextHandle := GetNextDlgTabItem ( nWindow , hCtrl, ( nSkip < 0 ) )
         lnoTabStop :=  Hwg_BitaND( HWG_GETWINDOWSTYLE( nexthandle ), WS_TABSTOP ) = 0
      ELSE
         lnoTabStop := .F.
       ENDIF
         i := AScan( oParent:aControls, { | o | o:Handle == nextHandle } )
      IF ( lnoTabStop .AND. i > 0 ) .OR. ( i > 0 .AND. i <= LEN( oParent:aControls ).AND. oparent:acontrols[ i ]:classname = "HGROUP") .OR.;
         ( i = 0 .AND. nextHandle > 0 )
          RETURN NextFocus( oParent, nextHandle, nSkip )
      ENDIF
      /*
          nextHandle := GetNextDlgTabItem ( nWindow , nextHandle, ( nSkip < 0 ) )
              i := AScan( oparent:aControls, { | o | o:Handle == nextHandle } )
      ENDIF
      IF i > 0 .AND. LEN( oParent:aControls[ i ]:aControls ) > 0 .AND. nSkip > 0 .AND. ;
        oParent:aControls[ i ]:className != "HTAB"
        RETURN NextFocus( oParent, nextHandle, nSkip )
      ENDIF
      */
   ENDIF
   RETURN nextHandle

STATIC FUNCTION NextFocusContainer(oParent,hCtrl,nSkip)
   Local nextHandle := 0,  i, i2, nWindow
   Local lGroup := Hwg_BitAND( HWG_GETWINDOWSTYLE(  hctrl ), WS_GROUP ) != 0
   Local lHradio := .F.
   Local lnoTabStop := .f.

   AEVAL(oparent:acontrols,{|o| IIF(Hwg_BitAND( HWG_GETWINDOWSTYLE(  o:handle ), WS_TABSTOP ) != 0, lnoTabStop := .T., .T. ) } )
   IF !lnoTabStop .OR. hCtrl= 0
      RETURN 0 //nexthandle
   ENDIF
   nWindow := oParent:handle
   i := AScan( oparent:acontrols, { | o | o:handle == hCtrl } )
    lHradio :=  i > 0 .AND. oParent:acontrols[ i ]:CLASSNAME = "HRADIOB"
      // TABs DO resource
   IF oParent:Type = WND_DLG_RESOURCE
      nexthandle := GetNextDlgGroupItem( oParent:handle , hctrl,( nSkip < 0 ) )
   ELSE
      IF  lHradio .OR.  lGroup
         nextHandle := GetNextDlgGroupItem( nWindow , hCtrl,( nSkip < 0 ) )
         i := AScan( oParent:aControls, { | o | o:Handle == nextHandle } )
         lnoTabStop := !( i > 0 .AND. oParent:aControls[ i ]:CLASSNAME = "HRADIOB")  //Hwg_BitAND( HWG_GETWINDOWSTYLE( nexthandle ), WS_TABSTOP ) = 0
      ENDIF
      IF ( lGroup .AND. nSkip < 0 ) .OR. lnoTabStop
         nextHandle := GetNextDlgTabItem ( nWindow , hctrl, ( nSkip < 0 ) )
         lnoTabStop :=  Hwg_BitaND( HWG_GETWINDOWSTYLE( nextHandle ), WS_TABSTOP ) = 0
      ELSE
        lnoTabStop := .F.
       ENDIF
         i2 := AScan( oParent:aControls, { | o | o:Handle == nextHandle } )
        IF ( ( i2 < i .AND. nSkip > 0 ) .OR. ( i2 > i .AND. nSkip < 0 )) .OR. hCtrl = nextHandle
          RETURN IIF( oParent:oParent:className == "HTAB", NextFocusTab(oParent:oParent, nWindow, nSkip ), ;
                       NextFocus( oParent:oparent, hCtrl, nSkip ) )
      ENDIF
      i := i2
      IF i = 0
         nextHandle := oParent:aControls[ Len( oParent:aControls ) ]:Handle
      ELSEIF lnoTabStop .OR. ( i > 0 .AND. i <= LEN( oParent:acontrols ).AND. oParent:aControls[i]:classname = "HGROUP") .OR. i = 0
         nextHandle := GetNextDlgTabItem ( nWindow , nextHandle, ( nSkip < 0 ) )
      ENDIF
   ENDIF
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

FUNCTION SetColorinFocus( lDef, tcolor, bcolor, lFixed )

   IF ValType( lDef ) <> "L"
      lDef := ( ValType( lDef ) = "C" .AND. Upper( lDef ) = "ON" )
   ENDIF
   lColorinFocus := lDef
   IF ! lDef
      RETURN .F.
   ENDIF
   lFixedColor   := IIf( lFixed != Nil, ! lFixed, lFixedColor )
   tcolorselect  := IIf( tcolor != Nil, tcolor, tcolorselect )
   bcolorselect  := IIf( bcolor != Nil, bcolor, bcolorselect )

   RETURN .T.

/*
Luis Fernando Basso contribution
*/

/** CheckFocus
* check focus of controls before calling events
*/
FUNCTION CheckFocus( oCtrl, nInside )
   LOCAL oParent := ParentGetDialog( oCtrl )

   IF ( oParent  != Nil .AND. ! IsWindowVisible( oParent:handle ) ) .OR. Empty( GetActiveWindow() ) // == 0
      IF ! nInside .and. Empty( oParent:nInitFocus ) // = 0
         oParent:Show()
         SetFocus( oParent:handle )
         SetFocus( GetFocus() )
      ENDIF
      RETURN .F.
   ENDIF
   IF oParent  != Nil .AND. nInside
      IF GETFOCUS() = oCtrl:oParent:Handle .AND. oParent:handle = oCtrl:oParent:Handle
         RETURN .F.
      ENDIF
   ENDIF
   RETURN .T.

