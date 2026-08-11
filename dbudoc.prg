// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +
// +    Source Module => DBUDOC.PRG
// +
// +    Functions: Function GERADOC()
// +               Function multidocs()
// +               Function multidocg()
// +               Function FAZERDBF(bUSO, lSHARE[.F.], bPRE, bPOS, cMASK["*."+TABLEEXT],LOPEN[.T.])
// +               Function GRAVADOC()
// +               Function TIPOC()
// +
// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

#include "BOX.CH"
#include "dbinfo.ch"
#include "dbstruct.ch"

// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +
// +    Function PEGTIPO2VAL(aESTRU)
// +
// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +
FUNCTION PEGTIPO2VAL(aESTRU)

   nLASTREC := LastRec()
   zei_fort( nLASTREC,,, 0 )
   dbGoTop()
   WHILE ! Eof()
      FOR X = 1 TO nFIELDS
         @ 3, 40 SAY PadR( aESTRU[ X ][ 1 ] )
         nVAL := hb_FieldGet( X )
         IF aESTRU[ X ][ 2 ] = "N"
            IF nVAL > aVAL[ X ]
               aVAL[ X ] := nVAL
            ENDIF
         ENDIF
         IF aESTRU[ X ][ 2 ] = "C"
            nVAL := Len( AllTrim( nVAL ) )
            IF nVAL > aVAL[ X ]
               aVAL[ X ] := nVAL
            ENDIF
         ENDIF
      NEXT X
      ZEI_FORT( nLASTREC,,, 1 )
      dbSkip()
   ENDDO

   RETURN

// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +
// +    Function GERADOC()
// +
// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +
FUNCTION GERADOC( tdoc )

   LOCAL stru_name
   LOCAL stru_base

