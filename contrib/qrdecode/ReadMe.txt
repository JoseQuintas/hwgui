ReadMe file for QR code and EAN bar codes decoding
 from HWGUI program by using a camera.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
 
 
Supported platforms:
- Windows 10/11
- LINUX <under construction>
- MacOS <under construction>  


1. Prerequisites
----------------

1.1. A full operating HWGUI system on your computer

1.2. A working computer camera
     Check it with your camera app delivered by the
     operating system.
     If not, you find many troubleshooting procedures in
     the internet (camera device driver update, device manager, ...) 
     Also be shure, that the camera is not used by another
     application.
     Usually, a little LED nearby the lens indicates, that
     the camera is activated.

1.3  Install ZBar

     Windows:

     The easy way is to install the prebuild setup
     for ZBar. 
     (File name is zbar-0.10-setup.exe , tested with Windows 10 and 11)
    
     LINUX and MacOS:
     <under construction>
   
     Get source code from
     https://sourceforge.net/projects/zbar

     Optional these files are also available in the "Files"
     section of the HWGUI project site.

1.4 Pre-check of Zbar
    Open a console or terminal and insert the following command:
    Windows:
     "C:\Program Files (x86)\Zbar\bin\zbarcam.exe"
    (with "").
    LINUX and MacOS:
      zbarcam

    First the splash window of ZBar appeared, then a window
    shows the camera image.
    Take now QR codes or bar codes.
    If a QR or bar code is detected, the code image is
    marked by red frame. If the code is successfully decoded,
    the color of the frame is turned to green.
    Also a short beep is sounded.
    The result text is sent to the console or terminal.
    You can take more than one QR or bar code in one session (mixed).
    If finished, close the Zbar app by clicking to the "X" field.
    Now the output file (here STDIN, later the redirected output
    file of the hwg_RunConsoleApp() function call (2nd parameter),
    so all results can be seen or processed.
    

    Get help info by typing:
     zbarcam --help  
    (if zbarcam is in PATH, otherwise add full path)

2. HWGUI test program

2.1 Compile the sample program

    CD to directory contrib\qrdecode
    and enter:
     hbmk2 qrdecode.hbp

2.2 Run the sample program
      qrdecode.exe
    or
      ./qrdecode
 
 
    Start the scan process by pressing the "Scan" button.
    The behavior is described in chapter 1.4
    If finished, the output file "output.txt" is closed
    and contains the complete result.

2.3 Your job

    Process the result by reading the output file
    line by line in your HWGUI app to your own needs.

3. Output format:

   Every scan operation starts with a string
   "QR-Code:" or "EAN-13:".
   QR codes may be have more than line, they are
   delimited by the line ending of the operating system.
   For every decoded issue the ASCII character BEL = 0x07
   is appended at the end of the output file 
   (for every beep).

   For example:
QR-Code:TO:DF7BE/M
VIA:
FRM:DK0YLO
QR-Code:OPERATOR;QSO_DATE;TIME_ON;BAND;MODE;RST_SENT;QSL_RCVD;
DK0YLO;11.07.17;17:23;70CM;FM;59;PSE;

EAN-13:4190784301991
QR-Code:https://

   
   Both QR-Codes at top: Sample printed on a QSL card.
   The 1st line is a header to explain the data fields.
   The 2nd line is data of a radio contact in CSV format +
   a blank line.
   
   
Have fun decoding lot's of QR or bar codes in your HWGUI
application.

73 es 55 de
DF7BE, Wilfried    

================= EOF of ReadMe.txt =========================