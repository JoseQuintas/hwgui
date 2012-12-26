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

FUNCTION InitObjects( oWnd )
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
         IF __ObjHasMsg( pArray[ i ], "INIT" ) .AND. SelfFocus( oWnd:Handle, pArray[ i ]:oParent:Handle )
            pArray[ i ]:Init( oWnd )
            pArray[ i ]:lInit := .T.
         ENDIF
      NEXT
   ENDIF
   HObject():aObjects := {}
   RETURN .T.

FUNCTION InitControls( oWnd, lNoActivate )
   LOCAL i, pArray := oWnd:aControls, lInit

   lNoActivate := IIf( lNoActivate == Nil, .F., lNoActivate )

   IF pArray != Nil
      FOR i := 1 TO Len( pArray )
         // writelog( "InitControl1"+str(pArray[i]:handle)+"/"+pArray[i]:classname+" "+str(pArray[i]:nWidth)+"/"+str(pArray[i]:nHeight) )
         IF Empty( pArray[ i ]:handle ) .AND. ! lNoActivate
//         IF empty(pArray[i]:handle ) .AND. !lNoActivate
            lInit := pArray[ i ]:lInit
            pArray[ i ]:lInit := .T.
            pArray[ i ]:Activate()
            pArray[ i ]:lInit := lInit
         ELSEIF  ! lNoActivate
            pArray[ i ]:lInit := .T.
         ENDIF
//           IF empty(pArray[i]:handle)// <= 0
         IF IIF( ValType( pArray[ i ]:handle ) == "P", ptrtoulong( pArray[ i ]:handle ), pArray[ i ]:handle ) <= 0
            pArray[ i ]:handle := GetDlgItem( oWnd:handle, pArray[ i ]:id )

            // writelog( "InitControl2"+str(pArray[i]:handle)+"/"+pArray[i]:classname )
         ENDIF
         IF ! Empty( pArray[ i ]:aControls )
            InitControls( pArray[ i ] )
         ENDIF
         pArray[ i ]:Init()
          // nando required to classes that inherit the class of patterns hwgui
         IF ! pArray[i]:lInit
            pArray[i]:Super:Init()
         ENDIF
      NEXT
   ENDIF

   RETURN .T.

FUNCTION FindParent( hCtrl, nLevel )
   LOCAL i, oParent, hParent := GetParent( hCtrl )
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
      IF ( oParent := FindParent( hParent, nLevel + 1 ) ) != Nil
         RETURN oParent:FindControl( , hParent )
      ENDIF
   ENDIF
   RETURN Nil

FUNCTION FindSelf( hCtrl )
   LOCAL oParent
   oParent := FindParent( hCtrl )
   IF oParent == Nil
      oParent := GetAncestor( hCtrl, GA_PARENT )
   ENDIF
   IF oParent != Nil  .AND. VALTYPE( oParent ) != "N"
      RETURN oParent:FindControl( , hCtrl )
   ENDIF
   RETURN Nil

FUNCTION WriteStatus( oWnd, nPart, cText, lRedraw )
   LOCAL aControls, i
   aControls := oWnd:aControls
   IF ( i := AScan( aControls, { | o | o:ClassName() == "HSTATUS" } ) ) > 0
      WriteStatusWindow( aControls[ i ]:handle, nPart - 1, cText )
      IF lRedraw != Nil .AND. lRedraw
         RedrawWindow( aControls[ i ]:handle, RDW_ERASE + RDW_INVALIDATE )
      ENDIF
   ENDIF
   RETURN Nil

FUNCTION ReadStatus( oWnd, nPart )
   LOCAL aControls, i, ntxtLen, cText := ""
   aControls := oWnd:aControls
   IF ( i := AScan( aControls, { | o | o:ClassName() == "HSTATUS" } ) ) > 0
      ntxtLen := SendMessage( aControls[ i ]:handle, SB_GETTEXTLENGTH, nPart - 1, 0 )
      cText := Replicate( Chr( 0 ), ntxtLen )
      SendMessage( aControls[ i ]:handle, SB_GETTEXT, nPart - 1, @cText )
   ENDIF
   RETURN cText

FUNCTION VColor( cColor )
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

