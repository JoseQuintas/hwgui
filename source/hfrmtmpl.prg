/*
 * $Id: hfrmtmpl.prg,v 1.63 2008-06-18 21:46:33 mlacecilia Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HFormTmpl Class
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#ifdef __XHARBOUR__
#xtranslate HB_AT(<x,...>) => AT(<x>)
#endif
// nando
Static coName
//
Static aClass := { "label", "button", "buttonex", "toolbutton", "checkbox",                   ;
                  "radiobutton", "editbox", "group", "radiogroup",  ;
                  "bitmap","icon", "richedit","datepicker","updown",;
								  "combobox", "line", "toolbar", "panel", "ownerbutton",     ;
								  "browse", "column", "monthcalendar","trackbar","page",      ;
								  "tree", "status","menu","animation" ,             ;
									"progressbar", "shadebutton","listbox","gridex",  ;
									"timer", "link"                                   ;
                }
Static aCtrls := { ;
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
  "AddColumn(HColumn():New(cHeader,Fblock,cValType,nLength,nDec,lEdit,nJusHead, nJusLine, cPicture,bValid, bWhen, Items, ClrBlck, HeadClick ))",;  //oBrw:AddColumn
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
  "HGridEx():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,onInit,onSize,onPaint,onEnter,onGetfocus,onLostfocus,lNoVScroll,lNoBorder,onKeyDown,onPosChg,onDispInfo,nItemCout,lNoLines,TextColor,BackColor,lNoHeader,aBit,Items)" ,;
  "HTimer():New(oPrnt,nId,nInterval, onAction)" ,;
  "HStaticLink():New(oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,cTooltip,TextColor,BackColor,lTransp,Link,VisitedColor,LinkColor,HoverColor)" ;  
  }

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "hxml.ch"

#define  CONTROL_FIRST_ID   34000

Static aPenType  := { "SOLID","DASH","DOT","DASHDOT","DASHDOTDOT" }
Static aJustify  := { "Left","Center","Right" }
Static aShadeID := {"SHS_METAL","SHS_SOFTBUMP","SHS_NOISE","SHS_HARDBUMP","SHS_HSHADE","SHS_VSHADE","SHS_DIAGSHADE","SHS_HBUMP"}
Static aPalette := {"PAL_DEFAULT","PAL_METAL"}

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

REQUEST DIRECTORY

REQUEST DBUSEAREA
REQUEST RECNO
REQUEST DBSKIP
REQUEST DBGOTOP
REQUEST DBCLOSEAREA

CLASS HCtrlTmpl

   DATA cClass
   DATA oParent
   DATA nId
   DATA aControls INIT {}
   DATA aProp, aMethods

   METHOD New( oParent )   INLINE ( ::oParent:=oParent, Aadd( oParent:aControls,Self ), Self )
   METHOD F( nId )
ENDCLASS

METHOD F( nId ) CLASS HCtrlTmpl
Local i, aControls := ::aControls, nLen := Len( aControls ), o

   FOR i := 1 TO nLen
      IF aControls[i]:nId == nId
         Return aControls[i]
      ELSEIF !Empty( aControls[i]:aControls ) .AND. ( o := aControls[i]:F(nId) ) != Nil
         Return o
      ENDIF
   NEXT

Return Nil


CLASS HFormTmpl

   CLASS VAR aForms   INIT {}
   CLASS VAR maxId    INIT 0
   DATA oDlg
   DATA aControls     INIT {}
   DATA aProp
   DATA aMethods
   DATA aVars         INIT {}
   DATA aNames        INIT {}
   DATA aFuncs
   DATA id
   DATA cId
   DATA nContainer    INIT 0
   DATA nCtrlId       INIT CONTROL_FIRST_ID
   DATA cargo

   METHOD Read( fname,cId )
   METHOD Show( nMode,params )
   METHOD ShowMain( params )   INLINE ::Show(1,params)
   METHOD ShowModal( params )  INLINE ::Show(2,params)
   METHOD Close()
   METHOD F( id,n )
   METHOD Find( cId )

ENDCLASS

METHOD Read( fname,cId ) CLASS HFormTmpl
Local oDoc
Local i, j, nCtrl := 0, aItems, o, aProp := {}, aMethods := {}
Local cPre

   IF cId != Nil .AND. ( o := HFormTmpl():Find( cId ) ) != Nil
      Return o
   ENDIF
   IF Left( fname,5 ) == "<?xml"
      oDoc := HXMLDoc():ReadString( fname )
   ELSE
      oDoc := HXMLDoc():Read( fname )
   ENDIF

   IF Empty( oDoc:aItems )
      MsgStop( "Can't open "+fname )
      Return Nil
   ELSEIF oDoc:aItems[1]:title != "part" .OR. oDoc:aItems[1]:GetAttribute( "class" ) != "form"
      MsgStop( "Form description isn't found" )
      Return Nil
   ENDIF

   ::maxId ++
   ::id := ::maxId
   ::cId := cId
   ::aProp := aProp
   ::aMethods := aMethods

   __pp_init()
   Aadd( ::aForms, Self )
   aItems := oDoc:aItems[1]:aItems
   FOR i := 1 TO Len( aItems )
      IF aItems[i]:title == "style"
         FOR j := 1 TO Len( aItems[i]:aItems )
            o := aItems[i]:aItems[j]
            IF o:title == "property"
               IF !Empty( o:aItems )
                  Aadd( aProp, { Lower(o:GetAttribute("name")),o:aItems[1] } )
               ENDIF
            ENDIF
         NEXT
      ELSEIF aItems[i]:title == "method"
         Aadd( aMethods, { Lower(aItems[i]:GetAttribute("name")),CompileMethod(aItems[i]:aItems[1]:aItems[1],Self) } )
         IF aMethods[ (j := Len(aMethods)),1 ] == "common"
            ::aFuncs := ::aMethods[ j,2,2 ]
            FOR j := 1 TO Len( ::aFuncs[2] )
               cPre := "#xtranslate "+ ::aFuncs[2,j,1] + ;
                     "( <params,...> ) => callfunc('"  + ;
                     Upper(::aFuncs[2,j,1]) +"',\{ <params> \}, oDlg:oParent:aFuncs )"
               __Preprocess( cPre )
               cPre := "#xtranslate "+ ::aFuncs[2,j,1] + ;
                     "() => callfunc('"  + ;
                     Upper(::aFuncs[2,j,1]) +"',, oDlg:oParent:aFuncs )"
               __Preprocess( cPre )
            NEXT
         ENDIF
      ELSEIF aItems[i]:title == "part"
         nCtrl ++
         ::nContainer := nCtrl
         ReadCtrl( aItems[i],Self,Self )
      ENDIF
   NEXT
   __pp_free()

Return Self

METHOD Show( nMode,p1,p2,p3 ) CLASS HFormTmpl
Local i, j, cType
Local nLeft, nTop, nWidth, nHeight, cTitle, oFont, lClipper := .F., lExitOnEnter := .F.
Local xProperty, block, bFormExit,nstyle
Local lModal := .f.
Local lMdi :=.F.
Local lMdiChild := .f.
Local lval := .f.
Local cBitmap := nil
Local oBmp := NIL
Memvar oDlg
Private oDlg

   nStyle := DS_ABSALIGN+WS_VISIBLE+WS_SYSMENU+WS_SIZEBOX

   FOR i := 1 TO Len( ::aProp )
      xProperty := hfrm_GetProperty( ::aProp[ i,2 ] )

      IF ::aProp[ i,1 ] == "geometry"
         nLeft   := Val(xProperty[1])
         nTop    := Val(xProperty[2])
         nWidth  := Val(xProperty[3])
         nHeight := Val(xProperty[4])
      ELSEIF ::aProp[ i,1 ] == "caption"
         cTitle := xProperty
      ELSEIF ::aProp[ i,1 ] == "font"
         oFont := hfrm_FontFromxml( xProperty )
      ELSEIF ::aProp[ i,1 ] == "lclipper"
         lClipper := xProperty
      ELSEIF ::aProp[ i,1 ] == "lexitonenter"
         lExitOnEnter := xProperty
      ELSEIF ::aProp[ i,1 ] == "exstyle"
         nStyle := xProperty
      ELSEIF ::aProp[ i,1 ] == "modal"
         lModal := xProperty
      ELSEIF ::aProp[ i,1 ] == "formtype"
         IF nMode == Nil
            lMdi := AT( "mdimain", Lower( xProperty ) ) > 0
            lMdiChild := AT( "mdichild", Lower( xProperty ) ) > 0
            nMode := if(left(xProperty,3) =="dlg",2,1)
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "variables"
         FOR j := 1 TO Len( xProperty )
            __mvPrivate( xProperty[j] )
         NEXT
      // Styles below
      ELSEIF ::aProp[ i,1 ] == "systemmenu"
         IF !xProperty
            nStyle := hwg_bitandinverse( nStyle,WS_SYSMENU )
         endif
      ELSEIF ::aProp[ i,1 ] == "minimizebox"
         IF xProperty
            nStyle += WS_MINIMIZEBOX
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "maximizebox"
         IF xProperty
            nStyle += WS_MAXIMIZEBOX
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "absalignent"
         IF !xProperty
            nStyle := hwg_bitandinverse( nStyle,DS_ABSALIGN )
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "sizeBox"
         IF !xProperty
            nStyle := hwg_bitandinverse( nStyle,WS_SIZEBOX )
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "visible"
         IF !xProperty
            nStyle := hwg_bitandinverse( nStyle,WS_VISIBLE )
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "3dLook"      
         IF xProperty
         	IF ::aControls[j]:cClass == "button" .OR. ::aControls[j]:cClass == "ownerbutton"
             nStyle += DS_3DLOOK 
					ELSE
						 nStyle += Iif(::aControls[j]:cClass = "checkbox",BS_PUSHLIKE,0)
					ENDIF	 
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
         IF Lower( xProperty ) == "popup"
            nStyle += WS_POPUP + WS_CAPTION
         ELSEIF Lower( xProperty ) == "child"
            nStyle += WS_CHILD
         ENDIF

      ELSEIF ::aProp[ i,1 ] == "bitmap"
         cBitmap := xProperty
      ENDIF
   NEXT

   FOR i := 1 TO Len( ::aNames )
      __mvPrivate( ::aNames[i] )
   NEXT
   FOR i := 1 TO Len( ::aVars )
      __mvPrivate( ::aVars[i] )
   NEXT


   oBmp := if( !Empty( cBitmap ), HBitmap():addfile( cBitmap, NIL ), NIL )

   IF nMode == Nil .OR. nMode == 2
      INIT DIALOG ::oDlg TITLE cTitle         ;
          AT nLeft, nTop SIZE nWidth, nHeight ;
          STYLE nStyle ;
          FONT oFont ;
          BACKGROUND BITMAP oBmp
      ::oDlg:lClipper := lClipper
      ::oDlg:lExitOnEnter := lExitOnEnter
      ::oDlg:oParent  := Self

   ELSEIF nMode == 1

      if lMdi
         INIT WINDOW ::oDlg MDI TITLE cTitle    ;
         AT nLeft, nTop SIZE nWidth, nHeight ;
         STYLE IF( nStyle >0 ,nStyle, NIL );
         FONT oFont;
         BACKGROUND BITMAP oBmp
      elseif lMdiChild
         INIT WINDOW ::oDlg  MDICHILD TITLE cTitle    ;
         AT nLeft, nTop SIZE nWidth, nHeight ;
         STYLE IF( nStyle >0 ,nStyle, NIL );
         FONT oFont ;
         BACKGROUND BITMAP oBmp
      else
      INIT WINDOW ::oDlg MAIN TITLE cTitle    ;
          AT nLeft, nTop SIZE nWidth, nHeight ;
          FONT oFont;
          BACKGROUND BITMAP oBmp;
          STYLE IF( nStyle >0 ,nStyle, NIL )

      ENDIF
   ENDIF

   oDlg := ::oDlg

   FOR i := 1 TO Len( ::aMethods )
      IF ( cType := Valtype( ::aMethods[ i,2 ] ) ) == "B"
         block := ::aMethods[ i,2 ]
      ELSEIF cType == "A"
         block := ::aMethods[ i,2,1 ]
      ENDIF
      IF ::aMethods[ i,1 ] == "ondlginit"
         ::oDlg:bInit := block
      ELSEIF ::aMethods[ i,1 ] == "onforminit"
         Eval( block,Self,p1,p2,p3 )
      ELSEIF ::aMethods[ i,1 ] == "onpaint"
         ::oDlg:bPaint := block
      ELSEIF ::aMethods[ i,1 ] == "ondlgexit"
         ::oDlg:bDestroy := block
      ELSEIF ::aMethods[ i,1 ] == "onformexit"
         bFormExit := block
      ENDIF
   NEXT

   j := Len( ::aControls )
   IF j > 0 .AND. ::aControls[j]:cClass == "status"
      CreateCtrl( ::oDlg, ::aControls[j], Self )
      j--
   ENDIF
   // nando
   IF j > 0 .AND. ::aControls[j]:cClass == "timer"
      CreateCtrl( ::oDlg, ::aControls[j], Self )
      j--
   ENDIF
   // nando

   FOR i := 1 TO j
      CreateCtrl( ::oDlg, ::aControls[i], Self )
   NEXT

   ::oDlg:Activate(lModal)

   IF bFormExit != Nil
      Return Eval( bFormExit )
   ENDIF

Return Nil

METHOD F( id,n ) CLASS HFormTmpl
Local i := Ascan( ::aForms, {|o|o:id==id} )

   IF i != 0 .AND. n != Nil
      Return ::aForms[i]:aControls[n]
   ENDIF
Return Iif( i==0, Nil, ::aForms[i] )                 

METHOD Find( cId ) CLASS HFormTmpl
Local i := Ascan( ::aForms, {|o|o:cId!=Nil.and.o:cId==cId} )
Return Iif( i==0, Nil, ::aForms[i] )

METHOD Close() CLASS HFormTmpl
Local i := Ascan( ::aForms, {|o|o:id==::id} )

   IF i != 0
      Adel( ::aForms,i )
      Asize( ::aForms, Len( ::aForms ) - 1 )
   ENDIF
Return Nil

// ------------------------------

Static Function ReadTree( oForm,aParent,oDesc )
Local i, aTree := {}, oNode, subarr

   FOR i := 1 TO Len( oDesc:aItems )
      oNode := oDesc:aItems[i]
      IF oNode:type == HBXML_TYPE_CDATA
         aParent[1] := CompileMethod( oNode:aItems[1],oForm )
      ELSE
         Aadd( aTree, { Nil, oNode:GetAttribute("name"), ;
                 Val( oNode:GetAttribute("id") ), .T. } )
         IF !Empty( oNode:aItems )
            IF ( subarr := ReadTree( oForm,aTail( aTree ),oNode ) ) != Nil
               aTree[ Len(aTree),1 ] := subarr
            ENDIF
         ENDIF
      ENDIF
   NEXT

Return Iif( Empty(aTree), Nil, aTree )

Function ParseMethod( cMethod )
Local arr := {}, nPos1, nPos2, cLine

   IF ( nPos1 := At( Chr(10),cMethod ) ) == 0
      Aadd( arr, Alltrim( cMethod ) )
   ELSE
      Aadd( arr, Alltrim( Left( cMethod,nPos1-1 ) ) )
      DO WHILE .T.
         IF ( nPos2 := hb_At( Chr(10),cMethod,nPos1+1 ) ) == 0
            cLine := AllTrim( Substr( cMethod,nPos1+1 ) )
         ELSE
            cLine := AllTrim( Substr( cMethod,nPos1+1,nPos2-nPos1-1 ) )
         ENDIF
         IF !Empty( cLine )
            Aadd( arr,cLine )
         ENDIF
         IF nPos2 == 0 .OR. Len( arr ) > 2
            EXIT
         ELSE
            nPos1 := nPos2
         ENDIF
      ENDDO
   ENDIF
   IF Right( arr[1],1 ) < " "
      arr[1] := Left( arr[1],Len(arr[1])-1 )
   ENDIF
   IF Len( arr ) > 1 .AND. Right( arr[2],1 ) < " "
      arr[2] := Left( arr[2],Len(arr[2])-1 )
   ENDIF

Return arr

Static Function CompileMethod( cMethod, oForm, oCtrl )
Local arr, arrExe, nContainer := 0, cCode1, cCode, bOldError, bRes

   IF cMethod = Nil .OR. Empty( cMethod )
      Return Nil
   ENDIF
   IF oCtrl != Nil .AND. Left( oCtrl:oParent:Classname(),2 ) == "HC"
      // writelog( oCtrl:cClass+" "+oCtrl:oParent:cClass+" "+ oCtrl:oParent:oParent:Classname() )
      nContainer := oForm:nContainer
   ENDIF
   arr := ParseMethod( cMethod )
   IF Len( arr ) == 1
      cCode := Iif( Lower( Left(arr[1],6) ) == "return", Ltrim( Substr( arr[1],8 ) ), arr[1] )
      bOldError := ERRORBLOCK( {|e|CompileErr(e,cCode)} )
      BEGIN SEQUENCE
         bRes := &( "{||" + __Preprocess( cCode ) + "}" )
      END SEQUENCE
      ERRORBLOCK( bOldError )
      Return bRes
   ELSEIF Lower( Left( arr[1],11 ) ) == "parameters "
      IF Len( arr ) == 2
         cCode := Iif( Lower( Left(arr[2],6) ) == "return", Ltrim( Substr( arr[2],8 ) ), arr[2] )
         cCode := "{|" + Ltrim( Substr( arr[1],12 ) ) + "|" + __Preprocess( cCode ) + "}"
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
         arrExe[2] := RdScript( ,cMethod,1,.T. )
         cCode :=  "{|" + Ltrim( Substr( arr[1],12 ) ) + ;
            "|DoScript(HFormTmpl():F("+Ltrim(Str(oForm:id))+Iif(nContainer!=0,","+Ltrim(Str(nContainer)),"")+"):" + ;
            Iif( oCtrl==Nil,"aMethods["+Ltrim(Str(Len(oForm:aMethods)+1))+",2,2],{", ;
                   cCode1+":aMethods["+ ;
                   Ltrim(Str(Len(oCtrl:aMethods)+1))+",2,2],{" ) + ;
                   Ltrim( Substr( arr[1],12 ) ) + "})" + "}"
         arrExe[1] := &cCode
         Return arrExe
      ENDIF
   ENDIF

   cCode1 := Iif( nContainer==0, ;
         "aControls["+Ltrim(Str(Len(oForm:aControls)))+"]", ;
         "F("+Ltrim(Str(oCtrl:nId))+")" )
   arrExe := Array(2)
   arrExe[2] := RdScript( ,cMethod,,.T. )
   cCode :=  "{||DoScript(HFormTmpl():F("+Ltrim(Str(oForm:id))+Iif(nContainer!=0,","+Ltrim(Str(nContainer)),"")+"):" + ;
      Iif( oCtrl==Nil,"aMethods["+Ltrim(Str(Len(oForm:aMethods)+1))+",2,2])", ;
             cCode1+":aMethods["+   ;
             Ltrim(Str(Len(oCtrl:aMethods)+1))+",2,2])" ) + "}"
   arrExe[1] := &cCode

Return arrExe

STATIC FUNCTION CompileErr( e, stroka )

   MsgStop( ErrorMessage( e ) + Chr(10)+Chr(13) + "in" + Chr(10)+Chr(13) + ;
          AllTrim(stroka),"Script compiling error" )
   BREAK
RETURN .T.

Static Function ReadCtrl( oCtrlDesc, oContainer, oForm )
Local oCtrl := HCtrlTmpl():New( oContainer )
Local i, j, o, cName, aProp := {}, aMethods := {}, aItems := oCtrlDesc:aItems

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
               IF ( cName := Lower( o:GetAttribute("name") ) ) == "varname"
                  Aadd( oForm:aVars, hfrm_GetProperty(o:aItems[1]) )
               ELSEIF cName == "name"
                  Aadd( oForm:aNames, hfrm_GetProperty(o:aItems[1]) )
               ENDIF
               IF cName == "atree"
                  Aadd( aProp, { cName, ReadTree( oForm,,o ) } )
               ELSE
                  Aadd( aProp, { cName,Iif( Empty(o:aItems),"",o:aItems[1] ) } )
               ENDIF
            ENDIF
         NEXT
      ELSEIF aItems[i]:title == "method"
         Aadd( aMethods, { Lower(aItems[i]:GetAttribute("name")),CompileMethod(aItems[i]:aItems[1]:aItems[1],oForm,oCtrl) } )
      ELSEIF aItems[i]:title == "part"
         ReadCtrl( aItems[i],oCtrl,oForm )
      ENDIF
   NEXT

Return Nil

#define TBS_AUTOTICKS                1
#define TBS_TOP                      4
#define TBS_BOTH                     8
#define TBS_NOTICKS                 16

Static Function CreateCtrl( oParent, oCtrlTmpl, oForm )
Local i, j, temp, oCtrl, stroka, varname, xProperty, cType, cPName
Local nCtrl := Ascan( aClass, oCtrlTmpl:cClass ), xInitValue, cInitName, cVarName
// LOCAL DE NANDO BROWSE
Local cAliasdbf, caArray, nHeadRows:= 1, nFootRows:= 0, lDispHead := .T., lDispSep:= .T., lSep3d:= .F., ladjright:= .T.
Local nheadColor:= 0, nsepColor:= 12632256, nLeftCol:= 0, nfreeze:= 0, nColumns := 0
#ifdef __XHARBOUR__
Local cKey:= "" ,cRelexpr:="", cLink:=""
#else
Local cKey:= ""
#endif
//
MEMVAR oPrnt, nId, nInitValue, cInitValue, dInitValue, nStyle, nLeft, nTop
MEMVAR onInit,onSize,onPaint,onEnter,onGetfocus,onLostfocus,lNoVScroll,lAppend,lAutoedit,bUpdate,onKeyDown,onPosChg
MEMVAR nWidth, nHeight, oFont, lNoBorder, bSetGet, ctoolTip
MEMVAR name, nMaxLines, nLength, lVertical, brwType, TickStyle, TickMarks, Tabs, tmp_nSheet
MEMVAR aImages, lEditLabels, aParts , Link
MEMVAR lEnabled, shadeID, palette, granularity, highlight, coloring, shcolor
// nando
MEMVAR fBlock, cHeader, nJusHead, lEdit, nJusLine, bWhen, bValid, ClrBlck, HeadClick
MEMVAR cValType, nDec, cPicture, lNoLines, lNoHeader,lMultiSelect, Items, nInterval, onAction
MEMVAR nBitIp, nState, onClick, amenu, ccaption, hbmp, nBStyle, hIco

//

#ifndef __XHARBOUR__
MEMVAR cLink, cRelExpr
PRIVATE cLink := ""
PRIVATE cRelexpr := ""
#endif
Public cOName
   IF nCtrl == 0
      IF Lower( oCtrlTmpl:cClass ) == "pagesheet"
         tmp_nSheet ++
         oParent:StartPage( Tabs[tmp_nSheet] )
         FOR i := 1 TO Len( oCtrlTmpl:aControls )
            CreateCtrl( oParent, oCtrlTmpl:aControls[i], oForm )
         NEXT
         oParent:EndPage()
      ENDIF
      Return Nil
   ENDIF

   /* Declaring of variables, which are in the appropriate 'New()' function */
   stroka := aCtrls[nCtrl]
   IF ( i := At( "New(", stroka ) ) != 0
      i += 4
      DO WHILE .T.
         IF ( j := hb_At( ",",stroka,i ) ) != 0 .OR. ( j := hb_At( ")",stroka,i ) ) != 0
            IF j-i > 0
               varname := Substr(stroka,i,j-i)
               __mvPrivate( varname )
               IF Substr( varname, 2 ) == "InitValue"
                  cInitName  := varname
                  xInitValue := Iif( Left(varname,1)=="n",1,Iif( Left(varname,1)=="c","",.F. ) )
               ENDIF
               stroka := Left( stroka,i-1 ) + "m->" + Substr( stroka,i )
               i := j+4
            ELSE
               i := j+1
            ENDIF
         ELSE
            EXIT
         ENDIF
      ENDDO
   ENDIF
   oPrnt  := oParent
   nId    := oCtrlTmpl:nId
   nStyle := 0
   ShadeID := 0
   lEnabled := .T.
   // nando
   lAppend   := .F.
	 lAutoedit := .F.
	 lMultiSelect := .F.
   lNoLines  := .F.
   lNoHeader := .F.
   lNoBorder := .F.
   lNoVScroll:= .F.
   // columns
   //cValType := "C" 
   caArray := {}
   nLength := Nil
   nDec := 0
	 nJusHead := 0
	 nJusLine := 0   
	 lEdit    := .F.
	 cpicture := Nil
	 Items := {}
	 nInterval := 0
	 onAction := Nil
	 bWhen := Nil
	 bValid := Nil
	 ClrBlck := Nil
	 HeadClick := Nil
	 // toolbar
	 cCaption := ""
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
      xProperty := hfrm_GetProperty( oCtrlTmpl:aProp[ i,2 ] )
      cPName := oCtrlTmpl:aProp[ i,1 ]
      //msginfo(cpname)
      IF cPName == "geometry"
         nLeft   := Val(xProperty[1])
         nTop    := Val(xProperty[2])
         nWidth  := Val(xProperty[3])
         nHeight := Val(xProperty[4])
         IF __ObjHasMsg( oParent,"ID")
            nLeft -= oParent:nLeft
            nTop -= oParent:nTop
            IF __ObjHasMsg( oParent:oParent,"ID")
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
         nStyle += Iif( xProperty=="Center",SS_CENTER,Iif( xProperty=="Right",SS_RIGHT,0 ) )
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
            nStyle += ES_AUTOHSCROLL + IIF(oCtrlTmpl:cClass == "browse",WS_HSCROLL,0)
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
						 nStyle += Iif(oCtrlTmpl:cClass = "checkbox",BS_PUSHLIKE,0)
					ENDIF	 
         ENDIF
      ELSEIF cPName == "effect"
            ShadeID := Ascan( aShadeID, xProperty ) - 1
      ELSEIF cPName == "palette"
            palette := Ascan( aPalette, xProperty ) - 1
      ELSEIF cPName == "vscroll"
         IF xProperty
            nStyle += WS_VSCROLL
         ENDIF
      // nando layout
      ELSEIF cPName == "alignment"
         nStyle += Iif( xProperty=="top",BS_TOP,Iif( xProperty=="bottom",BS_BOTTOM,0 ) )
         nStyle += Iif( "right"$xProperty,BS_RIGHTBUTTON,0 )
		  ELSEIF cPName == "layout"
		     nStyle += val(xProperty)
			ELSEIF cPName == "checked"
				IF xProperty
		      nStyle += 1
		    ENDIF 
		  ELSEIF cPName == "taborientation" //array="0-Top,2-Bottom,128-Left,129-Right">
		 		nStyle += val(xProperty)
      ELSEIF cPName == "tabstretch" //array="0-Single Row,1-Multiple Rows">
				nStyle += val(xProperty)
      // NANDO
      ELSEIF cPName == "bitmap" .AND. oCtrlTmpl:cClass == "buttonex"
        hBmp := HBitmap():addfile( trim(xProperty) )
        hBmp := hBmp:handle
      ELSEIF cPName == "icon" .AND. oCtrlTmpl:cClass == "buttonex"
        hIco := HIcon():addfile( xProperty, NIL )       
      ELSEIF cPName == "pictureposition"         
        nBStyle := val(xProperty)
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
        caArray := iif( xProperty != Nil .AND. !empty(xProperty),&(xProperty) , {} )
      ELSEIF cPName == "childorder"
        cKey := IIF( xProperty != Nil .AND. !empty(xProperty),trim(xProperty),"")    
      ELSEIF cPName == "relationalexpr"            
        crelexpr := IIF( xProperty != Nil .AND. !empty(xProperty),trim(xProperty),"")    
      ELSEIF cPName == "linkmaster"            
        clink := IIF( xProperty != Nil .AND. !empty(xProperty),trim(xProperty),"")    
      ELSEIF cPName == "filedbf"            
          IF !EMPTY(xProperty) 
            cAliasdbf := LEFT(CutPath( xProperty ),AT(".",CutPath( xProperty ))-1)
            IF select(LEFT(CutPath( xProperty ),AT(".",CutPath( xProperty ))-1)) = 0
               USE (xProperty) NEW SHARED ALIAS (LEFT(CutPath( xProperty ),AT(".",CutPath( xProperty ))-1))  //ftmp
            ENDIF
            select (LEFT(CutPath( xProperty ),AT(".",CutPath( xProperty ))-1))
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
        cHeader := Iif( xProperty != Nil ,xProperty ,"")
      ELSEIF cPName == "fieldname" 
        fblock  := Lower(Iif( xProperty != Nil .AND. !empty(xProperty),xProperty ,FieldName(i)))
      ELSEIF cPName == "fieldexpr"                              
        fblock  := Lower(Iif( xProperty != Nil .AND. !empty(xProperty),xProperty ,fblock))
       // IF !(cAlias == cTmpAlias) .AND. cTmpAlias $ cCampo  
       // 	cCampo := STRTRAN(cCampo,cTmpAlias,cAlias)
			//	ENDIF        
			ELSEIF cPName == "length"
				nLength :=	xProperty  //iif(xProperty != Nil,xProperty,10)
		  ELSEIF cPName == "picture"
   			cPicture := IIF(empty(xProperty),Nil,xProperty)
   	  ELSEIF cPName == "editable"
   	    lEdit := xProperty
   	  ELSEIF cPName == "justifyheader"   
 	     	 nJusHead := val(xProperty )
      ELSEIF cPName == "justifyline"
 				nJusLine := val(xProperty )
      // fim de column 
      // toolbutton
      ELSEIF cPName == "caption" .AND.oCtrlTmpl:cClass = "toolbutton"
        ccaption := xProperty 
			// FiM NANDO   			
      ELSEIF cPName == "atree"
         BuildMenu( xProperty,oForm:oDlg:handle,oForm:oDlg )
      ELSE
        IF cPName == "tooltip"
            cPName := "c" + cPName
        ELSEIF cPName == "name"
           __mvPrivate( cPName )
           cOName := IIF(oCtrlTmpl:cClass = "browse" .OR. oCtrlTmpl:cClass = "toolbar",xProperty ,cOname)
        ENDIF
         /* Assigning the value of the property to the variable with
            the same name as the property */
         __mvPut( cPName, xProperty )

         IF cPName == "varname" .AND.!empty(xProperty)
            cVarName := xProperty
            bSetGet := &( "{|v|Iif(v==Nil,"+xProperty+","+xProperty+":=v)}" )
            IF __mvGet( xProperty ) == Nil
               /* If the variable with 'varname' name isn't initialized
                  while onFormInit procedure, we assign her the init value */
               __mvPut( xProperty, xInitValue )
            ELSEIF cInitName != Nil
               /* If it is initialized, we assign her value to the 'init'
                  variable ( cInitValue, nInitValue, ... ) */
               __mvPut( cInitName, __mvGet( xProperty ) )
            ENDIF
         ELSEIF Substr( cPName, 2 ) == "initvalue"
            xInitValue := xProperty
         ENDIF
      ENDIF
   NEXT
   FOR i := 1 TO Len( oCtrlTmpl:aMethods )
      IF ( cType := Valtype( oCtrlTmpl:aMethods[ i,2 ] ) ) == "B"
         __mvPut( oCtrlTmpl:aMethods[ i,1 ], oCtrlTmpl:aMethods[ i,2 ] )
      ELSEIF cType == "A"
         __mvPut( oCtrlTmpl:aMethods[ i,1 ], oCtrlTmpl:aMethods[ i,2,1 ] )
      ENDIF
   NEXT

	 // NANDO
   IF oCtrlTmpl:cClass == "updown"
   		bSetGet := IIF(bSetGet == Nil,'1',bSetGet )
   		xInitValue := IIF(xInitValue == Nil, '1', xInitValue)
   ENDIF
	 //
   IF oCtrlTmpl:cClass == "combobox"
      IF ( i := Ascan( oCtrlTmpl:aProp,{|a|Lower(a[1])=="nmaxlines"} ) ) > 0
         nHeight := nHeight * nMaxLines
      ELSE
         nHeight := nHeight * 4
      ENDIF
   ELSEIF oCtrlTmpl:cClass == "line"
      nLength := Iif( lVertical==Nil.OR.!lVertical, nWidth, nHeight )
   ELSEIF oCtrlTmpl:cClass == "browse"
      brwType := Iif( brwType == Nil .OR. brwType == "dbf",BRW_DATABASE,BRW_ARRAY )
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
         FOR i := 1 TO Len(aParts)
            aParts[i] := Val(aParts[i])
         NEXT
      ENDIF
      onInit := {|o|o:Move(,,o:nWidth-1)}
   ENDIF
   // criacao
   IF oCtrlTmpl:cClass == "column" 
     cValType := TYPE("&fblock")
	   IF &(coName):Type = BRW_DATABASE .AND.!EMPTY(ALIAS())
       cAliasDbf := ALIAS()
       temp = strtran(UPPER(fblock),alias()+"->","")
       *- verificar se tem mais de um campo
       temp = substr(temp,1,IIF(at('+',temp)>0,at('+',temp)-1,LEN(temp)))
       j:={}
       AEVAL( &cAliasDbf->((DBSTRUCT())), {|aField| aadd(j,aField[1])} )
       IF m->nLength = Nil
 	        // m->nLength := &cTmpAlias->(fieldlen(ascan(j,temp)))
          // m->nLength := IIF(m->nLength = 0 ,IIF(type("&cCampo") = "C",LEN(&cCampo),10),m->nLength)
 	        m->nLength := &cAliasDbf->(fieldlen(ascan(j,temp)))
          m->nLength := IIF(m->nLength = 0 ,IIF(type("&fblock") = "C",LEN(&fblock),10),m->nLength)
       ENDIF  
 	     m->nDec := &cAliasDbf->(FIELDDEC(ascan(j,temp)))
       cHeader  := Iif( cHeader == Nil .OR. EMPTY(cHeader) ,temp,cHeader)
       fblock   := {|| &fblock }
     ELSE  //IF brwtype = 1
       m->nLength := IIF(m->nLength = Nil ,10,m->nLength)
       fblock := IIF(fblock = Nil,".T.",fblock)
       fblock := IIF(cvaltype="B",&fblock,{|| &fblock })  
		 ENDIF  
 	   IF !empty(cPicture) .AND. AT(".9",cPicture) > 0 .AND. nDec = 0
	       m->nDec := LEN(SUBSTR(cPicture,AT(".9",cPicture)+1))
		 ENDIF    
   	 stroka   := cOName+":"+stroka
   ENDIF
   IF oCtrlTmpl:cClass == "toolbutton"
   	 stroka   := cOname+":"+stroka
   ENDIF	 
   oCtrl := &stroka
   IF oCtrlTmpl:cClass == "browse" 
   	  oCtrl:aColumns := {}
   	  oCtrl:freeze:= nfreeze
      oCtrl:nHeadRows:= nHeadRows
    	oCtrl:nFootRows:= nFootRows
    	oCtrl:lDispHead:= lDispHead
      oCtrl:lDispSep:= lDispSep
      oCtrl:lSep3d:= lSep3d
      oCtrl:headColor:= nheadColor
      oCtrl:sepColor:= nsepColor
      oCtrl:nLeftCol:= nLeftCol
      oCtrl:lAdjRight := ladjright
      */
      oCtrl:nColumns := nColumns
      oCtrl:Type := brwType
      IF brwtype = BRW_DATABASE   	    //oCtrl:type = 1         	  
        // CRIAR AS RELA€OES E O LINK
   	    oCtrl:alias := cAliasdbf
        IF !empty(cKey)
          &(oCtrl:alias)->(DBSETORDER(cKey))
   	 	    cKey := (oCtrl:alias)->(ordkey(cKey))
   		    ckey := IIF(At('+',ckey) > 0,LEFT(ckey, At('+',ckey)-1),ckey)
        ENDIF		
        crelexpr := IIF( !empty(crelexpr),crelexpr,cKey )   
        IF !EMPTY(crelexpr+clink)
          &clink->(DBSETRELATION(oCtrl:alias, {|| &crelexpr },crelexpr)) 
   	      &(oCtrl:alias)->(DBSETFILTER(&("{|| "+crelexpr+" = "+clink+"->("+crelexpr+")}"), "&crelexpr = &clink->(&crelexpr) " ))
 	      ENDIF
	      // fim dos relacionamentos
 		    IF Empty( oCtrlTmpl:aControls )
          select (oCtrl:alias)        
          j := (DBSTRUCT())  
          //AEVAL( aStruct, {|aField| QOUT(aField[DBS_NAME])} )  
          FOR i := 1 TO IIF(oCtrl:nColumns=0,FCOUNT(),oCtrl:nColumns)
            //"AddColumn(HColumn():New(cHeader,Fblock,cValType,nLength,nDec,lEdit,nJusHead, nJusLine, cPicture,bValid, bWhen, Items, bClrBlck, bHeadClick ))",;  //oBrw:AddColumn	      
            m->cHeader := FieldName(i)
					  m->Fblock := FieldBlock(FieldName(i))          
 	          m->cValType := j[i,2]  //TYPE("FieldName(i)")
 	          m->nLength := j[i,3] //len(&(FieldName(i)))
 	          m->nDec := j[i,4]
 	          m->cPicture := Nil
 	          ledit := .t.
 	          oCtrl:AddColumn(HColumn():New(cHeader,Fblock,cValType,nLength,nDec,lEdit))
          NEXT
			  ENDIF
			ELSE
        oCtrl:aArray := caArray  //IIF(TYPE("caArray")="C",&(caArray),caArray)
 	      oCtrl:AddColumn( HColumn():New( ,{|v,o|Iif(v!=Nil,o:aArray[o:nCurrent]:=v,o:aArray[o:nCurrent])},'C',100,0))
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
   IF !Empty( oCtrlTmpl:aControls )
      IF oCtrlTmpl:cClass == "page"
         __mvPrivate( "tmp_nSheet" )
         __mvPut( "tmp_nSheet", 0 )
      ENDIF
      FOR i := 1 TO Len( oCtrlTmpl:aControls )
         CreateCtrl( Iif( oCtrlTmpl:cClass=="group".OR.oCtrlTmpl:cClass=="radiogroup",oParent,oCtrl ), oCtrlTmpl:aControls[i], oForm )
      NEXT
      IF oCtrlTmpl:cClass=="radiogroup"
         HRadioGroup():EndGroup()
      ENDIF
   ENDIF

