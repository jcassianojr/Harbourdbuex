#include "dbstruct.ch"
#INCLUDE "BOX.CH"
#INCLUDE "TRY.CH"
#INCLUDE "DBINFO.CH"
#INCLUDE "hbVER.CH"
#require "rddadox"
#include "rddadox.ch"
REQUEST RDDADOX

Function mdbmenu(cUSOSQL)
cTIPOSQL := cUSOSQL   
public oDB := nil
aAMBIENTE := SALVAA()
cSERVERX   := "localhost"+space(21)
cDATABASEX := space(30)
cUSERX     := SPACE(30)
cPASSX     := SPACE(30)
cTABELAX   := SPACE(30)
cBANCOX    := Space(30)
cOWNERX    := Space(30)
cPORTAX    := SPACE(30)
loledb     := .T.
lmdb       := .f.
laccdb     := .f.
lFDB       := .f.
nPageSize  := 8192 
cCharSet   := "ISO8859_1" 
nDialect   := 3 
CTIPOMIX   := "ODBC"
cTIPODBC   := "ODBC"

pegcfgbanco()

WHILE .T.
   HB_dispbox(3,18,18,55,B_DOUBLE+" ")
   DO CASE
   CASE cTIPOSQL = "MDB" .OR. cTIPOSQL = "ACCESS"
      IF loledb
         @ 03,40 SAY "oledb(32b)"         
      Else
         @ 03,40 SAY "accdb(64b)"         
      endif
   CASE cTIPOSQL = "MYSQL"
      IF loledb
         @ 03,40 SAY "odbc 8(32b)"         
      Else
         @ 03,40 SAY "odbc 9(64b)"         
      endif
   OTHERWISE
      @ 03,24 SAY "RDDADOX"+" "+cTIPOSQL         
   ENDCASE
   if cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" .OR. cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" ;
              .OR. cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER"
      OPCAO(4,24,"&Criar database             ",67)   
   else
      OPCAO(4,24,"&Criar arquivo              ",67)   
   endif
   OPCAO(  5, 24, "Executar arquivo &SQL     ", 83)    
   OPCAO(  6, 24, "&Importar  DBF            ", 73)    
   OPCAO(  7, 24, "Exportar Tabela &Formatos ", 69)    
   OPCAO(  8, 24, "&Database Selecionar      ", 68)    
   OPCAO(  9, 24, "&Exportar  DBF            ", 69)    
   OPCAO( 10, 24, "DBF para &Script          ", 83)    
   OPCAO( 11, 24, "DBF para D&BML            ", 84)    
   OPCAO( 12, 24, "&ODBC   Info DSN          ", 79 )   
   OPCAO( 13, 24, "Gerar md e dbml           ", 79 )   
   
   KEY := menu(1,0)
   DO CASE
   CASE KEY = 1; mdbcria()
   CASE KEY = 2; ExecArqSql()
   CASE KEY = 3; MDBIMPDBF()
   CASE KEY = 4; MDBEXP(2)
   CASE KEY = 5; IF(lMDB .OR. lACCDB,, mdbdatabases())
   CASE KEY = 6; MDBEXP(1)
   CASE KEY = 7 
        IF MDG("Individual") 
          tDOC = 5 
          ZANOFOR := cTIPOSQL
          zEXPOREXT = "SQL"
          lDOCCAB:=MDG( "Gravar Informacao Estrutura" )
          lDOCDAD:=MDG( "Gravar Dados" )
          lDOCRECNO:=.F. 
          cSUBTIPO:="SQL"
          cMASK:="*."+TABLEEXT
          FAZERDBF( {|| multidocg( lDOCCAB, lDOCDAD, lDOCRECNO, cSUBTIPO ) }, .F.,,, cMASK )
        else
          sqltodos(cTIPOSQL)
        endif  
   CASE KEY=8; mdltodos() 
   CASE KEY = 9; sqlrdd_ODBC_info()   
   CASE KEY = 10; MDBGERAINFO()  
   OTHERWISE; EXIT
   ENDCASE
ENDDO

RESTAA(aAMBIENTE)
layout()
loledb := .f.
lmdb   := .f.
laccdb := .f.
lFDB   := .f.
return nil

FUNCTION opencmdbarq()
   LOCAL lRETU := .T.
   DO CASE
   CASE lMDB
      hb_adoSetTable(cTABELA) 
      hb_adoSetEngine( iif(loledb, "ACCESS", "ACEOLEDB") )
      dbUseArea(.F., "RDDADOX", (cMDBARQ), , .T., .F.)
   CASE lACCDB
      hb_adoSetTable(cTABELA) 
      hb_adoSetEngine("ACEOLEDB") 
      dbUseArea(.F., "RDDADOX", (cMDBARQ), , .T., .F.)
   CASE lFDB 
      hb_adoSetTable(cTABELA) 
      hb_adoSetEngine("FIREBIRD") 
      hb_adoSetUser(CUSERX) 
      hb_adoSetPassword(CPASSX) 
      dbUseArea(.F., "RDDADOX", (cMDBARQ), , .T., .F.)
   CASE cTIPOSQL == "SQLITE"
      hb_adoSetTable(cTABELA) 
      hb_adoSetEngine("SQLITE") 
      dbUseArea(.F., "RDDADOX", (cMDBARQ), , .T., .F.)
   CASE cTIPOSQL == "MYSQL" .OR. cTIPOSQL == "MYSQL64"
      hb_adoSetTable(cTABELA) 
      hb_adoSetEngine( iif(loledb, "MYSQL", "MYSQL64") ) 
      hb_adoSetServer(cSERVERx); hb_adoSetUser(CUSERX); hb_adoSetPassword(CPASSX) 
      dbUseArea(.F., "RDDADOX", (cMDBARQ), , .T., .F.)
   CASE cTIPOSQL == "MARIADB"
      hb_adoSetTable(cTABELA) 
      hb_adoSetEngine("MARIADB") 
      hb_adoSetServer(cSERVERx); hb_adoSetUser(CUSERX); hb_adoSetPassword(CPASSX) 
      dbUseArea(.F., "RDDADOX", (cMDBARQ), , .T., .F.)
   CASE cTIPOSQL == "MSSQL" .OR. cTIPOSQL == "SQLSERVER"
      hb_adoSetTable(cTABELA) 
      hb_adoSetEngine("SQL") 
      hb_adoSetServer(cSERVERx); hb_adoSetUser(CUSERX); hb_adoSetPassword(CPASSX) 
      dbUseArea(.F., "RDDADOX", (cMDBARQ), , .T., .F.)
   CASE cTIPOSQL == "PGSQL" .OR. cTIPOSQL == "PGSQL64" .OR. cTIPOSQL == "POSTGRESQL"
      TRY
         hb_adoSetTable(cTABELA) 
         hb_adoSetEngine( iif(loledb, "PGSQL", "PGSQL64") ) 
         hb_adoSetServer(cSERVERx); hb_adoSetUser(CUSERX); hb_adoSetPassword(CPASSX) 
         dbUseArea(.F., "RDDADOX", (cMDBARQ), , .T., .F.)
      CATCH; MDT("Erro Abrindo"); lRETU := .F.; END
   CASE cTIPOSQL == "PARADOX"
      hb_adoSetTable(cTABELA)
      hb_adoSetEngine("PARADOX")
      dbUseArea(.F., "RDDADOX", (cMDBARQ), , .T., .F.)
   ENDCASE
   RETURN lRETU