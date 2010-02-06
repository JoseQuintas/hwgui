/*
 * $Id: control.c,v 1.100 2010-02-06 02:06:43 druzus Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level controls functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#define HB_OS_WIN_32_USED

#define _WIN32_WINNT 0x0400
#define _WIN32_IE    0x0400
#define OEMRESOURCE
#include <windows.h>
#include <commctrl.h>
#include <winuser.h>
#if defined(__DMC__)
#include "missing.h"
#endif

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbdate.h"
#include "hbtrace.h"
#include "hwingui.h"
#ifdef __XHARBOUR__
   #include "hbfast.h"
#endif

#if defined(__BORLANDC__) || (defined(_MSC_VER) && !defined(__XCC__) || defined(__WATCOMC__) || defined(__DMC__) )
HB_EXTERN_BEGIN
WINUSERAPI HWND WINAPI GetAncestor( HWND hwnd, UINT gaFlags );
HB_EXTERN_END
#endif

#ifndef TTS_BALLOON
   #define TTS_BALLOON             0x40    // added by MAG
#endif
#ifndef CCM_SETVERSION
   #define CCM_SETVERSION (CCM_FIRST + 0x7)
#endif
#ifndef CCM_GETVERSION
   #define CCM_GETVERSION (CCM_FIRST + 0x8)
#endif
#ifndef TB_GETIMAGELIST
   #define TB_GETIMAGELIST         (WM_USER + 49)
#endif

// LRESULT CALLBACK OwnBtnProc (HWND, UINT, WPARAM, LPARAM) ;
LRESULT CALLBACK WinCtrlProc( HWND, UINT, WPARAM, LPARAM );
LRESULT APIENTRY SplitterProc( HWND hwnd, UINT uMsg, WPARAM wParam,
      LPARAM lParam );
LRESULT APIENTRY StaticSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam,
      LPARAM lParam );
LRESULT APIENTRY EditSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam,
      LPARAM lParam );
LRESULT APIENTRY ButtonSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam,
      LPARAM lParam );
LRESULT APIENTRY ComboSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam,
      LPARAM lParam );
LRESULT APIENTRY ListSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam,
      LPARAM lParam );
LRESULT APIENTRY UpDownSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam,
      LPARAM lParam );
LRESULT APIENTRY DatePickerSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam,
      LPARAM lParam );
LRESULT APIENTRY TrackSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam,
      LPARAM lParam );
LRESULT APIENTRY TabSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam,
      LPARAM lParam );
static void CALLBACK s_timerProc( HWND, UINT, UINT, DWORD );

static HWND hWndTT = 0;
static BOOL lInitCmnCtrl = 0;
static BOOL lToolTipBalloon = FALSE;    // added by MAG
static WNDPROC wpOrigEditProc, wpOrigTrackProc, wpOrigTabProc, wpOrigComboProc, wpOrigStaticProc, wpOrigListProc, wpOrigUpDownProc, wpOrigDatePickerProc;       //wpOrigButtonProc
static LONG_PTR wpOrigButtonProc;

HB_FUNC( HWG_INITCOMMONCONTROLSEX )
{
   if( !lInitCmnCtrl )
   {
      INITCOMMONCONTROLSEX i;

      i.dwSize = sizeof( INITCOMMONCONTROLSEX );
      i.dwICC =
            ICC_DATE_CLASSES | ICC_INTERNET_CLASSES | ICC_BAR_CLASSES |
            ICC_LISTVIEW_CLASSES | ICC_TAB_CLASSES | ICC_TREEVIEW_CLASSES;
      InitCommonControlsEx( &i );
      lInitCmnCtrl = 1;
   }
}

HB_FUNC( MOVEWINDOW )
{
   RECT rc;

   GetWindowRect( ( HWND ) HB_PARHANDLE( 1 ), &rc );
   MoveWindow( ( HWND ) HB_PARHANDLE( 1 ),      // handle of window
         ( ISNIL( 2 ) ) ? rc.left : hb_parni( 2 ),      // horizontal position
         ( ISNIL( 3 ) ) ? rc.top : hb_parni( 3 ),       // vertical position
         ( ISNIL( 4 ) ) ? rc.right - rc.left : hb_parni( 4 ),   // width
         ( ISNIL( 5 ) ) ? rc.bottom - rc.top : hb_parni( 5 ),   // height
         ( hb_pcount(  ) < 6 ) ? TRUE : hb_parl( 6 )    // repaint flag
          );
}

/*
   CreateProgressBar( hParentWindow, nRange )
*/
HB_FUNC( CREATEPROGRESSBAR )
{
   HWND hPBar, hParentWindow = ( HWND ) HB_PARHANDLE( 1 );
   RECT rcClient;
   int cyVScroll = GetSystemMetrics( SM_CYVSCROLL );
   int x1, y1, nwidth, nheight;

   if( hb_pcount(  ) > 2 )
   {
      x1 = hb_parni( 3 );
      y1 = hb_parni( 4 );
      nwidth = hb_parni( 5 );
      nheight = cyVScroll;
   }
   else
   {
      GetClientRect( hParentWindow, &rcClient );
      x1 = rcClient.left;
      y1 = rcClient.bottom - cyVScroll;
      nwidth = rcClient.right;
      nheight = cyVScroll;
   }

   hPBar = CreateWindowEx( 0, PROGRESS_CLASS, NULL, WS_CHILD | WS_VISIBLE,    /* style  */
         x1,                    /* x */
         y1,                    /* y */
         nwidth, nheight,       /* nWidth, nHeight */
         hParentWindow,         /* parent window    */
         ( HMENU ) NULL, GetModuleHandle( NULL ), NULL );

   SendMessage( hPBar, PBM_SETRANGE, 0, MAKELPARAM( 0, hb_parni( 2 ) ) );
   SendMessage( hPBar, PBM_SETSTEP, ( WPARAM ) 1, 0 );

   HB_RETHANDLE( hPBar );
}

/*
   UpdateProgressBar( hPBar )
*/
HB_FUNC( UPDATEPROGRESSBAR )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), PBM_STEPIT, 0, 0 );
}

HB_FUNC( SETPROGRESSBAR )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), PBM_SETPOS,
         ( WPARAM ) hb_parni( 2 ), 0 );
}

/*
   CreatePanel( hParentWindow, nPanelControlID, nStyle, x1, y1, nWidth, nHeight )
*/
HB_FUNC( CREATEPANEL )
{
   HWND hWndPanel;
   hWndPanel = CreateWindow( TEXT( "PANEL" ),   /* predefined class  */
         NULL,                  /* no window title   */
         WS_CHILD | WS_VISIBLE | SS_GRAYRECT | SS_OWNERDRAW | CCS_TOP | hb_parnl( 3 ),  /* style  */
         hb_parni( 4 ), hb_parni( 5 ),  /* x, y       */
         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
         ( HMENU ) hb_parni( 2 ),       /* control ID  */
         GetModuleHandle( NULL ), NULL );

   HB_RETHANDLE( hWndPanel );
   // SS_ETCHEDHORZ
}

