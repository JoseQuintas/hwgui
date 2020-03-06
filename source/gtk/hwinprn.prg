/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HWinPrn class
 *
 * Copyright 2005 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * Modified by DF7BE: New parameter "nCharset" for 
 * selecting international charachter sets
*/

#include "hwgui.ch"
#include "hbclass.ch"


#define   STD_HEIGHT      4

#define   MODE_NORMAL     0
#define   MODE_ELITE      1
#define   MODE_COND       2
#define   MODE_ELITECOND  3
#define   MODE_USER      10

CLASS HWinPrn

   CLASS VAR nStdHeight SHARED  INIT Nil
   CLASS VAR cPrinterName SHARED  INIT Nil
   DATA   oPrinter
   DATA   nFormType INIT 9
   DATA   oFont
   DATA   nLineHeight, nLined
   DATA   nCharW
   DATA   x, y
   DATA   cPseudo   INIT "ÄÍ³ºÚÉÕÖ¿»·¸ÀÈÓÔÙ¼½¾ÂËÑÒÁÊÏÐÃÌÆÇ´¹µ¶ÅÎ×Ø"
   DATA   lElite    INIT .F.
   DATA   lCond     INIT .F.
   DATA   nLineInch INIT 6
   DATA   lBold     INIT .F.
   DATA   lItalic   INIT .F.
   DATA   lUnder    INIT .F.
   DATA   nLineMax  INIT 0
   DATA   lChanged  INIT .F.

   DATA   cpFrom, cpTo
   DATA   nTop      INIT 5
   DATA   nBottom   INIT 5
   DATA   nLeft     INIT 5
   DATA   nRight    INIT 5
   
   DATA   nCharset  INIT 0   &&  Charset (N) Default: 0  , 204 = Russian


   METHOD New( cPrinter, cpFrom, cpTo, nFormType, nCharset )
   METHOD InitValues( lElite, lCond, nLineInch, lBold, lItalic, lUnder, nLineMax , nCharset )
   METHOD SetMode( lElite, lCond, nLineInch, lBold, lItalic, lUnder, nLineMax , nCharset )
   METHOD StartDoc( lPreview, cMetaName )
   METHOD NextPage()
   METHOD PrintLine( cLine, lNewLine )
   METHOD PrintText( cText )
   METHOD PutCode( cText )
   METHOD EndDoc()
   METHOD END()
#ifdef __GTK__
   METHOD SetMetaFile( cMetafile )    INLINE ::oPrinter:cScriptFile := cMetafile
#endif

   HIDDEN:
   DATA lDocStart   INIT .F.
   DATA lPageStart  INIT .F.
   DATA lFirstLine

ENDCLASS

METHOD New( cPrinter, cpFrom, cpTo, nFormType , nCharset ) CLASS HWinPrn

   ::oPrinter := HPrinter():New( cPrinter, .F., nFormType )
   IF ::oPrinter == Nil
      RETURN Nil
   ENDIF
   ::cpFrom := cpFrom
   ::cpTo   := cpTo
#ifdef __GTK__
   IF !Empty( cpTo )
      ::oPrinter:cdpIn := cpTo
   ENDIF
#endif
   IF nFormType != Nil
      ::nFormType := nFormType
   ENDIF
   
   IF nCharset != Nil
      :: nCharset := nCharset
   ENDIF

   RETURN Self

METHOD InitValues( lElite, lCond, nLineInch, lBold, lItalic, lUnder, nLineMax , nCharset ) CLASS HWinPrn

   IF lElite != Nil ; ::lElite := lElite ;  ENDIF
   IF lCond != Nil ; ::lCond := lCond ;  ENDIF
   IF nLineInch != Nil ; ::nLineInch := nLineInch ;  ENDIF
   IF lBold != Nil ; ::lBold := lBold ;  ENDIF
   IF lItalic != Nil ; ::lItalic := lItalic ;  ENDIF
   IF lUnder != Nil ; ::lUnder := lUnder ;  ENDIF
   IF nLineMax != Nil ; ::nLineMax := nLineMax ;  ENDIF
   IF nCharset != Nil ; ::nCharset := nCharset ;  ENDIF
   ::lChanged := .T.

   RETURN Nil

METHOD SetMode( lElite, lCond, nLineInch, lBold, lItalic, lUnder, nLineMax , nCharset) CLASS HWinPrn

#ifdef __GTK__
   LOCAL cFont := "monospace"
#else
   LOCAL cFont := "Lucida Console"
