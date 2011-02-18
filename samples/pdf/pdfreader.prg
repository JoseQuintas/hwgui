/*
 *$Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 * pdfreader.prg - sample of ActiveX container for the Acrobat Reader ocx
 *
 *
 * Copyright 2006 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * Sample code derived from a sample code found on Internet.... oohg ?
 *
 */

#include "hwgui.ch"
#include "rmchart.ch"
#include "hbclass.ch"



Function Main
Local oMainWnd, oPanel
Private oPdf

   INIT WINDOW oMainWnd TITLE "Pdf example" AT 200,0 SIZE 500,400

   MENU OF oMainWnd
      MENU TITLE "File"
         MENUITEM "E&xit" ACTION oMainWnd:Close()
      ENDMENU
   ENDMENU

   @ 0,0 PANEL oPanel SIZE 500,366 ON SIZE {|o,x, y| o:Move(,,x,y), opdf:Move(,,x,y), opdf:Refresh() }

   opdf := ViewPdf( oPanel, "SAMPLE.PDF", 0, 0, 500, 366 )

   ACTIVATE WINDOW oMainWnd

Return

CLASS PdfReader  FROM HActiveX
CLASS VAR winclass INIT "Pdfreader"
  METHOD New()
ENDCLASS


METHOD New(p1,p2,p3,p4,p5,p6) CLASS PdfReader
  Super:New(p1,p2,p3,p4,p5,p6)
RETURN

function ViewPdf(oWindow, cPdfFile, col, row, nHeight, nWidth)
    local oPdf

    oPdf := PdfReader():New( oWindow, "AcroPDF.PDF.1", 0, 0, nHeight, nWidth )
    oPdf:LoadFile(cPdfFile)

    return oPdf


