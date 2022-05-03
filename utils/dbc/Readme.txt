DbcH
----

 $Id$

Text from http://kresin.ru/en/dbc.html.
(2022-04-27)


DbcH - Data Base Control (Harbour) is an utility that allows complete multi-user access to xBASE databases and indexes.

Here you can download the following binaries and sources:

Console version:

    Dbch 3.10 ( Windows ) supports DBFCDX (default) and DBFNTX drivers;
    Dbch 3.10_Debian ( Linux Debian 7 ) supports DBFCDX (default) and DBFNTX drivers;
    Dbchl 3.10 ( Windows ) a version for LetoDB;
    Dbchx 3.9 ( Windows ) supports Ads RDD. To use it you need to have ADS client dll's version 5.7 .
     You can download it from here.
    DbcH 3.10 - sources. Bat files to build DbcH with Borland C compiler and dbc.hbp for hbmk2 are included; 

GUI version:

    Dbchw 3.2 ( Windows ) for local files (DBFCDX,DBFNTX).
    The sources are included in HwGUI distribution( hwgui/utils/dbc ).
    Dbchwl 3.2 ( Windows ) for LetoDB.
    Dbchw 3.2-Debian ( Linux Debian 7 ) for local files (DBFCDX,DBFNTX). 

Pay attention to the file dbc.ini. It has the same set of options for console and GUI versions. DbcH first reads the ini-file, located near the executable file, and then the one that is in the directory from which you launched DbcH, so you can override Dbc options for different directories.

Dbc.ini options.

Section [MAIN]:

Shared = On
    Swith the Shared mode. 
Readonly = Off
    Swith (switch off in this case) the Readonly mode. 
DateFormat = dd.mm.yyyy
    Set the date format to show in a browse. 
lEngl=Off
    Swith the interface language. If lEngl == Off, the language is Russian ( for console version only). 
Index = ntx
    Set the default database driver. In this case - dbfntx, in all other - dbfcdx.
BrwFont = MS Sans Serif,0,-17
    Browse font( for GUI version only ). 
AppCodePage = RU1251
    Application codepage ( for GUI version only ). 
DataCodePage = RU866
    The codepage of dbf files ( for GUI version only ). 

Section [LETO]:

ServerPath = //192.168.0.5:2812/
    The path to the LetoDB server. 

Section [ADS]:

ServerPath = //192.168.0.5:6262/
    The path to the ADS server. 

With DbcH you can:

-    open dbf files for browse and editing in shared and exclusive modes, read/write and readonly modes
-    insert,delete,modify columns in browse
-    create (and modify structure) dbf files,indexes and tags
-    easy toggle workareas for multiple databases
-    edit/view in page(s)-per-record mode
-    edit/view in traditional row-per-record mode
-    execute commands:
      LOCATE, CONTINUE, SEEK, SET FILTER, GO TO,
      DELETE, RECALL, REPLACE, APPEND FROM, COPY TO, REINDEX, PACK, ZAP,
      COUNT, SUM, SET RELATION
-    print file (columns defined in current browse)
-    save and load views (view file have text format, so you can
      create and modify it from simple text editor)
-    create/save/load/execute SQL QUERIES
-    execute scripts
-    copy to/paste from Windows clipboard
-    convert memos between dbt and fpt format
-    pack memos 

====================== EOF of Readme.txt ===========================

