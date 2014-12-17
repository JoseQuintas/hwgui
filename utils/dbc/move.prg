/*
 * $Id$
 * DBCHW - DBC ( Harbour + HWGUI )
 * Move functions ( Locate, seek, ... )
 *
 * Copyright 2001 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "guilib.ch"
#include "dbchw.h"
#ifdef RDD_ADS
#include "ads.ch"
#endif

Memvar oMainFont, improc, aFiles

STATIC cLocate := "", cFilter := "", cSeek := ""

FUNCTION Move( nMove )
   LOCAL oDlg, aTitle := { "Locate", "Seek", "Filter", "Go to" }, aSay := { "locate expression", "seek key", "filter expression", "record number" }
   LOCAL cExpr := "", oBrw, nRec, key

   IF Empty( oBrw := GetBrwActive() )
      RETURN Nil
   ENDIF

   INIT DIALOG oDlg TITLE aTitle[nMove] ;
      AT 0, 0 SIZE 400, 140 FONT oMainFont

   IF nMove == 1
      cExpr := cLocate
   ELSEIF nMove == 2
      cExpr := cSeek
   ELSEIF nMove == 3
      cExpr := cFilter
   ENDIF

   @ 10, 10 SAY "Input " + aSay[nMove] SIZE 140, 22
   @ 10, 32 GET cExpr SIZE 380, 24
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @  30, 90  BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 270, 90 BUTTON "Cancel" SIZE 100, 32 ON CLICK { ||hwg_EndDialog() }

   oDlg:Activate()

   IF oDlg:lResult

      IF nMove == 1
         F_Locate( oBrw, cExpr )
      ELSEIF nMove == 2
         cSeek := cExpr
         nrec := RecNo()
         IF Type( OrdKey() ) == "N"
            key := Val( cExpr )
         ELSEIF Type( OrdKey() ) = "D"
            key := CToD( Trim( cExpr ) )
         ELSE
            key := cExpr
         ENDIF
         SEEK KEY
         IF !Found()
            GO nrec
            hwg_Msgstop( "Record not found" )
         ELSE
            hwg_WriteStatus( oBrw:oParent, 3, "Found" )
         ENDIF
      ELSEIF nMove == 3
         F_Filter( oBrw, cExpr )
      ELSEIF nMove == 4
         IF ( nrec := Val( cExpr ) ) != 0
            GO nrec
         ENDIF
      ENDIF
      UpdBrowse()

   ENDIF

   RETURN Nil

FUNCTION F_Locate( oBrw, cExpres )
   LOCAL nrec, i, res, block

   cLocate := cExpres
   IF ValType( &cLocate ) == "L"
      nrec := RecNo()
      block := &( "{||" + cLocate + "}" )
      IF aFiles[ improc,AF_LFLT ]
         Fgotop( oBrw )
         DO WHILE !Feof( oBrw )
            IF Eval( block )
               res := .T.
               EXIT
            ENDIF
            Fskip( oBrw, 1 )
         ENDDO
      ELSE
         __dbLocate( block, , , , .F. )
      ENDIF
      IF ( aFiles[ improc,AF_LFLT ] .AND. !res ) .OR. ( !aFiles[ improc,AF_LFLT ] .AND. !Found() )
         GO nrec
         hwg_Msgstop( "Record not found" )
      ELSE
         hwg_WriteStatus( HMainWindow():GetMdiActive(), 3, "Found" )
         IF aFiles[ improc,AF_LFLT ]
            oBrw:nCurrent := i
         ENDIF
      ENDIF
      UpdBrowse()
   ELSE
      hwg_Msginfo( "Wrong expression" )
   ENDIF

   RETURN Nil

FUNCTION F_Filter( oBrw, cExpres )
   LOCAL i, nrec, cArr, lRes := .F.

   cFilter := cExpres
   IF !Empty( cFilter ) .AND. !( Type( cFilter ) $ "UEUI" )
      IF ValType( &cFilter ) == "L"
         nrec := RecNo()
         dbSetFilter( &( "{||" + cFilter + "}" ), cFilter )

         GO TOP
         oBrw:nRecords := 0
         cArr := carr_Init( cArr, 512 )
         DO WHILE !Eof()
            oBrw:nRecords ++
            carr_Put( @cArr, Recno(), oBrw:nRecords )
            SKIP
         ENDDO

         IF oBrw:nRecords > 0
            oBrw:aArray := cArr
            Fgotop( oBrw )
            aFiles[ improc,AF_LFLT ] := .T.
            oBrw:bSkip :=  {|o,x| (o:alias)->(fSkip(o,x))}
            oBrw:bGoTop := {|o|   (o:alias)->(fGotop(o))}
            oBrw:bGoBot := {|o|   (o:alias)->(fGobot(o))}
            oBrw:bGoto :=  {|o,x| (o:alias)->(fGoto(o,x))}
            oBrw:bEof  :=  {|o| FEof(o) }
            oBrw:bBof  :=  {|o| FBof(o) }
            oBrw:bRecno := {|o| o:nCurrent }
            hwg_WriteStatus( HMainWindow():GetMdiActive(), 1, LTrim( Str(oBrw:nRecords,10 ) ) + " records filtered" )
            lRes := .T.
         ELSE
            GO nrec
            hwg_Msginfo( "Records not found" )
         ENDIF
         UpdBrowse()
      ELSE
         hwg_Msginfo( "Wrong expression" )
      ENDIF
   ENDIF
   IF !lRes
      oBrw:aArray := Nil
      aFiles[ improc,AF_LFLT ] := .F.
      SET FILTER TO
      oBrw:bSkip  := {|o,x|(o:alias)->(dbSkip(x))}
      oBrw:bGoTop := {|o|  (o:alias)->(dbGotop())}
      oBrw:bGoBot := {|o|  (o:alias)->(dbGobottom())}
      oBrw:bEof   := {|o|  (o:alias)->(Eof())}
      oBrw:bBof   := {|o|  (o:alias)->(Bof())}
      oBrw:bGoTo  := {|o,n|(o:alias)->(dbGoto(n) ) }
      oBrw:bRecno := {|o|  (o:alias)->(RecNo()) }     
      hwg_WriteStatus( HMainWindow():GetMdiActive(), 1, LTrim( Str(RecCount(),10 ) ) + " records" )
   ENDIF

   RETURN Nil

FUNCTION FGOTOP( oBrw )

   IF oBrw:nRecords > 0
      oBrw:nCurrent := 1
      GO carr_Get( oBrw:aArray, 1 )
   ENDIF
RETURN Nil

FUNCTION FGOBOT( oBrw )

   oBrw:nCurrent := oBrw:nRecords
   GO carr_Get( oBrw:aArray, oBrw:nRecords )
RETURN Nil

FUNCTION FGOTO( oBrw, nRec )

   IF oBrw:nRecords >= nRec .AND. nRec > 0
      oBrw:nCurrent := nRec
      GO carr_Get( oBrw:aArray, nRec )
   ENDIF
RETURN Nil

PROCEDURE FSKIP( oBrw, kolskip )

LOCAL tekzp1

   IF oBrw:nRecords == 0
      RETURN
   ENDIF
   tekzp1 := oBrw:nCurrent
   oBrw:nCurrent += kolskip + Iif( tekzp1 = 0, 1, 0 )
   IF oBrw:nCurrent < 1
      oBrw:nCurrent := 0
      GO carr_Get( oBrw:aArray, 1 )

   ELSEIF oBrw:nCurrent > oBrw:nRecords
      oBrw:nCurrent := oBrw:nRecords + 1
      GO carr_Get( oBrw:aArray, oBrw:nRecords )

   ELSE
      GO carr_Get( oBrw:aArray, oBrw:nCurrent )
   ENDIF
RETURN

FUNCTION FBof( oBrw )
RETURN ( oBrw:nCurrent == 0 )

FUNCTION FEof( oBrw )
RETURN ( oBrw:nCurrent > oBrw:nRecords )
