/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * The Extended edit control
 *
 * Copyright 2014 Alexander Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 */
#include "hbclass.ch"
#include "hwgui.ch"

#define  HILI_LEN       8

#define UNDO_LINE1      1
#define UNDO_POS1       2
#define UNDO_LINE2      3
#define UNDO_POS2       4
#define UNDO_OPER       5
#define UNDO_TEXT       6
#define UNDO_EX         7
#define UNDO_NTRTD      8

#define P_LENGTH        2
#define P_X             1
#define P_Y             2

#define SETC_COORS      1
#define SETC_XY         4
#define SETC_XYPOS      8

#define AL_LENGTH       8
#define AL_X1           1
#define AL_Y1           2
#define AL_X2           3
#define AL_Y2           4
#define AL_NCHARS       5
#define AL_LINE         6
#define AL_FIRSTC       7
#define AL_SUBL         8

/*
 * Internal dada structures ( ::aStru )
 *    ::aStru[n] - a structure for paragraph number n, the first item ( ::aStru[n,1] ) is <div>, <img> or <tr>
 * <div>:     0, 0, OB_CLS, OB_ID, OB_ACCESS
 *   Next items may be <span> or <a>
 * <span>:    nStart, nEnd, OB_CLS[, OB_ID[, OB_ACCESS[, OB_HREF, OB_EXEC]]]
 * <a>:       nStart, nEnd, OB_CLS, OB_ID, OB_ACCESS, OB_HREF
 *
 * <img>:     "img", OB_OB(HBitmap), OB_CLS, OB_ID, OB_ACCESS, OB_HREF, OB_IALIGN
 *
 * <tr>(1):   "tr", OB_OB(td), cClsName, OB_TRNUM(1), OB_OPT, OB_TBL
 *    The first <tr> of a table includes the table data (OB_TBL) 
 *    OB_TBL:  "tbl", OB_OB(aCols), cClsName, OB_TWIDTH, OB_TALIGN }
 *    aCols:   OB_CWIDTH, OB_CLEFT, OB_CRIGHT
 * <tr>(2...):"tr", OB_OB(td), cClsName, OB_TRNUM, OB_OPT
 * <td>:      "td", OB_ASTRU, cClsName, OB_ATEXT, OB_COLSPAN, OB_ROWSPAN, OB_AWRAP,
       OB_ALIN, OB_NLINES, OB_NLINEF, OB_NTLEN, OB_NWCF, OB_NWSF, OB_NLINEC, OB_NPOSC,
       OB_NLALL, OB_APC, OB_APM1, OB_APM2
 */
#define OB_ARRLEN      23
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
#define OB_FONT        20
#define OB_TCLR        21
#define OB_BCLR        22
#define OB_BCLRCUR     23

#define BIT_ALLOW       1
#define BIT_RDONLY      2
#define BIT_NOINS       3
#define BIT_NOCR        4
#define BIT_CLCSCR      5

#define TROPT_SEL       1

#define WM_MOUSEACTIVATE    33

STATIC cNewLine := e"\r\n"
STATIC aMsgs := { WM_MOUSEMOVE, WM_LBUTTONDOWN, WM_LBUTTONUP, WM_RBUTTONDOWN, ;
   WM_PAINT, WM_GETDLGCODE , WM_CHAR, WM_KEYDOWN, WM_MOUSEWHEEL, WM_VSCROLL, WM_MOUSEACTIVATE, ;
   WM_SETFOCUS, WM_KILLFOCUS, WM_LBUTTONDBLCLK, WM_SIZE, WM_DESTROY }

CLASS HCEdiExt INHERIT HCEdit

   DATA aStru
   DATA aBin
   DATA aImages
   DATA lHtml   INIT .F.
   DATA bImport, bImgLoad
   DATA lSupervise INIT .F.
   DATA lError
   DATA aTdSel     INIT { 0,0 }
   DATA aDefClasses

   DATA lPrinting  INIT .F.  PROTECTED
   DATA lChgStyle  INIT .F.  PROTECTED
   DATA aEnv       INIT Array(OB_ARRLEN)  PROTECTED

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, bPaint, tcolor, bcolor, bGfocus, bLfocus, lNoVScroll, lNoBorder )
   METHOD End()
   METHOD Close()
   METHOD SetText( xText, cPageIn, cPageOut, lCompact, lAdd, nFrom )
   METHOD ReadTag( cTagName, aAttr )      INLINE .T.
   METHOD onEvent( msg, wParam, lParam )
   METHOD PaintLine( hDC, yPos, nLine, lUse_aWrap )
   METHOD SetCaretPos( nType, p1, p2 )
   METHOD AddLine( nLine )
   METHOD DelLine( nLine )
   METHOD AddClass( cName, cSource )
   METHOD FindClass( xBase, xAttr, cNewClass )
   METHOD SetHili( nGroup, oFont, tColor, bColor, nMargL, nMargR, nIndent, nAlign )
   METHOD ChgStyle( P1, P2, xAttr, lDiv, PCell )
   METHOD StyleSpan( nLine, nPos1, nPos2, xAttr, cHref, cId, nOpt )
   METHOD StyleDiv( nLine, xAttr, cClass )
   METHOD InsTable( nCols, nRows, nWidth, nAlign, xAttr )
   METHOD InsRows( nL, nRows, nCols, lNoAddline )
   METHOD InsCol( nL, iTd )
   METHOD DelCol( nL, iTd )
   METHOD InsImage( cName, nAlign, xAttr, xBin, cExt )
   METHOD InsSpan( cText, xAttr, cHref, cId, nOpt )
   METHOD DelObject( cType, nL, nCol )
   METHOD Save( cFileName, cpSou, lHtml, lCompact, nFrom, nTo )
   METHOD SaveTag( cTagName, nL, nItem )  INLINE ""
   METHOD Undo( nLine1, nPos1, nLine2, nPos2, nOper, cText )
   METHOD LoadEnv( nL, iTd )
   METHOD RestoreEnv( nL, iTd )
   METHOD getEnv( n )
   METHOD GetPosInfo( xPos, yPos )
   METHOD getClassAttr( cClsName )
   METHOD PrintLine( oPrinter, yPos, nL )
   METHOD Scan( nl1, nl2, hDC, nWidth, nHeight )
   METHOD Find( cText, cId, cHRef, aStart, lCase, lRegex )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, bPaint, tcolor, bcolor, bGfocus, bLfocus, lNoVScroll, lNoBorder ) CLASS HCEdiExt

   ::oHili := HiliExt():Set( Self )
   ::lWrap := .T.

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, bPaint, tcolor, bcolor, bGfocus, bLfocus, lNoVScroll, lNoBorder )

   ::aEnv[OB_TYPE] := 0
   ::aEnv[OB_APC]  := ::PCopy()
   ::aEnv[OB_APM1] := ::PCopy()
   ::aEnv[OB_APM2] := ::PCopy()
   ::SetHili( "def" )

   RETURN Self

METHOD End() CLASS HCEdiExt
  
   ::Close()

   RETURN ::Super:End()

METHOD Close() CLASS HCEdiExt
   LOCAL i

   IF !Empty( ::aImages )
      FOR i := 1 TO Len( ::aImages )
         IF !Empty( ::aImages[i] )
            ::aImages[i]:Release()
         ENDIF
      NEXT
   ENDIF
   ::aImages := Nil

   RETURN Nil

METHOD SetText( xText, cPageIn, cPageOut, lCompact, lAdd, nFrom ) CLASS HCEdiExt
   LOCAL aText, i, j, n := 0, nBack, nFromBack
   LOCAL nPos1, nPos2 := 0, nPosS, nPosA, cTagName, cVal, xVal, nAlign, aAttr, lSingle
   LOCAL lDiv := .F., lSpan := .F., lA := .F., lStyle := .F., lTable := .F., lTr := .F., lTd := .F., lBin := .F.
   LOCAL lInsRows := .F., nInsCols
   LOCAL cStyles, cClsName, aStru, nAccess, aStruBack, aTextBack, iTd, nLTable, aStruTbl
   LOCAL aImg := {}, aClsReplace := {}

   ::lError := .F.
   IF Empty( lAdd )
      lAdd := .F.
      ::Close()
      ::aHili := hb_HMerge( hb_Hash(), ::aHili, {|k|hb_Ascan(::aDefClasses,k)>0} )
      aText := {}
      ::aStru := {}
      ::aBin := {}
      ::aImages := {}
      IF Empty( xText )
         ::aStru := { { { 0,0,Nil } } }
         RETURN ::Super:SetText()
      ELSEIF Valtype( xText ) == "A"
         RETURN ::Super:SetText( xText, cPageIn, cPageOut )
      ENDIF
   ELSE
      IF Empty( xText )
         RETURN Nil
      ENDIF
      aText := AClone( ::aText )
      ::lUpdated := .T.
      IF Valtype( xText ) == "A"
         aText := ASize( aText, Len(aText) + Len(xText) )
         FOR i := 1 TO Len(xText)
            aText[i+::nTextLen] := xText[i]
         NEXT
         RETURN ::Super:SetText( aText, cPageIn, cPageOut )
      ENDIF
      n := Iif( Empty( nFrom ), Len( aText ), nFrom-1 )
   ENDIF

   ::lHtml := .F.

   IF !Empty( ::bImport )
      aText := Eval( ::bImport, Self, xText, cPageIn, cPageOut )
   ELSE
      DO WHILE nPos2 < Len(xText) .AND. Substr( xText, ++nPos2, 1 ) $ e" \t\r\n"; ENDDO
      IF ( cTagName := Substr( xText, nPos2++, 5 ) ) == "<html"
         ::lHtml := .T.
      ELSEIF cTagName != "<hwge"
         IF Empty( lCompact )
            ::lError := .T.
            IF !lAdd
               ::aStru := { { {0,0,Nil} } }
            ENDIF
            RETURN ::Super:SetText( , cPageIn, cPageOut )
         ENDIF
         nPos2 := 1
      ELSE
         nPos1 := hb_At( ">", xText, nPos2 )
         aAttr := hbxml_GetAttr( Substr( xText, nPos2-1, nPos1-nPos2+2 ) )
         IF ( i:=Ascan(aAttr,{|a|a[1]=="page"}) ) == 0
            ::nDocFormat := 0
         ELSE
            xVal := hb_aTokens( aAttr[i,2], ',' )
            IF Len( xVal ) > 5
               ::nDocFormat := Ascan( HPrinter():aPaper,{|a|a[1]==xVal[1]} )
               ::nDocOrient := Val( xVal[2] )
               ::aDocMargins[1] := Val( xVal[3] )
               ::aDocMargins[2] := Val( xVal[4] )
               ::aDocMargins[3] := Val( xVal[5] )
               ::aDocMargins[4] := Val( xVal[6] )
            ENDIF
         ENDIF
         ::ReadTag( cTagName, aAttr )
      ENDIF

      hbxml_SetEntity( { { "lt;","<" }, { "gt;",">" },{ "amp;","&" } } )

      DO WHILE ( nPos1 := hb_At( "<", xText, nPos2 ) ) != 0
         i := 1
         DO WHILE !( Substr( xText, nPos1 + ++i, 1 ) $ " />" ); ENDDO
         cTagName := Substr( xText, nPos1 + 1, i-1 )

         nPos2 := hb_At( ">", xText, nPos1 )
         IF Left( cTagName,1 ) == "/"
            IF cTagName == "/div" .OR. cTagName == "/p"
               IF !lDiv ; ::lError := .T. ; EXIT ; ENDIF
               lDiv := .F.
               aText[n] += hbxml_preLoad( Substr( xText, nPosA, nPos1 - nPosA ) )

            ELSEIF cTagName == "/span"
               IF !lSpan ; ::lError := .T. ; EXIT ; ENDIF
               lSpan := .F.
               nPosA := nPos2 + 1
               cVal := hbxml_preLoad( Substr( xText, nPosS, nPos1 - nPosS ) )
               hced_CrStru( Self, aAttr, ::aStru[n], aText[n], cClsname, cVal )
               aText[n] += cVal

            ELSEIF cTagName == "/a"
               IF !lA ; ::lError := .T. ; EXIT ; ENDIF
               lA := .F.
               nPosA := nPos2 + 1
               cVal := hbxml_preLoad( Substr( xText, nPosS, nPos1 - nPosS ) )
               hced_CrStru( Self, aAttr, ::aStru[n], aText[n], Iif(cClsname==Nil,"url",cClsname), cVal, ;
                     Iif( (i:=Ascan(aAttr,{|a|a[1]=="href"}))==0, "", aAttr[i,2] ) )
               aText[n] += cVal

            ELSEIF cTagName == "/style"
               IF !lStyle ; ::lError := .T. ; EXIT ; ENDIF
               lStyle := .F.
               cStyles := Substr( xText, nPosS, nPos1 - nPosS )
               nPosA := 1
               DO WHILE ( nPosS := hb_At( "{", cStyles, nPosA ) ) != 0
                  cClsName := AllTrim( StrTran( StrTran( Substr(cStyles,nPosA,nPosS-nPosA), Chr(13), "" ), Chr(10), "" ) )
                  IF Left( cClsName, 1 ) == "."
                     cClsName := Substr( cClsName, 2 )
                  ENDIF
                  IF ( nPosA := hb_At( "}", cStyles, nPosS ) ) == 0
                     ::lError := .T.
                     EXIT
                  ENDIF
                  nPosS ++
                  IF !Empty( cVal := ::AddClass( cClsName, Substr( cStyleS, nPosS, nPosA-nPosS ) ) )
                     Aadd( aClsReplace, { cClsName, cVal } )
                  ENDIF
                  nPosA ++
               ENDDO

            ELSEIF cTagName == "/td"
               IF !lTd ; ::lError := .T. ; EXIT ; ENDIF
               lTd := .F.
               aStruBack[ nBack,1,OB_OB,iTd,OB_AWRAP ] := Array( Len(aText) )
               aStruBack[ nBack,1,OB_OB,iTd,OB_NTLEN ] := Len(aText)
               ::aStru := aStruBack
               aText := aTextBack
               nFrom := nFromBack
               n := nBack

            ELSEIF cTagName == "/tr"
               IF !lTr ; ::lError := .T. ; EXIT ; ENDIF
               lTr := .F.

            ELSEIF cTagName == "/table"
               IF !lTable ; ::lError := .T. ; EXIT ; ENDIF
               lTable := .F.
               IF lInsRows
                  lInsRows := .F.
                  j := ::aStru[n,1,OB_TRNUM]
                  i := n + 1
                  DO WHILE i <= Len( ::aStru ) .AND. Valtype( ::aStru[i,1,OB_TYPE] ) == "C" ;
                        .AND. ::aStru[i,1,OB_TYPE] == "tr"
                     ::aStru[i,1,OB_TRNUM] := ++j
                     i ++
                  ENDDO
               ENDIF

            ELSEIF cTagName == "/binary"
               IF !lBin ; ::lError := .T. ; EXIT ; ENDIF
               lBin := .F.
               cVal := hb_Base64Decode( Substr( xText, nPosS, nPos1 - nPosS ) )
               xVal := HBitmap():AddString( cClsName, cVal )
               Aadd( ::aImages, xVal )
               Aadd( ::aBin, { cClsName, cVal, xVal, Iif( (i:=Ascan(aAttr,{|a|a[1]=="ext"}))==0, Nil, aAttr[i,2] )} )

            ENDIF
         ELSE
            aAttr := hbxml_GetAttr( Substr( xText, nPos1, nPos2-nPos1+1 ), @lSingle )
            cClsName := Iif( (i:=Ascan(aAttr,{|a|a[1]=="class"}))==0, Nil, aAttr[i,2] )
            IF cClsName != Nil .AND. ( i := Ascan( aClsReplace, {|a|a[1]==cClsName}) ) > 0
               cClsName := aClsReplace[i,2]
            ENDIF
            IF cTagName == "div" .OR. cTagName == "p"
               IF lDiv ; ::lError := .T. ; EXIT ; ENDIF
               n ++
               IF Empty( nFrom )
                  Aadd( aText, "" )
                  Aadd( ::aStru, {} )
               ELSE
                  Aadd( aText, Nil ); AIns( aText, n ); aText[n] := ""
                  Aadd( ::aStru, Nil ); AIns( ::aStru, n ); ::aStru[n] := {}
               ENDIF
               hced_CrStru( Self, aAttr, ::aStru[n],, cClsname )
               lDiv := .T.
               nPosA := nPos2 + 1

            ELSEIF cTagName == "span"
               IF ( !lDiv .AND. !lTd ) .OR. lSpan .OR. lA ; ::lError := .T. ; EXIT ; ENDIF
               lSpan := .T.
               nPosS := nPos2 + 1
               IF ( i := Ascan(aAttr,{|a|a[1]=="value"}) ) != 0
                  DO WHILE Substr( xText, nPosS, 1 ) $ e" \t\r\n"; nPosS ++; ENDDO
                  IF Substr( xText, nPosS, 9 ) == "<![CDATA["
                     nPosS += 9
                     IF ( nPos2 := hb_At( "]]>", xText, nPosS ) ) == 0
                        ::lError := .T. ; EXIT
                     ENDIF
                     IF nPos1 > nPosA // + 1
                        aText[n] += hbxml_preLoad( Substr( xText, nPosA, nPos1 - nPosA ) )
                     ENDIF
                     hced_CrStru( Self, aAttr, ::aStru[n], aText[n], cClsname, cVal := aAttr[i,2], ;
                           Substr( xText, nPosS, nPos2 -nPosS ) )
                     aStru := Atail( ::aStru[n] )
                     aStru[OB_ACCESS] := hwg_SetBit( aStru[OB_ACCESS], BIT_CLCSCR )
                     Aadd( aStru, Nil )
                     aText[n] += cVal
                     nPosS := nPos2 + 3
                     DO WHILE Substr( xText, nPosS, 1 ) $ e" \t\r\n"; nPosS ++; ENDDO
                     IF Substr( xText, nPosS, 7 ) == "</span>"
                        nPosA := nPosS := nPos2 := nPosS + 7
                        lSpan := .F.
                     ELSE
                        ::lError := .T. ; EXIT
                     ENDIF
                  ELSE
                     ::lError := .T. ; EXIT
                  ENDIF
               ENDIF

               IF nPos1 > nPosA // + 1
                  aText[n] += hbxml_preLoad( Substr( xText, nPosA, nPos1 - nPosA ) )
               ENDIF

            ELSEIF cTagName == "a"
               IF ( !lDiv .AND. !lTd ) .OR. lSpan .OR. lA ; ::lError := .T. ; EXIT ; ENDIF
               lA := .T.
               nPosS := nPos2 + 1
               IF nPos1 > nPosA // + 1
                  aText[n] += hbxml_preLoad( Substr( xText, nPosA, nPos1 - nPosA ) )
               ENDIF

            ELSEIF cTagName == "style"
               IF lDiv .OR. lTable .OR. lStyle ; ::lError := .T. ; EXIT ; ENDIF
               lStyle := .T.
               nPosS := nPos2 + 1

            ELSEIF cTagName == "img"
               IF lDiv ; ::lError := .T. ; EXIT ; ENDIF
               cVal := Iif( (i:=Ascan(aAttr,{|a|a[1]=="align"}))==0, Nil, aAttr[i,2] )
               nAlign := Iif( Empty(cVal).or.cVal=="left", 0, Iif(cVal=="right", 2, 1 ) )
               cVal := Iif( (i:=Ascan(aAttr,{|a|a[1]=="src"}))==0, "", aAttr[i,2] )
               xVal := Iif( Empty(cVal) .OR. Left(cVal,1) == "#", Nil, Iif( ::bImgLoad==Nil, HBitmap():AddFile(cVal), Eval(::bImgLoad,cVal) ) )
               IF !Empty( xVal )
                  Aadd( ::aImages, xVal )
               ENDIF
               aStru := { "img", xVal, cClsName,,, cVal, nAlign }
               aStru[OB_ACCESS] := hced_ReadAccInfo( Iif( (i:=Ascan(aAttr,{|a|a[1]=="access"}))==0, "", aAttr[i,2] ) )
               IF (i := Ascan( aAttr,{|a|a[1]=="id"} )) != 0
                  aStru[OB_ID] := aAttr[i,2]
               ENDIF
               n ++
               IF Empty( nFrom )
                  Aadd( aText, "" )
                  Aadd( ::aStru, { aStru } )
               ELSE
                  Aadd( aText, Nil ); AIns( aText, n ); aText[n] := ""
                  Aadd( ::aStru, Nil ); AIns( ::aStru, n ); ::aStru[n] := { aStru }
               ENDIF
               IF Left(cVal,1) == "#"
                  Aadd( aImg, Atail(::aStru)[1] )
               ENDIF

            ELSEIF cTagName == "td"
               IF !lTr .OR. lTd ; ::lError := .T. ; EXIT ; ENDIF
               lTd := .T.
               nPosA := nPos2 + 1
               i := Iif( (i:=Ascan(aAttr,{|a|a[1]=="colspan"}))==0, 0, Val(aAttr[i,2]) )
               j := Iif( (j:=Ascan(aAttr,{|a|a[1]=="rowspan"}))==0, 0, Val(aAttr[j,2]) )
               Aadd( ::aStru[n,1,OB_OB], { "td", {}, cClsName, {}, i, j, Nil, Array(4,AL_LENGTH), 0, 1, 0, 1, 1, 1, 1, 1, {1,1}, {0,0}, {0,0}, 0, 0, 0, 0 } )
               iTd := Len( ::aStru[n,1,OB_OB] )
               aStruBack := ::aStru
               ::aStru := aStruBack[ n,1,OB_OB,iTd,2 ]
               aTextBack := aText
               aText := aStruBack[ n,1,OB_OB,iTd,OB_ATEXT ]
               nBack := n
               n := 0
               nFromBack := nFrom
               nFrom := Nil

            ELSEIF cTagName == "tr"
               IF !lTable .OR. lTr ; ::lError := .T. ; EXIT ; ENDIF
               lTr := .T.
               n ++
               aStru := Iif( n-nLTable==1, {"tr",{},cClsName,1,0,aStruTbl}, ;
                     {"tr",{},cClsName,n-nLTable,0} )
               IF lInsRows .AND. Len(aStruTbl[OB_OB]) != nInsCols
                  ::lError := .T. ; EXIT
               ENDIF
               IF Empty( nFrom )
                  Aadd( aText, "" )
                  Aadd( ::aStru, { aStru } )
               ELSE
                  IF aStru[OB_TRNUM] == 1
                     //aStru[OB_TBL] := ::aStru[n,1,OB_TBL]
                     ::aStru[n,1] := ASize( ::aStru[n,1],OB_TBL-1 )
                  ENDIF
                  Aadd( aText, Nil ); AIns( aText, n ); aText[n] := ""
                  Aadd( ::aStru, Nil ); AIns( ::aStru, n ); ::aStru[n] := { aStru }
               ENDIF

            ELSEIF cTagName == "col"
               IF !lTable .OR. lTr ; ::lError := .T. ; EXIT ; ENDIF
               IF lInsRows
                  nInsCols ++
               ELSE
                  cVal := Iif( (i:=Ascan(aAttr,{|a|a[1]=="width"}))==0, "", aAttr[i,2] )
                  Aadd( aStruTbl[OB_OB], ;
                     { Iif( Right(cVal,1)=='%',-Val(cVal),Val(cVal) ), 0, 0 } )
               ENDIF

            ELSEIF cTagName == "table"
               IF lTable ; ::lError := .T. ; EXIT ; ENDIF
               lTable := .T.
               IF lAdd .AND. !Empty( nFrom ) .AND. n == nFrom-1 .AND. ;
                     Valtype( ::aStru[nFrom,1,OB_TYPE] ) == "C" .AND. ;
                     ::aStru[nFrom,1,OB_TYPE] == "tr"
                  //::lError := .T. ; EXIT
                  nLTable := nFrom - ::aStru[nFrom,1,OB_TRNUM]
                  lInsRows := .T.
                  nInsCols := 0
                  aStruTbl := ::aStru[nLTable+1,1,OB_TBL]
               ELSE
                  nLTable := n
                  cVal := Iif( (i:=Ascan(aAttr,{|a|a[1]=="align"}))==0, Nil, aAttr[i,2] )
                  nAlign := Iif( Empty(cVal).or.cVal=="left", 0, Iif(cVal=="right", 2, 1 ) )
                  cVal := Iif( (i:=Ascan(aAttr,{|a|a[1]=="width"}))==0, "", aAttr[i,2] )
                  aStruTbl :=  { "tbl", {}, cClsName, ;
                     Iif( Right(cVal,1)=='%',-Val(cVal),Val(cVal) ), nALign }
               ENDIF

            ELSEIF cTagName == "binary"
               IF lDiv .OR. lTable .OR. lStyle ; ::lError := .T. ; EXIT ; ENDIF
               lBin := .T.
               nPosS := nPos2 + 1
               cClsName := Iif( (i:=Ascan(aAttr,{|a|a[1]=="id"}))==0, Nil, aAttr[i,2] )

            ENDIF
         ENDIF
         IF !::ReadTag( cTagName, aAttr )
            ::lError := .T.
            EXIT
         ENDIF
      ENDDO
      hbxml_SetEntity()
   ENDIF
   IF ::lError
      IF !lAdd
         ::aStru := { { {0,0,Nil} } }
         RETURN ::Super:SetText( , cPageIn, cPageOut )
      ELSE
         RETURN Nil
      ENDIF
   ENDIF
   FOR i := 1 TO Len( aImg )
      cVal := Substr( aImg[i,OB_HREF], 2 )
      IF ( n := Ascan( ::aBin, {|a|a[1]==cVal} ) ) > 0
         aImg[i,2] := ::aBin[n,3]
      ENDIF
   NEXT
   
   RETURN ::Super:SetText( aText, cPageIn, cPageOut )

