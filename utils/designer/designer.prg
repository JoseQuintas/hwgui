/*
 * $Id: designer.prg,v 1.11 2004-08-04 20:08:24 sandrorrfreire Exp $
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

REQUEST DRAWEDGE
REQUEST DRAWICON
REQUEST ELLIPSE
REQUEST SETWINDOWFONT
REQUEST INITMONTHCALENDAR
REQUEST INITTRACKBAR

Function Designer( p1, cForm )
Local oPanel, oTab, oFont, cResForm, lSingleF := .F.
LOCAL oIcon:= HICon():AddResource("HWG")
Public oDesigner
Public crossCursor, vertCursor, horzCursor
Public ds_myPath

#ifdef INTEGRATED
#ifdef MODAL
   IF p1 == "-s" .OR. p1 == "/s"
      lSingleF := .T.
   ENDIF
#endif
#endif
   oDesigner := HDesigner():New()
   IF !__mvExist( "cCurDir" )
      __mvPublic( "cCurDir" )
   ENDIF
   IF Valtype( cCurDir ) != "C"
      cCurDir := GetCurrentDir() + "\"
   ENDIF
   ds_mypath := cCurDir

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
   INIT DIALOG oDesigner:oMainWnd AT 0,0 SIZE 280,200 TITLE "Designer" ;
      FONT oFont                                    ;
      ON INIT {|o|StartDes(o,p1,cForm)} ;
      ON EXIT {||EndIde()}
#else
   INIT WINDOW oDesigner:oMainWnd MAIN AT 0,0 SIZE 280,200 TITLE "Designer" ;
      FONT oFont ICON oIcon                                                ;
      ON EXIT {||EndIde()}
#endif

   MENU OF oDesigner:oMainWnd
      MENU TITLE "&File"
         IF !lSingleF
            MENUITEM "&New Form" ACTION HFormGen():New()
            MENUITEM "&Open Form" ACTION HFormGen():Open()
            SEPARATOR
            MENUITEM "&Save Form"   ACTION Iif(HFormGen():oDlgSelected!=Nil,HFormGen():oDlgSelected:oParent:Save(),MsgStop("No Form in use!"))
            MENUITEM "&Save as ..." ACTION Iif(HFormGen():oDlgSelected!=Nil,HFormGen():oDlgSelected:oParent:Save(.T.),MsgStop("No Form in use!"))
            MENUITEM "&Close Form"  ACTION Iif(HFormGen():oDlgSelected!=Nil,HFormGen():oDlgSelected:oParent:End(),MsgStop("No Form in use!"))
         ELSE
            MENUITEM "&Open Form" ACTION HFormGen():OpenR()
            SEPARATOR
            MENUITEM "&Save as ..." ACTION ( oDesigner:lSingleForm:=.F.,HFormGen():oDlgSelected:oParent:Save(.T.),oDesigner:lSingleForm:=.T. )
         ENDIF        
         SEPARATOR
         MENUITEM "&Exit" ACTION oDesigner:oMainWnd:Close()
      ENDMENU
      MENU TITLE "&Edit"
         MENUITEM "&Copy control" ACTION (oDesigner:oClipBrd:=GetCtrlSelected(HFormGen():oDlgSelected),Iif(oDesigner:oClipBrd!=Nil,EnableMenuItem(,1012,.T.,.T.),.F.))
         MENUITEM "&Paste" ID 1012 ACTION oDesigner:addItem := oDesigner:oClipbrd
      ENDMENU
      MENU TITLE "&View"
         MENUITEM "&Object Inspector" ID 1010 ACTION Iif( oDesigner:oDlgInsp==Nil,InspOpen(),oDesigner:oDlgInsp:Close() )
      ENDMENU
      MENU TITLE "&Control"
         MENUITEM "&Delete"  ACTION DeleteCtrl()
      ENDMENU
      MENU TITLE "&Options"
         MENUITEM "&AutoAdjust" ID 1011 ACTION CheckMenuItem(oDesigner:oMainWnd:handle,1011,!IsCheckedMenuItem(oDesigner:oMainWnd:handle,1011))
      ENDMENU
      MENU TITLE "&Help"
         MENUITEM "&About" ACTION MsgInfo("About")
      ENDMENU
   ENDMENU  

   @ 0,0 PANEL oPanel SIZE 280,200 ON SIZE {|o,x,y|MoveWindow(o:handle,0,0,x,y)}

   IF !lSingleF
      @ 2,3 OWNERBUTTON OF oPanel       ;
          ON CLICK {||HFormGen():New()} ;
          SIZE 24,24 FLAT               ;
          BITMAP "BMP_NEW" FROM RESOURCE COORDINATES 0,4,0,0 TRANSPARENT ;
          TOOLTIP "New Form"
      @ 26,3 OWNERBUTTON OF oPanel       ;
          ON CLICK {||HFormGen():Open()} ;
          SIZE 24,24 FLAT                ;
          BITMAP "BMP_OPEN" FROM RESOURCE COORDINATES 0,4,0,0 TRANSPARENT ;
          TOOLTIP "Open Form"

      @ 55,6 LINE LENGTH 18 VERTICAL

      @ 60,3 OWNERBUTTON OF oPanel       ;
          ON CLICK {||Iif(HFormGen():oDlgSelected!=Nil,HFormGen():oDlgSelected:oParent:Save(),MsgStop("No Form in use!"))} ;
          SIZE 24,24 FLAT                ;
          BITMAP "BMP_SAVE" FROM RESOURCE COORDINATES 0,4,0,0 TRANSPARENT ;
          TOOLTIP "Save Form"
   ENDIF

   @ 3,30 TAB oTab ITEMS {} OF oPanel SIZE 280,210 FONT oFont ;
      ON SIZE {|o,x,y|ArrangeBtn(o,x,y)}

   BuildSet( oTab )

   CONTEXT MENU oDesigner:oCtrlMenu
      MENUITEM "Copy"   ACTION (oDesigner:oClipBrd:=GetCtrlSelected(HFormGen():oDlgSelected),Iif(oDesigner:oClipBrd!=Nil,EnableMenuItem(,1012,.T.,.T.),.F.))
      MENUITEM "Adjust to left"  ACTION AdjustCtrl( GetCtrlSelected(HFormGen():oDlgSelected),.T.,.F. )
      MENUITEM "Adjust to top"   ACTION AdjustCtrl( GetCtrlSelected(HFormGen():oDlgSelected),.F.,.T. )
      SEPARATOR
      MENUITEM "Delete" ACTION DeleteCtrl()
   ENDMENU

   CONTEXT MENU oDesigner:oTabMenu
      MENUITEM "New Page" ACTION Page_New( GetCtrlSelected(HFormGen():oDlgSelected) )
      MENUITEM "Next Page" ACTION Page_Next( GetCtrlSelected(HFormGen():oDlgSelected) )
      MENUITEM "Previous Page" ACTION Page_Prev( GetCtrlSelected(HFormGen():oDlgSelected) )
      SEPARATOR
      MENUITEM "Copy"   ACTION (oDesigner:oClipBrd:=GetCtrlSelected(HFormGen():oDlgSelected),Iif(oDesigner:oClipBrd!=Nil,EnableMenuItem(,1012,.T.,.T.),.F.))
      MENUITEM "Adjust to left"  ACTION AdjustCtrl( GetCtrlSelected(HFormGen():oDlgSelected),.T.,.F. )
      MENUITEM "Adjust to top"   ACTION AdjustCtrl( GetCtrlSelected(HFormGen():oDlgSelected),.F.,.T. )
      SEPARATOR
      MENUITEM "Delete" ACTION DeleteCtrl()
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
   StartDes( oDesigner:oMainWnd,p1,cForm )
   ACTIVATE WINDOW oDesigner:oMainWnd
#endif

Return cResForm

// -----------------
CLASS HDesigner

   DATA oMainWnd, oDlgInsp
   DATA oCtrlMenu, oTabMenu
   DATA oClipbrd
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
#ifdef MODAL
      ELSEIF p1 == "s"
         IF cForm == Nil
            HFormGen():New()
         ELSE
            HFormGen():Open( ,cForm )
         ENDIF
         oDesigner:lSingleForm := .T.
#endif
#endif
      ENDIF
   ENDIF

Return Nil

Static Function ReadIniFiles()
Local oIni := HXMLDoc():Read( "Designer.iml" )
Local i, oNode, cWidgetsFileName

   IF Empty( oIni:aItems )
      CreateIni( oIni )
   ENDIF
   FOR i := 1 TO Len( oIni:aItems[1]:aItems )
      oNode := oIni:aItems[1]:aItems[i]
      IF oNode:title == "widgetset"
         IF !Empty( oNode:aItems)
            cWidgetsFileName := oNode:aItems[1]
         ENDIF
      ELSEIF oNode:title == "format"
         Aadd( oDesigner:aFormats, { oNode:GetAttribute("name"), oNode:GetAttribute("ext"), ;
             oNode:GetAttribute("file"),oNode:GetAttribute("rdscr"), ;
             oNode:GetAttribute("wrscr"),oNode:GetAttribute("cnvtable") } )
      ELSEIF oNode:title == "editor"
         LoadEdOptions( oNode:aItems[1] )
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
                               cBmp,At(".",cBmp)==0,,,,,.F.,     ;
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

   IF oDlg != Nil .AND. ( oCtrl := GetCtrlSelected( oDlg ) ) != Nil
      IF oCtrl:oContainer != Nil
         i := Ascan( oCtrl:oContainer:aControls,{|o|o:handle==oCtrl:handle} )
         IF i != 0
            Adel( oCtrl:oContainer:aControls,i )
            Asize( oCtrl:oContainer:aControls,Len(oCtrl:oContainer:aControls)-1 )
         ENDIF
      ENDIF
      oDlg:DelControl( oCtrl )
      SetCtrlSelected( oDlg )
      oDlg:oParent:lChanged := .T.
   ENDIF
Return

Function FindWidget( cClass )
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

Static Function EndIde
Local i, alen := Len( HFormGen():aForms ), lRes := .T.

  IF alen > 0
     IF MsgYesNo( "Are you really want to quit ?" )
        FOR i := Len( HFormGen():aForms ) TO 1 STEP -1
           HFormGen():aForms[i]:End()
        NEXT
     ELSE
        lRes := .F.
     ENDIF
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
