/*
 * $Id: control.c,v 1.34 2005-11-01 17:48:38 lf_sfnet Exp $
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

#ifdef __EXPORT__
   #define HB_NO_DEFAULT_API_MACROS
   #define HB_NO_DEFAULT_STACK_MACROS
#endif

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include "hbdate.h"
#include "guilib.h"

#define TTS_BALLOON             0x40 // added by MAG

// LRESULT CALLBACK OwnBtnProc (HWND, UINT, WPARAM, LPARAM) ;
LRESULT CALLBACK WinCtrlProc (HWND, UINT, WPARAM, LPARAM);
LRESULT APIENTRY SplitterProc( HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam );
LRESULT APIENTRY EditSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam );
LRESULT APIENTRY TrackSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam );
LRESULT APIENTRY TabSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam );
void CALLBACK TimerProc (HWND, UINT, UINT, DWORD) ;

extern PHB_DYNS pSym_onEvent;

static HWND hWndTT = 0;
static BOOL lInitCmnCtrl = 0;
static BOOL lToolTipBalloon = FALSE; // added by MAG
static WNDPROC wpOrigEditProc, wpOrigTrackProc, wpOrigTabProc;

HB_FUNC( HWG_INITCOMMONCONTROLSEX )
{
   if( !lInitCmnCtrl )
   {
      INITCOMMONCONTROLSEX  i;

      i.dwSize = sizeof( INITCOMMONCONTROLSEX );
      i.dwICC = ICC_DATE_CLASSES | ICC_INTERNET_CLASSES;
      InitCommonControlsEx( &i );
      lInitCmnCtrl = 1;
   }
}

HB_FUNC( MOVEWINDOW )
{
   RECT rc;

   GetWindowRect( (HWND) hb_parnl( 1 ), &rc );
   MoveWindow(
    (HWND) hb_parnl( 1 ),                         // handle of window
    (ISNIL(2))? rc.left : hb_parni( 2 ),          // horizontal position
    (ISNIL(3))? rc.top : hb_parni( 3 ),           // vertical position
    (ISNIL(4))? rc.right-rc.left : hb_parni( 4 ), // width
    (ISNIL(5))? rc.bottom-rc.top : hb_parni( 5 ), // height
    (hb_pcount()<6)? TRUE:hb_parl(6) 	// repaint flag
   );
}

/*
   CreateProgressBar( hParentWindow, nRange )
*/
HB_FUNC( CREATEPROGRESSBAR )
{
   HWND hPBar, hParentWindow = (HWND) hb_parnl(1);
   RECT rcClient;
   int cyVScroll = GetSystemMetrics( SM_CYVSCROLL );
   int x1, y1, nwidth, nheight;

   if( hb_pcount() > 2 )
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

   hPBar = CreateWindowEx( 0, PROGRESS_CLASS, (LPSTR) NULL,
              WS_CHILD | WS_VISIBLE,    /* style  */
              x1,                       /* x */
              y1,                       /* y */
              nwidth, nheight,          /* nWidth, nHeight */
              hParentWindow,            /* parent window    */
              (HMENU) NULL,
              GetModuleHandle( NULL ), NULL );

   SendMessage( hPBar, PBM_SETRANGE, 0, MAKELPARAM( 0, hb_parni( 2 ) ) );
   SendMessage(hPBar, PBM_SETSTEP, (WPARAM) 1, 0);

   hb_retnl( (LONG) hPBar );
}

/*
   UpdateProgressBar( hPBar )
*/
HB_FUNC( UPDATEPROGRESSBAR )
{
   SendMessage( (HWND) hb_parnl(1), PBM_STEPIT, 0, 0 );
}  

HB_FUNC( SETPROGRESSBAR )
{
   SendMessage( (HWND) hb_parnl(1), PBM_SETPOS, (WPARAM) hb_parni(2), 0 );
}

/*
   CreatePanel( hParentWindow, nPanelControlID, nStyle, x1, y1, nWidth, nHeight )
*/
HB_FUNC( CREATEPANEL )
{
   HWND hWndPanel;
   hWndPanel = CreateWindow( 
                 "PANEL",                      /* predefined class  */
                 NULL,                        /* no window title   */
                 WS_CHILD | WS_VISIBLE | SS_GRAYRECT | SS_OWNERDRAW | CCS_TOP | hb_parnl(3),    /* style  */
                 hb_parni(4), hb_parni(5),    /* x, y       */
                 hb_parni(6), hb_parni(7),    /* nWidth, nHeight */
                 (HWND) hb_parnl(1),           /* parent window    */ 
                 (HMENU) hb_parni(2),          /* control ID  */
                 GetModuleHandle( NULL ), 
                 NULL);

   hb_retnl( (LONG) hWndPanel );
   // SS_ETCHEDHORZ
}

