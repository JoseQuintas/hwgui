/*
 * $Id$
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

CLASS HPager INHERIT HControl

   DATA winclass INIT "SysPager"
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
   METHOD SetScrollArea( nWidth, nHeight ) INLINE  ::m_nWidth := nWidth, ::m_nHeight := nHeight
   METHOD Activate()
   METHOD INIT()

   METHOD Notify( lParam )
   METHOD Pagersetchild( b ) INLINE ::hTool := b, hwg_Pagersetchild( ::handle, b )
   METHOD Pagerrecalcsize( ) INLINE hwg_Pagerrecalcsize( ::handle )
   METHOD Pagerforwardmouse( b ) INLINE hwg_Pagerforwardmouse( ::handle, b )
   METHOD Pagersetbkcolor(  b ) INLINE hwg_Pagersetbkcolor( ::handle, b )
   METHOD Pagergetbkcolor( ) INLINE hwg_Pagergetbkcolor( ::handle )
   METHOD Pagersetborder(  b ) INLINE hwg_Pagersetborder( ::handle, b )
   METHOD Pagergetborder( ) INLINE hwg_Pagergetborder( ::handle )
   METHOD Pagersetpos(  b ) INLINE hwg_Pagersetpos( ::handle, b )
   METHOD Pagergetpos(  ) INLINE hwg_Pagergetpos( ::handle )
   METHOD Pagersetbuttonsize(  b ) INLINE hwg_Pagersetbuttonsize( ::handle, b )
   METHOD Pagergetbuttonsize( ) INLINE hwg_Pagergetbuttonsize( ::handle )
   METHOD Pagergetbuttonstate() INLINE hwg_Pagergetbuttonstate( ::handle )

ENDCLASS


METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, ;
            bSize, bPaint, ctooltip, tcolor, bcolor, lvert ) CLASS HPager

   HB_SYMBOL_UNUSED( cCaption )

   DEFAULT  lvert  TO .f.
   ::lvert := lvert
   nStyle   := Hwg_BitOr( IIf( nStyle == NIL, 0, nStyle ), ;
                          WS_VISIBLE + WS_CHILD + IF( lvert, PGS_VERT, PGS_HORZ ) )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor )
   HWG_InitCommonControlsEx()


   ::Activate()

   RETURN Self



METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
                 bSize, bPaint, ctooltip, tcolor, bcolor, lVert )  CLASS HPager

   HB_SYMBOL_UNUSED( cCaption )

   DEFAULT  lVert TO .f.
   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor )
   HWG_InitCommonControlsEx()

   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0

   RETURN Self


METHOD Activate CLASS HPager

   IF ! Empty( ::oParent:handle )

      ::handle := hwg_Createpager( ::oParent:handle, ::id, ;
                               ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, IF( ::lVert, PGS_VERT, PGS_HORZ ) )

      ::Init()
   ENDIF
   RETURN Nil

METHOD INIT CLASS HPager

   IF ! ::lInit
      ::Super:Init()
   ENDIF
   RETURN Nil

METHOD Notify( lParam ) CLASS HPager

   LOCAL nCode :=  hwg_Getnotifycode( lParam )

   IF nCode == PGN_CALCSIZE
      hwg_Pageronpagercalcsize( lParam, ::hTool )
   ELSEIF nCode == PGN_SCROLL
      hwg_Pageronpagerscroll( lParam )
   ENDIF

   RETURN 0


