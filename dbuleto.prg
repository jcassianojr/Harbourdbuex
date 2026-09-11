*+--------------------------------------------------------------------
*+
*+    Programa  : dbuleto.prg
*+
*+     Sistema:
*+
*+     Linguagem: Harbour
*+
*+     Autor: jcassiano
*+
*+     Copyright (c) 2024,  jcassiano
*+
*+
*+    Documentado em 6-Jan-2025 as  3:37 pm
*+
*+--------------------------------------------------------------------
*+

// +--------------------------------------------------------------------
// +
// +
// +
// +    Function letomenu()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +

//#include "leto_rev.ch"
#include "rddleto.ch"
#include "BOX.CH"
#include "TRY.CH"

REQUEST LETO



*+--------------------------------------------------------------------
*+
*+
*+
*+    Function letomenu()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
*+--------------------------------------------------------------------
*+    Function letomenu()
*+--------------------------------------------------------------------
FUNCTION letomenu()

LOCAL aAMBIENTE, KEY := 0

cTIPOSQL := "LETO"  // Passa para privada usadas nas funcoes aBaixo

aAMBIENTE  := SALVAA()
cSERVERX   := PADR("//127.0.0.1:2812/",30," ")
cDATABASEX := Space(30)
cUSERX     := Space(30)
cPASSX     := Space(30)
cTABELAX   := Space(30)
cBANCOX    := Space(30)
cOWNERX    := Space(30)
cPORTAX    := SPACE(30)

cPATH      :=""
loledb     := .T.
lMDB       := .F.
lACCDB     := .F.
lFDB       := .F.

cRDDSQL     := "LETO"
cOLDRDD     := RDDSETDEFAULT("LETO")
nOLDTIPORDD := TIPODBF
TIPODBF     := 90

pegcfgbanco()

WHILE .T.
   hb_DispBox(3,18,18,55,B_DOUBLE+" ")
   @ 03,24 SAY "LETODB"+" "+cSERVERX         
   OPCAO(4,24,"&Informacoes Servidor      ",73)   // I
   OPCAO(5,24,"&DBF                       ",68)   // D
   OPCAO(6,24,"&Usuarios                 ",85)   // U 
   OPCAO(7,24,"S&QLite                   ",81)   // Q 
   OPCAO(8,24,"&Gestao (Server/User)     ",71)   // G
   
   
   KEY := menu(1,0)
   DO CASE
   CASE KEY = 1
      LETO_INFOMENU(cSERVERX)
   CASE KEY = 2
      LETO_DBFMENU(cSERVERX)
   CASE KEY = 3
      LETO_USERS(cSERVERX) 
   CASE KEY = 4
      LETO_SQLITEMENU(cSERVERX)     
   CASE KEY = 5
      LETO_GESTAOMENU(cSERVERX)      
   OTHERWISE
      EXIT
   ENDCASE
ENDDO

TIPODBF := nOLDTIPORDD
rddSetDefault(cOLDRDD)

RESTAA(aAMBIENTE)
LAYOUT()

RETURN .T.



*+--------------------------------------------------------------------
*+
*+
*+
*+    Function LETO_SRVTODBF()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
FUNCTION LETO_SRVTODBF(cSrvAddr)

cARQORI   := LETO_tables(cSrvAddr, "*."+TABLEEXT, .T., .F.)
cARQUIVO  := TIRAEXT(cARQORI)
cEXTMEMO  := ".FPT"
cEXTINDEX := ".CDX"
nConnect  := leto_conexao(cSrvAddr)
IF nConnect >= 0
   IF .NOT. File(cARQORI)
      Leto_FCopyFromSrv(cARQORI,cARQORI)
   ENDIF
   IF .NOT. FILE(cARQUIVO+cEXTMEMO)
      Leto_FCopyFromSrv(cARQUIVO+cEXTMEMO,cARQUIVO+cEXTMEMO)
   ENDIF
   IF .NOT. FILE(cARQUIVO+cEXTINDEX)
      Leto_FCopyFromSrv(cARQUIVO+cEXTINDEX,cARQUIVO+cEXTINDEX)
   ENDIF
   leto_disconnect()
else
   leto_errocon(nConnect)
ENDIF
RETURN .T.


*+--------------------------------------------------------------------
*+
*+
*+
*+    Function LETO_DELDBF()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
FUNCTION LETO_DELDBF(cSrvAddr)

cARQORI   := LETO_tables(cSrvAddr, "*."+TABLEEXT, .T., .F.)
cARQUIVO  := TIRAEXT(cARQORI)
cEXTMEMO  := ".FPT"
cEXTINDEX := ".CDX"
IF MDG('Excluir '+cARQORI)
   nConnect := leto_conexao(cSrvAddr)
   IF nConnect >= 0
      Leto_FERASE(cARQORI,cARQORI)
      Leto_FERASE(cARQUIVO+cEXTMEMO)
      Leto_FERASE(cARQUIVO+cEXTINDEX)
      leto_disconnect()
   else
      leto_errocon(nConnect)
   ENDIF
ENDIF
RETURN .T.



*+--------------------------------------------------------------------
*+    Function leto_conexao()
*+    Wrapper para centralizar conexao LetoDB com Timeout e Alertas
*+--------------------------------------------------------------------
FUNCTION leto_conexao( cSrvAddr,cUserName, cPassword, nTimeOut, lmes )
   LOCAL nConnect
   
   // 1. Define um timeout padrao (ex: 5 segundos) se nao for informado na chamada
   IF nTimeOut == NIL
      nTimeOut := 5 
   ENDIF
   
   // 2. Define o comportamento padrao do alerta (lmes)
   IF ValType( lmes ) != "L"
      lmes := .T. // Assume .T. para exibir o erro caso o parametro seja omitido
   ENDIF

   // 3. Executa a conexao passando NIL para usuario e senha, injetando o timeout[cite: 33]
   nConnect := LETO_CONNECT( cSrvAddr, cUserName, cPassword, nTimeOut )

   // 4. Se falhar (-1) e lmes for verdadeiro, dispara a mensagem[cite: 33]
   IF nConnect == -1 .AND. lmes
      leto_errocon( nConnect, cSrvAddr )
   ENDIF

   RETURN nConnect

*+--------------------------------------------------------------------
*+    Function leto_errocon()
*+    Interpreta o codigo de erro da conexao
*+--------------------------------------------------------------------
FUNCTION leto_errocon( nConnect, cSrvAddr )
   LOCAL nRes
   
   // Previne quebra caso cSrvAddr venha nulo
   IF cSrvAddr == NIL
      cSrvAddr := ""
   ENDIF

   IF nConnect == -1
      nRes := leto_Connect_Err()
      
      IF nRes == LETO_ERR_LOGIN
         mdt("Falha ao Logar no servidor.")
      ELSEIF nRes == LETO_ERR_RECV
         mdt("Erro ao conectar (Falha de recepcao).")
      ELSEIF nRes == LETO_ERR_SEND
         mdt("Erro de envio de dados para o servidor.")
      ELSE
         // Corrigido de cPath para cSrvAddr para mostrar a rota real que falhou
         mdt("Nao conectado ao servidor: " + cSrvAddr) 
      ENDIF
   ENDIF
   
RETURN NIL


*+--------------------------------------------------------------------
*+
*+
*+
*+    Function leto_expformat()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
FUNCTION leto_expformat(cSrvAddr)

cARQORI   := LETO_tables(cSrvAddr, "*."+TABLEEXT, .T., .F.)
cTABELAX := TIRAEXT(cARQORI)


LCOPIANAT := .F.  // MDG("Copia Nativa(SIM) Interna(NAO)") //copy to nao implemntado mysqlrddd
tDOC      := pegtipodoc()   // .t. Inclui dbf se for nativa
pegparexp()
lDOCCAB   := .F.
lDOCDAD   := .F.
lDOCRECNO := .F.
cSUBTIPO  := " "
PegcsUB(tDOC)   // pegar o subtipo conforme tipo
cDESTINO := cTABELAX+"_"+cTIPOSQL+"_leto."+zEXPOREXT
MDT(cDESTINO)
MDT("abrindo arquivo de origem: "+cTABELAX)
nConnect := leto_conexao(cSrvAddr)
IF nConnect >= 0
   //LETO_SETSKIPBUFFER( 10 )
   //DBUseArea( <lNewArea> , <cDriver> , <cName>, <xcAlias> , <lShared> , <lReadOnly>,<cCodePage>,<nConnection> ) -> lSuccess
   dbUseArea(.T.,,cTABELAX,,.T.)
   nLASTREC := LastRec()
   zei_fort(nLASTREC,,,0)
   aSTRU := dbStruct()
   multidocg(lDOCCAB,lDOCDAD,lDOCRECNO,cSUBTIPO,TIRAEXT(cDESTINO),aSTRU)
   dbCloseArea()
