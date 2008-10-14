/*
 *$Id: htab.prg,v 1.33 2008-10-14 15:19:24 lculik Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HTab class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch" 
#include "guilib.ch"
#include "common.ch"
#define TCM_SETCURSEL           4876     // (TCM_FIRST + 12)
#define TCM_SETCURFOCUS         4912     // (TCM_FIRST + 48)
#define TCM_GETCURFOCUS         4911     // (TCM_FIRST + 47)
#define TCM_GETITEMCOUNT        4868     // (TCM_FIRST + 4)

#define TCM_SETIMAGELIST        4867
//- HTab

//----------------------------------------------------//
CLASS HPage INHERIT HObject

   DATA xCaption     HIDDEN
   ACCESS Caption    INLINE ::xCaption
   ASSIGN Caption( xC )  INLINE ::xCaption := xC, ::SetTabText( ::xCaption )
   DATA xEnabled     INIT .T. HIDDEN
   ACCESS Enabled    INLINE ::xEnabled
   ASSIGN Enabled( xL )  INLINE ::xEnabled := xL, IIf( ::xEnabled, ::enable(), ::disable() )
   DATA PageOrder INIT 1
   DATA oParent
   DATA tcolor, bcolor   // not implemented
   DATA oFont   // not implemented
   DATA aItemPos       INIT { }

   METHOD New( cCaption, nPage, lEnabled, tcolor, bcolor )
   METHOD Enable()
   METHOD Disable()  INLINE ::oParent:Disable()
   METHOD GetTabText() INLINE GetTabName( ::oParent:Handle, ::PageOrder - 1 )
   METHOD SetTabText( cText )

ENDCLASS

//----------------------------------------------------//
METHOD New( cCaption, nPage, lEnabled, tcolor, bcolor ) CLASS HPage

   cCaption := IIf( cCaption == nil, "New Page", cCaption )
   lEnabled := IIf( lEnabled != Nil, lEnabled, .T. )
   ::tcolor  := tcolor
   ::bcolor  := bcolor
   ::Pageorder := nPage

   RETURN Self

METHOD SetTabText( cText ) CLASS HPage
   LOCAL i
   IF Len( ::aItemPos ) = 0
      RETURN Nil
   ENDIF
   SetTabName( ::oParent:Handle, ::PageOrder - 1, cText )
   ::oParent:HidePage( ::oParent:nActive )
   ::oParent:ShowPage( ::oParent:nActive )
   FOR i =  1 TO Len( ::oParent:Pages )
      ::oParent:Pages[ i ]:aItemPos := TabItemPos( ::oParent:Handle, i - 1 )
   NEXT
   RETURN Nil

METHOD Enable() CLASS HPage
   LOCAL hDC, client_rect, dwtext, nstyle

   hDC := GetWindowDC( ::oParent:handle )
   SetTextColor( hDC, GetSysColor( COLOR_WINDOWTEXT ) )
   SetBkMode( hDC, 1 )
   IF ::oParent:oFont != Nil
      SelectObject( hDC, ::oParent:oFont:handle )
   ENDIF
   client_rect := ::aItemPos
   IF  Hwg_BitAnd( ::oParent:Style, TCS_FIXEDWIDTH  ) != 0
      nstyle :=  SS_CENTER + SS_RIGHTJUST  //COLOR_GRAYTEXT
      SetaStyle( @nstyle, @dwtext )
      IF ::oParent:nActive = ::PageOrder
         DrawText( hDC, ::caption, client_rect[ 1 ], client_rect[ 2 ] + 1, client_rect[ 3 ], client_rect[ 4 ], dwtext )
      ELSE
         DrawText( hDC, ::caption, client_rect[ 1 ], client_rect[ 2 ] + 3, client_rect[ 3 ], client_rect[ 4 ], dwtext )
      ENDIF
   ELSE
      IF ::oParent:nActive = ::PageOrder
         TextOut( hDC, client_rect[ 1 ] + 6, client_rect[ 2 ] + 1, ::caption )
      ELSE
         TextOut( hDC, client_rect[ 1 ] + 6, client_rect[ 2 ] + 3, ::caption )
      ENDIF
   ENDIF
   RETURN Nil

 *------------------------------------------------------------------------------

CLASS HTab INHERIT HControl

CLASS VAR winclass   INIT "SysTabControl32"
   DATA  aTabs
   DATA  aPages  INIT { }
   DATA  Pages  INIT { }   //nando
   DATA  bChange, bChange2
   DATA  hIml, aImages, Image1, Image2
   DATA  oTemp
   DATA  bAction
   DATA  lResourceTab INIT .F.

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               oFont, bInit, bSize, bPaint, aTabs, bChange, aImages, lResour, nBC, ;
               bClick, bGetFocus, bLostFocus )

   //METHOD Paint( lpdis )
   METHOD Activate()
   METHOD Init()
   METHOD AddPage( oPage )
   METHOD SetTab( n )
   METHOD StartPage( cname, oDlg )
   METHOD EndPage()
   METHOD ChangePage( nPage )
   METHOD DeletePage( nPage )
   METHOD HidePage( nPage )
   METHOD ShowPage( nPage )
   METHOD GetActivePage( nFirst, nEnd )
   METHOD Notify( lParam )
   METHOD OnEvent( msg, wParam, lParam )
   METHOD Disable()
   METHOD Redefine( oWndParent, nId, oFont, bInit, ;
                    bSize, bPaint, ctooltip, tcolor, bcolor, lTransp )

   HIDDEN:
   DATA  nActive  INIT 0         // Active Page

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
            oFont, bInit, bSize, bPaint, aTabs, bChange, aImages, lResour, nBC, bClick, bGetFocus, bLostFocus  ) CLASS HTab
   LOCAL i, aBmpSize

   nStyle   := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), WS_CHILD + WS_VISIBLE + WS_TABSTOP )
   //bPaint   := { | o, p | o:paint( p ) }
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize, bPaint )

   ::title   := ""
   ::oFont   := IIf( oFont == Nil, ::oParent:oFont, oFont )
   ::aTabs   := IIf( aTabs == Nil, { }, aTabs )
   ::bChange := bChange
   ::bChange2 := bChange

   ::bGetFocus := IIf( bGetFocus == Nil, Nil, bGetFocus )
   ::bLostFocus := IIf( bLostFocus == Nil, Nil, bLostFocus )
   ::bAction   := IIf( bClick == Nil, Nil, bClick )

   IF aImages != Nil
      ::aImages := { }
      FOR i := 1 TO Len( aImages )
         AAdd( ::aImages, Upper( aImages[ i ] ) )
         aImages[ i ] := IIf( lResour, LoadBitmap( aImages[ i ] ), OpenBitmap( aImages[ i ] ) )
      NEXT
      aBmpSize := GetBitmapSize( aImages[ 1 ] )
      ::himl := CreateImageList( aImages, aBmpSize[ 1 ], aBmpSize[ 2 ], 12, nBC )
      ::Image1 := 0
      IF Len( aImages ) > 1
         ::Image2 := 1
      ENDIF
   ENDIF
   ::Activate()

   RETURN Self

METHOD Activate CLASS HTab
   IF ! Empty( ::oParent:handle )
      ::handle := CreateTabControl( ::oParent:handle, ::id, ;
                                    ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
   RETURN Nil

METHOD Init() CLASS HTab
   LOCAL i

   IF ! ::lInit
      Super:Init()
      InitTabControl( ::handle, ::aTabs, IF( ::himl != Nil, ::himl, 0 ) )
      ::nHolder := 1
      SetWindowObject( ::handle, Self )

      IF ::himl != Nil
         SendMessage( ::handle, TCM_SETIMAGELIST, 0, ::himl )
      ENDIF
      IF Len( ::aPages ) > 0
         ::Pages[ 1 ]:aItemPos := TabItemPos( ::Handle, 0 )
         FOR i := 2 TO Len( ::aPages )
            ::HidePage( i )
            ::Pages[ i ]:aItemPos := TabItemPos( ::Handle, i - 1 )
         NEXT
      ENDIF
      Hwg_InitTabProc( ::handle )
   ENDIF

   RETURN Nil

METHOD SetTab( n ) CLASS HTab
   SendMessage( ::handle, TCM_SETCURFOCUS, n - 1, 0 )
   // writelog( str(::handle )+" "+Str(SendMessage(::handle,TCM_GETCURFOCUS,0,0 ))+" "+Str(SendMessage(::handle,TCM_GETITEMCOUNT,0,0 )) )
   RETURN Nil

METHOD StartPage( cname, oDlg ) CLASS HTab

   ::oTemp := ::oDefaultParent
   ::oDefaultParent := Self

   IF Len( ::aTabs ) > 0 .AND. Len( ::aPages ) == 0
      ::aTabs := { }
   ENDIF
   AAdd( ::aTabs, cname )
   IF ::lResourceTab
      AAdd( ::aPages, { oDlg , 0 } )
   ELSE
      AAdd( ::aPages, { Len( ::aControls ), 0 } )
   ENDIF
   ::AddPage( HPage():New( cname , Len( ::aPages ), .t., ), cname )
   ::nActive := Len( ::aPages )

   RETURN Nil

METHOD AddPage( oPage, cCaption ) CLASS HTab

   AAdd( ::Pages, oPage )
   InitPage( Self, oPage, cCaption, Len( ::Pages ) )

   RETURN oPage

STATIC FUNCTION InitPage( oTab, oPage, cCaption, n )
   LOCAL cname := "Page" + AllTrim( Str( n ) )

   oPage:oParent := oTab
   __objAddData( oPage:oParent, cname )
   oPage:oParent: & ( cname ) := oPage
   oPage:Caption := cCaption

   RETURN Nil

METHOD EndPage() CLASS HTab
   IF ! ::lResourceTab
      ::aPages[ ::nActive, 2 ] := Len( ::aControls ) - ::aPages[ ::nActive, 1 ]
      IF ::handle != Nil .AND. !Empty( ::handle )
         AddTab( ::handle, ::nActive, ::aTabs[ ::nActive ] )
      ENDIF
      IF ::nActive > 1 .AND. ::handle != Nil .AND. !Empty( ::handle )
         ::HidePage( ::nActive )
      ENDIF
      ::nActive := 1

      ::oDefaultParent := ::oTemp
      ::oTemp := Nil

      ::bChange = { | o, n | o:ChangePage( n ) }


   ELSE
      IF ::handle != Nil .AND. !Empty( ::handle )

         AddTabDialog( ::handle, ::nActive, ::aTabs[ ::nActive ], ::aPages[ ::nactive, 1 ]:handle )
      ENDIF
      IF ::nActive > 1 .AND. ::handle != Nil .AND. !Empty( ::handle )
         ::HidePage( ::nActive )
      ENDIF
      ::nActive := 1

      ::oDefaultParent := ::oTemp
      ::oTemp := Nil

      ::bChange = { | o, n | o:ChangePage( n ) }
   ENDIF

   RETURN Nil

METHOD ChangePage( nPage ) CLASS HTab

   IF ! ::pages[ nPage ]:enabled
      SetTabFocus( Self, nPage )
      RETURN Nil
   ENDIF
   IF nPage = ::nActive
      RETURN Nil
   ENDIF
   IF ! ::pages[ ::nActive ]:enabled
      // REDRAW DISABLE  if disable is active
      ::SetTab( ::nActive )
      ::HidePage( ::nActive )
      ::nActive := nPage
      ::SetTab( nPage )
   ENDIF

   IF ! Empty( ::aPages )

      ::HidePage( ::nActive )

      ::nActive := nPage

      ::ShowPage( ::nActive )

   ENDIF

   IF ::bChange2 != Nil
      Eval( ::bChange2, Self, nPage )
   ENDIF
   //

   RETURN Nil

METHOD HidePage( nPage ) CLASS HTab
   LOCAL i, nFirst, nEnd
   IF ! ::lResourceTab
      nFirst := ::aPages[ nPage, 1 ] + 1
      nEnd   := ::aPages[ nPage, 1 ] + ::aPages[ nPage, 2 ]
      FOR i := nFirst TO nEnd
         ::aControls[ i ]:Hide()
      NEXT
   ELSE
      ::aPages[ nPage, 1 ]:Hide()
   ENDIF

   RETURN Nil

METHOD ShowPage( nPage ) CLASS HTab
   LOCAL i, nFirst, nEnd

   IF ! ::lResourceTab
      nFirst := ::aPages[ nPage, 1 ] + 1
      nEnd   := ::aPages[ nPage, 1 ] + ::aPages[ nPage, 2 ]
      FOR i := nFirst TO nEnd
         ::aControls[ i ]:Show()
      NEXT
   /*
   FOR i := nFirst TO nEnd
      IF (__ObjHasMsg( ::aControls[i],"BSETGET" ) .AND. ::aControls[i]:bSetGet != Nil) .OR. Hwg_BitAnd( ::aControls[i]:style, WS_TABSTOP ) != 0
         SetFocus( ::aControls[i]:handle )
         Exit
      ENDIF
   NEXT
   */
   ELSE
      ::aPages[ nPage, 1 ]:show()
      
      for i :=1  to len(::aPages[nPage,1]:aControls)
         IF (__ObjHasMsg( ::aPages[nPage,1]:aControls[i],"BSETGET" ) .AND. ::aPages[nPage,1]:aControls[i]:bSetGet != Nil) .OR. Hwg_BitAnd( ::aPages[nPage,1]:aControls[i]:style, WS_TABSTOP ) != 0
            SetFocus( ::aPages[nPage,1]:aControls[i]:handle )
            Exit
         ENDIF
      next
      
   ENDIF

   RETURN Nil

