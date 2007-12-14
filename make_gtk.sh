#!/bin/sh
#
# $Id: make_gtk.sh,v 1.4 2007-12-14 13:02:51 druzus Exp $
#

# ---------------------------------------------------------------
# simple script to build HWGui GTK binaries using [x]hb*scripts
# to hide platform differences
# By default they looks for native Harbour then xHarbour scripts
# It's possible to force build type using as 1-st parametr:
#     -hb      # Harbour platform native binaries
#     -xhb     # xHarbour platform native binaries
#
# Copyright 2007 by Przemyslaw Czerpak (druzus/at/priv.onet.pl)
#
# ---------------------------------------------------------------

case "$1" in
    -hb|-xhb)
        export HB_PREF=${1#-}
        shift
        ;;
    *)
        ;;
esac

if [ -z "${HB_PREF}" ]
then
    if which hbcmp &> /dev/null && [ -x "`which hbcmp 2>/dev/null`" ]
    then
        # create Harbour platform native libraries
        export HB_PREF=hb
    elif which xhbcmp &> /dev/null && [ -x "`which xhbcmp 2>/dev/null`" ]
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
