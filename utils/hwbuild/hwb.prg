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

#define HWB_VERSION  "1.6"

#define COMP_ID      1
#define COMP_EXE     2
#define COMP_LIBPATH 3
#define COMP_FLAGS   4        // C compiler flags
#define COMP_LFLAGSG 5        // Linker flags for gui app
#define COMP_LFLAGSC 6        // Linker flags for console app
#define COMP_LFLAGSL 7        // Linker flags for library
#define COMP_HVM     8
#define COMP_HWG     9
#define COMP_CMD1    10       // Template for compiling
#define COMP_CMD2    11       // Template for resource compiling
#define COMP_CMDL    12       // Template for lib linking
#define COMP_CMDE    13       // Template for exe linking
#define COMP_OBJEXT  14
#define COMP_LIBEXT  15
#define COMP_TMPLLIB 16
#define COMP_BINLIB  17
#define COMP_SYSLIBS 18

#define CLR_WHITE    0xffffff
#define CLR_BLACK    0
#define CLR_DBLUE    0x614834
#define CLR_DGRAY1   0x222222
#define CLR_DGRAYA   0x404040
#define CLR_DGRAY2   0x555555
#define CLR_DGRAY3   0x888888
#define CLR_LGRAY1   0xdddddd

#define CLR_BLUE1   0x552916
#define CLR_BLUE2   0x794431
#define CLR_BLUE3   0x8e624f
#define CLR_BLUE4   0xab8778
#define CLR_BLUE5   0xc9a596
#define CLR_BLUE6   0xe7c3b4

STATIC cIniPath
STATIC oPrg
STATIC lQ := .F.

STATIC cPathHrb := "", cPathHrbBin := "", cPathHrbInc := ""
STATIC cHrbDefFlags := "-n -q -w"
STATIC cGuiId := "hwgui", cPathHwgui := "", cPathHwguiInc := "", cPathHwguiLib := ""
STATIC lPathHrb := .F., lPathHrbBin := .F., lPathHrbInc := .F.
STATIC lPathHwgui := .F.

STATIC aHelp := { "hwbc <files>  [options...]", ;
  " -bcc              use the Borland C compiler", ;
  " -mingw            use the Mingw C compiler", ;
  " -msvc             use the MS Visual Studio", ;
  " -comp=<compiler>  use C compiler with specified id", ;
  " -gui=<guilib>     use GUI library with specified id", ;
  " -lib              build a library", ;
  " -clean            erase project obj files", ;
  " -q                shortened output", ;
  " -gt<lib>          use specified GT library", ;
  " -L<path>          an additional path to libraries", ;
  " -{<keyword>}      a keyword-condition for a project file", ;
  " -pf<options>, -prgflags=<options>  options for Harbour compiler", ;
  " -cf<options>, -cflags=<options>    options for C compiler", ;
  " -l<libraries>, -libs=<libraries>   a list of additionas libraries", ;
  " -sp<path>, -srcpath=<path>         a path to source files", ;
  " -o<name>, -out=<name>              a path and name of output file", ;
  " @<file>           include file", ;
  " -i<name>, -ini=<name>              a name of ini file" }

#ifdef __PLATFORM__UNIX
STATIC lUnix := .T.
STATIC cExeExt := ""
STATIC cLibsHrb := "hbvm hbrtl gtcgi gttrm hbcpage hblang hbrdd hbmacro hbpp rddntx rddcdx rddfpt hbsix hbcommon hbct hbcplr hbpcre hbzlib"
#else
STATIC lUnix := .F.
STATIC cExeExt := ".exe"
STATIC cLibsHrb := "hbvm hbrtl gtgui gtwin hbcpage hblang hbrdd hbmacro hbpp rddntx rddcdx rddfpt hbsix hbcommon hbct hbcplr hbpcre hbzlib"
#endif
STATIC cLibsHwGUI := ""

#ifndef __CONSOLE
STATIC oFontMain, oDlgBar
#endif
STATIC cFontMain := "", lProgressOn := .T., cExtView := ""

FUNCTION Main( ... )

   LOCAL aParams := hb_aParams(), i, j, c, aFiles := {}, af, cTmp
   LOCAL lPrj, lGUI := .F., lLib := .F., lClean := .F., oComp, oGui, cLibsDop, cLibsPath, cGtLib
   LOCAL cSrcPath, cObjPath, cOutName, cFlagsPrg, cFlagsC, aUserPar := {}
   LOCAL cIniName := "hwbuild.ini"

   FOR i := 1 TO Len( aParams )
      IF ( j := Left( aParams[i],1 ) ) == "-" .AND. Left( c := Substr( aParams[i],2 ), 1 ) == "i"
         IF '=' $ c
            IF Left( c,4 ) == "ini="
               cIniName := Substr( c, 5 )
            ELSE
               _MsgStop( c, "Wrong option" )
               RETURN Nil
            ENDIF
         ELSE
            cIniName := Substr( c, 2 )
         ENDIF
      ELSEIF j == "@"
         IF( c := _AddFromFile( Substr( aParams[i],2 ), .T. ) ) == Nil
            _MsgStop( Substr( aParams[i],2 ), "File doesn't exist" )
            RETURN Nil
         ENDIF
         j := 0
         DO WHILE !Empty( cTmp := hb_TokenPtr( c, @j, " ", .T. ) )
            AAdd( aParams, cTmp )
         ENDDO
         hb_ADel( aParams, i, .T. )
         i --
      ENDIF
   NEXT
   ReadIni( cIniName )

   FOR i := 1 TO Len( aParams )
      IF Left( aParams[i],1 ) == "-"
         IF ( c := Substr( aParams[i],2 ) ) == "bcc" .OR. c == "mingw" .OR. c == "msvc"
            IF ( j := Ascan( HCompiler():aList, {|o|o:id == c} ) ) > 0
               oComp := HCompiler():aList[j]
            ELSE
               _MsgStop( c + " compiler is missing in hwbuild.ini", "Wrong option" )
               RETURN Nil
            ENDIF

         ELSEIF c == "Open"
            lGUI := .T.

         ELSEIF c == "lib"
            lLib := .T.

         ELSEIF c == "q"
            lQ := .T.

         ELSEIF c == "clean"
            lClean := .T.

         ELSEIF Left( c,2 ) == "gt"
            cGtLib := c

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

         ELSEIF ( Left( c,1 ) == "o" .AND. !('=' $ c) ) .OR. Left( c,4 ) == "out="
            cOutName := _DropQuotes( Substr( c, Iif( '=' $ c, 5, 2 ) ) )

         ELSEIF ( Left( c,1 ) == "i" .AND. !('=' $ c) ) .OR. Left( c,4 ) == "ini="

         ELSEIF Left( c,5 ) == "comp="
            c := Substr( c, 6 )
            IF ( j := Ascan( HCompiler():aList, {|o|o:id == c} ) ) > 0
               oComp := HCompiler():aList[j]
            ENDIF
         ELSEIF Left( c,4 ) == "gui="
            c := Substr( c, 5 )
            IF ( j := Ascan( HGuilib():aList, {|o|o:id == c} ) ) > 0
               oGui := HGuilib():aList[j]
            ENDIF
         ELSEIF Left( c,1 ) == "{"
            Aadd( aUserPar, Iif( (j := At("}",c))==0, Substr( c,2 ), Substr( c, 2, j-2 ) ) )
         ELSE
            _MsgStop( c, "Wrong option" )
            RETURN Nil
         ENDIF
      ENDIF
   NEXT
   FOR i := 1 TO Len( aParams )
      IF Left( aParams[i],1 ) != "-"
         c := aParams[i]
         IF '*' $ c
            af := hb_Directory( Iif( Empty(cSrcPath), "", cSrcPath + hb_ps() ) + c )
            FOR j := 1 TO Len( af )
               AAdd( aFiles, { Iif( Empty(cSrcPath), af[i,1], cSrcPath + hb_ps() + af[i,1] ), } )
            NEXT
         ELSE
            c := Iif( !Empty( cSrcPath ) .AND. Empty( hb_fnameDir(c) ), cSrcPath + hb_ps() + c, c )
            IF Empty( hb_fnameExt(c) )
               IF File( c + ".hwprj" )
                  c += ".hwprj"
               ELSEIF File( c + ".prg" )
                  c += ".prg"
               ELSE
                  _MsgStop( c, "Wrong option" )
                  RETURN Nil
               ENDIF
            ENDIF
            Aadd( aFiles, { c, } )
         ENDIF
      ENDIF
   NEXT

#ifdef __CONSOLE
   IF Empty( aFiles )
      OutStd( "HwBuild - HwGUI Builder " + HWB_VERSION )
      FOR i := 1 TO Len( aHelp )
         OutStd( hb_eol() + aHelp[i] )
      NEXT
      RETURN Nil
   ENDIF
#endif

   IF Empty( oComp )
      oComp := HCompiler():aList[1]
   ENDIF
   IF !Empty( oGui )
      cGuiId := oGui:id
      cPathHwgui := _EnvVarsTran(oGui:cPath)
      cPathHwguiInc := _EnvVarsTran(oGui:cPathInc)
      cPathHwguiLib := _EnvVarsTran(oGui:cPathLib)
      cLibsHwGUI := oGui:cLibs
   ENDIF

   lPrj := ( Len( aFiles ) == 1 .AND. Lower( hb_fnameExt( aFiles[1,1] ) ) == ".hwprj" )
   IF Empty( aParams ) .OR. ( lGui .AND. lPrj )
#ifndef __CONSOLE
      StartGUI( Iif( Empty( aFiles ), Nil, aFiles[1,1] ) )
#endif
   ELSEIF !Empty( aFiles )
      IF lPrj
         IF !Empty( oPrg := HwProject():Open( aFiles[1,1], oComp, aUserPar ) )
            oPrg:Build( lClean )
         ENDIF
      ELSE
         oPrg := HwProject():New( aFiles, oComp, cGtLib, cLibsDop, cLibsPath, cFlagsPrg, cFlagsC, cOutName, cObjPath, lLib, .F. )
         oPrg:Build( lClean )
      ENDIF
   ELSE
