/*
 *$Id$
 */
#ifndef ___MISSING_H___
#define ___MISSING_H___

/*
   This file containts missing definitions/declarations in Digital Mars C++
   and/or OpenWatcom 1.7 (AJ:Nov-23-2007)
*/

#ifndef _WIN32_WINNT
   #define _WIN32_WINNT 0x0400
#endif

#if defined(__DMC__)

#define DWORD_PTR                    DWORD
#define LV_COLUMN                    LVCOLUMN

#define CDRF_DODEFAULT               0x00000000
#define CDRF_NEWFONT                 0x00000002
#define CDRF_NOTIFYPOSTPAINT         0x00000010
#define CDRF_NOTIFYITEMDRAW          0x00000020
#define CDRF_NOTIFYSUBITEMDRAW       0x00000020
#define CDRF_NOTIFYPOSTERASE         0x00000040
#define CDRF_SKIPDEFAULT             0x00000004

#define CDDS_PREPAINT                0x00000001
#define CDDS_POSTPAINT               0x00000002
#define CDDS_PREERASE                0x00000003
#define CDDS_POSTERASE               0x00000004
#define CDDS_ITEM                    0x00010000
#define CDDS_ITEMPREPAINT            (CDDS_ITEM | CDDS_PREPAINT)
#define CDDS_ITEMPOSTPAINT           (CDDS_ITEM | CDDS_POSTPAINT)
#define CDDS_ITEMPREERASE            (CDDS_ITEM | CDDS_PREERASE)
#define CDDS_ITEMPOSTERASE           (CDDS_ITEM | CDDS_POSTERASE)
#define CDDS_SUBITEM                 0x00020000

#define LVS_EX_GRIDLINES             0x00000001
#define LVS_EX_SUBITEMIMAGES         0x00000002
#define LVS_EX_CHECKBOXES            0x00000004
#define LVS_EX_TRACKSELECT           0x00000008
#define LVS_EX_HEADERDRAGDROP        0x00000010
#define LVS_EX_FULLROWSELECT         0x00000020
#define LVS_EX_ONECLICKACTIVATE      0x00000040
#define LVS_EX_TWOCLICKACTIVATE      0x00000080
#define LVS_EX_FLATSB                0x00000100
#define LVS_EX_REGIONAL              0x00000200
#define LVS_EX_INFOTIP               0x00000400
#define LVS_EX_UNDERLINEHOT          0x00000800
#define LVS_EX_UNDERLINECOLD         0x00001000
#define LVS_EX_MULTIWORKAREAS        0x00002000

#define LVCF_IMAGE                   0x0010

#define LVM_SUBITEMHITTEST           (LVM_FIRST + 57)
#define LVM_SETEXTENDEDLISTVIEWSTYLE (LVM_FIRST + 54)

#define CDIS_SELECTED                0x0001
#define CDIS_GRAYED                  0x0002
#define CDIS_DISABLED                0x0004
#define CDIS_CHECKED                 0x0008
#define CDIS_FOCUS                   0x0010
#define CDIS_DEFAULT                 0x0020
#define CDIS_HOT                     0x0040
#define CDIS_MARKED                  0x0080
#define CDIS_INDETERMINATE           0x0100

#define TME_LEAVE                    0x00000002

#define MCM_FIRST                    0x1000
#define MCM_GETMINREQRECT            (MCM_FIRST + 9)
#define MCM_GETCURSEL                (MCM_FIRST + 1)
#define MCM_SETCURSEL                (MCM_FIRST + 2)

#define ICC_DATE_CLASSES             0x00000100
#define ICC_INTERNET_CLASSES         0x00000800
#define ICC_BAR_CLASSES              0x00000004
#define ICC_LISTVIEW_CLASSES         0x00000001
#define ICC_TREEVIEW_CLASSES         0x00000002
#define ICC_TAB_CLASSES              0x00000008

#define DTM_FIRST                    0x1000
#define DTM_GETSYSTEMTIME            (DTM_FIRST + 1)
#define DTM_SETSYSTEMTIME            (DTM_FIRST + 2)

#define TV_FIRST                     0x1100

#define TVM_SETTEXTCOLOR             (TV_FIRST + 30)
#define TVM_SETBKCOLOR               (TV_FIRST + 29)

#define GetWindowLongPtr             GetWindowLong
#define SetWindowLongPtr             SetWindowLong

#define GDT_ERROR                    -1
#define GDT_VALID                    0
#define GDT_NONE                     1

#define TBSTYLE_FLAT                 0x0800
#define TBSTYLE_TRANSPARENT          0x8000

#define RBS_VARHEIGHT                0x0200

#define RBIM_IMAGELIST               0x00000001

