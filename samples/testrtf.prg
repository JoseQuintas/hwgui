/*
 * $Id: testrtf.prg,v 1.2 2004/03/18 09:20:25 alkresin Exp $
 *
 * The sample implemented by Sandro Freire <sandrorrfreire@yahoo.com.br>
 */

#include "common.ch"
#include "richtext.ch"
#include "windows.ch"
#include "guilib.ch"

STATIC oPrinter,aSize:={280,220}

function Main
Private oMainWindow, oPanel
Private oFont := Nil, cDir := "\"+Curdir()+"\"
Private nColor, oBmp2


   INIT WINDOW oMainWindow MDI TITLE "Example" ;
         MENUPOS 3
  
   MENU OF oMainWindow
      MENU TITLE "&File"
         MENUITEM "&Test RTF" ACTION TestRTF()
         SEPARATOR
         MENUITEM "&Exit" ACTION hwg_EndWindow()
      ENDMENU
      MENU TITLE "&Help"
         MENUITEM "&About" ACTION hwg_Shellabout("Info","RTF Demo")
      ENDMENU
   ENDMENU

   oMainWindow:Activate()

return nil

FUNCTION TestRtf()
LOCAL cOutFile, oRtf, anchos, i
LOCAL j, aMarca, lFormato := .F.

   cOutFile := hwg_Savefile( "*.rtf","RTF files( *.rtf )","*.rtf" )
   IF Empty( cOutFile )
      Return Nil
   ENDIF
   IF File( cOutFile ) .AND. !hwg_Msgyesno( "Recreate it ?",cOutFile+" already exists!" )
      Return Nil
   ENDIF

   //      Open the output file & set some defaults


   cOutFile:=alltrim(cOutFile)

   oRtf := SetupRTF( cOutFile)

   // Metodos nuevos que se han introducido

   BEGIN BOOKMARK oRTF ;
	TEXT "Marcadores"
   END BOOKMARK oRTF

   // Cajas de Texto

   BEGIN TEXTBOX oRtf;
	SIZE {9.0,0.30};     // Tamaño Caja de texto
	TEXT "Cajas de Texto";
	FONTNUMBER 2;
	FONTSIZE 12 ;
	APPEARANCE BOLD_ON+CAPS_ON;
        INDENT 0

   END TEXTBOX oRtf

   NEW PARAGRAPH oRTF TEXT ""
   NEW PARAGRAPH oRTF TEXT "";
        ALIGN RIGHT

   SETDATE oRtf FORMAT LONGFORMAT

   // Parrafos con estilo

   NEW PARAGRAPH oRTF TEXT "Estilo Prueba";
        STYLE 2

   NEW PARAGRAPH oRTF TEXT "CON LETRAS DE COLORES";
	APPEARANCE BOLD_OFF+ITALIC_OFF+CAPS_OFF;
        FONTNUMBER 2;
        FONTCOLOR 3;
        STYLE 1;
        ALIGN CENTER

   // Lineas

   LINEA oRtf;
        INICIO {0.1,1.0};         //Inicio
        FIN {10.0,1.0};          // Final
        TIPO "SOLIDA"      // Tipo de linea

   NEW PARAGRAPH oRTF TEXT ""
   NEW PARAGRAPH oRTF TEXT ""

   // Notas a hwg_Pie de pagina

   NEW PARAGRAPH oRTF TEXT "Notas hwg_Pie de pagina";
        FONTCOLOR 1;
        ALIGN LEFT

   FOOTNOTE oRtf ;
        TEXT "Prueba de hwg_Pie de pagina";
        CHARACTER "*";//        AUTO;
        UPPER

   cTexto:=".La unica forma que he encontrado para introducir imagenes. Sin utilizar"
   ctexto+=" C, es enlazandolas sin introducirlas en el documento realmente. Es por eso"
   ctexto+=" que esta posibilidad no se muestra aqui."

   WRITE TEXT  oRtf TEXT ctexto

   NEW PARAGRAPH oRTF TEXT ""
   NEW PARAGRAPH oRTF TEXT ""

   oRtf:NewPage()

   // Nueva definicion de tablas. Habia algunas propiedades de las celdas
   // que hacia que el MSWORD se quedara colgado.

   anchos:={1.0,1.0,1.0,1.2,1.0,1.0,1.0,1.5,1.7}
   aMarca=ARRAY(9)
   AFILL(aMarca,0)
   aMarca[7]:=25
   aMarca[9]:=25
		DEFINE NEWTABLE oRTF ;              // Specify the RTF object
			ALIGN CENTER ;                // Center table horizontally on page
			FONTNUMBER 2 ;                // Use font #2 for the body rows
			FONTSIZE 10 ;                  // Use 9 Pt. font for the body rows
			CELLAPPEAR BOLD_OFF ;         // Normal cells unbolded
			CELLHALIGN LEFT ;             // Text in normal cells aligned left
			COLUMNS 9 ;      	    // Table has n Columns
			CELLWIDTHS anchos ;        // Array of column widths
			ROWHEIGHT .2 ;               // Minimum row height is .25"
			CELLBORDERS SINGLE ;          // Outline cells with thin border
			COLSHADE aMarca;               // Sombras en columnas
			HEADERROWS 2;                // dos lineas de titulos
                        HEADER {"Sala","Generador","","","","","ACTIVIDAD",;
                        "NºEXPOSICIONES AÑO POR TUBO","CARGA DE TRABAJO mA. min/semana"},;
			{"","Marca","Modelo","Tension Pico (kVp)","Intensidad (mA)",;
			"Nº Tubos","","",""};       // Titulos. Cada linea es una matriz
			HEADERSHADE 0;
			HEADERFONTSIZE 10;
            HEADERHALIGN CENTER 
                                                      // 2,3 y 5,6 de la primera linea de titulos
                                                      // van a estar unidas en una sola.

                        FOR i=1 TO 40
                                       IF i==6
   // Se puede cambiar el formato de una celda individual en tiempo de ejecucion.
			                        aMarca[5]:=1500
			                        aMarca[7]:=2500
			                        aMarca[9]:=2500
						DEFINE CELL FORMAT oRTF ;
							CELLSHADE aMarca
			                        lFormato:=.T.
			                ELSEIF lFormato
						DEFINE CELL FORMAT oRTF
			                        lFormato:=.F.
			                ENDIF

                                FOR j=1 TO 9
                                        if i==6 .AND. j==5
						WRITE NEWCELL oRTF TEXT "sombra"
                                        else
						WRITE NEWCELL oRTF TEXT ""
                                        endif
                                NEXT j
                        NEXT i

		END TABLE oRTF

   CLOSE RTF oRtf

   hwg_Msginfo( cOutFile + " is created !" )

