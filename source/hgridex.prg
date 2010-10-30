 /*
 * $Id: hgridex.prg,v 1.26 2010-10-30 16:43:31 mlacecilia Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HGrid class
 *
 * Copyright 2004 Rodrigo Moreno <rodrigo_moreno@yahoo.com>
 *
 * Extended function Copyright 2006 Luiz Rafael Culik Guimaraes <luiz@xharbour.com.br>
*/


#include "windows.ch"
#include "guilib.ch"
#include "hbclass.ch"
#include "common.ch"
#define LVS_REPORT              1
#define LVS_SINGLESEL           4
#define LVS_SHOWSELALWAYS       8
#define LVS_OWNERDATA        4096

#define LVN_ITEMCHANGED      - 101
#define LVN_KEYDOWN          - 155
#define LVN_GETDISPINFO      - 150
#define NM_DBLCLK              - 3
#define NM_RETURN              - 4  // (NM_FIRST-4)
#define NM_SETFOCUS            - 7
#define NM_KILLFOCUS           - 8


CLASS HGridEX INHERIT HControl

CLASS VAR winclass INIT "SYSLISTVIEW32"
   DATA aBitMaps   INIT { }
   DATA aItems     INIT { }
   DATA ItemCount
   DATA color
   DATA bFlag      INIT .f.
   DATA bkcolor
   DATA aColumns   INIT { }
   DATA nRow       INIT 0
   DATA nCol       INIT 0
   DATA aColors    INIT { }
   DATA hSort
   DATA oMenu

   DATA lNoScroll  INIT .F.
   DATA lNoBorder  INIT .F.
   DATA lNoLines   INIT .F.
   DATA lNoHeader  INIT .F.

   DATA bEnter
   DATA bKeyDown
   DATA bPosChg
   DATA bDispInfo
   DATA him
   DATA bGfocus
   DATA bLfocus
   DATA aRow       INIT { }
   DATA aRowBitMap INIT { }
   DATA aRowStyle  INIT { }
   DATA iRowSelect INIT  0

   METHOD New( oWnd, nId, nStyle, x, y, width, height, oFont, bInit, bSize, bPaint, bEnter, ;
               bGfocus, bLfocus, lNoScroll, lNoBord, bKeyDown, bPosChg, bDispInfo, ;
               nItemCount, lNoLines, color, bkcolor, lNoHeader, aBit, aItems )

   METHOD Activate()
   METHOD Init()
   METHOD AddColumn( cHeader, nWidth, nJusHead, nBit ) INLINE AAdd( ::aColumns, { cHeader, nWidth, nJusHead, nBit } )
   METHOD Refresh()
   METHOD RefreshLine()                          INLINE Listview_update( ::handle, Listview_getfirstitem( ::handle ) )
   METHOD SetItemCount( nItem )                    INLINE Listview_setitemcount( ::handle, nItem )
   METHOD Row()                                  INLINE Listview_getfirstitem( ::handle )
   METHOD AddRow( a, bUpdate )
   METHOD Notify( lParam )

   METHOD DELETEROW()    INLINE IF( ::bFlag , ( SendMessage( ::HANDLE, LVM_DELETEITEM, ::iRowSelect , 0 ), ::bFlag := .f. ), .T. )
   METHOD DELETEALLROW() INLINE ::aItems := NIL, ::aColors := { }, SendMessage( ::Handle, LVM_DELETEALLITEMS, 0, 0 )
   METHOD SELECTALL()    INLINE ListViewSelectAll( ::Handle )
   METHOD SELECTLAST()   INLINE ListViewSelectLastItem( ::handle )
   METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aItem )
   METHOD UpdateData()
   METHOD SETVIEW( style )  INLINE LISTVIEW_SETVIEW( ::handle, style )
ENDCLASS


