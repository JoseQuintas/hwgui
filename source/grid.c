 /*
 * $Id: grid.c,v 1.11 2005-11-01 17:48:38 lf_sfnet Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HGrid class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
 * Copyright 2004 Rodrigo Moreno <rodrigo_moreno@yahoo.com>
 *
*/

#ifdef __EXPORT__
   #define HB_NO_DEFAULT_API_MACROS
   #define HB_NO_DEFAULT_STACK_MACROS
#endif

#define _WIN32_IE      0x0500
#define HB_OS_WIN_32_USED
#define _WIN32_WINNT   0x0400

#if defined(__POCC__) || defined(__XCC__)
#include <unknwn.h>
#endif

#include <shlobj.h>

#include <windows.h>
#include <commctrl.h>
#include "hbapi.h"
#include "hbapiitm.h"

HB_FUNC( LISTVIEW_CREATE )
{
        HWND hwnd;
        HWND handle;
        int style ;
        
        hwnd = (HWND) hb_parnl(1);

        style = hb_parni(7) ;

        if ( hb_parl(8) )
        {
                style = style | LVS_NOCOLUMNHEADER ;
        }

        if ( hb_parl(9) )
        {
                style = style | LVS_NOSCROLL ;
        }
        
        handle = CreateWindowEx(WS_EX_CLIENTEDGE, WC_LISTVIEW,"",
        style ,
        hb_parni(3), hb_parni(4) , hb_parni(5), hb_parni(6) ,
        hwnd,(HMENU)hb_parni(2) , GetModuleHandle(NULL) , NULL ) ;
        
        hb_retnl ( (LONG) handle );
}

HB_FUNC( LISTVIEW_INIT )
{
        int style ;
        
        style = 0;
        
        if ( ! hb_parl(3) )
        {
                style = style | LVS_EX_GRIDLINES ;
        }
        
        SendMessage( (HWND) hb_parnl(1), 
                      LVM_SETEXTENDEDLISTVIEWSTYLE, 0, 
                      LVS_EX_FULLROWSELECT | 
                      LVS_EX_HEADERDRAGDROP |
                      LVS_EX_FLATSB | style);
                      
        ListView_SetItemCount( (HWND) hb_parnl(1), hb_parnl(2) ) ;
}

HB_FUNC( LISTVIEW_SETITEMCOUNT )
{
        ListView_SetItemCount( (HWND) hb_parnl (1) , hb_parni (2) ) ;
}
    
HB_FUNC( LISTVIEW_ADDCOLUMN )
{
        LV_COLUMN COL;

        PHB_ITEM pValue = hb_itemNew( NULL );
        hb_itemCopy( pValue, hb_param( 4, HB_IT_STRING ));

        COL.mask= LVCF_WIDTH | LVCF_TEXT | LVCF_FMT | LVCF_SUBITEM ;
        COL.cx= hb_parni(3);
        COL.pszText = pValue->item.asString.value;
        COL.iSubItem=hb_parni(2)-1;
        COL.fmt = hb_parni(5) ;
        hb_itemRelease( pValue );

        ListView_InsertColumn( (HWND) hb_parnl( 1 ) , hb_parni(2)-1 , &COL );

        RedrawWindow( (HWND) hb_parnl( 1 ), NULL , NULL , RDW_ERASE | RDW_INVALIDATE | RDW_ALLCHILDREN | RDW_ERASENOW | RDW_UPDATENOW ) ;
}

HB_FUNC( LISTVIEW_DELETECOLUMN )
{
        ListView_DeleteColumn( (HWND) hb_parnl (1) , hb_parni(2)-1 ) ;
        RedrawWindow( (HWND) hb_parnl( 1 ), NULL , NULL , RDW_ERASE | RDW_INVALIDATE | RDW_ALLCHILDREN | RDW_ERASENOW | RDW_UPDATENOW ) ;
}

HB_FUNC( LISTVIEW_SETBKCOLOR )
{
        ListView_SetBkColor( (HWND) hb_parnl (1) , (COLORREF) hb_parni(2) ) ;
}

HB_FUNC( LISTVIEW_SETTEXTBKCOLOR )
{
        ListView_SetTextBkColor( (HWND) hb_parnl (1) , (COLORREF) hb_parni(2) ) ;
}