RETURN NIL



STATIC FUNCTION SetupRTF(cOutFile)
*********************************************************************
* Description:
* Arguments:
* Return:
*
*--------------------------------------------------------------------
* Date       Developer   Comments
* 01/28/97   TRM         Creation
*
*********************************************************************
LOCAL oRTF,i,nWidth:=0,lLandScape:=.F.
LOCAL  ancpag
MEMVAR nom_hosp1,nom_hosp2,nom_ser
MEMVAR cNomUser

DEFINE RTF oRTF FILE cOutFile ;
	FONTS "Times New Roman", "Arial", "Courier New" ;
	FONTFAMILY "froman","fswiss","fmodern";
        CHARSET 0,0,10;
	FONTSIZE 12 ;
	TWIPFACTOR 1440

// Estilos. Despues de la definicion del oRtf

BEGIN ESTILOS oRTF

DEFINE ESTILO oRtf;
        NAME "Prueba";          //Nombre del estilo
        TYPE PARAGRAPH;         // Tipo del estilo
        FONTNUMBER 3;           // Fuente
        FONTCOLOR 6;            // Color
        APPEARANCE BOLD_ON+ITALIC_ON;
        ALIGN CENTER;           // Alineacion
        SHADE 25;               // Sombreado
        LUPDATE

