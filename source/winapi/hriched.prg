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

   METHOD New( oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, tcolor, bcolor, bOther )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Setcolor( tColor, bColor, lRedraw )

ENDCLASS

METHOD New( oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, ;
      tcolor, bcolor, bOther ) CLASS HRichEdit

   nStyle := Hwg_BitOr( iif( nStyle == Nil,0,nStyle ), WS_CHILD + WS_VISIBLE + WS_TABSTOP + WS_BORDER )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, iif( bcolor == Nil, hwg_Getsyscolor( COLOR_BTNHIGHLIGHT ), bcolor ) )

   ::title  := vari
   ::bOther := bOther

   hwg_InitRichEdit()

   ::Activate()

   IF bGfocus != Nil
      ::oParent:AddEvent( EN_SETFOCUS, ::id, bGfocus )
   ENDIF
   IF bLfocus != Nil
      ::oParent:AddEvent( EN_KILLFOCUS, ::id, bLfocus )
   ENDIF

   RETURN Self

METHOD Activate CLASS HRichEdit

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createrichedit( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HRichEdit

   LOCAL nDelta

   IF ::bOther != Nil
      nDelta := Eval( ::bOther, Self, msg, wParam, lParam )
      IF ValType( nDelta ) != "N" .OR. nDelta > - 1
         RETURN nDelta
      ENDIF
   ENDIF
   IF msg == WM_CHAR
      ::lChanged := .T.
   ELSEIF msg == WM_KEYDOWN
      wParam := hwg_PtrToUlong( wParam )
      IF wParam == 27 // ESC
         IF hwg_Getparent( ::oParent:handle ) != Nil
            hwg_Sendmessage( hwg_Getparent( ::oParent:handle ), WM_CLOSE, 0, 0 )
         ENDIF
      ENDIF

      IF wParam == 46     // Del
         ::lChanged := .T.
      ENDIF
   ELSEIF msg == WM_MOUSEWHEEL
      nDelta := hwg_Hiword( wParam )
      nDelta := iif( nDelta > 32768, nDelta - 65535, nDelta )
      hwg_Sendmessage( ::handle, EM_SCROLL, iif( nDelta > 0,SB_LINEUP,SB_LINEDOWN ), 0 )
      hwg_Sendmessage( ::handle, EM_SCROLL, iif( nDelta > 0,SB_LINEUP,SB_LINEDOWN ), 0 )
   ELSEIF msg == WM_DESTROY
      ::End()
   ENDIF

   Return - 1

METHOD Init()  CLASS HRichEdit

   IF !::lInit
      ::Super:Init()
      ::nHolder := 1
      hwg_Setwindowobject( ::handle, Self )
      Hwg_InitRichProc( ::handle )
      ::SetColor( ::tColor, ::bColor )
   ENDIF

   RETURN Nil

METHOD Setcolor( tColor, bColor, lRedraw )  CLASS HRichEdit

   IF tcolor != Nil
      hwg_re_SetDefault( ::handle, tColor )
   ENDIF
   IF bColor != Nil
      hwg_Sendmessage( ::Handle, EM_SETBKGNDCOLOR, 0, bColor )
   ENDIF
   ::Super:Setcolor( tColor, bColor, lRedraw )

   RETURN Nil
