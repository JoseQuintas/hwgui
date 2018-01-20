
#xcommand @ <x>,<y> BROWSEEX [ <oBrw> ] ;
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
             [ TOOLTIP <ctoolt> ]       ;
             [ <class: CLASS> <classname> ] ;
          => ;
          [<oBrw> :=] HBrowseEx():New( Iif(<.lDb.>,BRW_DATABASE,Iif(<.lArr.>,BRW_ARRAY,0)),;
             <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>,<height>,<oFont>,<bInit>,<bSize>, ;
             <bDraw>,<bEnter>,<bGfocus>,<bLfocus>,<.lNoVScr.>,<.lNoBord.>, <.lAppend.>,;
             <.lAutoedit.>, <bUpdate>, <bKeyDown>, <bPosChg>, <.lMulti.>, <.lDescend.>,;
             <bWhile>, <bFirst>, <bLast>, <bFor>, <bOther>, <color>, <bcolor>, <bRClick>,<bChgrowcol>, <ctoolt>  );;
          [; hwg_SetCtrlName( <oBrw>,<(oBrw)> )]


#xcommand ADD COLUMNEX <block> TO <oBrw> ;
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
             [ [ON] COLORBLOCK <bClrBlck> ]  ;
             [ [ON] BHEADCLICK <bHeadClick> ]  ;
          => ;
          <oBrw>:AddColumn( HColumnEx():New( <cHeader>,<block>,<cType>,<nLen>,<nDec>,<.lEdit.>,;
             <nJusHead>, <nJusLine>, <cPict>, <{bValid}>, <{bWhen}>, <aItem>, <{bClrBlck}>, <{bHeadClick}>, <color>, <bcolor>, <bClick> ) )

#xcommand INSERT COLUMNEX <block> TO <oBrw> ;
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
          <oBrw>:InsColumn( HColumnEx():New( <cHeader>,<block>,<cType>,<nLen>,<nDec>,<.lEdit.>,;
             <nJusHead>, <nJusLine>, <cPict>, <{bValid}>, <{bWhen}>, <aItem>, <oBmp>, <{bClrBlck}> ),<nPos> )

#xcommand @ <x>,<y> SAY [ <lExt: EXTENDED,EXT> ] [ <oSay> CAPTION ] <caption> ;
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
          [<oSay> := ] HStaticEx():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, ;
             <height>,<caption>,<oFont>,<bInit>,<bSize>,<bDraw>,<ctoolt>, ;
             <color>,<bcolor>,<.lTransp.>,<bClick>,<bDblClick>,<bOther> );;
          [; hwg_SetCtrlName( <oSay>,<(oSay)> )]

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
             [ ICON <hIco> ]            ;
             [ <lTransp: TRANSPARENT> ] ;
             [ <lnoTheme: NOTHEMES> ]   ;
             [[ON OTHER MESSAGES <bOther>][ON OTHERMESSAGES <bOther>]] ;
          => ;
          [<oBut> := ] HButtonEx():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, ;
             <height>,<caption>,<oFont>,<bInit>,<bSize>,<bDraw>,<bClick>,<ctoolt>,<color>,<bcolor>,<hbit>, ;
             <nBStyle>,<hIco>, <.lTransp.>,<bGfocus>,<nMargin>,<.lnoTheme.>, <bOther> );
          [; hwg_SetCtrlName( <oBut>,<(oBut)> )]

		  
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
            [ TOOLTIP <ctoolt> ]       ;
			  [ ON GETFOCUS <bGfocus> ]  ;
			  [ BITMAP <hbit> ]          ;
             [ BSTYLE <nBStyle> ]       ;                     
             [ PICTUREMARGIN <nMargin> ];
             [ ICON <hIco> ]            ;
             [ <lTransp: TRANSPARENT> ] ;
             [ <lnoTheme: NOTHEMES> ]   ;
             [[ON OTHER MESSAGES <bOther>][ON OTHERMESSAGES <bOther>]] ;
          => ;
    [<oBut> := ] HButtonEx():Redefine( <oWnd>,<nId>,<oFont>,<bInit>,<bSize>,<bDraw>, ;
                    <bClick>,<ctoolt>,<color>,<bcolor>,<cCaption>,<hbit>, ;
             <nBStyle>,<hIco>, <.lTransp.>,<bGfocus>,<nMargin>,<.lnoTheme.>, <bOther> ) ;
    [; hwg_SetCtrlName( <oBut>,<(oBut)> )]
		  
		  
		  

#xcommand @ <x>,<y> GRIDEX <oGrid>      ;
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
                             <.lNoLines.>, <color>, <bkcolor>, <.lNoHeader.> ,<aBit>,<a>)

#xcommand ADDROWEX TO GRID <oGrid>    ;
            [ HEADER <cHeader> ]        ;
            [ BITMAP <n> ]              ;
            [ COLOR <color> ]           ;
            [ BACKCOLOR <bkcolor> ]     ;
            [ HEADER <cHeadern> ]        ;
            [ BITMAP <nn> ]              ;
            [ COLOR <colorn> ]           ;
            [ BACKCOLOR <bkcolorn> ]     ;
            => <oGrid>:AddRow(\{<cHeader>,<n>,<color>,<bkcolor> [, <cHeadern>, <nn>,<colorn>,<bkcolorn> ]\})

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
          =>  ;
          [<oCnt> := ] HContainerEx():New(<oWnd>, <nId>,IIF(<.lTabStop.>,WS_TABSTOP,),;
               <x>, <y>, <width>, <height>, <ncStyle>, <bSize>, <.lnoBorder.>,<bInit>,<nbackStyle>,<tcolor>,<bcolor>,;
               <bLoad>,<bRefresh>,<bOther>);;
          [; hwg_SetCtrlName( <oCnt>,<(oCnt)> )]

#xcommand @ <x>,<y> GROUPBOX [ <lExt: EXTENDED,EXT> ] [ <oGroup> CAPTION ] <caption> ;
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
          [<oGroup> := ] HGroupEx():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, ;
             <height>,<caption>,<oFont>,<bInit>,<bSize>,<bDraw>,<color>,<bcolor>,<.lTransp.>);;
          [; hwg_SetCtrlName( <oGroup>,<(oGroup)> )]

#xcommand ADD STATUSEX [<oStat>] [ TO <oWnd> ] ;
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
          [ <oStat> := ] HStatusEx():New( <oWnd>,<nId>,<nStyle>,<oFont>,\{<aparts>\},<bInit>,;
             <bSize>,<bDraw>, <bRClick>, <bDblClick>, <nHeight> );;
          [; hwg_SetCtrlName( <oStat>,<(oStat)> )]

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
             [ CHECK <acheck> ]         ;
             [ IMAGES <aImages> ]       ;
          => ;
          [<oCombo> := ] HCheckComboBox():New( <oWnd>,<nId>,<vari>,    ;
             {|v|Iif(v==Nil,<vari>,<vari>:=v)},      ;
             <nStyle>,<x>,<y>,<width>,<height>,      ;
             <aItems>,<oFont>,,,,<bChange>,<ctoolt>, ;
             <.edit.>,<.text.>,<bWhen>,<color>,<bcolor>, ;
						 <bValid>,<acheck>,<nDisplay>,<nhItem>,<ncWidth>, <aImages> );;
          [; hwg_SetCtrlName( <oCombo>,<(oCombo)> )]
