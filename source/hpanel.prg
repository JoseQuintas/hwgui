/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HPanel class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define TRANSPARENT 1

CLASS HPanel INHERIT HControl, HScrollArea

   DATA winclass Init "PANEL"
   DATA oEmbedded
   DATA bScroll
   DATA lResizeX, lResizeY HIDDEN
   DATA lBorder INIT .F.
   DATA nRePaint  INIT  - 1

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
         bInit, bSize, bPaint, bcolor )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Redefine( oWndParent, nId, nWidth, nHeight, bInit, bSize, bPaint, bcolor )
   METHOD Paint()
   METHOD BackColor( bcolor ) INLINE ::SetColor(, bcolor, .T. )
   METHOD Hide()
   METHOD Show()
   METHOD Release()
   METHOD Resize()
   METHOD ResizeOffSet( nMode )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      bInit, bSize, bPaint, bcolor ) CLASS HPanel
   LOCAL oParent := Iif( oWndParent == NIL, ::oDefaultParent, oWndParent )

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, Iif( nWidth == NIL, 0, nWidth ), ;
         Iif( nHeight == NIL, 0, nHeight ), oParent:oFont, bInit, ;
         bSize, bPaint,,, bcolor )

   ::lBorder  := IIF( Hwg_Bitand( nStyle,WS_BORDER ) + Hwg_Bitand( nStyle,WS_DLGFRAME ) > 0, .T., .F. )
   ::bPaint   := bPaint
   ::lResizeX := ( ::nWidth == 0 )
   ::lResizeY := ( ::nHeight == 0 )
   /*
   IF __ObjHasMsg( ::oParent, "AOFFSET" ) .AND. ::oParent:Type == WND_MDI
      IF ::nWidth > ::nHeight .OR. ::nWidth == 0
         ::oParent:aOffset[ 2 ] := ::nHeight
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[ 1 ] := ::nWidth
         ELSE
            ::oParent:aOffset[ 3 ] := ::nWidth
         ENDIF
      ENDIF
   ENDIF
   */
   ::nGetSkip := 1
   IF Hwg_Bitand( nStyle,WS_HSCROLL ) > 0
      ::nScrollBars ++
   ENDIF
   IF Hwg_Bitand( nStyle,WS_VSCROLL ) > 0
      ::nScrollBars += 2
   ENDIF

   hwg_RegPanel()
   ::Activate()

   RETURN Self

METHOD Redefine( oWndParent, nId, nWidth, nHeight, bInit, bSize, bPaint, bcolor ) CLASS HPanel
   LOCAL oParent := Iif( oWndParent == NIL, ::oDefaultParent, oWndParent )

   ::Super:New( oWndParent, nId, 0, 0, 0, Iif( nWidth == NIL, 0, nWidth ), ;
         Iif( nHeight != NIL, nHeight, 0 ), oParent:oFont, bInit, ;
         bSize, bPaint,,, bcolor )

   ::bPaint   := bPaint
   ::lResizeX := ( ::nWidth == 0 )
   ::lResizeY := ( ::nHeight == 0 )
   hwg_RegPanel()

   RETURN Self

