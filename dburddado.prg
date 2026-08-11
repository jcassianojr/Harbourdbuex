// +--------------------------------------------------------------------
// +
// +   git\core\extras\rddado\
// +
// +
// +--------------------------------------------------------------------
// +


*+--------------------------------------------------------------------
*+
*+    Programa  : mdb2dbf.prgF
*+
*+     Sistema:
*+
*+     Linguagem: HarbourF
*+
*+     Autor: jcassiano
*+
*+     Copyright (c) 2024,  jcassiano
*+
*+    Documentado em 28-Dez-2024 as 10:07 am
*+
*+--------------------------------------------------------------------
*+

#include "dbstruct.ch"
#INCLUDE "BOX.CH"
#INCLUDE "TRY.CH"
#INCLUDE "DBINFO.CH"
#INCLUDE "hbVER.CH"
#require "rddado"
#include "adordd.ch"

REQUEST ADORDD



*+--------------------------------------------------------------------
*+
*+    Function mdbmenu()
*+
*+--------------------------------------------------------------------
*+
Function mdbmenu(cUSOSQL)

cTIPOSQL := cUSOSQL   //Passa para privada usadas nas funcoes aBaixo
public oDB := nil

aAMBIENTE := SALVAA()

cSERVERX   := "localhost"+space(21)
cDATABASEX := space(30)
cUSERX     := SPACE(30)
cPASSX     := SPACE(30)
cTABELAX   := SPACE(30)
cBANCOX   := Space(30)
cOWNERX   := Space(30)
cPORTAX    :=SPACE(30)
loledb     := .T.
lmdb       := .f.
laccdb     := .f.
lFDB       := .f.

//usado pelo firebirdcreate
nPageSize := 8192 //1024
cCharSet := "ISO8859_1" //"ASCII"
nDialect := 3 //deixe com 1 caso de erro criacao com 3
CTIPOMIX :="ODBC"
cTIPODBC :="ODBC"


pegcfgbanco()

WHILE .T.
   HB_dispbox(3,18,18,55,B_DOUBLE+" ")
   DO CASE
   CASE cTIPOSQL = "MDB" .OR. cTIPOSQL = "ACCESS"
      IF loledb
         @ 03,40 SAY "oledb(32b)"         
      Else
         @ 03,40 SAY "accdb(64b)"         
      endif
   CASE cTIPOSQL = "MYSQL"
      IF loledb
         @ 03,40 SAY "odbc 8(32b)"         
      Else
         @ 03,40 SAY "odbc 9(64b)"         
      endif

   OTHERWISE
      @ 03,24 SAY "ADORDD"+" "+cTIPOSQL         
   ENDCASE
   if cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" .OR. cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" ;
              .OR. cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER"
      OPCAO(4,24,"&Criar database             ",67)   //c 67
   else
      OPCAO(4,24,"&Criar arquivo              ",67)   //c 67
   endif
   OPCAO(  5, 24, "Executar arquivo &SQL     ", 83)   //S 83 
   OPCAO(  6, 24, "&Importar  DBF            ", 73)   //I 73 
   OPCAO(  7, 24, "Exportar Tabela &Formatos ", 69)   //F 70 
   OPCAO(  8, 24, "&Database Selecionar      ", 68)   //D 68 
   OPCAO(  9, 24, "&Exportar  DBF            ", 69)   //E 69 
   OPCAO( 10, 24, "DBF para &Script          ", 83)   //S 83 
   OPCAO( 11, 24, "DBF para D&BML            ", 84)   //B 66
   OPCAO( 12, 24, "&ODBC   Info DSN          ", 79 )   // O
   OPCAO( 13, 24, "Gerar md e dbml           ", 79 )   // O 
   
   KEY := menu(1,0)
   DO CASE
   CASE KEY = 1
      mdbcria()
   CASE KEY = 2
      ExecArqSql()
   CASE KEY = 3
      MDBIMPDBF()
   CASE KEY = 4
      MDBEXP(2)
   CASE KEY = 5
      IF lMDB .OR. lACCDB
      ELSE
         mdbdatabases()
      ENDIF
   CASE KEY = 6
      MDBEXP(1)
   CASE KEY = 7 
        IF MDG("Individual") 
          tDOC = 5 //SQL
          ZANOFOR := cTIPOSQL
          zEXPOREXT = "SQL"
          lDOCCAB:=MDG( "Gravar Informacao Estrutura" )
          lDOCDAD:=MDG( "Gravar Dados" )
          lDOCRECNO:=.F. //MDG( "Incluir Recno()/ID" )
          cSUBTIPO:="SQL"
          cMASK:="*."+TABLEEXT
          FAZERDBF( {|| multidocg( lDOCCAB, lDOCDAD, lDOCRECNO, cSUBTIPO ) }, .F.,,, cMASK )
        else
          sqltodos(cTIPOSQL)
        endif  
   CASE KEY=8
        mdltodos() 
   CASE KEY = 9
          sqlrdd_ODBC_info()   
   CASE KEY = 10       
          MDBGERAINFO()  
   OTHERWISE
      EXIT
   ENDCASE
ENDDO

RESTAA(aAMBIENTE)
layout()
loledb     := .f.
lmdb       := .f.
laccdb     := .f.
lFDB       := .f.

return nil


*+--------------------------------------------------------------------
*+
*+
*+
*+    Function pegcfgbanco()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
function pegcfgbanco()

lMDB := .F.
IF cTIPOSQL = "MDB" .OR. cTIPOSQL = "ACCESS" .OR. cTIPOSQL = "MDB64" .OR. cTIPOSQL = "ACCESS64"
   lMDB := .T.
ENDIF
lACCDB := .F.
IF cTIPOSQL = "ACCDB" .OR. cTIPOSQL = "ACCDB64"
   lACCDB := .T.
ENDIF
lFDB   := .F.
IF cTIPOSQL = "FIREBIRD"   .OR. cTIPOSQL = "FDB" .OR.  cTIPOSQL ="GDB" .OR.  cTIPOSQL ="IB"
   lFDB   := .T.
ENDIF
buscapadrao() //valores padrao das portas e usuarios

//
// ajustes nomes de drivers para 32 e 64 bits
//
loledb := .T.
IF cTIPOSQL = "MDB" .OR. cTIPOSQL = "ACCESS"
   loledb := hb_Version(HB_VERSION_BITWIDTH) <> 64  //oledb jet (32b) oledb accdb(64b)")
ENDIF
IF cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64"
   loledb := hb_Version(HB_VERSION_BITWIDTH) <> 64  //odbc 8.0(32b) odbc 9.0(64b)")
ENDIF
IF cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL"
   loledb := hb_Version(HB_VERSION_BITWIDTH) <> 64  //odbc 8.0(32b) odbc 9.0(64b)")
ENDIF
// No bloco de ajustes de drivers (linha ~200) 32 bits 64 bits driver mesmo nome
//IF cTIPOSQL == "FIREBIRD"   .OR. cTIPOSQL = "FDB" .OR.  cTIPOSQL ="GDB"  .OR.  cTIPOSQL ="IB"
//   loledb := hb_Version(HB_VERSION_BITWIDTH) <> 64 // .T. se 32-bit, .F. se 64-bit
//ENDIf

//
//mariadb mesmo nome de driver para 32 e 64 bits
//


IF cTIPOSQL = "ACCDB" .OR. cTIPOSQL = "ACCDB64"
   loledb := .F.  //Requer aceole.db 32 e ou 64 instalado
ENDIF

IF cTIPOSQL = "MYSQL" .or. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" .OR. cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" ;
           .OR. cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER" 
   OPENTIPOARQ()
   mdbdatabases()
ENDIF

IF cTIPOSQL = "LETO"
   OPENTIPOARQ()
ENDIF
IF cTIPOSQL = "PARADOX"
   OPENTIPOARQ()
ENDIF
IF lFDB  
   OPENTIPOARQ()
ENDIF

layout()
return .t.




*+--------------------------------------------------------------------
*+
*+    Function ExecArqSql()
*+
*+--------------------------------------------------------------------
*+
function ExecArqSql

LOCAL cCOMANDO := ""
LOCAL cARQIMP  := ""

cARQIMP := win_GetOPENFileName(,"Arquivos SQL",HB_CWD(),"Arquivos SQL","*.SQL",1)
//cARQORI := OPENTIPOARQ()

IF FILE(cARQIMP)
   //nao pode ser linha a linha pois um comando pode estar em mais de uma linha
   cCOMANDO:=MEMOREAD(cARQIMP)
   executacmd(cARQORI,aCOMANDO)
endif
return .t.


*+--------------------------------------------------------------------
*+
*+    Function mdbdatabases()
*+
*+--------------------------------------------------------------------
*+
function mdbdatabases()

local nChoices
nChoices := 0
aResult  := MDBTABLES()
IF LEN(aResult) > 0
   HB_dispbox(3,22,22,55,B_DOUBLE+" ")
   nChoices := ACHOICE(4,23,21,54,aResult)
ENDIF
cDATABASEX := ALLTRIM(IIF(nChoices > 0,aResult[nChoices],""))
RETURN aResult



*+--------------------------------------------------------------------
*+
*+    Function mdbtabela()
*+
*+--------------------------------------------------------------------
*+
function mdbtabela(cMDBARQ)

local nChoices
local aResult
nChoices := 0
aResult:={}
IF cTIPOSQL="PARADOX"
   RETURN
ENDIF   
IF VALTYPE(cMDBARQ) = "A"
   aResult := cMDBARQ
ELSE
   aResult := MDBTABLES(cMDBARQ)
ENDIF
IF LEN(aResult) > 0 
   HB_dispbox(3,22,22,55,B_DOUBLE+" ")
   nChoices := ACHOICE(4,23,21,54,aResult)
ENDIF
cTABELAX := ALLTRIM(IIF(nChoices > 0,aResult[nChoices],""))
RETURN aResult


*+--------------------------------------------------------------------
*+
*+    Function MDBEXP()
*+
*+--------------------------------------------------------------------
*+
function MDBEXP(nTIPO)

LOCAL cCAMMDB      := SPACE(100)
LOCAL lCOPIANAT
local Ldoc
local Lgrvstruinfo
LOCAL aSTRU
LOCAL nFIM
LOCAL i

cMDBARQ := OPENTIPOARQ()

mdbtabela(cMDBARQ)

IF cTIPOSQL="PARADOX"
   RETURN
ENDIF   
cTABELA := cTABELAX

IF EMPTY(cTABELA)
   cTABELA := INPUTBOX(SPACE(30),"Tabela")
ENDIF
cTABELA := ALLTRIM(cTABELA)
IF EMPTY(cTABELA)
   RETURN NIL
ENDIF

IF nTIPO = 1
   tdoc      := 90  //dbf
   zEXPOREXT := "DBF"
ENDIF

IF nTIPO = 2
   LCOPIANAT := .f.   //MDG("Copia Nativa(SIM) Interna(NAO)") //copy to nao implemntado PGsqlrddd
   tDOC      := pegtipodoc()  // .t. Inclui dbf se for nativa
   pegparexp()
   lDOCCAB   := .F.
   lDOCDAD   := .F.
   lDOCRECNO := .F.
   cSUBTIPO  := " "
   PegcsUB(tDOC)  //pegar o subtipo conforme tipo
ENDIF


hb_FNameSplit(cMDBARQ,@cCAMMDB,NIL,NIL)
cDESTINO := cCAMMDB+cTABELA+"_"+Ctiposql+"."+zEXPOREXT
MDT(cDESTINO)


cTABELAGRV := cTABELA
IF cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL"  //Dupla aspas maiuscula
   cTABELA := CHR(34)+UPPER(cTABELA)+CHR(34)
ENDIF


MDT("abrindo arquivo de origem: "+cMDBARQ)
opencmdbarq()
nLASTREC := reccount()
zei_fort(nLASTREC,,,0)
aSTRU := dbstruct()

