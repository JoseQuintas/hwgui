/*
 * $Id: procscri.prg,v 1.8 2004-12-08 08:23:17 alkresin Exp $
 *
 * Common procedures
 * Scripts
 *
 * Author: Alexander S.Kresin <alex@belacy.belgorod.su>
 *         www - http://kresin.belgorod.su
*/
*+≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤
*+
*+    Source Module => D:\MYAPPS\SOURCE\PROCS\PROCSCRI.PRG
*+
*+    Functions: Function RdScript()
*+               Static Function Fou_If()
*+               Static Function Fou_Do()
*+               Function DoScript()
*+
*+    Reformatted by Click! 2.00 on Apr-12-2001 at  9:01 pm
*+
*+≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤

#include "fileio.ch"
#define __WINDOWS__

Memvar iscr

STATIC nLastError, numlin, scr_RetValue
#ifndef __WINDOWS__
STATIC y__size := 0, x__size := 0
#endif
#define STR_BUFLEN  1024

FUNCTION OpenScript( fname, scrkod )
LOCAL han, stroka, scom, aScr, rejim := 0, i
LOCAL strbuf := Space(STR_BUFLEN), poz := STR_BUFLEN+1
LOCAL aFormCode, aFormName

   scrkod = IIF( scrkod=Nil,"000",Upper(scrkod) )
   han := FOPEN( fname, FO_READ + FO_SHARED )
   IF han <> - 1
      DO WHILE .T.
         stroka := RDSTR( han,@strbuf,@poz,STR_BUFLEN )
         IF LEN( stroka ) = 0
            EXIT
         ELSEIF rejim == 0 .AND. Left( stroka,1 ) == "#"
            IF Upper( LEFT( stroka, 7 ) ) == "#SCRIPT"
               scom := Upper( Ltrim( Substr( stroka,9 ) ) )
               IF scom == scrkod
                  aScr := RdScript( han, @strbuf, @poz )
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
#ifdef __HARBOUR__
            i := WCHOICE( aFormName )
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
      MsgStop( fname + " can't be opened " )
#else
      ALERT( fname + " can't be opened " )
#endif
      RETURN Nil
   ENDIF
RETURN aScr

*+±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*+
*+    Function RdScript()
*+
*+±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*+
FUNCTION RdScript( scrSource, strbuf, poz )
LOCAL han
LOCAL rezArray := { "", {} }

   IF poz == Nil
      poz := 1
   ENDIF
   numlin := 1
   nLastError := 0
   IF scrSource == Nil
      han := Nil
      poz := 0
   ELSEIF VALTYPE( scrSource ) == "C"
      strbuf := SPACE( STR_BUFLEN )
      poz    := STR_BUFLEN+1
      han    := FOPEN( scrSource, FO_READ + FO_SHARED )
   ELSE
      han := scrSource
   ENDIF
   IF han == Nil .OR. han <> - 1
      IF VALTYPE( scrSource ) == "C"
         WndOut( "Compiling ..." )
         WndOut( "" )
      ENDIF
      IF !CompileScr( han, @strbuf, @poz, rezArray, scrSource )
         rezArray := Nil
      ENDIF
      IF scrSource != Nil .AND. VALTYPE( scrSource ) == "C"
         WndOut()
         FCLOSE( han )
      ENDIF
   ELSE
#ifdef __WINDOWS__
#ifdef ENGLISH
      MsgStop( "Can't open " + scrSource )
#else
      MsgStop( "ç• „§†´Æ·Ï Æ‚™‡Î‚Ï " + scrSource )
#endif
#else
#ifdef ENGLISH
      WndOut( "Can't open " + scrSource )
#else
      WndOut( "ç• „§†´Æ·Ï Æ‚™‡Î‚Ï " + scrSource )
#endif
      WAIT ""
      WndOut()
#endif
      nLastError := -1
      RETURN Nil
   ENDIF
RETURN rezArray

