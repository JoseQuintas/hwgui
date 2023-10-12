/*
 * $Id$
 *
 * HWGUI runner
 *
 * Copyright 2013 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 */

#include "hrbextern.ch"
#include "hwgextern.ch"

#ifndef __PLATFORM__WINDOWS
#define DIR_SEP         '/'
#else
#define DIR_SEP         '\'
#endif

STATIC cHwg_include_dir, cHrb_inc_dir, cMod_Dir

FUNCTION _APPMAIN( cFileName, cPar1, cPar2, cPar3, cPar4, cPar5, cPar6, cPar7, cPar8, cPar9 )

   LOCAL cInitPath := FilePath( hb_ArgV( 0 ) ), cIncPath, cExt
   LOCAL xRetVal, cHrbName

   IF Empty( cFileName )
      hwg_Msginfo( "Harbour Runner - HwGUI version" + hb_Eol() +;
              "Copyright 1999-2023, http://www.harbour-project.org" + hb_Eol() +;
              Version() + ",  " + hwg_Version() + hb_Eol() +;
              hb_Eol() +;
              "Syntax:  hwgrun <hrbfile[.hrb|.prg]> [parameters]" )

   ELSE
      ReadIni( cInitPath )
      IF Empty( hb_fnameExt( cFileName ) )
         cFileName += ".prg"
      ENDIF
      IF !File( cFileName )
         IF !Empty( hb_fnameDir( cFileName ) ) .OR. Empty( cMod_Dir ) .OR. ;
            !File( cFileName := hb_DirBase() + cMod_Dir + cFileName )
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
      ELSEIF cExt == ".lst"
#ifndef __XHARBOUR__
         IF !Empty( cFileName := FList( cFileName ) )
            IF !Empty( cHrbName := FCompile( cFileName ) )
               xRetVal := hb_hrbRun( cHrbName, cPar1, cPar2, cPar3, cPar4, cPar5, cPar6, cPar7, cPar8, cPar9 )
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
   LOCAL s := ""

   FOR i := Len( aFiles ) TO 1 STEP -1
      IF !Empty( cFileName := AllTrim( StrTran( aFiles[i], Chr(13), "" ) ) )
         IF ( cExt := Lower( hb_fnameExt( cFileName ) ) ) == ".prg"
            s += MemoRead( cFileName ) + hb_ps()
         ELSE
            aFiles[i] := hb_hrbLoad( cFileName )
            hb_hrbDo( aFiles[i] )
         ENDIF
      ENDIF
   NEXT
   IF !Empty( s )
      cFileName := "__" + hb_FNameExtSet( cFileName, ".prg" )
      hb_Memowrit( cFileName, s )
      RETURN cFileName
   ENDIF

   RETURN Nil

STATIC FUNCTION FCompile( cFileName )

   LOCAL cHrbName := hb_FNameExtSet( cFileName, ".hrb" )
   LOCAL lCompile := .T., cHrb
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

      IF Empty( cHrb := hb_compileBuf( "harbour", cFileName, "/n","/I"+cIncPath ) )
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

INIT PROCEDURE FInit

   IF hwg__isUnicode()
      hb_cdpSelect( "UTF8" )
   ENDIF
   RETURN
