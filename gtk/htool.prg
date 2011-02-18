/*
 * $Id$
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
   DATA Line

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp ,aItem)

   METHOD Activate()
   METHOD INIT()
   METHOD REFRESH()
   METHOD AddButton(a,s,d,f,g,h)
   METHOD onEvent( msg, wParam, lParam )
   METHOD EnableAllButtons()
   METHOD DisableAllButtons()
   METHOD EnableButtons(n)
   METHOD DisableButtons(n)



ENDCLASS


METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp ,aitem) CLASS hToolBar
   Default  aItem to {}
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )

   ::aitem := aItem

   ::Activate()

Return Self

METHOD Activate CLASS hToolBar
   IF !empty(::oParent:handle )

      ::handle := CREATETOOLBAR(::oParent:handle )
      SetWindowObject( ::handle,Self )
      ::Init()
   ENDIF
RETURN Nil

METHOD INIT CLASS hToolBar
Local n,n1
Local aTemp
Local hIm
Local aButton :={}
Local aBmpSize
Local oImage
Local nPos
Local aItem
   IF !::lInit
      Super:Init()
      For n := 1 TO len( ::aItem )

//         IF Valtype( ::aItem[ n, 7 ] ) == "B"
//
//            ::oParent:AddEvent( BN_CLICKED, ::aItem[ n, 2 ], ::aItem[ n ,7 ] )
//
//         ENDIF

//         IF Valtype( ::aItem[ n, 9 ] ) == "A"
//
//            ::aItem[ n, 10 ] := hwg__CreatePopupMenu()
//            aTemp := ::aItem[ n, 9 ]
//
//            FOR n1 :=1 to Len( aTemp )
//               hwg__AddMenuItem( ::aItem[ n, 10 ], aTemp[ n1, 1 ], -1, .F., aTemp[ n1, 2 ], , .F. )
//               ::oParent:AddEvent( BN_CLICKED, aTemp[ n1, 2 ], aTemp[ n1,3 ] )
//            NEXT
//
//         ENDIF
         if valtype( ::aItem[ n, 1 ] ) == "N"
            IF !empty( ::aItem[ n, 1 ] )
               AAdd( aButton, ::aItem[ n , 1 ])
            ENDIF
         elseif  valtype( ::aItem[ n, 1 ] ) == "C"
            if ".ico" $ lower(::aItem[ n, 1 ]) //if ".ico" in lower(::aItem[ n, 1 ])
               oImage:=hIcon():AddFile( ::aItem[ n, 1 ] )
            else
               oImage:=hBitmap():AddFile( ::aItem[ n, 1 ] )
            endif
            if valtype(oImage) =="O"
               aadd(aButton,Oimage:handle)
               ::aItem[ n, 1 ] := Oimage:handle
            endif
         ENDIF

      NEXT n

/*      IF Len(aButton ) >0

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
*/
      if len( ::aItem ) >0
         For Each aItem in ::aItem

            if aItem[4] == TBSTYLE_BUTTON

               aItem[11] := CreateToolBarButton(::handle,aItem[1],aItem[6],.f.)
               aItem[2] := hb_enumindex()
//               hwg_SetSignal( aItem[11],"clicked",WM_LBUTTONUP,aItem[2],0 )
               TOOLBAR_SETACTION(aItem[11],aItem[7])
               if !empty(aItem[8])
                  AddtoolTip(::handle, aItem[11],aItem[8])
               endif
            elseif aitem[4] == TBSTYLE_SEP
               aItem[11] := CreateToolBarButton(::handle,,,.t.)
               aItem[2] := hb_enumindex()
            endif
         next
      endif

   ENDIF
RETURN Nil
/*
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
*/
METHOD AddButton(nBitIp,nId,bState,bStyle,cText,bClick,c,aMenu) CLASS hToolBar
   Local hMenu := Nil
   DEFAULT nBitIp to -1
   DEFAULT bstate to TBSTATE_ENABLED
   DEFAULT bstyle to 0x0000
   DEFAULT c to ""
   DEFAULT ctext to ""
   AAdd( ::aItem ,{ nBitIp, nId, bState, bStyle, 0, cText, bClick, c, aMenu, hMenu ,0} )
RETURN Self

METHOD onEvent( msg, wParam, lParam )  CLASS HToolbar
Local nPos
   IF msg == WM_LBUTTONUP
      nPos := ascan(::aItem,{|x| x[2] == wParam})
      if nPos>0
         IF ::aItem[nPos,7] != Nil
            Eval( ::aItem[nPos,7] ,Self )
         ENDIF
      endif
   ENDIF
Return  NIL

METHOD REFRESH() class htoolbar
   if ::lInit
      ::lInit := .f.
   endif
   ::init()
return nil

METHOD EnableAllButtons() class htoolbar
   Local xItem
   For Each xItem in ::aItem
      EnableWindow( xItem[ 11 ], .T. )
   Next
RETURN Self

METHOD DisableAllButtons() class htoolbar
   Local xItem
   For Each xItem in ::aItem
      EnableWindow( xItem[ 11 ], .F. )
   Next
RETURN Self

METHOD EnableButtons(n) class htoolbar
   EnableWindow( ::aItem[n, 11 ], .T. )
RETURN Self

METHOD DisableButtons(n) class htoolbar
   EnableWindow( ::aItem[n, 11 ], .T. )
RETURN Self
