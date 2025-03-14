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
delfi()
{
 rm "$1" 2>/dev/null
} 

# === Remove all HWGUI basic libraries ===
#rm lib/*.a 2>/dev/null
rm lib/libhbxml.a 2>/dev/null
rm lib/libhwgdebug.a 2>/dev/null
rm lib/libhwgui.a 2>/dev/null
rm lib/libprocmisc.a 2>/dev/null
#
# Special
rm -rf lib/.hbmk 2>/dev/null
rm obj/*.o 2>/dev/null
#
rm contrib/hwreport/hwreport 2>/dev/null
#
# exe and files in utils
rm utils/debugger/sample 2>/dev/null
rm utils/designer/designer 2>/dev/null
rm utils/editor/editor 2>/dev/null
rm utils/tutorial/hwgrun 2>/dev/null
rm utils/tutorial/tutor 2>/dev/null
rm utils/dbc/a1 2>/dev/null
rm utils/tutorial/__tmp.hrb 2>/dev/null
rm utils/hbpad/hbpad 2>/dev/null
#
# Samples only for LINUX/GTK
rm samples/gtk_samples/GetWinVers 2>/dev/null
rm samples/gtk_samples/a 2>/dev/null
rm samples/a.log 2>/dev/null
rm samples/gtk_samples/dbview 2>/dev/null
rm samples/gtk_samples/escrita 2>/dev/null
rm samples/gtk_samples/example 2>/dev/null
rm samples/gtk_samples/graph 2>/dev/null
rm samples/gtk_samples/progbars 2>/dev/null
rm samples/gtk_samples/pseudocm 2>/dev/null
rm samples/gtk_samples/testget2 2>/dev/null
rm samples/gtk_samples/winprn 2>/dev/null
rm samples/gtk_samples/temp_a2.ps 2>/dev/null
delfi samples/arraybrowse
delfi samples/arraybrowse.c
#
# Samples for multi plattform (exe)
# and optional generated C source file
rm samples/a 2>/dev/null
rm samples/a.log 2>/dev/null
rm samples/testget1 2>/dev/null
rm samples/bincnts 2>/dev/null
rm samples/datepicker 2>/dev/null
rm samples/bincnts 2>/dev/null
delfi samples/GetWinVers
delfi samples/getupdown
delfi samples/demodbf
delfi samples/demohlistsub
delfi samples/fileselect
rm samples/stretch 2>/dev/null
rm samples/escrita 2>/dev/null
rm samples/night   2>/dev/null
rm samples/TwoLstSub 2>/dev/null
rm samples/dbview 2>/dev/null
rm samples/dbview.c 2>/dev/null
rm samples/testfunc 2>/dev/null
rm samples/winprn 2>/dev/null
delfi samples/winprn.c
rm samples/tstcombo.c  2>/dev/null
rm samples/tstcombo  2>/dev/null
rm samples/testxml 2>/dev/null
rm samples/xmltree 2>/dev/null
rm samples/colrbloc 2>/dev/null
rm samples/testtree 2>/dev/null
rm samples/bindbf 2>/dev/null
rm samples/hexbincnt  2>/dev/null
rm samples/imageview 2>/dev/null
rm samples/checkbox 2>/dev/null
rm samples/testbmpcr 2>/dev/null
rm samples/qrencode 2>/dev/null
rm samples/graph 2>/dev/null
rm samples/helpstatic 2>/dev/null
rm samples/icons 2>/dev/null
rm samples/testfehl.bmp 2>/dev/null
rm samples/testimage 2>/dev/null
rm samples/tab 2>/dev/null
rm samples/testget2.c 2>/dev/null
rm samples/testget2 2>/dev/null
delfi samples/Dialogboxes
delfi samples/bitmapbug
delfi samples/tststconsapp
delfi samples/helloworld
delfi samples/hello
delfi samples/htrack
delfi samples/progressbar/progress
delfi samples/progressbar/demo_progres
#
# created files from sample programs
rm samples/a.log 2>/dev/null
rm samples/temp_a2.ps 2>/dev/null
rm samples/temp_a2.pdf 2>/dev/null
rm samples/tstbrw.dbf 2>/dev/null
rm samples/test.bmp  2>/dev/null

#
# Bin exe and logs
rm bin/bincnt 2>/dev/null
rm bin/dbchw 2>/dev/null
rm bin/file2hex 2>/dev/null
rm bin/hwgdebug 2>/dev/null

#
# Utils exe and logs
rm utils/devtools/memdump 2>/dev/null
rm utils/devtools/test.mem 2>/dev/null
rm utils/devtools/test.txt 2>/dev/null
rm utils/devtools/lbldump 2>/dev/null
delfi utils/devtools/dbfcompare
rm utils/bincnt/a.log 2>/dev/null
rm utils/bincnt/bindbf 2>/dev/null
rm utils/statichelp/stathlpconv 2>/dev/null
rm utils/statichelp/stathlpsample 2>/dev/null
rm utils/statichelp/helptxt1_en.prg 2>/dev/null
rm utils/statichelp/helptxt2_de.prg 2>/dev/null
delfi contrib/hwreport/example
delfi utils/devtools/dbfcompare.log
delfi utils/devtools/dbfstru



# contrib exe
rm contrib/hwlabel/hwlbledt 2>/dev/null
rm contrib/hwlabel/hwlblsample 2>/dev/null
rm contrib/hwlabel/temp_a2.ps 2>/dev/null
# Other files created by contrib
delfi contrib/qrdecode/output.txt
delfi contrib/qrdecode/qrdecode

# test exe
rm test/gtk_err93 2>/dev/null
rm test/euro 2>/dev/null
rm test/xval 2>/dev/null
rm test/ChTooltip 2>/dev/null
rm test/testfilehex 2>/dev/null
rm test/ticket112 2>/dev/null
rm test/testbmpcr 2>/dev/null
rm test/template  2>/dev/null
rm test/hello 2>/dev/null
rm test/icon 2>/dev/null
rm test/checkbox 2>/dev/null
rm test/Test_tab 2>/dev/null
rm test/gtk3testvbox 2>/dev/null
delfi test/Ticket113
delfi test/Ticket85
delfi test/demosaycrash
delfi test/rdln_test

# Other files created by test programs
rm test/hexdump.txt 2>/dev/null
rm test/test.bmp 2>/dev/null
rm test/Test_tab 2>/dev/null
delfi test/a.log

# Find and delete all Error logs
find . -name Error.log -exec rm -f {} \;

# ========================= EOF of clean.sh ===================================


