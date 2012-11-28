/*
 * $Id$
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

   DATA   xName          HIDDEN
   ACCESS Name           INLINE ::xName
   ASSIGN Name( cName )  INLINE IIF( !EMPTY( cName ) .AND. VALTYPE( cName) == "C" .AND. ! ":" $ cName .AND. ! "[" $ cName,;
         ( ::xName := cName, __objAddData( ::oParent, cName ), ::oParent: & ( cName ) := Self), Nil)
   ACCESS Interval       INLINE ::value
   ASSIGN Interval( x )  INLINE ::value := x, SetTimer( ::oParent:handle, ::id, ::value )

   METHOD New( oParent, nId, value, bAction )
   METHOD Init()
   METHOD onAction()
   METHOD END()

ENDCLASS


METHOD New( oParent, nId, value, bAction ) CLASS HTimer

   ::oParent := Iif( oParent==NIL, HWindow():GetMain():oDefaultParent, oParent )
   IF nId == NIL
      nId := TIMER_FIRST_ID
      DO WHILE AScan( ::aTimers, { | o | o:id == nId } ) !=  0
         nId ++
      ENDDO
   ENDIF
   ::id      := nId
   ::value   := IIF( VALTYPE( value ) = "N", value, 0 )
   ::bAction := bAction
   /*
   IF ::value > 0
      SetTimer( oParent:handle, ::id, ::value )
   ENDIF
   */
   
   ::Init()
   AAdd( ::aTimers, Self )
   ::oParent:AddObject( Self )

   RETURN Self

METHOD Init() CLASS HTimer

   IF ! ::lInit .AND. ! EMPTY( ::oParent:handle )
      IF ::value > 0
         SetTimer( ::oParent:handle, ::id, ::value )
      ENDIF
      ::lInit := .T.
   ENDIF

   RETURN  NIL

METHOD END() CLASS HTimer
   LOCAL i

   IF ( i := AScan( ::aTimers, { | o | o:id == ::id } ) ) > 0
      IF ::oParent != NIL
         KillTimer( ::oParent:handle, ::id )
      ENDIF
      ADel( ::aTimers, i )
      ASize( ::aTimers, Len( ::aTimers ) - 1 )
   ENDIF

   RETURN NIL

METHOD onAction()

   TimerProc( , ::id, ::interval )

   RETURN NIL


FUNCTION TimerProc( hWnd, idTimer, Time )
   LOCAL i := AScan( HTimer():aTimers, { | o | o:id == idTimer } )

   HB_SYMBOL_UNUSED( hWnd )

   IF i != 0 .AND. HTimer():aTimers[ i ]:value > 0 .AND. HTimer():aTimers[ i ]:bAction != Nil .AND.;
      ValType( HTimer():aTimers[ i ]:bAction ) == "B"
      Eval( HTimer():aTimers[ i ]:bAction, HTimer():aTimers[i], time )
   ENDIF

   RETURN NIL

EXIT PROCEDURE CleanTimers
   LOCAL oTimer, i

   FOR i := 1 TO Len( HTimer():aTimers )
      oTimer := HTimer():aTimers[ i ]
      KillTimer( oTimer:oParent:handle, oTimer:id )
   NEXT

   RETURN
