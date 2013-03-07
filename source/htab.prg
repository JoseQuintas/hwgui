/*
 *$Id$
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

   //- HTab

#define TRANSPARENT 1

   //----------------------------------------------------//

CLASS HPage INHERIT HObject

   DATA xCaption     HIDDEN
   ACCESS Caption    INLINE ::xCaption
   ASSIGN Caption( xC )  INLINE ::xCaption := xC, ::SetTabText( ::xCaption )
   DATA lEnabled  INIT .T. // HIDDEN
   DATA PageOrder INIT 1
   DATA oParent
   DATA tcolor, bcolor
   DATA brush
   DATA oFont   // not implemented
   DATA aItemPos       INIT { }
   DATA Tooltip

   METHOD New( cCaption, nPage, lEnabled, tcolor, bcolor, cTooltip )
   METHOD Enable() INLINE ::Enabled( .T. )
   METHOD Disable() INLINE ::Enabled( .F. )
   METHOD GetTabText() INLINE hwg_Gettabname( ::oParent:Handle, ::PageOrder - 1 )
   METHOD SetTabText( cText )
   METHOD Refresh() INLINE ::oParent:ShowPage( ::PageOrder )
   METHOD Enabled( lEnabled ) SETGET
   METHOD Setcolor( tcolor, bcolor )

ENDCLASS

   //----------------------------------------------------//

METHOD New( cCaption, nPage, lEnabled, tcolor, bcolor, cTooltip ) CLASS HPage

   cCaption := iif( cCaption == NIL, "New Page", cCaption )
   ::lEnabled := iif( lEnabled != NIL, lEnabled, .T. )
   ::Pageorder := nPage
   ::Tooltip := cTooltip
   ::Setcolor( tColor, bColor )

   RETURN Self

METHOD Setcolor( tcolor, bColor ) CLASS HPage

   IF tcolor != NIL
      ::tcolor := tcolor
   ENDIF
   IF bColor != NIL
      ::bColor := bColor
      IF ::brush != NIL
         ::brush:Release()
      ENDIF
      ::brush := HBrush():Add( bColor )
   ENDIF
   IF ::oParent = NIL .OR. ( bColor = NIL .AND. tcolor = NIL )
      RETURN NIL
   ENDIF
   hwg_Invalidaterect( ::oParent:Handle, 1 )
   ::oParent:SetPaintSizePos( iif( bColor = NIL, 1, - 1 ) )

   RETURN NIL

METHOD SetTabText( cText ) CLASS HPage

   IF Len( ::aItemPos ) = 0
      RETURN NIL
   ENDIF

   hwg_Settabname( ::oParent:Handle, ::PageOrder - 1, cText )
   ::xCaption := cText
   hwg_Invalidaterect( ::oParent:handle, 0, ::aItemPos[ 1 ], ::aItemPos[ 2 ], ::aItemPos[ 1 ] + ::aItemPos[ 3 ], ::aItemPos[ 2 ] + ::aItemPos[ 4 ] )
   hwg_Invalidaterect( ::oParent:Handle, 1 )

   RETURN NIL

METHOD Enabled( lEnabled ) CLASS HPage
   LOCAL nActive

   IF lEnabled != NIL .AND. ::lEnabled != lEnabled
      ::lEnabled := lEnabled
      IF lEnabled .AND. ( ::PageOrder != ::oParent:nActive .OR. ! hwg_Iswindowenabled( ::oParent:Handle ) )
         IF ! hwg_Iswindowenabled( ::oParent:Handle )
            ::oParent:Enable()
            ::oParent:setTab( ::PageOrder )
         ENDIF
      ENDIF
      ::oParent:ShowDisablePage( ::PageOrder )
      IF ::PageOrder = ::oParent:nActive .AND. !::lenabled
         nActive := SetTabFocus( ::oParent, ::oParent:nActive, VK_RIGHT )
         IF nActive > 0 .AND. ::oParent:Pages[ nActive ]:lEnabled
            ::oParent:setTab( nActive )
         ENDIF
      ENDIF
      IF Ascan( ::oParent:Pages, { | p | p:lEnabled } ) = 0
         ::oParent:Disable()
         hwg_Sendmessage( ::oParent:handle, TCM_SETCURSEL, - 1, 0 )
      ENDIF
   ENDIF

   RETURN ::lEnabled

   /*----------------------------------------------------------------------------*/

