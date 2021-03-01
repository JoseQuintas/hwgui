/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HWinPrn class - international printer charset settings
 *
 * Copyright 2020 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 * Created by DF7BE
*/
* Defines for the nCharSet values for Class HWinPrn 
* Table:   nCharSet, GDI Character-Sets (Font.GdiCharSet), Type = Byte
*          defined in wingdi.h, in numerical order.
*
* 0   : ANSI               CP1252, ansi-0, iso8859-{1,15}
* 1   : DEFAULT
* 2   : SYMBOL
* 77  : MAC
* 128 : SHIFTJIS           CP932
* 129 : HANGEUL            CP949, ksc5601.1987-0
*       HANGUL
* 130 : JOHAB              korean (johab) CP1361
* 134 : GB2312             CP936, gb2312.1980-0
* 136 : CHINESEBIG5        CP950, big5.et-0
* 161 : GREEK              CP1253
* 162 : TURKISH            CP1254, -iso8859-9
* 163 : VIETNAMESE         CP1258 
* 177 : HEBREW             CP1255, -iso8859-8
* 178 : ARABIC             CP1256, -iso8859-6
* 186 : BALTIC             CP1257, -iso8859-13
* 204 : RUSSIAN            CP1251, -iso8859-5
* 222 : THAI               CP874,  -iso8859-11
* 238 : EAST EUROPE        EE_CHARSET
* 255 : OEM
* 
* Sample see samples\winprn.prg
*
* #include "hwgui.ch"
* #include "prncharsets.ch"
* ...
* #ifdef CHARSET_RU
* * Initialize sequence for printer (Russian)
* #ifdef __PLATFORM__Linux__
*   oWinPrn := HWinPrn():New( ,"RU866","RUKOI8" , , PRN_CHARSET_RUSSIAN )
*   oWinPrn:StartDoc( .T.,"temp_a2.ps" )
* #else
*    oWinPrn := HWinPrn():New( ,"RU866","RU1251", , PRN_CHARSET_RUSSIAN )
*   
*   Hwg_MsgInfo("nCharset=" + STR(oWinPrn:nCharset),"Russian" )
* *   oWinPrn:StartDoc( .T. )
*    oWinPrn:StartDoc( .T.,"temp_a2.pdf" )
* #endif
* ...

#define PRN_CHARSET_ANSI          0         && CP1252, ansi-0, iso8859-{1,15}
#define PRN_CHARSET_DEFAULT       1    
#define PRN_CHARSET_SYMBOL        2    
#define PRN_CHARSET_MAC          77   
#define PRN_CHARSET_SHIFTJIS    128         && CP932
#define PRN_CHARSET_HANGEUL     129         && CP949, ksc5601.1987-0
#define PRN_CHARSET_HANGUL      129      
#define PRN_CHARSET_JOHAB       130         && korean (johab) CP1361
#define PRN_CHARSET_GB2312      134         && CP936, gb2312.1980-0
#define PRN_CHARSET_CHINESEBIG5 136         && CP950, big5.et-0
#define PRN_CHARSET_GREEK       161         && CP1253
#define PRN_CHARSET_TURKISH     162         && CP1254, -iso8859-9
#define PRN_CHARSET_VIETNAMESE  163         && CP1258 
#define PRN_CHARSET_HEBREW      177         && CP1255, -iso8859-8
#define PRN_CHARSET_ARABIC      178         && CP1256, -iso8859-6
#define PRN_CHARSET_BALTIC      186         && CP1257, -iso8859-13
#define PRN_CHARSET_RUSSIAN     204         && CP1251, -iso8859-5
#define PRN_CHARSET_THAI        222         && CP874,  -iso8859-11
#define PRN_CHARSET_EAST_EUROPE 238         && EE_CHARSET
#define PRN_CHARSET_OEM         255

* ================ EOF of prncharsets.ch =======