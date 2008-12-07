/*
 * $Id: hprogres.prg,v 1.14 2008-12-07 15:00:10 lfbasso Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HProgressBar class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
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
   METHOD Increment() INLINE UpdateProgressBar( ::handle )
   METHOD STEP()
   METHOD SET( cTitle, nPos )
   METHOD SetLabel( cCaption )
   METHOD Close()
   METHOD End() INLINE DestroyWindow( ::handle )

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, maxPos, nRange, bInit, bSize, bPaint, ctooltip, nAnimation, lVertical ) CLASS HProgressBar

   ::Style := IIF( lvertical != Nil .AND. lVertical, PBS_VERTICAL, 0 )
	 ::Style += IIF( nAnimation != Nil .AND. nAnimation > 0, PBS_MARQUEE, 0 )
	 ::nAnimation := nAnimation

   Super:New( oWndParent, nId, ::Style, nLeft, nTop, nWidth, nHeight,, bInit, bSize, bPaint, ctooltip )

   ::maxPos  := IIf( maxPos == Nil, 20, maxPos )
   ::lNewBox := .F.
   ::nRange := Iif( nRange != Nil .AND. nRange != 0, nRange, 100 )
   ::nLimit := IIf( nRange != Nil, Int( ::nRange / ::maxPos ), 1 )

   ::Activate()

   RETURN Self

METHOD NewBox( cTitle, nLeft, nTop, nWidth, nHeight, maxPos, nRange, bExit, lPercent ) CLASS HProgressBar

   // ::classname:= "HPROGRESSBAR"
   ::style   := WS_CHILD + WS_VISIBLE
   nWidth := IIf( nWidth == Nil, 220, nWidth )
   nHeight := IIf( nHeight == Nil, 55, nHeight )
   nLeft   := IIf( nLeft == Nil, 0, nLeft )
   nTop    := IIf( nTop == Nil, 0, nTop )
   //nWidth  := IIf( nWidth == Nil, 220, nWidth )
  // nHeight := IIf( nHeight == Nil, 55, nHeight )
   ::nLeft := 20
   ::nTop  := 25
   ::nWidth  := nWidth - 40
   ::maxPos  := IIf( maxPos == Nil, 20, maxPos )
   ::lNewBox := .T.
   ::nRange := Iif( nRange != Nil .AND. nRange != 0, nRange, 100 )
   ::nLimit := IIf( nRange != Nil, Int( nRange / ::maxPos ), 1 )
	 ::lPercent := lPercent
	 
   INIT DIALOG ::oParent TITLE cTitle       ;
        At nLeft, nTop SIZE nWidth, nHeight   ;
        STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX + IIf( nTop == 0, DS_CENTER, 0 ) + DS_SYSMODAL + MB_USERICON

   @ ::nLeft, nTop + 5 SAY ::LabelBox CAPTION IIF( EMPTY( lPercent ), "", "%" )  SIZE ::nWidth, 19 ;
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
      ::handle := CreateProgressBar( ::oParent:handle, ::maxPos, ;
                                     ::nLeft, ::nTop, ::nWidth )
      ::Init()
   ENDIF
   RETURN Nil

METHOD Init  CLASS HProgressBar

   IF ! ::lInit
      Super:Init()
      SendMessage( ::handle, PBM_SETRANGE, 0, MAKELPARAM( 0, ::nRange ) )
	    SendMessage( ::handle, PBM_SETSTEP, ::maxPos, 0 )   
	    IF ::nAnimation != Nil .AND. ::nAnimation > 0
	       SendMessage( ::handle, PBM_SETMARQUEE, 1, ::nAnimation )
	    ENDIF   
   ENDIF

  RETURN Nil

METHOD STEP()

   ::nCount ++
   IF ::nCount == ::nLimit
      ::nCount := 0
      UpdateProgressBar( ::handle )
      IF ! EMPTY( ::lPercent )
         ::nPercent += ::nLimit
         ::setLabel( LTRIM( STR( ::nPercent, 3 ) ) + " %" )
      ENDIF
   ENDIF

   RETURN Nil

METHOD SET( cTitle, nPos ) CLASS HProgressBar

   IF cTitle != Nil
      SetWindowText( ::oParent:handle, cTitle )
   ENDIF
   IF nPos != Nil
      SetProgressBar( ::handle, nPos )
   ENDIF

   RETURN Nil
   
METHOD SetLabel( cCaption ) CLASS HProgressBar

   IF cCaption != Nil .AND. ::lNewBox
      ::LabelBox:caption := cCaption 
   ENDIF
   
   RETURN Nil

METHOD Close()

   DestroyWindow( ::handle )
   IF ::lNewBox
      EndDialog( ::oParent:handle )
   ENDIF

   RETURN Nil