/*
   CreateOwnBtn( hParentWIndow, nBtnControlID, x, y, nWidth, nHeight )
*/
HB_FUNC( CREATEOWNBTN )
{
   HWND hWndPanel;
   hWndPanel = CreateWindow( 
                 "OWNBTN",                    /* predefined class  */
                 NULL,                        /* no window title   */
                 WS_CHILD | WS_VISIBLE | SS_GRAYRECT | SS_OWNERDRAW,  /* style  */
                 hb_parni(3), hb_parni(4),           /* x, y       */
                 hb_parni(5), hb_parni(6),      /* nWidth, nHeight */
                 (HWND) hb_parnl(1),           /* parent window    */ 
                 (HMENU) hb_parni(2),          /* control ID  */ 
                 GetModuleHandle( NULL ), 
                 NULL);

   hb_retnl( (LONG) hWndPanel );
}

/*
   CreateStatic( hParentWyndow, nControlID, nStyle, x, y, nWidth, nHeight )
*/
HB_FUNC( CREATESTATIC )
{
   ULONG ulStyle = hb_parnl(3);
   ULONG ulExStyle = ( ( !ISNIL(8) )? hb_parnl(8):0 ) | ( (ulStyle&WS_BORDER)? WS_EX_CLIENTEDGE:0 );
   HWND hWndCtrl = CreateWindowEx( 
                 ulExStyle,                    /* extended style */
                 "STATIC",                     /* predefined class  */
                 NULL,                         /* title   */
                 WS_CHILD | WS_VISIBLE | ulStyle, /* style  */
                 hb_parni(4), hb_parni(5),      /* x, y       */
                 hb_parni(6), hb_parni(7),      /* nWidth, nHeight */
                 (HWND) hb_parnl(1),            /* parent window    */ 
                 (HMENU) hb_parni(2),           /* control ID  */
                 GetModuleHandle( NULL ),
                 NULL);

   /*
   if( hb_pcount() > 7 )
      SendMessage( hWndCtrl, WM_SETTEXT, 0, (LPARAM) hb_parc(8) );
   */

   hb_retnl( (LONG) hWndCtrl );

}

/*
   CreateButton( hParentWIndow, nButtonID, nStyle, x, y, nWidth, nHeight, 
               cCaption )
*/
HB_FUNC( CREATEBUTTON )
{
   HWND hBtn =
         CreateWindow( 
                 "BUTTON",                    /* predefined class  */
                 hb_parc(8),                  /* button text   */
                 WS_CHILD | WS_VISIBLE | hb_parnl(3),    /* style  */
                 hb_parni(4), hb_parni(5),           /* x, y       */
                 hb_parni(6), hb_parni(7),      /* nWidth, nHeight */
                 (HWND) hb_parnl(1),           /* parent window    */
                 (HMENU) hb_parni(2),          /* button       ID  */ 
                 GetModuleHandle( NULL ), 
                 NULL);

   hb_retnl( (LONG) hBtn );

}

/*
   CreateEdit( hParentWIndow, nEditControlID, nStyle, x, y, nWidth, nHeight,
               cInitialString )
*/
HB_FUNC( CREATEEDIT )
{
   ULONG ulStyle = hb_parnl(3);
   ULONG ulStyleEx = (ulStyle&WS_BORDER)? WS_EX_CLIENTEDGE:0;
   HWND  hWndEdit;

   if( ( ulStyle & WS_BORDER ) && ( ulStyle & WS_DLGFRAME ) )
      ulStyle &= ~WS_BORDER;
   hWndEdit =  CreateWindowEx( 
                 ulStyleEx,
                 "EDIT",                     
                 NULL,                        
                 WS_CHILD | WS_VISIBLE | ulStyle,
                 hb_parni(4), hb_parni(5),     
                 hb_parni(6), hb_parni(7),     
                 (HWND) hb_parnl(1),           
                 (HMENU) hb_parni(2),          
                 GetModuleHandle( NULL ), 
                 NULL);

   if( hb_pcount() > 7 )
      SendMessage( hWndEdit, WM_SETTEXT, 0, (LPARAM) hb_parc(8) );

   hb_retnl( (LONG) hWndEdit );

}

/*
   CreateCombo( hParentWIndow, nComboID, nStyle, x, y, nWidth, nHeight,
               cInitialString )
*/
HB_FUNC( CREATECOMBO )
{
   HWND hCombo =
         CreateWindow(
                 "COMBOBOX",                  /* predefined class  */
                 "",                                        /*   */
                 WS_CHILD | WS_VISIBLE | hb_parnl(3),    /* style  */
                 hb_parni(4), hb_parni(5),           /* x, y       */
                 hb_parni(6), hb_parni(7),      /* nWidth, nHeight */
                 (HWND) hb_parnl(1),           /* parent window    */
                 (HMENU) hb_parni(2),          /* combobox ID      */
                 GetModuleHandle( NULL ),
                 NULL);

   hb_retnl( (LONG) hCombo );

}