METHOD Activate() CLASS HPanel
   LOCAL handle := ::oParent:handle

   IF !Empty( handle )
      ::handle := hwg_Createpanel( handle, ::id, ;
            ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::ResizeOffSet( 0 )
      /*
      IF __ObjHasMsg( ::oParent, "AOFFSET" ) .AND. ::oParent:type == WND_MDI
         aCoors := hwg_Getwindowrect( ::handle )
         nWidth := aCoors[ 3 ] - aCoors[ 1 ]
         nHeight:= aCoors[ 4 ] - aCoors[ 2 ]
         IF nWidth > nHeight .OR. nWidth == 0
            ::oParent:aOffset[2] += nHeight
         ELSEIF nHeight > nWidth .OR. nHeight == 0
            IF ::nLeft == 0
               ::oParent:aOffset[1] += nWidth
            ELSE
               ::oParent:aOffset[3] += nWidth
            ENDIF
         ENDIF
      ENDIF
      */
      ::Init()
   ENDIF

   RETURN NIL

METHOD Init() CLASS HPanel

   IF !::lInit
      IF ::bSize == NIL
         ::bSize := { | o, x, y | o:Move( Iif( ::nLeft > 0, x - ::nLeft, 0 ), ;
               Iif( ::nTop > 0, y - ::nHeight, 0 ), ;
               Iif( ::nWidth == 0 .OR. ::lResizeX, x, ::nWidth ), ;
               Iif( ::nHeight == 0 .OR. ::lResizeY, y, ::nHeight ) ) }
      ENDIF

      ::Super:Init()
      ::nHolder := 1
      hwg_Setwindowobject( ::handle, Self )
      Hwg_InitWinCtrl( ::handle )
      ::RedefineScrollbars()
      
   ENDIF

   RETURN NIL

METHOD onEvent( msg, wParam, lParam ) CLASS HPanel
   LOCAL nret

   IF msg == WM_PAINT .AND. hwg_Getupdaterect( ::Handle ) > 0
      ::Paint()

   ELSEIF msg == WM_NCPAINT .AND. ! hwg_Selffocus( hwg_GetParentForm(Self):handle, hwg_Getactivewindow() )
      hwg_Redrawwindow( ::Handle, RDW_UPDATENOW )

   ELSEIF msg == WM_ERASEBKGND
      IF ::backstyle = OPAQUE
         RETURN ::nrePaint
         /*
         IF ::brush != NIL
            IF Valtype( ::brush ) != "N"
               hwg_Fillrect( wParam, 0, 0, ::nWidth, ::nHeight, ::brush:handle )
            ENDIF
            RETURN 1
         ELSE
            hwg_Fillrect( wParam, 0,0, ::nWidth, ::nHeight, COLOR_3DFACE + 1 )
            RETURN 1
         ENDIF
         */
      ENDIF
      hwg_Settransparentmode( wParam, .T. )
      RETURN hwg_Getstockobject( NULL_BRUSH )
   ELSEIF msg == WM_SIZE
      IF ::oEmbedded != NIL
         ::oEmbedded:Resize( hwg_Loword( lParam ), hwg_Hiword( lParam ) )
      ENDIF
      ::RedefineScrollbars()
      ::Resize()
      RETURN ::Super:onEvent( WM_SIZE, wParam, lParam )
   ELSEIF msg == WM_DESTROY
      IF ::oEmbedded != NIL
         ::oEmbedded:END()
      ENDIF
      ::Super:onEvent( WM_DESTROY )
      RETURN 0
   ENDIF
   IF ::bOther != NIL
      IF Valtype( nRet := Eval( ::bOther,Self,msg,wParam,lParam ) ) != "N"
         nRet := IIF( VALTYPE( nRet ) = "L" .AND. ! nRet, 0, -1 )
      ENDIF
      IF nRet >= 0
         RETURN -1
      ENDIF
   ENDIF
   IF msg = WM_NCPAINT .AND. hwg_GetParentForm(Self):nInitFocus > 0 .AND. ;
         ( hwg_Selffocus( hwg_Getparent( hwg_GetParentForm(Self):nInitFocus ), ::Handle  ) .OR. ;
         hwg_Selffocus( hwg_Getparent( hwg_GetParentForm(Self):nInitFocus ), hwg_Getparent( ::Handle ) ) )
      hwg_GetSkip( ::oParent, hwg_GetParentForm(Self):nInitFocus , , IIF( hwg_Selffocus( hwg_GetParentForm(Self):nInitFocus, ::Handle ), 1, 0 ) )
      hwg_GetParentForm(Self):nInitFocus := 0
   ELSEIF msg = WM_SETFOCUS .AND. EMPTY(hwg_GetParentForm(Self):nInitFocus) .AND. ! ::lSuspendMsgsHandling  //.AND. Hwg_BitaND( ::sTyle, WS_TABSTOP ) != 0
      hwg_GetSkip( ::oParent, ::handle, , ::nGetSkip )

   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .OR. ( msg == WM_MOUSEWHEEL ) //.AND. ::nScrollBars >= 2 )
         IF ::nScrollBars != -1 .AND. ::bScroll = NIL
             hwg_ScrollHV( Self, msg, wParam, lParam )
             IF  msg == WM_MOUSEWHEEL
                 RETURN 0
             ENDIF
         ENDIF
         hwg_onTrackScroll( Self, msg, wParam, lParam )
      ENDIF
      Return ::Super:onEvent( msg, wParam, lParam )
   ENDIF

   RETURN - 1

METHOD Paint() CLASS HPanel
   LOCAL pps, hDC, aCoors, oPenLight, oPenGray

   IF ::bPaint != NIL
      Eval( ::bPaint, Self )
      RETURN NIL
   ENDIF
   pps    := hwg_Definepaintstru()
   hDC    := hwg_Beginpaint( ::handle, pps )
   aCoors := hwg_Getclientrect( ::handle )
   hwg_Setbkmode( hDC, ::backStyle )
   IF ::backstyle = OPAQUE .AND. ::nrePaint = -1
      aCoors := hwg_Getclientrect( ::handle )
      IF ::brush != NIL
         IF Valtype( ::brush ) != "N"
            hwg_Fillrect( hDC, aCoors[ 1 ], aCoors[ 2 ], aCoors[ 3 ], aCoors[ 4 ], ::brush:handle )
         ENDIF
      ELSE
         hwg_Fillrect( hDC, aCoors[ 1 ], aCoors[ 2 ], aCoors[ 3 ], aCoors[ 4 ], COLOR_3DFACE + 1 )
      ENDIF
   ENDIF
   ::nrePaint := -1
   IF ::nScrollBars = - 1
      IF  ! ::lBorder
         oPenLight := HPen():Add( BS_SOLID, 1, hwg_Getsyscolor( COLOR_3DHILIGHT ) )
         oPenGray := HPen():Add( BS_SOLID, 1, hwg_Getsyscolor( COLOR_3DSHADOW) )
         hwg_Selectobject( hDC, oPenLight:handle )
         hwg_Drawline( hDC, 0, 1, aCoors[ 3 ] - 1, 1 )
         hwg_Selectobject( hDC, oPenGray:handle )
         hwg_Drawline( hDC, 0, 0, aCoors[ 3 ] - 1, 0 )
         oPenGray:Release()
         oPenLight:Release()
      ENDIF
   ENDIF
   hwg_Endpaint( ::handle, pps )

   RETURN NIL

METHOD Release() CLASS HPanel

   hwg_Invalidaterect(::oParent:handle, 1, ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight)
   ::ResizeOffSet( 3 )
   /*
   IF __ObjHasMsg( ::oParent, "AOFFSET" ) .AND. ::oParent:type == WND_MDI
      IF (::nWidth > ::nHeight .OR. ::nWidth == 0 ).AND. ::oParent:aOffset[2] > 0
         ::oParent:aOffset[ 2 ] -= ::nHeight
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[ 1 ] -= ::nWidth
         ELSE
            ::oParent:aOffset[ 3 ] -= ::nWidth
         ENDIF
      ENDIF
      ::oParent:aOffset[ 1 ] := MAX( ::oParent:aOffset[ 1 ] , 0 )
      ::oParent:aOffset[ 2 ] := MAX( ::oParent:aOffset[ 2 ] , 0 )
      ::oParent:aOffset[ 3 ] := MAX( ::oParent:aOffset[ 3 ] , 0 )
      hwg_Sendmessage( ::oParent:Handle, WM_SIZE, 0, hwg_Makelparam( ::oParent:nWidth, ::oParent:nHeight ) )
      ::nHeight := 0
      ::nWidth := 0
   ENDIF
   */
   ::nHeight := 0
   ::nWidth := 0
   ::Super:Release( )
   //  ::oParent:DelControl( Self )

   RETURN NIL

METHOD Hide() CLASS HPanel
   LOCAL lRes

   IF ::lHide
      Return NIL
   ENDIF
   ::nrePaint := 0
   lres := ::ResizeOffSet( 3 )
   /*
   IF __ObjHasMsg( ::oParent,"AOFFSET" ) .AND. ::oParent:type == WND_MDI
      IF ( ::nWidth > ::nHeight .OR. ::nWidth == 0 ) .AND. ::oParent:aOffset[2] > 0
         ::oParent:aOffset[2] -= ::nHeight
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[1] -= ::nWidth
         ELSE
            ::oParent:aOffset[3] -= ::nWidth
         ENDIF
      ENDIF
   ENDIF
   */
   ::Super:Hide()
   IF ::oParent:type == WND_MDI .AND. lRes
      //hwg_Sendmessage( ::oParent:Handle, WM_SIZE, 0, hwg_Makelparam( ::oParent:nWidth, ::oParent:nHeight ) )
      hwg_Invalidaterect( ::oParent:handle, 1, ::nLeft, ::nTop + 1, ::nLeft + ::nWidth, ::nTop + ::nHeight )
   ENDIF

   RETURN NIL

METHOD Show() CLASS HPanel
   LOCAL lRes

   IF ! ::lHide
      Return NIL
   ENDIF
   ::nrePaint := - 1
   lRes := ::ResizeOffSet( 2 )
   /*
   IF __ObjHasMsg( ::oParent,"AOFFSET" ) .AND. ::oParent:type == WND_MDI   //hwg_Iswindowvisible( ::handle )
      IF ( ::nWidth > ::nHeight .OR. ::nWidth == 0 ) .AND. ::oParent:aOffset[2] > 0
         ::oParent:aOffset[2] += ::nHeight
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[1] += ::nWidth
         ELSE
            ::oParent:aOffset[3] += ::nWidth
         ENDIF
      ENDIF
   ENDIF
   */
   ::Super:Show()
   IF ::oParent:type == WND_MDI .AND. lRes
       //hwg_Sendmessage( ::oParent:Handle, WM_SIZE, 0, hwg_Makelparam( ::oParent:nWidth, ::oParent:nHeight ) )
       hwg_Invalidaterect( ::oParent:handle, 1, ::nLeft, ::nTop+1, ::nLeft + ::nWidth, ::nTop + ::nHeight )
   ENDIF

   RETURN NIL

METHOD Resize() CLASS HPanel
   LOCAL aCoors := hwg_Getwindowrect( ::handle )
   Local nHeight := aCoors[ 4 ] - aCoors[ 2 ]
   Local nWidth  := aCoors[ 3 ] - aCoors[ 1 ]

   IF !hwg_Iswindowvisible( ::handle ) .OR.  ( ::nHeight = nHeight .AND. ::nWidth = nWidth )
      Return NIL
   ENDIF

   IF ! ::ResizeOffSet( 1 )
      RETURN NIL
   ENDIF
   /*
   IF __ObjHasMsg( ::oParent,"AOFFSET" ) .AND. ::oParent:type == WND_MDI   //hwg_Iswindowvisible( ::handle )
      IF ( ::nWidth > ::nHeight .OR. ::nWidth == 0 )  //.AND. ::oParent:aOffset[2] > 0
         ::oParent:aOffset[2] += ( nHeight  - ::nHeight )
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[1] += ( nWidth - ::nWidth )
         ELSE
            ::oParent:aOffset[3] += ( nWidth - ::nWidth )
         ENDIF
      ENDIF
      hwg_Sendmessage( ::oParent:Handle, WM_SIZE, 0, hwg_Makelparam( ::oParent:nWidth, ::oParent:nHeight ) )
   ELSE
      RETURN NIL
   ENDIF
   */
   ::nWidth  := aCoors[ 3 ] - aCoors[ 1 ]
   ::nHeight := aCoors[ 4 ] - aCoors[ 2 ]
   //  hwg_Redrawwindow( ::handle, RDW_ERASE + RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW )  // Force a complete redraw

   RETURN NIL

/* nMode => nMode = 0 INIT  / nMode = 1 RESIZE  / nMode = 2 SHOW  / nMode = 3 HIDE */
METHOD ResizeOffSet( nMode ) CLASS HPanel
   LOCAL aCoors := hwg_Getwindowrect( ::handle )
   LOCAL nHeight := aCoors[ 4 ] - aCoors[ 2 ]
   LOCAL nWidth  := aCoors[ 3 ] - aCoors[ 1 ]
   LOCAL nWinc :=  nWidth  - ::nWidth
   LOCAL nHinc :=  nHeight - ::nHeight
   LOCAL lres := .F.

   nWinc := IIF( nMode = 1, nWinc, IIF( nMode = 2, ::nWidth, nWidth ) )
   nHinc := IIF( nMode = 1, nHinc, IIF( nMode = 2, ::nHeight, nHeight ) )
   DEFAULT nMode := 0

   IF __ObjHasMsg( ::oParent,"AOFFSET" ) .AND. ::oParent:type == WND_MDI
      IF ( ::nWidth > ::nHeight .OR. ::nWidth == 0 ) //.AND. ::oParent:aOffset[2] > 0 //::nWidth = ::oParent:nWidth )
         ::oParent:aOffset[2] += IIF( nMode != 3, nHinc, - nHinc )
         lRes := .T.
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[ 1 ] += IIF( nMode != 3, nWinc, - nWinc )
         ELSE
            ::oParent:aOffset[ 3 ] += IIF( nMode != 3, nWinc, - nWinc )
         ENDIF
         lRes := .T.
      ENDIF
      ::oParent:aOffset[ 1 ] := MAX( ::oParent:aOffset[ 1 ] , 0 )
      ::oParent:aOffset[ 2 ] := MAX( ::oParent:aOffset[ 2 ] , 0 )
      ::oParent:aOffset[ 3 ] := MAX( ::oParent:aOffset[ 3 ] , 0 )
      IF lRes
         hwg_Sendmessage( ::oParent:Handle, WM_SIZE, 0, hwg_Makelparam( ::oParent:nWidth, ::oParent:nHeight ) )
      ENDIF
   ENDIF

   RETURN lRes
