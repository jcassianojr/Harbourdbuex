*+--------------------------------------------------------------------
*+
*+    Programa  : dbulib.prg
*+
*+     Sistema:
*+     Linguagem: Harbour
*+     Autor: jcassiano
*+     Copyright (c) 2024,  jcassiano
*+
*+    Documentado em 28-Dez-2024 as 10:07 am
*+
*+--------------------------------------------------------------------
*+


#INCLUDE "BOX.CH"
#include "ads.ch"
#include "dbinfo.ch"
#include "TRY.ch"
#INCLUDE "hbVER.CH"

REQUEST DBFCDXEX


*+--------------------------------------------------------------------
*+
*+
*+
*+    Function inputbox()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
Function inputbox(eVAR,cTITULO)

LOCAL aAMBIENTE
IF VALTYPE(EVAR) = "U"
   eVAR := SPACE(30)
ENDIF
IF VALTYPE(cTITULO) = "U"
   cTITULO := "Dados"
ENDIF

aAMBIENTE := SALVAA()
HB_dispbox(2,22,7,62,B_DOUBLE+" ")
@ 04,24 SAY cTIPOSQL         
@ 05,24 GET eVAR             
READ
RESTAA(aAMBIENTE)
RETURN eVAR


*+--------------------------------------------------------------------
*+
*+    Function LAYOUT()
*+
*+--------------------------------------------------------------------
*+
function LAYOUT()

LOCAL n
clear
for n := 2 to len(func_title)
   @  0,( 9 * n) - 18 say padc("F"+STR(N,1),8)          
   @  1,( 9 * n) - 18 say padc(func_title[n],9)         
next
@  2,0 say replicate("-",80)         
//alguns rdd nao tem RDDI_TABLEEXT RDDI_MEMOEX RDDI_ORDBAGEXT usando try para ignonar
TRY
  @ MAXROW() - 4,0 say cTIPOSQL+" Server: "+cSERVERX+" Banco: "+cBANCOX+" Database: "+cDATABASEX+" Tabela: "+cTABELAX
END
TRY
@ MAXROW() - 3,0 say "RDD("+zUSOVIA+") Extensao("+hb_rddInfo(RDDI_TABLEEXT)+") Memo("+hb_rddInfo(RDDI_MEMOEXT)+") Index("+hb_rddInfo(RDDI_ORDBAGEXT)+")"         
END
@ MAXROW() - 2,0 say "Exportar Para("+ZEXPOREXT+") Delimitador("+ZDELIMITE+") Oem Ansi("+ZCNVCHAR+")"                                                                                               
@ MAXROW() - 1,0 say "Sepador Decimal("+ZDECSIM+") Separador Registro("+Zregsep+")"+" Ano("+ALLTRIM(ZANOFOR)+ZANOSEP+ZANOTAM+") Logico("+zSEPLOGIC+")"         

return .T.


*+--------------------------------------------------------------------
*+
*+
*+
*+    Function MD()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
function MD

@ maxrow(),00
retuRN .T.



*+--------------------------------------------------------------------
*+
*+
*+
*+    Function MDT()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
function MDT(cMSG)

hb_Alert(cMSG,,,1)
retuRN .t.


*+--------------------------------------------------------------------
*+
*+    Function XEXT()
*+
*+--------------------------------------------------------------------
*+
function XEXT
LOCAL cEXT
cEXT:=""
TRY
  CEXT:=hb_rddInfo(RDDI_ORDBAGEXT)
END
RETURN cEXT  

*+--------------------------------------------------------------------
*+
*+    Function EINDEXCOMPOUND()
*+
*+--------------------------------------------------------------------
*+
FUNCTION EINDEXCOMPOUND()
LOCAL cEXT
LOCAL lRETU
lRETU:=.T.
cEXT:=""
TRY
  cEXT:=hb_rddInfo(RDDI_ORDBAGEXT)
END
cEXT:=UPPER(STRTRAN(cEXT,".",""))
IF cEXT="NDX" .OR. cEXT="NTX" .OR. cEXT="IDX"
   lRETU:=.F.
ENDIF
RETURN lRETU

*+--------------------------------------------------------------------
*+
*+
*+
*+    Function MENUSQL()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
FUNCTION MENUSQL(cTIPOSQL)

