/*
 * $Id: printdos.prg,v 1.4 2004-04-20 18:21:29 sandrorrfreire Exp $
 *
 * CLASS PrintDos
 *
 * Copyright (c) Sandro Freire <sandrorrfreire@yahoo.com.br>
 * for HwGUI By Alexander Kresin
 *
 */
#include "HBClass.ch"
#include "windows.ch"
#include "guilib.ch"
#include "fileio.ch"

#define PF_BUFFERS   2048

#define oFORMFEED               "12"
#define oLASER10CPI             "27,40,115,49,48,72"
#define oLASER12CPI             "27,40,115,49,50,72"
#define oLASER18CPI             "27,40,115,49,56,72"
#define oINKJETDOUBLE           "27,33,32"
#define oINKJETNORMAL           "27,33,00"
#define oINKJETCOMPRESS         "27,33,04"
#define oMATRIXDOUBLE           "14"
#define oMATRIXNORMAL           "18"
#define oMATRIXCOMPRESS         "15"

CLASS PrintDos

     DATA cCompr, cNormal,oText, cDouble AS CHARACTER
     DATA oPorta, oPicture      AS CHARACTER
     DATA orow, oCol            AS NUMERIC
     DATA cEject, nProw, nPcol, fText, gText
     DATA oTopMar               AS NUMERIC
     DATA oLeftMar              AS NUMERIC
     DATA oAns2Oem              AS LOGIC
     DATA oPrintStyle INIT 1 //1 = Matricial   2 = InkJet    3 = LaserJet

     METHOD New(oPorta) CONSTRUCTOR  

     METHOD Say(oProw, oCol, oTexto, oPicture)

     METHOD SetCols(nRow, nCol) 

     METHOD gWrite(oText)

     METHOD NewLine()

     METHOD Eject()

     METHOD Compress()

     METHOD Double()

     METHOD DesCompress()
  
     METHOD Comando()

     METHOD SetPrc(x,y)

     METHOD PrinterFile(oFile)

     METHOD TxttoGraphic(oFile,osize,oPreview)

     METHOD Preview(fname, cTitle)

     METHOD End()

ENDCLASS

METHOD New(oPorta) CLASS PrintDos
     Local oDouble  :={oMATRIXDOUBLE,   oINKJETDOUBLE,   oLASER10CPI}
     Local oNormal  :={oMATRIXNORMAL,   oINKJETNORMAL,   oLASER12CPI}
     Local oCompress:={oMATRIXCOMPRESS, oINKJETCOMPRESS, oLASER18CPI}

     ::oPorta       := Iif(Empty(oPorta),"LPT1",oPorta)

     ::cCompr   := oCompress[::oPrintStyle]
     ::cNormal  := oNormal[::oPrintStyle]
     ::cDouble  := oDouble[::oPrintStyle]
     ::cEject   := oFORMFEED
     ::nProw    := 0
     ::nPcol    := 0
     ::oTopMar  := 0
     ::oAns2Oem :=.t.
     ::oLeftMar := 0
     ::oText    := ""
     
     Iif( oPorta=="GRAPHIC" .or. ;
          oPorta=="PREVIEW"     ,;
          ::gText := ""         ,;      
          ::gText:=fCreate(::oPorta))
          
RETURN SELF


METHOD Comando(oComm1,oComm2, oComm3, oComm4, oComm5, oComm6, oComm7,;
               oComm8,oComm9, oComm10)  CLASS PrintDos

   local nCont := 1
   local cCont
   local oStr := oComm1

   oStr:=Chr( Val (oComm1) )

   IF oComm2  != NIL ;  oStr +=Chr(Val(oComm2 ));   END
   IF oComm3  != NIL ;  oStr +=Chr(Val(oComm3 ));   END
   IF oComm4  != NIL ;  oStr +=Chr(Val(oComm4 ));   END
   IF oComm5  != NIL ;  oStr +=Chr(Val(oComm5 ));   END
   IF oComm6  != NIL ;  oStr +=Chr(Val(oComm6 ));   END
   IF oComm7  != NIL ;  oStr +=Chr(Val(oComm7 ));   END
   IF oComm8  != NIL ;  oStr +=Chr(Val(oComm8 ));   END
   IF oComm9  != NIL ;  oStr +=Chr(Val(oComm9 ));   END
   IF oComm10 != NIL ;  oStr +=Chr(Val(oComm10));   END

 
   If ::oAns2Oem
     ::oText += ANSITOOEM(oStr)
   Else
     ::oText += oStr
   EndIf

