/*
 * $Id$
 */

/*
 * Harbour Project source code:
 * The Debugger
 *
 * Copyright 1999 Antonio Linares <alinares@fivetechsoft.com>
 * Copyright 2003-2006 Phil Krylov <phil@newstar.rinet.ru>
 * Copyright 2013 Alexander Kresin <alex@kresin.ru>
 * www - http://harbour-project.org
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
/*
 * ALTD() debuger function
 *
 * Copyright 2003 Przemyslaw Czerpak <druzus@acn.waw.pl>
 * www - http://www.xharbour.org
 */

#pragma DEBUGINFO=OFF

#define HB_CLS_NOTOBJECT      /* do not inherit from HBObject calss */
#include "hbclass.ch"

#include "hbdebug.ch"   /* for "nMode" of __dbgEntry */
#include "hbmemvar.ch"

#include "inkey.ch"
#include "set.ch"

   /* Information structure stored in DATA aCallStack */
#define CSTACK_MODULE           1  // module name (.prg file)
#define CSTACK_FUNCTION         2  // function name
#define CSTACK_LINE             3  // start line
#define CSTACK_LEVEL            4  // eval stack level of the function
#define CSTACK_LOCALS           5  // an array with local variables
#define CSTACK_STATICS          6  // an array with static variables

/* Information structure stored in aCallStack[ n ][ CSTACK_LOCALS ]
   { cLocalName, nLocalIndex, "Local", ProcName( 1 ), nLevel } */
#define VAR_NAME                1
#define VAR_POS                 2
#define VAR_TYPE                3
#define VAR_LEVEL               4  // eval stack level of the function

   /* Information structure stored in ::aWatch (watchpoints) */
#define WP_TYPE                 1  // wp = watchpoint, tr = tracepoint
#define WP_EXPR                 2  // source of an expression

   /* Information structure stored in ::aModules */
#define MODULE_NAME             1
#define MODULE_STATICS          2
#define MODULE_GLOBALS          3
#define MODULE_EXTERNGLOBALS    4

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

#define VAR_MAX_LEN            72

#ifndef __XHARBOUR__
   THREAD STATIC t_oDebugger
#else
   STATIC t_oDebugger
#endif

#ifdef __XHARBOUR__
#xtranslate __DBGADDBREAK([<n,...>]) =>  HB_DBG_ADDBREAK(<n>)
#xtranslate __DBGDELBREAK([<n,...>]) =>  HB_DBG_DELBREAK(<n>)
#xtranslate __DBGADDWATCH([<n,...>]) =>  HB_DBG_ADDWATCH(<n>)
#xtranslate __DBGDELWATCH([<n,...>]) =>  HB_DBG_DELWATCH(<n>)
#xtranslate __DBGISVALIDSTOPLINE([<n,...>]) =>  HB_DBG_ISVALIDSTOPLINE(<n>)
#xtranslate __DBGSETTOCURSOR([<n,...>]) =>  HB_DBG_SETTOCURSOR(<n>)
#xtranslate __DBGSETTRACE([<n,...>]) =>  HB_DBG_SETTRACE(<n>)
#xtranslate __DBGSETNEXTROUTINE([<n,...>]) =>  HB_DBG_SETNEXTROUTINE(<n>)
#xtranslate __DBGSETCBTRACE([<n,...>]) =>  HB_DBG_SETCBTRACE(<n>)
#xtranslate __DBGGETEXPRVALUE([<n,...>]) =>  HB_DBG_GETEXPRVALUE(<n>)
#xtranslate __DBGGETSOURCEFILES([<n,...>]) =>  HB_DBG_GETSOURCEFILES(<n>)
#xtranslate __DBGSETQUIT([<n,...>]) =>  HB_DBG_SETQUIT(<n>)
#xtranslate __DBGSETGO([<n,...>]) =>  HB_DBG_SETGO(<n>)
#xtranslate __DBGSETENTRY([<n,...>]) =>  HB_DBG_SETENTRY(<n>)

#xtranslate __DBGVMVARLSET([<n,...>]) =>  HB_DBG_VMVARLSET(<n>)
#xtranslate __DBGVMVARLGET([<n,...>]) =>  HB_DBG_VMVARLGET(<n>)
#xtranslate __DBGVMVARSGET([<n,...>]) =>  HB_DBG_VMVARSGET(<n>)
#xtranslate __DBGVMVARSSET([<n,...>]) =>  HB_DBG_VMVARSSET(<n>)
#xtranslate __DBGVMVARGGET([<n,...>]) =>  HB_DBG_VMVARGGET(<n>)
#xtranslate __DBGVMVARGSET([<n,...>]) =>  HB_DBG_VMVARGSET(<n>)
#xtranslate __DBGPROCLEVEL([<n,...>]) =>  HB_DBG_PROCLEVEL(<n>)
#xtranslate __DBGINVOKEDEBUG([<n,...>]) =>  HB_DBG_INVOKEDEBUG(<n>)

