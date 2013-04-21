/*
 * $Id$
 * DBCHW - DBC ( Harbour + HWGUI )
 * Commands ( Replace, delete, ... )
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "guilib.ch"
#include "dbchw.h"

   /* -----------------------  Replace --------------------- */

FUNCTION C_REPL
   LOCAL oDlg, oMsg, nRec
   LOCAL af := Array( FCount() ), nField := 0
   LOCAL cVal := "", xVal, r1 := 1, nNext := 0, cFor := "", bFor
   LOCAL oBrw := GetBrwActive()

   AFields( af )
   improc := oBrw:cargo

   IF aFiles[ improc, AF_RDONLY ]
      hwg_Msgstop( "File is opened in readonly mode" )
      RETURN Nil
   ENDIF

   INIT DIALOG oDlg TITLE aFiles[improc,AF_ALIAS]+": Replace" ;
      AT 0, 0         ;
      SIZE 320, 250   ;
      FONT oMainFont

   @ 10,10 GET COMBOBOX nField ITEMS af SIZE 120, 150

   @ 140,10 GROUPBOX "" SIZE 160, 80
   GET RADIOGROUP r1
   @ 150,24 RADIOBUTTON "All" SIZE 60, 20 
   @ 150,44 RADIOBUTTON "Next" SIZE 60, 20 
   @ 150,64 RADIOBUTTON "Rest" SIZE 60, 20 
   END RADIOGROUP
   @ 210,44 GET nNext SIZE 50, 24 PICTURE "9999"

   @ 10, 80 SAY "with value: " SIZE 100, 22
   @ 10, 104 GET cVal SIZE 300, 24
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @ 10, 130 SAY "For: " SIZE 100, 22
   @ 10, 154 GET cFor SIZE 300, 24 PICTURE "@S256" STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @  30, 210  BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 190, 210 BUTTON "Cancel" SIZE 100, 32 ON CLICK { ||hwg_EndDialog() }

   oDlg:Activate()

   IF oDlg:lResult
      IF !Empty( cFor ) .AND. Type( cFor ) != "L"
         hwg_Msgstop( "Wrong expression!" )
      ELSE
         IF !Empty( cFor )
            bFor := &( "{||" + cFor + "}" )
         ENDIF
         nrec := RecNo()
         oMsg := DlgWait( "Replacing" )

         xVal := &cVal
         IF r1 == 1
            Eval( oBrw:bGoTop, oBrw )
         ENDIF
         DO WHILE !Eval( oBrw:bEof, oBrw ) .AND. Iif( r1==2, nNext-- > 0, .T. )
            IF Empty( cFor ) .OR. Eval( bFor )
               IF !aFiles[improc,AF_EXCLU]
                  rlock()
               ENDIF
               Fieldput( nField, xVal )
               IF !aFiles[improc,AF_EXCLU]
                  UNLOCK
               ENDIF
            ENDIF
            Eval( oBrw:bSkip, oBrw, 1 )
         ENDDO

         GO nrec
         oMsg:Close()
         UpdBrowse()
      ENDIF
   ENDIF

   RETURN Nil


   /* -----------------------  Delete, recall, count --------------------- */

