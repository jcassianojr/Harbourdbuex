// +--------------------------------------------------------------------
// +
// +   harbour sqlrddpp https://github.com/marcosgambeta/sqlrddpp.git
// +
// +
// +--------------------------------------------------------------------
// +


// +--------------------------------------------------------------------
// +
// +    Programa  : dbumix.prg
// +
// +     Sistema:
// +
// +     Linguagem: Harbour
// +
// +     Autor: jcassiano
// +
// +     Copyright (c) 2024,  jcassiano
// +
// +
// +    Documentado em 28-Dez-2024 as 10:07 am
// +
// +--------------------------------------------------------------------
// +

//   SR_UseDeleteds(.F.)      // Don't keep deleted records in database  
/*
 ACCESS   ADABAS      AZURE    CACHE     CUBRID   FIREBR   FIREBR3   FIREBR4   FIREBR5   
 IBMDB2   INFORM      INGRES   MARIADB   MSSQL6   MSSQL7   MYSQL     ORACLE   
 OTERRO   PERVASIVE   POSTGR   SQLANY    SQLBAS   SYBASE 
"SQLITE","MARIADB","MYSQL","MDB ACCESS","ACCDB ACCESS","MSSQL","ORACLE","LETODB","FIREBIRD","PARADOX","DUCKDB"
  N        S         S            S           N            S       S         N          S         N        N
*/

#include "dbinfo.ch"
#include "error.ch"
#include "simpleio.ch"
#include "BOX.CH"
#include "dbstruct.ch"
#include "sqlrdd.ch"
#include "directry.ch"
#include "TRY.CH"


REQUEST SQLRDD
REQUEST SQLEX
REQUEST SR_ODBC

#ifdef USE_SR_MYSQL
  REQUEST SR_MARIADB
  REQUEST SR_MYSQL
#endif  
  
#ifdef USE_SR_FIREBIRD  
  REQUEST SR_FIREBIRD5
#endif

#ifdef USE_SR_POSTGRES
  REQUEST SR_PGS
#endif

#ifdef USE_SR_ORACLE
  REQUEST SR_ORACLE
#endif
  
REQUEST ARRAYRDD


#define SQL_DBMS_NAME                       17
#define SQL_DBMS_VER                        18


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function sqlrddmenu()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION sqlrddmenu( cUSOSQL )

   LOCAL aAMBIENTE
   
   
    IF cTIPOSQL="SQLITE" .OR. cTIPOSQL="PARADOX" .OR. cTIPOSQL="LETODB" .OR. cTIPOSQL="DUCKDB"  .OR. cTIPOSQL="ACCDB"
      MDT("Nao suportado:"+cTIPOSQL)
      RETURN
   ENDIF


   cTIPOSQL := cUSOSQL   // Passa para privada usadas nas funcoes aBaixo
   cRDDSQL  := "SQLRDD"

   nConnection := 0
   aAMBIENTE   := SALVAA()
   cSERVERX    := Space( 30 )
   cDATABASEX  := Space( 30 )
   cUSERX      := Space( 30 )
   cPASSX      := Space( 30 )
   cTABELAX    := Space( 30 )
   cBANCOX     := Space(30)
   cOWNERX     := Space(30)
   cPORTAX     := SPACE(30)
   loledb      := .T.
   lMDB        := .F.
   lACCDB      := .F.
   lFDB        := .F.


   pegcfgbanco()
   cTIPOMIX :=  "ODBC"
   cTIPODBC :=  "CONN"
   

   IF cTIPOSQL="MARIADB".OR. cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "FIREBIRD" .OR. cTIPOSQL = "ORACLE"
      IF  mdg( "SQLRDD (SIM) SQLRDDODBC (NAO)" )
         cTIPOMIX := cTIPOSQL
      ENDIF
   ENDIF

   TIPODBF:=92
   IF cTIPOMIX="ODBC"
      cOLDRDD := rddSetDefault( "SQLEX" )
      nOLDTIPORDD := TIPODBF
      cRDDSQL  := "SQLEX"
      TIPODBF:=93
   ELSE
      cOLDRDD := rddSetDefault( "SQLRDD" )
      nOLDTIPORDD := TIPODBF
      cRDDSQL  := "SQLRDD"
   ENDIF   
   
   

   WHILE .T.
      hb_DispBox( 3, 18, 18, 55, B_DOUBLE + " " )
      @ 03, 24 SAY "SQLRDD:" + cTIPOMIX + " SQL: " + cTIPOSQL 
      OPCAO(  4, 24, "&Criar database            ", 67 )   // C
      OPCAO(  5, 24, "&Database Selecionar       ", 68 )   // D
      OPCAO(  6, 24, "&Importar  DBF             ", 73 )   // I
      OPCAO(  7, 24, "&Tabelas                   ", 84 )   // T
      OPCAO(  8, 24, "&Exportar  DBF             ", 69 )   // E
      OPCAO(  9, 24, "&Apagar Tabela             ", 65 )   // A
      OPCAO( 10, 24, "Exportar &Formatos         ", 70 )  // F 
      OPCAO( 11, 24, "Executar arquivo &SQL      ", 83 )   //S 83
      OPCAO( 12, 24, "&Versao Info SR            ", 86 )   // V 
      OPCAO( 13, 24, "&ODBC   Info DSN           ", 79 )   // O 
      KEY := menu( 1, 0 )
      DO CASE
      CASE KEY = 1
         sqlrdd_createdatabase()
      CASE KEY = 2
          pegcfgbanco() //escolhe novamente
      CASE KEY = 3
         sqlrdd_impdbf()
      CASE KEY = 4
          sqlrdd_Tabela()
      CASE KEY = 5
         sqlrdd_expdbf( )
      CASE KEY = 6
          sqlrdd_delete_Tabela()
      CASE KEY = 7
         sqlrdd_expformat()
      CASE KEY = 8
         sqlrdd_ExecArqSql()
     CASE KEY = 9
         sqlrdd_info()    
     CASE KEY = 10
         sqlrdd_ODBC_info()    
              
      OTHERWISE
         EXIT
      ENDCASE
   ENDDO


   rddSetDefault( cOLDRDD )
   TIPODBF :=nOLDTIPORDD
   RDDNOME(TIPODBF)
   
   RESTAA( aAMBIENTE )
   LAYOUT()

   RETURN .T.


