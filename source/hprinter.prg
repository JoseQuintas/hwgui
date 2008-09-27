/*
 * $Id: hprinter.prg,v 1.34 2008-09-27 22:21:16 fperillo Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HPrinter class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

CLASS HPrinter INHERIT HObject

   DATA hDCPrn     INIT 0
   DATA hDC
   DATA cPrinterName
   DATA hPrinter   INIT 0
   DATA aMeta
   DATA lPreview
   DATA cMetaName
   DATA nWidth, nHeight, nPWidth, nPHeight
   DATA nHRes, nVRes                     // Resolution ( pixels/mm )
   DATA nPage

   DATA lmm  INIT .F.
   DATA nCurrPage, oTrackV, oTrackH
   DATA nZoom, xOffset, yOffset, x1, y1, x2, y2

   DATA memDC       HIDDEN    // dc offscreen
   DATA memBitmap   HIDDEN    // bitmap offscreen
   DATA NeedsRedraw INIT .T.  HIDDEN // if offscreen needs redrawing...

   METHOD New( cPrinter,lmm )
   METHOD SetMode( nOrientation )
   METHOD AddFont( fontName, nHeight ,lBold, lItalic, lUnderline )
   METHOD SetFont( oFont )  INLINE SelectObject( ::hDC,oFont:handle )
   METHOD SetTextColor( nColor )  INLINE SetTextColor( ::hDC,nColor )
   METHOD SetTBkColor( nColor )   INLINE SetBKColor( ::hDC,nColor )
   METHOD SetBkmode( lmode )   INLINE SetBkmode( ::hDC,if(lmode,1,0) )
   METHOD StartDoc( lPreview,cMetaName )
   METHOD EndDoc()
   METHOD StartPage()
   METHOD EndPage()
   METHOD ReleaseMeta()
   METHOD PlayMeta( nPage, oWnd )
   METHOD PrintMeta( nPage )
   METHOD Preview( cTitle )
   METHOD End()
   METHOD Box( x1,y1,x2,y2,oPen,oBrush )
   METHOD Line( x1,y1,x2,y2,oPen )
   METHOD Say( cString,x1,y1,x2,y2,nOpt,oFont,nTextColor,nBkColor )
   METHOD Bitmap( x1,y1,x2,y2,nOpt,hBitmap )
   METHOD GetTextWidth( cString, oFont )
   METHOD ResizePreviewDlg( oCanvas, nZoom, msg, wParam, lParam ) HIDDEN
   METHOD ChangePage( oSayPage,n,nPage ) HIDDEN
ENDCLASS

METHOD New( cPrinter,lmm ) CLASS HPrinter
Local aPrnCoors, cPrinterName

   IF lmm != Nil
      ::lmm := lmm
   ENDIF
   IF cPrinter == Nil
      ::hDCPrn := PrintSetup( @cPrinterName )
      ::cPrinterName := cPrinterName
   ELSEIF Empty( cPrinter )
      cPrinterName:=HWG_GETDEFAULTPRINTER()
      ::hDCPrn := Hwg_OpenPrinter( cPrinterName )
      ::cPrinterName := cPrinterName
   ELSE
      ::hDCPrn := Hwg_OpenPrinter( cPrinter )
      ::cPrinterName := cPrinter
   ENDIF
   IF ::hDCPrn == 0
      Return Nil
   ELSE
      aPrnCoors := GetDeviceArea( ::hDCPrn )
      ::nWidth  := Iif( ::lmm, aPrnCoors[3], aPrnCoors[1] )
      ::nHeight := Iif( ::lmm, aPrnCoors[4], aPrnCoors[2] )
      ::nPWidth  := Iif( ::lmm, aPrnCoors[8], aPrnCoors[1] )
      ::nPHeight := Iif( ::lmm, aPrnCoors[9], aPrnCoors[2] )
      ::nHRes   := aPrnCoors[1] / aPrnCoors[3]
      ::nVRes   := aPrnCoors[2] / aPrnCoors[4]
      // writelog( ::cPrinterName + str(aPrnCoors[1])+str(aPrnCoors[2])+str(aPrnCoors[3])+str(aPrnCoors[4])+str(aPrnCoors[5])+str(aPrnCoors[6])+str(aPrnCoors[8])+str(aPrnCoors[9]) )
   ENDIF

Return Self

METHOD SetMode( nOrientation ) CLASS HPrinter
Local hPrinter := ::hPrinter, hDC, aPrnCoors

   hDC := SetPrinterMode( ::cPrinterName, @hPrinter, nOrientation )
   IF hDC != Nil
      IF ::hDCPrn != 0
         DeleteDC( ::hDCPrn )
      ENDIF
      ::hDCPrn := hDC
      ::hPrinter := hPrinter
      aPrnCoors := GetDeviceArea( ::hDCPrn )
      ::nWidth  := Iif( ::lmm, aPrnCoors[3], aPrnCoors[1] )
      ::nHeight := Iif( ::lmm, aPrnCoors[4], aPrnCoors[2] )
      ::nPWidth  := Iif( ::lmm, aPrnCoors[8], aPrnCoors[1] )
      ::nPHeight := Iif( ::lmm, aPrnCoors[9], aPrnCoors[2] )
      ::nHRes   := aPrnCoors[1] / aPrnCoors[3]
      ::nVRes   := aPrnCoors[2] / aPrnCoors[4]
      // writelog( ":"+str(aPrnCoors[1])+str(aPrnCoors[2])+str(aPrnCoors[3])+str(aPrnCoors[4])+str(aPrnCoors[5])+str(aPrnCoors[6])+str(aPrnCoors[8])+str(aPrnCoors[9]) )
      Return .T.
   ENDIF

Return .F.

METHOD AddFont( fontName, nHeight ,lBold, lItalic, lUnderline, nCharset ) CLASS HPrinter
Local oFont

   IF ::lmm .AND. nHeight != Nil
      nHeight *= ::nVRes
   ENDIF
   oFont := HFont():Add( fontName,, nHeight,          ;
       Iif( lBold!=Nil.AND.lBold,700,400 ), nCharset, ;
       Iif( lItalic!=Nil.AND.lItalic,255,0 ), Iif( lUnderline!=Nil.AND.lUnderline,1,0 ) )

Return oFont

METHOD End() CLASS HPrinter

   IF ::hDCPrn != 0
      DeleteDC( ::hDCPrn )
      ::hDCPrn := 0
   ENDIF
   IF ::hPrinter != 0
      ClosePrinter( ::hPrinter )
   ENDIF
   ::ReleaseMeta()
Return Nil

METHOD Box( x1,y1,x2,y2,oPen,oBrush ) CLASS HPrinter

   IF oPen != Nil
      SelectObject( ::hDC,oPen:handle )
   ENDIF
   IF oBrush != Nil
      SelectObject( ::hDC,oBrush:handle )
   ENDIF
   IF ::lmm
      Box( ::hDC,::nHRes*x1,::nVRes*y1,::nHRes*x2,::nVRes*y2 )
   ELSE
      Box( ::hDC,x1,y1,x2,y2 )
   ENDIF

Return Nil

METHOD Line( x1,y1,x2,y2,oPen ) CLASS HPrinter

   IF oPen != Nil
      SelectObject( ::hDC,oPen:handle )
   ENDIF
   IF ::lmm
      DrawLine( ::hDC,::nHRes*x1,::nVRes*y1,::nHRes*x2,::nVRes*y2 )
   ELSE
      DrawLine( ::hDC,x1,y1,x2,y2 )
   ENDIF

Return Nil

METHOD Say( cString,x1,y1,x2,y2,nOpt,oFont,nTextColor,nBkColor ) CLASS HPrinter
Local hFont, nOldTC, nOldBC

   IF oFont != Nil
      hFont := SelectObject( ::hDC,oFont:handle )
   ENDIF
   IF nTextColor != Nil
      nOldTC:= SetTextColor(::hDC,nTextColor)
   ENDIf
   IF nBkColor != Nil
      nOldBC:= SetBKColor(::hDC,nBkColor)
   ENDIf

   IF ::lmm
      DrawText( ::hDC,cString,::nHRes*x1,::nVRes*y1,::nHRes*x2,::nVRes*y2,Iif(nOpt==Nil,DT_LEFT,nOpt) )
   ELSE
      DrawText( ::hDC,cString,x1,y1,x2,y2,Iif(nOpt==Nil,DT_LEFT,nOpt) )
   ENDIF

   IF oFont != Nil
      SelectObject( ::hDC,hFont )
   ENDIF

   IF nTextColor != Nil
      SetTextColor(::hDC,nOldTC)
   ENDIf

   IF nBkColor != Nil
      SetBKColor(::hDC,nOldBC)
   ENDIf


Return Nil

METHOD Bitmap( x1,y1,x2,y2,nOpt,hBitmap ) CLASS HPrinter

   IF ::lmm
      DrawBitmap( ::hDC,hBitmap,Iif(nOpt==Nil,SRCAND,nOpt),::nHRes*x1,::nVRes*y1,::nHRes*(x2-x1+1),::nVRes*(y2-y1+1) )
   ELSE
      DrawBitmap( ::hDC,hBitmap,Iif(nOpt==Nil,SRCAND,nOpt),x1,y1,x2-x1+1,y2-y1+1 )
   ENDIF

Return Nil

METHOD GetTextWidth( cString, oFont ) CLASS HPrinter
Local arr, hFont

   IF oFont != Nil
      hFont := SelectObject( ::hDC,oFont:handle )
   ENDIF
   arr := GetTextSize( ::hDC,cString )
   IF oFont != Nil
      SelectObject( ::hDC,hFont )
   ENDIF

Return Iif( ::lmm, Int( arr[1]/::nHRes ), arr[1] )

METHOD StartDoc( lPreview,cMetaName ) CLASS HPrinter

   IF lPreview != Nil .AND. lPreview
      ::lPreview := .T.
      ::ReleaseMeta()
      ::aMeta := {}
      ::cMetaName := cMetaName
   ELSE
      ::lPreview := .F.
      ::hDC := ::hDCPrn
      Hwg_StartDoc( ::hDC )
   ENDIF
   ::nPage := 0

Return Nil

METHOD EndDoc() CLASS HPrinter

   IF !::lPreview
      Hwg_EndDoc( ::hDC )
   ENDIF
Return Nil

METHOD StartPage() CLASS HPrinter
Local fname

   IF ::lPreview
      fname := Iif( ::cMetaName!=Nil, ::cMetaName + Ltrim(Str(Len(::aMeta)+1)) + ".emf", Nil )
      Aadd( ::aMeta, CreateMetaFile( ::hDCPrn,fname ) )
      ::hDC := Atail( ::aMeta )
   ELSE
      Hwg_StartPage( ::hDC )
   ENDIF
   ::nPage ++

Return Nil

METHOD EndPage() CLASS HPrinter
Local nLen

   IF ::lPreview
     nLen := Len( ::aMeta )
     ::aMeta[nLen] := CloseEnhMetaFile( ::aMeta[nLen] )
     ::hDC := 0
   ELSE
     Hwg_EndPage( ::hDC )
   ENDIF
Return Nil

METHOD ReleaseMeta() CLASS HPrinter
Local i, nLen

   IF ::aMeta == Nil .OR. Empty( ::aMeta )
      Return Nil
   ENDIF

   nLen := Len( ::aMeta )
   FOR i := 1 TO nLen
      DeleteEnhMetaFile( ::aMeta[i] )
   NEXT
   ::aMeta := Nil

Return Nil

METHOD Preview( cTitle,aBitmaps,aTooltips, aBootUser ) CLASS HPrinter
Local oDlg, oToolBar, oSayPage, oBtn, oCanvas, oTimer, i, nLastPage:=Len(::aMeta), aPage:={}
Local oFont := HFont():Add( "Times New Roman",0,-13,700 )
Local lTransp := ( aBitmaps != Nil .AND. Len(aBitmaps) > 9 .AND. aBitmaps[10] != Nil .AND. aBitmaps[10] )

   FOR i:=1 to nLastPage
     aadd(aPage,str(i,4)+":"+str(nLastPage,4))
   NEXT

   IF cTitle == Nil; cTitle := "Print preview - "+::cPrinterName; ENDIF
   ::nZoom := 0
   ::nCurrPage := 1

   ::NeedsRedraw := .T.

   INIT DIALOG oDlg TITLE cTitle                  ;
     AT 40,10 SIZE GetDesktopWidth(),GetDesktopHeight()                        ;
     STYLE hwg_multibitor( WS_POPUP, WS_VISIBLE, WS_CAPTION, WS_SYSMENU, WS_SIZEBOX, WS_MAXIMIZEBOX, WS_CLIPCHILDREN ) ;
     ON INIT {|o|o:Maximize(),::ResizePreviewDlg(oCanvas,1), SetTimer(oCanvas, @oTimer)} ;
     ON EXIT {|| oCanvas:brush := NIL, .T. }


   oDlg:bScroll:={|oWnd,msg,wParam,lParam|HB_SYMBOL_UNUSED(oWnd),::ResizePreviewDlg(oCanvas,,msg,wParam,lParam)}
   oDlg:brush := HBrush():Add( 11316396 )

   @ 0,0 PANEL oToolBar SIZE 88, oDlg:nHeight


// Canvas should fill ALL the available space
   @ oToolBar:nWidth,0 PANEL oCanvas ;
     SIZE oDlg:nWidth-oToolBar:nWidth,oDlg:nHeight ;
     ON SIZE {|o,x,y|o:Move(,,x-oToolBar:nWidth,y),::ResizePreviewDlg(o)} ;
     ON PAINT {|| ::PlayMeta(oCanvas)} STYLE WS_VSCROLL+WS_HSCROLL

   oCanvas:bScroll:={|oWnd,msg,wParam,lParam|HB_SYMBOL_UNUSED(oWnd), ::ResizePreviewDlg(oCanvas,,msg,wParam,lParam)}
   // DON'T CHANGE NOR REMOVE THE FOLLOWING LINE !
   // I need it to have the correct side-effect to avoid flickering !!!
   oCanvas:brush := 0

   @ 3,2 OWNERBUTTON oBtn OF oToolBar ON CLICK {||EndDialog()} ;
        SIZE oToolBar:nWidth-6,24 TEXT "Exit" FONT oFont        ;
        TOOLTIP Iif(aTooltips!=Nil,aTooltips[1],"Exit Preview")
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 1 .AND. aBitmaps[2] != Nil
      oBtn:oBitmap  := Iif( aBitmaps[1], HBitmap():AddResource( aBitmaps[2] ), HBitmap():AddFile( aBitmaps[2] ) )
      oBtn:title    := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 1,31 LINE LENGTH oToolBar:nWidth-1

   @ 3,36 OWNERBUTTON oBtn OF oToolBar ON CLICK {||::PrintMeta()} ;   // removed ::nCurrPage by Giuseppe Mastrangelo
        SIZE oToolBar:nWidth-6,24 TEXT "Print" FONT oFont         ;
        TOOLTIP Iif(aTooltips!=Nil,aTooltips[2],"Print file")
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 2 .AND. aBitmaps[3] != Nil
      oBtn:oBitmap := Iif( aBitmaps[1], HBitmap():AddResource( aBitmaps[3] ), HBitmap():AddFile( aBitmaps[3] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3,62 COMBOBOX oSayPage ITEMS aPage of oToolBar ;
            SIZE oToolBar:nWidth-6,24 color "fff000" backcolor 12507070 ;
            ON CHANGE {|| ::ChangePage(oSayPage,,oSayPage:GetValue()) } STYLE WS_VSCROLL


   @ 3,86 OWNERBUTTON oBtn OF oToolBar ON CLICK {||::ChangePage(oSayPage,0)} ;
        SIZE oToolBar:nWidth-6,24 TEXT "|<<" FONT oFont                 ;
        TOOLTIP Iif(aTooltips!=Nil,aTooltips[3],"First page")
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 3 .AND. aBitmaps[4] != Nil
      oBtn:oBitmap := Iif( aBitmaps[1], HBitmap():AddResource( aBitmaps[4] ), HBitmap():AddFile( aBitmaps[4] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3,110 OWNERBUTTON oBtn OF oToolBar ON CLICK {||::ChangePage(oSayPage,1)} ;
        SIZE oToolBar:nWidth-6,24 TEXT ">>" FONT oFont                  ;
        TOOLTIP Iif(aTooltips!=Nil,aTooltips[4],"Next page")
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 4 .AND. aBitmaps[5] != Nil
      oBtn:oBitmap := Iif( aBitmaps[1], HBitmap():AddResource( aBitmaps[5] ), HBitmap():AddFile( aBitmaps[5] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3,134 OWNERBUTTON oBtn OF oToolBar ON CLICK {||::ChangePage(oSayPage,-1)} ;
        SIZE oToolBar:nWidth-6,24 TEXT "<<" FONT oFont    ;
        TOOLTIP Iif(aTooltips!=Nil,aTooltips[5],"Previous page")
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 5 .AND. aBitmaps[6] != Nil
      oBtn:oBitmap := Iif( aBitmaps[1], HBitmap():AddResource( aBitmaps[6] ), HBitmap():AddFile( aBitmaps[6] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3,158 OWNERBUTTON oBtn OF oToolBar ON CLICK {||::ChangePage(oSayPage,2)} ;
        SIZE oToolBar:nWidth-6,24 TEXT ">>|" FONT oFont   ;
        TOOLTIP Iif(aTooltips!=Nil,aTooltips[6],"Last page")
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 6 .AND. aBitmaps[7] != Nil
      oBtn:oBitmap := Iif( aBitmaps[1], HBitmap():AddResource( aBitmaps[7] ), HBitmap():AddFile( aBitmaps[7] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 1,189 LINE LENGTH oToolBar:nWidth-1

   @ 3,192 OWNERBUTTON oBtn OF oToolBar ON CLICK {||::ResizePreviewDlg(oCanvas,-1)} ;
        SIZE oToolBar:nWidth-6,24 TEXT "(-)" FONT oFont   ;
        TOOLTIP Iif(aTooltips!=Nil,aTooltips[7],"Zoom out")
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 7 .AND. aBitmaps[8] != Nil
      oBtn:oBitmap := Iif( aBitmaps[1], HBitmap():AddResource( aBitmaps[8] ), HBitmap():AddFile( aBitmaps[8] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3,216 OWNERBUTTON oBtn OF oToolBar ON CLICK {||::ResizePreviewDlg(oCanvas,1)} ;
        SIZE oToolBar:nWidth-6,24 TEXT "(+)" FONT oFont   ;
        TOOLTIP Iif(aTooltips!=Nil,aTooltips[8],"Zoom in")
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 8 .AND. aBitmaps[9] != Nil
      oBtn:oBitmap := Iif( aBitmaps[1], HBitmap():AddResource( aBitmaps[9] ), HBitmap():AddFile( aBitmaps[9] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 1,243 LINE LENGTH oToolBar:nWidth-1

   IF aBootUser != Nil

      @ 1,313 LINE LENGTH oToolBar:nWidth-1

      @ 3,316 OWNERBUTTON oBtn OF oToolBar  ;
           SIZE oToolBar:nWidth-6,24        ;
           TEXT Iif( Len(aBootUser)==4,aBootUser[4],"User Button" ) ;
           FONT oFont                   ;
           TOOLTIP Iif(aBootUser[3]!=Nil,aBootUser[3],"User Button")

      oBtn:bClick := aBootUser[1]

      IF aBootUser[2] != Nil
         oBtn:oBitmap := Iif( aBitmaps[1], HBitmap():AddResource( aBootUser[2] ), HBitmap():AddFile( aBootUser[2] ) )
         oBtn:title   := Nil
         oBtn:lTransp := lTransp
      ENDIF

   ENDIF

   oDlg:Activate()

   oTimer:End()

   oDlg:brush:Release()
   // oCanvas:brush:Release()
   oFont:Release()

Return Nil

Static function SetTimer( oDlg, oTimer )
   SET TIMER oTimer OF oDlg VALUE 500 ACTION {||TimerFunc(oDlg)}
Return Nil

Static Function TimerFunc(o )
   // RedrawWindow( o:handle, RDW_ERASE + RDW_INVALIDATE )
   RedrawWindow( o:handle, RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW + RDW_INVALIDATE )  // Force a complete redraw
Return Nil

METHOD ChangePage( oSayPage,n,nPage ) CLASS hPrinter

   ::NeedsRedraw := .T.
   IF nPage == nil
      IF n == 0
         ::nCurrPage := 1
      ELSEIF n == 2
         ::nCurrPage := Len(::aMeta)
      ELSEIF n == 1 .AND. ::nCurrPage < Len(::aMeta)
         ::nCurrPage ++
      ELSEIF n == -1 .AND. ::nCurrPage > 1
         ::nCurrPage --
      ENDIF
      oSayPage:SetItem(::nCurrPage)
   ELSE
      ::nCurrPage := nPage
   ENDIF

Return Nil



/***
 nZoom: zoom factor: -1 or 1, NIL if scroll message
*/
METHOD ResizePreviewDlg( oCanvas, nZoom, msg, wParam, lParam ) CLASS hPrinter
Local nWidth, nHeight, k1, k2, x, y
Local i, nPos, wmsg, nPosVert, nPosHorz

   x := oCanvas:nWidth
   y := oCanvas:nHeight