/*
   CreateBrowse( hParentWIndow, nControlID, nStyle, x, y, nWidth, nHeight,
               cTitle )
*/
HB_FUNC( CREATEBROWSE )
{
   HWND hWndBrw;
   DWORD dwStyle = hb_parnl(3);
   hWndBrw = CreateWindowEx( 
               (dwStyle & WS_BORDER )? WS_EX_CLIENTEDGE:0, /* extended style */
               "BROWSE",                                   /* predefined class */
               (hb_pcount()>7)? hb_parc(8):NULL,           /* title */
               WS_CHILD | WS_VISIBLE |
               dwStyle,                                    /* style */
               hb_parni(4), hb_parni(5),                   /* x, y  */
               hb_parni(6), hb_parni(7),                   /* nWidth, nHeight */
               (HWND) hb_parnl(1),                         /* parent window */ 
               (HMENU) hb_parni(2),                        /* control ID  */
               GetModuleHandle( NULL ), 
               NULL);

   hb_retnl( (LONG) hWndBrw );

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
   HWND hwndStatus, hwndParent = (HWND) hb_parnl( 1 ); 

    // Ensure that the common control DLL is loaded.
    InitCommonControls(); 
 
    // Create the status window. 
    hwndStatus = CreateWindowEx( 
        0,                       // style
        STATUSCLASSNAME,         // name of status window class 
        (LPCTSTR) NULL,          // no text when first created 
        SBARS_SIZEGRIP |         // includes a sizing grip 

        WS_CHILD|WS_VISIBLE|WS_OVERLAPPED|WS_CLIPSIBLINGS,    // creates a child window
        0, 0, 0, 0,              // ignores size and position 
        hwndParent,              // handle to parent window 
        (HMENU) hb_parni( 2 ),   // child window identifier
        GetModuleHandle( NULL ), // handle to application instance 
        NULL);                   // no window creation data 

    hb_retnl( (LONG) hwndStatus );
}

HB_FUNC( HWG_INITSTATUS )
{
   HWND hParent = (HWND) hb_parnl( 1 ); 
   HWND hStatus = (HWND) hb_parnl( 2 ); 
   RECT rcClient; 
   HLOCAL hloc; 
   LPINT lpParts; 
   int i, nWidth, j, nParts = hb_parni( 3 );
   PHB_ITEM pArray = hb_param( 4, HB_IT_ARRAY );

    // Allocate an array for holding the right edge coordinates. 
    hloc = LocalAlloc(LHND, sizeof(int) * nParts); 
    lpParts = (LPINT)LocalLock(hloc); 
 
    if( !pArray || hb_itemGetNI( pArray->item.asArray.value->pItems + 0 ) == 0 )
    {
       // Get the coordinates of the parent window's client area. 
       GetClientRect(hParent, &rcClient); 
       // Calculate the right edge coordinate for each part, and 
       // copy the coordinates to the array. 
       nWidth = rcClient.right / nParts; 
       for (i = 0; i < nParts; i++) { 
           lpParts[i] = nWidth; 
           nWidth += nWidth; 
       }
    }
    else
    {
       nWidth = 0;
       for (i = 0; i < nParts; i++)
       {
          j = hb_itemGetNI( pArray->item.asArray.value->pItems + i );
          if( i == nParts-1 && j == 0 )
             nWidth = -1;
          else
             nWidth += j;
          lpParts[i] = nWidth;
       }
    }

    // Tell the status window to create the window parts. 
    SendMessage( hStatus, SB_SETPARTS, (WPARAM) nParts, (LPARAM) lpParts );

    // Free the array, and return. 
    LocalUnlock(hloc); 
    LocalFree(hloc); 
}

HB_FUNC( ADDTOOLTIP ) // changed by MAG
{
   TOOLINFO ti

;
   HWND hWnd = (HWND) hb_parnl( 1 );
   int iStyle = TTS_ALWAYSTIP;

   if ( lToolTipBalloon )
   {
   	iStyle = iStyle | TTS_BALLOON;
   }

   if( !hWndTT )
      hWndTT = CreateWindow( TOOLTIPS_CLASS, (LPSTR) NULL, iStyle,
                CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
                NULL, (HMENU) NULL, GetModuleHandle( NULL ), NULL );
   if( !hWndTT )
   {
      hb_retnl( 0 );
      return;
   }
   ti.uFlags = TTF_SUBCLASS | TTF_IDISHWND;
   ti.hwnd = hWnd;
   ti.uId = (UINT) hb_parnl( 2 );
   // ti.uId = (UINT) GetDlgItem( hWnd, hb_parni( 2 ) );
   ti.hinst = GetModuleHandle( NULL );
   ti.lpszText = (LPSTR) hb_parc( 3 );

   hb_retl( SendMessage( hWndTT, TTM_ADDTOOL, 0, (LPARAM) (LPTOOLINFO) &ti) );

}

HB_FUNC( DELTOOLTIP )
{
   TOOLINFO ti;

   if( hWndTT )
   {
      ti.cbSize = sizeof(TOOLINFO);
      ti.uFlags = TTF_IDISHWND;
      ti.hwnd = (HWND) hb_parnl( 1 );
      ti.uId = (UINT) hb_parnl( 2 );
      // ti.uId = (UINT) GetDlgItem( hWnd, hb_parni( 2 ) );
      ti.hinst = GetModuleHandle( NULL );

      SendMessage( hWndTT, TTM_DELTOOL, 0, (LPARAM) (LPTOOLINFO) &ti);
   }
}

