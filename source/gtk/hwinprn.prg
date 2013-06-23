/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HWinPrn class
 *
 * Copyright 2005 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hbclass.ch"


#define   STD_HEIGHT      4

#define   MODE_NORMAL     0
#define   MODE_ELITE      1
#define   MODE_COND       2
#define   MODE_ELITECOND  3
#define   MODE_USER      10

STATIC cPseudoChar := "ÄÍ³ºÚÉÕÖ¿»·¸ÀÈÓÔÙ¼½¾ÂËÑÒÁÊÏÐÃÌÆÇ´¹µ¶ÅÎ×Ø"

CLASS HWinPrn

   CLASS VAR nStdHeight SHARED  INIT Nil
   CLASS VAR cPrinterName SHARED  INIT Nil
   DATA   oPrinter
   DATA   oFont
   DATA   nLineHeight, nLined
   DATA   nCharW
   DATA   x, y
   DATA   lElite    INIT .F.
   DATA   lCond     INIT .F.
   DATA   nLineInch INIT 6
   DATA   lBold     INIT .F.
   DATA   lItalic   INIT .F.
   DATA   lUnder    INIT .F.
   DATA   lChanged  INIT .F.

   DATA   cpFrom, cpTo
   DATA   nTop      INIT 5
   DATA   nBottom   INIT 5
   DATA   nLeft     INIT 5
   DATA   nRight    INIT 5


   METHOD New( cPrinter, cpFrom, cpTo )
   METHOD InitValues( lElite, lCond, nLineInch, lBold, lItalic, lUnder  )
   METHOD SetMode( lElite, lCond, nLineInch, lBold, lItalic, lUnder )
   METHOD StartDoc( lPreview, cMetaName )
   METHOD NextPage()
   METHOD PrintLine( cLine, lNewLine )
   METHOD PrintText( cText )
   METHOD PutCode( cText )
   METHOD EndDoc()
   METHOD End()
   METHOD SetMetaFile( cMetafile )    INLINE ::oPrinter:cMetafile := cMetafile

   HIDDEN:
   DATA lDocStart   INIT .F.
   DATA lPageStart  INIT .F.
   DATA lFirstLine

ENDCLASS

METHOD New( cPrinter, cpFrom, cpTo ) CLASS HWinPrn

   ::oPrinter := HPrinter():New( cPrinter, .F. )
   IF ::oPrinter == Nil
      RETURN Nil
   ENDIF
   ::cpFrom := cpFrom
   ::cpTo   := cpTo
   IF !Empty( cpTo )
      ::oPrinter:cdpIn := cpTo
   ENDIF

   RETURN Self

METHOD InitValues( lElite, lCond, nLineInch, lBold, lItalic, lUnder ) CLASS HWinPrn

   IF lElite != Nil; ::lElite := lElite;  ENDIF
   IF lCond != Nil; ::lCond := lCond;  ENDIF
   IF nLineInch != Nil; ::nLineInch := nLineInch;  ENDIF
   IF lBold != Nil; ::lBold := lBold;  ENDIF
   IF lItalic != Nil; ::lItalic := lItalic;  ENDIF
   IF lUnder != Nil; ::lUnder := lUnder;  ENDIF
   ::lChanged := .T.

   RETURN Nil

METHOD SetMode( lElite, lCond, nLineInch, lBold, lItalic, lUnder ) CLASS HWinPrn

#ifdef __GTK__
   LOCAL cFont := "monospace"
#else
   LOCAL cFont := "Lucida Console"
#endif
   LOCAL aKoef := { 1, 1.22, 1.71, 2 }
   LOCAL nMode := 0, oFont, nWidth, nPWidth

   ::InitValues( lElite, lCond, nLineInch, lBold, lItalic, lUnder  )

   IF ::lPageStart

      IF ::nStdHeight == Nil .OR. ::cPrinterName != ::oPrinter:cPrinterName
         ::nStdHeight := STD_HEIGHT
         ::cPrinterName := ::oPrinter:cPrinterName
         nPWidth := ::oPrinter:nWidth / ::oPrinter:nHRes - 10
         IF nPWidth > 210 .OR. nPWidth < 190
            nPWidth := 200
         ENDIF
         oFont := ::oPrinter:AddFont( cFont, ::nStdHeight * ::oPrinter:nVRes )

         nWidth := ::oPrinter:GetTextWidth( Replicate( 'A',83 ), oFont ) / ::oPrinter:nHRes
         IF nWidth > nPWidth + 2 .OR. nWidth < nPWidth - 15
            ::nStdHeight := ::nStdHeight * ( nPWidth / nWidth )
         ENDIF
         oFont:Release()
      ENDIF

      IF ::lElite; nMode ++ ; ENDIF
      IF ::lCond; nMode += 2; ENDIF

      ::nLineHeight := ( ::nStdHeight / aKoef[nMode+1] ) * ::oPrinter:nVRes
      ::nLined := ( 25.4 * ::oPrinter:nVRes ) / ::nLineInch - ::nLineHeight

      oFont := ::oPrinter:AddFont( cFont, ::nLineHeight, ::lBold, ::lItalic, ::lUnder, 204 )

      IF ::oFont != Nil
         ::oFont:Release()
      ENDIF
      ::oFont := oFont

      ::oPrinter:SetFont( ::oFont )
      ::nCharW := ::oPrinter:GetTextWidth( "ABCDEFGHIJ", oFont ) / 10
      ::lChanged := .F.

   ENDIF

   RETURN Nil

