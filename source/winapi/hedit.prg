
/*
 *$Id$
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
STATIC bColorSelect  := 13434879
STATIC lPersistColorSelect := .F.
STATIC bDisablecolor :=  Nil

#include "windows.ch"
#include "hbclass.ch"
#include "hblang.ch"
#include "guilib.ch"
#ifdef __XHARBOUR__
   #xtranslate hb_RAScan([<x,...>])        => RAScan(<x>)
#endif

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
   DATA lFocu          INIT .F.
   DATA lReadOnly      INIT .F.
   DATA lNoPaste       INIT .F.
   DATA oUpDown
   DATA lCopy  INIT .F.  HIDDEN
   DATA nSelStart  INIT 0  HIDDEN
   DATA cSelText   INIT "" HIDDEN
   DATA nSelLength INIT 0 HIDDEN

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, tcolor, bcolor, cPicture, ;
      lNoBorder, nMaxLength, lPassword, bKeyDown, bChange, bOther )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Redefine( oWndParent, nId, vari, bSetGet, oFont, bInit, bSize, bPaint, ;
      bGfocus, bLfocus, ctooltip, tcolor, bcolor, cPicture, nMaxLength, lMultiLine, bKeyDown, bChange )
   METHOD Init()
   METHOD SetGet( value ) INLINE Eval( ::bSetGet, value, Self )
   METHOD Refresh()
   METHOD SetText( c )
   METHOD ParsePict( cPicture, vari )

   METHOD VarPut( value ) INLINE ::SetGet( value )
   METHOD VarGet() INLINE ::SetGet()

   METHOD IsEditable( nPos, lDel ) PROTECTED
   METHOD KeyRight( nPos ) PROTECTED
   METHOD KeyLeft( nPos ) PROTECTED
   METHOD DeleteChar( lBack ) PROTECTED
   METHOD INPUT( cChar, nPos ) PROTECTED
   METHOD GetApplyKey( cKey ) PROTECTED
   METHOD Valid() //PROTECTED BECAUSE IS CALL IN HDIALOG
   METHOD When() //PROTECTED
   METHOD onChange( lForce ) //PROTECTED
   METHOD IsBadDate( cBuffer ) PROTECTED
   METHOD Untransform( cBuffer ) PROTECTED
   METHOD FirstEditable() PROTECTED
   METHOD FirstNotEditable( nPos ) PROTECTED
   METHOD LastEditable() PROTECTED
   METHOD SetGetUpdated() PROTECTED
   METHOD ReadOnly( lreadOnly ) SETGET
   METHOD SelLength( Length ) SETGET
   METHOD SelStart( Start ) SETGET
   METHOD SelText( cText ) SETGET
   METHOD Value ( Value ) SETGET
   METHOD SetCueBanner ( cText, lshowFoco )

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, tcolor, bcolor, ;
      cPicture, lNoBorder, nMaxLength, lPassword, bKeyDown, bChange, bOther ) CLASS HEdit

   nStyle := Hwg_BitOr( iif( nStyle == Nil, 0, nStyle ), ;
      WS_TABSTOP + iif( lNoBorder == Nil .OR. ! lNoBorder, WS_BORDER, 0 ) + ;
      iif( lPassword == Nil .OR. ! lPassword, 0, ES_PASSWORD )  )

   bcolor := iif( bcolor == Nil .AND. Hwg_BitAnd( nStyle, WS_DISABLED ) = 0, hwg_Getsyscolor( COLOR_BTNHIGHLIGHT ), bcolor )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor  )

   IF vari != Nil
      ::cType   := ValType( vari )
   ENDIF
   ::SetText( vari )

   ::lReadOnly := Hwg_BitAnd( nStyle, ES_READONLY ) != 0
   ::bSetGet := bSetGet
   ::bKeyDown := bKeyDown
   ::bChange := bChange
   ::bOther := bOther
   IF Hwg_BitAnd( nStyle, ES_MULTILINE ) != 0
      ::lMultiLine := .T.
      ::lWantReturn := Hwg_BitAnd( nStyle, ES_WANTRETURN ) != 0
   ENDIF
   IF ( nMaxLength != Nil .AND. ! Empty( nMaxLength ) ) //.AND. (  Empty( cPicture ) .or. cPicture == Nil)
      ::nMaxLength := nMaxLength
   ENDIF
   IF ::cType == "N" .AND. Hwg_BitAnd( nStyle, ES_LEFT + ES_CENTER ) == 0
      ::style := Hwg_BitOr( ::style, ES_RIGHT + ES_NUMBER )
      cPicture := iif( cPicture == Nil .AND. ::nMaxLength != Nil, Replicate( "9", ::nMaxLength ), cPicture )
   ENDIF
   IF ::cType == "D" .AND. bSetGet != Nil
      ::nMaxLength := Len( Dtoc( vari ) ) //IIF( SET( _SET_CENTURY ), 10, 8 )
   ENDIF

   ::ParsePict( cPicture, vari )

   ::Activate()

   ::DisableBackColor := bDisablecolor
   // defines the number of characters based on the size of control
   IF  Empty( ::nMaxLength ) .AND. ::cType = "C" .AND. Empty( cPicture ) .AND. Hwg_BitAnd( nStyle, ES_AUTOHSCROLL ) = 0
      nWidth :=  ( hwg_TxtRect( " ", Self ) )[ 1 ]
      ::nMaxLength := Int( ( ::nWidth - nWidth ) / nWidth ) - 1
      ::nMaxLength := iif( ::nMaxLength < 10, 10, ::nMaxLength )
   ENDIF

   IF ::bSetGet != Nil
      ::bGetFocus := bGfocus
      ::bLostFocus := bLfocus
      ::lnoValid := iif( bGfocus != Nil, .T. , .F. )
      ::oParent:AddEvent( EN_SETFOCUS,  Self, { | | ::When( ) }, , "onGotFocus"  )
      ::oParent:AddEvent( EN_KILLFOCUS, Self, { | | ::Valid( ) }, , "onLostFocus" )
      ::bValid := { | | ::Valid( ) }
   ELSE
      IF bGfocus != Nil
         ::oParent:AddEvent( EN_SETFOCUS, Self, { | | ::When( ) }, , "onGotFocus"  )
      ENDIF
      ::oParent:AddEvent( EN_KILLFOCUS, Self, { | | ::Valid( ) }, , "onLostFocus" )
      ::bValid := { | | ::Valid( ) }
   ENDIF

   ::bColorOld := ::bcolor
   ::tColorOld := iif( tcolor = Nil, 0, ::tcolor )

   IF ::cType != "D"
      SET( _SET_INSERT, ! ::lPicComplex )
   ENDIF

   RETURN Self

METHOD Activate() CLASS HEdit

   IF ! Empty( ::oParent:handle )
      ::handle := hwg_Createedit( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF

   RETURN Nil

METHOD Init()  CLASS HEdit

   IF ! ::lInit
      ::Super:Init()
      ::nHolder := 1
      hwg_Setwindowobject( ::handle, Self )
      Hwg_InitEditProc( ::handle )
      ::Refresh()
      ::oParent:AddEvent( EN_CHANGE, Self, { | | ::onChange( ) }, , "onChange"  )
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HEdit
   LOCAL oParent := ::oParent, nPos
   LOCAL nextHandle, nShiftAltCtrl, lRes
   LOCAL cClipboardText

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
            hwg_Copystringtoclipboard( ::UnTransform( hwg_Getclipboardtext() ) )
            RETURN - 1
         ELSEIF msg = WM_PASTE .AND. ! ::lNoPaste
            ::lFirst := iif( ::cType = "N" .AND. "E" $ ::cPicFunc, .T. , .F. )
            cClipboardText :=  hwg_Getclipboardtext()
            IF ! Empty( cClipboardText )
               nPos := hwg_Hiword( hwg_Sendmessage( ::handle, EM_GETSEL, 0, 0 ) ) + 1
               hwg_Sendmessage(  ::handle, EM_SETSEL, nPos - 1 , nPos - 1  )
               FOR nPos = 1 TO Len( cClipboardText )
                  ::GetApplyKey( SubStr( cClipboardText , nPos, 1 ) )
               NEXT
               nPos := hwg_Hiword( hwg_Sendmessage( ::handle, EM_GETSEL, 0, 0 ) ) + 1
               ::title := ::UnTransform( hwg_Getedittext( ::oParent:handle, ::id ) )
               hwg_Sendmessage(  ::handle, EM_SETSEL, nPos - 1 , nPos - 1 )
            ENDIF
            RETURN 0
         ELSEIF msg == WM_CHAR
            IF ! hwg_Checkbit( lParam, 32 ) .AND. ::bKeyDown != Nil .AND. ValType( ::bKeyDown ) == 'B'
               nShiftAltCtrl := iif( hwg_IsCtrlShift( .F. , .T. ), 1 , 0 )
               nShiftAltCtrl += iif( hwg_IsCtrlShift( .T. , .F. ), 2 ,  nShiftAltCtrl )
               nShiftAltCtrl += iif( hwg_Checkbit( lParam, 28 ), 4, nShiftAltCtrl )
               ::oparent:lSuspendMsgsHandling := .T.
               lRes := Eval( ::bKeyDown, Self, wParam, nShiftAltCtrl  )
               ::oparent:lSuspendMsgsHandling := .F.
               IF Empty( lRes )
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
               IF ! hwg_ProcOkCancel( Self, wParam, hwg_GetParentForm( Self ):Type >= WND_DLG_RESOURCE ) .AND. ;
                     ( hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE .OR. ;
                     ! hwg_GetParentForm( Self ):lModal )
                  hwg_GetSkip( oParent, ::handle, , 1 )
                  RETURN 0
               ELSEIF  hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE
                  RETURN 0
               ENDIF
               RETURN - 1
            ELSEIF wParam == VK_TAB
               IF ( hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE .OR. ;
                     ! hwg_GetParentForm( Self ):lModal )
                  //- hwg_GetSkip( oParent, ::handle, , iif( hwg_IsCtrlShift(.f., .t.), -1, 1) )
               ENDIF
               RETURN 0
            ELSEIF wParam == VK_ESCAPE
               oParent := hwg_GetParentForm( Self )
               IF oParent:Handle == ::oParent:Handle .AND. oParent:lExitOnEsc .AND. ;
                     oParent:FindControl( IDCANCEL ) != Nil .AND. ;
                     ! oParent:FindControl( IDCANCEL ):IsEnabled()
                  hwg_Sendmessage( oParent:handle, WM_COMMAND, hwg_Makewparam( IDCANCEL, 0 ), ::handle )
               ENDIF
               IF ( oParent:Type < WND_DLG_RESOURCE .OR. ! oParent:lModal )
                  hwg_Setfocus( 0 )
                  hwg_ProcOkCancel( Self, VK_ESCAPE )
                  RETURN 0
               ENDIF
               RETURN 0
            ENDIF
            //
            IF ::lFocu
               IF ::cType = "N" .AND. Set( _SET_INSERT )
                  ::lFirst := .T.
               ENDIF
               IF ! lFixedColor
                  ::Setcolor( ::tcolorOld, ::bColorOld )
                  ::bColor := ::bColorOld
                  ::brush := iif( ::bColorOld = Nil, Nil, ::brush )
                  hwg_Sendmessage( ::handle, WM_MOUSEMOVE, 0, hwg_Makelparam( 1, 1 ) )
               ENDIF
               ::lFocu := .F.
            ENDIF
            //
            IF ! hwg_IsCtrlShift( , .F. )
               RETURN ::GetApplyKey( Chr( wParam ) )
            ENDIF

         ELSEIF msg == WM_KEYDOWN
            IF ( ( hwg_Checkbit( lParam, 25 ) .AND. wParam != 111 ) .OR.  ( wParam > 111 .AND. wParam < 124 ) ) .AND. ;
                  ::bKeyDown != Nil .AND. ValType( ::bKeyDown ) == 'B'
               nShiftAltCtrl := iif( hwg_IsCtrlShift( .F. , .T. ), 1 , 0 )
               nShiftAltCtrl += iif( hwg_IsCtrlShift( .T. , .F. ), 2 ,  nShiftAltCtrl )
               nShiftAltCtrl += iif( wParam > 111, 4, nShiftAltCtrl )
               ::oparent:lSuspendMsgsHandling := .T.
               lRes := Eval( ::bKeyDown, Self, wParam, nShiftAltCtrl  )
               ::oparent:lSuspendMsgsHandling := .F.
               IF Empty( lRes )
                  RETURN 0
               ENDIF
            ENDIF
            IF wParam == 40 .AND. ::oUpDown != Nil // KeyDown
               RETURN - 1
            ELSEIF wParam == 40 //.OR. ( wParam == 399 .AND. ::oUpDown != Nil )   // KeyDown
               IF ! hwg_IsCtrlShift()
                  hwg_GetSkip( oParent, ::handle, , 1 )
                  RETURN 0
               ENDIF
            ELSEIF wParam == 38 .AND. ::oUpDown != Nil   // KeyUp
               RETURN - 1
            ELSEIF wParam == 38 //.OR.( wParam == 377 .AND. ::oUpDown != Nil )   // KeyUp
               IF ! hwg_IsCtrlShift()
                  hwg_GetSkip( oParent, ::handle, , - 1 )
                  RETURN 0
               ENDIF
            ELSEIF wParam == 39     // KeyRight
               ::lFocu := .F.
               IF ! hwg_IsCtrlShift()
                  ::lFirst := .F.
                  RETURN ::KeyRight()
               ENDIF
            ELSEIF wParam == 37     // KeyLeft
               ::lFocu := .F.
               IF ! hwg_IsCtrlShift()
                  ::lFirst := .F.
                  RETURN ::KeyLeft()
               ENDIF
            ELSEIF wParam == 35     // End
               ::lFocu := .F.
               IF ! hwg_IsCtrlShift()
                  ::lFirst := .F.
                  IF ::cType == "C"
                     //nPos := Len( Trim( ::title ) )
                     nPos := Len( Trim( hwg_Getedittext( ::oParent:handle, ::id ) ) )
                     hwg_Sendmessage( ::handle, EM_SETSEL, nPos, nPos )
                     RETURN 0
                  ENDIF
               ENDIF
            ELSEIF wParam == 36     // HOME
               ::lFocu := .F.
               IF ! hwg_IsCtrlShift()
                  hwg_Sendmessage( ::handle, EM_SETSEL, ::FirstEditable() - 1, ::FirstEditable() - 1 )
                  RETURN 0
               ENDIF
            ELSEIF wParam == 45     // Insert
               IF ! hwg_IsCtrlShift()
                  SET( _SET_INSERT, ! Set( _SET_INSERT ) )
               ENDIF
            ELSEIF wParam == 46     // Del
               ::lFirst := .F.
               ::SetGetUpdated()
               ::DeleteChar( .F. )
               RETURN 0
            ELSEIF wParam == VK_TAB     // Tab
               hwg_GetSkip( oParent, ::handle, , ;
                  iif( hwg_IsCtrlShift( .F. , .T. ), - 1, 1 ) )
               RETURN 0
            ELSEIF wParam == VK_RETURN  // Enter
               //hwg_GetSkip( oParent, ::handle, .T., 1 )
               RETURN 0
            ENDIF
            IF "K" $ ::cPicFunc .AND. ::lFocu  .AND. ! Empty( ::Title )
               ::Title := iif( ::cType == "D", CToD( "" ), iif( ::cType == "N", 0, "" ) )
            ENDIF

         ELSEIF msg == WM_LBUTTONDOWN
            IF hwg_Getfocus() != ::handle
               //hwg_Setfocus( ::handle )
               //RETURN 0
            ENDIF

         ELSEIF msg == WM_LBUTTONUP
            IF Empty( hwg_Getedittext( oParent:handle, ::id ) )
               hwg_Sendmessage( ::handle, EM_SETSEL, 0, 0 )
            ENDIF

         ENDIF
      ELSE
         // no bsetget
         IF msg == WM_CHAR
            IF wParam == VK_TAB .OR. wParam == VK_ESCAPE .OR. wParam == VK_RETURN
               RETURN 0
            ENDIF
            RETURN - 1
         ELSEIF msg == WM_KEYDOWN
            IF wParam == VK_TAB .AND. hwg_GetParentForm( Self ):Type >= WND_DLG_RESOURCE    // Tab
               nexthandle := hwg_Getnextdlgtabitem ( hwg_Getactivewindow(), hwg_Getfocus(), ;
                  hwg_IsCtrlShift( .F. , .T. ) )
               hwg_Postmessage( hwg_Getactivewindow(), WM_NEXTDLGCTL, nextHandle, 1 )
               RETURN 0
            ELSEIF  ( wParam == VK_RETURN .OR. wParam == VK_ESCAPE ) .AND. hwg_ProcOkCancel( Self, wParam, hwg_GetParentForm( Self ):Type >= WND_DLG_RESOURCE )
               RETURN - 1
            ELSEIF ( wParam == VK_RETURN .OR. wParam == VK_TAB ) .AND. hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE
               hwg_GetSkip( oParent, ::handle, , 1 )

               RETURN 0
            ENDIF
         ENDIF
      ENDIF
      IF lColorinFocus
         IF msg == WM_SETFOCUS
            ::nSelStart := iif( Empty( ::title ), 0, ::nSelStart )
            ::Setcolor( tColorSelect, bColorSelect )
            hwg_Sendmessage( ::handle, EM_SETSEL, ::selStart, ::selStart ) // era -1
         ELSEIF msg == WM_KILLFOCUS .AND. ! lPersistColorSelect
            ::Setcolor( ::tcolorOld, ::bColorOld, .T. )
            ::bColor := ::bColorOld
            ::brush := iif( ::bColorOld = Nil, Nil, ::brush )
            hwg_Sendmessage( ::handle, WM_MOUSEMOVE, 0, hwg_Makelparam( 1, 1 ) )
         ENDIF
      ENDIF
      IF msg == WM_SETFOCUS
         ::lFocu := .T.
         ::lnoValid := .F.
         IF "K" $ ::cPicFunc
            hwg_Sendmessage( ::handle, EM_SETSEL, 0, - 1 )
         ELSEIF ::selstart = 0 .AND. "R" $ ::cPicFunc
            hwg_Sendmessage( ::handle, EM_SETSEL, ::FirstEditable() - 1, ::FirstEditable() - 1 )
         ENDIF
         IF ::lPicComplex .AND. ::cType <> "N" .AND. ! ::lFirst
            ::Title := Transform( ::Title, ::cPicFunc + " " + ::cPicMask )
         ENDIF
      ENDIF
   ELSE
      // multiline
      IF msg = WM_SETFOCUS
         hwg_Postmessage( ::handle, EM_SETSEL, 0, 0 )
      ELSEIF msg == WM_MOUSEWHEEL
         nPos := hwg_Hiword( wParam )
         nPos := iif( nPos > 32768, nPos - 65535, nPos )
         hwg_Sendmessage( ::handle, EM_SCROLL, iif( nPos > 0, SB_LINEUP, SB_LINEDOWN ), 0 )
      ELSEIF msg == WM_CHAR
         IF wParam == VK_TAB
            hwg_GetSkip( oParent, ::handle, , ;
               iif( hwg_IsCtrlShift( .F. , .T. ), - 1, 1 ) )
            RETURN 0
         ELSEIF wParam == VK_ESCAPE
            RETURN 0
         ELSEIF wParam == VK_RETURN .AND. ! ::lWantReturn .AND. ::bSetGet != Nil
            hwg_GetSkip( oParent, ::handle, , 1 )
            RETURN 0
         ENDIF
      ELSEIF msg == WM_KEYDOWN
         IF wParam == VK_TAB     // Tab
         ELSEIF wParam == VK_ESCAPE
            RETURN - 1
         ENDIF
         IF ::bKeyDown != Nil .AND. ValType( ::bKeyDown ) == 'B'
            IF !Eval( ::bKeyDown, Self, wParam )
               RETURN 0
            ENDIF
         ENDIF
      ENDIF
      // END multiline
   ENDIF

   IF ( msg == WM_KEYUP .OR. msg == WM_SYSKEYUP ) .AND. wParam != VK_ESCAPE     /* BETTER FOR DESIGNER */
      IF ! hwg_ProcKeyList( Self, wParam )
         IF ::bKeyUp != Nil
            IF !Eval( ::bKeyUp, Self, wParam )
               RETURN - 1
            ENDIF
         ENDIF
      ENDIF
      IF msg != WM_SYSKEYUP
         RETURN 0
      ENDIF

   ELSEIF msg == WM_GETDLGCODE
      IF wParam = VK_ESCAPE   .AND. ;          // DIALOG MODAL
            ( oParent := hwg_GetParentForm( Self ):FindControl( IDCANCEL ) ) != Nil .AND. ! oParent:IsEnabled()
         RETURN DLGC_WANTMESSAGE
      ENDIF
      IF ! ::lMultiLine .OR. wParam = VK_ESCAPE
         IF ::bSetGet != Nil
            RETURN DLGC_WANTARROWS + DLGC_WANTTAB + DLGC_WANTCHARS
         ENDIF
      ENDIF
   ELSEIF msg == WM_DESTROY
      ::END()
   ENDIF

   RETURN - 1

