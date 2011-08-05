/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HFormTmpl Class
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "hxml.ch"

#ifdef __XHARBOUR__
   #xtranslate HB_AT( < x, ... > ) => At( < x > )
#endif

#define  CONTROL_FIRST_ID   34000

// nando
STATIC coName
//
STATIC aClass := { "label", "button", "buttonex", "toolbutton", "checkbox",                   ;
       "radiobutton", "editbox", "group", "radiogroup",  ;
       "bitmap", "icon", "richedit", "datepicker", "updown", ;
       "combobox", "line", "toolbar", "panel", "ownerbutton",     ;
       "browse", "column", "monthcalendar", "trackbar", "page",      ;
       "tree", "status", "menu", "animation" ,             ;
       "progressbar", "shadebutton", "listbox", "gridex",  ;
       "timer", "link"                                   ;
     }
STATIC aCtrls := { ;
       "HStatic():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,ctooltip,TextColor,BackColor,lTransp)", ;
       "HButton():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,onClick,ctooltip,TextColor,BackColor)",  ;
       "HButtonex():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,onClick,ctooltip,TextColor,BackColor,hbmp,nBStyle,hIco )",  ;
       "AddButton(nBitIp,nId,nState,nStyle,cCaption,onClick,ctooltip,amenu)",  ;
       "HCheckButton():New(oPrnt,nId,lInitValue,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,onClick,ctooltip,TextColor,BackColor,bwhen)", ;
       "HRadioButton():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,onClick,ctooltip,TextColor,BackColor)", ;
       "HEdit():New(oPrnt,nId,cInitValue,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onSize,onPaint,onGetFocus,onLostFocus,ctooltip,TextColor,BackColor,cPicture,lNoBorder,nMaxLength,lPassword)", ;
       "HGroup():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,TextColor,BackColor)", ;
       "RadioNew(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,TextColor,BackColor,nInitValue,bSetGet)", ;
       "HSayBmp():New(oPrnt,nId,nLeft,nTop,nWidth,nHeight,Bitmap,lResource,onInit,onSize,ctooltip)", ;
       "HSayIcon():New(oPrnt,nId,nLeft,nTop,nWidth,nHeight,Icon,lResource,onInit,onSize,ctooltip)", ;
       "HRichEdit():New(oPrnt,nId,cInitValue,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onSize,onPaint,onGetFocus,onLostFocus,ctooltip,TextColor,BackColor)", ;
       "HDatePicker():New(oPrnt,nId,dInitValue,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onGetFocus,onLostFocus,onChange,ctooltip,TextColor,BackColor)", ;
       "HUpDown():New(oPrnt,nId,nInitValue,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onSize,onPaint,onGetFocus,onLostFocus,ctooltip,TextColor,BackColor,nUpDWidth,nLower,nUpper)", ;
       "HComboBox():New(oPrnt,nId,nInitValue,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,Items,oFont,onInit,onSize,onPaint,onChange,cTooltip,lEdit,lText,bWhen,TextColor,BackColor)", ;
       "HLine():New(oPrnt,nId,lVertical,nLeft,nTop,nLength,onSize)", ;
       "HToolBar():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,onInit,onSize,onPaint,,,,,,,Items)", ;
       "HPanel():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,onInit,onSize,onPaint,lDocked)", ;
       "HOwnButton():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,onInit,onSize,onPaint,onClick,flat,caption,TextColor,oFont,TextLeft,TextTop,widtht,heightt,BtnBitmap,lResource,BmpLeft,BmpTop,widthb,heightb,lTr,trColor,cTooltip)", ;
       "Hbrowse():New(BrwType,oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onSize,onPaint,onEnter,onGetfocus,onLostfocus,lNoVScroll,lNoBorder,lAppend,lAutoedit,onUpdate,onKeyDown,onPosChange,lMultiSelect)", ;
       "AddColumn(HColumn():New(cHeader,Fblock,cValType,nLength,nDec,lEdit,nJusHead, nJusLine, cPicture,bValid, bWhen, Items, ClrBlck, HeadClick ))", ;  //oBrw:AddColumn
       "HMonthCalendar():New(oPrnt,nId,dInitValue,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onChange,cTooltip,lNoToday,lNoTodayCircle,lWeekNumbers)", ;
       "HTrackBar():New(oPrnt,nId,nInitValue,nStyle,nLeft,nTop,nWidth,nHeight,onInit,onSize,bPaint,cTooltip,onChange,onDrag,nLow,nHigh,lVertical,TickStyle,TickMarks)", ;
       "HTab():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onSize,onPaint,Tabs,onChange,aImages,lResource)", ;
       "HTree():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onSize,TextColor,BackColor,aImages,lResource,lEditLabels,onTreeClick)", ;
       "HStatus():New(oPrnt,nId,nStyle,oFont,aParts,onInit,onSize)", ;
       ".F.", ;
       "HAnimation():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,Filename,AutoPlay,Center,Transparent)", ;
       "HProgressBar():New( oPrnt,nId,nLeft,nTop,nWidth,nHeight,maxPos,nRange,bInit,bSize,bPaint,ctooltip )", ;
       "HshadeButton():New( oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,onInit,onSize,onPaint,onClick,lFlat,caption,color,font,xt,yt,bmp,lResour,xb,yb,widthb,heightb,lTr,trColor,cTooltip,lEnabled,shadeID,palette,granularity,highlight,coloring,shcolor)", ;
       "HListBox():New(oPrnt,nId,nInitValue,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,Items,oFont,onInit,onSize,onPaint,onChange,cTooltip)", ;
       "HGridEx():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onSize,onPaint,onEnter,onGetfocus,onLostfocus,lNoVScroll,lNoBorder,onKeyDown,onPosChg,onDispInfo,nItemCout,lNoLines,TextColor,BackColor,lNoHeader,aBit,Items)" , ;
       "HTimer():New(oPrnt,nId,nInterval, onAction)" , ;
       "HStaticLink():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,cTooltip,TextColor,BackColor,lTransp,Link,VisitedColor,LinkColor,HoverColor)" ;
     }

STATIC aPenType  := { "SOLID", "DASH", "DOT", "DASHDOT", "DASHDOTDOT" }
STATIC aJustify  := { "Left", "Center", "Right" }
STATIC aShadeID := { "SHS_METAL", "SHS_SOFTBUMP", "SHS_NOISE", "SHS_HARDBUMP", "SHS_HSHADE", "SHS_VSHADE", "SHS_DIAGSHADE", "SHS_HBUMP" }
STATIC aPalette := { "PAL_DEFAULT", "PAL_METAL" }

REQUEST HSTATIC
REQUEST HBUTTON
REQUEST HBUTTONEX
REQUEST HCHECKBUTTON
REQUEST HRADIOBUTTON
REQUEST HEDIT
REQUEST HGROUP
REQUEST HSAYBMP
REQUEST HSAYICON
REQUEST HRICHEDIT
REQUEST HDATEPICKER
REQUEST HUPDOWN
REQUEST HCOMBOBOX
REQUEST HLINE
REQUEST HTOOLBAR
REQUEST HPANEL
REQUEST HOWNBUTTON
REQUEST HBROWSE
REQUEST HCOLUMN
REQUEST HMONTHCALENDAR
REQUEST HTRACKBAR
REQUEST HTAB
REQUEST HANIMATION
REQUEST HTREE
REQUEST HPROGRESSBAR
REQUEST HSHADEBUTTON
REQUEST HLISTBOX
REQUEST HGRIDEX
REQUEST HTIMER
REQUEST HSTATICLINK

REQUEST Directory

REQUEST DBUseArea
REQUEST RecNo
REQUEST DBSkip
REQUEST DBGoTop
REQUEST DBCloseArea

CLASS HCtrlTmpl

   DATA cClass
   DATA oParent
   DATA nId
   DATA aControls INIT { }
   DATA aProp, aMethods

   METHOD New( oParent )   INLINE ( ::oParent := oParent, AAdd( oParent:aControls, Self ), Self )
   METHOD F( nId )
ENDCLASS

METHOD F( nId ) CLASS HCtrlTmpl
   LOCAL i, aControls := ::aControls, nLen := Len( aControls ), o

   FOR i := 1 TO nLen
      IF aControls[ i ]:nId == nId
         RETURN aControls[ i ]
      ELSEIF ! Empty( aControls[ i ]:aControls ) .AND. ( o := aControls[ i ]:F( nId ) ) != Nil
         RETURN o
      ENDIF
   NEXT

   RETURN Nil


CLASS HFormTmpl

CLASS VAR aForms   INIT { }
CLASS VAR maxId    INIT 0
   DATA oDlg
   DATA aControls     INIT { }
   DATA oParent
   DATA aProp
   DATA aMethods
   DATA aVars         INIT { }
   DATA aNames        INIT { }
   DATA aFuncs
   DATA id
   DATA cId
   DATA nContainer    INIT 0
   DATA nCtrlId       INIT CONTROL_FIRST_ID
   DATA lDebug        INIT .F.
   DATA cargo

   METHOD Read( fname, cId )
   METHOD Show( nMode, p1, p2, p3 )
   METHOD ShowMain( params )   INLINE ::Show( 1, params )
   METHOD ShowModal( params )  INLINE ::Show( 2, params )
   METHOD Close()
   METHOD F( id, n )
   METHOD Find( cId )

ENDCLASS

