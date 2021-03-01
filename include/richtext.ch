/*
 * $Id$
 *
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³        Class: RichText                                                   ³
³  Description: System for generating simple RTF files.                    ³
³     Language: Clipper/Fivewin                                            ³
³      Version: 0.90 -- This is a usable, but incomplete, version that is  ³
³               being distributed in case anyone cares to use it as-is,    ³
³               or wants to comment on it.                                 ³
³         Date: 01/28/97                                                   ³
³       Author: Tom Marchione                                              ³
³     Internet: 73313,3626@compuserve.com                                  ³
³                                                                          ³
³    Copyright: (C) 1997, Thomas R. Marchione                              ³
³       Rights: Use/modify freely for applicaton work, under the condition ³
³               that you include the original author's credits (i.e., this ³
³               header), and you do not offer the source code for sale.    ³
³               The author may or may not supply updates and revisions     ³
³               to this code as "freeware".                                ³
³                                                                          ³
³   Warranties: None. The code has not been rigorously tested in a formal  ³
³               development environment, and is offered as-is.  The author ³
³               assumes no responsibility for its use.                     ³
³                                                                          ³
³    Revisions:                                                            ³
³                                                                          ³
³    DATE       AUTHOR  COMMENTS                                           ³
³ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ³
³    01/28/97   TRM     Date of initial release                            ³
³                                                                          ³
³                                                                          ³
³                                                                          ³
³                                                                          ³
³                                                                          ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/

#ifndef __RICHTEXT_CH__
#define __RICHTEXT_CH__

#define INCH_TO_TWIP 1440

// Text Styles
// These are special cases, defined with the RTF backslash, so that
// they can be easily concatenated at the application level.

#define BOLD_ON       "\b"
#define ITALIC_ON     "\i"
#define UNDERLINE_ON  "\ul"
#define OUTLINE_ON    "\outl"
#define CAPS_ON       "\caps"
#define SCAPS_ON      "\scaps"
#define SUBS_ON       "\sub"
#define SUPER_ON      "\super"
#define SHADOW_ON     "\shad"
#define STRIKE_ON     "\strike"
#define HIDDEN_ON     "\v"

#define STYLE_OFF     "0"
#define BOLD_OFF      BOLD_ON + STYLE_OFF
#define ITALIC_OFF    ITALIC_ON + STYLE_OFF
#define UNDERLINE_OFF UNDERLINE_ON + STYLE_OFF
#define OUTLINE_OFF   OUTLINE_ON + STYLE_OFF
#define CAPS_OFF      CAPS_ON + STYLE_OFF
#define SCAPS_OFF     SCAPS_ON + STYLE_OFF
#define SUBS_OFF      "\nosupersub"
#define SHADOW_OFF    SHADOW_ON + STYLE_OFF
#define STRIKE_OFF    STRIKE_ON + STYLE_OFF
#define HIDDEN_OFF    HIDDEN_ON + STYLE_OFF


// DEFAULTS:

// Font:        Courier New
// Font Size:   12 Point
// Units:       Inches (i.e., same as "TWIPFACTOR INCH_TO_TWIP")
// Page Setup:  Standard RTF file format defaults


#xcommand DEFINE RTF [<oRTF>] ;
      [ <filename: FILE, FILENAME> <cFileName> ] ;
      [ <fontname: FONTS, FONTNAMES> <aFontData,...> ] ;
      [ <fontfami: FONTFAMILY> <aFontFam,...> ] ;
      [ <fontchar: CHARSET> <aFontChar,...> ] ;
      [ FONTSIZE <nFontSize> ] ;
      [ FONTCOLOR <nFontColor> ] ;
      [ TWIPFACTOR <nScale> ] ;
      [ HIGHORDERMAP <aHigh> ] ;
   => ;
      [ <oRTF> := ] RichText():New( <cFileName>, [\{<aFontData>\}], ;
               [\{<aFontFam>\}],[\{<aFontChar>\}],<nFontSize>,<nFontColor>, <nScale>, <aHigh> )

#xcommand CLOSE RTF <oRTF> => <oRTF>:End()


// If used, DEFINE PAGESETUP should come immediately after DEFINE RTF
// NOTE: Page numbering is not supported yet in base class

#xcommand DEFINE PAGESETUP <oRTF> ;
      [ MARGINS <nLeft>, <nRight>, <nTop>, <nBottom> ] ;
      [ PAGEWIDTH <nWidth> ] ;
      [ PAGEHEIGHT <nHeight> ] ;
      [ TABWIDTH <nTabWidth> ] ;
      [ <landscape: LANDSCAPE> ] ;
      [ <lNoWidow: NOWIDOW> ] ;
      [ ALIGN <vertalign: TOP, BOTTOM, CENTER, JUSTIFY> ] ;
      [ PAGENUMBERS <cPgnumPos: LEFT, RIGHT, CENTER> ] ; // not supported
      [ <lPgnumTop: PAGENUMBERTOP> ] ; // not supported
   => ;
      <oRTF>:PageSetup( <nLeft>, <nRight>, <nTop>, <nBottom>, ;
             <nWidth>, <nHeight>, <nTabWidth>, <.landscape.>, <.lNoWidow.>, ;
             <"vertalign"> , <cPgnumPos>, <.lPgnumTop.> )


// Use these to enclose data to be included in headers & footers
#xcommand BEGIN HEADER <oRTF> => <oRTF>:BeginHeader()
#xcommand END HEADER <oRTF> => <oRTF>:EndHeader()

#xcommand BEGIN FOOTER <oRTF> => <oRTF>:BeginFooter()
#xcommand END FOOTER <oRTF> => <oRTF>:EndFooter()


// Use this to write formatted text within a paragraph
#xcommand WRITE TEXT <oRTF> ;
      [ TEXT <cText> ] ;
      [ FONTNUMBER <nFontNumber> ] ;
      [ FONTSIZE <nFontSize> ] ;
      [ APPEARANCE <cAppear> ] ;
      [ <lDefault: SETDEFAULT > ] ;
      [ FONTCOLOR <nFontColor> ] ;
      [ BORDER <cTypeBorder,...>] ;
      [ SHADED <nShdPct>] ;
                [ STYLE <nStyle > ] ;
   => ;
      <oRTF>:Paragraph( <cText>, <nFontNumber>, <nFontSize>, <cAppear>, ;
            ,,,,,,,,,,,,,, <.lDefault.>, .T. ,<nFontColor>,;
            [\{<cTypeBorder>\}],,, <nShdPct>,,<nStyle>,.T.)

// Use this to write an entire paragraph, with optional formatting.
#xcommand NEW PARAGRAPH <oRTF> ;
      [ TEXT <cText> ] ;
      [ FONTNUMBER <nFontNumber> ] ;
      [ FONTSIZE <nFontSize> ] ;
      [ APPEARANCE <cAppear> ] ;
      [ ALIGN <cHorzAlign: LEFT, RIGHT, CENTER, JUSTIFY> ] ;
      [ TABSTOPS <aTabPos,...> ] ;
      [ <indent: INDENT, LEFTINDENT> <nIndent> ] ;
      [ FIRSTINDENT <nFIndent> ] ;
      [ RIGHTINDENT <nRIndent> ] ;
      [ LINESPACE <nSpace> [ <lSpExact: ABSOLUTE>] ] ;
      [ SPACEBEFORE <nBefore> ] ;
      [ SPACEAFTER <nAfter> ] ;
      [ <lNoWidow: NOWIDOW> ] ;
      [ <lBreak: NEWPAGE > ] ;
      [ <lBullet: BULLET, BULLETED > [ BULLETCHAR <cBulletChar> ];
         [ HANGING <lHang> ] ] ;
      [ <lDefault: SETDEFAULT > ] ;
      [ <lNoPar: NORETURN> ] ;
      [ FONTCOLOR <nFontColor> ] ;
      [ BORDER <cTypeBorder,...> ;
         [ BORDSTYLE <cBordStyle: SINGLE, DOUBLETHICK, SHADOW, DOUBLE, ;
         DOTTED, DASHED, HAIRLINE,NONE> ] ;
                        [ BORDCOLOR <nBordCol> ] ];
      [ SHADE  <nShdPct> ;
                        [ SHADPAT <cShadPat:HORIZ,VERT,FORDIAG,BACKDIAG,CROSS> ] ];
                [ STYLE <nStyle> ];
   => ;
      <oRTF>:Paragraph( <cText>, <nFontNumber>, <nFontSize>, <cAppear>, ;
            <"cHorzAlign">, [\{<aTabPos>\}], <nIndent>, ;
            <nFIndent>, <nRIndent>, <nSpace>, <.lSpExact.>, ;
            <nBefore>, <nAfter> , <.lNoWidow.>, <.lBreak.>, ;
            <.lBullet.>, <cBulletChar>, <.lHang.>, <.lDefault.>, <.lNoPar.>,;
            <nFontColor>, [\{<cTypeBorder>\}],;
            <"cBordStyle">, <nBordCol>, <nShdPct>,<"cShadPat">,;
            <nStyle>,.F. )


// Use this to begin a new table
#xcommand DEFINE TABLE <oRTF> ;
      [ ALIGN <cHorzAlign: LEFT, RIGHT, CENTER> ] ;
      [ FONTNUMBER <nFontNumber> ] ;
      [ FONTSIZE <nFontSize> ] ;
      [ CELLAPPEAR <cCellAppear> ] ;
      [ CELLHALIGN <cCellHAlign: LEFT, RIGHT, CENTER> ] ;
      [ ROWS <nRows> ] ;
      [ COLUMNS <nColumns> ] ;
      [ CELLWIDTHS <aColWidths,...> ] ;
      [ ROWHEIGHT <nHeight> ] ;
      [ ROWBORDERS <cRowBorder: SINGLE, DOUBLETHICK, SHADOW, DOUBLE, ;
         DOTTED, DASHED, HAIRLINE > ] ;
      [ CELLBORDERS <cCellBorder: SINGLE, DOUBLETHICK, SHADOW, DOUBLE, ;
         DOTTED, DASHED, HAIRLINE,NONE> ] ;
      [ COLSHADE <aColPct,...> ] ;
      [ CELLSHADE <nCellPct> ] ;
      [ <lNoSplit: NOSPLIT> ] ;
      [ HEADERROWS <nHeadRows> ;
         [ HEADERHEIGHT <nHeadHgt> ] ;
         [ HEADERSHADE <nHeadPct> ] ;
         [ HEADERFONT <nHeadFont> ] ;
         [ HEADERFONTSIZE <nHFontSize> ] ;
         [ HEADERAPPEAR <cHeadAppear> ] ;
         [ HEADERHALIGN <cHeadHAlign: LEFT, RIGHT, CENTER> ] ;
         [ HEADERCOLOR  <nTblHdColor> ] ;
         [ HEADERFONTCOLOR <nTblHdFColor> ] ;
      ] ;
   => ;
      <oRTF>:DefineTable( <"cHorzAlign">, <nFontNumber>, <nFontSize>, ;
            <cCellAppear>, <"cCellHAlign">, <nRows>, ;
            <nColumns>, <nHeight>, [\{<aColWidths>\}], <"cRowBorder">, ;
            <"cCellBorder">, <aColPct>, <nCellPct>,<.lNoSplit.>, <nHeadRows>, ;
            <nHeadHgt>, <nHeadPct>, <nHeadFont>, <nHFontSize>, ;
            <cHeadAppear>, <"cHeadHAlign">,<nTblHdColor>,<nTblHdFColor>)

// Use this to begin a new table
#xcommand DEFINE NEWTABLE <oRTF> ;
      [ ALIGN <cHorzAlign: LEFT, RIGHT, CENTER> ] ;
      [ FONTNUMBER <nFontNumber> ] ;
      [ FONTSIZE <nFontSize> ] ;
      [ CELLAPPEAR <cCellAppear> ] ;
      [ CELLHALIGN <cCellHAlign: LEFT, RIGHT, CENTER> ] ;
      [ ROWS <nRows> ] ;
      [ COLUMNS <nColumns> ] ;
      [ CELLWIDTHS <aColWidths,...> ] ;
      [ ROWHEIGHT <nHeight> ] ;
      [ ROWBORDERS <cRowBorder: SINGLE, DOUBLETHICK, SHADOW, DOUBLE, ;
         DOTTED, DASHED, HAIRLINE > ] ;
      [ CELLBORDERS <cCellBorder: SINGLE, DOUBLETHICK, SHADOW, DOUBLE, ;
         DOTTED, DASHED, HAIRLINE,NONE> ] ;
      [ COLSHADE <aColPct,...> ] ;
      [ CELLSHADE <nCellPct> ] ;
      [ <lNoSplit: NOSPLIT> ] ;
      [ HEADERROWS <nHeadRows> ;
                        [ HEADER <aTitles,...> ] ;
         [ HEADERHEIGHT <nHeadHgt> ] ;
         [ HEADERSHADE <nHeadPct> ] ;
         [ HEADERFONT <nHeadFont> ] ;
         [ HEADERFONTSIZE <nHFontSize> ] ;
         [ HEADERAPPEAR <cHeadAppear> ] ;
         [ HEADERHALIGN <cHeadHAlign: LEFT, RIGHT, CENTER> ] ;
         [ HEADERCOLOR  <nTblHdColor> ] ;
         [ HEADERFONTCOLOR <nTblHdFColor> ] ;
                        [ HEADERJOIN <aColJoin,...>] ;
      ] ;
   => ;
      <oRTF>:DefNewTable( <"cHorzAlign">, <nFontNumber>, <nFontSize>, ;
            <cCellAppear>, <"cCellHAlign">, <nRows>, ;
                <nColumns>, <nHeight>, {<aColWidths>}, <"cRowBorder">, ;
            <"cCellBorder">, <aColPct>, <nCellPct>,<.lNoSplit.>, <nHeadRows>, ;
                {<aTitles>},<nHeadHgt>, <nHeadPct>, <nHeadFont>, <nHFontSize>, ;
            <cHeadAppear>, <"cHeadHAlign">,<nTblHdColor>,<nTblHdFColor>,;
                {<aColJoin>} )

#xcommand CLOSE TABLE oRTF => oRTF:EndRow() ; oRTF:TextCode("pard")
#xcommand END TABLE oRTF => oRTF:EndTable() ; oRTF:TextCode("pard")


// Use this to begin/end a row of the table
// NOTE: After the first row, the class will automatically
// start new rows as necessary, based on # of columns

#xcommand BEGIN ROW oRTF => oRTF:BeginRow()
#xcommand END ROW oRTF => oRTF:EndRow()


// Use this to write the next cell in a table
#xcommand WRITE CELL <oRTF> ;
      [ TEXT <cText> ] ;
      [ FONTNUMBER <nFontNumber> ] ;
      [ FONTSIZE <nFontSize> ] ;
      [ APPEARANCE <cAppear> ] ;
      [ ALIGN <cHorzAlign: LEFT, RIGHT, CENTER, JUSTIFY> ] ;
      [ LINESPACE <nSpace> [ <lSpExact: ABSOLUTE>] ] ;
      [ CELLBORDERS <cCellBorder: SINGLE, DOUBLETHICK, SHADOW, DOUBLE, ;
         DOTTED, DASHED, HAIRLINE > ] ;
      [ CELLSHADE <nCellPct> ] ;
      [ FONTCOLOR <nFontColor> ] ;
      [ <lDefault: SETDEFAULT > ] ;
   => ;
      <oRTF>:WriteCell( <cText>, <nFontNumber>, <nFontSize>, <cAppear>, ;
            <"cHorzAlign">, <nSpace>, <lSpExact>, <"cCellBorder">, ;
            <nCellPct>, <nFontColor>, <.lDefault.> )


#xcommand WRITE NEWCELL <oRTF> ;
      [ TEXT <cText> ] ;
      [ FONTNUMBER <nFontNumber> ] ;
      [ FONTSIZE <nFontSize> ] ;
      [ APPEARANCE <cAppear> ] ;
      [ ALIGN <cHorzAlign: LEFT, RIGHT, CENTER, JUSTIFY> ] ;
      [ LINESPACE <nSpace> [ <lSpExact: ABSOLUTE>] ] ;
      [ FONTCOLOR <nFontColor> ] ;
      [ <lDefault: SETDEFAULT > ] ;
   => ;
      <oRTF>:TableCell( <cText>, <nFontNumber>, <nFontSize>, <cAppear>, ;
            <"cHorzAlign">, <nSpace>, <lSpExact>, ;
             <nFontColor>, <.lDefault.> )


#xcommand DEFINE CELL FORMAT <oRTF> ;
      [ CELLBORDERS <cCellBorder: SINGLE, DOUBLETHICK, SHADOW, DOUBLE, ;
         DOTTED, DASHED, HAIRLINE > ] ;
      [ CELLSHADE <aCellPct> ] ;
   => ;
      <oRTF>:CellFormat(<"cCellBorder">,<aCellPct> )


// Use this to begin a new section -- for example, to change the page
// orientation, or the paper size, or the number of columns.

#xcommand NEW SECTION oRTF ;
      [ <landscape: LANDSCAPE> ] ;
      [ COLUMNS <nColumns> ] ;
      [ MARGINS <nLeft>, <nRight>, <nTop>, <nBottom> ] ;
      [ PAGEWIDTH <nWidth> ] ;
      [ PAGEHEIGHT <nHeight> ] ;
      [ ALIGN <vertalign: TOP, BOTTOM, CENTER, JUSTIFY> ] ;
      [ <lDefault: SETDEFAULT > ] ;
   => ;
      oRTF:NewSection( <.landscape.>, <nColumns>, ;
            <nLeft>, <nRight>, <nTop>, <nBottom>, ;
            <nWidth>, <nHeight>, <"vertalign">, <.lDefault.> )


#xcommand BEGIN BOOKMARK <oRTF> ;
      [ TEXT <cText> ] ;
   => ;
      <oRTF>:BegBookMark( <cText> )

#xcommand END BOOKMARK <oRTF> => <oRTF>:EndBookMark()


// Use this to write the next cell in a table
#xcommand LINEA <oRTF> ;
      [ INICIO <aInicio> ] ;
      [ FIN <aFinal> ] ;
      [ XOFFSET <nxoffset> ] ;
      [ YOFFSET <nyoffset> ] ;
      [ SIZE <aSize> ] ;
      [ TIPO <cTipo> ] ;
      [ COLORS <aColores,...> ] ;
      [ WIDTH <nWidth> ] ;
                [ PATTERN <nPatron> ];
                [ <lSombra:SOMBRA> ];
                [ OFFSOMBRA < aSombra > ];
   => ;
      <oRTF>:Linea( <aInicio>, <aFinal>, ;
            <nxoffset>, <nyoffset>, <aSize>, <cTipo>, ;
            [\{<aColores>\}],<nWidth>, ;
            <nPatron>,<.lSombra.>,<aSombra> )
#xcommand INFO <oRTF> ;
      [ TITLE <cTitle> ] ;
      [ SUBJECT <cSubject> ] ;
      [ AUTHOR <cAuthor> ] ;
      [ MANAGER <cManager> ] ;
      [ COMPANY <cCompany> ] ;
      [ OPERATOR <cOperator> ] ;
      [ CATEGORY <cCategor> ] ;
      [ KEYWORDS <cKeyWords> ] ;
                [ COMMENT <cComment> ];
   => ;
      <oRTF>:InfoDoc( <cTitle>, <cSubject>, ;
            <cAuthor>, <cManager>, <cCompany>, <cOperator>, ;
            <cCategor>,<cKeyWords>,<cComment> )
#xcommand FOOTNOTE <oRTF> ;
      [ TEXT <cText> ] ;
      [ CHARACTER <cChar> ] ;
      [ FONTNUMBER <nFontNumber> ] ;
      [ FONTSIZE <nFontSize> ] ;
      [ APPEARANCE <cAppear> ] ;
      [ FONTCOLOR <nFontColor> ] ;
      [ <lEnd: ENDNOTE> ] ;
      [ <lAuto: AUTO> ] ;
      [ <lUpper: UPPER> ] ;
   => ;
      <oRTF>:FootNote( <cText>, <cChar>,<nFontNumber>,;
            <nFontSize>,<cAppear>,<nFontColor>,;
            <.lEnd.>,<.lAuto.>,<.lUpper.> )
#xcommand BEGIN TEXTBOX <oRTF> ;
      [ TEXT <cText> ] ;
      [ OFFSET <aOffset> ] ;
                [ SIZE <aSize> ] ;
      [ TIPO <cTipo> ] ;
         [ COLORS <aColores,...> ] ;
         [ WIDTH <nWidth> ] ;
                   [ PATTERN <nPatron> ];
                   [ <lSombra:SOMBRA> ];
                   [ OFFSOMBRA < aSombra > ];
               [ FONTNUMBER <nFontNumber> ] ;
         [ FONTSIZE <nFontSize> ] ;
         [ APPEARANCE <cAppear> ] ;
         [ FONTCOLOR <nFontColor> ] ;
         [ INDENT <nIndent> ] ;
                [ <lRounded: ROUNDED> ];
           [ <lEnd: ENDBOX> ] ;
   => ;
      <oRTF>:BegTextBox( <cText>,<aOffset>, <aSize>, <cTipo>, ;
            [\{<aColores>\}],<nWidth>,<nPatron>,<.lSombra.>,<aSombra>,;
            <nFontNumber>,<nFontSize>,<cAppear>,<nFontColor>,<nIndent>,;
            <.lRounded.>,<.lEnd.> )

#xcommand END TEXTBOX <oRTF> => <oRTF>:EndTextBox()

#xcommand IMAGELINK <oRTF> ;
      [ NAME <cName> ] ;
      [ SIZE <aSize> ] ;
      [ ALIGN <cHorzAlign: LEFT, RIGHT, CENTER> ] ;
      [ <lFrame: FRAME> ] ;
                [ <lCell: TABLECELL>];
   => ;
      <oRTF>:IncImage( <cName>, <aSize>,<"cHorzAlign">,;
            <.lFrame.>,<.lCell.> )

#xcommand BEGIN ESTILOS <oRTF> => <oRTF>:BeginStly()

#xcommand DEFINE ESTILO <oRTF> ;
      [ NAME <cName> ] ;
      [ TYPE <styletype: CHARACTER, PARAGRAPH, SECTION> ] ;
      [ FONTNUMBER <nFontNumber> ] ;
      [ FONTSIZE <nFontSize> ] ;
      [ FONTCOLOR <nFontColor> ] ;
      [ APPEARANCE <cAppear> ] ;
      [ ALIGN <cHorzAlign: LEFT, RIGHT, CENTER, JUSTIFY> ] ;
      [ <indent: INDENT, LEFTINDENT> <nIndent> ] ;
      [ KEYCODE <cKeys > ] ;
      [ BORDER <cTypeBorder,...> ;
         [ BORDSTYLE <cBordStyle: SINGLE, DOUBLETHICK, SHADOW, DOUBLE, ;
         DOTTED, DASHED, HAIRLINE,NONE> ] ;
                        [ BORDCOLOR <nBordColor> ] ];
      [ SHADE  <nShdPct> ;
                        [ SHADPAT <cShadPat:HORIZ,VERT,FORDIAG,BACKDIAG,CROSS> ] ];
      [ <lAdd: ADDITIVE> ] ;
      [ <lUpdate: LUPDATE> ] ;
   => ;
      <oRTF>:IncStyle( <cName>, <"styletype">,<nFontNumber>,<nFontSize>,;
            <nFontColor>,<cAppear>,<"cHorzAlign">,;
            <nIndent>,<cKeys>,[\{<cTypeBorder>\}],<"cBordStyle">,;
            <nBordColor>,<nShdPct>,<"cShadPat">,<.lAdd.>,<.lUpdate.>)

#xcommand END ESTILOS <oRTF> => <oRTF>:WriteStly()

#xcommand DOCUMENT FORMAT <oRTF> ;
      [ TAB <nTab> ] ;
      [ LINE <nLineStart>] ;
      [ <lBackUp: BACKUP> ] ;
      [ DEFLANG <nDefLang> ] ;
      [ DOCTYPE <nDocType> ] ;
      [ FOOTTYPE <cFootType:FOOTNOTES, ENDNOTES,BOTH > ;
         [ FOOTNOTES <cFootNotes: SECTION, DOCUMENT > ] ;
                   [ ENDNOTES  <cEndNotes: SECTION,DOCUMENT> ];
                   [ FOOTNUMBER <cFootNumber: SIMBOL,ARABIC,ALPHA,ROMAN> ]   ] ;
      [ PAGESTART <nPage> ] ;
      [ PROTECT <cProtect: NONE,REVISIONS,COMMENTS> ] ;
                [ <lFacing :FACING >;
                        [ GUTTER <nGutter> ] ];
   => ;
      <oRTF>:DocFormat( <nTab>,<nLineStart>,<.lBackUp.>,<nDefLang>,;
         <nDocType>,<"cFootType">,<"cFootNotes">,;
         <"cEndNotes">,<"cFootNumber">,<nPage>,<"cProtect">,;
         <.lFacing.>,<nGutter>)

#xcommand SETPAGE <oRTF> => <oRTF>:NumPage()

#xcommand SETDATE <oRTF> ;
      [ FORMAT <cFormat: LONGFORMAT,SHORTFORMAT,HEADER> ] ;
   => ;
      <oRTF>:CurrDate(<"cFormat">)

#endif /* __RICHTEXT_CH__ */