CLASS HTab INHERIT HControl, HScrollArea

   CLASS VAR winclass   INIT "SysTabControl32"
   DATA  aTabs
   DATA  aPages  INIT { }
   DATA  Pages  INIT { }
   DATA  bChange, bChange2
   DATA  hIml, aImages, Image1, Image2
   DATA  aBmpSize INIT { 0, 0 }
   DATA  oTemp
   DATA  bAction, bRClick
   DATA  lResourceTab INIT .F.
   DATA oPaint
   DATA nPaintHeight INIT 0
   DATA TabHeightSize
   DATA internalPaint INIT 0 HIDDEN

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, aTabs, bChange, aImages, lResour, nBC, ;
      bClick, bGetFocus, bLostFocus, bRClick )
   METHOD Activate()
   METHOD Init()
   METHOD AddPage( oPage, cCaption )
   METHOD SetTab( n )
   METHOD StartPage( cname, oDlg, lEnabled, tcolor, bcolor, cTooltip )
   METHOD EndPage()
   METHOD ChangePage( nPage )
   METHOD DeletePage( nPage )
   METHOD HidePage( nPage )
   METHOD ShowPage( nPage )
   METHOD GetActivePage( nFirst, nEnd )
   METHOD Notify( lParam )
   METHOD OnEvent( msg, wParam, lParam )
   METHOD Refresh( lAll )
   METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aItem )
   METHOD ShowDisablePage( nPageEnable, nEvent )
   METHOD DisablePage( nPage ) INLINE ::Pages[ nPage ]:disable()
   METHOD EnablePage( nPage ) INLINE ::Pages[ nPage ]:enable()
   METHOD SetPaintSizePos( nFlag  )
   METHOD RedrawControls()
   METHOD ShowToolTips( lParam )
   METHOD onChange( )

   HIDDEN:
   DATA  nActive    INIT 0         // Active Page
   DATA  nPrevPage  INIT 0
   DATA  lClick     INIT .F.
   DATA  nActivate
   DATA  aControlsHide INIT {}

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, aTabs, bChange, aImages, lResour, nBC, bClick, bGetFocus, bLostFocus, bRClick ) CLASS HTab
   LOCAL i

   nStyle   := Hwg_BitOr( iif( nStyle == NIL, 0, nStyle ), WS_CHILD + WS_CLIPSIBLINGS + WS_TABSTOP + TCS_TOOLTIPS )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize, bPaint )
   ::title   := ""
   ::oFont   := iif( oFont == NIL, ::oParent:oFont, oFont )
   ::aTabs   := iif( aTabs == NIL, { }, aTabs )
   ::bChange := bChange
   ::bChange2 := bChange
   ::bGetFocus :=  bGetFocus
   ::bLostFocus :=  bLostFocus
   ::bAction   := bClick
   ::bRClick   := bRClick

   IF aImages != NIL
      ::aImages := { }
      FOR i := 1 TO Len( aImages )
         //AAdd( ::aImages, Upper( aImages[ i ] ) )
         aImages[ i ] := iif( lResour, hwg_Loadbitmap( aImages[ i ] ), hwg_Openbitmap( aImages[ i ] ) )
         AAdd( ::aImages, aImages[ i ] )
      NEXT
      ::aBmpSize := hwg_Getbitmapsize( aImages[ 1 ] )
      ::himl := hwg_Createimagelist( aImages, ::aBmpSize[ 1 ], ::aBmpSize[ 2 ], 12, nBC )
      ::Image1 := 0
      IF Len( aImages ) > 1
         ::Image2 := 1
      ENDIF
   ENDIF
   ::oPaint := HPaintTab():New( Self, , 0, 0, 0, 0 ) //, ::oFont )
   // ::brush := hwg_GetBackColorParent( Self, .T. )
   HWG_InitCommonControlsEx()
   ::Activate()

   RETURN Self

METHOD Activate() CLASS HTab

   IF ! Empty( ::oParent:handle )
      ::handle := hwg_Createtabcontrol( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN NIL

METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aItem )  CLASS hTab

   HB_SYMBOL_UNUSED( cCaption )
   HB_SYMBOL_UNUSED( lTransp )
   HB_SYMBOL_UNUSED( aItem )

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor )
   HWG_InitCommonControlsEx()
   ::lResourceTab := .T.
   ::aTabs := { }
   ::style := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   ::brush := hwg_GetBackColorParent( Self, .T. )
   ::oPaint := HPaintTab():New( Self, , 0, 0, 0, 0 ) //, ::oFont )

   RETURN Self

METHOD Init() CLASS HTab
   LOCAL i, x := 0

   IF ! ::lInit
      hwg_Inittabcontrol( ::handle, ::aTabs, iif( ::himl != NIL, ::himl, 0 ) )
      hwg_Sendmessage( ::HANDLE, TCM_SETMINTABWIDTH , 0 , 0 )
      IF Hwg_BitAnd( ::Style, TCS_FIXEDWIDTH  ) != 0
         ::TabHeightSize := 25 - ( ::oFont:Height + 12 )
         x := ::nWidth / Len( ::aPages ) - 2
      ELSEIF ::TabHeightSize != NIL
      ELSEIF ::oFont != NIL
         ::TabHeightSize := 25 - ( ::oFont:Height + 12 )
      ELSE
         ::TabHeightSize := 23
      ENDIF
      hwg_Sendmessage( ::Handle, TCM_SETITEMSIZE, 0, hwg_Makelparam( x, ::TabHeightSize ) )
      IF ::himl != NIL
         hwg_Sendmessage( ::handle, TCM_SETIMAGELIST, 0, ::himl )
      ENDIF
      hwg_Addtooltip( hwg_GetParentForm( Self ):handle, ::handle, "" )
      ::Super:Init()

      IF Len( ::aPages ) > 0
         ::SetPaintSizePos( iif( ASCAN( ::Pages, { | p | p:brush != NIL } ) > 0 , - 1, 1 ) )
         ::nActive := 0
         FOR i := 1 TO Len( ::aPages )
            ::Pages[ i ]:aItemPos := hwg_Tabitempos( ::handle, i - 1 )
            ::HidePage( i )
            ::nActive := Iif( ::nActive = 0 .AND. ::Pages[ i ]:Enabled, i, ::nActive )
         NEXT
         hwg_Sendmessage( ::handle, TCM_SETCURFOCUS, ::nActive - 1, 0 )
         IF ::nActive = 0
            ::Disable()
            ::ShowPage( 1 )
         ELSE
            ::ShowPage( ::nActive )
         ENDIF
      ELSEIF ( i := hwg_Sendmessage( ::handle, TCM_GETITEMCOUNT, 0, 0 ) ) > 0
         ASize( ::aPages, i )
         AEval( ::aPages, { | a , i | HB_SYMBOL_UNUSED( a ), ::AddPage( HPage():New( "" ,i, .T. , ), "" ) } )
         ::nActive := 1
      ENDIF
      ::nHolder := 1
      hwg_Setwindowobject( ::handle, Self )
      Hwg_InitTabProc( ::handle )
   ENDIF

   RETURN NIL

METHOD SetPaintSizePos( nFlag ) CLASS HTab
   LOCAL aItemPos

   ::Pages[ ::nActive ]:aItemPos := hwg_Tabitempos( ::Handle, ::nActive - 1 ) //0 )
   aItemPos := ::Pages[ ::nActive ]:aItemPos
   IF nFlag = - 1
      ::oPaint:nLeft :=   1
      ::oPaint:nWidth := ::nWidth - 3
      IF Hwg_BitAnd( ::Style, TCS_BOTTOM  ) != 0
         ::oPaint:nTop :=   1
         ::oPaint:nHeight := aItemPos[ 2 ] - 3
      ELSE
         ::oPaint:nTop := aItemPos[ 4 ]
         ::oPaint:nHeight := ::nHeight - aItemPos[ 4 ] - 3
      ENDIF
      ::nPaintHeight  := ::oPaint:nHeight
   ELSEIF nFlag = - 2
      hwg_Setwindowpos( ::oPaint:Handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE + SWP_NOREDRAW + SWP_NOACTIVATE + SWP_NOSENDCHANGING )
      RETURN NIL
   ELSEIF nFlag > 0
      ::npaintheight  := nFlag
      ::oPaint:nHeight := nFlag
      IF ! hwg_Iswindowenabled( ::Handle )
         RETURN NIL
      ENDIF
   ENDIF
   hwg_Setwindowpos( ::oPaint:Handle, NIL, ::oPaint:nLeft, ::oPaint:nTop, ::oPaint:nWidth, ::oPaint:nHeight, SWP_NOACTIVATE  ) //+ SWP_SHOWWINDOW  )

   RETURN NIL

