/*
 * $Id: hpanel.prg,v 1.30 2010-05-24 14:57:03 lfbasso Exp $
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

METHOD Activate CLASS HPanel
   LOCAL handle := ::oParent:handle
   LOCAL aCoors, nWidth, nHeight

   IF !Empty( handle )
      ::handle := CreatePanel( handle, ::id, ;
                               ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      IF __ObjHasMsg( ::oParent, "AOFFSET" )
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
      ::Init()
   ENDIF
   RETURN Nil

METHOD Init CLASS HPanel

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
      
      ::rect := GetClientRect( ::handle )   
      IF ::nScrollBars > - 1 .AND. ::bScroll = Nil
         AEval( ::aControls, { | o | ::ncurHeight := max( o:nTop +  o:nHeight + VERT_PTS ^ 2 + 6, ::ncurHeight ) } )  
         AEval( ::aControls, { | o | ::ncurWidth := max(  o:nLeft + o:nWidth  + HORZ_PTS ^ 2 + 12, ::ncurWidth ) } )  
         ::ResetScrollbars()
         ::SetupScrollbars()
      ENDIF
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HPanel

   IF msg == WM_PAINT
      ::Paint()
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
         RETURN GetStockObject( 5 )
      ENDIF
   ELSEIF msg == WM_SIZE
      IF ::oEmbedded != Nil
         ::oEmbedded:Resize( Loword( lParam ), Hiword( lParam ) )
      ENDIF
      IF ::nScrollBars > - 1 .AND. ::bScroll = Nil
         ::ResetScrollbars()
         ::SetupScrollbars()
      ENDIF
      ::Resize()
      ::Super:onEvent( WM_SIZE, wParam, lParam )
   ELSEIF msg == WM_DESTROY
      IF ::oEmbedded != Nil
         ::oEmbedded:END()
      ENDIF
      ::Super:onEvent( WM_DESTROY )
      RETURN 0
   ELSEIF msg = WM_SETFOCUS
      getskip( ::oParent, ::handle, , ::nGetSkip )
   ELSEIF msg = WM_KEYUP
       IF wParam = VK_DOWN
          getskip( ::oparent, ::handle, , 1 )
       ELSEIF   wParam = VK_UP
          getskip( ::oparent, ::handle, , -1 )
       ELSEIF wParam = VK_TAB 
          GetSkip( ::oParent, ::handle, , iif( IsCtrlShift(.f., .t.), -1, 1) )
       ENDIF
       RETURN 0
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .or. msg == WM_MOUSEWHEEL
         IF ::nScrollBars != -1 .AND. ::bScroll = Nil
             ::ScrollHV( Self,msg,wParam,lParam )
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
         FillRect( hDC, aCoors[ 1 ], aCoors[ 2 ], aCoors[ 3 ], aCoors[ 4 ], COLOR_3DFACE + 1 )  
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

METHOD Release CLASS HPanel

   IF __ObjHasMsg( ::oParent, "AOFFSET" ) .AND. ::oParent:type == WND_MDI
      IF ::nWidth > ::nHeight .OR. ::nWidth == 0
         ::oParent:aOffset[ 2 ] -= ::nHeight
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[ 1 ] -= ::nWidth
         ELSE
            ::oParent:aOffset[ 3 ] -= ::nWidth
         ENDIF
      ENDIF
      InvalidateRect(::oParent:handle, 1, ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight)
   ENDIF
   SENDMESSAGE( ::oParent:Handle, WM_SIZE, 0, MAKELPARAM( ::nWidth, ::nHeight ) )   
   ::oParent:DelControl( Self )
RETURN Nil

METHOD Hide CLASS HPanel
   LOCAL i
   LOCAL aCoors := GetWindowRect( ::handle )
   
   IF ::lHide
      Return Nil
   ENDIF
   nrePaint := 0
   IF __ObjHasMsg( ::oParent,"AOFFSET" ) .AND. ::oParent:type == WND_MDI
      IF ::nWidth > ::nHeight .OR. ::nWidth == 0
         ::oParent:aOffset[2] -= ::nHeight
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[1] -= ::nWidth
         ELSE
            ::oParent:aOffset[3] -= ::nWidth
         ENDIF
      ENDIF
   ENDIF
	 Super:Hide()
	 IF ::oParent:type == WND_MDI 
       SENDMESSAGE( ::oParent:Handle, WM_SIZE, 0, MAKELPARAM( ::nWidth, ::nHeight ) )
	 ENDIF   
	 RETURN Nil

METHOD Show CLASS HPanel
   LOCAL i

   IF ! ::lHide
      Return Nil
   ENDIF
   nrePaint := 0
   IF __ObjHasMsg( ::oParent,"AOFFSET" ) .AND. ::oParent:type == WND_MDI   //ISWINDOwVISIBLE( ::handle )
      IF ::nWidth > ::nHeight .OR. ::nWidth == 0
         ::oParent:aOffset[2] += ::nHeight 
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[1] += ::nWidth
         ELSE
            ::oParent:aOffset[3] += ::nWidth
         ENDIF
      ENDIF
   ENDIF
   Super:Show()	 
   IF ::oParent:type == WND_MDI
       nrePaint := -1
       SENDMESSAGE( ::oParent:Handle, WM_SIZE, 0, MAKELPARAM( ::nWidth, ::nHeight ) )
   ENDIF   
	 RETURN Nil

METHOD Resize CLASS HPanel
   LOCAL i
   LOCAL aCoors := GetWindowRect( ::handle )
   Local nHeight := aCoors[ 4 ] - aCoors[ 2 ]
   Local nWidth  := aCoors[ 3 ] - aCoors[ 1 ]

   IF !iswindowvisible( ::handle ) .OR. ::nHeight = nHeight
      Return Nil
   ENDIF
   
   IF __ObjHasMsg( ::oParent,"AOFFSET" ) .AND. ::oParent:type == WND_MDI   //ISWINDOwVISIBLE( ::handle )
      IF ::nWidth > ::nHeight .OR. ::nWidth == 0
         ::oParent:aOffset[2] += ( nHeight  - ::nHeight )
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[1] += ( nWidth - ::nWidth )
         ELSE
            ::oParent:aOffset[3] += ( nWidth - ::nWidth )
         ENDIF
      ENDIF
      SENDMESSAGE( ::oParent:Handle, WM_SIZE, 0, MAKELPARAM( nWidth, nHeight ) )
   ELSE
      RETURN Nil   
   ENDIF
   ::nWidth := aCoors[3] - aCoors[1]
   ::nHeight := aCoors[4] - aCoors[2]
   RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW )  // Force a complete redraw    
	 RETURN Nil
	 