METHOD GetActivePage( nFirst, nEnd ) CLASS HTab
   IF ! ::lResourceTab
      IF ! Empty( ::aPages )
         nFirst := ::aPages[ ::nActive, 1 ] + 1
         nEnd   := ::aPages[ ::nActive, 1 ] + ::aPages[ ::nActive, 2 ]
      ELSE
         nFirst := 1
         nEnd   := Len( ::aControls )
      ENDIF
   ELSE
      nFirst := 1
      nEnd   := LEN(::aPages[ ::nActive, 1]:aControls)
   ENDIF

   RETURN ::nActive

METHOD DeletePage( nPage ) CLASS HTab
   IF ::lResourceTab
      ADel( ::m_arrayStatusTab, nPage,, .t. )
      DeleteTab( ::handle, nPage )
      ::nActive := nPage - 1

   ELSE
      DeleteTab( ::handle, nPage - 1 )

      ADel( ::aPages, nPage )
      ADel( ::Pages, nPage )
      ASize( ::aPages, Len( ::aPages ) - 1 )
      ASize( ::Pages, Len( ::Pages ) - 1 )

      IF nPage > 1
         ::nActive := nPage - 1
         ::SetTab( ::nActive )
      ELSEIF Len( ::aPages ) > 0
         ::nActive := 1
         ::SetTab( 1 )
      ENDIF
   ENDIF

   RETURN ::nActive


