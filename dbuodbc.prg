// +--------------------------------------------------------------------
// +
// +   git\core\contrib\hbodbc\
// +
// +
// +--------------------------------------------------------------------
// +


// +--------------------------------------------------------------------
// +
// +
// +    Programa  : dbuodbc.prg
// +
// +     Sistema:
// +
// +     Linguagem: Harbour
// +
// +     Autor: jcassiano
// +
// +     Copyright (c) 2024,  jcassiano
// +
// +    Documentado em 28-Dez-2024 as 10:07 am
// +
// +--------------------------------------------------------------------
// +

#require "hbodbc"
#require "hbmemio"

#include "dbstruct.ch"
#include "BOX.CH"
#include "TRY.CH"
#include "DBINFO.CH"
#include "hbVER.CH"
#include "SQL.CH"



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function odbcmenu()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION odbcmenu( cUSOSQL )

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

// escolhe o arquivos
   IF lMDB .OR. lACCDB .OR. cTIPOSQL = "SQLITE"
      OPENTIPOARQ()
   ENDIF


   WHILE .T.
      hb_DispBox( 3, 18, 18, 55, B_DOUBLE + " " )
      @ 03, 24 SAY "ODBC" + " " + cTIPOSQL + " " + cDATABASEX
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
         odbccriadatabase()
      CASE KEY = 2
         IF lMDB .OR. lACCDB
         ELSE
            mdbdatabases()
         ENDIF
      CASE KEY = 3
         odbcimpdbf()
      CASE KEY = 4
         mdbtabela( cdatabasex )
      CASE KEY = 5
         odbcexpdbf( 1 )
      CASE KEY = 6
         odbcdeltable()
      CASE KEY = 7
         odbcexpdbf( 2 )
      CASE KEY = 8
         odbcExecArqSql()
      CASE KEY = 9
          sqlrdd_ODBC_info()          
      OTHERWISE
         RETURN
      ENDCASE
   ENDDO


   RESTAA( aAMBIENTE )
   LAYOUT()

   RETURN .T.



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function odbccriadatabase()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION odbccriadatabase()

   cnewDATABASEX := INPUTBOX( Space( 30 ), "Novo database" )
   cnewDATABASEX := AllTrim( cnewDATABASEX )
   IF !Empty( cnewDATABASEX )
      IF cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" .OR. cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER"
         odbcexecsql( "CREATE DATABASE IF NOT EXISTS " + Cnewdatabasex )
      ENDIF
      IF cTIPOSQL = "SQLITE" .OR. lMDB .OR. lACCDB .OR. lFDB
         mdbcria()
      ENDIF
   ENDIF

   RETURN .T.

*+--------------------------------------------------------------------
*+
*+    Function odbcExecArqSql()
*+
*+--------------------------------------------------------------------
*+
function odbcExecArqSql()

LOCAL cCOMANDO := ""
LOCAL cARQIMP  := ""

cARQIMP := win_GetOPENFileName(,"Arquivos SQL",HB_CWD(),"Arquivos SQL","*.SQL",1)
//cARQORI := OPENTIPOARQ()

IF FILE(cARQIMP)
   //nao pode ser linha a linha pois um comando pode estar em mais de uma linha
   cCOMANDO:=MEMOREAD(cARQIMP)
   odbcexecsql(cCOMANDO)
endif
return .t.


Function odbcimpdbf()
 nOLDTIPO := TIPODBF
            alertX( "escolha origem" )
            tipodbfesc()
            nORITIPO   := TIPODBF
            cORIDRIVER := RDDNOME( TIPODBF )
            lincdados:=mdg("Incluir Dados")
            IF MDG("Arquivo individual")
               cARQORI    := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*."+TABLEEXT, 1 )
                IF File( cARQORI )
                   odbc_impdbf(cARQORI,lincdados )
                ENDIF
            ELSE
               cPASTA:=SelectFolder()
               cPASTA+="\*."+TABLEEXT 
               //FAZERDBF(bUSO                                       , lSHARE[.F.] , bPRE, bPOS, cMASK ,LOPEN )
               FAZERDBF( {|| odbc_impdbf(cCAMINHOCOMPLETO,lincdados ) }, .F. ,     ,     ,cPASTA,.F.)
            ENDIF   
            RDDNOME( nOLDTIPO )   // retorna tipo anterior