FUNCTION MsgGet( cTitle, cText, nStyle, x, y, nDlgStyle, cResIni )
   LOCAL oModDlg, oFont := HFont():Add( "MS Sans Serif", 0, - 13 )
   LOCAL cRes := IIf( cResIni != Nil, Trim( cResIni ), "" )
   /*
   IF ! Empty( cRes )
      Keyb_Event( VK_END )
   ENDIF
   */
   nStyle := IIf( nStyle == Nil, 0, nStyle )
   x := IIf( x == Nil, 210, x )
   y := IIf( y == Nil, 10, y )
   nDlgStyle := IIf( nDlgStyle == Nil, 0, nDlgStyle )

   INIT DIALOG oModDlg TITLE cTitle At x, y SIZE 300, 140 ;
        FONT oFont CLIPPER ;
        STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX + nDlgStyle

   @ 20, 10 SAY cText SIZE 260, 22
   @ 20, 35 GET cRes  SIZE 260, 26 STYLE WS_TABSTOP + ES_AUTOHSCROLL + nStyle
   oModDlg:aControls[ 2 ]:Anchor := 11
   @ 20, 95 BUTTON "Ok" ID IDOK SIZE 100, 32
   @ 180, 95 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32
   oModDlg:aControls[ 4 ]:Anchor := 9

   ACTIVATE DIALOG oModDlg ON ACTIVATE { || IIF( ! EMPTY( cRes ), KEYB_EVENT( VK_END ), .T. ) }

   oFont:Release()
   IF oModDlg:lResult
      RETURN Trim( cRes )
   ELSE
      cRes := ""
   ENDIF

   RETURN cRes

FUNCTION WAITRUN( cRun )
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
//#else
//  __Run( cRun )
//   Return 0
//#endif

FUNCTION WChoice( arr, cTitle, nLeft, nTop, oFont, clrT, clrB, clrTSel, clrBSel, cOk, cCancel )
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

   hDC := GetDC( GetActiveWindow() )
   SelectObject( hDC, oFont:handle )
   aMetr := GetTextMetric( hDC )
   aArea := hwg_GetDeviceArea( hDC )
   aRect := GetWindowRect( GetActiveWindow() )
   ReleaseDC( GetActiveWindow(), hDC )
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
        ON INIT { | o | ResetWindowPos( o:handle ), o:nInitFocus := oBrw }
       //ON INIT {|o|ResetWindowPos(o:handle),oBrw:setfocus()}
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
   oBrw:bSize  := { | o, x, y | MoveWindow( o:handle, addX / 2, 10, x - addX, y - addY ) }
   oBrw:bEnter := { | o | nChoice := o:nCurrent, EndDialog( o:oParent:handle ) }
   oBrw:bKeyDown := {|o,key|HB_SYMBOL_UNUSED(o),Iif(key==27,(EndDialog(oDlg:handle),.F.),.T.)}

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
      @ x1, height - 36 BUTTON cOk SIZE 80, 30 ON CLICK { || nChoice := oBrw:nCurrent, EndDialog( oDlg:handle ) }
      IF cCancel != Nil
         @ x1 + 100, height - 36 BUTTON cCancel SIZE 80, 30 ON CLICK { || nChoice := 0, EndDialog( oDlg:handle ) }
      ENDIF
   ENDIF

   oDlg:Activate()
   IF lNewFont
      oFont:Release()
   ENDIF

   RETURN nChoice

FUNCTION ShowProgress( nStep, maxPos, nRange, cTitle, oWnd, x1, y1, width, height )
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
         hPBar := CreateProgressBar( oWnd:handle, maxPos, 20, 25, width - 40, 20 )
      ELSE
         INIT DIALOG oDlg TITLE cTitle   ;
              At x1, y1 SIZE width, height ;
              STYLE nStyle               ;
              ON INIT { | o | hPBar := CreateProgressBar( o:handle, maxPos, 20, 25, width - 40, 20 ) }
         ACTIVATE DIALOG oDlg NOMODAL
      ENDIF
   ELSEIF nStep == 1
      iCou ++
      IF iCou == nLimit
         iCou := 0
         UpdateProgressBar( hPBar )
      ENDIF
   ELSEIF nStep == 2
      UpdateProgressBar( hPBar )
   ELSEIF nStep == 3
      SetWindowText( oDlg:handle, cTitle )
      IF maxPos != Nil
         SetProgressBar( hPBar, maxPos )
      ENDIF
   ELSE
      DestroyWindow( hPBar )
      IF oDlg != Nil
         EndDialog( oDlg:handle )
      ENDIF
   ENDIF

   RETURN Nil

