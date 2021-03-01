
#include "windows.ch"
#include "guilib.ch"

REQUEST HTIMER
REQUEST DBCREATE
REQUEST DBUSEAREA
REQUEST DBCREATEINDEX
REQUEST DBSEEK
REQUEST HWG_SHELLABOUT


Function Main
Local oForm := HFormTmpl():Read( example() )

oForm:ShowMain()

Return Nil

#include "example.frm"
