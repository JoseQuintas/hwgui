/*
 * $Id: hcontrol.prg,v 1.85 2008-09-08 16:53:29 mlacecilia Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HControl, HStatus, HStatic, HButton, HGroup, HLine classes
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su

 *
 * ButtonEx class
 *
 * Copyright 2007 Luiz Rafael Culik Guimaraes <luiz at xharbour.com.br >
 * www - http://sites.uol.com.br/culikr/

*/

#translate :hBitmap       => :m_csbitmaps\[ 1 \]
#translate :dwWidth       => :m_csbitmaps\[ 2 \]
#translate :dwHeight      => :m_csbitmaps\[ 3 \]
#translate :hMask         => :m_csbitmaps\[ 4 \]
#translate :crTransparent => :m_csbitmaps\[ 5 \]
#pragma begindump
#include "windows.h"
#include "hbapi.h"
#pragma enddump

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define  CONTROL_FIRST_ID   34000
#define TRANSPARENT 1
#define BTNST_COLOR_BK_IN     1            // Background color when mouse is INside
#define BTNST_COLOR_FG_IN     2            // Text color when mouse is INside
#define BTNST_COLOR_BK_OUT    3             // Background color when mouse is OUTside
#define BTNST_COLOR_FG_OUT    4             // Text color when mouse is OUTside
#define BTNST_COLOR_BK_FOCUS  5           // Background color when the button is focused
#define BTNST_COLOR_FG_FOCUS  6            // Text color when the button is focused
#define BTNST_MAX_COLORS      6
#define WM_SYSCOLORCHANGE               0x0015
#define BS_TYPEMASK SS_TYPEMASK
//- HControl

CLASS HControl INHERIT HCustomWindow

   DATA   id
   DATA   tooltip
   DATA   lInit           INIT .F.
   DATA   xName           HIDDEN
   ACCESS Name            INLINE ::xName
   ASSIGN Name( cName )     INLINE ::xName := cName, ;
                                              __objAddData( ::oParent, cName ), ;
                                              ::oParent: & ( cName ) := Self

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor )
   METHOD Init()
   METHOD SetColor( tcolor, bColor, lRepaint )
   METHOD NewId()
   METHOD Disable()     INLINE EnableWindow( ::handle, .F. )
   METHOD Enable()      INLINE EnableWindow( ::handle, .T. )
   METHOD IsEnabled()   INLINE IsWindowEnabled( ::Handle )
   METHOD SetFocus()    INLINE ( SendMessage( ::oParent:handle, WM_NEXTDLGCTL, ;
                                              ::handle, 1 ), ;
                                 SetFocus( ::handle ) )
   METHOD GetText()     INLINE GetWindowText( ::handle )
   METHOD SetText( c )  INLINE SetWindowText( ::Handle, c ), ::Refresh()
   METHOD Refresh()     VIRTUAL
   METHOD END()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
            bInit, bSize, bPaint, cTooltip, tcolor, bColor ) CLASS HControl

   ::oParent := IIf( oWndParent == NIL, ::oDefaultParent, oWndParent )
   ::id      := IIf( nId == NIL, ::NewId(), nId )
   ::style   := Hwg_BitOr( IIf( nStyle == NIL, 0, nStyle ), ;
                           WS_VISIBLE + WS_CHILD )
   ::oFont   := oFont
   ::nLeft   := nLeft
   ::nTop    := nTop
   ::nWidth  := nWidth
   ::nHeight := nHeight
   ::bInit   := bInit
   ::bSize   := bSize
   ::bPaint  := bPaint
   ::tooltip := cTooltip
   ::SetColor( tcolor, bColor )

   ::oParent:AddControl( Self )

   RETURN Self

METHOD NewId() CLASS HControl

   LOCAL oParent := ::oParent, i := 0, nId

   DO WHILE oParent != Nil
      nId := CONTROL_FIRST_ID + 1000 * i + Len( ::oParent:aControls )
      oParent := oParent:oParent
      i ++
   ENDDO
   IF AScan( ::oParent:aControls, { | o | o:id == nId } ) != 0
      nId --
      DO WHILE nId >= CONTROL_FIRST_ID .AND. ;
               AScan( ::oParent:aControls, { | o | o:id == nId } ) != 0
         nId --
      ENDDO
   ENDIF
   RETURN nId

METHOD INIT CLASS HControl

   IF ! ::lInit
      IF ::tooltip != Nil
         AddToolTip( ::oParent:handle, ::handle, ::tooltip )
      ENDIF
      IF ::oFont != NIL
         SetCtrlFont( ::oParent:handle, ::id, ::oFont:handle )
      ELSEIF ::oParent:oFont != NIL
         SetCtrlFont( ::oParent:handle, ::id, ::oParent:oFont:handle )
      ENDIF

      IF ISBLOCK( ::bInit )
         Eval( ::bInit, Self )
      ENDIF
      ::lInit := .T.
   ENDIF
   RETURN NIL

METHOD SetColor( tcolor, bColor, lRepaint ) CLASS HControl

   IF tcolor != NIL
      ::tcolor := tcolor
      IF bColor == NIL .AND. ::bColor == NIL
         bColor := GetSysColor( COLOR_3DFACE )
      ENDIF
   ENDIF

   IF bColor != NIL
      ::bColor := bColor
      IF ::brush != NIL
         ::brush:Release()
      ENDIF
      ::brush := HBrush():Add( bColor )
   ENDIF

   IF lRepaint != NIL .AND. lRepaint
      RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
   ENDIF

   RETURN NIL

