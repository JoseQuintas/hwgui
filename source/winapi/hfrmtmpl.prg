/*
 * $Id: hfrmtmpl.prg,v 1.49 2007/04/17 05:43:32 alkresin Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HFormTmpl Class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/
#ifdef __XHARBOUR__
#xtranslate HB_AT(<x,...>) => AT(<x>)
#endif

STATIC nVertRes, nVertSize
STATIC aClass := { "label", "button", "checkbox",       ;
      "radiobutton", "editbox", "group", "radiogroup",  ;
      "bitmap", "icon", "richedit", "datepicker",       ;
      "updown", "combobox", "line", "toolbar",          ;
      "toolbartop", "toolbarbot", "ownerbutton",        ;
      "browse", "splitter", "monthcalendar", "trackbar",;
      "page", "tree", "status", "link", "menu",         ;
      "animation"     ;
      }
STATIC aCtrls := { ;
      "HStatic():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,ctooltip,TextColor,BackColor,lTransp)", ;
      "HButton():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,onClick,ctooltip,TextColor,BackColor)",  ;
      "HCheckButton():New(oPrnt,nId,lInitValue,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,onClick,ctooltip,TextColor,BackColor,onGetFocus,lTransp,onLostFocus)", ;
      "HRadioButton():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,onClick,ctooltip,TextColor,BackColor,lTransp)", ;
      "HEdit():New(oPrnt,nId,cInitValue,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onSize,onGetFocus,onLostFocus,ctooltip,TextColor,BackColor,cPicture,lNoBorder,nMaxLength,lPassword,onKeyDown,onChange)", ;
      "HGroup():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,TextColor,BackColor)", ;
      "hwg_RadioNew(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,TextColor,BackColor,nInitValue,bSetGet)", ;
      "HSayBmp():New(oPrnt,nId,nLeft,nTop,nWidth,nHeight,Bitmap,lResource,onInit,onSize,ctooltip,onClick,onDblClick,lTransp,nStretch,trColor,BackColor)", ;
      "HSayIcon():New(oPrnt,nId,nLeft,nTop,nWidth,nHeight,Icon,lResource,onInit,onSize,ctooltip,lOEM,onClick,onDblClick)", ;
      "HRichEdit():New(oPrnt,nId,cInitValue,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onSize,onGetFocus,onLostFocus,ctooltip,TextColor,BackColor)", ;
      "HDatePicker():New(oPrnt,nId,dInitValue,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onGetFocus,onLostFocus,onChange,ctooltip,TextColor,BackColor)", ;
      "HUpDown():New(oPrnt,nId,nInitValue,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onSize,onPaint,onGetFocus,onLostFocus,ctooltip,TextColor,BackColor,nUpDWidth,nLower,nUpper)", ;
      "HComboBox():New(oPrnt,nId,nInitValue,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,Items,oFont,onInit,onSize,onPaint,onChange,cTooltip,lEdit,lText,onGetFocus,TextColor,BackColor,onLostFocus,nDisplay)", ;
      "HLine():New(oPrnt,nId,lVertical,nLeft,nTop,nLength,onSize)", ;
      "HPanel():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,onInit,onSize,onPaint,BackColor,oStyle)", ;
      "HPanel():New(oPrnt,nId,nStyle,0,0,oPrnt:nWidth,nHeight,onInit,11,onPaint,BackColor,oStyle)", ;
      "HPanelStS():New(oPrnt,nId,nHeight,oFont,onInit,onPaint,BackColor,oStyle,aParts)", ;
      "HOwnButton():New(oPrnt,nId,aStyles,nLeft,nTop,nWidth,nHeight,onInit,onSize,onPaint,onClick,flat,caption,TextColor,oFont,TextLeft,TextTop,widtht,heightt,BtnBitmap,lResource,BmpLeft,BmpTop,widthb,heightb,lTransp,trColor,cTooltip,lEnabled,lCheck,BackColor)", ;
      "Hbrowse():New(BrwType,oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onSize,onPaint,onEnter,onGetfocus,onLostfocus,lNoVScroll,lNoBorder,lAppend,lAutoedit,onUpdate,onKeyDown,onPosChg,lMultiSelect,onRClick )", ;
      "HSplitter():New(oPrnt,nId,nLeft,nTop,nWidth,nHeight,onSize,onPaint,TextColor,BackColor,aLeft,aRight,nFrom,nTo,oStyle )", ;
      "HMonthCalendar():New(oPrnt,nId,dInitValue,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onChange,cTooltip,lNoToday,lNoTodayCircle,lWeekNumbers)", ;
      "HTrackBar():New(oPrnt,nId,nInitValue,nStyle,nLeft,nTop,nWidth,nHeight,onInit,onSize,bPaint,cTooltip,onChange,onDrag,nLow,nHigh,lVertical,TickStyle,TickMarks)", ;
      "HTab():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onSize,onPaint,aTabs,onChange,aImages,lResource,nBC,onClick,onGetFocus,onLostFocus)", ;
      "HTree():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onSize,TextColor,BackColor,aImages,lResource,lEditLabels,onTreeClick,nBC)", ;
      "HStatus():New(oPrnt,nId,nStyle,oFont,aParts,onInit,onSize)", ;
      "HStaticLink():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,ctooltip,TextColor,BackColor,lTransp,cLink,vColor,lColor,hColor)", ;
      ".F.", ;
      "HAnimation():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,Filename,AutoPlay,Center,Transparent)" ;
      }

#include "hbclass.ch"
#include "error.ch"
#include "hwgui.ch"
#include "hxml.ch"

#define  CONTROL_FIRST_ID   34000

STATIC aPenType  := { "SOLID", "DASH", "DOT", "DASHDOT", "DASHDOTDOT" }
STATIC aJustify  := { "Left", "Center", "Right" }

REQUEST HSTATIC, HBUTTON, HCHECKBUTTON, HRADIOBUTTON, HEDIT, HGROUP, HSAYBMP, HSAYICON
#ifndef __GTK__
REQUEST HRICHEDIT, HDATEPICKER
REQUEST HMONTHCALENDAR, HTRACKBAR, HTREE
#endif
REQUEST HUPDOWN, HCOMBOBOX, HLINE, HPANEL, HOWNBUTTON, HBROWSE, HTAB

REQUEST DBUSEAREA, RECNO, DBSKIP, DBGOTOP, DBCLOSEAREA

CLASS HCtrlTmpl

   DATA cClass
   DATA oParent
   DATA nId
   DATA aControls INIT {}
   DATA aProp, aMethods

   METHOD New( oParent )   INLINE ( ::oParent := oParent, AAdd( oParent:aControls,Self ), Self )
   METHOD F( nId )

ENDCLASS

METHOD F( nId ) CLASS HCtrlTmpl
   LOCAL i, aControls := ::aControls, nLen := Len( aControls ), o

   FOR i := 1 TO nLen
      IF aControls[i]:nId == nId
         RETURN aControls[i]
      ELSEIF !Empty( aControls[i]:aControls ) .AND. ( o := aControls[i]:F( nId ) ) != Nil
         RETURN o
      ENDIF
   NEXT

   RETURN Nil

CLASS HFormTmpl

   CLASS VAR aForms   INIT {}
   CLASS VAR maxId    INIT 0
   CLASS VAR oActive
   DATA cFormName
   DATA oDlg
   DATA aControls     INIT {}
   DATA aProp
   DATA aMethods
   DATA aVars         INIT {}
   DATA aNames        INIT {}
   DATA pVars
   DATA aFuncs
   DATA id
   DATA cId
   DATA nContainer    INIT 0
   DATA nCtrlId       INIT CONTROL_FIRST_ID
   DATA lDebug        INIT .F.
   DATA lNoModal      INIT .F.
   DATA bDlgExit, bFormExit
   DATA cargo

   METHOD Read( fname, cId )
   METHOD Show( nMode, params )
   METHOD ShowMain( params )   INLINE ::Show( 1, params )
   METHOD ShowModal( params )  INLINE ::Show( 2, params )
   METHOD Close()
   METHOD F( id, n )
   METHOD Find( cId )
   ERROR HANDLER OnError( xValue )

ENDCLASS

METHOD Read( fname, cId ) CLASS HFormTmpl
   LOCAL oDoc
   LOCAL i, j, nCtrl := 0, aItems, o, aProp := {}, aMethods := {}, arr
   LOCAL cPre, cName

   /* IF cId != Nil .AND. ( o := HFormTmpl():Find( cId ) ) != Nil
      Return o
   ENDIF */

   IF Left( fname, 5 ) == "<?xml"
      oDoc := HXMLDoc():ReadString( fname )
   ELSE
      ::cFormName := fname
      oDoc := HXMLDoc():Read( fname )
   ENDIF

   IF Empty( oDoc:aItems )
      hwg_Msgstop( "Can't open " + fname )
      RETURN Nil
   ELSEIF oDoc:aItems[1]:title != "part" .OR. oDoc:aItems[1]:GetAttribute( "class" ) != "form"
      hwg_Msgstop( "Form description isn't found" )
      RETURN Nil
   ENDIF

   ::maxId ++
   ::id := ::maxId
   ::cId := cId
   ::aProp := aProp
   ::aMethods := aMethods

   ppScript( , .T. )
   AAdd( ::aForms, Self )
   aItems := oDoc:aItems[1]:aItems
   FOR i := 1 TO Len( aItems )
      IF aItems[i]:title == "style"
         FOR j := 1 TO Len( aItems[i]:aItems )
            o := aItems[i]:aItems[j]
            IF o:title == "property"
               IF !Empty( o:aItems )
                  AAdd( aProp, { Lower( o:GetAttribute("name" ) ), o:aItems[1] } )
                  arr := Atail( aProp )
                  IF arr[1] == "ldebug" .AND. hwg_hfrm_GetProperty( arr[2] )
                     ::lDebug := .T.
                     SetDebugInfo( .T. )
                  ELSEIF arr[1] == "nomodal" .AND. hwg_hfrm_GetProperty( arr[2] )
                     ::lNoModal := .T.
                  ENDIF
               ENDIF
            ENDIF
         NEXT
      ELSEIF aItems[i]:title == "method"
         IF ( cName := Lower( aItems[i]:GetAttribute("name" ) ) ) == "common"
            arr := scr_GetFuncsList( aItems[i]:aItems[1]:aItems[1] )
            FOR j := 1 TO Len( arr )
               cPre := "#xtranslate " + arr[j] + ;
                  "( <params,...> ) => callfunc('"  + ;
                  Upper( arr[j] ) + "',\{ <params> \}, HFormTmpl():F("+LTrim(Str(::id))+"):aFuncs )"
               ppScript( cPre )
               cPre := "#xtranslate " + arr[j] + ;
                  "() => callfunc('"  + ;
                  Upper( arr[j] ) + "',, HFormTmpl():F("+LTrim(Str(::id))+"):aFuncs )"
               ppScript( cPre )
            NEXT
            AAdd( aMethods, { cName, CompileMethod( aItems[i]:aItems[1]:aItems[1],Self,,cName ) } )
            ::aFuncs := ::aMethods[ Len(aMethods),2,2 ]
         ELSE
            AAdd( aMethods, { cName, CompileMethod( aItems[i]:aItems[1]:aItems[1],Self,,cName ) } )
         ENDIF
         
      ELSEIF aItems[i]:title == "part"
         nCtrl ++
         ::nContainer := nCtrl
         ReadCtrl( aItems[i], Self, Self )
      ENDIF
   NEXT
   SetDebugInfo( .F. )
   ppScript( , .F. )

   RETURN Self

