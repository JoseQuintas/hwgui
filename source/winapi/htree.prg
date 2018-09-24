/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HTree class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define TVM_DELETEITEM       4353   // (TV_FIRST + 1) 0x1101
#define TVM_EXPAND           4354   // (TV_FIRST + 2)
#define TVM_SETIMAGELIST     4361   // (TV_FIRST + 9)
#define TVM_GETNEXTITEM      4362   // (TV_FIRST + 10)
#define TVM_SELECTITEM       4363   // (TV_FIRST + 11)
#define TVM_EDITLABEL        4366   // (TV_FIRST + 14)

#define TVE_COLLAPSE            0x0001
#define TVE_EXPAND              0x0002
#define TVE_TOGGLE              0x0003

#define TVSIL_NORMAL            0

#define TVS_HASBUTTONS          1   // 0x0001
#define TVS_HASLINES            2   // 0x0002
#define TVS_LINESATROOT         4   // 0x0004
#define TVS_EDITLABELS          8   // 0x0008
#define TVS_DISABLEDRAGDROP    16   // 0x0010
#define TVS_SHOWSELALWAYS      32   // 0x0020
#define TVS_RTLREADING         64   // 0x0040
#define TVS_NOTOOLTIPS        128   // 0x0080
#define TVS_CHECKBOXES        256   // 0x0100
#define TVS_TRACKSELECT       512   // 0x0200
#define TVS_SINGLEEXPAND     1024   // 0x0400
#define TVS_INFOTIP          2048   // 0x0800
#define TVS_FULLROWSELECT    4096   // 0x1000
#define TVS_NOSCROLL         8192   // 0x2000
#define TVS_NONEVENHEIGHT   16384   // 0x4000
#define TVS_NOHSCROLL       32768   // 0x8000  // TVS_NOSCROLL overrides this

#define TVGN_ROOT               0   // 0x0000
#define TVGN_NEXT               1   // 0x0001
#define TVGN_PREVIOUS           2   // 0x0002
#define TVGN_PARENT             3   // 0x0003
#define TVGN_CHILD              4   // 0x0004
#define TVGN_FIRSTVISIBLE       5   // 0x0005
#define TVGN_NEXTVISIBLE        6   // 0x0006
#define TVGN_PREVIOUSVISIBLE    7   // 0x0007
#define TVGN_DROPHILITE         8   // 0x0008
#define TVGN_CARET              9   // 0x0009
#define TVGN_LASTVISIBLE       10   // 0x000A

#define TVN_SELCHANGED       ( - 402 )
#define TVN_ITEMEXPANDING    ( - 405 )
#define TVN_BEGINLABELEDIT   ( - 410 )
#define TVN_ENDLABELEDIT     ( - 411 )

#define TVN_SELCHANGEDW       ( - 451 )
#define TVN_ITEMEXPANDINGW    ( - 454 )
#define TVN_BEGINLABELEDITW   ( - 459 )
#define TVN_ENDLABELEDITW     ( - 460 )

#define TVI_ROOT             ( - 65536 )

#define TREE_GETNOTIFY_HANDLE       1
#define TREE_GETNOTIFY_PARAM        2
#define TREE_GETNOTIFY_EDIT         3
#define TREE_GETNOTIFY_EDITPARAM    4
#define TREE_GETNOTIFY_ACTION       5

#define TREE_SETITEM_TEXT           1

CLASS HTreeNode INHERIT HObject

   DATA handle
   DATA oTree, oParent
   DATA aItems INIT { }
   DATA bClick

   METHOD New( oTree, oParent, oPrev, oNext, cTitle, bClick, aImages )
   METHOD AddNode( cTitle, oPrev, oNext, bClick, aImages )
   METHOD Delete()
   METHOD FindChild( h )
   METHOD GetText()  INLINE hwg_Treegetnodetext( ::oTree:handle, ::handle )
   METHOD SetText( cText ) INLINE hwg_Treesetitem( ::oTree:handle, ::handle, TREE_SETITEM_TEXT, cText )

