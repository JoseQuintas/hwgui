/*
 * $Id: htool.prg,v 1.12 2007-12-20 10:39:54 lculik Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 *
 *
 * Copyright 2004 Luiz Rafael Culik Guimaraes <culikr@brtrubo.com>
 * www - http://sites.uol.com.br/culikr/
*/

#include "windows.ch"
#include "inkey.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"
static hHook
#define TRANSPARENT 1

CLASS HToolBar INHERIT HControl

   DATA winclass INIT "ToolbarWindow32"
   Data TEXT, id, nTop, nLeft, nwidth, nheight
   CLASSDATA oSelected INIT Nil
   DATA State INIT 0
   Data ExStyle
   Data bClick, cTooltip

   DATA lPress INIT .F.
   DATA lFlat
   DATA nOrder
   Data aItem init {}

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp ,aItem)
   METHOD Redefine( oWndParent,nId,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp ,aItem)

   METHOD Activate()
   METHOD INIT()
   METHOD AddButton(a,s,d,f,g,h)
   METHOD Notify( lParam )
ENDCLASS


METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp ,aitem) CLASS hToolBar
   Default  aItem to {}
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )
   HWG_InitCommonControlsEx()
   ::aitem := aItem

   ::Activate()

Return Self



METHOD Redefine( oWndParent,nId,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp,aItem )  CLASS hToolBar
   Default  aItem to {}
   Super:New( oWndParent,nId,0,0,0,0,0,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )
   HWG_InitCommonControlsEx()
   ::aitem := aItem

   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0

Return Self


METHOD Activate CLASS hToolBar

   IF ::oParent:handle != 0

      ::handle := CREATETOOLBAR( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::extStyle )

      ::Init()
   ENDIF
RETURN Nil

METHOD INIT CLASS hToolBar
Local n,n1
Local aTemp
Local hIm
Local aButton :={}
Local aBmpSize
Local nPos
   IF !::lInit
      Super:Init()
      For n := 1 TO len( ::aItem )

         IF Valtype( ::aItem[ n, 7 ] ) == "B"

            ::oParent:AddEvent( BN_CLICKED, ::aItem[ n, 2 ], ::aItem[ n ,7 ] )

         ENDIF

         IF Valtype( ::aItem[ n, 9 ] ) == "A"

            ::aItem[ n, 10 ] := hwg__CreatePopupMenu()
            aTemp := ::aItem[ n, 9 ]

            FOR n1 :=1 to Len( aTemp )
               hwg__AddMenuItem( ::aItem[ n, 10 ], aTemp[ n1, 1 ], -1, .F., aTemp[ n1, 2 ], , .F. )
               ::oParent:AddEvent( BN_CLICKED, aTemp[ n1, 2 ], aTemp[ n1,3 ] )
            NEXT

         ENDIF

        IF ::aItem[ n, 1 ] > 0
           AAdd( aButton, LoadImage( , ::aitem[ n, 1 ] , IMAGE_BITMAP, 0, 0, LR_DEFAULTSIZE + LR_CREATEDIBSECTION ) )
        ENDIF

      NEXT

      IF Len(aButton ) >0

          aBmpSize := GetBitmapSize( aButton[1] )

          IF aBmpSize[ 3 ] == 4
             hIm := CreateImageList( {} ,aBmpSize[ 1 ], aBmpSize[ 2 ], 1, ILC_COLOR4 + ILC_MASK )
          ELSEIF aBmpSize[ 3 ] == 8
             hIm := CreateImageList( {} ,aBmpSize[ 1 ], aBmpSize[ 2 ], 1, ILC_COLOR8 + ILC_MASK )
          ELSEIF aBmpSize[ 3 ] == 24
             hIm := CreateImageList( {} ,aBmpSize[ 1 ], aBmpSize[ 2 ], 1, ILC_COLORDDB + ILC_MASK )
          ENDIF

          FOR nPos :=1 to len(aButton)

             aBmpSize := GetBitmapSize( aButton[nPos] )

             IF aBmpSize[3] == 24
