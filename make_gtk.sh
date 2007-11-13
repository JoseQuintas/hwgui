#!/bin/sh
#
# $Id: make_gtk.sh,v 1.1 2007-11-13 16:50:52 druzus Exp $
#

# ---------------------------------------------------------------
# simple script to build HWGui GTK binaries using [x]hb*scripts
# to hide platform differences
#
# Copyright 2007 by Przemyslaw Czerpak (druzus/at/priv.onet.pl)
#
# ---------------------------------------------------------------

if [ -z "${HB_PREF}" ]
then
    if which hbcmp &> /dev/null
    then
        # create Harbour platform native libraries
        export HB_PREF=hb
    elif which xhbcmp &> /dev/null
    then 
        # create Harbour platform native libraries
        export HB_PREF=xhb
    else
        echo "Cannot find Harbour or xHarbour build scripts."
        exit 1
    fi
fi

cd `dirname $0`/gtk
mkdir -p lib obj
make -fMakefile.scr $*
