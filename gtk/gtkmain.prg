/*
 * $Id: gtkmain.prg,v 1.7 2005-11-13 12:37:41 lculik Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Main prg level functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "hwgui.ch"

Function EndWindow()
   IF HWindow():GetMain() != Nil
      HWindow():aWindows[1]:Close()
   ENDIF
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

Function MsgGet( cTitle, cText, nStyle, x, y, nDlgStyle )
Local oModDlg, oFont := HFont():Add( "Sans",0,12 )
Local cRes := ""

   nStyle := Iif( nStyle == Nil, 0, nStyle )
   x := Iif( x == Nil, 210, x )
   y := Iif( y == Nil, 10, y )
   nDlgStyle := Iif( nDlgStyle == Nil, 0, nDlgStyle )

   INIT DIALOG oModDlg TITLE cTitle AT x,y SIZE 300,140 ;
        FONT oFont CLIPPER STYLE WS_POPUP+WS_VISIBLE+WS_CAPTION+WS_SYSMENU+WS_SIZEBOX+nDlgStyle

   @ 20,10 SAY cText SIZE 260,22
   @ 20,35 GET cres  SIZE 260,26 STYLE WS_DLGFRAME + WS_TABSTOP + nStyle

   @ 20,95 BUTTON "Ok" ID IDOK SIZE 100,32 ON CLICK {||oModDlg:lResult:=.T.,EndDialog()}
   @ 180,95 BUTTON "Cancel" ID IDCANCEL SIZE 100,32 ON CLICK {||EndDialog()}

   ACTIVATE DIALOG oModDlg

   oFont:Release()
   IF oModDlg:lResult
      Return Trim( cRes )
   ELSE
      cRes := ""
   ENDIF

Return cRes

Function WChoice( arr, cTitle, nLeft, nTop, oFont, clrT, clrB, clrTSel, clrBSel )
Local oDlg, oBrw
Local nChoice := 0, i, aLen := Len( arr ), nLen := 0, addX := 20, addY := 30
Local hDC, aMetr, width, height, screenh

   IF cTitle == Nil; cTitle := ""; ENDIF
   IF nLeft == Nil; nLeft := 10; ENDIF
   IF nTop == Nil; nTop := 10; ENDIF
   IF oFont == Nil; oFont := HFont():Add( "Times",0,12 ); ENDIF

   IF Valtype( arr[1] ) == "A"
      FOR i := 1 TO aLen
         nLen := Max( nLen,Len(arr[i,1]) )
      NEXT
   ELSE
      FOR i := 1 TO aLen
         nLen := Max( nLen,Len(arr[i]) )
      NEXT
   ENDIF

   hDC := GetDC( GetActiveWindow() )
   SelectObject( hDC, ofont:handle )
   aMetr := GetTextMetric( hDC )
   ReleaseDC( GetActiveWindow(),hDC )
   height := (aMetr[1]+1)*aLen+4+addY
   screenh := GETDESKTOPHEIGHT()
   IF height > screenh * 2/3
      height := Int( screenh *2/3 )
      addX := addY := 0
   ENDIF
   width := ( Round( (aMetr[3]+aMetr[2]) / 2,0 ) + 3 ) * nLen + addX

   INIT DIALOG oDlg TITLE cTitle ;
         AT nLeft,nTop           ;
         SIZE width,height  ;
         FONT oFont

   @ 0,0 BROWSE oBrw ARRAY          ;
       SIZE  width,height           ;
       FONT oFont                   ;
       STYLE WS_BORDER              ;
       ON SIZE {|o,x,y|o:Move(,,x,y)} ;
       ON CLICK {|o|nChoice:=o:tekzp,EndDialog(o:oParent:handle)}

   IF Valtype( arr[1] ) == "A"
      oBrw:AddColumn( HColumn():New( ,{|value,o|o:msrec[o:tekzp,1]},"C",nLen ) )
   ELSE
      oBrw:AddColumn( HColumn():New( ,{|value,o|o:msrec[o:tekzp]},"C",nLen ) )
   ENDIF
   CreateArList( oBrw, arr )
   oBrw:lDispHead := .F.
   IF clrT != Nil
      oBrw:tcolor := clrT
   ENDIF
   IF clrB != Nil
      oBrw:bcolor := clrB
   ENDIF
   IF clrTSel != Nil
      oBrw:tcolorSel := clrTSel
   ENDIF
   IF clrBSel != Nil
      oBrw:bcolorSel := clrBSel
   ENDIF

   oDlg:Activate()
   oFont:Release()

Return nChoice


INIT PROCEDURE GTKINIT()
   hwg_gtk_init()
Return

/*
EXIT PROCEDURE GTKEXIT()
   hwg_gtk_exit()
Return
*/

Function RefreshAllGets( oDlg )

   AEval( oDlg:GetList, {|o|o:Refresh()} )
Return Nil
