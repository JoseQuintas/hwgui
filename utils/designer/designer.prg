/*
 * $Id: designer.prg,v 1.28 2007-08-11 04:01:14 richardroesnadi Exp $
 *
 * Designer
 * Main file
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "guilib.ch"
#include "hbclass.ch"
#include "hxml.ch"
#include "extmodul.ch"

#define  MAX_RECENT_FILES  5

STATIC lOmmitMenuFile := .F.


REQUEST DRAWEDGE
REQUEST DRAWICON
REQUEST ELLIPSE
REQUEST SETWINDOWFONT
REQUEST INITMONTHCALENDAR
REQUEST INITTRACKBAR
REQUEST HTIMER, DBCREATE, DBUSEAREA, DBCREATEINDEX, DBSEEK
REQUEST BARCODE

Function Designer( p0, p1, p2 )
Local oPanel, oTab, oFont, cResForm, i
Memvar oDesigner, cCurDir
Memvar crossCursor, vertCursor, horzCursor

Public oDesigner, cCurDir
Public crossCursor, vertCursor, horzCursor


   oDesigner := HDesigner():New()

   IF p0 != Nil .AND. ( p0 == "-r" .OR. p0 == "/r" )
      oDesigner:lReport := .T.
      IF p1 != Nil
         IF Left( p1,1 ) $ "-/"
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
      cCurDir := GetCurrentDir() + "\"
   ENDIF
   oDesigner:ds_mypath := cCurDir

   IF !ReadIniFiles()
      Return Nil
   ENDIF

   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13
   IF Valtype( crossCursor ) != "N"
      crossCursor := LoadCursor( IDC_CROSS )
      horzCursor  := LoadCursor( IDC_SIZEWE )
      vertCursor  := LoadCursor( IDC_SIZENS )
   ENDIF

#ifdef INTEGRATED
   INIT DIALOG oDesigner:oMainWnd AT 0,0 SIZE 280,200 TITLE iif(!oDesigner:lReport,"Form","Report")+" designer" ;
      FONT oFont                          ;
      ON INIT {|o|StartDes(o,p0,p1)}   ;
      ON EXIT {||EndIde()}
#else
   INIT WINDOW oDesigner:oMainWnd MAIN AT 0,0 SIZE 280,200 TITLE iif(!oDesigner:lReport,"Form","Report")+" designer" ;
      FONT oFont                                                  ;
      ON EXIT {||EndIde()}
#endif

   MENU OF oDesigner:oMainWnd
      MENU TITLE "&File"
         IF !oDesigner:lSingleForm
            MENUITEM "&New "+iif(!oDesigner:lReport,"Form","Report")  ACTION HFormGen():New()
            MENUITEM "&Open "+iif(!oDesigner:lReport,"Form","Report") ACTION HFormGen():Open()
            SEPARATOR
            MENUITEM "&Save "+iif(!oDesigner:lReport,"Form","Report")   ACTION Iif(HFormGen():oDlgSelected!=Nil,HFormGen():oDlgSelected:oParent:Save(),MsgStop("No Form in use!", "Designer"))
            MENUITEM "&Save as ..." ACTION Iif(HFormGen():oDlgSelected!=Nil,HFormGen():oDlgSelected:oParent:Save(.T.),MsgStop("No Form in use!"))
            MENUITEM "&Close "+iif(!oDesigner:lReport,"Form","Report")  ACTION Iif(HFormGen():oDlgSelected!=Nil,HFormGen():oDlgSelected:oParent:End(),MsgStop("No Form in use!", "Designer"))
         ELSE
            If !lOmmitMenuFile
               MENUITEM "&Open "+iif(!oDesigner:lReport,"Form","Report") ACTION HFormGen():OpenR()
               SEPARATOR
               MENUITEM "&Save as ..." ACTION ( oDesigner:lSingleForm:=.F.,HFormGen():oDlgSelected:oParent:Save(.T.),oDesigner:lSingleForm:=.T. )
            EndIf
         ENDIF
         If !lOmmitMenuFile
            SEPARATOR
            i := 1
            DO WHILE i <= MAX_RECENT_FILES .AND. oDesigner:aRecent[i] != Nil
               Hwg_DefineMenuItem( CutPath(oDesigner:aRecent[i]), 1020+i, ;
                  &( "{||HFormGen():Open('"+oDesigner:aRecent[i]+"')}" ) )
               i ++
            ENDDO
            SEPARATOR
         EndIf
         MENUITEM If(!lOmmitMenuFile,"&Exit","&Close Designer") ACTION oDesigner:oMainWnd:Close()
      ENDMENU
      MENU TITLE "&Edit"
         MENUITEM "&Copy control" ACTION (oDesigner:oClipBrd:=GetCtrlSelected(HFormGen():oDlgSelected),Iif(oDesigner:oClipBrd!=Nil,EnableMenuItem(,1012,.T.,.T.),.F.))
         MENUITEM "&Paste" ID 1012 ACTION oDesigner:addItem := oDesigner:oClipbrd
      ENDMENU
      MENU TITLE "&View"
         MENUITEM "&Object Inspector" ID 1010 ACTION Iif( oDesigner:oDlgInsp==Nil,InspOpen(),oDesigner:oDlgInsp:Close() )
         SEPARATOR
         MENUITEM "&Preview"  ACTION DoPreview()
      ENDMENU
      MENU TITLE "&Control"
         MENUITEM "&Delete"  ACTION DeleteCtrl()
      ENDMENU
      MENU TITLE "&Options"
         MENUITEM "&AutoAdjust" ID 1011 ACTION CheckMenuItem(oDesigner:oMainWnd:handle,1011,!IsCheckedMenuItem(oDesigner:oMainWnd:handle,1011))
      ENDMENU
      MENU TITLE "&Help"
         MENUITEM "&About" ACTION MsgInfo("Visual Designer", "Designer")
      ENDMENU
   ENDMENU

   @ 0,0 PANEL oPanel SIZE 280,200 ON SIZE {|o,x,y|MoveWindow(o:handle,0,0,x,y)}

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
          ON CLICK {||Iif(HFormGen():oDlgSelected!=Nil,HFormGen():oDlgSelected:oParent:Save(),MsgStop("No Form in use!"))} ;
          SIZE 24,24 FLAT                ;
          BITMAP "BMP_SAVE" FROM RESOURCE TRANSPARENT COORDINATES 0,4,0,0  ;
          TOOLTIP "Save Form"
      @ 84,6 LINE LENGTH 18 VERTICAL

      @ 89,3 OWNERBUTTON OF oPanel       ;
          ON CLICK {||doPreview()} ;
          SIZE 24,24 FLAT                ;
          BITMAP "smNext" FROM RESOURCE TRANSPARENT COORDINATES 0,4,0,0  ;
          TOOLTIP "Preview Form"
   ENDIF

   @ 3,30 TAB oTab ITEMS {} OF oPanel SIZE 280,210 FONT oFont ;
      ON SIZE {|o,x,y|ArrangeBtn(o,x,y)}

   BuildSet( oTab )

   CONTEXT MENU oDesigner:oCtrlMenu
      MENUITEM "Copy"   ACTION (oDesigner:oClipBrd:=GetCtrlSelected(HFormGen():oDlgSelected),Iif(oDesigner:oClipBrd!=Nil,EnableMenuItem(,1012,.T.,.T.),.F.))
      SEPARATOR
      MENUITEM "Adjust to left"  ACTION AdjustCtrl( GetCtrlSelected(HFormGen():oDlgSelected),.T.,.F.,.F.,.F. )
      MENUITEM "Adjust to top"   ACTION AdjustCtrl( GetCtrlSelected(HFormGen():oDlgSelected),.F.,.T.,.F.,.F. )
      MENUITEM "Adjust to right" ACTION AdjustCtrl( GetCtrlSelected(HFormGen():oDlgSelected),.F.,.F.,.T.,.F. )
      MENUITEM "Adjust to bottom" ACTION AdjustCtrl( GetCtrlSelected(HFormGen():oDlgSelected),.F.,.F.,.F.,.T. )
      SEPARATOR
      IF oDesigner:lReport
         MENUITEM "Fit into box" ID 1030 ACTION FitLine( GetCtrlSelected(HFormGen():oDlgSelected) )
         SEPARATOR
      ENDIF
      MENUITEM "Delete" ACTION DeleteCtrl()
   ENDMENU

   CONTEXT MENU oDesigner:oTabMenu
      MENUITEM "New Page" ACTION Page_New( GetCtrlSelected(HFormGen():oDlgSelected) )
      MENUITEM "Next Page" ACTION Page_Next( GetCtrlSelected(HFormGen():oDlgSelected) )
      MENUITEM "Previous Page" ACTION Page_Prev( GetCtrlSelected(HFormGen():oDlgSelected) )
      SEPARATOR
      MENUITEM "Copy"   ACTION (oDesigner:oClipBrd:=GetCtrlSelected(HFormGen():oDlgSelected),Iif(oDesigner:oClipBrd!=Nil,EnableMenuItem(,1012,.T.,.T.),.F.))
      MENUITEM "Adjust to left"  ACTION AdjustCtrl( GetCtrlSelected(HFormGen():oDlgSelected),.T.,.F.,.F.,.F. )
      MENUITEM "Adjust to top"   ACTION AdjustCtrl( GetCtrlSelected(HFormGen():oDlgSelected),.F.,.T.,.F.,.F. )
      MENUITEM "Adjust to right" ACTION AdjustCtrl( GetCtrlSelected(HFormGen():oDlgSelected),.F.,.F.,.T.,.F. )
      MENUITEM "Adjust to bottom" ACTION AdjustCtrl( GetCtrlSelected(HFormGen():oDlgSelected),.F.,.F.,.F.,.T. )
      SEPARATOR
      MENUITEM "Delete" ACTION DeleteCtrl()
   ENDMENU

   CONTEXT MENU oDesigner:oDlgMenu
      MENUITEM "Paste" ACTION oDesigner:addItem := oDesigner:oClipbrd
      MENUITEM "Preview" ACTION DoPreview()
   ENDMENU

   HWG_InitCommonControlsEx()

#ifdef INTEGRATED
#ifdef MODAL
   ACTIVATE DIALOG oDesigner:oMainWnd
   cResForm := oDesigner:cResForm
   oDesigner := Nil
#else
   ACTIVATE DIALOG oDesigner:oMainWnd NOMODAL
#endif
#else
   StartDes( oDesigner:oMainWnd,p0,p1 )
   ACTIVATE WINDOW oDesigner:oMainWnd
#endif

Return cResForm

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

   METHOD New   INLINE Self
ENDCLASS
// -----------------

Static Function StartDes( oDlg,p1,cForm )

   MoveWindow( oDlg:handle,0,0,280,210 )

   IF p1 != Nil .AND. Left( p1,1 ) $ "-/"
      IF ( p1 := Substr( p1,2,1 ) ) == "n"
         HFormGen():New()
      ELSEIF p1 == "f"
         IF cForm == Nil
            HFormGen():New()
         ELSE
            HFormGen():Open( cForm )
         ENDIF
#ifdef INTEGRATED
// #ifdef MODAL
      ELSEIF p1 == "s"
         IF cForm == Nil
            HFormGen():New()
         ELSE
            HFormGen():Open( ,cForm )
         ENDIF
         Hwg_SetForegroundWindow( HFormGen():aForms[1]:oDlg:handle )
         SetFocus( HFormGen():aForms[1]:oDlg:handle )
// #endif
#endif
      ENDIF
   ENDIF

Return Nil

Static Function ReadIniFiles()
Local oIni := HXMLDoc():Read( "Designer.iml" )
Local i, oNode, cWidgetsFileName, cwitem, cfitem, critem, l_ds_mypath, j
memvar oDesigner, cCurDir

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
      MsgStop( "Widgets file isn't found!","Designer error" )
      Return .F.
   ENDIF

Return .T.

Static Function BuildSet( oTab )
Local i, j, j1, aSet, oWidget, oProperty, b1, b2, b3, cDlg, arr, b4
Local x1, cText,cBmp, oButton
Memvar oDesigner

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
                    oButton := HOwnButton():New( ,,,x1,28,30,26, ;
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
Return Nil

Static Function ArrangeBtn( oTab,x,y )
Local i, x1, y1, oBtn

   oTab:Move( ,, x-6, y-33 )
   FOR i := 1 TO Len( oTab:aControls )
      oBtn := oTab:aControls[i]
      IF oBtn:Classname == "HOWNBUTTON"
         IF oBtn:nLeft == 4 .AND. oBtn:nTop == 28
            x1 := 4
            y1 := 28
         ELSE
            IF oBtn:nLeft != x1 .OR. oBtn:nTop != y1
               oBtn:Move( x1, y1 )
            ENDIF
         ENDIF
         x1 += 30
         IF x1 + oBtn:nWidth > x
            x1 := 4
            y1 += 26
         ENDIF
      ENDIF
   NEXT
Return Nil

Static Function ClickBtn( oTab,nId, cItem,cText,nWidth,nHeight )
Local oBtn := oTab:FindControl( nId )
Memvar oDesigner

   IF !Empty( HFormGen():aForms )
      oDesigner:addItem := oBtn:cargo
      IF oDesigner:oBtnPressed != Nil
         oDesigner:oBtnPressed:Release()
      ENDIF
      oBtn:Press()
      oDesigner:oBtnPressed := oBtn
   ENDIF
Return Nil

Function DeleteCtrl()
Local oDlg := HFormGen():oDlgSelected, oCtrl, i
Memvar oDesigner

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

Return Nil

Function FindWidget( cClass )
memvar  odesigner
Local i, aSet := oDesigner:oWidgetsSet:aItems[1]:aItems, oNode

   FOR i := 1 TO Len( aSet )
      IF aSet[i]:title == "set"
         IF ( oNode := aSet[i]:Find( "widget",1,{|o|o:GetAttribute("class")==cClass} ) ) != Nil
            Return oNode
         ENDIF
      ENDIF
   NEXT
Return Nil

Function Evalcode( xCode )
Local nLines

   IF Valtype( xCode ) == "C"
      nLines := mlCount( xCode )
      IF nLines > 1
         xCode := RdScript( ,xCode )
      ELSE
         xCode := &( "{||" + xCode + "}" )
      ENDIF
   ENDIF
   IF Valtype( xCode ) == "A"
      Return DoScript( xCode )
   ELSE
      Return Eval( xCode )
   ENDIF

Return Nil

Static Function CreateIni( oIni )
Local oNode := oIni:Add( HXMLNode():New( "designer" ) )

   oNode:Add( HXMLNode():New( "widgetset",,,"widgets.xml" ) )

   oIni:Save( "designer.iml" )
Return Nil

Function AddRecent( oForm )
Local i, cItem := Lower( Trim( oForm:path+oForm:filename ) )
Memvar oDesigner

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

Return Nil

Static Function EndIde
Local i, j, alen := Len( HFormGen():aForms ), lRes := .T., oIni, critem, oNode
Memvar oDesigner, cCurDir

  IF alen > 0
     IF MsgYesNo( "Do you really want to quit ?", "Designer" )
        FOR i := Len( HFormGen():aForms ) TO 1 STEP -1
           HFormGen():aForms[i]:End( ,.F. )
        NEXT
     ELSE
        lRes := .F.
     ENDIF
  ENDIF
  IF !oDesigner:lSingleForm .AND. ( oDesigner:lChgRecent .OR. oDesigner:lChgPath )
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

Return lRes



Function SetOmmitMenuFile(lom)
lOmmitMenuFile := lOm
Return lOm