//ajustar adordd para melhor tratativa campos @ datatime m diferenciando logwchar memos
//pois cria com tipos @ e M deixando o dbf com tipos incompativeis
//criar opcao de criar o dbf tratado con mdbtables
//importar via pipe ou outro
IF tDOC = 90 .OR. zEXPOREXT = "DBF"
   aINDICES := {}
   IF lMDB .OR. lACCDB
      //Ainda nao implantado testes com catalog ver outras opcoes
      //utilizando sqltodbfstru
      aSTRU := sqltodbfstru(aSTRU)
      //funcionou o catalog porem com ordem diferente dos campos
      //gerando erro na gravacao
      //aSTRU   :=MDBTABLES(cMDBARQ,cTABELAgrv)
      aINDICES := MDBTABLES(cMDBARQ,cTABELAgrv,"__INDEX__")
   ELSE
      aSTRU := MDBTABLES(cMDBARQ,cTABELAgrv)
   ENDIF
   cALIASADO := ALIAS()
   DBCreate(ctabela+"_"+Ctiposql,aSTRU,"DBFCDX")
   DBUseArea(.T.,,ctabela+"_"+Ctiposql,,.F.,.F.)
   IF LEN(aINDICES) > 0
      cCHAVEINDEX  := aINDICES[1,1]
      cCAMPOSINDEX := ""
      FOR I := 1 TO LEN(aINDICES)
         IF cCHAVEINDEX <> aINDICES[I,1]
            cCHAVEINDEX  := aINDICES[I,1]
            cCAMPOSINDEX := aINDICES[I,2]
         ELSE
            IF EMPTY(cCAMPOSINDEX)
               cCAMPOSINDEX := aINDICES[I,2]
            ELSE
               cCAMPOSINDEX := cCAMPOSINDEX+","+aINDICES[I,2]
            ENDIF
         ENDIF
      NEXT I
   ENDIF
   cALIASDBF := ALIAS()
   nFIM      := FCOUNT()
   dbselectar(cALIASADO)
   dbgotop()
   while !eof()
      aVALOR := {}
      FOR I := 1 TO nFIM
         AADD(aVALOR,{hb_FIELDGET(I),FIELDNAME(I)})  //guarda o nome do campo caso a ordem venha invertida
      NEXT I
      dbselectar(cALIASDBF)
      NETRECAPP()
      FOR I := 1 TO nFIM
         eVALOR := aVALOR[I,1]
         if valtype(eVALOR) = "C" .AND. SUBSTR(eVALOR,5,1) = "-" .AND. SUBSTR(eVALOR,8,1) = "-"
            eVALOR := substr(eVALOR,6,2)+"/"+substr(eVALOR,9,2)+"/"+substr(eVALOR,1,4)
            eVALOR := CTOD(eVALOR)
         ENDIF
         if valtype(eVALOR) = "C" .OR. valtype(eVALOR) = "M"
            //eVALOR := RANGEREPL(chr(0),chr(31),eVALOR," ")  //Remove caracteres de controle
            //eVALOR := TIRACE(eVALOR)
            //eVALOR := ALLTRIM(eVALOR)
               eVALOR := FixSRTExtendido( eVALOR , .T. , .T. , .T. , .T. , .T. )
            //FixSRTExtendido( cVALOR,lLOW,lUP,lACE,lUTF, lESP )
         ENDIF
         IF !EMPTY(eVALOR)
            nPOSDBF := FieldPos(aVALOR[I,2])
            fieldput(nPOSDBF,Evalor)
            //grava com o nome do campo casos a posicao dos campos ados seja difetente dos campos dbf
            //FIELDPUT(I,eVALOR)
         ENDIF
      NEXT I
      dbselectar(cALIASADO)
      zei_fort(nLASTREC,,,1)
      dbskip()
   enddo
ELSE
   multidocg(lDOCCAB,lDOCDAD,lDOCRECNO,cSUBTIPO,TIRAEXT(cDESTINO))
ENDIF
dbcloseall()
return nil


*+--------------------------------------------------------------------
*+
*+    Function sqltodbfstru()
*+
*+--------------------------------------------------------------------
*+
function sqltodbfstru(aStruct)

local nFIM
local i
LOCAL aTAM
LOCAL nLENMAX
LOCAL aRETU
nFIM := LEN(aStruct)
for i := 1 to NFIM
   nLENMAX := 0
   IF (aStruct[i,DBS_TYPE] = "I" .or. aStruct[i,DBS_TYPE] = "B") .and. aStruct[i,DBS_LEN] = 0 .AND. cTIPOSQL = "SQLITE"
      Ctmp := "select max( length( "+aStruct[i,DBS_NAME]+" ) ) from "+cTABELA
      aTAM := MDBTABLES(cMDBARQ,cTABELA,ctmp)
      if len(aTAM) > 0
         nLenMAX := aTAM[1]
      endif

      //Tipo integer 4 =numerico 8
      IF aStruct[i,DBS_TYPE] = "I"  //integer
         aStruct[ i, DBS_TYPE ] := "N"
         IF nLENMAX > 8
            aStruct[i,DBS_LEN] = nLENMAX
         ELSE
            aStruct[i,DBS_LEN] = 8
         ENDIF
      ENDIF

      //Tipo B double
      IF aStruct[i,DBS_TYPE] = "B"
         aStruct[ i, DBS_TYPE ] := "N"
         IF nLENMAX > 15
            aStruct[i,DBS_LEN] = nLENMAX+4  //acrecenta 4 decimais
         ELSE
            aStruct[i,DBS_LEN] = 15
         ENDIF
         aStruct[i,DBS_LEN] = 4
      ENDIF
   endif

   IF aStruct[i,DBS_TYPE] = "I" .AND. (lmdb .or. Laccdb)
      aStruct[ i, DBS_TYPE ] := "N"
      //DBS_LEN TRAS precision int2 int4 int8
      //Ajustustando o tamanho precisao para numerico para  2->4  4->8  8->16
      aStruct[i,DBS_LEN] = aStruct[i,DBS_LEN] * 2
   ENDIF

   IF aStruct[i,DBS_TYPE] = "L" .AND. (lmdb .or. Laccdb) .AND. aStruct[i,DBS_LEN] > 1
      aStruct[ i, DBS_LEN ] := 1
   ENDIF

   aRETU := geracampodbf(aStruct[i,DBS_NAME],aStruct[i,DBS_TYPE],aStruct[i,DBS_LEN],aStruct[i,DBS_DEC])

   aStruct[ i, DBS_NAME ] := aRETU[DBS_NAME]
   aStruct[ i, DBS_TYPE ] := aRETU[DBS_TYPE]
   aStruct[ i, DBS_LEN ]  := aRETU[DBS_LEN]
   aStruct[ i, DBS_DEC ]  := aRETU[DBS_DEC]

next i
return aStruct


*+--------------------------------------------------------------------
*+
*+
*+
*+    Function opencmdbarq()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
function opencmdbarq()

local lRETU
lRETU := .T.
DO CASE
CASE lMDB
   // DBUseArea( <lNewArea> , <cDriver> , <cName>, <xcAlias> , <lShared> , <lReadOnly> ) -> Nil
   if loledb
      hb_adoSetTable(cTABELA) 
      dbUseArea(.F.,"ADORDD",(cMDBARQ),,.T.,.F.)
   else
      hb_adoSetTable(cTABELA) 
      hb_adoSetEngine("ACEOLEDB") 
      dbUseArea(.F.,"ADORDD",(cMDBARQ),,.T.,.F.)
   endif
CASE lACCDB
   hb_adoSetTable(cTABELA) 
   hb_adoSetEngine("ACEOLEDB") 
   dbUseArea(.F.,"ADORDD",(cMDBARQ),,.T.,.F.)
CASE  lFDB 
   hb_adoSetTable(cTABELA) 
   hb_adoSetEngine("FIREBIRD") 
   hb_adoSetUser(CUSERX) 
   hb_adoSetPassword(CPASSX) 

   dbUseArea(.F.,"ADORDD",(cMDBARQ),,.T.,.F.)
CASE cTIPOSQL = "SQLITE"
   hb_adoSetTable(cTABELA) 
   hb_adoSetEngine("SQLITE") 
   dbUseArea(.F.,"ADORDD",(cMDBARQ),,.T.,.F.)
CASE cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64"
   if loledb
      hb_adoSetTable(cTABELA) 
      hb_adoSetEngine("MYSQL") 
      hb_adoSetServer(cSERVERx) 
      hb_adoSetUser(CUSERX) 
      hb_adoSetPassword(CPASSX) 
      dbUseArea(.F.,"ADORDD",(cMDBARQ),,.T.,.F.)
   else
      hb_adoSetTable(cTABELA) 
      hb_adoSetEngine("MYSQL64") 
      hb_adoSetServer(cSERVERx) 
      hb_adoSetUser(CUSERX) 
      hb_adoSetPassword(CPASSX) 
      dbUseArea(.F.,"ADORDD",(cMDBARQ),,.T.,.F.)
   endif
CASE cTIPOSQL = "MARIADB"
   hb_adoSetTable(cTABELA) 
   hb_adoSetEngine("MARIADB") 
   hb_adoSetServer(cSERVERx) 
   hb_adoSetUser(CUSERX) 
   hb_adoSetPassword(CPASSX) 
   dbUseArea(.F.,"ADORDD",(cMDBARQ),,.T.,.F.)
CASE cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER"
   hb_adoSetTable(cTABELA) 
   hb_adoSetEngine("SQL") 
   hb_adoSetServer(cSERVERx) 
   hb_adoSetUser(CUSERX) 
   hb_adoSetPassword(CPASSX) 
   dbUseArea(.F.,"ADORDD",(cMDBARQ),,.T.,.F.)
CASE cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL"
   if loledb
      TRY
        hb_adoSetTable(cTABELA) 
        hb_adoSetEngine("PGSQL") 
        hb_adoSetServer(cSERVERx) 
        hb_adoSetUser(CUSERX) 
        hb_adoSetPassword(CPASSX) 
        dbUseArea(.F.,"ADORDD",(cMDBARQ),,.T.,.F.)
      catch oErR
        MDT("Erro Abrindo")
        lRETU := .F.
      END
   else
      TRY
        hb_adoSetTable(cTABELA) 
        hb_adoSetEngine("PGSQL64") 
        hb_adoSetServer(cSERVERx) 
        hb_adoSetUser(CUSERX) 
        hb_adoSetPassword(CPASSX) 
        dbUseArea(.F.,"ADORDD",(cMDBARQ),,.T.,.F.)
      catch oErR
        MDT("Erro Abrindo")
        lRETU := .F.
     END
   endif
CASE cTIPOSQL == "PARADOX"
   hb_adoSetTable(cTABELA)
   // Verifique se o seu ADORDD suporta "PARADOX" ou se requer "MSDASQL" com DSN
   hb_adoSetEngine("PARADOX")
   dbUseArea(.F.,"ADORDD",(cMDBARQ),,.T.,.F.)
ENDCASE
return lRETU




*+--------------------------------------------------------------------
*+
*+    Function mdbcria()
*+
*+--------------------------------------------------------------------
*+
function mdbcria()
LOCAL cCONN
cCONN:=""
if  lFDB //usando nativa erro com catalgo nao suportado
   firecreate() //Pergunta se quer usar sql ou fbcreate
    return
endif
DO CASE
    CASE lMDB
       cARQORI := win_GetSAVEFileName(,"Arquivos de Origem",HB_CWD(),"Arquivos mdb","*.MDB",1)
    CASE lACCDB
       cARQORI := win_GetSAVEFileName(,"Arquivos de Origem",HB_CWD(),"Arquivos accdb","*.accdb",1)
    CASE cTIPOSQL = "SQLITE"
       cARQORI := win_GetsaveFileName(,"SQLite Files",HB_CWD(),"SQLite",;
        {{'SQLite','*.sqlite'},{'SQLite db','*.DB'},;
        {'SQLite3','*.sqlite3'},{'SQLite db3','*.DB3'},;
        {'SQLite Fossil','*.fossil'},{'All Files','*.*'}},1)
    CASE lFDB 
       cARQORI := win_GetsaveFileName(,"Firebase Files",HB_CWD(),"Firebase",;
        {{'Firebird fdb','*.fdb'},{'Firebird gdb','*.gdb'},{'Firebird ib','*.ib'},;
         {'All Files','*.*'}},1)  
    CASE cTIPOSQL == "PARADOX"
       cARQORI := win_GetSAVEFileName(,"Arquivos Paradox",HB_CWD(),"Paradox","*.db",1)     
ENDCASE


IF lFDB 
    cDATABASEX := ""
    executacmd("", "CREATE DATABASE '"+cARQORI+"' USER 'SYSDBA' PASSWORD 'masterkey' PAGE_SIZE = 8192 DEFAULT CHARACTER SET ISO8859_1;")
     //Abre com "" para o geraconn nao atribui o fdb,gdb,ib na conecao pois ainda nao foi criado
    CDATABASEX := cARQORI
    RETURN
ENDIF



