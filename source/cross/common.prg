/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HPaintCB, HPicture classes, common functions
 *
 * Copyright 2023 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hblang.ch"
#include "hbclass.ch"

CLASS HPaintCB INHERIT HObject

   DATA   aCB    INIT {}

   METHOD New()  INLINE Self
   METHOD Set( nId, block, cId )
   METHOD Get( nId )
   
ENDCLASS

METHOD Set( nId, block, cId ) CLASS HPaintCB

   LOCAL i, nLen

   IF Empty( cId ); cId := "_"; ENDIF

   nLen := Len( ::aCB )
   FOR i := 1 TO nLen
      IF ::aCB[i,1] == nId .AND. ::aCB[i,2] == cId
         EXIT
      ENDIF
   NEXT
   IF Empty( block )
      IF i <= nLen
         ADel( ::aCB, i )
         ::aCB := ASize( ::aCB, nLen - 1 )
      ENDIF
   ELSE
      IF i > nLen
         AAdd( ::aCB, { nId, cId, block } )
      ELSE
         ::aCB[i,3] := block
      ENDIF
   ENDIF

   RETURN Nil

METHOD Get( nId ) CLASS HPaintCB

   LOCAL i, nLen, aRes

   IF !Empty( ::aCB )
      nLen := Len( ::aCB )
      FOR i := 1 TO nLen
         IF ::aCB[i,1] == nId
            IF nId < PAINT_LINE_ITEM
               RETURN ::aCB[i,3]
            ELSE
               IF aRes == Nil
                  aRes := { ::aCB[i,3] }
               ELSE
                  AAdd( aRes, ::aCB[i,3] )
               ENDIF
            ENDIF
         ENDIF
      NEXT
   ENDIF

   RETURN aRes

//  ------------------------------

CLASS HPicture INHERIT HObject

   DATA cPicFunc, cPicMask
   DATA lPicComplex    INIT .F.
   DATA cType
   DATA nMaxLength     INIT Nil

   METHOD New( cPicture, vari, nMaxLength )
   METHOD IsEditable( nPos )
   METHOD FirstEditable()
   METHOD LastEditable()
   METHOD KeyRight( nPos )
   METHOD KeyLeft( nPos )
   METHOD Delete( cText, nPos )
   METHOD Input( cChar, nPos )
   METHOD GetApplyKey( cText, nPos, cKey, lFirst, lIns )
   METHOD Transform( vari )
   METHOD UnTransform( cBuffer )

   ENDCLASS

METHOD New( cPicture, vari, nMaxLength ) CLASS HPicture

   LOCAL nAt, i, masklen

   ::cType := Valtype( vari )
   ::cPicFunc := ::cPicMask := ""
   IF cPicture != Nil
      IF Left( cPicture, 1 ) == "@"
         nAt := At( " ", cPicture )
         IF nAt == 0
            ::cPicFunc := Upper( cPicture )
            ::cPicMask := ""
         ELSE
            ::cPicFunc := Upper( SubStr( cPicture, 1, nAt - 1 ) )
            ::cPicMask := SubStr( cPicture, nAt + 1 )
         ENDIF
         IF ::cPicFunc == "@"
            ::cPicFunc := ""
         ENDIF
      ELSE
         ::cPicFunc   := ""
         ::cPicMask   := cPicture
      ENDIF
      IF Empty( ::nMaxLength ) .AND. !Empty( ::cPicMask ) .AND. !( ::cPicFunc == "@R")
         ::nMaxLength := Len( ::cPicMask )
      ENDIF
   ENDIF

   IF Empty( ::cPicMask )
      IF ::cType == "D"
         ::cPicMask := StrTran( Dtoc( CToD( Space(8) ) ), ' ', '9' )
      ELSEIF ::cType == "N"
         vari := Str( vari )
         IF ( nAt := At( ".", vari ) ) > 0
            ::cPicMask := Replicate( '9', nAt - 1 ) + "." + ;
               Replicate( '9', Len( vari ) - nAt )
         ELSE
            ::cPicMask := Replicate( '9', Len( vari ) )
         ENDIF
      ENDIF
   ENDIF

   IF !Empty( ::cPicMask )
      masklen := Len( ::cPicMask )
      FOR i := 1 TO masklen
         IF !( SubStr( ::cPicMask, i, 1 ) $ "!ANX9#" )
            ::lPicComplex := .T.
            EXIT
         ENDIF
      NEXT
   ENDIF

   IF Empty( ::nMaxLength ) .AND. ::cType == "C"
      ::nMaxLength := hwg_Len( vari )
   ENDIF
   IF nMaxLength != Nil
      ::nMaxLength := nMaxLength
   ENDIF

   //  ------------ added by Maurizio la Cecilia
   IF !Empty( ::nMaxLength ) .AND. Len( ::cPicMask ) < ::nMaxLength
      ::cPicMask := PadR( ::cPicMask, ::nMaxLength, "X" )
   ENDIF
   //  ------------- end of added code

   RETURN Self

