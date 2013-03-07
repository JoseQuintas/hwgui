/*
 * DBCHW - DBC ( Harbour + HWGUI )
 * Commands ( Replace, delete, ... )
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "guilib.ch"
#include "dbchw.h"
// #include "ads.ch"

MEMVAR finame, cValue, cFor, nSum, mypath, improc, msmode
/* -----------------------  Replace --------------------- */

Function C_REPL
Local aModDlg
Local af := Array( Fcount() )
   Afields( af )

   INIT DIALOG aModDlg FROM RESOURCE "DLG_REPLACE" ON INIT {|| InitRepl() }

   REDEFINE COMBOBOX af OF aModDlg ID IDC_COMBOBOX1

   DIALOG ACTIONS OF aModDlg ;
        ON 0,IDOK         ACTION {|| EndRepl()}   ;
        ON BN_CLICKED,IDC_RADIOBUTTON7 ACTION {|| RecNumberEdit() } ;
        ON BN_CLICKED,IDC_RADIOBUTTON6 ACTION {|| RecNumberDisable() } ;
        ON BN_CLICKED,IDC_RADIOBUTTON8 ACTION {|| RecNumberDisable() }

   aModDlg:Activate()

Return Nil

Static Function RecNumberEdit
Local hDlg := hwg_GetModalHandle()
Local hEdit := hwg_Getdlgitem( hDlg,IDC_EDITRECN )
   hwg_Sendmessage( hEdit, WM_ENABLE, 1, 0 )
   hwg_Setdlgitemtext( hDlg, IDC_EDITRECN, "1" )
   hwg_Setfocus( hEdit )
Return Nil

Static Function RecNumberDisable
Local hEdit := hwg_Getdlgitem( hwg_GetModalHandle(),IDC_EDITRECN )
   hwg_Sendmessage( hEdit, WM_ENABLE, 0, 0 )
Return Nil

Static Function InitRepl()
Local hDlg := hwg_GetModalHandle()

   RecNumberDisable()
   hwg_Checkradiobutton( hDlg,IDC_RADIOBUTTON6,IDC_RADIOBUTTON8,IDC_RADIOBUTTON6 )
   hwg_Setfocus( hwg_Getdlgitem( hDlg, IDC_COMBOBOX1 ) )
Return Nil

Static Function EndRepl()
Local hDlg := hwg_GetModalHandle()
Local nrest, nrec
Local oWindow, aControls, i
Private finame, cValue, cFor

   oWindow := HMainWindow():GetMdiActive()

   finame := hwg_Getdlgitemtext( hDlg, IDC_COMBOBOX1, 12 )
   IF Empty( finame )
      hwg_Setfocus( hwg_Getdlgitem( hDlg, IDC_COMBOBOX1 ) )
      Return Nil
   ENDIF
   cValue := hwg_Getdlgitemtext( hDlg, IDC_EDIT7, 60 )
   IF Empty( cValue )
      hwg_Setfocus( hwg_Getdlgitem( hDlg, IDC_EDIT7 ) )
      Return Nil
   ENDIF
   cFor := hwg_Getdlgitemtext( hDlg, IDC_EDITFOR, 60 )
   IF .NOT. EMPTY( cFor ) .AND. TYPE( cFor ) <> "L"
      hwg_Msgstop( "Wrong expression!" )
   ELSE
      IF EMPTY( cFor )
         cFor := ".T."
      ENDIF
      nrec := Recno()
      hwg_Setdlgitemtext( hDlg, IDC_TEXTMSG, "Wait ..." )
      IF hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON6 )
         REPLACE ALL &finame WITH &cValue FOR &cFor
      ELSEIF hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON7 )
         nrest := Val( hwg_Getdlgitemtext( hDlg, IDC_EDITRECN, 10 ) )
         REPLACE NEXT nrest &finame WITH &cValue FOR &cFor
      ELSEIF hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON8 )
         REPLACE REST &finame WITH &cValue FOR &cFor
      ENDIF
      Go nrec
      hwg_Setdlgitemtext( hDlg, IDC_TEXTMSG, "Done !" )
      IF oWindow != Nil
         aControls := oWindow:aControls
         IF ( i := Ascan( aControls, {|o|o:ClassName()=="HBROWSE"} ) ) > 0
            aControls[i]:Refresh()
         ENDIF
      ENDIF
   ENDIF
