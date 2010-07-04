/*
 *$Id: guilib.ch,v 1.162 2010-07-04 13:47:00 lfbasso Exp $
 */

#define HWG_VERSION            "2.17"
#define WND_MAIN               1
#define WND_MDI                2
#define WND_MDICHILD           3
#define WND_CHILD              4
#define WND_DLG_RESOURCE       10
#define WND_DLG_NORESOURCE     11

#define OBTN_INIT              0
#define OBTN_NORMAL            1
#define OBTN_MOUSOVER          2
#define OBTN_PRESSED           3

#define SHS_NOISE              0
#define SHS_DIAGSHADE          1
#define SHS_HSHADE             2
#define SHS_VSHADE             3
#define SHS_HBUMP              4
#define SHS_VBUMP              5
#define SHS_SOFTBUMP           6
#define SHS_HARDBUMP           7
#define SHS_METAL              8

#define PAL_DEFAULT            0
#define PAL_METAL              1

#define BRW_ARRAY              1
#define BRW_DATABASE           2

#define ANCHOR_TOPLEFT         0   // Anchors control to the top and left borders of the container and does not change the distance between the top and left borders. (Default)
#define ANCHOR_TOPABS          1   // Anchors control to top border of container and does not change the distance between the top border.
#define ANCHOR_LEFTABS         2   // Anchors control to left border of container and does not change the distance between the left border.
#define ANCHOR_BOTTOMABS       4   // Anchors control to bottom border of container and does not change the distance between the bottom border.
#define ANCHOR_RIGHTABS        8   // Anchors control to right border of container and does not change the distance between the right border.
#define ANCHOR_TOPREL          16  // Anchors control to top border of container and maintains relative distance between the top border.
#define ANCHOR_LEFTREL         32  // Anchors control to left border of container and maintains relative distance between the left border.
#define ANCHOR_BOTTOMREL       64  // Anchors control to bottom border of container and maintains relative distance between the bottom border.
#define ANCHOR_RIGHTREL        128 // Anchors control to right border of container and maintains relative distance between the right border.
#define ANCHOR_HORFIX          256 // Anchors center of control relative to left and right borders but remains fixed in size.
#define ANCHOR_VERTFIX         512 // Anchors center of control relative to top and bottom borders but remains fixed in size.

#define HORZ_PTS 7 //8
#define VERT_PTS 3.5 //4

#ifdef __XHARBOUR__
  #ifndef HB_SYMBOL_UNUSED
     #define HB_SYMBOL_UNUSED( x )    ( (x) := (x) )
  #endif
#endif

// Allow the definition of different classes without defining a new command

#xtranslate __IIF(.T., [<true>], [<false>]) => <true>
#xtranslate __IIF(.F., [<true>], [<false>]) => <false>

// Commands for windows, dialogs handling

#xcommand INIT WINDOW <oWnd>                ;
             [ MAIN ]                       ;
             [<lMdi: MDI>]                  ;
             [ APPNAME <appname> ]          ;
             [ TITLE <cTitle> ]             ;
             [ AT <x>, <y> ]                ;
             [ SIZE <width>, <height> ]     ;
             [ ICON <ico> ]                 ;
             [ COLOR <clr> ]                ;
             [ BACKGROUND BITMAP <oBmp> ]   ;
             [ STYLE <nStyle> ]             ;
             [ FONT <oFont> ]               ;
             [ MENU <cMenu> ]               ;
             [ MENUPOS <nPos> ]             ;
             [ ON MENU <bMdiMenu> ]         ;
             [ ON INIT <bInit> ]            ;
             [ ON SIZE <bSize> ]            ;
             [ ON PAINT <bPaint> ]          ;
             [ ON GETFOCUS <bGfocus> ]      ;
             [ ON LOSTFOCUS <bLfocus> ]     ;
             [[ON OTHER MESSAGES <bOther>][ON OTHERMESSAGES <bOther>]] ;
             [ ON REFRESH <bRefresh> ]      ;
             [ ON CLOSEQUERY <bCloseQuery> ];
             [ ON EXIT <bExit> ]            ;
             [ HELP <cHelp> ]               ;
             [ HELPID <nHelpId> ]           ;
          => ;
          <oWnd> := HMainWindow():New( Iif(<.lMdi.>,WND_MDI,WND_MAIN), ;
             <ico>,<clr>,<nStyle>,<x>,<y>,<width>,<height>,<cTitle>, ;
             <cMenu>,<nPos>,<oFont>,<bInit>,<bExit>,<bSize>,<bPaint>,;
             <bGfocus>,<bLfocus>,<bOther>,<appname>,<oBmp>,<cHelp>,<nHelpId>, <bCloseQuery>,<bRefresh>,<bMdiMenu>)

#xcommand INIT WINDOW <oWnd> MDICHILD [ VAR <vari> ]   ;
             [ APPNAME <appname> ]          ;
             [ OF <oParent>      ]          ;
             [ TITLE <cTitle> ]             ;
             [ AT <x>, <y> ]                ;
             [ SIZE <width>, <height> ]     ;
             [ ICON <ico> ]                 ;
             [ COLOR <clr> ]                ;
             [ BACKGROUND BITMAP <oBmp> ]   ;
             [ STYLE <nStyle> ]             ;
             [ FONT <oFont> ]               ;
             [ MENU <cMenu> ]               ;
             [ ON INIT <bInit> ]            ;
             [ ON SIZE <bSize> ]            ;
             [ ON PAINT <bPaint> ]          ;
             [ ON GETFOCUS <bGfocus> ]      ;
             [ ON LOSTFOCUS <bLfocus> ]     ;
             [[ON OTHER MESSAGES <bOther>][ON OTHERMESSAGES <bOther>]] ;
             [ ON REFRESH <bRefresh> ]      ;
             [ ON EXIT <bExit> ]            ;
             [ HELP <cHelp> ]               ;
             [ HELPID <nHelpId> ]           ;
             [ <lChild: CHILD>]             ;             
             [<lClipper: CLIPPER>]          ;
             [ <lnoClosable: NOCLOSABLE> ]  ;
          => ;
          <oWnd> := HMdiChildWindow():New( ;
                   <ico>,<clr>,<nStyle>,<x>,<y>,<width>,<height>,<cTitle>, ;
                   <cMenu>,<oFont>,<bInit>,<bExit>,<bSize>,<bPaint>, ;
                   <bGfocus>,<bLfocus>,<bOther>,<appname>,<oBmp>,<cHelp>,<nHelpId>,,;
									 <bRefresh>,<.lChild.>,<.lClipper.>,<.lnoClosable.>,[{|v|Iif(v==Nil,<vari>,<vari>:=v)}] ) ;;
        [ <oWnd>:SetParent( <oParent> ) ]            
      
#xcommand INIT WINDOW <oWnd> CHILD          ;
             APPNAME <appname>              ;
             [ TITLE <cTitle> ]             ;
             [ AT <x>, <y> ]                ;
             [ SIZE <width>, <height> ]     ;
             [ ICON <ico> ]                 ;
             [ COLOR <clr> ]                ;
             [ BACKGROUND BITMAP <oBmp> ]   ;
             [ STYLE <nStyle> ]             ;
             [ FONT <oFont> ]               ;
             [ MENU <cMenu> ]               ;
             [ ON INIT <bInit> ]            ;
             [ ON SIZE <bSize> ]            ;
             [ ON PAINT <bPaint> ]          ;
             [ ON GETFOCUS <bGfocus> ]      ;
             [ ON LOSTFOCUS <bLfocus> ]     ;
             [[ON OTHER MESSAGES <bOther>][ON OTHERMESSAGES <bOther>]] ;
             [ ON REFRESH <bRefresh> ]      ;
             [ ON EXIT <bExit> ]            ;
             [ HELP <cHelp> ]               ;
             [ HELPID <nHelpId> ]           ;
          => ;
          <oWnd> := HChildWindow():New( ;
             <ico>,<clr>,<nStyle>,<x>,<y>,<width>,<height>,<cTitle>, ;
             <cMenu>,<oFont>,<bInit>,<bExit>,<bSize>,<bPaint>, ;
             <bGfocus>,<bLfocus>,<bOther>,<appname>,<oBmp>,<cHelp>,<nHelpId>,<bRefresh> )

#xcommand INIT DIALOG <oDlg>                ;
             [<res: FROM RESOURCE> <Resid> ];
             [ TITLE <cTitle> ]             ;
             [ AT <x>, <y> ]                ;
             [ SIZE <width>, <height> ]     ;
             [ ICON <ico> ]                 ;
             [ COLOR <clr> ]                ;
             [ BACKGROUND BITMAP <oBmp> ]   ;
             [ STYLE <nStyle> ]             ;
             [ FONT <oFont> ]               ;
             [<lClipper: CLIPPER>]          ;
             [<lExitOnEnter: NOEXIT>]       ; //Modified By Sandro
             [<lExitOnEsc: NOEXITESC>]      ; //Modified By Sandro
             [ <lnoClosable: NOCLOSABLE> ]  ;
             [ ON INIT <bInit> ]            ;
             [ ON SIZE <bSize> ]            ;
             [ ON PAINT <bPaint> ]          ;
             [ ON GETFOCUS <bGfocus> ]      ;
             [ ON LOSTFOCUS <bLfocus> ]     ;
             [[ON OTHER MESSAGES <bOther>][ON OTHERMESSAGES <bOther>]] ;
             [ ON REFRESH <bRefresh> ]      ;
             [ ON EXIT <bExit> ]            ;
             [ HELPID <nHelpId> ]           ;
          => ;
          <oDlg> := HDialog():New( Iif(<.res.>,WND_DLG_RESOURCE,WND_DLG_NORESOURCE), ;
             <nStyle>,<x>,<y>,<width>,<height>,<cTitle>,<oFont>,<bInit>,<bExit>,;
             <bSize>, <bPaint>,<bGfocus>,<bLfocus>,<bOther>,<.lClipper.>,<oBmp>,;
             <ico>,<.lExitOnEnter.>,<nHelpId>,<Resid>,<.lExitOnEsc.>,<clr>,<bRefresh>,<.lnoClosable.>)

#xcommand ACTIVATE WINDOW <oWnd> ;
               [<lNoShow: NOSHOW>] ;
               [<lMaximized: MAXIMIZED>] ;
               [<lMinimized: MINIMIZED>] ;
               [<lCenter: CENTER>] ;
               [<lModal: MODAL>] ;
               [ ON ACTIVATE <bInit> ]            ;
           => ;
      <oWnd>:Activate( !<.lNoShow.>, <.lMaximized.>, <.lMinimized.>,  <.lCenter.>, <bInit>, <.lModal.> )

#xcommand CENTER WINDOW <oWnd> => <oWnd>:Center()

#xcommand MAXIMIZE WINDOW <oWnd> => <oWnd>:Maximize()

#xcommand MINIMIZE WINDOW <oWnd> => <oWnd>:Minimize()

#xcommand RESTORE WINDOW <oWnd> => <oWnd>:Restore()

#xcommand SHOW WINDOW <oWnd> => <oWnd>:Show()

#xcommand HIDE WINDOW <oWnd> => <oWnd>:Hide()

#xcommand ACTIVATE DIALOG <oDlg>                        ;
             [ <lNoModal: NOMODAL> ]                     ;
             [ SHOW <nShow>] ;
             [ ON ACTIVATE <bInit> ]                     ;
          => ;
          <oDlg>:Activate(<.lNoModal.>, <bInit>, <nShow> )

#xcommand MENU FROM RESOURCE OF <oWnd> ON <id1> ACTION <b1>      ;
             [ ON <idn> ACTION <bn> ]    ;
          => ;
          <oWnd>:aEvents := \{ \{ 0,<id1>, <{b1}> \} [ , \{ 0,<idn>, <{bn}> \} ] \}

