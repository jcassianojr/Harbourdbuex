// +--------------------------------------------------------------------
// +
// +   hmg\SOURCE\HbMySQL\  https://www.hmgextended.com/ https://github.com/ivanilmarcelino/OpenMinigui
// +   git\core\contrib\hbmysql\
// +
// +
// +--------------------------------------------------------------------
// +

// +--------------------------------------------------------------------
// +
// +
// +
// +    Programa  : dbumy.prg
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

#require "hbmysql"

#include "dbstruct.ch"
#include "box.ch"
#include "DBINFO.CH"
#include "hbVER.CH"



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function mysqlmenu()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION mysqlmenu()

   PRIV oServer, oQuery, oRow

   aAMBIENTE := SALVAA()

   cTIPOSQL := "MYSQL"


   loledb     := hb_Version( HB_VERSION_BITWIDTH ) <> 64
   lMDB       := .F.
   lACCDB     := .F.
   lFDB       := .F.
   cSERVERX   := "localhost" + Space( 21 )
   cUSERX     := PadR( "root", 30, " " )
   cDATABASEX := Space( 30 )
   cPASSX     := Space( 30 )
   cTABELAX   := Space( 30 )
   OPENTIPOARQ()

   oServer := TMySQLServer():New( cSERVERX, cUSERX, cPASSX )   //
   IF oServer:NetErr()
      Alert( oServer:Error() )
      RETURN .F.
   ENDIF

   MYSELECTDB()


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
         mysqlnewdatabase()
      CASE KEY = 2
         MYSELECTDB()
      CASE KEY = 3
         dbf2mysql()
      CASE KEY = 4
         MYSELECTTABLE()
      CASE KEY = 5
         mystrutodbf()
      CASE KEY = 6
         MYDELTABLE()
      CASE KEY = 7
         myexpformat()
      CASE KEY = 8
        myExecArqSql()   
      OTHERWISE
         RETURN
      ENDCASE
   ENDDO



   oserver:destroy()
   RESTAA( aAMBIENTE )
   layout()

   RETURN .T.



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function MYDELTABLE()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION MYDELTABLE()

   MYSELECTTABLE()
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
// +    Function MYSELECTDB()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION MYSELECTDB()

   LOCAL nCHOICES

   nCHOICES := 0
   aResult  := Oserver:ListDBs()
   IF Len( aResult ) > 0
      hb_DispBox( 3, 22, 22, 55, B_DOUBLE + " " )
      nChoices := AChoice( 4, 23, 21, 54, aResult )
   ENDIF
   cDATABASEX := iif( nChoices > 0, aResult[ nChoices ], "" )
   Oserver:SelectDB( cDATABASEX )
   IF oServer:NetErr()
      Alert( oServer:Error() )
      RETURN .F.
   ENDIF

   RETURN .T.



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function MYSELECTTABLE()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION MYSELECTTABLE()

   LOCAL nCHOICES

   nCHOICES := 0
   aResult  := oServer:ListTables()
   IF Len( aResult ) > 0
      hb_DispBox( 3, 22, 22, 55, B_DOUBLE + " " )
      nChoices := AChoice( 4, 23, 21, 54, aResult )
   ENDIF
   cTABELAX := iif( nChoices > 0, aResult[ nChoices ], "" )

   RETURN .T.


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function mysqlnewdatabase()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION mysqlnewdatabase()

   cnewDATABASEX := INPUTBOX( Space( 30 ), "Novo database" )
   cnewDATABASEX := AllTrim( cnewDATABASEX )
   IF ! Empty( cnewDATABASEX )
      IF hb_AScan( Oserver:ListDBs(), cnewDATABASEX,,, .T. ) > 0
         MDT( "Ja existe Database " + cnewDATABASEX )
         RETURN .F.
      ELSE
         oSERVER:CREATEDATABASE( cNEWDATABASEx )
         IF oServer:NetErr()
            Alert( oServer:Error() )
            RETURN .F.
         ENDIF
         Oserver:SelectDB( cNEWDATABASEx )
         IF oServer:NetErr()
            Alert( oServer:Error() )
            RETURN .F.
         ENDIF
         cDATABASEX := cNEWDATABASEx
      ENDIF
   ENDIF

   RETURN .T.
   
   


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function mystrudbf()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION mystrudbf()

   LOCAL aRETU

   aRETU  := {}
   oQuery := oServer:Query( "SHOW COLUMNS FROM " + cTABELAx )
   WHILE ! oQuery:Eof()
      cFieldName   := ''
      cFieldType   := ''
      nFieldLength := 0
      nFieldDec    := 0
      oRow         := oQuery:GetRow()

      // tmsql comeca com 1 padrao harbour
      cFieldName := Upper( AllTrim( oRow:FieldGet( 1 ) ) )
      cFieldType := Upper( AllTrim( oRow:FieldGet( 2 ) ) )
      AAdd( aRETU, geracampodbf( cFieldName, cFieldType, nFieldLength, nFieldDec ) )

      oQuery:skip()
   ENDDO
   oQUERY:DESTROY()

   RETURN aRETU


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function mystrutodbf()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION mystrutodbf()

   LOCAL aRETU
   LOCAL i
   LOCAL nFIM
   LOCAL eVALOR

   aRETU := {}
   MYSELECTTABLE()
   aRETU := mystrudbf()
   IF Len( aRETU ) = 0
      mdt( "estrutura em branco" )
      RETURN .F.
   ENDIF

   dbCreate( ctabelaX + "_mysql", aRETU, "DBFCDX" )
   dbUseArea( .T., "DBFCDX", ctabelaX + "_mysql",, .F., .F. )