#ifdef __PLATFORM__UNIX
   #define MESS_CHAR  WM_KEYDOWN
#else
   #define MESS_CHAR  WM_CHAR
#endif
METHOD onEvent( msg, wParam, lParam ) CLASS HCEdiExt
   LOCAL nRes := -1, nL, aStruTbl, iTd := 0, j, nIndent, nBoundL, nBoundR, nBoundT, nKey, nLine := 0, lInv := .F.
   LOCAL aPointC := {0,0}, aTbl1, aTbl2, lTab := .F., aPC, lChg := .F.
   LOCAL lReadOnly := ::lReadOnly, lInsert := ::lInsert, lNoPaste := ::lNoPaste, lProtected := .F.
   LOCAL nlM1 := ::aPointM1[P_Y], nlM2 := ::aPointM2[P_Y]

   //hwg_writelog( "oneve "+str(hwg_PtrToUlong(::hedit))+" "+ str(msg) )
   IF Ascan( aMsgs, msg ) > 0
      IF !Empty(::nLineC)
         aPointC[P_Y] := nl := ::aPointC[P_Y]
         aPointC[P_X] := ::aPointC[P_X]
         IF !Empty( nL )
            IF Valtype( ::aStru[nL] ) != "A"
               DO WHILE nl > 0 .AND. Valtype( ::aStru[--nL] ) != "A"; ENDDO
               aPointC[P_Y] := ::aPointC[P_Y] := nl
               aPointC[P_X] := ::aPointC[P_X] := 1 //Len( ::aText[nl] )
            ENDIF
            IF Valtype( ::aStru[nL,1,OB_TYPE] ) != "N"
               IF ::aStru[nL,1,1] == "tr"
                  aTbl1 := aStruTbl := ::aStru[nL-::aStru[nL,1,OB_TRNUM]+1,1,OB_TBL]
               ELSEIF ::aStru[nL,1,1] == "img"
                  IF msg == MESS_CHAR 
                     IF ( nKey := hwg_PtrToUlong( wParam ) ) == VK_RETURN
                        IF nL == 1
                          ::AddLine( nL )
                          ::aText[nL] := ""
                        ELSE
                          ::AddLine( nL+1 )
                          ::aText[nL+1] := ""
                        ENDIF
                        ::Paint( .F. )
                        msg := WM_KEYDOWN
                        wParam := VK_DOWN
                     ELSE
                        RETURN 0
                     ENDIF
                  ENDIF
               ENDIF
            ENDIF
         ENDIF
      ENDIF
      IF msg == WM_MOUSEMOVE .OR. msg == WM_LBUTTONDOWN .OR. msg == WM_LBUTTONUP ;
            .OR. msg == WM_RBUTTONDOWN
         aStruTbl := Nil
         nL := Iif( ( nL := hced_Line4Pos( Self, hwg_HiWord( lParam ) ) ) > 0, ::aLines[nL,AL_LINE], 0 )
         IF nL > 0 .AND. Valtype( ::aStru[nL,1,OB_TYPE] ) != "N" .AND. ::aStru[nL,1,OB_TYPE] == "tr"
            aTbl2 := aStruTbl := ::aStru[nL-::aStru[nL,1,OB_TRNUM]+1,1,OB_TBL]
            IF msg == WM_MOUSEMOVE .AND. ::lMDown
               IF nlM1 != 0 .AND. nlM2 != 0 .AND. nL != nlM1                 
                  ::aStru[nL,1,OB_OPT] := TROPT_SEL
                  ::aPointM2[P_Y] := nL; ::aPointM2[P_X] := 1
                  hced_Invalidaterect( ::hEdit, 0, 0, 0, ::nClientWidth, ::nHeight )
                  RETURN nRes
               ELSEIF ::aTdSel[2] != 0 .AND. ( ::aTdSel[2] != nL .OR. ::aTdSel[1] != ::nPosC )
                  ::aStru[nL,1,OB_OPT] := ::aStru[::aTdSel[2],1,OB_OPT] := TROPT_SEL
                  ::aPointM1[P_Y] := ::aTdSel[2]; ::aPointM1[P_X] := 1
                  ::aPointM2[P_Y] := nL; ::aPointM2[P_X] := 1
                  hced_Invalidaterect( ::hEdit, 0, 0, 0, ::nClientWidth, ::nHeight )
                  RETURN nRes
               ENDIF
            ENDIF
         ENDIF
      ENDIF
      IF !Empty( aStruTbl )
         IF msg == WM_MOUSEMOVE.OR. msg == WM_LBUTTONDOWN .OR. msg == WM_LBUTTONUP ;
               .OR. msg == WM_RBUTTONDOWN .OR. msg == WM_CHAR .OR. msg == WM_KEYDOWN
            iTd := ::nPosC
            nKey := hwg_PtrToUlong( wParam )
            IF msg == WM_MOUSEMOVE.OR. msg == WM_LBUTTONDOWN .OR. msg == WM_LBUTTONUP ;
                  .OR. msg == WM_RBUTTONDOWN
               iTd := hced_td4Pos( Self, nL, hwg_LoWord( lParam ) )
               IF msg == WM_LBUTTONDOWN .OR. msg == WM_RBUTTONDOWN
                  ::nLineC := hced_Line4Pos( Self, hwg_HiWord( lParam ) )
                  ::nPosC := iTd
                  ::PCopy( { ::nPosC, ::aLines[::nLineC,AL_LINE] }, ::aPointC )
               ENDIF
            ENDIF
            IF msg == MESS_CHAR  .AND. nKey == VK_TAB
               lTab := .T.
            ELSE
               nBoundL := ::nBoundL; nBoundR := ::nBoundR; nBoundT := ::nBoundT
               ::nBoundL := aStruTbl[OB_OB,itd,OB_CLEFT]
               j := Iif( ::aStru[nL,1,OB_OB,iTd,OB_COLSPAN] > 1, ::aStru[nL,1,OB_OB,iTd,OB_COLSPAN]-1, 0 )
               ::nBoundR := aStruTbl[OB_OB,itd+j,OB_CRIGHT]
               ::nBoundT := ::aLines[::nLineC,AL_Y1]
               nIndent := ::nIndent
               ::nIndent := 0
               ::LoadEnv( nL, iTd )
               IF msg == WM_KEYDOWN
                  nLine := hced_LineNum( Self, ::nLineC )
               ENDIF
            ENDIF
         ENDIF
      ENDIF
      IF !lTab
         aPC := ::PCopy( ::aPointC )
         IF !::lSupervise .AND. !Empty( j := hced_getAccInfo( Self, ::aPointC ) )
            lProtected := .T.
            IF hwg_checkBit( j, 2 )
               ::lReadOnly := .T.
            ENDIF
            IF hwg_checkBit( j, 3 )
               IF ( msg == MESS_CHAR .OR. msg == WM_KEYDOWN ) .AND. ;
                     ( ( nKey := hwg_PtrToUlong( wParam ) ) == VK_BACK .OR. nKey == VK_DELETE )
                  msg := 0
               ENDIF
               ::lInsert := .F.
               ::lNoPaste := .T.
            ENDIF
            IF hwg_checkBit( j, 4 ) .AND. msg == MESS_CHAR .AND. hwg_PtrToUlong( wParam ) == VK_RETURN
               msg := 0
            ENDIF
         ENDIF
         nRes := ::Super:onEvent( msg, wParam, lParam )
         IF lProtected
            ::lReadOnly := lReadOnly
            ::lInsert := lInsert
            ::lNoPaste := lNoPaste
         ENDIF
         lChg := ( ::aPointC[P_X] != aPC[P_X] .OR. ::aPointC[P_Y] != aPC[P_Y] )
         IF iTd > 0
            IF msg == WM_KEYDOWN .AND. nLine != hced_LineNum( Self, ::nLineC )
               nLine := -1
            ENDIF
            IF !Empty( ::aPointM2[P_Y] )
               ::aTdSel[1] := iTd
               ::aTdSel[2] := nL
            ELSEIF msg == WM_LBUTTONDOWN .OR. msg == WM_LBUTTONUP .OR. msg == WM_KEYDOWN
               ::aTdSel[2] := 0
            ENDIF
            ::RestoreEnv( nL, iTd )
            ::nBoundL := nBoundL; ::nBoundT := nBoundT; ::nBoundR := nBoundR
            ::nIndent := nIndent
            IF msg == WM_KEYDOWN .AND. nLine > 0
               IF nKey == VK_DOWN
                  ::LineDown()
               ELSEIF nKey == VK_UP
                  ::LineUp()
               ENDIF
            ENDIF
         ENDIF
      ELSE
         IF iTd < Len( ::aStru[nL,1,OB_OB] )
            ::SetCaretPos( SETC_COORS, aStruTbl[OB_OB,iTd+1,OB_CLEFT]+2, ::aLines[::nLineC,AL_Y1]+2 )
         ELSEIF nL < ::nTextLen
            hced_SetCaretPos( ::hEdit, ::nMarginL, ::aLines[::nLineC,AL_Y1]+2 )
            ::LineDown()
         ENDIF
         ::lSetFocus := .T.
      ENDIF
      IF aPointC[P_Y] != 0 .AND. ( aPointC[P_X] != ::aPointC[P_X] .OR. aPointC[P_Y] != ::aPointC[P_Y] )
         IF !Empty( aTbl1 )
            IF !Empty( ::aStru[aPointC[P_Y],1,OB_OB,aPointC[P_X],OB_APM2] )
               ::PCopy( , ::aStru[aPointC[P_Y],1,OB_OB,aPointC[P_X],OB_APM2] )
               lInv := .T.
            ENDIF
         ELSEIF !Empty( aTbl2 )
            IF !Empty( ::aPointM2[P_Y] )
               ::PCopy( , ::aPointM2 )
               lInv := .T.
            ENDIF
         ENDIF
         IF Empty( aTbl2 ) .OR. Empty( ::aStru[::aPointC[P_Y],1,OB_OB,::aPointC[P_X],OB_APM2,P_Y] )
            ::aTdSel[2] := 0
         ENDIF
         IF !lChg .AND. ::bChangePos != Nil
            Eval( ::bChangePos, Self )
         ENDIF
      ENDIF
      IF !Empty(nlM2) .AND. ( Empty(::aPointM2[P_Y]) .OR. msg == WM_LBUTTONDOWN )
         IF nlM1 > nlM2
            nL := nlM1; nlM1 := nlM2; nlM2 := nlM1
         ENDIF
         FOR nL := nlM1 TO nlM2
            IF nL <= ::nTextLen .AND. Valtype( ::aStru[nL,1,OB_TYPE] ) != "N" .AND. ::aStru[nL,1,OB_TYPE] == "tr"
               ::aStru[nL,1,OB_OPT] := 0
               lInv := .T.
            ENDIF
         NEXT
      ENDIF
      IF lInv
         hced_Invalidaterect( ::hEdit, 0, 0, 0, ::nClientWidth, ::nHeight )
      ENDIF
   ENDIF

   //hwg_writelog( "oneve10" )
   RETURN nRes

