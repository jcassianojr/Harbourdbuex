// +--------------------------------------------------------------------
// + Git\core\contrib\sddfb\
// + git\core\contrib\sddmy\  
// + git\core\contrib\sddoci\
// + git\core\contrib\sddodbc\
// + git\core\contrib\sddpg\
// + git\core\contrib\sddsqlt3\
// + git\core\contrib\rddsql\
// +
// +--------------------------------------------------------------------

// +--------------------------------------------------------------------
// +
// +
// +
// +    Programa  : dbumix.prg
// +
// +
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
// +
// +
// +
// +    Documentado em 28-Dez-2024 as 10:07 am
// +
// +
// +
// +--------------------------------------------------------------------
// +

#require "rddsql"
#require "sddodbc"
#require "sddsqlt3"


#ifdef USE_SDD_MYSQL
  #require "sddmy"
#endif

#ifdef USE_SDD_POSTGRES  
  #require "sddpg"
#endif  

//erro 64 bits usando outra tag
#ifdef USE_SDD_FIREBIRD
   #require "sddfb" 
#endif

#ifdef USE_SDD_FB5
   #require "sddfb5" 
#endif


#ifdef USE_SDD_ORACLE
    #require "sddoci"
#endif    


#include "dbinfo.ch"
#include "error.ch"
#include "simpleio.ch"
#include "BOX.CH"
#include "dbstruct.ch"


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
  

ANNOUNCE RDDSYS


// +--------------------------------------------------------------------
// +
// +    Function mixmenu()
// +
// +--------------------------------------------------------------------
// +
FUNCTION mixmenu( cUSOSQL )

   LOCAL aAMBIENTE

   cTIPOSQL := cUSOSQL   // Passa para privada usadas nas funcoes aBaixo

   nCONN      := 0
   aAMBIENTE  := SALVAA()
   cSERVERX   := "localhost" + Space( 21 )
   cDATABASEX := Space( 30 )
   cUSERX     := Space( 30 )
   cPASSX     := Space( 30 )
   cTABELAX   := Space( 30 )
   cBANCOX   := Space(30)
   cOWNERX   := Space(30)
   cPORTAX    :=SPACE(30)
   loledb     := .T.
   lMDB       := .F.
   lACCDB     := .F.
   lFDB       := .F.

   pegcfgbanco()
   cTIPOMIX := cTIPOSQL
   
   cTIPODBC :=  "CONN"

// Mariadb MSSQL nao tem nativo
   IF cTIPOSQL = "MARIADB" .OR. cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER" .OR. cTIPOSQL = "PARADOX"
      cTIPOMIX := "ODBC"
   ENDIF

// ORACLE COMO ODBC ate ajustar ocilib
   IF cTIPOSQL = "ORACLE" .OR. cTIPOSQL = "OCI"
      cTIPOMIX := "ODBC"
   ENDIF
   

// access mdb accdb nao tem nativo
   IF Lmdb .OR. laccdb
      cTIPOMIX := "ODBC"
      OPENTIPOARQ()
   ENDIF
// Verifica novamentes apos opentipoarq
   IF At( ".MDB", Upper( cdatabaseX ) ) > 0 .OR. At( ".ACCDB", Upper( cdatabaseX ) ) > 0
      cTIPOMIX := "ODBC"
   ENDIF

// esoolhe o arquivos sqlite
   IF cTIPOSQL = "SQLITE"
      OPENTIPOARQ()
   ENDIF

// esoolhe o arquivos firebird
   IF cTIPOSQL = "FIREBIRD"
      OPENTIPOARQ()
   ENDIF

// firebird sqlite mysql postgresql tem nativos e opcao para odbc
   IF cTIPOMIX <> "ODBC"
      IF ! mdg( "MIXRDD (SIM) MIXODBC (NAO)" )
         cTIPOMIX := "ODBC"
      ENDIF
   ENDIF
   
   

// Usando mdtabela depois criar nativa sqlmix
// precisa retornar rdd se for usar de charmar ddSetDefault( "SQLMIX" ) novamente nao ter connecao aberta sqlmix tambem
// mdbtabela(cdatabasex)

   cRDDSQL  := "SQLMIX"
   cOLDRDD := rddSetDefault( "SQLMIX" )
   nOLDTIPORDD := TIPODBF
   TIPODBF:=91