METHOD Read( fname, cId ) CLASS HFormTmpl
   LOCAL oDoc
   LOCAL i, j, nCtrl := 0, aItems, o, aProp := { }, aMethods := { }
   LOCAL cPre, cName, pp

   IF cId != Nil .AND. ( o := HFormTmpl():Find( cId ) ) != Nil
      RETURN o
   ENDIF
   IF Left( fname, 5 ) == "<?xml"
      oDoc := HXMLDoc():ReadString( fname )
   ELSE
      oDoc := HXMLDoc():Read( fname )
   ENDIF

   IF Empty( oDoc:aItems )
      MsgStop( "Can't open " + fname )
      RETURN Nil
   ELSEIF oDoc:aItems[ 1 ]:title != "part" .OR. oDoc:aItems[ 1 ]:GetAttribute( "class" ) != "form"
      MsgStop( "Form description isn't found" )
      RETURN Nil
   ENDIF

   ::maxId ++
   ::id := ::maxId
   ::cId := cId
   ::aProp := aProp
   ::aMethods := aMethods

   pp := __pp_init()
   AAdd( ::aForms, Self )
   aItems := oDoc:aItems[ 1 ]:aItems
   FOR i := 1 TO Len( aItems )
      IF aItems[ i ]:title == "style"
         FOR j := 1 TO Len( aItems[ i ]:aItems )
            o := aItems[ i ]:aItems[ j ]
            IF o:title == "property"
               IF ! Empty( o:aItems )
                  AAdd( aProp, { Lower( o:GetAttribute( "name" ) ), o:aItems[ 1 ] } )
                  IF Atail(aProp)[1] == "ldebug" .AND. hfrm_GetProperty( Atail(aProp)[2] )
                     ::lDebug := .T.
                     SetDebugInfo( .T. )
                  ENDIF
               ENDIF
            ENDIF
         NEXT
      ELSEIF aItems[ i ]:title == "method"
         Aadd( aMethods, { cName := Lower(aItems[i]:GetAttribute("name")),CompileMethod(pp,aItems[i]:aItems[1]:aItems[1],Self,,cName) } )
         IF aMethods[ ( j := Len( aMethods ) ), 1 ] == "common"
            ::aFuncs := ::aMethods[ j, 2, 2 ]
            FOR j := 1 TO Len( ::aFuncs[ 2 ] )
               cPre := "#xtranslate " + ::aFuncs[ 2, j, 1 ] + ;
                       "( <params,...> ) => callfunc('"  + ;
                                                      Upper( ::aFuncs[ 2, j, 1 ] ) + "',\{ <params> \}, oDlg:oParent:aFuncs )"
               __pp_process( pp, cPre )
               cPre := "#xtranslate " + ::aFuncs[ 2, j, 1 ] + ;
                       "() => callfunc('"  + ;
                                        Upper( ::aFuncs[ 2, j, 1 ] ) + "',, oDlg:oParent:aFuncs )"
               __pp_process( pp, cPre )
            NEXT
         ENDIF
      ELSEIF aItems[ i ]:title == "part"
         nCtrl ++
         ::nContainer := nCtrl
         ReadCtrl( pp, aItems[ i ], Self, Self )
      ENDIF
   NEXT
   pp := NIL
   SetDebugInfo( .F. )
   RETURN Self

METHOD Show( nMode, p1, p2, p3 ) CLASS HFormTmpl
   LOCAL i, j, cType
   LOCAL nLeft, nTop, nWidth, nHeight, cTitle, oFont, lClipper := .F., lExitOnEnter := .F.
   LOCAL xProperty, block, bFormExit, nstyle
   LOCAL lModal := .f.
   LOCAL lMdi := .F.
   LOCAL lMdiChild := .f.
   LOCAL cBitmap := nil
   LOCAL oBmp := NIL
   MEMVAR oDlg
   PRIVATE oDlg

   SetDebugInfo( ::lDebug )
   SetDebugger( ::lDebug )
   nstyle := DS_ABSALIGN + WS_VISIBLE + WS_SYSMENU + WS_SIZEBOX

   FOR i := 1 TO Len( ::aProp )
      xProperty := hfrm_GetProperty( ::aProp[ i, 2 ] )

      IF ::aProp[ i, 1 ] == "geometry"
         nLeft   := Val( xProperty[ 1 ] )
         nTop    := Val( xProperty[ 2 ] )
         nWidth  := Val( xProperty[ 3 ] )
         nHeight := Val( xProperty[ 4 ] )
      ELSEIF ::aProp[ i, 1 ] == "caption"
         cTitle := xProperty
      ELSEIF ::aProp[ i, 1 ] == "font"
         oFont := hfrm_FontFromxml( xProperty )
      ELSEIF ::aProp[ i, 1 ] == "lclipper"
         lClipper := xProperty
      ELSEIF ::aProp[ i, 1 ] == "lexitonenter"
         lExitOnEnter := xProperty
      ELSEIF ::aProp[ i, 1 ] == "exstyle"
         nstyle := xProperty
      ELSEIF ::aProp[ i, 1 ] == "modal"
         lModal := xProperty
      ELSEIF ::aProp[ i, 1 ] == "formtype"
         IF nMode == Nil
            lMdi := At( "mdimain", Lower( xProperty ) ) > 0
            lMdiChild := At( "mdichild", Lower( xProperty ) ) > 0
            nMode := IF( Left( xProperty, 3 ) == "dlg", 2, 1 )
         ENDIF
      ELSEIF ::aProp[ i, 1 ] == "variables"
         FOR j := 1 TO Len( xProperty )
            __mvPrivate( xProperty[ j ] )
         NEXT
         // Styles below
      ELSEIF ::aProp[ i, 1 ] == "systemmenu"
         IF ! xProperty
            nstyle := hwg_bitandinverse( nstyle, WS_SYSMENU )
         ENDIF
      ELSEIF ::aProp[ i, 1 ] == "minimizebox"
         IF xProperty
            nstyle += WS_MINIMIZEBOX
         ENDIF
      ELSEIF ::aProp[ i, 1 ] == "maximizebox"
         IF xProperty
            nstyle += WS_MAXIMIZEBOX
         ENDIF
      ELSEIF ::aProp[ i, 1 ] == "absalignent"
         IF ! xProperty
            nstyle := hwg_bitandinverse( nstyle, DS_ABSALIGN )
         ENDIF
      ELSEIF ::aProp[ i, 1 ] == "sizeBox"
         IF ! xProperty
            nstyle := hwg_bitandinverse( nstyle, WS_SIZEBOX )
         ENDIF
      ELSEIF ::aProp[ i, 1 ] == "visible"
         IF ! xProperty
            nstyle := hwg_bitandinverse( nstyle, WS_VISIBLE )
         ENDIF
      ELSEIF ::aProp[ i, 1 ] == "3dLook"
         IF xProperty
            IF ::aControls[ j ]:cClass == "button" .OR. ::aControls[ j ]:cClass == "ownerbutton"
               nstyle += DS_3DLOOK
            ELSE
               nstyle += IIf( ::aControls[ j ]:cClass = "checkbox", BS_PUSHLIKE, 0 )
            ENDIF
         ENDIF
      ELSEIF ::aProp[ i, 1 ] == "clipsiblings"
         IF xProperty
            nstyle += WS_CLIPSIBLINGS
         ENDIF
      ELSEIF ::aProp[ i, 1 ] == "clipchildren"
         IF xProperty
            nstyle += WS_CLIPCHILDREN
         ENDIF
      ELSEIF ::aProp[ i, 1 ] == "fromstyle"
         IF Lower( xProperty ) == "popup"
            nstyle += WS_POPUP + WS_CAPTION
         ELSEIF Lower( xProperty ) == "child"
            nstyle += WS_CHILD
         ENDIF

      ELSEIF ::aProp[ i, 1 ] == "bitmap"
         cBitmap := xProperty
      ENDIF
   NEXT

   FOR i := 1 TO Len( ::aNames )
      __mvPrivate( ::aNames[ i ] )
   NEXT
   FOR i := 1 TO Len( ::aVars )
      __mvPrivate( ::aVars[ i ] )
   NEXT


   oBmp := IF( ! Empty( cBitmap ), HBitmap():addfile( cBitmap, NIL ), NIL )

   IF nMode == Nil .OR. nMode == 2
      INIT DIALOG ::oDlg TITLE cTitle         ;
           At nLeft, nTop SIZE nWidth, nHeight ;
           STYLE nstyle ;
           FONT oFont ;
           BACKGROUND BITMAP oBmp
      ::oDlg:lClipper := lClipper
      ::oDlg:lExitOnEnter := lExitOnEnter
      ::oDlg:oParent  := Self

   ELSEIF nMode == 1

      IF lMdi
         INIT WINDOW ::oDlg MDI TITLE cTitle    ;
              At nLeft, nTop SIZE nWidth, nHeight ;
              STYLE IF( nstyle > 0 , nstyle, NIL ) ;
              FONT oFont ;
              BACKGROUND BITMAP oBmp
      ELSEIF lMdiChild
         INIT WINDOW ::oDlg  MDICHILD TITLE cTitle    ;
              At nLeft, nTop SIZE nWidth, nHeight ;
              STYLE IF( nstyle > 0 , nstyle, NIL ) ;
              FONT oFont ;
              BACKGROUND BITMAP oBmp
      ELSE
         INIT WINDOW ::oDlg MAIN TITLE cTitle    ;
              At nLeft, nTop SIZE nWidth, nHeight ;
              FONT oFont ;
              BACKGROUND BITMAP oBmp ;
              STYLE IF( nstyle > 0 , nstyle, NIL )

      ENDIF
   ENDIF

   oDlg := ::oDlg

   FOR i := 1 TO Len( ::aMethods )
      IF ( cType := ValType( ::aMethods[ i, 2 ] ) ) == "B"
         block := ::aMethods[ i, 2 ]
      ELSEIF cType == "A"
         block := ::aMethods[ i, 2, 1 ]
      ENDIF
      IF ::aMethods[ i, 1 ] == "ondlginit"
         ::oDlg:bInit := block
      ELSEIF ::aMethods[ i, 1 ] == "onforminit"
         Eval( block, Self, p1, p2, p3 )
      ELSEIF ::aMethods[ i, 1 ] == "onpaint"
         ::oDlg:bPaint := block
      ELSEIF ::aMethods[ i, 1 ] == "ondlgexit"
         ::oDlg:bDestroy := block
      ELSEIF ::aMethods[ i, 1 ] == "onformexit"
         bFormExit := block
      ENDIF
   NEXT

   j := Len( ::aControls )
   IF j > 0 .AND. ::aControls[ j ]:cClass == "status"
      CreateCtrl( ::oDlg, ::aControls[ j ], Self )
      j --
   ENDIF
   // nando
   IF j > 0 .AND. ::aControls[ j ]:cClass == "timer"
      CreateCtrl( ::oDlg, ::aControls[ j ], Self )
      j --
   ENDIF
   // nando

   FOR i := 1 TO j
      CreateCtrl( ::oDlg, ::aControls[ i ], Self )
   NEXT

   IF ::lDebug .AND. ( i := HWindow():GetMain() ) != Nil
      SetFocus( i:handle )
   ENDIF
   ::oDlg:Activate( lModal )

   IF bFormExit != Nil
      RETURN Eval( bFormExit )
   ENDIF

   RETURN Nil

