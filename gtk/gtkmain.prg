/*
 * $Id: gtkmain.prg,v 1.1 2005-01-12 11:56:33 alkresin Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Main prg level functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

Function EndWindow()
   IF HWindow():GetMain() != Nil
      HWindow():aWindows[1]:Close()
   ENDIF
Return Nil

FUNCTION WChoice()
Return Nil

INIT PROCEDURE GTKINIT()
   hwg_gtk_init()
Return

EXIT PROCEDURE GTKEXIT()
   hwg_gtk_exit()
Return