else
   leto_errocon(nConnect)
endif
return .t.


Function LETO_DBFTOSRV(cSrvAddr)
 nOLDTIPO := TIPODBF
            alertX( "escolha origem" )
            tipodbfesc()
            nORITIPO   := TIPODBF
            cORIDRIVER := RDDNOME( TIPODBF )
            lincdados:=mdg("Incluir Dados")
            IF MDG("Arquivo individual")
               cARQORI    := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*."+TABLEEXT, 1 )
                IF File( cARQORI )
                   LETO_DBFSRV(cSrvAddr,cARQORI)
                ENDIF
            ELSE
               cPASTA:=SelectFolder()
               cPASTA+="\*."+TABLEEXT 
               //FAZERDBF(bUSO                                       , lSHARE[.F.] , bPRE, bPOS, cMASK ,LOPEN )
               FAZERDBF( {|| LETO_DBFSRV(cSrvAddr,cCAMINHOCOMPLETO) }, .F. ,     ,     ,cPASTA,.F.)
            ENDIF   
            RDDNOME( nOLDTIPO )   // retorna tipo anterior
return


*+--------------------------------------------------------------------
*+
*+
*+
*+    Function LETO_DBFTOSRV()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
FUNCTION LETO_DBFSRV(cSrvAddr,cARQORI)

cCAMINHO  := ""
cARQUIVO  := ""
cEXTENSAO := ""
cEXTMEMO  := ""
cEXTINDEX := ""
//HB_FNameSplit( <cString>, <@cPath> , <@cFileName> , <@cExtension> ) -> NIL
hb_FNameSplit(cARQORI,@cCAMINHO,@cARQUIVO,@cEXTENSAO)
TRY
cEXTMEMO := hb_rddInfo(RDDI_MEMOEXT)  //a extensao do origem memo do destino vem com ponto
END
TRY
cEXTINDEX := hb_rddInfo(RDDI_ORDBAGEXT)
END
//melhorar antes da busca do dbf escolher rdd
//como o rdddefault esta leto nao tras as extensoes
//antes do connection setar novamente rdddefault leto
//usando exensoes dbfcdx por horan
// tipodbfesc tem as extensao memo e indices no menu
IF EMPTY(cEXTMEMO)
   cEXTMEMO := ".FPT"
ENDIF
IF EMPTY(cEXTINDEX)
   cEXTINDEX := ".CDX"
ENDIF
if at(".",cEXTENSAO)=0
   cEXTENSAO:="."+cEXTENSAO
endif
//*.dbf, *.fpt, *.dbt, *.smt
//.CDX, .IDX, .MDX, .NTX, .NDX
nConnect := leto_conexao(cSrvAddr)
IF nConnect >= 0
   iF leto_File(cARQUIVO+cEXTENSAO)
      alert("Arquivo ja existe no servidor"+cARQUIVO)
   else
     IF File(cARQORI)
        Leto_FCopyToSrv(cARQORI,cARQUIVO+cEXTENSAO)
     ENDIF
     IF FILE(cCAMINHO+cARQUIVO+cEXTMEMO)
        Leto_FCopyToSrv(cCAMINHO+cARQUIVO+cEXTMEMO,cARQUIVO+cEXTMEMO)
     ENDIF
     IF FILE(cCAMINHO+cARQUIVO+cEXTINDEX)
        Leto_FCopyToSrv(cCAMINHO+cARQUIVO+cEXTINDEX,cARQUIVO+cEXTINDEX)
     ENDIF
   endif  
   leto_disconnect()
else
   leto_errocon(nConnect)
ENDIF
RETURN .T.


*+--------------------------------------------------------------------
*+
*+
*+
*+    Function LETO_INFO()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
FUNCTION LETO_INFO(cSrvAddr,cLogFile,cOptions)

LOCAL nConnect := leto_conexao()
LOCAL cInfo    := ""
LOCAL cTmp,nTmp

#ifndef __XHARBOUR__   /* there is no useable LETO_UDF :-( */
IF nConnect < 0 .AND. !EMPTY(cSrvAddr)
   nConnect := leto_conexao(cSrvAddr)
ENDIF
#endif

IF nConnect >= 0
   cTmp := leto_udf("OS")
ELSE
   cInfo += "Server revision: "+__SRV_REVISION__+HB_EOL()+HB_EOL()
ENDIF
IF !EMPTY(cTmp) .AND. VALTYPE(cTmp) == "C"
   cInfo := "Server revision: "+__SRV_REVISION__+HB_EOL()+cTmp+HB_EOL()

   cTmp := leto_udf("VERSION") /* Harbour version */
   IF !EMPTY(cTmp) .AND. VALTYPE(cTmp) == "C"
      cInfo += cTmp+HB_EOL()
   ENDIF
   cTmp := leto_udf("HB_VERSION",1) /* C-compiler aka HB_VERSION_COMPILER */
   IF !EMPTY(cTmp) .AND. VALTYPE(cTmp) == "C"
      cInfo += cTmp+HB_EOL()
   ENDIF
   cInfo += HB_EOL()
ENDIF

cInfo += "Client revision: "+__RDD_REVISION__+HB_EOL()+OS()+HB_EOL()
cInfo += VERSION()+HB_EOL()
cTmp  := HB_VERSION(1) /* C-compiler aka HB_VERSION_COMPILER */
IF !EMPTY(cTmp) .AND. VALTYPE(cTmp) == "C"
   cInfo += cTmp+HB_EOL()
ENDIF

IF nConnect >= 0 .AND. !EMPTY(cOptions)
   IF VAL(cOptions) >= 0 .AND. LEFT(cOptions,1) $ "0123456789"
      nTmp := VAL(cOptions)
      //IF leto_mgID() != nTmp /* ele we have just overwritten the log */
      //   cTmp := leto_MgLog(nConnect,nTmp)
      //ELSE
      //   cTmp := ""
      //ENDIF
   ELSE
      nTmp := - 1
      //cTmp := leto_MgLog(nConnect,- 1)
   ENDIF
   IF !EMPTY(cTmp)
      cInfo += "- -[ "+STR(nTmp,4,0)+" ]"+REPL("- ",15)
      cInfo +=+HB_EOL()+cTmp+REPL("- ",42)+HB_EOL()
   ENDIF
ENDIF

cInfo += HB_EOL()

IF !EMPTY(cLogFile) .AND. VALTYPE(cLogFile) == "C"
   IF FILE(cLogFile)
      IF ".gz" $ LOWER(cLogFile)
         cTmp := HB_ZUNCOMPRESS(MEMOREAD(cLogFile))
      ELSE
         cTmp := MEMOREAD(cLogFile)
      ENDIF
      cInfo += cTmp
      IF ".gz" $ LOWER(cLogFile)
         cTmp := HB_GZCOMPRESS(cInfo)
         IF !EMPTY(cTmp)
            MEMOWRIT(cLogFile,cTmp)
         ELSE
            MEMOWRIT(cLogFile+".txt",cInfo)
         ENDIF
      ELSE
         MEMOWRIT(cLogFile,cInfo+MEMOREAD(cLogFile))
      ENDIF
   ELSE
      IF ".gz" $ LOWER(cLogFile)
         cTmp := HB_GZCOMPRESS(cInfo)
         IF !EMPTY(cTmp)
            MEMOWRIT(cLogFile,cTmp)
         ELSE
            MEMOWRIT(cLogFile+".txt",cInfo)
         ENDIF
      ELSE
         MEMOWRIT(cLogFile,cInfo)
      ENDIF
   ENDIF
ELSE
   ALERT(cInfo)
ENDIF

leto_disconnect()

RETURN cInfo