#xtranslate hb_ntos([<n,...>]) =>  Ltrim(Str((<n>)))
#endif

PROCEDURE __dbgAltDEntry()

   /* do not activate the debugger imediatelly because the module
      where ALTD() was called can have no debugger info - stop
      on first LINE with debugged info
    */

   __dbgInvokeDebug( Set( _SET_DEBUG ) )

   RETURN

   /* debugger entry point */

PROCEDURE __dbgEntry( nMode, uParam1, uParam2, uParam3, uParam4, uParam5 )

   LOCAL lStartup

   DO CASE
   CASE nMode == HB_DBG_GETENTRY

      __dbgSetEntry()

   CASE nMode == HB_DBG_ACTIVATE

      IF ( lStartup := ( t_oDebugger == NIL ) )
         t_oDebugger := HBDebugger():New()
         t_oDebugger:pInfo := uParam1
      ENDIF
      t_oDebugger:nProcLevel := uParam2
      t_oDebugger:aCallStack := uParam3
      t_oDebugger:aModules := uParam4
      t_oDebugger:aBreakPoints := uParam5
      IF lStartup
         IF !t_oDebugger:lRunAtStartup
            __dbgSetGo( uParam1 )
            RETURN
         ENDIF
      ENDIF
      t_oDebugger:lGo := .F.
      t_oDebugger:Activate()

   ENDCASE

   RETURN

CLASS HBDebugger

   VAR pInfo

   VAR cPrgName

   VAR aVars             INIT {}
   VAR aBreakPoints      INIT {}
   VAR aCallStack        INIT {}    // stack of procedures with debug info
   VAR aProcStack        INIT {}    // stack of all procedures
   VAR nProcLevel                   // procedure level where the debugger is currently
   VAR aModules          INIT {}    // array of modules with static and GLOBAL variables
   VAR nWatches          INIT 0

   VAR nSpeed            INIT 0

   VAR lViewStack        INIT .F.
   VAR lShowLocals       INIT .F.
   VAR lShowPrivate      INIT .F.
   VAR lShowPublic       INIT .F.
   VAR lShowStatic       INIT .F.
   VAR lShowWatch        INIT .F.
   VAR lGo                          // stores if GO was requested
   VAR lActive           INIT .F.
   VAR lCBTrace          INIT .T.   // stores if codeblock tracing is allowed
   VAR lRunAtStartup     INIT .T.

   METHOD New()
   METHOD Activate()

   METHOD CodeblockTrace()
   METHOD GetExprValue( xExpr, lValid )
   METHOD GetSourceFiles()

   METHOD GO()
   METHOD HandleEvent()
   METHOD LoadCallStack()

   METHOD QUIT()
   METHOD ShowCodeLine( nProc )

   METHOD VarGetInfo( aVar )
   METHOD VarGetValue( aVar )
   METHOD VarSetValue( aVar, uValue )

ENDCLASS

METHOD New() CLASS HBDebugger

   t_oDebugger := Self

   // Init Debugger Window
   hwg_dbg_New()

   ::lGo := ::lRunAtStartup

   RETURN Self

METHOD Activate() CLASS HBDebugger

   ::LoadCallStack()

   IF ! ::lActive
      ::lActive := .T.
   ENDIF

   // show the topmost procedure
   ::ShowCodeLine( 1 )
   ::HandleEvent()

   RETURN NIL

METHOD CodeblockTrace()

   __dbgSetCBTrace( ::pInfo, ::lCBTrace )

   RETURN NIL

METHOD GetExprValue( xExpr, lValid ) CLASS HBDebugger

   LOCAL xResult
   LOCAL bOldError, oErr

   lValid := .F.

   bOldError := ErrorBlock( { |oErr|Break( oErr ) } )
   BEGIN SEQUENCE
      xResult := __dbgGetExprValue( ::pInfo, xExpr, @lValid )
      IF ! lValid
         xResult := "Syntax error"
      ENDIF
   RECOVER USING oErr
      xResult := oErr:operation + ": " + oErr:description
      IF HB_ISARRAY( oErr:args )
         xResult += "; arguments:"
         AEval( oErr:args, { | x | xResult += " " + AllTrim( __dbgValToStr( x ) ) } )
      ENDIF
      lValid := .F.
   END SEQUENCE
   ErrorBlock( bOldError )

   RETURN xResult

