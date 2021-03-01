/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HListBox class
 *
 * Copyright 2004 Vic McClung
 *
 * Modified by DF7BE for GTK port trial (April 2020)
 *
*/

/*
 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 This is only a trial Version.
 The files hlistbox.prg and listbox.c are "sleeping" at the moment.
 Because of a bug in GTK, it is not possible,
 to create a port of the LISTBOX feature to GTK.
 The sample "demohlist.prg" could be compiled with
 activted files hlistbox.prg and listbox.c in the makefile, but
 the listbox is not visible.
 These files are only commited as preparation for
 the port to GTK, in the hope, that the bug is fixed
 in future GTK versions.
 
 The coding follows the sample "listbox_sample.c"
 from Eric Harlow. Some lines are commented out,
 activate them during development in the future.
 
 To actiave the port, add these two lines into the
 makefiles for GTK:
 $(LIB_DIR)/libhwgui.a : \
   $(OBJ_DIR)/commond.o \
   $(OBJ_DIR)/control.o \
...
  $(OBJ_DIR)/listbox.o \
  $(OBJ_DIR)/hlistbox.o
...  
 
*/

/* Special info for GTK:
   - The Listbox functions of GTK are very simple, some parameters about
     position and size have no effect, because they are automaticely calculated by the GTK functions.
     That are:
      > Positions x,y,
      > width, heigth,
      > style. 
*/


#ifdef __GTK__
#include "gtk.ch"
#endif
#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

CLASS HListBox INHERIT HControl

CLASS VAR winclass   INIT "LISTBOX"
   DATA  aItems
   DATA  bSetGet
   DATA  value         INIT 1
   DATA  nItemHeight
   DATA  bChangeSel
   DATA  bkeydown, bDblclick
   DATA  bValid
   DATA  handle  // GtkWidget of listbox

   METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
              aItems,oFont,bInit,bSize,bPaint,bChange,cTooltip,tColor,bcolor,bGFocus,bLFocus, bKeydown, bDblclick,bOther )
   METHOD Activate()
   METHOD Redefine( oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, ;
                    bChange, cTooltip, bKeydown, bOther  )
   METHOD Init()
   METHOD Refresh()
   METHOD Requery()
   METHOD Setitem( nPos )
   METHOD AddItems( p )
   METHOD DeleteItem( nPos )
   METHOD Valid( oCtrl )
   METHOD When( oCtrl )
   METHOD onChange( oCtrl )
   METHOD onDblClick()
   METHOD Clear()
   METHOD onEvent( msg, wParam, lParam )

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, aItems, oFont, ;
            bInit, bSize, bPaint, bChange, cTooltip, tColor, bcolor, bGFocus, bLFocus,bKeydown, bDblclick,bOther )  CLASS HListBox

   // removed: + LBS_DISABLENOSCROLL + LBS_NOTIFY  + LBS_NOINTEGRALHEIGHT
   nStyle   := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), WS_TABSTOP + WS_VSCROLL + WS_BORDER )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize, bPaint, cTooltip, tColor, bcolor )

   ::value   := IIf( vari == Nil .OR. ValType( vari ) != "N", 0, vari )
   ::bSetGet := bSetGet

   IF aItems == Nil
      ::aItems := { }
   ELSE
      ::aItems  := aItems
   ENDIF


   ::bChangeSel := bChange
   ::bGetFocus := bGFocus
   ::bLostFocus := bLFocus
   ::bKeydown := bKeydown
   ::bDblclick := bDblclick
   ::bOther := bOther
   
    /* Create Listbox */
   ::handle := HWG_CREATELISTBOX()

//   hwg_WriteLog(IIF(EMPTY(::handle),"E","F") )

    /* Listbox visble */
    ::Activate()
    /* Add items */
    ::AddItems(::handle,::aItems)
    
    
    hwg_ListBoxShowMain(::oParent,::handle)
/*
   IF bSetGet != Nil
      IF bGFocus != Nil
         ::oParent:AddEvent( LBN_SETFOCUS, ::id, { | o, id | ::When( o:FindControl( id ) ) } )
      ENDIF
      ::oParent:AddEvent( LBN_KILLFOCUS, ::id, { | o, id | ::Valid( o:FindControl( id ) ) } )
      ::bValid := { | o | ::Valid( o ) }
   ELSE
      IF bGFocus != Nil
         ::oParent:AddEvent( LBN_SETFOCUS, ::id, { | o, id | ::When( o:FindControl( id ) ) } )
      ENDIF
      ::oParent:AddEvent( LBN_KILLFOCUS, ::id, { | o, id | ::Valid( o:FindControl( id ) ) } )
   ENDIF
   IF bChange != Nil .OR. bSetGet != Nil
      ::oParent:AddEvent( LBN_SELCHANGE, ::id, { | o, id | ::onChange( o:FindControl( id ) ) } )
   ENDIF
   IF bDblclick != Nil
      ::oParent:AddEvent( LBN_DBLCLK, ::id, {|| ::onDblClick() } )
   ENDIF
*/
   RETURN Self

   
