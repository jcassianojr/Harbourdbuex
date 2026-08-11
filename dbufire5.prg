// +--------------------------------------------------------------------
// +
// +   git\core\contrib\hbfbird\
// +
// +
// +--------------------------------------------------------------------
// +

*+--------------------------------------------------------------------
*+
*+    Programa  : dbufire.prg
*+
*+     Sistema:
*+
*+     Linguagem: Harbour
*+
*+     Autor: jcassiano
*+
*+     Copyright (c) 2024,  jcassiano
*+
*+    Documentado em 6-Jan-2025 as  3:37 pm
*+
*+--------------------------------------------------------------------
*+

#include "BOX.CH"
#include "TRY.CH"
#include "dbstruct.ch"

#include "directry.ch"
#require "hbfbird5"


// +--------------------------------------------------------------------
// +    Function firebirdmenu()
// +--------------------------------------------------------------------
FUNCTION Firebirdmenu()

LOCAL aAMBIENTE
LOCAL KEY


 /*
 LOCAL cServer := "localhost:"
   LOCAL cDatabase
   LOCAL cUser := "SYSDBA"
   LOCAL cPass := "masterkey"
   LOCAL nPageSize := 1024
   LOCAL cCharSet := "ASCII"
   LOCAL nDialect := 1
   LOCAL cName
 */  

nPageSize := 8192 //1024
cCharSet := "ISO8859_1" //"ASCII"
nDialect := 3 //deixando com 1 caso de erro criacao com 3
//Dialeto 1 Focado em compatibilidade retroativa (InterBase 6.0 ou inferior).
//Dialeto 2 Criado como uma zona de transição para ajudar programadores na migração do Dialeto 1 para o 3.
//Dialeto 3 É o padrão moderno e o recomendado para todos os novos sistemas.

aAMBIENTE  := SALVAA() 
cSERVERX   := PADR("localhost",30)  // localhost:cARQUIVO no connection
cDATABASEX := Space(30) 
cUSERX     :=  PADR("SYSDBA",30)
cPASSX     := PADR("masterkey",30)
cTABELAX   := Space(30) 
cBANCOX    := Space(30) 
cOWNERX   := Space(30)
cPORTAX    :=SPACE(30)
cPATH      := "" 
loledb     := .T. 
lMDB       := .F. 
lACCDB     := .F. 
lFDB       := .T.

cOLDRDD     := RDDSETDEFAULT("") 
nOLDTIPORDD := TIPODBF 
cTIPOSQL := "FIREBIRD"  // Passa para privada usadas nas funcoes abaixo 


// Busca as credenciais e o caminho do banco dinamicamente via cofre do sistema
pegcfgbanco() 


//pegcfbanco ja faz o openarq quando necessario
// Seleção do arquivo físico .fdb se aplicável à rotina local pegcfgbanco ja chama opentiparq quando e firebird
//OPENTIPOARQ()

