
#include "hwgui.ch"
#include "hxml.ch"
#include "fileio.ch"

#define MODE_INPUT      1
#define MODE_INIT       2
#define MODE_WAIT_ANS   3
#define MODE_WAIT_BR    4

#define ANS_BRP         1
#define ANS_CALC        2
#define ANS_STACK       3
#define ANS_LOCAL       4
#define ANS_WATCH       5
#define ANS_AREAS       6

#define CMD_QUIT        1
#define CMD_GO          2
#define CMD_STEP        3
#define CMD_TRACE       4
#define CMD_NEXTR       5
#define CMD_TOCURS      6
#define CMD_EXIT        7
#define CMD_STACK       8

#define BUFF_LEN     1024
#define RES_LEN       100

#define  CLR_LGREEN  12507070
#define  CLR_GREEN      32768
#define  CLR_DBLUE    8404992
#define  CLR_LBLUE1  16759929
#define  CLR_LBLUE2  16764831
#define  CLR_LIGHT1  15132390
#define  CLR_LIGHT2  12632256

#define EDIT_RES         1900

#define MENU_VIEW        1901
#define MENU_STACK       1902
#define MENU_LOCAL       1903
#define MENU_WATCH       1904
#define MENU_RUN         1905
#define MENU_INIT        1906
#define MENU_QUIT        1907
#define MENU_EXIT        1908
#define MENU_BRP         1909

#if defined( __PLATFORM__UNIX )
ANNOUNCE HB_GTSYS
REQUEST HB_GT_CGI_DEFAULT
#endif

#ifdef __XHARBOUR__
#xtranslate HB_PROCESSOPEN([<n,...>]) =>  HB_OPENPROCESS(<n>)
#endif

STATIC handl1 := -1, handl2, cBuffer
STATIC nId1 := 0, nId2 := -1

STATIC oIni, cIniPath
STATIC cPrgName := "", cCurrPath := ""
STATIC cTextLocate, nLineLocate

STATIC oTimer, oSayState, oEditExpr, oBtnExp, oMainFont
STATIC oBrwRes
STATIC oStackDlg, oLocalsDlg, oWatchDlg, oAreasDlg
STATIC oBrwText
STATIC cPaths := ";"

STATIC aBP := {}
STATIC aWatches := {}
STATIC aExpr := {}
STATIC nCurrLine := 0
STATIC nMode, nAnsType
STATIC lAnimate := .F., nAnimate := 3

STATIC nExitMode := 1
STATIC cVerProto := 0

