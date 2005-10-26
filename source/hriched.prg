/*
 * $Id: hriched.prg,v 1.7 2005-10-26 07:43:26 omm Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HRichEdit class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HRichEdit INHERIT HControl

   CLASS VAR winclass   INIT "RichEdit20A"
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
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,Iif( bcolor==Nil,GetSysColor( COLOR_BTNHIGHLIGHT ),bcolor ) )

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
   IF ::oParent:handle != 0
      ::handle := CreateRichEdit( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF
Return Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HRichEdit
Local nDelta

   // writelog( str(msg) + str(wParam) + str(lParam) )
   IF msg == WM_CHAR
      ::lChanged := .T.
   ELSEIF msg == WM_KEYDOWN
      IF wParam == 46     // Del
         ::lChanged := .T.
      ENDIF
   ELSEIF msg == WM_MOUSEWHEEL
      nDelta := HiWord( wParam )
      nDelta := Iif( nDelta > 32768, nDelta - 65535, nDelta )
      SendMessage( ::handle,EM_SCROLL, Iif(nDelta>0,SB_LINEUP,SB_LINEDOWN), 0 )
      SendMessage( ::handle,EM_SCROLL, Iif(nDelta>0,SB_LINEUP,SB_LINEDOWN), 0 )
   ELSEIF msg == WM_DESTROY
      ::End()
   ELSEIF ::bOther != Nil
      Return Eval( ::bOther, Self, msg, wParam, lParam )
   ENDIF

Return -1

METHOD Init()  CLASS HRichEdit
   IF !::lInit
      Super:Init()
      ::nHolder := 1
      SetWindowObject( ::handle,Self )
      Hwg_InitRichProc( ::handle )
   ENDIF
Return Nil

/*
Function DefRichProc( hEdit, msg, wParam, lParam )
Local oEdit
   // writelog( "RichProc: " + Str(hEdit,10)+"|"+Str(msg,6)+"|"+Str(wParam,10)+"|"+Str(lParam,10) )
   oEdit := FindSelf( hEdit )
   IF msg == WM_CHAR
      oEdit:lChanged := .T.
   ELSEIF msg == WM_KEYDOWN
      IF wParam == 46     // Del
         oEdit:lChanged := .T.
      ENDIF
   ELSEIF oEdit:bOther != Nil
      Return Eval( oEdit:bOther, oEdit, msg, wParam, lParam )
   ENDIF
Return -1
*/
