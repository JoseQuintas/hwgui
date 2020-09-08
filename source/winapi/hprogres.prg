/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HProgressBar class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HProgressBar INHERIT HControl

   CLASS VAR winclass   INIT "msctls_progress32"
   DATA  maxPos
   DATA  nRange
   DATA  lNewBox
   DATA  nCount INIT 0
   DATA  nLimit
   DATA  nAnimation
   DATA  LabelBox
   DATA  nPercent INIT 0
   DATA  lPercent INIT .F.

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, maxPos, nRange, bInit, bSize, bPaint, ctooltip, nAnimation, lVertical )
   METHOD NewBox( cTitle, nLeft, nTop, nWidth, nHeight, maxPos, nRange, bExit, bInit, bSize, bPaint, ctooltip )
   METHOD Init()
   METHOD Activate()
   METHOD Increment() INLINE hwg_Updateprogressbar( ::handle )
   METHOD STEP()
   METHOD RESET( cTitle )
   METHOD SET( cTitle, nPos )
   METHOD SetLabel( cCaption )
   METHOD CLOSE()
   METHOD End() INLINE hwg_Destroywindow( ::handle )
   METHOD Redefine( oWndParent, nId,  maxPos, nRange, bInit, bSize, bPaint, ctooltip, nAnimation, lVertical )

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, maxPos, nRange, bInit, bSize, bPaint, ctooltip, nAnimation, lVertical ) CLASS HProgressBar

   ::Style := iif( lvertical != Nil .AND. lVertical, PBS_VERTICAL, 0 )
   ::Style += iif( nAnimation != Nil .AND. nAnimation > 0, PBS_MARQUEE, 0 )
   ::nAnimation := nAnimation

   ::Super:New( oWndParent, nId, ::Style, nLeft, nTop, nWidth, nHeight, , bInit, bSize, bPaint, ctooltip )

   ::maxPos  := iif( maxPos == Nil, 20, maxPos )
   ::lNewBox := .F.
   ::nRange := iif( nRange != Nil .AND. nRange != 0, nRange, 100 )
   ::nLimit := iif( nRange != Nil, Int( ::nRange / ::maxPos ), 1 )

   ::Activate()

   RETURN Self

   
METHOD Redefine( oWndParent, nId,  maxPos, nRange, bInit, bSize, bPaint, ctooltip, nAnimation, lVertical )

   ::Super:New( oWndParent,nId,0,0,0,0,0,,bInit, ;
                  bSize,bPaint,ctooltip,, )
   HWG_InitCommonControlsEx()
   //::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   ::maxPos  := iif( maxPos == Nil, 20, maxPos )
   ::lNewBox := .F.
   ::nRange := iif( nRange != Nil .AND. nRange != 0, nRange, 100 )
   ::nLimit := iif( nRange != Nil, Int( ::nRange / ::maxPos ), 1 )  
    ::nAnimation := nAnimation
return self    
   
METHOD NewBox( cTitle, nLeft, nTop, nWidth, nHeight, maxPos, nRange, bExit, lPercent ) CLASS HProgressBar

   // ::classname:= "HPROGRESSBAR"
   ::style   := WS_CHILD + WS_VISIBLE
   nWidth := iif( nWidth == Nil, 220, nWidth )
   nHeight := iif( nHeight == Nil, 55, nHeight )
   nLeft   := iif( nLeft == Nil, 0, nLeft )
   nTop    := iif( nTop == Nil, 0, nTop )
   ::nLeft := 20
   ::nTop  := 25
   ::nWidth  := nWidth - 40
   ::maxPos  := iif( maxPos == Nil, 20, maxPos )
   ::lNewBox := .T.
   ::nRange := iif( nRange != Nil .AND. nRange != 0, nRange, 100 )
   ::nLimit := iif( nRange != Nil, Int( ::nRange / ::maxPos ), 1 )
   ::lPercent := lPercent

   INIT DIALOG ::oParent TITLE cTitle       ;
      At nLeft, nTop SIZE nWidth, nHeight   ;
      STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX + iif( nTop == 0, DS_CENTER, 0 ) + DS_SYSMODAL + MB_USERICON

   @ ::nLeft, nTop + 5 SAY ::LabelBox CAPTION iif( Empty( lPercent ), "", "%" )  SIZE ::nWidth, 19 ;
      STYLE SS_CENTER

   IF bExit != Nil
      ::oParent:bDestroy := bExit
   ENDIF

   ACTIVATE DIALOG ::oParent NOMODAL

   ::id := ::NewId()
   ::Activate()
   ::oParent:AddControl( Self )

   RETURN Self

METHOD Activate CLASS HProgressBar

   IF ! Empty( ::oParent:handle )
      ::handle := hwg_Createprogressbar( ::oParent:handle, ::maxPos, ::style, ;
         ::nLeft, ::nTop, ::nWidth, iif( ::nHeight = 0, Nil, ::nHeight ) )
      ::Init()
   ENDIF

   RETURN Nil

METHOD Init  CLASS HProgressBar

   IF ! ::lInit
      ::Super:Init()
      //hwg_Sendmessage( ::handle, PBM_SETRANGE, 0, hwg_Makelparam( 0, ::nRange ) )
      //hwg_Sendmessage( ::handle, PBM_SETSTEP, ::maxPos, 0 )
      //hwg_Sendmessage( ::handle, PBM_SETSTEP, ::nLimit , 0 )
      IF ::nAnimation != Nil .AND. ::nAnimation > 0
         hwg_Sendmessage( ::handle, PBM_SETMARQUEE, 1, ::nAnimation )
      ENDIF
   ENDIF

   RETURN Nil

METHOD STEP( cTitle )

   ::nCount ++
   IF ::nCount == ::nLimit
      ::nCount := 0
      hwg_Updateprogressbar( ::handle )
      ::Set( cTitle )
      IF ! Empty( ::lPercent )
         ::nPercent += ::maxPos  //::nLimit
         ::setLabel( LTrim( Str( ::nPercent, 3 ) ) + " %" )
      ENDIF
   ENDIF

   RETURN Nil
   
* Added by DF7BE
METHOD RESET( cTitle )
  IF cTitle != Nil
      hwg_Setwindowtext( ::oParent:handle, cTitle )
  ENDIF
  hwg_Resetprogressbar( ::handle )

  RETURN Nil
   

METHOD SET( cTitle, nPos ) CLASS HProgressBar

   IF cTitle != Nil
      hwg_Setwindowtext( ::oParent:handle, cTitle )
   ENDIF
   IF nPos != Nil
      hwg_Setprogressbar( ::handle, nPos )
   ENDIF

   RETURN Nil

METHOD SetLabel( cCaption ) CLASS HProgressBar

   IF cCaption != Nil .AND. ::lNewBox
      ::LabelBox:SetText( cCaption )
   ENDIF

   RETURN Nil

METHOD CLOSE()

   hwg_Destroywindow( ::handle )
   IF ::lNewBox
      hwg_EndDialog( ::oParent:handle )
   ENDIF

   RETURN Nil
   
* ============================ EOF of hprogres.prg =============================
   
