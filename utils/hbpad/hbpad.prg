
#include "hwgui.ch"
#include "hxml.ch"

#define APP_VERSION  "1.0"

#define HILIGHT_KEYW    1
#define HILIGHT_FUNC    2
#define HILIGHT_QUOTE   3
#define HILIGHT_COMM    4

#define P_X             1
#define P_Y             2

#define FBITCTRL        4
#define FBITSHIFT       3
#define FBITALT         9

#ifdef __GTK__
#include "gtk.ch"
#endif

REQUEST HB_CODEPAGE_RU1251, HB_CODEPAGE_RU866, HB_CODEPAGE_RUKOI8
REQUEST HB_CODEPAGE_DEWIN, HB_CODEPAGE_DE850
REQUEST HB_CODEPAGE_UTF8

REQUEST HB_BLOWFISHKEY, HB_BLOWFISHENCRYPT, HB_BLOWFISHDECRYPT
REQUEST HB_BASE64ENCODE, HB_BASE64DECODE

#define MENU_NUMB        1901
#define MENU_WRAP        1902
#define MENU_FINDNEXT    1903
#define MENU_PLUS        1904
#define MENU_MINUS       1905
#define MENU_UNDO        1906
#define MENU_CTRL_C      1907
#define MENU_CTRL_X      1908
#define MENU_CURLINE     1909
#define MENU_UPPER       1910
#define MENU_LOWER       1911
#define MENU_TCASE       1912
#define MENU_STATUS      1913
#define MENU_CTRL_C_1    1914
#define MENU_CTRL_X_1    1915
#define MENU_UPPER_1     1916
#define MENU_LOWER_1     1917
#define MENU_TCASE_1     1918

#define MAX_RECENT_FILES    6

#define STATUS_HEIGHT      28

MEMVAR cIniPath

STATIC oEdit, lStatus := .T.
STATIC cSearch := "", aPointFound, lSeaCase := .T.
STATIC lSelected := .F., lIsUndo := .F.
STATIC aFilesRecent := {}, lOptChg := .F.
STATIC oFontMain, oMenu, cpDef := "RU1251"
STATIC aPlugins := {}

FUNCTION Main ( fName )

   LOCAL oMainWindow, oStatus, i
   PRIVATE cIniPath := hb_fnameDir( hb_ArgV( 0 ) )

   ReadIni( cIniPath )
   SetPlugins()

   SET DATE FORMAT "dd.mm.yy"
   IF Empty( oFontMain )
      PREPARE FONT oFontMain NAME "Courier New" WIDTH 0 HEIGHT - 17 CHARSET 204
   ENDIF

   SetCpDef()

   INIT WINDOW oMainWindow MAIN TITLE "HbPad"  ;
      AT 200, 0 SIZE 600, 300                                ;
      ON GETFOCUS { || iif( oEdit != Nil, hwg_Setfocus( oEdit:handle ), .T. ) } ;
      FONT oFontMain SYSCOLOR - 1

   @ 0, 0 HCEDIT oEdit SIZE 600, 270-STATUS_HEIGHT ;
      ON SIZE {|o,x,y|o:Move( ,, x, y-Iif(lStatus,STATUS_HEIGHT,0) ) }
   IF hwg__isUnicode()
      oEdit:lUtf8 := .T.
   ENDIF
   oEdit:bAfter := {||f_bAfter()}
   oEdit:bRClick := {||on_RClick()}
//#ifdef _USE_HILIGHT_
   oEdit:SetHili( HILIGHT_KEYW, oEdit:oFont:SetFontStyle( .T. ), 8388608, oEdit:bColor )  // 8388608
   oEdit:SetHili( HILIGHT_FUNC, - 1, 8388608, 16777215 )   // Blue on White // 8388608
   oEdit:SetHili( HILIGHT_QUOTE, - 1, 16711680, 16777215 )     // Green on White  // 4227072
   oEdit:SetHili( HILIGHT_COMM, oEdit:oFont:SetFontStyle( ,, .T. ), 32768, 16777215 )    // Green on White //4176740
