/*
 * $Id$
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
#define TVM_GETEDITCONTROL   4367   // (TV_FIRST + 15)
#define TVM_ENDEDITLABELNOW  4374   //(TV_FIRST + 22)
#define TVM_GETITEMSTATE     4391   // (TV_FIRST + 39)
#define TVM_SETITEM          4426   // (TV_FIRST + 63)
#define TVM_SETITEMHEIGHT    4379   // (TV_FIRST + 27)
#define TVM_GETITEMHEIGHT    4380
#define TVM_SETLINECOLOR     4392 

#define TVE_COLLAPSE            0x0001
#define TVE_EXPAND              0x0002
#define TVE_TOGGLE              0x0003

#define TVSIL_NORMAL            0

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
#define  NM_DBLCLK               - 3
#define  NM_RCLICK               - 5
#define  NM_KILLFOCUS            - 8
#define  NM_SETCURSOR            - 17    // uses NMMOUSE struct
#define  NM_CHAR                 - 18   // uses NMCHAR struct

Static s_aEvents

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
   METHOD AddNode( cTitle, oPrev, oNext, bAction, aImages, lCheck, bClick )
   METHOD Delete( lInternal )
   METHOD FindChild( h )
   METHOD GetText()  INLINE hwg_Treegetnodetext( ::oTree:handle, ::handle )
   METHOD SetText( cText ) INLINE hwg_Treesetitem( ::oTree:handle, ::handle, TREE_SETITEM_TEXT, cText ), ::title := cText
   METHOD Checked( lChecked )  SETGET
   METHOD GetLevel( h )

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
            aImages[ i ] := IIf( oTree:Type, hwg_Loadbitmap( aImages[ i ] ), hwg_Openbitmap( aImages[ i ] ) )
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
   ::image1 := im1
   ::image2 := im2

   RETURN Self

METHOD AddNode( cTitle, oPrev, oNext, bAction, aImages, lCheck, bClick ) CLASS HTreeNode
   LOCAL oParent := Self
   LOCAL oNode := HTreeNode():New( ::oTree, oParent, oPrev, oNext, cTitle, bAction, aImages, lCheck, bClick )

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

METHOD Checked( lChecked ) CLASS HTreeNode
   LOCAL state

   IF lChecked != NIL
      hwg_Treesetitem( ::oTree:handle, ::handle, TREE_SETITEM_CHECK, IIF( lChecked, 2, 1 ) )
      ::lChecked := lChecked
   ELSE
      state =  hwg_Sendmessage( ::oTree:handle, TVM_GETITEMSTATE, ::handle,, TVIS_STATEIMAGEMASK ) - 1
      ::lChecked := int( state/4092 ) = 2
   ENDIF
   RETURN ::lChecked

METHOD GetLevel( h ) CLASS HTreeNode
   LOCAL iLevel := 1
   
   LOCAL oNode := IIF( EMPTY( h ), Self, h )
   DO WHILE ( oNode:oParent ) != Nil 
	    oNode := oNode:oParent
	    iLevel ++
   ENDDO
   RETURN iLevel

CLASS HTree INHERIT HControl

CLASS VAR winclass   INIT "SysTreeView32"

   DATA aItems INIT { }
   DATA oSelected
   DATA oItem, oItemOld
   DATA hIml, aImages, Image1, Image2
   DATA bItemChange, bExpand, bRClick, bDblClick, bAction, bCheck, bKeyDown
   DATA bdrag, bdrop
   DATA lEmpty INIT .T.
   DATA lEditLabels INIT .F. HIDDEN
   DATA lCheckbox   INIT .F. HIDDEN
   DATA lDragDrop   INIT .F. HIDDEN
   DATA	lDragging  INIT .F. HIDDEN
   DATA  hitemDrag, hitemDrop HIDDEN
   DATA hTreeEdit

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bSize, color, bcolor, ;
               aImages, lResour, lEditLabels, bAction, nBC, bRClick, bDblClick, lCheckbox,  bCheck, lDragDrop, bDrag, bDrop, bOther )
   METHOD Init()
   METHOD Activate()
   METHOD AddNode( cTitle, oPrev, oNext, bAction, aImages, lCheck, bClick )
   METHOD FindChild( h )
   METHOD FindChildPos( oNode, h )
   METHOD GetSelected() INLINE IIF( VALTYPE( ::oItem := hwg_Treegetselected( ::handle ) ) = "O", ::oItem, Nil )
   METHOD EditLabel( oNode ) BLOCK { | Self, o | hwg_Sendmessage( ::handle, TVM_EDITLABEL, 0, o:handle ) }
   METHOD Expand( oNode, lAllNode )   //BLOCK { | Self, o | hwg_Sendmessage( ::handle, TVM_EXPAND, TVE_EXPAND, o:handle ), hwg_Redrawwindow( ::handle , RDW_NOERASE + RDW_FRAME + RDW_INVALIDATE  )}
   METHOD Select( oNode ) BLOCK { | Self, o | hwg_Sendmessage( ::handle, TVM_SELECTITEM, TVGN_CARET, o:handle ), ::oItem := hwg_Treegetselected( ::handle ) }
   METHOD Clean()
   METHOD Notify( lParam )
   METHOD END()   INLINE ( ::Super:END(), ReleaseTree( ::aItems ) )
   METHOD isExpand( oNodo ) INLINE ! hwg_Checkbit( oNodo, TVE_EXPAND )
   METHOD onEvent( msg, wParam, lParam )
   METHOD ItemHeight( nHeight ) SETGET
   METHOD SearchString( cText, iNivel, oNode, inodo )
   METHOD Selecteds( oItem, aSels )
   METHOD Top()    INLINE IIF( !Empty( ::aItems ), ( ::Select( ::aItems[ 1 ] ), hwg_Sendmessage( ::Handle, WM_VSCROLL, hwg_Makewparam( 0, SB_TOP ), Nil ) ), )
   METHOD Bottom() INLINE IIF( !Empty( ::aItems ), ( ::Select( ::aItems[ LEN( ::aItems ) ] ), hwg_Sendmessage( ::Handle, WM_VSCROLL, hwg_Makewparam( 0, SB_BOTTOM ), Nil ) ),)

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bSize, color, bcolor, ;
            aImages, lResour, lEditLabels, bAction, nBC, bRClick, bDblClick, lcheckbox,  bCheck, lDragDrop, bDrag, bDrop, bOther ) CLASS HTree
   LOCAL i, aBmpSize


   lEditLabels := IIf( lEditLabels == Nil, .F., lEditLabels )
   lCheckBox   := IIf( lCheckBox == Nil, .F., lCheckBox )
   lDragDrop   := IIf( lDragDrop == Nil, .F., lDragDrop )

   nStyle   := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), WS_TABSTOP  + TVS_FULLROWSELECT + ; //TVS_TRACKSELECT+; //TVS_HASLINES +  ;
                            TVS_LINESATROOT + TVS_HASBUTTONS  + TVS_SHOWSELALWAYS + ;
                          IIf( lEditLabels == Nil.OR. ! lEditLabels, 0, TVS_EDITLABELS ) +;
                          IIf( lCheckBox == Nil.OR. ! lCheckBox, 0, TVS_CHECKBOXES ) +;
                          IIF( ! lDragDrop, TVS_DISABLEDRAGDROP, 0 ) )

   ::sTyle := nStyle
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
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
         aImages[ i ] := IIf( lResour <> NIL.and.lResour, hwg_Loadbitmap( aImages[ i ] ), hwg_Openbitmap( aImages[ i ] ) )
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

METHOD Init() CLASS HTree

   IF ! ::lInit
      ::Super:Init()
      ::nHolder := 1
      hwg_Setwindowobject( ::handle, Self )
      Hwg_InitTreeView( ::handle )
      IF ::himl != Nil
         hwg_Sendmessage( ::handle, TVM_SETIMAGELIST, TVSIL_NORMAL, ::himl )
      ENDIF

   ENDIF

   RETURN Nil

METHOD Activate() CLASS HTree

   IF ! Empty( ::oParent:handle )
      ::handle := hwg_Createtree( ::oParent:handle, ::id, ;
                              ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::tcolor, ::bcolor )
      ::Init()
   ENDIF

   RETURN Nil


METHOD onEvent( msg, wParam, lParam ) CLASS HTree
   Local nEval, hitemNew, htiParent, htiPrev, htiNext
   
   IF ::bOther != Nil
      IF ( nEval := Eval( ::bOther,Self,msg,wParam,lParam )) != Nil .AND. nEval != - 1
         RETURN 0
      ENDIF
   ENDIF
   IF msg = WM_ERASEBKGND
      RETURN 0
   ELSEIF msg = WM_CHAR
      IF wParam = VK_ESCAPE
         Return DLGC_WANTMESSAGE
      ENDIF
      IF wParam = VK_RETURN
         ::oItem := ::oSelected
         IF ::lEditLabels .AND. ::bDblClick = Nil
            ::EditLabel( ::oSelected )
         ELSEIF ::bDblClick != Nil
            ::Setfocus()
            Eval( ::bDblClick, ::oItem, Self )
            //hwg_Sendmessage( ::handle, WM_LBUTTONDBLCLK, 0, hwg_Makelparam( 1, 1 ) )
            RETURN 0
         ENDIF
      ELSEIF wParam = VK_TAB
         hwg_GetSkip( ::oParent, ::handle, , IIF( hwg_IsCtrlShift( .F., .T.), - 1, 1 ) )
         RETURN 0
      ELSEIF ::bKeyDown != Nil
         RETURN 0
      ENDIF

   ELSEIF msg = WM_KEYDOWN
   
   ELSEIF msg = WM_KEYUP
      IF  hwg_ProcKeyList( Self, wParam )
         RETURN 0
      ENDIF

   ELSEIF msg = WM_GETDLGCODE
      IF  wParam = VK_RETURN .OR. ::bKeyDown != Nil // ! .AND. ::lEditLabels
         RETURN DLGC_WANTMESSAGE
      ENDIF

   ELSEIF msg == WM_LBUTTONDOWN

   ELSEIF msg == WM_LBUTTONUP .AND. ::lDragging .AND. ::hitemDrop != Nil
      ::lDragging := .F.
      hwg_Sendmessage( ::handle, TVM_SELECTITEM, TVGN_DROPHILITE, Nil )

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
         IF ! hwg_IsCtrlShift( .T. )
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
      IF  ! hwg_IsCtrlShift( .T. )
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

   ELSEIF  ::lEditLabels .AND. ( ( msg = WM_LBUTTONDBLCLK .AND. ::bDblClick = Nil ) .OR. msg = WM_CHAR )
      ::EditLabel( ::oSelected )
      RETURN 0
   ENDIF
   RETURN -1


METHOD AddNode( cTitle, oPrev, oNext, bAction, aImages, lCheck, bClick ) CLASS HTree
   LOCAL oNode := HTreeNode():New( Self, Nil, oPrev, oNext, cTitle, bAction, aImages, lCheck, bClick )
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
   LOCAL  i, alen := Len( aItems )

   FOR i := 1 TO alen
      IF aItems[ i ]:handle == h
         RETURN i
      ELSEIF .F. //! Empty( aItems[ i ]:aItems )
         RETURN ::FindChildPos( aItems[ i ], h )
      ENDIF
   NEXT
   RETURN 0

METHOD SearchString( cText, iNivel, oNode, inodo ) CLASS HTree
   LOCAL aItems := IIF( oNode = Nil, ::aItems,  oNode:aItems )
   Local  i , alen := Len( aItems )
   LOCAL oNodeRet
   
   iNodo := IIF( inodo = Nil, 0, iNodo )
   FOR i := 1 TO aLen
      IF ! Empty( aItems[ i ]:aItems ) .AND. ;
         ( oNodeRet := ::SearchString( cText, iNivel, aItems[ i ], iNodo ) ) != Nil 
         RETURN oNodeRet
      ENDIF
      IF  aItems[ i ]:Title = cText .AND. ( iNivel == Nil .OR. aItems[ i ]:GetLevel( ) = iNivel )       
         iNodo ++ 
         RETURN aItems[ i ]
      ELSE
         iNodo ++   
      ENDIF
   NEXT
   RETURN Nil 

METHOD Clean() CLASS HTree

   ::lEmpty := .T.
   ReleaseTree( ::aItems )
   hwg_Sendmessage( ::handle, TVM_DELETEITEM, 0, TVI_ROOT )
   ::aItems := { }

   RETURN Nil

METHOD ItemHeight( nHeight )  CLASS HTree

   IF nHeight != Nil
      hwg_Sendmessage( ::handle, TVM_SETITEMHEIGHT, nHeight, 0 )
   ELSE
      nHeight := hwg_Sendmessage( ::handle, TVM_GETITEMHEIGHT, 0, 0 )
   ENDIF
   RETURN  nHeight

METHOD Notify( lParam )  CLASS HTree
   LOCAL nCode := hwg_Getnotifycode( lParam ), oItem, cText, nAct, nHitem, leval
   LOCAL nkeyDown := hwg_Getnotifykeydown( lParam )
    
	IF ncode = NM_SETCURSOR .AND. ::lDragging
	   ::hitemDrop := hwg_Treehittest( ::handle,,, @nAct )
	   IF ::hitemDrop != Nil
	      hwg_Sendmessage( ::handle, TVM_SELECTITEM, TVGN_DROPHILITE, ::hitemDrop:handle )
	   ENDIF
	ENDIF
	
	IF nCode == TVN_SELCHANGING  //.AND. ::oitem != Nil // .OR. NCODE = -500

   ELSEIF nCode == TVN_SELCHANGED //.OR. nCode == TVN_ITEMCHANGEDW
      ::oItemOld := hwg_Treegetnotify( lParam, TREE_GETNOTIFY_OLDPARAM )
      oItem := hwg_Treegetnotify( lParam, TREE_GETNOTIFY_PARAM )
      IF ValType( oItem ) == "O"
         oItem:oTree:oSelected := oItem
         IF oItem != Nil .AND. ! oItem:oTree:lEmpty
            IF oItem:bAction != Nil
               Eval( oItem:bAction, oItem, Self )
            ELSEIF oItem:oTree:bAction != Nil
               Eval( oItem:oTree:bAction, oItem, Self )
            ENDIF
            hwg_Sendmessage( ::handle,TVM_SETITEM, , oitem:HANDLE)
         ENDIF
      ENDIF
	
   ELSEIF nCode == TVN_BEGINLABELEDIT .or. nCode == TVN_BEGINLABELEDITW
      ::hTreeEdit := hwg_Sendmessage( ::Handle, TVM_GETEDITCONTROL, 0, 0 )
      s_aEvents := aClone( ::oParent:aEvents )
      ::oParent:AddEvent( 0, IDOK, { || hwg_Sendmessage( ::handle, TVM_ENDEDITLABELNOW , 0, 0 ) } )
      ::oParent:AddEvent( 0, IDCANCEL, { || hwg_Sendmessage( ::handle, TVM_ENDEDITLABELNOW , 1, 0 ) } )
      hwg_Sendmessage( ::hTreeEdit, WM_KEYDOWN, VK_END, 0 )

   ELSEIF nCode == TVN_ENDLABELEDIT  .or. nCode == TVN_ENDLABELEDITW
      ::hTreeEdit := Nil
      IF ! Empty( cText := hwg_Treegetnotify( lParam, TREE_GETNOTIFY_EDIT ) )
         oItem := hwg_Treegetnotify( lParam, TREE_GETNOTIFY_EDITPARAM )
         IF ValType( oItem ) == "O"
            IF ! cText ==  oItem:GetText()  .AND. ;
               ( oItem:oTree:bItemChange == Nil .OR. Eval( oItem:oTree:bItemChange, oItem, cText ) )
               hwg_Treesetitem( oItem:oTree:handle, oItem:handle, TREE_SETITEM_TEXT, cText )
            ENDIF
         ENDIF
      ENDIF
      ::oParent:aEvents := s_aEvents
      
   ELSEIF nCode == TVN_ITEMEXPANDING .or. nCode == TVN_ITEMEXPANDINGW
      oItem := hwg_Treegetnotify( lParam, TREE_GETNOTIFY_PARAM )
      IF ValType( oItem ) == "O"
         IF ::bExpand != Nil
            RETURN IIf( Eval( oItem:oTree:bExpand, oItem, ;
                              hwg_Checkbit( hwg_Treegetnotify( lParam, TREE_GETNOTIFY_ACTION ), TVE_EXPAND ) ), ;
                        0, 1 )
         ENDIF
      ENDIF

   ELSEIF nCode = TVN_BEGINDRAG .AND. ::lDragDrop
      ::hitemDrag := hwg_Treegetnotify( lParam, TREE_GETNOTIFY_PARAM )
      ::lDragging := .T.

   ELSEIF nCode = TVN_KEYDOWN .AND. ::oItem != Nil
      IF ::oItem:oTree:bKeyDown != Nil
         Eval( ::oItem:oTree:bKeyDown, ::oItem, nKeyDown, Self )
      ENDIF

	 ELSEIF nCode = NM_CLICK  //.AND. ::oitem != Nil // .AND. !::lEditLabels
	    nHitem :=  hwg_Treegetnotify( lParam, 1 )
	    //nHitem :=  hwg_Getnotifycode( lParam )
	    oItem  := hwg_Treehittest( ::handle,,, @nAct )
	    IF nAct = TVHT_ONITEMSTATEICON
	       IF ::oItem == Nil .OR. oItem:Handle != ::oitem:Handle 
            ::Select( oItem )
            ::oItem := oItem
         ENDIF
         IF ::bCheck != Nil
            lEval := Eval( ::bCheck, ! ::oItem:checked, ::oItem, Self )
         ENDIF
         IF lEval == Nil .OR. ! EMPTY( lEval )
            MarkCheckTree( ::oItem, IIF( ::oItem:checked, 1, 2 ) )
            RETURN 0   
         ENDIF
         RETURN 1   
      ELSEIF ! ::lEditLabels .AND. EMPTY( nHitem )
         IF ! oItem:oTree:lEmpty
            IF oItem:bClick != Nil
               Eval( oItem:bClick, oItem, Self )
            ENDIF
         ENDIF
      ENDIF
	
   ELSEIF nCode == NM_DBLCLK
      IF ::bDblClick != Nil
         oItem  := hwg_Treehittest( ::handle,,, @nAct )
         IF oItem = Nil
            oItem := ::oItem
            *::Select( oItem )
         ENDIF
         Eval( ::bDblClick, oItem, Self, nAct )
      ENDIF
   ELSEIF nCode == NM_RCLICK
      IF ::bRClick != Nil
         oItem  := hwg_Treehittest( ::handle,,, @nAct )
         Eval( ::bRClick, oItem, Self, nAct )
      ENDIF
      
      /* working only windows 7
   ELSEIF nCode == - 24 .and. ::oitem != Nil
      //nhitem := hwg_Treehittest( ::handle,,, @nAct )
      IF ::bCheck != Nil
         lEval := Eval( ::bCheck, ! ::oItem:checked, ::oItem, Self )
      ENDIF
      IF lEval == Nil .OR. ! EMPTY( lEval )
         MarkCheckTree( ::oItem, IIF( ::oItem:checked, 1, 2 ) )
      ELSE
         RETURN 1
      ENDIF
      */
   ENDIF

   IF ValType( oItem ) == "O"
      ::oItem := oItem
   ENDIF
   RETURN 0

