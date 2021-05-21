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
   DATA id, tag
   DATA value
   DATA oParent
   DATA bAction
   DATA lOnce          INIT .F.
   DATA name
   /*
   ACCESS Interval     INLINE ::value
   ASSIGN Interval(x)  INLINE ::value := x, ::End(), ;
         Iif( x == 0, .T., ::tag := hwg_SetTimer( ::id,x ) )
   */
   METHOD Interval( n ) SETGET
   METHOD New( oParent, nId, value, bAction, lOnce )
   METHOD End()

ENDCLASS

METHOD New( oParent, nId, value, bAction, lOnce ) CLASS HTimer

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
   ::lOnce := !Empty( lOnce )

   ::tag := hwg_SetTimer( ::id, ::value )
   AAdd( ::aTimers, Self )

   RETURN Self

METHOD Interval( n ) CLASS HTimer

   LOCAL nOld := ::value, nId

   IF n != Nil
      IF n > 0
         nId := TIMER_FIRST_ID
         DO WHILE AScan( ::aTimers, { |o| o:id == nId } ) !=  0
            nId ++
         ENDDO
         ::id := nId
         ::tag := hwg_SetTimer( ::id, ::value := n )
      ENDIF
   ENDIF

   RETURN nOld

METHOD End() CLASS HTimer
   LOCAL i

   //hwg_KillTimer( ::tag )
   ::bAction := Nil
   i := Ascan( ::aTimers, { |o|o:id == ::id } )
   IF i != 0
      ADel( ::aTimers, i )
      ASize( ::aTimers, Len( ::aTimers ) - 1 )
   ENDIF

   RETURN Nil

FUNCTION hwg_TimerProc( idTimer )

   LOCAL i := Ascan( HTimer():aTimers, { |o|o:id == idTimer } ), b, oParent

   IF i != 0 .AND. ValType( HTimer():aTimers[i]:bAction ) == "B"
      b := HTimer():aTimers[i]:bAction
      oParent := HTimer():aTimers[i]:oParent
      IF HTimer():aTimers[i]:lOnce
         HTimer():aTimers[i]:End()
      ENDIF
      Eval( b, oParent )
      RETURN 1
   ENDIF

   RETURN 0

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

* ============================== EOF of htimer.prg =============================