Return Nil

Function RadioNew( oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,TextColor,BackColor,nInitValue,bSetGet )
Local oCtrl := HGroup():New( oPrnt,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption,oFont,onInit,onSize,onPaint,TextColor,BackColor )
   HRadioGroup():New( nInitValue,bSetGet )
Return oCtrl


Function Font2XML( oFont )
Local aAttr := {}

   Aadd( aAttr, { "name",oFont:name } )
   Aadd( aAttr, { "width",Ltrim(Str(oFont:width,5)) } )
   Aadd( aAttr, { "height",Ltrim(Str(oFont:height,5)) } )
   IF oFont:weight != 0
      Aadd( aAttr, { "weight",Ltrim(Str(oFont:weight,5)) } )
   ENDIF
   IF oFont:charset != 0
      Aadd( aAttr, { "charset",Ltrim(Str(oFont:charset,5)) } )
   ENDIF
   IF oFont:Italic != 0
      Aadd( aAttr, { "italic",Ltrim(Str(oFont:Italic,5)) } )
   ENDIF
   IF oFont:Underline != 0
      Aadd( aAttr, { "underline",Ltrim(Str(oFont:Underline,5)) } )
   ENDIF

Return HXMLNode():New( "font", HBXML_TYPE_SINGLE, aAttr )

