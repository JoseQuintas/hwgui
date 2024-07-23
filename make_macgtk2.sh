#!/bin/sh
#
# $Id$
#

# ---------------------------------------------------------------
# Script to build HWGui GTK binaries on MacOS
# Copyright 2024 by DF7BE
#
# ---------------------------------------------------------------

# configure the path of the Harbour compiler to your own needs
#export HB_ROOT=$HOME/Harbour/core-master
#export HB_ROOT=/usr/local
#
# Using default values in makefile:
# HRB_BIN = /usr/local/bin
# HRB_INC = /usr/local/include/harbour
# HRB_LIB = /usr/local/lib/harbour
# ==> so left HB_ROOT empty
#

# Set path to pkg-config
export PATH=/opt/local/bin:$PATH


cd `dirname $0`/source/gtk
if [ $? -ne 0 ]
then
  echo "error: no chdir to `dirname $0`/source/gtk possible"
  exit 1
fi
if ! [ -e ../../lib ]; then
   mkdir ../../lib
   chmod a+w+r+x ../../lib
fi
if ! [ -e ../../obj ]; then
   mkdir ../../obj
   chmod a+w+r+x ../../obj
fi
make -fMakefile.mac $*
#

# ================= EOF of make_macgtk2.sh =================
