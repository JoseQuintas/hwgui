/*
 * $Id: hcontrol.prg,v 1.74 2008-07-10 14:11:15 mlacecilia Exp $
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

   DATA id
   DATA tooltip
   DATA lInit           INIT .F.
   DATA xName           HIDDEN
   ACCESS Name         INLINE ::xName
   ASSIGN Name(cName)  INLINE ::xName := cName, ;
	                           __objAddData(::oParent, cName),;
                              ::oParent:&(cName) := self

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
   METHOD GetText()     INLINE GetWindowText(::handle)
   METHOD SetText( c )  INLINE SetWindowText( ::Handle, c )
   METHOD Refresh()     VIRTUAL
   METHOD End()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
            bInit, bSize, bPaint, cTooltip, tcolor, bColor ) CLASS HControl

   ::oParent := IIF( oWndParent==NIL, ::oDefaultParent, oWndParent )
   ::id      := IIF( nId == NIL, ::NewId(), nId )
   ::style   := Hwg_BitOr( IIF( nStyle == NIL, 0, nStyle ), ;
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

Local oParent := ::oParent, i := 0, nId

	DO WHILE oParent != Nil
      nId := CONTROL_FIRST_ID + 1000 * i + Len( ::oParent:aControls )
      oParent := oParent:oParent
      i ++
	ENDDO
   IF Ascan( ::oParent:aControls, {|o| o:id == nId } ) != 0
      nId --
      DO WHILE nId >= CONTROL_FIRST_ID .AND. ;
               Ascan( ::oParent:aControls, {|o| o:id == nId } ) != 0
         nId --
      ENDDO
   ENDIF
RETURN nId

METHOD INIT CLASS HControl

   IF !::lInit
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

METHOD End() CLASS HControl

   Super:End()

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
   METHOD Redefine( oWndParent,nId,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp,aParts )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, oFont, aParts, bInit, bSize, bPaint ) CLASS HStatus

   bSize  := IIF( bSize != NIL, bSize, {|o,x,y| o:Move( 0, y - 20, x, 20 ) } )
   nStyle := Hwg_BitOr( IIF( nStyle == NIL, 0, nStyle ), ;
                        WS_CHILD + WS_VISIBLE + WS_OVERLAPPED + ;
                        WS_CLIPSIBLINGS )
   Super:New( oWndParent, nId, nStyle, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint )

   ::aParts  := aParts

   ::Activate()

RETURN Self

METHOD Activate CLASS HStatus
LOCAL aCoors

   IF !empty( ::oParent:handle ) 
      ::handle := CreateStatusWindow( ::oParent:handle, ::id )
      ::Init()
      IF __ObjHasMsg( ::oParent, "AOFFSET" )
         aCoors := GetWindowRect( ::handle )
         ::oParent:aOffset[ 4 ] := aCoors[ 4 ] - aCoors[ 2 ]
      ENDIF
   ENDIF
RETURN NIL

METHOD Init CLASS HStatus
   IF !::lInit
      Super:Init()
      IF !Empty( ::aParts )
         hwg_InitStatus( ::oParent:handle, ::handle, Len( ::aParts ), ::aParts )
      ENDIF
   ENDIF
RETURN  NIL

METHOD Redefine( oWndParent,nId,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp,aParts )  CLASS hStatus

HB_SYMBOL_UNUSED(cCaption)
HB_SYMBOL_UNUSED(lTransp)

   Super:New( oWndParent,nId,0,0,0,0,0,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )
   HWG_InitCommonControlsEx()
   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   ::aparts :=aparts
Return Self

//- HStatic

CLASS HStatic INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
               bColor, lTransp )
   METHOD Redefine( oWndParent, nId, oFont, bInit, ;
                    bSize, bPaint, cTooltip, tcolor, bColor, lTransp )
   METHOD Activate()
   METHOD SetValue( value ) INLINE SetDlgItemText( ::oParent:handle, ::id, ;
                                                   value )
   METHOD Init()
   METHOD PAINT(o)
ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
            cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
            bColor, lTransp ) CLASS HStatic

   // Enabling style for tooltips
   IF ValType( cTooltip ) == "C"
      IF nStyle == NIL
         nStyle := SS_NOTIFY
      ELSE
         nStyle := Hwg_BitOr( nStyle, SS_NOTIFY )
      ENDIF
   ENDIF
//
   IF lTransp != NIL .AND. lTransp
      ::extStyle += WS_EX_TRANSPARENT
      bPaint := {|o,p| o:paint(p)}
   ENDIF

   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont,;
              bInit, bSize, bPaint, cTooltip, tcolor, bColor )

   ::title := cCaption

   ::Activate()

RETURN Self

METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
                 bSize, bPaint, cTooltip, tcolor, bColor, lTransp ) CLASS HStatic

   IF lTransp != NIL .AND. lTransp
      ::extStyle += WS_EX_TRANSPARENT

      bPaint := {|o,p| o:paint(p)}
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
   IF !empty( ::oParent:handle ) 
      ::handle := CreateStatic( ::oParent:handle, ::id, ::style, ;
                                ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
                                ::extStyle )
      ::Init()
   ENDIF
RETURN NIL

METHOD Init CLASS HStatic
   IF !::lInit
      Super:init()
      IF ::Title != NIL
         SETWINDOWTEXT( ::handle, ::title )
      ENDIF
   ENDIF
RETURN  NIL

METHOD Paint( lpDis ) CLASS HStatic

LOCAL drawInfo := GetDrawItemInfo( lpdis )
Local client_rect,szText
local dwtext,nstyle
LOCAL dc := drawInfo[ 3 ]

client_rect:=   GetClientRect(::handle)

szText:=    GetWindowText(::handle)

        //pFont = GetFont();
//  pOldFont = dc.SelectObject(pFont);

    // Map "Static Styles" to "Text Styles"
   nstyle :=::style
   SetaStyle(@nstyle,@dwtext )

    // Set transparent background
    SetBkMode(dc,1)

    // Draw the text
    DrawText(dc,szText, client_rect[1],client_rect[2],client_rect[3],client_rect[4], dwText)

    // Select old font
//  dc.SelectObject(pOldFont);

return nil

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

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
            cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
            tcolor, bColor ) CLASS HButton

   nStyle := Hwg_BitOr( IIF( nStyle == NIL, 0, nStyle ), BS_PUSHBUTTON )

   Super:New( oWndParent, nId, nStyle, nLeft, nTop, ;
              IIF( nWidth  == NIL, 90, nWidth  ), ;
              IIF( nHeight == NIL, 30, nHeight ), ;
              oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor )
   ::bClick  := bClick
   ::title   := cCaption
   ::Activate()

   IF bClick != NIL
      IF ::oParent:className == "HSTATUS"
         ::oParent:oParent:AddEvent( 0, self, bClick,,"onClick" )
      ELSE
         ::oParent:AddEvent( 0, self, bClick, , "onClick" )
      ENDIF
   ENDIF

RETURN Self

METHOD Activate CLASS HButton
   IF !empty( ::oParent:handle ) 
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
      ::oParent:AddEvent( 0, self, bClick,,"onClick" )
   ENDIF
RETURN Self

METHOD Init CLASS HButton
   IF !::lInit
      ::super:init()
      IF ::Title != NIL
         SETWINDOWTEXT( ::handle, ::title )
      ENDIF
   endif
RETURN  NIL

//- HGroup



CLASS HButtonEX INHERIT HButton

   Data hBitmap
   DATA hIcon
   DATA m_dcBk
   DATA m_bFirstTime INIT .T.
   DATA Themed INIT .F.
   DATA m_crColors INIT ARRAY( 6 )
   DATA hTheme
   DATA Caption
   DATA state
   DATA m_bIsDefault INIT .F.
   DATA m_nTypeStyle  init 0
   DATA m_bLButtonDown
   DATA m_bSent,m_bLButtonDown,m_bIsToggle
   DATA m_rectButton           // button rect in parent window coordinates
   DATA m_dcParent init hdc():new()
   DATA m_bmpParent
   DATA m_pOldParentBitmap
   DATA m_csbitmaps init {,,,,}
	DATA m_bToggled INIT .f.



   DATA m_bDrawTransparent INIT .f.
   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
   cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, tcolor, ;
   bColor, lTransp, hBitmap,hIcon )
   Data iStyle
   DATA m_bmpBk,m_pbmpOldBk
   DATA  bMouseOverButton INIT .f.

   METHOD Paint( lpDis )
   METHOD SetBitmap( )
   METHOD SetIcon()
   METHOD INIT()
   METHOD onevent( msg, wParam, lParam )
   METHOD CancelHover()
   METHOD End()
   METHOD Redefine( oWnd, nId, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
                    tcolor, bColor, hBitmap, iStyle,hIcon )
   METHOD PAINTBK(p)
   METHOD SETDEFAULTCOLOR(lRepaint)
   Method SetColorEx(nIndex,nColor,bPaint)

   Method settext(c) inline ::title:=c,::caption:=c,;
                            sendmessage(::handle,WM_PAINT,0,0),;
                            SETWINDOWTEXT( ::handle, ::title )


//   METHOD SaveParentBackground()


END CLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
               tcolor, bColor, hBitmap, iStyle,hicon,Transp ) CLASS HButtonEx

   DEFAULT iStyle TO ST_ALIGN_HORIZ
   DEFAULT Transp to .T.
   ::m_bLButtonDown := .f.
   ::m_bSent :=.f.
   ::m_bLButtonDown := .f.
   ::m_bIsToggle := .f.


   ::Caption := cCaption
   ::iStyle                             := iStyle
   ::hBitmap                            := hBitmap
   ::hIcon                              := hIcon
   ::m_bDrawTransparent                 := Transp


   bPaint   := { | o, p | o:paint( p ) }

   ::super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
                cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
                tcolor, bColor )

RETURN Self


METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
                 cTooltip, tcolor, bColor, cCaption, hBitmap, iStyle,hIcon  ) CLASS HButtonEx
   DEFAULT iStyle TO ST_ALIGN_HORIZ
   bPaint   := { | o, p | o:paint( p ) }
   ::m_bLButtonDown := .f.
   ::m_bIsToggle := .f.

   ::m_bLButtonDown := .f.
   ::m_bSent :=.f.

   ::title   := cCaption

   ::Caption := cCaption
   ::iStyle                             := iStyle
   ::hBitmap                            := hBitmap
   ::hicon                              := hIcon
   ::m_crColors[ BTNST_COLOR_BK_IN ]    := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_IN ]    := GetSysColor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_OUT ]   := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_OUT ]   := GetSysColor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_FOCUS ] := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_FOCUS ] := GetSysColor( COLOR_BTNTEXT )


::super:Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
                 cTooltip, tcolor, bColor, cCaption, hBitmap, iStyle,hIcon  ) 
   ::title   := cCaption

   ::Caption := cCaption
   

RETURN Self

METHOD SetBitmap() CLASS HButtonEX
   IF VALTYPE( ::hBitmap ) == "N"
      SendMessage( ::handle, BM_SETIMAGE, IMAGE_BITMAP, ::hBitmap )
   ENDIF

RETURN self

METHOD SetIcon() CLASS HButtonEX
   IF VALTYPE( ::hIcon ) == "N"
      SendMessage( ::handle, BM_SETIMAGE, IMAGE_ICON, ::hIcon )
   ENDIF
RETURN self

METHOD End() CLASS HButtonEX
   Super:end()
RETURN self

METHOD INIT CLASS HButtonEx
   local nbs
   IF !::lInit
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      HWG_INITBUTTONPROC( ::handle )
      if HB_IsNumeric( ::handle ) .and. ::handle > 0
        nbs:=HWG_GETWINDOWSTYLE(::handle)
   
       ::m_nTypeStyle :=  GetTheStyle(nBS , BS_TYPEMASK)

   // Check if this is a checkbox

   // Set initial default state flag
   if (::m_nTypeStyle == BS_DEFPUSHBUTTON)
   
      // Set default state for a default button
      ::m_bIsDefault := .t.

      // Adjust style for default button
      ::m_nTypeStyle := BS_PUSHBUTTON
   endif
        Nbs := modstyle(nbs,BS_TYPEMASK  ,BS_OWNERDRAW)
        HWG_SETWINDOWSTYLE ( ::handle,nbs)

endif

      ::super:init()
      ::SetBitmap()
endif
RETURN NIL

METHOD onEvent( msg, wParam, lParam ) CLASS HBUTTONEx

Local pt:={,},rectButton,acoor
local pos

   IF msg == WM_THEMECHANGED
      IF ::Themed
         IF VALTYPE( ::hTheme ) == "P"
            HB_CLOSETHEMEDATA( ::htheme )
            ::hTheme       := nil
            ::m_bFirstTime := .T.
         ENDIF
      ENDIF
      RETURN 0
   elseif msg == WM_ERASEBKGND
      return 0
   ELSEIF msg == BM_SETSTYLE
      return BUTTONEXONSETSTYLE(wParam,lParam,::handle,@::m_bIsDefault)

   ELSEIF msg == WM_MOUSEMOVE
      if(!::bMouseOverButton)
         ::bMouseOverButton := .T.
         Invalidaterect( ::handle, .f. )
         TRACKMOUSEVENT( ::handle )
      endif
      RETURN 0
   ELSEIF msg == WM_MOUSELEAVE
      ::CancelHover()
      RETURN 0                 
     
   elseif msg == WM_KEYDOWN
        
#ifdef __XHARBOUR__
      if hb_inline( lParam) { LPARAM l = (LPARAM) hb_parnl( 1 ); hb_retl( l & 0x40000000);}
#else
		if hb_BitTest( lParam , 30 )  // the key was down before ?
#endif
         return 0
      endif
      if ((wParam == VK_SPACE) .or. (wParam == VK_RETURN))
         SendMessage(::handle, WM_LBUTTONDOWN, 0, MAKELPARAM(1, 1))
         return 0
      endif
      IF	wParam = VK_LEFT  .OR. wParam = VK_UP
         GetSkip( ::oParent, ::handle, , -1 )
			return 0
		endif
		IF wParam = VK_RIGHT .OR. wParam = VK_DOWN
         GetSkip( ::oParent, ::handle, , 1 )
			return 0
		endif
   elseif msg == WM_KEYUP

      if ((wParam == VK_SPACE) .or. (wParam == VK_RETURN))
         SendMessage(::handle, WM_LBUTTONUP, 0, MAKELPARAM(1, 1))
         return 0
      endif
      
   elseif msg == WM_LBUTTONUP 
     ::m_bLButtonDown := .f.
     if (::m_bSent)
        SendMessage(::handle,BM_SETSTATE, 0,0)
       ::m_bSent := .f.
     endif
     if ::m_bIsToggle
       pt[1]:= loword( lParam )
       pt[2]:= hiword( lParam )
       acoor :=ClientToScreen(::handle,pt[1],pt[2])
 
       rectButton :=GetWindowRect(::handle )
        
       if (!PtInRect(rectButton,acoor))                      
           ::m_bToggled = !::m_bToggled
           InvalidateRect(::handle,0)
           SendMessage(::handle,BM_SETSTATE, 0,0)
           ::m_bLButtonDown := .T.
       endif
     endif
     return -1
     
   elseif msg == WM_LBUTTONDOWN
      ::m_bLButtonDown := .t.
      if (::m_bIsToggle)   
         ::m_bToggled := !::m_bToggled
         InvalidateRect(::handle,0)
      endif
      return -1

    elseif msg ==WM_LBUTTONDBLCLK
                
         if (::m_bIsToggle)
                        
            // for toggle buttons, treat doubleclick as singleclick
            SendMessage(::handle,BM_SETSTATE, ::m_bToggled,0)                     

         else

            SendMessage(::handle,BM_SETSTATE, 1,0)
            ::m_bSent := TRUE

         endif
         return 0
                
   elseif msg == WM_GETDLGCODE
      return ButtonGetDlgCode(lParam)

   elseif msg == WM_SYSCOLORCHANGE
       ::SetDefaultColors()
   elseif msg ==WM_CHAR //.or. msg == WM_KEYUP
      if wParam == VK_RETURN .or. wParam == VK_SPACE
         if (::m_bIsToggle)
                               
            ::m_bToggled := !::m_bToggled
            InvalidateRect(::handle,0)
         else
                               
            SendMessage(::handle,BM_SETSTATE, 1,0)
            ::m_bSent := .t. 
         endif


         if wParam == VK_RETURN .or. wParam == VK_SPACE
            SendMessage( ::oParent:handle, WM_COMMAND, makewparam( ::id, BN_CLICKED ), ::handle )
         endif
      endif
      return 0
   elseif msg ==WM_SYSKEYUP .and. ( pos := At( "&", ::title ) ) > 0 .and. wParam == Asc( Upper( ::title[ ++ pos ] ) )
         if Valtype(::bClick) =="B"
            SendMessage( ::oParent:handle, WM_COMMAND, makewparam( ::id, BN_CLICKED ), ::handle )
         endif
      return 0
   endif
RETURN -1



METHOD CancelHover() CLASS HBUTTONEx

   IF ( ::bMouseOverButton )
      ::bMouseOverButton := .F.
      Invalidaterect( ::handle, .f. )
   ENDIF

RETURN nil

METHOD SetdefaultColor(lPaint) CLASS HBUTTONEx
Default lPaint to .f.

   ::m_crColors[ BTNST_COLOR_BK_IN ]    := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_IN ]    := GetSysColor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_OUT ]   := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_OUT ]   := GetSysColor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_FOCUS ] := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_FOCUS ] := GetSysColor( COLOR_BTNTEXT )
   if lPaint
      Invalidaterect( ::handle, .f. )
   endif
return Self


METHOD SetColorEx(nIndex,nColor,lPaint) CLASS HBUTTONEx
Default lPaint to .f.
   if nIndex > BTNST_MAX_COLORS
      return -1
   endif
   ::m_crColors[ nIndex ]    := nColor
   if lPaint
      Invalidaterect( ::handle, .f. )
   endif
return 0


METHOD Paint( lpDis ) CLASS HBUTTONEx

LOCAL drawInfo := GetDrawItemInfo( lpdis )

LOCAL dc := drawInfo[ 3 ]

LOCAL bIsPressed     := HWG_BITAND( DrawInfo[ 9 ], ODS_SELECTED ) != 0
LOCAL bIsFocused     := HWG_BITAND( DrawInfo[ 9 ], ODS_FOCUS ) != 0
LOCAL bIsDisabled    := HWG_BITAND( DrawInfo[ 9 ], ODS_DISABLED ) != 0
LOCAL bDrawFocusRect := !HWG_BITAND( DrawInfo[ 9 ], ODS_NOFOCUSRECT ) != 0
LOCAL focusRect

LOCAL captionRect
LOCAL centerRect
LOCAL bHasTitle
LOCAL itemRect    := copyrect({ DrawInfo[ 4 ], DrawInfo[ 5 ], DrawInfo[ 6 ], DrawInfo[ 7 ] })

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
LOCAL uAlign,uStyleTmp


   IF ( ::m_bFirstTime )

      ::m_bFirstTime := .F.

      IF ( ISTHEMEDLOAD() )

         IF VALTYPE( ::hTheme ) == "P"
            HB_CLOSETHEMEDATA( ::htheme )
         ENDIF
         ::hTheme := nil
         ::hTheme := hb_OpenThemeData( ::handle, "BUTTON" )

      ENDIF
   ENDIF

   IF !EMPTY( ::hTheme )
      ::Themed := .T.
   ENDIF

   SetBkMode( dc, TRANSPARENT )
   if (::m_bDrawTransparent)
//        ::PaintBk(DC)
   endif


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
   uAlign:=DT_LEFT
   if VALTYPE( ::hbitmap ) == "N"
         uAlign := DT_CENTER
   endif
   if VALTYPE( ::hicon ) == "N"
         uAlign := DT_CENTER
   endif

//             DT_CENTER | DT_VCENTER | DT_SINGLELINE
//   uAlign += DT_WORDBREAK + DT_CENTER + DT_CALCRECT +  DT_VCENTER + DT_SINGLELINE  // DT_SINGLELINE + DT_VCENTER + DT_WORDBREAK
     uAlign += DT_VCENTER
     uStyleTmp := HWG_GETWINDOWSTYLE(::handle)
     
#ifdef __XHARBOUR
     if hb_inline(uStyleTmp) { ULONG ulStyle = (ULONG)hb_parnl( 1 ) ; hb_retl( ulStyle & BS_MULTILINE ); }
#else
	  if hb_BitAnd( uStyleTmp, BS_MULTILINE ) != 0
#endif
        uAlign += DT_WORDBREAK 
     else
        uAlign += DT_SINGLELINE
     endif
     


   captionRect := { DrawInfo[ 4 ], DrawInfo[ 5 ], DrawInfo[ 6 ], DrawInfo[ 7 ] }

   bHasTitle := valtype(::caption) =="C" .and. !EMPTY( ::Caption )

   DrawTheIcon( ::handle, dc, bHasTitle, @itemRect, @captionRect, bIsPressed, bIsDisabled, ::hIcon, ::hbitmap, ::iStyle )

   IF ( bHasTitle )

      // If button is pressed then "press" title also
      IF bIsPressed .and. !::Themed
         OffsetRect( @captionRect, 1, 1 )
      ENDIF

      // Center text
      centerRect := captionRect

      centerRect:=copyrect(captionRect)



      if VALTYPE( ::hicon ) == "N" .or. VALTYPE( ::hbitmap ) == "N"
         DrawText( dc, ::caption, captionrect[ 1 ], captionrect[ 2 ], captionrect[ 3 ], captionrect[ 4 ], uAlign + DT_CALCRECT, @captionRect )
      else
         uAlign += DT_CENTER // NANDO
      endif


      captionRectWidth  := captionrect[ 3 ] - captionrect[ 1 ]
      captionRectHeight := captionrect[ 4 ] - captionrect[ 2 ]
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

         hb_DrawThemeText( ::hTheme, dc, BP_PUSHBUTTON, if( bIsDisabled, PBS_DISABLED, PBS_NORMAL), ;
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
         DrawText( dc, ::caption, @captionRect[ 1 ], @captionRect[ 2 ], @captionRect[ 3 ], @captionRect[ 4 ], uAlign )

         ENDIF
      ENDIF
   ENDIF

   // Draw the focus rect
   IF bIsFocused .and. bDrawFocusRect

      focusRect := COPYRECT(itemRect)
      InflateRect( @focusRect, - 3, - 3 )
      DrawFocusRect( dc, focusRect )
   ENDIF

RETURN nil

METHOD PAINTBK(hdc) CLASS HBUTTONEx

    Local clDC:=HclientDc():New(::oparent:handle)
    Local rect, rect1

    rect:=GetClientRect(::handle)

    rect1:=GetWindowRect(::handle)
    ScreenToClient(::oparent:handle,rect1)

    if Valtype(::m_dcBk) =="U"

        ::m_dcBk:=Hdc():New()
        ::m_dcBk:CreateCompatibleDC(clDC:m_hDC)
        ::m_bmpBk := CreateCompatibleBitmap(clDC:m_hDC, rect[3]-rect[1], rect[4]-rect[2])
        ::m_pbmpOldBk = ::m_dcBk:SelectObject(::m_bmpBk)
        ::m_dcBk:BitBlt(0, 0, rect[3]-rect[1], rect[4]-rect[4], clDC:m_hDc, rect1[1], rect1[2], SRCCOPY)
    endif

    BitBlt(hdc,0, 0, rect[3]-rect[1], rect[4]-rect[4],::m_dcBk:m_hDC, 0, 0, SRCCOPY)
return self




CLASS HGroup INHERIT HControl

   CLASS VAR winclass   INIT "BUTTON"

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               cCaption, oFont, bInit, bSize, bPaint, tcolor, bColor )
   METHOD Activate()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, ;
            oFont, bInit, bSize, bPaint, tcolor, bColor ) CLASS HGroup

   nStyle := Hwg_BitOr( IIF( nStyle == NIL, 0, nStyle ), BS_GROUPBOX )
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
              oFont, bInit, bSize, bPaint,, tcolor, bColor )

   ::title   := cCaption
   ::Activate()

RETURN Self

METHOD Activate CLASS HGroup
   IF !empty( ::oParent:handle ) 
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
              bSize, {|o,lp| o:Paint( lp ) } )

   ::title := ""
   ::lVert := IIF( lVert==NIL, .F., lVert )
   IF ::lVert
      ::nWidth  := 10
      ::nHeight := IIF( nLength == NIL, 20, nLength )
   ELSE
      ::nWidth  := IIF( nLength == NIL, 20, nLength )
      ::nHeight := 10
   ENDIF

   ::oPenLight := HPen():Add( BS_SOLID, 1, GetSysColor( COLOR_3DHILIGHT ) )
   ::oPenGray  := HPen():Add( BS_SOLID, 1, GetSysColor( COLOR_3DSHADOW  ) )

   ::Activate()

RETURN Self

METHOD Activate CLASS HLine
   IF !empty( ::oParent:handle ) 
      ::handle := CreateStatic( ::oParent:handle, ::id, ::style, ;
                                ::nLeft, ::nTop, ::nWidth,::nHeight )
      ::Init()
   ENDIF
RETURN NIL

METHOD Paint( lpdis ) CLASS HLine
LOCAL drawInfo := GetDrawItemInfo( lpdis )
LOCAL hDC := drawInfo[3]
LOCAL x1  := drawInfo[4], y1 := drawInfo[5]
LOCAL x2  := drawInfo[6], y2 := drawInfo[7]

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



init procedure starttheme()
INITTHEMELIB()

exit procedure endtheme()
ENDTHEMELIB()
