/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HOwnButton class, which implements owner drawn buttons
 *
 * Copyright 2005 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "inkey.ch"
#include "hbclass.ch"
#include "hwgui.ch"

CLASS HOwnButton INHERIT HControl

   CLASS VAR cPath SHARED
   DATA winclass   INIT "OWNBTN"
   DATA lFlat
   DATA state
   DATA bClick
   DATA lPress  INIT .F.
   DATA text,ofont,xt,yt,widtht,heightt
   DATA bitmap,xb,yb,widthb,heightb,lTransp,trColor, oBitmap
   DATA lEnabled INIT .T.
   DATA nOrder

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  bInit,bSize,bPaint,bClick,lflat,              ;
                  cText,color,font,xt,yt,widtht,heightt,        ;
                  bmp,lResour,xb,yb,widthb,heightb,lTr,trColor, ;
                  cTooltip, lEnabled )

   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Paint()
   METHOD MouseMove( wParam, lParam )
   METHOD MDown()
   METHOD MUp()
   METHOD Press()   INLINE ( ::lPress := .T., ::MDown() )
   METHOD Release()
   METHOD End()
   METHOD Enable()
   METHOD Disable()

ENDCLASS

METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,   ;
                  bInit,bSize,bPaint,bClick,lflat,             ;
                  cText,color,font,xt,yt,widtht,heightt,       ;
                  bmp,lResour,xb,yb,widthb,heightb,lTr,trColor,;
                  cTooltip, lEnabled  ) CLASS HOwnButton

   ::Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,font,bInit, ;
                  bSize,bPaint,ctooltip )

   ::lFlat   := Iif( lFlat==Nil,.F.,lFlat )
   ::bClick  := bClick
   ::state   := OBTN_INIT
   ::nOrder  := iif( oWndParent==nil, 0, len( oWndParent:aControls ) )
   
   ::text    := cText
   ::tcolor  := Iif( color==Nil, 0, color )
   ::xt      := xt
   ::yt      := yt
   ::widtht  := widtht
   ::heightt := heightt

   if lEnabled!=Nil
      ::lEnabled:=lEnabled
   endif
   IF bmp != Nil
      ::bitmap := Iif( (lResour!=Nil.AND.lResour).OR.Valtype(bmp)=="N", ;
                     HBitmap():AddResource( bmp ), ;
                     HBitmap():AddFile( Iif( ::cPath!=Nil,::cPath+bmp,bmp ) ) )
      IF ::bitmap != Nil .AND. lTr != Nil .AND. lTr
         ::lTransp := .T.
         hwg_alpha2pixbuf( ::bitmap:handle, Iif( trColor!=Nil,trColor,16777215 ) )
      ENDIF
   ENDIF
   ::xb      := xb
   ::yb      := yb
   ::widthb  := widthb
   ::heightb := heightb
   ::trColor := trColor

   ::Activate()

Return Self