METHOD GetSourceFiles() CLASS HBDebugger

   RETURN __dbgGetSourceFiles( ::pInfo )

METHOD GO() CLASS HBDebugger

   __dbgSetGo( ::pInfo )

   RETURN NIL

METHOD HandleEvent() CLASS HBDebugger

   LOCAL nKey, p1, p2, p3, xResult, nAt

   DO WHILE .T.

      nKey := hwg_dbg_Input( @p1, @p2, @p3 )

      DO CASE
      CASE nKey == CMD_QUIT
         t_oDebugger:Quit()
         RETURN NIL

      CASE nKey == CMD_EXIT
         ::Go()
         RETURN NIL

      CASE nKey == CMD_GO
         ::Go()
         RETURN NIL

      CASE nKey == CMD_STEP
         RETURN NIL

      CASE nKey == CMD_TRACE
         __dbgSetTrace( ::pInfo )
         RETURN NIL

      CASE nKey == CMD_NEXTR
         __dbgSetNextRoutine( ::pInfo )
         RETURN NIL

      CASE nKey == CMD_TOCURS
         IF __dbgIsValidStopLine( ::pInfo, p1, p2 )
            __dbgSetToCursor( ::pInfo, p1, p2 )
            RETURN NIL
         ELSE
            hwg_dbg_SetActiveLine( ".", 0 )
         ENDIF

      CASE nKey == CMD_BADD
         IF __dbgIsValidStopLine( ::pInfo, p1, p2 )
            AAdd( ::aBreakPoints, { p2, p1 } )
            hwg_dbg_Answer( "line", LTrim( Str(p2 ) ) )
            __dbgAddBreak( ::pInfo, p1, p2 )
         ELSE
            hwg_dbg_Answer( "err" )
         ENDIF

      CASE nKey == CMD_BDEL
         IF ( nAt := AScan( ::aBreakPoints, { |a|a[1] == p2 .AND. a[2] == p1 } ) ) == 0
            hwg_dbg_Answer( "err" )
         ELSE
            ADel( ::aBreakPoints, nAt )
            ASize( ::aBreakPoints, Len( ::aBreakPoints ) - 1 )
            hwg_dbg_Answer( "ok", LTrim( Str(p2 ) ) )
            __dbgDelBreak( ::pInfo, nAt - 1 )
         ENDIF

      CASE nKey == CMD_WADD
         __dbgAddWatch( ::pInfo, p1, .F. )
         ::nWatches ++
         hwg_dbg_Answer( "valuewatch", SendWatch() )

      CASE nKey == CMD_WDEL
         __dbgDelWatch( ::pInfo, p1 - 1 )
         IF -- ::nWatches > 0
            hwg_dbg_Answer( "valuewatch", SendWatch() )
         ELSE
            hwg_dbg_Answer( "ok" )
         ENDIF

      CASE nKey == CMD_STACK
         IF p1 == "on"
            ::lViewStack := .T.
            hwg_dbg_Answer( "stack", SendStack() )
         ELSE
            ::lViewStack := .F.
            hwg_dbg_Answer( "ok" )
         ENDIF

      CASE nKey == CMD_LOCAL
         IF p1 == "on"
            ::lShowLocals := .T.
            ::lShowStatic := ::lShowPrivate := ::lShowPublic := .F.
            hwg_dbg_Answer( "valuelocal", SendLocal() )
         ELSE
            ::lShowStatic := ::lShowLocals := ::lShowPrivate := ::lShowPublic := .F.
            hwg_dbg_Answer( "ok" )
         ENDIF

      CASE nKey == CMD_PRIVATE
         IF p1 == "on"
            ::lShowPrivate := .T.
            ::lShowStatic := ::lShowLocals := ::lShowPublic := .F.
            hwg_dbg_Answer( "valuepriv", SendPrivate() )
         ELSE
            ::lShowStatic := ::lShowLocals := ::lShowPrivate := ::lShowPublic := .F.
            hwg_dbg_Answer( "ok" )
         ENDIF

      CASE nKey == CMD_PUBLIC
         IF p1 == "on"
            ::lShowPublic := .T.
            ::lShowStatic := ::lShowPrivate := ::lShowLocals := .F.
            hwg_dbg_Answer( "valuepubl", SendPublic() )
         ELSE
            ::lShowStatic := ::lShowLocals := ::lShowPrivate := ::lShowPublic := .F.
            hwg_dbg_Answer( "ok" )
         ENDIF

      CASE nKey == CMD_STATIC
         IF p1 == "on"
            ::lShowStatic := .T.
            ::lShowLocals := ::lShowPrivate := ::lShowPublic := .F.
            hwg_dbg_Answer( "valuestatic", SendStatic() )
         ELSE
            ::lShowStatic := ::lShowLocals := ::lShowPrivate := ::lShowPublic := .F.
            hwg_dbg_Answer( "ok" )
         ENDIF

      CASE nKey == CMD_WATCH
         IF p1 == "on"
            ::lShowWatch := .T.
            IF ::nWatches > 0
               hwg_dbg_Answer( "valuewatch", SendWatch() )
            ELSE
               hwg_dbg_Answer( "ok" )
            ENDIF
         ELSE
            ::lShowWatch := .F.
            hwg_dbg_Answer( "ok" )
         ENDIF

      CASE nKey == CMD_AREAS
         hwg_dbg_Answer( "valueareas", SendAreas() )

      CASE nKey == CMD_REC
         hwg_dbg_Answer( "valuerec", SendRec( p1 ) )

      CASE nKey == CMD_OBJECT
         hwg_dbg_Answer( "valueobj", SendObject( p1 ) )

      CASE nKey == CMD_ARRAY
         hwg_dbg_Answer( "valuearr", SendArray( p1,Val(p2 ),Val(p3 ) ) )

      CASE nKey == CMD_CALC
         IF Left( p1, 1 ) == "?"
            p1 := LTrim( SubStr( p1, iif( Left(p1,2 ) == "??",3,2 ) ) )
         ENDIF
         hwg_dbg_Answer( "value", __dbgValToStr( ::GetExprValue( p1 ) ) )

      ENDCASE
   ENDDO

   RETURN NIL