METHOD Show( nMode, p1, p2, p3 ) CLASS HFormTmpl
   LOCAL i, j, i1, j1, cTemp, a1, cType, xRes
   LOCAL nLeft, nTop, nWidth, nHeight, cTitle, oFont, lClipper := .F. , lExitOnEnter := .F.
   LOCAL xProperty, block, nStyle, nExclude := 0, bColor := - 1
   LOCAL lMdi := .F.
   LOCAL lMdiChild := .F.
   LOCAL lval := .F.
   LOCAL oIcon := Nil, cBitmap := nil
   LOCAL oBmp := NIL
   LOCAL bGetFo := { |o| HFormTmpl():oActive := o }

   MEMVAR oDlg
   PRIVATE oDlg

   SetDebugInfo( ::lDebug )
   SetDebugger( ::lDebug )
   nStyle := Iif( nMode==1, WS_OVERLAPPEDWINDOW, WS_VISIBLE + WS_SYSMENU + WS_SIZEBOX + WS_CAPTION )

   FOR i := 1 TO Len( ::aProp )
      xProperty := hwg_hfrm_GetProperty( ::aProp[ i,2 ] )

      IF ::aProp[ i,1 ] == "geometry"
         nLeft   := Val( xProperty[1] )
         nTop    := Val( xProperty[2] )
         nWidth  := Val( xProperty[3] )
         nHeight := Val( xProperty[4] )
      ELSEIF ::aProp[ i,1 ] == "caption"
         cTitle := xProperty
      ELSEIF ::aProp[ i,1 ] == "font"
         oFont := hwg_hfrm_FontFromXML( xProperty )
      ELSEIF ::aProp[ i,1 ] == "lclipper"
         lClipper := xProperty
      ELSEIF ::aProp[ i,1 ] == "lexitonenter"
         lExitOnEnter := xProperty
      ELSEIF ::aProp[ i,1 ] == "exstyle"
         nStyle := xProperty
      ELSEIF ::aProp[ i,1 ] == "formtype"
         IF nMode == Nil
            lMdi := At( "mdimain", Lower( xProperty ) ) > 0
            lMdiChild := At( "mdichild", Lower( xProperty ) ) > 0
            nMode := Iif( Left( xProperty,3 ) == "dlg", 2, 1 )
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "variables"
         FOR j := 1 TO Len( xProperty )
            Aadd( ::aVars, Lower( xProperty[j] ) )
         NEXT
         // Styles below
      ELSEIF ::aProp[ i,1 ] == "systemMenu"
         IF !xProperty
            nStyle := hwg_bitandinverse( nStyle, WS_SYSMENU )
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "minimizebox"
         IF xProperty
            nExclude += WS_MINIMIZEBOX
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "maximizebox"
         IF xProperty
            nExclude += WS_MAXIMIZEBOX
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "absalignent"
         IF !xProperty
            nStyle := hwg_bitandinverse( nStyle, DS_ABSALIGN )
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "sizeBox"
         IF !xProperty
            nStyle := hwg_bitandinverse( nStyle, WS_SIZEBOX )
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "visible"
         IF !xProperty
            nStyle := hwg_bitandinverse( nStyle, WS_VISIBLE )
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "3dLook"
         IF xProperty
            nStyle += DS_3DLOOK
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "clipsiblings"
         IF xProperty
            nStyle += WS_CLIPSIBLINGS
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "clipchildren"
         IF xProperty
            nStyle += WS_CLIPCHILDREN
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "fromstyle"
         IF nMode != 1
            IF Lower( xProperty ) == "popup"
               nStyle := hwg_bitor( nStyle, WS_POPUP )
            ELSEIF Lower( xProperty ) == "child"
               nStyle := hwg_bitor( nStyle, WS_CHILD )
            ENDIF
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "bitmap"
         cBitmap := xProperty
      ELSEIF ::aProp[ i,1 ] == "icon"
         oIcon := HIcon():Addfile(xProperty)
      ELSEIF ::aProp[ i,1 ] == "backcolor"
         bColor := xProperty
      ENDIF
   NEXT

   FOR i := 1 TO Len( ::aNames )
      __mvPrivate( ::aNames[i] )
   NEXT
   FOR i := 1 TO Len( ::aVars )
      __mvPrivate( ::aVars[i] )
   NEXT
   
   IF ::lNoModal
      ::pVars := hb_hash()
      FOR i := 1 TO Len( ::aVars )
         ::pVars[::aVars[i]] := Nil
      NEXT
   ENDIF
   
   oBmp := Iif( !Empty( cBitmap ), HBitmap():addfile( cBitmap, NIL ), NIL )

   IF nMode == Nil .OR. nMode == 2
      INIT DIALOG ::oDlg TITLE cTitle         ;
         AT nLeft, nTop SIZE -nWidth, -nHeight ;
         STYLE nStyle + nExclude;
         FONT oFont ;
         BACKGROUND BITMAP oBmp ;
         COLOR Iif( bColor >= 0, bColor, Nil ) ;
         ON GETFOCUS bGetFo
      ::oDlg:lClipper := lClipper
      ::oDlg:lExitOnEnter := lExitOnEnter
      ::oDlg:oParent  := Self

   ELSEIF nMode == 1

#ifndef __GTK__
      IF lMdi
         INIT WINDOW ::oDlg MDI TITLE cTitle    ;
            AT nLeft, nTop SIZE nWidth, nHeight ;
            STYLE Iif( nStyle > 0 , nStyle, NIL ) ;
            FONT oFont ;
            BACKGROUND BITMAP oBmp ;
            COLOR Iif( bColor >= 0, bColor, Nil ) ;
            ON GETFOCUS bGetFo
      ELSEIF lMdiChild
         INIT WINDOW ::oDlg  MDICHILD TITLE cTitle    ;
            AT nLeft, nTop SIZE nWidth, nHeight ;
            STYLE Iif( nStyle > 0 , nStyle, NIL ) ;
            FONT oFont ;
            BACKGROUND BITMAP oBmp ;
            COLOR Iif( bColor >= 0, bColor, Nil ) ;
            ON GETFOCUS bGetFo
      ELSE
#endif
         nExclude := hwg_BitAndInverse( WS_MAXIMIZEBOX + WS_MINIMIZEBOX, nExclude )
         INIT WINDOW ::oDlg MAIN TITLE cTitle    ;
            AT nLeft, nTop SIZE -nWidth, -nHeight ;
            FONT oFont ;
            BACKGROUND BITMAP oBmp ;
            COLOR Iif( bColor >= 0, bColor, Nil ) ;
            STYLE Iif( nStyle > 0 , nStyle, NIL ) ;
            ICON oIcon ;
            EXCLUDE Iif( nExclude > 0 , nExclude, NIL ) ;
            ON GETFOCUS bGetFo
#ifndef __GTK__
      ENDIF
