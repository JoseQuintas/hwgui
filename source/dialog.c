/*
 *$Id: dialog.c,v 1.17 2005-10-26 01:22:33 lculik Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level dialog boxes functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#define HB_OS_WIN_32_USED

#define _WIN32_WINNT 0x0400
// #define OEMRESOURCE
#include <windows.h>

#if defined(__MINGW32__) || defined(__WATCOMC__)
   #include <prsht.h>
#endif

#ifdef __EXPORT__
   #define HB_NO_DEFAULT_API_MACROS
   #define HB_NO_DEFAULT_STACK_MACROS
#endif


#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include "item.api"
#include "guilib.h"

#define  WM_PSPNOTIFY         WM_USER+1010

LRESULT WINAPI ModalDlgProc( HWND, UINT, WPARAM, LPARAM );
LRESULT CALLBACK DlgProc (HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK PSPProc (HWND, UINT, WPARAM, LPARAM);

extern void SetWindowObject( HWND hWnd, PHB_ITEM pObject );
extern PHB_ITEM GetObjectVar( PHB_ITEM pObject, char* varname );
extern void SetObjectVar( PHB_ITEM pObject, char* varname, PHB_ITEM pValue );

extern HMODULE hModule ;
extern PHB_DYNS pSym_onEvent;

#define	WND_DLG_RESOURCE       10
#define	WND_DLG_NORESOURCE     11

HWND * aDialogs = NULL;
// HWND aDialogs[ 20 ];
static int nDialogs = 0;
int iDialogs = 0;

HB_FUNC( HWG_DIALOGBOX )
{
   PHB_ITEM pObject = hb_param( 2, HB_IT_OBJECT );
   PHB_ITEM pData = GetObjectVar( pObject, "XRESOURCEID" );

   DialogBoxParam( hModule, ( HB_IS_STRING( pData ) ? hb_itemGetCPtr( pData ) : MAKEINTRESOURCE( hb_itemGetNL( pData ) ) ), 
         (HWND) hb_parnl( 1 ), (DLGPROC) ModalDlgProc, (LPARAM) pObject );
}

/*  Creates modeless dialog
    CreateDialog( hParentWindow, aDialog )
*/
HB_FUNC( HWG_CREATEDIALOG )
{
   PHB_ITEM pObject = hb_param( 2, HB_IT_OBJECT );
   HWND hDlg;
   PHB_ITEM pData = GetObjectVar( pObject, "XRESOURCEID" );

   hDlg = CreateDialogParam( hModule, ( HB_IS_STRING( pData ) ? hb_itemGetCPtr( pData ) : MAKEINTRESOURCE( hb_itemGetNL( pData ) ) ), (HWND) hb_parnl( 1 ), 
      (DLGPROC) DlgProc, (LPARAM) pObject );

   ShowWindow( hDlg, SW_SHOW);
   hb_retnl( (LONG) hDlg );
}

HB_FUNC( HWG_ENDDIALOG )
{
   EndDialog( (HWND) hb_parnl( 1 ), TRUE );
}

HB_FUNC( GETDLGITEM )
{
   HWND hWnd = GetDlgItem(
                 (HWND) hb_parnl( 1 ),	// handle of dialog box
                 hb_parni( 2 )	        // identifier of control
               );
   hb_retnl( (LONG) hWnd );
}

HB_FUNC( GETDLGCTRLID )
{
   hb_retni( GetDlgCtrlID( (HWND) hb_parnl( 1 ) ) );
}

HB_FUNC( SETDLGITEMTEXT )
{
    SetDlgItemText(
       (HWND) hb_parnl( 1 ),	// handle of dialog box
       hb_parni( 2 ),	        // identifier of control
       (LPCTSTR) hb_parc( 3 ) 	// text to set
    );
}

HB_FUNC( SETDLGITEMINT )
{
    SetDlgItemInt(
       (HWND) hb_parnl( 1 ),	// handle of dialog box
       hb_parni( 2 ),	        // identifier of control
       (UINT) hb_parni( 3 ), 	// text to set
       ( hb_pcount()<4 || ISNIL(4) || !hb_parl(4) )? 0:1
    );
}