METHOD LoadCallStack() CLASS HBDebugger

   LOCAL i
   LOCAL nDebugLevel
   LOCAL nCurrLevel
   LOCAL nlevel
   LOCAL nPos

   ::aProcStack := Array( ::nProcLevel )

   nCurrLevel := __dbgProcLevel() - 1
   nDebugLevel := nCurrLevel - ::nProcLevel + 1

   FOR i := nDebugLevel TO nCurrLevel
      nLevel := nCurrLevel - i + 1
      nPos := AScan( ::aCallStack, { | a | a[ CSTACK_LEVEL ] == nLevel } )
      IF nPos > 0
         // a procedure with debug info
         ::aProcStack[ i - nDebugLevel + 1 ] := ::aCallStack[ nPos ]
      ELSE
         ::aProcStack[ i - nDebugLevel + 1 ] := { , ProcName( i ) + "(" + hb_ntos( ProcLine( i ) ) + ")", , nLevel, , }
      ENDIF
   NEXT

   RETURN NIL

METHOD QUIT() CLASS HBDebugger

   __dbgSetQuit( ::pInfo )
   t_oDebugger := NIL

   hwg_dbg_Quit()

   RETURN NIL

METHOD ShowCodeLine( nProc ) CLASS HBDebugger

   LOCAL nLine
   LOCAL cPrgName

   // we only update the stack window and up a new browse
   // to view the code if we have just broken execution
   IF ! ::lGo
      nLine := ::aProcStack[ nProc ][ CSTACK_LINE ]
      cPrgName := ::aProcStack[ nProc ][ CSTACK_MODULE ]
      IF nLine == NIL
         hwg_dbg_Msg( ::aProcStack[ nProc ][ CSTACK_FUNCTION ] + ;
            ": Code not available" )
         RETURN NIL
      ENDIF

      IF ! Empty( cPrgName )
         hwg_dbg_SetActiveLine( cPrgName, nLine, ;
            iif( ::lViewStack, SendStack(), Nil ),  ;
            iif( ::lShowLocals, SendLocal(), ;
            iif( ::lShowStatic, SendStatic(), ;
            iif( ::lShowPrivate, SendPrivate(), ;
            iif( ::lShowPublic, SendPublic(), Nil ) ) ) ), ;
            iif( ::lShowWatch .AND. ( ::nWatches > 0 ), SendWatch(), Nil ), ;
            iif( ::lShowLocals, 1, ;
            iif( ::lShowPrivate, 2, ;
            iif( ::lShowPublic, 3, ;
            iif( ::lShowStatic, 4, Nil ) ) ) ) )
      ENDIF
   ENDIF

   RETURN NIL

