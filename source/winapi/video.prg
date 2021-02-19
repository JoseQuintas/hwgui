/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * TVideo component
 *
 * Copyright 2003 Luiz Rafael Culik Guimaraes <culikr@brtrubo.com>
 * www - http://sites.uol.com.br/culikr/
*/
#include "hbclass.ch"
#include "windows.ch"
#include "guilib.ch"

#include "common.ch"


//----------------------------------------------------------------------------//

CLASS TVideo FROM hControl


   DATA   oMci
   DATA   cAviFile

   METHOD New( nRow, nCol, nWidth, nHeight, cFileName, oWnd, ;
               lNoBorder, nid ) CONSTRUCTOR

   METHOD ReDefine( nId, cFileName, oDlg, bWhen, bValid ) CONSTRUCTOR

   METHOD Initiate( )

   METHOD Play( nFrom, nTo ) INLINE  ::oMci:Play( nFrom, nTo, ::oparent:handle )

ENDCLASS

//----------------------------------------------------------------------------//

/*  removed: bWhen , bValid */
METHOD New( nRow, nCol, nWidth, nHeight, cFileName, oWnd, lNoBorder, nid ) CLASS TVideo

   DEFAULT nWidth TO 200, nHeight TO 200, cFileName TO "", ;
   lNoBorder TO .f.

   ::nTop      := nRow *  VID_CHARPIX_H  // 8
   ::nLeft     := nCol * VID_CHARPIX_W   // 14
   ::nHeight   := ::nTop  + nHeight - 1
   ::nWidth    := ::nLeft + nWidth + 1
   ::Style     := hwg_bitOR( WS_CHILD + WS_VISIBLE + WS_TABSTOP, IF( ! lNoBorder, WS_BORDER, 0 ) )

   ::oParent   := IIf( oWnd == Nil, ::oDefaultParent, oWnd )
   ::id        := IIf( nid == Nil, ::NewId(), nid )
   ::cAviFile  := cFileName
   ::oMci      := TMci():New( "avivideo", cFileName )
   ::Initiate()

   IF ! Empty( ::oparent:handle )
      ::oMci:lOpen()
      ::oMci:SetWindow( Self )
   ELSE
      ::oparent:AddControl( Self )
   ENDIF

   RETURN Self

//----------------------------------------------------------------------------//

METHOD ReDefine( nId, cFileName, oDlg, bWhen, bValid ) CLASS TVideo

   ::nId      = nId
   ::cAviFile = cFileName
   ::bWhen    = bWhen
   ::bValid   = bValid
   ::oWnd     = oDlg
   ::oMci     = TMci():New( "avivideo", cFileName )

   oDlg:AddControl( Self )

   RETURN Self

//----------------------------------------------------------------------------//

METHOD Initiate( ) CLASS TVideo

   ::Super:Init(  )
   ::oMci:lOpen()
   ::oMci:SetWindow( Self )

   RETURN nil

//----------------------------------------------------------------------------//
