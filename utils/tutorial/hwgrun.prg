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

#ifdef __PLATFORM__UNIX
#define DIR_SEP         '/'
#else
#define DIR_SEP         '\'
#endif

STATIC cHwg_include_dir, cHrb_inc_dir

FUNCTION _APPMAIN( cHRBFile, cPar1, cPar2, cPar3, cPar4, cPar5, cPar6, cPar7, cPar8, cPar9 )
   LOCAL xRetVal, cHrb, cInitPath := FilePath( hb_ArgV( 0 ) ), cIncPath

   IF hwg__isUnicode()
      hb_cdpSelect( "UTF8" )
   ENDIF

   IF Empty( cHRBFile )
      hwg_Msginfo( "Harbour Runner - HwGUI version" + HB_OSNewLine() +;
              "Copyright 1999-2016, http://www.harbour-project.org" + HB_OSNewLine() +;
              Version() + ",  " + hwg_Version() + HB_OSNewLine() +;
              HB_OSNewLine() +;
              "Syntax:  hbrun <hrbfile[.hrb]> [parameters]" )

   ELSE
      IF Lower( Right( cHRBFile,4 ) ) == ".prg"
#ifndef __XHARBOUR__
         ReadIni( cInitPath )
         IF Empty( cHwg_include_dir ) .OR. !File( cHwg_include_dir + DIR_SEP + "hwgui.ch" )
            hwg_MsgStop( "Set correct path to HwGUI headers in hwgrun.xml", "Hwgui.ch isn't found" )
            RETURN Nil
         ENDIF
         cIncPath := cHwg_include_dir + Iif( Empty(cHrb_inc_dir), "", ;
               hb_OsPathListSeparator() + cHrb_inc_dir )

         IF Empty( cHrb := hb_compileBuf( "harbour", cHRBFile, "/n","/I"+cIncPath ) )
            hwg_MsgStop( "Error while compiling " + cHRBFile )
         ELSE
            hb_Memowrit( "__tmp.hrb", cHrb )
            xRetVal := hb_hrbRun( "__tmp.hrb", cPar1, cPar2, cPar3, cPar4, cPar5, cPar6, cPar7, cPar8, cPar9 )
         ENDIF
#endif
      ELSE
         xRetVal := hb_hrbRun( cHRBFile, cPar1, cPar2, cPar3, cPar4, cPar5, cPar6, cPar7, cPar8, cPar9 )
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
         ENDIF
      NEXT
   ENDIF

   RETURN Nil
