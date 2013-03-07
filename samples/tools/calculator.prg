/*
 * $Id: calculator.prg
 *
 * HWGUI - Harbour Win32 GUI library
 *
 * Sample
 *
*/


#Include "hwgui.ch"
STATIC Thisform

Function Main ()

   INIT WINDOW oMain MAIN TITLE "Calculator Sample" ;
      AT 0,0 ;
      SIZE hwg_Getdesktopwidth() - 100, hwg_Getdesktopheight() - 78

      MENU OF oMain
         MENUITEM "&Exit" ACTION oMain:Close()
         MENUITEM "&Demo" ACTION Calculator()
      ENDMENU

   ACTIVATE WINDOW oMain

Return Nil

FUNCTION calculator( )

  LOCAL oDlg,  oGroup1, oBtn1, oOw1, oValue, oLabel1

  LOCAL  vValue := 0


  INIT DIALOG oDlg TITLE "Calculando" ;
    AT 0, 0 SIZE 415,325 ;
        FONT HFont():Add( 'Verdana',0,-13,400,,,) CLIPPER  NOEXIT  ;
     STYLE WS_POPUP+WS_CAPTION+WS_SYSMENU+WS_SIZEBOX+DS_CENTER
    Thisform := oDlg

   @ 272,63 OWNERBUTTON oOw1  SIZE 106,36   ;
        TEXT 'Calculator'  ;
        COORDINATES 3, 0, 0, 0  ;
        ON CLICK {|| oOw1_onClick(  ) }
   @ 72,102 SAY oLabel2 CAPTION "F2 - activate calculator"  SIZE 235,26 ;
        STYLE SS_CENTER +DT_VCENTER+DT_SINGLELINE+WS_DLGFRAME +WS_DISABLED
   @ 119,71 GET UPDOWN oValue VAR vValue  ;
        RANGE -2147483647,2147483647  INCREMENT 1 SIZE 149,24  PICTURE '999,999.99'  ;
        VALID  {|| thisform:oLabel2:disable( ) } ;
        WHEN  {|| thisform:oLabel2:Enable( ) } ;
        ON KEYDOWN {|This, nKeyPress, nShiftAltCtrl| oValue_onKeyDown( This, nKeyPress, nShiftAltCtrl ) }
        hwg_SetFontStyle( oValue, .T. )   // oValue:FontBold := .T.
   @ 72,74 SAY oLabel1 CAPTION "Value:"  SIZE 42,21

   @ 22,30 GROUPBOX oGroup1 CAPTION "Calculator"  SIZE 368,106 ;
        STYLE BS_LEFT
   @ 297,271 BUTTONEX oBtn1 CAPTION "OK"   SIZE 100,42 ;
        STYLE BS_CENTER +WS_TABSTOP  ;
        ON CLICK {|| thisform:Close( ) }

   ACTIVATE DIALOG oDlg


RETURN oDlg:lresult

STATIC FUNCTION oOw1_onClick
   LOCAL ocalc
   oCalc := HCalculator():New('Calculator')
   oCalc:Show()
 RETURN .T.


STATIC FUNCTION oValue_onKeyDown( This, nKeyPress, nShiftAltCtrl )

   LOCAL oCalc
   IF nKeyPress = VK_F2
      oCalc := HCalculator():New()
      oCalc:Show( This, .T. )
   ENDIF
   RETURN .T.