HB_SYMBOL_UNUSED(lParam)

   nPosVert:=getscrollpos(oCanvas:handle,SB_VERT)
   nPosHorz:=getscrollpos(oCanvas:handle,SB_HORZ)

   IF msg=WM_VSCROLL
      setscrollrange(oCanvas:handle,SB_VERT,1,20)
      wmsg:=loword(wParam)
      IF wmsg=SB_THUMBPOSITION .OR. wmsg=SB_THUMBTRACK
         nPosVert:=hiword(wParam)
      ELSEIF wmsg=SB_LINEUP
         nPosVert:=nPosVert-1
         IF nPosVert<1
            nPosVert:=1
         ENDIF
      ELSEIF wmsg=SB_LINEDOWN
         nPosVert:=nPosvert+1
         IF nPosVert>20
            nPosVert=20
         ENDIF
      ELSEIF wmsg=SB_PAGEDOWN
         nPosVert:=nPosVert+4
         IF nPosVert>20
            nPosVert=20
         ENDIF
      ELSEIF wmsg=SB_PAGEUP
         nPosVert:=nPosVert-4
         IF nPosVert<1
            nPosVert=1
         ENDIF
      ENDIF
         setscrollpos(oCanvas:handle,SB_VERT,nPosVert)
      ::NeedsRedraw := .T.
   ENDIF

   IF msg=WM_HSCROLL
      setscrollrange(oCanvas:handle,SB_HORZ,1,20)
      wmsg:=loword(wParam)
      IF wmsg=SB_THUMBPOSITION .OR. wmsg=SB_THUMBTRACK
         nPosHorz:=hiword(wParam)
      ELSEIF wmsg=SB_LINEUP
         nPosHorz:=nPosHorz-1
         IF nPosHorz<1
            nPosHorz=1
         ENDIF
      ELSEIF wmsg=SB_LINEDOWN
         nPosHorz:=nPosHorz+1
         IF nPosHorz>20
            nPosHorz=20
         ENDIF
      ELSEIF wmsg=SB_PAGEDOWN
         nPosHorz:=nPosHorz+4
         IF nPosHorz>20
            nPosHorz=20
         ENDIF
      ELSEIF wmsg=SB_PAGEUP
         nPosHorz:=nPosHorz-4
         IF nPosHorz<1
            nPosHorz=1
         ENDIF
      ENDIF
         setscrollpos(oCanvas:handle,SB_HORZ,nPosHorz)
      ::NeedsRedraw := .T.
   ENDIF

   IF msg == WM_MOUSEWHEEL
      SetScrollRange( oCanvas:handle, SB_VERT, 1, 20)
      IF HIWORD(wParam) > 32678
         IF ++nPosVert > 20
            nPosVert := 20
         ENDIF
      ELSE
         IF --nPosVert < 1
            nPosVert := 1
         ENDIF
      ENDIF
      SetScrollPos( oCanvas:handle, SB_VERT, nPosVert )
      ::NeedsRedraw := .T.
   ENDIF

   IF nZoom != Nil
      // If already at maximum zoom returns
      IF nZoom < 0 .AND. ::nZoom == 0
         Return Nil
      ENDIF
      ::nZoom += nZoom
      ::NeedsRedraw := .T.
   ENDIF
   k1 := ::nWidth / ::nHeight
   k2 := ::nHeight / ::nWidth

   IF ::nWidth > ::nHeight
      nWidth := x - 20
      nHeight := Round( nWidth * k2, 0 )
      IF nHeight > y - 20
         nHeight := y - 20
         nWidth := Round( nHeight * k1, 0 )
      ENDIF
      ::NeedsRedraw := .T.
   ELSE
      nHeight := y - 10
      nWidth := Round( nHeight * k1, 0 )
      IF nWidth > x - 20
         nWidth := x - 20
         nHeight := Round( nWidth * k2, 0 )
      ENDIF
      ::NeedsRedraw := .T.
   ENDIF

   IF ::nZoom > 0
      FOR i := 1 TO ::nZoom
         nWidth := Round( nWidth*1.5,0 )
         nHeight := Round( nHeight*1.5,0 )
      NEXT
      ::NeedsRedraw := .T.
   ELSEIF ::nZoom == 0
      nWidth := Round( nWidth*0.93, 0 )
      nHeight := Round( nHeight*0.93, 0 )
   ENDIF

   ::xOffset := ::yOffset := 0
   IF nHeight > y
      npos:=nPosVert
      IF nPos > 0
         ::yOffset := Round( ((nPos-1)/18) * ( nHeight - y + 10 ),0 )
      ENDIF
   ELSE
      setscrollpos(oCanvas:handle,SB_VERT,0)
   ENDIF

   IF nWidth > x
      nPos := nPosHorz
      IF nPos > 0
         nPos := ( nPos - 1 ) / 18
         ::xOffset := Round( nPos * ( nWidth - x + 10 ),0 )
      ENDIF
   ELSE
     setscrollpos(oCanvas:handle,SB_HORZ,0)
   ENDIF

   ::x1 := Iif( nWidth < x, Round( (x-nWidth)/2,0 ), 10 ) - ::xOffset
   ::x2 := ::x1 + nWidth - 1
   ::y1 := Iif( nHeight< y, Round( (y-nHeight)/2,0 ), 10 ) - ::yOffset
   ::y2 := ::y1 + nHeight - 1

   IF nZoom != Nil .OR. msg != Nil
       RedrawWindow( oCanvas:handle, RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW + RDW_INVALIDATE )  // Force a complete redraw
   ENDIF

