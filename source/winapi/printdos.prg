/*
 * $Id$
 *
 * CLASS PrintDos
 *
 * Copyright (c) Sandro Freire <sandrorrfreire@yahoo.com.br>
 * for HwGUI By Alexander Kresin
 *
 */
#include "hbclass.ch"
#include "windows.ch"
#include "guilib.ch"
#include "fileio.ch"

#define PF_BUFFERS   2048

#define oFORMFEED               "12"
#define oLASER10CPI             "27,40,115,49,48,72"
#define oLASER12CPI             "27,40,115,49,50,72"
#define oLASER18CPI             "27,40,115,49,56,72"
#define oLASERBOLD              "27,40,49,54,46,54,55,72"   //Added by  por Fernando Athayde 27(16.67H
#define oLASERUNBOLD            "27,40,115,49,50,72"        //Added by  por Fernando Athayde 27(s12H
#define oINKJETDOUBLE           "27,33,32"
#define oINKJETNORMAL           "27,33,00"
#define oINKJETCOMPRESS         "27,33,04"
#define oINKJETBOLD             "27,40,115,55,66"   //Added by  por Fernando Athayde
#define oINKJETUNBOLD           "27,40,115,48,66"   //Added by  por Fernando Athayde
#define oMATRIXDOUBLE           "14"
#define oMATRIXNORMAL           "18"
#define oMATRIXCOMPRESS         "15"
#define oMATRIXBOLD             "27,71"   //Added by  por Fernando Athayde
#define oMATRIXUNBOLD           "27,72"   //Added by  por Fernando Athayde

CLASS PrintDos

   DATA cCompr, cNormal, oText, cDouble, cBold, cUnBold AS CHARACTER
   DATA oPorta, oPicture      AS CHARACTER
   DATA orow, oCol            AS NUMERIC
   DATA cEject, nProw, nPcol, fText, gText
   DATA oTopMar               AS NUMERIC
   DATA oLeftMar              AS NUMERIC
   DATA oAns2Oem              AS LOGIC
   DATA LastError
   DATA oPrintStyle INIT 1 //1 = Matricial   2 = InkJet    3 = LaserJet
   DATA colorPreview
   DATA nStartPage init 1
   DATA nEndPage init 0
   DATA nCopy init 1

   METHOD New( oPorta ) CONSTRUCTOR

   METHOD Say( oProw, oCol, oTexto, oPicture )

   METHOD SetCols( nRow, nCol )

   METHOD gWrite( oText )

   METHOD NewLine()

   METHOD Eject()

   METHOD Compress()

   METHOD Double()

   METHOD DesCompress()

   METHOD Bold()       //Added by  por Fernando Athayde

   METHOD UnBold()     //Added by  por Fernando Athayde

   METHOD Comando()

   METHOD SetPrc( x, y )

   METHOD PrinterFile( oFile )

   METHOD TxttoGraphic( oFile, osize, oPreview )

   METHOD Preview( fname, cTitle )

   METHOD END()

ENDCLASS

