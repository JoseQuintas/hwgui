#!/bin/bash
export SYSTEM_LIBS="-lm"
export HARBOUR_LIBS="-ldebug -lvm -lrtl -lgtcgi -llang -lrdd -lrtl -lvm -lmacro -lpp -ldbfntx -ldbfcdx -ldbfdbt -ldbffpt -lcommon -lcodepage"
export HWGUI_LIBS="-lhwgui -lprocmisc -lhbxml"
export HB_LIB=../../../lib
export HB_INC=../../../include
export HWGUI_INC=../../include
export HWGUI_LIB=../lib

../../../bin/harbour $1 -n -i$HB_INC -i$HWGUI_INC -w2 -d__LINUX__
gcc $1.c -o$1 -I $HB_INC -L $HB_LIB -L $HWGUI_LIB $SYSTEM_LIBS -Wl,--start-group $HWGUI_LIBS -Wl,--end-group $HARBOUR_LIBS  `pkg-config gtk+-2.0 --libs` `pkg-config libgnomeprint-2.2 --libs` $HWGUI_LIBS >bld.log 2>bld.log