//#endif
   oEdit:bColorCur := oEdit:bColor

   ADD STATUS PANEL oStatus TO oMainWindow HEIGHT STATUS_HEIGHT PARTS 160,80,70,0

   MENU OF oMainWindow
      MENU TITLE "&File"
         MENUITEM "&New"+Chr(9)+"Ctrl+N" ACTION NewFile() ACCELERATOR FCONTROL,Asc("N")
         MENUITEM "&Open"+Chr(9)+"Ctrl+O" ACTION __OpenFile() ACCELERATOR FCONTROL,Asc("O")
         SEPARATOR
         MENUITEM "&Save"+Chr(9)+"Ctrl+S" ACTION SaveFile( .F. ) ACCELERATOR FCONTROL,Asc("S")
         MENUITEM "&Save as" ACTION SaveFile(.T. )
         SEPARATOR
         MENU TITLE "&Recent files"
         FOR i := 1 TO Len( aFilesRecent )
            Hwg_DefineMenuItem( aFilesRecent[i,1], 1020 + i, ;
               &( "{||__OpenFile('" + aFilesRecent[i,1] + "','" + aFilesRecent[i,2] + "')}" ) )
         NEXT
         ENDMENU
         SEPARATOR
         MENUITEM "&Print"+Chr(9)+"Ctrl+P" ACTION PrintFile() ACCELERATOR FCONTROL,Asc("P")
         SEPARATOR
         MENUITEM "E&xit" ACTION hwg_EndWindow()
      ENDMENU
      MENU TITLE "&Edit"
         MENUITEM "Undo" + Chr( 9 ) + "Ctrl+Z" ID MENU_UNDO ACTION oEdit:Undo()
         SEPARATOR
         MENUITEM "Cut" + Chr( 9 ) + "Ctrl+X" ID MENU_CTRL_X ACTION oEdit:onKeyDown(88,,hwg_SetBit(0,FBITCTRL))
         MENUITEM "Copy" + Chr( 9 ) + "Ctrl+C" ID MENU_CTRL_C ACTION oEdit:onKeyDown(67,,hwg_SetBit(0,FBITCTRL))
         MENUITEM "Paste" + Chr( 9 ) + "Ctrl+V" ACTION oEdit:onKeyDown(86,,hwg_SetBit(0,FBITCTRL))
         SEPARATOR
         MENUITEM "&Find" + Chr( 9 ) + "Ctrl+F" ACTION Find() ACCELERATOR FCONTROL, Asc( "F" )
         MENUITEM "Find &Next"+Chr(9)+"F3" ID MENU_FINDNEXT ACTION FindNext() ACCELERATOR 0,VK_F3
         SEPARATOR
         MENUITEM "Select All" + Chr( 9 ) + "Ctrl+A" ACTION oEdit:onKeyDown(65,,hwg_SetBit(0,FBITCTRL))
         MENUITEM "Insert date/time" ACTION oEdit:InsText( oEdit:aPointC, Dtoc(Date())+" "+Time() )
      ENDMENU
      MENU TITLE "&View"
         MENUITEMCHECK "Show status pane" ID MENU_STATUS ACTION ShowStatus()
         MENUITEMCHECK "Wrap" ID MENU_WRAP ACTION hwg_Checkmenuitem(,MENU_WRAP,!oEdit:SetWrap(!oEdit:SetWrap()))
         MENUITEMCHECK "Show line numbers" ID MENU_NUMB ACTION ( hwg_Checkmenuitem(,MENU_NUMB,oEdit:lShowNumbers := !oEdit:lShowNumbers), oEdit:Refresh() )
         MENUITEMCHECK "Hilight current line" ID MENU_CURLINE ACTION ( hwg_Checkmenuitem(,MENU_CURLINE,(oEdit:bColorCur==oEdit:bColor)), oEdit:bColorCur := Iif(oEdit:bColorCur==oEdit:bColor,16449510,oEdit:bColor), oEdit:Refresh() )
         SEPARATOR
         MENUITEM "&Zoom in"  + Chr( 9 ) + "Ctrl++" ID MENU_PLUS ACTION ChangeFont( 2 ) ACCELERATOR FCONTROL,VK_ADD
         MENUITEM "&Zoom out"  + Chr( 9 ) + "Ctrl+-"  ID MENU_MINUS ACTION ChangeFont( -2 ) ACCELERATOR FCONTROL,VK_SUBTRACT
         SEPARATOR
         MENUITEM "Set font" ACTION SetFont()
      ENDMENU
      MENU TITLE "&Tools"
         MENUITEM "to &UPPER CASE" ID MENU_UPPER ACTION CnvCase( 1 )
         MENUITEM "To &lower case" ID MENU_LOWER ACTION CnvCase( 2 )
         MENUITEM "To &Title case" ID MENU_TCASE ACTION CnvCase( 3 )
         SEPARATOR
         MENU TITLE "&Plugins"
         FOR i := 1 TO Len( aPlugins )
            Hwg_DefineMenuItem( aPlugins[i,1], 1040 + i, ;
               &( "{||__RunPlugin(" + Ltrim(Str(i)) + ")}" ) )
         NEXT
         ENDMENU
      ENDMENU
      MENU TITLE "&Help"
         MENUITEM "About" ACTION hwg_MsgInfo( "HbPad"+Chr(13)+Chr(10)+"Simple text editor"+Chr(13)+Chr(10)+"Version "+APP_VERSION+Iif(hwg__isUnicode()," (Unicode)",""), "About" )
      ENDMENU
   ENDMENU

   CONTEXT MENU oMenu
      MENUITEM "Cut" + Chr( 9 ) + "Ctrl+X" ID MENU_CTRL_X_1 ACTION oEdit:onKeyDown(88,,hwg_SetBit(0,FBITCTRL))
      MENUITEM "Copy" + Chr( 9 ) + "Ctrl+C" ID MENU_CTRL_C_1 ACTION oEdit:onKeyDown(67,,hwg_SetBit(0,FBITCTRL))
      MENUITEM "Paste" + Chr( 9 ) + "Ctrl+V" ACTION oEdit:onKeyDown(86,,hwg_SetBit(0,FBITCTRL))
      SEPARATOR
      MENUITEM "to &UPPER CASE" ID MENU_UPPER_1 ACTION CnvCase( 1 )
      MENUITEM "To &lower case" ID MENU_LOWER_1 ACTION CnvCase( 2 )
      MENUITEM "To &Title case" ID MENU_TCASE_1 ACTION CnvCase( 3 )
   ENDMENU

   hwg_Enablemenuitem( , MENU_CTRL_C, lSelected, .T. )
   hwg_Enablemenuitem( , MENU_CTRL_X, lSelected, .T. )
   hwg_Enablemenuitem( , MENU_UNDO, lIsUndo, .T. )
   hwg_Enablemenuitem( , MENU_UPPER, lSelected, .T. )
   hwg_Enablemenuitem( , MENU_LOWER, lSelected, .T. )
   hwg_Enablemenuitem( , MENU_TCASE, lSelected, .T. )
   ShowStatus()
   oStatus:Write( cpDef, 2 )

   IF fname != Nil
      __OpenFile( fname )
   ENDIF

   ACTIVATE WINDOW oMainWindow

   CloseFile()
   IF lOptChg
      WriteIni( cIniPath )
   ENDIF

   RETURN Nil