END ESTILOS oRTF

// Informacion del documento.

INFO oRTF TITLE "Prueba"; 			//Titulo
	SUBJECT "Informe en RTF";               //Materia
	AUTHOR "Jose Ignacio Jimenez Alarcon";  // Autor
	MANAGER "Jose Ignacio Jimenez Alarcon" ;  //Director
	COMPANY "Servicio Canario de Salud" ;     // Compañia
	OPERATOR "Jose Ignacio Jimenez Alarcon"   // Operador

// Formato del documento. Se puede cambiar luego con el setup. Tiene
// que ir siempre detras del bloque de informacion si existe
DOCUMENT FORMAT oRtf;
        TAB 0.5;        	// Tabuladores
        LINE 1;         	// Linea Inicial
        BACKUP;         	// Backup al grabar
        DEFLANG 1034;           // Lenguaje del documento
        FOOTTYPE BOTH;          // Notas hwg_Pie de Pagina y Final Documento
        FOOTNOTES SECTION;      // Al final de la seccion
        ENDNOTES SECTION;
        FOOTNUMBER SIMBOL;      // Numeracion por simbolos
        PAGESTART 1;            // Pagina Inicial
        PROTECT NONE;           // Tipo de proteccion
        FACING;                 // Diferencia entre paginas pares o impares
        GUTTER 1.0              // Encuadernado 0.5

// Trim trailing spaces from data, to save file space.
oRTF:lTrimSpaces := .T.

DEFINE PAGESETUP oRTF MARGINS 0.5, 0.5, 0.5, 0.5 ;
	PAGEWIDTH (aSize[2]/25.4) ;
	PAGEHEIGHT (aSize[1]/25.4);
	TABWIDTH .5 ;
	ALIGN TOP;
        LANDSCAPE

BEGIN HEADER oRTF

	DEFINE NEWTABLE oRTF ;              // Specify the RTF object
		ALIGN LEFT ;                // Center table horizontally on page
		FONTNUMBER 2 ;                // Use font #2 for the body rows
		FONTSIZE 9 ;                  // Use 9 Pt. font for the body rows
		CELLAPPEAR BOLD_OFF ;         // Normal cells unbolded
		COLUMNS 3;      		// Table has n Columns
		CELLWIDTHS {0.98,5.71,0.71};        // Array of column widths
		ROWHEIGHT .2  ;              // Minimum row height is .25"
		CELLBORDERS NONE           // Outline cells with thin border


	WRITE NEWCELL oRTF TEXT "";
                FONTNUMBER 2;
		FONTSIZE 8 ;
		ALIGN LEFT

	WRITE NEWCELL oRTF TEXT "Clase RichText";
                FONTNUMBER 2;
		FONTSIZE 14 ;
                FONTCOLOR 2;                            // Colores
		APPEARANCE BOLD_ON+CAPS_ON+ITALIC_ON ;
		ALIGN CENTER

        WRITE NEWCELL oRtf TEXT ""

	WRITE NEWCELL oRTF TEXT ""
	WRITE NEWCELL oRTF TEXT ""
        WRITE NEWCELL oRtf TEXT ""

	WRITE NEWCELL oRTF TEXT ""
	WRITE NEWCELL oRTF TEXT ""
        WRITE NEWCELL oRtf TEXT ""

END TABLE oRTF

END HEADER oRTF

BEGIN FOOTER oRTF
	NEW PARAGRAPH oRTF TEXT "Pagina " ;
                FONTNUMBER 2;
		FONTSIZE 8 ;
	        BORDER "TOP";
		ALIGN LEFT
        
// Nuevo. Escribe en ese lugar el numero de pagina actual.

	SETPAGE oRtf

END FOOTER oRTF

RETURN oRTF
**********************  END OF SetupRTF()  ***********************


