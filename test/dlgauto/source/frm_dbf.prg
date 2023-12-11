/*
frm_DBF - Create DBF for test
*/

FUNCTION frm_DBF()

   LOCAL nCont, cTxt

   IF ! File( "DBCLIENT.DBF" )
      dbCreate( "DBCLIENT", { ;
         { "IDCLIENT", "N+", 6, 0 }, ;
         { "CLNAME",     "C", 50, 0 }, ;
         { "CLDOC",  "C", 18, 0 }, ;
         { "CLADDRESS",     "C", 50, 0 }, ;
         { "CLCITY", "C", 20, 0 }, ;
         { "CLSTATE", "C", 2, 0 }, ;
         { "CLMAIL", "C", 50, 0 }, ;
         { "CLSELLER", "N", 6, 0 }, ;
         { "CLBANK", "N", 6, 0 } } )
      USE DBCLIENT
      FOR nCont = 1 TO 9
         cTxt := Replicate( "CLIENT" + Str( nCont, 1 ), 10 )
         APPEND BLANK
         REPLACE IDCLIENT WITH nCont, CLNAME WITH cTxt, CLDOC WITH cTxt, ;
            CLADDRESS WITH cTxt, CLCITY WITH cTxt, CLSTATE WITH StrZero( nCont, 2 ), ;
            CLMAIL WITH cTxt, CLSELLER WITH nCont, CLBANK WITH nCont
      NEXT
      INDEX ON field->IDCLIENT TAG primary
      INDEX ON field->CLNAME TAG name
      USE
   ENDIF
   IF ! File( "DBPRODUCT.DBF" )
      dbCreate( "DBPRODUCT", { ;
         { "IDPRODUCT", "N+", 6, 0 }, ;
         { "PRNAME",    "C", 50, 0 }, ;
         { "PRUNIT",   "N", 6, 0 }, ;
         { "PRGROUP",   "N", 6, 0 }, ;
         { "PRNCM",     "C", 8, 0 }, ;
         { "PRQT",      "N", 6, 0 }, ;
         { "PRVALUE",   "N", 14, 2 } } )
      USE DBPRODUCT
      FOR nCont = 1 TO 9
         cTxt := Replicate( "PRODUCT" + Str( nCont, 1 ), 10 )
         APPEND BLANK
         REPLACE IDPRODUCT WITH nCont, PRNAME WITH cTxt, PRUNIT WITH nCont, ;
            PRGROUP WITH nCont, PRNCM WITH cTxt, PRQT WITH nCont, ;
            PRVALUE WITH nCont
      NEXT
      INDEX ON field->IDPRODUCT TAG primary
      INDEX ON field->PRNAME TAG name
      USE
   ENDIF
   IF ! File( "DBUNIT.DBF" )
      dbCreate( "DBUNIT", { ;
         { "IDUNIT", "N+", 6, 0 }, ;
         { "UNSYMBOL", "C", 8, 0 }, ;
         { "UNNAME",  "C", 30, 0 } } )
      USE DBUNIT
      FOR nCont = 1 TO 9
         cTxt := Replicate( "UNIT" + Str( nCont, 1 ), 10 )
         APPEND BLANK
         REPLACE IDUNIT WITH nCont, UNSYMBOL WITH cTxt, UNNAME WITH cTxt
      NEXT
      INDEX ON field->IDUNIT TAG primary
      INDEX ON field->UNNAME TAG name
      USE
   ENDIF
   IF ! File( "DBSELLER.DBF" )
      dbCreate( "DBSELLER", { ;
         { "IDSELLER", "N+", 6, 0 }, ;
         { "SENAME",   "C", 30, 0 } } )
      USE DBSELLER
      FOR nCont = 1 TO 9
         cTxt := Replicate( "SELLER" + Str( nCont, 1 ), 10 )
         APPEND BLANK
         REPLACE IDSELLER WITH nCont, SENAME WITH cTxt
      NEXT
      INDEX ON field->IDSELLER TAG primary
      INDEX ON field->SENAME TAG name
      USE
   ENDIF
   IF ! File( "DBBANK.DBF" )
      dbCreate( "DBBANK", { ;
         { "IDBANK", "N+", 6, 0 }, ;
         { "BANAME",   "C", 30, 0 } } )
      USE DBBANK
      FOR nCont = 1 TO 9
         cTxt := Replicate( "BANK" + Str( nCont, 1 ), 10 )
         APPEND BLANK
         REPLACE IDBANK WITH nCont, BANAME WITH cTxt
      NEXT
      INDEX ON field->IDBANK TAG primary
      INDEX ON field->BANAME TAG name
      USE
   ENDIF
   IF ! File( "DBGROUP.DBF" )
      dbCreate( "DBGROUP", { ;
         { "IDGROUP", "N+", 6, 0 }, ;
         { "GRNAME", "C", 30, 0 } } )
      USE DBGROUP
      FOR nCont = 1 TO 9
         cTxt := Replicate( "GROUP" + Str( nCont, 1 ), 10 )
         APPEND BLANK
         REPLACE IDGROUP WITH nCont, GRNAME WITH cTxt
      NEXT
      INDEX ON field->IDGROUP TAG primary
      INDEX ON field->GRNAME TAG name
      USE
   ENDIF
   IF ! File( "DBSTOCK.DBF" )
      dbCreate( "DBSTOCK", { ;
         { "IDSTOCK", "N+", 6, 0 }, ;
         { "STDATOPER", "D", 8, 0 }, ;
         { "STPRODUCT", "N", 6, 0 }, ;
         { "STCLIENT", "N", 6, 0 }, ;
         { "STNUMDOC", "C", 10, 0 }, ;
         { "STQT", "N", 10, 0 } } )
      USE DBSTOCK
      FOR nCont = 1 TO 9
         cTxt := Replicate( "STOCK" + Str( nCont, 1 ), 10 )
         APPEND BLANK
         REPLACE IDSTOCK WITH nCont, STDATOPER WITH Date() + nCont, ;
            STCLIENT WITH nCont, STNUMDOC WITH cTxt, ;
            STPRODUCT WITH nCont, STQT WITH nCont
      NEXT
      INDEX ON field->IDSTOCK TAG primary
      USE
   ENDIF
   IF ! File( "DBFINANC.DBF" )
      dbCreate( "DBFINANC", { ;
         { "IDFINANC", "N+", 6, 0 }, ;
         { "FIDATOPER", "D", 8, 0 }, ;
         { "FICLIENT", "N", 6, 0 }, ;
         { "FINUMDOC", "C", 10, 0 }, ;
         { "FIDATTOPAY", "D", 8, 0 }, ;
         { "FIDATPAY", "D", 10, 0 }, ;
         { "FIVALUE", "N", 14, 2 }, ;
         { "FIBANK", "N", 6, 0 } } )
      USE DBFINANC
      FOR nCont = 1 TO 9
         cTxt := Replicate( "FINANC" + Str( nCont, 1 ), 10 )
         APPEND BLANK
         REPLACE IDFINANC WITH nCont, FIDATOPER WITH Date() + nCont, ;
            FICLIENT WITH nCont, FINUMDOC WITH cTxt, ;
            FIDATTOPAY WITH DATE() + 30, FIBANK WITH nCont
      NEXT
      INDEX ON field->IDFINANC TAG primary
      USE
   ENDIF
   IF ! File( "DBSTATE.DBF" )
      dbCreate( "DBSTATE", { ;
         { "IDSTATE", "C", 2, 0 }, ;
         { "STNAME", "C", 30, 0 } } )
      USE DBSTATE
      FOR nCont = 1 TO 9
         cTxt := Replicate( "STATE" + Str( nCont, 1 ), 10 )
         APPEND BLANK
         REPLACE IDSTATE WITH StrZero( nCont, 2 ), STNAME WITH cTxt
      NEXT
      INDEX ON field->IDSTATE TAG primary
      USE
   ENDIF

   RETURN Nil
