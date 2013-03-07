/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Main prg level functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "guilib.ch"
#include "common.ch"

#ifdef __XHARBOUR__
   #xtranslate hb_processOpen([<x,...>])   => hb_openProcess(<x>)
   #xtranslate hb_NumToHex([<n,...>])      => NumToHex(<n>)
#endif

STATIC _winwait

FUNCTION hwg_InitObjects( oWnd )

   LOCAL i, pArray := oWnd:aObjects
   LOCAL LoadArray := HObject():aObjects

   IF !EMPTY( LoadArray )
      FOR i := 1 TO Len( LoadArray )
         IF ! EMPTY( oWnd:Handle )
            IF __ObjHasMsg( LoadArray[ i ],"INIT")
               LoadArray[ i ]:Init( oWnd )
               LoadArray[ i ]:lInit := .T.
            ENDIF
         ENDIF
      NEXT
   ENDIF
   IF pArray != Nil
      FOR i := 1 TO Len( pArray )
         IF __ObjHasMsg( pArray[ i ], "INIT" ) .AND. hwg_Selffocus( oWnd:Handle, pArray[ i ]:oParent:Handle )
            pArray[ i ]:Init( oWnd )
            pArray[ i ]:lInit := .T.
         ENDIF
      NEXT
   ENDIF
   HObject():aObjects := {}
   RETURN .T.

FUNCTION hwg_InitControls( oWnd, lNoActivate )

   LOCAL i, pArray := oWnd:aControls, lInit

   lNoActivate := IIf( lNoActivate == Nil, .F., lNoActivate )

   IF pArray != Nil
      FOR i := 1 TO Len( pArray )
         // writelog( "InitControl1"+str(pArray[i]:handle)+"/"+pArray[i]:classname+" "+str(pArray[i]:nWidth)+"/"+str(pArray[i]:nHeight) )
         IF Empty( pArray[ i ]:handle ) .AND. ! lNoActivate
            lInit := pArray[ i ]:lInit
            pArray[ i ]:lInit := .T.
            pArray[ i ]:Activate()
            pArray[ i ]:lInit := lInit
         ELSEIF  ! lNoActivate
            pArray[ i ]:lInit := .T.
         ENDIF
         IF IIF( ValType( pArray[ i ]:handle ) == "P", hwg_Ptrtoulong( pArray[ i ]:handle ), pArray[ i ]:handle ) <= 0
            pArray[ i ]:handle := hwg_Getdlgitem( oWnd:handle, pArray[ i ]:id )

            // writelog( "InitControl2"+str(pArray[i]:handle)+"/"+pArray[i]:classname )
         ENDIF
         IF ! Empty( pArray[ i ]:aControls )
            hwg_InitControls( pArray[ i ] )
         ENDIF
         pArray[ i ]:Init()
          // nando required to classes that inherit the class of patterns hwgui
         IF ! pArray[i]:lInit
            pArray[i]:Super:Init()
         ENDIF
      NEXT
   ENDIF

   RETURN .T.

FUNCTION hwg_FindParent( hCtrl, nLevel )

   LOCAL i, oParent, hParent := hwg_Getparent( hCtrl )
   IF hParent > 0
      IF ( i := AScan( HDialog():aModalDialogs, { | o | o:handle == hParent } ) ) != 0
         RETURN HDialog():aModalDialogs[ i ]
      ELSEIF ( oParent := HDialog():FindDialog( hParent ) ) != Nil
         RETURN oParent
      ELSEIF ( oParent := HWindow():FindWindow( hParent ) ) != Nil
         RETURN oParent
      ENDIF
   ENDIF
   IF nLevel == Nil ; nLevel := 0 ; ENDIF
   IF nLevel < 2
      IF ( oParent := hwg_FindParent( hParent, nLevel + 1 ) ) != Nil
         RETURN oParent:FindControl( , hParent )
      ENDIF
   ENDIF
   RETURN Nil

FUNCTION hwg_FindSelf( hCtrl )

   LOCAL oParent
   oParent := hwg_FindParent( hCtrl )
   IF oParent == Nil
      oParent := hwg_Getancestor( hCtrl, GA_PARENT )
   ENDIF
   IF oParent != Nil  .AND. VALTYPE( oParent ) != "N"
      RETURN oParent:FindControl( , hCtrl )
   ENDIF
   RETURN Nil

