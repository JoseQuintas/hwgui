/*
 * $Id: viewer.prg,v 1.2 2004-11-23 07:25:05 alkresin Exp $
 *
 * JPEG, BMP, PNG, MNG, TIFF images viewer.
 * FreeImage.dll should present to use this sample
 *
 * Copyright 2003 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "guilib.ch"

#define SB_HORZ             0
#define SB_VERT             1

#define SCROLLVRANGE       20
#define SCROLLHRANGE       20

Function Main
Local oMainWindow, oFont
// Local hDCwindow
Private oToolBar, oImage, oSayMain, oSayScale
Private aScreen, nKoef, lScrollV := .F., lScrollH := .F., nStepV := 0, nStepH := 0
Private nVert, nHorz

#ifdef __FREEIMAGE__
   IF !FI_Init()
      Return Nil
   ENDIF
#endif

   PREPARE FONT oFont NAME "Times New Roman" WIDTH 0 HEIGHT -17

   INIT WINDOW oMainWindow MAIN TITLE "Viewer"  ;
     COLOR COLOR_3DLIGHT+1                      ;
     AT 200,0 SIZE 400,150                      ;
     FONT oFont                                 ;
     ON OTHER MESSAGES {|o,m,wp,lp|MessagesProc(o,m,wp,lp)}
     //      ON PAINT {|o|PaintWindow(o)}               ;

   MENU OF oMainWindow
      MENU TITLE "&File"
         MENUITEM "&Open" ACTION FileOpen( oMainWindow )
         SEPARATOR
         MENUITEM "&Exit"+Chr(9)+"Alt+x" ACTION EndWindow() ;
           ACCELERATOR FALT,Asc("X")
      ENDMENU
      MENU TITLE "&View"
         MENUITEM "Zoom &in" ACTION Zoom( oMainWindow,-1 )
         MENUITEM "Zoom &out" ACTION Zoom( oMainWindow,1 )
         MENUITEM "Ori&ginal size" ACTION Zoom( oMainWindow,0 )
      ENDMENU
      MENU TITLE "&Help"
         MENUITEM "&About" ACTION MsgInfo("About")
      ENDMENU
   ENDMENU

   @ 0,0 PANEL oToolBar SIZE oMainWindow:nWidth,28 ;
      ON SIZE {|o,x,y|MoveWindow(o:handle,0,0,x,o:nHeight)}

   @ 2,2 OWNERBUTTON OF oToolBar ON CLICK {||FileOpen(oMainWindow)} ;
        SIZE 24,24 BITMAP "BMP_OPEN" FROM RESOURCE FLAT             ;
        TOOLTIP "Open file"
   @ 26,2 OWNERBUTTON OF oToolBar ON CLICK {||Zoom( oMainWindow,1 )} ;
        SIZE 24,24 BITMAP "BMP_ZOUT" FROM RESOURCE FLAT              ;
        TOOLTIP "Zoom out"
   @ 50,2 OWNERBUTTON OF oToolBar ON CLICK {||Zoom( oMainWindow,-1)} ;
        SIZE 24,24 BITMAP "BMP_ZIN" FROM RESOURCE FLAT               ;
        TOOLTIP "Zoom in"
   @ 74,2 OWNERBUTTON OF oToolBar ON CLICK {||ImageInfo()} ;
        SIZE 24,24 BITMAP "BMP_INFO" FROM RESOURCE TRANSPARENT FLAT  ;
        TOOLTIP "Info"

   @ 106,3 SAY oSayScale CAPTION "" OF oToolBar SIZE 60,22 STYLE WS_BORDER ;
        FONT oFont BACKCOLOR 12507070

#ifdef __FREEIMAGE__
   @ 0,oToolBar:nHeight IMAGE oSayMain SHOW Nil SIZE oMainWindow:nWidth, oMainWindow:nHeight
#else
   @ 0,oToolBar:nHeight BITMAP oSayMain SHOW Nil SIZE oMainWindow:nWidth, oMainWindow:nHeight
#endif

   aScreen := GetWorkareaRect()
   // writelog( str(aScreen[1])+str(aScreen[2])+str(aScreen[3])+str(aScreen[4]) )

   ACTIVATE WINDOW oMainWindow

Return Nil

Static Function MessagesProc( oWnd, msg, wParam, lParam )
Local i, aItem

   IF msg == WM_VSCROLL
      Vscroll( oWnd,LoWord( wParam ),HiWord( wParam ) )
   ELSEIF msg == WM_HSCROLL
      Hscroll( oWnd,LoWord( wParam ),HiWord( wParam ) )
   ELSEIF msg == WM_KEYUP
      IF wParam == 40        // Down
        VScroll( oWnd, SB_LINEDOWN )
      ELSEIF wParam == 38    // Up
        VScroll( oWnd, SB_LINEUP )
      ELSEIF wParam == 39    // Right
        HScroll( oWnd, SB_LINEDOWN )
      ELSEIF wParam == 37    // Left
        HScroll( oWnd, SB_LINEUP )
      ENDIF
   ENDIF

Return -1

Static Function Vscroll( oWnd, nScrollCode, nNewPos )
Local stepV

   IF nScrollCode == SB_LINEDOWN
      IF nStepV < SCROLLVRANGE
         nStepV ++
         stepV := Round( ( Round( oImage:nHeight * nKoef,0 ) - ( oWnd:nHeight-oToolbar:nHeight-nVert ) ) / SCROLLVRANGE, 0 )
         oSayMain:nOffsetV := - nStepV * stepV
         SetScrollInfo( oWnd:handle, SB_VERT, 1, nStepV+1, 1, SCROLLVRANGE )
         RedrawWindow( oSayMain:handle, RDW_ERASE + RDW_INVALIDATE )
      ENDIF
   ELSEIF nScrollCode == SB_LINEUP
      IF nStepV > 0
         nStepV --
         stepV := Round( ( Round( oImage:nHeight * nKoef,0 ) - ( oWnd:nHeight-oToolbar:nHeight-nVert ) ) / SCROLLVRANGE, 0 )
         oSayMain:nOffsetV := - nStepV * stepV
         SetScrollInfo( oWnd:handle, SB_VERT, 1, nStepV+1, 1, SCROLLVRANGE )
         RedrawWindow( oSayMain:handle, RDW_ERASE + RDW_INVALIDATE )
      ENDIF
   ELSEIF nScrollCode == SB_THUMBTRACK
      IF --nNewPos != nStepV
         nStepV := nNewPos
         stepV := Round( ( Round( oImage:nHeight * nKoef,0 ) - ( oWnd:nHeight-oToolbar:nHeight-nVert ) ) / SCROLLVRANGE, 0 )
         oSayMain:nOffsetV := - nStepV * stepV
         SetScrollInfo( oWnd:handle, SB_VERT, 1, nStepV+1, 1, SCROLLVRANGE )
         RedrawWindow( oSayMain:handle, RDW_ERASE + RDW_INVALIDATE )
      ENDIF
   ENDIF

Return Nil

Static Function Hscroll( oWnd, nScrollCode, nNewPos )
Local stepH

   IF nScrollCode == SB_LINEDOWN
      IF nStepH < SCROLLHRANGE
         nStepH ++
         stepH := Round( Round( oImage:nWidth * nKoef - ( oWnd:nWidth-nHorz ),0 ) / SCROLLVRANGE, 0 )
         oSayMain:nOffsetH := - nStepH * stepH
         SetScrollInfo( oWnd:handle, SB_HORZ, 1, nStepH+1, 1, SCROLLHRANGE )
         RedrawWindow( oSayMain:handle, RDW_ERASE + RDW_INVALIDATE )
      ENDIF
   ELSEIF nScrollCode == SB_LINEUP
      IF nStepH > 0
         nStepH --
         stepH := Round( Round( oImage:nWidth * nKoef - ( oWnd:nWidth-nHorz ),0 ) / SCROLLVRANGE, 0 )
         oSayMain:nOffsetH := - nStepH * stepH
         SetScrollInfo( oWnd:handle, SB_HORZ, 1, nStepH+1, 1, SCROLLHRANGE )
         RedrawWindow( oSayMain:handle, RDW_ERASE + RDW_INVALIDATE )
      ENDIF
   ELSEIF nScrollCode == SB_THUMBTRACK
      IF --nNewPos != nStepH
         nStepH := nNewPos
         stepH := Round( Round( oImage:nWidth * nKoef - ( oWnd:nWidth-nHorz ),0 ) / SCROLLVRANGE, 0 )
         oSayMain:nOffsetH := - nStepH * stepH
         SetScrollInfo( oWnd:handle, SB_HORZ, 1, nStepH+1, 1, SCROLLHRANGE )
         RedrawWindow( oSayMain:handle, RDW_ERASE + RDW_INVALIDATE )
      ENDIF

   ENDIF

Return Nil

Static Function FileOpen( oWnd )
Local mypath := "\" + CURDIR() + IIF( EMPTY( CURDIR() ), "", "\" )
Local fname
Local aCoors

#ifdef __FREEIMAGE__
   fname := SelectFile( "Graphic files( *.jpg;*.png;*.psd;*.tif )", "*.jpg;*.png;*.psd;*.tif", mypath )
#else
   fname := SelectFile( "Graphic files( *.jpg;*.gif;*.bmp )", "*.jpg;*.gif;*.bmp", mypath )
#endif
   IF !Empty( fname )
      nKoef := 1
      nStepV := nStepH := 0
      IF lScrollH
         SetScrollInfo( oWnd:handle, SB_HORZ, 1, nStepH+1, 1, SCROLLHRANGE )
      ENDIF
      IF lScrollV
         SetScrollInfo( oWnd:handle, SB_VERT, 1, nStepV+1, 1, SCROLLVRANGE )
      ENDIF
      /*
      IF oImage != Nil
         oImage:Release()
      ENDIF
      */