METHOD SetTab( n ) CLASS HTab

   IF n > 0 .AND. n <= Len( ::aPages )
      IF ::Pages[ n ]:Enabled
         ::changePage( n )
         hwg_Sendmessage( ::handle, TCM_SETCURFOCUS, n - 1, 0 )
      ENDIF
   ENDIF

   RETURN NIL

METHOD StartPage( cname, oDlg, lEnabled, tColor, bColor, cTooltip  ) CLASS HTab

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
   ::AddPage( HPage():New( cname ,Len( ::aPages ), lEnabled,  tColor, bcolor, cTooltip  ), cName )
   ::nActive := Len( ::aPages )
   ::Pages[ ::nActive ]:aItemPos := { 0, 0, 0, 0 }

   RETURN NIL

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

   RETURN NIL

METHOD EndPage() CLASS HTab
   LOCAL i, cName, cPage := "Page" + AllTrim( Str( ::nActive ) )

   IF ! ::lResourceTab
      ::aPages[ ::nActive, 2 ] := Len( ::aControls ) - ::aPages[ ::nActive, 1 ]
      IF ::handle != NIL .AND. ! Empty( ::handle )
         hwg_Addtab( ::handle, ::nActive, ::aTabs[ ::nActive ] )
      ENDIF
      IF ::nActive > 1 .AND. ::handle != NIL .AND. ! Empty( ::handle )
         ::HidePage( ::nActive )
      ENDIF
      // add news objects how property in tab
      FOR i = ::aPages[ ::nActive,1 ] + 1 TO ::aPages[ ::nActive,1 ] + ::aPages[ ::nActive,2 ]
         cName := ::aControls[ i ]:name
         IF !Empty( cName ) .AND. ValType( cName ) == "C" .AND. ! ":" $ cName .AND. ;
               ! "->" $ cName .AND. ! "[" $ cName
            __objAddData( ::&cPage, cName )
            ::&cPage:&( ::aControls[ i ]:name ) := ::aControls[ i ]
         ENDIF
      NEXT
      ::nActive := 1
      ::oDefaultParent := ::oTemp
      ::oTemp := NIL
      ::bChange = { | n, o | o:ChangePage( n ) }
   ELSE
      IF ::handle != NIL .AND. ! Empty( ::handle )
         hwg_Addtabdialog( ::handle, ::nActive, ::aTabs[ ::nActive ], ::aPages[ ::nactive, 1 ]:handle )
      ENDIF
      IF ::nActive > 1 .AND. ::handle != NIL .AND. ! Empty( ::handle )
         ::HidePage( ::nActive )
      ENDIF
      ::nActive := 1
      ::oDefaultParent := ::oTemp
      ::oTemp := NIL
      ::bChange = { | n, o | o:ChangePage( n ) }
   ENDIF

   RETURN NIL

METHOD ChangePage( nPage ) CLASS HTab

   IF nPage = ::nActive  //.OR. ! ::pages[ nPage ]:enabled
      RETURN NIL
   ENDIF
   IF ! Empty( ::aPages ) .AND. ::pages[ nPage ]:enabled
      //-client_rect := hwg_Tabitempos( ::Handle, ::nActive - 1 )
      IF ::nActive > 0
         ::HidePage( ::nActive )
         IF ::Pages[ nPage ]:brush != NIL
            ::SetPaintSizePos(  - 1 )
            hwg_Redrawwindow( ::oPaint:Handle, RDW_INVALIDATE  + RDW_INTERNALPAINT  )
         ENDIF
      ENDIF
      ::nActive := nPage
      IF ::bChange2 != NIL
         ::onChange( )
      ENDIF
      ::ShowPage( nPage )

      IF ::oPaint:nHeight  > ::TabHeightSize + 1
         //- hwg_Invalidaterect( ::handle, 1, client_rect[ 1 ], client_rect[ 2 ] , client_rect[ 3 ] + 3, client_rect[ 4 ] + 0 )
      ENDIF
   ENDIF

   RETURN NIL

METHOD onChange( ) CLASS HTab

   IF ::bChange2 != NIL
      ::oparent:lSuspendMsgsHandling := .T.
      Eval( ::bChange2, ::nActive, Self )
      ::oparent:lSuspendMsgsHandling := .F.
   ENDIF

   RETURN NIL

METHOD HidePage( nPage ) CLASS HTab
   LOCAL i, nFirst, nEnd, k

   IF ! ::lResourceTab
      nFirst := ::aPages[ nPage, 1 ] + 1
      nEnd   := ::aPages[ nPage, 1 ] + ::aPages[ nPage, 2 ]
      FOR i := nFirst TO nEnd
         IF ( k := ASCAN( ::aControlsHide, ::aControls[ i ]:id  ) ) = 0 .AND. ::aControls[ i ]:lHide
            AAdd( ::aControlsHide,  ::aControls[ i ]:id )
         ELSEIF k > 0 .AND. ! ::aControls[i]:lHide
            ADel( ::aControlsHide, k )
            ASize( ::aControlsHide, Len( ::aControlsHide ) - 1 )
         ENDIF
         ::aControls[ i ]:Hide()
      NEXT
   ELSE
      ::aPages[ nPage, 1 ]:Hide()
   ENDIF

   RETURN NIL