METHOD New( oPorta ) CLASS PrintDos
   LOCAL oDouble  := { oMATRIXDOUBLE,   oINKJETDOUBLE,   oLASER10CPI }
   LOCAL oNormal  := { oMATRIXNORMAL,   oINKJETNORMAL,   oLASER12CPI }
   LOCAL oCompress := { oMATRIXCOMPRESS, oINKJETCOMPRESS, oLASER18CPI }
   LOCAL oBold    := { oMATRIXBOLD,     oINKJETBOLD,     oLASERBOLD  }       //Added by  por Fernando Athayde
   LOCAL oUnBold  := { oMATRIXUNBOLD,   oINKJETUNBOLD,   oLASERUNBOLD }       //Added by  por Fernando Athayde
   LOCAL oPtrSetup, oPtrName

   ::cCompr   := oCompress[ ::oPrintStyle ]
   ::cNormal  := oNormal[ ::oPrintStyle ]
   ::cDouble  := oDouble[ ::oPrintStyle ]
   ::cBold    := oBold[ ::oPrintStyle ]       //Added by  por Fernando Athayde
   ::cUnBold  := oUnBold[ ::oPrintStyle ]       //Added by  por Fernando Athayde
   ::cEject   := oFORMFEED
   ::nProw    := 0
   ::nPcol    := 0
   ::oTopMar  := 0
   ::oAns2Oem := .t.
   ::oLeftMar := 0
   ::oText    := ""

   IF Empty( oPorta ) //
      ::oPorta       := "LPT1"
   ELSE
      IF oPorta == "DEFAULT"
         oPtrName := hwg_Printportname()
         IF oPtrName == Nil
            hwg_Msginfo( "Error, file to:ERROR.TXT" )
            ::oPorta := "Error.txt"
         ELSE
            ::oPorta := oPtrName
         ENDIF
      ELSEIF oPorta == "SELECT"

         #ifdef __XHARBOUR__
            oPtrSetup := hwg_Printsetupdos( @::nStartPage, @::nEndPage, @::nCopy )
         #else
            oPtrSetup := hwg_Printsetupdos()
         #endif
         IF oPtrSetup == Nil
            hwg_Msginfo( "Error, file to:ERROR.TXT" )
            ::oPorta := "Error.txt"
         ELSE
            oPtrName := hwg_Printportname()
            IF oPtrName == Nil
               hwg_Msginfo( "Error, file to:ERROR.TXT" )
               ::oPorta := "Error.txt"
            ELSE
               oPtrName := AllTrim( oPtrName )
               IF SubStr( oPtrName, 1, 3 ) == "LPT"
                  oPtrName := Left( oPtrName, Len( oPtrName ) - 1 )
               ENDIF
               ::oPorta := oPtrName
            ENDIF
         ENDIF
      ELSE
         ::oPorta     := oPorta
      ENDIF
   ENDIF

   IF oPorta == "GRAPHIC" .or. oPorta == "PREVIEW"
      ::gText := ""
   ELSE
      // tracelog([          ::gText:=fCreate(::oPorta)])
      ::gText := FCreate( ::oPorta )
      //tracelog([depois           ::gText:=fCreate(::oPorta)],::gtext)
      IF ::gText < 0
         ::LastError := FError()
      ELSE
         ::LastError := 0
      ENDIF
   ENDIF


   RETURN Self


METHOD Comando( oComm1, oComm2, oComm3, oComm4, oComm5, oComm6, oComm7, ;
                oComm8, oComm9, oComm10 )  CLASS PrintDos

   LOCAL oStr := oComm1

   oStr := Chr( Val ( oComm1 ) )

   IF oComm2  != NIL ;  oStr += Chr( Val( oComm2 ) ) ;   ENDIF
   IF oComm3  != NIL ;  oStr += Chr( Val( oComm3 ) ) ;   ENDIF
   IF oComm4  != NIL ;  oStr += Chr( Val( oComm4 ) ) ;   ENDIF
   IF oComm5  != NIL ;  oStr += Chr( Val( oComm5 ) ) ;   ENDIF
   IF oComm6  != NIL ;  oStr += Chr( Val( oComm6 ) ) ;   ENDIF
   IF oComm7  != NIL ;  oStr += Chr( Val( oComm7 ) ) ;   ENDIF
   IF oComm8  != NIL ;  oStr += Chr( Val( oComm8 ) ) ;   ENDIF
   IF oComm9  != NIL ;  oStr += Chr( Val( oComm9 ) ) ;   ENDIF
   IF oComm10 != NIL ;  oStr += Chr( Val( oComm10 ) ) ;   ENDIF


   IF ::oAns2Oem
      ::oText += hwg_WIN_Ansitooem( oStr )
   ELSE
      ::oText += oStr
   ENDIF

   RETURN Nil


METHOD gWrite( oText )  CLASS PrintDos

   //tracelog(otext)
   IF ::oAns2Oem
      ::oText += hwg_WIN_Ansitooem( oText )
      ::nPcol += Len( hwg_WIN_Ansitooem( oText ) )
   ELSE
      ::oText += oText
      ::nPcol += Len( oText )
   ENDIF
   //tracelog(otext)

   RETURN Nil

