#!/bin/bash
export HB_ROOT=../../..

if [ "x$HB_ROOT" = x ]; then
export HRB_BIN=/usr/local/bin
export HRB_INC=/usr/local/include/harbour
export HRB_LIB=/usr/local/lib/harbour
else
export HRB_BIN=$HB_ROOT/bin/linux/gcc
export HRB_INC=$HB_ROOT/include
export HRB_LIB=$HB_ROOT/lib/linux/gcc
fi

export SYSTEM_LIBS="-lm -lrt"
export HARBOUR_LIBS="-lhbdebug -lhbvmmt -lhbrtl -lgtcgi -lhblang -lhbrdd -lhbmacro -lhbpp -lrddntx -lrddcdx -lrddfpt -lhbsix -lhbcommon -lhbcpage -lhbct"
export HWGUI_LIBS="-lhwgui -lprocmisc -lhbxml -lhwgdebug"
export HWGUI_INC=../../include
export HWGUI_LIB=../../lib

$HRB_BIN/harbour editor -n -i$HRB_INC -i$HWGUI_INC -w2 2>bldh.log
$HRB_BIN/harbour hcediext -n -i$HRB_INC -i$HWGUI_INC -w2 2>>bldh.log
$HRB_BIN/harbour calc -n -i$HRB_INC -i$HWGUI_INC -w2 2>>bldh.log

gcc editor.c hcediext.c calc.c -oeditor -I $HRB_INC -I $HWGUI_INC -I ../../../source/gtk -DHWG_USE_POINTER_ITEM -L $HRB_LIB -L $HWGUI_LIB -Wl,--start-group $HWGUI_LIBS $HARBOUR_LIBS $SYSTEM_LIBS -Wl,--end-group `pkg-config --cflags gtk+-2.0` `pkg-config gtk+-2.0 --libs`  >bld.log 2>bld.log

rm *.c
rm *.o
