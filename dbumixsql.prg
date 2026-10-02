#include "dbinfo.ch"
#include "hbclass.ch"
#include "try.ch"



REQUEST SQLMIX
REQUEST SDDODBC
REQUEST SDDSQLITE3


#ifdef USE_SDD_MYSQL
    REQUEST SDDMY
#endif     

#ifdef USE_SDD_POSTGRES  
    REQUEST SDDPG
#endif 

#ifdef USE_SDD_FIREBIRD
    REQUEST SDDFB
#endif     

#ifdef USE_SDD_ORACLE
  REQUEST SDDOCI
#endif 


*---------------------------------------------------------------------------------------------*
CLASS SQLMIXEXT
*---------------------------------------------------------------------------------------------*
/*
 *  SQL Class Definition
 *  This class provides an interface for interacting with SQL databases using the SQLMIX RDD.
 */

   // Data:

   DATA lShowMsgs    // Flag to control the display of messages during SQL operations.
   DATA lTrace       // Flag to enable or disable tracing of SQL commands to a log file.
   DATA cMsgLang     // Stores the language code for messages (e.g., 'EN' for English, 'ES' for Spanish).
   DATA cNoQuoteChar // Character used to indicate that a string should not be quoted in SQL commands.

   DATA lError EXPORTED READONLY     // Read-only flag indicating whether an error occurred during the last SQL operation.
   DATA cErrorDesc EXPORTED READONLY // Read-only string containing the description of the last error.

   DATA aMsgs HIDDEN              // Hidden array storing messages for different languages.
   DATA cCommandBuffer HIDDEN     // Hidden string buffer used to build SQL commands.
   DATA cCommandWhere HIDDEN      // Hidden string used to store the WHERE clause for SQL commands.
   DATA nConnHandle HIDDEN        // Hidden numeric handle for the database connection.
   DATA cMessageWindowName HIDDEN // Hidden string containing the name of the message window.
   DATA aWorkAreas HIDDEN         // Hidden array storing the work areas used by the class.
   
   
   DATA cTipoMix     // Tipo/Driver do banco (ex: MYSQL, POSTGRESQL, SQLITE, FIREBIRD, ODBC, etc.)
   DATA cPorta       // Porta do servidor (opcional)
   DATA cOwner       // Schema/Owner (usado no PostgreSQL, etc.)

   // Methods:

   METHOD New()                           // Constructor: Initializes the SQL class instance.
   METHOD Connect( cServer, cUser, cPassword, cDatabase ) // Establishes a connection to the SQL database.
   METHOD Select( cCommand, cWorkArea )   // Executes a SELECT SQL command and opens a work area.
   METHOD Insert( cTable, aHash )         // Executes an INSERT SQL command using data from a hash.
   METHOD Update( cTable, cWhere, aHash ) // Executes an UPDATE SQL command using data from a hash and a WHERE clause.
   METHOD Delete( cTable, cWhere )        // Executes a DELETE SQL command with a WHERE clause.
   METHOD Exec( cCommand )                // Executes the SQL command stored in the command buffer.
   METHOD AffectedRows()                  // Returns the number of rows affected by the last SQL command.
   METHOD Disconnect()                    // Closes the database connection.
   METHOD CloseAreas()                    // Closes all open work areas used by the class.
   METHOD Destroy()                       // Destructor: Cleans up resources used by the SQL class instance.
   METHOD LastInsertID()
   
   /*
   METHOD BeginTrans()
   METHOD CommitTrans()
   METHOD RollbackTrans()
   */

   METHOD Field( cField, xExpression ) HIDDEN // Hidden method to format a field and its value for SQL commands.

ENDCLASS