METHOD Redefine( oWndParent, nId, vari, bSetGet, oFont, bInit, bSize, bPaint, ;
      bGfocus, bLfocus, ctooltip, tcolor, bcolor, cPicture, nMaxLength, lMultiLine, bKeyDown, bChange )  CLASS HEdit

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, iif( bcolor == Nil, hwg_Getsyscolor( COLOR_BTNHIGHLIGHT ), bcolor ) )
   ::bKeyDown := bKeyDown
   IF ValType( lMultiLine ) == "L"
      ::lMultiLine := lMultiLine
   ENDIF

   IF vari != Nil
      ::cType   := ValType( vari )
   ENDIF
   ::bSetGet := bSetGet

   IF ! Empty( cPicture ) .OR. cPicture == Nil .AND. nMaxLength != Nil .OR. ! Empty( nMaxLength )
      ::nMaxLength := nMaxLength
   ENDIF

   ::ParsePict( cPicture, vari )

   IF bSetGet != Nil
      ::bGetFocus := bGfocus
      ::bLostFocus := bLfocus
      ::lnoValid := iif( bGfocus != Nil, .T. , .F. )
      ::oParent:AddEvent( EN_SETFOCUS, Self, { | | ::When( ) }, , "onGotFocus" )
      ::oParent:AddEvent( EN_KILLFOCUS, Self, { | | ::Valid( ) }, , "onLostFocus" )
      ::bValid := { | | ::Valid() }
   ELSE
      IF bGfocus != Nil
         ::oParent:AddEvent( EN_SETFOCUS, Self, bGfocus, , "onGotFocus"  )
      ENDIF
      IF bLfocus != Nil
         ::oParent:AddEvent( EN_KILLFOCUS, Self, bLfocus, , "onLostFocus" )
      ENDIF
   ENDIF
   IF bChange != Nil
      ::oParent:AddEvent( EN_CHANGE, Self, bChange, , "onChange"  )
   ENDIF
   ::bColorOld := ::bcolor

   RETURN Self