Return Nil

/* -----------------------  Delete, recall, count --------------------- */

Function C_DELE( nAct )
Local aModDlg

   INIT DIALOG aModDlg FROM RESOURCE "DLG_DEL" ON INIT {|| InitDele(nAct) }
   DIALOG ACTIONS OF aModDlg ;
        ON 0,IDOK         ACTION {|| EndDele(nAct)}   ;
        ON 0,IDCANCEL     ACTION {|| hwg_EndDialog( hwg_GetModalHandle() )}  ;
        ON BN_CLICKED,IDC_RADIOBUTTON7 ACTION {|| RecNumberEdit() } ;
        ON BN_CLICKED,IDC_RADIOBUTTON6 ACTION {|| RecNumberDisable() } ;
        ON BN_CLICKED,IDC_RADIOBUTTON8 ACTION {|| RecNumberDisable() }
   aModDlg:Activate()

Return Nil

Static Function InitDele(nAct)
Local hDlg := hwg_GetModalHandle()
   IF nAct == 2
      hwg_Setwindowtext( hDlg,"Recall")
   ELSEIF nAct == 3
      hwg_Setwindowtext( hDlg,"Count")
   ENDIF
   RecNumberDisable()
   hwg_Checkradiobutton( hDlg,IDC_RADIOBUTTON6,IDC_RADIOBUTTON8,IDC_RADIOBUTTON6 )
   hwg_Setfocus( hwg_Getdlgitem( hDlg, IDC_EDITFOR ) )
Return Nil

Static Function EndDele( nAct )
Local hDlg := hwg_GetModalHandle()
Local nrest, nsum, nRec := Recno()
Local oWindow, aControls, i
Private cFor

   oWindow := HMainWindow():GetMdiActive()

   cFor := hwg_Getdlgitemtext( hDlg, IDC_EDITFOR, 60 )
   IF .NOT. EMPTY( cFor ) .AND. TYPE( cFor ) <> "L"
      hwg_Msgstop( "Wrong expression!" )
   ELSE
      IF EMPTY( cFor )
         cFor := ".T."
      ENDIF
      hwg_Setdlgitemtext( hDlg, IDC_TEXTMSG, "Wait ..." )
      IF nAct == 1
         IF hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON6 )
            DELETE ALL FOR &cFor
         ELSEIF hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON7 )
            nrest := Val( hwg_Getdlgitemtext( hDlg, IDC_EDITRECN, 10 ) )
            DELETE NEXT nrest FOR &cFor
         ELSEIF hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON8 )
            DELETE REST FOR &cFor
         ENDIF
      ELSEIF nAct == 2
         IF hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON6 )
            RECALL ALL FOR &cFor
         ELSEIF hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON7 )
            nrest := Val( hwg_Getdlgitemtext( hDlg, IDC_EDITRECN, 10 ) )
            RECALL NEXT nrest FOR &cFor
         ELSEIF hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON8 )
            RECALL REST FOR &cFor
         ENDIF
      ELSEIF nAct == 3
         IF hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON6 )
            COUNT TO nsum ALL FOR &cFor
         ELSEIF hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON7 )
            nrest := Val( hwg_Getdlgitemtext( hDlg, IDC_EDITRECN, 10 ) )
            COUNT TO nsum NEXT nrest FOR &cFor
         ELSEIF hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON8 )
            COUNT TO nsum REST FOR &cFor
         ENDIF
         hwg_Setdlgitemtext( hDlg, IDC_TEXTMSG, "Result: "+Str( nsum ) )
         Go nrec
         Return Nil
      ENDIF
      Go nrec
      hwg_WriteStatus( oWindow,3,"Done" )
      IF oWindow != Nil
         aControls := oWindow:aControls
         IF ( i := Ascan( aControls, {|o|o:ClassName()=="HBROWSE"} ) ) > 0
            hwg_Redrawwindow( aControls[i]:handle, RDW_ERASE + RDW_INVALIDATE )
         ENDIF
      ENDIF
   ENDIF

   hwg_EndDialog( hDlg )