#ifdef __FREEIMAGE__
      // oImage := HFreeImage():AddFile( fname )
      oSayMain:ReplaceImage( fname )
#else
      // oImage := HBitmap():AddFile( fname )
      oSayMain:ReplaceBitmap( fname )
#endif
      oImage := oSayMain:oImage
      oSayMain:nOffsetH := oSayMain:nOffsetV := 0

      lScrollV := lScrollH := .F.
      ShowScrollBar( oWnd:handle,SB_HORZ,lScrollH )
      ShowScrollBar( oWnd:handle,SB_VERT,lScrollV )

      aCoors := GetClientRect( oWnd:handle )
      nVert := ( oWnd:nHeight - aCoors[4] )
      nHorz := ( oWnd:nWidth-aCoors[3] )
      DO WHILE .T.
         oWnd:nWidth := Round( oImage:nWidth * nKoef,0 ) + nHorz
         oWnd:nHeight := Round( oImage:nHeight * nKoef,0 ) + oToolBar:nHeight + nVert

         IF ( oWnd:nWidth <= aScreen[3] .AND. oWnd:nHeight <= aScreen[4] ) .OR. nKoef < 0.15
            IF oWnd:nLeft+oWnd:nWidth >= aScreen[3]
               oWnd:nLeft := 0
            ENDIF
            IF oWnd:nTop+oWnd:nHeight >= aScreen[4]
               oWnd:nTop := 0
            ENDIF
            EXIT
         ENDIF
         nKoef -= 0.1
      ENDDO
      IF oWnd:nWidth < 200
         oWnd:nWidth := 200
      ENDIF
      IF oWnd:nHeight < 100
         oWnd:nHeight := 100
      ENDIF

      // writelog( "Window: "+str(oWnd:nWidth) + str(oWnd:nHeight) + str(nKoef)+str(oImage:nWidth) + str(oImage:nHeight) )
      MoveWindow( oWnd:handle,oWnd:nLeft,oWnd:nTop,oWnd:nWidth,oWnd:nHeight )
      oSayMain:nZoom := nKoef
      InvalidateRect( oSayMain:handle, 0 )
      oSayMain:Move( ,,oWnd:nWidth-nHorz,oWnd:nHeight-nVert-oToolBar:nHeight )
      oSayScale:SetValue( Str(nKoef*100,4)+" %" )
   ENDIF

