 /*
 * $Id: hgrid.prg,v 1.5 2004-07-29 16:48:15 lf_sfnet Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HGrid class
 *
 * Copyright 2004 Rodrigo Moreno <rodrigo_moreno@yahoo.com>
 *
*/

/*
TODO: 1) In line edit
         The better way is using listview_hittest to determine the item and subitem position
      2) Imagelist
         The way is using the ListView_SetImageList
      3) Checkbox
         The way is using the NM_CUSTOMDRAW and DrawFrameControl()
         
*/

#include "windows.ch"
#include "guilib.ch"
#include "hbclass.ch"

#define LVS_REPORT              1
#define LVS_SINGLESEL           4
#define LVS_SHOWSELALWAYS       8
#define LVS_OWNERDATA        4096

#define LVN_ITEMCHANGED      -101
#define LVN_KEYDOWN          -155
#define LVN_GETDISPINFO      -150
#define NM_DBLCLK              -3
#define NM_KILLFOCUS           -8
#define NM_SETFOCUS            -7

CLASS HGrid INHERIT HControl

   CLASS VAR winclass INIT "SYSLISTVIEW32"

   DATA ItemCount
   DATA color   
   DATA bkcolor
   DATA aColumns   INIT {}
   DATA nRow       INIT 0
   DATA nCol       INIT 0
   
   DATA lNoScroll  INIT .F.
   DATA lNoBorder  INIT .F.
   DATA lNoLines   INIT .F.
   DATA lNoHeader  INIT .F.

   DATA bEnter
   DATA bKeyDown  
   DATA bPosChg
   DATA bDispInfo

   DATA bGfocus
   DATA bLfocus

   METHOD New( oWnd, nId, nStyle, x, y, width, height, oFont, bInit, bSize, bPaint, bEnter,;
               bGfocus, bLfocus, lNoScroll, lNoBord, bKeyDown, bPosChg, bDispInfo,;
               nItemCount, lNoLines, color, bkcolor, lNoHeader )

   METHOD Activate()
   METHOD Init()
   METHOD AddColumn( cHeader, nWidth, nJusHead ) INLINE AADD( ::aColumns, { cHeader, nWidth, nJusHead } )
   METHOD Refresh()
   METHOD RefreshLine()                          INLINE Listview_update( ::handle, Listview_getfirstitem( ::handle ) )
   METHOD SetItemCount(nItem)                    INLINE Listview_setitemcount( ::handle, nItem )
   METHOD Row()                                  INLINE Listview_getfirstitem( ::handle )
ENDCLASS


METHOD New( oWnd, nId, nStyle, x, y, width, height, oFont, bInit, bSize, bPaint, bEnter,;
               bGfocus, bLfocus, lNoScroll, lNoBord, bKeyDown, bPosChg, bDispInfo,;
               nItemCount, lNoLines, color, bkcolor, lNoHeader ) CLASS HGrid

   nStyle := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), LVS_SHOWSELALWAYS + WS_TABSTOP + IIF( lNoBord, 0, WS_BORDER ) + LVS_REPORT + LVS_OWNERDATA + LVS_SINGLESEL )
   Super:New( oWnd,nId,nStyle,x,y,Width,Height,oFont,bInit, ;
                  bSize,bPaint )

   ::ItemCount := nItemCount

   ::bGfocus := bGfocus
   ::bLfocus := bLfocus

   ::color   := color
   ::bkcolor := bkcolor
   
   ::lNoScroll := lNoScroll
   ::lNoBorder := lNoBord  
   ::lNoLines  := lNoLines 
   ::lNoHeader := lNoHeader
                         
   ::bEnter    := bEnter   
   ::bKeyDown  := bKeyDown 
   ::bPosChg   := bPosChg  
   ::bDispInfo := bDispInfo
   
   HWG_InitCommonControlsEx()
   
   ::Activate()
   
   /*
   if bGfocus != Nil
      ::oParent:AddEvent( NM_SETFOCUS,::id,bGfocus,.T. )
   endif
   
   if bLfocus != Nil
      ::oParent:AddEvent( NM_KILLFOCUS,::id,bLfocus,.T. )
   endif
   */

Return Self

METHOD Activate CLASS HGrid
   if ::oParent:handle != 0      
      ::handle := ListView_Create ( ::oParent:handle, ::id, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::style, ::lNoHeader, ::lNoScroll ) 

      ::Init()
   endif
Return Nil

METHOD Init() CLASS HGrid
   local i
   if !::lInit
      Super:Init()
      
      Listview_Init( ::handle, ::ItemCount, ::lNoLines )

      for i := 1 to len( ::aColumns )
        Listview_addcolumn( ::handle, i, ::aColumns[i, 2], ::aColumns[i, 1], ::aColumns[i, 3])
      next        

      if ::color != nil
        ListView_SetTextColor( ::handle, ::color ) 

      endif
      
      if ::bkcolor != nil
        Listview_setbkcolor( ::handle, ::bkcolor ) 
        Listview_settextbkcolor( ::handle, ::bkcolor ) 
      endif        
   endif
Return Nil

METHOD Refresh() CLASS HGrid
    Local iFirst, iLast
    
    iFirst := ListView_GetTopIndex(::handle) 

    iLast := iFirst + ListView_GetCountPerPage(::handle)

    ListView_RedrawItems( ::handle , iFirst, iLast ) 
Return Nil

Function ListViewNotify( oCtrl, lParam )
    Local aCord

    If GetNotifyCode ( lParam ) = LVN_KEYDOWN .and. oCtrl:bKeydown != nil
        Eval( oCtrl:bKeyDown, oCtrl, Listview_GetGridKey(lParam) )
                
    elseif GetNotifyCode ( lParam ) == NM_DBLCLK .and. oCtrl:bEnter != nil
        aCord := Listview_Hittest( octrl:handle, GetCursorRow() - GetWindowRow ( oCtrl:handle ), ;
                                                 GetCursorCol() - GetWindowCol ( oCtrl:handle ) )
        oCtrl:nRow := aCord[1]
        oCtrl:nCol := aCord[2]
                
        Eval( oCtrl:bEnter, oCtrl )

    elseif GetNotifyCode ( lParam ) == NM_SETFOCUS .and. oCtrl:bGfocus != nil
        Eval( oCtrl:bGfocus, oCtrl )

    elseif GetNotifyCode ( lParam ) == NM_KILLFOCUS .and. oCtrl:bLfocus != nil
        Eval( oCtrl:bLfocus, oCtrl )
                
    elseif GetNotifyCode ( lParam ) = LVN_ITEMCHANGED 
        oCtrl:nRow := oCtrl:Row()

        if oCtrl:bPosChg != nil
            Eval( oCtrl:bPosChg, oCtrl, Listview_getfirstitem( oCtrl:handle ) )
        endif            
        
    elseif GetNotifyCode ( lParam ) = LVN_GETDISPINFO .and. oCtrl:bDispInfo != nil
        aCord := Listview_getdispinfo( lParam )
        
        oCtrl:nRow := aCord[1]
        oCtrl:nCol := aCord[2]

        Listview_setdispinfo( lParam, Eval( oCtrl:bDispInfo, oCtrl, oCtrl:nRow, oCtrl:nCol ) )        

    endif
Return 0
    