/*
HB_FUNC( SHOWTOOLTIP )
{
   MSG msg;

   msg.lParam = hb_parnl( 3 );
   msg.wParam = hb_parnl( 2 );
   msg.message = WM_MOUSEMOVE;
   msg.hwnd = (HWND) hb_parnl( 1 );
   hb_retnl( SendMessage( hWndTT, TTM_RELAYEVENT, 0, (LPARAM) (LPMSG) &msg ) );
}
*/

HB_FUNC( CREATEUPDOWNCONTROL )
{
   hb_retnl( (LONG) CreateUpDownControl( WS_CHILD|WS_BORDER|WS_VISIBLE|hb_parni(3),
     hb_parni(4),hb_parni(5),hb_parni(6),hb_parni(7),
     (HWND) hb_parnl(1), hb_parni(2), GetModuleHandle( NULL ),
     (HWND) hb_parnl(8),
     hb_parni(9), hb_parni(10), hb_parni(11) ) );
}

HB_FUNC( SETUPDOWN )
{
   SendMessage( (HWND) hb_parnl(1),UDM_SETPOS,0,hb_parnl(2) );
}

HB_FUNC( CREATEDATEPICKER )
{
   HWND hCtrl;
   LONG nStyle = ( (!ISNIL(7))? hb_parnl(7):0 ) | WS_CHILD | WS_VISIBLE | WS_TABSTOP;

   hCtrl = CreateWindowEx( 
             WS_EX_CLIENTEDGE,
             "SYSDATETIMEPICK32",
             0,
             nStyle,
             hb_parni(3), hb_parni(4),         /* x, y       */
             hb_parni(5) ,hb_parni(6),         /* nWidth, nHeight */
             (HWND) hb_parnl(1),               /* parent window    */ 
             (HMENU)hb_parni(2),               /* control ID  */ 
             GetModuleHandle(NULL), NULL );

   hb_retnl ( (LONG) hCtrl );
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

      sysTime.wYear = (unsigned short) lYear;
      sysTime.wMonth = (unsigned short) lMonth;
      sysTime.wDay = (unsigned short) lDay;
      sysTime.wDayOfWeek = 0;
      sysTime.wHour = 0;
      sysTime.wMinute = 0;
      sysTime.wSecond = 0;
      sysTime.wMilliseconds = 0;
	
      SendMessage( (HWND) hb_parnl (1), DTM_SETSYSTEMTIME,GDT_VALID, (LPARAM) &sysTime);
   }
}

HB_FUNC( GETDATEPICKER )
{
   SYSTEMTIME st

;
   char szDate[9];

   SendMessage( (HWND) hb_parnl (1), DTM_GETSYSTEMTIME, 0, (LPARAM) &st);

   hb_dateStrPut( szDate, st.wYear, st.wMonth, st.wDay );
   szDate[8] = 0;
   hb_retds( szDate );
}

HB_FUNC( CREATETABCONTROL )
{
   HWND hTab;

   hTab = CreateWindow( WC_TABCONTROL , 
                 NULL ,
                 WS_CHILD | WS_VISIBLE | hb_parnl(3),  /* style  */
                 hb_parni(4), hb_parni(5) , 
                 hb_parni(6), hb_parni(7) ,
                 (HWND) hb_parnl(1),           /* parent window    */ 
                 (HMENU) hb_parni(2),          /* control ID  */
                 GetModuleHandle( NULL ), 
                 NULL);

   hb_retnl( (LONG) hTab );

}

HB_FUNC( INITTABCONTROL )
{
   HWND hTab = (HWND) hb_parnl(1);
   PHB_ITEM pArr = hb_param( 2, HB_IT_ARRAY );
   int iItems = hb_parnl(3) ;
   TC_ITEM tie

;
   int i, nTabs = pArr->item.asArray.value->ulLen;

   tie.mask = TCIF_TEXT | TCIF_IMAGE; 
   tie.iImage = iItems == 0 ? -1 : 0 ;
   for( i = 0; i < nTabs; i++) 
   {
      tie.pszText = hb_itemGetCPtr( pArr->item.asArray.value->pItems + i );
      if( TabCtrl_InsertItem( hTab, i, &tie ) == -1 )
      {
         DestroyWindow(hTab);
         hTab = NULL; 
      }
      if (tie.iImage > -1)
          tie.iImage++;
   } 
}

HB_FUNC( ADDTAB )
{
   TC_ITEM tie

;

   tie.mask = TCIF_TEXT | TCIF_IMAGE; 
   tie.iImage = -1;
   tie.pszText = hb_parc(3);
   TabCtrl_InsertItem( (HWND) hb_parnl(1), hb_parni(2), &tie );
}

HB_FUNC( DELETETAB )
{
   TabCtrl_DeleteItem( (HWND) hb_parnl(1), hb_parni(2) );
}


HB_FUNC( GETCURRENTTAB )
{
   hb_retni( TabCtrl_GetCurSel( (HWND) hb_parnl(1) ) + 1 );
}

HB_FUNC( SETTABSIZE )
{
   SendMessage( (HWND)hb_parnl(1), TCM_SETITEMSIZE, 0, MAKELPARAM( hb_parni(2),hb_parni(3) ) );
}

