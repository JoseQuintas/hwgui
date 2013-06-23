/*
 * $Id$
 */

/*
 * HWGUI - Harbour Win32 GUI library source code:
 * The highliting class
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

#include "hbclass.ch"
#include "hxml.ch"

#define HILIGHT_GROUPS  4
#define HILIGHT_KEYW    1
#define HILIGHT_FUNC    2
#define HILIGHT_QUOTE   3
#define HILIGHT_COMM    4

#define MAX_ITEMS      40

Static cSpaces := e" \t", cQuotes := e"\"\'"

CLASS Hilight

   DATA   lCase      INIT .F.
   DATA   cCommands
   DATA   cFuncs
   DATA   cScomm
   DATA   cMcomm1, cMcomm2

   DATA   aLineStru, nItems
   DATA   lMultiComm

   METHOD New( cFile, cSection )
   METHOD Do( cLine, lComm, lCheck )
   METHOD AddItem( nPos1, nPos2, nType )
ENDCLASS

METHOD New( cFile, cSection ) CLASS Hilight
Local oIni, oMod, oNode, i, nPos

   ::aLineStru := Array( 20,3 )

   IF !Empty( cFile )
      IF Valtype( cFile ) == "C"
         oIni := HXMLDoc():Read( cFile )
         IF !Empty( oIni:aItems ) .AND. oIni:aItems[1]:title == "hilight"
            oIni := oIni:aItems[1]
            FOR i := 1 TO Len( oIni:aItems )
               IF oIni:aItems[i]:title == "module" .AND. oIni:aItems[i]:GetAttribute( "type" ) == cSection
                  oMod := oIni:aItems[i]
                  EXIT
               ENDIF
            NEXT
         ENDIF
      ELSEIF Valtype( cFile ) == "O"
         oMod := cFile
      ENDIF
      IF !Empty( oMod )      
         FOR i := 1 TO Len( oMod:aItems )
            oNode := oMod:aItems[i]
            IF oNode:title == "keywords"
               ::cCommands := " " + AllTrim( oNode:aItems[1] ) + " "
            ELSEIF oNode:title == "functions"
               ::cFuncs := " " + AllTrim( oNode:aItems[1] ) + " "
            ELSEIF oNode:title == "single_line_comment"
               ::cScomm := AllTrim( oNode:aItems[1] )
            ELSEIF oNode:title == "multi_line_comment"
               ::cMcomm1 := AllTrim( oNode:aItems[1] )
               IF ( nPos := At( " ", ::cMcomm1 ) ) > 0
                  ::cMcomm2 := Ltrim( Substr( ::cMcomm1,nPos+1 ) )
                  ::cMcomm1 := Trim( Left( ::cMcomm1,nPos-1 ) )
               ENDIF
            ELSEIF oNode:title == "case"
               IF oNode:GetAttribute( "value" ) == "on"
                  ::lCase := .T.
               ENDIF
            ENDIF
         NEXT
         IF !::lCase
            IF !Empty( ::cCommands )
               ::cCommands := Lower( ::cCommands )
            ENDIF
            IF !Empty( ::cFuncs )
               ::cFuncs := Lower( ::cFuncs )
            ENDIF
         ENDIF
      ENDIF
   ENDIF

Return Self

METHOD Do( cLine, lComm, lCheck ) CLASS Hilight
Local nLen := Len( cLine ), nLenS, nLenM
Local cs, cm
Local nPos, nPos1, cWord, c

   ::nItems := 0
   ::lMultiComm := .F.

   IF lCheck == Nil
      lCheck := .F.
   ELSEIF lCheck .AND. Empty( ::cMcomm1 )
      Return Nil
   ENDIF

   IF Empty( ::cMcomm1 )
      cm := ""
   ELSE
      cm := Left( ::cMcomm1,1 )
      nLenM := Len(::cMcomm1)
   ENDIF

   IF lComm != Nil .AND. lComm
      IF ( nPos := At( ::cMcomm2, cLine ) ) == 0
         IF !lCheck; ::AddItem( 1, Len(cLine), HILIGHT_COMM ); ENDIF
         ::lMultiComm := .T.
         Return Nil
      ELSE
         IF !lCheck; ::AddItem( 1, nPos, HILIGHT_COMM ); ENDIF
         nPos += nLenM
      ENDIF
   ELSE
      nPos := 1
   ENDIF

   IF Empty( ::cScomm )
      cs := ""
   ELSE
      cs := Left( ::cScomm,1 )
      nLenS := Len(::cScomm)
   ENDIF


   DO WHILE nPos <= nLen
      DO WHILE nPos <= nLen .AND. Substr( cLine,nPos,1 ) $ cSpaces; nPos++; ENDDO
      DO WHILE nPos <= nLen
         IF ( c := Substr( cLine,nPos,1 ) ) $ cQuotes
            nPos1 := nPos
            IF ( nPos := hb_At( c, cLine, nPos1+1 ) ) == 0
               nPos := Len( cLine )
            ENDIF
            IF !lCheck; ::AddItem( nPos1, nPos, HILIGHT_QUOTE ); ENDIF

         ELSEIF c == cs .AND. Substr( cLine, nPos, nLenS ) == ::cScomm
            IF !lCheck; ::AddItem( nPos, Len( cLine ), HILIGHT_COMM ); ENDIF
            nPos := Len( cLine ) + 1
            EXIT

         ELSEIF c == cm .AND. Substr( cLine, nPos, nLenM ) == ::cMcomm1
            nPos1 := nPos
            IF ( nPos := hb_At( ::cMcomm2, cLine, nPos1+1 ) ) == 0
               nPos := Len( cLine )
               ::lMultiComm := .T.
            ENDIF
            IF !lCheck; ::AddItem( nPos1, nPos, HILIGHT_COMM ); ENDIF
            nPos += nLenM - 1

         ELSEIF !lCheck .AND. IsLetter( c )
            nPos1 := nPos
            nPos ++
            DO WHILE IsLetter( Substr( cLine,nPos,1 ) ); nPos++; ENDDO
            cWord := " " + Iif( ::lCase, Substr( cLine, nPos1, nPos-nPos1 ), ;
                  Lower( Substr( cLine, nPos1, nPos-nPos1 ) ) ) + " "
            nPos --
            IF !Empty(::cCommands ) .AND. cWord $ ::cCommands
               ::AddItem( nPos1, nPos, HILIGHT_KEYW )
            ELSEIF !Empty(::cFuncs ) .AND. cWord $ ::cFuncs
               ::AddItem( nPos1, nPos, HILIGHT_FUNC )
            ENDIF

         ENDIF
         nPos ++
      ENDDO
   ENDDO
   
Return Nil

METHOD AddItem( nPos1, nPos2, nType ) CLASS Hilight

   IF ::nItems >= Len( ::aLineStru )
      Return Nil
   ENDIF
   ::nItems ++
   ::aLineStru[::nItems,1] := nPos1
   ::aLineStru[::nItems,2] := nPos2
   ::aLineStru[::nItems,3] := nType
   
Return Nil

Static Function IsLetter( c )
Return ( c >= "A" .AND. c <= "Z" ) .OR. ( c >= "a" .AND. c <= "z" ) .OR. ;
      c == "_" .OR. Asc(c) >= 128

