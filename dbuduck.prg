// +--------------------------------------------------------------------
// +
// +    Programa  : dbuduck.prg
// +    Sistema   : Utilitário de Gerenciamento DuckDB para Harbour
// +    Linguagem : Harbour
// +    Autor     : jcassiano (Adaptado para DuckDB)
// +--------------------------------------------------------------------

#include "BOX.CH"
#include "TRY.CH"
#include "dbstruct.ch"
#include "directry.ch"


// +--------------------------------------------------------------------
// +    Function duckdbmenu()
// +--------------------------------------------------------------------
FUNCTION Duckdbmenu()

   LOCAL aAMBIENTE
   LOCAL KEY

   aAMBIENTE  := SALVAA() 
   cSERVERX   := PADR("LOCAL",30)  
   cDATABASEX := PADR("dados.duckdb",30) // Caminho padrão do arquivo DuckDB
   cUSERX     := PADR("",30)           // DuckDB não usa usuário/senha
   cPASSX     := PADR("",30)
   cTABELAX   := Space(30) 
   cBANCOX    := Space(30) 
   cOWNERX    := Space(30)
   cPORTAX    := SPACE(30)
   cPATH      := "" 
   loledb     := .T. 
   lMDB       := .F. 
   lACCDB     := .F. 
   lFDB       := .F.

   cOLDRDD     := RDDSETDEFAULT("DUCKDB") 
   nOLDTIPORDD := TIPODBF 
   cTIPOSQL    := "DUCKDB"  // Define a global para as funções de dialeto

   // Busca as credenciais e o caminho do banco dinamicamente via cofre do sistema se houver
   IF IsFunction("pegcfgbanco")
      pegcfgbanco() 
   ENDIF

   WHILE .T.
      hb_DispBox(3,18,18,55,B_DOUBLE+" ") 
      @ 03,24 SAY "DUCKDB " + ALLTRIM(cDATABASEX) 
      
      OPCAO( 4, 24, "&Criar Database            ", 67 )   // C 1
      OPCAO( 5, 24, "&Database Selecionar       ", 68 )   // D 2
      OPCAO( 6, 24, "&Tabelas                   ", 84 )   // T 3
      OPCAO( 7, 24, "&Importar  DBF             ", 73 )   // I 4
      OPCAO( 8, 24, "&Exportar  DBF             ", 69 )   // E 5
      OPCAO( 9, 24, "&Apagar Tabela             ", 65 )   // A 6
      OPCAO(10, 24, "Exportar &Formatos         ", 70 )   // F 7
      OPCAO(11, 24, "&Versao Info               ", 86 )   // V 8
      OPCAO(12, 24, "Executar arquivo &SQL      ", 83 )   // S 9
      OPCAO(13, 24, "&Ler arquivo CSV           ", 76 )   // L 10
      OPCAO(14, 24, "&Gravar arquivo CSV        ", 71 )   // G 11
      OPCAO(15, 24, "&Ler arquivo JSON          ", 74 )   // J 12
      OPCAO(16, 24, "&Gravar arquivo JSON       ", 79 )   // O 13  
      OPCAO(17, 24, "L&er arquivo Parquet       ", 69 )   // 14
      OPCAO(18, 24, "G&ravar arquivo Parquet    ", 71 )   // 15
      
      
      KEY := menu(1,0) 
      DO CASE
      CASE KEY = 1
         duckcreate()
      CASE KEY = 2
         // Seleção de arquivo físico .duckdb
         cDATABASEX := win_GetOpenFileName(, "DuckDB Files", HB_CWD(), "DuckDB", {{'DuckDB Database','*.duckdb'},{'All Files','*.*'}}, 1)
         IF Empty(cDATABASEX)
            cDATABASEX := PADR("dados.duckdb",30)
         ENDIF
      CASE KEY = 3
         duckTABELAS() 
      CASE KEY = 4
         duckimpdbf()
      CASE KEY = 5
         duckexpdbf( 1 )
      CASE KEY = 6
         duckdeltable()
      CASE KEY = 7
         duckexpdbf( 2 )
      CASE KEY = 8
         duckverinfo()
      CASE KEY = 9
         duckExecArqSql()
      CASE KEY = 10
         duckChamaLerCSV() // Função de interface intermediária (opcional)
      CASE KEY = 11
         duckChamaGravarCSV() // Função de interface intermediária (opcional)   
      CASE KEY = 12
         duckChamaLerJSON()
      CASE KEY = 13
         duckChamaGravarJSON()        
     CASE KEY = 14
         duckChamaLerParquet()
      CASE KEY = 15
         duckChamaGravarParquet()    
      OTHERWISE
         EXIT 
      ENDCASE
   ENDDO 

   TIPODBF := nOLDTIPORDD 
   rddSetDefault(cOLDRDD) 
   RDDNOME(TIPODBF) 

   RESTAA(aAMBIENTE) 
   LAYOUT() 

