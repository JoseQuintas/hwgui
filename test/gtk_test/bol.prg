*
* Ticket #69 by Alain Aupaix
*
#include "hwgui.ch"

REQUEST HB_CODEPAGE_UTF8

function main()
local cBol, nBol, txt, rg, ok:=.f.
LOCAL oWinMain

INIT WINDOW oWinMain

hb_cdpSelect( "UTF8" )

run("wget https://www.vorwerk.fr/shop/thermomix/accessoires/filter/accessoires-thermomix/accessoires-tm31 -Obol.txt")
cBol=memoread("bol.txt")
nBol=mlcount(cBol,600)

for rg=1 to nbol
    txt=trim(memoline(cBol,600,rg))
    do case
       case at("Bol avec poignée pour Thermomix TM 31",txt) > 0
            ok=.t.
            rg+=13
            loop
       case at("délai de livraison",txt) > 0 .and. ok
//qout("disponible")
            hwg_MsgInfo("Bol Thermomix TM31 disponible !!!","Disponibilité du bol TM31")
            exit
       case at("non disponible",txt) > 0 .and. ok
//qout("indisponible")
            hwg_MsgStop("Bol Thermomix TM31 disponible !!!","Disponibilité du bol TM31")
            exit
    endcase
next

if at("délai de livraison",txt) > 0
   hwg_ShellExecute("https://www.vorwerk.fr/shop/thermomix/accessoires/filter/accessoires-thermomix/accessoires-tm31")
endif

oWinMain:Close()

return nil