WHILE .T.
   hb_DispBox(3,18,18,55,B_DOUBLE+" ") 
   @ 03,24 SAY "FIREBIRD"+" "+ALLTRIM(cSERVERX)+ " Banco " + cDATABASEX 
   
   OPCAO( 4, 24,"&Criar Database            ",67)   // c 1
   OPCAO( 5, 24, "&Database Selecionar       ", 68 )   // D 2
   OPCAO( 6, 24,"&Tabelas                   ",84)   // T  3
   OPCAO( 7, 24,"&Importar  DBF             ",73)   // I  4
   OPCAO( 8, 24,"&Exportar  DBF             ",69)   // E 5
   OPCAO( 9, 24,"&Apagar Tabela             ",65)   // A  6
   OPCAO(10, 24,"Exportar &Formatos         ",70)   // F  7
   OPCAO(11, 24,"&Versao Info               ",86)   // V   8
   OPCAO(12, 24,"Executar arquivo &SQL      ",83)   //S 83 9
   
   KEY := menu(1,0) 
   DO CASE
   CASE KEY = 1
      firecreate()
   CASE KEY = 2
          pegcfgbanco() //escolhe novamente    
   CASE KEY = 3
      fireTABELAS() 
   CASE KEY = 4
      fireimpdbf()
   CASE KEY = 5
      fireexpdbf( 1 )
   CASE KEY = 6
      firedeltable()
   CASE KEY = 7
      fireexpdbf( 2 )
   CASE KEY = 8
      fireverinfo()
   CASE KEY = 9
      fireExecArqSql()
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
// +    Function firecreate()
// +--------------------------------------------------------------------
function firecreate(lUSASQL)
LOCAL cCOMANDO
LOCAL cARQORI

    cARQORI := win_GetsaveFileName(,"Firebase Files",HB_CWD(),"Firebase",;
        {{'Firebird fdb','*.fdb'},{'Firebird gdb','*.gdb'},{'Firebird ib','*.ib'},;
         {'All Files','*.*'}},1)  

   IF VALTYPE(lUSASQL)<>"L"
      lUSASQL:=.F. //MDG("Usar SQL(SIM) FBCREATEDB(NAO)")
   ENDIF

   cDATABASEX := cARQORI
   cBANCOX:=hb_FNameSplit(cARQORI,NIL,cBANCOX,NIL)
   
   
    IF lUSASQL
        oServer := fireconnect(.F.)  //Abre sem anexar o arquivo
        IF oServer == NIL
           RETURN .F.
       ENDIF
       cCOMANDO := "CREATE DATABASE '"+cARQORI+"' USER 'SYSDBA' PASSWORD 'masterkey' PAGE_SIZE = 8192 DEFAULT CHARACTER SET ISO8859_1"
       oServer:Execute( cCOMANDO )
    ELSE
       FBCreateDB( AllTrim(cSERVERX) + ":" + AllTrim(cARQORI), cUSERX, cPASSX, nPageSize, cCharSet, nDialect )
    ENDIF

    //ccharset  e ndialect a prior nao podem ser alterados por isso se define na criacao    
return .T.

// +--------------------------------------------------------------------
// +    Function fireconnect()
// +--------------------------------------------------------------------
STATIC FUNCTION fireconnect(lINCLUIDB)
LOCAL oServer
LOCAL cConnString
IF VALTYPE(lINCLUIDB)<>"L"
   lINCLUIDB:=.T.
ENDIF

// Monta string de conexão no formato "host:caminho_ou_alias"
IF lINCLUIDB
   cConnString := AllTrim(cSERVERX) + ":" + AllTrim(cDATABASEX)
ELSE
   cConnString := AllTrim(cSERVERX) + ":" 
ENDIF   

// Instancia o servidor nativo usando Fb5class (Dialeto padrão 3)
oServer := Fb5class():New( cConnString, AllTrim(cUSERX), AllTrim(cPASSX), 3 )

IF oServer:NetErr()
   Alert( "Falha na conexao Nativa Firebird: " + oServer:Error() )
   RETURN NIL
ENDIF

RETURN oServer

// +--------------------------------------------------------------------
// +    Function fireverinfo()
// +--------------------------------------------------------------------
FUNCTION fireverinfo()
LOCAL oServer
LOCAL cVersionInfo := ""

oServer := fireconnect()
IF oServer != NIL
   // Captura a string de versão retornada diretamente pela API do cliente Firebird
   cVersionInfo := oServer:GetServerInfo()
   hb_memowrit("info01",oServer:GetServerInfo())
   hb_memowrit("info02",hb_valtoexp(oServer:ListTables()))
   hb_memowrit("info03",hb_valtoexp(oServer:TableStruct( "CLIENTES" )))
   
   IF Empty( cVersionInfo )
      cVersionInfo := "Nao foi possivel ler os detalhes da versao."
   ENDIF

   // Exibe a mensagem de sucesso junto com a versão detectada
   MDT( "Conectado com Sucesso!#Versao: " + AllTrim( cVersionInfo ) )
   
   oServer:Destroy()
ELSE
   MDT( "Falha ao obter informacoes do servidor." )
ENDIF

RETURN .T.



