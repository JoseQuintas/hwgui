/*
 * Notes
 * Embedded calculator
 *
 * Copyright 2015 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hbmemvar.ch"

#define P_X             1
#define P_Y             2

#define SETC_LEFT       3

#define OB_TYPE         1
#define OB_OB           2
#define OB_ASTRU        2
#define OB_CLS          3
#define OB_ID           4
#define OB_ACCESS       5
#define OB_ATEXT        4
#define OB_TWIDTH       4
#define OB_TRNUM        4
#define OB_TALIGN       5
#define OB_OPT          5
#define OB_TBL          6
#define OB_HREF         6
#define OB_IALIGN       7
#define OB_EXEC         7

#define OB_CWIDTH       1
#define OB_CLEFT        2
#define OB_CRIGHT       3

#define OB_COLSPAN      5
#define OB_ROWSPAN      6
#define OB_AWRAP        7
#define OB_ALIN         8
#define OB_NLINES       9
#define OB_NLINEF      10
#define OB_NTLEN       11
#define OB_NWCF        12
#define OB_NWSF        13
#define OB_NLINEC      14
#define OB_NPOSC       15
#define OB_NLALL       16
#define OB_APC         17
#define OB_APM1        18
#define OB_APM2        19

#define BIT_ALLOW       1
#define BIT_RDONLY      2
#define BIT_NOINS       3
#define BIT_NOCR        4
#define BIT_CLCSCR      5

REQUEST PI, COS, SIN, TAN, COT, ACOS, ASIN, ATAN, DTOR, RTOD

STATIC oEdiCurr, cIdExp := "clcexp", cIdRes := "clcres"
STATIC aCurrTD := { 0,0,0 }
STATIC ceol := e"\r\n"

FUNCTION EditScr( oEdit, aStru )

   LOCAL oDlg, oEdiScr, arr

   INIT DIALOG oDlg TITLE Iif( aStru==Nil, "Insert", "Edit" ) + " script" ;
      AT 100,240  SIZE 600,300  FONT HWindow():Getmain():oFont ;
      STYLE WS_POPUP+WS_VISIBLE+WS_CAPTION+WS_SYSMENU+WS_MAXIMIZEBOX+WS_SIZEBOX ;
      ON INIT {||hwg_Movewindow(oDlg:handle,100,240,600,310)}

   oEdiScr := HCEdit():New( ,,, 0, 0, 400, oDlg:nHeight, oDlg:oFont,, {|o,x,y|o:Move(,,x,y)} )

   IF aStru != Nil .AND. !Empty( aStru[OB_HREF] )
      oEdiScr:SetText( aStru[OB_HREF] )
   ENDIF

   ACTIVATE DIALOG oDlg

   IF oEdiScr:lUpdated .AND. hwg_Msgyesno( "Code was changed! Save it?" )
      IF aStru != Nil
         aStru[OB_HREF] := oEdiScr:GetText()
         aStru[OB_EXEC] := Nil
      ELSE
         oEdit:InsSpan( "()", "fb", oEdiScr:GetText() )
         oEdit:SetCaretPos( SETC_LEFT )
         arr := oEdit:GetPosInfo()
         IF !Empty( arr[3] )
            arr[3,OB_ACCESS] := hwg_setBit( hwg_setBit( 0, BIT_CLCSCR ), BIT_RDONLY )
            IF Len( arr[3] ) < OB_EXEC
               Aadd( arr[3], Nil )
            ENDIF
         ENDIF
      ENDIF
   ENDIF

   hced_Setfocus( oEdit:hEdit )

   RETURN Nil

STATIC FUNCTION PreProc( s )

   LOCAL cRes := "", nPos1 := 1, nPos2, c, cTemp

   DO WHILE Substr( s,nPos1,1 ) <= ' '; nPos1 ++; ENDDO
   DO WHILE ( nPos2 := hb_At( "$", s, nPos1 ) ) > 0        
      IF ( c := Substr( s, nPos2+1, 1 ) ) $ "CR"
         // $Cn (a column number 'n' of a current row)
         // or $Rn (a row number 'n' of a current column)
         cRes += Substr( s, nPos1, nPos2 - nPos1 )
         nPos1 := nPos2 := nPos2 + 3
         DO WHILE IsDigit( Substr( s, nPos1, 1 ) ); nPos1 ++; ENDDO
         IF Substr( s, nPos1, 1 ) == ":"
            // A range for "Sum" function: Sum($C1:3) or Sum($R1:4)
            cRes += "{" + Iif( c=="C","","," ) + Substr( s, nPos2-1, nPos1-nPos2+1 ) + Iif( c=="C",",","" ) + ","
            nPos1 := nPos2 := nPos1 + 1
            DO WHILE IsDigit( Substr( s, nPos1, 1 ) ); nPos1 ++; ENDDO
            cRes += Iif( c=="C","","," ) + Substr( s, nPos2, nPos1-nPos2 ) + Iif( c=="C",",","" ) + "}"
         ELSE
            cRes += "Z(" + Iif( c=="C","","," ) + Substr( s, nPos2-1, nPos1-nPos2+1 ) + ")"
         ENDIF
      ELSEIF c == 'M'
         nPos1 := nPos2 + 2
         cTemp := ""
         DO WHILE !( (c := Substr(s,nPos1,1)) $ " :=!<>+-*/%,") .AND. !(c $ ceol)
            cTemp += c
            nPos1 ++
         ENDDO
         DO WHILE (c := Substr( s,nPos1,1 )) == ' '; nPos1 ++; ENDDO
         IF c == ':'
            cRes += "SetAt('" + cTemp + "',"
            nPos1 += 2
            IF (nPos2 := hb_At( Chr(10), s, nPos1 )) > 0
               nPos2 --
               IF Substr( s, nPos2, 1 ) == Chr(13)
                  nPos2 --
               ENDIF
               cRes += PreProc( Substr( s,nPos1,nPos2-nPos1+1 ) ) + ")" + ceol
               nPos1 := nPos2 + 1
            ELSE
               cRes += PreProc( Substr( s,nPos1 ) ) + ")"
               nPos1 := Len(s) + 1
            ENDIF
         ELSE
            cRes += "GetAt('" + cTemp + "')"
         ENDIF
      ELSE
         cRes += Substr( s, nPos1, nPos2 - nPos1 + 1 )
         nPos1 := nPos2 + 1
      ENDIF
   ENDDO
   cRes += Substr( s, nPos1 )
   nPos2 := Len( cRes )
   DO WHILE Substr( cRes,nPos2,1 ) <= ' '; nPos2 --; ENDDO
   IF nPos2 < Len( cRes )
      cRes := Left( cRes, nPos2 )
   ENDIF

   RETURN cRes

