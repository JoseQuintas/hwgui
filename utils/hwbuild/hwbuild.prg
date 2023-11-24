/*
 * HwBuild - HwGUI Builder
 *
 * Copyright 2023 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 */

#ifndef __CONSOLE
#include "hwgui.ch"
#endif
#include "hbclass.ch"

#define HWB_VERSION  "1.0"

#define COMP_ID      1
#define COMP_EXE     2
#define COMP_LIBPATH 3
#define COMP_FLAGS   4
#define COMP_LFLAGS  5
#define COMP_HVM     6
#define COMP_HWG     7
#define COMP_CMD1    8
#define COMP_CMD2    9
#define COMP_CMDL    10
#define COMP_CMDE    11
#define COMP_OBJEXT  12
#define COMP_LIBEXT  13
#define COMP_TMPLLIB 14
#define COMP_BINLIB  15
#define COMP_BINEXE  16
#define COMP_SYSLIBS 17

#define CLR_WHITE    0xffffff
#define CLR_BLACK    0
#define CLR_DBLUE    0x614834
#define CLR_DGRAY1   0x222222
#define CLR_DGRAYA   0x404040
#define CLR_DGRAY2   0x555555
#define CLR_DGRAY3   0x888888
#define CLR_LGRAY1   0xdddddd

STATIC cIniPath
STATIC oPrg
STATIC cPathHrb := "", cPathHrbBin := "", cPathHrbInc := ""
STATIC cHrbDefFlags := "-n -q"
STATIC cPathHwgui := "", cPathHwguiInc := "", cPathHwguiLib := ""
STATIC lPathHrb := .F., lPathHrbBin := .F., lPathHrbInc := .F.
STATIC lPathHwgui := .F.

#ifdef __PLATFORM__UNIX
STATIC lUnix := .T.
STATIC cExeExt := ""
STATIC cLibsHrb := "hbvm hbrtl gtcgi gttrm hbcpage hblang hbrdd hbmacro hbpp rddntx rddcdx rddfpt hbsix hbcommon hbct hbcplr hbpcre hbzlib"
#else
STATIC lUnix := .F.
STATIC cExeExt := ".exe"
STATIC cLibsHrb := "hbvm hbrtl gtgui gtwin hbcpage hblang hbrdd hbmacro hbpp rddntx rddcdx rddfpt hbsix hbcommon hbct hbcplr hbpcre hbzlib"
#endif
STATIC cLibsHwGUI := "hwgui hbxml procmisc"

#ifndef __CONSOLE
STATIC oFontMain
#endif
STATIC cFontMain := ""

FUNCTION Main( ... )

   LOCAL aParams := hb_aParams(), i, j, c, aFiles := {}, af
   LOCAL lGUI := .F., lLib := .F., lClean := .F., oComp, cLibsDop, cLibsPath
   LOCAL cSrcPath, cObjPath, cOutPath, cOutName, cFlagsPrg, cFlagsC

   ReadIni( "hwbuild.ini" )

   FOR i := 1 TO Len( aParams )
      IF Left( aParams[i],1 ) == "-"
         IF ( c := Substr( aParams[i],2 ) ) == "bcc" .OR. c == "mingw" .OR. c == "msvc"
            IF ( j := Ascan( HCompiler():aList, {|o|o:id == c} ) ) > 0
               oComp := HCompiler():aList[j]
            ELSE
               _MsgStop( c + " compiler is missing in hwbuild.ini", "Wrong option" )
               RETURN Nil
            ENDIF

         ELSEIF c == "gui"
            lGUI := .T.

         ELSEIF c == "lib"
            lLib := .T.

         ELSEIF c == "clean"
            lClean := .T.

         ELSEIF ( Left( c,2 ) == "pf" .AND. !('=' $ c) ) .OR. Left( c,9 ) == "prgflags="
            cFlagsPrg := _DropQuotes( Substr( c, Iif( '=' $ c, 10, 3 ) ) )

         ELSEIF ( Left( c,2 ) == "cf" .AND. !('=' $ c) ) .OR. Left( c,7 ) == "cflags="
            cFlagsC := _DropQuotes( Substr( c, Iif( '=' $ c, 9, 3 ) ) )

         ELSEIF Left( c,1 ) == "L"
            cLibsPath := _DropQuotes( Substr( c, 2 ) )

         ELSEIF ( Left( c,1 ) == "l" .AND. !('=' $ c) ) .OR. Left( c,5 ) == "libs="
            cLibsDop := _DropQuotes( Substr( c, Iif( '=' $ c, 6, 2 ) ) )

         ELSEIF ( Left( c,2 ) == "sp" .AND. !('=' $ c) ) .OR. Left( c,8 ) == "srcpath="
            cSrcPath := _DropQuotes( Substr( c, Iif( '=' $ c, 9, 3 ) ) )

         ELSEIF ( Left( c,2 ) == "ob" .AND. !('=' $ c) ) .OR. Left( c,8 ) == "objpath="
            cObjPath := _DropQuotes( Substr( c, Iif( '=' $ c, 9, 3 ) ) )

         ELSEIF ( Left( c,2 ) == "op" .AND. !('=' $ c) ) .OR. Left( c,8 ) == "outpath="
            cOutPath := _DropQuotes( Substr( c, Iif( '=' $ c, 9, 3 ) ) )

         ELSEIF ( Left( c,2 ) == "on" .AND. !('=' $ c) ) .OR. Left( c,8 ) == "outname="
            cOutName := _DropQuotes( Substr( c, Iif( '=' $ c, 9, 3 ) ) )

         ELSEIF Left( c,5 ) == "comp="
            c := Substr( c, 6 )
            IF ( j := Ascan( HCompiler():aList, {|o|o:id == c} ) ) > 0
               oComp := HCompiler():aList[j]
            ENDIF
         ELSE
            _MsgStop( c, "Wrong option" )
            RETURN Nil
         ENDIF
      ELSE
         c := aParams[i]
         IF '*' $ c
            af := hb_Directory( cSrcPath + hb_ps() + c )
            FOR j := 1 TO Len( af )
               AAdd( aFiles, Iif( Empty( cSrcPath ), af[i,1], cSrcPath+hb_ps()+af[i,1] ) )
            NEXT
         ELSE
            c := Iif( !Empty( cSrcPath ) .AND. Empty( hb_fnameDir(c) ), cSrcPath + hb_ps() + c, c )
            IF Empty( hb_fnameExt(c) )
               IF File( c + ".hwg" )
                  c += ".hwg"
               ELSEIF File( c + ".prg" )
                  c += ".prg"
               ELSE
                  _MsgStop( c, "Wrong option" )
                  RETURN Nil
               ENDIF
            ENDIF
            Aadd( aFiles, c )
         ENDIF
      ENDIF
   NEXT

#ifdef __CONSOLE
   IF Empty( aFiles )
      OutStd( "HwBuild - HwGUI Builder" )
      OutStd( hb_eol() + "Usage:" )
      OutStd( hb_eol() + "hwbuildc <files> [-bcc|-mingw|-comp=<compiler>] [-lib] [-clean]" )
      OutStd( hb_eol() + "  [-pf<options>]|-prgflags=<options][-cf<options>|-cflags=<options>]" )
      OutStd( hb_eol() + "   [-l<libraries>|-libs=<libraries>] [-sp<path>|-srcpath=<path>]" )
      OutStd( hb_eol() + "   [-op<path>|-outpath=<path>] [-on<name>|-outname=<name>]" )
      RETURN Nil
   ENDIF
#endif

   IF Empty( oComp )
      oComp := HCompiler():aList[1]
   ENDIF

   IF Empty( aFiles ) .OR. lGUI
#ifndef __CONSOLE
      IF Empty( aFiles ) .OR. Lower( hb_fnameExt( aFiles[1] ) ) == ".hwg"
         StartGUI( Iif( Empty( aFiles ), Nil, aFiles[1] ) )
      ENDIF
#endif
   ELSE
      IF !Empty( c := CheckOptions( oComp ) )
#ifdef __CONSOLE
         OutStd( hb_eol() + c )
         OutStd( hb_eol() + "Check your hwbuild.ini" )
         RETURN Nil
#else
         _MsgStop( c, "Warning" )
         FPaths()
#endif
      ENDIF
#ifndef __CONSOLE
      IF !Empty( c := CheckOptions( oComp ) )
         _MsgStop( c, "Wrong options" )
         RETURN Nil
      ENDIF
