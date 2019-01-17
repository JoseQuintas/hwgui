/*
 * $Id$
 *
 * Common procedures
 * Scripts
 *
 * Author: Alexander S.Kresin <alex@belacy.belgorod.su>
 *         www - http://kresin.belgorod.su
*/

#include "fileio.ch"
#define __WINDOWS__

#ifdef __PLATFORM__UNIX
   #define DEF_SEP      '/'
   #define DEF_CH_SEP   '\'
#else
   #define DEF_SEP      '\'
   #define DEF_CH_SEP   '/'
#endif

Memvar iscr

STATIC nLastError, numlin
STATIC lDebugInfo := .F.
STATIC lDebugger := .F.
STATIC lDebugRun := .F.

#ifndef __WINDOWS__
STATIC y__size := 0, x__size := 0
#endif
#define STR_BUFLEN  1024

#ifndef __XHARBOUR__
REQUEST __PP_STDRULES
REQUEST OS
REQUEST HB_COMPILER
REQUEST HB_VERSION
#else
REQUEST VERSION
#endif

FUNCTION OpenScript( fname, scrkod )

LOCAL han, stroka, scom, aScr, rejim := 0, i
LOCAL strbuf := Space(STR_BUFLEN), poz := STR_BUFLEN+1
LOCAL aFormCode, aFormName

   scrkod := IIF( scrkod==Nil, "000", Upper(scrkod) )
   IF DEF_CH_SEP $ fname
      fname := StrTran( fname, DEF_CH_SEP, DEF_SEP )
   ENDIF
   han := FOPEN( fname, FO_READ + FO_SHARED )
   IF han != - 1
      DO WHILE .T.
         stroka := RDSTR( han,@strbuf,@poz,STR_BUFLEN )
         IF LEN( stroka ) = 0
            EXIT
         ELSEIF rejim == 0 .AND. Left( stroka,1 ) == "#"
            IF Upper( LEFT( stroka, 7 ) ) == "#SCRIPT"
               scom := Upper( Ltrim( Substr( stroka,9 ) ) )
               IF scom == scrkod
                  aScr := RdScript( han, @strbuf, @poz,,fname+","+scrkod )
                  EXIT
               ENDIF
            ELSEIF LEFT( stroka, 6 ) == "#BLOCK"
               scom := Upper( Ltrim( Substr( stroka,8 ) ) )
               IF scom == scrkod
                  rejim     := - 1
                  aFormCode := {}
                  aFormName := {}
               ENDIF
            ENDIF
         ELSEIF rejim == -1 .AND. LEFT( stroka, 1 ) == "@"
            i := AT( " ", stroka )
            Aadd( aFormCode, SUBSTR( stroka, 2, i-2 ) )
            Aadd( aFormName, SUBSTR( stroka, i+1 ) )
         ELSEIF rejim == -1 .AND. LEFT( stroka, 9 ) == "#ENDBLOCK"
#ifdef __WINDOWS__
            i := hwg_WChoice( aFormName )
#else
            i := FCHOICE( aFormName )
#endif
            IF i == 0
               FCLOSE( han )
               RETURN Nil
            ENDIF
            rejim  := 0
            scrkod := aFormCode[ i ]
         ENDIF
      ENDDO
      FCLOSE( han )
   ELSE
#ifdef __WINDOWS__
      hwg_Msgstop( fname + " can't be opened " )
#else
      ALERT( fname + " can't be opened " )
#endif
      RETURN Nil
   ENDIF
RETURN aScr

FUNCTION RdScript( scrSource, strbuf, poz, lppNoInit, cTitle )

