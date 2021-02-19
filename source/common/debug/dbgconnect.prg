/*
 * $Id$
 */

/*
 * HWGUI - Harbour Win32 GUI library source code:
 * The Debugger
 *
 * Copyright 2013 Alexander Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version, with one exception:
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA (or visit the web site http://www.gnu.org/).
 *
 * As a special exception, the Harbour Project gives permission for
 * additional uses of the text contained in its release of Harbour.
 *
 * The exception is that, if you link the Harbour libraries with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the Harbour library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the Harbour
 * Project under the name Harbour.  If you copy code from other
 * Harbour Project or Free Software Foundation releases into a copy of
 * Harbour, as the General Public License permits, the exception does
 * not apply to the code that you add in this way.  To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for Harbour, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 *
 */

#include "fileio.ch"

#define DEBUG_PROTO_VERSION     3

#define CMD_GO                  1
#define CMD_STEP                2
#define CMD_TRACE               3
#define CMD_NEXTR               4
#define CMD_TOCURS              5
#define CMD_QUIT                6
#define CMD_EXIT                7
#define CMD_BADD                8
#define CMD_BDEL                9
#define CMD_CALC               10
#define CMD_STACK              11
#define CMD_LOCAL              12
#define CMD_PRIVATE            13
#define CMD_PUBLIC             14
#define CMD_STATIC             15
#define CMD_WATCH              16
#define CMD_WADD               17
#define CMD_WDEL               18
#define CMD_AREAS              19
#define CMD_REC                20
#define CMD_OBJECT             21
#define CMD_ARRAY              22

#ifdef __XHARBOUR__
#xtranslate HB_AT([<n,...>]) =>  AT(<n>)
#xtranslate HB_PROGNAME([<n,...>]) =>  EXENAMEX(<n>)
#xtranslate HB_PROCESSOPEN([<n,...>]) =>  HB_OPENPROCESS(<n>)
#xtranslate HB_DIRTEMP([<n,...>]) =>  ""
#endif

Static lDebugRun := .F., handl1, handl2, cBuffer
Static nId1 := -1, nId2 := 0

