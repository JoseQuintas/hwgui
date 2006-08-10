#define CRLF Chr(13) + Chr(10)
*------------------------------------------------------------------------------------------------------------------------------------
Function Main
*------------------------------------------------------------------------------------------------------------------------------------
   Local aFiles := Directory( "*.xml" ), i
   Local cFile, cText
   
   For i:= 1 to Len( aFiles )
   
      cFile:= StrTran( Lower( Alltrim( aFiles[i,1] ) ), "xml", "frm" )
      
      If File( cFile )
         fErase( cFile )
      EndIF

      cText := "/*" + CRLF + "FORM HwGUI Designer : " + cFile + CRLF + "Date: " + DTOC (Date() ) + CRLF + "*/" + CRLF
      
      cText += "Function " + StrTran( cFile, ".frm", "" ) + CRLF
      cText += "   Local cXml " + CRLF + CRLF
      cText += "   TEXT INTO cXml " + CRLF
      cText += Memoread( alltrim( aFiles[i,1] ) ) + CRLF
      cText += "   ENDTEXT " + CRLF + CRLF
      cText += "Return cXml"+ CRLF
      
      
      Memowrit( cFile, cText )
      
      ? "Created " + cFile 
          
   Next
   
Return Nil   
   
   
   
   