HB_FUNC( GETDLGITEMTEXT )
{
   USHORT iLen = hb_parni( 3 );
   char *cText = (char*) hb_xgrab( iLen+1 );

   GetDlgItemText(
       (HWND) hb_parnl( 1 ),	// handle of dialog box
    hb_parni( 2 ),          	// identifier of control
    (LPTSTR) cText,       	// address of buffer for text
    iLen                   	// maximum size of string
   );	
   hb_retc( cText );
   hb_xfree( cText );
}

HB_FUNC( GETEDITTEXT )
{
   HWND   hDlg = (HWND) hb_parnl( 1 );
   int    id = hb_parni( 2 );
   USHORT iLen = (USHORT)SendMessage( GetDlgItem( hDlg,id ), WM_GETTEXTLENGTH, 0, 0 );
   char *cText = (char*) hb_xgrab( iLen+2 );

   GetDlgItemText(
       hDlg,	// handle of dialog box
    id,        	// identifier of control
    (LPTSTR) cText,       	// address of buffer for text
    iLen+1                   	// maximum size of string
   );	
   hb_retc( cText );
   hb_xfree( cText );
}

HB_FUNC( CHECKDLGBUTTON )
{
    CheckDlgButton(
       (HWND) hb_parnl( 1 ),	// handle of dialog box
       hb_parni( 2 ),	        // identifier of control
       ( hb_parl( 3 ) )? BST_CHECKED:BST_UNCHECKED 	// value to set
    );
}

HB_FUNC( CHECKRADIOBUTTON )
{
    CheckRadioButton(
       (HWND) hb_parnl( 1 ),	// handle of dialog box
       hb_parni( 2 ),	        // identifier of first radio button in group
       hb_parni( 3 ),	        // identifier of last radio button in group
       hb_parni( 4 )	        // identifier of radio button to select
    );
}

HB_FUNC( ISDLGBUTTONCHECKED )
{
  UINT nRes = IsDlgButtonChecked(
                  (HWND) hb_parnl( 1 ),       // handle of dialog box
                   hb_parni( 2 )               // button identifier
              );
  if( nRes == BST_CHECKED )
     hb_retl( TRUE );
  else
     hb_retl( FALSE );
}

HB_FUNC( COMBOADDSTRING )
{
   char *cString = hb_parc( 2 );
   SendMessage( (HWND) hb_parnl( 1 ), CB_ADDSTRING, 0, (LPARAM) cString );
}

HB_FUNC( COMBOSETSTRING )
{
   SendMessage( (HWND) hb_parnl( 1 ), CB_SETCURSEL, (WPARAM) hb_parni(2)-1, 0);
}

HB_FUNC( GETNOTIFYCODE )
{
   hb_retnl( (LONG) (((NMHDR *) hb_parnl(1))->code) );
}

LPWORD lpwAlign ( LPWORD lpIn)
{
  ULONG ul;

  ul = (ULONG) lpIn;
  ul +=3;
  ul >>=2;
  ul <<=2;
  return (LPWORD) ul;
}

int nCopyAnsiToWideChar ( LPWORD lpWCStr, LPCSTR lpAnsiIn )
{
   int CodePage = GetACP();
   LPWSTR pszDst;
   int nDstLen = MultiByteToWideChar( CodePage, 0, lpAnsiIn, -1, NULL, 0 );
   int i;

   pszDst = ( LPWSTR ) hb_xgrab( nDstLen*2 );

   MultiByteToWideChar( CodePage, 0, lpAnsiIn, -1, pszDst, nDstLen );

   for( i=0;i<nDstLen;i++ )
      *( lpWCStr+i ) = *( pszDst+i );

   hb_xfree( pszDst );      
   return nDstLen;
/*
  int nChar = 0;

  do {
    *lpWCStr++ = (WORD) *lpAnsiIn;
    nChar++;
  } while (*lpAnsiIn++);

  return nChar;
*/
}

