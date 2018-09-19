
#include "hwgui.ch"
#include "hwgextern.ch"

REQUEST DBCREATE
REQUEST DBUSEAREA
REQUEST DBCREATEINDEX
REQUEST DBSEEK

Function Main
Local oForm := HFormTmpl():Read( "example.xml" )

 oForm:ShowMain()

Return Nil