Return Nil
 

METHOD gWrite(oText)  CLASS PrintDos

    If ::oAns2Oem
       ::oText += ANSITOOEM(oText)
       ::nPcol += len(ANSITOOEM(oText))
    Else
       ::oText += oText
       ::nPcol += len(oText)
    EndIf


Return Nil

METHOD Eject()   CLASS PrintDos
    
     fWrite( ::gText, ::oText )
     
     If ::oAns2Oem
        fWrite( ::gText, ANSITOOEM(Chr(13)+Chr(10)+Chr(Val(::cEject))))
        fWrite(::gText, ANSITOOEM(Chr(13)+Chr(10))) 
     Else
        fWrite( ::gText,Chr(13)+Chr(10)+Chr(Val(::cEject)))
        fWrite(::gText, Chr(13)+Chr(10))
     EndIf

     ::oText :=""
     ::nProw := 0
     ::nPcol := 0
     
Return Nil

METHOD Compress() CLASS PrintDos

     ::Comando(::cCompr)

Return Nil

METHOD Double() CLASS PrintDos

     ::Comando(::cDouble)

Return Nil

METHOD DesCompress() CLASS PrintDos

     ::Comando(::cNormal)

Return Nil

METHOD NewLine() CLASS PrintDos
 
    If ::oAns2Oem
      ::oText += ANSITOOEM(Chr(13)+Chr(10))
    Else
      ::oText += Chr(13)+Chr(10)
    EndIf
    ::nPcol:=0
Return Nil

METHOD Say(oProw, oPcol, oTexto, oPicture) CLASS PrintDos
 
    If Valtype(oTexto)=="N"
        
       If !Empty(oPicture) .or. oPicture#Nil
          oTexto:=Transform(oTexto, oPicture)
       Else
          oTexto:=Str(oTexto)  
       Endif   
        
    Elseif Valtype(oTexto)=="D"
       oTexto:=DTOC(oTexto)
    Else   
       If !Empty(oPicture) .or. oPicture#Nil
          oTexto:=Transform(oTexto, oPicture)
       Endif
    EndIf   
    
    ::SetCols(oProw, oPcol)

    ::gWrite(oTexto)

Return Nil

METHOD SetCols(nProw, nPcol) CLASS PrintDos
     
     IF ::nProw > nProw
        ::Eject()
     ENDIF

     IF ::nProw < nProw
        Do While ::nProw<nProw
           ::NewLine()
           ++::nProw
        EndDo
     ENDIF
      
     IF nProw == ::nProw  .AND. nPcol < ::nPcol
          ::Eject()
     ENDIF
     
     IF nPcol > ::nPcol
          ::gWrite(Space(nPcol-::nPcol))
     ENDIF

Return Nil
           
METHOD SetPrc(x,y) CLASS PrintDos
::nProw:=x
::nPCol:=y
Return Nil

METHOD End() CLASS PrintDos

   fWrite( ::gText, ::oText )
   fClose( ::gText )

Return Nil

METHOD PrinterFile(fname) CLASS PrintDos
LOCAL strbuf := Space(PF_BUFFERS)
Local han, nRead

   IF !File( fname )
      MsgStop("Error open file "+fname,"Error")
      Return .F.
   EndIf

   han := FOPEN( fname, FO_READWRITE + FO_EXCLUSIVE )

   IF han <> - 1

         DO while .t.

            nRead := fRead(han, @strBuf, PF_BUFFERS)
            
            if nRead=0 ; Exit ; Endif

            IF fWrite(::gText, Left(strbuf, nRead)) < nRead
               ::ErrosAnt := fError()
               fClose(han)
               RETURN .F.
            ENDIF

         EndDo
                
   ELSE
   
         MsgStop( "Can't Open port" )
         Fclose( han )
         
   ENDIF
     
RETURN .T.
  
Function wProw(oPrinter)
Return oPrinter:nProw

Function wPCol(oPrinter)
Return oPrinter:nPcol

Function wSetPrc(x,y,oPrinter)
oPrinter:SetPrc(x,y)
Return Nil