FUNCTION hwg_WriteStatus( oWnd, nPart, cText, lRedraw )

   LOCAL aControls, i
   aControls := oWnd:aControls
   IF ( i := AScan( aControls, { | o | o:ClassName() == "HSTATUS" } ) ) > 0
      hwg_Writestatuswindow( aControls[ i ]:handle, nPart - 1, cText )
      IF lRedraw != Nil .AND. lRedraw
         hwg_Redrawwindow( aControls[ i ]:handle, RDW_ERASE + RDW_INVALIDATE )
      ENDIF
   ENDIF
   RETURN Nil

FUNCTION hwg_ReadStatus( oWnd, nPart )

   LOCAL aControls, i, ntxtLen, cText := ""
   aControls := oWnd:aControls
   IF ( i := AScan( aControls, { | o | o:ClassName() == "HSTATUS" } ) ) > 0
      ntxtLen := hwg_Sendmessage( aControls[ i ]:handle, SB_GETTEXTLENGTH, nPart - 1, 0 )
      cText := Replicate( Chr( 0 ), ntxtLen )
      hwg_Sendmessage( aControls[ i ]:handle, SB_GETTEXT, nPart - 1, @cText )
   ENDIF
   RETURN cText

FUNCTION hwg_VColor( cColor )

   LOCAL i, res := 0, n := 1, iValue
   cColor := Trim( cColor )
   FOR i := 1 TO Len( cColor )
      iValue := Asc( SubStr( cColor, Len( cColor ) - i + 1, 1 ) )
      IF iValue < 58 .and. iValue > 47
         iValue -= 48
      ELSEIF iValue >= 65 .and. iValue <= 70
         iValue -= 55
      ELSEIF iValue >= 97 .and. iValue <= 102
         iValue -= 87
      ELSE
         RETURN 0
      ENDIF
      res += iValue * n
      n *= 16
   NEXT
   RETURN res

FUNCTION hwg_MsgGet( cTitle, cText, nStyle, x, y, nDlgStyle, cResIni )

   LOCAL oModDlg, oFont := HFont():Add( "MS Sans Serif", 0, - 13 )
   LOCAL cRes := IIf( cResIni != Nil, Trim( cResIni ), "" )
   nStyle := IIf( nStyle == Nil, 0, nStyle )
   x := IIf( x == Nil, 210, x )
   y := IIf( y == Nil, 10, y )
   nDlgStyle := IIf( nDlgStyle == Nil, 0, nDlgStyle )

   INIT DIALOG oModDlg TITLE cTitle At x, y SIZE 300, 140 ;
        FONT oFont CLIPPER ;
        STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX + nDlgStyle

   @ 20, 10 SAY cText SIZE 260, 22
   @ 20, 35 GET cRes  SIZE 260, 26 STYLE WS_TABSTOP + ES_AUTOHSCROLL + nStyle
   oModDlg:aControls[ 2 ]:Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS
   @ 20, 95 BUTTON "Ok" ID IDOK SIZE 100, 32
   oModDlg:aControls[ 3 ]:Anchor := ANCHOR_BOTTOMABS
   @ 180, 95 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32
   oModDlg:aControls[ 4 ]:Anchor := ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   ACTIVATE DIALOG oModDlg ON ACTIVATE { || IIF( ! EMPTY( cRes ), hwg_Keyb_event( VK_END ), .T. ) }

   oFont:Release()
   IF oModDlg:lResult
      RETURN Trim( cRes )
   ELSE
      cRes := ""
   ENDIF

   RETURN cRes

FUNCTION hwg_WAITRUN( cRun )

//#ifdef __XHARBOUR__
Local hIn, hOut, nRet, hProc
   // "Launching process", cProc
   hProc := hb_processOpen( cRun , @hIn, @hOut, @hOut )

   // "Reading output"
   // "Waiting for process termination"
   nRet := HB_ProcessValue( hProc )

   FClose( hProc )
   FClose( hIn )
   FClose( hOut )

   Return nRet

