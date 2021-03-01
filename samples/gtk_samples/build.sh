#!/bin/bash
#
# build.sh
# 
# $Id$
#
# Shell script building HWGUI samples for LINUX/GTK
#
# Modify path to Harbour to your own needs
export HB_ROOT=$HOME/Harbour/core-master
#export HB_ROOT=../../..

if [ "$1" == "" ]; then
  echo "Usage: $0 <filename without or with extension .prg> [<additional Harbour options>]"
  exit
fi
# remove file extension
FILENAME=$1
PGM_NAME="${FILENAME%.*}" 

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
export HRB_EXE=$HRB_BIN/harbour
fi

export SYSTEM_LIBS="-lm"
export HARBOUR_LIBS="-lhbdebug -lhbvm -lhbrtl -lgtcgi -lhbdebug -lhblang -lhbrdd -lhbmacro -lhbpp -lrddntx -lrddcdx -lrddfpt -lhbsix -lhbcommon -lhbcpage"
export HWGUI_LIBS="-lhwgui -lprocmisc -lhbxml -lhwgdebug"
export HWGUI_INC=../../include
export HWGUI_LIB=../../lib

# -w2 : too much warnings
$HRB_EXE $PGM_NAME -n -i$HRB_INC -i$HWGUI_INC -es2 -d__LINUX__ -d__GTK__ $2
gcc $PGM_NAME.c -o$PGM_NAME -I $HRB_INC -L $HRB_LIB -L $HWGUI_LIB -Wl,--start-group $HWGUI_LIBS $HARBOUR_LIBS -Wl,--end-group `pkg-config --cflags gtk+-2.0` `pkg-config gtk+-2.0 --libs` $SYSTEM_LIBS
#
