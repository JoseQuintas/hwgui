#!/bin/bash
export HB_INS=/apps/harbour
export SYSTEM_LIBS="-lm -lncurses"
export HARBOUR_LIBS="-ldebug -lvm -lrtl -lgtcgi -lgtcrs -llang -lrdd -lrtl -lvm -lmacro -lpp -ldbfntx -ldbfcdx -ldbffpt -lhbsix -lcommon -lcodepage"
export HWGUI_LIBS="-lhwgui -lprocmisc -lhbxml"
export HWGUI_INC=../../include
export HWGUI_LIB=../lib

$HB_INS/bin/harbour $1 -n -i$HB_INS/include -i$HWGUI_INC -w2 -d__LINUX__
gcc $1.c -o$1 -I $HB_INS/include -L $HB_INS/lib -L $HWGUI_LIB $SYSTEM_LIBS -Wl,--start-group $HWGUI_LIBS -Wl,--end-group $HARBOUR_LIBS  `pkg-config gtk+-2.0 --libs` `pkg-config libgnomeprint-2.2 --libs` $HWGUI_LIBS >bld.log 2>bld.log
