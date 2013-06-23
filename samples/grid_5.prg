/*
 * $Id: grid_5.prg,v 1.1 2004/04/05 14:16:35 rodrigo_moreno Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HGrid class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 * Copyright 2004 Rodrigo Moreno <rodrigo_moreno@yahoo.com>
 *
 * This sample show how to edit records with grid control
*/

#include "windows.ch"
#include "guilib.ch"

#define GET_FIELD   1
#define GET_LABEL   2
#define GET_PICT    3
#define GET_EDIT    4
#define GET_VALID   5
#define GET_LIST    6
#define GET_LEN     7
#define GET_TYPE    8
#define GET_VALUE   9
#define GET_HEIGHT 10
#define GET_OBJECT 11

Static oMain, oForm, oBrowse

#xcommand ADD COLUMN TO GRIDEDIT <aGrid> ;
            FIELD <cField>               ;            
            [ LABEL <cLabel> ]           ;
            [ PICTURE <cPicture> ]       ;
            [ <lReadonly:READONLY> ]     ;
            [ VALID <bValid> ]           ;
            [ LIST <aList> ]             ;
          => ;
          aadd(<aGrid>, {<cField>, <cLabel>, <cPicture>, <.lReadonly.>, <{bValid}>, <aList>})

Function Main()
        INIT WINDOW oMain MAIN TITLE "Grid Edition Sample" ;
             AT 0,0 ;
             SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight() - 28

                MENU OF oMain
                        MENUITEM "&Exit"   ACTION oMain:Close()
                        MENUITEM "&Demo"   ACTION Test()
                ENDMENU

        ACTIVATE WINDOW oMain
Return Nil

Function Test()
    Local aItems := {}
    Local i
    
    PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT -11
        
    Ferase('temp.dbf')

    DBCreate("temp.dbf", {{"field_1", "N", 10, 0},;
	                  {"field_2", "C", 30, 0},;
	                  {"field_3", "L",  1, 0},;
	                  {"field_4", "D",  8, 0},;
	                  {"field_5", "M", 10, 0}})

    use temp new
    
    For i := 1 to 100
        append blank
        REPLACE field_1 WITH i
        REPLACE field_2 WITH 'Test ' + str(i)
        REPLACE field_3 WITH mod( i, 10) == 0
        REPLACE field_4 WITH Date() + i
        REPLACE field_5 WITH 'Memo Test'
    Next        
        
    commit

    ADD COLUMN TO GRIDEDIT aItems FIELD "Field_1" LABEL "Number" LIST {'List 1', 'List 2'}
    ADD COLUMN TO GRIDEDIT aItems FIELD "Field_2" LABEL "Char" PICTURE "@!" //READONLY
    ADD COLUMN TO GRIDEDIT aItems FIELD "Field_3" LABEL "Bool" 
    ADD COLUMN TO GRIDEDIT aItems FIELD "Field_4" LABEL "Date" 
    ADD COLUMN TO GRIDEDIT aItems FIELD "Field_5" LABEL "Memo" 
   
    INIT DIALOG oForm CLIPPER NOEXIT TITLE "Grid Edit";
        FONT oFont ;
        AT 0, 0 SIZE 700, 425 ;
        STYLE DS_CENTER + WS_VISIBLE + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU 

        @ 10,10 GRID oGrid OF oForm SIZE 680,375;
                ITEMCOUNT LastRec() ;
                ON KEYDOWN {|oCtrl, key| OnKey(oCtrl, key, aItems) } ;
                ON CLICK {|oCtrl| OnClick(oCtrl, aItems) } ;
                ON DISPINFO {|oCtrl, nRow, nCol| OnDispInfo( oCtrl, nRow, nCol ) } 

        ADD COLUMN TO GRID oGrid HEADER "Number" WIDTH 100
        ADD COLUMN TO GRID oGrid HEADER "Descr"  WIDTH 250
        ADD COLUMN TO GRID oGrid HEADER "Bool"   WIDTH 70
        ADD COLUMN TO GRID oGrid HEADER "Date"   WIDTH 100
        ADD COLUMN TO GRID oGrid HEADER "Memo"   WIDTH 200        
                                 
        @  10, 395 BUTTON 'Insert' SIZE 75,25 ON CLICK {|| OnKey( oGrid, VK_INSERT, aItems ) }                            
        @  90, 395 BUTTON 'Change' SIZE 75,25 ON CLICK {|| OnClick( oGrid, aItems ) }                            
        @ 170, 395 BUTTON 'Delete' SIZE 75,25 ON CLICK {|| OnKey( oGrid, VK_DELETE, aItems ) }                            

        @ 620, 395 BUTTON 'Close' SIZE 75,25 ON CLICK {|| oForm:close() }                            

    ACTIVATE DIALOG oForm                

