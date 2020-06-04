/*
 *
 * testfunc.prg
 *
 * Test program sample for displaying images and usage of FreeImage library.
 * 
 * $Id$
 *
 * Copyright 2005 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * Copyright 2020 Itamar M. Lins Jr. Junior (TNX)
 * See ticket #43 
 
*/
   * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes 
    *  GTK/Win  :  No (crashes)


#include "hwgui.ch"

function main
local odlg
LOCAL nameimg := "..\image\astro.bmp"

INIT Dialog oDlg AT 0,0 SIZE 500,400 CLIPPER NOEXIT NOEXITESC
* This command requires FreeImage
*@ 30, 10 IMAGE oSayMain SHOW nameimg OF oDlg SIZE 100, 90
* Supported formats: bmp, jpg 
@ 30, 10 BITMAP oSayMain SHOW nameimg OF oDlg SIZE 100, 90

ACTIVATE Dialog oDlg center
return nil

* ================ EOF of testimage.prg ===========================
