 Progress v1.01 for Linux
 2023-2025 (c) Alain Aupeix
 alain.aupeix@wanadoo.fr
 
 Modifications by DF7BE: Cross platform port.
 
 History:
 
 
 2025-03-14 DF7BE           Cross platform port Windows and MacOS
 2025-03-08 Alain Aupeix    First creation (received by EMail at 2025-03-08 14:25) 
 

 1) Why ?

	As it's not possible to have a progress bar during a 'for/next' or a
	'do while/enddo' without loosing it under the program, I make this
	little external tool.

 2) Pre-requites ?

 
	Windows: no external prerequisites

	LINUX:
	You must have install the tool wmctrl
        sudo apt install wmctrl

	MacOS: 
	(install from mac ports):
	Command for installing "wmctrl" is:
    sudo port install wmctrl
	(For details see install-macos.txt)


 3) Build progress

 (LINUX and MacOS only)
 
	Set the correct path'es in progress.hbp
	hbmk2 progress.hbp

	Once progress is created, put it in the path :
		cp progress ~/bin
		The directory $HOME/bin may not exist, create it with mkdir ~/bin.
		 Edit your .profile to add the path:
		 export PATH=$PATH:/$HOME/bin
		or
		sudo cp progress /usr/local/bin (root permission needed, here example by sudo command)
		or modify line 61 of demo_progress.prg:
		run("progress ..   ==> run("./progress
		to start from recent directory
		(or every other location you decide)

 4) How to use it ?

	Windows: only demo_progres.prg is needed.
	Contains the code also for WinAPI.
	The codes for the different platforms are
	selected by:
	#ifdef __PLATFORM__WINDOWS
 
	LINUX/MacOS:
	The program must be like that :
 		for <condition>
		   create the file 'what' under /tmp
		   run the tool progress (which can be put in the path)
		   do your treatment
		next
		kill progress
		delete what (Command: hb_run("rm /tmp/what") )


 5) Syntax of the command to create 'what' file

	(not Windows)
 
	hb_memowrit("/tmp/what","line 1 of the texte"+"#!"+"line 2 of the texte"+;
		    chr(10)+"title of the progress dialog")

	chr(10) is use to separate the text from the title
	#! is use to separate lines in progress

 6) Demo

    
	(Cross platform)
 
	build demo_progres:

	hbmk2 demo_progres.hbp

	run demo_progres
	Windows:
	demo_progres.exe

	or LINUX/MacOS:
	./demo_progres

 7) Some warnings:
 
   (Not Windows)

	The file 'what' must be located in /tmp

	There must not be a program running in the same time which has part of
	his title which contains 'progress', else progress wouldn't be killed.

 Have fun !!!
 
 
 ====================== EOF of Readme.txt ========================