STATIC FUNCTION CalcScr( aStru, nL, iTD, nL1 )

   LOCAL xRes, cRes, nPos2, c, nLen

   IF aStru[OB_EXEC] == Nil
      cRes := PreProc( aStru[OB_HREF] )
      //hwg_writelog( cRes )
      IF !( Chr(10) $ cRes )
         IF Lower( Left( cRes, 6 ) ) == "return"
            cRes := Substr( cRes, 8 )
         ENDIF
         aStru[OB_EXEC] := &( "{||" + cRes + "}" )
      ELSE
         aStru[OB_EXEC] := RdScript( , cRes )
      ENDIF
   ENDIF
   IF ( xRes := Iif( Valtype(aStru[OB_EXEC])=="A", DoScript(aStru[OB_EXEC]), Eval(aStru[OB_EXEC]) ) ) != Nil
      cRes := Trim( Transform( xReS, "@B" ) )
      IF Valtype( xRes ) == "N" .AND. Rat( ".", cRes ) > 0
        nPos2 := Len( cRes )
        DO WHILE Substr( cRes, nPos2, 1 ) == '0'; nPos2 --; ENDDO
        IF Substr( cRes, nPos2, 1 ) == '.'
           nPos2 --
        ENDIF
        cRes := Left( cRes, nPos2 )
      ENDIF
      cRes := "(" + cRes + ")"
      IF iTD != Nil
         oEdiCurr:LoadEnv( nL, iTD )
      ELSE
         nL1 := nL
      ENDIF
      nLen := hced_Len( oEdiCurr, hced_SubStr( oEdiCurr, oEdiCurr:aText[nL1], aStru[1], aStru[2] - aStru[1] + 1 ) )
      oEdiCurr:InsText( { aStru[1],nL1 }, cRes,, .F. )
      oEdiCurr:DelText( { aStru[1] + hced_Len( oEdiCurr,cRes ), nL1 }, ;
            { aStru[1] + hced_Len( oEdiCurr,cRes ) + nLen, nL1 } , .F. )
      oEdiCurr:lUpdated := .T.
      IF iTD != Nil
         oEdiCurr:RestoreEnv( nL, iTD )
      ENDIF
   ENDIF
   hced_Setfocus( oEdiCurr:hEdit )

   RETURN Nil