#ifndef __CONSOLE
   _MsgStop( "No files" )
#endif
   ENDIF

   RETURN Nil

#ifndef __CONSOLE
STATIC FUNCTION ShowResult( cOut )

   LOCAL oDlg, oFont := HFont():Add( "Georgia",0,20 ), oEdit, oBoard, oBtnSwi
   LOCAL lFull := .T., cWarn, cTmp
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
   LOCAL bSwi := {||
      LOCAL i, j, cLastHea := "", lLastHea := .F., cc
      lFull := !lFull
      oBtnSwi:SetText( Iif( lFull, 'Short log', 'Full log' ) )
      IF lFull
         oEdit:SetText( cOut )
      ELSE
         cWarn := ""
         FOR i := 1 TO Len( oEdit:aText )
            IF Left( oEdit:aText[i],3 ) == "***"
               lLastHea := .T.
               cLastHea := oEdit:aText[i]

            ELSEIF Left( oEdit:aText[i],3 ) == "==="
               cWarn += Chr(10) + oEdit:aText[i] + Chr(10)

            ELSEIF "warning" $ ( cc := Lower(oEdit:aText[i]) ) .OR. "error" $ cc .OR. "note:" $ cc
               IF lLastHea
                  lLastHea := .F.
                  cWarn += Chr(10) + cLastHea + Chr(10)
               ENDIF
               cWarn += Chr(10) + oEdit:aText[i] + Chr(10)
            ENDIF
         NEXT
         oEdit:SetText( cWarn )
      ENDIF
      RETURN .T.
   }

   IF Empty( HWindow():GetMain() ) .AND. !Empty( cExtView )
      hb_MemoWrit( cTmp := (hb_DirTemp() + "hwbuild.log"), cOut )
      hwg_RunApp( cExtView + " " + cTmp )
      RETURN Nil
   ENDIF

   INIT DIALOG oDlg TITLE "HwBuild" AT 0,0  SIZE 800,650 FONT oFont

   @ 0, 0 HCEDIT oEdit SIZE 800, 600 FONT oFont ON SIZE {|o,x,y|o:Move( ,, x, y-50 ) }
   IF hwg__isUnicode()
      oEdit:lUtf8 := .T.
   ENDIF
   oEdit:SetWrap( .T. )
   oEdit:SetText( cOut )

   @ 0, 600 BOARD oBoard SIZE oDlg:nWidth, 50 FONT oFontMain BACKCOLOR CLR_DGRAY2 ;
      ON SIZE {|o,x,y|o:Move( ,y-50, x, )}

   @ 100, 10 DRAWN SIZE 80, 30 COLOR CLR_WHITE HSTYLES aStyles TEXT 'Close' ON CLICK {||oDlg:Close()}
   @ 260, 10 DRAWN oBtnSwi SIZE 120, 30 COLOR CLR_WHITE HSTYLES aStyles TEXT '' ON CLICK bSwi
   oBtnSwi:Anchor := ANCHOR_RIGHTABS
   IF !Empty( oPrg ) .AND. !Empty( oPrg:cFile ) .AND. Empty( HWindow():GetMain() )
      @ 460, 10 DRAWN SIZE 120, 30 COLOR CLR_WHITE HSTYLES aStyles TEXT 'Project' ;
         ON CLICK {||oDlg:Close(),StartGUI(oPrg:cFile)}
      ATail(oBoard:aDrawn):Anchor := ANCHOR_RIGHTABS
   ENDIF
   @ 680, 10 DRAWN SIZE 80, 30 COLOR CLR_WHITE HSTYLES aStyles TEXT 'Save' ;
      ON CLICK {||hb_MemoWrit("hwbuild.log",Iif(lFull,cOut,cWarn))}
   ATail(oBoard:aDrawn):Anchor := ANCHOR_RIGHTABS

   hwg_SetDlgKey( oDlg, FCONTROL, VK_ADD, bFont )
   hwg_SetDlgKey( oDlg, FCONTROL, VK_SUBTRACT, bFont )

   Eval( bSwi )

   ACTIVATE DIALOG oDlg CENTER
   oFont:Release()

   RETURN Nil

#define HILIGHT_KEYW    1
#define HILIGHT_COMM    4

STATIC FUNCTION StartGUI( cFile )

   LOCAL oMain, oEdit
   LOCAL cKeyw := ":project objpath srcpath libspath outpath outname def_cflags def_lflags def_libflags prgflags cflags gtlib libs target makemode c_compiler guilib"
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
         MENUITEM "&Load template" ACTION LoadTemplate()
         MENUITEM "&Save" ACTION SaveProject()
         SEPARATOR
         MENUITEM "&Paths" ACTION FPaths()
         MENUITEM "&Exit" ACTION hwg_EndWindow()
      ENDMENU
      MENU TITLE "&Project"
         MENUITEM "&Run" ACTION RunProject( .F. )
         MENUITEM "&Clean" ACTION RunProject( .T. )
         SEPARATOR
         MENUITEM "&Add option"+Chr(9)+"Ctrl+I" ACTION AddOpt2Prj() ACCELERATOR FCONTROL,Asc("I")
         MENUITEM "&Add directory" ACTION AddDir2Prj()
      ENDMENU
      MENU TITLE "&Help"
         MENUITEM "&Command line" ACTION Help_CmdLine()
         MENUITEM "&About" ACTION hwg_MsgInfo( "HwGUI Builder " + HWB_VERSION + hb_eol() + ;
         "(C) Alexander S.Kresin, 2023" + hb_eol() + hb_eol() + hwg_Version(), "About" )
      ENDMENU
   ENDMENU

   @ 0, 0 HCEDIT oEdit SIZE oMain:nWidth, oMain:nHeight FONT oFontMain ON SIZE {|o,x,y|o:Move( ,, x, y ) }
   IF hwg__isUnicode()
      oEdit:lUtf8 := .T.
   ENDIF
   oEdit:bColorCur := oEdit:bColor
   oEdit:HighLighter( Hilight():New( ,, cKeyw,, "#", "{ }", .F. ) )
   oEdit:SetHili( HILIGHT_KEYW, oEdit:oFont:SetFontStyle( .T. ) )
   oEdit:SetHili( HILIGHT_COMM, oEdit:oFont:SetFontStyle( ,, .T. ), CLR_BLACK, CLR_LGRAY1 )

   IF !Empty( cFile )
      OpenProject( cFile )
   ELSE
      NewProject()
   ENDIF

   hwg_SetDlgKey( oMain, FCONTROL, VK_ADD, bFont )
   hwg_SetDlgKey( oMain, FCONTROL, VK_SUBTRACT, bFont )

   ACTIVATE WINDOW oMain

   RETURN Nil

STATIC FUNCTION Help_CmdLine()

   LOCAL s := "", i

   FOR i := 1 TO Len( aHelp )
      s += hb_eol() + aHelp[i]
   NEXT
   s += hb_eol() + " -Open             Open project in a window"

   hwg_MsgInfo( s, "Command line parameters" )

   RETURN Nil

STATIC FUNCTION FPaths()

   LOCAL oDlg, oBoard, oEdi1, oEdi2, oEdi3, oEdi4, oEdi5, oEdi6, aEdi := Array( Len(HCompiler():aList), 2 )
   LOCAL oLenta, nTab := 1, aItems := { "Harbour", "HwGUI" }, aTabs := Array( Len(HCompiler():aList)+2 )
   LOCAL aCorners := { 4,4,4,4 }, y, i
/*
   LOCAL aStyles := { HStyle():New( { CLR_BLUE2 }, 1, aCorners ), ;
      HStyle():New( { CLR_BLUE4 }, 2, aCorners ), ;
      HStyle():New( { CLR_BLUE3 }, 1, aCorners ) }
   LOCAL aStyleLenta := { HStyle():New( { CLR_BLUE2, CLR_BLUE4 }, 1 ), ;
      HStyle():New( { CLR_BLUE3 }, 1,, 1, CLR_BLUE5 ) }
*/
   LOCAL aStyles := { HStyle():New( { CLR_DGRAY2 }, 1, aCorners ), ;
      HStyle():New( { CLR_LGRAY1 }, 2, aCorners ), ;
      HStyle():New( { CLR_DGRAY3 }, 1, aCorners ) }
   LOCAL aStyleLenta := { HStyle():New( { CLR_DGRAY2, CLR_DGRAY3 }, 1 ), ;
      HStyle():New( { CLR_DGRAY2, CLR_DGRAY3 }, 1,, 1, CLR_WHITE ) }

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

   @ 0, 0 BOARD oBoard SIZE oDlg:nWidth, oDlg:nHeight FONT oFontMain BACKCOLOR CLR_DGRAY2 ;
      ON SIZE {|o,x,y|o:Move( ,, x, y )}

   FOR i := 1 TO Len( HCompiler():aList )
      AAdd( aItems, HCompiler():aList[i]:id )
   NEXT
   @ 30, 16 DRAWN LENTA oLenta SIZE 580, 28 FONT oFontMain COLOR CLR_WHITE ;
      ITEMS aItems ITEMSIZE 100 HSTYLES aStyleLenta ON CLICK bTab
    oLenta:Value := nTab

   y := 60
   @ 20, y DRAWN aTabs[1] SIZE 600, 200  COLOR CLR_WHITE BACKCOLOR CLR_DGRAY2

   @ 20, y DRAWN aTabs[2] SIZE 600, 200  COLOR CLR_WHITE BACKCOLOR CLR_DGRAY2
   aTabs[2]:lDisable := .T.

   FOR i := 1 TO Len( HCompiler():aList )
      @ 20, y DRAWN aTabs[i+2] SIZE 560, 190  COLOR CLR_WHITE BACKCOLOR CLR_DGRAY2
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

