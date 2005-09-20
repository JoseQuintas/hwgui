/*
 *$Id: htab.prg,v 1.18 2005-09-20 10:09:12 alkresin Exp $
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

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  oFont,bInit,bSize,bPaint,aTabs,bChange,aImages,lResour,nBC,;
                  bClick, bGetFocus, bLostFocus )
   METHOD Activate()
   METHOD Init()
   METHOD SetTab( n )
   METHOD StartPage( cname )
   METHOD EndPage()
   METHOD ChangePage( nPage )
   METHOD DeletePage( nPage )
   METHOD HidePage( nPage )
   METHOD ShowPage( nPage )
   METHOD GetActivePage( nFirst,nEnd )

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

METHOD StartPage( cname ) CLASS HTab

   ::oTemp := ::oDefaultParent
   ::oDefaultParent := Self

   IF Len( ::aTabs ) > 0 .AND. Len( ::aPages ) == 0
      ::aTabs := {}
   ENDIF
   Aadd( ::aTabs,cname )

   Aadd( ::aPages, { Len( ::aControls ),0 } )
   ::nActive := Len( ::aPages )

Return Nil

METHOD EndPage() CLASS HTab

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

   nFirst := ::aPages[ nPage,1 ] + 1
   nEnd   := ::aPages[ nPage,1 ] + ::aPages[ nPage,2 ]
   FOR i := nFirst TO nEnd
      ::aControls[i]:Hide()
   NEXT

Return Nil

METHOD ShowPage( nPage ) CLASS HTab
Local i, nFirst, nEnd

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

Return Nil

METHOD GetActivePage( nFirst,nEnd ) CLASS HTab

   IF !Empty( ::aPages )
      nFirst := ::aPages[ ::nActive,1 ] + 1
      nEnd   := ::aPages[ ::nActive,1 ] + ::aPages[ ::nActive,2 ]
   ELSE
      nFirst := 1
      nEnd   := Len( ::aControls )
   ENDIF

Return ::nActive

METHOD DeletePage( nPage ) CLASS HTab

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

Return ::nActive