METHOD ShowPage( nPage ) CLASS HTab
   LOCAL i, nFirst, nEnd

   IF ! ::lResourceTab
      nFirst := ::aPages[ nPage, 1 ] + 1
      nEnd   := ::aPages[ nPage, 1 ] + ::aPages[ nPage, 2 ]
      IF ::oPaint:nHeight > 1 .AND. ::Pages[ nPage ]:brush != NIL .AND. ;
            ASCAN( ::aControls, { | o | o:winclass = ::winclass }, nFirst, nEnd - nFirst + 1 ) > 0
         ::SetPaintSizePos( - 2 )
      ENDIF
      FOR i := nFirst TO nEnd
         IF ! ::aControls[i]:lHide .OR. ( Len( ::aControlsHide ) = 0 .OR. ASCAN( ::aControlsHide, ::aControls[i]:id ) = 0 )
            ::aControls[ i ]:Show( SW_SHOWNA )
         ENDIF
      NEXT
      IF ::Pages[ nPage ]:brush = NIL .AND. ::oPaint:nHeight > 1
         ::SetPaintSizePos( 1 )
      ENDIF
   ELSE
      ::aPages[ nPage, 1 ]:show()

      FOR i := 1  TO Len( ::aPages[ nPage, 1 ]:aControls )
         IF ( __ObjHasMsg( ::aPages[ nPage, 1 ]:aControls[ i ], "BSETGET" ) .AND. ::aPages[ nPage, 1 ]:aControls[ i ]:bSetGet != NIL ) .OR. Hwg_BitAnd( ::aPages[ nPage, 1 ]:aControls[ i ]:style, WS_TABSTOP ) != 0
            hwg_Setfocus( ::aPages[ nPage, 1 ]:aControls[ i ]:handle )
            EXIT
         ENDIF
      NEXT

   ENDIF

   RETURN NIL

METHOD Refresh( lAll ) CLASS HTab
   LOCAL i, nFirst, nEnd, lRefresh
   LOCAL hCtrl := hwg_Getfocus()

   IF ::nActive != 0
      IF ! ::lResourceTab
         lAll := iif( lAll = NIL, .F. , lAll )
         nFirst := ::aPages[ ::nActive, 1 ] + 1
         nEnd   := ::aPages[ ::nActive, 1 ] + ::aPages[ ::nActive, 2 ]
         FOR i := nFirst TO nEnd
            lRefresh :=  ! Empty( __ObjHasMethod( ::aControls[ i ], "REFRESH" ) ) .AND.  ;
               ( __ObjHasMsg( ::aControls[ i ], "BSETGET" ) .OR. lAll ) .AND. ::aControls[ i ]:Handle != hCtrl
            IF ! Empty( lRefresh )
               ::aControls[ i ]:Refresh( )
               IF ::aControls[ i ]:bRefresh != NIL
                  Eval( ::aControls[ i ]:bRefresh, ::aControls[ i ] )
               ENDIF
            ENDIF
         NEXT
      ENDIF
   ELSE
      ::aPages[ ::nActive, 1 ]:Refresh()
   ENDIF

   RETURN NIL

METHOD RedrawControls() CLASS HTab
   LOCAL i

   IF ::nActive != 0
      IF ! ::lResourceTab
         ::oParent:lSuspendMsgsHandling := .T.
         FOR i := ::aPages[ ::nActive, 1 ] + 1 TO ::aPages[ ::nActive, 1 ] + ::aPages[ ::nActive, 2 ]
            IF hwg_Iswindowvisible( ::aControls[ i ]:Handle )
               hwg_Redrawwindow( ::aControls[ i ]:handle,  iif( ::classname != ::aControls[ i ]:classname, ;
                  RDW_NOERASE + RDW_FRAME + RDW_INVALIDATE + RDW_NOINTERNALPAINT, RDW_NOERASE + RDW_INVALIDATE ) )
            ENDIF
         NEXT
         ::oParent:lSuspendMsgsHandling := .F.
      ENDIF
   ENDIF

   RETURN NIL

METHOD GetActivePage( nFirst, nEnd ) CLASS HTab

   IF ::nActive > 0
      IF ! ::lResourceTab
         IF ! Empty( ::aPages ) .AND. Valtype(::aPages[1]) == "A"
            nFirst := ::aPages[ ::nActive, 1 ] + 1
            nEnd   := ::aPages[ ::nActive, 1 ] + ::aPages[ ::nActive, 2 ]
         ELSE
            nFirst := 1
            nEnd   := Len( ::aControls )
         ENDIF
      ELSE
         nFirst := 1
         nEnd   := Len( ::aPages[ ::nActive, 1 ]:aControls )
      ENDIF
   ENDIF

   RETURN ::nActive