/*
   CreateOwnBtn( hParentWIndow, nBtnControlID, x, y, nWidth, nHeight )
*/
HB_FUNC( CREATEOWNBTN )
{
   HWND hWndPanel;
   hWndPanel = CreateWindow( TEXT( "OWNBTN" ),  /* predefined class  */
         NULL,                  /* no window title   */
         WS_CHILD | WS_VISIBLE | SS_GRAYRECT | SS_OWNERDRAW,    /* style  */
         hb_parni( 3 ), hb_parni( 4 ),  /* x, y       */
         hb_parni( 5 ), hb_parni( 6 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
         ( HMENU ) hb_parni( 2 ),       /* control ID  */
         GetModuleHandle( NULL ), NULL );

   HB_RETHANDLE( hWndPanel );
}

/*
   CreateStatic( hParentWyndow, nControlID, nStyle, x, y, nWidth, nHeight )
*/
HB_FUNC( CREATESTATIC )
{
   ULONG ulStyle = hb_parnl( 3 );
   ULONG ulExStyle =
         ( ( !ISNIL( 8 ) ) ? hb_parnl( 8 ) : 0 ) | ( ( ulStyle & WS_BORDER ) ?
         WS_EX_CLIENTEDGE : 0 );
   HWND hWndCtrl = CreateWindowEx( ulExStyle,   /* extended style */
         TEXT( "STATIC" ),      /* predefined class  */
         NULL,                  /* title   */
         WS_CHILD | WS_VISIBLE | ulStyle,       /* style  */
         hb_parni( 4 ), hb_parni( 5 ),  /* x, y       */
         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
         ( HMENU ) hb_parni( 2 ),       /* control ID  */
         GetModuleHandle( NULL ),
         NULL );

   /*
      if( hb_pcount() > 7 )
      {
         void * hStr;
         LPCTSTR lpText = HB_PARSTR( 8, &hStr, NULL );
         if( lpText )
            SendMessage( hWndEdit, WM_SETTEXT, 0, ( LPARAM ) lpText );
         hb_strfree( hStr );
      }
    */



   HB_RETHANDLE( hWndCtrl );

}

/*
   CreateButton( hParentWIndow, nButtonID, nStyle, x, y, nWidth, nHeight,
                 cCaption )
*/
HB_FUNC( CREATEBUTTON )
{
   void * hStr;
   HWND hBtn = CreateWindow( TEXT( "BUTTON" ),  /* predefined class  */
         HB_PARSTR( 8, &hStr, NULL ),           /* button text   */
         WS_CHILD | WS_VISIBLE | hb_parnl( 3 ), /* style  */
         hb_parni( 4 ), hb_parni( 5 ),  /* x, y       */
         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
         ( HMENU ) hb_parni( 2 ),       /* button       ID  */
         GetModuleHandle( NULL ),
         NULL );
   hb_strfree( hStr );

   HB_RETHANDLE( hBtn );

}

/*
   CreateEdit( hParentWIndow, nEditControlID, nStyle, x, y, nWidth, nHeight,
               cInitialString )
*/
HB_FUNC( CREATEEDIT )
{
   ULONG ulStyle = hb_parnl( 3 );
   ULONG ulStyleEx = ( ulStyle & WS_BORDER ) ? WS_EX_CLIENTEDGE : 0;
   HWND hWndEdit;

   if( ( ulStyle & WS_BORDER ) )        //&& ( ulStyle & WS_DLGFRAME ) )
      ulStyle &= ~WS_BORDER;
   hWndEdit = CreateWindowEx( ulStyleEx,
         TEXT( "EDIT" ),
         NULL,
         WS_CHILD | WS_VISIBLE | ulStyle,
         hb_parni( 4 ), hb_parni( 5 ),
         hb_parni( 6 ), hb_parni( 7 ),
         ( HWND ) HB_PARHANDLE( 1 ),
         ( HMENU ) hb_parni( 2 ), GetModuleHandle( NULL ), NULL );

   if( hb_pcount() > 7 )
   {
      void * hStr;
      LPCTSTR lpText = HB_PARSTR( 8, &hStr, NULL );
      if( lpText )
         SendMessage( hWndEdit, WM_SETTEXT, 0, ( LPARAM ) lpText );
      hb_strfree( hStr );
   }

   HB_RETHANDLE( hWndEdit );

}

/*
   CreateCombo( hParentWIndow, nComboID, nStyle, x, y, nWidth, nHeight,
                cInitialString )
*/
HB_FUNC( CREATECOMBO )
{
   HWND hCombo = CreateWindow( TEXT( "COMBOBOX" ),    /* predefined class  */
         TEXT( "" ),                    /*   */
         WS_CHILD | WS_VISIBLE | hb_parnl( 3 ), /* style  */
         hb_parni( 4 ), hb_parni( 5 ),  /* x, y       */
         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
         ( HMENU ) hb_parni( 2 ),       /* combobox ID      */
         GetModuleHandle( NULL ),
         NULL );

   HB_RETHANDLE( hCombo );

}


/*
   CreateBrowse( hParentWIndow, nControlID, nStyle, x, y, nWidth, nHeight,
               cTitle )
*/
HB_FUNC( CREATEBROWSE )
{
   HWND hWndBrw;
   DWORD dwStyle = hb_parnl( 3 );
   void * hStr;

   hWndBrw = CreateWindowEx( ( dwStyle & WS_BORDER ) ? WS_EX_CLIENTEDGE : 0,    /* extended style */
         TEXT( "BROWSE" ),              /* predefined class */
         HB_PARSTR( 8, &hStr, NULL ),           /* button text   */
         WS_CHILD | WS_VISIBLE | dwStyle,       /* style */
         hb_parni( 4 ), hb_parni( 5 ),  /* x, y  */
         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window */
         ( HMENU ) hb_parni( 2 ),       /* control ID  */
         GetModuleHandle( NULL ), NULL );
   hb_strfree( hStr );

   HB_RETHANDLE( hWndBrw );

}

/* CreateStatusWindow - creates a status window and divides it into
     the specified number of parts.
 Returns the handle to the status window.
 hwndParent - parent window for the status window
 nStatusID - child window identifier
 nParts - number of parts into which to divide the status window
 pArray - Array with Lengths of parts, if first item == 0, status window
          will be divided into equal parts.
*/
HB_FUNC( CREATESTATUSWINDOW )
{
   HWND hwndStatus, hwndParent = ( HWND ) HB_PARHANDLE( 1 );

   // Ensure that the common control DLL is loaded.
   InitCommonControls(  );

   // Create the status window.
   hwndStatus = CreateWindowEx( 0,      // style
         STATUSCLASSNAME,       // name of status window class
         NULL,                  // no text when first created
         SBARS_SIZEGRIP |       // includes a sizing grip
         WS_CHILD | WS_VISIBLE | WS_OVERLAPPED | WS_CLIPSIBLINGS,       // creates a child window
         0, 0, 0, 0,            // ignores size and position
         hwndParent,            // handle to parent window
         ( HMENU ) hb_parni( 2 ),       // child window identifier
         GetModuleHandle( NULL ),       // handle to application instance
         NULL );                // no window creation data

   HB_RETHANDLE( hwndStatus );
}

HB_FUNC( HWG_INITSTATUS )
{
   HWND hParent = ( HWND ) HB_PARHANDLE( 1 );
   HWND hStatus = ( HWND ) HB_PARHANDLE( 2 );
   RECT rcClient;
   HLOCAL hloc;
   LPINT lpParts;
   int i, nWidth, j, nParts = hb_parni( 3 );
   PHB_ITEM pArray = hb_param( 4, HB_IT_ARRAY );

   // Allocate an array for holding the right edge coordinates.
   hloc = LocalAlloc( LHND, sizeof( int ) * nParts );
   lpParts = ( LPINT ) LocalLock( hloc );

   if( !pArray || hb_arrayGetNI( pArray, 1 ) == 0 )
   {
      // Get the coordinates of the parent window's client area.
      GetClientRect( hParent, &rcClient );
      // Calculate the right edge coordinate for each part, and
      // copy the coordinates to the array.
      nWidth = rcClient.right / nParts;
      for( i = 0; i < nParts; i++ )
      {
         lpParts[i] = nWidth;
         nWidth += nWidth;
      }
   }
   else
   {
      ULONG ul;
      nWidth = 0;
      for( ul = 1; ul <= ( ULONG ) nParts; ul++ )
      {
         j = hb_arrayGetNI( pArray, ul );
         if( ul == ( ULONG ) nParts && j == 0 )
            nWidth = -1;
         else
            nWidth += j;
         lpParts[ul - 1] = nWidth;
      }
   }

   // Tell the status window to create the window parts.
   SendMessage( hStatus, SB_SETPARTS, ( WPARAM ) nParts, ( LPARAM ) lpParts );

   // Free the array, and return.
   LocalUnlock( hloc );
   LocalFree( hloc );
}

HB_FUNC( GETNOTIFYSBPARTS )
{
   hb_retnl( ( LONG ) ((( NMMOUSE * ) HB_PARHANDLE( 1 ))->dwItemSpec ) );
}

HB_FUNC( ADDTOOLTIP )           // changed by MAG
{
   TOOLINFO ti;
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   int iStyle = TTS_ALWAYSTIP;
   void * hStr;

   if( lToolTipBalloon )
   {
      iStyle = iStyle | TTS_BALLOON;
   }

   if( !hWndTT )
      hWndTT = CreateWindow( TOOLTIPS_CLASS, NULL, iStyle,
            CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
            NULL, ( HMENU ) NULL, GetModuleHandle( NULL ), NULL );
   if( !hWndTT )
   {
      hb_retnl( 0 );
      return;
   }
   ti.uFlags = TTF_SUBCLASS | TTF_IDISHWND;
   ti.hwnd = hWnd;
   ti.uId = ( UINT ) hb_parnl( 2 );
   // ti.uId = (UINT) GetDlgItem( hWnd, hb_parni( 2 ) );
   ti.hinst = GetModuleHandle( NULL );
   ti.lpszText = ( LPTSTR ) HB_PARSTR( 3, &hStr, NULL );

   hb_retl( SendMessage( hWndTT, TTM_ADDTOOL, 0,
               ( LPARAM ) ( LPTOOLINFO ) & ti ) );
   hb_strfree( hStr );
}

HB_FUNC( DELTOOLTIP )
{
   TOOLINFO ti;

   if( hWndTT )
   {
      ti.cbSize = sizeof( TOOLINFO );
      ti.uFlags = TTF_IDISHWND;
      ti.hwnd = ( HWND ) HB_PARHANDLE( 1 );
      ti.uId = ( UINT ) hb_parnl( 2 );
      // ti.uId = (UINT) GetDlgItem( hWnd, hb_parni( 2 ) );
      ti.hinst = GetModuleHandle( NULL );

      SendMessage( hWndTT, TTM_DELTOOL, 0, ( LPARAM ) ( LPTOOLINFO ) & ti );
   }
}

HB_FUNC( SETTOOLTIPTITLE )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );

   if( hWndTT )
   {
      TOOLINFO ti;
      void * hStr;

      ti.cbSize = sizeof( TOOLINFO );
      ti.uFlags = TTF_IDISHWND;
      ti.hwnd = hWnd;
      ti.uId = ( UINT ) hb_parnl( 2 );
      ti.hinst = GetModuleHandle( NULL );
      ti.lpszText = ( LPTSTR ) HB_PARSTR( 3, &hStr, NULL );

      hb_retl( SendMessage( hWndTT, TTM_SETTOOLINFO, 0,
                            ( LPARAM ) ( LPTOOLINFO ) & ti ) );
      hb_strfree( hStr );
   }
}

