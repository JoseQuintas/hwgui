#define	WND_MAIN		1
#define	WND_MDI 		2
#define  WND_MDICHILD      3
#define  WND_CHILD      4
#define	WND_DLG_RESOURCE       10
#define	WND_DLG_NORESOURCE     11

#define	OBTN_INIT               0
#define	OBTN_NORMAL             1
#define	OBTN_MOUSOVER           2
#define	OBTN_PRESSED            3

#define	BRW_ARRAY               1
#define	BRW_DATABASE            2


/* By Vitor McLung */
/*
 * Listbox Styles
 */
#define LBS_NOTIFY            0x0001
#define LBS_SORT              0x0002
#define LBS_NOREDRAW          0x0004
#define LBS_MULTIPLESEL       0x0008
#define LBS_OWNERDRAWFIXED    0x0010
#define LBS_OWNERDRAWVARIABLE 0x0020
#define LBS_HASSTRINGS        0x0040
#define LBS_USETABSTOPS       0x0080
#define LBS_NOINTEGRALHEIGHT  0x0100
#define LBS_MULTICOLUMN       0x0200
#define LBS_WANTKEYBOARDINPUT 0x0400
#define LBS_EXTENDEDSEL       0x0800
#define LBS_DISABLENOSCROLL   0x1000
#define LBS_NODATA            0x2000
#define LBS_NOSEL             0x4000
#define LBS_STANDARD          (LBS_NOTIFY+LBS_SORT+WS_VSCROLL+WS_BORDER)


/*
 * Listbox messages
 */
#define LB_ADDSTRING            0x0180
#define LB_INSERTSTRING         0x0181
#define LB_DELETESTRING         0x0182
#define LB_SELITEMRANGEEX       0x0183
#define LB_RESETCONTENT         0x0184
#define LB_SETSEL               0x0185
#define LB_SETCURSEL            0x0186
#define LB_GETSEL               0x0187
#define LB_GETCURSEL            0x0188
#define LB_GETTEXT              0x0189
#define LB_GETTEXTLEN           0x018A
#define LB_GETCOUNT             0x018B
#define LB_SELECTSTRING         0x018C
#define LB_DIR                  0x018D
#define LB_GETTOPINDEX          0x018E
#define LB_FINDSTRING           0x018F
#define LB_GETSELCOUNT          0x0190
#define LB_GETSELITEMS          0x0191
#define LB_SETTABSTOPS          0x0192
#define LB_GETHORIZONTALEXTENT  0x0193
#define LB_SETHORIZONTALEXTENT  0x0194
#define LB_SETCOLUMNWIDTH       0x0195
#define LB_ADDFILE              0x0196
#define LB_SETTOPINDEX          0x0197
#define LB_GETITEMRECT          0x0198
#define LB_GETITEMDATA          0x0199
#define LB_SETITEMDATA          0x019A
#define LB_SELITEMRANGE         0x019B
#define LB_SETANCHORINDEX       0x019C
#define LB_GETANCHORINDEX       0x019D
#define LB_SETCARETINDEX        0x019E
#define LB_GETCARETINDEX        0x019F
#define LB_SETITEMHEIGHT        0x01A0
#define LB_GETITEMHEIGHT        0x01A1
#define LB_FINDSTRINGEXACT      0x01A2
#define LB_SETLOCALE            0x01A5
#define LB_GETLOCALE            0x01A6
#define LB_SETCOUNT             0x01A7