METHOD DeletePage( nPage ) CLASS HTab

   IF ::lResourceTab
      ADel( ::m_arrayStatusTab, nPage, , .T. )
      hwg_Deletetab( ::handle, nPage )
      ::nActive := nPage - 1
   ELSE
      hwg_Deletetab( ::handle, nPage - 1 )
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
   LOCAL nCode := hwg_Getnotifycode( lParam )
   LOCAL nkeyDown := hwg_Getnotifykeydown( lParam )
   LOCAL nPage := hwg_Sendmessage( ::handle, TCM_GETCURSEL, 0, 0 ) + 1

   IF Hwg_BitAnd( ::Style, TCS_BUTTONS ) != 0
      nPage := hwg_Sendmessage( ::handle, TCM_GETCURFOCUS, 0, 0 ) + 1
   ENDIF
   IF nPage = 0 .OR. ::handle != hwg_Getfocus()
      IF nCode == TCN_SELCHANGE .AND. ::handle != hwg_Getfocus() .AND. ::lClick
         hwg_Sendmessage( ::handle, TCM_SETCURSEL, hwg_Sendmessage( ::handle, ::nPrevPage - 1, 0, 0 ), 0 )
         RETURN 0
      ELSEIF nCode == TCN_SELCHANGE .AND. ! ::lClick
         hwg_Sendmessage( ::handle, TCM_SETCURSEL, ::nActive  - 1, 0  )
      ENDIF
      ::nPrevPage := nPage
      RETURN 0
   ENDIF

   DO CASE
   CASE nCode == TCN_CLICK
      ::lClick := .T.
   CASE nCode == TCN_KEYDOWN   // -500
      IF ( nPage := SetTabFocus( Self, nPage, nKeyDown ) ) != nPage
         ::nActive := nPage
      ENDIF
   CASE nCode == TCN_FOCUSCHANGE  //-554
   CASE nCode == TCN_SELCHANGE
      // ACTIVATE NEW PAGE
      IF ! ::pages[nPage]:enabled
         ::lClick := .F.
         ::nPrevPage := nPage
         RETURN 0
      ENDIF
      IF nPage = ::nPrevPage
         RETURN 0
      ENDIF
      ::oparent:lSuspendMsgsHandling := .T.
      Eval( ::bChange, hwg_Getcurrenttab( ::handle ), Self )
      IF ::bGetFocus != NIL .AND. nPage != ::nPrevPage .AND. ::Pages[ nPage ]:Enabled .AND. ::nActivate > 0
         Eval( ::bGetFocus, hwg_Getcurrenttab( ::handle ), Self )
         ::nActivate := 0
      ENDIF
      ::oparent:lSuspendMsgsHandling := .F.
   CASE nCode == TCN_SELCHANGING .AND. ::nPrevPage > 0
      // DEACTIVATE PAGE //ocorre antes de trocar o focu
      ::nPrevPage := ::nActive //npage
      IF ::bLostFocus != NIL
         ::oparent:lSuspendMsgsHandling := .T.
         Eval( ::bLostFocus, ::nPrevPage, Self )
         ::oparent:lSuspendMsgsHandling := .F.
      ENDIF
   CASE nCode == TCN_SELCHANGING   //-552
      ::nPrevPage := nPage
      RETURN 0
   CASE nCode == TCN_RCLICK
      IF ! Empty( ::pages ) .AND. ::nActive > 0 .AND. ::pages[ ::nActive ]:enabled
         IF ::bRClick != NIL
            ::oparent:lSuspendMsgsHandling := .T.
            Eval( ::bRClick, Self, hwg_Getcurrenttab( ::handle ) )
            ::oparent:lSuspendMsgsHandling := .F.
         ENDIF
      ENDIF
   CASE nCode == TCN_SETFOCUS
      IF ::bGetFocus != NIL .AND. ! ::Pages[ nPage ]:Enabled
         Eval( ::bGetFocus, hwg_Getcurrenttab( ::handle ), Self )
      ENDIF
   CASE nCode == TCN_KILLFOCUS
      IF ::bLostFocus != NIL
         Eval( ::bLostFocus, hwg_Getcurrenttab( ::handle ), Self )
      ENDIF
   ENDCASE
   IF ( nCode == TCN_CLICK .AND. ::nPrevPage > 0 .AND. ::pages[ ::nPrevPage ]:enabled ) .OR. ;
         ( ::lClick .AND. nCode == TCN_SELCHANGE )
      ::oparent:lSuspendMsgsHandling := .T.
      IF ::bAction != NIL  .AND. ::lClick
         Eval( ::bAction, Self, hwg_Getcurrenttab( ::handle ) )
      ENDIF
      ::oparent:lSuspendMsgsHandling := .F.
      ::lClick := .F.
   ENDIF

   RETURN - 1

