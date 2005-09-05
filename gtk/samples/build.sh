#!/bin/bash
export SYSTEM_LIBS="-lm -lncurses"
export HARBOUR_LIBS="-ldebug -lvm -lrtl -lgtcrs -llang -lrdd -lrtl -lvm -lmacro -lpp -ldbfntx -ldbfcdx -ldbfdbt -lcommon -lcodepage"
export HWGUI_LIBS="-lhwgui -lprocmisc -lhbxml"
export HB_LIB=../../../lib
export HB_INC=../../../include
export HWGUI_INC=../../include
export HWGUI_LIB=../lib

../../../bin/harbour $1 -n -i$HB_INC -i$HWGUI_INC -w2
gcc $1.c -o$1 -I $HB_INC -L $HB_LIB -L $HWGUI_LIB $SYSTEM_LIBS $HWGUI_LIBS $HARBOUR_LIBS `pkg-config gtk+-2.0 --libs` >bld.log 2>bld.log
