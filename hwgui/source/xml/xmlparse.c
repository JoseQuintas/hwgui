/*
 * $Id: xmlparse.c,v 1.1 2004-03-18 11:19:12 alkresin Exp $
 *
 * Harbour XML Library
 * C level XML parse functions
 *
 * Copyright 2003 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include <stdio.h>
#include "hbapi.h"
#include "hbvm.h"
#include "hbstack.h"
#include "filesys.api"

#define HB_SKIPTABSPACES( sptr ) while( *sptr == ' ' || *sptr == '\t' || \
         *sptr == '\r' || *sptr == '\n' ) ( sptr )++
#define HB_SKIPCHARS( sptr ) while( *sptr && *sptr != ' ' && *sptr != '\t' && \
         *sptr != '=' && *sptr != '>' && *sptr != '<' && *sptr != '\"' \
         && *sptr != '\'' && *sptr != '\r' && *sptr != '\n' ) ( sptr )++

#define HBXML_ERROR_NOT_LT        1
#define HBXML_ERROR_NOT_GT        2
#define HBXML_ERROR_WRONG_TAG_END 3
#define HBXML_ERROR_WRONG_END     4
#define HBXML_ERROR_WRONG_ENTITY  5
#define HBXML_ERROR_NOT_QUOTE     6
#define HBXML_ERROR_TERMINATION   7

#define HBXML_TYPE_TAG            0
#define HBXML_TYPE_SINGLE         1
#define HBXML_TYPE_COMMENT        2
#define HBXML_TYPE_CDATA          3
#define HBXML_TYPE_PI             4

static unsigned char * cBuffer;
static int nParseError;
static ULONG  ulOffset;

static unsigned char * predefinedEntity1[] = { "lt;","gt;","amp;","quot;","apos;" };
static unsigned char * predefinedEntity2 = "<>&\"\'";


void hbxml_error( int nError, unsigned char *ptr )
{
   nParseError = nError;
   ulOffset = ptr - cBuffer;
}

HB_FUNC( HBXML_TRANSFORM )
{
   PHB_ITEM pItem;
   unsigned char * pBuffer = ( unsigned char * ) hb_parc(1), * pNew;
   unsigned char * ptr, * ptr1, * ptrs, c;
   ULONG ulLen = hb_parclen(1);
   int iLenAdd = 0, iLen;

   ptr = pBuffer;
   while( c = *ptr )
   {
      for( ptrs=predefinedEntity2; *ptrs; ptrs++ )
         if( *ptrs == c )
         {
            iLenAdd += strlen( predefinedEntity1[ptrs-predefinedEntity2] );
            break;
         }
      ptr++;
   }
   if( iLenAdd )
   {
      pNew = ( unsigned char * ) hb_xgrab( ulLen+iLenAdd+1 );
      ptr = pBuffer;
      ptr1 = pNew;
      while( c = *ptr )
      {
         *ptr1 = *ptr;
         for( ptrs=predefinedEntity2; *ptrs; ptrs++ )
            if( *ptrs == c )
            {
               iLen = strlen( predefinedEntity1[ptrs-predefinedEntity2] );
               *ptr1++ = '&';
               memcpy( ptr1, predefinedEntity1[ptrs-predefinedEntity2], iLen );
               ptr1 += iLen-1;
               break;
            }
         ptr++; ptr1++;
      }
      *ptr1 = '\0';
      pItem = hb_itemPutCPtr( NULL, pNew, ulLen+iLenAdd );
   }
   else
      pItem = hb_itemPutCL( NULL, pBuffer, ulLen );
   hb_itemRelease( hb_itemReturn( pItem ) );
}

/*
 * hbxml_pp( unsigned char * ptr, ULONG ulLen )
 * Translation of the predefined entities ( &lt;, etc. )
 */
PHB_ITEM hbxml_pp( unsigned char * ptr, ULONG ulLen )
{
   unsigned char * ptrStart = ptr;
   unsigned char * predefinedEntity1[] = { "lt;","gt;","amp;","quot;","apos;" };
   unsigned char * predefinedEntity2 = "<>&\"\'";
   int i, nlen;
   ULONG ul = 0, ul1;

   while( ul < ulLen )
   {
      if( *ptr == '&' )
      {
         for( i=0; i<5; i++ )
         {
            nlen = strlen( predefinedEntity1[i] );
            if( !memcmp( ptr+1, predefinedEntity1[i], nlen ) )
            {
               *ptr = predefinedEntity2[i];
               ulLen -= nlen;
               for( ul1=ul+1; ul1<ulLen; ul1++ )
                  *( ptrStart+ul1 ) = *( ptrStart+ul1+nlen );
               break;
            }
         }
         if( i == 5 )
            hbxml_error( HBXML_ERROR_WRONG_ENTITY, ptr );
      }
      ptr ++;
      ul ++;
   }
   return hb_itemPutCL( NULL, ptrStart, ulLen );
}