Return Nil

Static Function Zoom( oWnd,nOp )
Local aCoors
Local stepV, stepH

   IF oImage == Nil
      Return Nil
   ENDIF
   aCoors := GetClientRect( oWnd:handle )
   nVert := ( oWnd:nHeight - aCoors[4] )
   nHorz := ( oWnd:nWidth-aCoors[3] )

   IF nOp < 0 .AND. nKoef > 0.11
      nKoef -= 0.1
   ELSEIF nOp > 0
      nKoef += 0.1
   ELSEIF nOp == 0
      nKoef := 1
   ENDIF

   lScrollV := lScrollH := .F.
   oWnd:nWidth := Round( oImage:nWidth * nKoef,0 ) + nHorz
   oWnd:nHeight := Round( oImage:nHeight * nKoef,0 ) + oToolBar:nHeight + nVert
   // writelog( "1->"+str(oWnd:nWidth)+str(aScreen[3])+" - "+str(oWnd:nHeight)+str(aScreen[4]) )
   IF oWnd:nLeft+oWnd:nWidth >= aScreen[3]
      oWnd:nLeft := 0
      IF oWnd:nWidth >= aScreen[3]
         oWnd:nWidth := aScreen[3]
         lScrollH := .T.
         // writelog( "2->"+str(oWnd:nWidth)+str(aScreen[3])+" - "+str(oWnd:nHeight)+str(aScreen[4]) )
      ENDIF
   ENDIF
   IF oWnd:nTop+oWnd:nHeight >= aScreen[4]
      oWnd:nTop := 0
      IF oWnd:nHeight >= aScreen[4]
         oWnd:nHeight := aScreen[4]
         lScrollV := .T.
         // writelog( "3->"+str(oWnd:nWidth)+str(aScreen[3])+" - "+str(oWnd:nHeight)+str(aScreen[4]) )
      ENDIF
   ENDIF
   IF oWnd:nWidth < 200
      oWnd:nWidth := 200
   ENDIF
   IF oWnd:nHeight < 100
      oWnd:nHeight := 100
   ENDIF

   oSayMain:nZoom := nKoef
   oSayScale:SetValue( Str(nKoef*100,4)+" %" )
   InvalidateRect( oWnd:handle, 0 )
   // writelog( "Window: "+str(oWnd:nWidth) + str(oWnd:nHeight) + str(nKoef)+str(oImage:nWidth) + str(oImage:nHeight) )
   MoveWindow( oWnd:handle,oWnd:nLeft,oWnd:nTop,oWnd:nWidth,oWnd:nHeight )
   stepV := Round( ( Round( oImage:nHeight * nKoef,0 ) - ( oWnd:nHeight-oToolbar:nHeight-nVert ) ) / SCROLLVRANGE, 0 )
   stepH := Round( Round( oImage:nWidth * nKoef - ( oWnd:nWidth-nHorz ),0 ) / SCROLLVRANGE, 0 )
   oSayMain:nOffsetV := - nStepV * stepV
   oSayMain:nOffsetH := - nStepH * stepH
   oSayMain:Move( ,,oWnd:nWidth-nHorz,oWnd:nHeight-nVert-oToolBar:nHeight )
   ShowScrollBar( oWnd:handle,SB_HORZ,lScrollH )
   ShowScrollBar( oWnd:handle,SB_VERT,lScrollV )