METHOD Selecteds( oItem, aSels )  CLASS HTree
   LOCAL i, iLen
   LOCAL aSelecteds := IIF( aSels = Nil, {}, aSels )
   
   oItem := IIF( oItem = Nil, Self, oItem )
   iLen :=  Len( oItem:aitems )
   
   FOR i := 1 TO iLen
      IF oItem:aItems[ i ]:checked
         AADD( aSelecteds, oItem:aItems[ i ] )
      ENDIF   
      ::Selecteds( oItem:aItems[ i ], aSelecteds )
   NEXT
   RETURN aSelecteds

METHOD Expand( oNode, lAllNode )  CLASS HTree
   LOCAL i, iLen := Len( oNode:aitems  )
   
   hwg_Sendmessage( ::handle, TVM_EXPAND, TVE_EXPAND, oNode:handle )
   FOR i := 1 TO iLen
      IF ! EMPTY( lAllNode ) .AND. Len( oNode:aitems ) > 0
         ::Expand( oNode:aItems[ i ], lAllNode )
      ENDIF
   NEXT
   hwg_Redrawwindow( ::handle , RDW_NOERASE + RDW_FRAME + RDW_INVALIDATE  )
   RETURN Nil

STATIC PROCEDURE ReleaseTree( aItems )
   LOCAL i, iLen := Len( aItems )

   FOR i := 1 TO iLen
      hwg_Treereleasenode( aItems[ i ]:oTree:handle, aItems[ i ]:handle )
      ReleaseTree( aItems[ i ]:aItems )
      // hwg_DecreaseHolders( aItems[i]:handle )
   NEXT

   RETURN

STATIC PROCEDURE MarkCheckTree( oItem, state )
   LOCAL i, iLen := Len( oItem:aitems  ), oParent

   FOR i := 1 TO iLen
      hwg_Treesetitem( oItem:oTree:handle, oItem:aitems[ i ]:handle, TREE_SETITEM_CHECK, state )
      MarkCheckTree( oItem:aItems[ i ], state )   
   NEXT
   IF state = 1
      oParent = oItem:oParent
      DO WHILE oParent != Nil
         hwg_Treesetitem( oItem:oTree:handle, oParent:handle, TREE_SETITEM_CHECK, state )
         oParent := oParent:oParent
      ENDDO
   ENDIF
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