LPDLGTEMPLATE CreateDlgTemplate( PHB_ITEM pObj, int x1, int y1, int dwidth, int dheight, ULONG ulStyle )
{
   PWORD p, pdlgtemplate;
   PHB_ITEM pControls, pControl, temp;
   LONG baseUnit = GetDialogBaseUnits();
   int baseunitX = LOWORD( baseUnit ), baseunitY = HIWORD( baseUnit );
   int nchar, nControls, i;
   long lTemplateSize = 36;
   LONG lExtStyle;

   x1 = (x1 * 4) / baseunitX;
   dwidth = (dwidth * 4) / baseunitX;
   y1 = (y1 * 8) / baseunitY;
   dheight = (dheight * 8) / baseunitY;

   pControls = hb_itemNew( GetObjectVar( pObj, "ACONTROLS" ) );
   nControls = pControls->item.asArray.value->ulLen;

   temp = GetObjectVar( pObj, "TITLE" );
   if( hb_itemType( temp ) == HB_IT_STRING )
      lTemplateSize += temp->item.asString.length * 2;
   else
      lTemplateSize += 2;

   for( i=0;i<nControls;i++ )
   {
      lTemplateSize += 36;
      pControl = (PHB_ITEM) (pControls->item.asArray.value->pItems + i);
      temp =  GetObjectVar( pControl, "WINCLASS" );
      lTemplateSize += temp->item.asString.length * 2;
      temp =  GetObjectVar( pControl, "TITLE" );
      if( hb_itemType( temp ) == HB_IT_STRING )
         lTemplateSize += temp->item.asString.length * 2;
      else
         lTemplateSize += 2;
   }

   pdlgtemplate = (PWORD) LocalAlloc (LPTR,lTemplateSize );
   p = pdlgtemplate;
   *p++ = 1;          // DlgVer
   *p++ = 0xFFFF;     // Signature
   *p++ = 0;          // LOWORD HelpID
   *p++ = 0;          // HIWORD HelpID
   *p++ = 0;          // LOWORD (lExtendedStyle)
   *p++ = 0;          // HIWORD (lExtendedStyle)
   *p++ = LOWORD (ulStyle);
   *p++ = HIWORD (ulStyle);
   *p++ = nControls;  // NumberOfItems
   *p++ = x1;         // x
   *p++ = y1;         // y
   *p++ = dwidth;     // cx
   *p++ = dheight;    // cy
   *p++ = 0;          // Menu
   *p++ = 0;          // Class

   // Copy the title of the dialog box.

   temp = GetObjectVar( pObj, "TITLE" );
   if( hb_itemType( temp ) == HB_IT_STRING )
   {
      nchar = nCopyAnsiToWideChar (p, TEXT(hb_itemGetCPtr( temp )));
      p += nchar;
   }
   else
      *p++ = 0; 

   /* {
      char res[20];
      sprintf( res,"nControls: %d",nControls );
      MessageBox( GetActiveWindow(), res, "", MB_OK | MB_ICONINFORMATION );
   } */

   for( i=0;i<nControls;i++ )
   {
      pControl = (PHB_ITEM) (pControls->item.asArray.value->pItems + i);
      temp = hb_itemPutNI( NULL, -1 );
      SetObjectVar( pControl, "_HANDLE", temp );
      hb_itemRelease( temp );
      
      p = lpwAlign (p);

      ulStyle = (ULONG)hb_itemGetNL( GetObjectVar( pControl, "STYLE" ) );
      lExtStyle = hb_itemGetNL( GetObjectVar( pControl, "EXTSTYLE" ) );
      x1 = ( hb_itemGetNI( GetObjectVar( pControl, "NLEFT" ) ) * 4) / baseunitX;
      dwidth = ( hb_itemGetNI( GetObjectVar( pControl, "NWIDTH" ) ) * 4) / baseunitX;
      y1 = ( hb_itemGetNI( GetObjectVar( pControl, "NTOP" ) ) * 8) / baseunitY;
      dheight = ( hb_itemGetNI( GetObjectVar( pControl, "NHEIGHT" ) ) * 8) / baseunitY;
      
      *p++ = 0;          // LOWORD (lHelpID)
      *p++ = 0;          // HIWORD (lHelpID)
      *p++ = LOWORD (lExtStyle);          // LOWORD (lExtendedStyle)
      *p++ = HIWORD (lExtStyle);          // HIWORD (lExtendedStyle)
      *p++ = LOWORD (ulStyle);
      *p++ = HIWORD (ulStyle);
      *p++ = x1;         // x
      *p++ = y1;         // y
      *p++ = dwidth;     // cx
      *p++ = dheight;    // cy
      *p++ = hb_itemGetNI( GetObjectVar( pControl, "ID" ) );       // LOWORD (Control ID)
      *p++ = 0;      // HOWORD (Control ID)

      // class name
      nchar = nCopyAnsiToWideChar (p, TEXT(hb_itemGetCPtr( GetObjectVar( pControl, "WINCLASS" ) )));
      p += nchar;

      // Caption
      temp = GetObjectVar( pControl, "TITLE" );
      if( hb_itemType( temp ) == HB_IT_STRING )
         nchar = nCopyAnsiToWideChar (p, TEXT(hb_itemGetCPtr( temp )));
      else
         nchar = nCopyAnsiToWideChar (p, TEXT(""));
      p += nchar;

      *p++ = 0;  // Advance pointer over nExtraStuff WORD.
   }
   *p = 0;  // Number of bytes of extra data.

   hb_itemRelease( pControls );

   return (LPDLGTEMPLATE) pdlgtemplate;

}