// +--------------------------------------------------------------------
// +
// +    Function sqlrdd_expdbf()
// +
// +--------------------------------------------------------------------
// +
FUNCTION sqlrdd_expdbf()
sqlrdd_Tabela()
sqlrdd_open()
IF nConnection>0
   oSql:=SR_GetConnection()  //sempre exporta mais da erro com memos
   
   oSql:exec( "SELECT * FROM "+ctabelax, .F.,.T., , ctabelax)

   dbcloseall()
   sqlrdd_close()
   IF MDG("Exportar Outro Formato")
       multidocs(0,ctabelax+".dbf")
   ENDIF
ENDIF

/*
DO WHILE (oSql:Fetch(@aReturn) == SQL_SUCCESS)
      // Use aReturn with the line
      i++
   ENDDO
*/
 *+--------------------------------------------------------------------
*+
*+    Function sqlrdd_ExecArqSql()
*+
*+--------------------------------------------------------------------
*+
function sqlrdd_ExecArqSql()
LOCAL cCOMANDO := ""
LOCAL cARQIMP  := ""
cARQIMP := win_GetOPENFileName(,"Arquivos SQL",HB_CWD(),"Arquivos SQL","*.SQL",1)
IF FILE(cARQIMP)
   //nao pode ser linha a linha pois um comando pode estar em mais de uma linha
   cCOMANDO:=MEMOREAD(cARQIMP)
   sqlrdd_executesql( msql )
endif
return .t.
     
// +--------------------------------------------------------------------
// +
// +    Function sqlrdd_Tabela()
// +
// +--------------------------------------------------------------------
// +
function sqlrdd_Tabela()
local aTABELAS
aTABELAS:={}
sqlrdd_open()
IF nConnection>0
    aTABELAS:=SR_ListTables() 
    sqlrdd_close()
    IF EMPTY(aTABELAS)
       mdbtabela( cDATABASEX ) //Guarda public cTABELAX
    ELSE
       mdbtabela(aTABELAS)  //Guarda public cTABELAX
    ENDIF
ENDIF
mdt(cTABELAX)
return

// +--------------------------------------------------------------------
// +
// +    Function sqlrdd_info()
// +
// +--------------------------------------------------------------------
// +
function sqlrdd_info()
sqlrdd_open()
IF nConnection>0
    mdt("Connected to        :"+ SR_GetConnectionInfo(, SQL_DBMS_NAME)+" "+ SR_GetConnectionInfo(, SQL_DBMS_VER))
    sqlrdd_close()
