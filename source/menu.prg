/*
 * $Id: menu.prg,v 1.17 2005-09-14 15:22:06 lf_sfnet Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Prg level menu functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define  MENU_FIRST_ID   32000
#define  CONTEXTMENU_FIRST_ID   32900
#define  FLAG_DISABLED   1
#define  FLAG_CHECK      2

STATIC _aMenuDef, _oWnd, _aAccel, _nLevel, _Id, _oMenu, _oBitmap

CLASS HMenu INHERIT HObject
   DATA handle
   DATA aMenu 
   METHOD New()  INLINE Self
   METHOD End()  INLINE Hwg_DestroyMenu(::handle)
   METHOD Show( oWnd,xPos,yPos,lWnd )
ENDCLASS

METHOD Show( oWnd,xPos,yPos,lWnd ) CLASS HMenu
Local aCoor

   oWnd:oPopup := Self
   IF Pcount() == 1 .OR. lWnd == Nil .OR. !lWnd
      IF Pcount() == 1
         aCoor := hwg_GetCursorPos()
         xPos  := aCoor[1]
         yPos  := aCoor[2]
      ENDIF
      Hwg_trackmenu( ::handle,xPos,yPos,oWnd:handle )
   ELSE
      aCoor := ClientToScreen( oWnd:handle,xPos,yPos )
      Hwg_trackmenu( ::handle,aCoor[1],aCoor[2],oWnd:handle )
   ENDIF

Return Nil

Function Hwg_CreateMenu
Local hMenu

   IF ( hMenu := hwg__CreateMenu() ) == 0
      Return Nil
   ENDIF

Return { {},,, hMenu }

Function Hwg_SetMenu( oWnd, aMenu )

   IF oWnd:handle != 0
      IF hwg__SetMenu( oWnd:handle, aMenu[5] )
         oWnd:menu := aMenu
      ELSE
         Return .F.
      ENDIF
   ELSE
      oWnd:menu := aMenu
   ENDIF

Return .T.

/*
 *  AddMenuItem( aMenu,cItem,nMenuId,lSubMenu,[bItem] [,nPos] ) --> aMenuItem
 *
 *  If nPos is omitted, the function adds menu item to the end of menu,
 *  else it inserts menu item in nPos position.
 */
Function Hwg_AddMenuItem( aMenu,cItem,nMenuId,lSubMenu,bItem,nPos )
Local hSubMenu

   IF nPos == Nil
      nPos := Len( aMenu[1] ) + 1
   ENDIF

   hSubMenu := aMenu[5]
   hSubMenu := hwg__AddMenuItem( hSubMenu, cItem, nPos-1, .T., nMenuId,,lSubMenu )

   IF nPos > Len( aMenu[1] )
      IF lSubmenu
         Aadd( aMenu[1],{ {},cItem,nMenuId,0,hSubMenu } )
      ELSE
         Aadd( aMenu[1],{ bItem,cItem,nMenuId,0 } )
      ENDIF
      Return ATail( aMenu[1] )
   ELSE
      Aadd( aMenu[1],Nil )
      Ains( aMenu[1],nPos )
      IF lSubmenu
         aMenu[ 1,nPos ] := { {},cItem,nMenuId,0,hSubMenu }
      ELSE
         aMenu[ 1,nPos ] := { bItem,cItem,nMenuId,0 }
      ENDIF
      Return aMenu[ 1,nPos ]
   ENDIF

Return Nil

Function Hwg_FindMenuItem( aMenu, nId, nPos )
Local nPos1, aSubMenu
   nPos := 1
   DO WHILE nPos <= Len( aMenu[1] )
      IF aMenu[ 1,npos,3 ] == nId
         Return aMenu
      ELSEIF Len( aMenu[ 1,npos ] ) > 4
         IF ( aSubMenu := Hwg_FindMenuItem( aMenu[ 1,nPos ] , nId, @nPos1 ) ) != Nil
            nPos := nPos1
            Return aSubMenu
         ENDIF
      ENDIF
      nPos ++
   ENDDO
Return Nil

Function Hwg_GetSubMenuHandle( aMenu,nId )
Local aSubMenu := Hwg_FindMenuItem( aMenu, nId )

Return Iif( aSubMenu == Nil, 0, aSubMenu[5] )

Function BuildMenu( aMenuInit, hWnd, oWnd, nPosParent,lPopup )
Local hMenu, nPos, aMenu, i, oBmp

   IF nPosParent == Nil   
      IF lPopup == Nil .OR. !lPopup
         hMenu := hwg__CreateMenu()
      ELSE
         hMenu := hwg__CreatePopupMenu()
      ENDIF
      aMenu := { aMenuInit,,,,hMenu }
   ELSE
      hMenu := aMenuInit[5]
      nPos := Len( aMenuInit[1] )
      aMenu := aMenuInit[ 1,nPosParent ]
      hMenu := hwg__AddMenuItem( hMenu, aMenu[2], nPos+1, .T., aMenu[3],aMenu[4],.T. )
      IF Len( aMenu ) < 5
         Aadd( aMenu,hMenu )
      ELSE
         aMenu[5] := hMenu
      ENDIF
   ENDIF

   nPos := 1
   DO WHILE nPos <= Len( aMenu[1] )
      IF Valtype( aMenu[ 1,nPos,1 ] ) == "A"
         BuildMenu( aMenu,,,nPos )
      ELSE 
         IF aMenu[ 1,nPos,1 ] == Nil .OR. aMenu[ 1,nPos,2 ] != Nil
            hwg__AddMenuItem( hMenu, aMenu[1,npos,2], nPos, .T., ;
                   aMenu[1,nPos,3], aMenu[1,npos,4],.F. )
            oBmp:=Hwg_SearchPosBitmap( aMenu[1,nPos,3]) 
            if oBmp[1]       
               SetMenuItemBitmaps(hMenu, aMenu[1,nPos,3], oBmp[2],"")
            endIf    
            
         Endif
      ENDIF
      nPos ++
   ENDDO
   IF hWnd != Nil .AND. oWnd != Nil
      Hwg_SetMenu( oWnd, aMenu )
   ELSEIF _oMenu != Nil
      _oMenu:handle := aMenu[5]
      _oMenu:aMenu := aMenu
   ENDIF
