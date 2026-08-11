// +--------------------------------------------------------------------
// +
// +    Programa  : dbudialeto.prg
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
// +    Documentado em 28-Dez-2024 as 10:06 am
// +
// +--------------------------------------------------------------------
// +
#include "dbstruct.ch"
#INCLUDE "TRY.CH"
#INCLUDE "DBINFO.CH"
#include "hbwin.ch"

/* tamanho campos tabelas indices
Oracle (Versões anteriores à 12c.2): Limite de 30 bytes (caracteres).

Firebird: Limite de 31 caracteres.

PostgreSQL: Limite padrão de 63 bytes.

MySQL / MariaDB: Limite de 64 caracteres.

DuckDB / SQLite / SQL Server: Limite de pelo menos 128 a 256 caracteres (SQLite e DuckDB praticamente ilimitados).
*/


// Exemplo de função para higienizar a matriz do dbstruct()
//As letras após os dois pontos: Representam flags de collation, suporte a Unicode/UTF-8 e regras de comparação de strings. No caso específico de :BZEU:
//    B / BZ: Frequentemente associado a Binary ou Binary Collation / Case-Insensitive (regras de ordenação binária ou sem distinção entre maiúsculas e minúsculas).
//    EU / U: Indica tipicamente suporte a UTF-8 (Extended Unicode ou UTF-8 Encoding).
FUNCTION CleanDbStruct( aStruct )
   Local i, cType
   For i := 1 To Len( aStruct )
      cType := aStruct[ i, 2 ] // Pega a string do tipo (ex: "C:BZEU")
      If At( ":", cType ) > 0
         // Corta tudo a partir dos dois pontos, mantendo apenas a letra base (ex: "C")
         aStruct[ i, 2 ] := SubStr( cType, 1, At( ":", cType ) - 1 )
      EndIf
   Next
RETURN aStruct

FUNCTION ConverterEmptyParaSQL( cSQL )
   LOCAL nPos, nInicio, nFim, cCampo, cSubst, lNot, nTamRemover
   
   // Loop para processar todas as ocorrências
   DO WHILE (At("EMPTY(", Upper(cSQL)) > 0)
      nPos := At("EMPTY(", Upper(cSQL))
      
      // Analisa o contexto anterior para ver se é NOT ou !
      lNot := DetectarNegacao(cSQL, nPos)
      
      // Identifica o conteúdo dentro dos parênteses
      nInicio := At("(", SubStr(cSQL, nPos)) + nPos - 1
      nFim    := At(")", SubStr(cSQL, nInicio))
      
      IF nFim > 0
         nFim += nInicio - 1
         cCampo := AllTrim(SubStr(cSQL, nInicio + 1, nFim - nInicio - 1))
         
         // Define quanto remover da string original
         // Se for NOT, removemos o "NOT" e o "EMPTY("
         // Se for "!", removemos o "!" e o "EMPTY("
         IF lNot
            // Busca o início real para remover o NOT ou o !
            // Se tem "NOT", remove 3 chars, se "!", remove 1
            nTamRemover := IIF(At("NOT", Upper(SubStr(cSQL, Max(1, nPos-4), 4))) > 0, 3, 1)
            cSQL := Stuff(cSQL, nPos - nTamRemover, (nFim - (nPos - nTamRemover) + 1), "")
         ELSE
            cSQL := Stuff(cSQL, nPos, (nFim - nPos + 1), "")
         ENDIF
         
         // Insere o fragmento SQL no lugar
         cSubst := GerarFragmentoSQL(cCampo, lNot)
         cSQL := SubStr(cSQL, 1, nPos - 1 - IIF(lNot, nTamRemover, 0)) + cSubst + SubStr(cSQL, nPos - IIF(lNot, nTamRemover, 0))
         
      ELSE
         EXIT 
      ENDIF
   ENDDO
RETURN cSQL

FUNCTION DetectarNegacao( cSQL, nPos )
   LOCAL cPrecedente := ""
   LOCAL lNot := .F.
   
   // Verifica até 10 caracteres antes de EMPTY(
   IF nPos > 5
      cPrecedente := AllTrim(Upper(SubStr(cSQL, nPos - 5, 5)))
   ELSE
      cPrecedente := AllTrim(Upper(SubStr(cSQL, 1, nPos - 1)))
   ENDIF

   // Checa se termina com "!" ou "NOT"
   IF Right(cPrecedente, 1) == "!" .OR. Right(cPrecedente, 3) == "NOT"
      lNot := .T.
   ENDIF
   
RETURN lNot

FUNCTION GerarFragmentoSQL(cCampo, lNot)
   LOCAL cRet := ""
   
   // A lógica de "Vazio" varia conforme o dialeto:
   // - Alguns tratam '' como NULL (Oracle)
   // - Alguns exigem a verificação explícita de string vazia
   
   IF lNot
      // Lógica para !EMPTY(campo) -> IS NOT NULL
      DO CASE
         CASE cTIPOSQL == "MSSQL" .OR. cTIPOSQL == "SQLSERVER"
            cRet := " ( " + cCampo + " IS NOT NULL AND " + cCampo + " <> '' ) "
            
         CASE cTIPOSQL == "PGSQL" .OR. cTIPOSQL == "POSTGRESQL"
            cRet := " ( " + cCampo + " IS NOT NULL AND " + cCampo + " <> '' ) "
            
         CASE cTIPOSQL == "MYSQL" .OR. cTIPOSQL == "MARIADB"
            cRet := " ( " + cCampo + " IS NOT NULL AND " + cCampo + " <> '' ) "
            
         CASE cTIPOSQL == "SQLITE"
            cRet := " ( " + cCampo + " IS NOT NULL AND " + cCampo + " <> '' ) "
            
         CASE cTIPOSQL == "FIREBIRD"
            cRet := " ( " + cCampo + " IS NOT NULL AND " + cCampo + " <> '' ) "
            
         CASE cTIPOSQL == "ORACLE"
            cRet := " ( " + cCampo + " IS NOT NULL ) "
         CASE cTIPOSQL == "DUCKDB"
              cRet := " ( " + cCampo + " IS NOT NULL AND " + cCampo + " <> '' ) "
            
         OTHERWISE // Padrão ANSI (Compatível com a maioria)
            cRet := " ( " + cCampo + " IS NOT NULL AND " + cCampo + " <> '' ) "
      ENDCASE
   ELSE
      // Lógica para EMPTY(campo) -> IS NULL
      DO CASE
         CASE cTIPOSQL == "MSSQL" .OR. cTIPOSQL == "SQLSERVER"
            cRet := " ( " + cCampo + " IS NULL OR " + cCampo + " = '' ) "
            
         CASE cTIPOSQL == "PGSQL" .OR. cTIPOSQL == "POSTGRESQL"
            cRet := " ( " + cCampo + " IS NULL OR " + cCampo + " = '' ) "
            
         CASE cTIPOSQL == "MYSQL" .OR. cTIPOSQL == "MARIADB"
            cRet := " ( " + cCampo + " IS NULL OR " + cCampo + " = '' ) "
            
         CASE cTIPOSQL == "SQLITE"
            cRet := " ( " + cCampo + " IS NULL OR " + cCampo + " = '' ) "
            
         CASE cTIPOSQL == "FIREBIRD"
            // Firebird tem uma particularidade: '' às vezes é tratado como NULL
            cRet := " ( " + cCampo + " IS NULL OR " + cCampo + " = '' ) "
            
         CASE cTIPOSQL == "ORACLE"
            cRet := " ( " + cCampo + " IS NULL ) "
            
        CASE cTIPOSQL == "DUCKDB"
            cRet := " ( " + cCampo + " IS NULL OR " + cCampo + " = '' ) "
            
         OTHERWISE // Padrão ANSI
            cRet := " ( " + cCampo + " IS NULL OR " + cCampo + " = '' ) "
      ENDCASE
   ENDIF
   
RETURN cRet

FUNCTION IsDriverInstalled( cDriverName )
   LOCAL lRet     := .F.
   LOCAL cKeyPure := "HKLM\SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers\" + cDriverName
   LOCAL cKeyWow  := "HKLM\SOFTWARE\WOW6432Node\ODBC\ODBCINST.INI\ODBC Drivers\" + cDriverName
   LOCAL uValue

   // 1. Tenta ler o registro padrão de 32 bits
   uValue := win_regRead( cKeyPure )
   IF HB_IsString( uValue ) .AND. uValue == "Installed"
      lRet := .T.
   ENDIF

   // 2. Se não encontrou, tenta ler a ramificação WOW6432Node (Windows 64 bits)
   IF !lRet
      uValue := win_regRead( cKeyWow )
      IF HB_IsString( uValue ) .AND. uValue == "Installed"
         lRet := .T.
      ENDIF
   ENDIF

RETURN lRet


// +--------------------------------------------------------------------
// +
// +    Function DriverFirebird()
// +
// +--------------------------------------------------------------------
// +

FUNCTION DriverFirebird() 
LOCAL cDriverFirebird
cDriverFirebird:=""
    If IsDriverInstalled("Firebird ODBC Driver") 
       cDriverFirebird = "Firebird ODBC Driver"
    Else
       If IsDriverInstalled("Firebird/InterBase(r) driver") 
          cDriverFirebird = "Firebird/InterBase(r) driver"
       EndIf
    EndIf
    IF EMPTY(cDriverFirebird)
       cDriverFirebird = "Firebird ODBC Driver"
    ENDIF
RETURN cDriverFirebird

// +--------------------------------------------------------------------
// +
// +
// +
// +    Function Dialeto_begin()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION Dialeto_begin(cTipo)

   LOCAL cCOMANDO
   
   hb_Default( @cTipo, cTIPOSQL ) // Usa a global como fallback

   cCOMANDO := "BEGIN TRANSACTION"
   DO CASE
   CASE cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER"
      cCOMANDO := "BEGIN TRANSACTION"
   CASE cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB"
      cCOMANDO := "START TRANSACTION;"
   CASE cTIPOSQL = "FIREBIRD"
      cCOMANDO := "SET TRANSACTION"
   CASE cTIPOSQL = "SQLITE" .OR. At( ".SQLITE", Upper( cdatabaseX ) ) > 0
      cCOMANDO := "BEGIN TRANSACTION;"
   CASE cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL"
      cCOMANDO := "BEGIN;"
    CASE cTIPOSQL="ORACLE" .OR. cTIPOSQL="OCI"
           cCOMANDO ="SET TRANSACTION READ WRITE;"        
    CASE cTIPOSQL == "DUCKDB"
        cCOMANDO := "BEGIN TRANSACTION;"  
      
   ENDCASE

   RETURN cCOMANDO


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function Dialeto_commit()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION Dialeto_commit()

   LOCAL cCOMANDO

   cCOMANDO := "COMMIT TRANSACTION"
   DO CASE
   CASE cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER"
      cCOMANDO := "IF @@TRANCOUNT > 0 COMMIT"
   CASE cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB"
      cCOMANDO := "COMMIT;"
   CASE cTIPOSQL = "FIREBIRD"
      cCOMANDO := "COMMIT"
   CASE cTIPOSQL = "SQLITE" .OR. At( ".SQLITE", Upper( cdatabaseX ) ) > 0
      cCOMANDO := "end transaction"
   CASE cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL"
      cCOMANDO := "COMMIT;"
   CASE cTIPOSQL == "DUCKDB"
   cCOMANDO := "COMMIT;"   
   ENDCASE

   RETURN cCOMANDO


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function Dialeto_rollback()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION Dialeto_rollback()

   LOCAL cCOMANDO

   cCOMANDO := "ROLLBACK TRANSACTION"
   DO CASE
   CASE cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER"
      cCOMANDO := "IF @@TRANCOUNT > 0 ROLLBACK"
   CASE cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB"
      cCOMANDO := "ROLLBACK;"
   CASE cTIPOSQL = "FIREBIRD"
      cCOMANDO := "ROLLBACK"
   CASE cTIPOSQL = "SQLITE" .OR. At( ".SQLITE", Upper( cdatabaseX ) ) > 0
      cCOMANDO := "ROLLBACK;"
   CASE cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL"
      cCOMANDO := "ROLLBACK;"
   CASE cTIPOSQL == "DUCKDB"
   cCOMANDO := "ROLLBACK;"   
   ENDCASE

   RETURN cCOMANDO
   
// +--------------------------------------------------------------------
// +
// +
// +
// +    Function Dialeto_DataBanco()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +   
 Function Dialeto_DataBanco()
LOCAL cCOMANDO
cCOMANDO:=""
  DO CASE
      CASE cTIPOSQL="MSSQL" .OR. cTIPOSQL="SQLSERVER"
           cCOMANDO ="GETDATE()"
      CASE cTIPOSQL="MYSQL" .OR. cTIPOSQL="MYSQL64"  .OR. cTIPOSQL="MARIADB"
           cCOMANDO ="SYSDATE()"
    //  CASE cTIPOSQL="FIREBIRD"
    //       cCOMANDO =""
      CASE cTIPOSQL="SQLITE" .or. at(".SQLITE",upper(cdatabaseX))>0
           cCOMANDO ="CURRENT_DATE"
      CASE cTIPOSQL="PGSQL" .OR. cTIPOSQL="PGSQL64" .OR. cTIPOSQL="POSTGRESQL"
           cCOMANDO ="CURRENT_DATE"
        CASE cTIPOSQL="ORACLE" .OR. cTIPOSQL="OCI"
           cCOMANDO ="SYSDATE"  
      CASE cTIPOSQL == "DUCKDB"
   cCOMANDO := "CURRENT_DATE"                  
   ENDCASE
return cCOMANDO  


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function Dialeto_DataHoraBanco()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +   
 Function Dialeto_DataHoraBanco()
LOCAL cCOMANDO
cCOMANDO:=""
  DO CASE
      CASE cTIPOSQL="MSSQL" .OR. cTIPOSQL="SQLSERVER"
           cCOMANDO ="SYSDATETIME()"
      CASE cTIPOSQL="MYSQL" .OR. cTIPOSQL="MYSQL64"  .OR. cTIPOSQL="MARIADB"
           cCOMANDO ="CURRENT_TIMESTAMP ()"
    //  CASE cTIPOSQL="FIREBIRD"
    //       cCOMANDO =""
      CASE cTIPOSQL="SQLITE" //.or. at(".SQLITE",upper(cdatabaseX))>0
           cCOMANDO ="CURRENT_TIMESTAMP"
      CASE cTIPOSQL="PGSQL" .OR. cTIPOSQL="PGSQL64" .OR. cTIPOSQL="POSTGRESQL"
           cCOMANDO ="NOW()"
        CASE cTIPOSQL="ORACLE" .OR. cTIPOSQL="OCI"
           cCOMANDO ="SYSTIMESTAMP"
     CASE cTIPOSQL == "DUCKDB"
   cCOMANDO := "CURRENT_TIMESTAMP"                     
   ENDCASE
return cCOMANDO  

// +--------------------------------------------------------------------
// +
// +
// +
// +    Function Dialeto_DataVazia()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +   
   
 Function Dialeto_DataVazia(cSQLDIALETO)
LOCAL cCOMANDO
IF VALTYPE(cSQLDIALETO)<>"C"
   cSQLDIALETO:=cTIPOSQL //utiliza global