#xcommand DIALOG ACTIONS OF <oWnd> ON <id1>,<id2> ACTION <b1>      ;
             [ ON <idn1>,<idn2> ACTION <bn> ]  ;
          => ;
          <oWnd>:aEvents := \{ \{ <id1>,<id2>, <b1> \} [ , \{ <idn1>,<idn2>, <bn> \} ] \}

// Commands for control handling

// Contribution ATZCT" <atzct@obukhov.kiev.ua
#xcommand @ <x>,<y> PROGRESSBAR <oPBar>        ;
             [ OF <oWnd> ]                       ;
             [ ID <nId> ]                        ;
             [ SIZE <nWidth>,<nHeight> ]         ;
             [ ON INIT <bInit> ]                 ;
             [ ON PAINT <bDraw> ]                ;
             [ ON SIZE <bSize> ]                 ;
             [ BARWIDTH <maxpos> ]               ;
             [ QUANTITY <nRange> ]               ;
             [ <lVert: VERTICAL>]                ;
             [ ANIMATION <nAnimat> ]             ;
             [ TOOLTIP <ctooltip> ]              ;
          => ;
          <oPBar> :=  HProgressBar():New( <oWnd>,<nId>,<x>,<y>,<nWidth>, ;
             <nHeight>,<maxpos>,<nRange>, <bInit>,<bSize>,<bDraw>,<ctooltip>,<nAnimat>,<.lVert.> );;
          [ <oPBar>:name := <(oPBar)> ]

#xcommand ADD STATUS [<oStat>] [ TO <oWnd> ] ;
             [ ID <nId> ]           ;
             [ HEIGHT <nHeight> ]   ;             
             [ ON INIT <bInit> ]    ;
             [ ON SIZE <bSize> ]    ;
             [ ON PAINT <bDraw> ]   ;
             [ ON DBLCLICK <bDblClick> ];
             [ ON RIGHTCLICK <bRClick> ];
             [ STYLE <nStyle> ]     ;
             [ FONT <oFont> ]       ;
             [ PARTS <aparts,...> ] ;
          => ;
          [ <oStat> := ] HStatus():New( <oWnd>,<nId>,<nStyle>,<oFont>,\{<aparts>\},<bInit>,;
             <bSize>,<bDraw>, <bRClick>, <bDblClick>, <nHeight> );;
          [ <oStat>:name := <(oStat)> ]

#xcommand @ <x>,<y> SAY [ <oSay> CAPTION ] <caption> ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [<lTransp: TRANSPARENT>]   ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ON CLICK <bClick> ]      ;
             [ ON DBLCLICK <bDblClick> ];
             [[ON OTHER MESSAGES <bOther>][ON OTHERMESSAGES <bOther>]] ;
             [ STYLE <nStyle> ]         ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
          => ;
          [<oSay> := ] HStatic():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, ;
             <height>,<caption>,<oFont>,<bInit>,<bSize>,<bDraw>,<ctoolt>, ;
             <color>,<bcolor>,<.lTransp.>,<bClick>,<bDblClick>,<bOther> );;
          [ <oSay>:name := <(oSay)> ]

#xcommand REDEFINE SAY   [ <oSay> CAPTION ] <cCaption>   ;
             [ OF <oWnd> ]              ;
             ID <nId>                   ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [<lTransp: TRANSPARENT>]   ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ON CLICK <bClick> ]      ;
             [ ON DBLCLICK <bDblClick> ];
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
          => ;
          [<oSay> := ] HStatic():Redefine( <oWnd>,<nId>,<cCaption>, ;
             <oFont>,<bInit>,<bSize>,<bDraw>,<ctoolt>,<color>,<bcolor>,<.lTransp.>,<bClick>,<bDblClick> )

#xcommand @ <x>,<y> BITMAP [ <oBmp> SHOW ] <bitmap> ;
             [<res: FROM RESOURCE>]     ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ STRETCH <nStretch>]      ;
             [<lTransp: TRANSPARENT>]   ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON CLICK <bClick> ]      ;
             [ ON DBLCLICK <bDblClick> ];
             [ TOOLTIP <ctoolt> ]       ;
             [ STYLE <nStyle> ]         ;             
          => ;
          [<oBmp> := ] HSayBmp():New( <oWnd>,<nId>,<x>,<y>,<width>, ;
             <height>,<bitmap>,<.res.>,<bInit>,<bSize>,<ctoolt>,<bClick>,<bDblClick>, <.lTransp.>,<nStretch>, <nStyle> );;
          [ <oBmp>:name := <(oBmp)> ]

#xcommand REDEFINE BITMAP [ <oBmp> SHOW ] <bitmap> ;
             [<res: FROM RESOURCE>]     ;
             [ OF <oWnd> ]              ;
             ID <nId>                   ;
             [<lTransp: TRANSPARENT>]   ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ TOOLTIP <ctoolt> ]       ;
          => ;
          [<oBmp> := ] HSayBmp():Redefine( <oWnd>,<nId>,<bitmap>,<.res.>, ;
             <bInit>,<bSize>,<ctoolt>,<.lTransp.>)

#xcommand @ <x>,<y> ICON [ <oIco> SHOW ] <icon> ;
             [<res: FROM RESOURCE>]     ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON CLICK <bClick> ]      ;
             [ ON DBLCLICK <bDblClick> ];
             [ TOOLTIP <ctoolt> ]       ;
             [<oem: OEM>]     ;
          => ;
          [<oIco> := ] HSayIcon():New( <oWnd>,<nId>,<x>,<y>,<width>, ;
             <height>,<icon>,<.res.>,<bInit>,<bSize>,<ctoolt>,<.oem.>,<bClick>,<bDblClick> );;
          [ <oIco>:name := <(oIco)> ] 					                     

#xcommand REDEFINE ICON [ <oIco> SHOW ] <icon> ;
             [<res: FROM RESOURCE>]     ;
             [ OF <oWnd> ]              ;
             ID <nId>                   ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ TOOLTIP <ctoolt> ]       ;
          => ;
          [<oIco> := ] HSayIcon():Redefine( <oWnd>,<nId>,<icon>,<.res.>, ;
             <bInit>,<bSize>,<ctoolt> )

#xcommand @ <x>,<y> IMAGE [ <oImage> SHOW ] <image> ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ TOOLTIP <ctoolt> ]       ;
             [ TYPE <ctype>     ]       ;
          => ;
          [<oImage> := ] HSayFImage():New( <oWnd>,<nId>,<x>,<y>,<width>, ;
             <height>,<image>,<bInit>,<bSize>,<ctoolt>,<ctype> );;
          [ <oImage>:name := <(oImage)> ] 					                     

#xcommand REDEFINE IMAGE [ <oImage> SHOW ] <image> ;
             [ OF <oWnd> ]              ;
             ID <nId>                   ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ TOOLTIP <ctoolt> ]       ;
          => ;
          [<oImage> := ] HSayFImage():Redefine( <oWnd>,<nId>,<image>, ;
             <bInit>,<bSize>,<ctoolt> )

#xcommand @ <x>,<y> LINE [ <oLine> ]   ;
             [ LENGTH <length> ]       ;
             [ HEIGHT <nHeight> ]      ;
             [ OF <oWnd> ]             ;
             [ ID <nId> ]              ;
             [ COLOR <color> ]         ;
             [ LINESLANT <cSlant> ]    ;
             [ BORDERWIDTH <nBorder> ] ;
             [<lVert: VERTICAL>]       ;
             [ ON INIT <bInit> ]       ;
             [ ON SIZE <bSize> ]       ;
          => ;
          [<oLine> := ] HLine():New( <oWnd>,<nId>,<.lVert.>,<x>,<y>,<length>,<bSize>, <bInit>,;
					              <color>, <nHeight>, <cSlant>,<nBorder>  );;
          [ <oLine>:name := <(oLine)> ]

#xcommand @ <x>,<y> EDITBOX [ <oEdit> CAPTION ] <caption> ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ON GETFOCUS <bGfocus> ]  ;
             [ ON LOSTFOCUS <bLfocus> ] ;
             [ ON KEYDOWN <bKeyDown>]   ;
             [ ON CHANGE <bChange>]     ;
             [[ON OTHER MESSAGES <bOther>][ON OTHERMESSAGES <bOther>]] ;
             [ STYLE <nStyle> ]         ;
             [<lnoborder: NOBORDER>]    ;
             [<lPassword: PASSWORD>]    ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
          => ;
          [<oEdit> := ] HEdit():New( <oWnd>,<nId>,<caption>,,<nStyle>,<x>,<y>,<width>, ;
             <height>,<oFont>,<bInit>,<bSize>,<bDraw>,<bGfocus>, ;
             <bLfocus>,<ctoolt>,<color>,<bcolor>,,<.lnoborder.>,,<.lPassword.>,<bKeyDown>, <bChange>,<bOther> );;
          [ <oEdit>:name := <(oEdit)> ]

#xcommand REDEFINE EDITBOX [ <oEdit> ] ;
             [ OF <oWnd> ]              ;
             ID <nId>                   ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ FONT <oFont> ]           ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ON GETFOCUS <bGfocus> ]  ;
             [ ON LOSTFOCUS <bLfocus> ] ;
             [ ON KEYDOWN <bKeyDown>]   ;
             [ TOOLTIP <ctoolt> ]       ;
          => ;
          [<oEdit> := ] HEdit():Redefine( <oWnd>,<nId>,,,<oFont>,<bInit>,<bSize>,<bDraw>, ;
             <bGfocus>,<bLfocus>,<ctoolt>,<color>,<bcolor>,,,,<bKeyDown> )

#xcommand @ <x>,<y> RICHEDIT [ <oEdit> TEXT ] <vari> ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [<lallowtabs: ALLOWTABS>]  ; 
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ON GETFOCUS <bGfocus> ]  ;
             [ ON LOSTFOCUS <bLfocus> ] ;
             [ ON CHANGE <bChange>]     ;
             [[ON OTHER MESSAGES <bOther>][ON OTHERMESSAGES <bOther>]] ;
             [ STYLE <nStyle> ]         ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
          => ;
          [<oEdit> := ] HRichEdit():New( <oWnd>,<nId>,<vari>,<nStyle>,<x>,<y>,<width>, ;
             <height>,<oFont>,<bInit>,<bSize>,<bDraw>,<bGfocus>, ;
             <bLfocus>,<ctoolt>,<color>,<bcolor>,<bOther>, <.lallowtabs.>,<bChange> );;
          [ <oEdit>:name := <(oEdit)> ]

#xcommand @ <x>,<y> BUTTON [ <oBut> CAPTION ] <caption> ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ON CLICK <bClick> ]      ;
             [ ON GETFOCUS <bGfocus> ]  ;
             [ STYLE <nStyle> ]         ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
          => ;
          [<oBut> := ] HButton():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, ;
             <height>,<caption>,<oFont>,<bInit>,<bSize>,<bDraw>,<bClick>,<ctoolt>,<color>,<bcolor>,<bGfocus> );;
          [ <oBut>:name := <(oBut)> ]

#xcommand @ <x>,<y> BUTTONEX [ <oBut> CAPTION ] <caption> ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ON CLICK <bClick> ]      ;
             [ ON GETFOCUS <bGfocus> ]  ;
             [ STYLE <nStyle> ]         ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
             [ BITMAP <hbit> ]          ;
             [ BSTYLE <nBStyle> ]       ;                     
             [ PICTUREMARGIN <nMargin> ];
             [ ICON <hIco> ]          ;
             [ <lTransp: TRANSPARENT> ] ;
             [ <lnoTheme: NOTHEMES> ]   ;
             [ <class: CLASS> <classname> ] ;
          => ;
          [<oBut> := ] __IIF(<.class.>, <classname>,HButtonEx)():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, ;
             <height>,<caption>,<oFont>,<bInit>,<bSize>,<bDraw>,<bClick>,<ctoolt>,<color>,<bcolor>,<hbit>,<nBStyle>,<hIco>, <.lTransp.>,<bGfocus>,<nMargin>,<.lnoTheme.>);;
          [ <oBut>:name := <(oBut)> ]


