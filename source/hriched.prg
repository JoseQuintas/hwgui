/*
 * $Id$
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

#ifdef UNICODE
   CLASS VAR winclass INIT "RichEdit20W"
#else
   CLASS VAR winclass INIT "RichEdit20A"
#endif
   DATA lChanged   INIT .F.
   DATA lSetFocus  INIT .T.
   DATA lAllowTabs INIT .F.
   DATA lctrltab   HIDDEN
   DATA lReadOnly  INIT .F.
   DATA Col        INIT 0
   DATA Line       INIT 0
   DATA LinesTotal INIT 0
   DATA SelStart   INIT 0
   DATA SelText    INIT 0
   DATA SelLength  INIT 0

   DATA hdcPrinter

   DATA bChange

   METHOD New( oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
               oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip,;
               tcolor, bcolor, bOther, lAllowTabs, bChange, lnoBorder )
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
   METHOD SetColor( tColor, bColor, lRedraw )
   METHOD Savefile( cFile )
   METHOD OpenFile( cFile )
   METHOD Print()

ENDCLASS

METHOD New( oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
            oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, ;
            tcolor, bcolor, bOther, lAllowTabs, bChange, lnoBorder ) CLASS HRichEdit

   nStyle := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), WS_CHILD + WS_VISIBLE + WS_TABSTOP + ; // WS_BORDER )
                        IIf( lNoBorder = Nil.OR. ! lNoBorder, WS_BORDER, 0 ) )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, IIf( bcolor == Nil, hwg_Getsyscolor( COLOR_BTNHIGHLIGHT ), bcolor ) )

   ::title   := vari
   ::bOther  := bOther
   ::bChange := bChange
   ::lAllowTabs := IIF( EMPTY( lAllowTabs ), ::lAllowTabs, lAllowTabs )
   ::lReadOnly := Hwg_BitAnd( nStyle, ES_READONLY ) != 0

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

METHOD Activate() CLASS HRichEdit
   IF ! Empty( ::oParent:handle )
      ::handle := hwg_Createrichedit( ::oParent:handle, ::id, ;
                                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF
   RETURN Nil

METHOD Init()  CLASS HRichEdit
   IF ! ::lInit
      ::nHolder := 1
      hwg_Setwindowobject( ::handle, Self )
      Hwg_InitRichProc( ::handle )
      ::Super:Init()
      ::SetColor( ::tColor, ::bColor )
      IF ::bChange != Nil
         hwg_Sendmessage( ::handle, EM_SETEVENTMASK, 0, ENM_SELCHANGE + ENM_CHANGE )
         ::oParent:AddEvent( EN_CHANGE, ::id, {| | ::onChange( )} )
      ENDIF
   ENDIF
   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HRichEdit
   LOCAL nDelta, nret

   //HWG_writelog( 'rich' + str(msg) + str(wParam) + str(lParam) + chr(13) )
   IF msg = WM_KEYUP .OR. msg == WM_LBUTTONDOWN .OR. msg == WM_LBUTTONUP // msg = WM_NOTIFY .OR.
      ::updatePos()
   ELSEIF msg == WM_MOUSEACTIVATE  .AND. hwg_GetParentForm(Self):Type < WND_DLG_RESOURCE
      ::Setfocus( )
   ENDIF
   IF  msg = EM_GETSEL .OR. msg = EM_LINEFROMCHAR .OR. msg = EM_LINEINDEX .OR. ;
       msg = EM_GETLINECOUNT .OR. msg = EM_SETSEL .OR. msg = EM_SETCHARFORMAT .OR. ;
       msg = EM_HIDESELECTION .OR. msg = WM_GETTEXTLENGTH .OR. msg = EM_GETFIRSTVISIBLELINE
      Return - 1
   ENDIF
   IF msg = WM_SETFOCUS .AND. ::lSetFocus //.AND. hwg_Iswindowvisible(::handle)
      ::lSetFocus := .F.
      hwg_Postmessage( ::handle, EM_SETSEL, 0, 0 )
   ELSEIF msg = WM_SETFOCUS .AND. ::lAllowTabs .AND. hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE
        ::lctrltab := hwg_GetParentForm( Self ):lDisableCtrlTab
        hwg_GetParentForm( Self ):lDisableCtrlTab := ::lAllowTabs
   ELSEIF msg = WM_KILLFOCUS .AND. ::lAllowTabs .AND. hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE
        hwg_GetParentForm( Self ):lDisableCtrlTab := ::lctrltab
   ENDIF
   IF msg == WM_KEYDOWN .AND. ( wParam = VK_DELETE .OR. wParam = VK_BACK )  //46Del
      ::lChanged := .T.
   ENDIF
   IF msg == WM_CHAR
      IF wParam = VK_TAB .AND. hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE
         IF  ( hwg_IsCtrlShift(.T.,.f.) .OR. ! ::lAllowTabs )
            RETURN 0
         ENDIF
      ENDIF
       IF !hwg_IsCtrlShift( .T., .F.)
         ::lChanged := .T.
      ENDIF
   ELSEIF ::bOther != Nil
      nret := Eval( ::bOther, Self, msg, wParam, lParam )
      IF ValType( nret ) != "N" .OR. nret > - 1
         RETURN nret
      ENDIF
   ENDIF
   IF msg == WM_KEYUP
     IF wParam = VK_TAB .AND. hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE
         IF   hwg_IsCtrlShift(.T.,.f.)
            hwg_GetSkip( ::oParent, ::handle, , ;
                      iif( hwg_IsCtrlShift(.f., .t.), -1, 1) )
            RETURN 0
         ENDIF
      ENDIF
   ELSEIF msg == WM_KEYDOWN
      IF wParam = VK_TAB .AND. ( hwg_IsCtrlShift(.T.,.f.) .OR. ! ::lAllowTabs )
         hwg_GetSkip( ::oParent, ::handle, , ;
                      iif( hwg_IsCtrlShift(.f., .t.), -1, 1) )
         RETURN 0
      ELSEIF wParam = VK_TAB .AND. hwg_GetParentForm( Self ):Type >= WND_DLG_RESOURCE
         hwg_Re_inserttext( ::handle, CHR( VK_TAB ) )
          RETURN 0
      ENDIF
      IF wParam == VK_ESCAPE .AND. hwg_GetParentForm( Self ):Handle != ::oParent:handle
         IF hwg_Getparent(::oParent:handle) != Nil
            //hwg_Sendmessage( hwg_Getparent(::oParent:handle),WM_CLOSE,0,0 )
         ENDIF
         RETURN 0
      ENDIF
   ELSEIF msg == WM_MOUSEWHEEL
      nDelta := hwg_Hiword( wParam )
      IF nDelta > 32768
         nDelta -= 65535
      ENDIF
      hwg_Sendmessage( ::handle, EM_SCROLL, IIf( nDelta > 0, SB_LINEUP, SB_LINEDOWN ), 0 )
//      hwg_Sendmessage( ::handle,EM_SCROLL, Iif(nDelta>0,SB_LINEUP,SB_LINEDOWN), 0 )
   ELSEIF msg == WM_DESTROY
      ::END()
   ENDIF

   RETURN - 1

METHOD SetColor( tColor, bColor, lRedraw )  CLASS HRichEdit

   IF tcolor != NIL
      hwg_Re_setdefault( ::handle, tColor ) //, ID_FONT ,, ) // cor e fonte padrao
   ENDIF
   IF bColor != NIL
      hwg_Sendmessage( ::Handle, EM_SETBKGNDCOLOR, 0, bColor )  // cor de fundo
   ENDIF
   ::super:SetColor( tColor, bColor, lRedraw )

   RETURN NIL

METHOD ReadOnly( lreadOnly )

   IF lreadOnly != Nil
      IF ! EMPTY( hwg_Sendmessage( ::handle,  EM_SETREADONLY, IIF( lReadOnly, 1, 0 ), 0 ) )
          ::lReadOnly := lReadOnly
      ENDIF
   ENDIF
   RETURN ::lReadOnly

METHOD UpdatePos( ) CLASS HRichEdit
    LOCAL npos := hwg_Sendmessage( ::handle, EM_GETSEL, 0, 0 )
   LOCAL pos1 := hwg_Loword( npos ) + 1,   pos2 := hwg_Hiword( npos ) + 1

    ::Line := hwg_Sendmessage( ::Handle, EM_LINEFROMCHAR, pos1 - 1, 0 ) + 1
    ::LinesTotal := hwg_Sendmessage( ::handle, EM_GETLINECOUNT, 0, 0 )
    ::SelText := hwg_Re_gettextrange( ::handle, pos1, pos2 )
    ::SelStart := pos1
    ::SelLength := pos2 - pos1
   ::Col := pos1 - hwg_Sendmessage( ::Handle, EM_LINEINDEX, - 1, 0 )

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

    IF !hwg_CheckFocus( Self, .f. )
       RETURN .t.
   ENDIF
   ::title := ::GetText()
   ::oparent:lSuspendMsgsHandling := .t.
   Eval( ::bGetFocus, ::title, Self )
   ::oparent:lSuspendMsgsHandling := .f.
 RETURN .T.


METHOD Valid( ) CLASS HRichEdit

   IF ::bLostFocus != Nil .AND. !hwg_CheckFocus( Self, .T. )
       RETURN .T.
   ENDIF
   ::title := ::GetText()
   ::oparent:lSuspendMsgsHandling := .t.
   Eval( ::bLostFocus, ::title, Self )
   ::oparent:lSuspendMsgsHandling := .f.

  RETURN .T.

METHOD Savefile( cFile )  CLASS HRichEdit

   IF !EMPTY( cFile )
      IF ! EMPTY( hwg_Saverichedit( ::Handle, cFile ) )
          RETURN .T.
      ENDIF
   ENDIF
   RETURN .F.

METHOD OpenFile( cFile )  CLASS HRichEdit

   IF !EMPTY( cFile )
      IF ! EMPTY( hwg_Loadrichedit( ::Handle, cFile ) )
          RETURN .T.
      ENDIF
   ENDIF
   RETURN .F.

METHOD Print( )  CLASS HRichEdit

   IF ::hDCPrinter = Nil
    //  ::hDCPrinter := hwg_Printsetup()
   ENDIF
   IF HWG_STARTDOC( ::hDCPrinter ) <> 0
      IF hwg_Printrtf( ::Handle, ::hDCPrinter ) <> 0
          HWG_ENDDOC( ::hDCPrinter )
      ELSE
         HWG_ABORTDOC( ::hDCPrinter )
      ENDIF
   ENDIF
   RETURN .F.


/*
Function hwg_DefRichProc( hEdit, msg, wParam, lParam )

Local oEdit
   // writelog( "RichProc: " + Str(hEdit,10)+"|"+Str(msg,6)+"|"+Str(wParam,10)+"|"+Str(lParam,10) )
   oEdit := hwg_FindSelf( hEdit )
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

