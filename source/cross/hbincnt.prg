/*
 *$Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HBinC class
 *
 * Copyright 2014 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hbclass.ch"
#include "fileio.ch"

/* Data structure:
 * Header: "hwgbc" ver(2b) reserve(1b)  N items  Contents Len  Contents blocks  Pass Length Pass info
 *         ---------------------------  -------  ------------  ---------------  ----------- ---------
 *                    8b                 2b          3b             1b               1b      1 - 64b
 * Contents item:
 *         Name Length    Name     Type   Address   Size  Flags
 *         -----------  ---------  ----   -------   ----  -----
 *             1 b       1 - 32b    4b      4b       4b     2b
 */

#define VER_HIGH   1
#define VER_LOW       0
#define HEAD_LEN     15
#define CNT_FIX_LEN  15

#define OBJ_NAME      1
#define OBJ_TYPE      2
#define OBJ_VAL       3
#define OBJ_SIZE      4
#define OBJ_ADDR      5

STATIC oResCnt
STATIC cHead := "hwgbc"

CLASS HBinC

   DATA   cName
   DATA   handle
   DATA   lWriteAble
   DATA   nVerHigh, nVerLow
   DATA   nItems
   DATA   nCntLen
   DATA   nCntBlocks
   DATA   nPassLen

   DATA   nFileLen

   DATA   aObjects

   METHOD Create( cName, n )
   METHOD Open( cName, lWr )
   METHOD Close()
   METHOD Add( cObjName, cType, cVal )
   METHOD Del( cObjName )
   METHOD Pack()
   METHOD Exist( cObjName )
   METHOD Get( cObjName )
   METHOD GetPos( cObjName )
   METHOD GetType( cObjName )

ENDCLASS

METHOD Create( cName, n ) CLASS HBinC

   IF n == Nil; n := 16; ENDIF

   IF ( ::handle := FCreate( cName ) ) == -1
      RETURN Nil
   ENDIF

   ::cName := cName
   ::lWriteAble := .T.
   ::nVerHigh := VER_HIGH
   ::nVerLow := VER_LOW
   ::nItems  := ::nCntLen := ::nPassLen := 0
   ::nCntBlocks := Iif( n <= 18, 1, 2 + Int( (n-18)/21 ) )
   ::nFileLen := ::nCntBlocks*2048
   ::aObjects := {}

   FWrite( ::handle, cHead + Chr(::nVerHigh) + Chr(::nVerLow) + ;
         Replicate( Chr(0), 6 ) + Chr(::nCntBlocks) + ;
         Replicate( Chr(0), ::nCntBlocks*2048 - 14 ) )

   RETURN Self

METHOD Open( cName, lWr ) CLASS HBinC

   LOCAL cBuf, i, nLen, arr, nAddr := 0

   ::cName := cName
   ::lWriteAble := !Empty( lWr )
   IF ( ::handle := FOpen( cName, Iif( ::lWriteAble, FO_READWRITE, FO_READ ) ) ) == -1
      RETURN Nil
   ENDIF

   cBuf := Space( HEAD_LEN )
   FRead( ::handle, @cBuf, HEAD_LEN )
   IF Left( cBuf,5 ) != cHead
      FClose( ::handle )
      RETURN Nil
   ENDIF

   ::nVerHigh := Asc( Substr( cBuf, 6, 1 ) )
   ::nVerLow  := Asc( Substr( cBuf, 7, 1 ) )
   ::nItems   := Asc( Substr( cBuf, 9, 1 ) ) * 256 + Asc( Substr( cBuf, 10, 1 ) )
   ::nCntLen  := Asc( Substr( cBuf, 11, 1 ) ) * 65536 + Asc( Substr( cBuf, 12, 1 ) ) * 256 + Asc( Substr( cBuf, 13, 1 ) )
   ::nCntBlocks := Asc( Substr( cBuf, 14, 1 ) )
   ::nPassLen := Asc( Substr( cBuf, 15, 1 ) )
   ::nFileLen := FSeek( ::handle, 0, FS_END )

   FSeek( ::handle, HEAD_LEN + ::nPassLen, FS_SET )
   cBuf := Space( ::nCntLen )
   FRead( ::handle, @cBuf, ::nCntLen )

   ::aObjects := Array( ::nItems )
   FOR i := 1 TO ::nItems
      nLen := Asc( Substr( cBuf, nAddr+1 ) )
      arr := Array( 5 )
      arr[OBJ_NAME] := Substr( cBuf, nAddr+2, nLen )
      arr[OBJ_TYPE] := Substr( cBuf, nAddr+nLen+2, 4 )
      arr[OBJ_VAL]  := Asc( Substr( cBuf, nAddr+nLen+6, 1 ) ) * 16777216 + ;
            Asc( Substr( cBuf, nAddr+nLen+7, 1 ) ) * 65536 + Asc( Substr( cBuf, nAddr+nLen+8, 1 ) ) * 256 + Asc( Substr( cBuf, nAddr+nLen+9, 1 ) )
      arr[OBJ_SIZE] := Asc( Substr( cBuf, nAddr+nLen+10, 1 ) ) * 16777216 + ;
            Asc( Substr( cBuf, nAddr+nLen+11, 1 ) ) * 65536 + Asc( Substr( cBuf, nAddr+nLen+12, 1 ) ) * 256 + Asc( Substr( cBuf, nAddr+nLen+13, 1 ) )
      arr[OBJ_ADDR] := nAddr
      ::aObjects[i] := arr
      nAddr += nLen + CNT_FIX_LEN
   NEXT

   RETURN Self