LOCAL han
LOCAL rezArray := Iif( lDebugInfo, { "", {}, {} }, { "", {} } )

   IF lppNoInit == Nil
      lppNoInit := .F.
   ENDIF
   IF poz == Nil
      poz := 1
   ENDIF
   IF cTitle != Nil
      rezArray[ 1 ] := cTitle
   ENDIF
   nLastError := 0
   IF scrSource == Nil
      han := Nil
      poz := 1
   ELSEIF Valtype( scrSource ) == "C"
      strbuf := Space( STR_BUFLEN )
      poz := STR_BUFLEN + 1
      IF DEF_CH_SEP $ scrSource
         scrSource := StrTran( scrSource, DEF_CH_SEP, DEF_SEP )
      ENDIF
      han := Fopen( scrSource, FO_READ + FO_SHARED )
   ELSE
      han := scrSource
   ENDIF
   IF han == Nil .OR. han != - 1
      IF !lppNoInit
         ppScript( ,.T. )
      ENDIF
      IF Valtype( scrSource ) == "C"
         WndOut( "Compiling ..." )
         WndOut( "" )
      ENDIF
      numlin := 0
      IF !CompileScr( han, @strbuf, @poz, rezArray, scrSource )
         rezArray := Nil
      ENDIF
      IF scrSource != Nil .AND. Valtype( scrSource ) == "C"
         WndOut()
         Fclose( han )
      ENDIF
      IF !lppNoInit
         ppScript( ,.F. )
      ENDIF
   ELSE
#ifdef __WINDOWS__
      hwg_Msgstop( "Can't open " + scrSource )
#else
      WndOut( "Can't open " + scrSource )
      WAIT ""
      WndOut()
#endif
      nLastError := - 1
      RETURN Nil
   ENDIF
RETURN rezArray

FUNCTION ppScript( stroka, lNew )
STATIC s_pp

   IF lNew != Nil
      s_pp := Iif( lNew, __pp_init(), Nil )
      RETURN Nil
   ENDIF
RETURN __pp_process( s_pp, stroka )

FUNCTION scr_GetFuncsList( strbuf )
   LOCAL arr := {}, poz := 1, cLine, poz1, scom

   DO WHILE .T.
      cLine := RDSTR( , @strbuf, @poz, STR_BUFLEN )
      IF Len( cLine ) = 0
         EXIT
      ENDIF
      cLine := AllTrim( cLine )
      IF ( poz1 := AT( " ", cLine ) ) > 0
         scom := Upper( Left( cLine, poz1 - 1 ) )
         IF scom == "FUNCTION"
            cLine := Ltrim( Substr( cLine,poz1+1 ) )
            poz1 := At( "(",cLine )
            AAdd( arr, Upper( Left( cLine, Iif( poz1 != 0,poz1-1,999 ) ) ) )
         ENDIF
      ENDIF
   ENDDO

   RETURN arr

STATIC FUNCTION COMPILESCR( han, strbuf, poz, rezArray, scrSource )

LOCAL scom, poz1, stroka, strfull := "", bOldError, i, tmpArray := {}
Local cLine, lDebug := ( Len( rezArray ) >= 3 )

   DO WHILE .T.
      cLine := RDSTR( han, @strbuf, @poz, STR_BUFLEN )
      IF LEN( cLine ) = 0
         EXIT
      ENDIF
      numlin ++
      IF Right( cLine,1 ) == ';'
         strfull += Left( cLine,Len(cLine)-1 )
         LOOP
      ELSE
         IF !Empty( strfull )
            cLine := strfull + cLine
         ENDIF
         strfull := ""
      ENDIF
      stroka := AllTrim( cLine )
      IF RIGHT( stroka, 1 ) == CHR( 26 )
         stroka := LEFT( stroka, LEN( stroka ) - 1 )
      ENDIF
      IF !EMPTY( stroka ) .AND. LEFT( stroka, 2 ) != "//"

         IF Left( stroka,1 ) == "#"
            IF UPPER( Left( stroka,7 ) ) == "#ENDSCR"
               Return .T.
            ELSEIF UPPER( Left( stroka,6 ) ) == "#DEBUG"
               IF !lDebug .AND. Len( rezArray[2] ) == 0
                  lDebug := .T.
                  Aadd( rezArray, {} )
                  IF SUBSTR( stroka,7,3 ) == "GER"
                     AADD( rezArray[2], stroka )
                     AADD( tmpArray, "" )
                     Aadd( rezArray[3], Str( numlin,4 ) + ":" + cLine )
                  ENDIF
               ENDIF
               LOOP
#ifdef __HARBOUR__
            ELSE
               ppScript( stroka )
               LOOP
#endif
            ENDIF
#ifdef __HARBOUR__
         ELSE
            stroka := ppScript( stroka )
