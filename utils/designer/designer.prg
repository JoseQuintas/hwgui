/*
 * $Id$
 *
 * Designer
 * Main file
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

// LFB pos
#include "hbextern.ch"
// END LFB

#include "windows.ch"
#include "guilib.ch"
#include "hbclass.ch"
#include "hxml.ch"
#include "extmodul.ch"

#define  MAX_RECENT_FILES  8

STATIC lOmmitMenuFile := .F.
STATIC oMenuTool, oDlgx

REQUEST HWG_DRAWEDGE
REQUEST HWG_DRAWICON
REQUEST HWG_ELLIPSE
REQUEST HWG_SETWINDOWFONT
REQUEST HWG_INITMONTHCALENDAR
REQUEST HWG_INITTRACKBAR
REQUEST HTIMER, DBCREATE, DBUSEAREA, DBCREATEINDEX, DBSEEK
REQUEST BARCODE

REQUEST HWG_GETPRINTERS

#ifndef __XHARBOUR__
   ANNOUNCE GTSYS
   REQUEST HB_GT_NUL_DEFAULT
#endif

FUNCTION _AppMain( p0, p1, p2 )
   LOCAL oPanel, oTab, oFont, oStatus1, cResForm, i
   // LOCAL oMainWin
   MEMVAR oDesigner, cCurDir, oDlgx
   MEMVAR crossCursor, vertCursor, horzCursor, handCursor

   PUBLIC oDesigner, cCurDir, oMenuTool
   PUBLIC crossCursor, vertCursor, horzCursor, handCursor
   // :LFB
   REQUEST DBFCDX,DBFFPT
   RDDSETDEFAULT("DBFCDX")   // Set up DBFNTX as default driver
   // :END LFB

   // hb_cdpSelect( "RU1251" )
   oDesigner := HDesigner():New()

   IF p0 != NIL .AND. ( p0 == "-r" .OR. p0 == "/r" )
      oDesigner:lReport := .T.
      IF p1 != NIL
         IF Left( p1, 1 ) $ "-/"
            p0 := p1
            p1 := p2
         ELSE
            p0 := "-f"
         ENDIF
      ENDIF
   ENDIF

#ifdef INTEGRATED
// #ifdef MODAL
   IF p0 == "-s" .OR. p0 == "/s"
      oDesigner:lSingleForm := .T.
   ENDIF
// #endif
#endif

   //IF !__mvExist( "cCurDir" )
   //   __mvPublic( "cCurDir" )
   //ENDIF

   IF Valtype( cCurDir ) != "C"
      cCurDir := hwg_Getcurrentdir() + "\"
   ENDIF
   oDesigner:ds_mypath := cCurDir

   IF !ReadIniFiles()
      RETURN Nil
   ENDIF

   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13
   IF Valtype( crossCursor ) != "N"
      crossCursor := hwg_Loadcursor( IDC_CROSS )
      horzCursor  := hwg_Loadcursor( IDC_SIZEWE )
      vertCursor  := hwg_Loadcursor( IDC_SIZENS )
      // :LFB
      handCursor   := hwg_Loadcursor( IDC_HAND )  //65581
      // :END LFB
   ENDIF

#ifdef INTEGRATED
   INIT DIALOG oDesigner:oMainWnd AT 0,0 SIZE 400,200 TITLE iif(!oDesigner:lReport,"Form","Report")+" designer" ;
      FONT oFont                          ;
      ON INIT {|o|StartDes(o,p0,p1)}   ;
      ON EXIT {||EndIde()}
#else

 //  INIT WINDOW oDesigner:oMainWnd MAIN AT 0,0 SIZE 280,200 TITLE iif(!oDesigner:lReport,"Form","Report")+" designer" ;

   INIT WINDOW oDesigner:oMainWnd MAIN AT 0,0 SIZE 400,200 ;
      TITLE iif(!oDesigner:lReport,"Form","Report")+" designer" ;
      FONT oFont                                                ;
      ON EXIT {||EndIde()}

#endif

   MENU OF oDesigner:oMainWnd
      MENU TITLE "&File"
         IF !oDesigner:lSingleForm
            MENUITEM "&New "+iif(!oDesigner:lReport,"Form","Report")  ACTION HFormGen():New()
            MENUITEM "&Open "+iif(!oDesigner:lReport,"Form","Report") ACTION HFormGen():Open()
            SEPARATOR
            MENUITEM "&Save "+iif(!oDesigner:lReport,"Form","Report")   ACTION Iif(HFormGen():oDlgSelected!=Nil,HFormGen():oDlgSelected:oParent:Save(),hwg_Msgstop("No Form in use!", "Designer"))
            MENUITEM "&Save as ..." ACTION Iif(HFormGen():oDlgSelected!=Nil,HFormGen():oDlgSelected:oParent:Save(.T.),hwg_Msgstop("No Form in use!"))
            MENUITEM "&Close "+iif(!oDesigner:lReport,"Form","Report")  ACTION Iif(HFormGen():oDlgSelected!=Nil,HFormGen():oDlgSelected:oParent:End(),hwg_Msgstop("No Form in use!", "Designer"))
         ELSE
            IF !lOmmitMenuFile
               MENUITEM "&Open "+iif(!oDesigner:lReport,"Form","Report") ACTION HFormGen():OpenR()
               SEPARATOR
               MENUITEM "&Save as ..." ACTION ( oDesigner:lSingleForm:=.F.,HFormGen():oDlgSelected:oParent:Save(.T.),oDesigner:lSingleForm:=.T. )
            ENDIF
         ENDIF
         SEPARATOR
         MENU TITLE "Recent "+iif(!oDesigner:lReport,"Form","Report")
         IF !lOmmitMenuFile
            i := 1
            DO WHILE i <= MAX_RECENT_FILES .AND. oDesigner:aRecent[i] != Nil
               Hwg_DefineMenuItem( oDesigner:aRecent[i], 1020+i, ;
                  &( "{||HFormGen():Open('"+oDesigner:aRecent[i]+"')}" ) )
               i ++
            ENDDO
         ENDIF
         ENDMENU
         SEPARATOR
         MENUITEM If(!lOmmitMenuFile,"&Exit","&Close Designer") ACTION oDesigner:oMainWnd:Close()
      ENDMENU
      MENU TITLE "&Edit"
         MENUITEM "&Copy control" ACTION (oDesigner:oClipBrd:=GetCtrlSelected(HFormGen():oDlgSelected),Iif(oDesigner:oClipBrd!=Nil,hwg_Enablemenuitem(,1012,.T.,.T.),.F.))
         MENUITEM "&Paste" ID 1012 ACTION oDesigner:addItem := oDesigner:oClipbrd
      ENDMENU
      MENU TITLE "&View"
         MENUITEM "&Object Inspector" ID 1010 ACTION Iif( oDesigner:oDlgInsp==Nil,InspOpen(),oDesigner:oDlgInsp:Close() )
         SEPARATOR
         MENUITEM "&Show Grid 5px" ID 1050 ACTION ShowGrid5px()
         MENUITEM "&Show Grid 10px" ID 1052 ACTION ShowGrid10px()
         MENUITEM "S&nap to Grid" ID 1051 ACTION hwg_Checkmenuitem(oDesigner:oMainWnd:handle,1051,!hwg_Ischeckedmenuitem(oDesigner:oMainWnd:handle,1051))
         SEPARATOR
         MENUITEM "&Preview"  ACTION DoPreview()
         SEPARATOR
         MENUITEM "&ToolBars"  ACTION socontroles()
      ENDMENU
      MENU TITLE "&Control"
         MENUITEM "&Delete"  ACTION DeleteCtrl()
      ENDMENU
      MENU TITLE "&Options"
         MENUITEM "&AutoAdjust" ID 1011 ACTION hwg_Checkmenuitem(oDesigner:oMainWnd:handle,1011,!hwg_Ischeckedmenuitem(oDesigner:oMainWnd:handle,1011))
      ENDMENU
      MENU TITLE "&Help"
         MENUITEM "&About" ACTION hwg_Msginfo("Visual Designer", "Designer")
      ENDMENU
   ENDMENU

   IF ( oDesigner:nPixelGrid == 12 )
       hwg_Checkmenuitem(oDesigner:oMainWnd:handle,1050,.T.)
   ELSE
       hwg_Checkmenuitem(oDesigner:oMainWnd:handle,1052,.T.)
   ENDIF

   @ 0,0 PANEL oPanel SIZE 280,200 ON SIZE {|o,x,y|hwg_Movewindow(o:handle,0,0,x,y-21),statusbarmsg('')}

   IF !oDesigner:lSingleForm
      @ 2,3 OWNERBUTTON OF oPanel       ;
          ON CLICK {||HFormGen():New()} ;
          SIZE 24,24 FLAT               ;
          BITMAP "BMP_NEW" FROM RESOURCE TRANSPARENT COORDINATES 0,4,0,0  ;
          TOOLTIP "New Form"
      @ 26,3 OWNERBUTTON OF oPanel       ;
          ON CLICK {||HFormGen():Open()} ;
          SIZE 24,24 FLAT                ;
          BITMAP "BMP_OPEN" FROM RESOURCE TRANSPARENT COORDINATES 0,4,0,0  ;
          TOOLTIP "Open Form"

      @ 55,6 LINE LENGTH 18 VERTICAL

      @ 60,3 OWNERBUTTON OF oPanel       ;
          ON CLICK {||Iif(HFormGen():oDlgSelected!=Nil,HFormGen():oDlgSelected:oParent:Save(),hwg_Msgstop("No Form in use!"))} ;
          SIZE 24,24 FLAT                ;
          BITMAP "BMP_SAVE" FROM RESOURCE TRANSPARENT COORDINATES 0,4,0,0  ;
          TOOLTIP "Save Form"
      @ 84,6 LINE LENGTH 18 VERTICAL

      @ 89,3 OWNERBUTTON OF oPanel       ;
          ON CLICK {||doPreview()} ;
          SIZE 24,24 FLAT                ;
          BITMAP "smNext" FROM RESOURCE TRANSPARENT COORDINATES 0,4,0,0  ;
          TOOLTIP "Preview Form"

      // : LFB pos
      @ 164,6 LINE LENGTH 18 VERTICAL
      @ 166,3 OWNERBUTTON OF oPanel       ;
          ON CLICK {|| Iif( oDesigner:oDlgInsp==Nil,InspOpen(),InspShow())} ;
          SIZE 24,24 FLAT                ;
          BITMAP "smProprie" FROM RESOURCE TRANSPARENT COORDINATES 0,4,0,0  ;
          TOOLTIP "Propriedades"
      @ 192,6 LINE LENGTH 18 VERTICAL
      @ 194,3 OWNERBUTTON OF oPanel       ;
          ON CLICK {|| Asels_ajustar(1)} ;
          SIZE 24,24 FLAT                ;
          BITMAP "smAlignLeft" FROM RESOURCE TRANSPARENT COORDINATES 0,4,0,0  ;
          TOOLTIP "Align left sides"
      @ 218,3 OWNERBUTTON OF oPanel       ;
          ON CLICK {|| Asels_ajustar(2)} ;
          SIZE 24,24 FLAT                ;
          BITMAP "smAlignRight" FROM RESOURCE TRANSPARENT COORDINATES 0,4,0,0  ;
          TOOLTIP "Align Right sides"
      @ 242,3 OWNERBUTTON OF oPanel       ;
          ON CLICK {|| Asels_ajustar(3)} ;
          SIZE 24,24 FLAT                ;
          BITMAP "smAlignTop" FROM RESOURCE TRANSPARENT COORDINATES 0,4,0,0  ;
          TOOLTIP "Align Top Edges"
      @ 268,6 LINE LENGTH 18 VERTICAL
      @ 270,3 OWNERBUTTON OF oPanel       ;
          ON CLICK {|| Asels_ajustar(5)} ;
          SIZE 24,24 FLAT                ;
          BITMAP "smSameWidth" FROM RESOURCE TRANSPARENT COORDINATES 0,4,0,0  ;
          TOOLTIP "Same Width"
      @ 294,3 OWNERBUTTON OF oPanel       ;
          ON CLICK {|| Asels_ajustar(6)} ;
          SIZE 24,24 FLAT                ;
          BITMAP "smSameHeight" FROM RESOURCE TRANSPARENT COORDINATES 0,4,0,0  ;
          TOOLTIP "Same Height"
      @ 320,6 LINE LENGTH 18 VERTICAL
      @ 322,3 OWNERBUTTON OF oPanel       ;
          ON CLICK {|| Asels_ajustar(7)} ;
          SIZE 24,24 FLAT                ;
          BITMAP "smCenterHorz" FROM RESOURCE TRANSPARENT COORDINATES 0,4,0,0  ;
          TOOLTIP "Center Horizontally"
      @ 344,3 OWNERBUTTON OF oPanel       ;
          ON CLICK {|| Asels_ajustar(8)} ;
          SIZE 24,24 FLAT                ;
          BITMAP "smCentervert" FROM RESOURCE TRANSPARENT COORDINATES 0,4,0,0  ;
          TOOLTIP "center Vertically"

      // : END LFB

   ENDIF

   ADD STATUS oStatus1 TO oDesigner:oMainWnd ;
      PARTS oDesigner:oMainWnd:nWidth-280,80,80, 40,40,40 ;
      FONT HFont():Add( "MS Sans Serif",0,-12,400,,,)

   @ 3,30 TAB oTab ITEMS {} OF oPanel SIZE 380,310 FONT oFont ;
      ON SIZE {|o,x,y|ArrangeBtn(o,x,y)}

   BuildSet( oTab )

   CONTEXT MENU oDesigner:oCtrlMenu
      MENUITEM "Copy"   ACTION (oDesigner:oClipBrd:=GetCtrlSelected(HFormGen():oDlgSelected),Iif(oDesigner:oClipBrd!=Nil,hwg_Enablemenuitem(,1012,.T.,.T.),.F.))
      SEPARATOR
      MENUITEM "Adjust to left"  ACTION AdjustCtrl( GetCtrlSelected(HFormGen():oDlgSelected),.T.,.F.,.F.,.F. )
      MENUITEM "Adjust to top"   ACTION AdjustCtrl( GetCtrlSelected(HFormGen():oDlgSelected),.F.,.T.,.F.,.F. )
      MENUITEM "Adjust to right" ACTION AdjustCtrl( GetCtrlSelected(HFormGen():oDlgSelected),.F.,.F.,.T.,.F. )
      MENUITEM "Adjust to bottom" ACTION AdjustCtrl( GetCtrlSelected(HFormGen():oDlgSelected),.F.,.F.,.F.,.T. )
      // : LFB
      SEPARATOR
      MENUITEM "Align left sides"  ACTION Asels_ajustar(1)
      MENUITEM "Align Right sides"  ACTION Asels_ajustar(2)
      MENUITEM "Align Top Edges"  ACTION Asels_ajustar(3)
      //MENUITEM "Align Bottom Edges"  ACTION Asels_ajustar(4)
      MENUITEM "Same Width"  ACTION Asels_ajustar(5)
      MENUITEM "Same Height"  ACTION Asels_ajustar(6)
      // :END LFB
      SEPARATOR
      IF oDesigner:lReport
         MENUITEM "Fit into box" ID 1030 ACTION FitLine( GetCtrlSelected(HFormGen():oDlgSelected) )
         SEPARATOR
      ENDIF
      MENUITEM "Delete" ACTION DeleteCtrl()
      SEPARATOR
      MENUITEM "Properties" ACTION Iif( oDesigner:oDlgInsp==Nil,InspOpen(),InspShow())
      MENUITEM "Objetos" ACTION socontroles()
      SEPARATOR
      MENUITEM "Classe Objeto" ACTION objinspector(GetCtrlSelected(HFormGen():oDlgSelected))
           //Iif( oDesigner:oDlgInsp==Nil,InspOpen(), HWG_BRINGWINDOWTOTOP(oDesigner:oDlgInsp:handle) )
   ENDMENU

   CONTEXT MENU oDesigner:oTabMenu
      MENUITEM "New Page" ACTION Page_New( GetCtrlSelected(HFormGen():oDlgSelected) )
      MENUITEM "Next Page" ACTION Page_Next( GetCtrlSelected(HFormGen():oDlgSelected) )
      MENUITEM "Previous Page" ACTION Page_Prev( GetCtrlSelected(HFormGen():oDlgSelected) )
      SEPARATOR
      MENUITEM "Copy"   ACTION (oDesigner:oClipBrd:=GetCtrlSelected(HFormGen():oDlgSelected),Iif(oDesigner:oClipBrd!=Nil,hwg_Enablemenuitem(,1012,.T.,.T.),.F.))
      MENUITEM "Adjust to left"  ACTION AdjustCtrl( GetCtrlSelected(HFormGen():oDlgSelected),.T.,.F.,.F.,.F. )
      MENUITEM "Adjust to top"   ACTION AdjustCtrl( GetCtrlSelected(HFormGen():oDlgSelected),.F.,.T.,.F.,.F. )
      MENUITEM "Adjust to right" ACTION AdjustCtrl( GetCtrlSelected(HFormGen():oDlgSelected),.F.,.F.,.T.,.F. )
      MENUITEM "Adjust to bottom" ACTION AdjustCtrl( GetCtrlSelected(HFormGen():oDlgSelected),.F.,.F.,.F.,.T. )
      // : LFB
      SEPARATOR
      MENUITEM "Align left sides"  ACTION Asels_ajustar(1)
      MENUITEM "Align Right sides"  ACTION Asels_ajustar(2)
      MENUITEM "Align Top Edges"  ACTION Asels_ajustar(3)
      //MENUITEM "Align Bottom Edges"  ACTION Asels_ajustar(4)
      MENUITEM "Same Width"  ACTION Asels_ajustar(5)
      MENUITEM "Same Height"  ACTION Asels_ajustar(6)
      // : END LFB
         SEPARATOR
      MENUITEM "Delete" ACTION DeleteCtrl()
      SEPARATOR
      MENUITEM "Properties" ACTION Iif( oDesigner:oDlgInsp==Nil,InspOpen(),InspShow())
      MENUITEM "Objetos" ACTION socontroles()
      SEPARATOR
      MENUITEM "Classe Objeto" ACTION objinspector(GetCtrlSelected(HFormGen():oDlgSelected))
   ENDMENU

   CONTEXT MENU oDesigner:oDlgMenu
      MENUITEM "Paste" ACTION oDesigner:addItem := oDesigner:oClipbrd
      MENUITEM "Preview" ACTION DoPreview()
      SEPARATOR
      MENUITEM "Properties" ACTION Iif( oDesigner:oDlgInsp==Nil,InspOpen(),InspShow())
      MENUITEM "Objetos" ACTION socontroles()
      SEPARATOR
      MENUITEM "Classe Objeto" ACTION objinspector(GetCtrlSelected(HFormGen():oDlgSelected))
   ENDMENU

   HWG_InitCommonControlsEx()


#ifdef INTEGRATED
#ifdef MODAL
   ACTIVATE DIALOG oDesigner:oMainWnd
   cResForm := oDesigner:cResForm
   oDesigner := NIL
#else
   ACTIVATE DIALOG oDesigner:oMainWnd NOMODAL
#endif
#else
   StartDes( oDesigner:oMainWnd,p0,p1 )
   ACTIVATE WINDOW oDesigner:oMainWnd
#endif

   RETURN cResForm

STATIC FUNCTION ShowGrid10px()
   // local nForm, nForms
   MEMVAR oDesigner
   IF ( oDesigner:oDlgInsp == NIL )
      hwg_Checkmenuitem(oDesigner:oMainWnd:handle,1052,!hwg_Ischeckedmenuitem(oDesigner:oMainWnd:handle,1052))
      hwg_Checkmenuitem(oDesigner:oMainWnd:handle,1050,.F.)
      IF (hwg_Ischeckedmenuitem(oDesigner:oMainWnd:handle,1052))
         oDesigner:nPixelGrid := 18
         oDesigner:lShowGrid  := .T.
      ELSE
         oDesigner:nPixelGrid := 0
         oDesigner:lShowGrid  := .F.
      ENDIF
   ELSE
      hwg_Msginfo( "Close the form(s) first to change the grid status","Warning")
   ENDIF
   RETURN ( NIL )

STATIC FUNCTION ShowGrid5px()
   //local nForm, nForms
   MEMVAR oDesigner
   IF ( oDesigner:oDlgInsp == NIL )
      hwg_Checkmenuitem(oDesigner:oMainWnd:handle,1050,!hwg_Ischeckedmenuitem(oDesigner:oMainWnd:handle,1050))
      hwg_Checkmenuitem(oDesigner:oMainWnd:handle,1052,.F.)
      IF (hwg_Ischeckedmenuitem(oDesigner:oMainWnd:handle,1050))
         oDesigner:nPixelGrid := 12
         oDesigner:lShowGrid  := .T.
      ELSE
         oDesigner:nPixelGrid := 0
         oDesigner:lShowGrid  := .F.
      ENDIF
   ELSE
      hwg_Msginfo( "Close the form first to change the grid status","Warning")
   ENDIF

   RETURN ( NIL )

// -----------------
CLASS HDesigner

   DATA oMainWnd, oDlgInsp
   DATA oCtrlMenu, oTabMenu, oDlgMenu
   DATA oClipbrd
   DATA lReport      INIT .F.
   DATA ds_mypath
   DATA lChgPath     INIT .F.
   DATA aRecent      INIT Array(MAX_RECENT_FILES)
   DATA lChgRecent   INIT .F.
   DATA oWidgetsSet, oFormDesc
   DATA oBtnPressed, addItem
   DATA aFormats     INIT { { "Hwgui XML format","xml" } }
   DATA aDataDef     INIT {}
   DATA aMethDef     INIT {}
   DATA lSingleForm  INIT .F.
   DATA cResForm
   DATA nPixelGrid   INIT 0
   DATA lShowGrid    INIT .F.
   DATA lSnapToGrid  INIT .F.

   METHOD New   INLINE Self
ENDCLASS
// -----------------

STATIC FUNCTION StartDes( oDlg,p1,cForm )

   hwg_Movewindow( oDlg:handle,0,0,oDlg:nWidth+10,oDlg:nHeight )

   IF p1 != Nil .AND. Left( p1,1 ) $ "-/"
      IF ( p1 := Substr( p1,2,1 ) ) == "n"
         HFormGen():New()
      ELSEIF p1 == "f"
         IF cForm == NIL
            HFormGen():New()
         ELSE
            HFormGen():Open( cForm )
         ENDIF
#ifdef INTEGRATED
// #ifdef MODAL
      ELSEIF p1 == "s"
         IF cForm == NIL
            HFormGen():New()
         ELSE
            HFormGen():Open( ,cForm )
         ENDIF
         Hwg_SetForegroundWindow( HFormGen():aForms[1]:oDlg:handle )
         hwg_Setfocus( HFormGen():aForms[1]:oDlg:handle )
// #endif
#endif
      ENDIF
   ENDIF

   RETURN NIL

STATIC FUNCTION ReadIniFiles()
   LOCAL oIni := HXMLDoc():Read( "Designer.iml" )
   LOCAL i, oNode, cWidgetsFileName, cwitem, cfitem, critem, l_ds_mypath, j
   MEMVAR oDesigner, cCurDir

   IF oDesigner:lReport
      cwItem := "rep_widgetset"
      cfitem := "rep_format"
      critem := "rep_recent"
   ELSE
      cwItem := "widgetset"
      cfitem := "format"
      critem := "recent"
   ENDIF
   IF Empty( oIni:aItems )
      CreateIni( oIni )
   ENDIF
   FOR i := 1 TO Len( oIni:aItems[1]:aItems )
      oNode := oIni:aItems[1]:aItems[i]
      IF oNode:title == cwitem
         IF !Empty( oNode:aItems)
            cWidgetsFileName := oNode:aItems[1]
         ENDIF
      ELSEIF oNode:title == cfitem
         Aadd( oDesigner:aFormats, { oNode:GetAttribute("name"), oNode:GetAttribute("ext"), ;
            oNode:GetAttribute("file"),oNode:GetAttribute("rdscr"), ;
            oNode:GetAttribute("wrscr"),oNode:GetAttribute("cnvtable") } )
      ELSEIF oNode:title == "editor"
         LoadEdOptions( oNode:aItems[1] )
      ELSEIF oNode:title == "grid"
         l_ds_mypath := oNode:GetAttribute("default")
         IF !Empty( l_ds_mypath )
            oDesigner:nPixelGrid := val( l_ds_mypath )
            IF empty( oDesigner:nPixelGrid )
               oDesigner:lShowGrid := .F.
            ELSE
               oDesigner:lShowGrid := .T.
            ENDIF
         ENDIF
      ELSEIF oNode:title == "dirpath"
         l_ds_mypath := oNode:GetAttribute("default")
         IF !Empty( l_ds_mypath )
            oDesigner:ds_mypath := Lower( l_ds_mypath )
         ENDIF
      ELSEIF oNode:title == critem .AND. !oDesigner:lSingleForm
         FOR j := 1 TO Min( Len( oNode:aItems ),MAX_RECENT_FILES )
            oDesigner:aRecent[j] := Lower( Trim( oNode:aItems[j]:aItems[1] ) )
         NEXT
      ENDIF
   NEXT

   IF Valtype( cWidgetsFileName ) == "C"
      oDesigner:oWidgetsSet := HXMLDoc():Read( cCurDir + cWidgetsFileName )
   ENDIF
   IF oDesigner:oWidgetsSet == Nil .OR. Empty( oDesigner:oWidgetsSet:aItems )
      hwg_Msgstop( "Widgets file isn't found!","Designer error" )
      RETURN .F.
   ENDIF

   RETURN .T.

STATIC FUNCTION BuildSet( oTab )
   LOCAL i, j, j1, aSet, oWidget, oProperty, b1, b2, b3, cDlg, arr, b4
   LOCAL x1, cText,cBmp, oButton
   MEMVAR oDesigner

   IF !Empty( oDesigner:oWidgetsSet:aItems )
      aSet := oDesigner:oWidgetsSet:aItems[1]:aItems
      FOR i := 1 TO Len( aSet )
         IF aSet[i]:title == "set"
            oTab:StartPage( aSet[i]:GetAttribute( "name" ) )
            x1 := 4
            FOR j := 1 TO Len( aSet[i]:aItems )
               IF aSet[i]:aItems[j]:title == "widget"
                  oWidget := aSet[i]:aItems[j]
                  cText := oWidget:GetAttribute( "text" )
                  cBmp := oWidget:GetAttribute( "bmp" )
                  IF cText != Nil .OR. cBmp != Nil
                     oButton := HOwnButton():New( ,,,x1,32,30,26, ;
                        ,,,{|o,id|ClickBtn(o,id)},.T.,    ;
                        cText,,,,,,,                      ;
                        cBmp,At(".",cBmp)==0,,,,,.F.,,    ;
                        oWidget:GetAttribute( "name" ) )
                     oButton:cargo := oWidget
                     x1 += 30
                  ENDIF
               ENDIF
            NEXT
            oTab:EndPage()
         ELSEIF aSet[i]:title == "form"
            oDesigner:oFormDesc := aSet[i]
         ELSEIF aSet[i]:title == "data"
            FOR j := 1 TO Len( aSet[i]:aItems )
               IF aSet[i]:aItems[j]:title == "property"
                  oProperty := aSet[i]:aItems[j]
                  b1 := b2 := b3 := b4 := Nil
                  FOR j1 := 1 TO Len( oProperty:aItems )
                     IF oProperty:aItems[j1]:title == "code1"
                        b1 := oProperty:aItems[j1]:aItems[1]:aItems[1]
                     ELSEIF oProperty:aItems[j1]:title == "code2"
                        b2 := oProperty:aItems[j1]:aItems[1]:aItems[1]
                     ELSEIF oProperty:aItems[j1]:title == "code3"
                        b3 := oProperty:aItems[j1]:aItems[1]:aItems[1]
                     ELSEIF oProperty:aItems[j1]:title == "code_def"
                        b4 := oProperty:aItems[j1]:aItems[1]:aItems[1]
                     ENDIF
                  NEXT
                  cDlg := oProperty:GetAttribute("array")
                  IF cDlg != Nil
                     arr := {}
                     DO WHILE ( j1 := At( ",",cDlg ) ) > 0
                        Aadd( arr,Left( cDlg,j1-1 ) )
                        cDlg := LTrim( SubStr( cDlg,j1+1 ) )
                     ENDDO
                     Aadd( arr, cDlg )
                  ELSE
                     arr := Nil
                  ENDIF
                  cDlg := oProperty:GetAttribute("dlg")
                  IF cDlg != Nil
                     cDlg := Lower( cDlg )
                  ENDIF
                  Aadd( oDesigner:aDataDef, { Lower(oProperty:GetAttribute("name")), ;
                     b1,b2,b3,cDlg,arr,b4 } )
               ENDIF
            NEXT
         ELSEIF aSet[i]:title == "methods"
            FOR j := 1 TO Len( aSet[i]:aItems )
               IF aSet[i]:aItems[j]:title == "method"
                  Aadd( oDesigner:aMethDef, { Lower(aSet[i]:aItems[j]:GetAttribute("name")), ;
                     aSet[i]:aItems[j]:GetAttribute("params") } )
               ENDIF
            NEXT
         ENDIF
      NEXT
   ENDIF

   RETURN NIL

STATIC FUNCTION ArrangeBtn( oTab,x,y )
   LOCAL i, x1, y1, oBtn

   oTab:Move( ,, x-6, y-33 )
   FOR i := 1 TO Len( oTab:aControls )
      oBtn := oTab:aControls[i]
      IF oBtn:Classname == "HOWNBUTTON"
         IF oBtn:nLeft == 4 .AND. oBtn:nTop == 32
            x1 := 4
            y1 := 32
         ELSE
            IF oBtn:nLeft != x1 .OR. oBtn:nTop != y1
               oBtn:Move( x1, y1 )
            ENDIF
         ENDIF
         x1 += 30
         IF x1 + oBtn:nWidth > x
            x1 := 4
            y1 += 30
         ENDIF
      ENDIF
   NEXT

   RETURN NIL

STATIC FUNCTION ClickBtn( oTab,nId ) //, cItem,cText,nWidth,nHeight )
   LOCAL oBtn := oTab:FindControl( nId )
   MEMVAR oDesigner

   IF !Empty( HFormGen():aForms )
      oDesigner:addItem := oBtn:cargo
      IF oDesigner:oBtnPressed != NIL
         oDesigner:oBtnPressed:Release()
      ENDIF
      oBtn:Press()
      oDesigner:oBtnPressed := oBtn
   ENDIF

   RETURN NIL

FUNCTION DeleteCtrl()
   LOCAL oDlg := HFormGen():oDlgSelected, oCtrl, i
   MEMVAR oDesigner

   IF oDlg != Nil .AND. ( oCtrl := GetCtrlSelected( oDlg ) ) != Nil
      IF oCtrl:oContainer != Nil
         i := Ascan( oCtrl:oContainer:aControls,{|o|o:handle==oCtrl:handle} )
         IF i != 0
            Adel( oCtrl:oContainer:aControls,i )
            Asize( oCtrl:oContainer:aControls,Len(oCtrl:oContainer:aControls)-1 )
         ENDIF
      ENDIF
      IF oDesigner:lReport
         oDlg:aControls[1]:aControls[1]:DelControl( oCtrl )
      ELSE
         oDlg:DelControl( oCtrl )
      ENDIF
      InspSetCombo( )
      SetCtrlSelected( oDlg )
      oDlg:oParent:lChanged := .T.
   ENDIF

   RETURN NIL

FUNCTION FindWidget( cClass )
   MEMVAR  odesigner
   LOCAL i, aSet := oDesigner:oWidgetsSet:aItems[1]:aItems, oNode

   FOR i := 1 TO Len( aSet )
      IF aSet[i]:title == "set"
         IF ( oNode := aSet[i]:Find( "widget",1,{|o|o:GetAttribute("class")==cClass} ) ) != Nil
            RETURN oNode
         ENDIF
      ENDIF
   NEXT

   RETURN NIL

FUNCTION Evalcode( xCode )
   LOCAL nLines

   IF Valtype( xCode ) == "C"
      nLines := mlCount( xCode )
      IF nLines > 1
         xCode := RdScript( ,xCode )
      ELSE
         xCode := &( "{||" + xCode + "}" )
      ENDIF
   ENDIF
   IF Valtype( xCode ) == "A"
      RETURN DoScript( xCode )
   ELSE
      RETURN Eval( xCode )
   ENDIF

   RETURN NIL

STATIC FUNCTION CreateIni( oIni )
   LOCAL oNode := oIni:Add( HXMLNode():New( "designer" ) )

   oNode:Add( HXMLNode():New( "widgetset",,,"widgets.xml" ) )
   oIni:Save( "designer.iml" )

   RETURN NIL

FUNCTION AddRecent( oForm )
   LOCAL i, cItem := Lower( Trim( oForm:path+oForm:filename ) )
   MEMVAR oDesigner

   IF oDesigner:aRecent[1] == Nil .OR. !( oDesigner:aRecent[1] == cItem )
      FOR i := 1 TO MAX_RECENT_FILES
         IF oDesigner:aRecent[i] == Nil
            EXIT
         ELSEIF oDesigner:aRecent[i] == cItem
            Adel( oDesigner:aRecent,i )
         ENDIF
      NEXT
      Ains( oDesigner:aRecent, 1 )
      oDesigner:aRecent[1] := cItem
      oDesigner:lChgRecent := .T.
   ENDIF

   RETURN NIL

STATIC FUNCTION EndIde
   LOCAL i, j, alen := Len( HFormGen():aForms ), lRes := .T., oIni, critem, oNode
   MEMVAR oDesigner, cCurDir

   IF alen > 0
      IF hwg_Msgyesno( "Do you really want to quit ?", "Designer" )
         FOR i := Len( HFormGen():aForms ) TO 1 STEP -1
            HFormGen():aForms[i]:End( ,.F. )
         NEXT
      ELSE
         lRes := .F.
      ENDIF
   ENDIF
   IF !oDesigner:lSingleForm .AND. ( oDesigner:lChgRecent .OR. oDesigner:lChgPath .OR. .T. )
      critem := Iif( oDesigner:lReport, "rep_recent", "recent" )
      oIni := HXMLDoc():Read( cCurDir+"Designer.iml" )
      IF oDesigner:lChgPath
         i := 1
         oNode := HXMLNode():New( "dirpath",HBXML_TYPE_SINGLE,{{"default",oDesigner:ds_myPath}} )
         IF oIni:aItems[1]:Find( "dirpath",@i ) == Nil
            oIni:aItems[1]:Add( oNode )
         ELSE
            oIni:aItems[1]:aItems[i] := oNode
         ENDIF
      ENDIF
      IF oDesigner:lChgRecent
         i := 1
         IF oIni:aItems[1]:Find( critem,@i ) == Nil
            oIni:aItems[1]:Add( HXMLNode():New( critem,, ) )
            i := Len( oIni:aItems[1]:aItems )
         ENDIF
         j := 1
         oIni:aItems[1]:aItems[i]:aItems := {}
         DO WHILE j <= MAX_RECENT_FILES .AND. oDesigner:aRecent[j] != Nil
            oIni:aItems[1]:aItems[i]:Add( HXMLNode():New( "file",,,oDesigner:aRecent[j] ) )
            j ++
         ENDDO
      ENDIF
      i := 1
      oNode := HXMLNode():New( "grid",HBXML_TYPE_SINGLE,{{"default",alltrim(str(oDesigner:nPixelGrid))}} )
      IF oIni:aItems[1]:Find( "grid",@i ) == Nil
         oIni:aItems[1]:Add( oNode )
      ELSE
         oIni:aItems[1]:aItems[i] := oNode
      ENDIF

      oIni:Save( cCurDir+"Designer.iml" )
   ENDIF
   IF lRes
      oDesigner:oCtrlMenu:End()
      oDesigner:oTabMenu:End()
      IF HDTheme():lChanged
         SaveEdOptions()
      ENDIF
#ifndef MODAL
      oDesigner := Nil
#endif
   ENDIF

   RETURN lRes

FUNCTION SetOmmitMenuFile(lom)

   lOmmitMenuFile := lOm

   RETURN lOm

// : LFB
FUNCTION StatusBarMsg(cfile,cpos,ctam)
   MEMVAR oDesigner

   //cfile := IIF(cfile = Nil,'',cfile)
   cpos := IIF(cpos = Nil,'',cpos)
   ctam := IIF(ctam = Nil,'',ctam)
   IF cFile != Nil
      hwg_WriteStatus( oDesigner:oMainWnd,1,"File: "+cfile ,.T.)
   ENDIF
   hwg_WriteStatus( oDesigner:oMainWnd,2,cpos ,.T.)
   hwg_WriteStatus(oDesigner:oMainWnd,3,ctam ,.T.)

   *hwg_WriteStatus( OdLG,4,"INS" ,.T.)
   hwg_WriteStatus(oDesigner:oMainWnd,5,IIF(hwg_Isnumlockactive(),"NUM" ,"   "),.T.)
   hwg_WriteStatus(oDesigner:oMainWnd,6,IIF(hwg_Iscapslockactive(),"CAPS","    ") ,.T.)

   RETURN NIL

FUNCTION SoControles
   LOCAL opanelx, oTabx
   LOCAL oFont

   IF !empty(hwg_findwindow(0,"Toolbars - Classes ") )// > 0
      hwg_Showwindow(oDlgx:handle)
      hwg_Setfocus( oDlgx:handle )
      RETURN NIL
   ENDIF

   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13

   INIT DIALOG oDlgx AT 0,0 SIZE 400,99 TITLE "Toolbars - Classes ";
      FONT oFont                                                  ;
      STYLE WS_VISIBLE + WS_SYSMENU + DS_SYSMODAL + WS_SIZEBOX + MB_USERICON    ;
      ON EXIT {||  oDlgx := Nil, .t.}

   //ON OTHER MESSAGES {|o,m,wp,lp|MessagesOthers(o,m,wp,lp)}

   @ 0,0 PANEL oPanelx SIZE 395,98 ON SIZE {|o,x,y|hwg_Movewindow(o:handle,0,0,x+4,y+20)}
   @ 1,1 TAB oTabx ITEMS {} OF oPanelx SIZE 390,98 FONT oFont ;
      ON SIZE {|o,x,y|ArrangeBtn(o,x,y)}

   CONTEXT MENU oMenuTool
      MENUITEM "AlwaysOnTop" ACTION ActiveTopMost( 0, .t. )
      //{||oDesigner:oDlgInsp:Close(),inspOpen(.T.)}
      MENUITEM "Normal" ACTION ActiveTopMost( 0, .f. )
      //{||oDesigner:oDlgInsp:Close(),inspOpen(.F.)}
      MENUITEM "Hide" ACTION oDlgX:CLOSE()
   ENDMENU

   BuildSet( oTabx )

   HWG_InitCommonControlsEx()

   ACTIVATE DIALOG ODLGx NOMODAL

   RETURN NIL

FUNCTION InspShow()
   MEMVAR oDesigner

   Iif( oDesigner:oDlgInsp==Nil,InspOpen(),oDesigner:oDlgInsp:show() )
   HWG_BRINGWINDOWTOTOP(oDesigner:oDlgInsp:handle)

   RETURN NIL

FUNCTION HWLASTKEY
   LOCAL ckeyb := hwg_Getkeyboardstate() ,i
   FOR i= 1 to 255
      IF Asc(Substr(ckeyb,i,1)) >= 128
         RETURN i - 1
      ENDIF
   NEXT

   RETURN 0

   // :END LFB