#xcommand REDEFINE BUTTON [ <oBut> ]   ;
             [ OF <oWnd> ]              ;
             ID <nId>                   ;
             [ CAPTION <cCaption> ]     ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ FONT <oFont> ]           ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ON CLICK <bClick> ]      ;
             [ ON GETFOCUS <bGfocus> ]  ;
             [ TOOLTIP <ctoolt> ]       ;
          => ;
          [<oBut> := ] HButton():Redefine( <oWnd>,<nId>,<oFont>,<bInit>,<bSize>,<bDraw>, ;
             <bClick>,<ctoolt>,<color>,<bcolor>,<cCaption>,<bGfocus> )

#xcommand REDEFINE BUTTONEX [ <oBut> ]   ;
             [ OF <oWnd> ]              ;
             ID <nId>                   ;
             [ CAPTION <cCaption> ]     ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ FONT <oFont> ]           ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ON CLICK <bClick> ]      ;
             [ ON GETFOCUS <bGfocus> ]  ;
             [ TOOLTIP <ctoolt> ]       ;
             [ BITMAP <hbit> ]          ;
             [ BSTYLE <nBStyle> ]       ;
             [ PICTUREMARGIN <nMargin> ];
          => ;
          [<oBut> := ] HButtonEx():Redefine( <oWnd>,<nId>,<oFont>,<bInit>,<bSize>,<bDraw>, ;
             <bClick>,<ctoolt>,<color>,<bcolor>,<cCaption>,<hbit>,<nBStyle>,<bGfocus>,<nMargin>  )

#xcommand @ <x>,<y> GROUPBOX [ <oGroup> CAPTION ] <caption> ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [<lTransp: TRANSPARENT>]   ;
             [ FONT <oFont> ]           ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ STYLE <nStyle> ]         ;
          => ;
          [<oGroup> := ] HGroup():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, ;
             <height>,<caption>,<oFont>,<bInit>,<bSize>,<bDraw>,<color>,<bcolor>,<.lTransp.>);;
          [ <oGroup>:name := <(oGroup)> ]

#xcommand @ <x>,<y> TREE [ <oTree> ]   ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ FONT <oFont> ]           ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ <lEdit: EDITABLE>]       ;
             [ <lDragDrop: DRAGDROP>]   ;
             [ <lCheck: CHECKBOXES> ]   ;
             [ ON CHECK <bCheck> ]      ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON CLICK <bClick> ]      ;
             [ ON RIGHTCLICK <bRClick> ];
             [ ON DBLCLICK <bDClick> ]  ;
             [ ON DRAG <bDrag> ]        ;
             [ ON DROP <bDrop> ]        ;
             [ ON OTHERMESSAGES <bOther>] ;
             [ STYLE <nStyle> ]         ;
             [ BITMAP <aBmp>  [<res: FROM RESOURCE>] [ BITCOUNT <nBC> ] ]  ;
          => ;
          [<oTree> := ] HTree():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, ;
                <height>,<oFont>,<bInit>,<bSize>,<color>,<bcolor>,<aBmp>,<.res.>,<.lEdit.>,<bClick>,<nBC>, ;
                <bRClick>, <bDClick>, <.lCheck.>, <bCheck>, <.lDragDrop.>, <bDrag>, <bDrop>, <bOther> );;
          [ <oTree>:name := <(oTree)> ]

#xcommand INSERT NODE [ <oNode> CAPTION ] <cTitle>  ;
             TO <oTree>                            ;
             [ AFTER <oPrev> ]                     ;
             [ BEFORE <oNext> ]                    ;
             [ BITMAP <aBmp> ]                     ;
             [ ON CLICK <bClick> ]                 ;
             [ ON ACTION <bAction> ]                 ;
             [ <lCheck: CHECKED>]        ;
          => ;
          [<oNode> := ] <oTree>:AddNode( <cTitle>,<oPrev>,<oNext>,<bClick>,<aBmp>, <.lCheck.>, <bAction> )

#xcommand @ <x>,<y> TAB [ <oTab> ITEMS ] <aItems> ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ STYLE <nStyle> ]         ;
             [ FONT <oFont> ]           ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ON CHANGE <bChange> ]    ;
             [ ON CLICK <bClick> ]      ;
             [ ON RIGHTCLICK <bRClick> ];
             [ ON GETFOCUS <bGetFocus> ];
             [ ON LOSTFOCUS <bLostFocus>];
             [ BITMAP <aBmp>  [<res: FROM RESOURCE>] [ BITCOUNT <nBC> ] ]  ;
          => ;
          [<oTab> := ] HTab():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, ;
             <height>,<oFont>,<bInit>,<bSize>,<bDraw>,<aItems>,<bChange>, <aBmp>, <.res.>,<nBC>,;
             <bClick>, <bGetFocus>, <bLostFocus>, <bRClick> ) ;;
          [ <oTab>:name := <(oTab)> ]

#xcommand BEGIN PAGE <cname> OF <oTab> ;
            [ <enable: DISABLED> ]     ;
            [ COLOR <tcolor>]          ;
            [ BACKCOLOR <bcolor>]      ; 
          =>;
          <oTab>:StartPage( <cname>, ,! <.enable.> ,<tcolor>,<bcolor> )

#xcommand END PAGE OF <oTab> => <oTab>:EndPage()

#xcommand ENDPAGE OF <oTab> => <oTab>:EndPage()

#xcommand @ <x>,<y> CHECKBOX [ <oCheck> CAPTION ] <caption> ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ INIT <lInit> ]           ;
             [ SIZE <width>, <height> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [<lTransp: TRANSPARENT>]   ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ON CLICK <bClick> ]      ;
             [ ON GETFOCUS <bGfocus> ]  ;
             [ STYLE <nStyle> ]         ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
             [ <lEnter: ENTER> ]        ;
          => ;
          [<oCheck> := ] HCheckButton():New( <oWnd>,<nId>,<lInit>,,<nStyle>,<x>,<y>, ;
             <width>,<height>,<caption>,<oFont>,<bInit>,<bSize>,<bDraw>,<bClick>, ;
             <ctoolt>,<color>,<bcolor>,<bGfocus>,<.lEnter.>,<.lTransp.> );;
          [ <oCheck>:name := <(oCheck)> ]

#xcommand REDEFINE CHECKBOX [ <oCheck> ] ;
             [ OF <oWnd> ]              ;
             ID <nId>                   ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ INIT <lInit>    ]        ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ON CLICK <bClick> ]      ;
             [ ON GETFOCUS <bGfocus> ]  ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
             [ <lEnter: ENTER> ]        ;
          => ;
          [<oCheck> := ] HCheckButton():Redefine( <oWnd>,<nId>,<lInit>,,<oFont>, ;
             <bInit>,<bSize>,<bDraw>,<bClick>,<ctoolt>,<color>,<bcolor>,<bGfocus>,<.lEnter.> )

#xcommand RADIOGROUP => HRadioGroup():New()

#xcommand GET RADIOGROUP [ <ogr> VAR ] <vari>  ;
             [ ON INIT <bInit> ]        ;
             [ ON CLICK <bClick> ]      ;
             [ ON GETFOCUS <bWhen> ]           ;
          => [<ogr> := ] HRadioGroup():New( <vari>, {|v|Iif(v==Nil,<vari>,<vari>:=v)}, ;
					     <bInit>,<bClick>,<bWhen> )

          //nando
#xcommand @ <x>,<y> GET RADIOGROUP [ <ogr> VAR ] <vari>  ;
             [ CAPTION  <caption> ];
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [<lTransp: TRANSPARENT>]   ;
             [ FONT <oFont> ]           ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ STYLE <nStyle> ]         ;
             [ ON CLICK <bClick> ]      ;
             [ ON GETFOCUS <bWhen> ]           ;
          => [<ogr> := ] HRadioGroup():NewRG( <oWnd>,<nId>,<nStyle>,<vari>,;
                  {|v|Iif(v==Nil,<vari>,<vari>:=v)},<x>,<y>,<width>,<height>,<caption>,<oFont>,;
                  <bInit>,<bSize>,<color>,<bcolor>,<bClick>,<bWhen>,<.lTransp.>);;
          [ <ogr>:name := <(ogr)> ]


#xcommand END RADIOGROUP [ SELECTED <nSel> ] ;
          => ;
          HRadioGroup():EndGroup( <nSel> )

#xcommand END RADIOGROUP <oGr> [ SELECTED <nSel> ]  ;
          => ;
          <oGr>:EndGroup( <nSel> );;
          [ <oGr>:name := <(oGr)> ]
                    
#xcommand @ <x>,<y> RADIOBUTTON [ <oRadio> CAPTION ] <caption> ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [<lTransp: TRANSPARENT>]   ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ON CLICK <bClick> ]      ;
             [ ON GETFOCUS <bWhen> ]           ;
             [ STYLE <nStyle> ]         ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
          => ;
          [<oRadio> := ] HRadioButton():New( <oWnd>,<nId>,<nStyle>,<x>,<y>, ;
             <width>,<height>,<caption>,<oFont>,<bInit>,<bSize>,<bDraw>,<bClick>, ;
             <ctoolt>,<color>,<bcolor>,<bWhen>,<.lTransp.> );;
          [ <oRadio>:name := <(oRadio)> ]

#xcommand REDEFINE RADIOBUTTON [ <oRadio> ] ;
             [ OF <oWnd> ]              ;
             ID <nId>                   ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [<lTransp: TRANSPARENT>]   ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ON CLICK <bClick> ]      ;
             [ ON GETFOCUS <bWhen> ]           ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
             [ GROUP <oGroup>]          ;
          => ;
          [<oRadio> := ] HRadioButton():Redefine( <oWnd>,<nId>,<oFont>,<bInit>,<bSize>, ;
             <bDraw>,<bClick>,<ctoolt>,<color>,<bcolor>,<bWhen>,<.lTransp.>,<oGroup> )

#xcommand @ <x>,<y> COMBOBOX [ <oCombo> ITEMS ] <aItems> ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ INIT <nInit> ]           ;
             [ SIZE <width>, <height> ] ;
             [ DISPLAYCOUNT <nDisplay>] ;
             [ ITEMHEIGHT <nhItem>    ] ; 
             [ COLUMNWIDTH <ncWidth>  ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ON CHANGE <bChange> ]    ;
             [ STYLE <nStyle> ]         ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
             [ <edit: EDIT> ]           ;
             [ <text: TEXT> ]           ;
             [ ON GETFOCUS <bGfocus> ]  ;
             [ ON LOSTFOCUS <bLfocus> ] ;
             [ ON INTERACTIVECHANGE <bIChange> ]    ;
          => ;
          [<oCombo> := ] HComboBox():New( <oWnd>,<nId>,<nInit>,,<nStyle>,<x>,<y>,<width>, ;
             <height>,<aItems>,<oFont>,<bInit>,<bSize>,<bDraw>,<bChange>,<ctoolt>,;
             <.edit.>,<.text.>,<bGfocus>,<color>,<bcolor>, <bLfocus>,<bIChange>,;
						 <nDisplay>,<nhItem>,<ncWidth>);;
          [ <oCombo>:name := <(oCombo)> ]