*---------------------------------------------------------------------------------------------*
METHOD SQLMIXEXT:New()
*---------------------------------------------------------------------------------------------*
/*
 * SQLMIXEXT:New()
 *
 * Constructor for the SQL class.
 *
 * Initializes the class properties, sets default values, and defines the message window.
 * It determines the language to use for messages based on the system's language setting.
 *
 * Parameters:
 *   None
 *
 * Returns:
 *   Self (the SQL object)
 */

   ::cMsgLang := Upper( Left( Set ( _SET_LANGUAGE ), 2 ) )
   ::aMsgs := {}
   ::aWorkAreas := {}
   ::cCommandBuffer := ''
   ::cCommandWhere := ''
   ::nConnHandle := 0
   ::lError := .F.
   ::cErrorDesc := ''
   ::lShowMsgs := .T.
   ::cMessageWindowName := '_MIXSQL_'
   ::lTrace := .F.
   ::cNoQuoteChar := '@'

   ::aMsgs := ASize( ::aMsgs, 14 )
   
   
   ::cTipoMix := 'ODBC'
   ::cPorta := ''
   ::cOwner := ''

   IF ::cMsgLang = 'EN' // English EN

      ::aMsgs[ 1 ] := 'SQL: Connecting...'
      ::aMsgs[ 2 ] := 'Connection Error!'
      ::aMsgs[ 3 ] := 'SQL: Processing...'
      ::aMsgs[ 4 ] := 'INSERT/UPDATE Column Data Type Error'
      ::aMsgs[ 5 ] := 'INSERT cTable Param Type Error'
      ::aMsgs[ 6 ] := 'INSERT aHash Param Type Error'
      ::aMsgs[ 7 ] := 'DELETE cTable Param Type Error'
      ::aMsgs[ 8 ] := 'DELETE cWhere Param Type Error'
      ::aMsgs[ 9 ] := 'UPDATE cTable Param Type Error'
      ::aMsgs[ 10 ] := 'UPDATE cWhere Param Type Error'
      ::aMsgs[ 11 ] := 'UPDATE aHash Param Type Error'
      ::aMsgs[ 12 ] := 'EXEC Undefined Error'
      ::aMsgs[ 13 ] := 'SQL ERROR'
      ::aMsgs[ 14 ] := 'ShowMessage() Param Type Error'


   ELSEIF ::cMsgLang = 'PT' // Portuguese PT

      ::aMsgs[ 1 ] := 'SQL: Conectando...'
      ::aMsgs[ 2 ] := 'Erro de conex�o!'
      ::aMsgs[ 3 ] := 'SQL: Processando...'
      ::aMsgs[ 4 ] := 'Erro de tipo de dados da coluna INSERT/UPDATE'
      ::aMsgs[ 5 ] := 'Erro de tipo de par�metro INSERT cTable'
      ::aMsgs[ 6 ] := 'INSERT aHash Param Type Error'
      ::aMsgs[ 7 ] := 'DELETE erro de tipo de par�metro cTable'
      ::aMsgs[ 8 ] := 'DELETE cWhere Erro de tipo de par�metro'
      ::aMsgs[ 9 ] := 'ATUALIZAR erro de tipo de par�metro cTable'
      ::aMsgs[ 10 ] := 'ATUALIZAR erro de tipo de par�metro cWhere'
      ::aMsgs[ 11 ] := 'ATUALIZAR erro de tipo de par�metro aHash'
      ::aMsgs[ 12 ] := 'Erro EXEC indefinido'
      ::aMsgs[ 13 ] := 'ERRO SQL'
      ::aMsgs[ 14 ] := 'ShowMessage() Erro de tipo de par�metro'


   ENDIF


RETURN Self

*---------------------------------------------------------------------------------------------*
METHOD SQLMIXEXT:Destroy()
*---------------------------------------------------------------------------------------------*
/*
 * SQLMIXEXT:Destroy()
 *
 * Destructor for the SQL class.
 *
 * Disconnects from the database, closes all open work areas, and releases memory used by the class.
 * This ensures that resources are properly cleaned up when the object is no longer needed, preventing memory leaks and other issues.
 *
 * Parameters:
 *   None
 *
 * Returns:
 *   NIL
 */

   ::Disconnect()

   ::aMsgs := NIL
   ::aWorkAreas := NIL
   ::cCommandBuffer := NIL
   ::cCommandWhere := NIL
   ::nConnHandle := NIL
   ::lError := NIL
   ::cErrorDesc := NIL
   ::lShowMsgs := NIL
   ::cMessageWindowName := NIL
   ::lTrace := NIL

RETURN NIL

