/*
 * HWinPrn using sample
 * 
 *
 * Copyright 2005 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * Modified by DF7BE: New parameter "nCharset" for 
 * selecting international character sets
*/

#include "hwgui.ch"

* activate this for russian charset
* #define CHARSET_RU

* === Russian ===
REQUEST HB_CODEPAGE_RU866
#ifdef __LINUX__
REQUEST HB_CODEPAGE_RUKOI8
#else
REQUEST HB_CODEPAGE_RU1251
#endif

* === German ===
* Data Codepage (in DBFs)
REQUEST HB_CODEPAGE_DE850
* Windows codepage 
REQUEST HB_CODEPAGE_DEWIN

#ifdef __LINUX__
* LINUX Codepage
REQUEST HB_CODEPAGE_UTF8
#endif


Function Main
Local oWinPrn, i , j
LOCAL ctest1


#ifdef CHARSET_RU
* Initialize sequence for printer (Russiam)
#ifdef __PLATFORM__Linux__
   oWinPrn := HWinPrn():New( ,"RU866","RUKOI8" , , 204 )
   oWinPrn:StartDoc( .T.,"temp_a2.ps" )
#else
   oWinPrn := HWinPrn():New( ,"RU866","RU1251", , 204 )
   Hwg_MsgInfo("nCharset=" + STR(oWinPrn:nCharset),"Russian" )
*   oWinPrn:StartDoc( .T. )
    oWinPrn:StartDoc( .T.,"temp_a2.pdf" )
#endif

#else

* Initialize sequence for printer (German)

#ifdef __PLATFORM__Linux__
   oWinPrn := HWinPrn():New( ,"DE850","UTF8" )
   oWinPrn:StartDoc( .T.,"temp_a2.ps" )
#else
   oWinPrn := HWinPrn():New( ,"DE850","DEWIN")
*   oWinPrn:StartDoc( .T. )
    oWinPrn:StartDoc( .T.,"temp_a2.pdf" )
#endif

#endif

* Test German Umlaute and sharp "S"
   ctest1 := CHR(142) + CHR(153) + CHR(154) + CHR(132) + CHR(148) + CHR(129) + CHR(225)

  
  * print all chars over ASCII with decimal values
  FOR j := 128 TO 190
   oWinPrn:PrintLine(ALLTRIM(STR(j)) + ": " + CHR(j) )
  NEXT
  oWinPrn:NextPage()
  FOR j := 191 TO 255
   oWinPrn:PrintLine(ALLTRIM(STR(j)) + ": " + CHR(j) )
  NEXT
   oWinPrn:NextPage()
   
   oWinPrn:PrintLine( oWinPrn:oFont:name + " " + Str(oWinPrn:oFont:height) + " " + Str(oWinPrn:nCharW) + " " + Str(oWinPrn:nLineHeight) )
   oWinPrn:PrintLine( "A123456789012345678901234567890123456789012345678901234567890123456789012345678Z" )
/*
   oWinPrn:PrintLine( " ¡¢£¤¥¦§¨©ª«¬­®¯àáâãäåæçèéêëìíîï" )
   oWinPrn:PrintLine( "€‚ƒ„…†‡ˆ‰Š‹Œ‘’“”•–—˜™š›œŸ" )
*/

*  DOS  (dez / oct / hex) >> CP850, DE850
*  AE  = 142 / 216 / 8E
*  OE  = 153 / 231 / 99
*  UE  = 154 / 232 / 9A
*  ae  = 132 / 204 / 84
*  oe  = 148 / 224 / 94
*  ue  = 129 / 201 / 81
*  sz  = 225 / 341 / E1
*
*  Windows (ungefaehr ISO8859-1) "WIN1252"
*  WIN     (dez / oct / hex)
*
*  AE  = 196 / 304 / C4
*  OE  = 214 / 326 / D6
*  UE  = 220 / 334 / DC
*  ae  = 228 / 344 / E4
*  oe  = 246 / 366 / F6
*  ue  = 252 / 374 / FC
*  sz  = 223 / 337 / DF
*

   oWinPrn:PrintLine(ctest1)
 
   oWinPrn:PrintLine( "abcdefghijklmnopqrstuvwxyz" )
   oWinPrn:PrintLine( "ABCDEFGHIJKLMNOPQRSTUVWXYZ" )
   oWinPrn:PrintLine( "ÚÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿" )
   oWinPrn:PrintLine( "³   129.54³           0.00³" )
   oWinPrn:PrintLine( "ÃÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´" )
   oWinPrn:PrintLine( "³    17.88³      961014.21³" )
   oWinPrn:PrintLine( "ÀÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ" )
   oWinPrn:PrintLine()
   oWinPrn:PrintLine( "ÚÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿" )
   oWinPrn:PrintLine( "ÀÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ" )

   oWinPrn:PrintLine()
   oWinPrn:PrintLine()

   oWinPrn:SetMode( .T. )
   oWinPrn:PrintLine( "A12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678Z" )
   oWinPrn:PrintLine( "A123456789012345678901234567890123456789012345678901234567890123456789012345678Z" )
   oWinPrn:PrintLine()
   oWinPrn:PrintLine()

   oWinPrn:SetMode( .F.,.T. )
   oWinPrn:PrintLine( "A12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678Z" )
   oWinPrn:PrintLine( "A123456789012345678901234567890123456789012345678901234567890123456789012345678Z" )
   oWinPrn:PrintLine()
   oWinPrn:PrintLine()

   oWinPrn:SetMode( .T.,.T. )
   oWinPrn:PrintLine( "A12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678Z" )
   oWinPrn:PrintLine( "A123456789012345678901234567890123456789012345678901234567890123456789012345678Z" )

   oWinPrn:SetMode( .F.,.F. )
   oWinPrn:NextPage()
   oWinPrn:PrintLine( oWinPrn:oFont:name + " " + Str(oWinPrn:oFont:height) + " " + Str(oWinPrn:nCharW) + " " + Str(oWinPrn:nLineHeight) )
   FOR i := 1 TO 80
      oWinPrn:PrintLine( Padl( i,3 ) + " --------" )
   NEXT

   oWinPrn:End()

Return Nil

* ======================================================================