FUNCTION EndWindow()
   IF HWindow():GetMain() != Nil
      SendMessage( HWindow():aWindows[ 1 ]:handle, WM_SYSCOMMAND, SC_CLOSE, 0 )
   ENDIF
   RETURN Nil

FUNCTION HdSerial( cDrive )

   LOCAL n       :=  HDGETSERIAL( cDrive )
   LOCAL cHex    :=  HB_NUMTOHEX( n )
   LOCAL cResult
   cResult := SubStr( cHex, 1, 4 ) + '-' + SubStr( cHex, 5, 4 )

   RETURN cResult

FUNCTION Hwg_GetIni( cSection, cEntry, cDefault, cFile )
   RETURN GetPrivateProfileString( cSection, cEntry, cDefault, cFile )

FUNCTION Hwg_WriteIni( cSection, cEntry, cValue, cFile )
   RETURN( WritePrivateProfileString( cSection, cEntry, cValue, cFile ) )

FUNCTION SetHelpFileName ( cNewName )
   STATIC cName := ""
   LOCAL cOldName := cName
   IF cNewName <> Nil
      cName := cNewName
   ENDIF
   RETURN cOldName

FUNCTION RefreshAllGets( oDlg )

   AEval( oDlg:GetList, { | o | o:Refresh() } )
   RETURN Nil

/*

cTitle:   Window Title
cDescr:  'Data Bases','*.dbf'
cTip  :   *.dbf
cInitDir: Initial directory

*/

FUNCTION SelectMultipleFiles( cDescr, cTip, cIniDir, cTitle )

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

   cPath := _GetOpenFileName( hWnd, @cFile, cTitle, cFilter, nFlags, cIniDir, Nil, @nIndex )

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

FUNCTION TxtRect( cTxt, oWin, oFont )

   LOCAL hDC
   LOCAL ASize
   LOCAL hFont

   oFont := IIF( oFont != Nil, oFont, oWin:oFont )

   hDC       := GetDC( oWin:handle )
   IF oFont == Nil .AND. oWin:oParent != Nil
      oFont := oWin:oParent:oFont
   ENDIF
   IF oFont != Nil
      hFont := SelectObject( hDC, oFont:handle )
   ENDIF
   ASize     := GetTextSize( hDC, cTxt )
   IF oFont != Nil
      SelectObject( hDC, hFont )
   ENDIF
   ReleaseDC( oWin:handle, hDC )
   RETURN ASize


FUNCTION ParentGetDialog( o )
   DO WHILE ( o := o:oParent ) != Nil .and. ! __ObjHasMsg( o, "GETLIST" )
   ENDDO
   RETURN o

/*
Luis Fernando Basso contribution
*/

/** CheckFocus
* check focus of controls before calling events
*/
FUNCTION CheckFocus( oCtrl, lInside )
   LOCAL oParent := ParentGetDialog( oCtrl )
   LOCAL hGetFocus := PtrtouLong( GetFocus() ), lModal

   IF ( !EMPTY( oParent ) .AND. ! IsWindowVisible( oParent:handle ) ) .OR. Empty( GetActiveWindow() ) // == 0
      IF ! lInside .and. Empty( oParent:nInitFocus ) // = 0
         oParent:Show()
         SetFocus( oParent:handle )
         SetFocus( hGetFocus )
      ELSEIF ! lInside .AND. ! EMPTY( oParent:nInitFocus )
       //  SetFocus( oParent:handle )
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
      IF ( ( ! Empty( hGetFocus ) .AND. lModal .AND. ! SELFFOCUS( GetWindowParent( hGetFocus ), oParent:Handle ) ) .OR. ;
         (  SELFFOCUS( hGetFocus, oCtrl:oParent:Handle  ) ) ) .AND. ;
            SELFFOCUS( oParent:handle, oCtrl:oParent:Handle )
         RETURN .F.
      ENDIF
      oCtrl:lNoWhen := .F.
   ELSE
      oCtrl:oParent:lGetSkipLostFocus := .F.
   ENDIF

   RETURN .T.

