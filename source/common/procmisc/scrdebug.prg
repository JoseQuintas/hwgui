/*
 * $Id$
 *
 * Common procedures
 * Scripts Debugger
 *
 * Author: Alexander S.Kresin <alex@belacy.belgorod.su>
 *         www - http://kresin.belgorod.su
*/

#include "hwgui.ch"

STATIC oDlgDebug := Nil
STATIC oBrwData, oBrwScript, oSplit, oPanel, oEditExpr, oEditRes
STATIC nDebugMode := 0
STATIC i_scr := 0
STATIC oDlgFont, oScrFont, oBmpCurr, oBmpPoint
STATIC nAnimaTime
STATIC aBreakPoints
STATIC aBreaks  := {}
STATIC aWatches := {}
STATIC aScriptCurr
STATIC nScriptSch := 0

FUNCTION hwg_scrDebug( aScript, iscr )

   LOCAL nFirst, i

   IF Len( aScript ) < 3
      Return .F.
   ELSEIF Len( aScript ) == 3
      Aadd( aScript, Nil )
   ENDIF
   IF Empty( aScript[4] )
      nScriptSch ++
      aScript[4] := nScriptSch
   ENDIF
   IF aScriptCurr == Nil
      aScriptCurr := aScript
   ENDIF

   IF oDlgDebug == Nil .AND. iscr > 0

      oDlgFont := HFont():Add( "Georgia",0,-15,,204 )
      oScrFont := HFont():Add( "Courier New",0,-15,,204 )
#ifndef __GTK__
      oBmpCurr := HBitmap():AddStandard(OBM_RGARROWD)
      oBmpPoint:= HBitmap():AddStandard(OBM_CHECK)
#endif
      INIT DIALOG oDlgDebug TITLE ( "Script Debugger - " + aScript[ 1 ] ) AT 210,10 SIZE 500,300 ;
           FONT oDlgFont STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX ;
           ON EXIT { || dlgDebugClose() }

      MENU OF oDlgDebug
         MENUITEM "E&xit" ACTION oDlgDebug:Close()
         MENUITEM "&Step" ACTION ( nDebugMode:=0,SetDebugRun() )
         MENU TITLE "&Animate"
            MENUITEM "&0.5 seconds" ACTION ( nAnimaTime:=0.5,nDebugMode:=1,SetDebugRun() )
            MENUITEM "&1 seconds" ACTION ( nAnimaTime:=1,nDebugMode:=1,SetDebugRun() )
            MENUITEM "&3 seconds" ACTION ( nAnimaTime:=3,nDebugMode:=1,SetDebugRun() )
         ENDMENU
         MENUITEM "&Run" ACTION ( nDebugMode:=2,SetDebugRun() )
      ENDMENU

      @ 0,0 BROWSE oBrwData ARRAY SIZE 500,0 STYLE WS_BORDER + WS_VSCROLL ;
          ON SIZE { | o, x | o:Move(,, x ) }

      oBrwData:aArray := aWatches
      oBrwData:AddColumn( HColumn():New( "",{ |v, o | HB_SYMBOL_UNUSED( v ), o:aArray[ o:nCurrent, 1 ] }, "C", 30, 0 ) )
      oBrwData:AddColumn( HColumn():New( "",{ |v, o | HB_SYMBOL_UNUSED( v ), o:aArray[ o:nCurrent, 3 ] }, "C", 1, 0 ) )
      oBrwData:AddColumn( HColumn():New( "",{ |v, o | HB_SYMBOL_UNUSED( v ), o:aArray[ o:nCurrent, 4 ] }, "C", 60, 0 ) )
      @ 0,4 BROWSE oBrwScript ARRAY SIZE 500,236    ;
          FONT oScrFont STYLE WS_BORDER+WS_VSCROLL+WS_HSCROLL ;
          ON SIZE {|o,x,y|o:Move(,,x,y-oSplit:nTop-oSplit:nHeight-64)}

      @ 0,0 SPLITTER oSplit SIZE 600,3 DIVIDE {oBrwData} FROM {oBrwScript} ;
          ON SIZE { | o, x | o:Move(,, x ) }

      oBrwScript:aArray := aScript[3]
#ifdef __GTK__
      oBrwScript:rowCount := 5
      oBrwScript:AddColumn( HColumn():New( "",{|v,o|HB_SYMBOL_UNUSED( v ),Iif(o:nCurrent==i_scr,'>',Iif(aBreakPoints!=Nil.AND.Ascan(aBreakPoints[2],oBrwScript:nCurrent)!=0,'*',' '))},"C",1,0 ) )
