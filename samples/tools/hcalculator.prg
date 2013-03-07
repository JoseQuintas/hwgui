/*
 * $Id: hcalculator.prg
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HCalculator class
 *
 * Copyright 2012 LuisFernandoBasso <lfbasso@via-rs.net>
 *
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HCalculator

   CLASS VAR Hwnd SHARED
   DATA oFormCalc
   DATA oCurrGet
   DATA Title        INIT "Calculadora"
   DATA lDecimal
   DATA nResultado
   DATA cOperador
   DATA aOperando
   DATA lClear
   DATA nMemory
   DATA bColor        INIT hwg_Rgb( 255, 255, 255 )
   DATA nLeft         INIT 0
   DATA nTop          INIT 0
   DATA nWidth        INIT 196
   DATA nHeight       INIT 224
   DATA lCompacta     INIT .F.
   DATA Style, nFontSize

   METHOD New( cTitle, lCompacta, nLeft, nTop, nWidth, nHeight, bcolor )
   METHOD DefineStyle( lCompacta, nLeft, nTop, nWidth, nHeight, bcolor ) PROTECTED
   METHOD INIT( oCurrGet )
   METHOD Show( oGet, lCompacta, nLeft, nTop, nWidth, nHeight, bcolor  )
   METHOD Calculando( cNumero )
   METHOD GetRefresh( )
   METHOD End() INLINE  ::GetRefresh(), IIf( ::lCompacta, hwg_Postmessage( ::oFormCalc:Handle, WM_CLOSE, 0, 0 ),  )
ENDCLASS

METHOD New( cTitle, lCompacta, nLeft, nTop, nWidth, nHeight, bcolor ) CLASS HCalculator

   ::Title := IIF( cTitle == Nil, ::Title, cTitle )
   ::DefineStyle( lCompacta, nLeft, nTop, nWidth, nHeight, bcolor )

   RETURN Self

METHOD DefineStyle( lCompacta, nLeft, nTop, nWidth, nHeight, bcolor ) CLASS HCalculator
   LOCAL nStyle

   ::bColor    := IIf( bColor == Nil, ::bColor, bColor )
   ::lCompacta := IIf( lCompacta == Nil, ::lCompacta, lCompacta )
   ::nLeft     := IIf( nLeft == Nil, ::nLeft, nLeft )
   ::nTop      := IIf( nTop == Nil, ::nTop, nTop )

   ::Style := WS_POPUP + IIf( EMPTY( lCompacta ), WS_CAPTION + WS_SYSMENU + WS_SIZEBOX + ;
                        IIf( ::nLeft + ::nTop = 0, DS_CENTER, 0 ), DS_CONTROL + DS_MODALFRAME )
   ::nWidth := IIf( nWidth == Nil, ::nWidth, nWidth )
   ::nHeight :=  IIf( nHeight == Nil, ::nHeight, nHeight )

   RETURN Nil

METHOD Show( oGet, lCompacta, nLeft, nTop, nWidth, nHeight, bcolor  )  CLASS HCalculator

   LOCAL   oCnt1, oCalculo, oVisor, oBtn4, oBtn18, oBtn19, oBtn20 ;
        , oBtn9, oBtn16, oBtn17, oBtn15, oBtn8, oBtn12, oBtn13, oBtn14 ;
        , oBtn11, oBtn21, oBtn22, oBtn3, oBtn5, oBtn6 ;
        , oBtn7, oBtn10, obtnres, oBtn23, oMemory

   LOCAL hWin := hwg_Getactivewindow()
   ::oCurrGet := oGet
   ::DefineStyle( lCompacta, nLeft, nTop, nWidth, nHeight, bcolor )

   IF !::lCompacta .AND. ::Hwnd != Nil
      hwg_Setwindowpos( ::Hwnd, HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE + SWP_FRAMECHANGED )
      RETURN Nil
   ENDIF
   INIT DIALOG ::oFormCalc TITLE ::Title ;
        COLOR ::bColor ; //15852761  ;
        AT ::nLeft, ::nTop SIZE ::nWidth, ::nHeight ;
        FONT HFont():Add( 'Verdana',0,-13, 400,,,) NOEXIT  ;
     STYLE ::Style                          ;
     ON INIT {|This| ::Init( This, oGet ) } ;
     ON LOSTFOCUS {| | IIF( ::lCompacta, ::End(), .T. ) }  ;
     ON EXIT { | | ::Hwnd := Nil ,::GetRefresh( ) }

   ::oFormCalc:minHeight := 220
   ::oFormCalc:maxHeight := 258
   ::oFormCalc:minWidth  := 150

   @ 4,3 CONTAINER oCnt1 SIZE 190,58 ;
        STYLE 2;
         BACKCOLOR 16578289 ;
         BACKSTYLE 2
        oCnt1:Anchor := 75
   @ 156,189 BUTTONEX obtnres CAPTION "="   SIZE 34,28 ;
        STYLE BS_CENTER    ;
        FONT HFont():Add( 'Verdana',0,-16,700,,,) ;
        ON CLICK {|| ::Calculando( "=") }
        hwg_SetFontStyle( obtnres, .T. )  // obtnres:FontBold := .T.
   @ 119,189 BUTTONEX oBtn10 CAPTION "+"   SIZE 34,28 ;
        STYLE BS_CENTER   ;
        FONT HFont():Add( 'Verdana',0,-12,400,,,) ;
        ON CLICK {|| ::Calculando( "+") }
   @ 82,189 BUTTONEX oBtn7 CAPTION ","   SIZE 34,28 ;
        STYLE BS_CENTER   ;
        ON CLICK {|| ::Calculando( ",") }
   @ 8,189 BUTTONEX oBtn6 CAPTION "&0"   SIZE 72,28  ;
        STYLE BS_CENTER   ;
        ON CLICK {|| ::Calculando( "0") }
   @ 156,158 BUTTONEX oBtn11 CAPTION "%"   SIZE 34,28 ;
        STYLE BS_CENTER   ;
        FONT HFont():Add( 'Verdana',0,-12,400,,,) ;
        ON CLICK {|| ::Calculando( "%") }
   @ 119,158 BUTTONEX oBtn5 CAPTION "-"   SIZE 34,28 ;
        STYLE BS_CENTER   ;
        ON CLICK {|| ::Calculando( "-") }
   @ 82,158 BUTTONEX oBtn3 CAPTION "&3"   SIZE 34,28 ;
        STYLE BS_CENTER   ;
        ON CLICK {|| ::Calculando( "3") }
   @ 45,158 BUTTONEX oBtn2 CAPTION "&2"   SIZE 34,28 ;
        STYLE BS_CENTER   ;
        ON CLICK {|| ::Calculando( "2") }
   @ 8,158 BUTTONEX oBtn1 CAPTION "&1"   SIZE 34,28 ;
        STYLE BS_CENTER   ;
        ON CLICK {|| ::Calculando( "1") }
   @ 156,126 BUTTONEX oBtn23 CAPTION "&M+"   SIZE 34,28 ;
        STYLE BS_CENTER   ;
        FONT HFont():Add( 'Tahoma',0,-12,400,,,) ;
        ON CLICK {|| ::Calculando( "M+") }
   @ 119,127 BUTTONEX oBtn14 CAPTION "*"   SIZE 34,28 ;
        STYLE BS_CENTER   ;
        FONT HFont():Add( 'Symbol',0,-15,400,,,) ;
        ON CLICK {|| ::Calculando( "*") }
   @ 82,127 BUTTONEX oBtn13 CAPTION "&6"   SIZE 34,28 ;
        STYLE BS_CENTER   ;
        ON CLICK {|| ::Calculando( "6") }
   @ 45,127 BUTTONEX oBtn12 CAPTION "&5"   SIZE 34,28 ;
        STYLE BS_CENTER   ;
        ON CLICK {|| ::Calculando( "5") }
   @ 8,127 BUTTONEX oBtn8 CAPTION "&4"   SIZE 34,28 ;
        STYLE BS_CENTER   ;
        ON CLICK {|| ::Calculando( "4") }
   @ 156,96 BUTTONEX oBtn22 CAPTION "M&R"   SIZE 34,28 ;
        STYLE BS_CENTER   ;
        FONT HFont():Add( 'Tahoma',0,-12,400,,,) ;
        ON CLICK {|| ::Calculando( "MR") }
        oBtn22:Anchor := 224
   @ 119,96 BUTTONEX oBtn15 CAPTION "/"   SIZE 34,28 ;
        STYLE BS_CENTER   ;
        FONT HFont():Add( 'Verdana',0,-12,400,,,) ;
        ON CLICK {|| ::Calculando( "/") }
   @ 82,96 BUTTONEX oBtn17 CAPTION "&9"   SIZE 34,28 ;
        STYLE BS_CENTER   ;
        ON CLICK {|| ::Calculando( "9") }
   @ 45,96 BUTTONEX oBtn16 CAPTION "&8"   SIZE 34,28 ;
        STYLE BS_CENTER   ;
        ON CLICK {|| ::Calculando( "8") }
   @ 8,96 BUTTONEX oBtn9 CAPTION "&7"   SIZE 34,28 ;
        STYLE BS_CENTER   ;
        ON CLICK {|| ::Calculando( "7") }
   @ 156,65 BUTTONEX oBtn21 CAPTION "MC"   SIZE 34,28 ;
        STYLE BS_CENTER   ;
        FONT HFont():Add( 'Tahoma',0,-12,400,,,) ;
        ON CLICK {|| ::Calculando( "MC") }
        oBtn21:Anchor := 224
   @ 119,65 BUTTONEX oBtn20 CAPTION "&+"   SIZE 34,28 ;
        STYLE BS_MULTILINE+BS_CENTER   ;
        FONT HFont():Add( 'Tahoma',0,-12,400,,,) ;
        ON CLICK {|| ::Calculando( "#") }
   @ 82,65 BUTTONEX oBtn19 CAPTION "C"  ID IDCANCEL  SIZE 34,28 ;
        STYLE BS_CENTER   ;
        FONT HFont():Add( 'Tahoma',0,-12,400,,,) ;
        ON CLICK {|| ::Calculando( "") }
   @ 45,65 BUTTONEX oBtn18 CAPTION "CE"   SIZE 34,28 ;
        STYLE BS_CENTER   ;
        FONT HFont():Add( 'Tahoma',0,-12,400,,,) ;
        ON CLICK {|| ::Calculando( "C") }
   @ 8,65 BUTTONEX oBtn4 CAPTION "<--"   SIZE 34,28 ;
        STYLE BS_CENTER   ;
        FONT HFont():Add( 'System',0,-16,700,,,) ;
        ON CLICK {|| ::Calculando( " ")  }
        hwg_SetFontStyle( oBtn4, .T. ) // oBtn4:FontBold := .T.
   @ 21,24 SAY oVisor CAPTION "0"  SIZE 168,33 ;
        STYLE SS_RIGHT +DT_VCENTER+DT_SINGLELINE;
         BACKCOLOR 16578289  ;
        FONT HFont():Add( 'Consolas',0,-24,400,,,)
        oVisor:Anchor := 75
   @ 7,29 SAY oMemory CAPTION ""  SIZE 15,26 ;
        STYLE DT_VCENTER+DT_SINGLELINE;
         COLOR 6250335  BACKCOLOR 16578289  ;
        FONT HFont():Add( 'Arial',0,-13,700,,,)
        oMemory:Anchor := 75
        hwg_SetFontStyle( oMemory, .T. )  // oMemory:FontBold := .T.
   @ 7,6 SAY oCalculo CAPTION ""  SIZE 182,17 ;
        STYLE SS_RIGHT ;
         BACKCOLOR 16578289  ;
        FONT HFont():Add( 'Consolas',0,-12,400,,,)
        oCalculo:Anchor := 75

   ACTIVATE DIALOG ::oFormCalc NOMODAL

   ::nFontSize := hwg_TxtRect( "9", ::oFormCalc, ::oFormCalc:oCalculo:oFont )[ 1 ]
   ::Hwnd := ::oFormCalc:Handle

   RETURN 0


METHOD Calculando( cNumero ) CLASS HCalculator
   LOCAL oForm := ::oFormCalc
   Local nDiv := 1
   Local cOperar := ::cOperador
   Local nLen := Len( oForm:oVisor:Caption ), nCars
   Private nCalculo1 , ncalculo2

   IF hwg_IsCtrlShift( .F., .T. ) .AND. ( cNumero = "5" .OR. cNumero = "8" )
      cNumero := IIF( cNumero = "8", "*", IIF( cNumero = "5", "%", cNumero ) )
   ENDIF
   If cNumero $ "/*-+%="
      nCars := oForm:oCalculo:nWidth / ::nFontSize
      oForm:oCalculo:Caption += oForm:oVisor:Caption + " "+cNumero+" "
      oForm:oCalculo:Caption := RIGHT( oForm:oCalculo:Caption, nCars )
      ::cOperador := IIF( cNumero != "=", cNumero, ::cOperador )
      cOperar := IIF( cOperar = Nil, cNumero, cOperar )
      If ::aOperando[ 1 ] = Nil .AND. !::lClear
         ::aOperando[ 1 ] := Val( StrTran(oForm:oVisor:Caption,",",".") )
      ElseIf ::aOperando[ 2 ] = Nil .AND. ! ::lClear
         ::aOperando[ 2 ] := Val( StrTran(oForm:oVisor:Caption,",",".") )
      EndIf
      ::lClear := .T.
   ElseIf cNumero == "#"
      oForm:oVisor:Caption := iIf(oForm:oVisor:Caption = "-", SubStr(oForm:oVisor:Caption,2),"-"+oForm:oVisor:Caption)
      ::cOperador := cNumero
      If ::aOperando[ 2 ] != Nil
         ::aOperando[ 2 ] := Val( StrTran(oForm:oVisor:Caption,",",".") )
      ElseIf ::aOperando[ 1 ] != Nil
         ::aOperando[ 1 ] := Val( StrTran(oForm:oVisor:Caption,",",".") )
      EndIf
      ::lClear := .t.
   ElseIf cNumero == " "
      If !::lClear
         oForm:oVisor:Caption := Left( oForm:oVisor:Caption,nLen - 1 )
      EndIf
   ElseIf cNumero == "C"
      oForm:oVisor:Caption := "0"
      ::lClear := .t.
      ::aOperando[ 1 ] := IIf( ::aOperando[ 1 ] != Nil .and. ::aOperando[ 2 ] = nIL, ::aOperando[ 1 ], Nil )
      ::aOperando[ 2 ] := Nil //IIf( ::aOperando[ 2 ] = nIL, Nil, 0 )
      return nil
   ElseIf Empty( cNumero )
      oForm:oVisor:Caption := "0"
      oForm:oCalculo:Caption := ""
      ::lClear := .t.
      ::aOperando := {, , 0 }
      If ::oCurrGet != Nil
         ::End()
         RETURN Nil
      EndIf
   ElseIf cNumero == "MC"
      ::nMemory := 0
      oForm:oMemory:caption := " "
   ElseIf cNumero == "MR"
      oForm:oVisor:Caption := STR(::nMemory )
      ::lClear := .F.
   ElseIf cNumero == "M+"
      ::nMemory := Val( StrTran( oForm:oVisor:Caption,",",".") )
      oForm:oMemory:caption := "M"
   Else
      oForm:oVisor:Caption := IIf( ::lClear .OR. cOperar = "=","", oForm:oVisor:Caption )
      oForm:oVisor:Caption += cNumero
      ::lClear := .f.
      cOperar := ""
   EndIf

   If cNumero == "=" .And. (! Empty( ::aOperando[ 1 ]) .And. Empty( ::aOperando[ 2 ]) )
      ::aOperando[ 2 ] := ::aOperando[ 3 ]
   EndIf
   If ! Empty( cOperar ) .And. (! Empty( ::aOperando[ 1 ]) .And. ! Empty( ::aOperando[ 2 ]) )
      If ::cOperador == "%"
        ::aOperando[ 1 ] := (::aOperando[ 1 ] * ::aOperando[ 2 ] ) / 100
      Else
        nCalculo1 := ::aOperando[ 1 ]
        nCalculo2 := ::aOperando[ 2 ]
        ::aOperando[ 1 ] := &( "nCalculo1" + cOperar + "nCalculo2" )
      EndIf
      ::aOperando[ 1 ] := IIf( ::aOperando[ 1 ] - Int( ::aOperando[ 1 ] ) = 0 ,;
                          Int( ::aOperando[ 1 ]), ::aOperando[ 1 ] )
      oForm:oVisor:Caption := Ltrim( Str(::aOperando[ 1 ] ) )
      ::aOperando[ 3 ] := ::aOperando[ 2 ]
      ::aOperando[ 2 ] := Nil
      ::lClear := .T.
   EndIf
   If cNumero == "="
      oForm:oCalculo:Caption := ""
      If ::oCurrGet != Nil
         ::End()
         RETURN Nil
      EndIf
   EndIf
   oForm:oBtnRes:Setfocus( )

  Return Nil


METHOD INIT( ) CLASS HCalculator
   LOCAL aCoors

   hwg_SetDlgKey( ::oFormCalc ,,8,{|| ::Calculando( " ") })
   hwg_SetDlgKey( ::oFormCalc ,,46,{|| ::Calculando( "") })
   hwg_SetDlgKey( ::oFormCalc ,,110,{|| ::Calculando( ",") })
   hwg_SetDlgKey( ::oFormCalc ,,188,{|| ::Calculando( ",") })
   hwg_SetDlgKey( ::oFormCalc ,,190,{|| ::Calculando( ".") })
   hwg_SetDlgKey( ::oFormCalc ,,194,{|| ::Calculando( ".") })
   hwg_SetDlgKey( ::oFormCalc ,,106,{|| ::Calculando( "*") })
   hwg_SetDlgKey( ::oFormCalc ,,107,{|| ::Calculando( "+") })
   hwg_SetDlgKey( ::oFormCalc ,FSHIFT,187,{|| ::Calculando( "+") })
   hwg_SetDlgKey( ::oFormCalc ,,109,{|| ::Calculando( "-") })
   hwg_SetDlgKey( ::oFormCalc ,,189,{|| ::Calculando( "-") })
   hwg_SetDlgKey( ::oFormCalc ,,111,{|| ::Calculando( "/") })
   hwg_SetDlgKey( ::oFormCalc ,,193,{|| ::Calculando( "/") })
   hwg_SetDlgKey( ::oFormCalc ,,187,{|| ::Calculando( "=") })
   hwg_SetDlgKey( ::oFormCalc ,,13,{|| ::Calculando( "=") })

   ::lClear := .t.
   ::aOperando := { , , 0 }

   ::oFormCalc:hwg_SetAll( "anchor", 240, , "hbuttonex" )
  // ::oFormCalc:hwg_SetAll( "lflat", ::lCompacta, , "hbuttonex" )

   If ::oCurrGet != Nil
      ::oFormCalc:oVisor:Caption := ALLTRIM( STR( ::oCurrGet:Value ) )
      ::lClear := ::oFormCalc:oVisor:Caption = "0"
      IF ::oFormCalc:Type >= WND_DLG_RESOURCE
         aCoors := hwg_Getwindowrect( ::oCurrGet:handle )
      ELSE
         aCoors := { ::oCurrGet:oParent:nLeft + ::oCurrGet:nLeft + 8 , ;
          ::oCurrGet:oParent:nTop + ::oCurrGet:nTop + hwg_Getsystemmetrics( SM_CYCAPTION ) + 8, 0,0 }
      ENDIF
      aCoors[ 3 ] := IIF( ::lCompacta, MAX( 130, ::oCurrGet:nWidth + 8 ), ::nWidth )
      ::oFormCalc:Move( aCoors[ 1 ] + 1, aCoors[ 2 ] + ::oCurrGet:nHeight + 1 , aCoors[ 3 ], 180, 0 )
   EndIf
   ::oFormCalc:nInitFocus:= ::oFormCalc:oBtnRes

   RETURN Nil

METHOD GetRefresh( ) CLASS HCalculator
   LOCAL Value := ::aOperando[ 1 ]

   If ::oCurrGet != Nil
      If  Value != Nil
         ::oCurrGet:Value := Value
         //::oCurrGet:Setfocus()
      EndIf
   EndIf
   RETURN .T.

/* end */