/*
HB_FUNC( SHOWTOOLTIP )
{
   MSG msg;

   msg.lParam = hb_parnl( 3 );
   msg.wParam = hb_parnl( 2 );
   msg.message = WM_MOUSEMOVE;
   msg.hwnd = (HWND) HB_PARHANDLE( 1 );
   hb_retnl( SendMessage( hWndTT, TTM_RELAYEVENT, 0, (LPARAM) (LPMSG) &msg ) );
}
*/

HB_FUNC( CREATEUPDOWNCONTROL )
{
   HB_RETHANDLE( CreateUpDownControl( WS_CHILD | WS_BORDER | WS_VISIBLE |
               hb_parni( 3 ), hb_parni( 4 ), hb_parni( 5 ), hb_parni( 6 ),
               hb_parni( 7 ), ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ),
               GetModuleHandle( NULL ), ( HWND ) HB_PARHANDLE( 8 ),
               hb_parni( 9 ), hb_parni( 10 ), hb_parni( 11 ) ) );
}

HB_FUNC( SETUPDOWN )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), UDM_SETPOS, 0, hb_parnl( 2 ) );
}

HB_FUNC( GETNOTIFYDELTAPOS )
{
   int iItem = hb_parnl( 2 ) ;
   if ( iItem < 2 )
      hb_retni( (LONG) (((NMUPDOWN *) HB_PARHANDLE( 1 ) )->iPos ) );
   else
      hb_retni( (LONG) (((NMUPDOWN *) HB_PARHANDLE( 1 ) )->iDelta ) );
}

HB_FUNC( CREATEDATEPICKER )
{
   HWND hCtrl;
   LONG nStyle = hb_parnl( 7 ) | WS_CHILD | WS_VISIBLE | WS_TABSTOP;

   hCtrl = CreateWindowEx( WS_EX_CLIENTEDGE, TEXT( "SYSDATETIMEPICK32" ),
         NULL, nStyle,
         hb_parni( 3 ), hb_parni( 4 ),  /* x, y       */
         hb_parni( 5 ), hb_parni( 6 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
         ( HMENU ) hb_parni( 2 ),       /* control ID  */
         GetModuleHandle( NULL ), NULL );

   HB_RETHANDLE( hCtrl );
}

HB_FUNC( SETDATEPICKER )
{
   PHB_ITEM pDate = hb_param( 2, HB_IT_DATE );

   if( pDate )
   {
      SYSTEMTIME sysTime;
#ifndef HARBOUR_OLD_VERSION
      int lYear, lMonth, lDay;
#else
      long lYear, lMonth, lDay;
#endif

      hb_dateDecode( hb_itemGetDL( pDate ), &lYear, &lMonth, &lDay );

      sysTime.wYear = ( unsigned short ) lYear;
      sysTime.wMonth = ( unsigned short ) lMonth;
      sysTime.wDay = ( unsigned short ) lDay;
      sysTime.wDayOfWeek = 0;
      sysTime.wHour = 0;
      sysTime.wMinute = 0;
      sysTime.wSecond = 0;
      sysTime.wMilliseconds = 0;

      SendMessage( ( HWND ) HB_PARHANDLE( 1 ), DTM_SETSYSTEMTIME, GDT_VALID,
                   ( LPARAM ) & sysTime );
   }
}

HB_FUNC( SETDATEPICKERNULL )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), DTM_SETSYSTEMTIME, GDT_NONE,
                ( LPARAM ) 0 );
}

HB_FUNC( GETDATEPICKER )
{
   SYSTEMTIME st;

   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), DTM_GETSYSTEMTIME, 0,
                ( LPARAM ) & st );
   hb_retd( st.wYear, st.wMonth, st.wDay );
}

HB_FUNC( CREATETABCONTROL )
{
   HWND hTab;

   hTab = CreateWindow( WC_TABCONTROL, NULL, WS_CHILD | WS_VISIBLE | hb_parnl( 3 ),     /* style  */
         hb_parni( 4 ), hb_parni( 5 ), hb_parni( 6 ), hb_parni( 7 ), ( HWND ) HB_PARHANDLE( 1 ),        /* parent window    */
         ( HMENU ) hb_parni( 2 ),       /* control ID  */
         GetModuleHandle( NULL ), NULL );

   HB_RETHANDLE( hTab );

}

HB_FUNC( INITTABCONTROL )
{
   HWND hTab = ( HWND ) HB_PARHANDLE( 1 );
   PHB_ITEM pArr = hb_param( 2, HB_IT_ARRAY );
   int iItems = hb_parnl( 3 );
   TC_ITEM tie;
   ULONG ul, ulTabs = hb_arrayLen( pArr );

   tie.mask = TCIF_TEXT | TCIF_IMAGE;
   tie.iImage = iItems == 0 ? -1 : 0;

   for( ul = 1; ul <= ulTabs; ul++ )
   {
      void * hStr;

      tie.pszText = ( LPTSTR ) HB_ARRAYGETSTR( pArr, ul, &hStr, NULL );
      if( tie.pszText == NULL )
         tie.pszText = ( LPTSTR ) TEXT( "" );

      if( TabCtrl_InsertItem( hTab, ul - 1, &tie ) == -1 )
      {
         DestroyWindow( hTab );
         hTab = NULL;
      }
      hb_strfree( hStr );

      if( tie.iImage > -1 )
         tie.iImage++;
   }
}

HB_FUNC( ADDTAB )
{
   TC_ITEM tie;
   void * hStr;

   tie.mask = TCIF_TEXT | TCIF_IMAGE;
   tie.iImage = -1;
   tie.pszText = ( LPTSTR ) HB_PARSTR( 3, &hStr, NULL );
   TabCtrl_InsertItem( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ), &tie );
   hb_strfree( hStr );
}

HB_FUNC( ADDTABDIALOG )
{
   TC_ITEM tie;
   void * hStr;
   HWND pWnd = ( HWND ) HB_PARHANDLE( 4 );

   tie.mask = TCIF_TEXT | TCIF_IMAGE | TCIF_PARAM;
   tie.lParam = ( LPARAM ) pWnd;
   tie.iImage = -1;
   tie.pszText = ( LPTSTR ) HB_PARSTR( 3, &hStr, NULL );
   TabCtrl_InsertItem( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ), &tie );
   hb_strfree( hStr );
}

HB_FUNC( DELETETAB )
{
   TabCtrl_DeleteItem( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ) );
}


HB_FUNC( GETCURRENTTAB )
{
   hb_retni( TabCtrl_GetCurSel( ( HWND ) HB_PARHANDLE( 1 ) ) + 1 );
}

HB_FUNC( SETTABSIZE )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), TCM_SETITEMSIZE, 0,
                MAKELPARAM( hb_parni( 2 ), hb_parni( 3 ) ) );
}

HB_FUNC( SETTABNAME )
{
   TC_ITEM tie;
   void * hStr;

   tie.mask = TCIF_TEXT;
   tie.pszText = ( LPTSTR ) HB_PARSTR( 3, &hStr, NULL );

   TabCtrl_SetItem( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ), &tie );
   hb_strfree( hStr );
}

HB_FUNC( TAB_HITTEST )
{
   TC_HITTESTINFO ht;
   HWND hTab = ( HWND ) HB_PARHANDLE( 1 );
   int res;

   if( hb_pcount(  ) > 1 && ISNUM( 2 ) && ISNUM( 3 ) )
   {
      ht.pt.x = hb_parni( 2 );
      ht.pt.y = hb_parni( 3 );
   }
   else
   {
      GetCursorPos( &( ht.pt ) );
      ScreenToClient( hTab, &( ht.pt ) );
   }

   res = ( int ) SendMessage( hTab, TCM_HITTEST, 0, ( LPARAM ) & ht );

   hb_storni( ht.flags, 4 );
   hb_retni( res );
}

HB_FUNC( GETNOTIFYKEYDOWN )
{
   hb_retni( ( WORD ) ( ( ( TC_KEYDOWN * ) HB_PARHANDLE( 1 ) )->wVKey ) );
}

HB_FUNC( CREATETREE )
{
   HWND hCtrl;

   hCtrl = CreateWindowEx( WS_EX_CLIENTEDGE, WC_TREEVIEW, 0,
         WS_CHILD | WS_VISIBLE | WS_TABSTOP | hb_parnl( 3 ),
         hb_parni( 4 ), hb_parni( 5 ),  /* x, y       */
         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
         ( HMENU ) hb_parni( 2 ),       /* control ID  */
         GetModuleHandle( NULL ), NULL );

   if( !ISNIL( 8 ) )
      SendMessage( hCtrl, TVM_SETTEXTCOLOR, 0, ( LPARAM ) ( hb_parnl( 8 ) ) );
   if( !ISNIL( 9 ) )
      SendMessage( hCtrl, TVM_SETBKCOLOR, 0, ( LPARAM ) ( hb_parnl( 9 ) ) );

   HB_RETHANDLE( hCtrl );
}

