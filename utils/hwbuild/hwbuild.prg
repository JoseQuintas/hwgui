/*
 * $Id$
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

#define MENU_RUN     1001
#define MENU_SAVE    1002

#define CLR_WHITE    0xffffff
#define CLR_BLACK    0
#define CLR_DBLUE    0x614834
#define CLR_DGRAY1   0x222222
#define CLR_DGRAY2   0x555555
#define CLR_DGRAY3   0x888888
#define CLR_LGRAY1   0xdddddd

STATIC cIniPath
STATIC oPrg
STATIC nCompDef := 0
 STATIC cPathHrb := "", cPathHrbBin := "", cPathHrbInc := ""
STATIC cPathHwgui := "", cPathHwguiInc := "", cPathHwguiLib := ""
STATIC cPathBcc := "", cPathMingw := "", cPathMingwLib := ""
STATIC cPathHrbLib_bcc := "", cPathHrbLib_mingw := "", cPathHrbLib_gcc := ""
STATIC lPathHrb := .F., lPathHrbBin := .F., lPathHrbInc := .F.
STATIC lPathHwgui := .F.
STATIC lPathBcc := .F., lPathMingw := .F., lPathMingwLib := .F.
STATIC lPathHrbLib_bcc := .F., lPathHrbLib_mingw := .F., lPathHrbLib_gcc := .F.

#ifdef __PLATFORM__UNIX
STATIC lUnix := .T.
STATIC cLibsHrb := "hbvm hbrtl gtcgi gttrm hbcpage hblang hbrdd hbmacro hbpp rddntx rddcdx rddfpt hbsix hbcommon hbct hbcplr hbpcre hbzlib"
#else
STATIC lUnix := .F.
STATIC cLibsHrb := "hbvm hbrtl gtgui gtwin hbcpage hblang hbrdd hbmacro hbpp rddntx rddcdx rddfpt hbsix hbcommon hbct hbcplr hbpcre hbzlib"
#endif
STATIC cLibsHwGUI := "hwgui hbxml procmisc"
STATIC cLibsBcc := "ws2_32.lib cw32.lib import32.lib iphlpapi.lib"
STATIC cLibsMingw := "-luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdiplus -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lws2_32 -lwsock32 -liphlpapi"
STATIC cLibsGtk := "-lm -lz -lpcre -ldl"

#ifndef __CONSOLE
STATIC oFontMain
#endif

FUNCTION Main( ... )

   LOCAL aParams := hb_aParams(), i, j, c, aFiles := {}, af
   LOCAL lGUI := .F., lLib := .F., nComp := 0, cLibsDop, cLibsPath
   LOCAL cSrcPath, cObjPath, cOutPath, cOutName, cFlagsPrg, cFlagsC

   FOR i := 1 TO Len( aParams )
      IF Left( aParams[i],1 ) == "-"
         IF ( c := Substr( aParams[i],2 ) ) == "bcc"
            nComp := 1

         ELSEIF c == "mingw"
            nComp := 2

         ELSEIF c == "gui"
            lGUI := .T.

         ELSEIF c == "lib"
            lLib := .T.

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
         ELSE
            _Msg( c, "Wrong option" )
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
                  _Msg( c, "Wrong option" )
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
      OutStd( hb_eol() + "hwbuildc <files> [-bcc|-mingw] [-lib] [-pf<options>]|-prgflags=<options]" )
      OutStd( hb_eol() + "  [-cf<options>|-cflags=<options>] [-l<libraries>|-libs=<libraries>]" )
      OutStd( hb_eol() + "  [-sp<path>|-srcpath=<path>] [-op<path>|-outpath=<path>] [-on<name>|-outname=<name>]" )
      RETURN Nil
   ENDIF
#endif

   ReadIni( "hwbuild.ini" )

#ifdef __PLATFORM__UNIX
   nComp := 99
#else
   IF nComp == 0
      nComp := Iif( nCompDef > 0, nCompDef, Iif( !Empty( cPathBcc ), 1, ;
         Iif( !Empty( cPathMingw ), 2, 0 ) ) )
   ENDIF
#endif

   IF Empty( aFiles ) .OR. lGUI
#ifndef __CONSOLE
      IF Empty( aFiles ) .OR. Lower( hb_fnameExt( aFiles[1] ) ) == ".hwg"
         StartGUI( Iif( Empty( aFiles ), Nil, aFiles[1] ) )
      ENDIF
#endif
   ELSE
      IF !Empty( c := CheckOptions( nComp ) )
#ifdef __CONSOLE
         OutStd( hb_eol() + c )
         OutStd( hb_eol() + "Check your hwbuild.ini" )
         RETURN Nil
#else
         FPaths( c )
#endif
      ENDIF
#ifndef __CONSOLE
      IF !Empty( c := CheckOptions( nComp ) )
         _Msg( c, "Wrong options" )
         RETURN Nil
      ENDIF
#endif
      IF Len( aFiles ) == 1 .AND. Lower( hb_fnameExt( aFiles[1] ) ) == ".hwg"
         IF !Empty( oPrg := HwProject():Open( aFiles[1], nComp ) )
            oPrg:Build()
         ENDIF
      ELSE
         oPrg := HwProject():New( aFiles, nComp, cLibsDop, cLibsPath, cFlagsPrg, cFlagsC, cOutPath, cOutName, cObjPath, lLib, .F. )
         oPrg:Build()
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
         MENUITEM "&Save" ID MENU_SAVE ACTION SaveProject()
         SEPARATOR
         MENUITEM "&Paths" ACTION FPaths()
         MENUITEM "&Exit" ACTION hwg_EndWindow()
      ENDMENU
      MENU TITLE "&Project"
         MENUITEM "&Run" ID MENU_RUN ACTION RunProject()
      ENDMENU
      MENU TITLE "&Help"
         MENUITEM "&About" ACTION hwg_MsgInfo( "HwGUI Builder " + HWB_VERSION + hb_eol() + ;
         "(C) Alexander S.Kresin, 2023" + hb_eol() + hb_eol() + hwg_Version(), "About" )
      ENDMENU
   ENDMENU

   @ 0, 0 HCEDIT oEdit SIZE oMain:nWidth, oMain:nHeight ON SIZE {|o,x,y|o:Move( ,, x, y ) }
   IF hwg__isUnicode()
      oEdit:lUtf8 := .T.
   ENDIF

   //hwg_Enablemenuitem( , MENU_RUN, .F. )
   hwg_Enablemenuitem( , MENU_SAVE, .F. )

   IF !Empty( cFile )
      OpenProject( cFile )
   ELSE
      NewProject()
   ENDIF

   hwg_SetDlgKey( oMain, FCONTROL, VK_ADD, bFont )
   hwg_SetDlgKey( oMain, FCONTROL, VK_SUBTRACT, bFont )

   ACTIVATE WINDOW oMain

   RETURN Nil

STATIC FUNCTION FPaths( cErr )

   LOCAL oDlg, oBoard, oEdi1, oEdi2, oEdi3, oEdi4, oEdi5, oEdi6, oEdi7, oEdi8, oEdi9, oEdi10
   LOCAL aCorners := { 4,4,4,4 }, y := 40
   LOCAL aStyles := { HStyle():New( { CLR_DGRAY2 }, 1, aCorners ), ;
      HStyle():New( { CLR_LGRAY1 }, 2, aCorners ), ;
      HStyle():New( { CLR_DGRAY3 }, 1, aCorners ) }
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
#ifdef __PLATFORM__UNIX
      IF !( Trim(oEdi7:Value) == cPathHrbLib_gcc )
         cPathHrbLib_gcc := Trim(oEdi7:Value)
         lUpd := .T.
      ENDIF
#else
      IF !( Trim(oEdi7:Value) == cPathBcc )
         cPathBcc := Trim(oEdi7:Value)
         lUpd := .T.
      ENDIF
      IF !( Trim(oEdi8:Value) == cPathHrbLib_bcc )
         cPathHrbLib_bcc := Trim(oEdi8:Value)
         lUpd := .T.
      ENDIF
      IF !( Trim(oEdi9:Value) == cPathMingw )
         cPathMingw := Trim(oEdi9:Value)
         lUpd := .T.
      ENDIF
      IF !( Trim(oEdi10:Value) == cPathHrbLib_mingw )
         cPathHrbLib_mingw := Trim(oEdi10:Value)
         lUpd := .T.
      ENDIF
#endif
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

   INIT DIALOG oDlg TITLE "Paths" AT 0, 0 SIZE 640, 680

   @ 0, 0 BOARD oBoard SIZE oDlg:nWidth, oDlg:nHeight FONT oFontMain BACKCOLOR CLR_DGRAY1 ;
      ON SIZE {|o,x,y|o:Move( ,, x, y )}

   IF !Empty( cErr )
      @ 20, 4 DRAWN SIZE 560, 26 COLOR CLR_WHITE TEXT cErr
   ENDIF

   @ 32, y DRAWN SIZE 300, 28 COLOR CLR_WHITE TEXT "Harbour path:"
   ATail(oBoard:aDrawn):nTextStyle := DT_LEFT
   @ 40, y+28 DRAWN EDIT oEdi1 CAPTION cPathHrb SIZE 500, 28
   @ 540, y+28 DRAWN SIZE 40, 28 COLOR CLR_WHITE HSTYLES aStyles TEXT '..' ON CLICK bSele
   ATail(oBoard:aDrawn):cargo := oEdi1

   y += 56
   @ 32, y DRAWN SIZE 300, 28 COLOR CLR_WHITE TEXT "Harbour executables path:"
   ATail(oBoard:aDrawn):nTextStyle := DT_LEFT
   @ 40,y+28 DRAWN EDIT oEdi2 CAPTION cPathHrbBin SIZE 500, 28
   @ 540,y+28 DRAWN SIZE 40, 28 COLOR CLR_WHITE HSTYLES aStyles TEXT '..' ON CLICK bSele
   ATail(oBoard:aDrawn):cargo := oEdi2

   y += 56
   @ 32,y DRAWN SIZE 300, 26 COLOR CLR_WHITE TEXT "Harbour include path:"
   ATail(oBoard:aDrawn):nTextStyle := DT_LEFT
   @ 40,y+28 DRAWN EDIT oEdi3 CAPTION cPathHrbInc SIZE 500, 28
   @ 540,y+28 DRAWN SIZE 40, 28 COLOR CLR_WHITE HSTYLES aStyles TEXT '..' ON CLICK bSele
   ATail(oBoard:aDrawn):cargo := oEdi3

   y += 60
   @ 32,y DRAWN SIZE 300, 26 COLOR CLR_WHITE TEXT "HwGUI path:"
   ATail(oBoard:aDrawn):nTextStyle := DT_LEFT
   @ 40,y+28 DRAWN EDIT oEdi4 CAPTION cPathHwgui SIZE 500, 28
   @ 540,y+28 DRAWN SIZE 40, 28 COLOR CLR_WHITE HSTYLES aStyles TEXT '..' ON CLICK bSele
   ATail(oBoard:aDrawn):cargo := oEdi4

   y += 56
   @ 32,y DRAWN SIZE 300, 26 COLOR CLR_WHITE TEXT "HwGUI libraries path:"
   ATail(oBoard:aDrawn):nTextStyle := DT_LEFT
   @ 40,y+28 DRAWN EDIT oEdi5 CAPTION cPathHwguiLib SIZE 500, 28
   @ 540,y+28 DRAWN SIZE 40, 28 COLOR CLR_WHITE HSTYLES aStyles TEXT '..' ON CLICK bSele
   ATail(oBoard:aDrawn):cargo := oEdi5

   y += 56
   @ 32,y DRAWN SIZE 300, 26 COLOR CLR_WHITE TEXT "HwGUI include path:"
   ATail(oBoard:aDrawn):nTextStyle := DT_LEFT
   @ 40,y+28 DRAWN EDIT oEdi6 CAPTION cPathHwguiInc SIZE 500, 28
   @ 540,y+28 DRAWN SIZE 40, 28 COLOR CLR_WHITE HSTYLES aStyles TEXT '..' ON CLICK bSele
   ATail(oBoard:aDrawn):cargo := oEdi6

   y += 60
#ifdef __PLATFORM__UNIX
   @ 32,y DRAWN SIZE 300, 26 COLOR CLR_WHITE TEXT "Path to Harbour gcc libraries:"
   ATail(oBoard:aDrawn):nTextStyle := DT_LEFT
   @ 40,y+28 DRAWN EDIT oEdi7 CAPTION cPathHrbLib_gcc SIZE 500, 28
   @ 540,y+28 DRAWN SIZE 40, 28 COLOR CLR_WHITE HSTYLES aStyles TEXT '..' ON CLICK bSele
   ATail(oBoard:aDrawn):cargo := oEdi7
#else
   @ 32,y DRAWN SIZE 300, 26 COLOR CLR_WHITE TEXT "Borland C path:"
   ATail(oBoard:aDrawn):nTextStyle := DT_LEFT
   @ 40,y+28 DRAWN EDIT oEdi7 CAPTION cPathBcc SIZE 500, 28
   @ 540,y+28 DRAWN SIZE 40, 28 COLOR CLR_WHITE HSTYLES aStyles TEXT '..' ON CLICK bSele
   ATail(oBoard:aDrawn):cargo := oEdi7

   y += 56
   @ 32,y DRAWN SIZE 300, 26 COLOR CLR_WHITE TEXT "Path to Harbour bcc libraries:"
   ATail(oBoard:aDrawn):nTextStyle := DT_LEFT
   @ 40,y+28 DRAWN EDIT oEdi8 CAPTION cPathHrbLib_bcc SIZE 500, 28
   @ 540,y+28 DRAWN SIZE 40, 28 COLOR CLR_WHITE HSTYLES aStyles TEXT '..' ON CLICK bSele
   ATail(oBoard:aDrawn):cargo := oEdi8

   y += 60
   @ 32,y DRAWN SIZE 300, 26 COLOR CLR_WHITE TEXT "Mingw C path:"
   ATail(oBoard:aDrawn):nTextStyle := DT_LEFT
   @ 40,y+28 DRAWN EDIT oEdi9 CAPTION cPathMingw SIZE 500, 28
   @ 540,y+28 DRAWN SIZE 40, 28 COLOR CLR_WHITE HSTYLES aStyles TEXT '..' ON CLICK bSele
   ATail(oBoard:aDrawn):cargo := oEdi9

   y += 56
   @ 32,y DRAWN SIZE 300, 26 COLOR CLR_WHITE TEXT "Path to Harbour mingw libraries:"
   ATail(oBoard:aDrawn):nTextStyle := DT_LEFT
   @ 40,y+28 DRAWN EDIT oEdi10 CAPTION cPathHrbLib_mingw SIZE 500, 28
   @ 540,y+28 DRAWN SIZE 40, 28 COLOR CLR_WHITE HSTYLES aStyles TEXT '..' ON CLICK bSele
   ATail(oBoard:aDrawn):cargo := oEdi10
#endif

   @ 100, 630 DRAWN SIZE 100, 32 COLOR CLR_WHITE HSTYLES aStyles TEXT 'Save' ON CLICK bSave
   @ 400, 630 DRAWN SIZE 100, 32 COLOR CLR_WHITE HSTYLES aStyles TEXT 'Close' ON CLICK {||oDlg:Close()}

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
   hwg_Enablemenuitem( , MENU_RUN, .F. )

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
   hwg_Enablemenuitem( , MENU_SAVE, .T. )

   IF !Empty( oPrg := HwProject():Open( cFile ) )
      hwg_Enablemenuitem( , MENU_RUN, .T. )
   ENDIF

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

STATIC FUNCTION RunProject()

   LOCAL oMain := HWindow():GetMain()

   IF !Empty( oPrg := HwProject():Open( oMain:oEdit:GetText() ) )
      oPrg:Build()
   ENDIF

   RETURN Nil

#else

STATIC FUNCTION ShowResult()
   RETURN Nil

#endif

STATIC FUNCTION IsIniDataChanged()

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
   IF !lPathHrbLib_gcc .AND. !Empty(cPathHrbLib_gcc)
      RETURN ( lPathHrbLib_gcc := .T. )
   ENDIF
    IF !lPathBcc .AND. !Empty(cPathBcc)
      RETURN ( lPathBcc := .T. )
   ENDIF
   IF !lPathHrbLib_bcc .AND. !Empty(cPathHrbLib_bcc)
      RETURN ( lPathHrbLib_bcc := .T. )
   ENDIF
   IF !lPathMingw .AND. !Empty(cPathMingw)
      RETURN ( lPathMingw := .T. )
   ENDIF
   IF !lPathHrbLib_mingw .AND. !Empty(cPathHrbLib_mingw)
      RETURN ( lPathHrbLib_mingw := .T. )
   ENDIF

   RETURN .F.

STATIC FUNCTION CheckOptions( nComp )

   IF Empty( cPathHrbBin ) .OR. !File( cPathHrbBin + hb_ps() + Iif( lUnix, "harbour", "harbour.exe" ) )
      RETURN "Empty or wrong harbour executables path"
   ENDIF
   IF Empty( cPathHrbInc ) .OR. !File( cPathHrbInc + hb_ps() + "hbsetup.ch" )
      RETURN "Empty or wrong harbour include path"
   ENDIF
   IF Empty( cPathHwguiInc ) .OR. !File( cPathHwguiInc + hb_ps() + "hwgui.ch" )
      RETURN "Empty or wrong hwgui include path"
   ENDIF
   IF Empty( cPathHwguiLib ) .OR. !File( cPathHwguiLib + hb_ps() + ;
      Iif( lUnix, "libhwgui.a", Iif( nComp==2, "libhwgui.a", "hwgui.lib" ) ) )
      RETURN "Empty or wrong hwgui libraries path"
   ENDIF
#ifdef __PLATFORM__UNIX
   IF Empty( cPathHrbLib_gcc ) .OR. !File( cPathHrbLib_gcc + "/libhbvm.a" )
      RETURN "Empty or wrong harbour libraries path"
   ENDIF
#else
   IF nComp == 1
      IF ( Empty( cPathBcc ) .OR. !File( cPathBcc + "\bin\bcc32.exe" ) )
         RETURN "Empty or wrong bcc path"
      ENDIF
      IF Empty( cPathHrbLib_bcc ) .OR. !File( cPathHrbLib_bcc + "\hbvm.lib" )
         RETURN "Empty or wrong harbour bcc libraries path"
      ENDIF
   ENDIF
   IF nComp == 2
      IF ( Empty( cPathMingw ) .OR. !File( cPathMingw + "\bin\gcc.exe" ) )
         RETURN "Empty or wrong mingw path"
      ENDIF
      IF Empty( cPathHrbLib_mingw ) .OR. !File( cPathHrbLib_mingw + "\libhbvm.a" )
         RETURN "Empty or wrong harbour mingw libraries path"
      ENDIF
   ENDIF
#endif
   RETURN Nil

STATIC FUNCTION ReadIni( cFile )

   LOCAL cFullPath, hIni, aIni, nSect, aSect, cTmp, i, nPos, cCompId

#ifdef __PLATFORM__UNIX
   IF File( cFullPath := ( _CurrPath() + cFile ) ) .OR. ;
      File( cFullPath := ( getenv("HOME") + "/hwbuild/" + cFile ) ) .OR. ;
      File( cFullPath := ( hb_DirBase() + cFile ) )
#else
   IF File( cFullPath := ( _CurrPath() + cFile ) ) .OR. ;
      File( cFullPath := ( hb_DirBase() + cFile ) )
#endif
      cIniPath := cFullPath
      hIni := _IniRead( cFullPath )
#ifdef __CONSOLE
      OutStd( hb_eol() + "Read option from " + cFullPath )
#endif
   ENDIF

   IF !Empty( hIni )
      hb_hCaseMatch( hIni, .F. )
      aIni := hb_hKeys( hIni )
      FOR nSect := 1 TO Len( aIni )
         IF Upper(aIni[nSect]) == "HARBOUR" .AND. !Empty( aSect := hIni[ aIni[nSect] ] )
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
            IF hb_hHaskey( aSect, cTmp := "def_c_compiler" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
               nCompDef := Iif( cTmp == "bcc", 1, Iif( cTmp == "mingw", 2, 0 ) )
            ENDIF
         ELSEIF Left( Upper(aIni[nSect]), 11 ) == "C_COMPILER_" .AND. !Empty( aSect := hIni[ aIni[nSect] ] )
            hb_hCaseMatch( aSect, .F. )
            IF hb_hHaskey( aSect, cTmp := "id" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
               cCompId := cTmp
            ENDIF
            IF hb_hHaskey( aSect, cTmp := "path" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
               IF cCompId == "bcc"
                  cPathBcc := cTmp
                  lPathBcc := .T.
               ELSEIF cCompId == "mingw"
                  cPathMingw := cTmp
                  lPathMingw := .T.
               ENDIF
            ENDIF
            IF hb_hHaskey( aSect, cTmp := "harbour_lib_path" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
               IF cCompId == "bcc"
                  cPathHrbLib_bcc := cTmp
                  lPathHrbLib_bcc := .T.
               ELSEIF cCompId == "mingw"
                  cPathHrbLib_mingw := cTmp
                  lPathHrbLib_mingw := .T.
               ELSEIF cCompId == "gcc"
                  cPathHrbLib_gcc := cTmp
                  lPathHrbLib_gcc := .T.
               ENDIF
            ENDIF
         ELSEIF Upper(aIni[nSect]) == "HWGUI" .AND. !Empty( aSect := hIni[ aIni[nSect] ] )
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
         ENDIF
      NEXT
   ENDIF

   aSect := Nil
   IF Empty( cPathHrb ) .AND. Empty( cPathHrb := getenv("HB_PATH") ) .AND. Empty( cPathHrb := getenv("HB_ROOT") )
#ifdef __PLATFORM__UNIX
      cTmp := "harbour"
#else
      cTmp := "harbour.exe"
#endif
      aSect := hb_ATokens( getenv("PATH"), hb_osPathListSeparator() )
      FOR i := 1 TO Len( aSect )
         IF File( aSect[i] + hb_ps() + cTmp )
            cPathHrbBin := aSect[i]
            EXIT
         ENDIF
      NEXT
      IF !Empty( cPathHrbBin )
         IF ( nPos := hb_At( "/bin", cPathHrbBin ) ) > 0
            cPathHrb := Left( cPathHrbBin, nPos-1 )
         ENDIF
      ENDIF
   ENDIF

#ifndef __PLATFORM__UNIX
   IF Empty( cPathBcc )
      IF Empty( aSect )
         aSect := hb_ATokens( getenv("PATH"), hb_osPathListSeparator() )
      ENDIF
      FOR i := 1 TO Len( aSect )
         IF File( aSect[i] + hb_ps() + "bcc32.exe" )
            IF ( nPos := hb_At( "\bin", aSect[i] ) ) > 0
               cPathBcc := Left( aSect[i], nPos-1 )
               EXIT
            ENDIF
         ENDIF
      NEXT
   ENDIF
   IF Empty( cPathMingw )
      IF Empty( aSect )
         aSect := hb_ATokens( getenv("PATH"), hb_osPathListSeparator() )
      ENDIF
      FOR i := 1 TO Len( aSect )
         IF File( aSect[i] + hb_ps() + "gcc.exe" )
            IF ( nPos := hb_At( "\bin", aSect[i] ) ) > 0
               cPathMingw := Left( aSect[i], nPos-1 )
               EXIT
            ENDIF
         ENDIF
      NEXT
   ENDIF
#endif

   IF !Empty( cPathHrb )
      IF Empty( cPathHrbBin )
         cPathHrbBin := cPathHrb + hb_ps() + "bin"
      ENDIF
      IF Empty( cPathHrbInc )
         cPathHrbInc := cPathHrb + hb_ps() + "include"
#ifdef __PLATFORM__UNIX
         IF !hb_DirExists( cPathHrbInc ) .AND. cPathHrbBin == "/usr/local/bin"
            cPathHrbInc := "/usr/local/include/harbour"
            IF Empty( cPathHrbLib_gcc )
               cPathHrbLib_gcc := "/usr/local/lib/harbour"
            ENDIF
         ENDIF
#endif
      ENDIF
#ifdef __PLATFORM__UNIX
      IF Empty( cPathHrbLib_gcc )
         cPathHrbLib_gcc := cPathHrb + '/lib/linux/gcc'
      ENDIF
#else
      IF !Empty( cPathBcc )
         IF Empty( cPathHrbLib_bcc )
            cPathHrbLib_bcc := cPathHrb + "\lib\win\bcc"
         ENDIF
      ENDIF
      IF !Empty( cPathMingw )
         cPathMingwLib := cPathMingw + hb_ps() + "lib"
         IF Empty( cPathHrbLib_mingw )
            cPathHrbLib_mingw := cPathHrb + "\lib\win\mingw"
         ENDIF
      ENDIF
#endif
   ENDIF
   IF !Empty( cPathHwgui )
      IF Empty( cPathHwguiInc )
         cPathHwguiInc := cPathHwgui + hb_ps() + "include"
      ENDIF
      IF Empty( cPathHwguiLib )
         cPathHwguiLib := cPathHwgui + hb_ps() + "lib"
      ENDIF
   ENDIF

#ifndef __CONSOLE
   oFontMain := HFont():Add( "Georgia", 0, 18,, 204 )
#endif

   IF IsIniDataChanged()
      WriteIni()
   ENDIF

   RETURN Nil

STATIC FUNCTION WriteIni()

   LOCAL cr := hb_eol()
   LOCAL s := "[HARBOUR]" + cr + "harbour_path=" + cPathHrb + cr + "harbour_bin_path=" + ;
      cPathHrbBin + cr + "harbour_include_path=" + cPathHrbInc + cr

   IF nCompDef > 0
      s += "def_c_compiler=" + Iif( nCompDef == 1, "bcc", "mingw" ) + cr
   ENDIF
   s += cr
#ifdef __PLATFORM__UNIX
   s += "[C_COMPILER_1]" + cr + "id=gcc" + cr + "harbour_lib_path=" + cPathHrbLib_gcc + cr + cr
#else
   s += "[C_COMPILER_1]" + cr + "id=bcc" + "path=" + cPathBcc + cr + "harbour_lib_path=" + cPathHrbLib_bcc + cr + cr + ;
      "[C_COMPILER_2]" + cr + "id=mingw" + "path=" + cPathMingw + cr + "harbour_lib_path=" + cPathHrbLib_mingw + cr + cr
#endif

   s += "[HWGUI]" + cr + "path=" + cPathHwgui + cr + "inc_path=" + cPathHwguiInc + cr + ;
      "lib_path=" + cPathHwguiLib + cr

   hb_MemoWrit( cIniPath, s )

   RETURN Nil

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

STATIC FUNCTION _Msg( cText, cTitle )

#ifdef __CONSOLE
   IF !Empty( cTitle )
      OutStd( hb_eol() + cTitle )
   ENDIF
   OutStd( hb_eol() + cText )
#else
   hwg_MsgStop( cText, cTitle )
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

   CLASS VAR aList       SHARED INIT {}

   DATA id
   DATA cPath
   DATA cPathInc
   DATA cPathLib
   DATA cPathHrbLib
   DATA cFlags


   METHOD New( id )

ENDCLASS

METHOD New( id ) CLASS HCompiler

   ::id := id
   AAdd( ::aList, Self )

   RETURN Self

CLASS HwProject

   DATA aFiles     INIT {}
#ifdef __PLATFORM__UNIX
   DATA nComp      INIT 99
#else
   DATA nComp      INIT 1
#endif
   DATA cLibsDop
   DATA cLibsPath
   DATA cFlagsPrg, cFlagsC
   DATA cOutPath, cOutName, cObjPath
   DATA lLib       INIT .F.
   DATA lMake      INIT .F.

   DATA aProjects  INIT {}

   METHOD New( aFiles, nComp, cLibsDop, cLibsPath, cFlagsPrg, cFlagsC, ;
      cOutPath, cOutName, cObjPath, lLib, lMake )
   METHOD Open( cFile, nComp )
   METHOD Build()
ENDCLASS

METHOD New( aFiles, nComp, cLibsDop, cLibsPath, cFlagsPrg, cFlagsC, ;
      cOutPath, cOutName, cObjPath, lLib, lMake ) CLASS HwProject

   IF PCount() > 1
      ::aFiles := aFiles
      ::nComp := nComp
      ::cLibsDop := cLibsDop
      ::cLibsPath := cLibsPath
      ::cFlagsPrg := cFlagsPrg
      ::cFlagsC := cFlagsC
      ::cOutPath := cOutPath
      ::cOutName := cOutName
      ::cObjPath := cObjPath
      ::lLib := lLib
      ::lMake := lMake
   ENDIF

   RETURN Self

METHOD Open( xSource, nComp ) CLASS HwProject

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
               _Msg( cLine, "Wrong option" )
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
               nComp := Iif( ( cTmp := Substr( cLine, nPos + 1 ) ) == "bcc", 1, Iif( cTmp == "mingw", 2, 0 ) )

            ELSE
               _Msg( cLine, "Wrong option" )
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
               AAdd( ::aProjects, o := HwProject():Open( ap, nComp ) )
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
               _Msg( cLine, "Wrong option" )
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
            _Msg( cLine, "Wrong option" )
            RETURN Nil
         ENDIF
      ENDIF
   NEXT

   //_msg( hb_valtoexp(Self) )
   IF Empty( ::aFiles ) .AND. Empty( ::aProjects )
      _Msg( "Source files missing", "Project error" )
      RETURN Nil
   ENDIF

#ifndef __PLATFORM__UNIX
   ::nComp := Iif( !Empty( nComp ), nComp, Iif( nCompDef > 0, nCompDef, Iif( !Empty( cPathBcc ), 1, ;
      Iif( !Empty( cPathMingw ), 2, 0 ) ) ) )
#endif

   RETURN Self

METHOD Build() CLASS HwProject

   LOCAL i, cCmd, cComp, cLine, cOut, cFullOut := "", lErr := .F., to, tc
   LOCAL cObjExt, cObjs := "", cBinary, cObjFile, cObjPath
   LOCAL aLibs, cLibs := "", a4Delete := {}, tStart := hb_DtoT( Date(), Seconds()-1 )

   FOR i := 1 TO Len( ::aProjects )
      ::aProjects[i]:Build()
   NEXT
   IF Empty( ::aFiles )
      RETURN Nil
   ENDIF

   IF !Empty( ::cObjPath )
      cObjPath := ::cObjPath + hb_ps() + Iif( ::nComp == 1, "b32", Iif( ::nComp == 2, "mingw", ;
         Iif( ::nComp == 99, "gcc", "" ) ) )
      IF !hb_DirExists( cObjPath )
         hb_DirBuild( cObjPath )
      ENDIF
      cObjPath := cObjPath + hb_ps()
   ELSE
      cObjPath := ""
   ENDIF

   _ShowProgress( "", 0 )

   // Compile prg sources with Harbour
   cCmd := cPathHrbBin + hb_ps() + "harbour -n -q -i" + cPathHrbInc + " -i" + cPathHwguiInc + ;
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
#ifdef __PLATFORM__UNIX
      cComp := "gcc"
      cCmd := " -c -I "+ cPathHrbInc + " -I" + cPathHwguiInc
      cObjExt := ".o"
#else
      IF ::nComp == 1
         cComp := cPathBcc + hb_ps() + "bin" + hb_ps() + "bcc32"
         cCmd := " -c -d -w -O2 -I"+ cPathHrbInc + ";" + cPathHwguiInc
         cObjExt := ".obj"
      ELSEIF ::nComp == 2
         cComp := cPathMingw + hb_ps() + "bin" + hb_ps() + "gcc"
         cCmd := " -c -Wall -I"+ cPathHrbInc + " -I" + cPathHwguiInc
         cObjExt := ".o"
      ENDIF
#endif
      IF !Empty( ::cFlagsC )
          cCmd += " " + ::cFlagsC
      ENDIF
      FOR i := 1 TO Len( ::aFiles )
         IF Lower( hb_fnameExt( ::aFiles[i] )) == ".c"
            cObjFile := cObjPath + hb_fnameName( ::aFiles[i] ) + cObjExt
            IF ::lMake .AND. File( cObjFile ) .AND. hb_vfTimeGet( cObjFile, @to ) .AND. ;
               hb_vfTimeGet( ::aFiles[i], @tc ) .AND. to >= tc
            ELSE
               cLine := cComp + cCmd + " -o" + cObjFile + " " + ::aFiles[i]

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
         cLibs += " " + Iif( ::nComp==1, "", "-l" ) + aLibs[i] + Iif( ::nComp==1, ".lib", "" )
      NEXT
      aLibs := hb_ATokens( cLibsHrb, " " )
      FOR i := 1 TO Len( aLibs )
         cLibs += " " + Iif( ::nComp==1, "", "-l" ) + aLibs[i] + Iif( ::nComp==1, ".lib", "" )
      NEXT
      IF !Empty( ::cLibsDop )
         aLibs := hb_ATokens( ::cLibsDop, Iif( ',' $ ::cLibsDop, ",", " " ) )
         FOR i := 1 TO Len( aLibs )
            cLibs += " " + Iif( ::nComp==1, "", "-l" ) + Alltrim(aLibs[i]) + Iif( ::nComp==1, ".lib", "" )
         NEXT
      ENDIF
#ifdef __PLATFORM__UNIX
      IF ::lLib
         cBinary := Iif( Empty(::cOutPath), "./", ::cOutPath+hb_ps() ) + "lib" + hb_fnameExtSet( cBinary, ".a" )
         cComp = "ar"
         cCmd := " rc " + cBinary + cobjs
      ELSE
         cBinary := Iif( Empty(::cOutPath), "", ::cOutPath+hb_ps() ) + hb_fnameName( cBinary )
         cComp := "gcc"
         cCmd := cObjs + " -o" + cBinary + ;
            " -L" + cPathHrbLib_gcc + " -L" + cPathHwguiLib + Iif( Empty(::cLibsPath), "", " -L" + ::cLibsPath ) + ;
            " -Wl,--start-group " + cLibs + " -Wl,--end-group `pkg-config --libs gtk+-2.0` " + cLibsGtk
      ENDIF
#else
      IF ::nComp == 1
         IF ::lLib
            cBinary := Iif( Empty(::cOutPath), "", ::cOutPath+hb_ps() ) + hb_fnameExtSet( cBinary, ".lib" )
            cComp = cPathBcc + hb_ps() + "bin" + hb_ps() + "tlib"
            cCmd := " " + cBinary + StrTran( cObjs, " ", " +" )
            _RunApp( "del " + cBinary, @cOut )
         ELSE
            cBinary := Iif( Empty(::cOutPath), "", ::cOutPath+hb_ps() ) + hb_fnameExtSet( cBinary, ".exe" )
            // Compile resources
            hb_MemoWrit( "hwgui_xp.rc", '1 24 "' + cPathHwgui + '\image\WindowsXP.Manifest"' )
            cCmd := "brc32 -r hwgui_xp -fohwgui_xp"
            _ShowProgress( "> " + cCmd, 1 )
            _RunApp( cCmd, @cOut )
            cFullOut += "> " + cCmd + hb_eol()
            cFullOut += cOut + hb_eol()
            _ShowProgress( cOut, 1 )
            AAdd( a4Delete, "hwgui_xp.rc" )
            AAdd( a4Delete, "hwgui_xp.res" )

            cComp := cPathBcc + hb_ps() + "bin" + hb_ps() + "ilink32"
            cCmd := " -Gn -aa -Tpe -L" + cPathHrbLib_bcc + ";" + cPathHwguiLib + ;
               Iif( Empty(::cLibsPath), "", ";" + ::cLibsPath ) + " c0w32.obj" + cObjs + ", " + ;
               cBinary + ",, " + cLibs + " " + cLibsBcc + ",, hwgui_xp.res"
            AAdd( a4Delete, hb_fnameExtSet( cBinary, "tds" ) )
            AAdd( a4Delete, hb_fnameExtSet( cBinary, "map" ) )
         ENDIF
      ELSEIF ::nComp == 2
         IF ::lLib
            cBinary := Iif( Empty(::cOutPath), "", ::cOutPath+hb_ps() ) + "lib" + hb_fnameExtSet( cBinary, ".a" )
            cComp = cPathMingw + hb_ps() + "bin" + hb_ps() + "ar"
            cCmd := " rc " + cBinary + cobjs
         ELSE
            cBinary := Iif( Empty(::cOutPath), "", ::cOutPath+hb_ps() ) + hb_fnameExtSet( cBinary, ".exe" )
            // Compile resources
            cCmd := StrTran( cPathHwgui, '\', '/' )
            hb_MemoWrit( "hwgui_xp.rc", '1 24 "' + cCmd + '/image/WindowsXP.Manifest"' )
            cCmd := "windres hwgui_xp.rc hwgui_xp.o"
            _ShowProgress( "> " + cCmd, 1 )
            _RunApp( cCmd, @cOut )
            cFullOut += "> " + cCmd + hb_eol()
            cFullOut += cOut + hb_eol()
            _ShowProgress( cOut, 1 )
            AAdd( a4Delete, "hwgui_xp.rc" )
            AAdd( a4Delete, "hwgui_xp.o" )

            cComp := cPathMingw + hb_ps() + "bin" + hb_ps() + "gcc"
            cCmd := " -Wall -mwindows -o" + cBinary + ;
               cObjs + " hwgui_xp.o -L" + cPathMingwLib + ;
               " -L" + cPathHrbLib_mingw + " -L" + cPathHwguiLib + ;
               Iif( Empty(::cLibsPath), "", " -L" + ::cLibsPath ) + ;
               " -Wl,--allow-multiple-definition -Wl,--start-group" + cLibs + " " + cLibsMingw + ;
               " -Wl,--end-group"
         ENDIF
      ENDIF
#endif
      cLine := cComp + cCmd

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
      cFullOut += cLine + hb_eol()
      _ShowProgress( cLine, 2 )
   ELSE
      _ShowProgress( "Error...", 2 )
   ENDIF

   ShowResult( cFullOut )
   FOR i := 1 TO Len( a4Delete )
      FErase( a4Delete[i] )
   NEXT

   RETURN Nil