METHOD Value( Value )  CLASS HEdit
   LOCAL vari

   IF Value != Nil
      ::SetText( Value )
   ENDIF
   vari := iif( Empty( ::Handle ), ::Title, ::UnTransform( hwg_Getedittext( ::oParent:handle, ::id ) ) )
   IF ::cType == "D"
      vari := CToD( vari )
   ELSEIF ::cType == "N"
      vari := Val( LTrim( vari ) )
   ENDIF

   RETURN vari

METHOD Refresh()  CLASS HEdit
   LOCAL vari

   IF ::bSetGet != Nil
      vari := Eval( ::bSetGet, , Self )
      IF ! Empty( ::cPicFunc ) .OR. ! Empty( ::cPicMask )
         vari := iif( vari = Nil, "", Vari )
         vari := Transform( vari, ::cPicFunc + iif( Empty( ::cPicFunc ), "", " " ) + ::cPicMask )
      ELSE
         vari := iif( ::cType == "D", Dtoc( vari ), iif( ::cType == "N", Str( vari ), ;
            iif( ::cType == "C" .AND. ValType( vari ) == "C", Trim( vari ), "" ) ) )
      ENDIF
      ::Title := vari
   ENDIF
   hwg_Setdlgitemtext( ::oParent:handle, ::id, ::title )
   IF hwg_Iswindowvisible( ::handle ) .AND.   !Empty( hwg_GetWindowParent( ::handle ) ) //hwg_Ptrtoulong( hwg_Getfocus() ) == hwg_Ptrtoulong( ::handle )
      hwg_Redrawwindow( ::Handle, RDW_NOERASE + RDW_INVALIDATE + RDW_FRAME + RDW_UPDATENOW ) //+ RDW_NOCHILDREN )
   ENDIF

   RETURN Nil

