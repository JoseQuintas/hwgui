HB_INC_COMPILE=$(TOP)../include -I$(TOP)$(ROOT)include
ROOT=../../../
C_SOURCES=\
	commond.c \
	control.c \
	menu_c.c \
	message.c \
	misc.c \
	window.c \
	wprint.c \
	draw.c \
	drawtext.c
	
	
PRG_SOURCES=\
	drawwidg.prg \
	errorsys.prg \
	gtkmain.prg \
	hbrowse.prg \
	hcheck.prg \
	hcombo.prg \
	hcontrol.prg \
	hcwindow.prg \
	hdialog.prg \
	hedit.prg \
	hfrmtmpl.prg \
	hgraph.prg \
	hownbtn.prg \
	hpanel.prg \
   hprogres.prg \
   hmonthc.prg \
	hprinter.prg \
	hradio.prg \
	htab.prg \
	hsayimg.prg \
	hsplit.prg \
	htimer.prg \
	hupdown.prg \
	hwindow.prg \
	hwinprn.prg \
	menu.prg \
   	
	
LIBNAME=hwgtk

include $(TOP)$(ROOT)config/lib.cf
include $(TOP)$(ROOT)config/dir.cf

ifeq ($(HB_ARCHITECTURE),w32)
	C_USR += -mms-bitfields -I`pkg-config --cflags gtk+-2.0`
else
	C_USR += -I`pkg-config --cflags libgnomeprint-2.2 --cflags gtk+-2.0`
endif