METHOD VarGetInfo( aVar ) CLASS HBDebugger

   LOCAL cType := Left( aVar[ VAR_TYPE ], 1 )
   LOCAL uValue := ::VarGetValue( aVar )

   DO CASE
   CASE cType == "G" ; RETURN aVar[ VAR_NAME ] + " <Global, " + ValType( uValue ) + ">: " + __dbgValToStr( uValue )
   CASE cType == "L" ; RETURN aVar[ VAR_NAME ] + " <Local, " + ValType( uValue ) + ">: " + __dbgValToStr( uValue )
   CASE cType == "S" ; RETURN aVar[ VAR_NAME ] + " <Static, " + ValType( uValue ) + ">: " + __dbgValToStr( uValue )
      OTHERWISE         ; RETURN aVar[ VAR_NAME ] + " <" + aVar[ VAR_TYPE ] + ", " + ValType( uValue ) + ">: " + __dbgValToStr( uValue )
   ENDCASE

   // ; Never reached

   RETURN ""

METHOD VarGetValue( aVar ) CLASS HBDebugger

   LOCAL cType := Left( aVar[ VAR_TYPE ], 1 )

   DO CASE
   CASE cType == "G" ; RETURN __dbgVMVarGGet( aVar[ VAR_LEVEL ], aVar[ VAR_POS ] )
   CASE cType == "L" ; RETURN __dbgVMVarLGet( __dbgProcLevel() - aVar[ VAR_LEVEL ], aVar[ VAR_POS ] )
   CASE cType == "S" ; RETURN __dbgVMVarSGet( aVar[ VAR_LEVEL ], aVar[ VAR_POS ] )
      OTHERWISE         ; RETURN aVar[ VAR_POS ] // Public or Private
   ENDCASE

   // ; Never reached

   RETURN NIL

METHOD VarSetValue( aVar, uValue ) CLASS HBDebugger

   LOCAL nProcLevel
   LOCAL cType := Left( aVar[ VAR_TYPE ], 1 )

   IF cType == "G"
      __dbgVMVarGSet( aVar[ VAR_LEVEL ], aVar[ VAR_POS ], uValue )

   ELSEIF cType == "L"
      nProcLevel := __dbgProcLevel() - aVar[ VAR_LEVEL ]   // skip debugger stack
      __dbgVMVarLSet( nProcLevel, aVar[ VAR_POS ], uValue )

   ELSEIF cType == "S"
      __dbgVMVarSSet( aVar[ VAR_LEVEL ], aVar[ VAR_POS ], uValue )

   ELSE
      // Public or Private
      aVar[ VAR_POS ] := uValue
      &( aVar[ VAR_NAME ] ) := uValue

   ENDIF

   RETURN Self

FUNCTION __Dbg()

   RETURN t_oDebugger

STATIC FUNCTION SendStack()
   LOCAL aStack := t_oDebugger:aProcStack
   LOCAL arr := Array( Len( aStack ) * 3 + 1 ), i, j := 2

   arr[1] := LTrim( Str( Len( aStack ) ) )
   FOR i := 1 TO Len( aStack )
      arr[j++] := iif( Empty( aStack[i,CSTACK_MODULE] ), "", aStack[i,CSTACK_MODULE] )
      arr[j++] := iif( Empty( aStack[i,CSTACK_FUNCTION] ), "Unknown", aStack[i,CSTACK_FUNCTION] )
      arr[j++] := iif( Empty( aStack[i,CSTACK_LINE] ), "", LTrim( Str( aStack[i,CSTACK_LINE] ) ) )
   NEXT

   RETURN arr

STATIC FUNCTION SendLocal()
   LOCAL aVars := t_oDebugger:aProcStack[1,CSTACK_LOCALS]
   LOCAL arr := Array( Len( aVars ) * 3 + 1 ), i, j := 1, xVal

   arr[1] := LTrim( Str( Len( aVars ) ) )
   FOR i := 1 TO Len( aVars )
      arr[++j] := aVars[ i,VAR_NAME ]
      xVal := __dbgvmVarLGet( __dbgprocLevel() - aVars[i,VAR_LEVEL], aVars[i,VAR_POS] )
      arr[++j] := ValType( xVal )
      arr[++j] := __dbgValToStr( xVal )
      IF Len( arr[j] ) > VAR_MAX_LEN
         arr[j] := Left( arr[j], VAR_MAX_LEN )
      ENDIF
   NEXT

   RETURN arr

