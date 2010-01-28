
#include "windows.ch"
#include "guilib.ch"
#include "fileio.ch"
#include 'common.ch'
**************************
FUNCTION pesquisaglobal()
**************************
LOCAL oDlgPesq,getpesq,ocomb,atu:=1
local oIcon := HIcon():AddRESOURCE( "SEARCHICON" )
local oDir:=directory(DiskName()+':\*.',"D",.t.) // pegando diretirio
private rd_pesq:='',;
        diretorio :={},;
        resultado:='',;
        get01
//
for f = 1 to len(oDir) // filtrando diretorios
    if odir[f,1]#'.' .and. odir[f,1]#'..'
       aadd(diretorio,DiskName()+':\'+oDir[f,1]+'\')
    endif
next f
 //
asort(diretorio)
for g:= 1 to len(diretorio) // pegando diretorio atual
       if upper(diretorio[g]) =DiskName()+':\'+upper(curdir()+'\')
          atu:=g
       endif
next g
 //
 oComb:=atu
 //
 INIT DIALOG oDlgPesq TITLE "Pesquisa Gobal" ICON oIcon;
        AT 26,136 SIZE 694,456
   @ 20,10 SAY "Texto a Procurar" SIZE 111,15
   @ 20,57 SAY "Pasta" SIZE 80,14
   @ 20,30 get getpesq var rd_pesq SIZE 343,24
   @ 20,74 GET COMBOBOX oComb ITEMS diretorio SIZE 340,200
   @ 15,111 get get01 var  resultado SIZE 657,280 STYLE ES_MULTILINE+WS_HSCROLL+WS_VSCROLL
   //@ 364,77 CHECKBOX "Incluir Sub-diretorios" SIZE 147,22
   @ 605,395 BUTTON "&O.K." SIZE 80,32 ID IDOK ON CLICK {||pesq(diretorio[oComb],rd_pesq)}
   //readexit(.t.)
 ACTIVATE DIALOG oDlgPesq
RETURN
*****************************
function pesq(rd_dir,rd_text)
*****************************
local arquivos:=directory(rd_dir+'*.prg',"D",.t.) // pegando arquivos
local nom_arq:={}
local s_lEof:=.F.
private arq_contem:={},;
        result:=''
//
for f:= 1 to len(arquivos) // filtrando arquivos
    if arquivos[f,1]#'.' .and. arquivos[f,1]#'..'
       aadd(nom_arq,arquivos[f,1])
    endif
next f
//
asort(nom_arq)
resultado:=''
get01:refresh()
//
for g := 1 to len(nom_arq)
  arq:=FT_FUSE(rd_dir+nom_arq[g])
  //
  resultado:=resultado+nom_arq[g]+chr(13)+chr(10)
  get01:refresh()
  //
  lin:=0
  while ! FT_FEOF()
     linha :=upper(Substr( FT_FReadLn( @s_lEof ), 1 ) )
     //
     texto:=upper(rd_text)
     //
     //msginfo(linha)
     if at (texto,linha) # 0
         resultado:=resultado+str(lin,6)+':'+linha +chr(13)+chr(10)
         get01:refresh()
     endif
     //
     lin++
     FT_FSKIP()
  enddo
next g
retu .t.

