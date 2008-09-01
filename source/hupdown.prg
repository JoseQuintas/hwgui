/*
 * $Id: hupdown.prg,v 1.16 2008-09-01 19:00:20 mlacecilia Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HUpDown class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HUpDown INHERIT HControl

   CLASS VAR winclass   INIT "EDIT"
   DATA bSetGet
   DATA value
   DATA bValid
   DATA hUpDown, idUpDown, styleUpDown
   DATA nLower INIT 0
   DATA nUpper INIT 999
   DATA nUpDownWidth INIT 12
   DATA lChanged    INIT .F.
   DATA lnoValid       INIT .F.

   METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
         oFont,bInit,bSize,bPaint,bGfocus,bLfocus,ctooltip,tcolor,bcolor,nUpDWidth,nLower,nUpper )
   METHOD Activate()
   METHOD Init()
   METHOD Refresh()
   METHOD Hide() INLINE (::lHide := .T., HideWindow( ::handle ), HideWindow( ::hUpDown ) )
   METHOD Show() INLINE (::lHide := .F., ShowWindow( ::handle ), ShowWindow( ::hUpDown ) )

ENDCLASS

METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
         oFont,bInit,bSize,bPaint,bGfocus,bLfocus,ctooltip,tcolor,bcolor,   ;
         nUpDWidth,nLower,nUpper ) CLASS HUpDown

   nStyle   := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), WS_TABSTOP + WS_BORDER + ES_RIGHT )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )

   ::idUpDown := ::NewId()
   IF Valtype(vari) != "N"
      vari := 0
      Eval( bSetGet,vari )
   ENDIF
   ::title := Str(vari)
   ::bSetGet := bSetGet

   ::styleUpDown := UDS_SETBUDDYINT+UDS_ALIGNRIGHT

   IF nLower != Nil ; ::nLower := nLower ; ENDIF
   IF nUpper != Nil ; ::nUpper := nUpper ; ENDIF
   IF nUpDWidth != Nil ; ::nUpDownWidth := nUpDWidth ; ENDIF

   ::Activate()

   IF bSetGet != Nil
      ::bGetFocus := bGFocus
      ::bLostFocus := bLFocus
      ::bValid := bLFocus
      ::lnoValid := bGfocus != Nil
      ::oParent:AddEvent( EN_SETFOCUS,self,{|o,id|__When(o:FindControl(id))},,"onGotFocus" )
      ::oParent:AddEvent( EN_KILLFOCUS,self,{|o,id|__Valid(o:FindControl(id))},,"onLostFocus" )
   ELSE
      IF bGfocus != Nil
         ::lnoValid := .T.
         ::oParent:AddEvent( EN_SETFOCUS,self,{|o,id|__When(o:FindControl(id))},,"onGotFocus" )
         //::oParent:AddEvent( EN_SETFOCUS,self,bGfocus,,"onGotFocus"  )
      ENDIF
      IF bLfocus != Nil
        // ::oParent:AddEvent( EN_KILLFOCUS,self,bLfocus,,"onLostFocus"  )
         ::oParent:AddEvent( EN_KILLFOCUS,self,{|o,id|__Valid(o:FindControl(id))},,"onLostFocus" )
      ENDIF
   ENDIF

Return Self

METHOD Activate CLASS HUpDown
   IF !empty( ::oParent:handle )
      ::handle := CreateEdit( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF
Return Nil

METHOD Init()  CLASS HUpDown
   IF !::lInit
      Super:Init()
      ::hUpDown := CreateUpDownControl( ::oParent:handle, ::idUpDown, ;
          ::styleUpDown,0,0,::nUpDownWidth,0,::handle,::nUpper,::nLower,Val(::title) )
   ENDIF
Return Nil

METHOD Refresh()  CLASS HUpDown

   IF ::bSetGet != Nil
      ::value := Eval( ::bSetGet )
      IF Str(::value) != ::title
         ::title := Str( ::value )
         SetUpDown( ::hUpDown, ::value )
      ENDIF
   ELSE
      SetUpDown( ::hUpDown, Val(::title) )
   ENDIF

Return Nil

STATIC FUNCTION __When( oCtrl )
 LOCAL res := .t., oParent, nSkip

   IF !CheckFocus(oCtrl, .f.)
      RETURN .t.
   ENDIF
  IF oCtrl:bGetFocus != Nil
      oCtrl:Refresh()
      octrl:lnoValid := .T.
      octrl:oparent:lSuspendMsgsHandling := .t.
      res := Eval( oCtrl:bGetFocus, Eval( oCtrl:bSetGet, , oCtrl ), oCtrl )
      octrl:oparent:lSuspendMsgsHandling := .f.
      octrl:lnoValid := ! res
      IF ! res
         oParent := ParentGetDialog(oCtrl)
         IF oCtrl == ATail(oParent:GetList)
            nSkip := -1
         ELSEIF oCtrl == oParent:getList[1]
            nSkip := 1
         ENDIF
         GetSkip( oCtrl:oParent, oCtrl:handle, , nSkip )
      ENDIF
   ENDIF
RETURN res

Static Function __Valid( oCtrl )
LOCAL res := .t., hctrl , nSkip, oDlg
Local ltab :=  GETKEYSTATE(VK_TAB) < 0

   IF !CheckFocus(oCtrl, .t.)  .OR. oCtrl:lnoValid
      RETURN .T.
   ENDIF
   nSkip := iif(GetKeyState(VK_SHIFT) < 0 , -1, 1 )
    oCtrl:title := GetEditText( oCtrl:oParent:handle, oCtrl:id )
   oCtrl:value := Val( Ltrim( oCtrl:title ) )
   IF oCtrl:bSetGet != Nil
      Eval( oCtrl:bSetGet,oCtrl:value )
   ENDIF
   octrl:oparent:lSuspendMsgsHandling := .t.
   hctrl := getfocus()
   oDlg := ParentGetDialog( oCtrl )
   IF oCtrl:bLostFocus != Nil
      res := Eval( oCtrl:bLostFocus, oCtrl:value,  oCtrl )
       res := IIF(res,oCtrl:value <= oCtrl:nUpper .and. ;
            oCtrl:value >= oCtrl:nLower ,res)
       IF ! res
          SetFocus( oCtrl:handle )
          IF oDlg != Nil
              oDlg:nLastKey := 0
          ENDIF
       ENDIF
    ENDIF
    IF ltab .AND. hCtrl=getfocus() .AND. res
      IF oCtrl:oParent:CLASSNAME = "HTAB"
            getskip(octrl:oparent,octrl:handle,,nSkip)
        ENDIF
   ENDIF
   octrl:oparent:lSuspendMsgsHandling := .F.
Return res