METHOD SetText( c ) CLASS HEdit

   IF c != Nil
      IF ValType( c ) = "O"
         //in run time return object
         RETURN nil
      ENDIF
      IF ! Empty( ::cPicFunc ) .OR. ! Empty( ::cPicMask )
         ::title := Transform( c, ::cPicFunc + iif( Empty( ::cPicFunc ), "", " " ) + ::cPicMask )
      ELSE
         ::title := c
      ENDIF
      hwg_Setwindowtext( ::Handle, ::Title )
      IF hwg_Iswindowvisible( ::handle ) .AND. ! Empty( hwg_GetWindowParent( ::handle ) )
         hwg_Redrawwindow( ::Handle, RDW_NOERASE + RDW_INVALIDATE + RDW_UPDATENOW )
      ENDIF
      IF ::bSetGet != Nil
         Eval( ::bSetGet, c, Self )
      ENDIF
   ENDIF

   RETURN NIL

FUNCTION hwg_IsCtrlShift( lCtrl, lShift )

   LOCAL cKeyb := hwg_Getkeyboardstate()

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
         ::cPicFunc   := "@D" + iif( "K" $ ::cPicFunc, "K", "" )
         ::cPicMask := StrTran( Dtoc( CToD( Space( 8 ) ) ), ' ', '9' )
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
      ::nMaxLength := Nil
      masklen := Len( ::cPicMask )
      FOR i := 1 TO masklen
         cChar := SubStr( ::cPicMask, i, 1 )
         IF ! cChar $ "!ANX9#"
            ::lPicComplex := .T.
            EXIT
         ENDIF
      NEXT
   ENDIF
   IF Eval( ::bSetGet, , Self ) != Nil
      ::title := Transform( Eval( ::bSetGet,, Self ) , ::cPicFunc + iif( Empty( ::cPicFunc ), "", " " ) + ::cPicMask )
      hwg_Setdlgitemtext( ::oParent:handle, ::id, ::title )
   ENDIF

   RETURN Nil

METHOD IsEditable( nPos, lDel ) CLASS HEdit
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
   ELSEIF ::cType == "N"       // nando add
      RETURN cChar $ "9#$*Z" + iif( !Empty( lDel ), iif( "E" $ ::cPicFunc, ",", "" ), "" )
   ELSEIF ::cType == "D"
      RETURN cChar == "9"
   ELSEIF ::cType == "L"
      RETURN cChar $ "TFYN"
   ENDIF

   RETURN .F.

METHOD KeyRight( nPos ) CLASS HEdit
   LOCAL masklen, newpos

   IF nPos == Nil
      nPos := hwg_Hiword( hwg_Sendmessage( ::handle, EM_GETSEL, 0, 0 ) ) + 1
   ENDIF
   IF ::cPicMask == Nil .OR. Empty( ::cPicMask )
      hwg_Sendmessage( ::handle, EM_SETSEL, nPos, nPos )
   ELSE
      masklen := Len( ::cPicMask )
      DO WHILE nPos <= masklen
         IF ::IsEditable( ++ nPos )
            hwg_Sendmessage( ::handle, EM_SETSEL, nPos - 1, nPos - 1 )
            EXIT
         ENDIF
      ENDDO
   ENDIF

   //Added By Sandro Freire

   IF ! Empty( ::cPicMask )
      newpos := Len( ::cPicMask )
      IF nPos > newpos .AND. ! Empty( Trim( ::Title ) )
         hwg_Sendmessage( ::handle, EM_SETSEL, newpos, newpos )
      ENDIF
   ENDIF
   IF ::oUpDown != Nil .AND. nPos > newPos
      hwg_GetSkip( ::oParent, ::handle, , 1 )
   ENDIF

   RETURN 0

METHOD KeyLeft( nPos ) CLASS HEdit

   IF nPos == Nil
      nPos := hwg_Hiword( hwg_Sendmessage( ::handle, EM_GETSEL, 0, 0 ) ) + 1
   ENDIF
   IF ::cPicMask == Nil .OR. Empty( ::cPicMask )
      hwg_Sendmessage( ::handle, EM_SETSEL, nPos - 2, nPos - 2 )
   ELSE
      DO WHILE nPos >= 1
         IF ::IsEditable( -- nPos )
            hwg_Sendmessage( ::handle, EM_SETSEL, nPos - 1, nPos - 1 )
            EXIT
         ENDIF
      ENDDO
   ENDIF
   IF nPos <= 1
      hwg_GetSkip( ::oParent, ::handle, , - 1 )
   ENDIF

   RETURN 0

METHOD DeleteChar( lBack ) CLASS HEdit
   LOCAL nSel := hwg_Sendmessage( ::handle, EM_GETSEL, 0, 0 )
   LOCAL nPosEnd   := hwg_Hiword( nSel )
   LOCAL nPosStart := hwg_Loword( nSel )
   LOCAL nGetLen := Len( ::cPicMask )
   LOCAL cBuf, nPosEdit

   IF Hwg_BitAnd( hwg_Getwindowlong( ::handle, GWL_STYLE ), ES_READONLY ) != 0
      RETURN Nil
   ENDIF
   IF nGetLen == 0
      nGetLen := Len( ::title )
   ENDIF
   IF nPosEnd == nPosStart
      nPosEnd += iif( lBack, 1, 2 )
      nPosStart -= iif( lBack, 1, 0 )
   ELSE
      nPosEnd += 1
   ENDIF
   /* NEW */
   IF nPosEnd - nPosStart - 1 > 1 .AND. ::lPicComplex .AND. ::cType <> "N"
      lBack := .T.
   ELSE
      IF lBack .AND. ! ::IsEditable( nPosStart + 1, .T. )
         nPosStart -= iif( ::cType <> "N", 1, 0 )
         IF nPosStart < 0
            hwg_Sendmessage( ::handle, EM_SETSEL, ::FirstEditable() - 1, ::FirstEditable() - 1 )
            RETURN Nil
         ENDIF
      ENDIF
      IF  ::lPicComplex .AND. ::cType <> "N" .AND. ::FirstNotEditable( nPosStart ) > 0 .AND. ;
            ( !lBack  .OR. ( lBack .AND. nPosEnd - nPosStart - 1 < 2 ) )
         nPosEdit := ::FirstNotEditable( nPosStart  )
         nGetLen := Len( Trim( Left( ::title,  nPosEdit - 1 ) ) )
         cBuf := ::Title
         IF nGetLen >= nPosStart + 1
            cBuf := Stuff( ::title, nPosStart + 1, 1, "" )
            cBuf := Stuff( cBuf, nGetLen, 0, " " )
         ENDIF
      ELSE
         IF Empty( hwg_Sendmessage( ::handle, EM_GETPASSWORDCHAR, 0, 0 ) )
            cBuf := PadR( Left( ::title, nPosStart ) + SubStr( ::title, nPosEnd ), nGetLen, iif( ::lPicComplex, , Chr(0 ) ) )
         ELSE
            cBuf := Left( ::title, nPosStart ) + SubStr( ::title, nPosEnd )
         ENDIF
      ENDIF
   ENDIF
   IF lBack .AND. ::lPicComplex .AND. ::cType <> "N" .AND. ( nPosStart + nPosEnd > 0 )
      IF lBack .OR. nPosStart <> ( nPosEnd - 2 )
         IF  nPosStart <> ( nPosEnd - 2 )
            cBuf := Left( ::title, nPosStart ) + Space( nPosEnd - nPosStart - 1 ) + SubStr( ::title, nPosEnd )
         ENDIF
      ELSE
         nPosEdit := ::FirstNotEditable( nPosStart + 1 )
         IF nPosEdit > 0
            cBuf := Left( ::title, nPosStart ) + iif( ::IsEditable( nPosStart + 2 ), SubStr( ::title, nPosStart + 2, 1 ) + "  " , "  " ) + SubStr( ::title, nPosEdit + 1 )
         ELSE
            cBuf := Left( ::title, nPosStart ) + SubStr( ::title, nPosStart + 2 ) + Space( nPosEnd - nPosStart - 1 )
         ENDIF
      ENDIF
      cBuf := Transform( cBuf, ::cPicMask )
   ELSEIF ::cType = "N" .AND. Len( AllTrim( cBuf ) ) = 0
      ::lFirst := .T.
      nPosStart := ::FirstEditable() - 1
   ELSEIF ::cType = "N" .AND. ::lPicComplex .AND. !lBack .AND. ;
         Right( Trim( ::title ), 1 ) != '.'
      IF "E" $ ::cPicFunc
         cBuf := Trim( StrTran( cBuf, ".", "" ) )
         cBuf :=  StrTran( cBuf, ",", "." )
      ELSE
         cBuf := Trim( StrTran( cBuf, ",", "" ) )
      ENDIF
      cBuf := Val( LTrim( cBuf ) )
      cBuf := Transform( cBuf, ::cPicFunc + iif( Empty( ::cPicFunc ), "", " " ) + ::cPicMask )
   ENDIF
   ::title := cBuf
   hwg_Setdlgitemtext( ::oParent:handle, ::id, ::title )
   hwg_Sendmessage( ::handle, EM_SETSEL, nPosStart, nPosStart )

   RETURN Nil