#endif
      IF Len( aFiles ) == 1 .AND. Lower( hb_fnameExt( aFiles[1] ) ) == ".hwg"
         IF !Empty( oPrg := HwProject():Open( aFiles[1], oComp ) )
            oPrg:Build( lClean )
         ENDIF
      ELSE
         oPrg := HwProject():New( aFiles, oComp, cLibsDop, cLibsPath, cFlagsPrg, cFlagsC, cOutPath, cOutName, cObjPath, lLib, .F. )
         oPrg:Build( lClean )
      ENDIF
   ENDIF

   RETURN Nil

#ifndef __CONSOLE
STATIC FUNCTION ShowResult( cOut )

   LOCAL oDlg, oFont := HFont():Add( "Georgia",0,20 ), oEdit, oBoard
   LOCAL aCorners := { 4,4,4,4 }
   LOCAL aStyles := { HStyle():New( { CLR_DGRAY2 }, 1, aCorners ), ;
      HStyle():New( { CLR_LGRAY1 }, 2, aCorners ), ;
      HStyle():New( { CLR_DGRAY3 }, 1, aCorners ) }
   LOCAL bFont := {|o,nKey|
      LOCAL oFontNew, nHeight
      HB_SYMBOL_UNUSED( o )
      nHeight := oEdit:oFont:height + Iif( nKey == VK_ADD, 2, -2 )
      oFontNew := HFont():Add( oEdit:oFont:name,, nHeight,, oEdit:oFont:Charset,,,,, .T. )
      oEdit:SetFont( oFontNew )
      RETURN .T.
   }

   INIT DIALOG oDlg TITLE "HwBuild" AT 0,0  SIZE 800,650 FONT oFont

   @ 0, 0 HCEDIT oEdit SIZE 800, 600 FONT oFont ON SIZE {|o,x,y|o:Move( ,, x, y-50 ) }
   IF hwg__isUnicode()
      oEdit:lUtf8 := .T.
   ENDIF
   oEdit:SetWrap( .T. )
   oEdit:SetText( cOut )

   @ 0, 600 BOARD oBoard SIZE oDlg:nWidth, 50 FONT oFontMain BACKCOLOR CLR_DGRAY1 ;
      ON SIZE {|o,x,y|o:Move( ,y-50, x, )}

   @ 100, 10 DRAWN SIZE 80, 30 COLOR CLR_WHITE HSTYLES aStyles TEXT 'Close' ON CLICK {||oDlg:Close()}
   @ 680, 10 DRAWN SIZE 80, 30 COLOR CLR_WHITE HSTYLES aStyles TEXT 'Save' ON CLICK {||hb_MemoWrit("hwbuild.log",cOut)}
   ATail(oBoard:aDrawn):Anchor := ANCHOR_RIGHTABS

   hwg_SetDlgKey( oDlg, FCONTROL, VK_ADD, bFont )
   hwg_SetDlgKey( oDlg, FCONTROL, VK_SUBTRACT, bFont )

   ACTIVATE DIALOG oDlg CENTER
   oFont:Release()

   RETURN Nil

STATIC FUNCTION StartGUI( cFile )

   LOCAL oMain, oEdit
   LOCAL bFont := {|o,nKey|
      LOCAL oFontNew, nHeight
      HB_SYMBOL_UNUSED( o )
      nHeight := oEdit:oFont:height + Iif( nKey == VK_ADD, 2, -2 )
      oFontNew := HFont():Add( oEdit:oFont:name,, nHeight,, oEdit:oFont:Charset,,,,, .T. )
      oEdit:SetFont( oFontNew )
      RETURN .T.
   }

   INIT WINDOW oMain MAIN TITLE "HwBuild" AT 200, 100 SIZE 600,450 FONT oFontMain ;
      ON EXIT {||NewProject(),.T.}

   MENU OF oMain
      MENU TITLE "&File"
         MENUITEM "&New" ACTION NewProject()
         MENUITEM "&Open" ACTION OpenProject()
         MENUITEM "&Save" ACTION SaveProject()
         SEPARATOR
         MENUITEM "&Paths" ACTION FPaths()
         MENUITEM "&Exit" ACTION hwg_EndWindow()
      ENDMENU
      MENU TITLE "&Project"
         MENUITEM "&Run" ACTION RunProject( .F. )
         MENUITEM "&Clean" ACTION RunProject( .T. )
      ENDMENU
      MENU TITLE "&Help"
         MENUITEM "&About" ACTION hwg_MsgInfo( "HwGUI Builder " + HWB_VERSION + hb_eol() + ;
         "(C) Alexander S.Kresin, 2023" + hb_eol() + hb_eol() + hwg_Version(), "About" )
      ENDMENU
   ENDMENU

   @ 0, 0 HCEDIT oEdit SIZE oMain:nWidth, oMain:nHeight FONT oFontMain ON SIZE {|o,x,y|o:Move( ,, x, y ) }
   IF hwg__isUnicode()
      oEdit:lUtf8 := .T.
   ENDIF

   IF !Empty( cFile )
      OpenProject( cFile )
   ELSE
      NewProject()
   ENDIF

   hwg_SetDlgKey( oMain, FCONTROL, VK_ADD, bFont )
   hwg_SetDlgKey( oMain, FCONTROL, VK_SUBTRACT, bFont )

   ACTIVATE WINDOW oMain

   RETURN Nil

