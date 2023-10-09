#!/bin/bash
#
# build.sh
#
# $Id$
# 
# Build shell script build tutor on LINUX/GTK
# 

# Modify path to Harbour to your own needs
export HB_ROOT=$HOME/Harbour/core-master
# export HB_ROOT=../../..

if [ "x$HB_ROOT" = x ]; then
export HRB_BIN=/usr/local/bin
export HRB_INC=/usr/local/include/harbour
# 32 bit 
export HRB_LIB=/usr/local/lib/harbour
# 64 bit
# export HRB_LIB=/usr/local/lib64/harbour
else
export HRB_BIN=$HB_ROOT/bin/linux/gcc
export HRB_INC=$HB_ROOT/include
export HRB_LIB=$HB_ROOT/lib/linux/gcc
fi

export SYSTEM_LIBS="-lm -lz -lpcre -ldl"
export HARBOUR_LIBS="-lhbdebug -lhbvm -lhbrtl -lgtcgi -lhbdebug -lhblang -lhbrdd -lhbmacro -lhbpp -lrddntx -lrddcdx -lrddfpt -lhbsix -lhbcommon -lhbcpage -lhbcplr"
export HWGUI_LIBS="-lhwgui -lprocmisc -lhbxml -lhwgdebug"
export HWGUI_INC=../../include
export HWGUI_LIB=../../lib

$HRB_BIN/harbour tutor -n -i$HRB_INC -i$HWGUI_INC -w2 -d__LINUX__ -d__GTK__
gcc tutor.c -otutor -I $HRB_INC -L $HRB_LIB -L $HWGUI_LIB -Wl,--start-group $HWGUI_LIBS $HARBOUR_LIBS  -Wl,--end-group `pkg-config --libs gtk+-2.0` $SYSTEM_LIBS

$HRB_BIN/harbour hwgrun -n -i$HRB_INC -i$HWGUI_INC -w2 -d__LINUX__ -d__GTK__
gcc hwgrun.c -ohwgrun -I $HRB_INC -L $HRB_LIB -L $HWGUI_LIB -Wl,--start-group $HWGUI_LIBS $HARBOUR_LIBS  -Wl,--end-group `pkg-config --libs gtk+-2.0` $SYSTEM_LIBS

rm tutor.c
rm hwgrun.c

# =================== EOF of build.sh =======================
