/*
lib - select apropriate source code
*/

#ifdef HBMK_HAS_HWGUI
   #include "lib_hwgui.prg"
#endif

#ifdef HBMK_HAS_HMGE
   #include "lib_hmge.prg"
#endif

#ifdef HBMK_HAS_OOHG
   #include "lib_oohg.prg"
#endif

#ifdef HBMK_HAS_GTWVG
   #include "lib_gtwvg.prg"
#endif

#ifdef HBMK_HAS_HMG3
   #include "lib_hmg3.prg"
#endif