STATIC FUNCTION FPaths()

   LOCAL oDlg, oBoard, oEdi1, oEdi2, oEdi3, oEdi4, oEdi5, oEdi6, aEdi := Array( Len(HCompiler():aList), 2 )
   LOCAL oLenta, nTab := 1, aItems := { "Harbour", "HwGUI" }, aTabs := Array( Len(HCompiler():aList)+2 )
   LOCAL aCorners := { 4,4,4,4 }, y, i
   LOCAL aStyles := { HStyle():New( { CLR_DGRAY2 }, 1, aCorners ), ;
      HStyle():New( { CLR_LGRAY1 }, 2, aCorners ), ;
      HStyle():New( { CLR_DGRAY3 }, 1, aCorners ) }
   LOCAL aStyleLenta := { HStyle():New( { CLR_DGRAY2, CLR_DGRAY3 }, 1 ), ;
      HStyle():New( { CLR_DGRAY3 }, 1,, 1, CLR_WHITE ) }
   LOCAL bSave := {||
      LOCAL lUpd := .F.
      IF !( Trim(oEdi1:Value) == cPathHrb )
         cPathHrb := Trim(oEdi1:Value)
         lUpd := .T.
      ENDIF
      IF !( Trim(oEdi2:Value) == cPathHrbBin )
         cPathHrbBin := Trim(oEdi2:Value)
         lUpd := .T.
      ENDIF
      IF !( Trim(oEdi3:Value) == cPathHrbInc )
         cPathHrbInc := Trim(oEdi3:Value)
         lUpd := .T.
      ENDIF
      IF !( Trim(oEdi4:Value) == cPathHwgui )
         cPathHwgui := Trim(oEdi4:Value)
         lUpd := .T.
      ENDIF
      IF !( Trim(oEdi5:Value) == cPathHwguiLib )
         cPathHwgui := Trim(oEdi5:Value)
         lUpd := .T.
      ENDIF
      IF !( Trim(oEdi6:Value) == cPathHwguiInc )
         cPathHwguiInc := Trim(oEdi6:Value)
         lUpd := .T.
      ENDIF

      FOR i := 1 TO Len( HCompiler():aList )
#ifndef __PLATFORM__UNIX
         IF !( Trim(aEdi[i,1]:Value) == HCompiler():aList[i]:cPath )
            HCompiler():aList[i]:cPath := Trim(aEdi[i,1]:Value)
            lUpd := .T.
         ENDIF
#endif
         IF !( Trim(aEdi[i,2]:Value) == HCompiler():aList[i]:cPathHrbLib )
            HCompiler():aList[i]:cPathHrbLib := Trim(aEdi[i,2]:Value)
            lUpd := .T.
         ENDIF
      NEXT

      IF lUpd .OR. IsIniDataChanged()
         WriteIni()
      ENDIF
      oDlg:Close()
      RETURN Nil
   }
   LOCAL bSele := {|o|
      LOCAL cRes
      IF ( cRes := hwg_SelectFolder() ) != Nil
         o:cargo:SetText( cRes )
      ENDIF
      RETURN Nil
   }
   LOCAL bTab := { |o|
      IF nTab != o:Value
         aTabs[nTab]:lDisable := .T.
         //aTabs[nTab]:Refresh()
         nTab := o:Value
         aTabs[nTab]:lDisable := .F.
         aTabs[nTab]:Refresh()
      ENDIF
      RETURN .T.
   }

   INIT DIALOG oDlg TITLE "Paths" AT 0, 0 SIZE 640, 360

   @ 0, 0 BOARD oBoard SIZE oDlg:nWidth, oDlg:nHeight FONT oFontMain BACKCOLOR CLR_DGRAY1 ;
      ON SIZE {|o,x,y|o:Move( ,, x, y )}

   FOR i := 1 TO Len( HCompiler():aList )
      AAdd( aItems, HCompiler():aList[i]:id )
   NEXT
   @ 30, 16 DRAWN LENTA oLenta SIZE 580, 28 FONT oFontMain COLOR CLR_WHITE ;
      ITEMS aItems ITEMSIZE 100 HSTYLES aStyleLenta ON CLICK bTab
    oLenta:Value := nTab

   y := 60
   @ 20, y DRAWN aTabs[1] SIZE 600, 200  COLOR CLR_WHITE BACKCOLOR CLR_DGRAYA

   @ 20, y DRAWN aTabs[2] SIZE 600, 200  COLOR CLR_WHITE BACKCOLOR CLR_DGRAYA
   aTabs[2]:lDisable := .T.

   FOR i := 1 TO Len( HCompiler():aList )
      @ 20, y DRAWN aTabs[i+2] SIZE 560, 190  COLOR CLR_WHITE BACKCOLOR CLR_DGRAYA
      aTabs[i+2]:lDisable := .T.
   NEXT

   y := 70
   @ 32, y DRAWN OF aTabs[1] SIZE 300, 28 COLOR CLR_WHITE TEXT "Harbour path:"
   ATail(aTabs[1]:aDrawn):nTextStyle := DT_LEFT
   @ 40, y+28 DRAWN EDIT oEdi1 CAPTION cPathHrb OF aTabs[1] SIZE 500, 28
   @ 540, y+28 DRAWN OF aTabs[1] SIZE 40, 28 COLOR CLR_WHITE HSTYLES aStyles TEXT '..' ON CLICK bSele
   ATail(aTabs[1]:aDrawn):cargo := oEdi1

   y += 56
   @ 32, y DRAWN OF aTabs[1] SIZE 300, 28 COLOR CLR_WHITE TEXT "Harbour executables path:"
   ATail(aTabs[1]:aDrawn):nTextStyle := DT_LEFT
   @ 40,y+28 DRAWN EDIT oEdi2 CAPTION cPathHrbBin OF aTabs[1] SIZE 500, 28
   @ 540,y+28 DRAWN OF aTabs[1] SIZE 40, 28 COLOR CLR_WHITE HSTYLES aStyles TEXT '..' ON CLICK bSele
   ATail(aTabs[1]:aDrawn):cargo := oEdi2

   y += 56
   @ 32,y DRAWN OF aTabs[1] SIZE 300, 26 COLOR CLR_WHITE TEXT "Harbour include path:"
   ATail(aTabs[1]:aDrawn):nTextStyle := DT_LEFT
   @ 40,y+28 DRAWN EDIT oEdi3 CAPTION cPathHrbInc OF aTabs[1] SIZE 500, 28
   @ 540,y+28 DRAWN OF aTabs[1] SIZE 40, 28 COLOR CLR_WHITE HSTYLES aStyles TEXT '..' ON CLICK bSele
   ATail(aTabs[1]:aDrawn):cargo := oEdi3


   y := 70
   @ 32,y DRAWN OF aTabs[2] SIZE 300, 26 COLOR CLR_WHITE TEXT "HwGUI path:"
   ATail(aTabs[2]:aDrawn):nTextStyle := DT_LEFT
   @ 40,y+28 DRAWN EDIT oEdi4 CAPTION cPathHwgui OF aTabs[2] SIZE 500, 28
   @ 540,y+28 DRAWN OF aTabs[2] SIZE 40, 28 COLOR CLR_WHITE HSTYLES aStyles TEXT '..' ON CLICK bSele
   ATail(aTabs[2]:aDrawn):cargo := oEdi4

   y += 56
   @ 32,y DRAWN OF aTabs[2] SIZE 300, 26 COLOR CLR_WHITE TEXT "HwGUI libraries path:"
   ATail(aTabs[2]:aDrawn):nTextStyle := DT_LEFT
   @ 40,y+28 DRAWN EDIT oEdi5 CAPTION cPathHwguiLib OF aTabs[2] SIZE 500, 28
   @ 540,y+28 DRAWN OF aTabs[2] SIZE 40, 28 COLOR CLR_WHITE HSTYLES aStyles TEXT '..' ON CLICK bSele
   ATail(aTabs[2]:aDrawn):cargo := oEdi5

   y += 56
   @ 32,y DRAWN OF aTabs[2] SIZE 300, 26 COLOR CLR_WHITE TEXT "HwGUI include path:"
   ATail(aTabs[2]:aDrawn):nTextStyle := DT_LEFT
   @ 40,y+28 DRAWN EDIT oEdi6 CAPTION cPathHwguiInc OF aTabs[2] SIZE 500, 28
   @ 540,y+28 DRAWN OF aTabs[2] SIZE 40, 28 COLOR CLR_WHITE HSTYLES aStyles TEXT '..' ON CLICK bSele
   ATail(aTabs[2]:aDrawn):cargo := oEdi6

   FOR i := 1 TO Len( HCompiler():aList )
      y := 70
#ifndef __PLATFORM__UNIX
      @ 32,y DRAWN OF aTabs[i+2] SIZE 300, 26 COLOR CLR_WHITE TEXT HCompiler():aList[i]:id + " binaries path:"
      ATail(aTabs[i+2]:aDrawn):nTextStyle := DT_LEFT
      @ 40,y+28 DRAWN EDIT aEdi[i,1] CAPTION HCompiler():aList[i]:cPath OF aTabs[i+2] SIZE 500, 28
      @ 540,y+28 DRAWN OF aTabs[i+2] SIZE 40, 28 COLOR CLR_WHITE HSTYLES aStyles TEXT '..' ON CLICK bSele
      ATail(aTabs[i+2]:aDrawn):cargo := aEdi[i,1]
#endif
      y += 56
      @ 32,y DRAWN OF aTabs[i+2] SIZE 300, 26 COLOR CLR_WHITE TEXT "Path to Harbour " + HCompiler():aList[i]:id + " libraries:"
      ATail(aTabs[i+2]:aDrawn):nTextStyle := DT_LEFT
      @ 40,y+28 DRAWN EDIT aEdi[i,2] CAPTION HCompiler():aList[i]:cPathHrbLib OF aTabs[i+2] SIZE 500, 28
      @ 540,y+28 DRAWN OF aTabs[i+2] SIZE 40, 28 COLOR CLR_WHITE HSTYLES aStyles TEXT '..' ON CLICK bSele
      ATail(aTabs[i+2]:aDrawn):cargo := aEdi[i,2]
   NEXT

   @ 100, 300 DRAWN SIZE 100, 32 COLOR CLR_WHITE HSTYLES aStyles TEXT 'Save' ON CLICK bSave
   @ 400, 300 DRAWN SIZE 100, 32 COLOR CLR_WHITE HSTYLES aStyles TEXT 'Close' ON CLICK {||oDlg:Close()}

   ACTIVATE DIALOG oDlg CENTER

   RETURN Nil

STATIC FUNCTION NewProject()

   LOCAL oMain := HWindow():GetMain(), cFullPath, cFile := "template.hwg"

   IF oMain:oEdit:lUpdated .AND. hwg_MsgYesNo( "Project was changed. Save it?", "HwBuild" )
      SaveProject()
   ENDIF

#ifdef __PLATFORM__UNIX
   IF File( cFullPath := ( getenv("HOME") + "/hwbuild/" + cFile ) ) .OR. ;
      File( cFullPath := ( hb_DirBase() + cFile ) )
#else
   IF File( cFullPath := ( hb_DirBase() + cFile ) )
#endif
      oMain:oEdit:SetText( Memoread( cFullPath ) )
   ELSE
      oMain:oEdit:SetText( "" )
   ENDIF

   oPrg := Nil

   RETURN Nil

