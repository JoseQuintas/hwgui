ROOT=../../

DIRS=\
	source \
	source/procmisc \
	source/xml \
	source/qhtm \
	gtk

include $(ROOT)config/dir.cf

C_USR += -DHARBOUR_CVS_VERSION