METHOD Notify( lParam ) CLASS HTab
   LOCAL nCode := GetNotifyCode( lParam )

   DO CASE
   CASE nCode == - 552 //TCN_SELCHANGING    //= (TCN_FIRST - 2) -552
   CASE nCode == TCN_SELCHANGE
      IF ::bChange != Nil
         Eval( ::bChange, Self, GetCurrentTab( ::handle ) )
      ENDIF
   CASE nCode == TCN_CLICK
      IF ::pages[ ::nActive ]:enabled
         SetFocus( ::handle )
         IF ::bAction != Nil
            Eval( ::bAction, Self, GetCurrentTab( ::handle ) )
         ENDIF
      ENDIF
   CASE nCode == TCN_SETFOCUS
      IF ::bGetFocus != NIL
         Eval( ::bGetFocus, Self, GetCurrentTab( ::handle ) )
      ENDIF
   CASE nCode == TCN_KILLFOCUS
      IF ::bLostFocus != NIL
         Eval( ::bLostFocus, Self, GetCurrentTab( ::handle ) )
      ENDIF
   CASE nCode == - 500 //TCN_KEYDOWN   // -500

   ENDCASE

   RETURN - 1

METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
                 bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aItem )  CLASS hTab

   HB_SYMBOL_UNUSED( cCaption )
   HB_SYMBOL_UNUSED( lTransp )
   HB_SYMBOL_UNUSED( aItem )

   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor )
   HWG_InitCommonControlsEx()
   ::lResourceTab := .T.
   ::aTabs  := { }
   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   RETURN Self


