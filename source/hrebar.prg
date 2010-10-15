/*
 * $Id: hrebar.prg,v 1.10 2010-10-15 16:07:34 lfbasso Exp $
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
   DATA aBands INIT  {}

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, ;
               bSize, bPaint, ctooltip, tcolor, bcolor, lVert )
   METHOD Redefine( oWndParent, nId, oFont, bInit, ;
                    bSize, bPaint, ctooltip, tcolor, bcolor, lVert )

   METHOD Activate()
   METHOD INIT()
   METHOD ADDBARColor( pBar, clrFore, clrBack, pszText, dwStyle ) INLINE ADDBARCOLORS( ::handle, pBar, clrFore, clrBack, pszText, dwStyle )
   METHOD ADDBARBITMAP( pBar, pszText, pbmp, dwStyle ) INLINE ADDBARBITMAP( ::handle, pBar, pszText, pbmp, dwStyle )
   METHOD RebarBandNew( pBar, pszText, clrFore, clrBack, pbmp, dwStyle ) INLINE ::CreateBands( pBar, pszText, clrFore, clrBack, pbmp, dwStyle )    
   METHOD CreateBands()    

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
      ::CreateBands()
//      REBARSETIMAGELIST(::handle,nil)
   ENDIF
   RETURN Nil


METHOD CreateBands( pBar, pszText, clrFore, clrBack, pbmp, dwStyle ) CLASS hrebar
   LOCAL i

   IF pBar != Nil
      AADD( ::aBands, { pBar, pszText, clrFore, clrBack, pbmp, dwStyle } )
   ENDIF   
   IF ! ::lInit
       RETURN Nil
   ENDIF    
   dwStyle := RBBS_GRIPPERALWAYS + RBBS_USECHEVRON 
   FOR i = 1 TO LEN( ::aBands )
      ::aBands[ i, 4 ] := IIF( ::aBands[ i, 4 ] = Nil, GetSysColor( COLOR_3DFACE ), ::aBands[ i, 4 ] )
      ::aBands[ i, 6 ] := IIF( ::aBands[ i, 6 ] = Nil, dwStyle, ::aBands[ i, 6 ] )
      IF ! Empty( ::aBands[ i, 1 ] )
         ::aBands[ i, 1 ] := IIF( ValType( ::aBands[ i, 1 ] ) = "C", &( ::aBands[ i, 1 ] ), ::aBands[ i, 1 ] )
         IF ( ::aBands[ i, 5 ] != Nil )
            ADDBARBITMAP( ::handle, ::aBands[ i, 1 ]:handle, ::aBands[ i, 2 ], ::aBands[ i, 5 ], ::aBands[ i, 6 ] )
         ELSE   
           ADDBARCOLORS( ::handle, ::aBands[ i, 1 ]:handle, ::aBands[ i, 3 ], ::aBands[ i, 4 ], ::aBands[ i, 2 ], ::aBands[ i, 6 ]  ) 
         ENDIF  
      ENDIF
   NEXT   
   ::aBands := {}
   RETURN Nil