HB_FUNC( LISTVIEW_SETTEXTCOLOR )
{
	ListView_SetTextColor( (HWND) hb_parnl (1) , (COLORREF) hb_parni(2) ) ;
}


HB_FUNC( LISTVIEW_GETFIRSTITEM ) // Current Line
{
        hb_retni( ListView_GetNextItem( (HWND) hb_parnl( 1 )  , -1 ,LVNI_ALL | LVNI_SELECTED) + 1);
}

HB_FUNC( LISTVIEW_GETDISPINFO )
{
        LV_DISPINFO* pDispInfo = (LV_DISPINFO*)hb_parnl(1);

        int iItem = pDispInfo->item.iItem;
        int iSubItem = pDispInfo->item.iSubItem;

        hb_reta( 2 );
        hb_storni( iItem + 1 , -1, 1 ); 
        hb_storni( iSubItem + 1 , -1, 2 ); 
}

HB_FUNC( LISTVIEW_SETDISPINFO )
{
        PHB_ITEM pValue = hb_itemNew( NULL );
        LV_DISPINFO* pDispInfo = (LV_DISPINFO*)hb_parnl(1);
        hb_itemCopy( pValue, hb_param( 2, HB_IT_STRING ));
        pDispInfo->item.pszText = pValue->item.asString.value;
        hb_itemRelease( pValue );
        if (pDispInfo->item.iSubItem == 0)
                pDispInfo->item.state = 2;
        
}

HB_FUNC( LISTVIEW_GETGRIDKEY )
{
        #define pnm ((LV_KEYDOWN *) hb_parnl(1) ) 

        hb_retnl( (LPARAM) (pnm->wVKey) ) ;

        #undef pnm 
}

HB_FUNC( LISTVIEW_GETTOPINDEX )
{
        hb_retnl( ListView_GetTopIndex ( (HWND) hb_parnl(1) ) ) ;
}

HB_FUNC( LISTVIEW_REDRAWITEMS )
{
        hb_retnl( ListView_RedrawItems ( (HWND) hb_parnl(1) , hb_parni(2) , hb_parni(3) ) ) ;
}

HB_FUNC( LISTVIEW_GETCOUNTPERPAGE )
{
        hb_retnl( ListView_GetCountPerPage ( (HWND) hb_parnl (1) ) ) ;
}

HB_FUNC( LISTVIEW_UPDATE )
{
        ListView_Update( (HWND) hb_parnl (1) , hb_parni(2) - 1 );

}

HB_FUNC( LISTVIEW_SCROLL )
{
   ListView_Scroll( (HWND) hb_parnl (1), hb_parni(2) - 1, hb_parni(3) - 1 );
}

HB_FUNC( LISTVIEW_HITTEST )

{

   POINT point;
   LVHITTESTINFO lvhti;

   point.y = hb_parni(2) ;
   point.x = hb_parni(3) ;

   lvhti.pt = point;

   ListView_SubItemHitTest ( (HWND) hb_parnl (1) , &lvhti ) ;

   if(lvhti.flags & LVHT_ONITEM)
   {
      hb_reta( 2 );
      hb_storni( lvhti.iItem + 1 , -1, 1 );
      hb_storni( lvhti.iSubItem + 1 , -1, 2 );
   }
   else
   {
      hb_reta( 2 );
      hb_storni( 0 , -1, 1 );
      hb_storni( 0 , -1, 2 );
   }

}


HB_FUNC( GETWINDOWROW )

{

	RECT rect;

	int y ;

	GetWindowRect((HWND) hb_parnl (1), &rect) ;

	y = rect.top ;



	hb_retni(y);

}



HB_FUNC( GETWINDOWCOL )

{

	RECT rect;

	int x ;

	GetWindowRect((HWND) hb_parnl (1), &rect) ;

	x = rect.left ;



	hb_retni(x);

}



HB_FUNC( GETCURSORROW )

{

        POINT pt;

        GetCursorPos( &pt );

        hb_retni( pt.y );

}



HB_FUNC( GETCURSORCOL )

{

        POINT pt;

        GetCursorPos( &pt );

        hb_retni( pt.x );

}
