#!/bin/sh
#
# $Id$
#

# ---------------------------------------------------------------
# simple script to build HWGui GTK binaries using [x]hb*scripts
# to hide platform differences
# By default they looks for MinGW32 cross build scripts then
# Harbour and xHarbour platform native scripts
# It's also possible to force build type using as 1-st parameter:
#     -hb      # Harbour platform native binaries
#     -hbw     # Harbour Win32 cross build binaries (MinGW32)
#     -hbce    # Harbour WinCE cross build binaries (MinGW32-CE)
#     -xhb     # xHarbour platform native binaries
#     -xhbw    # Harbour Win32 cross build binaries (MinGW32)
#     -xhbce   # Harbour WinCE cross build binaries (MinGW32-CE)
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
    if which hbwcmp &> /dev/null && [ -x "`which hbwcmp 2>/dev/null`" ]
    then
        # create Harbour Win32 cross compiled libraries
        export HB_PREF=hbw
    elif which xhbwcmp &> /dev/null && [ -x "`which xhbwcmp 2>/dev/null`" ]
    then 
        # create xHarbour Win32 cross compiled libraries
        export HB_PREF=xhbw
    elif which hbcmp &> /dev/null && [ -x "`which hbcmp 2>/dev/null`" ]
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

cd `dirname $0`
mkdir -p obj lib
make -fMakefile.scr $*
