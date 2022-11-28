#!/bin/bash
#
# $Id$
#
# create gtk+-Libraries of hwgui for Msys64/GTK3
# (Cross develop environment on Windows for GTK3)
#
# Created by DF7BE
#
# Path to Harbour installation
# Modify to your own needs
HB_ROOT=$HARBOUR_INSTALL
export HB_ROOT
echo $HB_ROOT

#  -d  Print lots of debugging information.
make -fMakefile.linux-gtk3 $1
# ============ EOF of buildGTK3.bat =================