HB_FUNC( CREATEDLGTEMPLATE )
{
   hb_retnl( (LONG) CreateDlgTemplate( hb_param( 1, HB_IT_OBJECT ), hb_parni(2),
                         hb_parni(3), hb_parni(4), hb_parni(5), (ULONG)hb_parnd(6) ) );
}

HB_FUNC( RELEASEDLGTEMPLATE )
{
   LocalFree( LocalHandle( (LPDLGTEMPLATE) hb_parnl(1) ) );
}

/*
 *  _CreatePropertySheetPage( aDlg, x1, y1, nWidth, nHeight, nStyle ) --> hPage
 */
HB_FUNC( _CREATEPROPERTYSHEETPAGE )
{
   PROPSHEETPAGE psp;
   PHB_ITEM pObj = hb_param( 1, HB_IT_OBJECT ), temp;
   char *cTitle;
   LPDLGTEMPLATE pdlgtemplate;
   HPROPSHEETPAGE h;

   memset( (void*) &psp, 0, sizeof( PROPSHEETPAGE ) );

   psp.dwSize = sizeof(PROPSHEETPAGE);
   psp.hInstance = (HINSTANCE) NULL;
   psp.pszTitle = NULL;
   psp.pfnDlgProc = (DLGPROC) PSPProc;
   psp.lParam = (LPARAM) pObj;
   psp.pfnCallback = NULL;
   psp.pcRefParent = 0;
#if !defined(__BORLANDC__)
   psp.hIcon = 0;
#else
   psp.DUMMYUNIONNAME2.hIcon = 0;
#endif

   if( hb_itemGetNI( GetObjectVar( pObj, "TYPE" ) ) == WND_DLG_RESOURCE )
   {
      psp.dwFlags = 0;

      temp = GetObjectVar( pObj, "XRESOURCEID" );
      if( HB_IS_STRING( temp) || HB_IS_NUMERIC( temp ) )
         cTitle = ( HB_IS_STRING( temp ) ? hb_itemGetCPtr( temp ) : MAKEINTRESOURCE( hb_itemGetNL( temp ) ) );
      else
         cTitle = NULL;
#if !defined(__BORLANDC__)
      psp.pszTemplate = cTitle;
#else
      psp.DUMMYUNIONNAME.pszTemplate = cTitle;
#endif
   }
   else
   {
      pdlgtemplate = (LPDLGTEMPLATE) hb_parnl(2);

      psp.dwFlags = PSP_DLGINDIRECT;
#if !defined(__BORLANDC__)
      psp.pResource = pdlgtemplate;
#else
      psp.DUMMYUNIONNAME.pResource = pdlgtemplate;
#endif
   }

   h = CreatePropertySheetPage( &psp );
   hb_retnl( (LONG)h );
   // if( pdlgtemplate )
   //   LocalFree (LocalHandle (pdlgtemplate));
}

/*
 * _PropertySheet( hWndParent, aPageHandles, nPageHandles, cTitle, 
 *                [ lModeless ], [ lNoApply ], [ lWizard ] ) --> hPropertySheet
 */