RETURN .T. 


// +--------------------------------------------------------------------
// +    Interface: Parquet
// +--------------------------------------------------------------------
FUNCTION duckChamaLerParquet()
   LOCAL cArqParquet := win_GetOpenFileName( , "Selecione o arquivo Parquet", HB_CWD(), "Parquet Files", ;
      {{'Arquivos Parquet','*.parquet'},{'Todos os Arquivos','*.*'}}, 1)

   IF !Empty( cArqParquet )
      ducklerparquet( cArqParquet, NIL )
   ENDIF
RETURN .T.

FUNCTION duckChamaGravarParquet()
   LOCAL cArqDestino
   duckTABELAS() 
   IF Empty( cTABELAX )
      Alert( "Selecione uma tabela primeiro!" )
      RETURN .F.
   ENDIF

   cArqDestino := win_GetSaveFileName( , "Salvar Parquet como", HB_CWD(), "Parquet Files", ;
      {{'Arquivos Parquet','*.parquet'},{'Todos os Arquivos','*.*'}}, 1)

   IF !Empty( cArqDestino )
      IF !( Lower(Right(cArqDestino, 8)) == ".parquet" )
         cArqDestino += ".parquet"
      ENDIF
      duckgravarparquet( cArqDestino, AllTrim(cTABELAX) )
   ENDIF
RETURN .T.

// +--------------------------------------------------------------------
// +    Motor: Parquet (com CHECKPOINT)
// +--------------------------------------------------------------------
FUNCTION ducklerparquet( cArquivo, cTabela )
   LOCAL oServer, cSql

   IF Empty( cTabela )
      hb_FNameSplit( cArquivo, nil, @cTabela, NIL )
      cTabela := AllTrim( cTabela )
   ENDIF

   oServer := duckconnect()
   IF oServer == NIL; RETURN .F.; ENDIF

   IF oServer:TableExists( cTabela )
      oServer:Execute( "DROP TABLE " + cTabela )
   ENDIF

   // Importação otimizada do Parquet
   cSql := "CREATE TABLE " + cTabela + " AS SELECT * FROM read_parquet('" + cArquivo + "');"
   oServer:Execute( cSql )

   oServer:Commit()
   
   // SUGESTÃO 6: Força a gravação do WAL no disco principal para manter o banco compacto
   oServer:Execute( "CHECKPOINT;" ) 
   
   oServer:Close()
   MDT( "Arquivo Parquet importado com sucesso: " + cTabela )
RETURN .T.

FUNCTION duckgravarparquet( cArquivo, cTabela )
   LOCAL oServer, cSql
   oServer := duckconnect()
   IF oServer == NIL; RETURN .F.; ENDIF

   // Exportação colunar nativa
   cSql := "COPY " + cTabela + " TO '" + cArquivo + "' (FORMAT PARQUET);"
   oServer:Execute( cSql )

   oServer:Close()
   MDT( "Tabela exportada para Parquet com sucesso!" )
RETURN .T.
// +--------------------------------------------------------------------
// +    Function duckChamaLerJSON()
// +--------------------------------------------------------------------
FUNCTION duckChamaLerJSON()
   LOCAL cArqJSON

   cArqJSON := win_GetOpenFileName( , "Selecione o arquivo JSON", HB_CWD(), "JSON Files", ;
      {{'Arquivos JSON','*.json'},{'Todos os Arquivos','*.*'}}, 1)

   IF !Empty( cArqJSON )
      // Passamos o arquivo para a engine. Como não enviamos estrutura, fará auto-detect.
      ducklerjson( cArqJSON, NIL, NIL )
   ELSE
      MDT( "Importacao de JSON cancelada." )
   ENDIF

RETURN .T.

