# $Id: Makefile,v 1.5 2005-03-10 11:32:48 alkresin Exp $
# Building of libhwgui.a - Harbour Linux (GTK) GUI library

HRB_DIR = /apps/harbour
INC_DIR = ../include
OBJ_DIR = obj
LIB_DIR = lib
PROCMISC_DIR=../source/procmisc
XML_DIR=../source/xml
SRC_DIR=../source
CFLAGS = -Wall -O3 -mcpu=pentium

all: \
   $(LIB_DIR)/libhwgui.a \
   $(LIB_DIR)/libprocmisc.a \
   $(LIB_DIR)/libhbxml.a

$(LIB_DIR)/libhwgui.a : \
   $(OBJ_DIR)/commond.o \
   $(OBJ_DIR)/control.o \
   $(OBJ_DIR)/draw.o \
   $(OBJ_DIR)/drawtext.o \
   $(OBJ_DIR)/window.o \
   $(OBJ_DIR)/menu_c.o \
   $(OBJ_DIR)/message.o \
   $(OBJ_DIR)/misc.o \
   $(OBJ_DIR)/drawwidg.o \
   $(OBJ_DIR)/errorsys.o \
   $(OBJ_DIR)/gtkmain.o \
   $(OBJ_DIR)/hbrowse.o \
   $(OBJ_DIR)/hcwindow.o \
   $(OBJ_DIR)/hcheck.o \
   $(OBJ_DIR)/hcombo.o \
   $(OBJ_DIR)/hcontrol.o \
   $(OBJ_DIR)/hdialog.o \
   $(OBJ_DIR)/hedit.o \
   $(OBJ_DIR)/hfrmtmpl.o \
   $(OBJ_DIR)/hgraph.o \
   $(OBJ_DIR)/hradio.o \
   $(OBJ_DIR)/htimer.o \
   $(OBJ_DIR)/hupdown.o \
   $(OBJ_DIR)/hwindow.o \
   $(OBJ_DIR)/menu.o
	ar rc $@ $^

$(OBJ_DIR)/commond.o   : commond.c
	gcc $(CFLAGS) -c -I$(INC_DIR) -I$(HRB_DIR)/include `pkg-config --cflags gtk+-2.0` -o $@ $^

$(OBJ_DIR)/control.o   : control.c
	gcc $(CFLAGS) -c -I$(INC_DIR) -I$(HRB_DIR)/include `pkg-config --cflags gtk+-2.0` -o $@ $^

$(OBJ_DIR)/draw.o   : draw.c
	gcc $(CFLAGS) -c -I$(INC_DIR) -I$(HRB_DIR)/include `pkg-config --cflags gtk+-2.0` -o $@ $^

$(OBJ_DIR)/drawtext.o   : drawtext.c
	gcc $(CFLAGS) -c -I$(INC_DIR) -I$(HRB_DIR)/include `pkg-config --cflags gtk+-2.0` -o $@ $^

$(OBJ_DIR)/window.o   : window.c
	gcc $(CFLAGS) -c -I$(INC_DIR) -I$(HRB_DIR)/include `pkg-config --cflags gtk+-2.0` -o $@ $^

$(OBJ_DIR)/menu_c.o   : menu_c.c
	gcc $(CFLAGS) -c -I$(INC_DIR) -I$(HRB_DIR)/include `pkg-config --cflags gtk+-2.0` -o $@ $^

$(OBJ_DIR)/message.o   : message.c
	gcc $(CFLAGS) -c -I$(INC_DIR) -I$(HRB_DIR)/include `pkg-config --cflags gtk+-2.0` -o $@ $^

$(OBJ_DIR)/misc.o   : misc.c
	gcc $(CFLAGS) -c -I$(INC_DIR) -I$(HRB_DIR)/include `pkg-config --cflags gtk+-2.0` -o $@ $^

$(OBJ_DIR)/drawwidg.o  : $(OBJ_DIR)/drawwidg.c

$(OBJ_DIR)/drawwidg.c  : drawwidg.prg
	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -o$@ $^

$(OBJ_DIR)/errorsys.o  : $(OBJ_DIR)/errorsys.c

$(OBJ_DIR)/errorsys.c  : errorsys.prg
	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -o$@ $^

$(OBJ_DIR)/gtkmain.o  : $(OBJ_DIR)/gtkmain.c

$(OBJ_DIR)/gtkmain.c    : gtkmain.prg
	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -o$@ $^

$(OBJ_DIR)/hbrowse.o  : $(OBJ_DIR)/hbrowse.c

$(OBJ_DIR)/hbrowse.c  : hbrowse.prg
	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -d__LINUX_GTK__ -o$@ $^

$(OBJ_DIR)/hcwindow.o  : $(OBJ_DIR)/hcwindow.c

$(OBJ_DIR)/hcwindow.c  : hcwindow.prg
	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -d__LINUX_GTK__ -o$@ $^

