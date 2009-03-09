/*
 * $Id: hriched.prg,v 1.16 2009-03-09 21:11:22 lfbasso Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HRichEdit class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HRichEdit INHERIT HControl

CLASS VAR winclass   INIT "RichEdit20A"
   DATA lChanged    INIT .F.
   DATA lSetFocus   INIT .T.
   
   METHOD New( oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
               oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, tcolor, bcolor, bOther )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD GotFocus( oCtrl )
   METHOD LostFocus( oCtrl )


ENDCLASS

METHOD New( oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
            oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, ;
            tcolor, bcolor, bOther ) CLASS HRichEdit

   nStyle := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), WS_CHILD + WS_VISIBLE + WS_TABSTOP + WS_BORDER )
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, IIf( bcolor == Nil, GetSysColor( COLOR_BTNHIGHLIGHT ), bcolor ) )

   ::title   := vari
   ::bOther  := bOther
   hwg_InitRichEdit()

   ::Activate()

   IF bGfocus != Nil
      //::oParent:AddEvent( EN_SETFOCUS, Self, bGfocus,, "onGotFocus" )
      ::bGetFocus := bGfocus
      ::oParent:AddEvent( EN_SETFOCUS, Self, { | o | ::GotFocus( o ) }, , "onGotFocus" )
   ENDIF
   IF bLfocus != Nil
      //::oParent:AddEvent( EN_KILLFOCUS, Self, bLfocus,, "onLostFocus" )
      ::bLostFocus := bLfocus
      ::oParent:AddEvent( EN_KILLFOCUS, Self, { | o | ::LostFocus( o ) }, , "onLostFocus" )
   ENDIF

   RETURN Self

METHOD Activate CLASS HRichEdit
   IF ! Empty( ::oParent:handle )
      ::handle := CreateRichEdit( ::oParent:handle, ::id, ;
                                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF
   RETURN Nil
   
METHOD Init()  CLASS HRichEdit
   IF ! ::lInit
      Super:Init()
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      Hwg_InitRichProc( ::handle )
   ENDIF
   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HRichEdit
   LOCAL nDelta, nret

   // writelog( str(msg) + str(wParam) + str(lParam) )
   IF msg = WM_SETFOCUS .and. ::lSetFocus .AND. ISWINDOWVISIBLE( ::handle )
      ::lSetFocus := .F.
      // npos := SendMessage( ::handle, EM_GETSEL, 0, 0 )
      SendMessage( ::handle,EM_SETSEL,0,0) //Loword(npos),loword(npos))
   ENDIF
   
   IF msg == WM_CHAR
	    IF !IsCtrlShift( .T., .F.)
         ::lChanged := .T.
      ENDIF   
   ELSEIF msg == WM_KEYDOWN .AND. wParam = 46  //Del
      ::lChanged := .T.
   ELSEIF ::bOther != Nil
      nret := Eval( ::bOther, Self, msg, wParam, lParam )
      IF ValType( nret ) != "N" .OR. nret > - 1
         RETURN nret
      ENDIF
   ENDIF
   IF msg == WM_KEYUP
      IF wParam = VK_TAB .AND. IsCtrlShift(.T.) //GETKEYSTATE(VK_CONTROL) < 0
         GetSkip( ::oParent, ::handle, , ;
				          iif( IsCtrlShift(.f., .t.), -1, 1) )
         RETURN 0
      ENDIF
   ENDIF
   IF msg == WM_KEYDOWN
      IF wParam == 27 // ESC
         IF GetParent( ::oParent:handle ) != Nil
            //SendMessage( GetParent( ::oParent:handle ), WM_CLOSE, 0, 0 )
         ENDIF
      ENDIF
   ELSEIF msg == WM_MOUSEWHEEL
      nDelta := HIWORD( wParam )
      IF nDelta > 32768
         nDelta -= 65535
      ENDIF
      SendMessage( ::handle, EM_SCROLL, IIf( nDelta > 0, SB_LINEUP, SB_LINEDOWN ), 0 )
//      SendMessage( ::handle,EM_SCROLL, Iif(nDelta>0,SB_LINEUP,SB_LINEDOWN), 0 )
   ELSEIF msg == WM_DESTROY
      ::END()
   ENDIF

   RETURN - 1

METHOD GotFocus( Octrl ) CLASS HRichEdit
 
	 IF !CheckFocus( Self, .f. )
	    RETURN .t.
   ENDIF
	 
   ::oparent:lSuspendMsgsHandling := .t.
   Eval( ::bGetFocus, ::title, Self )
   ::oparent:lSuspendMsgsHandling := .f.
 RETURN .T.


METHOD LostFocus( oCtrl ) CLASS HRichEdit

	 IF ::bLostFocus != Nil .AND. !CheckFocus( Self, .T. )
	    RETURN .T.
 	 ENDIF
	 
   ::oparent:lSuspendMsgsHandling := .t.
   Eval( ::bLostFocus, ::title, Self )
   ::oparent:lSuspendMsgsHandling := .f.

  RETURN .T.


/*
Function DefRichProc( hEdit, msg, wParam, lParam )
Local oEdit
   // writelog( "RichProc: " + Str(hEdit,10)+"|"+Str(msg,6)+"|"+Str(wParam,10)+"|"+Str(lParam,10) )
   oEdit := FindSelf( hEdit )
   IF msg == WM_CHAR
      oEdit:lChanged := .T.
   ELSEIF msg == WM_KEYDOWN
      IF wParam == 46     // Del
         oEdit:lChanged := .T.
      ENDIF
   ELSEIF oEdit:bOther != Nil
      Return Eval( oEdit:bOther, oEdit, msg, wParam, lParam )
   ENDIF
Return -1
*/
