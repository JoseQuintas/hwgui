/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HProgressBar class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
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

   METHOD New( oWndParent,nId,nLeft,nTop,nWidth,nHeight,maxPos,nRange, bInit,bSize,bPaint,ctooltip )
   METHOD NewBox( cTitle,nLeft,nTop,nWidth,nHeight,maxPos,nRange,bExit,bInit,bSize,bPaint,ctooltip )
   METHOD Activate()
   METHOD Increment() INLINE UpdateProgressBar( ::handle )
   METHOD Step()
   METHOD Set( cTitle,nPos )
   METHOD Close()

ENDCLASS

METHOD New( oWndParent,nId,nLeft,nTop,nWidth,nHeight,maxPos,nRange,bInit,bSize,bPaint,ctooltip ) CLASS HProgressBar

   Super:New( oWndParent,nId,,nLeft,nTop,nWidth,nHeight,,bInit,bSize,bPaint,ctooltip )

   ::maxPos  := Iif( maxPos==Nil,20,maxPos )
   ::lNewBox := .F.
   ::nLimit := Iif( nRange != Nil,Int( nRange/::maxPos ),1 )

   ::Activate()

Return Self

METHOD NewBox( cTitle,nLeft,nTop,nWidth,nHeight,maxPos,nRange,bExit ) CLASS HProgressBar

   // ::classname:= "HPROGRESSBAR"
   ::style   := WS_CHILD+WS_VISIBLE
   nWidth := Iif( nWidth==Nil,220,nWidth )
   nHeight := Iif( nHeight==Nil,60,nHeight )
   nLeft   := Iif( nLeft==Nil,0,nLeft )
   nTop    := Iif( nTop==Nil,0,nTop )
   nWidth  := Iif( nWidth==Nil,220,nWidth )
   nHeight := Iif( nHeight==Nil,60,nHeight )
   ::nLeft := 20
   ::nTop  := 25
   ::nWidth  := nWidth-40
   ::nheight  := 20
   ::maxPos  := Iif( maxPos==Nil,20,maxPos )
   ::lNewBox := .T.
   ::nLimit := Iif( nRange != Nil,Int( nRange/::maxPos ),1 )

   INIT DIALOG ::oParent TITLE cTitle       ;
        AT nLeft,nTop SIZE nWidth,nHeight   ;
        STYLE WS_POPUP+WS_VISIBLE+WS_CAPTION+WS_SYSMENU+WS_SIZEBOX+Iif( nTop==0,DS_CENTER,0 )+DS_SYSMODAL

   IF bExit != Nil
      ::oParent:bDestroy := bExit
   ENDIF

   ACTIVATE DIALOG ::oParent NOMODAL

   ::id := ::NewId()
   ::Activate()
   ::oParent:AddControl( Self )

Return Self

METHOD Activate CLASS HProgressBar

   IF !empty(::oParent:handle )
      ::handle := CreateProgressBar( ::oParent:handle, ::maxPos, ;
                  ::nLeft, ::nTop, ::nWidth,::nHeight )
      ::Init()
   ENDIF
Return Nil

METHOD Step()

   ::nCount ++
   IF ::nCount == ::nLimit
      ::nCount := 0
      UpdateProgressBar( ::handle )
   ENDIF

Return Nil

METHOD Set( cTitle,nPos ) CLASS HProgressBar

   IF cTitle != Nil
      SetWindowText( ::oParent:handle,cTitle )
   ENDIF
   IF nPos != Nil
      SetProgressBar( ::handle,nPos )
   ENDIF

Return Nil

METHOD Close()

   HWG_DestroyWindow( ::handle )
   IF ::lNewBox
      EndDialog( ::oParent:handle )
   ENDIF

Return Nil

