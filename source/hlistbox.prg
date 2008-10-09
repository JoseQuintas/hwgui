/*
 * $Id: hlistbox.prg,v 1.17 2008-10-09 20:21:50 lfbasso Exp $
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
#include "common.ch"

CLASS HListBox INHERIT HControl

   CLASS VAR winclass   INIT "LISTBOX"
   DATA  aItems
   DATA  bSetGet
   DATA  value         INIT 1
   DATA  bChangeSel
   DATA  bValid
   DATA  lnoValid       INIT .F.

   METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
              aItems,oFont,bInit,bSize,bPaint,bChange,cTooltip,tColor,bcolor,bGFocus,bLFocus )
   METHOD Activate()
   METHOD Redefine( oWnd,nId,vari,bSetGet,aItems,oFont,bInit,bSize,bDraw,bChange,cTooltip )
   METHOD Init( aListbox, nCurrent )
   METHOD Refresh()
   METHOD Setitem( nPos )
   METHOD AddItems(p)
   METHOD DeleteItem(nPos)
   METHOD Clear()
ENDCLASS

METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,aItems,oFont, ;
                  bInit,bSize,bPaint,bChange,cTooltip,tColor,bcolor,bGFocus,bLFocus )  CLASS HListBox

   nStyle   := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), WS_TABSTOP+WS_VSCROLL+LBS_DISABLENOSCROLL+LBS_NOTIFY+LBS_NOINTEGRALHEIGHT+WS_BORDER )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctooltip, tColor,bcolor )

   ::value   := Iif( vari==Nil .OR. Valtype(vari)!="N",1,vari )
   ::bSetGet := bSetGet

   if aItems == Nil
        ::aItems := {}
   else
        ::aItems  := aItems
   endif

   ::Activate()

    ::bChangeSel := bChange
    ::bGetFocus := bGfocus
    ::bLostFocus := bLfocus

   IF bSetGet != Nil
      IF bGFocus != Nil
         ::lnoValid := .T.
         ::oParent:AddEvent( LBN_SETFOCUS,self,{|o,id|__When(o:FindControl(id))},,"onGotFocus" )
       ENDIF
      ::oParent:AddEvent( LBN_KILLFOCUS, self, { | o, id | __Valid( o:FindControl( id ) ) },.F.,"onLostFocus" )
      ::bValid := { | o | __Valid( o ) }
   ELSE
      IF bGfocus != Nil
         ::oParent:AddEvent( LBN_SETFOCUS,self,{|o,id|__When(o:FindControl(id))},,"onGotFocus" )
      ENDIF
        ::oParent:AddEvent( LBN_KILLFOCUS, self, { | o, id | __Valid( o:FindControl( id ) ) },.F.,"onLostFocus" )
   ENDIF
   IF bChange != Nil .OR. bSetGet != Nil
      ::oParent:AddEvent( LBN_SELCHANGE, self, {|o,id|__onChange(o:FindControl(id))},,"onChange" )
   ENDIF

Return Self

METHOD Activate CLASS HListBox
   IF !empty( ::oParent:handle )
      ::handle := CreateListbox( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
Return Nil

METHOD Redefine( oWndParent,nId,vari,bSetGet,aItems,oFont,bInit,bSize,bPaint, ;
                  bChange,cTooltip )  CLASS HListBox

   Super:New( oWndParent,nId,0,0,0,0,0,oFont,bInit, ;
                  bSize,bPaint,ctooltip )

   ::value   := Iif( vari==Nil .OR. Valtype(vari)!="N",1,vari )
   ::bSetGet := bSetGet
   if aItems == Nil
        ::aItems := {}
   else
        ::aItems  := aItems
   endif

   IF bSetGet != Nil
      ::bChangeSel := bChange
      ::oParent:AddEvent( LBN_SELCHANGE,self,{|o,id|__Valid(o:FindControl(id))},"onChange" )
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

METHOD AddItems(p)
// Local i
   aadd(::aItems,p)
   ListboxAddString( ::handle, p )
//   SendMessage( ::handle, LB_RESETCONTENT, 0, 0)
//   FOR i := 1 TO Len( ::aItems )
//      ListboxAddString( ::handle, ::aItems[i] )
//   NEXT
   ListboxSetString( ::handle, ::value )
return self

METHOD DeleteItem(nPos)

   IF SendMessage(::handle, LB_DELETESTRING ,nPos-1, 0) > 0 //<= LEN(ocombo:aitems)
      ADEL(::Aitems,nPos)
      ASIZE(::Aitems,len(::aitems)-1)
      RETURN .T.
   ENDIF
 RETURN .F.

METHOD Clear()
   ::aItems := {}
   ::value := 1
   SendMessage( ::handle, LB_RESETCONTENT, 0, 0)
   ListboxSetString( ::handle, ::value )
Return .T.


Static Function __onChange( oCtrl )
Local nPos

     nPos := SendMessage( oCtrl:handle,LB_GETCURSEL,0,0 ) + 1
     octrl:SetItem(npos)

RETURN Nil


Static Function __When( oCtrl )
Local res := .t., nSkip

   IF !CheckFocus(oCtrl, .f.)
      RETURN .t.
   ENDIF
   setfocus(oCtrl:handle)
   nSkip := iif( GetKeyState( VK_UP ) < 0 .or. (GetKeyState( VK_TAB ) < 0 .and. GetKeyState(VK_SHIFT) < 0 ), -1, 1 )
   IF oCtrl:bSetGet != Nil
      Eval( oCtrl:bSetGet, oCtrl:value, oCtrl )
   ENDIF
   IF oCtrl:bGetFocus != Nil
         octrl:lnoValid := .T.
         octrl:oparent:lSuspendMsgsHandling := .t.
      res := Eval( oCtrl:bGetFocus, oCtrl:Value, oCtrl )
      octrl:oparent:lSuspendMsgsHandling := .f.
      octrl:lnoValid := ! res
      IF ! res
         GetSkip( oCtrl:oParent, oCtrl:handle, , nSkip )
      ENDIF
   ENDIF
RETURN res


Static Function __Valid( oCtrl )
LOCAL res := .t., oDlg, nSkip
Local ltab :=  GETKEYSTATE(VK_TAB) < 0

  IF !CheckFocus(oCtrl, .t.) .or. oCtrl:lNoValid
     RETURN .t.
  ENDIF
  nSkip := iif(GetKeyState(VK_SHIFT) < 0 , -1, 1 )
  IF ( oDlg := ParentGetDialog( oCtrl ) ) == Nil .OR. oDlg:nLastKey != 27
      oCtrl:value := SendMessage( oCtrl:handle,LB_GETCURSEL,0,0 ) + 1
      IF oCtrl:bSetGet != Nil
         Eval( oCtrl:bSetGet, oCtrl:value, oCtrl )
      ENDIF
      IF oDlg != Nil
         oDlg:nLastKey := 27
      ENDIF
      IF oCtrl:bLostFocus != Nil
        octrl:oparent:lSuspendMsgsHandling := .t.
          res := Eval( oCtrl:bLostFocus, oCtrl:value, oCtrl )
          octrl:oparent:lSuspendMsgsHandling := .f.
        IF ! res
          SetFocus( oCtrl:handle )
          IF oDlg != Nil
             oDlg:nLastKey := 0
          ENDIF
          RETURN .F.
        ENDIF
      ENDIF
      IF oDlg != Nil
         oDlg:nLastKey := 0
      ENDIF
   ENDIF
   IF ltab .AND. GETFOCUS()=octrl:handle
      IF oCtrl:oParent:CLASSNAME = "HTAB"
         oCtrl:oParent:SETFOCUS()
      ENDIF
      GetSkip(octrl:oparent,octrl:handle,,nSkip)
   endif
 RETURN .T.
