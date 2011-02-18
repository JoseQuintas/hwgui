/*
 * DBCHW - DBC ( Harbour + HWGUI )
 * Move functions ( Locate, seek, ... )
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "guilib.ch"
#include "dbchw.h"
#ifdef RDD_ADS
#include "ads.ch"
#endif

Static cLocate := "", cFilter := "", cSeek := ""
Static klrecf := 200

Function Move( nMove )
Local aModDlg

   INIT DIALOG aModDlg FROM RESOURCE "DLG_MOVE" ON INIT {|| InitMove( nMove ) }
   DIALOG ACTIONS OF aModDlg ;
        ON 0,IDOK         ACTION {|| EndMove(.T., nMove)}   ;
        ON 0,IDCANCEL     ACTION {|| EndMove(.F., nMove) }
   aModDlg:Activate()

Return Nil

Static Function InitMove( nMove )
Local hDlg := getmodalhandle(), cTitle
   WriteStatus( HMainWindow():GetMdiActive(),3,"" )
   IF nMove == 1
      cTitle := "Input locate expression"
      SetDlgItemText( hDlg, IDC_EDIT6, cLocate )
   ELSEIF nMove == 2
      cTitle := "Input seek string"
      SetDlgItemText( hDlg, IDC_EDIT6, cSeek )
   ELSEIF nMove == 3
      cTitle := "Input filter expression"
      SetDlgItemText( hDlg, IDC_EDIT6, cFilter )
   ELSEIF nMove == 4
      cTitle := "Input record number"
   ENDIF
   SetDlgItemText( hDlg, IDC_TEXTHEAD, cTitle )
   SetFocus( GetDlgItem( hDlg, IDC_EDIT6 ) )
Return Nil

Static Function EndMove( lOk, nMove )
Local hDlg := getmodalhandle()
Local cExpres, nrec, key
Local hWnd, oWindow, aControls, iCont

   IF lOk
      cExpres := GetDlgItemText( hDlg, IDC_EDIT6, 80 )
      IF Empty( cExpres )
         SetFocus( GetDlgItem( hDlg, IDC_EDIT6 ) )
         Return Nil
      ENDIF

      oWindow := HMainWindow():GetMdiActive()
      IF oWindow != Nil
         aControls := oWindow:aControls
         iCont := Ascan( aControls, {|o|o:classname()=="HBROWSE"} )
      ENDIF
      IF nMove == 1
         F_Locate( aControls[iCont], cExpres )
      ELSEIF nMove == 2
         cSeek := cExpres
         nrec := RECNO()
         IF TYPE( ORDKEY() ) == "N"
            key := VAL( cSeek )
         ELSEIF TYPE( ORDKEY() ) = "D"
            key := CTOD( Trim( cSeek ) )
         ELSE
            key := cSeek
         ENDIF
         SEEK key
         IF .NOT. FOUND()
            GO nrec
            MsgStop( "Record not found" )
         ELSE
            WriteStatus( oWindow,3,"Found" )
         ENDIF
      ELSEIF nMove == 3
         F_Filter( aControls[iCont], cExpres )
      ELSEIF nMove == 4
         IF ( nrec := VAL( cExpres ) ) != 0
            GO nrec
         ENDIF
      ENDIF

      IF iCont > 0
         RedrawWindow( aControls[iCont]:handle, RDW_ERASE + RDW_INVALIDATE )
      ENDIF
   ENDIF

   EndDialog( hDlg )
Return Nil

Function F_Locate( oBrw, cExpres )
Local nrec, i, res, block
   cLocate := cExpres
   IF VALTYPE( &cLocate ) == "L"
      nrec := RECNO()
      block := &( "{||" + cLocate + "}" )
      IF oBrw:prflt
         FOR i := 1 TO Min( oBrw:nRecords,klrecf-1 )
            GO oBrw:aArray[ i ]
            IF Eval( block )
               res := .T.
               EXIT
            ENDIF
         NEXT
         IF !res .AND. i < oBrw:nRecords
            SKIP
            DO WHILE !Eof()
               IF Eval( block )
                  res := .T.
                  EXIT
               ENDIF
               i ++
               SKIP
            ENDDO
         ENDIF
      ELSE
         __dbLocate( block,,,, .F. )
      ENDIF
      IF ( oBrw:prflt .AND. !res ) .OR. ( !oBrw:prflt .AND. .NOT. FOUND() )
         GO nrec
         MsgStop( "Record not found" )
      ELSE
         WriteStatus( HMainWindow():GetMdiActive(),3,"Found" )
         IF oBrw:prflt
            oBrw:nCurrent := i
         ENDIF
      ENDIF
   ELSE
      MsgInfo( "Wrong expression" )
   ENDIF
Return Nil

Function F_Filter( oBrw, cExpres )
Local i, nrec
   cFilter := cExpres
   IF VALTYPE( &cFilter ) == "L"
      nrec := RECNO()
      dbSetFilter( &( "{||"+ cFilter + "}" ), cFilter )
      GO TOP
      i       := 1
      oBrw:nRecords := 0
      IF oBrw:aArray == Nil
         oBrw:aArray := Array( klrecf )
      ENDIF
      DO WHILE .NOT. EOF()
         oBrw:aArray[ i ] = RECNO()
         IF i < klrecf
            i ++
         ENDIF
         oBrw:nRecords ++
         IF INKEY() = 27
            oBrw:nRecords := 0
            EXIT
         ENDIF
         SKIP
      ENDDO
      oBrw:nCurrent := 1
      IF oBrw:nRecords > 0
         GO oBrw:aArray[ 1 ]
         oBrw:prflt := .T.
         oBrw:bSkip := &( "{|o,x|" + oBrw:alias + "->(FSKIP(o,x))}" )
         oBrw:bGoTop:= &( "{|o|" + oBrw:alias + "->(FGOTOP(o))}" )
         oBrw:bGoBot:= &( "{|o|" + oBrw:alias + "->(FGOBOT(o))}")
         oBrw:bEof  := &( "{|o|" + oBrw:alias + "->(FEOF(o))}" )
         oBrw:bBof  := &( "{|o|" + oBrw:alias + "->(FBOF(o))}" )
         WriteStatus( HMainWindow():GetMdiActive(),1,Ltrim(Str(oBrw:nRecords,10))+" records filtered" )
      ELSE
         oBrw:prflt := .F.
         SET FILTER TO
         GO nrec
         oBrw:bSkip := &( "{|a,x|" + oBrw:alias + "->(DBSKIP(x))}" )
         oBrw:bGoTop:= &( "{||" + oBrw:alias + "->(DBGOTOP())}" )
         oBrw:bGoBot:= &( "{||" + oBrw:alias + "->(DBGOBOTTOM())}")
         oBrw:bEof  := &( "{||" + oBrw:alias + "->(EOF())}" )
         oBrw:bBof  := &( "{||" + oBrw:alias + "->(BOF())}" )
         MsgInfo( "Records not found" )
         WriteStatus( HMainWindow():GetMdiActive(),1,Ltrim(Str(Reccount(),10))+" records" )
      ENDIF
   ELSE
      MsgInfo( "Wrong expression" )
   ENDIF
Return Nil

FUNCTION FGOTOP( oBrw )
   IF oBrw:nRecords > 0
      oBrw:nCurrent := 1
      GO oBrw:aArray[ 1 ]
   ENDIF
RETURN Nil

FUNCTION FGOBOT( oBrw )
   oBrw:nCurrent := oBrw:nRecords
   GO IIF( oBrw:nRecords < klrecf, oBrw:aArray[ oBrw:nRecords ], oBrw:aArray[ klrecf ] )
RETURN Nil

PROCEDURE FSKIP( oBrw, kolskip )
LOCAL tekzp1
   IF oBrw:nRecords = 0
      RETURN
   ENDIF
   tekzp1   := oBrw:nCurrent
   oBrw:nCurrent := oBrw:nCurrent + kolskip + IIF( tekzp1 = 0, 1, 0 )
   IF oBrw:nCurrent < 1
      oBrw:nCurrent := 0
      GO oBrw:aArray[ 1 ]
   ELSEIF oBrw:nCurrent > oBrw:nRecords
      oBrw:nCurrent := oBrw:nRecords + 1
      GO IIF( oBrw:nRecords < klrecf, oBrw:aArray[ oBrw:nRecords ], oBrw:aArray[ klrecf ] )
   ELSE
      IF oBrw:nCurrent > klrecf - 1
         SKIP IIF( tekzp1 = oBrw:nRecords + 1, kolskip + 1, kolskip )
      ELSE
         GO oBrw:aArray[ oBrw:nCurrent ]
      ENDIF
   ENDIF
RETURN

FUNCTION FBOF( oBrw )
RETURN IIF( oBrw:nCurrent = 0, .T., .F. )

FUNCTION FEOF( oBrw )
RETURN IIF( oBrw:nCurrent > oBrw:nRecords, .T., .F. )