// local aESTRU usada na pegval2 nao pode ser local
// local nFIELDS usada na pegval2 nao pode ser local
   LOCAL stru_nome
   LOCAL cTEXTO
   lDOCCAB := .F.
   lDOCDAD := .F.
   lDOCRECNO := .F.
   cSUBTIPO := " "
   IF Empty( M->cur_dbf )
      RETU .F.
   ENDIF

   IF tDOC = 0
      tdoc := pegtipodoc()
      IF tdoc = 0
         RETURN .F.
      ENDIF
      IF tDOC = 5 .or. tDOC = 6// parametros da exportacao delimitado
         pegparexp()
      ENDIF
   ENDIF


   stat_msg( "Lendo Estrutura do Arquivo" )
   stru_name := M->cur_dbf
   stru_base := SubStr( stru_name, 1, At( ".", stru_name ) - 1 )
   IF RAt( "\", STRU_BASE ) > 0
      STRU_BASE := SubStr( STRU_BASE, RAt( "\", STRU_BASE ) + 1 )
   ENDIF
   Select( M->cur_area )
   aESTRU := dbStruct()
   nFIELDS := Len( aESTRU )
   AVAL := Array( nFIELDS )
   AFill( aVAL, 0 )
   IF tDOC = 2 // Verificando o tamanho utilizado por cada campo
      PEGTIPO2VAL(aESTRU)
   ENDIF
   PegcsUB( tDOC )
   GRAVADOC( tdoc, stru_base, aESTRU, aVAL, lDOCCAB, lDOCDAD, cSUBTIPO, lDOCRECNO )
   stat_msg( "Documentacao Gerada" )



// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +
// +    Function PegcsUB()
// +
// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +
//

FUNCTION PegcsUB( tDOC )

   IF tDOC = 7    //xml
         nCHOICE := ALERT( "Tipo XML", { "MS", "PACKET", "ISO","XLSXLM"  } )
         DO CASE
         CASE nCHOICE = 1
            cSUBTIPO := "XML"
         CASE nCHOICE = 2
            cSUBTIPO := "PCK"
         CASE nCHOICE = 3
            cSUBTIPO := "ISO"
         CASE nCHOICE = 4
            cSUBTIPO := "XLSXLM"      
         ENDCASE
      lDOCDAD := MDG( "Gravar Dados" )
   ENDIF
   IF  tDOC = 1   //xls
       lDOCCAB := MDG( "Gravar Informacao Estrutura" )
       lDOCDAD := MDG( "Gravar Dados" )
       nCHOICE := ALERT( "Tipo XLS", { "TAB", "TRH-HTML", "TDB","XLSXLM" } )
         DO CASE
         CASE nCHOICE = 1   //xls
            tDOC := 5           //delimitado
            cSUBTIPO := "TAB"  //salva delimitado por tab 
         CASE nCHOICE = 2
            cSUBTIPO := "TRH"
         CASE nCHOICE = 3
            cSUBTIPO := "TDB"
         CASE nCHOICE = 4
            cSUBTIPO := "XLSXLM"   
         ENDCASE
   ENDIF
   IF  tDOC = 5 .OR.  tDOC = 6    //delimitado   //sdf
      lDOCCAB := MDG( "Gravar Informacao Estrutura" )
      lDOCDAD := MDG( "Gravar Dados" )
      IF lDOCDAD
         lDOCRECNO := MDG( "Incluir Recno()/ID" )
      ENDIF
      IF ZEXPOREXT = "SQL" .AND. tDOC = 5  //delimitado
         cSUBTIPO := "SQL"
      ENDIF
      IF tDOC=6
         zDELIMITE := ""
      ENDIF
   ELSE
      lDOCCAB := .T.
   ENDIF
   IF  tDOC = 8   //json
      lDOCDAD := .T.
      lDOCRECNO := .F. // A id do recno ja faz parte do json
   ENDIF


// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +
// +    Function multidocs()
// +    PARA tDOC, cMASK           // Passara outra funcao manter aqui para ficar como priv
// +
// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +

FUNCTION multidocs

   PARA tDOC, cMASK           // Passara outra funcao manter aqui para ficar como private
   LOCAL cPASTA               // se passar uma pasta incluir o filtro como exemplo multidocs(4, cPASTA+"\*."+TABLEEXT)  //4- dbe

   IF ValType( cMASK ) # "C"
      cMASK := "*."+TABLEEXT
      cPASTA:=SelectFolder()
      IF ! EMPTY(cPASTA)
         cMASK :=cPASTA + "\" + cMASK
      ENDIF
   ENDIF

   IF tDOC = 0
      tdoc := pegtipodoc()
      IF tdoc = 0
         RETURN .F.
      ENDIF
   ENDIF
   IF tDOC = 5 .or. tDOC = 6 // parametros da exportacao //delimitado sdf
      pegparexp()
   ENDIF
   lDOCCAB  := .F.
   lDOCDAD  := .F.
   lDOCRECNO := .F.
   cSUBTIPO := " "
   PegcsUB( tDOC )  // pegar o subtipo conforme tipo
   altd()
   DO CASE 
      CASE cSUBTIPO = "XLSXLM"                 //xlsxlm 
           FAZERDBF( {|| Fazerxlsxlm() }, .F.,,, cMASK )
      CASE tDOC = 1 .AND. cSUBTIPO = "TDB"    //xls
           FAZERDBF( {|| Fazerxlsclass() }, .F.,,, cMASK )
      CASE tdoc = 7 .AND. cSUBTIPO="XML"      //xlm 
          FAZERDBF( {|| dbf2xml() }, .F.,,, cMASK )
	  CASE tdoc = 14
          //FAZERDBF( {|| dbf2md() }, .F.,,, cMASK )	 
          //faztambem sqlite()
          //DocMarkdow()
          GeraMDdbml(cMASK)		  
      OTHERWISE
           FAZERDBF( {|| multidocg( lDOCCAB, lDOCDAD, lDOCRECNO, cSUBTIPO ) }, .F.,,, cMASK )
   ENDCASE
   stat_msg( "Documentacao Gerada" )

// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +
// +    Function multidocg()
// +
// +
// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +

FUNCTION multidocg( lDOCCAB, lDOCDAD, lDOCRECNO, cSUBTIPO, cARQDIC, aESTRU )

// Recebe aSTRU caso a base seja sql e tenha que sofrer transformacao
   IF ValType( aESTRU ) <> "A"
      aESTRU  := dbStruct()
   ENDIF
   IF ValType( cARQDIC ) <> "C" // memvar->ARQUIVO public do dbu melhorar posteriormente para sempre pegar paramentro cARQDIC
      cARQDIC := TIRAEXT( memvar->ARQUIVO )
   ENDIF
   aVAL := Array( Len( aESTRU ) )
   AFill( aVAL, 0 )
   nFIELDS := Len( aESTRU )
   IF tDOC = 2 // Verificando o tamanho utilizado por cada campo  TAM
      PEGTIPO2VAL(aESTRU)
   ENDIF
   GRAVADOC( tdoc, cARQDIC, aESTRU, aVAL, lDOCCAB, lDOCDAD, cSUBTIPO, lDOCRECNO )

// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +
// +    Function FAZERDBF(bUSO, lSHARE[.F.], bPRE, bPOS, cMASK["*."+TABLEEXT],LOPEN[.T.])
// +
// +
// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +

FUNCTION FAZERDBF( bUSO, lSHARE, bPRE, bPOS, cMASK,LOPEN )

   LOCAL cCAMMASK  := Space( 100 )
   LOCAL cCAMFILE  := Space( 50 )
   LOCAL cCAMEXT   := Space( 10 )
   PRIVATE cCAMINHOCOMPLETO
   
   cCAMINHOCOMPLETO:=''

   IF ValType( cMASK ) # "C" .OR. EMPTY(cMASK )
      cMASK := "*."+TABLEEXT
   ENDIF
   
   IF VALTyPE(lSHARE)<>"L"
      lSHARE:=.F.
   ENDIF
   
   IF VALTyPE(lOPEN)<>"L"
      lOPEN:=.T.
   ENDIF
   
   IF At( "\", cMASK ) > 0  // pega o caminho quando a mascara  vem c:\temp\uso.dbf  c:\temp\*.dbf filenames so retorna o nome
      hb_FNameSplit( cMASK, @cCAMMASK, @cCAMFILE, @cCAMEXT )
      IF ! EMPTY(cCAMMASK) .AND. EMPTY(cCAMEXT)
         cMASK:=cCAMMASK+"*."+TABLEEXT
      ENDIF
   ENDIF
   cCAMMASK := AllTrim( cCAMMASK )  //sava o caminho

   
   
   MATDBF := FILENAMES( cMASK ) //abre a mascara ou o caminho
   nARQ   := Len( MATDBF )
   IF nARQ > 0
      FOR w := 1 TO nARQ
         ARQUIVO := AllTrim( MATDBF[ w ] )
         IF ValType( bPRE ) = "B"
            Eval( bPRE )
         ENDIF
         IF ValType( bUSO ) = "B"
            IF File( cCAMMASK + ARQUIVO )
               MDS( "Arquivo: " + cCAMMASK + ARQUIVO )  //Remonta o caminho
               cCAMINHOCOMPLETO:=cCAMMASK + ARQUIVO
               IF lOPEN
                  DBUREDE( cCAMMASK + ARQUIVO,, lSHARE ) //abre o caminho
               ENDIF   
               nLASTREC := LastRec()
               zei_fort( nLASTREC,,, 0 )
               Eval( bUSO,, {|| zei_fort( nLASTREC,,, 1 ) } )
               IF lOPEN
                  dbCloseArea()
               ENDIF    
            ENDIF
         ENDIF
         IF ValType( bPOS ) = "B"
            Eval( bPOS )
         ENDIF
      NEXT w
   ENDIF
   MDS( "" )

// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +F
// +    Function GRAVADOC()
// aVAL maior dos campos usado no tipo TEC=3 /TAM=2
// lDOCCAB inclui cabecario
// lDOCDAD inclui dados registros
// cSUBTIPO subtipo alguns formartos
// lDOCREcno inclui uma coluna adicional com o recno()(id)
// +
// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +

FUNCTION GRAVADOC( tdoc, cARQ, aESTRU, aVAL, lDOCCAB, lDOCDAD, cSUBTIPO, lDOCRECNO )


   LOCAL cARQGRV := cARQ
   LOCAL cLIN := hb_osNewLine()
   LOCAL cVAL
   LOCAL cCAMPO
   LOCAL J, nIndexes
   LOCAL cINDEXNAME
   LOCAL cFieldName := ''
   LOCAL cFieldType := ''
   LOCAL nFieldLength := 0
   LOCAL nFieldDec := 0

   IF tDOC = 0
      tdoc := pegtipodoc()
      IF tdoc = 0
         RETURN .F.
      ENDIF
      IF tDOC = 5 .or. tdoc=6 // parametros da exportacao //delimitado
         pegparexp()
      ENDIF
      PegcsUB( tDOC )  // pegar o subtipo conforme tipo
   ENDIF

   IF tdoc = 7 .AND. cSUBTIPO="XML"    //xlm
      Dbf2Xml()
      RETURN .T.
   ENDIF
   
    IF tDOC = 1 .AND. cSUBTIPO = "TDB"  //xls
       Fazerxlsclass()
       RETURN .T.
   ENDIF    
   
    IF cSUBTIPO = "XLSXLM"         //xlsxlm 
       Fazerxlsxlm() 
       RETURN .T.
    ENDIF   

   IF zEXPOREXT = "XML" .AND. tDOC = 5   //xml //delimitado tab
      tDOC := 7
   ENDIF

   IF zEXPOREXT = "JSON"
      tDOC := 8    //json
   ENDIF
   IF tDOC = 4 // dbe
      lDOCDAD := .F.
      lDOCRECNO := .F.
      cSUBTIPO := ""
   ENDIF


   DO CASE
   case tDOC = 1    //xls
        cARQGRV += "_"+cSUBTIPO+"_.XLS"
   CASE tDOC = 2    //TAM 
      cARQGRV += ".TAM"
   CASE tDOC = 3    //TEC =3
      cARQGRV += ".TEC"
   CASE tDOC = 4    // dbe
      cARQGRV += ".DBE"
   CASE tDOC = 5  .OR. zEXPOREXT = "SQL" .OR. zEXPOREXT = "SSV" .OR. zEXPOREXT = "CSV" ;
         .OR. zEXPOREXT = "UNL" .OR. zEXPOREXT = "TSV" .OR. zEXPOREXT = "PSV"              //delimitado
      cARQGRV += "." + ZEXPOREXT
   CASE tDOC = 6   //sdf
      cARQGRV += ".SDF"
   CASE tDOC = 7  //xml
      cARQGRV += "_"+cSUBTIPO+"_.XLS"
   CASE tDOC = 8     //json
      cARQGRV += ".JSON"
   ENDCASE
   IF File( cARQGRV )
      FErase( cARQGRV )
   ENDIF

   nFIELDS := Len( aESTRU )
   cTEXTO  := ""
   IF nFIELDS = 0
      stat_msg( "Nao exitem campos na area selecionada" )
      RETURN .F.
   ENDIF
   IF tDOC = 4  // dbe
      cTEXTO += 'DBFDEF ' + Upper( cARQ ) + cLIN
   ENDIF
   IF tDOC = 3 .OR. tDOC = 2   //TAM=2  TEC=3
      cTEXTO += '+-----------------------------------------------------------------------------+' + cLIN
      cTEXTO += '| Arquivo          : ' + PadR( cARQ, 57 ) + '|' + cLIN
      cTEXTO += '| Atualizado em    : ' + PadR( LUpdate(), 57 ) + '|' + cLIN
      cTEXTO += '| No.de Registros  : ' + PadR( Str( LastRec(), 8, 0 ), 57 ) + '|' + cLIN
      cTEXTO += '| No.de Campos     : ' + PadR( Str( FCount(), 8, 0 ), 57 ) + '|' + cLIN
      cTEXTO += '| Tamanho Registro : ' + PadR( Str( RecSize(), 8, 0 ), 57 ) + '|' + cLIN
      cTEXTO += '|-----+------------+----------+-----+----+------------------------------------|' + cLIN
      cTEXTO += '| No. | Nome Campo | Tipo     | Com | De | Observacoes                        |' + cLIN
      cTEXTO += '|-----+------------+----------+-----+----+------------------------------------+' + cLIN
   ENDIF
   IF tDOC = 7 .AND. cSUBTIPO = "PCK" //xml
      cTEXTO += "<?xml version=" + Chr( 34 ) + "1.0" + Chr( 34 ) + " standalone=" + Chr( 34 ) + "yes" + Chr( 34 ) + "?>" + cLIN
      cTEXTO += "<DATAPACKET Version=" + Chr( 34 ) + "2.0" + Chr( 34 ) + ">" + cLIN
      cTEXTO += "<METADATA>" + cLIN
      cTEXTO += "   <FIELDS>" + cLIN
   ENDIF
   IF tDOC = 7 .AND. cSUBTIPO = "ISO"  //xml
      cTEXTO := '<?xml version="1.0" encoding="ISO-8859-1"?>' + cLIN
      cTEXTO += "<DataRoot>" + cLIN
      cTEXTO += "<Estrutura>" + cLIN
   ENDIF
   IF tDOC = 1 .AND. cSUBTIPO = "TRH"   //xls 
      cTEXTO += "<html>" + cLIN
      cTEXTO += "<body>" + cLIN
      cTEXTO += "<table border=" + Chr( 34 ) + "1" + Chr( 34 ) + ">" + cLIN
      cTEXTO += "<!-- cabecalho com os nomes dos campos da tabela -->" + cLIN
      cTEXTO += "<tr>" + cLIN
   ENDIF

   IF lDOCCAB
      FOR MEMVAR->x := 1 TO nFIELDS      // aqui menvar evitar confusao dbf que tem o campo X
         cCAMPO := aESTRU[ X, 1 ]
         DO CASE
         CASE tDOC = 3  .OR. tDOC = 2  //TAM=2  TEC=3
            cOBS := Space( 35 )
            IF tDOC = 2 .AND. aVAL[ X ] > 0   //TAM=2
               cOBS := PadR( StrZero( aVAL[ X ] ), 35 )
            ENDIF
            cTEXTO += '| ' + Str( X, 3 ) + ' | ' + ;
               PadR( cCAMPO, 10 ) + ' | ' + ;
               TIPOC( aESTRU[ X, 2 ] ) + ' | ' + ;
               Str( aESTRU[ X, 3 ], 3 ) + ' | ' + ;
               Str( aESTRU[ X, 4 ], 2 ) + ' | ' + ;
               cOBS + '|' + cLIN
         CASE tDOC = 4   // dbe
            cTEXTO += '   ' + PadR( cCAMPO, 10 ) + ' ' + ;
               aESTRU[ X, 2 ] + ' ' + ;
               Str( aESTRU[ X, 3 ], 3 ) + ' ' + ;
               Str( aESTRU[ X, 4 ], 2 ) + cLIN
         CASE tDOC = 5  .AND. cSUBTIPO <> "SQL"  //delimitado
            cCAMPO := AllTrim( cCAMPO )
            //cCAMPO := RANGEREPL( Chr( 0 ), Chr( 31 ), cCAMPO, " " ) // Remove caracteres de controle
            cCAMPO := FixSRTExtendido( cCAMPO , .T. , .T. , .T. , .T. , .T. )
            //FixSRTExtendido( cVALOR,lLOW,lUP,lACE,lUTF, lESP )
            
            IF lDOCDAD
               cTEXTO +=  AllTrim( cCAMPO ) + ZDELIMITE // clin no final
            ELSE
               cTEXTO += PadR( cCAMPO, 10 ) + ZDELIMITE + ;
                  aESTRU[ X, 2 ] + ZDELIMITE + ;
                  Str( aESTRU[ X, 3 ], 3 ) + ZDELIMITE + ;
                  Str( aESTRU[ X, 4 ], 2 ) + cLIN
            ENDIF
         CASE tDOC = 1 .AND. cSUBTIPO = "TRH"  //xls
            cTEXTO += "<th nowrap>" + AllTrim( cCAMPO ) + "</th>" + cLIN
         CASE tDOC = 6   //sdf
            IF lDOCDAD
               cTEXTO +=  AllTrim( cCAMPO ) + " " // So nome do campo
               cTEXTO:=PADR(cTEXTO,10)
            ELSE
               cTEXTO += PadR( cCAMPO, 10 ) + ' ' + ;
                  aESTRU[ X, 2 ] + ' ' + ;
                  Str( aESTRU[ X, 3 ], 3 ) + ' ' + ;
                  Str( aESTRU[ X, 4 ], 2 ) + cLIN
            ENDIF
         CASE tDOC = 7 .AND. cSUBTIPO = "PCK"  //xlm
            cTEXTO += "   <FIELD attrname=" + Chr( 34 ) + AllTrim( cCAMPO ) + Chr( 34 )
            cTEXTO += " fieldtype="
            cTEXTO += Chr( 34 ) + TIPOXML( aESTRU[ X, 2 ], aESTRU[ X, 3 ], aESTRU[ X, 4 ] ) + Chr( 34 )
            IF aESTRU[ X, 2 ] = "C"
               cTEXTO += " WIDTH=" + Chr( 34 ) + AllTrim( Str( aESTRU[ X, 3 ], 3 ) ) + Chr( 34 )
            ENDIF
            IF aESTRU[ X, 2 ] = "M"
               cTEXTO += " WIDTH=" + Chr( 34 ) + AllTrim( Str( 255 ) ) + Chr( 34 )
            ENDIF
            cTEXTO += "/>" + cLIN
         CASE tDOC = 7 .AND. cSUBTIPO = "ISO"  //xlm
            cTEXTO += "<Campo>" + CLIN
            cTEXTO += "<Nome>"    + AllTrim( cCAMPO ) +          "</Nome>" + CLIN
            cTEXTO += "<Tipo>"    + aESTRU[ X ][ 2 ] +             "</Tipo>" + CLIN
            cTEXTO += "<Tamanho>" + LTrim( Str( aESTRU[ X ][ 3 ] ) ) + "</Tamanho>" + CLIN
            cTEXTO += "<Decimal>" + LTrim( Str( aESTRU[ X ][ 4 ] ) ) + "</Decimal>" + CLIN
            cTEXTO += "</Campo>" + CLIN
         ENDCASE
      NEXT x
      
      // Grava os indices
      IF tDOC = 7 .AND. cSUBTIPO = "ISO"     //xlm
         
         aINDICES:=GeraINDICES()
        nIndexes := LEN(aINDICES)
        FOR j := 1 TO nIndexes
            cTEXTO += "<Indice>" + cLIN
            cTEXTO += "<Chave>" + aINDICES[J,6]  + "</Chave>" + CLIN
            cTEXTO += "</Indice>" + cLIN
        NEXT j
         
      ENDIF

      // cabecario sql  nao precisa loop nos fields
      IF (tDOC = 5 .AND. cSUBTIPO = "SQL" .AND. lDOCCAB ) //delimitado 
         aUSO := aESTRU
         IF Empty( aESTRU )
            aUSO := dbStruct()
         ENDIF
         // select case ZANOFOR="SQLITE" criar conforme o tipo sql difere datatypes
         //
         DO CASE
         CASE ZANOFOR = "SQLITE"
            cTEXTO := SqliteCreateTable( cARQ, aUSO, "SQLITE" )
         CASE  ZANOFOR = "MYSQL" .OR. ZANOFOR = "MYSQL64" .OR. ZANOFOR = "MARIADB"
            cTEXTO := SqliteCreateTable( cARQ, aUSO, "MYSQL" )
         CASE  ZANOFOR = "PGSQL" 
            cTEXTO := SqliteCreateTable( cARQ, aUSO, "PGSQL" )  
        CASE  ZANOFOR = "ORACLE" 
            cTEXTO := SqliteCreateTable( cARQ, aUSO, "ORACLE" )      
         CASE  ZANOFOR = "MDB" .OR. ZANOFOR = "ACCESS"
            cTEXTO := SqliteCreateTable( cARQ, aUSO, "MDB" )
         CASE  ZANOFOR = "MSSQL"
            cTEXTO := SqliteCreateTable( cARQ, aUSO, "MSSQL" )   
         OTHERWISE
            cTEXTO := "CREATE TABLE " + cARQ + hb_osNewLine()
            cTEXTO += " ("
            FOR K = 1 TO Len( aUSO )
               cTEXTO += AllTrim( aUSO[ K ][ DBS_NAME ] ) + " " 
               DO CASE
               CASE aUSO[ K ][ DBS_TYPE ] = "C"
                  IF aUSO[ K ][ DBS_LEN ] = 254
                     cTEXTO += "VARCHAR (512)"
                  ELSE
                     cTEXTO += "VARCHAR (" + AllTrim( Str( aUSO[ K ][ DBS_LEN ] ) ) + ")"
                  ENDIF
               CASE aUSO[ K ][ DBS_TYPE ] = "D"
                  cTEXTO += "SMALLDATETIME"
               CASE aUSO[ K ][ DBS_TYPE ] = "N"
                  cTEXTO += "DECIMAL (" + AllTrim( Str( aUSO[ K ][ DBS_LEN ] ) ) + "," + AllTrim( Str( aUSO[ K ][ DBS_DEC ] ) ) + ")"
               ENDCASE
               IF K <> Len( aUSO )
                  cTEXTO += " ," + hb_osNewLine()
               ENDIF
            NEXT K
            cTEXTO += ") ; "  + cLIN
         ENDCASE

        cTEXTO    +=  hb_osNewLine()
        aINDICES:=GeraINDICES()
        nIndexes := LEN(aINDICES)
        FOR j := 1 TO nIndexes
            cTEXTO += aINDICES[J,1]  + hb_osNewLine() //Create index
        NEXT j
        
         
      ENDIF
   ENDIF


   IF tDOC = 1 .AND. cSUBTIPO = "TRH"   //xls
      cTEXTO += "</tr>" + cLIN
   ENDIF
   IF tDOC = 7 .AND. cSUBTIPO = "PCK"   //xml
      cTEXTO += "  </FIELDS>" + cLIN
      cTEXTO += "</METADATA>" + cLIN
      cTEXTO += "<ROWDATA>" + cLIN
   ENDIF
   IF tDOC = 7 .AND. cSUBTIPO = "ISO"    //xml
      cTEXTO += "</Estrutura>" + cLIN
      cTEXTO += "<Dados>" + cLIN
   ENDIF

   IF tDOC = 5 .AND. lDOCCAB    //delimitado
      cTEXTO += cLIN
   ENDIF
   IF tDOC = 6 .AND. lDOCCAB   //SDF
      cTEXTO += cLIN
   ENDIF

    nHANDLEDOC := FCreate( cARQGRV )
    IF Len( cTEXTO ) > 0 
       FWrite( nHANDLEDOC, cTEXTO )
    eNDIF

   IF tDOC = 8     //json
      hRecords := { => }
   ENDIF

   cTEXTO := ""

   IF tDOC = 3  .OR. tDOC = 2   //TAM=3  TEC=2
      cTEXTO += '+-----+------------+----------+-----+----+------------------------------------+' + cLIN
   ENDIF
   
   
   
   IF tDOC = 4    // dbe
      cTEXTO += 'ENDDEF' + cLIN
      
      
     // AADD(aDUPLA,{msql,msqlmeta,cTablename,cINDEXNAME,cKey,cSqlExpr,cFilter,lIsUnique})       
     //                1     2          3          4      5      6        7       8   
      cTIPOSQL:="DBF"
      aINDICES:=GeraINDICES()
      nIndexes := LEN(aINDICES)
      IF nIndexes > 0
         cTEXTO += 'DEFINDEX ' + Upper( cARQ ) + cLIN
         FOR j = 1 TO  nIndexes
            cTEXTO += " "
            cTEXTO += aINDICES[J,4]
            cTEXTO += " "
            cTEXTO += aINDICES[J,5]
            cTEXTO += " "
            cTEXTO += aINDICES[J,6]
            cTEXTO += clin
         NEXT j
         cTEXTO += 'ENDINDEX' + cLIN
      ENDIF
      cTEXTO += 'ENDFILE' + cLIN
      cTEXTO +=  cLIN
      
     cTEXTO += clin + "[MATRIX ESTRUTURA]"+ cLIN
     cTEXTO += StrTran( hb_ValToExp(aESTRU), "},", "},"+HB_EOL() )+ cLIN
     cTEXTO +=  cLIN
     
     IF AT(".DBF",UPPER(cCAMINHOCOMPLETO))>0
         cTEXTO += clin + "[HEADERINFO]"
         aHeaderInfo:=GetHeaderInfo( cCAMINHOCOMPLETO ) 
         IF lEN(aHeaderInfo)>0
            cTEXTO += clin + PADR(hb_ValToStr(aHeaderInfo[1,2]),25)+": "+hb_ValToStr(aHeaderInfo[1,1])
            cTEXTO += clin + PADR(hb_ValToStr(aHeaderInfo[2,2]),25)+": "+hb_ValToStr(aHeaderInfo[2,1])
            cTEXTO += clin + PADR(hb_ValToStr(aHeaderInfo[3,2]),25)+": "+hb_ValToStr(aHeaderInfo[3,1])
            cTEXTO += clin + PADR(hb_ValToStr(aHeaderInfo[4,2]),25)+": "+hb_ValToStr(aHeaderInfo[4,1])
            cTEXTO += clin + PADR(hb_ValToStr(aHeaderInfo[5,2]),25)+": "+hb_ValToStr(aHeaderInfo[5,1])
            cTEXTO += clin + PADR(hb_ValToStr(aHeaderInfo[6,2]),25)+": "+hb_ValToStr(aHeaderInfo[6,1])
         ENDIF  
         aHeaderInfo:=INFOTIPODBF(cCAMINHOCOMPLETO ) 
         IF lEN(aHeaderInfo)>0
            cTEXTO += clin + PADR("Header: ",25)+hb_ValToStr(aHeaderInfo[1])
            cTEXTO += clin + PADR("Driver: ",25)+hb_ValToStr(aHeaderInfo[2])
            IF ! EMPTY(aHeaderInfo[3])
               cTEXTO += clin + PADR("Memo: ",25)+hb_ValToStr(aHeaderInfo[3])
            ENDIF   
            cTEXTO += clin + PADR("Tipo:   ",25)+hb_ValToStr(aHeaderInfo[4])
         ENDIF 
        cTEXTO += clin 
      ENDIF 
      
      cTEXTO +=  cLIN
      cTEXTO += "[" + Upper( AllTrim( carq ) ) + "."+TABLEEXT+"]" + clin
      cTEXTO += "CAMINHO=" + hb_cwd() + clin
      cTEXTO += "DRIVER=" + rddName() + clin
      cTEXTO += "NUMMAINTAINED=" + Str( nIndexes, 1 ) + cLIN
      cTEXTO += "MAINTAIN0=" + cARQ + XEXT() + cLIN
      cINDEXTEXTO := ""
      
      aINDICES:=GeraINDICES()
      nIndexes := LEN(aINDICES)

      //AADD(aDUPLA,{msql,msqlmeta,cTablename,cINDEXNAME,cKey,cSqlExpr,cFilter,lIsUnique})       
     //             1     2          3          4      5      6        7       8   
      
      IF nIndexes > 0
         FOR j = 1 TO  nIndexes
            cTEXTO += "TAG"   + Str( j - 1, 1 ) + "=" +  aINDICES[J,4] + clin
            cTEXTO += "INDEX" + Str( j - 1, 1 ) + "=" +  aINDICES[J,5] + clin
            cTEXTO += "INDEXFIELDS" + Str( j - 1, 1 ) + "=" +  aINDICES[J,6] + clin
            cINDEXTEXTO +=  aINDICES[J,1] + clin
         NEXT j
      ENDIF
      
      //SqliteCreateTable( cTablename, aStruct, cTIPOSQL, lINDEX ,lPK,lINCSR)
      //lINDEX e .t. pois cada banco necessita nome do indice especificos 
      cTIPOSQL:="SQLITE"
      cTEXTO += clin + "[SQLITE]"
      cTEXTO += clin + FormataBlocoSql(SqliteCreateTable( cARQ, aESTRU, "SQLITE",.T. ))
      /* incluso no SqliteCreateTable
      CTEXTO += clin + "PRAGMA temp_store = MEMORY ; " //
      CTEXTO += clin + "PRAGMA cache_size = 2000 ; " //Aumenta o tamanho do cache (ex: 2000 páginas)
      CTEXTO += clin + "PRAGMA journal_mode = WAL ; " //Modo WAL (Write-Ahead Logging) - Muito mais rápido para inserções e permite leitura e escrita simultâneas
      CTEXTO += clin + "PRAGMA synchronous = NORMAL ; "  //Reduz a sincronização com o disco (Normal é seguro o suficiente com WAL)
      CTEXTO += clin + "PRAGMA auto_vacuum = INCREMENTAL ; "  //Armazena arquivos temporários na memória em vez de disco
      CTEXTO += clin + "PRAGMA page_size = 4096 ; " //
      CTEXTO += clin + "PRAGMA mmap_size = 300000000 ; "
      CTEXTO += clin + "PRAGMA busy_timeout = 5000 ; "
      */
      CTEXTO += clin
      cTIPOSQL:="MSSQL"
      cTEXTO += clin + "[MSSQL]"
      cTEXTO += clin + FormataBlocoSql(SqliteCreateTable( cARQ, aESTRU, "MSSQL",.T. ))
      cTIPOSQL:="MYSQL"
      cTEXTO += clin + "[MYSQL]"
      cTEXTO += clin + FormataBlocoSql(SqliteCreateTable( cARQ, aESTRU, "MYSQL",.T. ))
      cTIPOSQL:="POSTGRESQL"
      cTEXTO += clin + "[POSTGRESQL]"
      cTEXTO += clin + FormataBlocoSql(SqliteCreateTable( cARQ, aESTRU, "POSTGRESQL",.T. ))
      cTIPOSQL:="ACCESS"
      cTEXTO += clin + "[ACCESS]"
      cTEXTO += clin + FormataBlocoSql(SqliteCreateTable( cARQ, aESTRU, "ACCESS",.T. ))
      cTIPOSQL:="ORACLE"
      cTEXTO += clin + "[ORACLE]"
      cTEXTO += clin + FormataBlocoSql(SqliteCreateTable( cARQ, aESTRU, "ORACLE",.T. ))
      cTIPOSQL:="FIREBIRD"
      cTEXTO += clin + "[FIREBIRD]"
      cTEXTO += clin + FormataBlocoSql(SqliteCreateTable( cARQ, aESTRU, "FIREBIRD",.T. ))
      cTIPOSQL:=""

       aINDICESDBML:={}
       FOR nI := 1 TO dbOrderInfo( DBOI_ORDERCOUNT )
            cTag  := dbOrderInfo( DBOI_NAME, , nI )
            cExpr := dbOrderInfo( DBOI_EXPRESSION, , nI )
            AAdd( aINDICESDBML, { nI, cTag, cExpr } )
       NEXT
      //Gera dbml       
      cTEXTO+="[DBML]"+HB_OSNEWLINE()
      CTEXTO += GERADBML_Custom( cARQ, aESTRU, aINDICESDBML, cARQ, zusovia )
      
      
      //CTEXTO += GERADBML(cARQ,aESTRU)

   ENDIF

// verificas se a quantidade de registros
   nLASTREC := 0
   IF lDOCDAD
      nLASTREC := LastRec()
   ENDIF
// nao faz o loop se nao incluir dados ou nao tiver registro
// alguns rdd sem registro nao trazem o eof() corretamente gerando loop infinito
   IF lDOCDAD .AND. nLASTREC > 0
      nLASTREC := LastRec()
      zei_fort( nLASTREC,,, 0 )
      nXLS := 0
      cTEXTO:=""
      if zEXPOREXT = "SQL" .AND. ZANOFOR = "ORACLE"
         cTEXTO +="SET AUTOCOMMIT ON ;" + HB_OSNEWLINE()
      endif
      if zEXPOREXT = "SQL" .AND. (ZANOFOR = "MYSQL" .OR. ZANOFOR = "MYSQL64" .OR. ZANOFOR = "MARIADB")
         cTEXTO +="SET autocommit=1;" + HB_OSNEWLINE()
      endif
      dbGoTop()
      WHILE ! Eof()
         IF tDOC = 5 .AND. lDOCRECNO    //delimitado
            cTEXTO += AllTrim( Str( RecNo() ) ) + ZDELIMITE
         ENDIF
         IF tDOC = 6 .AND. lDOCRECNO    //sdf
            cTEXTO += Strzero( RecNo(),8,0 )  
         ENDIF
         nXLS++
         DO CASE
         CASE tDOC = 7 .AND. cSUBTIPO = "PCK"     //xml
            cTEXTO += "<ROW RowState=" + Chr( 34 ) + "12" + Chr( 34 )
         CASE tDOC = 1 .AND. cSUBTIPO = "TRH"  //xls
            cTEXTO += "<tr>"         + cLIN
         CASE tDOC = 1 .AND. cSUBTIPO = "ISO"   //xls
            cTEXTO += "<Registro>" + cLin
         CASE zEXPOREXT = "SQL"
            cTEXTO += "insert into " + Alias() + " values ("
         ENDCASE

         IF tDOC = 8    //json
            hRecord := { => }
            cTEXTO := ""    // zerando estava gerando acumlando os campos anteriores
         ENDIF

         FOR X = 1 TO nFIELDS
            cCAMPO := aESTRU[ X, 1 ]
            IF tDOC = 7 .AND. cSUBTIPO = "PCK"    //xml
               cTEXTO += " " + AllTrim( cCAMPO ) + "=" + Chr( 34 )
            ENDIF
            IF tDOC = 1 .AND. cSUBTIPO = "TRH"     //xls
               cTEXTO += "<td align=" + Chr( 34 ) + "right" + Chr( 34 ) + ">"
            ENDIF
            IF tDOC = 7 .AND. cSUBTIPO = "ISO"     //xml
               cTEXTO += "<" + cCAMPO + ">"
            ENDIF

            @ 3, 40 SAY AllTrim( PadR( cCAMPO ) )
            nVAL := hb_FieldGet( X )

            cFieldName   := aESTRU[ X ][ 1 ]
            cFieldType   := aESTRU[ X ][ 2 ]
            nFieldLength := aESTRU[ X ][ 3 ]
            nFieldDec    := aESTRU[ X ][ 4 ]

            // HB_FT_CURDOUBLE       14      "Z"
            // HB_FT_CURRENCY       13      "Y"
            // moeda e moeda dupla
            IF cFieldType = "Z" .OR. cFieldType = "Y"
               cFieldType = "N"
               IF Empty( nFieldLength )
                  nFieldLength = 12
               ENDIF
               IF Empty( nFieldLength )
                  nFieldLength = 2
               ENDIF
            ENDIF

            // HB_FT_DOUBLE        7      "B"
            IF cFieldType = "B"
               cFieldType = "N"
               IF Empty( nFieldLength )
                  nFieldLength = 14
               ENDIF
               IF Empty( nFieldLength )
                  nFieldLength = 5
               ENDIF
            ENDIF

            // Integer
            IF cFieldType = "I"
               cFieldType = "N"
               IF Empty( nFieldLength )
                  nFieldLength = 8
               ENDIF
               //IF ! Empty( nFieldLength )
               //   nFieldLength = 0 
               //ENDIF
            ENDIF


            DO CASE
               //
               // String ou memo
               //
            CASE cFieldType = "C" .OR. cFieldType = "M"
               //nVAL := AllTrim( STRVAL( nVAL ) ) //Estendido trata nval
               //nVAL := RANGEREPL( Chr( 0 ), Chr( 31 ), nVAL, " " ) // Remove caracteres de controle
                nVAL := FixSRTExtendido( nVAL , .T. , .T. , .T. , .T. , .T. )
            //FixSRTExtendido( cVALOR,lLOW,lUP,lACE,lUTF, lESP )
               DO CASE
               CASE zCNVCHAR = "O"
                  nVAL := win_ANSIToOEM( nVAL ) // HB_ansitooem(nVAL)
               CASE zCNVCHAR = "A"
                  nVAL := win_oemtoansi( nVAL ) // hb_oemtoansi(nVAL)
               ENDCASE
               
               //inclui nova barra pois e considerada escape no insert into
               nVAL := StrTran(nVAL, "\", "\\" ) 

               // datetime em forma de string
               IF  SubStr( nVAL, 5, 1 ) = "-" .AND. SubStr( nVAL, 8, 1 ) = "-"
                  nVAL = SubStr( nVAL, 6, 2 ) + "/" + SubStr( nVAL, 9, 2 ) + "/" + SubStr( nVAL, 1, 4 )
                  nvAL = CToD( nVAL )
                  nVAL = DATA2STR( nVAL, ZANOFOR, ZANOSEP, ZANOTAM )
               ENDIF

               DO CASE
                   CASE tDOC=6 .AND. cFieldType = "C" .AND. nFieldLength>0
                        cTEXTO += PadR(nVAL,nFieldLength , " " ) 
                  CASE tDOC=6 .AND. cFieldType = "M" 
                        cTEXTO += PadR(nVAL,255 , " " )       
                   CASE tDOC = 7 // xml
                      cTEXTO += str2html( nVAL )
                   CASE zEXPOREXT = "SQL"
                      cTEXTO += "'" + nVAL + "'" // sql string recenbem aspas simples
                   CASE zEXPOREXT = "DLM" .AND. ( zREGSEP = Chr( 34 ) .OR. zREGSEP = Chr( 39 ) )    // dlm que char recebem aspas ou dupla aspas
                      cTEXTO += zREGSEP + nVAL + ZREGSEP
                   OTHERWISE
                      cTEXTO += nVAL
               ENDCASE
               //
               // Data
               //
            CASE cFieldType = "D"
               IF Empty( nVAL )
                  cTEXTO += Dialeto_DataVazia(ZANOFOR)  //""
               ELSE
                  cTEXTO += DATA2STR( nVAL, ZANOFOR, ZANOSEP, ZANOTAM )
               ENDIF

            CASE cFieldType = "@"
               IF Empty( nVAL )
                  cTEXTO += ""
               ELSE
                  cTEXTO += hb_TSToStr( nVAL )   // HB_TSTOSTR( <tTimeStamp> ) -> <cTimeStamp> // YYYY-MM-DD HH:MM:SS.fff
               ENDIF

            CASE cFieldType = "T"
               IF Empty( nVAL )
                  cTEXTO += ""
               ELSE
                  cTEXTO += hb_TSToStr( nVAL )
               ENDIF


               //
               // Logico
               //
            CASE cFieldType = "L"
               cTEXTO += logic2str( nval, 0, 0, zSEPLOGIC )
               //
               // Numerico
               //
            CASE cFieldType = "N"
                IF tDOC=6
                   cTEXTO += STRTRAN(STRVAL( nVAL, nFieldLength, nFieldDec, ZDECSIM ) ," ",0)
                ELSE
                   cTEXTO += AllTrim( STRVAL( nVAL, nFieldLength, nFieldDec, ZDECSIM ) )
                ENDIF
            ENDCASE
            
            DO CASE
            CASE tDOC = 7 .AND. cSUBTIPO = "PCK"     //xml
                 cTEXTO += Chr( 34 )
            CASE tDOC = 1 .AND. cSUBTIPO = "TRH"          //xls
                 cTEXTO += "</td>" + Chr( 13 ) + Chr( 10 )
            CASE tDOC = 5 .AND. cSUBTIPO = "TAB"     //delimitado tab  
               IF X <> nFIELDS
                  cTEXTO += ZDELIMITE
               ENDIF
            CASE tDOC = 7 .AND. cSUBTIPO = "ISO"       //xml
               cTEXTO += "</" + cCAMPO + ">" + cLIN
            CASE Tdoc = 8    //json
               hb_HSet( hRecord, FieldName( x ), Ctexto )// FieldGet(nField)) // for each record, hrecord holds a hash of column name: column value
               cTEXTO := ""
            OTHERWISE
               IF X <> nFIELDS  // O Ultimo campo nao recebe delimitador
                  Ctexto += Zdelimite
               ENDIF
            ENDCASE
         NEXT X
         DO CASE
         CASE tDOC = 7 .AND. cSUBTIPO = "PCK"     //xml
            cTEXTO += "/>" + cLIN
         CASE tDOC = 6                            //SDF
             cTEXTO += cLIN
         CASE tDOC = 1 .AND. cSUBTIPO = "TRH"     //xls
            cTEXTO += "</tr>" + cLIN
         CASE tDOC = 7 .AND. cSUBTIPO = "ISO"     //xml
            cTEXTO += "</Registro>" + cLIN
         CASE zEXPOREXT = "SQL"                   //delimitado
            cTEXTO += ") ; " + cLIN
         CASE Tdoc = 8                             //json
            // Abaixo
         OTHERWISE
            cTEXTO += cLIN
         ENDCASE
         DO CASE
         CASE tdoc = 8     //json
            hb_HSet( hRecords, LTrim( Str( nxls ) ), hRecord ) // like so, a hash of recno: hash of columns/values of this record  RecNo() usa nxls para ficar sequencial
         OTHERWISE
            FWrite( nHANDLEDOC, cTEXTO )
         ENDCASE
         cTEXTO := ""
         ZEI_FORT( nLASTREC,,, 1 )
         dbSkip()
      ENDDO
   ENDIF
   IF tDOC = 7 .AND. cSUBTIPO = "PCK"     //xml
      cTEXTO += "</ROWDATA>" + cLIN
      cTEXTO += "</DATAPACKET>" + cLIN
   ENDIF
   IF tDOC = 7 .AND. cSUBTIPO = "ISO"      //xml
      cTEXTO += "</Dados>" + cLIN
      cTEXTO += "</DataRoot>" + cLIN
   ENDIF
   IF tDOC = 1 .AND. cSUBTIPO = "TRH"      //xls
      cTEXTO += "</table>" + cLIN
      cTEXTO += "</body>" + cLIN
      cTEXTO += "</html>" + cLIN
   ENDIF
   IF Len( cTEXTO ) > 0
      FWrite( nHANDLEDOC, cTEXTO )
   ENDIF
   IF tDOC = 8   //json
      FSeek( nHandledoc, 0, 2 )
      FWrite( nHandledoc, hb_jsonEncode( hRecords, .T. ) )
   ENDIF
   FClose( nHANDLEDOC )

   RETURN .T.

// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +
// +    Function TIPOC()
// +
// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +
FUNCTION TIPOC( cTIPO )

   LOCAL cRETU := ""

   DO CASE
   CASE cTIPO = 'C'
      cRETU := 'Caracter'
   CASE cTIPO = 'N'
      cRETU := 'Numerico'
   CASE cTIPO = 'L'
      cRETU := 'Logico  '
   CASE cTIPO = 'D'
      cRETU := 'Data    '
   CASE cTIPO = 'M'
      cRETU := 'Memo    '

   CASE cTIPO = 'F'
      cRETU := 'Float   '
   CASE cTIPO = 'I'
      cRETU := 'Integer '
   CASE cTIPO = 'B'
      cRETU := 'Double  '
   CASE cTIPO = 'T'
      cRETU := 'Time    '
   CASE cTIPO = '@'
      cRETU := 'Timestamp'
   CASE cTIPO = '='
      cRETU := 'ModeTime'
   CASE cTIPO = '^'
      cRETU := 'Rowver  '
   CASE cTIPO = '+'
      cRETU := 'Autoinc '
   CASE cTIPO = 'Y'
      cRETU := 'Moeda   '
   CASE cTIPO = 'Z'
      cRETU := 'MoedaDup'
   CASE cTIPO = 'Q'
      cRETU := 'Variavel'
   CASE cTIPO = 'V'
      cRETU := 'Any     '
   CASE cTIPO = 'P'
      cRETU := 'Imagen  '
   CASE cTIPO = 'W'
      cRETU := 'Blob    '
   CASE cTIPO = 'G'
      cRETU := 'Ole     '
   ENDCASE

   RETURN cRETU




// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +
// +    Function DBUZAP()
// +
// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +
FUNCTION dbuzap()

   ZAP

   RETURN .T.

// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +
// +    Function DBUPACK()
// +
// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +
FUNCTION dbupack()

   PACK

   RETURN .T.

// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +
// +    Function DBETODBF(cMASK,lLAY,lCRIA)
// +
// +||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// +
FUNCTION DBETODBF( cMASK, lLAY, lCRIA )

   IF ValType( cMASK ) # "C"
      cMASK := "*."+TABLEEXT
   ENDIF
   IF ValType( lLAY ) # "L"
      lLAY := .T.
   ENDIF
   IF ValType( lCRIA ) # "L"
      lCRIA := .F.
   ENDIF
   MATDBF = FILENAMES( cMASK )
   nARQ = Len( MATDBF )
   IF nARQ > 0
      FOR X = 1 TO nARQ
         cARQDIC = TIRAEXT( MATDBF[ X ], 'DBE' )
         IF File( cARQDIC )
            @ 24, 00 SAY "Atualizando arquivo " + MATDBF[ X ]
            CLSCOR()
            MAKEDBF( cARQDIC,, lCRIA, RDDNOME( TIPODBF ) )
         ENDIF
      NEXT X
   ENDIF
   IF lLAY
      LAYOUT()
   ENDIF

   RETURN .T.



// + EOF: DBUDOC.PRG
