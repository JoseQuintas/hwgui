/*
 *$Id: hwmake.prg,v 1.1 2008-11-13 13:59:46 sandrorrfreire Exp $
 *
 * HWGUI - Harbour Win32 GUI library 
 * 
 * HwMake
 * Copyright 2004 Sandro R. R. Freire <sandrorrfreire@yahoo.com.br>
 * www - http://www.lumainformatica.com.br
*/

#include "windows.ch"
#include "guilib.ch"
#DEFINE  ID_EXENAME     10001
#DEFINE  ID_LIBFOLDER   10002
#DEFINE  ID_INCFOLDER   10003
#DEFINE  ID_PRGFLAG     10004
#DEFINE  ID_CFLAG       10005
#DEFINE  ID_PRGMAIN     10006
FUNCTION Main
Local oFont
Local aBrowse1, aBrowse2, aBrowse3, aBrowse4
LOCAL oPasta  := DiskName()+":\"+CurDir()+"\"
Local vGt1:=Space(80)
Local vGt2:=Space(80)
Local vGt3:=Space(80)
Local vGt4:=Space(80)
Local vGt5:=Space(80)
Local vGt6:=Space(80)
Local aFiles1:={""}, aFiles2:={""}, aFiles3:={""}, aFiles4:={""}
Private cDirec:=DiskName()+":\"+CurDir()+"\"
If !File(cDirec+"hwmake.ini")
  Hwg_WriteIni( 'Config', 'Dir_HwGUI', "C:\HwGUI", cDirec+"hwmake.ini" )
  Hwg_WriteIni( 'Config', 'Dir_HARBOUR', "C:\xHARBOUR", cDirec+"hwmake.ini" )
  Hwg_WriteIni( 'Config', 'Dir_BCC55', "C:\BCC55", cDirec+"hwmake.ini" )
  Hwg_WriteIni( 'Config', 'Dir_OBJ', "./OBJ", cDirec+"hwmake.ini" )
EndIf
 
