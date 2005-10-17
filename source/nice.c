/*
 * $Id: nice.c,v 1.10 2005-10-17 21:24:35 lculik Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * 
 *
 * Copyright 2003 Luiz Rafael Culik Guimaraes <culikr@brtrubo.com>
 * www - http://sites.uol.com.br/culikr/
*/

#define HB_OS_WIN_32_USED

#define _WIN32_WINNT 0x0500
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
#include "guilib.h"

#ifndef GRADIENT_FILL_RECT_H

#define GRADIENT_FILL_RECT_H 0
#define GRADIENT_FILL_RECT_V 1

#if !defined(__WATCOMC__) && !defined(__MINGW32__)
typedef struct _GRADIENT_RECT
{
    ULONG UpperLeft;
    ULONG LowerRight;
}GRADIENT_RECT,*PGRADIENT_RECT,*LPGRADIENT_RECT;
#endif

#endif

typedef int  (_stdcall *GRADIENTFILL) (HDC, PTRIVERTEX, int , PVOID, int , int );
LRESULT CALLBACK NiceButtProc (HWND, UINT, WPARAM, LPARAM );

static GRADIENTFILL pGradientfill = NULL;

void Draw_Gradient(HDC hdc, int x, int y, int w, int h, int r, int g, int b)
{
	TRIVERTEX  Vert[2];
   GRADIENT_RECT  Rect = { 0 } ;
   HB_SYMBOL_UNUSED( x );
   HB_SYMBOL_UNUSED( y );
	// ******************************************************
	Vert[0].x=0;
	Vert[0].y=0;
	Vert[0].Red=65535-(65535-(r*256));
	Vert[0].Green=65535-(65535-(g*256));
	Vert[0].Blue=65535-(65535-(b*256));
	Vert[0].Alpha=0;
	// ******************************************************
	Vert[1].x=w;
	Vert[1].y=h/2;
	Vert[1].Red=65535-(65535-(255*256));
	Vert[1].Green=65535-(65535-(255*256));
	Vert[1].Blue=65535-(65535-(255*256));
	Vert[1].Alpha=0;
	// ******************************************************
	Rect.UpperLeft=0;
	Rect.LowerRight=1;
	// ******************************************************
	pGradientfill(hdc,Vert,2,&Rect,1,GRADIENT_FILL_RECT_V);
	// ******************************************************
	Vert[0].x=0;
	Vert[0].y=h/2;
	Vert[0].Red=65535-(65535-(255*256));
	Vert[0].Green=65535-(65535-(255*256));
	Vert[0].Blue=65535-(65535-(255*256));
	Vert[0].Alpha=0;
	// ******************************************************
	Vert[1].x=w;
	Vert[1].y=h;
	Vert[1].Red=65535-(65535-(r*256));
	Vert[1].Green=65535-(65535-(g*256));
	Vert[1].Blue=65535-(65535-(b*256));
	Vert[1].Alpha=0;
	// ******************************************************
	Rect.UpperLeft=0;
	Rect.LowerRight=1;
	// ******************************************************
	pGradientfill(hdc,Vert,2,&Rect,1,GRADIENT_FILL_RECT_V);
}


LRESULT CALLBACK NiceButtProc (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
   long int res;
   PHB_DYNS pSymTest;
   if( ( pSymTest = hb_dynsymFind( "NICEBUTTPROC" ) ) != NULL )
   {
      hb_vmPushSymbol( pSymTest->pSymbol );
      hb_vmPushNil();                 /* places NIL at self */
      hb_vmPushLong( (LONG ) hWnd );    /* pushes parameters on to the hvm stack */
      hb_vmPushLong( (LONG ) message );
      hb_vmPushLong( (LONG ) wParam );
      hb_vmPushLong( (LONG ) lParam );
      hb_vmDo( 4 );  /* where iArgCount is the number of pushed parameters */
      res = hb_parl( -1 );
      if( res )
         return 0;
      else
         return( DefWindowProc( hWnd, message, wParam, lParam ));
    }
    else
       return( DefWindowProc( hWnd, message, wParam, lParam ));
}