METHOD New( oWnd, nId, nStyle, x, y, width, height, oFont, bInit, bSize, bPaint, bEnter, ;
            bGfocus, bLfocus, lNoScroll, lNoBord, bKeyDown, bPosChg, bDispInfo, ;
            nItemCount, lNoLines, color, bkcolor, lNoHeader, aBit, aItems ) CLASS HGridEx

   HB_SYMBOL_UNUSED( nItemCount )

   //nStyle := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), WS_VISIBLE + WS_CHILD + WS_TABSTOP + LVS_REPORT )
   nStyle := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), WS_TABSTOP + WS_BORDER   )
   Super:New( oWnd, nId, nStyle, x, y, width, height, oFont, bInit, ;
              bSize, bPaint )
   DEFAULT aBit TO { }
   ::aItems := aItems
   ::ItemCount := Len( aItems )
   ::aBitMaps := aBit
   ::bGfocus := bGfocus
   ::bLfocus := bLfocus

   ::color   := color
   ::bkcolor := bkcolor

   ::lNoScroll := lNoScroll
   ::lNoBorder := lNoBord
   ::lNoLines  := lNoLines
   ::lNoHeader := lNoHeader

   ::bEnter    := bEnter
   ::bKeyDown  := bKeyDown
   ::bPosChg   := bPosChg
   ::bDispInfo := bDispInfo


   HWG_InitCommonControlsEx()

   ::Activate()


   RETURN Self

METHOD Activate() CLASS HGridEx
   IF ! Empty( ::oParent:handle )
      ::Style :=  ::Style - WS_BORDER
      ::handle := ListView_Create ( ::oParent:handle, ::id, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::style, ::lNoHeader, ::lNoScroll )
      ::Init()
   ENDIF
   RETURN Nil

METHOD Init() CLASS HGridEx
   LOCAL i, nPos
   LOCAL aButton := { }
   LOCAL aBmpSize
   LOCAL n
   LOCAL n1
   LOCAL aTemp, aTemp1, nmax

   IF ! ::lInit
      Super:Init()
      ::nHolder := 1

      FOR n := 1 TO Len( ::aBitmaps )
         AAdd( aButton, LoadImage( , ::aBitmaps[ n ] , IMAGE_BITMAP, 0, 0, LR_DEFAULTSIZE + LR_CREATEDIBSECTION ) )
      NEXT

      IF Len( aButton ) > 0

         aBmpSize := GetBitmapSize( aButton[ 1 ] )
         nmax := aBmpSize[ 3 ]
         FOR n := 2 TO Len( aButton )
            aBmpSize := GetBitmapSize( aButton[ n ] )
            nmax := Max( nmax, aBmpSize[ 3 ] )
         NEXT


         IF nmax == 4
            ::hIm := CreateImageList( { } , aBmpSize[ 1 ], aBmpSize[ 2 ], 1, ILC_COLOR4 + ILC_MASK )
         ELSEIF nmax == 8
            ::hIm := CreateImageList( { } , aBmpSize[ 1 ], aBmpSize[ 2 ], 1, ILC_COLOR8 + ILC_MASK )
         ELSEIF nmax == 24
            ::hIm := CreateImageList( { } , aBmpSize[ 1 ], aBmpSize[ 2 ], 1, ILC_COLORDDB + ILC_MASK )
         ENDIF

         FOR nPos := 1 TO Len( aButton )

            aBmpSize := GetBitmapSize( aButton[ nPos ] )

            IF aBmpSize[ 3 ] == 24
               Imagelist_Add( ::hIm, aButton[ nPos ] )
            ELSE
               Imagelist_Add( ::hIm, aButton[ nPos ] )
            ENDIF

         NEXT

         Listview_setimagelist( ::handle, ::him )

      ENDIF

      Listview_Init( ::handle, ::ItemCount, ::lNoLines )

      FOR i := 1 TO Len( ::aColumns )
         Listview_addcolumnEX( ::handle, i, ::aColumns[ i, 1 ], ::aColumns[ i , 2 ], ::aColumns[ i, 3 ], IF( ::aColumns[ i, 4 ] != NIL, ::aColumns[ i, 4 ]  , - 1 ) )

      NEXT
      IF Len( ::aRow ) > 0
         FOR n := 1 TO Len( ::aRow )
            aTemp := ::aRow[ n ]
            aTemp1 := ::aRowBitMap[ n ]
            FOR n1 := 1 TO Len( aTemp )
               LISTVIEW_INSERTITEMEX( ::handle, n, n1, aTemp[ n1 ], aTemp1[ n1 ] )
            NEXT
         NEXT

      ENDIF
      IF ::color != nil
         ListView_SetTextColor( ::handle, ::color )

      ENDIF

      IF ::bkcolor != nil
         Listview_setbkcolor( ::handle, ::bkcolor )
         Listview_settextbkcolor( ::handle, ::bkcolor )
      ENDIF
   ENDIF
   RETURN Nil