Private lSaved:=.F.
Private oBrowse1, oBrowse2, oBrowse3
Private oDlg
PRIVATE oButton1, oExeName, oLabel1, oLibFolder, oButton4, oLabel2, oIncFolder, oLabel3, oButton3, oPrgFlag, oLabel4, oCFlag, oLabel5, oButton2, oMainPrg, oLabel6, oTab

   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -12
   
   INIT DIALOG oDlg CLIPPER NOEXIT TITLE "HwGUI Build Projects for BCC55" ;
        AT 213,195 SIZE 513,265  font oFont

   @ 14,16 TAB oTAB ITEMS {} SIZE 391,242

   BEGIN PAGE "Config" Of oTAB
      @  20,44 SAY oLabel1 CAPTION "Exe Name" SIZE 80,22  
      @ 136,44 GET oExeName VAR vGt1 ID ID_EXENAME  SIZE 206,24  

      @  20,74 SAY oLabel2 CAPTION "Lib Folder" SIZE 80,22  
      @ 136,74 GET oLibFolder  VAR vGt2 ID ID_LIBFOLDER SIZE 234,24  

      @  20,104 SAY oLabel3 CAPTION "Include Folder" SIZE 105,22  
      @ 136,104 GET oIncFolder VAR vGt3 ID ID_INCFOLDER   SIZE 234,24  

      @  20,134 SAY oLabel4 CAPTION "PRG Flags" SIZE 80,22  
      @ 136,134 GET oPrgFlag VAR vGt4 ID ID_PRGFLAG  SIZE 230,24  

      @  20,164 SAY oLabel5 CAPTION "C Flags" SIZE 80,22  
      @ 136,164 GET oCFlag VAR vGt5  ID ID_CFLAG SIZE 230,24  
 
      @  20,194 SAY oLabel6 CAPTION "Main PRG" SIZE 80,22  
      @ 136,194 GET oMainPrg VAR vGt6 ID ID_PRGMAIN  SIZE 206,24  
      @ 347,194 OWNERBUTTON    SIZE 24,24   ;
          ON CLICK {||searchFileName("xBase Files *.prg ", oMainPrg, "*.prg")};//       FLAT;
          TEXT "..." ;//BITMAP "SEARCH" FROM RESOURCE TRANSPARENT COORDINATES 0,0,0,0 ;
          TOOLTIP "Search main file" 

   END PAGE of oTAB
   BEGIN PAGE "Prg (Files)" of oTAB
      @ 21,29 BROWSE oBrowse1 ARRAY of oTAB ON CLICK {||SearchFile(oBrowse1,"*.prg")};
 	            STYLE WS_VSCROLL + WS_HSCROLL   SIZE 341,170  
      createarlist(oBrowse1,aFiles1)
      obrowse1:acolumns[1]:heading := "File Names"
      obrowse1:acolumns[1]:length := 50
      oBrowse1:bcolorSel := VColor( "800080" )
      oBrowse1:ofont := HFont():Add( 'Arial',0,-12 )
      @ 10, 205 BUTTON "Add"     SIZE 60,25  on click {||SearchFile(oBrowse1, "*.prg")}  
      @ 70, 205 BUTTON "Delete"  SIZE 60,25  on click {||Adel(oBrowse1:aArray, oBrowse1:nCurrent),oBrowse1:Refresh()}

   END PAGE of oTAB
   BEGIN PAGE "C (Files)" of oTAB
      @ 21,29 BROWSE oBrowse2 ARRAY of oTAB ON CLICK {||SearchFile(oBrowse2, "*.c")};
 	            STYLE WS_VSCROLL + WS_HSCROLL   SIZE 341,170  
      createarlist(oBrowse2,aFiles2)
      obrowse2:acolumns[1]:heading := "File Names"
      obrowse2:acolumns[1]:length := 50
      oBrowse2:bcolorSel := VColor( "800080" )
      oBrowse2:ofont := HFont():Add( 'Arial',0,-12 )
      @ 10, 205 BUTTON "Add"     SIZE 60,25  on click {||SearchFile(oBrowse2, "*.c")}  
      @ 70, 205 BUTTON "Delete"  SIZE 60,25  on click {||Adel(oBrowse1:aArray, oBrowse2:nCurrent),oBrowse2:Refresh()}
   END PAGE of oTAB
   BEGIN PAGE "Lib (Files)" of oTAB
      @ 21,29 BROWSE oBrowse3 ARRAY of oTAB ON CLICK {||SearchFile(oBrowse3, "*.lib")};
 	            STYLE WS_VSCROLL + WS_HSCROLL   SIZE 341,170  
      createarlist(oBrowse3,aFiles3)
      obrowse3:acolumns[1]:heading := "File Names"
      obrowse3:acolumns[1]:length := 50
      oBrowse3:bcolorSel := VColor( "800080" )
      oBrowse3:ofont := HFont():Add( 'Arial',0,-12 )
      @ 10, 205 BUTTON "Add"     SIZE 60,25  on click {||SearchFile(oBrowse3, "*.lib")}  
      @ 70, 205 BUTTON "Delete"  SIZE 60,25  on click {||Adel(oBrowse3:aArray, oBrowse3:nCurrent),oBrowse3:Refresh()}
   END PAGE of oTAB
   BEGIN PAGE "Resource (Files)" of oTAB
      @ 21,29 BROWSE oBrowse4 ARRAY of oTAB ON CLICK {||SearchFile(oBrowse3, "*.rc")};
 	            STYLE WS_VSCROLL + WS_HSCROLL   SIZE 341,170  
      createarlist(oBrowse4,aFiles4)
      obrowse4:acolumns[1]:heading := "File Names"
      obrowse4:acolumns[1]:length := 50
      oBrowse4:bcolorSel := VColor( "800080" )
      oBrowse4:ofont := HFont():Add( 'Arial',0,-12 )
      @ 10, 205 BUTTON "Add"     SIZE 60,25  on click {||SearchFile(oBrowse4, "*.rc")}  
      @ 70, 205 BUTTON "Delete"  SIZE 60,25  on click {||Adel(oBrowse4:aArray, oBrowse4:nCurrent),oBrowse4:Refresh()}
   END PAGE of oTAB
   
   @ 419, 20 BUTTON oButton1 CAPTION "Build" on Click {||BuildApp()} SIZE 78,52  
   @ 419, 80 BUTTON oButton2 CAPTION "Exit" on Click {||EndDialog()}  SIZE 78,52  
   @ 419,140 BUTTON oButton3 CAPTION "Open" on Click {||ReadBuildFile()}  SIZE 78,52  
   @ 419,200 BUTTON oButton4 CAPTION "Save" on Click {||SaveBuildFile()}   SIZE 78,52  

   ACTIVATE DIALOG oDlg
