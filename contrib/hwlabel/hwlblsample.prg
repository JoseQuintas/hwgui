*
* hwlblsample.prg
*
*   $Id$
*
* HWGUI - Harbour Win32 and Linux (GTK) GUI library
*
* Label sample for HWGUI
*
* Copyright 2022 Wilfried Brunken, DF7BE 
* https://sourceforge.net/projects/cllog/
*
* License:
* GNU General Public License
* with special exceptions of HWGUI.
* See file "license.txt" for details of
* HWGUI project at
*  https://sourceforge.net/projects/hwgui/
*
* This is the port of a label feature of Clipper/Harbour to HWGUI.
*
* Codepages stored in label:
* Recent setting of codepage is IBM DE858.
* (OK for most european countries with Euro currency sign)
*
    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes 
    
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*  Supported languages:
*  - English
* * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



#include "hwgui.ch"
#ifdef __GTK__
#include "gtk.ch"
#endif
#ifdef __XHARBOUR__
   #include "ttable.ch"
#endif
#include "hbclass.ch"
#include "hwgextern.ch"

* ==== REQUESTs =====
* === for default code pages ===
#ifdef __LINUX__
* LINUX Codepage
* REQUEST HB_CODEPAGE_UTF8
REQUEST HB_CODEPAGE_UTF8EX
#endif

* Other languages

* ==== German ====
REQUEST HB_LANG_DE
* Windows codepage 
REQUEST HB_CODEPAGE_DEWIN
* For label with Euro currency sign
REQUEST HB_CODEPAGE_DE858

* If you got the following error:
* Error BASE/1302  Argument error: HB_TRANSLATE
* Called from ->HB_TRANSLATE(0)
* Called from hwlblsample.prg->HWLABEL_TRANSLCP2(430)
* ...
* then the needed REQUEST command is missing !

* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
* STATIC variables
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~

/*
* === NLS German ===
* Special signs german and Euro currency sign
*        AE      OE       UE       ae      oe       ue       sz  
  STATIC CAGUML, COGUML , CUGUML , CAKUML, COKUML , CUKUML , CSZUML , EURO
* Code for variable name
*        !----- C for char-Variable, fixed
*        !+---- A = AE , O = OE , U = UE , SZ = see above
*        !!+--- G = gross / upper case  K = klein / lower case
*        !!!+-- UML for "Umlaut"
*        !!!! 
*       CAGUML
*        !!
*        ++ "SZ" for ss (sharp "s", ss is not greek beta sign !!!)
* ==================
*
*/

*       Label file name
*       !
STATIC  lblname

MEMVAR EC

FIELD ACCOUNT

FUNCTION MAIN()

LOCAL olbleditsam , oFontMain
LOCAL cValicon , oIcon

PUBLIC EC 
 
SET PROCEDURE TO libhwlabel
* Alternative:
* - Add libhwlabel.prg into your *.hbp file
* or
* - Add libhwlabel.prg into your Makefile

* Settings

SET EXACT ON

SET DATE GERMAN  // DD.MM.YYYY also OK for Russian
SET CENTURY ON

READINSERT(.T.)


* Init

EC := CHR(27)

lblname := "customer"  && Pass label name "sample.lbl" without file extension (.lbl) .
                         && Setzen des Label-Dateinamens ohne Datei-Erweiterung (.lbl) .
* TO-DO for you:
* Ask user for label filename.
* Remove the file extension with
* FUNCTION hwlabel_REM_FILEEXT() 

cValicon     := hwg_cHex2Bin ( hwlbl_IconHex() )
oIcon        := HIcon():AddString( "hwlabel" , cValicon ) 

        INIT WINDOW olbleditsam MAIN TITLE "HWLABEL Test" ;
        ICON oIcon ;
        SIZE 300, 100

        MENU OF olbleditsam
         MENU TITLE "&File" 
             MENUITEM "&Quit"  ACTION {|| olbleditsam:Close() } 
         ENDMENU
         MENU TITLE "&Label" 
             MENUITEM "&Test" ACTION hwlabel_test() 
         ENDMENU
        ENDMENU

       ACTIVATE WINDOW olbleditsam
RETURN NIL




* Test routine (use it as template for your HWGUI application)
FUNCTION hwlabel_test(clangf,cCpLocWin,cCpLocLINUX,cCpLabel)

LOCAL ctempoutfile , ctempoutficv
LOCAL hihandle , cbuffer , lEOF , oWinPrn 

