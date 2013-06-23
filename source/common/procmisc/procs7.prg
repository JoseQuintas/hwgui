/*
 * $Id$
 *
 * Common procedures
 *
 *
 * Author: Alexander S.Kresin <alex@belacy.belgorod.su>
 *         www - http://kresin.belgorod.su
*/

FUNCTION RDSTR( han, strbuf, poz, buflen )
LOCAL stro := "", rez, oldpoz, poz1

   oldpoz := poz
   poz    := At( Chr( 10 ), Substr( strbuf, poz ) )
   IF poz = 0
      IF han <> Nil
         stro += Substr( strbuf, oldpoz )
         rez  := Fread( han, @strbuf, buflen )
         IF rez = 0
            RETURN ""
         ELSEIF rez < buflen
            strbuf := Substr( strbuf, 1, rez ) + Chr( 10 ) + Chr( 13 )
         ENDIF
         poz  := At( Chr( 10 ), strbuf )
         stro += Substr( strbuf, 1, poz )
      ELSE
         stro += Rtrim( Substr( strbuf, oldpoz ) )
         poz  := oldpoz + Len( stro )
         IF Len( stro ) == 0
            RETURN ""
         ENDIF
      ENDIF
   ELSE
      stro += Substr( strbuf, oldpoz, poz )
      poz  += oldpoz - 1
   ENDIF
   poz ++
   poz1 := Len( stro )
   IF poz1 > 2 .AND. Right( stro, 1 ) $ Chr( 13 ) + Chr( 10 )
      IF Substr( stro, poz1 - 1, 1 ) $ Chr( 13 ) + Chr( 10 )
         poz1 --
      ENDIF
      stro := Substr( stro, 1, poz1 - 1 )
   ENDIF
RETURN stro

FUNCTION getNextVar( stroka, varValue )

LOCAL varName, iPosEnd, iPos3
   IF Empty( stroka )
      RETURN ""
   ELSE
      IF ( iPosEnd := Find_Z( stroka ) ) == 0
         iPosEnd := Iif( Right( stroka, 1 ) = ';', Len( stroka ), Len( stroka ) + 1 )
      ENDIF
      ipos3    := Find_Z( Left( stroka, iPosEnd - 1 ), ':' )
      varName  := Rtrim( Ltrim( Left( stroka, Iif( ipos3 = 0, iPosEnd, iPos3 ) - 1 ) ) )
      varValue := Iif( iPos3 <> 0, Ltrim( Substr( stroka, iPos3 + 2, iPosEnd - iPos3 - 2 ) ), Nil )
      stroka   := Substr( stroka, iPosEnd + 1 )
   ENDIF
RETURN varName

FUNCTION FIND_Z( stroka, symb )

LOCAL poz, poz1 := 1, i, j, ms1 := "(){}[]'" + '"', ms2 := { 0, 0, 0, 0, 0, 0, 0, 0 }

   symb := Iif( symb = Nil, ",", symb )
   DO WHILE .T.
      poz := At( symb, Substr( stroka, poz1 ) )
      IF poz = 0
         EXIT
      ELSE
         poz := poz + poz1 - 1
      ENDIF
      FOR i := poz1 TO poz - 1
         IF ( j := At( Substr( stroka, i, 1 ), ms1 ) ) <> 0
            ms2[ j ] ++
         ENDIF
      NEXT
      IF ms2[ 1 ] == ms2[ 2 ] .AND. ms2[ 3 ] == ms2[ 4 ] .AND. ;
                 ms2[ 5 ] == ms2[ 6 ] .AND. ms2[ 7 ] % 2 == 0 .AND. ms2[ 8 ] % 2 == 0
         EXIT
      ELSE
         IF ( j := At( Substr( stroka, poz, 1 ), ms1 ) ) <> 0
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
RETURN Iif( ( i := Rat( '.', fname ) ) = 0, fname, Substr( fname, 1, i - 1 ) )

FUNCTION FilExten( fname )

LOCAL i
RETURN Iif( ( i := Rat( '.', fname ) ) = 0, "", Substr( fname, i + 1 ) )

FUNCTION FilePath( fname )

LOCAL i
RETURN Iif( ( i := Rat( '\', fname ) ) = 0, ;
            Iif( ( i := Rat( '/', fname ) ) = 0, "", Left( fname, i ) ), ;
            Left( fname, i ) )

FUNCTION CutPath( fname )

LOCAL i
RETURN Iif( ( i := Rat( '\', fname ) ) = 0, ;
            Iif( ( i := Rat( '/', fname ) ) = 0, fname, Substr( fname, i + 1 ) ), ;
            Substr( fname, i + 1 ) )

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
      IF ( i := At( cSep, Substr( stroka, nPos ) ) ) == 0
         nPos := 99999
         RETURN Ltrim( Rtrim( Substr( stroka, oldPos ) ) )
      ELSE
         nPos += i
         RETURN Ltrim( Rtrim( Substr( stroka, oldPos, i - 1 ) ) )
      ENDIF
   ENDIF
RETURN ""