FUNCTION WhenSetFocus( oCtrl, nSkip )

   IF  SelfFocus( oCtrl:Handle ) .OR. EMPTY( GetFocus() )
       GetSkip( oCtrl:oParent, oCtrl:handle, , nSkip )
   ENDIF
   RETURN Nil

FUNCTION GetWindowParent( nHandle )

   DO WHILE ! Empty( GetParent( nHandle ) ) .AND. ! SelfFocus( nHandle, GetActiveWindow() )
      nHandle := GetParent( nHandle )
   ENDDO
   RETURN PtrtouLong( nHandle )


FUNCTION ProcKeyList( oCtrl, wParam, oMain )
LOCAL oParent, nCtrl,nPos

   IF ( wParam = VK_RETURN .OR. wParam = VK_ESCAPE ) .AND. ProcOkCancel( oCtrl, wParam )
      RETURN .F.
   ENDIF
   IF wParam != VK_SHIFT  .AND. wParam != VK_CONTROL .AND. wParam != VK_MENU
      oParent := IIF( oMain != Nil, oMain, ParentGetDialog( oCtrl ) )
      IF oParent != Nil .AND. ! Empty( oParent:KeyList )
         nctrl := IIf( IsCtrlShift(.t., .f.), FCONTROL, iif(IsCtrlShift(.f., .t.), FSHIFT, 0 ) )
         IF ( nPos := AScan( oParent:KeyList, { | a | a[ 1 ] == nctrl.AND.a[ 2 ] == wParam } ) ) > 0
            Eval( oParent:KeyList[ nPos, 3 ], oCtrl )
            RETURN .T.
         ENDIF
      ENDIF
      IF oParent != Nil .AND. oMain = Nil .AND. HWindow():GetMain() != Nil
          ProcKeyList( oCtrl, wParam, HWindow():GetMain():aWindows[ 1 ] )
      ENDIF
   ENDIF
   RETURN .F.

FUNCTION ProcOkCancel( oCtrl, nKey, lForce )
   Local oWin := oCtrl:GetParentForm(), lEscape
   Local iParHigh := IIF( nKey = VK_RETURN, IDOK, IDCANCEL )
   LOCAL oCtrlFocu := oCtrl

   lForce := ! Empty( lForce )
   lEscape := nKey = VK_ESCAPE .AND. ( oCtrl := oWin:FindControl( IDCANCEL ) ) != Nil .AND. ! oCtrl:IsEnabled()
   IF ( ( oWin:Type >= WND_DLG_RESOURCE .AND. oWin:lModal) .AND. ! lForce .and. !lEscape )  .OR. ( nKey != VK_RETURN .AND. nKey != VK_ESCAPE )
      Return .F.
	 ENDIF
   IF iParHigh == IDOK
      IF ( oCtrl := oWin:FindControl( IDOK ) ) != Nil .AND. oCtrl:IsEnabled()
         oCtrl:SetFocus()
  	     oWin:lResult := .T.
  	     IF lForce
	       ELSEIF ISBLOCK( oCtrl:bClick ) .AND. ! lForce
	          SendMessage( oCtrl:oParent:handle, WM_COMMAND, makewparam( oCtrl:id, BN_CLICKED ), oCtrl:handle )
	       ELSEIF oWin:lExitOnEnter
            oWin:close()
         ELSE
            SendMessage( oWin:handle, WM_COMMAND, makewparam( IDOK, 0 ), oCtrlFocu:handle )      
         ENDIF
         RETURN .T.
      ENDIF
   ELSEIF iParHigh == IDCANCEL
      IF ( oCtrl := oWin:FindControl( IDCANCEL ) ) != Nil .AND. oCtrl:IsEnabled() 
         oCtrl:SetFocus()
         oWin:lResult := .F.
         SendMessage( oCtrl:oParent:handle, WM_COMMAND, makewparam( oCtrl:id, BN_CLICKED ), oCtrl:handle )
      ELSEIF oWin:lGetSkiponEsc
         oCtrl := oCtrlFocu
         IF oCtrl  != Nil .AND.  __ObjHasMsg( oCtrl, "OGROUP" )  .AND. oCtrl:oGroup:oHGroup != Nil
             oCtrl := oCtrl:oGroup:oHGroup
         ENDIF
         IF oCtrl  != Nil .and. GetSkip( oCtrl:oParent, oCtrl:Handle, , - 1 )
            IF AScan( oWin:GetList, { | o | o:handle == oCtrl:Handle } ) > 1
               RETURN .T.
            ENDIF
         ENDIF                                               
      ELSEIF oWin:lExitOnEsc
          oWin:close()
      ELSEIF ! oWin:lExitOnEsc
         oWin:nLastKey := 0
         SendMessage( oWin:handle, WM_COMMAND, makewparam( IDCANCEL, 0 ), oCtrlFocu:handle )
         RETURN .F.
      ENDIF
      RETURN .T.
   ENDIF
   RETURN .F.


