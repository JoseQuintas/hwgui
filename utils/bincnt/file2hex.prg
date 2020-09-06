*
* file2hex.prg
*
* $Id$
*
* HWGUI - Harbour Win32 GUI and GTK library source code:
*
* Utility to dump a (binary) file
* into text file *.hex.
* Purpose is, that a bin file
* is inserted in a prg source
* to compile it as binary object
* directly into an exe of an
* HWGUI program.
*
* Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
* www - http://www.kresin.ru
* Copyright 2020 Wilfried Brunken, DF7BE

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes

* Troubleshooting:
* Curdir() 
* returns path without leading directory separator and drive letter.
* Use hwg_CurDir() vor correct path value with
* drive letter. 

FUNCTION MAIN

LOCAL fname, hd, varbuf, ccdir

 ccdir := hwg_CompleteFullPath(hwg_CurDir() )
 fname := hwg_Selectfile("All files (*.*)" , "*.*", hwg_CurDir() )
 * Check for cancel 
 IF EMPTY(fname)
  QUIT
 ENDIF
 * Read selected file
 varbuf := MEMOREAD(fname)
 * Write Hexdump
 hd := hwg_HEX_DUMP(varbuf,2)
 MEMOWRIT(ccdir + "hexdump.txt",hd)
 
 IF .NOT. EMPTY(hd)
  hwg_MsgInfo("Hexdump of >" + fname + "< written to file" + CHR(10) + ;
  ">" + ccdir + "hexdump.txt<")
 ENDIF 

 * Test rewrite binary file 
 * HB_MEMOWRIT(ccdir + "test.bin",varbuf) 


RETURN NIL


* ============== EOF of file2hex.prg =================