HB_FUNC( _PROPERTYSHEET )
{
   PHB_ITEM pArr = hb_param( 2, HB_IT_ARRAY );
   int nPages = hb_parni(3), i;
   HPROPSHEETPAGE psp[10];
   PROPSHEETHEADER psh;
   DWORD dwFlags = (hb_pcount()<5||ISNIL(5)||!hb_parl(5))? 0:PSH_MODELESS;

   if( hb_pcount()>5 && !ISNIL(6) && hb_parl(6) )
      dwFlags |= PSH_NOAPPLYNOW;
   if( hb_pcount()>6 && !ISNIL(7) && hb_parl(7) )
      dwFlags |= PSH_WIZARD;
   for( i=0;i<nPages;i++ )
      psp[i] = (HPROPSHEETPAGE) hb_itemGetNL( pArr->item.asArray.value->pItems + i );

   psh.dwSize = sizeof(PROPSHEETHEADER);
   psh.dwFlags = dwFlags;
   psh.hwndParent = (HWND) hb_parnl(1);
   psh.hInstance = (HINSTANCE) NULL;
#if !defined(__BORLANDC__)
   psh.pszIcon = NULL;
#else
   psh.DUMMYUNIONNAME.pszIcon = NULL;
#endif
   psh.pszCaption = (LPSTR) hb_parc(4);
   psh.nPages = nPages;
#if !defined(__BORLANDC__)
   psh.nStartPage = 0;
   psh.phpage = psp;
#else
   psh.DUMMYUNIONNAME2.nStartPage = 0;
   psh.DUMMYUNIONNAME3.phpage = psp;
#endif
   psh.pfnCallback = NULL;

   hb_retnl( (LONG) PropertySheet(&psh) );
}

/* Hwg_CreateDlgIndirect( hParentWnd, pArray, x1, y1, nWidth, nHeight, nStyle )
*/

HB_FUNC( HWG_CREATEDLGINDIRECT )
{
   LPDLGTEMPLATE pdlgtemplate;
   PHB_ITEM pObject = hb_param( 2, HB_IT_OBJECT );

   if( hb_pcount()>7 && !ISNIL(8) )
      pdlgtemplate = (LPDLGTEMPLATE) hb_parnl(8);
   else
   {
      ULONG ulStyle = ( ( hb_pcount()>6 && !ISNIL(7) )? (ULONG)hb_parnd(7):WS_POPUP | WS_VISIBLE | WS_CAPTION | WS_SYSMENU | WS_SIZEBOX ); // | DS_SETFONT;

      pdlgtemplate = CreateDlgTemplate( pObject, hb_parni(3), hb_parni(4),
                          hb_parni(5), hb_parni(6), ulStyle );
   }

   CreateDialogIndirectParam( hModule, pdlgtemplate,
                      (HWND) hb_parnl(1), (DLGPROC) DlgProc, (LPARAM) pObject );

   if( hb_pcount()<8 || ISNIL(8) )
      LocalFree( LocalHandle( pdlgtemplate ) );
}

/* Hwg_DlgBoxIndirect( hParentWnd, pArray, x1, y1, nWidth, nHeight, nStyle )
*/

HB_FUNC( HWG_DLGBOXINDIRECT )
{
   PHB_ITEM pObject = hb_param( 2, HB_IT_OBJECT );
   ULONG ulStyle = ( ( hb_pcount()>6 && !ISNIL(7) )? (ULONG)hb_parnd(7):WS_POPUP | WS_VISIBLE | WS_CAPTION | WS_SYSMENU ); // | DS_SETFONT;
   int x1 = hb_parni(3), y1 = hb_parni(4), dwidth = hb_parni(5), dheight = hb_parni(6);
   LPDLGTEMPLATE pdlgtemplate = CreateDlgTemplate( pObject, x1, y1, dwidth, dheight, ulStyle );

   DialogBoxIndirectParam( hModule, pdlgtemplate,
                (HWND) hb_parnl(1), (DLGPROC) ModalDlgProc, (LPARAM) pObject );
   LocalFree (LocalHandle (pdlgtemplate));
}

HB_FUNC( DIALOGBASEUNITS )
{
   hb_retnl( GetDialogBaseUnits() );
}