METHOD END() CLASS HControl

   Super:END()

   IF ::tooltip != NIL
      DelToolTip( ::oParent:handle, ::handle )
      ::tooltip := NIL

   ENDIF
   RETURN NIL


//- HStatus

CLASS HStatus INHERIT HControl

CLASS VAR winclass   INIT "msctls_statusbar32"

   DATA aParts

   METHOD New( oWndParent, nId, nStyle, oFont, aParts, bInit, bSize, bPaint )
   METHOD Activate()
   METHOD Init()
   METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
                    bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aParts )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, oFont, aParts, bInit, bSize, bPaint ) CLASS HStatus

   bSize  := IIf( bSize != NIL, bSize, { | o, x, y | o:Move( 0, y - 20, x, 20 ) } )
   nStyle := Hwg_BitOr( IIf( nStyle == NIL, 0, nStyle ), ;
                        WS_CHILD + WS_VISIBLE + WS_OVERLAPPED + ;
                        WS_CLIPSIBLINGS )
   Super:New( oWndParent, nId, nStyle, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint )

   ::aParts  := aParts

   ::Activate()

   RETURN Self

METHOD Activate CLASS HStatus
   LOCAL aCoors

   IF ! Empty( ::oParent:handle )
      ::handle := CreateStatusWindow( ::oParent:handle, ::id )
      ::Init()
      IF __ObjHasMsg( ::oParent, "AOFFSET" )
         aCoors := GetWindowRect( ::handle )
         ::oParent:aOffset[ 4 ] := aCoors[ 4 ] - aCoors[ 2 ]
      ENDIF
   ENDIF
   RETURN NIL

METHOD Init CLASS HStatus
   IF ! ::lInit
      Super:Init()
      IF ! Empty( ::aParts )
         hwg_InitStatus( ::oParent:handle, ::handle, Len( ::aParts ), ::aParts )
      ENDIF
   ENDIF
   RETURN  NIL

METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
                 bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aParts )  CLASS hStatus

   HB_SYMBOL_UNUSED( cCaption )
   HB_SYMBOL_UNUSED( lTransp )

   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor )
   HWG_InitCommonControlsEx()
   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   ::aParts := aParts
   RETURN Self

//- HStatic

CLASS HStatic INHERIT HControl

CLASS VAR winclass   INIT "STATIC"

   DATA AutoSize    INIT .F.
   DATA lownerDraw  INIT .F.
   DATA nStyleOwner INIT 0

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
               bColor, lTransp )
   METHOD Redefine( oWndParent, nId, oFont, bInit, ;
                    bSize, bPaint, cTooltip, tcolor, bColor, lTransp )
   METHOD Activate()
   // METHOD SetValue( value ) INLINE SetDlgItemText( ::oParent:handle, ::id, ;
   //                                                 value )
   METHOD SetValue( value ) INLINE ::Auto_Size( value ), ;
   SetDlgItemText( ::oParent:handle, ::id, value )
   METHOD Auto_Size( cValue, nAlign )  HIDDEN

   METHOD Init()
   METHOD PAINT( o )
ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
            cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
            bColor, lTransp ) CLASS HStatic

   ::lOwnerDraw := Hwg_BitAnd( nStyle, SS_OWNERDRAW ) + 1 >= SS_OWNERDRAW
   // Enabling style for tooltips
   IF ValType( cTooltip ) == "C"
      IF nStyle == NIL
         nStyle := SS_NOTIFY
      ELSE
         nStyle := Hwg_BitOr( nStyle, SS_NOTIFY )
      ENDIF
   ENDIF
   //
   IF ( lTransp != NIL .AND. lTransp ) .OR. ::lOwnerDraw
      ::extStyle += WS_EX_TRANSPARENT
      bPaint := { | o, p | o:paint( p ) }
      IF ::lOwnerDraw
         ::nStyleOwner := nStyle - SS_OWNERDRAW - Hwg_Bitand( nStyle, SS_NOTIFY )
         nStyle := SS_OWNERDRAW + Hwg_Bitand( nStyle, SS_NOTIFY )
      ENDIF
   ENDIF

   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
              bInit, bSize, bPaint, cTooltip, tcolor, bColor )

   IF ltransp .AND. bColor = Nil .AND. ::oParent:brush != Nil
      ::bcolor := ::oparent:bcolor
   ENDIF


   IF ::oParent:oParent != Nil
      bPaint := { | o, p | o:paint( p ) }
   ENDIF

   ::title := cCaption

   ::Activate()

   RETURN Self

METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
                 bSize, bPaint, cTooltip, tcolor, bColor, lTransp ) CLASS HStatic

   IF ( lTransp != NIL .AND. lTransp )  //.OR. ::lOwnerDraw
      ::extStyle += WS_EX_TRANSPARENT
      bPaint := { | o, p | o:paint( p ) }
   ENDIF

   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, cTooltip, tcolor, bColor )

   ::title := cCaption
   ::style := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   // Enabling style for tooltips
   IF ValType( cTooltip ) == "C"
      ::Style := SS_NOTIFY
   ENDIF
   RETURN Self

METHOD Activate CLASS HStatic
   IF ! Empty( ::oParent:handle )
      ::handle := CreateStatic( ::oParent:handle, ::id, ::style, ;
                                ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
                                ::extStyle )
      ::Init()
   ENDIF
   RETURN NIL

METHOD Init CLASS HStatic
   IF ! ::lInit
      Super:init()
      IF ::Title != NIL
         ::Auto_Size( ::Title, ::nStyleOwner )
         SetWindowText( ::handle, ::title )
      ENDIF
   ENDIF
   RETURN  NIL