LOCAL aAMBIENTE
aAMBIENTE := SALVAA()
WHILE .T.
   HB_dispbox(3,18,18,55,B_DOUBLE+" ")
   @ 03,24 SAY cTIPOSQL         
   OPCAO( 4,24,"&Nativo clientelib   ",78)   //N
   OPCAO( 5,24,"&ADORDD ODBC         ",65)   //A
   OPCAO( 6,24,"&RDD SQLMIX SDD      ",82)   //R
   OPCAO( 7,24,"&ODBC                ",79)   //D
   OPCAO( 8,24,"ADO&X ODBC           ",88)   //X
   OPCAO( 9,24,"&Tclass              ",84)   //t  
   OPCAO(10,24,"&SQLRDD    SR        ",83)   //S
   
   KEY := menu(1,0)
   DO CASE
   CASE KEY = 1 .AND. cTIPOSQL = "PGSQL"
      pgsqlmenu()
   CASE KEY = 1 .AND. cTIPOSQL = "MYSQL"
      mysqlmenu()
   CASE KEY = 1 .AND. cTIPOSQL = "SQLITE"
      sqlitemenu()
   CASE KEY = 1 .AND. cTIPOSQL = "FIREBIRD"
      Firebirdmenu()
   CASE KEY = 1 .AND. cTIPOSQL = "PARADOX"
      paradoxmenu()
   CASE KEY = 1
      MDT("Sem clientelib para "+cTIPOSQL)
   CASE KEY = 2
      mdbmenu(cTIPOSQL)  //ADORDD engine e ODBC
   CASE KEY = 3 
      mixmenu(cTIPOSQL)  //SQLMIX RDD SDD engine e odbc
   CASE KEY = 4
      ODBCmenu(cTIPOSQL) //odbc e dsn
   CASE KEY = 5
      adoxmenu(cTIPOSQL)  //adox engine e odbc e dsn
  CASE KEY = 6
      tclassmenu(cTIPOSQL)   //ao entrar trato os tipo que funcionam
  CASE KEY = 7
      sqlrddmenu(cTIPOSQL)   //sqlrdd engines odbc e dsn
   OTHERWISE
      RETURN
   ENDCASE
ENDDO
HB_dispbox(3,22,22,55,B_DOUBLE+" ")
RESTAA(aAMBIENTE)
LAYOUT()
return.t.



*+--------------------------------------------------------------------
*+
*+
*+
*+    Function tipodbfesc()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
FUNCtion tipodbfesc

//TipoDBF,USOVIA e varivel public
local aAMBIENTE
LOCAL KEY

/* indices
.NTX   Single NATIVE  DBFNTX Nantucket Clipper / CA-Clipper / Harbour Native Harbour RDD. One key per file. Full DESCEND, FOR, UNIQUE support.
.CDX Compound NATIVE  DBFCDX FoxPro / Visual FoxPro / Harbour Multi-tag compound index. Fully supported. VFP CDX compatible.
.NSX Compound NATIVE  DBFNSX Harbour native (modern) Harbour's own compound index. Recommended for new apps. Better perf than NTX.
.NDX Single   NATIVE  DBFNDX dBASE III / FoxBASE Oldest format. Supported via DBFNDX. Functional but avoid in new projects.
.MDX Compound PARTIAL DBFMDX* dBASE IV / dBASE 5 Partial support. DBFMDX not actively maintained. Test before use.
.IDX Single   NATIVE  DBFCDX FoxPro 2.x Simple FoxPro index. DBFCDX handles read/write correctly.
.DB   —    NOT SUPP.  — Borland Paradox NOT a DBF index. Proprietary Paradox format. ODBC/BDE access only. usar pxlib
.BAG compound PARTIAL SIXRDD* HiPer-Six / Six Driver HiPer-Six compound index. Requires external SIXRDD.
*/

/* memos
.DBT NATIVE dBASE III / dBASE IV / Clipper / CA-Clipper Most common legacy memo. Full support via DBFNTX and DBFCDX.
.FPT NATIVE FoxPro 2.x / Visual FoxPro Fully supported by DBFCDX. Handles MEMO, GENERAL and PICTURE fields.
.SMT PARTIAL HiPer-Six Proprietary HiPer-Six memo. Partial read via SIXRDD. Avoid.
.DBV NOT SUPP. dBASE 5 for Windows dBASE 5 memo. Not natively supported. ODBC access only. 
*/