METHOD Close() CLASS HBinC

   FClose( ::handle )

   RETURN Nil

METHOD Add( cObjName, cType, cVal ) CLASS HBinC

   LOCAL nAddress, nSize, cAddress, cSize, nAddr

   IF !::lWriteAble
      RETURN .F.
   ENDIF
   cObjName := Lower( cObjName )
   cType := Padr( Lower( Left( cType, 4 ) ), 4 )
   IF Ascan( ::aObjects, {|a|a[OBJ_NAME] == cObjName} ) > 0
      RETURN .F.
   ENDIF

   nAddress := ::nFileLen
   nSize := Len( cVal )
   nAddr := Iif( Empty(::aObjects), 0, ::aObjects[Len(::aObjects),OBJ_ADDR] + Len(::aObjects[Len(::aObjects),OBJ_NAME]) + CNT_FIX_LEN )
   Aadd( ::aObjects, { cObjName, cType, nAddress, nSize, nAddr } )

   IF HEAD_LEN + ::nPassLen + ::nCntLen + Len(cObjName) + CNT_FIX_LEN > ::nCntBlocks*2048
      :: Pack()
      IF HEAD_LEN + ::nPassLen + ::nCntLen + Len(cObjName) + CNT_FIX_LEN > ::nCntBlocks*2048
      ENDIF
   ENDIF

   FSeek( ::handle, 0, FS_END )
   FWrite( ::handle, cVal )
   ::nFileLen += nSize

   cAddress := Chr( nAddress/16777216 ) + Chr( (nAddress/65536)%256 ) + Chr( (nAddress/256)%65536 ) + Chr( nAddress%16777216 )
   cSize := Chr( nSize/16777216 ) + Chr( (nSize/65536)%256 ) + Chr( (nSize/256)%65536 ) + Chr( nSize%16777216 )
   FSeek( ::handle, HEAD_LEN + ::nPassLen + nAddr, FS_SET )
   FWrite( ::handle, Chr(Len(cObjName))+cObjName+cType+cAddress+cSize+Chr(0)+Chr(0) )

   ::nItems ++
   ::nCntLen += Len(cObjName) + CNT_FIX_LEN
   cAddress := Chr( ::nItems/256 ) + Chr( ::nItems%256 )
   cSize := Chr( ::nCntLen/65536 ) + Chr( (::nCntLen/256)%256 ) + Chr( ::nCntLen%65536 )
   FSeek( ::handle, 8, FS_SET )
   FWrite( ::handle, cAddress+cSize )

   RETURN .T.