METHOD PaintLine( hDC, yPos, nLine, lUse_aWrap, nRight ) CLASS HCEdiExt

   LOCAL nL := ::nLineF+nLine-1, aHili, aHiliTD, aLine, aStru := ::aStru[nL,1], i, j, aStruTbl
   LOCAL nMargL, nMargR, nIndent, nAlign, nBoundL, nBoundR, tColor, bColor, bColorCur, nDefFont
   LOCAL iCol, iTd, yPosMax := 0, yPosB := yPos, nBorder := 0, nTWidth, nWidth
   LOCAL oPrinter, lFormat := !Empty( ::nDocFormat ), x1, x2, aTD
   LOCAL nsec := seconds()

   IF ::lPrinting
      oPrinter := hDC
      hDC := Nil
   ENDIF
   nWidth := Iif( lFormat, ::nDocWidth, ::nClientWidth - :: nBoundL )
   IF Valtype( aStru[OB_TYPE] ) == "N"
      IF !Empty( aStru[OB_CLS] ) .AND. hb_hHaskey( ::aHili,aStru[OB_CLS] )
         aHili := ::aHili[aStru[OB_CLS]]
         nMargL := ::nMarginL; nMargR := ::nMarginR; nIndent := ::nIndent; nAlign := ::nAlign; nBoundL := ::nBoundL
         IF !Empty( aHili[4] )
            ::nMarginL := Iif( aHili[4] >= 0, aHili[4], Int( -aHili[4] * nWidth / 100 ) ) + Iif( lFormat, nMargL, 0 )
         ENDIF
         IF !Empty( aHili[5] )
            ::nMarginR := Iif( aHili[5] >= 0, aHili[5], Int( -aHili[5] * nWidth / 100 ) )  + Iif( lFormat, nMargR, 0 )
         ENDIF
         IF !Empty( aHili[6] )
            ::nIndent := Iif( aHili[6] >= 0, aHili[6], Int( -aHili[6] * nWidth / 100 ) ) + Iif( lFormat, nMargL, 0 )
         ENDIF
         IF !Empty( aHili[7] )
            ::nAlign := aHili[7]
         ENDIF
         IF !Empty( aHili[8] )
            nBorder := aHili[8]:width
            ::nBoundL += nBorder
            ::nMarginR += nBorder
         ENDIF

         IF aHili[1] != Nil .AND. aHili[1] > 0
            nDefFont := ::nDefFont
            ::nDefFont := aHili[1]
         ENDIF
         IF !Empty( hDC ) .AND. ( aHili[2] != Nil .OR. aHili[3] != Nil )
            tColor := ::tColor; bColor := ::bColor; bColorCur := ::bColorCur
            IF aHili[2] != Nil
               ::tColor := aHili[2]
            ENDIF
            IF aHili[3] != Nil
               ::bColor := aHili[3]
               IF ::bColorCur == bColor
                  ::bColorCur := ::bColor
               ENDIF
            ENDIF
            hced_Setcolor( ::hEdit, ::tcolor, ::bColor )
         ENDIF
         IF !Empty( hDC )
            hced_SetPaint( ::hEdit, hDC )
         ENDIF
      ENDIF
      IF ::lPrinting
         yPos := ::Super:PrintLine( oPrinter, yPos, nLine )
      ELSE
         yPos := ::Super:PaintLine( hDC, yPos, nLine, lUse_aWrap, nRight )
      ENDIF

      IF !Empty( aHili )
         IF aHili[8] != Nil
            x1 := ::nBoundL + ::nMarginL - aHili[8]:width
            x2 := nWidth - Iif( lFormat,0,::nMarginR )
            IF !Empty( hDC )
               i := hwg_Selectobject( hDC, aHili[8]:handle )
               hwg_Drawline( hDC, x1, yPosB, x1, yPos )
               hwg_Drawline( hDC, x2, yPosB, x2, yPos )
               hwg_Drawline( hDC, x1, yPosB, x2, yPosB )
               hwg_Drawline( hDC, x1, yPos, x2, yPos )
               hwg_Selectobject( hDC, i )
            ELSEIF ::lPrinting
               oPrinter:Line( x1, yPosB, x1, yPos, aHili[8] )
               oPrinter:Line( x2, yPosB, x2, yPos, aHili[8] )
               oPrinter:Line( x1, yPosB, x2, yPosB, aHili[8] )
               oPrinter:Line( x1, yPos, x2, yPos, aHili[8] )
            ENDIF
         ENDIF
         IF !Empty( hDC )
            IF ( aHili[2] != Nil .OR. aHili[3] != Nil )
               ::tColor := tColor; ::bColor := bColor; ::bColorCur := bColorCur
               hced_Setcolor( ::hEdit, ::tcolor, ::bColor )
            ENDIF
         ENDIF
         ::nMarginL := nMargL; ::nMarginR := nMargR; ::nIndent := nIndent; ::nAlign := nAlign; ::nBoundL := nBoundL
         IF aHili[1] != Nil .AND. aHili[1] > 0
            ::nDefFont := nDefFont
         ENDIF
         yPos += nBorder
      ENDIF
   ELSEIF aStru[OB_TYPE] == "img"
      IF nRight == Nil; nRight := nWidth; ENDIF
      IF ::lPrinting
         aLine := Array( AL_LENGTH )
      ELSE
         aLine := hced_Aline( Self )
      ENDIF
      aLine[AL_Y1] := aLine[AL_Y2] := yPos
      aLine[AL_LINE] := nL
      aLine[AL_FIRSTC] := aLine[AL_SUBL] := 1
      aLine[AL_X1] := aLine[AL_X2] := ::nBoundL + ::nMarginL
      aLine[AL_NCHARS] := 1
      IF !Empty( aStru[OB_OB] )
         nTWidth := aStru[OB_OB]:nWidth
         aLine[AL_X1] += Iif( Empty(aStru[OB_IALIGN]), 0, Iif( aStru[OB_IALIGN]==2, nRight-aLine[AL_X1]-nTWidth, Round( (nRight-aLine[AL_X1]-nTWidth) / 2, 0 ) ) )
         aLine[AL_X2] := aLine[AL_X1] + nTWidth
         aLine[AL_Y2] := yPos + aStru[OB_OB]:nHeight
         IF !Empty( aStru[OB_CLS] ) .AND. hb_hHaskey( ::aHili,aStru[OB_CLS] )
            aHili := ::aHili[aStru[OB_CLS]]
            IF !Empty( aHili[8] )
               nBorder := aHili[8]:width
            ENDIF
         ENDIF
         IF !Empty( hDC )
            IF !Empty( ::aPointM2[P_Y] ) .AND. ::aPointM2[P_Y] >= nL .AND. ::aPointM1[P_Y] <= nL
               hced_Setcolor( ::hEdit,, ::bColorSel )
               hced_FillRect( ::hEdit, aLine[AL_X1], aLine[AL_Y1], ::nBoundR, aLine[AL_Y2] )
               hced_Setcolor( ::hEdit,, ::bColor )
            ENDIF
            hwg_Drawbitmap( hDC, aStru[OB_OB]:handle,, aLine[AL_X1]+nBorder, yPos+nBorder, nTWidth, aStru[OB_OB]:nHeight )
            IF nBorder > 0
               i := hwg_Selectobject( hDC, aHili[8]:handle )
               hwg_Rectangle( hDC, aLine[AL_X1], aLine[AL_Y1], aLine[AL_X2]+nBorder, aLine[AL_Y2]+nBorder )
               hwg_Selectobject( hDC, i )
            ENDIF
         ELSEIF ::lPrinting
            oPrinter:Bitmap( aLine[AL_X1]+nBorder, yPos+nBorder, aLine[AL_X1]+nBorder+nTWidth-1, yPos+nBorder+aStru[OB_OB]:nHeight-1,, aStru[OB_OB]:handle, aStru[OB_OB]:name )
            IF nBorder > 0
               oPrinter:Box( aLine[AL_X1], aLine[AL_Y1], aLine[AL_X2]+nBorder, aLine[AL_Y2]+nBorder, aHili[8] )
            ENDIF
         ENDIF
         yPos += aStru[OB_OB]:nHeight + nBorder * 2
         aLine[AL_Y2] := yPos
      ENDIF
   ELSEIF aStru[OB_TYPE] == "tr"
      aStruTbl := ::aStru[nL-aStru[OB_TRNUM]+1,1,OB_TBL]
      nBoundL := ::nBoundL; nBoundR := ::nBoundR
      nMargL := ::nMarginL; nMargR := ::nMarginR

      IF !Empty( aStruTbl[OB_CLS] ) .AND. hb_hHaskey( ::aHili,aStruTbl[OB_CLS] )
         aHili := ::aHili[aStruTbl[OB_CLS]]
         IF !Empty( aHili[8] )
            nBorder := aHili[8]:width
         ENDIF
      ENDIF
      IF ( i := aStruTbl[OB_TWIDTH] ) == 0 .OR. i == -100
         nTWidth := nWidth - nBorder * ( Len(aStruTbl[OB_OB])+1 )
      ELSE
         nTWidth := Iif( i>0,i,Round(nWidth*(-i)/100,0) ) - nBorder * ( Len(aStruTbl[OB_OB])+1 )
         ::nBoundL += Iif( Empty(aStruTbl[OB_TALIGN]), 0, Iif( aStruTbl[OB_TALIGN]==2, nWidth - nTWidth, Round( (nWidth - nTWidth) / 2, 0 ) ) )
      ENDIF

      aLine := hced_Aline( Self )
      aLine[AL_Y1] := yPos
      aLine[AL_LINE] := nL
      aLine[AL_FIRSTC] := aLine[AL_SUBL] := 1
      aLine[AL_X1] := ::nBoundL
      aLine[AL_X2] := ::nBoundL + nTWidth + nBorder * 2
      aLine[AL_NCHARS] := 1

      nIndent := ::nIndent
      ::nIndent := 0

      iCol := 0
      // Draw cells of a table row
      aTD := Array( Len( aStru[OB_OB] ) )
      FOR iTd := 1 TO Len( aStru[OB_OB] )
         iCol ++
         ::LoadEnv( nL, iTd, !Empty( hDC ) )
         ::nBoundL += nBorder
         IF iCol > 1
           i := aStruTbl[ OB_OB,iCol-1,OB_CWIDTH ]
           ::nBoundL += Iif( i>0, i, Round( nTWidth*(-i)/100,0 ) )
         ENDIF
         aStruTbl[ OB_OB,iCol,OB_CLEFT ] := ::nBoundL

         IF aStru[OB_OB,iTd,OB_COLSPAN] > 1
            i := 0
            iCol --
            FOR j := 1 TO aStru[OB_OB,iTd,OB_COLSPAN]
               i += aStruTbl[ OB_OB,++iCol,OB_CWIDTH ]
            NEXT
         ELSE
            i := aStruTbl[ OB_OB,iCol,OB_CWIDTH ]
         ENDIF
         i := Iif( i>0, i, Round( nTWidth*(-i)/100,0 ) )

         aStruTbl[ OB_OB,iCol,OB_CRIGHT ] := ::nBoundR := ::nBoundL + i

         ::nLines := nLine := 0
         ::nMarginL := ::nMarginR := 0
         IF ::lPrinting
            ::nMarginL += ::nBoundL
         ENDIF

         IF !Empty( ::aText )
            IF ::lScan
               ::Scan( ,, hDC, ::nBoundR-::nBoundL, ::nHeight-yPos )
            ELSE
               DO WHILE ( ++nLine + ::nLineF - 1 ) <= ::nTextLen
                  IF ::lPrinting
                     yPos := ::PaintLine( oPrinter, yPos, nLine )
                  ELSE
                     //hwg_writelog( Iif(lUse_aWrap,"T ","F ") + str(aStruTbl[OB_OB,iCol,OB_CLEFT]) + " " + str(aStruTbl[OB_OB,iCol,OB_CWIDTH]) + " " + str(aStruTbl[OB_OB,iCol,OB_CRIGHT]) )
#ifdef __PLATFORM__UNIX
                     x1 := -1
                     IF !Empty( hDC ) .AND. ( nl != ::aEnv[OB_APC,P_Y] .OR. iTd != ::aEnv[OB_APC,P_X] )
                        x1 := hced_getXCaretPos( ::hEdit )
                        x2 := hced_getYCaretPos( ::hEdit )
                        hced_setCaretPos( ::hEdit, -10, -10 )
                     ENDIF
#endif
                     yPos := ::PaintLine( hDC, yPos, nLine, lUse_aWrap, aStruTbl[OB_OB,iCol,OB_CRIGHT] )
#ifdef __PLATFORM__UNIX
                     IF x1 >= 0
                        hced_setCaretPos( ::hEdit, x1, x2 )
                     ENDIF
#endif
                  ENDIF
                  IF yPos + ( ::aLines[nLine,AL_Y2] - ::aLines[nLine,AL_Y1] ) > ::nHeight
                     EXIT
                  ENDIF
               ENDDO
            ENDIF
         ENDIF

         aTD[iTd] := yPos
         ::RestoreEnv( nL, iTd, !Empty( hDC ) )
         yPosMax := Max( yPos, yPosMax )
         yPos := yPosB
      NEXT

      yPos := yPosMax
      IF !Empty( hDC ) .OR. ::lPrinting
         IF nBorder > 0  // Drawing a border around the table
            x1 := aStruTbl[OB_OB,1,OB_CLEFT]-nBorder
            x2 := aStruTbl[OB_OB,1,OB_CLEFT]+nTWidth-1
            IF ::lPrinting
               iCol := 0
               FOR iTd := 1 TO Len( aStru[OB_OB] )
                  iCol ++
                  oPrinter:Line( aStruTbl[OB_OB,iCol,OB_CLEFT]-nBorder, ;
                     yPosB-nBorder, aStruTbl[OB_OB,iCol,OB_CLEFT]-nBorder, yPos, aHili[8] )
                  IF aStru[OB_OB,iTd,OB_COLSPAN] > 1
                     iCol += (aStru[OB_OB,iTd,OB_COLSPAN] - 1)
                  ENDIF
               NEXT
               oPrinter:Line( x2, yPosB-nBorder, x2, yPos, aHili[8] )
               IF aStru[OB_TRNUM] == 1
                  oPrinter:Line( x1, yPosB, x2, yPosB, aHili[8] )
               ENDIF
               oPrinter:Line( x1, yPos, x2, yPos, aHili[8] )
            ELSE
               i := hwg_Selectobject( hDC, aHili[8]:handle )
               iCol := 0
               FOR iTd := 1 TO Len( aStru[OB_OB] )
                  iCol ++
                  IF aStru[OB_OB,iCol,OB_BCLR] != ::bColor
                     hced_Setcolor( ::hEdit,, aStru[OB_OB,iCol,OB_BCLR] )
                     hced_FillRect( ::hEdit, aStruTbl[OB_OB,iCol,OB_CLEFT], ;
                        aTD[iTd], aStruTbl[OB_OB,iCol,OB_CRIGHT], yPos )
                  ENDIF
                  hwg_Drawline( hDC, aStruTbl[OB_OB,iCol,OB_CLEFT]-nBorder, ;
                     yPosB-nBorder, aStruTbl[OB_OB,iCol,OB_CLEFT]-nBorder, yPos )
                  IF aStru[OB_OB,iTd,OB_COLSPAN] > 1
                     iCol += (aStru[OB_OB,iTd,OB_COLSPAN] - 1)
                  ENDIF
               NEXT
               hced_Setcolor( ::hEdit,, ::bColor )
               hwg_Drawline( hDC, x2, yPosB-nBorder, x2, yPos )
               IF aStru[OB_TRNUM] == 1
                  hwg_Drawline( hDC, x1, yPosB, x2, yPosB )
               ENDIF
               hwg_Drawline( hDC, x1, yPos, x2, yPos )
               hwg_Selectobject( hDC, i )
            ENDIF
         ENDIF
      ENDIF

      yPos += nBorder
      aLine[AL_Y2] := yPos
      ::nMarginL := nMargL; ::nMarginR := nMargR
      ::nBoundL := nBoundL
      ::nBoundR := nBoundR
   ENDIF

   RETURN yPos