ENDIF
cCOMANDO:=""
  DO CASE
      CASE cSQLDIALETO="MSSQL" .OR. cSQLDIALETO="SQLSERVER"
           cCOMANDO ="NULL"
      CASE cSQLDIALETO="MYSQL" .OR. cSQLDIALETO="MYSQL64"  .OR. cSQLDIALETO="MARIADB"
           cCOMANDO ="NULL"
    //  CASE cTIPOSQL="FIREBIRD"
    //       cCOMANDO =""
      CASE cSQLDIALETO="SQLITE" //.or. at(".SQLITE",upper(cdatabaseX))>0
           cCOMANDO =""
      CASE cSQLDIALETO="PGSQL" .OR. cSQLDIALETO="PGSQL64" .OR. cSQLDIALETO="POSTGRESQL"
           cCOMANDO ="NULL"
      CASE cSQLDIALETO="ORACLE" .OR. cSQLDIALETO="OCI"
           cCOMANDO ="NULL"               
   ENDCASE
return cCOMANDO  


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function Dialeto_GetIdentity ()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +   

Function Dialeto_GetIdentity() // AS LAST_ID; facilita implantacao pois todos voltam lat_id
LOCAL cCOMANDO
cCOMANDO:=""
  DO CASE
      CASE cTIPOSQL="MSSQL" .OR. cTIPOSQL="SQLSERVER"
           cCOMANDO ="select @@IDENTITY  AS LAST_ID;"
      CASE cTIPOSQL="MYSQL" .OR. cTIPOSQL="MYSQL64"  .OR. cTIPOSQL="MARIADB"
           cCOMANDO ="select LAST_INSERT_ID() AS LAST_ID;"
   //   CASE cTIPOSQL="FIREBIRD"
   //        cCOMANDO =""
      CASE cTIPOSQL="SQLITE" .or. at(".SQLITE",upper(cdatabaseX))>0
           cCOMANDO ="SELECT last_insert_rowid()  AS LAST_ID;"
      CASE cTIPOSQL="PGSQL" .OR. cTIPOSQL="PGSQL64" .OR. cTIPOSQL="POSTGRESQL"
           cCOMANDO ="SELECT lastval() AS LAST_ID;"
       CASE cTIPOSQL="ORACLE" .OR. cTIPOSQL="OCI"
           cCOMANDO ="select LAST_INSERT_ID()  AS LAST_ID;"  
       CASE cTIPOSQL == "CUBRID"   
          cCOMANDO := "SELECT LAST_INSERT_ID()" 
       CASE cTIPOSQL == "DUCKDB"
   cCOMANDO := "SELECT last_insert_rowid() AS LAST_ID;" // Ou via sequência      
   ENDCASE
return cCOMANDO

// +--------------------------------------------------------------------
// +
// +    Function Dialeto_ShowDatabases()
// +
// +    Retorna o comando SQL para listar as bases de dados/schemas
// +    Padroniza o retorno com o alias "DB_NAME"
// +
// +--------------------------------------------------------------------
FUNCTION Dialeto_ShowDatabases(cTipo)
   LOCAL cCOMANDO := ""
   
   hb_Default( @cTipo, cTIPOSQL ) // Usa a global como fallback

   DO CASE
   CASE cTipo == "MYSQL" .OR. cTipo == "MYSQL64" .OR. cTipo == "MARIADB"
      // O MySQL não aceita bem alias direto no SHOW DATABASES se usado de forma simples,
      // para garantir o alias padronizado em consultas relacionais estritas, podemos usar a information_schema:
      cCOMANDO := "SELECT SCHEMA_NAME AS DB_NAME FROM INFORMATION_SCHEMA.SCHEMATA;"  //"SHOW DATABASES;"

   CASE cTipo == "PGSQL" .OR. cTipo == "PGSQL64" .OR. cTipo == "POSTGRESQL"
      cCOMANDO := "SELECT datname AS DB_NAME FROM pg_database WHERE datistemplate = false;"

   CASE cTipo == "MSSQL" .OR. cTipo == "SQLSERVER"
      cCOMANDO := "SELECT name AS DB_NAME FROM master.dbo.sysdatabases WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb');"

   CASE cTipo == "ORACLE" .OR. cTipo == "OCI" 
      // No Oracle, o conceito de "Database" equivale mais ao "User/Schema" aberto
      cCOMANDO := "SELECT username AS DB_NAME FROM dba_users WHERE account_status = 'OPEN' ORDER BY username;"

   CASE cTipo == "SQLITE" .OR. At( ".SQLITE", Upper( cdatabaseX ) ) > 0    
      cCOMANDO := "SELECT name AS DB_NAME FROM pragma_database_list;"

   CASE cTipo == "FIREBIRD" .OR. cTipo == "FDB" .OR. cTipo == "GDB" .OR. cTipo == "IB"
      // No Firebird, por arquitetura, ele não lista outros bancos nativamente via SQL (cada arquivo FDB é isolado).
      // O padrão para retornar o alias do banco conectado na sessão atual é:
      cCOMANDO := "SELECT RDB$GET_CONTEXT('SYSTEM', 'DB_NAME') AS DB_NAME FROM RDB$DATABASE;"
   ENDCASE

RETURN cCOMANDO


FUNCTION Dialeto_Version(cTipo)
   LOCAL cCOMANDO := ""
   
   hb_Default( @cTipo, cTIPOSQL ) // Usa a global como fallback

   DO CASE
   CASE cTipo == "MSSQL" .OR. cTipo == "SQLSERVER"
      cCOMANDO := "SELECT @@VERSION AS VER;"

   CASE cTipo == "MYSQL" .OR. cTipo == "MYSQL64" .OR. cTipo == "MARIADB"
      cCOMANDO := "SELECT VERSION() AS VER;"

   CASE cTipo == "FIREBIRD" .OR. cTipo == "FDB" .OR. cTipo == "GDB" .OR. cTipo == "IB"
      // Em SQL padrão, apelidos de colunas usam aspas duplas ou nenhuma aspa.
      cCOMANDO := 'SELECT RDB$GET_CONTEXT("SYSTEM", "ENGINE_VERSION") AS VER FROM RDB$DATABASE;'

   CASE cTipo == "SQLITE" .OR. At( ".SQLITE", Upper( cdatabaseX ) ) > 0
      cCOMANDO := "SELECT sqlite_version() AS VER;"

   CASE cTipo == "PGSQL" .OR. cTipo == "PGSQL64" .OR. cTipo == "POSTGRESQL"
      cCOMANDO := "SELECT VERSION() AS VER;"

   CASE cTipo == "ORACLE" .OR. cTipo == "OCI"
      cCOMANDO := "SELECT BANNER AS VER FROM V$VERSION WHERE ROWNUM = 1;"
   CASE cTipo == "DUCKDB"
        cCOMANDO := "SELECT duckdb_version() AS VER;"   
      
   ENDCASE

RETURN cCOMANDO

// +--------------------------------------------------------------------
// +
// +
// +
// +    Function Dialeto_GetRowCount()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +   

Function Dialeto_GetRowCount()
LOCAL cCOMANDO
cCOMANDO:=""
  DO CASE
      CASE cTIPOSQL="MSSQL" .OR. cTIPOSQL="SQLSERVER"
           cCOMANDO ="select @@ROWCOUNT"
      CASE cTIPOSQL="MYSQL" .OR. cTIPOSQL="MYSQL64"  .OR. cTIPOSQL="MARIADB"
           cCOMANDO ="select ROW_COUNT()"
   //   CASE cTIPOSQL="FIREBIRD"
   //        cCOMANDO =""
      CASE cTIPOSQL="SQLITE" .or. at(".SQLITE",upper(cdatabaseX))>0
           cCOMANDO ="SELECT changes()"
      CASE cTIPOSQL="PGSQL" .OR. cTIPOSQL="PGSQL64" .OR. cTIPOSQL="POSTGRESQL"
           cCOMANDO =""
       CASE cTIPOSQL="ORACLE" .OR. cTIPOSQL="OCI"
           cCOMANDO ="select SQL%ROWCOUNT"     
      CASE cTIPOSQL == "DUCKDB"
           cCOMANDO := "SELECT last_rows_affected()"     
   ENDCASE
return cCOMANDO


// +--------------------------------------------------------------------
// +    Function Dialeto_SetLimit( nQtd )
// +--------------------------------------------------------------------
FUNCTION Dialeto_SetLimit( nQtd )
   LOCAL cCOMANDO := ""
   LOCAL cQtd     := AllTrim( hb_ntos( nQtd ) )

   DO CASE
   CASE cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" ;
                .OR. cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" ;
                .OR.  cTIPOSQL = "SQLITE" .OR. At( ".SQLITE", Upper( cdatabaseX ) ) > 0 ;
                .OR. cTIPOSQL = "CUBRID"
      cCOMANDO := " LIMIT " + cQtd

   CASE cTIPOSQL = "ORACLE" .OR. cTIPOSQL = "OCI"
      cCOMANDO := " FETCH FIRST " + cQtd + " ROWS ONLY"

   CASE cTIPOSQL == "INFORMIX"   
          cCOMANDO :=  " FIRST " + cQtd
          
   CASE cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER" .OR. cTIPOSQL = "SYBASE"
      cCOMANDO := " TOP " + cQtd + " "       
   CASE cTIPOSQL == "DUCKDB"
      cCOMANDO := " LIMIT " + cQtd       
      
   ENDCASE

   RETURN cCOMANDO

/*
// +--------------------------------------------------------------------
// +
// +
// +    Function Dialeto_()
// +
// +--------------------------------------------------------------------
// +   

Function Dialeto_()
LOCAL cCOMANDO
cCOMANDO:=""
  DO CASE
      CASE cTIPOSQL="MSSQL" .OR. cTIPOSQL="SQLSERVER"
           cCOMANDO =""
      CASE cTIPOSQL="MYSQL" .OR. cTIPOSQL="MYSQL64"  .OR. cTIPOSQL="MARIADB"
           cCOMANDO =""
      CASE cTIPOSQL="FIREBIRD"
           cCOMANDO =""
      CASE cTIPOSQL="SQLITE" .or. at(".SQLITE",upper(cdatabaseX))>0
           cCOMANDO =""
      CASE cTIPOSQL="PGSQL" .OR. cTIPOSQL="PGSQL64" .OR. cTIPOSQL="POSTGRESQL"
           cCOMANDO =""
       CASE cTIPOSQL="ORACLE" .OR. cTIPOSQL="OCI"
           cCOMANDO =""     
   ENDCASE
return cCOMANDO

*/


// +--------------------------------------------------------------------
// +
// +
// +    Function Dialeto_concat()
// +
// +--------------------------------------------------------------------
// +   

Function Dialeto_concat()
LOCAL cCOMANDO
cCOMANDO:=""
// +  || (MySQL:
  DO CASE
      CASE cTIPOSQL="MSSQL" .OR. cTIPOSQL="SQLSERVER"
           cCOMANDO =""
      CASE cTIPOSQL="MYSQL" .OR. cTIPOSQL="MYSQL64"  .OR. cTIPOSQL="MARIADB"
           cCOMANDO =""
      CASE cTIPOSQL="FIREBIRD"
           cCOMANDO =""
      CASE cTIPOSQL="SQLITE" .or. at(".SQLITE",upper(cdatabaseX))>0
           cCOMANDO =""
      CASE cTIPOSQL="PGSQL" .OR. cTIPOSQL="PGSQL64" .OR. cTIPOSQL="POSTGRESQL"
           cCOMANDO =""
       CASE cTIPOSQL="ORACLE" .OR. cTIPOSQL="OCI"
           cCOMANDO =""     
   ENDCASE
return cCOMANDO

// +--------------------------------------------------------------------
// +
// +
// +    Function Dialeto_condicionais()
// +
// +--------------------------------------------------------------------
// +   

Function Dialeto_condicionais(cSQLCNV)
 //Removendo os pontos do harbour
   cSQLCNV := StrTran( cSQLCNV, ".NOT.", " NOT " )
   cSQLCNV := StrTran( cSQLCNV, ".OR.", " OR " )
   cSQLCNV := StrTran( cSQLCNV, ".AND.", " AND " )

// .not. .or. .AND. //harbour usa ponto(.)
  DO CASE
      CASE cTIPOSQL="MSSQL" .OR. cTIPOSQL="SQLSERVER"
           cSQLCNV := StrTran( cSQLCNV, "!=", " <> " )
      CASE cTIPOSQL="MYSQL" .OR. cTIPOSQL="MYSQL64"  .OR. cTIPOSQL="MARIADB"
           
      CASE cTIPOSQL="FIREBIRD"
           
      CASE cTIPOSQL="SQLITE" 
           
      CASE cTIPOSQL="PGSQL" .OR. cTIPOSQL="PGSQL64" .OR. cTIPOSQL="POSTGRESQL"
           cSQLCNV := StrTran( cSQLCNV, "<>", " != " )
       CASE cTIPOSQL="ORACLE" .OR. cTIPOSQL="OCI"
                
   ENDCASE
return cSQLCNV