METHOD Eject()   CLASS PrintDos
//tracelog( ::gText, ::oText )

   FWrite( ::gText, ::oText )

   IF ::oAns2Oem
      FWrite( ::gText, hwg_WIN_Ansitooem( Chr( 13 ) + Chr( 10 ) + Chr( Val( ::cEject ) ) ) )
      FWrite( ::gText, hwg_WIN_Ansitooem( Chr( 13 ) + Chr( 10 ) ) )
   ELSE
      FWrite( ::gText, Chr( 13 ) + Chr( 10 ) + Chr( Val( ::cEject ) ) )
      FWrite( ::gText, Chr( 13 ) + Chr( 10 ) )
   ENDIF

   ::oText := ""
   ::nProw := 0
   ::nPcol := 0
   //tracelog( ::gText, ::oText )
   RETURN Nil

METHOD Compress() CLASS PrintDos

   ::Comando( ::cCompr )

   RETURN Nil

METHOD Double() CLASS PrintDos

   ::Comando( ::cDouble )

   RETURN Nil

METHOD DesCompress() CLASS PrintDos

   ::Comando( ::cNormal )

   RETURN Nil

//*** Contribution Fernando Athayde ***

METHOD Bold() CLASS PrintDos

   ::Comando( ::cBold )

   RETURN Nil

METHOD UnBold() CLASS PrintDos

   ::Comando( ::cUnBold )

   RETURN Nil


METHOD NewLine() CLASS PrintDos

   IF ::oAns2Oem
      ::oText += hwg_WIN_Ansitooem( Chr( 13 ) + Chr( 10 ) )
   ELSE
      ::oText += Chr( 13 ) + Chr( 10 )
   ENDIF
   ::nPcol := 0
   RETURN Nil

METHOD Say( oProw, oPcol, oTexto, oPicture ) CLASS PrintDos
   // tracelog(oProw, oPcol, oTexto, oPicture)
   IF ValType( oTexto ) == "N"

      IF ! Empty( oPicture ) .or. oPicture # Nil
         oTexto := Transform( oTexto, oPicture )
      ELSE
         oTexto := Str( oTexto )
      ENDIF

   ELSEIF ValType( oTexto ) == "D"
      oTexto := DToC( oTexto )
   ELSE
      IF ! Empty( oPicture ) .or. oPicture # Nil
         oTexto := Transform( oTexto, oPicture )
      ENDIF
   ENDIF
   //tracelog([antes     ::SetCols(oProw, oPcol)])
   ::SetCols( oProw, oPcol )
   //tracelog([depois de ::SetCols(oProw, oPcol) e  antes         ::gWrite(oTexto))])
   ::gWrite( oTexto )

   RETURN Nil

METHOD SetCols( nProw, nPcol ) CLASS PrintDos

   IF ::nProw > nProw
      ::Eject()
   ENDIF

   IF ::nProw < nProw
      DO WHILE ::nProw < nProw
         ::NewLine()
         ++ ::nProw
      ENDDO
   ENDIF

   IF nProw == ::nProw  .AND. nPcol < ::nPcol
      ::Eject()
   ENDIF

   IF nPcol > ::nPcol
      ::gWrite( Space( nPcol - ::nPcol ) )
   ENDIF

   RETURN Nil

METHOD SetPrc( x, y ) CLASS PrintDos
   ::nProw := x
   ::nPCol := y
   RETURN Nil

METHOD END() CLASS PrintDos

   FWrite( ::gText, ::oText )
   FClose( ::gText )

   RETURN Nil

METHOD PrinterFile( fname ) CLASS PrintDos
   LOCAL strbuf := Space( PF_BUFFERS )
   LOCAL han, nRead

   IF ! File( fname )
      hwg_Msgstop( "Error open file " + fname, "Error" )
      RETURN .F.
   ENDIF

   han := FOpen( fname, FO_READWRITE + FO_EXCLUSIVE )

   IF han <> - 1

      DO WHILE .t.

         nRead := FRead( han, @strbuf, PF_BUFFERS )

         IF nRead = 0 ; EXIT ; ENDIF

         IF FWrite( ::gText, Left( strbuf, nRead ) ) < nRead
            ::ErrosAnt := FError()
            FClose( han )
            RETURN .F.
         ENDIF

      ENDDO

   ELSE

      hwg_Msgstop( "Can't Open port" )
      FClose( han )

   ENDIF

   RETURN .T.

FUNCTION hwg_wProw( oPrinter )

   RETURN oPrinter:nProw

