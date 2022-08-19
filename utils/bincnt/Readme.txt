
Readme file for Binary Resource Management in HWGUI programs.

$Id$

Created by DF7BE, 2020-09-07.

Contents:
---------

0.) Introduction
1.) The Binary Container
2.) Hex value resources
3.) Additional information for WinAPI
4.) Additional bug information
5.) Add binary files to a container in a batch
6.) DBF as binary container


0.) Introduction
   Resources means images and icons in GUI applications.
   They could be loaded directly from an single image file(s)
   or compiled directly into the exe file.
   If loading a lot of image files, you must deliver them all with your
   setup script. This is uncomfortable. You can use the Windows resource
   compiler utility (HWGUI supports this), but for multi platform programs
   you must avoid the resource compiler.
   But there are 2 alternatives (as a good substitute for the Windows resource compiler):

   - The Binary Container
   - Hex value resources

   Here a short description.


1.) The Binary Container

    The binary container is a simple database containing
    all binary resources. You can create and edit the
    container with the utility "Binary Container Manager"
    in the current directory.
    Read more about this topic in HWGUI documentation
    "doc/hwgdoc_misc.html", chapter "7.6. Binary container manager".
    
    The sample program "samples/bincnts.prg"
    demonstrates the usage of items in a Binary Container file.

    Attention:
    The file size of the resulted container manager file may not
    exceed about 128 kByte. Otherwise the container
    "crackled records", refer the screenshot "Crackled_items.png".
    Make a backup copy of your binary container file before
    any modification.

    An alternative method is the usage of a DBF file,
    described in "6.) DBF as binary container".


2.) Hex value resources

    The program "file2hex.prg" converts the contents of a binary file
    into a hex string.
    You can paste and copy it into a source code file and it is
    compiled into the exe file, so no external file(s) for delivering
    them all is necessary.

    The sample program "hexbincnt.prg" demonstrates the usage.
    In the inline comment of the source code file you find instructions for use.

    For building the file2hex utility, copy a build script for your used compiler
    from the samples or samples/gtk_samples directory into the current directory and
    call it with parameter "file2hex" or by:
    hbmk2 file2hex.hbp .


3.) Additional information for WinAPI

    The Windows resources in the exe file can be read by the operating sytem for displaying
    icons on the desktop for a link file to a program.
    For icons it is recommended to use the Windows resource compiler.
    Use the compiler switch for multi platform applications (for example):


    #ifndef __GTK__
     oIcon1 := HIcon():AddResource( "ICON" )   && Windows
    #else
     oIcon1 := HIcon():AddString( "icon" , cValIcon  )  && *NIX with GTK, by hex values
    #endif

    For bitmaps the use of Hex value resources or the binary container it is no problem. 

    Read more information about iconification in HWGUI HTML documentation
    "doc/hwgdoc.html", chapter "3.11. Handling resources".

    
4.) Additional bug information

    - Container manager
       The exchange or removal of items (files) is buggy.
       So make a backup copy of your binary container file before you begin
       to add or edit items.
      Name conflict:
       If you want to add an item with same name, but other type,
       the recent type is overwritten without changing the type, for example:
        astro.bmp , astro.png, astro.jpg.
       If you want to add these file into one container, rename them with a unique name,
       for example:
        astro.bmp, astro2.jpg, astro3.png
       This is done in the sample program "bincnts.prg".
      Delete item not working:
       This bug will be fixed if we have time.  

    - Converting bitmaps to icons:
       First i converted a bitmap to icons with the "Greenfish Icon Editor" (gfie64),
       but the converted icon files are corrupt. On Windows they are displayed correct,
       but on Ubuntu LINUX 20 they are crackeld.
       On Windows the corrupted icons are displayed correct, so
       for multiplatform applications check them on LINUX, too !
       This is also visible in the preview of the file viewer.
       But new created icons seemed to be OK.
      
       Because of this i tested the conversion with IrfanView64:
       Load the bitmap file, goto menu "Modify size" and set the desired
       file size (recommeded default size for Icons is 48 x 48 pixels), and save the
       image as "Windows icon". Now they are OK.
                      
  
5.) Add binary files to a container in a batch 

With the HWGUI container manager "bincnt.prg" it is
very hard to add a lot of files to a binary container manually.

With the program "addbatitem.prg" and the sample batch "sample.bat"
it is no problem do that.
Here in this example a lot of bitmap images are to add.

Instructions:
Build the binary container manager "bincnt.prg" as described in "1.) The Binary Container".

Compile the import program by:
hbmk2 addbatitem.prg
Copy the created file "addbatitem.exe" and "bincnt.exe"
(the binary container manager) into your working directory.

Also copy all files to import and the batch "sample.bat"
into this directory.
The files to import must have the same file extension !
Modify sample.bat to your own needs. 

The container to be filled, must be existing.
Before starting the import, make a backup copy
of the container file.

If you start at scratch, create a new container with
the binary container manager:
File / Create

Enter file name for
binary container to create,
for example sample.bin 

Start your import by calling 
sample.bat

Now the binary container is filled.
Check your result with the Binary container manager.

In case of errors, recover the binary container file
from your backup copy.


6.) DBF as binary container
    (To be continued)

    It seems, that there are no size limits known.
    A 2,8 Mbyte big exe file was added and exported.
    Let us know, if you a find a size limit.

    The file bindbf.prg is the source code
    of the binary container manager.

    Compile the container mamager with
    hbmk2 bindbf.hbp

    First create an new DBF file, after than
    open the file.

    Now you add binary files and export them.


    In the next steps, we will add the following features:
    - Handle resources
    - Add a lot files within a batch.
    - Display bitmaps in the container manager.


* =============== EOF of Readme.txt ================================
  