STATIC FUNCTION AddOpt2Prj()

   LOCAL arr := { "objpath", "srcpath", "libspath", "outpath", "outname", ;
       "def_cflags", "def_lflags", "def_libflags", "prgflags", "cflags", "gtlib", "libs", "target", ;
        "makemode", "c_compiler", "guilib", ":project" }
   LOCAL nChoic
   LOCAL oEdit := HWindow():GetMain():oEdit, nLine

   nChoic := hwg_WChoice( arr, "Add option",,, oFontMain,,,,, "Add", "Cancel" )
   IF nChoic == 0
      RETURN Nil
   ENDIF

   nLine := oEdit:nLineC
   IF !Empty( oEdit:aText[nLine] )
      oEdit:onKeyDown( VK_END, 0, 0 )
      oEdit:InsText( { oEdit:nPosC, nLine }, Chr(10) + arr[nChoic] + '=' )
   ELSE
      oEdit:InsText( { 1, nLine }, arr[nChoic] + '=' )
   ENDIF

   AddDir2Prj( .T. )
   hwg_SetFocus( oEdit:handle )

   RETURN Nil

STATIC FUNCTION AddDir2Prj( lSilent )

   LOCAL oEdit := HWindow():GetMain():oEdit, cDir
   LOCAL nLine := oEdit:nLineC, cLine := oEdit:aText[nLine]
   LOCAL arr := { "objpath", "srcpath", "libspath", "outpath" }

   IF !( Right( cLine,1 ) == "=" ) .OR. hb_Ascan( arr, hb_strShrink(cLine,1),,, .T. ) == 0
      IF Empty( lSilent )
         _MsgStop( "Wrong place" )
      ENDIF
      RETURN Nil
   ENDIF

   IF Empty( cDir := hwg_SelectFolder() )
      RETURN Nil
   ENDIF

   oEdit:onKeyDown( VK_END, 0, 0 )
   oEdit:InsText( { oEdit:nPosC, nLine }, cDir )
   hwg_SetFocus( oEdit:handle )

   RETURN Nil

STATIC FUNCTION AskForSave()

   IF HWindow():GetMain():oEdit:lUpdated .AND. hwg_MsgYesNo( "Project was changed. Save it?", "HwBuild" )
      RETURN .T.
   ENDIF

   RETURN .F.

STATIC FUNCTION NewProject()

   IF AskForSave()
      SaveProject()
   ENDIF

   HWindow():GetMain():oEdit:SetText( "" )

   oPrg := Nil

   RETURN Nil

STATIC FUNCTION LoadTemplate()

   LOCAL cFullPath, cFile := "template.hwprj"

   IF AskForSave()
      SaveProject()
   ENDIF

#ifdef __PLATFORM__UNIX
   IF File( cFullPath := ( getenv("HOME") + "/hwbuild/" + cFile ) ) .OR. ;
      File( cFullPath := ( hb_DirBase() + cFile ) )
#else
   IF File( cFullPath := ( hb_DirBase() + cFile ) )
#endif
      HWindow():GetMain():oEdit:SetText( Memoread( cFullPath ) )
   ENDIF

   RETURN Nil

STATIC FUNCTION OpenProject( cFile )

   LOCAL oMain := HWindow():GetMain()

   IF AskForSave()
      SaveProject()
   ENDIF
   IF Empty( cFile )
      cFile := hwg_Selectfile( { "Hwbuild project (*.hwprj)" }, { "*.hwprj" }, Curdir() )
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
         oMain:oEdit:cFileName := hwg_Selectfile( "( *.hwprj )", "*.hwprj" )
#else
         oMain:oEdit:cFileName := hwg_SaveFile( "*.hwprj", "( *.hwprj )", "*.hwprj" )
#endif
         IF Empty( oMain:oEdit:cFileName )
            RETURN Nil
         ENDIF
         oMain:oEdit:cFileName := hb_fnameExtSet( oMain:oEdit:cFileName, "hwprj" )
      ENDIF
      oMain:oEdit:Save( oMain:oEdit:cFileName )
      oMain:oEdit:lUpdated := .F.
   ENDIF
   RETURN Nil

STATIC FUNCTION RunProject( lClean )

   LOCAL oEdit := HWindow():GetMain():oEdit
   LOCAL i, nPos, cLine, cTmp, l, aUserPar := {}, arr
   LOCAL lCompilers := ( Len(HCompiler():aList) > 1 )

   FOR i := 1 TO Len( oEdit:aText )
      IF !Empty( cLine := AllTrim( oEdit:aText[i] ) ) .AND. !( Left( cLine, 1 ) == "#" )
         l := .T.
         DO WHILE Left( cLine,1 ) == '{'
            IF ( nPos := At( "}", cLine ) ) > 0
               cTmp := AllTrim( Substr( cLine, 2, nPos-2 ) )
               l := .T.
               IF Left( cTmp,1 ) == "!"
                  cTmp := LTrim( Substr( cTmp,2 ) )
                  l := .F.
               ENDIF
               IF ( cTmp == "win" .AND. ( (lUnix .AND. l) .OR. (!lUnix .AND. !l) )  ) .OR. ;
                  ( cTmp == "unix" .AND. ( (!lUnix .AND. l) .OR. (lUnix .AND. !l) ) )
                  l := .F.
                  EXIT
               ENDIF
               l := .T.
               IF !( cTmp == "win" .OR. cTmp == "unix" .OR. ;
                  Ascan( HCompiler():aList, {|o|o:id==cTmp .OR. o:family==cTmp} ) > 0 ) ;
                  .AND. Ascan( aUserPar, {|a|a[2]==cTmp} ) == 0
                  AAdd( aUserPar, { .F., cTmp } )
               ENDIF
               cLine := LTrim( Substr( cLine, nPos + 1 ) )
            ELSE
               _MsgStop( cLine, "Wrong option" )
               RETURN .F.
            ENDIF
         ENDDO
         IF l .AND. Left( cLine, 10 ) == "c_compiler"
            lCompilers := .F.
         ENDIF
      ENDIF
   NEXT

   IF !Empty( aUserPar ) .OR. lCompilers
      IF !SelectFromList( lCompilers, aUserPar )
         RETURN .F.
      ENDIF
      IF !Empty( aUserPar ) .AND. Ascan( aUserPar, {|a|a[1]} ) > 0
         arr := {}
         FOR i := 1 TO Len( aUserPar )
            IF aUserPar[i,1]
               AAdd( arr, aUserPar[i,2] )
            ENDIF
         NEXT
      ENDIF
   ENDIF

   IF !Empty( oPrg := HwProject():Open( oEdit:aText, oPrg:oComp, arr ) )
      oPrg:Build( lClean )
   ENDIF

   RETURN .T.

STATIC FUNCTION SelectFromList( lComp, arr )

   LOCAL i, n := Len( arr ), x := Iif( lComp .AND. !Empty(arr), 20, 100 )
   LOCAL oDlg, oBoard, lRes := .F.
   LOCAL aCorners := { 4,4,4,4 }
   LOCAL aStyles := { HStyle():New( { CLR_DGRAY2 }, 1, aCorners ), ;
      HStyle():New( { CLR_LGRAY1 }, 2, aCorners ), ;
      HStyle():New( { CLR_DGRAY3 }, 1, aCorners ) }
   LOCAL bOk := {||
      LOCAL j := 1
      IF lComp
         FOR i := 1 TO Len( HCompiler():aList )
            IF oBoard:aDrawn[j]:Value
               oPrg:oComp := HCompiler():aList[i]
               EXIT
            ENDIF
            j += 2
         NEXT
         j := Len( HCompiler():aList ) * 2 + 1
      ENDIF
      FOR i := 1 TO Len( arr )
         IF oBoard:aDrawn[j]:Value
            arr[i,1] := .T.
         ENDIF
         j += 2
      NEXT
      lRes := .T.
      oDlg:Close()
      RETURN Nil
   }

   IF lComp
      n := Max( n, Len(HCompiler():aList) )
   ENDIF

   INIT DIALOG oDlg TITLE "Select" AT 0,0 SIZE 300, n*40 + 80

   @ 0, 0 BOARD oBoard SIZE oDlg:nWidth, oDlg:nHeight FONT oFontMain BACKCOLOR CLR_DGRAYA ;
      ON SIZE {|o,x,y|o:Move( ,, x, y )}

   IF lComp
      FOR i := 1 TO Len( HCompiler():aList )
         @ x, 12 + (i-1) * 40 DRAWN RADIO GROUP "m" SIZE 20, 30 COLOR CLR_WHITE ;
            BACKCOLOR CLR_BLACK HSTYLES aStyles TEXT 'X' INIT (i==1)
         @ x+30, 12 + (i-1) * 40 DRAWN SIZE 90, 30 COLOR CLR_WHITE TEXT HCompiler():aList[i]:id
      NEXT
      x += 150
   ENDIF

   FOR i := 1 TO Len( arr )
      @ x, 12 + (i-1) * 40 DRAWN CHECK SIZE 20, 30 COLOR CLR_WHITE ;
         BACKCOLOR CLR_BLACK HSTYLES aStyles TEXT 'X'
      @ x+30, 12 + (i-1) * 40 DRAWN SIZE 90, 30 COLOR CLR_WHITE TEXT arr[i,2]
   NEXT

   @ 40, oDlg:nHeight - 50 DRAWN SIZE 80, 30 COLOR CLR_WHITE HSTYLES aStyles TEXT 'Ok' ;
      ON CLICK bOk
   @ 180, oDlg:nHeight - 50 DRAWN SIZE 80, 30 COLOR CLR_WHITE HSTYLES aStyles TEXT 'Cancel' ;
      ON CLICK {||lRes:=.F.,oDlg:Close()}

   ACTIVATE DIALOG oDlg CENTER

   RETURN lRes