#xcommand REDEFINE COMBOBOX [ <oCombo> ITEMS ] <aItems> ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            [ INIT <nInit>    ]        ;
            [ DISPLAYCOUNT <nDisplay>] ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CHANGE <bChange> ]    ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
            [ ON GETFOCUS <bGfocus> ]  ;
            [ ON LOSTFOCUS <bLfocus> ] ;
            [ ON INTERACTIVECHANGE <bIChange> ]    ;
          => ;
    [<oCombo> := ] HComboBox():Redefine( <oWnd>,<nId>,<nInit>,,<aItems>,<oFont>,<bInit>, ;
             <bSize>,<bDraw>,<bChange>,<ctoolt>,<bGfocus>, <bLfocus>, <bIChange>,<nDisplay>)

#xcommand @ <x>,<y> UPDOWN [ <oUpd> INIT ] <nInit> ;
             RANGE <nLower>,<nUpper>    ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ WIDTH <nUpDWidth> ]      ;
             [ INCREMENT <nIncr> ]      ;        
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ON GETFOCUS <bGfocus> ]  ;
             [ ON LOSTFOCUS <bLfocus> ] ;
             [ STYLE <nStyle> ]         ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
          => ;
          [<oUpd> := ] HUpDown():New( <oWnd>,<nId>,<nInit>,,<nStyle>,<x>,<y>,<width>, ;
             <height>,<oFont>,<bInit>,<bSize>,<bDraw>,<bGfocus>,         ;
             <bLfocus>,<ctoolt>,<color>,<bcolor>,<nUpDWidth>,<nLower>,<nUpper>,<nIncr> );;
          [ <oUpd>:name := <(oUpd)> ]

#xcommand @ <x>,<y> PANEL [ <oPanel> ] ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ BACKCOLOR <bcolor> ]     ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ STYLE <nStyle> ]         ;
          => ;
          [<oPanel> :=] HPanel():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>,<height>,<bInit>,<bSize>,<bDraw>,<bcolor> );;
          [ <oPanel>:name := <(oPanel)> ]

#xcommand REDEFINE PANEL [ <oPanel> ]  ;
             [ OF <oWnd> ]              ;
             ID <nId>                   ;
             [ BACKCOLOR <bcolor> ]     ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ HEIGHT <nHeight> ]       ;
             [ WIDTH <nWidth> ]         ;
          => ;
          [<oPanel> :=] HPanel():Redefine( <oWnd>,<nId>,<nWidth>,<nHeight>,<bInit>,<bSize>,<bDraw>, <bcolor> )

#xcommand @ <x>,<y> BROWSE [ <oBrw> ]  ;
             [ <lArr: ARRAY> ]          ;
             [ <lDb: DATABASE> ]        ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ON CLICK <bEnter> ]      ;
             [ ON RIGHTCLICK <bRClick> ];
             [ ON GETFOCUS <bGfocus> ][WHEN <bGfocus> ]   ;
             [ ON LOSTFOCUS <bLfocus> ][ VALID <bLfocus> ] ;
             [ STYLE <nStyle> ]         ;
             [ <lNoVScr: NO VSCROLL> ]  ;
             [ <lNoBord: NOBORDER> ]    ;
             [ FONT <oFont> ]           ;
             [ <lAppend: APPEND> ]      ;
             [ <lAutoedit: AUTOEDIT> ]  ;
             [ ON UPDATE <bUpdate> ]    ;
             [ ON KEYDOWN <bKeyDown> ]  ;
             [ ON POSCHANGE <bPosChg> ] ;
             [ ON CHANGEROWCOL <bChgrowcol> ] ;
             [ <lMulti: MULTISELECT> ]  ;
             [ <lDescend: DESCEND> ]    ; // By Marcelo Sturm (marcelo.sturm@gmail.com)
             [ WHILE <bWhile> ]         ; // By Luiz Henrique dos Santos (luizhsantos@gmail.com)
             [ FIRST <bFirst> ]         ; // By Luiz Henrique dos Santos (luizhsantos@gmail.com)
             [ LAST <bLast> ]           ; // By Marcelo Sturm (marcelo.sturm@gmail.com)
             [ FOR <bFor> ]             ; // By Luiz Henrique dos Santos (luizhsantos@gmail.com)
             [ ON OTHER MESSAGES <bOther> ] ;
             [ ON OTHERMESSAGES <bOther>  ] ;
             [ <class: CLASS> <classname> ] ;
          => ;
          [<oBrw> :=] __IIF(<.class.>, <classname>, HBrowse)():New( Iif(<.lDb.>,BRW_DATABASE,Iif(<.lArr.>,BRW_ARRAY,0)),;
             <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>,<height>,<oFont>,<bInit>,<bSize>, ;
             <bDraw>,<bEnter>,<bGfocus>,<bLfocus>,<.lNoVScr.>,<.lNoBord.>, <.lAppend.>,;
             <.lAutoedit.>, <bUpdate>, <bKeyDown>, <bPosChg>, <.lMulti.>, <.lDescend.>,;
             <bWhile>, <bFirst>, <bLast>, <bFor>, <bOther>, <color>, <bcolor>, <bRClick>,<bChgrowcol>  );;
          [ <oBrw>:name := <(oBrw)> ]

#xcommand REDEFINE BROWSE [ <oBrw> ]   ;
             [ <lArr: ARRAY> ]          ;
             [ <lDb: DATABASE> ]        ;
             [ <lFlt: FILTER> ]        ;
             [ OF <oWnd> ]              ;
             ID <nId>                   ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ON CLICK <bEnter> ]      ;
             [ ON GETFOCUS <bGfocus> ]  ;
             [ ON LOSTFOCUS <bLfocus> ] ;
             [ FONT <oFont> ]           ;
          => ;
          [<oBrw> :=] HBrowse():Redefine( Iif(<.lDb.>,BRW_DATABASE,Iif(<.lArr.>,BRW_ARRAY,Iif(<.lFlt.>,BRW_FILTER,0))),;
             <oWnd>,<nId>,<oFont>,<bInit>,<bSize>,<bDraw>,<bEnter>,<bGfocus>,<bLfocus> )

#xcommand ADD COLUMN <block> TO <oBrw> ;
             [ HEADER <cHeader> ]       ;
             [ TYPE <cType> ]           ;
             [ LENGTH <nLen> ]          ;
             [ DEC <nDec>    ]          ;
             [ <lEdit: EDITABLE> ]      ;
             [ JUSTIFY HEAD <nJusHead> ];
             [ JUSTIFY LINE <nJusLine> ];
             [ PICTURE <cPict> ]        ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ VALID <bValid> ]         ;
             [ WHEN <bWhen> ]           ;
             [ ON CLICK <bClick> ]      ;
             [ ITEMS <aItem> ]          ;
             [ COLORBLOCK <bClrBlck> ]  ;
             [ BHEADCLICK <bHeadClick> ]  ;
          => ;
          <oBrw>:AddColumn( HColumn():New( <cHeader>,<block>,<cType>,<nLen>,<nDec>,<.lEdit.>,;
             <nJusHead>, <nJusLine>, <cPict>, <{bValid}>, <{bWhen}>, <aItem>, <{bClrBlck}>, <{bHeadClick}>, <color>, <bcolor>, <bClick> ) )

#xcommand INSERT COLUMN <block> TO <oBrw> ;
             [ HEADER <cHeader> ]       ;
             [ TYPE <cType> ]           ;
             [ LENGTH <nLen> ]          ;
             [ DEC <nDec>    ]          ;
             [ <lEdit: EDITABLE> ]      ;
             [ JUSTIFY HEAD <nJusHead> ];
             [ JUSTIFY LINE <nJusLine> ];
             [ PICTURE <cPict> ]        ;
             [ VALID <bValid> ]         ;
             [ WHEN <bWhen> ]           ;
             [ ITEMS <aItem> ]          ;
             [ BITMAP <oBmp> ]          ;
             [ COLORBLOCK <bClrBlck> ]  ;
             INTO <nPos>                ;
          => ;
          <oBrw>:InsColumn( HColumn():New( <cHeader>,<block>,<cType>,<nLen>,<nDec>,<.lEdit.>,;
             <nJusHead>, <nJusLine>, <cPict>, <{bValid}>, <{bWhen}>, <aItem>, <oBmp>, <{bClrBlck}> ),<nPos> )

#xcommand @ <x>,<y> GRID <oGrid>        ;
             [ OF <oWnd> ]               ;
             [ ID <nId> ]                ;
             [ STYLE <nStyle> ]          ;
             [ SIZE <width>, <height> ]  ;
             [ FONT <oFont> ]            ;
             [ ON INIT <bInit> ]         ;
             [ ON SIZE <bSize> ]         ;
             [ ON PAINT <bPaint> ]       ;
             [ ON CLICK <bEnter> ]       ;
             [ ON GETFOCUS <bGfocus> ]   ;
             [ ON LOSTFOCUS <bLfocus> ]  ;
             [ ON KEYDOWN <bKeyDown> ]   ;
             [ ON POSCHANGE <bPosChg> ]  ;
             [ ON DISPINFO <bDispInfo> ] ;
             [ ITEMCOUNT <nItemCount> ]  ;
             [ <lNoScroll: NOSCROLL> ]   ;
             [ <lNoBord: NOBORDER> ]     ;
             [ <lNoLines: NOGRIDLINES> ] ;
             [ COLOR <color> ]           ;
             [ BACKCOLOR <bkcolor> ]     ;
             [ <lNoHeader: NO HEADER> ]  ;
             [BITMAP <aBit>];
          => ;
          <oGrid> := HGrid():New( <oWnd>, <nId>, <nStyle>, <x>, <y>, <width>, <height>,;
             <oFont>, <{bInit}>, <{bSize}>, <{bPaint}>, <{bEnter}>,;
             <{bGfocus}>, <{bLfocus}>, <.lNoScroll.>, <.lNoBord.>,;
             <{bKeyDown}>, <{bPosChg}>, <{bDispInfo}>, <nItemCount>,;
             <.lNoLines.>, <color>, <bkcolor>, <.lNoHeader.> ,<aBit>);;
          [ <oGrid>:name := <(oGrid)> ]

#xcommand ADD COLUMN TO GRID <oGrid>    ;
             [ HEADER <cHeader> ]        ;
             [ WIDTH <nWidth> ]          ;
             [ JUSTIFY HEAD <nJusHead> ] ;
             [ BITMAP <n> ]              ;
          => ;
          <oGrid>:AddColumn( <cHeader>, <nWidth>, <nJusHead> ,<n>)

#xcommand @ <x>,<y> OWNERBUTTON [ <oOwnBtn> ]  ;
             [ OF <oWnd> ]             ;
             [ ID <nId> ]              ;
             [ SIZE <width>, <height> ] ;
             [ BACKCOLOR <bcolor> ]     ;
             [ ON INIT <bInit> ]     ;
             [ ON SIZE <bSize> ]     ;
             [ ON DRAW <bDraw> ]     ;
             [ ON CLICK <bClick> ]   ;
             [ ON GETFOCUS <bGfocus> ]   ;
             [ ON LOSTFOCUS <bLfocus> ]  ;
             [ STYLE <nStyle> ]      ;
             [ <flat: FLAT> ]        ;
             [ <enable: DISABLED> ]        ;
             [ TEXT <cText>          ;
             [ COLOR <color>] [ FONT <font> ] ;
             [ COORDINATES  <xt>, <yt>, <widtht>, <heightt> ] ;
             ] ;
             [ BITMAP <bmp>  [<res: FROM RESOURCE>] [<ltr: TRANSPARENT> [COLOR  <trcolor> ]] ;
             [ COORDINATES  <xb>, <yb>, <widthb>, <heightb> ] ;
             ] ;
             [ TOOLTIP <ctoolt> ]    ;
             [ <lCheck: CHECK> ]     ;
             [ <lThemed: THEMED> ]     ;             
          => ;
          [<oOwnBtn> :=] HOWNBUTTON():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, ;
             <height>,<bInit>,<bSize>,<bDraw>,<bClick>,<.flat.>,<cText>,<color>, ;
             <font>,<xt>,<yt>,<widtht>,<heightt>,<bmp>,<.res.>,<xb>,<yb>,<widthb>, ;
             <heightb>,<.ltr.>,<trcolor>,<ctoolt>,!<.enable.>,<.lCheck.>,<bcolor>, <bGfocus>, <bLfocus>,<.lThemed.> );; 
          [ <oOwnBtn>:name := <(oOwnBtn)> ]