METHOD Paint( lpDis ) CLASS HStatic
   LOCAL drawInfo := GetDrawItemInfo( lpDis )
   LOCAL client_rect, szText
   LOCAL dwtext, nstyle
   LOCAL dc := drawInfo[ 3 ]

   client_rect := GetClientRect( ::handle )
   szText      := GetWindowText( ::handle )

   // Map "Static Styles" to "Text Styles"
   nstyle := ::style   ////Hwg_BitaND( nStyle, SS_OWNERDRAW )
   SetAStyle( @nstyle, @dwtext )

   // Set transparent background
   SetBkMode( dc, 1 )
   IF ::lOwnerDraw
      ::Auto_Size( szText, ::nStyleOwner )
   ENDIF
   // Draw the text
   DrawText( dc, szText, ;
             client_rect[ 1 ], client_rect[ 2 ], client_rect[ 3 ], client_rect[ 4 ], ;
             dwtext )
   RETURN nil

METHOD Auto_Size( cValue, nAlign ) CLASS HStatic
   LOCAL  ASize, nLeft

   IF ::autosize .OR. ::lOwnerDraw
      ASize :=  TxtRect( cValue, Self )
      IF nAlign == SS_RIGHT
         nLeft := ::nLeft + ( ::nWidth - ASize[ 1 ] - 2 )
      ELSEIF nAlign == SS_CENTER
         nLeft := ::nLeft + Int( ( ::nWidth - ASize[ 1 ] - 2 ) / 2 )
      ELSEIF nAlign == SS_LEFT
         nLeft := ::nLeft
      ENDIF
      ::nWidth := ASize[ 1 ] + 2
      ::nHeight := ASize[ 2 ]
      ::move( ::nLeft, ::nTop )
      ::nLeft := nLeft
   ENDIF
   RETURN Nil


//- HButton

CLASS HButton INHERIT HControl

CLASS VAR winclass   INIT "BUTTON"

   DATA bClick

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
               tcolor, bColor )
   METHOD Activate()
   METHOD Redefine( oWnd, nId, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
                    tcolor, bColor )
   METHOD Init()
   METHOD Notify( lParam )
   METHOD onClick()

ENDCLASS


METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
            cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
            tcolor, bColor ) CLASS HButton


   nStyle := Hwg_BitOr( IIf( nStyle == NIL, 0, nStyle ), BS_PUSHBUTTON + BS_NOTIFY )

   Super:New( oWndParent, nId, nStyle, nLeft, nTop, ;
              IIf( nWidth  == NIL, 90, nWidth  ), ;
              IIf( nHeight == NIL, 30, nHeight ), ;
              oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor )
   ::bClick  := bClick
   ::title   := cCaption
   ::Activate()
   IF ::oParent:oParent != Nil .and. ::oParent:ClassName == "HTAB"
      ::oParent:AddEvent( BN_KILLFOCUS, Self, { || ::Notify( WM_KEYDOWN ) } )
      IF bClick != NIL
         ::oParent:oParent:AddEvent( 0, Self, { || ::onClick() } )
      ENDIF
   ENDIF
   IF bClick != NIL
      ::oParent:AddEvent( 0, Self, { || ::onClick() } )
   ENDIF
   RETURN Self

METHOD Activate CLASS HButton
   IF ! Empty( ::oParent:handle )
      ::handle := CreateButton( ::oParent:handle, ::id, ::style, ;
                                ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
                                ::title )
      ::Init()
   ENDIF
   RETURN NIL

METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
                 cTooltip, tcolor, bColor, cCaption ) CLASS HButton

   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, cTooltip, tcolor, bColor )

   ::title   := cCaption

   IF bClick != NIL
      ::oParent:AddEvent( 0, Self, bClick )
   ENDIF
   RETURN Self

METHOD Init CLASS HButton
   IF ! ::lInit
      ::Super:init()
      IF ::Title != NIL
         SETWINDOWTEXT( ::handle, ::title )
      ENDIF
   ENDIF
   RETURN  NIL

METHOD onClick()  CLASS HButton
   IF ::bClick != Nil
      ::oParent:lSuspendMsgsHandling := .T.
      Eval( ::bClick, ::oParent, ::id )
      ::oParent:lSuspendMsgsHandling := .F.
   ENDIF
   RETURN Nil


METHOD Notify( lParam ) CLASS HButton
   LOCAL ndown := getkeystate( VK_RIGHT ) + getkeystate( VK_DOWN ) + GetKeyState( VK_TAB )
   LOCAL nSkip := 0
   //
   IF lParam = WM_KEYDOWN
      IF ::oParent:Classname = "HTAB"
         IF getfocus() != ::handle
            InvalidateRect( ::handle, 0 )
            SENDMESSAGE( ::handle, BM_SETSTYLE , BS_PUSHBUTTON , 1 )
         ENDIF
         IF getkeystate( VK_LEFT ) + getkeystate( VK_UP ) < 0 .OR. ;
            ( GetKeyState( VK_TAB ) < 0 .and. GetKeyState( VK_SHIFT ) < 0 )
            nSkip := - 1
         ELSEIF ndown < 0
            nSkip := 1
         ENDIF
         IF nSkip != 0
            SETFOCUS( ::oParent:Handle )
            GetSkip( ::oparent, ::handle, , nSkip )
            RETURN 0
         ENDIF
      ENDIF
   ENDIF
   RETURN - 1