METHOD OnEvent( msg, wParam, lParam ) CLASS HTab
   //WRITELOG('TAB'+STR(MSG)+STR(WPARAM)+STR(LPARAM)+CHR(13))

   ::disable()
   IF (msg == WM_KEYDOWN .OR.(msg = WM_GETDLGCODE .AND. wparam == VK_RETURN)) .AND. GetFocus()= ::handle
      IF ( wParam == VK_DOWN .or. wParam == VK_RETURN ) .AND. ::nActive > 0  
         GetSkip( Self, ::handle,, 1 )
      ENDIF
      IF wParam == VK_UP .AND. ::nActive > 0  //
         KEYB_EVENT( VK_TAB, VK_SHIFT, .T. )
      ENDIF
   ENDIF
   IF ::bOther != Nil
      ::oparent:lSuspendMsgsHandling := .t.
      IF Eval( ::bOther, Self, msg, wParam, lParam ) != - 1
        * RETURN 0
      ENDIF
      ::oparent:lSuspendMsgsHandling := .f.
   ENDIF
   IF ! ( ( msg == WM_COMMAND .OR. msg == WM_NOTIFY ) .AND. ::oParent:lSuspendMsgsHandling )
      IF  __ObjHasMsg(::oParent,"NINITFOCUS") .AND. ::oParent:nInitFocus > 0 .AND. isWindowVisible(::oParent:handle)
         SETFOCUS(::oParent:nInitFocus)
         ::oParent:nInitFocus := 0
      ENDIF  
      RETURN ( Super:onevent( msg, wParam, lParam ) )
   ENDIF

   RETURN - 1


