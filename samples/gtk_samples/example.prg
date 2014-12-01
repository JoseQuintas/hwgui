
#include "hwgui.ch"

REQUEST HTIMER
REQUEST DBCREATE
REQUEST DBUSEAREA
REQUEST DBCREATEINDEX
REQUEST DBSEEK

Function Main
Local oForm := HFormTmpl():Read( "example.xml" )

 oForm:ShowMain()

Return Nil