METHOD INPUT( cChar, nPos ) CLASS HEdit
   LOCAL cPic

   IF ! Empty( ::cPicMask ) .AND. nPos > Len( ::cPicMask )
      RETURN Nil
   ENDIF
   IF ::cType == "N"
      IF cChar == "-"
         IF nPos != 1
            RETURN Nil
         ENDIF
         ::lFirst := .F.
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
         IF ! IsAlpha( cChar ) .AND. ! IsDigit( cChar )
            cChar := Nil
         ENDIF
      ELSEIF cPic == "9"
         IF ! IsDigit( cChar ) .AND. cChar != "-"
            cChar := Nil
         ENDIF
      ELSEIF cPic == "#"
         IF ! IsDigit( cChar ) .AND. ! ( cChar == " " ) .AND. ! ( cChar $ "+-" )
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
   IF Hwg_BitAnd( hwg_Getwindowlong( ::handle, GWL_STYLE ), ES_READONLY ) != 0
      RETURN 0
   ENDIF

   x := hwg_Sendmessage( ::handle, EM_GETSEL, 0, 0 )
   IF hwg_Hiword( x ) != hwg_Loword( x )
      ::DeleteChar( .F. )
   ENDIF
   ::title := hwg_Getedittext( ::oParent:handle, ::id )
   IF ::cType == "N" .AND. cKey $ ".," .AND. ;
         ( nPos := At( ".", ::cPicMask ) ) != 0
      IF ::lFirst
         // vari := 0
         vari := StrTran( Trim( ::title ), " ", iif( "E" $ ::cPicFunc, ",", "." ) )
         vari := Val( vari )
      ELSE
         vari := Trim( ::title )
         lSignal := iif( Left( vari, 1 ) = "-", .T. , .F. )
         FOR i := 2 TO Len( vari )
            IF ! IsDigit( SubStr( vari, i, 1 ) )
               vari := Left( vari, i - 1 ) + SubStr( vari, i + 1 )
            ENDIF
         NEXT
         IF "E" $ ::cPicFunc .AND. "," $ ::title
            vari := StrTran( ::title, ".", "" )
            vari := StrTran( vari, ",", "." )
            ::title := "."
         ELSE
            // nando -                               remove the .
            vari := StrTran( vari, " ", iif( "E" $ ::cPicFunc, ",", " " ) )
         ENDIF
         vari := Val( vari )
         lSignal := iif( lSignal .AND. vari != 0, .F. , lSignal )
      ENDIF
      IF ( ! Empty( ::cPicFunc ) .OR. ! Empty( ::cPicMask ) ) .AND. ;
            ( ! cKey $ ",." .OR. Right( Trim( ::title ), 1 ) = '.'   )
         ::title := Transform( vari, StrTran( ::cPicFunc, "Z", "" ) + iif( Empty( ::cPicFunc ), "", " " ) + ::cPicMask )
         IF lSignal
            ::title := "-" + SubStr( ::title, 2 )
         ENDIF

      ENDIF
      hwg_Setdlgitemtext( ::oParent:handle, ::id, ::title )
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
         nPos := hwg_Hiword( hwg_Sendmessage( ::handle, EM_GETSEL, 0, 0 ) ) + 1
      ENDIF
      cKey := ::Input( cKey, nPos )
      IF cKey != Nil
         ::SetGetUpdated()
         IF SET( _SET_INSERT ) .OR. hwg_Hiword( x ) != hwg_Loword( x )
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

            IF ( ! Empty( ::cPicFunc ) .OR. ! Empty( ::cPicMask ) ) .AND. ;
                  ( ! cKey $ ",." .OR. Right( Trim( ::title ), 1 ) = '.' )
               ::title := Left( ::title, nPos - 1 ) + cKey + SubStr( ::title, nPos + 1 )
            ENDIF
         ELSE
            ::title := Left( ::title, nPos - 1 ) + cKey + SubStr( ::title, nPos + 1 )
         ENDIF
         IF ! Empty( hwg_Sendmessage( ::handle, EM_GETPASSWORDCHAR, 0, 0 ) )
            ::title := Left( ::title, nPos - 1 ) + cKey + Trim( SubStr( ::title, nPos + 1 ) )
            IF  !Empty( ::nMaxLength ) .AND. Len( Trim( ::GetText() ) ) = ::nMaxLength
               ::title := PadR( ::title, ::nMaxLength )
            ENDIF
            nLen := Len( Trim( ::GetText() ) )
         ELSEIF ! Empty( ::nMaxLength )
            nLen := Len( Trim( ::GetText() ) )
            ::title := PadR( ::title, ::nMaxLength )
         ELSEIF ! Empty( ::cPicMask ) .AND. !"@" $ ::cPicMask
            ::title := PadR( ::title, Len( ::cPicMask ) )
         ENDIF
         hwg_Setdlgitemtext( ::oParent:handle, ::id, ::title )
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
         ELSEIF ! Set( _SET_CONFIRM )
            IF ( ::cType != "D" .AND. !"@" $ ::cPicFunc .AND. Empty( ::cPicMask ) .AND. !Empty( ::nMaxLength ) .AND. nLen >= ::nMaxLength - 1 ) .OR. ;
                  ( !Empty( ::nMaxLength ) .AND. nPos = ::nMaxLength ) .OR. nPos = Len( ::cPicMask )
               hwg_GetSkip( ::oParent, ::handle, , 1 )
            ENDIF
         ENDIF
      ENDIF
   ENDIF
   ::lFirst := .F.

   RETURN 0

METHOD ReadOnly( lreadOnly )

   IF lreadOnly != Nil
      IF ! Empty( hwg_Sendmessage( ::handle,  EM_SETREADONLY, iif( lReadOnly, 1, 0 ), 0 ) )
         ::lReadOnly := lReadOnly
      ENDIF
   ENDIF

   RETURN ::lReadOnly

METHOD SelStart( Start ) CLASS HEdit
   LOCAL nPos

   IF Start != Nil
      ::nSelStart := start
      ::nSelLength := 0
      hwg_Sendmessage( ::handle, EM_SETSEL, start , start )
   ELSEIF ::nSelLength = 0
      nPos := hwg_Hiword( hwg_Sendmessage( ::handle, EM_GETSEL, 0, 0 ) )
      ::nSelStart := nPos
   ENDIF

   RETURN ::nSelStart

METHOD SelLength( Length ) CLASS HEdit

   IF Length != Nil
      hwg_Sendmessage( ::handle, EM_SETSEL, ::nSelStart, ::nSelStart + Length  )
      ::nSelLength := Length
   ENDIF

   RETURN ::nSelLength

METHOD SelText( cText ) CLASS HEdit

   IF cText != Nil
      hwg_Sendmessage( ::handle, EM_SETSEL, ::nSelStart, ::nSelStart + ::nSelLength  )
      hwg_Sendmessage( ::handle, WM_CUT, 0, 0 )
      hwg_Copystringtoclipboard( cText )
      hwg_Sendmessage( ::handle, EM_SETSEL, ::nSelStart, ::nSelStart )
      hwg_Sendmessage( ::handle, WM_PASTE, 0, 0 )
      ::nSelLength := 0
      ::cSelText := cText
   ELSE
      ::cSelText := SubStr( ::title, ::nSelStart + 1, ::nSelLength )
   ENDIF

   RETURN ::cSelText

METHOD SetCueBanner( cText, lShowFoco ) CLASS HEdit

