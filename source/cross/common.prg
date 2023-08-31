/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HPaintCB class
 *
 * Copyright 2023 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
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