PHB_ITEM hbxml_getattr( unsigned char ** pBuffer, BOOL * lSingle )
{

   unsigned char * ptr, cQuo;
   int    nlen;
   PHB_ITEM pArray = hb_itemNew( NULL );
   PHB_ITEM pSubArray, pTemp;
   BOOL bPI = 0;

   hb_arrayNew( pArray, 0 );
   *lSingle = FALSE;
   if( **pBuffer == '<' )
   {
      (*pBuffer) ++;
      if( **pBuffer == '?' )
         bPI = 1;
      HB_SKIPTABSPACES( *pBuffer );        // go till tag name
      HB_SKIPCHARS( *pBuffer );            // skip tag name
      if( *(*pBuffer-1) == '/' || *(*pBuffer-1) == '?' )
         (*pBuffer) --;
      else
         HB_SKIPTABSPACES( *pBuffer );

      while( **pBuffer && **pBuffer != '>' )
      {
         if( !(**pBuffer) )
         {
            hbxml_error( HBXML_ERROR_TERMINATION, *pBuffer );
            break;
         }
         if( **pBuffer == '/' || **pBuffer == '?' )
         {
            *lSingle = (**pBuffer=='/')? 1 : 2;
            (*pBuffer) ++;
            if( **pBuffer != '>' || (*lSingle==2 && !bPI) )
            {
               hbxml_error( HBXML_ERROR_NOT_GT, *pBuffer );
            }
            break;
         }
         ptr = *pBuffer;
         HB_SKIPCHARS( *pBuffer );         // skip attribute name
         nlen = *pBuffer - ptr;
         // add attribute name to result array
         pSubArray = hb_itemNew( NULL );
         hb_arrayNew( pSubArray, 2 );
         pTemp = hb_itemPutCL( NULL, ptr, nlen );
         hb_arraySet( pSubArray, 1, pTemp );
         hb_itemRelease( pTemp );

         HB_SKIPTABSPACES( *pBuffer );    // go till '='
         if( **pBuffer == '=' )
         {
            (*pBuffer) ++;
            HB_SKIPTABSPACES( *pBuffer ); // go till attribute value
            cQuo = **pBuffer;
            if( cQuo == '\"' || cQuo == '\'' )
               (*pBuffer) ++;
            else
            {
               hbxml_error( HBXML_ERROR_NOT_QUOTE, *pBuffer );
               break;
            }
            ptr = *pBuffer;
            while( **pBuffer && **pBuffer != cQuo ) (*pBuffer) ++;
            if( **pBuffer != cQuo )
            {
               hbxml_error( HBXML_ERROR_NOT_QUOTE, *pBuffer );
               break;
            }
            nlen = *pBuffer - ptr;
            // add attribute value to result array
            pTemp = hbxml_pp( ptr, nlen );
            hb_arraySet( pSubArray, 2, pTemp );
            hb_itemRelease( pTemp );
            (*pBuffer) ++;
         }
         hb_arrayAdd( pArray, pSubArray );
         hb_itemRelease( pSubArray );
         HB_SKIPTABSPACES( *pBuffer );
      }
      if( nParseError )
      {
         hb_itemRelease( pSubArray );
         hb_itemRelease( pArray );
         return NULL;
      }
      if( **pBuffer == '>' )
         (*pBuffer) ++;
   }
   return pArray;
}

void hbxml_getdoctype( PHB_ITEM pDoc, unsigned char ** pBuffer )
{
   while( **pBuffer != '>' )
      (*pBuffer) ++;
   (*pBuffer) ++;
}

PHB_ITEM hbxml_addnode( PHB_ITEM pParent )
{
   PHB_ITEM pNode = hb_itemNew( NULL );
   PHB_DYNS pSym = hb_dynsymFindName( "HXMLNODE" );

   hb_vmPushSymbol( pSym->pSymbol );
   hb_vmPushNil();
   hb_vmDo( 0 );

   hb_objSendMsg( &(hb_stack.Return), "NEW", 0 );
   hb_itemCopy( pNode, &(hb_stack.Return) );

   hb_objSendMsg( pParent, "AITEMS", 0 );
   hb_arrayAdd( &(hb_stack.Return), pNode );

   return pNode;
}