FUNCTION C_4( nAct )
   LOCAL oDlg, aTitle := { "Delete", "Recall", "Count", "Sum" }
   LOCAL cExpr := "", r1 := 1, nNext := 0, cFor := "", bFor, bSum
   LOCAL oBrw := GetBrwActive(), nCount := 0

   INIT DIALOG oDlg TITLE aTitle[nAct] ;
      AT 0, 0         ;
      SIZE 320, 250   ;
      FONT oMainFont

   IF nAct <= 2 .AND. aFiles[ improc, AF_RDONLY ]
      hwg_Msgstop( "File is opened in readonly mode" )
      RETURN Nil
   ENDIF

   IF nAct == 4
      @ 10, 10 SAY "Sum: " SIZE 40, 22
      @ 50, 10 GET cExpr SIZE 260, 24
      Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS
   ENDIF

   @ 20,40 GROUPBOX "" SIZE 160, 80
   GET RADIOGROUP r1
   @ 30,50 RADIOBUTTON "All" SIZE 60, 20 
   @ 30,70 RADIOBUTTON "Next" SIZE 60, 20 
   @ 30,90 RADIOBUTTON "Rest" SIZE 60, 20 
   END RADIOGROUP
   @ 96,70 GET nNext SIZE 50, 24 PICTURE "9999"

   @ 10, 130 SAY "For: " SIZE 60, 22
   @ 10, 152 GET cFor SIZE 300, 24 PICTURE "@S256" STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @  30, 210  BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 190, 210 BUTTON "Cancel" SIZE 100, 32 ON CLICK { ||hwg_EndDialog() }

   oDlg:Activate()

   IF oDlg:lResult

      IF !Empty( cFor ) .AND. Type( cFor ) != "L"
         hwg_Msgstop( "Wrong 'FOR' expression!" )
         RETURN Nil
      ENDIF
      IF nAct == 4 
         IF Empty( cExpr ) .AND. Type( cExpr ) != "N"
            hwg_Msgstop( "Wrong 'SUM' expression!" )
            RETURN Nil
         ELSE
            bSum := &( "{||" + cExpr + "}" )
         ENDIF
      ENDIF

      IF !Empty( cFor )
         bFor := &( "{||" + cFor + "}" )
      ENDIF
      nrec := RecNo()
      oMsg := DlgWait( aTitle[nAct] )

      IF r1 == 1
         Eval( oBrw:bGoTop, oBrw )
      ENDIF
      DO WHILE !Eval( oBrw:bEof, oBrw ) .AND. Iif( r1==2, nNext-- > 0, .T. )
         IF Empty( cFor ) .OR. Eval( bFor )
            IF nAct == 1
               IF !aFiles[improc,AF_EXCLU]
                  rlock()
               ENDIF
               DELETE
               IF !aFiles[improc,AF_EXCLU]
                  UNLOCK
               ENDIF
            ELSEIF nAct == 2
               IF !aFiles[improc,AF_EXCLU]
                  rlock()
               ENDIF
               RECALL
               IF !aFiles[improc,AF_EXCLU]
                  UNLOCK
               ENDIF
            ELSEIF nAct == 3
               nCount ++
            ELSEIF nAct == 4
               nCount += Eval( bSum )
            ENDIF
         ENDIF
         Eval( oBrw:bSkip, oBrw, 1 )
      ENDDO

      GO nrec
      oMsg:Close()
      IF nAct > 2
         hwg_MsgInfo( Ltrim(Str(nCount)), "Result" )
      ELSE
         UpdBrowse()
      ENDIF
   ENDIF

   RETURN Nil

   /* -----------------------  Append from --------------------- */

FUNCTION C_APPEND()
   LOCAL oDlg, oMsg, cFile := "", cFields := "", cFor := "", cDelim := ""
   LOCAL r1 := 1, bFor, af, cPath := cServerPath
#ifdef RDD_ADS
   LOCAL lRemote := (nServerType == 6)
#else
   LOCAL lRemote := (nServerType == REMOTE_SERVER)
