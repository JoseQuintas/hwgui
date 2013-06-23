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

  IF WinMsg == WM_KEYUP
	 nKey := WParam
	 hwg_Msginfo( "Keyup " + chr( nKey ) + " " + str( nKey ) )
  endif

RETURN( -1 )


