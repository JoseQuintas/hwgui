/*
 * $Id: hprinter.prg,v 1.17 2005-08-29 08:33:54 alkresin Exp $
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

   METHOD New( cPrinter,lmm )
   METHOD SetMode( nOrientation )
   METHOD AddFont( fontName, nHeight ,lBold, lItalic, lUnderline )
   METHOD SetFont( oFont )  INLINE SelectObject( ::hDC,oFont:handle )
   METHOD StartDoc( lPreview,cMetaName )
   METHOD EndDoc()
   METHOD StartPage()
   METHOD EndPage()
   METHOD ReleaseMeta()
   METHOD PlayMeta( nPage, oWnd )
   METHOD PrintMeta( nPage )
   METHOD Preview( cTitle )
   METHOD End()
   METHOD Box( x1,y1,x2,y2,oPen )
   METHOD Line( x1,y1,x2,y2,oPen )
   METHOD Say( cString,x1,y1,x2,y2,nOpt,oFont )
   METHOD Bitmap( x1,y1,x2,y2,nOpt,hBitmap )
   METHOD GetTextWidth( cString, oFont )

ENDCLASS

METHOD New( cPrinter,lmm ) CLASS HPrinter
Local aPrnCoors, cPrinterName, cDriverName

   IF lmm != Nil
      ::lmm := lmm
   ENDIF
   IF cPrinter == Nil
      ::hDCPrn := PrintSetup( @cPrinterName )
      ::cPrinterName := cPrinterName
   ELSEIF Empty( cPrinter )
      ::hDCPrn := Hwg_OpenDefaultPrinter( @cPrinterName )
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

METHOD Box( x1,y1,x2,y2,oPen ) CLASS HPrinter

   IF oPen != Nil
      SelectObject( ::hDC,oPen:handle )
   ENDIF
   IF ::lmm
      Rectangle( ::hDC,::nHRes*x1,::nVRes*y1,::nHRes*x2,::nVRes*y2 )
   ELSE
      Rectangle( ::hDC,x1,y1,x2,y2 )
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

METHOD Say( cString,x1,y1,x2,y2,nOpt,oFont ) CLASS HPrinter
Local hFont

   IF oFont != Nil
      hFont := SelectObject( ::hDC,oFont:handle )
   ENDIF
   IF ::lmm
      DrawText( ::hDC,cString,::nHRes*x1,::nVRes*y1,::nHRes*x2,::nVRes*y2,Iif(nOpt==Nil,DT_LEFT,nOpt) )
   ELSE
      DrawText( ::hDC,cString,x1,y1,x2,y2,Iif(nOpt==Nil,DT_LEFT,nOpt) )
   ENDIF
   IF oFont != Nil
      SelectObject( ::hDC,hFont )
   ENDIF

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
Local oDlg, oToolBar, oSayPage, oBtn, oCanvas
Local oFont := HFont():Add( "Times New Roman",0,-13,700 )
Local lTransp := ( aBitmaps != Nil .AND. Len(aBitmaps) > 9 .AND. aBitmaps[10] != Nil .AND. aBitmaps[10] )

   IF cTitle == Nil; cTitle := "Print preview - "+::cPrinterName; ENDIF
   ::nZoom := 0
   ::nCurrPage := 1

   INIT DIALOG oDlg TITLE cTitle                  ;
     AT 40,10 SIZE 600,440                        ;
     STYLE WS_POPUP+WS_VISIBLE+WS_CAPTION+WS_SYSMENU+WS_SIZEBOX+WS_MAXIMIZEBOX ;
     ON INIT {|o|o:Maximize(),ResizePreviewDlg(oCanvas,Self,1)}

   oDlg:brush := HBrush():Add( 0 )

   @ 0,0 PANEL oToolBar SIZE 44,oDlg:nHeight

   @ oToolBar:nWidth+2,3 PANEL oCanvas ;
     SIZE oDlg:nWidth-oToolBar:nWidth-4,oDlg:nHeight-5 ;
     ON SIZE {|o,x,y|o:Move(,,x-oToolBar:nWidth-4,y-5),ResizePreviewDlg(o,Self)} ;
     ON PAINT {||::PlayMeta(oCanvas)}
   oCanvas:brush := HBrush():Add( 11316396 )

   @ 3,2 OWNERBUTTON oBtn OF oToolBar ON CLICK {||EndDialog()} ;
        SIZE oToolBar:nWidth-6,24 TEXT "Exit" FONT oFont        ;
        TOOLTIP Iif(aTooltips!=Nil,aTooltips[1],"Exit Preview")
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 1 .AND. aBitmaps[2] != Nil
      oBtn:bitmap  := Iif( aBitmaps[1], HBitmap():AddResource( aBitmaps[2] ), HBitmap():AddFile( aBitmaps[2] ) )
      oBtn:text    := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 1,31 LINE LENGTH oToolBar:nWidth-1

   @ 3,36 OWNERBUTTON oBtn OF oToolBar ON CLICK {||::PrintMeta(::nCurrPage)} ;
        SIZE oToolBar:nWidth-6,24 TEXT "Print" FONT oFont         ;
        TOOLTIP Iif(aTooltips!=Nil,aTooltips[2],"Print file")
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 2 .AND. aBitmaps[3] != Nil
      oBtn:bitmap := Iif( aBitmaps[1], HBitmap():AddResource( aBitmaps[3] ), HBitmap():AddFile( aBitmaps[3] ) )
      oBtn:text   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 0,62 SAY oSayPage CAPTION "1:"+Ltrim(Str(Len(::aMeta))) OF oToolBar ;
        SIZE oToolBar:nWidth,22 STYLE WS_BORDER+SS_CENTER FONT oFont BACKCOLOR 12507070

   @ 3,86 OWNERBUTTON oBtn OF oToolBar ON CLICK {||ChangePage(oDlg,oSayPage,Self,0)} ;
        SIZE oToolBar:nWidth-6,24 TEXT "|<<" FONT oFont FLAT                ;
        TOOLTIP Iif(aTooltips!=Nil,aTooltips[3],"First page")
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 3 .AND. aBitmaps[4] != Nil
      oBtn:bitmap := Iif( aBitmaps[1], HBitmap():AddResource( aBitmaps[4] ), HBitmap():AddFile( aBitmaps[4] ) )
      oBtn:text   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3,110 OWNERBUTTON oBtn OF oToolBar ON CLICK {||ChangePage(oDlg,oSayPage,Self,1)} ;
        SIZE oToolBar:nWidth-6,24 TEXT ">>" FONT oFont FLAT                 ;
        TOOLTIP Iif(aTooltips!=Nil,aTooltips[4],"Next page")
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 4 .AND. aBitmaps[5] != Nil
      oBtn:bitmap := Iif( aBitmaps[1], HBitmap():AddResource( aBitmaps[5] ), HBitmap():AddFile( aBitmaps[5] ) )
      oBtn:text   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3,134 OWNERBUTTON oBtn OF oToolBar ON CLICK {||ChangePage(oDlg,oSayPage,Self,-1)} ;
        SIZE oToolBar:nWidth-6,24 TEXT "<<" FONT oFont FLAT   ;
        TOOLTIP Iif(aTooltips!=Nil,aTooltips[5],"Previous page")
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 5 .AND. aBitmaps[6] != Nil
      oBtn:bitmap := Iif( aBitmaps[1], HBitmap():AddResource( aBitmaps[6] ), HBitmap():AddFile( aBitmaps[6] ) )
      oBtn:text   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3,158 OWNERBUTTON oBtn OF oToolBar ON CLICK {||ChangePage(oDlg,oSayPage,Self,2)} ;
        SIZE oToolBar:nWidth-6,24 TEXT ">>|" FONT oFont FLAT  ;
        TOOLTIP Iif(aTooltips!=Nil,aTooltips[6],"Last page")
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 6 .AND. aBitmaps[7] != Nil
      oBtn:bitmap := Iif( aBitmaps[1], HBitmap():AddResource( aBitmaps[7] ), HBitmap():AddFile( aBitmaps[7] ) )
      oBtn:text   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 1,189 LINE LENGTH oToolBar:nWidth-1

   @ 3,192 OWNERBUTTON oBtn OF oToolBar ON CLICK {||ResizePreviewDlg(oCanvas,Self,-1)} ;
        SIZE oToolBar:nWidth-6,24 TEXT "(-)" FONT oFont FLAT  ;
        TOOLTIP Iif(aTooltips!=Nil,aTooltips[7],"Zoom out")
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 7 .AND. aBitmaps[8] != Nil
      oBtn:bitmap := Iif( aBitmaps[1], HBitmap():AddResource( aBitmaps[8] ), HBitmap():AddFile( aBitmaps[8] ) )
      oBtn:text   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3,216 OWNERBUTTON oBtn OF oToolBar ON CLICK {||ResizePreviewDlg(oCanvas,Self,1)} ;
        SIZE oToolBar:nWidth-6,24 TEXT "(+)" FONT oFont FLAT  ;
        TOOLTIP Iif(aTooltips!=Nil,aTooltips[8],"Zoom in")
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 8 .AND. aBitmaps[9] != Nil
      oBtn:bitmap := Iif( aBitmaps[1], HBitmap():AddResource( aBitmaps[9] ), HBitmap():AddFile( aBitmaps[9] ) )
      oBtn:text   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 1,243 LINE LENGTH oToolBar:nWidth-1

   @ 2,246 TRACKBAR ::oTrackH OF oToolBar ;
      SIZE 40,20 ;
      RANGE 1,20 ;
      INIT 1 AUTOTICKS ;
      ON DRAG {|o|ResizePreviewDlg(oCanvas,Self,,.T.)}

   @ 10,270 TRACKBAR ::oTrackV OF oToolBar ;
      SIZE 20,40 ;
      RANGE 1,20 ;
      INIT 1 AUTOTICKS VERTICAL ;
      ON DRAG {|o|ResizePreviewDlg(oCanvas,Self,,.T.)}
      
   IF aBootUser != Nil
  
      @ 1,313 LINE LENGTH oToolBar:nWidth-1

      @ 3,316 OWNERBUTTON oBtn OF oToolBar  ;
           SIZE oToolBar:nWidth-6,24        ;
           TEXT Iif( Len(aBootUser)==4,aBootUser[4],"User Button" ) ;
           FONT oFont FLAT                  ;
           TOOLTIP Iif(aBootUser[3]!=Nil,aBootUser[3],"User Button")
      
      oBtn:bClick := aBootUser[1]
      
      IF aBootUser[2] != Nil  
         oBtn:bitmap := Iif( aBitmaps[1], HBitmap():AddResource( aBootUser[2] ), HBitmap():AddFile( aBootUser[2] ) )
         oBtn:text   := Nil
         oBtn:lTransp := lTransp
      ENDIF
      
   ENDIF    

   oDlg:Activate()

   oDlg:brush:Release()
   oCanvas:brush:Release()
   oFont:Release()

Return Nil

Static Function ChangePage( oDlg,oSayPage,oPrinter,n )

   IF n == 0
      oPrinter:nCurrPage := 1
   ELSEIF n == 2
      oPrinter:nCurrPage := Len(oPrinter:aMeta)
   ELSEIF n == 1 .AND. oPrinter:nCurrPage < Len(oPrinter:aMeta)
      oPrinter:nCurrPage ++
   ELSEIF n == -1 .AND. oPrinter:nCurrPage > 1
      oPrinter:nCurrPage --
   ENDIF
   oSayPage:SetValue( Ltrim(Str(oPrinter:nCurrPage))+":"+Ltrim(Str(Len(oPrinter:aMeta))) )
   RedrawWindow( oDlg:handle, RDW_ERASE + RDW_INVALIDATE )
Return Nil

Static Function ResizePreviewDlg( oCanvas, oPrinter, nZoom, lTrack )
Local nWidth, nHeight, k1, k2, x := oCanvas:nWidth, y := oCanvas:nHeight
Local i, nPos

   IF nZoom != Nil
      IF nZoom < 0 .AND. oPrinter:nZoom == 0
         Return Nil
      ENDIF
      oPrinter:nZoom += nZoom
   ENDIF
   k1 := oPrinter:nWidth / oPrinter:nHeight
   k2 := oPrinter:nHeight / oPrinter:nWidth
   IF oPrinter:nWidth > oPrinter:nHeight
      nWidth := x - 20
      nHeight := Round( nWidth * k2, 0 )
      IF nHeight > y - 20
         nHeight := y - 20
         nWidth := Round( nHeight * k1, 0 )
      ENDIF
   ELSE
      nHeight := y - 10
      nWidth := Round( nHeight * k1, 0 )
      IF nWidth > x - 20
         nWidth := x - 20
         nHeight := Round( nWidth * k2, 0 )
      ENDIF
   ENDIF

   IF oPrinter:nZoom > 0
      FOR i := 1 TO oPrinter:nZoom
         nWidth := Round( nWidth*1.5,0 )
         nHeight := Round( nHeight*1.5,0 )
      NEXT
   ENDIF

   oPrinter:xOffset := oPrinter:yOffset := 0
   IF nHeight > y
      IF !oPrinter:oTrackV:isEnabled()
         oPrinter:oTrackV:Enable()
         oPrinter:oTrackV:SetValue( oPrinter:oTrackV:nLow )
      ELSE
         nPos := SendMessage( oPrinter:oTrackV:handle, TBM_GETPOS, 0, 0 )
         IF nPos > 0 
            nPos := ( nPos - oPrinter:oTrackV:nLow ) / ( oPrinter:oTrackV:nHigh - oPrinter:oTrackV:nLow )
            oPrinter:yOffset := Round( nPos * ( nHeight - y + 10 ),0 )
         ENDIF
      ENDIF
   ELSEIF oPrinter:oTrackV:isEnabled()
      oPrinter:oTrackV:SetValue( oPrinter:oTrackV:nLow )
      oPrinter:oTrackV:Disable()
   ENDIF

   IF nWidth > x
      IF !oPrinter:oTrackH:isEnabled()
         oPrinter:oTrackH:Enable()
         oPrinter:oTrackH:SetValue( oPrinter:oTrackH:nLow )
      ELSE
         nPos := SendMessage( oPrinter:oTrackH:handle, TBM_GETPOS, 0, 0 )
         IF nPos > 0 
            nPos := ( nPos - oPrinter:oTrackH:nLow ) / ( oPrinter:oTrackH:nHigh - oPrinter:oTrackH:nLow )
            oPrinter:xOffset := Round( nPos * ( nWidth - x + 10 ),0 )
         ENDIF
      ENDIF
   ELSEIF oPrinter:oTrackH:isEnabled()
      oPrinter:oTrackH:SetValue( oPrinter:oTrackH:nLow )
      oPrinter:oTrackH:Disable()
   ENDIF

   oPrinter:x1 := Iif( nWidth<x, Round( (x-nWidth)/2,0 ), 10 ) - oPrinter:xOffset
   oPrinter:x2 := oPrinter:x1 + nWidth - 1
   oPrinter:y1 := Iif( nHeight<y, Round( (y-nHeight)/2,0 ), 5 ) - oPrinter:yOffset
   oPrinter:y2 := oPrinter:y1 + nHeight - 1

   IF nZoom != Nil .OR. lTrack != Nil
      RedrawWindow( oCanvas:handle, RDW_ERASE + RDW_INVALIDATE )
   ENDIF

Return Nil

METHOD PlayMeta( oWnd ) CLASS HPrinter
Local pps, hDC

   IF ::xOffset == Nil
      ResizePreviewDlg( oWnd, Self )
   ENDIF

   pps := DefinePaintStru()
   hDC := BeginPaint( oWnd:handle, pps )
   FillRect( hDC, ::x1, ::y1, ::x2, ::y2, COLOR_3DHILIGHT+1 )
   PlayEnhMetafile( hDC, ::aMeta[::nCurrPage], ::x1, ::y1, ::x2, ::y2 )
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