ENDIF    
return

// +--------------------------------------------------------------------
// +
// +    Function sqlrdd_delete_Tabela()
// +
// +--------------------------------------------------------------------
// +
function sqlrdd_delete_Tabela()
sqlrdd_Tabela()
if ! empty(cTABELAX) .AND. MDG("Excluir tabela "+cTABELAX)
   sqlrdd_open()
   IF nConnection>0
       IF sr_ExistTable(cTABELAX)
          sr_DropTable(cTABELAX)
       ENDIF
       IF sr_ExistTable(cTABELAX)
          sqlrdd_executesql( "DROP TABLE  " + cTABELAX, .F., .F. ,.F.)
       ENDIF
       sqlrdd_close()
   ENDIF
endif
return

// +--------------------------------------------------------------------
// +
// +    Function sqlrdd_impdbf()
// +
// +--------------------------------------------------------------------
// +
FUNCTION sqlrdd_impdbf()

   mdt( "escolha origem" )
   tipodbfesc()
   nORITIPO   := TIPODBF
   cORIDRIVER := RDDNOME( TIPODBF )
   
   IF MDG("Arquivo Individual")
      cARQORI    := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*."+TABLEEXT, 1 )
   else
      cARQORI    := SelectFolder()
      cARQORI += "\"+ "*." +TABLEEXT
   endif   

   sqlrdd_open()
   IF nConnection>0
      sqlrdd_upload_dbf(cARQORI, "", cORIDRIVER, cRDDSQL)
      sqlrdd_close()
   ENDIF

   TIPODBF :=nOLDTIPORDD
   RDDNOME(TIPODBF)


   RETURN .T.


// +--------------------------------------------------------------------
// +
// +    Function sqlrdd_createdatabase()
// +
// +--------------------------------------------------------------------
// +
FUNCTION sqlrdd_createdatabase()
  DO CASE
       CASE cTIPOMIX = "MARIADB" 
       CASE cTIPOMIX = "MYSQL" .OR. cTIPOMIX = "MYSQL64"
       CASE cTIPOMIX = "PGSQL" .OR. cTIPOMIX = "PGSQL64"
       CASE cTIPOSQL = "FIREBIRD"
            cDATABASEX:=""
           cARQORI := win_GetsaveFileName(,"Firebase Files",HB_CWD(),"Firebase",;
                                         {{'Firebird fdb','*.fdb'},{'Firebird gdb','*.gdb'},{'Firebird ib','*.ib'},;
                                         {'All Files','*.*'}},1)  
           SR_FIREBIRD5():CreateDatabase(cARQORI, cUSERX, cPASSX, NIL, NIL, NIL)
           cDATABASEX:=cARQORI
       CASE cTIPOMIX = "ORACLE"
       CASE cTIPOSQL = "SQLITE"
           cDATABASEX:=""
           cARQORI := win_GetsaveFileName(,"SQLite Files",HB_CWD(),"SQLite",;
                                       {{'SQLite','*.sqlite'},{'SQLite db','*.DB'},;
                                     {'SQLite3','*.sqlite3'},{'SQLite db3','*.DB3'},;
                                     {'SQLite Fossil','*.fossil'},{'All Files','*.*'}},1)
            IF ! hb_FileExists(cARQORI) //Sqlite pasta existir o arquivo
               HB_MEMOWRIT(cARQORI,"")
            ENDIF   
            cDATABASEX:=cARQORI
       CASE cTIPOMIX = "ODBC" .AND. cTIPODBC =  "DSN" // Cserver 
       CASE cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" .OR. cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" ;
            .OR. cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER"
             cnewDATABASEX := INPUTBOX( Space( 30 ), "Novo database" )
             cnewDATABASEX := AllTrim( cnewDATABASEX )
             IF ! Empty( cnewDATABASEX )
                sqlrdd_executesql( "CREATE DATABASE IF NOT EXISTS " + Cnewdatabasex )
                CDATABASEX:=CNEWDATABASEX
             ENDIF    
                 
  ENDCASE
 


// +--------------------------------------------------------------------
// +
// +    Function sqlrdd_executesql
// +
// +--------------------------------------------------------------------
// +