Function hfrm_FontFromXML( oXmlNode )
Local width  := oXmlNode:GetAttribute( "width" )
Local height := oXmlNode:GetAttribute( "height" )
Local weight := oXmlNode:GetAttribute( "weight" )
Local charset := oXmlNode:GetAttribute( "charset" )
Local ita   := oXmlNode:GetAttribute( "italic" )
Local under := oXmlNode:GetAttribute( "underline" )

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

Return HFont():Add( oXmlNode:GetAttribute( "name" ),  ;
                    width, height, weight, charset,   ;
                    ita, under )

Function hfrm_Str2Arr( stroka )
Local arr := {}, pos1 := 2, pos2 := 1

   IF Len( stroka ) > 2
      DO WHILE pos2 > 0
         DO WHILE Substr( stroka,pos1,1 ) <= ' ' ; pos1 ++ ; ENDDO
         pos2 := hb_At( ',',stroka,pos1 )
         Aadd( arr, Trim( Substr( stroka,pos1,Iif( pos2>0,pos2-pos1,hb_At('}',stroka,pos1)-pos1 ) ) ) )
         pos1 := pos2 + 1
      ENDDO
   ENDIF

Return arr

Function hfrm_Arr2Str( arr )
Local stroka := "{", i, cType

   FOR i := 1 TO Len( arr )
      IF i > 1
         stroka += ","
      ENDIF
      cType := Valtype( arr[i] )
      IF cType == "C"
         stroka += arr[i]
      ELSEIF cType == "N"
         stroka += Ltrim( Str( arr[i] ) )
      ENDIF
   NEXT