HB_FUNC( TREEADDNODE )
{
   TV_ITEM tvi;
   TV_INSERTSTRUCT is;

   int nPos = hb_parni( 5 );
   PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT );
   void * hStr;

   tvi.iImage = 0;
   tvi.iSelectedImage = 0;

   tvi.mask = TVIF_TEXT | TVIF_PARAM;
   tvi.pszText = ( LPTSTR ) HB_PARSTR( 6, &hStr, NULL );
   tvi.lParam = ( LPARAM ) ( hb_itemNew( pObject ) );
   if( hb_pcount(  ) > 6 && !ISNIL( 7 ) )
   {
      tvi.iImage = hb_parni( 7 );
      tvi.mask |= TVIF_IMAGE;
      if( hb_pcount(  ) > 7 && !ISNIL( 8 ) )
      {
         tvi.iSelectedImage = hb_parni( 8 );
         tvi.mask |= TVIF_SELECTEDIMAGE;
      }
   }

#if !defined(__BORLANDC__) ||  (__BORLANDC__ >= 1424)
   is.item = tvi;
#else
   is.DUMMYUNIONNAME.item = tvi;
#endif

   is.hParent = ( ISNIL( 3 ) ? NULL : ( HTREEITEM ) HB_PARHANDLE( 3 ) );
   if( nPos == 0 )
      is.hInsertAfter = ( HTREEITEM ) HB_PARHANDLE( 4 );
   else if( nPos == 1 )
      is.hInsertAfter = TVI_FIRST;
   else if( nPos == 2 )
      is.hInsertAfter = TVI_LAST;

   HB_RETHANDLE( SendMessage( ( HWND ) HB_PARHANDLE( 2 ), TVM_INSERTITEM, 0,
               ( LPARAM ) ( &is ) ) );

   if( tvi.mask & TVIF_IMAGE )
      if ( tvi.iImage )
         DeleteObject( ( HGDIOBJ ) tvi.iImage );
   if( tvi.mask & TVIF_SELECTEDIMAGE )
      if ( tvi.iSelectedImage )
         DeleteObject( ( HGDIOBJ ) tvi.iSelectedImage );

   hb_strfree( hStr );
}

/*
HB_FUNC( TREEDELNODE )
{

   hb_parl( TreeView_DeleteItem( (HWND)HB_PARHANDLE(1), (HTREEITEM)HB_PARHANDLE(2) ) );
}

HB_FUNC( TREEDELALLNODES )
{

   TreeView_DeleteAllItems( (HWND)HB_PARHANDLE(1) );
}
*/

HB_FUNC( TREEGETSELECTED )
{
   TV_ITEM TreeItem;

   memset( &TreeItem, 0, sizeof( TV_ITEM ) );
   TreeItem.mask = TVIF_HANDLE | TVIF_PARAM;
   TreeItem.hItem = TreeView_GetSelection( ( HWND ) HB_PARHANDLE( 1 ) );

   if( TreeItem.hItem )
   {
      PHB_ITEM oNode;           // = hb_itemNew( NULL );
      SendMessage( ( HWND ) HB_PARHANDLE( 1 ), TVM_GETITEM, 0,
            ( LPARAM ) ( &TreeItem ) );
      oNode = ( PHB_ITEM ) TreeItem.lParam;
      hb_itemReturn( oNode );
   }
}

/*
HB_FUNC( TREENODEHASCHILDREN )
{

   TV_ITEM TreeItem;

   memset( &TreeItem, 0, sizeof(TV_ITEM) );
   TreeItem.mask = TVIF_HANDLE | TVIF_CHILDREN;
   TreeItem.hItem = (HTREEITEM) HB_PARHANDLE(2);

   SendMessage( (HWND)HB_PARHANDLE(1), TVM_GETITEM, 0, (LPARAM)(&TreeItem) );
   hb_retni( TreeItem.cChildren );
}

*/

HB_FUNC( TREEGETNODETEXT )
{
   TV_ITEM TreeItem;
   TCHAR ItemText[256] = { 0 };

   memset( &TreeItem, 0, sizeof( TV_ITEM ) );
   TreeItem.mask = TVIF_HANDLE | TVIF_TEXT;
   TreeItem.hItem = ( HTREEITEM ) HB_PARHANDLE( 2 );
   TreeItem.pszText = ItemText;
   TreeItem.cchTextMax = 256;

   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), TVM_GETITEM, 0,
                ( LPARAM ) ( &TreeItem ) );
   HB_RETSTR( TreeItem.pszText );
}

#define TREE_SETITEM_TEXT       1

HB_FUNC( TREESETITEM )
{
   TV_ITEM TreeItem;
   int iType = hb_parni( 3 );
   void * hStr = NULL;

   memset( &TreeItem, 0, sizeof( TV_ITEM ) );
   TreeItem.mask = TVIF_HANDLE;
   TreeItem.hItem = ( HTREEITEM ) HB_PARHANDLE( 2 );

   if( iType == TREE_SETITEM_TEXT )
   {
      TreeItem.mask |= TVIF_TEXT;
      TreeItem.pszText = ( LPTSTR ) HB_PARSTR( 4, &hStr, NULL );
   }
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), TVM_SETITEM, 0,
                ( LPARAM ) ( &TreeItem ) );
   hb_strfree( hStr );
}

#define TREE_GETNOTIFY_HANDLE       1
#define TREE_GETNOTIFY_PARAM        2
#define TREE_GETNOTIFY_EDIT         3
#define TREE_GETNOTIFY_EDITPARAM    4
#define TREE_GETNOTIFY_ACTION       5

HB_FUNC( TREE_GETNOTIFY )
{
   int iType = hb_parni( 2 );

   if( iType == TREE_GETNOTIFY_HANDLE )
      hb_retnl( ( LONG ) ( ( ( NM_TREEVIEW * ) HB_PARHANDLE( 1 ) )->itemNew.
                  hItem ) );

   if( iType == TREE_GETNOTIFY_ACTION )
      hb_retnl( ( LONG ) ( ( ( NM_TREEVIEW * ) HB_PARHANDLE( 1 ) )->
                  action ) );

   else if( iType == TREE_GETNOTIFY_PARAM ||
         iType == TREE_GETNOTIFY_EDITPARAM )
   {
      PHB_ITEM oNode;           // = hb_itemNew( NULL );
      if( iType == TREE_GETNOTIFY_EDITPARAM )
         oNode =
               ( PHB_ITEM ) ( ( ( TV_DISPINFO * ) HB_PARHANDLE( 1 ) )->item.
               lParam );
      else
         oNode =
               ( PHB_ITEM ) ( ( ( NM_TREEVIEW * ) HB_PARHANDLE( 1 ) )->
               itemNew.lParam );

      hb_itemReturn( oNode );

   }
   else if( iType == TREE_GETNOTIFY_EDIT )
   {
      TV_DISPINFO *tv;
      tv = ( TV_DISPINFO * ) HB_PARHANDLE( 1 );

      HB_RETSTR( ( tv->item.pszText ) ? tv->item.pszText : TEXT( "" ) );
   }
}

/*
 * Tree_Hittest( hTree, x, y ) --> oNode
 */
HB_FUNC( TREE_HITTEST )
{
   TV_HITTESTINFO ht;
   HWND hTree = ( HWND ) HB_PARHANDLE( 1 );

   if( hb_pcount(  ) > 1 && ISNUM( 2 ) && ISNUM( 3 ) )
   {
      ht.pt.x = hb_parni( 2 );
      ht.pt.y = hb_parni( 3 );
   }
   else
   {
      GetCursorPos( &( ht.pt ) );
      ScreenToClient( hTree, &( ht.pt ) );
   }

   SendMessage( hTree, TVM_HITTEST, 0, ( LPARAM ) & ht );

   if( ht.hItem )
   {
      PHB_ITEM oNode;           // = hb_itemNew( NULL );
      TV_ITEM TreeItem;

      memset( &TreeItem, 0, sizeof( TV_ITEM ) );
      TreeItem.mask = TVIF_HANDLE | TVIF_PARAM;
      TreeItem.hItem = ht.hItem;

      SendMessage( hTree, TVM_GETITEM, 0, ( LPARAM ) ( &TreeItem ) );
      oNode = ( PHB_ITEM ) TreeItem.lParam;
      hb_itemReturn( oNode );
      if( hb_pcount(  ) > 3 )
         hb_storni( ( int ) ht.flags, 4 );
   }
   else
      hb_ret(  );
}

HB_FUNC( TREE_RELEASENODE )
{
   TV_ITEM TreeItem;

   memset( &TreeItem, 0, sizeof( TV_ITEM ) );
   TreeItem.mask = TVIF_HANDLE | TVIF_PARAM;
   TreeItem.hItem = ( HTREEITEM ) HB_PARHANDLE( 2 );

   if( TreeItem.hItem )
   {
      SendMessage( ( HWND ) HB_PARHANDLE( 1 ), TVM_GETITEM, 0,
            ( LPARAM ) ( &TreeItem ) );
      hb_itemRelease( ( PHB_ITEM ) TreeItem.lParam );
      TreeItem.lParam = 0;
      SendMessage( ( HWND ) HB_PARHANDLE( 1 ), TVM_SETITEM, 0,
            ( LPARAM ) ( &TreeItem ) );
   }

}