$(OBJ_DIR)/hcheck.o  : $(OBJ_DIR)/hcheck.c

$(OBJ_DIR)/hcheck.c  : hcheck.prg
	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -o$@ $^

$(OBJ_DIR)/hcombo.o  : $(OBJ_DIR)/hcombo.c

$(OBJ_DIR)/hcombo.c  : hcombo.prg
	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -o$@ $^

$(OBJ_DIR)/hcontrol.o  : $(OBJ_DIR)/hcontrol.c

$(OBJ_DIR)/hcontrol.c  : hcontrol.prg
	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -o$@ $^

$(OBJ_DIR)/hdialog.o  : $(OBJ_DIR)/hdialog.c

$(OBJ_DIR)/hdialog.c  : hdialog.prg
	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -o$@ $^

$(OBJ_DIR)/hedit.o  : $(OBJ_DIR)/hedit.c

$(OBJ_DIR)/hedit.c  : hedit.prg
	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -o$@ $^

$(OBJ_DIR)/hfrmtmpl.o  : $(OBJ_DIR)/hfrmtmpl.c

$(OBJ_DIR)/hfrmtmpl.c  : hfrmtmpl.prg
	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -o$@ $^

$(OBJ_DIR)/hgraph.o  : $(OBJ_DIR)/hgraph.c

$(OBJ_DIR)/hgraph.c  : hgraph.prg
	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -o$@ $^

$(OBJ_DIR)/hradio.o  : $(OBJ_DIR)/hradio.c

$(OBJ_DIR)/hradio.c  : hradio.prg
	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -o$@ $^

$(OBJ_DIR)/htimer.o  : $(OBJ_DIR)/htimer.c

$(OBJ_DIR)/htimer.c  : htimer.prg
	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -o$@ $^

$(OBJ_DIR)/hupdown.o  : $(OBJ_DIR)/hupdown.c

$(OBJ_DIR)/hupdown.c  : hupdown.prg
	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -o$@ $^

$(OBJ_DIR)/hwindow.o  : $(OBJ_DIR)/hwindow.c

$(OBJ_DIR)/hwindow.c  : hwindow.prg
	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -o$@ $^

$(OBJ_DIR)/menu.o  : $(OBJ_DIR)/menu.c

$(OBJ_DIR)/menu.c  : menu.prg
	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -d__LINUX_GTK__ -o$@ $^


$(LIB_DIR)/libprocmisc.a : \
   $(OBJ_DIR)/arr2str.o \
   $(OBJ_DIR)/blowfish.o \
   $(OBJ_DIR)/procini.o \
   $(OBJ_DIR)/procs7.o \
   $(OBJ_DIR)/procscri.o
	ar rc $@ $^

$(OBJ_DIR)/arr2str.o  : $(PROCMISC_DIR)/arr2str.c
	gcc $(CFLAGS) -c -I$(INC_DIR) -I$(HRB_DIR)/include -o $@ $^
$(OBJ_DIR)/blowfish.o : $(PROCMISC_DIR)/blowfish.c
	gcc $(CFLAGS) -c -I$(INC_DIR) -I$(HRB_DIR)/include -o $@ $^
$(OBJ_DIR)/procini.o  : $(OBJ_DIR)/procini.c
$(OBJ_DIR)/procs7.o   : $(OBJ_DIR)/procs7.c
$(OBJ_DIR)/procscri.o : $(OBJ_DIR)/procscri.c

$(OBJ_DIR)/procini.c    : $(PROCMISC_DIR)/procini.prg
	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -d__WINDOWS__ -o$@ $^
$(OBJ_DIR)/procs7.c     : $(PROCMISC_DIR)/procs7.prg
	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -d__WINDOWS__ -o$@ $^
$(OBJ_DIR)/procscri.c   : $(PROCMISC_DIR)/procscri.prg
	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -d__WINDOWS__ -o$@ $^


$(LIB_DIR)/libhbxml.a : \
   $(OBJ_DIR)/xmlparse.o \
   $(OBJ_DIR)/hxmldoc.o
	ar rc $@ $^

$(OBJ_DIR)/xmlparse.o  : $(XML_DIR)/xmlparse.c
	gcc $(CFLAGS) -c -I$(INC_DIR) -I$(HRB_DIR)/include -o $@ $^
$(OBJ_DIR)/hxmldoc.o  : $(OBJ_DIR)/hxmldoc.c

$(OBJ_DIR)/hxmldoc.c    : $(XML_DIR)/hxmldoc.prg
	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -d__WINDOWS__ -o$@ $^

#.prg.c:
#	$(HRB_DIR)/bin/harbour $^ -n -w -I$(HRB_DIR)/include -i$(INC_DIR) -d__WINDOWS__ -o$@ $^

.c.o:
	gcc $(CFLAGS) -c -I$(INC_DIR) -I$(HRB_DIR)/include `pkg-config --cflags gtk+-2.0` -o $@ $^
