/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HMonthCalendar class
 *
 * Copyright 2008 Luiz Rafael Culik (luiz at xharbour.com.br
 * www - http://www.xharbour.org
*/

#include "hbclass.ch"
#include "guilib.ch"

#define MCS_DAYSTATE             1
#define MCS_MULTISELECT          2
#define MCS_WEEKNUMBERS          4
#define MCS_NOTODAYCIRCLE        8
#define MCS_NOTODAY             16

CLASS HMonthCalendar INHERIT HControl

   CLASS VAR winclass   INIT "SysMonthCal32"

   DATA dValue
   DATA bChange

   METHOD New( oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bChange, cTooltip, lNoToday, lNoTodayCircle, ;
      lWeekNumbers )
   METHOD Activate()
   METHOD Init()
   METHOD Value( dValue ) SETGET

ENDCLASS

METHOD New( oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bChange, cTooltip, lNoToday, lNoTodayCircle, ;
      lWeekNumbers ) CLASS HMonthCalendar

   * Parameters not used
   HB_SYMBOL_UNUSED(lNoToday)
   HB_SYMBOL_UNUSED(lNoTodayCircle)
   HB_SYMBOL_UNUSED(lWeekNumbers)

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      , , ctooltip )

   ::dValue   := iif( ValType( vari ) == "D" .AND. !Empty( vari ), vari, Date() )

   ::bChange := bChange

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HMonthCalendar

LOCAL bChg := {||
   ::dValue := hwg_Getmonthcalendardate( ::handle )
   IF !Empty( ::bChange )
      Eval( ::bChange )
   ENDIF
   RETURN .T.
   }

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Initmonthcalendar ( ::oParent:handle, , ;
         ::nLeft, ::nTop, ::nWidth, ::nHeight )
      hwg_Setwindowobject( ::handle, Self )
      hwg_Monthcalendar_setaction( ::handle, bChg )
      ::Init()
   ENDIF

   RETURN Nil

METHOD Init() CLASS HMonthCalendar

   IF !::lInit
      ::Super:Init()
      IF !Empty( ::dValue )
         hwg_Setmonthcalendardate( ::handle , ::dValue )
      ENDIF
   ENDIF

   RETURN Nil

METHOD Value( dValue ) CLASS HMonthCalendar

   IF dValue != Nil
      IF ValType( dValue ) == "D" .AND. !Empty( dValue )
         hwg_Setmonthcalendardate( ::handle, dValue )
         ::dValue := dValue
      ENDIF
   ENDIF

   RETURN ::dValue

FUNCTION hwg_pCalendar(dstartdate, cTitle , cOK, cCancel , nx , ny , wid, hei )

   * Date picker command for all platforms in the design of original
   * Windows only DATEPICKER command

   LOCAL oDlg, oMC , oFont , dolddate , dnewdate,  lcancel

   IF cTitle == NIL
      cTitle := "Calendar"
   ENDIF

   IF cOK == NIL
      cOK := "OK"
   ENDIF

   IF cCancel == NIL
      cCancel := "Cancel"
   ENDIF

   IF dstartdate == NIL
      dstartdate := DATE()
   ENDIF

   IF nx == NIL
      nx := 0  && old: 20
   ENDIF

   IF ny == NIL
      ny := 0  && old: 20
   ENDIF

   IF wid == NIL
      wid := 200 && old: 80
   ENDIF

   IF hei == NIL
      hei := 160 && old: 20
   ENDIF

   oFont := hwg_DefaultFont()

   lcancel := .T.

   * Remember old date
   dolddate := dstartdate

   INIT DIALOG oDlg TITLE cTitle ;
      AT nx,ny SIZE  wid , hei + 23 && wid , hei , 22 = height of buttons

   @ 0,0 MONTHCALENDAR oMC ;
      SIZE wid - 1 , hei - 1 ;
      INIT dstartdate ;   && Date(), if NIL
      FONT oFont

   @ 0 ,hei BUTTON cOK FONT oFont ;
    ON CLICK {|| lcancel := .F., dnewdate := oMC:Value , oDlg:Close() } SIZE 80 , 22
   @ 81,hei BUTTON cCancel FONT oFont ;
    ON CLICK {|| oDlg:Close() } SIZE 80, 22

   ACTIVATE DIALOG oDlg

   IF lcancel
      dnewdate := dolddate
   ENDIF

   RETURN dnewdate

FUNCTION hwg_oDatepicker_bmp()

   * Returns the bimap object of image Datepick_Button2.bmp
   * (size 11 x 11 )
   * for the multi platform datepicker based on HMONTHCALENDAR class

RETURN HBitmap():AddString("Datepick_Button", hwg_cHex2Bin(;
   "42 4D 6A 00 00 00 00 00 00 00 3E 00 00 00 28 00 " + ;
   "00 00 0B 00 00 00 0B 00 00 00 01 00 01 00 00 00 " + ;
   "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
   "00 00 00 00 00 00 F0 FB FF 00 00 00 00 00 00 00 " + ;
   "00 00 00 00 00 00 00 00 00 00 04 00 00 00 0E 00 " + ;
   "00 00 1F 00 00 00 3F 80 00 00 00 00 00 00 00 00 " + ;
   "00 00 00 00 00 00 00 00 00 00 " ) )
