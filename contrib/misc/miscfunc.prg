/*
 *$Id: $
 */

FUNCTION ADDMETHOD( oObjectName, cMethodName, pFunction )    

   IF VALTYPE( oObjectName ) = "O" .AND. ! EMPTY( cMethodName )
      IF ! __ObjHasMsg( oObjectName, cMethodName )
          __objAddMethod( oObjectName, cMethodName, pFunction )  
      ENDIF   
      RETURN .T.
   ENDIF	    
   RETURN .F.

FUNCTION ADDPROPERTY( oObjectName, cPropertyName, eNewValue )

   IF VALTYPE( oObjectName ) = "O" .AND. ! EMPTY( cPropertyName )
      IF ! __objHasData( oObjectName, cPropertyName )
         IF EMPTY( __objAddData( oObjectName, cPropertyName ) )
              RETURN .F.
         ENDIF
      ENDIF
      IF !EMPTY( eNewValue )
         IF VALTYPE( eNewValue ) = "B"
            oObjectName: & ( cPropertyName ) := EVAL( eNewValue )
         ELSE
            oObjectName: & ( cPropertyName ) := eNewValue
         ENDIF
      ENDIF
      RETURN .T.
   ENDIF
   RETURN .F.

FUNCTION REMOVEPROPERTY( oObjectName, cPropertyName )

   IF VALTYPE( oObjectName ) = "O" .AND. ! EMPTY( cPropertyName ) .AND.;
       __objHasData( oObjectName, cPropertyName )
       RETURN EMPTY( __objDelData( oObjectName, cPropertyName ) )
   ENDIF
   RETURN .F.