/* drives
DBFNTX NATIVE   0x02/0x03/0x83   .NTX       .DBT     Legacy Clipper/CA-Clipper systems. Maintenance and migration.
DBFCDX NATIVE   0x30/0xF5       .CDX/.IDX  .FPT      FoxPro/VFP interop. New apps needing compound indexes. Strongly recommended.
DBFNSX NATIVE   0x03            .NSX       .DBT/.FPT Pure  Harbour native. Best choice for new Harbour applications.
DBFNDX NATIVE   0x02/0x03       .NDX       .DBT      dBASE III/FoxBASE compatibility. Avoid in modern production code.
DBFMDX PARTIAL  0x43/0x63/0x8B  .MDX       .DBT      dBASE IV MDX. Partial support. Read legacy files only, avoid index creation.
SIXRDD EXTERNAL 0xE5            .BAG/.NTX  .SMT      External HiPer-Six library. Not bundled with Harbour. Legacy-specific only.
LETO   NATIVE   any             any        any       Remote DBF over network (leto server). Works on top of DBFNTX/CDX/NSX.
SQLRDD NATIVE   —               —          —         SQL access (MySQL, PostgreSQL, SQLite, MSSQL) using xBase syntax.

PXRDD  baseada na pxlib        implementacao
*/




//KEY= TIPODBF //posiciona pela escolha anterior
aAMBIENTE := SALVAA()
HB_dispbox(03,08,21,60,B_DOUBLE+" ")
@ 03,10 SAY "DRIVER    ARQ IND MEMO"          //     Driver   heranca
@ 03,35 SAY "DRIVER    ARQ IND MEMO"
OPCAO( 4,10,"DBF&NTX   DBF NTX DBT ",78)  //N  1 DBFNTX   DBF/DBFFPT/DBFNTX
OPCAO( 5,10,"DBF&CDX   DBF CDX FPT ",67)  //C  2 DBFCDX   DBF/DBFFPT/CDXRDD
OPCAO( 6,10,"&ADSCDX   DBF CDX FPT ",65)  //A  3 ADSCDX
OPCAO( 7,10,"ADSNT&X   DBF NTX DBT ",88)  //X  4 ADSNTX
OPCAO( 8,10,"ADSVF&P   DBF CDX FPT ",80)  //P  5 ADSVFP
OPCAO( 9,10,"ADSAD&T   ADT ADI ADM ",84)  //T  6 ADSADT
OPCAO(10,10,"D&BTCDX   DBF CDX DBT ",66)  //B  7 DBTCDX   DBFCDX/DBFFPT/DBTCDX
OPCAO(11,10,"&SMTCDX   DBF CDX SMT ",83)  //S  8 DBFCDX   DBFFPT/SMTCDX
OPCAO(12,10,"&FPTCDX   DBF CDX FPT ",70)  //F  9 FPTCDX   DBFCDX/DBFFPT/FPTCDX
OPCAO(13,10,"S&IXCDX   DBF CDX FPT ",73)  //I 10 SIXCDX

OPCAO(04,35,"&DBFNSX   DBF NSX MST ",68)  //D 11 DBFNSX   DBF/DBFFPT/DBFNSX
OPCAO(05,35,"DBFB&LOB  DBF     DBV ",76)  //L 12 DBFBLOB  DBF/DBFFPT/DBFBLOB
OPCAO(06,35,"&HSCDX    DBF CDX FPT ",72)  //H 13 HSCDX    DBFCDX/HSCDX
OPCAO(07,35,"&RLCDX    DBF CDX FPT ",82)  //R 14 RLCDX    DBFCDX/RLCDX
OPCAO(08,35,"&VFPCDX   DBF CDX FPT ",86)  //V 15 VFPCDX   DBFCDX/DBFFPT/VFPCDX
OPCAO(09,35,"B&MDBFCDX DBF CXD FPT ",77)  //M 16 BMDBFCDX DBFCDX DBFFPT
OPCAO(10,35,"BMDBFNSX  DBF NSX FPT ",49)  //1 17 BMDBFNSX DBFNSX DBFFPT
OPCAO(11,35,"BMDBFNTX  DBF NTX FPT ",50)  //2 18 BMDBFNTX DBFNTX DBFFPT 
OPCAO(12,35,"DBFCDXEX  DBF CDX FPT ",51)  //2 19 Crypto   DBFCDXEX   -lbcrypt
#ifdef USE_PXRDD
   OPCAO(13,35,"PARADOX   DB  PX  MB  ",51)   //-20 Carrega a RDD do Paradox pxrdd
#endif

KEY := menu(2,0)
if KEY > 0
   TIPODBF := KEY
else
   TIPODBF := 2   //padrao dbfcdx
endif
USOVIA := RDDNOME(TIPODBF)
RESTAA(aAMBIENTE)
layout()
return TIPODBF


*+--------------------------------------------------------------------
*+
*+    Function RDDNOME()
*+
*+--------------------------------------------------------------------
*+
FUNCTION RDDNOME(nTIPODBF)

LOCAL USOVIA
IF VALTYPE(nTIPODBF) <> "N"
   nTIPODBF := TIPODBF  //Atribui a publica se nao for passado
