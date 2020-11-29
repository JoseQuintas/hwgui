/*
 * test_bot.prg
 *
 * HWGUI sample display key codes
 * 
 *  $Id$
 *
 * Status:
 *  WinAPI   :  Yes
 *  GTK/Linux:  No
 *  GTK/Win  :  No 
 *
*/

#INCLUDE "hwgui.CH"

FUNCTION Main

  local oMainWindow

  INIT WINDOW oMainWindow MAIN                         ;
      TITLE "bOther Test"                              ;
      SIZE 500, 500                                    ;
      ON OTHER MESSAGES {|a,b,c,d| OnOtherMessages(a,b,c,d) }

  oMainWindow:activate()

 RETURN( NIL )

FUNCTION OnOtherMessages( Sender, WinMsg, WParam, LParam )

  local nKey

/* Remove comment chars to display keydown codes */  
// IF WinMsg == WM_KEYDOWN
//    nKey := WParam
//    hwg_Msginfo( "Keydown " + chr( hwg_Loword( nKey ) ) + " " + str( hwg_Loword( nKey ) ) )
//  endif
  

  IF WinMsg == WM_KEYUP
    nKey := WParam
    hwg_Msginfo( "Keyup " + chr( hwg_Loword( nKey ) ) + " " + str( hwg_Loword( nKey ) ) )
  endif

RETURN( -1 )


* ============================ EOF of test_bot.prg ==========================

