#!/bin/bash
#
# $Id$
#
# Script building HWGUI application


#
# This scripts detects, if running on LINUX or MacOS,
# so the environment for compiling is selected coresponding.

if [ "$1" == "" ]; then
  echo "Usage: $0 <filename without extension .prg>"
  exit
fi

# Find out for Mac
# The command "sw_vers" is only existing on MacOS !

if [ -e /usr/bin/sw_vers ]
then
MAJOR_MAC_VERSION=$(sw_vers -productVersion | awk -F '.' '{print $1 "." $2}')
echo "MacOS detected, major version is:"
echo $MAJOR_MAC_VERSION

# Linker options -Wl,--end-group and -Wl,--end-group not allowed on MacOS
OPSYS="mac"
else
# Otherwise LINUX expected, but other *NIX systems may also run this script.
echo "LINUX expected !"
OPSYS="LINUX"
fi


# configure Harbour installation path



###########################
# LINUX (by default)
###########################
# if [ $OPSYS == "LINUX" ]
# then
#export HB_ROOT=../../..
export HB_ROOT=$HOME/Harbour/core-master
# #######################################
export HRB_EXE=$HB_ROOT/bin/linux/gcc/harbour
# #######################################
# configure HWGUI installation path
export HWGUI_ROOT=$HOME/svnwork/hwgui-code/hwgui
#export HWGUI_ROOT=$HOME/hwgui
# #######################################
export CCOMPILER=GCC
export HB_COMOPTS=
#
# fi

if [ $OPSYS == "mac" ]
then
###########################
# MacOS
###########################
# Overwrite existing variables
export HWGUI_ROOT=$HOME/hwgui/hwgui
export HB_ROOT=
export PATH=/opt/local/bin:$PATH
export HB_COMOPTS=-d___MACOSX___
fi


# remove file extension
FILENAME=$1
PGM_NAME="${FILENAME%.*}" 


# These are the default locations of Harbour
if [ "x$HB_ROOT" = x ]; then
export HRB_BIN=/usr/local/bin
export HRB_INC=/usr/local/include/harbour
export HRB_LIB=/usr/local/lib/harbour
else
export HRB_BIN=$HB_ROOT/bin/linux/gcc
export HRB_INC=$HB_ROOT/include
export HRB_LIB=$HB_ROOT/lib/linux/gcc
fi


export SYSTEM_LIBS="-lm -lpcre"
# export HARBOUR_LIBS="-lhbdebug -lhbvm -lhbrtl -lgtcgi -lhbdebug -lhblang -lhbrdd -lhbmacro -lhbpp -lrddntx -lrddcdx -lrddfpt -lhbsix -lhbcommon -lhbcpage -lgttrm"
export HARBOUR_LIBS="-lhbvm -lhbrtl -lgtcgi -lhbdebug -lhblang -lhbrdd -lhbmacro -lhbpp -lrddntx -lrddcdx -lrddfpt -lhbsix -lhbcommon -lhbcpage -lgttrm"

export HWGUI_LIBS="-lhwgui -lprocmisc -lhbxml -lhwgdebug"

# export HWGUI_INC=../../include
# export HWGUI_LIB=../../lib
export HWGUI_INC=$HWGUI_ROOT/include
#export HWGUI_LIB=$HWGUI_ROOT/gtk/lib
export HWGUI_LIB=$HWGUI_ROOT/lib
export CLLOG_INC=../include


echo "==================================================="
echo "Compile $PGM_NAME.prg for target OS $OPSYS"
echo "==================================================="

# -w2 : too much warnings  -w0 : no warnungs 


$HRB_BIN/harbour $PGM_NAME -n -i$HRB_INC -i$HWGUI_INC -i$CLLOG_INC -w0 $HB_COMOPTS -d__LINUX__ -d__GTK__ -d__GNUC__ $2


if [ $OPSYS == "mac" ]
then
gcc $PGM_NAME.c -o$PGM_NAME -I $HRB_INC -L $HRB_LIB -L $HWGUI_LIB $HWGUI_LIBS $HARBOUR_LIBS  `pkg-config --cflags gtk+-2.0` `pkg-config gtk+-2.0 --libs` $SYSTEM_LIBS
else
 gcc $PGM_NAME.c -o$PGM_NAME -I $HRB_INC -L $HRB_LIB -L $HWGUI_LIB -Wl,--start-group $HWGUI_LIBS $HARBOUR_LIBS -Wl,--end-group `pkg-config --cflags gtk+-2.0` `pkg-config gtk+-2.0 --libs` $SYSTEM_LIBS
fi

# Remark:
# Bugfixing of error message "fmod@@GLIBC_2.2.5" :
# => the system libs must be at the end of die library list. (Variable SYSTEM_LIBS)
# See also ==> hwgui/samples/gtk_samples/build.sh


# ------------ EOF of hwmk.sh --------------------