STATIC FUNCTION PBar( nAct, nMax )

   LOCAL oBoard, oSay, oBar
   STATIC bPaint := {|o,h|

      hwg_Rectangle_Filled( h, o:nLeft, o:nTop, ;
         o:nLeft+Iif( o:xValue>=o:cargo, o:nWidth, Int(o:nWidth*o:xValue/o:cargo) ), ;
         o:nTop+o:nHeight-1, .F., o:oBrush:handle )
      RETURN 0
   }

   IF nAct == 0

      IF !Empty( oDlgBar )
         oDlgBar:Close()
         oDlgBar := Nil
      ENDIF

      INIT DIALOG oDlgBar TITLE "HwBuilder" AT 0, 0 SIZE 200, 100 ON EXIT {||oDlgBar:=Nil,.T.}

      @ 0, 0 BOARD oBoard SIZE oDlgBar:nWidth, oDlgBar:nHeight FONT oFontMain BACKCOLOR CLR_DGRAY2 ;
         ON SIZE {|o,x,y|o:Move( ,, x, y )}

      @ 20, 20 DRAWN oSay SIZE oDlgBar:nWidth-40, 30 COLOR CLR_WHITE TEXT ''

      @ 20, 70 DRAWN oBar SIZE oDlgBar:nWidth-40, 4 BACKCOLOR CLR_WHITE
      oBar:bPaint := bPaint
      oBar:xValue := 0
      oBar:cargo := nMax

      ACTIVATE DIALOG oDlgBar NOMODAL CENTER

   ELSEIF nAct == 1

      oDlgBar:oBoard:oBar:xValue ++
      oDlgBar:oBoard:oBar:Refresh()
      hwg_Sleep( 1 )
      hwg_ProcessMessage()

   ELSEIF nAct == 2

      IF !Empty( oDlgBar )
         oDlgBar:Close()
         oDlgBar := Nil
      ENDIF

   ENDIF

   RETURN Nil

#else

STATIC FUNCTION ShowResult()
   RETURN Nil

STATIC FUNCTION FPaths()
   RETURN Nil

#endif

STATIC FUNCTION CheckOptions( oProject )

   LOCAL nDef, oComp := oProject:oComp

   IF Empty( cPathHrbBin ) .OR. !File( _EnvVarsTran(cPathHrbBin) + hb_ps() + "harbour" + cExeExt )
      RETURN "Empty or wrong harbour executables path"
   ENDIF
   IF Empty( cPathHrbInc ) .OR. !File( _EnvVarsTran(cPathHrbInc) + hb_ps() + "hbsetup.ch" )
      RETURN "Empty or wrong harbour include path"
   ENDIF
   IF cGuiId == "hwgui" .AND. ( Empty( cPathHwguiInc ) .OR. ;
      !File( cPathHwguiInc + hb_ps() + "hwgui.ch" ) )
      RETURN "Empty or wrong hwgui include path"
   ENDIF

   IF ( nDef := Ascan( HCompiler():aDef, {|a|a[COMP_ID] == oComp:id} ) ) > 0
      IF !oProject:lLib .AND. cGuiId == "hwgui" .AND. ( Empty( cPathHwguiLib ) .OR. ;
         !File( cPathHwguiLib + hb_ps() + HCompiler():aDef[nDef,COMP_HWG] ) )
         RETURN "Empty or wrong hwgui libraries path"
      ENDIF
#ifndef __PLATFORM__UNIX
      IF Empty( oComp:cPath ) .OR. !File( _EnvVarsTran(oComp:cPath) + hb_ps() + ;
         HCompiler():aDef[nDef,COMP_EXE] )
         RETURN "Empty or wrong " + oComp:id + " path"
      ENDIF
#endif
      IF !oProject:lLib .AND. ( Empty( oComp:cPathHrbLib ) .OR. ;
         !File( _EnvVarsTran(oComp:cPathHrbLib) + hb_ps() + HCompiler():aDef[nDef,COMP_HVM] ) )
         RETURN "Empty or wrong " + oComp:id + " harbour libraries path"
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION FindHarbour()

   LOCAL aEnv, cTmp, cPath, nPos

   IF Empty( cPathHrb ) .AND. Empty( cPathHrb := getenv("HB_PATH") ) .AND. Empty( cPathHrb := getenv("HB_ROOT") )
      cTmp := "harbour" + cExeExt
      aEnv := hb_ATokens( getenv("PATH"), hb_osPathListSeparator() )
      FOR EACH cPath IN aEnv
         IF File( _DropSlash(cPath) + hb_ps() + cTmp )
            cPathHrbBin := _DropSlash( cPath )
            EXIT
         ENDIF
      NEXT
      IF !Empty( cPathHrbBin )
         IF ( nPos := hb_At( hb_ps()+"bin", cPathHrbBin ) ) > 0
            cPathHrb := Left( cPathHrbBin, nPos-1 )
         ENDIF
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION ReadIni( cFile )

   LOCAL cPath, hIni, aIni, arr, nSect, aSect, cTmp, i, j, key, nPos, cFam, oComp, oGui
   LOCAL aEnv, aMsvc := Array(4), aEnvM

#ifdef __PLATFORM__UNIX
   IF File( cPath := ( _CurrPath() + cFile ) ) .OR. ;
      File( cPath := ( getenv("HOME") + "/hwbuild/" + cFile ) ) .OR. ;
      File( cPath := ( hb_DirBase() + cFile ) )
#else
   IF File( cPath := ( _CurrPath() + cFile ) ) .OR. ;
      File( cPath := ( hb_DirBase() + cFile ) )
#endif
      hIni := _IniRead( cPath )
#ifdef __CONSOLE
      OutStd( hb_eol() + "Read options from " + cPath + hb_eol() )
