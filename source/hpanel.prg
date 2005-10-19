/*
 * $Id: hpanel.prg,v 1.11 2005-10-19 10:04:27 alkresin Exp $
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
   ELSEIF msg == WM_ERASEBKGND
      IF ::brush != Nil
         IF Valtype( ::brush ) != "N"
            FillRect( wParam, 0,0,::nWidth,::nHeight,::brush:handle )
         ENDIF
         Return 1
      ENDIF
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL
         onTrackScroll( Self,wParam,lParam )
      ENDIF
      Return Super:onEvent( msg, wParam, lParam )
   ENDIF

Return -1

METHOD Init CLASS HPanel

   IF !::lInit
      IF ::bSize == Nil
         IF ::nHeight!=0 .AND. ( ::nWidth>::nHeight .OR. ::nWidth==0 )
            ::bSize := {|o,x,y|o:Move( 0,::nTop,x,::nHeight )}
         ELSEIF ::nWidth!=0 .AND. ( ::nHeight>::nWidth .OR. ::nHeight==0 )
            ::bSize := {|o,x,y|o:Move( ::nLeft,0,::nWidth,y )}
         ENDIF
      ENDIF

      Super:Init()
      ::nHolder := 1
      SetWindowObject( ::handle,Self )
      Hwg_InitWinCtrl( ::handle )
   ENDIF

Return Nil


METHOD Redefine( oWndParent,nId,nHeight,bInit,bSize,bPaint,lDocked ) CLASS HPanel
Local oParent:=iif(oWndParent==Nil, ::oDefaultParent, oWndParent)

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

