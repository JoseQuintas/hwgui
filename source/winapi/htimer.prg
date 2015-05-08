/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HTimer class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define  TIMER_FIRST_ID   33900

CLASS HTimer INHERIT HObject

   CLASS VAR aTimers   INIT {}
   DATA objname
   DATA id
   DATA value
   DATA oParent
   DATA bAction

   ACCESS Interval     INLINE ::value
   ASSIGN Interval(x)  INLINE ::value := x, ;
         Iif( x == 0, ::End(), hwg_SetTimer( ::oParent:handle,::id,x ) )

   METHOD New( oParent, id, value, bAction )
   METHOD End()

ENDCLASS

METHOD New( oParent, nId, value, bAction ) CLASS HTimer

   ::oParent := Iif( oParent == Nil, HWindow():GetMain(), oParent )
   ::id := Iif( nId == Nil, TIMER_FIRST_ID + Len( ::aTimers ), nId )
   ::value   := value
   ::bAction := bAction

   hwg_Settimer( ::oParent:handle, ::id, ::value )
   AAdd( ::aTimers, Self )

   RETURN Self

METHOD End() CLASS HTimer
   LOCAL i

   hwg_Killtimer( ::oParent:handle, ::id )
   i := Ascan( ::aTimers, { |o|o:id == ::id } )
   IF i != 0
      ADel( ::aTimers, i )
      ASize( ::aTimers, Len( ::aTimers ) - 1 )
   ENDIF

   RETURN Nil

FUNCTION hwg_TimerProc( hWnd, idTimer, time )

   LOCAL i := Ascan( HTimer():aTimers, { |o|o:id == idTimer } )

   IF i != 0
      Eval( HTimer():aTimers[i]:bAction, time )
   ENDIF

   RETURN Nil

FUNCTION hwg_ReleaseTimers()
   LOCAL oTimer, i

   For i := 1 TO Len( HTimer():aTimers )
      oTimer := HTimer():aTimers[i]
      hwg_Killtimer( oTimer:oParent:handle, oTimer:id )
   NEXT

   RETURN Nil

   EXIT PROCEDURE CleanTimers
   hwg_ReleaseTimers()

   RETURN