STATIC FUNCTION f_bAfter()

   STATIC nCurrLine := 0, nLines := 0, nCurrPos := 0, lIns := Nil

   IF lSelected != !Empty( oEdit:aPointM2[P_Y] )
      lSelected := !lSelected
      hwg_Enablemenuitem( , MENU_CTRL_C, lSelected, .T. )
      hwg_Enablemenuitem( , MENU_CTRL_X, lSelected, .T. )
      hwg_Enablemenuitem( , MENU_UPPER, lSelected, .T. )
      hwg_Enablemenuitem( , MENU_LOWER, lSelected, .T. )
      hwg_Enablemenuitem( , MENU_TCASE, lSelected, .T. )
   ENDIF
   IF lIsUndo != !Empty( oEdit:aUndo )
      lIsUndo := !lIsUndo
      hwg_Enablemenuitem( , MENU_UNDO, lIsUndo, .T. )
   ENDIF
   IF oEdit:aPointC[P_Y] != nCurrLine .OR. oEdit:aPointC[P_X] != nCurrPos .OR. oEdit:nTextLen != nLines
      nCurrLine := oEdit:aPointC[P_Y]
      nCurrPos := oEdit:aPointC[P_X]
      nLines := oEdit:nTextLen
      HWindow():GetMain():oStatus:Write( Ltrim(Str(nCurrLine))+"/"+Ltrim(Str(nLines))+"  ["+Ltrim(Str(nCurrPos))+"]", 1, .T. )
   ENDIF
   IF lIns == Nil .OR. lIns != oEdit:lInsert
      lIns := oEdit:lInsert
      HWindow():GetMain():oStatus:Write( Iif( lIns, "Ins", "Repl" ), 3, .T. )
   ENDIF

   RETURN -1