// cARQIMPUNL:=ctabela+"_"+Ctiposql+"_pipe.unl"
// APPEND FROM &cARQIMPUNL. DELIMITED  WITH PIPE


   oQuery2  := oServer:Query( "SELECT * FROM " + cTABELAx )
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
   oQuery2:Destroy()
   dbCloseAll()

   RETURN .T.

FUNCTION dbf2mysql()
  nOLDTIPO := TIPODBF
            alertX( "escolha origem" )
            tipodbfesc()
            nORITIPO   := TIPODBF
            cORIDRIVER := RDDNOME( TIPODBF )
            lincdados:=mdg("Incluir Dados")
            IF MDG("Arquivo individual")
               cARQORI    := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*."+TABLEEXT, 1 )
                IF File( cARQORI )
                   mysql_DBF(cARQORI,lincdados)
                ENDIF
            ELSE
               cPASTA:=SelectFolder()
               cPASTA+="\*."+TABLEEXT 
               //FAZERDBF(bUSO                                       , lSHARE[.F.] , bPRE, bPOS, cMASK ,LOPEN )
               FAZERDBF( {|| mysql_DBF(cCAMINHOCOMPLETO,lincdados) }, .F. ,     ,     ,cPASTA,.F.)
            ENDIF   
            RDDNOME( nOLDTIPO )   // retorna tipo anterior
RETURN

// +--------------------------------------------------------------------
// +
// +
// +
// +    Function dbf2mysql()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION mysql_DBF(cARQORI,lincdados)

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
               MDT( oServer:Error() )
               RETURN .F.
            ENDIF
         ELSE
            RETURN .F.
         ENDIF
      ENDIF
      oServer:CreateTable( cTable, aDbfStruct )
      IF oServer:NetErr()
         MDT( oServer:Error() )
         dbCloseAll()
         RETURN .F.
      ENDIF

     //               1     2          3          4      5      6        7       8  
     //AADD(aDUPLA,{msql,msqlmeta,cTablename,cINDEXNAME,cKey,cSqlExpr,cFilter,lIsUnique}) 
     
     aINDICES:=GeraINDICES()
     nIndexes := LEN(aINDICES)
     FOR j := 1 TO nIndexes
        cINDEXNAME  :=aINDICES[j,4]
        cCHAVES     :=aINDICES[j,6]
        aFNAMES    := hb_ATokens( cCHAVES, "," )
        oSERVER:CreateIndex( cINDEXNAME, cTable, aFNames, .F. )
     NEXT j


      // Initialize MySQL table
      oTable := oServer:Query( "SELECT * FROM " + cTable + " LIMIT 1" )
      IF oTable:NetErr()
         Alert( oTable:Error() )
         RETURN .F.
      ENDIF


      IF lincdados
          DO WHILE !dbffile->( Eof() )

             oRecord := oTable:GetBlankRow()

             FOR i := 1 TO dbffile->( FCount() )
                oRecord:FieldPut( i, dbffile->( FieldGet( i ) ) )
             NEXT

             oTable:Append( oRecord )
             IF oTable:NetErr()
                mdt( oTable:Error() )
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

 *+--------------------------------------------------------------------
*+
*+    Function myExecArqSql()
*+
*+--------------------------------------------------------------------
*+
function myExecArqSql()

LOCAL cCOMANDO := ""
LOCAL cARQIMP  := ""

cARQIMP := win_GetOPENFileName(,"Arquivos SQL",HB_CWD(),"Arquivos SQL","*.SQL",1)
//cARQORI := OPENTIPOARQ()

IF FILE(cARQIMP)
   //nao pode ser linha a linha pois um comando pode estar em mais de uma linha
   cCOMANDO:=MEMOREAD(cARQIMP)
   oServer:Query(cCOMANDO)
endif
return .t.



// + EOF: dbumy.prg
// +
