#ifndef _SSAY_CH
#define _SSAY_CH

/*----------------------------------------------------------------------------//
!short: SENSITIVE SAY  */

#xcommand REDEFINE SENSITIVE SAY [<oSSay>] ;
             [ <label: PROMPT, VAR> <cText> ] ;
             [ PICTURE <cPict> ] ;
             [ ID <nId> ] ;
             [ <dlg: OF,WINDOW,DIALOG > <oWnd> ] ;
             [ ACTION <uAction,...> ] ;
             [ <lCenter: CENTERED, CENTER > ] ;
             [ <lRight:  RIGHT > ] ;
             [ <lBottom: BOTTOM > ];
             [ <color: COLOR,COLORS > <nClrText> [,<nClrBack> ] ] ;
             [ COLOROVER <nClrOver> ] ;
             [ <update: UPDATE > ] ;
             [ FONT <oFont> ] ;
             [ CURSOR <oCursor> ] ;
             [ <lShaded: SHADED, SHADOW > ] ;
             [ <lBox:    BOX > ] ;
             [ <lRaised: RAISED > ] ;
             [ <lTransparent: TRANSPARENT > ] ;
             [ ON MOUSEOVER <uMOver> ] ; 
       => ;
          [ <oSSay> := ] TSSay():ReDefine( <nId>, <{cText}>, <oWnd>, <cPict>, ;
             [\{|Self|<uAction>\}], <.lCenter.>, <.lRight.>, <.lBottom.>, ;
             <nClrText>, <nClrBack>, <nClrOver>, <.update.>, <oFont>, <oCursor>, ;
             <.lShaded.>, <.lBox.>, <.lRaised.>, <.lTransparent.>, [{||<uMOver>}] )

#xcommand @ <nRow>, <nCol> SENSITIVE SAY [ <oSSay> <label: PROMPT,VAR > ] <cText> ;
             [ PICTURE <cPict> ] ;
             [ <dlg: OF,WINDOW,DIALOG > <oWnd> ] ;
             [ FONT <oFont> ]  ;
             [ CURSOR <oCursor> ] ;
             [ <lCenter: CENTERED, CENTER > ] ;
             [ <lRight:  RIGHT > ] ;
             [ <lBottom: BOTTOM > ];
             [ <lBorder: BORDER > ] ;
             [ <lPixel: PIXEL, PIXELS > ] ;
             [ <color: COLOR,COLORS > <nClrText> [,<nClrBack> ] ] ;
             [ COLOROVER <nClrOver> ] ;
             [ SIZE <nWidth>, <nHeight> ] ;
             [ ACTION <uAction,...> ] ;
             [ <design: DESIGN > ] ;
             [ <update: UPDATE > ] ;
             [ <lShaded: SHADED, SHADOW > ] ;
             [ <lBox: BOX > ] ;
             [ <lRaised: RAISED > ] ;
             [ <lTransparent: TRANSPARENT > ] ;
             [ ON MOUSEOVER <uMOver> ] ; 
      => ;
          [ <oSSay> := ] TSSay():New( <nRow>, <nCol>, <{cText}>,;
             [<oWnd>], [<cPict>], <oFont>, <oCursor>, ;
             [\{|Self|<uAction>\}], <.lCenter.>, <.lRight.>, <.lBottom.>, <.lBorder.>,;
             <.lPixel.>, <nClrText>, <nClrBack>, <nClrOver>, <nWidth>, <nHeight>,;
             <.design.>, <.update.>, <.lShaded.>, <.lBox.>, <.lRaised.>,;
             <.lTransparent.>, [{||<uMOver>}] )