Function Main( ... )
Local oMainW, oBmpPoint, oBmpCurr
Local aParams := hb_aParams(), i, cFile, cExe, cDirWait

   ReadIni( cIniPath := FilePath( hb_ArgV( 0 ) ) )

   IF Empty( oMainFont )
      PREPARE FONT oMainFont NAME "Georgia" WIDTH 0 HEIGHT -17 CHARSET 4
   ENDIF

   INIT WINDOW oMainW MAIN TITLE "Debugger" ;
     AT 200,0 SIZE 600,544                  ;
     FONT oMainFont                         ;
     ON EXIT {|| ExitDbg()}

   MENU OF oMainW
      MENU TITLE "&File"
         MENUITEM "Debug program" ID MENU_INIT ACTION DebugNewExe()
         SEPARATOR
         MENUITEM "Set Path" ACTION SetPath()
         MENUITEM "Open prg" ACTION OpenPrg()
         SEPARATOR
         MENUITEM "&Close debugger" ID MENU_EXIT ACTION DoCommand( CMD_EXIT )
         MENUITEM "&Exit and terminate program" ID MENU_QUIT ACTION DoCommand( CMD_QUIT )
      ENDMENU
      MENU TITLE "&Locate"
         MENUITEM "&Find"+Chr(9)+"Ctrl+F" ACTION Locate( 0 ) ACCELERATOR FCONTROL,Asc("F")
         MENUITEM "&Next" +Chr(9)+"F3" ACTION Locate( 1 ) ACCELERATOR 0,VK_F3
         MENUITEM "&Previous" ACTION Locate( -1 )
         SEPARATOR
         MENUITEM "Functions &list" ACTION Funclist()
      ENDMENU
      MENU ID MENU_VIEW TITLE "&View"
         MENUITEM "&Stack" ID MENU_STACK ACTION StackToggle()
         MENUITEM "&Local vars" ID MENU_LOCAL ACTION LocalsToggle()
         MENUITEM "&Watches" ID MENU_WATCH ACTION WatchesToggle()
         SEPARATOR
         MENUITEM "Work&Areas"+Chr(9)+"F6" ACTION AreasToggle() ACCELERATOR 0,VK_F6
      ENDMENU
      MENU ID MENU_RUN TITLE "&Run"
         MENUITEM "&Animate" ACTION Animate()
         MENUITEM "&Go"+Chr(9)+"F5" ACTION DoCommand( CMD_GO ) ACCELERATOR 0,VK_F5
         MENUITEM "&Step"+Chr(9)+"F8" ACTION DoCommand( CMD_STEP ) ACCELERATOR 0,VK_F8
         MENUITEM "To &cursor"+Chr(9)+"F7" ACTION DoCommand( CMD_TOCURS ) ACCELERATOR 0,VK_F7
         MENUITEM "&Trace"+Chr(9)+"F10" ACTION DoCommand( CMD_TRACE ) ACCELERATOR 0,VK_F10
         MENUITEM "&Next Routine"+Chr(9)+"Ctrl+F5" ACTION DoCommand( CMD_NEXTR ) ACCELERATOR FCONTROL,VK_F5
      ENDMENU
      MENU ID MENU_BRP TITLE "&BreakPoints"
         MENUITEM "&Add"+Chr(9)+"F9" ACTION AddBreakPoint() ACCELERATOR 0,VK_F9
         MENUITEM "&Delete"+Chr(9)+"F9" ACTION AddBreakPoint()
      ENDMENU
      MENU TITLE "&Options"
         MENUITEM "&Font" ACTION SetFont()
         SEPARATOR
         MENUITEM "&Save Settings" ACTION SaveIni()
      ENDMENU
      MENUITEM "&About" ACTION About()
   ENDMENU

   @ 0,0 BROWSE oBrwText ARRAY SIZE 600,436  ;
       FONT oMainFont STYLE WS_BORDER+WS_VSCROLL ;
       ON SIZE {|o,x,y|o:Move(,,x,y-108)}
       
   oBrwText:aArray := {}

   oBrwText:AddColumn( HColumn():New( "",{|v,o|Iif(o:nCurrent==nCurrLine,'>',Iif(getBP(o:nCurrent)!=0,'#',' '))},"C",2,0 ) )
   oBrwText:aColumns[1]:oFont := oMainFont:SetFontStyle( .T. )
   oBrwText:aColumns[1]:bColorBlock := {||Iif(getBP(oBrwText:nCurrent)!=0, { 65535, 255, 16777215, 255 }, { oBrwText:tColor, oBrwText:bColor, oBrwText:tColorSel, oBrwText:bColorSel } )}

   oBrwText:AddColumn( HColumn():New( "",{|v,o|o:nCurrent},"N",5,0 ) )
   oBrwText:AddColumn( HColumn():New( "",{|v,o|o:aArray[o:nCurrent]},"C",80,0 ) )

   oBrwText:bEnter:= {||AddBreakPoint()}
   oBrwText:lDispHead := .F.
   oBrwText:bcolorSel := oBrwText:htbcolor := CLR_LGREEN
   oBrwText:tcolorSel := 0

   @ 4,444 BROWSE oBrwRes ARRAY SIZE 592,72 STYLE WS_BORDER + WS_VSCROLL ;
       ON SIZE {|o,x,y|o:Move(,y-104,x-8)}

   oBrwRes:aArray := {}
   oBrwRes:AddColumn( HColumn():New( "",{|v,o|o:aArray[o:nCurrent,1]},"C",80,0 ) )
   oBrwRes:lDispHead := .F.
   oBrwRes:bcolor := CLR_LIGHT1
   oBrwRes:bcolorSel := oBrwRes:htbcolor := CLR_LGREEN
   oBrwRes:tcolorSel := oBrwRes:httcolor := 0
   oBrwRes:bEnter := {|o| Iif( o:nCurrent>0.AND.o:nCurrent<=o:nRecords,oEditExpr:SetText(o:aArray[o:nCurrent,2]),.T. ) }

   @ 4,516 SAY oSayState CAPTION "" SIZE 80,28 STYLE WS_BORDER+SS_CENTER ON SIZE {|o,x,y|o:Move(,y-32)}
   SET KEY 0,VK_RETURN TO KeyPress( VK_RETURN )
   SET KEY 0,VK_UP TO KeyPress( VK_UP )
   SET KEY 0,VK_DOWN TO KeyPress( VK_DOWN )
   @ 84,516 EDITBOX oEditExpr CAPTION "" ID EDIT_RES SIZE 452,26 STYLE ES_AUTOHSCROLL ON SIZE {|o,x,y|o:Move(,y-32,x-148)}

   @ 536,516 BUTTON "-" SIZE 24, 14 ON CLICK {||PrevExpr(1)} ON SIZE {|o,x,y|o:Move(x-64,y-32)}
   @ 536,530 BUTTON "-" SIZE 24, 14 ON CLICK {||PrevExpr(-1)} ON SIZE {|o,x,y|o:Move(x-64,y-18)}
   @ 560,516 BUTTON oBtnExp CAPTION "Ok" SIZE 36, 28 ON CLICK {||Calc()} ON SIZE {|o,x,y|o:Move(x-40,y-32)}

   SetMode( MODE_INIT )

   cBuffer := Space( BUFF_LEN )

   FOR i := 1 TO Len( aParams)
      IF Left( aParams[i],1 ) == "-"
         IF Left( aParams[i],2 ) == "-c"
            cFile := Substr( aParams[i], 3 )
         ELSEIF Left( aParams[i],2 ) == "-w"
            cDirWait := Substr( aParams[i], 3 )
         ENDIF        
      ELSE
         cExe := aParams[i]
      ENDIF
   NEXT

   IF !Empty( cFile )
      hwg_Enablemenuitem( ,MENU_INIT, .F., .T. )
      handl1 := FOpen( cFile + ".d1", FO_READWRITE + FO_SHARED )
      handl2 := FOpen( cFile + ".d2", FO_READ + FO_SHARED )
      IF handl1 != -1 .AND. handl2 != -1
      ELSE
         handl1 := handl2 := -1
         hwg_MsgStop( "No connection" )
      ENDIF
   ELSEIF !Empty( cExe )
      DebugNewExe( cExe )
   ELSEIF !Empty( cDirWait )
      Wait4Conn( cDirWait )
   ENDIF

   SET TIMER oTimer OF oMainW VALUE 30 ACTION {||TimerProc()}

   ACTIVATE WINDOW oMainW

Return Nil

Static Function ReadIni( cDir )
Local oInit, oModule
Local i, j, aChn, aBoxes := {}, cValue, cTitle, cPass

   oIni := HXMLDoc():Read( cDir + "hwgdebug.xml" )
   IF !Empty( oIni:aItems ) .AND. oIni:aItems[1]:title == "init"
      oInit := oIni:aItems[1]
      FOR i := 1 TO Len( oInit:aItems )
         IF oInit:aItems[i]:title == "module"
            oModule := oInit:aItems[i]
         ELSEIF oInit:aItems[i]:title == "path"
            cPaths := oInit:aItems[i]:aItems[1]
            IF Left( cPaths,1 ) != ";"
               cPaths := ";" + cPaths
            ENDIF
         ELSEIF oInit:aItems[i]:title == "font"
            oMainFont := hwg_hfrm_FontFromXML( oInit:aItems[i] )
         ENDIF
      NEXT
   ENDIF

Return Nil

Static Function SaveIni( cDir )
Local oInit, oNode

   IF Empty( oIni ) .OR. Empty( oIni:aItems )
      oIni := HXMLDoc():New( "windows-1251" )
      oIni:Add( oInit := HXMLNode():New( "init" ) )
   ELSE
      oInit := oIni:aItems[1]
   ENDIF

   IF !Empty( oNode := oInit:Find( "path" ) )
      oNode:aItems[1] := cPaths
   ELSE
      oInit:Add( HXMLNode():New( "path",,,cPaths ) )
   ENDIF
   IF !Empty( oNode := oInit:Find( "font" ) )
      oNode:aAttr := Font2Attr( oMainFont )
   ELSE
      oInit:Add( HXMLNode():New( "font", HBXML_TYPE_SINGLE, Font2Attr( oMainFont ) ) )
   ENDIF

   oIni:Save( cIniPath + "hwgdebug.xml" )