METHOD SetCaretPos( nt, p1, p2 ) CLASS HCEdiExt

   LOCAL nType, y1, x1, nL, nL2, nDefFont, aHili, xPos, lInfo := .F.
   LOCAL nLinePrev := ::nLineC, nPosPrev, aPointC
   LOCAL iTd, aStru, j, aStruTbl, nIndent, nBoundL, nBoundR, nBoundT, aRes

   nType := nt
   IF Valtype(nt) == "N"
      IF nt > 200
         lInfo := .T.
         nPosPrev := ::nPosC
         aPointC := ::PCopy( ::aPointC )
         nType -= 200
      ELSEIF nt > 100
         nType -= 100
      ENDIF
   ENDIF
   IF nType == SETC_COORS
      y1 := hced_Line4Pos( Self, p2 )
   ELSEIF nType == SETC_XYPOS
      y1 := p2
   ELSE
      y1 := ::nLineC
   ENDIF
   IF y1 == 0
      RETURN Nil
   ENDIF

   IF Empty( nType ) .OR. Empty( ::nLines ) .OR. Empty(nL := ::aLines[y1,AL_LINE])
      RETURN ::Super:SetCaretPos( nt, p1, p2 )
   ENDIF

   aStru := ::aStru[nL,1]
   IF Valtype( aStru[OB_TYPE] ) == "N"
      IF !Empty( aStru[OB_CLS] ) .AND. hb_hHaskey( ::aHili,aStru[OB_CLS] )
         aHili := ::aHili[aStru[OB_CLS]]
         IF aHili[1] != Nil .AND. aHili[1] > 0
            nDefFont := ::nDefFont
            ::nDefFont := aHili[1]
         ENDIF
      ENDIF
      ::Super:SetCaretPos( nt, p1, p2 )
      IF !Empty( aHili ) .AND. aHili[1] != Nil .AND. aHili[1] > 0
         ::nDefFont := nDefFont
      ENDIF
      IF lInfo
         x1 := ::aPointC[P_X]
         aStru := hced_Stru4Pos( ::aStru[nL], x1 )
         ::nLineC := nLinePrev; ::nPosC := nPosPrev; ::PCopy( aPointC, ::aPointC )
         RETURN { nL, x1, aStru }
      ELSE
         RETURN Nil
      ENDIF

   ELSEIF aStru[OB_TYPE] == "img"
      IF lInfo
         RETURN { nL, 1, Nil }
      ELSE
         ::nLineC := y1
         ::nPosC := 1
         ::PCopy( { ::aLines[::nLineC,AL_FIRSTC] + ::nPosF + ::nPosC - 2, ::aLines[::nLineC,AL_LINE] }, ::aPointC )
         hced_SetCaretPos( ::hEdit, ::aLines[::nLineC,AL_X1], ::aLines[::nLineC,AL_Y1] )
      ENDIF
   ELSEIF aStru[OB_TYPE] == "tr"
      IF nType == SETC_COORS
         xPos := p1
      ELSE
         xPos := hced_GetXCaretPos( ::hEdit )
      ENDIF
      aStruTbl := ::aStru[nL-aStru[OB_TRNUM]+1,1,OB_TBL]
      iTd := hced_td4Pos( Self, nL, xPos )

      nBoundL := ::nBoundL; nBoundR := ::nBoundR; nBoundT := ::nBoundT
      ::nBoundL := aStruTbl[OB_OB,itd,OB_CLEFT]
      j := Iif( aStru[OB_OB,iTd,OB_COLSPAN] > 1, aStru[OB_OB,iTd,OB_COLSPAN]-1, 0 )
      ::nBoundR := aStruTbl[OB_OB,itd+j,OB_CRIGHT]
      ::nBoundT := ::aLines[::nLineC,AL_Y1]
      nIndent := ::nIndent
      ::nIndent := 0

      IF lInfo
         nLinePrev := ::nLineC; nPosPrev := ::nPosC; aPointC := ::PCopy( ::aPointC )
      ENDIF
      ::LoadEnv( nL, iTd )
      IF nType == SETC_XYPOS
         p1 := p2 := 1
      ENDIF

      ::Super:SetCaretPos( nt, p1, p2 )

      IF lInfo
         aStru := Nil
         IF !Empty( nL2 := ::aLines[::nLineC,AL_LINE] )
            x1 := ::aPointC[P_X]
            aStru := hced_Stru4Pos( ::aStru[nL2], x1 )
            aRes := { nL, iTd, aStru, nL2, x1, ::aText, ::aStru[nL2] }
         ELSE
            aRes := { nL, iTd, aStru }
         ENDIF
      ENDIF
      ::RestoreEnv( nL, iTd )
      ::nBoundL := nBoundL; ::nBoundT := nBoundT; ::nBoundR := nBoundR
      ::nIndent := nIndent
      IF lInfo
         ::nLineC := nLinePrev; ::nPosC := nPosPrev; ::PCopy( aPointC, ::aPointC )
         RETURN aRes
      ELSE
         ::nLineC := y1
         ::nPosC := iTd
         ::PCopy( { iTd, nL }, ::aPointC )
      ENDIF

      RETURN Nil
   ENDIF
   IF !lInfo .AND. nLinePrev != ::nLineC
      IF nLinePrev <= ::nLines
         hced_Invalidaterect( ::hEdit, 0, 0, ::aLines[nLinePrev,AL_Y1], ::nClientWidth, ;
            ::aLines[nLinePrev,AL_Y2] )
      ENDIF
      hced_Invalidaterect( ::hEdit, 0, 0, ::aLines[::nLineC,AL_Y1], ::nClientWidth, ;
         ::aLines[::nLineC,AL_Y2] )
#ifdef __PLATFORM__UNIX
   ELSE
      hced_Invalidaterect( ::hEdit, 0, 0, ::aLines[nLinePrev,AL_Y1], ::nClientWidth, ;
         ::aLines[nLinePrev,AL_Y2] )
#endif
   ENDIF

   RETURN Nil

METHOD AddLine( nLine ) CLASS HCEdiExt

   ::Super:AddLine( nLine )
   IF Len( ::aStru ) != Len( ::aText )
      ASize( ::aStru, Len( ::aText ) )
   ENDIF
   AIns( ::aStru, nLine )
   ::aStru[nLine] := { { 0,0,Nil } }

   RETURN Nil

METHOD DelLine( nLine ) CLASS HCEdiExt

   ADel( ::aStru, nLine )

   RETURN ::Super:DelLine( nLine )

METHOD AddClass( cName, cSource ) CLASS HCEdiExt

   LOCAL i,  nPos, cProp, cValue, cClass
   LOCAL nColor, nBackg, name, lFont := .F., nFont := -1, cHeight, height, weight, Italic, Underline, Strike
   LOCAL nMargL, nMargR, nIndent, nAlign, oPen, aPen

   DO WHILE .T.
      IF ( i := At( ':', cSource ) ) == 0
         EXIT
      ENDIF
      cProp := Lower( Alltrim( Left( cSource,i-1 ) ) )
      IF ( nPos := hb_At( ';', cSource, i ) ) == 0
         nPos := Len( cSource ) + 1
      ENDIF
      cValue := AllTrim( Substr( cSource, i+1, nPos-i-1 ) )
      cSource := Substr( cSource, nPos + 1 )
      IF Asc( cValue ) == 34  // "
         cValue := Substr( cValue,2,Len(cValue)-2 )
      ENDIF
      IF cProp == "color"
         nColor := hced_x2Color( cValue )
      ELSEIF cProp == "background-color"
         nBackg := hced_x2Color( cValue )
      ELSEIF cProp == "font-family"
         name := cValue
         lFont := .T.
      ELSEIF cProp == "font-size"
         IF Right(cValue,1) == '%'
            height := Int( Val(cValue) * ::oFont:height / 100 )
         ELSE
            height := Val(cValue)
         ENDIF
         cHeight := cValue
         lFont := .T.
      ELSEIF cProp == "font-weight"
         weight := Iif( cValue=="bold", 700, 400 )
         lFont := .T.
      ELSEIF cProp == "font-style"
         italic := Iif( cValue=="italic", 255, 0 )
         lFont := .T.
      ELSEIF cProp == "text-decoration"
         IF cValue=="underline"
            Underline := 255
         ELSEIF cValue=="line-through"
            Strike := 255
         ELSE
            Strike := Underline := 0
         ENDIF
         lFont := .T.
      ELSEIF cProp == "text-indent"
         nIndent := Iif( Right(cValue,1)=='%', -Val(cValue), Val(cValue) )
      ELSEIF cProp == "text-align"
         nAlign := Iif( cValue=="center", 1, Iif( cValue=="right", 2, 0 ) )
      ELSEIF cProp == "margin-left"
         nMargL := Iif( Right(cValue,1)=='%', -Val(cValue), Val(cValue) )
      ELSEIF cProp == "margin-right"
         nMargR := Iif( Right(cValue,1)=='%', -Val(cValue), Val(cValue) )
      ELSEIF cProp == "border"
         aPen := hb_aTokens( cValue )
         oPen := HPen():Add( , Val(aPen[1]), Iif( Len(aPen)>2, hced_X2Color(aPen[3]) ,Nil) )
      ENDIF
   ENDDO
   IF lFont
      IF Empty( ::aFonts )
         ::AddFont( ::oFont )
      ENDIF
      nFont := ::AddFont( , Iif( name==Nil,::oFont:name,name ),, ;
           Iif( height==Nil,::oFont:height,height ), ;
           Iif( weight==Nil,::oFont:weight,weight ),,;
           Iif( italic==Nil,::oFont:italic,Italic ), ;
           Iif( Underline==Nil,::oFont:Underline,Underline ), ;
           Iif( Strike==Nil,::oFont:StrikeOut,Strike ) )
      ::aFonts[nFont]:cargo := cHeight
   ENDIF

   IF !Empty( cClass := hced_FindClass( ::aHili, { nFont, nColor, nBackg, nMargL, nMargR, nIndent, nAlign, oPen } ) )
      RETURN Iif( cClass==cName, Nil, cClass )
   ELSEIF hb_hHaskey( ::aHili, cName )
      i := Len( ::aHili )
      DO WHILE hb_hHaskey( ::aHili, ( cClass := "c" + Ltrim(Str( ++i )) ) )
      ENDDO
      ::SetHili( cClass, nFont, nColor, nBackg, nMargL, nMargR, nIndent, nAlign, oPen )
      RETURN cClass
   ENDIF

   ::SetHili( cName, nFont, nColor, nBackg, nMargL, nMargR, nIndent, nAlign, oPen )

   RETURN Nil

METHOD FindClass( xBase, xAttr, xNewClass ) CLASS HCEdiExt

   LOCAL aHili := Iif( !Empty(xBase), AClone(::aHili[xBase]), Array(HILI_LEN) )
   LOCAL i, cName, oFont := Iif( !Empty(aHili[1]).AND.aHili[1]>0, ::aFonts[aHili[1]], ::oFont )
   LOCAL lFont := .F., nfont, name, cVal, cHeight, height, weight, Italic, Underline, Strike
   LOCAL lPen := .F., nBWidth := 1, nBColor := 0

   IF Valtype( xAttr ) == "C"
      xAttr := { xAttr }
   ENDIF

   FOR i := 1 TO Len( xAttr )
      SWITCH Left( xAttr[i], 2 )
      CASE "ct" ; aHili[2] := Val( Substr( xAttr[i],3 ) )
         EXIT
      CASE "cb" ; aHili[3] := Val( Substr( xAttr[i],3 ) )
         EXIT
      CASE "ml" ; aHili[4] := Iif( Right(cVal:=Substr(xAttr[i],3),1) == '%', -Val(cVal), Val(cVal) )
         EXIT
      CASE "mr" ; aHili[5] := Iif( Right(cVal:=Substr(xAttr[i],3),1) == '%', -Val(cVal), Val(cVal) )
         EXIT
      CASE "ti" ; aHili[6] := Iif( Right(cVal:=Substr(xAttr[i],3),1) == '%', -Val(cVal), Val(cVal) )
         EXIT
      CASE "ta" ; aHili[7] := Val( Substr( xAttr[i],3 ) )
         EXIT
      CASE "fb" ; lFont := .T. ; weight := Iif( Substr(xAttr[i],3,1)=='-', 400, 700 )
         EXIT
      CASE "fi" ; lFont := .T. ; italic := Iif( Substr(xAttr[i],3,1)=='-', 0, 255 )
         EXIT
      CASE "fu" ; lFont := .T. ; Underline := Iif( Substr(xAttr[i],3,1)=='-', 0, 255 )
         EXIT
      CASE "fs" ; lFont := .T. ; Strike := Iif( Substr(xAttr[i],3,1)=='-', 0, 255 )
         EXIT
      CASE "fh" ; lFont := .T. ; cHeight := Substr( xAttr[i],3 )
         height := Iif( Right(cHeight,1) == '%', Int( Val(cHeight) * ::oFont:height / 100 ), Val(cHeight) )
         EXIT
      CASE "fn" ; lFont := .T. ; name := Substr( xAttr[i],3 )
         EXIT
      CASE "ff" ; lFont := .T. ; nfont := Val( Substr( xAttr[i],3 ) )
         EXIT
      CASE "bw" ; lPen := .T. ; nBWidth := Val( Substr( xAttr[i],3 ) )
         EXIT
      CASE "bc" ; lPen := .T. ; nBColor := Val( Substr( xAttr[i],3 ) )
         EXIT
      ENDSWITCH
   NEXT

   IF lFont
      IF !Empty( nfont )
         aHili[1] := nfont
         cHeight := Ltrim(Str(::aFonts[nfont]:height))
      ELSE
         aHili[1] := ::AddFont( , Iif( name==Nil,oFont:name,name ),, ;
              Iif( height==Nil,oFont:height,height ), ;
              Iif( weight==Nil,oFont:weight,weight ),,;
              Iif( italic==Nil,oFont:italic,Italic ), ;
              Iif( Underline==Nil,oFont:Underline,Underline ), ;
              Iif( Strike==Nil,oFont:StrikeOut,Strike ) )
      ENDIF
      ::aFonts[aHili[1]]:cargo := cHeight
   ENDIF
   IF lPen
      aHili[8] := Iif( nBWidth > 0, HPen():Add( , nBWidth, nBColor, Nil ), Nil )
   ENDIF

   cName := hced_FindClass( ::aHili, aHili )

   IF Empty( cName ) .AND. !Empty( xNewClass )
      IF Valtype( xNewClass ) == "L"
         i := Len( ::aHili )
         DO WHILE hb_hHaskey( ::aHili, ( xNewClass := "c" + Ltrim(Str( ++i )) ) )
         ENDDO
      ENDIF
      cName := xNewClass
      ::SetHili( cName, aHili[1], aHili[2], aHili[3], aHili[4], aHili[5], aHili[6], aHili[7], aHili[8] )
   ENDIF

   RETURN cName

METHOD SetHili( xGroup, xFont, tColor, bColor, nMargL, nMargR, nIndent, nAlign, oPen ) CLASS HCEdiExt

   LOCAL arr

   IF !hb_hHaskey( ::aHili, xGroup )
      ::aHili[xGroup] := Array( HILI_LEN )
   ENDIF
   arr := ::aHili[xGroup]

   arr[ 4 ] := nMargL
   arr[ 5 ] := nMargR
   arr[ 6 ] := nIndent
   arr[ 7 ] := nAlign
   arr[ 8 ] := oPen

   RETURN ::Super:SetHili( xGroup, xFont, tColor, bColor )

METHOD ChgStyle( P1, P2, xAttr, lDiv, PCell ) CLASS HCEdiExt

   LOCAL i, n1, n2
   LOCAL Pstart, Pend, aStru, nLTr, iTd

   IF P1 == Nil
      IF !Empty( ::aPointM2[P_Y] )
         P1 := ::aPointM1; P2 := ::aPointM2
      ELSEIF !Empty( nLTr := ::aTdSel[2] )
         aStru := ::aStru[nLTr,1,OB_OB, iTd := ::aTdSel[1]]
         IF !Empty( aStru[OB_APM2,P_Y] )
            ::LoadEnv( nLTr, iTd )
            P1 := aStru[OB_APM1]; P2 := aStru[OB_APM2]
         ENDIF
      ELSE
         RETURN Nil
      ENDIF
   ELSEIF PCell != Nil
      ::LoadEnv( nLTr := PCell[P_Y], iTd := PCell[P_X] )
   ENDIF
   IF ::Pcmp( P1, P2 ) < 0
      Pstart := ::PCopy( P1, Pstart )
      Pend := ::PCopy( P2, Pend )
   ELSE
      Pstart := ::PCopy( P2, Pstart )
      Pend := ::PCopy( P1, Pend )
   ENDIF

   ::lChgStyle := .T.
   ::Undo( Pstart[P_Y], Pstart[P_X], Pend[P_Y], Pend[P_X], 4, Nil )
   IF lDiv != Nil .AND. lDiv
      FOR i := Pstart[P_Y] TO Pend[P_Y]
         ::StyleDiv( i, xAttr )
      NEXT
   ELSE
      i := Pstart[P_Y]
      aStru := AClone( ::aStru[i] )

      hced_Stru4Pos( aStru, Pstart[P_X], @n1 )
      IF n1 > Len( aStru )
         ::StyleSpan( i, Pstart[P_X], Iif( i==Pend[P_Y], Pend[P_X]-1, hced_Len( Self,::aText[i]) ), xAttr )
      ELSE
         IF Pstart[P_X] < aStru[n1,1]
            ::StyleSpan( i, Pstart[P_X], Iif( i==Pend[P_Y], ;
               Min( Pend[P_X]-1,aStru[n1,1]-1 ), aStru[n1,1]-1 ), xAttr )
         ELSEIF Pstart[P_X] <= aStru[n1,2]
            ::StyleSpan( i, Pstart[P_X], Iif( i==Pend[P_Y], ;
               Min( Pend[P_X]-1,aStru[n1,2] ), aStru[n1,2] ), xAttr )
            IF Pend[P_X]-1 > aStru[n1,2]
               ::StyleSpan( i, aStru[n1,2]+1, Min( Pend[P_X]-1, ;
                     Iif(n1+1<=Len(aStru),aStru[n1+1,1]-1,Pend[P_X]-1) ), xAttr )
            ENDIF
            n1 ++
         ENDIF
         DO WHILE n1 <= Len( aStru )
            IF i == Pend[P_Y]
               IF Pend[P_X] < aStru[n1,1]
                  EXIT
               ENDIF
               ::StyleSpan( i, aStru[n1,1], Min( Pend[P_X]-1,aStru[n1,2] ), xAttr )
               IF n1 < Len( aStru )
                  ::StyleSpan( i, aStru[n1,2]+1, Min( Pend[P_X]-1,aStru[n1+1,1]-1 ), xAttr )
               ELSEIF aStru[n1,2] < Pend[P_X]
                  ::StyleSpan( i, aStru[n1,2]+1, Pend[P_X]-1, xAttr )
               ENDIF
            ELSE
               ::StyleSpan( i, aStru[n1,1], aStru[n1,2], xAttr )
               IF n1 < Len( aStru )
                  ::StyleSpan( i, aStru[n1,2]+1, aStru[n1+1,1]-1, xAttr )
               ELSEIF aStru[n1,2] < ( n2 := hced_Len( Self,::aText[i] ) )
                  ::StyleSpan( i, aStru[n1,2]+1, n2, xAttr )
               ENDIF
            ENDIF
            n1 ++
         ENDDO
      ENDIF
      FOR i := Pstart[P_Y]+1 TO Pend[P_Y]
         aStru := AClone( ::aStru[i] )
         IF i < Pend[P_Y]
            ::StyleSpan( i, 1, Iif(Len(aStru)>1,aStru[2,1]-1,hced_Len(Self,::aText[i])), xAttr )
            FOR n1 := 2 TO Len( aStru )
               ::StyleSpan( i, aStru[n1,1], aStru[n1,2], xAttr )
               IF n1 < Len( aStru )
                  ::StyleSpan( i, aStru[n1,2]+1, aStru[n1+1,1], xAttr )
               ELSEIF aStru[n1,2] < ( n2 := hced_Len( Self,::aText[i] ) )
                  ::StyleSpan( i, aStru[n1,2]+1, n2, xAttr )
               ENDIF
            NEXT
         ELSE
            ::StyleSpan( i, 1, Min( Pend[P_X], Iif(Len(aStru)>1,aStru[2,1]-1,hced_Len(Self,::aText[i])) ), xAttr )
            FOR n1 := 2 TO Len( aStru )
               IF Pend[P_X] < aStru[n1,1]
                  EXIT
               ENDIF
               IF Pend[P_X] < aStru[n1,2]
                  ::StyleSpan( i, aStru[n1,1], Pend[P_X], xAttr )
                  EXIT
               ELSE
                  ::StyleSpan( i, aStru[n1,1], aStru[n1,2], xAttr )
               ENDIF
               IF n1 < Len( aStru )
                  ::StyleSpan( i, aStru[n1,2]+1, Min( Pend[P_X],aStru[n1+1,1] ), xAttr )
               ELSEIF aStru[n1,2] < Pend[P_X]
                  ::StyleSpan( i, aStru[n1,2]+1, Pend[P_X], xAttr )
               ENDIF
            NEXT
         ENDIF
      NEXT
   ENDIF
   hced_CleanStru( Self, Pstart[P_Y], Pend[P_Y] )

   ::Scan( Pstart[P_Y], Pend[P_Y] )
   IF !Empty( iTd )
      ::RestoreEnv( nLTr, iTd )
   ENDIF
   ::Paint( .F. )
   ::SetCaretPos( SETC_XY )
   ::Refresh()

   ::lChgStyle := .F.
   ::lUpdated := .T.

   RETURN Nil