#xcommand REDEFINE OWNERBUTTON [ <oOwnBtn> ]  ;
             [ OF <oWnd> ]                     ;
             ID <nId>                          ;
             [ ON INIT <bInit> ]     ;
             [ ON SIZE <bSize> ]     ;
             [ ON DRAW <bDraw> ]     ;
             [ ON CLICK <bClick> ]   ;
             [ <flat: FLAT> ]        ;
             [ TEXT <cText>          ;
             [ COLOR <color>] [ FONT <font> ] ;
             [ COORDINATES  <xt>, <yt>, <widtht>, <heightt> ] ;
             ] ;
             [ BITMAP <bmp>  [<res: FROM RESOURCE>] [<ltr: TRANSPARENT>] ;
             [ COORDINATES  <xb>, <yb>, <widthb>, <heightb> ] ;
             ] ;
             [ TOOLTIP <ctoolt> ]    ;
             [ <enable: DISABLED> ]  ;
             [ <lCheck: CHECK> ]      ;
          => ;
          [<oOwnBtn> :=] HOWNBUTTON():Redefine( <oWnd>,<nId>,<bInit>,<bSize>,;
             <bDraw>,<bClick>,<.flat.>,<cText>,<color>,<font>,<xt>,<yt>,;
             <widtht>,<heightt>,<bmp>,<.res.>,<xb>,<yb>,<widthb>,<heightb>,;
             <.ltr.>,<ctoolt>,!<.enable.>,<.lCheck.> )

#xcommand @ <x>,<y> SHADEBUTTON [ <oShBtn> ]  ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ EFFECT <shadeID>  [ PALETTE <palet> ]             ;
             [ GRANULARITY <granul> ] [ HIGHLIGHT <highl> ] ;
             [ COLORING <coloring> ] [ SHCOLOR <shcolor> ] ];
             [ ON INIT <bInit> ]     ;
             [ ON SIZE <bSize> ]     ;
             [ ON DRAW <bDraw> ]     ;
             [ ON CLICK <bClick> ]   ;
             [ STYLE <nStyle> ]      ;
             [ <flat: FLAT> ]        ;
             [ <enable: DISABLED> ]  ;
             [ TEXT <cText>          ;
             [ COLOR <color>] [ FONT <font> ] ;
             [ COORDINATES  <xt>, <yt> ] ;
             ] ;
             [ BITMAP <bmp>  [<res: FROM RESOURCE>] [<ltr: TRANSPARENT> [COLOR  <trcolor> ]] ;
             [ COORDINATES  <xb>, <yb>, <widthb>, <heightb> ] ;
             ] ;
             [ TOOLTIP <ctoolt> ]    ;
          => ;
          [<oShBtn> :=] HSHADEBUTTON():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, ;
             <height>,<bInit>,<bSize>,<bDraw>,<bClick>,<.flat.>,<cText>,<color>, ;
             <font>,<xt>,<yt>,<bmp>,<.res.>,<xb>,<yb>,<widthb>,<heightb>,<.ltr.>, ;
             <trcolor>,<ctoolt>,!<.enable.>,<shadeID>,<palet>,<granul>,<highl>, ;
             <coloring>,<shcolor> );;
          [ <oShBtn>:name := <(oShBtn)> ]

#xcommand @ <x>,<y> DATEPICKER [ <oPick> ]  ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ INIT <dInit> ]           ;
             [ ON INIT <bInit> ]        ;
             [ ON GETFOCUS <bGfocus> ]  ;
             [ ON LOSTFOCUS <bLfocus> ] ;
             [ ON CHANGE <bChange> ]    ;
             [ STYLE <nStyle> ]         ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
          => ;
          [<oPick> :=] HDatePicker():New( <oWnd>,<nId>,<dInit>,,<nStyle>,<x>,<y>, ;
             <width>,<height>,<oFont>,<bInit>,<bGfocus>,<bLfocus>,<bChange>,<ctoolt>, ;
             <color>,<bcolor> );;
          [ <oPick>:name := <(oPick)> ]

#xcommand REDEFINE DATEPICKER [ <oPick> VAR  ] <vari> ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ INIT <dInit> ]           ;
             [ ON SIZE <bSize>]         ;
             [ ON INIT <bInit> ]        ;
             [ ON GETFOCUS <bGfocus> ]  ;
             [ ON LOSTFOCUS <bLfocus> ] ;
             [ ON CHANGE <bChange> ]    ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
          => ;
          [<oPick> :=] HDatePicker():redefine( <oWnd>,<nId>,<dInit>,{|v|Iif(v==Nil,<vari>,<vari>:=v)}, ;
             <oFont>,<bSize>,<bInit>,<bGfocus>,<bLfocus>,<bChange>,<ctoolt>, ;
             <color>,<bcolor> )

#xcommand @ <x>,<y> SPLITTER [ <oSplit> ] ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ DIVIDE <aLeft> FROM <aRight> ] ;
          => ;
          [<oSplit> :=] HSplitter():New( <oWnd>,<nId>,<x>,<y>,<width>,<height>,<bSize>,<bDraw>,;
             <color>,<bcolor>,<aLeft>,<aRight> );;
          [ <oSplit>:name := <(oSplit)> ]

#xcommand PREPARE FONT <oFont>       ;
             NAME <cName>            ;
             [ WIDTH <nWidth> ]      ;
             [ HEIGHT <nHeight> ]     ;
             [ WEIGHT <nWeight> ]    ;
             [ CHARSET <charset> ]   ;
             [ <ita: ITALIC> ]       ;
             [ <under: UNDERLINE> ]  ;
             [ <strike: STRIKEOUT> ] ;
          => ;
          <oFont> := HFont():Add( <cName>, <nWidth>, <nHeight>, <nWeight>, <charset>, ;
             iif( <.ita.>,1,0 ), iif( <.under.>,1,0 ), iif( <.strike.>,1,0 ) )

/* Print commands */

#xcommand START PRINTER DEFAULT => OpenDefaultPrinter(); StartDoc()

/* SAY ... GET system     */

#xcommand @ <x>,<y> GET [ <oEdit> VAR ]  <vari>  ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ PICTURE <cPicture> ]     ;
             [ WHEN  <bGfocus> ]        ;
             [ VALID <bLfocus> ]        ;
             [<lPassword: PASSWORD>]    ;
             [ MAXLENGTH <nMaxLength> ] ;
             [ STYLE <nStyle> ]         ;
             [<lnoborder: NOBORDER>]    ;
             [ FONT <oFont> ]           ;
             [ ON INIT <bInit> ]        ;
             [ TOOLTIP <ctoolt> ]       ;
             [ ON KEYDOWN <bKeyDown>   ];
             [ ON CHANGE <bChange> ]    ;
             [[ON OTHER MESSAGES <bOther>][ON OTHERMESSAGES <bOther>]] ;
          => ;
          [<oEdit> := ] HEdit():New( <oWnd>,<nId>,<vari>,               ;
             {|v|Iif(v==Nil,<vari>,<vari>:=v)},             ;
             <nStyle>,<x>,<y>,<width>,<height>,<oFont>,<bInit>,,,  ;
             <bGfocus>,<bLfocus>,<ctoolt>,<color>,<bcolor>,<cPicture>,;
             <.lnoborder.>,<nMaxLength>,<.lPassword.>,<bKeyDown>,<bChange>,<bOther>);;
          [ <oEdit>:name := <(oEdit)> ]

/* Added MULTILINE: AJ: 11-03-2007*/
#xcommand REDEFINE GET [ <oEdit> VAR ] <vari>  ;
             [ OF <oWnd> ]              ;
             ID <nId>                   ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ PICTURE <cPicture> ]     ;
             [ WHEN  <bGfocus> ]        ;
             [ VALID <bLfocus> ]        ;
             [ MAXLENGTH <nMaxLength> ] ;
             [ FONT <oFont> ]           ;
             [ ON INIT <bInit> ]        ;
             [ TOOLTIP <ctoolt> ]       ;
             [<lMultiLine: MULTILINE>]  ;
             [ ON KEYDOWN <bKeyDown>]   ;
             [ ON CHANGE <bChange> ]    ;
          => ;
          [<oEdit> := ] HEdit():Redefine( <oWnd>,<nId>,<vari>, ;
             {|v|Iif(v==Nil,<vari>,<vari>:=v)},    ;
             <oFont>,,,,<{bGfocus}>,<{bLfocus}>,<ctoolt>,<color>,<bcolor>,<cPicture>,<nMaxLength>,<.lMultiLine.>,<bKeyDown>, <bChange>)

#xcommand @ <x>,<y> GET CHECKBOX [ <oCheck> VAR ] <vari>  ;
             CAPTION  <caption>         ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [<lTransp: TRANSPARENT>]   ;
             [ <valid: VALID, ON CLICK> <bClick> ] ;
             [ STYLE <nStyle> ]         ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
             [ WHEN <bWhen> ]           ;
             [ <lEnter: ENTER> ]        ;
          => ;
          [<oCheck> := ] HCheckButton():New( <oWnd>,<nId>,<vari>,              ;
             {|v|Iif(v==Nil,<vari>,<vari>:=v)},                   ;
             <nStyle>,<x>,<y>,<width>,<height>,<caption>,<oFont>, ;
             ,,,<bClick>,<ctoolt>,<color>,<bcolor>,<bWhen>,<.lEnter.>,<.lTransp.>);;
          [ <oCheck>:name := <(oCheck)> ]

#xcommand REDEFINE GET CHECKBOX [ <oCheck> VAR ] <vari>  ;
             [ OF <oWnd> ]              ;
             ID <nId>                   ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ <valid: VALID, ON CLICK> <bClick> ] ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
             [ WHEN <bWhen> ]           ;
             [ <lEnter: ENTER> ]        ;
          => ;
          [<oCheck> := ] HCheckButton():Redefine( <oWnd>,<nId>,<vari>, ;
             {|v|Iif(v==Nil,<vari>,<vari>:=v)},           ;
             <oFont>,,,,<bClick>,<ctoolt>,<color>,<bcolor>,<bWhen>,<.lEnter.>)

#xcommand @ <x>,<y> GET COMBOBOX [ <oCombo> VAR ] <vari> ;
            ITEMS  <aItems>            ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ DISPLAYCOUNT <nDisplay>] ;
            [ ITEMHEIGHT <nhItem>    ] ; 
            [ COLUMNWIDTH <ncWidth>  ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ ON INIT <bInit> ]        ;
            [ ON CHANGE <bChange> ]    ;
            [ STYLE <nStyle> ]         ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
            [ <edit: EDIT> ]           ;
            [ <text: TEXT> ]           ;
            [ WHEN  <bGfocus> ]        ;
            [ VALID <bLfocus> ]        ;
            [ ON INTERACTIVECHANGE <bIChange> ]    ;
          => ;
    [<oCombo> := ] HComboBox():New( <oWnd>,<nId>,<vari>,    ;
                    {|v|Iif(v==Nil,<vari>,<vari>:=v)},      ;
                    <nStyle>,<x>,<y>,<width>,<height>,      ;
                    <aItems>,<oFont>,<bInit>,,,<bChange>,<ctoolt>, ;
                    <.edit.>,<.text.>,<bGfocus>,<color>,<bcolor>,;
										<bLfocus>,<bIChange>,<nDisplay>,<nhItem>,<ncWidth> );;
    [ <oCombo>:name := <(oCombo)> ]                                                                      


