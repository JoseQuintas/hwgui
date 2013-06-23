#!/bin/bash
export HB_INS=../../../
export SYSTEM_LIBS="-lm"
export HARBOUR_LIBS="-lhbdebug -lhbvm -lhbrtl -lgtcgi -lhblang -lhbrdd -lhbmacro -lhbpp -lrddntx -lrddcdx -lrddfpt -lhbsix -lhbcommon -lhbcpage"
export HWGUI_LIBS="-lhwgui -lprocmisc -lhbxml"
export HWGUI_INC=../../include
export HWGUI_LIB=../lib

$HB_INS/bin/linux/gcc/harbour $1 -n -i$HB_INS/include -i$HWGUI_INC -w2 -d__LINUX__
gcc $1.c -o$1 -I $HB_INS/include -L $HB_INS/lib/linux/gcc -L $HWGUI_LIB $SYSTEM_LIBS -Wl,--start-group $HWGUI_LIBS $HARBOUR_LIBS -Wl,--end-group `pkg-config gtk+-2.0 --libs` >bld.log 2>bld.log
