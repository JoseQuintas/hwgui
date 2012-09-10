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
/*
#define TCM_SETCURSEL           4876     // (TCM_FIRST + 12)
#define TCM_SETCURFOCUS         4912     // (TCM_FIRST + 48)
#define TCM_GETCURFOCUS         4911     // (TCM_FIRST + 47)
#define TCM_GETITEMCOUNT        4868     // (TCM_FIRST + 4)

#define TCM_SETIMAGELIST        4867
*/
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
   METHOD GetTabText() INLINE GetTabName( ::oParent:Handle, ::PageOrder - 1 )
   METHOD SetTabText( cText )
   METHOD Refresh() INLINE ::oParent:ShowPage( ::PageOrder )
   METHOD Enabled( lEnabled ) SETGET
   METHOD SetColor( tcolor, bcolor )

ENDCLASS

//----------------------------------------------------//
METHOD New( cCaption, nPage, lEnabled, tcolor, bcolor, cTooltip ) CLASS HPage

   cCaption := IIf( cCaption == nil, "New Page", cCaption )
   ::lEnabled := IIF( lEnabled != Nil, lEnabled, .T. )
   ::Pageorder := nPage
   ::Tooltip := cTooltip
   ::SetColor( tColor, bColor )

   RETURN Self

METHOD SetColor( tcolor, bColor ) CLASS HPage

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
   IF ::oParent = Nil .OR. ( bColor = Nil .AND. tcolor = NIL )
      RETURN Nil
   ENDIF
   ::oParent:SetPaintSizePos( IIF( bColor = Nil, 1, - 1 ) )

   RETURN NIL

METHOD SetTabText( cText ) CLASS HPage

   IF Len( ::aItemPos ) = 0
      RETURN Nil
   ENDIF

   SetTabName( ::oParent:Handle, ::PageOrder - 1, cText )
   ::xCaption := cText
   InvalidateRect( ::oParent:handle, 0, ::aItemPos[ 1 ], ::aItemPos[ 2 ], ::aItemPos[ 1 ] + ::aItemPos[ 3 ], ::aItemPos[ 2 ] + ::aItemPos[ 4 ] )
   InvalidateRect( ::oParent:Handle, 0 )
   /*
   FOR i =  1 TO Len( ::oParent:Pages )
      ::oParent:Pages[ i ]:aItemPos := TabItemPos( ::oParent:Handle, i - 1 )
   NEXT
   */
   RETURN Nil


METHOD Enabled( lEnabled ) CLASS HPage
  LOCAL nActive

  IF lEnabled != Nil .AND. ::lEnabled != lEnabled
     ::lEnabled := lEnabled
     IF lEnabled .AND. ( ::PageOrder != ::oParent:nActive .OR. ! IsWindowEnabled( ::oParent:Handle ) )
        IF ! IsWindowEnabled( ::oParent:Handle )
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
     IF Ascan( ::oParent:Pages, {| p | p:lEnabled } ) = 0
        ::oParent:Disable()
        SendMessage( ::oParent:handle, TCM_SETCURSEL, - 1, 0 )
     ENDIF
  ENDIF
  RETURN ::lEnabled

 *------------------------------------------------------------------------------

CLASS HTab INHERIT HControl

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

   nStyle   := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), WS_CHILD + WS_CLIPSIBLINGS + WS_TABSTOP + TCS_TOOLTIPS )

   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize, bPaint )

   ::title   := ""
   ::oFont   := IIf( oFont == Nil, ::oParent:oFont, oFont )
   ::aTabs   := IIf( aTabs == Nil, { }, aTabs )
   ::bChange := bChange
   ::bChange2 := bChange

   ::bGetFocus :=  bGetFocus
   ::bLostFocus :=  bLostFocus
   ::bAction   := bClick
   ::bRClick   := bRClick

   IF aImages != Nil
      ::aImages := { }
      FOR i := 1 TO Len( aImages )
         //AAdd( ::aImages, Upper( aImages[ i ] ) )
         aImages[ i ] := IIf( lResour, LoadBitmap( aImages[ i ] ), OpenBitmap( aImages[ i ] ) )
         AAdd( ::aImages, aImages[ i ] )
      NEXT
      ::aBmpSize := GetBitmapSize( aImages[ 1 ] )
      ::himl := CreateImageList( aImages, ::aBmpSize[ 1 ], ::aBmpSize[ 2 ], 12, nBC )
      ::Image1 := 0
      IF Len( aImages ) > 1
         ::Image2 := 1
      ENDIF
   ENDIF
   ::oPaint := HPaintTab():New( Self, , 0, 0, 0, 0 ) //, ::oFont )
//   ::brush := GetBackColorParent( Self, .T. )
    HWG_InitCommonControlsEx()
   ::Activate()


   RETURN Self

