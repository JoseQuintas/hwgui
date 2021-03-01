#!/bin/bash
#
# hbmk.sh
#
# Script building a HWGUI GTK sample programm with hbmk2 utility on LINUX.
#
# remove file extension
FILENAME=$1
PGM_NAME="${FILENAME%.*}"
echo "compiling $PGM_NAME .." 

# Add -trace for debug output 
hbmk2 $PGM_NAME.hbp 

# ======================= EOF of hbmk.sh =============================