// mix_open()

   WHILE .T.
      hb_DispBox( 3, 18, 18, 55, B_DOUBLE + " " )
      @ 03, 24 SAY "SQLMIX" + " " + cTIPOSQL + " " + cDATABASEX
      OPCAO(  4, 24, "&Criar database            ", 67 )   // C
      OPCAO(  5, 24, "&Database Selecionar       ", 68 )   // D
      OPCAO(  6, 24, "&Importar  DBF             ", 73 )   // I
      OPCAO(  7, 24, "&Tabelas                   ", 84 )   // T
      OPCAO(  8, 24, "&Exportar  DBF             ", 69 )   // E
      OPCAO(  9, 24, "&Apagar Tabela             ", 65 )   // A
      OPCAO( 10, 24, "Exportar &Formatos         ", 70 )  // F 
      OPCAO( 11, 24, "Executar arquivo &SQL      ", 83 )   //S 83
      OPCAO( 12, 24, "&ODBC   Info DSN           ", 79 )   // O 
      
      KEY := menu( 1, 0 )
      DO CASE
      CASE KEY = 1
         mix_open()
         mixcreatedatabase()
         mix_close()
      CASE KEY = 2
         IF lMDB .OR. lACCDB
         ELSE
            mdbdatabases()
         ENDIF
      CASE KEY = 3
         miximpdbf()
      CASE KEY = 4
         mdbtabela( cdatabasex )
      CASE KEY = 5
         mixexpdbf( 1 )
      CASE KEY = 6
         mdbtabela( cdatabasex )
         IF MDG( "Apagar Tabela" + cTABELAX )
            mix_open()
            mix_executesql( "DROP TABLE  " + cTABELAX )
            mix_close()
         ENDIF
      CASE KEY = 7
         mixexpdbf( 2 )
         // mixexpformat() usando sqlmix array memory migrar rdd quando disponivel
      CASE KEY = 8
         mixExecArqSql()
      CASE KEY = 9
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
// +
// +
// +    Function mixexpdbf()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION mixexpdbf( nTIPO )

   LOCAL cDESTINO
   LOCAL aSTRU
   LOCAL aVALOR
   LOCAL I
   LOCAL nFIM
   LOCAL eVALOR

   IF nTIPO = 2
      LCOPIANAT := .F.   // MDG("Copia Nativa(SIM) Interna(NAO)") //copy to nao implemntado PGsqlrddd
      tDOC      := pegtipodoc()  // .t. Inclui dbf se for nativa
      pegparexp()
      lDOCCAB   := .F.
      lDOCDAD   := .F.
      lDOCRECNO := .F.
      cSUBTIPO  := " "
      PegcsUB( tDOC )  // pegar o subtipo conforme tipo
   ENDIF


   mdbtabela( cdatabasex )

   cDESTINO := cTABELAX + "_" + cTIPOSQL
   MDT( cDESTINO )


   MDT( "abrindo arquivo de origem: " + cTABELAX )
   dbUseArea( .T.,, "SELECT * FROM " + cTABELAX, "ORIGEM" )
   nLASTREC := LastRec()
   nFIM     := FCount()
   zei_fort( nLASTREC,,, 0 )
   aSTRU := dbStruct()
   aSTRU := sqltodbfstru( aSTRU )

   IF nTIPO = 1  // arquivo fisico
      MDT( cDESTINO )
      dbCreate( cDESTINO, aSTRU, "DBFCDX" )
      dbUseArea( .T., "DBFCDX", cDESTINO, "DESTINO", .T., .F. )
   ELSE

      // cria um arrayrdd para usar na exportacao usar memoria mudar para rdd quando disponivel
      // dbCreate( cFile, aStruct, cRDD, lKeepOpen, cAlias, cDelimArg, cCodePage, nConnection ) --> <lSuccess>
      // nao passa o driver sqlmix ja e default rddSetDefault( "SQLMIX" )
      // nao precisa abrir area lKeepOpen 4 parametro mantem aberto
      dbCreate( "DESTINO", aSTRU,, .T., "DESTINO" )

   ENDIF


   dbSelectAr( "ORIGEM" )
   dbGoTop()
   WHILE !Eof()
      aVALOR := {}
      FOR I := 1 TO nFIM
         AAdd( aVALOR, hb_FieldGet( I ) )
      NEXT I
      dbSelectAr( "DESTINO" )
      netrecapp()

      FOR I := 1 TO nFIM
         eVALOR := aVALOR[ I ]
         IF ValType( eVALOR ) = "C" .AND. SubStr( eVALOR, 5, 1 ) = "-" .AND. SubStr( eVALOR, 8, 1 ) = "-"
            eVALOR := SubStr( eVALOR, 6, 2 ) + "/" + SubStr( eVALOR, 9, 2 ) + "/" + SubStr( eVALOR, 1, 4 )
            eVALOR := CToD( eVALOR )
         ENDIF
         IF ValType( eVALOR ) = "C" .OR. ValType( eVALOR ) = "M"
            eVALOR := FixSRTExtendido( eVALOR , .T. , .T. , .T. , .T. , .T. )
            //FixSRTExtendido( cVALOR,lLOW,lUP,lACE,lUTF, lESP )
            //eVALOR := RANGEREPL( Chr( 0 ), Chr( 31 ), eVALOR, " " )   // Remove caracteres de controle
            //eVALOR := TIRACE( eVALOR )
         ENDIF
         IF !Empty( eVALOR )
            FieldPut( I, eVALOR )
         ENDIF
      NEXT I

      dbSelectAr( "ORIGEM" )
      dbSkip()
      zei_fort( nLASTREC,,, 1 )
   ENDDO
   dbSelectAr( "ORIGEM" )
   dbCloseArea()

   IF nTIPO = 2
      cDESTINO := cTABELAX + "_" + cTIPOSQL + zEXPOREXT
      MDT( cDESTINO )
      dbSelectAr( "DESTINO" )
      nLASTREC := LastRec()
      zei_fort( nLASTREC,,, 0 )
      dbGoTop()
      multidocg( lDOCCAB, lDOCDAD, lDOCRECNO, cSUBTIPO, TIRAEXT( cDESTINO ), aSTRU )
   ENDIF

   dbSelectAr( "DESTINO" )
   dbCloseArea()

   RETURN .T.


 *+--------------------------------------------------------------------
