/*
 * $Id: hrebar.prg,v 1.5 2008-05-27 12:10:55 lculik Exp $
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

CLASS hrebar INHERIT HControl

   DATA winclass INIT "ReBarWindow32"
   Data TEXT, id, nTop, nLeft, nwidth, nheight
   CLASSDATA oSelected INIT Nil
   Data ExStyle
   Data bClick
   DATA lVert
   DATA hTool
   DATA m_nWidth,m_nHeight

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lVert)
   METHOD Redefine( oWndParent,nId,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lVert)

   METHOD Activate()
   METHOD INIT()
   METHOD ADDBARColor( pBar, clrFore, clrBack, pszText, dwStyle ) INLINE ADDBARCOLORS( ::handle, pBar, clrFore, clrBack, pszText, dwStyle )
   METHOD ADDBARBITMAP( pBar, pszText, pbmp, dwStyle ) INLINE ADDBARBITMAP(::handle, pBar, pszText, pbmp, dwStyle )

ENDCLASS


METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lvert) CLASS hrebar
   Default  lVert  to .f.
   nstyle   := Hwg_BitOr( IIF( nStyle == NIL, 0, nStyle ), ;
                           WS_VISIBLE + WS_CHILD )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )
   HWG_InitCommonControlsEx()


   ::Activate()

Return Self



METHOD Redefine( oWndParent,nId,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lVert)  CLASS hrebar
   Default  lVert to .f.
   Super:New( oWndParent,nId,0,0,0,0,0,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )
   HWG_InitCommonControlsEx()

   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0

Return Self


METHOD Activate CLASS hrebar

   IF !empty( ::oParent:handle ) 

      ::handle := CREATEREBAR( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight)

      ::Init()
   ENDIF
RETURN Nil

METHOD INIT CLASS hrebar

Local aButton :={}

   IF !::lInit
      Super:Init()
//      REBARSETIMAGELIST(::handle,nil)
   endif
RETURN Nil

