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
#DEFINE IDTOOLBAR 700
#define TB_SETBITMAPSIZE        (WM_USER + 32)
#define TB_SETINDENT            (WM_USER + 47)
#define TB_SETBUTTONWIDTH       (WM_USER + 59)

CLASS HToolButton INHERIT HObject

   DATA Name
   DATA id
   DATA nBitIp INIT -1
   DATA bState INIT TBSTATE_ENABLED
   DATA bStyle INIT  0x0000
   DATA tooltip 
   DATA aMenu INIT {}
   DATA hMenu
   DATA Caption 
   DATA lEnabled  INIT .T. HIDDEN
   ACCESS Enabled  INLINE ::lEnabled  
   ASSIGN Enabled( l ) INLINE ::lEnabled := l,IIF( l, ::enable(),::disable())
   DATA oParent
   //DATA oFont   // not implemented
   
   METHOD New(oParent,cName,nBitIp,nId,bState,bStyle,cText,bClick,ctip, aMenu )
   METHOD Enable() INLINE ::oParent:EnableButton( ::id, .T. )
   METHOD Disable() INLINE ::oParent:EnableButton( ::id, .F. )
   METHOD Show() INLINE hwg_Sendmessage( ::oParent:handle, TB_HIDEBUTTON, INT( ::id ), hwg_Makelong( 0, 0 ) )
   METHOD Hide() INLINE hwg_Sendmessage( ::oParent:handle, TB_HIDEBUTTON, INT( ::id ), hwg_Makelong( 1, 0 ) )         
																										  
ENDCLASS

METHOD New(oParent,cName,nBitIp,nId,bState,bStyle,cText,bClick,ctip,aMenu) CLASS  HToolButton

   ::Name := cName
   ::iD := nId
   ::Caption := cText
   ::nBitIp := nBitIp
   ::bState := bState
   ::bStyle := bStyle
   ::tooltip := ctip
   ::aMenu := amenu
	 ::oParent := oParent
	  __objAddData(::oParent, cName)
	 ::oParent:&(cName) := Self
   
RETURN Self

   

CLASS HToolBar INHERIT HControl

   DATA winclass INIT "ToolbarWindow32"
   DATA TEXT, id, nTop, nLeft, nwidth, nheight
   CLASSDATA oSelected INIT Nil
   DATA State INIT 0
   DATA ExStyle
   DATA bClick, cTooltip

   DATA lPress INIT .F.
   DATA lFlat
   DATA lTransp    INIT .F. //
   DATA lVertical  INIT .F. //
   DATA lCreate    INIT .F. HIDDEN 
   DATA nOrder
   DATA BtnWidth  //
   DATA nIDB       
   DATA aButtons    INIT {}
   DATA aSeparators INIT {}
   Data aItem       INIT {}
   DATA Line
   DATA nIndent
   DATA nSize

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,btnWidth,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp, lVertical ,aItem, nSize,nIndent, nIDB )
   METHOD Redefine( oWndParent, nId, oFont, bInit, ;
                    bSize, bPaint, ctooltip, tcolor, bcolor, lTransp , aItem )

   METHOD Activate()
   METHOD INIT()
   METHOD CreateTool()
   METHOD AddButton( a, s, d, f, g, h )
   METHOD Notify( lParam )
   METHOD EnableButton( idButton, lEnable ) INLINE hwg_Sendmessage( ::handle, TB_ENABLEBUTTON, INT( idButton ), hwg_Makelong( IIF( lEnable, 1, 0 ), 0) )
   METHOD ShowButton( idButton ) INLINE hwg_Sendmessage( ::handle, TB_HIDEBUTTON, INT( idButton ), hwg_Makelong( 0, 0 ) )
   METHOD HideButton( idButton ) INLINE hwg_Sendmessage( ::handle, TB_HIDEBUTTON, INT( idButton ), hwg_Makelong( 1, 0 ) )         
   METHOD REFRESH()
   
ENDCLASS

METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,btnWidth,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp, lVertical ,aItem, nSize,nIndent, nIDB ) CLASS hToolBar

   //HB_SYMBOL_UNUSED( cCaption )
   HB_SYMBOL_UNUSED( lTransp )

   DEFAULT  aitem TO { }
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor )
   HWG_InitCommonControlsEx()
   ::lTransp := IIF( lTransp != NIL, lTransp, .F. )
   ::BtnWidth :=  BtnWidth //!= Nil, BtnWidth, 32 )
   ::lVertical := IIF( lVertical != NIL .AND. TYPE( "lVertical" ) = "L", lVertical, ::lVertical )
   ::nIDB := nIDB
   ::aItem := aItem
   ::nIndent := IIF( nIndent != NIL , nIndent, 1 )
   ::nSize := IIF( nSize != NIL .AND. nSize > 11 , nSize, Nil ) 

   IF ! ::lVertical
       ::Line := HLine():New(oWndParent,,,nLeft,nTop + nHeight + 1,nWidth)
   ELSE
       ::Line := HLine():New(oWndParent,,::lVertical,nLeft + nWidth + 1 ,nTop,nHeight)      
   ENDIF   

   ::Activate()
   
   RETURN Self


METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
                 bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aItem )  CLASS hToolBar

   //HB_SYMBOL_UNUSED( cCaption )
   HB_SYMBOL_UNUSED( lTransp )

   DEFAULT  aItem TO { }
   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor )
   HWG_InitCommonControlsEx()
   ::aItem := aItem

   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0

   RETURN Self


METHOD Activate CLASS hToolBar

   IF ! Empty( ::oParent:handle )
      ::lCreate := .T.
      ::handle := hwg_Createtoolbar( ::oParent:handle, ::id, ;
                                 ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::extStyle )

      ::Init()
   ENDIF
   RETURN Nil

METHOD INIT CLASS hToolBar

   IF ! ::lInit
      IF ::Line != Nil
         ::Line:Anchor := ::Anchor 
      ENDIF   
      ::Super:Init()
      ::CreateTool()
   ENDIF

   RETURN Nil