// +--------------------------------------------------------------------
// +    Function duckChamaGravarJSON()
// +--------------------------------------------------------------------
FUNCTION duckChamaGravarJSON()
   LOCAL cArqDestino

   // Seleciona tabela atual
   duckTABELAS() 
   
   IF Empty( cTABELAX )
      Alert( "Selecione uma tabela primeiro!" )
      RETURN .F.
   ENDIF

   cArqDestino := win_GetSaveFileName( , "Salvar arquivo JSON como", HB_CWD(), "JSON Files", ;
      {{'Arquivos JSON','*.json'},{'Todos os Arquivos','*.*'}}, 1)

   IF !Empty( cArqDestino )
      IF !( Lower(Right(cArqDestino, 5)) == ".json" )
         cArqDestino += ".json"
      ENDIF

      duckgravarjson( cArqDestino, AllTrim(cTABELAX) )
   ELSE
      MDT( "Exportacao de JSON cancelada." )
   ENDIF

RETURN .T.

// +--------------------------------------------------------------------
// +    Function duckChamaGravarCSV()
// +--------------------------------------------------------------------
FUNCTION duckChamaGravarCSV()
   LOCAL cArqDestino

   // Verifica se o usuário selecionou uma tabela previamente no menu (variavel global cTABELAX)
   duckTABELAS() 
   
   IF Empty( cTABELAX )
      Alert( "Selecione uma tabela primeiro!" )
      RETURN .F.
   ENDIF

   // Pede ao usuário o local e nome para salvar o novo CSV
   cArqDestino := win_GetSaveFileName( , "Salvar arquivo CSV como", HB_CWD(), "CSV Files", ;
      {{'Arquivos CSV','*.csv'},{'Todos os Arquivos','*.*'}}, 1)

   IF !Empty( cArqDestino )
      // Garante que a extensão .csv esteja no nome
      IF !( Lower(Right(cArqDestino, 4)) == ".csv" )
         cArqDestino += ".csv"
      ENDIF

      // Chama a função de gravação passando o arquivo, a tabela atual e o delimitador padrão
      duckgravarcsv( cArqDestino, AllTrim(cTABELAX), "|" )
   ELSE
      MDT( "Exportacao de CSV cancelada." )
   ENDIF

RETURN .T.


// +--------------------------------------------------------------------
// +    Function ducklerjson( cArquivo, cTabela, aStruct )
// +--------------------------------------------------------------------
FUNCTION ducklerjson( cArquivo, cTabela, aStruct )
   LOCAL oServer, cSql, cCampos := "", i

   IF Empty( cArquivo )
      RETURN .F.
   ENDIF

   IF Empty( cTabela )
      hb_FNameSplit( cArquivo, nil, @cTabela, NIL )
      cTabela := AllTrim( cTabela )
   ENDIF

   oServer := duckconnect()
   IF oServer == NIL
      RETURN .F.
   ENDIF

   IF oServer:TableExists( cTabela )
      oServer:Execute( "DROP TABLE " + cTabela )
   ENDIF

   IF Empty( aStruct ) 
      // MODO AUTO: O DuckDB infere as chaves, níveis e tipos (funciona tanto para arrays quanto objetos aninhados)[cite: 6]
      cSql := "CREATE TABLE " + cTabela + " AS SELECT * FROM read_json('" + cArquivo + "', auto_detect=true);"
      oServer:Execute( cSql )
   ELSE 
      // MODO ESTRUTURA MANUAL
      FOR i := 1 TO Len( aStruct )
         cCampos += aStruct[i, 1] + " " + duck_map_type_json( aStruct[i, 2], aStruct[i, 3], aStruct[i, 4] )
         IF i < Len( aStruct )
            cCampos += ", "
         ENDIF
      NEXT

      cSql := "CREATE TABLE " + cTabela + " (" + cCampos + ");"
      oServer:Execute( cSql )

      // A clausula FORMAT JSON sinaliza ao motor de COPY como importar[cite: 6]
      cSql := "COPY " + cTabela + " FROM '" + cArquivo + "' (FORMAT JSON);"
      oServer:Execute( cSql )
   ENDIF

   oServer:Commit()
   oServer:Close()
   
   MDT( "Arquivo JSON importado com sucesso para a tabela: " + cTabela )
RETURN .T.