METHOD OnEvent( msg, wParam, lParam ) CLASS HTab
   LOCAL oCtrl

   IF ( msg >= TCM_FIRST .AND. msg < TCM_FIRST + 61 )  // optimized only
      RETURN - 1
   ENDIF
   IF msg = WM_LBUTTONDOWN
      ::lClick := .F.
      IF ::ShowDisablePage( lParam, WM_LBUTTONDOWN  ) = 0
         ::nPrevPage := - 1
         RETURN 0
      ENDIF
      //::lClick := .T.
      IF ! hwg_Selffocus( ::Handle )
         ::Setfocus( 0 )
      ENDIF
      RETURN - 1
   ELSEIF msg = WM_LBUTTONUP
      IF hwg_Selffocus( ::Handle )
         ::nPrevPage := iif( ::nPrevPage = 0, ::nActive, ::nPrevPage )
         ::lClick := ::nPrevPage != - 1
      ENDIF
   ELSEIF  msg = WM_MOUSEMOVE //.OR. ( ::nPaintHeight = 0 .AND. msg = WM_NCHITTEST  )
      ::ShowToolTips( lParam )
      RETURN ::ShowDisablePage( lParam )
   ELSEIF msg = WM_PAINT
      RETURN - 1
   ELSEIF msg =  WM_ERASEBKGND
      ::ShowDisablePage()
      RETURN - 1
   ELSEIF  msg = WM_PRINTCLIENT .OR. msg = WM_NCHITTEST  .OR. msg = WM_UPDATEUISTATE
      RETURN - 1  // painted objects without METHOD PAINT
   ELSEIF  msg = WM_PRINT
      ::SetPaintSizePos(  iif( ::nPaintHeight > 1, - 1, 1 ) )
      IF ::nActive > 0
         ::ShowPage( ::nActive )
         IF hwg_Sendmessage( ::handle, TCM_GETROWCOUNT, 0 , 0 ) > 1
            hwg_Invalidaterect( ::Handle, 0, 1, ::Pages[ 1 ]:aItemPos[ 2 ], ::nWidth - 1,  ::Pages[ 1 ]:aItemPos[ 4 ] * hwg_Sendmessage( ::handle,TCM_GETROWCOUNT, 0 ,0 )  )
         ENDIF
      ENDIF
   ELSEIF msg = WM_SIZE
      AEval( ::Pages, { | p, i |  p:aItemPos := hwg_Tabitempos( ::Handle, i - 1 ) } )
      ::oPaint:nHeight := ::nPaintHeight
      ::oPaint:Anchor := iif( ::nPaintHeight > 1, 15, 0 )
      IF ::nPaintHeight > 1
         hwg_Postmessage( ::handle, WM_PRINT, hwg_Getdc( ::handle ), PRF_CHECKVISIBLE )
      ENDIF
   ELSEIF  msg = WM_SETFONT .AND. ::oFont != NIL .AND. ::lInit
      hwg_Sendmessage( ::handle,    WM_PRINT, hwg_Getdc( ::handle ) , PRF_CHECKVISIBLE )
   ELSEIF msg == WM_KEYDOWN .AND. hwg_Getfocus() = ::handle
      IF hwg_ProcKeyList( Self, wParam )
         RETURN - 1
      ELSEIF wParam = VK_ESCAPE
         RETURN 0
      ENDIF
      IF wParam = VK_RIGHT .OR. wParam = VK_LEFT
         IF SetTabFocus( Self, ::nActive, wParam )  = ::nActive
            RETURN 0
         ENDIF
      ELSEIF ( wparam == VK_DOWN .OR. wparam == VK_RETURN ) .AND. ::nActive > 0  //
         hwg_GetSkip( Self, ::handle, , 1 )
         RETURN 0
      ELSEIF wParam = VK_TAB
         hwg_GetSkip( ::oParent, ::handle, , iif( hwg_IsCtrlShift( .F. , .T. ), - 1, 1 ) )
         RETURN 0
      ELSEIF wparam == VK_UP .AND. ::nActive > 0  //
         hwg_GetSkip( ::oParent, ::handle, , - 1 )
         RETURN 0
      ENDIF
   ELSEIF msg == WM_HSCROLL .OR. msg == WM_VSCROLL
      IF hwg_Getfocus() = ::Handle
         hwg_Invalidaterect( ::oPaint:handle, 1, 0, 0 , ::nwidth, 30 )
      ENDIF
      IF hwg_GetParentForm( self ):Type < WND_DLG_RESOURCE
         RETURN ( ::oParent:onEvent( msg, wparam, lparam ) )
      ELSE
         RETURN ( ::super:onevent( msg, wparam, lparam ) )
      ENDIF
   ELSEIF msg = WM_GETDLGCODE
      IF wparam == VK_RETURN .OR. wParam = VK_ESCAPE  .AND. ;
            ( ( oCtrl := hwg_GetParentForm(Self ):FindControl( IDCANCEL ) ) != NIL .AND. ! oCtrl:IsEnabled() )
         RETURN DLGC_WANTMESSAGE
      ENDIF
   ENDIF
   IF msg = WM_NOTIFY .AND. hwg_Iswindowvisible( ::oParent:handle ) .AND.  ::nActivate = NIL
      IF ::bGetFocus != NIL
         ::oParent:lSuspendMsgsHandling := .T.
         Eval( ::bGetFocus, Self, hwg_Getcurrenttab( ::handle ) )
         ::oParent:lSuspendMsgsHandling := .F.
      ENDIF
   ELSEIF ( hwg_Iswindowvisible( ::handle ) .AND. ::nActivate = NIL ) .OR. msg == WM_KILLFOCUS
      ::nActivate := hwg_Getfocus()
   ENDIF

   IF ::bOther != NIL
      ::oparent:lSuspendMsgsHandling := .T.
      IF Eval( ::bOther, Self, msg, wParam, lParam ) != - 1
         // RETURN 0
      ENDIF
      ::oparent:lSuspendMsgsHandling := .F.
   ENDIF
   IF ! ( ( msg = WM_COMMAND .OR. msg = WM_NOTIFY ) .AND. ::oParent:lSuspendMsgsHandling .AND. ::lSuspendMsgsHandling )
      IF msg = WM_NCPAINT .AND. hwg_GetParentForm( Self ):nInitFocus > 0  .AND. hwg_Ptrtoulong( hwg_Getparent( hwg_GetParentForm(Self ):nInitFocus ) ) = hwg_Ptrtoulong( ::Handle )
         hwg_GetSkip( ::oParent, hwg_GetParentForm( Self ):nInitFocus , , 0 )
         hwg_GetParentForm( Self ):nInitFocus := 0
      ENDIF
      IF msg == WM_KILLFOCUS .AND. hwg_GetParentForm( Self ) != NIL  .AND. hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE
         hwg_Sendmessage( ::oParent:handle, WM_COMMAND, hwg_Makewparam( ::id, 0 ), ::handle )
         ::nPrevPage := 0
      ENDIF
      IF msg = WM_DRAWITEM
         ::ShowDisablePage()
      ENDIF
      RETURN ::Super:onEvent( msg, wparam, lparam )
   ENDIF

   RETURN - 1

METHOD ShowDisablePage( nPageEnable, nEvent ) CLASS HTab
   LOCAL client_rect, i, pt := { , }

   DEFAULT nPageEnable := 0
   IF ! hwg_Iswindowvisible( ::handle ) .OR. ( Ascan( ::Pages, { | p | ! p:lEnabled } ) = 0  .AND. nPageEnable = NIL )
      RETURN - 1
   ENDIF
   nPageEnable := iif( nPageEnable = NIL, 0, nPageEnable )
   nEvent := iif( nEvent = NIL, 0 , nEvent )
   IF hwg_Ptrtoulong( nPageEnable ) > 128
      pt[ 1 ] = hwg_Loword( nPageEnable )
      pt[ 2 ] = hwg_Hiword( nPageEnable )
   ENDIF
   FOR i = 1 TO Len( ::Pages )
      IF ! ::pages[ i ]:enabled .OR. i = hwg_Ptrtoulong( nPageEnable )
         client_rect := hwg_Tabitempos( ::Handle, i - 1 )
         IF ( hwg_Ptinrect( client_rect, pt ) ) .AND. i != nPageEnable
            RETURN 0
         ENDIF
         ::oPaint:ShowTextTabs(  ::pages[ i ] , client_rect )
      ENDIF
   NEXT

   RETURN - 1

METHOD ShowToolTips( lParam ) CLASS HTab
   LOCAL i, pt := { , }, client_rect

   IF Ascan( ::Pages, { | p | p:ToolTip != NIL } ) = 0
      RETURN NIL
   ENDIF
   pt[ 1 ] := hwg_Loword( lParam )
   pt[ 2 ] := hwg_Hiword( lParam )

   FOR i := 1 TO Len( ::Pages )
      client_rect :=  ::Pages[ i ]:aItemPos
      IF ( hwg_Ptinrect( client_rect, pt ) )
         ::SetToolTip( iif( ::Pages[ i ]:Tooltip = NIL, "", ::Pages[ i ]:Tooltip ) )
         EXIT
      ENDIF
   NEXT

   RETURN NIL