METHOD IsEditable( nPos ) CLASS HPicture

   LOCAL cChar

   IF Empty( ::cPicMask )
      RETURN .T.
   ENDIF
   IF nPos > Len( ::cPicMask )
      RETURN .F.
   ENDIF

   cChar := SubStr( ::cPicMask, nPos, 1 )

   IF ::cType == "C"
      RETURN cChar $ "!ANX9#"
   ELSEIF ::cType == "N"
      RETURN cChar $ "9#$*"
   ELSEIF ::cType == "D"
      RETURN cChar == "9"
   ELSEIF ::cType == "L"
      RETURN cChar $ "TFYN"
   ENDIF

   RETURN .F.

METHOD FirstEditable() CLASS HPicture

   LOCAL nFor, nMaxLen := Len( ::cPicMask )

   IF ::IsEditable( 1 )
      RETURN 1
   ENDIF

   FOR nFor := 2 TO nMaxLen
      IF ::IsEditable( nFor )
         RETURN nFor
      ENDIF
   NEXT

   RETURN 0

METHOD LastEditable() CLASS HPicture

   LOCAL nFor, nMaxLen := Len( ::cPicMask )

   FOR nFor := nMaxLen TO 1 step - 1
      IF ::IsEditable( nFor )
         RETURN nFor
      ENDIF
   NEXT

   RETURN 0

METHOD KeyRight( nPos ) CLASS HPicture

   LOCAL masklen, newpos

   IF Empty( ::cPicMask )
      RETURN nPos + 1
   ELSE
      masklen := Len( ::cPicMask )
      DO WHILE nPos < masklen
         nPos ++
         IF ::IsEditable( nPos )
            RETURN nPos
         ENDIF
      ENDDO
   ENDIF

   //Added By Sandro Freire

   IF !Empty( ::cPicMask )
      newPos := Len( ::cPicMask )
      IF nPos > newPos //.AND. !Empty( Trim( ::Title ) )
         RETURN newPos
      ENDIF
   ENDIF

   RETURN -1

METHOD KeyLeft( nPos ) CLASS HPicture

   IF ::cPicMask == Nil .OR. Empty( ::cPicMask )
      RETURN nPos - 1
   ELSE
      DO WHILE nPos > 1
         nPos --
         IF ::IsEditable( nPos )
            RETURN nPos
         ENDIF
      ENDDO
   ENDIF

   RETURN -1

METHOD Delete( cText, nPos ) CLASS HPicture

   LOCAL nGetLen := Len( ::cPicMask ), nLen

   FOR nLen := 0 TO nGetLen
      IF !::IsEditable( nPos + nLen )
         EXIT
      ENDIF
   NEXT
   IF nLen == 0
      DO WHILE nPos >= 1
         nPos --
         nLen ++
         IF ::IsEditable( nPos )
            EXIT
         ENDIF
      ENDDO
   ENDIF
   cText := PadR( Left( cText, nPos - 1 ) + ;
      SubStr( cText, nPos + 1, nLen - 1 ) + " " + ;
      SubStr( cText, nPos + nLen ), nGetLen )

   RETURN cText

