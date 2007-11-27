#!/bin/sh
#
# $Id: make_gtk.sh,v 1.3 2007-11-27 14:00:09 druzus Exp $
#

# ---------------------------------------------------------------
# simple script to build HWGui GTK binaries using [x]hb*scripts
# to hide platform differences
#
# Copyright 2007 by Przemyslaw Czerpak (druzus/at/priv.onet.pl)
#
# ---------------------------------------------------------------

if [ "$1" = "-hb" ]
then
   export HB_PREF=hb
   shift
elif [ "$1" = "-xhb" ]
then
   export HB_PREF=xhb
   shift
fi

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
mkdir -p obj lib
make -fMakefile.scr $*