STATIC FUNCTION on_RClick()

   LOCAL lSelected := !Empty( oEdit:aPointM2[P_Y] )

   hwg_Enablemenuitem( oMenu, MENU_CTRL_C_1, lSelected, .T. )
   hwg_Enablemenuitem( oMenu, MENU_CTRL_X_1, lSelected, .T. )
   hwg_Enablemenuitem( oMenu, MENU_UPPER_1, lSelected, .T. )
   hwg_Enablemenuitem( oMenu, MENU_LOWER_1, lSelected, .T. )
   hwg_Enablemenuitem( oMenu, MENU_TCASE_1, lSelected, .T. )

   oMenu:Show( HWindow():GetMain() )

   RETURN Nil

STATIC FUNCTION ShowStatus()

   LOCAL oWnd := HWindow():GetMain()

   lStatus := !lStatus
   IF lStatus
      oEdit:Move( ,,, oEdit:nHeight-(STATUS_HEIGHT) )
      oWnd:oStatus:Show()
      //oWnd:oStatus:Move( ,,, STATUS_HEIGHT )
   ELSE
      oWnd:oStatus:Hide()
      //oWnd:oStatus:Move( ,,, 0 )
      oEdit:Move( ,,, oEdit:nHeight+STATUS_HEIGHT )
   ENDIF
   hwg_Checkmenuitem( , MENU_STATUS, lStatus )
   oEdit:Refresh()

   RETURN Nil

STATIC FUNCTION NewFile()

   //oEdit:SetText( , oEdit:cpSource, cpDef )
   oEdit:SetText( ,, cpDef )
   HWindow():GetMain():oStatus:Write( cpDef, 2, .T. )

   RETURN Nil

FUNCTION __OpenFile( fname, cp )

   LOCAL oDlg, oGet, cFile := ""
   LOCAL aCps := { "", "DE850", "DEWIN", "RU1251", "RU866", "RUKOI8" }, nCp := 1

   CloseFile()

   IF Empty( fname )
      IF hwg__isUnicode()
         AAdd( aCps, "UTF8" )
      ENDIF

      INIT DIALOG oDlg TITLE "Open file" AT 50, 50 SIZE 400, 230 FONT HWindow():GetMain():oFont

      @ 20, 30 GET oGet VAR cFile SIZE 320, 24 STYLE ES_AUTOHSCROLL MAXLENGTH 0
      @ 340, 30 BUTTON ".." SIZE 40, 24 ON CLICK ;
         {||fname := hwg_Selectfile( { "Text files (*.txt)", "All files" }, { "*.txt", "*.*" }, "" ), cFile := Iif(Empty(fname),cFile,fname), oGet:Refresh()}

      @ 20, 80 SAY "Codepage:" SIZE 120, 24
      @ 140, 80 GET COMBOBOX nCp ITEMS aCps SIZE 140, 28 DISPLAYCOUNT 5

      @ 20, 180  BUTTON "Ok" SIZE 100, 32 ON CLICK {||oDlg:lResult := .T., hwg_EndDialog() }
      @ 280, 180 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32

      ACTIVATE DIALOG oDlg
      cp := aCps[nCp]
   ELSE
      cFile := fname
   ENDIF

   IF ( Empty(oDlg) .OR. oDlg:lResult ) .AND. !Empty( cFile )
//#ifdef _USE_HILIGHT_
      IF File( cIniPath + "hilight.xml" )
         oEdit:HighLighter( Hilight():New( cIniPath + "hilight.xml", Lower( hb_fnameExt( cFile ) ) ) )
      ENDIF
//#endif
      oEdit:Open( cFile, Iif( Empty(cp), Nil, cp ), SetCpDef( cp ) )
      Add2Recent( cFile )
      HWindow():GetMain():oStatus:Write( Iif( Empty(cp), SetCpDef(), cp ), 2, .T. )
   ENDIF

   RETURN Nil

STATIC FUNCTION SaveFile( lAs )

   LOCAL oWnd, oDlg, oGet, cFile := "", fname
   LOCAL aCps, nCp := 1, cp := ""

   IF lAs .OR. Empty( oEdit:cFileName )
      IF Empty( oEdit:cpSource ) .OR. oEdit:cpSource == "UTF8"
         aCps := { "DE850", "DEWIN", "RU1251", "RU866", "RUKOI8" }
         IF Empty( oEdit:cpSource )
            hb_AIns( aCps, 1, "", .T. )
         ENDIF
      ELSEIF Left( oEdit:cpSource,2 ) == "RU"
         aCps := { "RU1251", "RU866", "RUKOI8" }
      ELSE
         aCps := { "DE850", "DEWIN" }
      ENDIF
      IF hwg__isUnicode()
         AAdd( aCps, "UTF8" )
      ENDIF
      nCp := Iif( Empty( oEdit:cpSource ), 1, Ascan( aCps, oEdit:cpSource ) )
      IF lAs
         cFile := oEdit:cFileName
      ENDIF

      INIT DIALOG oDlg TITLE "Save file" AT 50, 50 SIZE 400, 230 FONT oFontMain

      @ 20, 30 GET oGet VAR cFile SIZE 320, 24 STYLE ES_AUTOHSCROLL MAXLENGTH 0