#define EM_SETCUEBANNER 0x1501
   LOCAL lRet := .F.

   IF ! ::lMultiLine
      lRet := hwg_Sendmessage( ::Handle, EM_SETCUEBANNER, ;
         iif( Empty( lShowFoco ), 0, 1 ), hwg_Ansitounicode( cText ) )
   ENDIF

   RETURN lRet

METHOD When() CLASS HEdit
   LOCAL res := .T. , nSkip, vari

   IF ! hwg_CheckFocus( Self, .F. )
      RETURN .F.
   ENDIF

   ::lFirst := .T.
   nSkip := iif( hwg_Getkeystate( VK_UP ) < 0 .OR. ( hwg_Getkeystate( VK_TAB ) < 0 ;
      .AND. hwg_Getkeystate( VK_SHIFT ) < 0 ), - 1, 1 )
   IF ::bGetFocus != Nil
      ::lnoValid := .T.
      IF ::cType == "D"
         vari := CToD( ::title )
      ELSEIF ::cType == "N"
         vari := Val( LTrim( ::title ) )
      ELSE
         vari := ::title
      ENDIF
      ::oParent:lSuspendMsgsHandling := .T.
      res := Eval( ::bGetFocus, vari, iif( ::oUpDown = Nil, Self, ::oUpDown ) )
      res := iif( ValType( res ) == "L", res, .T. )
      ::lnoValid := ! res
      ::oParent:lSuspendMsgsHandling := .F.
      IF ! res
         hwg_WhenSetFocus( Self, nSkip )
      ELSE
         ::Setfocus()
      ENDIF
   ENDIF

   RETURN res

METHOD Valid( ) CLASS HEdit
   LOCAL res := .T. , vari, oDlg

   IF ( ! hwg_CheckFocus( Self, .T. ) .OR. ::lNoValid ) .AND. ::bLostFocus != Nil
      RETURN .T.
   ENDIF
   IF ::bSetGet != Nil
      IF ( oDlg := hwg_GetParentForm( Self ) ) == Nil .OR. oDlg:nLastKey != 27
         vari := ::UnTransform( hwg_Getedittext( ::oParent:handle, ::id ) )
         ::title := vari
         IF ::cType == "D"
            IF ::IsBadDate( vari )
               hwg_Setfocus( 0 )
               ::Setfocus( .T. )
               hwg_Msgbeep()
               hwg_Sendmessage( ::handle, EM_SETSEL, 0, 0 )
               RETURN .F.
            ENDIF
            vari := CToD( vari )
            IF __SetCentury() .AND. Len( Trim ( ::title ) ) < 10
               ::title :=  Dtoc( vari )
               hwg_Setdlgitemtext( ::oParent:handle, ::id, ::title )
            ENDIF
         ELSEIF ::cType == "N"
            vari := Val( LTrim( vari ) )
            ::title := Transform( vari, ::cPicFunc + iif( Empty( ::cPicFunc ), "", " " ) + ::cPicMask )
            hwg_Setdlgitemtext( ::oParent:handle, ::id, ::title )
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
            IF ::oUpDown != Nil // updown control
               ::oUpDown:nValue := vari
            ENDIF
            IF ::bLostFocus != Nil
               res := Eval( ::bLostFocus, vari, iif( ::oUpDown = Nil, Self, ::oUpDown ) )
               res := iif( ValType( res ) == "L", res, .T. )
            ENDIF
            IF res .AND. ::oUpDown != Nil // updown control
               res := ::oUpDown:Valid()
            ENDIF
            IF ValType( res ) = "L" .AND. ! res
               IF oDlg != Nil
                  oDlg:nLastKey := 0
               ENDIF
               ::Setfocus( .T. )
               ::oparent:lSuspendMsgsHandling := .F.
               RETURN .F.
            ENDIF
            IF Empty( hwg_Getfocus() )
               hwg_GetSkip( ::oParent, ::handle, , ::nGetSkip )
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
            res := iif( ValType( res ) == "L", res, .T. )
         ENDIF
         IF res .AND. ::oUpDown != Nil // updown control
            res := ::oUpDown:Valid()
         ENDIF
         IF ! res
            ::Setfocus()
            ::oparent:lSuspendMsgsHandling := .F.
            RETURN .F.
         ENDIF
         IF Empty( hwg_Getfocus() )
            hwg_GetSkip( ::oParent, ::handle, , ::nGetSkip )
         ENDIF
      ENDIF
   ENDIF
   ::oparent:lSuspendMsgsHandling := .F.

   RETURN .T.

METHOD onChange( lForce ) CLASS HEdit

   LOCAL vari

   IF ! hwg_Selffocus( ::handle ) .AND. Empty( lForce )
      RETURN Nil
   ENDIF
   vari := ::Value( )
   IF ::bSetGet != Nil
      Eval( ::bSetGet, vari, Self )
   ENDIF
   IF ::bChange != Nil
      ::oparent:lSuspendMsgsHandling := .T.
      Eval( ::bChange, vari, Self )
      ::oparent:lSuspendMsgsHandling := .F.
   ENDIF

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
            IF ! ::IsEditable( nFor ) .AND. SubStr( cBuffer, nFor, 1 ) != "."
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

METHOD SetGetUpdated() CLASS HEdit

   LOCAL oParent

   ::lChanged := .T.
   IF ( oParent := hwg_GetParentForm( Self ) ) != Nil
      oParent:lUpdated := .T.
   ENDIF

   RETURN Nil

FUNCTION hwg_CreateGetList( oDlg, oCnt )

   LOCAL i, oCtrl, aLen1

   IF oCnt = Nil
      aLen1 := Len( oDlg:aControls )
      oCtrl := oDlg
   ELSE
      aLen1 := Len( oCnt:aControls )
      oCtrl := oCnt
   ENDIF
   FOR i := 1 TO aLen1
      IF Len( oCtrl:aControls[ i ]:aControls ) > 0
         hwg_CreateGetList( oDlg, oCtrl:aControls[ i ] )
      ENDIF
      IF __ObjHasMsg( oCtrl:aControls[ i ], "BSETGET" ) .AND. oCtrl:aControls[ i ]:bSetGet != Nil
         AAdd( oDlg:GetList, oCtrl:aControls[ i ] )
      ENDIF
   NEXT

   RETURN oCtrl

FUNCTION hwg_GetSkip( oParent, hCtrl, lClipper, nSkip )

   LOCAL i, nextHandle, oCtrl
   LOCAL oForm := iif( ( oForm := hwg_GetParentForm(oParent ) ) = Nil, oParent, oForm )

   DEFAULT nSkip := 1
   IF oParent == Nil .OR. ( lClipper != Nil .AND. lClipper .AND. ! oForm:lClipper )
      RETURN .F.
   ENDIF
   i := AScan( oParent:acontrols, { | o | hwg_Ptrtoulong( o:handle ) == hwg_Ptrtoulong( hCtrl ) } )
   oCtrl := iif( i > 0, oParent:acontrols[ i ], oParent )

   IF nSkip != 0
      nextHandle := iif( oParent:className == "HTAB", NextFocusTab( oParent, hCtrl, nSkip ), ;
         iif( oParent:className == oForm:ClassName, NextFocus( oParent, hCtrl, nSkip ), ;
         NextFocuscontainer( oParent, hCtrl, nSkip ) ) )
   ELSE
      nextHandle := hCtrl
   ENDIF

   IF i > 0
      oCtrl:nGetSkip := nSkip
      oCtrl:oParent:lGetSkipLostFocus := .T.
   ENDIF
   IF ! Empty( nextHandle )
      IF oForm:classname == oParent:classname  .OR. oParent:className != "HTAB"
         IF oParent:Type = Nil .OR. oParent:Type < WND_DLG_RESOURCE
            hwg_Setfocus( nextHandle )
         ELSE
            hwg_Postmessage( oParent:handle, WM_NEXTDLGCTL, nextHandle , 1 )
         ENDIF
      ELSE
         IF oForm:Type < WND_DLG_RESOURCE .AND. hwg_Ptrtoulong( oParent:handle ) = hwg_Ptrtoulong( hwg_Getfocus() ) //oParent:oParent:Type < WND_DLG_RESOURCE
            hwg_Setfocus( nextHandle )
         ELSEIF hwg_Ptrtoulong( oParent:handle ) = hwg_Ptrtoulong( hwg_Getfocus() )
            hwg_Postmessage( hwg_Getactivewindow(), WM_NEXTDLGCTL, nextHandle , 1 )
         ELSE
            hwg_Postmessage( oParent:handle, WM_NEXTDLGCTL, nextHandle , 1 )
         ENDIF
      ENDIF
      IF oForm:Type < WND_DLG_RESOURCE
         oForm:nFocus := NextHandle
      ENDIF
      IF  oParent:nScrollBars > - 1  .OR. oForm:nScrollBars > - 1
         oForm := iif( oParent:nScrollBars > - 1, oParent, oForm )
         IF ( i := AScan( oparent:acontrols, { | o | o:handle == NEXTHANDLE } ) ) = 0 .AND.  oParent:oParent != Nil
            i := AScan( oParent:oParent:acontrols, { | o | o:handle == NEXTHANDLE } )
            oCtrl := iif( i > 0, oParent:oParent:aControls[i], oParent )
         ELSE
            oCtrl := iif( i > 0, oParent:aControls[i], oParent )
         ENDIF
         GetSkipScroll( oForm, oCtrl )
      ENDIF
   ENDIF
   IF nSkip != 0 .AND. hwg_Selffocus( hctrl, nextHandle ) .AND. oCtrl != Nil
      // necessary when FORM have only one object and ! CLIPPER
      IF  __ObjHasMsg( oCtrl, "BLOSTFOCUS" ) .AND. oCtrl:blostfocus != Nil .AND. ! oForm:lClipper
         hwg_Sendmessage( nexthandle, WM_KILLFOCUS, 0,  0 )
      ELSE
         hwg_Setfocus( 0 )
         oCtrl:Setfocus( )
      ENDIF
   ENDIF

   RETURN .T.

