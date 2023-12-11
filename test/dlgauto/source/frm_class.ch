#define CFG_FNAME     1  // frm_print       // field name
#define CFG_FTYPE     2                     // field type
#define CFG_FLEN      3                     // field len
#define CFG_FDEC      4                     // field decimals
#define CFG_ISKEY     5                     // if field is the key
#define CFG_FPICTURE  6                     // picture mask
#define CFG_CAPTION   7   // frm_print      // text description of field
#define CFG_VALID     8                     // validation
#define CFG_VTABLE    9                     // table to make seek
#define CFG_VFIELD    10                    // field of table to seek
#define CFG_VSHOW     11                    // field to show information
#define CFG_VALUE     12                    // app value for edit field
#define CFG_VLEN      13                    // app len of VSHOW
#define CFG_CTLTYPE   14                    // app current control type
#define CFG_FCONTROL  15                    // app control for input
#define CFG_CCONTROL  16                    // app control for caption
#define CFG_VCONTROL  17                    // app control for VSHOW
#define CFG_ACTION    18                    // app action for button

#define CFG_EMPTY { "", "C", 1, 0, .F., "", "", .T., "", "", "", Nil, 0, TYPE_EDIT, Nil, Nil, Nil, Nil }

#define TYPE_BUTTON   1
#define TYPE_EDIT     2
#define TYPE_TAB      3
#define TYPE_TABPAGE  4
#define TYPE_PANEL    5
#define TYPE_BROWSE   6

#ifdef HBMK_HAS_HWGUI
   #include "hwgui.ch"
#endif

#ifdef HBMK_HAS_HMG3
   #include "hmg.ch"
   #include "i_altsyntax.ch"
   //MEMVAR _HMG_SYSDATA
#endif

#ifdef HBMK_HAS_HMGE
   #include "hmg.ch"
   #include "i_altsyntax.ch"
#endif

#ifdef HBMK_HAS_OOHG
   #include "oohg.ch"
   #include "i_altsyntax.ch"
#endif

#ifdef HBMK_HAS_GTWVG
   #include "gtwvg.ch"
#endif

#ifndef WIN_RGB
   #ifdef HBMK_HAS_HWGUI
      #define WIN_RGB( r, g, b ) hwg_ColorRGB2N( r, g, b )
   #else
      #define WIN_RGB( r, g, b ) ( r * 256 ) + ( b * 16 ) + c
   #endif
#endif

#define COLOR_BLACK   WIN_RGB( 0, 0, 0 )
#define COLOR_WHITE   WIN_RGB( 255, 255, 255 )
#define COLOR_YELLOW  WIN_RGB( 255, 255, 0 )
#define COLOR_GREEN   12507070
#define DEFAULT_FONTNAME "MS Sans Serif"
#define PREVIEW_FONTNAME "Courier New"
