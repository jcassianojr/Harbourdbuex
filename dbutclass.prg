// +--------------------------------------------------------------------
// +
// +  harbour builder tdclass https://github.com/FiveTechSoft/HarbourBuilder 
// +
// +
// +--------------------------------------------------------------------
// +


// +--------------------------------------------------------------------
// +    Programa  : dbutclass.prg
// +    Objetivo  : TDatabase OOP
// +--------------------------------------------------------------------

#include "simpleio.ch"
#include "BOX.CH"
#include "TRY.CH"
#include "dbstruct.ch"



// +--------------------------------------------------------------------
// +    Function tclassmenu()
// +--------------------------------------------------------------------
FUNCTION tclassmenu( cUSOSQL )
      PUBLIC oDb
      aAMBIENTE  := SALVAA() 
      cSERVERX   := Space(30) // localhost:cARQUIVO no connection
      cDATABASEX := Space(30) 
      cUSERX     := Space(30)
      cPASSX     := Space(30)
      cTABELAX   := Space(30) 
      cBANCOX    := Space(30) 
      cOWNERX   := Space(30)
      cPORTAX    :=SPACE(30)
      cPATH      := "" 
      loledb     := .T. 
      lMDB       := .F. 
      lACCDB     := .F. 
      lFDB       := .T.

   DO CASE
      CASE cTIPOSQL == "MYSQL"
      CASE cTIPOSQL == "MARIADB"
      CASE cTIPOSQL == "SQLITE"
      CASE cTIPOSQL == "PGSQL"
      CASE cTIPOSQL == "MSSQL"
      CASE lFDB //Firebird 
      CASE cTIPOSQL == "ORACLE"
       //CASE cTIPOSQL == "MONGODB"   
       //   oDb := TMongoDB():New()
       OTHERWISE
         ALERT("Nao suportado")
         RETURN
      // Adicionar outros conforme classes implementadas
   ENDCASE




      cOLDRDD     := RDDSETDEFAULT("") 
      nOLDTIPORDD := TIPODBF 


      cTIPOSQL := cUSOSQL



   
    // Busca as credenciais e o caminho do banco dinamicamente via cofre do sistema
     pegcfgbanco() 

  
   

   WHILE .T.
      hb_DispBox( 3, 18, 18, 55, B_DOUBLE + " " )
      @ 03, 24 SAY "TCLASS " + cTIPOSQL
      OPCAO( 4, 24, "&Criar database            ", 67 )
      OPCAO( 5, 24, "&Importar DBF              ", 73 )
      OPCAO( 6, 24, "&Tabelas                   ", 84 )
      OPCAO( 7, 24, "&Exportar DBF              ", 69 )
      OPCAO( 8, 24, "Exportar &Formatos         ", 70 )
      KEY := menu( 1, 0 )
      
      DO CASE
      CASE KEY = 1
           tclass_open() 
           tclass_createdatabase()
           tclass_close()
      CASE KEY = 2; tclass_impdbf()
      CASE KEY = 3; tclass_TABELAS()
      CASE KEY = 4; tclass_expdbf(1)
      CASE KEY = 5; tclass_expdbf(2)
      OTHERWISE; EXIT
      ENDCASE
   ENDDO

   RETURN .T.

// +--------------------------------------------------------------------
// +    Gerenciamento de Conexao
// +--------------------------------------------------------------------
FUNCTION tclass_open()
   DO CASE
      CASE cTIPOSQL == "MYSQL"
          oDb := TMySQL():New()
          oDb:cServer   := cSERVERX
          oDb:cDatabase :=  cDATABASEX 
          oDb:cUser     :=   cUSERX
          oDb:cPassword :=   cPASSX
          oDb:nPort     :=  VAL(cPORTAX)
      CASE cTIPOSQL == "MARIADB"
          oDb := TMariaDB():New()
          oDb:cServer   := cSERVERX
          oDb:cDatabase :=  cDATABASEX 
          oDb:cUser     :=   cUSERX
          oDb:cPassword :=   cPASSX
          oDb:nPort     :=  VAL(cPORTAX)
      CASE cTIPOSQL == "SQLITE"
           oDb := TSQLite():New()
           oDb:cDatabase :=  cDATABASEX
      CASE cTIPOSQL == "PGSQL"
           oDb := TPostgreSQL():New()
           oDb:cServer   := cSERVERX
          oDb:cDatabase :=  cDATABASEX 
          oDb:cUser     :=   cUSERX
          oDb:cPassword :=   cPASSX
          oDb:nPort     :=  VAL(cPORTAX)
      CASE cTIPOSQL == "MSSQL"
           oDb := TSQLServer():New()
           oDb:cServer   := cSERVERX
          oDb:cDatabase :=  cDATABASEX 
          oDb:cUser     :=   cUSERX
          oDb:cPassword :=   cPASSX
          oDb:nPort     :=  VAL(cPORTAX)
      CASE lFDB //Firebird
           oDb := TFirebird():New()
           oDb:cServer   := cSERVERX
          oDb:cDatabase :=  cDATABASEX 
          oDb:cUser     :=   cUSERX
          oDb:cPassword :=   cPASSX
          oDb:nPort     :=  VAL(cPORTAX)
      CASE cTIPOSQL == "ORACLE"
           oDb := TOracle():New()
           oDb:cServer   := cSERVERX
          oDb:cDatabase :=  cDATABASEX 
          oDb:cUser     :=   cUSERX
          oDb:cPassword :=   cPASSX
          oDb:nPort     :=  VAL(cPORTAX)    
       //CASE cTIPOSQL == "MONGODB"   
       //   oDb := TMongoDB():New()
       OTHERWISE
         ALERT("Nao suportado")
 
      // Adicionar outros conforme classes implementadas
   ENDCASE
   
   // Preencher propriedades conforme necessidades do sistema antigo
   // oDb:cServer := ...
   
   IF !oDb:Open()
      Alert( "Erro: " + oDb:LastError() )
   ENDIF
   RETURN NIL

