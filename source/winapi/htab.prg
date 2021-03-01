/*
 *$Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HTab class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

CLASS HTab INHERIT HControl

   CLASS VAR winclass   INIT "SysTabControl32"
   DATA  aTabs
   DATA  aPages  INIT {}
   DATA  bChange, bChange2
   DATA  hIml, aImages, Image1, Image2
   DATA  oTemp
   DATA  bAction
   DATA  lResourceTab INIT .F.

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, aTabs, bChange, aImages, lResour, nBC, ;
      bClick, bGetFocus, bLostFocus )
   METHOD Activate()
   METHOD Init()
   //METHOD onEvent( msg, wParam, lParam )
   METHOD SetTab( n )
   METHOD StartPage( cName, oDlg )
   METHOD EndPage()
   METHOD ChangePage( nPage )
   METHOD DeletePage( nPage )
   METHOD HidePage( nPage )
   METHOD ShowPage( nPage )
   METHOD GetActivePage( nFirst, nEnd )
   METHOD Notify( lParam )
   METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aItem )

   HIDDEN:
   DATA  nActive  INIT 0         // Active Page

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, aTabs, bChange, aImages, lResour, nBC, bClick, bGetFocus, bLostFocus  ) CLASS HTab
   LOCAL i, aBmpSize

   nStyle   := Hwg_BitOr( iif( nStyle == Nil,0,nStyle ), WS_CHILD + WS_VISIBLE + WS_TABSTOP )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize, bPaint )

   ::title   := ""
   ::oFont   := iif( oFont == Nil, ::oParent:oFont, oFont )
   ::aTabs   := iif( aTabs == Nil, {}, aTabs )
   ::bChange := bChange
   ::bChange2 := bChange

   ::bGetFocus := iif( bGetFocus == Nil, Nil, bGetFocus )
   ::bLostFocus := iif( bLostFocus == Nil, Nil, bLostFocus )
   ::bAction   := iif( bClick == Nil, Nil, bClick )

   IF aImages != Nil
      ::aImages := {}
      FOR i := 1 TO Len( aImages )
         AAdd( ::aImages, Upper( aImages[i] ) )
         aImages[i] := iif( lResour, hwg_Loadbitmap( aImages[i] ), hwg_Openbitmap( aImages[i] ) )
      NEXT
      aBmpSize := hwg_Getbitmapsize( aImages[1] )
      ::himl := hwg_Createimagelist( aImages, aBmpSize[1], aBmpSize[2], 12, nBC )
      ::Image1 := 0
      IF Len( aImages ) > 1
         ::Image2 := 1
      ENDIF
   ENDIF

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HTab

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createtabcontrol( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN Nil

METHOD Init() CLASS HTab
   LOCAL i

   IF !::lInit
      ::Super:Init()
      hwg_Inittabcontrol( ::handle, ::aTabs, IF( ::himl != Nil,::himl,0 ) )
      ::nHolder := 1
      hwg_Setwindowobject( ::handle, Self )

      IF ::himl != Nil
         hwg_Sendmessage( ::handle, TCM_SETIMAGELIST, 0, ::himl )
      ENDIF

      FOR i := 2 TO Len( ::aPages )
         ::HidePage( i )
      NEXT
      Hwg_InitTabProc( ::handle )
   ENDIF

   RETURN Nil
/*
METHOD onEvent( msg, wParam, lParam ) CLASS HTab

   LOCAL iParHigh, iParLow, nPos

   IF msg == WM_COMMAND
      IF ::aEvents != Nil
         iParHigh := hwg_Hiword( wParam )
         iParLow  := hwg_Loword( wParam )
         IF ( nPos := Ascan( ::aEvents, { |a|a[1] == iParHigh .AND. a[2] == iParLow } ) ) > 0
            Eval( ::aEvents[ nPos,3 ], Self, iParLow )
         ENDIF
      ENDIF
   ENDIF

   Return - 1
*/
METHOD SetTab( n ) CLASS HTab

   hwg_Sendmessage( ::handle, TCM_SETCURFOCUS, n - 1, 0 )

   RETURN Nil

METHOD StartPage( cname, oDlg ) CLASS HTab

   ::oTemp := ::oDefaultParent
   ::oDefaultParent := Self

   IF Len( ::aTabs ) > 0 .AND. Len( ::aPages ) == 0
      ::aTabs := {}
   ENDIF
   AAdd( ::aTabs, cname )
   if ::lResourceTab
      AAdd( ::aPages, { oDlg , 0 } )
   ELSE
      AAdd( ::aPages, { Len( ::aControls ), 0 } )
   ENDIF
   IF ::nActive > 1 .AND. !Empty( ::handle )
      ::HidePage( ::nActive )
   ENDIF
   ::nActive := Len( ::aPages )

   RETURN Nil

METHOD EndPage() CLASS HTab

   IF !::lResourceTab
      ::aPages[ ::nActive,2 ] := Len( ::aControls ) - ::aPages[ ::nActive,1 ]
      IF !Empty( ::handle )
         hwg_Addtab( ::handle, ::nActive, ::aTabs[::nActive] )
      ENDIF
   ELSE
      IF !Empty( ::handle != Nil )
         hwg_Addtabdialog( ::handle, ::nActive, ::aTabs[::nActive], ::aPages[::nactive,1]:handle )
      ENDIF
   ENDIF

   IF ::nActive > 1 .AND. !Empty( ::handle )
      ::HidePage( ::nActive )
   ENDIF
   ::nActive := 1

   ::oDefaultParent := ::oTemp
   ::oTemp := Nil

   ::bChange = { |o, n|o:ChangePage( n ) }

   RETURN Nil