//cria com sql query create database
if cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" .OR. cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" ;
           .OR. cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER"
   cARQORI       := OPENTIPOARQ()
   cnewDATABASEX := INPUTBOX(SPACE(30),"Novo database")
   cnewDATABASEX := alltrim(cnewDATABASEX)
   IF .NOT. EMPTy(cnewDATABASEX)
      IF hb_AScan(MDBTABLES(),cnewDATABASEX,,,.T.) > 0
         MDT("Ja existe Database "+cnewDATABASEX)
         return .f.
      ENDIF
      cDATABASEX := ""
      executacmd(Carqori,"CREATE DATABASE IF NOT EXISTS "+Cnewdatabasex)
      CDATABASEX := CNEWDATABASEX
   ENDIF
endif

//cria com catalogx
IF lMDB .OR. lACCDB
   CreateAccessDatabase(cARQORI)
   EXECUTACMD(cARQORI,"GRANT SELECT ON TABLE MSysObjects TO ADMIN,PUBLIC")
   EXECUTACMD(cARQORI,"create view showtables as select name from MSysObjects where MSysObjects.type In (1,4,6) and MSysObjects.name not like '~*' and MSysObjects.name not like 'MSys%'")
   //EXECUTACMD(cARQORI,"GRANT SELECT ON VIEW showtableS TO ADMIN,PUBLIC")
ENDIF

IF lFDB 
   CreateAccessDatabase(cARQORI)
ENDIF


//basta criar o arquivo ja e entendido pelo sqlite
IF cTIPOSQL = "SQLITE"
    IF ! hb_FileExists(cARQORI)
       HB_MEMOWRIT(cARQORI,"")
    ENDIF   
ENDIF

IF cTIPOSQL == "PARADOX"
   ParadoxCreateTable( cARQORI, aStruct )
ENDIF

RETURN NIL

FUNCTION GeraSQLMetadata()
LOCAL cSqlFields, cSqlIndexes
cSqlFields := ""
cSqlIndexes := ""
DO CASE
   CASE cTIPOSQL == "SQLITE"
      cSqlFields  := "CREATE TABLE IF NOT EXISTS table_metadata (nome_tabela TEXT, column_name TEXT, original_type TEXT, tamanho INTEGER, precisao INTEGER, is_nullable INTEGER, field_visual_picture TEXT)"
      cSqlIndexes := "CREATE TABLE IF NOT EXISTS index_metadata (nome_tabela TEXT, index_name TEXT, expression TEXT, sql_expression TEXT, filter_expression TEXT, is_unique INTEGER, is_bag INTEGER)"

   CASE cTIPOSQL == "MYSQL" .OR. cTIPOSQL == "MYSQL64" .OR. cTIPOSQL == "MARIADB"
      cSqlFields  := "CREATE TABLE IF NOT EXISTS table_metadata (nome_tabela VARCHAR(50), column_name VARCHAR(50), original_type VARCHAR(1), tamanho INTEGER, precisao INTEGER, is_nullable INTEGER, field_visual_picture VARCHAR(250))"
      cSqlIndexes := "CREATE TABLE IF NOT EXISTS index_metadata (nome_tabela VARCHAR(50), index_name VARCHAR(50), expression TEXT, sql_expression TEXT, filter_expression TEXT, is_unique INTEGER, is_bag INTEGER)"
  CASE cTIPOSQL == "DUCKDB"
     cSqlFields  := "CREATE TABLE IF NOT EXISTS table_metadata (nome_tabela VARCHAR, column_name VARCHAR, original_type VARCHAR, tamanho BIGINT, precisao BIGINT, is_nullable BIGINT, field_visual_picture VARCHAR)"
     cSqlIndexes := "CREATE TABLE IF NOT EXISTS index_metadata (nome_tabela VARCHAR, index_name VARCHAR, expression VARCHAR, sql_expression VARCHAR, filter_expression VARCHAR, is_unique BIGINT, is_bag BIGINT)"

   CASE cTIPOSQL == "PGSQL" .OR. cTIPOSQL == "PGSQL64" .OR. cTIPOSQL == "POSTGRESQL"
      cSqlFields  := "CREATE TABLE IF NOT EXISTS table_metadata (nome_tabela VARCHAR(50), column_name VARCHAR(50), original_type VARCHAR(1), tamanho INTEGER, precisao INTEGER, is_nullable INTEGER, field_visual_picture VARCHAR(250))"
      cSqlIndexes := "CREATE TABLE IF NOT EXISTS index_metadata (nome_tabela VARCHAR(50), index_name VARCHAR(50), expression TEXT, sql_expression TEXT, filter_expression TEXT, is_unique INTEGER, is_bag INTEGER)"

   CASE lMDB .OR. lACCDB 
      // Access não aceita IF NOT EXISTS e exige colchetes em palavras reservadas. Usa TEXT(tamanho) e MEMO para textos longos.
      cSqlFields  := "CREATE TABLE table_metadata (nome_tabela TEXT(50), column_name TEXT(50), original_type TEXT(1), [tamanho] INTEGER, [precisao] INTEGER, is_nullable INTEGER, field_visual_picture TEXT(250))"
      cSqlIndexes := "CREATE TABLE index_metadata (nome_tabela TEXT(50), index_name TEXT(50), expression MEMO, sql_expression MEMO, filter_expression MEMO, is_unique INTEGER, is_bag INTEGER)"

   CASE cTIPOSQL == "MSSQL" .OR. cTIPOSQL == "SQLSERVER"
      // SQL Server exige verificação via OBJECT_ID e usa VARCHAR(MAX) para blocos grandes de texto, além de INT ao invés de INTEGER.
      cSqlFields  := "IF OBJECT_ID('table_metadata', 'U') IS NULL " + ;
                     "CREATE TABLE table_metadata (nome_tabela VARCHAR(50), column_name VARCHAR(50), original_type VARCHAR(1), tamanho INT, precisao INT, is_nullable INT, field_visual_picture VARCHAR(250))"
      cSqlIndexes := "IF OBJECT_ID('index_metadata', 'U') IS NULL " + ;
                     "CREATE TABLE index_metadata (nome_tabela VARCHAR(50), index_name VARCHAR(50), expression VARCHAR(MAX), sql_expression VARCHAR(MAX), filter_expression VARCHAR(MAX), is_unique INT, is_bag INT)"

   CASE cTIPOSQL == "FIREBIRD"
      // Firebird não possui IF NOT EXISTS por padrão em DDL simples e exige BLOB SUB_TYPE TEXT para textos longos/expressões.
      cSqlFields  := "CREATE TABLE table_metadata (nome_tabela VARCHAR(50), column_name VARCHAR(50), original_type VARCHAR(1), tamanho INTEGER, precisao INTEGER, is_nullable INTEGER, field_visual_picture VARCHAR(250))"
      cSqlIndexes := "CREATE TABLE index_metadata (nome_tabela VARCHAR(50), index_name VARCHAR(50), expression BLOB SUB_TYPE TEXT, sql_expression BLOB SUB_TYPE TEXT, filter_expression BLOB SUB_TYPE TEXT, is_unique INTEGER, is_bag INTEGER)"
   ENDCASE
RETURN {cSqlFields,cSqlIndexes}



*+--------------------------------------------------------------------
*+
*+    Function DBF2MDB()
*+
*+--------------------------------------------------------------------
*+
FUNCTION DBF2MDB(cMDBARQ,cDBFARQ,lincdados)

local aINDICES
LOCAL nINDICES
LOCAL cINDEXNAME
LOCAL J
local msql
local lgravasql
LOCAL cSqlFields, cSqlIndexes
LOCAL aRETUMETA

aRETUMETA:=GeraSQLMetadata()
cSqlFields  :=aRETUMETA[1] 
cSqlIndexes := aRETUMETA[2]



// Execução dos comandos de criação das tabelas de metadados
IF !Empty( cSqlFields )
   
   IF lMDB .OR. lACCDB  .OR. lFDB 
      
      // Tenta criar a tabela de metadados de campos de forma isolada
      TRY
         executacmd(cMDBARQ, cSqlFields)
      CATCH
         // Tabela 'table_metadata' já existe ou erro ignorado com segurança
      END
      
      // Tenta criar a tabela de metadados de índices de forma isolada
      TRY
         executacmd(cMDBARQ, cSqlIndexes)
      CATCH
         // Tabela 'index_metadata' já existe ou erro ignorado com segurança
      END
      
   ELSE
      // Bancos que suportam "IF NOT EXISTS" ou validação nativa (SQLite, MySQL, PostgreSQL, SQL Server)
      executacmd(cMDBARQ, cSqlFields)
      executacmd(cMDBARQ, cSqlIndexes)
   ENDIF
   
ENDIF

lgravasql := mdg("gravar sql")
aINDICES  := {}
dbUseArea( .F.,, cDBFARQ,, .T., .F. )
//use &cDBFARQ.
aSTRU    := DBSTRUCT()
nLASTREC := reccount()
zei_fort(nLASTREC,,,0)
cNOMETABELA := ALIAS()
ctablename  := cNOMETABELA

// 1. LIMPEZA DOS METADADOS (Geral para todos os bancos)
// Limpa o que existia anteriormente para evitar duplicidade na re-importacao
executacmd( cMDBARQ, "DELETE FROM table_metadata WHERE nome_tabela = " + c2sql(cNOMETABELA) )
executacmd( cMDBARQ, "DELETE FROM index_metadata WHERE nome_tabela = " + c2sql(cNOMETABELA) )


//Grava metadata do dbf
aMETADBF:=GeradbfSchema( cNOMETABELA, aStru )
FOR j := 1 TO LEN(aMETADBF)
    mSQL:=aMETADBF[J]
    executacmd( cMDBARQ, msql )
NEXT J

aINDICES:=GeraINDICES()
nIndexes := LEN(aINDICES)
FOR j := 1 TO nIndexes
//    msql := aINDICES[J,1]  //Create index abaixo apos criacao da tabela
 //   executacmd( cMDBARQ, msql )
    msql := aINDICES[J,2]   //insert into metadata
    executacmd( cMDBARQ, msql )
NEXT j

dbclosearea()

MDT(cNOMETABELA)

Set(_SET_DATEFORMAT,"yyyy-mm-dd")




msql := ""
DO CASE
CASE cTIPOSQL = "SQLITE"
   msql := SqliteCreateTable(cNOMETABELA,aSTRU,"SQLITE")
   executacmd(cMDBARQ,msql)
CASE cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB"
   msql := SqliteCreateTable(cNOMETABELA,aSTRU,"MYSQL")
   executacmd(cMDBARQ,msql)
CASE cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL"
   msql := SqliteCreateTable(cNOMETABELA,aSTRU,"PGSQL")
   executacmd(cMDBARQ,msql)
CASE lMDB   
   msql := SqliteCreateTable(cNOMETABELA,aSTRU,"MDB")
   executacmd(cMDBARQ,msql)
CASE lACCDB   
   msql := SqliteCreateTable(cNOMETABELA,aSTRU,"ACCDB")
   executacmd(cMDBARQ,msql)
CASE cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER"
   msql := SqliteCreateTable(cNOMETABELA,aSTRU,"MSSQL")
   executacmd(cMDBARQ,msql)
CASE lFDB 
   msql := SqliteCreateTable(cNOMETABELA, aSTRU, "FIREBIRD") // Certifique-se que sua SqliteCreateTable suporte este parâmetro
   executacmd(cMDBARQ, msql)   
OTHERWISE
ENDCASE

IF lGRAVASQL .AND. .NOT. EMPTY(msql)
   HB_MEMOWRIT(cNOMETABELA+"_createtable_"+cTIPOSQL+".sql",Msql,.F.)
ENDIF

if len(aindices) > 0
    msql := ""
    for ii := 1 to len(aINDICES)
        executacmd(cMDBARQ, aINDICEs[II,1])
        mSQL += aINDICEs[II,1]+HB_OSNEWLINE()
    next ii
    IF lGRAVASQL
       HB_MEMOWRIT(cNOMETABELA+"_createindex_"+cTIPOSQL+".sql",mSQL,.f.)
    endif  
endif

cTABELA := cNOMETABELA  //publica usada o opencmdarq
IF cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "POSTGRESQL" .OR. cTIPOSQL = "PGSQL64"  //Dupla aspas maiuscula
   IF EMPTY(COWNERX)
      cTABELA := CHR(34)+UPPER(cTABELA)+CHR(34)
   ELSE
      cTABELA := CHR(34)+AllTrim(cOWNERX) + "." + cTABELA+CHR(34)
   ENDIF   
ENDIF

if nLASTREC > 0 .AND. lincdados  //nao importa se nao tiver registros
   try
      opencmdbarq()
   //Criar opcao de append from insert into usando
      try
         append from &cDBFARQ. WHILE zei_fort(nLASTREC,,,1)
      catch oErR
          MDT("Erro anexando dados")
      end
   catch oErR
      MDT("Erro ao abrir nova tabela")
   end
   dbcloseall()