// +--------------------------------------------------------------------
// +    Function duckgravarjson( cArquivo, cTabela )
// +--------------------------------------------------------------------
FUNCTION duckgravarjson( cArquivo, cTabela )
   LOCAL oServer, cSql
   
   // Proteção extra caso a função seja chamada diretamente via código
   IF Empty( cTabela ) .OR. Empty( cArquivo )
      RETURN .F.
   ENDIF

   oServer := duckconnect()
   IF oServer == NIL
      RETURN .F.
   ENDIF

   // Gravamos usando COPY nativo do DuckDB. 
   // FORMAT JSON e ARRAY true criam um Array de Objetos JSON limpo e formatado!
   cSql := "COPY " + cTabela + " TO '" + cArquivo + "' (FORMAT JSON, ARRAY true);"
   
   IF oServer:Execute( cSql )
      MDT( "Tabela " + cTabela + " exportada para " + cArquivo + " com sucesso!" )
   ELSE
      Alert( "Erro ao exportar arquivo JSON: " + oServer:Error() )
   ENDIF

   oServer:Close()
RETURN .T.

// +--------------------------------------------------------------------
// Função auxiliar (pode ser omitida se você renomear a do CSV para geral)
// +--------------------------------------------------------------------
STATIC FUNCTION duck_map_type_json( cTipo, nTam, nDec )
   SWITCH cTipo
      CASE "C"; RETURN "VARCHAR"
      CASE "N"
         IF nDec > 0; RETURN "DOUBLE"; ELSE; RETURN "INTEGER"; ENDIF
      CASE "D"; RETURN "DATE"
      CASE "L"; RETURN "BOOLEAN"
      CASE "M"; RETURN "VARCHAR"
   ENDSWITCH
RETURN "VARCHAR"

// +--------------------------------------------------------------------
// +    Function duckChamaLerCSV()
// +--------------------------------------------------------------------
FUNCTION duckChamaLerCSV()
   LOCAL cArqCSV

   // Abre a caixa de diálogo do Windows para o usuário procurar o CSV
   cArqCSV := win_GetOpenFileName( , "Selecione o arquivo CSV", HB_CWD(), "CSV Files", ;
      {{'Arquivos CSV','*.csv'},{'Todos os Arquivos','*.*'}}, 1)

   // Se o usuário selecionou um arquivo e não cancelou
   IF !Empty( cArqCSV )
      // Passa apenas o arquivo. Tabela, delimitador e estrutura ficam NIL para o DuckDB resolver
      ducklercsv( cArqCSV, NIL, NIL, NIL )
   ELSE
      MDT( "Importacao de CSV cancelada." )
   ENDIF

RETURN .T.

// +--------------------------------------------------------------------
// +    Function duckcreate()
// +--------------------------------------------------------------------
FUNCTION duckcreate()
   LOCAL cARQORI

   cARQORI := win_GetsaveFileName(, "DuckDB Files", HB_CWD(), "DuckDB", ;
      {{'DuckDB Database','*.duckdb'},{'All Files','*.*'}}, 1)  

   IF !Empty(cARQORI)
      cDATABASEX := cARQORI
      // No DuckDB, criar o banco significa apenas abri-lo pela primeira vez; 
      // a engine cria o arquivo físico no disco automaticamente no primeiro Execute/Connect.
      oServer := DuckDBClass():New( AllTrim(cARQORI) )
      IF oServer != NIL .AND. !oServer:NetErr()
         MDT("Base de dados DuckDB criada/aberta com sucesso!")
         oServer:Close()
      ELSE
         Alert("Erro ao criar base DuckDB.")
      ENDIF
   ENDIF

RETURN .T.


// +--------------------------------------------------------------------
// +    Function duckgravarcsv( cArquivo, cTabela, cDelim )
// +--------------------------------------------------------------------
FUNCTION duckgravarcsv( cArquivo, cTabela, cDelim )
   LOCAL oServer, cSql
   
   IF Empty( cTabela ) .OR. Empty( cArquivo )
      RETURN .F.
   ENDIF

   IF Empty( cDelim )
      cDelim := "|" // Delimitador padrão
   ENDIF

   oServer := duckconnect()
   IF oServer == NIL
      RETURN .F.
   ENDIF

   // Usamos a instrução COPY do DuckDB para gravar o CSV nativamente[cite: 4]
   cSql := "COPY " + cTabela + " TO '" + cArquivo + "' (HEADER, DELIMITER '" + cDelim + "');"
   
   IF oServer:Execute( cSql )
      MDT( "Tabela " + cTabela + " exportada para " + cArquivo )
   ELSE
      Alert( "Erro ao exportar arquivo CSV." )
   ENDIF

   oServer:Close()
RETURN .T.