#endif
         ENDIF

         poz1 := AT( " ", stroka )
         scom := UPPER( SUBSTR( stroka, 1, IIF( poz1 <> 0, poz1 - 1, 999 ) ) )
         DO CASE
         CASE scom == "PRIVATE" .OR. scom == "PARAMETERS" .OR. scom == "LOCAL"
            IF LEN( rezArray[2] ) == 0 .OR. ( i := VALTYPE( ATAIL( rezArray[2] ) ) ) == "C" ;
                    .OR. i == "A"
               IF Left( scom,2 ) == "LO"
                  AADD( rezArray[2], " "+ALLTRIM( SUBSTR( stroka, 7 ) ) )     
               ELSEIF Left( scom,2 ) == "PR"
                  AADD( rezArray[2], " "+ALLTRIM( SUBSTR( stroka, 9 ) ) )
               ELSE
                  AADD( rezArray[2], "/"+ALLTRIM( SUBSTR( stroka, 12 ) ) )
               ENDIF
               AADD( tmpArray, "" )
            ELSE
               nLastError := 1
               RETURN .F.
            ENDIF
         CASE ( scom == "DO" .AND. UPPER( SUBSTR( stroka, 4, 5 ) ) == "WHILE" ) ;
                .OR. scom == "WHILE"
            AADD( tmpArray, stroka )
            AADD( rezArray[2], .F. )
         CASE scom == "ENDDO"
            IF !Fou_Do( rezArray[2], tmpArray )
               nLastError := 2
               RETURN .F.
            ENDIF
         CASE scom == "EXIT"
            AADD( tmpArray, "EXIT" )
            AADD( rezArray[2], .F. )
         CASE scom == "LOOP"
            AADD( tmpArray, "LOOP" )
            AADD( rezArray[2], .F. )
         CASE scom == "IF"
            AADD( tmpArray, stroka )
            AADD( rezArray[2], .F. )
         CASE scom == "ELSEIF"
            IF !Fou_If( rezArray, tmpArray, .T. )
               nLastError := 3
               RETURN .F.
            ENDIF
            AADD( tmpArray, SUBSTR( stroka, 5 ) )
            AADD( rezArray[2], .F. )
         CASE scom == "ELSE"
            IF !Fou_If( rezArray, tmpArray, .T. )
               nLastError := 1
               RETURN .F.
            ENDIF
            AADD( tmpArray, "IF .T." )
            AADD( rezArray[2], .F. )
         CASE scom == "ENDIF"
            IF !Fou_If( rezArray, tmpArray, .F. )
               nLastError := 1
               RETURN .F.
            ENDIF
         CASE scom == "RETURN"
            bOldError := ERRORBLOCK( { | e | MacroError(1,e,stroka) } )
            BEGIN SEQUENCE
               AADD( rezArray[2], &( "{||EndScript("+Ltrim( Substr( stroka,7 ) )+")}" ) )
            RECOVER
               IF scrSource != Nil .AND. VALTYPE( scrSource ) == "C"
                  WndOut()
                  FCLOSE( han )
               ENDIF
               ERRORBLOCK( bOldError )
               RETURN .F.
            END SEQUENCE
            ERRORBLOCK( bOldError )
            AADD( tmpArray, "" )
         CASE scom == "FUNCTION"
            stroka := Ltrim( Substr( stroka,poz1+1 ) )
            poz1 := At( "(",stroka )
            scom := UPPER( LEFT( stroka, IIF( poz1 != 0, poz1 - 1, 999 ) ) )
            AADD( rezArray[2], Iif( lDebug,{ scom,{},{} },{ scom,{} } ) )
            AADD( tmpArray, "" )
            IF !CompileScr( han, @strbuf, @poz, rezArray[2,Len(rezArray[2])] )
               RETURN .F.
            ENDIF
         CASE scom == "#ENDSCRIPT" .OR. Left( scom,7 ) == "ENDFUNC"
            RETURN .T.
         OTHERWISE
            bOldError := ERRORBLOCK( { | e | MacroError(1,e,stroka) } )
            BEGIN SEQUENCE
               AADD( rezArray[2], &( "{||" + ALLTRIM( stroka ) + "}" ) )
            RECOVER
               IF scrSource != Nil .AND. VALTYPE( scrSource ) == "C"
                  WndOut()
                  FCLOSE( han )
               ENDIF
               ERRORBLOCK( bOldError )
               RETURN .F.
            END SEQUENCE
            ERRORBLOCK( bOldError )
            AADD( tmpArray, "" )
         ENDCASE
         IF lDebug .AND. Len( rezArray[3] ) < Len( rezArray[2] )
            Aadd( rezArray[3], Str( numlin,4 ) + ":" + cLine )
         ENDIF
      ENDIF
   ENDDO