Return stroka + "}"

Function hfrm_GetProperty( xProp )
Local c

   IF Valtype( xProp ) == "C"
      c := Left( xProp,1 )
      IF c == "["
         xProp := Substr( xProp,2,Len(xProp)-2 )
      ELSEIF c == "."
         xProp := ( Substr( xProp,2,1 ) == "T" )
      ELSEIF c == "{"
         xProp := hfrm_Str2Arr( xProp )
      ELSE
         xProp := Val( xProp )
      ENDIF
   ENDIF

Return xProp

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

   METHOD New( oParent )   INLINE ( ::oParent:=oParent, Aadd( oParent:aControls,Self ), Self )
ENDCLASS

CLASS HRepTmpl

   CLASS VAR aReports INIT {}
   CLASS VAR maxId    INIT 0
   DATA aControls     INIT {}
   DATA aProp
   DATA aMethods
   DATA aVars         INIT {}
   DATA aFuncs
   DATA id
   DATA cId

   DATA nKoefX, nKoefY, nKoefPix
   DATA nTOffset, nAOffSet, ny
   DATA lNextPage, lFinish
   DATA oPrinter

   METHOD Read( fname,cId )
   METHOD Print( printer, lPreview, p1, p2, p3 )
   METHOD PrintItem( oItem )
   METHOD ReleaseObj( aControls )
   METHOD Find( cId )
   METHOD Close()