METHOD StyleSpan( nLine, nPos1, nPos2, xAttr, cHref, cId, nOpt ) CLASS HCEdiExt

   LOCAL aStru := ::aStru[nLine], n1, nPosTmp, xCls

   IF nPos2 < nPos1
      RETURN Nil
   ENDIF
   IF !::lChgStyle
      ::Undo( nLine, nPos1, nLine, nPos2, 4, Nil )
   ENDIF
   hced_Stru4Pos( aStru, nPos1, @n1, .T. )
   IF n1 > Len( aStru )
      AAdd( aStru, { nPos1, nPos2, ::FindClass( aStru[1,3], xAttr, .T. ) } )
      n1 := Len( aStru )
   ELSE
      IF nPos1 < aStru[n1,1]
         AAdd( aStru, Nil )
         AIns( aStru, n1 )
         aStru[n1] := { nPos1, nPos2, ::FindClass( aStru[1,3], xAttr, .T. ) }
      ELSE     
         IF nPos1 == aStru[n1,1] .AND. nPos2 == aStru[n1,2]
            aStru[n1,3] := ::FindClass( aStru[n1,3], xAttr, .T. )
         ELSE
            xCls := aStru[n1,3]
            IF nPos1 > aStru[n1,1]
               AAdd( aStru, Nil )
               AIns( aStru, n1 )
               aStru[n1] := { aStru[n1+1,1], nPos1-1, xCls }
               n1 ++
               aStru[n1,1] := nPos1
            ENDIF
            aStru[n1,3] := ::FindClass( xCls, xAttr, .T. )
            IF nPos2 < aStru[n1,2]
               nPosTmp := aStru[n1,2]
               aStru[n1,2] := nPos2
               n1 ++
               AAdd( aStru, Nil )
               AIns( aStru, n1 )
               aStru[n1] := { nPos2+1, nPosTmp, xCls }
            ENDIF
         ENDIF
      ENDIF
   ENDIF
   IF cHref != Nil
      Aadd( aStru[n1], cId )
      Aadd( aStru[n1], nOpt )
      Aadd( aStru[n1], cHRef )
   ELSEIF nOpt != Nil
      Aadd( aStru[n1], cId )
      Aadd( aStru[n1], nOpt )
   ELSEIF cId != Nil
      Aadd( aStru[n1], cId )
   ENDIF
   IF !::lChgStyle
      hced_CleanStru( Self, nLine, nLine )
      ::Scan( nLine, nLine )
      ::Paint( .F. )
      ::SetCaretPos( SETC_XY )
      ::Refresh()
   ENDIF
   ::lUpdated := .T.

   RETURN Nil

METHOD StyleDiv( nLine, xAttr, cClass ) CLASS HCEdiExt

   LOCAL cBase, lCell := .F.

   IF nLine == Nil; nLine := ::aPointC[P_Y]; ENDIF
   IF Valtype( ::aStru[nLine,1,OB_TYPE] ) == "C" .AND. ::aStru[nLine,1,OB_TYPE] == "tr"
      lCell := .T.
      cBase := ::aStru[nLine,1,OB_OB,::aPointc[P_X],OB_CLS]
   ELSE
      cBase := ::aStru[nLine,1,OB_CLS]
   ENDIF

   IF xAttr == Nil .AND. cClass == Nil
      RETURN Iif( Empty( cBase ), Nil, AClone( ::aHili[cBase] ) )
   ELSE
      IF !::lChgStyle
         ::Undo( nLine, 1, nLine, 1, 4, Nil )
      ENDIF

      IF cClass == Nil
         cClass := ::FindClass( cBase, xAttr, .T. )
      ENDIF
      IF lCell
         ::aStru[nLine,1,OB_OB,::aPointc[P_X],OB_CLS] := cClass
      ELSE
         ::aStru[nLine,1,OB_CLS] := cClass
      ENDIF
      IF !::lChgStyle
         hced_CleanStru( Self, nLine, nLine )
         ::Scan( nLine, nLine )
         ::Paint( .F. )
         ::SetCaretPos( SETC_XY )
         ::Refresh()
      ENDIF

   ENDIF
   ::lUpdated := .T.

   RETURN Nil

METHOD InsTable( xCols, nRows, nWidth, nAlign, xAttr ) CLASS HCEdiExt
   LOCAL nL, i, cClsName, nCols, aStruOB

   IF !Empty( xAttr )
      cClsName := ::FindClass( , xAttr, .T. )
   ENDIF
   nL := ::aPointC[P_Y]

   IF Valtype( ::aStru[nL,1,OB_TYPE] ) == "C"
      RETURN .F.
   ENDIF

   IF Valtype( xCols ) == "N"
      nCols := xCols
      aStruOB := Array( nCols )
      FOR i := 1 TO nCols
         aStruOB[i] := { - 100/nCols, 0, 0 }
      NEXT
   ELSE
      nCols := Len( xCols )
      aStruOB := Array( nCols )
      FOR i := 1 TO nCols
         aStruOB[i] := { xCols[i], 0, 0 }
      NEXT
   ENDIF

   IF !Empty( ::aText[nl] )
      ::InsText( ::aPointC, cNewLine )
      IF !Empty( ::aText[nl] )
         nl++
         ::AddLine( nL )
      ENDIF
   ENDIF

   ::InsRows( nL, nRows, nCols, .T. )

   // Add table description to the first row
   Aadd( ::aStru[nL,1], { "tbl", {}, cClsName, Iif(Empty(nWidth),-100,nWidth), nAlign } )
   ::aStru[nL,1,OB_TBL,OB_OB] := aStruOB

   hced_Invalidaterect( ::hEdit, 0, 0, 0, ::nClientWidth, ::nHeight )

   RETURN .T.

METHOD InsRows( nL, nRows, nCols, lNoAddline ) CLASS HCEdiExt
   LOCAL i, n, nRow

   IF Empty( lNoAddline )
      IF Valtype( ::aStru[nL,1,1] ) == "C" .AND. ::aStru[nL,1,1] == "tr"
         nRow := ::aStru[nL,1,OB_TRNUM] + 1
      ELSE
         nRow := 1
      ENDIF
      nL ++
      ::AddLine( nL )
   ELSE
      nRow := 1
   ENDIF
   IF nCols == Nil
      nCols := Len( ::aStru[nL-nRow+1,1,OB_TBL,OB_OB] )
   ENDIF
   FOR n := 1 TO nRows
      ::aStru[nL,1] :=  { "tr", {},, nRow, 0 }
      ::aText[nL] := ""
      FOR i := 1 TO nCols
         Aadd( ::aStru[nL,1,OB_OB], { "td", { { { 0,0,Nil } } }, Nil, {""}, 0, 0, {Nil}, Array(4,AL_LENGTH), 0, 1, 1, 1, 1, 1, 1, 1, {1,1}, {0,0}, {0,0}, 0, 0, 0, 0 } )
      NEXT
      IF n < nRows
         nRow ++
         nL ++
         ::AddLine( nL )
      ENDIF
   NEXT

   IF nL == ::nTextLen
      ::AddLine( nL+1 )
      ::aText[nL+1] := ""
   ENDIF
   DO WHILE ++nL <= ::nTextLen
      IF Valtype( ::aStru[nL,1,1] ) == "C" .AND. ::aStru[nL,1,1] == "tr"
         ::aStru[nL,1,OB_TRNUM] := ++nRow
      ELSE
         EXIT
      ENDIF
   ENDDO

   ::lUpdated := .T.

   RETURN .T.

METHOD InsCol( nL, iTd ) CLASS HCEdiExt

   LOCAL aStruCols, nCols, nWidth, i, n

   IF Empty( nL ) .OR. Valtype( ::aStru[nL,1,1] ) != "C" .OR. ::aStru[nL,1,1] != "tr"
      RETURN .F.
   ENDIF

   nL := nL - ::aStru[nL,1,OB_TRNUM] + 1
   aStruCols := ::aStru[nL,1,OB_TBL,OB_OB]
   nCols := Len( aStruCols ) + 1
   IF iTd == Nil
      iTd := nCols
   ENDIF
   Aadd( aStruCols, Nil )
   AIns( aStruCols, iTd )
   nWidth := Int( 100/nCols ) 
   aStruCols[iTd] := { -nWidth, 0, 0 }
   n := Int( nWidth/(nCols-1) )
   FOR i := 1 TO nCols
      IF i != iTd .AND. Abs(aStruCols[i,1]) > n
         aStruCols[i,1] := - (Abs(aStruCols[i,1])-n)
         nWidth -= n
      ENDIF
   NEXT
   IF nWidth > 0
      FOR i := 1 TO nCols
         IF i != iTd .AND. Abs(aStruCols[i,1]) > nWidth
            aStruCols[i,1] := - (Abs(aStruCols[i,1])-nWidth)
         ENDIF
      NEXT
   ENDIF

   DO WHILE Valtype( ::aStru[nL,1,1] ) == "C" .AND. ::aStru[nL,1,1] == "tr"
      aStruCols := ::aStru[nL,1,OB_OB]
      Aadd( aStruCols, Nil )
      AIns( aStruCols, iTd )
      aStruCols[iTd] := { "td", { { { 0,0,Nil } } }, Nil, {""}, 0, 0, {Nil}, Array(4,AL_LENGTH), 0, 1, 1, 1, 1, 1, 1, 1, {1,1}, {0,0}, {0,0} }
      nL++
   ENDDO

   ::lUpdated := .T.

   RETURN .T.

METHOD DelCol( nL, iTd ) CLASS HCEdiExt

   LOCAL aStruCols, nCols, nWidth, i, n

   IF Empty( nL ) .OR. Empty( iTd ) .OR. Valtype( ::aStru[nL,1,1] ) != "C" .OR. ::aStru[nL,1,1] != "tr"
      RETURN .F.
   ENDIF

   nL := nL - ::aStru[nL,1,OB_TRNUM] + 1
   aStruCols := ::aStru[nL,1,OB_TBL,OB_OB]
   nCols := Len( aStruCols )
   IF iTd > nCols
      RETURN .F.
   ENDIF

   nCols --
   n := Int( Abs(aStruCols[iTd,1]) / nCols )
   ADel( aStruCols, iTd )
   ASize( aStruCols, nCols )
   nWidth := 0
   FOR i := 1 TO nCols
      aStruCols[i,1] := - (Abs(aStruCols[i,1])+n)
      nWidth += n
   NEXT
   IF nWidth > 100
      aStruCols[1,1] := - (Abs(aStruCols[1,1])-(nWidth-100))
   ENDIF

   DO WHILE Valtype( ::aStru[nL,1,1] ) == "C" .AND. ::aStru[nL,1,1] == "tr"
      aStruCols := ::aStru[nL,1,OB_OB]
      ADel( aStruCols, iTd )
      ASize( aStruCols, nCols )
      nL++
   ENDDO

   ::lUpdated := .T.

   RETURN .T.

/* InsImage( cName, nAlign, xAttr, xBin, cExt ) - inserts an image in a current position - ::aPointC
 *    cName - a name of an image file
 *    nAlign - alignment ( 0, 1, 2 : Left, Center, Right )
 *    xAttr - attributes ( "bw2" - border width 2px )
 *    xBin - a string, an image file content - in case of embedded image
 *    cExt - an extention of an image file
 * In case of embedded image a <xBin> must present and <cName> may be omitted (default "img_..." name will be set)
 */
METHOD InsImage( cName, nAlign, xAttr, xBin, cExt ) CLASS HCEdiExt

   LOCAL nL, xVal, aStruTbl, iTd, nIndent, nBoundL, nBoundR, nBoundT, nLTr, cClsName, i, j

   IF !Empty( xAttr )
      cClsName := ::FindClass( , xAttr, .T. )
   ENDIF
   IF Empty( cExt ) .AND. !Empty( cName )
      cExt := hb_FNameExt( cName )
   ENDIF

   nL := ::aPointC[P_Y]

   IF Valtype( ::aStru[nL,1,OB_TYPE] ) == "C" .AND. ::aStru[nL,1,OB_TYPE] == "tr"
      aStruTbl := ::aStru[nL-::aStru[nL,1,OB_TRNUM]+1,1,OB_TBL]

      iTd := ::nPosC

      nBoundL := ::nBoundL; nBoundR := ::nBoundR; nBoundT := ::nBoundT
      ::nBoundL := aStruTbl[OB_OB,itd,OB_CLEFT]
      j := Iif( ::aStru[nL,1,OB_OB,iTd,OB_COLSPAN] > 1, ::aStru[nL,1,OB_OB,iTd,OB_COLSPAN]-1, 0 )
      ::nBoundR := aStruTbl[OB_OB,itd+j,OB_CRIGHT]
      ::nBoundT := ::aLines[::nLineC,AL_Y1]
      nIndent := ::nIndent
      ::nIndent := 0

      ::LoadEnv( nL, iTd )
      nLTr := nL
      nL := ::aPointC[P_Y]
   ENDIF

   IF Valtype( ::aStru[nL,1,OB_TYPE] ) == "N"
      IF !Empty( ::aText[nl] )
         ::InsText( ::aPointC, cNewLine )
         IF !Empty( ::aText[nl] )
            nl++
            ::AddLine( nL )
         ENDIF
      ENDIF
   ELSE
      ::AddLine( nL )
   ENDIF

   IF Empty( xBin )
      xVal := Iif( ::bImgLoad==Nil, HBitmap():AddFile(cName), Eval(::bImgLoad,cName) )
   ELSE
      IF ( i := Ascan( ::aBin, {|a|a[2]==xBin} ) ) > 0
         xVal := ::aBin[i,3]
         cName := "#" + ::aBin[i,1]
      ELSE
         IF Empty( cName )
            i := 1
            DO WHILE !Empty( cName := "img_"+Ltrim(Str(i)) ) .AND. Ascan( ::aBin, {|a|a[1]==cName} ) != 0
               i ++
            ENDDO
         ENDIF
         xVal := HBitmap():AddString( cName, xBin )
         Aadd( ::aBin, { cName, xBin, xVal, cExt } )
         cName := "#" + cName
      ENDIF
   ENDIF
   ::aStru[nL,1] :=  { "img", xVal, cClsName,,, cName, nAlign }
   IF ::aImages == Nil
      ::aImages := {}
   ENDIF
   Aadd( ::aImages, xVal )

   IF !Empty( nLTr )
      ::RestoreEnv( nLTr, iTd )
      ::nBoundL := nBoundL; ::nBoundT := nBoundT; ::nBoundR := nBoundR
      ::nIndent := nIndent
   ENDIF

   ::lUpdated := .T.
   hced_Invalidaterect( ::hEdit, 0, 0, 0, ::nClientWidth, ::nHeight )

   RETURN .T.

METHOD InsSpan( cText, xAttr, cHref, cId, nOpt ) CLASS HCEdiExt
   LOCAL nL, x1, aStruTbl, iTd, nIndent, nBoundL, nBoundR, nBoundT, nLTr, aStru, j

   nL := ::aPointC[P_Y]

   IF Valtype( ::aStru[nL,1,OB_TYPE] ) == "C" .AND. ::aStru[nL,1,OB_TYPE] == "tr"
      aStruTbl := ::aStru[nL-::aStru[nL,1,OB_TRNUM]+1,1,OB_TBL]

      iTd := ::nPosC

      nBoundL := ::nBoundL; nBoundR := ::nBoundR; nBoundT := ::nBoundT
      ::nBoundL := aStruTbl[OB_OB,itd,OB_CLEFT]
      j := Iif( ::aStru[nL,1,OB_OB,iTd,OB_COLSPAN] > 1, ::aStru[nL,1,OB_OB,iTd,OB_COLSPAN]-1, 0 )
      ::nBoundR := aStruTbl[OB_OB,itd+j,OB_CRIGHT]
      ::nBoundT := ::aLines[::nLineC,AL_Y1]
      nIndent := ::nIndent
      ::nIndent := 0

      ::LoadEnv( nL, iTd )
      nLTr := nL
      nL := ::aPointC[P_Y]
   ENDIF

   x1 := ::aPointC[P_X]
   IF ( aStru := hced_Stru4Pos( ::aStru[nL], x1 ) ) == Nil .OR. Len( aStru ) == 3
      ::InsText( ::aPointC, cText )
      ::StyleSpan( nL, x1, x1+hced_Len(Self,cText)-1, xAttr, cHRef, cId, nOpt )
      hced_CleanStru( Self, nL, nL )
   ENDIF

   IF !Empty( nLTr )
      ::RestoreEnv( nLTr, iTd )
      ::nBoundL := nBoundL; ::nBoundT := nBoundT; ::nBoundR := nBoundR
      ::nIndent := nIndent
   ENDIF

   ::lUpdated := .T.
   hced_Invalidaterect( ::hEdit, 0, 0, 0, ::nClientWidth, ::nHeight )

   RETURN .T.

