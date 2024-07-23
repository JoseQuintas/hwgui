/*

    windows_mac.h
    
    $Id$
    
    Header file for MacOS
    
    Simular to 
	windows.h - for Win32 API

*/

#ifndef _WINDOWSMAC_H
#define _WINDOWSMAC_H
#if __GNUC__ >=3
#pragma GCC system_header
#endif

typedef void *PVOID;
typedef PVOID HANDLE;
typedef HANDLE HWND;
typedef unsigned char BOOL;
typedef HANDLE HMODULE;


struct Rect {
 short top;
 short left;
 short bottom;
 short right;
 };
 typedef struct Rect RECT;

#include <stdarg.h> 


#endif

/* ============== EOF of windows_mac.h ================ */
