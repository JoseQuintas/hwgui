/*
 *$Id: hcombo.prg,v 1.3 2005-10-21 08:50:15 alkresin Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HComboBox class 
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
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
   DATA  bChangeSel
   DATA  lText    INIT .F.
   DATA  lEdit    INIT .F.
   DATA  hEdit

   METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  aItems,oFont,bInit,bSize,bPaint,bChange,cToolt,lEdit,lText,bGFocus,tcolor,bcolor )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init( aCombo, nCurrent )
   METHOD Refresh()     
   METHOD Setitem( nPos )
ENDCLASS

METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,aItems,oFont, ;
                  bInit,bSize,bPaint,bChange,cToolt,lEdit,lText,bGFocus,tcolor,bcolor ) CLASS HComboBox

   if lEdit == Nil; lEdit := .f.; endif
   if lText == Nil; lText := .f.; endif

   nStyle := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ),Iif( lEdit,CBS_DROPDOWN,CBS_DROPDOWNLIST )+WS_TABSTOP )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, bSize,bPaint,ctoolt,tcolor,bcolor )
      
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
/*
   IF bSetGet != Nil
      ::bChangeSel := bChange
      ::bGetFocus  := bGFocus
      ::oParent:AddEvent( CBN_SETFOCUS,::id,{|o,id|__When(o:FindControl(id))} )
      ::oParent:AddEvent( CBN_SELCHANGE,::id,{|o,id|__Valid(o:FindControl(id))} )
   ELSEIF bChange != Nil
      ::oParent:AddEvent( CBN_SELCHANGE,::id,bChange )
   ENDIF
   
   IF bGFocus != Nil .AND. bSetGet == Nil
      ::oParent:AddEvent( CBN_SETFOCUS,::id,{|o,id|__When(o:FindControl(id))} )
   ENDIF
*/
   ::bGetFocus := bGFocus
   ::bLostFocus := bChange

   hwg_SetEvent( ::hEdit,"focus_in_event",EN_SETFOCUS,0,0 )
   hwg_SetEvent( ::hEdit,"focus_out_event",EN_KILLFOCUS,0,0 )

Return Self

METHOD Activate CLASS HComboBox

   IF !Empty(::oParent:handle )
      ::handle := CreateCombo( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::hEdit := hwg_ComboGetEdit( ::handle )
      ::Init()
      SetWindowObject( ::handle,Self )      
   ENDIF
Return Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HComboBox

   IF msg == EN_SETFOCUS
      writelog("SETFOCUS")
      IF ::bSetGet == Nil
         Eval( ::bGetFocus, hwg_Edit_GetText( ::handle ), Self )
      ELSE
         __When( Self )
      ENDIF
   ELSEIF msg == EN_KILLFOCUS
      writelog("KILLFOCUS")
      IF ::bSetGet == Nil
         Eval( ::bLostFocus, hwg_Edit_GetText( ::handle ), Self )
      ELSE
         __Valid( Self )
      ENDIF

   ENDIF
   
Return 0

METHOD Init() CLASS HComboBox
Local i

   IF !::lInit
      Super:Init()
      IF ::aItems != Nil
	 hwg_ComboSetArray( ::handle, ::aItems )      
         IF ::value == Nil
            IF ::lText
                ::value := ::aItems[1]
            ELSE
                ::value := 1                                                     
            ENDIF                
         ENDIF
         IF ::lText
            hwg_edit_Settext( ::hEdit, ::value )
         ELSE
            hwg_edit_Settext( ::hEdit, ::aItems[::value] )
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

   hwg_ComboSetArray( ::handle, ::aItems )
   
   IF ::lText
      hwg_edit_Settext( ::hEdit, ::value )
   ELSE
      hwg_edit_Settext( ::hEdit, ::aItems[::value] )
   ENDIF                    

Return Nil

METHOD SetItem( nPos ) CLASS HComboBox

   IF ::lText
      ::value := ::aItems[nPos]
   ELSE
      ::value := nPos
   ENDIF
                       
   hwg_edit_Settext( ::hEdit, ::aItems[nPos] )
   
   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::value, self )
   ENDIF
   
   IF ::bChangeSel != Nil
      Eval( ::bChangeSel, ::value, Self )
   ENDIF
   
Return Nil

Static Function __Valid( oCtrl )
Local vari := hwg_edit_Gettext( oCtrl:hEdit )

   IF oCtrl:lText
      oCtrl:value := vari
   ELSE
      oCtrl:value := Ascan( oCtrl:aItems,vari )
   ENDIF
               
   IF oCtrl:bSetGet != Nil
      Eval( oCtrl:bSetGet, oCtrl:value, oCtrl )
   ENDIF
   IF oCtrl:bChangeSel != Nil
      Eval( oCtrl:bChangeSel, oCtrl:value, oCtrl )
   ENDIF
Return .T.

Static Function __When( oCtrl )
Local res

   // oCtrl:Refresh()

   IF oCtrl:bGetFocus != Nil 
      res := Eval( oCtrl:bGetFocus, Eval( oCtrl:bSetGet,, oCtrl ), oCtrl )
      IF !res
         GetSkip( oCtrl:oParent,oCtrl:handle,1 )
      ENDIF
      Return res
   ENDIF

Return .T.