// +--------------------------------------------------------------------
// +    Function ducklercsv( cArquivo, cTabela, cDelim, aStruct )
// +--------------------------------------------------------------------
FUNCTION ducklercsv( cArquivo, cTabela, cDelim, aStruct )
   LOCAL oServer, cSql, cCampos := "", i

   // 1. Validar Arquivo
   IF Empty( cArquivo )
      RETURN .F.
   ENDIF

   // 2. Definir Nome da Tabela se não passado
   IF Empty( cTabela )
      hb_FNameSplit( cArquivo, nil, @cTabela, NIL )
      cTabela := AllTrim( cTabela )
   ENDIF

   oServer := duckconnect()
   IF oServer == NIL
      RETURN .F.
   ENDIF

   // Derruba a tabela se ela já existir para recriar
   IF oServer:TableExists( cTabela )
      oServer:Execute( "DROP TABLE " + cTabela )
   ENDIF

   // 3 & 4. Tratar Estrutura e Delimitador
   IF Empty( aStruct ) 
      // MODO AUTO: O DuckDB infere as colunas automaticamente
      cSql := "CREATE TABLE " + cTabela + " AS SELECT * FROM read_csv('" + cArquivo + "', auto_detect=true"
      
      IF !Empty( cDelim )
         // Se o delimitador for passado, força o uso[cite: 4]
         cSql += ", delim='" + cDelim + "'"
      ENDIF
      
      cSql += ");"
      oServer:Execute( cSql )
      
   ELSE 
      // MODO ESTRUTURA: Converte array do Clipper/Harbour para SQL
      FOR i := 1 TO Len( aStruct )
         cCampos += aStruct[i, 1] + " " + duck_map_type_csv( aStruct[i, 2], aStruct[i, 3], aStruct[i, 4] )
         IF i < Len( aStruct )
            cCampos += ", "
         ENDIF
      NEXT

      // Cria a tabela
      cSql := "CREATE TABLE " + cTabela + " (" + cCampos + ");"
      oServer:Execute( cSql )

      // Importa usando COPY[cite: 4]
      cSql := "COPY " + cTabela + " FROM '" + cArquivo + "' (HEADER true"
      IF !Empty( cDelim )
         cSql += ", DELIMITER '" + cDelim + "'"
      ENDIF
      cSql += ");"
      
      oServer:Execute( cSql )
   ENDIF

   oServer:Commit()
   oServer:Close()
   
   MDT( "Arquivo CSV importado com sucesso para a tabela: " + cTabela )
RETURN .T.

// Função auxiliar para mapear tipos do Harbour para SQL compatível com DuckDB
STATIC FUNCTION duck_map_type_csv( cTipo, nTam, nDec )
   SWITCH cTipo
      CASE "C"; RETURN "VARCHAR"
      CASE "N"
         IF nDec > 0; RETURN "DOUBLE"; ELSE; RETURN "INTEGER"; ENDIF
      CASE "D"; RETURN "DATE"
      CASE "L"; RETURN "BOOLEAN"
      CASE "M"; RETURN "VARCHAR"
   ENDSWITCH
RETURN "VARCHAR"

// +--------------------------------------------------------------------
// +    Function duckconnect()
// +--------------------------------------------------------------------
STATIC FUNCTION duckconnect()
   LOCAL oServer

   // Instancia a classe DuckDBClass usando o caminho do arquivo físico (ou vazio para memória)
   oServer := DuckDBClass():New( AllTrim(cDATABASEX) )

   IF oServer:NetErr()
      Alert( "Falha na conexao com DuckDB: " + oServer:Error() )
      RETURN NIL
   ENDIF

   // Inicia transação padrão para segurança das operações
   oServer:StartTransaction()

RETURN oServer

// +--------------------------------------------------------------------
// +    Function duckverinfo()
// +--------------------------------------------------------------------
FUNCTION duckverinfo()
   LOCAL oServer
   LOCAL cVersionInfo := ""

   oServer := duckconnect()
   IF oServer != NIL
      cVersionInfo := oServer:GetServerInfo()
      
      IF Empty( cVersionInfo )
         cVersionInfo := "Nao foi possivel ler os detalhes da versao."
      ENDIF

      MDT( "Conectado com Sucesso!#Versao: " + AllTrim( cVersionInfo ) )
      oServer:Close()
   ELSE
      MDT( "Falha ao obter informacoes do servidor." )
   ENDIF

RETURN .T.