/* Removed: cType */
METHOD Del( cObjName ) CLASS HBinC

   LOCAL n

   IF !::lWriteAble
      RETURN .F.
   ENDIF
   cObjName := Lower( cObjName )
   IF ( n := Ascan( ::aObjects, {|a|a[OBJ_NAME] == cObjName} ) ) == 0
      RETURN .F.
   ENDIF

   FSeek( ::handle, HEAD_LEN + ::nPassLen + ::aObjects[n,OBJ_ADDR] + 1, FS_SET )
   FWrite( ::handle, Replicate( ' ', Len(cObjName)+4 ) )
   ::aObjects[n,OBJ_NAME] := ::aObjects[n,OBJ_TYPE] := ""

   RETURN .T.

METHOD Pack() CLASS HBinC

   LOCAL i, nItems := 0, nCntLen := 0
   LOCAL nAddr, cAddr, cSize, a
   LOCAL s := cHead + Chr(::nVerHigh) + Chr(::nVerLow) + Chr(0), handle, cTempName

   IF !::lWriteAble
      RETURN .F.
   ENDIF

   Aeval( ::aObjects, {|a| Iif(!Empty(a[OBJ_NAME]), (nItems++,nCntLen+=Len(a[OBJ_NAME])+CNT_FIX_LEN),.T.) } )
   IF nItems == ::nItems
      RETURN .T.
   ENDIF

   cTempName := ::cName + ".new"
   IF ( handle := FCreate( cTempName ) ) == -1
      RETURN .F.
   ENDIF

   ::nItems := nItems
   ::nCntLen := nCntLen

   cAddr := Chr( nItems/256 ) + Chr( nItems%256 )
   cSize := Chr( nCntLen/65536 ) + Chr( (nCntLen/256)%256 ) + Chr( nCntLen%65536 )
   s += cAddr + cSize + Chr(::nCntBlocks) + Chr(::nPassLen)

   nAddr := ::aObjects[1,OBJ_VAL]
   FOR i := 1 TO Len( ::aObjects )
      a := ::aObjects[i]
      IF !Empty( a[OBJ_NAME] )
         cAddr := Chr( nAddr/16777216 ) + Chr( (nAddr/65536)%256 ) + Chr( (nAddr/256)%65536 ) + Chr( nAddr%16777216 )
         cSize := Chr( a[OBJ_SIZE]/16777216 ) + Chr( (a[OBJ_SIZE]/65536)%256 ) + Chr( (a[OBJ_SIZE]/256)%65536 ) + Chr( a[OBJ_SIZE]%16777216 )
         nAddr += a[OBJ_SIZE]
         s += Chr(Len(a[OBJ_NAME]))+a[OBJ_NAME]+a[OBJ_TYPE]+cAddr+cSize+Chr(0)+Chr(0)
      ENDIF
   NEXT

   FWrite( handle, s )
   FWrite( handle, Replicate( Chr(0), ::nCntBlocks*2048 - Len(s) ) )

   FOR i := 1 TO Len( ::aObjects )
      IF !Empty( ::aObjects[i,OBJ_NAME] )
         s := Space( ::aObjects[i,OBJ_SIZE] )
         FSeek( ::handle, ::aObjects[i,OBJ_VAL], FS_SET )
         FRead( ::handle, @s, ::aObjects[i,OBJ_SIZE] )
         FWrite( handle, s, ::aObjects[i,OBJ_SIZE] )
      ENDIF
   NEXT

   FClose( handle )
   FClose( ::handle )
   FErase( ::cName )
   FRename( cTempName, ::cName )

   IF ::Open( ::cName, ::lWriteAble ) == Nil
      ::nItems := 0
      ::aObjects := Nil
   ENDIF

   RETURN .T.

METHOD Get( cObjName ) CLASS HBinC

   LOCAL n, cBuf

   cObjName := Lower( cObjName )
   IF ( n := Ascan( ::aObjects, {|a|a[OBJ_NAME] == cObjName} ) ) == 0
      RETURN Nil
   ENDIF

   cBuf := Space( ::aObjects[n,OBJ_SIZE] )
   FSeek( ::handle, ::aObjects[n,OBJ_VAL], FS_SET )
   FRead( ::handle, @cBuf, ::aObjects[n,OBJ_SIZE] )

   RETURN cBuf

METHOD Exist( cObjName )  CLASS HBinC

   cObjName := Lower( cObjName )

   RETURN ( Ascan( ::aObjects, {|a|a[OBJ_NAME] == cObjName} ) ) != 0