METHOD StartDoc( lPreview, cMetaName ) CLASS HWinPrn

   ::lDocStart := .T.
   ::oPrinter:StartDoc( lPreview, cMetaName )
   ::NextPage()

   RETURN Nil

METHOD NextPage() CLASS HWinPrn

   IF !::lDocStart
      RETURN Nil
   ENDIF
   IF ::lPageStart
      ::oPrinter:EndPage()
   ENDIF

   ::lPageStart := .T.
   ::oPrinter:StartPage()

   IF ::oFont == Nil
      ::SetMode()
   ELSE
      ::oPrinter:SetFont( ::oFont )
   ENDIF

   ::y := ::nTop * ::oPrinter:nVRes - ::nLineHeight + ::nLined
   ::lFirstLine := .T.

   RETURN Nil

METHOD PrintLine( cLine, lNewLine ) CLASS HWinPrn
   LOCAL i, i0, j, slen, c

   IF !::lDocStart
      ::StartDoc()
   ENDIF

   IF ::y + 3 * ( ::nLineHeight + ::nLined ) > ::oPrinter:nHeight
      ::NextPage()
   ENDIF
   ::x := ::nLeft * ::oPrinter:nHRes
   IF ::lFirstLine
      ::lFirstLine := .F.
   ELSEIF lNewLine == Nil .OR. lNewLine
      ::y += ::nLineHeight + ::nLined
   ENDIF

   IF cLine != Nil .AND. !Empty( cLine )
      slen := Len( cLine )
      i := 1
      i0 := 0
      DO WHILE i <= slen
         IF ( c := SubStr( cLine,i,1 ) ) < " "
            IF i0 != 0
               ::PrintText( SubStr( cLine,i0,i - i0 ) )
               i0 := 0
            ENDIF
            i += ::PutCode( SubStr( cLine,i ) )
            LOOP
         ELSEIF ( j := At( c,cPseudoChar ) ) != 0
            IF i0 != 0
               ::PrintText( SubStr( cLine,i0,i - i0 ) )
               i0 := 0
            ENDIF
            IF j < 3            // Horisontal line ÄÍ
               i0 := i
               DO WHILE i <= slen .AND. SubStr( cLine, i, 1 ) == c
                  i ++
               ENDDO
               ::oPrinter:Line( ::x, ::y + ( ::nLineHeight/2 ), ::x + ( i - i0 ) * ::nCharW, ::y + ( ::nLineHeight/2 ) )
               ::x += ( i - i0 ) * ::nCharW
               i0 := 0
               LOOP
            ELSE
               IF j < 5         // Vertical Line ³º
                  ::oPrinter:Line( ::x + ( ::nCharW/2 ), ::y, ::x + ( ::nCharW/2 ), ::y + ::nLineHeight + ::nLined )
               ELSEIF j < 9     // ÚÉÕÖ
                  ::oPrinter:Line( ::x + ( ::nCharW/2 ), ::y + ( ::nLineHeight/2 ), ::x + ::nCharW, ::y + ( ::nLineHeight/2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW/2 ), ::y + ( ::nLineHeight/2 ), ::x + ( ::nCharW/2 ), ::y + ::nLineHeight + ::nLined )
               ELSEIF j < 13    // ¿»·¸
                  ::oPrinter:Line( ::x, ::y + ( ::nLineHeight/2 ), ::x + ( ::nCharW/2 ), ::y + ( ::nLineHeight/2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW/2 ), ::y + ( ::nLineHeight/2 ), ::x + ( ::nCharW/2 ), ::y + ::nLineHeight + ::nLined )
               ELSEIF j < 17    // ÀÈÓÔ
                  ::oPrinter:Line( ::x + ( ::nCharW/2 ), ::y + ( ::nLineHeight/2 ), ::x + ::nCharW, ::y + ( ::nLineHeight/2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW/2 ), ::y, ::x + ( ::nCharW/2 ), ::y + ( ::nLineHeight/2 ) )
               ELSEIF j < 21    // Ù¼½¾
                  ::oPrinter:Line( ::x, ::y + ( ::nLineHeight/2 ), ::x + ( ::nCharW/2 ), ::y + ( ::nLineHeight/2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW/2 ), ::y, ::x + ( ::nCharW/2 ), ::y + ( ::nLineHeight/2 ) )
               ELSEIF j < 25    // ÂËÑÒ
                  ::oPrinter:Line( ::x, ::y + ( ::nLineHeight/2 ), ::x + ::nCharW, ::y + ( ::nLineHeight/2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW/2 ), ::y + ( ::nLineHeight/2 ), ::x + ( ::nCharW/2 ), ::y + ::nLineHeight + ::nLined )
               ELSEIF j < 29    // ÁÊÏÐ
                  ::oPrinter:Line( ::x, ::y + ( ::nLineHeight/2 ), ::x + ::nCharW, ::y + ( ::nLineHeight/2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW/2 ), ::y, ::x + ( ::nCharW/2 ), ::y + ( ::nLineHeight/2 ) )
               ELSEIF j < 33    // ÃÌÆÇ
                  ::oPrinter:Line( ::x + ( ::nCharW/2 ), ::y + ( ::nLineHeight/2 ), ::x + ::nCharW, ::y + ( ::nLineHeight/2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW/2 ), ::y, ::x + ( ::nCharW/2 ), ::y + ::nLineHeight + ::nLined )
               ELSEIF j < 37    // ´¹µ¶
                  ::oPrinter:Line( ::x, ::y + ( ::nLineHeight/2 ), ::x + ( ::nCharW/2 ), ::y + ( ::nLineHeight/2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW/2 ), ::y, ::x + ( ::nCharW/2 ), ::y + ::nLineHeight + ::nLined )
               ELSE    // ÅÎ×Ø
                  ::oPrinter:Line( ::x, ::y + ( ::nLineHeight/2 ), ::x + ::nCharW, ::y + ( ::nLineHeight/2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW/2 ), ::y, ::x + ( ::nCharW/2 ), ::y + ::nLineHeight + ::nLined )
               ENDIF
               ::x += ::nCharW
            ENDIF
         ELSE
            IF i0 == 0
               i0 := i
            ENDIF
         ENDIF
         i ++
      ENDDO
      IF i0 != 0
         ::PrintText( SubStr( cLine,i0,i - i0 ) )
      ENDIF
   ENDIF

   RETURN Nil