STATIC FUNCTION SetTabFocus( oCtrl, nPage, nKeyDown )
   LOCAL i, nSkip, nStart, nEnd, nPageAcel

   IF nKeyDown = VK_LEFT .OR. nKeyDown = VK_RIGHT  // 37,39
      nEnd := iif( nKeyDown = VK_LEFT, 1, Len( oCtrl:aPages ) )
      nSkip := iif( nKeyDown = VK_LEFT, - 1, 1 )
      nStart :=  nPage + nSkip
      FOR i = nStart TO nEnd STEP nSkip
         IF oCtrl:pages[ i ]:enabled
            IF ( nSkip > 0 .AND. i > nStart ) .OR. ( nSkip < 0 .AND. i < nStart )
               hwg_Sendmessage( oCtrl:handle, TCM_SETCURFOCUS, i - nSkip - 1, 0 ) // BOTOES
            ENDIF
            RETURN i
         ELSEIF i = nEnd
            IF oCtrl:pages[ i - nSkip ]:enabled
               hwg_Sendmessage( oCtrl:handle, TCM_SETCURFOCUS, i - ( nSkip * 2 ) - 1 , 0 ) // BOTOES
               RETURN ( i - nSkip )
            ENDIF
            RETURN nPage
         ENDIF
      NEXT
   ELSE
      nPageAcel := hwg_FindTabAccelerator( oCtrl, nKeyDown )
      IF nPageAcel = 0
         hwg_Msgbeep()
      ENDIF
   ENDIF

   RETURN nPage

FUNCTION hwg_FindTabAccelerator( oPage, nKey )

   LOCAL  i , pos , cKey

   cKey := Upper( Chr( nKey ) )
   FOR i = 1 TO Len( oPage:aPages )
      IF ( pos := At( "&", oPage:Pages[ i ]:caption ) ) > 0 .AND.  cKey  ==  Upper( SubStr( oPage:Pages[ i ]:caption , ++ pos, 1 ) )
         IF oPage:pages[ i ]:Enabled
            hwg_Sendmessage( oPage:handle, TCM_SETCURFOCUS, i - 1, 0 )
         ENDIF
         RETURN  i
      ENDIF
   NEXT

   RETURN 0

/* ------------------------------------------------------------------
 new class to PAINT Pages
------------------------------------------------------------------ */