*---------------------------------------------------------------------------------------------*
METHOD SQLMIXEXT:CloseAreas()
*---------------------------------------------------------------------------------------------*
/*
 * SQLMIXEXT:CloseAreas()
 *
 * Closes all open work areas used by the SQL class.
 * This is important to release database resources and prevent conflicts when working with multiple tables.
 *
 * Parameters:
 *   None
 *
 * Returns:
 *   The number of work areas closed.
 */
   LOCAL i, n := 0

   FOR i := Len( ::aWorkAreas ) TO 1 STEP -1
      IF Select( ::aWorkAreas[ I ] ) <> 0
         CLOSE ( ::aWorkAreas[ I ] )
         n++
      ENDIF
   NEXT i
   ::aWorkAreas := {}

RETURN n

*---------------------------------------------------------------------------------------------*
METHOD SQLMIXEXT:Connect( cServer, cUser, cPassword, cDatabase, cTipoMix, cPorta, cOwner, cStringCom )
*---------------------------------------------------------------------------------------------*
/*
 * SQLMIXEXT:Connect( cServer, cUser, cPassword, cDatabase, cTipoMix, cPorta, cOwner )
 *
 * Establishes a connection to the SQL database supporting multiple drivers/types (MySQL, PgSQL, SQLite, Firebird, Oracle, ODBC).
 */
   LOCAL oError, lSuccess := .F.
   LOCAL cConnStr
   LOCAL cConnectError := ''

   ::lError := .F.
   ::cErrorDesc := ''

   // Se os par�metros opcionais foram passados, atualiza as propriedades internas
   IF !Empty( cTipoMix ); ::cTipoMix := Upper( AllTrim( cTipoMix ) ); ENDIF
   IF !Empty( cPorta ); ::cPorta := AllTrim( cPorta ); ENDIF
   IF !Empty( cOwner ); ::cOwner := AllTrim( cOwner ); ENDIF

   // Valida��es b�sicas de acordo com o tipo de banco
   IF ::cTipoMix $ "MYSQL|MYSQL64|PGSQL|PGSQL64|POSTGRESQL|ORACLE|OCI"
      IF Empty( cServer ) .OR. Empty( cDatabase )
         ::lError := .T.
         ::cErrorDesc := ::aMsgs[ 2 ] // 'Connection Error!'
         IF ::lShowMsgs; ALERT( ::cErrorDesc ); ENDIF
         RETURN .F.
      ENDIF
   ELSEIF ::cTipoMix $ "SQLITE|FIREBIRD"
      IF Empty( cDatabase )
         ::lError := .T.
         ::cErrorDesc := ::aMsgs[ 2 ]
         IF ::lShowMsgs; ALERT( ::cErrorDesc ); ENDIF
         RETURN .F.
      ENDIF
   ENDIF

   IF ::lShowMsgs
      ::ShowMessage( ::aMsgs[ 1 ] ) // 'SQL: Conectando...'
   ENDIF

   TRY
      rddSetDefault( "SQLMIX" )

      DO CASE
      CASE ::cTipoMix = "MYSQL" .OR. ::cTipoMix = "MYSQL64"
         ::nConnHandle := rddInfo( RDDI_CONNECT, { "MYSQL", AllTrim(cServer), AllTrim(cUser), AllTrim(cPassword), AllTrim(cDatabase) }, "SQLMIX" )

      CASE ::cTipoMix = "PGSQL" .OR. ::cTipoMix = "PGSQL64" .OR. ::cTipoMix = "POSTGRESQL"
         ::nConnHandle := rddInfo( RDDI_CONNECT, { "POSTGRESQL", AllTrim(cServer), AllTrim(cUser), AllTrim(cPassword), AllTrim(cDatabase) }, "SQLMIX" )
         IF ::nConnHandle > 0
            // For�a o schema e encoding no Postgres
            IF ! rddInfo( RDDI_EXECUTE, "SET search_path TO " + If(Empty(::cOwner), "public", AllTrim(::cOwner)) + ", public; SET client_encoding TO 'WIN1252';", "SQLMIX", ::nConnHandle )
               cConnectError := rddInfo( RDDI_ERROR, , "SQLMIX", ::nConnHandle )
               IF Empty( cConnectError )
                  cConnectError := ::aMsgs[ 12 ]
               ENDIF
               IF rddInfo( RDDI_DISCONNECT,, "SQLMIX", ::nConnHandle )
                  ::nConnHandle := 0
               ENDIF
            ENDIF
         ENDIF

      CASE ::cTipoMix = "SQLITE" .OR. ::cTipoMix = "SQLITE3"
         ::nConnHandle := rddInfo( RDDI_CONNECT, { "SQLITE3", AllTrim(cDatabase) }, "SQLMIX" )

      CASE ::cTipoMix = "FIREBIRD"
         IF !Empty(cUser) .AND. !Empty(cPassword)
            ::nConnHandle := rddInfo( RDDI_CONNECT, { "FIREBIRD", AllTrim(cDatabase), AllTrim(cUser), AllTrim(cPassword) }, "SQLMIX" )
         ELSE
            ::nConnHandle := rddInfo( RDDI_CONNECT, { "FIREBIRD", AllTrim(cDatabase) }, "SQLMIX" )
         ENDIF

      CASE ::cTipoMix = "ORACLE" .OR. ::cTipoMix = "OCI"
         ::nConnHandle := rddInfo( RDDI_CONNECT, { "OCILIB", AllTrim(cServer), AllTrim(cUser), AllTrim(cPassword), AllTrim(cDatabase) }, "SQLMIX" )

     CASE ::cTipoMix = "ODBC"
         IF !Empty( cStringCom )
            // Utiliza a string pronta passada por par�metro
            cConnStr := AllTrim( cStringCom )
         ELSEIF !Empty( cServer ) .AND. At( "DRIVER=", Upper( cServer ) ) > 0
            // Caso o cServer traga a string pronta de conex�o
            cConnStr := AllTrim( cServer )
         ELSE // Ajuste l�gico para DSN se aplic�vel
            cConnStr := "Provider=MSDASQL;Data Source=" + AllTrim( cDatabase ) + ";"
            IF !Empty( cUser ); cConnStr += "Uid=" + AllTrim( cUser ) + ";"; ENDIF
            IF !Empty( cPassword ); cConnStr += "Pwd=" + AllTrim( cPassword ) + ";"; ENDIF
         ENDIF

         ::nConnHandle := rddInfo( RDDI_CONNECT, { "ODBC", cConnStr }, "SQLMIX" )

      OTHERWISE
         // Gen�rico customizado
         ::nConnHandle := rddInfo( RDDI_CONNECT, { ::cTipoMix, AllTrim(cServer), AllTrim(cUser), AllTrim(cPassword), AllTrim(cDatabase) }, "SQLMIX" )
      ENDCASE

      lSuccess := ( ValType( ::nConnHandle ) == 'N' .AND. ::nConnHandle > 0 .AND. Empty( cConnectError ) )

   CATCH oError
      ::lError := .T.
      cConnectError := rddInfo( RDDI_ERROR, , "SQLMIX", ::nConnHandle )
      IF Empty( cConnectError )
         cConnectError := oError:Description
      ENDIF
   END

   IF !lSuccess
      ::lError := .T.
      IF Empty( cConnectError )
         cConnectError := rddInfo( RDDI_ERROR, , "SQLMIX", ::nConnHandle )
      ENDIF
      IF Empty( cConnectError )
         cConnectError := ::aMsgs[ 2 ] // 'Connection Error!'
      ENDIF
      ::cErrorDesc := cConnectError
   ENDIF

   IF ::lShowMsgs .AND. ::lError
      alert( ::cErrorDesc, ::aMsgs[ 13 ] )
   ENDIF

   IF ::lTrace .AND. lSuccess
      hb_MemoWrit( 'trace.log', DToC( Date() ) + ' ' + Time() + ': CONNECTED TO ' + ::cTipoMix + ' DB: ' + cDatabase + hb_eol(), .T. )
   ENDIF