LOCAL nPrCharset , lpreview , lprbutton

LOCAL ctestfa := "O_PRTTXT(" + CHR(34) + "Test1" + CHR(34) + ")"

* Set to your own needs or by configuration dialog
nPrCharset := 1    && See include\prncharsets.ch for valid values
* Compile and run samples/winprn.prg to set a suitable printer character for your language
lpreview   := .T.
lprbutton  := .T.

* Open sample database

USE customer

* This is a good idea for debugging, to set a simple file name, so
* it is easy to open the files with a text editor
* In normal case, use
* hwg_CreateTempfileName() for creating a tempory file
* and don't forget, to erase them with
*  Erase &ctempoutfile
*  Erase &ctempoutficv 
* after processing.  

ctempoutfile := hwg_CreateTempfileName() + "1"
ctempoutficv := hwg_CreateTempfileName() 


* ctempoutfile := "lblprt.txt"
* ctempoutficv := "lblprt2.txt"

   LABEL FORM (lblname);
      TO FILE (ctempoutfile)    && .txt
*      RECORD RECNO() The default is "ALL"


* Translate the label output to local codepage (optional)
// hwlabel_transfi(ctempoutfile,ctempoutficv,cCpLocWin,cCpLocLINUX,cCpLabel)

* Read the translated file or the original file and start printing by using the HWINPRN class

* Open for read
 hihandle := hwlabel_OPENR(ctempoutfile)
  IF hihandle <  0
  * Leave, if error  
  RETURN NIL
 ENDIF 
 
 lEOF := .F.
 
 * Create HWINPRN object
#ifndef __PLATFORM__WINDOWS
   // oWinPrn := HWinPrn():New( ,"DE858","UTF8", , nPrCharset )
   O_NEW(,"DE858","UTF8", , nPrCharset)
   // oWinPrn:StartDoc( lpreview ,"temp_a2.ps", lprbutton )
   O_STD(lpreview ,"temp_a2.ps", lprbutton)
#else
   // oWinPrn := HWinPrn():New( ,"DE858","DEWIN", , nPrCharset)
   O_NEW( ,"DE858","DEWIN", , nPrCharset)
   // oWinPrn:StartDoc( lpreview ,"temp_a2.pdf" , lprbutton )
   O_STD( lpreview ,"temp_a2.pdf" , lprbutton )
#endif


* Store the HWinPrn object
// hwlabel_setO(oWinPrn)

// SMA()
 
 DO WHILE .NOT. lEOF 
 
  cbuffer := hwlabel_filerln(hihandle)
  IF cbuffer == ""
    lEOF := .T.
  ELSE
  * Remove CR line ending
   cbuffer := hwlabel_REM_CR(cbuffer)
   // hwg_xvalLog(cbuffer)  && Debug
   * Substitute 0 by macro for stroked 0 (optional)
   cbuffer :=  STRTRAN(cbuffer,"0", CHR(27) + "&STR0();")
   // hwg_xvalLog(cbuffer)  && Debug
   * Now the contents of buffer must be processed
   * with the macro interpreter
   // oWinPrn:PrintLine(ALLTRIM(cbuffer))
   hwlabel_macro(cbuffer)  && add second parameter .T. for debug output into log file a.log
  ENDIF  
ENDDO

* Test
// SET_VSM()
// oWinPrn:PrintLine("Very Small")

* Test by macro call : O_PRTTXT("Test1")
//  &ctestfa

// O_PRTTXT("Test2")
// O_NEWLINE()
// O_PRTTXT("Test3")
// O_PRTTXT("Test4") 

* At your opinion:
* for single sheet labels it is better,
* to eject the last sheet with this command.
* Ask for this in an own configuration dialog
// oWinPrn:NextPage()

* End printing (preview and start)
 O_END()
 
* Close file
FCLOSE(hihandle) 

 * Close the sample database
 USE

ERASE &ctempoutfile
ERASE &ctempoutficv 
  
RETURN NIL


FUNCTION CACC()
* Returns Strings for negative or positive value of ACCOUNT
* A good sample for usage of a user defined function in a
* label.
IF ACCOUNT < 0
 RETURN " debts "
ENDIF
IF ACCOUNT == 0
 RETURN " balanced "
ENDIF 
RETURN " credit " 

* ==================================== EOF of hwlblsample.prg ================================
