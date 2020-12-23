/*
  $Id$
  
  incomp_pointer.h
  
  Suppress warning if a function pointer is cast to an incompatible function pointer
  for GCC >= 8.1.x (MinGW64 )
  
*/

#ifndef _INCOMP_POINTER_WARNING
#define _INCOMP_POINTER_WARNING

#if defined(__GNUC__) && !defined(__INTEL_COMPILER) && !defined(__clang__)
#if (__GNUC__ > 8) || ((__GNUC__ == 8 ) && (__GNUC_MINOR__ >= 1 ))
#pragma GCC diagnostic ignored "-Wcast-function-type"
#pragma GCC diagnostic ignored "-Wint-to-pointer-cast"
#endif
#endif

#endif /* _INCOMP_POINTER_WARNING */

/* ============================= EOF of incomp_pointer.h ============================= */