STATIC FUNCTION COMPILESCR( han, strbuf, poz, rezArray, scrSource )
LOCAL scom, poz1, stroka, strfull := "", bOldError, i, tmpArray := {}
Local cLine, lDebug := ( Len( rezArray ) == 3 )

   DO WHILE .T.
      stroka := RDSTR( han, @strbuf, @poz, STR_BUFLEN )
      IF LEN( stroka ) = 0
         EXIT
      ENDIF
      IF Right( stroka,1 ) == ';'
         strfull += Left( stroka,Len(stroka)-1 )
         LOOP
      ELSE
         IF !Empty( strfull )
            stroka := strfull + stroka
         ENDIF
         strfull := ""
      ENDIF
      numlin ++
      stroka := RTRIM( LTRIM( stroka ) )
      IF RIGHT( stroka, 1 ) = CHR( 26 )
         stroka := LEFT( stroka, LEN( stroka ) - 1 )
      ENDIF
      IF .NOT. EMPTY( stroka ) .AND. LEFT( stroka, 2 ) <> "//"

         cLine := stroka
         IF Left( stroka,1 ) == "#"
            IF UPPER( Left( stroka,7 ) ) == "#ENDSCR"
               Return .T.
            ELSEIF UPPER( Left( stroka,6 ) ) == "#DEBUG"
               IF !lDebug .AND. Len( rezArray[2] ) == 0
                  lDebug := .T.
                  Aadd( rezArray, {} )
                  LOOP
               ENDIF
#ifdef __HARBOUR__
            ELSE
               __ppAddRule( stroka )
               LOOP
#endif
            ENDIF
#ifdef __HARBOUR__
         ELSE
            stroka := __Preprocess( stroka )
#endif
         ENDIF

         poz1 := AT( " ", stroka )
         scom := UPPER( SUBSTR( stroka, 1, IIF( poz1 <> 0, poz1 - 1, 999 ) ) )
         DO CASE
         CASE scom = "PRIVATE" .OR. scom = "PARAMETERS"
            IF LEN( rezArray[2] ) == 0 .OR. ( i := VALTYPE( ATAIL( rezArray[2] ) ) ) == "C" ;
                    .OR. i == "A"
               IF Left( scom,2 ) == "PR"
                  AADD( rezArray[2], " "+ALLTRIM( SUBSTR( stroka, 9 ) ) )
               ELSE
                  AADD( rezArray[2], "/"+ALLTRIM( SUBSTR( stroka, 12 ) ) )
               ENDIF
               AADD( tmpArray, "" )
            ELSE
               nLastError := 1
               RETURN .F.
            ENDIF
         CASE ( scom = "DO" .AND. UPPER( SUBSTR( stroka, 4, 5 ) ) = "WHILE" ) ;
                .OR. scom == "WHILE"
            AADD( tmpArray, stroka )
            AADD( rezArray[2], .F. )
         CASE scom = "ENDDO"
            IF .NOT. Fou_Do( rezArray[2], tmpArray )
               nLastError := 2
               RETURN .F.
            ENDIF
         CASE scom = "EXIT"
            AADD( tmpArray, "EXIT" )
            AADD( rezArray[2], .F. )
         CASE scom = "LOOP"
            AADD( tmpArray, "LOOP" )
            AADD( rezArray[2], .F. )
         CASE scom = "IF"
            AADD( tmpArray, stroka )
            AADD( rezArray[2], .F. )
         CASE scom = "ELSEIF"
            IF .NOT. Fou_If( rezArray[2], tmpArray, .T. )
               nLastError := 3
               RETURN .F.
            ENDIF
            AADD( tmpArray, SUBSTR( stroka, 5 ) )
            AADD( rezArray[2], .F. )
         CASE scom = "ELSE"
            IF .NOT. Fou_If( rezArray[2], tmpArray, .T. )
               nLastError := 1
               RETURN .F.
            ENDIF
            AADD( tmpArray, "IF .T." )
            AADD( rezArray[2], .F. )
         CASE scom = "ENDIF"
            IF .NOT. Fou_If( rezArray[2], tmpArray, .F. )
               nLastError := 1
               RETURN .F.
            ENDIF
         CASE scom = "RETURN"
            AADD( rezArray[2], &( "{||EndScript("+Ltrim( Substr( stroka,7 ) )+")}" ) )
            AADD( tmpArray, "" )
         CASE scom = "FUNCTION"
            stroka := Ltrim( Substr( stroka,poz1+1 ) )
            poz1 := At( "(",stroka )
            scom := UPPER( SUBSTR( stroka, 1, IIF( poz1 <> 0, poz1 - 1, 999 ) ) )
            AADD( rezArray[2], Iif( lDebug,{ scom,{},{} },{ scom,{} } ) )
            AADD( tmpArray, "" )
            IF !CompileScr( han, @strbuf, @poz, rezArray[2,Len(rezArray[2])] )
               RETURN .F.
            ENDIF
         CASE scom = "#ENDSCRIPT" .OR. Left( scom,7 ) == "ENDFUNC"
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
            Aadd( rezArray[3], Ltrim( Str( Len(rezArray[2]),4 ) ) + ;
                ": " + cLine )
         ENDIF
      ENDIF
   ENDDO
