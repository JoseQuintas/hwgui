/*
 * HWGUI using sample
 * 
 *
 * Jose Augusto M de Andrade Jr - jamaj@terra.com.br
 * 
*/

#include "windows.ch"
#include "guilib.ch"

static aChilds := {}

function Main()
   Local oMainWindow

   INIT WINDOW oMainWindow MAIN TITLE "HwGui - Child Windows Example" STYLE WS_CLIPCHILDREN ;

   MENU OF oMainWindow
      MENUITEM "&Exit" ACTION hwg_EndWindow()
      MENUITEM "&Create a child" ACTION CreateChild()
   ENDMENU


   ACTIVATE WINDOW oMainWindow

return (NIL)



function CreateChild(lClip)
   Local oChild
   Local cTitle := "Child Window #" + Str(len(aChilds)+1,2,0)
   Local oIcon := HIcon():AddFile("..\image\PIM.ICO")
   Local oBmp  := HBitMap():AddFile("..\image\logo.bmp")
   Local cMenu := ""
   Local bExit := { | oSelf | hwg_Msginfo( "Bye!" , "Destroy message from " + oSelf:title )  }

   DEFAULT lClip := .f.


   /*
   oChild := HWindow():New( WND_CHILD , oIcon,hwg_ColorC2N("0000FF"),NIL,10,10,200,100,cTitle,cMenu,NIL,NIL, ;
                          NIL,bExit,NIL,NIL,NIL,NIL,NIL, "Child_" + Alltrim(Str(len(aChilds))) , oBmp )
   */
   
   oChild := HChildWindow():New( oIcon,hwg_ColorC2N("0000FF"),NIL,10,10,200,100,cTitle,cMenu,NIL,NIL, ;
                          bExit,NIL,NIL,NIL,NIL,NIL, "Child_" + Alltrim(Str(len(aChilds))) , NIL )
   
   // Test if we could create the window object 
   If ISOBJECT(oChild)
      aAdd(aChilds,oChild)
   Else
       hwg_Msgstop("Erro ao tentar criar objeto HWindow!")
   Endif

   oChild:Activate(.t.)

return (NIL)