FUNCTION hwg_WChoice( arr, cTitle, nLeft, nTop, oFont, clrT, clrB, clrTSel, clrBSel, cOk, cCancel )

   LOCAL oDlg, oBrw, nChoice := 0, lArray := .T., nField, lNewFont := .F.
   LOCAL i, aLen, nLen := 0, addX := 20, addY := 20, minWidth := 0, x1
   LOCAL hDC, aMetr, width, height, aArea, aRect
   LOCAL nStyle := WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX

   IF cTitle == Nil ; cTitle := "" ; ENDIF
   IF nLeft == Nil .AND. nTop == Nil ; nStyle += DS_CENTER ; ENDIF
   IF nLeft == Nil ; nLeft := 0 ; ENDIF
   IF nTop == Nil ; nTop := 0 ; ENDIF
   IF oFont == Nil
      oFont := HFont():Add( "MS Sans Serif", 0, - 13 )
      lNewFont := .T.
   ENDIF
   IF cOk != Nil
      minWidth += 120
      IF cCancel != Nil
         minWidth += 100
      ENDIF
      addY += 30
   ENDIF

   IF ValType( arr ) == "C"
      lArray := .F.
      aLen := RecCount()
      IF ( nField := FieldPos( arr ) ) == 0
         RETURN 0
      ENDIF
      nLen := dbFieldInfo( 3, nField )
   ELSE
      aLen := Len( arr )
      IF ValType( arr[ 1 ] ) == "A"
         FOR i := 1 TO aLen
            nLen := Max( nLen, Len( arr[ i, 1 ] ) )
         NEXT
      ELSE
         FOR i := 1 TO aLen
            nLen := Max( nLen, Len( arr[ i ] ) )
         NEXT
      ENDIF
   ENDIF

   hDC := hwg_Getdc( hwg_Getactivewindow() )
   hwg_Selectobject( hDC, oFont:handle )
   aMetr := hwg_Gettextmetric( hDC )
   aArea := hwg_GetDeviceArea( hDC )
   aRect := hwg_Getwindowrect( hwg_Getactivewindow() )
   hwg_Releasedc( hwg_Getactivewindow(), hDC )
   height := ( aMetr[ 1 ] + 1 ) * aLen + 4 + addY + 8
   IF height > aArea[ 2 ] - aRect[ 2 ] - nTop - 60
      height := aArea[ 2 ] - aRect[ 2 ] - nTop - 60
   ENDIF
   width := Max( aMetr[ 2 ] * 2 * nLen + addX, minWidth )

   INIT DIALOG oDlg TITLE cTitle ;
        At nLeft, nTop           ;
        SIZE width, height       ;
        STYLE nStyle            ;
        FONT oFont              ;
        ON INIT { | o | hwg_Resetwindowpos( o:handle ), o:nInitFocus := oBrw }
   IF lArray
      @ 0, 0 Browse oBrw Array
      oBrw:aArray := arr
      IF ValType( arr[ 1 ] ) == "A"
         oBrw:AddColumn( HColumn():New( , { | value, o | HB_SYMBOL_UNUSED( value ), o:aArray[ o:nCurrent, 1 ] }, "C", nLen ) )
      ELSE
         oBrw:AddColumn( HColumn():New( , { | value, o | HB_SYMBOL_UNUSED( value ), o:aArray[ o:nCurrent ] }, "C", nLen ) )
      ENDIF
   ELSE
      @ 0, 0 Browse oBrw DATABASE
      oBrw:AddColumn( HColumn():New( , { | value, o | HB_SYMBOL_UNUSED( value ), ( o:Alias ) ->( FieldGet( nField ) ) }, "C", nLen ) )
   ENDIF

   oBrw:oFont  := oFont
   oBrw:bSize  := { | o, x, y | hwg_Movewindow( o:handle, addX / 2, 10, x - addX, y - addY ) }
   oBrw:bEnter := { | o | nChoice := o:nCurrent, hwg_EndDialog( o:oParent:handle ) }
   oBrw:bKeyDown := {|o,key|HB_SYMBOL_UNUSED(o),Iif(key==27,(hwg_EndDialog(oDlg:handle),.F.),.T.)}

   oBrw:lDispHead := .F.
   IF clrT != Nil
      oBrw:tcolor := clrT
   ENDIF
   IF clrB != Nil
      oBrw:bcolor := clrB
   ENDIF
   IF clrTSel != Nil
      oBrw:tcolorSel := clrTSel
   ENDIF
   IF clrBSel != Nil
      oBrw:bcolorSel := clrBSel
   ENDIF

   IF cOk != Nil
      x1 := Int( width / 2 ) - IIf( cCancel != Nil, 90, 40 )
      @ x1, height - 36 BUTTON cOk SIZE 80, 30 ON CLICK { || nChoice := oBrw:nCurrent, hwg_EndDialog( oDlg:handle ) }
      IF cCancel != Nil
         @ x1 + 100, height - 36 BUTTON cCancel SIZE 80, 30 ON CLICK { || nChoice := 0, hwg_EndDialog( oDlg:handle ) }
      ENDIF
   ENDIF

   oDlg:Activate()
   IF lNewFont
      oFont:Release()
   ENDIF

   RETURN nChoice

