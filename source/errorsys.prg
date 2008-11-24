/*
 * $Id: errorsys.prg,v 1.11 2008-11-24 10:02:12 mlacecilia Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Windows errorsys replacement
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "common.ch"
#include "error.ch"
#include "windows.ch"
#include "guilib.ch"

STATIC LogInitialPath := ""

PROCEDURE ErrorSys

   ErrorBlock( { | oError | DefError( oError ) } )
   LogInitialPath := "\" + CurDir() + IIf( Empty( CurDir() ), "", "\" )

   RETURN

STATIC FUNCTION DefError( oError )
   LOCAL cMessage
   LOCAL cDOSError

   LOCAL n

   // By default, division by zero results in zero
   IF oError:genCode == EG_ZERODIV
      RETURN 0
   ENDIF

   // Set NetErr() of there was a database open error
   IF oError:genCode == EG_OPEN .AND. ;
      oError:osCode == 32 .AND. ;
      oError:canDefault
      NetErr( .T. )
      RETURN .F.
   ENDIF

   // Set NetErr() if there was a lock error on dbAppend()
   IF oError:genCode == EG_APPENDLOCK .AND. ;
      oError:canDefault
      NetErr( .T. )
      RETURN .F.
   ENDIF

   cMessage := ErrorMessage( oError )
   IF ! Empty( oError:osCode )
      cDOSError := "(DOS Error " + LTrim( Str( oError:osCode ) ) + ")"
   ENDIF

   IF ! Empty( oError:osCode )
      cMessage += " " + cDOSError
   ENDIF

   n := 2
   WHILE ! Empty( ProcName( n ) )
      #ifdef __XHARBOUR__
         cMessage += Chr( 13 ) + Chr( 10 ) + "Called from " + ProcFile( n ) + "->" + ProcName( n ) + "(" + AllTrim( Str( ProcLine( n ++ ) ) ) + ")"
      #else
         cMessage += Chr( 13 ) + Chr( 10 ) + "Called from " + ProcName( n ) + "(" + AllTrim( Str( ProcLine( n ++ ) ) ) + ")"
      #endif
   ENDDO

   //included aditional informations

   cMessage += Chr( 13 ) + Chr( 10 )

   cMessage += Chr( 13 ) + Chr( 10 ) + hwg_version( 1 )
   cMessage += Chr( 13 ) + Chr( 10 ) + "Date:" + DToC( Date() )
   cMessage += Chr( 13 ) + Chr( 10 ) + "Time:" + Time()


   MemoWrit( LogInitialPath + "Error.log", cMessage )

   ErrorPreview( cMessage )
   EndWindow()
   PostQuitMessage( 0 )

   RETURN .F.


FUNCTION ErrorMessage( oError )
   LOCAL cMessage

   // start error message
   cMessage := IIf( oError:severity > ES_WARNING, "Error", "Warning" ) + " "

   // add subsystem name if available
   IF ISCHARACTER( oError:subsystem )
      cMessage += oError:subsystem()
   ELSE
      cMessage += "???"
   ENDIF

   // add subsystem's error code if available
   IF ISNUMBER( oError:subCode )
      cMessage += "/" + LTrim( Str( oError:subCode ) )
   ELSE
      cMessage += "/???"
   ENDIF

   // add error description if available
   IF ISCHARACTER( oError:description )
      cMessage += "  " + oError:description
   ENDIF

   // add either filename or operation
   DO CASE
   CASE ! Empty( oError:filename )
      cMessage += ": " + oError:filename
   CASE ! Empty( oError:operation )
      cMessage += ": " + oError:operation
   ENDCASE

   /*
   IF ! Empty( oError:Args )
      cMessage += "Arguments: " + ValToPrgExp( oError:Args )
   ENDIF
   */

   RETURN cMessage

FUNCTION hwg_WriteLog( cText, fname )
   LOCAL nHand

   fname := LogInitialPath + IIf( fname == Nil, "a.log", fname )
   IF ! File( fname )
      nHand := FCreate( fname )
   ELSE
      nHand := FOpen( fname, 1 )
   ENDIF
   FSeek( nHand, 0, 2 )
   FWrite( nHand, cText + Chr( 10 ) )
   FClose( nHand )

   RETURN nil

STATIC FUNCTION ErrorPreview( cMess )
   LOCAL oDlg, oEdit

   INIT DIALOG oDlg TITLE "Error.log" ;
        At 92, 61 SIZE 500, 500

   @ 10, 10 EDITBOX oEdit CAPTION cMess SIZE 480, 440 STYLE WS_VSCROLL + WS_HSCROLL + ES_MULTILINE + ES_READONLY ;
      COLOR 16777088 BACKCOLOR 0 ;
      ON GETFOCUS { || SendMessage( oEdit:handle, EM_SETSEL, 0, 0 ) }

   @ 200, 460 BUTTON "Close" ON CLICK { || EndDialog() } SIZE 100, 32

   oDlg:Activate()
   RETURN Nil