METHOD F( id, n ) CLASS HFormTmpl
   LOCAL i := AScan( ::aForms, { | o | o:id == id } )

   IF i != 0 .AND. n != Nil
      RETURN ::aForms[ i ]:aControls[ n ]
   ENDIF
   RETURN IIf( i == 0, Nil, ::aForms[ i ] )

METHOD Find( cId ) CLASS HFormTmpl
   LOCAL i := AScan( ::aForms, { | o | o:cId != Nil.and.o:cId == cId } )
   RETURN IIf( i == 0, Nil, ::aForms[ i ] )

METHOD Close() CLASS HFormTmpl
   LOCAL i := AScan( ::aForms, { | o | o:id == ::id } )

   IF i != 0
      ADel( ::aForms, i )
      ASize( ::aForms, Len( ::aForms ) - 1 )
   ENDIF
   RETURN Nil

// ------------------------------

STATIC FUNCTION ReadTree( pp, oForm, aParent, oDesc )
   LOCAL i, aTree := { }, oNode, subarr

   FOR i := 1 TO Len( oDesc:aItems )
      oNode := oDesc:aItems[ i ]
      IF oNode:Type == HBXML_TYPE_CDATA
         aParent[ 1 ] := CompileMethod( pp, oNode:aItems[ 1 ], oForm )
      ELSE
         AAdd( aTree, { Nil, oNode:GetAttribute( "name" ), ;
                        Val( oNode:GetAttribute( "id" ) ), .T. } )
         IF ! Empty( oNode:aItems )
            IF ( subarr := ReadTree( pp, oForm, ATail( aTree ), oNode ) ) != Nil
               aTree[ Len( aTree ), 1 ] := subarr
            ENDIF
         ENDIF
      ENDIF
   NEXT

   RETURN IIf( Empty( aTree ), Nil, aTree )

FUNCTION ParseMethod( cMethod )
   LOCAL arr := { }, nPos1, nPos2, cLine

   IF ( nPos1 := At( Chr(10),cMethod ) ) == 0
      Aadd( arr, RTrim( cMethod ) )
   ELSE
      Aadd( arr, RTrim( Left( cMethod,nPos1-1 ) ) )
      DO WHILE .T.
         IF ( nPos2 := hb_At( Chr( 10 ), cMethod, nPos1 + 1 ) ) == 0
            cLine := AllTrim( SubStr( cMethod, nPos1 + 1 ) )
         ELSE
            cLine := AllTrim( SubStr( cMethod, nPos1 + 1, nPos2 - nPos1 - 1 ) )
         ENDIF
         IF ! Empty( cLine )
            AAdd( arr, cLine )
         ENDIF
         IF nPos2 == 0 .OR. Len( arr ) > 2
            EXIT
         ELSE
            nPos1 := nPos2
         ENDIF
      ENDDO
   ENDIF
   IF Right( arr[ 1 ], 1 ) < " "
      arr[ 1 ] := Left( arr[ 1 ], Len( arr[ 1 ] ) - 1 )
   ENDIF
   IF Len( arr ) > 1 .AND. Right( arr[ 2 ], 1 ) < " "
      arr[ 2 ] := Left( arr[ 2 ], Len( arr[ 2 ] ) - 1 )
   ENDIF

   RETURN arr

STATIC FUNCTION CompileMethod( pp, cMethod, oForm, oCtrl, cName )
   LOCAL arr, arrExe, nContainer := 0, cCode1, cCode, bOldError, bRes, cParam, nPos

   IF cMethod = Nil .OR. Empty( cMethod )
      Return Nil
   ENDIF
   IF oCtrl != Nil .AND. Left( oCtrl:oParent:Classname(),2 ) == "HC"
      // writelog( oCtrl:cClass+" "+oCtrl:oParent:cClass+" "+ oCtrl:oParent:oParent:Classname() )
      nContainer := oForm:nContainer
   ENDIF
   IF Asc( cMethod ) <= 32
      cMethod := Ltrim( cMethod )
   ENDIF
   IF Lower( Left( cMethod ,11 ) ) == "parameters " .AND. ;
         ( nPos := At( Chr(10),cMethod ) ) != 0
      DO WHILE Substr( cMethod, --nPos, 1 ) <= ' '; ENDDO
      cParam := Alltrim( Substr( Left( cMethod,nPos ), 12 ) )
   ENDIF
   IF oForm:lDebug
      arr := {}
   ELSE
      arr := ParseMethod( cMethod )
   ENDIF
   IF Len( arr ) == 1
      cCode := Iif( Lower( Left(arr[1],6) ) == "return", Ltrim( Substr( arr[1],8 ) ), arr[1] )
      bOldError := ERRORBLOCK( {|e|CompileErr(e,cCode)} )
      BEGIN SEQUENCE
         bRes := &( "{||" + __pp_process( pp, cCode ) + "}" )
      END SEQUENCE
      ERRORBLOCK( bOldError )
      Return bRes
   ELSEIF !Empty(arr) .AND. !Empty( cParam )
      IF Len( arr ) == 2
         cCode := Iif( Lower( Left(arr[2],6) ) == "return", Ltrim( Substr( arr[2],8 ) ), arr[2] )
         cCode := "{|" + cParam + "|" + __pp_process( pp, cCode ) + "}"
         bOldError := ERRORBLOCK( {|e|CompileErr(e,cCode)} )
         BEGIN SEQUENCE
            bRes := &cCode
         END SEQUENCE
         ERRORBLOCK( bOldError )
         Return bRes
      ELSE
         cCode1 := Iif( nContainer==0, ;
               "aControls["+Ltrim(Str(Len(oForm:aControls)))+"]", ;
               "F("+Ltrim(Str(oCtrl:nId))+")" )
         arrExe := Array(2)
         arrExe[2] := RdScript( ,cMethod,1,.T.,cName )
         cCode :=  "{|" + cParam + ;
            "|DoScript(HFormTmpl():F("+Ltrim(Str(oForm:id))+Iif(nContainer!=0,","+Ltrim(Str(nContainer)),"")+"):" + ;
            Iif( oCtrl==Nil,"aMethods["+Ltrim(Str(Len(oForm:aMethods)+1))+",2,2],{", ;
                   cCode1+":aMethods["+ ;
                   Ltrim(Str(Len(oCtrl:aMethods)+1))+",2,2],{" ) + ;
                   cParam + "})" + "}"
         arrExe[1] := &cCode
         Return arrExe
      ENDIF
   ENDIF

   cCode1 := Iif( nContainer==0, ;
         "aControls["+Ltrim(Str(Len(oForm:aControls)))+"]", ;
         "F("+Ltrim(Str(oCtrl:nId))+")" )
   arrExe := Array(2)
   arrExe[2] := RdScript( ,cMethod,,.T.,cName )
   cCode := "{|" + Iif( Empty(cParam),"",cParam ) + ;
      "|DoScript(HFormTmpl():F("+Ltrim(Str(oForm:id))+Iif(nContainer!=0,","+Ltrim(Str(nContainer)),"")+"):" + ;
      Iif( oCtrl==Nil,"aMethods["+Ltrim(Str(Len(oForm:aMethods)+1))+",2,2]" + ;
             Iif( Empty(cParam),"",",{"+cParam+"}" ) + ")", ;
             cCode1+":aMethods["+   ;
             Ltrim(Str(Len(oCtrl:aMethods)+1))+",2,2]" + ;
             Iif( Empty(cParam),"",",{"+cParam+"}" ) + ")" ) + "}"
   arrExe[1] := &cCode

   RETURN arrExe

STATIC PROCEDURE CompileErr( e, stroka )

   MsgStop( ErrorMessage( e ) + Chr( 10 ) + Chr( 13 ) + "in" + Chr( 10 ) + Chr( 13 ) + ;
            AllTrim( stroka ), "Script compiling error" )
   BREAK( nil )

