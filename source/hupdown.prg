/*
 * $Id: hupdown.prg,v 1.18 2009-02-15 20:12:30 lfbasso Exp $
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
   
   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
               oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, tcolor, bcolor, nUpDWidth, nLower, nUpper )
   METHOD Activate()
   METHOD Init()
   METHOD OnEvent(msg,wParam,lParam)
   METHOD Refresh()
   METHOD Hide() INLINE ( ::lHide := .T., HideWindow( ::handle ), HideWindow( ::hUpDown ) )
   METHOD Show() INLINE ( ::lHide := .F., ShowWindow( ::handle ), ShowWindow( ::hUpDown ) )

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
            oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, tcolor, bcolor,   ;
            nUpDWidth, nLower, nUpper ) CLASS HUpDown

   nStyle   := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), WS_TABSTOP + WS_BORDER + ES_RIGHT )
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor )

   ::idUpDown := ::NewId()
   IF ValType( vari ) != "N"
      vari := 0
      Eval( bSetGet, vari )
   ENDIF
   ::title := Str( vari )
   ::bSetGet := bSetGet

   ::styleUpDown := UDS_SETBUDDYINT + UDS_ALIGNRIGHT

   IF nLower != Nil ; ::nLower := nLower ; ENDIF
   IF nUpper != Nil ; ::nUpper := nUpper ; ENDIF
   IF nUpDWidth != Nil ; ::nUpDownWidth := nUpDWidth ; ENDIF

   ::Activate()

   IF bSetGet != Nil
      ::bGetFocus := bGfocus
      ::bLostFocus := bLfocus
      ::bValid := bLfocus
      ::lnoValid := bGfocus != Nil
      ::oParent:AddEvent( EN_SETFOCUS, Self, { | o, id | __When( o:FindControl( id ) ) },, "onGotFocus" )
      ::oParent:AddEvent( EN_KILLFOCUS, Self, { | o, id | __Valid( o:FindControl( id ) ) },, "onLostFocus" )
   ELSE
      IF bGfocus != Nil
         ::lnoValid := .T.
         ::oParent:AddEvent( EN_SETFOCUS, Self, { | o, id | __When( o:FindControl( id ) ) },, "onGotFocus" )
         //::oParent:AddEvent( EN_SETFOCUS,self,bGfocus,,"onGotFocus"  )
      ENDIF
      IF bLfocus != Nil
         // ::oParent:AddEvent( EN_KILLFOCUS,self,bLfocus,,"onLostFocus"  )
         ::oParent:AddEvent( EN_KILLFOCUS, Self, { | o, id | __Valid( o:FindControl( id ) ) },, "onLostFocus" )
      ENDIF
   ENDIF

   RETURN Self

METHOD Activate CLASS HUpDown
   IF ! Empty( ::oParent:handle )
      ::handle := CreateEdit( ::oParent:handle, ::id, ;
                              ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF
   RETURN Nil

METHOD Init()  CLASS HUpDown
   IF ! ::lInit
      Super:Init()
      ::nHolder := 1
      SetWindowObject( ::handle, Self )     
      HWG_INITUpDownPROC( ::handle )
      ::hUpDown := CreateUpDownControl( ::oParent:handle, ::idUpDown, ;
                                        ::styleUpDown, 0, 0, ::nUpDownWidth, 0, ::handle, ::nUpper, ::nLower, Val( ::title ) )
   ENDIF
   RETURN Nil

METHOD OnEvent( msg, wParam, lParam ) CLASS HUpDown

   IF msg == WM_CHAR
      IF wParam = VK_TAB 
          GetSkip( ::oParent, ::handle, , iif( IsCtrlShift(.f., .t.), -1, 1) )
          RETURN 0
      ELSEIF wParam == VK_RETURN 
          GetSkip( ::oParent, ::handle, , 1 )
          RETURN 0
		  ENDIF
		  
	 ELSEIF msg = WM_KEYDOWN
	 
		  ProcKeyList( Self, wParam )  
		  
   ELSEIF msg == WM_VSCROLL		  
	 ENDIF
  
RETURN -1

METHOD Refresh()  CLASS HUpDown

   IF ::bSetGet != Nil
      ::value := Eval( ::bSetGet )
      IF Str( ::value ) != ::title
         ::title := Str( ::value )
         SetUpDown( ::hUpDown, ::value )
      ENDIF
   ELSE
      SetUpDown( ::hUpDown, Val( ::title ) )
   ENDIF

   RETURN Nil

STATIC FUNCTION __When( oCtrl )
   LOCAL res := .t., oParent, nSkip

   IF ! CheckFocus( oCtrl, .f. )
      RETURN .t.
   ENDIF
   IF oCtrl:bGetFocus != Nil
      oCtrl:Refresh()
      oCtrl:lnoValid := .T.
      oCtrl:oParent:lSuspendMsgsHandling := .t.
      res := Eval( oCtrl:bGetFocus, Eval( oCtrl:bSetGet, , oCtrl ), oCtrl )
      oCtrl:oParent:lSuspendMsgsHandling := .f.
      oCtrl:lnoValid := ! res
      IF ! res
         oParent := ParentGetDialog( oCtrl )
         IF oCtrl == ATail( oParent:GetList )
            nSkip := - 1
         ELSEIF oCtrl == oParent:getList[ 1 ]
            nSkip := 1
         ENDIF
         GetSkip( oCtrl:oParent, oCtrl:handle, , nSkip )
      ENDIF
   ENDIF
   RETURN res

STATIC FUNCTION __Valid( oCtrl )
   LOCAL res := .t., hctrl , nSkip, oDlg
   LOCAL ltab :=  GETKEYSTATE( VK_TAB ) < 0

   IF ! CheckFocus( oCtrl, .t. )  .OR. oCtrl:lnoValid
      RETURN .T.
   ENDIF
   nSkip := IIf( GetKeyState( VK_SHIFT ) < 0 , - 1, 1 )
   oCtrl:title := GetEditText( oCtrl:oParent:handle, oCtrl:id )
   oCtrl:value := Val( LTrim( oCtrl:title ) )
   IF oCtrl:bSetGet != Nil
      Eval( oCtrl:bSetGet, oCtrl:value )
   ENDIF
   oCtrl:oparent:lSuspendMsgsHandling := .t.
   hctrl := getfocus()
   oDlg := ParentGetDialog( oCtrl )
   IF oCtrl:bLostFocus != Nil
      res := Eval( oCtrl:bLostFocus, oCtrl:value,  oCtrl )
      res := IIf( res, oCtrl:value <= oCtrl:nUpper .and. ;
                  oCtrl:value >= oCtrl:nLower , res )
      IF ! res
         SetFocus( oCtrl:handle )
         IF oDlg != Nil
            oDlg:nLastKey := 0
         ENDIF
      ENDIF
   ENDIF
   IF ltab .AND. hctrl = getfocus() .AND. res
      IF oCtrl:oParent:CLASSNAME = "HTAB"
         getskip( oCtrl:oparent, oCtrl:handle,, nSkip )
      ENDIF
   ENDIF
   oCtrl:oparent:lSuspendMsgsHandling := .F.
   IF GetFocus() = 0 
      GetSkip( octrl:oParent, octrl:handle,, octrl:nGetSkip )
   ENDIF 

   RETURN res