BOOL hbxml_readComment( PHB_ITEM pParent, unsigned char ** pBuffer )
{
   unsigned char * ptr;
   PHB_ITEM pNode  = hbxml_addnode( pParent );
   PHB_ITEM pTemp;

   pTemp = hb_itemPutNI( NULL, HBXML_TYPE_COMMENT );
   hb_objSendMsg( pNode, "_TYPE", 1, pTemp );
   hb_itemRelease( pTemp );

   (*pBuffer) += 4;
   ptr = *pBuffer;
   while( **pBuffer && 
          ( **pBuffer != '-' || *(*pBuffer+1) != '-' || *(*pBuffer+2) != '>' ) )
      (*pBuffer) ++;

   if( **pBuffer )
   {
      pTemp = hb_itemPutCL( NULL, ptr, *pBuffer-ptr );
      hb_objSendMsg( pNode, "AITEMS", 0 );
      hb_arrayAdd( &(hb_stack.Return), pTemp );
      hb_itemRelease( pTemp );

      (*pBuffer) += 3;
   }
   else
      hbxml_error( HBXML_ERROR_TERMINATION, *pBuffer );

   hb_itemRelease( pNode );
   return ( nParseError )? FALSE : TRUE;
}

BOOL hbxml_readCDATA( PHB_ITEM pParent, unsigned char ** pBuffer )
{
   unsigned char * ptr;
   PHB_ITEM pNode  = hbxml_addnode( pParent );
   PHB_ITEM pTemp;

   pTemp = hb_itemPutNI( NULL, HBXML_TYPE_CDATA );
   hb_objSendMsg( pNode, "_TYPE", 1, pTemp );
   hb_itemRelease( pTemp );

   (*pBuffer) += 9;
   ptr = *pBuffer;
   while( **pBuffer && 
          ( **pBuffer != ']' || *(*pBuffer+1) != ']' || *(*pBuffer+2) != '>' ) )
      (*pBuffer) ++;

   if( **pBuffer )
   {
      pTemp = hb_itemPutCL( NULL, ptr, *pBuffer-ptr );
      hb_objSendMsg( pNode, "AITEMS", 0 );
      hb_arrayAdd( &(hb_stack.Return), pTemp );
      hb_itemRelease( pTemp );

      (*pBuffer) += 3;
   }
   else
      hbxml_error( HBXML_ERROR_TERMINATION, *pBuffer );

   hb_itemRelease( pNode );
   return ( nParseError )? FALSE : TRUE;
}