Return Nil

/* -----------------------  Sum --------------------- */

Function C_SUM()
Local aModDlg

   INIT DIALOG aModDlg FROM RESOURCE "DLG_SUM" ON INIT {|| InitSum() }
   DIALOG ACTIONS OF aModDlg ;
        ON 0,IDOK         ACTION {|| EndSum()}   ;
        ON 0,IDCANCEL     ACTION {|| hwg_EndDialog( hwg_GetModalHandle() )}  ;
        ON BN_CLICKED,IDC_RADIOBUTTON7 ACTION {|| RecNumberEdit() } ;
        ON BN_CLICKED,IDC_RADIOBUTTON6 ACTION {|| RecNumberDisable() } ;
        ON BN_CLICKED,IDC_RADIOBUTTON8 ACTION {|| RecNumberDisable() }
   aModDlg:Activate()

Return Nil

Static Function InitSum()
Local hDlg := hwg_GetModalHandle()
   RecNumberDisable()
   hwg_Checkradiobutton( hDlg,IDC_RADIOBUTTON6,IDC_RADIOBUTTON8,IDC_RADIOBUTTON6 )
   hwg_Setfocus( hwg_Getdlgitem( hDlg, IDC_EDIT7 ) )
Return Nil

Static Function EndSum()
Local hDlg := hwg_GetModalHandle()
Local cSumf, cFor, nrest, blsum, blfor, nRec := Recno()
Private nsum := 0

   cSumf := hwg_Getdlgitemtext( hDlg, IDC_EDIT7, 60 )
   IF EMPTY( cSumf )
      hwg_Setfocus( hwg_Getdlgitem( hDlg, IDC_EDIT7 ) )
      Return Nil
   ENDIF

   cFor := hwg_Getdlgitemtext( hDlg, IDC_EDITFOR, 60 )
   IF ( !EMPTY( cFor ) .AND. TYPE( cFor ) <> "L" ) .OR. TYPE( cSumf ) <> "N"
      hwg_Msgstop( "Wrong expression!" )
   ELSE
      IF EMPTY( cFor )
         cFor := ".T."
      ENDIF
      hwg_Setdlgitemtext( hDlg, IDC_TEXTMSG, "Wait ..." )
      blsum := &( "{||nsum:=nsum+" + cSumf + "}" )
      blfor := &( "{||" + cFor + "}" )
      IF hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON6 )
         DBEVAL( blsum, blfor )
      ELSEIF hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON7 )
         nrest := Val( hwg_Getdlgitemtext( hDlg, IDC_EDITRECN, 10 ) )
         DBEVAL( blsum, blfor,, nrest )
      ELSEIF hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON8 )
         DBEVAL( blsum, blfor,,,, .T. )
      ENDIF
      Go nrec
      hwg_Setdlgitemtext( hDlg, IDC_TEXTMSG, "Result: "+Str( nsum ) )
      Return Nil
   ENDIF

   hwg_EndDialog( hDlg )
Return Nil

/* -----------------------  Append from --------------------- */

Function C_APPEND()
Local aModDlg

   INIT DIALOG aModDlg FROM RESOURCE "DLG_APFROM" ON INIT {|| InitApp() }
   DIALOG ACTIONS OF aModDlg ;
        ON 0,IDOK         ACTION {|| EndApp()}  ;
        ON 0,IDCANCEL     ACTION {|| hwg_EndDialog( hwg_GetModalHandle() )}  ;
        ON BN_CLICKED,IDC_BUTTONBRW ACTION {||hwg_Setdlgitemtext( hwg_GetModalHandle(), IDC_EDIT7, hwg_SelectFile( "xBase files( *.dbf )", "*.dbf", mypath ) ) } ;
        ON BN_CLICKED,IDC_RADIOBUTTON11 ACTION {|| DelimEdit() } ;
        ON BN_CLICKED,IDC_RADIOBUTTON10 ACTION {|| DelimDisable() } ;
        ON BN_CLICKED,IDC_RADIOBUTTON9 ACTION {|| DelimDisable() }
   aModDlg:Activate()

