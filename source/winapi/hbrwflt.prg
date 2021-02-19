/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HBrwFlt class - browse filtered databases
 *
 * Copyright 2016 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * Code provided by By Luiz Henrique dos Santos (luizhsantos@gmail.com)
*/

#include "hwgui.ch"
#include "hbclass.ch"

CLASS HBrwflt INHERIT HBrowse

   DATA lDescend INIT .F.              // Descend Order?
   DATA lFilter INIT .F.               // Filtered? (atribuition is automatic in method "New()").
   DATA bFirst INIT { || DBGOTOP() }     // Block to place pointer in first record of condition filter. (Ex.: DbGoTop(), DbSeek(), etc.).
   DATA bLast  INIT { || dbGoBottom() }  // Block to place pointer in last record of condition filter. (Ex.: DbGoBottom(), DbSeek(), etc.).
   DATA bWhile INIT { || .T. }           // Clausule "while". Return logical.
   DATA bFor INIT { || .T. }             // Clausule "for". Return logical.
   DATA nLastRecordFilter INIT 0       // Save the last record of filter.
   DATA nFirstRecordFilter INIT 0      // Save the first record of filter.

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, bPaint, bEnter, bGfocus, bLfocus, lNoVScroll, ;
      lNoBorder, lAppend, lAutoedit, bUpdate, bKeyDown, bPosChg, lMultiSelect, ;
      lDescend, bWhile, bFirst, bLast, bFor, bRClick )

   METHOD InitBrw()
   METHOD Refresh( lFull )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, bPaint, bEnter, bGfocus, bLfocus, lNoVScroll, ;
      lNoBorder, lAppend, lAutoedit, bUpdate, bKeyDown, bPosChg, lMultiSelect, ;
      lDescend, bWhile, bFirst, bLast, bFor, bRClick ) CLASS HBrwflt

   ::lDescend := Iif( lDescend == Nil, .F. , lDescend )

   IF HB_ISBLOCK( bFirst ) .OR. HB_ISBLOCK( bFor ) .OR. HB_ISBLOCK( bWhile )
      ::lFilter := .T.
      IF HB_ISBLOCK( bFirst )
         ::bFirst  := bFirst
      ENDIF
      IF HB_ISBLOCK( bLast )
         ::bLast   := bLast
      ENDIF
      IF HB_ISBLOCK( bWhile )
         ::bWhile  := bWhile
      ENDIF
      IF HB_ISBLOCK( bFor )
         ::bFor    := bFor
      ENDIF
   ELSE
      ::lFilter := .F.
   ENDIF

   RETURN ::Super:New( BRW_DATABASE, oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, bPaint, bEnter, bGfocus, bLfocus, lNoVScroll, lNoBorder, ;
      lAppend, lAutoedit, bUpdate, bKeyDown, bPosChg, lMultiSelect, bRClick )

METHOD InitBrw()  CLASS HBrwFlt

   ::Super:InitBrw()

   IF ::lFilter
      ::nLastRecordFilter  := ::nFirstRecordFilter := 0
      IF ::lDescend
         ::bSkip     := { |o, n| ( ::alias ) -> ( FltSkip( o, n, .T. ) ) }
         ::bGoTop    := { |o| ( ::alias ) -> ( FltGoBottom( o ) ) }
         ::bGoBot    := { |o| ( ::alias ) -> ( FltGoTop( o ) ) }
         ::bEof      := { |o| ( ::alias ) -> ( FltBOF( o ) ) }
         ::bBof      := { |o| ( ::alias ) -> ( FltEOF( o ) ) }
      ELSE
         ::bSkip     := { |o, n| ( ::alias ) -> ( FltSkip( o, n, .F. ) ) }
         ::bGoTop    := { |o| ( ::alias ) -> ( FltGoTop( o ) ) }
         ::bGoBot    := { |o| ( ::alias ) -> ( FltGoBottom( o ) ) }
         ::bEof      := { |o| ( ::alias ) -> ( FltEOF( o ) ) }
         ::bBof      := { |o| ( ::alias ) -> ( FltBOF( o ) ) }
      ENDIF
      ::bRcou     := { |o| ( ::alias ) -> ( FltRecCount( o ) ) }
      ::bRecnoLog := ::bRecno := { |o| ( ::alias ) -> ( FltRecNo( o ) ) }
      ::bGoTo     := { |o, n|( ::alias ) -> ( FltGoTo( o, n ) ) }
   ENDIF

   RETURN Nil

METHOD Refresh( lFull ) CLASS HBrwFlt

   IF lFull == Nil .OR. lFull
      IF ::lFilter
         ::nLastRecordFilter := 0
         ::nFirstRecordFilter := 0
         FltGoTop( Self )
      ENDIF
   ENDIF

   RETURN ::Super:Refresh( lFull )

