// +--------------------------------------------------------------------
// +    Programa  : dbufire5.prg (Refatorado)
// +    Sistema   : Importacao e Exportacao Firebird 5
// +    Linguagem : Harbour
// +--------------------------------------------------------------------

#include "BOX.CH"
#include "TRY.CH"
#include "dbstruct.ch"
#include "directry.ch"
#require "hbfbird5"

FUNCTION Firebirdmenu5()
   LOCAL aAMBIENTE
   LOCAL KEY

   nPageSize := 8192
   cCharSet  := "ISO8859_1"
   nDialect  := 3 

   aAMBIENTE  := SALVAA() 
   cSERVERX   := PADR("localhost", 30)
   cDATABASEX := Space(30) 
   cUSERX     := PADR("SYSDBA", 30)
   cPASSX     := PADR("masterkey", 30)
   cTABELAX   := Space(30) 
   cBANCOX    := Space(30) 
   cOWNERX    := Space(30)
   cPORTAX    := SPACE(30)
   cPATH      := "" 
   
   loledb := .T.; lMDB := .F.; lACCDB := .F.; lFDB := .T.

   cOLDRDD     := RDDSETDEFAULT("") 
   nOLDTIPORDD := TIPODBF 
   cTIPOSQL    := "FIREBIRD"

   pegcfgbanco() 

   WHILE .T.
      hb_DispBox(3,18,18,55,B_DOUBLE+" ") 
      @ 03,24 SAY "FIREBIRD " + ALLTRIM(cSERVERX) + " Banco " + cDATABASEX 
      
      OPCAO( 4, 24,"&Criar Database            ",67)
      OPCAO( 5, 24,"&Database Selecionar       ",68)
      OPCAO( 6, 24,"&Tabelas                   ",84)
      OPCAO( 7, 24,"&Importar  DBF             ",73)
      OPCAO( 8, 24,"&Exportar  DBF             ",69)
      OPCAO( 9, 24,"&Apagar Tabela             ",65)
      OPCAO(10, 24,"Exportar &Formatos         ",70)
      OPCAO(11, 24,"&Versao Info               ",86)
      OPCAO(12, 24,"Executar arquivo &SQL      ",83)
      
      KEY := menu(1,0) 
      DO CASE
         CASE KEY == 1; firecreate5()
         CASE KEY == 2; pegcfgbanco()    
         CASE KEY == 3; fireTABELAS() 
         CASE KEY == 4; fireimpdbf()
         CASE KEY == 5; fireexpdbf( 1 )
         CASE KEY == 6; firedeltable()
         CASE KEY == 7; fireexpdbf( 2 )
         CASE KEY == 8; fireverinfo()
         CASE KEY == 9; fireExecArqSql()
         OTHERWISE; EXIT 
      ENDCASE
   ENDDO 

   TIPODBF := nOLDTIPORDD 
   rddSetDefault(cOLDRDD) 
   RDDNOME(TIPODBF) 
   RESTAA(aAMBIENTE) 
   LAYOUT() 
RETURN .T. 

// +--------------------------------------------------------------------
// +    Wrapper Robusto de Conexão (FireConnect)
// +--------------------------------------------------------------------
STATIC FUNCTION fireconnect( lIncluiDB )
   LOCAL oServer, cConnString, cSrv, cDb, cUsr, cPwd

   hb_default( @lIncluiDB, .T. )

   cSrv := AllTrim( cSERVERX )
   cDb  := AllTrim( cDATABASEX )
   cUsr := AllTrim( cUSERX )
   cPwd := AllTrim( cPASSX )

   IF Empty( cSrv )
      cSrv := "localhost"
   ENDIF

   IF lIncluiDB .AND. !Empty( cDb )
      cConnString := cSrv + ":" + cDb
   ELSE
      cConnString := cSrv + ":"
   ENDIF

   oServer := Fb5class():New( cConnString, cUsr, cPwd, nDialect )

   IF oServer:NetErr()
      Alert( "Falha na conexao Nativa Firebird: " + oServer:Error() )
      RETURN NIL
   ENDIF
RETURN oServer