STATIC FUNCTION ReadCtrl( pp, oCtrlDesc, oContainer, oForm )
   LOCAL oCtrl := HCtrlTmpl():New( oContainer )
   LOCAL i, j, o, cName, aProp := { }, aMethods := { }, aItems := oCtrlDesc:aItems

   oCtrl:nId      := oForm:nCtrlId
   oForm:nCtrlId ++
   oCtrl:cClass   := oCtrlDesc:GetAttribute( "class" )
   oCtrl:aProp    := aProp
   oCtrl:aMethods := aMethods

   FOR i := 1 TO Len( aItems )
      IF aItems[ i ]:title == "style"
         FOR j := 1 TO Len( aItems[ i ]:aItems )
            o := aItems[ i ]:aItems[ j ]
            IF o:title == "property"
               IF ( cName := Lower( o:GetAttribute( "name" ) ) ) == "varname"
                  AAdd( oForm:aVars, hfrm_GetProperty( o:aItems[ 1 ] ) )
               ELSEIF cName == "name"
                  AAdd( oForm:aNames, hfrm_GetProperty( o:aItems[ 1 ] ) )
               ENDIF
               IF cName == "atree"
                  AAdd( aProp, { cName, ReadTree( pp, oForm,, o ) } )
               ELSE
                  AAdd( aProp, { cName, IIf( Empty( o:aItems ), "", o:aItems[ 1 ] ) } )
               ENDIF
            ENDIF
         NEXT
      ELSEIF aItems[ i ]:title == "method"
         Aadd( aMethods, { cName := Lower(aItems[i]:GetAttribute("name")),CompileMethod(pp,aItems[i]:aItems[1]:aItems[1],oForm,oCtrl,cName) } )
      ELSEIF aItems[ i ]:title == "part"
         ReadCtrl( pp, aItems[ i ], oCtrl, oForm )
      ENDIF
   NEXT

   RETURN Nil

   #define TBS_AUTOTICKS                1
   #define TBS_TOP                      4
   #define TBS_BOTH                     8
   #define TBS_NOTICKS                 16

STATIC FUNCTION CreateCtrl( oParent, oCtrlTmpl, oForm )
   LOCAL i, j, temp, oCtrl, stroka, varname, xProperty, cType, cPName
   LOCAL nCtrl := AScan( aClass, oCtrlTmpl:cClass ), xInitValue, cInitName, cVarName
// LOCAL DE NANDO BROWSE
   LOCAL cAliasdbf, caArray, nHeadRows := 1, nFootRows := 0, lDispHead := .T., lDispSep := .T., lSep3d := .F., ladjright := .T.
   LOCAL nheadColor := 0, nsepColor := 12632256, nLeftCol := 0, nfreeze := 0, nColumns := 0
   #ifdef __XHARBOUR__
      LOCAL cKey := "" , cRelexpr := "", cLink := ""
   #else
      LOCAL cKey := ""
   #endif
//
   MEMVAR oPrnt, nId, nStyle, nLeft, nTop
   MEMVAR onInit, lNoVScroll, lAppend, lAutoedit
   MEMVAR nWidth, nHeight, oFont, lNoBorder, bSetGet, ctoolTip
   MEMVAR name, nLength, lVertical, brwType, TickStyle, TickMarks, Tabs, tmp_nSheet
   MEMVAR aParts
   MEMVAR lEnabled, shadeID, palette, granularity, highlight, coloring, shcolor
// nando
   MEMVAR fBlock, cHeader, nJusHead, lEdit, nJusLine, bWhen, bValid, ClrBlck, HeadClick
   MEMVAR cValType, nDec, cPicture, lNoLines, lNoHeader, lMultiSelect, Items, nInterval, onAction
   MEMVAR nBitIp, nState, onClick, amenu, ccaption, hbmp, nBStyle, hIco