//- HGroup

CLASS HButtonEX INHERIT HButton

   DATA hBitmap
   DATA hIcon
   DATA m_dcBk
   DATA m_bFirstTime INIT .T.
   DATA Themed INIT .F.
   DATA m_crColors INIT Array( 6 )
   DATA hTheme
   DATA Caption
   DATA state
   DATA m_bIsDefault INIT .F.
   DATA m_nTypeStyle  init 0
   DATA m_bSent, m_bLButtonDown, m_bIsToggle
   DATA m_rectButton           // button rect in parent window coordinates
   DATA m_dcParent init hdc():new()
   DATA m_bmpParent
   DATA m_pOldParentBitmap
   DATA m_csbitmaps init {,,,, }
   DATA m_bToggled INIT .f.



   DATA m_bDrawTransparent INIT .f.
   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, tcolor, ;
               bColor, lTransp, hBitmap, hIcon )
   DATA iStyle
   DATA m_bmpBk, m_pbmpOldBk
   DATA  bMouseOverButton INIT .f.

   METHOD Paint( lpDis )
   METHOD SetBitmap( )
   METHOD SetIcon()
   METHOD Init()
   METHOD onevent( msg, wParam, lParam )
   METHOD CancelHover()
   METHOD End()
   METHOD Redefine( oWnd, nId, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
                    tcolor, bColor, hBitmap, iStyle, hIcon )
   METHOD PaintBk( p )
   METHOD SetDefaultColor( lRepaint )
   METHOD SetColorEx( nIndex, nColor, bPaint )

   METHOD SetText( c ) INLINE ::title := c, ::caption := c, ;
                                                         SendMessage( ::handle, WM_PAINT, 0, 0 ), ;
                                                         SetWindowText( ::handle, ::title )


//   METHOD SaveParentBackground()


END CLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
            cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
            tcolor, bColor, hBitmap, iStyle, hicon, Transp ) CLASS HButtonEx

   DEFAULT iStyle TO ST_ALIGN_HORIZ
   DEFAULT Transp TO .T.
   ::m_bLButtonDown := .f.
   ::m_bSent := .f.
   ::m_bLButtonDown := .f.
   ::m_bIsToggle := .f.


   ::Caption := cCaption
   ::iStyle                             := iStyle
   ::hBitmap                            := hBitmap
   ::hicon                              := hicon
   ::m_bDrawTransparent                 := Transp


   bPaint   := { | o, p | o:paint( p ) }

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
                cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
                tcolor, bColor )

   RETURN Self


METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
                 cTooltip, tcolor, bColor, cCaption, hBitmap, iStyle, hIcon  ) CLASS HButtonEx
   DEFAULT iStyle TO ST_ALIGN_HORIZ
   bPaint   := { | o, p | o:paint( p ) }
   ::m_bLButtonDown := .f.
   ::m_bIsToggle := .f.

   ::m_bLButtonDown := .f.
   ::m_bSent := .f.

   ::title   := cCaption

   ::Caption := cCaption
   ::iStyle                             := iStyle
   ::hBitmap                            := hBitmap
   ::hIcon                              := hIcon
   ::m_crColors[ BTNST_COLOR_BK_IN ]    := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_IN ]    := GetSysColor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_OUT ]   := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_OUT ]   := GetSysColor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_FOCUS ] := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_FOCUS ] := GetSysColor( COLOR_BTNTEXT )


   ::Super:Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
                     cTooltip, tcolor, bColor, cCaption, hBitmap, iStyle, hIcon  )
   ::title   := cCaption

   ::Caption := cCaption


   RETURN Self

METHOD SetBitmap() CLASS HButtonEX
   IF ValType( ::hBitmap ) == "N"
      SendMessage( ::handle, BM_SETIMAGE, IMAGE_BITMAP, ::hBitmap )
   ENDIF

   RETURN Self

METHOD SetIcon() CLASS HButtonEX
   IF ValType( ::hIcon ) == "N"
      SendMessage( ::handle, BM_SETIMAGE, IMAGE_ICON, ::hIcon )
   ENDIF
   RETURN Self

METHOD END() CLASS HButtonEX
   Super:END()
   RETURN Self

METHOD INIT CLASS HButtonEx
   LOCAL nbs
   IF ! ::lInit
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      HWG_INITBUTTONPROC( ::handle )
      IF HB_IsNumeric( ::handle ) .and. ::handle > 0
         nbs := HWG_GETWINDOWSTYLE( ::handle )

         ::m_nTypeStyle :=  GetTheStyle( nbs , BS_TYPEMASK )

         // Check if this is a checkbox

         // Set initial default state flag
         IF ( ::m_nTypeStyle == BS_DEFPUSHBUTTON )

            // Set default state for a default button
            ::m_bIsDefault := .t.

            // Adjust style for default button
            ::m_nTypeStyle := BS_PUSHBUTTON
         ENDIF
         nbs := modstyle( nbs, BS_TYPEMASK  , BS_OWNERDRAW )
         HWG_SETWINDOWSTYLE ( ::handle, nbs )

      ENDIF

      ::Super:init()
      ::SetBitmap()
   ENDIF
   RETURN NIL