METHOD CREATETOOL CLASS hToolBar
Local n,n1
Local aTemp
Local hIm
Local aButton :={}
Local aBmpSize
Local nPos
Local nmax
Local nStyle
Local hImage, img, nlistimg, ndrop := 0

     IF Empty( ::handle ) 
        RETURN Nil
		 ENDIF   
		 IF !::lCreate 
			   hwg_Destroywindow( ::Handle )    
			   ::activate()
	   ENDIF
     IF ::lVertical
        nStyle := hwg_Sendmessage( ::handle, TB_GETSTYLE, 0, 0 ) + CCS_VERT
        hwg_Sendmessage( ::handle, TB_SETSTYLE, 0, nStyle )
     ENDIF
     img := 0
     nlistimg := 0
     IF ::nIDB != Nil .AND. ::nIDB >= 0
        nlistimg := hwg_Toolbar_loadstandartimage( ::handle, ::nIDB )  
     ENDIF   

      FOR n := 1 TO Len( ::aItem )

         IF ValType( ::aItem[ n, 7 ] ) == "B"

            ::oParent:AddEvent( BN_CLICKED, ::aItem[ n, 2 ], ::aItem[ n , 7 ] )

         ENDIF

         IF ValType( ::aItem[ n, 9 ] ) == "A"

            ::aItem[ n, 10 ] := hwg__CreatePopupMenu()
            ::aItem[ n, 11 ]:hMenu := ::aItem[ n, 10 ]
            aTemp := ::aItem[ n, 9 ]

            FOR n1 := 1 TO Len( aTemp )
               hwg__AddMenuItem( ::aItem[ n, 10 ], aTemp[ n1, 1 ], - 1, .F., aTemp[ n1, 2 ], , .F. )
               ::oParent:AddEvent( BN_CLICKED, aTemp[ n1, 2 ], aTemp[ n1, 3 ] )
            NEXT

         ENDIF

       	 IF ::aItem[ n, 4 ] = BTNS_SEP
				    LOOP
				 ENDIF
				 
				 nDrop := IIF( nDrop = 8, nDrop, IIF( Hwg_Bitand(::aItem[ n, 4 ], BTNS_DROPDOWN ) != 0 .AND.::aItem[ n, 4 ] < 128, 8, 1 ) )
				 IF ::nSize != Nil
				    //hwg_Sendmessage( ::HANDLE ,TB_SETBITMAPSIZE,0, hwg_Makelong ( ::nSize, ::nSize ) )
				 ENDIF   

         IF ValType( ::aItem[ n, 1 ] )  == "C"
            IF At(".", ::aitem[ n, 1 ] ) != 0
               //AAdd( aButton, hwg_Loadimage( , ::aitem[ n, 1 ] , IMAGE_BITMAP, 0, 0, LR_DEFAULTSIZE + LR_CREATEDIBSECTION+ LR_LOADFROMFILE ) )
               hImage := HBITMAP():AddFile( ::aitem[ n, 1 ], , .T., ::nSize, ::nSize ):handle 
            ELSE
              // AAdd( aButton, HBitmap():AddResource( ::aitem[ n, 1 ] ):handle )
               hImage := HBitmap():AddResource( ::aitem[ n, 1 ], LR_LOADTRANSPARENT + LR_LOADMAP3DCOLORS, ,::nSize,::nSize ):handle 
            ENDIF
            IF ( img := Ascan( aButton, hImage )) = 0
               AAdd( aButton, hImage ) 
               img := Len( aButton )
            ENDIF
            ::aItem[n ,1 ] := img + nlistimg //n
            hwg_Toolbar_loadimage( ::Handle, aButton[ img ])          

         ELSE
            IF ::aItem[ n, 1 ] > 0
              // AAdd( aButton, hwg_Loadimage( , ::aitem[ n, 1 ] , IMAGE_BITMAP, 0, 0, LR_DEFAULTSIZE + LR_CREATEDIBSECTION ) )
            ENDIF
         ENDIF

      NEXT
			/*
      IF Len( aButton ) > 0

         aBmpSize := hwg_Getbitmapsize( aButton[ 1 ] )
         nmax := aBmpSize[ 3 ]

         FOR n := 2 TO Len( aButton )
            aBmpSize := hwg_Getbitmapsize( aButton[ n ] )
            nmax := Max( nmax, aBmpSize[ 3 ] )
         NEXT
         aBmpSize := hwg_Getbitmapsize( aButton[ 1 ] )
         
         IF nmax == 4
            hIm := hwg_Createimagelist( { } , aBmpSize[ 1 ], aBmpSize[ 2 ], 1, ILC_COLOR4 + ILC_MASK )
         ELSEIF nmax == 8
            hIm := hwg_Createimagelist( { } , aBmpSize[ 1 ], aBmpSize[ 2 ], 1, ILC_COLOR8 + ILC_MASK )
         ELSEIF nMax == 16 //
             hIm := hwg_Createimagelist( {} ,aBmpSize[ 1 ], aBmpSize[ 2 ], 1, ILC_COLORDDB + ILC_MASK )
         ELSEIF nmax == 24
            hIm := hwg_Createimagelist( { } , aBmpSize[ 1 ], aBmpSize[ 2 ], 1, ILC_COLORDDB + ILC_MASK )
         ENDIF

         FOR nPos := 1 TO Len( aButton )

            aBmpSize := hwg_Getbitmapsize( aButton[ nPos ] )

            IF aBmpSize[ 3 ] == 24
//             hwg_Imagelist_addmasked( hIm,aButton[nPos],hwg_Rgb(236,223,216) )
               hwg_Imagelist_add( hIm, aButton[ nPos ] )
            ELSE
               hwg_Imagelist_add( hIm, aButton[ nPos ] )
            ENDIF

         NEXT

         hwg_Sendmessage( ::Handle, TB_SETIMAGELIST, 0, hIm )

      ENDIF
      */
      
      hwg_Sendmessage( ::Handle, TB_SETINDENT, ::nIndent,  0)
      IF Len( ::aItem ) > 0
         hwg_Toolbaraddbuttons( ::handle, ::aItem, Len( ::aItem ) )
        hwg_Sendmessage( ::handle, TB_SETEXTENDEDSTYLE, 0, TBSTYLE_EX_DRAWDDARROWS )
      ENDIF

      IF ::BtnWidth != Nil
         IF  ! ::lVertical   //                -2 s nÆo tiver menu - 9 se tiver menu tipo 8
           hwg_Sendmessage( ::handle, TB_SETBUTTONSIZE, 0,  hwg_Makelparam( ::BtnWidth, ::nHeight - nDrop - 1 ) )
         ELSE
           hwg_Sendmessage( ::handle, TB_SETBUTTONSIZE, 0,  hwg_Makelparam( ::nWidth - nDrop - 1, ::BtnWidth )  )
			 	 ENDIF   
      ENDIF         
      
      IF ::lTransp
         nStyle := hwg_Sendmessage( ::handle, TB_GETSTYLE, 0, 0 ) + TBSTYLE_TRANSPARENT
         hwg_Sendmessage( ::handle, TB_SETSTYLE, 0, nStyle )
      ENDIF
      

   RETURN Nil