STATIC FUNCTION SendPrivate()
   LOCAL nCount := __mvDbgInfo( HB_MV_PRIVATE )
   LOCAL arr := Array( nCount * 3 + 1 ), cName, xValue, i, j := 1

   arr[1] := LTrim( Str( nCount ) )
   FOR i := 1 TO nCount
      xValue := __mvDbgInfo( HB_MV_PRIVATE, i, @cName )
      arr[++j] := cName
      arr[++j] := ValType( xValue )
      arr[++j] := __dbgValToStr( xValue )
      IF Len( arr[j] ) > VAR_MAX_LEN
         arr[j] := Left( arr[j], VAR_MAX_LEN )
      ENDIF
   NEXT

   RETURN arr

STATIC FUNCTION SendPublic()
   LOCAL nCount := __mvDbgInfo( HB_MV_PUBLIC )
   LOCAL arr := Array( nCount * 3 + 1 ), cName, xValue, i, j := 1

   arr[1] := LTrim( Str( nCount ) )
   FOR i := 1 TO nCount
      xValue := __mvDbgInfo( HB_MV_PUBLIC, i, @cName )
      arr[++j] := cName
      arr[++j] := ValType( xValue )
      arr[++j] := __dbgValToStr( xValue )
      IF Len( arr[j] ) > VAR_MAX_LEN
         arr[j] := Left( arr[j], VAR_MAX_LEN )
      ENDIF
   NEXT

   RETURN arr

STATIC FUNCTION SendStatic()
   LOCAL aVars, nAll := 0
   LOCAL arr, i, j := 1, xVal

   xVal := t_oDebugger:aProcStack[ 1,CSTACK_MODULE ]
   i := AScan( t_oDebugger:aModules, { |a| hb_FileMatch( a[MODULE_NAME], xVal ) } )
   IF i > 0
      aVars := t_oDebugger:aModules[ i,MODULE_STATICS ]
      nAll := Len( aVars )
   ENDIF

   nAll += Len( t_oDebugger:aProcStack[1,CSTACK_STATICS] )
   arr := Array( nAll * 3 + 1 )

   arr[1] := LTrim( Str( nAll ) )

   IF !Empty( aVars )
      FOR i := 1 TO Len( aVars )
         arr[++j] := aVars[ i,VAR_NAME ]
         xVal := __dbgVMVarSGet( aVarS[ i,VAR_LEVEL ], aVarS[ i,VAR_POS ] )
         arr[++j] := ValType( xVal )
         arr[++j] := __dbgValToStr( xVal )
         IF Len( arr[j] ) > VAR_MAX_LEN
            arr[j] := Left( arr[j], VAR_MAX_LEN )
         ENDIF
      NEXT
   ENDIF

   aVars := t_oDebugger:aProcStack[1,CSTACK_STATICS]
   FOR i := 1 TO Len( aVars )
      arr[++j] := aVars[ i,VAR_NAME ]
      xVal := __dbgVMVarSGet( aVarS[ i,VAR_LEVEL ], aVarS[ i,VAR_POS ] )
      arr[++j] := ValType( xVal )
      arr[++j] := __dbgValToStr( xVal )
      IF Len( arr[j] ) > VAR_MAX_LEN
         arr[j] := Left( arr[j], VAR_MAX_LEN )
      ENDIF
   NEXT

   RETURN arr

STATIC FUNCTION SendWatch()
   LOCAL arr := Array( t_oDebugger:nWatches + 1 ), i

   arr[1] := LTrim( Str( t_oDebugger:nWatches ) )

   FOR i := 1 TO t_oDebugger:nWatches
      arr[i+1] := __dbgValToStr( t_oDebugger:GetExprValue( i ) )
   NEXT

   RETURN arr

#define WA_ITEMS  12