METHOD Activate() CLASS HTab
   IF ! Empty( ::oParent:handle )
      ::handle := CreateTabControl( ::oParent:handle, ::id, ;
                                    ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
   RETURN Nil

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

   ::brush := GetBackColorParent( Self, .T. )
   ::oPaint := HPaintTab():New( Self, , 0, 0, 0, 0 ) //, ::oFont )

   RETURN Self


METHOD Init() CLASS HTab
   LOCAL i, x := 0

   IF ! ::lInit
      InitTabControl( ::handle, ::aTabs, IIF( ::himl != Nil, ::himl, 0 ) )
      SendMessage( ::HANDLE, TCM_SETMINTABWIDTH ,0 ,0 )
      IF  Hwg_BitAnd( ::Style, TCS_FIXEDWIDTH  ) != 0
         ::TabHeightSize := 25 - ( ::oFont:Height + 12 )
         x := ::nWidth / Len( ::aPages ) - 2
      ELSEIF ::TabHeightSize != Nil
      ELSEIF ::oFont != Nil
         ::TabHeightSize := 25 - ( ::oFont:Height + 12 )
      ELSE
         ::TabHeightSize := 23
      ENDIF
      SendMessage( ::Handle, TCM_SETITEMSIZE, 0, MAKELPARAM( x, ::TabHeightSize ) )
      IF ::himl != Nil
         SendMessage( ::handle, TCM_SETIMAGELIST, 0, ::himl )
      ENDIF
      AddToolTip( ::GetParentForm():handle, ::handle, "" )
      Super:Init()

      IF Len( ::aPages ) > 0
         //::Pages[ 1 ]:aItemPos := TabItemPos( ::Handle, 0 )
         /*
         IF ASCAN( ::Pages, { | p | p:brush != Nil } ) > 0
            ::SetPaintSizePos( - 1 )
         ELSEIF ASCAN( ::Pages, { | p | p:tcolor != Nil } ) > 0
            ::SetPaintSizePos( 1 )
         ELSE
            ::oPaint:nHeight := ::TabHeightSize
         ENDIF
         */
         ::SetPaintSizePos( IIF( ASCAN( ::Pages, { | p | p:brush != Nil } ) > 0 , - 1, 1 ) )
         ::nActive := 0
         FOR i := 1 TO Len( ::aPages )
            ::Pages[ i ]:aItemPos := TabItemPos( ::Handle, i - 1 )
            ::HidePage( i )
            ::nActive := IIF( ::nActive = 0 .AND. ::Pages[ i ]:Enabled, i, ::nActive )
         NEXT
         SendMessage( ::handle, TCM_SETCURFOCUS, ::nActive - 1, 0 )
         IF ::nActive = 0
            ::Disable()
            ::ShowPage( 1 )
         ELSE
            ::ShowPage( ::nActive )
         ENDIF
      ELSE
         Asize( ::aPages, SendMessage( ::handle, TCM_GETITEMCOUNT, 0, 0 ) )
         AEval( ::aPages, { | a , i | HB_SYMBOL_UNUSED(a), ::AddPage( HPage():New( "" ,i,.t.,), "" )})
      ENDIF
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      Hwg_InitTabProc( ::handle )

   ENDIF

   RETURN Nil

METHOD SetPaintSizePos( nFlag ) CLASS HTab
   Local aItemPos

   ::Pages[ ::nActive ]:aItemPos := TabItemPos( ::Handle, ::nActive - 1 ) //0 )
   aItemPos := ::Pages[ ::nActive ]:aItemPos
   IF nFlag = - 1
      ::oPaint:nLeft :=   1
      ::oPaint:nWidth := ::nWidth - 3
      IF Hwg_BitAnd( ::Style,TCS_BOTTOM  ) != 0
         ::oPaint:nTop :=   1
         ::oPaint:nHeight := aItemPos[ 2 ] - 3
      ELSE
         ::oPaint:nTop := aItemPos[ 4 ]
         ::oPaint:nHeight := ::nHeight - aItemPos[ 4 ] - 3
      ENDIF
      ::nPaintHeight  := ::oPaint:nHeight
   ELSEIF nFlag = - 2
      SetWindowPos( ::oPaint:Handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE+ SWP_NOREDRAW + SWP_NOACTIVATE +SWP_NOSENDCHANGING)
      RETURN Nil
   ELSEIF nFlag > 0
      ::npaintheight  := nFlag
      ::oPaint:nHeight := nFlag
      IF ! IsWindowEnabled( ::Handle ) 
         RETURN Nil
      ENDIF
   ENDIF
   SetWindowPos( ::oPaint:Handle, Nil, ::oPaint:nLeft, ::oPaint:nTop, ::oPaint:nWidth, ::oPaint:nHeight, SWP_NOACTIVATE  ) //+ SWP_SHOWWINDOW  )
   RETURN Nil

METHOD SetTab( n ) CLASS HTab
   IF n > 0 .AND. n <= LEN( ::aPages )
      IF  ::Pages[ n ]:Enabled
         ::changePage( n )
         SendMessage( ::handle, TCM_SETCURFOCUS, n - 1, 0 )
      ENDIF
   ENDIF
   RETURN Nil

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
   ::Pages[ ::nActive ]:aItemPos := { 0, 0, 0, 0 } //TabItemPos( ::Handle, ::nActive - 1 )

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
   LOCAL i, cName, cPage := "Page" + ALLTRIM( STR( ::nActive ) )
   IF ! ::lResourceTab
      ::aPages[ ::nActive, 2 ] := Len( ::aControls ) - ::aPages[ ::nActive, 1 ]
      IF ::handle != Nil .AND. ! Empty( ::handle )
         AddTab( ::handle, ::nActive, ::aTabs[ ::nActive ] )
      ENDIF
      IF ::nActive > 1 .AND. ::handle != Nil .AND. ! Empty( ::handle )
         ::HidePage( ::nActive )
      ENDIF
      // add news objects how property in tab
      FOR i = ::aPages[ ::nActive,1 ] + 1 TO ::aPages[ ::nActive,1 ] + ::aPages[ ::nActive,2 ]
         cName := ::aControls[ i ]:name
         IF !EMPTY( cName ) .AND. VALTYPE( cName) == "C" .AND. ! ":" $ cName .AND.;
                                 ! "->"$ cName .AND. ! "[" $ cName
             __objAddData( ::&cPage, cName )
               ::&cPage:&(::aControls[ i ]:name) := ::aControls[ i ]
           ENDIF
      NEXT
      ::nActive := 1

      ::oDefaultParent := ::oTemp
      ::oTemp := Nil

      ::bChange = { | o, n | o:ChangePage( n ) }


   ELSE
      IF ::handle != Nil .AND. ! Empty( ::handle )

         AddTabDialog( ::handle, ::nActive, ::aTabs[ ::nActive ], ::aPages[ ::nactive, 1 ]:handle )
      ENDIF
      IF ::nActive > 1 .AND. ::handle != Nil .AND. ! Empty( ::handle )
         ::HidePage( ::nActive )
      ENDIF
      ::nActive := 1

      ::oDefaultParent := ::oTemp
      ::oTemp := Nil

      ::bChange = { | o, n | o:ChangePage( n ) }
   ENDIF

   RETURN Nil

METHOD ChangePage( nPage ) CLASS HTab
   //LOCAL client_rect

   IF nPage = ::nActive  &&.OR. ! ::pages[ nPage ]:enabled
      //SetTabFocus( Self, nPage, .F. )
      RETURN Nil
   ENDIF
   IF ! Empty( ::aPages ) .AND. ::pages[ nPage ]:enabled
      *-client_rect := TabItemPos( ::Handle, ::nActive - 1 )
      IF ::nActive > 0
         ::HidePage( ::nActive )
         IF ::Pages[ nPage ]:brush != Nil
            ::SetPaintSizePos(  - 1 )
            RedrawWindow( ::oPaint:Handle, RDW_INVALIDATE  + RDW_INTERNALPAINT  )
         ENDIF
      ENDIF
      ::nActive := nPage
      IF ::bChange2 != Nil
        ::onChange( )
      ENDIF
      ::ShowPage( nPage )

      IF ::oPaint:nHeight  > ::TabHeightSize + 1
         *- InvalidateRect( ::handle, 1, client_rect[ 1 ], client_rect[ 2 ] , client_rect[ 3 ] + 3, client_rect[ 4 ] + 0 )
      ENDIF
   ENDIF

   RETURN Nil

METHOD onChange( ) CLASS HTab

   IF ::bChange2 != Nil
      ::oparent:lSuspendMsgsHandling := .t.
      Eval( ::bChange2, ::nActive, Self )
      ::oparent:lSuspendMsgsHandling := .f. //lSuspendMsgsHandling
   ENDIF
   RETURN Nil

METHOD HidePage( nPage ) CLASS HTab
   LOCAL i, nFirst, nEnd, k
   IF ! ::lResourceTab
      nFirst := ::aPages[ nPage, 1 ] + 1
      nEnd   := ::aPages[ nPage, 1 ] + ::aPages[ nPage, 2 ]
      FOR i := nFirst TO nEnd
         IF ( k:= ASCAN( ::aControlsHide, ::aControls[ i ]:id  ) ) = 0 .AND. ::aControls[ i ]:lHide
            AADD( ::aControlsHide,  ::aControls[ i ]:id )
         ELSEIF k > 0 .AND. ! ::aControls[i]:lHide
            ADEL( ::aControlsHide, k )
            ASIZE( ::aControlsHide, Len( ::aControlsHide ) - 1 )
         ENDIF
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
      IF ::oPaint:nHeight > 1 .AND. ::Pages[ nPage ]:brush != Nil .AND.;
         ASCAN( ::aControls, { | o | o:winclass = ::winclass }, nFirst, nEnd - nFirst + 1 ) > 0
         ::SetPaintSizePos( - 2 )
      ENDIF
      FOR i := nFirst TO nEnd
         //IF  ASCAN( ::aControlsHide, ::aControls[ i ]:id ) = 0 .OR. ::aControls[i]:lHide = .F.
         IF ! ::aControls[i]:lHide .OR. ( LEN( ::aControlsHide ) = 0 .OR. ASCAN( ::aControlsHide, ::aControls[i]:id ) = 0 )
            ::aControls[ i ]:Show( SW_SHOWNA )
         ENDIF
      NEXT
      IF ::Pages[ nPage ]:brush = Nil .AND. ::oPaint:nHeight > 1
         ::SetPaintSizePos( 1 )
      ENDIF
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

      FOR i := 1  TO Len( ::aPages[ nPage, 1 ]:aControls )
         IF ( __ObjHasMsg( ::aPages[ nPage, 1 ]:aControls[ i ], "BSETGET" ) .AND. ::aPages[ nPage, 1 ]:aControls[ i ]:bSetGet != Nil ) .OR. Hwg_BitAnd( ::aPages[ nPage, 1 ]:aControls[ i ]:style, WS_TABSTOP ) != 0
            SetFocus( ::aPages[ nPage, 1 ]:aControls[ i ]:handle )
            EXIT
         ENDIF
      NEXT

   ENDIF

   RETURN Nil

METHOD Refresh( lAll ) CLASS HTab
   LOCAL i, nFirst, nEnd, lRefresh
   LOCAL hCtrl := GetFocus()

   IF ::nActive != 0
      IF ! ::lResourceTab
         lAll := IIF( lAll = Nil, .F., lAll )
         nFirst := ::aPages[ ::nActive, 1 ] + 1
         nEnd   := ::aPages[ ::nActive, 1 ] + ::aPages[ ::nActive, 2 ]
         FOR i := nFirst TO nEnd
            lRefresh :=  ! Empty( __ObjHasMethod( ::aControls[ i ], "REFRESH" ) ) .AND.  ;
                  ( __ObjHasMsg( ::aControls[ i ], "BSETGET" ) .OR. lAll ) .AND. ::aControls[ i ]:Handle != hCtrl
                IF  ! Empty( lRefresh )
               ::aControls[ i ]:Refresh( )
               IF ::aControls[ i ]:bRefresh != Nil
                  EVAL( ::aControls[ i ]:bRefresh, ::aControls[ i ] )
               ENDIF
            ENDIF
         NEXT
      ENDIF
   ELSE
      ::aPages[ ::nActive, 1 ]:Refresh()
   ENDIF
   RETURN Nil

METHOD RedrawControls() CLASS HTab
   LOCAL i

   IF ::nActive != 0
      IF ! ::lResourceTab
         ::oParent:lSuspendMsgsHandling := .T.
         FOR i := ::aPages[ ::nActive, 1 ] + 1 TO ::aPages[ ::nActive, 1 ] + ::aPages[ ::nActive, 2 ]
            IF isWindowVisible( ::aControls[ i ]:Handle ) //.AND. ::aControls[ i ]:bPaint = NIL
               RedrawWindow( ::aControls[ i ]:handle,  IIF( ::classname != ::aControls[ i ]:classname, ;
                               RDW_NOERASE + RDW_FRAME + RDW_INVALIDATE +RDW_NOINTERNALPAINT, RDW_NOERASE +RDW_INVALIDATE ) )
               /*
               IF ::aControls[ i ]:winclass = "EDIT" .AND. __ObjHasMsg( ::aControls[ i ], "hUpDown" )
                   InvalidateRect( ::aControls[ i ]:hUpDown, 0 )
                ENDIF
                */
            ENDIF
         NEXT
         ::oParent:lSuspendMsgsHandling := .F.
      ENDIF
   ENDIF
   RETURN Nil

METHOD GetActivePage( nFirst, nEnd ) CLASS HTab
   IF  ::nActive > 0
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
         nEnd   := Len( ::aPages[ ::nActive, 1 ]:aControls )
      ENDIF
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
   LOCAL nkeyDown := GetNotifyKeydown( lParam )
   LOCAL nPage := SendMessage( ::handle, TCM_GETCURSEL, 0, 0 ) + 1

   IF  Hwg_BitAnd( ::Style, TCS_BUTTONS ) != 0
      nPage := SendMessage( ::handle, TCM_GETCURFOCUS, 0, 0 ) + 1
   ENDIF
   IF nPage = 0 .OR. ::handle != GetFocus()
      IF nCode == TCN_SELCHANGE .AND. ::handle != GetFocus() .AND. ::lClick
         SendMessage( ::handle, TCM_SETCURSEL, SendMessage( ::handle, ::nPrevPage - 1, 0, 0 ), 0 )
         RETURN 0
      ELSEIF nCode == TCN_SELCHANGE
         SendMessage( ::handle, TCM_SETCURSEL, SendMessage( ::handle, TCM_GETCURFOCUS, 0, 0 ), 0 )
      ENDIF
      ::nPrevPage := nPage
      Return 0
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
           //::SetTab( ::nActive  )
                   ::lClick := .F.
                   ::nPrevPage := nPage
               RETURN 0
            ENDIF
            IF  nPage = ::nPrevPage
            RETURN 0
        ENDIF
              //IF GETFOCUS() != ::handle
            //   ::SETFOCUS()
            //ENDIF
        ::oparent:lSuspendMsgsHandling := .T.
        Eval( ::bChange, Self, GetCurrentTab( ::handle ) )
        IF ::bGetFocus != NIL .AND. nPage != ::nPrevPage .AND. ::Pages[ nPage ]:Enabled .AND. ::nActivate > 0
            Eval( ::bGetFocus, GetCurrentTab( ::handle ), Self )
            ::nActivate := 0
        ENDIF
        ::oparent:lSuspendMsgsHandling := .F.
   CASE nCode == TCN_SELCHANGING .AND. ::nPrevPage > 0
        // DEACTIVATE PAGE //ocorre antes de trocar o focu
        ::nPrevPage := ::nActive //npage
        IF ::bLostFocus != NIL
           ::oparent:lSuspendMsgsHandling := .T.
           Eval( ::bLostFocus, ::nPrevPage, Self)
           ::oparent:lSuspendMsgsHandling := .F.
        ENDIF
   CASE nCode == TCN_SELCHANGING   //-552
      ::nPrevPage := nPage
      RETURN 0
     /*
   CASE nCode == TCN_CLICK
      IF ! Empty( ::pages ) .AND. ::nActive > 0 .AND. ::pages[ ::nActive ]:enabled
         SetFocus( ::handle )
         IF ::bAction != Nil
            Eval( ::bAction, Self, GetCurrentTab( ::handle ) )
         ENDIF
      ENDIF
   */
   CASE nCode == TCN_RCLICK
      IF ! Empty( ::pages ) .AND. ::nActive > 0 .AND. ::pages[ ::nActive ]:enabled
          IF ::bRClick != Nil
              ::oparent:lSuspendMsgsHandling := .T.
              Eval( ::bRClick, Self, GetCurrentTab( ::handle ) )
              ::oparent:lSuspendMsgsHandling := .F.
          ENDIF
      ENDIF

   CASE nCode == TCN_SETFOCUS
      IF ::bGetFocus != NIL .AND. ! ::Pages[ nPage ]:Enabled
         Eval( ::bGetFocus, GetCurrentTab( ::handle ), Self )
      ENDIF
   CASE nCode == TCN_KILLFOCUS
      IF ::bLostFocus != NIL
         Eval( ::bLostFocus, GetCurrentTab( ::handle ), Self )
      ENDIF

   ENDCASE
   IF ( nCode == TCN_CLICK .AND. ::nPrevPage > 0 .AND. ::pages[ ::nPrevPage ]:enabled ) .OR.;
        ( ::lClick .AND. nCode == TCN_SELCHANGE )
       ::oparent:lSuspendMsgsHandling := .T.
       IF ::bAction != Nil  .AND. ::lClick
          Eval( ::bAction, Self, GetCurrentTab( ::handle ) )
       ENDIF
       ::oparent:lSuspendMsgsHandling := .F.
       ::lClick := .f.
   ENDIF
   RETURN - 1


METHOD OnEvent( msg, wParam, lParam ) CLASS HTab
   LOCAL oCtrl

   IF (msg >= TCM_FIRST .AND. msg < TCM_FIRST + 61 )  // optimized only
       RETURN -1
   ENDIF

   IF msg = WM_LBUTTONDOWN
      IF ::ShowDisablePage( lParam, WM_LBUTTONDOWN  ) = 0
          RETURN 0
      ENDIF
      ::lClick := .T.
      ::SetFocus( 0 )
      RETURN -1
   ELSEIF  msg = WM_MOUSEMOVE //.OR. ( ::nPaintHeight = 0 .AND. msg = WM_NCHITTEST  )
      ::ShowToolTips( lParam )
      RETURN ::ShowDisablePage( lParam )
   ELSEIF msg = WM_PAINT
      RETURN - 1
   ELSEIF msg =  WM_ERASEBKGND
      ::ShowDisablePage()
      Return - 1
   ELSEIF  msg = WM_PRINTCLIENT .OR. msg = WM_NCHITTEST  .OR. msg = WM_UPDATEUISTATE
      Return -1  // painted objects without METHOD PAINT

   ELSEIF  msg = WM_PRINT
      *-AEVAL( ::Pages, {| p, i |  p:aItemPos := TabItemPos( ::oParent:Handle, i - 1 ) } )
      *- ::SetPaintSizePos( -1 )
      ::SetPaintSizePos(  IIF(::nPaintHeight > 1, - 1, 1 ) )
      IF ::nActive > 0
         ::ShowPage( ::nActive )
         IF SendMessage( ::handle,TCM_GETROWCOUNT, 0 ,0 ) > 1
            InvalidateRect( ::Handle, 0, 1, ::Pages[ 1 ]:aItemPos[ 2 ], ::nWidth - 1,  ::Pages[ 1 ]:aItemPos[ 4 ] * SendMessage( ::handle,TCM_GETROWCOUNT, 0 ,0 )  )
         ENDIF
      ENDIF

   ELSEIF msg = WM_SIZE
      AEVAL( ::Pages, {| p, i |  p:aItemPos := TabItemPos( ::Handle, i - 1 ) } )
      ::oPaint:nHeight := ::nPaintHeight
      ::oPaint:Anchor := IIF( ::nPaintHeight > 1, 15, 0 )
      IF ::nPaintHeight > 1
         PostMessage( ::handle, WM_PRINT, GETDC( ::handle ), PRF_CHECKVISIBLE )
      ENDIF

   ELSEIF  msg = WM_SETFONT .AND. ::oFont != Nil .AND. ::lInit
      SendMessage( ::handle,    WM_PRINT, GETDC( ::handle ) , PRF_CHECKVISIBLE ) //+ PRF_ERASEBKGND ) //PRF_CLIENT + PRF_CHILDREN + PRF_OWNED )

   ELSEIF msg == WM_KEYDOWN .AND. GetFocus()= ::handle //.OR.(msg = WM_GETDLGCODE .AND. wparam == VK_RETURN))
       IF ProcKeyList( Self, wParam )
          RETURN - 1
       ELSEIF wParam = VK_ESCAPE
         RETURN 0
       ENDIF
       IF wParam = VK_RIGHT .OR. wParam = VK_LEFT
          IF  SetTabFocus( Self, ::nActive, wParam )  = ::nActive
             RETURN 0
          ENDIF
       ELSEIF (wparam == VK_DOWN .or.wparam == VK_RETURN).AND. ::nActive > 0  //
           GetSkip( Self, ::handle, , 1 )
           RETURN 0
       ELSEIF wParam = VK_TAB
           GetSkip( ::oParent, ::handle, , iif( IsCtrlShift( .f., .t. ), -1, 1 ) )
           RETURN 0
       ELSEIF wparam == VK_UP .AND. ::nActive > 0  //
          GetSkip( ::oParent, ::handle, , - 1 )
          RETURN 0
       ENDIF
   ELSEIF msg == WM_HSCROLL .OR. msg == WM_VSCROLL //.AND. ::FINDCONTROL(,GETFOCUS()):classname = "HUPDO"
       IF GetFocus() = ::Handle
          InvalidateRect( ::oPaint:handle, 1, 0, 0 , ::nwidth, 30 ) //::TabHeightSize + 2 )
       ENDIF
       IF ::GetParentForm( self ):Type < WND_DLG_RESOURCE
          RETURN ( ::oParent:onEvent( msg, wparam, lparam ) )
       ELSE
          RETURN ( super:onevent(msg, wparam, lparam ) )
       ENDIF
   ELSEIF  msg = WM_GETDLGCODE
      IF wparam == VK_RETURN .OR. wParam = VK_ESCAPE  .AND. ;
           ( ( oCtrl := ::GetParentForm:FindControl( IDCANCEL ) ) != Nil .AND. ! oCtrl:IsEnabled() )
         RETURN DLGC_WANTMESSAGE
      ENDIF
   ENDIF
     IF  msg = WM_NOTIFY .AND. isWindowVisible( ::oParent:handle) .AND.  ::nActivate = Nil
      IF ::bGetFocus != NIL
          ::oParent:lSuspendMsgsHandling := .T.
          Eval( ::bGetFocus, Self, GetCurrentTab( ::handle ) )
          ::oParent:lSuspendMsgsHandling := .F.
      ENDIF
   ELSEIF ( isWindowVisible( ::handle) .AND. ::nActivate = Nil ) .OR. msg == WM_KILLFOCUS
      ::nActivate := getfocus()
   ENDIF

   IF ::bOther != Nil
      ::oparent:lSuspendMsgsHandling := .t.
      IF Eval( ::bOther, Self, msg, wParam, lParam ) != - 1
        * RETURN 0
      ENDIF
      ::oparent:lSuspendMsgsHandling := .f.
   ENDIF
   IF ! ( ( msg = WM_COMMAND .OR. msg = WM_NOTIFY) .AND. ::oParent:lSuspendMsgsHandling .AND. ::lSuspendMsgsHandling )
      IF msg = WM_NCPAINT .AND. ::GetParentForm():nInitFocus > 0  .AND. PtrtouLong( GetParent( ::GetParentForm():nInitFocus ) ) = PtrtouLong( ::Handle ) 
          GetSkip( ::oParent, ::GetParentForm():nInitFocus , , 0 )
          ::GetParentForm():nInitFocus := 0
      ENDIF
      IF msg == WM_KILLFOCUS .AND. ::GetParentForm() != Nil  .AND. ::GetParentForm():Type < WND_DLG_RESOURCE
          SendMessage( ::oParent:handle, WM_COMMAND, makewparam( ::id, 0 ), ::handle )
          ::nPrevPage := 0
      ENDIF
      IF msg = WM_DRAWITEM
         ::ShowDisablePage()
      ENDIF
      RETURN Super:onEvent( msg, wparam, lparam )
   ENDIF
   RETURN - 1


METHOD ShowDisablePage( nPageEnable, nEvent ) CLASS HTab
   LOCAL client_rect, i, pt := {, }

   DEFAULT nPageEnable := 0
   IF ! isWindowVisible(::handle) .OR. ( Ascan( ::Pages, {| p | ! p:lEnabled } ) = 0  .AND. nPageEnable = Nil )
      RETURN - 1
   ENDIF
   nPageEnable := IIF( nPageEnable = Nil, 0, nPageEnable )
   nEvent := IIF( nEvent = Nil, 0 , nEvent )
   IF  PtrtoUlong( nPageEnable ) > 128
      pt[ 1 ] = LOWORD( nPageEnable )
      pt[ 2 ] = HIWORD( nPageEnable )
   ENDIF
   FOR i = 1 to Len( ::Pages )
      IF ! ::pages[ i ]:enabled .OR. i = PtrtoUlong(nPageEnable)
         //client_rect := ::Pages[ i ]:aItemPos
         client_rect := TabItemPos( ::Handle, i - 1 )
         IF ( PtInRect( client_rect, pt ) ) .AND. i != nPageEnable
            RETURN 0
         ENDIF
         ::oPaint:ShowTextTabs(  ::pages[ i ] , client_rect )
      ENDIF
   NEXT
   RETURN -1

METHOD ShowToolTips( lParam ) CLASS HTab
   LOCAL i, pt := {, }, client_rect

   IF Ascan( ::Pages, {| p | p:ToolTip != Nil } ) = 0
       RETURN Nil
   ENDIF
   pt[ 1 ] := LOWORD( lParam )
   pt[ 2 ] := HIWORD( lParam )

   FOR i := 1 to Len( ::Pages )
       client_rect :=  ::Pages[ i ]:aItemPos
       IF ( PtInRect( client_rect, pt ) )
             ::SetToolTip( IIF( ::Pages[ i ]:Tooltip = Nil, "", ::Pages[ i ]:Tooltip ) )
          EXIT
       ENDIF
   NEXT
   RETURN NIL

STATIC Function SetTabFocus( oCtrl, nPage, nKeyDown )
   LOCAL i, nSkip, nStart, nEnd, nPageAcel

   IF nKeyDown = VK_LEFT .OR. nKeyDown = VK_RIGHT  // 37,39
     nEnd := IIF( nKeyDown = VK_LEFT, 1, Len( oCtrl:aPages ) )
     nSkip := IIF( nKeyDown = VK_LEFT, -1, 1 )
     nStart :=  nPage + nSkip
     FOR i = nStart TO nEnd STEP nSkip
         IF oCtrl:pages[ i ]:enabled
            IF ( nSkip > 0 .AND. i > nStart ) .OR. ( nSkip < 0 .AND. i < nStart )
               SendMessage( oCtrl:handle, TCM_SETCURFOCUS, i - nSkip - 1, 0 ) // BOTOES
            ENDIF
            RETURN i
         ELSEIF i = nEnd
            IF oCtrl:pages[ i - nSkip ]:enabled
             SendMessage( oCtrl:handle, TCM_SETCURFOCUS, i - (nSkip * 2) - 1 , 0 ) // BOTOES
             RETURN ( i - nSkip )
          ENDIF
            RETURN nPage
         ENDIF
       NEXT
     ELSE
      nPageAcel := FindTabAccelerator( oCtrl, nKeyDown )
      IF nPageAcel = 0
         MsgBeep()
      ENDIF
   ENDIF
   RETURN nPage

FUNCTION FindTabAccelerator( oPage, nKey )
  Local  i ,pos ,cKey
  cKey := Upper( Chr( nKey ) )
  FOR i = 1 to Len( oPage:aPages )
     IF ( pos := At( "&", oPage:Pages[ i ]:caption ) ) > 0 .AND.  cKey  ==  Upper( SubStr( oPage:Pages[ i ]:caption , ++ pos, 1 ) )
        IF oPage:pages[ i ]:Enabled
            SendMessage( oPage:handle, TCM_SETCURFOCUS, i - 1, 0 )
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
   Super:New( oWndParent, nId, SS_OWNERDRAW + WS_DISABLED , nLeft, nTop, nWidth, nHeight, , ;
              ,, ::bPaint,, tcolor, bColor )
   ::anchor := 15
   ::brush := Nil
   ::backstyle := TRANSPARENT
   ::Name := "PaintTab"

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HPaintTab
   IF !Empty( ::oParent:handle )
      ::handle := CreateStatic( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth,::nHeight )
   ENDIF
   RETURN Nil

METHOD Paint( lpdis ) CLASS HPaintTab
   LOCAL drawInfo := GetDrawItemInfo( lpdis )
   LOCAL hDC := drawInfo[ 3 ]
   LOCAL  x1 := drawInfo[ 4 ], y1 := drawInfo[ 5 ]
   LOCAL  x2 := drawInfo[ 6 ], y2 := drawInfo[ 7 ]
   LOCAL  i, client_rect
   LOCAL nPage := SendMessage( ::oParent:handle, TCM_GETCURFOCUS, 0, 0 ) + 1
   LOCAL oPage := IIF( nPage > 0, ::oParent:Pages[ nPage ], ::oParent:Pages[ 1 ] )

   ::disablebrush := oPage:brush
   IF oPage:brush != Nil
      IF ::oParent:nPaintHeight < ::oParent:TabHeightSize //40
        ::nHeight := 1
        ::move( ,,, ::nHeight )
      ELSEIF oPage:brush != Nil
        FillRect( hDC, x1 + 1, y1 + 2, x2 - 1, y2 - 0, oPage:brush:Handle ) //obrush )
        ::oParent:RedrawControls( )
      ENDIF
   ENDIF

   ::hDC := GetDC( ::oParent:handle )
   FOR i = 1 to Len( ::oParent:Pages )
      oPage := ::oParent:Pages[ i ]
      client_rect :=  TabItemPos( ::oParent:Handle,i - 1 )
      oPage:aItemPos := client_rect
      IF oPage:brush != Nil //.AND. client_rect[ 4 ] - client_rect[ 2 ] > 5
         //SetBkMode( hDC, TRANSPARENT )
         IF nPage = oPage:PageOrder
            FillRect( ::hDC, client_rect[ 1 ], client_rect[ 2 ] + 1, client_rect[ 3 ] ,client_rect[ 4 ] + 2 , oPage:brush:handle )
            IF GetFocus() = oPage:oParent:handle
               InflateRect( @client_rect, - 2, - 2 )
               DrawFocusRect( ::hDC, client_rect )
            endif
         ELSE
            FillRect( ::hDC, client_rect[ 1 ] + IIF( i = nPage + 1, 2, 1 ),;
                             client_rect[ 2 ] + 1,;
                             client_rect[ 3 ] - IIF( i = nPage - 1 , 3, 2 ) - IIF( i = Len( ::oParent:Pages ), 1, 0 ), ;
                             client_rect[ 4 ] - 1, oPage:brush:Handle )
         ENDIF
      ENDIF
      IF  oPage:brush != Nil .OR. oPage:tColor != Nil .OR. ! oPage:lenabled
         ::showTextTabs( oPage , client_rect )
      ENDIF
   NEXT
   RETURN 0

METHOD showTextTabs( oPage, aItemPos ) CLASS HPaintTab
    LOCAL nStyle, BmpSize := 0, size := 0, aTxtSize, aItemRect
    LOCAL nActive := oPage:oParent:GetActivePage(), hTheme
    //nStyle := SS_CENTER + IIF(  Hwg_BitAnd( oPage:oParent:Style, TCS_FIXEDWIDTH  ) != 0 ,;
    //                            SS_RIGHTJUST, DT_VCENTER + DT_SINGLELINE )
    AEVAL( oPage:oParent:Pages, {| p | size += p:aItemPos[ 3 ] - p:aItemPos[ 1 ] } )
    nStyle := SS_CENTER + DT_VCENTER + DT_SINGLELINE + DT_END_ELLIPSIS

    ::hDC := IIF( ::hDC = Nil, GetDC( ::oParent:handle ), ::hDC )
    IF ( ISTHEMEDLOAD() )
       hTheme := nil
       IF ::WindowsManifest
           hTheme := hb_OpenThemeData( ::oParent:handle, "TAB" )
       ENDIF
       hTheme := IIF( EMPTY( hTheme  ), Nil, hTheme )
    ENDIF
    SetBkMode( ::hDC, TRANSPARENT )
    IF oPage:oParent:oFont != Nil
       SelectObject( ::hDC, oPage:oParent:oFont:handle )
    ENDIF
    IF oPage:lEnabled
       SetTextColor( ::hDC, IIF( EMPTY( oPage:tColor ), GetSysColor( COLOR_WINDOWTEXT ), oPage:tColor ) )
    ELSE
         //SetTextColor( ::hDC, GetSysColor( COLOR_GRAYTEXT ) )
         SetTextColor( ::hDC, GetSysColor( COLOR_BTNHIGHLIGHT ) )
    ENDIF
    aTxtSize := TxtRect( oPage:caption, oPage:oParent )
    IF oPage:oParent:himl != Nil
        BmpSize := ( ( aItemPos[ 3 ] - aItemPos[ 1 ] ) - ( oPage:oParent:aBmpSize[ 1 ] + aTxtSize[1] ) ) / 2
        BmpSize += oPage:oParent:aBmpSize[ 1 ]
        BmpSize := MAX( BmpSize, oPage:oParent:aBmpSize[ 1 ] )
    ENDIF
    aItemPos[ 3 ] := IIF( size > oPage:oParent:nWidth .AND. aItemPos[ 1 ] + BmpSize + aTxtSize[ 1 ] > oPage:oParent:nWidth - 44, oPage:oParent:nWidth - 44, aItemPos[ 3 ] )
    aItemRect := { aItemPos[ 1 ] + IIF( oPage:PageOrder = nActive + 1, 1, 0 ), aItemPos[ 2 ]  , aItemPos[ 3 ] - IIF( oPage:PageOrder = Len( oPage:oParent:Pages ), 2, IIF( oPage:PageOrder = nActive - 1, 1, 0 ) ) , aItemPos[ 4 ] - 1   }
    IF  Hwg_BitAnd( oPage:oParent:Style, TCS_BOTTOM  ) = 0
       IF hTheme != Nil .AND. oPage:brush = Nil
          hb_DrawThemeBackground( hTheme, ::hDC, BP_PUSHBUTTON, 0, aItemRect, Nil )
       ELSE
          FillRect( ::hDC,  aItemPos[ 1 ] + BmpSize + 3, aItemPos[ 2 ] + 4, aItemPos[ 3 ] - 3, aItemPos[ 4 ] - 5, ;
                   IIF( oPage:brush != Nil, oPage:brush:Handle, GetStockObject( NULL_BRUSH ) ) )
       ENDIF
       IF nActive = oPage:PageOrder                       // 4
          DrawText( ::hDC, oPage:caption, aItemPos[ 1 ] + BmpSize - 1 , aItemPos[ 2 ] - 1, aItemPos[ 3 ]   , aItemPos[ 4 ] - 1 , nstyle )
       ELSE
          IF oPage:lEnabled = .F.
             DrawText( ::hDC, oPage:caption, aItemPos[ 1 ] + BmpSize - 1, aItemPos[ 2 ] + 1, aItemPos[ 3 ] + 1 , aItemPos[ 4 ] + 1 , nstyle )
             SetTextColor( ::hDC, GetSysColor( COLOR_GRAYTEXT ) )
          ENDIF
          DrawText( ::hDC, oPage:caption, aItemPos[ 1 ] + BmpSize - 1, aItemPos[ 2 ] + 1, aItemPos[ 3 ] + 1 , aItemPos[ 4 ] + 1 , nstyle )
       ENDIF
    ELSE
       IF hTheme != Nil .AND. oPage:brush = Nil
          hb_DrawThemeBackground( hTheme, ::hDC, BP_PUSHBUTTON, 0, aItemRect, Nil )
       ELSE
          FillRect( ::hDC,  aItemPos[ 1 ] + 3, aItemPos[ 2 ] + 3, aItemPos[ 3 ] - 4, aItemPos[ 4 ] - 5, IIF( oPage:brush != Nil, oPage:brush:Handle, GetStockObject( NULL_BRUSH ) ) ) // oPage:oParent:brush:Handle ) )
       ENDIF
       IF nActive = oPage:PageOrder                       // 4
          DrawText( ::hDC, oPage:caption, aItemPos[ 1 ] , aItemPos[ 2 ] + 2, aItemPos[ 3 ] , aItemPos[ 4 ] + 2 , nstyle )
       ELSE
          IF oPage:lEnabled = .F.
             DrawText( ::hDC, oPage:caption, aItemPos[ 1 ] + 1, aItemPos[ 2 ] + 1 , aItemPos[ 3 ] + 1  , aItemPos[ 4 ] + 1 , nstyle )
             SetTextColor( ::hDC, GetSysColor( COLOR_GRAYTEXT ) )
          ENDIF
          DrawText( ::hDC, oPage:caption, aItemPos[ 1 ] , aItemPos[ 2 ] , aItemPos[ 3 ] , aItemPos[ 4 ]  , nstyle )
       ENDIF
    ENDIF
    IF oPage:lEnabled .AND. oPage:brush = Nil
        InvalidateRect( ::oParent:handle, 0, aItemPos[ 1 ] , aItemPos[ 2 ] ,aItemPos[ 1 ]+ aItemPos[ 3 ] , aItemPos[ 2 ]+aItemPos[ 4 ] )
    ENDIF

    RETURN Nil