RETURN .T.

STATIC FUNCTION MacroError( nm, e, stroka )

Local n, cTitle

#ifdef __WINDOWS__
   IF nm == 1
      stroka := hwg_ErrMsg( e ) + Chr(10)+Chr(13) + "in" + Chr(10)+Chr(13) + ;
                      AllTrim(stroka)
      cTitle := "Script compiling error"
   ELSEIF nm == 2
      stroka := hwg_ErrMsg( e )
      cTitle := "Script variables error"
   ELSEIF nm == 3
      n := 2
      WHILE !Empty( ProcName( n ) )
        stroka += Chr(13)+Chr(10) + "Called from " + ProcName( n ) + "(" + AllTrim( Str( ProcLine( n++ ) ) ) + ")"
      ENDDO
      stroka := hwg_ErrMsg( e )+ Chr(10)+Chr(13) + stroka
      cTitle := "Script execution error"
   ENDIF
   stroka += Chr(13)+Chr(10) + Chr(13)+Chr(10) + "Continue ?"
   IF !hwg_Msgyesno( stroka, cTitle )
      hwg_EndWindow()
      QUIT
   ENDIF
#else
   IF nm == 1
      ALERT( "Error in;" + AllTrim(stroka) )
   ELSEIF nm == 2
      Alert( "Script variables error" )
   ELSEIF nm == 3
      stroka += ";" + hwg_ErrMsg( e )
      n := 2
      WHILE !Empty( ProcName( n ) )
        stroka += ";Called from " + ProcName( n ) + "(" + AllTrim( Str( ProcLine( n++ ) ) ) + ")"
      ENDDO
      Alert( "Script execution error:;"+stroka )
   ENDIF
#endif
   BREAK
RETURN .T.

STATIC FUNCTION Fou_If( rezArray, tmpArray, prju )

LOCAL i, j, bOldError

   IF prju
      AADD( tmpArray, "JUMP" )
      AADD( rezArray[2], .F. )
      IF Len( rezArray ) >= 3
         Aadd( rezArray[3], Str( numlin,4 ) + ":JUMP" )
      ENDIF
   ENDIF
   j := LEN( rezArray[2] )
   FOR i := j TO 1 STEP - 1
      IF UPPER( LEFT( tmpArray[ i ], 2 ) ) == "IF"
         bOldError := ERRORBLOCK( { | e | MacroError(1,e,tmpArray[ i ]) } )
         BEGIN SEQUENCE
            rezArray[ 2,i ] := &( "{||IIF(" + ALLTRIM( SUBSTR( tmpArray[ i ], 4 ) ) + ;
                 ",.T.,iscr:=" + LTRIM( STR( j, 5 ) ) + ")}" )
         RECOVER
            ERRORBLOCK( bOldError )
            RETURN .F.
         END SEQUENCE
         ERRORBLOCK( bOldError )
         tmpArray[ i ] := ""
         i --
         IF i > 0 .AND. tmpArray[ i ] == "JUMP"
            rezArray[ 2,i ] := &( "{||iscr:=" + LTRIM( STR( IIF( prju, j - 1, j ), 5 ) ) + "}" )
            tmpArray[ i ] := ""
         ENDIF
         RETURN .T.
      ENDIF
   NEXT
RETURN .F.

STATIC FUNCTION Fou_Do( rezArray, tmpArray )

