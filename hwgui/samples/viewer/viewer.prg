/*
 * JPEG, BMP, PNG, MNG, TIFF images viewer.
 * FreeImage.dll should present to use this sample
 *
 * Copyright 2003 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
*/

#include "windows.ch"
#include "guilib.ch"

Function Main
Local oMainWindow, oFont
Local hDCwindow
Private oToolBar, oImage, oSayMain
Private aScreen, nKoef

   IF !FI_Init()
      Return Nil
   ENDIF

   PREPARE FONT oFont NAME "Times New Roman" WIDTH 0 HEIGHT -17

   INIT WINDOW oMainWindow MAIN TITLE "Viewer"  ;
     COLOR COLOR_3DLIGHT+1                      ;
     AT 200,0 SIZE 400,150                      ;
     FONT oFont                                 ;
     ON PAINT {|o|PaintWindow(o)}

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

   @ 106,3 SAY oSayMain CAPTION "" OF oToolBar SIZE 60,22 STYLE WS_BORDER ;
        FONT oFont BACKCOLOR 12507070

   hDCwindow := GetDC( oMainWindow:handle )
   aScreen := GetDeviceArea( hDCwindow )
   DeleteDC( hDCwindow )

   ACTIVATE WINDOW oMainWindow

Return Nil

Static Function FileOpen( oWnd )
Local mypath := "\" + CURDIR() + IIF( EMPTY( CURDIR() ), "", "\" )
Local fname := SelectFile( "Graphic files( *.jpg;*.png;*.psd;*.tif )", "*.jpg;*.png;*.psd;*.tif", mypath )
Local aCoors, nVert, nHorz

   IF !Empty( fname )
      nKoef := 1
      IF oImage != Nil
         oImage:Release()
      ENDIF
      oImage := HFreeImage():AddFile( fname )
      aCoors := GetClientRect( oWnd:handle )
      nVert := ( oWnd:nHeight - aCoors[4] )
      nHorz := ( oWnd:nWidth-aCoors[3] )
      IF aCoors[3] != oImage:nWidth .OR. aCoors[4] != oImage:nHeight + oToolBar:nHeight

         DO WHILE .T.
            oWnd:nWidth := Round( oImage:nWidth * nKoef,0 ) + nHorz
            oWnd:nHeight := Round( oImage:nHeight * nKoef,0 ) + oToolBar:nHeight + nVert

            IF ( oWnd:nWidth <= aScreen[1] .AND. oWnd:nHeight <= aScreen[2] ) .OR. nKoef < 0.15
               IF oWnd:nLeft+oWnd:nWidth >= aScreen[1]
                  oWnd:nLeft := 0
               ENDIF
               IF oWnd:nTop+oWnd:nHeight >= aScreen[2]
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

         InvalidateRect( oWnd:handle, 0 )
         // writelog( "Window: "+str(oWnd:nWidth) + str(oWnd:nHeight) + str(nKoef)+str(oImage:nWidth) + str(oImage:nHeight) )
         MoveWindow( oWnd:handle,oWnd:nLeft,oWnd:nTop,oWnd:nWidth,oWnd:nHeight )
      ELSE
         RedrawWindow( oWnd:handle, RDW_ERASE + RDW_INVALIDATE )
      ENDIF
      oSayMain:SetValue( Str(nKoef*100,4)+" %" )
   ENDIF

Return Nil

Static Function Zoom( oWnd,nOp )
Local aCoors, nVert, nHorz

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

   oWnd:nWidth := Round( oImage:nWidth * nKoef,0 ) + nHorz
   oWnd:nHeight := Round( oImage:nHeight * nKoef,0 ) + oToolBar:nHeight + nVert

   IF oWnd:nLeft+oWnd:nWidth >= aScreen[1]
      oWnd:nLeft := 0
   ENDIF
   IF oWnd:nTop+oWnd:nHeight >= aScreen[2]
      oWnd:nTop := 0
   ENDIF
   IF oWnd:nWidth < 200
      oWnd:nWidth := 200
   ENDIF
   IF oWnd:nHeight < 100
      oWnd:nHeight := 100
   ENDIF

   oSayMain:SetValue( Str(nKoef*100,4)+" %" )
   InvalidateRect( oWnd:handle, 0 )
   // writelog( "Window: "+str(oWnd:nWidth) + str(oWnd:nHeight) + str(nKoef)+str(oImage:nWidth) + str(oImage:nHeight) )
   MoveWindow( oWnd:handle,oWnd:nLeft,oWnd:nTop,oWnd:nWidth,oWnd:nHeight )

Return Nil

Static Function PaintWindow( oWnd )

   IF oImage == Nil
      Return -1
   ENDIF

   pps := DefinePaintStru()
   hDC := BeginPaint( oWnd:handle, pps )

   // writelog( "Paint: "+str(Round( oImage:nWidth * nKoef,0 )) + str(Round( oImage:nHeight * nKoef,0 )) )
   oImage:Draw( hDC, 0, oToolbar:nHeight, Round( oImage:nWidth * nKoef,0 ), Round( oImage:nHeight * nKoef,0 ) )

   EndPaint( oWnd:handle, pps )

Return 0

Static Function ImageInfo()

   IF oImage == Nil
      Return Nil
   ENDIF

Return Nil
