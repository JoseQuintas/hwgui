/*
 *$Id: htimer.prg,v 1.1 2005-01-12 11:56:34 alkresin Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HTimer class 
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
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

   METHOD New( oParent,id,value,bAction )
   METHOD End()

ENDCLASS

METHOD New( oParent,nId,value,bAction ) CLASS HTimer

   ::oParent := Iif( oParent==Nil, HWindow():GetMain(), oParent )
   ::id      := Iif( nId==Nil, TIMER_FIRST_ID + Len( ::oParent:aControls ), ;
                         nId )
   ::value   := value
   ::bAction := bAction

   ::tag := hwg_SetTimer( ::id,::value )
   Aadd( ::aTimers,Self )

Return Self

METHOD End() CLASS HTimer
Local i

   hwg_KillTimer( ::tag )
   i := Ascan( ::aTimers,{|o|o:id==::id} )
   IF i != 0
      Adel( ::aTimers,i )
      Asize( ::aTimers,Len( ::aTimers )-1 )
   ENDIF

Return Nil

Function TimerProc( idTimer )
Local i := Ascan( HTimer():aTimers,{|o|o:id==idTimer} )

   IF i != 0
      Eval( HTimer():aTimers[i]:bAction )
   ENDIF

Return Nil

EXIT PROCEDURE CleanTimers
Local oTimer, i

   For i := 1 TO Len( HTimer():aTimers )
      oTimer := HTimer():aTimers[i]
      hwg_KillTimer( oTimer:tag )
   NEXT

Return