FUNCTION hwg_ShowProgress( nStep, maxPos, nRange, cTitle, oWnd, x1, y1, width, height )

   LOCAL nStyle := WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX
   STATIC oDlg, hPBar, iCou, nLimit

   IF nStep == 0
      nLimit := IIf( nRange != Nil, Int( nRange / maxPos ), 1 )
      iCou := 0
      x1 := IIf( x1 == Nil, 0, x1 )
      y1 := IIf( x1 == Nil, 0, y1 )
      width := IIf( width == Nil, 220, width )
      height := IIf( height == Nil, 55, height )
      IF x1 == 0
         nStyle += DS_CENTER
      ENDIF
      IF oWnd != Nil
         oDlg := Nil
         hPBar := hwg_Createprogressbar( oWnd:handle, maxPos, 20, 25, width - 40, 20 )
      ELSE
         INIT DIALOG oDlg TITLE cTitle   ;
              At x1, y1 SIZE width, height ;
              STYLE nStyle               ;
              ON INIT { | o | hPBar := hwg_Createprogressbar( o:handle, maxPos, 20, 25, width - 40, 20 ) }
         ACTIVATE DIALOG oDlg NOMODAL
      ENDIF
   ELSEIF nStep == 1
      iCou ++
      IF iCou == nLimit
         iCou := 0
         hwg_Updateprogressbar( hPBar )
      ENDIF
   ELSEIF nStep == 2
      hwg_Updateprogressbar( hPBar )
   ELSEIF nStep == 3
      hwg_Setwindowtext( oDlg:handle, cTitle )
      IF maxPos != Nil
         hwg_Setprogressbar( hPBar, maxPos )
      ENDIF
   ELSE
      hwg_Destroywindow( hPBar )
      IF oDlg != Nil
         hwg_EndDialog( oDlg:handle )
      ENDIF
   ENDIF

   RETURN Nil

FUNCTION hwg_EndWindow()

   IF HWindow():GetMain() != Nil
      hwg_Sendmessage( HWindow():aWindows[ 1 ]:handle, WM_SYSCOMMAND, SC_CLOSE, 0 )
   ENDIF
   RETURN Nil

FUNCTION hwg_HdSerial( cDrive )


   LOCAL n       :=  hwg_HDGETSERIAL( cDrive )
   LOCAL cHex    :=  HB_NUMTOHEX( n )
   LOCAL cResult
   cResult := SubStr( cHex, 1, 4 ) + '-' + SubStr( cHex, 5, 4 )

   RETURN cResult

FUNCTION Hwg_GetIni( cSection, cEntry, cDefault, cFile )
   RETURN hwg_GetPrivateProfileString( cSection, cEntry, cDefault, cFile )

FUNCTION Hwg_WriteIni( cSection, cEntry, cValue, cFile )
   RETURN( hwg_WritePrivateProfileString( cSection, cEntry, cValue, cFile ) )

FUNCTION hwg_SetHelpFileName ( cNewName )

   STATIC cName := ""
   LOCAL cOldName := cName
   IF cNewName <> Nil
      cName := cNewName
   ENDIF
   RETURN cOldName

FUNCTION hwg_RefreshAllGets( oDlg )


   AEval( oDlg:GetList, { | o | o:Refresh() } )
   RETURN Nil

/*

cTitle:   Window Title
cDescr:  'Data Bases','*.dbf'
cTip  :   *.dbf
cInitDir: Initial directory

*/

FUNCTION hwg_SelectMultipleFiles( cDescr, cTip, cIniDir, cTitle )


   LOCAL aFiles, cPath, cFile, cFilter, nAt
   LOCAL hWnd := 0
   LOCAL nFlags := NIL
   LOCAL nIndex := 1

   cFilter := cDescr + Chr( 0 ) + cTip + Chr( 0 )
   /* initialize buffer with 0 bytes. Important is the 1-st character,
    * from MSDN:  The first character of this buffer must be NULL
    *             if initialization is not necessary
    */
   cFile := repl( chr( 0 ), 32000 )
   aFiles := {}

   cPath := hwg_GetOpenFileName( hWnd, @cFile, cTitle, cFilter, nFlags, cIniDir, Nil, @nIndex )

   nAt := At( Chr( 0 ) + Chr( 0 ), cFile )
   IF nAt != 0
      cFile := Left( cFile, nAt - 1 )
      nAt := At( Chr( 0 ), cFile )
      IF nAt != 0
         /* skip path which is already in cPath variable */
         cFile := SubStr( cFile, nAt + 1 )
         /* decode files */
         WHILE ! cFile == ""
            nAt := At( Chr( 0 ), cFile )
            IF nAt != 0
               AAdd( aFiles, cPath + hb_osPathSeparator() + ;
                             Left( cFile, nAt - 1 ) )
               cFile := SubStr( cFile, nAt + 1 )
            ELSE
               AAdd( aFiles, cPath + hb_osPathSeparator() + cFile )
               EXIT
            ENDIF
         ENDDO
      ELSE
         /* only single file selected */
         AAdd( aFiles, cPath )
      ENDIF
   ENDIF
   RETURN aFiles