#endif
   LOCAL aKoef := { 1, 1.22, 1.71, 2 }
   LOCAL nMode := 0, oFont, nWidth, nPWidth, nStdHeight, nStdLineW

   ::InitValues( lElite, lCond, nLineInch, lBold, lItalic, lUnder, nLineMax , nCharset )

   IF ::lPageStart

      IF ::nStdHeight == Nil .OR. ::cPrinterName != ::oPrinter:cPrinterName
         ::nStdHeight := STD_HEIGHT
         ::cPrinterName := ::oPrinter:cPrinterName
         nPWidth := ::oPrinter:nWidth / ::oPrinter:nHRes - 10

         IF ::nFormType == 9 .AND. ( nPWidth > 210 .OR. nPWidth < 190 )
            nPWidth := 200
         ELSEIF ::nFormType == 8 .AND. ( nPWidth > 300 .OR. nPWidth < 280 )
            nPWidth := 290
         ENDIF
         
         oFont := ::oPrinter:AddFont( cFont, ::nStdHeight * ::oPrinter:nVRes )

         nWidth := ::oPrinter:GetTextWidth( Replicate( 'A', Iif( ::nFormType==8, 113, 80 ) ), oFont ) / ::oPrinter:nHRes
         IF nWidth > nPWidth + 2 .OR. nWidth < nPWidth - 15
            ::nStdHeight := ::nStdHeight * ( nPWidth / nWidth )
         ENDIF
         oFont:Release()
      ENDIF

      nStdLineW  := Iif( ::nFormType==8, Iif(::oPrinter:nOrient==2,160,113), Iif(::oPrinter:nOrient==2,113,80) )
      nStdHeight := Iif( !Empty(::nLineMax), ::nStdHeight / ( ::nLineMax/nStdLineW ), ::nStdHeight )
      IF ::lElite ; nMode ++ ; ENDIF
      IF ::lCond ; nMode += 2 ; ENDIF
      //hwg_writelog( "nStdHeight: "+Ltrim(str(::nStdHeight))+"/"+Ltrim(str(nStdHeight))+" ::nLineMax: "+Ltrim(str(::nLineMax))+"  nStdLineW: "+Ltrim(str(nStdLineW)) )

      ::nLineHeight := ( nStdHeight / aKoef[ nMode + 1 ] ) * ::oPrinter:nVRes
      ::nLined := ( 25.4 * ::oPrinter:nVRes ) / ::nLineInch - ::nLineHeight

      oFont := ::oPrinter:AddFont( cFont, ::nLineHeight, ::lBold, ::lItalic, ::lUnder, ::nCharset ) && ::nCharset 204 = Russian

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

   IF ! ::lDocStart
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

#ifdef __GTK__
   ::y := ::nTop * ::oPrinter:nVRes - ::nLineHeight + ::nLined
#else
   ::y := ::nTop * ::oPrinter:nVRes - ::nLineHeight - ::nLined
#endif
   ::lFirstLine := .T.

   RETURN Nil

METHOD PrintLine( cLine, lNewLine ) CLASS HWinPrn
   LOCAL i, i0, j, slen, c

   IF ! ::lDocStart
      ::StartDoc()
   ENDIF

#ifdef __GTK__
   IF ::y + 3 * ( ::nLineHeight + ::nLined ) > ::oPrinter:nHeight
#else
   IF ::y + 2 * ( ::nLineHeight + ::nLined ) > ::oPrinter:nHeight
