// +--------------------------------------------------------------------
// +
// +   c:\devgit\core\contrib\hbpgsql\
// +
// +
// +--------------------------------------------------------------------
// +

// +--------------------------------------------------------------------
// +
// +    Programa  : dbupg.prg
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

#require "hbpgsql"

#include "dbstruct.ch"
#include "box.ch"
#include "DBINFO.CH"
#include "hbVER.CH"



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function pgsqlmenu()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION pgsqlmenu()

   PRIV oServer, oQuery, oRow

   aAMBIENTE  := SALVAA()
   cTIPOSQL   := "PGSQL"
   cSERVERX   := "localhost" + Space( 21 )
   cUSERX     := PadR( "postgres", 30, " " )
   cDATABASEX := Space( 30 )
   cPASSX     := Space( 30 )
   cTABELAX   := Space( 30 )

   loledb := hb_Version( HB_VERSION_BITWIDTH ) <> 64   // mdg("User sim=odbc 8.0(32b) nao=odbc 9.0(64b)")
   lMDB   := .F.
   lACCDB := .F.
   lFDB   := .F.

   OPENTIPOARQ()

// usar mdbdatabases fde mdb2dbf a classe precisa do database para iniciar tambem nao possuio methodo dblist como a do mysql
   mdbdatabases()

   IF Empty( cDATABASEX )
      cDATABASEX := INPUTBOX( Space( 30 ), "Database" )
      cDATABASEX := AllTrim( cDATABASEX )
   ENDIF

   cPathx := "public"
   pgsetdatabase( .F. )


   WHILE .T.
      hb_DispBox( 3, 18, 18, 55, B_DOUBLE + " " )
      @ 03, 24 SAY cDATABASEX
      OPCAO(  4, 24, "&Criar database            ", 67 )   // C
      OPCAO(  5, 24, "&Database Selecionar       ", 68 )   // D
      OPCAO(  6, 24, "&Importar  DBF             ", 73 )   // I
      OPCAO(  7, 24, "&Tabelas                   ", 84 )   // T
      OPCAO(  8, 24, "&Exportar  DBF             ", 69 )   // E
      OPCAO(  9, 24, "&Apagar Tabela             ", 65 )   // A
      OPCAO( 10, 24, "Exportar &Formatos         ", 70 )  // F 
      OPCAO( 11, 24, "Executar arquivo &SQL      ", 83)   //S 83
      KEY := menu( 1, 0 )
      DO CASE
      CASE KEY = 1
         PGsqlnewdatabase()
      CASE KEY = 2
         mdbdatabases()
         pgsetdatabase( .T. )
      CASE KEY = 3
         dbf2Pgsql()
      CASE KEY = 4
         PGSELECTTABLE()
      CASE KEY = 5
         PGstrutodbf()
      CASE KEY = 6
         PGDELTABLE()
      CASE KEY = 7
         pgexpformat()
      CASE KEY = 8
         pgExecArqSql()   
      OTHERWISE
         RETURN
      ENDCASE
   ENDDO



   oserver:destroy()
   RESTAA( aAMBIENTE )
   layout()

   RETURN .T.

 *+--------------------------------------------------------------------
*+
*+    Function pgExecArqSql()
*+
*+--------------------------------------------------------------------
*+
function pgExecArqSql()

LOCAL cCOMANDO := ""
LOCAL cARQIMP  := ""

cARQIMP := win_GetOPENFileName(,"Arquivos SQL",HB_CWD(),"Arquivos SQL","*.SQL",1)
//cARQORI := OPENTIPOARQ()

IF FILE(cARQIMP)
   //nao pode ser linha a linha pois um comando pode estar em mais de uma linha
   cCOMANDO:=MEMOREAD(cARQIMP)
   oSERVER:EXECUTe(cCOMANDO)
   IF oServer:NetErr()
      Alert( oServer:ErrorMSG() )
      RETURN .F.
   ENDIF
endif
return .t.
     