//

   #ifndef __XHARBOUR__
      MEMVAR cLink, cRelexpr
      PRIVATE cLink := ""
      PRIVATE cRelexpr := ""
   #endif
   PUBLIC coName
   IF nCtrl == 0
      IF Lower( oCtrlTmpl:cClass ) == "pagesheet"
         tmp_nSheet ++
         oParent:StartPage( Tabs[ tmp_nSheet ] )
         FOR i := 1 TO Len( oCtrlTmpl:aControls )
            CreateCtrl( oParent, oCtrlTmpl:aControls[ i ], oForm )
         NEXT
         oParent:EndPage()
      ENDIF
      RETURN Nil
   ENDIF

   /* Declaring of variables, which are in the appropriate 'New()' function */
   stroka := aCtrls[ nCtrl ]
   IF ( i := At( "New(", stroka ) ) != 0
      i += 4
      DO WHILE .T.
         IF ( j := hb_At( ",", stroka, i ) ) != 0 .OR. ( j := hb_At( ")", stroka, i ) ) != 0
            IF j - i > 0
               varname := SubStr( stroka, i, j - i )
               __mvPrivate( varname )
               IF SubStr( varname, 2 ) == "InitValue"
                  cInitName  := varname
                  xInitValue := IIf( Left( varname, 1 ) == "n", 1, IIf( Left( varname, 1 ) == "c", "", .F. ) )
               ENDIF
               stroka := Left( stroka, i - 1 ) + "m->" + SubStr( stroka, i )
               i := j + 4
            ELSE
               i := j + 1
            ENDIF
         ELSE
            EXIT
         ENDIF
      ENDDO
   ENDIF
   oPrnt  := oParent
   nId    := oCtrlTmpl:nId
   nStyle := 0
   shadeID := 0
   lEnabled := .T.
   // nando
   lAppend   := .F.
   lAutoedit := .F.
   lMultiSelect := .F.
   lNoLines  := .F.
   lNoHeader := .F.
   lNoBorder := .F.
   lNoVScroll := .F.
   // columns
   //cValType := "C"
   caArray := { }
   nLength := Nil
   nDec := 0
   nJusHead := 0
   nJusLine := 0
   lEdit    := .F.
   cPicture := Nil
   Items := { }
   nInterval := 0
   onAction := Nil
   bWhen := Nil
   bValid := Nil
   ClrBlck := Nil
   HeadClick := Nil
   // toolbar
   ccaption := ""
   nBitIp := 0
   nState := 4
   onClick := Nil
   ctoolTip := ""
   amenu := ""
   //
   palette :=  PAL_METAL
   granularity := 0
   highlight := 0
   coloring := 0
   shcolor := 0

   FOR i := 1 TO Len( oCtrlTmpl:aProp )
      xProperty := hfrm_GetProperty( oCtrlTmpl:aProp[ i, 2 ] )
      cPName := oCtrlTmpl:aProp[ i, 1 ]
      //msginfo(cpname)
      IF cPName == "geometry"
         nLeft   := Val( xProperty[ 1 ] )
         nTop    := Val( xProperty[ 2 ] )
         nWidth  := Val( xProperty[ 3 ] )
         nHeight := Val( xProperty[ 4 ] )
         IF __ObjHasMsg( oParent, "ID" )
            nLeft -= oParent:nLeft
            nTop -= oParent:nTop
            IF __ObjHasMsg( oParent:oParent, "ID" )
               nLeft -= oParent:oParent:nLeft
               nTop -= oParent:oParent:nTop
            ENDIF
         ENDIF
      ELSEIF cPName == "font"
         oFont := hfrm_FontFromxml( xProperty )
      ELSEIF cPName == "border"
         IF xProperty
            nStyle += WS_BORDER
         ELSE
            lNoBorder := .T.
         ENDIF
      ELSEIF cPName == "justify"
         nStyle += IIf( xProperty == "Center", SS_CENTER, IIf( xProperty == "Right", SS_RIGHT, 0 ) )
      ELSEIF cPName == "multiline" .or. cPName == "wordwrap"
         IF xProperty
            nStyle += ES_MULTILINE
         ENDIF
      ELSEIF cPName == "password"
         IF xProperty
            nStyle += ES_PASSWORD
         ENDIF
      ELSEIF cPName == "autohscroll"
         IF xProperty
            nStyle += ES_AUTOHSCROLL + IIf( oCtrlTmpl:cClass == "browse", WS_HSCROLL, 0 )
         ENDIF
      ELSEIF cPName == "autovscroll"
         IF xProperty
            nStyle += ES_AUTOVSCROLL
         ENDIF
      ELSEIF cPName == "3dlook"
         IF xProperty
            IF oCtrlTmpl:cClass == "button" .OR. oCtrlTmpl:cClass == "ownerbutton"
               nStyle += DS_3DLOOK
            ELSE
               nStyle += IIf( oCtrlTmpl:cClass = "checkbox", BS_PUSHLIKE, 0 )
            ENDIF
         ENDIF
      ELSEIF cPName == "effect"
         shadeID := AScan( aShadeID, xProperty ) - 1
      ELSEIF cPName == "palette"
         palette := AScan( aPalette, xProperty ) - 1
      ELSEIF cPName == "vscroll"
         IF xProperty
            nStyle += WS_VSCROLL
         ENDIF
         // nando layout
      ELSEIF cPName == "alignment"
         nStyle += IIf( xProperty == "top", BS_TOP, IIf( xProperty == "bottom", BS_BOTTOM, 0 ) )
         nStyle += IIf( "right" $ xProperty, BS_RIGHTBUTTON, 0 )
      ELSEIF cPName == "layout"
         nStyle += Val( xProperty )
      ELSEIF cPName == "checked"
         IF xProperty
            nStyle += 1
         ENDIF
      ELSEIF cPName == "taborientation" //array="0-Top,2-Bottom,128-Left,129-Right">
         nStyle += Val( xProperty )
      ELSEIF cPName == "tabstretch" //array="0-Single Row,1-Multiple Rows">
         nStyle += Val( xProperty )
         // NANDO
      ELSEIF cPName == "bitmap" .AND. oCtrlTmpl:cClass == "buttonex"
         hbmp := HBitmap():addfile( Trim( xProperty ) )
         hbmp := hbmp:handle
      ELSEIF cPName == "icon" .AND. oCtrlTmpl:cClass == "buttonex"
         hIco := HIcon():addfile( xProperty, NIL )
      ELSEIF cPName == "pictureposition"
         nBStyle := Val( xProperty )
      ELSEIF cPName == "style"
         nStyle += xProperty
      ELSEIF cPName == "state"
         nState := xProperty
      ELSEIF cPName == "header"
         IF xProperty
            lNoHeader := .T.
         ENDIF
      ELSEIF cPName == "gridlines"
         IF xProperty
            lNoLines  := .T.
         ENDIF
      ELSEIF cPName == "append"
         IF xProperty
            lAppend   := .F.
         ENDIF
      ELSEIF cPName == "autoedit"
         IF xProperty
            lAutoedit := .F.
         ENDIF
      ELSEIF cPName == "multiselect"
         IF xProperty
            lMultiSelect := .T.
         ENDIF
      ELSEIF cPName == "interval"
         nInterval := xProperty
         // browse - colunas
         //  "cOName:AddColumn(HColumn():New(cHeader,block,cType,nLen,nDec,lEdit,nJusHead, nJusLine, cPicture,bValid, bWhen, Items, bClrBlck, bHeadClick ))",;  //oBrw:AddColumn
         //ELSEIF cPName == "brwtype"
         //  brwtype := xProperty
      ELSEIF cPName == "aarray"
         caArray := IIf( xProperty != Nil .AND. ! Empty( xProperty ), &( xProperty ) , { } )
      ELSEIF cPName == "childorder"
         cKey := IIf( xProperty != Nil .AND. ! Empty( xProperty ), Trim( xProperty ), "" )
      ELSEIF cPName == "relationalexpr"
         cRelexpr := IIf( xProperty != Nil .AND. ! Empty( xProperty ), Trim( xProperty ), "" )
      ELSEIF cPName == "linkmaster"
         cLink := IIf( xProperty != Nil .AND. ! Empty( xProperty ), Trim( xProperty ), "" )
      ELSEIF cPName == "filedbf"
         IF ! Empty( xProperty )
            cAliasdbf := Left( CutPath( xProperty ), At( ".", CutPath( xProperty ) ) - 1 )
            IF Select( Left( CutPath( xProperty ), At( ".", CutPath( xProperty ) ) - 1 ) ) = 0
               USE ( xProperty ) NEW SHARED Alias ( Left( CutPath( xProperty ), At( ".", CutPath( xProperty ) ) - 1 ) )  //ftmp
            ENDIF
            Select ( Left( CutPath( xProperty ), At( ".", CutPath( xProperty ) ) - 1 ) )
         ENDIF
      ELSEIF cPName == "columnscount"
         nColumns :=  xProperty
      ELSEIF cPName == "columnsfreeze"
         nfreeze := xProperty
      ELSEIF cPName == "headrows"
         nHeadRows := xProperty
      ELSEIF cPName == "footerrows"
         nFootRows := xProperty
      ELSEIF cPName == "showheader"
         lDispHead := xProperty
      ELSEIF cPName == "showgridlinessep"
         lDispSep := xProperty
      ELSEIF cPName == "gridlinessep3d"
         lSep3d := xProperty
      ELSEIF cPName == "headtextcolor"
         nheadColor := xProperty
      ELSEIF cPName == "gridlinessepcolor"
         nsepColor := xProperty
      ELSEIF cPName == "leftcol"
         nLeftCol := xProperty
      ELSEIF cPName == "adjright"
         ladjright := xProperty
         // COLUNAS
      ELSEIF cPName == "heading"
         cHeader := IIf( xProperty != Nil , xProperty , "" )
      ELSEIF cPName == "fieldname"
         fBlock  := Lower( IIf( xProperty != Nil .AND. ! Empty( xProperty ), xProperty , FieldName( i ) ) )
      ELSEIF cPName == "fieldexpr"
         fBlock  := Lower( IIf( xProperty != Nil .AND. ! Empty( xProperty ), xProperty , fBlock ) )
         // IF !(cAlias == cTmpAlias) .AND. cTmpAlias $ cCampo
         //    cCampo := STRTRAN(cCampo,cTmpAlias,cAlias)
         //   ENDIF
      ELSEIF cPName == "length"
         nLength :=   xProperty  //iif(xProperty != Nil,xProperty,10)
      ELSEIF cPName == "picture"
         cPicture := IIf( Empty( xProperty ), Nil, xProperty )
      ELSEIF cPName == "editable"
         lEdit := xProperty
      ELSEIF cPName == "justifyheader"
         nJusHead := Val( xProperty )
      ELSEIF cPName == "justifyline"
         nJusLine := Val( xProperty )
         // fim de column
         // toolbutton
      ELSEIF cPName == "caption" .AND.oCtrlTmpl:cClass = "toolbutton"
         ccaption := xProperty
         // FiM NANDO
      ELSEIF cPName == "atree"
         BuildMenu( xProperty, oForm:oDlg:handle, oForm:oDlg )
      ELSE
         IF cPName == "tooltip"
            cPName := "c" + cPName
         ELSEIF cPName == "name"
            __mvPrivate( cPName )
            cOName := IIf( oCtrlTmpl:cClass = "browse" .OR. oCtrlTmpl:cClass = "toolbar", xProperty , cOName )
         ENDIF
         /* Assigning the value of the property to the variable with
         the same name as the property */
         __mvPut( cPName, xProperty )

         IF cPName == "varname" .AND. ! Empty( xProperty )
            cVarName := xProperty
            bSetGet := &( "{|v|Iif(v==Nil," + xProperty + "," + xProperty + ":=v)}" )
            IF __mvGet( xProperty ) == Nil
               /* If the variable with 'varname' name isn't initialized
               while onFormInit procedure, we assign her the init value */
                  __mvPut( xProperty, xInitValue )
               ELSEIF cInitName != Nil
               /* If it is initialized, we assign her value to the 'init'
                  variable ( cInitValue, nInitValue, ... ) */
                  __mvPut( cInitName, __mvGet( xProperty ) )
               ENDIF
            ELSEIF SubStr( cPName, 2 ) == "initvalue"
               xInitValue := xProperty
            ENDIF
         ENDIF
      NEXT
      FOR i := 1 TO Len( oCtrlTmpl:aMethods )
         IF ( cType := ValType( oCtrlTmpl:aMethods[ i, 2 ] ) ) == "B"
            __mvPut( oCtrlTmpl:aMethods[ i, 1 ], oCtrlTmpl:aMethods[ i, 2 ] )
         ELSEIF cType == "A"
            __mvPut( oCtrlTmpl:aMethods[ i, 1 ], oCtrlTmpl:aMethods[ i, 2, 1 ] )
         ENDIF
      NEXT

      // NANDO
      IF oCtrlTmpl:cClass == "updown"
         bSetGet := IIf( bSetGet == Nil, '1', bSetGet )
      ENDIF
      //
      IF oCtrlTmpl:cClass == "combobox"
         IF ( AScan( oCtrlTmpl:aProp, { | a | Lower( a[ 1 ] ) == "nmaxlines" } ) ) > 0
          *-  nHeight := nHeight * nMaxLines
         ELSE
          *-  nHeight := nHeight * 4
         ENDIF
      ELSEIF oCtrlTmpl:cClass == "line"
         nLength := IIf( lVertical == Nil.OR. ! lVertical, nWidth, nHeight )
      ELSEIF oCtrlTmpl:cClass == "browse"
         brwType := IIf( brwType == Nil .OR. brwType == "dbf", BRW_DATABASE, BRW_ARRAY )
      ELSEIF oCtrlTmpl:cClass == "trackbar"
         IF TickStyle == Nil .OR. TickStyle == "auto"
            TickStyle := TBS_AUTOTICKS
         ELSEIF TickStyle == "none"
            TickStyle := TBS_NOTICKS
         ELSE
            TickStyle := 0
         ENDIF
         IF TickMarks == Nil .OR. TickMarks == "bottom"
            TickMarks := 0
         ELSEIF TickMarks == "both"
            TickMarks := TBS_BOTH
         ELSE
            TickMarks := TBS_TOP
         ENDIF
      ELSEIF oCtrlTmpl:cClass == "status"
         IF aParts != Nil
            FOR i := 1 TO Len( aParts )
               aParts[ i ] := Val( aParts[ i ] )
            NEXT
         ENDIF
         onInit := { | o | o:Move(,, o:nWidth - 1 ) }
      ENDIF
      // criacao
      IF oCtrlTmpl:cClass == "column"
         cValType := Type( "&fblock" )
         IF &( cOName ):Type = BRW_DATABASE .AND. ! Empty( Alias() )
            cAliasdbf := Alias()
            temp = StrTran( Upper( fBlock ), Alias() + "->", "" )
       *- verificar se tem mais de um campo
            temp = SubStr( temp, 1, IIf( At( '+', temp ) > 0, At( '+', temp ) - 1, Len( temp ) ) )
            j := { }
            AEval( &cAliasdbf->( ( DBStruct() ) ), { | aField | AAdd( j, aField[ 1 ] ) } )
            IF m->nLength = Nil
               // m->nLength := &cTmpAlias->(fieldlen(ascan(j,temp)))
               // m->nLength := IIF(m->nLength = 0 ,IIF(type("&cCampo") = "C",LEN(&cCampo),10),m->nLength)
               m->nLength := &cAliasdbf->( fieldlen( AScan( j, temp ) ) )
               m->nLength := IIf( m->nLength = 0 , IIf( Type( "&fblock" ) = "C", Len( &fBlock ), 10 ), m->nLength )
            ENDIF
            m->nDec := &cAliasdbf->( FIELDDEC( AScan( j, temp ) ) )
            cHeader  := IIf( cHeader == Nil .OR. Empty( cHeader ) , temp, cHeader )
            fBlock   := { || &fBlock }
         ELSE  //IF brwtype = 1
            m->nLength := IIf( m->nLength = Nil , 10, m->nLength )
            fBlock := IIf( fBlock = Nil, ".T.", fBlock )
            fBlock := IIf( cValType = "B", &fBlock, { || &fBlock } )
         ENDIF
         IF ! Empty( cPicture ) .AND. At( ".9", cPicture ) > 0 .AND. nDec = 0
            m->nDec := Len( SubStr( cPicture, At( ".9", cPicture ) + 1 ) )
         ENDIF
         stroka   := cOName + ":" + stroka
      ENDIF
      IF oCtrlTmpl:cClass == "toolbutton"
         stroka   := cOName + ":" + stroka
      ENDIF
      oCtrl := &stroka
      IF oCtrlTmpl:cClass == "browse"
         oCtrl:aColumns := { }
         oCtrl:freeze := nfreeze
         oCtrl:nHeadRows := nHeadRows
         oCtrl:nFootRows := nFootRows
         oCtrl:lDispHead := lDispHead
         oCtrl:lDispSep := lDispSep
         oCtrl:lSep3d := lSep3d
         oCtrl:headColor := nheadColor
         oCtrl:sepColor := nsepColor
         oCtrl:nLeftCol := nLeftCol
         oCtrl:ladjright := ladjright
      */
         oCtrl:nColumns := nColumns
         oCtrl:Type := brwType
         IF brwType = BRW_DATABASE          //oCtrl:type = 1
            // CRIAR AS RELA€OES E O LINK
            oCtrl:Alias := cAliasdbf
            IF ! Empty( cKey )
               &( oCtrl:Alias ) ->( DBSetOrder( cKey ) )
               cKey := ( oCtrl:Alias ) ->( ordkey( cKey ) )
               cKey := IIf( At( '+', cKey ) > 0, Left( cKey, At( '+', cKey ) - 1 ), cKey )
            ENDIF
            cRelexpr := IIf( ! Empty( cRelexpr ), cRelexpr, cKey )
            IF ! Empty( cRelexpr + cLink )
               &cLink->( DBSetRelation( oCtrl:Alias, { || &cRelexpr }, cRelexpr ) )
               &( oCtrl:Alias ) ->( DBSetFilter( &( "{|| " + cRelexpr + " = " + cLink + "->(" + cRelexpr + ")}" ), "&crelexpr = &clink->(&crelexpr) " ) )
            ENDIF
            // fim dos relacionamentos
            IF Empty( oCtrlTmpl:aControls )
               Select ( oCtrl:Alias )
               j := ( DBStruct() )
               //AEVAL( aStruct, {|aField| QOUT(aField[DBS_NAME])} )
               FOR i := 1 TO IIf( oCtrl:nColumns = 0, FCount(), oCtrl:nColumns )
                  //"AddColumn(HColumn():New(cHeader,Fblock,cValType,nLength,nDec,lEdit,nJusHead, nJusLine, cPicture,bValid, bWhen, Items, bClrBlck, bHeadClick ))",;  //oBrw:AddColumn
                  m->cHeader := FieldName( i )
                  m->fBlock := FieldBlock( FieldName( i ) )
                  m->cValType := j[ i, 2 ]  //TYPE("FieldName(i)")
                  m->nLength := j[ i, 3 ] //len(&(FieldName(i)))
                  m->nDec := j[ i, 4 ]
                  m->cPicture := Nil
                  lEdit := .t.
                  oCtrl:AddColumn( HColumn():New( cHeader, fBlock, cValType, nLength, nDec, lEdit ) )
               NEXT
            ENDIF
         ELSE
            oCtrl:aArray := caArray  //IIF(TYPE("caArray")="C",&(caArray),caArray)
            oCtrl:AddColumn( HColumn():New( , { | v, o | IIf( v != Nil, o:aArray[ o:nCurrent ] := v, o:aArray[ o:nCurrent ] ) }, 'C', 100, 0 ) )
         ENDIF
      ENDIF
      IF cVarName != Nil
         oCtrl:cargo := cVarName
      ENDIF
      IF Type( "m->name" ) == "C"
         // writelog( oCtrlTmpl:cClass+" "+name )
         __mvPut( name, oCtrl )
         name := Nil
      ENDIF
      IF ! Empty( oCtrlTmpl:aControls )
         IF oCtrlTmpl:cClass == "page"
            __mvPrivate( "tmp_nSheet" )
            __mvPut( "tmp_nSheet", 0 )
         ENDIF
         FOR i := 1 TO Len( oCtrlTmpl:aControls )
            CreateCtrl( IIf( oCtrlTmpl:cClass == "group".OR.oCtrlTmpl:cClass == "radiogroup", oParent, oCtrl ), oCtrlTmpl:aControls[ i ], oForm )
         NEXT
         IF oCtrlTmpl:cClass == "radiogroup"
            HRadioGroup():EndGroup()
         ENDIF
      ENDIF

      RETURN Nil

   FUNCTION RadioNew( oPrnt, nId, nStyle, nLeft, nTop, nWidth, nHeight, caption, oFont, onInit, onSize, onPaint, TextColor, BackColor, nInitValue, bSetGet )
      LOCAL oCtrl := HGroup():New( oPrnt, nId, nStyle, nLeft, nTop, nWidth, nHeight, caption, oFont, onInit, onSize, onPaint, TextColor, BackColor )
      HRadioGroup():New( nInitValue, bSetGet )
      RETURN oCtrl


   FUNCTION Font2XML( oFont )
      LOCAL aAttr := { }

      AAdd( aAttr, { "name", oFont:name } )
      AAdd( aAttr, { "width", LTrim( Str( oFont:width, 5 ) ) } )
      AAdd( aAttr, { "height", LTrim( Str( oFont:height, 5 ) ) } )
      IF oFont:weight != 0
         AAdd( aAttr, { "weight", LTrim( Str( oFont:weight, 5 ) ) } )
      ENDIF
      IF oFont:charset != 0
         AAdd( aAttr, { "charset", LTrim( Str( oFont:charset, 5 ) ) } )
      ENDIF
      IF oFont:Italic != 0
         AAdd( aAttr, { "italic", LTrim( Str( oFont:Italic, 5 ) ) } )
      ENDIF
      IF oFont:Underline != 0
         AAdd( aAttr, { "underline", LTrim( Str( oFont:Underline, 5 ) ) } )
      ENDIF

      RETURN HXMLNode():New( "font", HBXML_TYPE_SINGLE, aAttr )

   FUNCTION hfrm_FontFromXML( oXmlNode )
      LOCAL width  := oXmlNode:GetAttribute( "width" )
      LOCAL height := oXmlNode:GetAttribute( "height" )
      LOCAL weight := oXmlNode:GetAttribute( "weight" )
      LOCAL charset := oXmlNode:GetAttribute( "charset" )
      LOCAL ita   := oXmlNode:GetAttribute( "italic" )
      LOCAL under := oXmlNode:GetAttribute( "underline" )

      IF width != Nil
         width := Val( width )
      ENDIF
      IF height != Nil
         height := Val( height )
      ENDIF
      IF weight != Nil
         weight := Val( weight )
      ENDIF
      IF charset != Nil
         charset := Val( charset )
      ENDIF
      IF ita != Nil
         ita := Val( ita )
      ENDIF
      IF under != Nil
         under := Val( under )
      ENDIF

      RETURN HFont():Add( oXmlNode:GetAttribute( "name" ),  ;
                          width, height, weight, charset,   ;
                          ita, under )

   FUNCTION hfrm_Str2Arr( stroka )
      LOCAL arr := { }, pos1 := 2, pos2 := 1

      IF Len( stroka ) > 2
         DO WHILE pos2 > 0
            DO WHILE SubStr( stroka, pos1, 1 ) <= ' ' ; pos1 ++ ; ENDDO
            pos2 := hb_At( ',', stroka, pos1 )
            AAdd( arr, Trim( SubStr( stroka, pos1, IIf( pos2 > 0, pos2 - pos1, hb_At( '}', stroka, pos1 ) - pos1 ) ) ) )
            pos1 := pos2 + 1
         ENDDO
      ENDIF

      RETURN arr

   FUNCTION hfrm_Arr2Str( arr )
      LOCAL stroka := "{", i, cType

      FOR i := 1 TO Len( arr )
         IF i > 1
            stroka += ","
         ENDIF
         cType := ValType( arr[ i ] )
         IF cType == "C"
            stroka += arr[ i ]
         ELSEIF cType == "N"
            stroka += LTrim( Str( arr[ i ] ) )
         ENDIF
      NEXT

      RETURN stroka + "}"

   FUNCTION hfrm_GetProperty( xProp )
      LOCAL c

      IF ValType( xProp ) == "C"
         c := Left( xProp, 1 )
         IF c == "["
            xProp := SubStr( xProp, 2, Len( xProp ) - 2 )
         ELSEIF c == "."
            xProp := ( SubStr( xProp, 2, 1 ) == "T" )
         ELSEIF c == "{"
            xProp := hfrm_Str2Arr( xProp )
         ELSE
            xProp := Val( xProp )
         ENDIF
      ENDIF

      RETURN xProp