METHOD Input( cChar, nPos ) CLASS HPicture

   LOCAL cPic

   IF !Empty( ::cPicMask ) .AND. nPos > Len( ::cPicMask )
      RETURN Nil
   ENDIF
   IF ::cType == "N"
      IF cChar == "-"
         IF nPos != 1
            RETURN Nil
         ENDIF
      ELSEIF !( cChar $ "0123456789" )
         RETURN Nil
      ENDIF

   ELSEIF ::cType == "D"

      IF !( cChar $ "0123456789" )
         RETURN Nil
      ENDIF

   ELSEIF ::cType == "L"

      IF !( Upper( cChar ) $ "YNTF" )
         RETURN Nil
      ENDIF

   ENDIF

   IF Len( cChar ) > 1
      IF !Empty( ::cPicMask ) .AND. SubStr( ::cPicMask, nPos, 1 ) $ "N9#"
         cChar := Nil
      ENDIF
   ELSE
      IF !Empty( ::cPicFunc )
         cChar := Transform( cChar, ::cPicFunc )
      ENDIF

      IF !Empty( ::cPicMask )
         cPic  := SubStr( ::cPicMask, nPos, 1 )

         cChar := Transform( cChar, cPic )
         IF cPic == "A"
            IF ! IsAlpha( cChar )
               cChar := Nil
            ENDIF
         ELSEIF cPic == "N"
            IF ! IsAlpha( cChar ) .AND. ! IsDigit( cChar )
               cChar := Nil
            ENDIF
         ELSEIF cPic == "9"
            IF ! IsDigit( cChar ) .AND. cChar != "-"
               cChar := Nil
            ENDIF
         ELSEIF cPic == "#"
            IF ! IsDigit( cChar ) .AND. !( cChar == " " ) .AND. !( cChar $ "+-" )
               cChar := Nil
            ENDIF
         ENDIF
      ENDIF
   ENDIF

   RETURN cChar

METHOD GetApplyKey( cText, nPos, cKey, lFirst, lIns ) CLASS HPicture

   LOCAL nGetLen, nLen, vari, x, newPos
   LOCAL nDecimals, lMinus := .F.

   IF lFirst
      nPos := ::KeyRight( 0 )
   ENDIF

   IF ::cType == "N" .AND. cKey $ ".," .AND. ( nPos := At( ".",::cPicMask ) ) != 0
      IF lFirst
         vari := 0
      ELSE
         vari := Val( LTrim( ::UnTransform( Trim( cText ) ) ) )
         lMinus := Iif( Left( Ltrim(cText),1 ) == "-", .T., .F. )
      ENDIF
      cText := ::Transform( vari )
      IF ( x := ::KeyRight( nPos - 1 ) ) > 0
         nPos := x
      ENDIF
      IF !Empty( ::cPicFunc ) .OR. !Empty( ::cPicMask )
         IF lMinus .AND. vari == 0
            nLen := Len( cText )
            cText := Padl( "-" + Ltrim( cText ), nLen )
         ENDIF
      ENDIF
   ELSE

      IF ::cType == "N" .AND. lFirst
         nGetLen := Len( ::cPicMask )
         IF ( nPos := At( ".", ::cPicMask ) ) == 0
            cText := Space( nGetLen )
         ELSE
            cText := Space( nPos - 1 ) + "." + Space( nGetLen - nPos )
         ENDIF
         nPos := 1
      ENDIF
      cKey := ::Input( cKey, nPos )
      IF cKey != Nil
         IF lIns
            IF ::lPicComplex
               nGetLen := Len( ::cPicMask )
               FOR nLen := 0 TO nGetLen
                  IF !::IsEditable( nPos + nLen )
                     EXIT
                  ENDIF
               NEXT
               cText := hwg_Left( cText, nPos - 1 ) + cKey + ;
                  hwg_SubStr( cText, nPos, nLen - 1 ) + hwg_SubStr( cText, nPos + nLen )
            ELSE
               cText := hwg_Left( cText, nPos - 1 ) + cKey + ;
                  hwg_SubStr( cText, nPos )
            ENDIF

            IF !Empty( ::cPicMask ) .AND. Len( ::cPicMask ) < hwg_Len( cText )
               cText := hwg_Left( cText, nPos - 1 ) + cKey + hwg_SubStr( cText, nPos + 1 )
            ENDIF
         ELSE
            cText := hwg_Left( cText, nPos - 1 ) + cKey + hwg_SubStr( cText, nPos + 1 )
         ENDIF
         IF !Empty( ::nMaxLength )
            nGetLen := Max( Len( ::cPicMask ), ::nMaxLength )
            nLen := hwg_Len( cText )
            IF nGetLen > nLen
               cText += Space( nGetLen-nLen )
            ELSEIF nGetLen < nLen
               cText := hwg_Left( cText, nGetLen )
            ENDIF
         ENDIF
         IF ( x := ::KeyRight( nPos ) ) > 0
            nPos := x
         ENDIF
         //Added By Sandro Freire
         IF ::cType == "N"
            IF !Empty( ::cPicMask )
               nDecimals := Len( SubStr(  ::cPicMask, At( ".", ::cPicMask ), Len( ::cPicMask ) ) )
               IF nDecimals <= 0
                  nDecimals := 3
               ENDIF
               newPos := Len( ::cPicMask ) - nDecimals
               IF "E" $ ::cPicFunc .AND. nPos == newPos
                  cText := ::GetApplyKey( cText, nPos, ",", .F., lIns )
               ENDIF
            ENDIF
         ENDIF
      ENDIF
   ENDIF

   RETURN cText