FUNCTION fireTABELAS( lNATIVE )
   LOCAL oServer, aTABELAS := {}

   IF VALTYPE( lNATIVE ) <> "L"
      lNATIVE := .T.
   ENDIF

   IF lNATIVE
      oServer := fireconnect()
      IF oServer != NIL
         // Substituindo o oServer:ListTables() pela nossa nova função
         aTABELAS := oServer:ListTables()
         
         IF !Empty( aTABELAS )
            mdbtabela( aTABELAS ) // Passa a matriz populada para sua rotina de interface
         ELSE
            MDT( "Nenhuma tabela encontrada." )
         ENDIF
         
         oServer:Destroy()
      ENDIF
   ELSE
      mdbtabela( cDATABASEX )
   ENDIF
   
RETURN .T.


Function fireimpdbf()
  nOLDTIPO := TIPODBF
            alertX( "escolha origem" )
            tipodbfesc()
            nORITIPO   := TIPODBF
            cORIDRIVER := RDDNOME( TIPODBF )
            lincdados:=mdg("Incluir Dados")
            IF MDG("Arquivo individual")
               cARQORI    := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*."+TABLEEXT, 1 )
                IF File( cARQORI )
                   fire_impdbf(cARQORI,lincdados)
                ENDIF
            ELSE
               cPASTA:=SelectFolder()
               cPASTA+="\*."+TABLEEXT 
               //FAZERDBF(bUSO                                       , lSHARE[.F.] , bPRE, bPOS, cMASK ,LOPEN )
               FAZERDBF( {|| fire_impdbf(cCAMINHOCOMPLETO,lincdados) }, .F. ,     ,     ,cPASTA,.F.)
            ENDIF   
            RDDNOME( nOLDTIPO )   // retorna tipo anterior

RETURN


// +--------------------------------------------------------------------
// +    Function fireimpdbf()
// +--------------------------------------------------------------------
FUNCTION fire_impdbf(cARQORI,lincdados)
LOCAL oServer
LOCAL aINDICES := {}
LOCAL nINDICES, cINDEXNAME, cINDEXUSO, msql, cTABLE
LOCAL i,j, nCont

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


aINDICES:=GeraINDICES()



// Conecta nativamente via classe Fb5class
oServer := fireconnect()
IF oServer == NIL
   dbCloseArea()
   RETURN .F.
ENDIF

// INICIA UMA TRANSAÇÃO EXPLÍCITA PARA OS METADADOS E DDL
oServer:StartTransaction()

//cria as metadados
aRETUMETA:=GeraSQLMetadata()
  cSqlFields  :=aRETUMETA[1] 
  cSqlIndexes := aRETUMETA[2]
  
  IF ! Empty( cSqlFields )
     oServer:Execute(cSqlFields )
   //  oServer:Commit()
     mSQL="GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE  ON table_metadata TO  SYSDBA WITH GRANT OPTION GRANTED BY SYSDBA;"
     oServer:Execute( msql )
    // oServer:Commit()
  ENDIF   

  IF ! Empty( cSqlIndexes )
     oServer:Execute(cSqlIndexes )
    // oServer:Commit()
     mSQL="GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE  ON index_metadata TO  SYSDBA WITH GRANT OPTION GRANTED BY SYSDBA;"
     oServer:Execute( msql )
    // oServer:Commit()
  ENDIF 


// Limpar metadados antigos desta tabela específica 
oServer:Execute( "DELETE FROM table_metadata WHERE nome_tabela = " + c2sql(cTable) )
//oServer:Commit()
   
// LIMPA todos os metadados de índices desta tabela 
oServer:Execute( "DELETE FROM index_metadata WHERE nome_tabela = " + c2sql(cTable) )
//oServer:Commit()

 //Grava metadata do dbf
  aMETADBF:=GeradbfSchema( cTABLE, aStru )
   FOR j := 1 TO LEN(aMETADBF)
       mSQL:=aMETADBF[J]
       oServer:Execute( msql )
  //     oServer:Commit()
   NEXT J


oServer:Commit()
oServer:StartTransaction()