*+--------------------------------------------------------------------
*+
*+
*+
*+    Function leto_tables()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
*+--------------------------------------------------------------------
*+    Function leto_tables()
*+--------------------------------------------------------------------
FUNCTION leto_tables(cSrvAddr, cMASK, lSODBF, lSOSQLITE)

   LOCAL aResult, nChoices, i, aRETU
   LOCAL aAMBIENTE, cDir, cName, cExt
   LOCAL aSqExt := {".SQLITE", ".DB", ".SQLITE3", ".DB3", ".FOSSIL"}

   // Default config conforme especificado
   IF cMASK == NIL;     cMASK := "*.*";      ENDIF
   IF lSODBF == NIL;    lSODBF := .F.;       ENDIF
   IF lSOSQLITE == NIL; lSOSQLITE := .F.;    ENDIF

   nChoices  := 0
   aAMBIENTE := SALVAA()
   aRESULT   := {}

   nConnect := leto_conexao(cSrvAddr)

   IF nConnect >= 0
      aRETU := leto_directory(cMASK) // Busca respeitando a mascara atual

      FOR i := 1 TO Len(aRETU)
         hb_FNameSplit(aRETU[i,1], @cDir, @cName, @cExt)
         cExt := Upper(cExt)

         // Se nenhuma flag for exigida, lista tudo que encontrar na cMASK
         IF !lSODBF .AND. !lSOSQLITE
            AAdd(aRESULT, aRETU[i,1])
         ELSE
            // Se for arquivo de dados DBF e a flag estiver ativada
            IF lSODBF .AND. cExt == "." + Upper(TABLEEXT)
               AAdd(aRESULT, aRETU[i,1])
            ENDIF
            
            // Se for base SQLite (checando vetor) e a flag estiver ativada
            IF lSOSQLITE .AND. AScan(aSqExt, cExt) > 0
               AAdd(aRESULT, aRETU[i,1])
            ENDIF
         ENDIF
      NEXT i

      IF Len(aResult) > 0
         hb_DispBox(3,22,22,55,B_DOUBLE+" ")
         nChoices := AChoice(4,23,21,54,aResult)
      ENDIF
   ELSE
      leto_errocon(nConnect)
   ENDIF

   leto_disconnect()
   RESTAA(aAMBIENTE)

RETURN (iif(nChoices > 0, aResult[nChoices], ""))

*+--------------------------------------------------------------------
*+    Function LETO_USERS()
*+--------------------------------------------------------------------
FUNCTION LETO_USERS(cSrvAddr)
   LOCAL KEY := 0, arr
   LOCAL nConnect := leto_conexao(cSrvAddr)

   IF nConnect >= 0
      WHILE .T.
         hb_DispBox(12,18,19,55,B_DOUBLE+" ")
         @ 12,24 SAY " MENU USUARIOS "
         OPCAO(13,20,"&Add user                  ",65)   // A
         OPCAO(14,20,"&Change password           ",67)   // C
         OPCAO(15,20,"Change &rights             ",82)   // R
         OPCAO(16,20,"&Flush changes             ",70)   // F
         OPCAO(17,20,"&List users                ",76)   // L
         
         KEY := menu(1,0)
         
         DO CASE
         CASE KEY = 1
            IF( arr := Leto_GetUser( .T., .T. ) ) != Nil
               IF leto_useradd( arr[ 1 ], arr[ 2 ], arr[ 3 ] )
                  MDT( "User is added" )
               ELSE
                  MDT( "User is not added" )
               ENDIF
            ELSE
               MDT( "Operation canceled" )
            ENDIF
         CASE KEY = 2
            IF( arr := Leto_GetUser( .T., .F. ) ) != Nil
               IF leto_userpasswd( arr[ 1 ], arr[ 2 ] )
                  MDT( "Password is changed" )
               ELSE
                  MDT( "Password is not changed" )
               ENDIF
            ELSE
               MDT( "Operation canceled" )
            ENDIF
         CASE KEY = 3
            IF( arr := Leto_GetUser( .F., .T. ) ) != Nil
               IF leto_userrights( arr[ 1 ], arr[ 3 ] )
                  MDT( "Rights are changed" )
               ELSE
                  MDT( "Rights are not changed" )
               ENDIF
            ELSE
               MDT( "Operation canceled" )
            ENDIF
         CASE KEY = 4
            leto_userflush()
            MDT( "Flush changes OK" )
         CASE KEY = 5
            Leto_UsersList()
         OTHERWISE
            EXIT
         ENDCASE
      ENDDO
      leto_disconnect()
   ELSE
      leto_errocon(nConnect)
   ENDIF
RETURN .T.

*+--------------------------------------------------------------------
*+
*+    Function Leto_GetUser()
*+
*+--------------------------------------------------------------------
STATIC FUNCTION Leto_GetUser( lPass, lRights )

   LOCAL cUser := Space(15), cPass := Space(15), cRights := ""
   LOCAL cAdmin := "N", cManage := "N", cWrite := "N", cExecute := "N"
   LOCAL cExistingRights

   @ 20, 20 SAY "User name :" GET cUser PICT "@!"
   READ
   
   IF LastKey() == 27
      RETURN NIL
   ENDIF
   
   cUser := AllTrim(cUser)
   IF Empty( cUser )
      RETURN NIL
   ENDIF

   IF lPass
      @ 21, 20 SAY "Password  :" GET cPass 
      READ
      
      IF LastKey() == 27
         RETURN NIL
      ENDIF
      
      cPass := AllTrim(cPass)
      IF Empty( cPass )
         RETURN NIL
      ENDIF
   ENDIF

   IF lRights
      // Busca os direitos atuais do usu·rio utilizando a funÁ„o nativa do rddleto
      cExistingRights := leto_usergetrights( cUser )
      
      // Se retornar uma string v·lida (ex: "YNNN"), preenche as vari·veis de GET
      IF ValType( cExistingRights ) == "C" .AND. Len( cExistingRights ) >= 4
         cAdmin   := SubStr( cExistingRights, 1, 1 )
         cManage  := SubStr( cExistingRights, 2, 1 )
         cWrite   := SubStr( cExistingRights, 3, 1 )
         cExecute := SubStr( cExistingRights, 4, 1 )
      ENDIF

      // Exibe os GETs na tela (estar„o preenchidos com os direitos atuais ou com 'N')
      @ 22, 20 SAY "Admin   (Y/N) :" GET cAdmin   PICT "!" VALID cAdmin   $ "YN"
      @ 23, 20 SAY "Manage  (Y/N) :" GET cManage  PICT "!" VALID cManage  $ "YN"
      @ 24, 20 SAY "Write   (Y/N) :" GET cWrite   PICT "!" VALID cWrite   $ "YN"
      @ 25, 20 SAY "Execute (Y/N) :" GET cExecute PICT "!" VALID cExecute $ "YN"
      READ
      
      IF LastKey() == 27
         RETURN NIL
      ENDIF

      // Monta a string concatenando as respostas para retornar e gravar
      cRights := cAdmin + cManage + cWrite + cExecute
   ENDIF

   // Limpa as linhas de input da tela
   @ 20, 0 CLEAR TO 25, 79 

RETURN { cUser, cPass, cRights }

*+--------------------------------------------------------------------
*+    Function LETO_INFOMENU()
*+--------------------------------------------------------------------
FUNCTION LETO_INFOMENU(cSrvAddr)
   LOCAL KEY := 0
   LOCAL nConnect := leto_conexao(cSrvAddr)

   IF nConnect >= 0
      WHILE .T.
         hb_DispBox(12,18,20,55,B_DOUBLE+" ")
         @ 12,24 SAY " INFORMACOES "
         OPCAO(13,20,"&Basic Info                ",66)   // B
         OPCAO(14,20,"&Tables Info               ",84)   // T
         OPCAO(15,20,"&Locks Info                ",76)   // L
         OPCAO(16,20,"&Ping                      ",80)   // P
         OPCAO(17,20,"&Vars List                 ",86)   // V
         OPCAO(18,20,"&INI Config (letodb.ini)   ",73)   // I
         
         KEY := menu(1,0)
         
         DO CASE
         CASE KEY = 1
            Leto_BasicInfo()
         CASE KEY = 2
            Leto_TablesInfo()
         CASE KEY = 3
            Leto_LocksInfo()
         CASE KEY = 4
            Leto_PingAction()
         CASE KEY = 5
            Leto_VarsList()
         CASE KEY = 6
            Leto_IniList(cSrvAddr)   
         OTHERWISE
            EXIT
         ENDCASE
      ENDDO
      leto_disconnect()
   ELSE
      leto_errocon(nConnect)
   ENDIF
RETURN .T.

*+--------------------------------------------------------------------
*+    Helper: Renderizar a lista usando AChoice salvando o fundo
*+--------------------------------------------------------------------
STATIC FUNCTION ShowInChoice( aList, cTitle )
   LOCAL cTela, nChoices := 0
   IF Len( aList ) > 0
      // Salva a tela abaixo do menu para restauraÁ„o posterior
      cTela := SaveScreen( 4, 9, 23, 71 )
      hb_DispBox( 4, 9, 23, 71, B_DOUBLE+" " )
      @ 4, 12 SAY " " + cTitle + " "
      
      nChoices := AChoice( 5, 10, 22, 70, aList )
      
      // Restaura a tela limpando o AChoice
      RestScreen( 4, 9, 23, 71, cTela )
   ELSE
      MDT( "Nenhum dado encontrado para: " + cTitle )
   ENDIF
