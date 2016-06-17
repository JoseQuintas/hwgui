/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HPanel class 
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HPanel INHERIT HControl

   DATA winclass   INIT "PANEL"

   DATA hBox
   DATA hScrollV  INIT Nil
   DATA hScrollH  INIT Nil
   DATA nScrollV  INIT 0
   DATA nScrollH  INIT 0
   DATA bVScroll, bHScroll

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  bInit,bSize,bPaint,lDocked )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Paint()
   METHOD Move( x1,y1,width,height )

ENDCLASS

METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  bInit,bSize,bPaint,lDocked ) CLASS HPanel
Local oParent:=iif(oWndParent==Nil, ::oDefaultParent, oWndParent)

   ::Super:New( oWndParent,nId,nStyle,nLeft,nTop,Iif( nWidth==Nil,0,nWidth ), ;
                  nHeight,oParent:oFont,bInit, ;
                  bSize,bPaint )

   ::bPaint  := bPaint

   ::Activate()

Return Self

METHOD Activate CLASS HPanel

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createpanel( Self, ::id, ;
                   ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
Return Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HPanel

   IF msg == WM_PAINT
      ::Paint()

   ELSEIF msg == WM_HSCROLL
      IF ::bHScroll != Nil
         Eval( ::bHScroll, Self )
      ENDIF

   ELSEIF msg == WM_VSCROLL
      IF ::bVScroll != Nil
         Eval( ::bVScroll, Self )
      ENDIF

   ELSE
      Return ::Super:onEvent( msg, wParam, lParam )
   ENDIF

Return 0

METHOD Init CLASS HPanel

   IF !::lInit
      IF ::bSize == Nil .AND. Empty( ::Anchor )
         IF ::nHeight!=0 .AND. ( ::nWidth>::nHeight .OR. ::nWidth==0 )
            ::bSize := {|o,x,y|o:Move( ,Iif(::nTop>0,y-::nHeight,0),x,::nHeight )}
         ELSEIF ::nWidth!=0 .AND. ( ::nHeight>::nWidth .OR. ::nHeight==0 )
            ::bSize := {|o,x,y|o:Move( Iif(::nLeft>0,x-::nLeft,0),,::nWidth,y )}
         ENDIF
      ENDIF

      ::Super:Init()
      hwg_Setwindowobject( ::handle,Self )
   ENDIF

Return Nil

METHOD Paint() CLASS HPanel
Local hDC, aCoors, oPenLight, oPenGray

   IF ::bPaint != Nil
      Eval( ::bPaint,Self )
   ELSE
      hDC := hwg_Getdc( ::handle )
      hwg_Drawbutton( hDC, 0,0,::nWidth-1,::nHeight-1,5 )
      hwg_Releasedc( ::handle, hDC )
   ENDIF

Return Nil

METHOD Move( x1,y1,width,height )  CLASS HPanel

   LOCAL lMove := .F. , lSize := .F.

   IF x1 != Nil .AND. x1 != ::nLeft
      ::nLeft := x1
      lMove := .T.
   ENDIF
   IF y1 != Nil .AND. y1 != ::nTop
      ::nTop := y1
      lMove := .T.
   ENDIF
   IF width != Nil .AND. width != ::nWidth
      ::nWidth := width
      lSize := .T.
   ENDIF
   IF height != Nil .AND. height != ::nHeight
      ::nHeight := height
      lSize := .T.
   ENDIF
   IF lMove .OR. lSize
      hwg_MoveWidget( ::hbox, iif( lMove,::nLeft,Nil ), iif( lMove,::nTop,Nil ), ;
         iif( lSize, ::nWidth, Nil ), iif( lSize, ::nHeight, Nil ), .F. )
      IF lSize
         hwg_MoveWidget( ::handle, Nil, Nil, ::nWidth, ::nHeight, .F. )
         hwg_Redrawwindow( ::handle )
      ENDIF
   ENDIF

   //::Super:Move( x1,y1,width,height,.T. )
Return Nil