endif

Set(_SET_DATEFORMAT,"dd/mm/yyyy")


RETURN .T.


*+--------------------------------------------------------------------
*+
*+    Function OPENTIPOARQ()
*+
*+--------------------------------------------------------------------
*+
FUNCTION OPENTIPOARQ

LOCAL cMDBARQ
cMDBARQ := ""

DO CASE
CASE lMDB   
   cMDBARQ    := win_GetOPENFileName(,"Arquivos de Destino",HB_CWD(),"Arquivos mdb","*.MDB",1)
   cDATABASEX := cMDBARQ
    hb_FNameSplit(cMDBARQ,NIL,@cBANCOX,NIL)
CASE lACCDB   
   cMDBARQ    := win_GetOPENFileName(,"Arquivos de Destino",HB_CWD(),"Arquivos accdb","*.accdb",1)
   cDATABASEX := cMDBARQ
    hb_FNameSplit(cMDBARQ,NIL,@cBANCOX,NIL)
CASE cTIPOSQL = "SQLITE"
   cMDBARQ := win_GetOpenFileName(,"SQLite Files",HB_CWD(),"SQLite",;
    {{'SQLite','*.sqlite'},{'SQLite db','*.DB'},;
    {'SQLite3','*.sqlite3'},{'SQLite db3','*.DB3'},;
    {'SQLite Fossil','*.fossil'},{'All Files','*.*'}},1)
   cDATABASEX := cMDBARQ
    hb_FNameSplit(cMDBARQ,NIL,@cBANCOX,NIL)
CASE lFDB 
   cMDBARQ := win_GetopenFileName(,"Firebase Files",HB_CWD(),"Firebase",;
    {{'Firebird fdb','*.fdb'},{'Firebird gdb','*.gdb'},{'Firebird ib','*.ib'},;
     {'All Files','*.*'}},1)      
    cDATABASEX := cMDBARQ
    hb_FNameSplit(cMDBARQ,NIL,@cBANCOX,NIL)
CASE cTIPOSQL == "PARADOX"
    cMDBARQ := win_GetOPENFileName(,"Selecione o arquivo Paradox",,"Arquivo DB|*.db",,"*.db")
    cDATABASEX := cMDBARQ
    HB_FNameSplit( cMDBARQ, NIL , @cTABELAX , NIL ) 
ENDCASE

IF cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB" .OR. cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL" ;
    .OR. cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER" .OR. cTIPOSQL = "LETO" .OR. lFDB 
    cBANCOX := PADR(cBANCOX,30," ")
   cSERVERX := PADR(cSERVERX,30," ")
   cUSERX := PADR(cUSERX,30," ")
   cPASSX := PADR(cPASSX,30," ")
   cownerX := PADR(cownerX,30," ")
   cPASSX := PADR(cPASSX,30," ")
   HB_dispbox(3,22,22,55,B_DOUBLE+" ")
   @ 05,23 SAY "Banco"
   @ 07,23 SAY "Server"         
   @ 09,23 SAY "user"           
   @ 11,23 say "pass"    
   @ 13,23 say "owner"
   @ 15,23 say "port"
   @ 06,23 GET cBANCOX   VALID buscachaves( cBANCOX )  
   @ 08,23 get cSERVERX  
   @ 10,23 get cuserx         
   @ 12,23 get cpassx
   @ 14,23 get cownerx
   @ 16,23 get cportax         
   READ
   cSERVERX  := ALLTRIM(cSERVERX)
   cuserx    := alltrim(cuserx)
   cpassx    := alltrim(cpassx)
   cowenrx   := alltrim(cownerx)
   cportax   := alltrim(cportax)
   cBANCOX   := alltrim(cBANCOx)
   cDATABASEX:= alltrim(cdatabasex)
   IF lFDB //firebird requer arquivo fisico .fdb .gdb .ib e configuracao do server
   ELSE
     cMDBARQ := cDATABASEX
   ENDIF  
ENDIF

RETURN cMDBARQ


*+--------------------------------------------------------------------\
*+    Function buscachaves()
*+--------------------------------------------------------------------\
FUNCTION buscachaves( cNomeBanco )
   LOCAL cSecaoCofre

   // Se o usuário digitou algo manualmente no servidor, aceita e não busca no cofre
   IF ! Empty( cNomeBanco)

       // Garante que a seção do cofre será o nome do banco limpo em maiúsculas
       cSecaoCofre := Upper( AllTrim( cNomeBanco ) )

       // Busca as credenciais de forma segura no config.dat mascarado
       cSERVERX := padr(LerDoCofre( cSecaoCofre, "Server",cSERVERX ),30," ")
       cUSERX   := padr(LerDoCofre( cSecaoCofre, "User",cUSERX ),30," ")
       cPASSX   := padr(LerDoCofre( cSecaoCofre, "Password",cPASSX ),30," ")
       cOwnerX   := padr(LerDoCofre( cSecaoCofre, "Owner",cOwnerX ),30," ")
       cportaX   := padr(LerDoCofre( cSecaoCofre, "portax",cportaX),30," ")
    ENDIF   
    buscapadrao()
    IF lFDB .AND. EMPTY(cPASSX)
       cPASSX   := padr("masterkey",30," ")
    ENDIF

   RETURN .T.

function buscapadrao()
IF cTIPOSQL="LETO"
   IF EMPTY(cSERVERX)
      cSERVERX   := PADR("//127.0.0.1:2812/",30," ")  
   ENDIF   
   IF EMPTY(cPORTAX)
      cPORTAX:= PADR("2812",30," ")
   ENDIF   
ENDIF   

IF cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64" .OR. cTIPOSQL = "MARIADB"
   IF EMPTY(cUSERX)
       cUSERX := PADR("root",30," ")   
   ENDIF
   IF EMPTY(cPORTAX)
       cPORTAX:= PADR("3306",30," ")
   ENDIF
ENDIF

IF cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL"
   IF EMPTY(cUSERX)
       cUSERX := PADR("postgres",30," ") 
   ENDIF   
   IF EMPTY(cPORTAX)
       cPORTAX:= PADR("5432",30," ")
   ENDIF
ENDIF
IF lFDB 
   IF EMPTY(cSERVERX)
       cSERVERX := PADR("localhost", 30, " ")   //net://
   ENDIF
   IF EMPTY(cUSERX)
      cUSERX := PADR("SYSDBA",30," ")  
   ENDIF
   IF EMPTY(cPORTAX)
      cPORTAX:= PADR("3050",30," ")
   ENDIF
ENDIF
IF cTIPOSQL = "ORACLE" .OR. cTIPOSQL = "OCI"
   IF EMPTY(cPORTAX)
        cPORTAX:= PADR("1521",30," ")
   ENDIF
ENDIF
IF cTIPOSQL = "MSSQL"
   IF EMPTY(cPORTAX)
        cPORTAX:= PADR("1433",30," ")
   ENDIF
ENDIF
IF cTIPOSQL == "PARADOX"
    cSERVERX := SPACE(30)
ENDIF
IF cTIPOSQL == "CUBRID"
    IF EMPTY(cSERVERX)
        cSERVERX := PADR("localhost", 30, " ") 
   ENDIF
   IF EMPTY(cPORTAX)
        cPORTAX:= PADR("33000",30," ")
   ENDIF
      IF EMPTY(cUSERX)
      cUSERX := PADR("dba",30," ")  
   ENDIF
ENDIF
RETURN





*+--------------------------------------------------------------------
*+
*+    Function MDBIMPDBF()
*+
*+--------------------------------------------------------------------
*+
FUNCTION MDBIMPDBF()


MDBARQ := OPENTIPOARQ()


 nOLDTIPO := TIPODBF
            alertX( "escolha origem" )
            tipodbfesc()
            nORITIPO   := TIPODBF
            cORIDRIVER := RDDNOME( TIPODBF )
            lincdados:=mdg("Incluir Dados")
            IF MDG("Arquivo individual")
               cARQORI    := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*."+TABLEEXT, 1 )
                IF File( cARQORI )
                   IF cTIPOSQL="PARADOX"
                     Dbf_Para_Paradox( cARQORI,cORIDRIVER)
                   ELSE
                     DBF2MDB(cMDBARQ,cARQORI,lincdados)
                  ENDIF
              ENDIF
            ELSE
               cPASTA:=SelectFolder()
               cPASTA+="\*."+TABLEEXT 
               //FAZERDBF(bUSO                                       , lSHARE[.F.] , bPRE, bPOS, cMASK ,LOPEN )
               IF cTIPOSQL="PARADOX"
                  FAZERDBF( {|| Dbf_Para_Paradox( cCAMINHOCOMPLETO,cORIDRIVER,lincdados) }, .F. ,     ,     ,cPASTA,.F.)
               ELSE
                  FAZERDBF( {|| DBF2MDB(cMDBARQ,cCAMINHOCOMPLETO,lincdados) }, .F. ,     ,     ,cPASTA,.F.)
               ENDIF   
            ENDIF   
            RDDNOME( nOLDTIPO )   // retorna tipo anterior
return


*+--------------------------------------------------------------------
*+
*+    Function MDBGERAINFO()
*+
*+--------------------------------------------------------------------
*+
FUNCTION MDBGERAINFO()
LOCAL cCONNSTRING
MDBARQ := OPENTIPOARQ()
DO CASE 
   CASE lMDB
        GeraMDdbml(MDBARQ)
   CASE lACCDB
        GeraMDdbml(MDBARQ)
   CASE cTIPOSQL == "SQLITE"
       GeraMDdbml(MDBARQ)
   OTHERWISE
       cCONNSTRING:=GERACONN( cDATABASEX )
       GeraMDdbml(,cCONNSTRING)
ENDCASE



*+--------------------------------------------------------------------
*+
*+
*+
*+    Function MDBTABLES()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
FUNCTION MDBTABLES(cDataBase,cTABELA,cCAMPOSQL)

LOCAL aRETU
local cCONN
LOCAL cCOMANDO
LOCAL cTIPOINFO
local cFieldName   := ''
local cFieldType   := ''
local nFieldLength := 0
local nFieldDec    := 0
local lopen
LOCAL cSchema
LOCAL cSchemaSQL
LOCAL cUserOracle
LOCAL cSchemaMY
LOCAL cSchemaPG
LOCAL cCHAVENAME  := ""
LOCAL cCHAVECAMPO := ""

IF cTIPOSQL == "PARADOX"
   RETURN //Nao implantado
ENDIF

Lopen        := .F.
lARQMDBACCDB := .F.
cCOMANDO     := ""


IF lMDB .OR. lACCDB
   lARQMDBACCDB := .T.
ENDIF

cTIPOINFO := "TABELA"
IF VALTYPE(cDATABASE) <> "C"
   cTIPOINFO := "DATABASE"
ENDIF
IF VALTYPE(cTABELA) = "C"
   cTIPOINFO := "ESTRUTURA"
ENDIF
IF VALTYPE(cCAMPOSQL) = "C"
   do case
   case cCAMPOSQL = "__INDEX__"
      cTIPOINFO := "__INDEX__"
   case cCAMPOSQL = "__VERSION__"
      cTIPOINFO := "__VERSION__"
   OTHERWISE
      cTIPOINFO := "CCAMPOSQL"
   ENDCASE
ENDIF

aRETU := {}
cCONN := GERACONN(cDATABASE)

try
oConn := WIN_OLECreateObject("ADODB.Connection")
with object oConn
:ConnectionString := cConn
:Open()
END
catch oErr
ShowADOError(oERR,oConn,cConn)
return aRETU
end


oRS                := WIN_OLECreateObject('ADODB.RecordSet')
oRS:CursorLocation := 3



cCOMANDO := ""
IF cTIPOINFO = "DATABASE"
   cCOMANDO :=Dialeto_ShowDatabases()
ENDIF

