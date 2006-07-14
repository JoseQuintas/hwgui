/*
 * $Id: htool.prg,v 1.3 2006-07-14 11:10:27 lculik Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 *
 *
 * Copyright 2004 Luiz Rafael Culik Guimaraes <culikr@brtrubo.com>
 * www - http://sites.uol.com.br/culikr/
*/

#include "windows.ch"
#include "inkey.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define TRANSPARENT 1

CLASS HToolBar INHERIT HControl

   DATA winclass INIT "ToolbarWindow32"
   Data TEXT, id, nTop, nLeft, nwidth, nheight
   CLASSDATA oSelected INIT Nil
   DATA State INIT 0
   Data ExStyle
   Data bClick, cTooltip

   DATA lPress INIT .F.
   DATA lFlat
   DATA nOrder
   Data aItem init {}

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp ,aItem)
   METHOD Redefine( oWndParent,nId,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp ,aItem)

   METHOD Activate()
   METHOD INIT()
   method AddButton(a,s,d,f,g,h) 
ENDCLASS


METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp ,aitem) CLASS hToolBar
   Default  aItem to {}
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )
   HWG_InitCommonControlsEx()
   ::aitem := aItem

   ::Activate()

Return Self



METHOD Redefine( oWndParent,nId,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp,aItem )  CLASS hToolBar
   Default  aItem to {}
   Super:New( oWndParent,nId,0,0,0,0,0,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )
   HWG_InitCommonControlsEx()
   ::aitem := aItem

   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0

Return Self


RETURN Self

METHOD Activate CLASS hToolBar

   IF ::oParent:handle != 0

      ::handle := CREATETOOLBAR( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::extStyle )

      ::Init()
   ENDIF
RETURN Nil

METHOD INIT CLASS hToolBar
Local n
   IF !::lInit
      Super:Init()
      For n:=1 TO len( ::aItem )
         IF Valtype( ::aItem[ n, 7 ] ) == "B"
            ::oParent:AddEvent( BN_CLICKED, ::aItem[ n, 2 ], ::aItem[ n ,7 ] )
         ENDIF
      NEXT

      TOOLBARADDBUTTONS( ::handle, ::aItem, Len( ::aItem ) )
      SendMessage( ::handle, TB_SETEXTENDEDSTYLE, 0, TBSTYLE_EX_DRAWDDARROWS )
   ENDIF
RETURN Nil



Function ToolbarNotify( oCtrl, wParam,lParam )
    Local aCord
    Local nCode :=  GetNotifyCode( lParam )
    Local nId

    Local nButton 
    Local nPos

    IF nCode == TTN_GETDISPINFO

       nButton :=TOOLBAR_GETDISPINFOID( lParam )
       nPos := AScan( oCtrl:aItem,  { | x | x[ 2 ] == nButton })
       TOOLBAR_SETDISPINFO( lParam, oCtrl:aItem[ nPos, 8 ] )

    ELSEIF nCode == TBN_GETINFOTIP

       nId := TOOLBAR_GETINFOTIPID(lParam)
       nPos := AScan( oCtrl:aItem,  { | x | x[ 2 ] == nId })
       TOOLBAR_GETINFOTIP( lParam, oCtrl:aItem[ nPos, 8 ] )

    ELSEIF nCode == TBN_DROPDOWN
    ENDIF
    
Return 0

METHOD AddButton(nBitIp,nId,bState,bStyle,cText,bClick,c) CLASS hToolBar

   DEFAULT nBitIp to -1
   DEFAULT bstate to TBSTATE_ENABLED
   DEFAULT bstyle to 0x0000
   DEFAULT c to ""
   DEFAULT ctext to ""
   AAdd( ::aItem ,{ nBitIp, nId, bState, bStyle, 0, cText, bClick ,c} )

RETURN Self

