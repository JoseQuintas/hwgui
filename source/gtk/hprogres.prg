/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HProgressBar class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/
/*
 * Copyright 2008 Luiz Rafal Culik Guimaraes <luiz at xharbour.com.br>
 * port for linux version
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HProgressBar INHERIT HControl

   CLASS VAR winclass   INIT "ProgressBar"
   DATA  maxPos
   DATA  lNewBox
   DATA  nCount INIT 0
   DATA  nLimit

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, maxPos, nRange, bInit, bSize, bPaint, ctooltip )
   METHOD NewBox( cTitle, nLeft, nTop, nWidth, nHeight, maxPos, nRange, bExit, bInit, bSize, bPaint, ctooltip )
   METHOD Activate()
   METHOD Increment() INLINE hwg_Updateprogressbar( ::handle )
   METHOD Step()
   METHOD SET( cTitle, nPos )
   METHOD CLOSE()

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, maxPos, nRange, bInit, bSize, bPaint, ctooltip ) CLASS HProgressBar

   ::Super:New( oWndParent, nId, , nLeft, nTop, nWidth, nHeight, , bInit, bSize, bPaint, ctooltip )

   ::maxPos  := iif( maxPos == Nil, 20, maxPos )
   ::lNewBox := .F.
   ::nLimit := iif( nRange != Nil, Int( nRange/::maxPos ), 1 )

   ::Activate()

   RETURN Self

METHOD NewBox( cTitle, nLeft, nTop, nWidth, nHeight, maxPos, nRange, bExit ) CLASS HProgressBar

   // ::classname:= "HPROGRESSBAR"
   ::style   := WS_CHILD + WS_VISIBLE
   nWidth := iif( nWidth == Nil, 220, nWidth )
   nHeight := iif( nHeight == Nil, 60, nHeight )
   nLeft   := iif( nLeft == Nil, 0, nLeft )
   nTop    := iif( nTop == Nil, 0, nTop )
   nWidth  := iif( nWidth == Nil, 220, nWidth )
   nHeight := iif( nHeight == Nil, 60, nHeight )
   ::nLeft := 20
   ::nTop  := 25
   ::nWidth  := nWidth - 40
   ::nheight  := 20
   ::maxPos  := iif( maxPos == Nil, 20, maxPos )
   ::lNewBox := .T.
   ::nLimit := iif( nRange != Nil, Int( nRange/::maxPos ), 1 )

   INIT DIALOG ::oParent TITLE cTitle       ;
      AT nLeft, nTop SIZE nWidth, nHeight   ;
      STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX + iif( nTop == 0, DS_CENTER, 0 ) + DS_SYSMODAL

   IF bExit != Nil
      ::oParent:bDestroy := bExit
   ENDIF

   ACTIVATE DIALOG ::oParent NOMODAL

   ::id := ::NewId()
   ::Activate()
   ::oParent:AddControl( Self )

   RETURN Self

METHOD Activate CLASS HProgressBar

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createprogressbar( ::oParent:handle, ::maxPos, ;
         ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN Nil

METHOD Step()

   ::nCount ++
   IF ::nCount == ::nLimit
      ::nCount := 0
      hwg_Updateprogressbar( ::handle )
   ENDIF

   RETURN Nil

METHOD SET( cTitle, nPos ) CLASS HProgressBar

   IF cTitle != Nil
      hwg_Setwindowtext( ::oParent:handle, cTitle )
   ENDIF
   IF nPos != Nil
      IF ::nLimit * ::maxpos != 0
         nPos := nPos / (::nLimit*::maxpos)
      ENDIF
      hwg_Setprogressbar( ::handle, nPos )
   ENDIF

   RETURN Nil

METHOD CLOSE()

   HWG_DestroyWindow( ::handle )
   IF ::lNewBox
      hwg_EndDialog( ::oParent:handle )
   ENDIF

   RETURN Nil