ENDCLASS

METHOD Read( fname,cId ) CLASS HRepTmpl
Local oDoc
Local i, j, aItems, o, aProp := {}, aMethods := {}
Local cPre

   IF cId != Nil .AND. ( o := HFormTmpl():Find( cId ) ) != Nil
      Return o
   ENDIF

   IF Left( fname,5 ) == "<?xml"
      oDoc := HXMLDoc():ReadString( fname )
   ELSE
      oDoc := HXMLDoc():Read( fname )
   ENDIF

   IF Empty( oDoc:aItems )
      MsgStop( "Can't open "+fname )
      Return Nil
   ELSEIF oDoc:aItems[1]:title != "part" .OR. oDoc:aItems[1]:GetAttribute( "class" ) != "report"
      MsgStop( "Report description isn't found" )
      Return Nil
   ENDIF

   ::maxId ++
   ::id := ::maxId
   ::cId := cId
   ::aProp := aProp
   ::aMethods := aMethods

   __pp_init()
   Aadd( ::aReports, Self )
   aItems := oDoc:aItems[1]:aItems
   FOR i := 1 TO Len( aItems )
      IF aItems[i]:title == "style"
         FOR j := 1 TO Len( aItems[i]:aItems )
            o := aItems[i]:aItems[j]
            IF o:title == "property"
               IF !Empty( o:aItems )
                  Aadd( aProp, { Lower(o:GetAttribute("name")),hfrm_GetProperty(o:aItems[1]) } )
               ENDIF
            ENDIF
         NEXT
      ELSEIF aItems[i]:title == "method"
         Aadd( aMethods, { Lower(aItems[i]:GetAttribute("name")),RdScript(,aItems[i]:aItems[1]:aItems[1],,.T.) } )
         IF aMethods[ (j := Len(aMethods)),1 ] == "common"
            ::aFuncs := ::aMethods[ j,2 ]
            FOR j := 1 TO Len( ::aFuncs[2] )
               cPre := "#xtranslate "+ ::aFuncs[2,j,1] + ;
                     "( <params,...> ) => callfunc('"  + ;
                     Upper(::aFuncs[2,j,1]) +"',\{ <params> \}, oReport:aFuncs )"
               __Preprocess( cPre )
               cPre := "#xtranslate "+ ::aFuncs[2,j,1] + ;
                     "() => callfunc('"  + ;
                     Upper(::aFuncs[2,j,1]) +"',, oReport:aFuncs )"
               __Preprocess( cPre )
            NEXT
         ENDIF
      ELSEIF aItems[i]:title == "part"
         ReadRepItem( aItems[i],Self )
      ENDIF
   NEXT
   __pp_free()