/*
 * CreateImagelist( array, cx, cy, nGrow, flags )
*/
HB_FUNC( CREATEIMAGELIST )
{
   PHB_ITEM pArray = hb_param( 1, HB_IT_ARRAY );
   UINT flags = ( ISNIL( 5 ) ) ? ILC_COLOR : hb_parni( 5 );
   HIMAGELIST himl;
   ULONG ul, ulLen = hb_arrayLen( pArray );
   HBITMAP hbmp;

   himl = ImageList_Create( hb_parni( 2 ), hb_parni( 3 ), flags,
         ulLen, hb_parni( 4 ) );

   for( ul = 1; ul <= ulLen; ul++ )
   {
      hbmp = ( HBITMAP ) HB_GETPTRHANDLE( pArray, ul );
      ImageList_Add( himl, hbmp, ( HBITMAP ) NULL );
      DeleteObject( hbmp );
   }

   HB_RETHANDLE( himl );
}

HB_FUNC( IMAGELIST_ADD )
{
   hb_retnl( ImageList_Add( ( HIMAGELIST ) HB_PARHANDLE( 1 ),
               ( HBITMAP ) HB_PARHANDLE( 2 ), ( HBITMAP ) NULL ) );
}

HB_FUNC( IMAGELIST_ADDMASKED )
{
   hb_retnl( ImageList_AddMasked( ( HIMAGELIST ) HB_PARHANDLE( 1 ),
               ( HBITMAP ) HB_PARHANDLE( 2 ), ( COLORREF ) hb_parnl( 3 ) ) );
}

/*
 *  SetTimer( hWnd, idTimer, i_MilliSeconds )
 */

/* 22/09/2005 - <maurilio.longo@libero.it>
      If I pass a fourth parameter as 0 (zero) I don't set
      the TimerProc, this way I can receive WM_TIMER messages
      inside an ON OTHER MESSAGES code block
*/
HB_FUNC( SETTIMER )
{
   SetTimer( ( HWND ) HB_PARHANDLE( 1 ), ( UINT ) hb_parni( 2 ),
             ( UINT ) hb_parni( 3 ),
             hb_pcount() == 3 ? s_timerProc : ( TIMERPROC ) NULL );
}

/*
 *  KillTimer( hWnd, idTimer )
 */

HB_FUNC( KILLTIMER )
{
   hb_retl( KillTimer( ( HWND ) HB_PARHANDLE( 1 ), ( UINT ) hb_parni( 2 ) ) );
}

HB_FUNC( GETPARENT )
{
   HB_RETHANDLE( GetParent( ( HWND ) HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( GETANCESTOR )
{
   HB_RETHANDLE( GetAncestor( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ) ) );
}

HB_FUNC( LOADCURSOR )
{
   void * hStr;
   LPCTSTR lpStr = HB_PARSTR( 1, &hStr, NULL );

   if( lpStr )
      HB_RETHANDLE( LoadCursor( GetModuleHandle( NULL ), lpStr ) );
   else
      HB_RETHANDLE( LoadCursor( NULL, MAKEINTRESOURCE( hb_parni( 1 ) ) ) );
   hb_strfree( hStr );
}

HB_FUNC( HWG_SETCURSOR )
{
   HB_RETHANDLE( SetCursor( ( HCURSOR ) HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( HWG_GETCURSOR )
{
   HB_RETHANDLE( GetCursor() );
}

HB_FUNC( GETTOOLTIPHANDLE )     // added by MAG
{
   HB_RETHANDLE( hWndTT );
}

HB_FUNC( SETTOOLTIPBALLOON )    // added by MAG
{
   lToolTipBalloon = hb_parl( 1 );
}

HB_FUNC( GETTOOLTIPBALLOON )    // added by MAG
{
   hb_retl( lToolTipBalloon );
}

HB_FUNC( HWG_REGPANEL )
{
   static BOOL bRegistered = FALSE;

   if( !bRegistered )
   {
      WNDCLASS wndclass;

      wndclass.style = CS_OWNDC | CS_VREDRAW | CS_HREDRAW | CS_DBLCLKS;
      wndclass.lpfnWndProc = DefWindowProc;
      wndclass.cbClsExtra = 0;
      wndclass.cbWndExtra = 0;
      wndclass.hInstance = GetModuleHandle( NULL );
      wndclass.hIcon = NULL;
      wndclass.hCursor = LoadCursor( NULL, IDC_ARROW );
      wndclass.hbrBackground = ( HBRUSH ) ( COLOR_3DFACE + 1 );
      wndclass.lpszMenuName = NULL;
      wndclass.lpszClassName = TEXT( "PANEL" );

      RegisterClass( &wndclass );
      bRegistered = TRUE;
   }
}

HB_FUNC( HWG_REGOWNBTN )
{
   static BOOL bRegistered = FALSE;

   WNDCLASS wndclass;

   if( !bRegistered )
   {
      wndclass.style = CS_OWNDC | CS_VREDRAW | CS_HREDRAW | CS_DBLCLKS;
      wndclass.lpfnWndProc = WinCtrlProc;
      wndclass.cbClsExtra = 0;
      wndclass.cbWndExtra = 0;
      wndclass.hInstance = GetModuleHandle( NULL );
      wndclass.hIcon = NULL;
      wndclass.hCursor = LoadCursor( NULL, IDC_ARROW );
      wndclass.hbrBackground = ( HBRUSH ) ( COLOR_3DFACE + 1 );
      wndclass.lpszMenuName = NULL;
      wndclass.lpszClassName = TEXT( "OWNBTN" );

      RegisterClass( &wndclass );
      bRegistered = TRUE;
   }
}

HB_FUNC( HWG_REGBROWSE )
{

   static BOOL bRegistered = FALSE;

   if( !bRegistered )
   {
      WNDCLASS wndclass;

      wndclass.style = CS_OWNDC | CS_VREDRAW | CS_HREDRAW | CS_DBLCLKS;
      wndclass.lpfnWndProc = WinCtrlProc;
      wndclass.cbClsExtra = 0;
      wndclass.cbWndExtra = 0;
      wndclass.hInstance = GetModuleHandle( NULL );
      // wndclass.hIcon         = LoadIcon (NULL, IDI_APPLICATION) ;
      wndclass.hIcon = NULL;
      wndclass.hCursor = LoadCursor( NULL, IDC_ARROW );
      wndclass.hbrBackground = ( HBRUSH ) ( COLOR_WINDOW + 1 );
      wndclass.lpszMenuName = NULL;
      wndclass.lpszClassName = TEXT( "BROWSE" );

      RegisterClass( &wndclass );
      bRegistered = TRUE;
   }
}

static void CALLBACK s_timerProc( HWND hWnd, UINT message, UINT idTimer, DWORD dwTime )
{
   static PHB_DYNS s_pSymTest = NULL;

   HB_SYMBOL_UNUSED( message );

   if( s_pSymTest == NULL )
      s_pSymTest = hb_dynsymGetCase( "TIMERPROC" );

   if( hb_dynsymIsFunction( s_pSymTest ) )
   {
      hb_vmPushDynSym( s_pSymTest );
      hb_vmPushNil();   /* places NIL at self */
//      hb_vmPushLong( (LONG ) hWnd );    /* pushes parameters on to the hvm stack */
      HB_PUSHITEM( hWnd );
      hb_vmPushLong( ( LONG ) idTimer );
      hb_vmPushLong( ( LONG ) dwTime );
      hb_vmDo( 3 );             /* where iArgCount is the number of pushed parameters */
   }
}

BOOL RegisterWinCtrl( void )    // Added by jamaj - Used by WinCtrl
{
   WNDCLASS wndclass;

   wndclass.style = CS_OWNDC | CS_VREDRAW | CS_HREDRAW | CS_DBLCLKS;
   wndclass.lpfnWndProc = WinCtrlProc;
   wndclass.cbClsExtra = 0;
   wndclass.cbWndExtra = 0;
   wndclass.hInstance = GetModuleHandle( NULL );
   wndclass.hCursor = LoadCursor( NULL, IDC_ARROW );
   wndclass.hbrBackground = ( HBRUSH ) ( COLOR_3DFACE + 1 );
   wndclass.lpszMenuName = NULL;
   wndclass.lpszClassName = TEXT( "WINCTRL" );

   return RegisterClass( &wndclass );
}

HB_FUNC( HWG_INITWINCTRL )
{
   SetWindowLong( ( HWND ) HB_PARHANDLE( 1 ),
         GWL_WNDPROC, ( LONG ) WinCtrlProc );
}

LRESULT CALLBACK WinCtrlProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return ( DefWindowProc( hWnd, message, wParam, lParam ) );
      else
         return res;
   }
   else
      return ( DefWindowProc( hWnd, message, wParam, lParam ) );
}

HB_FUNC( HWG_INITSTATICPROC )
{
   wpOrigStaticProc = ( WNDPROC ) SetWindowLong( ( HWND ) HB_PARHANDLE( 1 ),
         GWL_WNDPROC, ( LONG ) StaticSubclassProc );
}

LRESULT APIENTRY StaticSubclassProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return ( CallWindowProc( wpOrigStaticProc, hWnd, message, wParam,
                     lParam ) );
      else
         return res;
   }
   else
      return ( CallWindowProc( wpOrigStaticProc, hWnd, message, wParam,
                  lParam ) );
}


HB_FUNC( HWG_INITEDITPROC )
{
   wpOrigEditProc = ( WNDPROC ) SetWindowLong( ( HWND ) HB_PARHANDLE( 1 ),
         GWL_WNDPROC, ( LONG ) EditSubclassProc );
}

LRESULT APIENTRY EditSubclassProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return ( CallWindowProc( wpOrigEditProc, hWnd, message, wParam,
                     lParam ) );
      else
         return res;
   }
   else
      return ( CallWindowProc( wpOrigEditProc, hWnd, message, wParam,
                  lParam ) );
}