// ---------------------------------------------------- //

   CLASS HRepItem

      DATA cClass
      DATA oParent
      DATA aControls INIT { }
      DATA aProp, aMethods
      DATA oPen, obj
      DATA lPen INIT .F.
      DATA y2
      DATA lMark INIT .F.

      METHOD New( oParent )   INLINE ( ::oParent := oParent, AAdd( oParent:aControls, Self ), Self )
   ENDCLASS

CLASS HRepTmpl

CLASS VAR aReports INIT { }
CLASS VAR maxId    INIT 0
   DATA aControls     INIT { }
   DATA aProp
   DATA aMethods
   DATA aVars         INIT { }
   DATA aFuncs
   DATA lDebug        INIT .F.
   DATA id
   DATA cId

   DATA nKoefX, nKoefY, nKoefPix
   DATA nTOffset, nAOffSet, ny
   DATA lNextPage, lFinish
   DATA oPrinter

   METHOD Read( fname, cId )
   METHOD Print( printer, lPreview, p1, p2, p3 )
   METHOD PrintItem( oItem )
   METHOD ReleaseObj( aControls )
   METHOD Find( cId )
   METHOD Close()

ENDCLASS

METHOD Read( fname, cId ) CLASS HRepTmpl
   LOCAL oDoc
   LOCAL i, j, aItems, o, aProp := { }, aMethods := { }
   LOCAL cPre, cName, pp

   IF cId != Nil .AND. ( o := HFormTmpl():Find( cId ) ) != Nil
      RETURN o
   ENDIF

   IF Left( fname, 5 ) == "<?xml"
      oDoc := HXMLDoc():ReadString( fname )
   ELSE
      oDoc := HXMLDoc():Read( fname )
   ENDIF

   IF Empty( oDoc:aItems )
      MsgStop( "Can't open " + fname )
      RETURN Nil
   ELSEIF oDoc:aItems[ 1 ]:title != "part" .OR. oDoc:aItems[ 1 ]:GetAttribute( "class" ) != "report"
      MsgStop( "Report description isn't found" )
      RETURN Nil
   ENDIF

   ::maxId ++
   ::id := ::maxId
   ::cId := cId
   ::aProp := aProp
   ::aMethods := aMethods

   pp := __pp_init()
   AAdd( ::aReports, Self )
   aItems := oDoc:aItems[ 1 ]:aItems
   FOR i := 1 TO Len( aItems )
      IF aItems[ i ]:title == "style"
         FOR j := 1 TO Len( aItems[ i ]:aItems )
            o := aItems[ i ]:aItems[ j ]
            IF o:title == "property"
               IF ! Empty( o:aItems )
                  AAdd( aProp, { Lower( o:GetAttribute( "name" ) ), hfrm_GetProperty( o:aItems[ 1 ] ) } )
                  IF Atail(aProp)[1] == "ldebug" .AND. hfrm_GetProperty( Atail(aProp)[2] )
                     ::lDebug := .T.
                     SetDebugInfo( .T. )
                  ENDIF
               ENDIF
            ENDIF
         NEXT
      ELSEIF aItems[ i ]:title == "method"
         Aadd( aMethods, { cName := Lower(aItems[i]:GetAttribute("name")),RdScript(,aItems[i]:aItems[1]:aItems[1],,.T.,cName) } )
         IF aMethods[ ( j := Len( aMethods ) ), 1 ] == "common"
            ::aFuncs := ::aMethods[ j, 2 ]
            FOR j := 1 TO Len( ::aFuncs[ 2 ] )
               cPre := "#xtranslate " + ::aFuncs[ 2, j, 1 ] + ;
                       "( <params,...> ) => callfunc('"  + ;
                                                      Upper( ::aFuncs[ 2, j, 1 ] ) + "',\{ <params> \}, oReport:aFuncs )"
               __pp_process( pp, cPre )
               cPre := "#xtranslate " + ::aFuncs[ 2, j, 1 ] + ;
                       "() => callfunc('"  + ;
                                        Upper( ::aFuncs[ 2, j, 1 ] ) + "',, oReport:aFuncs )"
               __pp_process( pp, cPre )
            NEXT
         ENDIF
      ELSEIF aItems[ i ]:title == "part"
         ReadRepItem( aItems[ i ], Self )
      ENDIF
   NEXT
   pp := NIL
   SetDebugInfo( .F. )
   RETURN Self

