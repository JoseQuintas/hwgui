/*
 * $Id$
 *
 * HWGUI runner
 *
 * Copyright 2013 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 */

#include "hwgui.ch"
#include "hrbextern.ch"
#include "hwgextern.ch"

#ifndef __PLATFORM__WINDOWS
#define DIR_SEP         '/'
#else
#define DIR_SEP         '\'
#endif

STATIC cHwg_include_dir, cHrb_inc_dir, cMod_dir

FUNCTION _APPMAIN( cFileName, cPar1, cPar2, cPar3, cPar4, cPar5, cPar6, cPar7, cPar8, cPar9 )

   LOCAL cExt, xRetVal, cHrbName, aHrbs, i

   IF Empty( cFileName )
      hwg_Msginfo( "Harbour Runner - HwGUI version" + hb_Eol() +;
              "Copyright 1999-2023, http://www.harbour-project.org" + hb_Eol() +;
              Version() + ",  " + hwg_Version() + hb_Eol() +;
              hb_Eol() +;
              "Syntax:  hwgrun <hrbfile[.hrb|.prg]> [parameters]" )

   ELSE
      ReadIni( FilePath( hb_ArgV( 0 ) ) )
      IF Empty( hb_fnameExt( cFileName ) )
         cFileName += ".prg"
      ENDIF
      IF !File( cFileName )
         IF !Empty( hb_fnameDir( cFileName ) ) .OR. Empty( cMod_dir ) .OR. ;
            !File( cFileName := hb_DirBase() + cMod_dir + cFileName )
            hwg_Msgstop( "Can't find " + hb_fnameName( cFileName ) )
            RETURN Nil
         ENDIF
      ENDIF
      IF ( cExt := Lower( hb_fnameExt( cFileName ) ) ) == ".prg"
#ifndef __XHARBOUR__
         IF !Empty( cHrbName := FCompile( cFileName ) )
            xRetVal := hb_hrbRun( cHrbName, cPar1, cPar2, cPar3, cPar4, cPar5, cPar6, cPar7, cPar8, cPar9 )
         ENDIF
#endif
      ELSEIF cExt == ".hwg"
#ifndef __XHARBOUR__
         IF !Empty( aHrbs := FList( cFileName ) )
            IF Len( aHrbs ) == 1
               xRetVal := hb_hrbRun( aHrbs[1], cPar1, cPar2, cPar3, cPar4, cPar5, cPar6, cPar7, cPar8, cPar9 )
            ELSE
               FOR i := Len( aHrbs ) TO 1 STEP -1
                 aHrbs[i] := hb_hrbLoad( aHrbs[i] )
                 hb_hrbDo( aHrbs[i] )
               NEXT
            ENDIF
         ENDIF
#endif
      ELSE
         xRetVal := hb_hrbRun( cFileName, cPar1, cPar2, cPar3, cPar4, cPar5, cPar6, cPar7, cPar8, cPar9 )
      ENDIF
   ENDIF

   RETURN xRetVal

#ifndef __XHARBOUR__

STATIC FUNCTION FList( cFileName )

   LOCAL aFiles := hb_Atokens( Memoread( cFileName ), Chr(10) ), i, cExt
   LOCAL s := "", cFile, aCompileOpt := {}, aHrbs := {}

   FOR i := 1 TO Len( aFiles )
      IF !Empty( cFile := AllTrim( StrTran( aFiles[i], Chr(13), "" ) ) ) .AND. !( Left( cFile, 1 ) == "#" )
         IF Left( cFile, 1 ) == "-"
            AAdd( aCompileOpt, "/" + Substr(cFile,2) )
         ELSEIF ( cExt := Lower( hb_fnameExt( cFile ) ) ) == ".prg"
            IF i < Len( aFiles ) .AND. Left( aFiles[i+1], 1 ) == "+"
               s += MemoRead( cFile ) + hb_eol()
            ELSE
               IF Left( cFile, 1 ) == "+"
                  cFile := Ltrim( Substr(cFile,2) )
                  cFileName := Iif( Empty(cMod_dir), hb_FNameExtSet( cFile, ".prg_" ), ;
                     cMod_dir + hb_FnameName( cFile ) + ".prg_" )
                  hb_Memowrit( cFileName, s )
                  IF !Empty( cFileName := FCompile( cFileName, aCompileOpt ) )
                     AAdd( aHrbs, cFileName )
                  ELSE
                     RETURN Nil
                  ENDIF
               ELSE
                  IF !Empty( cFileName := FCompile( cFile, aCompileOpt ) )
                     AAdd( aHrbs, cFileName )
                  ELSE
                     RETURN Nil
                  ENDIF
               ENDIF
            ENDIF
         ELSEIF cExt == ".hrb"
            AAdd( aHrbs, cFile )
         ENDIF
      ENDIF
   NEXT
   IF !Empty( s )
      cFileName := Iif( Empty(cMod_dir), hb_FNameExtSet( cFileName, ".prg_" ), ;
         cMod_dir + hb_FnameName( cFileName ) + ".prg_" )
      hb_Memowrit( cFileName, s )
      IF !Empty( cFileName := FCompile( cFileName, aCompileOpt ) )
         AAdd( aHrbs, cFileName )
      ENDIF
   ENDIF

   RETURN aHrbs