METHOD Refresh() CLASS HGridEx
   LOCAL iFirst, iLast

   iFirst := ListView_GetTopIndex( ::handle )

   iLast := iFirst + ListView_GetCountPerPage( ::handle )

   ListView_RedrawItems( ::handle , iFirst, iLast )
   RETURN Nil


METHOD AddRow( a , bupdate ) CLASS HGRIDEX
   LOCAL nLen := Len( a )
   LOCAL n
   LOCAL aTmp := { }
   LOCAL aTmp1 := { }
   LOCAL aTmp2 := { }


   DEFAULT bupdate TO .f.
   FOR n := 1 TO nLen STEP 4
      AAdd( aTmp1, a[ n ] )
      AAdd( aTmp,  IF( ValType( a[ n + 1 ] ) == "N", a[ n + 1 ], - 1 ) )

      AAdd( aTmp2,  IF( ValType( a[ n + 2  ] ) == "N", a[ n + 2 ], RGB( 12, 15, 46 ) ) )


      AAdd( aTmp2,  IF( ValType( a[ n + 3  ] ) == "N", a[ n + 3 ], RGB( 192, 192, 192 ) ) )

      AAdd( ::aColors, aTmp2 )
      aTmp2 := { }
   NEXT

   AAdd( ::aRowBitMap, aTmp )
   AAdd( ::aRow,    aTmp1 )
   IF bupdate
      ::updatedata()
   ENDIF

   RETURN nil

METHOD Notify( lParam )  CLASS HGRIDEX
   LOCAL nCode := GetNotifyCode( lParam )
   LOCAL Res, iSelect, oParent := ::GetParentForm()

   IF nCode == NM_CUSTOMDRAW .and. GETNOTIFYCODEFROM( lParam ) == ::Handle
      Res := PROCESSCUSTU( ::handle, lParam, ::aColors )
      Hwg_SetDlgResult( oParent:Handle, Res )
      RETURN Res
   ENDIF

   IF nCode == NM_CLICK
      iSelect = SendMessage( ::handle, LVM_GETNEXTITEM, - 1, LVNI_FOCUSED )

      IF( iSelect == - 1 )
         RETURN 0
      ENDIF

      ::iRowSelect := iSelect
      ::bFlag := .t.
      RETURN 1
   ENDIF

   IF nCode == LVN_COLUMNCLICK //.and. GETNOTIFYCODEFROM(lParam) == ::Handle
      IF Empty( ::hsort )
         ::hSort := LISTVIEWSORTINFONEW( lParam, nil )
      ENDIF
      LISTVIEWSORT( ::handle, lParam, ::hSort )
      RETURN  0
   ENDIF
   IF nCode == NM_SETFOCUS
   ELSEIF nCode == NM_KILLFOCUS
   ENDIF
   IF nCode == NM_RETURN
   ENDIF
   IF nCode == LVN_KEYDOWN
   ENDIF

   Res := ListViewNotify( Self, lParam )
   IF ValType( Res ) == "N"
      Hwg_SetDlgResult( oParent:Handle, Res )
      //RETURN 1
   ENDIF
   RETURN Res

METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
                 bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aItem )  CLASS hGridex

   HB_SYMBOL_UNUSED( cCaption )
   HB_SYMBOL_UNUSED( lTransp )

   DEFAULT  aItem TO { }
   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor )
   HWG_InitCommonControlsEx()
   ::arow := aItem

   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0

   RETURN Self

METHOD UpdateData() CLASS hGridex
   LOCAL n := Len( ::aRow ), n1
   LOCAL aTemp, atemp1

   aTemp := ::aRow[ n ]
   atemp1 := ::aRowBitMap[ n ]

   FOR n1 := 1 TO Len( aTemp )

      LISTVIEW_INSERTITEMEX( ::handle, n, n1, aTemp[ n1 ], atemp1[ n1 ] )
   NEXT

   RETURN .t.
