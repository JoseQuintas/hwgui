/*
 * $Id: hpager.prg,v 1.3 2007-11-27 14:00:10 druzus Exp $
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
   METHOd SetScrollArea( nWidth, nHeight ) inline  ::m_nWidth := nWidth, ::m_nHeight := nHeight
   METHOD Activate()
   METHOD INIT()

   METHOD Notify( lParam )
   METHOD PAGERSETCHILD( b ) inline ::hTool:=b,PAGERSETCHILD( ::handle, b )
   METHOD PAGERRECALCSIZE( ) inline PAGERRECALCSIZE( ::handle )
   METHOD PAGERFORWARDMOUSE( b ) inline PAGERFORWARDMOUSE( ::handle, b )
   METHOD PAGERSETBKCOLOR(  b ) inline PAGERSETBKCOLOR( ::handle, b )
   METHOD PAGERGETBKCOLOR( ) inline PAGERGETBKCOLOR( ::handle )
   METHOD PAGERSETBORDER(  b ) inline PAGERSETBORDER( ::handle, b )
   METHOD PAGERGETBORDER( ) inline PAGERGETBORDER( ::handle )
   METHOD PAGERSETPOS(  b ) inline PAGERSETPOS( ::handle, b )
   METHOD PAGERGETPOS(  ) inline PAGERGETPOS( ::handle )
   METHOD PAGERSETBUTTONSIZE(  b ) inline PAGERSETBUTTONSIZE( ::handle, b )
   METHOD PAGERGETBUTTONSIZE( ) inline PAGERGETBUTTONSIZE( ::handle )
   METHOD PAGERGETBUTTONSTATE() inline PAGERGETBUTTONSTATE( ::handle )

ENDCLASS


METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lvert) CLASS HPager
   Default  lVert  to .f.
   ::lVert := lVert
   nstyle   := Hwg_BitOr( IIF( nStyle == NIL, 0, nStyle ), ;
                           WS_VISIBLE + WS_CHILD+if(lvert,PGS_VERT,PGS_HORZ) )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )
   HWG_InitCommonControlsEx()


   ::Activate()

Return Self



METHOD Redefine( oWndParent,nId,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lVert)  CLASS HPager
   Default  lVert to .f.
   Super:New( oWndParent,nId,0,0,0,0,0,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )
   HWG_InitCommonControlsEx()

   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0

Return Self


METHOD Activate CLASS HPager

   IF ::oParent:handle != 0

      ::handle := CREATEPAGER( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, if(::lVert,PGS_VERT,PGS_HORZ ) )

      ::Init()
   ENDIF
RETURN Nil

METHOD INIT CLASS HPager

Local aButton :={}

   IF !::lInit
      Super:Init()
   endif
RETURN Nil

METHOD Notify( lParam ) CLASS HPager

    Local nCode :=  GetNotifyCode( lParam )

    IF nCode == PGN_CALCSIZE
       PAGERONPAGERCALCSIZE( lParam,::hTool )
    ELSEIF nCode == PGN_SCROLL
       PAGERONPAGERSCROLL( lParam )
    ENDIF

Return 0


