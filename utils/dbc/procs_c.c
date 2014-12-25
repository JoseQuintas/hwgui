/*
 * $Id$
 * Set of functions
 *
 * Copyright 2013 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hbapi.h"
#include "hbapiitm.h"

#ifdef __XHARBOUR__
   #xtranslate hb_isByRef([<n>])        => isByRef(<n>)
#endif

HB_FUNC( CARR_INIT )
{
   HB_LONG * pulin = (HB_LONG*) hb_parc(1);
   HB_ULONG  ulLen = hb_parnl(2);
   HB_LONG * pul;

   if( pulin && ulLen * sizeof(HB_LONG) <= hb_parclen(1) )
   {
      *pulin = 0;
   }
   else
   {
      pul = (HB_LONG *) hb_xgrab( ulLen * sizeof(HB_LONG) + 1 );
      *pul = 0;
      if( HB_ISBYREF(1) )
         hb_storclen_buffer( (char*) pul, ulLen * sizeof(HB_LONG), 1 );
      else
         hb_retclen_buffer( (char*) pul, ulLen * sizeof(HB_LONG) );
   }
}

HB_FUNC( CARR_PUT )
{
   HB_ULONG ulLen = hb_parclen(1) / sizeof(HB_LONG);
   HB_ULONG * pul = (HB_ULONG*) hb_parc(1);
   HB_ULONG ulItem = hb_parnl(3);

   if( ulItem == 0 )
      ulItem = *pul;

   if( *pul < ulItem )
      *pul = ulItem;
   if( ulItem < ulLen )
      *( pul + ulItem ) = hb_parnl(2);
   else if( ulItem == ulLen && HB_ISBYREF(1) )
   {
      HB_ULONG * pul1 = (HB_ULONG*) hb_xgrab( ulLen * sizeof(HB_LONG) * 2 + 1 );
      memcpy( pul1, pul, ulLen * sizeof(HB_LONG) );
      // hb_xfree( pul );
      // memset( pul1 + ulLen * sizeof(HB_LONG), 0, ulLen * sizeof(HB_LONG) + 1 );
      *( pul1 + ulItem ) = hb_parnl(2);
      hb_storclen_buffer( (char*) pul1, ulLen * sizeof(HB_LONG) * 2, 1 );
   }
}

HB_FUNC( CARR_DEL )
{
   HB_ULONG ulLen = hb_parclen(1) / sizeof(HB_LONG);
   HB_LONG * pul = (HB_LONG*) hb_parc(1);
   HB_ULONG ulItem = hb_parnl(2) + 1;

   for( ; ulItem < ulLen; ulItem++ )
      *( pul + ulItem - 1 ) = *( pul + ulItem );

   (*pul) --;
}

HB_FUNC( CARR_GET )
{
   HB_ULONG ulLen = hb_parclen(1) / sizeof(HB_LONG);
   HB_LONG * pul = (HB_LONG*) hb_parc(1);
   HB_ULONG ulItem = hb_parnl(2);

   if( ulItem > 0 && ulItem < ulLen )
      hb_retnl( *( pul + ulItem ) );
   else
      hb_retnl( 0 );
}

HB_FUNC( CARR_COUNT )
{
   HB_LONG * pul = (HB_LONG*) hb_parc(1);

   hb_retnl( *pul );
}

/*
 * "clong" is a set of functions for working with a bit array, represented in
 * a form of a character variable
 */
HB_FUNC( CLONG_TEST )
{
   unsigned char * cptr = (unsigned char *) hb_parc( 1 );
   unsigned char c;
   unsigned int uiBit = (unsigned int) hb_parni( 2 ) - 1;

   if( uiBit > (unsigned int) (hb_parclen(1) * 8) )
      hb_retl( 0 );
   else
   {
      c = *( cptr+(uiBit/8) );
      hb_retl( ( c & ( 0x80 >> (uiBit%8) ) ) != 0 );
   }
}

HB_FUNC( CLONG_SET )
{
   unsigned char c;
   HB_ULONG ulLen = hb_parclen(1);
   unsigned char * cptr = ( unsigned char * ) hb_xgrab( ulLen+1 );
   unsigned int uiBit = (unsigned int) hb_parni( 2 ) - 1;

   memcpy( cptr, hb_parc(1), ulLen+1 );
   if( uiBit <= (unsigned int) (ulLen * 8) )
   {
      c = *( cptr+(uiBit/8) );
      c |= ( 0x80 >> (uiBit%8) );
      *( cptr+(uiBit/8) ) = c;
   }
   hb_retclen_buffer( (char*) cptr, ulLen );
}

HB_FUNC( CLONG_RESET )
{
   unsigned char c;
   HB_ULONG ulLen = hb_parclen(1);
   unsigned char * cptr = ( unsigned char * ) hb_xgrab( ulLen+1 );
   unsigned int uiBit = (unsigned int) hb_parni( 2 ) - 1;

   memcpy( cptr, hb_parc(1), ulLen+1 );
   if( uiBit <= (unsigned int) (ulLen * 8) )
   {
      c = *( cptr+(uiBit/8) );
      c &= ~( 0x80 >> (uiBit%8) );
      *( cptr+(uiBit/8) ) = c;
   }
   hb_retclen_buffer( (char*) cptr, ulLen );
}