FUNCTION sqlrdd_executesql( eCOMANDO, lTRANS, lMES ,lopen)

   LOCAL aCOMANDOS := {}
   LOCAL nFIM
   LOCAL i
   LOCAL lRet

   lRET := .T.
   IF ValType( LMES ) <> "L"
      lMES := .F.
   ENDIF
   IF ValType( Lopen ) <> "L"
      lopen := .t.
   ENDIF
   
   IF ValType( eCOMANDO ) = "C"
      AAdd( aCOMANDOS, eCOMANDO )
   ELSE
      aCOMANDOS := eCOMANDO
   ENDIF
   nFIM := Len( aCOMANDOS )
   
   if lopen
      sqlrdd_open()
   endif
   IF nConnection>0
      oSql   := SR_GetConnection()
       IF lTRANS
          oSql:execute( Dialeto_begin() )
       ENDIF
       FOR i := 1 TO nfim
          cCOMANDO := aCOMANDOS[ I ]
          oSql:execute( cCOMANDO )
       NEXT i
       IF lTRANS
          oSql:execute( Dialeto_commit() )
       ENDIF
       if lopen
          sqlrdd_close()
       endif
   ENDIF
   RETURN lRet



// +--------------------------------------------------------------------
// +
// +    Function sqlrdd_open()
// +
// +--------------------------------------------------------------------
// +
FUNCTION sqlrdd_open()
  LOCAL cCONN
  LOCAL oSQL
  LOCAL cConnectionString

   cCONN := ""
   nConnection:=0
   cConnectionString:= ""
  

IF cTIPOMIX = "ODBC"
   rddSetDefault( "SQLEX" )   
   DO CASE
      CASE cTIPODBC ==  "DSN"
           cConnectionString :=  "dsn="+cBANCOX
            // dsn=informix;uid=informix;pwd=1234;dtb=test 
            // dsn=db2;uid=db2admin;pwd=1234
            // dsn=ingres  
      
       CASE cTIPOMIX = "MARIADB" 
            s_ODBC_DRIVER   :="MariaDB ODBC 3.2 Driver"
            S_ODBC_OPTIONS  := "TCPIP=1"
           cConnectionString :=  "Driver="   + s_ODBC_DRIVER   + ";" + ;
                        "Server="   + cSERVERX   + ";" + ;
                        "Port="     + cPORTAX     + ";" + ;
                        "Database=" + cDATABASEX + ";" + ;
                        "Uid="      + cUSERX      + ";" + ;
                        "Pwd="      + cPASSX      + ";" + ;
                        ""          + s_ODBC_OPTIONS  + ";"
       CASE cTIPOMIX = "MYSQL" .OR. cTIPOMIX = "MYSQL64"
            if loledb
               s_ODBC_DRIVER   :="MySQL ODBC 8.0 ANSI Driver"
            else
               s_ODBC_DRIVER   :="MySQL ODBC 9.0 ANSI Driver"
            endif   
             cConnectionString :=  "Driver="   + s_ODBC_DRIVER   + ";" + ;
                          "Server="   + cSERVERX   + ";" + ;
                          "Port="     + cPORTAX     + ";" + ;
                          "Database=" + cDATABASEX + ";" + ;
                          "Uid="      + cUSERX      + ";" + ;
                          "Pwd="      + cPASSX      + ";" + ;
                          ""          + s_ODBC_OPTIONS  + ";"
       CASE cTIPOMIX = "PGSQL" .OR. cTIPOMIX = "PGSQL64"
             if lOLEDB
                s_ODBC_DRIVER   :="PostgreSQL ANSI"
             ELSE
                s_ODBC_DRIVER   :="PostgreSQL ANSI(x64)"
             ENDIF
             s_ODBC_OPTIONS  := "BoolsAsChar=0;TrueIsMinus1;" // DO NOT CHANGE
              cConnectionString := "Driver="   + s_ODBC_DRIVER   + ";" + ;
                      "Server="   + cSERVERX   + ";" + ;
                      "Port="     + cPORTAX     + ";" + ;
                      "Database=" + cDATABASEX + ";" + ;
                      "Uid="      + cUSERX     + ";" + ;
                      "Pwd="      + cPASSX     + ";" + ;
                      ""          + s_ODBC_OPTIONS  + ";"
       CASE cTIPOMIX = "FIREBIRD"
            s_ODBC_DRIVER   := DriverFirebird()
            s_ODBC_CLIENT   := "fbclient.dll"
            s_ODBC_CHARSET  := "ISO8859_1"
            cConnectionString :=       "driver="   + s_ODBC_DRIVER   + ";" + ;
                  "server="   + cSERVERX   + ";" + ;
                  "port="     + cPORTAX     + ";" + ;
                  "uid="      + cUSERX      + ";" + ;
                  "pwd="      + cPASSX      + ";" + ;
                  "database=" + cDATABASEX + ";" + ;
                  "client="   + s_ODBC_CLIENT   + ";" + ;
                  "charset="  + s_ODBC_CHARSET  + ";"
    CASE cTIPOMIX = "CUBRID"
          cConnectionString := "DRIVER="   + s_DRIVER   + ";" + ;
                          "SERVER="   + s_SERVER   + ";" + ;
                          "PORT="     + s_PORT     + ";" + ;
                          "DB_NAME="  + s_DATABASE + ";" + ;
                          "UID="      + s_UID      + ";" + ;
                          "PWD="      + s_PWD      + ";"
     CASE cTIPOMIX = "ORACLE"
    ENDCASE
    IF ! EMPTY(cConnectionString)
       sr_AddConnection(CONNECT_ODBC,cConnectionString)
    ENDIF   