// +--------------------------------------------------------------------
// +    Criação de Base de Dados
// +--------------------------------------------------------------------
FUNCTION firecreate5( lUSASQL )
   LOCAL cCOMANDO, cARQORI, oServer

   hb_default( @lUSASQL, .F. )

   cARQORI := win_GetsaveFileName(,"Firebase Files",HB_CWD(),"Firebase",;
        {{'Firebird fdb','*.fdb'},{'Firebird gdb','*.gdb'},{'All Files','*.*'}},1)  

   IF Empty( cARQORI )
      RETURN .F.
   ENDIF

   cDATABASEX := cARQORI
   cBANCOX    := hb_FNameSplit(cARQORI, NIL, cBANCOX, NIL)
   
   IF lUSASQL
      oServer := fireconnect( .F. ) 
      IF oServer == NIL; RETURN .F.; ENDIF

      cCOMANDO := "CREATE DATABASE '" + cARQORI + "' USER 'SYSDBA' PASSWORD 'masterkey' PAGE_SIZE = 8192 DEFAULT CHARACTER SET ISO8859_1"
      IF !oServer:Execute( cCOMANDO )
         Alert( "Erro ao criar banco: " + oServer:Error() )
      ENDIF
      oServer:Destroy()
   ELSE
      FBCreateDB( AllTrim(cSERVERX) + ":" + AllTrim(cARQORI), cUSERX, cPASSX, nPageSize, cCharSet, nDialect )
   ENDIF
RETURN .T.

