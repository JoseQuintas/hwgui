/*
 *$Id: htab.prg,v 1.4 2005-10-21 08:50:15 alkresin Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HTab class
 *
 * Copyright 2005 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "hwgui.ch"
#include "hbclass.ch"

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
   METHOD HidePage( nPage )
   METHOD ShowPage( nPage )
   METHOD GetActivePage( nFirst,nEnd )

   HIDDEN:
     DATA  nActive  INIT 0         // Active Page

ENDCLASS

METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  oFont,bInit,bSize,bPaint,aTabs,bChange,aImages,lResour,nBC,bClick, bGetFocus, bLostFocus  ) CLASS HTab
LOCAL i, aBmpSize

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

   ::Activate()

Return Self

METHOD Activate CLASS HTab

   IF !Empty(::oParent:handle )
      ::handle := CreateTabControl( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
Return Nil

METHOD Init() CLASS HTab
Local i, h

   IF !::lInit
      Super:Init()
      FOR i := 1 TO Len( ::aTabs )
         h := AddTab( ::handle, ::aTabs[i] )
	 Aadd( ::aPages, { 0,0,.F.,h } )
      NEXT
      
      ::nHolder := 1
      SetWindowObject( ::handle,Self )

      FOR i := 2 TO Len( ::aPages )
         ::HidePage( i )
      NEXT
   ENDIF

Return Nil

METHOD SetTab( n ) CLASS HTab
   SendMessage( ::handle, TCM_SETCURFOCUS, n-1, 0 )
Return Nil

METHOD StartPage( cname ) CLASS HTab
Local i := Iif( cName==Nil, Len(::aPages)+1, Ascan( ::aTabs,cname ) )
Local lNew := ( i == 0 )

   ::oTemp := ::oDefaultParent
   ::oDefaultParent := Self
   IF lNew
      Aadd( ::aTabs,cname )
      i := Len( ::aTabs )
   ENDIF
   DO WHILE Len( ::aPages ) < i
      Aadd( ::aPages, { Len( ::aControls ),0,lNew,0 } )
   ENDDO
   ::nActive := i
   ::aPages[ i,4 ] := AddTab( ::handle,::aTabs[i] )

Return Nil

METHOD EndPage() CLASS HTab

   ::aPages[ ::nActive,2 ] := Len( ::aControls ) - ::aPages[ ::nActive,1 ]
   IF ::nActive > 1 .AND. ::handle != Nil .AND. !Empty( ::handle )
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