#endif
      ::NextPage()
   ENDIF
   ::x := ::nLeft * ::oPrinter:nHRes
   IF ::lFirstLine
      ::lFirstLine := .F.
   ELSEIF lNewLine == Nil .OR. lNewLine
      ::y += ::nLineHeight + ::nLined
   ENDIF

   IF cLine != Nil .AND. ! Empty( cLine )
      slen := Len( cLine )
      i := 1
      i0 := 0
      DO WHILE i <= slen
         IF ( c := SubStr( cLine, i, 1 ) ) < " "
            IF i0 != 0
               ::PrintText( SubStr( cLine, i0, i - i0 ) )
               i0 := 0
            ENDIF
            i += ::PutCode( SubStr( cLine, i ) )
            LOOP
         ELSEIF ( j := At( c, ::cPseudo ) ) != 0
            IF i0 != 0
               ::PrintText( SubStr( cLine, i0, i - i0 ) )
               i0 := 0
            ENDIF
            IF j < 3            // Horisontal line ÄÍ
               i0 := i
               DO WHILE i <= slen .AND. SubStr( cLine, i, 1 ) == c
                  i ++
               ENDDO
               ::oPrinter:Line( ::x, ::y + ( ::nLineHeight / 2 ), ::x + ( i - i0 ) * ::nCharW, ::y + ( ::nLineHeight / 2 ) )
               ::x += ( i - i0 ) * ::nCharW
               i0 := 0
               LOOP
            ELSE
               IF j < 5         // Vertical Line ³º
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y, ::x + ( ::nCharW / 2 ), ::y + ::nLineHeight + ::nLined )
               ELSEIF j < 9     // ÚÉÕÖ
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ), ::x + ::nCharW, ::y + ( ::nLineHeight / 2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ), ::x + ( ::nCharW / 2 ), ::y + ::nLineHeight + ::nLined )
               ELSEIF j < 13    // ¿»·¸
                  ::oPrinter:Line( ::x, ::y + ( ::nLineHeight / 2 ), ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ), ::x + ( ::nCharW / 2 ), ::y + ::nLineHeight + ::nLined )
               ELSEIF j < 17    // ÀÈÓÔ
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ), ::x + ::nCharW, ::y + ( ::nLineHeight / 2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y, ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ) )
               ELSEIF j < 21    // Ù¼½¾
                  ::oPrinter:Line( ::x, ::y + ( ::nLineHeight / 2 ), ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y, ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ) )
               ELSEIF j < 25    // ÂËÑÒ
                  ::oPrinter:Line( ::x, ::y + ( ::nLineHeight / 2 ), ::x + ::nCharW, ::y + ( ::nLineHeight / 2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ), ::x + ( ::nCharW / 2 ), ::y + ::nLineHeight + ::nLined )
               ELSEIF j < 29    // ÁÊÏÐ
                  ::oPrinter:Line( ::x, ::y + ( ::nLineHeight / 2 ), ::x + ::nCharW, ::y + ( ::nLineHeight / 2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y, ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ) )
               ELSEIF j < 33    // ÃÌÆÇ
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ), ::x + ::nCharW, ::y + ( ::nLineHeight / 2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y, ::x + ( ::nCharW / 2 ), ::y + ::nLineHeight + ::nLined )
               ELSEIF j < 37    // ´¹µ¶
                  ::oPrinter:Line( ::x, ::y + ( ::nLineHeight / 2 ), ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y, ::x + ( ::nCharW / 2 ), ::y + ::nLineHeight + ::nLined )
               ELSE    // ÅÎ×Ø
                  ::oPrinter:Line( ::x, ::y + ( ::nLineHeight / 2 ), ::x + ::nCharW, ::y + ( ::nLineHeight / 2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y, ::x + ( ::nCharW / 2 ), ::y + ::nLineHeight + ::nLined )
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
         ::PrintText( SubStr( cLine, i0, i - i0 ) )
      ENDIF
   ENDIF

   RETURN Nil

METHOD PrintText( cText ) CLASS HWinPrn

   IF ::lChanged
      ::SetMode()
   ENDIF
   ::oPrinter:Say( IIf( ::cpFrom != ::cpTo, hb_Translate( cText, ::cpFrom, ::cpTo ), cText ), ;
         ::x, ::y, ::oPrinter:nWidth, ::y + ::nLineHeight + ::nLined )
   ::x += ( ::nCharW * Len( cText ) )

   RETURN Nil

METHOD PutCode( cLine ) CLASS HWinPrn
   STATIC aCodes := {   ;
          { Chr( 27 ) + '@', .f., .f., 6, .f., .f., .f. },  ;     /* Reset */
          { Chr( 27 ) + 'M', .t.,,,,, },  ;     /* Elite */
          { Chr( 15 ),, .t.,,,, },      ;     /* Cond */
          { Chr( 18 ),, .f.,,,, },      ;     /* Cancel Cond */
          { Chr( 27 ) + '0',,, 8,,, },    ;     /* 8 lines per inch */
          { Chr( 27 ) + '2',,, 6,,, },    ;     /* 6 lines per inch ( standard ) */
          { Chr( 27 ) + '-1',,,,,, .t. }, ;     /* underline */
          { Chr( 27 ) + '-0',,,,,, .f. }, ;     /* cancel underline */
          { Chr( 27 ) + '4',,,,, .t., },  ;     /* italic */
          { Chr( 27 ) + '5',,,,, .f., },  ;     /* cancel italic */
          { Chr( 27 ) + 'G',,,, .t.,, },  ;     /* bold */
          { Chr( 27 ) + 'H',,,, .f.,, }   ;     /* cancel bold */
        }
   LOCAL i, sLen := Len( aCodes ), c := Left( cLine, 1 )

   IF !Empty( c ) .AND. c < " "
      IF Asc( c ) == 31
         ::InitValues( ,,,,,, Asc(Substr(cLine,2,1)) )
         RETURN 2
      ELSE
         FOR i := 1 TO sLen
            IF Left( aCodes[ i, 1 ], 1 ) == c .AND. At( aCodes[ i, 1 ], Left( cLine, 3 ) ) == 1
               ::InitValues( aCodes[ i, 2 ], aCodes[ i, 3 ], aCodes[ i, 4 ], aCodes[ i, 5 ], aCodes[ i, 6 ], aCodes[ i, 7 ]  )
               RETURN Len( aCodes[ i, 1 ] )
            ENDIF
         NEXT
      ENDIF
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

METHOD END() CLASS HWinPrn

   ::EndDoc()
   ::oFont:Release()
   ::oPrinter:END()

   RETURN Nil