STATIC FUNCTION SendAreas()
   LOCAL arr, arr1[512], n, i, j, nAreas := 0, nAlias, cName

   FOR n := 1 TO 512
      IF ( ( n ) -> ( Used() ) )
         arr1[ ++nAreas ] := n
      ENDIF
   NEXT

   nAlias := Select()
   arr := Array( 2 + nAreas * WA_ITEMS )
   arr[1] := hb_ntos( nAreas )
   arr[2] := hb_ntos( WA_ITEMS )
   n := 2
   FOR i := 1 TO nAreas
      SELECT( arr1[i] )
      arr[++n] := iif( arr1[i] == nAlias, "*", "" ) + Alias()
      arr[++n] := hb_ntos( arr1[i] )
      arr[++n] := rddName()
      arr[++n] := hb_ntos( RecCount() )
      arr[++n] := hb_ntos( RecNo() )
      arr[++n] := iif( Bof(), "Yes", "No" )
      arr[++n] := iif( Eof(), "Yes", "No" )
      arr[++n] := iif( Found(), "Yes", "No" )
      arr[++n] := iif( Deleted(), "Yes", "No" )
      arr[++n] := dbFilter()
      IF !Empty( cName := OrdSetFocus() )
         arr[++n] := LTrim( Str( OrdNumber(cName ) ) )
      ELSE
         arr[++n] := "0"
      ENDIF
      arr[++n] := ""
      j := 0
      DO WHILE !Empty( cName := OrdName( ++ j ) )
         arr[n] += "/" + cName + "@" + OrdKey( j )
      ENDDO
      //hwg_writelog( "D> "+arr[n-1]+" "+arr[n] )
      //arr[++n] := ordName()
      //arr[++n] := ordKey()
   NEXT
   SELECT( nAlias )

   RETURN arr

STATIC FUNCTION SendRec( cAlias )
   LOCAL af, nCount, arr, i, j := 3

   IF Empty( cAlias )
      cAlias := Alias()
   ENDIF
   IF Empty( cAlias ) .OR. ( i := Select( cAlias ) ) == 0
      RETURN { "0", "", "0" }
   ENDIF
   af := ( cAlias ) -> ( dbStruct() )
   nCount := Len( af )
   arr := Array( nCount * 4 + 3 )

   arr[1] := LTrim( Str( nCount ) )
   arr[2] := cAlias
   arr[3] := LTrim( Str( (cAlias ) -> (RecNo() ) ) )
   FOR i := 1 TO nCount
      arr[++j] := af[i,1]
      arr[++j] := af[i,2]
      arr[++j] := LTrim( Str( af[i,3] ) )
      arr[++j] := __dbgValToStr( ( cAlias ) -> ( FieldGet(i ) ) )
      IF Len( arr[j] ) > VAR_MAX_LEN
         arr[j] := Left( arr[j], VAR_MAX_LEN )
      ENDIF
   NEXT

   RETURN arr

#ifdef __XHARBOUR__

STATIC FUNCTION SendObject( cObjName )
   LOCAL aVars, aMethods, arr, obj, i, j := 1

   obj := t_oDebugger:GetExprValue( cObjName )
   IF ValType( obj ) == "O"
      aVars := __objGetValueList( obj )
      aMethods := __objGetMethodList( obj )
      arr := Array( ( Len(aVars ) + Len(aMethods ) ) * 3 + 1 )
      arr[1] := LTrim( Str( Len(aVars ) + Len(aMethods ) ) )

      FOR i := 1 TO Len( aVars )
         arr[++j] := aVars[ i,1 ]
         arr[++j] := ValType( aVars[ i,2 ] )
         arr[++j] := __dbgValToStr( aVars[ i,2 ] )
         IF Len( arr[j] ) > VAR_MAX_LEN
            arr[j] := Left( arr[j], VAR_MAX_LEN )
         ENDIF
      NEXT
      FOR i := 1 TO Len( aMethods )
         arr[++j] := aMethods[ i ]
         arr[++j] := ""
         arr[++j] := "Method"
      NEXT

   ELSE
      RETURN { "0" }
   ENDIF

   RETURN arr

#else

STATIC FUNCTION SendObject( cObjName )
   LOCAL aVars, aMethods, arr, obj, i, j := 1, xVal

   obj := t_oDebugger:GetExprValue( cObjName )
   IF ValType( obj ) == "O"
      aVars := __objGetMsgList( obj )
      aMethods := __objGetMethodList( obj )
      arr := Array( ( Len(aVars ) + Len(aMethods ) ) * 3 + 1 )
      arr[1] := LTrim( Str( Len(aVars ) + Len(aMethods ) ) )

      FOR i := 1 TO Len( aVars )
         arr[++j] := aVars[i]
         xVal := __dbgObjGetValue( obj, aVars[i] )
         arr[++j] := ValType( xVal )
         arr[++j] := __dbgValToStr( xVal )

         IF Len( arr[j] ) > VAR_MAX_LEN
            arr[j] := Left( arr[j], VAR_MAX_LEN )
         ENDIF
      NEXT
      FOR i := 1 TO Len( aMethods )
         arr[++j] := aMethods[ i ]
         arr[++j] := ""
         arr[++j] := "Method"
      NEXT

   ELSE
      RETURN { "0" }
   ENDIF

   RETURN arr