Return Nil


Static Function DebugNewExe( cExe )
Local hProcess, lFromMenu := .F.

   IF cExe == Nil
      IF !Empty( cExe := hwg_Selectfile( "Executable files( *.exe )", "*.exe", Curdir() ) )
         lFromMenu := .T.
         aBP := {}
         aWatches := {}
         aExpr := {}
         nCurrLine := 0
         nId1 := 0
         nId2 := -1
      ELSE
         Return Nil
      ENDIF
   ENDIF

   IF !File( cExe )
      hwg_MsgStop( cExe + " isn't found..." )
      Return Nil
   ENDIF

   FErase( cExe + ".d1" )
   FErase( cExe + ".d2" )

   handl1 := FCreate( cExe + ".d1" )
   FWrite( handl1, "init,!" )
   FClose( handl1 )
   handl2 := FCreate( cExe + ".d2" )
   FClose( handl2 )

   hProcess := hb_processOpen( cExe )

   handl1 := FOpen( cExe + ".d1", FO_READWRITE + FO_SHARED )
   handl2 := FOpen( cExe + ".d2", FO_READ + FO_SHARED )
   IF handl1 != -1 .AND. handl2 != -1
      hwg_Enablemenuitem( ,MENU_INIT, .F., .T. )
   ELSE
      handl1 := handl2 := -1
      hwg_MsgStop( "No connection" )
   ENDIF

Return Nil

Static Function Wait4Conn( cDir )
Local lFromMenu := .F.

   cDir += Iif( Right( cDir,1 ) $ "\/", "", hb_OsPathSeparator() ) + "hwgdebug"
   FErase( cDir + ".d1" )
   FErase( cDir + ".d2" )

   handl1 := FCreate( cDir + ".d1" )
   FWrite( handl1, "init,!" )
   FClose( handl1 )
   handl2 := FCreate( cDir + ".d2" )
   FClose( handl2 )

   handl1 := FOpen( cDir + ".d1", FO_READWRITE + FO_SHARED )
   handl2 := FOpen( cDir + ".d2", FO_READ + FO_SHARED )
   IF handl1 != -1 .AND. handl2 != -1
      hwg_Enablemenuitem( ,MENU_INIT, .F., .T. )
   ELSE
      handl1 := handl2 := -1
      hwg_MsgStop( "No connection" )
   ENDIF

Return Nil

Static Function dbgRead()
Local n, s := "", arr

   FSeek( handl2, 0, 0 )
   DO WHILE ( n := Fread( handl2, @cBuffer, Len(cBuffer) ) ) > 0
      s += Left( cBuffer, n )
      IF ( n := At( ",!", s ) ) > 0
         IF ( arr := hb_aTokens( Left( s,n+1 ), "," ) ) != Nil .AND. Len( arr ) > 2 .AND. arr[1] == arr[Len(arr)-1]
            Return arr
         ELSE
            EXIT
         ENDIF
      ENDIF
   ENDDO
Return Nil

Static Function SetCurrLine( nLine )
Local nLine1 := oBrwText:nCurrent - oBrwText:rowPos + 1
   oBrwText:nCurrent := nLine
   IF nLine < nLine1 .OR. nLine > nLine1 + oBrwText:rowCount - 1
      oBrwText:rowPos := Int( oBrwText:rowCount / 2 )
   ENDIF
   IF oBrwText:rowPos > nLine
      oBrwText:rowPos := nLine
   ENDIF
   hwg_VScrollPos( oBrwText, 0, .F. )
   oBrwText:Refresh()
Return Nil

Static Function Locate( nDir )
Local i, arr := oBrwText:aArray

   IF Empty( arr )
      Return Nil
   ENDIF
   IF nDir == 0 .OR. nDir > 0
      IF nDir == 0
         cTextLocate := hu_Get( "Search string", "@S256", "" )
         nLineLocate := 0
      ELSEIF Empty( nLineLocate )
         Return Nil
      ENDIF
      IF !Empty( cTextLocate )
         cTextLocate := Lower( cTextLocate )
         FOR i := nLineLocate+1 TO Len( arr )
            IF cTextLocate $ Lower( arr[i] )
               nLineLocate := i
               EXIT
            ENDIF
         NEXT
         IF i > Len( arr )
            hwg_MsgStop( "String isn't found" )
         ELSE
            SetCurrLine( nLineLocate )
         ENDIF
      ENDIF
   ELSEIF nDir < 0
       IF !Empty( cTextLocate ) .AND. !Empty( nLineLocate )
         FOR i := nLineLocate-1 TO 1 STEP -1
            IF cTextLocate $ Lower( arr[i] )
               nLineLocate := i
               EXIT
            ENDIF
         NEXT
       ENDIF
       IF i == 0
          hwg_MsgStop( "String isn't found" )
       ELSE
          SetCurrLine( nLineLocate )
       ENDIF
   ENDIF
Return Nil

Static Function Funclist()
Local i, arr := oBrwText:aArray, cLine, cfirst, cSecond, nSkip, arrfnc := {}

   IF Empty( arr )
      Return Nil
   ENDIF
   FOR i := 1 TO Len( arr )
      cLine := Lower( Ltrim( arr[i] ) )
      nSkip := 0
      cfirst := hb_TokenPtr( cLine, @nSkip )
      IF cfirst == "function" .OR. cfirst == "procedure" .OR. ;
            cfirst == "method" .OR. cfirst == "func" .OR. cfirst == "proc" .OR. ;
            ( cfirst == "static" .AND. ( ( cSecond := hb_TokenPtr( cLine, @nSkip ) ) == "function" .OR. ;
            cSecond == "procedure" .OR. cSecond == "func" .OR. cSecond == "proc" ) )
         Aadd( arrfnc, { arr[i], i } )
      ENDIF
   NEXT
   IF !Empty( arrfnc ) .AND. ( i := hwg_WChoice( arrfnc, "Functions list",,,HWindow():GetMain():oFont ) ) != 0
      SetCurrLine( arrfnc[i,2] )
   ENDIF
