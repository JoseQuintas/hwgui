/*
 *$Id: barcode.prg,v 1.2 2010-10-16 15:32:04 richardroesnadi Exp $
 *
 * HWGUI - Harbour Win32 GUI library 
 * 
 * File to Demonstrate Display Barcode to Form and Printer  
 * using hwgui xml technique.
 *
 * Copyright 2010 Richard Roesnadi <richsoft8@yahoo.com.id>
 * www - http://www.richard-software.com
*/



EXTERNAL BARCODE

PROCEDURE SHOWBARCODE

 HFORMTMPL():READ("BARCODE.XML"):SHOWMODAL()

RETURN
