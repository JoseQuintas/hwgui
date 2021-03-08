/*
 * $Id$
 *
 * HWGUI runner
 *
 * Copyright 2013 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 */

#include "hwgextern.ch"

EXTERNAL DBCREATE, DBUSEAREA, DBCREATEINDEX, DBSEEK, DBCLOSEAREA, DBSELECTAREA, DBUNLOCK, DBUNLOCKALL
EXTERNAL BOF, EOF, DBF, DBAPPEND, DBCLOSEALL, DBCLOSEAREA, DBCOMMIT,DBCOMMITALL, DBCREATE
EXTERNAL DBDELETE, DBFILTER, DBSETFILTER, DBGOBOTTOM, DBGOTO, DBGOTOP, DBRLOCK, DBRECALL, DBDROP, DBEXISTS
EXTERNAL DBRLOCKLIST, DBRUNLOCK, LOCK, RECNO,  DBSETFILTER, DBFILEGET, DBFILEPUT, FIELDBLOCK
EXTERNAL DBSKIP, DBSTRUCT, DBTABLEEXT, DELETED, DBINFO, DBORDERINFO, DBRECORDINFO
EXTERNAL ORDNUMBER, ORDKEY, ORDNAME, ORDSETFOCUS, ORDBAGNAME, ORDCONDSET, ORDKEYNO, ORDKEYCOUNT
EXTERNAL FCOUNT, FIELDDEC, FIELDGET, FIELDNAME, FIELDLEN, FIELDPOS, FIELDPUT
EXTERNAL FIELDTYPE, FLOCK, FOUND, HEADER, LASTREC, LUPDATE, NETERR, AFIELDS
EXTERNAL RECCOUNT, RECSIZE, SELECT, ALIAS, RLOCK
EXTERNAL __DBZAP, USED, RDDSETDEFAULT, __DBPACK, __DBAPP, __DBCOPY, __DBLOCATE, __DBCONTINUE, __SETFORMAT
EXTERNAL DBFCDX, DBFFPT
EXTERNAL FOPEN, FCLOSE, FSEEK, FREAD, FWRITE, FERASE, DIRECTORY, CURDIR
EXTERNAL HB_BITAND, HB_BITOR, HB_BITSHIFT
EXTERNAL HB_ATOKENS
EXTERNAL ASORT, ASCAN, OS
EXTERNAL HB_CODEPAGE_RU866, HB_CODEPAGE_RU1251, HB_CODEPAGE_RUKOI8, HB_CODEPAGE_UTF8

#ifndef __PLATFORM__WINDOWS
#define DIR_SEP         '/'
#else
#define DIR_SEP         '\'
#endif

STATIC cHwg_include_dir, cHrb_inc_dir, cMod_Dir

FUNCTION _APPMAIN( cFileName, cPar1, cPar2, cPar3, cPar4, cPar5, cPar6, cPar7, cPar8, cPar9 )

   LOCAL cInitPath := FilePath( hb_ArgV( 0 ) ), cIncPath
   LOCAL xRetVal, cHrb, cPath, cHrbName, lExt, lCompile
   LOCAL tHrb, tPrg

   IF Empty( cFileName )
      hwg_Msginfo( "Harbour Runner - HwGUI version" + hb_Eol() +;
              "Copyright 1999-2020, http://www.harbour-project.org" + hb_Eol() +;
              Version() + ",  " + hwg_Version() + hb_Eol() +;
              hb_Eol() +;
              "Syntax:  hwgrun <hrbfile[.hrb]> [parameters]" )

   ELSE
      ReadIni( cInitPath )
      IF !( lExt := !Empty( hb_fnameExt( cFileName ) ) )
         cFileName += ".prg"
      ENDIF
      IF !File( cFileName )
         IF !Empty( hb_fnameDir( cFileName ) ) .OR. Empty( cMod_Dir ) .OR. ;
            !File( cFileName := hb_DirBase() + cMod_Dir + cFileName )
            hwg_Msgstop( "Can't find " + hb_fnameName( cFileName ) )
            RETURN Nil
         ENDIF
      ENDIF
      cPath := hb_fnameDir( cFileName )
      IF Lower( hb_fnameExt( cFileName ) ) == ".prg"
#ifndef __XHARBOUR__
         cHrbName := cPath + hb_fnameName( cFileName ) + ".hrb"
         lCompile := .T.
         IF !lExt .AND. File( cHrbName )
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
         xRetVal := hb_hrbRun( cHrbName, cPar1, cPar2, cPar3, cPar4, cPar5, cPar6, cPar7, cPar8, cPar9 )
#endif
      ELSE
         xRetVal := hb_hrbRun( cFileName, cPar1, cPar2, cPar3, cPar4, cPar5, cPar6, cPar7, cPar8, cPar9 )
      ENDIF
   ENDIF

   RETURN xRetVal

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
