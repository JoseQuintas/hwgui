/*
 *$Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HTimer class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define  TIMER_FIRST_ID   33900

CLASS HTimer INHERIT HObject

   CLASS VAR aTimers   INIT {}
   DATA objname
   DATA id, tag
   DATA value
   DATA oParent
   DATA bAction
   DATA name
   ACCESS Interval     INLINE ::value
   ASSIGN Interval(x)  INLINE ::value := x, ::End(), ;
         Iif( x == 0, .T., ::tag := hwg_SetTimer( ::id,x ) )

   METHOD New( oParent, id, value, bAction )
   METHOD End()

ENDCLASS

METHOD New( oParent, nId, value, bAction ) CLASS HTimer

   ::oParent := iif( oParent == Nil, HWindow():GetMain(), oParent )
   IF nId == Nil
      nId := TIMER_FIRST_ID
      DO WHILE AScan( ::aTimers, { |o| o:id == nId } ) !=  0
         nId ++
      ENDDO
   ENDIF
   ::Id := nId

   ::value   := iif( ValType( value ) == "N", value, 1000 )
   ::bAction := bAction

   ::tag := hwg_SetTimer( ::id, ::value )
   AAdd( ::aTimers, Self )

   RETURN Self

METHOD End() CLASS HTimer
   LOCAL i

   hwg_KillTimer( ::tag )
   i := Ascan( ::aTimers, { |o|o:id == ::id } )
   IF i != 0
      ADel( ::aTimers, i )
      ASize( ::aTimers, Len( ::aTimers ) - 1 )
   ENDIF

   RETURN Nil

FUNCTION hwg_TimerProc( idTimer )

   LOCAL i := Ascan( HTimer():aTimers, { |o|o:id == idTimer } )

   IF i != 0 .AND. ValType( HTimer():aTimers[i]:bAction ) == "B"
      Eval( HTimer():aTimers[i]:bAction )
   ENDIF

   RETURN Nil

FUNCTION hwg_ReleaseTimers()
   LOCAL oTimer, i

   For i := 1 TO Len( HTimer():aTimers )
      oTimer := HTimer():aTimers[i]
      hwg_KillTimer( oTimer:tag )
   NEXT

   RETURN Nil

   EXIT PROCEDURE CleanTimers
   hwg_ReleaseTimers()

   RETURN
