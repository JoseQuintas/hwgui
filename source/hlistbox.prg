/*
 * $Id: hlistbox.prg,v 1.5 2004-07-29 16:48:15 lf_sfnet Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HListBox class
 *
 * Copyright 2004 Vic McClung
 * 
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define LB_ERR              (-1)
#define LBN_SELCHANGE       1
#define LBN_DBLCLK          2
#define LBN_SETFOCUS        3
#define LBN_KILLFOCUS       4
#define LBN_EDITCHANGE      5
#define LBN_EDITUPDATE      6
#define LBN_DROPDOWN        7
#define LBN_CLOSEUP         8
#define LBN_SELENDOK        9
#define LBN_SELENDCANCEL    10


CLASS HListBox INHERIT HControl

   CLASS VAR winclass   INIT "LISTBOX"
   DATA  aItems
   DATA  bSetGet
   DATA  value    INIT 1
   DATA  bChangeSel

   METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  aItems,oFont,bInit,bSize,bPaint,bChange,cTooltip )
   METHOD Activate()
   METHOD Redefine( oWnd,nId,vari,bSetGet,aItems,oFont,bInit,bSize,bDraw,bChange,cTooltip )
   METHOD Init( aListbox, nCurrent )
   METHOD Refresh()
   METHOD Setitem( nPos )
ENDCLASS

METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,aItems,oFont, ;
                  bInit,bSize,bPaint,bChange,cTooltip ) CLASS HListBox

   nStyle   := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), WS_TABSTOP+WS_VSCROLL+LBS_DISABLENOSCROLL+LBS_NOTIFY+LBS_NOINTEGRALHEIGHT+WS_BORDER )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctooltip )

   ::value   := Iif( vari==Nil .OR. Valtype(vari)!="N",1,vari )
   ::bSetGet := bSetGet

   ::aItems  := aItems

   ::Activate()

   IF bSetGet != Nil
      ::bChangeSel := bChange
      ::oParent:AddEvent( LBN_SELCHANGE,::id,{|o,id|__Valid(o:FindControl(id))} )
   ELSEIF bChange != Nil
      ::oParent:AddEvent( LBN_SELCHANGE,::id,bChange )
   ENDIF

Return Self

METHOD Activate CLASS HListBox
   IF ::oParent:handle != 0
      ::handle := CreateListbox( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
Return Nil

METHOD Redefine( oWndParent,nId,vari,bSetGet,aItems,oFont,bInit,bSize,bPaint, ;
                  bChange,cTooltip ) CLASS HListBox

   Super:New( oWndParent,nId,0,0,0,0,0,oFont,bInit, ;
                  bSize,bPaint,ctooltip )

   ::value   := Iif( vari==Nil .OR. Valtype(vari)!="N",1,vari )
   ::bSetGet := bSetGet
   ::aItems  := aItems

   IF bSetGet != Nil
      ::bChangeSel := bChange
      ::oParent:AddEvent( LBN_SELCHANGE,::id,{|o,id|__Valid(o:FindControl(id))} )
   ENDIF
Return Self

METHOD Init() CLASS HListBox
Local i

   IF !::lInit
      Super:Init()
      IF ::aItems != Nil
         IF ::value == Nil
            ::value := 1
         ENDIF
         SendMessage( ::handle, LB_RESETCONTENT, 0, 0)
         FOR i := 1 TO Len( ::aItems )
            ListboxAddString( ::handle, ::aItems[i] )
         NEXT
         ListboxSetString( ::handle, ::value )
      ENDIF
   ENDIF
Return Nil

METHOD Refresh() CLASS HListBox
        Local vari
        IF ::bSetGet != Nil
                vari := Eval( ::bSetGet )
        ENDIF

        ::value := Iif( vari==Nil .OR. Valtype(vari)!="N",1,vari )
        ::SetItem(::value )
Return Nil

METHOD SetItem(nPos) CLASS HListBox
        ::value := nPos
        SendMessage( ::handle, LB_SETCURSEL, nPos - 1, 0)

        IF ::bSetGet != Nil
                Eval( ::bSetGet, ::value )
        ENDIF

        IF ::bChangeSel != Nil
                Eval( ::bChangeSel, ::value, Self )
        ENDIF
Return Nil

Static Function __Valid( oCtrl )

   oCtrl:value := SendMessage( oCtrl:handle,LB_GETCURSEL,0,0 ) + 1

   IF oCtrl:bSetGet != Nil
      Eval( oCtrl:bSetGet,oCtrl:value )
   ENDIF
   IF oCtrl:bChangeSel != Nil
      Eval( oCtrl:bChangeSel, oCtrl:value, oCtrl )
   ENDIF

Return .T.

