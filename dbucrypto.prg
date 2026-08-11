// +--------------------------------------------------------------------
// + requer -lbcrypt no hbp    libbcrypt
// + dbfcdxex https://github.com/carles9000/dbfcdxex
*+
*+--------------------------------------------------------------------
*+


*+--------------------------------------------------------------------
*+
*+    Programa  : crypto.prg
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
// +    Function DBFcryptomenu()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +

#INCLUDE "BOX.CH"

REQUEST DBFCDXEX



FUNCTION DBFcryptomenu()


LOCAL aAMBIENTE

cTIPOSQL := "DBFCDXEX"  // Passa para privada usadas nas funcoes aBaixo

aAMBIENTE  := SALVAA()
cSERVERX   := Space(30)
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

zSENHACDX := INPUTBOX( PADR( zSENHACDX,30 ), "Senha para cryptografia" )
zSENHACDX :=ALLTRIM(zSENHACDX)
USOVIA := "DBFCDXEX"
rddSetDefault("DBFCDXEX")   
DbfcdxexSetup( "aes256", zSENHACDX )



WHILE .T.
   hb_DispBox(3,18,18,55,B_DOUBLE+" ")
   @ 03,24 SAY "Crypto DBF DBFCDXEX"        
   OPCAO(4,24,"&Encryptar                 ",86)   // V
   OPCAO(5,24,"&Descrptar                 ",84)   // T
   OPCAO(6,24,"&Checar                    ",73)   // I
   KEY := menu(1,0)
   DO CASE
   CASE KEY = 1
        DBFcrypto_enc()
   CASE KEY = 2
        DBFcrypto_dec() 
   CASE KEY = 3
        DBFcrypto_check()
   OTHERWISE
      EXIT
   ENDCASE
ENDDO

TIPODBF := nOLDTIPORDD
rddSetDefault(cOLDRDD)
RDDNOME(TIPODBF)

RESTAA(aAMBIENTE)
LAYOUT()

RETURN .T.


function DBFcrypto_enc()
cARQORI    := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*.dbf", 1 )
DbfcdxexSetup( "aes256", zSENHACDX )

 USE ( cARQORI ) VIA "DBFCDXEX" EXCLUSIVE NEW

   IF ! CDXEX_IsTableEncrypted()
      IF CDXEX_EncryptTable()
         MDT("Tabela cryptografada")
      ELSE
         MDT("Erro ao cryptografar")
      ENDIF
   ELSE
       MDT("Tabela ja cryptografada")
   ENDIF
USE
mdt(CDXEX_Info()) 
return


function DBFcrypto_dec()
cARQORI    := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*.dbf", 1 )
DbfcdxexSetup( "aes256", zSENHACDX )

USE ( cARQORI ) VIA "DBFCDXEX" EXCLUSIVE NEW
IF CDXEX_IsTableEncrypted()
   iF CDXEX_DecryptTable()
      MDT("Tabela descryptografada")
   ELSE
      MDT("Erro ao descryptografar")
   ENDIF
ELSE
   MDT("Tabela nao cryptografada")
ENDIF  
mdt(CDXEX_Info()) 
USE
return

function DBFcrypto_check()
cARQORI    := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*.dbf", 1 )
DbfcdxexSetup( "aes256", zSENHACDX )

USE ( cARQORI ) VIA "DBFCDXEX" EXCLUSIVE NEW
IF CDXEX_IsTableEncrypted()
   MDT("Tabela cryptografada")
ELSE
   MDT("Tabela nao cryptografada")
ENDIF
alert(CDXEX_Info())
USE
return

// cARQORI    := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*.dbf", 1 )
  