// +--------------------------------------------------------------------
// +
// +
// +
// +    Function PGDELTABLE()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION PGDELTABLE()

   PGSELECTTABLE()
   IF hb_AScan( oServer:ListTables(), cTABELAX,,, .T. ) > 0
      IF MDG( "Apagar " + cTABELAX + " apagara todas informacoes" )
         oServer:DeleteTable( cTABELAX )
         IF oServer:NetErr()
            MDT( oServer:ErrorMSG() )
            RETURN .F.
         ENDIF
      ELSE
         RETURN .F.
      ENDIF
   ENDIF

   RETURN .T.


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function PGSELECTTABLE()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION PGSELECTTABLE()

   LOCAL nCHOICES

   nCHOICES := 0
   aResult  := oServer:ListTables()
   IF Len( aResult ) > 0
      hb_DispBox( 3, 22, 22, 55, B_DOUBLE + " " )
      nChoices := AChoice( 4, 23, 21, 54, aResult )
   ENDIF
   cTABELAX := iif( nChoices > 0, aResult[ nChoices ], "" )

   RETURN aResult


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function pgsetdatabase()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION pgsetdatabase( ldestroy )

   IF lDESTROY
      oserver:destroy()
   ENDIF
   oServer := TPQServer():New( cserverx, cDatabasex, cUserx, cPassx,, cPathx )
   IF oServer:NetErr()
      Alert( oServer:ErrorMSG() )
      RETURN .F.
   ENDIF

   RETURN .T.



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function PGsqlnewdatabase()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION PGsqlnewdatabase()

   cnewDATABASEX := INPUTBOX( Space( 30 ), "Novo database" )
   cnewDATABASEX := AllTrim( cnewDATABASEX )
   IF ! Empty( cnewDATABASEX )
      IF hb_AScan( Oserver:ListDBs(), cnewDATABASEX,,, .T. ) > 0
         MDT( "Ja existe Database " + cnewDATABASEX )
         RETURN .F.
      ELSE
	     oSERVER:EXECUTE( "CREATE DATABASE  " + Cnewdatabasex )
         IF oServer:NetErr()
            Alert( oServer:ErrorMSG() )
            RETURN .F.
         ENDIF
         cDATABASEX := cNEWDATABASEx
         pgsetdatabase( .T. )
      ENDIF
   ENDIF

   RETURN .T.


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function PGstrudbf()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION PGstrudbf()

   LOCAL aRETU

   aRETU := {}

   cCOMANDO := "SELECT   column_name,  udt_name,   character_maximum_length,   numeric_precision,  numeric_scale ,  data_type "
   cCOMANDO += " FROM   information_schema.columns "
   cCOMANDO += " WHERE   table_name = '" + cTABELAX + "' ORDER BY ordinal_position ;"

   oQuery := oServer:Query( cCOMANDO )
   WHILE ! oQuery:Eof()
      cFieldName   := ''
      cFieldType   := ''
      nFieldLength := 0
      nFieldDec    := 0
      oRow         := oQuery:GetRow()

      // tmsql comeca com 1 padrao harbour
      cFieldName   := Upper( AllTrim( oRow:FieldGet( 1 ) ) )   // column_name 0
      cFieldType   := Upper( AllTrim( oRow:FieldGet( 2 ) ) )   // data_type1
      nFieldLength := fixnum( oRow:FieldGet( 3 ) )   // tamanho string character_maximum_length 2
      IF fixnum( oRow:FieldGet( 4 ) ) > 0  // tamannho numeric 3
         nFieldLength := fixnum( oRow:FieldGet( 4 ) )  // numeric_precision 3
         nFieldDec    := fixnum( oRow:FieldGet( 5 ) )  // numeric_scale 4
      ENDIF

      AAdd( aRETU, geracampodbf( cFieldName, cFieldType, nFieldLength, nFieldDec ) )

      oQuery:skip()
   ENDDO
   oquery:destroy()

   RETURN Aretu


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function PGstrutodbf()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION PGstrutodbf()

   LOCAL aRETU
   LOCAL i
   LOCAL nFIM
   LOCAL eVALOR

   PGSELECTTABLE()
   aRETU := PGstrudbf()

   dbCreate( ctabelaX + "_pgsql", aRETU, "DBFCDX" )
   dbUseArea( .T., "DBFCDX", ctabelaX + "_pgsql",, .F., .F. )

   oQuery2 := oServer:Query( "SELECT * FROM " + Chr( 34 ) + cTABELAx + Chr( 34 ) )   // aspas duplas tenta maiscula
   IF oServer:NetErr()
      MDT( oServer:ErrorMSG() )
      RETURN .F.
   ENDIF

   nFIM     := oQuery2:FCount()
   nLASTREC := oQuery2:LastRec()
   zei_fort( nLASTREC,,, 0 )

   WHILE ! oQuery2:Eof()
      oRow := oQuery2:GetRow()
      netrecapp()
      FOR I := 1 TO nFIM
         eVALOR := oRow:FieldGet( I )
         // datetime em modo texto
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

         IF ! Empty( evalor )
            FieldPut( i, eVALOR )
         ENDIF
      NEXT I
      zei_fort( nLASTREC,,, 1 )
      oQuery2:skip()
   ENDDO

   dbCloseAll()

   RETURN .T.



