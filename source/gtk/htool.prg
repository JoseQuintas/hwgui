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
   DATA lVertical  INIT .F.
   DATA lFlat
   DATA nOrder
   Data aItem init {}
   DATA Line

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp,lVertical,aItem)

   METHOD Activate()
   METHOD INIT()
   METHOD REFRESH()
   METHOD AddButton(nBitIp,nId,bState,bStyle,cText,bClick,c,aMenu)  && a,s,d,f,g,h
   METHOD onEvent( msg, wParam, lParam )
   METHOD EnableAllButtons()
   METHOD DisableAllButtons()
   METHOD EnableButtons(n)
   METHOD DisableButtons(n)



ENDCLASS

/* Added: lVertical */
METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, ;
                  bSize, bPaint, ctooltip, tcolor, bcolor, lTransp , lVertical, aItem ) CLASS hToolBar

   * Parameters not used
   HB_SYMBOL_UNUSED(cCaption)
   HB_SYMBOL_UNUSED(lTransp)   

   Default  aItem to {}
   ::Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )

   ::aItem := aItem
   ::lVertical := IIF( lVertical != NIL .AND. VALTYPE( lVertical ) = "L", lVertical, ::lVertical )

   ::Activate()

Return Self

METHOD Activate() CLASS hToolBar
   IF !empty(::oParent:handle )

      ::handle := hwg_Createtoolbar(::oParent:handle )
      hwg_Setwindowobject( ::handle,Self )
      ::Init()
   ENDIF
RETURN Nil

METHOD INIT() CLASS hToolBar
Local n
Local aButton := {}
Local oImage
Local aItem
* Variables not used
* Local n1
* Local aTemp
* Local hIm
* Local aBmpSize
* Local nPos

   IF !::lInit
      ::Super:Init()
      For n := 1 TO len( ::aItem )

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

      if len( ::aItem ) >0
         For Each aItem in ::aItem

            if aItem[4] == TBSTYLE_BUTTON

               aItem[11] := hwg_Createtoolbarbutton(::handle,aItem[1],aItem[6],.f.)
               #ifdef __XHARBOUR__
               aItem[2] := hb_enumindex()
               #else
               aItem[2] := aItem:__enumIndex()
               #endif
               hwg_Toolbar_setaction(aItem[11],aItem[7])
               if !empty(aItem[8])
                  hwg_Addtooltip(::handle, aItem[11],aItem[8])
               endif
            elseif aitem[4] == TBSTYLE_SEP
               aItem[11] := hwg_Createtoolbarbutton(::handle,,,.t.)
               #ifdef __XHARBOUR__
               aItem[2] := hb_enumindex()
               #else
               aItem[2] := aItem:__enumIndex()
               #endif
            endif
         next
      endif

   ENDIF
RETURN Nil

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

   * Parameters not used
   HB_SYMBOL_UNUSED(lParam)

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
      hwg_Enablewindow( xItem[ 11 ], .T. )
   Next
RETURN Self

METHOD DisableAllButtons() class htoolbar
   Local xItem
   For Each xItem in ::aItem
      hwg_Enablewindow( xItem[ 11 ], .F. )
   Next
RETURN Self

METHOD EnableButtons(n) class htoolbar
   hwg_Enablewindow( ::aItem[n, 11 ], .T. )
RETURN Self

METHOD DisableButtons(n) class htoolbar
   hwg_Enablewindow( ::aItem[n, 11 ], .T. )
RETURN Self

* ================================== EOF of htool.prg ==================================