METHOD DelObject( cType, nL, nCol ) CLASS HCEdiExt

   IF cType == "tbl"
   ELSEIF cType == "tr"
   ELSEIF cType == "td"
   ENDIF
   RETURN Nil

METHOD Save( cFileName, cpSou, lHtml, lCompact, xFrom, xTo, lEmbed ) CLASS HCEdiExt
   LOCAL nHand := -1, s := "", s1, i, iTbl, j, nPos, cLine, aClasses, aImages, aHili, oFont
   LOCAL cPart, cHref, cId, nAcc, cAcc
   LOCAL lNested := ( Valtype(cFileName) == "L"), aStruTbl, xTemp
   LOCAL aText, nTextLen, aStru, n, i1, j1, cNewL := Iif( Empty( lCompact ), cNewLine, "" )
   LOCAL aDefClasses := Iif( Empty(::aDefClasses), {}, ::aDefClasses )
   LOCAL nFrom := Iif( xFrom==Nil, 1, Iif( Valtype(xFrom)=="A",xFrom[P_Y],xFrom ) ), nXFrom := -1
   LOCAL nTo := Iif( xTo==Nil, ::nTextLen, Iif( Valtype(xTo)=="A",xTo[P_Y],xTo ) ), nXTo := 999999999

   IF !lNested
      IF Valtype( xFrom ) == "A"; nXFrom := xFrom[P_X]; ENDIF
      IF Valtype( xTo ) == "A"; nXTo := xTo[P_X]; ENDIF
      IF !Empty( cFileName )
         ::cFileName := cFileName
         IF ( nHand := FCreate( ::cFileName := cFileName ) ) == -1
            RETURN .F.
         ENDIF
      ENDIF

      IF Empty( cpSou )
         cpSou := ::cpSource
      ENDIF
      IF lHtml == Nil
         lHtml := ::lHtml
      ENDIF

      aClasses := {}
      aImages := {}
      FOR i := nFrom TO nTo
         FOR j := 1 TO Len( ::aStru[i] )
            IF ( i == nFrom .AND. j > 1 .AND. ::aStru[i,j,2] < nXFrom ) .OR. ;
               ( i == nTo .AND. j > 1 .AND. ::aStru[i,j,1] > nXTo )
               LOOP
            ENDIF
            IF !Empty(xTemp := ::aStru[i,j,OB_CLS]) .AND. Ascan( aClasses, xTemp ) == 0
               AAdd( aClasses, xTemp )
            ENDIF
         NEXT
         IF Valtype(::aStru[i,1,OB_TYPE]) == "C"
            IF ::aStru[i,1,OB_TYPE] == "img"
               Aadd( aImages, ::aStru[i,1,OB_HREF] )
            ELSEIF ::aStru[i,1,OB_TYPE] == "tr"
               IF ::aStru[i,1,OB_TRNUM] == 1 .AND. !Empty(xTemp := ::aStru[i,1,OB_TBL,OB_CLS] ) ;
                     .AND. Ascan( aClasses, xTemp ) == 0
                  AAdd( aClasses, xTemp )
               ENDIF
               FOR n := 1 TO Len( ::aStru[i,1,OB_OB] )
                  IF !Empty(xTemp := ::aStru[i,1,OB_OB,n,OB_CLS]) .AND. Ascan( aClasses, xTemp ) == 0
                     AAdd( aClasses, xTemp )
                  ENDIF
                  aStru := ::aStru[ i,1,OB_OB,n,OB_ASTRU ]
                  aText := ::aStru[ i,1,OB_OB,n,OB_ATEXT ]
                  nTextLen := ::aStru[ i,1,OB_OB,n,OB_NTLEN ]
                  FOR i1 := 1 TO nTextLen
                     FOR j1 := 1 TO Len( aStru[i1] )
                        IF !Empty(xTemp := aStru[i1,j1,OB_CLS]) .AND. Ascan( aClasses, xTemp ) == 0
                           AAdd( aClasses, xTemp )
                        ENDIF
                     NEXT
                     IF Valtype(aStru[i1,1,OB_TYPE]) == "C" .AND. ;
                           aStru[i1,1,OB_TYPE] == "img"
                        Aadd( aImages, aStru[i1,1,OB_HREF] )
                     ENDIF
                  NEXT
               NEXT
            ENDIF
         ENDIF
      NEXT

      IF lHtml
         s += "<html><head>"
      ELSEIF Empty( lCompact )
         s += "<hwge" + Iif(Empty(::cpSource),"",' cp="' + ::cpSource + '"' ) + ;
               Iif(Empty(::nDocFormat),"",' page="' + HPrinter():aPaper[ ::nDocFormat,1] ;
               + ',' + Ltrim(Str(::nDocOrient)) + ',' + Ltrim(Str(::aDocMargins[1])) + ',' + ;
               Ltrim(Str(::aDocMargins[2])) + ',' + Ltrim(Str(::aDocMargins[3])) + ',' + Ltrim(Str(::aDocMargins[4])) + '"' ) + ;
               + ::SaveTag( "hwge" ) + '>' + cNewL
      ENDIF
      IF !Empty( aClasses )
         s1 := ""
         FOR i := 1 TO Len( aClasses )
            IF lHtml .OR. hb_Ascan( aDefClasses, aClasses[i],,, .T. ) == 0
               s1 += "." + aClasses[i] + " { "
               IF hb_hHaskey( ::aHili, aClasses[i] )
                  aHili := ::aHili[aClasses[i]]
                  IF !Empty( aHili[1] ) .AND. aHili[1] > 0
                     oFont := ::aFonts[aHili[1]]
                     IF oFont:name != ::oFont:name
                        s1 += "font-family: " + oFont:name + "; "
                     ENDIF
                     IF oFont:cargo != Nil
                        s1 += "font-size: " + oFont:cargo + "; "
                     ENDIF
                     IF oFont:weight == 700
                        s1 += "font-weight: bold; "
                     ENDIF
                     IF oFont:italic == 255
                        s1 += "font-style: italic; "
                     ENDIF
                     IF oFont:Underline == 255
                        s1 += "text-decoration: underline; "
                     ELSEIF oFont:StrikeOut == 255
                        s1 += "text-decoration: line-through; "
                     ENDIF
                  ENDIF
                  IF aHili[2] != Nil
                     s1 += "color: " + hced_color2x(aHili[2]) + "; "
                  ENDIF
                  IF aHili[3] != Nil
                     s1 += "background-color: " + hced_color2x(aHili[3]) + "; "
                  ENDIF
                  IF aHili[4] != Nil
                     s1 += "margin-left: " + Iif( aHili[4]>=0, Ltrim(Str(aHili[4])), Ltrim(Str(-aHili[4]))+"%" ) + "; "
                  ENDIF
                  IF aHili[5] != Nil
                     s1 += "margin-right: " + Iif( aHili[5]>=0, Ltrim(Str(aHili[5])), Ltrim(Str(-aHili[5]))+"%" ) + "; "
                  ENDIF
                  IF aHili[6] != Nil
                     s1 += "text-indent: " + Iif( aHili[6]>=0, Ltrim(Str(aHili[6])), Ltrim(Str(-aHili[6]))+"%" ) + "; "
                  ENDIF
                  IF aHili[7] != Nil
                     s1 += "text-align: " + Iif( aHili[7]==1, "center", Iif( aHili[7]==2, "right", 0 ) ) + "; "
                  ENDIF              
                  IF aHili[8] != Nil
                     s1 += "border: " + Ltrim(Str(aHili[8]:width))+"px " + "solid " + hced_Color2X(aHili[8]:color) + "; "
                  ENDIF              
               ENDIF
               s1 += "}" + cNewL
            ENDIF
         NEXT
         IF !Empty( s1 )
            s += "<style>" + cNewL + s1 + "</style>" + cNewL
         ENDIF
      ENDIF
      IF lHtml
         s += "</head><body>" + cNewL
      ENDIF
      hbxml_SetEntity( { { "lt;","<" }, { "gt;",">" },{ "amp;","&" } } )   
   ENDIF

   FOR i := nFrom TO nTo
      IF Valtype(::aStru[i,1,OB_TYPE]) == "N"
         IF !Empty( aStruTbl )
            aStruTbl := Nil
            s += "</table>" + cNewL
         ENDIF
         s += "<div" + Iif( !Empty(::aStru[i,1,OB_CLS]), ' class="' + ::aStru[i,1,OB_CLS] + '"', '' ) + ;
               Iif( Len(::aStru[i,1])>=OB_ID.AND.!Empty(::aStru[i,1,OB_ID]),' id="'+::aStru[i,1,OB_ID]+'"','' ) + ;
               Iif( !lHtml.AND.Len(::aStru[i,1])>=OB_ACCESS.AND.!Empty(::aStru[i,1,OB_ACCESS]),' access="'+hced_SaveAccInfo(::aStru[i,1,OB_ACCESS])+'"','' ) + ;
               ::SaveTag( "div", i ) + '>'
         cLine := Trim(::aText[i] )
         nPos := Iif( i == nFrom .AND. nXFrom != -1, nXFrom, 1 )
         FOR j := 2 TO Len( ::aStru[i] )
            IF i == nTo .AND. nXTo != -1 .AND. ::aStru[i,j,1] > nXTo
               LOOP
            ENDIF
            IF ::aStru[i,j,1] > nPos
               cPart := hced_Substr( Self, cLine, nPos, ::aStru[i,j,1] - nPos )
               s += hbxml_preSave( Iif( !Empty(cpSou).AND.!(cpSou==::cp), hb_Translate( cPart, ::cp, cpSou ), cPart ) )
            ENDIF
            nPos := ::aStru[i,j,2] + 1
            IF i == nFrom .AND. nXFrom > ::aStru[i,j,1] .AND. nXFrom <= ::aStru[i,j,2]
               cPart := hced_Substr( Self, cLine, ::aStru[i,j,1], nPos - nXFrom )
            ELSE
               cPart := hced_Substr( Self, cLine, ::aStru[i,j,1], nPos - ::aStru[i,j,1] )
            ENDIF
            IF Len(::aStru[i,j]) >= OB_HREF
               cHref := ::aStru[i,j,OB_HREF]
               IF lHtml .AND. Left( cHref, 5 ) == "goto:"
                  cHref := Substr( cHref, 8 )
               ENDIF
            ELSE
               cHref := ""
            ENDIF
            cId := Iif( Len(::aStru[i,j])>=OB_ID.AND.!Empty(::aStru[i,j,OB_ID]),' id="'+::aStru[i,j,OB_ID]+'"','' )
            nAcc := Iif( Len(::aStru[i,j])>=OB_ACCESS.AND.!Empty(::aStru[i,j,OB_ACCESS]), ::aStru[i,j,OB_ACCESS], 0 )
            cAcc := Iif( !lHtml.AND.hwg_SetBit(nAcc,BIT_CLCSCR,0)!=0, ;
                  ' access="'+hced_SaveAccInfo( nAcc ) +'"','' )
            IF hwg_checkBit( nAcc, BIT_CLCSCR )
               cPart := hbxml_preSave( Iif( !Empty(cpSou).AND.!(cpSou==::cp), hb_Translate( cPart, ::cp, cpSou ), cPart ) )
               IF lHtml
                  s += '<span class="'+::aStru[i,j,OB_CLS] + '"' + ;
                        cId + ::SaveTag( "span", i, j ) + '>' + cPart + '</span>'
               ELSE
                  s += '<span class="'+::aStru[i,j,OB_CLS] + '"' + ;
                        cId + cAcc + ' value="' + cPart + '"' + ;
                        ::SaveTag( "span", i, j ) + '><![CDATA[' + cHref + ']]></span>'
               ENDIF
            ELSE
               xTemp := Iif( !Empty(cHref) .AND. ::aStru[i,j,OB_CLS]=="url", "", ' class="'+::aStru[i,j,OB_CLS] + '"' )
               s += Iif( !Empty(cHref), '<a href="'+cHref+'"', '<span' ) + xTemp + ;
                     cId + cAcc + ::SaveTag( "span", i, j ) + '>' + ;
                     hbxml_preSave( Iif( !Empty(cpSou).AND.!(cpSou==::cp), hb_Translate( cPart, ::cp, cpSou ), cPart ) ) + ;
                     Iif( !Empty(cHref), '</a>', '</span>' )
            ENDIF
         NEXT
         IF nPos <= hced_Len( Self, cLine )
            IF i == nTo .AND. nXTo != -1 .AND. nPos < nXTo
               cPart := hced_Substr( Self, cLine, nPos, nXTo - nPos )
            ELSE
               cPart := hced_Substr( Self, cLine, nPos, hced_Len( Self, cLine ) - nPos + 1 )
            ENDIF
            s += hbxml_preSave( Iif( !Empty(cpSou).AND.!(cpSou==::cp), hb_Translate( cPart, ::cp, cpSou ), cPart ) )
         ENDIF
         s += "</div>" + cNewL
      ELSEIF ::aStru[i,1,OB_TYPE] == "img"
         IF !Empty( aStruTbl )
            aStruTbl := Nil
            s += "</table>" + cNewL
         ENDIF
         cHref := ::aStru[i,1,OB_HREF]
         IF lHtml .AND. Left( cHref,1 ) == "#"
            cHref := Substr( cHref, 2 )
            IF Empty( hb_FNameExt(cHRef) ) .AND. ( j := Ascan( ::aBin, {|a|a[1]==cHref} ) ) > 0 ;
                  .AND. !Empty( ::aBin[j,4] )
               cHref += ::aBin[j,4]
            ENDIF
         ELSEIF !Empty( lEmbed ) .AND. Left( cHref,1 ) != "#"
            cHref = "#" + hb_FNameName( cHref )
         ENDIF
         s += "<img" + Iif( !Empty(::aStru[i,1,OB_CLS]), ' class="' + ::aStru[i,1,OB_CLS] + '"', "" ) ;
            + ' src="' + cHref + '"' + ;
            Iif( !Empty(xTemp:=::aStru[i,1,OB_IALIGN]), ' align="' + Iif( xTemp==2, 'right"','center"' ), "" ) + ;
            Iif( Len(::aStru[i,1])>=OB_ID.and.!Empty(::aStru[i,1,OB_ID]),' id="'+::aStru[i,1,OB_ID]+'"','' ) + ;
            Iif( !lHtml.AND.Len(::aStru[i,1])>=OB_ACCESS.and.!Empty(::aStru[i,1,OB_ACCESS]),' access="'+hced_SaveAccInfo(::aStru[i,1,OB_ACCESS])+'"','' ) + ;
            ::SaveTag( "img", i ) + '/>' + cNewL
      ELSEIF ::aStru[i,1,OB_TYPE] == "tr"
         IF nFrom > 1 .AND. aStruTbl == Nil
            iTbl := i - ::aStru[i,1,OB_TRNUM] + 1
         ELSE
            iTbl := i
         ENDIF
         IF ::aStru[iTbl,1,OB_TRNUM] == 1
            aStruTbl := ::aStru[iTbl,1,OB_TBL]
            s += "<table" + Iif( !Empty(aStruTbl[OB_CLS]), ' class="' + aStruTbl[OB_CLS] + '"', "" ) ;
               + Iif( (xTemp:=Int(aStruTbl[OB_TWIDTH]))==0, "", ' width="'+Iif( xTemp>0,Ltrim(Str(xTemp)),Ltrim(Str(-xTemp))+'%' ) + '"') + ;
               Iif( !Empty(xTemp:=aStruTbl[OB_TALIGN]), ' align="' + Iif( xTemp==2, 'right"','center"' ), "" ) + ;
               ::SaveTag( "table", i ) + '>'
            FOR j := 1 TO Len( aStruTbl[OB_OB] )
               s += '<col width="' + ;
                  Iif( (xTemp:=Int(aStruTbl[OB_OB,j,OB_CWIDTH]))>0,Ltrim(Str(xTemp)),Ltrim(Str(-xTemp))+'%' ) + ;
                  '"/>'
            NEXT
            s += cNewL
         ENDIF
         s += "<tr" + ::SaveTag( "tr", i ) + ">" + cNewL
         FOR j := 1 TO Len( ::aStru[i,1,OB_OB] )
            s += "<td" + Iif( !Empty(::aStru[i,1,OB_OB,j,OB_CLS]), ' class="' + ::aStru[i,1,OB_OB,j,OB_CLS] + '"', "" ) ;
               + Iif( !Empty(::aStru[i,1,OB_OB,j,OB_COLSPAN]), ' colspan="' + Ltrim(Str(::aStru[i,1,OB_OB,j,OB_COLSPAN])) + '"', "" ) ;
               + Iif( !Empty(::aStru[i,1,OB_OB,j,OB_ROWSPAN]), ' rowspan="' + Ltrim(Str(::aStru[i,1,OB_OB,j,OB_ROWSPAN])) + '"', "" ) ;
               + ::SaveTag( "td", i, j ) + '>' + cNewL
            nTextLen := ::nTextLen; aText := ::aText; aStru := ::aStru
            ::aStru := aStru[ i,1,OB_OB,j,2 ]
            ::aText := aStru[ i,1,OB_OB,j,OB_ATEXT ]
            ::nTextLen := aStru[ i,1,OB_OB,j,OB_NTLEN ]
            s += ::Save( .F., cpSou, lHtml, lCompact )
            ::nTextLen := nTextLen; ::aText := aText; ::aStru := aStru
            s += "</td>" + cNewL
         NEXT
         s += "</tr>" + cNewL
      ELSE
         s += ::SaveTag( ::aStru[i,1,OB_TYPE], i )
      ENDIF
   NEXT
   IF !Empty( aStruTbl )
      aStruTbl := Nil
      s += "</table>" + cNewL
   ENDIF
   
   IF !lNested
      ::lUpdated := .F.
      hbxml_SetEntity()
      FOR i := 1 TO Len( ::aBin )
         IF ( j := Ascan( aImages, "#" + ::aBin[i,1] ) ) != 0
            IF lHtml
               cHref := Iif( Empty(hb_FNameExt(::aBin[i,1])) .AND. !Empty(::aBin[i,4]), ::aBin[i,1]+::aBin[i,4], ::aBin[i,1] )
               hb_Memowrit( ::aBin[i,1], ::aBin[i,2] )
            ELSE
               s += '<binary id="' + ::aBin[i,1] + '"' + ;
                     Iif( !Empty(::aBin[i,4]), ' ext="'+::aBin[i,4]+'"', '' ) + '>' + ;
                     hb_Base64Encode( ::aBin[i,2] ) + '</binary>' + cNewL
            ENDIF
            aImages[j] := ""
         ENDIF
      NEXT
      IF !Empty( lEmbed )
         FOR i := 1 TO Len( aImages )
            IF !Empty( aImages[i] )
               s += '<binary id="' + hb_FnameName( aImages[i] ) + '"' + ;
                     ' ext="'+ hb_FnameExt( aImages[i] ) +'"' + '>' + ;
                     hb_Base64Encode( Iif( ::bImgLoad==Nil, MemoRead(aImages[i]), Eval(::bImgLoad,aImages[i],.T.) ) ) ;
                     + '</binary>' + cNewL
            ENDIF
         NEXT
      ENDIF
      IF lHtml
         s += "</body></html>"
      ELSEIF Empty( lCompact )
         s += "</hwge>"
      ENDIF
      IF nHand != -1
         FWrite( nHand, s )
         FClose( nHand )
         RETURN .T.
      ENDIF
   ENDIF

   RETURN s