FUNCTION CalcAll( oEdit )

   LOCAL i, j, aStru, l := .F.
   LOCAL aStruTD, aTextTD, nTextLen, n, i1

   oEdiCurr := oEdit
   FOR i := 1 TO oEdit:nTextLen
      aStru := oEdit:aStru[i]
      aCurrTD[1] := aCurrTD[2] := aCurrTD[3] := 0
      FOR j := 2 TO Len( aStru )
         IF Len( aStru[j] ) >= OB_HREF .AND. hwg_CheckBit( aStru[j,OB_ACCESS], BIT_CLCSCR )
            CalcScr( aStru[j], i )
            l := .T.
         //ELSEIF Len( aStru[j] ) >= OB_ID .AND. !Empty( aStru[j,OB_ID] ) .AND. Left(aStru[j,OB_ID],6) == cIdRes
         //   Calc( oEdit, i )
         ENDIF
      NEXT
      IF Valtype(aStru[1,OB_TYPE]) == "C" .AND. aStru[1,OB_TYPE] == "tr"
         FOR n := 1 TO Len( aStru[1,OB_OB] )
            aCurrTD[1] := n; aCurrTD[2] := aStru[1,OB_TRNUM]; aCurrTD[3] := i
            aStruTD := aStru[ 1,OB_OB,n,2 ]
            aTextTD := aStru[ 1,OB_OB,n,OB_ATEXT ]
            nTextLen := aStru[ 1,OB_OB,n,OB_NTLEN ]
            FOR i1 := 1 TO nTextLen
               FOR j := 2 TO Len( aStruTD[i1] )
                  IF Len( aStruTD[i1,j] ) >= OB_HREF .AND. hwg_CheckBit( aStruTD[i1,j,OB_ACCESS], BIT_CLCSCR )
                     CalcScr( aStruTD[i1,j], i, n, i1 )
                  ELSEIF Len( aStruTD[i1,j] ) >= OB_ID .AND. !Empty( aStruTD[i1,j,OB_ID] ) .AND. Left(aStruTD[i1,j,OB_ID],6) == cIdRes
                     Calc( oEdit, i, n, i1 )
                  ENDIF
               NEXT
            NEXT
         NEXT
      ELSEIF !l
         Calc( oEdit, i )
      ENDIF

   NEXT

   RETURN Nil