FUNCTION HWG_Version( oTip )
   LOCAL oVersion
   IF oTip == 1
      oVersion := "HwGUI " + HWG_VERSION + " " + Version()
   ELSE
      oVersion := "HwGUI " + HWG_VERSION
   ENDIF
   RETURN oVersion

FUNCTION hwg_TxtRect( cTxt, oWin, oFont )


   LOCAL hDC
   LOCAL ASize
   LOCAL hFont

   oFont := IIF( oFont != Nil, oFont, oWin:oFont )

   hDC       := hwg_Getdc( oWin:handle )
   IF oFont == Nil .AND. oWin:oParent != Nil
      oFont := oWin:oParent:oFont
   ENDIF
   IF oFont != Nil
      hFont := hwg_Selectobject( hDC, oFont:handle )
   ENDIF
   ASize     := hwg_Gettextsize( hDC, cTxt )
   IF oFont != Nil
      hwg_Selectobject( hDC, hFont )
   ENDIF
   hwg_Releasedc( oWin:handle, hDC )
   RETURN ASize

FUNCTION hwg_getParentForm( o )
   DO WHILE o:oParent != Nil .AND. !__ObjHasMsg( o, "GETLIST" )
      o := o:oParent
   ENDDO
   RETURN o

/*
Luis Fernando Basso contribution
*/

/** CheckFocus
* check focus of controls before calling events
*/
FUNCTION hwg_CheckFocus( oCtrl, lInside )

   LOCAL oParent := hwg_GetParentForm( oCtrl )
   LOCAL hGetFocus := hwg_Ptrtoulong( hwg_Getfocus() ), lModal

   IF ( !EMPTY( oParent ) .AND. ! hwg_Iswindowvisible( oParent:handle ) ) .OR. Empty( hwg_Getactivewindow() ) // == 0
      IF ! lInside .and. Empty( oParent:nInitFocus ) // = 0
         oParent:Show()
         hwg_Setfocus( oParent:handle )
         hwg_Setfocus( hGetFocus )
      ELSEIF ! lInside .AND. ! EMPTY( oParent:nInitFocus )
       //  hwg_Setfocus( oParent:handle )
         RETURN .T.
     ENDIF
      RETURN .F.
   ELSEIF ! lInside .AND. ! oCtrl:lNoWhen
      oCtrl:lNoWhen := .T.
   ELSEIF ! lInside
      RETURN .F.
   ENDIF
   IF oParent  != Nil .AND. lInside   // valid
      lModal :=  oParent:lModal .AND.  oParent:Type >  WND_DLG_RESOURCE
      IF ( ( ! Empty( hGetFocus ) .AND. lModal .AND. ! hwg_Selffocus( hwg_GetWindowParent( hGetFocus ), oParent:Handle ) ) .OR. ;
         (  hwg_Selffocus( hGetFocus, oCtrl:oParent:Handle  ) ) ) .AND. ;
            hwg_Selffocus( oParent:handle, oCtrl:oParent:Handle )
         RETURN .F.
      ENDIF
      oCtrl:lNoWhen := .F.
   ELSE
      oCtrl:oParent:lGetSkipLostFocus := .F.
   ENDIF

   RETURN .T.

FUNCTION hwg_WhenSetFocus( oCtrl, nSkip )


   IF  hwg_Selffocus( oCtrl:Handle ) .OR. EMPTY( hwg_Getfocus() )
       hwg_GetSkip( oCtrl:oParent, oCtrl:handle, , nSkip )
   ENDIF
   RETURN Nil

FUNCTION hwg_GetWindowParent( nHandle )


   DO WHILE ! Empty( hwg_Getparent( nHandle ) ) .AND. ! hwg_Selffocus( nHandle, hwg_Getactivewindow() )
      nHandle := hwg_Getparent( nHandle )
   ENDDO
   RETURN hwg_Ptrtoulong( nHandle )


FUNCTION hwg_ProcKeyList( oCtrl, wParam, oMain )