ELSE  
   cOLDRDD := rddSetDefault( "SQLRDD" )
   DO CASE
       CASE cTIPOMIX = "MARIADB" 
            nConnection := sr_AddConnection(CONNECT_MARIADB, "MARIADB=" + cSERVERx + ";UID=" + cUSERX + ";PWD=" + cPASSX + ";DTB=" + cDATABASEX)
       CASE cTIPOMIX = "MYSQL" .OR. cTIPOMIX = "MYSQL64"
            nConnection := sr_AddConnection(CONNECT_MYSQL, "MySQL=" +  cSERVERX + ";PORT=" + cPORTAX + ";UID=" + cUSERX + ";PWD=" + cPASSX + ";DTB=" + cDATABASEX)
       CASE cTIPOMIX = "PGSQL" .OR. cTIPOMIX = "PGSQL64"
            nConnection := sr_AddConnection(CONNECT_POSTGRES, "PGS=" + cSERVERX + ";UID=" + cUSERX + ";PWD=" +  cPASSX + ";DTB=" + cDATABASEX)
          IF nConnection > 0
             oSql   := SR_GetConnection()
             // SE CONECTOU NO MIX, FORÇA O SCHEMA E ENCODING VIA INTERFACE RDD
             // O comando RD_EXECUTE envia a instrução direto para a linha ativa do banco
            oSql:execute( "SET search_path TO myschema, public; SET client_encoding TO 'WIN1252';")
          ENDIF
       CASE cTIPOMIX = "FIREBIRD"
          //cConnectionString:="FIREBIRD=" + alltrim(cSERVERX) + ";UID=" + alltrim(cUSERX) + ";PWD=" + alltrim(cPASSX) + ";DTB=" + alltrim(cDATABASEX)
          //nao passando o servidor funcionou
          cConnectionString:="FIREBIRD=;UID=" + alltrim(cUSERX) + ";PWD=" + alltrim(cPASSX) + ";DTB=" + alltrim(cDATABASEX)
          
          //memowrit("dbufireconn.sql",cConnectionString)
          nConnection := sr_AddConnection(CONNECT_FIREBIRD5,cConnectionString )
       CASE cTIPOMIX = "ORACLE"
          nConnection := sr_AddConnection(CONNECT_ORACLE, "OCI=" + cSERVERX + ";UID=" + cUSERX + ";PWD=" + cPASSX + ";DTB=" + cDATABASEX)
    ENDCASE
ENDIF
   IF !( nConnection > 0 )
      mdt( "Erro ao connectar " + cServerx + " "+ cDATABASEX )
      nConnection := 0
   ENDIF

   RETURN nConnection


// +--------------------------------------------------------------------
// +
// +    Function sqlrdd_close()
// +
// +--------------------------------------------------------------------
// +
// +
FUNCTION sqlrdd_close()
   IF ! Empty( nConnection ) .AND. nConnection <> 0
      sr_EndConnection(nConnection)
   ENDIF



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function sqlrdd_expformat()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION sqlrdd_expformat()
LOCAL aSTRU
LOCAL nCOMO
aSTRU:=""
sqlrdd_Tabela()
sqlrdd_open()
IF nConnection>0
ELSE
   RETURN
