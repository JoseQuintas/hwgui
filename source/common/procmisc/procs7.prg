/*
 * $Id$
 *
 * Common procedures
 *
 *
 * Author: Alexander S.Kresin <alex@kresin.ru>
 *         www - http://www.kresin.ru
*/

FUNCTION RDSTR( han, strbuf, poz, buflen )
   LOCAL stro := "", rez, oldpoz, poz1

   oldpoz := poz
   poz    := At( Chr( 10 ), SubStr( strbuf, poz ) )
   IF poz = 0
      IF han <> Nil
         stro += SubStr( strbuf, oldpoz )
         rez  := FRead( han, @strbuf, buflen )
         IF rez = 0
            RETURN ""
         ELSEIF rez < buflen
            strbuf := SubStr( strbuf, 1, rez ) + Chr( 10 ) + Chr( 13 )
         ENDIF
         poz  := At( Chr( 10 ), strbuf )
         stro += SubStr( strbuf, 1, poz )
      ELSE
         stro += RTrim( SubStr( strbuf, oldpoz ) )
         poz  := oldpoz + Len( stro )
         IF Len( stro ) == 0
            RETURN ""
         ENDIF
      ENDIF
   ELSE
      stro += SubStr( strbuf, oldpoz, poz )
      poz  += oldpoz - 1
   ENDIF
   poz ++
   poz1 := Len( stro )
   IF poz1 > 2 .AND. Right( stro, 1 ) $ Chr( 13 ) + Chr( 10 )
      IF SubStr( stro, poz1 - 1, 1 ) $ Chr( 13 ) + Chr( 10 )
         poz1 --
      ENDIF
      stro := SubStr( stro, 1, poz1 - 1 )
   ENDIF

   RETURN stro

FUNCTION getNextVar( stroka, varValue )

   LOCAL varName, iPosEnd, iPos3

   IF Empty( stroka )
      RETURN ""
   ELSE
      IF ( iPosEnd := Find_Z( stroka ) ) == 0
         iPosEnd := iif( Right( stroka, 1 ) = ';', Len( stroka ), Len( stroka ) + 1 )
      ENDIF
      ipos3    := Find_Z( Left( stroka, iPosEnd - 1 ), ':' )
      varName  := RTrim( LTrim( Left( stroka, iif( ipos3 = 0, iPosEnd, iPos3 ) - 1 ) ) )
      varValue := iif( iPos3 <> 0, LTrim( SubStr( stroka, iPos3 + 2, iPosEnd - iPos3 - 2 ) ), Nil )
      stroka   := SubStr( stroka, iPosEnd + 1 )
   ENDIF

   RETURN varName

FUNCTION FIND_Z( stroka, symb )

   LOCAL poz, poz1 := 1, i, j, ms1 := "(){}[]'" + '"', ms2 := { 0, 0, 0, 0, 0, 0, 0, 0 }

   symb := iif( symb = Nil, ",", symb )
   DO WHILE .T.
      poz := At( symb, SubStr( stroka, poz1 ) )
      IF poz = 0
         EXIT
      ELSE
         poz := poz + poz1 - 1
      ENDIF
      FOR i := poz1 TO poz - 1
         IF ( j := At( SubStr( stroka, i, 1 ), ms1 ) ) <> 0
            ms2[ j ] ++
         ENDIF
      NEXT
      IF ms2[ 1 ] == ms2[ 2 ] .AND. ms2[ 3 ] == ms2[ 4 ] .AND. ;
            ms2[ 5 ] == ms2[ 6 ] .AND. ms2[ 7 ] % 2 == 0 .AND. ms2[ 8 ] % 2 == 0
         EXIT
      ELSE
         IF ( j := At( SubStr( stroka, poz, 1 ), ms1 ) ) <> 0
            ms2[ j ] ++
         ENDIF
         poz1 := poz + 1
      ENDIF
   ENDDO

   RETURN poz

#ifdef __WINDOWS__

FUNCTION Fchoice()

   RETURN 1

#endif

FUNCTION CutExten( fname )

   LOCAL i

   RETURN iif( ( i := RAt( '.', fname ) ) = 0, fname, SubStr( fname, 1, i - 1 ) )

FUNCTION FilExten( fname )

   LOCAL i

   RETURN iif( ( i := RAt( '.', fname ) ) = 0, "", SubStr( fname, i + 1 ) )

FUNCTION FilePath( fname )

   LOCAL i

   RETURN iif( ( i := RAt( '\', fname ) ) = 0, ;
      iif( ( i := RAt( '/', fname ) ) = 0, "", Left( fname, i ) ), ;
      Left( fname, i ) )

FUNCTION CutPath( fname )

   LOCAL i

   RETURN iif( ( i := RAt( '\', fname ) ) = 0, ;
      iif( ( i := RAt( '/', fname ) ) = 0, fname, SubStr( fname, i + 1 ) ), ;
      SubStr( fname, i + 1 ) )

FUNCTION AddPath( fname, cPath )

   IF Empty( FilePath( fname ) ) .AND. !Empty( cPath )
      IF !( Right( cPath,1 ) $ "\/" )
#ifdef __PLATFORM__UNIX
         cPath += "/"
#else
         cPath += "\"
#endif
      ENDIF
      fname := cPath + fname
   ENDIF

   RETURN fname

FUNCTION NextItem( stroka, lFirst, cSep )

   STATIC nPos
   LOCAL i, oldPos

   IF ( lFirst != Nil .AND. lFirst ) .OR. nPos == Nil
      nPos := 1
   ENDIF
   IF cSep == Nil
      cSep := ";"
   ENDIF
   IF nPos != 99999
      oldPos := nPos
      IF ( i := At( cSep, SubStr( stroka, nPos ) ) ) == 0
         nPos := 99999
         RETURN LTrim( RTrim( SubStr( stroka, oldPos ) ) )
      ELSE
         nPos += i
         RETURN LTrim( RTrim( SubStr( stroka, oldPos, i - 1 ) ) )
      ENDIF
   ENDIF

   RETURN ""

FUNCTION hwg_GetDirSep()
* returns the directory seperator character OS dependant
#ifdef __PLATFORM__WINDOWS
 RETURN "\"
#else
 RETURN "/"
#endif

* ===== EOF of proc7.prg =====
