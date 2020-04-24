/*
 *$Id$
 *
 * HWGUI - Harbour Win32 GUI and GTK library source code:
 * Misc functions
 *
 * This is a container for several useful functions.
 * Don't forget to add the desription in the function docu, if
 * a new function is added.
 * Try to make versions for WinAPI and GTK equal.
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 * Copyright 2020 Wilfried Brunken, DF7BE
*/
#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

FUNCTION hwg_isWindows()
#ifndef __PLATFORM__WINDOWS
 RETURN .F.
#else
 RETURN .T.
#endif


* ============== EOF of hmisc.prg ================= 