ENDIF
TABLEEXT:="DBF"
//pego abaixo pelo redinfo
//MEMOEXT  := "FPT"    //hb_rddInfo(RDDI_MEMOEXT)
//INDIEXT  := "CDX"   //hb_rddInfo(RDDI_ORDBAGEXT)
do case
    case nTIPODBF = 1
       USOVIA := "DBFNTX"
       rddSetDefault("DBFNTX")
    case nTIPODBF = 2
       USOVIA := "DBFCDX"
       rddsetdefault("DBFCDX")
    case nTIPODBF = 3
       USOVIA := "ADSCDX"
       rddSetDefault("ADSCDX")
       AdsSetServerType(ADS_LOCAL_SERVER)
       AdsSetFileType(ADS_CDX)
    case nTIPODBF = 4
       USOVIA := "ADSNTX"
       rddSetDefault("ADSNTX")
       AdsSetServerType(ADS_LOCAL_SERVER)
       AdsSetFileType(ADS_NTX)
    case nTIPODBF = 5
       USOVIA := "ADSVFP"
       rddSetDefault("ADSVFP")
       AdsSetServerType(ADS_LOCAL_SERVER)
       AdsSetFileType(ADS_VFP)
    case nTIPODBF = 6
       USOVIA   := "ADSADT"
       TABLEEXT :="ADT"
       rddSetDefault("ADSADT")
       AdsSetServerType(ADS_LOCAL_SERVER)
       AdsSetFileType(ADS_ADT)
    case nTIPODBF = 7
       USOVIA := "DBTCDX"
       rddSetDefault("DBTCDX")
    case nTIPODBF = 8
       USOVIA := "SMTCDX"
       rddSetDefault("SMTCDX")
    case nTIPODBF = 9
       USOVIA := "FPTCDX"
       rddSetDefault("FPTCDX")
    case nTIPODBF = 10
       USOVIA := "SIXCDX"
       rddSetDefault("SIXCDX")
    case nTIPODBF = 11
       USOVIA := "DBFNSX"
       rddSetDefault("DBFNSX")
    case nTIPODBF = 12
       USOVIA := "DBFBLOB"
       rddSetDefault("DBFBLOB")
    case nTIPODBF = 13
       USOVIA := "HSCDX"
       rddSetDefault("HSCDX")
    case nTIPODBF = 14
       USOVIA := "RLCDX"
       rddSetDefault("RLCDX")
    case nTIPODBF = 15
       USOVIA := "VFPCDX"
       rddSetDefault("VFPCDX")
    case nTIPODBF = 16
       USOVIA := "BMDBFCDX"
       rddSetDefault("BMDBFCDX")
    case nTIPODBF = 17
       USOVIA := "BMDBFNSX"
       rddSetDefault("BMDBFNSX")
    case nTIPODBF = 18
       USOVIA := "BMDBFNTX"
       rddSetDefault("BMDBFNTX")
    case nTIPODBF = 19
       zSENHACDX := INPUTBOX( PADR( zSENHACDX,30 ), "Senha" )
       zSENHACDX :=ALLTRIM(zSENHACDX)
       USOVIA := "DBFCDXEX"
       rddSetDefault("DBFCDXEX")   
       DbfcdxexSetup( "aes256", zSENHACDX )
#ifdef USE_PXRDD
    case nTIPODBF = 20
        TABLEEXT :="DB"
        USOVIA := "PXRDD"
        rddSetDefault("PXRDD")
#endif
    case nTIPODBF = 90   
       USOVIA := "LETO"
       rddSetDefault("LETO")
    case nTIPODBF = 91  
       USOVIA := "SQLMIX"
       rddSetDefault("SQLMIX")
    case nTIPODBF = 92  
       USOVIA := "SQLRDD"
       rddSetDefault("SQLRDD")
    case nTIPODBF = 93  
       USOVIA := "SQLEX"
       rddSetDefault("SQLEX")
    otherwise
       USOVIA := "DBFCDX"
       rddsetdefault("DBFCDX")
endcase
zusovia := USOVIA
//Algumas rdd nao tem hb_rddinfo usando try para ignonar 
TRY
  //TABLEEXT :=strtran(hb_rddInfo(RDDI_TABLEEXT),".","") Fixado nos case so tem dbf adt(ads) db(paradox)
END
TRY
   MEMOEXT:=strtran(hb_rddInfo(RDDI_MEMOEXT),".","") 
END
TRY
   INDIEXT:=strtran(hb_rddInfo(RDDI_ORDBAGEXT),".","")       
END
layout()
RETURN USOVIA



*+--------------------------------------------------------------------
*+
*+
*+
*+    Function pegtipodoc()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
Function pegtipodoc(lincdbf)