// +--------------------------------------------------------------------
// +    Function tclass_exec_script( cArquivoSQL )
// +    Executa comandos SQL contidos em um arquivo de texto.
// +--------------------------------------------------------------------
FUNCTION tclass_exec_script( cArquivoSQL )
LOCAL cCOMANDO := ""
LOCAL cARQIMP  := ""
cARQIMP := win_GetOPENFileName(,"Arquivos SQL",HB_CWD(),"Arquivos SQL","*.SQL",1)

IF FILE(cARQIMP)
   //nao pode ser linha a linha pois um comando pode estar em mais de uma linha
   cCOMANDO:=MEMOREAD(cARQIMP)
   tclass_exec_script(cCOMANDO)
endif
RETURN .T.




// +--------------------------------------------------------------------
// +    Function tclass_checkconn()
// +    Diagnostica se a conexão está ativa e retorna metadados básicos.
// +--------------------------------------------------------------------
FUNCTION tclass_checkconn()
   LOCAL lStatus := .F.

   tclass_open()

   IF oDb != NIL .AND. oDb:IsConnected()
      MDT( "Conectado ao Driver: " + oDb:cDriver )
      MDT( "Banco/Arquivo: " + oDb:cDatabase )
      lStatus := .T.
   ELSE
      Alert( "Falha na conexão: " + oDb:LastError() )
   ENDIF

   tclass_close()
RETURN lStatus

function tclass_close()
   if oDb != nil
      oDb:Close()
      oDb := NIL
   endif
return nil

FUNCTION tclass_TABELAS(lNATIVE)
LOCAL oServer

IF VALTYPE(lNATIVE)<>"L" //testar a native nao esta trazendo a array
   lNATIVE:=.F.
ENDIF

IF lNATIVE
    tclass_open()
    mdbtabela( oDb:Tables )
    tclass_close()
ELSE
   mdbtabela( cDATABASEX ) //via ado 
ENDIF
RETURN .T.


// +--------------------------------------------------------------------
// +    Function tclass_deltable()
// +    Implementação usando a classe TDatabase para deletar tabelas
// +--------------------------------------------------------------------
FUNCTION tclass_deltable()
   
   // Verifica se o banco ja esta aberto, se nao, abre
      tclass_open()

   tclass_TABELAS()
   // Reutiliza a variavel de ambiente ou logica de selecao de tabela cTABELAX
   // Certifique-se de que mdbtabela() ou similar preencheu cTABELAX
   IF Empty( AllTrim(cTABELAX) )
      Alert( "Nenhuma tabela selecionada para exclusao." )
      RETURN .F.
   ENDIF

   // Confirmacao (MDG eh uma funcao de sistema, mantida conforme seu padrao)
   IF !MDG( "Apagar Tabela " + AllTrim(cTABELAX) + "?" )
      RETURN .F.
   ENDIF

   // Verifica a existencia da tabela usando o metodo padrao da classe
   IF oDb:TableExists( AllTrim(cTABELAX) )
      
      // Executa o comando de remocao
      IF oDb:Execute( "DROP TABLE " + AllTrim(cTABELAX) )
         MDT( "Tabela " + AllTrim(cTABELAX) + " eliminada com sucesso." )
      ELSE
         Alert( "Erro ao eliminar tabela: " + oDb:LastError() )
         RETURN .F.
      ENDIF
      
   ELSE
      Alert( "Tabela nao encontrada no banco de dados." )
      RETURN .F.
   ENDIF

    tclass_close()


RETURN .T.

