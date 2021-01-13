#!/bin/bash

# colors.sh

# Harbour Project source code:
# Header file to allow colors in qout()

# $Id$

# Shell script setting and exporting shell variables with
# color definitions
# Call specification:
# . ./colors.sh

version=1.10
datvers=2018-01-28

if [ "x$1" = "x-v" ];then
   echo -e "ii\tcolors\t$version\t$datvers"
   exit
fi

# Color defintions
# Définition des couleurs

# Background colors
# Arrière-plan
export bBla='\033[40m'
export bRed='\033[41m'
export bGre='\033[42m'
export bYel='\033[43m'
export bBlu='\033[44m'
export bMag='\033[45m'
export bCya='\033[46m'
export bWhi='\033[47m'
# Normal
export fBla='\033[30m'
export fRed='\033[31m'
export fGre='\033[32m'
export fYel='\033[33m'
export fBlu='\033[34m'
export fMag='\033[35m'
export fCya='\033[36m'
export fWhi='\033[37m'
#  Bold letters
export gBla='\033[1;30m'
export gRed='\033[1;31m'
export gGre='\033[1;32m'
export gYel='\033[1;33m'
export gBlu='\033[1;34m'
export gMag='\033[1;35m'
export gCya='\033[1;36m'
export gWhi='\033[1;37m'
# Without colors
# Sans couleur
export noColor='\033[0m'
# Movements on screen
# Déplacements sur l'écran:
export mho='\033[0H'
export men='\033[0F'
export mle='\033[0D'
export mri='\033[0C'
export mup='\033[0A'
export mdo='\033[0B'
# Cursor behavior
# Gestion curseur:
export chid="\033[?25l"
export csee="\033[?25h"

# --------------------------- EOF of colors.sh -------------------