METHOD onEvent( msg, wParam, lParam ) CLASS HBUTTONEx

   LOCAL pt := {, }, rectButton, acoor
   LOCAL pos

   IF msg == WM_THEMECHANGED
      IF ::Themed
         IF ValType( ::hTheme ) == "P"
            HB_CLOSETHEMEDATA( ::htheme )
            ::hTheme       := nil
            ::m_bFirstTime := .T.
         ENDIF
      ENDIF
      RETURN 0
   ELSEIF msg == WM_ERASEBKGND
      RETURN 0
   ELSEIF msg == BM_SETSTYLE
      RETURN BUTTONEXONSETSTYLE( wParam, lParam, ::handle, @::m_bIsDefault )

   ELSEIF msg == WM_MOUSEMOVE
      IF( ! ::bMouseOverButton )
      ::bMouseOverButton := .T.
      Invalidaterect( ::handle, .f. )
      TRACKMOUSEVENT( ::handle )
      ENDIF
      RETURN 0
   ELSEIF msg == WM_MOUSELEAVE
      ::CancelHover()
      RETURN 0

   ELSEIF msg == WM_KEYDOWN

   #ifdef __XHARBOUR__
      IF hb_inline( lParam ) {  LPARAM  l = ( LPARAM ) hb_parnl( 1 ) ; hb_retl( l & 0x40000000 ) ; }
   #else
      IF hb_BitTest( lParam , 30 )  // the key was down before ?
   #endif
          RETURN 0
       ENDIF
    IF ( ( wParam == VK_SPACE ) .or. ( wParam == VK_RETURN ) )
       SendMessage( ::handle, WM_LBUTTONDOWN, 0, MAKELPARAM( 1, 1 ) )
       RETURN 0
    ENDIF
    IF wParam == VK_LEFT .OR. wParam == VK_UP
       GetSkip( ::oParent, ::handle, , - 1 )
       RETURN 0
    ENDIF
    IF wParam == VK_RIGHT .OR. wParam == VK_DOWN
       GetSkip( ::oParent, ::handle, , 1 )
       RETURN 0
    ENDIF
 ELSEIF msg == WM_SYSKEYUP
    IF ( pos := At( "&", ::title ) ) > 0 .and. wParam == Asc( Upper( SubStr( ::title, ++ pos, 1 ) ) )
       IF ValType( ::bClick ) == "B" .or. ::id < 3
          SendMessage( ::oParent:handle, WM_COMMAND, makewparam( ::id, BN_CLICKED ), ::handle )
       ENDIF
    ENDIF
    RETURN 0
 ELSEIF msg == WM_KEYUP

    IF ( ( wParam == VK_SPACE ) .or. ( wParam == VK_RETURN ) )
       SendMessage( ::handle, WM_LBUTTONUP, 0, MAKELPARAM( 1, 1 ) )
       RETURN 0
    ENDIF

 ELSEIF msg == WM_LBUTTONUP
    ::m_bLButtonDown := .f.
    IF ( ::m_bSent )
       SendMessage( ::handle, BM_SETSTATE, 0, 0 )
       ::m_bSent := .f.
    ENDIF
    IF ::m_bIsToggle
       pt[ 1 ] := LOWORD( lParam )
       pt[ 2 ] := HIWORD( lParam )
       acoor := ClientToScreen( ::handle, pt[ 1 ], pt[ 2 ] )

       rectButton := GetWindowRect( ::handle )

       IF ( ! PtInRect( rectButton, acoor ) )
          ::m_bToggled = ! ::m_bToggled
          InvalidateRect( ::handle, 0 )
          SendMessage( ::handle, BM_SETSTATE, 0, 0 )
          ::m_bLButtonDown := .T.
       ENDIF
    ENDIF
    RETURN - 1

 ELSEIF msg == WM_LBUTTONDOWN
    ::m_bLButtonDown := .t.
    IF ( ::m_bIsToggle )
       ::m_bToggled := ! ::m_bToggled
       InvalidateRect( ::handle, 0 )
    ENDIF
    RETURN - 1

 ELSEIF msg == WM_LBUTTONDBLCLK

    IF ( ::m_bIsToggle )

       // for toggle buttons, treat doubleclick as singleclick
       SendMessage( ::handle, BM_SETSTATE, ::m_bToggled, 0 )

    ELSE

       SendMessage( ::handle, BM_SETSTATE, 1, 0 )
       ::m_bSent := TRUE

    ENDIF
    RETURN 0

 ELSEIF msg == WM_GETDLGCODE
    RETURN ButtonGetDlgCode( lParam )

 ELSEIF msg == WM_SYSCOLORCHANGE
    ::SetDefaultColors()
 ELSEIF msg == WM_CHAR
    IF wParam == VK_RETURN .or. wParam == VK_SPACE
       IF ( ::m_bIsToggle )

          ::m_bToggled := ! ::m_bToggled
          InvalidateRect( ::handle, 0 )
       ELSE

          SendMessage( ::handle, BM_SETSTATE, 1, 0 )
          ::m_bSent := .t.
       ENDIF

       SendMessage( ::oParent:handle, WM_COMMAND, makewparam( ::id, BN_CLICKED ), ::handle )
       ELSEIF wParam == VK_ESCAPE
          SendMessage( ::oParent:handle, WM_COMMAND, makewparam( 2, BN_CLICKED ), ::handle )
       ENDIF
    ENDIF
    RETURN 0
 ENDIF
 RETURN - 1



METHOD CancelHover() CLASS HBUTTONEx

   IF ( ::bMouseOverButton )
      ::bMouseOverButton := .F.
      Invalidaterect( ::handle, .f. )
   ENDIF

   RETURN nil