METHOD Transform( vari ) CLASS HPicture
   RETURN Transform( vari, ::cPicFunc + iif( Empty(::cPicFunc ),""," " ) + ::cPicMask )

METHOD UnTransform( cBuffer ) CLASS HPicture

   LOCAL xValue, cChar, nFor, minus

   IF ::cType == "C"

      IF "R" $ ::cPicFunc
         FOR nFor := 1 TO Len( ::cPicMask )
            cChar := SubStr( ::cPicMask, nFor, 1 )
            IF !cChar $ "ANX9#!"
               cBuffer := SubStr( cBuffer, 1, nFor - 1 ) + Chr( 1 ) + SubStr( cBuffer, nFor + 1 )
            ENDIF
         NEXT
         cBuffer := StrTran( cBuffer, Chr( 1 ), "" )
      ENDIF

      xValue := cBuffer

   ELSEIF ::cType == "N"
      minus := ( Left( LTrim( cBuffer ),1 ) == "-" )
      cBuffer := Space( ::FirstEditable() - 1 ) + SubStr( cBuffer, ::FirstEditable(), ::LastEditable() - ::FirstEditable() + 1 )

      IF "D" $ ::cPicFunc
         FOR nFor := ::FirstEditable() TO ::LastEditable()
            IF !::IsEditable( nFor )
               cBuffer = Left( cBuffer, nFor - 1 ) + Chr( 1 ) + SubStr( cBuffer, nFor + 1 )
            ENDIF
         NEXT
      ELSE
         IF "E" $ ::cPicFunc
            cBuffer := Left( cBuffer, ::FirstEditable() - 1 ) +  ;
               StrTran( SubStr( cBuffer, ::FirstEditable(),      ;
               ::LastEditable() - ::FirstEditable() + 1 ),       ;
               ".", " " ) + SubStr( cBuffer, ::LastEditable() + 1 )
            cBuffer := Left( cBuffer, ::FirstEditable() - 1 ) +  ;
               StrTran( SubStr( cBuffer, ::FirstEditable(),      ;
               ::LastEditable() - ::FirstEditable() + 1 ),  ;
               ",", "." ) + SubStr( cBuffer, ::LastEditable() + 1 )
         ELSE
            cBuffer := Left( cBuffer, ::FirstEditable() - 1 ) + ;
               StrTran( SubStr( cBuffer, ::FirstEditable(),     ;
               ::LastEditable() - ::FirstEditable() + 1 ), ;
               ",", " " ) + SubStr( cBuffer, ::LastEditable() + 1 )
         ENDIF

         FOR nFor := ::FirstEditable() TO ::LastEditable()
            IF !::IsEditable( nFor ) .AND. SubStr( cBuffer, nFor, 1 ) != "."
               cBuffer = Left( cBuffer, nFor - 1 ) + Chr( 1 ) + SubStr( cBuffer, nFor + 1 )
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
         FOR nFor := 1 TO Len( cBuffer )
            IF IsDigit( SubStr( cBuffer, nFor, 1 ) )
               EXIT
            ENDIF
         NEXT
         nFor --
         IF nFor > 0
            cBuffer := Left( cBuffer, nFor - 1 ) + "-" + SubStr( cBuffer, nFor + 1 )
         ELSE
            cBuffer := "-" + cBuffer
         ENDIF
      ENDIF

      xValue := cBuffer

   ELSEIF ::cType == "L"

      cBuffer := Upper( cBuffer )
      xValue := "T" $ cBuffer .OR. "Y" $ cBuffer .OR. hb_langmessage( HB_LANG_ITEM_BASE_TEXT + 1 ) $ cBuffer

   ELSEIF ::cType == "D"

      IF "E" $ ::cPicFunc
         cBuffer := SubStr( cBuffer, 4, 3 ) + SubStr( cBuffer, 1, 3 ) + SubStr( cBuffer, 7 )
      ENDIF
      xValue := cBuffer

   ENDIF

   RETURN xValue