#else
      oBrwScript:AddColumn( HColumn():New( "",{|v,o|HB_SYMBOL_UNUSED( v ),Iif(o:nCurrent==i_scr,1,Iif(aBreakPoints!=Nil.AND.Ascan(aBreakPoints[2],oBrwScript:nCurrent)!=0,2,0))},"N",1,0 ) )
      oBrwScript:aColumns[1]:aBitmaps := { { {|n|n==1},oBmpCurr },{ {|n|n==2},oBmpPoint } }
#endif
      oBrwScript:AddColumn( HColumn():New( "",{|v,o|HB_SYMBOL_UNUSED( v ),Left(o:aArray[o:nCurrent],4)},"C",4,0 ) )
      oBrwScript:AddColumn( HColumn():New( "",{|v,o|HB_SYMBOL_UNUSED( v ),Substr(o:aArray[o:nCurrent],6)},"C",80,0 ) )

      oBrwScript:bEnter:= {||AddBreakPoint()}

      @ 0,240 PANEL oPanel OF oDlgDebug SIZE oDlgDebug:nWidth,64 ;
          ON SIZE {|o,x,y|o:Move(,y-64,x)}

#ifdef __GTK__
      @ 10,10 OWNERBUTTON TEXT "Add" SIZE 100, 24 OF oPanel ON CLICK {||AddWatch()}
      @ 10,36 OWNERBUTTON TEXT "Calculate" SIZE 100, 24 OF oPanel ON CLICK {||Calculate()}
#else
      @ 10,10 BUTTON "Add" SIZE 100, 24 OF oPanel ON CLICK {||AddWatch()}
      @ 10,36 BUTTON "Calculate" SIZE 100, 24 OF oPanel ON CLICK {||Calculate()}
#endif
      @ 110,10 EDITBOX oEditExpr CAPTION "" SIZE 380,24 OF oPanel ON SIZE {|o,x|o:Move(,,x-120)}
      @ 110,36 EDITBOX oEditRes CAPTION "" SIZE 380,24 OF oPanel ON SIZE {|o,x|o:Move(,,x-120)}

      ACTIVATE DIALOG oDlgDebug NOMODAL

      oDlgDebug:Move( ,,,400 )
   ENDIF

   IF aScriptCurr[4] != aScript[4]
      IF !Empty( aBreakPoints )
         IF Ascan( aBreaks, {|a|a[1]==aBreakPoints[1]} ) == 0
            Aadd( aBreaks, aBreakPoints )
         ENDIF
         IF ( i := Ascan( aBreaks, {|a|a[1]==aScript[4]} ) ) == 0
            aBreakPoints := Nil
         ELSE
            aBreakPoints := aBreaks[i]
         ENDIF
      ENDIF
      aScriptCurr := aScript
      hwg_Setwindowtext( oDlgDebug:handle, "Script Debugger - " + aScript[1] )
   ENDIF

   oBrwScript:aArray := aScript[3]
   IF ( i_scr := iscr ) == 0
      nDebugMode := 0
      oBrwScript:Top()
   ELSE
      IF aBreakPoints!=Nil .AND. Ascan(aBreakPoints[2],i_scr) != 0
         nDebugMode := 0
      ENDIF
      IF nDebugMode < 2
         FOR i := 1 TO Len( aWatches )
            CalcWatch( i )
         NEXT
         IF !Empty( aWatches )
            oBrwData:Refresh()
         ENDIF
         nFirst := oBrwScript:nCurrent - oBrwScript:rowPos + 1
         oBrwScript:nCurrent := i_scr
         IF i_scr - nFirst >= oBrwScript:rowCount
            oBrwScript:rowPos := 1
         ELSE
            oBrwScript:rowPos := oBrwScript:nCurrent - nFirst + 1
         ENDIF
         oBrwScript:Refresh()
         IF nDebugMode == 1
            nFirst := Seconds()
            DO WHILE Seconds() - nFirst < nAnimaTime
               hwg_ProcessMessage()
            ENDDO
            SetDebugRun()
         ENDIF
      ELSEIF nDebugMode == 2
         SetDebugRun()
      ENDIF
   ENDIF

Return .T.

STATIC FUNCTION dlgDebugClose()

   oDlgDebug := Nil
   SetDebugger( .F. )
   SetDebugRun()
   aBreakPoints := aScriptCurr := Nil
   aBreaks  := {}
   aWatches := {}
   oScrFont:Release()
   oDlgFont:Release()
#ifndef __GTK__
   oBmpCurr:Release()
   oBmpPoint:Release()