// +--------------------------------------------------------------------
// +    Exportar DBF - Refatorado (Corrigida Falha de Estrutura)
// +--------------------------------------------------------------------
FUNCTION fireexpdbf( nTipo )
   LOCAL oServer, oQuery, oRow
   LOCAL aSTRU := {}, aVALOR
   LOCAL i, nFIM, cDESTINO, eVALOR, nLASTREC

   oServer := fireconnect()
   IF oServer == NIL; RETURN .F.; ENDIF

   fireTABELAS() 
   
   IF Empty( cTABELAX )
      oServer:Destroy()
      RETURN .F.
   ENDIF

   oQuery := oServer:Query( "SELECT * FROM " + AllTrim(cTABELAX) )
   IF oServer:NetErr()
      Alert( "Erro ao ler tabela: " + oServer:Error() )
      oServer:Destroy()
      RETURN .F.
   ENDIF

   aStructInfo := MDBTABLES(cDATABASEX,cTABELAX)
   aStru := sqltodbfstru(aStructInfo)
   
   nFIM  := Len( aSTRU )

   IF nFIM == 0
      Alert( "Falha ao extrair metadados da tabela ou tabela vazia estruturalmente." )
      oQuery:Destroy()
      oServer:Destroy()
      RETURN .F.
   ENDIF

   nLASTREC := oQuery:LastRec()
   zei_fort( nLASTREC,,, 0 )

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
      oRow   := oQuery:GetRow()
      
      FOR i := 1 TO nFIM
         AAdd( aVALOR, oRow:FieldGet( i ) )
      NEXT i
      
      dbSelectArea( "DESTINO" )
      NETRECAPP()
      
      FOR i := 1 TO nFIM
         eVALOR := aVALOR[i]
         
         // Protecao e conversao de Nulos
         IF eVALOR == NIL
            DO CASE
               CASE aSTRU[i, DBS_TYPE] == "C"; eVALOR := Space( aSTRU[i, DBS_LEN] )
               CASE aSTRU[i, DBS_TYPE] == "N"; eVALOR := 0
               CASE aSTRU[i, DBS_TYPE] == "D"; eVALOR := CToD("")
               CASE aSTRU[i, DBS_TYPE] == "L"; eVALOR := .F.
               CASE aSTRU[i, DBS_TYPE] == "M"; eVALOR := ""
            ENDCASE
         ENDIF
      
         IF ValType( eVALOR ) == "C" .OR. ValType( eVALOR ) == "M"
            eVALOR := FixSRTExtendido( eVALOR , .T. , .T. , .T. , .T. , .T. )
         ENDIF
         
         IF !Empty( eVALOR ) .OR. ValType( eVALOR ) $ "NLD"
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
// +    Importação DBF -> Firebird (Com Segurança Transacional)
// +--------------------------------------------------------------------
FUNCTION fire_impdbf( cARQORI, lincdados )
   LOCAL oServer
   LOCAL aINDICES := {}, aSTRU, aRETUMETA, aMETADBF, aCAMPOS
   LOCAL i, j, nCont, cTABLE, msql, cSqlFields, cSqlIndexes, iac

   cTABLE := Space( 30 )
   IF Empty( cARQORI ); RETURN .F.; ENDIF

   hb_FNameSplit( cARQORI, nil, @cTable, NIL )
   cTABLE := AllTrim( cTABLE )

   dbUseArea( .T., cORIDRIVER, cARQORI, cTABLE, .T., .T. )
   aSTRU    := dbStruct()
   nLASTREC := RecCount()
   zei_fort( nLASTREC,,, 0 )

   aINDICES := GeraINDICES()

   oServer := fireconnect()
   IF oServer == NIL
      dbCloseArea()
      RETURN .F.
   ENDIF

   // FASE 1: METADADOS GERAIS
   aRETUMETA := GeraSQLMetadata()
   cSqlFields  := aRETUMETA[1] 
   cSqlIndexes := aRETUMETA[2]
  
   oServer:StartTransaction()
   TRY
      IF ! Empty( cSqlFields )
         oServer:Execute( cSqlFields )
         oServer:Execute( "GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON table_metadata TO SYSDBA WITH GRANT OPTION;" )
      ENDIF   

      IF ! Empty( cSqlIndexes )
         oServer:Execute( cSqlIndexes )
         oServer:Execute( "GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON index_metadata TO SYSDBA WITH GRANT OPTION;" )
      ENDIF 

      oServer:Execute( "DELETE FROM table_metadata WHERE nome_tabela = " + c2sql(cTable) )
      oServer:Execute( "DELETE FROM index_metadata WHERE nome_tabela = " + c2sql(cTable) )

      aMETADBF := GeradbfSchema( cTABLE, aStru )
      FOR j := 1 TO LEN(aMETADBF)
         oServer:Execute( aMETADBF[J] )
      NEXT J
      
      IF oServer:TableExists( cTABLE )
         IF ! MDG("Excluir tabela existente " + cTABLE)
            oServer:Rollback()
            dbCloseArea()
            oServer:Destroy()
            RETURN .F.
         ELSE
            oServer:Execute( "DROP TABLE " + cTABLE )
         ENDIF  
      ENDIF
      
      // Cria a nova tabela lendo a string gerada
      msql := SqliteCreateTable( cTABLE, aSTRU, "FIREBIRD" )
      aCAMPOS := HB_ATokens( msql, hb_eol() ) 
      FOR iac := 1 TO Len( aCAMPOS )
         IF !Empty( aCAMPOS[iac] )
            IF !oServer:Execute( aCAMPOS[iac] )
               // Força erro para cair no Catch
               Throw( ErrorNew( "FIRE", 0, 0, oServer:Error() ) )
            ENDIF
         ENDIF
      NEXT iac

      // Criacao dos índices coletados
      FOR i := 1 TO Len( aINDICES )
         oServer:Execute( aINDICES[i,1] ) 
         oServer:Execute( aINDICES[i,2] ) 
      NEXT i

      oServer:Commit()
   CATCH oErr
      oServer:Rollback()
      Alert( "Erro estrutural ao preparar banco: " + oErr:Description )
      dbCloseArea()
      oServer:Destroy()
      RETURN .F.
   END

   // FASE 2: INSERÇÃO EM LOTE SEGURO
   IF lincdados
      nCont := 0
      oServer:StartTransaction()
      
      dbSelectArea( cTABLE )
      dbGoTop()

      WHILE !Eof()
         zei_fort( nLASTREC,,, 1 )
         
         msql := "INSERT INTO " + cTABLE + " VALUES ("
         FOR i := 1 TO Len( aSTRU )
            IF i > 1; msql += ", "; ENDIF
            msql += c2sql( &( aSTRU[i, DBS_NAME] ) )
         NEXT i
         msql += ")"
         
         IF !oServer:Execute( msql )
            Alert("Erro inserindo no registo " + hb_ntos(nCont) + ": " + oServer:Error() )
            // Se preferir abortar tudo no primeiro erro:
            // oServer:Rollback(); EXIT
         ENDIF
         
         nCont++
         IF nCont % 500 == 0
            oServer:Commit()
            oServer:StartTransaction()
         ENDIF
         
         dbSkip()
      ENDDO
      oServer:Commit()
   ENDIF

   dbCloseArea()
   oServer:Destroy()

   MDT( "Importacao concluida com sucesso!" )
RETURN .T.

// +--------------------------------------------------------------------
// +    Utilitarios Complementares e Restante Interface Menu
// +--------------------------------------------------------------------
FUNCTION fireimpdbf()
   LOCAL nOLDTIPO, cORIDRIVER, nORITIPO, cARQORI, cPASTA, lincdados

   nOLDTIPO := TIPODBF
   alertX( "escolha origem" )
   tipodbfesc()
   nORITIPO   := TIPODBF
   cORIDRIVER := RDDNOME( TIPODBF )
   lincdados  := MDG("Incluir Dados")
   
   IF MDG("Arquivo individual")
      cARQORI := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*."+TABLEEXT, 1 )
      IF File( cARQORI )
         fire_impdbf( cARQORI, lincdados )
      ENDIF
   ELSE
      cPASTA := SelectFolder()
      cPASTA += "\*." + TABLEEXT 
      FAZERDBF( {|| fire_impdbf(cCAMINHOCOMPLETO,lincdados) }, .F. ,     ,     ,cPASTA,.F.)
   ENDIF   
   RDDNOME( nOLDTIPO )
