/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HWinPrn class
 *
 * Copyright 2005 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * Modifications by DF7BE:
 * - New parameter "nCharset" for 
 *   selecting international charachter sets
 *   Data and methods for National Language Support
 *
 * - New method SetDefaultMode():
 *   should act like a "printer reset"
 *   (Set back to default values).
 *
 * - Recovered METHOD PrintBitmap
 *   (Ticket #64, TNX HKrzak)
*/

/*
  Some notes how to explain the work flow of the
  HWINPRN class:
  Every method adding lines or settings into the document to print  
  collect records in an Array aPages[] initialized by method New() of HPRINTER class.
  These methods are for example:
  SetMode(), PrintLine(), PrintBitmap(), NextPage().
  When running method End() of HWINPRN class to close the print job,
  all collected records in the array
  are written in a script file with default filename "temp_a2.ps". 
  This script builds the complete layout of the printing job in background.
  After this, the layout is diplayed in the print preview dialag, the last step
  is send the data to the printer device.

  Sample for the page 7 created by sample program "winprn.prg":
   page,7,px,p
   fnt,monospace,12.2410,400,0,0,
   txt,14.16,-0.3156,589,11.6812,,From file >hwgui.bmp<
   img,14.16,11.6812,315.16,171.6812,,../../image/hwgui.bmp
   txt,14.16,183.6780,589,195.6749,,astro from hex value via temporary file
   img,14.16,195.6749,121.16,285.6749,,/tmp/e5950039.bmp
   img,248.16,297.6717,355.16,387.6717,,/tmp/e5950039.bmp
   img,482.16,399.6685,589.16,489.6685,,/tmp/e5950039.bmp
   txt,14.16,501.6654,589,513.6622,,--------------------

   The record secription (not valid for all types):
   <type>,<x1>,<y1>,<x2>,<y2>,nOpt,<value> CRLF

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

   // --- International Language Support for internal dialogs --
   DATA aTooltips   INIT {}  // Array with tooltips messages for print preview dialog
   DATA aBootUser   INIT {}  // Array with control  messages for print preview dialog  (optional usage)
   

   METHOD New( cPrinter, cpFrom, cpTo, nFormType, nCharset )
   METHOD SetLanguage(apTooltips, apBootUser)
   METHOD InitValues( lElite, lCond, nLineInch, lBold, lItalic, lUnder, nLineMax , nCharset )
   METHOD SetMode( lElite, lCond, nLineInch, lBold, lItalic, lUnder, nLineMax , nCharset )
   METHOD SetDefaultMode()
   METHOD StartDoc( lPreview, cMetaName )
   METHOD NextPage()
   METHOD PrintLine( cLine, lNewLine )
   METHOD PrintBitmap( xBitmap, nAlign , cImageName )
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

   ::SetLanguage() // Start with default english

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


METHOD SetLanguage(apTooltips, apBootUser) CLASS HWinPrn
* NLS: Sets the message and control texts to print preview dialog
* Are stored in arrays:   ::aTooltips[], ::aBootUser[]

* Default settings (English)
  ::aTooltips := hwg_HPrinter_LangArray_EN()
* Overwrite default, if array with own language served 
   IF apTooltips != NIL ; ::aTooltips := apTooltips ; ENDIF
/* Activate, if necessary */   
//   IF apBootUser != NIL ; ::aBootUser := apBootUser ; ENDIF  
RETURN Nil

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

/*
  Added by DF7BE:
  Should act like a "printer reset"
  (Set back to default values).
*/   
METHOD SetDefaultMode() CLASS HWinPrn

   ::SetMode( .F., .F. , 6, .F. , .F. , .F. , 0 , 0 )

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

   
/*
   DF7BE:
   Recovered from r2536 2016-06-16
   added support for bitmap object

   xBitmap     : Name and path to bitmap file 
                 or bitmap object variable
   nAlign      : 0 - left, 1 - center, 2 - right, default = 0
   cBitmapName  : Name of resource, if xBitmap is bitmap object
 */   
METHOD PrintBitmap( xBitmap, nAlign , cBitmapName ) CLASS HWinPrn

   LOCAL i , cTmp , bfromobj
   LOCAL oBitmap, hBitmap, aBmpSize , cImageName

   IF ! ::lDocStart
      ::StartDoc()
   ENDIF
   
   IF nAlign == NIL
     nAlign := 0  // 0 - left, 1 - center, 2 - right
   ENDIF

   bfromobj := .F.

   cTmp := hwg_CreateTempfileName( , ".bmp")   
   
   // IF VALTYPE( xBitmap ) == "C" && does not work on GTK
 
     IF ! hb_fileexists( xBitmap )
      * xBitmap is a bitmap object
      bfromobj := .T.
      cImageName := IIF(EMPTY (cBitmapName), "" , cBitmapName)
      * Store into a temporary file
      /* DF7BE:
        Bug in GTK: gdk_pixbuf_save(pixbuff,handle,"bmp",&error,cFile,contents_encode,NULL)
        set the value of printer resolution (pixels per meter) to zero.
        For example: astro.bmp
        Offsets / values
        26 / c4 0e
        2a / c4 0e = 3780 dec.
        New function OBMP2FILE2( cTmp , cImageName ) saves the bmp object
        correct to file.    
      */
      xBitmap:OBMP2FILE( cTmp , cImageName , "bmp" )
      hBitmap := hwg_Openbitmap( cTmp , ::oPrinter:hDC )
      // hwg_msginfo(hb_valtostr(hBitmap))
      IF hb_ValToStr(hBitmap) == "0x00000000"
        RETURN NIL
      ENDIF
      aBmpSize  := hwg_Getbitmapsize( hBitmap )
      cImageName := IIF(EMPTY (cBitmapName), xBitmap, cBitmapName)
      // FERASE(cTmp)
     ELSE
      * from file 
      hBitmap := hwg_Openbitmap( xBitmap, ::oPrinter:hDC )
      // hwg_msginfo(hb_valtostr(hBitmap))
      IF hb_ValToStr(hBitmap) == "0x00000000"
        RETURN NIL
      ENDIF  
      cImageName := IIF(EMPTY (cBitmapName), xBitmap, cBitmapName)
      //  aBmpSize[1] = width(x) aBmpSize[2] = height(y)
      aBmpSize  := hwg_Getbitmapsize( hBitmap )
   ENDIF  
  
/* Page size overflow  ? ==> next page */ 
#ifdef __GTK__
   IF ::y + aBmpSize[2] + ::nLined > ::oPrinter:nHeight
#else
   IF ::y + aBmpSize[2] + ::nLined > ::oPrinter:nHeight
#endif
      ::NextPage()
   ENDIF
   
   ::x := ::nLeft * ::oPrinter:nHRes
   ::y += ::nLineHeight + ::nLined

   IF nAlign == 1 .AND. ::x + aBmpSize[1] < ::oPrinter:nWidth 
     ::x += ROUND( (::oPrinter:nWidth - ::x - aBmpSize[1] ) / 2, 0)
  * HKrzak 2020-10-27 
   ELSEIF nAlign == 2
     ::x += ROUND( (::oPrinter:nWidth - ::x - aBmpSize[1]), 0) 
   ENDIF
   IF ::lFirstLine
      ::lFirstLine := .F.
   ENDIF
   * Paint bitmap
   // hwg_msginfo(STR(::x) + CHR(10) + STR(::y) + CHR(10) + STR(aBmpSize[1]) + CHR(10) +  STR(aBmpSize[2]) )

   IF bfromobj
   /* from object: need to read from temporary file */
    ::oPrinter:Bitmap( ::x, ::y, ::x + aBmpSize[1], ::y + aBmpSize[2],, hBitmap, cTmp )
    FERASE(cTmp)
   ELSE
    ::oPrinter:Bitmap( ::x, ::y, ::x + aBmpSize[1], ::y + aBmpSize[2],, hBitmap, cImageName )
   ENDIF 
   /* Height of bitmap, increase Y value */    
   i := aBmpSize[2]   &&   - ::nLineHeight  ==> DF7BE: not the correct size of bitmap !
   IF i > 0
       ::Y +=  i 
   ENDIF

   // hwg_WriteLog(STR(::x) + CHR(10) + STR(::y) + CHR(10) ;
   // + STR(aBmpSize[1]) + CHR(10) +  STR(aBmpSize[2]) + CHR(10) +  STR(i) )

  RETURN Nil

   
METHOD PrintLine( cLine, lNewLine ) CLASS HWinPrn
   LOCAL i, i0, j, slen, c

   IF ! ::lDocStart
      ::StartDoc()
   ENDIF

   IF lNewLine == Nil
     lNewLine := .T.
   ENDIF
   
* HKrzak.Start 2020-10-25
* Bug Ticket #64
IF cLine != Nil .AND. VALTYPE(cLine) == "N"
     ::y += ::nLineHeight * cLine
     IF ::y < 0
       ::y := 0
     ENDIF
   ENDIF
* HKrzak.End   


#ifdef __GTK__
   IF ::y + 3 * ( ::nLineHeight + ::nLined ) > ::oPrinter:nHeight
#else
   IF ::y + 2 * ( ::nLineHeight + ::nLined ) > ::oPrinter:nHeight
#endif
      ::NextPage()
   ENDIF

* HKrzak.Start 2020-10-25
* Bug Ticket #64
   IF cLine != Nil .AND. VALTYPE(cLine) == "N"
     RETURN NIL
   ENDIF
* HKrzak.End

   ::x := ::nLeft * ::oPrinter:nHRes
   IF ::lFirstLine
      ::lFirstLine := .F.
   ELSEIF lNewLine 
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
       // hwg_writelog(STR(::x) + CHR(10) + STR(::y) + CHR(10) + STR(i0) + CHR(10) + STR(i) + ;
       //  CHR(10) + STR(::nLineHeight) )
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
         ::oPrinter:Preview( , , ::aTooltips,)
      ENDIF
   ENDIF

   RETURN Nil

METHOD END() CLASS HWinPrn

   ::EndDoc()
   ::oFont:Release()
   ::oPrinter:END()

   RETURN Nil
   
* ================================ EOF of hwinprn.prg ==========================   
