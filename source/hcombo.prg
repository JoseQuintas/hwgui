/*
 * $Id: hcombo.prg,v 1.9 2004-04-19 15:24:11 alkresin Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HCombo class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "HBClass.ch"
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
   DATA  bValid   INIT {||.T.}
   DATA  value    INIT 1
   DATA  bChangeSel

   METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  aItems,oFont,bInit,bSize,bPaint,bChange,cToolt )
   METHOD Activate()
   METHOD Redefine( oWnd,nId,vari,bSetGet,aItems,oFont,bInit,bSize,bDraw,bChange,cToolt )
   METHOD Init( aCombo, nCurrent )
   METHOD Refresh()     
   METHOD Setitem( nPos )
ENDCLASS

METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,aItems,oFont, ;
                  bInit,bSize,bPaint,bChange,cToolt ) CLASS HComboBox

   nStyle := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), CBS_DROPDOWNLIST )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctoolt )

   ::value   := Iif( vari==Nil .OR. Valtype(vari)!="N",1,vari )
   ::bSetGet := bSetGet
   ::aItems  := aItems

   ::Activate()

   IF bSetGet != Nil
      ::bChangeSel := bChange
      ::oParent:AddEvent( CBN_SELCHANGE,::id,{|o,id|__Valid(o:FindControl(id))} )
   ELSEIF bChange != Nil
      ::oParent:AddEvent( CBN_SELCHANGE,::id,bChange )
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
                  bChange,cToolt ) CLASS HComboBox

   Super:New( oWndParent,nId,0,0,0,0,0,oFont,bInit, ;
                  bSize,bPaint,ctoolt )

   ::value   := Iif( vari==Nil .OR. Valtype(vari)!="N",1,vari )
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
            ::value := 1
         ENDIF
         SendMessage( ::handle, CB_RESETCONTENT, 0, 0)
         FOR i := 1 TO Len( ::aItems )
            ComboAddString( ::handle, ::aItems[i] )
         NEXT
         ComboSetString( ::handle, ::value )
      ENDIF
   ENDIF
Return Nil

METHOD Refresh() CLASS HComboBox
        Local vari, i
        IF ::bSetGet != Nil
                vari := Eval( ::bSetGet,,Self )
                ::value := Iif( vari==Nil .OR. Valtype(vari)!="N",1,vari ) 
        ENDIF

        SendMessage( ::handle, CB_RESETCONTENT, 0, 0)
        
        FOR i := 1 TO Len( ::aItems )
            ComboAddString( ::handle, ::aItems[i] )
        NEXT
        
        ComboSetString( ::handle, ::value )

        ::SetItem(::value )
Return Nil

METHOD SetItem(nPos) CLASS HComboBox
        ::value := nPos
        SendMessage( ::handle, CB_SETCURSEL, nPos - 1, 0)
        
        IF ::bSetGet != Nil
                Eval( ::bSetGet, ::value, self )
        ENDIF
        
        IF ::bChangeSel != Nil
                Eval( ::bChangeSel, ::value, Self )
        ENDIF
Return Nil

Static Function __Valid( oCtrl )

   oCtrl:value := SendMessage( oCtrl:handle,CB_GETCURSEL,0,0 ) + 1

   IF oCtrl:bSetGet != Nil
      Eval( oCtrl:bSetGet,oCtrl:value, oCtrl )
   ENDIF
   IF oCtrl:bChangeSel != Nil
      Eval( oCtrl:bChangeSel, oCtrl:value, oCtrl )
   ENDIF

Return .T.