*+
*+    Function mixExecArqSql()
*+
*+--------------------------------------------------------------------
*+
function mixExecArqSql()

LOCAL cCOMANDO := ""
LOCAL cARQIMP  := ""

cARQIMP := win_GetOPENFileName(,"Arquivos SQL",HB_CWD(),"Arquivos SQL","*.SQL",1)
//cARQORI := OPENTIPOARQ()

IF FILE(cARQIMP)
   //nao pode ser linha a linha pois um comando pode estar em mais de uma linha
   cCOMANDO:=MEMOREAD(cARQIMP)
   mix_open()
   mix_executesql( msql )
   mix_close()
endif
return .t.
     
Function miximpdbf()

  nOLDTIPO := TIPODBF
            alertX( "escolha origem" )
            tipodbfesc()
            nORITIPO   := TIPODBF
            cORIDRIVER := RDDNOME( TIPODBF )
            lincdados:=mdg("Incluir Dados")
            IF MDG("Arquivo individual")
               cARQORI    := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*."+TABLEEXT, 1 )
                IF File( cARQORI )
                   mix_impdbf(cARQORI,lincdados)
                ENDIF
            ELSE
               cPASTA:=SelectFolder()
               cPASTA+="\*."+TABLEEXT 
               //FAZERDBF(bUSO                                       , lSHARE[.F.] , bPRE, bPOS, cMASK ,LOPEN )
               FAZERDBF( {|| mix_impdbf(cCAMINHOCOMPLETO,lincdados) }, .F. ,     ,     ,cPASTA,.F.)
            ENDIF   
            RDDNOME( nOLDTIPO )   // retorna tipo anterior
return     
     