METHOD GetPos( cObjName )  CLASS HBinC

  cObjName := Lower( cObjName )

  RETURN  Ascan( ::aObjects, {|a|a[OBJ_NAME] == cObjName} )


METHOD GetType( cObjName )

  LOCAL n, crettype := ""

  cObjName := Lower( cObjName )

  n:=  Ascan( ::aObjects, {|a|a[OBJ_NAME] == cObjName} )

  IF n > 0
    crettype := ::aObjects[n,OBJ_TYPE]
  ENDIF

  RETURN crettype

/*
 Functions for Binary Container handling
 List of array elements:
 OBJ_NAME      1
 OBJ_TYPE      2
 OBJ_VAL       3
 OBJ_SIZE      4
 OBJ_ADDR      5
*/

FUNCTION hwg_SetResContainer( cName )

   // Returns .T., if container is opened successfully

   IF Empty( cName )
      IF !Empty( oResCnt )
         oResCnt:Close()
         oResCnt := Nil
      ENDIF
   ELSE
      IF Empty( oResCnt := HBinC():Open( cName ) )
         RETURN .F.
      ENDIF
   ENDIF

   RETURN .T.

FUNCTION hwg_GetResContainerOpen()

   // Returns .T., if a container is open
   IF !Empty( oResCnt )
      RETURN .T.
   ENDIF

   RETURN .F.

FUNCTION hwg_GetResContainer()

   // Returns the object of opened container,
   // otherwise NIL
   // (because the object variable is static)

   IF !Empty( oResCnt )
      RETURN oResCnt
   ENDIF

   RETURN NIL

FUNCTION hwg_ExtractResContItem2file( cfilename, cname )

   // Extracts an item with name cname of an opened
   // container to file cfilename
   // (get file extension with function
   // hwg_ExtractResContItemType() before)
   // Returns .T., if success, otherwise .F.
   // for example if no match.

   LOCAL n

   n := hwg_ResContItemPosition( cname )
   IF n > 0
      hb_MemoWrit( cfilename, oResCnt:Get( oResCnt:aObjects[n,1] ) )
      RETURN .T.
   ENDIF

   RETURN .F.

FUNCTION hwg_ExtractResContItemType( cname )

   // Extracts the type of item with name cname of an opened
   // container
   // Returns the type (bmp,png,ico,jpg)
   // as a string.
   // Empty string "", of container not open or no match

   LOCAL  cItemType := ""

   IF hwg_GetResContainerOpen()
      cItemType := oResCnt:GetType( cname )
   ENDIF

   RETURN cItemType

FUNCTION hwg_ResContItemPosition( cname )

   // Extracts the position number of item with name cname of an opened
   // container
   // Returns the position name of item in the container,
   // 0 , if no match or container not open.

   LOCAL i := 0

   IF hwg_GetResContainerOpen()
      i := oResCnt:GetPos( cname )
   ENDIF

   RETURN i

FUNCTION hwg_Bitmap2tmpfile( objBitmap , cname , cfextn )

   // Creates a temporary file from a bitmap object
   // Avoids trouble with imcompatibility of image displays.
   // Almost needed for binary container.
   // objBitmap : object from resource container (from HBitmap class)
   // cname     : resource name of object
   // cfextn    : file extension, for example "bmp" (Default)
   // Returns:
   // The temporary file name,
   // empty string, if error occured.
   // Don't forget to delete the temporary file after usage.
   // LOCAL ctmpbmpf
   // ctmpbmpf := hwg_Bitmap2tmpfile(obitmap , "sample" , "bmp")
   // hwg_MsgInfo(ctmpbmpf,"Temporary image file")
   // IF .NOT. EMPTY(ctmpbmpf)
   //  ...
   // ENDIF
   // ERASE &ctmpbmpf
   //
   // Read more about the usage of this function in the documentation
   // of the Binary Container Manager in the utils/bincnt directory.

   LOCAL ctmpfilename

   IF cfextn == NIL
      cfextn := "bmp"
   ENDIF

   ctmpfilename := hwg_CreateTempfileName( "img", "." + cfextn )
   objBitmap:OBMP2FILE( ctmpfilename , cname )

   IF .NOT. File( ctmpfilename )
      RETURN ""
   ENDIF

   RETURN ctmpfilename

   // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   // End of Binary Container functions
   // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
