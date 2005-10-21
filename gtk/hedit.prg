/*
 *$Id: hedit.prg,v 1.8 2005-10-21 08:50:15 alkresin Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HEdit class 
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "hbclass.ch"
#include "hblang.ch"
#include "hwgui.ch"

#define DLGC_WANTARROWS     1      /* Control wants arrow keys         */
#define DLGC_WANTTAB        2      /* Control wants tab keys           */
#define DLGC_WANTCHARS    128      /* Want WM_CHAR messages            */

#define GDK_BackSpace       0xFF08
#define GDK_Tab             0xFF09
#define GDK_Return          0xFF0D
#define GDK_Escape          0xFF1B
#define GDK_Delete          0xFFFF
#define GDK_Home            0xFF50
#define GDK_Left            0xFF51
#define GDK_Up              0xFF52
#define GDK_Right           0xFF53
#define GDK_Down            0xFF54
#define GDK_End             0xFF57
#define GDK_Insert          0xFF63

#define GDK_Shift_L         0xFFE1
#define GDK_Shift_R         0xFFE2
#define GDK_Control_L       0xFFE3
#define GDK_Control_R       0xFFE4
#define GDK_Alt_L           0xFFE9
#define GDK_Alt_R           0xFFEA

CLASS HEdit INHERIT HControl

   CLASS VAR winclass   INIT "EDIT"
   DATA lMultiLine   INIT .F.
   DATA cType INIT "C"
   DATA bSetGet
   DATA bValid
   DATA bAnyEvent
   DATA cPicFunc, cPicMask
   DATA lPicComplex  INIT .F.
   DATA lFirst       INIT .T.
   DATA lChanged     INIT .F.
   DATA lMaxLength   INIT Nil
   DATA nLastKey     INIT 0

   METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
         oFont,bInit,bSize,bPaint,bGfocus,bLfocus,ctoolt,tcolor,bcolor,cPicture,lNoBorder, lMaxLength )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD SetGet(value) INLINE Eval( ::bSetGet,value,self )
   METHOD Refresh() 
   METHOD SetText(c)
   METHOD GetText() INLINE hwg_Edit_GetText( ::handle )

ENDCLASS

METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  oFont,bInit,bSize,bPaint,bGfocus,bLfocus,ctoolt, ;
                  tcolor,bcolor,cPicture,lNoBorder, lMaxLength, lPassword ) CLASS HEdit
 
   nStyle := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), ;
                WS_TABSTOP+Iif(lNoBorder==Nil.OR.!lNoBorder,WS_BORDER,0)+;
                Iif(lPassword==Nil .or. !lPassword, 0, ES_PASSWORD)  )

   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctoolt,tcolor,bcolor )

   IF vari != Nil
      ::cType   := Valtype( vari )
   ENDIF
   IF bSetGet == Nil
      ::title := vari
   ENDIF
   ::bSetGet := bSetGet

   IF Hwg_BitAnd( nStyle,ES_MULTILINE ) != 0
      ::style := Hwg_BitOr( ::style,ES_WANTRETURN )
      ::lMultiLine := .T.
   ENDIF

   IF !Empty(cPicture) .or. cPicture==Nil .And. lMaxLength !=Nil .or. !Empty(lMaxLength)
      ::lMaxLength:= lMaxLength
   ENDIF
/*   IF ::lMaxLength != Nil .and. !Empty(::lMaxLength) 
      IF !Empty(cPicture) .or. cPicture==Nil
         cPicture:=Replicate("X",::lMaxLength)
      ENDIF
   ENDIF                        ----------------- commented out by Maurizio la Cecilia */
 
   ParsePict( Self, cPicture, vari )
   ::Activate()

   IF bSetGet != Nil
      ::bGetFocus := bGFocus
      ::bLostFocus := bLFocus
      ::bValid := {|o|__Valid(o)}
   ENDIF
   hwg_SetEvent( ::handle,"focus_in_event",WM_SETFOCUS,0,0 )
   hwg_SetEvent( ::handle,"focus_out_event",WM_KILLFOCUS,0,0 )   
   hwg_SetEvent( ::handle,"key_press_event",0,0,0 )

