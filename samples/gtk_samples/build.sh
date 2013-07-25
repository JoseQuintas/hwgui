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

export SYSTEM_LIBS="-lm"
export HARBOUR_LIBS="-lhbdebug -lhbvm -lhbrtl -lgtcgi -lhbdebug -lhblang -lhbrdd -lhbmacro -lhbpp -lrddntx -lrddcdx -lrddfpt -lhbsix -lhbcommon -lhbcpage"
export HWGUI_LIBS="-lhwgui -lprocmisc -lhbxml -lhwgdebug"
export HWGUI_INC=../../include
export HWGUI_LIB=../../lib

$HRB_BIN/harbour $1 -n -i$HRB_INC -i$HWGUI_INC -w2 -d__LINUX__ $2
gcc $1.c -o$1 -I $HRB_INC -L $HRB_LIB -L $HWGUI_LIB $SYSTEM_LIBS -Wl,--start-group $HWGUI_LIBS $HARBOUR_LIBS -Wl,--end-group `pkg-config --cflags gtk+-2.0` `pkg-config gtk+-2.0 --libs`