LOCAL oParent, nCtrl,nPos

   IF ( wParam = VK_RETURN .OR. wParam = VK_ESCAPE ) .AND. hwg_ProcOkCancel( oCtrl, wParam )
      RETURN .F.
   ENDIF
   IF wParam != VK_SHIFT  .AND. wParam != VK_CONTROL .AND. wParam != VK_MENU
      oParent := IIF( oMain != Nil, oMain, hwg_GetParentForm( oCtrl ) )
      IF oParent != Nil .AND. ! Empty( oParent:KeyList )
         nctrl := IIf( hwg_IsCtrlShift(.t., .f.), FCONTROL, iif(hwg_IsCtrlShift(.f., .t.), FSHIFT, 0 ) )
         IF ( nPos := AScan( oParent:KeyList, { | a | a[ 1 ] == nctrl.AND.a[ 2 ] == wParam } ) ) > 0
            Eval( oParent:KeyList[ nPos, 3 ], oCtrl )
            RETURN .T.
         ENDIF
      ENDIF
      IF oParent != Nil .AND. oMain = Nil .AND. HWindow():GetMain() != Nil
          hwg_ProcKeyList( oCtrl, wParam, HWindow():GetMain():aWindows[ 1 ] )
      ENDIF
   ENDIF
   RETURN .F.

FUNCTION hwg_ProcOkCancel( oCtrl, nKey, lForce )

   Local oWin := hwg_GetParentForm(oCtrl), lEscape
   Local iParHigh := IIF( nKey = VK_RETURN, IDOK, IDCANCEL )
   LOCAL oCtrlFocu := oCtrl

   lForce := ! Empty( lForce )
   lEscape := nKey = VK_ESCAPE .AND. ( oCtrl := oWin:FindControl( IDCANCEL ) ) != Nil .AND. ! oCtrl:IsEnabled()
   IF ( ( oWin:Type >= WND_DLG_RESOURCE .AND. oWin:lModal) .AND. ! lForce .and. !lEscape )  .OR. ( nKey != VK_RETURN .AND. nKey != VK_ESCAPE )
      Return .F.
	 ENDIF
   IF iParHigh == IDOK
      IF ( oCtrl := oWin:FindControl( IDOK ) ) != Nil .AND. oCtrl:IsEnabled()
         oCtrl:Setfocus()
  	     oWin:lResult := .T.
  	     IF lForce
	       ELSEIF ISBLOCK( oCtrl:bClick ) .AND. ! lForce
	          hwg_Sendmessage( oCtrl:oParent:handle, WM_COMMAND, hwg_Makewparam( oCtrl:id, BN_CLICKED ), oCtrl:handle )
	       ELSEIF oWin:lExitOnEnter
            oWin:close()
         ELSE
            hwg_Sendmessage( oWin:handle, WM_COMMAND, hwg_Makewparam( IDOK, 0 ), oCtrlFocu:handle )      
         ENDIF
         RETURN .T.
      ENDIF
   ELSEIF iParHigh == IDCANCEL
      IF ( oCtrl := oWin:FindControl( IDCANCEL ) ) != Nil .AND. oCtrl:IsEnabled() 
         oCtrl:Setfocus()
         oWin:lResult := .F.
         hwg_Sendmessage( oCtrl:oParent:handle, WM_COMMAND, hwg_Makewparam( oCtrl:id, BN_CLICKED ), oCtrl:handle )
      ELSEIF oWin:lGetSkiponEsc
         oCtrl := oCtrlFocu
         IF oCtrl  != Nil .AND.  __ObjHasMsg( oCtrl, "OGROUP" )  .AND. oCtrl:oGroup:oHGroup != Nil
             oCtrl := oCtrl:oGroup:oHGroup
         ENDIF
         IF oCtrl  != Nil .and. hwg_GetSkip( oCtrl:oParent, oCtrl:Handle, , - 1 )
            IF AScan( oWin:GetList, { | o | o:handle == oCtrl:Handle } ) > 1
               RETURN .T.
            ENDIF
         ENDIF                                               
      ELSEIF oWin:lExitOnEsc
          oWin:close()
      ELSEIF ! oWin:lExitOnEsc
         oWin:nLastKey := 0
         hwg_Sendmessage( oWin:handle, WM_COMMAND, hwg_Makewparam( IDCANCEL, 0 ), oCtrlFocu:handle )
         RETURN .F.
      ENDIF
      RETURN .T.
   ENDIF
   RETURN .F.