METHOD Activate() CLASS HListBox
* Make listbox visible

   IF ! Empty( ::oParent:handle )
     HWG_LISTBOXSHOW(::handle)
/* 
      ::handle := hwg_Createlistbox( ::oParent:handle, ::id, ;
                                 ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
*/
      hwg_Setwindowobject( ::handle, Self )
      hwg_WriteLog("hier")
   ENDIF
   
   RETURN Nil

   
METHOD Redefine( oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, ;
                 bChange, cTooltip, bKeydown, bOther )  CLASS HListBox

/*
   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, cTooltip )

   ::value   := IIf( vari == Nil .OR. ValType( vari ) != "N", 1, vari )
   ::bSetGet := bSetGet
   ::bKeydown := bKeydown
    ::bOther := bOther

   IF aItems == Nil
      ::aItems := { }
   ELSE
      ::aItems  := aItems
   ENDIF

   IF bSetGet != Nil
      ::bChangeSel := bChange
      ::oParent:AddEvent( LBN_SELCHANGE, Self, { | o, id | ::Valid( o:FindControl( id ) ) }, "onChange" )
   ENDIF
   RETURN Self
*/
 RETURN NIL   

METHOD Init() CLASS HListBox

   LOCAL i

   IF ! ::lInit
      ::nHolder := 1
      hwg_Setwindowobject( ::handle, Self )
//      HWG_INITLISTPROC( ::handle )
      ::Super:Init()
      IF ::aItems != Nil
         IF ::value == Nil
            ::value := 1
         ENDIF
         IF !EMPTY( ::nItemHeight )
 //           hwg_Sendmessage( ::handle, LB_SETITEMHEIGHT , 0, ::nItemHeight )
         ENDIF
//         hwg_Sendmessage( ::handle, LB_RESETCONTENT, 0, 0 )
         FOR i := 1 TO Len( ::aItems )
            hwg_Listboxaddstring( ::handle, ::aItems[ i ] )
         NEXT
//         hwg_Listboxsetstring( ::handle, ::value )
      ENDIF
   ENDIF
   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HListBox

/*
 Local nEval

   IF ::bOther != Nil
      IF (nEval := Eval( ::bOther,Self,msg,wParam,lParam )) != -1 .AND. nEval != Nil
         RETURN 0
      ENDIF
   ENDIF
   wParam := hwg_PtrToUlong( wParam )
   IF msg == WM_KEYDOWN
      IF wParam = VK_TAB //.AND. nType < WND_DLG_RESOURCE
         hwg_GetSkip( ::oParent, ::handle, , iif( hwg_IsCtrlShift(.f., .t.), -1, 1) )
      ENDIF
         IF ::bKeyDown != Nil .and. ValType( ::bKeyDown ) == 'B'
         nEval := Eval( ::bKeyDown, Self, wParam )
         IF (VALTYPE( nEval ) == "L" .AND. ! nEval ) .OR. ( nEval != -1 .AND. nEval != Nil )
            RETURN 0
         ENDIF
      ENDIF
   ELSEIF  msg = WM_GETDLGCODE .AND. ( wParam = VK_RETURN .OR.wParam = VK_ESCAPE ) .AND. ::bKeyDown != Nil
      RETURN DLGC_WANTALLKEYS  //DLGC_WANTARROWS + DLGC_WANTTAB + DLGC_WANTCHARS
   ENDIF
*/   
   RETURN -1

METHOD Requery() CLASS HListBox
/*
   Local i

   hwg_Sendmessage( ::handle, LB_RESETCONTENT, 0, 0)
   FOR i := 1 TO Len( ::aItems )
      hwg_Listboxaddstring( ::handle, ::aItems[i] )
   NEXT
   hwg_Listboxsetstring( ::handle, ::value )
   ::refresh()
*/   
   Return Nil


