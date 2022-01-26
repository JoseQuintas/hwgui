#!/bin/bash
#
# clean.sh
#
# 
# Removes all executeables, o files and libraries
# outside the makefile "clean".
# (created by "hbmk2 allhbp.hbp)
# 
rm -rf lib/.hbmk 2>/dev/null
rm lib/*.a 2>/dev/null
rm obj/*.o 2>/dev/null
#
rm contrib/hwreport/hwreport 2>/dev/null
#
rm utils/debugger/sample 2>/dev/null
rm utils/designer/designer 2>/dev/null
rm utils/editor/editor 2>/dev/null
rm utils/tutorial/hwgrun 2>/dev/null
rm utils/tutorial/tutor 2>/dev/null
#
rm samples/gtk_samples/GetWinVers 2>/dev/null
rm samples/gtk_samples/a 2>/dev/null
rm samples/gtk_samples/dbview 2>/dev/null
rm samples/gtk_samples/escrita 2>/dev/null
rm samples/gtk_samples/example 2>/dev/null
rm samples/gtk_samples/graph 2>/dev/null
rm samples/gtk_samples/progbars 2>/dev/null
rm samples/gtk_samples/pseudocm 2>/dev/null
rm samples/gtk_samples/testget2 2>/dev/null
rm samples/gtk_samples/winprn 2>/dev/null
#
rm samples/testget1 2>/dev/null
rm samples/bincnts 2>/dev/null
rm samples/datepicker 2>/dev/null
#
rm bin/bincnt 2>/dev/null
rm bin/dbchw 2>/dev/null
rm bin/file2hex 2>/dev/null
rm bin/hwgdebug 2>/dev/null

# ========================= EOF of clean.sh ===================================


