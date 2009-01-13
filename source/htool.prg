/*
 * $Id: htool.prg,v 1.25 2009-01-13 17:06:09 lfbasso Exp $
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
   DATA TEXT, id, nTop, nLeft, nwidth, nheight
   CLASSDATA oSelected INIT Nil
   DATA State INIT 0
   DATA ExStyle
   DATA bClick, cTooltip

   DATA lPress INIT .F.
   DATA lFlat
   DATA nOrder
   DATA lTransp    INIT .F. 
   DATA lVertical  INIT .F. 
   DATA lCreate    INIT .F. HIDDEN 
   DATA BtnWidth  
   DATA aItem init { }

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, BtnWidth, oFont, bInit, ;
               bSize, bPaint, ctooltip, tcolor, bcolor, lTransp,lVertical, aItem )
   METHOD Redefine( oWndParent, nId, oFont, bInit, ;
                    bSize, bPaint, ctooltip, tcolor, bcolor, lTransp , aItem )

   METHOD Activate()
   METHOD INIT()
   METHOD CreateTool()
   METHOD AddButton( a, s, d, f, g, h )
   METHOD Notify( lParam )
   METHOD EnableButton( idButton, lEnable ) INLINE SENDMESSAGE( ::handle, TB_ENABLEBUTTON, INT( idButton ), MAKELONG( IIF( lEnable, 1, 0 ), 0) )
   METHOD ShowButton( idButton ) INLINE SENDMESSAGE( ::handle, TB_HIDEBUTTON, INT( idButton ), MAKELONG( 0, 0 ) )
   METHOD HideButton( idButton ) INLINE SENDMESSAGE( ::handle, TB_HIDEBUTTON, INT( idButton ), MAKELONG( 1, 0 ) )         
   METHOD REFRESH
   
ENDCLASS


METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, BtnWidth, oFont, bInit, ;
            bSize, bPaint, ctooltip, tcolor, bcolor, lTransp,lVertical, aitem ) CLASS hToolBar

   //HB_SYMBOL_UNUSED( cCaption )
   HB_SYMBOL_UNUSED( lTransp )

   DEFAULT  aitem TO { }
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor )
   HWG_InitCommonControlsEx()
   ::lTransp := IIF( lTransp != NIL, lTransp, .F. )
   ::BtnWidth := IIF( BtnWidth != Nil, BtnWidth, 32 )
   ::lVertical := IIF( lVertical != NIL, lVertical, ::lVertical )

   ::aitem := aitem

   ::Activate()

   RETURN Self


METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
                 bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aItem )  CLASS hToolBar

   //HB_SYMBOL_UNUSED( cCaption )
   HB_SYMBOL_UNUSED( lTransp )

   DEFAULT  aItem TO { }
   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor )
   HWG_InitCommonControlsEx()
   ::aItem := aItem

   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0

   RETURN Self


METHOD Activate CLASS hToolBar

   IF ! Empty( ::oParent:handle )
      ::lCreate := .T.
      ::handle := CREATETOOLBAR( ::oParent:handle, ::id, ;
                                 ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::extStyle )

      ::Init()
   ENDIF
   RETURN Nil

METHOD INIT CLASS hToolBar

   IF ! ::lInit
      Super:Init()
      ::CreateTool()
   ENDIF

   RETURN Nil

METHOD CREATETOOL CLASS hToolBar
   LOCAL n, n1
   LOCAL aTemp
   LOCAL hIm
   LOCAL aButton := { }
   LOCAL aBmpSize
   LOCAL nPos
   LOCAL nmax
   LOCAL nStyle
   
     IF Empty( ::handle ) 
        RETURN Nil
		 ENDIF   
		 IF !::lCreate 
			   DESTROYWINDOW( ::Handle )    
			   ::activate()
	   ENDIF
     IF ::lVertical
        ::Style := SendMessage( ::handle, TB_GETSTYLE, 0, 0 ) + CCS_VERT
        SendMessage( ::handle, TB_SETSTYLE, 0, nStyle )
     ENDIF
   
      FOR n := 1 TO Len( ::aItem )

         IF ValType( ::aItem[ n, 7 ] ) == "B"

            ::oParent:AddEvent( BN_CLICKED, ::aItem[ n, 2 ], ::aItem[ n , 7 ] )

         ENDIF

         IF ValType( ::aItem[ n, 9 ] ) == "A"

            ::aItem[ n, 10 ] := hwg__CreatePopupMenu()
            aTemp := ::aItem[ n, 9 ]

            FOR n1 := 1 TO Len( aTemp )
               hwg__AddMenuItem( ::aItem[ n, 10 ], aTemp[ n1, 1 ], - 1, .F., aTemp[ n1, 2 ], , .F. )
               ::oParent:AddEvent( BN_CLICKED, aTemp[ n1, 2 ], aTemp[ n1, 3 ] )
            NEXT

         ENDIF

         IF ValType( ::aItem[ n, 1 ] )  == "C"
           IF At(".", ::aitem[ n, 1 ] ) != 0
              AAdd( aButton, LoadImage( , ::aitem[ n, 1 ] , IMAGE_BITMAP, 0, 0, LR_DEFAULTSIZE + LR_CREATEDIBSECTION+ LR_LOADFROMFILE ) )
           ELSE
              AAdd( aButton, HBitmap():AddResource( ::aitem[ n, 1 ] ):handle )
           ENDIF
            ::aItem[ n , 1 ] := n

         ELSE
            IF ::aItem[ n, 1 ] > 0
               AAdd( aButton, LoadImage( , ::aitem[ n, 1 ] , IMAGE_BITMAP, 0, 0, LR_DEFAULTSIZE + LR_CREATEDIBSECTION ) )
            ENDIF
         ENDIF

      NEXT

      IF Len( aButton ) > 0


         aBmpSize := GetBitmapSize( aButton[ 1 ] )
         nmax := aBmpSize[ 3 ]

         FOR n := 2 TO Len( aButton )
            aBmpSize := GetBitmapSize( aButton[ n ] )
            nmax := Max( nmax, aBmpSize[ 3 ] )
         NEXT


         IF nmax == 4
            hIm := CreateImageList( { } , aBmpSize[ 1 ], aBmpSize[ 2 ], 1, ILC_COLOR4 + ILC_MASK )
         ELSEIF nmax == 8
            hIm := CreateImageList( { } , aBmpSize[ 1 ], aBmpSize[ 2 ], 1, ILC_COLOR8 + ILC_MASK )
         ELSEIF nmax == 24
            hIm := CreateImageList( { } , aBmpSize[ 1 ], aBmpSize[ 2 ], 1, ILC_COLORDDB + ILC_MASK )
         ENDIF

         FOR nPos := 1 TO Len( aButton )

            aBmpSize := GetBitmapSize( aButton[ nPos ] )

            IF aBmpSize[ 3 ] == 24
//             Imagelist_AddMasked( hIm,aButton[nPos],RGB(236,223,216) )
               Imagelist_Add( hIm, aButton[ nPos ] )
            ELSE
               Imagelist_Add( hIm, aButton[ nPos ] )
            ENDIF

         NEXT

         SendMessage( ::Handle, TB_SETIMAGELIST, 0, hIm )

      ENDIF
      IF Len( ::aItem ) > 0
         TOOLBARADDBUTTONS( ::handle, ::aItem, Len( ::aItem ) )

         SendMessage( ::handle, TB_SETEXTENDEDSTYLE, 0, TBSTYLE_EX_DRAWDDARROWS )
      ENDIF
      
      IF ::BtnWidth != Nil
        IF  ! ::lVertical
           SENDMESSAGE( ::handle, TB_SETBUTTONSIZE, 0,  MAKELPARAM( ::BtnWidth, ::nHeight - 2 ) )
        ELSE
           SENDMESSAGE( ::handle, TB_SETBUTTONSIZE, 0,  MAKELPARAM( ::nWidth - 2, ::BtnWidth ) )
				ENDIF   
      ENDIF   
      IF ::lTransp
         nStyle := SendMessage( ::handle, TB_GETSTYLE, 0, 0 ) + TBSTYLE_TRANSPARENT
         SendMessage( ::handle, TB_SETSTYLE, 0, nStyle )
      ENDIF
      

   RETURN Nil


METHOD Notify( lParam ) CLASS hToolBar

   LOCAL nCode :=  GetNotifyCode( lParam )
   LOCAL nId

   LOCAL nButton
   LOCAL nPos

   IF nCode == TTN_GETDISPINFO

      nButton := TOOLBAR_GETDISPINFOID( lParam )
      nPos := AScan( ::aItem,  { | x | x[ 2 ] == nButton } )
      TOOLBAR_SETDISPINFO( lParam, ::aItem[ nPos, 8 ] )

   ELSEIF nCode == TBN_GETINFOTIP

      nId := TOOLBAR_GETINFOTIPID( lParam )
      nPos := AScan( ::aItem,  { | x | x[ 2 ] == nId } )
      TOOLBAR_GETINFOTIP( lParam, ::aItem[ nPos, 8 ] )

   ELSEIF nCode == TBN_DROPDOWN
      nId := TOOLBAR_SUBMENUEXGETID( lParam )
      IF nId > 0 //valtype(::aItem[1,9]) ="A"
//       nid := TOOLBAR_SUBMENUEXGETID( lParam )
         nPos := AScan( ::aItem,  { | x | x[ 2 ] == nId } )
         TOOLBAR_SUBMENUEx( lParam, ::aItem[ nPos, 10 ], ::oParent:handle )
      ELSE
         TOOLBAR_SUBMENU( lParam, 1, ::oParent:handle )
      ENDIF
   ENDIF

   RETURN 0

METHOD REFRESH() CLASS htoolbar
   IF ::lInit
      ::lInit := .f.
   ENDIF
   ::init()
   RETURN nil

METHOD AddButton( nBitIp, nId, bState, bStyle, cText, bClick, c, aMenu ) CLASS hToolBar
   LOCAL hMenu := Nil

   DEFAULT nBitIp TO - 1
   DEFAULT bState TO TBSTATE_ENABLED
   DEFAULT bStyle TO 0x0000
   DEFAULT c TO ""
   DEFAULT cText TO ""
   AAdd( ::aItem , { nBitIp, nId, bState, bStyle, 0, cText, bClick, c, aMenu, hMenu } )

   RETURN Self


CLASS HToolBarEX INHERIT HToolBar

//method onevent()
   METHOD init()
   METHOD ExecuteTool( nid )
   DESTRUCTOR MyDestructor
END CLASS


METHOD init CLASS htoolbarex
   ::Super:init()
   SetWindowObject( ::handle, Self )
   SETTOOLHANDLE( ::handle )
   Sethook()
   RETURN Self

//method onEvent(msg,w,l) class htoolbarex
//Local nId
//Local nPos
//  if msg == WM_KEYDOWN
//
//  return -1
//  elseif msg==WM_KEYUP
//  unsethook()
//  return -1
//  endif
//return 0

METHOD ExecuteTool( nid ) CLASS htoolbarex
   LOCAL nPos
   nPos := AScan( ::aItem, { | x | x[ 2 ] == nid } )
   IF nid > 0
      SendMessage( ::oParent:handle, WM_COMMAND, makewparam( nid, BN_CLICKED ), ::handle )
      RETURN 0
   ENDIF
   RETURN - 200
STATIC FUNCTION IsAltShift( lAlt )
   LOCAL cKeyb := GetKeyboardState()

   IF lAlt == Nil ; lAlt := .T. ; ENDIF
   RETURN ( lAlt .AND. ( Asc( SubStr( cKeyb, VK_MENU + 1, 1 ) ) >= 128 ) )


PROCEDURE MyDestructor CLASS htoolbarex
   unsethook()
   RETURN