METHOD Refresh() CLASS HListBox

   LOCAL vari
   IF ::bSetGet != Nil
      vari := Eval( ::bSetGet )
   ENDIF

   ::value := IIf( vari == Nil .OR. ValType( vari ) != "N", 0, vari )
   ::SetItem( ::value )
  
   RETURN Nil

METHOD SetItem( nPos ) CLASS HListBox

   ::value := nPos
//   hwg_Sendmessage( ::handle, LB_SETCURSEL, nPos - 1, 0 )

   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::value )
   ENDIF

   IF ::bChangeSel != Nil
      Eval( ::bChangeSel, ::value, Self )
   ENDIF
   
   RETURN Nil

METHOD onDblClick()  CLASS HListBox

  IF ::bDblClick != Nil
      Eval( ::bDblClick, self, ::value )
   ENDIF
  
   RETURN Nil
   

METHOD AddItems( p ) CLASS HListBox

   AAdd( ::aItems, p )
   hwg_Listboxaddstring( ::handle, p )
//   hwg_Listboxsetstring( ::handle, ::value )
   RETURN Self
   

METHOD DeleteItem( nPos ) CLASS HListBox

//   IF hwg_Sendmessage( ::handle, LB_DELETESTRING , nPos - 1, 0 ) >= 0 //<= LEN(ocombo:aitems)
      ADel( ::Aitems, nPos )
      ASize( ::Aitems, Len( ::aitems ) - 1 )
      ::value := Min( Len( ::aitems ) , ::value )
      IF ::bSetGet != Nil
         Eval( ::bSetGet, ::value, Self )
      ENDIF
      RETURN .T.
//   ENDIF
 
   RETURN .F.

METHOD Clear() CLASS HListBox

   ::aItems := { }
   ::value := 0
//   hwg_Sendmessage( ::handle, LB_RESETCONTENT, 0, 0 )
//   hwg_Listboxsetstring( ::handle, ::value )
 
   RETURN .T.


METHOD onChange( oCtrl ) CLASS HListBox
/*
   LOCAL nPos

   HB_SYMBOL_UNUSED( oCtrl )

   nPos := hwg_Sendmessage( ::handle, LB_GETCURSEL, 0, 0 ) + 1
   ::SetItem( nPos )
*/
   RETURN Nil


METHOD When( oCtrl ) CLASS HListBox
/*
   LOCAL res := .t., nSkip

   HB_SYMBOL_UNUSED( oCtrl )

    nSkip := IIf( hwg_Getkeystate( VK_UP ) < 0 .or. ( hwg_Getkeystate( VK_TAB ) < 0 .AND. hwg_Getkeystate( VK_SHIFT ) < 0 ), - 1, 1 )
   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::value, Self )
   ENDIF
   IF ::bGetFocus != Nil
      res := Eval( ::bGetFocus, ::Value, Self )
      ::Setfocus()      
   ENDIF
   RETURN res
*/
 RETURN .F.   


METHOD Valid( oCtrl ) CLASS HListBox
/*
   LOCAL res, oDlg

   HB_SYMBOL_UNUSED( oCtrl )

   IF ( oDlg := hwg_GetParentForm( Self ) ) == Nil .OR. oDlg:nLastKey != 27
      ::value := hwg_Sendmessage( ::handle, LB_GETCURSEL, 0, 0 ) + 1
      IF ::bSetGet != Nil
         Eval( ::bSetGet, ::value, Self )
      ENDIF
      IF oDlg != Nil
         oDlg:nLastKey := 27
      ENDIF
      IF ::bLostFocus != Nil
         res := Eval( ::bLostFocus, ::value, Self )
         IF ! res
            ::Setfocus( .T. ) //( ::handle )
            IF oDlg != Nil
               oDlg:nLastKey := 0
            ENDIF
            RETURN .F.
         ENDIF
      ENDIF
      IF oDlg != Nil
         oDlg:nLastKey := 0
      ENDIF
   ENDIF
   IF Empty( hwg_Getfocus() )
       hwg_GetSkip( ::oParent, ::handle, 1 )
   ENDIF
*/   
   RETURN .T.
/*   
STATIC FUNCTION AddLItems (h,it)
* h = Handle, it = array with items
    LOCAL i
    IF it == Nil
      it := { }
    ENDIF  
    IF .NOT. EMPTY(it)
     FOR i := 1 TO LEN(it)
       HWG_LISTBOXADDSTRING( h,it[ i ] )
     NEXT
    ENDIF
RETURN NIL
*/
* =========================== EOF of hlistbox.prg ===========================