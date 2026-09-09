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
FUNCTION letomenu()


LOCAL aAMBIENTE

cTIPOSQL := "LETO"  // Passa para privada usadas nas funcoes aBaixo

aAMBIENTE  := SALVAA()
cSERVERX   := PADR("//127.0.0.1:2812/",30," ")
cDATABASEX := Space(30)
cUSERX     := Space(30)
cPASSX     := Space(30)
cTABELAX   := Space(30)
cBANCOX   := Space(30)
cOWNERX   := Space(30)
cPORTAX    :=SPACE(30)

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
   OPCAO(5,24,"&Tabelas                   ",84)   // T
   OPCAO(6,24,"&Importar  DBF             ",73)   // I
   OPCAO(7,24,"&Exportar  DBF             ",69)   // E
   OPCAO(8,24,"&Apagar Tabela             ",65)   // A
   OPCAO(9,24,"Exportar &Formatos         ",70)   // F
   OPCAO(10,24,"&Usuarios                 ",85)   // U  <- NOVA OPÇÃO
   //opcao backup zip
   KEY := menu(1,0)
   DO CASE
   CASE KEY = 1
      LETO_INFOMENU(cSERVERX)
   CASE KEY = 2
      LETO_tables(cSERVERX)
   CASE KEY = 3
      LETO_DBFTOSRV(cSERVERX)
   CASE KEY = 4
      LETO_SRVTODBF(cSERVERX)
   CASE KEY = 5
      LETO_DELDBF(cSERVERX)
   CASE KEY = 6
      leto_expformat(cSERVERX)
   CASE KEY = 7
      LETO_USERS(cSERVERX)   
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

cARQORI   := LETO_tables(cSERVERX)
cARQUIVO  := TIRAEXT(cARQORI)
cEXTMEMO  := ".FPT"
cEXTINDEX := ".CDX"
nConnect  := LETO_CONNECT(cSrvAddr)
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

cARQORI   := LETO_tables(cSERVERX)
cARQUIVO  := TIRAEXT(cARQORI)
cEXTMEMO  := ".FPT"
cEXTINDEX := ".CDX"
IF MDG('Excluir '+cARQORI)
   nConnect := LETO_CONNECT(cSrvAddr)
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
*+
*+
*+
*+    Function leto_errocon()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
function leto_errocon(nConnect)

LOCAL nRES
IF nConNect == - 1
   nRes := leto_Connect_Err()
   IF nRes == LETO_ERR_LOGIN
      mdt("Falha ao Logar")
   ELSEIF nRes == LETO_ERR_RECV
      mdt("Error ao conectar")
   ELSEIF nRes == LETO_ERR_SEND
      mdt("Erro de envio")
   ELSE
      mdt("NÆo connectado ao servidor: "+cPath)
   ENDIF
ENDIF
RETURN



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

cARQORI  := LETO_tables(cSERVERX)
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
nConnect := LETO_CONNECT(cSrvAddr)
IF nConnect >= 0
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
//*.dbf, *.fpt, *.dbt, *.smt
//.CDX, .IDX, .MDX, .NTX, .NDX
nConnect := LETO_CONNECT(cSrvAddr)
IF nConnect >= 0
   IF File(cARQORI)
      Leto_FCopyToSrv(cARQORI,cARQUIVO+cEXTENSAO)
   ENDIF
   IF FILE(cCAMINHO+cARQUIVO+cEXTMEMO)
      Leto_FCopyToSrv(cCAMINHO+cARQUIVO+cEXTMEMO,cARQUIVO+cEXTMEMO)
   ENDIF
   IF FILE(cCAMINHO+cARQUIVO+cEXTINDEX)
      Leto_FCopyToSrv(cCAMINHO+cARQUIVO+cEXTINDEX,cARQUIVO+cEXTINDEX)
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
*+    Function LETO_INFO()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
FUNCTION LETO_INFO(cSrvAddr,cLogFile,cOptions)

LOCAL nConnect := LETO_CONNECT()
LOCAL cInfo    := ""
LOCAL cTmp,nTmp

#ifndef __XHARBOUR__   /* there is no useable LETO_UDF :-( */
IF nConnect < 0 .AND. !EMPTY(cSrvAddr)
   nConnect := LETO_CONNECT(cSrvAddr)
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
FUNCTION leto_tables(cSrvAddr)


LOCAL aResult,nChoices,I,aRETU
LOCAL aAMBIENTE
nChoices  := 0
aAMBIENTE := SALVAA()
aRESULT   := {}



nConnect := LETO_CONNECT(cSrvAddr)

IF nConnect >= 0

   aRETU := leto_directory("*."+TABLEEXT)

   FOR i := 1 TO Len(aRETU)
      AAdd(aRESULT,aRETU[i,1])
   NEXT i


   IF Len(aResult) > 0
      hb_DispBox(3,22,22,55,B_DOUBLE+" ")
      nChoices := AChoice(4,23,21,54,aResult)
   ENDIF
else
   leto_errocon(nConnect)
endif

leto_disconnect()

RESTAA(aAMBIENTE)

RETURN (iif(nChoices > 0,aResult[nChoices],""))