METHOD Activate CLASS HOwnButton
   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createownbtn( ::oParent:handle, ::id, ;
                  ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   if !::lEnabled
      hwg_Enablewindow( ::handle, .f. )
      ::Disable()
   EndIf

   ENDIF
Return Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HOwnButton

   IF msg == WM_PAINT
      ::Paint()
   ELSEIF msg == WM_LBUTTONDOWN
      ::MDown()
   ELSEIF msg == WM_LBUTTONUP
      ::MUp()
   ELSEIF msg == WM_MOUSEMOVE
      ::MouseMove( wParam, lParam )
   ELSEIF msg == WM_DESTROY
      ::End()
   ENDIF

Return 0

METHOD Init CLASS HOwnButton

   IF !::lInit
      ::Super:Init()
      hwg_Setwindowobject( ::handle,Self )
   ENDIF

Return Nil

METHOD Paint() CLASS HOwnButton
Local hDC := hwg_Getdc( ::handle )
Local aCoors, aMetr, oPen, oldBkColor, x1, y1, x2, y2

   aCoors := hwg_Getclientrect( ::handle )

   // oldBkColor := hwg_Setbkcolor( hDC,hwg_Getsyscolor(COLOR_3DFACE) )
   IF ::state == OBTN_INIT
      ::state := OBTN_NORMAL
   ENDIF

   IF ::lFlat
      IF ::state == OBTN_NORMAL
         hwg_Drawbutton( hDC, aCoors[1],aCoors[2],aCoors[3],aCoors[4],0 )
      ELSEIF ::state == OBTN_MOUSOVER
         hwg_Drawbutton( hDC, aCoors[1],aCoors[2],aCoors[3],aCoors[4],1 )
      ELSEIF ::state == OBTN_PRESSED
         hwg_Drawbutton( hDC, aCoors[1],aCoors[2],aCoors[3],aCoors[4],2 )
      ENDIF
   ELSE
      IF ::state == OBTN_NORMAL
         hwg_Drawbutton( hDC, aCoors[1],aCoors[2],aCoors[3],aCoors[4],5 )
      ELSEIF ::state == OBTN_PRESSED
         hwg_Drawbutton( hDC, aCoors[1],aCoors[2],aCoors[3],aCoors[4],6 )
      ENDIF
   ENDIF

   IF ::bitmap != Nil
      IF ::widthb == Nil .OR. ::widthb == 0
         ::widthb := ::bitmap:nWidth
         ::heightb := ::bitmap:nHeight
      ENDIF
      x1 := Iif( ::xb!=Nil .AND. ::xb!=0, ::xb, ;
                 Round( (aCoors[3]-aCoors[1]-::widthb) / 2, 0 ) )
      y1 := Iif( ::yb!=Nil .AND. ::yb!=0, ::yb, ;
                 Round( (aCoors[4]-aCoors[2]-::heightb) / 2, 0 ) )
      if ::lEnabled
         if ::oBitmap!=Nil
            ::bitmap:handle:=::oBitmap
            ::oBitmap:=Nil
         EndIf
         hwg_Drawbitmap( hDC, ::bitmap:handle,, x1, y1, ::widthb, ::heightb )
      Else
         ::oBitmap:=::bitmap:handle
         hwg_Drawgraybitmap( hDC, ::bitmap:handle, x1, y1 )
      EndIf
   ENDIF

   IF ::text != Nil
      IF ::ofont != Nil
         hwg_Selectobject( hDC, ::ofont:handle )
      ELSEIF ::oParent:oFont != Nil
         hwg_Selectobject( hDC, ::oParent:ofont:handle )
      ENDIF
      aMetr := hwg_Gettextmetric( hDC )
      if ::lEnabled //if button is enabled
         hwg_Settextcolor( hDC,::tcolor )
      Else
         hwg_Settextcolor( hDC, 0 )
      EndIf
      x1 := Iif( ::xt!=Nil .AND. ::xt!=0, ::xt, aCoors[1]+2 )
      y1 := Iif( ::yt!=Nil .AND. ::yt!=0, ::yt, ;
                              Round( ( aCoors[4]-aCoors[2]-aMetr[1] ) / 2, 0 ) )
      x2 := Iif( ::widtht!=Nil .AND. ::widtht!=0, ;
                          ::xt+::widtht-1, aCoors[3]-2 )
      y2 := Iif( ::heightt!=Nil .AND. ::heightt!=0, ;
                 ::yt+::heightt-1, y1+aMetr[1] )
      // hwg_Settransparentmode( hDC,.T. )
      hwg_Drawtext( hDC, ::text, x1, y1, x2, y2, Iif( ::xt!=Nil.AND.::xt!=0,DT_LEFT,DT_CENTER ) )
      // hwg_Settransparentmode( hDC,.F. )
   ENDIF
   // hwg_Setbkcolor( hDC,oldBkColor )
   hwg_Releasedc( ::handle, hDC )

Return Nil

METHOD MouseMove( wParam, lParam )  CLASS HOwnButton
Local lEnter := ( hwg_BitAnd( wParam,16 ) > 0 )
Local res := .F.

   IF ::state != OBTN_INIT
      IF !lEnter .AND. !::lPress
         ::state := OBTN_NORMAL
         hwg_Redrawwindow( ::handle )
      ENDIF
      IF lEnter .AND. ::state == OBTN_NORMAL
         ::state := OBTN_MOUSOVER
         hwg_Redrawwindow( ::handle )
      ENDIF
   ENDIF
   
Return Nil

METHOD MDown()  CLASS HOwnButton
   IF ::state != OBTN_PRESSED
      ::state := OBTN_PRESSED
      hwg_Redrawwindow( ::handle )
      hwg_Setfocus( ::handle )
   ENDIF
Return Nil

METHOD MUp() CLASS HOwnButton
   IF ::state == OBTN_PRESSED
      IF !::lPress
         ::state := OBTN_NORMAL
         hwg_Redrawwindow( ::handle )
      ENDIF
      IF ::bClick != Nil
         Eval( ::bClick, ::oParent, ::id )
      ENDIF
   ENDIF

Return Nil

METHOD Release()  CLASS HOwnButton
   ::lPress := .F.
   ::state := OBTN_NORMAL
   hwg_Redrawwindow( ::handle )
Return Nil

METHOD End()  CLASS HOwnButton

   ::Super:End()
   IF ::ofont != Nil
       ::ofont:Release()
       ::ofont := Nil
   ENDIF
   IF ::bitmap != Nil
      ::bitmap:Release()
      ::bitmap := Nil
   ENDIF

Return Nil

METHOD Enable() CLASS HOwnButton

   hwg_Enablewindow( ::handle, .T. )
   ::lEnabled:=.T.
   hwg_Redrawwindow( ::handle )

Return Nil

METHOD Disable() CLASS HOwnButton

   ::state   := OBTN_INIT
   ::lEnabled:=.F.
   hwg_Redrawwindow( ::handle )
   hwg_Enablewindow( ::handle, .F. )

Return Nil