METHOD ChangePage( nPage ) CLASS HTab

   IF !Empty( ::aPages )

      ::HidePage( ::nActive )

      ::nActive := nPage

      ::ShowPage( ::nActive )

   ENDIF

   IF ::bChange2 != Nil
      Eval( ::bChange2, Self, nPage )
   ENDIF

   RETURN Nil

METHOD HidePage( nPage ) CLASS HTab
   LOCAL i, nFirst, nEnd

   IF !::lResourceTab
      nFirst := ::aPages[ nPage,1 ] + 1
      nEnd   := ::aPages[ nPage,1 ] + ::aPages[ nPage,2 ]
      FOR i := nFirst TO nEnd
         ::aControls[i]:Hide()
      NEXT
   ELSE
      ::aPages[nPage,1]:Hide()
   ENDIF

   RETURN Nil

METHOD ShowPage( nPage ) CLASS HTab
   LOCAL i, nFirst, nEnd

   IF !::lResourceTab
      nFirst := ::aPages[ nPage,1 ] + 1
      nEnd   := ::aPages[ nPage,1 ] + ::aPages[ nPage,2 ]
      FOR i := nFirst TO nEnd
         ::aControls[i]:Show()
      NEXT
      FOR i := nFirst TO nEnd
         IF __ObjHasMsg( ::aControls[i], "BSETGET" ) .AND. ::aControls[i]:bSetGet != Nil
            hwg_Setfocus( ::aControls[i]:handle )
            EXIT
         ENDIF
      NEXT
   ELSE
      ::aPages[nPage,1]:Show()
      FOR i := 1  TO Len( ::aPages[nPage,1]:aControls )
         IF __ObjHasMsg( ::aPages[nPage,1]:aControls[i], "BSETGET" ) .AND. ::aPages[nPage,1]:aControls[i]:bSetGet != Nil
            hwg_Setfocus( ::aPages[nPage,1]:aControls[i]:handle )
            EXIT
         ENDIF
      NEXT
   ENDIF

   RETURN Nil

METHOD GetActivePage( nFirst, nEnd ) CLASS HTab

   IF !::lResourceTab
      IF !Empty( ::aPages )
         nFirst := ::aPages[ ::nActive,1 ] + 1
         nEnd   := ::aPages[ ::nActive,1 ] + ::aPages[ ::nActive,2 ]
      ELSE
         nFirst := 1
         nEnd   := Len( ::aControls )
      ENDIF
   ENDIF

   Return ::nActive

METHOD DeletePage( nPage ) CLASS HTab
Local nFirst, nEnd, i

   if ::lResourceTab
      ADel( ::m_arrayStatusTab, nPage, , .T. )
      hwg_Deletetab( ::handle, nPage )
      ::nActive := nPage - 1

   ELSE

      nFirst := ::aPages[ nPage,1 ] + 1
      nEnd   := ::aPages[ nPage,1 ] + ::aPages[ nPage,2 ]
      FOR i := nEnd TO nFirst STEP -1
         ::DelControl( ::aControls[i] )
      NEXT
      FOR i := nPage + 1 TO Len( ::aPages )
         ::aPages[ i,1 ] -= ( nEnd-nFirst+1 )
      NEXT

      hwg_Deletetab( ::handle, nPage - 1 )

      ADel( ::aPages, nPage )
      ASize( ::aPages, Len( ::aPages ) - 1 )

      ADel( :: aTabs, nPage )
      ASize( :: aTabs, Len( :: aTabs) - 1 )

      IF nPage > 1
         ::nActive := nPage - 1
         ::SetTab( ::nActive )
      ELSEIF Len( ::aPages ) > 0
         ::nActive := 1
         ::SetTab( 1 )
      ENDIF
   ENDIF

   Return ::nActive

METHOD Notify( lParam ) CLASS HTab
   LOCAL nCode := hwg_Getnotifycode( lParam )

   //hwg_writelog( str(ncode) )
   DO CASE
   CASE nCode == TCN_SELCHANGE
      IF ::bChange != Nil
         Eval( ::bChange, Self, hwg_Getcurrenttab( ::handle ) )
      ENDIF
   CASE nCode == TCN_CLICK
      IF ::bAction != Nil
         Eval( ::bAction, Self, hwg_Getcurrenttab( ::handle ) )
      ENDIF
   CASE nCode == TCN_SETFOCUS
      IF ::bGetFocus != NIL
         Eval( ::bGetFocus, Self, hwg_Getcurrenttab( ::handle ) )
      ENDIF
   CASE nCode == TCN_KILLFOCUS
      IF ::bLostFocus != NIL
         Eval( ::bLostFocus, Self, hwg_Getcurrenttab( ::handle ) )
      ENDIF
   ENDCASE

   Return - 1

/* aItem and cCaption added */
METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aItem )  CLASS hTab

     * Parameters not used
    HB_SYMBOL_UNUSED(cCaption)
    HB_SYMBOL_UNUSED(lTransp)
    HB_SYMBOL_UNUSED(aItem)
  

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor )
   HWG_InitCommonControlsEx()
   ::lResourceTab := .T.
   ::aTabs := {}
   ::style := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0

   RETURN Self

* ============================ EOF of htab.prg ===========================