// +--------------------------------------------------------------------
// +    Function duckTABELAS()
// +--------------------------------------------------------------------
FUNCTION duckTABELAS( lNATIVE )
   LOCAL oServer, aTABELAS := {}
   LOCAL cSchemaBusca

   IF VALTYPE( lNATIVE ) <> "L"
      lNATIVE := .T.
   ENDIF

   // TRAVA: Se estiver vazio ou só com espaços, assume 'main'. Senão, limpa os espaços.
   cSchemaBusca := iif( Empty( cUSERX ), "main", Lower( AllTrim( cUSERX ) ) )

   IF lNATIVE
      oServer := duckconnect()
      IF oServer != NIL
         
         // Passa o schema já validado e travado
         aTABELAS := oServer:ListTables( cSchemaBusca )
         
         IF !Empty( aTABELAS )
            mdbtabela( aTABELAS ) 
         ELSE
            MDT( "Nenhuma tabela encontrada no schema (" + cSchemaBusca + ")." )
         ENDIF
         
         oServer:Close()
      ENDIF
   ELSE
      mdbtabela( cDATABASEX )
   ENDIF
   
RETURN .T.

// +--------------------------------------------------------------------
// +    Function duckTABELAS()
// +--------------------------------------------------------------------
FUNCTION duckTABELAS( lNATIVE )
   LOCAL oServer, aTABELAS := {}

   IF VALTYPE( lNATIVE ) <> "L"
      lNATIVE := .T.
   ENDIF

   IF lNATIVE
      oServer := duckconnect()
      IF oServer != NIL
         aTABELAS := oServer:ListTables()
         
         IF !Empty( aTABELAS )
            mdbtabela( aTABELAS ) 
         ELSE
            MDT( "Nenhuma tabela encontrada." )
         ENDIF
         
         oServer:Close()
      ENDIF
   ELSE
      mdbtabela( cDATABASEX )
   ENDIF
   
RETURN .T.

// +--------------------------------------------------------------------
// +    Function duckimpdbf()
// +--------------------------------------------------------------------
FUNCTION duckimpdbf()
   LOCAL nOLDTIPO, nORITIPO, cORIDRIVER, lincdados, cARQORI, cPASTA
   
   nOLDTIPO := TIPODBF
   alertX( "Escolha origem" )
   tipodbfesc()
   nORITIPO   := TIPODBF
   cORIDRIVER := RDDNOME( TIPODBF )
   lincdados  := mdg("Incluir Dados")
   
   IF MDG("Arquivo individual")
      cARQORI := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*."+TABLEEXT, 1 )
      IF File( cARQORI )
         duck_impdbf( cARQORI, lincdados )
      ENDIF
   ELSE
      cPASTA := SelectFolder()
      cPASTA += "\*."+TABLEEXT 
      FAZERDBF( {|| duck_impdbf(cCAMINHOCOMPLETO, lincdados) }, .F., ,, cPASTA, .F. )
   ENDIF   
   
   RDDNOME( nOLDTIPO )

RETURN .T.