HB_FUNC( SETTABNAME )
{
   TC_ITEM tie

;

   tie.mask = TCIF_TEXT;
   tie.pszText = hb_parc(3);

   TabCtrl_SetItem( (HWND) hb_parnl(1), hb_parni(2), &tie );

}

HB_FUNC( TAB_HITTEST )
{
   TC_HITTESTINFO ht;
   HWND hTab = (HWND)hb_parnl(1);
   int res;

   if( hb_pcount() > 1 && ISNUM(2) && ISNUM(3) )
   {
      ht.pt.x = hb_parni( 2 );
      ht.pt.y = hb_parni( 3 );
   }
   else
   {
      GetCursorPos( &(ht.pt) );
      ScreenToClient( hTab,&(ht.pt) );
   }

   res = (int) SendMessage( hTab, TCM_HITTEST, 0, (LPARAM)&ht );

   hb_storni( ht.flags,4 );
   hb_retni( res );

}

HB_FUNC( CREATETREE )
{
   HWND hCtrl;

   hCtrl = CreateWindowEx( 
             WS_EX_CLIENTEDGE,
             WC_TREEVIEW,
             0,
             WS_CHILD | WS_VISIBLE | WS_TABSTOP | hb_parnl(3),
             hb_parni(4), hb_parni(5),         /* x, y       */
             hb_parni(6) ,hb_parni(7),         /* nWidth, nHeight */
             (HWND) hb_parnl(1),               /* parent window    */ 
             (HMENU)hb_parni(2),               /* control ID  */ 
             GetModuleHandle(NULL), NULL );

   if( !ISNIL(8) )
      SendMessage( hCtrl, TVM_SETTEXTCOLOR, 0, (LPARAM)(hb_parnl(8)) );
   if( !ISNIL(9) )
      SendMessage( hCtrl, TVM_SETBKCOLOR, 0, (LPARAM)(hb_parnl(9)) );

   hb_retnl ( (LONG) hCtrl );
}

HB_FUNC( TREEADDNODE )
{

   TV_ITEM tvi

;
   TV_INSERTSTRUCT is

;
   int nPos = hb_parni(5);
   PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT );

   tvi.mask    = TVIF_TEXT | TVIF_PARAM;
   tvi.pszText = hb_parc(6);
   tvi.lParam  = (LPARAM)( hb_itemNew( pObject ) );
   if( hb_pcount() > 6 && !ISNIL(7) )
   {
      tvi.iImage = hb_parni(7);
      tvi.mask |= TVIF_IMAGE;
      if( hb_pcount() > 7 && !ISNIL(8) )
      {
         tvi.iSelectedImage = hb_parni(8);
         tvi.mask |= TVIF_SELECTEDIMAGE;
      }
   }

#if !defined(__BORLANDC__)
   is.item   = tvi;
#else
   is.DUMMYUNIONNAME.item = tvi;
#endif

   is.hParent = ( ISNIL(3) ? NULL : (HTREEITEM) hb_parnl(3) );
   if( nPos==0 )
      is.hInsertAfter = (HTREEITEM)hb_parnl(4);
   else if( nPos == 1 )
      is.hInsertAfter = TVI_FIRST;
   else if( nPos == 2 )
      is.hInsertAfter = TVI_LAST;

   hb_retnl( (LONG) 
         SendMessage( (HWND)hb_parnl(2), TVM_INSERTITEM, 0, (LPARAM)(&is) ) );

   if( tvi.mask & TVIF_IMAGE )
      DeleteObject( (HGDIOBJ)tvi.iImage );
   if( tvi.mask & TVIF_SELECTEDIMAGE )
      DeleteObject( (HGDIOBJ)tvi.iSelectedImage );

}

/*
HB_FUNC( TREEDELNODE )
{

   hb_parl( TreeView_DeleteItem( (HWND)hb_parnl(1), (HTREEITEM)hb_parnl(2) ) );
}

HB_FUNC( TREEDELALLNODES )
{

   TreeView_DeleteAllItems( (HWND)hb_parnl(1) );
}
*/

HB_FUNC( TREEGETSELECTED )
{
   TV_ITEM TreeItem;

   memset( &TreeItem, 0, sizeof(TV_ITEM) );
   TreeItem.mask = TVIF_HANDLE | TVIF_PARAM;
   TreeItem.hItem = TreeView_GetSelection( (HWND)hb_parnl(1) );

   if( TreeItem.hItem )
   {
      PHB_ITEM oNode;  // = hb_itemNew( NULL );
      SendMessage( (HWND)hb_parnl(1), TVM_GETITEM, 0, (LPARAM)(&TreeItem) );
      oNode = (PHB_ITEM)TreeItem.lParam;
      hb_itemReturn( oNode );
   }
}

/*
HB_FUNC( TREENODEHASCHILDREN )
{
	
   TV_ITEM TreeItem;

   memset( &TreeItem, 0, sizeof(TV_ITEM) );
   TreeItem.mask = TVIF_HANDLE | TVIF_CHILDREN;
   TreeItem.hItem = (HTREEITEM) hb_parnl(2);
  
   SendMessage( (HWND)hb_parnl(1), TVM_GETITEM, 0, (LPARAM)(&TreeItem) );
   hb_retni( TreeItem.cChildren );	
}

*/