Function hwg_dbg_New()
   Local i, nPos, arr, cCmd, cDir, cFile := hb_Progname()
   Local cDebugger := "hwgdebug", cExe
   Local lRun
   Local hProcess

   cBuffer := Space( 1024 )

   IF File( cDebugger+".info" ) .AND. ( handl1 := FOpen( cDebugger+".info", FO_READ ) ) != -1
      i := FRead( handl1, @cBuffer, Len( cBuffer ) )
      IF i > 0
         arr := hb_aTokens( Left( cBuffer,i ), ;
               Iif( hb_At( Chr(13),cBuffer,1,i ) > 0, Chr(13)+Chr(10), Chr(10) ) )
         FOR i := 1 TO Len( arr )
            IF ( nPos := At( "=", arr[i] ) ) > 0
               cCmd := Lower( Trim( Left( arr[i],nPos-1 ) ) )
               IF cCmd == "dir"
                  cDir := Ltrim( Substr( arr[i], nPos+1 ) )
               ELSEIF cCmd == "debugger"
                  cExe := Ltrim( Substr( arr[i], nPos+1 ) )
               ELSEIF cCmd == "runatstart"
                  __Dbg():lRunAtStartup := ( Lower( Alltrim( Substr( arr[i], nPos+1 ) ) ) == "on" )
               ENDIF
            ENDIF
         NEXT
      ENDIF
      FClose( handl1 )
   ENDIF

   IF File( cFile + ".d1" ) .AND. File( cFile + ".d2" )
   
      IF ( handl1 := FOpen( cFile + ".d1", FO_READ + FO_SHARED ) ) != -1
         i := FRead( handl1, @cBuffer, Len( cBuffer ) )
         IF ( i > 0 ) .AND. ;
               Left( cBuffer,4 ) == "init"
            handl2 := FOpen( cFile + ".d2", FO_READWRITE + FO_SHARED )
            IF handl2 != -1
               lDebugRun := .T.
               Return Nil
            ENDIF
         ENDIF      
         FClose( handl1 )
      ENDIF
    
   ENDIF

   IF !Empty( cDir)
      cDir += Iif( Right( cDir,1 ) $ "\/", "", hb_OsPathSeparator() )
      IF File( cDir + cDebugger + ".d1" ) .AND. File( cDir + cDebugger + ".d2" )
         IF ( handl1 := FOpen( cDir + cDebugger + ".d1", FO_READ + FO_SHARED ) ) != -1
            i := FRead( handl1, @cBuffer, Len( cBuffer ) )
            IF ( i  > 0 ) .AND. ;
                  Left( cBuffer,4 ) == "init"
               handl2 := FOpen( cDir + cDebugger + ".d2", FO_READWRITE + FO_SHARED )
               IF handl2 != -1
                  lDebugRun := .T.
                  Return Nil
               ENDIF
            ENDIF
            FClose( handl1 )
         ENDIF
      ENDIF
   ENDIF

   cFile := Iif( !Empty( cDir), cDir, hb_dirTemp() ) + ;
         Iif( ( i := Rat( '\', cFile ) ) = 0, ;
         Iif( ( i := Rat( '/', cFile ) ) = 0, cFile, Substr( cFile, i + 1 ) ), ;
         Substr( cFile, i + 1 ) )

   Ferase( cFile + ".d1" )
   Ferase( cFile + ".d2" )

   handl1 := FCreate( cFile + ".d1" )
   FClose( handl1 )
   handl2 := FCreate( cFile + ".d2" )
   FClose( handl2 )

#ifndef __PLATFORM__WINDOWS
   IF Empty( cExe )
      cExe := Iif( File(cDebugger), "./", "" ) + cDebugger
   ENDIF
   // lRun := __dbgProcessRun( cExe, "-c" + cFile )
   hProcess := hb_processOpen( cExe + ' -c' + cFile )
   lRun := ( hProcess != -1 .AND. hb_processValue( hProcess, .F. ) == -1 )
#else
   IF Empty( cExe )
      cExe := cDebugger
   ENDIF
   hProcess := hb_processOpen( cExe + ' -c"' + cFile + '"' )
   lRun := ( hProcess  > 0 )
#endif
   IF !lRun
      hwg_dbg_Alert( cExe + " isn't available..." )
   ELSE
      handl1 := FOpen( cFile + ".d1", FO_READ + FO_SHARED )
      handl2 := FOpen( cFile + ".d2", FO_READWRITE + FO_SHARED )
      IF handl1 != -1 .AND. handl2 != -1
         lDebugRun := .T.
      ELSE
         hwg_dbg_Alert( "Can't open connection..." )
      ENDIF
   ENDIF
   
Return Nil

Static Function hwg_dbg_Read()
Local n, s := "", arr

   FSeek( handl1, 0, 0 )
   DO WHILE ( n := Fread( handl1, @cBuffer, Len(cBuffer) ) ) > 0
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

Static Function hwg_dbg_Send( ... )
Local arr := hb_aParams(), i, s := ""

   FSeek( handl2, 0, 0 )
   FOR i := 2 TO Len( arr )
      s += arr[i] + ","
   NEXT
   IF Len( s ) > 800
      FWrite( handl2, "!," + Space( Len(arr[1])-1 ) + s + arr[1] + ",!" )
      FSeek( handl2, 0, 0 )
      FWrite( handl2, arr[1] + "," )
   ELSE
      FWrite( handl2, arr[1] + "," + s + arr[1] + ",!" )
   ENDIF

Return Nil


Function hwg_dbg_SetActiveLine( cPrgName, nLine, aStack, aVars, aWatch, nVarType )
Local i, s := cPrgName + "," + Ltrim(Str(nLine)), nLen

   IF !lDebugRun ; Return Nil; ENDIF

   IF nId2 == 0
      s += ",ver," + Ltrim(Str(DEBUG_PROTO_VERSION))
   ENDIF
   IF aStack != Nil
      s += ",stack"
      nLen := Len( aStack )
      FOR i := 1 TO nLen
         s += "," + aStack[i]
      NEXT
   ENDIF
   IF aVars != Nil
      s += Iif( nVarType==1, ",valuelocal,", ;
            Iif( nVarType==2, ",valuepriv,", Iif( nVarType==3, ",valuepubl,", ",valuestatic," ) ) ) + aVars[1]
      nLen := Len( aVars )
      FOR i := 2 TO nLen
         s += "," + Str2Hex(aVars[i])
      NEXT
   ENDIF
   IF aWatch != Nil
      s += ",valuewatch," + aWatch[1]
      nLen := Len( aWatch )
      FOR i := 2 TO nLen
         s += "," + Str2Hex(aWatch[i])
      NEXT
   ENDIF

   hwg_dbg_Send( "a"+Ltrim(Str(++nId2)), s  )

Return Nil

Function hwg_dbg_Wait( nWait )

     * Parameters not used
    HB_SYMBOL_UNUSED(nWait)

   IF !lDebugRun ; Return Nil; ENDIF

Return Nil

Function hwg_dbg_Input( p1, p2, p3 )
Local n, cmd, arr

   IF !lDebugRun ; Return CMD_GO; ENDIF

   DO WHILE .T.

      IF !Empty( arr := hwg_dbg_Read() )
         IF ( n := Val( arr[1] ) ) > nId1 .AND. arr[Len(arr)] == "!"
            nId1 := n
            IF arr[2] == "cmd"
               IF ( cmd := arr[3] ) == "go"
                  Return CMD_GO
               ELSEIF cmd == "step"
                  Return CMD_STEP
               ELSEIF cmd == "trace"
                  Return CMD_TRACE
               ELSEIF cmd == "nextr"
                  Return CMD_NEXTR
               ELSEIF cmd == "to"
                  p1 := arr[4]
                  p2 := Val( arr[5] )
                  Return CMD_TOCURS
               ELSEIF cmd == "quit"
                  Return CMD_QUIT
               ELSEIF cmd == "exit"
                  lDebugRun := .F.
                  Return CMD_EXIT
               ENDIF
            ELSEIF arr[2] == "brp"
               IF arr[3] == "add"
                  p1 := arr[4]
                  p2 := Val( arr[5] )
                  Return CMD_BADD
               ELSEIF arr[3] == "del"
                  p1 := arr[4]
                  p2 := Val( arr[5] )
                  Return CMD_BDEL
               ENDIF
            ELSEIF arr[2] == "watch"
               IF arr[3] == "add"
                  p1 := Hex2Str( arr[4] )
                  Return CMD_WADD
               ELSEIF arr[3] == "del"
                  p1 := Val( arr[4] )
                  Return CMD_WDEL
               ENDIF
            ELSEIF arr[2] == "exp"
               p1 := Hex2Str( arr[3] )
               Return CMD_CALC
            ELSEIF arr[2] == "view"
               IF arr[3] == "stack"
                  p1 := arr[4]
                  Return CMD_STACK
               ELSEIF arr[3] == "local"
                  p1 := arr[4]
                  Return CMD_LOCAL
               ELSEIF arr[3] == "priv"
                  p1 := arr[4]
                  Return CMD_PRIVATE
               ELSEIF arr[3] == "publ"
                  p1 := arr[4]
                  Return CMD_PUBLIC
               ELSEIF arr[3] == "static"
                  p1 := arr[4]
                  Return CMD_STATIC
               ELSEIF arr[3] == "watch"
                  p1 := arr[4]
                  Return CMD_WATCH
               ELSEIF arr[3] == "areas"
                  Return CMD_AREAS
               ENDIF
            ELSEIF arr[2] == "insp"
               IF arr[3] == "rec"
                  p1 := arr[4]
                  Return CMD_REC
               ELSEIF arr[3] == "obj"
                  p1 := arr[4]
                  Return CMD_OBJECT
               ELSEIF arr[3] == "arr"
                  p1 := arr[4]
                  p2 := arr[5]
                  p3 := arr[6]
                  Return CMD_ARRAY
               ENDIF
            ENDIF
            hwg_dbg_Send( "e"+Ltrim(Str(++nId2)) )
         ENDIF
      ENDIF
      hb_ReleaseCpu()

   ENDDO

Return 0

Function hwg_dbg_Answer( ... )
Local arr := hb_aParams(), i, j, s := "", lConvert

   IF !lDebugRun ; Return Nil; ENDIF

   FOR i := 1 TO Len( arr )
      IF Valtype( arr[i] ) == "A"
         lConvert := ( i > 1 .AND. Valtype(arr[i-1]) == "C" .AND. Left( arr[i-1],5 ) == "value" )
         FOR j := 1 TO Len( arr[i] )
            s += Iif( j>1.AND.lConvert, Str2Hex(arr[i,j]), arr[i,j] ) + ","
         NEXT
      ELSE
         IF arr[i] == "value" .AND. i < Len( arr )
            s += arr[i] + "," + Str2Hex( arr[++i] ) + ","
         ELSE
            s += arr[i] + ","
         ENDIF
      ENDIF
   NEXT
   hwg_dbg_Send( "b"+Ltrim(Str(nId1)), Left( s,Len(s)-1 ) )

Return Nil

Function hwg_dbg_Msg( cMessage )

     * Parameters not used
    HB_SYMBOL_UNUSED(cMessage)

   IF !lDebugRun ; Return Nil; ENDIF

Return Nil

Function hwg_dbg_Alert( cMessage )
Local bCode := &( Iif( Type( "hwg_msginfo()" ) == "UI", "{|s|hwg_msginfo(s)}", ;
       Iif( Type( "msginfo()" ) == "UI", "{|s|msginfo(s)}", "{|s|alert(s)}" ) ) )

   Eval( bCode, cMessage )
Return Nil

Function hwg_dbg_Quit()
Local cCode, bCode

   IF Type( "hwg_endwindow()" ) == "UI"
      cCode := "{||hwg_endwindow()"
      IF Type( "hwg_Postquitmessage()" ) == "UI"
         cCode += ",hwg_Postquitmessage(),__Quit()}"
      ELSEIF Type( "hwg_gtk_exit()" ) == "UI"
         cCode += ",hwg_gtk_exit(),__Quit()}"
      ELSE
         cCode += ",__Quit()}"
      ENDIF
   ELSEIF Type( "ReleaseAllWindows()" ) == "UI"
      cCode := "{||ReleaseAllWindows()}"
   ELSE
      cCode := "{||__Quit()}"
   ENDIF

   bCode := &( cCode )
Return Eval( bCode )

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

EXIT PROCEDURE hwg_dbg_exit

   hwg_dbg_Send( "quit" )
   FClose( handl1 )
   FClose( handl2 )
Return

#ifdef __XHARBOUR__
#ifndef __PLATFORM__WINDOWS
FUNCTION EXENAMEX()
   RETURN HB_ARGV( 0 )
#endif
#ifdef __PLATFORM__WINDOWS
#pragma BEGINDUMP

#include "hbapi.h"
#include "windows.h"
HB_FUNC(EXENAMEX)
{
   char szBuffer[ MAX_PATH + 1 ] = {0} ;

   GetModuleFileName( ISNIL(1) ? GetModuleHandle( NULL ) : (HMODULE) hb_parnl( 1 ), szBuffer ,MAX_PATH );

   hb_retc( szBuffer );
}


#pragma enddump
#endif
#endif