FUNCTION Calc( oEdit, nL, iTD, nL1 )

   LOCAL arr, aStru, i, j, n, nStruExp, nStruRes
   LOCAL xRes, cRes, cExp, lEqExi := .F., lNewExp := .F., nPos1, nPos2
   LOCAL bOldError, lAll := .T.

   oEdiCurr := oEdit

   IF nL == Nil
      lAll := .F.
      aCurrTD[1] := aCurrTD[2] := aCurrTD[3] := 0
      arr := oEdit:GetPosInfo()
      nL := arr[1]
      IF Len( arr ) >= 7
         aCurrTD[1] := arr[2]; aCurrTD[2] := oEdit:aStru[nL,1,OB_TRNUM]; aCurrTD[3] := nL
         iTD := arr[2]; nL1 := arr[4]
      ENDIF
      IF !Empty( arr[3] ) .AND. Len( arr[3] ) >= OB_HREF .AND. ;
            hwg_CheckBit( arr[3,OB_ACCESS], BIT_CLCSCR )
         IF Len( arr ) >= 7
            RETURN CalcScr( arr[3], nL, arr[2], arr[4] )
         ELSE
            RETURN CalcScr( arr[3], nL )
         ENDIF
      ENDIF
   ENDIF

   IF iTD != Nil
      oEdit:LoadEnv( nL, iTD )
   ELSE
      nL1 := nL
   ENDIF

   aStru := oEdit:aStru[nL1]
   FOR i := 2 TO Len( aStru )
      IF Len( aStru[i] ) >= OB_ID .AND. !Empty( aStru[i,OB_ID] )
         IF Left(aStru[i,OB_ID],6) == cIdExp
            nStruExp := i
         ELSEIF Left(aStru[i,OB_ID],6) == cIdRes
            nStruRes := i
         ENDIF
      ENDIF
   NEXT

   IF Empty( nStruExp )
      IF Empty( oEdit:aPointM2[P_Y] )
         cExp := Trim( Iif( Empty(nStruRes), oEdit:aText[nL1], ;
               Left(oEdit:aText[nL1],aStru[nStruRes,1]-1) ) )
      ELSE
         cExp := Trim( oEdit:GetText( oEdit:aPointM1, oEdit:aPointM2 ) )
         lNewExp := .T.
      ENDIF
   ELSE
      cExp := Trim( Substr(oEdit:aText[nL1],aStru[nStruExp,1],aStru[nStruExp,2]-aStru[nStruExp,1]+1) )
   ENDIF

   IF !lNewExp .AND. Right( cExp, 1 ) == '='
      cExp := Trim( Left( cExp, Len( cExp ) - 1 ) )
      lEqExi := .T.
   ENDIF

   nPos1 := 1
   DO WHILE ( nPos2 := hb_At( "$-", cExp, nPos1 ) ) > 0
      nPos1 := nPos2 + 3
      IF IsDigit( n := Substr( cExp, nPos2+2, 1 ) ) .AND. !IsDigit( Substr( cExp, nPos2+3, 1 ) )
         n := Val(n)
         j := nL1
         DO WHILE --j > 0 .AND. n > 0
            aStru := oEdit:aStru[j]
            FOR i := 2 TO Len( aStru )
               IF Len( aStru[i] ) >= OB_ID .AND. !Empty( aStru[i,OB_ID] )
                  IF Left(aStru[i,OB_ID],6) == cIdRes
                     IF --n == 0
                        cExp := Left( cExp,nPos2-1 ) + ;
                           Substr( oEdit:aText[j],aStru[i,1],aStru[i,2]-aStru[i,1]+1 ) + ;
                           Substr( cExp, nPos2+3 )
                        nPos1 := nPos2 + aStru[i,2] - aStru[i,1]
                     ENDIF
                     EXIT
                  ENDIF
               ENDIF
            NEXT
         ENDDO
      ENDIF
   ENDDO

   aStru := oEdit:aStru[nL1]

   IF iTD != Nil
      oEdit:RestoreEnv( nL, iTD )
   ENDIF

   SET DECIMALS TO 8
   bOldError := ErrorBlock( { |e|break( e ) } )
   BEGIN SEQUENCE
      xRes := &cExp
   RECOVER
      xRes := Nil
   END SEQUENCE
   ErrorBlock( bOldError )

   IF iTD != Nil
      oEdit:LoadEnv( nL, iTD )
   ENDIF
   IF xRes == Nil
      IF !lAll
         hwg_MsgStop( "Expression error", "Calculator" )
      ENDIF
   ELSE
      cRes := CnvVal( xRes )
      IF Empty( nStruRes )
         nPos2 := Len(oEdit:aText[nL1]) + 1
         IF lNewExp
            nPos1 := Min( oEdit:aPointM1[P_X], oEdit:aPointM2[P_X] )
            nPos2 := Max( oEdit:aPointM1[P_X], oEdit:aPointM2[P_X] )
         ENDIF
         IF !lEqExi
            oEdit:InsText( { nPos2,nL1 }, ' = ',, .F. )
            nPos2 += 3
         ENDIF
         IF lNewExp
            oEdit:ChgStyle( { nPos1,nL1 }, { nPos2-3,nL1 }, "fi" )
            aStru := oEdit:GetPosInfo( { nPos1+1,nL1 } )[3]
            IF Len( aStru ) >= OB_ID
               aStru[OB_ID] := cIdExp
            ELSE
               Aadd( aStru, cIdExp )
            ENDIF
         ENDIF
         oEdit:aPointC[P_X] := nPos2
         oEdit:aPointC[P_Y] := nL1
         oEdit:InsSpan( cRes, "fb" )
         aStru := oEdit:GetPosInfo( { nPos2+1,nL1 } )[3]
         IF Len( aStru ) >= OB_ID
            aStru[OB_ID] := cIdRes
         ELSE
            Aadd( aStru, cIdRes )
         ENDIF
      ELSE
         n := aStru[nStruRes,2]-aStru[nStruRes,1]+1
         oEdit:InsText( { aStru[nStruRes,1],nL1 }, cRes,, .F. )
         oEdit:DelText( { aStru[nStruRes,1]+hced_Len(oEdit,cRes),nL1 }, ;
               { aStru[nStruRes,1]+hced_Len(oEdit,cRes)+n,nL1 }, .F. )
      ENDIF
      oEdit:lUpdated := .T.
   ENDIF
   SET DECIMALS TO 2
   IF iTD != Nil
      oEdit:RestoreEnv( nL, iTD )
   ENDIF

   IF lAll
      __mvSetBase()
   ENDIF
   hced_Setfocus( oEdit:hEdit )
   
   RETURN Nil