#define RBBIM_STYLE                  0x00000001
#define RBBIM_COLORS                 0x00000002
#define RBBIM_TEXT                   0x00000004
#define RBBIM_IMAGE                  0x00000008
#define RBBIM_CHILD                  0x00000010
#define RBBIM_CHILDSIZE              0x00000020
#define RBBIM_SIZE                   0x00000040
#define RBBIM_BACKGROUND             0x00000080
#define RBBIM_ID                     0x00000100
#define RBBIM_IDEALSIZE              0x00000200
#define RBBIM_LPARAM                 0x00000400
#define RBBIM_HEADERSIZE             0x00000800

#define MONTHCAL_CLASS               "SysMonthCal32"
#define REBARCLASSNAME               "ReBarWindow32"
#define WC_PAGESCROLLER              "SysPager"
#define WC_IPADDRESS                 "SysIPAddress32"

#define RB_INSERTBAND                (WM_USER +   1)
#define RB_SETBARINFO                (WM_USER +   4)

#define TB_GETRECT                   (WM_USER +  51)
#define TB_GETHOTITEM                (WM_USER +  71)
#define TB_SETHOTITEM                (WM_USER +  72)
#define TB_MAPACCELERATOR            (WM_USER +  78)
#define TB_GETMAXSIZE                (WM_USER +  83)

#define IPM_SETADDRESS               (WM_USER + 101)
#define IPM_GETADDRESS               (WM_USER + 102)
#define IPM_CLEARADDRESS             (WM_USER + 100)

#define MAKEIPADDRESS(b1,b2,b3,b4)   ((LPARAM)(((DWORD)(b1)<<24)+((DWORD)(b2)<<16)+((DWORD)(b3)<<8)+((DWORD)(b4))))
#define FIRST_IPADDRESS(x)           ((x>>24) & 0xff)
#define SECOND_IPADDRESS(x)          ((x>>16) & 0xff)
#define THIRD_IPADDRESS(x)           ((x>>8) & 0xff)
#define FOURTH_IPADDRESS(x)          (x & 0xff)

#define PGF_CALCWIDTH                1
#define PGF_CALCHEIGHT               2
#define PGF_SCROLLUP                 1
#define PGF_SCROLLDOWN               2
#define PGF_SCROLLLEFT               4
#define PGF_SCROLLRIGHT              8

#define PGS_VERT                     0x00000000
#define PGS_HORZ                     0x00000001
#define PGS_AUTOSCROLL               0x00000002
#define PGS_DRAGNDROP                0x00000004

#define PGM_FIRST                    0x1400
#define PGM_SETCHILD                 (PGM_FIRST + 1)
#define PGM_RECALCSIZE               (PGM_FIRST + 2)
#define PGM_FORWARDMOUSE             (PGM_FIRST + 3)
#define PGM_SETBKCOLOR               (PGM_FIRST + 4)
#define PGM_GETBKCOLOR               (PGM_FIRST + 5)
#define PGM_SETBORDER                (PGM_FIRST + 6)
#define PGM_GETBORDER                (PGM_FIRST + 7)
#define PGM_SETPOS                   (PGM_FIRST + 8)
#define PGM_GETPOS                   (PGM_FIRST + 9)
#define PGM_SETBUTTONSIZE            (PGM_FIRST + 10)
#define PGM_GETBUTTONSIZE            (PGM_FIRST + 11)
#define PGM_GETBUTTONSTATE           (PGM_FIRST + 12)
#define PGM_GETDROPTARGET            CCM_GETDROPTARGET

#define MonthCal_GetMinReqRect(hmc, prc) \
   SNDMSG(hmc, MCM_GETMINREQRECT, 0, (LPARAM)(prc))

#define MonthCal_GetCurSel(hmc, pst) \
   (BOOL)SNDMSG(hmc, MCM_GETCURSEL, 0, (LPARAM)(pst))

#define MonthCal_SetCurSel(hmc, pst) \
   (BOOL)SNDMSG(hmc, MCM_SETCURSEL, 0, (LPARAM)(pst))

#define ListView_SubItemHitTest(hwnd, plvhti) \
   (int)SNDMSG((hwnd), LVM_SUBITEMHITTEST, 0, (LPARAM)(LPLVHITTESTINFO)(plvhti))

#define ListView_SetExtendedListViewStyle(hwndLV, dw)\
   (DWORD)SNDMSG((hwndLV), LVM_SETEXTENDEDLISTVIEWSTYLE, 0, dw)

typedef struct tagNMCUSTOMDRAWINFO
{
   NMHDR   hdr;
   DWORD   dwDrawStage;
   HDC   hdc;
   RECT   rc;
   DWORD   dwItemSpec;
   UINT   uItemState;
   LPARAM   lItemlParam;
}   NMCUSTOMDRAW, FAR * LPNMCUSTOMDRAW;