#xcommand REDEFINE GET COMBOBOX [ <oCombo> VAR ] <vari> ;
            ITEMS  <aItems>            ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            [ DISPLAYCOUNT <nDisplay>] ;
            [ ON CHANGE <bChange> ]    ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
            [ WHEN  <bGfocus> ]        ;
            [ VALID <bLfocus> ]        ;
            [ ON INTERACTIVECHANGE <bIChange> ]    ;
          => ;
    [<oCombo> := ] HComboBox():Redefine( <oWnd>,<nId>,<vari>, ;
                    {|v|Iif(v==Nil,<vari>,<vari>:=v)},        ;
                    <aItems>,<oFont>,,,,<bChange>,<ctoolt>,<bGfocus>, <bLfocus>,<bIChange>,<nDisplay>)

#xcommand REDEFINE GET COMBOBOXEX [ <oCombo> VAR ] <vari> ;
             ITEMS  <aItems>            ;
             [ OF <oWnd> ]              ;
             ID <nId>                   ;
             [ ON CHANGE <bChange> ]    ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
             [ WHEN <bWhen> ]           ;
             [ CHECK <acheck>] ;
          => ;
          [<oCombo> := ] HComboBox():Redefine( <oWnd>,<nId>,<vari>, ;
             {|v|Iif(v==Nil,<vari>,<vari>:=v)},        ;
             <aItems>,<oFont>,,,,<bChange>,<ctoolt>, <bWhen> ,<acheck>)

#xcommand @ <x>,<y> GET UPDOWN [ <oUpd> VAR ]  <vari>  ;
             RANGE <nLower>,<nUpper>    ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ INCREMENT <nIncr> ]      ;        
             [ WIDTH <nUpDWidth> ]      ;
             [ MAXLENGTH <nMaxLength> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ PICTURE <cPicture> ]     ;
             [ WHEN  <bGfocus> ]        ;
             [ VALID <bLfocus> ]        ;
             [ STYLE <nStyle> ]         ;
             [ FONT <oFont> ]           ;
             [<lnoborder: NOBORDER>]    ;
             [ TOOLTIP <ctoolt> ]       ;
             [ ON INIT <bInit> ]        ;
             [ ON KEYDOWN <bKeyDown>   ];
             [ ON CHANGE <bChange> ]    ;
             [[ON OTHER MESSAGES <bOther>][ON OTHERMESSAGES <bOther>]] ;
          => ;
          [<oUpd> := ] HUpDown():New( <oWnd>,<nId>,<vari>,{|v|Iif(v==Nil,<vari>,<vari>:=v)}, ;
             <nStyle>,<x>,<y>,<width>,<height>,<oFont>,<bInit>,,,;
             <bGfocus>,<bLfocus>,<ctoolt>,<color>,<bcolor>, ;
             <nUpDWidth>,<nLower>,<nUpper>,<nIncr>,<cPicture>,<.lnoborder.>,;
             <nMaxLength>,<bKeyDown>,<bChange>,<bOther>,,);;            
          [ <oUpd>:name := <(oUpd)> ]


#xcommand @ <x>,<y> GET DATEPICKER [ <oPick> VAR ] <vari> ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ ON INIT <bInit> ]        ;
             [ WHEN <bGfocus> ]         ;
             [ VALID <bLfocus> ]        ;
             [ ON CHANGE <bChange> ]    ;
             [ STYLE <nStyle> ]         ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
          => ;
          [<oPick> :=] HDatePicker():New( <oWnd>,<nId>,<vari>,    ;
             {|v|Iif(v==Nil,<vari>,<vari>:=v)},      ;
             <nStyle>,<x>,<y>,<width>,<height>,      ;
             <oFont>,<bInit>,<bGfocus>,<bLfocus>,<bChange>,<ctoolt>,<color>,<bcolor> );;
          [ <oPick>:name := <(oPick)> ]

#xcommand SAY <value> TO <oDlg> ID <id> ;
          => ;
          SetDlgItemText( <oDlg>:handle, <id>, <value> )

/*   Menu system     */

#xcommand MENU [ OF <oWnd> ] [ ID <nId> ] [ TITLE <cTitle> ] ;
          => ;
          Hwg_BeginMenu( <oWnd>, <nId>, <cTitle> )

#xcommand CONTEXT MENU <oMenu> => <oMenu> := Hwg_ContextMenu()

#xcommand ENDMENU => Hwg_EndMenu()

#xcommand MENUITEM <item> [ ID <nId> ]    ;
             ACTION <act>                  ;
             [ BITMAP <bmp> ]               ; //ADDED by Sandro Freire
             [<res: FROM RESOURCE>]        ; //true use image from resource
             [ ACCELERATOR <flag>, <key> ] ;
             [<lDisabled: DISABLED>]       ;
          => ;
          Hwg_DefineMenuItem( <item>, <nId>, <{act}>, <.lDisabled.>, <flag>, <key>, <bmp>, <.res.>, .f. )

#xcommand MENUITEMCHECK <item> [ ID <nId> ]    ;
             [ ACTION <act> ]              ;
             [ ACCELERATOR <flag>, <key> ] ;
             [<lDisabled: DISABLED>]       ;
          => ;
          Hwg_DefineMenuItem( <item>, <nId>, <{act}>, <.lDisabled.>, <flag>, <key>,,, .t. )

#xcommand MENUITEMBITMAP <oMain>  ID <nId> ;
             BITMAP <bmp>                  ;
             [<res: FROM RESOURCE>]         ;
          => ;
          Hwg_InsertBitmapMenu( <oMain>:menu, <nId>, <bmp>, <.res.>)

#xcommand ACCELERATOR <flag>, <key>       ;
             [ ID <nId> ]                  ;
             ACTION <act>                  ;
          => ;
          Hwg_DefineAccelItem( <nId>, <{act}>, <flag>, <key> )

#xcommand SEPARATOR => Hwg_DefineMenuItem()

#xcommand SET TIMER <oTimer> [ OF <oWnd> ] [ ID <id> ] ;
             VALUE <value> ACTION <bAction> ;
          => ;
          <oTimer> := HTimer():New( <oWnd>, <id>, <value>, <bAction> );;
          [ <oTimer>:name := <(oTimer)> ]

#xcommand SET KEY <nctrl>,<nkey> [ OF <oDlg> ] [ TO <func> ] ;
          => ;
          SetDlgKey( <oDlg>, <nctrl>, <nkey>, <{func}> )

#translate LastKey( )  =>  HWG_LASTKEY( )

/*             */
#xcommand @ <x>,<y> GRAPH [ <oGraph> DATA ] <aData> ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ ON SIZE <bSize> ]        ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
          => ;
          [<oGraph> := ] HGraph():New( <oWnd>,<nId>,<aData>,<x>,<y>,<width>, ;
             <height>,<oFont>,<bSize>,<ctoolt>,<color>,<bcolor> );;
          [ <oGraph>:name := <(oGraph)> ]

/* open an .dll resource */
#xcommand SET RESOURCES TO <cName1> => LoadResource( <cName1> )

#xcommand SET RESOURCES TO => LOADRESOURCE( NIL )

#xcommand SET COLORFOCUS <x:ON,OFF,&> [COLOR [<tColor>],[<bColor>]] [< lFixed : NOFIXED >] [< lPersistent : PERSISTENT >];
          => ;
          SetColorinFocus( <(x)> , <tColor>, <bColor>, <.lFixed.>, <.lPersistent.> )

#xcommand SET DISABLEBACKCOLOR <x:ON,OFF,&> [COLOR [<bColor>]] ;
          => ;
          SetDisableBackColor( <(x)> , <bColor> )

// Addded by jamaj
#xcommand DEFAULT <uVar1> := <uVal1> ;
             [, <uVarN> := <uValN> ] ;
          => ;
          <uVar1> := IIf( <uVar1> == nil, <uVal1>, <uVar1> ) ;;
          [ <uVarN> := IIf( <uVarN> == nil, <uValN>, <uVarN> ); ]

#xcommand @ <x>,<y> GET IPADDRESS [ <oIp> VAR ] <vari> ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ BACKCOLOR <bcolor> ]     ;
             [ STYLE <nStyle> ]         ;
             [ FONT <oFont> ]           ;
             [ ON GETFOCUS <bGfocus> ]      ;
             [ ON LOSTFOCUS <bLfocus> ]     ;
          => ;
          [<oIp> := ] HIpEdit():New( <oWnd>,<nId>,<vari>,{|v| iif(v==Nil,<vari>,<vari>:=v)},<nStyle>,<x>,<y>,<width>,<height>,<oFont>, <bGfocus>, <bLfocus> );;
          [ <oIp>:name := <(oIp)> ]

#define ISOBJECT(c)    ( Valtype(c) == "O" )
#define ISBLOCK(c)     ( Valtype(c) == "B" )
#define ISARRAY(c)     ( Valtype(c) == "A" )
#define ISNUMBER(c)    ( Valtype(c) == "N" )
#define ISLOGICAL(c)   ( Valtype(c) == "L" )

/* Commands for PrintDos Class*/

#xcommand SET PRINTER TO <oPrinter> OF <oPtrObj>     ;
          => ;
          <oPtrObj>:=Printdos():New( <oPrinter>)

#xcommand @ <x>,<y> PSAY  <vari>  ;
             [ PICTURE <cPicture> ] OF <oPtrObj>   ;
          => ;
          <oPtrObj>:Say(<x>, <y>, <vari>, <cPicture>)

#xcommand EJECT OF <oPtrObj> => <oPtrObj>:Eject()

#xcommand END PRINTER <oPtrObj> => <oPtrObj>:End()

/* Hprinter */

#xcommand INIT PRINTER <oPrinter>   ;
             [ NAME <cPrinter> ]     ;
             [ <lPixel: PIXEL> ]     ;
             [ FORMTYPE  <nFormType> ];
             [ BIN <nBin> ];
             [ <lLandScape: LANDSCAPE>];
             [ COPIES <nCopies> ];
          =>  ;
          <oPrinter> := HPrinter():New( <cPrinter>,!<.lPixel.>, <nFormType>, <nBin>, <.lLandScape.>, <nCopies> )

#xcommand INIT DEFAULT PRINTER <oPrinter>   ;
             [ <lPixel: PIXEL> ]             ;
             [ FORMTYPE  <nFormType> ];
             [ BIN <nBin> ];
             [ <lLandScape: LANDSCAPE>];
             [ COPIES <nCopies> ];
          =>  ;
          <oPrinter> := HPrinter():New( "",!<.lPixel.>, <nFormType>, <nBin>, <.lLandScape.>, <nCopies>  )

/*
Command for MonthCalendar Class
Added by Marcos Antonio Gambeta
*/

#xcommand @ <x>,<y> MONTHCALENDAR [ <oMonthCalendar> ] ;
             [ OF <oWnd> ]                              ;
             [ ID <nId> ]                               ;
             [ SIZE <nWidth>,<nHeight> ]                ;
             [ INIT <dInit> ]                           ;
             [ ON INIT <bInit> ]                        ;
             [ ON CHANGE <bChange> ]                    ;
             [ ON SELECT <bSelect> ]                   ;
             [ STYLE <nStyle> ]                         ;
             [ FONT <oFont> ]                           ;
             [ TOOLTIP <cTooltip> ]                     ;
             [ < notoday : NOTODAY > ]                  ;
             [ < notodaycircle : NOTODAYCIRCLE > ]      ;
             [ < weeknumbers : WEEKNUMBERS > ]          ;
          => ;
          [<oMonthCalendar> :=] HMonthCalendar():New( <oWnd>,<nId>,<dInit>,<nStyle>,;
             <x>,<y>,<nWidth>,<nHeight>,<oFont>,<bInit>,<bChange>,<cTooltip>,;
             <.notoday.>,<.notodaycircle.>,<.weeknumbers.>,<bSelect> );;
          [ <oMonthCalendar>:name := <(oMonthCalendar)> ]