IF cTIPOINFO = "TABELA"
    DO CASE
       CASE lMDB .OR. lACCDB 
          cCOMANDO := "SELECT MSysObjects.name AS TABLE_NAME FROM MSysObjects WHERE MSysObjects.type IN (1,4,6) " + ;
                      "AND MSysObjects.name NOT LIKE '~*' AND MSysObjects.name NOT LIKE 'MSys%' " + ;
                      "ORDER BY MSysObjects.name;"

       CASE cTIPOSQL == "SQLITE" .OR. At( ".SQLITE", Upper( cdatabaseX ) ) > 0
          cCOMANDO := "SELECT name AS TABLE_NAME FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;"

       CASE cTIPOSQL == "MYSQL" .OR. cTIPOSQL == "MYSQL64" .OR. cTIPOSQL == "MARIADB"
          // Permite o uso padronizado do alias "TABLE_NAME" e aceita filtrar por banco/schema (cOwnerx)
          if Empty( cOwnerx )
             cCOMANDO := "SELECT table_name AS TABLE_NAME FROM information_schema.tables WHERE table_type = 'BASE TABLE' AND table_schema = DATABASE() ORDER BY table_name;"
          else
             cCOMANDO := "SELECT table_name AS TABLE_NAME FROM information_schema.tables WHERE table_type = 'BASE TABLE' AND table_schema = '" + cOwnerx + "' ORDER BY table_name;"
          endif

       CASE cTIPOSQL == "PGSQL" .OR. cTIPOSQL == "PGSQL64" .OR. cTIPOSQL == "POSTGRESQL"
          if Empty( cOwnerx )
             cCOMANDO := "SELECT tablename AS TABLE_NAME FROM pg_tables WHERE schemaname='public' ORDER BY tablename;"
          else
             cCOMANDO := "SELECT tablename AS TABLE_NAME FROM pg_tables WHERE schemaname = '" + cOwnerx + "' ORDER BY tablename;"
          endif
          
       CASE cTIPOSQL == "MSSQL" .OR. cTIPOSQL == "SQLSERVER"
          if Empty( cOwnerx )
             cCOMANDO := "SELECT TABLE_NAME AS TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME;"
          else
             cCOMANDO := "SELECT TABLE_NAME AS TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_SCHEMA = '" + cOwnerx + "' ORDER BY TABLE_NAME;"
          endif

       CASE cTIPOSQL == "ORACLE" .OR. cTIPOSQL == "OCI" 
          if Empty( cOwnerx )
             cCOMANDO := "SELECT table_name AS TABLE_NAME FROM user_tables ORDER BY TABLE_NAME;"
          else
             cCOMANDO := "SELECT table_name AS TABLE_NAME FROM all_tables WHERE owner = '" + Upper(cOwnerx) + "' ORDER BY TABLE_NAME;"
          endif
      CASE cTIPOSQL == "DUCKDB"
         if Empty( cOwnerx )
            cCOMANDO := "SELECT table_name AS TABLE_NAME FROM duckdb_tables WHERE schema_name = 'main' ORDER BY table_name;"
         else
            cCOMANDO := "SELECT table_name AS TABLE_NAME FROM duckdb_tables WHERE schema_name = '" + Lower(cOwnerx) + "' ORDER BY table_name;"
         endif    

       CASE lFDB 
          // RDB$SYSTEM_FLAG = 0 traz apenas tabelas criadas pelo usuário (ignora tabelas do sistema do Firebird)
          // TRIM() remove espaços em branco à direita que o Firebird gera nativamente nos metadados
          if Empty( cOwnerx )
             cCOMANDO := "SELECT TRIM(RDB$RELATION_NAME) AS TABLE_NAME FROM RDB$RELATIONS WHERE COALESCE(RDB$SYSTEM_FLAG, 0) = 0 AND RDB$VIEW_BLR IS NULL ORDER BY RDB$RELATION_NAME;"
          else
             cCOMANDO := "SELECT TRIM(RDB$RELATION_NAME) AS TABLE_NAME FROM RDB$RELATIONS WHERE COALESCE(RDB$SYSTEM_FLAG, 0) = 0 AND RDB$VIEW_BLR IS NULL AND RDB$OWNER_NAME = '" + cOwnerx + "' ORDER BY RDB$RELATION_NAME;"
          endif
          
       CASE cTIPOSQL == "SYBASE"
          if Empty( cOwnerx )
             cCOMANDO := "SELECT name AS TABLE_NAME FROM sysobjects WHERE type = N'U' ORDER BY name;"
          else
             cCOMANDO := "SELECT name AS TABLE_NAME FROM sysobjects WHERE type = N'U' AND USER_NAME(uid) = '" + cOwnerx + "' ORDER BY name;"
          endif
   ENDCASE
ENDIF
IF cTIPOINFO = "ESTRUTURA"
   cCOMANDO :=DIALETO_Estrutura(cTIPOSQL,cTABELA,cOwnerx)
   /*
   DO CASE
   CASE lARQMDBACCDB  
      //Implantado abaixo com  catalogx
   CASE cTIPOSQL="INFORMIX"   
      cCOMANDO := "select t.tabname,c.colname AS FIELD_NAME,c.coltype AS FIELD_NAME,c.collength AS FIELD_LEN,c.colno " + ;
            "from systables t,syscolumns c " + ;
            "where t.tabid > 0 " + ;
            "and t.tabid = c.tabid " + ;
            "order by 1,5 " 
  
   CASE cTIPOSQL == "SQLITE" .OR. At( ".SQLITE", Upper( cdatabaseX ) ) > 0
      // PRAGMA table_info retorna: cid, name, type, notnull, dflt_value, pk
      // Como o SQLite não aceita aliases em PRAGMAs diretamente, a sua camada de dados
      // deverá ler os campos nativos do pragma ("name", "type") ou usamos uma query vazia de metadados:
      cCOMANDO := "SELECT name AS FIELD_NAME, type AS DATA_TYPE, 0 AS FIELD_LEN, 0 AS FIELD_DEC FROM pragma_table_info('" + cTabela + "');"

   CASE cTIPOSQL == "MYSQL" .OR. cTIPOSQL == "MYSQL64" .OR. cTIPOSQL == "MARIADB"
      // Em vez de SHOW COLUMNS (que gera colunas dinâmicas), usamos a information_schema para fixar os aliases
      if Empty( cOwnerx )
         cCOMANDO := "SELECT COLUMN_NAME AS FIELD_NAME, DATA_TYPE AS DATA_TYPE, " + ;
                     "COALESCE(CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION) AS FIELD_LEN, " + ;
                     "COALESCE(NUMERIC_SCALE, 0) AS FIELD_DEC " + ;
                     "FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '" + cTabela + "' AND TABLE_SCHEMA = DATABASE() ORDER BY ORDINAL_POSITION;"
      else
         cCOMANDO := "SELECT COLUMN_NAME AS FIELD_NAME, DATA_TYPE AS DATA_TYPE, " + ;
                     "COALESCE(CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION) AS FIELD_LEN, " + ;
                     "COALESCE(NUMERIC_SCALE, 0) AS FIELD_DEC " + ;
                     "FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '" + cTabela + "' AND TABLE_SCHEMA = '" + cOwnerx + "' ORDER BY ORDINAL_POSITION;"
      endif

   CASE cTIPOSQL == "PGSQL" .OR. cTIPOSQL == "PGSQL64" .OR. cTIPOSQL == "POSTGRESQL"
      // PostgreSQL diferencia maiúsculas de minúsculas. Geralmente tabelas ficam em minúsculo no Postgres.
      // udt_name ou data_type mapeados perfeitamente
       //nome tabela em maiusculo postgresql e case sensitive
      //udt_name melhor retorno mas tambem tras data_type caso necesario
      //where table_schema='public'  tras todas as tabelas do usurio(public)
   
      
      cSchema := iif( Empty(cOwnerx), "public", cOwnerx )
      cCOMANDO := "SELECT column_name AS FIELD_NAME, udt_name AS DATA_TYPE, " + ;
                  "COALESCE(character_maximum_length, numeric_precision) AS FIELD_LEN, " + ;
                  "COALESCE(numeric_scale, 0) AS FIELD_DEC " + ;
                  "FROM information_schema.columns " + ;
                  "WHERE LOWER(table_name) = '" + Lower(cTabela) + "' AND table_schema = '" + cSchema + "' " + ;
                  "ORDER BY ordinal_position;"

   CASE cTIPOSQL == "MSSQL" .OR. cTIPOSQL == "SQLSERVER"
      cSchemaSQL := iif( Empty(cOwnerx), "dbo", cOwnerx )
      cCOMANDO := "SELECT COLUMN_NAME AS FIELD_NAME, DATA_TYPE AS DATA_TYPE, " + ;
                  "ISNULL(CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION) AS FIELD_LEN, " + ;
                  "ISNULL(NUMERIC_SCALE, 0) AS FIELD_DEC " + ;
                  "FROM INFORMATION_SCHEMA.COLUMNS " + ;
                  "WHERE TABLE_NAME = '" + cTabela + "' AND TABLE_SCHEMA = '" + cSchemaSQL + "' " + ;
                  "ORDER BY ORDINAL_POSITION;"
CASE cTIPOSQL == "DUCKDB"
   cSchemaSQL := iif( Empty(cOwnerx), "main", Lower(cOwnerx) )
   cCOMANDO := "SELECT column_name AS FIELD_NAME, data_type AS DATA_TYPE, " + ;
               "column_size AS FIELD_LEN, decimal_digits AS FIELD_DEC " + ;
               "FROM duckdb_columns " + ;
               "WHERE table_name = '" + cTabela + "' AND schema_name = '" + cSchemaSQL + "' " + ;
               "ORDER BY column_index;"
   CASE cTIPOSQL == "ORACLE" .OR. cTIPOSQL == "OCI"
      cUserOracle := iif( Empty(cOwnerx), "USER_TAB_COLUMNS", "ALL_TAB_COLUMNS" )
      cCOMANDO := "SELECT COLUMN_NAME AS FIELD_NAME, DATA_TYPE AS DATA_TYPE, " + ;
                  "DATA_LENGTH AS FIELD_LEN, COALESCE(DATA_SCALE, 0) AS FIELD_DEC " + ;
                  "FROM " + cUserOracle + " WHERE TABLE_NAME = '" + Upper(cTabela) + "' " + ;
                  iif( !Empty(cOwnerx), "AND OWNER = '" + Upper(cOwnerx) + "' ", "" ) + ;
                  "ORDER BY COLUMN_ID;"

   CASE lFDB 
      // O Firebird exige um JOIN complexo no catálogo do sistema para extrair os tipos amigáveis
      cCOMANDO := "SELECT TRIM(F.RDB$FIELD_NAME) AS FIELD_NAME, " + ;
                  "CASE T.RDB$FIELD_TYPE " + ;
                  "  WHEN 7 THEN 'SMALLINT' WHEN 8 THEN 'INTEGER' WHEN 16 THEN 'BIGINT' " + ;
                  "  WHEN 10 THEN 'FLOAT' WHEN 27 THEN 'DOUBLE PRECISION' " + ;
                  "  WHEN 14 THEN 'CHAR' WHEN 37 THEN 'VARCHAR' WHEN 40 THEN 'CSTRING' " + ;
                  "  WHEN 12 THEN 'DATE' WHEN 13 THEN 'TIME' WHEN 35 THEN 'TIMESTAMP' " + ;
                  "  WHEN 261 THEN 'BLOB' END AS DATA_TYPE, " + ;
                  "T.RDB$FIELD_LENGTH AS FIELD_LEN, COALESCE(T.RDB$FIELD_SCALE, 0) * -1 AS FIELD_DEC " + ;
                  "FROM RDB$RELATION_FIELDS F " + ;
                  "JOIN RDB$FIELDS T ON F.RDB$FIELD_SOURCE = T.RDB$FIELD_NAME " + ;
                  "WHERE F.RDB$RELATION_NAME = '" + Upper(cTabela) + "' " + ;
                  "ORDER BY F.RDB$FIELD_POSITION;"
   ENDCASE
   */
ENDIF
IF cTIPOINFO = "CCAMPOSQL"
   cCOMANDO := cCAMPOSQL