Return Nil

Static Function TimerProc()
Local n, arr, lRes := .F.
Static nLastSec := 0

   IF nMode != MODE_INPUT
      IF !Empty( arr := dbgRead() )
         IF nMode == MODE_WAIT_ANS
            IF Left(arr[1],1) == "b" .AND. ( n := Val( Substr(arr[1],2) ) ) == nId1
               IF nAnsType == ANS_CALC
                  IF arr[2] == "value"
                     SetResult( Hex2Str( arr[3] ) )
                  ELSE
                     oEditExpr:SetText( "-- BAD ANSWER --" )
                  ENDIF
               ELSEIF nAnsType == ANS_BRP
                  IF arr[2] == "err"
                     oEditExpr:SetText( "-- BAD LINE --" )
                  ELSE
                     ToggleBreakPoint( arr[2], arr[3] )
                  ENDIF
               ELSEIF nAnsType == ANS_STACK
                  IF arr[2] == "stack"
                     ShowStack( arr, 3 )
                  ENDIF
               ELSEIF nAnsType == ANS_LOCAL
                  IF arr[2] == "valuelocal"
                     ShowLocals( arr, 3 )
                  ENDIF
               ELSEIF nAnsType == ANS_WATCH
                  IF arr[2] == "valuewatch"
                     ShowWatch( arr, 3 )
                  ENDIF
               ELSEIF nAnsType == ANS_AREAS
                  IF arr[2] == "valueareas"
                     ShowAreas( arr, 3 )
                  ENDIF
               ENDIF
               lRes := .T.
               SetMode( MODE_INPUT )
            ENDIF
         ELSE
            IF Left(arr[1],1) == "a" .AND. ( n := Val( Substr(arr[1],2) ) ) > nId2
               lRes := .T.
               nId2 := n
               IF arr[2] == "."
                  oEditExpr:SetText( "-- BAD LINE --" )
               ELSE
                  IF !( cPrgName == arr[2] )
                     cPrgName := arr[2]
                     SetBrwText()
                  ENDIF
                  nCurrLine := Val( arr[3] )
                  IF !Empty( oBrwText:aArray )
                     SetCurrLine( nCurrLine )
                  ENDIF
                  n := 4
                  DO WHILE .T.
                     IF arr[n] == "ver"
                        cVerProto := Val( arr[n+1] )
                        n += 2
                     ELSEIF arr[n] == "stack"
                        ShowStack( arr, n+1 )
                        n += 2 + Val( arr[n+1] ) * 3
                     ELSEIF arr[n] == "valuelocal"
                        ShowLocals( arr, n+1 )
                        n += 2 + Val( arr[n+1] ) * 3
                     ELSEIF arr[n] == "valuewatch"
                        ShowWatch( arr, n+1 )
                        n += 2 + Val( arr[n+1] )
                     ELSE
                        EXIT
                     ENDIF
                  ENDDO
                  hwg_Setwindowtext( HWindow():GetMain():handle, "Debugger ("+arr[2]+", line "+arr[3]+")" )
               ENDIF
               SetMode( MODE_INPUT )
               nLastSec := Seconds()
            ENDIF
         ENDIF
      ENDIF
   ELSEIF lAnimate .AND. Seconds() - nLastSec > nAnimate
      Send( "cmd", "step" )
      SetMode( MODE_WAIT_BR )
   ENDIF

Return Nil

Static Function SetMode( newMode )
Local aStates := { { "Input",16711680,CLR_LGREEN }, { "Init",16777215,CLR_DBLUE }, { "Wait",16777215,255 }, { "Run",16777215,0 } }

   nMode := newMode
   hwg_Enablemenuitem( ,MENU_RUN, (newmode==MODE_INPUT), .T. )
   hwg_Enablemenuitem( ,MENU_VIEW, (newmode==MODE_INPUT), .T. )
   hwg_Enablemenuitem( ,MENU_BRP, (newmode==MODE_INPUT), .T. )
   hwg_Enablemenuitem( ,MENU_QUIT, (newmode==MODE_INPUT), .T. )
   hwg_Drawmenubar( HWindow():GetMain():handle )
   oSayState:SetValue( aStates[ newMode,1 ] )
   oSayState:SetColor( aStates[ newMode,2 ], aStates[ newMode,3 ], .T. )
   IF newMode == MODE_INPUT
      oBtnExp:Enable()
#if defined( __PLATFORM__UNIX )
#else
      hwg_SetForeGroundWindow( HWindow():GetMain():handle )
#endif
   ELSE
      oBtnExp:Disable()
      IF newMode == MODE_WAIT_ANS .OR. newMode == MODE_WAIT_BR
         IF newMode == MODE_WAIT_BR
            nCurrLine := 0
            oBrwText:Refresh()
         ENDIF
      ENDIF
   ENDIF

Return Nil

Static Function Send( ... )
Local arr := hb_aParams(), i, s := ""

   FSeek( handl1, 0, 0 )
   FOR i := 1 TO Len( arr )
      s += arr[i] + ","
   NEXT
   FWrite( handl1, Ltrim(Str(++nId1)) + "," + s + Ltrim(Str(nId1)) + ",!" )

Return Nil

Static Function Animate()
Local n := hu_Get( "Seconds:", "9", nAnimate )

   IF !Empty( n )
      nAnimate := n
      lAnimate := .T.
      Send( "cmd", "step" )
      SetMode( MODE_WAIT_BR )
   ENDIF
Return Nil