ENDIF   

nCOMO:=1


   LCOPIANAT := .F.  // MDG("Copia Nativa(SIM) Interna(NAO)") //copy to nao implemntado mysqlrddd
   tDOC      := pegtipodoc()   // .t. Inclui dbf se for nativa
   pegparexp()
   lDOCCAB   := .F.
   lDOCDAD   := .F.
   lDOCRECNO := .F.
   cSUBTIPO  := " "
   PegcsUB( tDOC )   // pegar o subtipo conforme tipo
   cDESTINO := cTABELAX + "." + zEXPOREXT
   MDT( cDESTINO )
   MDT( "abrindo arquivo de origem: " + cTABELAX )

   altd() //erro as vezes quando a tabela foi criado/importado fora do sqlrdd
   TRY
      dbUseArea(.T., cRDDSQL , cTABELAX, "ORIGEM", .F.) //ok e nao da erro de fieldget
   catch oErR
      TRY
        //FIELDGET(0) abre corretamente com select tabelas nao importas pelo sqlrdd porem da erro no fieldget
        nCOMO:=2  
       //   dbUseArea(.T., cRDDSQL ,"SELECT * FROM "+ctabelax , "ORIGEM", .F.)
      catch oErR
        RETURN
      END
   END   
   oSql:=SR_GetConnection()
   aSTRU:=oSql:aFields
   
   IF nCOMO=2 //teste com array add estudar append or while registro tratar caso 2 tabela nao registrada no sr erro fielget
     aDADOSUSO:={}
     oSql:exec( "SELECT * FROM "+ctabelax, .F.,.T.,@aDADOSUSO )
     // criar e manter aberto
     dbCreate( "arrtest.dbf", aStru, "ARRAYRDD", .T., "arrtest" )
     // criar e abrir
     //dbCreate( "arrtest.dbf", aStru, "ARRAYRDD" )
     // USE arrtest.dbf VIA "ARRAYRDD"
     
     hb_SetArrayRdd(aDADOSUSO)

   ENDIF

   nLASTREC := LastRec()
   zei_fort( nLASTREC,,, 0 )

   multidocg( lDOCCAB, lDOCDAD, lDOCRECNO, cSUBTIPO, TIRAEXT( cDESTINO ), aSTRU )

   dbCloseAll()

   sqlrdd_close()


   RETURN NIL



FUNCTION sqlrdd_upload_dbf(cBaseDir, cPrefix, cDriver, cRDD)

   LOCAL aFiles
   LOCAL aStruct
   LOCAL aFile
   LOCAL cFile
   LOCAL J
   LOCAL aINDICES
   LOCAL nINDEXES
   LOCAL cINDEXNAME
   LOCAL cKEY
   LOCAL cARQORI

   /* upload files */

   aFiles := directory(cBaseDir )  

   altd()
   FOR EACH aFile IN aFiles
      cFile := strtran(lower(alltrim(cPrefix + aFile[F_NAME])), ".dbf", "")
      cARQORI:=HB_FNAMEDIR(cBaseDir)+"\"+aFile[F_NAME]
      dbUseArea(.T., cDriver, cARQORI, "ORIG")
      //dbUseArea( [<lNewArea>], [<cDriver>], <cName>, [<xcAlias>],
      MDT("   Uploading... "+ cFile  + " (" + alltrim(str(ORIG->(lastrec()))), "records)")
      
      //sqlrdd faz o mapeamento dos tipos nao usar criasql aqui
      aStruct := ORIG->(dbStruct())
      
      //sqlrdd ja faz a padronizacao dos nomes dos indices passar a key,tag somente por isso nao usando geraindices aqui
      //implantar geraindices depois porem ao criar usar key,tag e nao create index sql
      aINDICES:={}
      nIndexes := dbORDERINFO(DBOI_ORDERCOUNT)
      FOR j := 1 TO nIndexes
         cINDEXNAME := dbORDERINFO(DBOI_NAME,,j)
         cINDEXNAME := AllTrim(cINDEXNAME)
         cKey := dbOrderInfo( DBOI_EXPRESSION, , j )
         cKEY       := ALLTRIM(cKEY)
         AADD(aINDICES,{cINDEXNAME,cKEY})
      NEXT j
      ORIG->(dbCloseArea())

      dbCreate(cFile, aStruct, cRDD)
      dbUseArea(.T., cRDD, cFile, "DEST", .F.)
      APPEND FROM (cARQORI) VIA cDriver


     //sqlrdd ja faz a padronizacao dos nomes dos indices passar a key,tag somente por isso nao usando geraindices aqui
      nIndexes:=LEN(aINDICES)
     IF nIndexes>0
       FOR j := 1 TO nIndexes
           cINDEXNAME := Aindices[J,1]
           cINDEXCHAVE:=Aindices[J,2]
           MDT( "Criando Indice: "+cINDEXNAME+" "+cINDEXCHAVE)
            INDEX ON &cINDEXCHAVE TAG &cINDEXNAME//TO &cARQINDEX
       NEXT j
     ENDIF    

      
      DEST->(dbCloseArea())
   NEXT


