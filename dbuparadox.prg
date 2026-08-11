*+--------------------------------------------------------------------
*+
*+    Programa  : dbuparadox.prg
*+
*+     Sistema:
*+
*+     Linguagem: Harbour
*+
*+     Autor: jcassiano
*+
*+     Copyright (c) 2024,  jcassiano
*+
*+    Documentado em 6-Jan-2025 as  3:37 pm
*+
*+--------------------------------------------------------------------
*+

#include "BOX.CH"
#include "TRY.CH"
#include "dbstruct.ch"
#include "directry.ch"

REQUEST PXRDD

// +--------------------------------------------------------------------
// +    Function firebirdmenu()
// +--------------------------------------------------------------------
FUNCTION Paradoxmenu()

LOCAL aAMBIENTE
LOCAL KEY



aAMBIENTE  := SALVAA() 
cSERVERX   := Space(30)  // localhost:cARQUIVO no connection
cDATABASEX := Space(30) 
cUSERX     := Space(30) 
cPASSX     := Space(30) 
cTABELAX   := Space(30) 
cBANCOX    := Space(30) 
cOWNERX   :=  Space(30)
cPORTAX    := SPACE(30)
cPATH      := "" 
loledb     := .T. 
lMDB       := .F. 
lACCDB     := .F. 
lFDB       := .T.

cOLDRDD     := RDDSETDEFAULT("") 
nOLDTIPORDD := TIPODBF 
cTIPOSQL := "PARADOX"  // Passa para privada usadas nas funcoes abaixo 


// Busca as credenciais e o caminho do banco dinamicamente via cofre do sistema
//pegcfgbanco() 



WHILE .T.
   hb_DispBox(3,18,18,55,B_DOUBLE+" ") 
   @ 03,24 SAY "PARADOX" 
   
   OPCAO( 4, 24,"&Informacao do db        ",67)   // c 1
   OPCAO( 5, 24,"&Informacao dos campos   ",68 )   // D 2
   OPCAO( 6, 24,"&Exportar  Paradox-->DBF ",84)   // T  3
   OPCAO( 7, 24,"&Exportar  Paradox-->CSV ",73)   // I  4
   OPCAO( 8, 24,"&Importar  DBF-->Paradox ",69)   // E 5
   
   KEY := menu(1,0) 
   DO CASE
     CASE KEY = 1
          cARQORI := win_GetOPENFileName(,"Selecione o arquivo Paradox",,"Arquivo DB|*.db",,"*.db")
     CASE KEY = 2
          cARQORI := win_GetOPENFileName(,"Selecione o arquivo Paradox",,"Arquivo DB|*.db",,"*.db")
     CASE KEY = 3
          paradoxexportadb(1)
     CASE KEY = 4
          paradoxexportadb(2)
     CASE KEY = 5
         paradoximportadbf()
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

FUNCTION paradoxexportadb(nTIPO)
IF nTIPO=1
  nOLDTIPO := TIPODBF
  mdt( "escolha destino" )
  tipodbfesc()
  nORITIPO   := TIPODBF
  cDRIVEDES := RDDNOME( TIPODBF )
  lincdados:=mdg("Incluir Dados")
ENDIF            
            
            IF MDG("Arquivo individual")
                cARQORI := win_GetOPENFileName(,"Selecione o arquivo Paradox",,"Arquivo DB|*.db",,"*.db")
                IF File( cARQORI )
                  IF nTIPO=1
                     paradox_to_dbf(cARQORI,cDRIVEDES,lincdados)
                  ELSE
                     paradox_to_csv(cARQORI,cSEPARADOR)
                  ENDIF   
                ENDIF
            ELSE
               cPASTA:=SelectFolder()
               cPASTA+="\*.db" 
               //FAZERDBF(bUSO                                       , lSHARE[.F.] , bPRE, bPOS, cMASK ,LOPEN )
               IF nTIPO=1
                  FAZERDBF( {|| paradox_to_dbf(cARQORI,cDRIVEDES,lincdados) }, .F. ,     ,     ,cPASTA,.F.)
               ELSE
                  FAZERDBF( {|| paradox_to_csv(cARQORI,cSEPARADOR) }, .F. ,     ,     ,cPASTA,.F.)
               ENDIF   
            ENDIF  
IF nTIPO=1             
   RDDNOME( nOLDTIPO )   // retorna tipo anterior
ENDIF   
RETURN



FUNCTION paradoximportadbf()
  nOLDTIPO := TIPODBF
  mdt( "escolha origem" )
  tipodbfesc()
            nORITIPO   := TIPODBF
            cORIDRIVER := RDDNOME( TIPODBF )
            lincdados:=mdg("Incluir Dados")
            IF MDG("Arquivo individual")
               cARQORI    := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*."+TABLEEXT, 1 )
                IF File( cARQORI )
                   dbf_para_paradox(cARQORI,cORIDRIVER,lincdados)
                ENDIF
            ELSE
               cPASTA:=SelectFolder()
               cPASTA+="\*."+TABLEEXT 
               //FAZERDBF(bUSO                                       , lSHARE[.F.] , bPRE, bPOS, cMASK ,LOPEN )
               FAZERDBF( {|| dbf_para_paradox(cCAMINHOCOMPLETO,cORIDRIVER,lincdados) }, .F. ,     ,     ,cPASTA,.F.)
            ENDIF   
            RDDNOME( nOLDTIPO )   // retorna tipo anterior
RETURN


FUNCTION paradoxexpformat()
   cARQORI := win_GetOPENFileName(,"Selecione o arquivo Paradox",,"Arquivo DB|*.db",,"*.db")
   LCOPIANAT := .F.  // MDG("Copia Nativa(SIM) Interna(NAO)") //copy to nao implemntado mysqlrddd
   tDOC      := pegtipodoc()   // .t. Inclui dbf se for nativa
   pegparexp()
   lDOCCAB   := .F.
   lDOCDAD   := .F.
   lDOCRECNO := .F.
   cSUBTIPO  := " "
   
   cTABELA:=HB_FNAMENAME(cARQORI)
   PegcsUB( tDOC )   // pegar o subtipo conforme tipo
   cDESTINO := cTABELA + "_mysql." + zEXPOREXT
   MDT( "abrindo arquivo de origem: " + cTABELA )
   
   aSTRU=Paradox_DbStruct( cARQORI )
   
   USE ( cARQORI ) VIA "PXRDD" ALIAS ( cTabela )   




   nLASTREC := LastRec()
   zei_fort( nLASTREC,,, 0 )

   //aSTRU := dbstruct()

   multidocg( lDOCCAB, lDOCDAD, lDOCRECNO, cSUBTIPO, TIRAEXT( cDESTINO ), aSTRU )

   dbCloseAll()

   RETURN NIL