ENDIF
IF cTIPOINFO = "__INDEX__"
  DO CASE
   CASE cTIPOSQL == "MYSQL" .OR. cTIPOSQL == "MYSQL64" .OR. cTIPOSQL == "MARIADB"
      // Em vez de SHOW INDEXES (que dificulta aliases), usamos a STATISTICS da information_schema
      cSchemaMY := iif( Empty(cOwnerx), "DATABASE()", "'" + cOwnerx + "'" )
      cCOMANDO := "SELECT INDEX_NAME AS INDEX_NAME, COLUMN_NAME AS COLUMN_NAME " + ;
                  "FROM INFORMATION_SCHEMA.STATISTICS " + ;
                  "WHERE TABLE_NAME = '" + cTabela + "' AND TABLE_SCHEMA = " + cSchemaMY + " " + ;
                  "ORDER BY INDEX_NAME, SEQ_IN_INDEX;"

   CASE cTIPOSQL == "PGSQL" .OR. cTIPOSQL == "PGSQL64" .OR. cTIPOSQL == "POSTGRESQL"
      // No Postgres precisamos cruzar o catálogo interno para extrair os nomes das colunas de forma ordenada
      cSchemaPG := iif( Empty(cOwnerx), "public", cOwnerx )
      cCOMANDO := "SELECT t.relname AS INDEX_NAME, a.attname AS COLUMN_NAME " + ;
                  "FROM pg_class t " + ;
                  "JOIN pg_index ix ON t.oid = ix.indexrelid " + ;
                  "JOIN pg_class i ON i.oid = ix.indrelid " + ;
                  "JOIN pg_attribute a ON a.attrelid = t.oid " + ;
                  "JOIN pg_namespace n ON n.oid = i.relnamespace " + ;
                  "WHERE LOWER(i.relname) = '" + Lower(cTabela) + "' AND n.nspname = '" + cSchemaPG + "' " + ;
                  "ORDER BY t.relname, a.attnum;"
   CASE cTIPOSQL == "DUCKDB"
      cSchemaDK := iif( Empty(cOwnerx), "main", Lower(cOwnerx) )
      cCOMANDO := "SELECT index_name AS INDEX_NAME, expressions AS COLUMN_NAME " + ;
                  "FROM duckdb_indexes " + ;
                  "WHERE table_name = '" + cTabela + "' AND schema_name = '" + cSchemaDK + "' " + ;
                  "ORDER BY index_name;"               

   CASE cTIPOSQL == "MSSQL" .OR. cTIPOSQL == "SQLSERVER"
      // Consulta padrão na sys.indexes do SQL Server
      cCOMANDO := "SELECT ind.name AS INDEX_NAME, col.name AS COLUMN_NAME " + ;
                  "FROM sys.indexes ind " + ;
                  "JOIN sys.index_columns ic ON ind.object_id = ic.object_id AND ind.index_id = ic.index_id " + ;
                  "JOIN sys.columns col ON ic.object_id = col.object_id AND ic.column_id = col.column_id " + ;
                  "JOIN sys.tables t ON ind.object_id = t.object_id " + ;
                  "WHERE t.name = '" + cTabela + "' AND ind.is_primary_key = 0 " + ;
                  "ORDER BY ind.name, ic.key_ordinal;"

   CASE cTIPOSQL == "SQLITE" .OR. At( ".SQLITE", Upper( cdatabaseX ) ) > 0
      // Nota: O SQLite exige comandos em lote ou PRAGMA. Para leitura via Recordset genérico, 
      // o mais seguro é ler os metadados diretamente da tabela sqlite_master caso queira a query pura,
      // mas o comando pragma nativo é: "PRAGMA index_list('" + cTabela + "')"
      cCOMANDO := "SELECT name AS INDEX_NAME, '' AS COLUMN_NAME FROM sqlite_master WHERE type='index' AND tbl_name='" + cTabela + "';"
   ENDCASE
ENDIF
IF cTIPOINFO = "__VERSION__"
   cCOMANDO :=Dialeto_Version()
ENDIF


lopen := .f.
IF (cTIPOINFO = "ESTRUTURA" .OR. cTIPOINFO = "__INDEX__") .AND. lARQMDBACCDB
   //abaixo com catalog
ELSE
   TRY
   oRS:Open(cCOMANDO,oConN,adOpenDynamic,adLockOptimistic)
   lOPEN := .T.
   CATCH oERR
   lOPEN := .F.
   IF lARQMDBACCDB .AND. cTIPOINFO = "TABELA"
      //erro permisao acesso mysy
      EXECUTACMD(cdatabase,"GRANT SELECT ON TABLE MSysObjects TO ADMIN,PUBLIC")
      EXECUTACMD(cdatabase,"create view showtables as select name from MSysObjects where MSysObjects.type In (1,4,6) and MSysObjects.name not like '~*' and MSysObjects.name not like 'MSys%'")
   ELSE
      ShowADOError(oERR,oConn,cCOMANDO)
   ENDIF
END
ENDIF


/* a vezes e preciso conceder este acesso na ide para a consulta na retornar vazia
cCOMANDO:="GRANT SELECT ON TABLE MSysObjects TO ADMIN,PUBLIC" 

create view showtables as select name from MSysObjects where MSysObjects.type In (1,4,6) and MSysObjects.name not like '~*' and MSysObjects.name not like 'MSys%' 
//nao aceita order by na criacao da view
*/


IF lOPEN
   while !ors:eof
      IF cTIPOINFO = "TABELA" .OR. cTIPOINFO = "CCAMPOSQL" .OR. cTIPOINFO = "DATABASE" .OR. cTIPOINFO = "__VERSION__"
         AADD(aRETU,ors:fields(0) :value)   //ors:fields(0) inicia as colunas com zero ou pelo nome da coluna fields("name")
      ENDIF
      IF cTIPOINFO = "ESTRUTURA"
        
         cFieldName   := ''
         cFieldType   := ''
         nFieldLength := 0
         nFieldDec    := 0
         eDEFAULT     := ''
         nNotNull     := 0

         // Como a nossa 'Dialeto_ShowColumns()' padronizou o retorno usando ALIASES ("AS ..."),
         // não precisamos mais de um CASE para separar a leitura dos campos por banco!
         // Todos os SGBDs agora devolvem as mesmas colunas textuais em 'ors'.
         
         TRY
            // Captura segura por nome do alias unificado
            cFieldName   := Upper(AllTrim( hb_valToStr(ors:Fields("FIELD_NAME"):Value) ))
            cFieldType   := Upper(AllTrim( hb_valToStr(ors:Fields("DATA_TYPE"):Value) ))
            nFieldLength := fixnum( ors:Fields("FIELD_LEN"):Value )
            nFieldDec    := fixnum( ors:Fields("FIELD_DEC"):Value )
         CATCH
            // Tratamento de contingência para o SQLite antigo (caso o PRAGMA nativo ignore aliases)
            IF cTIPOSQL == "SQLITE" .OR. At(".SQLITE", Upper(cdatabase)) > 0
               TRY
                  cFieldName   := Upper(AllTrim( hb_valToStr(ors:Fields("name"):Value) ))
                  cFieldType   := Upper(AllTrim( hb_valToStr(ors:Fields("type"):Value) ))
                  nFieldLength := 0
                  nFieldDec    := 0
               CATCH
                  cFieldName   := ""
               END
            ENDIF
         END

         // Se o metadado for válido, adiciona ao array de retorno estruturado para o DBF
         IF !Empty(cFieldName)
            AADD(aRETU, geracampodbf(cFieldName, cFieldType, nFieldLength, nFieldDec))
         ENDIF

      ENDIF
      IF cTIPOINFO = "__INDEX__"
        cCHAVENAME  := ""
        cCHAVECAMPO := ""

           // Graças aos aliases fixos da Dialeto_ShowIndexes(), 
           // NÃO precisamos mais separar a leitura por "CASE cTIPOSQL" !
           TRY
              cCHAVENAME  := Upper(AllTrim( hb_valToStr(ors:Fields("INDEX_NAME"):Value) ))
              cCHAVECAMPO := Upper(AllTrim( hb_valToStr(ors:Fields("COLUMN_NAME"):Value) ))
           CATCH
              // Contingência para o SQLite se o driver do PRAGMA nativo for utilizado diretamente
              IF cTIPOSQL == "SQLITE" .OR. At(".SQLITE", Upper(cdatabase)) > 0
                 TRY
                    cCHAVENAME  := Upper(AllTrim( hb_valToStr(ors:Fields("name"):Value) ))
                    cCHAVECAMPO := "" // Índices do SQLite puro exigem um segundo passo (index_info) se lidos via pragma nativo
                 CATCH
                    cCHAVENAME  := ""
                 END
              ENDIF
           END

           // Se capturou um índice válido, adiciona ao array de retorno do Harbour
           IF !Empty(cCHAVENAME)
              // Retorna o par { Nome_Do_Indice, Coluna_Do_Banco }
              AADD(aRETU, { cCHAVENAME, cCHAVECAMPO })
           ENDIF



      ENDIF


      ors:movenext()
   enddo
   oRs:Close()
ENDIF


if LEN(aRETU) = 0 .AND. cTIPOINFO = "TABELA"
   //necessario nova conecaro
   //nao funcionou criando olecreate adox.catalog
   IF lARQMDBACCDB  
      oXConection := win_oleCreateObject("ADODB.Connection")
      oXConection:Open(CCONN)
      oXCatalog := oXConection:OpenSchema(adSchemaTables)
      do while .not. oXCatalog:EOF()
         cTABELA := upper(alltrim(oXCatalog:Fields("TABLE_NAME") :Value))
         IF SUBSTR(cTABELA,1,4) <> "MSYS"
            AADD(aRETU,cTABELA)
         ENDIF
         oXCatalog:MoveNext()
      enddo
   ENDIF
endif

if LEN(aRETU) = 0 .AND. cTIPOINFO = "ESTRUTURA"
   IF lARQMDBACCDB  
      //nao funcionou criando olecreate adox.catalog
      //necessario nova conecaro
      oXConection := win_oleCreateObject("ADODB.Connection")
      oXConection:Open(CCONN)
      oXCatalog := oXConection:OpenSchema(adSchemaColumns)
      do while .not. oXCatalog:EOF()
         IF UPPER(cTABELA) = UPPER(oXcatalog:Fields("TABLE_NAME") :Value)
            cFieldName   := UPPER(oXcatalog:Fields("COLUMN_NAME") :Value)
            cFieldType   := TipoDado2(oXcatalog:Fields("DATA_TYPE") :Value)
            nFieldLength := 0
            nFieldDec    := 0
            If cFieldType = "C"
               nFieldLength := oXcatalog:Fields("CHARACTER_MAXIMUM_LENGTH") :Value
               IF nFieldLength > 250
                  nFieldLength := 250
               ENDIF
               IF nFieldLength = 0  //alguns long var estao trazendo 0
                  nFieldLength := 250
               ENDIF
            ENDIF
            If cFieldType = "N"
               nFieldLength := oXcatalog:Fields("NUMERIC_PRECISION") :Value
               nFieldDec    := oXcatalog:Fields("NUMERIC_SCALE") :Value
            ENDIF
            If cFieldType = "D"
               nFieldLength := oXcatalog:Fields("DATETIME_PRECISION") :Value
            ENDIF
            If cFieldType = "L"
               nFieldLength := 1
            ENDIF
            IF oXcatalog:Fields("DATA_TYPE") :Value = 5   // adDouble   5
               IF nFieldDec = 0
                  nFieldDec := 5  //Coloca 5 como decimal
               ENDIF
            ENDIF
            nFieldLength := FIXINT(nFieldLength)
            nFieldDec    := FIXINT(nFieldDec)
            AADD(aRETU,geracampodbf(cFieldName,cFieldType,nFieldLength,nFieldDec))
         ENDIF
         oXcatalog:movenext()
      enddo
   ENDIF
endif


if LEN(aRETU) = 0 .AND. cTIPOINFO = "__INDEX__"
   IF lARQMDBACCDB  
      //nao funcionou criando olecreate adox.catalog
      //necessario nova conecaro
      oXConection := win_oleCreateObject("ADODB.Connection")
      oXConection:Open(CCONN)
      oXCatalog := oXConection:OpenSchema(adSchemaIndexes)
      do while .not. oXCatalog:EOF()
         IF UPPER(cTABELA) = UPPER(oXcatalog:Fields("TABLE_NAME") :Value)
            cCHAVENAME  := UPPER(oXcatalog:Fields("INDEX_NAME") :Value)
            cCHAVECAMPO := UPPER(oXcatalog:Fields("COLUMN_NAME") :Value)
            //PRIMARY_KEY
            AADD(aRETU,{cCHAVENAME,cCHAVECAMPO})
         ENDIF
         oXcatalog:movenext()
      enddo
   ENDIF
endif

TRY
oConN:close()
END
RETURN aRETU


//TIPOC     tras o descritivo caracter data numeric...(em dbudoc)
//tipodado2 pega o tipo numerico do ado e convert para o tipo dbf padrao CNMDL
// Adotipodbf( nADOFieldType,nTIPORETORNO )
//numerico ado para nTIPORETRONO=1 numerico dbf, =2 tipo caracter exetendio(inclui double,ole...) =3 tuoos Basicos CMDLN

//pega o tipo numerico do ado e convert para o tipo dbf padrao CNMDL

*+--------------------------------------------------------------------
*+
*+
*+
*+    Function TipoDado2()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
Function TipoDado2(nTipo)