ENDCLASS

METHOD New( oTree, oParent, oPrev, oNext, cTitle, bClick, aImages ) CLASS HTreeNode
   LOCAL aItems, i, h, im1, im2, cImage, op, nPos

   ::oTree := oTree
   ::oParent := oParent
   ::bClick := bClick

   IF aImages == Nil
      IF oTree:Image1 != Nil
         im1 := oTree:Image1
         IF oTree:Image2 != Nil
            im2 := oTree:Image2
         ENDIF
      ENDIF
   ELSE
      FOR i := 1 TO Len( aImages )
         cImage := Upper( aImages[ i ] )
         IF ( h := AScan( oTree:aImages, cImage ) ) == 0
            AAdd( oTree:aImages, cImage )
            aImages[ i ] := IIf( oTree:Type, hwg_BmpFromRes( aImages[ i ] ), hwg_Openbitmap( AddPath( aImages[i],HBitmap():cPath ) ) )
            hwg_Imagelist_add( oTree:himl, aImages[ i ] )
            h := Len( oTree:aImages )
         ENDIF
         h --
         IF i == 1
            im1 := h
         ELSE
            im2 := h
         ENDIF
      NEXT
   ENDIF
   IF im2 == Nil
      im2 := im1
   ENDIF

   nPos := IIf( oPrev == Nil, 2, 0 )
   IF oPrev == Nil .AND. oNext != Nil
      op := IIf( oNext:oParent == Nil, oNext:oTree, oNext:oParent )
      FOR i := 1 TO Len( op:aItems )
         IF op:aItems[ i ]:handle == oNext:handle
            EXIT
         ENDIF
      NEXT
      IF i > 1
         oPrev := op:aItems[ i - 1 ]
         nPos := 0
      ELSE
         nPos := 1
      ENDIF
   ENDIF
   ::handle := hwg_Treeaddnode( Self, oTree:handle,               ;
                            IIf( oParent == Nil, Nil, oParent:handle ), ;
                            IIf( oPrev == Nil, Nil, oPrev:handle ), nPos, cTitle, im1, im2 )

   aItems := IIf( oParent == Nil, oTree:aItems, oParent:aItems )
   IF nPos == 2
      AAdd( aItems, Self )
   ELSEIF nPos == 1
      AAdd( aItems, Nil )
      AIns( aItems, 1 )
      aItems[ 1 ] := Self
   ELSE
      AAdd( aItems, Nil )
      h := oPrev:handle
      IF ( i := AScan( aItems, { | o | o:handle == h } ) ) == 0
         aItems[ Len( aItems ) ] := Self
      ELSE
         AIns( aItems, i + 1 )
         aItems[ i + 1 ] := Self
      ENDIF
   ENDIF

   RETURN Self

METHOD AddNode( cTitle, oPrev, oNext, bClick, aImages ) CLASS HTreeNode
   LOCAL oParent := Self
   LOCAL oNode := HTreeNode():New( ::oTree, oParent, oPrev, oNext, cTitle, bClick, aImages )

   RETURN oNode

METHOD Delete( lInternal ) CLASS HTreeNode
   LOCAL h := ::handle, j, alen, aItems

   IF ! Empty( ::aItems )
      alen := Len( ::aItems )
      FOR j := 1 TO alen
         ::aItems[ j ]:Delete( .T. )
         ::aItems[ j ] := Nil
      NEXT
   ENDIF
   hwg_Treereleasenode( ::oTree:handle, ::handle )
   hwg_Sendmessage( ::oTree:handle, TVM_DELETEITEM, 0, ::handle )
   IF lInternal == Nil
      aItems := IIf( ::oParent == Nil, ::oTree:aItems, ::oParent:aItems )
      j := AScan( aItems, { | o | o:handle == h } )
      ADel( aItems, j )
      ASize( aItems, Len( aItems ) - 1 )
   ENDIF
   // hwg_DecreaseHolders( ::handle )

   RETURN Nil