STATIC FUNCTION FCompile( cFileName, aCompileOpt )

   LOCAL cHrbName := Iif( Empty( cMod_dir ), hb_FNameExtSet( cFileName, ".hrb" ), ;
      cMod_dir + hb_fnameName( cFileName ) + ".hrb" )
   LOCAL cFileErr := hb_DirTemp() + "hwg_compile_err.out", cTemp
   LOCAL cIncPath, lCompile := .T., cHrb, aParams, i, ie
   LOCAL tHrb, tPrg

   IF File( cHrbName )
      hb_vfTimeGet( cHrbName, @tHrb )
      hb_vfTimeGet( cFileName, @tPrg )
      lCompile := ( tPrg > tHrb )
   ENDIF

   IF lCompile
      IF Empty( cHwg_include_dir ) .OR. !File( cHwg_include_dir + DIR_SEP + "hwgui.ch" )
         hwg_MsgStop( "Set correct path to HwGUI headers in hwgrun.xml", "Hwgui.ch isn't found" )
         RETURN Nil
      ENDIF
      cIncPath := cHwg_include_dir + Iif( Empty(cHrb_inc_dir), "", ;
            hb_OsPathListSeparator() + cHrb_inc_dir )

      aParams := { "harbour", cFileName, "/n", "/w", "/I"+cIncPath }
      IF !Empty( aCompileOpt )
         FOR i := 1 TO Len( aCompileOpt )
            AAdd( aParams, aCompileOpt[i] )
         NEXT
      ENDIF

      i := hwg_rediron( 1, hb_DirTemp() + "hwg_compile.out" )
      ie := hwg_rediron( 2, cFileErr )
      cHrb := hb_compileBuf( hb_ArrayToParams( aParams ) )
      hwg_rediroff( 2, ie )
      hwg_rediroff( 1, i )
      cTemp := MemoRead( cFileErr )
      ie := .T.
      IF !Empty( cTemp ) .AND. ( ( " Warning " $ cTemp ) .OR. ( " Error " $ cTemp ) )
         ie := ShowErr( cTemp )
      ENDIF
      IF Empty( cHrb ) .OR. !ie
         hwg_MsgStop( "Error while compiling " + cFileName )
         RETURN Nil
      ENDIF
   ENDIF

   hb_Memowrit( cHrbName, cHrb )

   RETURN cHrbName
#endif

STATIC FUNCTION ReadIni( cPath )
   LOCAL oIni, oInit, i, oNode1

   oIni := HXMLDoc():Read( cPath + "hwgrun.xml" )
   IF !Empty( oIni:aItems ) .AND. oIni:aItems[1]:title == "init"
      oInit := oIni:aItems[1]
      FOR i := 1 TO Len( oInit:aItems )
         oNode1 := oInit:aItems[i]
         IF oNode1:title == "hwgui_inc"
            cHwg_include_dir := oNode1:GetAttribute( "path",,"" )
         ELSEIF oNode1:title == "harbour_inc"
            cHrb_inc_dir := oNode1:GetAttribute( "path",,"" )
         ELSEIF oNode1:title == "modules"
            cMod_dir := oNode1:GetAttribute( "path",,"" )
         ENDIF
      NEXT
   ENDIF

   RETURN Nil

STATIC FUNCTION ShowErr( cMess )

   LOCAL oDlg, oEdit, lErr := ( " Error " $ cMess ), lRes := .F.
   LOCAL oFont := HFont():Add( "Georgia", 0, - 15 )

   INIT DIALOG oDlg TITLE "Error.log" At 92, 61 SIZE 500, 500 FONT oFont

   @ 4, 4 HCEDIT oEdit SIZE 492, 440 ON SIZE {|o,x,y|o:Move( ,, x-8, y-60 ) }
   IF hwg__isUnicode()
      oEdit:lUtf8 := .T.
   ENDIF
   oEdit:SetText( cMess )

   IF lErr
      @ 200, 460 BUTTON "Close" ON CLICK { || hwg_EndDialog() } SIZE 100, 32 ;
         ON SIZE ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS
   ELSE
      @ 50, 460 BUTTON "Run anyway" ON CLICK { || lRes := .T., hwg_EndDialog() } SIZE 100, 32 ;
         ON SIZE ANCHOR_BOTTOMABS
      @ 350, 460 BUTTON "Cancel" ON CLICK { || hwg_EndDialog() } SIZE 100, 32 ;
         ON SIZE ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS
   ENDIF

   ACTIVATE DIALOG oDlg CENTER

   RETURN lRes

INIT PROCEDURE FInit

   IF hwg__isUnicode()
      hb_cdpSelect( "UTF8" )
   ENDIF
   RETURN
