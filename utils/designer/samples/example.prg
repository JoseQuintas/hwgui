
#include "windows.ch"
#include "guilib.ch"

REQUEST HTIMER
REQUEST DBCREATE
REQUEST DBUSEAREA
REQUEST DBCREATEINDEX
REQUEST DBSEEK
REQUEST HWG_SHELLABOUT
REQUEST HWG_SLEEP
REQUEST BARCODE
REQUEST HWG_CHOOSECOLOR


// #include "example.frm"

Function Main
Local oForm := HFormTmpl():Read( "example.xml" )

 oForm:ShowMain()

Return Nil