RETURN .T.

STATIC FUNCTION MacroError( nm, e, stroka )
Local n

#ifdef __WINDOWS__
   IF nm == 1
      MsgStop( ErrorMessage( e ) + Chr(10)+Chr(13) + "in" + Chr(10)+Chr(13) + ;
             AllTrim(stroka),"Script compiling error" )
   ELSEIF nm == 2
      MsgStop( ErrorMessage( e ),"Script variables error" )
   ELSEIF nm == 3
      n := 2
      WHILE !Empty( ProcName( n ) )
        stroka += Chr(13)+Chr(10) + "Called from " + ProcName( n ) + "(" + AllTrim( Str( ProcLine( n++ ) ) ) + ")"
      ENDDO
      MsgStop( ErrorMessage( e )+ Chr(10)+Chr(13) + stroka,"Script execution error" )
   ENDIF
#else
   IF nm == 1
      ALERT( "Error in;" + AllTrim(stroka) )
   ELSEIF nm == 2
      Alert( "Script variables error" )
   ELSEIF nm == 3
      Alert( "Script execution error:;"+stroka )
   ENDIF
#endif
   BREAK
RETURN .T.

*+±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*+
*+    Static Function Fou_If()
*+
*+    Called from ( procscri.prg )   3 - function rdscript()
*+
*+±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*+
STATIC FUNCTION Fou_If( rezArray, tmpArray, prju )

LOCAL i, j, bOldError
   IF prju
      AADD( tmpArray, "JUMP" )
      AADD( rezArray, .F. )
   ENDIF
   j := LEN( rezArray )
   FOR i := j TO 1 STEP - 1
      IF .NOT. EMPTY( tmpArray[ i ] ) .AND. UPPER( LEFT( tmpArray[ i ], 2 ) ) = "IF"
         bOldError := ERRORBLOCK( { | e | MacroError(1,e,tmpArray[ i ]) } )
         BEGIN SEQUENCE
            rezArray[ i ] = &( "{||IIF(" + ALLTRIM( SUBSTR( tmpArray[ i ], 4 ) ) + ;
                 ",.T.,iscr:=" + LTRIM( STR( j, 5 ) ) + ")}" )
         RECOVER
            ERRORBLOCK( bOldError )
            RETURN .F.
         END SEQUENCE
         ERRORBLOCK( bOldError )
         tmpArray[ i ] = ""
         i --
         IF i > 0 .AND. .NOT. EMPTY( tmpArray[ i ] ) .AND. tmpArray[ i ] = "JUMP"
            rezArray[ i ] = &( "{||iscr:=" + LTRIM( STR( IIF( prju, j - 1, j ), 5 ) ) + "}" )
            tmpArray[ i ] = ""
         ENDIF
         RETURN .T.
      ENDIF
   NEXT
RETURN .F.

*+±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*+
*+    Static Function Fou_Do()
*+
*+    Called from ( procscri.prg )   1 - function rdscript()
*+
*+±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*+
STATIC FUNCTION Fou_Do( rezArray, tmpArray )

LOCAL i, j, iloop := 0, iPos, bOldError
   j := LEN( rezArray )
   FOR i := j TO 1 STEP - 1
      IF .NOT. EMPTY( tmpArray[ i ] ) .AND. LEFT( tmpArray[ i ], 4 ) = "EXIT"
         rezArray[ i ] = &( "{||iscr:=" + LTRIM( STR( j + 1, 5 ) ) + "}" )
         tmpArray[ i ] = ""
      ENDIF
      IF .NOT. EMPTY( tmpArray[ i ] ) .AND. LEFT( tmpArray[ i ], 4 ) = "LOOP"
         iloop := i
      ENDIF
      IF .NOT. EMPTY( tmpArray[ i ] ) .AND. ;
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