Static Function DoCommand( nCmd )

   IF nMode == MODE_INPUT
      lAnimate := .F.
      IF nCmd == CMD_GO
         hwg_Setwindowtext( HWindow():GetMain():handle, "Debugger ("+cPrgName+")" )
         Send( "cmd", "go" )
      ELSEIF nCmd == CMD_STEP
         Send( "cmd", "step" )
      ELSEIF nCmd == CMD_TOCURS
         Send( "cmd", "to", cPrgName, Ltrim(Str(oBrwText:nCurrent)) )
      ELSEIF nCmd == CMD_TRACE
         Send( "cmd", "trace" )
      ELSEIF nCmd == CMD_NEXTR
         Send( "cmd", "nextr" )
      ELSEIF nCmd == CMD_QUIT
         nExitMode := 2
         hwg_EndWindow()
         Return Nil
      ELSEIF nCmd == CMD_EXIT
         nExitMode := 1
         hwg_EndWindow()
         Return Nil
      ENDIF
      SetMode( MODE_WAIT_BR )
   ELSEIF nCmd == CMD_EXIT
      nExitMode := 1
      hwg_EndWindow()
   ENDIF
Return Nil

Static Function getBP( nLine, cPrg )

   cPrg := Lower( Iif( cPrg==Nil, cPrgName, cPrg ) )
Return Ascan( aBP, {|a|a[1]==nLine .and. Lower(a[2])==cPrg} )

Static Function ToggleBreakPoint( cAns, cLine )
Local nLine := Val( cLine ), i

   IF cAns == "line"
      FOR i := 1 TO Len(aBP)
         IF aBP[i,1] == 0
            aBP[i,1] := nLine
            EXIT
         ENDIF
      NEXT
      IF i > Len(aBP)
         Aadd( aBP, { nLine, cPrgName } )
      ENDIF
   ELSE
      IF ( i := getBP( nLine ) ) == 0
         hwg_MsgInfo( "Error deleting BP line " + cLine )
      ELSE
         aBP[i,1] := 0
      ENDIF
   ENDIF
   oBrwText:Refresh()
Return Nil

Static Function AddBreakPoint()
Local i, nLine := oBrwText:nCurrent

   IF nMode != MODE_INPUT
      Return Nil
   ENDIF
   IF lAnimate
      lAnimate := .F.
      Return Nil
   ENDIF
   IF ( i := getBP( nLine ) ) == 0
      Send( "brp", "add", cPrgName, Ltrim(Str(nLine)) )
   ELSE
      Send( "brp", "del", cPrgName, Ltrim(Str(nLine)) )
   ENDIF
   nAnsType := ANS_BRP
   SetMode( MODE_WAIT_ANS )
   
Return Nil

Static Function SetPath( cRes, lClear )
Local arr, i, cFull

   IF !Empty( cRes ) .OR. !Empty( cRes := hu_Get( "Path to source files", "@S256", cPaths ) )
      cPaths := Iif( Left( cRes,1 ) != ";", ";" + cRes, cRes )
      arr := hb_aTokens( cPaths, ";" )
      IF Empty( oBrwText:aArray ) .AND. !Empty( cPrgName )
         FOR i := 1 TO Len( arr )
            cFull := arr[i] + ;
               Iif( Right( arr[i],1 ) $ "\/", "", hb_OsPathSeparator() ) + cPrgName
            IF SetBrwText( cFull, lClear )
               EXIT
            ENDIF
         NEXT
      ENDIF
   ENDIF

Return Nil

Static Function OpenPrg()
Local cFile := hwg_Selectfile( "Source files( *.prg )", "*.prg", cCurrPath )

   IF !Empty( cFile )
      SetBrwText( cFile )
   ENDIF
Return Nil

Static Function SetBrwText( cName, lClear )
Local cBuff, cNewLine := Chr(13)+Chr(10), i

   IF cName == Nil; cName := cPrgName; ENDIF

   IF File( cName ) .AND. !Empty( cBuff := MemoRead( cName ) )
      IF !( cNewLine $ cBuff )
         cNewLine := Chr(10)
      ENDIF
      cCurrPath := FilePath( cName )
      cPrgName := CutPath( cName )
      oBrwText:aArray := hb_aTokens( cBuff, cNewLine )
      FOR i := 1 TO Len( oBrwText:aArray )
         IF Chr(9) $ oBrwText:aArray[i]
            oBrwText:aArray[i] := StrTran( oBrwText:aArray[i], Chr(9), Space(4) )
         ENDIF
      NEXT
      hwg_Invalidaterect( oBrwText:handle, 1 )
      oBrwText:Refresh()
      Return .T.
   ELSEIF !Empty( lClear )
      oBrwText:aArray := {}
      hwg_Invalidaterect( oBrwText:handle, 1 )
      oBrwText:Refresh()
   ENDIF

Return .F.

Static Function PrevExpr( nDirection )
Local i
Static iPos := 0

   IF nDirection == 0

      iPos := 0
   ELSEIF iPos + nDirection <= Len( oBrwRes:aArray ) .AND. iPos + nDirection > 0

      iPos += nDirection
      i := Len(oBrwRes:aArray) - iPos + 1
      oEditExpr:SetText( oBrwRes:aArray[ i,2] )

      oBrwRes:nCurrent := i
      oBrwRes:rowPos := Min( 2, i )
      hwg_VScrollPos( oBrwRes, 0, .F. )
      hwg_Invalidaterect( oBrwRes:handle, 1 )
      oBrwRes:Refresh()

   ELSEIF nDirection < 0

      oEditExpr:SetText( "" )     
      iPos := 0
   ENDIF
   
Return Nil

Static Function SetResult( cLine )

   oBrwRes:aArray[ Len(oBrwRes:aArray),1 ] := cLine
   oBrwRes:Bottom( .T. )
   hwg_Setfocus( oEditExpr:handle )
Return Nil

Static Function KeyPress( nKey )
Local o

   IF nMode == MODE_INPUT .AND. !Empty( o := HWindow():GetMain():FindControl( ,hwg_Getfocus() ) ) .AND. o:id == EDIT_RES
      IF nKey == VK_RETURN
         Calc( o )
      ELSEIF nKey == VK_UP
         PrevExpr( 1 )
         hwg_Setfocus( oEditExpr:handle )
      ELSEIF nKey == VK_DOWN
         PrevExpr( -1 )
         hwg_Setfocus( oEditExpr:handle )
      ENDIF
   ENDIF

Return Nil

