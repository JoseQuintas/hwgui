/*
 * $Id$
 * DBCHW - DBC ( Harbour + HWGUI )
 * Views save and load functions
 *
 * Copyright 2013 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "dbchw.h"
#include "fileio.ch"

STATIC crlf := e"\r\n"

MEMVAR aFiles, aDrivers, numdriv, improc, lShared, lRdOnly, mypath, nServerType

FUNCTION RdView( fname )
   LOCAL aLines, nLine, res := .T.
   LOCAL scom, sword, i, n, nPos
   LOCAL aRel := {}, aFlt := {}

   IF Empty( fname )
      fname := hwg_Selectfile( "View files( *.vew )", "*.vew", mypath )
   ENDIF

   IF !Empty( fname ) .AND. !Empty( aLines := hb_aTokens( MemoRead( fname ), crlf  ) )
      FOR nLine := 1 TO Len( aLines )
         nPos := 0
         IF ( scom := Upper( hb_TokenPtr( aLines[nLine], @nPos, " " ) ) ) == "DRIVER"
            sword := hb_TokenPtr( aLines[nLine], @nPos, " " )
            IF hb_TokenPtr( aLines[nLine], @nPos, " " ) == "REMOTE"
#if defined( RDD_ADS )
               AdsSetServerType( 6 )
#elif !defined( RDD_LETO )
               res := .F.
               EXIT
#endif
            ELSE
               nServerType := LOCAL_SERVER
#if defined( RDD_ADS )
               AdsSetServerType( ADS_LOCAL_SERVER )
#elif defined( RDD_LETO )
               res := .F.
               EXIT
#endif
            ENDIF
            IF ( n := Ascan( aDrivers, sword ) ) == 0
               res := .F.
               EXIT
            ENDIF
            numdriv := n
#if defined( RDD_ADS )
            AdsSetFileType( Iif( n == 1,2,Iif( n == 2,1,3 ) ) )
#elif !defined( RDD_LETO )
            rddSetDefault( aDrivers[n] )
#endif
         ELSEIF scom == "FILE"
            lShared := ( hb_TokenPtr( aLines[nLine], @nPos, " " ) == "SHARED" )
            Set( _SET_EXCLUSIVE, !lShared )
            lRdonly := ( hb_TokenPtr( aLines[nLine], @nPos, " " ) == "READ" )
            IF Empty( sword := LTrim( SubStr( aLines[nLine], nPos + 1 ) ) )
               res := .F.
               EXIT
            ELSE
               OpenDbf( sword )
            ENDIF
         ELSEIF scom == "ORDER"
            IF !Empty( sword := LTrim( SubStr( aLines[nLine], nPos + 1 ) ) )
               OrdSetFocus( sword )
               UpdBrowse()
            ENDIF
         ELSEIF scom == "FILTER"
            AAdd( aFlt, { improc, LTrim( SubStr( aLines[nLine], nPos + 1 ) ) } )
         ELSEIF scom == "RELATION"
            sword := hb_TokenPtr( aLines[nLine], @nPos, " " )
            AAdd( aRel, { improc, sword, LTrim( SubStr( aLines[nLine], nPos + 1 ) ) } )
         ENDIF
      NEXT
      IF !res
         hwg_MsgStop( "View file error" )
      ELSE
         FOR i := 1 TO Len( aRel )
            dbSelectArea( aFiles[aRel[i,1],AF_ALIAS] )
            dbSetRelation( aRel[i,2], &( "{||" + aRel[i,3] + "}" ), aRel[i,3] )
         NEXT

         FOR i := 1 TO Len( aFlt )
            dbSelectArea( aFiles[aFlt[i,1],AF_ALIAS] )
            F_Filter( aFiles[aFlt[i,1],AF_BRW], aFlt[i,2] )
            UpdBrowse()
         NEXT
      ENDIF
   ENDIF

RETURN Nil

FUNCTION WrView()

   LOCAL i, han, j, strlen, obl, cTmp
#ifdef __GTK__
   Local fname := hwg_Selectfile( "View files( *.vew )","*.vew",mypath )
#else
   Local fname := hwg_Savefile( "*.vew","View files( *.vew )", "*.vew", mypath )
#endif

   IF Empty( fname )
      Return Nil
   ENDIF

   obl := SELECT()
   IF ( han := Fcreate( fname, FC_NORMAL ) ) != - 1
      FOR i := 1 TO Len( aFiles )
         IF !Empty( aFiles[i,AF_NAME] )
            dbSelectArea( aFiles[i,AF_ALIAS] )
            FWrite( han, "DRIVER " +  aDrivers[ aFiles[ improc,AF_DRIVER ] ] +  ;
               iif( nServerType == LOCAL_SERVER, " LOCAL", " REMOTE" ) + crlf )

            FWrite( han, "FILE " + Iif(aFiles[i,AF_EXCLU],"EXCLUSIVE ","SHARED ") + ;
                  Iif(aFiles[i,AF_RDONLY],"READ ","WRITE ") + ;
                  aFiles[i,AF_NAME] + crlf )

            IF !Empty( cTmp := OrdSetFocus() )
               FWrite( han, "ORDER " + cTmp + crlf )
            ENDIF

            IF !Empty( cTmp := dbFilter() )
               FWrite( han, "FILTER " + cTmp + crlf )
            ENDIF

            j := 0
            DO WHILE !Empty( cTmp := dbRelation( ++ j ) )
               FWrite( han, "RELATION " + Alias( dbRSelect( j ) ) + " " + cTmp + crlf )
            ENDDO
         ENDIF
      NEXT
      Fclose( han )
   ENDIF
   SELECT( obl )
RETURN Nil