CLASS HPaintTab INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"
   DATA hDC

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, tColor, bColor )
   METHOD Activate()
   METHOD Paint( lpDis )
   METHOD showTextTabs( oPage, aItemPos )
   METHOD Refresh() VIRTUAL

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, tcolor, bColor ) CLASS HPaintTab

   ::bPaint   := { | o, p | o:paint( p ) }
   ::Super:New( oWndParent, nId, SS_OWNERDRAW + WS_DISABLED + WS_CLIPCHILDREN , nLeft, nTop, nWidth, nHeight, , ;
      , , ::bPaint, , tcolor, bColor )
   ::anchor := 15
   ::brush := NIL
   ::Name := "PaintTab"

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HPaintTab

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createstatic( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
   ENDIF

   RETURN NIL

METHOD Paint( lpdis ) CLASS HPaintTab
   LOCAL drawInfo := hwg_Getdrawiteminfo( lpdis )
   LOCAL hDC := drawInfo[ 3 ]
   LOCAL x1 := drawInfo[ 4 ], y1 := drawInfo[ 5 ]
   LOCAL x2 := drawInfo[ 6 ], y2 := drawInfo[ 7 ]
   LOCAL i, client_rect
   LOCAL nPage := hwg_Sendmessage( ::oParent:handle, TCM_GETCURFOCUS, 0, 0 ) + 1
   LOCAL oPage := iif( nPage > 0, ::oParent:Pages[ nPage ], ::oParent:Pages[ 1 ] )

   ::disablebrush := oPage:brush
   IF oPage:brush != NIL
      IF ::oParent:nPaintHeight < ::oParent:TabHeightSize //40
         ::nHeight := 1
         ::move( , , , ::nHeight )
      ELSEIF oPage:brush != NIL
         hwg_Fillrect( hDC, x1 + 1, y1 + 2, x2 - 1, y2 - 0, oPage:brush:Handle ) //obrush )
         ::oParent:RedrawControls( )
      ENDIF
   ENDIF

   ::hDC := hwg_Getdc( ::oParent:handle )
   FOR i = 1 TO Len( ::oParent:Pages )
      oPage := ::oParent:Pages[ i ]
      client_rect :=  hwg_Tabitempos( ::oParent:Handle, i - 1 )
      oPage:aItemPos := client_rect
      IF oPage:brush != NIL
         IF nPage = oPage:PageOrder
            hwg_Fillrect( ::hDC, client_rect[ 1 ], client_rect[ 2 ] + 1, client_rect[ 3 ] , client_rect[ 4 ] + 2 , oPage:brush:handle )
            IF hwg_Getfocus() = oPage:oParent:handle
               hwg_Inflaterect( @client_rect, - 2, - 2 )
               hwg_Drawfocusrect( ::hDC, client_rect )
            ENDIF
         ELSE
            hwg_Fillrect( ::hDC, client_rect[ 1 ] + iif( i = nPage + 1, 2, 1 ), ;
               client_rect[ 2 ] + 1, ;
               client_rect[ 3 ] - iif( i = nPage - 1 , 3, 2 ) - iif( i = Len( ::oParent:Pages ), 1, 0 ), ;
               client_rect[ 4 ] - 1, oPage:brush:Handle )
         ENDIF
      ENDIF
      IF oPage:brush != NIL .OR. oPage:tColor != NIL .OR. ! oPage:lenabled
         ::showTextTabs( oPage , client_rect )
      ENDIF
   NEXT

   RETURN 0

METHOD showTextTabs( oPage, aItemPos ) CLASS HPaintTab
   LOCAL nStyle, BmpSize := 0, size := 0, aTxtSize, aItemRect
   LOCAL nActive := oPage:oParent:GetActivePage(), hTheme

   AEval( oPage:oParent:Pages, { | p | size += p:aItemPos[ 3 ] - p:aItemPos[ 1 ] } )
   nStyle := SS_CENTER + DT_VCENTER + DT_SINGLELINE + DT_END_ELLIPSIS
   ::hDC := iif( ::hDC = NIL, hwg_Getdc( ::oParent:handle ), ::hDC )
   IF ( hwg_Isthemedload() )
      hTheme := NIL
      IF ::WindowsManifest
         hTheme := hwg_openthemedata( ::oParent:handle, "TAB" )
      ENDIF
      hTheme := iif( Empty( hTheme  ), NIL, hTheme )
   ENDIF
   hwg_Setbkmode( ::hDC, TRANSPARENT )
   IF oPage:oParent:oFont != NIL
      hwg_Selectobject( ::hDC, oPage:oParent:oFont:handle )
   ENDIF
   IF oPage:lEnabled
      hwg_Settextcolor( ::hDC, iif( Empty( oPage:tColor ), hwg_Getsyscolor( COLOR_WINDOWTEXT ), oPage:tColor ) )
   ELSE
      hwg_Settextcolor( ::hDC, hwg_Getsyscolor( COLOR_BTNHIGHLIGHT ) )
   ENDIF
   aTxtSize := hwg_TxtRect( oPage:caption, oPage:oParent )
   IF oPage:oParent:himl != NIL
      BmpSize := ( ( aItemPos[ 3 ] - aItemPos[ 1 ] ) - ( oPage:oParent:aBmpSize[ 1 ] + aTxtSize[1] ) ) / 2
      BmpSize += oPage:oParent:aBmpSize[ 1 ]
      BmpSize := Max( BmpSize, oPage:oParent:aBmpSize[ 1 ] )
   ENDIF
   aItemPos[ 3 ] := iif( size > oPage:oParent:nWidth .AND. aItemPos[ 1 ] + BmpSize + aTxtSize[ 1 ] > oPage:oParent:nWidth - 44, oPage:oParent:nWidth - 44, aItemPos[ 3 ] )
   aItemRect := { aItemPos[ 1 ] + iif( oPage:PageOrder = nActive + 1, 1, 0 ), aItemPos[ 2 ]  , aItemPos[ 3 ] - iif( oPage:PageOrder = Len( oPage:oParent:Pages ), 2, iif( oPage:PageOrder = nActive - 1, 1, 0 ) ) , aItemPos[ 4 ] - 1   }
   IF Hwg_BitAnd( oPage:oParent:Style, TCS_BOTTOM  ) = 0
      IF hTheme != NIL .AND. oPage:brush = NIL
         hwg_drawthemebackground( hTheme, ::hDC, BP_PUSHBUTTON, 0, aItemRect, NIL )
      ELSE
         hwg_Fillrect( ::hDC,  aItemPos[ 1 ] + BmpSize + 3, aItemPos[ 2 ] + 4, aItemPos[ 3 ] - 3, aItemPos[ 4 ] - 5, ;
            iif( oPage:brush != NIL, oPage:brush:Handle, hwg_Getstockobject( NULL_BRUSH ) ) )
      ENDIF
      IF nActive = oPage:PageOrder                       // 4
         hwg_Drawtext( ::hDC, oPage:caption, aItemPos[ 1 ] + BmpSize - 1 , aItemPos[ 2 ] - 1, aItemPos[ 3 ]   , aItemPos[ 4 ] - 1 , nstyle )
      ELSE
         IF oPage:lEnabled = .F.
            hwg_Drawtext( ::hDC, oPage:caption, aItemPos[ 1 ] + BmpSize - 1, aItemPos[ 2 ] + 1, aItemPos[ 3 ] + 1 , aItemPos[ 4 ] + 1 , nstyle )
            hwg_Settextcolor( ::hDC, hwg_Getsyscolor( COLOR_GRAYTEXT ) )
         ENDIF
         hwg_Drawtext( ::hDC, oPage:caption, aItemPos[ 1 ] + BmpSize - 1, aItemPos[ 2 ] + 1, aItemPos[ 3 ] + 1 , aItemPos[ 4 ] + 1 , nstyle )
      ENDIF
   ELSE
      IF hTheme != NIL .AND. oPage:brush = NIL
         hwg_drawthemebackground( hTheme, ::hDC, BP_PUSHBUTTON, 0, aItemRect, NIL )
      ELSE
         hwg_Fillrect( ::hDC,  aItemPos[ 1 ] + 3, aItemPos[ 2 ] + 3, aItemPos[ 3 ] - 4, aItemPos[ 4 ] - 5, iif( oPage:brush != NIL, oPage:brush:Handle, hwg_Getstockobject( NULL_BRUSH ) ) ) // oPage:oParent:brush:Handle ) )
      ENDIF
      IF nActive = oPage:PageOrder                       // 4
         hwg_Drawtext( ::hDC, oPage:caption, aItemPos[ 1 ] , aItemPos[ 2 ] + 2, aItemPos[ 3 ] , aItemPos[ 4 ] + 2 , nstyle )
      ELSE
         IF oPage:lEnabled = .F.
            hwg_Drawtext( ::hDC, oPage:caption, aItemPos[ 1 ] + 1, aItemPos[ 2 ] + 1 , aItemPos[ 3 ] + 1  , aItemPos[ 4 ] + 1 , nstyle )
            hwg_Settextcolor( ::hDC, hwg_Getsyscolor( COLOR_GRAYTEXT ) )
         ENDIF
         hwg_Drawtext( ::hDC, oPage:caption, aItemPos[ 1 ] , aItemPos[ 2 ] , aItemPos[ 3 ] , aItemPos[ 4 ]  , nstyle )
      ENDIF
   ENDIF
   IF oPage:lEnabled .AND. oPage:brush = NIL
      hwg_Invalidaterect( ::oParent:handle, 0, aItemPos[ 1 ] , aItemPos[ 2 ] , aItemPos[ 1 ] + aItemPos[ 3 ] , aItemPos[ 2 ] + aItemPos[ 4 ] )
   ENDIF

   RETURN NIL