HB_FUNC( TREEGETNODETEXT )
{
	
   TV_ITEM TreeItem;
   char ItemText[256];

   memset( &TreeItem, 0, sizeof(TV_ITEM) );
   TreeItem.mask = TVIF_HANDLE | TVIF_TEXT;
   TreeItem.hItem = (HTREEITEM) hb_parnl(2);
   TreeItem.pszText = ItemText;
   TreeItem.cchTextMax = 256;
  
   SendMessage( (HWND)hb_parnl(1), TVM_GETITEM, 0, (LPARAM)(&TreeItem) );
   hb_retc ( TreeItem.pszText );
}

#define TREE_SETITEM_TEXT       1

HB_FUNC( TREESETITEM )
{

   TV_ITEM TreeItem;
   int iType = hb_parni( 3 );

   memset( &TreeItem, 0, sizeof(TV_ITEM) );
   TreeItem.mask = TVIF_HANDLE;
   TreeItem.hItem = (HTREEITEM)hb_parnl(2);

   if( iType == TREE_SETITEM_TEXT )
   {
      TreeItem.mask |= TVIF_TEXT;
      TreeItem.pszText = hb_parc(4);
   }

   SendMessage( (HWND)hb_parnl(1), TVM_SETITEM, 0, (LPARAM)(&TreeItem) );
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
      hb_retnl( (LONG) (((NM_TREEVIEW *) hb_parnl(1))->itemNew.hItem) );

   if( iType == TREE_GETNOTIFY_ACTION )
      hb_retnl( (LONG) (((NM_TREEVIEW *) hb_parnl(1))->action) );

   else if( iType == TREE_GETNOTIFY_PARAM || iType == TREE_GETNOTIFY_EDITPARAM )
   {
      PHB_ITEM oNode ;  // = hb_itemNew( NULL );
      if( iType == TREE_GETNOTIFY_EDITPARAM )
         oNode = (PHB_ITEM)(((TV_DISPINFO *) hb_parnl(1))->item.lParam);
      else
         oNode = (PHB_ITEM)(((NM_TREEVIEW *) hb_parnl(1))->itemNew.lParam);

      hb_itemReturn( oNode );

   }
   else if( iType == TREE_GETNOTIFY_EDIT )
   {
      TV_DISPINFO * tv;
      tv = (TV_DISPINFO *) hb_parnl(1);
      if( tv->item.pszText )
      {
         hb_retc( (char*)tv->item.pszText );
      }
      else
         hb_retc( "" );
   }
}

/*
 * Tree_Hittest( hTree, x, y ) --> oNode
 */
HB_FUNC( TREE_HITTEST )
{
   TV_HITTESTINFO ht;
   HWND hTree = (HWND)hb_parnl(1);

   if( hb_pcount() > 1 && ISNUM(2) && ISNUM(3) )
   {
      ht.pt.x = hb_parni( 2 );
      ht.pt.y = hb_parni( 3 );
   }
   else
   {
      GetCursorPos( &(ht.pt) );
      ScreenToClient( hTree,&(ht.pt) );
   }

   SendMessage( hTree, TVM_HITTEST, 0, (LPARAM)&ht );

   if( ht.hItem )
   {
      PHB_ITEM oNode ; // = hb_itemNew( NULL );
      TV_ITEM TreeItem;

      memset( &TreeItem, 0, sizeof(TV_ITEM) );
      TreeItem.mask = TVIF_HANDLE | TVIF_PARAM;
      TreeItem.hItem = ht.hItem;

      SendMessage( hTree, TVM_GETITEM, 0, (LPARAM)(&TreeItem) );
      oNode = (PHB_ITEM)TreeItem.lParam;
      hb_itemReturn( oNode );
      if( hb_pcount() > 3 )
         hb_storni( (int) ht.flags,4 );
   }
   else
      hb_ret();
}

HB_FUNC( TREE_RELEASENODE )
{

   TV_ITEM TreeItem;

   memset( &TreeItem, 0, sizeof(TV_ITEM) );
   TreeItem.mask = TVIF_HANDLE | TVIF_PARAM;
   TreeItem.hItem = (HTREEITEM)hb_parnl(2);

   if( TreeItem.hItem )
   {
      SendMessage( (HWND)hb_parnl(1), TVM_GETITEM, 0, (LPARAM)(&TreeItem) );
      hb_itemRelease( (PHB_ITEM)TreeItem.lParam );
      TreeItem.lParam = 0;
      SendMessage( (HWND)hb_parnl(1), TVM_SETITEM, 0, (LPARAM)(&TreeItem) );
   }

}

