// +--------------------------------------------------------------------
// +
// +   
// +
// +
// +--------------------------------------------------------------------
// +


// +--------------------------------------------------------------------
// +
// +    Programa  : dbuadox.prg
// +
// +     Sistema:
// +
// +     Linguagem: Harbour
// +
// +     Autor: jcassiano
// +
// +     Copyright (c) 2024,  jcassiano
// +
// +    Documentado em 28-Dez-2024 as 10:06 am
// +
// +
// +--------------------------------------------------------------------
// +

#require "hbmemio"

#include "dbstruct.ch"
#include "BOX.CH"
#include "TRY.CH"
#include "DBINFO.CH"
#include "hbVER.CH"




// +--------------------------------------------------------------------
// +
// +
// +
// +    Function adoxmenu()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION adoxmenu( cUSOSQL )

   LOCAL aAMBIENTE

   cTIPOSQL := cUSOSQL   // Passa para privada usadas nas funcoes aBaixo

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
   CTIPOMIX :="ODBC"
   cTIPODBC :="ODBC"

   pegcfgbanco()

// Cria variaveis e inicializa obrigatorio
   ADOSetRDD( cTIPOSQL )
   
   /*
   ADOSetRDD( "ACCESS" )  seta tipo conecao
   ADOFile( "clientes" ) verifica arquivo ou tabela
   ADOEXECUTE(cSQL)
   ADOCopy2DBF() nao implantado
   ADOIndex( "clientes", "nome", "CliNome", .t. )
   ADOSetOrder( 1 )
   ADOAlias()
   ADOSORT()
   ADOSETFILTER()
   */

   WHILE .T.
      hb_DispBox( 3, 18, 18, 55, B_DOUBLE + " " )
      @ 03, 24 SAY "ADOX" + " " + cTIPOSQL + " " + cDATABASEX
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
         adoxcriadatabase()
      CASE KEY = 2
         IF lMDB .OR. lACCDB
         ELSE
            mdbdatabases()
         ENDIF
      CASE KEY = 3
         adoximpdbf()
      CASE KEY = 4
         mdbtabela( cdatabasex )
      CASE KEY = 5
         adoxexpdbf( 1 )
      CASE KEY = 6
         adoxdeltable()
      CASE KEY = 7
         adoxexpdbf( 2 )
      CASE KEY = 8
          adoxExecArqSql()
       CASE KEY = 9
          sqlrdd_ODBC_info()        
      OTHERWISE
         RETURN
      ENDCASE
   ENDDO


   RESTAA( aAMBIENTE )
   LAYOUT()

   RETURN .T.


*+--------------------------------------------------------------------
*+
*+    Function adoxExecArqSql()
*+
*+--------------------------------------------------------------------
*+
function adoxExecArqSql()

LOCAL cCOMANDO := ""
LOCAL cARQIMP  := ""

cARQIMP := win_GetOPENFileName(,"Arquivos SQL",HB_CWD(),"Arquivos SQL","*.SQL",1)
//cARQORI := OPENTIPOARQ()

IF FILE(cARQIMP)
   //nao pode ser linha a linha pois um comando pode estar em mais de uma linha
   cCOMANDO:=MEMOREAD(cARQIMP)
   adoxexecsql(cCOMANDO)
endif
return .t.
     

// +--------------------------------------------------------------------
// +
// +
// +
// +    Function adoxcriadatabase()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION adoxcriadatabase()

   cnewDATABASEX := INPUTBOX( Space( 30 ), "Novo database" )
   cnewDATABASEX := AllTrim( cnewDATABASEX )
   IF !Empty( cnewDATABASEX )
      IF cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" .OR. cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER"
         adoxexecsql( "CREATE DATABASE IF NOT EXISTS " + Cnewdatabasex )
      ENDIF
      IF cTIPOSQL = "SQLITE" .OR. lMDB .OR. lACCDB .OR. lFDB
         mdbcria()
      ENDIF
   ENDIF

   RETURN .T.


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function adoximpdbf()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
Function adoximpdbf()
   IF cTIPOSQL="PARADOX"
      RETURN
   ENDIF   
   cMDBARQ := OPENTIPOARQ()
    nOLDTIPO := TIPODBF
            alertX( "escolha origem" )
            tipodbfesc()
            nORITIPO   := TIPODBF
            cORIDRIVER := RDDNOME( TIPODBF )
            lincdados:=mdg("Incluir Dados")
            IF MDG("Arquivo individual")
               cARQORI    := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*."+TABLEEXT, 1 )
                IF File( cARQORI )
                   adox_impdbf(cARQORI)
                ENDIF
            ELSE
               cPASTA:=SelectFolder()
               cPASTA+="\*."+TABLEEXT 
               //FAZERDBF(bUSO                                       , lSHARE[.F.] , bPRE, bPOS, cMASK ,LOPEN )
               FAZERDBF( {|| adox_impdbf(cARQORI,lincdados) }, .F. ,     ,     ,cPASTA,.F.)
            ENDIF   
            RDDNOME( nOLDTIPO )   // retorna tipo anterior
RETURN
  




