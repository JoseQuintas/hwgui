/*
  $Id$
  
  warnings.h
  
  Suppress common warnings 
  for GCC 
  
*/

#ifndef _COMMON_GCC_WARNINGS
#define _COMMON_GCC_WARNINGS

/*
 "-Wpragmas" avoid warnings with invalid pragma warnings in
 old GCC versions. 
*/


#if defined(__GNUC__) && !defined(__INTEL_COMPILER) && !defined(__clang__)
#pragma GCC diagnostic ignored "-Wpragmas" 
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#pragma GCC diagnostic ignored "-Wstringop-truncation"
#endif

#endif /* _COMMON_GCC_WARNINGS */

/* ============================= EOF of warnings.h ====================== */
