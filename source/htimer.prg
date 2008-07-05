/*
 * $Id: htimer.prg,v 1.5 2008-07-05 16:53:00 mlacecilia Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HTimer class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define  TIMER_FIRST_ID   33900

CLASS HTimer INHERIT HObject

   CLASS VAR aTimers   INIT {}
   DATA id
   DATA value
   DATA oParent
   DATA bAction
   
   DATA   xName        HIDDEN
   ACCESS Name         INLINE ::xName
   ASSIGN Name(cName)  INLINE ::xName := cName, ;
	                           __objAddData(::oParent, cName),;
                              ::oParent:&(cName) := self

	DATA   xInterval    HIDDEN
   ACCESS Interval     INLINE ::xInterval
   ASSIGN Interval(x)  INLINE ::xInterval := x, ;
                              IIF( ::xInterval == 0, ;
										     KillTimer( ::oParent:handle, ::id ), ;
											  SetTimer( ::oParent:handle, ::id, ::xInterval ))

   METHOD New( oParent,id,value,bAction )
   METHOD End()

ENDCLASS

METHOD New( oParent,nId,value,bAction ) CLASS HTimer

   ::oParent := Iif( oParent==Nil, HWindow():GetMain(), oParent )
   ::id      := Iif( nId==Nil, TIMER_FIRST_ID + Len( ::oParent:aControls ), ;
                         nId )
   ::value   := value
   ::bAction := bAction
	if ::value > 0
      SetTimer( oParent:handle, ::id, ::value )
   endif
   Aadd( ::aTimers,Self )

Return Self

METHOD End() CLASS HTimer
Local i

   KillTimer( ::oParent:handle,::id )
   i := Ascan( ::aTimers,{|o|o:id==::id} )
   IF i != 0
      Adel( ::aTimers,i )
      Asize( ::aTimers,Len( ::aTimers )-1 )
   ENDIF

Return Nil

Function TimerProc( hWnd, idTimer, time )
Local i := Ascan( HTimer():aTimers,{|o|o:id==idTimer} )

HB_SYMBOL_UNUSED(hWnd)

   IF i != 0
      Eval( HTimer():aTimers[i]:bAction,time )
   ENDIF

Return Nil

EXIT PROCEDURE CleanTimers
Local oTimer, i

   For i := 1 TO Len( HTimer():aTimers )
      oTimer := HTimer():aTimers[i]
      KillTimer( oTimer:oParent:handle,oTimer:id )
   NEXT

Return
