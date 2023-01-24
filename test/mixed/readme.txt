create hwgui using -DHB_GT_NOGUI=YES -DMT_EXPERIMENTAL
without -DMT_EXPERIMENTAL need to close dialogs in reverse open order
without -HB_GT_NOGUI may to have crashes

gtwvg.hbc add some ch files that conflicts with hwgui ch files
remove headers= and add #include files on prg where needed
hwgui source code using hwgui ch files
gtwvg source code using gtwvg ch files
compile using -w3 -es2, this alerts if forgot #include a ch file

Attention:

do not use a nomodal dialog as first windows on multithread.
there is no previous active window to be locked, and dialog will be closed.

multithread is like separated EXEs, but on same EXE.
If a module crash on a thread, another one on another thread will continue working.
depending module error, may be you need to close application on task manager.
some harbour configuration is not for all threads, you need configure on each one.
I use an AppInit() function to setup the defaults on each new thread, on this way
all threads will have same configuration.