LOCAL tDOC
LOCAL aAMBIENTE
if valtype(lincdbf) <> "L"
   lincdbf := .F.
ENDIF

tDOC      := 0
aAMBIENTE := SALVAA()

HB_dispbox(03,10,22,60,B_DOUBLE+" ")
OPCAO(05,14,"X&LS                                ",76)  //L 1
OPCAO(06,14,"&TAM  STRU+TAM                      ",84)  //T 3
OPCAO(07,14,"TE&C  STRU                          ",67)  //C 2
OPCAO(08,14,"&DBE  STRU DDL                      ",68)  //D 4
OPCAO(09,14,"DL&M  Delimitador Especificado      ",77)  //M 5
OPCAO(10,14,"&SDF  tamanho do campo              ",83)  //S 6
OPCAO(11,14,"&XML                                ",88)  //X 7
OPCAO(12,14,"&JSON                               ",74)  //J 8
OPCAO(13,14,"SSV Semi Colon (;) &Ponto e Virgula ",80)  //P  9
OPCAO(14,14,"CS&V Colon     (,) Virgula          ",86)  //V1 0
OPCAO(15,14,"&UNL PSV       (|) Pipe             ",85)  //U 11
OPCAO(16,14,"TSV            TA&B                 ",66)  //B 12
OPCAO(17,14,"S&QL   insert into                  ",81)  //Q 13
OPCAO(18,14,"Mar&kdown                           ",75)  //K 14

IF lincdbf
   OPCAO(21,14,"DB&F                                ",70)   //F 15-->90
ENDIF
tdoc := menu(2,0)

DO CASE
CASE tDOC = 1
   zEXPOREXT := "XLS"
CASE tDOC = 2
   zEXPOREXT := "TAM"
CASE tDOC = 3
   zEXPOREXT := "TEC"
CASE tDOC = 4
   zEXPOREXT := "DBE"  
CASE tDOC = 5   
   zEXPOREXT := "DLM" //-->5 delimitado pelo caracter escolhido
CASE tDOC = 6   
   zEXPOREXT := "SDF" //  espaco
CASE tDOC = 7
   zEXPOREXT := "XML"
CASE tDOC = 8
   zEXPOREXT := "JSON"
CASE tDOC = 9   
   zEXPOREXT := "SSV" //-->5 delimitado ;
CASE tDOC = 10   
   zEXPOREXT := "CSV" //-->5 delimitado ,
CASE tDOC = 11   
   zEXPOREXT := "UNL" //-->5 delimitado | PIPE
CASE tDOC = 12  
   zEXPOREXT := "TSV" //-->5 delimitado TAB CHR(9)
CASE tDOC = 13   
   zEXPOREXT := "SQL" //-->5 delimitado , no insert into
CASE tDOC = 14
    zEXPOREXT :="MD"  //-->14 Mar&kdown MD   
CASE tDOC = 15
   zEXPOREXT := "DBF"  //como vao incluindos novos tipos o dbf fica travando no 90 evitando a cada novo tipo verre fontes para correcao da posicao
   tdoc=90 
ENDCASE
IF tDOC >= 9 .AND. tDOC <= 13
   checkextEXP()  //pega o delimitador zDELIMITE:
   tDOC := 5  //retorna para o tipo 5 DML a geracao SSV CSV UNL PSV TSV SQL usam as funcoes da DML
ENDIF

RESTAA(aAMBIENTE)
return tDOC


*+--------------------------------------------------------------------
*+
*+
*+
*+    Function pegparexp()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
function pegparexp

local aAMBIENTE
aAMBIENTE := SALVAA()
zEXPOREXT := PADR(zEXPOREXT,4)

HB_dispbox(03,10,22,60,B_DOUBLE+" ")
@ 03,12 say "TXT SDF DML    fornecer delimitador"         
@ 04,12 SAY "SSV Semi Colon (;) Ponto e Virgula "         
@ 05,12 say "CSV Colon      (,) Virgula         "         
@ 06,12 say "UNL PSV        (|) Pipe            "         
@ 07,12 say "TSV            TAB                 "         
@ 08,12 say "XLS XML SQL JSON MD               "         

@ 09,12 say "Formato"                                 
@ 10,12 say "Delimitador ,;|#~ 9=(TAB)"               
@ 11,12 say "Sep Reg "+chr(34)+chr(39)+"( ) "         
@ 12,12 say "Separador Decimal ,. "                   

@ 13,12 say "(D)ia(M)es(A)no DMA AMD MDA SQL MYS DHZ"           
@ 14,12 say "ASPAS ACESSS CRYSTAL DATE(, DATESERIAL"            
@ 15,12 say "MYSQL/ MYSQL- ORACLE TO_DATE MSSQL SQLITE"         