#endif
   ENDIF

   ::oActive := oDlg := ::oDlg
   ::oDlg:bDestroy := &( "{|o|hwg_hfrm_Exit(o," + Ltrim(Str(::id)) + ")}" )

   FOR i := 1 TO Len( ::aMethods )
      IF ( cType := ValType( ::aMethods[ i,2 ] ) ) == "B"
         block := ::aMethods[ i,2 ]
      ELSEIF cType == "A"
         block := ::aMethods[ i,2,1 ]
      ENDIF
      IF ::aMethods[ i,1 ] == "ondlginit"
         IF nMode == 1
            Eval( block, Self )
         ELSE
            ::oDlg:bInit := block
         ENDIF
      ELSEIF ::aMethods[ i,1 ] == "ondlgactivate"
         ::oDlg:bActivate := block
      ELSEIF ::aMethods[ i,1 ] == "onforminit"
         Eval( block, Self, p1, p2, p3 )
      ELSEIF ::aMethods[ i,1 ] == "onpaint"
         ::oDlg:bPaint := block
      ELSEIF ::aMethods[ i,1 ] == "ondlgexit"
         ::bDlgExit := block
      ELSEIF ::aMethods[ i,1 ] == "onformexit"
         ::bFormExit := block
      ENDIF
   NEXT

   j := Len( ::aControls )
   IF j > 0 .AND. ::aControls[j]:cClass == "status"
      CreateCtrl( ::oDlg, ::aControls[j], Self )
      j --
   ENDIF

   FOR i := 1 TO j
      CreateCtrl( ::oDlg, ::aControls[i], Self )
   NEXT
   FOR i := 1 TO Len( ::oDlg:aControls )
      IF __ObjHasMsg( ::oDlg:aControls[i], "ALEFT" )
         a1 := ::oDlg:aControls[i]:aLeft
         FOR i1 := 1 TO Len( a1 )
            cTemp := Upper( a1[i1] )
            IF (j1 := Ascan( ::oDlg:aControls,{|o|o:objname != Nil .AND. o:objname == cTemp } )) != 0
               a1[i1] := ::oDlg:aControls[j1]
            ENDIF
         NEXT
         a1 := ::oDlg:aControls[i]:aRight
         FOR i1 := 1 TO Len( a1 )
            cTemp := Upper( a1[i1] )
            IF (j1 := Ascan( ::oDlg:aControls,{|o|o:objname != Nil .AND. o:objname == cTemp } )) != 0
               a1[i1] := ::oDlg:aControls[j1]
            ENDIF
         NEXT
      ENDIF
   NEXT

   IF ::lDebug .AND. ( i := HWindow():GetMain() ) != Nil
      hwg_Setfocus( i:handle )
   ENDIF

   ::oDlg:Activate( Iif( nMode == Nil .OR. nMode == 2 , ::lNoModal, Nil ) )

   IF !::lNoModal
      IF ::bFormExit != Nil
         xRes := Eval( ::bFormExit )
      ENDIF
      ::Close()
      RETURN xRes
   ENDIF

   RETURN Nil

METHOD F( id, n ) CLASS HFormTmpl
   LOCAL i := Ascan( ::aForms, { |o|o:id == id } )

   IF i != 0 .AND. n != Nil
      Return ::aForms[i]:aControls[n]
   ENDIF

   RETURN Iif( i == 0, Nil, ::aForms[i] )

METHOD Find( cId ) CLASS HFormTmpl
   LOCAL i := Ascan( ::aForms, { |o|o:cId != Nil .AND. o:cId == cId } )

   RETURN Iif( i == 0, Nil, ::aForms[i] )

METHOD Close() CLASS HFormTmpl
   LOCAL i := Ascan( ::aForms, { |o|o:id == ::id } )

   IF i != 0
      ADel( ::aForms, i )
      ASize( ::aForms, Len( ::aForms ) - 1 )
   ENDIF

   RETURN Nil

METHOD OnError( xValue ) CLASS HFormTmpl

   LOCAL cMsg := Lower( __GetMessage() )
   LOCAL oError, lSet := .F., lErr

   IF PCount() > 0 .AND. Left( cMsg, 1 ) == "_"
      cMsg := SubStr( cMsg, 2 )
      lSet := .T.
   ENDIF
#ifdef __XHARBOUR__
   lErr := ( Ascan( ::aVars, {|s| s == cMsg} ) == 0 )
#else
   lErr := ( hb_Ascan( ::aVars, cMsg,,, .T. ) == 0 )
#endif
   IF !lErr
      IF lSet
         IF ::lNoModal
            hb_hset( ::pVars, cMsg, xValue )
         ELSE
            __mvPut( cMsg, xValue )
         ENDIF
         RETURN Nil
      ELSE
         IF ::lNoModal
            RETURN hb_hget( ::pVars, cMsg )
         ELSE
            RETURN __mvGet( cMsg )
         ENDIF
      ENDIF
   ENDIF

   oError := ErrorNew()
   oError:severity    := ES_ERROR
   oError:genCode     := EG_LIMIT
   oError:subSystem   := "HFORMTMPL"
   oError:subCode     := 0
   oError:description := "Invalid class member"
   oError:canRetry    := .F.
   oError:canDefault  := .F.
   oError:fileName    := ""
   oError:osCode      := 0

   Eval( ErrorBlock(), oError )
   __errInHandler()

   RETURN Nil


   // ------------------------------

FUNCTION hwg_hfrm_Exit( oDlg, nId )

   LOCAL oForm := HFormTmpl():F( nId )

   IF !Empty( oForm:bDlgExit )
      IF !Eval( oForm:bDlgExit, oDlg )
         RETURN .F.
      ENDIF
   ENDIF
   IF oForm:lNoModal
      IF !Empty( oForm:bFormExit )
         Eval( oForm:bFormExit )
      ENDIF
      oForm:Close()
   ENDIF

   RETURN .T.

STATIC FUNCTION ReadTree( oForm, aParent, oDesc )
   LOCAL i, aTree := {}, oNode, subarr

   FOR i := 1 TO Len( oDesc:aItems )
      oNode := oDesc:aItems[i]
      IF oNode:type == HBXML_TYPE_CDATA
         aParent[1] := CompileMethod( oNode:aItems[1], oForm )
      ELSE
         AAdd( aTree, { Nil, oNode:GetAttribute( "name" ), ;
            Val( oNode:GetAttribute( "id" ) ), .T. } )
         IF !Empty( oNode:aItems )
            IF ( subarr := ReadTree( oForm,aTail( aTree ),oNode ) ) != Nil
               aTree[ Len(aTree),1 ] := subarr
            ENDIF
         ENDIF
      ENDIF
   NEXT

   RETURN Iif( Empty( aTree ), Nil, aTree )

FUNCTION hwg_ParseMethod( cMethod )

   LOCAL arr := {}, nPos1, nPos2, cLine

   IF ( nPos1 := At( Chr(10 ),cMethod ) ) == 0
      AAdd( arr, AllTrim( cMethod ) )
   ELSE
      AAdd( arr, AllTrim( Left( cMethod,nPos1 - 1 ) ) )
      DO WHILE .T.
         IF ( nPos2 := hb_At( Chr(10 ),cMethod,nPos1 + 1 ) ) == 0
            cLine := AllTrim( SubStr( cMethod,nPos1 + 1 ) )
         ELSE
            cLine := AllTrim( SubStr( cMethod,nPos1 + 1,nPos2 - nPos1 - 1 ) )
         ENDIF
         IF !Empty( cLine )
            AAdd( arr, cLine )
         ENDIF
         IF nPos2 == 0 .OR. Len( arr ) > 2
            EXIT
         ELSE
            nPos1 := nPos2
         ENDIF
      ENDDO
   ENDIF
   IF Right( arr[1], 1 ) < " "
      arr[1] := Left( arr[1], Len( arr[1] ) - 1 )
   ENDIF
   IF Len( arr ) > 1 .AND. Right( arr[2], 1 ) < " "
      arr[2] := Left( arr[2], Len( arr[2] ) - 1 )
   ENDIF

   RETURN arr