return


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function odbcimpdbf()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION odbc_impdbf(cARQORI,lincdados )

   LOCAL aINDICES
   LOCAL nINDICES
   LOCAL cINDEXNAME
   LOCAL J
   LOCAL msql
   LOCAL cTABLE
   LOCAL cCONN

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
   odbcexecsql( msql )
   IF Len( aindices ) > 0
      odbcexecsql( Aindices )  // Executa comando unico ou array de comandos
   ENDIF

   cCONN       := GERACONN( cDATABASEX, .F. )
   dsFunctions := TODBC():New( cCONN )
   
   if ! dsFunctions:lSuccess
      Alert( "Falha na conexao ODBC no modulo dbuodbc!" )
      return .f.
   endif
    
    
   if cTIPOSQL == "PGSQL" .OR. cTIPOSQL == "PGSQL64" .OR. cTIPOSQL == "POSTGRESQL"  
      dsFunctions:SetSQL( "SET search_path TO myschema, public; SET client_encoding TO 'WIN1252';" )
      dsFunctions:ExecSQL()
   endif
   
   nCont := 0

  dsFunctions:SETSQL( Dialeto_begin() )
      dsFunctions:ExecSQL()

   if lincdados
     dbSelectArea( cTABLE )
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
  	  
  	  
        dsFunctions:SETSQL( mSQL )
        dsFunctions:ExecSQL()
  	  
  	   nCont++
        IF nCont % 500 == 0
           dsFunctions:SETSQL( Dialeto_commit()  )
           dsFunctions:ExecSQL()
  		 dsFunctions:SETSQL( Dialeto_begin() )
           dsFunctions:ExecSQL()
  		 
        ENDIF
        dbSkip()
     ENDDO
  ENDIF
   
   dsFunctions:SETSQL( Dialeto_commit()  )
   dsFunctions:ExecSQL()
   dbCloseArea()
   dsFunctions:Destroy()

   RETURN .T.


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function odbcexpdbf()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION odbcexpdbf( ntipo )

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


   mdbtabela( cdatabasex )
   cCONN       := GERACONN( cDATABASEX, .F. )
   dsFunctions := TODBC():New( cCONN )
    if ! dsFunctions:lSuccess
      Alert( "Falha na conexao ODBC no modulo dbuodbc!" )
      return .f.
   endif
   
    if cTIPOSQL == "PGSQL" .OR. cTIPOSQL == "PGSQL64" .OR. cTIPOSQL == "POSTGRESQL"  
      dsFunctions:SetSQL( "SET search_path TO myschema, public; SET client_encoding TO 'WIN1252';" )
      dsFunctions:ExecSQL()
   endif
   
   dsFunctions:SetSQL( "SELECT * FROM " + cTABELAX )
   dsFunctions:Open()

   nLASTREC := dsFunctions:LastRec()
   zei_fort( nLASTREC,,, 0 )

   aSTRU := {}
   nFIM  := Len( dsFunctions:Fields )
   FOR i := 1 TO nFIM
      // aqui o posicionameto e 2,3,4,5 diferente do padrao dbstruct 1,2,3,4
      cFieldName   := dsFunctions:FIELDS[ i, 2 ]
      cFieldType   := dsFunctions:FIELDS[ i, 3 ]
      nFieldLength := dsFunctions:FIELDS[ i, 4 ]
      nFieldDec    := dsFunctions:FIELDS[ i, 5 ]
      // sql.ch Standard SQL datatypes, using ANSI type numbering
      DO CASE
      CASE cFIELDTYPE = SQL_CHAR
         cFIELDTYPE := "CHAR"
      CASE cFIELDTYPE = SQL_NUMERIC
         cFIELDTYPE := "NUMERIC"
      CASE cFIELDTYPE = SQL_DECIMAL
         cFIELDTYPE := "DECIMAL"
      CASE cFIELDTYPE = SQL_INTEGER
         cFIELDTYPE := "INTEGER"
      CASE cFIELDTYPE = SQL_SMALLINT
         cFIELDTYPE := "SMALLINT"
      CASE cFIELDTYPE = SQL_FLOAT
         cFIELDTYPE := "FLOAT"
      CASE cFIELDTYPE = SQL_REAL
         cFIELDTYPE := "REAL"
      CASE cFIELDTYPE = SQL_DOUBLE
         cFIELDTYPE := "DOUBLE"
      CASE cFIELDTYPE = SQL_DATE
         cFIELDTYPE := "DATE"
      CASE cFIELDTYPE = SQL_TIME
         cFIELDTYPE := "TIME"
      CASE cFIELDTYPE = SQL_TIMESTAMP
         cFIELDTYPE := "TIMESTAMP"
      CASE cFIELDTYPE = SQL_VARCHAR
         cFIELDTYPE := "VARCHAR"
      CASE cFIELDTYPE = SQL_TYPE_DATE
         cFIELDTYPE := "TYPE_DATE"
      CASE cFIELDTYPE = SQL_TYPE_TIME
         cFIELDTYPE := "TYPE_TIME"
      CASE cFIELDTYPE = SQL_TYPE_TIMESTAMP
         cFIELDTYPE := "TYPE_TIMESTAMP"
      CASE cFIELDTYPE = SQL_LONGVARCHAR
         cFIELDTYPE := "LONGVARCHAR"
      CASE cFIELDTYPE = SQL_BINARY
         cFIELDTYPE := "BINARY"
      CASE cFIELDTYPE = SQL_VARBINARY
         cFIELDTYPE := "VARBINARY"
      CASE cFIELDTYPE = SQL_LONGVARBINARY
         cFIELDTYPE := "LONGVARBINARY"
      CASE cFIELDTYPE = SQL_BIGINT
         cFIELDTYPE := "BIGINT"
      CASE cFIELDTYPE = SQL_TINYINT
         cFIELDTYPE := "TINYINT"
      CASE cFIELDTYPE = SQL_BIT
         cFIELDTYPE := "BIT"
      CASE cFIELDTYPE = SQL_WCHAR
         cFIELDTYPE := "WCHAR"
      CASE cFIELDTYPE = SQL_WVARCHAR
         cFIELDTYPE := "WVARCHAR"
      CASE cFIELDTYPE = SQL_NVARCHAR
         cFIELDTYPE := "WVARCHAR"
      CASE cFIELDTYPE = SQL_WLONGVARCHAR
         cFIELDTYPE := "WLONGVARCHAR"
      ENDCASE

      AAdd( aSTRU, geracampodbf( cFieldName, cFieldType, nFieldLength, nFieldDec ) )
   NEXT


   avalor   := {}
   cDESTINO := cTABELAX + "_" + cTIPOSQL
   IF nTIPO = 1  // arquivo fisico
      MDT( cDESTINO )
      dbCreate( cDESTINO, aSTRU, "DBFCDX" )
      dbUseArea( .T., "DBFCDX", cDESTINO, "DESTINO", .T., .F. )
   ELSE
      dbCreate( "mem:destino", aSTRU,, .T., "DESTINO" )
   ENDIF

   WHILE !dsFunctions:Eof()
      FOR I := 1 TO nFIM
         AAdd( aVALOR, dsFunctions:FIELDS[ i ] :VALUE )
      NEXT I
      dbSelectAr( "DESTINO" )
      NETRECAPP()
      FOR I := 1 TO nFIM
         eVALOR := aVALOR[ I ]
         IF ValType( eVALOR ) = "C" .AND. SubStr( eVALOR, 5, 1 ) = "-" .AND. SubStr( eVALOR, 8, 1 ) = "-"
            eVALOR := SubStr( eVALOR, 6, 2 ) + "/" + SubStr( eVALOR, 9, 2 ) + "/" + SubStr( eVALOR, 1, 4 )
            eVALOR := CToD( eVALOR )
         ENDIF
         IF ValType( eVALOR ) = "C" .OR. ValType( eVALOR ) = "M"
            //eVALOR := RANGEREPL( Chr( 0 ), Chr( 31 ), eVALOR, " " )   // Remove caracteres de controle
            //eVALOR := TIRACE( eVALOR )
               eVALOR := FixSRTExtendido( eVALOR , .T. , .T. , .T. , .T. , .T. )
            //FixSRTExtendido( cVALOR,lLOW,lUP,lACE,lUTF, lESP )
         ENDIF
         IF !Empty( eVALOR )
            FieldPut( I, eVALOR )
         ENDIF
      NEXT I
      zei_fort( nLASTREC,,, 1 )
      dsFunctions:Skip()
   ENDDO
   dsFunctions:Close()
   dsFunctions:Destroy()

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
// +    Function odbcdeltable()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION odbcdeltable()

   mdbtabela( cdatabasex )
   IF ! MDG( "Apagar Tabela" + cTABELAX )
      RETURN .F.
   ENDIF
   odbcexecsql( "DROP TABLE  " + cTABELAX )

   RETURN .T.


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function odbcexecsql()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION odbcexecsql( eCOMANDO )

   LOCAL aCOMANDOS := {}
   LOCAL nFIM
   LOCAL i
   LOCAL cCONN

   IF ValType( eCOMANDO ) = "C"
      AAdd( aCOMANDOS, eCOMANDO )
   ELSE
      aCOMANDOS := eCOMANDO
   ENDIF
   cCONN       := GERACONN( cDATABASEX, .F. )
   dsFunctions := TODBC():New( cCONN )
   if ! dsFunctions:lSuccess
      Alert( "Falha na conexao ODBC no modulo dbuodbc!" )
      return .f.
   endif
   
    if cTIPOSQL == "PGSQL" .OR. cTIPOSQL == "PGSQL64" .OR. cTIPOSQL == "POSTGRESQL"  
      dsFunctions:SetSQL( "SET search_path TO myschema, public; SET client_encoding TO 'WIN1252';" )
      dsFunctions:ExecSQL()
   endif
   
   nFIM        := Len( aCOMANDOS )
   FOR i := 1 TO nfim
      cCOMANDO := aCOMANDOS[ I ]
      dsFunctions:SetSQL( cCOMANDO )
      dsFunctions:ExecSQL()
   NEXT i
   dsFunctions:Destroy()

   RETURN .T.


// + EOF: dbuodbc.prg
// +
