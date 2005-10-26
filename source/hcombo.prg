/*
 * $Id: hcombo.prg,v 1.21 2005-10-26 07:43:26 omm Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HCombo class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define CB_ERR              (-1)
#define CBN_SELCHANGE       1
#define CBN_DBLCLK          2
#define CBN_SETFOCUS        3
#define CBN_KILLFOCUS       4
#define CBN_EDITCHANGE      5
#define CBN_EDITUPDATE      6
#define CBN_DROPDOWN        7
#define CBN_CLOSEUP         8
#define CBN_SELENDOK        9
#define CBN_SELENDCANCEL    10


CLASS HComboBox INHERIT HControl

   CLASS VAR winclass   INIT "COMBOBOX"
   DATA  aItems
   DATA  bSetGet
   DATA  value    INIT 1
   DATA  bValid   INIT {||.T.}
   DATA  bChangeSel
   DATA  lText    INIT .F.
   DATA  lEdit    INIT .F.

   METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  aItems,oFont,bInit,bSize,bPaint,bChange,ctooltip,lEdit,lText,bGFocus,tcolor,bcolor,bValid )
   METHOD Activate()
   METHOD Redefine( oWnd,nId,vari,bSetGet,aItems,oFont,bInit,bSize,bDraw,bChange,ctooltip,bGFocus )
   METHOD Init( aCombo, nCurrent )
   METHOD Refresh()
   METHOD Setitem( nPos )
ENDCLASS

METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,aItems,oFont, ;
                  bInit,bSize,bPaint,bChange,ctooltip,lEdit,lText,bGFocus,tcolor,bcolor,bValid ) CLASS HComboBox

   if lEdit == Nil; lEdit := .f.; endif
   if lText == Nil; lText := .f.; endif
   if bValid != NIL; ::bValid := bValid; endif

   nStyle := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ),Iif( lEdit,CBS_DROPDOWN,CBS_DROPDOWNLIST )+WS_TABSTOP )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, bSize,bPaint,ctooltip,tcolor,bcolor )

   ::lEdit := lEdit
   ::lText := lText

   if lEdit
      ::lText := .t.
   endif

   if ::lText
      ::value := Iif( vari==Nil .OR. Valtype(vari)!="C","",vari )
   else
      ::value := Iif( vari==Nil .OR. Valtype(vari)!="N",1,vari )
   endif

   ::bSetGet := bSetGet
   ::aItems  := aItems

   ::Activate()

   IF bSetGet != Nil
      ::bChangeSel := bChange
      ::bGetFocus  := bGFocus
      ::oParent:AddEvent( CBN_SETFOCUS,::id,{|o,id|__When(o:FindControl(id))} )
      ::oParent:AddEvent( CBN_SELCHANGE,::id,{|o,id|__Valid(o:FindControl(id))} )
   ELSEIF bChange != Nil
      ::oParent:AddEvent( CBN_SELCHANGE,::id,bChange )
   ENDIF

   IF ::lEdit
      ::oParent:AddEvent( CBN_KILLFOCUS,::id,{|o,id|__KillFocus(o:FindControl(id))} )
   ENDIF

   IF bGFocus != Nil .AND. bSetGet == Nil
      ::oParent:AddEvent( CBN_SETFOCUS,::id,{|o,id|__When(o:FindControl(id))} )
   ENDIF

Return Self

METHOD Activate CLASS HComboBox
   IF ::oParent:handle != 0
      ::handle := CreateCombo( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
Return Nil

METHOD Redefine( oWndParent,nId,vari,bSetGet,aItems,oFont,bInit,bSize,bPaint, ;
                  bChange,ctooltip,bGFocus ) CLASS HComboBox

   Super:New( oWndParent,nId,0,0,0,0,0,oFont,bInit,bSize,bPaint,ctooltip )

   if ::lText
      ::value := Iif( vari==Nil .OR. Valtype(vari)!="C","",vari )
   else
      ::value := Iif( vari==Nil .OR. Valtype(vari)!="N",1,vari )
   endif
   ::bSetGet := bSetGet
   ::aItems  := aItems

   IF bSetGet != Nil
      ::bChangeSel := bChange
      ::oParent:AddEvent( CBN_SELCHANGE,::id,{|o,id|__Valid(o:FindControl(id))} )
   ELSEIF bChange != Nil
      ::oParent:AddEvent( CBN_SELCHANGE,::id,bChange )
   ENDIF
Return Self

METHOD Init() CLASS HComboBox
   Local i

   IF !::lInit
      Super:Init()
      IF ::aItems != Nil
         IF ::value == Nil
            IF ::lText
                ::value := ::aItems[1]
            ELSE
                ::value := 1
            ENDIF
         ENDIF
         SendMessage( ::handle, CB_RESETCONTENT, 0, 0)
         FOR i := 1 TO Len( ::aItems )
            ComboAddString( ::handle, ::aItems[i] )
         NEXT
         IF ::lText
            IF ::lEdit
                SetDlgItemText(getmodalhandle(), ::id, ::value)
            ELSE
                ComboSetString( ::handle, AScan( ::aItems, ::value ) )
            ENDIF
         ELSE
            ComboSetString( ::handle, ::value )
         ENDIF
      ENDIF
   ENDIF
Return Nil

METHOD Refresh() CLASS HComboBox
   Local vari, i
   IF ::bSetGet != Nil
      vari := Eval( ::bSetGet,,Self )
      if ::lText
         ::value := Iif( vari==Nil .OR. Valtype(vari)!="C","",vari )
      else
         ::value := Iif( vari==Nil .OR. Valtype(vari)!="N",1,vari )
      endif
   ENDIF

   SendMessage( ::handle, CB_RESETCONTENT, 0, 0)

   FOR i := 1 TO Len( ::aItems )
      ComboAddString( ::handle, ::aItems[i] )
   NEXT

   IF ::lText
      IF ::lEdit
        SetDlgItemText(getmodalhandle(), ::id, ::value)
      ELSE
        ComboSetString( ::handle, AScan( ::aItems, ::value ) )
      ENDIF
   ELSE
      ComboSetString( ::handle, ::value )
      ::SetItem(::value )
   ENDIF

Return Nil

METHOD SetItem(nPos) CLASS HComboBox
   IF ::lText
      ::value := ::aItems[nPos]
   ELSE
      ::value := nPos
   ENDIF

   SendMessage( ::handle, CB_SETCURSEL, nPos - 1, 0)

   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::value, self )
   ENDIF

   IF ::bChangeSel != Nil
      Eval( ::bChangeSel, nPos, Self )
   ENDIF
Return Nil

Static Function __Valid( oCtrl )
   Local nPos

   nPos := SendMessage( oCtrl:handle,CB_GETCURSEL,0,0 ) + 1

   IF oCtrl:lText
      oCtrl:value := oCtrl:aItems[nPos]
   ELSE
      oCtrl:value := nPos
   ENDIF

   IF oCtrl:bSetGet != Nil
      Eval( oCtrl:bSetGet, oCtrl:value, oCtrl )
   ENDIF
   IF oCtrl:bChangeSel != Nil
      Eval( oCtrl:bChangeSel, nPos, oCtrl )
   ENDIF

Return .T.

Static Function __KillFocus( oCtrl )
   oCtrl:value := GetEditText( getmodalhandle(), oCtrl:id )
   IF oCtrl:bSetGet != Nil
      Eval( oCtrl:bSetGet, oCtrl:value, oCtrl )
   ENDIF
Return .T.

Static Function __When( oCtrl )
Local res

   oCtrl:Refresh()

   IF oCtrl:bGetFocus != Nil
      res := Eval( oCtrl:bGetFocus, Eval( oCtrl:bSetGet,, oCtrl ), oCtrl )
      IF !res
         GetSkip( oCtrl:oParent,oCtrl:handle,1 )
      ENDIF
      Return res
   ENDIF

Return .T.