METHOD SetDefaultColor( lPaint ) CLASS HBUTTONEx
   DEFAULT lPaint TO .f.

   ::m_crColors[ BTNST_COLOR_BK_IN ]    := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_IN ]    := GetSysColor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_OUT ]   := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_OUT ]   := GetSysColor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_FOCUS ] := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_FOCUS ] := GetSysColor( COLOR_BTNTEXT )
   IF lPaint
      Invalidaterect( ::handle, .f. )
   ENDIF
   RETURN Self


METHOD SetColorEx( nIndex, nColor, lPaint ) CLASS HBUTTONEx
   DEFAULT lPaint TO .f.
   IF nIndex > BTNST_MAX_COLORS
      RETURN - 1
   ENDIF
   ::m_crColors[ nIndex ]    := nColor
   IF lPaint
      Invalidaterect( ::handle, .f. )
   ENDIF
   RETURN 0


METHOD Paint( lpDis ) CLASS HBUTTONEx

   LOCAL drawInfo := GetDrawItemInfo( lpDis )

   LOCAL dc := drawInfo[ 3 ]

   LOCAL bIsPressed     := HWG_BITAND( drawInfo[ 9 ], ODS_SELECTED ) != 0
   LOCAL bIsFocused     := HWG_BITAND( drawInfo[ 9 ], ODS_FOCUS ) != 0
   LOCAL bIsDisabled    := HWG_BITAND( drawInfo[ 9 ], ODS_DISABLED ) != 0
   LOCAL bDrawFocusRect := ! HWG_BITAND( drawInfo[ 9 ], ODS_NOFOCUSRECT ) != 0
   LOCAL focusRect

   LOCAL captionRect
   LOCAL centerRect
   LOCAL bHasTitle
   LOCAL itemRect    := copyrect( { drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ] } )

   LOCAL state

   LOCAL crColor
   LOCAL brBackground
   LOCAL br
   LOCAL brBtnShadow
   LOCAL uState
   LOCAL captionRectWidth
   LOCAL captionRectHeight
   LOCAL centerRectWidth
   LOCAL centerRectHeight
   LOCAL uAlign, uStyleTmp


   IF ( ::m_bFirstTime )

      ::m_bFirstTime := .F.

      IF ( ISTHEMEDLOAD() )

         IF ValType( ::hTheme ) == "P"
            HB_CLOSETHEMEDATA( ::htheme )
         ENDIF
         ::hTheme := nil
         ::hTheme := hb_OpenThemeData( ::handle, "BUTTON" )

      ENDIF
   ENDIF

   IF ! Empty( ::hTheme )
      ::Themed := .T.
   ENDIF

   SetBkMode( dc, TRANSPARENT )
   IF ( ::m_bDrawTransparent )
//        ::PaintBk(DC)
   ENDIF


   // Prepare draw... paint button background

   IF ::Themed

      state := IF( bIsPressed, PBS_PRESSED, PBS_NORMAL )

      IF state == PBS_NORMAL

         IF bIsFocused
            state := PBS_DEFAULTED
         ENDIF
         IF ::bMouseOverButton
            state := PBS_HOT
         ENDIF
      ENDIF
      hb_DrawThemeBackground( ::hTheme, dc, BP_PUSHBUTTON, state, itemRect, Nil )
   ELSE

      IF bIsFocused

         br := HBRUSH():Add( RGB( 0, 0, 0 ) )
         FrameRect( dc, itemRect, br:handle )
         InflateRect( @itemRect, - 1, - 1 )

      ENDIF

      crColor := GetSysColor( COLOR_BTNFACE )

      brBackground := HBRUSH():Add( crColor )

      FillRect( dc, itemRect, brBackground:handle )

      IF ( bIsPressed )
         brBtnShadow := HBRUSH():Add( GetSysColor( COLOR_BTNSHADOW ) )
         FrameRect( dc, itemRect, brBtnShadow:handle )

      ELSE

         uState := HWG_BITOR( ;
                              HWG_BITOR( DFCS_BUTTONPUSH, ;
                                         IF( ::bMouseOverButton, DFCS_HOT, 0 ) ), ;
                              IF( bIsPressed, DFCS_PUSHED, 0 ) )

         DrawFrameControl( dc, itemRect, DFC_BUTTON, uState )
      ENDIF

   ENDIF

//      if ::iStyle ==  ST_ALIGN_HORIZ
//         uAlign := DT_RIGHT
//      else
//         uAlign := DT_LEFT
//      endif
//
//      IF VALTYPE( ::hbitmap ) != "N"
//         uAlign := DT_CENTER
//      ENDIF
   uAlign := DT_LEFT
   IF ValType( ::hbitmap ) == "N"
      uAlign := DT_CENTER
   ENDIF
   IF ValType( ::hicon ) == "N"
      uAlign := DT_CENTER
   ENDIF