BOOL hbxml_readElement( PHB_ITEM pParent, unsigned char ** pBuffer )
{
   PHB_ITEM pNode  = hbxml_addnode( pParent );
   PHB_ITEM pArray;
   unsigned char * ptr, cNodeName[50];
   PHB_ITEM pTemp;
   int nLenNodeName;
   BOOL lEmpty;
   BOOL lSingle;

   (*pBuffer) ++;
   if( **pBuffer == '?' )
      (*pBuffer) ++;
   ptr = *pBuffer;
   HB_SKIPCHARS( ptr );
   nLenNodeName = ptr - *pBuffer - ( (*(ptr-1)=='/')? 1 : 0 );
   memcpy( cNodeName, *pBuffer, nLenNodeName );
   cNodeName[nLenNodeName] = '\0';

   pTemp = hb_itemPutC( NULL, cNodeName );
   hb_objSendMsg( pNode, "_TITLE", 1, pTemp );
   hb_itemRelease( pTemp );

   (*pBuffer) --;
   if( **pBuffer == '?' )
      (*pBuffer) --;
   if( ( pArray = hbxml_getattr( pBuffer, &lSingle ) ) == NULL )
   {
      hb_itemRelease( pNode );
      return FALSE;
   }
   else
   {
      hb_objSendMsg( pNode, "_AATTR", 1, pArray );
      hb_itemRelease( pArray );
   }
   pTemp = hb_itemPutNI( NULL, ( lSingle )? ( ( lSingle==2 )? HBXML_TYPE_PI : HBXML_TYPE_SINGLE ) : HBXML_TYPE_TAG );
   hb_objSendMsg( pNode, "_TYPE", 1, pTemp );
   hb_itemRelease( pTemp );

   if( !lSingle )
   {
      while( TRUE )
      {
         ptr = *pBuffer;
         lEmpty = TRUE;
         while( **pBuffer != '<' )
         {
            if( lEmpty && ( **pBuffer != ' ' && **pBuffer != '\t' && 
                            **pBuffer != '\r' && **pBuffer != '\n' ) )
               lEmpty = FALSE;
            (*pBuffer) ++;
         }
         if( !lEmpty )
         {
            pTemp = hbxml_pp( ptr, *pBuffer-ptr );
            hb_objSendMsg( pNode, "AITEMS", 0 );
            hb_arrayAdd( &(hb_stack.Return), pTemp );
            hb_itemRelease( pTemp );
         }

         if( *(*pBuffer+1) == '/' )
         {
            if( memcmp( *pBuffer+2, cNodeName, nLenNodeName ) )
               hbxml_error( HBXML_ERROR_WRONG_TAG_END, *pBuffer );
            else
            {
               while( **pBuffer != '>' ) (*pBuffer) ++;
               (*pBuffer) ++;
               break;
            }
         }
         else
         {
            if( !memcmp( *pBuffer+1,"!--",3 ) )
            {
               if( !hbxml_readComment( pNode, pBuffer ) )
               {
                  hb_itemRelease( pNode );
                  return FALSE;
               }
            }
            else if( !memcmp( *pBuffer+1,"![CDATA[",8 ) )
            {
               if( !hbxml_readCDATA( pNode, pBuffer ) )
               {
                  hb_itemRelease( pNode );
                  return FALSE;
               }
            }
            else
            {
               if( !hbxml_readElement( pNode, pBuffer ) )
               {
                  hb_itemRelease( pNode );
                  return FALSE;
               }
            }
         }
      }
   }
   hb_itemRelease( pNode );
   return TRUE;

}

/*
 * hbxml_Getdoc( PHB_ITEM pDoc, char * cData || FHANDLE handle )
 */

HB_FUNC( HBXML_GETDOC )
{
   PHB_ITEM pDoc = hb_param( 1, HB_IT_OBJECT );
   BOOL bFile;
   unsigned char * ptr;
   int iMainTags = 0;

   if( ISCHAR(2) )
   {
      cBuffer = (unsigned char * ) hb_parc(2);
      bFile = FALSE;
   }
   else if( ISNUM(2) )
   {
      FHANDLE hInput = (FHANDLE) hb_parni(2);
      ULONG ulLen = hb_fsSeek( hInput, 0, FS_END ), ulRead;

      hb_fsSeek( hInput, 0, FS_SET );
      cBuffer = (unsigned char*) hb_xgrab( ulLen + 1 );
      ulRead = hb_fsRead( hInput, (BYTE *) cBuffer, ulLen );
      cBuffer[ulRead] = '\0';
      bFile = TRUE;
   }
   else
      return;

   nParseError = 0;
   ptr = cBuffer;
   HB_SKIPTABSPACES( ptr );
   if( *ptr != '<' )
      hbxml_error( HBXML_ERROR_NOT_LT, ptr );
   else
   {
      if( !memcmp( ptr+1, "?xml", 4 ) )
      {
         BOOL lSingle;
         PHB_ITEM pArray = hbxml_getattr( &ptr,&lSingle );
         hb_objSendMsg( pDoc, "_AATTR", 1, pArray );
         hb_itemRelease( pArray );
         HB_SKIPTABSPACES( ptr );
      }
      if( !memcmp( ptr+1, "!DOCTYPE", 8 ) )
      {
         hbxml_getdoctype( pDoc, &ptr );
         HB_SKIPTABSPACES( ptr );
      }
      while( TRUE )
      {
         if( !memcmp( ptr+1,"!--",3 ) )
         {
            if( !hbxml_readComment( pDoc, &ptr ) )
               break;
         }
         else
         {
            if( iMainTags )
               hbxml_error( HBXML_ERROR_WRONG_END, ptr );
            if( !hbxml_readElement( pDoc, &ptr ) )
               break;
            iMainTags ++;
         }
         HB_SKIPTABSPACES( ptr );
         if( !*ptr )
            break;
      }
   }

   if( bFile )
      hb_xfree( cBuffer );

   if( nParseError )
      hb_retni( nParseError );
   else
      hb_retni( 0 );
}