RETURN

Static Function SearchFile(oBrow, oFile)
Local oTotReg:={}, i
Local aSelect:=SelectMultipleFiles("xBase Files ("+oFile+")", oFile ) 
if len(aSelect) ==0
   return Nil
endif
if LEN(oBrow:aArray) == 1 .and. obrow:aArray[1]=="" 
   obrow:aArray := {}
endif
For i:=1 to Len(oBrow:aArray)
  AADD(oTotReg, oBrow:aArray[i])  
Next
For i:=1 to Len(aSelect)
  AADD(oTotReg, aSelect[i])  
Next
obrow:aArray := oTotReg
obrow:refresh()
Return Nil

Static Function SearchFileName(nName, oGet, oFile)
Local oTextAnt:=oGet:GetText()
Local fFile:=SelectFile(nName+" ("+oFile+")", oFile,,,.T. ) 
If !Empty(oTextAnt)
   fFile:=oTextAnt //
endif   
oGet:SetText(fFile)
oGet:Refresh()
Return Nil


Function ReadBuildFile()
Local cLibFiles, oBr1:={}, oBr2:={}, oBr3:={}, oBr4:={}, oSel1, oSel2, oSel3, i, oSel4
Local aPal:=""
Local cFolderFile:=SelectFile("HwGUI File Build (*.bld)", "*.bld" ) 
if empty(cFolderFile); Return Nil; Endif
   
oExeName:SetText( Hwg_GetIni( 'Config', 'ExeName' , , cFolderFile ))
oLibFolder:SetText(Hwg_GetIni( 'Config', 'LibFolder' , , cFolderFile ))
oIncFolder:SetText(Hwg_GetIni( 'Config', 'IncludeFolder' , , cFolderFile ))
oPrgFlag:SetText(Hwg_GetIni( 'Config', 'PrgFlags' , , cFolderFile ))
oCFlag:SetText(Hwg_GetIni( 'Config', 'CFlags' , , cFolderFile ))
oMainPrg:SetText(Hwg_GetIni( 'Config', 'PrgMain' , , cFolderFile ))

For i:=1 to 300
    oSel1:=Hwg_GetIni( 'FilesPRG', Alltrim(Str(i)) , , cFolderFile )
    if !empty(oSel1) //.or. oSel1#Nil
        AADD(oBr1, oSel1)
    EndIf
Next
    
  
For i:=1 to 300
    oSel2:=Hwg_GetIni( 'FilesC', Alltrim(Str(i)) , , cFolderFile )
    if !empty(oSel2) //.or. oSel2#Nil
        AADD(oBr2, oSel2)
    EndIf
Next

For i:=1 to 300
    oSel3:=Hwg_GetIni( 'FilesLIB', Alltrim(Str(i)) , , cFolderFile )
    if !empty(oSel3) //.or. oSel3#Nil
        AADD(oBr3, oSel3)
    EndIf
Next

For i:=1 to 300
    oSel4:=Hwg_GetIni( 'FilesRES', Alltrim(Str(i)) , , cFolderFile )
    if !empty(oSel4) //.or. oSel4#Nil
        AADD(oBr4, oSel4)
    EndIf
Next

oBrowse1:aArray:=oBr1  
oBrowse2:aArray:=oBr2  
oBrowse3:aArray:=oBr3  
oBrowse4:aArray:=oBr4  
oBrowse1:Refresh()
oBrowse2:Refresh()
oBrowse3:Refresh()
oBrowse4:Refresh()

Return Nil

*-------------------------------------------------------------------------------------
Function cFileNoExt( cArq )
*-------------------------------------------------------------------------------------
Local n
n:=At( ".", cArq )
If n > 0
   Return Substr( cArq, 1, n - 1 )
Endif

Return cArq   

Function cFileNoPath( cArq ) 
Local i
Local cDest := ""
Local cLetra

For i:=1 to Len( cArq )
   
   cLetra := Substr( cArq, i, 1 )
   If cLetra == "\"
      cDest := ""
   Else   
      cDest += cLetra
   EndIf         
   
Next