Static Function Calc()
Local cExp := Trim( oEditExpr:GetText() )

   IF !Empty( cExp )

      IF Len( oBrwRes:aArray ) < RES_LEN
         Aadd( oBrwRes:aArray, { "", cExp } )
         oBrwRes:nRecords ++
      ELSE
         Adel( oBrwRes:aArray, 1 )
         oBrwRes:aArray[RES_LEN] := { "", cExp }
      ENDIF
      PrevExpr( 0 )
      Send( "exp", Str2Hex( cExp ) )
      oEditExpr:SetText( "" )
      nAnsType := ANS_CALC
      SetMode( MODE_WAIT_ANS )
   ENDIF

Return Nil

Static FUNCTION StackToggle()
Local lStack := hwg_Ischeckedmenuitem( ,MENU_STACK )
Local bEnter := {|o| 
   IF Lower(cPrgName) != Lower(o:aArray[o:nCurrent,1])
      cPrgName := o:aArray[o:nCurrent,1]
      SetPath( cPaths,.T. )
   ENDIF
   IF !Empty( oBrwText:aArray )
      oBrwText:nCurrent := Val( o:aArray[o:nCurrent,3] )
      oBrwText:rowPos := Int( oBrwText:rowCount / 2 )
      hwg_VScrollPos( oBrwText, 0, .F. )
      oBrwText:Refresh()
   ENDIF
   }
Local bClose := {|| 
   hwg_Checkmenuitem(,MENU_STACK,.F.)
   oStackDlg:=Nil
   Send( "view", "stack", "off" )
   nAnsType := ANS_STACK
   SetMode( MODE_WAIT_ANS )
   Return .T.
   }

   IF lStack     
      oStackDlg:Close()
   ELSE
      INIT DIALOG oStackDlg TITLE "Stack" AT 0, 0 SIZE 340, 120 ;
        FONT HWindow():GetMain():oFont ON EXIT bClose

      @ 0,0 BROWSE oBrw ARRAY OF oStackDlg     ;
            SIZE 340,120                       ;
            FONT HWindow():GetMain():oFont     ;
            STYLE WS_VSCROLL                   ;
            ON SIZE {|o,x,y|o:Move(0,0,x,y)}

      oBrw:aArray := {}
      oBrw:AddColumn( HColumn():New( "",{|v,o|o:aArray[o:nCurrent,1]},"C",16,0 ) )
      oBrw:AddColumn( HColumn():New( "",{|v,o|o:aArray[o:nCurrent,2]},"C",16,0 ) )
      oBrw:AddColumn( HColumn():New( "",{|v,o|o:aArray[o:nCurrent,3]},"C",8,0 ) )

      oBrw:bcolorSel := oBrw:htbcolor := CLR_LGREEN
      oBrw:tcolorSel := oBrw:httcolor := 0
      oBrw:bEnter := bEnter

      ACTIVATE DIALOG oStackDlg NOMODAL

      Send( "view", "stack", "on" )
      nAnsType := ANS_STACK
      SetMode( MODE_WAIT_ANS )
      hwg_Checkmenuitem( ,MENU_STACK, .T. )
   ENDIF

Return Nil

Static FUNCTION ShowStack( arr, n )
Local oBrw, i, nLen := Val( arr[n] )

   IF !Empty(  oStackDlg )
      oBrw := oStackDlg:aControls[1]
      IF Empty( oBrw:aArray ) .OR. Len( oBrw:aArray ) != nLen
         oBrw:aArray := Array( nLen,3 )
      ENDIF
      FOR i := 1 TO nLen
         oBrw:aArray[i,1] := arr[ ++n ]
         oBrw:aArray[i,2] := arr[ ++n ]
         oBrw:aArray[i,3] := arr[ ++n ]
      NEXT
      oBrw:Refresh()
   ENDIF
Return Nil

Static FUNCTION LocalsToggle()
Local lLocals := hwg_Ischeckedmenuitem( ,MENU_LOCAL )
Local bClose := {|| 
   hwg_Checkmenuitem(,MENU_LOCAL,.F.)
   oLocalsDlg := Nil
   Send( "view", "local", "off" )
   nAnsType := ANS_LOCAL
   SetMode( MODE_WAIT_ANS )
   Return .T.
   }

   IF lLocals
      oLocalsDlg:Close()
   ELSE
      INIT DIALOG oLocalsDlg TITLE "Local variables" AT 10, 10 SIZE 340, 120 ;
        FONT HWindow():GetMain():oFont ON EXIT bClose

      @ 0,0 BROWSE oBrw ARRAY OF oLocalsDlg    ;
            SIZE 340,120                       ;
            FONT HWindow():GetMain():oFont     ;
            STYLE WS_VSCROLL                   ;
            ON SIZE {|o,x,y|o:Move(0,0,x,y)}

      oBrw:aArray := {}
      oBrw:AddColumn( HColumn():New( "",{|v,o|o:aArray[o:nCurrent,1]},"C",16,0 ) )
      oBrw:AddColumn( HColumn():New( "",{|v,o|o:aArray[o:nCurrent,2]},"C",2,0 ) )
      oBrw:AddColumn( HColumn():New( "",{|v,o|o:aArray[o:nCurrent,3]},"C",60,0 ) )

      oBrw:bcolorSel := oBrw:htbcolor := CLR_LGREEN
      oBrw:tcolorSel := oBrw:httcolor := 0

      ACTIVATE DIALOG oLocalsDlg NOMODAL

      Send( "view", "local", "on" )
      nAnsType := ANS_LOCAL
      SetMode( MODE_WAIT_ANS )
      hwg_Checkmenuitem( ,MENU_LOCAL, .T. )
   ENDIF

Return Nil

Static FUNCTION ShowLocals( arr, n )
Local oBrw, i, nLen := Val( arr[n] )

   IF !Empty(  oLocalsDlg )
      oBrw := oLocalsDlg:aControls[1]
      IF Empty( oBrw:aArray ) .OR. Len( oBrw:aArray ) != nLen
         oBrw:aArray := Array( nLen,3 )
      ENDIF
      FOR i := 1 TO nLen
         oBrw:aArray[i,1] := Hex2Str( arr[ ++n ] )
         oBrw:aArray[i,2] := Hex2Str( arr[ ++n ] )
         oBrw:aArray[i,3] := Hex2Str( arr[ ++n ] )
      NEXT
      oBrw:Refresh()
   ENDIF
Return Nil

