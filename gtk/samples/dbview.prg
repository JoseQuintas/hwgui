/*
 *$Id: dbview.prg,v 1.1 2005-09-05 10:11:33 alkresin Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code: 
 * dbview.prg - dbf browsing sample
 *
 * Copyright 2005 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 */


#include "hwgui.ch"
#include "gtk.ch"

REQUEST HB_CODEPAGE_RU866
REQUEST HB_CODEPAGE_RUKOI8
REQUEST HB_CODEPAGE_RU1251

Function Main
Local oWndMain
Private oBrw, oFont := HFont():Add( "Times",0,12 ), DataCP
Memvar oBrw, oFont

   INIT WINDOW oWndMain MAIN TITLE "Dbf browse" AT 200,100 SIZE 300,300

   MENU OF oWndMain
     MENU TITLE "File"
       MENUITEM "Open" ACTION FileOpen()
       SEPARATOR
       MENUITEM "Список шрифтов" ACTION Wchoice(HWG_GP_FONTLIST(),"Fonts")
       SEPARATOR       
       MENUITEM "Exit" ACTION oWndMain:Close()
     ENDMENU
     MENU TITLE "View"
       MENUITEM "Font" ACTION ChangeFont()
       MENU TITLE "Local codepage"
          MENUITEMCHECK "EN" ACTION hb_SetCodepage( "EN" )
          MENUITEMCHECK "RUKOI8" ACTION hb_SetCodepage( "RUKOI8" )
          MENUITEMCHECK "RU1251" ACTION hb_SetCodepage( "RU1251" )
       ENDMENU
       MENU TITLE "Data's codepage"
          MENUITEMCHECK "EN" ACTION SetDataCP( "EN" )
          MENUITEMCHECK "RUKOI8" ACTION SetDataCP( "RUKOI8" )
          MENUITEMCHECK "RU1251" ACTION SetDataCP( "RU1251" )
          MENUITEMCHECK "RU866"  ACTION SetDataCP( "RU866" )
       ENDMENU
     ENDMENU
     MENU TITLE "Help"
       MENUITEM "About" ACTION MsgInfo("About")
     ENDMENU
   ENDMENU
   
   @ 0,0 BROWSE oBrw                 ;
      SIZE 300,300                   ;
      STYLE WS_VSCROLL + WS_HSCROLL  ;
      FONT oFont             ;
      ON SIZE {|o,x,y|o:Move(,,x-1,y-1)}
      
   oBrw:bScrollPos := {|o,n,lEof,nPos|VScrollPos(o,n,lEof,nPos)}


   ACTIVATE WINDOW oWndMain

Return Nil

Static Function FileOpen
Local mypath := "\" + CURDIR() + IIF( EMPTY( CURDIR() ), "", "\" )
Local fname := SelectFile( "xBase files( *.dbf )", "*.dbf", mypath )
Memvar oBrw, DataCP

   IF !Empty( fname )
      mypath := "\" + CURDIR() + IIF( EMPTY( CURDIR() ), "", "\" )
      close all
      
      IF DataCP != Nil
         use (fname) new codepage (DataCP)
      ELSE
         use (fname) new
      ENDIF
      
      oBrw:InitBrw( 2 )
      CreateList( oBrw,.T. )

   ENDIF
   
Return Nil

Static Function ChangeFont()
Local oBrwFont
Memvar oBrw, oFont

   IF ( oBrwFont := HFont():Select(oFont) ) != Nil

      oFont := oBrwFont
      oBrw:oFont := oFont
      oBrw:ReFresh()
   ENDIF
   
Return Nil

Static Function SetDataCP( cp )
Memvar DataCP

   DataCP := cp
Return Nil