Return cDest

Function SaveBuildFile()
Local cLibFiles, i, oNome, g
Local cFolderFile:=SaveFile("*.bld", "HwGUI File Build (*.bld)", "*.bld" ) 
if empty(cFolderFile); Return Nil; Endif
if file(cFolderFile)
   If(MsgYesNo("File "+cFolderFile+" EXIT ..Replace?"))
     Erase( cFolderFile )
   Else
     MsgInfo("No file SAVED.")
     Return Nil
   EndIf
EndIf     
Hwg_WriteIni( 'Config', 'ExeName'       ,oExeName:GetText(), cFolderFile )
Hwg_WriteIni( 'Config', 'LibFolder'     ,oLibFolder:GetText(), cFolderFile )
Hwg_WriteIni( 'Config', 'IncludeFolder' ,oIncFolder:GetText(), cFolderFile )
Hwg_WriteIni( 'Config', 'PrgFlags'      ,oPrgFlag:GetText(), cFolderFile )
Hwg_WriteIni( 'Config', 'CFlags'        ,oCFlag:GetText(), cFolderFile )
Hwg_WriteIni( 'Config', 'PrgMain'       ,oMainPrg:GetText(), cFolderFile )
oNome:=""

if Len(oBrowse1:aArray)>=1
   for i:=1 to Len(oBrowse1:aArray)

      if !empty(oBrowse1:aArray[i])
 
         Hwg_WriteIni( 'FilesPRG', Alltrim(Str(i)),oBrowse1:aArray[i], cFolderFile )
   
      EndIf    
      
    Next    

endif

if Len(oBrowse2:aArray)>=1
   for i:=1 to Len(oBrowse2:aArray)
      if !empty(oBrowse2:aArray[i])
         Hwg_WriteIni( 'FilesC', Alltrim(Str(i)),oBrowse2:aArray[i], cFolderFile )
     endif    
   Next     
endif

if Len(oBrowse3:aArray)>=1
   for i:=1 to Len(oBrowse3:aArray)
      if !empty(oBrowse3:aArray[i])
         Hwg_WriteIni( 'FilesLIB', Alltrim(Str(i)),oBrowse3:aArray[i], cFolderFile )
      endif   
   Next     
endif   

if Len(oBrowse4:aArray)>=1
   for i:=1 to Len(oBrowse4:aArray)
      if !empty(oBrowse4:aArray[i])
         Hwg_WriteIni( 'FilesRES', Alltrim(Str(i)),oBrowse4:aArray[i], cFolderFile )
     endif   
   Next     
endif   

Msginfo("File "+cFolderFile+" saved","HwGUI Build")
Return Nil

Function BuildApp() 
Local cExeHarbour
Local cHwGUI,cHarbour,cBCC55, cObj
LOCAL cObjFileAttr  , nObjFileSize
LOCAL dObjCreateDate, nObjCreateTime
LOCAL dObjChangeDate, nObjChangeTime
Local cObjName, I
LOCAL cPrgFileAttr  , nPrgFileSize
LOCAL dPrgCreateDate, nPrgCreateTime
LOCAL dPrgChangeDate, nPrgChangeTime
Local cPrgName
Local lAll := MsgYesNo("Build All Fontes?", "Attention" )
Local lCompile
Local cList := ""
Local cMake
Local CRLF := Chr(13) + Chr(10)
Local cListObj := "c0w32.obj" + CRLF
Local cListRes := ""
Local cMainPrg := Alltrim( Lower( cFileNoPath( cFileNoExt( oMainPrg:GetText() ) ) ) )
If File(cDirec+"hwmake.Ini")
   cHwGUI  := Hwg_GetIni( 'Config', 'DIR_HwGUI'   , , cDirec+"hwmake.Ini" )
   cHarbour:= Hwg_GetIni( 'Config', 'DIR_HARBOUR' , , cDirec+"hwmake.Ini")
   cBCC55  := Hwg_GetIni( 'Config', 'DIR_BCC55'   , , cDirec+"hwmake.Ini" )
   cObj    := Hwg_GetIni( 'Config', 'DIR_OBJ'     , , cDirec+"hwmake.Ini" )
Else 
   cHwGUI  :="C:\HWGUI"
   cHarbour:="C:\Harbour"
   cBCC55  :="C:\BCC55"   
   cObj    :=".\OBJ"
