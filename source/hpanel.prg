/*
 * $Id: hpanel.prg,v 1.7 2004-10-19 05:43:42 alkresin Exp $
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

CLASS HPanel INHERIT HControl

   DATA winclass   INIT "PANEL"

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  bInit,bSize,bPaint,lDocked )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Redefine( oWndParent,nId,nHeight,bInit,bSize,bPaint,lDocked )
   METHOD Paint()

ENDCLASS


METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  bInit,bSize,bPaint,lDocked ) CLASS HPanel
   Local oParent:=iif(oWndParent==Nil, ::oDefaultParent, oWndParent)
   IF bSize == Nil
      bSize := {|o,x,y|MoveWindow(o:handle,0,0,Iif(::nHeight!=0.and.(::nWidth>::nHeight.or.::nWidth==0),x,::nWidth),Iif(::nWidth!=0.and.(::nHeight>::nWidth.or.::nHeight==0),y,::nHeight))}
   ENDIF
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,Iif( nWidth==Nil,0,nWidth ), ;
                  nHeight,oParent:oFont,bInit, ;
                  bSize,bPaint )

   ::bPaint  := bPaint
   IF __ObjHasMsg( ::oParent,"AOFFSET" ) .AND. ::oParent:type == WND_MDI
      IF ::nWidth > ::nHeight .OR. ::nWidth == 0
         ::oParent:aOffset[2] := ::nHeight
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[1] := ::nWidth
         ELSE
            ::oParent:aOffset[3] := ::nWidth
         ENDIF
      ENDIF
   ENDIF

   hwg_RegPanel()
   ::Activate()

Return Self

METHOD Activate CLASS HPanel
Local handle := ::oParent:handle, oClient

   IF handle != 0
      ::handle := CreatePanel( handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
Return Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HPanel

   IF msg == WM_PAINT
      ::Paint()
   ELSE
      Return Super:onEvent( msg, wParam, lParam )
   ENDIF

Return -1

METHOD Init CLASS HPanel

   Super:Init()
   ::nHolder := 1
   SetWindowObject( ::handle,Self )
   Hwg_InitWinCtrl( ::handle )
Return Nil


METHOD Redefine( oWndParent,nId,nHeight,bInit,bSize,bPaint,lDocked ) CLASS HPanel
   Local oParent:=iif(oWndParent==Nil, ::oDefaultParent, oWndParent)

   IF bSize == Nil
      bSize := {|o,x,y|MoveWindow(o:handle,0,0,Iif(::nHeight!=0.and.(::nWidth>::nHeight.or.::nWidth==0),x,::nWidth),Iif(::nWidth!=0.and.(::nHeight>::nWidth.or.::nHeight==0),y,::nHeight))}
   ENDIF
   Super:New( oWndParent,nId,0,0,0,0, ;
                  IIF( nHeight!=Nil,nHeight,0 ),oParent:oFont,bInit, ;
                  bSize,bPaint )

   ::bPaint  := bPaint
   hwg_RegPanel()

Return Self

METHOD Paint() CLASS HPanel
Local pps, hDC, aCoors, oPenLight, oPenGray

   IF ::bPaint != Nil
      Eval( ::bPaint,Self )
   ELSE
      pps := DefinePaintStru()
      hDC := BeginPaint( ::handle, pps )
      aCoors := GetClientRect( ::handle )

      oPenLight := HPen():Add( BS_SOLID,1,GetSysColor(COLOR_3DHILIGHT) )
      SelectObject( hDC, oPenLight:handle )
      DrawLine( hDC, 5,1,aCoors[3]-5,1 )
      oPenGray := HPen():Add( BS_SOLID,1,GetSysColor(COLOR_3DSHADOW) )
      SelectObject( hDC, oPenGray:handle )
      DrawLine( hDC, 5,0,aCoors[3]-5,0 )

      oPenGray:Release()
      oPenLight:Release()
      EndPaint( ::handle, pps )
   ENDIF

Return Nil