STATIC FUNCTION GetSkipScroll( oForm, oCtrl )
   LOCAL lScroll := .T.
   LOCAL nWidthScroll := 2

   IF  oForm:nScrollBars > - 1 .AND. oForm:classname == oCtrl:oParent:classname
      DO WHILE lScroll
         lScroll := .F.
         // SCROOLL HORIZONTAL
         IF oForm:nScrollBars != 1
            IF oCtrl:nLeft + oCtrl:nWidth + 12 >= oForm:nWidth - nWidthScroll + oForm:nHscrollPos * HORZ_PTS .AND. ;
                  oCtrl:nWidth < oForm:nWidth .AND. oCtrl:nLeft > oForm:nWidth - oForm:nHscrollPos * HORZ_PTS - nWidthScroll
               IF oForm:nHscrollMax / oForm:nHorzInc > 1
                  hwg_ScrollHV( oForm, WM_HSCROLL, SB_PAGEDOWN, 0 )
               ELSE
                  hwg_ScrollHV( oForm, WM_HSCROLL, SB_LINEDOWN, 0 )
               ENDIF
               lScroll := .T.
            ELSEIF ( oCtrl:nLeft <= oForm:nHscrollPos * HORZ_PTS - nWidthScroll ) //( oCtrl:nLeft + oCtrl:nWidth ) > oForm:nWidth
               IF oForm:nHscrollMax / oForm:nHorzInc > 1
                  hwg_ScrollHV( oForm, WM_HSCROLL, SB_PAGEUP, 0 )
               ELSE
                  hwg_ScrollHV( oForm, WM_HSCROLL, SB_LINEUP, 0 )
               ENDIF
               lScroll := .T.
            ENDIF
            IF oForm:nHscrollMax * HORZ_PTS < oCtrl:nLeft + oCtrl:nWidth
               oForm:nHscrollMax := ( oCtrl:nLeft + oCtrl:nWidth ) / HORZ_PTS
            ENDIF
         ENDIF
         // SCROLL VERTICAL
         IF oForm:nScrollBars >= 1
            IF oCtrl:nTop + oCtrl:nHeight + 12 >= oForm:nHeight - nWidthScroll + oForm:nVscrollPos * VERT_PTS .AND. ;
                  ( oCtrl:nHeight < oForm:nHeight )
               IF  oForm:nVscrollMax / oForm:nVertInc > 1    .AND. .F.
                  hwg_ScrollHV( oForm, WM_VSCROLL, SB_PAGEDOWN, 0 )
               ELSE
                  hwg_ScrollHV( oForm, WM_VSCROLL, SB_LINEDOWN, 0 )
               ENDIF
               lScroll := .T.
            ELSEIF  oCtrl:nTop  <= ( oForm:nVscrollPos * VERT_PTS )
               IF oForm:nVscrollMax / oForm:nVertInc > 1 .AND. .F.
                  hwg_ScrollHV( oForm, WM_VSCROLL, SB_PAGEUP, 0 )
               ELSE
                  hwg_ScrollHV( oForm, WM_VSCROLL, SB_LINEUP, 0 )
               ENDIF
               lScroll := .T.
            ENDIF
            IF oForm:nVscrollMax * VERT_PTS < oCtrl:nTop + oCtrl:nHeight
               oForm:nVscrollMax := ( oCtrl:nTop + oCtrl:nHeight ) / VERT_PTS
            ENDIF
         ENDIF
      ENDDO
   ENDIF

   RETURN Nil

STATIC FUNCTION NextFocusTab( oParent, hCtrl, nSkip )
   LOCAL nextHandle := NIL, i, nPage, nFirst , nLast , k := 0

   IF Len( oParent:aPages ) > 0
      oParent:Setfocus()
      nPage := oParent:GetActivePage( @nFirst, @nLast )
      IF ! oParent:lResourceTab  // TAB without RC
         i :=  AScan( oParent:acontrols, { | o | o:handle == hCtrl } )
         i += iif( i == 0, nFirst, nSkip ) //nLast, nSkip)
         IF i >= nFirst .AND. i <= nLast
            nextHandle := hwg_Getnextdlgtabitem ( oParent:handle , hCtrl, ( nSkip < 0 ) )
            IF  i != AScan( oParent:aControls, { | o | o:handle == nextHandle } ) .AND. oParent:aControls[ i ]:CLASSNAME = "HRADIOB"
               nextHandle := hwg_Getnextdlggroupitem( oParent:handle , hCtrl, ( nSkip < 0 ) )
            ENDIF
            k := AScan( oParent:acontrols, { | o | o:Handle == nextHandle } )
            IF Len( oParent:aControls[ k ]:aControls ) > 0 .AND. hCtrl != nextHandle .AND. oParent:aControls[ k ]:classname != "HTAB"
               nextHandle := NextFocusContainer( oParent:aControls[ k ], oParent:aControls[ k ]:Handle, nSkip )
               RETURN iif( !Empty( nextHandle ), nextHandle, NextFocusTab( oParent, oParent:aControls[ k ]:Handle, nSkip ) )
            ENDIF
         ENDIF
      ELSE
         hwg_Setfocus( oParent:aPages[ nPage, 1 ]:aControls[ 1 ]:Handle )
         RETURN 0
      ENDIF
      IF ( nSkip < 0 .AND. ( k > i .OR. k == 0 ) ) .OR. ( nSkip > 0 .AND. i > k )
         IF oParent:oParent:classname = "HTAB" .AND. oParent:oParent:classname != oParent:classname
            NextFocusTab( oParent:oParent, nextHandle, nSkip )
         ENDIF
         IF Type( "oParent:oParent:Type" ) = "N" .AND. oParent:oParent:Type < WND_DLG_RESOURCE
            nextHandle := hwg_Getnextdlgtabitem ( oParent:oParent:handle , hctrl, ( nSkip < 0 ) )
         ELSE
            nextHandle := hwg_Getnextdlgtabitem ( hwg_Getactivewindow(), hCtrl, ( nSkip < 0 ) )
         ENDIF
         IF AScan( oParent:oParent:acontrols, { | o | o:handle == hCtrl } ) = 0
            RETURN iif( nSkip > 0, NextFocus( oParent:oParent, oParent:Handle, nSkip ), oParent:Handle )
         ELSE
            hwg_Postmessage( hwg_Getactivewindow(), WM_NEXTDLGCTL, nextHandle , 1 )
         ENDIF
         IF !Empty( nextHandle ) .AND. Hwg_BitaND( HWG_GETWINDOWSTYLE( nextHandle ), WS_TABSTOP ) = 0
            NextFocusTab( oParent, nextHandle, nSkip )
         ENDIF
      ENDIF
   ENDIF

   RETURN nextHandle