STATIC FUNCTION CompileMethod( cMethod, oForm, oCtrl, cName )
   LOCAL arr, arrExe, nContainer := 0, cCode1, cCode, bOldError, bRes

   IF cMethod = Nil .OR. Empty( cMethod )
      RETURN Nil
   ENDIF
   IF oCtrl != Nil .AND. Left( oCtrl:oParent:Classname(), 2 ) == "HC"
      nContainer := oForm:nContainer
   ENDIF
   IF oForm:lDebug
      arr := {}
   ELSE
      arr := hwg_ParseMethod( cMethod )
   ENDIF
   IF Len( arr ) == 1
      cCode := Iif( Lower( Left(arr[1],6 ) ) == "return", LTrim( SubStr( arr[1],8 ) ), arr[1] )
      bOldError := ErrorBlock( { |e|CompileErr( e,cCode ) } )
      BEGIN SEQUENCE
         bRes := &( "{||" + ppScript( cCode ) + "}" )
      END SEQUENCE
      ErrorBlock( bOldError )
      RETURN bRes
   ELSEIF !Empty( arr ) .AND. Lower( Left( arr[1],11 ) ) == "parameters "
      IF Len( arr ) == 2
         cCode := Iif( Lower( Left(arr[2],6 ) ) == "return", LTrim( SubStr( arr[2],8 ) ), arr[2] )
         cCode := "{|" + LTrim( SubStr( arr[1],12 ) ) + "|" + ppScript( cCode ) + "}"
         bOldError := ErrorBlock( { |e|CompileErr( e,cCode ) } )
         BEGIN SEQUENCE
            bRes := &cCode
         END SEQUENCE
         ErrorBlock( bOldError )
         RETURN bRes
      ELSE
         cCode1 := Iif( nContainer == 0, ;
            "aControls[" + LTrim( Str( Len(oForm:aControls ) ) ) + "]", ;
            "F(" + LTrim( Str( oCtrl:nId ) ) + ")" )
         arrExe := Array( 2 )
         arrExe[2] := RdScript( , cMethod, 1, .T. , cName )
         cCode :=  "{|" + LTrim( SubStr( arr[1],12 ) ) + ;
            "|DoScript(HFormTmpl():F(" + LTrim( Str( oForm:id ) ) + Iif( nContainer != 0, "," + LTrim( Str(nContainer ) ), "" ) + "):" + ;
            Iif( oCtrl == Nil, "aMethods[" + LTrim( Str(Len(oForm:aMethods ) + 1 ) ) + ",2,2],{", ;
            cCode1 + ":aMethods[" + ;
            LTrim( Str( Len(oCtrl:aMethods ) + 1 ) ) + ",2,2],{" ) + ;
            LTrim( SubStr( arr[1],12 ) ) + "})" + "}"
         arrExe[1] := &cCode
         RETURN arrExe
      ENDIF
   ENDIF

   cCode1 := Iif( nContainer == 0, ;
      "aControls[" + LTrim( Str( Len(oForm:aControls ) ) ) + "]", ;
      "F(" + LTrim( Str( oCtrl:nId ) ) + ")" )
   arrExe := Array( 2 )
   arrExe[2] := RdScript( , cMethod, , .T. , cName )
   cCode :=  "{||DoScript(HFormTmpl():F(" + LTrim( Str( oForm:id ) ) + Iif( nContainer != 0, "," + LTrim( Str(nContainer ) ), "" ) + "):" + ;
      Iif( oCtrl == Nil, "aMethods[" + LTrim( Str(Len(oForm:aMethods ) + 1 ) ) + ",2,2])", ;
      cCode1 + ":aMethods[" +   ;
      LTrim( Str( Len(oCtrl:aMethods ) + 1 ) ) + ",2,2])" ) + "}"
   arrExe[1] := &cCode

   RETURN arrExe

STATIC PROCEDURE CompileErr( e, stroka )

   hwg_Msgstop( hwg_ErrMsg( e ) + Chr( 10 ) + Chr( 13 ) + "in" + Chr( 10 ) + Chr( 13 ) + ;
      AllTrim( stroka ), "Script compiling error" )
   BREAK( NIL )

STATIC FUNCTION ReadCtrl( oCtrlDesc, oContainer, oForm )
   LOCAL oCtrl := HCtrlTmpl():New( oContainer )
   LOCAL i, j, o, cName, aProp := {}, aMethods := {}, aItems := oCtrlDesc:aItems

   oCtrl:nId      := oForm:nCtrlId
   oForm:nCtrlId ++
   oCtrl:cClass   := oCtrlDesc:GetAttribute( "class" )
   oCtrl:aProp    := aProp
   oCtrl:aMethods := aMethods

   FOR i := 1 TO Len( aItems )
      IF aItems[i]:title == "style"
         FOR j := 1 TO Len( aItems[i]:aItems )
            o := aItems[i]:aItems[j]
            IF o:title == "property"
               IF ( cName := Lower( o:GetAttribute("name" ) ) ) == "varname"
                  AAdd( oForm:aVars, Lower( hwg_hfrm_GetProperty(o:aItems[1] ) ) )
               ELSEIF cName == "name"
                  AAdd( oForm:aNames, hwg_hfrm_GetProperty(o:aItems[1] ) )
               ENDIF
               IF cName == "atree"
                  AAdd( aProp, { cName, ReadTree( oForm,,o ) } )
               ELSEIF cname == "styles"
                  AAdd( aProp, { cName, Iif( Empty(o:aItems ),"",o:aItems ) } )
               ELSE
                  AAdd( aProp, { cName, Iif( Empty(o:aItems ),"",o:aItems[1] ) } )
               ENDIF
            ENDIF
         NEXT
      ELSEIF aItems[i]:title == "method"
         AAdd( aMethods, { cName := Lower( aItems[i]:GetAttribute("name" ) ), CompileMethod( aItems[i]:aItems[1]:aItems[1],oForm,oCtrl,cName ) } )
      ELSEIF aItems[i]:title == "part"
         ReadCtrl( aItems[i], oCtrl, oForm )
      ENDIF
   NEXT

   RETURN Nil

#define TBS_AUTOTICKS                1
#define TBS_TOP                      4
#define TBS_BOTH                     8
#define TBS_NOTICKS                 16

STATIC FUNCTION CreateCtrl( oParent, oCtrlTmpl, oForm )
   LOCAL i, j, oCtrl, stroka, varname, xProperty, block, cType, cPName, cCtrlName
   LOCAL nCtrl := Ascan( aClass, oCtrlTmpl:cClass ), xInitValue, cInitName, cVarName
   MEMVAR oPrnt, nId, nInitValue, cInitValue, dInitValue, nStyle, nLeft, nTop, oStyle, aStyles
   MEMVAR onInit, onSize, onPaint, onEnter, onGetfocus, onLostfocus, lNoVScroll, lAppend, lAutoedit, bUpdate, onKeyDown, onPosChg
   MEMVAR nWidth, nHeight, oFont, lNoBorder, lTransp, trColor, bSetGet
   MEMVAR name, nMaxLines, nLength, lVertical, brwType, TickStyle, TickMarks, Tabs, tmp_nSheet
   MEMVAR aImages, lEditLabels, aParts, aLeft, aRight, nFrom, nTo, cLink, vColor, lColor, hColor
   MEMVAR oStyleHead, oStyleFoot, oStyleCell

   IF nCtrl == 0
      IF Lower( oCtrlTmpl:cClass ) == "pagesheet"
         tmp_nSheet ++
         oParent:StartPage( Tabs[tmp_nSheet] )
         FOR i := 1 TO Len( oCtrlTmpl:aControls )
            CreateCtrl( oParent, oCtrlTmpl:aControls[i], oForm )
         NEXT
         oParent:EndPage()
      ENDIF
      RETURN Nil
   ENDIF

   /* Declaring of variables, which are in the appropriate 'New()' function */
   stroka := aCtrls[nCtrl]
   IF ( i := At( "New(", stroka ) ) != 0
      i += 4
      DO WHILE .T.
         IF ( j := hb_At( ",",stroka,i ) ) != 0 .OR. ( j := hb_At( ")",stroka,i ) ) != 0
            IF j - i > 0 .AND. !IsDigit(SubStr( stroka, i, 1 ))
               varname := SubStr( stroka, i, j - i )
               __mvPrivate( varname )
               IF SubStr( varname, 2 ) == "InitValue"
                  cInitName  := varname
                  xInitValue := Iif( Left( varname,1 ) == "n", 1, Iif( Left(varname,1 ) == "c","", .F. ) )
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

   FOR i := 1 TO Len( oCtrlTmpl:aProp )
      xProperty := hwg_hfrm_GetProperty( oCtrlTmpl:aProp[ i,2 ] )
      cPName := oCtrlTmpl:aProp[ i,1 ]
      IF cPName == "geometry"
         nLeft   := Val( xProperty[1] )
         nTop    := Val( xProperty[2] )
         nWidth  := Val( xProperty[3] )
         nHeight := Val( xProperty[4] )
         IF __ObjHasMsg( oParent, "ID" )
            nLeft -= oParent:nLeft
            nTop -= oParent:nTop
            IF __ObjHasMsg( oParent:oParent, "ID" )
               nLeft -= oParent:oParent:nLeft
               nTop -= oParent:oParent:nTop
            ENDIF
         ENDIF
      ELSEIF cPName == "font"
         oFont := hwg_hfrm_FontFromXML( xProperty )
      ELSEIF Left(cPName,6) == "hstyle"
         oStyle := hwg_HStyleFromXML( xProperty )
         IF cPName == "hstylehead"
            oStyleHead := oStyle
         ELSEIF cPName == "hstylefoot"
            oStyleFoot := oStyle
         ELSEIF cPName == "hstylecell"
            oStyleCell := oStyle
         ENDIF
      ELSEIF cPName == "styles"
         aStyles := {}
         FOR j := 1 TO Len( xProperty )
            Aadd( aStyles, hwg_HstyleFromXML( xProperty[j] ) )
         NEXT
      ELSEIF cPName == "border"
         IF xProperty
            nStyle += WS_BORDER
         ELSE
            lNoBorder := .T.
         ENDIF
      ELSEIF cPName == "justify"
         nStyle += Iif( xProperty == "Center", SS_CENTER, Iif( xProperty == "Right",SS_RIGHT,0 ) )
      ELSEIF cPName == "multiline"
         IF xProperty
            nStyle += ES_MULTILINE
         ENDIF
      ELSEIF cPName == "password"
         IF xProperty
            nStyle += ES_PASSWORD
         ENDIF
      ELSEIF cPName == "autohscroll"
         IF xProperty
            nStyle += ES_AUTOHSCROLL
         ENDIF
      ELSEIF cPName == "3dlook"
         IF xProperty
            nStyle += DS_3DLOOK
         ENDIF
      ELSEIF cPName == "transparent"
         IF xProperty
            lTransp := .T.
         ENDIF

      ELSEIF cPName == "atree"
         hwg_BuildMenu( xProperty, oForm:oDlg:handle, oForm:oDlg )
      ELSE
         IF cPName == "tooltip"
            cPName := "c" + cPName
         ELSEIF cPName == "name"
            cCtrlName := xProperty
         ELSEIF cPName == "anchor"
            __mvPut( "onsize", xProperty )
         ELSE
            /* Assigning the value of the property to the variable with
               the same name as the property */
            __mvPut( cPName, xProperty )
         ENDIF
         IF cPName == "varname"
            cVarName := xProperty
            bSetGet := &( "{|v|Iif(v==Nil,HFormTmpl():F("+LTrim(Str(oForm:id))+"):" + xProperty + ",HFormTmpl():F("+LTrim(Str(oForm:id))+"):" + xProperty + ":=v)}" )
            IF __objSendMsg( oForm, xProperty ) == Nil
               __objSendMsg( oForm, '_'+xProperty, xInitValue )
            ELSEIF cInitName != Nil
               __mvPut( cInitName, __objSendMsg( oForm, xProperty ) )
            ENDIF
         ELSEIF SubStr( cPName, 2 ) == "initvalue"
            xInitValue := xProperty
         ENDIF
      ENDIF
   NEXT
   FOR i := 1 TO Len( oCtrlTmpl:aMethods )
      IF ( cType := ValType( oCtrlTmpl:aMethods[ i,2 ] ) ) == "B"
         __mvPut( oCtrlTmpl:aMethods[ i,1 ], oCtrlTmpl:aMethods[ i,2 ] )
      ELSEIF cType == "A"
         __mvPut( oCtrlTmpl:aMethods[ i,1 ], oCtrlTmpl:aMethods[ i,2,1 ] )
      ENDIF
   NEXT

   IF oCtrlTmpl:cClass == "combobox"