@ 16,12 say "Digitos Ano 2/4"              
@ 17,12 say "Separador Data /-( )"         

@ 18,12 say "Logico= TRUE .T. ON YES SIM 1 T Y S"             
@ 19,12 say "Converter (N)ao oemto(A)nsi ansito(O)em"         

@ 09,53 get zEXPOREXT PICT "!!!!"                         VALID checkextEXP()               
@ 10,53 get zDELIMITE PICT "!"                            VALID zDELIMITE $ " ,;|#~9"       
@ 11,53 get zregSEP   VALID zregsEP $ chr(34)+chr(39)+" "                                   
@ 12,53 get zDECSIM   VALID zDECSIM $ ",."                                                  

@ 13,53 get zANOFOR PICT "!!!!!!!!!!"     VALID checkanofor()        
@ 16,53 get zANOTAM PICT "9"              VALID zANOTAM $ "24"       
@ 17,53 get zANOSEP VALID zANOSEP $ "/- "                            

@ 18,53 get zSEPLOGIC valid zSEPLOGIC = "TRUE" .OR. zSEPLOGIC = ".T. " .OR. zSEPLOGIC = "YES " .OR. zSEPLOGIC = "ON  " .OR. zSEPLOGIC = "SIM " .OR. zSEPLOGIC = "1   " .OR. zSEPLOGIC = "T   " .OR. zSEPLOGIC = "Y   " .OR. zSEPLOGIC = "S   "                              
@ 19,53 get zCNVCHAR  PICT "!"                                                                                                                                                                                                                 VALID zCNVCHAR $ "NAO"       
readcur()

zEXPOREXT := ALLTRIM(ZEXPOREXT)
IF zEXPOREXT = "XLS" .AND. zDELIMITE <> "9"
   error_msg("XLS requer requerer 9=(TAB)")
   zDELIMITE := "9"
ENDIF
IF zDELIMITE = "9"
   zDELIMITE := CHR(9)
ENDIF
IF zEXPOREXT = "SQL"
   zDELIMITE := ","
ENDIF
IF zEXPOREXT = "JSON" 
   zDELIMITE := ""
ENDIF
RESTAA(aAMBIENTE)
layout()
return nil



*+--------------------------------------------------------------------
*+
*+
*+
*+    Function checkanofor()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
function checkanofor()

LOCAL lRETU
LOCAL cANOFOR
lRETU   := .F.
cANOFOR := ALLTRIM(zANOFOR)
IF cANOFOR = "DMA" .OR. cANOFOR = "AMD" .OR. cANOFOR = "MDA" .OR. cANOFOR = "SQL" .OR. cANOFOR = "MYS" .OR. cANOFOR = "DHZ" ;
           .OR. cANOFOR = "ASPAS" .OR. cANOFOR = "ACESSS" .OR. cANOFOR = "CRYSTAL" .OR. cANOFOR = "DATE(," .OR. cANOFOR = "DATESERIAL" ;
           .OR. cANOFOR = "MYSQL/" .OR. cANOFOR = "MYSQL-" .OR. cANOFOR = "ORACLE" .OR. cANOFOR = "TO_DATE" .OR. cANOFOR = "MSSQL" .OR. cANOFOR = "SQLITE"
   lRETU := .T.
ENDIF
DO CASE
CASE cANOFOR = "SQLITE"
   zSEPLOGIC := "1   "
   zANOTAM   := "4"
   zANOSEP   := "-"
ENDCASE
RETURN lRETU



*+--------------------------------------------------------------------
*+
*+
*+
*+    Function checkextEXP()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
function checkextEXP()  //",;|#~9" zEXPOREXT="DLM" .OR. zEXPOREXT="CVS" .OR. zEXPOREXT="UNL" 
                     //.OR. zEXPOREXT="XLS" .OR. zEXPOREXT="XML" .OR. zEXPOREXT="SQL" .OR. zEXPOREXT="JSON"
                    //.OR. zEXPOREXT="MD"
