/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HCombo class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

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
   METHOD GetValue()
ENDCLASS

METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,aItems,oFont, ;
                  bInit,bSize,bPaint,bChange,ctooltip,lEdit,lText,bGFocus,tcolor,bcolor,bValid ) CLASS HComboBox

   if lEdit == Nil; lEdit := .f.; endif
   if lText == Nil; lText := .f.; endif
   //if bValid != NIL; ::bValid := bValid; endif

   nStyle := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ),Iif( lEdit,CBS_DROPDOWN,CBS_DROPDOWNLIST )+WS_TABSTOP )
   ::Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, bSize,bPaint,ctooltip,tcolor,bcolor )

   ::lEdit := lEdit
   ::lText := lText

   if lEdit
      ::lText := .t.
   endif

   if ::lText
      ::value := Iif( vari==Nil .OR. Valtype(vari)!="C","",Trim(vari) )
   else
      ::value := Iif( vari==Nil .OR. Valtype(vari)!="N",1,vari )
   endif

   ::bSetGet := bSetGet
   ::aItems  := aItems

   ::Activate()

   IF bSetGet != Nil
      ::bChangeSel := bChange
      ::bGetFocus := bGFocus
      ::oParent:AddEvent( CBN_SETFOCUS,::id,{|o,id|__When(o:FindControl(id))} )

      // By Luiz Henrique dos Santos (luizhsantos@gmail.com) 03/06/2006
      if ::bSetGet <> nil
         ::oParent:AddEvent( CBN_SELCHANGE,::id,{|o,id|__Valid(o:FindControl(id))} )
      elseif ::bChangeSel != NIL
         ::oParent:AddEvent( CBN_SELCHANGE,::id,{|o,id|__Valid(o:FindControl(id))} )
      ENDIF
      
      IF bValid != NIL
         ::bValid := bValid
         ::oParent:AddEvent( CBN_KILLFOCUS,::id,{|o,id|__Valid(o:FindControl(id))} ) 
      ENDIF
      //---------------------------------------------------------------------------
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
   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createcombo( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
Return Nil

METHOD Redefine( oWndParent,nId,vari,bSetGet,aItems,oFont,bInit,bSize,bPaint, ;
                  bChange,ctooltip,bGFocus ) CLASS HComboBox

   ::Super:New( oWndParent,nId,0,0,0,0,0,oFont,bInit,bSize,bPaint,ctooltip )

   if ::lText
      ::value := Iif( vari==Nil .OR. Valtype(vari)!="C","",Trim(vari) )
   else
      ::value := Iif( vari==Nil .OR. Valtype(vari)!="N",1,vari )
   endif
   ::bSetGet := bSetGet
   ::aItems  := aItems

   IF bSetGet != Nil
      ::bChangeSel := bChange
      // By Luiz Henrique dos Santos (luizhsantos@gmail.com) 04/06/2006
      IF ::bChangeSel != NIL
        ::oParent:AddEvent( CBN_SELCHANGE,::id,{|o,id|__Valid(o:FindControl(id))} )
      ENDIF
   ELSEIF bChange != Nil
      ::oParent:AddEvent( CBN_SELCHANGE,::id,bChange )
   ENDIF
   ::Refresh() // By Luiz Henrique dos Santos
Return Self

METHOD Init() CLASS HComboBox
   Local i

   IF !::lInit
      ::Super:Init()
      IF ::aItems != Nil
         IF ::value == Nil
            IF ::lText
                ::value := ::aItems[1]
            ELSE
                ::value := 1
            ENDIF
         ENDIF
         hwg_Sendmessage( ::handle, CB_RESETCONTENT, 0, 0)
         FOR i := 1 TO Len( ::aItems )
            hwg_Comboaddstring( ::handle, ::aItems[i] )
         NEXT
         IF ::lText
            IF ::lEdit
                hwg_Setdlgitemtext(hwg_GetModalHandle(), ::id, ::value)
            ELSE
                hwg_Combosetstring( ::handle, AScan( ::aItems, ::value ) )
            ENDIF
         ELSE
            hwg_Combosetstring( ::handle, ::value )
         ENDIF
      ENDIF
   ENDIF
Return Nil

METHOD Refresh() CLASS HComboBox
   Local vari, i
   IF ::bSetGet != Nil
      vari := Eval( ::bSetGet,,Self )
      if ::lText
         ::value := Iif( vari==Nil .OR. Valtype(vari)!="C","",Trim(vari) )
      else
         ::value := Iif( vari==Nil .OR. Valtype(vari)!="N",1,vari )
      endif
   ENDIF

   hwg_Sendmessage( ::handle, CB_RESETCONTENT, 0, 0)

   FOR i := 1 TO Len( ::aItems )
      hwg_Comboaddstring( ::handle, ::aItems[i] )
   NEXT

   IF ::lText
      IF ::lEdit
        hwg_Setdlgitemtext(hwg_GetModalHandle(), ::id, ::value)
      ELSE
        hwg_Combosetstring( ::handle, AScan( ::aItems, ::value ) )
      ENDIF
   ELSE
      hwg_Combosetstring( ::handle, ::value )
      ::SetItem(::value )
   ENDIF

Return Nil

METHOD SetItem(nPos) CLASS HComboBox
   IF ::lText
      ::value := ::aItems[nPos]
   ELSE
      ::value := nPos
   ENDIF

   hwg_Sendmessage( ::handle, CB_SETCURSEL, nPos - 1, 0)

   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::value, self )
   ENDIF

   IF ::bChangeSel != Nil
      Eval( ::bChangeSel, nPos, Self )
   ENDIF
Return Nil

METHOD GetValue() CLASS HComboBox
Local nPos := hwg_Sendmessage( ::handle,CB_GETCURSEL,0,0 ) + 1

   ::value := Iif( ::lText, ::aItems[nPos], nPos )
   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::value, Self )
   ENDIF

Return ::value

Static Function __Valid( oCtrl )
   Local nPos
   local lESC
   // by sauli
   if __ObjHasMsg(oCtrl:oParent,"nLastKey")
      // caso o PARENT seja HDIALOG
      lESC := oCtrl:oParent:nLastKey <> 27
   else
      // caso o PARENT seja HTAB, HPANEL
      lESC := .t.
   end
   // end by sauli
   IF lESC // "if" by Luiz Henrique dos Santos (luizhsantos@gmail.com) 04/06/2006
     nPos := hwg_Sendmessage( oCtrl:handle,CB_GETCURSEL,0,0 ) + 1
  
     oCtrl:value := Iif( oCtrl:lText, oCtrl:aItems[nPos], nPos )
  
     IF oCtrl:bSetGet != Nil
        Eval( oCtrl:bSetGet, oCtrl:value, oCtrl )
     ENDIF
     IF oCtrl:bChangeSel != Nil
        Eval( oCtrl:bChangeSel, nPos, oCtrl )
     ENDIF
     
     // By Luiz Henrique dos Santos (luizhsantos@gmail.com.br) 03/06/2006
     IF oCtrl:bValid != NIL 
       IF ! EVAL( oCtrl:bValid, oCtrl )
         hwg_Setfocus( oCtrl:handle )
         RETURN .F.
       ENDIF
     ENDIF
   ENDIF
Return .T.

Static Function __KillFocus( oCtrl )
   oCtrl:value := hwg_Getedittext( hwg_GetModalHandle(), oCtrl:id )
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
         hwg_GetSkip( oCtrl:oParent,oCtrl:handle,1 )
      ENDIF
      Return res
   ENDIF

Return .T.