#ifndef __GTK__
      IF ( i := Ascan( oCtrlTmpl:aProp,{ |a|Lower(a[1] ) == "nmaxlines" } ) ) > 0
         nHeight := nHeight * nMaxLines
      ELSE
         nHeight := nHeight * 4
      ENDIF
#endif
   ELSEIF oCtrlTmpl:cClass == "line"
      nLength := Iif( lVertical == Nil .OR. !lVertical, nWidth, nHeight )
   ELSEIF oCtrlTmpl:cClass == "browse"
      brwType := Iif( brwType == Nil .OR. brwType == "Dbf", BRW_DATABASE, BRW_ARRAY )
   ELSEIF oCtrlTmpl:cClass == "trackbar"
      IF TickStyle == Nil .OR. TickStyle == "Auto"
         TickStyle := TBS_AUTOTICKS
      ELSEIF TickStyle == "None"
         TickStyle := TBS_NOTICKS
      ELSE
         TickStyle := 0
      ENDIF
      IF TickMarks == Nil .OR. TickMarks == "Bottom"
         TickMarks := 0
      ELSEIF TickMarks == "Both"
         TickMarks := TBS_BOTH
      ELSE
         TickMarks := TBS_TOP
      ENDIF
   ELSEIF oCtrlTmpl:cClass == "status" .OR. oCtrlTmpl:cClass == "toolbarbot"
      IF aParts != Nil
         FOR i := 1 TO Len( aParts )
            aParts[i] := Val( aParts[i] )
         NEXT
      ENDIF
      onInit := { |o|o:Move( , , o:nWidth - 1 ) }
   ENDIF
   oCtrl := &stroka
   IF cVarName != Nil
      oCtrl:cargo := cVarName
   ENDIF

   IF !Empty( cCtrlName ) .AND. Valtype(oCtrl) == "O"
      __mvPut( cCtrlName, oCtrl )
      hwg_SetCtrlName( oCtrl, cCtrlName )
   ENDIF
   IF __mvExist( "OSTYLEHEAD" ) .AND. __ObjHasMsg( oCtrl, "OSTYLEHEAD" )
      oCtrl:oStyleHead := oStyleHead
   ENDIF
   IF __mvExist( "OSTYLEFOOT" ) .AND. __ObjHasMsg( oCtrl, "OSTYLEFOOT" )
      oCtrl:oStyleFoot := oStyleFoot
   ENDIF
   IF __mvExist( "OSTYLECELL" ) .AND. __ObjHasMsg( oCtrl, "OSTYLECELL" )
      oCtrl:oStyleCell := oStyleCell
   ENDIF

   IF !Empty( oCtrlTmpl:aControls )
      IF oCtrlTmpl:cClass == "page"
         __mvPrivate( "tmp_nSheet" )
         __mvPut( "tmp_nSheet", 0 )
      ENDIF
      FOR i := 1 TO Len( oCtrlTmpl:aControls )
         CreateCtrl( Iif( oCtrlTmpl:cClass == "group" .OR. oCtrlTmpl:cClass == "radiogroup",oParent,oCtrl ), oCtrlTmpl:aControls[i], oForm )
      NEXT
      IF oCtrlTmpl:cClass == "radiogroup"
         HRadioGroup():EndGroup()
      ENDIF
   ENDIF

   RETURN Nil

FUNCTION hwg_RadioNew( oPrnt, nId, nStyle, nLeft, nTop, nWidth, nHeight, caption, oFont, onInit, onSize, onPaint, TextColor, BackColor, nInitValue, bSetGet )

   LOCAL oCtrl := HGroup():New( oPrnt, nId, nStyle, nLeft, nTop, nWidth, nHeight, caption, oFont, onInit, onSize, onPaint, TextColor, BackColor )

   oCtrl:cargo := HRadioGroup():New( nInitValue, bSetGet )

   RETURN oCtrl

FUNCTION hwg_Font2XML( oFont )

   LOCAL aAttr := {}
   LOCAL hWnd, hDC, aMetr, aTMetr

   hDC := hwg_Getdc( hWnd := hwg_Getactivewindow() )
   IF Empty( nVertRes )
      aMetr  := hwg_Getdevicearea( hDC )
      nVertRes  := aMetr[2]
      nVertSize := aMetr[4]
   ENDIF
   hwg_Selectobject( hDC, oFont:handle )
   aTMetr := hwg_Gettextmetric( hDC )
   hwg_Releasedc( hWnd, hDC )

   AAdd( aAttr, { "name", oFont:name } )
   AAdd( aAttr, { "width", LTrim( Str(oFont:width,5 ) ) } )
   AAdd( aAttr, { "height", LTrim( Str(oFont:height,5 ) ) + "M" + LTrim( Str(Round((aTMetr[1] - aTMetr[5] ) * nVertSize/nVertRes,2 ),5,2 ) ) } )
   IF oFont:weight != 0
      AAdd( aAttr, { "weight", LTrim( Str(oFont:weight,5 ) ) } )
   ENDIF
   IF oFont:charset != 0
      AAdd( aAttr, { "charset", LTrim( Str(oFont:charset,5 ) ) } )
   ENDIF
   IF oFont:Italic != 0
      AAdd( aAttr, { "italic", LTrim( Str(oFont:Italic,5 ) ) } )
   ENDIF
   IF oFont:Underline != 0
      AAdd( aAttr, { "underline", LTrim( Str(oFont:Underline,5 ) ) } )
   ENDIF

   RETURN HXMLNode():New( "font", HBXML_TYPE_SINGLE, aAttr )

FUNCTION hwg_hfrm_FontFromXML( oXmlNode, lReport )

   LOCAL i, hWnd, hDC, aMetr
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
      IF !Empty( lReport ) .AND. ( i := At( 'M',height ) ) != 0
         IF Empty( nVertRes )
            hDC := hwg_Getdc( hWnd := hwg_Getactivewindow() )
            aMetr  := hwg_Getdevicearea( hDC )
            nVertRes  := aMetr[2]
            nVertSize := aMetr[4]
            hwg_Releasedc( hWnd, hDC )
         ENDIF
         //hwg_writelog( str(Val( height )) + "/" + Str(Round( Val( Substr(height,i+1) ) * nVertRes / nVertSize, 0 )) )
         height := - Round( Val( SubStr(height,i + 1 ) ) * nVertRes / nVertSize, 0 )
      ELSE
         height := Val( height )
      ENDIF
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