/*
 * CreateImagelist( array, cx, cy, nGrow, flags )
*/
HB_FUNC( CREATEIMAGELIST )
{
   PHB_ITEM pArray = hb_param( 1, HB_IT_ARRAY );
   UINT flags = ( ISNIL(5) )? ILC_COLOR : hb_parni(5);
   HIMAGELIST himl;
   ULONG ul, ulLen = pArray->item.asArray.value->ulLen;
   HBITMAP hbmp;

   himl = ImageList_Create( hb_parni(2), hb_parni(3), flags, 
                   ulLen, hb_parni(4) );

   for( ul=0; ul<ulLen; ul++ )
   {
      hbmp = (HBITMAP)hb_itemGetNL( pArray->item.asArray.value->pItems + ul );
      ImageList_Add( himl, hbmp, (HBITMAP) NULL );
      DeleteObject(hbmp);
   }

   hb_retnl( (LONG) himl );

}

HB_FUNC( IMAGELIST_ADD )
{
   hb_retnl( ImageList_Add( (HIMAGELIST)hb_parnl(1), (HBITMAP)hb_parnl(2), (HBITMAP) NULL ) );
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
   SetTimer( (HWND) hb_parnl(1), (UINT) hb_parni(2), (UINT) hb_parni(3),
             hb_pcount() == 3 ? (TIMERPROC) TimerProc : (TIMERPROC) NULL );
}

/*
 *  KillTimer( hWnd, idTimer )
 */

HB_FUNC( KILLTIMER )
{
   hb_retl( KillTimer( (HWND) hb_parnl(1), (UINT) hb_parni(2) ) );
}

HB_FUNC( GETPARENT )
{
   hb_retnl( (LONG) GetParent( (HWND) hb_parnl( 1 ) ) );
}

HB_FUNC( LOADCURSOR )
{
   if( ISCHAR(1) )
      hb_retnl( (LONG) LoadCursor( GetModuleHandle( NULL ), hb_parc( 1 )  ) );
   else
      hb_retnl( (LONG) LoadCursor( NULL, MAKEINTRESOURCE( hb_parnl( 1 ) ) ) );
}

HB_FUNC( HWG_SETCURSOR )
{
   hb_retnl( (LONG) SetCursor( (HCURSOR) hb_parnl( 1 ) ) );
}

HB_FUNC( GETTOOLTIPHANDLE ) // added by MAG
{
   hb_retnl( (LONG) hWndTT );
}

HB_FUNC( SETTOOLTIPBALLOON ) // added by MAG
{
   if( hb_parl( 1 ) )
   {
   	lToolTipBalloon = TRUE;
   }
   else
   {
   	lToolTipBalloon = FALSE;
   }
}

HB_FUNC( GETTOOLTIPBALLOON ) // added by MAG
{
   hb_retl( lToolTipBalloon );
}

HB_FUNC( HWG_REGPANEL )
{

   static TCHAR szAppName[] = TEXT ( "PANEL" );
   static BOOL  bRegistered = 0;

   if( !bRegistered )
   {
      WNDCLASS     wndclass 

;
      wndclass.style = CS_OWNDC | CS_VREDRAW | CS_HREDRAW | CS_DBLCLKS;
      wndclass.lpfnWndProc   = DefWindowProc ;
      wndclass.cbClsExtra    = 0 ;
      wndclass.cbWndExtra    = 0 ;
      wndclass.hInstance     = GetModuleHandle( NULL );
      wndclass.hIcon         = NULL;
      wndclass.hCursor       = LoadCursor (NULL, IDC_ARROW) ;
      wndclass.hbrBackground = (HBRUSH)( COLOR_3DFACE+1 );
      wndclass.lpszMenuName  = NULL;
      wndclass.lpszClassName = szAppName ;

      RegisterClass (&wndclass);
      bRegistered = 1;     
   }
}

HB_FUNC( HWG_REGOWNBTN )
{

   static TCHAR szAppName[] = TEXT ( "OWNBTN" );
   static BOOL  bRegistered = 0;
   WNDCLASS     wndclass 

;

   if( !bRegistered )
   {
      wndclass.style = CS_OWNDC | CS_VREDRAW | CS_HREDRAW | CS_DBLCLKS;
      wndclass.lpfnWndProc   = WinCtrlProc;
      wndclass.cbClsExtra    = 0 ;
      wndclass.cbWndExtra    = 0 ;
      wndclass.hInstance     = GetModuleHandle( NULL );
      wndclass.hIcon         = NULL;
      wndclass.hCursor       = LoadCursor (NULL, IDC_ARROW) ;
      wndclass.hbrBackground = (HBRUSH)( COLOR_3DFACE+1 );
      wndclass.lpszMenuName  = NULL;
      wndclass.lpszClassName = szAppName ;

      RegisterClass (&wndclass);
      bRegistered = 1;
   }
}

HB_FUNC( HWG_REGBROWSE )
{

   static TCHAR szAppName[] = TEXT ( "BROWSE" );
   static BOOL  bRegistered = 0;
   WNDCLASS     wndclass 

;

   if( !bRegistered )
   {
      wndclass.style = CS_OWNDC | CS_VREDRAW | CS_HREDRAW | CS_DBLCLKS;
      wndclass.lpfnWndProc   = WinCtrlProc;
      wndclass.cbClsExtra    = 0 ;
      wndclass.cbWndExtra    = 0 ;
      wndclass.hInstance     = GetModuleHandle( NULL );
      // wndclass.hIcon         = LoadIcon (NULL, IDI_APPLICATION) ;
      wndclass.hIcon         = NULL;
      wndclass.hCursor       = LoadCursor (NULL, IDC_ARROW) ;
      wndclass.hbrBackground = (HBRUSH)( COLOR_WINDOW+1 );
      wndclass.lpszMenuName  = NULL;
      wndclass.lpszClassName = szAppName ;

      RegisterClass (&wndclass);
      bRegistered = 1;
   }
}