FUNCTION hwg_FindAccelerator( oCtrl, lParam )

  Local nlen , i ,pos

  nlen := LEN( oCtrl:aControls )
  FOR i = 1 to nLen
     IF oCtrl:aControls[ i ]:classname = "HTAB"
        IF ( pos := hwg_FindTabAccelerator( oCtrl:aControls[ i ], lParam ) ) > 0 .AND. ;
  	  oCtrl:aControls[ i ]:Pages[ pos ]:Enabled
            oCtrl:aControls[ i ]:SetTab( pos )
            RETURN oCtrl:aControls[ i ]
        ENDIF
     ENDIF
     IF LEN(oCtrl:aControls[ i ]:aControls ) > 0
         RETURN hwg_FindAccelerator( oCtrl:aControls[ i ], lParam)
	   ENDIF
     IF __ObjHasMsg( oCtrl:aControls[ i ],"TITLE") .AND. VALTYPE( oCtrl:aControls[ i ]:title) = "C" .AND. ;
         ! oCtrl:aControls[ i ]:lHide .AND. hwg_Iswindowenabled( oCtrl:aControls[ i ]:handle )
        IF ( pos := At( "&", oCtrl:aControls[ i ]:title ) ) > 0 .AND.  Upper( Chr( lParam)) ==  Upper( SubStr( oCtrl:aControls[ i ]:title, ++ pos, 1 ) )
           RETURN oCtrl:aControls[ i ]
        ENDIF
     ENDIF
   NEXT
   RETURN Nil

FUNCTION hwg_GetBackColorParent( oCtrl, lSelf, lTransparent )

   Local bColor := hwg_Getsyscolor( COLOR_BTNFACE ), hTheme
   Local brush := nil

   DEFAULT lTransparent := .F.
   IF lSelf == Nil .OR. ! lSelf
      oCtrl := oCtrl:oParent
   ENDIF
   IF  oCtrl != Nil .AND. oCtrl:Classname = "HTAB"
       IF Len( oCtrl:aPages ) > 0 .AND. oCtrl:Pages[ oCtrl:GETACTIVEPAGE() ]:bColor != Nil
          bColor := oCtrl:Pages[ oCtrl:GetActivePage() ]:bColor
       ELSEIF hwg_Isthemeactive() .AND. oCtrl:WindowsManifest
          hTheme := hwg_openthemedata( oCtrl:handle, "TAB" )
          IF !EMPTY( hTheme )
             bColor := HWG_GETTHEMESYSCOLOR( hTheme, COLOR_WINDOW  )
             hwg_closethemedata( hTheme )
          ENDIF
       ENDIF
   ELSEIF oCtrl:bColor != Nil
       bColor := oCtrl:bColor
   ENDIF
   brush := HBrush():Add( bColor ) 
   Return brush

Function  hwg_SetFontStyle( oWnd, lBold, lItalic, lUnderline )
   LOCAL oFont

   IF oWnd:oFont == NIL
      IF hwg_GetParentForm(oWnd) != NIL .AND. hwg_GetParentForm(oWnd):oFont != NIL
         oFont := hwg_GetParentForm(oWnd):oFont
      ELSEIF oWnd:oParent:oFont != NIL
         oFont := oWnd:oParent:oFont
      ENDIF
      IF oFont == NIL .AND. lBold == NIL .AND. lItalic == NIL .AND. lUnderline == NIL
         RETURN .T.
      ENDIF
      oWnd:oFont := IIF( oFont != NIL, HFont():Add( oFont:name, oFont:Width,,,, Iif(lItalic!=Nil,Iif(lItalic,1,0),NIL),Iif(lUnderline!=Nil,Iif(lUnderline,1,0),NIL) ), ;
            HFont():Add( "", 0,, Iif(lBold!=Nil,Iif(lBold,FW_BOLD,FW_REGULAR),NIL),,Iif(lItalic!=Nil,Iif(lItalic,1,0),NIL),Iif(lUnderline!=Nil,Iif(lUnderline,1,0),NIL)) )
   ENDIF
   IF lBold != NIL .OR. lItalic != NIL .OR. lUnderline != NIL
      oWnd:oFont := oWnd:oFont:SetFontStyle( lBold,,lItalic,lUnderline )
      hwg_Sendmessage( oWnd:handle, WM_SETFONT, oWnd:oFont:handle, hwg_Makelparam( 0, 1 ) )
      hwg_Redrawwindow( oWnd:handle, RDW_NOERASE + RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT )
   ENDIF

   RETURN Iif(lBold!=Nil,(oWnd:oFont:weight==FW_BOLD), Iif(lItalic!=Nil,(oWnd:oFont:italic=1),oWnd:oFont:Underline==1))

Function hwg_SetAll( oWnd, cProperty, Value, aControls, cClass )

