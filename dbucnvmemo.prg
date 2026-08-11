*+--------------------------------------------------------------------
*+
*+    Programa  : dbucnvmemo.prg
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
*+    Documentado em 28-Dez-2024 as 10:06 am
*+
*+--------------------------------------------------------------------
*+

//#include "ads.ch"
#include "dbinfo.ch"
#include "try.ch"



*+--------------------------------------------------------------------
*+
*+    Function convertmemo()
*+
*+--------------------------------------------------------------------
*+
function convertmemo()


aAMBIENTE := SALVAA()
nOLDTIPO  := TIPODBF

alertx("escolha origem")
nORITIPO   := tipodbfesc()
cORIDRIVER := RDDNOME(nORITIPO)
cORIMEMO   := hb_rddInfo(RDDI_MEMOEXT)  //a extensao do origem memo do destino vem com ponto

alertx("escolha destino")
nDESTIPO   := tipodbfesc()
cDESDRIVER := RDDNOME(nDESTIPO)
cDESMEMO   := hb_rddInfo(RDDI_MEMOEXT)  //a extensao do rdiinfo memo do destino vem com ponto

cBUSCA    := "*"+cORIMEMO
aARQMEMOS := directory(cBUSCA)  // ".FPT" a extensao do rdiinfo memo do destino vem com o ponto
IF LEN(aARQMEMOS) = 0
   ALERTX("Sem arquivos: "+cORIMEMO)
   RESTAA(aAMBIENTE)
   TIPODBF := nOLDTIPO
   RDDNOME(nOLDTIPO)  //retorna tipo anterior
   RETURN .F.
ENDIF




FOR XY := 1 TO LEN(aARQMEMOS)

   cARQORIMEMO   := lower(aARQMEMOS[XY,1])
   cARQORISEMEXT := tiraext(cARQORIMEMO)

   MDT("Fazendo copia de reserva: "+"old_"+cARQORISEMEXT)
   if ! filecopy(cARQORISEMEXT+"."+TABLEEXT,"old_"+cARQORISEMEXT+"."+TABLEEXT)
     ALERTX("Erro ao criar backup do DBF: " + cARQORISEMEXT)
     RETURN .F.
   ENDIF
   if ! filecopy(cARQORISEMEXT+cORIMEMO,"old_"+cARQORISEMEXT+cORIMEMO)
      ALERTX("Erro ao criar backup do DBF: " + cARQORISEMEXT)
      RETURN .F.
   ENDIF
   cOLDDBF := "old_"+cARQORISEMEXT
   cNEWDBF := "new_"+cARQORISEMEXT

   MDT("abrindo arquivo antigo: "+cOLDDBF)
   //FDBUseArea( <lNewArea> , <cDriver> , <cName>, <xcAlias> , <lShared> , <lReadOnly>,<cCodePage>,<nConnection> ) -> lSuccess
   dbUseArea( .T., (cORIDRIVER), (cOLDDBF), "aliasantigo", .T. , .F. )
   //USE (cOLDDBF) ALIAS aliasantigo SHARED NEW VIA (cORIDRIVER) //"DBFNTX" 	via driver antigo

   MDT("copiando estrutura")
   try
   COPY STRUCTURE TO (cNEWDBF) //criando a estrutura usa o rdddefauld destino ultimo atribuido
   catch oERROR
   alertx("Erro Criando nova strutura")
   RESTAA(aAMBIENTE)
   TIPODBF := nOLDTIPO
   RDDNOME(nOLDTIPO)  //retorna tipo anterior
   RETURN .F.
end
IF file(cNEWDBF+"."+TABLEEXT) .AND. file(cNEWDBF+cDESMEMO)  // ".FPT" a extensao do rdiinfo memo do destino
   MDT("copia efetuada:"+cNEWDBF+"."+TABLEEXT+" "+cNEWDBF+cDESMEMO)
ENDIF

dbUseArea( .T., (cDESDRIVER), (cNEWDBF), "aliasnovo", .F. , .F. )
//USE (cNEWDBF) ALIAS aliasnovo EXCLUSIVE NEW VIA (cDESDRIVER) //abre a copia usa o rdddefauld destino ultimo atribuido

MDT("Importando registros para: "+cNEWDBF)
dbSelectArea( "ALIASNOVO" )

nLASTREC := NetRegCount(cOLDDBF)
zei_fort(nLASTREC,,,0)

APPEND FROM (cOLDDBF) VIA(cORIDRIVER) while zei_fort(nLASTREC,,,1)  //"DBFNTX" 	via driver antigo

DBCLOSEALL()
next xy
RDDNOME(nOLDTIPO)   //retorna tipo anterior
RESTAA(aAMBIENTE)


*+--------------------------------------------------------------------
*+
*+
*+
*+    Function converttipo()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
function converttipo()

aINDICES  :={}
aCHAVES   = {}
nINDEXES  :=0
aAMBIENTE := SALVAA()
nOLDTIPO  := TIPODBF

alertx("escolha origem")
nORITIPO   := tipodbfesc()
cORIDRIVER := RDDNOME(nORITIPO)
cORIEXT    := hb_rddInfo(RDDI_TABLEEXT)   //a extensao do rdiinfo memo do destino vem com ponto
cORIMEMO   := hb_rddInfo(RDDI_MEMOEXT)  //a extensao do origem memo do destino vem com ponto
cORIEXTINDEX := hb_rddInfo(RDDI_ORDBAGEXT)