RETURN nChoices

*+--------------------------------------------------------------------
*+    Info do Servidor (Basic Info)
*+--------------------------------------------------------------------
STATIC FUNCTION Leto_BasicInfo()
   LOCAL aInfo, aDisp := {}, nSec, nDay, nHour, nTransAll, nTransBad
   IF ( aInfo := leto_MgGetInfo() ) != Nil
      AAdd( aDisp, "Users   current: " + PadL( aInfo[ 1 ], 12 ) + "   Max: " + PadL( aInfo[ 2 ], 12 ) )
      AAdd( aDisp, "Tables  current: " + PadL( aInfo[ 3 ], 12 ) + "   Max: " + PadL( aInfo[ 4 ], 12 ) )
      nSec := Val( aInfo[ 5 ] )
      nDay := Int( nSec / 86400 )
      nHour := Int( ( nSec % 86400 ) / 3600 )
      AAdd( aDisp, "Time elapsed:   " + PadL( LTrim( Str( nDay ) ) + iif( nDay == 1, " day ", " days " ) + ;
         LTrim( Str( nHour ) ) + iif( nHour == 1, " hour ", " hours " ) + ;
         LTrim( Str( Int( ( nSec % 3600 ) / 60 ) ) ) + " min", 15 ) )
      AAdd( aDisp, "Operations:     " + PadL( aInfo[ 6 ], 12 ) )
      AAdd( aDisp, "KBytes sent:    " + PadL( Int( Val( aInfo[ 7 ] ) / 1024 ), 12 ) )
      AAdd( aDisp, "KBytes read:    " + PadL( Int( Val( aInfo[ 8 ] ) / 1024 ), 12 ) )
      IF !Empty( aInfo[ 14 ] )
         nTransAll := Val( aInfo[ 14 ] )
         nTransBad := nTransAll - Val( aInfo[ 15 ] )
         AAdd( aDisp, "Transactions All:" + Str( nTransAll, 11 ) + "   Bad: " + Str( nTransBad, 12 ) )
      ENDIF
      AAdd( aDisp, "Waiting current:" + PadL( aInfo[ 13 ], 12 ) + "   Max: " + PadL( aInfo[ 12 ], 12 ) )
      
      ShowInChoice( aDisp, "Server Basic Info" )
   ELSE
      MDT("Erro ao obter Info")
   ENDIF
RETURN .T.

*+--------------------------------------------------------------------
*+    Lista de Usu·rios no Banco (Users Info)
*+--------------------------------------------------------------------
STATIC FUNCTION Leto_UsersList()
   LOCAL aInfo, aDisp := {}, i
   IF ( aInfo := leto_MgGetUsers() ) != Nil
      FOR i := 1 TO Len( aInfo )
         // aInfo[2] Nome, aInfo[3] Tipo, aInfo[4] Direitos, aInfo[5] Tempo Conectado
         AAdd( aDisp, PadR( aInfo[ i, 2 ], 15 ) + " | " + ;
                      PadR( aInfo[ i, 3 ], 18 ) + " | " + ;
                      PadR( aInfo[ i, 4 ], 18 ) + " | " + ;
                      PadL( LTrim( Str( Int( ( Val( aInfo[ i, 5 ] ) % 86400 ) / 3600 ) ) ), 2, '0' ) + ":" + ;
                      PadL( LTrim( Str( Int( ( Val( aInfo[ i, 5 ] ) % 3600 ) / 60 ) ) ), 2, '0' ) + ":" + ;
                      PadL( LTrim( Str( Int( Val( aInfo[ i, 5 ] ) % 60 ) ) ), 2, '0' ) )
      NEXT
      ShowInChoice( aDisp, "Users List (Name | Type | Rights | Time)" )
   ELSE
      MDT("Nenhum usuario listado")
   ENDIF
RETURN .T.

*+--------------------------------------------------------------------
*+    Tabelas Abertas (Tables Info)
*+--------------------------------------------------------------------
STATIC FUNCTION Leto_TablesInfo()
   LOCAL aInfo, aDisp := {}, i
   IF ( aInfo := leto_MgGetTables() ) != Nil
      FOR i := 1 TO Len( aInfo )
         AAdd( aDisp, aInfo[ i, 2 ] )
      NEXT
      ShowInChoice( aDisp, "Tables Info" )
   ELSE
      MDT("Erro ao obter Tabelas")
   ENDIF
RETURN .T.

*+--------------------------------------------------------------------
*+    Locks de Registros (Locks Info)
*+--------------------------------------------------------------------
STATIC FUNCTION Leto_LocksInfo()
   LOCAL aInfo, aDisp := {}, i
   IF ( aInfo := leto_MgGetLocks() ) != Nil
      FOR i := 1 TO Len( aInfo )
         AAdd( aDisp, PadR( aInfo[ i, 1 ], 35 ) + aInfo[ i, 2 ] )
      NEXT
      ShowInChoice( aDisp, "Locks Info" )
   ELSE
      MDT("Nenhum lock encontrado")
   ENDIF
RETURN .T.

*+--------------------------------------------------------------------
*+    Ping no Servidor (Ping)
*+--------------------------------------------------------------------
STATIC FUNCTION Leto_PingAction()
   IF leto_Ping()
      MDT("Ping: OK - Resposta recebida")
   ELSE
      MDT("Ping: No answer - Sem resposta")
   ENDIF
RETURN .T.

*+--------------------------------------------------------------------
*+    Variaveis e Estatisticas (Vars List)
*+--------------------------------------------------------------------
STATIC FUNCTION Leto_VarsList()
   LOCAL arr, arr1, i, j, aDisp := {}
   IF ( arr := leto_varGetlist() ) != Nil
      FOR i := 1 TO Len( arr )
         AAdd( aDisp, "[Grupo: " + arr[ i ] + "]" )
         arr1 := leto_varGetlist( arr[ i ] )
         FOR j := 1 TO Len( arr1 )
            AAdd( aDisp, "   Var: " + arr1[ j ] )
         NEXT
         arr1 := leto_varGetlist( arr[ i ], 8 ) // Busca as estatisticas da var
         FOR j := 1 TO Len( arr1 )
            // Transformando em string para garantir formataÁ„o no vetor
            AAdd( aDisp, "   " + arr1[ j, 1 ] + ": " + LTrim(Str(arr1[ j, 2 ])) )
         NEXT
         AAdd( aDisp, "-------------------------------------")
      NEXT
      ShowInChoice( aDisp, "Variables List" )
   ELSE
      MDT("Erro reading variables list")
   ENDIF
RETURN .T.


*+--------------------------------------------------------------------
*+    Function LETO_SQLITEMENU()
*+--------------------------------------------------------------------
FUNCTION LETO_SQLITEMENU(cSrvAddr)
   LOCAL KEY := 0
   LOCAL nConnect := leto_conexao(cSrvAddr)

   IF nConnect >= 0
      WHILE .T.
         hb_DispBox(12,18,20,55,B_DOUBLE+" ")
         @ 12,24 SAY " MENU SQLITE "
         OPCAO(13,20,"C&riar base                ",82)   // R
         OPCAO(14,20,"&Copiar base (Loc->Srv)    ",67)   // C
         OPCAO(15,20,"Copiar &do servidor        ",68)   // D
         OPCAO(16,20,"&Listar bases SQLite       ",76)   // L
         OPCAO(17,20,"&Excluir base SQLite       ",69)   // E
         OPCAO(18,20,"&Importar DBF p/ SQLite    ",73)   // I
         
         KEY := menu(1,0)
         
         DO CASE
         CASE KEY = 1
            Leto_SQLTCriar(cSrvAddr)
         CASE KEY = 2
            Leto_SQLTCopiar(cSrvAddr)
         CASE KEY = 3
            Leto_SQLTCopiarSrv(cSrvAddr)
         CASE KEY = 4
            Leto_SQLTListar(cSrvAddr)
         CASE KEY = 5
            Leto_SQLTExcluir(cSrvAddr)
        CASE KEY = 6
            Leto_SQLTImportDBF(cSrvAddr)    
         OTHERWISE
            EXIT
         ENDCASE
      ENDDO
      leto_disconnect()
   ELSE
      leto_errocon(nConnect)
   ENDIF
RETURN .T.