*+--------------------------------------------------------------------
*+    Function LETO_USERS()
*+--------------------------------------------------------------------
FUNCTION LETO_USERS(cSrvAddr)
   LOCAL nKey := 0, arr
   LOCAL nConnect := LETO_CONNECT(cSrvAddr)

   IF nConnect >= 0
      DO WHILE nKey != 48
         // Aumentando a altura da caixa para caber a nova opção
         hb_DispBox(12,18,20,55,B_DOUBLE+" ")
         @ 12,24 SAY " MENU USUARIOS "
         @ 13,20 SAY "1 Add user"
         @ 14,20 SAY "2 Change password"
         @ 15,20 SAY "3 Change access rights"
         @ 16,20 SAY "4 Flush changes"
         @ 17,20 SAY "5 List users"
         @ 18,20 SAY "0 Exit"
         
         nKey := Inkey( 0 )
         
         IF nKey == 49
            IF( arr := Leto_GetUser( .T., .T. ) ) != Nil
               IF leto_useradd( arr[ 1 ], arr[ 2 ], arr[ 3 ] )
                  MDT( "User is added" )
               ELSE
                  MDT( "User is not added" )
               ENDIF
            ELSE
               MDT( "Operation canceled" )
            ENDIF
         ELSEIF nKey == 50
            IF( arr := Leto_GetUser( .T., .F. ) ) != Nil
               IF leto_userpasswd( arr[ 1 ], arr[ 2 ] )
                  MDT( "Password is changed" )
               ELSE
                  MDT( "Password is not changed" )
               ENDIF
            ELSE
               MDT( "Operation canceled" )
            ENDIF
         ELSEIF nKey == 51
            IF( arr := Leto_GetUser( .F., .T. ) ) != Nil
               IF leto_userrights( arr[ 1 ], arr[ 3 ] )
                  MDT( "Rights are changed" )
               ELSE
                  MDT( "Rights are not changed" )
               ENDIF
            ELSE
               MDT( "Operation canceled" )
            ENDIF
         ELSEIF nKey == 52
            leto_userflush()
            MDT( "Flush changes OK" )
         ELSEIF nKey == 53
            Leto_UsersList()   // <- CHAMADA PARA LISTAR USUÁRIOS
         ENDIF
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
      // Busca os direitos atuais do usuário utilizando a função nativa do rddleto
      cExistingRights := leto_usergetrights( cUser )
      
      // Se retornar uma string válida (ex: "YNNN"), preenche as variáveis de GET
      IF ValType( cExistingRights ) == "C" .AND. Len( cExistingRights ) >= 4
         cAdmin   := SubStr( cExistingRights, 1, 1 )
         cManage  := SubStr( cExistingRights, 2, 1 )
         cWrite   := SubStr( cExistingRights, 3, 1 )
         cExecute := SubStr( cExistingRights, 4, 1 )
      ENDIF

      // Exibe os GETs na tela (estarão preenchidos com os direitos atuais ou com 'N')
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
   LOCAL nKey := 0
   LOCAL nConnect := LETO_CONNECT(cSrvAddr)

   IF nConnect >= 0
      DO WHILE nKey != 48
         hb_DispBox(12,18,20,55,B_DOUBLE+" ")
         @ 12,24 SAY " INFORMACOES "
         @ 13,20 SAY "1 Basic Info"
         @ 14,20 SAY "2 Tables Info"
         @ 15,20 SAY "3 Locks Info"
         @ 16,20 SAY "4 Ping"
         @ 17,20 SAY "5 Vars List"
         @ 18,20 SAY "0 Exit"
         
         nKey := Inkey( 0 )
         
         IF nKey == 49       // Opção 1 - Info Connection
            Leto_BasicInfo()
         ELSEIF nKey == 50   // Opção 2 - Tables
            Leto_TablesInfo()
         ELSEIF nKey == 51   // Opção 3 - Locks
            Leto_LocksInfo()
         ELSEIF nKey == 52   // Opção 4 - Ping
            Leto_PingAction()
         ELSEIF nKey == 53   // Opção 5 - Vars
            Leto_VarsList()
         ENDIF
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
      // Salva a tela abaixo do menu para restauração posterior
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
*+    Lista de Usuários no Banco (Users Info)
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
            // Transformando em string para garantir formatação no vetor
            AAdd( aDisp, "   " + arr1[ j, 1 ] + ": " + LTrim(Str(arr1[ j, 2 ])) )
         NEXT
         AAdd( aDisp, "-------------------------------------")
      NEXT
      ShowInChoice( aDisp, "Variables List" )
   ELSE
      MDT("Erro reading variables list")
   ENDIF
RETURN .T.

/*
private Mydbf:="//127.0.0.1:2812/\Testdbf.dbf"
private cfilter:='FIELD1="ABC"'
dbCreate( Mydbf , { {"FIELD1","C",3,0} } , "LETO" )
dbUsearea( .F. , "LETO" , Mydbf , NIL , .T. , .F. )
dbSetfilter( {|| &cfilter } , cfilter )
dbclearfilter()
dbclosearea()


Local cPATH := "//localhost:2812/" //nÆo precisa informar o caminho dos DBFïs porque j  foi informado(configurado) no arquivo leotdb. ini
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