FUNCTION hwg_HStyle2XML( oStyle )
   LOCAL aAttr := {}

   IF !Empty( oStyle:aColors )
      AAdd( aAttr, { "colors", hwg_hfrm_Arr2Str( oStyle:aColors ) } )
      AAdd( aAttr, { "orient", Ltrim(Str( oStyle:nOrient )) } )
   ENDIF
   IF !Empty( oStyle:aCorners )
      AAdd( aAttr, { "corners", hwg_hfrm_Arr2Str( oStyle:aCorners ) } )
   ENDIF
   IF oStyle:nBorder != 0
      AAdd( aAttr, { "border", Ltrim(Str( oStyle:nBorder )) } )
      AAdd( aAttr, { "tcolor", Ltrim(Str( oStyle:tColor )) } )
   ENDIF

   RETURN HXMLNode():New( "hstyle", HBXML_TYPE_SINGLE, aAttr )

FUNCTION hwg_HstyleFromXML( oXmlNode )
   LOCAL cColors := oXmlNode:GetAttribute( "colors" ), aColors, i, nOrient
   LOCAL cCorners := oXmlNode:GetAttribute( "corners" ), aCorners
   LOCAL nBorder, tColor

   IF !Empty( cColors )
      aColors := hwg_hfrm_Str2Arr( cColors )
      FOR i := 1 TO Len(aColors)
         aColors[i] := Val( aColors[i] )
      NEXT
      nOrient := oXmlNode:GetAttribute( "orient", "N", 1 )
   ENDIF
   IF !Empty( cCorners )
      aCorners := hwg_hfrm_Str2Arr( cCorners )
      FOR i := 1 TO Len(aCorners)
         aCorners[i] := Val( aCorners[i] )
      NEXT
   ENDIF
   nBorder := oXmlNode:GetAttribute( "border", "N", Nil )
   tColor := oXmlNode:GetAttribute( "tcolor", "N", Nil )

   RETURN HStyle():New( aColors, nOrient, aCorners, nBorder, tColor )

FUNCTION hwg_hfrm_Str2Arr( stroka )

   LOCAL arr := {}, pos1 := 2, pos2 := 1

   IF Len( stroka ) > 2
      DO WHILE pos2 > 0
         DO WHILE SubStr( stroka, pos1, 1 ) <= ' ' ; pos1 ++ ; ENDDO
         pos2 := hb_At( ',', stroka, pos1 )
         AAdd( arr, Trim( SubStr( stroka,pos1,Iif( pos2 > 0,pos2 - pos1,hb_At('}',stroka,pos1 ) - pos1 ) ) ) )
         pos1 := pos2 + 1
      ENDDO
   ENDIF

   RETURN arr

FUNCTION hwg_hfrm_Arr2Str( arr )

   LOCAL stroka := "{", i, cType

   FOR i := 1 TO Len( arr )
      IF i > 1
         stroka += ","
      ENDIF
      cType := ValType( arr[i] )
      IF cType == "C"
         stroka += arr[i]
      ELSEIF cType == "N"
         stroka += LTrim( Str( arr[i] ) )
      ENDIF
   NEXT

   RETURN stroka + "}"

FUNCTION hwg_hfrm_GetProperty( xProp )

   LOCAL c

   IF ValType( xProp ) == "C"
      c := Left( xProp, 1 )
      IF c == "["
         xProp := SubStr( xProp, 2, Len( Trim(xProp ) ) - 2 )
      ELSEIF c == "."
         xProp := ( SubStr( xProp,2,1 ) == "T" )
      ELSEIF c == "{"
         xProp := hwg_hfrm_Str2Arr( xProp )
      ELSE
         xProp := Val( xProp )
      ENDIF
   ENDIF

   RETURN xProp

   // ---------------------------------------------------- //

CLASS HRepItem

   DATA cClass
   DATA oParent
   DATA aControls INIT {}
   DATA aProp, aMethods
   DATA oPen, obj
   DATA lPen INIT .F.
   DATA y2
   DATA lMark INIT .F.

   METHOD New( oParent )   INLINE ( ::oParent := oParent, AAdd( oParent:aControls,Self ), Self )

ENDCLASS

CLASS HRepTmpl

   CLASS VAR aReports INIT {}
   CLASS VAR maxId    INIT 0
   CLASS VAR aFontTable
   DATA aControls     INIT {}
   DATA cFormName
   DATA aProp
   DATA aMethods
   DATA aVars         INIT {}
   DATA aFuncs
   DATA lDebug        INIT .F.
   DATA id
   DATA cId

   DATA nKoefX, nKoefY, nKoefPix
   DATA nTOffset, nAOffSet, ny
   DATA lNextPage, lFinish
   DATA oPrinter

   METHOD READ( fname, cId )
   METHOD PRINT( printer, lPreview, p1, p2, p3, p4, p5 )
   METHOD PrintAsPage( printer, nPageType, lPreview, p1, p2, p3, p4, p5 )
   METHOD PrintItem( oItem )
   METHOD ReleaseObj( aControls )
   METHOD Find( cId )
   METHOD CLOSE()

ENDCLASS

METHOD READ( fname, cId ) CLASS HRepTmpl
   LOCAL oDoc
   LOCAL i, j, aItems, o, aProp := {}, aMethods := {}
   LOCAL cPre, cName

   IF cId != Nil .AND. ( o := HRepTmpl():Find( cId ) ) != Nil
      RETURN o
   ENDIF

   IF Left( fname, 5 ) == "<?xml"
      oDoc := HXMLDoc():ReadString( fname )
   ELSE
      ::cFormName := fname
      oDoc := HXMLDoc():Read( fname )
   ENDIF

   IF Empty( oDoc:aItems )
      hwg_Msgstop( "Can't open " + fname )
      RETURN Nil
   ELSEIF oDoc:aItems[1]:title != "part" .OR. oDoc:aItems[1]:GetAttribute( "class" ) != "report"
      hwg_Msgstop( "Report description isn't found" )
      RETURN Nil
   ENDIF

   ::maxId ++
   ::id := ::maxId
   ::cId := cId
   ::aProp := aProp
   ::aMethods := aMethods

   ppScript( , .T. )
   AAdd( ::aReports, Self )
   aItems := oDoc:aItems[1]:aItems
   FOR i := 1 TO Len( aItems )
      IF aItems[i]:title == "style"
         FOR j := 1 TO Len( aItems[i]:aItems )
            o := aItems[i]:aItems[j]
            IF o:title == "property"
               IF !Empty( o:aItems )
                  AAdd( aProp, { Lower( o:GetAttribute("name" ) ), hwg_hfrm_GetProperty( o:aItems[1] ) } )
                  IF Atail( aProp )[1] == "ldebug" .AND. hwg_hfrm_GetProperty( Atail( aProp )[2] )
                     ::lDebug := .T.
                     SetDebugInfo( .T. )
                  ENDIF
               ENDIF
            ENDIF
         NEXT
      ELSEIF aItems[i]:title == "method"
         AAdd( aMethods, { cName := Lower( aItems[i]:GetAttribute("name" ) ), RdScript( ,aItems[i]:aItems[1]:aItems[1],, .T. ,cName ) } )
         IF aMethods[ (j := Len(aMethods)),1 ] == "common"
            ::aFuncs := ::aMethods[ j,2 ]
            FOR j := 1 TO Len( ::aFuncs[2] )
               cPre := "#xtranslate " + ::aFuncs[2,j,1] + ;
                  "( <params,...> ) => callfunc('"  + ;
                  Upper( ::aFuncs[2,j,1] ) + "',\{ <params> \}, oReport:aFuncs )"
               ppScript( cPre )
               cPre := "#xtranslate " + ::aFuncs[2,j,1] + ;
                  "() => callfunc('"  + ;
                  Upper( ::aFuncs[2,j,1] ) + "',, oReport:aFuncs )"
               ppScript( cPre )
            NEXT
         ENDIF
      ELSEIF aItems[i]:title == "part"
         ReadRepItem( aItems[i], Self )
      ENDIF
   NEXT
   SetDebugInfo( .F. )
   ppScript( , .F. )

   RETURN Self

METHOD PRINT( printer, lPreview, p1, p2, p3, p4, p5 ) CLASS HRepTmpl
   LOCAL oPrinter := Iif( printer != Nil, Iif( ValType(printer ) == "O",printer,HPrinter():New(printer, .T. ) ), HPrinter():New( , .T. ) )
   LOCAL i, j, aMethod, xProperty, oFont, xTemp, nPWidth, nPHeight, nOrientation := 1, nDuplex
   MEMVAR oReport
   PRIVATE oReport := Self

   IF oPrinter == Nil
      RETURN Nil
   ENDIF
   SetDebugInfo( ::lDebug )
   SetDebugger( ::lDebug )

   FOR i := 1 TO Len( ::aProp )
      IF ::aProp[ i,1 ] == "paper size"
         IF Lower( ::aProp[i,2] ) == "a4"
            nPWidth  := 210
            nPHeight := 297
         ELSEIF Lower( ::aProp[i,2] ) == "a3"
            nPWidth  := 297
            nPHeight := 420
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "orientation"
         IF Lower( ::aProp[i,2] ) != "portrait"
            xTemp    := nPWidth
            nPWidth  := nPHeight
            nPHeight := xTemp
            nOrientation := 2
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "duplex"
         IF Lower( ::aProp[i,2] ) == "no"
            nDuplex := 1
         ELSEIF Lower( ::aProp[i,2] ) == "vertical"
            nDuplex := 2
         ELSE
            nDuplex := 3
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "font"
         xProperty := ::aProp[i,2]
      ELSEIF ::aProp[ i,1 ] == "variables"
         FOR j := 1 TO Len( ::aProp[i,2] )
            __mvPrivate( ::aProp[i,2][j] )
         NEXT
      ENDIF
   NEXT
