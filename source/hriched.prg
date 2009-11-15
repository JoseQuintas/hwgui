/*
 * $Id: hriched.prg,v 1.19 2009-11-15 18:55:05 lfbasso Exp $
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
	 DATA lAllowTabs  INIT .F.
	 DATA lctrltab    HIDDEN
   DATA lReadOnly      INIT .F.
 	 DATA Col        INIT 0
   DATA Line       INIT 0
   DATA LinesTotal INIT 0
	 DATA SelStart   INIT 0
   DATA SelText    INIT 0
   DATA SelLength  INIT 0
	 DATA bChange

   METHOD New( oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
               oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip,;
               tcolor, bcolor, bOther, lAllowTabs, bChange )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD onGotFocus()
   METHOD onLostFocus()
   METHOD When()
   METHOD Valid()
   METHOD UpdatePos( ) 
   METHOD onChange( )
   METHOD ReadOnly( lreadOnly ) SETGET 
   
ENDCLASS

METHOD New( oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
            oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, ;
            tcolor, bcolor, bOther, lAllowTabs, bChange ) CLASS HRichEdit

   nStyle := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), WS_CHILD + WS_VISIBLE + WS_TABSTOP + WS_BORDER )
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, IIf( bcolor == Nil, GetSysColor( COLOR_BTNHIGHLIGHT ), bcolor ) )

   ::title   := vari
   ::bOther  := bOther
   ::bChange := bChange
   ::lAllowTabs := IIF( EMPTY( lAllowTabs ), ::lAllowTabs, lAllowTabs )
   hwg_InitRichEdit()

   ::Activate()

   IF bGfocus != Nil
      //::oParent:AddEvent( EN_SETFOCUS, Self, bGfocus,, "onGotFocus" )
      ::bGetFocus := bGfocus
      ::oParent:AddEvent( EN_SETFOCUS, Self, { | o | ::When( o ) }, , "onGotFocus" )
   ENDIF
   IF bLfocus != Nil
      //::oParent:AddEvent( EN_KILLFOCUS, Self, bLfocus,, "onLostFocus" )
      ::bLostFocus := bLfocus
      ::oParent:AddEvent( EN_KILLFOCUS, Self, { | o | ::Valid( o ) }, , "onLostFocus" )
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
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      Hwg_InitRichProc( ::handle )
      Super:Init()
      IF ::bChange != Nil
         SendMessage( ::handle, EM_SETEVENTMASK, 0, ENM_SELCHANGE + ENM_CHANGE )
         ::oParent:AddEvent( EN_CHANGE, ::id, {| | ::onChange( )} )
      ENDIF   
   ENDIF
   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HRichEdit
   LOCAL nDelta, nret, nPos

   // writelog( str(msg) + str(wParam) + str(lParam) )
   IF msg = WM_NOTIFY .OR. msg = WM_KEYUP .OR. msg == WM_LBUTTONDOWN .OR. msg == WM_LBUTTONUP 
      ::updatePos()
   ENDIF
   IF msg = EM_GETSEL .OR. msg = EM_LINEFROMCHAR .OR. msg = EM_LINEINDEX .OR. msg = EM_GETLINECOUNT
      Return - 1
   ENDIF
   
   IF msg = WM_SETFOCUS .and. ::lSetFocus .AND. ISWINDOWVISIBLE(::handle)
      ::lSetFocus := .F.
      SendMessage( ::handle, EM_SETSEL, 0, 0 ) //Loword(npos),loword(npos))
   ELSEIF msg = WM_SETFOCUS .AND. ::lAllowTabs .AND. ::GetParentForm( Self ):Type < WND_DLG_RESOURCE
    	 ::lctrltab := ::GetParentForm( Self ):lDisableCtrlTab 
    	 ::GetParentForm( Self ):lDisableCtrlTab := ::lAllowTabs 
   ELSEIF msg = WM_KILLFOCUS .AND. ::lAllowTabs .AND. ::GetParentForm( Self ):Type < WND_DLG_RESOURCE
    	 ::GetParentForm( Self ):lDisableCtrlTab := ::lctrltab
   ENDIF
   IF msg == WM_CHAR
      IF wParam = VK_TAB .AND. ::GetParentForm( Self ):Type < WND_DLG_RESOURCE
         IF  ( IsCtrlShift(.T.,.f.) .OR. ! ::lAllowTabs )
            RETURN 0
         ENDIF 
      ENDIF
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
     IF wParam = VK_TAB .AND. ::GetParentForm( Self ):Type < WND_DLG_RESOURCE
         IF   IsCtrlShift(.T.,.f.) 
            GetSkip( ::oParent, ::handle, , ;
				          iif( IsCtrlShift(.f., .t.), -1, 1) )
            RETURN 0
         ENDIF 
      ENDIF
   ELSEIF msg == WM_KEYDOWN
      IF wParam = VK_TAB .AND. ( IsCtrlShift(.T.,.f.) .OR. ! ::lAllowTabs )
         GetSkip( ::oParent, ::handle, , ;
				          iif( IsCtrlShift(.f., .t.), -1, 1) )
         RETURN 0
      ELSEIF wParam = VK_TAB .AND. ::GetParentForm( Self ):Type >= WND_DLG_RESOURCE
         RE_INSERTTEXT( ::handle, CHR( VK_TAB ) ) 
	       RETURN 0
      ENDIF
      IF wParam == VK_ESCAPE
         IF GetParent(::oParent:handle) != Nil
            //SendMessage( GetParent(::oParent:handle),WM_CLOSE,0,0 )
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

METHOD ReadOnly( lreadOnly )

   IF lreadOnly != Nil
      IF ! EMPTY( SENDMESSAGE( ::handle,  EM_SETREADONLY, IIF( lReadOnly, 1, 0 ), 0 ) )
          ::lReadOnly := lReadOnly
      ENDIF    
   ENDIF   
   RETURN ::lReadOnly

METHOD UpdatePos( ) CLASS HRichEdit
 	 LOCAL npos := SendMessage( ::handle, EM_GETSEL, 0, 0 )
   LOCAL pos1 := Loword( npos ) + 1,	pos2 := Hiword( npos ) + 1

	 ::Line := SendMessage( ::Handle, EM_LINEFROMCHAR, pos1 - 1, 0 ) + 1
	 ::LinesTotal := SendMessage( ::handle, EM_GETLINECOUNT, 0, 0 )
	 ::SelText := RE_GETTEXTRANGE( ::handle, pos1, pos2 ) 
	 ::SelStart := pos1
	 ::SelLength := pos2 - pos1
   ::Col := pos1 - SendMessage( ::Handle, EM_LINEINDEX, - 1, 0 ) 

   RETURN nPos
   
METHOD onChange( ) CLASS HRichEdit

   IF ::bChange != Nil 
      ::oparent:lSuspendMsgsHandling := .t.
      Eval( ::bChange, ::gettext(), Self  )
      ::oparent:lSuspendMsgsHandling := .f.
   ENDIF
   RETURN Nil

METHOD onGotFocus( ) CLASS HRichEdit
  RETURN ::When()

METHOD onLostFocus( ) CLASS HRichEdit
  RETURN ::Valid()
   

METHOD When( ) CLASS HRichEdit
 
	 IF !CheckFocus( Self, .f. )
	    RETURN .t.
   ENDIF
	 
   ::oparent:lSuspendMsgsHandling := .t.
   Eval( ::bGetFocus, ::title, Self )
   ::oparent:lSuspendMsgsHandling := .f.
 RETURN .T.


METHOD Valid( ) CLASS HRichEdit

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
