/*
 * $Id: $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * ButtonEx, HGroupEx
 *
 * Copyright 2007 Luiz Rafael Culik Guimaraes <luiz at xharbour.com.br >
 * www - http://sites.uol.com.br/culikr/
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#translate :hBitmap       => :m_csbitmaps\[ 1 \]
#translate :dwWidth       => :m_csbitmaps\[ 2 \]
#translate :dwHeight      => :m_csbitmaps\[ 3 \]
#translate :hMask         => :m_csbitmaps\[ 4 \]
#translate :crTransparent => :m_csbitmaps\[ 5 \]

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

CLASS HButtonEX INHERIT HButton

   DATA hBitmap
   DATA hIcon
   DATA m_dcBk
   DATA m_bFirstTime INIT .T.
   DATA Themed INIT .F.
   // DATA lnoThemes  INIT .F. HIDDEN
   DATA m_crColors INIT Array( 6 )
   DATA m_crBrush INIT Array( 6 )
   DATA hTheme
   // DATA Caption
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
   DATA PictureMargin INIT 0
   DATA m_bDrawTransparent INIT .f.
   DATA iStyle
   DATA m_bmpBk, m_pbmpOldBk
   DATA bMouseOverButton INIT .f.

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
         cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
         tcolor, bColor, hBitmap, iStyle, hicon, Transp, bGFocus, nPictureMargin, lnoThemes, bOther )
   METHOD Paint( lpDis )
   METHOD SetBitmap( hBitMap )
   METHOD SetIcon( hIcon )
   METHOD Init()
   METHOD onevent( msg, wParam, lParam )
   METHOD CancelHover()
   METHOD END()
   METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
         cTooltip, tcolor, bColor, cCaption, hBitmap, iStyle, hIcon, bGFocus, nPictureMargin )
   METHOD PaintBk( hdc )
   METHOD SetColor( tcolor, bcolor ) INLINE ::SetDefaultColor( tcolor, bcolor ) //, ::SetDefaultColor( .T. )
   METHOD SetDefaultColor( tColor, bColor, lPaint )
   // METHOD SetDefaultColor( lRepaint )
   METHOD SetColorEx( nIndex, nColor, lPaint )
   //METHOD SetText( c ) INLINE ::title := c, ::caption := c, ;
   METHOD SetText( c ) INLINE ::title := c,  ;
         RedrawWindow( ::Handle, RDW_NOERASE + RDW_INVALIDATE ),;
         IIF( ::oParent != NIL .AND. isWindowVisible( ::Handle ) ,;
         InvalidateRect( ::oParent:Handle, 1 , ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight  ), ), ;
         SetWindowText( ::handle, ::title )
//   METHOD SaveParentBackground()

END CLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
      tcolor, bColor, hBitmap, iStyle, hicon, Transp, bGFocus, nPictureMargin, lnoThemes, bOther ) CLASS HButtonEx

   DEFAULT iStyle TO ST_ALIGN_HORIZ
   DEFAULT Transp TO .T.
   DEFAULT nPictureMargin TO 0
   DEFAULT lnoThemes  TO .F.
   ::m_bLButtonDown := .f.
   ::m_bSent := .f.
   ::m_bLButtonDown := .f.
   ::m_bIsToggle := .f.

   cCaption := IIF( cCaption = NIL, "", cCaption )
   ::Caption := cCaption
   ::iStyle              := iStyle
   ::hBitmap             := IIF( EMPTY( hBitmap ), NIL, hBitmap )
   ::hicon               := IIF( EMPTY( hicon ), NIL, hIcon )
   ::m_bDrawTransparent  := Transp
   ::PictureMargin       := nPictureMargin
   ::lnoThemes           := lnoThemes
   ::bOther := bOther
   bPaint := { | o, p | o:paint( p ) }

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
         cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
         tcolor, bColor, bGFocus )

   RETURN Self

METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
      cTooltip, tcolor, bColor, cCaption, hBitmap, iStyle, hIcon, bGFocus, nPictureMargin ) CLASS HButtonEx

   DEFAULT iStyle TO ST_ALIGN_HORIZ
   DEFAULT nPictureMargin TO 0
   bPaint := { | o, p | o:paint( p ) }
   ::m_bLButtonDown := .f.
   ::m_bIsToggle := .f.
   ::m_bLButtonDown := .f.
   ::m_bSent := .f.
   ::title := cCaption
   ::Caption := cCaption
   ::iStyle  := iStyle
   ::hBitmap := hBitmap
   ::hIcon   := hIcon
   ::m_crColors[ BTNST_COLOR_BK_IN ]    := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_IN ]    := GetSysColor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_OUT ]   := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_OUT ]   := GetSysColor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_FOCUS ] := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_FOCUS ] := GetSysColor( COLOR_BTNTEXT )
   ::PictureMargin                      := nPictureMargin

   ::Super:Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
         cTooltip, tcolor, bColor, cCaption, hBitmap, iStyle, hIcon, bGFocus  )
   ::title := cCaption
   ::Caption := cCaption
   
   

   RETURN Self

METHOD SetBitmap( hBitMap ) CLASS HButtonEX

   DEFAULT hBitmap TO ::hBitmap
   IF ValType( hBitmap ) == "N"
      ::hBitmap := hBitmap
      SendMessage( ::handle, BM_SETIMAGE, IMAGE_BITMAP, ::hBitmap )
      REDRAWWINDOW( ::Handle, RDW_NOERASE + RDW_INVALIDATE + RDW_INTERNALPAINT )
   ENDIF

   RETURN Self

METHOD SetIcon( hIcon ) CLASS HButtonEX

   DEFAULT hIcon TO ::hIcon
   IF ValType( ::hIcon ) == "N"
      ::hIcon := hIcon
      SendMessage( ::handle, BM_SETIMAGE, IMAGE_ICON, ::hIcon )
      REDRAWWINDOW( ::Handle, RDW_NOERASE + RDW_INVALIDATE + RDW_INTERNALPAINT)
   ENDIF

   RETURN Self

METHOD END() CLASS HButtonEX

   Super:END()

   RETURN Self

METHOD INIT() CLASS HButtonEx
   LOCAL nbs

   IF ! ::lInit
      ::nHolder := 1
      //SetWindowObject( ::handle, Self )
      //HWG_INITBUTTONPROC( ::handle )
      // call in HBUTTON CLASS
      //::SetDefaultColor( ,, .F. )
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
   LOCAL pos, nID, oParent, nEval

   IF msg == WM_THEMECHANGED
      IF ::Themed
         IF ValType( ::hTheme ) == "P"
            HB_CLOSETHEMEDATA( ::htheme )
            ::hTheme       := NIL
            //::m_bFirstTime := .T.
         ENDIF
         ::Themed := .F.
      ENDIF
      ::m_bFirstTime := .T.
      RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
      RETURN 0
   ELSEIF msg == WM_ERASEBKGND
      RETURN 0
   ELSEIF msg == BM_SETSTYLE
      RETURN BUTTONEXONSETSTYLE( wParam, lParam, ::handle, @::m_bIsDefault )
   ELSEIF msg == WM_MOUSEMOVE
      IF wParam = MK_LBUTTON
         pt[ 1 ] := LOWORD( lParam )
         pt[ 2 ] := HIWORD( lParam )
         acoor := ClientToScreen( ::handle, pt[ 1 ], pt[ 2 ] )
         rectButton := GetWindowRect( ::handle )
         IF ( ! PtInRect( rectButton, acoor ) )
            SendMessage( ::handle, BM_SETSTATE, ::m_bToggled, 0 )
            ::bMouseOverButton := .F.
            RETURN 0
         ENDIF
      ENDIF
      IF ( ! ::bMouseOverButton )
         ::bMouseOverButton := .T.
         Invalidaterect( ::handle, .f. )
         TRACKMOUSEVENT( ::handle )
      ENDIF
      RETURN 0
   ELSEIF msg == WM_MOUSELEAVE
      ::CancelHover()
      RETURN 0
   ENDIF
   IF ::bOther != NIL
      IF ( nEval := Eval( ::bOther, Self, msg, wParam, lParam )) != -1 .AND. nEval != NIL
         RETURN 0
      ENDIF
   ENDIF
   IF msg == WM_KEYDOWN
#ifdef __XHARBOUR__
      IF hb_BitIsSet( PtrtoUlong( lParam ), 30 )  // the key was down before ?
#else
      IF hb_BitTest( lParam, 30 )   // the key was down before ?
#endif
         RETURN 0
      ENDIF
      IF ( ( wParam == VK_SPACE ) .or. ( wParam == VK_RETURN ) )
         /*
         IF ( ::GetParentForm( Self ):Type < WND_DLG_RESOURCE )
            SendMessage( ::handle, WM_LBUTTONDOWN, 0, MAKELPARAM( 1, 1 ) )
             ELSE
            SendMessage( ::handle, WM_LBUTTONDOWN, 0, MAKELPARAM( 1, 1 ) )
         ENDIF
         */
         SendMessage( ::handle, WM_LBUTTONDOWN, 0, MAKELPARAM( 1, 1 ) )
         RETURN 0
      ENDIF
      IF wParam == VK_LEFT .OR. wParam == VK_UP
         GetSkip( ::oParent, ::handle, , - 1 )
         RETURN 0
      ELSEIF wParam == VK_RIGHT .OR. wParam == VK_DOWN
         GetSkip( ::oParent, ::handle, , 1 )
         RETURN 0
      ELSEIF  wParam = VK_TAB
         GetSkip( ::oparent, ::handle, , iif( IsCtrlShift(.f., .t.), -1, 1)  )
      ENDIF
      ProcKeyList( Self, wParam )
   ELSEIF msg == WM_SYSKEYUP .OR. ( msg == WM_KEYUP .AND.;
         ASCAN( { VK_SPACE, VK_RETURN, VK_ESCAPE }, wParam ) = 0 )
      IF CheckBit( lParam, 23 ) .AND. ( wParam > 95 .AND. wParam < 106 )
         wParam -= 48
      ENDIF
      IF ! EMPTY( ::title) .AND. ( pos := At( "&", ::title ) ) > 0 .AND. wParam == Asc( Upper( SubStr( ::title, ++ pos, 1 ) ) )
         IF ValType( ::bClick ) == "B" .OR. ::id < 3
            SendMessage( ::oParent:handle, WM_COMMAND, makewparam( ::id, BN_CLICKED ), ::handle )
         ENDIF
      ELSEIF ( nID := Ascan( ::oparent:acontrols, { | o | IIF( VALTYPE( o:title ) = "C", ( pos := At( "&", o:title )) > 0 .AND. ;
            wParam == Asc( Upper( SubStr( o:title, ++ pos, 1 ) )), ) } )) > 0
         IF __ObjHasMsg( ::oParent:aControls[ nID ],"BCLICK") .AND.;
               ValType( ::oParent:aControls[ nID ]:bClick ) == "B" .OR. ::oParent:aControls[ nID]:id < 3
            SendMessage( ::oParent:handle, WM_COMMAND, makewparam( ::oParent:aControls[ nID ]:id, BN_CLICKED ), ::oParent:aControls[ nID ]:handle )
         ENDIF
      ENDIF
      IF msg != WM_SYSKEYUP
         RETURN 0
      ENDIF
   ELSEIF msg == WM_KEYUP
      IF ( wParam == VK_SPACE .OR. wParam == VK_RETURN  )
         ::bMouseOverButton := .T.
         SendMessage( ::handle, WM_LBUTTONUP, 0, MAKELPARAM( 1, 1 ) )
         ::bMouseOverButton := .F.
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
            ::m_bToggled := ! ::m_bToggled
            InvalidateRect( ::handle, 0 )
            SendMessage( ::handle, BM_SETSTATE, 0, 0 )
            ::m_bLButtonDown := .T.
         ENDIF
      ENDIF
      IF ( ! ::bMouseOverButton )
         SETFOCUS( 0 )
         ::SETFOCUS()
         RETURN 0
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
      IF wParam = VK_ESCAPE .AND. ( GETDLGMESSAGE( lParam ) = WM_KEYDOWN .OR. GETDLGMESSAGE( lParam ) = WM_KEYUP )
         oParent := ::GetParentForm()
         IF ! ProcKeyList( Self, wParam )  .AND. ( oParent:Type < WND_DLG_RESOURCE .OR. ! oParent:lModal )
            SendMessage( oParent:handle, WM_COMMAND, makewparam( IDCANCEL, 0 ), ::handle )
         ELSEIF oParent:FindControl( IDCANCEL ) != NIL .AND. ! oParent:FindControl( IDCANCEL ):IsEnabled() .AND. oParent:lExitOnEsc
            SendMessage( oParent:handle, WM_COMMAND, makewparam( IDCANCEL, 0 ), ::handle )
            RETURN 0
         ENDIF
      ENDIF
      RETURN IIF( wParam = VK_ESCAPE, - 1, ButtonGetDlgCode( lParam ) )
   ELSEIF msg == WM_SYSCOLORCHANGE
      ::SetDefaultColors()
   ELSEIF msg == WM_CHAR
      IF wParam == VK_RETURN .or. wParam == VK_SPACE
         IF ( ::m_bIsToggle )
            ::m_bToggled := ! ::m_bToggled
            InvalidateRect( ::handle, 0 )
         ELSE
            SendMessage( ::handle, BM_SETSTATE, 1, 0 )
            //::m_bSent := .t.
         ENDIF
         // remove because repet click  2 times
         //SendMessage( ::oParent:handle, WM_COMMAND, makewparam( ::id, BN_CLICKED ), ::handle )
      ELSEIF wParam == VK_ESCAPE
         SendMessage( ::oParent:handle, WM_COMMAND, makewparam( IDCANCEL, BN_CLICKED ), ::handle )
      ENDIF
      RETURN 0
   ENDIF

   RETURN - 1

