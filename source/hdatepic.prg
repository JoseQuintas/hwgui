/*
 * $Id$
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
#define DTM_FIRST             0x1000
#define DTM_GETSYSTEMTIME     (DTM_FIRST + 1)
#define DTM_SETSYSTEMTIME     (DTM_FIRST + 2)
#define DTM_GETMONTHCAL        4104   // 0x1008
#define DTM_CLOSEMONTHCAL      4109
#define NM_KILLFOCUS          - 8
#define NM_SETFOCUS           - 7
#define GDT_ERROR             - 1
#define GDT_VALID              0
#define GDT_NONE               1


CLASS HDatePicker INHERIT HControl

   CLASS VAR winclass   INIT "SYSDATETIMEPICK32"
   DATA bSetGet
   DATA dValue, tValue
   DATA bChange
   DATA lShowTime      INIT .T.

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
         oFont, bInit, bGfocus, bLfocus, bChange, ctooltip, tcolor, bcolor, lShowTime )
   METHOD Activate()
   METHOD Init()
   METHOD OnEvent( msg, wParam, lParam )
   METHOD Refresh()
   METHOD GetValue()
   METHOD SetValue( xValue )
   METHOD Redefine( oWndParent, nId, vari, bSetGet, oFont, bSize, bInit, ;
         bGfocus, bLfocus, bChange, ctooltip, tcolor, bcolor, lShowTime )
   METHOD onChange( nMess )
   METHOD When( )
   METHOD Valid( )
   METHOD Value ( Value ) SETGET
   METHOD Checkvalue ( lValue ) SETGET

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bGfocus, bLfocus, bChange, ctooltip, tcolor, bcolor, lShowTime ) CLASS HDatePicker

   nStyle := Hwg_BitOr( Iif( nStyle==NIL, 0, nStyle ), IIF( bSetGet != NIL, WS_TABSTOP, 0 ) + ;
         IIF( lShowTime == NIL .OR. ! lShowTime, 0, DTS_TIMEFORMAT ) )
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
         ,, ctooltip, tcolor, bcolor )

   ::lShowTime := Hwg_BitAnd( nStyle, DTS_TIMEFORMAT ) > 0
   ::dValue    := IIF( vari == NIL .OR. ValType( vari ) != "D", CToD( Space( 8 ) ), vari )
   ::tValue    := IIF( vari == NIL .OR. Valtype( vari ) != "C", SPACE(6), vari )
   ::title     := IIF( ! ::lShowTime, ::dValue, ::tValue )

   ::bSetGet := bSetGet
   ::bChange := bChange

   HWG_InitCommonControlsEx()
   ::Activate()

   IF bSetGet != NIL
      ::bGetFocus := bGfocus
      ::bLostFocus := bLfocus
      ::oParent:AddEvent( NM_SETFOCUS, Self, { | o, id | ::When( o:FindControl( id ) ) }, .T., "onGotFocus" )
      ::oParent:AddEvent( NM_KILLFOCUS, Self, { | o, id | ::Valid( o:FindControl( id ) ) }, .T., "onLostFocus" )
   ELSE
      IF bGfocus != NIL
         ::lnoValid := .T.
         ::oParent:AddEvent( NM_SETFOCUS, Self, bGfocus, .T., "onGotFocus" )
      ENDIF
      IF bLfocus != NIL
         ::oParent:AddEvent( NM_KILLFOCUS, Self, bLfocus, .T., "onLostFocus" )
      ENDIF
   ENDIF
   ::oParent:AddEvent( DTN_DATETIMECHANGE, Self, { | | ::onChange( DTN_DATETIMECHANGE ) }, .T., "onChange" )
   ::oParent:AddEvent( DTN_CLOSEUP, Self, { | | ::onChange( DTN_CLOSEUP ) }, .T., "onClose" )

   RETURN Self

METHOD Redefine( oWndParent, nId, vari, bSetGet, oFont, bSize, bInit, ;
      bGfocus, bLfocus, bChange, ctooltip, tcolor, bcolor, lShowTime ) CLASS  HDatePicker
   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
         bSize,, ctooltip, tcolor, bcolor )

   HWG_InitCommonControlsEx()
   ::dValue   := IIf( vari == NIL .OR. ValType( vari ) != "D", CToD( Space( 8 ) ), vari )
   ::tValue    := IIF( vari == NIL .OR. Valtype( vari ) != "C", SPACE(6), vari )
   ::bSetGet := bSetGet
   ::bChange := bChange
   ::lShowTime := lShowTime
   IF bGfocus != NIL
      ::oParent:AddEvent( NM_SETFOCUS, Self, bGfocus, .T., "onGotFocus" )
   ENDIF
   ::oParent:AddEvent( DTN_DATETIMECHANGE, Self, { | | ::onChange( DTN_DATETIMECHANGE ) }, .T., "onChange" )
   ::oParent:AddEvent( DTN_CLOSEUP, Self, { | | ::onChange(  DTN_CLOSEUP ) }, .T., "onClose" )
   IF bSetGet != NIL
      ::bLostFocus := bLfocus
      ::oParent:AddEvent( NM_KILLFOCUS, Self, { | o, id | ::Valid( o:FindControl( id ) ) }, .T., "onLostFocus" )
   ELSE
      IF bLfocus != NIL
         ::oParent:AddEvent( NM_KILLFOCUS, Self, bLfocus, .T., "onLostFocus" )
      ENDIF
   ENDIF

   RETURN Self

METHOD Activate() CLASS HDatePicker
   IF ! Empty( ::oParent:handle )
      ::handle := CreateDatePicker( ::oParent:handle, ::id, ;
            ::nLeft, ::nTop, ::nWidth, ::nHeight, ::style )
      ::Init()
   ENDIF

   RETURN NIL

METHOD Init() CLASS HDatePicker
   IF ! ::lInit
   
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      HWG_INITDATEPICKERPROC( ::handle )
      ::Refresh()
      Super:Init()

   ENDIF

   RETURN NIL

METHOD OnEvent( msg, wParam, lParam ) CLASS HDatePicker

   IF ::bOther != NIL
      IF Eval( ::bOther, Self, msg, wParam, lParam ) != -1
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
      IF ProcKeyList( Self, wParam )
         RETURN 0
      ENDIF
   ELSEIF  msg = WM_GETDLGCODE
      IF WPARAM = VK_RETURN .OR. wParam = VK_TAB
          Return DLGC_WANTMESSAGE
          //RETURN DLGC_WANTTAB
      ENDIF
   ENDIF

   RETURN -1

METHOD CheckValue( lValue )  CLASS HDatePicker

   IF HWG_BITAND( ::Style, DTS_SHOWNONE ) = 0
       RETURN .F.
   ENDIF
   IF lValue != Nil
      IF IIF( GetDatePicker( ::handle, GDT_NONE ) = GDT_NONE ,.F., .T. ) != lValue
         IF ! lValue
            SendMessage( ::Handle, DTM_SETSYSTEMTIME, GDT_NONE, 0 )
         ELSE
            SetDatePicker( ::handle, ::dValue, STRTRAN( ::tValue, ":", "" ) )
         ENDIF
      ENDIF
   ENDIF
   RETURN IIF( GetDatePicker( ::handle, GDT_NONE ) = GDT_NONE ,.F., .T. )

METHOD Value( Value )  CLASS HDatePicker

   IF Value != NIL
      ::SetValue( Value  )
   ENDIF

   RETURN IIF( ::lShowTime, ::tValue, ::dValue )

METHOD GetValue() CLASS HDatePicker

   RETURN IIF( ! ::lShowTime, GetDatePicker( ::handle ), GetTimePicker( ::handle ) )

METHOD SetValue( xValue ) CLASS HDatePicker

   IF Empty( xValue )
      SetDatePickerNull( ::handle )
   ELSEIF ::lShowTime
      SetDatePicker( ::handle, Date(), STRTRAN( xValue, ":", "" ) )
   ELSE
      SetDatePicker( ::handle, xValue, STRTRAN( ::tValue, ":", "" ) )
   ENDIF
   ::dValue := GetDatePicker( ::handle )
   ::tValue := GetTimePicker( ::handle )
   ::title := IIF( ::lShowTime, ::tValue, ::dValue )
   IF ::bSetGet != NIL
      Eval( ::bSetGet, IIF( ::lShowTime, ::tValue,::dValue ), Self )
   ENDIF

   RETURN NIL

METHOD Refresh() CLASS HDatePicker

   IF ::bSetGet != NIL
      IF ! ::lShowTime
         ::dValue := Eval( ::bSetGet,, Self )
      ELSE
         ::tValue := Eval( ::bSetGet,, Self )
      ENDIF
   ENDIF
   IF Empty( ::dValue ) .AND. ! ::lShowTime
      //SetDatePickerNull( ::handle )
      SetDatePicker( ::handle, date(), STRTRAN( Time(), ":", "" ) )
   ELSE
      ::SetValue( IIF( ! ::lShowTime, ::dValue, ::tValue ) )
   ENDIF

   RETURN NIL


METHOD onChange( nMess ) CLASS HDatePicker

   IF ( nMess == DTN_DATETIMECHANGE .AND. ;
         SendMessage( ::handle, DTM_GETMONTHCAL, 0, 0 ) == 0 ) .OR. ;
      nMess == DTN_CLOSEUP
      IF nMess = DTN_CLOSEUP
         POSTMESSAGE( ::handle, WM_KEYDOWN, VK_RIGHT, 0 )
         ::SetFocus()
      ENDIF
      ::dValue := GetDatePicker( ::handle )
      ::tValue := GetTimePicker( ::handle )
      IF ::bSetGet != NIL
         Eval( ::bSetGet, IIF( ::lShowTime, ::tValue, ::dValue ), Self )
      ENDIF
      IF ::bChange != NIL
         ::oparent:lSuspendMsgsHandling := .T.
         Eval( ::bChange, IIF( ::lShowTime, ::tValue, ::dValue), Self )
         ::oparent:lSuspendMsgsHandling := .F.
      ENDIF
   ENDIF

   RETURN .T.

METHOD When( ) CLASS HDatePicker
   LOCAL res := .t.,  nSkip

   IF ! CheckFocus( Self, .f. )
      RETURN .t.
   ENDIF
   IF ::bGetFocus != NIL
      nSkip := IIf( GetKeyState( VK_UP ) < 0 .or. ( GetKeyState( VK_TAB ) < 0 .and. GetKeyState( VK_SHIFT ) < 0 ), - 1, 1 )
      ::oParent:lSuspendMsgsHandling := .T.
      ::lnoValid := .T.
      res :=  Eval( ::bGetFocus, IIF( ::lShowTime, ::tValue, ::dValue ), Self )
      ::lnoValid := ! res
      ::oParent:lSuspendMsgsHandling := .F.
      IF VALTYPE(res) = "L" .AND. ! res
         WhenSetFocus( Self, nSkip )
         SendMessage( ::handle, DTM_CLOSEMONTHCAL, 0, 0 )
      ELSE
         ::SetFocus()
      ENDIF
   ENDIF

   RETURN res

METHOD Valid( ) CLASS HDatePicker
   LOCAL  res := .t.

   IF ! CheckFocus( Self, .T. ) .OR. ::lnoValid
      RETURN .T.
   ENDIF
   ::dValue := GetDatePicker( ::handle )
   IF ::bSetGet != NIL
      Eval( ::bSetGet, IIF( ::lShowTime, ::tValue,::dValue ), Self )
   ENDIF
   IF ::bLostFocus != NIL
      ::oparent:lSuspendMsgsHandling := .T.
      res := Eval( ::bLostFocus, IIF( ::lShowTime, ::tValue, ::dValue ), Self )
      res := IIF( ValType( res ) == "L", res, .T. )
      ::oparent:lSuspendMsgsHandling := .F.
      IF ! res
         POSTMESSAGE( ::handle, WM_KEYDOWN, VK_RIGHT, 0 )
         ::SetFocus( .T. )
      ENDIF
   ENDIF

   RETURN res
