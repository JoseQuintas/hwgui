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

STATIC nrePaint := - 1

CLASS HPanel INHERIT HControl

   DATA winclass Init "PANEL"
   DATA oEmbedded
   DATA bScroll
   DATA lResizeX, lResizeY HIDDEN
   DATA lBorder INIT .F.

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
LOCAL oParent := Iif( oWndParent == Nil, ::oDefaultParent, oWndParent )

   Super:New( oWndParent, nId, nStyle, nLeft, nTop, Iif( nWidth == Nil, 0, nWidth ), ;
              Iif( nHeight == Nil, 0, nHeight ), oParent:oFont, bInit, ;
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
    IF  Hwg_Bitand( nStyle,WS_VSCROLL ) > 0
      ::nScrollBars += 2
    ENDIF

   hwg_RegPanel()
   ::Activate()

RETURN Self

METHOD Redefine( oWndParent, nId, nWidth, nHeight, bInit, bSize, bPaint, bcolor ) CLASS HPanel
LOCAL oParent := Iif( oWndParent == Nil, ::oDefaultParent, oWndParent )

   Super:New( oWndParent, nId, 0, 0, 0, Iif( nWidth == Nil, 0, nWidth ), ;
              Iif( nHeight != Nil, nHeight, 0 ), oParent:oFont, bInit, ;
              bSize, bPaint,,, bcolor )


   ::bPaint   := bPaint
   ::lResizeX := ( ::nWidth == 0 )
   ::lResizeY := ( ::nHeight == 0 )
   hwg_RegPanel()

RETURN Self

METHOD Activate() CLASS HPanel
   LOCAL handle := ::oParent:handle

   IF !Empty( handle )
      ::handle := CreatePanel( handle, ::id, ;
                               ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::ResizeOffSet( 0 )
      /*
      IF __ObjHasMsg( ::oParent, "AOFFSET" ) .AND. ::oParent:type == WND_MDI
         aCoors := GetWindowRect( ::handle )
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
   RETURN Nil

METHOD Init() CLASS HPanel

   IF !::lInit
      IF ::bSize == Nil
         ::bSize := { | o, x, y | o:Move( Iif( ::nLeft > 0, x - ::nLeft, 0 ), ;
                                          Iif( ::nTop > 0, y - ::nHeight, 0 ), ;
                                          Iif( ::nWidth == 0 .OR. ::lResizeX, x, ::nWidth ), ;
                                          Iif( ::nHeight == 0 .OR. ::lResizeY, y, ::nHeight ) ) }
      ENDIF

      Super:Init()
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      Hwg_InitWinCtrl( ::handle )

      ::RedefineScrollbars()
      
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HPanel
   LOCAL nret

   IF msg == WM_PAINT
      ::Paint()
      *-RedrawWindow( ::handle, RDW_NOERASE +  RDW_FRAME + RDW_INVALIDATE )
   ELSEIF msg == WM_NCPAINT
     *- RedrawWindow( ::handle, RDW_NOERASE +  RDW_FRAME + RDW_INVALIDATE + RDW_INTERNALPAINT )
   ELSEIF msg == WM_ERASEBKGND
      IF ::backstyle = OPAQUE
         RETURN nrePaint
         /*
         IF ::brush != Nil
            IF Valtype( ::brush ) != "N"
               FillRect( wParam, 0, 0, ::nWidth, ::nHeight, ::brush:handle )
            ENDIF
            RETURN 1
         ELSE
            FillRect( wParam, 0,0, ::nWidth, ::nHeight, COLOR_3DFACE + 1 )
            RETURN 1
         ENDIF
         */
      ELSE
         SETTRANSPARENTMODE( wParam, .T. )
         RETURN GetStockObject( NULL_BRUSH )
      ENDIF
   ELSEIF msg == WM_SIZE
      IF ::oEmbedded != Nil
         ::oEmbedded:Resize( Loword( lParam ), Hiword( lParam ) )
      ENDIF

      ::RedefineScrollbars()
      ::Resize()
      RETURN Super:onEvent( WM_SIZE, wParam, lParam )

   ELSEIF msg == WM_DESTROY
      IF ::oEmbedded != Nil
         ::oEmbedded:END()
      ENDIF
      ::Super:onEvent( WM_DESTROY )
      RETURN 0
   ENDIF
   IF ::bOther != Nil
      IF Valtype( nRet := Eval( ::bOther,Self,msg,wParam,lParam ) ) != "N"
         nRet := IIF( VALTYPE( nRet ) = "L" .AND. ! nRet, 0, -1 )
      ENDIF
      IF nRet >= 0
		   RETURN -1
      ENDIF
   ENDIF
   IF  msg = WM_NCPAINT .AND. ::GetParentForm():nInitFocus > 0 .AND. ;
       ( SELFFOCUS( GetParent( ::GetParentForm():nInitFocus ), ::Handle  ) .OR. ;
         SELFFOCUS( GetParent( ::GetParentForm():nInitFocus ), GetParent( ::Handle ) ) )
      GetSkip( ::oParent, ::GetParentForm():nInitFocus , , IIF( SelfFocus( ::GetParentForm():nInitFocus, ::Handle ), 1, 0 ) )
      ::GetParentForm():nInitFocus := 0

   ELSEIF msg = WM_SETFOCUS .AND. EMPTY(::GetParentForm():nInitFocus) .AND. ! ::lSuspendMsgsHandling  //.AND. Hwg_BitaND( ::sTyle, WS_TABSTOP ) > 0 .
      Getskip( ::oParent, ::handle, , ::nGetSkip )
/*
   ELSEIF msg = WM_KEYUP
       IF wParam = VK_DOWN
          getskip( ::oparent, ::handle, , 1 )
       ELSEIF   wParam = VK_UP
          getskip( ::oparent, ::handle, , -1 )
       ELSEIF wParam = VK_TAB
          GetSkip( ::oParent, ::handle, , iif( IsCtrlShift(.f., .t.), -1, 1) )
       ENDIF
       RETURN 0
*/
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .or. msg == WM_MOUSEWHEEL
         IF ::nScrollBars != -1 .AND. ::bScroll = Nil
             ::ScrollHV( Self, msg, wParam, lParam )
             IF  msg == WM_MOUSEWHEEL
                 RETURN 0
             ENDIF
         ENDIF
         onTrackScroll( Self,msg,wParam,lParam )
      ENDIF
      Return Super:onEvent( msg, wParam, lParam )
   ENDIF

   RETURN - 1


METHOD Paint() CLASS HPanel
LOCAL pps, hDC, aCoors, oPenLight, oPenGray

   IF ::bPaint != Nil
      Eval( ::bPaint, Self )
      RETURN Nil
   ENDIF

   pps    := DefinePaintStru()
   hDC    := BeginPaint( ::handle, pps )
   aCoors := GetClientRect( ::handle )

   SetBkMode( hDC, ::backStyle )
   IF ::backstyle = OPAQUE .AND. nrePaint = -1
      aCoors := GetClientRect( ::handle )
      IF ::brush != Nil
         IF Valtype( ::brush ) != "N"
            FillRect( hDC, aCoors[ 1 ], aCoors[ 2 ], aCoors[ 3 ], aCoors[ 4 ], ::brush:handle )
         ENDIF
      ELSE
       *  FillRect( hDC, aCoors[ 1 ], aCoors[ 2 ], aCoors[ 3 ], aCoors[ 4 ], COLOR_3DFACE + 1 )
         Gradient( hDC, aCoors[ 1 ], aCoors[ 2 ], aCoors[ 3 ], aCoors[ 4 ], RGB( 230, 240, 255 ), RGB( 255, 255, 2555 ), 0 )
      ENDIF
   ENDIF
   nrePaint := -1
   IF ::nScrollBars = - 1
      IF  ! ::lBorder
         oPenLight := HPen():Add( BS_SOLID, 1, GetSysColor( COLOR_3DHILIGHT ) )
         oPenGray := HPen():Add( BS_SOLID, 1, GetSysColor( COLOR_3DSHADOW) )

         SelectObject( hDC, oPenLight:handle )
         DrawLine( hDC, 0, 1, aCoors[ 3 ] - 1, 1 )
         SelectObject( hDC, oPenGray:handle )
         DrawLine( hDC, 0, 0, aCoors[ 3 ] - 1, 0 )
         oPenGray:Release()
         oPenLight:Release()
      ENDIF
   ENDIF
   EndPaint( ::handle, pps )
   RETURN Nil

METHOD Release() CLASS HPanel

   InvalidateRect(::oParent:handle, 1, ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight)
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
      SENDMESSAGE( ::oParent:Handle, WM_SIZE, 0, MAKELPARAM( ::oParent:nWidth, ::oParent:nHeight ) )
      ::nHeight := 0
      ::nWidth := 0
   ENDIF
   */
   ::nHeight := 0
   ::nWidth := 0
   Super:Release( )
   //  ::oParent:DelControl( Self )

RETURN Nil

METHOD Hide() CLASS HPanel
   LOCAL lRes
   
   IF ::lHide
      Return Nil
   ENDIF
   nrePaint := 0
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
    Super:Hide()
    IF ::oParent:type == WND_MDI .AND. lRes
       //SENDMESSAGE( ::oParent:Handle, WM_SIZE, 0, MAKELPARAM( ::oParent:nWidth, ::oParent:nHeight ) )
       InvalidateRect( ::oParent:handle, 1, ::nLeft, ::nTop + 1, ::nLeft + ::nWidth, ::nTop + ::nHeight )
    ENDIF
    RETURN Nil

METHOD Show() CLASS HPanel
   LOCAL lRes
   
   IF ! ::lHide
      Return Nil
   ENDIF
   nrePaint := 0
   lRes := ::ResizeOffSet( 2 )
   /*
   IF __ObjHasMsg( ::oParent,"AOFFSET" ) .AND. ::oParent:type == WND_MDI   //ISWINDOwVISIBLE( ::handle )
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
   Super:Show()
   IF ::oParent:type == WND_MDI .AND. lRes
       //SENDMESSAGE( ::oParent:Handle, WM_SIZE, 0, MAKELPARAM( ::oParent:nWidth, ::oParent:nHeight ) )
       InvalidateRect( ::oParent:handle, 1, ::nLeft, ::nTop+1, ::nLeft + ::nWidth, ::nTop + ::nHeight )
       nrePaint := -1
   ENDIF
   RETURN Nil

METHOD Resize() CLASS HPanel
   LOCAL aCoors := GetWindowRect( ::handle )
   Local nHeight := aCoors[ 4 ] - aCoors[ 2 ]
   Local nWidth  := aCoors[ 3 ] - aCoors[ 1 ]
   
   IF !isWindowVisible( ::handle ) .OR.  ( ::nHeight = nHeight .AND. ::nWidth = nWidth )
      Return Nil
   ENDIF

   IF ! ::ResizeOffSet( 1 )
      RETURN Nil
   ENDIF
   /*
   IF __ObjHasMsg( ::oParent,"AOFFSET" ) .AND. ::oParent:type == WND_MDI   //ISWINDOwVISIBLE( ::handle )
      IF ( ::nWidth > ::nHeight .OR. ::nWidth == 0 )  //.AND. ::oParent:aOffset[2] > 0
         ::oParent:aOffset[2] += ( nHeight  - ::nHeight )
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[1] += ( nWidth - ::nWidth )
         ELSE
            ::oParent:aOffset[3] += ( nWidth - ::nWidth )
         ENDIF
      ENDIF
      SENDMESSAGE( ::oParent:Handle, WM_SIZE, 0, MAKELPARAM( ::oParent:nWidth, ::oParent:nHeight ) )
   ELSE
      RETURN Nil
   ENDIF
   */
   ::nWidth  := aCoors[ 3 ] - aCoors[ 1 ]
   ::nHeight := aCoors[ 4 ] - aCoors[ 2 ]
   RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW )  // Force a complete redraw
   RETURN Nil

/* nMode => nMode = 0 INIT  / nMode = 1 RESIZE  / nMode = 2 SHOW  / nMode = 3 HIDE */
METHOD ResizeOffSet( nMode ) CLASS HPanel
   LOCAL aCoors := GetWindowRect( ::handle )
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
         SENDMESSAGE( ::oParent:Handle, WM_SIZE, 0, MAKELPARAM( ::oParent:nWidth, ::oParent:nHeight ) )
      ENDIF
   ENDIF

   RETURN lRes