LOCAL lRETU
zDELIMITE := " "
zregSEP   := " "
lRETU     := .T.
DO CASE
    CASE zEXPOREXT = "TXT"
    CASE zEXPOREXT = "TEC"
    CASE zEXPOREXT = "DBE"
    CASE zEXPOREXT = "TAM"
    CASE zEXPOREXT = "DBF"
    CASE zEXPOREXT = "SDF"
         zDELIMITE := ""  //pelo tamanho do campo sem delimitador
    CASE zEXPOREXT = "DLM"
    CASE zEXPOREXT = "SSV"
       zDELIMITE := ";"
    CASE zEXPOREXT = "CSV"
       zDELIMITE := ","
    CASE zEXPOREXT = "UNL" .OR. zEXPOREXT = "PSV"
       zDELIMITE := "|"
    CASE zEXPOREXT = "TSV" .OR. zEXPOREXT = "XLS"
       zDELIMITE := "9"
    CASE zEXPOREXT = "XML"
    CASE zEXPOREXT = "SQL"
       zDELIMITE := ","
    CASE zEXPOREXT = "JSON"
	CASE zEXPOREXT = "MD"
    OTHERWISE
   lRETU := .F.
ENDCASE
RETURN lRETU



*+--------------------------------------------------------------------
*+
*+    Function copiardbfpara()
*+
*+--------------------------------------------------------------------
*+
*+
*+
function copiardbfpara(nTIPOPR)   //1 Copiar 2 anexar

LOCAL aAMBIENTE
LOCAL nOLDTIPO
LOCAL nORITIPO
LOCAL cORIDRIVER
LOCAL cARQORI
LOCAL cDESTINO

IF VALTYPE(nTIPOPR) <> "N"
   nTIPOPR := 1
ENDIF

aAMBIENTE := SALVAA()
nOLDTIPO  := TIPODBF

if nTIPOPR = 1
   alertX("escolha origem")
else
   alertX("escolha destino")
endif
tipodbfesc()
nORITIPO   := TIPODBF
cORIDRIVER := RDDNOME(TIPODBF)


//nao mostrar tipo 90 dbf na escolha nao spbrepor na copia passando falso aqui
tDOC := pegtipodoc(.F.)
IF nTIPOPR = 2 // append from somente nativo anexar
   IF zEXPOREXT = "DBF" .OR. zEXPOREXT = "SDF" .OR. zEXPOREXT = "DLM" .OR. zEXPOREXT = "CSV" .OR. zEXPOREXT = "UNL" .OR. zEXPOREXT = "PSV" .OR. zEXPOREXT = "TSV" .OR. zEXPOREXT = "SSV"
   ELSE
      MDT("Ainda nao disponivel para "+zEXPOREXT)
      RETURN
   ENDIF
ENDIF

pegparexp()



if nTIPOPR = 1
   cARQORI := win_GetOpenFileName(,"Arquivos de Origem",HB_CWD(),"Arquivos de Origem","*."+TABLEEXT,1)
else
   cDESTINO := win_GetOpenFileName(,"Arquivos de Destino",HB_CWD(),"Arquivos de destino","*."+TABLEEXT,1)
endif

altd()
LCOPIANAT := .F.
IF nTIPOPR = 1
   //     XML         TAM             TEC           dbe            xml            json            sql       md markdown
   IF tDOC = 1  .OR. tDOC = 2  .OR. tDOC = 3  .OR. tDOC = 4  .OR. tDOC = 7  .OR. tDOC = 8  .OR. tDOC = 13  .OR. tDOC = 14
     LCOPIANAT:=.F.
   ELSE
     LCOPIANAT := MDG("Copia Nativa(copy to)(SIM) Interna(gerada)(NAO)")
   ENDIF  
ENDIF
IF nTIPOPR = 2 //Extensoes tratadas acima fica so nativa quando o tipo 2 anexar
   LCOPIANAT := .T.
ENDIF


IF nTIPOPR = 1
   IF .NOT. lCOPIANAT
      PegcsUB(tDOC)   //pegar o subtipo conforme tipo
   ENDIF
ENDIF

IF nTIPOPR = 1 //Exportar copy to ou gerado
   IF LCOPIANAT
      cDESTINO := TROCAEXT(cARQORI,zEXPOREXT)
      MDT("abrindo arquivo de origem: "+cARQORI)
      //USE (cARQORI) ALIAS ORIGEM EXCLUSIVE NEW VIA (cORIDRIVER)
      dbUseArea( .T., (cORIDRIVER), (cARQORI), "ORIGEM", .F. , .F. )
      COPYTO(cDESTINO)
      dbcloseall()
   ELSE
      multidocs(tDOC,cARQORI)
   ENDIF
ENDIF
IF nTIPOPR = 2 //Importar append from so nativo
   cARQORI := win_GetOpenFileName(,"Arquivos de Origem",HB_CWD(),"Arquivos de Origem","*."+zEXPOREXT,1)
    MDT("abrindo arquivo de destino: "+cDESTINO)
    //USE (cDESTINO) ALIAS DESTINO EXCLUSIVE NEW VIA (cORIDRIVER)
    dbUseArea( .T., (cORIDRIVER), (cDESTINO), "DESTINO", .F. , .F. )
    APPENDFROM(cARQORI)
    dbcloseall()