RETURN lSuccess

*---------------------------------------------------------------------------------------------*
METHOD SQLMIXEXT:Disconnect()
*---------------------------------------------------------------------------------------------*
/*
 * SQLMIXEXT:Disconnect()
 *
 * Closes the database connection and all work areas opened by this instance.
 *
 * Returns:
 *   .T. if the connection was closed, .F. otherwise.
 */
   LOCAL lDisconnected := .T.

   ::lError := .F.
   ::cErrorDesc := ''

   IF ValType( ::nConnHandle ) == 'N' .AND. ::nConnHandle > 0
      ::CloseAreas()
      lDisconnected := rddInfo( RDDI_DISCONNECT,, "SQLMIX", ::nConnHandle )
      IF lDisconnected
         ::nConnHandle := 0
      ELSE
         ::lError := .T.
         ::cErrorDesc := rddInfo( RDDI_ERROR, , "SQLMIX", ::nConnHandle )
         IF Empty( ::cErrorDesc )
            ::cErrorDesc := ::aMsgs[ 2 ]
         ENDIF
      ENDIF
   ENDIF

RETURN lDisconnected

*---------------------------------------------------------------------------------------------*
METHOD SQLMIXEXT:Select( cCommand, cWorkArea )
*---------------------------------------------------------------------------------------------*
/*
 * SQLMIXEXT:Select( cCommand, cWorkArea )
 *
 * Executes a SELECT SQL command and opens a work area.
 * It uses the dbUseArea function to execute the command and open the work area.
 *
 * Parameters:
 *   cCommand  : The SELECT SQL command to execute.
 *   cWorkArea : The work area to open for the result set.
 *
 * Returns:
 *   .T. if the command was executed successfully, .F. otherwise.
 */
   LOCAL oError, lSuccess := .F.

   ::lError := .F.
   ::cErrorDesc := ''

   // Validate parameters
   IF ValType( cCommand ) <> 'C' .OR. Empty( cCommand ) .OR. At( ';', cCommand ) > 0
      ::lError := .T.
      ::cErrorDesc := 'Invalid SQL command'
      IF ::lShowMsgs
         alert( ::cErrorDesc, ::aMsgs[ 13 ] )
      ENDIF
      RETURN .F.
   ENDIF

   IF ValType( cWorkArea ) <> 'C' .OR. Empty( cWorkArea )
      ::lError := .T.
      ::cErrorDesc := 'Invalid work area name'
      IF ::lShowMsgs
         alert( ::cErrorDesc, ::aMsgs[ 13 ] )
      ENDIF
      RETURN .F.
   ENDIF

   IF ::lShowMsgs
      ALERT( ::aMsgs[ 3 ] ) // 'SQL: Processing...'
   ENDIF

   TRY
      dbUseArea( .T., "SQLMIX", cCommand, cWorkArea,,,, ::nConnHandle )
      lSuccess := Used()
      AAdd( ::aWorkAreas, cWorkArea )

      IF ::lTrace
         hb_MemoWrit( 'trace.log', DToC( Date() ) + ' ' + Time() + ': SELECT ' + cCommand + hb_eol(), .T. )
      ENDIF

   CATCH oError
      ::lError := .T.
      ::cErrorDesc := oError:Description
   END

   IF ::lShowMsgs
      IF ::lError
         alert( ::cErrorDesc, ::aMsgs[ 13 ] )
      ENDIF
   ENDIF