//             DT_CENTER | DT_VCENTER | DT_SINGLELINE
//   uAlign += DT_WORDBREAK + DT_CENTER + DT_CALCRECT +  DT_VCENTER + DT_SINGLELINE  // DT_SINGLELINE + DT_VCENTER + DT_WORDBREAK
   uAlign += DT_VCENTER
   uStyleTmp := HWG_GETWINDOWSTYLE( ::handle )

   #ifdef __XHARBOUR
      IF hb_inline( uStyleTmp ) { ULONG ulStyle = ( ULONG ) hb_parnl( 1 ) ; hb_retl( ulStyle & BS_MULTILINE ) ; }
    #else
       IF hb_BitAnd( uStyleTmp, BS_MULTILINE ) != 0
       #endif
       uAlign += DT_WORDBREAK
    ELSE
       uAlign += DT_SINGLELINE
    ENDIF



    captionRect := { drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ] }

    bHasTitle := ValType( ::caption ) == "C" .and. ! Empty( ::Caption )

    DrawTheIcon( ::handle, dc, bHasTitle, @itemRect, @captionRect, bIsPressed, bIsDisabled, ::hIcon, ::hbitmap, ::iStyle )

    IF ( bHasTitle )

       // If button is pressed then "press" title also
       IF bIsPressed .and. ! ::Themed
          OffsetRect( @captionRect, 1, 1 )
       ENDIF

       // Center text
       centerRect := captionRect

       centerRect := copyrect( captionRect )



       IF ValType( ::hicon ) == "N" .or. ValType( ::hbitmap ) == "N"
          DrawText( dc, ::caption, captionRect[ 1 ], captionRect[ 2 ], captionRect[ 3 ], captionRect[ 4 ], uAlign + DT_CALCRECT, @captionRect )
       ELSE
          uAlign += DT_CENTER // NANDO
       ENDIF


       captionRectWidth  := captionRect[ 3 ] - captionRect[ 1 ]
       captionRectHeight := captionRect[ 4 ] - captionRect[ 2 ]
       centerRectWidth   := centerRect[ 3 ] - centerRect[ 1 ]
       centerRectHeight  := centerRect[ 4 ] - centerRect[ 2 ]
//ok      OffsetRect( @captionRect, ( centerRectWidth - captionRectWidth ) / 2, ( centerRectHeight - captionRectHeight ) / 2 )
//      OffsetRect( @captionRect, ( centerRectWidth - captionRectWidth ) / 2, ( centerRectHeight - captionRectHeight ) / 2 )
//      OffsetRect( @captionRect, ( centerRectWidth - captionRectWidth ) / 2, ( centerRectHeight - captionRectHeight ) / 2 )
       OffsetRect( @captionRect, 0, ( centerRectHeight - captionRectHeight ) / 2 )


/*      SetBkMode( dc, TRANSPARENT )
      IF ( bIsDisabled )

         OffsetRect( @captionRect, 1, 1 )
         SetTextColor( DC, GetSysColor( COLOR_3DHILIGHT ) )
         DrawText( DC, ::caption, captionRect[ 1 ], captionRect[ 2 ], captionRect[ 3 ], captionRect[ 4 ], DT_WORDBREAK + DT_CENTER, @captionRect )
         OffsetRect( @captionRect, - 1, - 1 )
         SetTextColor( DC, GetSysColor( COLOR_3DSHADOW ) )
         DrawText( DC, ::caption, captionRect[ 1 ], captionRect[ 2 ], captionRect[ 3 ], captionRect[ 4 ], DT_WORDBREAK + DT_VCENTER + DT_CENTER, @captionRect )

      ELSE

         IF ( ::bMouseOverButton .or. bIsPressed )

            SetTextColor( DC, ::m_crColors[ BTNST_COLOR_FG_IN ] )
            SetBkColor( DC, ::m_crColors[ BTNST_COLOR_BK_IN ] )

         ELSE

            IF ( bIsFocused )

               SetTextColor( DC, ::m_crColors[ BTNST_COLOR_FG_FOCUS ] )
               SetBkColor( DC, ::m_crColors[ BTNST_COLOR_BK_FOCUS ] )

            ELSE

               SetTextColor( DC, ::m_crColors[ BTNST_COLOR_FG_OUT ] )
               SetBkColor( DC, ::m_crColors[ BTNST_COLOR_BK_OUT ] )
            ENDIF
         ENDIF
      ENDIF
  */

       IF ::Themed

          hb_DrawThemeText( ::hTheme, dc, BP_PUSHBUTTON, IF( bIsDisabled, PBS_DISABLED, PBS_NORMAL ), ;
                            ::caption, ;
                            uAlign, ;
                            0, captionRect )

       ELSE

          SetBkMode( dc, TRANSPARENT )

          IF ( bIsDisabled )

             OffsetRect( @captionRect, 1, 1 )
             SetTextColor( dc, GetSysColor( COLOR_3DHILIGHT ) )
             DrawText( dc, ::caption, @captionRect[ 1 ], @captionRect[ 2 ], @captionRect[ 3 ], @captionRect[ 4 ], uAlign )
             OffsetRect( @captionRect, - 1, - 1 )
             SetTextColor( dc, GetSysColor( COLOR_3DSHADOW ) )
             DrawText( dc, ::caption, @captionRect[ 1 ], @captionRect[ 2 ], @captionRect[ 3 ], @captionRect[ 4 ], uAlign )
             // if
          ELSE

             //          SetTextColor( dc, GetSysColor( COLOR_BTNTEXT ) )