METHOD Disable() CLASS HTab
   LOCAL hDC, client_rect, dwtext, nstyle, i

   FOR i = 1 TO Len( ::Pages )
      IF ::pages[ i ]:enabled = .F.
         hDC := GetWindowDC( ::handle )
         selectObject( hDC, ::oFont )
         SetTextColor( hDC, GetSysColor( COLOR_GRAYTEXT ) )
         SetBkMode( hDC, 1 )
         IF ::oFont != Nil
            SelectObject( hDC, ::oFont:handle )
         ENDIF
         client_rect := ::pages[ i ]:aItemPos //TABITEMPOS(OTAB:Handle,i-1)
         IF  Hwg_BitAnd( ::Style, TCS_FIXEDWIDTH  ) != 0
            nstyle :=  SS_CENTER + SS_RIGHTJUST  //COLOR_GRAYTEXT
            SetaStyle( @nstyle, @dwtext )
            IF ::nActive = i
               DrawText( hDC, ::pages[ i ]:caption, client_rect[ 1 ], client_rect[ 2 ] + 1, client_rect[ 3 ], client_rect[ 4 ], dwtext )
            ELSE
               DrawText( hDC, ::pages[ i ]:caption, client_rect[ 1 ], client_rect[ 2 ] + 3, client_rect[ 3 ], client_rect[ 4 ], dwtext )
            ENDIF
         ELSE
            IF ::nActive = i
               TextOut( hDC, client_rect[ 1 ] + 6, client_rect[ 2 ] + 1, ::pages[ i ]:caption )
            ELSE
               TextOut( hDC, client_rect[ 1 ] + 6, client_rect[ 2 ] + 3, ::pages[ i ]:caption )
            ENDIF
         ENDIF
      ENDIF
   NEXT
   RETURN NIL

STATIC FUNCTION SetTabFocus( oCtrl, nPage )
   LOCAL lkLeft := GetKeyState( VK_LEFT ) < 0
   LOCAL i := 0, nSkip, nStart, nEnd

   IF lkLeft .OR. GetKeyState( VK_RIGHT ) < 0
      nStart :=  nPage //IIF(lkLeft, nPage, 1)
      nEnd := IIf( lkLeft, 1, Len( oCtrl:aPages ) )
      nSkip := IIf( lkLeft, - 1, 1 )
      FOR i = nStart TO nEnd STEP nSkip
         IF oCtrl:pages[ i ]:enabled
            oCtrl:SetTab( i )
            RETURN Nil
         ENDIF
      NEXT
   ENDIF
   oCtrl:SetTab( oCtrl:nActive )
   RETURN Nil