#xcommand @ <x>,<y> LISTBOX [ <oListbox> ITEMS ] <aItems> ;
             [ OF <oWnd> ]                 ;
             [ ID <nId> ]                  ;
             [ INIT <nInit> ]              ;
             [ SIZE <width>, <height> ]    ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ ON INIT <bInit> ]           ;
             [ ON SIZE <bSize> ]           ;
             [ ON PAINT <bDraw> ]          ;
             [ ON CHANGE <bChange> ]       ;
             [ STYLE <nStyle> ]            ;
             [ FONT <oFont> ]              ;
             [ TOOLTIP <ctoolt> ]          ;
             [ ON GETFOCUS <bGfocus> ]     ;
             [ ON LOSTFOCUS <bLfocus> ]    ;
             [ ON KEYDOWN <bKeyDown> ]  ;
             [ ON DBLCLICK <bDblClick> ];
             [[ON OTHER MESSAGES <bOther>][ON OTHERMESSAGES <bOther>]] ;
          => ;
          [<oListbox> := ] HListBox():New( <oWnd>,<nId>,<nInit>,,<nStyle>,<x>,<y>,<width>, ;
             <height>,<aItems>,<oFont>,<bInit>,<bSize>,<bDraw>,<bChange>,<ctoolt>,;
             <color>,<bcolor>, <bGfocus>,<bLfocus>,<bKeyDown>,<bDblClick>,<bOther> ) ;;
          [ <oListbox>:name := <(oListbox)> ]

#xcommand REDEFINE LISTBOX [ <oListbox> ITEMS ] <aItems> ;
             [ OF <oWnd> ]                 ;
             ID <nId>                      ;
             [ INIT <nInit>    ]           ;
             [ ON INIT <bInit> ]           ;
             [ ON SIZE <bSize> ]           ;
             [ ON PAINT <bDraw> ]          ;
             [ ON CHANGE <bChange> ]       ;
             [ FONT <oFont> ]              ;
             [ TOOLTIP <ctoolt> ]          ;
             [ ON GETFOCUS <bGfocus> ]     ;
             [ ON LOSTFOCUS <bLfocus> ]    ;
             [ ON KEYDOWN <bKeyDown> ]     ;
             [[ON OTHER MESSAGES <bOther>][ON OTHERMESSAGES <bOther>]] ;
          => ;
          [<oListbox> := ] HListBox():Redefine( <oWnd>,<nId>,<nInit>,,<aItems>,<oFont>,<bInit>, ;
             <bSize>,<bDraw>,<bChange>,<ctoolt>,<bGfocus>,<bLfocus>, <bKeyDown>,<bOther> )

/* Add Sandro R. R. Freire */

#xcommand SPLASH [<osplash> TO]  <oBitmap> ;
             [<res: FROM RESOURCE>]         ;
             [ TIME <otime> ]               ;
             [WIDTH <w>];
             [HEIGHT <h>];
          => ;
          [ <osplash> := ] HSplash():Create(<oBitmap>,<otime>,<.res.>,<w>,<h>)

// Nice Buttons by Luiz Rafael
#xcommand @ <x>,<y> NICEBUTTON [ <oBut> CAPTION ] <caption> ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ ON INIT <bInit> ]        ;
             [ ON CLICK <bClick> ]      ;
             [ STYLE <nStyle> ]         ;
             [ EXSTYLE <nStyleEx> ]         ;
             [ TOOLTIP <ctoolt> ]       ;
             [ RED <r> ] ;
             [ GREEN <g> ];
             [ BLUE <b> ];
          => ;
          [<oBut> := ] HNicebutton():New( <oWnd>,<nId>,<nStyle>,<nStyleEx>,<x>,<y>,<width>, ;
             <height>,<bInit>,<bClick>,<caption>,<ctoolt>,<r>,<g>,<b> );;
          [ <oBut>:name := <(oBut)> ]

#xcommand REDEFINE NICEBUTTON [ <oBut> CAPTION ] <caption> ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ ON INIT <bInit> ]        ;
             [ ON CLICK <bClick> ]      ;
             [ EXSTYLE <nStyleEx> ]         ;
             [ TOOLTIP <ctoolt> ]       ;
             [ RED <r> ] ;
             [ GREEN <g> ];
             [ BLUE <b> ];
          => ;
          [<oBut> := ] HNicebutton():Redefine( <oWnd>,<nId>,<nStyleEx>, ;
             <bInit>,<bClick>,<caption>,<ctoolt>,<r>,<g>,<b> )

// trackbar control
#xcommand @ <x>,<y> TRACKBAR [ <oTrackBar> ]  ;
             [ OF <oWnd> ]                 ;
             [ ID <nId> ]                  ;
             [ SIZE <width>, <height> ]    ;
             [ RANGE <nLow>,<nHigh> ]      ;
             [ INIT <nInit> ]              ;
             [ ON INIT <bInit> ]           ;
             [ ON SIZE <bSize> ]           ;
             [ ON PAINT <bDraw> ]          ;
             [ ON CHANGE <bChange> ]       ;
             [ ON DRAG <bDrag> ]           ;
             [ STYLE <nStyle> ]            ;
             [ TOOLTIP <cTooltip> ]        ;
             [ < vertical : VERTICAL > ]   ;
             [ < autoticks : AUTOTICKS > ] ;
             [ < noticks : NOTICKS > ]     ;
             [ < both : BOTH > ]           ;
             [ < top : TOP > ]             ;
             [ < left : LEFT > ]           ;
          => ;
          [<oTrackBar> :=] HTrackBar():New( <oWnd>,<nId>,<nInit>,<nStyle>,<x>,<y>,      ;
             <width>,<height>,<bInit>,<bSize>,<bDraw>,<cTooltip>,<bChange>,<bDrag>,<nLow>,<nHigh>,<.vertical.>,;
             Iif(<.autoticks.>,1,Iif(<.noticks.>,16,0)), ;
             Iif(<.both.>,8,Iif(<.top.>.or.<.left.>,4,0)) );;
          [ <oTrackBar>:name := <(oTrackBar)> ]

// animation control
#xcommand @ <x>,<y>  ANIMATION [ <oAnimation> ] ;
             [ OF <oWnd> ]                       ;
             [ ID <nId> ]                        ;
             [ FROM RESOURCE <xResID> ]          ;
             [ STYLE <nStyle> ]                  ;
             [ SIZE <nWidth>, <nHeight> ]        ;
             [ FILE <cFile> ]                    ;
             [ < autoplay: AUTOPLAY > ]          ;
             [ < center : CENTER > ]             ;
             [ < transparent: TRANSPARENT > ]    ;
          => ;
          [<oAnimation> :=] HAnimation():New( <oWnd>,<nId>,<nStyle>,<x>,<y>, ;
             <nWidth>,<nHeight>,<cFile>,<.autoplay.>,<.center.>,<.transparent.>,<xResID>);;
          [ <oAnimation>:name := <(oAnimation)> ]

//Contribution   Ricardo de Moura Marques
#xcommand @ <X>, <Y>, <X2>, <Y2> RECT <oRect> [<lPress: PRESS>] [OF <oWnd>] [RECT_STYLE <nST>];
          => <oRect> := HRect():New(<oWnd>,<X>,<Y>,<X2>,<Y2>, <.lPress.>, <nST> )
          //  [ <oRect>:name := <(oRect)> ]

//New Control
#xcommand @ <x>,<y> SAY [ <oSay> CAPTION ] <caption> ;
             [ OF <oWnd> ]              ;
             LINK <cLink>               ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ <lTransp: TRANSPARENT>]  ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ STYLE <nStyle> ]         ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
             [ VISITCOLOR <vcolor> ]    ;
             [ LINKCOLOR <lcolor> ]     ;
             [ HOVERCOLOR <hcolor> ]    ;
          => ;
          [<oSay> := ] HStaticLink():New( <oWnd>, <nId>, <nStyle>, <x>, <y>, <width>, ;
             <height>, <caption>, <oFont>, <bInit>, <bSize>, <bDraw>, <ctoolt>, ;
             <color>, <bcolor>, <.lTransp.>, <cLink>, <vcolor>, <lcolor>, <hcolor> );;
          [ <oSay>:name := <(oSay)> ]

#xcommand REDEFINE SAY [ <oSay> CAPTION ] <cCaption>      ;
             [ OF <oWnd> ]              ;
             ID <nId>                   ;
             LINK <cLink>               ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ <lTransp: TRANSPARENT>]  ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
             [ VISITCOLOR <vcolor> ]    ;
             [ LINKCOLOR <lcolor> ]     ;
             [ HOVERCOLOR <hcolor> ]    ;
          => ;
          [<oSay> := ] HStaticLink():Redefine( <oWnd>, <nId>, <cCaption>, ;
             <oFont>, <bInit>, <bSize>, <bDraw>, <ctoolt>, <color>, <bcolor>,;
             <.lTransp.>, <cLink>, <vcolor>, <lcolor>, <hcolor> )

#xcommand TOOLBUTTON  <O>       ;
             ID <nId>              ;
             [ BITMAP <nBitIp> ]   ;
             [ STYLE <bstyle> ]    ;
             [ STATE <bstate>]     ;
             [ TEXT <ctext> ]      ;
             [ TOOLTIP <c> ]       ;
             [ MENU <d>]           ;
             ON CLICK <bclick>    ;
          =>;
          <O>:AddButton(<nBitIp>,<nId>,<bstate>,<bstyle>,<ctext>,<bclick>,<c>,<d>)

#xcommand @ <x>,<y> TOOLBAR [ <oTool> ] ;
            [ OF <oWnd> ]               ;
            [ ID <nId> ]                ;
            [ SIZE <width>, <height> ]  ;
            [ BUTTONWIDTH <btnwidth> ]  ;
            [ INDENT <nIndent>       ]  ;
						[ BITMAPSIZE <nSize>     ]  ;
            [ FONT <oFont> ]           ;   
            [ ON INIT <bInit> ]         ;
            [<lTransp: TRANSPARENT>]    ;
            [<lVertical: VERTICAL>]     ;
            [ STYLE <nStyle> ]          ;
            [ LOADSTANDARDIMAGE <nIDB>] ;
            [ ITEMS <aItems> ]          ;
          => ;
    [<oTool> := ]  Htoolbar():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, <height>,<btnwidth>,<oFont>,;
              <bInit>,,,,,,<.lTransp.>,<.lVertical.>,<aItems>,<nSize>,<nIndent>,<nIDB>) ;;
    [ <oTool>:name := <(oTool)> ] 

#xcommand REDEFINE TOOLBAR  <oSay>     ;
             [ OF <oWnd> ]              ;
             ID <nId>                   ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ITEM <aitem>];
          => ;
          [<oSay> := ] Htoolbar():Redefine( <oWnd>,<nId>,,  ,<bInit>,<bSize>,<bDraw>, , , , ,<aitem> )

#xcommand CREATE MENUBAR <o> => <o> := \{ \}

#xcommand MENUBARITEM  <oWnd> CAPTION <c> ON <id1> ACTION <b1>      ;
          => ;
          Aadd( <oWnd>, \{ <c>, <id1>, <{b1}> \})