METHOD CancelHover() CLASS HBUTTONEx

   IF ( ::bMouseOverButton ) .AND. ::id != IDOK //NANDO
      ::bMouseOverButton := .F.
      IF !::lflat
         Invalidaterect( ::handle, .f. )
      ELSE
         InvalidateRect( ::oParent:Handle, 1 , ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight  )
      ENDIF
   ENDIF

   RETURN NIL

METHOD SetDefaultColor( tColor, bColor, lPaint ) CLASS HBUTTONEx

   DEFAULT lPaint TO .f.

   IF !EMPTY( tColor )
      ::tColor := tColor
   ENDIF
   IF !EMPTY( bColor )
      ::bColor := bColor
   ENDIF
   ::m_crColors[ BTNST_COLOR_BK_IN ]    := IIF( ::bColor = NIL, GetSysColor( COLOR_BTNFACE ), ::bColor )
   ::m_crColors[ BTNST_COLOR_FG_IN ]    := IIF( ::tColor = NIL, GetSysColor( COLOR_BTNTEXT ), ::tColor )
   ::m_crColors[ BTNST_COLOR_BK_OUT ]   := IIF( ::bColor = NIL, GetSysColor( COLOR_BTNFACE ), ::bColor )
   ::m_crColors[ BTNST_COLOR_FG_OUT ]   := IIF( ::tColor = NIL, GetSysColor( COLOR_BTNTEXT ), ::tColor )
   ::m_crColors[ BTNST_COLOR_BK_FOCUS ] := IIF( ::bColor = NIL, GetSysColor( COLOR_BTNFACE ), ::bColor )
   ::m_crColors[ BTNST_COLOR_FG_FOCUS ] := IIF( ::tColor = NIL, GetSysColor( COLOR_BTNTEXT ), ::tColor )
   //
   ::m_crBrush[ BTNST_COLOR_BK_IN ] := HBrush():Add( ::m_crColors[ BTNST_COLOR_BK_IN ] )
   ::m_crBrush[ BTNST_COLOR_BK_OUT ] := HBrush():Add( ::m_crColors[ BTNST_COLOR_BK_OUT ] )
   ::m_crBrush[ BTNST_COLOR_BK_FOCUS ] := HBrush():Add( ::m_crColors[ BTNST_COLOR_BK_FOCUS ] )
   /*
   ::m_crColors[ BTNST_COLOR_BK_IN ]    := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_IN ]    := GetSysColor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_OUT ]   := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_OUT ]   := GetSysColor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_FOCUS ] := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_FOCUS ] := GetSysColor( COLOR_BTNTEXT )
   */
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
   LOCAL itemRect := copyrect( { drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ] } )
   LOCAL state
   LOCAL crColor
   LOCAL brBackground
   LOCAL br
   LOCAL brBtnShadow
   LOCAL uState
   LOCAL captionRectHeight
   LOCAL centerRectHeight
   //LOCAL captionRectWidth
   //LOCAL centerRectWidth
   LOCAL uAlign, uStyleTmp
   LOCAL aTxtSize := IIf( ! Empty( ::caption ), TxtRect( ::caption, Self ), { 0, 0 } )
   LOCAL aBmpSize := IIf( ! Empty( ::hbitmap ), GetBitmapSize( ::hbitmap ), { 0, 0 } )
   LOCAL itemRectOld, saveCaptionRect, bmpRect, itemRect1, captionRect1, fillRect
   LOCAL lMultiLine, nHeight := 0

   IF ( ::m_bFirstTime )
      ::m_bFirstTime := .F.
      IF ( ISTHEMEDLOAD() )
         IF ValType( ::hTheme ) == "P"
            HB_CLOSETHEMEDATA( ::htheme )
         ENDIF
         ::hTheme := NIL
         IF ::WindowsManifest
            ::hTheme := hb_OpenThemeData( ::handle, "BUTTON" )
         ENDIF
      ENDIF
   ENDIF
   IF ! Empty( ::hTheme ) .AND. !::lnoThemes
       ::Themed := .T.
   ENDIF
   SetBkMode( dc, TRANSPARENT )
   IF ( ::m_bDrawTransparent )
      // ::PaintBk(DC)
   ENDIF

   // Prepare draw... paint button background
   IF ::Themed
      IF bIsDisabled
         state :=  PBS_DISABLED
      ELSE
         state := IIF( bIsPressed, PBS_PRESSED, PBS_NORMAL )
      ENDIF
      IF state == PBS_NORMAL
         IF bIsFocused
            state := PBS_DEFAULTED
         ENDIF
         IF ::bMouseOverButton .OR. ::id = IDOK
            state := PBS_HOT
         ENDIF
      ENDIF
      IF ! ::lFlat
         hb_DrawThemeBackground( ::hTheme, dc, BP_PUSHBUTTON, state, itemRect, NIL )
      ELSEIF bIsDisabled
         FillRect( dc, itemRect[ 1 ] + 1, itemRect[ 2 ] + 1, itemRect[ 3 ] - 1, itemRect[ 4 ] - 1, GetSysColorBrush( GetSysColor( COLOR_BTNFACE ) ) )
      ELSEIF ::bMouseOverButton .OR. bIsFocused
         hb_DrawThemeBackground( ::hTheme, dc, BP_PUSHBUTTON  , state, itemRect, NIL ) // + PBS_DEFAULTED
      ENDIF
   ELSE
      IF bIsFocused .OR. ::id = IDOK
         br := HBRUSH():Add( RGB( 1, 1, 1 ) )
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
         IF ! ::lFlat .OR. ::bMouseOverButton
            uState := HWG_BITOR( ;
                  HWG_BITOR( DFCS_BUTTONPUSH, ;
                  IIF( ::bMouseOverButton, DFCS_HOT, 0 ) ), ;
                  IIF( bIsPressed, DFCS_PUSHED, 0 ) )
            DrawFrameControl( dc, itemRect, DFC_BUTTON, uState )
         ELSEIF bIsFocused
            uState := HWG_BITOR( ;
                  HWG_BITOR( DFCS_BUTTONPUSH + DFCS_MONO ,; // DFCS_FLAT , ;
                  IIF( ::bMouseOverButton, DFCS_HOT, 0 ) ), ;
                  IIF( bIsPressed, DFCS_PUSHED, 0 ) )
            DrawFrameControl( dc, itemRect, DFC_BUTTON, uState )
         ENDIF
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

   uAlign := 0 //DT_LEFT
   IF ValType( ::hbitmap ) == "N" .OR. ValType( ::hicon ) == "N"
      uAlign := DT_VCENTER // + DT_CENTER
   ENDIF
   /*
   IF ValType( ::hicon ) == "N"
      uAlign := DT_CENTER
   ENDIF
   */
   IF uAlign = DT_VCENTER  //!= DT_CENTER + DT_VCENTER
      uAlign := IIF( HWG_BITAND( ::Style, BS_TOP ) != 0, DT_TOP, DT_VCENTER )
      uAlign += IIF( HWG_BITAND( ::Style, BS_BOTTOM ) != 0, DT_BOTTOM - DT_VCENTER , 0 )
      uAlign += IIF( HWG_BITAND( ::Style, BS_LEFT ) != 0, DT_LEFT, DT_CENTER )
      uAlign += IIF( HWG_BITAND( ::Style, BS_RIGHT ) != 0, DT_RIGHT - DT_CENTER, 0 )
   ELSE
      uAlign := IIF( uAlign = 0, DT_CENTER + DT_VCENTER, uAlign )
   ENDIF

   //             DT_CENTER | DT_VCENTER | DT_SINGLELINE
   //   uAlign += DT_WORDBREAK + DT_CENTER + DT_CALCRECT +  DT_VCENTER + DT_SINGLELINE  // DT_SINGLELINE + DT_VCENTER + DT_WORDBREAK
   //  uAlign += DT_VCENTER
   uStyleTmp := HWG_GETWINDOWSTYLE( ::handle )
   itemRectOld := aclone(itemRect)
   IF hb_BitAnd( uStyleTmp, BS_MULTILINE ) != 0 .AND. !EMPTY(::caption) .AND. ;
         INT( aTxtSize[ 2 ] ) !=  INT( DrawText( dc, ::caption, itemRect[ 1 ], itemRect[ 2 ],;
         itemRect[ 3 ] - IIF( ::iStyle = ST_ALIGN_VERT, 0, aBmpSize[ 1 ] + 8 ),;
         itemRect[ 4 ], DT_CALCRECT + uAlign + DT_WORDBREAK, itemRectOld ) )
      // *-INT( aTxtSize[ 2 ] ) !=  INT( DrawText( dc, ::caption, itemRect,  DT_CALCRECT + uAlign + DT_WORDBREAK ) )
      uAlign += DT_WORDBREAK
      lMultiline := .T.
      drawInfo[ 4 ] += 2
      drawInfo[ 6 ] -= 2
      itemRect[ 1 ] += 2
      itemRect[ 3 ] -= 2
      aTxtSize[ 1 ] := itemRectold[ 3 ] - itemRectOld[ 1 ] + 1
      aTxtSize[ 2 ] := itemRectold[ 4 ] - itemRectold[ 2 ] + 1
   ELSE
       uAlign += DT_SINGLELINE
       lMultiline := .F.
   ENDIF

   captionRect := { drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ] }
   //
   IF ( ValType( ::hbitmap ) == "N" .OR. ValType( ::hicon ) == "N" ) .AND. lMultiline
      IF ::iStyle = ST_ALIGN_HORIZ
         captionRect := { drawInfo[ 4 ] + ::PictureMargin , drawInfo[ 5 ], drawInfo[ 6 ] , drawInfo[ 7 ] }
      ELSEIF ::iStyle = ST_ALIGN_HORIZ_RIGHT
         captionRect := { drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ] - ::PictureMargin, drawInfo[ 7 ] }
      ELSEIF ::iStyle = ST_ALIGN_VERT
      ENDIF
   ENDIF

   itemRectOld := AClone( itemRect )

   IF !EMPTY( ::caption ) .AND. !EMPTY( ::hbitmap )  //.AND.!EMPTY( ::hicon )
      nHeight :=  aTxtSize[ 2 ] //nHeight := IIF( lMultiLine, DrawText( dc, ::caption, itemRect,  DT_CALCRECT + uAlign + DT_WORDBREAK  ), aTxtSize[ 2 ] )
      IF ::iStyle = ST_ALIGN_HORIZ
         itemRect[ 1 ] := IIF( ::PictureMargin = 0, ( ( ( ::nWidth - aTxtSize[ 1 ] - aBmpSize[ 1 ] / 2 ) / 2 ) ) / 2, ::PictureMargin )
         itemRect[ 1 ] := IIF( itemRect[ 1 ] < 0, 0, itemRect[ 1 ] )
      ELSEIF ::iStyle = ST_ALIGN_HORIZ_RIGHT
      ELSEIF ::iStyle = ST_ALIGN_VERT .OR. ::iStyle = ST_ALIGN_OVERLAP
         nHeight := IIF( lMultiLine,  DrawText( dc, ::caption, itemRect,  DT_CALCRECT + DT_WORDBREAK  ), aTxtSize[ 2 ] )
         ::iStyle := ST_ALIGN_OVERLAP
         itemRect[ 1 ] := ( ::nWidth - aBmpSize[ 1 ] ) /  2
         itemRect[ 2 ] := IIF( ::PictureMargin = 0, ( ( ( ::nHeight - ( nHeight + aBmpSize[ 2 ] + 1 ) ) / 2 ) ), ::PictureMargin )
      ENDIF
   ELSEIF ! EMPTY( ::caption )
      nHeight := aTxtSize[ 2 ] //nHeight := IIF( lMultiLine, DrawText( dc, ::caption, itemRect,  DT_CALCRECT + DT_WORDBREAK ), aTxtSize[ 2 ] )
   ENDIF

   bHasTitle := ValType( ::caption ) == "C" .and. ! Empty( ::Caption )

   //   DrawTheIcon( ::handle, dc, bHasTitle, @itemRect, @captionRect, bIsPressed, bIsDisabled, ::hIcon, ::hbitmap, ::iStyle )
   IF ValType( ::hbitmap ) == "N" .AND. ::m_bDrawTransparent .AND. ( ! bIsDisabled .OR. ::istyle = ST_ALIGN_HORIZ_RIGHT )
      bmpRect := PrepareImageRect( ::handle, dc, bHasTitle, @itemRect, @captionRect, bIsPressed, ::hIcon, ::hbitmap, ::iStyle )
      IF ::istyle = ST_ALIGN_HORIZ_RIGHT
         bmpRect[ 1 ]     -= ::PictureMargin
         captionRect[ 3 ] -= ::PictureMargin
      ENDIF
      IF ! bIsDisabled
          DrawTransparentBitmap( dc, ::hbitmap, bmpRect[ 1 ], bmpRect[ 2 ] )
      ELSE
          DrawGrayBitmap( dc, ::hbitmap, bmpRect[ 1 ], bmpRect[ 2 ] )
      ENDIF
   ELSEIF ValType( ::hbitmap ) == "N" .OR. ValType( ::hicon ) == "N"
      IF ::istyle = ST_ALIGN_HORIZ_RIGHT
         captionRect[ 3 ] -= ::PictureMargin
      ENDIF
      DrawTheIcon( ::handle, dc, bHasTitle, @itemRect, @captionRect, bIsPressed, bIsDisabled, ::hIcon, ::hbitmap, ::iStyle )
   ELSE
      InflateRect( @captionRect, - 3, - 3 )
   ENDIF
   captionRect[ 1 ] += IIF( HWG_BITAND( ::Style, BS_LEFT )  != 0, Max( ::PictureMargin, 2 ), 0 )
   captionRect[ 3 ] -= IIF( HWG_BITAND( ::Style, BS_RIGHT ) != 0, Max( ::PictureMargin, 3 ), 0 )

   itemRect1    := aclone( itemRect )
   captionRect1 := aclone( captionRect )
   itemRect     := aclone( itemRectOld )

   IF ( bHasTitle )
      // If button is pressed then "press" title also
      IF bIsPressed .and. ! ::Themed
         OffsetRect( @captionRect, 1, 1 )
      ENDIF
      // Center text
      centerRect := copyrect( captionRect )
      IF ValType( ::hicon ) == "N" .OR. ValType( ::hbitmap ) == "N"
         IF ! lmultiline  .AND. ::iStyle != ST_ALIGN_OVERLAP
            // DrawText( dc, ::caption, captionRect[ 1 ], captionRect[ 2 ], captionRect[ 3 ], captionRect[ 4 ], uAlign + DT_CALCRECT, @captionRect )
         ELSEIF !EMPTY(::caption)
            // figura no topo texto em baixo
            IF ::iStyle = ST_ALIGN_OVERLAP //ST_ALIGN_VERT
               captionRect[ 2 ] :=  itemRect1[ 2 ] + aBmpSize[ 2 ] //+ 1
               uAlign -= ST_ALIGN_OVERLAP + 1
            ELSE
               captionRect[ 2 ] :=  ( ::nHeight - nHeight ) / 2 + 2
            ENDIF
            savecaptionRect := aclone( captionRect )
            DrawText( dc, ::caption, captionRect[ 1 ], captionRect[ 2 ], captionRect[ 3 ], captionRect[ 4 ], uAlign , @captionRect )
         ENDIF
      ELSE
         // *- uAlign += DT_CENTER
      ENDIF

      //captionRectWidth  := captionRect[ 3 ] - captionRect[ 1 ]
      captionRectHeight := captionRect[ 4 ] - captionRect[ 2 ]
      //centerRectWidth   := centerRect[ 3 ] - centerRect[ 1 ]
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
         IF ( ValType( ::hicon ) == "N" .OR. ValType( ::hbitmap ) == "N" )
            IF lMultiLine  .OR. ::iStyle = ST_ALIGN_OVERLAP
               captionRect := aclone( savecaptionRect )
            ENDIF
         ELSEIF lMultiLine
            captionRect[ 2 ] := (::nHeight  - nHeight ) / 2 + 2
         ENDIF
         hb_DrawThemeText( ::hTheme, dc, BP_PUSHBUTTON, IIF( bIsDisabled, PBS_DISABLED, PBS_NORMAL ), ;
               ::caption, ;
               uAlign + DT_END_ELLIPSIS, ;
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
               fillRect := COPYRECT( itemRect )
               IF bIsPressed
                  DrawButton( dc, fillRect[ 1 ], fillRect[ 2 ], fillRect[ 3 ], fillRect[ 4 ], 6 )
               ENDIF
               InflateRect( @fillRect, - 2, - 2 )
               FillRect( dc, fillRect[ 1 ], fillRect[ 2 ], fillRect[ 3 ], fillRect[ 4 ], ::m_crBrush[ BTNST_COLOR_BK_IN ]:handle )
            ELSE
               IF ( bIsFocused )
                  SetTextColor( dc, ::m_crColors[ BTNST_COLOR_FG_FOCUS ] )
                  SetBkColor( dc, ::m_crColors[ BTNST_COLOR_BK_FOCUS ] )
                  fillRect := COPYRECT( itemRect )
                  InflateRect( @fillRect, - 2, - 2 )
                  FillRect( dc, fillRect[ 1 ], fillRect[ 2 ], fillRect[ 3 ], fillRect[ 4 ], ::m_crBrush[ BTNST_COLOR_BK_FOCUS ]:handle )
               ELSE
                  SetTextColor( dc, ::m_crColors[ BTNST_COLOR_FG_OUT ] )
                  SetBkColor( dc, ::m_crColors[ BTNST_COLOR_BK_OUT ] )
                  fillRect := COPYRECT( itemRect )
                  InflateRect( @fillRect, - 2, - 2 )
                  FillRect( dc, fillRect[ 1 ], fillRect[ 2 ], fillRect[ 3 ], fillRect[ 4 ], ::m_crBrush[ BTNST_COLOR_BK_OUT ]:handle )
               ENDIF
            ENDIF
            IF ValType( ::hbitmap ) == "N" .AND. ::m_bDrawTransparent
                DrawTransparentBitmap( dc, ::hbitmap, bmpRect[ 1 ], bmpRect[ 2 ])
            ELSEIF ValType( ::hbitmap ) == "N" .OR. ValType( ::hicon ) == "N"
                DrawTheIcon( ::handle, dc, bHasTitle, @itemRect1, @captionRect1, bIsPressed, bIsDisabled, ::hIcon, ::hbitmap, ::iStyle )
            ENDIF
            IF ( ValType( ::hicon ) == "N" .OR. ValType( ::hbitmap ) == "N" )
               IF lmultiline  .OR. ::iStyle = ST_ALIGN_OVERLAP
                  captionRect := aclone( savecaptionRect )
               ENDIF
            ELSEIF lMultiLine
               captionRect[ 2 ] := (::nHeight  - nHeight ) / 2 + 2
            ENDIF
            DrawText( dc, ::caption, @captionRect[ 1 ], @captionRect[ 2 ], @captionRect[ 3 ], @captionRect[ 4 ], uAlign )
         ENDIF
      ENDIF
   ENDIF

   // Draw the focus rect
   IF bIsFocused .and. bDrawFocusRect .AND. Hwg_BitaND( ::sTyle, WS_TABSTOP ) != 0
      focusRect := COPYRECT( itemRect )
      InflateRect( @focusRect, - 3, - 3 )
      DrawFocusRect( dc, focusRect )
   ENDIF
   DeleteObject( br )
   DeleteObject( brBackground )
   DeleteObject( brBtnShadow )

   RETURN NIL

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
      ::m_pbmpOldBk := ::m_dcBk:SelectObject( ::m_bmpBk )
      ::m_dcBk:BitBlt( 0, 0, rect[ 3 ] - rect[ 1 ], rect[ 4 ] - rect[ 4 ], clDC:m_hDc, rect1[ 1 ], rect1[ 2 ], SRCCOPY )
   ENDIF
   BitBlt( hdc, 0, 0, rect[ 3 ] - rect[ 1 ], rect[ 4 ] - rect[ 4 ], ::m_dcBk:m_hDC, 0, 0, SRCCOPY )

   RETURN Self


CLASS HGroupEx INHERIT HGroup

   DATA oRGroup
   DATA oBrush
   DATA lTransparent HIDDEN

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
         cCaption, oFont, bInit, bSize, bPaint, tcolor, bColor, lTransp, oRGroup )
   METHOD Init()
   METHOD Paint( lpDis )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, ;
      oFont, bInit, bSize, bPaint, tcolor, bColor, lTransp, oRGroup ) CLASS HGroupEx

   ::oRGroup := oRGroup
   ::oBrush := IIF( bColor != NIL, ::brush,NIL )
   ::lTransparent := IIF( lTransp != NIL, lTransp, .F. )
   ::backStyle := IIF( ( lTransp != NIL .AND. lTransp ) .OR. ::bColor != NIL , TRANSPARENT, OPAQUE )
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
         oFont, bInit, bSize, bPaint,, tcolor, bColor )

   RETURN Self