FUNCTION hwg_wPCol( oPrinter )

   RETURN oPrinter:nPcol

FUNCTION hwg_wSetPrc( x, y, oPrinter )

   oPrinter:SetPrc( x, y )
   RETURN Nil

METHOD TxttoGraphic( fName, osize, oPreview ) CLASS PrintDos

   LOCAL strbuf := Space( 2052 ), poz := 2052, stroka
   LOCAL han := FOpen( fName, FO_READ + FO_SHARED )
   LOCAL oCol := 0, oPage := 1  //Added by  Por Fernando Athayde
   LOCAL oPrinter
   LOCAL oFont

   INIT PRINTER oPrinter // HPrinter():New()
// added by Giuseppe Mastrangelo
   IF oPrinter == nil
      RETURN .f.
   ENDIF
// end of added code
   oFont := oPrinter:AddFont( "Courier New", osize )

   oPrinter:StartDoc( oPreview  )
   oPrinter:StartPage()

   hwg_Selectobject( oPrinter:hDC, oFont:handle )

   IF han <> - 1
      DO WHILE .T.
         stroka := RDSTR( han, @strbuf, @poz, 2052 )
         IF Len( stroka ) = 0
            EXIT
         ENDIF
         IF osize < 0
            oPrinter:Say( stroka, 0, oCol, 2400, oCol + ( - osize + 2 ),, oFont )  //Added by  Por Fernando Athayde
            oCol := oCol + ( - osize + 2 )   //Added by  Por Fernando Athayde
         ELSE
            oPrinter:Say( stroka, 0, oCol, 2400, oCol + ( osize + 2 ),, oFont )  //Added by  Por Fernando Athayde
            oCol := oCol + ( osize + 2 )   //Added by  Por Fernando Athayde
         ENDIF

         IF Left( stroka, 1 ) == Chr( 12 )
            oPrinter:EndPage()
            oPrinter:StartPage()
            ++ oPage
            oCol := 0  //Added by  Por Fernando Athayde
         ENDIF

      ENDDO
      FClose( han )
   ELSE
      hwg_Msgstop( "Can't open " + fName )
      RETURN .F.
   ENDIF
   oPrinter:EndPage()
   oPrinter:EndDoc()
   oPrinter:Preview()
   oPrinter:END()
   oFont:Release()

   RETURN .T.

METHOD Preview( fName, cTitle ) CLASS PrintDos
   LOCAL oedit1
   LOCAL strbuf := Space( 2052 ), poz := 2052, stroka
   LOCAL han := FOpen( fName, FO_READ + FO_SHARED )
   LOCAL oCol := 10, oPage := 1, nPage := 1
   LOCAL oFont := HFont():Add( "Courier New", 0, - 13 )
   LOCAL oText := { "" }
   LOCAL oDlg, oColor1, oColor2
   LOCAL oEdit
   LOCAL oPrt := IIf( Empty( ::oPorta ) .or. ::oPorta == "PREVIEW", "LPT1", ::oPorta )

   IF han <> - 1
      DO WHILE .T.
         stroka := RDSTR( han, @strbuf, @poz, 2052 )
         IF Len( stroka ) = 0
            EXIT
         ENDIF
         IF ::oAns2Oem
            oText[ oPage ] += hwg_WIN_Ansitooem( stroka ) + Chr( 13 ) + Chr( 10 )
         ELSE
            oText[ oPage ] += stroka + Chr( 13 ) + Chr( 10 )
         ENDIF
         IF Left( stroka, 1 ) == Chr( 12 )
            AAdd( oText, "" )
            ++ oPage
         ENDIF
         oCol := oCol + 30
      ENDDO
      FClose( han )
   ELSE
      hwg_Msgstop( "Can't open " + fName )
      RETURN .F.
   ENDIF

   oEdit := SUBS( oText[ nPage ], 2 )  //Added by  Por Fernando Exclui 1 byte do oText nao sei de onde ele aparece

   IF ! Empty( ::colorpreview )
      oColor1 := ::colorpreview[ 1 ]
      oColor2 := ::colorpreview[ 2 ]
   ELSE
      oColor1 := 16777088
      oColor2 := 0
   ENDIF

   IIf( cTitle == Nil, cTitle := "Print Preview", cTitle := cTitle )

   INIT DIALOG oDlg TITLE cTitle ;
        At 0, 0 SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight() on init { || hwg_Sendmessage( oedit1:handle, WM_VSCROLL  , SB_TOP, 0 ) }