METHOD Undo( nLine1, nPos1, nLine2, nPos2, nOper, cText ) CLASS HCEdiExt
   LOCAL nUndo := Iif( Empty( ::aUndo ), 0, Len( ::aUndo ) ), arr := {}, i, aStru, nL, nTrTd

   IF ::nMaxUndo == 0
      RETURN Nil
   ENDIF

   IF PCount() >= 5
      IF nOper <= 3
         ::Super:Undo( nLine1, nPos1, nLine2, nPos2, nOper, cText )
         nUndo := Iif( Empty( ::aUndo ), 0, Len( ::aUndo ) )
         IF Len( ::aUndo[nUndo] ) < UNDO_EX
            FOR i := nLine1 TO Min( nLine2, Len(::aStru) )
               Aadd( arr, AClone(::aStru[i]) )
            NEXT
            Aadd( ::aUndo[nUndo], arr )
            Aadd( ::aUndo[nUndo], ::aEnv[OB_TYPE] )
         ENDIF
      ELSEIF nOper == 4
         IF nUndo == ::nMaxUndo
            ADel( ::aUndo, 1 )
         ELSE
            IF nUndo == 0
               ::aUndo := { Nil }
            ELSE
               Aadd( ::aUndo, Nil )
            ENDIF
            nUndo ++
         ENDIF
          FOR i := nLine1 TO nLine2
             Aadd( arr, AClone(::aStru[i]) )
          NEXT
         ::aUndo[nUndo] := { nLine1, nPos1, nLine2, nPos2, nOper, Nil, arr, ::aEnv[OB_TYPE] }
      ENDIF
   ELSEIF PCount() == 0 .AND. nUndo > 0
      IF ::aUndo[nUndo,UNDO_OPER] <= 4
         arr := ::aUndo[nUndo,UNDO_EX]
         nLine1 := ::aUndo[nUndo,UNDO_LINE1]
         nLine2 := ::aUndo[nUndo,UNDO_LINE2]
         nTrTd := ::aUndo[nUndo,UNDO_NTRTD]
         IF ::aUndo[nUndo,UNDO_OPER] <= 3
            ::Super:Undo()
         ELSE
            ::aUndo := Iif( nUndo==1, Nil, ASize( ::aUndo, nUndo-1 ) )
         ENDIF
         IF nTrTd == 0
            aStru := ::aStru
         ELSE
            nL := hb_BitShift( nTrTd - (nTrTd%256), -8 )
            aStru := ::aStru[nL,1,OB_OB,nTrTd%256,OB_ASTRU]
         ENDIF
         FOR i := nLine1 TO nLine2
            IF i-nLine1+1 <= Len( arr )
               aStru[i] := arr[i-nLine1+1]
            ENDIF
            IF Empty( aStru[i] )
               aStru[i] := { { 0, 0, Nil } }
            ENDIF
         NEXT
      ENDIF
   ENDIF

   RETURN Nil

METHOD LoadEnv( nL, iTd, lPaint ) CLASS HCEdiExt
   LOCAL aStru := ::aStru[nL,1], aStruTbl, aHili, lChgClr := .F.

   aStruTbl := ::aStru[nL-aStru[OB_TRNUM]+1,1,OB_TBL]

   ::aEnv[OB_TYPE] := nL * 256 + iTd
   ::aEnv[OB_ASTRU] := ::aStru
   ::aEnv[OB_ATEXT] := ::aText
   ::aEnv[OB_AWRAP] := ::aWrap
   ::aEnv[OB_ALIN] := ::aLines
   ::aEnv[OB_NLINES] := ::nLines
   ::aEnv[OB_NLINEF] := ::nLineF
   ::aEnv[OB_NTLEN] := ::nTextLen
   ::aEnv[OB_NWCF] := ::nWCharF
   ::aEnv[OB_NWSF] := ::nWSublF
   ::aEnv[OB_NLINEC] := ::nLineC
   ::aEnv[OB_NPOSC] := ::nPosC
   ::aEnv[OB_NLALL] := ::nLinesAll
   ::PCopy( ::aPointC, ::aEnv[OB_APC] )
   ::PCopy( ::aPointM1, ::aEnv[OB_APM1] )
   ::PCopy( ::aPointM2, ::aEnv[OB_APM2] )
   ::aEnv[OB_FONT] := ::nDefFont

   ::aStru := aStru[OB_OB,iTd,OB_ASTRU]
   ::aText := aStru[OB_OB,iTd,OB_ATEXT]
   ::aWrap := aStru[OB_OB,iTd,OB_AWRAP]
   ::aLines := aStru[OB_OB,iTd,OB_ALIN]
   ::nLines := aStru[OB_OB,iTd,OB_NLINES]
   ::nLineF := aStru[OB_OB,iTd,OB_NLINEF]
   ::nTextLen := aStru[OB_OB,iTd,OB_NTLEN]
   ::nWCharF := aStru[OB_OB,iTd,OB_NWCF]
   ::nWSublF := aStru[OB_OB,iTd,OB_NWSF]
   ::nLineC := aStru[OB_OB,iTd,OB_NLINEC]
   ::nPosC := aStru[OB_OB,iTd,OB_NPOSC]
   ::nLinesAll := aStru[OB_OB,iTd,OB_NLALL]
   ::PCopy( aStru[OB_OB,iTd,OB_APC], ::aPointC )
   ::PCopy( aStru[OB_OB,iTd,OB_APM1], ::aPointM1 )
   ::PCopy( aStru[OB_OB,iTd,OB_APM2], ::aPointM2 )

   IF !Empty( lPaint )
      ::aEnv[OB_TCLR] := ::tColor
      ::aEnv[OB_BCLR] := ::bColor
      ::aEnv[OB_BCLRCUR] := ::bColorCur
   ENDIF
   IF !Empty( aStruTbl[OB_CLS] ) .AND. hb_hHaskey( ::aHili,aStruTbl[OB_CLS] )
      aHili := ::aHili[aStruTbl[OB_CLS]]
      IF aHili[1] != Nil .AND. aHili[1] > 0
         ::nDefFont := aHili[1]
      ENDIF
      IF !Empty( lPaint )
         IF aHili[3] != Nil .AND. aHili[3] >= 0
            ::bColorCur := ::bColor := aHili[3]
            lChgClr := .T.
         ENDIF
         IF aHili[2] != Nil .AND. aHili[2] >= 0
            ::tColor := aHili[2]
            lChgClr := .T.
         ENDIF
      ENDIF
   ENDIF
   IF !Empty( aStru[OB_OB,iTd,OB_CLS] ) .AND. hb_hHaskey( ::aHili,aStru[OB_OB,iTd,OB_CLS] )
      aHili := ::aHili[aStru[OB_OB,iTd,OB_CLS]]
      IF aHili[1] != Nil .AND. aHili[1] > 0
         ::nDefFont := aHili[1]
      ENDIF
      IF !Empty( lPaint )
         IF aHili[3] != Nil .AND. aHili[3] >= 0
            ::bColorCur := ::bColor := aHili[3]
            lChgClr := .T.
         ENDIF
         IF aHili[2] != Nil .AND. aHili[2] >= 0
            ::tColor := aHili[2]
            lChgClr := .T.
         ENDIF
      ENDIF
   ENDIF
   IF !Empty( lPaint ) .AND. hwg_BitAnd( aStru[OB_OPT], TROPT_SEL ) > 0
      ::bColor := ::bcolorSel
      lChgClr := .T.
   ENDIF
   IF lChgClr
      hced_Setcolor( ::hEdit, ::tColor, ::bColor )
   ENDIF

   RETURN Nil

METHOD RestoreEnv( nL, iTd, lPaint ) CLASS HCEdiExt
   LOCAL aStru := ::aEnv[OB_ASTRU,nL,1]

   aStru[OB_OB,iTd,OB_ASTRU] := ::aStru
   aStru[OB_OB,iTd,OB_ATEXT] := ::aText
   aStru[OB_OB,iTd,OB_AWRAP] := ::aWrap
   aStru[OB_OB,iTd,OB_ALIN]  := ::aLines
   aStru[OB_OB,iTd,OB_NLINES] := ::nLines
   aStru[OB_OB,iTd,OB_NLINEF] := ::nLineF
   aStru[OB_OB,iTd,OB_NTLEN]  := ::nTextLen
   aStru[OB_OB,iTd,OB_NWSF] := ::nWSublF
   aStru[OB_OB,iTd,OB_NWCF] := ::nWCharF
   aStru[OB_OB,iTd,OB_NLINEC] := ::nLineC
   aStru[OB_OB,iTd,OB_NPOSC]  := ::nPosC
   aStru[OB_OB,iTd,OB_NLALL]  := ::nLinesAll
   ::PCopy( ::aPointC, aStru[OB_OB,iTd,OB_APC] )
   ::PCopy( ::aPointM1, aStru[OB_OB,iTd,OB_APM1] )
   ::PCopy( ::aPointM2, aStru[OB_OB,iTd,OB_APM2] )
   aStru[OB_OB,iTd,OB_BCLR]  := ::bColor

   ::aStru := ::aEnv[OB_ASTRU]
   ::aText := ::aEnv[OB_ATEXT]
   ::aWrap := ::aEnv[OB_AWRAP]
   ::aLines := ::aEnv[OB_ALIN]
   ::nLines := ::aEnv[OB_NLINES]
   ::nLineF := ::aEnv[OB_NLINEF]
   ::nWSublF := ::aEnv[OB_NWSF]
   ::nWCharF := ::aEnv[OB_NWCF]
   ::nTextLen := ::aEnv[OB_NTLEN]
   ::nLineC := ::aEnv[OB_NLINEC]
   ::nPosC := ::aEnv[OB_NPOSC]
   ::nLinesAll := ::aEnv[OB_NLALL]
   ::PCopy( ::aEnv[OB_APC], ::aPointC )
   ::PCopy( ::aEnv[OB_APM1], ::aPointM1 )
   ::PCopy( ::aEnv[OB_APM2], ::aPointM2 )
   ::nDefFont := ::aEnv[OB_FONT]
   IF !Empty( lPaint )
      ::tColor := ::aEnv[OB_TCLR]
      ::bColor := ::aEnv[OB_BCLR]
      ::bColorCur := ::aEnv[OB_BCLRCUR]
      hced_Setcolor( ::hEdit, ::tColor, ::bColor )
   ENDIF
   ::aEnv[OB_TYPE] := 0

   RETURN Nil

METHOD getEnv( n ) CLASS HCEdiExt
   RETURN ::aEnv[Iif(Empty(n),OB_TYPE,n)]

METHOD GetPosInfo( xPos, yPos ) CLASS HCEdiExt

   IF xPos == Nil
      RETURN ::SetCaretPos( SETC_XY + 200 )
   ELSEIF Valtype( xPos ) == "A"
      RETURN ::SetCaretPos( SETC_XYPOS + 200, xPos[P_X], xPos[P_Y] )
   ENDIF
   RETURN ::SetCaretPos( SETC_COORS + 200, xPos, yPos )

METHOD getClassAttr( cClsName ) CLASS HCEdiExt
   LOCAL aAttr := {}, aHili, oFont

   IF hb_hHaskey( ::aHili, cClsName )
      aHili := ::aHili[cClsName]
      IF aHili[1] > 0
         oFont := ::aFonts[aHili[1]]
         IF oFont:weight == 700
            Aadd( aAttr, "fb" )
         ENDIF
         IF oFont:italic == 255
            Aadd( aAttr, "fi" )
         ENDIF
         IF oFont:Underline == 255
            Aadd( aAttr, "fu" )
         ENDIF
         IF oFont:StrikeOut == 255
            Aadd( aAttr, "fs" )
         ENDIF
         IF !Empty( oFont:cargo )
            Aadd( aAttr, "fh" + oFont:cargo )
         ENDIF
         IF !(oFont:name == ::oFont:name)
            Aadd( aAttr, "fn" + oFont:name )
         ENDIF
      ENDIF
      IF !Empty( aHili[2] )
         Aadd( aAttr, "ct" + Ltrim(Str( aHili[2] )) )
      ENDIF
      IF !Empty( aHili[3] )
         Aadd( aAttr, "cb" + Ltrim(Str( aHili[3] )) )
      ENDIF
      IF !Empty( aHili[4] )
         Aadd( aAttr, "ml" + Iif( aHili[4]>0, Ltrim(Str( aHili[4] )), Ltrim(Str( -aHili[4] ))+"%" ) )
      ENDIF
      IF !Empty( aHili[5] )
         Aadd( aAttr, "mr" + Iif( aHili[5]>0, Ltrim(Str( aHili[5] )), Ltrim(Str( -aHili[5] ))+"%" ) )
      ENDIF
      IF !Empty( aHili[6] )
         Aadd( aAttr, "ti" + Iif( aHili[6]>0, Ltrim(Str( aHili[6] )), Ltrim(Str( -aHili[6] ))+"%" ) )
      ENDIF
      IF !Empty( aHili[7] )
         Aadd( aAttr, "ta" + Ltrim(Str( aHili[7] )) )
      ENDIF
      IF !Empty( aHili[8] )
         Aadd( aAttr, "bw" + Ltrim(Str( aHili[8]:width )) )
         IF !Empty( aHili[8]:color )
            Aadd( aAttr, "bc" + Ltrim(Str( aHili[8]:color )) )
         ENDIF
      ENDIF
   ENDIF
   RETURN aAttr

METHOD PrintLine( oPrinter, yPos, nL ) CLASS HCEdiExt

   ::lPrinting := .T.
   yPos := ::PaintLine( oPrinter, yPos, nL )
   ::lPrinting := .F.

   RETURN yPos

METHOD Scan( nl1, nl2, hDC, nWidth, nHeight ) CLASS HCEdiExt

   IF Empty( ::aText )
      RETURN Nil
   ENDIF
   IF !Empty( ::aEnv[OB_TYPE] ) .AND. Empty( nWidth )
      RETURN ::Super:Scan( nl1, nl2, hDC, ::nBoundR-::nBoundL, nHeight )
   ENDIF

   RETURN ::Super:Scan( nl1, nl2, hDC, nWidth, nHeight )