EndIf

Makedir( cObj )

cExeHarbour := cHarbour+"\bin\harbour.exe"
If !File( cExeHarbour )
   MsgInfo( "Not exiSt HARBOUR.EXE!!!" )
   Return Nil
EndIf

//PrgFiles
i := Ascan( oBrowse1:aArray, {|x| At( cMainPrg, x ) > 0 } )
If i == 0
   AADD(  oBrowse1:aArray, Alltrim( oMainPrg:GetText() ) )
EndIf   

For Each i in oBrowse1:aArray 
   cObjName := cObj+"\"+cFileNoPath( cFileNoExt( i ) ) + ".obj"
   cPrgName := i
   lCompile := .F.
   If lAll
      lCompile := .T.
   Else   
      If File( cObjName  )
         FileStats( cObjName, @cObjFileAttr  , @nObjFileSize, @dObjCreateDate, @nObjCreateTime, @dObjChangeDate, @nObjChangeTime  )
         FileStats( cPrgName, @cPrgFileAttr  , @nPrgFileSize, @dPrgCreateDate, @nPrgCreateTime, @dPrgChangeDate, @nPrgChangeTime  )
         If dObjChangeDate <= dPrgChangeDate .and.  nObjChangeTime <  nPrgChangeTime
            lCompile := .T.
         EndIF   
      Else
         lCompile := .T.
      EndIf      
   EndIF       

   If lCompile 
      if !ShellExecute(  cExeHarbour,, cPrgName + " -o" + cObj + " " + Alltrim( oPrgFlag:GetText() ) + " -n -i"+cHarbour+"\include;"+cHwGUI+"\include;"+oIncFolder:GetText() )        
         MsgInfo( "Error to execute HARBOUR.EXE!!!" )         
         Return Nil
      EndIf
      If !File( cObjName )
         MsgInfo("No Created " + cObjName + "!" )
         Return nil
      EndIF
   EndIf
   If At( cMainPrg,cObjName ) == 0
      cList    += cFilenoExt( cObjName ) + ".c "     
      cListObj += cObjName + CRLF
   EndIf   
Next

cListObj := cObj + "\" + cMainPrg + ".obj" + CRLF + cListObj

FOR EACH i in oBrowse2:aArray     
   cList += i + " "
   cListObj += cObj+"\"+cFileNoPath( cFilenoExt( i ) ) + ".obj"
Next

If !ShellExecute( cBCC55 + "bcc32.exe" ,, "-v -y -c " +Alltrim( oCFlag:GetText() ) + " -O2 -tW -M -I"+cHarbour+"\include;"+cHwGUI+"\include;"+cBCC55+"\include "+ cList ) 
   MsgInfo("No Created Object files!" )
   Return nil
EndIF
         