// +--------------------------------------------------------------------
// +    Function duck_impdbf()
// +--------------------------------------------------------------------
FUNCTION duck_impdbf( cARQORI, lincdados )
   LOCAL oServer
   LOCAL aINDICES := {}
   LOCAL msql, cTABLE
   LOCAL i, j, nCont, aSTRU, nLASTREC, aRETUMETA, cSqlFields, cSqlIndexes, aMETADBF

   cTABLE := Space( 30 )

   IF Empty( cARQORI )
      RETURN .F.
   ENDIF

   hb_FNameSplit( cARQORI, nil, @cTable, NIL )
   cTABLE := AllTrim( cTABLE )

   dbUseArea( .T., cORIDRIVER, cARQORI, cTABLE, .T., .T. )
   aSTRU    := dbStruct()
   nLASTREC := RecCount()
   zei_fort( nLASTREC,,, 0 )

   IF IsFunction("GeraINDICES")
      aINDICES := GeraINDICES()
   ENDIF

   oServer := duckconnect()
   IF oServer == NIL
      dbCloseArea()
      RETURN .F.
   ENDIF

   // Criação opcional de tabelas de metadados padrão se a função existir no seu sistema
   IF IsFunction("GeraSQLMetadata")
      aRETUMETA := GeraSQLMetadata()
      cSqlFields  := aRETUMETA[1] 
      cSqlIndexes := aRETUMETA[2]
      
      IF !Empty( cSqlFields )
         oServer:Execute( cSqlFields )
      ENDIF   
      IF !Empty( cSqlIndexes )
         oServer:Execute( cSqlIndexes )
      ENDIF 
   ENDIF

   // Se a tabela já existir, remove para recriar
   IF oServer:TableExists( cTABLE )
      IF !MDG("Excluir tabela existente " + cTABLE)
         dbCloseArea()
         oServer:Close()
         RETURN .F.
      ELSE
         oServer:Execute( "DROP TABLE " + cTABLE )
      ENDIF  
   ENDIF

   // Gera a estrutura DDL adaptada para o DuckDB
   IF IsFunction("SqliteCreateTable")
      msql := SqliteCreateTable( cTABLE, aSTRU, "DUCKDB" )
   ELSE
      msql := "CREATE TABLE " + cTABLE + " (id INTEGER);"
   ENDIF
   
   HB_memowrit("create_duckdb_" + cTABLE + ".SQL", msql, .F.)

   // Executa o DDL de criação
   oServer:Execute( msql )

   // Criação dos índices coletados
   FOR i := 1 TO Len( aINDICES )
      TRY
         oServer:Execute( aINDICES[i,1] )
      CATCH
         MDT("Erro ao criar indice: " + aINDICES[i,1])   
      END
   NEXT i

   // Importação dos dados
   nCont := 0
   dbSelectArea( cTABLE )
   dbGoTop()

   IF lincdados
      WHILE !Eof()
         zei_fort( nLASTREC,,, 1 )
         
         msql := "INSERT INTO " + cTABLE + " VALUES ("
         FOR i := 1 TO Len( aSTRU )
            IF i > 1
               msql += ", "
            ENDIF
            msql += DataToSql( & ( aSTRU[i, DBS_NAME] ) )
         NEXT i
         msql += ")"
         
         oServer:Execute( msql )
         
         nCont++
         dbSkip()
      ENDDO
   ENDIF

   oServer:Commit()
   dbCloseArea()
   oServer:Close()

   MDT( "Importacao para DuckDB concluida com sucesso!" )
RETURN .T.

// +--------------------------------------------------------------------
// +    Function duckexpdbf()
// +--------------------------------------------------------------------
FUNCTION duckexpdbf( nTipo )
   LOCAL oServer, oQuery, oRow
   LOCAL aSTRU := {}
   LOCAL aVALOR
   LOCAL i, nFIM, cDESTINO, eVALOR, nLASTREC
   LOCAL aStructInfo

   oServer := duckconnect()
   IF oServer == NIL
      RETURN .F.
   ENDIF

   duckTABELAS() 

   oQuery := oServer:Query( "SELECT * FROM " + AllTrim(cTABELAX) )
   IF oServer:NetErr()
      Alert( "Erro ao ler tabela: " + oServer:Error() )
      oServer:Close()
      RETURN .F.
   ENDIF

   nLASTREC := oQuery:LastRec()
   zei_fort( nLASTREC,,, 0 )

   // Obtém estrutura para exportação
   aStructInfo := oServer:TableStruct( AllTrim(cTABELAX) )
   
   FOR i := 1 TO Len(aStructInfo)
      AAdd( aSTRU, { aStructInfo[i, 1], aStructInfo[i, 2], aStructInfo[i, 3], aStructInfo[i, 4] } )
   NEXT i

   nFIM := Len( aSTRU )
   cDESTINO := AllTrim(cTABELAX) + "_DUCKDB"

   IF nTipo == 1
      MDT( cDESTINO )
      dbCreate( cDESTINO, aSTRU, "DBFCDX" )
      dbUseArea( .T., "DBFCDX", cDESTINO, "DESTINO", .T., .F. )
   ELSE
      dbCreate( "mem:destino", aSTRU,, .T., "DESTINO" )
   ENDIF

   oQuery:GoTop()
   DO WHILE !oQuery:Eof()
      aVALOR := {}
      oRow := oQuery:GetRow()
      
      FOR i := 1 TO nFIM
         AAdd( aVALOR, oRow:FieldGet( i ) )
      NEXT i
      
      dbSelectArea( "DESTINO" )
      NETRECAPP()
      
      FOR i := 1 TO nFIM
         eVALOR := aVALOR[i]
         
         IF eVALOR == NIL
            IF aSTRU[i, DBS_TYPE] == "C"
               eVALOR := Space( aSTRU[i, DBS_LEN] )
            ELSEIF aSTRU[i, DBS_TYPE] == "N"
               eVALOR := 0
            ELSEIF aSTRU[i, DBS_TYPE] == "D"
               eVALOR := CToD("")
            ELSEIF aSTRU[i, DBS_TYPE] == "L"
               eVALOR := .F.
            ELSEIF aSTRU[i, DBS_TYPE] == "M"
               eVALOR := ""
            ENDIF
         ENDIF
         
         IF !Empty( eVALOR )
            FieldPut( i, eVALOR )
         ENDIF
      NEXT i
      
      zei_fort( nLASTREC,,, 1 )
      oQuery:Skip()
   ENDDO

   oQuery:Destroy()
   oServer:Close()

   dbSelectArea( "DESTINO" )
   dbCloseArea()

   IF nTipo == 2
      dbDrop( "mem:destino" )
   ENDIF

   MDT( "Exportacao concluida!" )