METHOD Print( printer, lPreview, p1, p2, p3 ) CLASS HRepTmpl
   LOCAL oPrinter := IIf( printer != Nil, IIf( ValType( printer ) == "O", printer, HPrinter():New( printer, .T. ) ), HPrinter():New(, .T. ) )
   LOCAL i, j, aMethod, xProperty, oFont, xTemp, nPWidth, nPHeight, nOrientation := 1

   MEMVAR oReport
   PRIVATE oReport := Self

   IF oPrinter == Nil
      RETURN Nil
   ENDIF
   SetDebugInfo( ::lDebug )
   SetDebugger( ::lDebug )

   FOR i := 1 TO Len( ::aProp )
      IF ::aProp[ i, 1 ] == "paper size"
         IF Lower( ::aProp[ i, 2 ] ) == "a4"
            nPWidth  := 210
            nPHeight := 297
         ELSEIF Lower( ::aProp[ i, 2 ] ) == "a3"
            nPWidth  := 297
            nPHeight := 420
         ENDIF
      ELSEIF ::aProp[ i, 1 ] == "orientation"
         IF Lower( ::aProp[ i, 2 ] ) != "portrait"
            xTemp    := nPWidth
            nPWidth  := nPHeight
            nPHeight := xTemp
            nOrientation := 2
         ENDIF
      ELSEIF ::aProp[ i, 1 ] == "font"
         xProperty := ::aProp[ i, 2 ]
      ELSEIF ::aProp[ i, 1 ] == "variables"
         FOR j := 1 TO Len( ::aProp[ i, 2 ] )
            __mvPrivate( ::aProp[ i, 2 ][ j ] )
         NEXT
      ENDIF
   NEXT
   xTemp := GetDeviceArea( oPrinter:hDCPrn )
   ::nKoefPix := ( ( xTemp[ 1 ] / xTemp[ 3 ] + xTemp[ 2 ] / xTemp[ 4 ] ) / 2 ) / 3.8
   oPrinter:SetMode( nOrientation )
   ::nKoefX := oPrinter:nWidth / nPWidth
   ::nKoefY := oPrinter:nHeight / nPHeight
   IF ( aMethod := aGetSecond( ::aMethods, "onrepinit" ) ) != Nil
      DoScript( aMethod, { p1, p2, p3 } )
   ENDIF
   IF xProperty != Nil
      oFont := hrep_FontFromxml( oPrinter, xProperty, aGetSecond( ::aProp, "fonth" ) * ::nKoefY )
   ENDIF

   oPrinter:StartDoc( lPreview )
   ::lNextPage := .F.

   ::lFinish := .T.
   ::oPrinter := oPrinter
   DO WHILE .T.

      oPrinter:StartPage()
      IF oFont != Nil
         oPrinter:SetFont( oFont )
      ENDIF
      ::nTOffset := ::nAOffSet := ::ny := 0
      // Writelog( "Print-1 "+ str(oPrinter:nPage) )
      FOR i := 1 TO Len( ::aControls )
         ::PrintItem( ::aControls[ i ] )
      NEXT
      oPrinter:EndPage()
      IF ::lFinish
         EXIT
      ENDIF
   ENDDO

   oPrinter:EndDoc()
   ::ReleaseObj( ::aControls )
   IF ( aMethod := aGetSecond( ::aMethods, "onrepexit" ) ) != Nil
      DoScript( aMethod )
   ENDIF
   IF lPreview != Nil .AND. lPreview
      oPrinter:Preview()
   ENDIF
   oPrinter:END()

   RETURN Nil

