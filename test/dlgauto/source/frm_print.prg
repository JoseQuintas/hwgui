/*
frm_print - single report
*/

#define CFG_FNAME     1
#define CFG_FPICTURE  6
#define CFG_CAPTION   7
#define PAGE_ROWS     66
#define PAGE_COLS     132

FUNCTION frm_Print( Self )

   LOCAL aItem, nPag, nLin, nCol, nLen, nLinAnt

   SET PRINTER TO ( "rel.lst" )
   SET DEVICE TO PRINT
   nPag := 0
   nLin := 99
   GOTO TOP
   DO WHILE ! Eof()
      IF nLin > PAGE_ROWS - 2
         nPag += 1
         @ 0, 0 SAY gui_LibName()
         @ 0, 66 - Int( Len( ::cFileDbf ) / 2 ) SAY ::cFileDBF
         @ 0, PAGE_COLS - 9 SAY "Page " + StrZero( nPag, 3 )
         @ 1, 0 SAY Replicate( "-", PAGE_COLS )
         nLin := 2
         nCol := 0
         FOR EACH aItem IN ::aEditList
            nLen := Max( Len( aItem[ CFG_CAPTION ] ), Len( Transform( FieldGet( FieldNum( aItem[ CFG_FNAME ] ) ), aItem[ CFG_FPICTURE ] ) ) )
            IF nCol != 0 .AND. nCol + nLen > PAGE_COLS - 1
               nLin += 1
               nCol := 0
            ENDIF
            @ nLin, nCol SAY aItem[ CFG_FNAME ]
            nCol += nLen + 2
         NEXT
         nLin += 1
      ENDIF
      nCol := 0
      nLinAnt := nLin
      FOR EACH aItem IN ::aEditList
         nLen := Max( Len( aItem[ CFG_CAPTION ] ), Len( Transform( FieldGet( FieldNum( aItem[ CFG_FNAME ] ) ), aItem[ CFG_FPICTURE ] ) ) )
         IF nCol != 0 .AND. nCol + nLen > PAGE_COLS - 1
            nLin += 1
            nCol := 0
         ENDIF
         @ nLin, nCol SAY Transform( FieldGet( FieldNum( aItem[ CFG_FNAME ] ) ), "" )
         nCol += nLen + 2
      NEXT
      nLin += 1 + iif( nLinAnt != nLin, 1, 0 )
      SKIP
   ENDDO

   SET DEVICE TO SCREEN
   SET PRINTER TO

   frm_Preview( "rel.lst", Self )
   fErase( "rel.lst" )

   RETURN Nil

