// +--------------------------------------------------------------------
// +
// +   git\core\contrib\hbpgsql\
// +
// +
// +--------------------------------------------------------------------
// +
// +


// +--------------------------------------------------------------------
// +
// +    Programa  : sqlite.prg
// +
// +     Sistema: DBU - sqlite nativo hbsqlit3
// +
// +     Linguagem: Harbour
// +
// +     Autor: jcassiano
// +
// +     Copyright (c) 2024,  jcassiano
// +
// +    Documentado em 28-Dez-2024 as 10:08 am
// +
// +--------------------------------------------------------------------
// +

#include "dbstruct.ch"
#include "BOX.CH"
#include "dbinfo.ch"
#include "hbVER.CH"
#include "directry.ch"

#require "hbsqlit3"
#require "hbmemio"


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function sqlitemenu()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION sqlitemenu()

   PUBLIC oDB         := nil
   PUBLIC oDB1        := nil
   PRIVATE cTableName := ''
   PRIVATE cNewTable  := ''
   PRIVATE lOpened    := .F.

   loledb    := hb_Version( HB_VERSION_BITWIDTH ) <> 64
   lMDB      := .F.
   lACCDB    := .F.
   lFDB       := .F.
   cTIPOSQL  := "SQLITE"
   aAMBIENTE := SALVAA()

   WHILE .T.
      hb_DispBox( 3, 18, 18, 55, B_DOUBLE + " " )
      OPCAO(  4, 24, "&Criar base sqllite        ", 67 )   // c
      OPCAO(  5, 24, "&VACUUM (PACK)             ", 86 )   // V
      OPCAO(  6, 24, "&Importar  DBF             ", 73 )   // I
      OPCAO(  7, 24, "&Exportar  DBF             ", 69 )   // E
      OPCAO(  8, 24, "&Tabelas                   ", 84 )   // T
      OPCAO(  9, 24, "&Apagar Tabela             ", 65 )   // A
      OPCAO( 10, 24, "Exportar &Formatos         ", 70 )  // f
	  OPCAO( 11, 24, "Mar&kdown documentacao     ", 75 )   //K
      OPCAO( 12, 24, "C&hecar integridade        ", 72 )   //h
      OPCAO( 13, 24, "Executar arquivo &SQL      ", 83 )   //S 83
      KEY := menu( 1, 0 )
      DO CASE
      CASE KEY = 1
         createSqlitedb()
      CASE KEY = 2
         IF selectdb()
            sqlitepack( odb )
         ENDIF
      CASE KEY = 3
         IF selectdb()
            nOLDTIPO := TIPODBF
            alertX( "escolha origem" )
            tipodbfesc()
            nORITIPO   := TIPODBF
            cORIDRIVER := RDDNOME( TIPODBF )
            lincdados:=mdg("Incluir Dados")
            IF MDG("Arquivo individual")
               cARQORI    := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*."+TABLEEXT, 1 )
                IF File( cARQORI )
                   export2sql( odb, cARQORI,lincdados )
                ENDIF
            ELSE
               cPASTA:=SelectFolder()
               cPASTA+="\*."+TABLEEXT 
               //FAZERDBF(bUSO                                       , lSHARE[.F.] , bPRE, bPOS, cMASK ,LOPEN )
               FAZERDBF( {|| export2sql( odb, cCAMINHOCOMPLETO ,lincdados ) }, .F. ,     ,     ,cPASTA,.F.)
            ENDIF   
            RDDNOME( nOLDTIPO )   // retorna tipo anterior
         ENDIF
      CASE KEY = 4
         IF selectdb()
            exportadbf( odb, 1 )
         ENDIF
      CASE KEY = 5
         IF selectdb()
            SqliteTables( odb )
         ENDIF
      CASE KEY = 6
         IF selectdb()
            SqliteTables( odb )
            sqllitedeltable( odb )
         ENDIF
      CASE KEY = 7
         IF selectdb()
            exportadbf( odb, 2 )
         ENDIF
	  case key = 8	
           cFileName := win_GetOpenFileName(, "SQLite Files", hb_cwd(), "SQLite", ;
      { { 'SQLite', '*.sqlite' }, { 'SQLite db', '*.DB' }, ;
      { 'SQLite3', '*.sqlite3' }, { 'SQLite db3', '*.DB3' }, ;
      { 'SQLite Fossil', '*.fossil' }, { 'All Files', '*.*' } }, 1 )
            GeraMDdbml(cFileName)
       CASE KEY = 9
         IF selectdb()
            check_sqlite( odb )
         ENDIF      
        CASE KEY = 10
           SqliteArqSql()  
            	  
      OTHERWISE
         RETURN
      ENDCASE
   ENDDO

   RESTAA( aAMBIENTE )
   layout()

   RETURN NIL