#ifdef __GTK__
      @ 340, 30 BUTTON ".." SIZE 40, 24 ON CLICK ;
         {||fname := hwg_Selectfile( "( *.* )", "*.*", CurDir() ), cFile := Iif(Empty(fname),cFile,fname), oGet:Refresh()}
#else
      @ 340, 30 BUTTON ".." SIZE 40, 24 ON CLICK ;
         {||fname := hwg_SaveFile( "*.*", "( *.* )", "*.*", CurDir() ), cFile := Iif(Empty(fname),cFile,fname), oGet:Refresh()}
#endif
      @ 20, 80 SAY "Codepage:" SIZE 120, 24
      @ 140, 80 GET COMBOBOX nCp ITEMS aCps SIZE 140, 28 DISPLAYCOUNT 5

      @ 20, 180  BUTTON "Ok" SIZE 100, 32 ON CLICK {||oDlg:lResult := .T., hwg_EndDialog() }
      @ 280, 180 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32

      ACTIVATE DIALOG oDlg
      cp := aCps[nCp]
   ELSE
      cFile := oEdit:cFileName
      cp := oEdit:cpSource
   ENDIF

   IF !Empty( cFile )
      oEdit:Save( cFile, cp )
      oEdit:lUpdated := .F.
      oEdit:cpSource := cp
      Add2Recent( cFile )
      IF !Empty( oWnd := HWindow():GetMain() )
         oWnd:oStatus:Write( Iif( Empty(cp), SetCpDef(), cp ), 2, .T. )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION CloseFile()

   IF oEdit:lUpdated .AND. hwg_MsgYesNo( "Save changes ?" )
      SaveFile( .F. )
   ENDIF

   RETURN Nil

STATIC FUNCTION PrintFile( )
   LOCAL arr := ChangeDoc()

   IF arr != Nil
      oEdit:Print( arr[1], arr[2]-1, arr[3], arr[4], arr[5], arr[6] )
   ENDIF
   RETURN Nil

STATIC FUNCTION ChangeDoc()
   LOCAL oDlg, arr[6]
   LOCAL nFormat := 2, aCombo := { "A3", "A4", "A5", "A6" }
   LOCAL nOrient := 1, nMargL, nMargR, nMargT, nMargB

   nMargL := nMargR := nMargT := nMargB := 10

   INIT DIALOG oDlg CLIPPER NOEXIT TITLE "Page format"  ;
      AT 210, 10  SIZE 440, 370 FONT HWindow():GetMain():oFont

   @ 20, 20 SAY "Size:" SIZE 100, 24
   @ 120, 16 GET COMBOBOX nFormat ITEMS aCombo SIZE 120, 150

   @ 20,60 GROUPBOX "Orientation" SIZE 200, 90

   GET RADIOGROUP nOrient
   @ 40,90 RADIOBUTTON "Portrait" SIZE 160, 22
   @ 40,114 RADIOBUTTON "Landscape" SIZE 160, 22
   END RADIOGROUP

   @ 20,170 GROUPBOX "Margins" SIZE 400, 120

   @ 40, 200 SAY "Left" SIZE 100, 24
   @ 140,200 GET UPDOWN nMargL RANGE 0,80 SIZE 60,30

   @ 240,200 SAY "Top" SIZE 100, 24
   @ 340,200 GET UPDOWN nMargT RANGE 0,80 SIZE 60,30

   @ 40, 240 SAY "Right" SIZE 100, 24
   @ 140,240 GET UPDOWN nMargR RANGE 0,80 SIZE 60,30

   @ 240,240 SAY "Bottom" SIZE 100, 24
   @ 340,240 GET UPDOWN nMargB RANGE 0,80 SIZE 60,30

   @  20, 320  BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 220, 320 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult

      arr[1] := nFormat; arr[2] := nOrient; arr[3] := nMargL; arr[4] := nMargR; arr[5] := nMargT; arr[6] := nMargB
      RETURN arr
   ENDIF

   RETURN Nil

