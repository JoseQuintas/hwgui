/*
 * $Id: hcombo.prg,v 1.25 2007-08-20 14:56:58 lculik Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HCombo class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HCheckComboEx class
 *
 * Copyright 2007 Luiz Rafale Culik Guimaraes (Luiz at xharbour.com.br)
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define CB_ERR              (-1)
#define CBN_SELCHANGE       1
#define CBN_DBLCLK          2
#define CBN_SETFOCUS        3
#define CBN_KILLFOCUS       4
#define CBN_EDITCHANGE      5
#define CBN_EDITUPDATE      6
#define CBN_DROPDOWN        7
#define CBN_CLOSEUP         8
#define CBN_SELENDOK        9
#define CBN_SELENDCANCEL    10


CLASS HComboBox INHERIT HControl

   CLASS VAR winclass   INIT "COMBOBOX"
   DATA  aItems
   DATA  bSetGet
   DATA  value    INIT 1
   DATA  bValid   INIT {||.T.}
   DATA  bChangeSel

   DATA  lText    INIT .F.
   DATA  lEdit    INIT .F.

   METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  aItems,oFont,bInit,bSize,bPaint,bChange,ctooltip,lEdit,lText,bGFocus,tcolor,bcolor,bValid )
   METHOD Activate()
   METHOD Redefine( oWnd,nId,vari,bSetGet,aItems,oFont,bInit,bSize,bDraw,bChange,ctooltip,bGFocus )
   METHOD Init( aCombo, nCurrent )
   METHOD Refresh()
   METHOD Setitem( nPos )
   METHOD GetValue()
ENDCLASS

METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,aItems,oFont, ;
                  bInit,bSize,bPaint,bChange,ctooltip,lEdit,lText,bGFocus,tcolor,bcolor,bValid ) CLASS HComboBox

   if lEdit == Nil; lEdit := .f.; endif
   if lText == Nil; lText := .f.; endif
   //if bValid != NIL; ::bValid := bValid; endif

   nStyle := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ),Iif( lEdit,CBS_DROPDOWN,CBS_DROPDOWNLIST )+WS_TABSTOP )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, bSize,bPaint,ctooltip,tcolor,bcolor )

   ::lEdit := lEdit
   ::lText := lText

   if lEdit
      ::lText := .t.
   endif

   if ::lText
      ::value := Iif( vari==Nil .OR. Valtype(vari)!="C","",vari )
   else
      ::value := Iif( vari==Nil .OR. Valtype(vari)!="N",1,vari )
   endif

   ::bSetGet := bSetGet
   ::aItems  := aItems

   ::Activate()

   IF bSetGet != Nil
      ::bChangeSel := bChange
      ::bGetFocus := bGFocus
      ::oParent:AddEvent( CBN_SETFOCUS,::id,{|o,id|__When(o:FindControl(id))} )

      // By Luiz Henrique dos Santos (luizhsantos@gmail.com) 03/06/2006
      if ::bSetGet <> nil
         ::oParent:AddEvent( CBN_SELCHANGE,::id,{|o,id|__Valid(o:FindControl(id))} )
      elseif ::bChangeSel != NIL
         ::oParent:AddEvent( CBN_SELCHANGE,::id,{|o,id|__Valid(o:FindControl(id))} )
      ENDIF
      
      IF bValid != NIL
         ::bValid := bValid
         ::oParent:AddEvent( CBN_KILLFOCUS,::id,{|o,id|__Valid(o:FindControl(id))} ) 
      ENDIF
      //---------------------------------------------------------------------------
   ELSEIF bChange != Nil
      ::oParent:AddEvent( CBN_SELCHANGE,::id,bChange )
   ENDIF

   IF ::lEdit
      ::oParent:AddEvent( CBN_KILLFOCUS,::id,{|o,id|__KillFocus(o:FindControl(id))} )
   ENDIF

   IF bGFocus != Nil .AND. bSetGet == Nil
      ::oParent:AddEvent( CBN_SETFOCUS,::id,{|o,id|__When(o:FindControl(id))} )
   ENDIF

Return Self

METHOD Activate CLASS HComboBox
   IF ::oParent:handle != 0
      ::handle := CreateCombo( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
Return Nil

METHOD Redefine( oWndParent,nId,vari,bSetGet,aItems,oFont,bInit,bSize,bPaint, ;
                  bChange,ctooltip,bGFocus ) CLASS HComboBox

   Super:New( oWndParent,nId,0,0,0,0,0,oFont,bInit,bSize,bPaint,ctooltip )

   if ::lText
      ::value := Iif( vari==Nil .OR. Valtype(vari)!="C","",vari )
   else
      ::value := Iif( vari==Nil .OR. Valtype(vari)!="N",1,vari )
   endif
   ::bSetGet := bSetGet
   ::aItems  := aItems

   IF bSetGet != Nil
      ::bChangeSel := bChange
      // By Luiz Henrique dos Santos (luizhsantos@gmail.com) 04/06/2006
      IF ::bChangeSel != NIL
        ::oParent:AddEvent( CBN_SELCHANGE,::id,{|o,id|__Valid(o:FindControl(id))} )
      ENDIF
   ELSEIF bChange != Nil
      ::oParent:AddEvent( CBN_SELCHANGE,::id,bChange )
   ENDIF
   ::Refresh() // By Luiz Henrique dos Santos
Return Self

METHOD Init() CLASS HComboBox
   Local i

   IF !::lInit
      Super:Init()
      IF ::aItems != Nil
         IF ::value == Nil
            IF ::lText
                ::value := ::aItems[1]
            ELSE
                ::value := 1
            ENDIF
         ENDIF
         SendMessage( ::handle, CB_RESETCONTENT, 0, 0)
         FOR i := 1 TO Len( ::aItems )
            ComboAddString( ::handle, ::aItems[i] )
         NEXT
         IF ::lText
            IF ::lEdit
                SetDlgItemText(getmodalhandle(), ::id, ::value)
            ELSE
                ComboSetString( ::handle, AScan( ::aItems, ::value ) )
            ENDIF
         ELSE
            ComboSetString( ::handle, ::value )
         ENDIF
      ENDIF
   ENDIF
Return Nil

METHOD Refresh() CLASS HComboBox
   Local vari, i
   IF ::bSetGet != Nil
      vari := Eval( ::bSetGet,,Self )
      if ::lText
         ::value := Iif( vari==Nil .OR. Valtype(vari)!="C","",vari )
      else
         ::value := Iif( vari==Nil .OR. Valtype(vari)!="N",1,vari )
      endif
   ENDIF

   SendMessage( ::handle, CB_RESETCONTENT, 0, 0)

   FOR i := 1 TO Len( ::aItems )
      ComboAddString( ::handle, ::aItems[i] )
   NEXT

   IF ::lText
      IF ::lEdit
        SetDlgItemText(getmodalhandle(), ::id, ::value)
      ELSE
        ComboSetString( ::handle, AScan( ::aItems, ::value ) )
      ENDIF
   ELSE
      ComboSetString( ::handle, ::value )
      ::SetItem(::value )
   ENDIF

Return Nil

METHOD SetItem(nPos) CLASS HComboBox
   IF ::lText
      ::value := ::aItems[nPos]
   ELSE
      ::value := nPos
   ENDIF

   SendMessage( ::handle, CB_SETCURSEL, nPos - 1, 0)

   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::value, self )
   ENDIF

   IF ::bChangeSel != Nil
      Eval( ::bChangeSel, nPos, Self )
   ENDIF
Return Nil

METHOD GetValue() CLASS HComboBox
Local nPos := SendMessage( ::handle,CB_GETCURSEL,0,0 ) + 1

   ::value := Iif( ::lText, ::aItems[nPos], nPos )
   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::value, Self )
   ENDIF

Return ::value

Static Function __Valid( oCtrl )
   Local nPos
   local lESC
   // by sauli
   if __ObjHasMsg(oCtrl:oParent,"nLastKey")
      // caso o PARENT seja HDIALOG
      lESC := oCtrl:oParent:nLastKey <> 27
   else
      // caso o PARENT seja HTAB, HPANEL
      lESC := .t.
   end
   // end by sauli
   IF lESC // "if" by Luiz Henrique dos Santos (luizhsantos@gmail.com) 04/06/2006
     nPos := SendMessage( oCtrl:handle,CB_GETCURSEL,0,0 ) + 1
  
     oCtrl:value := Iif( oCtrl:lText, oCtrl:aItems[nPos], nPos )
  
     IF oCtrl:bSetGet != Nil
        Eval( oCtrl:bSetGet, oCtrl:value, oCtrl )
     ENDIF
     IF oCtrl:bChangeSel != Nil
        Eval( oCtrl:bChangeSel, nPos, oCtrl )
     ENDIF
     
     // By Luiz Henrique dos Santos (luizhsantos@gmail.com.br) 03/06/2006
     IF oCtrl:bValid != NIL 
       IF ! EVAL( oCtrl:bValid, oCtrl )
         SetFocus( oCtrl:handle )
         RETURN .F.
       ENDIF
     ENDIF
   ENDIF
Return .T.

Static Function __KillFocus( oCtrl )
   oCtrl:value := GetEditText( getmodalhandle(), oCtrl:id )
   IF oCtrl:bSetGet != Nil
      Eval( oCtrl:bSetGet, oCtrl:value, oCtrl )
   ENDIF
Return .T.

Static Function __When( oCtrl )
Local res

   oCtrl:Refresh()

   IF oCtrl:bGetFocus != Nil
      res := Eval( oCtrl:bGetFocus, Eval( oCtrl:bSetGet,, oCtrl ), oCtrl )
      IF !res
         GetSkip( oCtrl:oParent,oCtrl:handle,1 )
      ENDIF
      Return res
   ENDIF

Return .T.


CLASS HCheckComboBox INHERIT HComboBox

   CLASS VAR winclass INIT "COMBOBOX"
   DATA m_bTextUpdated INIT .f.

   DATA m_bItemHeightSet INIT .f.
   DATA m_hListBox INIT 0
   DATA aCheck
   DATA m_strText INIT ""
   METHOD onGetText( w, l )
   METHOD OnGetTextLength( w, l )

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
   aItems, oFont, bInit, bSize, bPaint, bChange, ctooltip, lEdit, lText, bGFocus, tcolor, bcolor, bValid, acheck )
   METHOD Redefine( oWnd, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bDraw, bChange, ctooltip, bGFocus )
   METHOD INIT( aCombo, nCurrent )
   METHOD Refresh()
   METHOD Paint( lpDis )
   METHOD SetCheck( nIndex, bFlag )
   METHOD RecalcText()

   METHOD GetCheck( nIndex )

   METHOD SelectAll( bCheck )
   METHOD MeasureItem( l )

   METHOD onEvent
   METHOD GetAllCheck() 
ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, aItems, oFont, ;
               bInit, bSize, bPaint, bChange, ctooltip, lEdit, lText, bGFocus, tcolor, bcolor, bValid, acheck ) CLASS hCheckComboBox

   ::aCheck := acheck
   IF VALTYPE( nStyle ) == "N"
      nstyle += CBS_DROPDOWNLIST + CBS_OWNERDRAWVARIABLE + CBS_HASSTRINGS
   ELSE
      nstyle := CBS_DROPDOWNLIST + CBS_OWNERDRAWVARIABLE + CBS_HASSTRINGS
   ENDIF

   bPaint := { | o, p | o:paint( p ) }

   ::super:New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, aItems, oFont, ;
                bInit, bSize, bPaint, bChange, ctooltip, lEdit, lText, bGFocus, tcolor, bcolor, bValid )

RETURN Self

METHOD Redefine( oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, ;
                    bChange, ctooltip, bGFocus, acheck ) CLASS hCheckComboBox

   ::super:Redefine( oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, ;
                     bChange, ctooltip, bGFocus )

   ::acheck := acheck

RETURN Self

METHOD onevent( msg, wParam, lParam )

LOCAL nIndex
LOCAL rcItem
LOCAL rcClient
LOCAL pt
LOCAL nItemHeight
LOCAL nTopIndex
   IF msg == WM_RBUTTONDOWN
   ELSEIF msg == LB_GETCURSEL
      RETURN - 1
   ELSEIF msg == LB_GETCURSEL
      RETURN - 1

   ELSEIF msg == WM_MEASUREITEM
      ::MeasureItem( lParam )
      RETURN 0
   ELSEIF msg == WM_GETTEXT
      RETURN ::OnGetText( wParam, lParam )

   ELSEIF msg == WM_GETTEXTLENGTH
      RETURN ::OnGetTextLength()

   ELSEIF msg == WM_CHAR
      IF ( wParam == VK_SPACE )

         nIndex := SendMessage( ::handle, CB_GETCURSEL, wParam, lParam ) + 1

         rcItem := COMBOGETITEMRECT( ::handle, nIndex - 1 )

         InvalidateRect( ::handle, .f., rcItem[ 1 ], rcItem[ 2 ], rcItem[ 3 ], rcItem[ 4 ] )

         ::SetCheck( nIndex, !::GetCheck( nIndex ) )

         SendMessage( ::oParent:handle, WM_COMMAND, MAKELONG( ::id, CBN_SELCHANGE ), ::handle )
      ENDIF
      RETURN 0

   ELSEIF msg == WM_LBUTTONDOWN

      rcClient := GetClientRect( ::handle )

      pt := {, }
      pt[ 1 ] = LOWORD( lParam )
      pt[ 2 ] = HIWORD( lParam )

      IF ( PtInRect( rcClient, pt ) )

         nItemHeight := SendMessage( ::handle, LB_GETITEMHEIGHT, 0, 0 )
         nTopIndex   := SendMessage( ::handle, LB_GETTOPINDEX, 0, 0 )

         // Compute which index to check/uncheck
         nIndex := ( nTopIndex + pt[ 2 ] / nItemHeight ) + 1

         rcItem := COMBOGETITEMRECT( ::handle, nIndex - 1 )

         IF ( PtInRect( rcItem, pt ) )
            // Invalidate this window
            InvalidateRect( ::handle, .f., rcItem[ 1 ], rcItem[ 2 ], rcItem[ 3 ], rcItem[ 4 ] )
            ::SetCheck( nIndex, !::GetCheck( nIndex ) )

            // Notify that selection has changed

            SendMessage( ::oParent:handle, WM_COMMAND, MAKELONG( ::id, CBN_SELCHANGE ), ::handle )

         ENDIF
      ENDIF

   ELSEIF msg == WM_LBUTTONUP

      RETURN 0
   ENDIF
RETURN - 1

METHOD INIT() CLASS hCheckComboBox

LOCAL i
   ::nHolder := 1
   SetWindowObject( ::handle, Self )
   HWG_INITCOMBOPROC( ::handle )

   IF !::lInit
      Super:Init()
      IF LEN( ::acheck ) > 0
         FOR i := 1 TO LEN( ::acheck )
            ::Setcheck( ::acheck[ i ], .t. )
         NEXT
      ENDIF
   ENDIF
RETURN Nil

METHOD Refresh() CLASS hCheckComboBox

   ::super:refresh()
   IF LEN( ::acheck ) > 0
      FOR i := 1 TO LEN( ::acheck )
         ::Setcheck( ::acheck[ i ], .t. )
      NEXT
   ENDIF

RETURN Nil

METHOD SetCheck( nIndex, bFlag ) CLASS hCheckComboBox

LOCAL nResult := COMBOBOXSETITEMDATA( ::handle, nIndex - 1, bFlag )

   IF ( nResult < 0 )
      RETURN nResult
   ENDIF

   ::m_bTextUpdated := FALSE

   // Redraw the window
   InvalidateRect( ::handle, 0 )

RETURN nResult

METHOD GetCheck( nIndex ) CLASS hCheckComboBox

LOCAL l := COMBOBOXGETITEMDATA( ::handle, nIndex - 1 )

RETURN IF( l == 1, .t., .f. )

METHOD SelectAll( bCheck ) CLASS hCheckComboBox

LOCAL nCount
LOCAL i
   DEFAULT bCheck TO .t.

   nCount := SendMessage( ::handle, CB_GETCOUNT, 0, 0 )

   FOR i := 1 TO nCount
      ::SetCheck( i, bCheck )
   NEXT
RETURN nil

METHOD RecalcText() CLASS hCheckComboBox

LOCAL strtext
LOCAL ncount
LOCAL szBuffer
LOCAL strSeparator
LOCAL i
LOCAL stritem
   IF ( !::m_bTextUpdated )

      // Get the list count
      nCount := SendMessage( ::handle, CB_GETCOUNT, 0, 0 )

      // Get the list separator

      strSeparator := GetLocaleInfo()

      // If none found, the the ''
      IF LEN( strSeparator ) == 0
         strSeparator := ''
      ENDIF

      strSeparator := RTRIM( strSeparator )

      strSeparator += ' '

      FOR i := 1 TO nCount

         IF ( COMBOBOXGETITEMDATA( ::handle, i ) )

            COMBOBOXGETLBTEXT( ::handle, i, @strItem )

            IF !EMPTY( strText )
               strText += strSeparator
            ENDIF

            strText += strItem
         ENDIF
      NEXT

      // Set the text
      ::m_strText := strText

      ::m_bTextUpdated := TRUE
   ENDIF
RETURN self

METHOD Paint( lpDis ) CLASS hCheckComboBox

LOCAL drawInfo := GetDrawItemInfo( lpdis )

LOCAL dc := drawInfo[ 3 ]

LOCAL rcBitmap := { DrawInfo[ 4 ], DrawInfo[ 5 ], DrawInfo[ 6 ], DrawInfo[ 7 ] }
LOCAL rcText   := { DrawInfo[ 4 ], DrawInfo[ 5 ], DrawInfo[ 6 ], DrawInfo[ 7 ] }
LOCAL strtext  := ""
LOCAL ncheck
LOCAL metricks
LOCAL nstate

   IF ( DrawInfo[ 1 ] < 0 )

      ::RecalcText()

      strText := ::m_strText

      nCheck := 0

   ELSE
      COMBOBOXGETLBTEXT( ::handle, DrawInfo[ 1 ], @strText )

      nCheck := 1 + ( COMBOBOXGETITEMDATA( ::handle, DrawInfo[ 1 ] ) )

      metrics := GETTEXTMETRIC( dc )

      rcBitmap[ 1 ] := 0
      rcBitmap[ 3 ] := rcBitmap[ 1 ] + metrics[ 1 ] + metrics[ 4 ] + 6
      rcBitmap[ 2 ] += 1
      rcBitmap[ 4 ] -= 1

      rcText[ 1 ] := rcBitmap[ 3 ]
   ENDIF

   IF ( nCheck > 0 )
      SetBkColor( dc, GetSysColor( COLOR_WINDOW ) )
      SetTextColor( dc, GetSysColor( COLOR_WINDOWTEXT ) )

      nState := DFCS_BUTTONCHECK

      IF ( nCheck > 1 )
         nState := hwg_bitor( nstate, DFCS_CHECKED )
      ENDIF

      // Draw the checkmark using DrawFrameControl
      DrawFrameControl( dc, rcBitmap, DFC_BUTTON, nState )
   ENDIF

   IF ( hwg_Bitand( DrawInfo[ 9 ], ODS_SELECTED ) != 0 )
      SetBkColor( dc, GetSysColor( COLOR_HIGHLIGHT ) )
      SetTextColor( dc, GetSysColor( COLOR_HIGHLIGHTTEXT ) )

   ELSE
      SetBkColor( dc, GetSysColor( COLOR_WINDOW ) )
      SetTextColor( dc, GetSysColor( COLOR_WINDOWTEXT ) )
   ENDIF

   // Erase and draw
   IF EMPTY( strtext )
      strtext := ""
   ENDIF

   ExtTextOut( dc, 0, 0, rcText[ 1 ], rcText[ 2 ], rcText[ 3 ], rcText[ 4 ] )

   DrawText( DC, ' ' + strText, rcText[ 1 ], rcText[ 2 ], rcText[ 3 ], rcText[ 4 ], DT_SINGLELINE | DT_VCENTER | DT_END_ELLIPSIS )

   IF ( ( hwg_Bitand( DrawInfo[ 9 ], ODS_FOCUS | ODS_SELECTED ) ) == ( ODS_FOCUS | ODS_SELECTED ) )
      DrawFocusRect( dc, rcText )
   ENDIF

RETURN self

METHOD MeasureItem( l ) CLASS hCheckComboBox

LOCAL dc                  := HCLIENTDC():new( ::handle )
LOCAL lpMeasureItemStruct := GETMEASUREITEMINFO( l )
LOCAL metrics
LOCAL pFont

   pFont := dc:SelectObject( IF( VALTYPE( ::oFont ) == "O", ::oFont:handle, ::oParent:oFont:handle ) )
   IF ( pFont != 0 )

      metrics := dc:GetTextMetric()

      lpMeasureItemStruct[ 5 ] := metrics[ 1 ] + metrics[ 4 ]

      lpMeasureItemStruct[ 5 ] += 2

      IF ( !::m_bItemHeightSet )
         ::m_bItemHeightSet := .t.
         SendMessage( ::handle, CB_SETITEMHEIGHT, - 1, MAKELONG( lpMeasureItemStruct[ 5 ], 0 ) )
      ENDIF

      dc:SelectObject( pFont )
      dc:end()
   ENDIF
RETURN self

METHOD OnGetText( wParam, lParam ) CLASS hCheckComboBox


   ::RecalcText()

   IF ( lParam == 0 )
      RETURN 0
   ENDIF

   // Copy the 'fake' window text
   hb_inline( lParam, ::m_strText, wParam )
   {
   LPARAM lParam = ( LPARAM ) hb_parnl( 1 ) ;
                     char * m_strText = hb_parc( 2 ) ;
                     WPARAM wParam = ( WPARAM ) hb_parnl( 3 ) ;

   lstrcpyn( ( LPSTR ) lParam, m_strText, ( INT ) wParam ) ;
             }

RETURN LEN( ::m_strText )

METHOD OnGetTextLength( WPARAM, LPARAM ) CLASS hCheckComboBox

   ::RecalcText()
RETURN LEN( ::m_strText )

METHOD GetAllCheck() CLASS hCheckComboBox
Local aCheck :={}
   For n := 1  to len(::aItems)
      aadd( aCheck ,::GetCheck(n))
   next
return aCheck