#ifdef __GTK__
   xTemp := hwg_gp_GetDeviceArea( oPrinter:hDC )
#else
   xTemp := hwg_Getdevicearea( oPrinter:hDCPrn )
#endif
   ::nKoefPix := ( ( xTemp[1]/xTemp[3] + xTemp[2]/xTemp[4] ) / 2 ) / 3.8
   oPrinter:SetMode( nOrientation, nDuplex )
   ::nKoefX := oPrinter:nWidth / nPWidth
   ::nKoefY := oPrinter:nHeight / nPHeight
   IF ( aMethod := aGetSecond( ::aMethods,"onrepinit" ) ) != Nil
      DoScript( aMethod, { p1, p2, p3, p4, p5 } )
   ENDIF
   IF xProperty != Nil
      oFont := hrep_FontFromxml( oPrinter, xProperty, ::nKoefY, aGetSecond( ::aProp,"fonth" ) )
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
      FOR i := 1 TO Len( ::aControls )
         ::PrintItem( ::aControls[i] )
      NEXT
      oPrinter:EndPage()
      IF ::lFinish
         EXIT
      ENDIF
   ENDDO

   oPrinter:EndDoc()
   ::ReleaseObj( ::aControls )
   IF ( aMethod := aGetSecond( ::aMethods,"onrepexit" ) ) != Nil
      DoScript( aMethod )
   ENDIF
   IF lPreview != Nil .AND. lPreview
      oPrinter:Preview()
   ENDIF
   oPrinter:End()

   RETURN Nil

METHOD PrintAsPage( printer, nPageType, lPreview, p1, p2, p3, p4, p5 ) CLASS HRepTmpl
   LOCAL oPrinter := Iif( printer != Nil, Iif( ValType(printer ) == "O",printer,HPrinter():New(printer, .T. ) ), HPrinter():New( , .T. ) )
   LOCAL i, j, aMethod, xProperty, oFont, xTemp, nPWidth, nPHeight, nOrientation := 1, nDuplex
   MEMVAR oReport
   PRIVATE oReport := Self

   IF oPrinter == Nil
      RETURN Nil
   ENDIF
   SetDebugInfo( ::lDebug )
   SetDebugger( ::lDebug )

   FOR i := 1 TO Len( ::aProp )
      IF ::aProp[ i,1 ] == "paper size"
         IF Lower( ::aProp[i,2] ) == "a4"
            nPWidth  := 210
            nPHeight := 297
         ELSEIF Lower( ::aProp[i,2] ) == "a3"
            nPWidth  := 297
            nPHeight := 420
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "orientation"
         IF Lower( ::aProp[i,2] ) != "portrait"
            xTemp    := nPWidth
            nPWidth  := nPHeight
            nPHeight := xTemp
            nOrientation := 2
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "duplex"
         IF Lower( ::aProp[i,2] ) == "no"
            nDuplex := 1
         ELSEIF Lower( ::aProp[i,2] ) == "vertical"
            nDuplex := 2
         ELSE
            nDuplex := 3
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "font"
         xProperty := ::aProp[i,2]
      ELSEIF ::aProp[ i,1 ] == "variables"
         FOR j := 1 TO Len( ::aProp[i,2] )
            __mvPrivate( ::aProp[i,2][j] )
         NEXT
      ENDIF
   NEXT
#ifdef __GTK__
   xTemp := hwg_gp_GetDeviceArea( oPrinter:hDC )
#else
   xTemp := hwg_Getdevicearea( oPrinter:hDCPrn )
#endif
   ::nKoefPix := ( ( xTemp[1]/xTemp[3] + xTemp[2]/xTemp[4] ) / 2 ) / 3.8
   IF !Empty( nPageType ) .AND. nPageType == PAGE_FIRST
      oPrinter:SetMode( nOrientation, nDuplex )
   ENDIF
   ::nKoefX := oPrinter:nWidth / nPWidth
   ::nKoefY := oPrinter:nHeight / nPHeight
   IF ( aMethod := aGetSecond( ::aMethods,"onrepinit" ) ) != Nil
      DoScript( aMethod, { p1, p2, p3, p4, p5 } )
   ENDIF
   IF xProperty != Nil
      oFont := hrep_FontFromxml( oPrinter, xProperty, ::nKoefY, aGetSecond( ::aProp,"fonth" ) )
   ENDIF

   IF !Empty( nPageType ) .AND. nPageType == PAGE_FIRST
      oPrinter:StartDoc( lPreview )
   ENDIF
   ::lNextPage := .F.

   ::lFinish := .T.
   ::oPrinter := oPrinter
   DO WHILE .T.

      oPrinter:StartPage()
      IF oFont != Nil
         oPrinter:SetFont( oFont )
      ENDIF
      ::nTOffset := ::nAOffSet := ::ny := 0
      FOR i := 1 TO Len( ::aControls )
         ::PrintItem( ::aControls[i] )
      NEXT
      oPrinter:EndPage()
      IF ::lFinish
         EXIT
      ENDIF
   ENDDO

   IF !Empty( nPageType ) .AND. nPageType == PAGE_LAST
      oPrinter:EndDoc()
   ENDIF
   ::ReleaseObj( ::aControls )
   IF ( aMethod := aGetSecond( ::aMethods,"onrepexit" ) ) != Nil
      DoScript( aMethod )
   ENDIF

   RETURN Nil

METHOD PrintItem( oItem ) CLASS HRepTmpl
   LOCAL aMethod, lRes := .T. , i, nPenType, nPenWidth
   LOCAL x, y, x2, y2, cText, nJustify, xProperty, nLen, dy, nFirst, ny, nw, x1
   MEMVAR lLastCycle, lSkipItem

   IF oItem:cClass == "area"
      cText := aGetSecond( oItem:aProp, "areatype" )
      IF cText == "DocHeader"
         IF ::oPrinter:nPage > 1
            ::nAOffSet := Val( aGetSecond( oItem:aProp,"geometry" )[4] ) * ::nKoefY
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
   IF !__mvExist( "LSKIPITEM" ) .OR. !lSkipItem
      IF ( aMethod := aGetSecond( oItem:aMethods,"onbegin" ) ) != Nil
         DoScript( aMethod, { oItem } )
      ENDIF
      IF ( aMethod := aGetSecond( oItem:aMethods,"condition" ) ) != Nil
         lRes := DoScript( aMethod )
         IF !lRes .AND. oItem:cClass == "area"
            ::nAOffSet += Val( aGetSecond( oItem:aProp,"geometry" )[4] ) * ::nKoefY
         ENDIF
      ENDIF
   ENDIF
   IF lRes
      xProperty := aGetSecond( oItem:aProp, "geometry" )
      x   := Val( xProperty[1] ) * ::nKoefX
      y   := Val( xProperty[2] ) * ::nKoefY
      x2  := Val( xProperty[5] ) * ::nKoefX
      y2  := Val( xProperty[6] ) * ::nKoefY
      // writelog( xProperty[1]+" "+xProperty[2] )

      IF oItem:cClass == "area"
         oItem:y2 := y2
         // writelog( "Area: "+cText+" "+Iif(::lNextPage,"T","F") )
         IF ( xProperty := aGetSecond( oItem:aProp,"varoffset" ) ) == Nil ;
               .OR. !xProperty
            ::nTOffset := ::nAOffSet := 0
         ENDIF
         IF cText == "Table"
            PRIVATE lLastCycle := .F.
            ::lFinish := .F.
            DO WHILE !lLastCycle
               ::ny := 0
               FOR i := 1 TO Len( oItem:aControls )
                  IF !::lNextPage .OR. oItem:aControls[i]:lMark
                     oItem:aControls[i]:lMark := ::lNextPage := .F.
                     IF __mvExist( "LSKIPITEM" )
                        lSkipItem := .F.
                     ENDIF
                     ::PrintItem( oItem:aControls[i] )
                     IF ::lNextPage
                        RETURN Nil
                     ENDIF
                  ENDIF
               NEXT
               IF ::lNextPage
                  EXIT
               ELSE
                  ::nTOffset := ::ny - y
                  IF ( aMethod := aGetSecond( oItem:aMethods,"onnextline" ) ) != Nil
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
               ::PrintItem( oItem:aControls[i] )
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
         IF ( xProperty := aGetSecond( oItem:aProp,"pentype" ) ) != Nil
            nPenType := Ascan( aPenType, xProperty ) - 1
         ELSE
            nPenType := 0
         ENDIF
         IF ( xProperty := aGetSecond( oItem:aProp,"penwidth" ) ) != Nil
            nPenWidth := Round( xProperty * ::nKoefPix, 0 )
         ELSE
            nPenWidth := Round( ::nKoefPix, 0 )
         ENDIF
#ifdef __GTK__
         oItem:oPen := HGP_Pen():Add( nPenWidth, nPenType )
#else
         oItem:oPen := HPen():Add( nPenType, nPenWidth )
