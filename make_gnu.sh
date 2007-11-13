#!/bin/sh
#
# $Id: make_gnu.sh,v 1.1 2007-11-13 19:33:20 druzus Exp $
#

# ---------------------------------------------------------------
# simple script to build HWGui GTK binaries using [x]hb*scripts
# to hide platform differences
#
# Copyright 2007 by Przemyslaw Czerpak (druzus/at/priv.onet.pl)
#
# ---------------------------------------------------------------

case "$1" in
        -hb|-hbw|-hbce|-xhb|-xhbw|-xhbce)
            export HB_PREF=${1#-}
            shift
            ;;
        *)
            ;;
esac

if [ -z "${HB_PREF}" ]
then
    if which hbwcmp &> /dev/null
    then
        # create Harbour Win32 cross compiled libraries
        export HB_PREF=hbw
    elif which xhbwcmp &> /dev/null
    then 
        # create xHarbour Win32 cross compiled libraries
        export HB_PREF=xhbw
    elif which hbcmp &> /dev/null
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

cd `dirname $0`
mkdir -p lib obj
make -fMakefile.scr $*