LRESULT CALLBACK ModalDlgProc( HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam )
{
   // PHB_DYNS pSymTest;
   long int res;
   PHB_ITEM pObject;

   if( uMsg == WM_INITDIALOG )
   {
      PHB_ITEM temp;

      temp = hb_itemPutNL( NULL, 1 );
      SetObjectVar( (PHB_ITEM) lParam, "_NHOLDER", temp );
      hb_itemRelease( temp );

      temp = hb_itemPutNL( NULL, (LONG)hDlg );
      SetObjectVar( (PHB_ITEM) lParam, "_HANDLE", temp );
      hb_itemRelease( temp );

      SetWindowObject( hDlg, (PHB_ITEM) lParam );
   }
   pObject = ( PHB_ITEM ) GetWindowLongPtr( hDlg, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( pSym_onEvent->pSymbol );
      hb_vmPush( pObject );
      hb_vmPushLong( (LONG ) uMsg );
      hb_vmPushLong( (LONG ) wParam );
      hb_vmPushLong( (LONG ) lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return FALSE;
      else
         return res;
   }
   else
      return FALSE;

}

LRESULT CALLBACK DlgProc( HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject;

   if( uMsg == WM_INITDIALOG )
   {
      PHB_ITEM temp;

      temp = hb_itemPutNL( NULL, 1 );
      SetObjectVar( (PHB_ITEM) lParam, "_NHOLDER", temp );
      hb_itemRelease( temp );

      temp = hb_itemPutNL( NULL, (LONG)hDlg );
      SetObjectVar( (PHB_ITEM) lParam, "_HANDLE", temp );
      hb_itemRelease( temp );

      SetWindowObject( hDlg, (PHB_ITEM) lParam );

      if( iDialogs == nDialogs )
      {
         nDialogs += 16;
         if( nDialogs == 16 )
            aDialogs = (HWND*)hb_xgrab( sizeof( HWND ) * nDialogs );
         else
            aDialogs = (HWND*)hb_xrealloc( aDialogs, sizeof( HWND ) * nDialogs );
      }
      aDialogs[ iDialogs++ ] = hDlg;
   }
   else if( uMsg == WM_DESTROY )
   {
      int i;
      for( i=0;i<iDialogs;i++ )
         if( aDialogs[ i ] == hDlg )  break;
      iDialogs --;
      for( ;i<iDialogs;i++ )
         aDialogs[ i ] = aDialogs[ i+1 ];
   }

   pObject = ( PHB_ITEM ) GetWindowLongPtr( hDlg, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( pSym_onEvent->pSymbol );
      hb_vmPush( pObject );
      hb_vmPushLong( (LONG ) uMsg );
      hb_vmPushLong( (LONG ) wParam );
      hb_vmPushLong( (LONG ) lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return FALSE;
      else
         return res;
   }
   else
      return FALSE;

}

LRESULT CALLBACK PSPProc( HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject;

   if( uMsg == WM_INITDIALOG )
   {
      PHB_ITEM pObj, temp;

      pObj = (PHB_ITEM) (((PROPSHEETPAGE *)lParam)->lParam);

      temp = hb_itemPutNL( NULL, 1 );
      SetObjectVar( pObj, "_NHOLDER", temp );
      hb_itemRelease( temp );

      temp = hb_itemPutNL( NULL, (LONG)hDlg );
      SetObjectVar( pObj, "_HANDLE", temp );
      hb_itemRelease( temp );

      SetWindowObject( hDlg, pObj );

      if( iDialogs == nDialogs )
      {
         nDialogs += 16;
         if( nDialogs == 16 )
            aDialogs = (HWND*)hb_xgrab( sizeof( HWND ) * nDialogs );
         else
            aDialogs = (HWND*)hb_xrealloc( aDialogs, sizeof( HWND ) * nDialogs );
      }
      aDialogs[ iDialogs++ ] = hDlg;
      // hb_itemRelease( pObj );
   }
   else if( uMsg == WM_NOTIFY )
      uMsg = WM_PSPNOTIFY;
   else if( uMsg == WM_DESTROY )
   {
      int i;
      for( i=0;i<iDialogs;i++ )
         if( aDialogs[ i ] == hDlg )  break;
      iDialogs --;
      for( ;i<iDialogs;i++ )
         aDialogs[ i ] = aDialogs[ i+1 ];
   }

   pObject = ( PHB_ITEM ) GetWindowLongPtr( hDlg, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( pSym_onEvent->pSymbol );
      hb_vmPush( pObject );
      hb_vmPushLong( (LONG ) uMsg );
      hb_vmPushLong( (LONG ) wParam );
      hb_vmPushLong( (LONG ) lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return FALSE;
      else
         return res;
   }
   else
      return FALSE;

}

HB_FUNC( HWG_EXITPROC )
{
   if( aDialogs )
      hb_xfree( aDialogs );
}