//  ------------------------------

FUNCTION hwg_EndWindow()

   IF HWindow():GetMain() != Nil
      HWindow():aWindows[1]:Close()
   ENDIF

   RETURN Nil

FUNCTION hwg_FindParent( hCtrl, nLevel )

   LOCAL i, oParent, hParent := hwg_Getparent( hCtrl )

   IF !Empty( hParent )
      IF ( i := Ascan( HDialog():aModalDialogs,{ |o|o:handle == hParent } ) ) != 0
         RETURN HDialog():aModalDialogs[i]
      ELSEIF ( oParent := HDialog():FindDialog( hParent ) ) != Nil
         RETURN oParent
      ELSEIF ( oParent := HWindow():FindWindow( hParent ) ) != Nil
         RETURN oParent
      ENDIF
   ENDIF
   IF nLevel == Nil; nLevel := 0; ENDIF
   IF nLevel < 2
      IF ( oParent := hwg_FindParent( hParent,nLevel + 1 ) ) != Nil
         RETURN oParent:FindControl( , hParent )
      ENDIF
   ENDIF

   RETURN Nil

FUNCTION hwg_FindSelf( hCtrl )

   LOCAL oParent := hwg_FindParent( hCtrl )

   IF oParent != Nil
      RETURN oParent:FindControl( , hCtrl )
   ENDIF

   RETURN Nil

FUNCTION hwg_getParentForm( o )

   DO WHILE o:oParent != Nil .AND. !__ObjHasMsg( o, "GETLIST" )
      o := o:oParent
   ENDDO

   RETURN o

FUNCTION hwg_ColorC2N( cColor )

   LOCAL i, res := 0, n := 1, iValue

   IF Left( cColor,1 ) == "#"
      cColor := Substr( cColor,2 )
   ENDIF
   cColor := Trim( cColor )
   FOR i := 1 TO Len( cColor )
      iValue := Asc( SubStr( cColor,i,1 ) )
      IF iValue < 58 .AND. iValue > 47
         iValue -= 48
      ELSEIF iValue >= 65 .AND. iValue <= 70
         iValue -= 55
      ELSEIF iValue >= 97 .AND. iValue <= 102
         iValue -= 87
      ELSE
         RETURN 0
      ENDIF
      iValue *= n
      IF i % 2 == 1
         iValue *= 16
      ELSE
         n *= 256
      ENDIF
      res += iValue
   NEXT

   RETURN res

