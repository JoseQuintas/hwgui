/*
 *$Id$
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
   DATA lInit   INIT .F.
   DATA oParent
   DATA bAction

   METHOD New( oParent,id,value,bAction )
   METHOD Init()
   METHOD onAction()

   METHOD End()

   DATA   xName          HIDDEN
   ACCESS Name           INLINE ::xName
   ASSIGN Name( cName )  INLINE IIF( !EMPTY( cName ) .AND. VALTYPE( cName) == "C" .AND. ! ":" $ cName .AND. ! "[" $ cName,;
			( ::xName := cName, __objAddData( ::oParent, cName ), ::oParent: & ( cName ) := Self), Nil)

ENDCLASS

METHOD New( oParent,nId,value,bAction ) CLASS HTimer

   ::oParent := Iif( oParent==Nil, HWindow():GetMain(), oParent )
   IF nId == nil
      nId := TIMER_FIRST_ID
      DO WHILE AScan( ::aTimers, { | o | o:id == nId } ) !=  0
         nId ++
      ENDDO
   ENDIF
   ::id      := nId
   /*
   ::value   := value
   ::bAction := bAction

//   ::tag := hwg_SetTimer( ::id,::value )

   */
   ::value   := IIF( VALTYPE( value ) = "N", value, 0 )
   ::bAction := bAction
   /*
    if ::value > 0
      SetTimer( oParent:handle, ::id, ::value )
   endif
   */
   ::Init()
   AAdd( ::aTimers, Self )
   ::oParent:AddObject( Self )





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

METHOD Init CLASS HTimer
   IF ! ::lInit
      IF ::value > 0
         ::tag := hwg_SetTimer( ::id, ::value )
      ENDIF
   ENDIF
   RETURN  NIL

METHOD onAction()

   hwg_TimerProc( , ::id, ::interval )
   
RETURN Nil


Function hwg_TimerProc( hWnd, idTimer, Time ) 

   LOCAL i := AScan( HTimer():aTimers, { | o | o:id == idTimer } )

   HB_SYMBOL_UNUSED( hWnd )

   IF i != 0 .AND. HTimer():aTimers[ i ]:value > 0 .AND. HTimer():aTimers[ i ]:bAction != Nil .AND.;
      ValType( HTimer():aTimers[ i ]:bAction ) == "B"
      Eval( HTimer():aTimers[ i ]:bAction, HTimer():aTimers[i], time )
   ENDIF

   RETURN Nil

EXIT PROCEDURE CleanTimers
Local oTimer, i

   For i := 1 TO Len( HTimer():aTimers )
      oTimer := HTimer():aTimers[i]
      hwg_KillTimer( oTimer:tag )
   NEXT

Return

