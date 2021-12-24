/*
 * HWGUI using sample
 * 
 * $Id$
 *
 * Jose Augusto M de Andrade Jr - jamaj@terra.com.br
 * 
 * Modifications by DF7BE:
 * - Ticket 102: PIM.ICO does not exist any more, use W.ico instead
 *               Don't working yet, bug must be found in source code file
 *               hwindow.prg, about line 529
 *               (to be continued)
 *   
 * - Need for GTK : Port of function HCHILDWINDOW() 
*/

#include "windows.ch"
#include "guilib.ch"

static aChilds := {}

function Main()
   Local oMainWindow

   INIT WINDOW oMainWindow MAIN TITLE "HwGui - Child Windows Example" STYLE WS_CLIPCHILDREN ;

   MENU OF oMainWindow
#ifdef __GTK__
     MENU TITLE "&Exit"
      MENUITEM "&Quit" ACTION hwg_EndWindow()
     ENDMENU
     MENU TITLE "&Test"
      MENUITEM "&Create a child" ACTION CreateChild()
     ENDMENU
#else   
      MENUITEM "&Exit" ACTION hwg_EndWindow()
      MENUITEM "&Create a child" ACTION CreateChild()
#endif
   ENDMENU


   ACTIVATE WINDOW oMainWindow

return (NIL)



function CreateChild(lClip)
   Local oChild
   Local cdirsep := hwg_GetDirSep()
#ifdef __GTK__
   Local cImagdir := ".." + cdirsep + ".." + cdirsep + "image" + cdirsep
#else
   Local cImagdir := ".." + cdirsep + "image" + cdirsep 
#endif   

   Local cTitle := "Child Window #" + Str(len(aChilds)+1,2,0)
   Local oIcon := HIcon():AddFile(cImagdir + "W.ico")
   Local oBmp  := HBitMap():AddFile(cImagdir + "logo.bmp")
   Local cMenu := ""
   Local bExit := { | oSelf | hwg_Msginfo( "Bye!" , "Destroy message from " + oSelf:title )  }

   DEFAULT lClip := .f.

    /*
   oChild := HWindow():New( WND_CHILD , oIcon,hwg_ColorC2N("0000FF"),NIL,10,10,200,100,cTitle,cMenu,NIL,NIL, ;
                          NIL,bExit,NIL,NIL,NIL,NIL,NIL, "Child_" + Alltrim(Str(len(aChilds))) , oBmp )
    */
   
   * The class HChildWindow is coded in file hwindow.prg at about line 517
   
   oChild := HChildWindow():New( oIcon,hwg_ColorC2N("0000FF"),NIL,10,10,200,100,cTitle,cMenu,NIL,NIL, ;
                          bExit,NIL,NIL,NIL,NIL,NIL, "Child_" + Alltrim(Str(len(aChilds))) , NIL )

   
   // Test if we could create the window object 
   If ISOBJECT(oChild)
      hwg_MsgInfo("Child object exists") 
      aAdd(aChilds,oChild)
   Else
       * Erro ao tentar criar objeto HWindow!
       hwg_Msgstop("Error trying to create object HWindow!")
   Endif

   oChild:Activate(.t.)

return (NIL)

* ===================================== EOF of testchild.prg =============================================