// +--------------------------------------------------------------------
// +    Operacoes de Banco
// +--------------------------------------------------------------------
Function tclass_createdatabase()
   cnewDATABASEX := INPUTBOX( Space( 30 ), "Novo database" )
   cnewDATABASEX := AllTrim( cnewDATABASEX )
   IF !Empty( cnewDATABASEX )
      IF cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" .OR. cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER"
         oDb:Execute( "CREATE DATABASE IF NOT EXISTS " + Cnewdatabasex )
      ENDIF
      IF cTIPOSQL = "SQLITE" .OR. lMDB .OR. lACCDB .OR. lFDB
         mdbcria()
      ENDIF
   ENDIF
return nil

FUNCTION tclass_impdbf()
  nOLDTIPO := TIPODBF
            alertX( "escolha origem" )
            tipodbfesc()
            nORITIPO   := TIPODBF
            cORIDRIVER := RDDNOME( TIPODBF )
            lincdados:=mdg("Incluir Dados")
            IF MDG("Arquivo individual")
               cARQORI    := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*."+TABLEEXT, 1 )
                IF File( cARQORI )
                   tclassimpdbf(cARQORI,lincdados)
                ENDIF
            ELSE
               cPASTA:=SelectFolder()
               cPASTA+="\*."+TABLEEXT 
               //FAZERDBF(bUSO                                       , lSHARE[.F.] , bPRE, bPOS, cMASK ,LOPEN )
               FAZERDBF( {|| tclassimpdbf(cCAMINHOCOMPLETO,lincdados) }, .F. ,     ,     ,cPASTA,.F.)
            ENDIF   
            RDDNOME( nOLDTIPO )   // retorna tipo anterior
RETURN            


// +--------------------------------------------------------------------
// +    Function tclass_impdbf()
// +    Implementação orientada a objetos (TDatabase)
// +--------------------------------------------------------------------
FUNCTION tclassimpdbf(cARQORI,lincdados)
   LOCAL aINDICES := {}, aSTRU, nLASTREC, cTABLE := Space(30), j, nIndexes
   LOCAL msql, i, nCont := 0


   IF Empty( cARQORI ); RETURN .F.; ENDIF

   hb_FNameSplit( cARQORI, nil, @cTable, NIL )
   cTABLE := AllTrim( cTable )

   // 2. Abertura do DBF
   dbUseArea( .T., RDDNOME( TIPODBF ), cARQORI, cTABLE, .T., .T. )
   aSTRU    := dbStruct()
   nLASTREC := RecCount()
   zei_fort( nLASTREC,,, 0 )

   // 3. Preparação da estrutura SQL
   msql := SqliteCreateTable( cTABLE, aSTRU, cTIPOSQL )
   
   // 4. Execução via TDatabase
   tclass_open()
   
   // Cria tabela
   IF oDb:TableExists( cTABLE )
      oDb:Execute( "DROP TABLE " + cTABLE )
   ENDIF
   oDb:Execute( msql )

   // Cria índices (se houver)
   aINDICES := GeraINDICES()
   FOR j := 1 TO Len(aINDICES)
      oDb:Execute( aINDICES[j, 1] )
   NEXT j

   // 5. Migração dos dados com Transação
   oDb:BeginTransaction()
   
   
   IF lincdados
       dbGoTop()
       WHILE !Eof()
          zei_fort( nLASTREC,,, 1 )
          
          msql := "INSERT INTO " + cTABLE + " VALUES ("
          FOR i := 1 TO Len( aSTRU )
             msql += c2sql( hb_FieldGet( i ) ) + iif( i < Len(aSTRU), ", ", "" )
          NEXT
          msql += ")"
          
          oDb:Execute( msql )
          
          nCont++
          IF nCont % 500 == 0
             oDb:Commit()
             oDb:BeginTransaction()
          ENDIF
          
          dbSkip()
       ENDDO
   ENDIF
   oDb:Commit()
   dbCloseArea()
   tclass_close()

   MDT( "Importação concluída com sucesso!" )
   RETURN .T.