FUNCTION FindAccelerator( oCtrl, lParam )
  Local nlen , i ,pos

  nlen := LEN( oCtrl:aControls )
  FOR i = 1 to nLen
	   IF oCtrl:aControls[ i ]:classname = "HTAB"
	      IF ( pos := FindTabAccelerator( oCtrl:aControls[ i ], lParam ) ) > 0 .AND. ;
        	  oCtrl:aControls[ i ]:Pages[ pos ]:Enabled
	          oCtrl:aControls[ i ]:SetTab( pos )
	          RETURN oCtrl:aControls[ i ]
	      ENDIF
	   ENDIF
     IF LEN(oCtrl:aControls[ i ]:aControls ) > 0
         RETURN FindAccelerator( oCtrl:aControls[ i ], lParam)
	   ENDIF
     IF __ObjHasMsg( oCtrl:aControls[ i ],"TITLE") .AND. VALTYPE( oCtrl:aControls[ i ]:title) = "C" .AND. ;
         ! oCtrl:aControls[ i ]:lHide .AND. IsWindowEnabled( oCtrl:aControls[ i ]:handle )
        IF ( pos := At( "&", oCtrl:aControls[ i ]:title ) ) > 0 .AND.  Upper( Chr( lParam)) ==  Upper( SubStr( oCtrl:aControls[ i ]:title, ++ pos, 1 ) )
           RETURN oCtrl:aControls[ i ]
        ENDIF
     ENDIF
   NEXT
   RETURN Nil

FUNCTION GetBackColorParent( oCtrl, lSelf, lTransparent )
   Local bColor := GetSysColor( COLOR_BTNFACE ), hTheme
   Local brush := nil

   DEFAULT lTransparent := .F.
   IF lSelf == Nil .OR. ! lSelf
      oCtrl := oCtrl:oParent
   ENDIF
   IF  oCtrl != Nil .AND. oCtrl:Classname = "HTAB"
       *-brush := HBrush():Add( bColor )
       IF Len( oCtrl:aPages ) > 0 .AND. oCtrl:Pages[ oCtrl:GETACTIVEPAGE() ]:bColor != Nil
          *-brush := oCtrl:Pages[ oCtrl:GetActivePage() ]:brush
          bColor := oCtrl:Pages[ oCtrl:GetActivePage() ]:bColor
       ELSEIF ISTHEMEACTIVE() .AND. oCtrl:WindowsManifest
          hTheme := hb_OpenThemeData( oCtrl:handle, "TAB" ) //oCtrl:oParent:WinClass )
          IF !EMPTY( hTheme )
             bColor := HWG_GETTHEMESYSCOLOR( hTheme, COLOR_WINDOW  )
             HB_CLOSETHEMEDATA( hTheme )
             *-brush := HBrush():Add( bColor )
          ENDIF
       ENDIF
   ELSEIF oCtrl:bColor != Nil
       *-brush := oCtrl:brush
       bColor := oCtrl:bColor
    *-ELSEIF oCtrl:brush = Nil .AND. lTransparent
    *-   brush := HBrush():Add( bColor )
   ENDIF
   brush := HBrush():Add( bColor ) 
   Return brush