Static FUNCTION WatchesToggle()
Local lWatches := hwg_Ischeckedmenuitem( ,MENU_LOCAL )
Local bClose := {|| 
   hwg_Checkmenuitem(,MENU_WATCH,.F.)
   oWatchDlg := Nil
   Send( "view", "watch", "off" )
   nAnsType := ANS_WATCH
   SetMode( MODE_WAIT_ANS )
   Return .T.
   }

   IF lWatches
      oWatchDlg:Close()
   ELSE
      INIT DIALOG oWatchDlg TITLE "Watch expressions" AT 20, 20 SIZE 340, 120 ;
        FONT HWindow():GetMain():oFont ON EXIT bClose

      MENU OF oWatchDlg
         MENUITEM "&Add" ACTION WatchAdd()
         MENUITEM "&Delete" ACTION WatchDel()
      ENDMENU

      @ 0,0 BROWSE oBrw ARRAY OF oWatchDlg     ;
            SIZE 340,120                       ;
            FONT HWindow():GetMain():oFont     ;
            STYLE WS_VSCROLL                   ;
            ON SIZE {|o,x,y|o:Move(0,0,x,y)}

      oBrw:aArray := aWatches
      oBrw:AddColumn( HColumn():New( "",{|v,o|o:aArray[o:nCurrent,1]},"C",16,0 ) )
      oBrw:AddColumn( HColumn():New( "",{|v,o|o:aArray[o:nCurrent,2]},"C",60,0 ) )

      oBrw:bcolorSel := oBrw:htbcolor := CLR_LGREEN
      oBrw:tcolorSel := oBrw:httcolor := 0

      ACTIVATE DIALOG oWatchDlg NOMODAL

      Send( "view", "watch", "on" )
      nAnsType := ANS_WATCH
      SetMode( MODE_WAIT_ANS )
      hwg_Checkmenuitem( ,MENU_WATCH, .T. )
   ENDIF

Return Nil

Static FUNCTION ShowWatch( arr, n )
Local oBrw, i, nLen := Val( arr[n] )

   IF !Empty(  oWatchDlg )
      oBrw := oWatchDlg:aControls[1]
      FOR i := 1 TO nLen
         oBrw:aArray[i,2] := Hex2Str( arr[ ++n ] )
      NEXT
      oBrw:Refresh()
   ENDIF
Return Nil

Static FUNCTION WatchAdd()
Local cExpr

   IF !Empty( cExpr := hu_Get( "Watch expression", "@S256", "" ) )
      Aadd( aWatches, { cExpr, "" } )
      Send( "watch", "add", Str2Hex( cExpr ) )
      nAnsType := ANS_WATCH
      SetMode( MODE_WAIT_ANS )
   ENDIF
Return Nil

Static FUNCTION WatchDel()
Local n := oWatchDlg:aControls[1]:nCurrent

   IF n > 0 .AND. n <= Len( aWatches )
      IF Len( aWatches ) == 1
         oWatchDlg:aControls[1]:aArray := aWatches := {}
      ELSE
         ADel( aWatches, n )
         oWatchDlg:aControls[1]:aArray := ASize( aWatches, Len( aWatches ) - 1 )
      ENDIF
      Send( "watch", "del", Ltrim(Str( n )) )
      nAnsType := ANS_WATCH
      SetMode( MODE_WAIT_ANS )
   ENDIF
Return Nil

Static FUNCTION AreasToggle()
Local oSayRdd
Local bChgPos := {|o|
   IF Empty( o:aArray )
      oSayRdd:SetValue( "No Workareas in use..." )
   ELSE
      oSayRdd:SetValue( "Rdd: " + o:aArray[o:nCurrent,3] + ;
            "  area N: " + o:aArray[o:nCurrent,2] + Chr(13)+Chr(10) + ;
            "Filter: " + o:aArray[o:nCurrent,10] + Chr(13)+Chr(10) +  ;
            "Order: " + o:aArray[o:nCurrent,11] + ", " + o:aArray[o:nCurrent,12] )
   ENDIF
   }

   IF !Empty( oAreasDlg )
      Return Nil
   ENDIF
   INIT DIALOG oAreasDlg TITLE "Watch expressions" AT 30, 30 SIZE 480, 400 ;
     FONT HWindow():GetMain():oFont ON EXIT {||oAreasDlg := Nil, .T.}

   @ 0,0 BROWSE oBrw ARRAY OF oAreasDlg     ;
         SIZE 480,260                       ;
         FONT HWindow():GetMain():oFont     ;
         STYLE WS_VSCROLL                   ;
         ON POSCHANGE bChgPos               ;
         ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   oBrw:aArray := {}
   oBrw:AddColumn( HColumn():New( "",{|v,o|Iif(Left(o:aArray[o:nCurrent,1],1)=="*","*","")},"C",1,0 ) )
   oBrw:AddColumn( HColumn():New( "Alias",{|v,o|Iif(Left(o:aArray[o:nCurrent,1],1)=="*",Substr(o:aArray[o:nCurrent,1],2),o:aArray[o:nCurrent,1])},"C",10,0 ) )
   oBrw:AddColumn( HColumn():New( "Records",{|v,o|o:aArray[o:nCurrent,4]},"C",10,0 ) )
   oBrw:AddColumn( HColumn():New( "Current",{|v,o|o:aArray[o:nCurrent,5]},"C",10,0 ) )
   oBrw:AddColumn( HColumn():New( "Bof",{|v,o|o:aArray[o:nCurrent,6]},"C",5,0 ) )
   oBrw:AddColumn( HColumn():New( "Eof",{|v,o|o:aArray[o:nCurrent,7]},"C",5,0 ) )
   oBrw:AddColumn( HColumn():New( "Fou",{|v,o|o:aArray[o:nCurrent,8]},"C",5,0 ) )
   oBrw:AddColumn( HColumn():New( "Del",{|v,o|o:aArray[o:nCurrent,9]},"C",5,0 ) )

   oBrw:bcolorSel := oBrw:htbcolor := CLR_LGREEN
   oBrw:tcolorSel := oBrw:httcolor := 0

   @ 10,264 SAY oSayRdd CAPTION "" SIZE 460,80 STYLE WS_BORDER BACKCOLOR CLR_LIGHT1 ON SIZE ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   @ 60, 360 BUTTON "Refresh" ON CLICK {|| Send("view","areas"),nAnsType:=ANS_AREAS,SetMode(MODE_WAIT_ANS) } SIZE 100, 28 ON SIZE ANCHOR_BOTTOMABS
   @ 320, 360 BUTTON "Close" ON CLICK {|| oAreasDlg:Close() } SIZE 100, 28 ON SIZE ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   ACTIVATE DIALOG oAreasDlg NOMODAL

   Send( "view", "areas" )
   nAnsType := ANS_AREAS
   SetMode( MODE_WAIT_ANS )

