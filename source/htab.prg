/*
 *$Id: htab.prg,v 1.21 2006-11-14 13:38:56 lculik Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HTab class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"
#define TCM_SETCURSEL           4876     // (TCM_FIRST + 12)
#define TCM_SETCURFOCUS         4912     // (TCM_FIRST + 48)
#define TCM_GETCURFOCUS         4911     // (TCM_FIRST + 47)
#define TCM_GETITEMCOUNT        4868     // (TCM_FIRST + 4)

#define TCM_SETIMAGELIST        4867
//- HTab

CLASS HTab INHERIT HControl

   CLASS VAR winclass   INIT "SysTabControl32"
   DATA  aTabs
   DATA  aPages  INIT {}
   DATA  bChange, bChange2
   DATA  hIml, aImages, Image1, Image2
   DATA  oTemp
   DATA  bAction
   DATA  lResourceTab INIT .F.

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  oFont,bInit,bSize,bPaint,aTabs,bChange,aImages,lResour,nBC,;
                  bClick, bGetFocus, bLostFocus )
   METHOD Activate()
   METHOD Init()
   METHOD SetTab( n )
   METHOD StartPage( cname, oDlg )
   METHOD EndPage()
   METHOD ChangePage( nPage )
   METHOD DeletePage( nPage )
   METHOD HidePage( nPage )
   METHOD ShowPage( nPage )
   METHOD GetActivePage( nFirst,nEnd )
   METHOD Notify( lParam )
//   METHOD OnEvent(msg,wParam,lParam)
   METHOD Redefine( oWndParent,nId,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp )

   HIDDEN:
     DATA  nActive  INIT 0         // Active Page

ENDCLASS

METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  oFont,bInit,bSize,bPaint,aTabs,bChange,aImages,lResour,nBC,bClick, bGetFocus, bLostFocus  ) CLASS HTab
LOCAL i, aBmpSize

   nStyle   := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), WS_CHILD+WS_VISIBLE+WS_TABSTOP )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint )

   ::title   := ""
   ::oFont   := Iif( oFont==Nil, ::oParent:oFont, oFont )
   ::aTabs   := Iif( aTabs==Nil,{},aTabs )
   ::bChange := bChange
   ::bChange2 := bChange

   ::bGetFocus :=IIf( bGetFocus==Nil, Nil, bGetFocus)
   ::bLostFocus:=IIf( bLostFocus==Nil, Nil, bLostFocus)
   ::bAction   :=IIf( bClick==Nil, Nil, bClick)

   IF aImages != Nil
      ::aImages := {}
      FOR i := 1 TO Len( aImages )
         Aadd( ::aImages, Upper(aImages[i]) )
         aImages[i] := Iif( lResour,LoadBitmap( aImages[i] ),OpenBitmap( aImages[i] ) )
      NEXT
      aBmpSize := GetBitmapSize( aImages[1] )
      ::himl := CreateImageList( aImages,aBmpSize[1],aBmpSize[2],12,nBC )
      ::Image1 := 0
      IF Len( aImages ) > 1
         ::Image2 := 1
      ENDIF
   ENDIF

   ::Activate()

Return Self

METHOD Activate CLASS HTab
   IF ::oParent:handle != 0
      ::handle := CreateTabControl( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
Return Nil

METHOD Init() CLASS HTab
Local i

   IF !::lInit
      Super:Init()
      InitTabControl( ::handle,::aTabs,IF( ::himl != Nil,::himl,0 ))
      ::nHolder := 1
      SetWindowObject( ::handle,Self )

      IF ::himl != Nil
         SendMessage( ::handle, TCM_SETIMAGELIST, 0, ::himl )
      ENDIF

      FOR i := 2 TO Len( ::aPages )
         ::HidePage( i )
      NEXT
      Hwg_InitTabProc( ::handle )
   ENDIF

Return Nil

METHOD SetTab( n ) CLASS HTab
   SendMessage( ::handle, TCM_SETCURFOCUS, n-1, 0 )
   // writelog( str(::handle )+" "+Str(SendMessage(::handle,TCM_GETCURFOCUS,0,0 ))+" "+Str(SendMessage(::handle,TCM_GETITEMCOUNT,0,0 )) )
Return Nil

METHOD StartPage( cname,oDlg ) CLASS HTab

   ::oTemp := ::oDefaultParent
   ::oDefaultParent := Self

   IF Len( ::aTabs ) > 0 .AND. Len( ::aPages ) == 0
      ::aTabs := {}
   ENDIF
   Aadd( ::aTabs,cname )
   if ::lResourceTab
      Aadd( ::aPages, { oDlg ,0 } )
   else
      Aadd( ::aPages, { Len( ::aControls ),0 } )
   endif
   ::nActive := Len( ::aPages )

Return Nil

METHOD EndPage() CLASS HTab
   if !::lResourceTab   
      ::aPages[ ::nActive,2 ] := Len( ::aControls ) - ::aPages[ ::nActive,1 ]
      IF ::handle != Nil .AND. ::handle > 0
         AddTab( ::handle,::nActive,::aTabs[::nActive] )
      ENDIF
      IF ::nActive > 1 .AND. ::handle != Nil .AND. ::handle > 0
         ::HidePage( ::nActive )
      ENDIF
      ::nActive := 1

      ::oDefaultParent := ::oTemp
      ::oTemp := Nil

      ::bChange = {|o,n|o:ChangePage(n)}
   else
//      ::aPages[ ::nActive,2 ] := Len( ::aControls ) - ::aPages[ ::nActive,1 ]
   IF ::handle != Nil .AND. ::handle > 0
//         AddTab( ::handle,::nActive,::aTabs[::nActive] )
         ADDTABDIALOG(::handle,::nActive,::aTabs[::nActive],::aPages[::nactive,1]:handle)
//         aadd(::aControls,::aPages[::nactive,1])
   ENDIF
   IF ::nActive > 1 .AND. ::handle != Nil .AND. ::handle > 0
      ::HidePage( ::nActive )
   ENDIF
   ::nActive := 1

   ::oDefaultParent := ::oTemp
   ::oTemp := Nil

   ::bChange = {|o,n|o:ChangePage(n)}
   endif

Return Nil

METHOD ChangePage( nPage ) CLASS HTab

   IF !Empty( ::aPages )

      ::HidePage( ::nActive )

      ::nActive := nPage

      ::ShowPage( ::nActive )

   ENDIF

   IF ::bChange2 != Nil
      Eval( ::bChange2,Self,nPage )
   ENDIF

Return Nil

METHOD HidePage( nPage ) CLASS HTab
Local i, nFirst, nEnd
   if !::lResourceTab
   nFirst := ::aPages[ nPage,1 ] + 1
   nEnd   := ::aPages[ nPage,1 ] + ::aPages[ nPage,2 ]
   FOR i := nFirst TO nEnd
      ::aControls[i]:Hide()
   NEXT
   else
      ::aPages[nPage,1]:Hide()
   endif

Return Nil

METHOD ShowPage( nPage ) CLASS HTab
Local i, nFirst, nEnd

   if !::lResourceTab
   nFirst := ::aPages[ nPage,1 ] + 1
   nEnd   := ::aPages[ nPage,1 ] + ::aPages[ nPage,2 ]
   FOR i := nFirst TO nEnd
      ::aControls[i]:Show()
   NEXT
   FOR i := nFirst TO nEnd
      IF __ObjHasMsg( ::aControls[i],"BSETGET" ) .AND. ::aControls[i]:bSetGet != Nil
         SetFocus( ::aControls[i]:handle )
         Exit
      ENDIF
   NEXT
   else
      ::aPages[nPage,1]:show()
      for i :=1  to len(::aPages[nPage,1]:aControls)
         Tracelog(::aPages[nPage,1]:aControls,::aPages[nPage,1]:aControls[i])
         IF __ObjHasMsg( ::aPages[nPage,1]:aControls[i],"BSETGET" ) .AND. ::aPages[nPage,1]:aControls[i]:bSetGet != Nil
            SetFocus( ::aPages[nPage,1]:aControls[i]:handle )
            Exit
         ENDIF

      next
   endif

Return Nil

METHOD GetActivePage( nFirst,nEnd ) CLASS HTab
if !::lResourceTab
   IF !Empty( ::aPages )
      nFirst := ::aPages[ ::nActive,1 ] + 1
      nEnd   := ::aPages[ ::nActive,1 ] + ::aPages[ ::nActive,2 ]
   ELSE
      nFirst := 1
      nEnd   := Len( ::aControls )
   ENDIF
endif

Return ::nActive

METHOD DeletePage( nPage ) CLASS HTab
  if ::lResourceTab
     aDel(::m_arrayStatusTab,nPage,,.t.)
     DeleteTab( ::handle, nPage )
     ::nActive := nPage - 1

  else
   DeleteTab( ::handle, nPage-1 )

   Adel( ::aPages, nPage )

   Asize( ::aPages, len( ::aPages ) - 1 )

   IF nPage > 1
      ::nActive := nPage - 1
      ::SetTab( ::nActive )
   ELSEIF Len( ::aPages ) > 0
      ::nActive := 1
      ::SetTab( 1 )
   ENDIF
  endif

Return ::nActive

METHOD Notify( lParam ) CLASS HTab
Local nCode := GetNotifyCode( lParam )

   DO CASE
      CASE nCode == TCN_SELCHANGE
         IF ::bChange != Nil
            Eval( ::bChange, Self, GetCurrentTab( ::handle ) )
         ENDIF
      CASE nCode == TCN_CLICK
           IF ::bAction != Nil
              Eval( ::bAction, Self, GetCurrentTab( ::handle ) )
           ENDIF
      CASE nCode == TCN_SETFOCUS
           IF ::bGetFocus != NIL
              Eval( ::bGetFocus, Self, GetCurrentTab( ::handle ) )
           ENDIF
      CASE nCode == TCN_KILLFOCUS
           IF ::bLostFocus != NIL
              Eval( ::bLostFocus, Self, GetCurrentTab( ::handle ) )
           ENDIF
   ENDCASE

Return -1

METHOD Redefine( oWndParent,nId,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp,aItem )  CLASS hTab

   Super:New( oWndParent,nId,0,0,0,0,0,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )
   HWG_InitCommonControlsEx()
   ::lResourceTab := .T.
   ::aTabs  := {}
   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
Return Self

//METHOD OnEvent(msg,wParam,lParam)
//if msg == WM_PAINT
//   return -1
//elseif msg == WM_COMMAND
//   SendMessage(::aPages[::nactive,1]:handle,msg,wParam,lParam)
//endif
//return -1