// +--------------------------------------------------------------------
// +
// +
// +
// +    Function adoximpdbf()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION adox_impdbf(cARQORI,lincdados)

   LOCAL aINDICES
   LOCAL nINDICES
   LOCAL cINDEXNAME
   LOCAL J
   LOCAL msql
   LOCAL cTABLE
   LOCAL cCONN
   LOCAL nCAMPOS
   LOCAL cCAMPO


   aINDICES := {}
   cTABLE   := Space( 30 )
 

   dbUseArea( .T., cORIDRIVER, cARQORI, cTABLE, .T., .T. )
   aSTRU := dbStruct()

    aINDICESx:=GeraINDICES()
    nIndexes := LEN(aINDICESx)
    FOR j := 1 TO nIndexes
        msql := aINDICESx[J,1]  //Create index
        AAdd( Aindices, msql )
    NEXT j


   msql := SqliteCreateTable( cTABLE, aSTRU, cTIPOSQL )
   adoxexecsql( msql )
   IF Len( aindices ) > 0
      adoxexecsql( Aindices )  // Executa comando unico ou array de comandos
   ENDIF

   cCONN := GERACONN( cDATABASEX )

   ADOCONNECT( cCONN )
   ADOUSE( cTABLE )
   ADOSELECT( cTABLE )


   dbSelectArea( cTABLE )
   IF lincdados
       nLASTREC := RecCount()
       nCAMPOS  := FCount()
       zei_fort( nLASTREC,,, 0 )
       dbGoTop()
       WHILE !Eof()
          zei_fort( nLASTREC,,, 1 )
          ADOAPPEND()
          FOR i := 1 TO nCAMPOS
             cCAMPO := aSTRU[ i, DBS_NAME ]
             ADOREPLACE( cCAMPO, FieldGet( i ) )
          NEXT I
          ADOCOMMIT()
          dbSelectArea( cTABLE )
          dbSkip()
       ENDDO
   ENDIF
   dbCloseArea()
   ADOCLOSE()
   ADODISCONNECT()

   RETURN .T.


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function adoxexpdbf()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION adoxexpdbf( ntipo )

   LOCAL aSTRU
   LOCAL cCONN
   LOCAL i
   LOCAL nFIM
   LOCAL aVALOR

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


   cMDBARQ := OPENTIPOARQ()

   mdbtabela( cdatabasex )

   cCONN := GERACONN( cDATABASEX )
   ADOCONNECT( cCONN )
   IF Empty( cTABELAX )
      mdbtabela( adotables() )
   ENDIF


   aSTRU2 := MDBTABLES( cDataBaseX, cTABELAX )

   ADOUSE( cTABELAX )
   ADOSELECT( cTABELAX )
   aSTRU    := ADOSTRU()
   nFIM     := Len( aSTRU )
   nLASTREC := ADORecCount()
   zei_fort( nLASTREC,,, 0 )



   avalor   := {}
   cDESTINO := cTABELAX + "_" + cTIPOSQL
   IF nTIPO = 1  // arquivo fisico
      MDT( cDESTINO )
      dbCreate( cDESTINO, aSTRU, "DBFCDX" )
      dbUseArea( .T., "DBFCDX", cDESTINO, "DESTINO", .T., .F. )
   ELSE
      dbCreate( "mem:destino", aSTRU,, .T., "DESTINO" )
   ENDIF

   WHILE ! ADOEof()  // .AND. .NOT. ADOBOF()
      dbSelectAr( "DESTINO" )
      NETRECAPP()
      FOR I := 1 TO nFIM
         cCAMPO := aSTRU[ i, DBS_NAME ]
         eVALOR := ADOField( Ccampo )
         IF ValType( eVALOR ) = "C" .AND. SubStr( eVALOR, 5, 1 ) = "-" .AND. SubStr( eVALOR, 8, 1 ) = "-" //Data vindo como string
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
      zei_fort( nLASTREC,,, 1 )
      ADOMoveNext()
   ENDDO

   ADOCLOSE()
   ADODISCONNECT()


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

   IF nTIPO = 2
      dbDrop( "mem:destino" )
   ENDIF

   RETURN .T.




// +--------------------------------------------------------------------
// +
// +
// +
// +    Function adoxdeltable()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION adoxdeltable()

   mdbtabela( cdatabasex )
   IF ! MDG( "Apagar Tabela" + cTABELAX )
      RETURN .F.
   ENDIF
   adoxexecsql( "DROP TABLE  " + cTABELAX )

   RETURN .T.


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function adoxexecsql()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION adoxexecsql( eCOMANDO )

   LOCAL aCOMANDOS := {}
   LOCAL nFIM
   LOCAL i
   LOCAL cCONN

   IF ValType( eCOMANDO ) = "C"
      AAdd( aCOMANDOS, eCOMANDO )
   ELSE
      aCOMANDOS := eCOMANDO
   ENDIF
   cCONN := GERACONN( cDATABASEX )
   ADOCONNECT( cCONN )
   nFIM := Len( aCOMANDOS )
   FOR i := 1 TO nfim
      cCOMANDO := aCOMANDOS[ I ]
      ADOEXECUTE( cCOMANDO )
   NEXT i
   ADODISCONNECT()

   RETURN .T.

// + EOF: dbuadox.prg
// +