RETURN

function sqlrdd_ODBC_info()
LOCAL cTEXTO
LOCAL n
LOCAL a
LOCAL aODBC
LOCAL aTIPO
aODBC:={}
aTIPO:={}

cTEXTO:="Drives:"+HB_OSNEWLINE()
a := SR_ListODBCDrivers()
FOR n := 1 TO len(a)
    cTEXTO+="desc="+ a[n, 1] + " attr="+ a[n, 2]+HB_OSNEWLINE()
NEXT n

cTEXTO+="Data Sources Sistema:"+HB_OSNEWLINE()
   a := SR_ListODBCSystemDataSources()
   FOR n := 1 TO len(a)
      cTEXTO+= "DSN= "+ a[n, 1]+" Dialeto= "+DIALETO_DetectTargetDb(a[n, 2])+ " DRIVER="+ a[n, 2]+HB_OSNEWLINE()
      AADD(aODBC, a[n, 1])
      AADD(aTIPO, a[n, 2])
   NEXT n

cTEXTO+="Data Sources Usuario:"+HB_OSNEWLINE()
   a :=  SR_ListODBCUserDataSources()
   FOR n := 1 TO len(a)
      cTEXTO+= "DSN= "+ a[n, 1]+" Dialeto= "+DIALETO_DetectTargetDb(a[n, 2])+ " DRIVER="+ a[n, 2]+HB_OSNEWLINE()
      AADD(aODBC, a[n, 1])
      AADD(aTIPO, a[n, 2])
   NEXT n


 // list all data sources
//   a := SR_ListODBCDataSources()

   // list all data sources
//   a := SR_ListODBCDataSources(2) // SQL_FETCH_FIRST

   // list only user data sources
//   a := SR_ListODBCDataSources(31) // SQL_FETCH_FIRST_USER

   // list only system data sources
//   a := SR_ListODBCDataSources(32) // SQL_FETCH_FIRST_SYSTEM
IF mdg("Gravar info")
   hb_memowrit("odbc_info.txt",cTEXTO)
   mdt("arquivo odbc_info.txt gerado")
ENDIF   
IF ! mdg("Escolhar um DSN/ODBC para Usar")
   RETURN .F.
ENDIF
IF LEN(aODBC)>0
   nChoices := ACHOICE(4,19,17,54,aODBC)
   //3, 18, 18, 55
  // AChoice( <nTop>, <nLeft>, <nBottom>, <nRight>, <acMenuItems>, [<alSelableItems>  <lSelableItems>], [<cUserFunction> | <bUserBlock>], [<nInitialItem>]
   IF nChoices >0
       cBANCOX  :=aODBC[nChoices]
       cTIPOSQL :=DIALETO_DetectTargetDb(aTIPO[nChoices])
       cTIPOMIX :="ODBC"
       cTIPODBC :="DSN" 
       cRDDSQL  := "SQLEX"
       
       cSERVERX    := "" //Space( 30 )
       cDATABASEX  := ""  //Space( 30 )
       cUSERX      := ""   //Space( 30 )
       cPASSX      := ""  //Space( 30 )
       cTABELAX    := ""  //Space( 30 )
       cOWNERX     := ""   //Space(30)
       cPORTAX     := ""  //SPACE(30)
       
       
       MDT(cBANCOX+" "+cTIPOSQL)
       layout()
   ENDIF
ENDIF
RETURN .T.



// + EOF: sqlrdd.prg
// +