RETURN NIL

FUNCTION fireverinfo()
   LOCAL oServer, cVersionInfo := ""

   oServer := fireconnect()
   IF oServer != NIL
      cVersionInfo := oServer:GetServerInfo()
      hb_memowrit("info01", oServer:GetServerInfo())
      hb_memowrit("info02", hb_valtoexp(oServer:ListTables()))
      //nao usar pois aqui fixa em uma tabela
      //hb_memowrit("info03", hb_valtoexp(oServer:TableStruct( "CLIENTES" )))
      
      IF Empty( cVersionInfo )
         cVersionInfo := "Nao foi possivel ler os detalhes da versao."
      ENDIF
      MDT( "Conectado com Sucesso!#Versao: " + AllTrim( cVersionInfo ) )
      oServer:Destroy()
   ELSE
      MDT( "Falha ao obter informacoes do servidor." )
   ENDIF
RETURN .T.

FUNCTION fireTABELAS( lNATIVE )
   LOCAL oServer, aTABELAS := {}
   hb_default( @lNATIVE, .T. )

   IF lNATIVE
      oServer := fireconnect()
      IF oServer != NIL
         aTABELAS := oServer:ListTables()
         IF !Empty( aTABELAS )
            mdbtabela( aTABELAS ) 
         ELSE
            MDT( "Nenhuma tabela encontrada." )
         ENDIF
         oServer:Destroy()
      ENDIF
   ELSE
      mdbtabela( cDATABASEX )
   ENDIF
RETURN .T.

FUNCTION firedeltable()
   LOCAL oServer
   
   oServer := fireconnect()
   IF oServer == NIL; RETURN .F.; ENDIF

   fireTABELAS() 
   IF Empty( cTABELAX ) .OR. !MDG( "Apagar Tabela " + AllTrim(cTABELAX) + "?" )
      oServer:Destroy()
      RETURN .F.
   ENDIF

   IF oServer:TableExists( AllTrim(cTABELAX) )
      IF oServer:Execute( "DROP TABLE " + AllTrim(cTABELAX) )
         MDT( "Tabela eliminada com sucesso." )
      ELSE
         Alert( "Falha ao apagar tabela: " + oServer:Error() )
      ENDIF
   ELSE
      Alert( "Tabela nao encontrada no banco de dados." )
   ENDIF

   oServer:Destroy()
RETURN .T.

FUNCTION fireExecArqSql()
   LOCAL cCOMANDO := "", cARQIMP := "", oServer

   cARQIMP := win_GetOPENFileName(,"Arquivos SQL",HB_CWD(),"Arquivos SQL","*.SQL",1)

   IF FILE(cARQIMP)
      cCOMANDO := MEMOREAD(cARQIMP)
      fireexecuteSQL( cCOMANDO, .T., .T. ) // Usa transacao
   ENDIF
RETURN NIL

// Wrapper seguro para execucao generica
FUNCTION fireexecuteSQL( eCOMANDO, lTRANS, lMES )
   LOCAL aCOMANDOS := {}, cCOMANDO, nFIM, i, lRet := .T., oServer

   hb_default( @lMES, .F. )
   hb_default( @lTRANS, .F. )
   
   IF ValType( eCOMANDO ) == "C"
      AAdd( aCOMANDOS, eCOMANDO )
   ELSE
      aCOMANDOS := eCOMANDO
   ENDIF
   
   nFIM := Len( aCOMANDOS )
   oServer := fireconnect()
   IF oServer == NIL; RETURN .F.; ENDIF
   
   IF lTRANS
      oServer:StartTransaction()
   ENDIF
   
   TRY
      FOR i := 1 TO nFIM
         cCOMANDO := aCOMANDOS[ i ]
         IF !oServer:Execute( cCOMANDO )
            Throw( ErrorNew("FIRE", 0, 0, oServer:Error()) )
         ENDIF
      NEXT i
      
      IF lTRANS
         oServer:Commit()
      ENDIF
   CATCH oErr
      IF lTRANS
         oServer:Rollback()
      ENDIF
      Alert("Erro na execucao do SQL: " + oErr:Description )
      lRet := .F.
   END
   
   oServer:Destroy()
RETURN lRet