FUNCTION hwg_ColorN2C( nColor )

   LOCAL s := "", n1, n2, i

   FOR i := 0 to 2
      n1 := hb_BitAnd( hb_BitShift( nColor,-i*8-4 ), 15 )
      n2 := hb_BitAnd( hb_BitShift( nColor,-i*8 ), 15 )
      s += Chr( Iif(n1<10,n1+48,n1+55) ) + Chr( Iif(n2<10,n2+48,n2+55) )
   NEXT

   RETURN s

FUNCTION hwg_ColorN2RGB( nColor, nr, ng, nb )

   nr := nColor % 256
   ng := Int( nColor/256 ) % 256
   nb := Int( nColor/65536 )

   RETURN { nr, ng, nb }

FUNCTION hwg_RefreshAllGets( oDlg )

   AEval( oDlg:GetList, { |o|o:Refresh() } )

   RETURN Nil

FUNCTION hwg_CreateGetList( oDlg )

   LOCAL i, j, aLen1 := Len( oDlg:aControls ), aLen2

   FOR i := 1 TO aLen1
      IF __ObjHasMsg( oDlg:aControls[i], "BSETGET" ) .AND. oDlg:aControls[i]:bSetGet != Nil
         AAdd( oDlg:GetList, oDlg:aControls[i] )
      ELSEIF !Empty( oDlg:aControls[i]:aControls )
         aLen2 := Len( oDlg:aControls[i]:aControls )
         FOR j := 1 TO aLen2
            IF __ObjHasMsg( oDlg:aControls[i]:aControls[j], "BSETGET" ) .AND. oDlg:aControls[i]:aControls[j]:bSetGet != Nil
               AAdd( oDlg:GetList, oDlg:aControls[i]:aControls[j] )
            ENDIF
         NEXT
      ENDIF
   NEXT

   RETURN Nil

FUNCTION hwg_GetSkip( oParent, hCtrl, nSkip, lClipper )

   LOCAL i, aLen

   DO WHILE oParent != Nil .AND. !__ObjHasMsg( oParent, "GETLIST" )
      oParent := oParent:oParent
   ENDDO
   IF oParent == Nil .OR. ( lClipper != Nil .AND. lClipper .AND. !oParent:lClipper )
      RETURN .F.
   ENDIF
   IF hCtrl == Nil
      i := 0
   ENDIF
   IF ( hCtrl == Nil .OR. ( i := Ascan( oParent:Getlist,{ |o|o:handle == hCtrl } ) ) != 0 ) .AND. ;
      ( aLen := Len( oParent:Getlist ) ) > 1
      IF i > 0 .AND. __ObjHasMsg( oParent:Getlist[i], "LFIRST" )
         oParent:Getlist[i]:lFirst := .T.
      ENDIF
      IF nSkip > 0
         DO WHILE ( i := i + nSkip ) <= aLen
            IF !oParent:Getlist[i]:lHide .AND. hwg_Iswindowenabled( oParent:Getlist[i]:Handle ) // Now tab and enter goes trhow the check, combo, etc...
               hwg_Setfocus( oParent:Getlist[i]:handle )
               RETURN .T.
            ENDIF
         ENDDO
      ELSE
         DO WHILE ( i := i + nSkip ) > 0
            IF !oParent:Getlist[i]:lHide .AND. hwg_Iswindowenabled( oParent:Getlist[i]:Handle )
               hwg_Setfocus( oParent:Getlist[i]:handle )
               RETURN .T.
            ENDIF
         ENDDO
      ENDIF
   ENDIF

   RETURN .F.

FUNCTION hwg_SetGetUpdated( o )

   o:lChanged := .T.
   IF ( o := hwg_getParentForm( o ) ) != Nil
      o:lUpdated := .T.
   ENDIF

   RETURN Nil