//             Imagelist_AddMasked( hIm,aButton[nPos],RGB(236,223,216) )
                Imagelist_Add( hIm, aButton[ nPos ] )
             ELSE
                Imagelist_Add( hIm, aButton[ nPos ] )
             ENDIF

          NEXT

       SendMessage( ::Handle, TB_SETIMAGELIST, 0, hIm )

      ENDIF
      if len( ::aItem ) >0
         TOOLBARADDBUTTONS( ::handle, ::aItem, Len( ::aItem ) )

         SendMessage( ::handle, TB_SETEXTENDEDSTYLE, 0, TBSTYLE_EX_DRAWDDARROWS )
      endif

   ENDIF

RETURN Nil

METHOD Notify( lParam ) CLASS hToolBar

    Local nCode :=  GetNotifyCode( lParam )
    Local nId

    Local nButton
    Local nPos

    IF nCode == TTN_GETDISPINFO

       nButton :=TOOLBAR_GETDISPINFOID( lParam )
       nPos := AScan( ::aItem,  { | x | x[ 2 ] == nButton })
       TOOLBAR_SETDISPINFO( lParam, ::aItem[ nPos, 8 ] )

    ELSEIF nCode == TBN_GETINFOTIP

       nId := TOOLBAR_GETINFOTIPID(lParam)
       nPos := AScan( ::aItem,  { | x | x[ 2 ] == nId })
       TOOLBAR_GETINFOTIP( lParam, ::aItem[ nPos, 8 ] )

    ELSEIF nCode == TBN_DROPDOWN
       if valtype(::aItem[1,9]) ="A"
       nid := TOOLBAR_SUBMENUEXGETID( lParam )
       nPos := AScan( ::aItem,  { | x | x[ 2 ] == nId })
       TOOLBAR_SUBMENUEx( lParam, ::aItem[ nPos, 10 ], ::oParent:handle )
       else
              TOOLBAR_SUBMENU(lParam,1,::oParent:handle)
       endif
    ENDIF

Return 0

METHOD AddButton(nBitIp,nId,bState,bStyle,cText,bClick,c,aMenu) CLASS hToolBar
   Local hMenu := Nil
   DEFAULT nBitIp to -1
   DEFAULT bstate to TBSTATE_ENABLED
   DEFAULT bstyle to 0x0000
   DEFAULT c to ""
   DEFAULT ctext to ""
   AAdd( ::aItem ,{ nBitIp, nId, bState, bStyle, 0, cText, bClick, c, aMenu, hMenu } )

RETURN Self


CLASS HToolBarEX INHERIT HToolBar

//method onevent()
method init()
METHOD ExecuteTool(nid)
DESTRUCTOR MyDestructor
end class


method init class htoolbarex
   ::super:init()
   SetWindowObject( ::handle,Self )
   SETTOOLHANDLE(::handle)
  Sethook()
return self

//method onEvent(msg,w,l) class htoolbarex
//Local nId
//Local nPos
//  if msg == WM_KEYDOWN
//
//  return -1
//  elseif msg==WM_KEYUP
//  unsethook()
//  return -1
//  endif
//return 0

method ExecuteTool(nid) class htoolbarex
Local nPos
nPos := ascan(::aItem,{|x| x[2] == nid})
if nId >0
   SEndMessage(::oParent:handle,WM_COMMAND,makewparam(nid,BN_CLICKED),::handle)
   return 0
endif
return -200
Static Function IsAltShift( lAlt)
Local cKeyb := GetKeyboardState()

   IF lAlt==Nil; lAlt := .T.; ENDIF
Return ( lAlt .AND. ( Asc(Substr(cKeyb,VK_MENU+1,1)) >= 128 ) )


PROCEDURE MyDestructor CLASS htoolbarex
  unsethook()
return
