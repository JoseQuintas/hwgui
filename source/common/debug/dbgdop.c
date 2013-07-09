#include "hbapi.h"
#include "hbapiitm.h"

#ifdef __XHARBOUR__
HB_FUNC( HB_RELEASECPU )
{
   hb_releaseCPU(0);
}
#endif


#if defined( HB_OS_UNIX )
#include <glib.h>
HB_FUNC( __DBGPROCESSRUN )
{
   char * argv[] = { (char *) hb_parc(1), (char *) hb_parc(2), NULL };
   hb_retl( g_spawn_async( NULL, argv,
         NULL, G_SPAWN_SEARCH_PATH, NULL, NULL, NULL, NULL ) );
}
#endif