Return Nil
    
Function GridEdit(cAlias, aFields, lAppend, bChange)
    Local i
    Local cField
    Local nSay := 0
    Local nGet := 0
    Local cType
    Local nLen
    Local nRowSize := 30
    Local nGetSize := 10
    Local oForm
    Local nRow := 10
    Local nCol 
    Local nHeight := 0
    Local cValid
    Local nStyle := 0
    Local nArea := Select()
    
    DBSelectArea(cAlias)
    
    if lAppend
        DBAppend()
    else
        rlock()        
    endif
    
    /* set the highest say and get */
    for i := 1 to len(aFields)
        ASize(aFields[i], 12)
        
        nSay := max( nSay, len(aFields[i, GET_LABEL]) )
        
        cType := Fieldtype(Fieldpos(aFields[i, GET_FIELD]))
        
        if Empty(aFields[i, GET_PICT])
        
            if cType == "M"
                nLen := 50
            elseif cType == "D"
                nLen := 15
            elseif cType == "L"
                nLen := 5
            else
                nLen := Fieldlen(Fieldpos(aFields[i, GET_FIELD]))
            endif                    
        
        else
            nLen := len(transform(Fieldget(FieldPos(aFields[i, GET_FIELD])), aFields[i, GET_PICT]))
        
        endif        

        nGet := max( nGet, nLen )

        aFields[i, GET_LEN] := nLen
        aFields[i, GET_TYPE] := cType
        aFields[i, GET_HEIGHT] := iif( cType == "M", 150, 25 )
        aFields[i, GET_VALUE] := Fieldget(FieldPos(aFields[i, GET_FIELD]))

        nHeight += aFields[i, GET_HEIGHT]
    next
    
    nHeight += 5 * len(aFields) + 15 + 30
    nRow := 10
    nCol := nSay * nGetSize
    
    INIT DIALOG oForm CLIPPER TITLE "Teste";
        FONT oFont ;
        AT 0, 0 ;
        SIZE Min( hwg_Getdesktopwidth() - 50, (nSay + nGet) * nGetSize + nGetSize ), ;
             Min( hwg_Getdesktopheight() - 28, nheight ) ;
        STYLE DS_CENTER + WS_VISIBLE + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU 

        For i := 1 to len(aFields)
            @   10, nRow SAY aFields[i, GET_LABEL] SIZE len(aFields[i, GET_LABEL]) * nGetSize, 25
            
            cType  := Fieldtype(Fieldpos(aFields[i, GET_FIELD]))
            
            if cType == "N" .and. aFields[i, GET_LIST] != NIL
                aFields[i, GET_OBJECT] := HComboBox():New( oForm,;
                            3000 + i,;
                            aFields[i, GET_VALUE],;
                            FieldBlock(aFields[i, GET_FIELD]),;
                            IIF( ! aFields[i, GET_EDIT], NIL, WS_DISABLED ),;
                            nCol,;
                            nRow,;
                            aFields[i, GET_LEN] * nGetSize,;
                            min(150, len(aFields[i, GET_LIST]) * 25 + 25),;
                            aFields[i, GET_LIST],;
                            NIL,;
                            NIL,;
                            NIL,;
                            NIL,;
                            {|value, oCtrl| __valid(value, oCtrl, aFields, bChange) },;
                            NIL)
            
            elseif cType == 'L'
                aFields[i, GET_OBJECT] := HCheckButton():New( oForm,;
                            3000 + i,;
                            aFields[i, GET_VALUE],;
                            FieldBlock(aFields[i, GET_FIELD]),;
                            IIF( ! aFields[i, GET_EDIT], NIL, WS_DISABLED ),;
                            nCol,;
                            nRow,;
                            aFields[i, GET_LEN] * nGetSize,;
                            aFields[i, GET_HEIGHT],;
                            '',;
                            NIL, ;
                            NIL,;
                            NIL,;
                            NIL,;
                            {|value, oCtrl| __valid(value, oCtrl, aFields, bChange) },;
                            NIL,;
                            NIL,;
                            NIL)

            elseif cType = 'D' 
                aFields[i, GET_OBJECT] := HDatePicker():New( oForm,;
                            3000 + i,;
                            aFields[i, GET_VALUE],;
                            FieldBlock(aFields[i, GET_FIELD ]),;
                            IIF( ! aFields[i, GET_EDIT], NIL, WS_DISABLED ),;
                            nCol,;
                            nRow,;
                            aFields[i, GET_LEN] * nGetSize,;
                            aFields[i, GET_HEIGHT],;
                            NIL,;
                            NIL,;
                            NIL,;
                            {|value, oCtrl| __valid(value, oCtrl, aFields, bChange) },;
                            NIL,;
                            NIL,;
                            NIL )
            else
                if cType == "M"
                    nStyle := WS_VSCROLL + WS_HSCROLL + ES_AUTOHSCROLL + ES_MULTILINE 
                endif
                
                if aFields[i, GET_EDIT]
                    nStyle += WS_DISABLED
                endif
                                    
                aFields[i, GET_OBJECT] := HEdit():New( oForm, ;
                            3000 + i,;
                            aFields[i, GET_VALUE],;
                            FieldBlock(aFields[i, GET_FIELD]),;
                            nStyle,;
                            nCol,;
                            nRow,;
                            aFields[i, GET_LEN] * nGetSize,;
                            aFields[i, GET_HEIGHT],;
                            NIL,;
                            NIL,NIL,NIL,;
                            NIL,;
                            {|value, oCtrl| __valid(value, oCtrl, aFields, bChange) },;
                            NIL,;
                            NIL,;
                            NIL,;
                            aFields[i, GET_PICT],;
                            .F.)            
            endif                                                
                                                
            nRow += aFields[i, GET_HEIGHT] + 5

        Next
    
        @ oForm:nWidth - 160, oForm:nHeight - 30 BUTTON "Ok"     ID IDOK SIZE 75,25 
        @ oForm:nWidth -  80, oForm:nHeight - 30 BUTTON "Cancel" ID IDCANCEL SIZE 75,25 ON CLICK {|| oForm:Close() }
        
        oForm:bActivate := {|| hwg_Setfocus(aFields[1, GET_OBJECT]:handle)}
        
    ACTIVATE DIALOG oForm                
    
    if oForm:lResult
        DBCommit()    
    elseif lAppend
        Delete
    else
        /* When canceled, reverte record to old information */        
        For i := 1 TO len(aFields)
            Fieldput(Fieldpos(aFields[i, GET_FIELD]), aFields[i, GET_VALUE])        
        Next
    endif
    
    Unlock
    DBSelectArea(nArea)
    
