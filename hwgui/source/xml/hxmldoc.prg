/*
 * $Id: hxmldoc.prg,v 1.1 2004-03-18 11:19:12 alkresin Exp $
 *
 * Harbour XML Library
 * HXmlDoc class
 *
 * Copyright 2003 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "HBClass.ch"
#include "fileio.ch"
#include "hxml.ch"

/*
 *  CLASS DEFINITION
 *  HXMLNode
 */

CLASS HXMLNode

   DATA title
   DATA type
   DATA aItems  INIT {}
   DATA aAttr   INIT {}

   METHOD New( cTitle, type, aAttr )
   METHOD Add( xItem )
   METHOD GetAttribute( cName )
   METHOD SetAttribute( cName,cValue )
   METHOD Save( handle,level )
ENDCLASS

METHOD New( cTitle, type, aAttr, cValue ) CLASS HXMLNode

   IF cTitle != Nil ; ::title := cTitle ; ENDIF
   IF aAttr  != Nil ; ::aAttr := aAttr  ; ENDIF
   ::type := Iif( type != Nil , type, HBXML_TYPE_TAG )
   IF cValue != Nil
      ::Add( cValue )
   ENDIF
Return Self

METHOD Add( xItem ) CLASS HXMLNode

   Aadd( ::aItems, xItem )
Return xItem

METHOD GetAttribute( cName ) CLASS HXMLNode
Local i := Ascan( ::aAttr,{|a|a[1]==cName} )

Return Iif( i==0, Nil, ::aAttr[ i,2 ] )

METHOD SetAttribute( cName,cValue ) CLASS HXMLNode
Local i := Ascan( ::aAttr,{|a|a[1]==cName} )

   IF i == 0
      Return .F.
   ELSE
      ::aAttr[ i,2 ] := cValue
   ENDIF

Return .T.

METHOD Save( handle,level ) CLASS HXMLNode
Local i, s, lNewLine

   s := Space(level*2) + '<'
   IF ::type == HBXML_TYPE_COMMENT
      s += '!--'
   ELSEIF ::type == HBXML_TYPE_CDATA
      s += '![CDATA['
   ELSEIF ::type == HBXML_TYPE_PI
      s += '?' + ::title
   ELSE
      s += ::title
   ENDIF
   FOR i := 1 TO Len( ::aAttr )
      s += ' ' + ::aAttr[i,1] + '="' + HBXML_Transform(::aAttr[i,2]) + '"'
   NEXT
   IF ::type == HBXML_TYPE_COMMENT
      s += '-->' + Chr(10)
   ELSEIF ::type == HBXML_TYPE_CDATA
      s += ']]>' + Chr(10)
   ELSEIF ::type == HBXML_TYPE_PI
      s += '?>' + Chr(10)
   ELSEIF ::type == HBXML_TYPE_SINGLE
      s += '/>' + Chr(10)
   ELSE
      s += '>'
      IF Len(::aItems) == 1 .AND. Valtype(::aItems[1]) == "C" .AND. ;
                Len(::aItems[1]) + Len(s) < 80
         lNewLine := .F.
      ELSE
         s += Chr(10)
         lNewLine := .T.
      ENDIF
   ENDIF
   FWrite( handle,s )

   FOR i := 1 TO Len( ::aItems )
      IF Valtype( ::aItems[i] ) == "C"
        FWrite( handle, HBXML_Transform( ::aItems[i] ) )
      ELSE
        ::aItems[i]:Save( handle, level+1 )
      ENDIF
   NEXT
   IF ::type == HBXML_TYPE_TAG
      FWrite( handle, Iif(lNewLine,Space(level*2),"") + '</' + ::title + '>' + Chr(10 ) )
   ENDIF
Return .T.


/*
 *  CLASS DEFINITION
 *  HXMLDoc
 */

CLASS HXMLDoc INHERIT HXMLNode

   METHOD New( encoding )
   METHOD Read( fname )
   METHOD Save( fname )
ENDCLASS

METHOD New( encoding ) CLASS HXMLDoc

   IF encoding != Nil
      Aadd( ::aAttr, { "version","1.0" } )
      Aadd( ::aAttr, { "encoding",encoding } )
   ENDIF

Return Self

METHOD Read( fname ) CLASS HXMLDoc
Local han := FOpen( fname, FO_READ )

   IF han != -1
      hbxml_GetDoc( Self,han )
      FClose( han )
   ENDIF
Return Self

METHOD Save( fname ) CLASS HXMLDoc
Local handle := FCreate( fname )
Local cEncod, i

   IF handle != -1
      IF ( cEncod := ::GetAttribute( "encoding" ) ) == Nil
         cEncod := "UTF-8"
      ENDIF
      FWrite( handle, '<?xml version="1.0" encoding="'+cEncod+'"?>'+Chr(10 ) )
      FOR i := 1 TO Len( ::aItems )
         ::aItems[i]:Save( handle, 0 )
      NEXT
      FClose( handle )
   ENDIF
Return .T.