HB_FUNC( CREATEROUNDRECTRGN )
{
HRGN Res = CreateRoundRectRgn( hb_parni( 1 ), hb_parni( 2 ), hb_parni( 3 ),
           hb_parni( 4 ), hb_parni( 5 ), hb_parni( 6 ) ) ;
   hb_retnl( (LONG) Res );
}


HB_FUNC( SETWINDOWRGN )
{
   hb_retni( SetWindowRgn((HWND) hb_parnl( 1 ), (HRGN) hb_parnl( 2 ), hb_parl( 3 ) ) );
}

HB_FUNC( HWG_REGNICE )
{
	// **********[ DLL Declarations ]**********
   static TCHAR szAppName[] = TEXT ( "NICEBUTT" );
   static BOOL  bRegistered = 0;
   static  WNDCLASS  wc = { 0 };

	pGradientfill = (GRADIENTFILL) GetProcAddress(LoadLibrary("MSIMG32.DLL"),"GradientFill");
//    if (Gradientfill == NULL)
//        return FALSE;
   if( !bRegistered )
   {
    
       wc.style         = CS_HREDRAW|CS_VREDRAW|CS_GLOBALCLASS;
       wc.hInstance     = GetModuleHandle(0);
       wc.hbrBackground = (HBRUSH)(COLOR_BTNFACE+1);
       wc.lpszClassName = szAppName;
       wc.lpfnWndProc   = NiceButtProc;
       wc.cbClsExtra    = 0;
       wc.cbWndExtra    = 0;
       wc.hIcon         = NULL;
       wc.hCursor       = NULL;
       wc.lpszMenuName  = 0;
   
       RegisterClass(&wc);
       bRegistered = 1  ;
   }
}


HB_FUNC( CREATENICEBTN )
{
   HWND hWndPanel;
   ULONG ulStyle = (!ISNIL(3) ? hb_parnl(3):  WS_CLIPCHILDREN | WS_CLIPSIBLINGS );


   hWndPanel = CreateWindowEx( hb_parni( 8 ),
                 "NICEBUTT",                      /* predefined class  */
                 hb_parc(9),                      /* no window title   */
                 WS_CHILD | WS_VISIBLE | ulStyle, /* style  */
                 hb_parni(4), hb_parni(5),        /* x, y       */
                 hb_parni(6), hb_parni(7),     /* nWidth, nHeight */
                 (HWND) hb_parnl(1),           /* parent window    */ 
                 (HMENU) hb_parni(2),          /* control ID  */ 
                 GetModuleHandle( NULL ), 
                 NULL);

   hb_retnl( (LONG) hWndPanel );
}

HB_FUNC( ISMOUSEOVER )
{
	RECT  Rect;
	POINT  Pt;
    GetWindowRect( (HWND) hb_parnl( 1 ), &Rect ) ;
    GetCursorPos( &Pt );
    hb_retl( PtInRect( &Rect, Pt ) );
}


HB_FUNC( RGB )
{
   hb_retnl( RGB( hb_parni( 1 ), hb_parni( 2 ), hb_parni( 3 ) ) ) ;
}

HB_FUNC( DRAW_GRADIENT )
{
   Draw_Gradient( (HDC) hb_parnl( 1 ), hb_parni( 2 ), hb_parni( 3 ), hb_parni( 4 ), hb_parni( 5 ), hb_parni( 6 ), hb_parni( 7 ),hb_parni( 8 ) );
}

HB_FUNC( MAKELONG )
{
   hb_retnl( (LONG) MAKELONG( (WORD) hb_parnl( 1 ), (WORD) hb_parnl( 2 ) ) );
}


HB_FUNC( GETWINDOWLONG )
{
   hb_retnl( GetWindowLong( (HWND) hb_parnl( 1 ), hb_parni( 2 ) ) ) ;
}

HB_FUNC( SETBKMODE )
{
   hb_retni( SetBkMode( (HDC) hb_parnl( 1 ), hb_parni( 2 ) ) );
}