//            SetBkColor( dc, GetSysColor( COLOR_BTNFACE ) )
//            DrawText( dc, ::caption, @captionRect[ 1 ], @captionRect[ 2 ], @captionRect[ 3 ], @captionRect[ 4 ], uAlign )
             IF ( ::bMouseOverButton .or. bIsPressed )

                SetTextColor( dc, ::m_crColors[ BTNST_COLOR_FG_IN ] )
                SetBkColor( dc, ::m_crColors[ BTNST_COLOR_BK_IN ] )

             ELSE

                IF ( bIsFocused )

                   SetTextColor( dc, ::m_crColors[ BTNST_COLOR_FG_FOCUS ] )
                   SetBkColor( dc, ::m_crColors[ BTNST_COLOR_BK_FOCUS ] )

                ELSE

                   SetTextColor( dc, ::m_crColors[ BTNST_COLOR_FG_OUT ] )
                   SetBkColor( dc, ::m_crColors[ BTNST_COLOR_BK_OUT ] )
                ENDIF
             ENDIF
             DrawText( dc, ::caption, @captionRect[ 1 ], @captionRect[ 2 ], @captionRect[ 3 ], @captionRect[ 4 ], uAlign )

          ENDIF
       ENDIF
    ENDIF

    // Draw the focus rect
    IF bIsFocused .and. bDrawFocusRect

       focusRect := COPYRECT( itemRect )
       InflateRect( @focusRect, - 3, - 3 )
       DrawFocusRect( dc, focusRect )
    ENDIF

    RETURN nil

 METHOD PAINTBK( hdc ) CLASS HBUTTONEx

    LOCAL clDC := HclientDc():New( ::oparent:handle )
    LOCAL rect, rect1

    rect := GetClientRect( ::handle )

    rect1 := GetWindowRect( ::handle )
    ScreenToClient( ::oparent:handle, rect1 )

    IF ValType( ::m_dcBk ) == "U"

       ::m_dcBk := hdc():New()
       ::m_dcBk:CreateCompatibleDC( clDC:m_hDC )
       ::m_bmpBk := CreateCompatibleBitmap( clDC:m_hDC, rect[ 3 ] - rect[ 1 ], rect[ 4 ] - rect[ 2 ] )
       ::m_pbmpOldBk = ::m_dcBk:SelectObject( ::m_bmpBk )
       ::m_dcBk:BitBlt( 0, 0, rect[ 3 ] - rect[ 1 ], rect[ 4 ] - rect[ 4 ], clDC:m_hDc, rect1[ 1 ], rect1[ 2 ], SRCCOPY )
    ENDIF

    BitBlt( hdc, 0, 0, rect[ 3 ] - rect[ 1 ], rect[ 4 ] - rect[ 4 ], ::m_dcBk:m_hDC, 0, 0, SRCCOPY )
    RETURN Self




 CLASS HGroup INHERIT HControl

 CLASS VAR winclass   INIT "BUTTON"

    METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
                cCaption, oFont, bInit, bSize, bPaint, tcolor, bColor )
    METHOD Activate()

 ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, ;
            oFont, bInit, bSize, bPaint, tcolor, bColor ) CLASS HGroup

   nStyle := Hwg_BitOr( IIf( nStyle == NIL, 0, nStyle ), BS_GROUPBOX )
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
              oFont, bInit, bSize, bPaint,, tcolor, bColor )

   ::title   := cCaption
   ::Activate()

   RETURN Self

METHOD Activate CLASS HGroup
   IF ! Empty( ::oParent:handle )
      ::handle := CreateButton( ::oParent:handle, ::id, ::style, ;
                                ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
                                ::title )
      ::Init()
   ENDIF
   RETURN NIL

// HLine

CLASS HLine INHERIT HControl

CLASS VAR winclass   INIT "STATIC"

   DATA lVert
   DATA oPenLight, oPenGray

   METHOD New( oWndParent, nId, lVert, nLeft, nTop, nLength, bSize )
   METHOD Activate()
   METHOD Paint()

ENDCLASS


METHOD New( oWndParent, nId, lVert, nLeft, nTop, nLength, bSize ) CLASS HLine

   Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop,,,,, ;
              bSize, { | o, lp | o:Paint( lp ) } )

   ::title := ""
   ::lVert := IIf( lVert == NIL, .F., lVert )
   IF ::lVert
      ::nWidth  := 10
      ::nHeight := IIf( nLength == NIL, 20, nLength )
   ELSE
      ::nWidth  := IIf( nLength == NIL, 20, nLength )
      ::nHeight := 10
   ENDIF

   ::oPenLight := HPen():Add( BS_SOLID, 1, GetSysColor( COLOR_3DHILIGHT ) )
   ::oPenGray  := HPen():Add( BS_SOLID, 1, GetSysColor( COLOR_3DSHADOW  ) )

   ::Activate()

   RETURN Self

METHOD Activate CLASS HLine
   IF ! Empty( ::oParent:handle )
      ::handle := CreateStatic( ::oParent:handle, ::id, ::style, ;
                                ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
   RETURN NIL

METHOD Paint( lpdis ) CLASS HLine
   LOCAL drawInfo := GetDrawItemInfo( lpdis )
   LOCAL hDC := drawInfo[ 3 ]
   LOCAL x1  := drawInfo[ 4 ], y1 := drawInfo[ 5 ]
   LOCAL x2  := drawInfo[ 6 ], y2 := drawInfo[ 7 ]

   SelectObject( hDC, ::oPenLight:handle )
   IF ::lVert
      // DrawEdge( hDC,x1,y1,x1+2,y2,EDGE_SUNKEN,BF_RIGHT )
      DrawLine( hDC, x1 + 1, y1, x1 + 1, y2 )
   ELSE
      // DrawEdge( hDC,x1,y1,x2,y1+2,EDGE_SUNKEN,BF_RIGHT )
      DrawLine( hDC, x1 , y1 + 1, x2, y1 + 1 )
   ENDIF

   SelectObject( hDC, ::oPenGray:handle )
   IF ::lVert
      DrawLine( hDC, x1, y1, x1, y2 )
   ELSE
      DrawLine( hDC, x1, y1, x2, y1 )
   ENDIF

   RETURN NIL



   init PROCEDURE starttheme()
   INITTHEMELIB()

   EXIT PROCEDURE endtheme()
   ENDTHEMELIB()
