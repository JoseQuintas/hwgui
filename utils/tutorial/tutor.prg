/*
 * $Id$
 *
 * HWGUI Tutorial
 *
 * Copyright 2013 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 */

#include "hwgui.ch"
#include "hwgextern.ch"

#ifdef __PLATFORM__UNIX
ANNOUNCE HB_GTSYS
REQUEST HB_GT_CGI_DEFAULT
#endif

Static oIni
Static cIniPath, cTutor
Static oText, oHilight
Static oBtnRun
Static cHwgrunPath
Static cHwg_include_dir := "..\..\include"
Static cHwg_image_dir := "..\..\image"
Static cHrb_inc_dir := "", cHrb_bin_dir

Function Main
Local oMain, oPanel, oFont := HFont():Add( "Georgia",0,-15 )
Local oTree, oSplit

   cIniPath := FilePath( hb_ArgV( 0 ) )
   cHwgrunPath := isFileInPath()
   ReadIni()

#ifdef __PLATFORM__UNIX
   cHwg_image_dir := StrTran( cHwg_image_dir, '\', '/' )
   cHwg_include_dir := StrTran( cHwg_include_dir, '\', '/' )
#endif

   HBitmap():cPath := cHwg_image_dir

   INIT WINDOW oMain MAIN TITLE "HwGUI Tutorial" ;
     AT 200,0 SIZE 800,600 FONT oFont

   @ 0,0 PANEL oPanel SIZE 800,32 ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS
   @ 760,3 OWNERBUTTON oBtnRun OF oPanel ON CLICK {||RunSample()} ;
       SIZE 32,26 FLAT ;
       BITMAP "next.bmp" TRANSPARENT COLOR 12632256 ;
       TOOLTIP "Run sample" ON SIZE ANCHOR_RIGHTABS
   oBtnRun:Disable()

   @ 0,32 TREE oTree SIZE 270,568 ;
        EDITABLE ;
        BITMAP { "cl_fl.bmp","op_fl.bmp" } ;
        ON SIZE {|o,x,y|o:Move(,,,y-32)}

   oTree:bDblClick := {|oTree,oItem|RunSample(oItem)}

   oText := HCEdit():New( oMain,, WS_BORDER, 274, 32, 526, 568, oFont,, {|o,x,y|o:Move(,,x-oSplit:nLeft-oSplit:nWidth,y-32)} )

   @ 270,32 SPLITTER oSplit SIZE 4,568 ;
         DIVIDE {oTree} FROM {oText} ;
         ON SIZE {|o,x,y|o:Move(,,,y-32)}

   oSplit:bEndDrag := {||hwg_Redrawwindow( oText:handle,RDW_ERASE+RDW_INVALIDATE+RDW_INTERNALPAINT+RDW_UPDATENOW)}

   BuildTree( oTree  )

   ACTIVATE WINDOW oMain
Return Nil

Static Function ReadIni()
Local oInit, i, oNode1, cHwgui_dir

   oIni := HXMLDoc():Read( cIniPath + "tutor.xml" )
   IF !Empty( oIni:aItems ) .AND. oIni:aItems[1]:title == "init"
      oInit := oIni:aItems[1]
      FOR i := 1 TO Len( oInit:aItems )
         oNode1 := oInit:aItems[i]
         IF oNode1:title == "tutorial"
            cTutor := oNode1:GetAttribute( "file" )
         ELSEIF oNode1:title == "hwgui_dir"
            IF !Empty( cHwgui_dir := oNode1:GetAttribute( "path",,"" ) )
               cHwg_include_dir := cHwgui_dir + "\include"
               cHwg_image_dir := cHwgui_dir + "\image"
            ENDIF
         ELSEIF oNode1:title == "harbour_bin"
            cHrb_bin_dir := oNode1:GetAttribute( "path",,"" )
         ELSEIF oNode1:title == "harbour_inc"
            IF !Empty( cHrb_inc_dir := oNode1:GetAttribute( "path",,"" ) )
               cHrb_inc_dir := hb_OsPathListSeparator() + cHrb_inc_dir
            ENDIF
         ELSEIF oNode1:title == "hilight"
            oHilight := Hilight():New( oNode1 )
         ENDIF
      NEXT
   ENDIF

Return Nil

Static Function BuildTree( oTree )
Local oTreeNode1, oTreeNode2, oTNode
Local oIniTut, oInit, i, j, j1, oNode1, oNode2, oNode3, cTemp
#ifdef __PLATFORM__UNIX
Local cVer := "gtk"
#else
Local cVer := "win"
#endif
   oIniTut := HXMLDoc():Read( cIniPath + cTutor )
   IF !Empty( oIniTut:aItems ) .AND. oIniTut:aItems[1]:title == "init"
      oInit := oIniTut:aItems[1]
      FOR i := 1 TO Len( oInit:aItems )
         oNode1 := oInit:aItems[i]
         IF oNode1:title == "chapter"
            INSERT NODE oTreeNode1 CAPTION oNode1:GetAttribute( "name",,"" ) TO oTree ON CLICK {|o|NodeOut(o)}
            oTreeNode1:cargo := { .F., "" }
            FOR j := 1 TO Len( oNode1:aItems )
               oNode2 := oNode1:aItems[j]
               IF oNode2:title == "chapter"
                  INSERT NODE oTreeNode2 CAPTION oNode2:GetAttribute( "name",,"" ) TO oTreeNode1 ON CLICK {|o|NodeOut(o)}
                  oTreeNode2:cargo := { .F., "" }
                  FOR j1 := 1 TO Len( oNode2:aItems )
                     oNode3 := oNode2:aItems[j1]
                     IF oNode3:title == "module"
                        IF Empty( cTemp := oNode3:GetAttribute( "ver",,"" ) ) .OR. cTemp == cVer
                           INSERT NODE oTNode CAPTION oNode3:GetAttribute( "name",,"" ) TO oTreeNode2 BITMAP {"book.bmp"} ON CLICK {|o|NodeOut(o)}
                           oTNode:cargo := { .T., "" }
                           IF Empty( oTNode:cargo[2] := oNode3:GetAttribute( "file",,"" ) )
                              IF !Empty( oNode3:aItems ) .AND. Valtype( oNode3:aItems[1] ) == "O"
                                 oTNode:cargo[2] := oNode3:aItems[1]:aItems[1]
                              ENDIF
                           ENDIF
                        ENDIF
                     ELSEIF oNode3:title == "comment"
                        IF !Empty( oNode3:aItems ) .AND. Valtype( oNode3:aItems[1] ) == "O"
                           oTreeNode2:cargo[2] := oNode3:aItems[1]:aItems[1]
                        ENDIF
                     ENDIF
                  NEXT
               ELSEIF oNode2:title == "module"
                  IF Empty( cTemp := oNode2:GetAttribute( "ver",,"" ) ) .OR. cTemp == cVer
                     INSERT NODE oTNode CAPTION oNode2:GetAttribute( "name",,"" ) TO oTreeNode1 BITMAP {"book.bmp"} ON CLICK {|o|NodeOut(o)}
                     oTNode:cargo := { .T., "" }
                     IF Empty( oTNode:cargo[2] := oNode2:GetAttribute( "file",,"" ) )
                        IF !Empty( oNode2:aItems ) .AND. Valtype( oNode2:aItems[1] ) == "O"
                           oTNode:cargo[2] := oNode2:aItems[1]:aItems[1]
                        ENDIF
                     ENDIF
                  ENDIF
               ELSEIF oNode2:title == "comment"
                  IF !Empty( oNode2:aItems ) .AND. Valtype( oNode2:aItems[1] ) == "O"
                     oTreeNode1:cargo[2] := oNode2:aItems[1]:aItems[1]
                  ENDIF
               ENDIF
            NEXT
         ELSEIF oNode1:title == "module"
            IF Empty( cTemp := oNode1:GetAttribute( "ver",,"" ) ) .OR. cTemp == cVer
               INSERT NODE oTNode CAPTION oNode1:GetAttribute( "name",,"" ) TO oTree BITMAP {"book.bmp"} ON CLICK {|o|NodeOut(o)}
               oTNode:cargo := { .T., "" }
               IF Empty( oTNode:cargo[2] := oNode1:GetAttribute( "file",,"" ) )
                  IF !Empty( oNode1:aItems ) .AND. Valtype( oNode1:aItems[1] ) == "O"
                     oTNode:cargo[2] := oNode1:aItems[1]:aItems[1]
                  ENDIF
               ENDIF
            ENDIF
         ENDIF
      NEXT
   ENDIF
   IF !Empty( oTree:aItems )
      oTree:Select( oTree:aItems[1] )
   ENDIF

   oTree:bExpand := {||.T.}

Return Nil

Static Function NodeOut( oItem )

   IF oItem:cargo[1]
      oText:oHili := oHilight
      oBtnRun:Enable()
   ELSE
      oText:oHili := Nil
      oBtnRun:Disable()
   ENDIF
   oText:SetText( oItem:cargo[2] )

Return Nil

Static Function RunSample( oItem )
Local cText := "", cLine, i, cHrb, lWnd := .F.

   IF oItem != Nil .AND. !oItem:cargo[1]
      Return Nil
   ENDIF

   FOR i := 1 TO oText:nTextLen
      cLine := oText:aText[i]
      IF "INIT WINDOW" $ Upper( cLine )
         lWnd := .T.
      ENDIF
      cText += cLine + Chr(13)+Chr(10)
   NEXT

#ifdef __XHARBOUR__
   FErase( "__tmp.hrb" )
   oText:Save( "__tmp.prg" )
   IF hwg_RunConsoleApp( cHrb_bin_dir+"harbour "+ "__tmp.prg -n -gh -I" + cHwg_include_dir+cHrb_inc_dir ) .AND. File( "__tmp.hrb" )
      IF !Empty( cHwgrunPath )
#ifdef __PLATFORM__UNIX
           hwg_RunApp( cHwgrunPath + "hwgrun","__tmp.hrb" )
#else
           hwg_RunApp( cHwgrunPath + "hwgrun __tmp.hrb" )
#endif
      ELSE
         hwg_MsgStop( "HwgRun is absent, you need to compile it at first." )
      ENDIF
   ELSE
      hwg_MsgStop( "Compile error" )
   ENDIF
#else
   IF !Empty( cHrb := hb_compileFromBuf( cText, "harbour","-n","-I"+cHwg_include_dir+cHrb_inc_dir ) )
      IF lWnd
        IF !Empty( cHwgrunPath )
           hb_Memowrit( "__tmp.hrb", cHrb )
#ifdef __PLATFORM__UNIX
           hwg_RunApp( cHwgrunPath + "hwgrun","__tmp.hrb" )
#else
           hwg_RunApp( cHwgrunPath + "hwgrun __tmp.hrb" )
#endif
        ELSE
           hwg_MsgStop( "HwgRun is absent, you need to compile it at first." )
        ENDIF
      ELSE
        hb_hrbRun( cHrb )
      ENDIF
   ELSE
      hwg_MsgStop( "Compile error" )
   ENDIF
#endif

Return Nil

Static Function isFileInPath()
Local arr, i, cPath
#ifdef __PLATFORM__UNIX
Local cDefSep := "/"
Local cHwgRun := "hwgrun"
#else
Local cDefSep := "\"
Local cHwgRun := "hwgrun.exe"
#endif

   arr := hb_aTokens( "./" + hb_OsPathListSeparator() + Getenv( "PATH" ), hb_OsPathListSeparator() )
   FOR i := 1 TO Len( arr )
      cPath := arr[i] + Iif( Empty(arr[i]).OR.Right( arr[i],1 ) $ "\/", ;
            "", cDefSep )
      IF File( cPath + cHwgRun )
         Return cPath
      ENDIF
   NEXT

Return ""
