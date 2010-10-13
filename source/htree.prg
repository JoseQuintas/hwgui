/*
 * $Id: htree.prg,v 1.21 2010-10-13 14:17:30 lfbasso Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HTree class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
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
#define TVM_GETITEMSTATE     4391   // (TV_FIRST + 39)
#define TVM_SETITEM          4426   // (TV_FIRST + 63)
#define TVM_SETITEMHEIGHT    4379   // (TV_FIRST + 27)
#define TVM_GETITEMHEIGHT    4380
   
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

#define TVIS_STATEIMAGEMASK    61440

#define TVN_SELCHANGING      ( - 401 ) // (TVN_FIRST-1)
#define TVN_SELCHANGED       ( - 402 )
#define TVN_GETDISPINFO      ( - 403 )
#define TVN_SETDISPINFO      ( - 404 )
#define TVN_ITEMEXPANDING    ( - 405 )
#define TVN_ITEMEXPANDED     ( - 406 )
#define TVN_BEGINDRAG        ( - 407 ) 
#define TVN_BEGINRDRAG       ( - 408 )
#define TVN_DELETEITEM       ( - 409 )
#define TVN_BEGINLABELEDIT   ( - 410 )
#define TVN_ENDLABELEDIT     ( - 411 )
#define TVN_KEYDOWN          ( - 412 )
#define TVN_ITEMCHANGINGA    ( - 416 )
#define TVN_ITEMCHANGINGW    ( - 417 )
#define TVN_ITEMCHANGEDA     ( - 418 )
#define TVN_ITEMCHANGEDW     ( - 419 ) 


#define TVN_SELCHANGEDW       ( - 451 )
#define TVN_ITEMEXPANDINGW    ( - 454 )
#define TVN_BEGINLABELEDITW   ( - 459 )
#define TVN_ENDLABELEDITW     ( - 460 )

#define TVI_ROOT              ( - 65536 )

#define TREE_GETNOTIFY_HANDLE       1
#define TREE_GETNOTIFY_PARAM        2
#define TREE_GETNOTIFY_EDIT         3
#define TREE_GETNOTIFY_EDITPARAM    4
#define TREE_GETNOTIFY_ACTION       5
#define TREE_GETNOTIFY_OLDPARAM     6

#define TREE_SETITEM_TEXT           1
#define TREE_SETITEM_CHECK          2

//#define  NM_CLICK               - 2
#define  NM_DBLCLK              - 3
#define  NM_RCLICK              - 5
#define  NM_SETCURSOR           - 17    // uses NMMOUSE struct
#define NM_CHAR                 - 18   // uses NMCHAR struct



CLASS HTreeNode INHERIT HObject

   DATA handle
   DATA oTree, oParent
   DATA aItems INIT { }
   DATA bAction, bClick
   DATA cargo
   DATA title
   DATA image1, image2 
   DATA lchecked INIT .F.

   METHOD New( oTree, oParent, oPrev, oNext, cTitle, bAction, aImages, lchecked, bClick )
   METHOD AddNode( cTitle, oPrev, oNext, bAction, aImages )
   METHOD Delete()
   METHOD FindChild( h )
   METHOD GetText()  INLINE TreeGetNodeText( ::oTree:handle, ::handle )
   METHOD SetText( cText ) INLINE TreeSetItem( ::oTree:handle, ::handle, TREE_SETITEM_TEXT, cText ), ::title := cText
   METHOD Checked()  SETGET 

ENDCLASS

METHOD New( oTree, oParent, oPrev, oNext, cTitle, bAction, aImages, lchecked, bClick ) CLASS HTreeNode
   LOCAL aItems, i, h, im1, im2, cImage, op, nPos

   ::oTree    := oTree
   ::oParent  := oParent
   ::Title    := cTitle
   ::bAction  := bAction
   ::bClick   := bClick
   ::lChecked := IIF( lChecked = Nil, .F., lChecked )

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
            aImages[ i ] := IIf( oTree:Type, LoadBitmap( aImages[ i ] ), OpenBitmap( aImages[ i ] ) )
            Imagelist_Add( oTree:himl, aImages[ i ] )
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
   ::handle := TreeAddNode( Self, oTree:handle,               ;
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
   ::image1 := im1
   ::image2 := im2
   
   RETURN Self

METHOD AddNode( cTitle, oPrev, oNext, bAction, aImages ) CLASS HTreeNode
   LOCAL oParent := Self
   LOCAL oNode := HTreeNode():New( ::oTree, oParent, oPrev, oNext, cTitle, bAction, aImages )

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
   tree_ReleaseNode( ::oTree:handle, ::handle )
   SendMessage( ::oTree:handle, TVM_DELETEITEM, 0, ::handle )
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

METHOD Checked( lChecked ) 
   LOCAL state
   
   IF lChecked != NIL 
      TreeSetItem( ::oTree:handle, ::handle, TREE_SETITEM_CHECK, IIF( lChecked, 2, 1 ) )
      ::lChecked := lChecked 
   ELSE
      state =  SendMessage( ::oTree:handle, TVM_GETITEMSTATE, ::handle,, TVIS_STATEIMAGEMASK ) - 1 
      ::lChecked := int( state/4092 ) = 2
   ENDIF
   RETURN ::lChecked

CLASS HTree INHERIT HControl

CLASS VAR winclass   INIT "SysTreeView32"

   DATA aItems INIT { }
   DATA oSelected
   DATA oItem, oItemOld
   DATA hIml, aImages, Image1, Image2
   DATA bItemChange, bExpand, bRClick, bDblClick, bAction, bCheck
   DATA bdrag, bdrop
   DATA lEmpty INIT .T.
   DATA lEditLabels INIT .F. HIDDEN
   DATA lCheckbox   INIT .F. HIDDEN
   DATA lDragDrop   INIT .F. HIDDEN
   
   DATA		lDragging INIT .F. HIDDEN
	 DATA	  hitemDrag, hitemDrop HIDDEN

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bSize, color, bcolor, ;
               aImages, lResour, lEditLabels, bAction, nBC, bRClick, bDblClick, lCheckbox,  bCheck, lDragDrop, bDrag, bDrop, bOther )
   METHOD Init()
   METHOD Activate()
   METHOD AddNode( cTitle, oPrev, oNext, bAction, aImages )
   METHOD FindChild( h )
   METHOD FindChildPos( h, inodo ) 
   METHOD GetSelected()   INLINE TreeGetSelected( ::handle )
   METHOD EditLabel( oNode ) BLOCK { | Self, o | SendMessage( ::handle, TVM_EDITLABEL, 0, o:handle ) }
   METHOD Expand( oNode ) BLOCK { | Self, o | SendMessage( ::handle, TVM_EXPAND, TVE_EXPAND, o:handle ) }
   METHOD Select( oNode ) BLOCK { | Self, o | SendMessage( ::handle, TVM_SELECTITEM, TVGN_CARET, o:handle ) }
   METHOD Clean()
   METHOD Notify( lParam )
   METHOD END()   INLINE ( Super:END(), ReleaseTree( ::aItems ) )
   METHOD isExpand( oNodo ) INLINE ! CheckBit( oNodo, TVE_EXPAND ) 
   METHOD onEvent( msg, wParam, lParam )
   METHOD ItemHeight( nHeight ) SETGET
      
ENDCLASS                                           

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bSize, color, bcolor, ;
            aImages, lResour, lEditLabels, bAction, nBC, bRClick, bDblClick, lcheckbox,  bCheck, lDragDrop, bDrag, bDrop, bOther ) CLASS HTree
   LOCAL i, aBmpSize


   lEditLabels := IIf( lEditLabels == Nil, .F., lEditLabels )
   lCheckBox   := IIf( lCheckBox == Nil, .F., lCheckBox )
   lDragDrop   := IIf( lDragDrop == Nil, .F., lDragDrop )

   nStyle   := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), WS_TABSTOP + WS_BORDER + TVS_HASLINES +  ;
                            TVS_LINESATROOT + TVS_HASBUTTONS  + ; //+ TVS_SHOWSELALWAYS
                          IIf( lEditLabels == Nil.OR. ! lEditLabels, 0, TVS_EDITLABELS ) +;
                          IIf( lCheckBox == Nil.OR. ! lCheckBox, 0, TVS_CHECKBOXES ) +;
                          IIF( ! lDragDrop, TVS_DISABLEDRAGDROP, 0 ) )

   ::sTyle := nStyle                       
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize,,, color, bcolor )

   ::lEditLabels :=  lEditLabels
   ::lCheckBox   :=  lCheckBox
   ::lDragDrop   :=  lDragDrop
   
   ::title   := ""
   ::Type    := IIf( lResour == Nil, .F., lResour )
   ::bAction := bAction
   ::bRClick := bRClick     
   ::bDblClick := bDblClick
   ::bCheck  :=  bCheck
   ::bDrag   := bDrag
   ::bDrop   := bDrop 
   ::bOther  := bOther

   IF aImages != Nil .AND. ! Empty( aImages )
      ::aImages := { }
      FOR i := 1 TO Len( aImages )
         AAdd( ::aImages, Upper( aImages[ i ] ) )
         aImages[ i ] := IIf( lResour <> NIL.and.lResour, LoadBitmap( aImages[ i ] ), OpenBitmap( aImages[ i ] ) )
      NEXT
      aBmpSize := GetBitmapSize( aImages[ 1 ] )
      ::himl := CreateImageList( aImages, aBmpSize[ 1 ], aBmpSize[ 2 ], 12, nBC )
      ::Image1 := 0
      IF Len( aImages ) > 1
         ::Image2 := 1
      ENDIF
   ENDIF

   ::Activate()

   RETURN Self

METHOD Init CLASS HTree

   IF ! ::lInit
      Super:Init()
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      Hwg_InitTreeView( ::handle )
      IF ::himl != Nil
         SendMessage( ::handle, TVM_SETIMAGELIST, TVSIL_NORMAL, ::himl )
      ENDIF
      
   ENDIF

   RETURN Nil

METHOD Activate CLASS HTree

   IF ! Empty( ::oParent:handle )
      ::handle := CreateTree( ::oParent:handle, ::id, ;
                              ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::tcolor, ::bcolor )
      ::Init()
   ENDIF

   RETURN Nil


METHOD onEvent( msg, wParam, lParam )
   Local nEval, hitemNew, htiParent, htiPrev, htiNext

   IF ::bOther != Nil
      IF ( nEval := Eval( ::bOther,Self,msg,wParam,lParam )) != Nil .AND. nEval != - 1
         RETURN 0
      ENDIF
   ENDIF

   IF msg = WM_ERASEBKGND
      RETURN 0
   ELSEIF msg = WM_KEYDOWN 
      IF  ProcKeyList( Self, wParam )
         RETURN 0
      ENDIF
      
   ELSEIF msg == WM_LBUTTONDOWN

   ELSEIF msg == WM_LBUTTONUP .AND. ::lDragging .AND. ::hitemDrop != Nil
      ::lDragging := .F. 
      SendMessage( ::handle, TVM_SELECTITEM, TVGN_DROPHILITE, Nil )
      
      IF ::bDrag != Nil
         nEval :=  Eval( ::bDrag, Self, ::hitemDrag, ::hitemDrop )  
         nEval := IIF( VALTYPE( nEval ) = "L", nEval, .T. )
         IF ! nEval
            RETURN 0
         ENDIF    
      ENDIF
      IF ::hitemDrop != Nil
         IF ::hitemDrag:handle == ::hitemDrop:handle
   			    Return 0
         ENDIF
         htiParent := ::hitemDrop //:oParent
         DO WHILE ( htiParent:oParent ) != Nil
            htiParent := htiParent:oParent 
            IF htiParent:handle = ::hitemDrag:handle
               RETURN 0
            ENDIF
         ENDDO
         IF ! IsCtrlShift( .T. )
            IF ( ::hitemDrag:oParent = Nil .OR. ::hitemDrop:oParent = Nil ) .OR. ;
               ( ::hitemDrag:oParent:handle == ::hitemDrop:oParent:handle )
               IF ::FindChildPos( ::hitemDrop:oParent, ::hitemDrag:Handle ) > ::FindChildPos( ::hitemDrop:oParent, ::hitemDrop:Handle )
                  htiNext := ::hitemDrop //htiParent
               ELSE
                  htiPrev := ::hitemDrop  //htiParent
               ENDIF
            ELSE
            ENDIF   
         ENDIF
      ENDIF
      // fazr a arotina para copias os nodos filhos ao arrastar
      IF  ! IsCtrlShift( .T. )
         IF ::hitemDrop:oParent != Nil
            hitemNew := ::hitemDrop:oParent:AddNode( ::hitemDrag:GetText(), htiPrev ,htiNext, ::hitemDrag:bAction,, ::hitemDrag:lchecked, ::hitemDrag:bClick  ) //, ::hitemDrop:aImages )    
         ELSE      
            hitemNew := ::AddNode( ::hitemDrag:GetText(), htiPrev ,htiNext, ::hitemDrag:bAction,, ::hitemDrag:lchecked, ::hitemDrag:bClick  ) //, ::hitemDrop:aImages )    
         ENDIF
         DragDropTree( ::hitemDrag, hitemNew , ::hitemDrop ) //htiParent ) 
      ELSEIF ::hitemDrop != Nil
         hitemNew := ::hitemDrop:AddNode( ::hitemDrag:Title, htiPrev ,htiNext, ::hitemDrag:bAction,, ::hitemDrag:lchecked, ::hitemDrag:bClick  ) //, ::hitemDrop:aImages )    
         DragDropTree( ::hitemDrag, hitemNew,::hitemDrop ) 
      ENDIF
      hitemNew:cargo  := ::hitemDrag:cargo
      hitemNew:image1 := ::hitemDrag:image1
      hitemNew:image2 := ::hitemDrag:image2
      ::hitemDrag:delete()
      ::Select( hitemNew )
    
      IF ::bDrop != Nil
         Eval( ::bDrop, Self, hitemNew, ::hitemDrop )
      ENDIF
          
   ELSEIF msg = WM_LBUTTONDBLCLK
   
   ENDIF
   RETURN -1
   
   
METHOD AddNode( cTitle, oPrev, oNext, bAction, aImages ) CLASS HTree
   LOCAL oNode := HTreeNode():New( Self, Nil, oPrev, oNext, cTitle, bAction, aImages )
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

METHOD FindChildPos( oNode, h ) CLASS HTree
   LOCAL aItems := IIF( oNode = Nil, ::aItems,  oNode:aItems )
   LOCAL  i := 0, alen := Len( aItems )

   FOR i := 1 TO alen
      IF aItems[ i ]:handle == h
         RETURN i 
      ELSEIF .F. //! Empty( aItems[ i ]:aItems )
         RETURN ::FindChildPos( aItems[ i ], h )
      ENDIF
   NEXT
   RETURN 0

METHOD Clean() CLASS HTree

   ::lEmpty := .T.
   ReleaseTree( ::aItems )
   SendMessage( ::handle, TVM_DELETEITEM, 0, TVI_ROOT )
   ::aItems := { }

   RETURN Nil

METHOD ItemHeight( nHeight )  CLASS HTree

   IF nHeight != Nil
      SendMessage( ::handle, TVM_SETITEMHEIGHT, nHeight, 0 )
   ELSE   
      nHeight := SendMessage( ::handle, TVM_GETITEMHEIGHT, 0, 0 )
   ENDIF
   RETURN  nHeight

METHOD Notify( lParam )  CLASS HTree
   LOCAL nCode := GetNotifyCode( lParam ), oItem, cText, nAct, nHitem, leval

	 IF ncode = NM_SETCURSOR .AND. ::lDragging 
	    ::hitemDrop := tree_Hittest( ::handle,,, @nAct )
	    IF ::hitemDrop != Nil
	       SendMessage( ::handle, TVM_SELECTITEM, TVGN_DROPHILITE, ::hitemDrop:handle )
	    ENDIF
	 ENDIF
	 
	 IF nCode == TVN_SELCHANGING  //.AND. ::oitem != Nil // .OR. NCODE = -500
      
   ELSEIF nCode == TVN_SELCHANGED //.OR. nCode == TVN_ITEMCHANGEDW   
      ::oItemOld := Tree_GetNotify( lParam, TREE_GETNOTIFY_OLDPARAM )
      oItem := Tree_GetNotify( lParam, TREE_GETNOTIFY_PARAM )
      IF ValType( oItem ) == "O"
         oItem:oTree:oSelected := oItem
         IF ! oItem:oTree:lEmpty
            IF oItem:bAction != Nil
               Eval( oItem:bAction, oItem, Self )
            ELSEIF oItem:oTree:bAction != Nil
               Eval( oItem:oTree:bAction, oItem, Self )
            ENDIF
            SENDMESSAGE( ::handle,TVM_SETITEM, , oitem:HANDLE)
         ENDIF
      ENDIF
	 
   ELSEIF nCode == TVN_BEGINLABELEDIT .or. nCode == TVN_BEGINLABELEDITW
      // Return 1
      
   ELSEIF nCode == TVN_ENDLABELEDIT  .or. nCode == TVN_ENDLABELEDITW
      IF ! Empty( cText := Tree_GetNotify( lParam, TREE_GETNOTIFY_EDIT ) )
         oItem := Tree_GetNotify( lParam, TREE_GETNOTIFY_EDITPARAM )
         IF ValType( oItem ) == "O"
            IF ! cText ==  oItem:GetText()  .AND. ;
               ( oItem:oTree:bItemChange == Nil .OR. Eval( oItem:oTree:bItemChange, oItem, cText ) )
               TreeSetItem( oItem:oTree:handle, oItem:handle, TREE_SETITEM_TEXT, cText )
            ENDIF
         ENDIF
      ENDIF
   ELSEIF nCode == TVN_ITEMEXPANDING .or. nCode == TVN_ITEMEXPANDINGW
      oItem := Tree_GetNotify( lParam, TREE_GETNOTIFY_PARAM )
      IF ValType( oItem ) == "O"
         IF ::bExpand != Nil
            RETURN IIf( Eval( oItem:oTree:bExpand, oItem, ;
                              CheckBit( Tree_GetNotify( lParam, TREE_GETNOTIFY_ACTION ), TVE_EXPAND ) ), ;
                        0, 1 )
         ENDIF
      ENDIF
     
   ELSEIF nCode = TVN_BEGINDRAG .AND. ::lDragDrop 
      ::hitemDrag := Tree_GetNotify( lParam, TREE_GETNOTIFY_PARAM )
      ::lDragging := .T. 
              
   ELSEIF nCode = TVN_KEYDOWN
        
	 ELSEIF nCode = NM_CLICK  .AND. ::oitem != Nil .AND. !::lEditLabels 
	    nHitem :=  Tree_GetNotify( lParam, 1 )
	    IF ! EMPTY( nHitem ) .AND. nHitem != ::oitem:Handle 
         oItem  := tree_Hittest( ::handle,,, @nAct )
         //TreeSetItem( ::handle, Tree_GetNotify( lParam, 1 ), nil )
         ::Select( oItem )
      ELSEIF ! ::lEditLabels .AND. EMPTY( nHitem )
         IF ! ::oItem:oTree:lEmpty
            IF ::oItem:bClick != Nil
               Eval( ::oItem:bClick, ::oItem, Self )
            ENDIF
         ENDIF
      ENDIF   
	 
   ELSEIF nCode == NM_DBLCLK
      IF ::bDblClick != Nil
         oItem  := tree_Hittest( ::handle,,, @nAct )
         Eval( ::bDblClick, oItem, Self, nAct )
      ENDIF
   ELSEIF nCode == NM_RCLICK
      IF ::bRClick != Nil
         oItem  := tree_Hittest( ::handle,,, @nAct )
         Eval( ::bRClick, oItem, Self, nAct )
      ENDIF
   ELSEIF nCode == - 24 .and. ::oitem != Nil
      IF ::bCheck != Nil
         lEval := Eval( ::bCheck, ! ::oItem:checked, ::oItem, Self )
      ENDIF
      IF lEval == Nil .OR. ! EMPTY( lEval )
         MarkCheckTree( ::oItem, IIF( ::oItem:checked, 1, 2 ) )
      ELSE
         RETURN 1   
      ENDIF
   ENDIF
   
   IF oitem != Nil
      ::oItem := oItem
   ENDIF
   RETURN 0

STATIC PROCEDURE ReleaseTree( aItems )
   LOCAL i, iLen := Len( aItems )

   FOR i := 1 TO iLen
      tree_ReleaseNode( aItems[ i ]:oTree:handle, aItems[ i ]:handle )
      ReleaseTree( aItems[ i ]:aItems )
      // hwg_DecreaseHolders( aItems[i]:handle )
   NEXT

   RETURN
   
STATIC PROCEDURE MarkCheckTree( oItem, state )
   LOCAL i, iLen := Len( oItem:aitems  )

   FOR i := 1 TO iLen
      TreeSetItem( oItem:oTree:handle, oItem:aitems[ i ]:handle, TREE_SETITEM_CHECK, state )
      MarkCheckTree( oItem:aItems[ i ], state )
   NEXT
   RETURN 

STATIC PROCEDURE DragDropTree( oDrag, oItem, oDrop )
   LOCAL i, iLen := Len( oDrag:aitems  ), hitemNew

   FOR i := 1 TO iLen
      hitemNew := oItem:AddNode( oDrag:aItems[ i ]:GetText(), ,, oDrag:aItems[ i ]:bAction,, oDrag:aItems[ i ]:lchecked, oDrag:aItems[ i ]:bClick  ) //, ::hitemDrop:aImages )    
      hitemNew:oTree  := oDrag:aItems[ i ]:oTree
      hitemNew:cargo := oDrag:aItems[ i ]:cargo
      hitemNew:image1 := oDrag:aItems[ i ]:image1
      hitemNew:image2 := oDrag:aItems[ i ]:image2
      IF Len( oDrag:aitems[ i ]:aitems ) > 0
         DragDropTree( oDrag:aItems[ i ], hitemNew, oDrop )
      ENDIF   
      //oDrag:aItems[ i ]:delete()
   NEXT
   RETURN 