#endif

STATIC FUNCTION SendArray( cArrName, nFirst, nCount )
   LOCAL arr, arrFrom, xValue, i, j := 3

   arrFrom := t_oDebugger:GetExprValue( cArrName )
   IF ValType( arrFrom ) == "A"
      IF Len( arrFrom ) < nFirst + nCount - 1
         nCount := Len( arrFrom ) - nFirst + 1
      ENDIF
      arr := Array( nCount * 2 + 3 )
      arr[1] := LTrim( Str( nCount ) )
      arr[2] := LTrim( Str( nFirst ) )
      arr[3] := LTrim( Str( Len(arrFrom ) ) )
      FOR i := 1 TO nCount
         arr[++j] := ValType( arrFrom[nFirst+i-1] )
         arr[++j] := __dbgValToStr( arrFrom[nFirst+i-1] )
         IF Len( arr[j] ) > VAR_MAX_LEN
            arr[j] := Left( arr[j], VAR_MAX_LEN )
         ENDIF
      NEXT
   ELSE
      RETURN { "0", "0", "0" }
   ENDIF

   RETURN arr

   /* Check if a string starts with another string */

STATIC FUNCTION starts( cLine, cStart )

   RETURN cStart == Left( cLine, Len( cStart ) )

   /* Strip path from filename */

STATIC FUNCTION strip_path( cFileName )

   LOCAL cName
   LOCAL cExt

   IF cFileName == Nil; cFileName := ""; ENDIF

   hb_FNameSplit( cFileName, NIL, @cName, @cExt )

   RETURN cName + cExt

FUNCTION __dbgValToStr( uVal )

   LOCAL cType := ValType( uVal ), i, s, nLen

   DO CASE
   CASE uVal == NIL  ; RETURN "NIL"
   CASE cType == "B" ; RETURN "{|| ... }"
   CASE cType == "A"
      s := ""
      nLen := Min( 8, Len( uVal ) )
      FOR i := 1 TO nLen
         s += '"' + ValType( uVal[i] ) + '"' + iif( i == nLen, "", ", " )
      NEXT
      IF nLen < Len( uVal )
         s += ", ..."
      ENDIF
      RETURN "Array(" + hb_ntos( Len( uVal ) ) + "): { " + s + " }"
   CASE cType $ "CM" ; RETURN '"' + uVal + '"'
   CASE cType == "L" ; RETURN iif( uVal, ".T.", ".F." )
   CASE cType == "D" ; RETURN Dtoc( uVal )
#ifndef __XHARBOUR__
   CASE cType == "T" ; RETURN hb_TToC( uVal )
#endif
   CASE cType == "N" ; RETURN Str( uVal )
   CASE cType == "O" ; RETURN "Class " + uVal:ClassName() + " object"
   CASE cType == "H" ; RETURN "Hash(" + hb_ntos( Len( uVal ) ) + ")"
   CASE cType == "P" ; RETURN "Pointer"
   ENDCASE

   RETURN "U"

#ifndef __XHARBOUR__

STATIC FUNCTION __dbgObjGetValue( oObject, cVar, lCanAcc )

   LOCAL nProcLevel := __Dbg():nProcLevel
   LOCAL xResult
   LOCAL oErr

   BEGIN SEQUENCE WITH { || Break() }
      xResult := __dbgSENDMSG( nProcLevel, oObject, cVar )
      lCanAcc := .T.
   RECOVER
      BEGIN SEQUENCE WITH { | oErr | Break( oErr ) }
         /* Try to access variables using class code level */
         xResult := __dbgSENDMSG( 0, oObject, cVar )
         lCanAcc := .T.
      RECOVER USING oErr
         xResult := oErr:description
         lCanAcc := .F.
      END SEQUENCE
   END SEQUENCE

   RETURN xResult

#endif

#ifdef __XHARBOUR__

#define ALTD_DISABLE   0

#define ALTD_ENABLE    1

FUNCTION AltD( nAction )

   IF PCount() == 0
      IF SET( _SET_DEBUG ) .AND. Type( "__DBGALTDENTRY()" ) == "UI"
         &( "__DBGALTDENTRY()" )
      ENDIF
   ELSEIF ValType( nAction ) == "N"
      IF nAction == ALTD_DISABLE
         SET( _SET_DEBUG, .F. )
      ELSEIF nAction == ALTD_ENABLE
         SET( _SET_DEBUG, .T. )
      ENDIF
   ENDIF

   RETURN nil

#endif