#endif
   ENDIF
   cIniPath := cPath

   IF !Empty( hIni )
      hb_hCaseMatch( hIni, .F. )
      IF hb_hHaskey( hIni, cTmp := "HARBOUR" ) .AND. !Empty( aSect := hIni[ cTmp ] )
         hb_hCaseMatch( aSect, .F. )
         IF hb_hHaskey( aSect, cTmp := "harbour_path" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
            cPathHrb := _DropSlash( cTmp )
            lPathHrb := .T.
         ENDIF
         IF hb_hHaskey( aSect, cTmp := "harbour_bin_path" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
            cPathHrbBin := _DropSlash( cTmp )
            lPathHrbBin := .T.
         ENDIF
         IF hb_hHaskey( aSect, cTmp := "harbour_include_path" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
            cPathHrbInc := _DropSlash( cTmp )
            lPathHrbInc := .T.
         ENDIF
         IF hb_hHaskey( aSect, cTmp := "def_flags" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
            cHrbDefFlags := cTmp
         ENDIF
         IF hb_hHaskey( aSect, cTmp := "libs" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
            cLibsHrb := cTmp
         ENDIF
      ENDIF
      FindHarbour()

      aIni := hb_hKeys( hIni )
      FOR nSect := 1 TO Len( aIni )
         IF Left( aIni[nSect], 6 ) == "GUILIB" .AND. !Empty( aSect := hIni[ aIni[nSect] ] )
            hb_hCaseMatch( aSect, .F. )
            IF hb_hHaskey( aSect, cTmp := "id" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
               cGuiId := cTmp
               oGui := HGuilib():New( cTmp )

               IF hb_hHaskey( aSect, cTmp := "path" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
                  oGui:cPath := _DropSlash( cTmp )
                  lPathHwgui := .T.
               ENDIF
               IF hb_hHaskey( aSect, cTmp := "inc_path" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
                  oGui:cPathInc := _DropSlash( cTmp )
               ENDIF
               IF hb_hHaskey( aSect, cTmp := "lib_path" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
                  oGui:cPathLib := _DropSlash( cTmp )
               ENDIF
               IF hb_hHaskey( aSect, cTmp := "libs" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
                  oGui:cLibs := cTmp
               ENDIF
            ENDIF

         ELSEIF Left( aIni[nSect], 10 ) == "C_COMPILER" .AND. !Empty( aSect := hIni[ aIni[nSect] ] )
            hb_hCaseMatch( aSect, .F. )
            IF hb_hHaskey( aSect, cTmp := "id" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
               cFam := Iif( hb_hHaskey( aSect, cFam := "family" ) .AND. ;
                  !Empty( cFam := aSect[ cFam ] ), cFam, "" )
               oComp := HCompiler():New( cTmp, cFam )
               arr := hb_hKeys( aSect )
               FOR EACH key IN arr
                  IF key == "bin_path" .AND. !Empty( cTmp := aSect[ key ] )
                     oComp:cPath := _DropSlash( cTmp )
                     oComp:lPath := .T.
                  ELSEIF key == "harbour_lib_path" .AND. !Empty( cTmp := aSect[ key ] )
                     oComp:cPathHrbLib := _DropSlash( cTmp )
                     oComp:lPathHrbLib := .T.
                  ELSEIF key == "def_cflags" .AND. !Empty( cTmp := aSect[ key ] )
                     oComp:cFlags := cTmp
                     oComp:lFlags := .T.
                  ELSEIF key == "def_linkflags" .AND. !Empty( cTmp := aSect[ key ] )
                     oComp:cLinkFlagsGui := cTmp
                     oComp:lLinkFlagsGui := .T.
                  ELSEIF key == "def_libflags" .AND. !Empty( cTmp := aSect[ key ] )
                     oComp:cLinkFlagsLib := cTmp
                     oComp:lLinkFlagsLib := .T.
                  ELSEIF key == "def_syslibs" .AND. !Empty( cTmp := aSect[ key ] )
                     oComp:cSysLibs := cTmp
                     oComp:lSysLibs := .T.
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
            IF hb_hHaskey( aSect, cTmp := "progressbar" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
               lProgressOn := ( Lower(cTmp) == "on" )
            ENDIF
            IF hb_hHaskey( aSect, cTmp := "extview" ) .AND. !Empty( cTmp := aSect[ cTmp ] )
               cExtView := cTmp
            ENDIF
         ENDIF
      NEXT
   ELSE
      FindHarbour()
   ENDIF

   IF !Empty( cPathHrb )
      IF Empty( cPathHrbBin )
         cPathHrbBin := cPathHrb + hb_ps() + "bin"
      ENDIF
      IF Empty( cPathHrbInc )
         cPathHrbInc := cPathHrb + hb_ps() + "include"
#ifdef __PLATFORM__UNIX
         IF !hb_DirExists( _EnvVarsTran(cPathHrbInc) ) .AND. cPathHrbBin == "/usr/local/bin"
            cPathHrbInc := "/usr/local/include/harbour"
         ENDIF
#endif
      ENDIF
   ENDIF

   IF Empty( HGuilib():aList )
      HGuilib():New( "hwgui" )
   ENDIF
   oGui := HGuilib():aList[1]
   cGuiId := oGui:id
   cPathHwgui := _EnvVarsTran(oGui:cPath)
   cPathHwguiInc := _EnvVarsTran(oGui:cPathInc)
   cPathHwguiLib := _EnvVarsTran(oGui:cPathLib)
   cLibsHwGUI := oGui:cLibs

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
      IF !hb_DirExists( _EnvVarsTran(oComp:cPathHrbLib) ) .AND. cPathHrbBin == "/usr/local/bin"
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
               IF File( _DropSlash(cPath) + hb_ps() + HCompiler():aDef[i,COMP_EXE] )
                  oComp:cPath := _DropSlash( cPath )
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
                     IF File( _DropSlash(cPath) + hb_ps() + HCompiler():aDef[i,COMP_EXE] )
                        oComp:cPath := _DropSlash( cPath )
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
      oFontMain := HFont():Add( "Georgia", 0, 18,, 204 )
      cFontMain := oFontMain:SaveToStr()
   ELSE
      oFontMain := HFont():LoadFromStr( cFontMain )
   ENDIF
#endif

   IF IsIniDataChanged()
      WriteIni()
   ENDIF

   RETURN Nil

STATIC FUNCTION WriteIni()

   LOCAL cr := hb_eol(), oComp, oGui, n := 0, n1, aEnv
   LOCAL s := "[HARBOUR]" + cr + "harbour_path=" + cPathHrb + cr + "harbour_bin_path=" + ;
      cPathHrbBin + cr + "harbour_include_path=" + cPathHrbInc + cr + "def_flags=" + cHrbDefFlags + ;
      cr + "libs=" + cLibsHrb + cr + cr

   FOR EACH oGui IN HGuilib():aList
      n ++
      s += "[GUILIB" + Iif( n == 1, "", "_" + Ltrim(Str(n)) ) + "]" + cr + ;
         "id=" + oGui:id + cr + "path=" + oGui:cPath + cr + ;
         "inc_path=" + oGui:cPathInc + cr + "lib_path=" + oGui:cPathLib + cr + ;
         "libs=" + oGui:cLibs + cr + cr
   NEXT

   n := 0
   FOR EACH oComp IN HCompiler():aList
      n ++
      s += "[C_COMPILER" + Iif( n == 1, "", "_" + Ltrim(Str(n)) ) + "]" + cr + ;
         "id=" + oComp:id + cr + "bin_path=" + ;
         oComp:cPath + cr + "harbour_lib_path=" + oComp:cPathHrbLib + cr + ;
         "def_cflags=" + oComp:cFlags + cr + "def_linkflags=" + oComp:cLinkFlagsGui + cr + ;
         + "def_libflags=" + oComp:cLinkFlagsLib + cr + "def_syslibs=" + oComp:cSysLibs + cr
      n1 := 0
      FOR EACH aEnv in oComp:aEnv
         s += "env_" + Ltrim(Str(++n1)) + "=" + aEnv[1] + "=" + aEnv[2] + cr
      NEXT
      s += cr
   NEXT

   s += "[VIEW]" + cr + "font=" + cFontMain + cr + "progressbar=" + Iif( lProgressOn, "On", "" ) + ;
      cr + "extview=" + cExtView + cr + cr

#ifdef __CONSOLE
      OutStd( hb_eol() + "Update options in " + cIniPath + hb_eol() )
#endif
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
      IF !oComp:lFlags .AND. !Empty( oComp:cFlags )
         RETURN ( oComp:lFlags := .T. )
      ENDIF
      IF !oComp:lLinkFlagsGui .AND. !Empty( oComp:cLinkFlagsGui )
         RETURN ( oComp:lLinkFlagsGui := .T. )
      ENDIF
      IF !oComp:lLinkFlagsLib .AND. !Empty( oComp:cLinkFlagsLib )
         RETURN ( oComp:lLinkFlagsLib := .T. )
      ENDIF
      IF !oComp:lSysLibs .AND. !Empty( oComp:cSysLibs )
         RETURN ( oComp:lSysLibs := .T. )
      ENDIF
   NEXT

   RETURN .F.

STATIC FUNCTION _DropQuotes( cLine )

   IF Left( cLine, 1 ) == '"' .AND. Right( cLine, 1 ) == '"'
      RETURN Substr( cLine, 2, Len( cLine ) - 2 )
   ENDIF

   RETURN cLine

STATIC FUNCTION _DropSlash( cLine )

   IF Right( cLine,1 ) $ "/\"
      RETURN hb_strShrink( cLine, 1 )
   ENDIF
   RETURN cLine

STATIC FUNCTION _DropBr( cLine )

   LOCAL nPos

   IF Left( cLine,1 ) == "{"
      IF ( nPos := At( "}", cLine ) ) > 0
         RETURN Substr( cLine,nPos+1 )
      ELSE
         RETURN ""
      ENDIF
   ENDIF

   RETURN cLine

STATIC FUNCTION _HasError( cLine )

   LOCAL nPos := 1, c, l

   DO WHILE ( nPos := hb_AtI( "error", cLine, nPos ) ) > 0

      l := .F.
      c := Iif( nPos == 1, 'a', Substr( cLine, nPos-1, 1 ) )
      IF c < 'A' .OR. (c > 'Z' .AND. c < 'a') .OR. c > 'z'
         l := .T.
      ENDIF
      nPos += 5
      c := Iif( nPos > Len( cLine ), 'a', Substr( cLine, nPos, 1 ) )
      IF c < 'A' .OR. (c > 'Z' .AND. c < 'a') .OR. c > 'z'
         IF l
            RETURN .T.
         ENDIF
      ENDIF
   ENDDO

   RETURN .F.

STATIC FUNCTION _EnvVarsTran( cLine )

   LOCAL nPos := 1, nPos2, nLen, cVar, cValue

   DO WHILE ( nPos := hb_At( '%', cLine, nPos ) ) > 0
      IF ( nPos2 := hb_At( '%', cLine, nPos+1 ) ) > 0
         cVar := Substr( cLine, nPos+1, nPos2-nPos-1 )
         IF !Empty( cValue := Getenv( cVar ) )
            cLine := Left( cLine, nPos-1 ) + cValue + Substr( cLine, nPos2+1 )
         ELSE
            _MsgStop( cVar, "Variable does not exist" )
            RETURN cLine
         ENDIF
      ELSE
         _MsgStop( cLine, "Wrong line in ini" )
         RETURN cLine
      ENDIF
   ENDDO

   nPos := 1
   DO WHILE ( nPos := hb_At( '$', cLine, nPos ) ) > 0
      nPos2 := nPos + 2
      nLen := Len( cLine )
      DO WHILE nPos2 < nLen .AND. !( Substr( cLine, nPos2, 1 ) $ "/\." )
         nPos2 ++
      ENDDO
      cVar := Substr( cLine, nPos+1, nPos2-nPos-1 )
      IF !Empty( cValue := Getenv( cVar ) )
         cLine := Left( cLine, nPos-1 ) + cValue + Substr( cLine, nPos2 )
      ELSE
         _MsgStop( cVar, "Variable does not exist" )
         RETURN cLine
      ENDIF
   ENDDO

   RETURN cLine

STATIC FUNCTION _AddFromFile( cFile, l2Line )

   LOCAL cPath

   IF Empty( hb_fnameDir( cFile := _DropQuotes(cFile) ) )
#ifdef __PLATFORM__UNIX
      IF File( cPath := ( _CurrPath() + cFile ) ) .OR. ;
         File( cPath := ( getenv("HOME") + "/hwbuild/" + cFile ) ) .OR. ;
         File( cPath := ( hb_DirBase() + cFile ) )
#else
      IF File( cPath := ( _CurrPath() + cFile ) ) .OR. ;
         File( cPath := ( hb_DirBase() + cFile ) )
#endif
         cFile := cPath
      ELSE
         RETURN Nil
      ENDIF
   ELSEIF !File( cFile )
      RETURN Nil
   ENDIF

   cPath := StrTran( Memoread( cPath ), Chr(13), "" )
   IF l2Line
      RETURN StrTran( cPath, Chr(10), " " )
   ENDIF

   RETURN cPath

#ifdef __PLATFORM__UNIX
STATIC FUNCTION _RunApp( cLine, cOut )
   RETURN hwg_RunConsoleApp( cLine + " 2>&1",, @cOut )
#else
STATIC FUNCTION _RunApp( cLine, cOut )
   RETURN hwg_RunConsoleApp( cLine,, @cOut )
#endif

STATIC FUNCTION _ShowProgress( cText, nAct, cTitle, cFull )

#ifdef __CONSOLE
   HB_SYMBOL_UNUSED( cFull )
   IF !lQ .OR. nAct == 2 .OR. "warning" $ Lower(cText) .OR. "error" $ Lower(cText)
      IF !Empty( cTitle )
         OutStd( "*** " + cTitle + " *** " + hb_eol() )
      ENDIF
      IF nAct == 2
         OutStd( "=== " + cText + " ===" + hb_eol() )
      ELSE
         OutStd( cText + hb_eol() )
      ENDIF
   ENDIF
#else

   IF cFull != Nil
      IF !Empty( cTitle )
         cFull += "*** " + cTitle + " *** " + hb_eol()
      ENDIF
      IF nAct == 2
         cFull += "=== " + cText + " ===" + hb_eol()
      ELSE
         cFull += cText + hb_eol()
      ENDIF
   ENDIF

   IF nAct == 1
      IF !Empty( oDlgBar ) .AND. !Empty( cTitle )
         oDlgBar:oBoard:oSay:SetText( cTitle )
         PBar( 1 )
      ENDIF
      hb_gcStep()
   ELSEIF nAct == 2
      PBar( 2 )
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
   hwg_MsgStop( cText, Iif( Empty(cTitle), "HwBuilder", cTitle ) )
#endif
   RETURN Nil

STATIC FUNCTION _MsgInfo( cText, cTitle )

#ifdef __CONSOLE
   IF !Empty( cTitle )
      OutStd( hb_eol() + cTitle )
   ENDIF
   OutStd( hb_eol() + cText )
#else
   hwg_MsgInfo( cText, Iif( Empty(cTitle), "HwBuilder", cTitle ) )
#endif
   RETURN Nil

STATIC FUNCTION _PS( cPath )

   RETURN Iif( !Empty( cPath ), Iif( lUnix .AND. '\' $ cPath, StrTran( cPath, '\', '/' ), ;
      Iif( !lUnix .AND. '/' $ cPath, StrTran( cPath, '/', '\' ), cPath ) ), cPath )

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
      {"bcc", "bcc32.exe", "\lib\win\bcc", "-c -d -w -O2", "-Gn -aa -Tpe", "-Gn -ap", "", ;
         "hbvm.lib", "hwgui.lib", ;
         "{path}\bcc32.exe {f} -I{hi} -I{gi} -o{obj} {src}", ;
         "{path}\brc32 -r {src} -fo{out}", ;
         "{path}\tlib {f} {out} {objs}", ;
         "{path}\ilink32 {f} -L{hL} -L{gL} {dL} c0w32.obj {objs}, {out},, {libs},, {res}", ;
         "", "", "", "", "ws2_32.lib cw32.lib import32.lib iphlpapi.lib" }, ;
      {"mingw", "gcc.exe", "\lib\win\mingw", "-c -Wall", "-Wall -mwindows", "-Wall", "", ;
         "libhbvm.a", "libhwgui.a", ;
         "{path}\gcc {f} -I{hi} -I{gi} -o{obj} {src}", ;
         "{path}\windres {src} {out}.o", ;
         "{path}\ar rc {f} {out} {objs}", ;
         "{path}\gcc {f} -o{out} {objs} {res} -L{hL} -L{gL} {dL} -Wl,--allow-multiple-definition -Wl,--start-group {libs} -Wl,--end-group", ;
         ".o", ".a", "-l{l}", "lib{l}.a", ;
         "-luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdiplus -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lws2_32 -lwsock32 -liphlpapi" }, ;
      {"msvc", "cl.exe", "\lib\win\msvc", "/TP /W3 /nologo /c", "-SUBSYSTEM:WINDOWS", "", "", ;
         "hbvm.lib", "hwgui.lib", ;
         "cl.exe {f} /I{hi} /I{gi} /Fo{obj} {src}", ;
         "rc -fo {out}.res {src}", ;
         "lib {f} /out:{out} {objs}", ;
         "link {f} /LIBPATH:{hL} /LIBPATH:{gL} {dL} {objs} {res} {libs}", "", "", "", "", ;
         "user32.lib gdi32.lib comdlg32.lib shell32.lib comctl32.lib winspool.lib advapi32.lib winmm.lib ws2_32.lib iphlpapi.lib OleAut32.Lib Ole32.Lib" }, ;
      {"gcc", "gcc", "/lib/linux/gcc", "-c -Wall -Wunused `pkg-config --cflags gtk+-2.0`", ;
         "`pkg-config --libs gtk+-2.0`", "", "", "libhbvm.a", "libhwgui.a", ;
         "gcc {f} -I{hi} -I{gi} -o{obj} {src}", ;
         "", ;
         "ar rc {f} {out} {objs}", ;
         "gcc {objs} -o{out} -L{hL} -L{gL} {dL} -Wl,--start-group {libs} -Wl,--end-group {f}", ;
         ".o", ".a", "-l{l}", "lib{l}.a", "-lm -lz -lpcre -ldl" } }
   //,, hwgui_xp.res
   CLASS VAR aList       SHARED INIT {}

   DATA id
   DATA family           INIT ""
   DATA cPath            INIT ""
   DATA cPathInc         INIT ""
   DATA cPathLib         INIT ""
   DATA cPathHrbLib      INIT ""
   DATA cFlags           INIT ""
   DATA cLinkFlagsGui    INIT ""
   DATA cLinkFlagsCons   INIT ""
   DATA cLinkFlagsLib    INIT ""
   DATA cObjExt          INIT ".obj"
   DATA cLibExt          INIT ".obj"
   DATA cSysLibs         INIT ""

   DATA cCmdComp         INIT ""
   DATA cCmdRes          INIT ""
   DATA cCmdLinkLib      INIT ""
   DATA cCmdLinkExe      INIT ""
   DATA cTmplLib         INIT "{l}.lib"
   DATA cBinLib          INIT "{l}.lib"

   DATA aEnv             INIT {}

   DATA lPath            INIT .F.
   DATA lPathHrbLib      INIT .F.
   DATA lFlags           INIT .F.
   DATA lLinkFlagsGui    INIT .F.
   DATA lLinkFlagsLib    INIT .F.
   DATA lSysLibs         INIT .F.

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
      ::cLinkFlagsGui := HCompiler():aDef[nDef,COMP_LFLAGSG]
      ::cLinkFlagsCons := HCompiler():aDef[nDef,COMP_LFLAGSC]
      ::cLinkFlagsLib := HCompiler():aDef[nDef,COMP_LFLAGSL]
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
      IF !Empty( cTmp := HCompiler():aDef[nDef,COMP_OBJEXT] )
         ::cObjExt  := cTmp
      ENDIF
      IF !Empty( cTmp := HCompiler():aDef[nDef,COMP_LIBEXT] )
         ::cLibExt  := cTmp
      ENDIF
   ENDIF

   AAdd( ::aList, Self )

   RETURN Self

CLASS HGuilib

   CLASS VAR aList       SHARED INIT {}
   DATA id
   DATA cPath      INIT ""
   DATA cPathInc   INIT ""
   DATA cPathLib   INIT ""
   DATA cLibs      INIT ""

   METHOD New( id )

ENDCLASS

METHOD New( id )

   ::id := id

   IF id == "hwgui"
      ::cLibs := "hwgui hbxml procmisc"
   ENDIF

   AAdd( ::aList, Self )

   RETURN Self

CLASS HwProject

   DATA cFile
   DATA aFiles     INIT {}
   DATA oComp
   DATA cGtLib
   DATA cLibsDop   INIT ""
   DATA cLibsPath  INIT ""
   DATA cFlagsPrg  INIT ""
   DATA cFlagsC    INIT ""
   DATA cOutPath, cOutName, cObjPath
   DATA lLib       INIT .F.
   DATA lMake      INIT .F.

   DATA cDefFlagsC INIT Nil
   DATA cDefFlagsL INIT Nil
   DATA cDefFlagsLib INIT Nil

   DATA aProjects  INIT {}

   METHOD New( aFiles, oComp, cGtLib, cLibsDop, cLibsPath, cFlagsPrg, cFlagsC, ;
      cOutName, cObjPath, lLib, lMake )
   METHOD Open( xSource, oComp, aUserPar )
   METHOD Build( lClean )

ENDCLASS

METHOD New( aFiles, oComp, cGtLib, cLibsDop, cLibsPath, cFlagsPrg, cFlagsC, ;
      cOutName, cObjPath, lLib, lMake ) CLASS HwProject

   IF PCount() > 1
      ::aFiles := aFiles
      ::oComp  := oComp
      ::cGtLib    := cGtLib
      ::cLibsDop  := Iif( Empty( cLibsDop ) , "", cLibsDop )
      IF !Empty( cGtLib )
         //::cLibsDop := Iif( Empty( cLibsDop ), cGtLib, cLibsDop + " " + cGtLib )
         ::cFlagsPrg += " -d__" + Upper( cGtLib ) + "__"
      ENDIF
      ::cLibsPath := Iif( Empty(cLibsPath), "", cLibsPath )
      ::cFlagsPrg := Iif( Empty(cFlagsPrg), "", cFlagsPrg )
      ::cFlagsC   := Iif( Empty(cFlagsC), "", cFlagsC )
      IF !Empty( cOutName )
         ::cOutName := hb_fnameNameExt( cOutName )
         IF Len( ::cOutName ) < Len( cOutName )
            ::cOutPath := Left( cOutName, Len( cOutName ) - Len( ::cOutName ) - 1 )
         ENDIF
      ENDIF
      ::cObjPath  := cObjPath
      ::lLib  := lLib
      ::lMake := lMake
   ENDIF

   RETURN Self

METHOD Open( xSource, oComp, aUserPar ) CLASS HwProject

   LOCAL arr, i, j, n, l, lYes, nPos, af, ap, o, oGui
   LOCAL cLine, cTmp, cTmp2, cSrcPath := "", lLib

   IF Empty( oComp )
      oComp := HCompiler():aList[1]
   ENDIF

   IF Valtype( xSource ) == "A"
      arr := AClone( xSource )
   ELSEIF Chr(10) $ xSource
      arr := hb_Atokens( xSource, Chr(10) )
   ELSEIF !File( xSource )
      _MsgStop( xSource + " not found", "Wrong file" )
      RETURN Nil
   ELSE
      ::cFile := xSource
      arr := hb_Atokens( Memoread( xSource ), Chr(10) )
   ENDIF
   FOR i := 1 TO Len( arr )
      IF !Empty( cLine := AllTrim( StrTran( arr[i], Chr(13), "" ) ) ) .AND. !( Left( cLine, 1 ) == "#" )
         DO WHILE Left( cLine,1 ) == '{'
            IF ( nPos := At( "}", cLine ) ) > 0
               cTmp := AllTrim( Substr( cLine, 2, nPos-2 ) )
               l := .T.
               IF Left( cTmp,1 ) == "!"
                  cTmp := LTrim( Substr( cTmp,2 ) )
                  l := .F.
               ENDIF
               lYes := ( ( cTmp == "unix" .AND. lUnix ) .OR. ;
                  ( cTmp == "win" .AND. !lUnix ) .OR. oComp:family == cTmp .OR. oComp:id == cTmp .OR. ;
                  ( !Empty( aUserPar ) .AND. hb_Ascan( aUserPar,cTmp,,,.T. ) > 0 ) )
               IF !l
                  lYes := !lYes
               ENDIF
               IF lYes
                  cLine := LTrim( Substr( cLine, nPos + 1 ) )
               ELSE
                  cLine := ""
                  EXIT
               ENDIF
            ELSE
               _MsgStop( cLine, "Wrong option" )
               RETURN Nil
            ENDIF
         ENDDO
         IF Empty( cLine )
            LOOP
         ENDIF
         IF ( nPos := At( "=", cLine ) ) > 0
            IF ( cTmp := Lower( Left( cLine, nPos-1 ) ) ) == "srcpath"
               cSrcPath := _DropSlash( Substr( cLine, nPos + 1 ) ) + hb_ps()

            ELSEIF cTmp == "def_cflags"
               ::cDefFlagsC := Substr( cLine, nPos + 1 )

            ELSEIF cTmp == "def_lflags"
               ::cDefFlagsL := Substr( cLine, nPos + 1 )

            ELSEIF cTmp == "def_libflags"
               ::cDefFlagsLib := Substr( cLine, nPos + 1 )

            ELSEIF cTmp == "prgflags"
               ::cFlagsPrg += ( Iif( Empty(::cFlagsPrg), "", " " ) + Substr( cLine, nPos + 1 ) )

            ELSEIF cTmp == "cflags"
               ::cFlagsC += ( Iif( Empty(::cFlagsC), "", " " ) + Substr( cLine, nPos + 1 ) )

            ELSEIF cTmp == "gtlib"
               ::cGtLib := Substr( cLine, nPos + 1 )

            ELSEIF cTmp == "libs"
               ::cLibsDop += Iif( Empty(::cLibsDop), "", " " ) + Substr( cLine, nPos + 1 )

            ELSEIF cTmp == "libspath"
               ::cLibsPath := _DropSlash( Substr( cLine, nPos + 1 ) )

            ELSEIF cTmp == "outpath"
               ::cOutPath := _DropSlash( Substr( cLine, nPos + 1 ) )

            ELSEIF cTmp == "outname"
               ::cOutName := Substr( cLine, nPos + 1 )

            ELSEIF cTmp == "objpath"
               ::cObjPath := _DropSlash( Substr( cLine, nPos + 1 ) )

            ELSEIF cTmp == "target"
               ::lLib := Substr( cLine, nPos + 1 ) == "lib"

            ELSEIF cTmp == "makemode"
               ::lMake := ( cTmp := Lower( Substr( cLine, nPos + 1 ) ) ) == "on" .OR. cTmp == "yes"

            ELSEIF cTmp == "c_compiler"
               cTmp := Substr( cLine, nPos + 1 )
               IF ( j := Ascan( HCompiler():aList, {|o|o:id == cTmp} ) ) > 0
                  ::oComp := HCompiler():aList[j]
               ELSE
                  _MsgStop( cLine, "Wrong compiler id" )
                  RETURN Nil
               ENDIF
            ELSEIF cTmp == "guilib"
               cTmp := Substr( cLine, nPos + 1 )
               IF ( j := Ascan( HGuilib():aList, {|o|o:id == cTmp} ) ) > 0
                  oGui := HGuilib():aList[j]
                  cGuiId := oGui:id
                  cPathHwgui := _EnvVarsTran(oGui:cPath)
                  cPathHwguiInc := _EnvVarsTran(oGui:cPathInc)
                  cPathHwguiLib := _EnvVarsTran(oGui:cPathLib)
                  cLibsHwGUI := oGui:cLibs
               ENDIF

            ELSE
               _MsgStop( cLine, "Wrong option" )
               RETURN Nil
            ENDIF

         ELSEIF Left( cLine,1 ) == '@'
            cTmp := _AddFromFile( Substr( cLine,2 ), .F. )
            ap := hb_ATokens( cTmp, Chr(10) )
            n := i + 1
            FOR j := 1 TO Len( ap )
               IF !Empty( ap[j] )
                  hb_AIns( arr, n, ap[j], .T. )
                  n ++
               ENDIF
            NEXT

         ELSEIF Left( cLine,1 ) == ':'
            IF Left( cLine,8 ) == ':project'
               ap := {}
               DO WHILE ++i <= Len( arr ) .AND. !Left( Ltrim(_DropBr(arr[i])),8 ) == ':project'
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
               IF Empty( o:cFlagsPrg ) .AND. !Empty( ::cFlagsPrg )
                  o:cFlagsPrg := ::cFlagsPrg
               ENDIF
               IF Empty( o:cFlagsC ) .AND. !Empty( ::cFlagsC )
                  o:cFlagsC := ::cFlagsC
               ENDIF
               IF Empty( o:cDefFlagsC ) .AND. !Empty( ::cDefFlagsC )
                  o:cDefFlagsC := ::cDefFlagsC
               ENDIF
               IF Empty( o:cDefFlagsL ) .AND. !Empty( ::cDefFlagsL )
                  o:cDefFlagsL := ::cDefFlagsL
               ENDIF
               IF Empty( o:cDefFlagsLib ) .AND. !Empty( ::cDefFlagsLib )
                  o:cDefFlagsLib := ::cDefFlagsLib
               ENDIF
            ELSE
               _MsgStop( cLine, "Wrong option" )
               RETURN Nil
            ENDIF

         ELSE
            IF ( nPos := At( " ", cLine ) ) > 0
               cTmp := Left( cLine, nPos - 1 )
               cTmp2 := AllTrim( Substr( cLine, nPos + 1 ) )
            ELSE
               cTmp := cLine
               cTmp2 := Nil
            ENDIF
            IF '*' $ cTmp
               ap := Nil
               IF !Empty( cTmp2 ) .AND. ( nPos := At( "-(", cTmp2 ) ) > 0 .AND. ;
                  ( j := hb_At( ")", cTmp2, nPos ) ) > 0
                  ap := hb_aTokens( Substr( cTmp2, nPos+2, j-nPos-2 ), ' ' )
                  cTmp2 := AllTrim( Left( cTmp2, nPos-1 ) + Substr( cTmp2, j+1 ) )
               ENDIF
               af := hb_Directory( cSrcPath + cTmp )
               FOR j := 1 TO Len( af )
                  IF Empty( ap ) .OR. hb_AScan( ap, af[j,1],,, .T. ) == 0
                     AAdd( ::aFiles, { cSrcPath+af[j,1], cTmp2 } )
                  ENDIF
               NEXT
            ELSE
               AAdd( ::aFiles, { Iif( Empty( cSrcPath ) .AND. Empty( hb_fnameDir(cTmp) ), ;
                  cTmp, cSrcPath + cTmp ), cTmp2 } )
            ENDIF

         ENDIF
      ENDIF
   NEXT

   IF !Empty( ::cGtLib )
      //::cLibsDop := Iif( Empty( ::cLibsDop ), ::cGtLib, ::cLibsDop + " " + ::cGtLib )
      ::cFlagsPrg += " -d__" + Upper( ::cGtLib ) + "__"
   ENDIF

   IF !Empty( ::aProjects ) .AND. Empty( ::aFiles ) .AND. !::lLib
      lLib := .T.
      FOR i := 1 TO Len( ::aProjects )
         IF !::aProjects[i]:lLib
            lLib := .F.
            EXIT
         ENDIF
      NEXT
      ::lLib := lLib
   ENDIF
   IF Empty( ::aFiles ) .AND. Empty( ::aProjects )
      _MsgStop( "Source files missing", "Project error" )
      RETURN Nil
   ENDIF

   ::oComp := oComp

   RETURN Self

METHOD Build( lClean, lSub ) CLASS HwProject

   LOCAL i, cCmd, cComp, cLine, cOut, cFullOut := "", lErr := .F., to, tc
   LOCAL cObjs := "", cFile, cBinary, cObjFile, cObjPath, lGuiApp := .T.
   LOCAL aLibs, cLibs := "", a4Delete := {}, tStart := hb_DtoT( Date(), Seconds()-1 )
   LOCAL aEnv, cResFile := "", cResList := ""
   LOCAL cCompPath, cCompHrbLib

   IF Empty( lClean ) .AND. !Empty( cLine := CheckOptions( Self ) )
      _MsgStop( cLine + hb_eol() + "Check your hwbuild.ini", "Wrong options" )
      FPaths()
      RETURN Nil
   ENDIF

   FOR i := 1 TO Len( ::aProjects )
      cFullOut += ::aProjects[i]:Build( lClean, .T. )
   NEXT
   IF Empty( ::aFiles )
      IF !Empty( cFullOut )
         ShowResult( cFullOut )
      ENDIF
      RETURN ""
   ENDIF

   IF !Empty( ::cObjPath )
      cObjPath := ::cObjPath + hb_ps() + ::oComp:id
      IF !hb_DirExists( cObjPath )
         hb_DirBuild( cObjPath )
      ENDIF
      cObjPath := _PS( cObjPath ) + hb_ps()
   ELSE
      cObjPath := ""
   ENDIF

   IF !Empty( lClean )
      FOR i := 1 TO Len( ::aFiles )
         IF Lower( hb_fnameExt( ::aFiles[i,1] )) == ".prg"
            FErase( cObjPath + hb_fnameName( ::aFiles[i,1] ) + ".c" )
         ENDIF
         FErase( cObjPath + hb_fnameName( ::aFiles[i,1] ) + ::oComp:cObjExt )
      NEXT
      cBinary := Iif( Empty( ::cOutName ), hb_fnameNameExt( ::aFiles[1,1] ), ::cOutName )
      IF ::lLib
         cBinary := Iif( Empty(::cOutPath), "", ::cOutPath+hb_ps() ) + StrTran( ::oComp:cBinLib, "{l}", cBinary )
      ELSE
         cBinary := Iif( Empty(::cOutPath), "", ::cOutPath+hb_ps() ) + hb_fnameExtSet( cBinary, cExeExt )
      ENDIF
      FErase( cBinary )
      _MsgInfo( "Cleaned" )
      RETURN ""
   ENDIF

   IF !Empty( ::cOutPath := _PS(::cOutPath) ) .AND. !hb_DirExists( ::cOutPath )
      hb_DirBuild( ::cOutPath )
   ENDIF

   IF !Empty( ::cGtLib )
      IF !( ::cGtLib $ "gttrm;gtwvt;gtxwc;gtwvg;gtwvw;gthwg" )
         lGuiApp := .F.
      ENDIF
   ENDIF

   FOR i := 1 TO Len( ::aFiles )
      IF !( cFile := Lower( hb_fnameExt(::aFiles[i,1]) ) ) == ".prg" .AND. !( cFile == ".c" ) ;
         .AND. !( cFile == ::oComp:cObjExt ) .AND. !( cFile == ".rc" )
         _MsgStop( "Wrong source file extention", hb_fnameNameExt(::aFiles[i,1]) )
         RETURN ""
      ENDIF
   NEXT

#ifndef __CONSOLE
   IF lProgressOn
      to := 0
      FOR i := 1 TO Len( ::aFiles )
         IF ( cFile := Lower( hb_fnameExt( ::aFiles[i,1] )) ) == ".prg"
            to += 2
         ELSEIF cFile == ".c" .OR. cFile == "rc"
            to ++
         ENDIF
      NEXT
      PBar( 0, to )
   ENDIF
#endif
   cCompPath := _EnvVarsTran( ::oComp:cPath )
   cCompHrbLib := _EnvVarsTran( ::oComp:cPathHrbLib )

   // Compile prg sources with Harbour
   IF !Empty( ::oComp:aEnv )
      aEnv := Array( Len(::oComp:aEnv),2 )
      FOR i := 1 TO Len( ::oComp:aEnv )
         aEnv[i,1] := ::oComp:aEnv[i,1]
         aEnv[i,2] := getenv( aEnv[i,1] )
         hb_setenv( ::oComp:aEnv[i,1], ::oComp:aEnv[i,2] )
      NEXT
   ENDIF
   cCmd := _EnvVarsTran(cPathHrbBin) + hb_ps() + "harbour " + cHrbDefFlags + ;
      " -i" + _EnvVarsTran(cPathHrbInc) + ;
      " -i" + cPathHwguiInc + Iif( Empty( ::cFlagsPrg ), "", " " + ::cFlagsPrg ) + ;
      Iif( Empty( cObjPath ), "", " -o" + cObjPath )
   FOR i := 1 TO Len( ::aFiles )
      cFile := _PS( ::aFiles[i,1] )
      IF Lower( hb_fnameExt( cFile )) == ".prg"
         cObjFile := cObjPath + hb_fnameName( cFile ) + ".c"
         IF ::lMake .AND. File( cObjFile ) .AND. hb_vfTimeGet( cObjFile, @to ) .AND. ;
            hb_vfTimeGet( cFile, @tc ) .AND. to >= tc
         ELSE
            cLine := cCmd + Iif( Empty( ::aFiles[i,2] ), "", " " + ::aFiles[i,2] ) + " " + cFile

            _ShowProgress( "> " + cLine, 1, hb_fnameNameExt( cFile ), @cFullOut )
            _RunApp( cLine, @cOut )
            IF Valtype( cOut ) != "C"
               EXIT
            ENDIF
            _ShowProgress( cOut, 1,, @cFullOut )
            IF "Error" $ cOut
               lErr := .T.
               EXIT
            ENDIF

         ENDIF
         ::aFiles[i,1] := cObjFile
         ::aFiles[i,2] := Nil
         IF !::lMake
            AAdd( a4Delete, ::aFiles[i,1] )
         ENDIF
      ENDIF
   NEXT

   IF !lErr
      // Compile C sources with C compiler
      cOut := Nil
      cCmd := StrTran( StrTran( StrTran( ::oComp:cCmdComp, "{hi}", _EnvVarsTran(cPathHrbInc) ), ;
         "{gi}", cPathHwguiInc ), "{path}", cCompPath )

      FOR i := 1 TO Len( ::aFiles )
         cFile := _PS( ::aFiles[i,1] )
         IF Lower( hb_fnameExt( cFile )) == ".c"
            cObjFile := cObjPath + hb_fnameName( cFile ) + ::oComp:cObjExt
            IF ::lMake .AND. File( cObjFile ) .AND. hb_vfTimeGet( cObjFile, @to ) .AND. ;
               hb_vfTimeGet( cFile, @tc ) .AND. to >= tc
            ELSE
               cLine := StrTran( StrTran( StrTran( cCmd, "{obj}", cObjFile ), ;
                  "{src}", cFile ), ;
                  "{f}", Iif( ::cDefFlagsC==Nil, ::oComp:cFlags, ::cDefFlagsC ) + ;
                  Iif( Empty( ::cFlagsC ), "", " " + ::cFlagsC ) + ;
                  Iif( Empty( ::aFiles[i,2] ), "", " " + ::aFiles[i,2] ) )

               _ShowProgress( "> " + cLine, 1, hb_fnameNameExt(cFile), @cFullOut )
               _RunApp( cLine, @cOut )
               IF Valtype( cOut ) != "C"
                  EXIT
               ENDIF
               _ShowProgress( cOut, 1,, @cFullOut )
               IF _HasError( cOut )
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

#ifndef __PLATFORM__UNIX
   IF !lErr
      // Compile resource files
      cOut := Nil
      IF !Empty( ::oComp:cCmdRes ) .AND. Empty( ::cGtLib )
         IF File( cPathHwgui + "\image\WindowsXP.Manifest" )
            cLine := '1 24 "' + cPathHwgui + '\image\WindowsXP.Manifest"'
            cResFile := "hwgui_xp.res"
            IF ::oComp:family == "mingw"
               cLine := Strtran( cLine, '\', '/' )
               cResFile := "hwgui_xp.o"
            ENDIF
            hb_MemoWrit( "hwgui_xp.rc", cLine )
            cLine := StrTran( StrTran( StrTran( ::oComp:cCmdRes, "{path}", cCompPath ), ;
            "{src}", "hwgui_xp.rc" ), "{out}", "hwgui_xp" )
            _ShowProgress( "> " + cLine, 1,, @cFullOut)
            _RunApp( cLine, @cOut )
            IF Valtype( cOut ) == "C"
               _ShowProgress( cOut, 1,, @cFullOut )
               AAdd( a4Delete, "hwgui_xp.rc" )
               AAdd( a4Delete, cResFile )
               cResList += cResFile
            ENDIF
         ENDIF

         FOR i := 1 TO Len( ::aFiles )
            cFile := _PS( ::aFiles[i,1] )
            IF Lower( hb_fnameExt( cFile )) == ".rc"
               cLine := StrTran( StrTran( StrTran( ::oComp:cCmdRes, "{path}", cCompPath ), ;
                  "{src}", cFile ), "{out}", hb_fnameName( cFile ) + ;
                  Iif( ::oComp:family == "mingw", "_rc", "" ) )
               _ShowProgress( "> " + cLine, 1,, @cFullOut)
               _RunApp( cLine, @cOut )
               IF Valtype( cOut ) == "C"
                  _ShowProgress( cOut, 1,, @cFullOut )
                  cResFile := hb_fnameName( cFile ) + Iif( ::oComp:family == "mingw", "_rc.o", ".res" )
                  AAdd( a4Delete, cResFile )
                  cResList += " " + cResFile
               ENDIF
            ENDIF
         NEXT
      ENDIF
   ENDIF
#endif

   IF !lErr
      // Link the app
      cBinary := Iif( Empty( ::cOutName ), hb_fnameNameExt( ::aFiles[1,1] ), ::cOutName )
      cOut := Nil
      aLibs := hb_ATokens( cLibsHwGUI, " " )
      FOR i := 1 TO Len( aLibs )
         cLibs += " " + StrTran( ::oComp:cTmplLib, "{l}", aLibs[i] )
      NEXT
      IF !Empty( ::cGtLib )
         cLibs += " " + StrTran( ::oComp:cTmplLib, "{l}", ::cGtLib )
      ENDIF
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
         cLine := StrTran( StrTran( StrTran( StrTran( ::oComp:cCmdLinkLib, "{out}", cBinary ), ;
            "{objs}", Iif( ::oComp:family == "bcc", StrTran( cObjs, " ", " +" ), cObjs ) ), ;
            "{path}", cCompPath ), "{f}", Iif( ::cDefFlagsLib == Nil, ::oComp:cLinkFlagsLib, ::cDefFlagsLib ) )
      ELSE
         cBinary := Iif( Empty(::cOutPath), "", ::cOutPath+hb_ps() ) + hb_fnameExtSet( cBinary, cExeExt )
         cLine := StrTran( StrTran( StrTran( StrTran( StrTran( StrTran( StrTran( StrTran( StrTran( ;
             ::oComp:cCmdLinkExe, "{out}", cBinary ), "{objs}", cObjs ), "{path}", cCompPath ), ;
             "{f}", Iif( ::cDefFlagsL == Nil, Iif( lGuiApp, ::oComp:cLinkFlagsGui, ;
             ::oComp:cLinkFlagsCons ), ::cDefFlagsL ) ), ;
             "{hL}", cCompHrbLib ), "{gL}", cPathHwguiLib ), ;
             "{dL}", Iif( Empty(::cLibsPath), "", Iif(::oComp:family=="msvc","/LIBPATH:","-L") + ::cLibsPath ) ), ;
             "{libs}", cLibs + " " + ::oComp:cSysLibs ), "{res}", cResList )
         IF ::oComp:family == "bcc"
            AAdd( a4Delete, hb_fnameExtSet( cBinary, "tds" ) )
            AAdd( a4Delete, hb_fnameExtSet( cBinary, "map" ) )
         ENDIF
      ENDIF

      _ShowProgress( "> " + cLine, 1, hb_fnameNameExt(cBinary), @cFullOut )
      FErase( cBinary )
      _RunApp( cLine, @cOut )
      IF Valtype( cOut ) == "C"
         _ShowProgress( cOut, 1,, @cFullOut )
      ENDIF

      cLine := Iif( File( cBinary ) .AND. hb_vfTimeGet( cBinary, @to ) .AND. to > tStart, ;
         cBinary + " " + "created successfully!", "Error. Can't create " + cBinary )
      _ShowProgress( cLine, 2,, @cFullOut )
   ELSE
      _ShowProgress( "Error...", 2,, @cFullOut )
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