void CALLBACK TimerProc( HWND hWnd, UINT message, UINT idTimer, DWORD dwTime )
{

   PHB_DYNS pSymTest;
   HB_SYMBOL_UNUSED( message );
   if( ( pSymTest = hb_dynsymFind( "TIMERPROC" ) ) != NULL )
   {
      hb_vmPushSymbol( pSymTest->pSymbol );
      hb_vmPushNil();                   /* places NIL at self */
      hb_vmPushLong( (LONG ) hWnd );    /* pushes parameters on to the hvm stack */
      hb_vmPushLong( (LONG ) idTimer );
      hb_vmPushLong( (LONG ) dwTime );
      hb_vmDo( 3 );  /* where iArgCount is the number of pushed parameters */
    }
}

BOOL RegisterWinCtrl(void)  // Added by jamaj - Used by WinCtrl
{

   static TCHAR szAppName[] = TEXT ( "WINCTRL" );
   WNDCLASS     wndclass 

;

   wndclass.style = CS_OWNDC | CS_VREDRAW | CS_HREDRAW | CS_DBLCLKS;
   wndclass.lpfnWndProc   = WinCtrlProc ;
   wndclass.cbClsExtra    = 0 ;
   wndclass.cbWndExtra    = 0 ;
   wndclass.hInstance     = GetModuleHandle( NULL );
   wndclass.hCursor       = LoadCursor (NULL, IDC_ARROW) ;
   wndclass.hbrBackground = (HBRUSH)( COLOR_3DFACE+1 );
   wndclass.lpszMenuName  = NULL;
   wndclass.lpszClassName = szAppName ;

   return RegisterClass (&wndclass);
}

HB_FUNC( HWG_INITWINCTRL )
{
   SetWindowLong( (HWND) hb_parnl(1),
                                 GWL_WNDPROC, (LONG) WinCtrlProc );
}

LRESULT CALLBACK WinCtrlProc( HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( pSym_onEvent->pSymbol );
      hb_vmPush( pObject );
      hb_vmPushLong( (LONG ) message );
      hb_vmPushLong( (LONG ) wParam );
      hb_vmPushLong( (LONG ) lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return( DefWindowProc( hWnd, message, wParam, lParam ) );
      else
         return res;
   }
   else
      return( DefWindowProc( hWnd, message, wParam, lParam ) );
}

HB_FUNC( HWG_INITEDITPROC )
{
   wpOrigEditProc = (WNDPROC) SetWindowLong( (HWND) hb_parnl(1),
                                 GWL_WNDPROC, (LONG) EditSubclassProc );
}

LRESULT APIENTRY EditSubclassProc( HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( pSym_onEvent->pSymbol );
      hb_vmPush( pObject );
      hb_vmPushLong( (LONG ) message );
      hb_vmPushLong( (LONG ) wParam );
      hb_vmPushLong( (LONG ) lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return( CallWindowProc( wpOrigEditProc, hWnd, message, wParam, lParam ) );
      else
         return res;
   }
   else
      return( CallWindowProc( wpOrigEditProc, hWnd, message, wParam, lParam ) );
}

HB_FUNC( HWG_INITTRACKPROC )
{
   wpOrigTrackProc = (WNDPROC) SetWindowLong( (HWND) hb_parnl(1),
                                 GWL_WNDPROC, (LONG) TrackSubclassProc );
}

LRESULT APIENTRY TrackSubclassProc( HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( pSym_onEvent->pSymbol );
      hb_vmPush( pObject );
      hb_vmPushLong( (LONG ) message );
      hb_vmPushLong( (LONG ) wParam );
      hb_vmPushLong( (LONG ) lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return( CallWindowProc( wpOrigTrackProc, hWnd, message, wParam, lParam ) );
      else
         return res;
   }
   else
      return( CallWindowProc( wpOrigTrackProc, hWnd, message, wParam, lParam ) );
}

HB_FUNC( HWG_INITTABPROC )
{
   wpOrigTabProc = (WNDPROC) SetWindowLong( (HWND) hb_parnl(1),
                                 GWL_WNDPROC, (LONG) TabSubclassProc );
}

LRESULT APIENTRY TabSubclassProc( HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( pSym_onEvent->pSymbol );
      hb_vmPush( pObject );
      hb_vmPushLong( (LONG ) message );
      hb_vmPushLong( (LONG ) wParam );
      hb_vmPushLong( (LONG ) lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return( CallWindowProc( wpOrigTabProc, hWnd, message, wParam, lParam ) );
      else
         return res;
   }
   else
      return( CallWindowProc( wpOrigTabProc, hWnd, message, wParam, lParam ) );
}