Return Self

METHOD Print( printer, lPreview, p1, p2, p3 ) CLASS HRepTmpl
Local oPrinter := Iif( printer != Nil, Iif( Valtype(printer)=="O",printer,HPrinter():New(printer,.T.) ), HPrinter():New(,.T.) )
Local i, j, aMethod, xProperty, oFont, xTemp, nPWidth, nPHeight, nOrientation := 1

Memvar oReport
Private oReport := Self

   IF oPrinter == Nil
      Return Nil
   ENDIF
   FOR i := 1 TO Len( ::aProp )
      IF ::aProp[ i,1 ] == "paper size"
         IF Lower(::aProp[i,2]) == "a4"
            nPWidth  := 210
            nPHeight := 297
         ELSEIF Lower(::aProp[i,2]) == "a3"
            nPWidth  := 297
            nPHeight := 420
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "orientation"
         IF Lower(::aProp[i,2]) != "portrait"
            xTemp    := nPWidth
            nPWidth  := nPHeight
            nPHeight := xTemp
            nOrientation := 2
         ENDIF
      ELSEIF ::aProp[ i,1 ] == "font"
         xProperty := ::aProp[i,2]
      ELSEIF ::aProp[ i,1 ] == "variables"
         FOR j := 1 TO Len( ::aProp[i,2] )
            __mvPrivate( ::aProp[i,2][j] )
         NEXT
      ENDIF
   NEXT
   xTemp := GetDeviceArea( oPrinter:hDCPrn )
   ::nKoefPix := ( ( xTemp[1]/xTemp[3] + xTemp[2]/xTemp[4] ) / 2 ) / 3.8
   oPrinter:SetMode( nOrientation )
   ::nKoefX := oPrinter:nWidth / nPWidth
   ::nKoefY := oPrinter:nHeight / nPHeight
   IF ( aMethod := aGetSecond( ::aMethods,"onrepinit" ) ) != Nil
      DoScript( aMethod,{ p1,p2,p3 } )
   ENDIF
   IF xProperty != Nil
      oFont := hrep_FontFromxml( oPrinter,xProperty,aGetSecond(::aProp,"fonth")*::nKoefY )
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