STATIC FUNCTION NextFocus( oParent, hCtrl, nSkip )
   LOCAL nextHandle := 0,  i, nWindow
   LOCAL lGroup := Hwg_BitAND( HWG_GETWINDOWSTYLE(  hctrl ), WS_GROUP ) != 0
   LOCAL lHradio
   LOCAL lnoTabStop := .T.

   oParent := iif( oParent:Type = Nil, hwg_GetParentForm( oParent ), oParent )
   nWindow := iif( oParent:Type <= WND_DLG_RESOURCE, oParent:Handle, hwg_Getactivewindow() )

   i := AScan( oparent:acontrols, { | o | hwg_Selffocus( o:Handle, hCtrl ) } )
   IF i > 0 .AND. Len( oParent:acontrols[ i ]:aControls ) > 0 .AND. ;
         oParent:aControls[ i ]:className != "HTAB" .AND. ( hwg_Ptrtoulong( hCtrl ) != hwg_Ptrtoulong( nextHandle ) )
      nextHandle := NextFocusContainer( oParent:aControls[ i ], hCtrl , nSkip )
      IF !Empty( nextHandle  )
         RETURN nextHandle
      ENDIF
   ENDIF
   lHradio :=  i > 0 .AND. oParent:acontrols[ i ]:CLASSNAME = "HRADIOB"
   nextHandle := hwg_Getnextdlgtabitem( nWindow , hctrl, ( nSkip < 0 ) )
   IF  lHradio .OR.  lGroup
      nexthandle := hwg_Getnextdlggroupitem( nWindow , hctrl, ( nSkip < 0 ) )
      i := AScan( oParent:aControls, { | o | hwg_Ptrtoulong( o:Handle ) == hwg_Ptrtoulong( nextHandle ) } )
      lnoTabStop := !( i > 0 .AND. oParent:aControls[ i ]:CLASSNAME = "HRADIOB" )
   ENDIF

   IF ( lGroup .AND. nSkip < 0 ) .OR. lnoTabStop
      nextHandle := hwg_Getnextdlgtabitem ( nWindow , hCtrl, ( nSkip < 0 ) )
      lnoTabStop :=  Hwg_BitaND( HWG_GETWINDOWSTYLE( nexthandle ), WS_TABSTOP ) = 0
   ELSE
      lnoTabStop := .F.
   ENDIF
   i := AScan( oParent:aControls, { | o | hwg_Selffocus( o:Handle,  nextHandle ) } )

   IF ( lnoTabStop .AND. i > 0 .AND. !hwg_Selffocus( hCtrl, NextHandle ) ) .OR. ( i > 0 .AND. i <= Len( oParent:aControls ) .AND. ;
         oparent:acontrols[ i ]:classname = "HGROUP" ) .OR. ( i = 0 .AND. !Empty( nextHandle ) )
      RETURN NextFocus( oParent, nextHandle, nSkip )
   ENDIF

   RETURN nextHandle

STATIC FUNCTION NextFocusContainer( oParent, hCtrl, nSkip )
   LOCAL nextHandle := NIL,  i, i2, nWindow
   LOCAL lGroup := Hwg_BitAND( HWG_GETWINDOWSTYLE(  hctrl ), WS_GROUP ) != 0
   LOCAL lHradio
   LOCAL lnoTabStop := .F.

   AEval( oParent:aControls, { | o | iif( Hwg_BitAND( HWG_GETWINDOWSTYLE(  o:handle ), WS_TABSTOP ) != 0, lnoTabStop := .T. , .T. ) } )
   IF !lnoTabStop .OR. Empty( hCtrl )
      RETURN nil //nexthandle
   ENDIF
   nWindow := oParent:handle
   i := AScan( oparent:acontrols, { | o | hwg_Ptrtoulong( o:handle ) == hwg_Ptrtoulong( hCtrl ) } )
   lHradio :=  i > 0 .AND. oParent:acontrols[ i ]:CLASSNAME = "HRADIOB"
   // TABs DO resource
   IF oParent:Type = WND_DLG_RESOURCE
      nexthandle := hwg_Getnextdlggroupitem( oParent:handle , hctrl, ( nSkip < 0 ) )
   ELSE
      IF  lHradio .OR. lGroup
         nextHandle := hwg_Getnextdlggroupitem( nWindow , hCtrl, ( nSkip < 0 ) )
         i := AScan( oParent:aControls, { | o | o:Handle == nextHandle } )
         lnoTabStop := !( i > 0 .AND. oParent:aControls[ i ]:CLASSNAME = "HRADIOB" )  //Hwg_BitAND( HWG_GETWINDOWSTYLE( nexthandle ), WS_TABSTOP ) = 0
      ENDIF
      IF ( lGroup .AND. nSkip < 0 ) .OR. lnoTabStop
         nextHandle := hwg_Getnextdlgtabitem ( nWindow , hctrl, ( nSkip < 0 ) )
         lnoTabStop :=  Hwg_BitaND( HWG_GETWINDOWSTYLE( nextHandle ), WS_TABSTOP ) = 0
      ELSE
         lnoTabStop := .F.
      ENDIF
      i2 := AScan( oParent:aControls, { | o | hwg_Ptrtoulong( o:Handle ) == hwg_Ptrtoulong( nextHandle ) } )
      IF ( ( ( i2 < i .AND. nSkip > 0 ) .OR. ( i2 > i .AND. nSkip < 0 ) ) .OR. hCtrl == nextHandle )
         IF ( ( i2 > i .OR. hCtrl == nextHandle ) .AND. nSkip < 0 )  .AND.  Hwg_BitaND( HWG_GETWINDOWSTYLE( oParent:Handle ), WS_TABSTOP ) != 0
            RETURN oParent:Handle
         ENDIF
         RETURN iif( oParent:oParent:className == "HTAB", NextFocusTab( oParent:oParent, nWindow, nSkip ), ;
            iif( hwg_GetParentForm( oParent ):ClassName == oParent:oParent:Classname, ;
            NextFocus( oParent:oparent, hCtrl, nSkip ), NextFocusContainer( oParent:oparent, hCtrl, nSkip ) ) )
      ENDIF
      i := i2
      IF i = 0
         nextHandle := oParent:aControls[ Len( oParent:aControls ) ]:Handle
      ELSEIF lnoTabStop .OR. ( i > 0 .AND. i <= Len( oParent:acontrols ) .AND. oParent:aControls[i]:classname $ "HGROUP" ) .OR. i = 0
         nextHandle := hwg_Getnextdlgtabitem ( nWindow , nextHandle, ( nSkip < 0 ) )
      ELSEIF nSkip < 0 .AND. Len( oParent:aControls[ i2 ]:aControls ) > 0
         IF ( nextHandle := hb_RASCAN( oParent:aControls[ i2 ]:aControls, ;
               { | o | Hwg_BitaND( HWG_GETWINDOWSTYLE( o:Handle ), WS_TABSTOP ) != 0 .AND. ! o:lHide .AND. o:Enabled } ) ) > 0
            nextHandle := oParent:aControls[ i2 ]:aControls[ nexthandle ]:handle
         ELSE
            nextHandle :=  oParent:aControls[ i2 ]:Handle
         ENDIF
      ENDIF
   ENDIF

   RETURN nextHandle

FUNCTION hwg_SetColorinFocus( lDef, tcolor, bcolor, lFixed, lPersist )


   IF ValType( lDef ) <> "L"
      lDef := ( ValType( lDef ) = "C" .AND. Upper( lDef ) = "ON" )
   ENDIF
   lColorinFocus := lDef
   IF ! lDef
      RETURN .F.
   ENDIF
   lFixedColor   := iif( lFixed != Nil, ! lFixed, lFixedColor )
   tcolorselect  := iif( tcolor != Nil, tcolor, tcolorselect )
   bcolorselect  := iif( bcolor != Nil, bcolor, bcolorselect )
   lPersistColorSelect := iif( lPersist != Nil,  lPersist, lPersistColorSelect )

   RETURN .T.

FUNCTION hwg_SetDisableBackColor( lDef, bcolor )


   IF ValType( lDef ) <> "L"
      lDef := ( ValType( lDef ) = "C" .AND. Upper( lDef ) = "ON" )
   ENDIF
   IF ! lDef
      bDisablecolor := Nil
      RETURN .F.
   ENDIF
   IF  Empty( bColor )
      bDisablecolor :=  iif( Empty( bDisablecolor ), hwg_Getsyscolor( COLOR_BTNHIGHLIGHT ), bDisablecolor )
   ELSE
      bDisablecolor :=  bColor
   ENDIF

   RETURN .T.

