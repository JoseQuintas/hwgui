ROOT=../../

ifeq ($(HB_ARCHITECTURE),w32)

DIRS=\
	include \
	source \
	source\cross \
	source/procmisc \
	source/xml \
	source/qhtm \
	gtk

else

DIRS=\
	include \
	source/procmisc \
	source\cross \
	source/xml \
	gtk

endif

include $(ROOT)config/dir.cf