METHOD FindChild( h ) CLASS HTreeNode
   LOCAL aItems := ::aItems, i, alen := Len( aItems ), oNode
   FOR i := 1 TO alen
      IF aItems[ i ]:handle == h
         RETURN aItems[ i ]
      ELSEIF ! Empty( aItems[ i ]:aItems )
         IF ( oNode := aItems[ i ]:FindChild( h ) ) != Nil
            RETURN oNode
         ENDIF
      ENDIF
   NEXT
   RETURN Nil


CLASS HTree INHERIT HControl

CLASS VAR winclass   INIT "SysTreeView32"

   DATA aItems INIT { }
   DATA oSelected
   DATA hIml, aImages, Image1, Image2
   DATA bItemChange, bExpand, bRClick, bDblClick, bClick
   DATA lEmpty INIT .T.

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
               bInit, bSize, color, bcolor, aImages, lResour, lEditLabels, bClick, nBC )
   METHOD Init()
   METHOD Activate()
   METHOD AddNode( cTitle, oPrev, oNext, bClick, aImages )
   METHOD FindChild( h )
   METHOD GetSelected()   INLINE hwg_Treegetselected( ::handle )
   METHOD EditLabel( oNode ) BLOCK { | Self, o | hwg_Sendmessage( ::handle, TVM_EDITLABEL, 0, o:handle ) }
   METHOD Expand( oNode ) BLOCK { | Self, o | hwg_Sendmessage( ::handle, TVM_EXPAND, TVE_EXPAND, o:handle ) }
   METHOD Select( oNode ) BLOCK { | Self, o | hwg_Sendmessage( ::handle, TVM_SELECTITEM, TVGN_CARET, o:handle ) }
   METHOD Clean()
   METHOD Notify( lParam )
   METHOD END()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
            bInit, bSize, color, bcolor, aImages, lResour, lEditLabels, bClick, nBC ) CLASS HTree
   LOCAL i, aBmpSize

   nStyle   := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), WS_CHILD + WS_VISIBLE + ;
                          TVS_HASLINES + TVS_LINESATROOT + TVS_HASBUTTONS + TVS_SHOWSELALWAYS + ;
                          IIf( lEditLabels == Nil.OR. ! lEditLabels, 0, TVS_EDITLABELS ) )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize,,, color, bcolor )

   ::title   := ""
   ::Type    := IIf( lResour == Nil, .F., lResour )
   ::bClick := bClick

   IF aImages != Nil .AND. ! Empty( aImages )
      ::aImages := { }
      FOR i := 1 TO Len( aImages )
         AAdd( ::aImages, Upper( aImages[ i ] ) )
         aImages[ i ] := IIf( lResour <> NIL.and.lResour, hwg_BmpFromRes( aImages[ i ] ), hwg_Openbitmap( AddPath( aImages[i],HBitmap():cPath ) ) )
      NEXT
      aBmpSize := hwg_Getbitmapsize( aImages[ 1 ] )
      ::himl := hwg_Createimagelist( aImages, aBmpSize[ 1 ], aBmpSize[ 2 ], 12, nBC )
      ::Image1 := 0
      IF Len( aImages ) > 1
         ::Image2 := 1
      ENDIF
   ENDIF

   ::Activate()

   RETURN Self

METHOD Init CLASS HTree

   IF ! ::lInit
      ::Super:Init()
      IF ::himl != Nil
         hwg_Sendmessage( ::handle, TVM_SETIMAGELIST, TVSIL_NORMAL, ::himl )
      ENDIF
   ENDIF

   RETURN Nil

METHOD Activate CLASS HTree

   IF ! Empty( ::oParent:handle )
      ::handle := hwg_Createtree( ::oParent:handle, ::id, ;
                              ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::tcolor, ::bcolor )
      ::Init()
   ENDIF

   RETURN Nil

METHOD AddNode( cTitle, oPrev, oNext, bClick, aImages ) CLASS HTree
   LOCAL oNode := HTreeNode():New( Self, Nil, oPrev, oNext, cTitle, bClick, aImages )
   ::lEmpty := .F.
   RETURN oNode