// +--------------------------------------------------------------------
// +    Function tclass_executesql()
// +    Implementação completa seguindo a lógica do dbumix.prg
// +    Permite execução de string única ou array de comandos.
// +--------------------------------------------------------------------
FUNCTION tclass_executesql( eCOMANDO, lTRANS, lMES )

   LOCAL aCOMANDOS := {}
   LOCAL i
   LOCAL lRet := .T.

   // Tratamento de parâmetros opcionais
   IF HB_ISNIL( lTRANS ); lTRANS := .F.; ENDIF
   IF HB_ISNIL( lMES );   lMES   := .F.; ENDIF

   // Normaliza comando para um array
   IF ValType( eCOMANDO ) == "C"
      AAdd( aCOMANDOS, eCOMANDO )
   ELSEIF ValType( eCOMANDO ) == "A"
      aCOMANDOS := eCOMANDO
   ENDIF

   tclass_open()
   // Inicia transação se solicitado
   IF lTRANS
      oDb:Execute( Dialeto_begin() ) // Adaptado para a interface TDatabase
   ENDIF

   FOR i := 1 TO Len( aCOMANDOS )
      // Executa o comando via método da classe
      IF !oDb:Execute( aCOMANDOS[i] )
         lRet := .F.
         IF lMES
            Alert( "Erro ao executar: " + aCOMANDOS[i] + hb_eol() + "Msg: " + oDb:LastError() )
         ENDIF
      ENDIF
   NEXT i

   // Finaliza transação
   IF lTRANS
      IF lRet
         oDb:Execute(Dialeto_commit()  )
      ELSE
         oDb:Execute( Dialeto_rollback() )
      ENDIF
   ENDIF
    tclass_close()

   RETURN lRet
   
   
   // +--------------------------------------------------------------------
// +    Function tclass_expdbf( nTipo )
// +    Adaptada para usar a instância global oDb
// +--------------------------------------------------------------------
FUNCTION tclass_expdbf( nTipo )
   LOCAL aSTRU := {}, aVALOR, aStructInfo
   LOCAL i, nFIM, cDESTINO, eVALOR, nLASTREC

   // 1. Garante conexão ativa
   tclass_open()
   tclass_TABELAS() // Seleciona cTABELAX
   IF Empty(AllTrim(cTABELAX))
    tclass_close()
    RETURN .F.
ENDIF

   // 2. Executa Query usando o método da TDatabase
   // oDb:Query retorna um array, e oDb é o cursor ativo
   // Vamos garantir que a tabela seja consultada
   oDb:cSQL := "SELECT * FROM " + AllTrim(cTABELAX)
   oDb:LoadCursor() 

   nLASTREC := Len(oDb:aRows) // Baseado no cursor carregado
   zei_fort( nLASTREC,,, 0 )

   // 3. Obtenção de metadados
   // Mantemos MDBTABLES conforme seu sistema original
   aStructInfo := MDBTABLES( cDATABASEX, cTABELAX )
   
   aStru:=sqltodbfstru(aStructInfo)
   
   //nFIM        := Len( aStructInfo )

   //FOR i := 1 TO nFIM
   //   AAdd( aSTRU, geracampodbf( aStructInfo[i, 1], aStructInfo[i, 2], aStructInfo[i, 3], aStructInfo[i, 4] ) )
   //NEXT i

   // 4. Criação do arquivo
   cDESTINO := AllTrim(cTABELAX) + "_" + cTIPOSQL
   IF nTipo == 1
      MDT( cDESTINO )
      dbCreate( cDESTINO, aSTRU, "DBFCDX" )
      dbUseArea( .T., "DBFCDX", cDESTINO, "DESTINO", .T., .F. )
   ELSE
      dbCreate( "mem:destino", aSTRU,, .T., "DESTINO" )
   ENDIF

   // 5. Navegação no cursor da TDatabase
   oDb:GoTop()
   DO WHILE !oDb:Eof()
      dbSelectArea( "DESTINO" )
      NETRECAPP()
      
      FOR i := 1 TO nFIM
         eVALOR := oDb:FieldGet(i)
         
            // CORREÇÃO: Tratamento preventivo de valores Nulos (NULL) vindos do Firebird
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

         // Tratamento de String/UTF8
         IF ValType( eVALOR ) == "C"
            //IF hb_UTF8Len(eVALOR) != Len(eVALOR); eVALOR := hb_UTF8ToStr(eVALOR); ENDIF
            //eVALOR := RANGEREPL( Chr( 0 ), Chr( 31 ), eVALOR, " " )
            //eVALOR := TIRACE( eVALOR )
            eVALOR := FixSRTExtendido( eVALOR , .T. , .T. , .T. , .T. , .T. )
            //FixSRTExtendido( cVALOR,lLOW,lUP,lACE,lUTF, lESP )
         ENDIF
         
         IF !Empty( eVALOR ); FieldPut( i, eVALOR ); ENDIF
      NEXT i
      
      zei_fort( nLASTREC,,, 1 )
      oDb:Skip(1)
   ENDDO

   // 6. Finalização e Exportação de formatos
   IF nTipo == 2
      cDESTINO := AllTrim(cTABELAX) + "_" + cTIPOSQL + zEXPOREXT
      MDT( cDESTINO )
      dbGoTop()
      multidocg( lDOCCAB, lDOCDAD, lDOCRECNO, cSUBTIPO, TIRAEXT( cDESTINO ), aSTRU )
   ENDIF

   dbSelectArea( "DESTINO" )
   dbCloseArea()
   
   IF nTipo == 2; dbDrop( "mem:destino" ); ENDIF

   tclass_close()
RETURN .T.