LOCAL i, j, iloop := 0, iPos, bOldError

   j := LEN( rezArray )
   FOR i := j TO 1 STEP - 1
      IF !EMPTY( tmpArray[ i ] ) .AND. LEFT( tmpArray[ i ], 4 ) == "EXIT"
         rezArray[ i ] = &( "{||iscr:=" + LTRIM( STR( j + 1, 5 ) ) + "}" )
         tmpArray[ i ] = ""
      ENDIF
      IF !EMPTY( tmpArray[ i ] ) .AND. LEFT( tmpArray[ i ], 4 ) == "LOOP"
         iloop := i
      ENDIF
      IF !EMPTY( tmpArray[ i ] ) .AND. ;
            ( UPPER( LEFT( tmpArray[ i ], 8 ) ) = "DO WHILE" .OR. ;
              UPPER( LEFT( tmpArray[ i ], 5 ) ) = "WHILE" )
         bOldError := ERRORBLOCK( { | e | MacroError(1,e,tmpArray[ i ] ) } )
         BEGIN SEQUENCE
            rezArray[ i ] = &( "{||IIF(" + ALLTRIM( SUBSTR( tmpArray[ i ], ;
                 IIF( UPPER( LEFT( tmpArray[ i ],1 ) ) == "D",10,7 ) ) ) + ;
                 ",.T.,iscr:=" + LTRIM( STR( j + 1, 5 ) ) + ")}" )
         RECOVER
            ERRORBLOCK( bOldError )
            RETURN .F.
         END SEQUENCE
         ERRORBLOCK( bOldError )
         tmpArray[ i ] = ""
         AADD( rezArray, &( "{||iscr:=" + LTRIM( STR( i - 1, 5 ) ) + "}" ) )
         AADD( tmpArray, "" )
         IF iloop > 0
            rezArray[ iloop ] = &( "{||iscr:=" + LTRIM( STR( i - 1, 5 ) ) + "}" )
            tmpArray[ iloop ] = ""
         ENDIF
         RETURN .T.
      ENDIF
   NEXT
RETURN .F.

FUNCTION DoScript( aScript, aParams )

LOCAL arlen, stroka, varName, varValue, lDebug, lParam, j, lSetDebugger := .F.
MEMVAR iscr, bOldError, aScriptt, doscr_RetValue
PRIVATE iscr := 1, bOldError, doscr_RetValue := Nil

   IF Type( "aScriptt" ) != "A"
      PRIVATE aScriptt := aScript
   ENDIF
   IF aScript == Nil .OR. ( arlen := Len( aScript[ 2 ] ) ) == 0
      RETURN .T.
   ENDIF
   lDebug := ( Len( aScript ) >= 3 )
   DO WHILE Valtype( aScript[ 2, iscr ] ) != "B"
      IF Valtype( aScript[ 2, iscr ] ) == "C"
         IF Left( aScript[ 2, iscr ], 1 ) == "#"
            IF !lDebugger
               lSetDebugger := .T.
               SetDebugger()
            ENDIF
         ELSE
            stroka    := Substr( aScript[ 2, iscr ], 2 )
            lParam    := ( Left( aScript[ 2, iscr ], 1 ) == "/" )
            bOldError := Errorblock( { | e | MacroError( 2, e ) } )
            BEGIN SEQUENCE
               j := 1
               DO WHILE !Empty( varName := getNextVar( @stroka, @varValue ) )
                  PRIVATE &varName
                  IF varvalue != Nil
                     &varName := &varValue
                  ENDIF
                  IF lParam .AND. aParams != Nil .AND. Len( aParams ) >= j
                     &varname := aParams[ j ]
                  ENDIF
                  j ++
               ENDDO
            RECOVER
               WndOut()
               Errorblock( bOldError )
               RETURN .F.
            END SEQUENCE
            Errorblock( bOldError )
         ENDIF
      ENDIF
      iscr ++
   ENDDO
   IF lDebug
      bOldError := Errorblock( { | e | MacroError( 3, e, aScript[ 3, iscr ] ) } )
   ELSE
      bOldError := Errorblock( { | e | MacroError( 3, e, Ltrim( Str( iscr ) ) ) } )
   ENDIF
   BEGIN SEQUENCE
      IF lDebug .AND. lDebugger
         DO WHILE iscr > 0 .AND. iscr <= arlen
#ifdef __WINDOWS__
            IF lDebugger
               lDebugRun := .F.
               hwg_scrDebug( aScript, iscr )
               DO WHILE !lDebugRun
                  hwg_ProcessMessage()
               ENDDO
            ENDIF
#endif
            Eval( aScript[ 2, iscr ] )
            iscr ++
         ENDDO
#ifdef __WINDOWS__
         hwg_scrDebug( aScript, 0 )
         IF lSetDebugger
            SetDebugger( .F. )
         ENDIF
#endif
      ELSE
         DO WHILE iscr > 0 .AND. iscr <= arlen
            Eval( aScript[ 2, iscr ] )
            iscr ++
         ENDDO
      ENDIF
   RECOVER
      WndOut()
      Errorblock( bOldError )