#endif

Return .T.

Static Function AddBreakPoint
Local i

   IF aBreakPoints == Nil
      aBreakPoints := { aScriptCurr[4], {} }
   ENDIF
   IF ( i := Ascan( aBreakPoints[2],oBrwScript:nCurrent ) ) == 0
      FOR i := 1 TO Len(aBreakPoints[2])
         IF aBreakPoints[2,i] == 0
            aBreakPoints[2,i] := oBrwScript:nCurrent
            EXIT
         ENDIF
      NEXT
      IF i > Len(aBreakPoints[2])
         Aadd( aBreakPoints[2], oBrwScript:nCurrent )
      ENDIF
   ELSE
      Adel( aBreakPoints[2], i )
      aBreakPoints[2,Len(aBreakPoints[2])] := 0
   ENDIF
   oBrwScript:Refresh()
Return .T.

Static Function AddWatch()
Local xRes, bCodeblock, bOldError, lRes := .T.

#ifdef __GTK__
   IF !Empty( xRes := oEditExpr:GetText() )
#else
   IF !Empty( xRes := hwg_Getedittext( oEditExpr:oParent:handle, oEditExpr:id ) )
#endif
      bOldError := ERRORBLOCK( { | e | MacroError(e) } )
      BEGIN SEQUENCE
         bCodeblock := &( "{||" + xRes + "}" )
      RECOVER
         lRes := .F.
      END SEQUENCE
      ERRORBLOCK( bOldError )
   ENDIF

   IF lRes
      IF Ascan( aWatches, {|s|s[1] == xRes} ) == 0
         Aadd( aWatches, { xRes,bCodeblock, Nil, Nil } )
         CalcWatch( Len(aWatches) )
      ENDIF
      IF oBrwData:nHeight < 20
         oSplit:Move( ,56)
         oBrwScript:Move( ,60,,oDlgDebug:nHeight-oSplit:nTop-oSplit:nHeight-64)
         oBrwData:Move( ,,,56 )
         oDlgDebug:Move( ,,,oDlgDebug:nHeight+4 )
      ENDIF
      oBrwData:Refresh()
   ELSE
      oEditRes:SetText( "Error..." )
   ENDIF
Return .T.

Static Function CalcWatch( n )
Local xRes, bOldError, lRes := .T., cType

   bOldError := ERRORBLOCK( { | e | MacroError(e) } )
   BEGIN SEQUENCE
      xRes := Eval( aWatches[n,2] )
   RECOVER
      lRes := .F.
   END SEQUENCE
   ERRORBLOCK( bOldError )

   IF lRes
      IF ( cType := Valtype( xRes ) ) == "N"
         aWatches[n,4] := Ltrim(Str(xRes))
      ELSEIF cType == "D"
         aWatches[n,4] := Dtoc(xRes)
      ELSEIF cType == "L"
         aWatches[n,4] := Iif(xRes,".T.",".F.")
      ELSEIF cType == "C"
         aWatches[n,4] := xRes
      ELSE
         aWatches[n,4] := "Undefined"
      ENDIF
      aWatches[n,3] := cType
   ELSE
      aWatches[n,4] := "Error..."
      aWatches[n,3] := "U"
   ENDIF

Return .T.

Static Function Calculate()
Local xRes, bOldError, lRes := .T., cType

#ifdef __GTK__
   IF !Empty( xRes := oEditExpr:GetText() )
#else
   IF !Empty( xRes := hwg_Getedittext( oEditExpr:oParent:handle, oEditExpr:id ) )
#endif
      bOldError := ERRORBLOCK( { | e | MacroError(e) } )
      BEGIN SEQUENCE
         xRes := &xRes
      RECOVER
         lRes := .F.
      END SEQUENCE
      ERRORBLOCK( bOldError )
   ENDIF

   IF lRes
      IF ( cType := Valtype( xRes ) ) == "N"
         oEditRes:SetText( Ltrim(Str(xRes)) )
      ELSEIF cType == "D"
         oEditRes:SetText( Dtoc(xRes) )
      ELSEIF cType == "L"
         oEditRes:SetText( Iif(xRes,".T.",".F.") )
      ELSE
         oEditRes:SetText( xRes )
      ENDIF
   ELSE
      oEditRes:SetText( "Error..." )
   ENDIF

Return .T.

STATIC FUNCTION MacroError( /* e */ )

   IF .T.      // compile -w3 -es2
      BREAK
   ENDIF

RETURN .T.

Function scrBreakPoint()

   nDebugMode := 0

Return .T.