Return Nil

/*
Static Function PaintWindow( oWnd )
Local stepV, stepH
Local nOffsV, nOffsH

   IF oImage == Nil
      Return -1
   ENDIF

   stepV := Round( ( Round( oImage:nHeight * nKoef,0 ) - ( oWnd:nHeight-oToolbar:nHeight-nVert ) ) / SCROLLVRANGE, 0 )
   stepH := Round( Round( oImage:nWidth * nKoef - ( oWnd:nWidth-nHorz ),0 ) / SCROLLVRANGE, 0 )
   nOffsV := nStepV * stepV
   nOffsH := nStepH * stepH

   pps := DefinePaintStru()
   hDC := BeginPaint( oWnd:handle, pps )

   // writelog( "Paint: "+str(Round( oImage:nWidth * nKoef,0 )) + str(Round( oImage:nHeight * nKoef,0 )) )
#ifdef __FREEIMAGE__
   oImage:Draw( hDC, -nOffsH, oToolbar:nHeight-nOffsV, Round( oImage:nWidth * nKoef,0 ), Round( oImage:nHeight * nKoef,0 ) )
#else
   DrawBitmap( hDC, oImage:handle,, -nOffsH, oToolbar:nHeight-nOffsV, Round( oImage:nWidth * nKoef,0 ), Round( oImage:nHeight * nKoef,0 ) )
#endif

   IF lScrollV
      SetScrollInfo( oWnd:handle, SB_VERT, 1, nStepV+1, 1, SCROLLVRANGE )
   ENDIF
   EndPaint( oWnd:handle, pps )

Return 0
*/

Static Function ImageInfo()

   IF oImage == Nil
      Return Nil
   ENDIF

Return Nil

#pragma BEGINDUMP

#include <windows.h>
#include "hbapi.h"
#include "hbapicdp.h"

#define SPI_GETWORKAREA     48

HB_FUNC( GETWORKAREARECT )
{
   RECT rc;
   PHB_ITEM aMetr = hb_itemArrayNew( 4 );
   PHB_ITEM temp;

   SystemParametersInfo(

       SPI_GETWORKAREA, // system parameter to query or set
       0,               // depends on action to be taken
       (PVOID) &rc,     // depends on action to be taken
       0                // user profile update flag
      );

   temp = hb_itemPutNI( NULL, rc.left );
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNI( NULL, rc.top );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNI( NULL, rc.right );
   hb_itemArrayPut( aMetr, 3, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNI( NULL, rc.bottom );
   hb_itemArrayPut( aMetr, 4, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );

}

#pragma ENDDUMP