Return Nil

Static Function DelimEdit
Local hDlg := hwg_GetModalHandle()
Local hEdit := hwg_Getdlgitem( hDlg,IDC_EDITDWITH )
   hwg_Sendmessage( hEdit, WM_ENABLE, 1, 0 )
   hwg_Setdlgitemtext( hDlg, IDC_EDITDWITH, " " )
   hwg_Setfocus( hEdit )
Return Nil

Static Function DelimDisable
Local hEdit := hwg_Getdlgitem( hwg_GetModalHandle(),IDC_EDITDWITH )
   hwg_Sendmessage( hEdit, WM_ENABLE, 0, 0 )
Return Nil

Static Function InitApp()
Local hDlg := hwg_GetModalHandle()
   DelimDisable()
   hwg_Checkradiobutton( hDlg,IDC_RADIOBUTTON9,IDC_RADIOBUTTON9,IDC_RADIOBUTTON11 )
   hwg_Setfocus( hwg_Getdlgitem( hDlg, IDC_EDIT7 ) )
Return Nil

Static Function EndApp()
Local hDlg := hwg_GetModalHandle()
Local fname, nRec := Recno()

   fname := hwg_Getdlgitemtext( hDlg, IDC_EDIT7, 60 )
   IF EMPTY( fname )
      hwg_Setfocus( hwg_Getdlgitem( hDlg, IDC_EDIT7 ) )
      Return Nil
   ENDIF

   hwg_Setdlgitemtext( hDlg, IDC_TEXTMSG, "Wait ..." )
   IF hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON6 )
      // DBEVAL( blsum, blfor )
   ELSEIF hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON7 )
      // nrest := Val( hwg_Getdlgitemtext( hDlg, IDC_EDITRECN, 10 ) )
      // DBEVAL( blsum, blfor,, nrest )
   ELSEIF hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON8 )
      // DBEVAL( blsum, blfor,,,, .T. )
   ENDIF
   Go nrec

   hwg_EndDialog( hDlg )
Return Nil

/* -----------------------  Reindex, pack, zap --------------------- */

Function C_RPZ( nAct )
Local aModDlg

   INIT DIALOG aModDlg FROM RESOURCE "DLG_OKCANCEL" ON INIT {|| InitRPZ(nAct) }
   DIALOG ACTIONS OF aModDlg ;
        ON 0,IDOK         ACTION {|| EndRPZ(nAct)}   ;
        ON 0,IDCANCEL     ACTION {|| hwg_EndDialog( hwg_GetModalHandle() ) }
   aModDlg:Activate()

Return Nil

Static Function InitRPZ( nAct )
Local hDlg := hwg_GetModalHandle()
   hwg_Setdlgitemtext( hDlg, IDC_TEXTHEAD, Iif( nAct==1,"Reindex ?", ;
                                       Iif( nAct==2,"Pack ?", "Zap ?" ) ) )
Return Nil

Static Function EndRPZ( nAct )
Local hDlg := hwg_GetModalHandle()
Local hWnd, oWindow, aControls, i

   IF .NOT. msmode[ improc, 1 ]
      IF .NOT. FileLock()
         hwg_EndDialog( hDlg )
         Return Nil
      ENDIF
   ENDIF
   hwg_Setdlgitemtext( hDlg, IDC_TEXTMSG, "Wait ..." )
   IF nAct == 1
      Reindex
   ELSEIF nAct == 2
      Pack
   ELSEIF nAct == 3
      Zap
   ENDIF

   hWnd := hwg_Sendmessage( HWindow():GetMain():handle, WM_MDIGETACTIVE,0,0 )
   oWindow := HWindow():FindWindow( hWnd )
   IF oWindow != Nil
      aControls := oWindow:aControls
      IF ( i := Ascan( aControls, {|o|o:ClassName()=="HBROWSE"} ) ) > 0
         hwg_Redrawwindow( aControls[i]:handle, RDW_ERASE + RDW_INVALIDATE )
      ENDIF
   ENDIF

   hwg_EndDialog( hDlg )
Return Nil
