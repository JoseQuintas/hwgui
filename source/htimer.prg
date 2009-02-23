/*
 * $Id: htimer.prg,v 1.12 2009-02-23 04:18:32 lfbasso Exp $
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

CLASS VAR aTimers   INIT { }

   DATA lInit   INIT .F.
   DATA id
   DATA value
   DATA oParent
   DATA bAction

   //DATA   xName          HIDDEN
   //ACCESS Name           INLINE ::xName
   //ASSIGN Name( cName )  INLINE ::xName := cName, ;
   //                                        __objAddData( ::oParent, cName ), ;
   //                                        ::oParent: & ( cName ) := Self
   ASSIGN Name( cName )   INLINE IIF( !EMPTY( cName ) .AND. VALTYPE( cName) == "C" .AND. cName != "::" .AND. ! "[" $ cName, ;
	          		                (__objAddData( ::oParent, cName ), ::oParent: & ( cName ) := Self), .T. )
   ACCESS Interval       INLINE ::value
   ASSIGN Interval( x )  INLINE ::value := x,     ;
                                           SetTimer( ::oParent:handle, ::id, ::value )

   METHOD New( oParent, id, value, bAction )
   METHOD Init()
   METHOD END()

ENDCLASS


METHOD New( oParent, nId, value, bAction ) CLASS HTimer

   ::oParent := Iif( oParent==Nil, HWindow():GetMain():oDefaultParent, oParent )
   IF nId == nil
      nId := TIMER_FIRST_ID
      DO WHILE AScan( ::aTimers, { | o | o:id == nId } ) !=  0
         nId ++
      ENDDO
   ENDIF
   ::id      := nId
   ::value   := value
   ::bAction := bAction
   /*
    if ::value > 0
      SetTimer( oParent:handle, ::id, ::value )
   endif
   */
   ::Init()
   AAdd( ::aTimers, Self )
   ::oParent:AddObject( Self )

   RETURN Self

METHOD Init CLASS HTimer
   IF ! ::lInit
      IF ::value > 0
         SetTimer( ::oParent:handle, ::id, ::value )
      ENDIF
   ENDIF
   RETURN  NIL

METHOD END() CLASS HTimer
   LOCAL i

   KillTimer( ::oParent:handle, ::id )
   IF ( i := AScan( ::aTimers, { | o | o:id == ::id } ) ) > 0
      ADel( ::aTimers, i )
      ASize( ::aTimers, Len( ::aTimers ) - 1 )
   ENDIF

   RETURN Nil


FUNCTION TimerProc( hWnd, idTimer, Time )
   LOCAL i := AScan( HTimer():aTimers, { | o | o:id == idTimer } )

   HB_SYMBOL_UNUSED( hWnd )

   IF i != 0 .and. HTimer():aTimers[ i ]:value > 0 .AND. HTimer():aTimers[ i ]:bAction != Nil
      Eval( HTimer():aTimers[ i ]:bAction, HTimer():aTimers[i], time )
   ENDIF

   RETURN Nil



   EXIT PROCEDURE CleanTimers
   LOCAL oTimer, i

   FOR i := 1 TO Len( HTimer():aTimers )
      oTimer := HTimer():aTimers[ i ]
      KillTimer( oTimer:oParent:handle, oTimer:id )
   NEXT

   RETURN