// Se a tabela já existir, dropa para evitar conflitos de reimportação
IF oServer:TableExists( cTABLE )
   IF ! MDG("Excluir tabela existente"+ cTABLE)
     dbCloseArea()
     oServer:Destroy()
     return .f.
   ELSE
     oServer:Execute( "DROP TABLE " + cTABLE )
    // oServer:Commit()
   ENDIF  
ENDIF

IF oServer:StartedTrans
   oServer:Commit()
ENDIF

oServer:Destroy()

oServer := fireconnect()
IF oServer == NIL
   dbCloseArea()
   RETURN .F.
ENDIF



oServer:StartTransaction()
// Gera a estrutura DDL adaptada para o Firebird usando seu tradutor existente
msql := SqliteCreateTable( cTABLE, aSTRU, "FIREBIRD" )
HB_memowrit("create_firebird_"+cTABLE+".SQL",MSQL,.F.)
//altd()

//O execute nao roda muliplas linha 
aCAMPOS:=HB_ATokens(msql,hb_eol()) 
FOR iac:=1 to len(acampos)
    msql:=aCAMPOS[iac]
    oServer:Execute( msql )
    mdt(msql)
next iac
oServer:Execute( msql )
oServer:Commit()


oServer:StartTransaction()

//ja no 
//mSQL="GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE  ON "+cTABLE+" TO  SYSDBA WITH GRANT OPTION GRANTED BY SYSDBA;"
//oServer:Execute( msql )
//oServer:Commit()

oServer:StartTransaction()

// Criação dos índices coletados
FOR i := 1 TO Len( aINDICES )
   TRY
      oServer:Execute( aINDICES[i,1] )  //create index
  //    oServer:Commit()
   catch oErR
      MDT("Erro "+aINDICES[i,1])   
   end   
   oServer:Execute( aINDICES[i,2] )  //metadado
   //oServer:Commit()
NEXT i
oServer:Commit()

nCont := 0
oServer:StartTransaction()

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
        msql += c2sql( & ( aSTRU[i, DBS_NAME] ) )
     NEXT i
     msql += ")"
     
     oServer:Execute( msql )
     
     nCont++
     // Bloco de Commit térmico para otimizar transações em lote (Bulk Insert)
     IF nCont % 500 == 0
        oServer:Commit()
        oServer:StartTransaction()
     ENDIF
     
     dbSkip()
   ENDDO
endif

oServer:Commit()
dbCloseArea()
oServer:Destroy()

MDT( "Importacao concluida com sucesso!" )
RETURN .T.


// +--------------------------------------------------------------------
// +    Function fireexpdbf()
// +--------------------------------------------------------------------
// Passa nTipo = 1 para criar DBF físico ou 2 para exportação baseada em memória/formatos
FUNCTION fireexpdbf( nTipo )
LOCAL oServer, oQuery
LOCAL aSTRU := {}
LOCAL aVALOR
LOCAL i, nFIM, cFieldName, cFieldType, nFieldLength, nFieldDec, cDESTINO, eVALOR


oServer := fireconnect()
IF oServer == NIL
   RETURN .F.
ENDIF

fireTABELAS() 


oQuery := oServer:Query( "SELECT * FROM " + AllTrim(cTABELAX) )
IF oServer:NetErr()
   Alert( "Erro ao ler tabela: " + oServer:Error() )
   oServer:Destroy()
   RETURN .F.
ENDIF

nLASTREC := oQuery:LastRec()
zei_fort( nLASTREC,,, 0 )

// Obtém metadados da tabela do Firebird e converte em dbStruct compatível
//aStructInfo := oQuery:GetStruct() //voltando matriz vazia
aStructInfo := MDBTABLES(cDATABASEX,cTABELAX)


aStructInfo:=sqltodbfstru(aStructInfo)


