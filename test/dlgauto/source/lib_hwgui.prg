/*
lib_hwgui - hwgui source selected by lib.prg
*/

#include "frm_class.ch"

STATIC lDrawboard := .F.

FUNCTION IsDrawBoard( lParam )

   IF lParam != Nil
      lDrawboard := lParam
   ENDIF

   RETURN lDrawboard

FUNCTION gui_Init()

   hwg_SetColorInFocus( .T., COLOR_BLACK,COLOR_YELLOW )

   RETURN Nil

FUNCTION gui_MainMenu( xDlg, aMenuList, aAllSetup, cTitle )

   LOCAL aGroupList, cDBF

   gui_DialogCreate( @xDlg, 0, 0,1024, 768, cTitle )
   MENU OF xDlg
      FOR EACH aGroupList IN aMenuList
         MENU TITLE "Data" + Ltrim( Str( aGroupList:__EnumIndex ) )
            FOR EACH cDBF IN aGroupList
               MENUITEM cDBF ACTION frm_Main( cDBF, aAllSetup )
            NEXT
         ENDMENU
      NEXT
      MENU TITLE "Exit"
         MENUITEM "&Exit" ACTION gui_DialogClose( xDlg )
      ENDMENU
   ENDMENU
   gui_DialogActivate( xDlg )

   RETURN Nil

FUNCTION gui_ButtonCreate( xDlg, xControl, nRow, nCol, nWidth, nHeight, cCaption, cResName, bAction )

   @ nCol, nRow BUTTON xControl ;
      CAPTION  Nil ;
      OF       xDlg ;
      SIZE     nWidth, nHeight ;
      STYLE    BS_TOP ;
      ON CLICK bAction ;
      ON INIT  { || ;
         BtnSetImageText( xControl:Handle, cCaption, cResName, nWidth, nHeight ) } ;
         TOOLTIP cCaption
   ( xDlg )

   RETURN Nil

FUNCTION gui_ButtonEnable( xDlg, xControl, lEnable )

   IF lEnable
      xControl:Enable()
   ELSE
      xControl:Disable()
   ENDIF
   (xDlg)

   RETURN Nil

FUNCTION gui_Browse( xDlg, xControl, nRow, nCol, nWidth, nHeight, oTbrowse, cField, xValue, workarea )

   LOCAL aItem

   @ nCol, nRow BROWSE xControl DATABASE SIZE nWidth, nHeight STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL

   FOR EACH aItem IN oTBrowse
      ADD COLUMN { || Transform( FieldGet( FieldNum( aItem[2] ) ), aItem[3] ) } TO xControl ;
         HEADER aItem[1] ;
         LENGTH Max( Len( aItem[1] ), Len( Transform( FieldGet( FieldNum( aItem[2] ) ), aItem[3] ) ) ) ;
         JUSTIFY LINE DT_LEFT
   NEXT

   xControl:bOther := { |xControl, msg, wParam, lParam| gui_BrowseKeyDown( xControl, msg, wParam, lParam, cField, @xValue ) }

   (xDlg); (workarea)

   RETURN Nil

STATIC FUNCTION gui_BrowseKeyDown( xControl, msg, wParam, lParam, cField, xValue )

   LOCAL nKEY

   IF msg == WM_KEYDOWN
      nKey := hwg_PtrToUlong( wParam )
      IF nKey = VK_RETURN
         IF ! Empty( cField )
            xValue := FieldGet( FieldNum( cField, xValue ) )
         ENDIF
         hwg_EndDialog()
      ENDIF
   ENDIF
   (xControl)
   (lParam)

   RETURN .T.

FUNCTION gui_DialogActivate( xDlg, bCode )

   // xDlg:Center()
   IF Empty( bCode )
      ACTIVATE DIALOG xDLG CENTER // xDlg:Activate()
   ELSE
      ACTIVATE DIALOG xDlg CENTER ON ACTIVATE bCode
   ENDIF

   RETURN Nil

FUNCTION gui_DialogClose( xDlg )

   RETURN xDlg:Close()

FUNCTION gui_DialogCreate( xDlg, nRow, nCol, nWidth, nHeight, cTitle, bInit )

   LOCAL oFont

   IF Empty( bInit )
      bInit := { || Nil }
   ENDIF
   oFont := HFont():Add( DEFAULT_FONTNAME, 0, -11 )
   INIT DIALOG xDlg ;
      CLIPPER ;
      FONT oFont ;
      NOEXIT ;
      TITLE     cTitle ;
      AT        nRow, nCol ;
      SIZE      nWidth, nHeight ;
      BACKCOLOR COLOR_WHITE ;
      ON INIT   bInit

   RETURN Nil

FUNCTION gui_IsCurrentFocus( xDlg, xControl )

      (xDlg)

      RETURN hwg_SelfFocus( xControl:Handle )

FUNCTION gui_LabelCreate( xDlg, xControl, nRow, nCol, nWidth, nHeight, xValue, lBorder )

   IF lBorder
      @ nCol, nRow SAY xControl ;
         CAPTION xValue ;
         OF      xDlg ;
         SIZE    nWidth, nHeight ;
         STYLE   WS_BORDER ;
         COLOR COLOR_BLACK ;
         BACKCOLOR COLOR_GREEN // TRANSPARENT // DO NOT USE TRANSPARENT WITH BORDER
   ELSE
      @ nCol, nRow SAY xControl ;
         CAPTION xValue ;
         OF      xDlg ;
         SIZE    nWidth, nHeight ;
         COLOR   COLOR_BLACK ;
         TRANSPARENT
   ENDIF
   (xDlg); (lBorder)

   RETURN Nil