Return Self

METHOD Activate CLASS HEdit

   IF !Empty(::oParent:handle )
      ::handle := CreateEdit( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      SetWindowObject( ::handle,Self )
      ::Init()
   ENDIF
Return Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HEdit
Local oParent := ::oParent, nPos, nctrl, cKeyb

   // WriteLog( "Edit: "+Str(msg,10)+"|"+Str(wParam,10)+"|"+Str(lParam,10) )
   IF ::bAnyEvent != Nil .AND. Eval( ::bAnyEvent,Self,msg,wParam,lParam ) != 0
      Return 0
   ENDIF
   IF ::bSetGet == Nil
      Return 0
   ENDIF

   IF !::lMultiLine
      IF msg == WM_KEYDOWN
         ::nLastKey := wParam
         IF wParam == GDK_BackSpace
            ::lFirst := .F.
            SetGetUpdated( Self )
            IF ::lPicComplex
               DeleteChar( Self,.T. )
               Return 1
            ENDIF
            Return 0
         ELSEIF wParam == GDK_Down     // KeyDown
            IF lParam == 0
               GetSkip( oParent,::handle,1 )
               Return 1
            ENDIF
         ELSEIF wParam == GDK_Up     // KeyUp
            IF lParam == 0
               GetSkip( oParent,::handle,-1 )
               Return 1
            ENDIF
         ELSEIF wParam == GDK_Right     // KeyRight
            IF lParam == 0
               ::lFirst := .F.
               Return KeyRight( Self )
            ENDIF
         ELSEIF wParam == GDK_Left     // KeyLeft
               ::lFirst := .F.
               Return KeyLeft( Self )
         ELSEIF wParam == GDK_Home     // Home
               ::lFirst := .F.
               hwg_edit_SetPos( ::handle, 0 )
               Return 1
         ELSEIF wParam == GDK_End     // End
               ::lFirst := .F.
               IF ::cType == "C"
                  nPos := Len( Trim( ::title ) )
		  hwg_edit_SetPos( ::handle, nPos )
                  Return 1
               ENDIF
         ELSEIF wParam == GDK_Insert     // Insert
            IF lParam == 0
               Set( _SET_INSERT, ! Set( _SET_INSERT ) )
            ENDIF
         ELSEIF wParam == GDK_Delete     // Del
            ::lFirst := .F.
            SetGetUpdated( Self )
            IF ::lPicComplex
               DeleteChar( Self,.F. )
               Return 1
            ENDIF
         ELSEIF wParam == GDK_Tab     // Tab
            IF CheckBit( lParam,1 )
               GetSkip( oParent,::handle,-1 )
            ELSE
               GetSkip( oParent,::handle,1 )
            ENDIF
            Return 1
         ELSEIF wParam == GDK_Return  // Enter
            IF !GetSkip( oParent,::handle,1,.T. ) .AND. ::bValid != Nil
	       __Valid( Self )
	    ENDIF
            Return 1
         ELSEIF wParam >= 32 .AND. wParam < 65000
            Return GetApplyKey( Self,Chr(wParam) )
	 ELSE
	    Return 1    
         ENDIF
      ENDIF

   ELSE

      IF msg == WM_MOUSEWHEEL
         nPos := HiWord( wParam )
         nPos := Iif( nPos > 32768, nPos - 65535, nPos )
         // SendMessage( ::handle,EM_SCROLL, Iif(nPos>0,SB_LINEUP,SB_LINEDOWN), 0 )
         // SendMessage( ::handle,EM_SCROLL, Iif(nPos>0,SB_LINEUP,SB_LINEDOWN), 0 )
      ENDIF

   ENDIF

   IF msg == WM_KEYUP  
      IF wParam != 16 .AND. wParam != 17 .AND. wParam != 18
         DO WHILE oParent != Nil .AND. !__ObjHasMsg( oParent,"GETLIST" )
            oParent := oParent:oParent
         ENDDO
         IF oParent != Nil .AND. !Empty( oParent:KeyList )
	    /*
            cKeyb := GetKeyboardState()
            nctrl := Iif( Asc(Substr(cKeyb,VK_CONTROL+1,1))>=128,FCONTROL,Iif( Asc(Substr(cKeyb,VK_SHIFT+1,1))>=128,FSHIFT,0 ) )
            IF ( nPos := Ascan( oParent:KeyList,{|a|a[1]==nctrl.AND.a[2]==wParam} ) ) > 0
               Eval( oParent:KeyList[ nPos,3 ] )
            ENDIF
	    */
         ENDIF
      ENDIF
   ELSEIF msg == WM_SETFOCUS
      IF ::bSetGet == Nil
         Eval( ::bGetFocus, hwg_Edit_GetText( ::handle ), Self )
      ELSE
         __When( Self )
      ENDIF
   ELSEIF msg == WM_KILLFOCUS
      IF ::bSetGet == Nil
         Eval( ::bLostFocus, hwg_Edit_GetText( ::handle ), Self )
      ELSE
         __Valid( Self )
      ENDIF
   ELSEIF msg == WM_DESTROY
      ::End()
   ENDIF
 
Return 0

METHOD Init()  CLASS HEdit

   IF !::lInit
      Super:Init()
      ::nHolder := 1
      ::Refresh()
   ENDIF

Return Nil

METHOD Refresh()  CLASS HEdit
Local vari

   IF ::bSetGet != Nil
      vari := Eval( ::bSetGet,,self )

      IF !Empty( ::cPicFunc ) .OR. !Empty( ::cPicMask )
         vari := Transform( vari, ::cPicFunc + Iif(Empty(::cPicFunc),""," ") + ::cPicMask )
      ELSE
         vari := Iif(::cType=="D",Dtoc(vari),Iif(::cType=="N",Str(vari),Iif(::cType=="C",vari,"")))
      ENDIF
      ::title := vari
      hwg_Edit_SetText( ::handle,vari )
   ELSE
      hwg_Edit_SetText( ::handle,::title )
   ENDIF

Return Nil

METHOD SetText( c ) CLASS HEdit

  IF c != Nil
     if valtype(c)="O"
        //in run time return object
        return nil
     endif
     IF !Empty( ::cPicFunc ) .OR. !Empty( ::cPicMask )
        ::title := Transform( c, ::cPicFunc + Iif(Empty(::cPicFunc),""," ") + ::cPicMask )
     ELSE
        ::title := c
     ENDIF
     hwg_Edit_SetText( ::handle,::title )
     IF ::bSetGet != Nil
       Eval( ::bSetGet, c, self )
     ENDIF
  ENDIF

RETURN NIL

Static Function ParsePict( oEdit,cPicture,vari )
Local nAt, i, masklen, cChar

   IF oEdit:bSetGet == Nil
      Return Nil
   ENDIF
   oEdit:cPicFunc := oEdit:cPicMask := ""
   IF cPicture != Nil
      IF Left( cPicture, 1 ) == "@"
         nAt := At( " ", cPicture )
         IF nAt == 0
            oEdit:cPicFunc := Upper( cPicture )
            oEdit:cPicMask := ""
         ELSE
            oEdit:cPicFunc := Upper( SubStr( cPicture, 1, nAt - 1 ) )
            oEdit:cPicMask := SubStr( cPicture, nAt + 1 )
         ENDIF
         IF oEdit:cPicFunc == "@"
            oEdit:cPicFunc := ""
         ENDIF
      ELSE
         oEdit:cPicFunc   := ""
         oEdit:cPicMask   := cPicture
      ENDIF
   ENDIF

   IF Empty( oEdit:cPicMask ) 
      IF oEdit:cType == "D"
         oEdit:cPicMask := StrTran( Dtoc( Ctod( Space(8) ) ),' ','9' )
      ELSEIF oEdit:cType == "N"
         vari := Str( vari )
         IF ( nAt := At( ".", vari ) ) > 0
            oEdit:cPicMask := Replicate( '9', nAt - 1 ) + "." + ;
                  Replicate( '9', Len( vari ) - nAt )
         ELSE
            oEdit:cPicMask := Replicate( '9', Len( vari ) )
         ENDIF
      ENDIF
   ENDIF

   IF !Empty( oEdit:cPicMask )
      masklen := Len( oEdit:cPicMask )
      FOR i := 1 TO masklen
         cChar := SubStr( oEdit:cPicMask, i, 1 )
         IF !cChar $ "!ANX9#"
            oEdit:lPicComplex := .T.
            EXIT
         ENDIF
      NEXT
   ENDIF

//                                         ------------ added by Maurizio la Cecilia

   IF oEdit:lMaxLength != Nil .and. !Empty( oEdit:lMaxLength ) .and. Len( oEdit:cPicMask ) < oEdit:lMaxLength
      oEdit:cPicMask := PadR( oEdit:cPicMask, oEdit:lMaxLength, "X" )
   ENDIF

//                                         ------------- end of added code

Return Nil

Static Function IsEditable( oEdit,nPos )
Local cChar

   IF Empty( oEdit:cPicMask )
      Return .T.
   ENDIF
   IF nPos > Len( oEdit:cPicMask )
      Return .F.
   ENDIF

   cChar := SubStr( oEdit:cPicMask, nPos, 1 )

   IF oEdit:cType == "C"
      return cChar $ "!ANX9#"
   ELSEIF oEdit:cType == "N"
      Return cChar $ "9#$*"
   ELSEIF oEdit:cType == "D"
      Return cChar == "9"
   ELSEIF oEdit:cType == "L"
      Return cChar $ "TFYN"
   ENDIF

Return .F.

Static Function KeyRight( oEdit,nPos )
Local i, masklen, newpos, vari

   IF oEdit == Nil
      Return 0
   ENDIF
   IF nPos == Nil
      nPos := hwg_edit_Getpos( oEdit:handle ) + 1
   ENDIF
   IF oEdit:cPicMask == Nil .OR. Empty( oEdit:cPicMask )
      hwg_edit_Setpos( oEdit:handle, nPos )
   ELSE
      masklen := Len( oEdit:cPicMask ) 
      DO WHILE nPos <= masklen
         IF IsEditable( oEdit,++nPos )
            // writelog( "KeyRight-2 "+str(nPos) )
            hwg_edit_Setpos( oEdit:handle, nPos-1 )
            EXIT
         ENDIF
       ENDDO
   ENDIF

   //Added By Sandro Freire

   IF !Empty( oEdit:cPicMask )
        newPos:=Len(oEdit:cPicMask)
        //writelog( "KeyRight-2 "+str(nPos) + " " +str(newPos) )
        IF nPos>newPos .and. !empty(TRIM(oEdit:Title))
            hwg_edit_Setpos( oEdit:handle, newPos )
        ENDIF
   ENDIF

Return 1

Static Function KeyLeft( oEdit,nPos )
Local i
   IF oEdit == Nil
      Return 0
   ENDIF
   IF nPos == Nil
      nPos := hwg_edit_Getpos( oEdit:handle ) + 1
   ENDIF
   IF oEdit:cPicMask == Nil .OR. Empty( oEdit:cPicMask )
      hwg_edit_Setpos( oEdit:handle, nPos-2 )
   ELSE
      DO WHILE nPos >= 1
         IF IsEditable( oEdit,--nPos )
            hwg_edit_Setpos( oEdit:handle, nPos-1 )
            EXIT
         ENDIF
      ENDDO
   ENDIF
Return 1

Static Function DeleteChar( oEdit,lBack )
Local nPos := hwg_edit_Getpos( oEdit:handle ) + Iif( !lBack,1,0 )
Local nGetLen := Len( oEdit:cPicMask ), nLen

   FOR nLen := 0 TO nGetLen
      IF !IsEditable( oEdit,nPos+nLen )
         Exit
      ENDIF
   NEXT
   IF nLen == 0
      DO WHILE nPos >= 1
         nPos --
         nLen ++
         IF IsEditable( oEdit,nPos )
            EXIT
         ENDIF
      ENDDO
   ENDIF
   IF nPos > 0
      oEdit:title := PadR( Left( oEdit:title, nPos-1 ) + ;
                  SubStr( oEdit:title, nPos+1, nLen-1 ) + " " + ;
                  SubStr( oEdit:title, nPos+nLen ), nGetLen )
      hwg_edit_Settext( oEdit:handle, oEdit:title )
      hwg_edit_Getpos( oEdit:handle, nPos-1 )
   ENDIF
   
Return Nil

Static Function Input( oEdit,cChar,nPos )
Local cPic

   IF !Empty( oEdit:cPicMask ) .AND. nPos > Len( oEdit:cPicMask )
      Return Nil
   ENDIF
   IF oEdit:cType == "N"
      IF cChar == "-"
         IF nPos != 1
            Return Nil
         ENDIF
         // ::minus := .t.
      ELSEIF !( cChar $ "0123456789" )
         Return Nil
      ENDIF

   ELSEIF oEdit:cType == "D"

      IF !( cChar $ "0123456789" )
         Return Nil
      ENDIF

   ELSEIF oEdit:cType == "L"

      IF !( Upper( cChar ) $ "YNTF" )
         Return Nil
      ENDIF

   ENDIF

   IF !Empty( oEdit:cPicFunc )
      cChar := Transform( cChar, oEdit:cPicFunc )
   ENDIF

   IF !Empty( oEdit:cPicMask )
      cPic  := Substr( oEdit:cPicMask, nPos, 1 )

      cChar := Transform( cChar, cPic )
      IF cPic == "A"
         if ! IsAlpha( cChar )
            cChar := Nil
         endif
      ELSEIF cPic == "N"
         IF ! IsAlpha( cChar ) .and. ! IsDigit( cChar )
            cChar := Nil
         ENDIF
      ELSEIF cPic == "9"
         IF ! IsDigit( cChar ) .and. cChar != "-"
            cChar := Nil
         ENDIF
      ELSEIF cPic == "#"
         IF ! IsDigit( cChar ) .and. !( cChar == " " ) .and. !( cChar $ "+-" )
            cChar := Nil
         ENDIF
      ENDIF
   ENDIF

Return cChar

Static Function GetApplyKey( oEdit,cKey )
Local nPos, nGetLen, nLen, vari, i, x, newPos

   x := hwg_edit_Getpos( oEdit:handle )

   // writelog( "GetApplyKey "+str(asc(ckey)) )
   oEdit:title := hwg_edit_Gettext( oEdit:handle )
   IF oEdit:cType == "N" .and. cKey $ ".," .AND. ;
                     ( nPos := At( ".",oEdit:cPicMask ) ) != 0
      IF oEdit:lFirst
         vari := 0
      ELSE
         vari := Trim( oEdit:title )
         FOR i := 2 TO Len( vari )
            IF !IsDigit( Substr( vari,i,1 ) )
               vari := Left( vari,i-1 ) + Substr( vari,i+1 )
            ENDIF
         NEXT
         vari := Val( vari )
      ENDIF
      IF !Empty( oEdit:cPicFunc ) .OR. !Empty( oEdit:cPicMask )
         oEdit:title := Transform( vari, oEdit:cPicFunc + Iif(Empty(oEdit:cPicFunc),""," ") + oEdit:cPicMask )
      ENDIF
      hwg_edit_Settext( oEdit:handle, oEdit:title )
      KeyRight( oEdit,nPos-1 )
   ELSE

      IF oEdit:cType == "N" .AND. oEdit:lFirst
         nGetLen := Len( oEdit:cPicMask )
         IF ( nPos := At( ".",oEdit:cPicMask ) ) == 0
            oEdit:title := Space( nGetLen )
         ELSE
            oEdit:title := Space( nPos-1 ) + "." + Space( nGetLen-nPos )
         ENDIF
         nPos := 1
      ELSE
         nPos := hwg_edit_Getpos( oEdit:handle ) + 1
      ENDIF
      cKey := Input( oEdit,cKey,nPos )
      IF cKey != Nil
         SetGetUpdated( oEdit )         
         IF Set( _SET_INSERT ) // .or. HiWord(x) != LoWord(x)
            IF oEdit:lPicComplex
               nGetLen := Len( oEdit:cPicMask )
               FOR nLen := 0 TO nGetLen
                  IF !IsEditable( oEdit,nPos+nLen )
                     Exit
                  ENDIF
               NEXT
               oEdit:title := Left( oEdit:title,nPos-1 ) + cKey + ;
                  Substr( oEdit:title,nPos,nLen-1 ) + Substr( oEdit:title,nPos+nLen )
            ELSE
               oEdit:title := Left( oEdit:title,nPos-1 ) + cKey + ;
                  Substr( oEdit:title,nPos )
            ENDIF

            IF !Empty( oEdit:cPicMask ) .AND. Len( oEdit:cPicMask ) < Len( oEdit:title )
               oEdit:title := Left( oEdit:title,nPos-1 ) + cKey + SubStr( oEdit:title,nPos+1 )
            ENDIF
         ELSE
            oEdit:title := Left( oEdit:title,nPos-1 ) + cKey + SubStr( oEdit:title,nPos+1 )
         ENDIF
         hwg_edit_Settext( oEdit:handle, oEdit:title )
         // writelog( "GetApplyKey "+oEdit:title+str(nPos-1) )
         KeyRight( oEdit,nPos )
         //Added By Sandro Freire
         IF oEdit:cType == "N"
            IF !Empty(oEdit:cPicMask) 
                newPos:=Len(oEdit:cPicMask)-3
                IF "E" $ oEdit:cPicFunc .AND. nPos==newPos 
                    GetApplyKey( oEdit, "," )
                ENDIF
            ENDIF
         ENDIF

      ENDIF
   ENDIF
   oEdit:lFirst := .F.

Return 1

Static Function __When( oCtrl )
Local res

   oCtrl:Refresh()
   oCtrl:lFirst := .T.
   IF oCtrl:bGetFocus != Nil 
      res := Eval( oCtrl:bGetFocus, oCtrl:title, oCtrl )
      IF !res
         GetSkip( oCtrl:oParent,oCtrl:handle,1 )
      ENDIF
      Return res
   ENDIF

Return .T.

Static Function __valid( oCtrl )
Local vari, oDlg

    IF oCtrl:bSetGet != Nil
      IF ( oDlg := ParentGetDialog( oCtrl ) ) == Nil .OR. oDlg:nLastKey != 27
         vari := UnTransform( oCtrl,hwg_Edit_GetText( oCtrl:handle ) )
         oCtrl:title := vari
         IF oCtrl:cType == "D"
            IF IsBadDate( vari )
               SetFocus( oCtrl:handle )
	       hwg_edit_SetPos( oCtrl:handle,0 )
               Return .F.
            ENDIF
            vari := Ctod( vari )
         ELSEIF oCtrl:cType == "N"
            vari := Val( Ltrim( vari ) )
            oCtrl:title := Transform( vari, oCtrl:cPicFunc + Iif(Empty(oCtrl:cPicFunc),""," ") + oCtrl:cPicMask )
            hwg_edit_Settext( oCtrl:handle, oCtrl:title )
         ENDIF
         Eval( oCtrl:bSetGet, vari, oCtrl )

         IF oDlg != Nil
            oDlg:nLastKey := 27
         ENDIF
         IF oCtrl:bLostFocus != Nil .AND. !Eval( oCtrl:bLostFocus, vari, oCtrl )
            SetFocus( oCtrl:handle )
	    hwg_edit_SetPos( oCtrl:handle,0 )
            IF oDlg != Nil
               oDlg:nLastKey := 0
            ENDIF
            Return .F.
         ENDIF
         IF oDlg != Nil
            oDlg:nLastKey := 0
         ENDIF
      ENDIF
   ENDIF

Return .T.

Static function Untransform( oEdit,cBuffer )
Local xValue, cChar, nFor, minus

   IF oEdit:cType == "C"

      IF "R" $ oEdit:cPicFunc
         FOR nFor := 1 to Len( oEdit:cPicMask )
            cChar := SubStr( oEdit:cPicMask, nFor, 1 )
            IF !cChar $ "ANX9#!"
               cBuffer := SubStr( cBuffer, 1, nFor - 1 ) + Chr( 1 ) + SubStr( cBuffer, nFor + 1 )
            ENDIF
         NEXT
         cBuffer := StrTran( cBuffer, Chr( 1 ), "" )
      endif

      xValue := cBuffer

   ELSEIF oEdit:cType == "N"
      minus := ( Left( Ltrim( cBuffer ),1 ) == "-" )
      cBuffer := Space( FirstEditable(oEdit) - 1 ) + SubStr( cBuffer, FirstEditable(oEdit), LastEditable(oEdit) - FirstEditable(oEdit) + 1 )

      IF "D" $ oEdit:cPicFunc
         FOR nFor := FirstEditable( oEdit ) to LastEditable( oEdit )
            IF !IsEditable( oEdit,nFor )
               cBuffer = Left( cBuffer, nFor-1 ) + Chr( 1 ) + SubStr( cBuffer, nFor+1 )
            ENDIF
         NEXT
      ELSE
         IF "E" $ oEdit:cPicFunc
            cBuffer := Left( cBuffer, FirstEditable(oEdit) - 1 ) +           ;
                        StrTran( SubStr( cBuffer, FirstEditable(oEdit),      ;
                           LastEditable(oEdit) - FirstEditable(oEdit) + 1 ), ;
                           ".", " " ) + SubStr( cBuffer, LastEditable(oEdit) + 1 )
            cBuffer := Left( cBuffer, FirstEditable(oEdit) - 1 ) +           ;
                        StrTran( SubStr( cBuffer, FirstEditable(oEdit),      ;
                           LastEditable(oEdit) - FirstEditable(oEdit) + 1 ), ;
                           ",", "." ) + SubStr( cBuffer, LastEditable(oEdit) + 1 )
         ELSE
            cBuffer := Left( cBuffer, FirstEditable(oEdit) - 1 ) +        ;
                        StrTran( SubStr( cBuffer, FirstEditable(oEdit),   ;
                        LastEditable(oEdit) - FirstEditable(oEdit) + 1 ), ;
                         ",", " " ) + SubStr( cBuffer, LastEditable(oEdit) + 1 )
         ENDIF

         FOR nFor := FirstEditable(oEdit) to LastEditable(oEdit)
            IF !IsEditable( oEdit,nFor ) .and. SubStr( cBuffer, nFor, 1 ) != "."
               cBuffer = Left( cBuffer, nFor-1 ) + Chr( 1 ) + SubStr( cBuffer, nFor+1 )
            ENDIF
         NEXT
      ENDIF

      cBuffer := StrTran( cBuffer, Chr( 1 ), "" )

      cBuffer := StrTran( cBuffer, "$", " " )
      cBuffer := StrTran( cBuffer, "*", " " )
      cBuffer := StrTran( cBuffer, "-", " " )
      cBuffer := StrTran( cBuffer, "(", " " )
      cBuffer := StrTran( cBuffer, ")", " " )

      cBuffer := PadL( StrTran( cBuffer, " ", "" ), Len( cBuffer ) )

      IF minus
         FOR nFor := 1 to Len( cBuffer )
            IF IsDigit( SubStr( cBuffer, nFor, 1 ) )
               exit
            ENDIF
         NEXT
         nFor--
         IF nFor > 0
            cBuffer := Left( cBuffer, nFor-1 ) + "-" + SubStr( cBuffer, nFor+1 )
         ELSE
            cBuffer := "-" + cBuffer
         ENDIF
      ENDIF

      xValue := cBuffer

   ELSEIF oEdit:cType == "L"

      cBuffer := Upper( cBuffer )
      xValue := "T" $ cBuffer .or. "Y" $ cBuffer .or. hb_langmessage( HB_LANG_ITEM_BASE_TEXT + 1 ) $ cBuffer

   ELSEIF oEdit:cType == "D"

      IF "E" $ oEdit:cPicFunc
         cBuffer := SubStr( cBuffer, 4, 3 ) + SubStr( cBuffer, 1, 3 ) + SubStr( cBuffer, 7 )
      ENDIF
      xValue := cBuffer

   ENDIF

Return xValue

Static Function FirstEditable( oEdit )
Local nFor, nMaxLen := Len( oEdit:cPicMask )

   IF IsEditable( oEdit,1 )
      Return 1
   ENDIF

   FOR nFor := 2 to nMaxLen
      IF IsEditable( oEdit,nFor )
         Return nFor
      ENDIF
   NEXT

Return 0

Static Function  LastEditable( oEdit )
Local nFor, nMaxLen := Len( oEdit:cPicMask )

   FOR nFor := nMaxLen to 1 step -1
      IF IsEditable( oEdit,nFor )
         Return nFor
      ENDIF
   NEXT

Return 0

Static Function IsBadDate( cBuffer )
Local i, nLen

   IF !Empty( Ctod( cBuffer ) )
      Return .F.
   ENDIF
   nLen := len( cBuffer )
   FOR i := 1 to nLen
      If IsDigit( Substr( cBuffer,i,1 ) )
         Return .T.
      ENDIF
   NEXT
Return .F.

Function CreateGetList( oDlg )
Local i, j, aLen1 := Len( oDlg:aControls ), aLen2

   FOR i := 1 TO aLen1
      IF __ObjHasMsg( oDlg:aControls[i],"BSETGET" ) .AND. oDlg:aControls[i]:bSetGet != Nil
         Aadd( oDlg:GetList,oDlg:aControls[i] )
      ELSEIF !Empty(oDlg:aControls[i]:aControls)
         aLen2 := Len(oDlg:aControls[i]:aControls)
         FOR j := 1 TO aLen2
            IF __ObjHasMsg( oDlg:aControls[i]:aControls[j],"BSETGET" ) .AND. oDlg:aControls[i]:aControls[j]:bSetGet != Nil
               Aadd( oDlg:GetList,oDlg:aControls[i]:aControls[j] )
            ENDIF
         NEXT
      ENDIF
   NEXT
Return Nil

Function GetSkip( oParent,hCtrl,nSkip,lClipper )
Local i, aLen

   DO WHILE oParent != Nil .AND. !__ObjHasMsg( oParent,"GETLIST" )
      oParent := oParent:oParent
   ENDDO
   IF oParent == Nil .OR. ( lClipper != Nil .AND. lClipper .AND. !oParent:lClipper )
      Return .F.
   ENDIF
   IF hCtrl == Nil
      i := 0
   ENDIF
   IF hCtrl == Nil .OR. ( i := Ascan( oParent:Getlist,{|o|o:handle==hCtrl} ) ) != 0
      IF ( aLen := Len( oParent:Getlist ) ) > 1
         IF nSkip > 0
            DO WHILE ( i := i+nSkip ) <= aLen
               IF !oParent:Getlist[i]:lHide .AND. IsWindowEnabled( oParent:Getlist[i]:Handle ) // Now tab and enter goes trhow the check, combo, etc...
                  SetFocus( oParent:Getlist[i]:handle )
                  IF oParent:Getlist[i]:winclass == "EDIT"
       	         hwg_edit_SetPos( oParent:Getlist[i]:handle,0 )
                  ENDIF
                  Return .T.
               ENDIF
            ENDDO
         ELSE
            DO WHILE ( i := i+nSkip ) > 0
               IF !oParent:Getlist[i]:lHide .AND. IsWindowEnabled( oParent:Getlist[i]:Handle )
                  SetFocus( oParent:Getlist[i]:handle )
                  IF oParent:Getlist[i]:winclass == "EDIT"
   	               hwg_edit_SetPos( oParent:Getlist[i]:handle,0 )
                  ENDIF
                  Return .T.
               ENDIF
            ENDDO
         ENDIF
      ENDIF
   ENDIF

Return .F.

Function SetGetUpdated( o )

   o:lChanged := .T.
   IF ( o := ParentGetDialog( o ) ) != Nil
      o:lUpdated := .T.
   ENDIF

Return Nil

Function ParentGetDialog( o )
   DO WHILE .T.
      o := o:oParent
      IF o == Nil
         EXIT
      ELSE
         IF __ObjHasMsg( o,"GETLIST" )
            EXIT
         ENDIF
      ENDIF
   ENDDO
Return o