STATIC FUNCTION ChangeFont( n )
   LOCAL oFont, nHeight := oEdit:oFont:height

   nHeight := Iif( nHeight<0, nHeight-n, nHeight+n )
#ifdef __GTK__
   oFont := HFont():Add( oEdit:oFont:name, oEdit:oFont:Width,nHeight,,oEdit:oFont:Charset,,,,,.T. )
#else
   oFont := HFont():Add( oEdit:oFont:name, oEdit:oFont:Width,nHeight,,oEdit:oFont:Charset, )
#endif
   //hwg_Setctrlfont( oEdit:oParent:handle, oEdit:id, ( oEdit:oFont := oFont ):handle )

   oEdit:SetFont( oFont )

   RETURN Nil

STATIC FUNCTION Find()

   LOCAL oDlg, oGet, i, j, lUtf8 := oEdit:lUtf8

   INIT DIALOG oDlg TITLE "Find" AT 0, 0 SIZE 400, 160 ;
      FONT HWindow():GetMain():oFont

   @ 10, 20 SAY "String:" SIZE 80, 24 STYLE SS_RIGHT

   @ 90, 20 GET oGet VAR cSearch SIZE 300, 24 STYLE ES_AUTOHSCROLL MAXLENGTH 0 ;
         ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @ 20, 56 GET CHECKBOX lSeaCase CAPTION "Case sensitive" SIZE 280, 24

   @  30, 120 BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 270, 120 BUTTON "Cancel" SIZE 100, 32 ON CLICK { ||hwg_EndDialog() }

   ACTIVATE DIALOG oDlg CENTER

   IF oDlg:lResult
      aPointFound := Nil
      IF !lSeaCase
         cSearch := Iif( oEdit:lUtf8, edi_utf8_Lower(cSearch), Lower(cSearch) )
      ENDIF
      FOR i := 1 TO oEdit:nTextLen
         IF lSeaCase
            j := At( cSearch, oEdit:aText[i] )
         ELSE
            j := At( cSearch, Iif( oEdit:lUtf8, edi_utf8_Lower(oEdit:aText[i]), Lower(oEdit:aText[i]) ) )
         ENDIF
         IF j != 0
            aPointFound := { j, i }
            EXIT
         ENDIF
      NEXT
      IF !Empty( aPointFound )
         hwg_Enablemenuitem( , MENU_FINDNEXT, .T., .T. )
         oEdit:PCopy( { aPointFound[1],aPointFound[2] }, oEdit:aPointM1 )
         oEdit:PCopy( { aPointFound[1]+hced_Len(oEdit,cSearch),aPointFound[2] }, oEdit:aPointM2 )
         oEdit:PCopy( oEdit:aPointM1, oEdit:aPointC )
         oEdit:Goto( aPointFound[2] )
      ELSE
         hwg_Enablemenuitem( , MENU_FINDNEXT, .F., .T. )
         hwg_MsgStop( "String isn't found." )
      ENDIF
   ENDIF
   hwg_Setfocus( oEdit:handle )

   RETURN Nil

STATIC FUNCTION FindNext()

   LOCAL i, j, nPosStart, nLineStart

   IF !Empty( aPointFound )
      nPosStart := aPointFound[1] + hced_Len( oEdit, cSearch )
      nLineStart := aPointFound[2]
      aPointFound := Nil

      FOR i := nLineStart TO oEdit:nTextLen
         IF lSeaCase
            j := hb_At( cSearch, oEdit:aText[i], Iif( i==nLineStart,nPosStart,1 ) )
         ELSE
            j := hb_At( cSearch, Iif(oEdit:lUtf8,edi_utf8_Lower(oEdit:aText[i]),Lower(oEdit:aText[i])), ;
               Iif( i==nLineStart,nPosStart,1 ) )
         ENDIF
         IF j != 0
            aPointFound := { j, i }
            EXIT
         ENDIF
      NEXT
      IF !Empty( aPointFound )
         oEdit:PCopy( {aPointFound[1],aPointFound[2]}, oEdit:aPointM1 )
         oEdit:PCopy( {aPointFound[1]+hced_Len(oEdit,cSearch),aPointFound[2]}, oEdit:aPointM2 )
         oEdit:Goto( aPointFound[2] )
      ELSE
         hwg_Enablemenuitem( , MENU_FINDNEXT, .F., .T. )
         hwg_MsgStop( "String isn't found." )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION SetCpDef( cpSou )

   IF hwg__isUnicode()
      hb_cdpSelect( cpDef := "UTF8" )
   ELSE
      IF Empty( cpSou )
         hb_cdpSelect( cpDef )
      ELSEIF Left( cpSou, 2 ) == "RU"
         hb_cdpSelect( cpDef := "RU1251" )
      ELSE
         hb_cdpSelect( cpDef := "DEWIN" )
      ENDIF
   ENDIF
   RETURN cpDef

