/*
 * $Id: htool.prg,v 1.1 2006-07-03 01:47:12 lculik Exp $
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
   method AddButton(a,s,d,f,g,h) // inline aadd(::aItem,aButton)
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

   ENDIF
RETURN Nil



Function ToolbarNotify( oCtrl, wParam,lParam )
    Local aCord


    
Return 0

METHOD AddButton(nBitIp,nId,bstate,bstyle,ctext,bclick) CLASS hToolBar

   DEFAULT nBitIp to -1
   DEFAULT bstate to TBSTATE_ENABLED
   DEFAULT bstyle to 0x0000
   DEFAULT ctext to ""
   AAdd( ::aItem ,{ nBitIp, nId, bstate, bstyle, 0, ctext, bclick } )
RETURN Self