#xcommand ADD TOOLBUTTON  <O> ;
             ID <nId> ;
             [ BITMAP <nBitIp> ];
             [ STYLE <bstyle> ];
             [ STATE <bstate>];
             [ TEXT <ctext> ] ;
             [ TOOLTIP <c> ];
             [ MENU <d>];
             ON CLICK <bclick>;
          =>;
          aadd(<O> ,\{<nBitIp>,<nId>,<bstate>,<bstyle>,,<ctext>,<bclick>,<c>,<d>,,\})

#xcommand ADDTOOLBUTTON  <oTool> ;
             [ ID <nId> ];
             [ BITMAP <nBitIp> ];
             [ STYLE <bstyle> ];
             [ STATE <bstate>];
             [ TEXT <ctext> ] ;
             [ TOOLTIP <c> ];
             [ MENU <d>];
             [ NAME < cButton > ];
             ON CLICK <bclick>;
          =>;
          <oTool>:AddButton( <nBitIp>,<nId>,<bstate>,<bstyle>,<ctext>,<bclick>,<c>,<d>,<cButton>

#xcommand @ <x>,<y> GRIDEX <oGrid>        ;
             [ OF <oWnd> ]               ;
             [ ID <nId> ]                ;
             [ STYLE <nStyle> ]          ;
             [ SIZE <width>, <height> ]  ;
             [ FONT <oFont> ]            ;
             [ ON INIT <bInit> ]         ;
             [ ON SIZE <bSize> ]         ;
             [ ON PAINT <bPaint> ]       ;
             [ ON CLICK <bEnter> ]       ;
             [ ON GETFOCUS <bGfocus> ]   ;
             [ ON LOSTFOCUS <bLfocus> ]  ;
             [ ON KEYDOWN <bKeyDown> ]   ;
             [ ON POSCHANGE <bPosChg> ]  ;
             [ ON DISPINFO <bDispInfo> ] ;
             [ ITEMCOUNT <nItemCount> ]  ;
             [ <lNoScroll: NOSCROLL> ]   ;
             [ <lNoBord: NOBORDER> ]     ;
             [ <lNoLines: NOGRIDLINES> ] ;
             [ COLOR <color> ]           ;
             [ BACKCOLOR <bkcolor> ]     ;
             [ <lNoHeader: NO HEADER> ]  ;
             [BITMAP <aBit>];
             [ ITEMS <a>];
          => ;
          <oGrid> := HGridEx():New( <oWnd>, <nId>, <nStyle>, <x>, <y>, <width>, <height>,;
             <oFont>, <{bInit}>, <{bSize}>, <{bPaint}>, <{bEnter}>,;
             <{bGfocus}>, <{bLfocus}>, <.lNoScroll.>, <.lNoBord.>,;
             <{bKeyDown}>, <{bPosChg}>, <{bDispInfo}>, <nItemCount>,;
             <.lNoLines.>, <color>, <bkcolor>, <.lNoHeader.> ,<aBit>,<a>);;
          [ <oGrid>:name := <(oGrid)> ]

#xcommand ADDROW TO GRID <oGrid>    ;
             [ HEADER <cHeader> ]        ;
             [ JUSTIFY HEAD <nJusHead> ] ;
             [ BITMAP <n> ]              ;
             [ HEADER <cHeadern> ]        ;
             [ JUSTIFY HEAD <nJusHeadn> ] ;
             [ BITMAP <nn> ]              ;
          => ;
          <oGrid>:AddRow(<cHeader>,<nJusHead>,<n>) [;<oGrid>:AddRow(<cHeadern>,<nJusHeadn>,<nn>)]

#xcommand ADDROWEX TO GRID <oGrid>        ;
             [ HEADER <cHeader>         ;
             [ BITMAP <n> ]              ;
             [ COLOR <color> ]           ;
             [ BACKCOLOR <bkcolor> ]][,     ;
             HEADER <cHeadern>        ;
             [ BITMAP <nn> ]             ;
             [ COLOR <colorn> ]          ;
             [ BACKCOLOR <bkcolorn> ]]    ;
          => ;
          <oGrid>:AddRow(\{<cHeader>,<n>,<color>,<bkcolor> [,<cHeadern>,<nn>,<colorn>,<bkcolorn> ] \})

#xcommand ADDROWEX TO GRID <oGrid>        ;
             [ HEADER <cHeader>         ;
             [ BITMAP <n> ]              ;
             [ COLOR <color> ]           ;
             [ BACKCOLOR <bkcolor> ]][,     ;
             HEADER <cHeadern>        ;
             [ BITMAP <nn> ]             ;
             [ COLOR <colorn> ]          ;
             [ BACKCOLOR <bkcolorn> ]]    ;
          => ;
          <oGrid>:AddRow(\{<cHeader>,<n>,<color>,<bkcolor> [,<cHeadern>,<nn>,<colorn>,<bkcolorn> ] \})

#xcommand REDEFINE TAB  <oSay>  ;
             [ OF <oWnd> ]              ;
             ID <nId>                   ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ON CHANGE <bChange> ]    ;
          => ;
          [<oSay> := ] Htab():Redefine( <oWnd>,<nId>,,  ,<bInit>,<bSize>,<bDraw>, , , , ,<bChange> )

#xcommand ADDROWEX  <oGrid>        ;
             HEADER <cHeader>         ;
             [ BITMAP <n> ]              ;
             [ COLOR <color> ]           ;
             [ BACKCOLOR <bkcolor> ]     ;
             [ HEADER <cHeadern> ]       ;
             [ BITMAP <nn> ]             ;
             [ COLOR <colorn> ]          ;
             [ BACKCOLOR <bkcolorn> ]    ;
          => ;
          <oGrid>:AddRow(\{<cHeader>,<n>,<color>,<bkcolor> [, <cHeadern>,<nn>,<colorn>,<bkcolorn>] \})

#xcommand REDEFINE STATUS  <oSay>  ;
             [ OF <oWnd> ]              ;
             ID <nId>                   ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ PARTS <bChange,...> ]    ;
          => ;
          [<oSay> := ] HStatus():Redefine( <oWnd>,<nId>,,  ,<bInit>,<bSize>,<bDraw>, , , , ,\{<bChange>\} )

#xcommand REDEFINE GRID  <oSay>  ;
             [ OF <oWnd> ]              ;
             ID <nId>                   ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ITEM <aitem>];
          => ;
          [<oSay> := ] HGRIDex():Redefine( <oWnd>,<nId>,,  ,<bInit>,<bSize>,<bDraw>, , , , ,<aitem> )

#xcommand @ <x>,<y> PAGER [ <oTool> ] ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ STYLE <nStyle> ]         ;
             [ <lVert: VERTICAL> ] ;
          => ;
          [<oTool> := ] HPager():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, <height>,,,,,,,,,<.lVert.>);;
          [ <oTool>:name := <(oTool)> ]

#xcommand @ <x>,<y> REBAR [ <oTool> ] ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ STYLE <nStyle> ]         ;
          => ;
          [<oTool> := ]        HREBAR():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, <height>,,,,,,,,);;
          [ <oTool>:name := <(oTool)> ]

#xcommand ADDBAND <hWnd> to <opage> ;
             [BACKCOLOR <b> ] [FORECOLOR <f>] ;
             [STYLE <nstyle>] [TEXT <t>] ;
          => ;
          <opage>:ADDBARColor(<hWnd>,<f>,<b>,<t>,<nstyle>)

#xcommand ADDBAND <hWnd> to <opage> ;
             [BITMAP <b> ]  ;
             [STYLE <nstyle>] [TEXT <t>] ;
          => ;
          <opage>:ADDBARBITMAP(<hWnd>,<t>,<b>,<nstyle>)

#xcommand @ <x>,<y> GET LISTBOX [ <oListbox> VAR ]  <vari> ;
             ITEMS  <aItems>            ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ON CHANGE <bChange> ]    ;
             [ STYLE <nStyle> ]         ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
             [ WHEN <bGFocus> ]         ;
             [ VALID <bLFocus> ]        ;
             [ ON KEYDOWN <bKeyDown> ]  ;
             [ ON DBLCLICK <bDblClick> ];
             [[ON OTHER MESSAGES <bOther>][ON OTHERMESSAGES <bOther>]] ;
          => ;
          [<oListbox> := ] HListBox():New( <oWnd>,<nId>,<vari>,;
             {|v|Iif(v==Nil,<vari>,<vari>:=v)},;
             <nStyle>,<x>,<y>,<width>,<height>,<aItems>,<oFont>,<bInit>,<bSize>,<bDraw>, ;
             <bChange>,<ctoolt>,<color>,<bcolor>,<bGFocus>,<bLFocus>,<bKeyDown>,<bDblClick>,<bOther>);;
          [ <oListbox>:name := <(oListbox)> ]

          
#xcommand @ <x>,<y> GET COMBOBOXEX [ <oCombo> VAR ] <vari> ;
             ITEMS  <aItems>            ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ DISPLAYCOUNT <nDisplay>] ;
             [ ITEMHEIGHT <nhItem>    ] ; 
             [ COLUMNWIDTH <ncWidth>  ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ ON CHANGE <bChange> ]    ;
             [ STYLE <nStyle> ]         ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
             [ <edit: EDIT> ]           ;
             [ <text: TEXT> ]           ;
             [ WHEN <bWhen> ]           ;
             [ VALID <bValid> ]         ;
             [CHECK <acheck>];
          => ;
          [<oCombo> := ] HCheckComboBox():New( <oWnd>,<nId>,<vari>,    ;
             {|v|Iif(v==Nil,<vari>,<vari>:=v)},      ;
             <nStyle>,<x>,<y>,<width>,<height>,      ;
             <aItems>,<oFont>,,,,<bChange>,<ctoolt>, ;
             <.edit.>,<.text.>,<bWhen>,<color>,<bcolor>, ;
						 <bValid>,<acheck>,<nDisplay>,<nhItem>,<ncWidth>);;
          [ <oCombo>:name := <(oCombo)> ]

//Contribution Luis Fernando Basso

#xcommand @ <x>, <y>  SHAPE [<oShape>] [OF <oWnd>] ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ BORDERWIDTH <nBorder> ]  ;
             [ CURVATURE <nCurvature>]  ;
             [ COLOR <tcolor> ]         ;
             [ BACKCOLOR <bcolor> ]     ;
             [ BORDERSTYLE <nbStyle>]   ;
             [ FILLSTYLE <nfStyle>]     ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
          => ;
          <oShape> := HShape():New(<oWnd>, <nId>, <x>, <y>, <width>, <height>, ;
             <nBorder>, <nCurvature>, <nbStyle>,<nfStyle>, <tcolor>, <bcolor>, <bSize>,<bInit>);;
          [ <oShape>:name := <(oShape)> ]

#xcommand @ <x>, <y>  CONTAINER [<oCnt>] [OF <oWnd>] ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ BACKSTYLE <nbackStyle>]    ;
             [ COLOR <tcolor> ]         ;
             [ BACKCOLOR <bcolor> ]     ;
             [ STYLE <ncStyle>]          ;
             [ <lnoBorder: NOBORDER> ]   ;
             [ ON LOAD <bLoad> ]        ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;           
             [ <lTabStop: TABSTOP> ]   ;
             [ ON REFRESH <bRefresh> ]      ;
             [ ON OTHER MESSAGES <bOther> ] ;
             [ ON OTHERMESSAGES <bOther>  ] ;
             [ <class: CLASS> <classname> ] ;
          =>  ;
          [<oCnt> := ] __IIF(<.class.>, <classname>,HContainer)():New(<oWnd>, <nId>,IIF(<.lTabStop.>,WS_TABSTOP,),;
               <x>, <y>, <width>, <height>, <ncStyle>, <bSize>, <.lnoBorder.>,<bInit>,<nbackStyle>,<tcolor>,<bcolor>,;
               <bLoad>,<bRefresh>,<bOther>);;
          [ <oCnt>:name := <(oCnt)> ] 