*+±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*+
*+    Function DoScript()
*+
*+±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*+
FUNCTION DoScript( aScript, aParams )
LOCAL arlen, stroka, varName, varValue, lDebug, lParam, j
MEMVAR iscr, bOldError, aScriptt
PRIVATE iscr := 1, bOldError

   scr_RetValue := Nil
   IF Type( "aScriptt" ) != "A"
      Private aScriptt := aScript
   ENDIF
   IF aScript == Nil .OR. ( arlen := Len( aScript[2] ) ) == 0
      Return .T.
   ENDIF
   lDebug := ( Len( aScript ) == 3 )
   DO WHILE VALTYPE( aScript[ 2,iscr ] ) != "B"
      IF VALTYPE( aScript[ 2,iscr ] ) == "C"
         stroka := Substr( aScript[ 2,iscr ],2 )
         lParam := ( Left( aScript[ 2,iscr ],1 ) == "/" )
         bOldError := ERRORBLOCK( { | e | MacroError(2,e) } )
         BEGIN SEQUENCE
         j := 1
         DO WHILE !EMPTY( varName := getNextVar( @stroka, @varValue ) )
            PRIVATE &varName
            IF varvalue != Nil
               &varName := &varValue
            ENDIF
            IF lParam .AND. aParams != Nil .AND. Len(aParams) >= j
               &varname = aParams[ j ]
            ENDIF
            j ++
         ENDDO
         RECOVER
            WndOut()
            ERRORBLOCK( bOldError )
            Return .F.
         END SEQUENCE
         ERRORBLOCK( bOldError )
      ENDIF
      iscr ++
   ENDDO
   IF lDebug
      bOldError := ERRORBLOCK( { | e | MacroError(3,e,aScript[3,iscr]) } )
   ELSE
      bOldError := ERRORBLOCK( { | e | MacroError(3,e,LTrim(Str(iscr))) } )
   ENDIF
   BEGIN SEQUENCE
      DO WHILE iscr > 0 .AND. iscr <= arlen
         EVAL( aScript[ 2,iscr ] )
         iscr ++
      ENDDO
   RECOVER
      WndOut()
      ERRORBLOCK( bOldError )
      Return .F.
   END SEQUENCE
   ERRORBLOCK( bOldError )
   WndOut()

RETURN scr_RetValue

FUNCTION CallFunc( cProc, aParams, aScript )
Local i := 1
MEMVAR aScriptt

   IF aScript == Nil
      aScript := aScriptt
   ENDIF
   scr_RetValue := Nil
   cProc := Upper( cProc )
   DO WHILE i <= Len(aScript[2]) .AND. VALTYPE( aScript[2,i] ) == "A"
      IF aScript[2,i,1] == cProc
         DoScript( aScript[2,i],aParams )
         EXIT
      ENDIF
      i ++
   ENDDO
   
RETURN scr_RetValue

FUNCTION EndScript( xRetValue )
   scr_RetValue := xRetValue
   iscr := -99
RETURN Nil

FUNCTION CompileErr( nLine )
   nLine := numlin
RETURN nLastError

FUNCTION Codeblock( string )
   IF Left( string,2 ) == "{|"
      Return &( string )
   ENDIF
RETURN &("{||"+string+"}")

#ifdef __WINDOWS__

FUNCTION WndOut()
RETURN Nil

#else

*+±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*+
*+    Function WndOut()
*+
*+    Called from ( procscri.prg )   4 - function rdscript()
*+                                   1 - function doscript()
*+                                   1 - function wndget()
*+                                   1 - function wndopen()
*+
*+±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*+
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
         @ y1, x1, y2, x2 BOX "⁄ƒø≥Ÿƒ¿≥ "
      ELSEIF noscroll = Nil
         SCROLL( y1 + 1, x1 + 1, y2 - 1, x2 - 1, 1 )
      ENDIF
      @ y2 - 1, x1 + 2 SAY sout         
      SETCOLOR( oldc )
   ENDIF
RETURN Nil

*+±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*+
*+    Function WndGet()
*+
*+±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*+
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

*+±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*+
*+    Function WndOpen()
*+
*+±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*+
FUNCTION WndOpen( ysize, xsize )

   y__size := ysize
   x__size := xsize
   WndOut( "",, .T. )
RETURN Nil
#endif