METHOD PrintText( cText ) CLASS HWinPrn

   IF ::lChanged
      ::SetMode()
   ENDIF
   ::oPrinter:Say( iif( ::cpFrom != ::cpTo, hb_Translate( cText,::cpFrom,::cpTo ), cText ), ;
      ::x, ::y, ::oPrinter:nWidth, ::y + ::nLineHeight + ::nLined )
   ::x += ( ::nCharW * Len( cText ) )

   RETURN Nil

METHOD PutCode( cLine ) CLASS HWinPrn
   STATIC aCodes := {   ;
   { Chr( 27 ) + '@', .F. , .F. , 6, .F. , .F. , .F. },  ;     /* Reset */
   { Chr( 27 ) + 'M', .T. , , , , , },  ;     /* Elite */
   { Chr( 15 ), , .T. , , , , },      ;     /* Cond */
   { Chr( 18 ), , .F. , , , , },      ;     /* Cancel Cond */
   { Chr( 27 ) + '0', , , 8, , , },    ;     /* 8 lines per inch */
   { Chr( 27 ) + '2', , , 6, , , },    ;     /* 6 lines per inch ( standard ) */
   { Chr( 27 ) + '-1', , , , , , .T. }, ;     /* underline */
   { Chr( 27 ) + '-0', , , , , , .F. }, ;     /* cancel underline */
   { Chr( 27 ) + '4', , , , , .T. , },  ;     /* italic */
   { Chr( 27 ) + '5', , , , , .F. , },  ;     /* cancel italic */
   { Chr( 27 ) + 'G', , , , .T. , , },   ;     /* bold */
   { Chr( 27 ) + 'H', , , , .F. , , }   ;     /* cancel bold */
   }
   LOCAL i, sLen := Len( aCodes ), c := Left( cLine, 1 )

   IF !Empty( c ) .AND. Asc( cLine ) < 32
      FOR i := 1 TO sLen
         IF Left( aCodes[i,1], 1 ) == c .AND. At( aCodes[i,1], Left( cLine,3 ) ) == 1
            ::InitValues( aCodes[i,2], aCodes[i,3], aCodes[i,4], aCodes[i,5], aCodes[i,6], aCodes[i,7]  )
            RETURN Len( aCodes[i,1] )
         ENDIF
      NEXT
   ENDIF

   RETURN 1

METHOD EndDoc() CLASS HWinPrn

   IF ::lPageStart
      ::oPrinter:EndPage()
      ::lPageStart := .F.
   ENDIF
   IF ::lDocStart
      ::oPrinter:EndDoc()
      ::lDocStart := .F.
      IF __ObjHasMsg( ::oPrinter, "PREVIEW" ) .AND. ::oPrinter:lPreview
         ::oPrinter:Preview()
      ENDIF
   ENDIF

   RETURN Nil

METHOD End() CLASS HWinPrn

   ::EndDoc()
   ::oFont:Release()
   ::oPrinter:End()

   RETURN Nil