STATIC FUNCTION SetFont()

   LOCAL oFont := HFont():Select( oFontMain )

   IF !Empty( oFont )
      oFontMain := oFont
      lOptChg := .T.
      oEdit:SetFont( oFont )
   ENDIF

   RETURN Nil

STATIC FUNCTION CnvCase( nType )

   LOCAL nL1, nL2, i, nPos1, nPos2, nLen, cTemp
   LOCAL lUtf8 := oEdit:lUtf8, P1, P2

   IF !Empty( oEdit:aPointM2[P_Y] )
      IF oEdit:aPointM2[P_Y] >= oEdit:aPointM1[P_Y]
         P1 := oEdit:aPointM1
         P2 := oEdit:aPointM2
      ELSE
         P2 := oEdit:aPointM1
         P1 := oEdit:aPointM2
      ENDIF
      nL1 := P1[P_Y]
      nL2 := P2[P_Y]
      FOR i := nL1 TO nL2
         nPos1 := Iif( i==nL1, P1[P_X], 1 )
         nLen := hced_Len( oEdit, oEdit:aText[i] )
         nPos2 := Iif( i==nL2, P2[P_X]-1, nLen )
         cTemp := hced_Substr( oEdit, oEdit:aText[i], nPos1, nPos2-nPos1+1 )
         IF nType == 1
            cTemp := Iif( lUtf8, edi_utf8_Upper( cTemp ), Upper( cTemp ) )
         ELSEIF nType == 2
            cTemp := Iif( lUtf8, edi_utf8_Lower( cTemp ), Lower( cTemp ) )
         ELSEIF nType == 3
            cTemp := Iif( lUtf8, edi_utf8_Upper(hb_utf8Left(cTemp,1)), Upper(Left(cTemp,1 )) ) + ;
               Iif( lUtf8, edi_utf8_Upper(hb_utf8Substr(cTemp,2)), Lower(Substr(cTemp,2)) )
         ENDIF
         oEdit:aText[i] := Iif( nPos1==1,"", hced_Left(oEdit,oEdit:aText[i],nPos1-1) ) + ;
            cTemp + Iif( nPos2==nLen, "", hced_Substr(oEdit,oEdit:aText[i],nPos2+1) )
      NEXT
      oEdit:lUpdated := .T.
      oEdit:Refresh()
   ENDIF

   RETURN Nil

FUNCTION Add2Recent( cFile )

   LOCAL i, j, cp := Iif( Empty(oEdit:cpSource), "", oEdit:cpSource )

   IF ( i := Ascan( aFilesRecent, {|a|a[1]==cFile} ) ) == 0
      IF Len( aFilesRecent ) < MAX_RECENT_FILES
         Aadd( aFilesRecent, Nil )
      ENDIF
      AIns( aFilesRecent, 1 )
      aFilesRecent[1] := { cFile, cp }
      lOptChg := .T.
   ELSEIF i > 1
      FOR j := i TO 2 STEP -1
         aFilesRecent[j] := aFilesRecent[j-1]
      NEXT
      aFilesRecent[1] := { cFile, cp }
      lOptChg := .T.
   ELSEIF !( aFilesRecent[1,2] == cp )
      aFilesRecent[1,2] := cp
      lOptChg := .T.
   ENDIF

   RETURN Nil

STATIC FUNCTION ReadIni( cPath )

   LOCAL oIni := HXMLDoc():Read( cPath + "hbpad.ini" )
   LOCAL oNode, i, j

   IF !Empty( oIni ) .AND. !Empty( oIni:aItems )
      FOR i := 1 TO Len( oIni:aItems[1]:aItems )
         oNode := oIni:aItems[1]:aItems[i]
         IF oNode:title == "recent"
            FOR j := 1 TO Min( Len( oNode:aItems ), MAX_RECENT_FILES )
               Aadd( aFilesRecent, { Trim( oNode:aItems[j]:GetAttribute("name","C","") ), ;
                  Trim( oNode:aItems[j]:GetAttribute("cp","C","") ) } )
            NEXT
         ELSEIF oNode:title == "font"
            oFontMain := FontFromXML( oNode )
         ENDIF
      NEXT
   ENDIF

   RETURN Nil