// +--------------------------------------------------------------------
// +
// +    Function SqliteArqSql()
// +
// +--------------------------------------------------------------------
// +

function SqliteArqSql()

LOCAL cCOMANDO := ""
LOCAL cARQIMP  := ""

cARQIMP := win_GetOPENFileName(,"Arquivos SQL",HB_CWD(),"Arquivos SQL","*.SQL",1)
//cARQORI := OPENTIPOARQ()

IF FILE(cARQIMP)
   //nao pode ser linha a linha pois um comando pode estar em mais de uma linha
   cCOMANDO:=MEMOREAD(cARQIMP)
   sqlite3_exec( db, cCOMANDO ) 
endif
return .t.


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function sqllitedeltable()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION sqllitedeltable( db )

   IF ! MDG( "Apagar Tabela" + cTABELAX )
      RETURN .F.
   ENDIF
   IF sqlite3_exec( db, "DROP TABLE IF EXISTS " + cTABELAX ) == SQLITE_OK
      MDT( Ctabelax + " Excluida" )
   ENDIF

   RETURN .T.



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function exportadbf()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION exportadbf( db, ntipo )

   LOCAL cTABELAEXP

   IF nTIPO = 2
      LCOPIANAT := .F.   // MDG("Copia Nativa(SIM) Interna(NAO)") //copy to nao implemntado PGsqlrddd
      tDOC      := pegtipodoc()  // .t. Inclui dbf se for nativa
      pegparexp()
      lDOCCAB   := .F.
      lDOCDAD   := .F.
      lDOCRECNO := .F.
      cSUBTIPO  := " "
   ENDIF
   IF MDG( "Todas(SIM) Escolher Nao" )
      aTable := sqltablestru( DB, "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name" )
      IF Len( aTable ) == 0
         msgstop( 'No Tables in the DB', 'DBF<-->SQLite Exporter' )
         RETURN NIL
      ENDIF
      FOR i := 1 TO Len( aTable )
         MDT( aTable[ i, 1 ] )
         Export2dbf( DB, aTable[ i, 1 ], ntipo )
      NEXT i
   ELSE
      cTABELAEXP := SQLITETABLES( DB )
      IF !Empty( cTABELAEXP )
         Export2dbf( DB, cTABELAEXP, Ntipo )
      ENDIF
   ENDIF

   RETURN NIL


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function C2SQLTS
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION C2SQLTS( dpDate, cpTime )
   LOCAL cDate := ""
   LOCAL cTime := ""
   LOCAL cRetu := ""

   // Se for SQLite e o valor estiver vazio/nulo, já retorna string vazia de imediato
   IF cTIPOSQL == "SQLITE" .AND. Empty( dpDate )
      RETURN "''"
   ENDIF

   IF PCount() == 0
      cDate := DToS( Date() )
      cTime := Time()
   ELSE
      DO CASE
         CASE PCount() == 1
            // Se o dado for um Timestamp nativo ("@"), desmembramos a data e hora dele
            IF ValType( dpDate ) == "@"
               cDate := DToS( TToD( dpDate ) ) // Extrai a Data pura
               cTime := TToC( dpDate )         // Converte para String de Hora
               
               // Se a conversão trouxer a data junto na string, pega apenas o pedaço da hora
               IF " " $ cTime
                  cTime := AllTrim( SubStr( cTime, At( " ", cTime ) + 1 ) )
               ENDIF
               IF Empty( cTime )
                  cTime := "00:00:00"
               ENDIF
            ELSE
               cDate := DToS( dpDate )
               cTime := "23:59:59"
            ENDIF
            
         CASE PCount() == 2
            IF ValType( dpDate ) == "@"
               cDate := DToS( TToD( dpDate ) )
            ELSE
               cDate := DToS( dpDate )
            ENDIF
            cTime := AllTrim( cpTime )
      ENDCASE
   ENDIF

   // Se a data acabou ficando vazia após os desmembramentos
   IF Empty( cDate )
      IF cTIPOSQL == "SQLITE"
         RETURN "''"
      ELSE
         RETURN "NULL"
      ENDIF
   ENDIF

   // Monta o formato padrão internacional: 'YYYY-MM-DD HH:MM:SS'
   cRetu := "'" + SubStr( cDate, 1, 4 ) + "-" + SubStr( cDate, 5, 2 ) + "-" + SubStr( cDate, 7, 2 ) + " " + cTime + "'"