#endif
   LOCAL oBrw := GetBrwActive()
   Local oBtnFile, bBtnDis := {||Iif(lRemote,oBtnFile:Disable(),oBtnFile:Enable()),.T.}
   LOCAL bFileBtn := {||
   cFile := hwg_Selectfile( "dbf files( *.dbf )", "*.dbf", hb_curDrive()+":\"+Curdir() )
   hwg_RefreshAllGets( oDlg )
   Return .T.
   }

   IF aFiles[ improc, AF_RDONLY ]
      hwg_Msgstop( "File is opened in readonly mode" )
      RETURN Nil
   ENDIF

   INIT DIALOG oDlg TITLE aFiles[improc,AF_ALIAS]+": Append" ;
      AT 0, 0         ;
      SIZE 400, 320   ;
      FONT oMainFont ON INIT bBtnDis

#if defined( RDD_ADS ) .OR. defined( RDD_LETO )
   @ 10,10 SAY "Server " SIZE 60,22 STYLE SS_RIGHT
   @ 70,10 GET CHECKBOX lRemote CAPTION "Remote:" SIZE 80, 20 ON CLICK bBtnDis
   @ 150,10 GET cPath SIZE 240,24
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_RIGHTABS
#endif

   @ 10,34 SAY "File name: " SIZE 80,22 STYLE SS_RIGHT
   @ 90,34 GET cFile SIZE 220,24 PICTURE "@S128" STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_RIGHTABS
   @ 310,34 BUTTON oBtnFile CAPTION "Browse" SIZE 80, 26 ON CLICK bFileBtn ON SIZE ANCHOR_RIGHTABS

   @ 10,60 SAY "Fields: " SIZE 80,22 STYLE SS_RIGHT
   @ 90,60 GET cFields SIZE 220,24 PICTURE "@S256" STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_RIGHTABS

   @ 10, 92 GROUPBOX "" SIZE 168, 88
   GET RADIOGROUP r1
   @ 20,104 RADIOBUTTON "Dbf" SIZE 90, 20 
   @ 20,128 RADIOBUTTON "Sdf" SIZE 90, 20 
   @ 20,152 RADIOBUTTON "Delimited with" SIZE 112, 20 
   END RADIOGROUP
   @ 132,152 GET cDelim SIZE 30, 24 PICTURE "XX"

   @ 10, 200 SAY "For: " SIZE 100, 22
   @ 10, 222 GET cFor SIZE 380, 24 PICTURE "@S256" STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @  30, 268  BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 190, 268 BUTTON "Cancel" SIZE 100, 32 ON CLICK { ||hwg_EndDialog() }

   oDlg:Activate()

   IF oDlg:lResult

      IF Empty( cFile )
         hwg_Msgstop( "File name is absent" )
         RETURN Nil
      ENDIF
      IF !Empty( cFor ) .AND. Type( cFor ) != "L"
         hwg_Msgstop( "Wrong 'FOR' expression!" )
         RETURN Nil
      ENDIF
      IF !Empty( cFor )
         bFor := &( "{||" + cFor + "}" )
      ENDIF
      IF !Empty( cFields )
         af := hb_aTokens( Trim(cFields), "," )
      ENDIF

      oMsg := DlgWait( "Append" )
      cFile := Iif( lRemote, Trim( cServerPath ), "" ) + Trim( cFile )
      IF r1 == 1
#ifdef RDD_ADS
         AdsSetServerType( nServerType := Iif( lRemote, 6, ADS_LOCAL_SERVER ) )
         __dbApp( cFile, af, bfor,,,, .F. )
#else
         __dbApp( cFile, af, bfor,,,, .F., Iif( lRemote,"LETO","DBFCDX" ),, cDataCPage )
#endif
      ELSEIF r1 == 2
         __dbSdf( .F., cFile, af, bfor,,,, .F. )
      ELSE
         __dbDelim( .F., cFile, Iif( Empty(cdelim), "blank", Trim(cdelim) ), af, bfor,,,, .F. )
      ENDIF
      oMsg:Close()
      UpdBrowse()
   ENDIF

   RETURN Nil

FUNCTION C_COPY()
   LOCAL oDlg, oMsg, cFile := "", cFields := "", cFor := "", cDelim := ""
   LOCAL r1 := 1, r2 := 1, bFor, af, nNext := 0, cPath := cServerPath
#ifdef RDD_ADS
   LOCAL lRemote := (nServerType == 6)
#else
   LOCAL lRemote := (nServerType == REMOTE_SERVER)
#endif
   LOCAL oBtnFile, bBtnDis := {||Iif(lRemote,oBtnFile:Disable(),oBtnFile:Enable()),.T.}
   LOCAL bFileBtn := {||
   cFile := hwg_Savefile( "*.dbf","xBase files( *.dbf )", "*.dbf", mypath )
   hwg_RefreshAllGets( oDlg )
   Return .T.
   }

   INIT DIALOG oDlg TITLE aFiles[improc,AF_ALIAS]+": Copy" ;
      AT 0, 0         ;
      SIZE 400, 320   ;
      FONT oMainFont ON INIT bBtnDis

#if defined( RDD_ADS ) .OR. defined( RDD_LETO )
   @ 10,10 SAY "Server " SIZE 60,22 STYLE SS_RIGHT
   @ 70,10 GET CHECKBOX lRemote CAPTION "Remote:" SIZE 80, 20 ON CLICK bBtnDis
   @ 150,10 GET cPath SIZE 240,24
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_RIGHTABS
#endif

   @ 10,34 SAY "File name: " SIZE 80,22 STYLE SS_RIGHT
   @ 90,34 GET cFile SIZE 220,24 PICTURE "@S128" STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_RIGHTABS
   @ 310,34 BUTTON oBtnFile CAPTION "Browse" SIZE 80, 26 ON CLICK bFileBtn ON SIZE ANCHOR_RIGHTABS

   @ 10,60 SAY "Fields: " SIZE 80,22 STYLE SS_RIGHT
   @ 90,60 GET cFields SIZE 220,24 PICTURE "@S256" STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_RIGHTABS

   @ 10, 92 GROUPBOX "" SIZE 168, 88
   GET RADIOGROUP r1
   @ 20,104 RADIOBUTTON "Dbf" SIZE 90, 20 
   @ 20,128 RADIOBUTTON "Sdf" SIZE 90, 20 
   @ 20,152 RADIOBUTTON "Delimited with" SIZE 112, 20 
   END RADIOGROUP
   @ 132,152 GET cDelim SIZE 30, 24 PICTURE "XX"

   @ 200, 92 GROUPBOX "" SIZE 168, 88
   GET RADIOGROUP r2
   @ 210,104 RADIOBUTTON "All" SIZE 90, 20 
   @ 210,128 RADIOBUTTON "Next" SIZE 90, 20 
   @ 210,152 RADIOBUTTON "Rest" SIZE 90, 20 
   END RADIOGROUP
   @ 300,128 GET nNext SIZE 40, 24 PICTURE "9999"

   @ 10, 200 SAY "For: " SIZE 100, 22
   @ 10, 222 GET cFor SIZE 380, 24 PICTURE "@S256" STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @  30, 268  BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 190, 268 BUTTON "Cancel" SIZE 100, 32 ON CLICK { ||hwg_EndDialog() }

   oDlg:Activate()

   IF oDlg:lResult

      IF Empty( cFile )
         hwg_Msgstop( "File name is absent" )
         RETURN Nil
      ENDIF
      IF !Empty( cFor ) .AND. Type( cFor ) != "L"
         hwg_Msgstop( "Wrong 'FOR' expression!" )
         RETURN Nil
      ENDIF
      IF !Empty( cFor )
         bFor := &( "{||" + cFor + "}" )
      ENDIF
      IF !Empty( cFields )
         af := hb_aTokens( Trim(cFields), "," )
      ENDIF

      oMsg := DlgWait( "Append" )
      cFile := Iif( lRemote, Trim( cServerPath ), "" ) + Trim( cFile )
      IF r1 == 1 .AND. r2 == 1
#ifdef RDD_ADS
          AdsSetServerType( nServerType := Iif( lRemote, 6, ADS_LOCAL_SERVER ) )
         __dbApp( cFile, af, bfor,,,, .F. )
#else
         __dbCopy( cFile, af, bFor,,,, .F., Iif( lRemote,"LETO","DBFCDX" ),, cDataCPage )
#endif
      ELSEIF r1 == 1 .AND. r2 == 2
#ifdef RDD_ADS
          AdsSetServerType( nServerType := Iif( lRemote, 6, ADS_LOCAL_SERVER ) )
         __dbCopy( cFile, af, bFor,, nNext,, .F. )
#else
         __dbCopy( cFile, af, bFor,, nNext,, .F., Iif( lRemote,"LETO","DBFCDX" ),, cDataCPage )
#endif
      ELSEIF r1 == 1 .AND. r2 == 3
#ifdef RDD_ADS
          AdsSetServerType( nServerType := Iif( lRemote, 6, ADS_LOCAL_SERVER ) )
         __dbCopy( cFile, af, bFor,,,, .T. )
#else
         __dbCopy( cFile, af, bFor,,,, .T., Iif( lRemote,"LETO","DBFCDX" ),, cDataCPage )
#endif
      ELSEIF r1 == 2 .AND. r2 == 1
         __dbSdf( .T., cFile, af, bFor,,,, .F. )
      ELSEIF r1 == 2 .AND. r2 == 2
         __dbSdf( .T., cFile, af, bFor,, nrest,, .F. )
      ELSEIF r1 == 2 .AND. r2 == 3
         __dbSdf( .T., cFile, af, bFor,,,, .T. )
      ELSEIF r1 == 3 .AND. r2 == 1
         __dbDelim( .T., cFile, Iif( Empty(cdelim), "blank", cdelim ), af, bFor,,,, .F. )
      ELSEIF r1 == 3 .AND. r2 == 2
         __dbDelim( .T., cFile, Iif( Empty(cdelim), "blank", cdelim ), af, bFor,, nrest,, .F. )
      ELSEIF r1 == 3 .AND. r2 == 3
         __dbDelim( .T., cFile, Iif( Empty(cdelim), "blank", cdelim ), af, bFor,,,, .T. )
      ENDIF
      oMsg:Close()
      UpdBrowse()
   ENDIF

   RETURN Nil

   /* -----------------------  Reindex, pack, zap --------------------- */

FUNCTION C_RPZ( nAct )
   LOCAL oMsg, aTitle := { "Reindex", "Pack", "Zap" }
   LOCAL oBrw := GetBrwActive()

   improc := oBrw:cargo

   IF !aFiles[ improc, AF_EXCLU ]
      hwg_Msgstop( "File must be opened in exclusive mode" )
      RETURN Nil
   ENDIF
   IF aFiles[ improc, AF_RDONLY ]
      hwg_Msgstop( "File is opened in readonly mode" )
      RETURN Nil
   ENDIF

   IF hwg_MsgYesNo( "Really " + aTitle[nAct] + " " + aFiles[improc,AF_ALIAS] + "?", "Attention!" )

      oMsg := DlgWait( aTitle[nAct] )
      IF nAct == 1
         REINDEX
      ELSEIF nAct == 2
         PACK
      ELSEIF nAct == 3
         ZAP
      ENDIF
      oMsg:Close()
      UpdBrowse()
   ENDIF

   RETURN Nil

FUNCTION C_REL
   LOCAL oDlg, oBrowse, arel := {}, aals := {}, nAlias := 1, i := 0, cExpr
   LOCAL bClear := {||
      dbClearRelation()
      oBrowse:aArray := arel := {}
      hwg_Invalidaterect( oBrowse:handle, 1 )
      oBrowse:Refresh()
      }
   LOCAL bAdd := {||
      LOCAL cTmp
      dbSetRelation( aals[nAlias], &( "{||"+Trim(cExpr)+"}" ), Trim(cExpr) )
      oBrowse:aArray := aRel := {}
      i := 0
      DO WHILE !Empty( cTmp := dbRelation( ++i ) )
         Aadd( arel, { cTmp, Alias( dbRselect(i) ) } )
      ENDDO
      hwg_Invalidaterect( oBrowse:handle, 1 )
      oBrowse:Refresh()
      }

   DO WHILE !Empty( cExpr := dbRelation( ++i ) )
      Aadd( arel, { cExpr, Alias( dbRselect(i) ) } )
   ENDDO
   FOR i := 1 TO Len( aFiles )
      IF aFiles[ i,AF_NAME ] != Nil .AND. i != improc
         Aadd( aals, aFiles[ i,AF_ALIAS ] )
      ENDIF
   NEXT

   INIT DIALOG oDlg TITLE "Relations" ;
      AT 0, 0         ;
      SIZE 400, 280   ;
      FONT oMainFont

   @ 20,20 BROWSE oBrowse ARRAY   ;
       SIZE 360,120               ;
       STYLE WS_BORDER+WS_VSCROLL ;
       ON SIZE ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_BOTTOMABS+ANCHOR_RIGHTABS

   oBrowse:aArray := arel
   oBrowse:AddColumn( HColumn():New( "",{|v,o|o:nCurrent},"N",4,0 ) )
   oBrowse:AddColumn( HColumn():New( "Expression",{|v,o|o:aArray[o:nCurrent,1]},"C",30,0 ) )
   oBrowse:AddColumn( HColumn():New( "Child",{|v,o|o:aArray[o:nCurrent,2]},"C",10,0 ) )
   oBrowse:bcolorSel := COLOR_SELE

   cExpr := ""
   @ 10,160 SAY "Expression: " SIZE 90, 22
   @ 100,160 GET cExpr SIZE 280, 24 STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_BOTTOMABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @ 10,184 SAY "To area: " SIZE 90, 22
   @ 100,184 GET COMBOBOX nAlias ITEMS aals SIZE 120, 150

   @ 40,230 BUTTON "Add" SIZE 80,30 ON CLICK bAdd ON SIZE ANCHOR_LEFTABS+ANCHOR_BOTTOMABS
   @ 160,230 BUTTON "Clear all" SIZE 80,30 ON CLICK bClear ON SIZE ANCHOR_LEFTABS+ANCHOR_BOTTOMABS
   @ 280,230 BUTTON "Close" SIZE 80,30 ON CLICK {||hwg_EndDialog()} ON SIZE ANCHOR_BOTTOMABS+ANCHOR_RIGHTABS

   oDlg:Activate()

   RETURN Nil