RETURN lSuccess

*---------------------------------------------------------------------------------------------*
METHOD SQLMIXEXT:Field( cField, xExpression )
*---------------------------------------------------------------------------------------------*
/*
 * SQLMIXEXT:Field( cField, xExpression )
 *
 * Formats a field and its value for use in SQL commands (INSERT or UPDATE).
 * This is a HIDDEN method, intended for internal use by the class.
 *
 * Parameters:
 *   cField      : The name of the field.
 *   xExpression : The value of the field.  Can be of various data types (Date, Character, Numeric, Logical).
 *
 * Returns:
 *   .T. if the field was formatted successfully, .F. otherwise.
 *
 * Note:
 *   This method handles data type conversion and quoting for SQL compatibility.
 *   It also supports a "raw" mode where the value is not quoted (indicated by a leading ::cNoQuoteChar).
 *   This allows for inserting values that are already SQL expressions or functions.
 */
   LOCAL cExpression, lRaw := .F.

   ::lError := .F.
   ::cErrorDesc := ''

   IF ValType( xExpression ) = 'D'
      cExpression := StrZero( Year( xExpression ), 4 ) + '-' + StrZero( Month( xExpression ), 2 ) + '-' + StrZero( Day( xExpression ), 2 )
   ELSEIF ValType( xExpression ) = 'C'
      cExpression := AllTrim( xExpression )
      IF Left( cExpression, 1 ) = ::cNoQuoteChar
         lRaw := .T.
         cExpression := Right( cExpression, Len( cExpression ) - 1 )
      ENDIF
      cExpression := StrTran( cExpression, "'", "''" )
      cExpression := StrTran( cExpression, "\", "\\" )
   ELSEIF ValType( xExpression ) = 'N'
      cExpression := hb_ntos( xExpression )
      lRaw := .T.
   ELSEIF ValType( xExpression ) = 'L'
      IF xExpression
         cExpression := '1'
      ELSE
         cExpression := '0'
      ENDIF
      lRaw := .T.
   ELSEIF ValType( xExpression ) = 'U' // Nil
      cExpression := "NULL"
      lRaw := .T.   
   ELSE
      ::lError := .T.
      ::cErrorDesc := ::aMsgs[ 4 ] // SQL: Column Data Expression Type Error

      IF ::lShowMsgs
         alert( ::cErrorDesc, ::aMsgs[ 13 ] )
      ENDIF
   ENDIF

   IF ! ::lError
      IF lRaw
         ::cCommandBuffer += cField + " = " + cExpression + ' ' + ','
      ELSE
         ::cCommandBuffer += cField + " = " + "'" + cExpression + "'" + ','
      ENDIF
   ENDIF

RETURN ! ::lError

*---------------------------------------------------------------------------------------------*
METHOD SQLMIXEXT:Insert( cTable, aHash )
*---------------------------------------------------------------------------------------------*
/*
 * SQLMIXEXT:Insert( cTable, aHash )
 *
 * Executes an INSERT SQL command using data from a hash.
 * It iterates through the hash, formatting each field and value using the ::Field() method.
 *
 * Parameters:
 *   cTable : The name of the table to insert into.
 *   aHash  : A hash containing the field names and values to insert.
 *
 * Returns:
 *   .T. if the command was executed successfully, .F. otherwise.
 */
   LOCAL aKeys, aValues, i

   IF ValType( cTable ) <> 'C'
      ::lError := .T.
      ::cErrorDesc := ::aMsgs[ 5 ] // 'SQL: INSERT cTable Param Type Error'

      IF ::lShowMsgs
         alert( ::cErrorDesc, ::aMsgs[ 13 ] )
      ENDIF
   ELSEIF ValType( aHash ) <> 'H'
      ::lError := .T.
      ::cErrorDesc := ::aMsgs[ 6 ] // 'SQL: INSERT aHash Param Type Error'

      IF ::lShowMsgs
         alert( ::cErrorDesc, ::aMsgs[ 13 ] )
      ENDIF
   ELSE
      ::lError := .F.
      ::cErrorDesc := ''

      ::cCommandBuffer := ''
      ::cCommandWhere := ''

      ::cCommandBuffer += "INSERT INTO " + cTable + " SET "

      aKeys := hb_HKeys( aHash )

      aValues := hb_HValues( aHash )

      FOR i := 1 TO Len( aKeys )
         IF ! ::Field( aKeys[ i ], aValues[ i ] )
            EXIT
         ENDIF
      NEXT i

      IF ! ::lError
         ::Exec()
      ENDIF
   ENDIF

RETURN ! ::lError

*---------------------------------------------------------------------------------------------*
METHOD SQLMIXEXT:Delete( cTable, cWhere )
*---------------------------------------------------------------------------------------------*
/*
 * SQLMIXEXT:Delete( cTable, cWhere )
 *
 * Executes a DELETE SQL command with a WHERE clause.
 *
 * Parameters:
 *   cTable : The name of the table to delete from.
 *   cWhere : The WHERE clause to use in the DELETE command.
 *
 * Returns:
 *   .T. if the command was executed successfully, .F. otherwise.
 */

   IF ValType( cTable ) <> 'C'
      ::lError := .T.
      ::cErrorDesc := ::aMsgs[ 7 ] // 'SQL: DELETE cTable Param Type Error'
      IF ::lShowMsgs
         alert( ::cErrorDesc, ::aMsgs[ 13 ] )
      ENDIF
   ELSEIF ValType( cWhere ) <> 'C'
      ::lError := .T.
      ::cErrorDesc := ::aMsgs[ 8 ] // 'SQL: DELETE cWhere Param Type Error'
      IF ::lShowMsgs
         alert( ::cErrorDesc, ::aMsgs[ 13 ] )
      ENDIF
   ELSE

      ::cCommandBuffer := ''
      ::cCommandWhere := ''

      ::cCommandBuffer += "DELETE FROM " + cTable + " WHERE " + cWhere

      ::Exec()

   ENDIF

RETURN ! ::lError

*---------------------------------------------------------------------------------------------*
METHOD SQLMIXEXT:AffectedRows()
*---------------------------------------------------------------------------------------------*
/*
 * SQLMIXEXT:AffectedRows()
 *
 * Returns the number of rows affected by the last SQL command.
 * It uses the rddInfo function with RDDI_AFFECTEDROWS to retrieve the number of affected rows.
 *
 * Parameters:
 *   None
 *
 * Returns:
 *   The number of rows affected, or 0 if an error occurred.
 */
   LOCAL nRetVal

   ::lError := .F.
   ::cErrorDesc := ''

   nRetVal := rddInfo( RDDI_AFFECTEDROWS,, "SQLMIX", ::nConnHandle )

   IF ValType( nRetVal ) <> 'N'
      nRetVal := 0
      ::lError := .T.
   ENDIF

RETURN nRetVal

*---------------------------------------------------------------------------------------------*
METHOD SQLMIXEXT:Update( cTable, cWhere, aHash )
*---------------------------------------------------------------------------------------------*
/*
 * SQLMIXEXT:Update( cTable, cWhere, aHash )
 *
 * Executes an UPDATE SQL command using data from a hash and a WHERE clause.
 * It iterates through the hash, formatting each field and value using the ::Field() method.
 *
 * Parameters:
 *   cTable : The name of the table to update.
 *   cWhere : The WHERE clause to use in the UPDATE command.
 *   aHash  : A hash containing the field names and values to update.
 *
 * Returns:
 *   .T. if the command was executed successfully, .F. otherwise.
 */
   LOCAL aKeys, aValues, i

   IF ValType( cTable ) <> 'C'
      ::lError := .T.
      ::cErrorDesc := ::aMsgs[ 9 ] // 'SQL: UPDATE cTable Param Type Error'
      IF ::lShowMsgs
         alert( ::cErrorDesc, ::aMsgs[ 13 ] )
      ENDIF
   ELSEIF ValType( cWhere ) <> 'C'
      ::lError := .T.
      ::cErrorDesc := ::aMsgs[ 10 ] // 'SQL: UPDATE cWhere Param Type Error'
      IF ::lShowMsgs
         alert( ::cErrorDesc, ::aMsgs[ 13 ] )
      ENDIF
   ELSEIF ValType( aHash ) <> 'H'
      ::lError := .T.
      ::cErrorDesc := ::aMsgs[ 11 ] // 'SQL: UPDATE aHash Param Type Error'
      IF ::lShowMsgs
         alert( ::cErrorDesc, ::aMsgs[ 13 ] )
      ENDIF
   ELSE
      ::cCommandBuffer := ''

      ::cCommandWhere := cWhere

      ::cCommandBuffer += "UPDATE " + cTable + " SET "

      aKeys := hb_HKeys( aHash )

      aValues := hb_HValues( aHash )

      FOR i := 1 TO Len( aKeys )
         IF ! ::Field( aKeys[ i ], aValues[ i ] )
            EXIT
         ENDIF
      NEXT i

      IF ! ::lError
         ::Exec()
      ENDIF

   ENDIF

RETURN ! ::lError

*---------------------------------------------------------------------------------------------*
METHOD SQLMIXEXT:Exec( cCommand )
*---------------------------------------------------------------------------------------------*
/*
 * SQLMIXEXT:Exec( cCommand )
 *
 * Executes the SQL command stored in the command buffer or a provided command.
 * Uses rddInfo with RDDI_EXECUTE for execution, with enhanced error handling and logging.
 *
 * Parameters:
 *   cCommand (optional): The SQL command to execute. If omitted, the command in ::cCommandBuffer is executed.
 *
 * Returns:
 *   .T. if the command was executed successfully, .F. otherwise.
 */
   LOCAL oError, lSuccess := .F.
   LOCAL cFinalCommand
   LOCAL lExecuteStarted := .F.

   ::lError := .F.
   ::cErrorDesc := ''

   IF ::lShowMsgs
      ALERT( ::aMsgs[ 3 ] ) // 'SQL: Processing...'
   ENDIF

   TRY
      IF ValType( cCommand ) == 'U'
         cFinalCommand := ::cCommandBuffer
         IF Right( cFinalCommand, 1 ) == ','
            cFinalCommand := hb_StrShrink( cFinalCommand )
         ENDIF
         IF ! Empty( ::cCommandWhere )
            cFinalCommand += ' WHERE ' + AllTrim( ::cCommandWhere )
         ENDIF
      ELSE
         cFinalCommand := AllTrim( cCommand )
      ENDIF

      IF Empty( cFinalCommand ) .OR. At( ';', cFinalCommand ) > 0
         ::lError := .T.
         ::cErrorDesc := 'SQL command must be non-empty and contain no semicolon'
      ELSE
         lExecuteStarted := .T.
         lSuccess := rddInfo( RDDI_EXECUTE, cFinalCommand, "SQLMIX", ::nConnHandle )
         IF ! lSuccess
            ::lError := .T.
            ::cErrorDesc := rddInfo( RDDI_ERROR, , "SQLMIX", ::nConnHandle )
            IF Empty( ::cErrorDesc )
               ::cErrorDesc := ::aMsgs[ 12 ]
            ENDIF
         ENDIF

         IF ::lTrace
            hb_MemoWrit( 'trace.log', DToC( Date() ) + ' ' + Time() + ': ' + cFinalCommand + hb_eol(), .T. )
         ENDIF
      ENDIF

   CATCH oError
      ::lError := .T.
      IF lExecuteStarted .AND. ! lSuccess
         ::cErrorDesc := rddInfo( RDDI_ERROR, , "SQLMIX", ::nConnHandle )
      ENDIF
      IF Empty( ::cErrorDesc )
         ::cErrorDesc := oError:Description
      ENDIF
   END

   IF ! lSuccess
      ::lError := .T.
      IF Empty( ::cErrorDesc )
         ::cErrorDesc := ::aMsgs[ 12 ] // 'EXEC Undefined Error'
      ENDIF
   ENDIF

   ::cCommandBuffer := ''
   ::cCommandWhere := ''

   IF ::lShowMsgs
      IF ::lError
         alert( ::cErrorDesc, ::aMsgs[ 13 ] )
      ENDIF
   ENDIF

RETURN lSuccess

METHOD SQLMIXEXT:LastInsertID()
   LOCAL nID := 0

   ::lError := .F.
   ::cErrorDesc := ''

   TRY
      nID := rddInfo( RDDI_INSERTID, , "SQLMIX", ::nConnHandle )
   CATCH oError
      nID := 0
      ::lError := .T.
      ::cErrorDesc := oError:Description
   END
RETURN nID

/*
METHOD SQLMIXEXT:BeginTrans()
   RETURN rddInfo( RDDI_EXECUTE, Dialeto_begin(), "SQLMIX", ::nConnHandle )

METHOD SQLMIXEXT:CommitTrans()
   RETURN rddInfo( RDDI_EXECUTE, Dialeto_commit(), "SQLMIX", ::nConnHandle )

METHOD SQLMIXEXT:RollbackTrans()
   RETURN rddInfo( RDDI_EXECUTE, Dialeto_rollback(), "SQLMIX", ::nConnHandle )
*/