METHOD FindChild( h ) CLASS HTree
   LOCAL aItems := ::aItems, i, alen := Len( aItems ), oNode
   FOR i := 1 TO alen
      IF aItems[ i ]:handle == h
         RETURN aItems[ i ]
      ELSEIF ! Empty( aItems[ i ]:aItems )
         IF ( oNode := aItems[ i ]:FindChild( h ) ) != Nil
            RETURN oNode
         ENDIF
      ENDIF
   NEXT
   RETURN Nil

METHOD Clean() CLASS HTree

   ::lEmpty := .T.
   ReleaseTree( ::aItems )
   hwg_Sendmessage( ::handle, TVM_DELETEITEM, 0, TVI_ROOT )
   ::aItems := { }

   RETURN Nil

METHOD Notify( lParam )  CLASS HTree
   LOCAL nCode := hwg_Getnotifycode( lParam ), oItem, cText, nAct

   IF nCode == TVN_SELCHANGED .OR. nCode == TVN_SELCHANGEDW
      oItem := hwg_Treegetnotify( lParam, TREE_GETNOTIFY_PARAM )
      IF ValType( oItem ) == "O"
         oItem:oTree:oSelected := oItem
         IF ! oItem:oTree:lEmpty
            IF oItem:bClick != Nil
               Eval( oItem:bClick, oItem )
            ELSEIF oItem:oTree:bClick != Nil
               Eval( oItem:oTree:bClick, oItem )
            ENDIF
         ENDIF
      ENDIF
   ELSEIF nCode == TVN_BEGINLABELEDIT .or. nCode == TVN_BEGINLABELEDITW
      // Return 1
   ELSEIF nCode == TVN_ENDLABELEDIT .or. nCode == TVN_ENDLABELEDITW
      IF ! Empty( cText := hwg_Treegetnotify( lParam, TREE_GETNOTIFY_EDIT ) )
         oItem := hwg_Treegetnotify( lParam, TREE_GETNOTIFY_EDITPARAM )
         IF ValType( oItem ) == "O"
            IF cText != oItem:GetText() .AND. ;
               ( oItem:oTree:bItemChange == Nil .OR. Eval( oItem:oTree:bItemChange, oItem, cText ) )
               hwg_Treesetitem( oItem:oTree:handle, oItem:handle, TREE_SETITEM_TEXT, cText )
            ENDIF
         ENDIF
      ENDIF
   ELSEIF nCode == TVN_ITEMEXPANDING .or. nCode == TVN_ITEMEXPANDINGW
      oItem := hwg_Treegetnotify( lParam, TREE_GETNOTIFY_PARAM )
      IF ValType( oItem ) == "O"
         IF ::bExpand != Nil
            RETURN IIf( Eval( oItem:oTree:bExpand, oItem, ;
                              hwg_Checkbit( hwg_Treegetnotify( lParam, TREE_GETNOTIFY_ACTION ), TVE_EXPAND ) ), ;
                        0, 1 )
         ENDIF
      ENDIF
   ELSEIF nCode == - 3
      IF ::bDblClick != Nil
         oItem  := hwg_Treehittest( ::handle,,, @nAct )
         Eval( ::bDblClick, Self, oItem, nAct )
      ENDIF
   ELSEIF nCode == - 5
      IF ::bRClick != Nil
         oItem  := hwg_Treehittest( ::handle,,, @nAct )
         Eval( ::bRClick, Self, oItem, nAct )
      ENDIF
   ENDIF
   RETURN 0

METHOD End() CLASS HTree

   ::Super:End()

   ReleaseTree( ::aItems )
   hwg_DestroyImagelist( ::himl )

   RETURN Nil

STATIC PROCEDURE ReleaseTree( aItems )
   LOCAL i, iLen := Len( aItems )

   FOR i := 1 TO iLen
      hwg_Treereleasenode( aItems[ i ]:oTree:handle, aItems[ i ]:handle )
      ReleaseTree( aItems[ i ]:aItems )
   NEXT

   RETURN