STATIC FUNCTION CnvVal( xRes )

   LOCAL cRes := Valtype(xRes), nPos2

   IF cRes == "A"
      cRes := "Array, " + Ltrim(Str(Len(xRes))) + " elements"
   ELSEIF cRes == "O"
      cRes := "Object of " + xRes:Classname()
   ELSEIF cRes == "H"
      cRes := "Hash array"
   ELSEIF cRes == "U"
      cRes := "Nil"
   ELSEIF cRes == "C"
      cRes := '"' + xRes + '"'
   ELSE
      cRes := Trim( Transform( xReS, "@B" ) )
   ENDIF
   IF Valtype( xRes ) == "N" .AND. Rat( ".", cRes ) > 0
     nPos2 := Len( cRes )
     DO WHILE Substr( cRes, nPos2, 1 ) == '0'; nPos2 --; ENDDO
     IF Substr( cRes, nPos2, 1 ) == '.'
        nPos2 --
     ENDIF
     cRes := Left( cRes, nPos2 )
   ENDIF

   RETURN cRes

FUNCTION Z( nCol, nRow )

   LOCAL nL, cText, c

   IF nCol == Nil
      nCol := aCurrTD[1]
   ELSEIF nCol < 0
      nCol := aCurrTD[1] + nCol
   ENDIF
   IF nRow == Nil
      nRow := aCurrTD[2]
   ELSEIF nRow < 0
      nRow := aCurrTD[2] + nRow
   ENDIF
   IF Empty(nCol) .OR. Empty(nRow)
      RETURN Nil
   ENDIF

   nL := aCurrTD[3] - oEdiCurr:aStru[aCurrTD[3],1,OB_TRNUM] + nRow
   cText := Ltrim( oEdiCurr:aStru[ nL,1,OB_OB,nCol,OB_ATEXT ][1] )

   RETURN Iif( (c := Left(cText,1))=="(", Val(Substr(cText,2)), ;
         Iif( IsDigit(c).OR.c=='-', Val(cText), cText ) )