alertx("escolha destino")
nDESTIPO   := tipodbfesc()
cDESDRIVER := RDDNOME(nDESTIPO)
cDESEXT    := hb_rddInfo(RDDI_TABLEEXT)   //a extensao do rdiinfo memo do destino vem com ponto
cDESMEMO   := hb_rddInfo(RDDI_MEMOEXT)  //a extensao do rdiinfo memo do destino vem com ponto
cDESEXTINDEX := hb_rddInfo(RDDI_ORDBAGEXT)

cBUSCA  := "*"+cORIEXT  //a extensao do rdiinfo memo do destino vem com ponto
aARQDBF := directory(cBUSCA)
IF LEN(aARQDBF) = 0
   ALERTX("Sem arquivos para converter ")
   RESTAA(aAMBIENTE)
   TIPODBF := nOLDTIPO
   RDDNOME(nOLDTIPO)  //retorna tipo anterior
   RETURN .F.
ENDIF

lSTRUEXT := MDG("STRU EXTEND(S) DBCREATE(N)")

FOR XY := 1 TO LEN(aARQDBF)

   cARQNOME := lower(aARQDBF[XY,1])
   cARQNOME := tiraext(cARQNOME)
   cARQORI  := cARQNOME+cORIEXT
   cARQMEMO := cARQNOME+cORIMEMO
   cARQINDEX:=cARQNOME+cORIEXTINDEX

   MDT("Fazendo copia de reserva: "+"old_"+cARQORI)
   filecopy(cARQORI,"old_"+cARQORI)
   filecopy(cARQMEMO,"old_"+cARQMEMO)
   filecopy(cARQINDEX,"old_"+cARQINDEx)

   cOLDDBF := "old_"+cARQNOME
   cNEWDBF := "new_"+cARQNOME
   

   MDT("abrindo arquivo antigo: "+cOLDDBF)
  // USE (cOLDDBF) ALIAS aliasantigo SHARED NEW VIA (cORIDRIVER) //	via driver antigo utiliza aliasantigo mas o driver defaiult e o destino
  dbUseArea( .T., (cORIDRIVER), (cOLDDBF), "aliasantigo", .T. , .F. )
  
     aINDICES  :={}
   aCHAVES   = {}
 
  //               1     2          3          4         5      6        7       8  
     //AADD(aDUPLA,{msql,msqlmeta,cTablename,cINDEXNAME,cKey,cSqlExpr,cFilter,lIsUnique}) 
   aINDICESx:=GeraINDICES()
    nIndexes := LEN(aINDICESx)
    FOR j := 1 TO nIndexes
      AAdd( Aindices, aINDICESx[J,4] )
      AADD( aCHAVES , aINDICESx[J,5] )
    NEXT j
  

   MDT("copiando estrutura")
   IF lSTRUEXT
      try
         COPY STRUCTURE TO (cNEWDBF) //criando a estrutura usa o rdddefauld destino ultimo atribuido
      catch oERROR
         alertx("Erro Criando nova strutura")
         RESTAA(aAMBIENTE)
         TIPODBF := nOLDTIPO
         RDDNOME(nOLDTIPO)   //retorna tipo anterior
        RETURN .F.
     end
ELSE
   aESTRUTURA := dbStruct()   //cria matriz com a estrura
   dbcreate(cNEWDBF,aESTRUTURA,cDESDRIVER,.F.)
   // dbCreate( <cFile>, <aStruct>, [<cRDD>], [<lKeepOpen>]]
   dbclosearea()
ENDIF
//dbclosearea()

IF file(cNEWDBF+cDESEXT)
   MDT("copia efetuada:"+cNEWDBF+cDESEXT)

   //USE (cNEWDBF) ALIAS aliasnovo EXCLUSIVE NEW VIA (cDESDRIVER) //abre a copia usa o rdddefauld destino ultimo atribuido utiliza aliasnovo
   dbUseArea( .T., (cDESDRIVER), (cNEWDBF), "aliasnovo", .F. , .F. )

   MDT("Importando registros para: "+cNEWDBF)
   //  SELE ALIASNOVO

   nLASTREC := NetRegCount(cOLDDBF)
   zei_fort(nLASTREC,,,0)

   APPEND FROM (cOLDDBF) VIA(cORIDRIVER) while zei_fort(nLASTREC,,,1)   //"	via driver antigo
   
   cARQINDEX:=cNEWDBF+cDESEXTINDEX
   IF nIndexes>0
       FOR j := 1 TO nIndexes
           cINDEXNAME := Aindices[J]
           cINDEXCHAVE:= ACHAVES[J]
           MDT("Criando Indice: "+cINDEXNAME+" "+cINDEXCHAVE)
           try
              IF EINDEXCOMPOUND()
                 INDEX ON &cINDEXCHAVE TAG &cINDEXNAME//TO &cARQINDEX
              ELSE
                 INDEX ON &cINDEXCHAVE TO &cARQINDEX
              ENDIF   
           catch oERROR
              ALERT(cINDEXNAME+" "+cINDEXCHAVE)
           end
          
          
       NEXT j
   ENDIF    
ENDIF

DBCLOSEALL()
next xy
TIPODBF := nOLDTIPO
RDDNOME(nOLDTIPO)   //retorna tipo anterior
RESTAA(aAMBIENTE)

*+ EOF: dbucnvmemo.prg
*+
