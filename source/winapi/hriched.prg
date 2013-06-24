/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HRichEdit class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HRichEdit INHERIT HControl

#ifdef UNICODE
   CLASS VAR winclass INIT "RichEdit20W"
#else
   CLASS VAR winclass INIT "RichEdit20A"
#endif
   DATA lChanged    INIT .F.

   METHOD New( oWndParent,nId,vari,nStyle,nLeft,nTop,nWidth,nHeight, ;
         oFont,bInit,bSize,bPaint,bGfocus,bLfocus,ctooltip,tcolor,bcolor )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()

ENDCLASS

METHOD New( oWndParent,nId,vari,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  oFont,bInit,bSize,bPaint,bGfocus,bLfocus,ctooltip, ;
                  tcolor,bcolor ) CLASS HRichEdit

   nStyle := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), WS_CHILD+WS_VISIBLE+WS_TABSTOP+WS_BORDER )
   ::Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,Iif( bcolor==Nil,hwg_Getsyscolor( COLOR_BTNHIGHLIGHT ),bcolor ) )

   ::title   := vari

   hwg_InitRichEdit()

   ::Activate()

   IF bGfocus != Nil
      ::oParent:AddEvent( EN_SETFOCUS,::id,bGfocus )
   ENDIF
   IF bLfocus != Nil
      ::oParent:AddEvent( EN_KILLFOCUS,::id,bLfocus )
   ENDIF

Return Self

METHOD Activate CLASS HRichEdit
   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createrichedit( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF
Return Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HRichEdit
Local nDelta

   IF msg == WM_CHAR
      ::lChanged := .T.
   ELSEIF msg == WM_KEYDOWN
      wParam := hwg_PtrToUlong( wParam )
      IF wParam == 27 // ESC 
         IF hwg_Getparent(::oParent:handle) != Nil 
            hwg_Sendmessage( hwg_Getparent(::oParent:handle),WM_CLOSE,0,0 ) 
         ENDIF 
      ENDIF 

      IF wParam == 46     // Del
         ::lChanged := .T.
      ENDIF
   ELSEIF msg == WM_MOUSEWHEEL
      nDelta := hwg_Hiword( wParam )
      nDelta := Iif( nDelta > 32768, nDelta - 65535, nDelta )
      hwg_Sendmessage( ::handle,EM_SCROLL, Iif(nDelta>0,SB_LINEUP,SB_LINEDOWN), 0 )
      hwg_Sendmessage( ::handle,EM_SCROLL, Iif(nDelta>0,SB_LINEUP,SB_LINEDOWN), 0 )
   ELSEIF msg == WM_DESTROY
      ::End()
   ELSEIF ::bOther != Nil
      Return Eval( ::bOther, Self, msg, wParam, lParam )
   ENDIF

Return -1

METHOD Init()  CLASS HRichEdit
   IF !::lInit
      ::Super:Init()
      ::nHolder := 1
      hwg_Setwindowobject( ::handle,Self )
      Hwg_InitRichProc( ::handle )
   ENDIF
Return Nil

