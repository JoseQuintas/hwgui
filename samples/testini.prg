/*
 *$Id: testini.prg,v 1.1 2004/03/19 12:58:06 sandrorrfreire Exp $
 *
 * HwGUI Samples
 * testini.prg - Test to use files ini 
 */

#include "windows.ch"
#include "guilib.ch"

Function Main

   Local oMainWindow
   Local cIniFile:="HwGui.ini"

   //Create the inifile
   if !file( cIniFile )

      Hwg_WriteIni( 'Config', 'WallParer' , "No Paper", cIniFile )
      Hwg_WriteIni( 'Config', 'DirHwGUima', "C:\HwGUI" , cIniFile )
      Hwg_WriteIni( 'Print',  'Spoll'   ,   "Epson LX 80" , cIniFile )

    endif 


   INIT WINDOW oMainWindow MAIN TITLE "Example" ;
     AT 200,0 SIZE 400,150

   MENU OF oMainWindow
      MENUITEM "&Exit" ACTION hwg_EndWindow()
      MENUITEM "&Read Ini" ACTION ReadIni()
   ENDMENU

   ACTIVATE WINDOW oMainWindow
Return Nil

Function ReadIni()
Local cIniFile:="HwGui.ini"
hwg_Msginfo( Hwg_GetIni( 'Config', 'WallParer' ,, cIniFile ) )
hwg_Msginfo( Hwg_GetIni( 'Config', 'DirHwGUima',, cIniFile ) )
hwg_Msginfo( Hwg_GetIni( 'Print',  'Spoll'     ,, cIniFile ) )
Return Nil