HB_FUNC( HWG_INITBUTTONPROC )
{
//   wpOrigButtonProc = (WNDPROC) SetWindowLong( (HWND) HB_PARHANDLE(1),
//                                 GWL_WNDPROC, (LONG) ButtonSubclassProc );
   wpOrigButtonProc =
         ( LONG_PTR ) SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
         GWLP_WNDPROC, ( LONG_PTR ) ButtonSubclassProc );

}

LRESULT APIENTRY ButtonSubclassProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return ( CallWindowProc( ( WNDPROC ) wpOrigButtonProc, hWnd, message,
                     wParam, lParam ) );
      else
         return res;
   }
   else
      return ( CallWindowProc( ( WNDPROC ) wpOrigButtonProc, hWnd, message,
                  wParam, lParam ) );
}

LRESULT APIENTRY ComboSubclassProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return ( CallWindowProc( wpOrigComboProc, hWnd, message, wParam,
                     lParam ) );
      else
         return res;
   }
   else
      return ( CallWindowProc( wpOrigComboProc, hWnd, message, wParam,
                  lParam ) );
}

HB_FUNC( HWG_INITCOMBOPROC )
{
   wpOrigComboProc = ( WNDPROC ) SetWindowLong( ( HWND ) HB_PARHANDLE( 1 ),
         GWL_WNDPROC, ( LONG ) ComboSubclassProc );
}


LRESULT APIENTRY ListSubclassProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return ( CallWindowProc( wpOrigListProc, hWnd, message, wParam,
                     lParam ) );
      else
         return res;
   }
   else
      return ( CallWindowProc( wpOrigListProc, hWnd, message, wParam,
                  lParam ) );
}

HB_FUNC( HWG_INITLISTPROC )
{
   wpOrigListProc = ( WNDPROC ) SetWindowLong( ( HWND ) HB_PARHANDLE( 1 ),
         GWL_WNDPROC, ( LONG ) ListSubclassProc );
}


HB_FUNC( HWG_INITUPDOWNPROC )
{
   wpOrigUpDownProc = ( WNDPROC ) SetWindowLong( ( HWND ) HB_PARHANDLE( 1 ),
         GWL_WNDPROC, ( LONG ) UpDownSubclassProc );
}

LRESULT APIENTRY UpDownSubclassProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return ( CallWindowProc( wpOrigUpDownProc, hWnd, message, wParam,
                     lParam ) );
      else
         return res;
   }
   else
      return ( CallWindowProc( wpOrigUpDownProc, hWnd, message, wParam,
                  lParam ) );
}

HB_FUNC( HWG_INITDATEPICKERPROC )
{
   wpOrigDatePickerProc =
         ( WNDPROC ) SetWindowLong( ( HWND ) HB_PARHANDLE( 1 ), GWL_WNDPROC,
         ( LONG ) DatePickerSubclassProc );
}

LRESULT APIENTRY DatePickerSubclassProc( HWND hWnd, UINT message,
      WPARAM wParam, LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return ( CallWindowProc( wpOrigDatePickerProc, hWnd, message, wParam,
                     lParam ) );
      else
         return res;
   }
   else
      return ( CallWindowProc( wpOrigDatePickerProc, hWnd, message, wParam,
                  lParam ) );
}

HB_FUNC( HWG_INITTRACKPROC )
{
   wpOrigTrackProc = ( WNDPROC ) SetWindowLong( ( HWND ) HB_PARHANDLE( 1 ),
         GWL_WNDPROC, ( LONG ) TrackSubclassProc );
}

LRESULT APIENTRY TrackSubclassProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return ( CallWindowProc( wpOrigTrackProc, hWnd, message, wParam,
                     lParam ) );
      else
         return res;
   }
   else
      return ( CallWindowProc( wpOrigTrackProc, hWnd, message, wParam,
                  lParam ) );
}

HB_FUNC( HWG_INITTABPROC )
{
   wpOrigTabProc = ( WNDPROC ) SetWindowLong( ( HWND ) HB_PARHANDLE( 1 ),
         GWL_WNDPROC, ( LONG ) TabSubclassProc );
}

LRESULT APIENTRY TabSubclassProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return ( CallWindowProc( wpOrigTabProc, hWnd, message, wParam,
                     lParam ) );
      else
         return res;
   }
   else
      return ( CallWindowProc( wpOrigTabProc, hWnd, message, wParam,
                  lParam ) );
}

#if defined(__MINGW32__) && !defined(LPNMTBGETINFOTIP)
typedef struct tagNMTBGETINFOTIPA
{
   NMHDR hdr;
   LPSTR pszText;
   int cchTextMax;
   int iItem;
   LPARAM lParam;
} NMTBGETINFOTIPA, *LPNMTBGETINFOTIPA;

typedef struct tagNMTBGETINFOTIPW
{
   NMHDR hdr;
   LPWSTR pszText;
   int cchTextMax;
   int iItem;
   LPARAM lParam;
} NMTBGETINFOTIPW, *LPNMTBGETINFOTIPW;

#ifdef UNICODE
#define LPNMTBGETINFOTIP        LPNMTBGETINFOTIPW
#else
#define LPNMTBGETINFOTIP        LPNMTBGETINFOTIPA
#endif

#endif

HB_FUNC( CREATETOOLBAR )
{

   ULONG ulStyle = hb_parnl( 3 );
   ULONG ulExStyle =
         ( ( !ISNIL( 8 ) ) ? hb_parnl( 8 ) : 0 ) | ( ( ulStyle & WS_BORDER ) ?
         WS_EX_CLIENTEDGE : 0 );

   HWND hWndCtrl = CreateWindowEx( ulExStyle,   /* extended style */
         TOOLBARCLASSNAME,      /* predefined class  */
         NULL,                  /* title   -   TBSTYLE_TRANSPARENT | */
         WS_CHILD | WS_OVERLAPPED | WS_VISIBLE | TBSTYLE_ALTDRAG | TBSTYLE_TOOLTIPS |  TBSTYLE_WRAPABLE | CCS_TOP | CCS_NORESIZE | ulStyle, /* style  */
         hb_parni( 4 ), hb_parni( 5 ),  /* x, y       */
         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
         ( HMENU ) hb_parni( 2 ),       /* control ID  */
         GetModuleHandle( NULL ),
         NULL );

   HB_RETHANDLE( hWndCtrl );

}

HB_FUNC( TOOLBARADDBUTTONS )
{

   HWND hWndCtrl = ( HWND ) HB_PARHANDLE( 1 );
   /* HWND hToolTip = ( HWND ) HB_PARHANDLE( 4 ) ; */
   PHB_ITEM pArray = hb_param( 2, HB_IT_ARRAY );
   int iButtons = hb_parni( 3 );
   TBBUTTON *tb =
         ( struct _TBBUTTON * ) hb_xgrab( iButtons * sizeof( TBBUTTON ) );
   PHB_ITEM pTemp;

   ULONG ulCount;
   ULONG ulID;
   DWORD style = GetWindowLong( hWndCtrl, GWL_STYLE );

   //SendMessage(hWndCtrl, CCM_SETVERSION, (WPARAM) 4, 0);   

   SetWindowLong( hWndCtrl, GWL_STYLE,
         style | TBSTYLE_TOOLTIPS | TBSTYLE_FLAT );

   SendMessage( hWndCtrl, TB_BUTTONSTRUCTSIZE, sizeof( TBBUTTON ), 0L );

   for( ulCount = 0; ( ulCount < hb_arrayLen( pArray ) ); ulCount++ )
   {

      pTemp = hb_arrayGetItemPtr( pArray, ulCount + 1 );
      ulID = hb_arrayGetNI( pTemp, 1 );
      if ( hb_arrayGetNI( pTemp, 4 ) == TBSTYLE_SEP )
         tb[ulCount].iBitmap = 8 ;
      else
         tb[ulCount].iBitmap = ulID - 1;   //ulID > 0 ? ( int ) ulCount : -1 ;
      tb[ulCount].idCommand = hb_arrayGetNI( pTemp, 2 );
      tb[ulCount].fsState = hb_arrayGetNI( pTemp, 3 );
      tb[ulCount].fsStyle = hb_arrayGetNI( pTemp, 4 );
      tb[ulCount].dwData = hb_arrayGetNI( pTemp, 5 );
      tb[ulCount].iString =
            hb_arrayGetCLen( pTemp, 6 ) > 0 ? ( int ) hb_arrayGetCPtr( pTemp,
            6 ) : 0;

   }

   SendMessage( hWndCtrl, TB_ADDBUTTONS, ( WPARAM ) iButtons,
         ( LPARAM ) ( LPTBBUTTON ) tb );
   SendMessage( hWndCtrl, TB_AUTOSIZE, 0, 0 );

   hb_xfree( tb );
}


