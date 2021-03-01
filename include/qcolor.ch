/*
* qcolor.ch 
*
* Harbour Project source code:
* Header file to allow colors in qout()
*
* $Id$
*
* Copyright 2015-2018 Alain Aupeix
*
* English comments added by DF7BE
*
*/

/*
 Color definitions
 Définition des couleurs
*/
 
/*
# Background colors
# Arrière-plan
*/
#define bBla      chr(27)+"[40m"
#define bRed      chr(27)+"[41m"
#define bGre      chr(27)+"[42m"
#define bYel      chr(27)+"[43m"
#define bBlu      chr(27)+"[44m"
#define bMag      chr(27)+"[45m"
#define bCya      chr(27)+"[46m"
#define bWhi      chr(27)+"[47m"

/*
 Normal letters 
 Lettres normales
*/
#define fBla      chr(27)+"[0;30m"
#define fRed      chr(27)+"[0;31m"
#define fGre      chr(27)+"[0;32m"
#define fYel      chr(27)+"[0;33m"
#define fBlu      chr(27)+"[0;34m"
#define fMag      chr(27)+"[0;35m"
#define fCya      chr(27)+"[0;36m"
#define fWhi      chr(27)+"[0;37m"

/*
 Bold letters
 Lettres bold
*/
#define gBla      chr(27)+"[1;30m"
#define gRed      chr(27)+"[1;31m"
#define gGre      chr(27)+"[1;32m"
#define gYel      chr(27)+"[1;33m"
#define gBlu      chr(27)+"[1;34m"
#define gMag      chr(27)+"[1;35m"
#define gCya      chr(27)+"[1;36m"
#define gWhi      chr(27)+"[1;37m"

/*
 Without colors
 Sans couleur
 */
#define noColor      chr(27)+"[0m"

/*
 Movements on screen
 Déplacements sur l"écran:
*/
#define mho      chr(27)+"[0H"
#define men      chr(27)+"[0F"
#define mle      chr(27)+"[0D"
#define mri      chr(27)+"[0C"
#define mup      chr(27)+"[0A"
#define mdo      chr(27)+"[0B"

/* 
  Cursor behavior
  Gestion curseur:
*/
#define chid      chr(27)+"[?25l"
#define csee      chr(27)+"[?25h"

/* -------------------- EOF of qcolor.ch ----------------------- */