#endif
      ENDIF
      IF oItem:cClass == "label"
         IF ( aMethod := aGetSecond( oItem:aMethods,"expression" ) ) != Nil
            cText := DoScript( aMethod )
         ELSE
            cText := aGetSecond( oItem:aProp, "caption" )
         ENDIF
         IF ValType( cText ) == "C"
            IF ( xProperty := aGetSecond( oItem:aProp,"border" ) ) != Nil .AND. xProperty
               ::oPrinter:Box( x, y, x2, y2, oItem:oPen )
               x += 0.5
               y += 0.5
            ENDIF
            IF ( xProperty := aGetSecond( oItem:aProp,"justify" ) ) == Nil
               nJustify := 0
            ELSE
               nJustify := Ascan( aJustify, xProperty ) - 1
            ENDIF
            IF oItem:obj == Nil
               IF ( xProperty := aGetSecond( oItem:aProp,"font" ) ) != Nil
                  oItem:obj := hrep_FontFromxml( ::oPrinter, xProperty, ::nKoefY, aGetSecond( oItem:aProp,"fonth" ) )
               ENDIF
            ENDIF
            hwg_Settransparentmode( ::oPrinter:hDC, .T. )
            IF ( xProperty := aGetSecond( oItem:aProp,"multiline" ) ) != Nil .AND. xProperty
               nLen := i := 1
               DO WHILE ( i := hb_At( ";",cText,i ) ) > 0
                  i ++
                  nLen ++
               ENDDO
               dy := ( y2 - y ) / nLen
               nFirst := i := 1
               ny := y
               DO WHILE ( i := hb_At( ";",cText,i ) ) > 0
                  ::oPrinter:Say( SubStr( cText,nFirst,i - nFirst ), x, ny, x2, ny + dy, nJustify, oItem:obj )
                  i ++
                  nFirst := i
                  ny += dy
               ENDDO
               ::oPrinter:Say( SubStr( cText,nFirst,Len(cText ) - nFirst + 1 ), x, ny, x2, ny + dy, nJustify, oItem:obj )
            ELSEIF ( xProperty := aGetSecond( oItem:aProp,"inrect" ) ) != Nil .AND. xProperty
               nLen := Len( cText )
               nw := ( x2 - x )/nLen - 1
               x1 := x
               FOR i := 1 TO nLen
                  ::oPrinter:Box( x1, y, x1 + nw, y2, oItem:oPen )
                  ::oPrinter:Say( SubStr( cText,i,1 ), x1 + 0.5, y + 0.5, x1 + nw, y2, 1, oItem:obj )
                  x1 += nw + 1
               NEXT
            ELSE
               ::oPrinter:Say( cText, x, y, x2, y2, nJustify, oItem:obj )
            ENDIF
            hwg_Settransparentmode( ::oPrinter:hDC, .F. )
         ENDIF
      ELSEIF oItem:cClass == "box"
         ::oPrinter:Box( x, y, x2, y2, oItem:oPen )
      ELSEIF oItem:cClass == "vline"
         ::oPrinter:Line( x, y, x, y2, oItem:oPen )
      ELSEIF oItem:cClass == "hline"
         ::oPrinter:Line( x, y, x2, y, oItem:oPen )
      ELSEIF oItem:cClass == "bitmap"
         IF oItem:obj == Nil .AND. ( !::oPrinter:lPreview .OR. ::oPrinter:lUseMeta )
            oItem:obj := hwg_Openbitmap( aGetSecond( oItem:aProp,"bitmap" ), ::oPrinter:hDC )
         ENDIF
         ::oPrinter:Bitmap( x, y, x2, y2, , oItem:obj, aGetSecond( oItem:aProp,"bitmap" ) )
      ENDIF
      ::ny := Max( ::ny, y2 + ::nAOffSet )
   ENDIF

   IF ( aMethod := aGetSecond( oItem:aMethods,"onend" ) ) != Nil
      DoScript( aMethod )
   ENDIF

   RETURN Nil

METHOD ReleaseObj( aControls ) CLASS HRepTmpl
   LOCAL i

   FOR i := 1 TO Len( aControls )
      IF !Empty( aControls[i]:aControls )
         ::ReleaseObj( aControls[i]:aControls )
      ELSE
         IF !Empty( aControls[i]:obj )
            IF aControls[i]:cClass == "bitmap"
               hwg_Deleteobject( aControls[i]:obj )
               aControls[i]:obj := Nil
            ELSEIF aControls[i]:cClass == "label"
               aControls[i]:obj:Release()
               aControls[i]:obj := Nil
            ENDIF
         ENDIF
         IF !Empty( aControls[i]:oPen )
            aControls[i]:oPen:Release()
            aControls[i]:oPen := Nil
         ENDIF
      ENDIF
   NEXT

   RETURN Nil

METHOD Find( cId ) CLASS HRepTmpl
   LOCAL i := Ascan( ::aReports, { |o|o:cId != Nil .AND. o:cId == cId } )

   RETURN Iif( i == 0, Nil, ::aReports[i] )

METHOD CLOSE() CLASS HRepTmpl
   LOCAL i := Ascan( ::aReports, { |o|o:id == ::id } )

   IF i != 0
      ADel( ::aReports, i )
      ASize( ::aReports, Len( ::aReports ) - 1 )
   ENDIF

   RETURN Nil

STATIC FUNCTION ReadRepItem( oCtrlDesc, oContainer )
   LOCAL oCtrl := HRepItem():New( oContainer )
   LOCAL i, j, o, cName, aProp := {}, aMethods := {}, aItems := oCtrlDesc:aItems, xProperty
   LOCAL nPenWidth, nPenType

   oCtrl:cClass   := oCtrlDesc:GetAttribute( "class" )
   oCtrl:aProp    := aProp
   oCtrl:aMethods := aMethods

   FOR i := 1 TO Len( aItems )
      IF aItems[i]:title == "style"
         FOR j := 1 TO Len( aItems[i]:aItems )
            o := aItems[i]:aItems[j]
            IF o:title == "property"
               AAdd( aProp, { Lower( o:GetAttribute("name" ) ), Iif( Empty(o:aItems ),"",hwg_hfrm_GetProperty(o:aItems[1] ) ) } )
            ENDIF
         NEXT
      ELSEIF aItems[i]:title == "method"
         AAdd( aMethods, { cName := Lower( aItems[i]:GetAttribute("name" ) ), RdScript( ,aItems[i]:aItems[1]:aItems[1],, .T. ,cName ) } )
      ELSEIF aItems[i]:title == "part"
         ReadRepItem( aItems[i], Iif( oCtrl:cClass == "area",oCtrl,oContainer ) )
      ENDIF
   NEXT
   IF oCtrl:cClass $ "box.vline.hline" .OR. ( oCtrl:cClass == "label" .AND. ( ;
         ( ( xProperty := aGetSecond( oCtrl:aProp,"border" ) ) != Nil .AND. xProperty ) ;
         .OR. ( ( xProperty := aGetSecond( oCtrl:aProp,"inrect" ) ) != Nil .AND. xProperty ) ) )
      oCtrl:lPen := .T.
   ENDIF

   RETURN Nil

STATIC FUNCTION aGetSecond( arr, xFirst )
   LOCAL i := Ascan( arr, { |a|a[1] == xFirst } )

   RETURN Iif( i == 0, Nil, arr[i,2] )

FUNCTION hwg_aSetSecond( arr, xFirst, xValue )

   LOCAL i := Ascan( arr, { |a|a[1] == xFirst } ), xRet

   IF i != 0
      xRet := arr[i,2]
      IF xValue != Nil
         arr[i,2] := xValue
      ENDIF
   ELSEIF xValue != Nil
      AAdd( arr, { xFirst, xValue } )
   ENDIF

   RETURN xRet

STATIC FUNCTION hrep_FontFromXML( oPrinter, oXmlNode, nKoeff, nFontH )
   LOCAL height := oXmlNode:GetAttribute( "height" ), nPos
   LOCAL weight := oXmlNode:GetAttribute( "weight" )
   LOCAL charset := oXmlNode:GetAttribute( "charset" )
   LOCAL ita   := oXmlNode:GetAttribute( "italic" )
   LOCAL under := oXmlNode:GetAttribute( "underline" )
   LOCAL name  := oXmlNode:GetAttribute( "name" ), i

   IF ValType( HRepTmpl():aFontTable ) == "A"
      IF ( i := Ascan( HRepTmpl():aFontTable,{ |a|Lower(a[1] ) == Lower(name ) } ) ) != 0
         name := HRepTmpl():aFontTable[ i,2 ]
      ENDIF
   ENDIF

   IF !Empty( nFontH )
      height := nFontH * nKoeff
   ELSEIF ( nPos := At( 'M',height ) ) != 0
      height := - Round( Val( SubStr(height,nPos + 1 ) ) * nKoeff, 0 )
   ELSE
      height := Val( height ) * nKoeff
   ENDIF

   weight := Iif( weight != Nil, Val( weight ), 400 )
   IF charset != Nil
      charset := Val( charset )
   ENDIF
   ita    := Iif( ita != Nil, Val( ita ), 0 )
   under  := Iif( under != Nil, Val( under ), 0 )

   RETURN oPrinter:AddFont( name, height, ( weight > 400 ), ( ita > 0 ), ( under > 0 ), charset )
