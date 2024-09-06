#!/bin/bash
#
# hbmk.sh
#
# $Id$
#
# Creating CLLOG exe files with Harbour
# ( as LINUX terminal application)
# Also for MacOS (autodetect)
#
# CLLOG-Programme mit Harbour erzeugen
# ( als  LINUX-Terminal-Anwendung )
# Ebenso fuer MacOS (automatische Erkennung)
#
# (c) DF7BE
# GNU General Public License with HWGUI exceptions
#
# Aufruf: ./mkhb.sh <programm ohne Erweiterung .PRG> <Ziel-DVZ>
# Usage : ./mkhb.sh <program name without extension .PRG> <target directory>
#


if [ "$1" == "" ]; then
  echo "Usage: $0 <filename without extension .prg> [<target directory>]"
  exit
fi

HBMKOPTS=""
export HARBOUR_LIBS=""
# Detect OS
if [ -e /usr/bin/sw_vers ]
then
# echo "=== MacOS detected ==="
OPSYS="mac"
HBMKOPTS="-static -d___MACOSX___ -L/usr/local/lib/harbour"
#export HARBOUR_LIBS="-lharbour -lhbvm -lhbrtl -lgtcgi -lhbdebug -lhblang -lhbrdd -lhbmacro -lhbpp -lrddntx -lrddcdx -lrddfpt -lhbsix -lhbcommon -lhbcpage -lgttrm"
else
# Otherwise LINUX expected, but other *NIX systems may also run this script.
# echo "LINUX expected !"
OPSYS="LINUX"
fi

echo "==================================================="
echo "Compile $1.prg for target OS $OPSYS"
echo "==================================================="


hbmk2 -I../include  $HBMKOPTS $1
# hbmk2 -I../include  -comp="$HARBOUR_INSTALL" $1

if [ $? -eq 0 ] ; then 
# Erfolg, dann:
# Loeschen der 
# BAK-Dateien
# Compile success: delete backup files
 rm -f $1.bak 2>/dev/null
# -------
 echo "Creation of $1 successful"
 echo "Erstellung von $1 erfolgreich"
 ls -l $1
#
else
 echo "=== Error creating $1 ==="
 echo "... Abort"
 echo "=== Fehler beim Erstellen von $1 ==="
 echo "... Abbruch"
 exit
fi



# === EOF ===


