/*
 * $Id: hdatepic.prg,v 1.26 2010-01-27 15:52:05 lfbasso Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HDatePicker class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define DTN_DATETIMECHANGE    - 759
#define DTN_CLOSEUP           - 753
#define DTM_GETMONTHCAL       4104   // 0x1008
#define NM_KILLFOCUS          - 8
#define NM_SETFOCUS           - 7

CLASS HDatePicker INHERIT HControl

CLASS VAR winclass   INIT "SYSDATETIMEPICK32"
   DATA bSetGet
   DATA value
   DATA bChange
   DATA lnoValid       INIT .F.

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
               oFont, bInit, bGfocus, bLfocus, bChange, ctooltip, tcolor, bcolor )
   METHOD Activate()
   METHOD Init()
   METHOD OnEvent( msg, wParam, lParam )
   METHOD Refresh()
   METHOD GetValue()
   METHOD SetValue( dValue )
   METHOD Redefine( oWndParent, nId, vari, bSetGet, oFont, bInit, ;
                    bGfocus, bLfocus, bChange, ctooltip, tcolor, bcolor )
   METHOD onChange( nMess )
   METHOD When( ) 
   METHOD Valid( )

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
            oFont, bInit, bGfocus, bLfocus, bChange, ctooltip, tcolor, bcolor ) CLASS HDatePicker

   nStyle := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), IIF( vari != Nil, WS_TABSTOP, 0 ) ) 
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              ,, ctooltip, tcolor, bcolor )

   ::value   := IIf( vari == Nil .OR. ValType( vari ) != "D", CToD( Space( 8 ) ), vari )
   ::title   := ::value
   ::bSetGet := bSetGet
   ::bChange := bChange

   HWG_InitCommonControlsEx()
   ::Activate()

   IF bSetGet != Nil
      ::bGetFocus := bGfocus
      ::bLostFocus := bLfocus
      ::oParent:AddEvent( NM_SETFOCUS, Self, { | o, id | ::When( o:FindControl( id ) ) }, .T., "onGotFocus" )
      ::oParent:AddEvent( NM_KILLFOCUS, Self, { | o, id | ::Valid( o:FindControl( id ) ) }, .T., "onLostFocus" )
   ELSE
      IF bGfocus != Nil
         ::lnoValid := .T.
         ::oParent:AddEvent( NM_SETFOCUS, Self, bGfocus, .T., "onGotFocus" )
      ENDIF
      IF bLfocus != Nil
         ::oParent:AddEvent( NM_KILLFOCUS, Self, bLfocus, .T., "onLostFocus" )
      ENDIF
   ENDIF
   ::oParent:AddEvent( DTN_DATETIMECHANGE, Self, { | o, id | ::onChange( DTN_DATETIMECHANGE ) }, .T., "onChange" )
   ::oParent:AddEvent( DTN_CLOSEUP, Self, { | o, id | ::onChange( DTN_CLOSEUP ) }, .T., "onClose" )

   RETURN Self

METHOD Redefine( oWndParent, nId, vari, bSetGet, oFont, bSize, bInit, ;
                 bGfocus, bLfocus, bChange, ctooltip, tcolor, bcolor ) CLASS  HDatePicker
   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize,, ctooltip, tcolor, bcolor )
   HWG_InitCommonControlsEx()
   ::value   := IIf( vari == Nil .OR. ValType( vari ) != "D", CToD( Space( 8 ) ), vari )
   ::bSetGet := bSetGet
   ::bChange := bChange
   
   IF bGfocus != Nil
      ::oParent:AddEvent( NM_SETFOCUS, Self, bGfocus, .T., "onGotFocus" )
   ENDIF
   ::oParent:AddEvent( DTN_DATETIMECHANGE, Self, { | o, id | ::onChange( DTN_DATETIMECHANGE ) }, .T., "onChange" )
   ::oParent:AddEvent( DTN_CLOSEUP, Self, { | o, id | ::onChange(  DTN_CLOSEUP ) }, .T., "onClose" )
   IF bSetGet != Nil
      ::bLostFocus := bLfocus
      ::oParent:AddEvent( NM_KILLFOCUS, Self, { | o, id | ::Valid( o:FindControl( id ) ) }, .T., "onLostFocus" )
   ELSE
      IF bLfocus != Nil
         ::oParent:AddEvent( NM_KILLFOCUS, Self, bLfocus, .T., "onLostFocus" )
      ENDIF
   ENDIF


   RETURN Self

METHOD Activate CLASS HDatePicker
   IF ! Empty( ::oParent:handle )
      ::handle := CreateDatePicker( ::oParent:handle, ::id, ;
                                    ::nLeft, ::nTop, ::nWidth, ::nHeight, ::style )
      ::Init()
   ENDIF
   RETURN Nil

METHOD Init() CLASS HDatePicker
   IF ! ::lInit
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      HWG_INITDATEPICKERPROC( ::handle )
      Super:Init()
      IF Empty( ::value )
         SetDatePickerNull( ::handle )
      ELSE
         SetDatePicker( ::handle, ::value )
      ENDIF
   ENDIF
   RETURN Nil

METHOD OnEvent( msg, wParam, lParam ) CLASS HDatePicker   

   IF ::bOther != Nil                                         
      IF Eval( ::bOther,Self,msg,wParam,lParam ) != -1
         RETURN 0
      ENDIF
   ENDIF
   IF msg == WM_CHAR
      IF wParam = VK_TAB 
        GetSkip( ::oParent, ::handle, , iif( IsCtrlShift(.f., .t.), -1, 1) )
        RETURN 0
      ELSEIF wParam == VK_RETURN 
         GetSkip( ::oParent, ::handle, , 1 )
         RETURN 0
		  ENDIF
	 ELSEIF msg = WM_KEYDOWN
		  IF  ProcKeyList( Self, wParam )  
		     RETURN 0
		  ENDIF   
   ELSEIF  msg = WM_GETDLGCODE
      IF wParam = VK_TAB //.AND.  ::GetParentForm( Self ):Type < WND_DLG_RESOURCE
        // GetSkip( ::oParent, ::handle, , iif( IsCtrlShift(.f., .t.), -1, 1) )
         RETURN DLGC_WANTTAB
      ENDIF   
	 ENDIF
  
RETURN -1
        
METHOD GetValue CLASS HDatePicker   
   RETURN GetDatePicker( ::handle )
         
METHOD SetValue( dValue ) CLASS HDatePicker

   IF Empty( dValue )
      SetDatePickerNull( ::handle )
   ELSE
      SetDatePicker( ::handle, dValue )
   ENDIF
   ::value := GetDatePicker( ::handle )
   ::title := ::Value
   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::value, Self )
   ENDIF
   
   RETURN Nil

METHOD Refresh() CLASS HDatePicker
   IF ::bSetGet != Nil
      ::value := Eval( ::bSetGet,, nil )
   ENDIF
   IF Empty( ::value )
      SetDatePickerNull( ::handle )
   ELSE
      SetDatePicker( ::handle, ::value )
   ENDIF
   RETURN Nil


METHOD onChange( nMess ) CLASS HDatePicker

   IF ( nMess == DTN_DATETIMECHANGE .AND. ;
        SendMessage( ::handle, DTM_GETMONTHCAL, 0, 0 ) == 0 ) .OR. ;
      nMess == DTN_CLOSEUP
      IF nMess = DTN_CLOSEUP   
         POSTMESSAGE( ::handle, WM_KEYDOWN, VK_RIGHT, 0 )
         ::SetFocus()
      ENDIF
      ::value := GetDatePicker( ::handle )
      IF ::bSetGet != Nil
         Eval( ::bSetGet, ::value, Self )
      ENDIF
      IF ::bChange != Nil
         ::oparent:lSuspendMsgsHandling := .T.
         Eval( ::bChange, ::value, Self )
         ::oparent:lSuspendMsgsHandling := .F.
      ENDIF
   ENDIF
   RETURN .T.

METHOD When( ) CLASS HDatePicker
   LOCAL res := .t.,  nSkip

   IF ! CheckFocus( Self, .f. )
      RETURN .t.
   ENDIF
   nSkip := IIf( GetKeyState( VK_UP ) < 0 .or. ( GetKeyState( VK_TAB ) < 0 .and. GetKeyState( VK_SHIFT ) < 0 ), - 1, 1 )
   IF ::bGetFocus != Nil
      ::oParent:lSuspendMsgsHandling := .T.
      ::lnoValid := .T.
      res :=  Eval( ::bGetFocus, ::value, Self )
      ::oParent:lSuspendMsgsHandling := .F.
      ::lnoValid := ! res
      IF ! res
         GetSkip( ::oParent, ::handle, , nSkip )
      ENDIF
   ENDIF

   RETURN res

METHOD Valid( ) CLASS HDatePicker
   LOCAL  res := .t.

   IF ! CheckFocus( Self, .T. ) .OR. ::lnoValid
      RETURN .T.
   ENDIF
   ::value := GetDatePicker( ::handle )
   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::value, Self )
   ENDIF
   IF ::bLostFocus != Nil
      ::oparent:lSuspendMsgsHandling := .T.
      res := Eval( ::bLostFocus, ::value, Self )
      ::oparent:lSuspendMsgsHandling := .F.
      IF ! res
         ::SetFocus( )
      ENDIF
   ENDIF
   RETURN res