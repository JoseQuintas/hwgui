#include "hwgui.ch"

FUNCTION Main
LOCAL chexdump , oMainW

chexdump := Convert_file("ok.ico")

INIT WINDOW oMainW  ;
   TITLE "Dummy Main Window" AT 0,0 SIZE 0 , 0

hwg_Msginfo(chexdump)


* ACTIVATE WINDOW oMainW
oMainW:Close()


RETURN NIL


// ===============================================================
function Convert_file(fname)
// ===============================================================
local hd, varbuf

if EMPTY(fname)
  return nil
endif
* dirchange(cspath+"/../../image")
dirchange("../../image")

* Read selected file
varbuf := memoread(fname)

* Convert to Hexdump
hd := hwg_hex_dump(varbuf,2)

return hd