METHOD Notify( lParam ) CLASS hToolBar

   LOCAL nCode :=  hwg_Getnotifycode( lParam )
   LOCAL nId

   LOCAL nButton
   LOCAL nPos

   IF nCode == TTN_GETDISPINFO

      nButton := hwg_Toolbar_getdispinfoid( lParam )
      nPos := AScan( ::aItem,  { | x | x[ 2 ] == nButton } )
      hwg_Toolbar_setdispinfo( lParam, ::aItem[ nPos, 8 ] )

   ELSEIF nCode == TBN_GETINFOTIP

      nId := hwg_Toolbar_getinfotipid( lParam )
      nPos := AScan( ::aItem,  { | x | x[ 2 ] == nId } )
      hwg_Toolbar_getinfotip( lParam, ::aItem[ nPos, 8 ] )

   ELSEIF nCode == TBN_DROPDOWN
      nId := hwg_Toolbar_submenuexgetid( lParam )
      IF nId > 0 //valtype(::aItem[1,9]) ="A"
//       nid := hwg_Toolbar_submenuexgetid( lParam )
         nPos := AScan( ::aItem,  { | x | x[ 2 ] == nId } )
         hwg_Toolbar_submenuex( lParam, ::aItem[ nPos, 10 ], ::oParent:handle )
      ELSE
         hwg_Toolbar_submenu( lParam, 1, ::oParent:handle )
      ENDIF
   ENDIF

   RETURN 0

METHOD REFRESH() CLASS htoolbar
   /*
   IF ::lInit
      ::lInit := .f.
   ENDIF
   ::init()
   */
   RETURN nil

METHOD AddButton(nBitIp,nId,bState,bStyle,cText,bClick,c,aMenu, cName) CLASS hToolBar
   Local hMenu := Nil, oButton

   DEFAULT nBitIp to -1
   DEFAULT bstate to TBSTATE_ENABLED
   DEFAULT bstyle to 0x0000
   DEFAULT c to ""
   DEFAULT ctext to ""
   IF nId = Nil .OR. EMPTY( nId )
      //IDTOOLBAR
      nId := ::id + IDTOOLBAR + LEN( ::aButtons ) + LEN( ::aSeparators ) + 1
   ENDIF   
   
   IF bStyle != BTNS_SEP  //1
      DEFAULT cName to "oToolButton" + LTRIM( STR( LEN( ::aButtons ) + 1 ) )
      AAdd( ::aButtons,{ cName, nid } )
   ELSE
      bstate :=  IIF( !( ::lVertical .AND. LEN( ::aButtons) = 0 ), bState, 8 )//TBSTATE_HIDE
      DEFAULT nBitIp to 0
      DEFAULT cName to "oSeparator"+LTRIM( STR( LEN( ::aSeparators ) + 1 ) )
      AAdd( ::aSeparators,{ cName, nid } )
   ENDIF
   
   oButton := HToolButton():New(Self,cName,nBitIp,nId,bState,bStyle,cText,bClick, c ,aMenu) 	 
   AAdd( ::aItem ,{ nBitIp, nId, bState, bStyle, 0, cText, bClick, c, aMenu, hMenu, oButton } )
   
   RETURN oButton


CLASS HToolBarEX INHERIT HToolBar

//method onevent()
   METHOD init()
   METHOD ExecuteTool( nid )
   DESTRUCTOR MyDestructor
END CLASS


METHOD init CLASS htoolbarex
   ::Super:init()
   hwg_Setwindowobject( ::handle, Self )
   hwg_Settoolhandle( ::handle )
   hwg_Sethook()
   RETURN Self

METHOD ExecuteTool( nid ) CLASS htoolbarex
   LOCAL nPos
   nPos := AScan( ::aItem, { | x | x[ 2 ] == nid } )
   IF nid > 0
      hwg_Sendmessage( ::oParent:handle, WM_COMMAND, hwg_Makewparam( nid, BN_CLICKED ), ::handle )
      RETURN 0
   ENDIF
   RETURN - 200
STATIC FUNCTION IsAltShift( lAlt )
   LOCAL cKeyb := hwg_Getkeyboardstate()

   IF lAlt == Nil ; lAlt := .T. ; ENDIF
   RETURN ( lAlt .AND. ( Asc( SubStr( cKeyb, VK_MENU + 1, 1 ) ) >= 128 ) )


PROCEDURE MyDestructor CLASS htoolbarex
   hwg_Unsethook()
   RETURN
