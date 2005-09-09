/*
 * $Id: arr2str.c,v 1.7 2005-09-09 06:30:20 lf_sfnet Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Array / String conversion functions
 *
 * Copyright 2003 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#ifdef __EXPORT__
   #define HB_NO_DEFAULT_API_MACROS
   #define HB_NO_DEFAULT_STACK_MACROS
#endif

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"


static char * ReadArray( char * ptr, PHB_ITEM pItem )
{
   int  iArLen, i;
   PHB_ITEM temp;

   ptr ++;
   iArLen = ( *ptr + ( ( *(ptr+1) ) << 8 ) ) & 0xffff;
   ptr ++; ptr ++;
   hb_arrayNew( pItem, iArLen );
   for( i=0; i<iArLen; i++ )
   {
      if( *ptr == '\6' )            // Array
      {
         temp = hb_itemNew( NULL );
         ptr = ReadArray( ptr, temp );
      }
      else if( *ptr == '\1' )       // Char
      {
         unsigned int iLen;
         ptr ++;
         // iLen = ( *ptr + ( ( *(ptr+1) ) << 8 ) ) & 0xffff;
         iLen = ( (unsigned int)*ptr & 0x00ff ) + 
            ( ( (unsigned int)( ( *(ptr+1) ) << 8 ) ) & 0xffff);
         ptr ++; ptr ++;
         temp = hb_itemPutCL( NULL, ptr, iLen );
         ptr += iLen;
      }
      else if( *ptr == '\2' )       // Int
      {
         long int lValue;
         ptr ++;
         lValue = *( (long int*)ptr );
         temp = hb_itemPutNL( NULL, lValue );
         ptr += 4;
      }
      else if( *ptr == '\3' )       // Numeric
      {
         int iLen, iDec;
         double dValue;
         ptr ++;
         iLen = (int) *ptr++;
         iDec = (int) *ptr++;
         dValue = *( (double*)ptr );
         temp = hb_itemPutNDLen( NULL,dValue,iLen,iDec );
         ptr += 8;
      }
      else if( *ptr == '\4' )       // Date
      {
         long int lValue;
         ptr ++;
         lValue = *( (long int*)ptr );
         temp = hb_itemPutDL( NULL, lValue );
         ptr += 4;
      }
      else if( *ptr == '\5' )       // Logical
      {
         ptr ++;
         temp = hb_itemPutL( NULL, (int) *ptr++ );
      }
      else if( *ptr == '\7' )       // Long Char
      {
         unsigned int iLen;
         ptr ++;
         iLen = ( (unsigned int)*ptr & 0x00ff ) + 
                ( ( (unsigned int)( ( *(ptr+1) ) << 8 ) ) & 0xff00 ) +
                ( ( (unsigned int)( ( *(ptr+2) ) << 16 ) ) & 0xff0000 ) +
                ( ( (unsigned int)( ( *(ptr+3) ) << 24 ) ) & 0xff000000 );
         ptr ++; ptr ++; ptr ++; ptr ++;
         temp = hb_itemPutCL( NULL, ptr, iLen );
         ptr += iLen;
      }
      else                            // Nil
      {
         ptr ++;
         temp = hb_itemNew( NULL );
      }

      hb_itemArrayPut( pItem, i+1, temp );
      hb_itemRelease( temp );
   }
   return ptr;

}

static long int ArrayMemoSize( PHB_ITEM pArray )
{
   long int lMemoSize = 3;
   unsigned int i, iLen;

   for( i=1; i<=pArray->item.asArray.value->ulLen; i++ )
   {
      switch( ( pArray->item.asArray.value->pItems + i - 1 )->type )
      {
         case HB_IT_STRING:
            iLen = ( pArray->item.asArray.value->pItems + i - 1 )->item.asString.length;
            lMemoSize += ( ( ( iLen > 0xffff ) )? 5:3 ) + iLen;
            break;

         case HB_IT_DATE:
            lMemoSize += 5;
            break;

         case HB_IT_LOGICAL:
            lMemoSize += 2;
            break;

         case HB_IT_ARRAY:
            lMemoSize += ArrayMemoSize( pArray->item.asArray.value->pItems + i - 1 );
            break;

         case HB_IT_INTEGER:
         case HB_IT_LONG:
            lMemoSize += 5;
            break;

         case HB_IT_DOUBLE:
            lMemoSize += 11;
            break;

         default:
            lMemoSize += 1;
            break;
      }
   }

   return lMemoSize;
}

static char * WriteArray( char * ptr, PHB_ITEM pArray )
{
   unsigned int i, iLen;

   *ptr++ = '\6';
   *( (short int*)ptr ) = pArray->item.asArray.value->ulLen;
   ptr++; ptr++;

   for( i=1; i<=pArray->item.asArray.value->ulLen; i++ )
   {
      switch( ( pArray->item.asArray.value->pItems + i - 1 )->type )
      {
         case HB_IT_STRING:
            iLen = ( pArray->item.asArray.value->pItems + i - 1 )->item.asString.length;
            if( iLen > 0xffff )
            {
               *ptr++ = '\7';
               *ptr = iLen & 0xff; ptr ++;
               *ptr = ( iLen & 0xff00 ) >> 8; ptr ++;
               *ptr = ( iLen & 0xff0000 ) >> 16; ptr ++;
               *ptr = ( iLen & 0xff000000 ) >> 24; ptr ++;
            }
            else
            {
               *ptr++ = '\1';
               *ptr = iLen & 0xff; ptr ++;
               *ptr = ( iLen & 0xff00 ) >> 8; ptr ++;
            }
            memcpy( ptr, ( pArray->item.asArray.value->pItems + i - 1 )->item.asString.value, iLen );
            ptr += iLen;
            break;

         case HB_IT_DATE:
            *ptr++ = '\4';
            *( (long int*)ptr ) = ( pArray->item.asArray.value->pItems + i - 1 )->item.asDate.value;
            ptr += 4;
            break;

         case HB_IT_LOGICAL:
            *ptr++ = '\5';
            *ptr++ = ( pArray->item.asArray.value->pItems + i - 1 )->item.asLogical.value;
            break;

         case HB_IT_ARRAY:
            ptr = WriteArray( ptr, pArray->item.asArray.value->pItems + i - 1 );
            break;

         case HB_IT_INTEGER:
         case HB_IT_LONG:
            *ptr++ = '\2';
            *( (long int*)ptr ) = hb_itemGetNL( pArray->item.asArray.value->pItems + i - 1 );
            ptr += 4;
            break;

         case HB_IT_DOUBLE:
            *ptr++ = '\3';
            *ptr++ = (char)( ( pArray->item.asArray.value->pItems + i - 1 )->item.asDouble.length );
            *ptr++ = (char)( ( pArray->item.asArray.value->pItems + i - 1 )->item.asDouble.decimal );
            *( (double*)ptr ) = hb_itemGetND( pArray->item.asArray.value->pItems + i - 1 );
            ptr += 8;
            break;

         default:
            *ptr++ = '\0';
      }
   }

   return ptr;
}

HB_FUNC( ARRAY2STRING )
{
   PHB_ITEM pArray    = hb_param( 1, HB_IT_ARRAY );
   long int lMemoSize = ArrayMemoSize( pArray );
   char * szResult    = (char*) hb_xgrab( lMemoSize + 10 );

   WriteArray( szResult, pArray );
   hb_retclen_buffer( szResult,lMemoSize );
}

HB_FUNC( STRING2ARRAY )
{
   char * szResult = hb_parc( 1 );
   PHB_ITEM pItem = hb_itemNew( NULL );

   if( hb_parclen(1) > 2 && *szResult == '\6' )
      ReadArray( szResult, pItem );

   // hb_itemReturn( pItem );
   // hb_itemRelease( pItem );
   hb_itemRelease( hb_itemReturn( pItem ) );
}