METHOD Init() CLASS HGroupEx
   LOCAL nbs

   IF ! ::lInit
      Super:Init()
      // *-IF ::backStyle = TRANSPARENT .OR. ::bColor != NIL
      IF ::oBrush != NIL .OR. ::backStyle = TRANSPARENT
         nbs := HWG_GETWINDOWSTYLE( ::handle )
         nbs := modstyle( nbs, BS_TYPEMASK , BS_OWNERDRAW + WS_DISABLED )
         HWG_SETWINDOWSTYLE ( ::handle, nbs )
         ::bPaint   := { | o, p | o:paint( p ) }
      ENDIF
      IF ::oRGroup != NIL
         ::oRGroup:Handle := ::handle
         ::oRGroup:id := ::id
         ::oFont := ::oRGroup:oFont
         ::oRGroup:lInit := .f.
         ::oRGroup:Init()
      ELSE
         IF ::oBrush != NIL
            SetWindowPos( ::Handle, NIL, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE + SWP_NOACTIVATE )
         ELSE
            SetWindowPos( ::Handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE + SWP_NOACTIVATE + SWP_NOSENDCHANGING )
         ENDIF
      ENDIF
   ENDIF

   RETURN NIL

METHOD PAINT( lpdis ) CLASS HGroupEx
   LOCAL drawInfo := GetDrawItemInfo( lpdis )
   LOCAL DC := drawInfo[ 3 ]
   LOCAL ppnOldPen, pnFrmDark,   pnFrmLight, iUpDist
   LOCAL szText, aSize, dwStyle
   LOCAL rc  := copyrect( { drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ] - 1, drawInfo[ 7 ] - 1 } )
   LOCAL rcText

   // determine text length
   szText := ::Title
   aSize := TxtRect( IIF( Empty( szText ), "A", szText ), Self )
   // distance from window top to group rect
   iUpDist := ( aSize[ 2 ] / 2 )
   dwStyle := ::Style //HWG_GETWINDOWSTYLE( ::handle ) //GetStyle();
   rcText := { 0, rc[ 2 ] + iUpDist , 0, rc[ 2 ] + iUpDist  }
   IF Empty( szText )
   ELSEIF hb_BitAnd( dwStyle, BS_CENTER ) == BS_RIGHT // right aligned
      rcText[ 3 ] := rc[ 3 ] + 2 - OFS_X
      rcText[ 1 ] := rcText[ 3 ] - aSize[ 1 ]
   ELSEIF hb_BitAnd( dwStyle, BS_CENTER ) == BS_CENTER  // text centered
      rcText[ 1 ] := ( rc[ 3 ] - rc[ 1 ]  - aSize[ 1 ]  ) / 2
      rcText[ 3 ] := rcText[ 1 ] + aSize[ 1 ]
   ELSE //((!(dwStyle & BS_CENTER)) || ((dwStyle & BS_CENTER) == BS_LEFT))// left aligned   / default
      rcText[ 1 ] := rc[ 1 ] + OFS_X
      rcText[ 3 ] := rcText[ 1 ] + aSize[ 1 ]
   ENDIF
   SetBkMode( dc, TRANSPARENT )

   IF Hwg_BitAND( dwStyle, BS_FLAT) != 0  // "flat" frame
      //pnFrmDark  := CreatePen( PS_SOLID, 1, RGB(0, 0, 0) ) )
      pnFrmDark  := HPen():Add( PS_SOLID, 1,  RGB( 64, 64, 64 ) )
      pnFrmLight := HPen():Add( PS_SOLID, 1, GetSysColor( COLOR_3DHILIGHT ) )
      ppnOldPen := SelectObject( dc, pnFrmDark:Handle )
      MoveTo( dc, rcText[ 1 ] - 2, rcText[ 2 ]  )
      LineTo( dc, rc[ 1 ], rcText[ 2 ] )
      LineTo( dc, rc[ 1 ], rc[ 4 ] )
      LineTo( dc, rc[ 3 ], rc[ 4 ] )
      LineTo( dc, rc[ 3 ], rcText[ 4 ] )
      LineTo( dc, rcText[ 3 ], rcText[ 4 ] )
      SelectObject( dc, pnFrmLight:handle)
      MoveTo( dc, rcText[ 1 ] - 2, rcText[ 2 ] + 1 )
      LineTo( dc, rc[ 1 ] + 1, rcText[ 2 ] + 1)
      LineTo( dc, rc[ 1 ] + 1, rc[ 4 ] - 1 )
      LineTo( dc, rc[ 3 ] - 1, rc[ 4 ] - 1 )
      LineTo( dc, rc[ 3 ] - 1, rcText[ 4 ] + 1 )
      LineTo( dc, rcText[ 3 ], rcText[ 4 ] + 1 )
    ELSE // 3D frame
      pnFrmDark  := HPen():Add( PS_SOLID, 1, GetSysColor( COLOR_3DSHADOW ) )
      pnFrmLight := HPen():Add( PS_SOLID, 1, GetSysColor( COLOR_3DHILIGHT ) )
      ppnOldPen := SelectObject( dc, pnFrmDark:handle )
      MoveTo( dc, rcText[ 1 ] - 2, rcText[ 2 ] )
      LineTo( dc, rc[ 1 ], rcText[ 2 ] )
      LineTo( dc, rc[ 1 ], rc[ 4 ] - 1 )
      LineTo( dc, rc[ 3 ] - 1, rc[ 4 ] - 1 )
      LineTo( dc, rc[ 3 ] - 1, rcText[ 4 ] )
      LineTo( dc, rcText[ 3 ], rcText[ 4 ] )
      SelectObject( dc, pnFrmLight:handle )
      MoveTo( dc, rcText[ 1 ] - 2, rcText[ 2 ] + 1 )
      LineTo( dc, rc[ 1 ] + 1, rcText[ 2 ] + 1 )
      LineTo( dc, rc[ 1 ] + 1, rc[ 4 ] - 1 )
      MoveTo( dc, rc[ 1 ], rc[ 4 ] )
      LineTo( dc, rc[ 3 ], rc[ 4 ] )
      LineTo( dc, rc[ 3 ], rcText[ 4 ] - 1)
      MoveTo( dc, rc[ 3 ] - 2, rcText[ 4 ] + 1 )
      LineTo( dc, rcText[ 3 ], rcText[ 4 ] + 1 )
   ENDIF
   // draw text (if any)
   IF !Empty( szText ) && !(dwExStyle & (BS_ICON|BS_BITMAP)))
      SetBkMode( dc, TRANSPARENT )
      IF ::oBrush != NIL
         FillRect( DC, rc[ 1 ] + 2, rc[ 2 ] + iUpDist + 2 , rc[ 3 ] - 2, rc[ 4 ] - 2 , ::brush:handle )
         IF ! ::lTransparent
            FillRect( DC, rcText[ 1 ] - 2, rc[ 2 ] + 1 ,  rcText[ 3 ] + 1, rc[ 2 ] + iUpDist + 2 , ::brush:handle )
         ENDIF
      ENDIF
      DrawText( dc, szText, rcText, DT_VCENTER + DT_LEFT + DT_SINGLELINE + DT_NOCLIP )
   ENDIF
   // cleanup
   DeleteObject( pnFrmLight )
   DeleteObject( pnFrmDark )
   SelectObject( dc, ppnOldPen )

   RETURN NIL
