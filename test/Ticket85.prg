* Ticket #85:

* At first:
* Labels and buttons are objects, so the methods of the calls must be called
* to process them.
* For more details, read the class reference of HWGUI


#include "hwgui.ch"

// This init an array with only one element with numeric value 2, not the number of elements
// STATIC o_BUTTON := { 2 }
// STATIC o_LABEL := { 2 }

STATIC o_BUTTON := {"","" }
STATIC o_LABEL := {"","" }

* Please care: every element of the array stores one object !

// in main function

FUNCTION MAIN()
   LOCAL oMainWindow, nlauf

/*
 Alternative:
  STATIC o_BUTTON := {  }
  STATIC o_LABEL := {  }
  ...
FOR nlauf := 1 TO 2
 AADD(o_BUTTON,"")
 AADD(o_LABEL,"")
NEXT */ 



   INIT WINDOW oMainWindow MAIN TITLE "Ticket 85" AT 168,50 SIZE 350,350 

// after window declaration i put

@ 10, 70 BUTTON o_BUTTON[ 1 ] CAPTION "Apri 1" OF oMAINWINDOW ;
ON CLICK { || START( 1 ) } ;


@ 10, 90 BUTTON o_BUTTON[ 2 ] CAPTION "Clx" OF oMAINWINDOW 
// then

@ 180, 75 SAY o_LABEL[1] CAPTION "Open" SIZE 65, 30

@ 180, 95 SAY o_LABEL[2] CAPTION "JoJo" SIZE 65, 30
// ...
// ...

* Be sure,that all objects are created !
* 
o_BUTTON[ 1 ]:SetText("Open2")
o_LABEL[1]:SetText("XYZ")
o_BUTTON[ 2 ]:SetText("Closed2")
o_LABEL[2]:SetText("Two")


  ACTIVATE WINDOW oMainWindow

RETURN Nil

FUNCTION START( nBUTTON )
LOCAL nPOSTO := 2
o_LABEL[ nPOSTO ]:SetText("Opened")
RETURN NIL

/*
there is no problem compiling, but when i run the program. i have

Error BASE/1068 Argument error: array access
on line where is the say

why i need this solution, because when i push the button the value of the label have to change with some value

if i use two or more STATIC labels definition, all works

o_LABEL1 := ""
o_LABEL2 := ""
*/
