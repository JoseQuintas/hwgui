/*
* sleep.c
*   
* solves problem
* " undefined reference to 'sleep'"
* winbase.h:
* WINBASEAPI void WINAPI Sleep(DWORD);
* ==>
* void Sleep(DWORD dwMiliseconds)
*/
#ifdef __unix__
# include <unistd.h>
#elif defined _WIN32
#include <windows.h>
/* #define sleep(x) Sleep(1000 * (x)) */
#endif
#include <time.h>
 
void sleep(unsigned int mseconds)
{
  clock_t goal = mseconds + clock();
  while (goal > clock());
}

/* ==== EOF of sleep.c ==== */