// +--------------------------------------------------------------------
// +
// +
// +
// +    Function Dialeto_SQL()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION Dialeto_SQL( cSQLCNV )
   //Removendo os pontos do harbour
   cSQLCNV := Dialeto_condicionais(cSQLCNV)
   cSQLCNV := ConverterEmptyParaSQL( cSQLCNV )
   
   DO CASE
   CASE cTIPOSQL = "SQLITE"
      // '"LOWER(%1%)"        ,"LOWER(%1%)"
      // '"UPPER(%1%)"        ,"UPPER(%1%)"
      cSQLCNV := StrTran( cSQLCNV, "TODAY()", "CURRENT_DATE " )
      cSQLCNV := StrTran( cSQLCNV, "CHR(", "CHAR(" )
      cSQLCNV := StrTran( cSQLCNV, "ASC(", "ASCII(" )
      cSQLCNV := StrTran( cSQLCNV, "TRIM(", "RTRIM(" )
      cSQLCNV := StrTran( cSQLCNV, "ALLTRIM(", "TRIM(" )
      cSQLCNV := StrTran( cSQLCNV, "LEN(", "LENGTH(" )
      cSQLCNV := StrTran( cSQLCNV, "CURRENTDATETIME", " current_timestamp " )
      
      // Tradução de REPL() (Repetir caracteres)
        cSQLCNV := StrTran( cSQLCNV, "REPL(", "printf('%.*c', " ) // Gambiarra comum em SQLite

        // Tratamento de Substring (Harbour usa 1-based)
        cSQLCNV := StrTran( cSQLCNV, "SUBSTR(", "SUBSTR(" ) 

        // DTOS (Data para String YYYYMMDD)
        cSQLCNV := StrTran( cSQLCNV, "DTOS(", "strftime('%Y%m%d', " )
      
      // '  {"LEFT(%1%,%2%)"      ,"SUBSTR(%1%,1,%2%)"},;
      // '        {"DTOS(%1%)"        ,"strftime('%Y%m%d',%1%)"},;
      // '        {"DAY(%1%)"       ,"cast(strftime('%d',%1) as int)"},;
      // ''        {"MONTH(%1%)"       ,"cast(strftime('%m',%1) as int)"},;
      // '        {"YEAR(%1%)"        ,"cast(strftime('%Y',%1) as int)"},;
      // '        {"REPL(%1%,%2%)"      ,"FORMAT('%.*c',%2%,%1%)"},;
   CASE cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB"
      // '"LOWER(%1%)"        ,"LOWER(%1%)"
      // '"UPPER(%1%)"        ,"UPPER(%1%)"
      // '"LEFT(%1%,%2%)"     ,"LEFT(%1%,%2%)"
      // '"DAY(%1%)"         ,"DAY(%1%)"
      // '"MONTH(%1%)"       ,"MONTH(%1%)"}
      // '"YEAR(%1%)"        ,"YEAR(%1%)"
      cSQLCNV := StrTran( cSQLCNV, "TODAY()", "SYSDATE()" )
      cSQLCNV := StrTran( cSQLCNV, "CHR(", "CHAR(" )
      cSQLCNV := StrTran( cSQLCNV, "ASC(", "ASCII(" )
      cSQLCNV := StrTran( cSQLCNV, "TRIM(", "RTRIM(" )
      cSQLCNV := StrTran( cSQLCNV, "ALLTRIM(", "TRIM(" )
      cSQLCNV := StrTran( cSQLCNV, "REPL(", "REPEAT(" )
      // '        {"DTOS(%1%)"        ,"DATE_FORMAT(%1%,'%Y%m%d')"},;
   CASE cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL"
      // '"LOWER(%1%)"        ,"LOWER(%1%)"
      // '"UPPER(%1%)"        ,"UPPER(%1%)"
      // '"LEFT(%1%,%2%)"      ,"LEFT(%1%,%2%)"
      // '"CHR(%1%)"         ,"CHR(%1%)"
      cSQLCNV := StrTran( cSQLCNV, "TODAY()", "CURRENT_DATE " )
      cSQLCNV := StrTran( cSQLCNV, "ASC(", "ASCII(" )
      cSQLCNV := StrTran( cSQLCNV, "TRIM(", "RTRIM(" )
      cSQLCNV := StrTran( cSQLCNV, "ALLTRIM(", "TRIM(" )
      cSQLCNV := StrTran( cSQLCNV, "LEN(", "LENGTH(" )
      cSQLCNV := StrTran( cSQLCNV, "DAY(", "EXTRACT('DAY' FROM " )
      cSQLCNV := StrTran( cSQLCNV, "MONTH(", "EXTRACT('MONTH' FROM " )
      cSQLCNV := StrTran( cSQLCNV, "YEAR(", "EXTRACT('YEAR' FROM " )
      cSQLCNV := StrTran( cSQLCNV, "REPL(", "REPEAT(" )
      // Booleano: Converter .T. e .F. do Harbour
     cSQLCNV := StrTran( cSQLCNV, ".T.", "TRUE" )
     cSQLCNV := StrTran( cSQLCNV, ".F.", "FALSE" )
     
     // 2. Limpeza de datas vazias (Clipper adora '  /  /  ')
      // O Postgres quebra se receber uma string vazia em um campo DATE.
      cSQLCNV := StrTran( cSQLCNV, "'  /  /  '", "NULL" )
      cSQLCNV := StrTran( cSQLCNV, "'00/00/0000'", "NULL" )

      // 3. Funções do SQLite/Access para equivalentes Postgres
      cSQLCNV := StrTran( cSQLCNV, "IIF(", "CASE WHEN " ) // Se usar IIF do Access, precisará expandir para CASE WHEN
      cSQLCNV := StrTran( cSQLCNV, "NOW()", "CURRENT_TIMESTAMP" )
      cSQLCNV := StrTran( cSQLCNV, "IFNULL(", "COALESCE(" ) // O SQLite usa IFNULL, o Pos
     
     
  CASE cTIPOSQL == "DUCKDB"
   cSQLCNV := StrTran( cSQLCNV, "TODAY()", "CURRENT_DATE" )
   cSQLCNV := StrTran( cSQLCNV, "LEN(", "LENGTH(" )
   cSQLCNV := StrTran( cSQLCNV, "ALLTRIM(", "TRIM(" )
   cSQLCNV := StrTran( cSQLCNV, "IIF(", "CASE WHEN " ) // Necessita expandir o IIF
   cSQLCNV := StrTran( cSQLCNV, "CHR(", "CHR(" )   
      
   CASE cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER"
      cSQLCNV := StrTran( cSQLCNV, "TODAY()", "GETDATE() " )
      cSQLCNV := StrTran( cSQLCNV, "ASC(", "ASCII(" )
      cSQLCNV := StrTran( cSQLCNV, "TRIM(", "RTRIM(" )
      cSQLCNV := StrTran( cSQLCNV, "ALLTRIM(", "TRIM(" )
      cSQLCNV := StrTran( cSQLCNV, "REPL(", "REPLICATE(" )
      cSQLCNV := StrTran( cSQLCNV, "CHR(", "CHAR(" )
      cSQLCNV := StrTran( cSQLCNV, "SUBSTR(", "SUBSTRING(" )
      // No MSSQL, SUBSTR deve ser SUBSTRING
      cSQLCNV := StrTran( cSQLCNV, "SUBSTR(", "SUBSTRING(" )

     // AT() do Harbour para CHARINDEX() do SQL
     cSQLCNV := StrTran( cSQLCNV, "AT(", "CHARINDEX(" )
      
      // '  {"STR(%1%,%2%,%3%)"      ,"STR(%1%,%2%,%3%)"},;
      // '       {"STR(%1%,%2%)"       ,"STR(%1%,%2%,0)"},;
      // '     {"DTOS(%1%)"        ,"CONVERT(char(8), %1%,11)"},;
      // '      {"IIF(%1%,%2%,%3%)"     ,"CASE WHEN %1% THEN %2% ELSE %3% END"},;

      // Case "ODBC"
   /*
        '       {"STR(%1%,%2%,%3%)"      ,"{fn RIGHT({fn SPACE(%2%)}+{fn CONVERT({fn ROUND(%1%,%3%)},SQL_VARCHAR)},%2%)}"},;
        '                {"STR(%1%,%2%)"       ,"{fn RIGHT({fn SPACE(%2%)}+{fn CONVERT({fn ROUND(%1%,0)},SQL_VARCHAR)},%2%)}"},;
         '               {"SUBSTR(%1%,%2%,%3%)"    ,"{fn SUBSTRING(%1%,%2%,%3%)}"},;
          '              {"DTOS(%1%)"        ,"{fn CONVERT({fn YEAR(%1%)}, SQL_VARCHAR)}+{fn RIGHT('0'+ {fn CONVERT({fn MONTH(%1%)},SQL_VARCHAR)},2)}+{fn RIGHT('0'+ {fn CONVERT({fn DAYOFMONTH(%1%)},SQL_VARCHAR)},2)}"},;
      '                  {"DAY(%1%)"         ,"{fn DAYOFMONTH(%1%)}"},;
     '                   {"MONTH(%1%)"       ,"{fn MONTH(%1%)}"},;
      '                  {"YEAR(%1%)"        ,"{fn YEAR(%1%)}"},;
         '               {"UPPER(%1%)"       ,"{fn UCASE(%1%)}"},;
         '               {"LOWER(%1%)"       ,"{fn LCASE(%1%)}"},;
         '               {"LEFT(%1%,%2%)"      ,"{fn LEFT(%1%,%2%)}"},;
          '              {"LEN(%1%)"         ,"{fn LENGTH(%1%)}"},;
         '               {"CHR(%1%)"         ,"{fn CHAR(%1%)}"},;
         '               {"ASC(%1%)"         ,"{fn ASCII(%1%)}"},;
         '               {"TODAY()"          ,"{fn CURDATE()}"},;
         '               {"REPL(%1%,%2%)"      ,"{fn REPEAT(%1%,%2%)}"},;
         '               {"TRIM(%1%)"        ,"{fn RTRIM(%1%)}"},;
         ''               {"ALLTRIM(%1%)"       ,"{fn LTRIM( {fn RTRIM(%1%) } )}"},;
         '               {"RIGHT(%1%)"       ,"{fn RIGHT(%1%)}"},;
            */

      // Case "ADS", "ADVANTAGE"


      // Case "OLEDB"
   /*
   '    {"STR(%1%,%2%,%3%)"      ,"{fn RIGHT({fn SPACE(%2%)}+{fn CONVERT({fn ROUND(%1%,%3%)},SQL_VARCHAR)},%2%)}"},;
   '                     {"STR(%1%,%2%)"       ,"{fn RIGHT({fn SPACE(%2%)}+{fn CONVERT({fn ROUND(%1%,0)},SQL_VARCHAR)},%2%)}"},;
   '                     {"SUBSTR(%1%,%2%,%3%)"    ,"{fn SUBSTRING(%1%,%2%,%3%)}"},;
   '                     {"DTOS(%1%)"        ,"{fn CONVERT({fn YEAR(%1%)}, SQL_VARCHAR)}+{fn RIGHT('0'+ {fn CONVERT({fn MONTH(%1%)},SQL_VARCHAR)},2)}+{fn RIGHT('0'+ {fn CONVERT({fn DAYOFMONTH(%1%)},SQL_VARCHAR)},2)}"},;
   '                     {"DAY(%1%)"         ,"{fn DAYOFMONTH(%1%)}"},;
   '                     {"MONTH(%1%)"       ,"{fn MONTH(%1%)}"},;
   '                     {"YEAR(%1%)"        ,"{fn YEAR(%1%)}"},;
   '                     {"UPPER(%1%)"       ,"{fn UCASE(%1%)}"},;
   '                     {"LOWER(%1%)"       ,"{fn LCASE(%1%)}"},;
   '                     {"LEN(%1%)"         ,"{fn LENGTH(%1%)}"},;
   '                     {"CHR(%1%)"         ,"{fn CHAR(%1%)}"},;
   '                     {"ASC(%1%)"         ,"{fn ASCII(%1%)}"},;
   '                     {"TODAY()"          ,"{fn CURDATE()}"},;
   '                     {"REPL(%1%,%2%)"      ,"{fn REPEAT(%1%,%2%)}"},;
   '                     {"TRIM(%1%)"        ,"{fn RTRIM(%1%)}"},;
   '                     {"ALLTRIM(%1%)"       ,"{fn LTRIM( {fn RTRIM(%1%) } )}"},;
   '                     {"LEFT(%1%,%2%)"      ,"{fn LEFT(%1%,%2%)}"},;
   '                     {"RIGHT(%1%)"       ,"{fn RIGHT(%1%)}"},;
            */
   CASE cTIPOSQL = "ORACLE" .OR. cTIPOSQL = "OCI"
      cSQLCNV := StrTran( cSQLCNV, "TODAY()", "SYSDATE " )
      cSQLCNV := StrTran( cSQLCNV, "CHR(", "CHAR(" )
      cSQLCNV := StrTran( cSQLCNV, "ASC(", "ASCII(" )
      cSQLCNV := StrTran( cSQLCNV, "TRIM(", "RTRIM(" )
      cSQLCNV := StrTran( cSQLCNV, "ALLTRIM(", "LTRIM(RTRIM(" )
      cSQLCNV := StrTran( cSQLCNV, "LEN(", "LENGTH(" )
      cSQLCNV := StrTran( cSQLCNV, "REPL(", "REPLICATE(" )
      // '  {"LEFT(%1%,%2%)"     ,"SUBSTR(%1%,1,%2%)"},;
      // '           {"DTOS(%1%)"        ,"TO_CHAR(%1%,'YYYYMMDD')"},;
      // '           {"DAY(%1%)"         ,"TO_NUM(TO_CHAR(%1%,'DD'))"},;
      // '           {"MONTH(%1%)"       ,"TO_NUM(TO_CHAR(%1%,'MM'))"},;
      // '           {"YEAR(%1%)"        ,"TO_NUM(TO_CHAR(%1%,'YYYY'))"},;

   CASE lMDB .OR. lACCDB
      cSQLCNV := StrTran( cSQLCNV, "CURRENTDATETIME", " now " )

   ENDCASE

   RETURN cSQLCNV
   
   