*   @ 88,19 EDITBOX oEdit ID 1001 SIZE 548,465 STYLE WS_VSCROLL + WS_HSCROLL + ES_AUTOHSCROLL + ES_MULTILINE ;
*        COLOR oColor1 BACKCOLOR oColor2  //Blue to Black  && Original
//   @ 88,19 EDITBOX oEdit ID 1001 SIZE 548,465 STYLE WS_VSCROLL + WS_HSCROLL + ES_AUTOHSCROLL + ES_MULTILINE ;
//        COLOR oColor1 BACKCOLOR oColor2 FONT oFont //Blue to Black  //Added by  por Fernando Athayde
   @ 88, 19 EDITBOX oedit1 CAPTION oEdit ID 1001 SIZE hwg_Getdesktopwidth() - 100, hwg_Getdesktopheight() - 100 STYLE WS_VSCROLL + WS_HSCROLL + ES_AUTOHSCROLL + ES_MULTILINE ;
      COLOR oColor1 BACKCOLOR oColor2 FONT oFont //Blue to Black  //Added by  por Fernando Athayde


*   @ 88,19 EDITBOX oEdit ID 1001 SIZE 548,465 STYLE WS_VSCROLL + WS_HSCROLL + ES_AUTOHSCROLL + ES_MULTILINE ;
*        COLOR oColor1 BACKCOLOR oColor2  //Blue to Black  && Original
//   @ 88,19 EDITBOX oEdit ID 1001 SIZE 548,465 STYLE WS_VSCROLL + WS_HSCROLL + ES_AUTOHSCROLL + ES_MULTILINE ;
//        COLOR oColor1 BACKCOLOR oColor2 FONT oFont //Blue to Black  //Added by  por Fernando Athayde
//       COLOR 16711680 BACKCOLOR 16777215  //Black to Write
   @ 6, 30 BUTTON "<<"    ON CLICK { || nPage := PrintDosAnt( nPage, oText ) } SIZE 69, 32  STYLE IF( nPage = 1, WS_DISABLED, 0 )
   @ 6, 80 BUTTON ">>"    ON CLICK { || nPage := PrintDosNext( oPage, nPage, oText ) } SIZE 69, 32 STYLE IF( nPage = 1, WS_DISABLED, 0 )
   @ 6, 130 BUTTON "Imprimir" ON CLICK { || PrintDosPrint( oText, oPrt ) } SIZE 69, 32
//   @ 6,180 BUTTON "Grafico" on Click {||hwg_EndDialog(),oDos2:TxttoGraphic(fName,2,.t.),oDos2:end()} SIZE 69,32
   @ 6, 230 BUTTON "Fechar" ON CLICK { || hwg_EndDialog() } SIZE 69, 32

   oDlg:Activate()

   RETURN .T.

STATIC FUNCTION PrintDosPrint( oText, oPrt )
   LOCAL i
   LOCAL nText := FCreate( oPrt )
   FOR i := 1 TO Len( oText )
      FWrite( nText, oText[ i ] )
   NEXT
   FClose( nText )
   RETURN Nil


STATIC FUNCTION PrintDosAnt( nPage, oText )
   LOCAL oDlg := hwg_GetModalHandle()
   nPage := -- nPage
   IF nPage < 1 ; nPage := 1 ; ENDIF
   IF nPage = 1  //Added by  Por Fernando Exclui 1 byte do oText nao sei de onde ele aparece
      hwg_Setdlgitemtext( oDlg, 1001, SUBS( oText[ nPage ], 2 ) )  //Added by  Por Fernando Exclui 1 byte do oText nao sei de onde ele aparece
   ELSE
      hwg_Setdlgitemtext( oDlg, 1001, oText[ nPage ] )
   ENDIF
   RETURN nPage

STATIC FUNCTION PrintDosNext( oPage, nPage, oText )
   LOCAL oDlg := hwg_GetModalHandle()
   nPage := ++ nPage
   IF nPage > oPage ; nPage := oPage ; ENDIF
   hwg_Setdlgitemtext( oDlg, 1001, oText[ nPage ] )
   RETURN nPage