FUNCTION Sum( aCells )

   LOCAL nSum := 0, i, nL, cText

   IF aCells[1] == Nil
      aCells[1] := aCells[3] := aCurrTD[1]
   ELSEIF aCells[1] < 0
      aCells[1] := aCurrTD[1] + aCells[1]
   ENDIF
   IF aCells[3] < 0
      aCells[3] := aCurrTD[1] + aCells[3]
   ENDIF

   IF aCells[2] == Nil
      aCells[2] := aCells[4] := aCurrTD[2]
   ELSEIF aCells[2] < 0
      aCells[2] := aCurrTD[2] + aCells[2]
   ENDIF
   IF aCells[4] < 0
      aCells[4] := aCurrTD[2] + aCells[4]
   ENDIF

   IF aCells[1] == aCells[3]
      nL := aCurrTD[3] - oEdiCurr:aStru[aCurrTD[3],1,OB_TRNUM] + aCells[2]
      FOR i := aCells[2] TO aCells[4]
         cText := Ltrim( oEdiCurr:aStru[ nL,1,OB_OB,aCells[1],OB_ATEXT ][1] )
         nSum += Iif( Left(cText,1)=="(", Val(Substr(cText,2)), Val(cText) )
         nL ++
      NEXT
   ELSE
      nL := aCurrTD[3] - oEdiCurr:aStru[aCurrTD[3],1,OB_TRNUM] + aCells[2]
      FOR i := aCells[1] TO aCells[3]
         cText := Ltrim( oEdiCurr:aStru[ nL,1,OB_OB,i,OB_ATEXT ][1] )
         nSum += Iif( Left(cText,1)=="(", Val(Substr(cText,2)), Val(cText) )
      NEXT
   ENDIF

   RETURN nSum

FUNCTION GetAt( cMet )

   LOCAL arrf, nL, aStru, cOldVal

   IF !Empty( arrf := oEdiCurr:Find( ,cMet ) ) .AND. arrf[1] > 1
      nL := arrf[2]
      aStru := oEdiCurr:aStru[nL,arrf[1]]
      cOldVal := Ltrim( hced_SubStr( oEdiCurr, oEdiCurr:aText[nL], aStru[1], aStru[2] - aStru[1] + 1 ) )
      IF Left( cOldVal,1 ) == "("
         cOldVal := Substr( cOldVal,2,Len(cOldVal)-2 )
      ENDIF
      IF IsDigit( Left( cOldVal,1 ) )
         RETURN Val( Substr(cOldVal,1) )
      ELSE
         RETURN cOldVal
      ENDIF
   ENDIF

   RETURN Nil

FUNCTION SetAt( cMet, xVal )

   LOCAL cVal := CnvVal(xVal), arrf, nL, aStru, cOldVal

   IF !Empty( arrf := oEdiCurr:Find( ,cMet ) ) .AND. arrf[1] > 1
      nL := arrf[2]
      aStru := oEdiCurr:aStru[nL,arrf[1]]
      cOldVal := hced_SubStr( oEdiCurr, oEdiCurr:aText[nL], aStru[1], aStru[2] - aStru[1] + 1 )
      oEdiCurr:InsText( { aStru[1],nL }, cVal,, .F. )
      oEdiCurr:DelText( { aStru[1]+hced_Len(oEdiCurr,cVal),nL }, ;
            { aStru[1]+hced_Len(oEdiCurr,cVal)+hced_Len(oEdiCurr,cOldVal),nL }, .F. )
   ENDIF

   RETURN cVal