// cProperty Specifies the property to be set.
// Value Specifies the new setting for the property. The data type of Value depends on the property being set.
 //aControls - property of the Control with objectos inside
 // cClass baseclass hwgui
   Local nLen , i

   aControls := IIF( EMPTY( aControls ), oWnd:aControls, aControls )
   nLen := IIF( VALTYPE( aControls ) = "C", Len( oWnd:&aControls ), LEN( aControls ) )
   FOR i = 1 TO nLen
      IF VALTYPE( aControls ) = "C"
         oWnd:&aControls[ i ]:&cProperty := Value
      ELSEIF cClass == Nil .OR. UPPER( cClass ) == aControls[ i ]:ClassName
         IF Value = Nil
            __mvPrivate( "oCtrl" )
            &( "oCtrl" ) := aControls[ i ]
            &( "oCtrl:" + cProperty )
         ELSE
            aControls[ i ]:&cProperty := Value
         ENDIF
      ENDIF
   NEXT
   RETURN Nil

FUNCTION HWG_ScrollHV( oForm, msg,wParam,lParam )
   Local nDelta, nSBCode , nPos, nInc

   HB_SYMBOL_UNUSED(lParam)

   nSBCode := hwg_Loword(wParam)
   IF msg == WM_MOUSEWHEEL
      nSBCode = IIF( hwg_Hiword( wParam ) > 32768, hwg_Hiword( wParam ) - 65535, hwg_Hiword( wParam ) )
      nSBCode = IIF( nSBCode < 0, SB_LINEDOWN, SB_LINEUP )
   ENDIF
   IF ( msg = WM_VSCROLL ) .OR.msg == WM_MOUSEWHEEL
     // Handle vertical scrollbar messages
      Switch (nSBCode)
         Case SB_TOP
             nInc := - oForm:nVscrollPos; EXIT
         Case SB_BOTTOM
             nInc := oForm:nVscrollMax - oForm:nVscrollPos;  EXIT
         Case SB_LINEUP
             nInc := - Int( oForm:nVertInc * 0.05 + 0.49);    EXIT
         Case SB_LINEDOWN
             nInc := Int( oForm:nVertInc * 0.05 + 0.49); EXIT
         Case SB_PAGEUP
             nInc := min( - 1, - oForm:nVertInc / 2 );  EXIT
         Case SB_PAGEDOWN
            nInc := max( 1, oForm:nVertInc / 2 );   EXIT
         Case SB_THUMBTRACK
            nPos := hwg_Hiword( wParam )
            nInc := nPos - oForm:nVscrollPos ; EXIT
      #ifdef __XHARBOUR__
         Default
      #else
         Otherwise
      #endif
            nInc := 0
      END
      nInc := Max( - oForm:nVscrollPos, Min( nInc, oForm:nVscrollMax - oForm:nVscrollPos))
      oForm:nVscrollPos += nInc
      nDelta := - VERT_PTS * nInc
      hwg_Scrollwindow( oForm:handle, 0, nDelta ) //, Nil, NIL )
      hwg_Setscrollpos( oForm:Handle, SB_VERT, oForm:nVscrollPos, .T. )

   ELSEIF ( msg = WM_HSCROLL ) //.OR. msg == WM_MOUSEWHEEL
    // Handle vertical scrollbar messages
      Switch (nSBCode)
         Case SB_TOP
             nInc := - oForm:nHscrollPos; EXIT
         Case SB_BOTTOM
             nInc := oForm:nHscrollMax - oForm:nHscrollPos;  EXIT
         Case SB_LINEUP
             nInc := -1;    EXIT
         Case SB_LINEDOWN
             nInc := 1; EXIT
         Case SB_PAGEUP
             nInc := - HORZ_PTS;  EXIT
         Case SB_PAGEDOWN
            nInc := HORZ_PTS;   EXIT
         Case SB_THUMBTRACK
            nPos := hwg_Hiword( wParam )
            nInc := nPos - oForm:nHscrollPos; EXIT
      #ifdef __XHARBOUR__
         Default
      #else
         Otherwise
      #endif
            nInc := 0
      END
      nInc := max( - oForm:nHscrollPos, min( nInc, oForm:nHscrollMax - oForm:nHscrollPos ) )
      oForm:nHscrollPos += nInc
      nDelta := - HORZ_PTS * nInc
      hwg_Scrollwindow( oForm:handle, nDelta, 0 )
      hwg_Setscrollpos( oForm:Handle, SB_HORZ, oForm:nHscrollPos, .T. )
   ENDIF 	
   RETURN Nil