HB_FUNC( TOOLBAR_LOADIMAGE )
{
   TBADDBITMAP tbab;
   HWND hWndCtrl = ( HWND ) HB_PARHANDLE( 1 );
   int iIDB = hb_parni( 2 );

   tbab.hInst = NULL;
   tbab.nID = iIDB;

   SendMessage( hWndCtrl, TB_ADDBITMAP, 0, ( LPARAM ) & tbab );
}

HB_FUNC( TOOLBAR_LOADSTANDARTIMAGE )
{
   TBADDBITMAP tbab;
   HWND hWndCtrl = ( HWND ) HB_PARHANDLE( 1 );
   int iIDB = hb_parni( 2 );
   HIMAGELIST himl;

   tbab.hInst = HINST_COMMCTRL;
   tbab.nID = iIDB;             //IDB_HIST_SMALL_COLOR / IDB_VIEW_SMALL_COLOR / IDB_VIEW_SMALL_COLOR;

   SendMessage( hWndCtrl, TB_ADDBITMAP, 0, ( LPARAM ) & tbab );
   himl = ( HIMAGELIST ) SendMessage( hWndCtrl, TB_GETIMAGELIST, 0, 0 );
   hb_retni( ( int ) ImageList_GetImageCount( himl ) );
}

HB_FUNC( ImageList_GetImageCount )
{
   HIMAGELIST hWndCtrl = ( HIMAGELIST ) HB_PARHANDLE( 1 );
   hb_retni( ImageList_GetImageCount( hWndCtrl ) );
}

HB_FUNC( TOOLBAR_SETDISPINFO )
{
   PHB_ITEM pValue = hb_itemNew( NULL );
   LPTOOLTIPTEXT pDispInfo = ( LPTOOLTIPTEXT ) HB_PARHANDLE( 1 );
   hb_itemCopy( pValue, hb_param( 2, HB_IT_STRING ) );
   /* TOFIX: wrong code - have to be redesigned */
   pDispInfo->lpszText = ( LPSTR ) hb_itemGetCPtr( pValue );
   hb_itemRelease( pValue );
}

HB_FUNC( TOOLBAR_GETDISPINFOID )
{
   LPTOOLTIPTEXT pDispInfo = ( LPTOOLTIPTEXT ) hb_parnl( 1 );
   DWORD idButton = pDispInfo->hdr.idFrom;
   hb_retnl( idButton );
}

HB_FUNC( TOOLBAR_GETINFOTIP )
{
   PHB_ITEM pValue = hb_itemNew( NULL );
   LPNMTBGETINFOTIP pDispInfo = ( LPNMTBGETINFOTIP ) HB_PARHANDLE( 1 );
   hb_itemCopy( pValue, hb_param( 2, HB_IT_STRING ) );
   /* TOFIX: wrong code - have to be redesigned */
   pDispInfo->pszText = ( LPSTR ) hb_itemGetCPtr( pValue );
   hb_itemRelease( pValue );
}

HB_FUNC( TOOLBAR_GETINFOTIPID )
{
   LPNMTBGETINFOTIP pDispInfo = ( LPNMTBGETINFOTIP ) HB_PARHANDLE( 1 );
   DWORD idButton = pDispInfo->iItem;
   hb_retnl( idButton );
}

HB_FUNC( TOOLBAR_SUBMENU )
{
   LPNMTOOLBAR lpnmTB = ( LPNMTOOLBAR ) HB_PARHANDLE( 1 );
   RECT rc = { 0, 0, 0, 0 };
   TPMPARAMS tpm;
   HMENU hPopupMenu;
   HMENU hMenuLoaded;
   HWND g_hwndMain = ( HWND ) HB_PARHANDLE( 3 );
   HANDLE g_hinst = GetModuleHandle( 0 );

   SendMessage( lpnmTB->hdr.hwndFrom, TB_GETRECT,
         ( WPARAM ) lpnmTB->iItem, ( LPARAM ) & rc );

   MapWindowPoints( lpnmTB->hdr.hwndFrom, HWND_DESKTOP, ( LPPOINT ) ( void * ) &rc, 2 );

   tpm.cbSize = sizeof( TPMPARAMS );
   // tpm.rcExclude = rc;
   tpm.rcExclude.left = rc.left;
   tpm.rcExclude.top = rc.top;
   tpm.rcExclude.bottom = rc.bottom;
   tpm.rcExclude.right = rc.right;
   hMenuLoaded =
         LoadMenu( ( HINSTANCE ) g_hinst, MAKEINTRESOURCE( hb_parni( 2 ) ) );
   hPopupMenu =
         GetSubMenu( LoadMenu( ( HINSTANCE ) g_hinst,
               MAKEINTRESOURCE( hb_parni( 2 ) ) ), 0 );

   TrackPopupMenuEx( hPopupMenu,
         TPM_LEFTALIGN | TPM_LEFTBUTTON | TPM_VERTICAL,
         rc.left, rc.bottom, g_hwndMain, &tpm );
   //rc.left, rc.bottom, g_hwndMain, &tpm);

   DestroyMenu( hMenuLoaded );

}

HB_FUNC( TOOLBAR_SUBMENUEX )
{
   LPNMTOOLBAR lpnmTB = ( LPNMTOOLBAR ) HB_PARHANDLE( 1 );
   RECT rc = { 0, 0, 0, 0 };
   TPMPARAMS tpm;
   HMENU hPopupMenu = ( HMENU ) HB_PARHANDLE( 2 );
   HWND g_hwndMain = ( HWND ) HB_PARHANDLE( 3 );

   SendMessage( lpnmTB->hdr.hwndFrom, TB_GETRECT,
         ( WPARAM ) lpnmTB->iItem, ( LPARAM ) & rc );

   MapWindowPoints( lpnmTB->hdr.hwndFrom, HWND_DESKTOP, ( LPPOINT ) ( void * ) &rc, 2 );

   tpm.cbSize = sizeof( TPMPARAMS );
   //tpm.rcExclude = rc;
   tpm.rcExclude.left = rc.left;
   tpm.rcExclude.top = rc.top;
   tpm.rcExclude.bottom = rc.bottom;
   tpm.rcExclude.right = rc.right;
   TrackPopupMenuEx( hPopupMenu,
         TPM_LEFTALIGN | TPM_LEFTBUTTON | TPM_VERTICAL,
         rc.left, rc.bottom, g_hwndMain, &tpm );
   //rc.left, rc.bottom, g_hwndMain, &tpm);

}

HB_FUNC( TOOLBAR_SUBMENUEXGETID )
{

   LPNMTOOLBAR lpnmTB = ( LPNMTOOLBAR ) HB_PARHANDLE( 1 );
   hb_retnl( ( LONG ) lpnmTB->iItem );
}


HB_FUNC( CREATEPAGER )
{
   HWND hWndPanel;
   BOOL bVert = hb_parl( 8 );
   hWndPanel = CreateWindow( WC_PAGESCROLLER,   /* predefined class  */
         NULL,                  /* no window title   */
         WS_CHILD | WS_VISIBLE | bVert ? PGS_VERT : PGS_HORZ | hb_parnl( 3 ),   /* style  */
         hb_parni( 4 ), hb_parni( 5 ),  /* x, y       */
         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
         ( HMENU ) hb_parni( 2 ),       /* control ID  */
         GetModuleHandle( NULL ), NULL );

   HB_RETHANDLE( hWndPanel );

}




HB_FUNC( CREATEREBAR )
{
   ULONG ulStyle = hb_parnl( 3 );
   ULONG ulExStyle =
         ( ( !ISNIL( 8 ) ) ? hb_parnl( 8 ) : 0 ) | ( ( ulStyle & WS_BORDER ) ?
         WS_EX_CLIENTEDGE : 0 ) | WS_EX_TOOLWINDOW;
   HWND hWndCtrl = CreateWindowEx( ulExStyle,   /* extended style */
         REBARCLASSNAME,        /* predefined class  */
         NULL,                  /* title   */
         WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS | WS_CLIPCHILDREN | RBS_VARHEIGHT | CCS_NODIVIDER | ulStyle,   /* style  */
         hb_parni( 4 ), hb_parni( 5 ),  /* x, y       */
         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
         ( HMENU ) hb_parni( 2 ),       /* control ID  */
         GetModuleHandle( NULL ),
         NULL );


   HB_RETHANDLE( hWndCtrl );

}


