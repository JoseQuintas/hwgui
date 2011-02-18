/*
 * HWGUI using sample
 * 
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/

THIS IS A REGRESSION TEST FOR THE GET SYSTEM

WHEN and VALID should be called once and at the right moment both in
the Direct and Indirect way

*/

#include "windows.ch"
#include "guilib.ch"

FUNCTION Main
Local oMain

   INIT WINDOW oMain MAIN TITLE "Browse Example - Database" ;
     AT 0,0 ;
     SIZE GetDesktopWidth(), GetDesktopHeight() - 28

   MENU OF oMain
      MENUITEM "&Exit"     ACTION oMain:Close()
      MENUITEM "&Direct"   ACTION TestForm()
      MENUITEM "&Indirect" ACTION IndirectDialog()
   ENDMENU

   ACTIVATE WINDOW oMain

RETURN .T.

FUNCTION IndirectDialog
Local iDialog

   INIT DIALOG iDialog CLIPPER NOEXIT TITLE "Intermediate Dialog"  ;
     STYLE WS_VISIBLE + WS_POPUP + WS_CAPTION + WS_SYSMENU  ;
     AT 210,10  SIZE 300,300                    

   @ 20,35 BUTTON "Open form" ON CLICK {|| TestForm()  }

   ACTIVATE DIALOG iDialog


function TestForm()
Local cTitle := "Dialog from prg"
Local oModDlg, oFont := HFont():Add( "MS Sans Serif",0,-13 )
Local oRadio1, oRadio2, onome, ocodigo, wcodigo, wnome, wfracao
Local bInit

wfracao := 1
wcodigo := "XXXX"
wnome   := "Nome"

   bInit := {|o|MoveWindow(o:handle,x1,y1,nWidth,o:nHeight+1)}

   INIT DIALOG oModDlg CLIPPER NOEXIT TITLE cTitle           ;
     STYLE DS_CENTER + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU  ;
     AT 210,10  SIZE 300,300                    ;
     FONT oFont                                 ;
     ON EXIT {||MsgYesNo("Really exit ?")}

   @ 20,35 GET ocodigo VAR wcodigo PICTURE "@!" SIZE 100,22 ;
     NOBORDER STYLE ES_AUTOHSCROLL ;
     WHEN {|| msginfo("WHEN codigo"), .T.  } ;
     VALID {|| msginfo("VALID codigo"), .F.  }

   ACTIVATE DIALOG oModDlg

   oFont:Release()

Return Nil