Return Nil

Function Hwg_BeginMenu( oWnd,nId,cTitle )
Local aMenu, i
   IF oWnd != Nil
      _aMenuDef := {}
      _aAccel   := {}
      _oBitmap  := {}
      _oWnd     := oWnd
      _oMenu    := Nil
      _nLevel   := 0
      _Id       := Iif( nId == Nil, MENU_FIRST_ID, nId )
   ELSE
      nId   := Iif( nId == Nil, ++ _Id, nId )
      aMenu := _aMenuDef
      FOR i := 1 TO _nLevel
         aMenu := Atail(aMenu)[1]
      NEXT
      _nLevel++
      Aadd( aMenu, { {},cTitle,nId,0 } )
   ENDIF
Return .T.

Function Hwg_ContextMenu()
   _aMenuDef := {}
   _oBitmap  := {}
   _oWnd := Nil
   _nLevel := 0
   _Id := CONTEXTMENU_FIRST_ID
   _oMenu := HMenu():New()
Return _oMenu

Function Hwg_EndMenu()
   IF _nLevel > 0
      _nLevel --
   ELSE
      BuildMenu( Aclone(_aMenuDef), Iif( _oWnd!=Nil,_oWnd:handle,Nil ), ;
                   _oWnd,,Iif( _oWnd!=Nil,.F.,.T. ) )
      IF _oWnd != Nil .AND. _aAccel != Nil .AND. !Empty( _aAccel )
         _oWnd:hAccel := CreateAcceleratorTable( _aAccel )
      ENDIF
      _aMenuDef := Nil
      _oBitmap  := Nil
      _aAccel   := Nil
      _oWnd     := Nil
      _oMenu    := Nil
   ENDIF
Return .T.

Function Hwg_DefineMenuItem( cItem, nId, bItem, lDisabled, accFlag, accKey, lBitmap, lResource, lCheck )
Local aMenu, i, oBmp, nFlag

   lCheck := Iif( lCheck==Nil, .F., lCheck )
   lDisabled := Iif( lDisabled==Nil,.T.,!lDisabled )
   nFlag := Hwg_BitOr( Iif( lCheck,FLAG_CHECK,0 ), Iif( lDisabled,0,FLAG_DISABLED ) )

   aMenu := _aMenuDef
   FOR i := 1 TO _nLevel
      aMenu := Atail(aMenu)[1]
   NEXT
   if !empty( cItem )
      cItem := strtran( cItem, "\t", chr(9) )
   endif
   nId := Iif( nId == Nil .AND. cItem != Nil, ++ _Id, nId )
   Aadd( aMenu, { bItem,cItem,nId,nFlag } )
   IF lBitmap!=Nil .or. !Empty(lBitmap)
      if lResource==Nil ;lResource:=.F.; Endif         
      if !lResource 
         oBmp:=HBitmap():AddFile(lBitmap)
      else
         oBmp:=HBitmap():AddResource(lBitmap)
      endif
      Aadd( _oBitmap, {.t., oBmp:Handle,cItem,nId} )
   Else   
      Aadd( _oBitmap, {.F., "",cItem, nID})
   Endif         
   IF accFlag != Nil .AND. accKey != Nil
      Aadd( _aAccel, { accFlag,accKey,nId } )
   ENDIF
Return .T.

Function Hwg_DefineAccelItem( nId, bItem, accFlag, accKey )
Local aMenu, i
   aMenu := _aMenuDef
   FOR i := 1 TO _nLevel
      aMenu := Atail(aMenu)[1]
   NEXT
   nId := Iif( nId == Nil, ++ _Id, nId )
   Aadd( aMenu, { bItem,Nil,nId,0 } )
   Aadd( _aAccel, { accFlag,accKey,nId } )
Return .T.


Function Hwg_SetMenuItemBitmaps( aMenu, nId, abmp1, abmp2 )
Local aSubMenu := Hwg_FindMenuItem( aMenu, nId )
Local oMenu:=aSubMenu

   oMenu := Iif( aSubMenu == Nil, 0, aSubMenu[5] )
   SetMenuItemBitmaps( oMenu, nId, abmp1, abmp2 )
Return Nil

Function Hwg_InsertBitmapMenu( aMenu, nId, lBitmap, oResource )
Local aSubMenu := Hwg_FindMenuItem( aMenu, nId )
Local oMenu:=aSubMenu, oBmp

   If !oResource .or. oResource==Nil
      oBmp:=HBitmap():AddFile(lBitmap)
   else
      oBmp:=HBitmap():AddResource(lBitmap)
   endif
   oMenu := Iif( aSubMenu == Nil, 0, aSubMenu[5] )
   HWG__InsertBitmapMenu( oMenu, nId, obmp:handle )
Return Nil

Function Hwg_SearchPosBitmap( nPos_Id )

   Local nPos := 1, lBmp:={.F.,""}

   IF _oBitmap != Nil
      DO WHILE nPos<=Len(_oBitmap )

         if _oBitmap[nPos][4] == nPos_Id
            lBmp:={_oBitmap[nPos][1], _oBitmap[nPos][2],_oBitmap[nPos][3]}     
         Endif

         nPos ++

      ENDDO
   ENDIF

Return lBmp
 