Return oForm:lResult

static Function __valid(value, oCtrl, aFields, bChange)
    Local result := .T.
    Local i, n, oGet
    Local val

    if ISOBJECT(oCtrl)
        n := oCtrl:id - 3000    
        
        Eval(bChange, oCtrl, n)
        
        if aFields[n, GET_VALID] != nil
            if ! Eval(aFields[n, GET_VALID])
                result := .F.            
                oGet := aFields[n, GET_OBJECT]
            
                oGet:Setfocus()
            endif
        endif    
    
        for i := 1 to len(aFields)
            val := Fieldget(fieldpos(aFields[i, GET_FIELD])) 
            
            if valtype(val) == "D" .and. empty(val)
                Fieldput(Fieldpos(aFields[i, GET_FIELD]), Date())
            endif                        

            oGet := aFields[i, GET_OBJECT]
        
            if oGet:id != oCtrl:id .or. valtype(val) == "D"
                oGet:refresh()
            endif            
        next        
    endif            
Return result

Static Function OnDispInfo( oCtrl, nRow, nCol )
    Local result := ''
    DBGoto(nRow)
    
    if nCol == 1
        result := str(field->field_1)
    elseif nCol == 2
        result := field->field_2
    elseif nCol == 3
        result := iif( field->field_3, 'Y', 'N' )
    elseif nCol == 4
        result := DtoC( field->field_4 )
    elseif nCol == 5
        result := MemoLine( field->field_5, 100, 1)
    endif                                          
Return result

Static Function OnKey( o, k, aItems )
    if k == VK_INSERT
        if GridEdit('temp', aItems, .T., {|oCtrl, colpos| myblock(oCtrl, colpos)})
            o:SetItemCount(lastrec())
        else
            MyDelete()
        endif
    elseif k == VK_DELETE .and. hwg_Msgyesno("Delete this record ?", "Warning")                   
        MyDelete()
    endif        
return nil    

Static function OnClick( o, aItems )
    GridEdit('temp', aItems, .F., {|oCtrl, colpos| myblock(oCtrl, colpos)})
return nil    

Static function myblock( oCtrl, colpos )
    if colpos == 3
        replace field_5 with 'hello'
    endif            
return nil    
    
Static Function mydelete()
    DELETE
    PACK
    oGrid:SetItemCount(Lastrec())
return nil
