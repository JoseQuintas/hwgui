/*
  $Id$
  
  warnings.h
  
  Suppress common warnings 
  for GCC 
  
*/

/* DF7BE 2024-09-05:
  until now, i found no way to suppress
  warning: "HB DEPRECATED" redefined
  
 DF7BE 2025-02-18: Addition information:
 See closed bug ticket: #198 Redefinition warning:

 /usr/include/harfbuzz/hb-common.h
 "This is part of HarfBuzz, a text shaping library."

 So the warning is fired by an external product.

 This is a warning and has no effects on
 running programs.
 So please ignore it. 
  
*/  

#ifndef _COMMON_GCC_WARNINGS
#define _COMMON_GCC_WARNINGS

/*
 "-Wpragmas" avoid warnings with invalid pragma warnings in
 old GCC versions. 
*/


#if defined(__GNUC__) && !defined(__INTEL_COMPILER) && !defined(__clang__)

#pragma GCC diagnostic ignored "-Wpragmas"
#pragma GCC diagnostic ignored "-Wold-style-cast" 
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#pragma GCC diagnostic ignored "-Wstringop-truncation"
#pragma GCC diagnostic ignored "-Wdiscarded-qualifiers"
#pragma GCC diagnostic ignored "-Wunused-function"
#pragma GCC diagnostic ignored "-Wunused-result"
#pragma GCC diagnostic ignored "-Wdeprecated"
#pragma GCC diagnostic ignored "-Wdeprecated-copy"
#pragma GCC diagnostic ignored "-Wmaybe-uninitialized"

#endif

#endif /* _COMMON_GCC_WARNINGS */

/* ============================= EOF of warnings.h ====================== */