//   @ nCol, nRow BOARD xControl SIZE nWidth, nHeight ON PAINT { | o, h | LabelPaint( o, h, lBorder ) }
//   xControl:Title := xValue

//   RETURN Nil

//FUNCTION LabelPaint( o, h, lBorder )

//   IF o:oFont != Nil
//      hwg_SelectObject( h, o:oFont:Handle )
//   ENDIF
//   IF o:TColor != Nil
//      hwg_SetTextColor( h, o:TColor )
//   ENDIF
//   IF ! Empty( lBorder ) .AND. lBorder
//      hwg_Rectangle( h, 0, 0, o:nWidth - 1, o:nHeight - 1 )
//   ENDIF
//   hwg_SetTransparentMode( h, .T. )
//   hwg_DrawText( h, o:Title, 2, 2, o:nWidth - 2, o:nHeight - 2 )
//   hwg_SetTransparentMode( h, .F. )

//   RETURN Nil

FUNCTION gui_LabelSetValue( xDlg, xControl, xValue )

   xControl:SetText( xValue )
   xControl:Refresh()
   (xDlg)

   RETURN Nil

FUNCTION gui_LibName()

   RETURN "HWGUI"

FUNCTION gui_MLTextCreate( xDlg, xControl, nRow, nCol, nWidth, nHeight, xValue )

   LOCAL oFont := HFont():Add( PREVIEW_FONTNAME, 0, -11 )

   @ nCol, nRow EDITBOX xControl ;
      CAPTION xValue ;
      SIZE    nWidth, nHeight ;
      FONT    oFont ;
      STYLE   ES_MULTILINE + ES_AUTOVSCROLL + WS_VSCROLL + WS_HSCROLL
   (xDlg)

   RETURN Nil

FUNCTION gui_Msgbox( cText )

   RETURN hwg_MsgInfo( cText )

FUNCTION gui_MsgYesNo( cText )

   RETURN hwg_MsgYesNo( cText )

FUNCTION gui_PanelCreate( xDlg, xControl, nRow, nCol, nWidth, nHeight )

   @ nCol, nRow PANEL xControl ;
      OF        xDlg ;
      SIZE      nWidth, nHeight ;
      BACKCOLOR COLOR_WHITE

   RETURN Nil

FUNCTION gui_SetFocus( xDlg, xControl )

   (xDlg)
   xControl:SetFocus()

   RETURN Nil

FUNCTION gui_TabCreate( xDlg, xControl, nRow, nCol, nWidth, nHeight )

   @ nCol, nRow TAB xControl ;
      ITEMS {} ;
      OF    xDlg ;
      ID    101 ;
      SIZE  nWidth, nHeight ;
      STYLE WS_CHILD + WS_VISIBLE

   RETURN Nil

FUNCTION gui_TabEnd()

   RETURN Nil

FUNCTION gui_TabNavigate( xDlg, oTab, aList )

   LOCAL nTab, nPageNext

   FOR nTab = 1 TO Len( aList ) - 1
      nPageNext  := iif( nTab == Len( aList ), 1, nTab + 1 )
      gui_TabSetLostFocus( aList[ nTab, Len( aList[ nTab ] ) ], oTab, nPageNext, aList[ nPageNext, 1 ] )
   NEXT
   (xDlg)

   RETURN Nil

FUNCTION gui_TabPageBegin( xDlg, xControl, cText )

   BEGIN PAGE cText OF xControl
   (xDlg)

   RETURN Nil

FUNCTION gui_TabPageEnd( xDlg, xControl )

   END PAGE OF xControl
   (xDlg)

   RETURN Nil

STATIC FUNCTION gui_TabSetLostFocus( oEdit, oTab, nPageNext, oEditNext )

   oEdit:bLostFocus := { || oTab:ChangePage( nPageNext ), oTab:SetTab( nPageNext ), gui_SetFocus( Nil, oEditNext ), .T. }

   RETURN Nil

FUNCTION gui_TextCreate( xDlg, xControl, nRow, nCol, nWidth, nHeight, ;
            xValue, cPicture, nMaxLength, bValid )

   @ nCol, nRow GET xControl ;
      VAR       xValue ;
      OF        xDlg ;
      SIZE      nWidth, nHeight ;
      STYLE     WS_DISABLED + iif( ValType( xValue ) $ "N,N+", ES_RIGHT, ES_LEFT ) ;
      ; // MAXLENGTH nMaxLength ;
      PICTURE   iif( Empty( cPicture ), Nil, cPicture ) ;
      VALID     bValid
   (nMaxLength)

   RETURN Nil

FUNCTION gui_TextEnable( xDlg, xControl, lEnable )

   IF lEnable
      xControl:Enable()
   ELSE
      xControl:Disable()
   ENDIF
   (xDlg)

   RETURN Nil

FUNCTION gui_TextGetValue( xDlg, xControl )

   (xDlg)

   RETURN xControl:Value

FUNCTION gui_TextSetValue( xDlg, xControl, xValue )

   ( xDlg )

   xControl:Value := xValue

   RETURN Nil

STATIC FUNCTION BtnSetImageText( hHandle, cCaption, cResName, nWidth, nHeight )

   LOCAL oIcon, hIcon

   oIcon := HICON():AddResource( cResName, nWidth - 20, nHeight - 20 )
   IF ValType( oIcon ) == "O"
      hIcon := oIcon:Handle
   ENDIF
   hwg_SendMessage( hHandle, BM_SETIMAGE, IMAGE_ICON, hIcon )
   hwg_SendMessage( hHandle, WM_SETTEXT, 0, cCaption )

   RETURN Nil