FUNCTION hwg_regenfile( o, new )

   LOCAL aText := AFillText( o )
   LOCAL stroka
   LOCAL o1 := printdos():new( new )
   LOCAL nLine := 0
   LOCAL nChr12 := 0
   LOCAL i

   FOR i := 1 TO Len( aText )

      stroka := aText[ i ]
      nChr12 := At( Chr( 12 ), stroka )

      IF nChr12 > 0
         stroka := SubStr( stroka, 1, nChr12 - 1 )
      ENDIF
      o1:say( nLine, 0, stroka )
      nLine ++

      IF nChr12 > 0
         o1:eject()
         nLine := 0
      ENDIF

   NEXT

   RETURN Nil


#PRAGMA BEGINDUMP
/*
   txtfile.c
   AFILLTEXT( cFile ) -> aArray
   NTXTLINE( cFile )  -> nLines
*/

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbstack.h"
#ifdef __XHARBOUR__
#include "hbfast.h"
#endif

#undef LINE_MAX
// #define LINE_MAX 4096
// #define LINE_MAX 8192
// #define LINE_MAX 16384
#define LINE_MAX    0x20000
//----------------------------------------------------------------------------//
static int file_read ( FILE *stream, char *string )
{
   int ch, cnbr = 0;

   memset (string, ' ', LINE_MAX);

   for (;;)
   {
      ch = fgetc (stream);

      if ( (ch == '\n') ||  (ch == EOF) ||  (ch == 26) )
      {
         string [cnbr] = '\0';
         return (ch == '\n' || cnbr);
      }
      else
      {
         if ( cnbr < LINE_MAX && ch != '\r' )
         {
            string [cnbr++] = (char) ch;
         }
      }

      if (cnbr >= LINE_MAX)
      {
         string [LINE_MAX] = '\0';
         return (1);
      }
   }
}

//----------------------------------------------------------------------------//
HB_FUNC( AFILLTEXT )
{
   FILE *inFile ;
   const char *pSrc = hb_parc(1) ;
   PHB_ITEM pArray = hb_itemNew(NULL);
   PHB_ITEM pTemp = hb_itemNew(NULL);
   char *string ;

   if ( !pSrc )
   {
      hb_reta( 0 );
      return;
   }

   if ( strlen( pSrc ) == 0 )
   {
      hb_reta( 0 );
      return;
   }
   inFile = fopen( pSrc, "r" );

   if ( !inFile )
   {
      hb_reta( 0 );
      return;
   }

   string = (char*) hb_xgrab( LINE_MAX + 1 );
   hb_arrayNew( pArray, 0 );

   while ( file_read ( inFile, string ) )
   {
      hb_arrayAddForward( pArray, hb_itemPutC( pTemp, string ));
   }

   hb_itemRelease( hb_itemReturn( pArray ) );
   hb_itemRelease( pTemp );
   hb_xfree( string );
   fclose( inFile );
}

#include <windows.h>

HB_FUNC( HWG_WIN_ANSITOOEM )
{
   PHB_ITEM pString = hb_param( 1, HB_IT_STRING );

   if( pString )
   {
      int nLen = ( int ) hb_itemGetCLen( pString );
      const char * pszSrc = hb_itemGetCPtr( pString );

      int nWideLen = MultiByteToWideChar( CP_ACP, MB_PRECOMPOSED, pszSrc, nLen, NULL, 0 );
      LPWSTR pszWide = ( LPWSTR ) hb_xgrab( ( nWideLen + 1 ) * sizeof( wchar_t ) );

      char * pszDst;

      MultiByteToWideChar( CP_ACP, MB_PRECOMPOSED, pszSrc, nLen, pszWide, nWideLen );

      nLen = WideCharToMultiByte( CP_OEMCP, 0, pszWide, nWideLen, NULL, 0, NULL, NULL );
      pszDst = ( char * ) hb_xgrab( nLen + 1 );

      WideCharToMultiByte( CP_OEMCP, 0, pszWide, nWideLen, pszDst, nLen, NULL, NULL );

      hb_xfree( pszWide );
      hb_retclen_buffer( pszDst, nLen );
   }
   else
      hb_retc_null();
}

#PRAGMA ENDDUMP