HB_FUNC( REBARSETIMAGELIST )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   HIMAGELIST p = ( ISNUM( 2 ) ||
         ISPOINTER( 2 ) ) ? ( HIMAGELIST ) HB_PARHANDLE( 2 ) : NULL;
   REBARINFO rbi;

   memset( &rbi, '\0', sizeof( rbi ) );
   rbi.cbSize = sizeof( REBARINFO );
   rbi.fMask = ( ISNUM( 2 ) || ISPOINTER( 2 ) ) ? RBIM_IMAGELIST : 0;
   rbi.himl = ( ISNUM( 2 ) ||
         ISPOINTER( 2 ) ) ? ( HIMAGELIST ) p : ( HIMAGELIST ) NULL;
   SendMessage( hWnd, RB_SETBARINFO, 0, ( LPARAM ) & rbi );
}


static BOOL _AddBar( HWND pParent, HWND pBar, REBARBANDINFO * pRBBI )
{
   SIZE size;
   RECT rect;
   BOOL bResult;

   pRBBI->cbSize = sizeof( REBARBANDINFO );
   pRBBI->fMask |= RBBIM_CHILD | RBBIM_CHILDSIZE;
   pRBBI->hwndChild = pBar;

   GetWindowRect( pBar, &rect );

   size.cx = rect.right - rect.left;
   size.cy = rect.bottom - rect.top;

   pRBBI->cxMinChild = size.cx;
   pRBBI->cyMinChild = size.cy;
   bResult =
         SendMessage( pParent, RB_INSERTBAND, ( WPARAM ) - 1,
         ( LPARAM ) pRBBI );

   return bResult;
}

static BOOL AddBar( HWND pParent, HWND pBar, LPCTSTR pszText, HBITMAP pbmp,
      DWORD dwStyle )
{
   REBARBANDINFO rbBand;

   memset( &rbBand, '\0', sizeof( rbBand ) );

   rbBand.fMask = RBBIM_STYLE;
   rbBand.fStyle = dwStyle;
   if( pszText != NULL )
   {
      rbBand.fMask |= RBBIM_TEXT;
      rbBand.lpText = ( LPTSTR ) pszText;
   }
   if( pbmp != NULL )
   {
      rbBand.fMask |= RBBIM_BACKGROUND;
      rbBand.hbmBack = ( HBITMAP ) pbmp;
   }
   return _AddBar( pParent, pBar, &rbBand );
}

static BOOL AddBar1( HWND pParent, HWND pBar, COLORREF clrFore, COLORREF clrBack,
      LPCTSTR pszText, DWORD dwStyle )
{
   REBARBANDINFO rbBand;
   memset( &rbBand, '\0', sizeof( rbBand ) );
   rbBand.fMask = RBBIM_STYLE | RBBIM_COLORS;
   rbBand.fStyle = dwStyle;
   rbBand.clrFore = clrFore;
   rbBand.clrBack = clrBack;
   if( pszText != NULL )
   {
      rbBand.fMask |= RBBIM_TEXT;
      rbBand.lpText = ( LPTSTR ) pszText;
   }
   return _AddBar( pParent, pBar, &rbBand );
}

HB_FUNC( ADDBARBITMAP )
{
   HWND pParent = ( HWND ) HB_PARHANDLE( 1 );
   HWND pBar = ( HWND ) HB_PARHANDLE( 2 );
   void * hStr;
   LPCTSTR pszText = HB_PARSTR( 3, &hStr, NULL );
   HBITMAP pbmp = ( HBITMAP ) HB_PARHANDLE( 4 );
   DWORD dwStyle = hb_parnl( 5 );
   hb_retl( AddBar( pParent, pBar, pszText, pbmp, dwStyle ) );
   hb_strfree( hStr );
}

HB_FUNC( ADDBARCOLORS )
{
   HWND pParent = ( HWND ) HB_PARHANDLE( 1 );
   HWND pBar = ( HWND ) HB_PARHANDLE( 2 );
   COLORREF clrFore = ( COLORREF ) hb_parnl( 3 );
   COLORREF clrBack = ( COLORREF ) hb_parnl( 4 );
   void * hStr;
   LPCTSTR pszText = HB_PARSTR( 5, &hStr, NULL );
   DWORD dwStyle = hb_parnl( 6 );

   hb_retl( AddBar1( pParent, pBar, clrFore, clrBack, pszText, dwStyle ) );
   hb_strfree( hStr );
}

//Combo Box Procedure

HB_FUNC( GETCOMBOWNDPROC )
{
   hb_retnl( ( LONG ) wpOrigComboProc );
}

HB_FUNC( COMBOGETITEMRECT )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );

   int nIndex = hb_parnl( 2 );
   RECT rcItem;
   SendMessage( hWnd, LB_GETITEMRECT, nIndex, ( LONG ) ( VOID * ) & rcItem );
   hb_itemRelease( hb_itemReturn( Rect2Array( &rcItem ) ) );
}

HB_FUNC( COMBOBOXGETITEMDATA )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   int nIndex = hb_parnl( 2 );
   DWORD_PTR p;
   p = ( DWORD_PTR ) SendMessage( ( HWND ) hWnd, CB_GETITEMDATA, nIndex, 0 );
   hb_retnl( p );

}

HB_FUNC( COMBOBOXSETITEMDATA )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   int nIndex = hb_parnl( 2 );
   DWORD_PTR dwItemData = ( DWORD_PTR ) hb_parnl( 3 );
   hb_retnl( SendMessage( ( HWND ) hWnd, CB_SETITEMDATA, nIndex,
               ( LPARAM ) dwItemData ) );
}

HB_FUNC( GETLOCALEINFO )
{
   TCHAR szBuffer[10] = { 0 };
   GetLocaleInfo( LOCALE_USER_DEFAULT, LOCALE_SLIST, szBuffer,
                  HB_SIZEOFARRAY( szBuffer ) );
   HB_RETSTR( szBuffer );
}


HB_FUNC( COMBOBOXGETLBTEXT )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   int nIndex = hb_parnl( 2 );
   TCHAR lpszText[255] = { 0 };
   hb_retni( SendMessage( hWnd, CB_GETLBTEXT, nIndex,
                          ( LPARAM ) lpszText ) );
   HB_STORSTR( lpszText, 3 );
}

HB_FUNC( DEFWINDOWPROC )
{
//   WNDPROC wpProc = (WNDPROC) hb_parnl(1);
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   LONG message = hb_parnl( 2 );
   WPARAM wParam = ( WPARAM ) hb_parnl( 3 );
   LPARAM lParam = ( LPARAM ) hb_parnl( 4 );

   hb_retnl( DefWindowProc( hWnd, message, wParam, lParam ) );
}


HB_FUNC( CALLWINDOWPROC )
{
   WNDPROC wpProc = ( WNDPROC ) hb_parnl( 1 );
   HWND hWnd = ( HWND ) HB_PARHANDLE( 2 );
   LONG message = hb_parnl( 3 );
   WPARAM wParam = ( WPARAM ) hb_parnl( 4 );
   LPARAM lParam = ( LPARAM ) hb_parnl( 5 );

   hb_retnl( CallWindowProc( wpProc, hWnd, message, wParam, lParam ) );
}


HB_FUNC( BUTTONGETDLGCODE )
{
   LPARAM lParam = ( LPARAM ) HB_PARHANDLE( 1 );
   if( lParam )
   {
      MSG *pMsg = ( MSG * ) lParam;

      if( pMsg && ( pMsg->message == WM_KEYDOWN ) &&
            ( pMsg->wParam == VK_TAB ) )
      {
         // don't interfere with tab processing
         hb_retnl( 0 );
         return;
      }


   }
   hb_retnl( DLGC_WANTALLKEYS );        // we want all keys except TAB key
}


HB_FUNC( GETDLGMESSAGE )
{
   LPARAM lParam = ( LPARAM ) HB_PARHANDLE( 1 );
   if( lParam )
   {
      MSG *pMsg = ( MSG * ) lParam;

      if( pMsg )
      {
         hb_retnl( pMsg->message );
         return;
      }
   }
   hb_retnl( 0 );
}

HB_FUNC( HANDLETOPTR )
{
   DWORD h = hb_parnl( 1 );
#ifdef HWG_USE_POINTER_ITEM
   hb_retptr( ULongToPtr( h ) );
   return;
#endif
   hb_retnl( ( LONG ) h );
}


HB_FUNC( TABITEMPOS )
{
   RECT pRect;
   TabCtrl_GetItemRect( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ), &pRect );
   hb_itemRelease( hb_itemReturn( Rect2Array( &pRect ) ) );
}

HB_FUNC( GETTABNAME )
{
   TC_ITEM tie;
   TCHAR d[255] = { 0 };

   tie.mask = TCIF_TEXT;
   tie.cchTextMax = HB_SIZEOFARRAY( d ) - 1;
   tie.pszText = d;
   TabCtrl_GetItem( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ) - 1,
                    ( LPTCITEM ) &tie );
   HB_RETSTR( tie.pszText );
}


#ifdef __XHARBOUR__

HB_FUNC( XHB_BITTEST )
{
   LPARAM l = ( LPARAM ) hb_parnl( 1 );
   hb_retl( l & 0x40000000 );
}

#endif
