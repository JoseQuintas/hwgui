/*
 * $Id: gtkmain.prg,v 1.2 2005-01-20 08:38:26 alkresin Exp $
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

Function VColor( cColor )
Local i,res := 0, n := 1, iValue
   cColor := Trim(cColor)
   for i := 1 to Len( cColor )
      iValue := Asc( Substr( cColor,Len(cColor)-i+1,1 ) )
      if iValue < 58 .and. iValue > 47
         iValue -= 48
      elseif iValue >= 65 .and. iValue <= 70
         iValue -= 55
      elseif iValue >= 97 .and. iValue <= 102
         iValue -= 87
      else
        Return 0
      endif
      res += iValue * n
      n *= 16
   next
Return res


INIT PROCEDURE GTKINIT()
   hwg_gtk_init()
Return

/*
EXIT PROCEDURE GTKEXIT()
   hwg_gtk_exit()
Return
*/