Return Nil

Static FUNCTION ShowAreas( arr, n )
Local oBrw, arr1, i, j, nAreas := Val( arr[n] ), nAItems := Val( Hex2Str(arr[++n]) )

   IF !Empty(  oAreasDlg )
      oBrw := oAreasDlg:aControls[1]
      arr1 := Array( nAreas, nAItems )
      FOR i := 1 TO nAreas
         FOR j := 1 TO nAItems
            arr1[i,j] := Hex2Str( arr[ ++n ] )
         NEXT
      NEXT
      oBrw:aArray := arr1
      Eval( oBrw:bPosChanged, oBrw )
      oBrw:Refresh()
   ENDIF
Return Nil

Static FUNCTION SetFont( oFont )

   IF !Empty( oFont ) .OR. !Empty( oFont := HFont():Select( HWindow():GetMain():oFont ) )
      oMainFont := oBrwText:oFont := oBrwRes:oFont := HWindow():GetMain():oFont := oFont
      oBrwText:lChanged := .T.
      oBrwText:Refresh()
      oBrwRes:lChanged := .T.
      oBrwRes:lChanged := .T.
      oBrwRes:Refresh()
   ENDIF
Return Nil

Static FUNCTION About()

   INIT DIALOG oDlg TITLE "About" AT 0, 0 SIZE 340, 170 ;
        FONT HWindow():GetMain():oFont ;
        STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX + DS_CENTER

   @ 20,30 SAY "HwGUI Debugger" SIZE 300, 24 STYLE SS_CENTER ON SIZE ANCHOR_LEFTABS + ANCHOR_RIGHTABS
   @ 20,60 SAY "Version 1.02" SIZE 300, 24 STYLE SS_CENTER ON SIZE ANCHOR_LEFTABS + ANCHOR_RIGHTABS

#if !defined( __PLATFORM__UNIX )
   @ 20,90 SAY "http://www.kresin.ru/debugger.html" ;
           LINK "http://www.kresin.ru/debugger.html" ;
           SIZE 300, 24 STYLE SS_CENTER  ;
           COLOR hwg_VColor("0000FF") ON SIZE ANCHOR_LEFTABS + ANCHOR_RIGHTABS
#endif
   @ 120, 130 BUTTON "Ok" ID IDOK SIZE 100, 28 ON SIZE ANCHOR_BOTTOMABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   ACTIVATE DIALOG oDlg

Return Nil

Function Font2Attr( oFont )
Local aAttr := {}

   Aadd( aAttr, { "name",oFont:name } )
   Aadd( aAttr, { "width",Ltrim(Str(oFont:width,5)) } )
   Aadd( aAttr, { "height",Ltrim(Str(oFont:height,5)) } )
   IF oFont:weight != 0
      Aadd( aAttr, { "weight",Ltrim(Str(oFont:weight,5)) } )
   ENDIF
   IF oFont:charset != 0
      Aadd( aAttr, { "charset",Ltrim(Str(oFont:charset,5)) } )
   ENDIF
   IF oFont:Italic != 0
      Aadd( aAttr, { "italic",Ltrim(Str(oFont:Italic,5)) } )
   ENDIF
   IF oFont:Underline != 0
      Aadd( aAttr, { "underline",Ltrim(Str(oFont:Underline,5)) } )
   ENDIF

Return aAttr

Static FUNCTION hu_Get( cTitle, tpict, txget )
LOCAL oDlg

   INIT DIALOG oDlg TITLE cTitle AT 0, 0 SIZE 300, 100 ;
        FONT HWindow():GetMain():oFont CLIPPER ;
        STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX + DS_CENTER

   @ 20, 15 GET txget SIZE 260, 26 PICTURE tpict STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @ 20, 55 BUTTON "Ok" ID IDOK SIZE 100, 32 ON SIZE ANCHOR_BOTTOMABS
   @ 180, 55 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32 ON SIZE ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      RETURN Iif( Valtype( txget ) == "C", Trim( txget ), txget )
   ENDIF

RETURN ""

Static Function Hex2Int( stroka )
Local i := ASC( stroka ), res

   IF i > 64 .AND. i < 71
      res := ( i - 55 ) * 16
   ELSEIF i > 47 .AND. i < 58
      res := ( i - 48 ) * 16
   ELSE
      Return 0
   ENDIF

   i := ASC( SubStr( stroka,2,1 ) )
   IF i > 64 .AND. i < 71
      res += i - 55
   ELSEIF i > 47 .AND. i < 58
      res += i - 48
   ENDIF
Return res

Static Function Int2Hex( n )
Local n1 := Int( n/16 ), n2 := n % 16

   IF n > 255
      Return "XX"
   ENDIF
Return Chr( Iif(n1<10,n1+48,n1+55) ) + Chr( Iif(n2<10,n2+48,n2+55) )

Static Function Str2Hex( stroka )
Local cRes := "", i, nLen := Len( stroka )

   FOR i := 1 to nLen
      cRes += Int2Hex( Asc( Substr(stroka,i,1) ) )
   NEXT
Return cRes

Static Function Hex2Str( stroka )
Local cRes := "", i := 1, nLen := Len( stroka )

   DO WHILE i <= nLen
      cRes += Chr( Hex2Int( Substr( stroka,i,2 ) ) )
      i += 2
   ENDDO
Return cRes

Static Function ExitDbg()

   IF nExitMode == 1
      IF handl1 != -1
         Send( "cmd", "exit" )
      ENDIF
   ELSEIF nExitMode == 2
      Send( "cmd", "quit" )
   ENDIF

   HWindow():GetMain():bOther := Nil
   FClose( handl1 )
   FClose( handl2 )
   handl1 := -1
Return .T.
