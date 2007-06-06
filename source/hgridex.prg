 /*
 * $Id: hgridex.prg,v 1.7 2007-06-06 22:53:27 lculik Exp $
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

#define LVN_ITEMCHANGED      -101
#define LVN_KEYDOWN          -155
#define LVN_GETDISPINFO      -150
#define NM_DBLCLK              -3
#define NM_KILLFOCUS           -8
#define NM_SETFOCUS            -7

CLASS HGridEX INHERIT HControl

   CLASS VAR winclass INIT "SYSLISTVIEW32"
   DATA aBitMaps   INIT {}
   DATA aItems     INIT {}
   DATA ItemCount
   DATA color   
   DATA bkcolor
   DATA aColumns   INIT {}
   DATA nRow       INIT 0
   DATA nCol       INIT 0
   DATA aColors    INIT {}
   
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
   DATA aRow       INIT {}
   Data aRowBitMap INIT {}
   Data aRowStyle  INIT {}
   DATA iRowSelect INIT  0

   METHOD New( oWnd, nId, nStyle, x, y, width, height, oFont, bInit, bSize, bPaint, bEnter,;
               bGfocus, bLfocus, lNoScroll, lNoBord, bKeyDown, bPosChg, bDispInfo,;
               nItemCount, lNoLines, color, bkcolor, lNoHeader,aBit,aItems )

   METHOD Activate()
   METHOD Init()
   METHOD AddColumn( cHeader, nWidth, nJusHead, nBit ) INLINE AADD( ::aColumns, { cHeader, nWidth, nJusHead, nBit } )
   METHOD Refresh()
   METHOD RefreshLine()                          INLINE Listview_update( ::handle, Listview_getfirstitem( ::handle ) )
   METHOD SetItemCount(nItem)                    INLINE Listview_setitemcount( ::handle, nItem )
   METHOD Row()                                  INLINE Listview_getfirstitem( ::handle )
   METHOD AddRow( aRow )
   METHOD Notify( lParam )

   METHOD DELETEROW()    INLINE IF( ::iRowSelect > 0 ,( SendMessage( ::HANDLE, LVM_DELETEITEM, ::iRowSelect , 0), ::iRowSelect := -1 ), .T. )
   METHOD DELETEALLROW() INLINE ::aItems :=NIL, ::aColors := {}, SendMessage( ::Handle, LVM_DELETEALLITEMS, 0, 0 )
   METHOD SELECTALL()    INLINE ListViewSelectAll( ::Handle )
   METHOD SELECTLAST()   INLINE ListViewSelectLastItem( ::handle )
   METHOD Redefine( oWndParent,nId,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp ,aItem)
METHOD UpdateData()
ENDCLASS


METHOD New( oWnd, nId, nStyle, x, y, width, height, oFont, bInit, bSize, bPaint, bEnter,;
               bGfocus, bLfocus, lNoScroll, lNoBord, bKeyDown, bPosChg, bDispInfo,;
               nItemCount, lNoLines, color, bkcolor, lNoHeader,aBit,aItems ) CLASS HGridEx

   nStyle := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), WS_VISIBLE+WS_CHILD+LVS_REPORT )
   Super:New( oWnd,nId,nStyle,x,y,Width,Height,oFont,bInit, ;
                  bSize,bPaint )
   Default aBit to {}
   ::aItems := aItems
   ::ItemCount := Len(aItems)
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
   

Return Self

METHOD Activate CLASS HGridEx
   if ::oParent:handle != 0      
      ::handle := ListView_Create ( ::oParent:handle, ::id, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::style, ::lNoHeader, ::lNoScroll ) 

      ::Init()
   endif
Return Nil

METHOD Init() CLASS HGridEx
   local i,nPos
   Local aButton :={}
   Local aBmpSize
   Local n
   Local n1
   Local aItem
   Local aTemp,aTemp1

   if !::lInit
      Super:Init()
      ::nHolder := 1

      for n :=1 to Len( ::aBitmaps )
           AAdd( aButton, LoadImage( , ::aBitmaps[ n ] , IMAGE_BITMAP, 0, 0, LR_DEFAULTSIZE + LR_CREATEDIBSECTION ) )
      next

      IF Len(aButton ) >0

          aBmpSize := GetBitmapSize( aButton[1] )

          IF aBmpSize[ 3 ] == 4
             ::hIm := CreateImageList( {} ,aBmpSize[ 1 ], aBmpSize[ 2 ], 1, ILC_COLOR4 + ILC_MASK )
          ELSEIF aBmpSize[ 3 ] == 8
             ::hIm := CreateImageList( {} ,aBmpSize[ 1 ], aBmpSize[ 2 ], 1, ILC_COLOR8 + ILC_MASK )
          ELSEIF aBmpSize[ 3 ] == 24
             ::hIm := CreateImageList( {} ,aBmpSize[ 1 ], aBmpSize[ 2 ], 1, ILC_COLORDDB + ILC_MASK )
          ENDIF

          FOR nPos :=1 to len(aButton)

             aBmpSize := GetBitmapSize( aButton[nPos] )

             IF aBmpSize[3] == 24
                Imagelist_Add( ::hIm, aButton[ nPos ] )
             ELSE
                Imagelist_Add( ::hIm, aButton[ nPos ] )
             ENDIF

          NEXT

     Listview_setimagelist(::handle,::him)

endif
      
      Listview_Init( ::handle, ::ItemCount, ::lNoLines )

      for i := 1 to len( ::aColumns )
        Listview_addcolumnEX( ::handle, i, ::aColumns[ i, 1 ], ::aColumns[ i ,2 ], ::aColumns[i, 3], if( ::aColumns[ i, 4 ] != NIL, ::aColumns[ i, 4 ]  , -1))

      next
      if len(::aRow) >0
       for n := 1 to len(::aRow)
          aTemp := ::aRow[n]
          aTemp1 := ::aRowBitMap[ n ]
          for n1 := 1 to len(aTemp)
             LISTVIEW_INSERTITEMEX(::handle,n,n1,atemp[n1],atemp1[n1])
          next
       next

      endif
      if ::color != nil
        ListView_SetTextColor( ::handle, ::color ) 

      endif
      
      if ::bkcolor != nil
        Listview_setbkcolor( ::handle, ::bkcolor ) 
        Listview_settextbkcolor( ::handle, ::bkcolor ) 
      endif        
   endif
Return Nil

METHOD Refresh() CLASS HGridEx
    Local iFirst, iLast
    
    iFirst := ListView_GetTopIndex(::handle) 

    iLast := iFirst + ListView_GetCountPerPage(::handle)

    ListView_RedrawItems( ::handle , iFirst, iLast ) 
Return Nil


METHOD AddRow( a ,bupdate ) Class HGRIDEX
   Local nLen := Len( a ) 
   Local n
   Local aTmp := {}
   Local aTmp1 := {}
   Local aTmp2 := {}
  

default bupdate to .F.
   For n := 1 to nLen step 4
      aadd( aTmp1, a[ n ] )
      aadd( aTmp,  if( valtype(a[ n + 1 ] ) == "N", a[ n + 1 ], -1 ) )

      aadd( aTmp2,  if( valtype(a[ n + 2  ] ) == "N", a[ n + 2 ], RGB(12,15,46) ) )


      aadd( aTmp2,  if( valtype(a[ n + 3  ] ) == "N", a[ n + 3 ], RGB(192,192,192) ) )

      aadd(::aColors,aTmp2)
      aTmp2:={}
   next
  
   aadd( ::aRowBitMap, aTmp )
   aadd( ::aRow,    aTmp1 )
   if bUpdate
      ::updatedata()
   endif

return nil
      
METHOD Notify( lParam )  Class HGRIDEX
    Local aCord,Res

    IF GetNotifyCode( lParam ) == NM_CUSTOMDRAW .and. GETNOTIFYCODEFROM(lParam) == ::Handle
        Res := PROCESSCUSTU( ::handle, lParam, ::aColors )
        return res
    ENDIF
    Res := ListViewNotify( Self, lParam )
    IF Valtype(Res) == "N"
       Hwg_SetDlgResult( ::oParent:Handle, res )
       return 1
    ENDIF
return Res

METHOD Redefine( oWndParent,nId,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp,aItem )  CLASS hGridex
   Default  aItem to {}
   Super:New( oWndParent,nId,0,0,0,0,0,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )
   HWG_InitCommonControlsEx()
   ::arow := aItem

   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0

Return Self

METHOD UpdateData()
   Local n := Len( ::aRow ), n1
   Local aTemp,atemp1

   aTemp := ::aRow[ n ]
   aTemp1 := ::aRowBitMap[ n ]

   FOR n1 := 1 TO Len( aTemp )   
      LISTVIEW_INSERTITEMEX( ::handle, n, n1, atemp[ n1 ], atemp1[ n1 ] )
   NEXT

return .t.
