#!/bin/bash
#
# clean.sh
#
# 
# Removes all executeables, o files , libraries
# and other temporary files of program runs
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
rm utils/dbc/a1 2>/dev/null
rm utils/tutorial/__tmp.hrb 2>/dev/null
#
# Samples only for LINUX/GTK
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
rm samples/gtk_samples/temp_a2.ps 2>/dev/null
#
# Samples for multi plattform
rm samples/testget1 2>/dev/null
rm samples/bincnts 2>/dev/null
rm samples/datepicker 2>/dev/null
rm samples/bincnts 2>/dev/null
rm samples/stretch 2>/dev/null
rm samples/escrita 2>/dev/null
rm samples/night   2>/dev/null
rm samples/TwoLstSub 2>/dev/null
rm samples/dbview 2>/dev/null
rm samples/testfunc 2>/dev/null
rm samples/winprn 2>/dev/null
rm samples/temp_a2.ps 2>/dev/null
rm samples/temp_a2.pdf 2>/dev/null
rm samples/tstcombo  2>/dev/null


#
# Utils exe
rm bin/bincnt 2>/dev/null
rm bin/dbchw 2>/dev/null
rm bin/file2hex 2>/dev/null
rm bin/hwgdebug 2>/dev/null
rm utils/devtools/memdump 2>/dev/null
rm utils/devtools/test.mem 2>/dev/null
rm utils/devtools/test.txt 2>/dev/null
rm utils/devtools/lbldump 2>/dev/null

# contrib exe
rm contrib/hwlabel/hwlbledt 2>/dev/null
rm contrib/hwlabel/hwlblsample 2>/dev/null

# test exe
rm test/gtk_err93 2>/dev/null


# Find and delete all Error logs
find . -name Error.log -exec rm -f {} \;

# ========================= EOF of clean.sh ===================================


