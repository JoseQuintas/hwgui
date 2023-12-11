/*
frm_Edit - Create textbox/label on dialog
*/

#include "hbclass.ch"
#include "frm_class.ch"

FUNCTION frm_Edit( Self )

   LOCAL nRow, nCol, aItem, oTab, nPageCount := 0, nLen, aList := {}
   LOCAL nLenList, nRow2, nCol2, lFirst := .T.

   FOR EACH aItem IN ::aEditList
      aItem[ CFG_VALUE ]    := &( ::cFileDbf )->( FieldGet( FieldNum( aItem[ CFG_FNAME ] ) ) )
      AAdd( ::aControlList, AClone( aItem ) )
   NEXT
   IF ::lWithTab
      gui_TabCreate( ::oDlg, @oTab, 70, 5, ::nDlgWidth - 19, ::nDlgHeight - 75 )
      AAdd( ::aControlList, CFG_EMPTY )
      Atail( ::aControlList )[ CFG_CTLTYPE ]  := TYPE_TAB
      Atail( ::aControlList )[ CFG_FCONTROL ] := oTab
      //PanelCreate( oTab, @oPanel, 23, 1, ::nDlgWidth - 25, ::nDlgHeight - 100 )
      //AAdd( ::aControlList, CFG_EMPTY )
      //Atail( ::aControlList )[ CFG_CTLTYPE ] := TYPE_PANEL
      //Atail( ::aControlList )[ CFG_FCONTROL ] := oPanel
      nRow := 999
   ELSE
      nRow := 80
   ENDIF
   nCol := 10
   nLenList := Len( ::aControlList )
   FOR EACH aItem IN ::aControlList
      IF aItem:__EnumIndex > nLenList
         EXIT
      ENDIF
      IF aItem[ CFG_CTLTYPE ] != TYPE_EDIT
         LOOP
      ENDIF
      IF ::nEditStyle == 1 .OR. ::nEditStyle == 2
         nLen := Len( aItem[ CFG_CAPTION ] ) + aItem[ CFG_FLEN ] + 1 + ;
            iif( Empty( aItem[ CFG_VTABLE ] ), 0, aItem[ CFG_VLEN ] + 4 )
      ELSE
         nLen := Max( aItem[ CFG_FLEN ] + 1 + iif( Empty( aItem[ CFG_VTABLE ] ), 0, aItem[ CFG_VLEN ] + 4 ), ;
            Len( aItem[ CFG_CAPTION ] ) )
      ENDIF
      IF ::nEditStyle == 1 .OR. ( nCol != 10 .AND. nCol + 30 + ( nLen * 12 ) > ::nDlgWidth - 40 ) .OR. ;
         ( ::lWithTab .AND. nRow > ::nDlgHeight - ( ::nLineHeight * 3 ) )
         IF ::lWithTab .AND. nRow > ::nDlgHeight - ( ::nLineHeight * 3 ) - 150
            IF nPageCount > 0
               gui_TabPageEnd( ::oDlg, oTab )
            ENDIF
            nPageCount += 1
            gui_TabPageBegin( ::oDlg, oTab, "Pag." + Str( nPageCount, 2 ) )
            nRow := 40
            AAdd( aList, {} )
            lFirst := .T.
         ENDIF
         nCol := 10
         IF ! lFirst
            nRow += ( ::nLineSpacing * iif( ::nEditStyle < 3, 2, 3 ) )
         ENDIF
      ENDIF
      IF ::nEditStyle == 1 .OR. ::nEditStyle == 2
         nRow2 := nRow
         nCol2 := nCol + ( Len( aItem[ CFG_CAPTION ] ) * 12 )
      ELSE
         nRow2 := nRow + ::nLineSpacing
         nCol2 := nCol
      ENDIF
      lFirst := .F.
      gui_LabelCreate( iif( ::lWithTab, oTab, ::oDlg ), @aItem[ CFG_CCONTROL ], ;
         nRow, nCol, nLen * 12, ::nLineHeight, aItem[ CFG_CAPTION ], .F. )

      gui_TextCreate( iif( ::lWithTab, oTab, ::oDlg ), @aItem[ CFG_FCONTROL ], ;
         nRow2, nCol2, aItem[ CFG_FLEN ] * 12 + 12, ::nLineHeight, ;
         @aItem[ CFG_VALUE ], aItem[ CFG_FPICTURE ], aitem[ CFG_FLEN ], ;
         { || ::Validate( aItem ) } )
      nCol += ( nLen + 3 ) * 12
      IF ::lWithTab
         AAdd( Atail( aList ), aItem[ CFG_FCONTROL ] )
      ENDIF
      IF ! Empty( aItem[ CFG_VTABLE ] )
         gui_LabelCreate( iif( ::lWithTab, oTab, ::oDlg ), @aItem[ CFG_VCONTROL ], ;
            nRow2, nCol2 + ( ( aItem[ CFG_FLEN ] + 4 ) * 12 ), aItem[ CFG_VLEN ] * 12, ;
            ::nLineHeight, Space( aItem[ CFG_VLEN ] ), .T. )
      ENDIF
   NEXT
#ifdef HBMK_HAS_HWGUI
   // dummy textbox to works last valid
   AAdd( ::aControlList, CFG_EMPTY )
   gui_TextCreate( ::oDlg, @Atail( ::aControlList )[ CFG_FCONTROL ], ;
      nRow, nCol, 0, 0, "", "", 0, { || .T. } )
#endif
   IF ::lWithTab
      gui_TabPageEnd( ::oDlg, oTab )
      gui_TabNavigate( ::oDlg, oTab, aList )
      gui_TabEnd()
   ENDIF
   (nRow2)
   (nCol2)

   RETURN Nil