cDESTINO := AllTrim(cTABELAX) + "_FIREBIRD"

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
      AAdd( aVALOR,oRow:FieldGet( i )) //oQuery:FieldGet( i ) )
   NEXT i
   
   dbSelectArea( "DESTINO" )
   NETRECAPP()
   
   FOR i := 1 TO nFIM
      eVALOR := aVALOR[i]
      
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
   
      // Limpeza de strings e caracteres de controle oriundos do banco
      IF ValType( eVALOR ) == "C" .OR. ValType( eVALOR ) == "M"
         eVALOR := FixSRTExtendido( eVALOR , .T. , .T. , .T. , .T. , .T. )
            //FixSRTExtendido( cVALOR,lLOW,lUP,lACE,lUTF, lESP )
      ENDIF
      
      IF !Empty( eVALOR )
         FieldPut( i, eVALOR )
      ENDIF
   NEXT i
   
   zei_fort( nLASTREC,,, 1 )
   oQuery:Skip()
ENDDO

oQuery:Destroy()
oServer:Destroy()

IF nTipo == 2
   cDESTINO := AllTrim(cTABELAX) + "_FIREBIRD" + zEXPOREXT
   MDT( cDESTINO )
   dbSelectArea( "DESTINO" )
   nLASTREC := LastRec()
   zei_fort( nLASTREC,,, 0 )
   dbGoTop()
   multidocg( lDOCCAB, lDOCDAD, lDOCRECNO, cSUBTIPO, TIRAEXT( cDESTINO ), aSTRU )
ENDIF

dbSelectArea( "DESTINO" )
dbCloseArea()

IF nTipo == 2
   dbDrop( "mem:destino" )
ENDIF

RETURN .T.


// +--------------------------------------------------------------------
// +    Function firedeltable()
// +--------------------------------------------------------------------
FUNCTION firedeltable()
LOCAL oServer
LOCAL X
LOCAL aTABLES
oServer := fireconnect()
IF oServer == NIL
   RETURN .F.
ENDIF

fireTABELAS() 
IF !MDG( "Apagar Tabela " + AllTrim(cTABELAX) + "?" )
   RETURN .F.
ENDIF

IF oServer:TableExists( AllTrim(cTABELAX) )
   oServer:Execute( "DROP TABLE " + AllTrim(cTABELAX) )
   MDT( "Tabela eliminada com sucesso." )
ELSE
   Alert( "Tabela nao encontrada no banco de dados." )
ENDIF

oServer:Destroy()
RETURN .T.


 *+--------------------------------------------------------------------
*+
*+    Function fireExecArqSql()
*+
*+--------------------------------------------------------------------
*+
function fireExecArqSql()

LOCAL cCOMANDO := ""
LOCAL cARQIMP  := ""

cARQIMP := win_GetOPENFileName(,"Arquivos SQL",HB_CWD(),"Arquivos SQL","*.SQL",1)
//cARQORI := OPENTIPOARQ()

IF FILE(cARQIMP)
   //nao pode ser linha a linha pois um comando pode estar em mais de uma linha
   cCOMANDO:=MEMOREAD(cARQIMP)
   oServer := fireconnect()
   fireexecuteSQL(cCOMANDO)
   oServer:Destroy()
endif


 *+--------------------------------------------------------------------
*+
*+    Function fireExecuteSql()
*+
*+--------------------------------------------------------------------
*+

FUNCTION fireexecuteSQL( eCOMANDO, lTRANS, lMES )

   LOCAL aCOMANDOS := {}
   LOCAL nFIM
   LOCAL i
   LOCAL lRet
   LOCAL oServer


   lRET := .T.
   IF ValType( LMES ) <> "L"
      lMES := .F.
   ENDIF
   IF ValType( lTRANS ) <> "L"
      lTRANS := .F.
   ENDIF
   
   IF ValType( eCOMANDO ) = "C"
      AAdd( aCOMANDOS, eCOMANDO )
   ELSE
      aCOMANDOS := eCOMANDO
   ENDIF
   nFIM := Len( aCOMANDOS )
   oServer := fireconnect()
   IF oServer == NIL
      RETURN .F.
   ENDIF
   IF lTRANS
      oServer:StartTransaction()
   ENDIF
   FOR i := 1 TO nfim
      cCOMANDO := aCOMANDOS[ I ]
      oServer:Execute( cCOMANDO )
   NEXT i
   IF lTRANS
      oServer:Commit()
   ENDIF
   oServer:Destroy()
   RETURN lRet