STATIC FUNCTION WriteIni( cPath )

   LOCAL oIni := HXMLDoc():New()
   LOCAL oNode, oNodeR, i

   oIni:Add( oNode := HXMLNode():New( "init" ) )

   oNode:Add( FontToXML( oFontMain, "font" ) )
   //oNode:Add(  HXMLNode():New( "codepage", HBXML_TYPE_SINGLE, { { "main", cpDef }, { "source", cpSource } } ) )
   //oNode:Add(  HXMLNode():New( "codepage", HBXML_TYPE_SINGLE, { { "main", cpDef } } ) )

   oNodeR := oNode:Add( HXMLNode():New( "recent" ) )
   FOR i := 1 TO Len( aFilesRecent )
      oNodeR:Add( HXMLNode():New( "file", HBXML_TYPE_SINGLE, { { "name", aFilesRecent[i,1] }, { "cp", aFilesRecent[i,2] } } ) )
   NEXT

   oIni:Save( cPath + "hbpad.ini" )

   RETURN Nil

STATIC FUNCTION FontFromXML( oXmlNode )

   LOCAL width  := oXmlNode:GetAttribute( "width" )
   LOCAL height := oXmlNode:GetAttribute( "height" )
   LOCAL weight := oXmlNode:GetAttribute( "weight" )
   LOCAL charset := oXmlNode:GetAttribute( "charset" )
   LOCAL ita   := oXmlNode:GetAttribute( "italic" )
   LOCAL under := oXmlNode:GetAttribute( "underline" )

   IF width != Nil
      width := Val( width )
   ENDIF
   IF height != Nil
      height := Val( height )
   ENDIF
   IF weight != Nil
      weight := Val( weight )
   ENDIF
   IF charset != Nil
      charset := Val( charset )
   ENDIF
   IF ita != Nil
      ita := Val( ita )
   ENDIF
   IF under != Nil
      under := Val( under )
   ENDIF

   RETURN HFont():Add( oXmlNode:GetAttribute( "name" ),  ;
      width, height, weight, charset, ita, under,,,.T. )

STATIC FUNCTION FontToXML( oFont, cTitle )

   LOCAL aAttr := {}

   AAdd( aAttr, { "name", oFont:name } )
   AAdd( aAttr, { "width", LTrim( Str(oFont:width,5 ) ) } )
   AAdd( aAttr, { "height", LTrim( Str(oFont:height,5 ) ) } )
   IF oFont:weight != 0
      AAdd( aAttr, { "weight", LTrim( Str(oFont:weight,5 ) ) } )
   ENDIF
   IF oFont:charset != 0
      AAdd( aAttr, { "charset", LTrim( Str(oFont:charset,5 ) ) } )
   ENDIF
   IF oFont:Italic != 0
      AAdd( aAttr, { "italic", LTrim( Str(oFont:Italic,5 ) ) } )
   ENDIF
   IF oFont:Underline != 0
      AAdd( aAttr, { "underline", LTrim( Str(oFont:Underline,5 ) ) } )
   ENDIF

   RETURN HXMLNode():New( cTitle, HBXML_TYPE_SINGLE, aAttr )

STATIC FUNCTION SetPlugins()

   LOCAL oIni
   LOCAL oNode, i, xTemp

   IF File( xTemp := (cIniPath + "plugins" + hb_ps() + "plugins.ini") )
      oIni := HXMLDoc():Read( xTemp )
      IF !Empty( oIni ) .AND. !Empty( oIni:aItems )
         FOR i := 1 TO Len( oIni:aItems[1]:aItems )
            oNode := oIni:aItems[1]:aItems[i]
            IF oNode:title == "plugin"
               xTemp := Trim( oNode:GetAttribute("file","C","") )
               IF File( xTemp := cIniPath + "plugins" + hb_ps() + xTemp )
                  AAdd( aPlugins, { Trim( oNode:GetAttribute("title","C","") ), xTemp } )
               ENDIF
            ENDIF
         NEXT
      ENDIF
   ENDIF

   RETURN Nil

FUNCTION __RunPlugin( n )

   IF Valtype( aPlugins[n,2] ) == "C"
      aPlugins[n,2] := hb_hrbLoad( aPlugins[n,2] )
   ENDIF
   IF !Empty( aPlugins[n,2] )
      hb_hrbDo( aPlugins[n,2] )
   ENDIF

   RETURN Nil
