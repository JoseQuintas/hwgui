/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HMonthCalendar class
 *
 * Copyright 2008 Luiz Rafael Culik (luiz at xharbour.com.br
 * www - http://www.xharbour.org
*/

   //--------------------------------------------------------------------------//


#include "hbclass.ch"
#include "guilib.ch"

#define MCS_DAYSTATE             1
#define MCS_MULTISELECT          2
#define MCS_WEEKNUMBERS          4
#define MCS_NOTODAYCIRCLE        8
#define MCS_NOTODAY             16

   //--------------------------------------------------------------------------//

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

   //--------------------------------------------------------------------------//

METHOD New( oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bChange, cTooltip, lNoToday, lNoTodayCircle, ;
      lWeekNumbers ) CLASS HMonthCalendar

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      , , ctooltip )

   ::dValue   := iif( ValType( vari ) == "D" .AND. !Empty( vari ), vari, Date() )

   ::bChange := bChange

   ::Activate()

   RETURN Self

   //--------------------------------------------------------------------------//

METHOD Activate CLASS HMonthCalendar

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Initmonthcalendar ( ::oParent:handle, , ;
         ::nLeft, ::nTop, ::nWidth, ::nHeight )
      hwg_Setwindowobject( ::handle, Self )  
      hwg_Monthcalendar_setaction( ::handle, { ||::dValue := hwg_Getmonthcalendardate( ::handle ) } )
      ::Init()
   ENDIF

   RETURN Nil

   //--------------------------------------------------------------------------//

METHOD Init() CLASS HMonthCalendar

   IF !::lInit
      ::Super:Init()
      IF !Empty( ::dValue )
         hwg_Setmonthcalendardate( ::handle , ::dValue )
      ENDIF
   ENDIF

   RETURN Nil

   //--------------------------------------------------------------------------//

METHOD Value( dValue ) CLASS HMonthCalendar

   IF dValue != Nil
      IF ValType( dValue ) == "D" .AND. !Empty( dValue )
         hwg_Setmonthcalendardate( ::handle, dValue )
         ::dValue := dValue
      ENDIF
   ENDIF

   Return ::dValue