FUNCTION dbf2pgsql()
 nOLDTIPO := TIPODBF
            alertX( "escolha origem" )
            tipodbfesc()
            nORITIPO   := TIPODBF
            cORIDRIVER := RDDNOME( TIPODBF )
            lincdados:=mdg("Incluir Dados")
            IF MDG("Arquivo individual")
               cARQORI    := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*."+TABLEEXT, 1 )
                IF File( cARQORI )
                   pgsql_dbf(cARQORI,lincdados)
                ENDIF
            ELSE
               cPASTA:=SelectFolder()
               cPASTA+="\*."+TABLEEXT 
               //FAZERDBF(bUSO                                       , lSHARE[.F.] , bPRE, bPOS, cMASK ,LOPEN )
               FAZERDBF( {|| pgsql_dbf(cCAMINHOCOMPLETO,lincdados) }, .F. ,     ,     ,cPASTA,.F.)
            ENDIF   
            RDDNOME( nOLDTIPO )   // retorna tipo anterior


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function dbf2pgsql()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION pgsql_dbf(cARQORI,lincdados)

   cTABLE   := Space( 30 )
   IF File( cARQORI )
      hb_FNameSplit( cARQORI, nil, @cTable, NIL )
      cTABLE := AllTrim( cTABLE )
      dbUseArea( .T.,, cARQORI, "dbffile",, .T. )
      aDbfStruct := dbffile->( dbStruct() )
      nLASTREC   := RecCount()
      zei_fort( nLASTREC,,, 0 )
      IF hb_AScan( oServer:ListTables(), cTable,,, .T. ) > 0
         IF MDG( "Criar novamente " + cTABLE + " apagara todas informacoes" )
            oServer:DeleteTable( cTable )
            IF oServer:NetErr()
               MDT( oServer:ErrorMSG() )
               RETURN .F.
            ENDIF
         ELSE
            RETURN .F.
         ENDIF
      ENDIF
      oServer:CreateTable( cTable, aDbfStruct )
      IF oServer:NetErr()
         MDT( oServer:ErrorMSG() )
         dbCloseAll()
         RETURN .F.
      ENDIF

      aINDICES:=GeraINDICES()
      nIndexes := LEN(aINDICES)
      FOR j := 1 TO nIndexes
          msql := aINDICES[J,1]  //Create index
          oSERVER:execute( msql )
          //msql := aINDICES[J,2]   //insert into metadata
          //oSERVER:execute( msql )
      NEXT j



      // Initialize pgSQL table necessario para getblankrow ter um registro para montar a strutura
      oTable := oServer:Query( "SELECT * FROM " + Chr( 34 ) + Lower( cTable ) + Chr( 34 ) + " LIMIT 1" )   // dupla aspas tenta minuscula
      IF oTable:NetErr()
         Alert( oTable:ErrorMSG() )
         oTable := oServer:Query( "SELECT * FROM " + Chr( 34 ) + Upper( cTable ) + Chr( 34 ) + " LIMIT 1" )  // dupla aspas maiscula
         IF oTable:NetErr()
            Alert( oTable:ErrorMSG() )
            RETURN .F.
         ENDIF
      ENDIF


      IF lincdados
          DO WHILE !dbffile->( Eof() )

             oRecord := oTable:GetBlankRow()

             FOR i := 1 TO dbffile->( FCount() )
                oRecord:FieldPut( i, dbffile->( hb_FieldGet( i ) ) )
             NEXT

             oTable:Append( oRecord )
             IF oTable:NetErr()
                mdt( oTable:ErrorMSG() )
             ENDIF

             dbffile->( dbSkip() )

             zei_fort( nLASTREC,,, 1 )
          ENDDO
      ENDIF

      dbffile->( dbCloseArea() )


      oTable:Destroy()
      RDDNOME( nOLDTIPO )  // retorna tipo anterior
   ENDIF

   RETURN .T.



// + EOF: dbupg.prg
// +
