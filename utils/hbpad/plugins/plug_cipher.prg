
#include "hwgui.ch"

#define P_X             1
#define P_Y             2

FUNCTION Plug_cipher

   LOCAL oEdit := HWindow():GetMain():oEdit
   LOCAL lSelected := !Empty( oEdit:aPointM2[P_Y] ), cSelected, cRes, cEncoded
   LOCAL oDlg
   LOCAL cHelp := "  This plugin may encrypt any text snippet" + Chr(13)+Chr(10) + ;
      " from an editor window and review decrypted." + Chr(13)+Chr(10) + Chr(13)+Chr(10) + ;
      "  To encrypt the text you need to select it" + Chr(13)+Chr(10) + ;
      " an editor window before to call the plugin." + Chr(13)+Chr(10) + Chr(13)+Chr(10) + ;
      "  To decrypt it you need to place the cursor" + Chr(13)+Chr(10) + ;
      " to a line with encrypted text in an editor" + Chr(13)+Chr(10) + ;
      " window before to call the plugin."

   //hwg_Writelog( "/"+Left( cText,Len(cPrefix) )+"/"+Right(cText,Len(cSuffix))+"/" )
   INIT DIALOG oDlg TITLE "Encryption/decryption" AT 50, 50 SIZE 400, 230 FONT HWindow():GetMain():oFont

   IF lSelected
      cSelected := oEdit:GetText( oEdit:aPointM1, oEdit:aPointM2 )
      @ 70, 30 BUTTON "Encrypt selected text" SIZE 260, 30 ON CLICK ;
         {||cRes := plug_ciph_Encrypt(cSelected), plug_ciph_Replace(cRes), hwg_EndDialog()}
   ELSE
      @ 20, 30 SAY "No text selected to encrypt" SIZE 380, 26 STYLE SS_CENTER
   ENDIF

   cEncoded := plug_ciph_GetText()
   //hwg_writelog( cEncoded )
   IF !Empty( cEncoded )
      @ 70, 70 BUTTON "Decrypt pointed text" SIZE 260, 30 ON CLICK ;
         {||cRes:=plug_ciph_Decrypt(cEncoded),hwg_EndDialog(),plug_ciph_View(cRes)}
   ELSE
      @ 20, 70 SAY "No encrypted text under cursor" SIZE 380, 26 STYLE SS_CENTER
   ENDIF

   @ 80, 180  BUTTON "Help" SIZE 100, 32 ON CLICK {||plug_ciph_View(cHelp)}
   @ 220, 180  BUTTON "Close" SIZE 100, 32 ON CLICK {||hwg_EndDialog()}

   ACTIVATE DIALOG oDlg

   RETURN Nil

STATIC FUNCTION plug_ciph_Replace( cText )

   LOCAL oEdit := HWindow():GetMain():oEdit
   LOCAL P1 := Iif( oEdit:aPointM2[P_Y] >= oEdit:aPointM1[P_Y], oEdit:aPointM1, oEdit:aPointM2 )

   oEdit:DelText( oEdit:aPointM1, oEdit:aPointM2, .F. )
   oEdit:aPointM2[P_Y] := 0
   oEdit:InsText( P1, cText )
   oEdit:Refresh()
   oEdit:lUpdated := .T.

   RETURN Nil

STATIC FUNCTION plug_ciph_GetText()

   LOCAL oEdit := HWindow():GetMain():oEdit, cText, nL1, nL2, i

   nL1 := oEdit:aPointC[P_Y]
   DO WHILE nL1 > 0
      cText := oEdit:aText[nL1]
      IF Left( cText,1 ) == "{" .AND. Right( cText,1 ) == "}"
         IF Left( cText,4 ) == "{bf{"
            EXIT
         ENDIF
      ELSE
         nL1 := 0
         EXIT
      ENDIF
      nL1 --
   ENDDO

   IF nL1 > 0
      nL2 := oEdit:aPointC[P_Y]
      DO WHILE nL2 <= Len( oEdit:aText )
         cText := oEdit:aText[nL2]
         IF Left( cText,1 ) == "{" .AND. Right( cText,1 ) == "}"
            IF Right( cText,2 ) == "}}"
               EXIT
            ENDIF
         ELSE
            nL2 := 0
            EXIT
         ENDIF
         nL2 ++
      ENDDO
   ENDIF

   IF nL1 == 0 .OR. nL2 == 0
      RETURN ""
   ENDIF

   cText := ""
   FOR i := nL1 TO nL2
      cText += Substr( oEdit:aText[i], Iif(i==nL1,5,2), ;
         Len(oEdit:aText[i]) - Iif(i==nL1,4,1) - Iif(i==nL2,2,1) )
   NEXT

   RETURN cText

STATIC FUNCTION plug_ciph_Encrypt( cText )

   LOCAL cPassword := Trim( hwg_MsgGet( "Password","",ES_PASSWORD,,,DS_CENTER ) )
   LOCAL cTemp, cRes, nPos

   cTemp := hb_base64encode( hb_blowfishEncrypt( hb_blowfishKey( cPassword ), cText ) )
   IF Len( cTemp ) > 120
      nPos := 1
      cRes := Chr(13)+Chr(10) + "{bf"
      DO WHILE nPos <= Len( cTemp )
         cRes += Iif( nPos==1, "", Chr(13)+Chr(10) ) + "{" + Substr( cTemp, nPos, Min( 120, Len(cTemp)-nPos+1 ) ) + "}"
         nPos += 120
      ENDDO
      cRes += "}" + Chr(13)+Chr(10)
   ELSE
      cRes := Chr(13)+Chr(10) + "{bf{" + cTemp + "}}" + Chr(13)+Chr(10)
   ENDIF

   RETURN cRes

STATIC FUNCTION plug_ciph_Decrypt( cText )

   LOCAL cPassword, cDecoded

   cPassword := Trim( hwg_MsgGet( "Password","",ES_PASSWORD,,,DS_CENTER ) )
   cDecoded := hb_blowfishDecrypt( hb_blowfishKey( cPassword ), hb_base64decode( cText ) )

   RETURN cDecoded

STATIC FUNCTION plug_ciph_View( cText )

   LOCAL oDlg, oEdit

   INIT DIALOG oDlg TITLE "Text decrypted" At 92, 61 SIZE 500, 500 FONT HWindow():GetMain():oFont

   @ 10, 10 EDITBOX oEdit CAPTION cText SIZE 480, 440 ;
   STYLE WS_VSCROLL + WS_HSCROLL + ES_MULTILINE + ES_READONLY

   @ 200, 460 BUTTON "Close" ON CLICK { || hwg_EndDialog() } SIZE 100, 32

   oDlg:Activate()

   RETURN Nil