typedef struct tagLVHITTESTINFO
{
   POINT   pt;
   UINT   flags;
   int   iItem;
   int   iSubItem;
}   LVHITTESTINFO, FAR* LPLVHITTESTINFO;

typedef struct tagLVCOLUMN
{
   UINT   mask;
   int   fmt;
   int   cx;
   LPSTR   pszText;
   int   cchTextMax;
   int   iSubItem;
   int   iImage;
   int   iOrder;
}   LVCOLUMN, FAR* LPLVCOLUMN;

typedef struct tagLVITEM
{
   UINT   mask;
   int   iItem;
   int   iSubItem;
   UINT   state;
   UINT   stateMask;
   LPSTR   pszText;
   int   cchTextMax;
   int   iImage;
   LPARAM   lParam;
   int   iIndent;
}   LVITEM, FAR* LPLVITEM;

typedef struct tagNMLVCUSTOMDRAW
{
   NMCUSTOMDRAW   nmcd;
   COLORREF   clrText;
   COLORREF   clrTextBk;
   int      iSubItem;
}   NMLVCUSTOMDRAW, *LPNMLVCUSTOMDRAW;

typedef struct tagNMLISTVIEW
{
   NMHDR   hdr;
   int     iItem;
   int     iSubItem;
   UINT    uNewState;
   UINT    uOldState;
   UINT    uChanged;
   POINT   ptAction;
   LPARAM  lParam;
}   NMLISTVIEW, FAR *LPNMLISTVIEW;

typedef struct tagNMTTCUSTOMDRAW
{
    NMCUSTOMDRAW   nmcd;
    UINT      uDrawFlags;
}   NMTTCUSTOMDRAW, FAR * LPNMTTCUSTOMDRAW;

typedef struct tagINITCOMMONCONTROLSEX {
   DWORD dwSize;
   DWORD dwICC;
}   INITCOMMONCONTROLSEX, *LPINITCOMMONCONTROLSEX;

typedef struct tagPAINTSTRUCT {
    HDC         hdc;
    BOOL        fErase;
    RECT        rcPaint;
    BOOL        fRestore;
    BOOL        fIncUpdate;
    BYTE        rgbReserved[32];
} PAINTSTRUCT, *PPAINTSTRUCT, *NPPAINTSTRUCT, *LPPAINTSTRUCT;

#ifdef __cplusplus
   extern "C" {
#endif

WINCOMMCTRLAPI
BOOL
WINAPI
_TrackMouseEvent(LPTRACKMOUSEEVENT lpEventTrack);

WINCOMMCTRLAPI
BOOL
WINAPI
InitCommonControlsEx(LPINITCOMMONCONTROLSEX);

#ifdef __cplusplus
   }
#endif

typedef struct tagNMTBGETINFOTIP
{
   NMHDR   hdr;
   LPSTR   pszText;
   int   cchTextMax;
   int   iItem;
   LPARAM   lParam;
}   NMTBGETINFOTIP, *LPNMTBGETINFOTIP;

typedef struct tagNMTOOLBAR {
   NMHDR      hdr;
   int      iItem;
   TBBUTTON   tbButton;
   int      cchText;
   LPSTR      pszText;
#if (_WIN32_IE >= 0x500)
   RECT      rcButton;
#endif
}   NMTOOLBAR, FAR* LPNMTOOLBAR;

typedef struct tagREBARINFO
{
   UINT        cbSize;
   UINT        fMask;
#ifndef NOIMAGEAPIS
   HIMAGELIST  himl;
#else
   HANDLE      himl;
#endif
}   REBARINFO, FAR *LPREBARINFO;

typedef struct tagREBARBANDINFO
{
   UINT      cbSize;
   UINT      fMask;
   UINT      fStyle;
   COLORREF   clrFore;
   COLORREF   clrBack;
   LPSTR      lpText;
   UINT      cch;
   int      iImage;
   HWND      hwndChild;
   UINT      cxMinChild;
   UINT      cyMinChild;
   UINT      cx;
   HBITMAP      hbmBack;
   UINT      wID;
#if(_WIN32_IE >= 0x0400)
   UINT      cyChild;
   UINT      cyMaxChild;
   UINT      cyIntegral;
   UINT      cxIdeal;
   LPARAM      lParam;
   UINT      cxHeader;
#endif
}   REBARBANDINFO, FAR *LPREBARBANDINFO;


typedef struct {
   NMHDR   hdr;
   DWORD   dwFlag;
   int     iWidth;
   int     iHeight;
}   NMPGCALCSIZE, *LPNMPGCALCSIZE;

typedef struct {
   NMHDR   hdr;
   WORD   fwKeys;
   RECT   rcParent;
   int   iDir;
   int   iXpos;
   int   iYpos;
   int   iScroll;
}   NMPGSCROLL, *LPNMPGSCROLL;


#endif /* __DMC__ */

#endif /* ___MISSING_H___ */