do case
case nTipo = 8 .or. nTipo = 12 .or. nTipo = 72 .or. nTipo = 129 .or. nTipo = 130 .or. (nTipo >= 200 .and. nTipo <= 203)
   // adBSTR             8
   // adGUID             72
   // adChar             129
   // adWChar            130
   // adVarChar          200
   // adLongVarChar      201
   // adVarWChar         202
   // adLongVarWChar     203
   return 'C'

case nTipo = 17 .or. nTipo = 16 .or. nTipo = 14 .or. nTipo = 5 .or. nTipo = 3 .or. nTipo = 131 .or. nTipo = 2 .or. nTipo = 6 .or. ;
    nTipo = 4 .or. nTipo = 020 .or. nTipo = 018 .or. nTipo = 019 .or. nTipo = 21 .or. nTipo = 138 .or. nTipo = 139
   // adSmallInt         2
   // adInteger          3
   // adSingle           4
   // adDouble           5
   // adCurrency         6
   // adDecimal          14
   // adTinyInt          16
   // adUnsignedTinyInt  17
   // adUnsignedSmallInt 18
   // adUnsignedInt      19
   // adBigInt           20
   // adUnsignedBigInt   21
   // adNumeric          131
   // adPropVariant      138
   // adVarNumeric       139
   return 'N'   // Numerico

case nTipo = 7 .or. nTipo = 64 .or. nTipo = 133 .or. nTipo = 134 .or. nTipo = 135
   // adDate             7
   // adFileTime         64
   // adDBDate           133
   // adDBTime           134
   // adDBTimeStamp      135
   return 'D'   // Data

case nTipo = 11
   // adBoolean          11
   return 'L'   // Logico

case nTipo = 128 .or. nTipo = 201 .or. nTipo = 203 .or. nTipo = 205
   // adLongVarWChar     203
   // adPropVariant      138
   return 'M'   // Memo

case nTipo = 128 .or. nTipo = 204 .or. nTipo = 205
   // adBinary           128
   // adVarBinary        204
   // adLongVarBinary    205
   return 'G'   // Imagem HB_FT_OLE

otherwise
   alert('Tipo de dado invalido: Campo '+cField+' Type='+str(nTipo))
endcase
return 'U'



//numerico ado para nTIPORETRONO=1 numerico dbf, =2 tipo caracter extendido(inclui double,ole...) =3 typos Basicos CMDLN

*+--------------------------------------------------------------------
*+
*+
*+
*+    Function Adotipodbf()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
function Adotipodbf(nADOFieldType,nTIPORETORNO)

//HB_FT_PICTURE ="P" sem equivalente ado harbour
//adarray nao padrao rdd harbour conta na adox e na adordd

LOCAL nDBFFieldType := 0
LOCAL cDBFFieldType := ""

IF nTIPORETORNO = 3
   RETURN TipoDado2(nADOFieldType)
ENDIF


DO CASE

CASE nADOFieldType == adEmpty
CASE nADOFieldType == adTinyInt
   nDBFFieldType := HB_FT_INTEGER
   cDBFFieldType := "I"

CASE nADOFieldType == adSmallInt
   nDBFFieldType := HB_FT_INTEGER
   cDBFFieldType := "I"

CASE nADOFieldType == adInteger
   nDBFFieldType := HB_FT_INTEGER
   cDBFFieldType := "I"

CASE nADOFieldType == adBigInt
   nDBFFieldType := HB_FT_INTEGER
   cDBFFieldType := "I"

CASE nADOFieldType == adUnsignedTinyInt
CASE nADOFieldType == adUnsignedSmallInt
CASE nADOFieldType == adUnsignedInt
CASE nADOFieldType == adUnsignedBigInt
CASE nADOFieldType == adSingle

CASE nADOFieldType == adDouble
   nDBFFieldType := HB_FT_DOUBLE
   cDBFFieldType := "B"

CASE nADOFieldType == adCurrency
   nDBFFieldType := HB_FT_INTEGER
   cDBFFieldType := "I"

CASE nADOFieldType == adDecimal
   nDBFFieldType := HB_FT_LONG
   cDBFFieldType := "N"

CASE nADOFieldType == adNumeric
   nDBFFieldType := HB_FT_LONG
   cDBFFieldType := "N"

CASE nADOFieldType == adError
CASE nADOFieldType == adUserDefined
CASE nADOFieldType == adVariant
   nDBFFieldType := HB_FT_ANY
   cDBFFieldType := "V"

CASE nADOFieldType == adIDispatch

CASE nADOFieldType == adIUnknown

CASE nADOFieldType == adGUID
   nDBFFieldType := HB_FT_STRING
   cDBFFieldType := "C"

CASE nADOFieldType == adDate
   nDBFFieldType := HB_FT_DATE
   cDBFFieldType := "D"

CASE nADOFieldType == adDBDate
   nDBFFieldType := HB_FT_DATE
   cDBFFieldType := "D"

CASE nADOFieldType == adDBTime

CASE nADOFieldType == adDBTimeStamp
   nDBFFieldType := HB_FT_TIMESTAMP
   cDBFFieldType := "@"

CASE nADOFieldType == adFileTime
   nDBFFieldType := HB_FT_DATETIME
   cDBFFieldType := "T"

CASE nADOFieldType == adBSTR
   nDBFFieldType := HB_FT_STRING
   cDBFFieldType := "C"

CASE nADOFieldType == adChar
   nDBFFieldType := HB_FT_STRING
   cDBFFieldType := "C"

CASE nADOFieldType == adVarChar
   nDBFFieldType := HB_FT_STRING
   cDBFFieldType := "C"

CASE nADOFieldType == adLongVarChar
   nDBFFieldType := HB_FT_STRING
   cDBFFieldType := "C"

CASE nADOFieldType == adWChar
   nDBFFieldType := HB_FT_STRING
   cDBFFieldType := "C"

CASE nADOFieldType == adVarWChar
   nDBFFieldType := HB_FT_STRING
   cDBFFieldType := "C"

CASE nADOFieldType == adBinary
   nDBFFieldType := HB_FT_OLE
   cDBFFieldType := "G"

CASE nADOFieldType == adVarBinary
   nDBFFieldType := HB_FT_OLE
   cDBFFieldType := "G"

CASE nADOFieldType == adLongVarBinary
   nDBFFieldType := HB_FT_OLE
   cDBFFieldType := "G"

CASE nADOFieldType == adChapter

CASE nADOFieldType == adVarNumeric

   // CASE nADOFieldType == adArray


CASE nADOFieldType == adBoolean
   nDBFFieldType := HB_FT_LOGICAL
   cDBFFieldType := "L"

CASE nADOFieldType == adLongVarWChar
   nDBFFieldType := HB_FT_MEMO
   cDBFFieldType := "M"

CASE nADOFieldType == adPropVariant
   nDBFFieldType := HB_FT_MEMO
   cDBFFieldType := "M"

ENDCASE

RETURN if(nTIPORETORNO = 1,nDBFFieldType,cDBFFieldType)




*+--------------------------------------------------------------------
*+
*+    Function geraconn(cCAMBASE,lPROVIDER,StrUsuario,StrSenha,StrServer,StrPort)
*+
*+--------------------------------------------------------------------
*+
FUNCTION geraconn(cCAMBASE,lPROVIDER,StrUsuario,StrSenha,StrServer,StrPort)

LOCAL cCONN
LOCAL cSQLUSER
LOCAL cCAMDIR
cConn    := ""
cSQLUSER := ""
IF VALTYPE(cCAMBASE) <> "C"   //ser for database nao tem caminho usa cservex
   cCAMBASE := ""   //atribui vazio
ENDIF
IF vALTYPE(lPROVIDER) <> "L"
   lPROVIDER := .T.
ENDIF

    cCAMDIR := hb_FNameDir( cCAMBASE ) 
    IF Right( AllTrim( cCAMDIR ), 1 ) != "\" .AND. Right( AllTrim( cCAMDIR ), 1 ) != "/"
      cCAMDIR += "\"
   ENDIF

   IF ! EMPTY (cBANCOX)
      buscachaves( cBANCOX )
   ENDIF

   IF Empty( cUSERX ) .and. ! empty(StrUsuario)
      cUSERX := StrUsuario
   ENDIF

   IF Empty( cPASSX ) .and. ! empty(StrSenha)
      cPASSX := StrSenha
   ENDIF
   
   IF Empty( cSERVERX ) .and. ! empty(StrServer)
      cSERVERX := StrServer
   ENDIF

   IF Empty( cPORTAX ) .and. ! empty(StrPort)
      cPORTAX := StrPort
   ENDIF


DO CASE
  CASE cTIPOMIX = "ODBC"  .AND. cTIPODBC =  "DSN"    
       cCONN:="Provider=MSDASQL;Data Source="+cBANCOX+";" //Uid=admin;Pwd=secret;"


CASE lMDB .OR. at(".MDB",upper(cCAMBASE)) > 0   
   if loledb  // provider ou driver que fixa o nome independente da versao do access sqlmix(usa driver) adordd(use provider)
      IF lPROVIDER
         cConn := "Provider=Microsoft.Jet.OLEDB.4.0;Data Source="+cCAMBASE+";Mode=Share Deny None"  //32 bit jet oledb
      ELSE
         cCONN := "Driver={Microsoft Access Driver (*.mdb)};Dbq="+cDATABASEX+";Mode=Share Deny None"
      ENDIF
   else
      IF lPROVIDER
         cConn := "Provider=Microsoft.ACE.OLEDB.12.0;Data Source="+cCAMBASE+";Mode=Share Deny None"   //64 bit ace oledb
      ELSE
         cCONN := "Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq="+cDATABASEX+";Mode=Share Deny None"
      ENDIF
   endif

CASE Laccdb .or. at(".ACCDB",upper(cCAMBASE)) > 0   
   //provider ou driver que fixa o nome independente da versao do access sqlmix(usa driver) adordd(use provider)
   IF lPROVIDER
      cConn := "Provider=Microsoft.ACE.OLEDB.12.0;Data Source="+cCAMBASE+";Mode=Share Deny None"  //driver 32 e 64 devem estar instalados
   ELSE
      cCONN := "Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq="+cDATABASEX+";Mode=Share Deny None"
   ENDIF
CASE cTIPOSQL = "SQLITE" .or. at(".SQLITE",upper(cCAMBASE)) > 0
   cConn := "Driver={SQLite3 ODBC Driver};Database="+cCAMBASE+";"   //mesmo nome de driver para 32 e 64 ambos devem estar instaldos
   
CASE cTIPOSQL = "DUCKDB" 
   cConn := "Driver={DuckDB Driver};Database="+cCAMBASE+";"   //mesmo nome de driver para 32 e 64 ambos devem estar instaldos
   
   
   

CASE cTIPOSQL = "MYSQL" .OR. cTIPOSQL = "MYSQL64"
   if empty(cDATABASEX)
      if loledb
         cConn := "Driver={MySQL ODBC 8.0 ANSI Driver};Server="+cSERVERX+";Uid="+CUSERX+";Pwd="+cPASSX+";"  //32 driver versao 8
      else
         cConn := "Driver={MySQL ODBC 9.0 ANSI Driver};Server="+cSERVERX+";Uid="+CUSERX+";Pwd="+cPASSX+";"  //64 driver versao 9
      endif
   else
      if loledb
         cConn := "Driver={MySQL ODBC 8.0 ANSI Driver};Server="+cSERVERX+";Database="+cDATABASEX+";Uid="+CUSERX+";Pwd="+cPASSX+";"  //32 driver versao 8
      else
         cConn := "Driver={MySQL ODBC 9.0 ANSI Driver};Server="+cSERVERX+";Database="+cDATABASEX+";Uid="+CUSERX+";Pwd="+cPASSX+";"  //64 driver versao 9
      endif
   endif
case cTIPOSQL = "MARIADB"   //mesmo nome de driver para 32 e 64 ambos devem estar instaldos
   if empty(cDATABASEX)
      cConn := "DRIVER={MariaDB ODBC 3.2 Driver};SERVER="+cSERVERX+";UID="+cUSERX+";PASSWORD="+cPASSX
   else
      cConn := "DRIVER={MariaDB ODBC 3.2 Driver};DATABASE="+cDATABASEX+";SERVER="+cSERVERX+";UID="+cUSERX+";PASSWORD="+cPASSX
   endif