Return Nil

METHOD PrintItem( oItem ) CLASS HRepTmpl
Local aMethod, lRes := .T., i, nPenType, nPenWidth
Local x, y, x2, y2, cText, nJustify, xProperty, nLines, dy, nFirst, ny

Memvar lLastCycle, lSkipItem

   IF oItem:cClass == "area"
      cText := aGetSecond( oItem:aProp,"areatype" )
      IF cText == "DocHeader"
         IF ::oPrinter:nPage > 1
            ::nAOffSet := Val( aGetSecond( oItem:aProp,"geometry" )[4] ) * ::nKoefY
            Return Nil
         ENDIF
      ELSEIF cText == "DocFooter"
         IF ::lNextPage
            Return Nil
         ENDIF
      ELSEIF cText == "Table" .AND. ::lNextPage
         Private lSkipItem := .T.
      ENDIF
   ENDIF
   IF !__mvExist("LSKIPITEM") .OR. !lSkipItem
      IF ( aMethod := aGetSecond( oItem:aMethods,"onbegin" ) ) != Nil
         DoScript( aMethod )
      ENDIF
      IF ( aMethod := aGetSecond( oItem:aMethods,"condition" ) ) != Nil
         lRes := DoScript( aMethod )
         IF !lRes .AND. oItem:cClass == "area"
            ::nAOffSet += Val( aGetSecond( oItem:aProp,"geometry" )[4] ) * ::nKoefY
         ENDIF
      ENDIF
   ENDIF
   IF lRes
      xProperty := aGetSecond( oItem:aProp,"geometry" )
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
            Private lLastCycle := .F.
            ::lFinish := .F.
            DO WHILE !lLastCycle
               ::ny := 0
               FOR i := 1 TO Len( oItem:aControls )
                  IF !::lNextPage .OR. oItem:aControls[i]:lMark
                     oItem:aControls[i]:lMark := ::lNextPage := .F.
                     IF __mvExist("LSKIPITEM")
                        lSkipItem := .F.
                     ENDIF
                     ::PrintItem( oItem:aControls[i] )
                     IF ::lNextPage
                        Return Nil
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
               ::nAOffSet += y2-y+1 - ( ::ny - y )
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
            Return Nil
         ENDIF
      ENDIF

      IF oItem:lPen .AND. oItem:oPen == Nil
         IF ( xProperty := aGetSecond( oItem:aProp,"pentype" ) ) != Nil
            nPenType := Ascan( aPenType,xProperty ) - 1
         ELSE
            nPenType := 0
         ENDIF
         IF ( xProperty := aGetSecond( oItem:aProp,"penwidth" ) ) != Nil
            nPenWidth := Round( xProperty * ::nKoefPix, 0 )
         ELSE
            nPenWidth := Round( ::nKoefPix, 0 )
         ENDIF
         oItem:oPen := HPen():Add( nPenType,nPenWidth )
         // writelog( str(nPenWidth) + " " + str(::nKoefY) )
      ENDIF
      IF oItem:cClass == "label"
         IF ( aMethod := aGetSecond( oItem:aMethods,"expression" ) ) != Nil
            cText := DoScript( aMethod )
         ELSE
            cText := aGetSecond( oItem:aProp,"caption" )
         ENDIF
         IF Valtype( cText ) == "C"
            IF ( xProperty := aGetSecond( oItem:aProp,"border" ) ) != Nil ;
                   .AND. xProperty
               ::oPrinter:Box( x,y,x2,y2 )
               x += 0.5
               y += 0.5
            ENDIF
            IF ( xProperty := aGetSecond( oItem:aProp,"justify" ) ) == Nil
               nJustify := 0
            ELSE
               nJustify := Ascan( aJustify,xProperty ) - 1
            ENDIF
            IF oItem:obj == Nil
               IF ( xProperty := aGetSecond( oItem:aProp,"font" ) ) != Nil
                  oItem:obj := hrep_FontFromxml( ::oPrinter,xProperty,aGetSecond(oItem:aProp,"fonth")*::nKoefY )
               ENDIF
            ENDIF
            SetTransparentMode( ::oPrinter:hDC,.T. )
            IF ( xProperty := aGetSecond( oItem:aProp,"multiline" ) ) != Nil ;
                   .AND. xProperty
               nLines := i := 1
               DO WHILE ( i := hb_At( ";",cText,i ) ) > 0
                  i ++
                  nLines ++
               ENDDO
               dy := ( y2 - y ) / nLines
               nFirst := i := 1
               ny := y
               DO WHILE ( i := hb_At( ";",cText,i ) ) > 0
                  ::oPrinter:Say( Substr(cText,nFirst,i-nFirst),x,ny,x2,ny+dy,nJustify,oItem:obj )
                  i ++
                  nFirst := i
                  ny += dy
               ENDDO
               ::oPrinter:Say( Substr(cText,nFirst,Len(cText)-nFirst+1),x,ny,x2,ny+dy,nJustify,oItem:obj )
            ELSE
               ::oPrinter:Say( cText,x,y,x2,y2,nJustify,oItem:obj )
            ENDIF
            SetTransparentMode( ::oPrinter:hDC,.F. )
            // Writelog( str(x)+" "+str(y)+" "+str(x2)+" "+str(y2)+" "+str(::nAOffSet)+" "+str(::nTOffSet)+" Say: "+cText)
         ENDIF
      ELSEIF oItem:cClass == "box"
         ::oPrinter:Box( x,y,x2,y2,oItem:oPen )
         // writelog( "Draw "+str(x)+" "+str(x+width-1) )
      ELSEIF oItem:cClass == "vline"
         ::oPrinter:Line( x,y,x,y2,oItem:oPen )
      ELSEIF oItem:cClass == "hline"
         ::oPrinter:Line( x,y,x2,y,oItem:oPen )
      ELSEIF oItem:cClass == "bitmap"
         IF oItem:obj == Nil
            oItem:obj := OpenBitmap( aGetSecond( oItem:aProp,"bitmap" ), ::oPrinter:hDC )
         ENDIF
         ::oPrinter:Bitmap( x,y,x2,y2,, oItem:obj )
      ENDIF
      ::ny := Max( ::ny,y2 + ::nAOffSet )
   ENDIF

   IF ( aMethod := aGetSecond( oItem:aMethods,"onend" ) ) != Nil
      DoScript( aMethod )
   ENDIF