STATIC FUNCTION FltSkip( oBrw, nLines, lDesc )

   LOCAL n

   IF nLines == NIL
      nLines := 1
   ENDIF
   IF lDesc == NIL
      lDesc := .F.
   ENDIF
   IF nLines > 0
      FOR n := 1 TO nLines
         SKIP IF( lDesc, - 1, + 1 )
         WHILE ! Eof() .AND. Eval( oBrw:bWhile ) .AND. ! Eval( oBrw:bFor )
            SKIP IF( lDesc, - 1, + 1 )
         ENDDO
      NEXT
   ELSEIF nLines < 0
      FOR n := 1 TO ( nLines * ( - 1 ) )
         IF Eof()
            IF lDesc
               FltGoTop( oBrw )
            ELSE
               FltGoBottom( oBrw )
            ENDIF
         ELSE
            SKIP IF( lDesc, + 1, - 1 )
         ENDIF
         WHILE ! Bof() .AND. Eval( oBrw:bWhile ) .AND. ! Eval( oBrw:bFor )
            SKIP IF( lDesc, + 1, - 1 )
         ENDDO
      NEXT
   ENDIF

   RETURN NIL

STATIC FUNCTION FltGoTop( oBrw )

   IF oBrw:nFirstRecordFilter == 0
      Eval( oBrw:bFirst )
      IF ! Eof()
         WHILE ! Eof() .AND. ! ( Eval( oBrw:bWhile ) .AND. Eval( oBrw:bFor ) )
            dbSkip()
         ENDDO
         oBrw:nFirstRecordFilter := FltRecNo( oBrw )
      ELSE
         oBrw:nFirstRecordFilter := 0
      ENDIF
   ELSE
      FltGoTo( oBrw, oBrw:nFirstRecordFilter )
   ENDIF

   RETURN NIL

STATIC FUNCTION FltGoBottom( oBrw )

   IF oBrw:nLastRecordFilter == 0
      Eval( oBrw:bLast )
      IF ! Eval( oBrw:bWhile ) .OR. ! Eval( oBrw:bFor )
         WHILE ! Bof() .AND. ! Eval( oBrw:bWhile )
            dbSkip( - 1 )
         ENDDO
         WHILE ! Bof() .AND. Eval( oBrw:bWhile ) .AND. ! Eval( oBrw:bFor )
            dbSkip( - 1 )
         ENDDO
      ENDIF
      oBrw:nLastRecordFilter := FltRecNo( oBrw )
   ELSE
      FltGoTo( oBrw, oBrw:nLastRecordFilter )
   ENDIF

   RETURN NIL

STATIC FUNCTION FltBOF( oBrw )

   LOCAL lRet := .F. , nRecord
   LOCAL xValue, xFirstValue

   IF Bof()
      lRet := .T.
   ELSE
      // cKey  := IndexKey()
      nRecord := FltRecNo( oBrw )

      xValue := OrdKeyNo() //&(cKey)

      FltGoTop( oBrw )
      xFirstValue := OrdKeyNo()//&(cKey)

      IF xValue < xFirstValue
         lRet := .T.
         FltGoTop( oBrw )
      ELSE
         FltGoTo( oBrw, nRecord )
      ENDIF
   ENDIF

   RETURN lRet

STATIC FUNCTION FltEOF( oBrw )

   LOCAL lRet := .F. , nRecord
   LOCAL xValue, xLastValue

   IF Eof()
      lRet := .T.
   ELSE
      // cKey := IndexKey()
      nRecord := FltRecNo( oBrw )

      xValue := OrdKeyNo()

      FltGoBottom( oBrw )
      xLastValue := OrdKeyNo()

      IF xValue > xLastValue
         lRet := .T.
         FltGoBottom( oBrw )
         dbSkip()
      ELSE
         FltGoTo( oBrw, nRecord )
      ENDIF
   ENDIF

   RETURN lRet

STATIC FUNCTION FltRecCount( oBrw )

   LOCAL nRecord, nCount := 0

   nRecord := FltRecNo( oBrw )
   FltGoTop( oBrw )
   WHILE ! Eof() .AND. Eval( oBrw:bWhile )
      IF Eval( oBrw:bFor )
         nCount ++
      ENDIF
      dbSkip()
   ENDDO
   FltGoTo( oBrw, nRecord )

   RETURN nCount

STATIC FUNCTION FltGoTo( oBrw, nRecord )

   HB_SYMBOL_UNUSED(oBrw)

   RETURN dbGoto( nRecord )

STATIC FUNCTION FltRecNo( oBrw )

   HB_SYMBOL_UNUSED(oBrw)

   RETURN RecNo()