// +--------------------------------------------------------------------
// +
// +    Function miximpdbf()
// +
// +--------------------------------------------------------------------
// +
FUNCTION mix_impdbf(cARQORI,lincdados)

   LOCAL aINDICES
   LOCAL nINDICES
   LOCAL cINDEXNAME
   LOCAL J
   LOCAL msql
   LOCAL cTABLE
   LOCAL nCOUNT

   aINDICES := {}

   cTABLE := Space( 30 )

   hb_FNameSplit( cARQORI, nil, @cTable, NIL )
   cTABLE := AllTrim( cTABLE )

   IF cTIPOSQL="PARADOX"
      RETURN
   ENDIF 

   dbUseArea( .T., cORIDRIVER, cARQORI, cTABLE, .T., .T. )
   aSTRU    := dbStruct()
   nLASTREC := RecCount()
   zei_fort( nLASTREC,,, 0 )

    aINDICESx:=GeraINDICES()
    nIndexes := LEN(aINDICESx)
    FOR j := 1 TO nIndexes
        msql := aINDICESx[J,1]  //Create index
        AAdd( Aindices, msql )
    NEXT j

   msql := SqliteCreateTable( cTABLE, aSTRU, cTIPOSQL )
   mix_open()
   mix_executesql( msql )
   IF Len( aindices ) > 0
      mix_executesql( Aindices )   // Executa comando unico ou array de comandos
   ENDIF

  mix_executesql( Dialeto_begin() ) // Inicia transação
  nCont := 0

   IF lincdados
   dbGoTop()
   WHILE !Eof()
      zei_fort( nLASTREC,,, 1 )
      mSql := "INSERT INTO " + cTable + " VALUES "
      msql := msql + "("
      FOR i := 1 TO Len( aSTRU )
         mFldNm := aSTRU[ i, DBS_NAME ]
         IF i > 1
            mSql += ", "
         ENDIF
         mSql += c2sql( &mFldNm )
      NEXT
      mSql += ")"
      mix_executesql( msql )
      nCont++
      IF nCont % 500 == 0
         mix_executesql( Dialeto_commit() )
         mix_executesql( Dialeto_begin() )
      ENDIF
      dbSkip()
   ENDDO

   endif
   mix_executesql( Dialeto_commit() )
   dbCloseArea()
   mix_close()

   RETURN .T.


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function mixcreatedatabase()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION mixcreatedatabase()

   cnewDATABASEX := INPUTBOX( Space( 30 ), "Novo database" )
   cnewDATABASEX := AllTrim( cnewDATABASEX )
   IF !Empty( cnewDATABASEX )
      IF cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" .OR. cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" ;
            .OR. cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER"
         mix_executesql( "CREATE DATABASE IF NOT EXISTS " + Cnewdatabasex )
         // fechar a connecao e trocar o database
         // CDATABASEX:=CNEWDATABASEX
      ENDIF
      IF cTIPOSQL = "SQLITE" .OR. lMDB .OR. lACCDB .OR. lFDB
         mdbcria()
      ENDIF
   ENDIF



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function mix_executesql()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +

FUNCTION mix_executesql( eCOMANDO, lTRANS, lMES )

   LOCAL aCOMANDOS := {}
   LOCAL nFIM
   LOCAL i
   LOCAL lRet

   lRET := .T.
   IF ValType( LMES ) <> "L"
      lMES := .F.
   ENDIF
   IF ValType( eCOMANDO ) = "C"
      AAdd( aCOMANDOS, eCOMANDO )
   ELSE
      aCOMANDOS := eCOMANDO
   ENDIF
   nFIM := Len( aCOMANDOS )
   IF lTRANS
      rddInfo( RDDI_EXECUTE, Dialeto_begin() )
   ENDIF
   FOR i := 1 TO nfim
      cCOMANDO := aCOMANDOS[ I ]
      lRet     := rddInfo( RDDI_EXECUTE, cCOMANDO )
      IF rddInfo( RDDI_ERRORNO ) = 9999
         // da este error cuando delete no encuentra nada que borrar. No debería dar error.
         lRet := .T.
      ELSE
         IF Lmes
            MDT( cstr( rddInfo( RDDI_ERROR ) ) + " Error " + cstr( rddInfo( RDDI_ERRORNO ) ) )
         ENDIF
      ENDIF
   NEXT i
   IF lTRANS
      rddInfo( RDDI_EXECUTE, Dialeto_commit() )
   ENDIF
