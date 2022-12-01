#!/bin/sh
#
# $Id$
#
# Simple script to build HWGui GTK3 binaries

# Path to Harbour installation
# Modify to your own needs
HB_ROOT=$HARBOUR_INSTALL
export HB_ROOT
echo $HB_ROOT 

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

#  -d  Print lots of debugging information.
make -fMakefile.linux-gtk3 $1


# ======================= EOF of make_gtk3.sh =============================


