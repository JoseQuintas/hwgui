* Create the what command for progressbar tool by Alain Aupaix
*
* Compile with:
* hbmk2 crwhat.prg
* and run:
* ./crwhat	

FUNCTION MAIN()

hb_memowrit("/tmp/what","line 1 of the texte"+"#!"+"line 2 of the texte"+;
		    chr(10)+"title of the progress dialog")

*	chr(10) is use to separate the texte from the title
*	#! is use to separate lines in progress
RETURN NIL

* =============== EOF of crwhat.prg ==================