STATIC FUNCTION OpenProject( cFile )

   LOCAL oMain := HWindow():GetMain()

   IF oMain:oEdit:lUpdated .AND. hwg_MsgYesNo( "Project was changed. Save it?", "HwBuild" )
      SaveProject()
   ENDIF
   IF Empty( cFile )
      cFile := hwg_Selectfile( { "Hwbuild project (*.hwg)" }, { "*.hwg" }, Curdir() )
   ENDIF
   IF Empty( cFile )
      RETURN Nil
   ENDIF

   oMain:oEdit:Open( cFile )
   oMain:SetTitle( "HwBuild: " + hb_fnameName( cFile ) )

   oPrg := HwProject():Open( cFile )

   RETURN Nil

STATIC FUNCTION SaveProject()

   LOCAL oMain := HWindow():GetMain()

   IF oMain:oEdit:lUpdated
      IF Empty( oMain:oEdit:cFileName )
#ifdef __PLATFORM__UNIX
         oMain:oEdit:cFileName := hwg_Selectfile( "( *.hwg )", "*.hwg" )
#else
         oMain:oEdit:cFileName := hwg_SaveFile( "*.hwg", "( *.hwg )", "*.hwg" )
#endif
         IF Empty( oMain:oEdit:cFileName )
            RETURN Nil
         ENDIF
         oMain:oEdit:cFileName := hb_fnameExtSet( oMain:oEdit:cFileName, "hwg" )
      ENDIF
      oMain:oEdit:Save( oMain:oEdit:cFileName )
      oMain:oEdit:lUpdated := .F.
   ENDIF
   RETURN Nil

STATIC FUNCTION RunProject( lClean )

   LOCAL oMain := HWindow():GetMain()

   IF !Empty( oPrg := HwProject():Open( oMain:oEdit:GetText() ) )
      oPrg:Build( lClean )
   ENDIF

   RETURN Nil

#else

STATIC FUNCTION ShowResult()
   RETURN Nil

#endif

STATIC FUNCTION CheckOptions( oComp )

   LOCAL nDef

   IF Empty( cPathHrbBin ) .OR. !File( cPathHrbBin + hb_ps() + "harbour" + cExeExt )
      RETURN "Empty or wrong harbour executables path"
   ENDIF
   IF Empty( cPathHrbInc ) .OR. !File( cPathHrbInc + hb_ps() + "hbsetup.ch" )
      RETURN "Empty or wrong harbour include path"
   ENDIF
   IF Empty( cPathHwguiInc ) .OR. !File( cPathHwguiInc + hb_ps() + "hwgui.ch" )
      RETURN "Empty or wrong hwgui include path"
   ENDIF

   IF ( nDef := Ascan( HCompiler():aDef, {|a|a[COMP_ID] == oComp:id} ) ) > 0
      IF Empty( cPathHwguiLib ) .OR. !File( cPathHwguiLib + hb_ps() + HCompiler():aDef[nDef,COMP_HWG] )
         RETURN "Empty or wrong hwgui libraries path"
      ENDIF
#ifndef __PLATFORM__UNIX
      IF Empty( oComp:cPath ) .OR. !File( oComp:cPath + hb_ps() + HCompiler():aDef[nDef,COMP_EXE] )
         RETURN "Empty or wrong " + oComp:id + " path"
      ENDIF
#endif
      IF Empty( oComp:cPathHrbLib ) .OR. !File( oComp:cPathHrbLib + hb_ps() + HCompiler():aDef[nDef,COMP_HVM] )
         RETURN "Empty or wrong " + oComp:id + " harbour libraries path"
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION ReadIni( cFile )

   LOCAL cPath, hIni, aIni, arr, nSect, aSect, cTmp, i, j, key, nPos, cFam, oComp
   LOCAL aEnv, aMsvc := Array(4), aEnvM

#ifdef __PLATFORM__UNIX
   IF File( cPath := ( _CurrPath() + cFile ) ) .OR. ;
      File( cPath := ( getenv("HOME") + "/hwbuild/" + cFile ) ) .OR. ;
      File( cPath := ( hb_DirBase() + cFile ) )
#else
   IF File( cPath := ( _CurrPath() + cFile ) ) .OR. ;
      File( cPath := ( hb_DirBase() + cFile ) )
#endif
      cIniPath := cPath
      hIni := _IniRead( cPath )
#ifdef __CONSOLE
      OutStd( hb_eol() + "Read options from " + cPath + hb_eol() )