case cTIPOSQL = "PGSQL" .OR. cTIPOSQL = "PGSQL64" .OR. cTIPOSQL = "POSTGRESQL"
   //Driver={PostgreSQL ANSI};Server=IP address;Port=5432;Database=myDataBase;Uid=myUsername;Pwd=myPassword;
   if empty(cDATABASEX)
      if loledb
         cConn := "DRIVER={PostgreSQL ANSI};Server="+cSERVERX+";Uid="+cUSERX+";Pwd="+cPASSX +"; ConnSettings=SET client_encoding TO 'WIN1252';"  //+";pqopt={search_path=myschema,public}" //32 driver versao
      else
         cConn := "DRIVER={PostgreSQL ANSI(x64)};Server="+cSERVERX+";Uid="+cUSERX+";Pwd="+cPASSX +"; ConnSettings=SET client_encoding TO 'WIN1252';" //+";pqopt={search_path=myschema,public}"  //64 driver versao x64
      endif
   else
      if loledb
         cConn := "DRIVER={PostgreSQL ANSI};Database="+cDATABASEX+";Server="+cSERVERX+";Uid="+cUSERX+";Pwd="+cPASSX +"; ConnSettings=SET client_encoding TO 'WIN1252';"  //+";pqopt={search_path=myschema,public}"  //32 driver versao
      else
         cConn := "DRIVER={PostgreSQL ANSI(x64)};Database="+cDATABASEX+";Server="+cSERVERX+";Uid="+cUSERX+";Pwd="+cPASSX +"; ConnSettings=SET client_encoding TO 'WIN1252';" //+";pqopt={search_path=myschema,public}" //64 driver versao 964
      endif
   endif
CASE cTIPOSQL = "MSSQL" .OR. cTIPOSQL = "SQLSERVER" .OR. cTIPOSQL = "SQL"
   IF EMPTY(cUSERX)
      cSQLUSER := "; Trusted_Connection=True;"
   ELSE
      cSQLUSER := "; Uid="+cUSERX+"; Pwd="+cPASSX+";"
   ENDIF
   if empty(cDATABASEX)
      IF lPROVIDER
         cCONN := "Provider=SQLOLEDB;Server="+cSERVERX+";Database="+cDATABASEX+cSQLUSER
      ELSE
         cCONN := "Driver={SQL Server};Server="+cSERVERX+";Database="+cDATABASEX+cSQLUSER
      ENDIF
   else
      IF lPROVIDER
         cCONN := "Provider=SQLOLEDB;Server="+cSERVERX+cSQLUSER
      ELSE
         cCONN := "Driver={SQL Server};Server="+cSERVERX+cSQLUSER
      ENDIF
   endif
CASE cTIPOSQL = "JETFOX"
   cCONN = "Provider=VFPOLEDB.1;Data Source=" + cCAMDIR + ";Mode=ReadWrite|Share Deny None;Persist Security Info=False;Collating Sequence=MACHINE;DELETED=True;"  //'NULL=NO"
CASE cTIPOSQL = "DBASE"
   cCONN := "Provider=Microsoft.Jet.OLEDB.4.0;Data Source="+cCAMDIR+";Extended Properties=dBASE IV;"
CASE lFDB 
   //altd()
   IF EMPTY(cUSERX)
      cUSERX:="SYSDBA"
   ENDIF
    IF EMPTY(cPASSX)
      cPASSX:="masterkey"
   ENDIF
   cUSERX:=ALLTRIM(cUSERX)
   cPASSX:=ALLTRIM(CPASSX)
   IF EMPTY(cCAMBASE)
      cCONN := "DRIVER={"+DriverFirebird()+"};UID="+cUSERX+"; PWD="+cPASSX
   ELSE
      cCONN := "DRIVER={"+DriverFirebird()+"};UID="+cUSERX+"; PWD="+cPASSX+"; DBNAME="+cCAMBASE
   ENDIF
   //alert(cCONN)   
   //memowrit("connn.txt",cCONN)
CASE cTIPOSQL = "PARADOX"   // ADOPX
   cCONN := "Provider=Microsoft.Jet.OLEDB.4.0;Data Source="+cCAMDIR+";Extended Properties=Paradox 5.x;"
CASE cTIPOSQL == "XMLDB"  // ADOXML
   cCONN := "Provider=MSPersist"
CASE cTIPOSQL == "XML"  // ADOXML
   cCONN := "Provider=MSDAOSP;Data Source="+cCAMBASE+";"  //MSXML2.DSOControl.2.6"
CASE cTIPOSQL = "XLS"   // ADOXLS
   cCONN := "Provider=Microsoft.Jet.OLEDB.4.0;Data Source="+cCAMBASE+";Extended Properties=Excel 8.0;HDR=Yes;IMEX=1"
CASE cTIPOSQL = "REMOTE"  // ADORDS
   cCONN := "Provider=MS Remote;Remote Provider=Microsoft.Jet.OLEDB.4.0;Data Source="+cDATABASEX+";Remote Server="+cSERVERX
Case cTIPOSQL = "ORACLE" .OR. cTIPOSQL = "OCI"
   cSQLUSER := ";User ID="+cUSERX+";Password="+cPASSX
   IF lPROVIDER
      cCONN := "Provider=MSDAORA.1;Persist Security Info=False;Data source="+cDATABASEX+cSQLUSER
   ELSE
      cCONN := "DRIVER={Microsoft ODBC For Oracle};SERVER="+cSERVERX+"; UID= "+cUSERX+";PWD="+cPASSX
   ENDIF
   //Provider=OraOLEDB.Oracle.1;Persist Security Info=False;User ID=someuser;Data Source=someserver;
   //"Provider=OraOLEDB.Oracle;dbq=localhost:1521/XE;Database=myDataBase;", User, Pass
   //"Provider=MSDAORA.1;Password=[pwd];User ID=[schema name];Data Source=[db name];Persist Security Info=True")
ENDCASE
RETURN cConn


*+--------------------------------------------------------------------
*+
*+    Function executacmd()
*+
*+--------------------------------------------------------------------
*+
Function executacmd(cCAMBASE,eCOMANDO)

LOCAL cCHAVEV
LOCAL cConn
LOCAL aCOMANDOS := {}
LOCAL nFIM
LOCAL cCOMANDO  := ""
local i

//Gera array para casos sejam mutilplos comando em uma matriz
//evitando abrir e fechar a conecao para comando em sequencia
IF VALTYPE(eCOMANDO) = "C"
   AAdd(aCOMANDOS,eCOMANDO)
ELSE
   aCOMANDOS := eCOMANDO
ENDIF
nFIM := LEN(aCOMANDOS)

cCHAVEV := ""
cConn   := geraconn(cCAMBASE)

IF EMPTY(cConn)
   return .f.
endif

try
oConn := WIN_OLECreateObject("ADODB.Connection")
with object oConn
:ConnectionString := cConn
:Open()
END   //end do with
catch oErr
ShowAdoError(oERR,oCoNn)
return .f.
end

try
oComm := WIN_OLECreateObject("ADODB.Command")
catch oErr
ShowAdoError(oERR,oCoNn)
return .f.
end

for i := 1 to nfim
   cCOMANDO := aCOMANDOS[I]
   IF .NOT. EMPTY(cCOMANDO)
      try
      with object oComm
      :CommandText      := cCOMANDO
      :CommandType      := adCmdText
      :ActiveConnection := oConn
      :Execute()
   end
end
ENDIF
next i
oConn:Close()
oConn := NIL
RETURN .t.

*+--------------------------------------------------------------------
*+
*+    Function CreateAccessDatabase(cDatabase, cUserName, cPassword, lEncrypt)
*+
*+--------------------------------------------------------------------
*+

FUNCTION CreateAccessDatabase(cDatabase, cUserName, cPassword, lEncrypt)

    LOCAL oCatalog
    LOCAL cEXTENSAO, cDIRETORIO, cNAME

    cNAME      := ""
    cEXTENSAO  := ""
    cDIRETORIO := ""

    hb_FNameSplit(cDatabase, @cDIRETORIO, @cName, @cEXTENSAO)
    cEXTENSAO := LOWER(cEXTENSAO)

    // Ajustes de segurança conforme sua lógica original 
    IIF(cPassword == NIL, cPassword := "''", NIL)
    IIF(lEncrypt == NIL, lEncrypt := .F., NIL)

    // Bloco isolado para tratar a criação do objeto COM [cite: 5, 20]
    TRY
        oCatalog := CreateObject("ADOX.Catalog.2.8") 
    CATCH
        // Fallback caso a versão 2.8 não esteja registrada
        TRY
            oCatalog := CreateObject("ADOX.Catalog")
        CATCH
            ? "Erro: Classe ADOX.Catalog não registrada no sistema."
            RETURN NIL
        END
    END

    IF ! hb_FileExists(cDatabase)
       DO CASE
          CASE lACCDB .OR. cEXTENSAO == ".accdb"
             oCatalog:Create("Provider=Microsoft.ACE.OLEDB.12.0;" + ;
              "Data Source=" + cDatabase + ";" + ;
              "JET OLEDB:Engine Type=6;")

          CASE lMDB .OR. cEXTENSAO == ".mdb"
             IF loledb // 32 bits mdb [cite: 23]
                oCatalog:Create("Provider=Microsoft.Jet.OLEDB.4.0;" + ;
                 "Data Source=" + cDatabase + ";" + ;
                 "JET OLEDB:Engine Type=5;") 
             ELSE
                oCatalog:Create("Provider=Microsoft.ACE.OLEDB.12.0;" + ;
                 "Data Source=" + cDatabase + ";" + ;
                 "JET OLEDB:Engine Type=5;") 
             ENDIF

          CASE cTIPOSQL = "SQLITE" .OR. cEXTENSAO == ".sqlite" .OR. cEXTENSAO == ".sqlite3" .OR. cEXTENSAO == ".fossil" .OR. cEXTENSAO == ".db3"
             oCatalog:Create("DRIVER=SQLite3 ODBC Driver;Database=" + cDatabase) 

          CASE cTIPOSQL = "XLS" .OR. cEXTENSAO == ".xls"
             oCatalog:Create("Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" + cDatabase + ";Extended Properties='Excel 8.0;HDR=YES';Persist Security Info=False") 

          CASE cEXTENSAO == ".db" .OR. cTIPOSQL == "PARADOX"
             //nao funciona catalog e a paradoxcreatetable precisas da estrutura(nao cria vazia)

         /* o driver nao suporta catalogo
          CASE cEXTENSAO == ".fdb" .OR. cEXTENSAO == ".gdb" .OR. cEXTENSAO == ".ib" .OR. lFDB 
               cConn := "DRIVER={" + DriverFirebird() + "};" + ;
               "Uid=SYSDBA;" + ;
               "Pwd=masterkey;" + ;
               "DbName=" + AllTrim(cDatabase) + ";" + ;
               "CHARSET=ISO8859_1;" + ; // Define o Character Set
              "DIALECT=3;"        // Define o Dialeto (sempre use 3 para Firebird moderno)
              oCatalog:Create(cConn)
          */    
       ENDCASE
    ENDIF

    oCatalog := NIL
    RETURN NIL



*+--------------------------------------------------------------------
*+
*+    Function mdltodos()
*+
*+--------------------------------------------------------------------
*+

function mdltodos(cPASTA)

IF EMPTY(CPASTA)
  cPASTA:=SelectFolder()
ENDIF
/* aqui e dbf para md dbml porem geradbml suporta mdb accdb sqlite
IF ! EMPTY(cPASTA)
   DO CASE
      CASE llMDB
           cPASTA+="\*.MDB"
      CASE llACCDB
           cPASTA+="\*.ACCDB"
      OTHERWISE
           cPASTA+="\*."+TABLEEXT
   ENDCASE
ENDIF
*/
cPASTA+="\*."+TABLEEXT
GeraMDdbml(cPASTA)
RETURN .T.

*+--------------------------------------------------------------------
*+
*+    Function sqltodos(cTIPOSQL)
*+
*+--------------------------------------------------------------------
*+

function sqltodos(cTIPOSQL,cPASTA)
IF EMPTY(CPASTA)
   cPASTA:=SelectFolder()
ENDIF   
IF ! EMPTY(cPASTA)
   cPASTA+="\*."+TABLEEXT
ENDIF
cTEXTO:=""
//FAZERDBF(bUSO                                                           , lSHARE[.F.] , bPRE, bPOS, cMASK["*."+TABLEEXT],LOPEN[.T.])
FAZERDBF( {|| cTEXTO+=FormataBlocoSql(SqliteCreateTable( , , cTIPOSQL,.T.,.T. )) }, .F. ,     ,     ,cPASTA)
hb_MemoWrit(cTIPOSQL+".sql", cTEXTO ) 
RETURN .T.


*+ EOF: mdb2dbf.prg
*+
