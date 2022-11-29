#/bin/bash
#
# linux-env.sh
#
# $Id$
#
# Environment settings for Harbour and HWGUI

   # --- Harbour and HWGUI --
   HARBOUR_INSTALL=$HOME/Harbour/core-master
   export HARBOUR_INSTALL
   HWGUI_INSTALL=$HOME/hwgui
   PATH=$PATH:$HARBOUR_INSTALL/bin/linux/gcc:$HWGUI_INSTALL/bin
   export PATH
   LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HARBOUR_INSTALL/lib/linux/gcc
   export LD_LIBRARY_PATH
   #  
   
   
# ==================== EOF of linux-env.sh =======================