ENDIF

RESTAA(aAMBIENTE)
TIPODBF := nOLDTIPO
RDDNOME(nOLDTIPO)   //retorna tipo anterio


*+--------------------------------------------------------------------
*+
*+
*+
*+    Function COPYTO()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
FUNCTION COPYTO(cDESTINO)

nLASTREC := LASTREC()
zei_fort(nLASTREC,,,0)
DO CASE
   //
   // DML CSV UNL PSV TSV
   //
CASE zREGSEP = chr(34) .OR. zREGSEP = chr(39)   //delimitador + aspas duplas aspas (") (')
   try
   COPY to &cDESTINO. while zei_fort(nLASTREC,,,1) DELIMITED WITH ( { zDELIMITE, zREGSE } )
   catch oErR
   MDT("Erro copiando dados")
END
//
//tDOC=15
//
CASE zEXPOREXT = "DBF"
try
COPY to &cDESTINO. while zei_fort(nLASTREC,,,1)
catch oErR
MDT("Erro copiando dados")
END
//
//tDOC=6
//
CASE zEXPOREXT = "SDF"
try
COPY to &cDESTINO. while zei_fort(nLASTREC,,,1) SDF
catch oErR
MDT("Erro copiando dados")
END
//
//tDOC=10
//
CASE zEXPOREXT = "DLM" .OR. zEXPOREXT = "CSV"
TRY
COPY to &cDESTINO. whILE zei_fort(nLASTREC,,,1) DELIMITED
catch oErR
MDT("Erro copiando dados")

END
//
//tDOC=11
//
CASE zEXPOREXT = "UNL" .OR. zEXPOREXT = "PSV"
TRY
COPY to &cDESTINO. whILE zei_fort(nLASTREC,,,1) DELIMITED WITH PIPE
catch oErR
MDT("Erro copiando dados")
END
//
// tDOC=12
//
CASE zEXPOREXT = "TSV"
TRY
COPY to &cDESTINO. whILE zei_fort(nLASTREC,,,1) DELIMITED WITH TAB
catch oErR
MDT("Erro copiando dados")
END
//
// SSV  zdelimite= ; e outro delimitador tDOC=9
//
OTHERWISE
TRY
COPY to &cDESTINO. while zei_fort(nLASTREC,,,1) DELIMITED WITH &zDELIMITE
catch oErR
MDT("Erro copiando dados")
END
ENDCASE
RETURN NIL


*+--------------------------------------------------------------------
*+
*+
*+
*+    Function APPENDFROM()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
FUNCTION APPENDFROM(cDESTINO)

nLASTREC := LASTREC()
zei_fort(nLASTREC,,,0)
DO CASE
CASE zREGSEP = chr(34) .OR. zREGSEP = chr(39)   //delimitador + aspas duplas aspas (") (')
   APPEND FROM &cDESTINO. while zei_fort(nLASTREC,,,1) DELIMITED WITH ({zDELIMITE,zREGSEP})
CASE zEXPOREXT = "DBF"
   APPEND FROM &cDESTINO. while zei_fort(nLASTREC,,,1)
CASE zEXPOREXT = "SDF"
   APPEND FROM &cDESTINO. while zei_fort(nLASTREC,,,1) SDF
CASE zEXPOREXT = "DLM" .OR. zEXPOREXT = "CSV"
   APPEND FROM &cDESTINO. whILE zei_fort(nLASTREC,,,1) DELIMITED
CASE zEXPOREXT = "UNL" .OR. zEXPOREXT = "PSV"
   APPEND FROM &cDESTINO. whILE zei_fort(nLASTREC,,,1) DELIMITED WITH PIPE
CASE zEXPOREXT = "TSV"
   APPEND FROM &cDESTINO. whILE zei_fort(nLASTREC,,,1) DELIMITED WITH TAB
OTHERWISE   //SSV  zdelimite= ; e outro delimitador
   APPEND FROM &cDESTINO. while zei_fort(nLASTREC,,,1) DELIMITED WITH &zDELIMITE
ENDCASE
RETURN NIL





*+--------------------------------------------------------------------
*+
*+
*+
*+    Function formatacpf()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
FUNCTION formatacpf(xCPF)

XCPF := AllTrim(TIRAOUT(xCPF))
IF VAL(xCPF) = 0 .OR. LEN(xCPF) <> 11
   return xCPF
ENDIf
xCPF := StrZero(Val(XCPF),11)
RETUrn Transform(xCPF,"@R 999.999.999-99")


*+ EOF: dbulib.prg
*+