//ResourceFiles
For Each i in oBrowse4:aArray    
   If !ShellExecute( cBCC55 + "\brc32 ",,"-r "+i+" -fo"+cObj+"\"+cFileNoPath( cFileNoExt( i ) ) )
      MsgInfo("Error in Resource File " + i + "!" )
      Return Nil
   EndIf   
   cListRes += cObj+"\"+cFileNoPath( cFileNoExt( i ) ) + ".res" + CRLF
Next

cMake := cListObj
cMake += oExeName:GetText() + CRLF
cMake += cFileNoExt( oExeName:GetText() + ".map" ) + CRLF
cMake += RetLibrary( cHwGUI, cHarbour, oBrowse3:aArray )
cMake += cListRes
For EACH i in oBrowse4:aArray
   cMake += i + CRLF
Next

If File( cMainPrg + ".bc ")
   fErase( cMainPrg + ".bc " )
EndIF   

If !ShellExecute( cBCC55 + "\ilink32 ",," -Gn -aa -Tpe @"+cMainPrg + ".bc" )
      MsgInfo("No link file " + cMainPrg +"!" ) 
      Return Nil
EndIf

If File( cMainPrg + ".bc ")
   fErase( cMainPrg + ".bc " )
EndIF   
   
Return Nil
 

Function RetLibrary( cHwGUI, cHarbour, aLibs )
Local i, cLib, CRLF := Chr(13) + Chr(10)
Local lMt := .F.
cLib := cHwGUI + "\lib\hwgui.lib " + CRLF
cLib += cHwGUI + "\lib\procmisc.lib " + CRLF
cLib += cHwGUI + "\lib\hbxml.lib " + CRLF
cLib += If( File(  cHarbour + "\lib\rtl"+If(lMt, cMt, "" )+".lib" ) ,  cHarbour + "\lib\rtl"+If(lMt, cMt, "" )+".lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\hbrtl"+If(lMt, cMt, "" )+".lib" )  ,  cHarbour + "\lib\hbrtl"+If(lMt, cMt, "" )+".lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\vm"+If(lMt, cMt, "" )+".lib" )  ,  cHarbour + "\lib\vm"+If(lMt, cMt, "" )+".lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\hbvm.lib" )  ,  cHarbour + "\lib\hbvm.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\gtgui.lib" )  ,  cHarbour + "\lib\gtgui.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\gtwin.lib" )  ,  cHarbour + "\lib\gtwin.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\lang.lib" )  ,  cHarbour + "\lib\lang.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\hblang.lib" )  ,  cHarbour + "\lib\hblang.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\codepage.lib" )  ,  cHarbour + "\lib\codepage.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\hbcpage.lib" )  ,  cHarbour + "\lib\hbcpage.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\macro"+If(lMt, cMt, "" )+".lib" )  ,  cHarbour + "\lib\macro"+If(lMt, cMt, "" )+" "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\hbmacro.lib" )  ,  cHarbour + "\lib\hbmacro.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\rdd"+If(lMt, cMt, "" )+".lib" )  ,  cHarbour + "\lib\rdd"+If(lMt, cMt, "" )+" " + CRLF, "" )
cLib += If( File(  cHarbour + "\lib\hbrdd.lib") ,  cHarbour + "\lib\hbrdd.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\dbfntx"+If(lMt, cMt, "" )+".lib" )  ,  cHarbour + "\lib\dbfntx"+If(lMt, cMt, "" )+" "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\rddntx.lib" ) ,  cHarbour + "\lib\rddntx.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\dbfcdx"+If(lMt, cMt, "" )+".lib" )  ,  cHarbour + "\lib\dbfcdx"+If(lMt, cMt, "" )+" "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\rddcdx.lib") ,  cHarbour + "\lib\rddcdx.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\dbffpt"+If(lMt, cMt, "" )+".lib" )  ,  cHarbour + "\lib\dbffpt"+If(lMt, cMt, "" )+" "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\rddfpt.lib") ,  cHarbour + "\lib\rddfpt.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\sixcdx"+If(lMt, cMt, "" )+".lib" )  ,  cHarbour + "\lib\sixcdx"+If(lMt, cMt, "" )+" "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\hbsix.lib") ,  cHarbour + "\lib\hbsix.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\common.lib") ,  cHarbour + "\lib\common "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\hbcommon.lib") ,  cHarbour + "\lib\hbcommon.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\debug.lib") ,  cHarbour + "\lib\debug.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\hbdebug.lib") ,  cHarbour + "\lib\hbdebug.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\pp.lib") ,  cHarbour + "\lib\pp.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\hbpp.lib" ),  cHarbour + "\lib\hbpp.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\hsx.lib") ,  cHarbour + "\lib\hsx.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\hbhsx.lib") ,  cHarbour + "\lib\hbhsx.lib "+ CRLF, "" )
cLib += cHarbour + "\lib\hbsix.lib "+ CRLF
cLib += If( File(  cHarbour + "\lib\pcrepos.lib" ),  cHarbour + "\lib\pcrepos.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\hbpcre.lib" ),  cHarbour + "\lib\hbpcre.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\zlib.lib" ),  cHarbour + "\lib\zlib.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\hbzlib.lib" ),  cHarbour + "\lib\hbzlib.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\hbw32.lib" ),  cHarbour + "\lib\hbw32.lib "+ CRLF, "" )
cLib += If( File(  cHarbour + "\lib\hbwin.lib" ),  cHarbour + "\lib\hbwin.lib "+ CRLF, "" )
cLib += cBcc55 + "\lib\cw32.lib " + CRLF
cLib += cBcc55 + "\lib\import32.lib" + CRLF
FOR EACH i in aLibs
   cLib += i + CRLF
Next
Return cLib
 