*+--------------------------------------------------------------------
*+    Sub-rotina 4: Listar Bases SQLite no Servidor
*+--------------------------------------------------------------------
STATIC FUNCTION Leto_SQLTListar(cSrvAddr)
   LOCAL cArqSrv

   // Chama a funcao leto_tables ativando apenas o filtro SQLite (lSOSQLITE = .T.)
   // Ela se encarrega de desenhar o AChoice e aguardar a selecao
   cArqSrv := leto_tables(cSrvAddr, "*.*", .F., .T.)

   // Se o usuario selecionou alguma base em vez de pressionar Esc
   IF !Empty(cArqSrv)
      MDT("Base selecionada: " + cArqSrv)
   ENDIF

RETURN NIL

*+--------------------------------------------------------------------
*+    Sub-rotina 5: Excluir Base SQLite no Servidor
*+--------------------------------------------------------------------
STATIC FUNCTION Leto_SQLTExcluir(cSrvAddr)
   LOCAL cArqSrv, nConnect

   // Usa leto_tables para listar apenas SQLite para escolha
   cArqSrv := leto_tables(cSrvAddr, "*.*", .F., .T.)

   // Se o usuario confirmou uma selecao
   IF !Empty(cArqSrv)
      // Pede a confirmacao usando a funcao MDG padrao do sistema
      IF MDG('Excluir ' + cArqSrv + ' ?')
         
         nConnect := leto_conexao(cSrvAddr)
         IF nConnect >= 0
            // Deleta o arquivo selecionado
            Leto_FERASE(cArqSrv, cArqSrv)
            
            MDT("Base " + cArqSrv + " excluida com sucesso.")
            leto_disconnect()
         ELSE
            leto_errocon(nConnect)
         ENDIF

      ENDIF
   ENDIF
   
RETURN NIL

*+--------------------------------------------------------------------
*+    Sub-rotina 1: Criar Base SQLite no Servidor
*+--------------------------------------------------------------------
STATIC FUNCTION Leto_SQLTCriar(cSrvAddr)
   LOCAL cNome := Space(30), hDb
   LOCAL nConnect
   
   @ 18, 20 SAY "Nome do arquivo :" GET cNome PICT "@!"
   READ
   
   IF LastKey() == 27
      @ 18, 0 CLEAR TO 18, 79
      RETURN NIL
   ENDIF
   
   cNome := AllTrim(cNome)
   IF Empty(cNome)
      @ 18, 0 CLEAR TO 18, 79
      RETURN NIL
   ENDIF

   // Adiciona a extensao padrao caso falte
   IF At(".", cNome) == 0
      cNome += ".sqlite"
   ENDIF

   nConnect := leto_conexao(cSrvAddr)
   IF nConnect >= 0
      // Checa pelo arquivo conforme test_sqlt_1
      IF leto_file(cNome)
         MDT("Arquivo ja existe no servidor: " + cNome)
      ELSE
         // Cria a base
         hDb := leto_sqlt_Create( cNome )
         IF Empty(hDb)
            MDT("Falha: nao foi possivel criar a base.")
         ELSE
            leto_sqlt_Close( hDb ) // Fecha apos instanciar o arquivo zerado
            MDT("Base criada com sucesso.")
         ENDIF
      ENDIF
      leto_disconnect()
   ELSE
      leto_errocon(nConnect)
   ENDIF
   
   @ 18, 0 CLEAR TO 18, 79 // Limpa barra de interacao
RETURN NIL

*+--------------------------------------------------------------------
*+    Sub-rotina 2: Copiar Base (Local para o Servidor)
*+--------------------------------------------------------------------
STATIC FUNCTION Leto_SQLTCopiar(cSrvAddr)
   LOCAL cFileName, cDir := "", cName := "", cExt := ""
   LOCAL nConnect
   
   // Selecionador de arquivos com mascaras especificas
   cFileName := win_GetOpenFileName(, "SQLite Files", hb_cwd(), "SQLite", ;
      { { 'SQLite', '*.sqlite' }, { 'SQLite db', '*.DB' }, ;
      { 'SQLite3', '*.sqlite3' }, { 'SQLite db3', '*.DB3' }, ;
      { 'SQLite Fossil', '*.fossil' }, { 'All Files', '*.*' } }, 1 )

   IF !Empty(cFileName) .AND. File(cFileName)
      hb_FNameSplit(cFileName, @cDir, @cName, @cExt)
      IF At(".", cExt) == 0
         cExt := "." + cExt
      ENDIF
      
      // Abre a conexao e aplica logica identica ao LETO_DBFSRV
      nConnect := leto_conexao(cSrvAddr)
      IF nConnect >= 0
         IF leto_File( cName + cExt )
            MDT("Arquivo ja existe no servidor: " + cName + cExt)
         ELSE
            Leto_FCopyToSrv( cFileName, cName + cExt )
            MDT("Base importada para o servidor com sucesso.")
         ENDIF
         leto_disconnect()
      ELSE
         leto_errocon(nConnect)
      ENDIF
   ENDIF
RETURN NIL

*+--------------------------------------------------------------------
*+    Sub-rotina 3: Copiar Base do Servidor (Srv para Local)
*+--------------------------------------------------------------------
STATIC FUNCTION Leto_SQLTCopiarSrv(cSrvAddr)
   LOCAL cArqSrv, cDestPasta, cDestArquivo
   LOCAL nConnect

   // Chama listagem do servidor bloqueando DBFs e permitindo apenas extensoes SQLite (.T.)
   cArqSrv := leto_tables(cSrvAddr, "*.*", .F., .T.)

   IF !Empty(cArqSrv)
      // Seleciona a pasta de destino usando Try/Catch local
      cDestPasta := SelectFolder("Selecione o destino para: " + cArqSrv, hb_cwd(), .F.)
      
      IF !Empty(cDestPasta)
         nConnect := leto_conexao(cSrvAddr)
         IF nConnect >= 0
            cDestArquivo := cDestPasta + "\" + cArqSrv
            
            // Verifica na maquina do cliente se ira sobrescrever algo
            IF File(cDestArquivo)
               MDT("Arquivo ja existe no destino local.")
            ELSE
               Leto_FCopyFromSrv( cArqSrv, cDestArquivo )
               MDT("Download concluido com sucesso.")
            ENDIF
            leto_disconnect()
         ELSE
            leto_errocon(nConnect)
         ENDIF
      ENDIF
   ENDIF
RETURN NIL


*+--------------------------------------------------------------------
*+    Function LETO_DBFMENU()
*+--------------------------------------------------------------------
FUNCTION LETO_DBFMENU(cSrvAddr)
   LOCAL KEY := 0

   WHILE .T.
      hb_DispBox(12,18,19,55,B_DOUBLE+" ")
      @ 12,24 SAY " MENU DBF "
      OPCAO(13,20,"&Tabelas (Listar)          ",84)   // T
      OPCAO(14,20,"&Importar DBF              ",73)   // I
      OPCAO(15,20,"&Exportar DBF              ",69)   // E
      OPCAO(16,20,"&Apagar Tabela             ",65)   // A
      OPCAO(17,20,"E&xportar Formatos         ",88)   // X
      
      KEY := menu(1,0)
      
      DO CASE
      CASE KEY = 1
         // Passando mascara, lSODBF = .T., lSOSQLITE = .F.
         LETO_tables(cSrvAddr, "*."+TABLEEXT, .T., .F.)
      CASE KEY = 2
         LETO_DBFTOSRV(cSrvAddr)
      CASE KEY = 3
         LETO_SRVTODBF(cSrvAddr)
      CASE KEY = 4
         LETO_DELDBF(cSrvAddr)
      CASE KEY = 5
         leto_expformat(cSrvAddr)
      OTHERWISE
         EXIT
      ENDCASE
   ENDDO
RETURN .T.


*+--------------------------------------------------------------------
*+    Function LETO_GESTAOMENU()
*+--------------------------------------------------------------------
FUNCTION LETO_GESTAOMENU(cSrvAddr)
   LOCAL KEY := 0
   LOCAL nConnect := leto_conexao(cSrvAddr)

   IF nConnect >= 0
      WHILE .T.
         hb_DispBox(12,18,19,55,B_DOUBLE+" ")
         @ 12,24 SAY " MENU GESTAO "
         OPCAO(13,20,"&Lock/Unlock (Conexoes)    ",76)   // L
         OPCAO(14,20,"&Disconnect user (Kill)    ",68)   // D
         OPCAO(15,20,"&Backup Geral (Srv ZIP)    ",66)   // B
         OPCAO(16,20,"Backup Local (C&li ZIP)    ",76)   // L
         OPCAO(17,20,"&Skip Buffer (Otimizacao)  ",83)   // S
         KEY := menu(1,0)
         
         DO CASE
         CASE KEY = 1
            Leto_ToggleLock()
         CASE KEY = 2
            Leto_KillUser()
         CASE KEY = 3
            Leto_ServerBackup(cSrvAddr)   
         CASE KEY = 4
            Leto_ClientBackup(cSrvAddr) 
         CASE KEY = 5
            Leto_ConfigSkipBuffer()      
         OTHERWISE
            EXIT
         ENDCASE
      ENDDO
      leto_disconnect()
   ELSE
      leto_errocon(nConnect)
   ENDIF