#ifdef __WINDOWS__
      IF lDebug .AND. lDebugger
         hwg_scrDebug( aScript, 0 )
      ENDIF
#endif
      RETURN .F.
   END SEQUENCE
   Errorblock( bOldError )
   WndOut()

RETURN m->doscr_RetValue

FUNCTION CallFunc( cProc, aParams, aScript )

LOCAL i := 1, RetValue := Nil

   IF aScript == Nil
      aScript := m->aScriptt
   ENDIF
   cProc := Upper( cProc )
   DO WHILE i <= Len( aScript[ 2 ] ) .AND. Valtype( aScript[ 2, i ] ) == "A"
      IF aScript[ 2, i, 1 ] == cProc
         RetValue := DoScript( aScript[ 2, i ], aParams )
         EXIT
      ENDIF
      i ++
   ENDDO

RETURN RetValue

FUNCTION EndScript( xRetValue )

   m->doscr_RetValue := xRetValue
   iscr := - 99
RETURN Nil

FUNCTION CompileErr( nLine )

   nLine := numlin
RETURN nLastError

FUNCTION Codeblock( string )

   IF Left( string,2 ) == "{|"
      Return &( string )
   ENDIF
RETURN &("{||"+string+"}")

FUNCTION SetDebugInfo( lDebug )

   lDebugInfo := Iif( lDebug==Nil, .T., lDebug )
RETURN .T.

FUNCTION SetDebugger( lDebug )

   lDebugger := Iif( lDebug==Nil, .T., lDebug )
RETURN .T.

FUNCTION SetDebugRun()

   lDebugRun := .T.
RETURN .T.

Function RunScript( fname, scrname, args )
Local scr := OpenScript( fname, scrname )
Return Iif( scr==Nil, Nil, DoScript( scr, args ) )

#ifdef __WINDOWS__

STATIC FUNCTION WndOut()

   RETURN Nil

#else

FUNCTION WndOut( sout, noscroll, prnew )

LOCAL y1, x1, y2, x2, oldc, ly__size := (y__size != 0)
STATIC w__buf
   IF sout == Nil .AND. !ly__size
      Return Nil
   ENDIF
   IF y__size == 0
      y__size := 5
      x__size := 30
      prnew   := .T.
   ELSEIF prnew == Nil
      prnew := .F.
   ENDIF
   y1 := 13 - INT( y__size / 2 )
   x1 := 41 - INT( x__size / 2 )
   y2 := y1 + y__size
   x2 := x1 + x__size
   IF sout == Nil 
      RESTSCREEN( y1, x1, y2, x2, w__buf )
      y__size := 0
   ELSE
      oldc := SETCOLOR( "N/W" )
      IF prnew
         w__buf := SAVESCREEN( y1, x1, y2, x2 )
         @ y1, x1, y2, x2 BOX "ÚÄ¿³ÙÄÀ³ "
      ELSEIF noscroll = Nil
         SCROLL( y1 + 1, x1 + 1, y2 - 1, x2 - 1, 1 )
      ENDIF
      @ y2 - 1, x1 + 2 SAY sout         
      SETCOLOR( oldc )
   ENDIF
RETURN Nil

FUNCTION WndGet( sout, varget, spict )

LOCAL y1, x1, y2, x2, oldc
LOCAL GetList := {}
   WndOut( sout )
   y1   := 13 - INT( y__size / 2 )
   x1   := 41 - INT( x__size / 2 )
   y2   := y1 + y__size
   x2   := x1 + x__size
   oldc := SETCOLOR( "N/W" )
   IF LEN( sout ) + IIF( spict = "@D", 8, LEN( spict ) ) > x__size - 3
      SCROLL( y1 + 1, x1 + 1, y2 - 1, x2 - 1, 1 )
   ELSE
      x1 += LEN( sout ) + 1
   ENDIF
   @ y2 - 1, x1 + 2 GET varget PICTURE spict        
   READ
   SETCOLOR( oldc )
RETURN IIF( LASTKEY() = 27, Nil, varget )

FUNCTION WndOpen( ysize, xsize )

   y__size := ysize
   x__size := xsize
   WndOut( "",, .T. )
RETURN Nil
#endif