Return Nil

METHOD PlayMeta( oWnd ) CLASS HPrinter
Local pps, hDC
Local rect
local aArray
static lRefreshVideo := .T.
static Brush := NIL
static BrushShadow := NIL
static BrushBorder := NIL
static BrushWhite := NIL
static BrushBlack := NIL
static BrushLine := NIL
static BrushBackground := NIL

   rect:=GetClientRect(oWnd:handle)

	// WriteLog(stR(rect[1])+ stR(rect[2])+ stR(rect[3])+ stR(rect[4]) )
	// offscreen canvas must be THE WHOLE CANVAS !

   IF ::xOffset == Nil
      ::ResizePreviewDlg( oWnd )
   ENDIF

   pps := DefinePaintStru()
   hDC := BeginPaint( oWnd:handle, pps )
   aArray= GetPPSRect( pps )
   // tracelog( "PPS"+str(aArray[1])+str(aArray[2])+str(aArray[3])+str(aArray[4]) )

   if ( aArray[1] == 0 .AND. aArray[2] == 0)  // IF WHOLE AREA
      if ( ::NeedsRedraw .OR. lRefreshVideo )
         if Valtype( ::memDC ) =="U"
            ::memDC := Hdc():New()
            ::memDC:CreateCompatibleDC( hDC )
            ::memBitmap := CreateCompatibleBitmap( hDC, rect[3]-rect[1], rect[4]-rect[2] )
            ::memDC:SelectObject( ::memBitmap )
            Brush           := HBrush():Add(GetSysColor( COLOR_3DHILIGHT+1 )):handle
            BrushWhite      := HBrush():Add( RGB( 255, 255, 255 ) ):handle
            BrushBlack      := HBrush():Add( RGB( 0, 0, 0 ) ):handle
            BrushLine       := HBrush():Add( RGB( 102, 100, 92 ) ):handle
            BrushBackground := HBrush():Add( RGB( 204, 200, 184 ) ):handle
            BrushShadow     := HBrush():Add( RGB( 178, 175, 161 ) ):handle
            BrushBorder     := HBrush():Add( RGB( 129, 126, 115 ) ):handle
         endif

         if ::NeedsRedraw
            // Draw the canvas background (gray)
            FillRect( ::memDC:m_hDC, rect[1], rect[2], rect[3], rect[4], BrushBackground )
            FillRect( ::memDC:m_hDC, rect[1], rect[2], rect[1], rect[4], BrushBorder )
            FillRect( ::memDC:m_hDC, rect[1], rect[2], rect[3], rect[2], BrushBorder )
            // Draw the PAPER background (white)
            FillRect( ::memDC:m_hDC, ::x1-1, ::y1-1, ::x2+1, ::y2+1, BrushLine )
            FillRect( ::memDC:m_hDC, ::x1, ::y1, ::x2, ::y2, BrushWhite )
            // Draw the actual printer data
            PlayEnhMetafile( ::memDC:m_hDC, ::aMeta[::nCurrPage], ::x1, ::y1, ::x2, ::y2 )
            // Draw
            // Rectangle( ::memDC:m_hDC, ::x1, ::y1, ::x2, ::y2 )

            FillRect( ::memDC:m_hDC, ::x2, ::y1+2, ::x2+1, ::y2+2, BrushBlack )
            FillRect( ::memDC:m_hDC, ::x2+1, ::y1+1, ::x2+2, ::y2+2, BrushShadow )
            FillRect( ::memDC:m_hDC, ::x2+1, ::y1+2, ::x2+2, ::y2+2, BrushLine )
            FillRect( ::memDC:m_hDC, ::x2+2, ::y1+2, ::x2+3, ::y2+2, BrushShadow )


            FillRect( ::memDC:m_hDC, ::x1+2, ::y2, ::x2, ::y2+2, BrushBlack )
            FillRect( ::memDC:m_hDC, ::x1+2, ::y2+1, ::x2+1, ::y2+2, BrushLine )
            FillRect( ::memDC:m_hDC, ::x1+2, ::y2+2, ::x2+2, ::y2+3, BrushShadow )
            ::NeedsRedraw := .F.
         endif
        // tracelog("bitblt")
         lRefreshVideo := .F.
         BitBlt(hDC, rect[1], rect[2], rect[3], rect[4], ::memDC:m_hDC, 0, 0, SRCCOPY)
      else   // window fully uncovered... force a repaint
         lRefreshVideo := .T.
      endif
   else
      // tracelog("no refresh video" )
      lRefreshVideo := .T.   // request a repaint
   endif


#if 0
   // Draws a line from upper left to bottom right of the PAPER
   // used to check for PAPER dimension...
   DrawLine( hDC, ::x1, ::y1, ::x2, ::y2 )
#endif

   EndPaint( oWnd:handle, pps )

Return Nil

METHOD PrintMeta( nPage ) CLASS HPrinter

   IF ::lPreview

      ::StartDoc()
      IF nPage == Nil
         FOR nPage := 1 TO Len( ::aMeta )
            PrintEnhMetafile( ::hDCPrn,::aMeta[nPage] )
         NEXT
      ELSE
         PrintEnhMetafile( ::hDCPrn,::aMeta[nPage] )
      ENDIF
      ::EndDoc()
      ::lPreview := .T.
   ENDIF
Return Nil
