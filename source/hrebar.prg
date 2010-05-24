/*
 * $Id: hrebar.prg,v 1.8 2010-05-24 14:57:03 lfbasso Exp $
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
   DATA TEXT, id, nTop, nLeft, nwidth, nheight
   CLASSDATA oSelected INIT Nil
   DATA ExStyle
   DATA bClick
   DATA lVert
   DATA hTool
   DATA m_nWidth, m_nHeight

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, ;
               bSize, bPaint, ctooltip, tcolor, bcolor, lVert )
   METHOD Redefine( oWndParent, nId, oFont, bInit, ;
                    bSize, bPaint, ctooltip, tcolor, bcolor, lVert )

   METHOD Activate()
   METHOD INIT()
   METHOD ADDBARColor( pBar, clrFore, clrBack, pszText, dwStyle ) INLINE ADDBARCOLORS( ::handle, pBar, clrFore, clrBack, pszText, dwStyle )
   METHOD ADDBARBITMAP( pBar, pszText, pbmp, dwStyle ) INLINE ADDBARBITMAP( ::handle, pBar, pszText, pbmp, dwStyle )

ENDCLASS


METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, ;
            bSize, bPaint, ctooltip, tcolor, bcolor, lvert ) CLASS hrebar

   HB_SYMBOL_UNUSED( cCaption )

   DEFAULT  lvert  TO .f.
   nStyle   := Hwg_BitOr( IIf( nStyle == NIL, 0, nStyle ), ;
                          WS_VISIBLE + WS_CHILD ) 
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor )
   HWG_InitCommonControlsEx()


   ::Activate()

   RETURN Self



METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
                 bSize, bPaint, ctooltip, tcolor, bcolor, lVert )  CLASS hrebar

   HB_SYMBOL_UNUSED( cCaption )

   DEFAULT  lVert TO .f.
   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor )
   HWG_InitCommonControlsEx()

   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0

   RETURN Self


METHOD Activate CLASS hrebar

   IF ! Empty( ::oParent:handle )

      ::handle := CREATEREBAR( ::oParent:handle, ::id, ;
                               ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )

      ::Init()
   ENDIF
   RETURN Nil

METHOD INIT CLASS hrebar

   IF ! ::lInit
      Super:Init()
//      REBARSETIMAGELIST(::handle,nil)
   ENDIF
   RETURN Nil