RETURN .T.

*+--------------------------------------------------------------------
*+    Sub-rotina: Configurar Skip Buffer (Leitura em Lote)
*+--------------------------------------------------------------------
STATIC FUNCTION Leto_ConfigSkipBuffer()
   LOCAL nSize := 10 // Valor padrao do LetoDB[cite: 33]
   LOCAL nStat := 0

   // Tenta pegar a estatistica atual sem quebrar caso nao tenha workarea aberta
   TRY
      nStat := LETO_SETSKIPBUFFER() //[cite: 33]
   CATCH
      nStat := 0
   END

   // Exibe a estatistica na tela e pede o novo valor
   @ 20, 20 SAY "Estatistica Atual: " + LTrim(Str(nStat)) 
   @ 21, 20 SAY "Tamanho (Registros):" GET nSize PICT "99999"
   READ

   IF LastKey() != 27 .AND. nSize > 0
      TRY
         LETO_SETSKIPBUFFER( nSize ) //[cite: 33]
         MDT( "Skip Buffer ajustado para " + LTrim(Str(nSize)) + " registros." )
      CATCH
         MDT( "Aviso: Nenhuma tabela (Workarea) ativa no momento." )
      END
   ENDIF
   
   // Limpa as linhas de input da tela
   @ 20, 0 CLEAR TO 21, 79 

RETURN NIL

*+--------------------------------------------------------------------
*+    Sub-rotina: Lock/Unlock (Bloquear novas conexoes)
*+--------------------------------------------------------------------
STATIC FUNCTION Leto_ToggleLock()
   STATIC lLocked := .F. // Mantem o estado na sessao

   IF MDG( iif( lLocked, "Unlock server (Permitir conexoes)?", "Lock server (Bloquear conexoes)?" ) )
      IF leto_LockConn( !lLocked )
         lLocked := !lLocked
         MDT( iif( lLocked, "Servidor BLOQUEADO para novas conexoes.", "Servidor DESBLOQUEADO." ) )
      ELSE
         MDT( "Falha ao alterar estado do servidor." )
      ENDIF
   ENDIF
RETURN NIL

*+--------------------------------------------------------------------
*+    Sub-rotina: Disconnect/Kill User (Derrubar conexao especifica)
*+--------------------------------------------------------------------
STATIC FUNCTION Leto_KillUser()
   LOCAL aInfo, aDisp := {}, aIds := {}, nChoice, i

   // Busca a lista de usuarios ativos no servidor
   IF ( aInfo := leto_MgGetUsers() ) != Nil .AND. Len(aInfo) > 0
      
      // Monta os arrays de exibicao e o array paralelo de IDs
      FOR i := 1 TO Len( aInfo )
         // aInfo[i,1] contem o ID necessario para a exclusao
         AAdd( aIds, aInfo[ i, 1 ] )
         
         // aInfo[2] Nome, aInfo[3] Tipo
         AAdd( aDisp, PadR( aInfo[ i, 2 ], 15 ) + " | " + aInfo[ i, 3 ] )
      NEXT

      // Usa a funcao auxiliar que ja criamos para exibir em AChoice
      nChoice := ShowInChoice( aDisp, "Selecione o usuario para derrubar" )

      IF nChoice > 0
         IF MDG( "Really kill " + AllTrim(aInfo[nChoice, 2]) + " ?" )
            // Passa o ID do usuario para a funcao leto_mgKill
            leto_mgKill( aIds[nChoice] )
            MDT( "Comando de desconexao enviado." )
         ENDIF
      ENDIF

   ELSE
      MDT("Nenhum usuario conectado ou erro ao listar.")
   ENDIF

RETURN NIL

*+--------------------------------------------------------------------
*+    Sub-rotina: Backup Geral (Zipar via Servidor e Salvar Local)
*+--------------------------------------------------------------------
STATIC FUNCTION Leto_ServerBackup(cSrvAddr)
   LOCAL cDestPasta, cDestArquivo, cArqSrv := ""
   LOCAL cExtTable := "", cExtMemo := "", cExtIndex := ""
   LOCAL aMasks := {}
   LOCAL nConnect, cRetorno

   TRY
      cExtTable := hb_rddInfo(RDDI_TABLEEXT)
   CATCH
   END
   TRY
      cExtMemo := hb_rddInfo(RDDI_MEMOEXT)
   CATCH
   END
   TRY
      cExtIndex := hb_rddInfo(RDDI_ORDBAGEXT)
   CATCH
   END

   IF Empty(cExtTable); cExtTable := ".DBF"; ENDIF
   IF Empty(cExtMemo);  cExtMemo  := ".FPT"; ENDIF
   IF Empty(cExtIndex); cExtIndex := ".CDX"; ENDIF

   IF At(".", cExtTable) == 0; cExtTable := "." + cExtTable; ENDIF
   IF At(".", cExtMemo)  == 0; cExtMemo  := "." + cExtMemo;  ENDIF
   IF At(".", cExtIndex) == 0; cExtIndex := "." + cExtIndex; ENDIF

   AAdd(aMasks, "*" + cExtTable)
   AAdd(aMasks, "*" + cExtMemo)
   AAdd(aMasks, "*" + cExtIndex)
   AAdd(aMasks, "*.sqlite")
   AAdd(aMasks, "*.db")
   AAdd(aMasks, "*.db3")
   AAdd(aMasks, "*.fossil")

   cDestPasta := SelectFolder("Selecione a pasta local para salvar o backup", hb_cwd(), .F.)
   
   IF !Empty(cDestPasta)
      nConnect := leto_conexao(cSrvAddr)
      
      IF nConnect >= 0
         MDT("Gerando ZIP no servidor. Isso pode demorar, aguarde...")
         
         cRetorno := leto_udf("leto_Zip", "", aMasks, 9, .T., , , , .F.)
         
         IF ValType(cRetorno) == "C" .AND. !Empty(cRetorno)
            cArqSrv := cRetorno
            cDestArquivo := cDestPasta + "\bkp_" + DToS(Date()) + "_" + StrTran(Time(), ":", "") + ".zip"
            
            IF leto_File( cArqSrv )
               Leto_FCopyFromSrv( cArqSrv, cDestArquivo )
               MDT("Backup concluido com sucesso em: " + cDestArquivo)
               
               // Remove o arquivo temporario do servidor apos o download
               Leto_FErase( cArqSrv )
            ELSE
               MDT("Falha: Arquivo ZIP de backup nao encontrado no servidor.")
            ENDIF
         ELSE
            MDT("Falha ao gerar o arquivo de compactacao no servidor.")
         ENDIF
         
         leto_disconnect()
      ELSE
         leto_errocon(nConnect)
      ENDIF
   ENDIF

Return NIL