RETURN cRetu

// +--------------------------------------------------------------------
// +
// +
// +
// +    Function C2SQL()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION C2SQL( Value )
   LOCAL cValue := ""
   LOCAL cdate  := ""

   DO CASE
       CASE ValType( Value ) == "N"
          cValue := AllTrim( Str( Value ) )

       CASE ValType( Value ) == "@"    // Datetime
          cValue := C2SQLTS( Value )

       CASE ValType( Value ) == "D"
          IF ! Empty( Value )
             cdate  := DToS( value )
             cValue := "'" + SubStr( cDate, 1, 4 ) + "-" + SubStr( cDate, 5, 2 ) + "-" + SubStr( cDate, 7, 2 ) + "'"
          ELSE
             // Se for SQLite, retorna '' conforme a estrutura NOT NULL DEFAULT ''
             // Para outros bancos, mantém o comportamento original caso prefira NULL
             IF cTIPOSQL == "SQLITE"
                cValue := "''"
             ELSE
                cValue := "NULL"
             ENDIF
          ENDIF

       CASE ValType( Value ) $ "CM"
          IF Empty( Value )
             IF cTIPOSQL == "SQLITE"
                cValue := "''"
             ELSE
                cValue := "NULL"
             ENDIF
          ELSE
             cVALUE := VALUE
             
              //mantendo ansi mas analisarei se a necessario realmente mudar para uf8 visto que deu muitos problemas no vo com truncamento de dados
             // Aplica a conversão UTF-8 estritamente para o SQLite tratar acentuação
             //IF cTIPOSQL == "SQLITE"
             //   cVALUE := hb_StrToUTF8( cVALUE )
             //ENDIF

             // Troca caracteres ',() usados pelo sql language
             cVALUE := StrTran( cVALUE, "'", " " )
             cVALUE := StrTran( cVALUE, ",", " " )
             cVALUE := StrTran( cVALUE, "(", " " )
             cVALUE := StrTran( cVALUE, ")", " " )
             cVALUE := StrTran( cVALUE, "\", "\\" )   // inclui nova barra pois e considerada escape no insert into
             cVALUE := AllTrim( cVALUE ) 
             cValue := "'" + cvalue + "'"
          ENDIF

       CASE ValType( Value ) == "L"
          IF cTIPOSQL == "SQLITE"
             cValue := AllTrim( Str( iif( Value == .F., 0, 1 ) ) )
          ELSE
             cValue := iif( Value == .F., ".F.", ".T." )
          ENDIF

   OTHERWISE
      cValue := iif( cTIPOSQL == "SQLITE", "''", "NULL" )
   ENDCASE

RETURN cValue


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function sqltablestru()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION sqltablestru( dbo1, qstr )

   LOCAL table    := {}
   LOCAL stmt
   LOCAL currow   := nil
   LOCAL tablearr := {}
   LOCAL rowarr   := {}
   LOCAL typesarr := {}
   LOCAL cdate    := ""
   LOCAL current  := ""
   LOCAL i        := 0
   LOCAL j        := 0
   LOCAL type1    := ""

   IF Empty( dbo1 )
      msgstop( "Database Connection Error!" )
      RETURN tablearr
   ENDIF
   table := sqlite3_get_table( dbo1, qstr )
   IF sqlite3_errcode( dbo1 ) > 0  // error
      msgstop( sqlite3_errmsg( dbo1 ) + " Query is : " + qstr )
      RETURN NIL
   ENDIF
   stmt := sqlite3_prepare( dbo1, qstr )
   IF !Empty( stmt )
      FOR i := 1 TO sqlite3_column_count( stmt )
         type1 := Upper( AllTrim( sqlite3_column_decltype( stmt, i ) ) )
         DO CASE
         CASE type1 == "INTEGER" .OR. type1 == "REAL" .OR. type1 == "FLOAT" .OR. type1 == "DOUBLE" .OR. type1 == "INT" .OR. type1 == "SMALLINT"
            AAdd( typesarr, "N" )
         CASE type1 == "DATE" .OR. type1 == "DATETIME" .OR. type1 == "TIMESTAMP"
            AAdd( typesarr, "D" )
         CASE type1 == "BOOL"
            AAdd( typesarr, "L" )
         OTHERWISE
            AAdd( typesarr, "C" )
         ENDCASE
      NEXT i
   ENDIF
   sqlite3_reset( stmt )
   IF Len( table ) > 1
      ASize( tablearr, 0 )
      FOR i := 2 TO Len( table )
         rowarr := table[ i ]
         FOR j := 1 TO Len( rowarr )
            DO CASE
            CASE typesarr[ j ] == "D"
               cDate       := SubStr( rowarr[ j ], 1, 4 ) + SubStr( rowarr[ j ], 6, 2 ) + SubStr( rowarr[ j ], 9, 2 )
               rowarr[ j ] := SToD( cDate )
            CASE typesarr[ j ] == "N"
               rowarr[ j ] := Val( rowarr[ j ] )
            CASE typesarr[ j ] == "L"
               IF Val( rowarr[ j ] ) == 1
                  rowarr[ j ] := .T.
               ELSE
                  rowarr[ j ] := .F.
               ENDIF
            ENDCASE
         NEXT j
         AAdd( tablearr, AClone( rowarr ) )
      NEXT i
   ENDIF

   RETURN tablearr


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function sqlitepack()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION sqlitepack( db )


   if mdg("Implantar configuracao de performace")
      optimize_sqlite( db )
   endif

   IF !Empty( db )
   
       
      MDT( "Otimizando índices..." )
      sqlite3_exec( db, "PRAGMA optimize" )
      
      MDT( "Executando VACUUM (PACK)..." )
      IF sqlite3_exec( db, "VACUUM" ) == SQLITE_OK
         MDT( "Processo concluído com sucesso." )
      ENDIF
   
      
   ENDIF

   RETURN .T.
   
   
 FUNCTION optimize_sqlite( db )
 IF !Empty( db )
   // Armazena arquivos temporários na memória em vez de disco
   sqlite3_exec( db, "PRAGMA temp_store = MEMORY" )
   
   // Aumenta o tamanho do cache (ex: 2000 páginas)
   sqlite3_exec( db, "PRAGMA cache_size = 2000" )
   
   // Modo WAL (Write-Ahead Logging) - Muito mais rápido para inserções
   // e permite leitura e escrita simultâneas
   sqlite3_exec( db, "PRAGMA journal_mode = WAL" )
   
   // Reduz a sincronização com o disco (Normal é seguro o suficiente com WAL)
   sqlite3_exec( db, "PRAGMA synchronous = NORMAL" )
   
   sqlite3_exec( db, "PRAGMA auto_vacuum = INCREMENTAL" )
   // Para liberar o espaço de fato:
   sqlite3_exec( db, "PRAGMA incremental_vacuum" )
   
endif   
RETURN NIL  

 FUNCTION check_sqlite( db )
 IF !Empty( db )
   // Armazena arquivos temporários na memória em vez de disco
   if sqlite3_exec( db, "PRAGMA integrity_check" )  == SQLITE_OK
         MDT( "Processo concluído com sucesso." )
   ENDIF
endif   
RETURN NIL  


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function selectdb()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION selectdb

   LOCAL cFileName := ''
   LOCAL cDBName   := ''
   LOCAL nSlash    := 0
   LOCAL nDot      := 0
   LOCAL lRETU     := .F.

   cFileName := win_GetOpenFileName(, "SQLite Files", hb_cwd(), "SQLite", ;
      { { 'SQLite', '*.sqlite' }, { 'SQLite db', '*.DB' }, ;
      { 'SQLite3', '*.sqlite3' }, { 'SQLite db3', '*.DB3' }, ;
      { 'SQLite Fossil', '*.fossil' }, { 'All Files', '*.*' } }, 1 )

   IF Len( AllTrim( cFileName ) ) > 0
      cDBName := tiraext( cFileName )
      oDB     := Connect2DB( cFileName, .F. )
      IF oDB == Nil
         msgstop( 'Not a valid SQLite file.', 'SQLite File Selection' )
         RETURN .F.
      ELSE
         lRETU := .T.
         // MDT(" is Connected! Version: "+cFILENAME) //+ valtostr(sqlite3_libversion_number())

         mdt( cFILENAME + "Version library = " + sqlite3_libversion() + ;
            "number version library = " + LTrim( Str( sqlite3_libversion_number() ) ) )

      ENDIF
   ELSE
      msgstop( 'You have to select a SQLite File!', 'SQLite File Selection' )
      RETURN lRETU
   ENDIF
   
   optimize_sqlite( odb )

   RETURN lRETU



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function SqliteTables()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION SqliteTables( DB )

// ---------------------------------------------------------------------------
// Shows all tables inside the database
// ---------------------------------------------------------------------------
   LOCAL aResult, nChoices, I, aRETU
   LOCAL aAMBIENTE
   nChoices  := 0
   aAMBIENTE := SALVAA()
   aRESULT   := {}

// Show all tables inside database
   aRETU := sqltablestru( DB, "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name" )

   FOR i := 1 TO Len( aRETU )
      AAdd( aRESULT, aRETU[ i, 1 ] )
   NEXT i


   IF Len( aResult ) > 0
      hb_DispBox( 3, 22, 22, 55, B_DOUBLE + " " )
      nChoices := AChoice( 4, 23, 21, 54, aResult )
   ENDIF

   RESTAA( aAMBIENTE )

   RETURN ( iif( nChoices > 0, aResult[ nChoices ], "" ) )



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function connect2db()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION connect2db( dbname, lCreate )

   LOCAL dbo1 := sqlite3_open( dbname, lCreate )

   IF Empty( dbo1 )
      alertx( "Database could not be connected!" )
      RETURN NIL
   ENDIF


   RETURN dbo1



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function createSqlitedb()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION createSqlitedb

   LOCAL cFileName := ''
   LOCAL cDBName   := ''
   LOCAL nSlash    := 0
   LOCAL nDot      := 0

   cFileName := win_GetsaveFileName(, "SQLite Files", hb_cwd(), "SQLite", ;
      { { 'SQLite', '*.sqlite' }, { 'SQLite db', '*.DB' }, ;
      { 'SQLite3', '*.sqlite3' }, { 'SQLite db3', '*.DB3' }, ;
      { 'SQLite Fossil', '*.fossil' }, { 'All Files', '*.*' } }, 1 )


   IF Len( AllTrim( cFileName ) ) == 0
      msgstop( 'File name can not be empty!', 'DBF2SQLite Exporter' )
      RETURN NIL
   ENDIF
   IF At( '.', cFileName ) == 0
      cFileName := cFileName + '.sqlite'
   ENDIF
   IF File( cFileName )
      alertx( "Arquivo ja existe" )
      RETURN
   ENDIF
   cDBName := tiraext( cFileName )
   oDB     := Connect2DB( cFileName, .T. )
   IF oDB == Nil
      msgstop( 'Not a valid SQLite file.', 'SQLite File Selection' )
      RETURN NIL
   ELSE
      mdt( cDBName + " is Connected!" )
   ENDIF

   if mdg("Implantar configuracao de performace")
      optimize_sqlite( odb )
   endif


   RETURN NIL


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function export2dbf()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION export2dbf( ODB1, cNEWTABLE, Ntipo )

   LOCAL aTable       := {}
   LOCAL aTable1      := {}
   LOCAL cSQLTable    := {}
   LOCAL aStruct      := {}
   LOCAL cType        := ''
   LOCAL cFieldName   := ''
   LOCAL cFieldType   := ''
   LOCAL nFieldLength := ''
   LOCAL nFieldDec    := ''
   LOCAL nLength      := 0
   LOCAL aRecord      := {}
   LOCAL cINDEXNAME   := ""
   LOCAL i, j
   LOCAL aUsados := {}
   LOCAL cCurName
   LOCAL aUsedNames := {} // Lista para controlar nomes já usados
   LOCAL nSeq := 0
   LOCAL cBaseName := ""
   

   IF Len( AllTrim( cNewTable ) ) == 0
      msgstop( 'You have to select a DBF to export', 'DBF<-->SQLite Exporter' )
      RETURN NIL
   ENDIF
   IF Len( cNEWTABLE ) > 0
      cSQLTable := cNEWTABLE
      aTable    := sqltablestru( oDB1, 'PRAGMA table_info( ' + c2sql( cSQLTable ) + ')' )
      IF Len( aTable ) == 0
         msgstop( 'This is an empty table!' )
         RETURN NIL
      ENDIF
      FOR i := 1 TO Len( aTable )
         // table info colunas
         // cid, name, type, "notnull", dflt_value, pk
         // 1    2     3      4           5         6
         cFieldType   := Upper( AllTrim( aTable[ i, 3 ] ) )
         cFieldName   := AllTrim( aTable[ i, 2 ] )
         cfieldOrigin :=cFieldName //guarda o nome original para para nao utilizar os tratrado maiores que 10 abaixo
         nFieldLength := 0
         nFieldDec    := 0
         
         
         // --- LOGICA DE TRATAMENTO DE NOME ---
        cFieldName := Upper( Left( cFieldName, 10 ) ) // Garante 10 chars
        
        // Se o nome já existe na estrutura, entra no loop de renomeio
        IF AScan( aUsedNames, cFieldName ) > 0
           nSeq := 1
           cBaseName := Left( cFieldName, 8 ) // Deixa espaço para "_1"
           
           DO WHILE .T.
              cFieldName := cBaseName + "_" + AllTrim(Str(nSeq))
              IF AScan( aUsedNames, cFieldName ) == 0
                 EXIT
              ENDIF
              nSeq++
              // Se chegar em 10, reduz o nome base
              IF nSeq > 9
                 cBaseName := Left( cFieldName, 7 )
              ENDIF
           ENDDO
        ENDIF
        AAdd( aUsedNames, cFieldName ) // Registra o nome final como usado
        // ------------------------------------


         aTMP := geracampodbf( cFieldName, cFieldType, nFieldLength, nFieldDec )



         IF aTMP[ DBS_LEN ] = 0 .OR. aTMP[ DBS_LEN ] >= 250   // text geracampo volta 250 tentando ajustar o valor mais proximo
            //usa o nome nao tratado para puxar corretamente
            aTable1 := sqltablestru( oDB1, 'select max( length( ' + cfieldOrigin + ' ) ) from ' + c2sql( cSQLTable ) )
            IF Len( aTable1 ) > 0
               aTMP[ DBS_LEN ] := Val( AllTrim( aTable1[ 1, 1 ] ) )
            ENDIF
         ENDIF

         AAdd( aStruct, aTMP )
         // aadd( aStruct, { cFieldName, cFieldType, nFieldLength, nFieldDec } )
      NEXT i
      IF Len( aStruct ) > 0
         // cNEWARQ:=cNEWTABLE+"_exp"
         IF ntipo = 1
            dbCreate( cNewTable, aStruct, "DBFCDX" )
            dbUseArea( .T., "DBFCDX", cNewTable, "DESTINO", .T., .F. )
         ELSE
            dbCreate( "mem:destino", aStruct,, .T., "DESTINO" )
         ENDIF

         // use &cNewTable
         IF ! Used()
            msgstop( 'DBF File Creation error!', 'DBF<-->SQLite Exporter' )
            RETURN NIL
         ENDIF
         aTable   := sqltablestru( oDB1, 'select * from ' + c2sql( cSQLTable ) )
         nLASTREC := Len( aTable )
         zei_fort( nLASTREC,,, 0 )
         FOR i := 1 TO nLASTREC
            zei_fort( nLASTREC,,, 1 )
            netrecapp()  // append blank
            aRecord := aTable[ i ]
            FOR j := 1 TO Len( aRecord )
               //cFieldName := Left( aStruct[ j, 1 ], 10 )   // dbf nome maximo dez caracteres
               cFieldName := aStruct[ j, 1 ] // Pega o nome tratado na estrutura
               eVALORGRV  := aRecord[ j ]
               if valtype(eVALORGRV)="C" .AND. aStruct[ j, 2 ]="N"
                  eVALORGRV:=VAL(eVALORGRV)
               ENDIF
               REPLACE &cFieldName WITH eVALORGRV //aRecord[ j ]
            NEXT j
         NEXT i
         dbCommit()
         dbUnlock()
         mdt( "Successfully exported" + cNEWTABLE )

         IF nTIPO = 2
            cDESTINO := cSQLTable + "_sqlite" + zEXPOREXT
            MDT( cDESTINO )
            dbSelectAr( "DESTINO" )
            nLASTREC := LastRec()
            zei_fort( nLASTREC,,, 0 )
            dbGoTop()
            multidocg( lDOCCAB, lDOCDAD, lDOCRECNO, cSUBTIPO, TIRAEXT( cDESTINO ), aStruct )
         ENDIF

         dbCloseAll()  // close all
         IF nTIPO = 2
            dbDrop( "mem:destino" )
         ENDIF
         cNewTable := ''
      ENDIF
   ELSE
      msgstop( 'You have to select a Table to export!', 'DBF<-->SQLite Exporter' )
      RETURN NIL
   ENDIF

   RETURN NIL


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function miscsql()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION miscsql( dbo1, qstr )

   IF Empty( dbo1 )
      msgstop( "Database Connection Error!" )
      RETURN .F.
   ENDIF
   sqlite3_exec( dbo1, qstr )
   IF sqlite3_errcode( dbo1 ) > 0  // error
      msgstop( sqlite3_errmsg( dbo1 ) + " Query is : " + qstr )
      RETURN .F.
   ENDIF

   RETURN .T.


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function export2sql()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION export2sql( odb, cDBFFILE, lincdados )

   LOCAL aStruct := {}, i, j, mFldNm, mFldtype, mFldLen, mFldDec, mSql
   LOCAL totrec, nrec, nIndexes

   IF oDB == nil
      msgstop( "No Connection to SQLite DB! Try to create a new SQLite DB or select an existing SQLite DB", 'DBF->SQLite Exporter' )
      RETURN NIL
   ENDIF

   IF ! File( cDBFFILE )
      RETURN NIL
   ENDIF
   
   if valtype(lincdados)<>"L"
      lincdados:=.T.
   endif


   cTablename := HB_FNAMENAME(cDBFFILE) //TIRAEXT( cDBFFILE )


  //cria as tabelas metadados tabela e indice
  aRETUMETA:=GeraSQLMetadata()
  cSqlFields  :=aRETUMETA[1] 
  cSqlIndexes := aRETUMETA[2]
  IF ! Empty( cSqlFields )
     miscsql( oDB,cSqlFields )
  ENDIF   

  IF ! Empty( cSqlIndexes )
     miscsql( oDB,cSqlIndexes )
  ENDIF 


   // Verifica se a tabela 
   aTablesExist := sqltablestru( oDB, "SELECT name FROM sqlite_master WHERE type='table' AND name=" + c2sql(cTablename) )
   
   IF Len( aTablesExist ) > 0
      IF MDG( "Tabela " + cTablename + " ja existe. Deseja exclui-la?" )
         IF sqlite3_exec( oDB, "DROP TABLE IF EXISTS " + cTablename ) == SQLITE_OK
            MDT( "Tabela anterior excluida com sucesso." )
         ELSE
            msgstop( "Erro ao excluir tabela existente!" )
            RETURN NIL
         ENDIF
      ELSE
         // Se o usuário não quiser excluir, cancelamos a importação
         RETURN NIL
      ENDIF
   ENDIF


// Limpar metadados antigos desta tabela específica 
   miscsql( oDB, "DELETE FROM table_metadata WHERE nome_tabela = " + c2sql(cTablename) )
   
   //LIMPA todos os metadados de índices desta tabela
  miscsql( oDB, "DELETE FROM index_metadata WHERE nome_tabela = " + c2sql(cTablename) )

  //abre o dbf para importacao
  dbUseArea( .T., ( cORIDRIVER ), ( cDBFFILE ), , .T. , .F. )   //cARQORI
  aStruct := dbStruct()

  //Grava metadata do dbf
  aMETADBF:=GeradbfSchema( cTablename, aStruct )
   FOR j := 1 TO LEN(aMETADBF)
       mSQL:=aMETADBF[J]
       miscsql( oDB, mSql )
   NEXT J
   

   // cria sql create table
   mSQL := SqliteCreateTable( cTablename, aStruct, "SQLITE" )
   IF !miscsql( oDB, mSql )
      alertx( 'Table Creation Error!', 'DBF2SQLite' )
      MemoWrit( "sql_create_" +cTablename,msql)
      RETURN NIL
   ENDIF

   //roda create index e grava metadado indices
   aINDICES:=GeraINDICES(cTABLENAME)
   nIndexes := LEN(aINDICES)
   FOR j := 1 TO nIndexes
      msql := aINDICES[J,1]  //Create index
      IF ! miscsql( oDB, mSql )
         MemoWrit( "sql_index_create_" +cTablename+"_"+ StrZero( j, 2, 0 ) + ".txt", msql )
      ENDIF
      msql := aINDICES[J,2]  //metadado
      IF ! miscsql( oDB, mSql )
         MemoWrit( "sql" + StrZero( j, 2, 0 ) + ".txt", msql )
      ENDIF
   NEXT j


   //grava dados do dbf com insert into
   IF lincdados
       nLASTREC := RecCount()  // NetRegCount(cOLDDBF)
       zei_fort( nLASTREC,,, 0 )
       dbGoTop()
       IF !miscsql( oDB, 'begin transaction' )
          RETURN NIL
       ENDIF
       DO WHILE !Eof()
          zei_fort( nLASTREC,,, 1 )

          mSql := "INSERT INTO " + cTablename + " VALUES "
          msql := msql + "("
          FOR i := 1 TO Len( aStruct )
             mFldNm := aStruct[ i, DBS_NAME ]
             IF i > 1
                mSql += ", "
             ENDIF
             mSql += c2sql( &mFldNm )
          NEXT
          mSql += ")"
          IF ! miscsql( oDB, mSql )
             alertx( "Problem in Query: " + mSql )
             RETURN NIL
          ENDIF
          dbSkip()
       ENDDO
       IF !miscsql( oDB, 'end transaction' )
          RETURN NIL
       ENDIF
   endif   
   dbCloseAll()

   RETURN NIL



// +--------------------------------------------------------------------
// +
// +    Function MDPCHAVEI()
// +
// +--------------------------------------------------------------------
// +
FUNCTION MDPCHAVEI( cICHAVE )   // Cria string campo1,campo2,... para create index em sql

   LOCAL nPOS
   LOCAL cCHAVE
   LOCAL cTMPCHV
   LOCAL aICampos
   LOCAL I

   cCHAVE   := ""
   aicampos := hb_ATokens( cICHAVE, "+" )
   FOR I := 1 TO Len( aICampos )
      cTMPCHV := aICampos[ I ]
      nPOS    := At( "(", cTMPCHV )
      IF nPOS >= 0
         cTMPCHV := SubStr( cTMPCHV, nPOS + 1 )
      ENDIF
      nPOS := At( "(", cTMPCHV )
      IF nPOS > 0
         cTMPCHV := SubStr( cTMPCHV, nPOS + 1 )
      ENDIF
      nPOS := At( ")", cTMPCHV )
      IF nPOS > 0
         cTMPCHV := SubStr( cTMPCHV, 1, nPOS - 1 )
      ENDIF
      nPOS := At( ",", cTMPCHV )
      IF nPOS > 0
         cTMPCHV := SubStr( cTMPCHV, 1, nPOS - 1 )
      ENDIF
      cCHAVE += cTMPCHV
      IF I <> Len( aICAMPOS )
         cCHAVE += ","
      ENDIF
   NEXT I

   RETURN cCHAVE






// + EOF: sql2dbf.prg
// +