METHOD TxttoGraphic(fName,osize,oPreview) CLASS PrintDos

LOCAL strbuf := Space(2052), poz := 2052, stroka
Local han := FOPEN( fname, FO_READ + FO_SHARED )
Local i, itemName, aItem, res := .T., sFont
Local oCol:=10, oPage:=1
Local oFont := HFont():Add( "Courier New",0,oSize )
Local oPrinter := HPrinter():New()

oPrinter:StartDoc( oPreview  )
oPrinter:StartPage()

SelectObject( oPrinter:hDC,oFont:handle )

IF han <> - 1
   DO WHILE .T.
      stroka := RDSTR( han,@strbuf,@poz,2052 )
      IF LEN( stroka ) = 0
         EXIT
      ENDIF
      IF Left( stroka,1 ) == Chr(12)
         oPrinter:EndPage()
         oPrinter:StartPage()
         ++oPage
      ENDIF
      oPrinter:Say( stroka, 100, ocol,300,26,,oFont )
      oCol:=oCol+30
   
   ENDDO
   Fclose( han )
ELSE
   MsgStop( "Can't open "+fname )
   Return .F.
ENDIF
oPrinter:EndPage()
oPrinter:EndDoc()
oPrinter:Preview() 
oPrinter:End()     
oFont:Release()

Return .T.
 
METHOD Preview(fName,cTitle) CLASS PrintDos

LOCAL strbuf := Space(2052), poz := 2052, stroka
Local han := FOPEN( fname, FO_READ + FO_SHARED )
Local i, itemName, aItem, res := .T., sFont
Local oCol:=10, oPage:=1, nPage:=1
Local oFont := HFont():Add( "Courier New",0,-13 )
Local oText := {"" }
Local oDlg
Local oEdit 
IF han <> - 1
   DO WHILE .T.
      stroka := RDSTR( han,@strbuf,@poz,2052 )
      IF LEN( stroka ) = 0
         EXIT
      ENDIF
      IF Left( stroka,1 ) == Chr(12)
         AADD(oText,"")
         ++oPage
      ENDIF
      oText[oPage]+=stroka + Chr(13) + Chr(10)
      oCol:=oCol+30  
   ENDDO
   Fclose( han )
ELSE
   MsgStop( "Can't open "+fname )
   Return .F.
ENDIF

oEdit:=oText[nPage]

Iif(cTitle==Nil,cTitle:="Print Preview",cTitle:=cTitle)

INIT DIALOG oDlg TITLE cTitle ;
        AT 92,61 SIZE 673,499

   @ 88,19 EDITBOX oEdit ID 1001 SIZE 548,465 STYLE WS_VSCROLL + WS_HSCROLL + ES_AUTOHSCROLL + ES_MULTILINE ;
        COLOR 16777088 BACKCOLOR 0  //Blue to Black
//       COLOR 16711680 BACKCOLOR 16777215  //Black to Write      
   @ 6, 30 BUTTON "<<"    ON CLICK {||nPage:=PrintDosAnt(nPage,oText)} SIZE 69,32 
   @ 6, 80 BUTTON ">>"    ON CLICK {||nPage:=PrintDosNext(oPage,nPage,oText)} SIZE 69,32 
   @ 6,130 BUTTON "Print" ON CLICK {||PrintDosPrint(oText)} SIZE 69,32 
   @ 6,180 BUTTON "Close" ON CLICK {||EndDialog()} SIZE 69,32 

   oDlg:Activate()
 
Return .T.

Static Function PrintDosPrint(oText)
Local i
Local nText:=fCreate("LPT1")
FOR i:=1 to Len(oText)
    fWrite( nText, oText[i])
NEXT   
fClose(nText)
Return Nil


Static Function PrintDosAnt(nPage, oText)
Local oDlg:=GetModalhandle()
nPage:=--nPage
If nPage<1; nPage :=1 ; Endif
SetDlgItemText( oDlg, 1001, oText[nPage] )
Return nPage

Static Function PrintDosNext(oPage,nPage, oText)
Local oDlg:=GetModalhandle()
nPage:=++nPage
If nPage>oPage; nPage := oPage ; Endif
SetDlgItemText( oDlg, 1001, oText[nPage] )
Return nPage