// +--------------------------------------------------------------------
// + Utilitário: FormataBlocoSql
// + Objetivo: Embeleza e formata strings brutas de SQL (CREATE TABLE / INDEX)
// +           Garante compatibilidade estrita, elimina duplicidade de ';'
// +           e protege tipos com decimais como NUMERIC(5,2) ou DECIMAL(12,3)
// +--------------------------------------------------------------------
FUNCTION FormataBlocoSql( cTextoBruto )
   // --- TODAS AS DECLARAÇÕES LOCAL RIGOROSAMENTE NO TOPO ---
   LOCAL aLinhas          := hb_ATokens( cTextoBruto, .T. )
   LOCAL cTextoFormatado  := ""
   LOCAL cInstrucao       := ""
   LOCAL cLinhaLimpa      := ""
   LOCAL cHeader          := ""
   LOCAL cMiolo           := ""
   LOCAL cCampo           := ""
   LOCAL aCampos          := {}
   LOCAL i                := 0
   LOCAL j                := 0
   LOCAL nPosAbre         := 0
   LOCAL nPosFecha        := 0
   LOCAL nContCampo       := 0
   //LOCAL nFIM             := 0

   // --- MIOLO DA FUNÇÃO: APENAS COMANDOS EXECUTÁVEIS ---
   //IF cTIPOSQL="FIREBIRD"
   //   ALTD()
   //ENDIF
   //HB_ATokens( <cString> , <cDelimiter> , <lSkipQuotes> , <lDoubleQuotesOnly> ) -> aTokens
   //MemoLine(<cString>, <nLineLength> , <nLineNumber> , <nTabSize> , <lWrap> ) -> cLine
   
   //nfim=MLCount(cTextoBruto ) 
   
   FOR i := 1 TO Len( aLinhas )
      cLinhaLimpa := AllTrim( aLinhas[i] )  //memoline(cTEXTOBRUTO) PRAGMA
      
      IF  ( "GRANT " $ Upper( cLinhaLimpa ) ) .OR. ( "ENGINE=" $ Upper( cLinhaLimpa ) )  .OR. ( "PRAGMA " $ Upper( cLinhaLimpa ) ) 
          cTextoFormatado += cLinhaLimpa + hb_eol()
          LOOP
      ENDIF
      
   //   IF Empty( cLinhaLimpa ) //Mantem linha em branco
   //       cTextoFormatado +=  hb_eol()
   //       LOOP
    //  ENDIF

      // Ignora linhas vazias, pontos e vírgulas isolados ou tags de seções
      IF Empty( cLinhaLimpa ) .OR. cLinhaLimpa == ";" .OR. ( Left( cLinhaLimpa, 1 ) == "[" .AND. Right( cLinhaLimpa, 1 ) == "]" )
         IF !Empty( cLinhaLimpa ) .AND. cLinhaLimpa != ";"
            cTextoFormatado += cLinhaLimpa + hb_eol()
         ENDIF
         LOOP
      ENDIF

      // Limpa pontos e vírgulas residuais colados na linha antes de acumular
      IF Right( cLinhaLimpa, 1 ) == ";"
         cLinhaLimpa := Left( cLinhaLimpa, Len( cLinhaLimpa ) - 1 )
         cLinhaLimpa := AllTrim( cLinhaLimpa )
      ENDIF

      // Acumula pedaços de strings para remontar o comando completo
      cInstrucao += iif( Empty( cInstrucao ), "", " " ) + cLinhaLimpa



      // Se não atingiu o delimitador final da estrutura, continua acumulando
      IF ! ( "CREATE TABLE" $ Upper( cInstrucao ) ) .AND. ! ( "INDEX" $ Upper( cInstrucao ) ) .AND. ! ( "ALTER" $ Upper( cInstrucao ) )
         LOOP
      ENDIF

      // --- TRATAMENTO DO CREATE TABLE ---
      IF "CREATE TABLE" $ Upper( cInstrucao )
         // Aguarda o fechamento do parêntese final da estrutura da tabela para processar
         IF ! ( ")" $ cLinhaLimpa )
            LOOP
         ENDIF

         nPosAbre  := At( "(", cInstrucao )
         nPosFecha := Rat( ")", cInstrucao )

         IF nPosAbre > 0
            cHeader := Left( cInstrucao, nPosAbre ) 
            cMiolo  := SubStr( cInstrucao, nPosAbre + 1, iif( nPosFecha > 0, nPosFecha - nPosAbre - 1, Len( cInstrucao ) ) )
            
            cTextoFormatado += AllTrim( cHeader ) + hb_eol()
            
            aCampos    := hb_ATokens( cMiolo, "," )
            nContCampo := 0
            
            FOR j := 1 TO Len( aCampos )
               cCampo := AllTrim( aCampos[j] )
               
               // === CORREÇÃO CRÍTICA PARA DECIMAIS EM HARBOUR ===
               // Se houver um parêntese aberto "(" mas nenhum ")" fechando neste bloco do array,
               // significa que a vírgula do decimal (ex: NUMERIC(5,2)) separou o campo.
               // Juntamos com a próxima posição de forma limpa.
               IF ( "(" $ cCampo ) .AND. ! ( ")" $ cCampo ) .AND. j < Len( aCampos )
                  j++
                  cCampo += "," + AllTrim( aCampos[j] )
               ENDIF

               IF !Empty( cCampo )
                  nContCampo++
                  IF nContCampo == 1
                     cTextoFormatado += "    " + cCampo + hb_eol()
                  ELSE
                     cTextoFormatado += "    ," + cCampo + hb_eol()
                  ENDIF
               ENDIF
            NEXT
            
            // Fecha o bloco da tabela perfeitamente com um único ponto e vírgula na mesma linha
            cTextoFormatado += ") ;" + hb_eol()
         ELSE
            cTextoFormatado += cInstrucao + " ;" + hb_eol()
         ENDIF

         cInstrucao := "" 

      // --- TRATAMENTO DE ÍNDICES ---
      ELSEIF "CREATE" $ Upper( cInstrucao ) .AND. "INDEX" $ Upper( cInstrucao )
         cInstrucao := StrTran( cInstrucao, " ;", "" )
         cInstrucao := StrTran( cInstrucao, ";", "" )
         
         cTextoFormatado += AllTrim( cInstrucao ) + " ;" + hb_eol()
         cInstrucao := ""
         
      // --- TRATAMENTO DE ALTER TABLE ---
      ELSEIF "ALTER TABLE" $ Upper( cInstrucao )
         cInstrucao := StrTran( cInstrucao, " ;", "" )
         cInstrucao := StrTran( cInstrucao, ";", "" )
         
         cTextoFormatado += AllTrim( cInstrucao ) + " ;" + hb_eol()
         cInstrucao := ""
      ELSE
         // Fallback estrutural seguro
         cTextoFormatado += AllTrim( cInstrucao ) + " ;" + hb_eol()
         cInstrucao := ""
      ENDIF

   NEXT