#endif
   ENDIF

   IF !Empty( hIni )
      hb_hCaseMatch( hIni, .F. )
      IF hb_hHaskey( hIni, cTmp := "HARBOUR" ) .AND. !Empty( aSect := hIni[ cTmp ] )
         hb_hCaseMatch( aSect, .F. )
         IF hb_hHaskey( aSect, cTmp := "harbour_path" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
            cPathHrb := cTmp
            lPathHrb := .T.
         ENDIF
         IF hb_hHaskey( aSect, cTmp := "harbour_bin_path" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
            cPathHrbBin := cTmp
            lPathHrbBin := .T.
         ENDIF
         IF hb_hHaskey( aSect, cTmp := "harbour_include_path" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
            cPathHrbInc := cTmp
            lPathHrbInc := .T.
         ENDIF
         IF hb_hHaskey( aSect, cTmp := "def_flags" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
            cHrbDefFlags := cTmp
         ENDIF
      ENDIF
      IF Empty( cPathHrb ) .AND. Empty( cPathHrb := getenv("HB_PATH") ) .AND. Empty( cPathHrb := getenv("HB_ROOT") )
         cTmp := "harbour" + cExeExt
         aEnv := hb_ATokens( getenv("PATH"), hb_osPathListSeparator() )
         FOR EACH cPath IN aEnv
            IF File( cPath + hb_ps() + cTmp )
               cPathHrbBin := cPath
               EXIT
            ENDIF
         NEXT
         IF !Empty( cPathHrbBin )
            IF ( nPos := hb_At( "/bin", cPathHrbBin ) ) > 0
               cPathHrb := Left( cPathHrbBin, nPos-1 )
            ENDIF
         ENDIF
      ENDIF

      aIni := hb_hKeys( hIni )
      FOR nSect := 1 TO Len( aIni )
         IF aIni[nSect] == "HWGUI" .AND. !Empty( aSect := hIni[ aIni[nSect] ] )
            hb_hCaseMatch( aSect, .F. )
            IF hb_hHaskey( aSect, cTmp := "path" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
               cPathHwgui := cTmp
               lPathHwgui := .T.
            ENDIF
            IF hb_hHaskey( aSect, cTmp := "inc_path" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
               cPathHwguiInc := cTmp
            ENDIF
            IF hb_hHaskey( aSect, cTmp := "lib_path" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
               cPathHwguiLib := cTmp
            ENDIF

         ELSEIF Left( aIni[nSect], 11 ) == "C_COMPILER_" .AND. !Empty( aSect := hIni[ aIni[nSect] ] )
            hb_hCaseMatch( aSect, .F. )
            IF hb_hHaskey( aSect, cTmp := "id" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
               cFam := Iif( hb_hHaskey( aSect, cFam := "family" ) .AND. ;
                  !Empty( cFam := aSect[ cFam ] ), cFam, "" )
               oComp := HCompiler():New( cTmp, cFam )
               arr := hb_hKeys( aSect )
               FOR EACH key IN arr
                  IF key == "bin_path" .AND. !Empty( cTmp := aSect[ key ] )
                     oComp:cPath := cTmp
                     oComp:lPath := .T.
                  ELSEIF key == "harbour_lib_path" .AND. !Empty( cTmp := aSect[ key ] )
                     oComp:cPathHrbLib := cTmp
                     oComp:lPathHrbLib := .T.
                  ELSEIF key == "def_flags" .AND. !Empty( cTmp := aSect[ key ] )
                     oComp:cFlags := cTmp
                  ELSEIF Left(key,4) == "env_" .AND. !Empty( cTmp := aSect[ key ] )
                     IF ( nPos := At( '=', cTmp ) ) > 0
                        AAdd( oComp:aEnv, {Left( cTmp,nPos-1 ), Substr( cTmp,nPos+1 )} )
                     ENDIF
                  ENDIF
               NEXT
            ENDIF
         ELSEIF aIni[nSect] == "VIEW" .AND. !Empty( aSect := hIni[ aIni[nSect] ] )
            hb_hCaseMatch( aSect, .F. )
            IF hb_hHaskey( aSect, cTmp := "font" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
               cFontMain := cTmp
            ENDIF
         ENDIF
      NEXT
   ENDIF

   IF !Empty( cPathHrb )
      IF Empty( cPathHrbBin )
         cPathHrbBin := cPathHrb + hb_ps() + "bin"
      ENDIF
      IF Empty( cPathHrbInc )
         cPathHrbInc := cPathHrb + hb_ps() + "include"
#ifdef __PLATFORM__UNIX
         IF !hb_DirExists( cPathHrbInc ) .AND. cPathHrbBin == "/usr/local/bin"
            cPathHrbInc := "/usr/local/include/harbour"
         ENDIF
#endif
      ENDIF
   ENDIF

   IF !Empty( cPathHwgui )
      IF Empty( cPathHwguiInc )
         cPathHwguiInc := cPathHwgui + hb_ps() + "include"
      ENDIF
      IF Empty( cPathHwguiLib )
         cPathHwguiLib := cPathHwgui + hb_ps() + "lib"
      ENDIF
   ENDIF

#ifdef __PLATFORM__UNIX
   IF ( i := Ascan( HCompiler():aList, {|o|o:id == "gcc"} ) ) > 0
      oComp := HCompiler():aList[i]
   ELSE
      oComp := HCompiler():New( "gcc" )
   ENDIF
   IF !Empty( cPathHrb ) .AND. Empty( oComp:cPathHrbLib )
      oComp:cPathHrbLib := cPathHrb + "/lib/linux/gcc"
      IF !hb_DirExists( oComp:cPathHrbLib ) .AND. cPathHrbBin == "/usr/local/bin"
         oComp:cPathHrbLib := "/usr/local/lib/harbour"
      ENDIF
   ENDIF

#else
   IF Empty( HCompiler():aList )
      HCompiler():New( "bcc" )
      HCompiler():New( "mingw" )
   ENDIF
   FOR EACH oComp IN HCompiler():aList

      IF Empty( oComp:cPath ) .AND. ( i := Ascan( HCompiler():aDef, {|a|a[COMP_ID] == oComp:id} ) ) > 0
         IF Empty( aEnv )
            aEnv := hb_ATokens( getenv("PATH"), hb_osPathListSeparator() )
         ENDIF
         IF oComp:id == "bcc" .OR. oComp:id == "mingw"
            FOR EACH cPath IN aEnv
               IF File( cPath + hb_ps() + HCompiler():aDef[i,COMP_EXE] )
                  oComp:cPath := cPath
                  EXIT
               ENDIF
            NEXT
         ELSEIF oComp:id == "msvc"
            IF Empty( oComp:aEnv )
               IF !Empty( aMsvc[4] := getenv( "LIBPATH" ) ) .AND. "Microsoft" $ aMsvc[4] .AND. ;
                  !Empty( aMsvc[3] := getenv( "LIB" ) ) .AND. !Empty( aMsvc[2] := getenv( "INCLUDE" ) ) ;
                  .AND. !Empty( aMsvc[1] := getenv( "PATH" ) )
                  aEnvM := hb_ATokens( aMsvc[1], hb_osPathListSeparator() )
                  FOR EACH cPath IN aEnv
                     IF File( cPath + hb_ps() + HCompiler():aDef[i,COMP_EXE] )
                        oComp:cPath := cPath
                        EXIT
                     ENDIF
                  NEXT
                  IF !Empty( oComp:cPath )
                     AAdd( oComp:aEnv, { "PATH",aMsvc[1] } )
                     AAdd( oComp:aEnv, { "INCLUDE", aMsvc[2] } )
                     AAdd( oComp:aEnv, { "LIB", aMsvc[3] } )
                     AAdd( oComp:aEnv, { "LIBPATH", aMsvc[4] } )
                  ENDIF
               ENDIF
            ENDIF
         ENDIF
      ENDIF
   NEXT
#endif
#ifndef __CONSOLE
   IF Empty( cFontMain )
      oFontMain := HFont():Add( "Georgia", 0, 24,, 204 )
      cFontMain := oFontMain:SaveToStr()
   ELSE
      oFontMain := HFont():LoadFromStr( cFontMain )
   ENDIF
#endif

   IF IsIniDataChanged()
#ifdef __CONSOLE
      OutStd( hb_eol() + "Update options in " + cPath + hb_eol() )
#endif
      WriteIni()
   ENDIF

   RETURN Nil

STATIC FUNCTION WriteIni()

   LOCAL cr := hb_eol(), oComp, n := 0, n1, aEnv
   LOCAL s := "[HARBOUR]" + cr + "harbour_path=" + cPathHrb + cr + "harbour_bin_path=" + ;
      cPathHrbBin + cr + "harbour_include_path=" + cPathHrbInc + cr + "def_flags=" + cHrbDefFlags + ;
      cr + cr + "[HWGUI]" + cr + "path=" + cPathHwgui + cr + "inc_path=" + cPathHwguiInc + cr + ;
      "lib_path=" + cPathHwguiLib + cr + cr

   FOR EACH oComp IN HCompiler():aList
      n ++
      s += "[C_COMPILER_" + Ltrim(Str(n)) + "]" + cr + "id=" + oComp:id + cr + "bin_path=" + ;
         oComp:cPath + cr + "harbour_lib_path=" + oComp:cPathHrbLib + cr + "def_flags=" + oComp:cFlags + cr
      n1 := 0
      FOR EACH aEnv in oComp:aEnv
         s += "env_" + Ltrim(Str(++n1)) + "=" + aEnv[1] + "=" + aEnv[2] + cr
      NEXT
      s += cr
   NEXT

   s += "[VIEW]" + cr + "font=" + cFontMain + cr + cr

   hb_MemoWrit( cIniPath, s )

   RETURN Nil

STATIC FUNCTION IsIniDataChanged()

   LOCAL oComp

   IF !lPathHrb .AND. !Empty(cPathHrb)
      RETURN ( lPathHrb := .T. )
   ENDIF
   IF !lPathHrbBin .AND. !Empty(cPathHrbBin)
      RETURN ( lPathHrbBin := .T. )
   ENDIF
   IF !lPathHrbInc .AND. !Empty(cPathHrbInc)
      RETURN ( lPathHrbInc := .T. )
   ENDIF
   IF !lPathHwgui .AND. !Empty(cPathHwgui)
      RETURN ( lPathHwgui := .T. )
   ENDIF

   FOR EACH oComp IN HCompiler():aList
      IF !oComp:lPath .AND. !Empty( oComp:cPath )
         RETURN ( oComp:lPath := .T. )
      ENDIF
      IF !oComp:lPathHrbLib .AND. !Empty( oComp:cPathHrbLib )
         RETURN ( oComp:lPathHrbLib := .T. )
      ENDIF
   NEXT

   RETURN .F.

STATIC FUNCTION _DropQuotes( cLine )

   IF Left( cLine, 1 ) == '"' .AND. Right( cLine, 1 ) == '"'
      RETURN Substr( cLine, 2, Len( cLine ) - 2 )
   ENDIF

   RETURN cLine

#ifdef __PLATFORM__UNIX
STATIC FUNCTION _RunApp( cLine, cOut )
   RETURN hwg_RunConsoleApp( cLine + " 2>&1",, @cOut )
#else
STATIC FUNCTION _RunApp( cLine, cOut )
   RETURN hwg_RunConsoleApp( cLine,, @cOut )
#endif

STATIC FUNCTION _ShowProgress( cText, nAct, cTitle )

#ifdef __CONSOLE
   IF !Empty( cTitle )
      OutStd( "*** " + cTitle + " *** " + hb_eol() )
   ENDIF
   IF nAct == 2
      OutStd( "*** " + cText + " *** " + hb_eol() )
   ELSE
      OutStd( cText + hb_eol() )
   ENDIF
#else
   STATIC oBar

   IF nAct == 0
      IF !Empty( oBar )
         oBar:Close()
         oBar := Nil
      ENDIF
      oBar := HProgressBar():NewBox( Iif( Empty(cTitle),"Building ...",cTitle ),,,,, 10,10 )
      hwg_Sleep( 1 )
      hwg_ProcessMessage()
      hb_gcStep()
   ELSEIF nAct == 1
      IF !Empty( oBar ) .AND. !Empty( cTitle )
         oBar:Set( cTitle )
         oBar:Step()
         hwg_Sleep( 1 )
         hwg_ProcessMessage()
         hb_gcStep()
      ENDIF
   ELSEIF nAct == 2
      IF !Empty( oBar )
         oBar:Close()
         oBar := Nil
      ENDIF
   ENDIF
#endif

   RETURN Nil

STATIC FUNCTION _MsgStop( cText, cTitle )

#ifdef __CONSOLE
   IF !Empty( cTitle )
      OutStd( hb_eol() + cTitle )
   ENDIF
   OutStd( hb_eol() + cText )
#else
   hwg_MsgStop( cText, Iif( Empty(cTitle), "HwBuild", cTitle ) )
#endif
   RETURN Nil

STATIC FUNCTION _MsgInfo( cText, cTitle )

#ifdef __CONSOLE
   IF !Empty( cTitle )
      OutStd( hb_eol() + cTitle )
   ENDIF
   OutStd( hb_eol() + cText )
#else
   hwg_MsgInfo( cText, Iif( Empty(cTitle), "HwBuild", cTitle ) )
#endif
   RETURN Nil

STATIC FUNCTION _CurrPath()

   LOCAL cPrefix

#ifdef __PLATFORM__UNIX
   cPrefix := '/'
#else
   cPrefix := hb_curDrive() + ':\'
#endif

   RETURN cPrefix + CurDir() + hb_ps()

STATIC FUNCTION _IniRead( cFileName )

   LOCAL cText := Memoread( cFileName ), aText, i, s, nPos
   LOCAL hIni, hSect

   IF Empty( cText )
      RETURN Nil
   ENDIF

   aText := hb_aTokens( cText, Chr(10) )
   hIni := hb_Hash()

   FOR i := 1 TO Len( aText )
      s := Iif( Left( aText[i],1 ) == ' ', Ltrim( aText[i] ), aText[i] )
      IF Left( s, 1 ) $ ";#"
         LOOP
      ENDIF
      s := Trim( Iif( Right(s,1)==Chr(13), Left( s,Len(s)-1 ), s ) )
      IF Empty( s )
         LOOP
      ENDIF

      IF Left( s,1 ) == '[' .AND. Right( s,1 ) == ']'
         hSect := hIni[Substr( s,2,Len(s)-2 )] := hb_Hash()
      ELSEIF !( hSect == Nil )
         IF ( nPos := At( '=', s ) ) > 0
            hSect[Trim(Left(s,nPos-1))] := Ltrim( Substr( s,nPos+1 ) )
         ENDIF
      ENDIF
   NEXT

   RETURN hIni

CLASS HCompiler

   CLASS VAR aDef        SHARED INIT { ;
      {"bcc", "bcc32.exe", "\lib\win\bcc", "-c -d -w -O2", "-Gn -aa -Tpe", "hbvm.lib", "hwgui.lib", ;
         "{path}\bcc32.exe {f} -I{hi} -I{gi} -o{obj} {src}", ;
         "{path}\brc32 -r hwgui_xp -fohwgui_xp", ;
         "{path}\tlib {out} {objs}", ;
         "{path}\ilink32 {f} -L{hL} -L{gL} {dL} c0w32.obj {objs}, {out},, {libs}", ;
         "", "", "", "", "", "ws2_32.lib cw32.lib import32.lib iphlpapi.lib" }, ;
      {"mingw", "gcc.exe", "\lib\win\mingw", "-c -Wall", "-Wall -mwindows", "libhbvm.a", "libhwgui.a", ;
         "{path}\gcc {f} -I{hi} -I{gi} -o{obj} {src}", ;
         "{path}\windres hwgui_xp.rc hwgui_xp.o", "{path}\ar rc {out} {objs}", ;
         "{path}\gcc {f} -o{out} {objs} -L{hL} -L{gL} {dL} -Wl,--allow-multiple-definition -Wl,--start-group {libs} -Wl,--end-group", ;
         ".o", ".a", "-l{l}", "lib{l}.a", "", ;
         "-luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdiplus -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lws2_32 -lwsock32 -liphlpapi" }, ;
      {"msvc", "cl.exe", "\lib\win\msvc", "/TP /W3 /nologo /c", "-SUBSYSTEM:WINDOWS", "hbvm.lib", "hwgui.lib", ;
         "{path}\cl.exe {f} /I{hi} /I{gi} /Fo{obj} {src}", "", "{path}\lib /out:{out} {objs}", ;
         "{path}\link {f} /LIBPATH:{hL} /LIBPATH:{gL} {dL} {objs} {libs}", "", "", "", "", "", ;
         "user32.lib gdi32.lib comdlg32.lib shell32.lib comctl32.lib winspool.lib advapi32.lib winmm.lib ws2_32.lib iphlpapi.lib OleAut32.Lib Ole32.Lib" }, ;
      {"gcc", "gcc", "/lib/linux/gcc", "-c", "", "libhbvm.a", "libhwgui.a", ;
         "gcc {f} -I{hi} -I{gi} -o{obj} {src}", "", "ar rc {out} {objs}", ;
         "gcc {objs} -o{out} -L{hL} -L{gL} {dL} -Wl,--start-group {libs} -Wl,--end-group `pkg-config --libs gtk+-2.0`", ;
         ".o", ".a", "-l{l}", "lib{l}.a", "", "-lm -lz -lpcre -ldl" } }
   //,, hwgui_xp.res
   CLASS VAR aList       SHARED INIT {}

   DATA id
   DATA family           INIT ""
   DATA cPath            INIT ""
   DATA cPathInc         INIT ""
   DATA cPathLib         INIT ""
   DATA cPathHrbLib      INIT ""
   DATA cFlags           INIT ""
   DATA cLinkFlags       INIT ""
   DATA cObjExt          INIT ".obj"
   DATA cLibExt          INIT ".obj"
   DATA cSysLibs         INIT ""

   DATA cCmdComp         INIT ""
   DATA cCmdRes          INIT ""
   DATA cCmdLinkLib      INIT ""
   DATA cCmdLinkExe      INIT ""
   DATA cTmplLib         INIT "{l}.lib"
   DATA cBinLib          INIT "{l}.lib"
   DATA cBinExe          INIT "{e}.exe"

   DATA aEnv             INIT {}

   DATA lPath            INIT .F.
   DATA lPathHrbLib      INIT .F.

   METHOD New( id, cFam )

ENDCLASS

METHOD New( id, cFam ) CLASS HCompiler

   LOCAL nDef, cTmp

   ::id := id
   IF !Empty( cFam ) .AND. ( nDef := Ascan( HCompiler():aDef, {|a|a[COMP_ID] == cFam} ) ) > 0
      ::family := cFam
   ELSEIF ( nDef := Ascan( HCompiler():aDef, {|a|a[COMP_ID] == id} ) ) > 0
      ::family := id
   ENDIF
   IF nDef > 0
      ::cPathHrbLib := cPathHrb + HCompiler():aDef[nDef,COMP_LIBPATH]
      ::cFlags := HCompiler():aDef[nDef,COMP_FLAGS]
      ::cLinkFlags := HCompiler():aDef[nDef,COMP_LFLAGS]
      ::cCmdComp := HCompiler():aDef[nDef,COMP_CMD1]
      ::cCmdRes  := HCompiler():aDef[nDef,COMP_CMD2]
      ::cCmdLinkLib := HCompiler():aDef[nDef,COMP_CMDL]
      ::cCmdLinkExe := HCompiler():aDef[nDef,COMP_CMDE]
      ::cSysLibs := HCompiler():aDef[nDef,COMP_SYSLIBS]
      IF !Empty( cTmp := HCompiler():aDef[nDef,COMP_TMPLLIB] )
         ::cTmplLib  := cTmp
      ENDIF
      IF !Empty( cTmp := HCompiler():aDef[nDef,COMP_BINLIB] )
         ::cBinLib  := cTmp
      ENDIF
      IF !Empty( cTmp := HCompiler():aDef[nDef,COMP_BINEXE] )
         ::cBinExe  := cTmp
      ENDIF
      IF !Empty( cTmp := HCompiler():aDef[nDef,COMP_OBJEXT] )
         ::cObjExt  := cTmp
      ENDIF
      IF !Empty( cTmp := HCompiler():aDef[nDef,COMP_LIBEXT] )
         ::cLibExt  := cTmp
      ENDIF
   ENDIF

   AAdd( ::aList, Self )

   RETURN Self

CLASS HwProject

   DATA aFiles     INIT {}
   DATA oComp
   DATA cLibsDop   INIT ""
   DATA cLibsPath  INIT ""
   DATA cFlagsPrg  INIT ""
   DATA cFlagsC    INIT ""
   DATA cOutPath, cOutName, cObjPath
   DATA lLib       INIT .F.
   DATA lMake      INIT .F.

   DATA aProjects  INIT {}

   METHOD New( aFiles, nComp, cLibsDop, cLibsPath, cFlagsPrg, cFlagsC, ;
      cOutPath, cOutName, cObjPath, lLib, lMake )
   METHOD Open( cFile, nComp )
   METHOD Build( lClean )
ENDCLASS

METHOD New( aFiles, oComp, cLibsDop, cLibsPath, cFlagsPrg, cFlagsC, ;
      cOutPath, cOutName, cObjPath, lLib, lMake ) CLASS HwProject

   IF PCount() > 1
      ::aFiles := aFiles
      ::oComp := oComp
      ::cLibsDop := cLibsDop
      ::cLibsPath := Iif( Empty(cLibsPath), "", cLibsPath )
      ::cFlagsPrg := cFlagsPrg
      ::cFlagsC := cFlagsC
      ::cOutPath := cOutPath
      ::cOutName := cOutName
      ::cObjPath := cObjPath
      ::lLib := lLib
      ::lMake := lMake
   ENDIF

   RETURN Self

METHOD Open( xSource, oComp ) CLASS HwProject

   LOCAL arr, i, j, nPos, af, ap, o
   LOCAL cLine, cTmp, cSrcPath

   IF Valtype( xSource ) == "A"
      arr := xSource
   ELSEIF Chr(10) $ xSource
      arr := hb_Atokens( xSource, Chr(10) )
   ELSE
      arr := hb_Atokens( Memoread( xSource ), Chr(10) )
   ENDIF
   FOR i := 1 TO Len( arr )
      IF !Empty( cLine := AllTrim( StrTran( arr[i], Chr(13), "" ) ) ) .AND. !( Left( cLine, 1 ) == "#" )
         IF Left( cLine,1 ) == '{'
            IF ( nPos := At( "}", cLine ) ) > 0
               IF ( ( cTmp := Substr( cLine, 2, nPos-2 ) ) == "unix" .AND. !lUnix ) .OR. ;
                  ( cTmp == "win" .AND. lUnix )
                  LOOP
               ELSE
                  cLine := Substr( cLine, nPos + 1 )
               ENDIF
            ELSE
               _MsgStop( cLine, "Wrong option" )
               RETURN Nil
            ENDIF
         ENDIF
         IF ( nPos := At( "=", cLine ) ) > 0
            IF ( cTmp := Left( cLine, nPos-1 ) ) == "srcpath"
               cSrcPath := Substr( cLine, nPos + 1 )

            ELSEIF cTmp == "prgflags"
               ::cFlagsPrg := Substr( cLine, nPos + 1 )

            ELSEIF cTmp == "cflags"
               ::cFlagsC := Substr( cLine, nPos + 1 )

            ELSEIF cTmp == "libs"
               ::cLibsDop := Substr( cLine, nPos + 1 )

            ELSEIF cTmp == "libspath"
               ::cLibsPath := Substr( cLine, nPos + 1 )

            ELSEIF cTmp == "outpath"
               ::cOutPath := Substr( cLine, nPos + 1 )

            ELSEIF cTmp == "outname"
               ::cOutName := Substr( cLine, nPos + 1 )

            ELSEIF cTmp == "objpath"
               ::cObjPath := Substr( cLine, nPos + 1 )

            ELSEIF cTmp == "target"
               ::lLib := Substr( cLine, nPos + 1 ) == "lib"

            ELSEIF cTmp == "makemode"
               ::lMake := ( cTmp := Lower( Substr( cLine, nPos + 1 ) ) ) == "on" .OR. cTmp == "yes"

            ELSEIF cTmp == "c_compiler"
               //nComp := Iif( ( cTmp := Substr( cLine, nPos + 1 ) ) == "bcc", 1, Iif( cTmp == "mingw", 2, 0 ) )

            ELSE
               _MsgStop( cLine, "Wrong option" )
               RETURN Nil
            ENDIF

         ELSEIF Left( cLine,1 ) == ':'
            IF Left( cLine,8 ) == ':project'
               ap := {}
               DO WHILE ++i <= Len( arr ) .AND. !Left( Ltrim(arr[i]),8 ) == ':project'
                  AAdd( ap, arr[i] )
               ENDDO
               IF i < Len( arr )
                  i --
               ENDIF
               AAdd( ::aProjects, o := HwProject():Open( ap, oComp ) )
               IF o == Nil
                  RETURN Nil
               ENDIF
               IF Empty( o:cObjPath ) .AND. !Empty( ::cObjPath )
                  o:cObjPath := ::cObjPath
               ENDIF
               IF Empty( o:cOutPath ) .AND. !Empty( ::cOutPath )
                  o:cOutPath := ::cOutPath
               ENDIF
               IF Empty( o:lMake ) .AND. !Empty( ::lMake )
                  o:lMake := ::lMake
               ENDIF
            ELSE
               _MsgStop( cLine, "Wrong option" )
               RETURN Nil
            ENDIF

         ELSEIF ( cTmp := Lower(hb_fnameExt( cLine )) ) == ".prg" .OR. cTmp == ".c"
            IF '*' $ cLine
               af := hb_Directory( cSrcPath + hb_ps() + cLine )
               FOR j := 1 TO Len( af )
                  AAdd( ::aFiles, Iif( Empty( cSrcPath ), af[j,1], cSrcPath+hb_ps()+af[j,1] ) )
               NEXT
            ELSE
               AAdd( ::aFiles, Iif( Empty( cSrcPath ) .AND. Empty( hb_fnameDir(cLine) ), ;
                  cLine, cSrcPath+hb_ps()+cLine ) )
            ENDIF

         ELSE
            _MsgStop( cLine, "Wrong option" )
            RETURN Nil
         ENDIF
      ENDIF
   NEXT

   //_MsgStop( hb_valtoexp(Self) )
   IF Empty( ::aFiles ) .AND. Empty( ::aProjects )
      _MsgStop( "Source files missing", "Project error" )
      RETURN Nil
   ENDIF

   IF Empty( oComp )
      oComp := HCompiler():aList[1]
   ENDIF
   ::oComp := oComp

   RETURN Self

METHOD Build( lClean, lSub ) CLASS HwProject

   LOCAL i, cCmd, cComp, cLine, cOut, cFullOut := "", lErr := .F., to, tc
   LOCAL cObjs := "", cBinary, cObjFile, cObjPath
   LOCAL aLibs, cLibs := "", a4Delete := {}, tStart := hb_DtoT( Date(), Seconds()-1 )
   LOCAL aEnv

   FOR i := 1 TO Len( ::aProjects )
      cFullOut += ::aProjects[i]:Build( lClean, .T. )
   NEXT
   IF Empty( ::aFiles )
      IF !Empty( cFullOut )
         ShowResult( cFullOut )
      ENDIF
      RETURN Nil
   ENDIF

   IF !Empty( ::cObjPath )
      cObjPath := ::cObjPath + hb_ps() + ::oComp:id
      IF !hb_DirExists( cObjPath )
         hb_DirBuild( cObjPath )
      ENDIF
      cObjPath := cObjPath + hb_ps()
   ELSE
      cObjPath := ""
   ENDIF

   IF !Empty( lClean )
      FOR i := 1 TO Len( ::aFiles )
         IF Lower( hb_fnameExt( ::aFiles[i] )) == ".prg"
            FErase( cObjPath + hb_fnameName( ::aFiles[i] ) + ".c" )
         ENDIF
         FErase( cObjPath + hb_fnameName( ::aFiles[i] ) + ::oComp:cObjExt )
      NEXT
      cBinary := Iif( Empty( ::cOutName ), hb_fnameNameExt( ::aFiles[1] ), ::cOutName )
      IF ::lLib
         cBinary := Iif( Empty(::cOutPath), "", ::cOutPath+hb_ps() ) + StrTran( ::oComp:cBinLib, "{l}", cBinary )
      ELSE
         cBinary := Iif( Empty(::cOutPath), "", ::cOutPath+hb_ps() ) + hb_fnameExtSet( cBinary, cExeExt )
      ENDIF
      FErase( cBinary )
      _MsgInfo( "Cleaned" )
      RETURN Nil
   ENDIF

   _ShowProgress( "", 0 )

   // Compile prg sources with Harbour
   IF !Empty( ::oComp:aEnv )
      aEnv := Array( Len(::oComp:aEnv),2 )
      FOR i := 1 TO Len( ::oComp:aEnv )
         aEnv[i,1] := ::oComp:aEnv[i,1]
         aEnv[i,2] := getenv( aEnv[i,1] )
         hb_setenv( ::oComp:aEnv[i,1], ::oComp:aEnv[i,2] )
      NEXT
   ENDIF
   cCmd := cPathHrbBin + hb_ps() + "harbour " + cHrbDefFlags + " -i" + cPathHrbInc + " -i" + cPathHwguiInc + ;
      Iif( Empty( ::cFlagsPrg ), "", " " + ::cFlagsPrg ) + Iif( Empty( cObjPath ), "", " -o" + cObjPath )
   FOR i := 1 TO Len( ::aFiles )
      IF Lower( hb_fnameExt( ::aFiles[i] )) == ".prg"
         cObjFile := cObjPath + hb_fnameName( ::aFiles[i] ) + ".c"
         IF ::lMake .AND. File( cObjFile ) .AND. hb_vfTimeGet( cObjFile, @to ) .AND. ;
            hb_vfTimeGet( ::aFiles[i], @tc ) .AND. to >= tc
         ELSE
            cLine := cCmd + " " + ::aFiles[i]

            cFullOut += "> " + cLine + hb_eol()
            _ShowProgress( "> " + cLine, 1, hb_fnameNameExt(::aFiles[i]) )
            _RunApp( cLine, @cOut )
            IF Valtype( cOut ) != "C"
               EXIT
            ENDIF
            cFullOut += cOut + hb_eol()
            _ShowProgress( cOut, 1 )
            IF "Error" $ cOut
               lErr := .T.
               EXIT
            ENDIF

         ENDIF
         ::aFiles[i] := cObjFile
         IF !::lMake
            AAdd( a4Delete, ::aFiles[i] )
         ENDIF
      ENDIF
   NEXT

   IF !lErr
      // Compile C sources with C compiler
      cOut := Nil
      cCmd := StrTran( StrTran( StrTran( StrTran( ::oComp:cCmdComp, "{f}", ::oComp:cFlags + ;
         Iif( Empty( ::cFlagsC ), "", " " + ::cFlagsC ) ), "{hi}", cPathHrbInc ), ;
         "{gi}", cPathHwguiInc ), "{path}", ::oComp:cPath )

      FOR i := 1 TO Len( ::aFiles )
         IF Lower( hb_fnameExt( ::aFiles[i] )) == ".c"
            cObjFile := cObjPath + hb_fnameName( ::aFiles[i] ) + ::oComp:cObjExt
            IF ::lMake .AND. File( cObjFile ) .AND. hb_vfTimeGet( cObjFile, @to ) .AND. ;
               hb_vfTimeGet( ::aFiles[i], @tc ) .AND. to >= tc
            ELSE
               cLine := StrTran( StrTran( cCmd, "{obj}", cObjFile ), "{src}", ::aFiles[i] )

               _ShowProgress( "> " + cLine, 1, hb_fnameNameExt(::aFiles[i]) )
               cFullOut += "> " + cLine + hb_eol()
               _RunApp( cLine, @cOut )
               IF Valtype( cOut ) != "C"
                  EXIT
               ENDIF
               cFullOut += cOut + hb_eol()
               _ShowProgress( cOut, 1 )
               IF "Error" $ cOut
                  lErr := .T.
                  EXIT
               ENDIF

            ENDIF
            cObjs += " " + cObjFile
            IF !::lMake
               AAdd( a4Delete, cObjFile )
            ENDIF
         ENDIF
      NEXT
   ENDIF

   IF !lErr
      // Link the app
      cBinary := Iif( Empty( ::cOutName ), hb_fnameNameExt( ::aFiles[1] ), ::cOutName )
      cOut := Nil
      aLibs := hb_ATokens( cLibsHwGUI, " " )
      FOR i := 1 TO Len( aLibs )
         cLibs += " " + StrTran( ::oComp:cTmplLib, "{l}", aLibs[i] )
      NEXT
      aLibs := hb_ATokens( cLibsHrb, " " )
      FOR i := 1 TO Len( aLibs )
         cLibs += " " + StrTran( ::oComp:cTmplLib, "{l}", aLibs[i] )
      NEXT
      IF !Empty( ::cLibsDop )
         aLibs := hb_ATokens( ::cLibsDop, Iif( ',' $ ::cLibsDop, ",", " " ) )
         FOR i := 1 TO Len( aLibs )
            cLibs += " " + StrTran( ::oComp:cTmplLib, "{l}", aLibs[i] )
         NEXT
      ENDIF
      IF ::lLib
         cBinary := Iif( Empty(::cOutPath), Iif(lUnix,"./",""), ::cOutPath+hb_ps() ) + StrTran( ::oComp:cBinLib, "{l}", cBinary )
         FErase( cBinary )
         cLine := StrTran( StrTran( StrTran( ::oComp:cCmdLinkLib, "{out}", cBinary ), ;
            "{objs}", Iif( ::oComp:family == "bcc", StrTran( cObjs, " ", " +" ), cObjs ) ), ;
            "{path}", ::oComp:cPath )
      ELSE
         cBinary := Iif( Empty(::cOutPath), "", ::cOutPath+hb_ps() ) + hb_fnameExtSet( cBinary, cExeExt )
         IF !Empty( ::oComp:cCmdRes )
            cLine := '1 24 "' + cPathHwgui + '\image\WindowsXP.Manifest"'
            IF ::oComp:family == "mingw"
               cLine := Strtran( cLine, '\', '/' )
            ENDIF
            hb_MemoWrit( "hwgui_xp.rc", cLine )
            cLine := StrTran( ::oComp:cCmdRes, "{path}", ::oComp:cPath )
            _ShowProgress( "> " + cLine, 1 )
            _RunApp( cLine, @cOut )
            cFullOut += "> " + cLine + hb_eol() + cOut + hb_eol()
            _ShowProgress( cOut, 1 )
            AAdd( a4Delete, "hwgui_xp.rc" )
            AAdd( a4Delete, "hwgui_xp.res" )
         ENDIF
         cLine := StrTran( StrTran( StrTran( StrTran( StrTran( StrTran( StrTran( StrTran( ;
             ::oComp:cCmdLinkExe, "{out}", cBinary ), "{objs}", cObjs ), "{path}", ::oComp:cPath ), ;
             "{f}", ::oComp:cLinkFlags ), "{hL}", ::oComp:cPathHrbLib ), "{gL}", cPathHwguiLib ), ;
             "{dL}", Iif( Empty(::cLibsPath), "", Iif(::oComp:family=="msvc","/LIBPATH:","-L") + ::cLibsPath ) ), ;
             "{libs}", cLibs + " " + ::oComp:cSysLibs )
         IF ::oComp:family == "bcc"
            AAdd( a4Delete, hb_fnameExtSet( cBinary, "tds" ) )
            AAdd( a4Delete, hb_fnameExtSet( cBinary, "map" ) )
         ENDIF
      ENDIF

      _ShowProgress( "> " + cLine, 1, hb_fnameNameExt(cBinary) )
      cFullOut += "> " + cLine + hb_eol()
      FErase( cBinary )
      _RunApp( cLine, @cOut )
      IF Valtype( cOut ) == "C"
         cFullOut += cOut
         _ShowProgress( cOut, 1 )
      ENDIF

      cLine := Iif( File( cBinary ) .AND. hb_vfTimeGet( cBinary, @to ) .AND. to > tStart, ;
         cBinary + " " + "created successfully!", "Error. Can't create " + cBinary )
      cFullOut += cLine + hb_eol() + hb_eol()
      _ShowProgress( cLine, 2 )
   ELSE
      _ShowProgress( "Error...", 2 )
   ENDIF

   IF !Empty( aEnv )
      FOR i := 1 TO Len( aEnv )
         hb_setenv( aEnv[i,1], aEnv[i,2] )
      NEXT
   ENDIF

   IF Empty( lSub )
      ShowResult( cFullOut )
   ENDIF
   FOR i := 1 TO Len( a4Delete )
      FErase( a4Delete[i] )
   NEXT

   RETURN Iif( Empty( lSub ), Nil, cFullOut )