// RDDINFO(RDDI_EXECUTE, Dialeto_rollback())

   RETURN lRet


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function mix_Query()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION mix_Query()  // returns last sql instruction

   RETURN rddInfo( RDDI_QUERY )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function mix_open()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION mix_open()

   LOCAL cCONN

   cCONN := ""
   rddSetDefault( "SQLMIX" )
   DO CASE
   CASE cTIPOMIX = "MYSQL" .OR. cTIPOMIX = "MYSQL64"
      nCONN := rddInfo( RDDI_CONNECT, { "MYSQL", cSERVERX, cUSERX, cPASSX, cDATABASEX } )
   CASE cTIPOMIX = "PGSQL" .OR. cTIPOMIX = "PGSQL64"
      nCONN := rddInfo( RDDI_CONNECT, { "POSTGRESQL", cSERVERX, cUSERX, cPASSX, cDATABASEX } )
      IF nConn > 0
         // SE CONECTOU NO MIX, FORÇA O SCHEMA E ENCODING VIA INTERFACE RDD
         // O comando RD_EXECUTE envia a instrução direto para a linha ativa do banco
        rddInfo( RDDI_EXECUTE, "SET search_path TO myschema, public; SET client_encoding TO 'WIN1252';")
      ENDIF
      
   CASE cTIPOMIX = "SQLITE"
      nCONN := rddInfo( RDDI_CONNECT, { "SQLITE3", cDATABASEX } )
   CASE cTIPOMIX = "FIREBIRD"
      nCONN := rddInfo( RDDI_CONNECT, { "FIREBIRD", cDATABASEX } )
      
   CASE cTIPOMIX = "ORACLE"
      nCONN := rddInfo( RDDI_CONNECT, { "OCILIB", cSERVERX, cUSERX, cPASSX, cDATABASEX } )
  CASE cTIPOMIX = "ODBC"  .AND. cTIPODBC =  "DSN"    
       cCONN:="Provider=MSDASQL;Data Source="+cBANCOX+";" //Uid=admin;Pwd=secret;"
      
       nCONN := rddInfo( RDDI_CONNECT, { "ODBC", cCONN } )
   CASE cTIPOMIX = "ODBC"  // Cserver Conneccao
      Set( _SET_DATEFORMAT, "yyyy-mm-dd" )
      cCONN := GERACONN( cDATABASEX, .F. )  // Sqlmix usa driver no lugar de provider(adooledb) geraconn(cCAMBASE,lPROVIDER)
      nCONN := rddInfo( RDDI_CONNECT, { "ODBC", cCONN } )
   ENDCASE
   
   IF !( nConn > 0 )
      mdt( "Erro ao connectar " + cServerx + " " + cstr( rddInfo( RDDI_ERROR ) ) + " Error" + cstr( rddInfo( RDDI_ERRORNO ) ) )
      nConn := 0
   ENDIF

   RETURN nConn


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function mix_close()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION mix_close()

   IF ! Empty( nconn ) .AND. nConn <> 0
      rddInfo( RDDI_DISCONNECT, nConn )
   ENDIF


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function mix_AFFECTEDROWS()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
function mix_AFFECTEDROWS()
LOCAL nRetVal
nRetVal:=0
IF ! Empty( nconn ) .AND. nConn <> 0
     nRetVal := rddInfo( RDDI_AFFECTEDROWS,,, nConn )
ENDIF
return nRetVal


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function mix_Conn()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +

FUNCTION mix_Conn()

   IF HB_ISNIL( nConn )
      // Select the default connection.
      nConn := rddInfo( RDDI_CONNECTION )  // esto NO selecciona una conexion, siempre regresa cero 0
   ELSE
      // Select the current connection.
      // msgbox("Seleccionando conexcion "+str(nConn))
      // RDDINFO(RDDI_CONNECTION,,,nConn)
      nConn := rddInfo( RDDI_CONNECTION,,, nConn )
   ENDIF

   RETURN nConn


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function mixexpformat()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION mixexpformat()

   mdbtabela( cdatabasex )
   LCOPIANAT := .F.  // MDG("Copia Nativa(SIM) Interna(NAO)") //copy to nao implemntado sqlmix
   tDOC      := pegtipodoc()   // .t. Inclui dbf se for nativa
   pegparexp()
   lDOCCAB   := .F.
   lDOCDAD   := .F.
   lDOCRECNO := .F.
   cSUBTIPO  := " "
   PegcsUB( tDOC )   // pegar o subtipo conforme tipo
   cDESTINO := cTABELAX + "_" + cTIPOSQL + "_rddmix." + zEXPOREXT
   MDT( cDESTINO )
   MDT( "abrindo arquivo de origem: " + cTABELAX )
   dbUseArea( .T.,, "SELECT * FROM " + cTABELAX, cTABELAX )
   nLASTREC := LastRec()
   zei_fort( nLASTREC,,, 0 )
   aSTRU := dbStruct()
   multidocg( lDOCCAB, lDOCDAD, lDOCRECNO, cSUBTIPO, TIRAEXT( cDESTINO ), aSTRU )
   dbCloseArea()


// + EOF: dbumix.prg
// +