*+--------------------------------------------------------------------
*+    Sub-rotina: Backup Local (Copia arq a arq e Zipa no Cliente)
*+--------------------------------------------------------------------
STATIC FUNCTION Leto_ClientBackup(cSrvAddr)
   LOCAL cDestPasta, cDestZip, cArqSrv, cDestArquivo
   LOCAL cExtTable := "", cExtMemo := "", cExtIndex := ""
   LOCAL aMasks := {}, aServerFiles := {}, aLocalFiles := {}
   LOCAL aDirRes
   LOCAL nConnect, i, j

   // 1. Captura as extensoes da RDD atual
   TRY
      cExtTable := hb_rddInfo(RDDI_TABLEEXT)
   CATCH
   END
   TRY
      cExtMemo := hb_rddInfo(RDDI_MEMOEXT)
   CATCH
   END
   TRY
      cExtIndex := hb_rddInfo(RDDI_ORDBAGEXT)
   CATCH
   END

   // Aplica os padroes (dbf, fpt, cdx) caso a RDD nao retorne nada
   IF Empty(cExtTable); cExtTable := ".DBF"; ENDIF
   IF Empty(cExtMemo);  cExtMemo  := ".FPT"; ENDIF
   IF Empty(cExtIndex); cExtIndex := ".CDX"; ENDIF

   // Garante que todas possuem o ponto '.'
   IF At(".", cExtTable) == 0; cExtTable := "." + cExtTable; ENDIF
   IF At(".", cExtMemo)  == 0; cExtMemo  := "." + cExtMemo;  ENDIF
   IF At(".", cExtIndex) == 0; cExtIndex := "." + cExtIndex; ENDIF

   // 2. Monta o vetor de mascaras
   AAdd(aMasks, "*" + cExtTable)
   AAdd(aMasks, "*" + cExtMemo)
   AAdd(aMasks, "*" + cExtIndex)
   AAdd(aMasks, "*.sqlite")
   AAdd(aMasks, "*.db")
   AAdd(aMasks, "*.db3")
   AAdd(aMasks, "*.fossil")

   // 3. Pede para o usuario escolher a pasta local de destino
   cDestPasta := SelectFolder("Selecione a pasta local para salvar e zipar", hb_cwd(), .F.)
   
   IF !Empty(cDestPasta)
      nConnect := leto_conexao(cSrvAddr)
      
      IF nConnect >= 0
         MDT("Mapeando arquivos no servidor...")
         
         // 4. Mapeia os arquivos no servidor usando as mascaras
         FOR i := 1 TO Len(aMasks)
            aDirRes := leto_directory(aMasks[i])
            FOR j := 1 TO Len(aDirRes)
               // Adiciona o nome do arquivo encontrado na lista final
               AAdd(aServerFiles, aDirRes[j, 1])
            NEXT
         NEXT
         
         IF Len(aServerFiles) > 0
            MDT("Baixando " + LTrim(Str(Len(aServerFiles))) + " arquivos. Aguarde...")
            
            // 5. Copia arquivo a arquivo para a pasta local
            FOR i := 1 TO Len(aServerFiles)
               cArqSrv := aServerFiles[i]
               cDestArquivo := cDestPasta + "\" + cArqSrv
               
               Leto_FCopyFromSrv(cArqSrv, cDestArquivo)
               
               // Guarda o caminho completo do arquivo local para zipar depois
               AAdd(aLocalFiles, cDestArquivo)
            NEXT
            
            MDT("Compactando " + LTrim(Str(Len(aLocalFiles))) + " arquivos localmente...")
            cDestZip := cDestPasta + "\bkp_cli_" + DToS(Date()) + "_" + StrTran(Time(), ":", "") + ".zip"
            
            // 6. Zipa os arquivos localmente na maquina cliente (Nivel 9 = maximo)
            IF hb_ZipFile( cDestZip, aLocalFiles, 9, , .T., , .F., , , .F. )
               
               // 7. Apaga os arquivos soltos que foram baixados
               FOR i := 1 TO Len(aLocalFiles)
                  FErase( aLocalFiles[i] )
               NEXT
               
               MDT("Backup Cliente concluido com sucesso em: " + cDestZip)
            ELSE
               MDT("Erro ao tentar compactar os arquivos localmente.")
            ENDIF
            
         ELSE
            MDT("Nenhum arquivo de dados encontrado no servidor.")
         ENDIF
         
         leto_disconnect()
      ELSE
         leto_errocon(nConnect)
      ENDIF
   ENDIF

RETURN NIL

*+--------------------------------------------------------------------
*+    Sub-rotina 6: Importar DBF para SQLite Remoto
*+--------------------------------------------------------------------
STATIC FUNCTION Leto_SQLTImportDBF(cSrvAddr)
   LOCAL cArqSrv, nConnect, hDb
   LOCAL nOLDTIPO, nORITIPO, cORIDRIVER, lincdados
   LOCAL cARQORI, cPASTA, cOldTipoSQL

   // 1. Escolhe a tabela SQLite no servidor usando leto_tables[cite: 30]
   cArqSrv := leto_tables(cSrvAddr, "*.*", .F., .T.) 

   IF !Empty(cArqSrv)
      nConnect := leto_conexao(cSrvAddr)
      IF nConnect >= 0
         
         // 2. Abre a conexao do banco SQLite via LetoDB
         hDb := leto_sqlt_Open( cArqSrv ) 
         
         IF !Empty(hDb)
            // Esqueleto da interface dbusqlite[cite: 30]
            nOLDTIPO := TIPODBF
            alertX( "escolha origem" )
            tipodbfesc()
            nORITIPO   := TIPODBF
            cORIDRIVER := RDDNOME( TIPODBF )
            lincdados  := mdg("Incluir Dados")

            // Forca o dialeto para SQLite para garantir que funcoes geradoras de metadados 
            // funcionem corretamente durante a importacao
            cOldTipoSQL := cTIPOSQL
            cTIPOSQL    := "SQLITE" 

            IF MDG("Arquivo individual")
               cARQORI := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*."+TABLEEXT, 1 )
               IF File( cARQORI )
                  Leto_export2sql( hDb, cARQORI, lincdados )
               ENDIF
            ELSE
               cPASTA := SelectFolder()
               cPASTA += "\*."+TABLEEXT 
               FAZERDBF( {|| Leto_export2sql( hDb, cCAMINHOCOMPLETO, lincdados ) }, .F., , , cPASTA, .F. )
            ENDIF   
            
            // Retorna o RDD e o Dialeto anteriores
            cTIPOSQL := cOldTipoSQL
            RDDNOME( nOLDTIPO ) 

            // Fecha a base SQLite remota[cite: 25, 30]
            leto_sqlt_Close( hDb ) 
            MDT("Conexao com base SQLite encerrada.")
         ELSE
            MDT("Falha ao abrir base SQLite no servidor LetoDB.")
         ENDIF
         
         leto_disconnect()
      ELSE
         leto_errocon(nConnect)
      ENDIF
   ENDIF

RETURN NIL


*+--------------------------------------------------------------------
*+    Engine: Cria tabela, Ìndices e envia os inserts ao Servidor
*+--------------------------------------------------------------------
STATIC FUNCTION Leto_export2sql( hDb, cDBFFILE, lincdados )
   LOCAL aStruct := {}, i, j, mFldNm, mSql
   LOCAL aRETUMETA, cSqlFields, cSqlIndexes, aMETADBF
   LOCAL cTablename, aINDICES, nIndexes, nLASTREC

   IF Empty(hDb)
      msgstop( "Sem conexao ativa com a base SQLite no LetoDB!" )
      RETURN NIL
   ENDIF
   IF !File( cDBFFILE )
      RETURN NIL
   ENDIF
   IF ValType(lincdados) <> "L"
      lincdados := .T.
   ENDIF

   // Extrai o nome padrao da tabela baseado no arquivo
   cTablename := HB_FNAMENAME(cDBFFILE) 

   // Como e uma importacao via LetoDB e a comunicacao de estruturas complexas na memoria (table info) 
   // pode onerar a rede, adotamos a abordagem direta do DROP IF EXISTS.
   IF MDG( "A tabela " + cTablename + " sera recriada. Continuar?" )
      leto_sqlt_Exec( hDb, "DROP TABLE IF EXISTS " + cTablename ) //[cite: 25, 30]
   ELSE
      RETURN NIL
   ENDIF

   // --- PROCESSAMENTO DE METADADOS (Espelhado do sqlite.prg original) ---
   TRY
      aRETUMETA := GeraSQLMetadata()
      cSqlFields  := aRETUMETA[1] 
      cSqlIndexes := aRETUMETA[2]
      IF !Empty( cSqlFields ); leto_sqlt_Exec( hDb, cSqlFields ); ENDIF //[cite: 25, 30]
      IF !Empty( cSqlIndexes ); leto_sqlt_Exec( hDb, cSqlIndexes ); ENDIF //[cite: 25, 30]
   CATCH
   END

   leto_sqlt_Exec( hDb, "DELETE FROM table_metadata WHERE nome_tabela = " + c2sql(cTablename) ) //[cite: 25, 30]
   leto_sqlt_Exec( hDb, "DELETE FROM index_metadata WHERE nome_tabela = " + c2sql(cTablename) ) //[cite: 25, 30]

   // Abre o DBF para importacao
   dbUseArea( .T., ( RDDNOME(TIPODBF) ), ( cDBFFILE ), , .T., .F. ) 
   aStruct := dbStruct()

   // Grava metadata do dbf[cite: 28]
   TRY
      aMETADBF := GeradbfSchema( cTablename, aStruct )
      FOR j := 1 TO LEN(aMETADBF)
          leto_sqlt_Exec( hDb, aMETADBF[j] ) //[cite: 25, 30]
      NEXT j
   CATCH
   END

   // --- CRIACAO DA TABELA E INDICES NO LETODB ---
   mSQL := SqliteCreateTable( cTablename, aStruct, "SQLITE" )
   IF leto_sqlt_Exec( hDb, mSql ) != 0 //[cite: 25, 30]
      alertx( 'Table Creation Error no LetoDB!', 'DBF2SQLite' )
      MemoWrit( "sql_create_" + cTablename + ".txt", msql )
      dbCloseArea()
      RETURN NIL
   ENDIF

   aINDICES := GeraINDICES(cTABLENAME)
   nIndexes := LEN(aINDICES)
   FOR j := 1 TO nIndexes
      // Envia o Create index
      leto_sqlt_Exec( hDb, aINDICES[j, 1] ) //[cite: 25, 30]
      // Envia os metadados do indice
      leto_sqlt_Exec( hDb, aINDICES[j, 2] ) //[cite: 25, 30]
   NEXT j

   // --- TRANSFERENCIA DE DADOS (TRANSACTION) ---
