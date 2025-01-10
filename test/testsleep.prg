*
* 
* testsleep.prg
*
* $Id$
*
* Harbour Test program for hwg_Sleep_C()
*
* compile with
*  hbmk2 testsleep.prg
*
* On LINUX, measure the elapsed time with the command "time"
* 
FUNCTION MAIN()

hwg_Sleep_C(10000)

QUIT

RETURN NIL

#pragma BEGINDUMP

#include "hbapi.h"
#include <unistd.h>


HB_FUNC( HWG_SLEEP_C )
{
   if( hb_parinfo( 1 ) )
      usleep( hb_parnl( 1 ) );
}

#pragma ENDDUMP

* ======================= EOF of testsleep.prg ========================