METHOD PrintItem( oItem ) CLASS HRepTmpl
   LOCAL aMethod, lRes := .T., i, nPenType, nPenWidth
   LOCAL x, y, x2, y2, cText, nJustify, xProperty, nLines, dy, nFirst, ny

   MEMVAR lLastCycle, lSkipItem

   IF oItem:cClass == "area"
      cText := aGetSecond( oItem:aProp, "areatype" )
      IF cText == "DocHeader"
         IF ::oPrinter:nPage > 1
            ::nAOffSet := Val( aGetSecond( oItem:aProp, "geometry" )[ 4 ] ) * ::nKoefY
            RETURN Nil
         ENDIF
      ELSEIF cText == "DocFooter"
         IF ::lNextPage
            RETURN Nil
         ENDIF
      ELSEIF cText == "Table" .AND. ::lNextPage
         PRIVATE lSkipItem := .T.
      ENDIF
   ENDIF
   IF ! __mvExist( "LSKIPITEM" ) .OR. ! lSkipItem
      IF ( aMethod := aGetSecond( oItem:aMethods, "onbegin" ) ) != Nil
         DoScript( aMethod )
      ENDIF
      IF ( aMethod := aGetSecond( oItem:aMethods, "condition" ) ) != Nil
         lRes := DoScript( aMethod )
         IF ! lRes .AND. oItem:cClass == "area"
            ::nAOffSet += Val( aGetSecond( oItem:aProp, "geometry" )[ 4 ] ) * ::nKoefY
         ENDIF
      ENDIF
   ENDIF
   IF lRes
      xProperty := aGetSecond( oItem:aProp, "geometry" )
      x   := Val( xProperty[ 1 ] ) * ::nKoefX
      y   := Val( xProperty[ 2 ] ) * ::nKoefY
      x2  := Val( xProperty[ 5 ] ) * ::nKoefX
      y2  := Val( xProperty[ 6 ] ) * ::nKoefY
      // writelog( xProperty[1]+" "+xProperty[2] )

      IF oItem:cClass == "area"
         oItem:y2 := y2
         // writelog( "Area: "+cText+" "+Iif(::lNextPage,"T","F") )
         IF ( xProperty := aGetSecond( oItem:aProp, "varoffset" ) ) == Nil ;
              .OR. ! xProperty
            ::nTOffset := ::nAOffSet := 0
         ENDIF
         IF cText == "Table"
            PRIVATE lLastCycle := .F.
            ::lFinish := .F.
            DO WHILE ! lLastCycle
               ::ny := 0
               FOR i := 1 TO Len( oItem:aControls )
                  IF ! ::lNextPage .OR. oItem:aControls[ i ]:lMark
                     oItem:aControls[ i ]:lMark := ::lNextPage := .F.
                     IF __mvExist( "LSKIPITEM" )
                        lSkipItem := .F.
                     ENDIF
                     ::PrintItem( oItem:aControls[ i ] )
                     IF ::lNextPage
                        RETURN Nil
                     ENDIF
                  ENDIF
               NEXT
               IF ::lNextPage
                  EXIT
               ELSE
                  ::nTOffset := ::ny - y
                  IF ( aMethod := aGetSecond( oItem:aMethods, "onnextline" ) ) != Nil
                     DoScript( aMethod )
                  ENDIF
               ENDIF
            ENDDO
            IF lLastCycle
               // writelog( "--> "+str(::nAOffSet)+str(y2-y+1 - ( ::ny - y )) )
               ::nAOffSet += y2 - y + 1 - ( ::ny - y )
               ::nTOffset := 0
               ::lFinish := .T.
            ENDIF
         ELSE
            FOR i := 1 TO Len( oItem:aControls )
               ::PrintItem( oItem:aControls[ i ] )
            NEXT
         ENDIF
         lRes := .F.
      ENDIF
   ENDIF

   IF lRes

      y  -= ::nAOffSet
      y2 -= ::nAOffSet
      IF ::nTOffset > 0
         y  += ::nTOffset
         y2 += ::nTOffset
         IF y2 > oItem:oParent:y2
            oItem:lMark := .T.
            ::lNextPage := .T.
            ::nTOffset := ::nAOffSet := 0
            // writelog( "::lNextPage := .T. "+ oItem:cClass )
            RETURN Nil
         ENDIF
      ENDIF

      IF oItem:lPen .AND. oItem:oPen == Nil
         IF ( xProperty := aGetSecond( oItem:aProp, "pentype" ) ) != Nil
            nPenType := AScan( aPenType, xProperty ) - 1
         ELSE
            nPenType := 0
         ENDIF
         IF ( xProperty := aGetSecond( oItem:aProp, "penwidth" ) ) != Nil
            nPenWidth := Round( xProperty * ::nKoefPix, 0 )
         ELSE
            nPenWidth := Round( ::nKoefPix, 0 )
         ENDIF
         oItem:oPen := HPen():Add( nPenType, nPenWidth )
         // writelog( str(nPenWidth) + " " + str(::nKoefY) )
      ENDIF
      IF oItem:cClass == "label"
         IF ( aMethod := aGetSecond( oItem:aMethods, "expression" ) ) != Nil
            cText := DoScript( aMethod )
         ELSE
            cText := aGetSecond( oItem:aProp, "caption" )
         ENDIF
         IF ValType( cText ) == "C"
            IF ( xProperty := aGetSecond( oItem:aProp, "border" ) ) != Nil ;
                 .AND. xProperty
               ::oPrinter:Box( x, y, x2, y2 )
               x += 0.5
               y += 0.5
            ENDIF
            IF ( xProperty := aGetSecond( oItem:aProp, "justify" ) ) == Nil
               nJustify := 0
            ELSE
               nJustify := AScan( aJustify, xProperty ) - 1
            ENDIF
            IF oItem:obj == Nil
               IF ( xProperty := aGetSecond( oItem:aProp, "font" ) ) != Nil
                  oItem:obj := hrep_FontFromxml( ::oPrinter, xProperty, aGetSecond( oItem:aProp, "fonth" ) * ::nKoefY )
               ENDIF
            ENDIF
            SetTransparentMode( ::oPrinter:hDC, .T. )
            IF ( xProperty := aGetSecond( oItem:aProp, "multiline" ) ) != Nil ;
                 .AND. xProperty
               nLines := i := 1
               DO WHILE ( i := hb_At( ";", cText, i ) ) > 0
                  i ++
                  nLines ++
               ENDDO
               dy := ( y2 - y ) / nLines
               nFirst := i := 1
               ny := y
               DO WHILE ( i := hb_At( ";", cText, i ) ) > 0
                  ::oPrinter:Say( SubStr( cText, nFirst, i - nFirst ), x, ny, x2, ny + dy, nJustify, oItem:obj )
                  i ++
                  nFirst := i
                  ny += dy
               ENDDO
               ::oPrinter:Say( SubStr( cText, nFirst, Len( cText ) - nFirst + 1 ), x, ny, x2, ny + dy, nJustify, oItem:obj )
            ELSE
               ::oPrinter:Say( cText, x, y, x2, y2, nJustify, oItem:obj )
            ENDIF
            SetTransparentMode( ::oPrinter:hDC, .F. )
            // Writelog( str(x)+" "+str(y)+" "+str(x2)+" "+str(y2)+" "+str(::nAOffSet)+" "+str(::nTOffSet)+" Say: "+cText)
         ENDIF
      ELSEIF oItem:cClass == "box"
         ::oPrinter:Box( x, y, x2, y2, oItem:oPen )
         // writelog( "Draw "+str(x)+" "+str(x+width-1) )
      ELSEIF oItem:cClass == "vline"
         ::oPrinter:Line( x, y, x, y2, oItem:oPen )
      ELSEIF oItem:cClass == "hline"
         ::oPrinter:Line( x, y, x2, y, oItem:oPen )
      ELSEIF oItem:cClass == "bitmap"
         IF oItem:obj == Nil
            oItem:obj := OpenBitmap( aGetSecond( oItem:aProp, "bitmap" ), ::oPrinter:hDC )
         ENDIF
         ::oPrinter:Bitmap( x, y, x2, y2,, oItem:obj )
      ENDIF
      ::ny := Max( ::ny, y2 + ::nAOffSet )
   ENDIF

   IF ( aMethod := aGetSecond( oItem:aMethods, "onend" ) ) != Nil
      DoScript( aMethod )
   ENDIF

   RETURN Nil

METHOD ReleaseObj( aControls ) CLASS HRepTmpl
   LOCAL i

   FOR i := 1 TO Len( aControls )
      IF ! Empty( aControls[ i ]:aControls )
         ::ReleaseObj( aControls[ i ]:aControls )
      ELSE
         IF aControls[ i ]:obj != Nil
            IF aControls[ i ]:cClass == "bitmap"
               DeleteObject( aControls[ i ]:obj )
               aControls[ i ]:obj := Nil
            ELSEIF aControls[ i ]:cClass == "label"
               aControls[ i ]:obj:Release()
               aControls[ i ]:obj := Nil
            ENDIF
         ENDIF
         IF aControls[ i ]:oPen != Nil
            aControls[ i ]:oPen:Release()
            aControls[ i ]:oPen := Nil
         ENDIF
      ENDIF
   NEXT

   RETURN Nil

METHOD Find( cId ) CLASS HRepTmpl
   LOCAL i := AScan( ::aReports, { | o | o:cId != Nil.and.o:cId == cId } )
   RETURN IIf( i == 0, Nil, ::aReports[ i ] )

METHOD Close() CLASS HRepTmpl
   LOCAL i := AScan( ::aReports, { | o | o:id == ::id } )

   IF i != 0
      ADel( ::aReports, i )
      ASize( ::aReports, Len( ::aReports ) - 1 )
   ENDIF
   RETURN Nil

STATIC FUNCTION ReadRepItem( oCtrlDesc, oContainer )
   LOCAL oCtrl := HRepItem():New( oContainer )
   LOCAL i, j, o, aProp := { }, aMethods := { }, aItems := oCtrlDesc:aItems, xProperty, cName

   oCtrl:cClass   := oCtrlDesc:GetAttribute( "class" )
   oCtrl:aProp    := aProp
   oCtrl:aMethods := aMethods

   FOR i := 1 TO Len( aItems )
      IF aItems[ i ]:title == "style"
         FOR j := 1 TO Len( aItems[ i ]:aItems )
            o := aItems[ i ]:aItems[ j ]
            IF o:title == "property"
               AAdd( aProp, { Lower( o:GetAttribute( "name" ) ), IIf( Empty( o:aItems ), "", hfrm_GetProperty( o:aItems[ 1 ] ) ) } )
            ENDIF
         NEXT
      ELSEIF aItems[ i ]:title == "method"
         Aadd( aMethods, { cName := Lower(aItems[i]:GetAttribute("name")),RdScript(,aItems[i]:aItems[1]:aItems[1],,.T.,cName) } )
      ELSEIF aItems[ i ]:title == "part"
         ReadRepItem( aItems[ i ], IIf( oCtrl:cClass == "area", oCtrl, oContainer ) )
      ENDIF
   NEXT
   IF oCtrl:cClass $ "box.vline.hline" .OR. ( oCtrl:cClass == "label" .AND. ;
                                              ( xProperty := aGetSecond( oCtrl:aProp, "border" ) ) != Nil .AND. xProperty )
      oCtrl:lPen := .T.
   ENDIF

   RETURN Nil

STATIC FUNCTION aGetSecond( arr, xFirst )
   LOCAL i := AScan( arr, { | a | a[ 1 ] == xFirst } )

   RETURN IIf( i == 0, Nil, arr[ i, 2 ] )

STATIC FUNCTION hrep_FontFromXML( oPrinter, oXmlNode, height )
   LOCAL weight := oXmlNode:GetAttribute( "weight" )
   LOCAL charset := oXmlNode:GetAttribute( "charset" )
   LOCAL ita   := oXmlNode:GetAttribute( "italic" )
   LOCAL under := oXmlNode:GetAttribute( "underline" )

   weight := IIf( weight != Nil, Val( weight ), 400 )
   IF charset != Nil
      charset := Val( charset )
   ENDIF
   ita    := IIf( ita != Nil, Val( ita ), 0 )
   under  := IIf( under != Nil, Val( under ), 0 )

   RETURN oPrinter:AddFont( oXmlNode:GetAttribute( "name" ),  ;
                            height, ( weight > 400 ), ( ita > 0 ), ( under > 0 ), charset )