// --- TRANSFERENCIA DE DADOS (TRANSACTION) ---
   IF lincdados
      nLASTREC := RecCount() 
      zei_fort( nLASTREC,,, 0 )
      dbGoTop()
      
      nCont := 0 // Inicializa o contador

      // Inicia bloco transacional direto na memoria do servidor SQLite
      IF leto_sqlt_Exec( hDb, 'BEGIN TRANSACTION;' ) != 0 //
         dbCloseArea()
         RETURN NIL
      ENDIF
      
      DO WHILE !Eof()
         zei_fort( nLASTREC,,, 1 )

         mSql := "INSERT INTO " + cTablename + " VALUES ("
         FOR i := 1 TO Len( aStruct )
            mFldNm := aStruct[ i, 1 ] //[cite: 32]
            IF i > 1
               mSql += ", "
            ENDIF
            mSql += c2sql( &mFldNm ) // Usa a global c2sql para sanitizar dados[cite: 32]
         NEXT
         mSql += ")"
         
         IF leto_sqlt_Exec( hDb, mSql ) != 0 //[cite: 32]
            alertx( "Problem in Query: " + mSql )
            EXIT
         ENDIF
         
         nCont++
         
         // Bloco de Commit em lote (Bulk Insert) a cada 500 registros
         IF nCont % 500 == 0
            leto_sqlt_Exec( hDb, 'COMMIT;' )
            leto_sqlt_Exec( hDb, 'BEGIN TRANSACTION;' )
         ENDIF

         dbSkip()
      ENDDO
      
      // Garante o commit dos registros residuais (que nao fecharam o lote exato de 500)
      leto_sqlt_Exec( hDb, 'COMMIT;' ) //[cite: 32]
   ENDIF
   
   dbCloseArea()
   MDT( "Tabela " + cTablename + " importada com sucesso para o LetoDB!" )

RETURN NIL

*+--------------------------------------------------------------------
*+    Exibe as configuracoes do letodb.ini
*+--------------------------------------------------------------------
STATIC FUNCTION Leto_IniList(cSrvAddr)
   LOCAL cTempFile := "temp_leto.ini"
   LOCAL cIniData, aIni, aDisp := {}, i, j
   
   // Tenta buscar o arquivo letodb.ini do servidor remotamente
   cIniData := leto_MemoRead( cSrvAddr + "letodb.ini" )
   
   // Fallback: Tenta ler localmente se falhar a leitura remota
   IF Empty( cIniData )
      IF File( "letodb.ini" )
         cIniData := MemoRead( "letodb.ini" )
      ELSE
         MDT("Erro: letodb.ini nao encontrado no servidor nem localmente.")
         RETURN .F.
      ENDIF
   ENDIF
   
   // Grava em arquivo temporario para o RDINI (que usa FOPEN local) processar
   MemoWrit( cTempFile, cIniData )
   
   aIni := RDINI( cTempFile ) //[cite: 18]
   
   IF !Empty( aIni )
      FOR i := 1 TO Len( aIni )
         AAdd( aDisp, "[" + aIni[i, 1] + "]" )
         FOR j := 1 TO Len( aIni[i, 2] )
            AAdd( aDisp, "   " + PadR( aIni[i, 2, j, 1], 20 ) + " = " + aIni[i, 2, j, 2] )
         NEXT
         AAdd( aDisp, "-------------------------------------" )
      NEXT
      ShowInChoice( aDisp, "letodb.ini (Chaves e Valores)" )
   ELSE
      MDT("Erro ao processar o letodb.ini ou arquivo vazio.")
   ENDIF
   
   // Limpeza
   FErase( cTempFile )
   
RETURN .T.


*+--------------------------------------------------------------------
*+    Rotinas originais do Harbour Project para leitura de INI
*+--------------------------------------------------------------------
#define STR_BUFLEN  1024

STATIC FUNCTION RDINI( fname )
LOCAL han, stroka, strfull, poz1, vname, arr
LOCAL strbuf := Space(STR_BUFLEN), poz := STR_BUFLEN+1

   IF ( han := FOPEN( fname, FO_READ + FO_SHARED ) ) != - 1 //[cite: 18]
      arr := {}
      strfull := ""
      DO WHILE .T.
         IF LEN( stroka := RDSTR( han,@strbuf,@poz,STR_BUFLEN ) ) = 0
            EXIT
         ENDIF
         IF Right( stroka,1 ) == '&'
            strfull += Left( stroka,Len(stroka)-1 )
            LOOP
         ELSE
            IF !Empty( strfull )
               stroka := strfull + stroka
            ENDIF
            strfull := ""
         ENDIF
         
         IF Left( stroka,1 ) == "["
            stroka := UPPER( SUBSTR( stroka, 2, AT( "]", stroka ) - 2 ) )
            AADD( arr, { stroka, {} } )
         ELSEIF Left( stroka,1 ) <> ";"
            poz1 := AT( "=", stroka )
            IF poz1 != 0
               IF Empty( arr )
                  AADD( arr, { "MAIN", {} } )
               ENDIF
               vname  := RTRIM( LEFT( stroka, poz1 - 1 ) )
               stroka := ALLTRIM( SUBSTR( stroka, poz1 + 1 ) )
               AADD( arr[ LEN( arr ), 2 ], { UPPER( vname ), stroka } )
            ENDIF           
         ENDIF
      ENDDO
      FCLOSE( han )
   ENDIF

RETURN arr

STATIC FUNCTION RDSTR( han, strbuf, poz, buflen )
LOCAL stro := "", rez, oldpoz, poz1
      oldpoz := poz
      poz    := AT( CHR( 10 ), SUBSTR( strbuf, poz ) )
      IF poz = 0
         IF han <> Nil
            stro += SUBSTR( strbuf, oldpoz )
            rez  := FREAD( han, @strbuf, buflen ) //[cite: 18]
            IF rez = 0
               RETURN ""
            ELSEIF rez < buflen
               strbuf := SUBSTR( strbuf, 1, rez ) + CHR( 10 ) + CHR( 13 )
            ENDIF
            poz  := AT( CHR( 10 ), strbuf )
            stro += SUBSTR( strbuf, 1, poz )
         ELSE
            stro += Rtrim( SUBSTR( strbuf, oldpoz ) )
            poz  := oldpoz + Len( stro )
            IF Len( stro ) == 0
               RETURN ""
            ENDIF
         ENDIF
      ELSE
         stro += SUBSTR( strbuf, oldpoz, poz )
         poz  += oldpoz - 1
      ENDIF
      poz ++
   poz1 := LEN( stro )
   IF poz1 > 2 .AND. RIGHT( stro, 1 ) $ CHR( 13 ) + CHR( 10 )
      IF SUBSTR( stro, poz1 - 1, 1 ) $ CHR( 13 ) + CHR( 10 )
         poz1 --
      ENDIF
      stro := SUBSTR( stro, 1, poz1 - 1 )
   ENDIF
RETURN stro

/*
private Mydbf:="//127.0.0.1:2812/\Testdbf.dbf"
private cfilter:='FIELD1="ABC"'
dbCreate( Mydbf , { {"FIELD1","C",3,0} } , "LETO" )
dbUsearea( .F. , "LETO" , Mydbf , NIL , .T. , .F. )
dbSetfilter( {|| &cfilter } , cfilter )
dbclearfilter()
dbclosearea()


Local cPATH := "//localhost:2812/" //n∆o precisa informar o caminho dos DBFÔs porque j† foi informado(configurado) no arquivo leotdb. ini
usando setrdddefault() nao precisaou do path

cIndex  := cPATH+"meu_arquivo.cdx"

cDbf := cPATH+"meu_aquivo.dbf"

DbUseArea(.t.,'LETO',cDbf,"alias_xyz",.T.,.F.,'PTISO')
If leto_file(cIndex)
   DBSETINDEX( cIndex )
Else
   index on ...//seu c¢digo
   index on ... //seu c¢digo
EndIf


*/


*+ EOF: dbuleto.prg
*+
