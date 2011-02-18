/*
 * $Id$
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
   METHOD NewBox( cTitle, nLeft, nTop, nWidth, nHeight, maxPos, nRange, bExit, lPercent )
   METHOD Init()
   METHOD Activate()
   METHOD Increment() INLINE UpdateProgressBar( ::handle )
   METHOD STEP( cTitle )
   METHOD SET( cTitle, nPos )
   METHOD SetLabel( cCaption )
   METHOD SetAnimation( nAnimation ) SETGET
   METHOD Close()
   METHOD End() INLINE DestroyWindow( ::handle )

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, maxPos, nRange, bInit, bSize, bPaint, ctooltip, nAnimation, lVertical ) CLASS HProgressBar

   ::Style := IIF( lvertical != Nil .AND. lVertical, PBS_VERTICAL, 0 )
	 ::Style += IIF( nAnimation != Nil .AND. nAnimation > 0, PBS_MARQUEE, 0 )
	 ::nAnimation := nAnimation

   Super:New( oWndParent, nId, ::Style, nLeft, nTop, nWidth, nHeight,, bInit, bSize, bPaint, ctooltip )

   ::maxPos  := Iif( maxPos != Nil .AND. maxPos != 0, maxPos, 20 )
   ::lNewBox := .F.
   ::nRange := Iif( nRange != Nil .AND. nRange != 0, nRange, 100 )
   ::nLimit := Int( ::nRange/::maxPos )

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
   ::nLimit := IIf( nRange != Nil, Int( ::nRange / ::maxPos ), 1 )
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
   ::nHeight := 0
   ::Activate()
   ::oParent:AddControl( Self )

   RETURN Self

METHOD Activate() CLASS HProgressBar

   IF ! Empty( ::oParent:handle )
      ::handle := CreateProgressBar( ::oParent:handle, ::maxPos, ::style, ;
                                     ::nLeft, ::nTop, ::nWidth, IIF( ::nHeight = 0, Nil, ::nHeight ) )
      ::Init()
   ENDIF
   RETURN Nil

METHOD Init()  CLASS HProgressBar

   IF ! ::lInit
      Super:Init()
	    IF ::nAnimation != Nil .AND. ::nAnimation > 0
	       SendMessage( ::handle, PBM_SETMARQUEE, 1, ::nAnimation )
	    ENDIF
   ENDIF

  RETURN Nil

METHOD STEP( cTitle )

   ::nCount ++
   IF ::nCount == ::nLimit
      ::nCount := 0
      UpdateProgressBar( ::handle )
      ::SET( cTitle )
      IF ! EMPTY( ::lPercent )
         ::nPercent += ::maxPos  //::nLimit
         ::setLabel( LTRIM( STR( ::nPercent, 3 ) ) + " %" )
      ENDIF
      RETURN .T.
   ENDIF

   RETURN .F.

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
      ::LabelBox:SetValue( cCaption )
   ENDIF

   RETURN Nil

METHOD SetAnimation( nAnimation ) CLASS HProgressBar

   IF nAnimation != Nil
	    IF  nAnimation <= 0
	       SendMessage( ::handle, PBM_SETMARQUEE, 0, Nil )
	       MODIFYSTYLE( ::Handle, PBS_MARQUEE, 0 )
	       SendMessage( ::handle, PBM_SETPOS, 0, 0)
	    ELSE
	       IF Hwg_BitAND( ::Style, PBS_MARQUEE ) = 0
	          MODIFYSTYLE( ::Handle, PBS_MARQUEE, PBS_MARQUEE )
         ENDIF
         SendMessage( ::handle, PBM_SETMARQUEE, 1, nAnimation)
	    ENDIF
	    ::nAnimation := nAnimation
   ENDIF
   RETURN IIF( ::nAnimation != Nil, ::nAnimation, 0 )

METHOD Close()

   DestroyWindow( ::handle )
   IF ::lNewBox
      EndDialog( ::oParent:handle )
   ENDIF

   RETURN Nil