Return Nil

METHOD ReleaseObj( aControls ) CLASS HRepTmpl
Local i

   FOR i := 1 TO Len( aControls )
      IF !Empty( aControls[i]:aControls )
         ::ReleaseObj( aControls[i]:aControls )
      ELSE
         IF aControls[i]:obj != Nil
            IF aControls[i]:cClass == "bitmap"
               DeleteObject( aControls[i]:obj )
               aControls[i]:obj := Nil
            ELSEIF aControls[i]:cClass == "label"
               aControls[i]:obj:Release()
               aControls[i]:obj := Nil
            ENDIF
         ENDIF
         IF aControls[i]:oPen != Nil
            aControls[i]:oPen:Release()
            aControls[i]:oPen := Nil
         ENDIF
      ENDIF
   NEXT

Return Nil

METHOD Find( cId ) CLASS HRepTmpl
Local i := Ascan( ::aReports, {|o|o:cId!=Nil.and.o:cId==cId} )
Return Iif( i==0, Nil, ::aReports[i] )

METHOD Close() CLASS HRepTmpl
Local i := Ascan( ::aReports, {|o|o:id==::id} )

   IF i != 0
      Adel( ::aReports,i )
      Asize( ::aReports, Len( ::aReports ) - 1 )
   ENDIF
Return Nil

Static Function ReadRepItem( oCtrlDesc, oContainer )
Local oCtrl := HRepItem():New( oContainer )
Local i, j, o, aProp := {}, aMethods := {}, aItems := oCtrlDesc:aItems, xProperty

   oCtrl:cClass   := oCtrlDesc:GetAttribute( "class" )
   oCtrl:aProp    := aProp
   oCtrl:aMethods := aMethods

   FOR i := 1 TO Len( aItems )
      IF aItems[i]:title == "style"
         FOR j := 1 TO Len( aItems[i]:aItems )
            o := aItems[i]:aItems[j]
            IF o:title == "property"
               Aadd( aProp, { Lower(o:GetAttribute("name")),Iif( Empty(o:aItems),"",hfrm_GetProperty(o:aItems[1]) ) } )
            ENDIF
         NEXT
      ELSEIF aItems[i]:title == "method"
         Aadd( aMethods, { Lower(aItems[i]:GetAttribute("name")),RdScript(,aItems[i]:aItems[1]:aItems[1],,.T.) } )
      ELSEIF aItems[i]:title == "part"
         ReadRepItem( aItems[i],Iif(oCtrl:cClass=="area",oCtrl,oContainer) )
      ENDIF
   NEXT
   IF oCtrl:cClass $ "box.vline.hline" .OR. ( oCtrl:cClass == "label" .AND. ;
      ( xProperty := aGetSecond( oCtrl:aProp,"border" ) ) != Nil .AND. xProperty )
      oCtrl:lPen := .T.
   ENDIF

Return Nil

Static Function aGetSecond( arr, xFirst )
Local i := Ascan( arr,{|a|a[1]==xFirst} )

Return Iif( i==0,Nil,arr[i,2] )

Static Function hrep_FontFromXML( oPrinter,oXmlNode,height )
Local weight := oXmlNode:GetAttribute( "weight" )
Local charset := oXmlNode:GetAttribute( "charset" )
Local ita   := oXmlNode:GetAttribute( "italic" )
Local under := oXmlNode:GetAttribute( "underline" )

  weight := Iif( weight != Nil, Val( weight ), 400 )
  IF charset != Nil
     charset := Val( charset )
  ENDIF
  ita    := Iif( ita != Nil, Val( ita ), 0 )
  under  := Iif( under != Nil, Val( under ), 0 )

Return oPrinter:AddFont( oXmlNode:GetAttribute( "name" ),  ;
                    height, (weight>400), (ita>0), (under>0), charset )