RETURN .T.

// +--------------------------------------------------------------------
// +    Function duckdeltable()
// +--------------------------------------------------------------------
FUNCTION duckdeltable()
   LOCAL oServer

   oServer := duckconnect()
   IF oServer == NIL
      RETURN .F.
   ENDIF

   duckTABELAS() 
   IF !MDG( "Apagar Tabela " + AllTrim(cTABELAX) + "?" )
      oServer:Close()
      RETURN .F.
   ENDIF

   IF oServer:TableExists( AllTrim(cTABELAX) )
      oServer:Execute( "DROP TABLE " + AllTrim(cTABELAX) )
      MDT( "Tabela eliminada com sucesso." )
   ELSE
      Alert( "Tabela nao encontrada no banco de dados." )
   ENDIF

   oServer:Close()
RETURN .T.

// +--------------------------------------------------------------------
// +    Function duckExecArqSql()
// +--------------------------------------------------------------------
FUNCTION duckExecArqSql()
   LOCAL cCOMANDO := ""
   LOCAL cARQIMP  := ""
   LOCAL oServer

   cARQIMP := win_GetOPENFileName(, "Arquivos SQL", HB_CWD(), "Arquivos SQL", "*.SQL", 1)

   IF FILE(cARQIMP)
      cCOMANDO := MEMOREAD(cARQIMP)
      oServer  := duckconnect()
      duckexecuteSQL( cCOMANDO )
      oServer:Close()
   ENDIF

RETURN .T.

// +--------------------------------------------------------------------
// +    Function duckexecuteSQL()
// +--------------------------------------------------------------------
FUNCTION duckexecuteSQL( eCOMANDO, lTRANS )
   LOCAL aCOMANDOS := {}
   LOCAL nFIM, i
   LOCAL lRet := .T.
   LOCAL oServer

   IF ValType( lTRANS ) <> "L"
      lTRANS := .F.
   ENDIF
   
   IF ValType( eCOMANDO ) = "C"
      AAdd( aCOMANDOS, eCOMANDO )
   ELSE
      aCOMANDOS := eCOMANDO
   ENDIF
   
   nFIM := Len( aCOMANDOS )
   oServer := duckconnect()
   
   IF oServer == NIL
      RETURN .F.
   ENDIF
   
   IF lTRANS
      oServer:StartTransaction()
   ENDIF
   
   FOR i := 1 TO nFIM
      cCOMANDO := aCOMANDOS[ i ]
      oServer:Execute( cCOMANDO )
   NEXT i
   
   IF lTRANS
      oServer:Commit()
   ENDIF
   
   oServer:Close()
RETURN lRet


STATIC FUNCTION DataToSql( xField )
   SWITCH ValType( xField )
   CASE "C"; CASE "M"
      RETURN "'" + StrTran( xField, "'", "''" ) + "'"
   CASE "D"
      IF Empty( xField ); RETURN "NULL"; ENDIF
      RETURN "'" + StrZero( Year( xField ), 4 ) + "-" + StrZero( Month( xField ), 2 ) + "-" + StrZero( Day( xField ), 2 ) + "'"
   CASE "N"
      RETURN Str( xField )
   CASE "L"
      RETURN iif( xField, "TRUE", "FALSE" )
   CASE "A"; CASE "H"
      // Serializa Array e Hash do Harbour para JSON. 
      // O DuckDB faz o casting automático para LIST, STRUCT ou MAP internamente.
      RETURN "'" + hb_jsonEncode( xField, .F. ) + "'"
   ENDSWITCH
RETURN "NULL"