METHOD Find( cText, cId, cHRef, aStart, lCase, lRegex ) CLASS HCEdiExt

   LOCAL nLType, i, j, i1, j1, n, nPos, aStru, aText, nTextLen, cLine, cRes
   LOCAL nLStart := Iif( Valtype(aStart)=="A",aStart[P_Y],1 ), nPosStart := Iif( Valtype(aStart)=="A",aStart[P_X],1 ), nL1Start
   LOCAL lId := (cId != Nil), lText := (cText != Nil), lHref := (cHRef != Nil), lAll
   LOCAL arr

   IF lCase == Nil; lCase := .T.; ENDIF
   IF !lCase
      cText := Lower( cText )
   ENDIF
   lAll := Iif( aStart==Nil.OR.Valtype(aStart)!="L", .F., aStart )
   IF lAll
      arr := {}
   ENDIF

   FOR i := nLStart TO ::nTextLen
      nLType := Iif( Valtype(::aStru[i,1,OB_TYPE]) == "N", 0, ;
            Iif( ::aStru[i,1,OB_TYPE] == "tr", 1, Iif( ::aStru[i,1,OB_TYPE] == "img", 2, 3 ) ) )
      IF nLType == 0
         IF lId .AND. Len( ::aStru[i,1] ) >= OB_ID .AND. !Empty( ::aStru[i,1,OB_ID] )
            IF !lAll .AND. ::aStru[i,1,OB_ID] == cId
               RETURN { 1, i }
            ELSEIF lAll .AND. ::aStru[i,1,OB_ID] = cId
               Aadd( arr, { 1, i } )
            ENDIF
         ELSEIF lText
            nPos := Iif( i==nLStart,nPosStart,1 )
            cLine := Iif( lCase, ::aText[i], Lower( ::aText[i] ) )
            DO WHILE nPos > 0
               IF Empty( lRegex )
                  nPos := hced_At( Self, cText, cLine, nPos )
               ELSEIF ( cRes := hb_Atx( cText, cLine, lCase, @nPos ) ) != Nil
                  IF lAll
                     Aadd( arr, { nPos, i, hced_Len( Self,cRes ) } )
                  ELSE
                     RETURN { nPos, i, hced_Len( Self,cRes ) }
                  ENDIF
               ELSE
                  nPos := 0
               ENDIF
               IF nPos > 0 .AND. Empty( lRegex )
                  IF lAll
                     Aadd( arr, { nPos, i } )
                  ELSE
                     RETURN { nPos, i }
                  ENDIF
               ENDIF
               IF !lAll
                  EXIT
               ENDIF
            ENDDO
         ENDIF
         IF lHref .OR. lId
            FOR j := 2 TO Len( ::aStru[i] )
               IF lHref .AND. Len(::aStru[i,j]) >= OB_HREF .AND. ::aStru[i,j,OB_HREF] == cHRef
                  IF lAll
                     Aadd( arr, { j, i } )
                  ELSE
                     RETURN { j, i }
                  ENDIF
               ELSEIF lId .AND. Len(::aStru[i,j]) >= OB_ID .AND. !Empty( ::aStru[i,j,OB_ID] )
                  IF !lAll .AND. ::aStru[i,j,OB_ID] == cId
                     RETURN { j, i }
                  ELSEIF lAll .AND. ::aStru[i,j,OB_ID] = cId
                     Aadd( arr, { j, i } )
                  ENDIF
               ENDIF
            NEXT
         ENDIF
      ELSEIF nLType == 1
         FOR n := Iif( i==nLStart,nPosStart,1 ) TO Len( ::aStru[i,1,OB_OB] )
            aStru := ::aStru[ i,1,OB_OB,n,2 ]
            aText := ::aStru[ i,1,OB_OB,n,OB_ATEXT ]
            nTextLen := ::aStru[ i,1,OB_OB,n,OB_NTLEN ]
            nL1Start := Iif( Valtype(aStart)=="A".AND.Len(aStart)>3,aStart[4],1 )
            FOR i1 := nL1Start TO nTextLen
               IF lId .AND. Len( aStru[i1,1] ) >= OB_ID .AND. !Empty( aStru[i1,1,OB_ID] )
                  IF !lAll .AND. aStru[i1,1,OB_ID] == cId
                     RETURN { n, i, 1, i1 }
                  ELSEIF lAll .AND. aStru[i1,1,OB_ID] = cId
                     Aadd( arr, { n , i, 1, i1 } )
                  ENDIF
               ELSEIF lText
                  nPos := Iif( i1==nL1Start, Iif( Valtype(aStart)=="A".AND.Len(aStart)>3,aStart[3],1 ), 1 )
                  cLine := Iif( lCase, aText[i1], Lower( ::aText[i] ) )
                  DO WHILE nPos > 0
                     IF Empty( lRegex )
                        nPos := hced_At( Self, cText, cLine, nPos )
                     ELSEIF ( cRes := hb_Atx( cText, cLine, lCase, @nPos ) ) != Nil
                        IF lAll
                           Aadd( arr, { n, i, nPos, i1, hced_Len( Self,cRes ) } )
                        ELSE
                           RETURN { n, i, nPos, i1, hced_Len( Self,cRes ) }
                        ENDIF
                     ELSE
                        nPos := 0
                     ENDIF
                     IF nPos > 0 .AND. Empty( lRegex )
                        IF lAll
                           Aadd( arr, { n, i, nPos, i1 } )
                        ELSE
                           RETURN { n, i, nPos, i1 }
                        ENDIF
                     ENDIF
                     IF !lAll
                        EXIT
                     ENDIF
                  ENDDO
               ENDIF
               IF lHref .OR. lId
                  FOR j1 := 2 TO Len( aStru[i1] )
                     IF lHref .AND. Len(aStru[i1,j1]) >= OB_HREF .AND. aStru[i1,j1,OB_HREF] == cHRef
                        IF lAll
                           Aadd( arr, { n, i, j1, i1 } )
                        ELSE
                           RETURN { n, i, j1, i1 }
                        ENDIF
                     ELSEIF lId .AND. Len(aStru[i1,j1]) >= OB_ID .AND. !Empty( aStru[i1,j1,OB_ID] )
                        IF !lAll .AND. aStru[i1,j1,OB_ID] == cId
                           RETURN { n, i, j1, i1 }
                        ELSEIF lAll .AND. aStru[i1,j1,OB_ID] = cId
                           Aadd( arr, { n, i, j1, i1 } )
                        ENDIF
                     ENDIF
                  NEXT
               ENDIF
            NEXT
         NEXT
      ELSEIF nLType == 2 .AND. lId
         IF !lAll .AND. ::aStru[i,1,OB_ID] == cId
            RETURN { 1, i }
         ELSEIF lAll .AND. ::aStru[i,1,OB_ID] = cId
            Aadd( arr, { 1, i } )
         ENDIF
      ENDIF
   NEXT

   RETURN arr

CLASS HiliExt  INHERIT HilightBase

   METHOD New()   INLINE  Self
   METHOD Set( oEdit )
   METHOD Do( oEdit, nLine )
   METHOD UpdSource( nLine1, nPos1, nLine2, nPos2, nOper, cText )

ENDCLASS

METHOD Set( oEdit ) CLASS HiliExt
Local oHili := HiliExt():New()

   oHili:oEdit := oEdit

   RETURN oHili

METHOD Do( oEdit, nLine ) CLASS HiliExt

   IF Valtype( ::oEdit:aStru[nLine,1,OB_TYPE] ) == "N"
      ::aLineStru := ::oEdit:aStru[nLine]
      ::nItems := Len( ::aLineStru )
      ::nLine := nLine
   ELSE
      ::nItems := 0
   ENDIF
   RETURN Nil

/*  nOper: 1 - insert, 2 - over, 3 - delete
 */
METHOD UpdSource( nLine1, nPos1, nLine2, nPos2, nOper, cText ) CLASS HiliExt

   LOCAL i, n1, n2, nDel := 0, aText, aRest
   LOCAL aStru1 := ::oEdit:aStru[nLine1], aStru2 := ::oEdit:aStru[nLine2]

   IF nOper == 1            // Text inserted
      IF nLine1 == nLine2   // within the same paragraph
         hced_Stru4Pos( aStru1, nPos1, @n1 )
         FOR i := n1 TO Len( aStru1 )
            IF i > n1 .OR. nPos1 < aStru1[i,1]
               aStru1[i,1] += ( nPos2-nPos1 )
            ENDIF
            aStru1[i,2] += ( nPos2-nPos1 )
         NEXT
      ELSE                  // consisting of several paragraphs
         hced_Stru4Pos( aStru1, nPos1, @n1, .T. )
         aText := hb_aTokens( cText, cNewLine )
         IF n1 <= Len( aStru1 )
            nDel := nPos1 - 1  //aStru1[n1,1] - 1
            IF nPos1 > aStru1[n1,1] //.AND. nPos1 <= aStru1[n1,2]
               n2 := hced_Len( ::oEdit, Atail(aText) ) + 1
               aRest := { n2, n2 + aStru1[n1,2] - nPos1, aStru1[n1,3] }
               aStru1[n1,2] := nPos1 + hced_Len( ::oEdit, ::oEdit:aText[nLine1] )
               n1 ++
            ENDIF
            FOR i := n1 TO Len( aStru1 )
               aStru1[i,1] -= nDel
               aStru1[i,2] -= nDel
               Aadd( aStru2, aStru1[i] )
            NEXT
            IF !Empty( aRest )
               Aadd( aStru2, aRest )
            ENDIF
            ::oEdit:aStru[nLine1] := ASize( aStru1, n1-1 )
         ENDIF
      ENDIF

   ELSEIF nOper == 3        // Text deleted
      //IF nPos2 > 1
         nPos2 --
      //ENDIF
      IF nLine2 > nLine1    // consisting of several paragraphs
         FOR i := Len(aStru1) TO 2 STEP -1
            IF nPos1 > aStru1[i,2]
               EXIT
            ELSEIF nPos1 > aStru1[i,1]
               aStru1[i,2] := nPos1
            ELSE
               ADel( aStru1, i )
               nDel ++
            ENDIF
         NEXT
         IF nDel > 0
            aStru1 := ASize( aStru1, Len(aStru1)-nDel )
         ENDIF
         FOR i := 2 TO Len( aStru2 )
            IF nPos2 < aStru2[i,2]
               IF nPos2 < aStru2[i,1]
                  aStru2[i,1] := nPos1 + aStru2[i,1] - nPos2 - 1
               ELSE
                  aStru2[i,1] := nPos1
               ENDIF
               aStru2[i,2] := nPos1 + aStru2[i,2] - nPos2 - 1
               Aadd( aStru1, aStru2[i] )
            ENDIF
         NEXT
         //::oEdit:aStru[nLine2] := { { 0, 0, Nil } }
      ELSE                  // within the same paragraph
         FOR i := Len(aStru1) TO 2 STEP -1
            IF nPos2 >= aStru1[i,2]
               IF nPos1 <= aStru1[i,1]
                  ADel( aStru1, i )
                  nDel ++
               ELSE
                  IF nPos1 <= aStru1[i,2]
                     aStru1[i,2] := nPos1 - 1
                  ENDIF
                  EXIT
               ENDIF
            ELSE
               IF nPos2 >= aStru1[i,1]
                  IF nPos1 < aStru1[i,1]
                     aStru1[i,1] := nPos1
                  ENDIF
               ELSE
                  aStru1[i,1] -= ( nPos2 - nPos1 + 1 )
               ENDIF
               aStru1[i,2] -= ( nPos2 - nPos1 + 1 )
            ENDIF
         NEXT
         aStru1 := ASize( aStru1, Len(aStru1)-nDel )
      ENDIF
      ::oEdit:aStru[nLine1] := aStru1
   ENDIF
   RETURN Nil

STATIC FUNCTION hced_Aline( oEdit )

   LOCAL i

   oEdit:nLines ++
   IF oEdit:nLines >= Len( oEdit:aLines )
      oEdit:aLines := ASize( oEdit:aLines, Len( oEdit:aLines ) + 16 )
      FOR i := 0 TO 15
         oEdit:aLines[Len(oEdit:aLines)-i] := Array( AL_LENGTH )
      NEXT
   ENDIF

   RETURN oEdit:aLines[oEdit:nLines]

STATIC FUNCTION hced_td4Pos( oEdit, nL, xPos )
   LOCAL iTd, iCol := 0, aStru := oEdit:aStru[nL,1], aStruTbl

   xPos += oEdit:nShiftL
   aStruTbl := oEdit:aStru[nL-oEdit:aStru[nL,1,OB_TRNUM]+1,1,OB_TBL]
   FOR iTd := 1 TO Len( aStru[OB_OB] )
      iCol ++
      IF aStru[OB_OB,iTd,OB_COLSPAN] > 1
         iCol += (aStru[OB_OB,iTd,OB_COLSPAN] - 1)
      ENDIF
      IF xPos <= aStruTbl[ OB_OB,iCol,OB_CRIGHT ]
         EXIT
      ENDIF
   NEXT
   RETURN Iif( iTd > Len( aStru[OB_OB] ), --iTd, iTd )

FUNCTION hced_Stru4Pos( aStru, xPos, i, lExact )

   IF Empty(lExact) .AND. xPos > 1
      xPos --
   ENDIF
   FOR i := 2 TO Len( aStru )
      IF xPos < aStru[i,1]
         RETURN Nil
      ELSEIF xPos <= aStru[i,2]
     
         IF Empty(lExact) .AND. Len( aStru[i] ) >= OB_HREF
            IF xPos + 1 <= aStru[i,2]
               RETURN aStru[i]
            ELSE
               LOOP
            ENDIF
         ELSE
            RETURN aStru[i]
         ENDIF
      ENDIF
   NEXT
   RETURN Nil

FUNCTION hced_CleanStru( oEdit, nLine1, nLine2 )
   LOCAL nL, i, aStru, nDel

   FOR nL := nLine1 TO nLine2
      aStru := oEdit:aStru[nL]
      nDel := 0
      FOR i := 2 TO Len( aStru ) - nDel
         IF ( ( aStru[i,OB_CLS] == aStru[1,OB_CLS] .OR. aStru[i,OB_CLS] == "def" ) .AND. ;
               Len(aStru[i]) <= OB_CLS ) .OR. aStru[i,1] > aStru[i,2]
            Adel( aStru, i )
            nDel ++
         ENDIF
      NEXT
      IF nDel > 0
         oEdit:aStru[nL] := aStru := Asize( aStru, Len( aStru ) - nDel )
      ENDIF
      nDel := 0
      FOR i := 3 TO Len( aStru ) - nDel
         IF aStru[i,1] == aStru[i-1,2] + 1 .AND. aStru[i,OB_CLS] == aStru[i-1,OB_CLS] ;
               .AND. Len(aStru[i]) == Len(aStru[i-1]) .AND. ;
               ( Len(aStru[i]) < OB_ID .OR. !(aStru[i,OB_ID]==aStru[i-1,OB_ID]) ) .AND. ;
               ( Len(aStru[i]) < OB_ACCESS .OR. !(aStru[i,OB_ACCESS]==aStru[i-1,OB_ACCESS]) )
            aStru[i-1,2] := aStru[i,2]
            Adel( aStru, i )
            nDel ++
         ENDIF
      NEXT
      IF nDel > 0
         oEdit:aStru[nL] := Asize( aStru, Len( aStru ) - nDel )
      ENDIF
   NEXT
   RETURN Nil

FUNCTION hced_getAccInfo( oEdit, aPoint, nType )

   LOCAL nOpt := 0, nOpt1, aLineStru := oEdit:aStru[aPoint[P_Y]], aStru

   IF (nType == Nil .OR. nType == 0) .AND. Len( aLineStru[1] ) >= OB_ACCESS
      nOpt := aLineStru[1,OB_ACCESS]
   ENDIF
   IF (nType == Nil .OR. nType > 0)
      IF ( aStru := hced_Stru4Pos( aLineStru, aPoint[P_X],, .T. ) ) != Nil
         IF Len( aStru ) >= OB_ACCESS
            nOpt1 := aStru[OB_ACCESS]
            IF nType == Nil
               IF hwg_checkBit( nOpt1, 1 )
                  nOpt := Iif( nOpt == 0, 0, 8 )
               ELSEIF nOpt1 != 0
                  nOpt := nOpt1
               ENDIF
            ELSE
               nOpt := nOpt1
            ENDIF
         ENDIF
      ELSEIF nType != Nil
         RETURN Nil
      ENDIF
   ENDIF

   RETURN nOpt

FUNCTION hced_setAccInfo( oEdit, aPoint, nType, nOpt )

   LOCAL aLineStru := oEdit:aStru[aPoint[P_Y]], aStru

   IF nType == 0
      aStru := aLineStru[1]
   ELSE
      aStru := hced_Stru4Pos( aLineStru, aPoint[P_X],, .T. )
   ENDIF
   IF aStru == Nil
      RETURN .F.
   ENDIF
   IF Len( aStru ) < OB_ID
      Aadd( aStru, Nil )
   ENDIF
   IF Len( aStru ) < OB_ACCESS
      Aadd( aStru, Nil )
   ENDIF
   aStru[OB_ACCESS] := nOpt

   RETURN .T.

STATIC FUNCTION hced_ReadAccInfo( s )

   LOCAL nOpt := 0

   IF "allow" $ s
      RETURN 1
   ENDIF
   IF "nowr" $ s
      nOpt += 2
   ENDIF
   IF "noins" $ s
      nOpt += 12
   ELSEIF "nocr" $ s
      nOpt += 8
   ENDIF

   RETURN nOpt

STATIC FUNCTION hced_SaveAccInfo( nOpt )

   LOCAL s := ""

   IF hwg_checkBit( nOpt, BIT_ALLOW )
      RETURN "allow"
   ENDIF
   IF hwg_checkBit( nOpt, BIT_RDONLY )
      s += "nowr"
   ENDIF
   IF hwg_checkBit( nOpt, BIT_NOINS )
      s += Iif( Empty(s), "","," ) + "noins"
   ELSEIF hwg_checkBit( nOpt, BIT_NOCR )
      s += Iif( Empty(s), "","," ) + "nocr"
   ENDIF

   RETURN s

STATIC FUNCTION hced_CrStru( oEdit, aAttr, aStru, aText, cClsname, cVal, cHRef )

   LOCAL i, n1 := 0, n2 := 0, cId
   LOCAL nAccess := hced_ReadAccInfo( Iif( (i:=Ascan(aAttr,{|a|a[1]=="access"}))==0, "", aAttr[i,2] ) )

   cId := Iif( ( i := Ascan( aAttr,{|a|a[1]=="id"} ) ) == 0, "", aAttr[i,2] )
   IF cVal != Nil
      n1 := hced_Len( oEdit, aText )+1
      n2 := hced_Len( oEdit, aText ) + hced_Len( oEdit,cVal )
   ENDIF
   Aadd( aStru, Iif( cHRef!=Nil, { n1, n2, cClsName, cId, nAccess, cHRef }, ;
         Iif( nAccess!=0, { n1, n2, cClsName, cId, nAccess }, ;
         Iif( !Empty(cId), { n1, n2, cClsName, cId }, { n1, n2, cClsName } ) ) ) )

   RETURN Nil

STATIC FUNCTION hced_FindClass( aClasses, aHili )

   LOCAL i, cName, arr

   FOR EACH arr IN aClasses
      IF aHili[1] != arr[1] .AND. ( arr[1] > 1 .OR. ( !Empty(aHili[1]) .AND. aHili[1] > 1 ) )
         i := 1
      ELSEIF Valtype(arr[HILI_LEN]) != Valtype(aHili[HILI_LEN]) .OR. ;
         ( Valtype(arr[HILI_LEN]) == "O" .AND. ( (arr[HILI_LEN]:style != aHili[HILI_LEN]:style) .OR. ;
         (arr[HILI_LEN]:width != aHili[HILI_LEN]:width) .OR. (arr[HILI_LEN]:color != aHili[HILI_LEN]:color) ) )
         i := 1
      ELSE
         FOR i := 2 TO HILI_LEN-1
            IF Valtype(arr[i]) != Valtype(aHili[i]) .OR. arr[i] != aHili[i]
               EXIT
            ENDIF
         NEXT
      ENDIF
      IF i > HILI_LEN-1
         cName := arr:__enumKey()
         EXIT
      ENDIF
   NEXT

   RETURN cName
