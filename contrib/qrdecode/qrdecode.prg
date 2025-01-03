*
 * qrdecode.prg
 *
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 *
 * Sample program for QR decoding and
 * converts its output to ext
 *
 * The decoding from camera to text is done
 * by external open source program
 * "Zbar"
 * https://sourceforge.net/projects/zbar 
 *
 * Copyright 2024 Wilfried Brunken, DF7BE
 * https://sourceforge.net/projects/cllog/


    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  No
    *  GTK/MacOS:  Yes

#include "hwgui.ch"

FUNCTION Main()

   LOCAL oMainWindow, oButton1, oButton2

   INIT WINDOW oMainWindow MAIN TITLE "Decoding QR code" AT 168,50 SIZE 250,150

   @ 20,50 BUTTON oButton1 CAPTION "Scan" ;
      ON CLICK { || Testen() } ;
      SIZE 80,32

   @ 120,50 BUTTON oButton2 CAPTION "Quit";
      ON CLICK { || oMainWindow:Close } ;
      SIZE 80,32

   ACTIVATE WINDOW oMainWindow

RETURN Nil


* Starts the external program "ZBar"
* and reads the output file to
* display the decoded QR-Code
* in a messagebox.

FUNCTION Testen()

LOCAL rc, outfilename, ccommand, dtueddel
outfilename := "output.txt"
dtueddel := CHR(34)  && "

* Start the external app

#ifdef __PLATFORM__WINDOWS
  ccommand := dtueddel + "C:\Program Files (x86)\Zbar\bin\zbarcam.exe" + dtueddel
  rc := hwg_RunConsoleApp(ccommand,outfilename,.T.)
#else
  ccommand := "~/local/bin/zbarcam"
  rc := hwg_RunConsoleApp(ccommand,outfilename)
#endif

  * Now you can get the decoded text from output file 

RETURN Nil

 


* ===================== EOF of qrdecode.prg ==================