RETURN cTextoFormatado



    //SQL MIX does not support all the following field types.
    //    ; Current field type mappings are:
    //        C; Character,n     HB_FT_STRING,n                      ADS_STRING
    //        N; Numeric,n,d     HB_FT_LONG,n,d                      ADS_NUMERIC
    //        D; Date,n          HB_FT_DATE,3 or 4 or 8              ADS_COMPACTDATE; ADS_DATE
    //        ShortDate          HB_FT_DATE,3                        ADS_COMPACTDATE
    //        L; Logical         HB_FT_LOGICAL,1                     ADS_LOGICAL
    //        M; Memo,n          HB_FT_MEMO,4 or 9 or 8              ADS_MEMO
    //        B; Double,,d       HB_FT_DOUBLE,8,d                    ADS_DOUBLE
    //        I; Integer,n       HB_FT_INTEGER, 2 or 4 or 8          ADS_SHORTINT; ADS_INTEGER; ADS_LONGLONG
    //        ShortInt           HB_FT_INTEGER,2                     ADS_SHORTINT
    //        Longlong           HB_FT_INTEGER,8                     ADS_LONGLONG
    //        P; Image           HB_FT_IMAGE,9 or 10                 ADS_IMAGE
    //        W; Binary          HB_FT_BLOB,4 or 9 or 10             ADS_BINARY
    //        Y; Money           HB_FT_CURRENCY,8,4                  ADS_MONEY
    //        Z; CurDouble,,d    HB_FT_CURDOUBLE,8,d                 ADS_CURDOUBLE
    //        T,4; Time          HB_FT_TIME,4                        ADS_TIME
    //        @; T,8; TimeStamp  HB_FT_TIMESTAMP,8                   ADS_TIMESTAMP
    //        +; AutoInc         HB_FT_AUTOINC,4                     ADS_AUTOINC
    //        ^; RowVersion      HB_FT_ROWVER,8                      ADS_ROWVERSION
    //        =; ModTime         HB_FT_MODTIME,8                     ADS_MODTIME
    //        Raw,n              HB_FT_STRING,n (+HB_FF_BINARY)      ADS_RAW
    //        Q; VarChar,n       HB_FT_VARLENGTH,n                   ADS_VARCHAR; ADS_VARCHAR_FOX
    //        VarBinary,n        HB_FT_VARLENGTH,n (+HB_FF_BINARY)   ADS_VARBINARY_FOX; ADS_RAW
    //        CICharacter,n      HB_FT_STRING,n                      ADS_CISTRING

    // /* Field types */
    // #define HB_FT_NONE            0
    // #define HB_FT_STRING          1     /* "C" */
    // #define HB_FT_LOGICAL         2     /* "L" */
    // #define HB_FT_DATE            3     /* "D" */
    // #define HB_FT_LONG            4     /* "N" */
    // #define HB_FT_FLOAT           5     /* "F" */
    // #define HB_FT_INTEGER         6     /* "I" */
    // #define HB_FT_DOUBLE          7     /* "B" */
    // #define HB_FT_TIME            8     /* "T" */
    // #define HB_FT_TIMESTAMP       9     /* "@" */
    // #define HB_FT_MODTIME         10    /* "=" */
    // #define HB_FT_ROWVER          11    /* "^" */
    // #define HB_FT_AUTOINC         12    /* "+" */
    // #define HB_FT_CURRENCY        13    /* "Y" */
    // #define HB_FT_CURDOUBLE       14    /* "Z" */
    // #define HB_FT_VARLENGTH       15    /* "Q" */
    // #define HB_FT_MEMO            16    /* "M" */
    // #define HB_FT_ANY             17    /* "V" */
    // #define HB_FT_IMAGE           18    /* "P" */
    // #define HB_FT_BLOB            19    /* "W" */
    // #define HB_FT_OLE             20    /* "G" */



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function SqliteCreateTable()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION SqliteCreateTable( cTablename, aStruct, cTIPOSQL, lINDEX ,lPK,lINCSR)

   LOCAL mSQL
   LOCAL i, j, nX
   LOCAL llMDB
   LOCAL llACCDB
   LOCAL aCAMMYTRIGER
   LOCAL mFldNm, mFldType, mFldLen, mFldDec
   LOCAL aINDICES, nIndexes, cPKCHAVE, cSqlIdx, cCampo, cSqlTrigger
   
   aCAMMYTRIGER:={}

   IF ValType( cTIPOSQL ) <> "C"
      cTIPOSQL := "SQLITE"
   ENDIF
   
   IF VALTYPE(cTablename)<>"C"
      cTablename:=ALIAS()
   ENDIF
   
   IF VALTYPE(aStruct)<>"A"
     aStruct:=DBSTRUCT()
   ENDIF
   
   IF VALTYPE(lINDEX)<>"L"
      lINDEX:=.F.
   ENDIF
  
   IF VALTYPE(lPK)<>"L"
      lPK:=.F.
   ENDIF 
   
   IF VALTYPE(lINCSR)<>"L"
      lINCSR:=.F.
   ENDIF
   
   IF lINCSR
      AADD(aStruct,{"SR_RECNO"  ,"N",15,0})
      AADD(aStruct,{"SR_DELETED","C", 1,0})
   ENDIF
   
   llMDB:=.F.
   llACCDB:=.F.
   
   IF cTIPOSQL = "MDB" .OR. cTIPOSQL = "ACCESS" .OR. cTIPOSQL = "MDB64" .OR. cTIPOSQL = "ACCESS64"
       llMDB := .T.
   ENDIF
   IF cTIPOSQL = "ACCDB" .OR. cTIPOSQL = "ACCDB64"
       llACCDB := .T.
   ENDIF

   mSql := ""
   IF cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL"  
      cTABLENAME := Upper( cTABLENAME )
   ENDIF
   
 // Validação robusta de quem NÃO aceita o "IF NOT EXISTS"
   IF llMDB .OR. llACCDB .OR. ;
      "ACCESS" $ cTIPOSQL .OR. ;
      "FIREBIRD" $ cTIPOSQL .OR. cTIPOSQL $ "FDB|GDB|IB" .OR. ;
      cTIPOSQL $ "ORACLE|OCI" .OR. ;
      cTIPOSQL $ "MSSQL|SQLSERVER"
      
      // Para estes, usa a sintaxe tradicional estrita
      mSql := "CREATE TABLE " + cTablename + " ("
   ELSE
      // Para MySQL, MariaDB, Postgres e SQLite, usa a sintaxe segura
      mSql := "CREATE TABLE IF NOT EXISTS " + cTablename + " ("
   ENDIF
 
   FOR i := 1 TO Len( aStruct )
      mFldNm   := aStruct[ i, DBS_NAME ]
      mFldType := aStruct[ i, DBS_TYPE ]
      mFldLen  := aStruct[ i, DBS_LEN ]
      mFldDec  := aStruct[ i, DBS_DEC ]

      IF i > 1
         mSql += ", "
      ENDIF
      
      IF cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL"   
         mFldnm := Upper( mFldnm )
      ENDIF
      
      mSql += AllTrim( mFldnm ) + " "

      DO CASE
        CASE (mFldNm == "SR_DELETED") .AND. ( cTIPOSQL == "FIREBIRD" )      
            MSql += " SR_DELETED CHAR(1) DEFAULT ' ' NOT NULL"
      
         // Campo Auto-incremento / SR_RECNO unificado para MySQL/MariaDB
         CASE (mFldType = "+" .OR. mFldNm == "SR_RECNO") .AND. ( cTIPOSQL $ "MYSQL|MYSQL64|MARIADB" )   
            MSql += " INT NOT NULL DEFAULT 0 "
            aadd(aCAMMYTRIGER,mFldNm)
       
         CASE (mFldType = "+" .OR. mFldNm == "SR_RECNO") .AND. ( cTIPOSQL $ "ORACLE|OCI" )  
            MSql += " NUMBER(10,0) GENERATED ALWAYS AS IDENTITY UNIQUE " 
               
         CASE (mFldType = "+" .OR. mFldNm == "SR_RECNO") .AND. ( cTIPOSQL $ "PGSQL|PGSQL64|POSTGRESQL" )       
            MSql += " SERIAL UNIQUE "
               
         CASE (mFldType = "+" .OR. mFldNm == "SR_RECNO") .AND. ( cTIPOSQL $ "MSSQL|SQLSERVER" )      
            MSql += " INT IDENTITY(1,1) UNIQUE "
               
         CASE (mFldType = "+" .OR. mFldNm == "SR_RECNO") .AND. ( cTIPOSQL == "SQLITE" )      
            MSql += " INTEGER UNIQUE " 
               
         CASE (mFldType = "+" .OR. mFldNm == "SR_RECNO") .AND. (cTIPOSQL == "CUBRID" )
            MSql += " BIGINT NOT NULL UNIQUE AUTO_INCREMENT "
            
         CASE (mFldType = "+" .OR. mFldNm == "SR_RECNO") .AND. ( llMDB .OR. llACCDB )
            MSql += " COUNTER UNIQUE "   
               
         CASE (mFldType = "+" .OR. mFldNm == "SR_RECNO") .AND. ( cTIPOSQL == "FIREBIRD" )      
            MSql += " INTEGER GENERATED ALWAYS AS IDENTITY UNIQUE "
            //"SR_RECNO" DECIMAL (15,0) GENERATED BY DEFAULT AS IDENTITY  NOT NULL UNIQUE 
            //SR_RECNO DECIMAL(15,0) GENERATED BY DEFAULT AS IDENTITY NOT NULL,
        	//SR_DELETED CHAR(1) NOT NULL,
	        //CONSTRAINT INTEG_5 UNIQUE (SR_RECNO)
            //CREATE UNIQUE INDEX RDB$3 ON TEST (SR_RECNO);
            
            
         // Caracter (C)
         CASE mFldType = "C" .AND. ( cTIPOSQL = "ORACLE" .OR. cTIPOSQL = "OCI" )
            mSql += "VARCHAR2 (" + LTrim( Str( mFldLen ) ) + ")"
         CASE mFldType = "C" .AND. ( cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER" ;
                                   .OR. cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" ;
                                   .OR. cTIPOSQL == "CUBRID")
            mSql += "VARCHAR(" + LTrim( Str( mFldLen ) ) + ")"
         CASE mFldType = "C" .AND. ( llMDB .OR. llACCDB  )
            mSql += "VARCHAR(" + LTrim( Str( mFldLen ) ) + ") DEFAULT ''"
         
         CASE mFldType = "C" .AND. ( cTIPOSQL = "IBMDB2" )
            IF mFldLen > 128
               mSql += "VARCHAR (" + LTrim( Str( mFldLen ) ) + ")"
            ELSE
               mSql += "CHARACTER (" + LTrim( Str( mFldLen ) ) + ")"
            ENDIF

         CASE mFldType = "C" .AND. ( cTIPOSQL = "INGRES" .OR. cTIPOSQL = "INFORMIX" )
            mSql += "CHARACTER (" + LTrim( Str( mFldLen ) ) + ")"

         CASE mFldType = "C" .AND. ( cTIPOSQL = "SQLANY" .OR. cTIPOSQL = "SYBASE" )
            IF mFldLen > 254
               mSql += "LONG VARCHAR"
            ELSE
               mSql += "CHAR (" + LTrim( Str( mFldLen ) ) + ")"
            ENDIF

         CASE mFldType = "C" .AND. cTIPOSQL = "SQLITE"
            mSql += "TEXT NOT NULL DEFAULT ('')"    
         CASE mFldType = "C" .AND. cTIPOSQL = "FIREBIRD"
            mSql += "VARCHAR(" + LTrim( Str( mFldLen ) ) + ")"  
         // Exemplo de como fica a sua função adaptada
        CASE mFldType = "C" .AND. cTIPOSQL == "DUCKDB"
            IF mFldLen > 0
                mSql += "VARCHAR(" + LTrim(Str(mFldLen)) + ")" // O DuckDB aceita e otimiza
            ELSE
            mSql += "VARCHAR"
        ENDIF    
         CASE mFldType = "C"
            mSql += "CHAR(" + LTrim( Str( mFldLen ) ) + ")"

         // Varchar (V)
         CASE mFldType = "V" .AND. cTIPOSQL = "SQLITE"
            mSql += "TEXT NOT NULL DEFAULT ('')"
         CASE mFldType = "V" .AND. ( cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" )
            IF mFldDec > 0
               mSql += "TEXT(" + hb_ntos( mFldDec ) + ")"
            ELSE
               mSql += "TEXT "
            ENDIF
         CASE mFldType = "V" .AND. ( cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER" ;
                               .OR. cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" ;
                               .OR. cTIPOSQL == "CUBRID" ;
                                    )
            mSql += "VARCHAR(" + hb_ntos( mFldDec ) + ")"
      
         // Date (D)
         CASE mFldType = "D" .AND. cTIPOSQL = "SQLITE"
            mSql += "DATE NOT NULL DEFAULT ('')"
         CASE mFldType = "D" .AND. ( cTIPOSQL = "ORACLE" .OR. cTIPOSQL = "OCI" ;
                                   .OR. cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" ;
                                   .OR. cTIPOSQL = "FIREBIRD" ;
                                   )   
            mSql += "TIMESTAMP"
         CASE mFldType = "D" .AND. ( cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER"  ;
                                    .OR. cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" ;
                                    .OR. llMDB .OR. llACCDB ;
                                    .OR. cTIPOSQL == "CUBRID" ;
                                    )   
            mSql += "DATETIME"
         CASE mFldType = "D" .AND. cTIPOSQL == "DUCKDB"
            mSql += "DATE" // DuckDB nativo para datas   

        CASE mFldType = "D" .AND. ( cTIPOSQL = "IBMDB2" )
            mSql += "DATE"

         CASE mFldType = "D" .AND. ( cTIPOSQL = "SYBASE" )
            mSql += "DATETIME"

         CASE mFldType = "D" .AND. ( cTIPOSQL = "SQLANY" )
            mSql += "TIMESTAMP"

         CASE mFldType = "D"
            mSql += "DATE"
  
         // Datetime (@)
         CASE mFldType = "@" .AND. ( cTIPOSQL = "ORACLE" .OR. cTIPOSQL = "OCI" ;
                                   .OR. cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" ;
                                   .OR. cTIPOSQL = "FIREBIRD" ;
                                   )   
            mSql += "TIMESTAMP"
         CASE mFldType = "@" .AND. ( cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER" .or. cTIPOSQL = "SQLITE" ;
                                    .OR. cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" ;
                                    .OR. llMDB .OR. llACCDB ;
                                    .OR. cTIPOSQL == "CUBRID" ;
                                    )   
            mSql += "DATETIME"
         CASE mFldType = "@" .AND. cTIPOSQL == "DUCKDB"
            mSql += "TIMESTAMP"    
         CASE mFldType = "@"
             mSql += "TIMESTAMP"
         
         // Time (T)
         CASE mFldType = "T" .AND. ( cTIPOSQL = "ORACLE" .OR. cTIPOSQL = "OCI" ;
                                   .OR. cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" ;
                                   .OR. cTIPOSQL = "FIREBIRD" ;
                                   )   
            mSql += "TIMESTAMP"
         CASE mFldType = "T" .AND. ( cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER" .or. cTIPOSQL = "SQLITE" ;
                                    .OR. cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" ;
                                    .OR. llMDB .OR. llACCDB ;
                                    .OR. cTIPOSQL == "CUBRID" ;
                                    )   
            mSql += "DATETIME"
         CASE mFldType = "T"
             mSql += "DATETIME"
         

         // Numeric (N)
         CASE mFldType = "N" .AND. ( cTIPOSQL = "ORACLE" .OR. cTIPOSQL = "OCI" )
            IF mFldDec > 0
               mSql += "NUMBER(" + hb_ntos( mFldLen ) + "," + hb_ntos( mFldDec ) + ")  DEFAULT 0"
            ELSE
               mSql += "NUMBER(" + hb_ntos( mFldLen ) + ")  DEFAULT 0"
            ENDIF
         CASE mFldType = "N" .AND. cTIPOSQL == "DUCKDB"
             IF mFldDec > 0
                mSql += "DECIMAL(" + hb_ntos(mFldLen) + "," + hb_ntos(mFldDec) + ")" // Ideal para monetários
             ELSE
                mSql += "BIGINT" // Prefira BIGINT para inteiros no DuckDB
             ENDIF   

         CASE mFldType = "N" .AND. ( cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER" ;
                                    .OR. cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" ;
                                    .OR. cTIPOSQL == "CUBRID" )
            IF mFldDec > 0
               mSql += "NUMERIC(" + hb_ntos( mFldLen ) + "," + hb_ntos( mFldDec ) + ")"
            ELSE
               IF mFldLen <= 9
                  IF cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL"
                     mSQL += "INTEGER"
                  ELSE
                     mSql += "INT"  
                  ENDIF
               ELSE
                  mSql += "BIGINT"   
               ENDIF
            ENDIF

         CASE mFldType = "N" .AND. cTIPOSQL = "FIREBIRD"
            IF mFldDec > 0
               mSql += "DECIMAL(" + LTrim( Str( mFldLen ) ) + "," + LTrim( Str( mFldDec ) ) + ")"
            ELSE
               IF mFldLen <= 4
                  mSql += "SMALLINT"
               ELSEIF mFldLen <= 9
                  mSql += "INTEGER"
               ELSE
                  mSql += "BIGINT"
               ENDIF
            ENDIF

         CASE mFldType = "N" .AND. ( llMDB .OR. llACCDB )
            IF mFldDec > 0
               mSql += "DOUBLE DEFAULT 0"
            ELSE
               mSql += "LONG DEFAULT 0"
            ENDIF
            
         CASE mFldType = "N" .AND. cTIPOSQL = "SQLITE"
            IF mFldDec > 0
               mSql += "FLOAT  default 0" 
            ELSE
               mSql += "INTEGER default 0"
            ENDIF
            
            
       CASE mFldType = "N" .AND. ( cTIPOSQL = "IBMDB2" )
            IF mFldDec > 0
               mSql += "DECIMAL(" + hb_ntos( mFldLen ) + "," + hb_ntos( mFldDec ) + ")"
            ELSE
               mSql += "DECIMAL(" + hb_ntos( mFldLen ) + ")"
            ENDIF

         CASE mFldType = "N" .AND. ( cTIPOSQL = "ADABAS" .OR. cTIPOSQL = "SQLANY" )
            mSql += "NUMERIC (" + hb_ntos( mFldLen ) + "," + hb_ntos( mFldDec ) + ")"

         CASE mFldType = "N" .AND. ( cTIPOSQL = "INGRES" )
            mSql += "DECIMAL (" + hb_ntos( mFldLen ) + "," + hb_ntos( mFldDec ) + ")"

         CASE mFldType = "N" .AND. ( cTIPOSQL = "INFORMIX" )
            IF mFldLen > 15
               mSql += "DECIMAL (" + hb_ntos( mFldLen ) + "," + hb_ntos( mFldDec ) + ")"
            else
               mSql += "DECIMAL (" + hb_ntos( mFldLen ) + "," + hb_ntos( mFldDec ) + ")"
            ENDIF     
            

         CASE mFldType = "N" .AND. ( cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" .OR. cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER"  )
            IF mFldDec > 0
               mSql += "NUMERIC(" + hb_ntos( mFldLen ) + "," + hb_ntos( mFldDec ) + ")"
            ELSE
               IF mFldLen <= 9
                  mSql += "INTEGER" // Correção: Removido o (size) que quebrava o MySQL moderno
                  IF cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER"
                      mSql += " default 0"
                  ENDIF
               ELSE
                  mSql += "BIGINT" // Correção: Removido o (size)
               ENDIF
            ENDIF
    
         // Float (F)
         CASE mFldType = "F" .AND. ( llMDB .OR. llACCDB )
            mSql += "DOUBLE"
         CASE mFldType = "F" .AND. cTIPOSQL = "SQLITE"
            mSql += "REAL "
         CASE mFldType = "F" .AND. ( cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" )
            mSql += "FLOAT(" + hb_ntos( mFldLen ) + "," + hb_ntos( mFldDec ) + ")"
         CASE mFldType = "F" .AND. ( cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" )
            mSql += "NUMERIC(" + hb_ntos( mFldLen ) + "," + hb_ntos( mFldDec ) + ")"
         CASE mFldType = "F" .AND. ( cTIPOSQL = "FIREBIRD" )
            mSql += "DECIMAL(" + hb_ntos( mFldLen ) + "," + hb_ntos( mFldDec ) + ")"
         CASE mFldType = "F"
            mSql += "FLOAT "
         CASE mFldType = "" .AND. ( cTIPOSQL = "ORACLE" .OR. cTIPOSQL = "OCI")    
            mSql += "FLOAT ("+ hb_ntos( mFldDec ) + ")  DEFAULT 0"
         
         // Currency (Y)
         CASE mFldType = "Y" .AND. cTIPOSQL = "SQLITE"
            IF mFldDec > 0
               mSql += "NUMERIC(" + hb_ntos( mFldLen ) + "," + hb_ntos( mFldDec ) + ")"
            ELSE
               mSql += "NUMERIC(" + hb_ntos( mFldLen ) + ")"
            ENDIF
         CASE mFldType = "Y" .AND. ( cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" )
            mSql += "NUMERIC(" + hb_ntos( mFldLen ) + "," + hb_ntos( mFldDec ) + ")"
         CASE mFldType = "Y" .AND. ( cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER" )
            mSql += "MONEY "
         CASE mFldType = "Y" .AND. ( cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" .OR. cTIPOSQL = "FIREBIRD" )
            mSql += "DECIMAL(" + hb_ntos( mFldLen ) + "," + hb_ntos( mFldDec ) + ")"
         CASE mFldType = "Y"
            mSql += "FLOAT"
         
         // Integer (I)
         CASE mFldType = "I" .AND. cTIPOSQL = "FIREBIRD"
            mSql += "INTEGER"
         CASE mFldType = "I" .AND. ( llMDB .OR. llACCDB )
            mSql += "LONG DEFAULT 0"
         CASE mFldType = "I" .AND. ( cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" )
            mSql += "INT " 
         CASE mFldType = "I" .AND. ( cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER"  )
            mSql += "INT  default 0"
         CASE mFldType = "I" .AND. ( cTIPOSQL = "SQLITE")          
            mSql += "INTEGER  default 0"
         CASE mFldType = "I" .AND. ( cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" )  
            mSql += "INT  default 0 "
         CASE mFldType = "I" .AND. ( cTIPOSQL = "ORACLE" .OR. cTIPOSQL = "OCI")   
            mSql += "NUMBER(" + hb_ntos( mFldLen ) + ",0)  DEFAULT 0"
        CASE mFldType = "I" .AND. cTIPOSQL == "DUCKDB"
            mSql += "BIGINT"    
         CASE mFldType = "I"
            mSql += "INTEGER"
         
         // Double (B)
         CASE mFldType = "B" .AND. ( cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER" )
            mSql += "FLOAT"
         CASE mFldType = "B" .AND. ( cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" )
            mSql += "DOUBLE(" + hb_ntos( mFldLen ) + "," + hb_ntos( mFldDec ) + ")"
         CASE mFldType = "B" .AND. ( cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" )
            mSql += "NUMERIC(" + hb_ntos( mFldLen ) + "," + hb_ntos( mFldDec ) + ")"
         CASE mFldType = "B" .AND. ( cTIPOSQL = "FIREBIRD" )
            mSql += "DECIMAL(" + hb_ntos( mFldLen ) + "," + hb_ntos( mFldDec ) + ")"
         CASE mFldType = "B"
            mSql += "DOUBLE"

         // Logical (L)
         CASE mFldType = "L" .AND. ( cTIPOSQL = "ORACLE" .OR. cTIPOSQL = "OCI"  )
            mSql += "SMALLINT"
         CASE mFldType = "L" .AND. ( cTIPOSQL == "CUBRID" )
            mSql += "BIT"   
         CASE mFldType = "L" .AND. ( cTIPOSQL = "FIREBIRD" )
            mSql += "SMALLINT DEFAULT 0 NOT NULL"  //BOOLEAN DEFAULT FALSE NOT NULL
         CASE mFldType = "L" .AND. ( cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" .OR. cTIPOSQL = "SQLITE"  )
            mSql += "BOOLEAN"
         CASE mFldType = "L" .AND. ( llMDB .OR. llACCDB .OR. cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER" )
            mSql += "BIT DEFAULT 0"
         CASE mFldType = "L" .AND. cTIPOSQL == "DUCKDB"
            mSql += "BOOLEAN" 
        CASE mFldType = "L" .AND. ( cTIPOSQL = "IBMDB2" )
            mSql += "SMALLINT"

         CASE mFldType = "L" .AND. ( cTIPOSQL = "SYBASE" )
            mSql += "BIT NOT NULL"

         CASE mFldType = "L" .AND. ( cTIPOSQL = "SQLANY" )
            mSql += "NUMERIC (1) NULL"

         CASE mFldType = "L" .AND. ( cTIPOSQL = "INFORMIX" )
            mSql += "BOOLEAN"

         CASE mFldType = "L" .AND. ( cTIPOSQL = "INGRES" )
            mSql += "TINYINT"       
              
         CASE mFldType = "L"
            mSql += "BOOL"

         // Memo (M)
         CASE mFldType = "M" .AND. ( cTIPOSQL = "ORACLE" .OR. cTIPOSQL = "OCI" )
            mSql += "CLOB"
         CASE mFldType = "M" .AND. ( cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER" .OR. cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" )
            mSql += "TEXT"
         CASE mFldType = "M" .AND. ( llMDB .OR. llACCDB )
            mSql += "LONGTEXT"
         CASE mFldType = "M" .AND. ( cTIPOSQL = "FIREBIRD" )
            mSql += "BLOB SUB_TYPE TEXT" 
         CASE mFldType = "M" .AND. cTIPOSQL == "DUCKDB"
            mSql += "VARCHAR" // DuckDB lida com textos grandes eficientemente como VARCHAR   
        CASE mFldType = "M" .AND. ( cTIPOSQL = "IBMDB2" )
            mSql += "CLOB (256000)"

         CASE mFldType = "M" .AND. ( cTIPOSQL = "SQLANY" .OR. cTIPOSQL = "INGRES" )
            mSql += "LONG VARCHAR"

         CASE mFldType = "M" .AND. ( cTIPOSQL = "SYBASE" )
            mSql += "TEXT"

         CASE mFldType = "M" .AND. ( cTIPOSQL = "ADABAS" )
            mSql += "LONG"    
            
         CASE mFldType = "M"
            mSql += "TEXT"

         // Blobs / Binary (G, Q, W, P)
         CASE mFldType = "G" .AND. ( cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" )
            mSql += "BYTEA"
         CASE mFldType = "G" .AND. ( cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER" )
            mSql += "VARBINARY"
         CASE mFldType = "G" .AND. ( llMDB .OR. llACCDB )
            mSql += "LONGBINARY"
         CASE mFldType = "G" .AND. ( cTIPOSQL = "FIREBIRD" )
            mSql += "BLOB SUB_TYPE 0"
         CASE mFldType = "G"
            mSql += "BLOB"
            
         CASE mFldType = "Q" .AND. cTIPOSQL = "SQLITE"
            mSql += "BLOB "
         CASE mFldType = "Q" .AND. ( cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER" .OR. cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" )
            mSql += "VARBINARY(" + hb_ntos( mFldLen ) + ")"
         CASE mFldType = "Q" .AND. ( cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" )
            mSql += "BYTEA"
         CASE mFldType = "Q" .AND. ( cTIPOSQL = "FIREBIRD" )
            mSql += "BLOB SUB_TYPE 0"
            
         CASE mFldType = "W" .AND. ( cTIPOSQL = "SQLITE" .OR. cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" )
            mSql += "BLOB "
         CASE mFldType = "W" .AND. ( cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER" )
            mSql += "IMAGE"
         CASE mFldType = "W" .AND. ( cTIPOSQL = "FIREBIRD" )
            mSql += "BLOB SUB_TYPE 0"
         CASE mFldType = "W" .AND. ( cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" )
            mSql += "BYTEA"     
         CASE mFldType = "W" .AND. ( llMDB .OR. llACCDB )
            mSql += "OLEOBJECT"
            
         CASE mFldType = "P" .AND. ( cTIPOSQL = "SQLITE"  )
            mSql += "BLOB "
         CASE mFldType = "P" .AND. ( cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER"  )
            mSql += "VARBINARY(" + hb_ntos( mFldLen ) + ")"
         CASE mFldType = "P" .AND. ( cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" )
            mSql += "BYTEA" 
         CASE mFldType = "P" .AND. ( cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" )   
            mSql += "BLOB"
         CASE mFldType = "P" .AND. ( llMDB .OR. llACCDB )
            mSql += "OLEOBJECT"
         CASE mFldType = "P" .AND. ( cTIPOSQL = "FIREBIRD")      
            mSql += "BLOB SUB_TYPE 0"
         
         // Rowversion (Z)
         CASE mFldType = "Z" .AND. ( cTIPOSQL = "SQLITE"  )
            mSql += "INTEGER DEFAULT 0"
         CASE mFldType = "Z" .AND. ( cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER"  )
            mSql += "rowversion"
         CASE mFldType = "Z" .AND. ( cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" )   
            mSql += "BIGINT"
         CASE mFldType = "Z" .AND. ( cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" )
            mSql += "BIGINT DEFAULT 0"    
         CASE mFldType = "Z" .AND. ( llMDB .OR. llACCDB )
            mSql += "LONG"  
         CASE mFldType = "Z" .AND. ( cTIPOSQL = "FIREBIRD")
            mSql += "BIGINT DEFAULT 0"  

         OTHERWISE
            alertx( "Invalid Field Type: " + mFldType + " "+ cTIPOSQL )
            RETURN ""
      ENDCASE
   NEXT
   
   mSql += ") ;" + HB_OSNEWLINE()
   IF cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB"
      mSql += "ENGINE=InnoDB DEFAULT CHARSET=latin1;" + HB_OSNEWLINE()
   ENDIF
   //mSql += " ; " + HB_OSNEWLINE()
   IF cTIPOSQL = "FIREBIRD"
      mSql += "GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON " + cTablename + " TO  SYSDBA WITH GRANT OPTION GRANTED BY SYSDBA;" + HB_OSNEWLINE()
   ENDIF
   
   
   // Criação dos Índices Originais do DBF
   IF lINDEX
      msql +=  hb_osNewLine() 
      aINDICES := GeraINDICES()
      nIndexes := LEN(aINDICES)
      FOR j := 1 TO nIndexes
          msql += aINDICES[j,1] + hb_osNewLine()  
       
          IF j = 1 .AND. lPK
             cPKCHAVE := aINDICES[j,6]
             IF !EMPTY(cPKCHAVE)
                mSQL += "ALTER TABLE " + cTablename + " ADD PRIMARY KEY(" + cPKCHAVE + ") ;" + HB_OSNEWLINE()
             ENDIF   
          ENDIF
      NEXT j
   ENDIF
   IF lINCSR
      mSql += " CREATE INDEX IDX_" + cTablename + "_DELETED ON" + cTablename + " (SR_DELETED);" + HB_OSNEWLINE()
      mSql += " CREATE INDEX IDX_" + cTablename + "_RECNO   ON" + cTablename + " (SR_RECNO);"   + HB_OSNEWLINE()
   ENDIF
   IF cTIPOSQL = "SQLITE"
      mSql += "PRAGMA temp_store = MEMORY ; " + HB_OSNEWLINE()//
      mSql += "PRAGMA cache_size = 2000 ; "+ HB_OSNEWLINE() //Aumenta o tamanho do cache (ex: 2000 páginas)
      mSql += "PRAGMA journal_mode = WAL ; " + HB_OSNEWLINE()//Modo WAL (Write-Ahead Logging) - Muito mais rápido para inserções e permite leitura e escrita simultâneas
      mSql += "PRAGMA synchronous = NORMAL ; " + HB_OSNEWLINE() //Reduz a sincronização com o disco (Normal é seguro o suficiente com WAL)
      mSql += "PRAGMA auto_vacuum = INCREMENTAL ; " + HB_OSNEWLINE() //Armazena arquivos temporários na memória em vez de disco
      mSql += "PRAGMA page_size = 4096 ; " + HB_OSNEWLINE()//
      mSql += "PRAGMA mmap_size = 300000000 ; "+ HB_OSNEWLINE()
      mSql += "PRAGMA busy_timeout = 5000 ; "+ HB_OSNEWLINE()
   ENDIF
   
   // SISTEMA AUTOMÁTICO DE TRRIGERS E ÍNDICES PARA MULTI-AUTOINCREMENTOS (MYSQL)
   IF Len(aCAMMYTRIGER) > 0 .AND. ( cTIPOSQL $ "MYSQL|MYSQL64|MARIADB" )
      
      mSql += HB_OSNEWLINE()
      
      // 1. Criar os Índices Únicos para performance de busca por RecNo e outros campos +
      FOR nX := 1 TO Len(aCAMMYTRIGER)
          cCampo := aCAMMYTRIGER[nX]
          cSqlIdx := "ALTER TABLE " + cTablename + " ADD UNIQUE KEY idx_" + cTablename + "_" + cCampo + " (" + cCampo + ");" + HB_OSNEWLINE()
          mSql += cSqlIdx 
      NEXT

      mSql += HB_OSNEWLINE()

      // 2. Criar uma ÚNICA Trigger nativa que processa todos os incrementos necessários
      cSqlTrigger := "CREATE TRIGGER tg_auto_" + cTablename + " BEFORE INSERT ON " + cTablename + HB_OsNewLine()
      cSqlTrigger += "FOR EACH ROW" + HB_OsNewLine()
      cSqlTrigger += "BEGIN" + HB_OsNewLine()

      FOR nX := 1 TO Len(aCAMMYTRIGER)
          cCampo := aCAMMYTRIGER[nX]
          cSqlTrigger += "    IF NEW." + cCampo + " IS NULL OR NEW." + cCampo + " = 0 THEN" + HB_OsNewLine()
          cSqlTrigger += "        SET NEW." + cCampo + " = (SELECT COALESCE(MAX(" + cCampo + "), 0) + 1 FROM " + cTablename + ");" + HB_OsNewLine()
          cSqlTrigger += "    END IF;" + HB_OsNewLine()
      NEXT

      cSqlTrigger += "END;" + HB_OsNewLine()
      
      mSql += cSqlTrigger 
   ENDIF
   
   

RETURN mSql   
   
*+
*+--------------------------------------------------------------------
*+
*+ Function geracampodbf()
*+
*+--------------------------------------------------------------------
*+
 

function geracampodbf(cFieldName, cFieldType, nFieldLength, nFieldDec)

local aRETU
local cSUBTIPO, cTYPE, cTMPSIZE



// Validação original para drivers ADS
IF type("TIPODBF") == "N" .AND. TIPODBF == 6
   RETURN geracampoadt(cFieldName, cFieldType, nFieldLength, nFieldDec)
ENDIF

// Padroniza o nome do campo
cFieldName := AllTrim(cFieldName)

cTYPE    := UPPER(cFieldType) // Evita falhas com minúsculas vindas do banco (ex: "int", "text")
cSUBTIPO := ""

// Trata se vier no formato SQLIMIX (Ex: N:i, C:CU, @:D)
IF SUBSTR(cTYPE, 2, 1) = ":"  
   cFieldType := SUBSTR(cTYPE, 1, 1)
   cSUBTIPO   := SUBSTR(cTYPE, 3)
   cTYPE      := SUBSTR(cTYPE, 1, 1)
ENDIF

do case

  // Ajuste para sub-tipagem SQLIMIX
   CASE cType == "I" .AND. cSUBTIPO == "N"
        cFieldType := 'N' 

   //ja esta tipado C,D,N,M,L
   CASE LEN(cTYPE) =1 
        IF cType == "C" .AND. (nFieldLength=0 .OR. nFieldLength > 250)
           nFieldLength := 250
        ENDIF 

   //
   // numeric(l,d) decimal(l,d) number(l,d) - O tamanho está entre parênteses
   //
   CASE AT("(", cTYPE) > 0 .AND. AT(")", cTYPE) > 0 .AND. AT(",", cTYPE) > 0 .AND. ;
        ( "NUMERIC" $ cTYPE .OR. "DECIMAL" $ cTYPE .OR. "NUMBER" $ cTYPE )
        
        cTMPSIZE     := SUBSTR(cTYPE, AT("(", cTYPE) + 1)
        cTMPSIZE     := SUBSTR(cTMPSIZE, 1, AT(",", cTMPSIZE) - 1)
        nFieldLength := val(cTMPSIZE)
        cTMPSIZE     := SUBSTR(cTYPE, AT(",", cTYPE) + 1)
        cTMPSIZE     := SUBSTR(cTMPSIZE, 1, AT(")", cTMPSIZE) - 1)
        nFieldDec    := val(cTMPSIZE)
        cFieldType   := 'N'

   //
   // tinyint(n) int(n) number(n) - Tamanho inteiro entre parênteses
   //
   CASE AT("(", cTYPE) > 0 .AND. AT(")", cTYPE) > 0 .AND. AT(",", cTYPE) == 0 .AND. ;
        ( "INT" $ cTYPE .OR. "NUMBER" $ cTYPE )
        
        cTMPSIZE     := SUBSTR(cTYPE, AT("(", cTYPE) + 1)
        cTMPSIZE     := SUBSTR(cTMPSIZE, 1, AT(")", cTMPSIZE) - 1)
        nFieldLength := VAL(cTMPSIZE)
        cFieldType   := 'N'
        nFieldDec    := 0

   //
   // varchar(n) char(n) text(n) VARCHAR2(n) bpchar(n) - O tamanho está entre parênteses
   //
   CASE AT("(", cTYPE) > 0 .AND. AT(")", cTYPE) > 0 .AND. ;
        ( "CHAR" $ cTYPE .OR. "TEXT" $ cTYPE .OR. "VARCHAR2" $ cTYPE .OR. "BPCHAR" $ cTYPE )
        
        cTMPSIZE     := SUBSTR(cTYPE, AT("(", cTYPE) + 1)
        cTMPSIZE     := SUBSTR(cTMPSIZE, 1, AT(")", cTMPSIZE) - 1)
        nFieldLength := VAL(cTMPSIZE)
        cFieldType   := 'C'
        nFieldDec    := 0
        
        // Mantém sua lógica: Se estourar o limite de caractere do DBF, trunca no tamanho seguro
        IF nFieldLength=0 .OR. nFieldLength > 250
           nFieldLength := 250
        ENDIF

   // Tipos Inteiros Puros do SQL
   CASE cType == "TINYINT"
        cFieldType   := 'N'
        nFieldLength := 3
        nFieldDec    := 0

   CASE cType $ "INT2|SMALLINT"
        cFieldType   := 'N'
        nFieldLength := 5
        nFieldDec    := 0

   CASE cType $ "INT|MEDIUMINT|INTEGER|INT4|SERIAL"
        cFieldType   := 'N'
        nFieldLength := 10
        nFieldDec    := 0

   CASE cType $ "BIGINT|INT8|BIGSERIAL|OID"
        cFieldType   := 'N'
        nFieldLength := 19
        nFieldDec    := 0

   // Ponto Flutuante e Decimais Genéricos //MUDANDO A Logica entrava aqui quando o tipo era "C"
   CASE cType $ "DOUBLE PRECISION|FLOAT8|DECIMAL" 
        cFieldType   := 'N'
        nFieldLength := 19
        nFieldDec    := 9

   CASE cType == "MONEY"
        cFieldType   := 'N'
        nFieldLength := 14
        nFieldDec    := 2

   CASE cType $ "REAL|FLOAT|DOUBLE|FLOAT4"
        cFieldType   := 'N'
        nFieldLength := 14
        nFieldDec    := 5

   // Datas e Horas
   CASE cType $ "DATE|DATETIME|SHORTDATE|TIMESTAMP|D|TYPE_TIMESTAMP|TYPE_DATE|@"
        cFieldType   := 'D'
        nFieldLength := 8
        nFieldDec    := 0

   // Lógicos
   CASE cType $ "BOOL|BOOLEAN"
        cFieldType   := 'L'
        nFieldLength := 1
        nFieldDec    := 0

   // VOLTANDO À SUA LÓGICA ORIGINAL:
   // Mapeia textos longos para Caracter ('C') limitado a 250 para proteger RDDs com problemas em múltiplos Memos.
   CASE cType $ "CLOB|LONGTEXT|M|WLONGVARCHAR|LONGCHAR|MEMO|LONGVARCHAR"
        cFieldType   := 'C'
        IF nFieldLength=0 .OR. nFieldLength > 250
           nFieldLength := 250
        ENDIF   
        nFieldDec    := 0

   CASE cType == "TEXT" .AND. (cTIPOSQL $ "SQLITE|PGSQL|PGSQL64|POSTGRESQL")
        cFieldType   := 'C'
        IF nFieldLength=0 .OR. nFieldLength > 250
           nFieldLength := 250
        ENDIF   
        nFieldDec    := 0

   // Fallback para instâncias de TEXT puras sem parênteses
   CASE AT("(", cTYPE) == 0 .AND. "TEXT" $ cTYPE
        cFieldType   := 'M'
        nFieldLength := 10
        nFieldDec    := 0

   // Numéricos sem definição de tamanho em parênteses
   CASE AT("(", cTYPE) == 0 .AND. "NUMERIC" $ cTYPE
        cFieldType := 'N'
        IF nFieldLength == 0  
           nFieldLength := 10
           nFieldDec    := 0
        ENDIF

   // Tipos Caracteres sem tamanho específico informado
   CASE cType $ "VARCHAR|BPCHAR|CHARACTER|WVARCHAR|WCHAR"
        cFieldType := 'C'
        IF nFieldLength == 0 .OR. nFieldLength > 250
           nFieldLength := 250 
        ENDIF
        nFieldDec  := 0

   CASE cType == "NAME"
        cFieldType   := 'C'
        nFieldLength := 64
        nFieldDec    := 0

   // Binários / Blobs e Imagens convertidos para Memo padrão
   CASE cType $ "BYTEA|BLOB|IMAGE|VARBINARY"
        cFieldType   := 'M'
        nFieldLength := 10
        nFieldDec    := 0

   // Controle de concorrência / Rowversion do SQL Server
   CASE cType == "ROWVERSION" 
        cFieldType   := 'C'
        nFieldLength := 8
        nFieldDec    := 0   

   otherwise
        // Mantém a estrutura recebida se cair em um tipo desconhecido
        cFieldType   := if(Empty(cFieldType), "C", cFieldType)
        nFieldLength := if(nFieldLength == 0, 10, if(nFieldLength > 250 .AND. cFieldType == "C", 250, nFieldLength))
endcase

// Monta e retorna o array final estruturado para o DBSTRUCT()
aRETU := { cFieldName, cFieldType, nFieldLength, nFieldDec }

return aRETU

/*
tipo ADS,Código/ID,Descrição,Equivalente DBF
VARCHAR,V,String Variável,C
CHAR,C,String Fixa,C
MONEY,Y,Monetário (Exato),N
DOUBLE,O,Ponto Flutuante,N
INTEGER,I,Inteiro 32-bit,N
SHORTINT,S,Inteiro 16-bit,N
AUTOINC,+,Auto-incremento,N
LOGICAL,L,Booleano,L
DATE,D,Data,D
TIMESTAMP,@,Data e Hora,C (ou @)
MEMO,M,Texto Longo,M
BLOB,W,Binário/Objetos,M / W
MODIFIED,X,Timestamp Auto,N/A
RAW,R,Binário Fixo,N/A
*/

/*   subtipos sqlmix
Grupo 'N' (Numéricos)

    N:i ou N:I ? Numeric : Integer. Significa que no Harbour ele é tratado como Numérico (Array de estrutura), mas no banco SQL ele deve ser mapeado como um INTEGER puro (sem decimais, ocupando menos espaço e processando mais rápido que um NUMERIC/DECIMAL).

    N:+ ou N:A ? Numeric : Auto-increment / Serial. Indica que o campo numérico é a chave auto-incrementada da tabela (como o SERIAL do Postgres ou INT AUTO_INCREMENT do MySQL).

    N:s ? Numeric : Smallint. Mapeia para inteiros curtos de 2 bytes.

Grupo 'C' (Caracteres)

    C:CU ? Character : Code/Unicode (ou Custom/Upper). Geralmente usado para indicar que o campo armazena strings textuais texturizadas ou que possui tratamento de Collation específico (como UTF8 ou CASE INSENSITIVE) no banco de dados, ou que armazena dados binários convertidos.

    C:V ? Character : Varchar. Diferencia um campo CHAR (tamanho fixo, completa com espaços) de um VARCHAR (tamanho variável) no banco de dados.

Grupo '@' ou 'D' (Datas e Horas)

    @:D ou D:T ? Date/TimeStamp : DateTime. O Harbour nativo (DBF) usa o tipo D apenas para data (AAAA-MM-DD). O subtipo avisa ao driver SQLMIX para buscar ou gravar também a hora, minuto e segundo (DATETIME ou TIMESTAMP no SQL).
*/
*+--------------------------------------------------------------------
*+
*+ Function GERACAMPOADT()
*+
*+--------------------------------------------------------------------
FUNCTION GERACAMPOADT(cFieldName, cSqlType, nFieldLength, nFieldDec)

   LOCAL aRetu
   LOCAL cType    := UPPER(AllTrim(cSqlType)) // Padroniza em caixa alta para evitar falhas de case
   LOCAL cSUBTIPO := ""
   LOCAL cTmpSize, cSubSize

   // Garante inicializações seguras de tamanho caso venham zeradas
   nFieldLength := If(ValType(nFieldLength) <> "N", 0, nFieldLength)
   nFieldDec    := If(ValType(nFieldDec) <> "N", 0, nFieldDec)
   cFieldName   := AllTrim(cFieldName)

   // TRATAMENTO EXCLUSIVO SQLIMIX (Ex: N:i, C:CU, @:D)
   IF SUBSTR(cType, 2, 1) == ":"  
      cSUBTIPO := SUBSTR(cType, 3)
      cType    := SUBSTR(cType, 1, 1)
   ENDIF

   // 1. EXTRAÇÃO DE TAMANHO: Tipos com Tamanho entre Parênteses Ex: VARCHAR(50) ou NUMERIC(10,2)
   IF AT("(", cType) > 0 .AND. AT(")", cType) > 0
      cTmpSize := SUBSTR(cType, AT("(", cType) + 1)
      cTmpSize := SUBSTR(cTmpSize, 1, AT(")", cTmpSize) - 1)
      
      IF AT(",", cTmpSize) > 0 // Caso de decimais como (10,2)
         nFieldLength := VAL(SUBSTR(cTmpSize, 1, AT(",", cTmpSize) - 1))
         nFieldDec    := VAL(SUBSTR(cTmpSize, AT(",", cTmpSize) + 1))
         
         // Se for um tipo numérico explicitado com tamanho
         IF "NUMERIC" $ cType .OR. "DECIMAL" $ cType .OR. "NUMBER" $ cType
            RETURN {cFieldName, "N", nFieldLength, nFieldDec}
         ENDIF
      ELSE // Caso de tamanho único como (50)
         nFieldLength := VAL(cTmpSize)
         
         IF "CHAR" $ cType .OR. "TEXT" $ cType .OR. "VARCHAR" $ cType .OR. "BPCHAR" $ cType
            // Na ADT, campos caracter normais podem ter até 255 posições. Acima disso, usamos Memo.
            IF nFieldLength > 255
               RETURN {cFieldName, "M", 10, 0}
            ELSE
               RETURN {cFieldName, "C", nFieldLength, 0}
            ENDIF
         ELSEIF "INT" $ cType .OR. "NUMBER" $ cType
            RETURN {cFieldName, "N", nFieldLength, 0}
         ENDIF
      ENDIF
   ENDIF

   // 2. CASES ESPECÍFICOS: Avaliação de tipos sem restrição por parênteses
   DO CASE
   
     // Ajuste para sub-tipagem SQLIMIX
     CASE cType == "I" .AND. cSUBTIPO == "N"
            cFieldType := 'N' 

    //ja esta tipado C,D,N,M,L
    CASE LEN(cTYPE) =1 
        IF cType == "C" .AND. (nFieldLength=0 .OR. nFieldLength > 250)
           nFieldLength := 250
        ENDIF 
      
      // Numéricos Inteiros (Mapeados para tamanhos compatíveis na ADT)
      CASE cType == "TINYINT"
           RETURN {cFieldName, "N", 3, 0}

      CASE cType $ "INT2|SMALLINT"
           RETURN {cFieldName, "N", 5, 0}

      CASE cType $ "INT|MEDIUMINT|INTEGER|INT4"
           RETURN {cFieldName, "N", 10, 0}

      CASE cType $ "BIGINT|INT8|BIGSERIAL|OID"
           RETURN {cFieldName, "N", 19, 0}
      
      // Auto-incrementos nativos da ADT
      CASE cType $ "SERIAL|IDENTITY|+"
           RETURN {cFieldName, "+", 10, 0}
      
      // Reais e Ponto Flutuante
      CASE cType $ "DOUBLE PRECISION|FLOAT8|DECIMAL"
           RETURN {cFieldName, "N", 19, 9}

      CASE cType $ "REAL|FLOAT|DOUBLE|FLOAT4"
           RETURN {cFieldName, "N", 14, 5}

      CASE cType == "MONEY"
           RETURN {cFieldName, "N", 14, 2}
      
      // Datas, Horas e Timestamps -> ADT suporta o tipo nativo '@' (TimeStamp)
      CASE cType $ "DATE|DATETIME|SHORTDATE|TIMESTAMP|D|TYPE_TIMESTAMP|TYPE_DATE|@"
           RETURN {cFieldName, "@", 8, 0}
      
      // Lógicos
      CASE cType $ "BOOL|BOOLEAN"
           RETURN {cFieldName, "L", 1, 0}
      
      // Memo e Textos Longos (Aproveitando que a ADT aceita múltiplos campos Memos sem problemas)
      CASE cType $ "CLOB|TEXT|LONGTEXT|M|WLONGVARCHAR"
           RETURN {cFieldName, "M", 10, 0}
      
      // Imagens e Objetos Binários Grandes (Blobs) -> Mapeia para tipo 'P' (Picture/Blob) ou 'W'
      CASE cType $ "BYTEA|BLOB|IMAGE|VARBINARY"
           RETURN {cFieldName, "P", If(nFieldLength == 0, 10, nFieldLength), 0}
      
      // Tipos específicos/exclusivos do ecossistema ADS/ADT
      CASE cType == "ROWVERSION"
           RETURN {cFieldName, "Z", 8, 0}

      CASE cType == "W"
           RETURN {cFieldName, "W", If(nFieldLength == 0, 10, nFieldLength), 0}
      
      // Tratamento genérico de strings sem parênteses (Varchar, Character, etc.)
      CASE cType $ "VARCHAR|BPCHAR|WVARCHAR|WCHAR|NAME" .OR. "CHARACTER" $ cType
           nFieldLength := If(nFieldLength == 0, 250, nFieldLength)
           IF nFieldLength > 255
              RETURN {cFieldName, "M", 10, 0}
           ENDIF
           RETURN {cFieldName, "C", nFieldLength, 0}

      // Fallbacks herdados da lógica original e do tratamento SQLIMIX
      CASE cType == "C" .AND. nFieldLength > 255
           RETURN {cFieldName, "M", 10, 0}

      CASE cType == "I" .AND. cSUBTIPO == "N"
           RETURN {cFieldName, "N", 10, 0}

      OTHERWISE
           // Retorno padrão seguro se cair em um tipo desconhecido
           nFieldLength := If(nFieldLength == 0, 10, nFieldLength)
           RETURN {cFieldName, "C", nFieldLength, 0}

   ENDCASE

RETURN aRetu

FUNCTION GeradbfSchema( cTablename, aStruct )
LOCAL aRETU
LOCAL       mFldNm   
LOCAL       mFldType 
LOCAL       mFldLen  
LOCAL       mFldDec 
LOCAL       i
LOCAL       mSql
LOCAL       nIsNullable
LOCAL       cVisualPic

aRETU:={}
IF ValType( cTablename ) <> "C"
   cTablename := Alias()
ENDIF
IF ValType( aStruct) <> "A"
   aStruct := DBSTRUCT()
ENDIF
FOR i := 1 TO Len( aStruct )
   mFldNm   := aStruct[ i, 1 ]
   mFldType := aStruct[ i, 2 ]
   mFldLen  := aStruct[ i, 3 ]
   mFldDec  := aStruct[ i, 4 ]

   // Monta uma máscara visual padrão baseada nas características do campo DBF
   // Dentro do loop de gravação de dados de campos (aSTRU):
   nIsNullable := 1 //1 pois a tag isnulllable quando permite null e o padrao 1
   cVisualPic  := ""

   DO CASE
   CASE mFldType == "+"
      nIsNullable := 0 // Auto-incremento nunca é nulo
      cVisualPic  := "99999999"
      
   CASE mFldType == "I" // Inteiro nativo do ADS
      cVisualPic  := Replicate("9", mFldLen)
      
   CASE mFldType == "T" // Time/Timestamp do ADS
      cVisualPic  := "99/99/9999 99:99:99"
      
   CASE mFldType == "D"
      cVisualPic  := "99/99/9999"
      
   CASE mFldType == "L"
      cVisualPic  := "Y"
   ENDCASE

   // Monta o INSERT alimentando a nova estrutura de metadados estendida
   msql := "INSERT INTO table_metadata (nome_tabela, column_name, original_type, tamanho, precisao, is_nullable, field_visual_picture) VALUES (" + ;
           c2sql(cTablename)   + ", " + ;
           c2sql(mFldNm)       + ", " + ;
           c2sql(mFldType)     + ", " + ;
           LTrim(Str(mFldLen)) + ", " + ;
           LTrim(Str(mFldDec)) + ", " + ;
           LTrim(Str(nIsNullable)) + ", " + ; // Salva 0 ou 1
           c2sql(cVisualPic)   + ")"          // Salva a máscara padrão gerada
   aadd(aretu,msql)
NEXT
reTURN aRETU

// AJUSTE: Passamos cTablename e cTIPOSQL como parâmetros para a função
FUNCTION GeraINDICES( cTablename )
LOCAL aDUPLA
LOCAL j, nIndexes, cINDEXNAME, cKey, lIsUnique, cFilter, cSqlExpr, msql, msqlMETA
LOCAL llMDB, llACCDB

aDUPLA:={}


IF ValType( cTablename ) <> "C"
   cTablename := Alias()
ENDIF

// Ajusta caixa alta para o Postgres
IF cTIPOSQL $ "PGSQL|PGSQL64|POSTGRESQL"  
   cTablename := Upper( cTablename )
ENDIF

llMDB  := ( cTIPOSQL $ "MDB|ACCESS|MDB64|ACCESS64" )
llACCDB := ( cTIPOSQL $ "ACCDB|ACCDB64" )

nIndexes := dbORDERINFO(DBOI_ORDERCOUNT)

FOR j := 1 TO nIndexes
   // Inicialização correta dos tipos de variáveis a cada iteração
   cINDEXNAME := ""
   cKey       := ""
   lIsUnique  := .F.  
   cFilter    := ""   
   
   // Tenta ler o Nome do Índice
   TRY
      cINDEXNAME := dbORDERINFO(DBOI_NAME,,j)
   CATCH
      cINDEXNAME := "" 
   END   
   
   cINDEXNAME := AllTrim(cINDEXNAME)
   
   // Se a RDD não retornou um nome válido, usa o fallback sequencial
   IF Empty( cINDEXNAME )
      cINDEXNAME :=  AllTrim(cTablename) + "_" + AllTrim(Str(j))
   ELSE
      // Ajuste de escopo global de nomes de índice
      IF cTIPOSQL $ "SQLITE|PGSQL|PGSQL64|POSTGRESQL"
         cINDEXNAME :=  AllTrim(cTablename) + "_" + cINDEXNAME
      ELSE
         cINDEXNAME :=   cINDEXNAME 
      ENDIF
   ENDIF   
   IF cTIPOSQL<>"DBF" .AND. ! EMPTY(cTIPOSQL)
      cINDEXNAME := "IDX_"+cINDEXNAME 
   ENDIF

   // Trata caracteres inválidos no nome final gerado
   cINDEXNAME := StrTran(cINDEXNAME, "-", "_") 
   cINDEXNAME := StrTran(cINDEXNAME, " ", "_")
   
   // Tenta ler a Expressão da Chave
   TRY
      cKey := dbOrderInfo( DBOI_EXPRESSION, , j )
   CATCH
      cKey := ""
   END
   
   // Tenta ler a propriedade de Unicidade
   TRY  
      lIsUnique := dbOrderInfo( DBOI_UNIQUE, , j )
   CATCH
      lIsUnique := .F. 
   END
   
   // Tenta ler a Condição de Filtro (O comando FOR do índice)
   TRY  
      cFilter := dbOrderInfo( DBOI_CONDITION, , j ) 
   CATCH
      cFilter := "" 
   END  
   
   // Só processa e grava se a RDD conseguir extrair uma expressão de chave válida
   IF .NOT. Empty( cKey )
      
      // Transforma a chave Harbour em colunas SQL separadas por vírgula
      cSqlExpr := MDPCHAVEI( cKey ) 
      
      // SOLUÇÃO PARA O PROBLEMA DO "IF NOT EXISTS" NO INDEX:
      IF cTIPOSQL $ "SQLITE|PGSQL|PGSQL64|POSTGRESQL"
         // Bancos que SUPORTAM o Not Exists no índice
         msql := "CREATE " + iif(lIsUnique, "UNIQUE ", "") + "INDEX IF NOT EXISTS " + cINDEXNAME + " ON " + cTablename + " ( " + cSqlExpr + " ) ;"
      ELSE
         // Bancos corporativos (MySQL, SQLServer, Firebird, Oracle) que NÃO SUPORTAM o Not Exists
         msql := "CREATE " + iif(lIsUnique, "UNIQUE ", "") + "INDEX " + cINDEXNAME + " ON " + cTablename + " ( " + cSqlExpr + " ) ;"
      ENDIF
      
      // Monta o INSERT alimentando a estrutura de metadados
      msqlMETA := "INSERT INTO index_metadata (nome_tabela, index_name, expression, sql_expression, filter_expression, is_unique, is_bag) VALUES (" + ;
                  c2sql(cTablename) + ", " + ;
                  c2sql(cINDEXNAME) + ", " + ; 
                  c2sql(cKey)       + ", " + ; 
                  c2sql(cSqlExpr)   + ", " + ; 
                  c2sql(cFilter)    + ", " + ; 
                  iif( lIsUnique, "1", "0" ) + ", " + ; 
                  "1);"                                 
                    
                        
      AADD(aDUPLA,{msql,msqlmeta,cTablename,cINDEXNAME,cKey,cSqlExpr,cFilter,lIsUnique})       
   ENDIF 
NEXT j

RETURN aDUPLA


FUNCTION DIALETO_DetectTargetDb(cTargetDB)

   LOCAL cSystemID := ""
   LOCAL aVers

   cSystemID := ""
   
   cTargetDB:=UPPER(cTargetDB)

   DO CASE
   CASE "ORACLE" $ cTargetDB
      cSystemID := "ORACLE"                 //SQLRDD_RDBMS_ORACLE
//   CASE ("MICROSOFT" $ cTargetDB .AND. "SQL" $ cTargetDB .AND. "SERVER" $ cTargetDB .AND.("10.25" $ ::cSystemVers))
//      cSystemID := "AZURE"                   //SQLRDD_RDBMS_AZURE
//   CASE "MICROSOFT" $ cTargetDB .AND. "SQL" $ cTargetDB .AND. "SERVER" $ cTargetDB .AND. "6.5" $ ::cSystemVers
//      cSystemID := "MSSQL6"                   //SQLRDD_RDBMS_MSSQL6
   CASE "SQL Server" $ cTargetDB                //.AND. "00.53.0000" $ ::cSystemVers) .OR. ("MICROSOFT SQL SERVER" $ cTargetDB)
      cSystemID := "MSSQL"                           //SQLRDD_RDBMS_MSSQL7
//      aVers := hb_atokens(::cSystemVers, '.')
//      IF Val(aVers[1]) >= 8
//         ::lClustered := .T.
//      ENDIF
//         //culik 30/12/2011 adicionado para indicar se e  sqlserver versao 2008 ou superior
//      IF Val(aVers[1]) >= 10
//         ::lSqlServer2008 := .T.
//      ENDIF
//   CASE ("MICROSOFT" $ cTargetDB .AND. "SQL" $ cTargetDB .AND. "SERVER" $ cTargetDB .AND.("7.0" $ ::cSystemVers .OR. "8.0" $ ::cSystemVers .OR. "9.0" $ ::cSystemVers .OR. "10.00" $ ::cSystemVers .OR. "10.50" $ ::cSystemVers .OR. "11.00" $ ::cSystemVers))
//      cSystemID := SQLRDD_RDBMS_MSSQL7
//      aVers := hb_atokens(::cSystemVers, '.')
//      IF Val(aVers[1]) >= 8
//         ::lClustered := .T.
//      ENDIF
   CASE "SQLITE" $ cTargetDB
      cSystemID := "SQLITE" //SQLRDD_RDBMS_SQLANY   
   CASE "FOXPRO" $ cTargetDB
      cSystemID := "FOXPRO" //SQLRDD_RDBMS_SQLANY       
   CASE "ANYWHERE" $ cTargetDB
      cSystemID := "ANYWHERE" //SQLRDD_RDBMS_SQLANY
   CASE "SYBASE" $ cTargetDB .OR. "SQL SERVER" $ cTargetDB
      cSystemID := "SYBASE" //SQLRDD_RDBMS_SYBASE
   CASE "ACCESS" $ cTargetDB
      cSystemID := "ACCESS" //SQLRDD_RDBMS_ACCESS
   CASE "INGRES" $ cTargetDB
      cSystemID := "INGRES" //SQLRDD_RDBMS_INGRES
   CASE "SQLBASE" $ cTargetDB
      cSystemID := "SQLBASE" //SQLRDD_RDBMS_SQLBAS
   CASE "INFORMIX" $ cTargetDB
      cSystemID := "INFORMIX" //SQLRDD_RDBMS_INFORM
   CASE "ADABAS" $ cTargetDB
      cSystemID := "ADABAS" //SQLRDD_RDBMS_ADABAS
      //::lComments := .F.
   CASE "POSTGRESQL" $ cTargetDB
      cSystemID :=  "POSTGRESQL" //SQLRDD_RDBMS_POSTGR
   CASE "DB2" $ cTargetDB .OR. "SQLDS/VM" $ cTargetDB
      cSystemID := "DB2" //SQLRDD_RDBMS_IBMDB2
      //::lComments := .F.
      //IF "05.03" $ ::cSystemVers       // Detects AS/400 from Win98 ODBC
      //   ::cSystemName := "DB2/400"
      //   cTargetDB := "DB2/400"
      //ENDIF
   CASE "MYSQL" $ cTargetDB //.AND. SubStr(AllTrim(::cSystemVers), 1, 3) >= "4.1"
      cSystemID := "MYSQL" //SQLRDD_RDBMS_MYSQL
   CASE "MARIADB" $ cTargetDB
      cSystemID := "MARIADB" //SQLRDD_RDBMS_MARIADB
   CASE "FIREBIRD" $ cTargetDb .OR. "INTERBASE" $ cTargetdb
      cSystemID := "FIREBIRD" //SQLRDD_RDBMS_FIREBR
      //aVers := hb_atokens(::cSystemVers, '.')
      //IF Val(aVers[1]) >= 5
      //   cSystemID := SQLRDD_RDBMS_FIREBR5
      //ELSEIF Val(aVers[1]) >= 4
      //   cSystemID := SQLRDD_RDBMS_FIREBR4
      //ELSEIF Val(aVers[1]) >= 3
      //   cSystemID := SQLRDD_RDBMS_FIREBR3
      //ENDIF
   CASE "INTERSYSTEMS CACHE" $ cTargetDb
      cSystemID := "CACHE" //"INTERSYSTEMS CACHE"  //SQLRDD_RDBMS_CACHE
      //::lComments := .F.
   CASE "OTERRO" $ cTargetDb
      cSystemID := "OTERRO" //SQLRDD_RDBMS_OTERRO
      //::lComments := .F.
   CASE "PERVASIVE" $ cTargetDb  //"PERVASIVE.SQL"
      cSystemID := "PERVASIVE" //SQLRDD_RDBMS_PERVASIVE
      //::lComments := .F.
   CASE "CUBRID" $ cTargetDB
      cSystemID := "CUBRID" //SQLRDD_RDBMS_CUBRID
   CASE "DUCKDB" $ cTargetDB
       cSystemID := "DUCKDB"   
   OTHERWISE
   ENDCASE


RETURN cSystemID


FUNCTION DIALETO_Estrutura(cTargetDB,cTABELA,cUsuario)
LOCAL cCOMANDO
LOCAL cSchema
LOCAL cSchemaSQL
LOCAL cUserOracle
cCOMANDO:=""
cSchema:=""
cSchemaSQL:=""
cUserOracle:=""


DO CASE
   CASE cTargerdb="INFORMIX"   
      cCOMANDO := "select t.tabname,c.colname AS FIELD_NAME,c.coltype AS FIELD_NAME,c.collength AS FIELD_LEN,c.colno " + ;
            "from systables t,syscolumns c " + ;
            "where t.tabid > 0 " + ;
            "and t.tabid = c.tabid " + ;
            "order by 1,5 " 
  
   CASE cTargerdb == "SQLITE" 
      // PRAGMA table_info retorna: cid, name, type, notnull, dflt_value, pk
      // Como o SQLite não aceita aliases em PRAGMAs diretamente, a sua camada de dados
      // deverá ler os campos nativos do pragma ("name", "type") ou usamos uma query vazia de metadados:
      cCOMANDO := "SELECT name AS FIELD_NAME, type AS DATA_TYPE, 0 AS FIELD_LEN, 0 AS FIELD_DEC FROM pragma_table_info('" + cTabela + "');"

   CASE cTargerdb == "MYSQL" .OR. cTargerdb == "MYSQL64" .OR. cTargerdb == "MARIADB"
      // Em vez de SHOW COLUMNS (que gera colunas dinâmicas), usamos a information_schema para fixar os aliases
      if Empty( cUsuario )
         cCOMANDO := "SELECT COLUMN_NAME AS FIELD_NAME, DATA_TYPE AS DATA_TYPE, " + ;
                     "COALESCE(CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION) AS FIELD_LEN, " + ;
                     "COALESCE(NUMERIC_SCALE, 0) AS FIELD_DEC " + ;
                     "FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '" + cTabela + "' AND TABLE_SCHEMA = DATABASE() ORDER BY ORDINAL_POSITION;"
      else
         cCOMANDO := "SELECT COLUMN_NAME AS FIELD_NAME, DATA_TYPE AS DATA_TYPE, " + ;
                     "COALESCE(CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION) AS FIELD_LEN, " + ;
                     "COALESCE(NUMERIC_SCALE, 0) AS FIELD_DEC " + ;
                     "FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '" + cTabela + "' AND TABLE_SCHEMA = '" + cUsuario + "' ORDER BY ORDINAL_POSITION;"
      endif

   CASE cTargerdb == "PGSQL" .OR. cTargerdb == "PGSQL64" .OR. cTargerdb == "POSTGRESQL"
      // PostgreSQL diferencia maiúsculas de minúsculas. Geralmente tabelas ficam em minúsculo no Postgres.
      // udt_name ou data_type mapeados perfeitamente
       //nome tabela em maiusculo postgresql e case sensitive
      //udt_name melhor retorno mas tambem tras data_type caso necesario
      //where table_schema='public'  tras todas as tabelas do usurio(public)
   
      
      cSchema := iif( Empty(cUsuario), "public", cUsuario )
      cCOMANDO := "SELECT column_name AS FIELD_NAME, udt_name AS DATA_TYPE, " + ;
                  "COALESCE(character_maximum_length, numeric_precision) AS FIELD_LEN, " + ;
                  "COALESCE(numeric_scale, 0) AS FIELD_DEC " + ;
                  "FROM information_schema.columns " + ;
                  "WHERE LOWER(table_name) = '" + Lower(cTabela) + "' AND table_schema = '" + cSchema + "' " + ;
                  "ORDER BY ordinal_position;"

   CASE cTargerdb == "MSSQL" .OR. cTargerdb == "SQLSERVER"
      cSchemaSQL := iif( Empty(cUsuario), "dbo", cUsuario )
      cCOMANDO := "SELECT COLUMN_NAME AS FIELD_NAME, DATA_TYPE AS DATA_TYPE, " + ;
                  "ISNULL(CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION) AS FIELD_LEN, " + ;
                  "ISNULL(NUMERIC_SCALE, 0) AS FIELD_DEC " + ;
                  "FROM INFORMATION_SCHEMA.COLUMNS " + ;
                  "WHERE TABLE_NAME = '" + cTabela + "' AND TABLE_SCHEMA = '" + cSchemaSQL + "' " + ;
                  "ORDER BY ORDINAL_POSITION;"
  CASE cTargerdb == "DUCKDB"
     cSchemaSQL := iif( Empty(cUsuario), "main", Lower(cUsuario) )
     cCOMANDO := "SELECT column_name AS FIELD_NAME, data_type AS DATA_TYPE, " + ;
                 "column_size AS FIELD_LEN, decimal_digits AS FIELD_DEC " + ;
                 "FROM duckdb_columns " + ;
                 "WHERE table_name = '" + cTabela + "' AND schema_name = '" + cSchemaSQL + "' " + ;
                 "ORDER BY column_index;"
   CASE cTargerdb == "ORACLE" .OR. cTargerdb == "OCI"
      cUserOracle := iif( Empty(cUsuario), "USER_TAB_COLUMNS", "ALL_TAB_COLUMNS" )
      cCOMANDO := "SELECT COLUMN_NAME AS FIELD_NAME, DATA_TYPE AS DATA_TYPE, " + ;
                  "DATA_LENGTH AS FIELD_LEN, COALESCE(DATA_SCALE, 0) AS FIELD_DEC " + ;
                  "FROM " + cUserOracle + " WHERE TABLE_NAME = '" + Upper(cTabela) + "' " + ;
                  iif( !Empty(cUsuario), "AND OWNER = '" + Upper(cUsuario) + "' ", "" ) + ;
                  "ORDER BY COLUMN_ID;"

   CASE cTargerdb == "FIREBIRD"
      // O Firebird exige um JOIN complexo no catálogo do sistema para extrair os tipos amigáveis
      cCOMANDO := "SELECT TRIM(F.RDB$FIELD_NAME) AS FIELD_NAME, " + ;
                  "CASE T.RDB$FIELD_TYPE " + ;
                  "  WHEN 7 THEN 'SMALLINT' WHEN 8 THEN 'INTEGER' WHEN 16 THEN 'BIGINT' " + ;
                  "  WHEN 10 THEN 'FLOAT' WHEN 27 THEN 'DOUBLE PRECISION' " + ;
                  "  WHEN 14 THEN 'CHAR' WHEN 37 THEN 'VARCHAR' WHEN 40 THEN 'CSTRING' " + ;
                  "  WHEN 12 THEN 'DATE' WHEN 13 THEN 'TIME' WHEN 35 THEN 'TIMESTAMP' " + ;
                  "  WHEN 261 THEN 'BLOB' END AS DATA_TYPE, " + ;
                  "T.RDB$FIELD_LENGTH AS FIELD_LEN, COALESCE(T.RDB$FIELD_SCALE, 0) * -1 AS FIELD_DEC " + ;
                  "FROM RDB$RELATION_FIELDS F " + ;
                  "JOIN RDB$FIELDS T ON F.RDB$FIELD_SOURCE = T.RDB$FIELD_NAME " + ;
                  "WHERE F.RDB$RELATION_NAME = '" + Upper(cTabela) + "' " + ;
                  "ORDER BY F.RDB$FIELD_POSITION;"
ENDCASE
RETURN cCOMANDO

// + EOF: dbudialeto.prg
// +
