*+--------------------------------------------------------------------
*+
*+    Programa  : dbu.prg
*+
*+     Sistema:
*+
*+     Linguagem: Harbour
*+
*+     Autor: jcassiano
*+
*+     Copyright (c) 2024,  jcassiano
*+
*+    Documentado em 28-Dez-2024 as 10:06 am
*+
*+
*+--------------------------------------------------------------------
*+

#include "dbinfo.ch"
#INCLUDE "INKEY.CH"
#INCLUDE "BOX.CH"

#INCLUDE "HBGTINFO.CH"
#INCLUDE "hbVER.CH"



REQUEST HB_LANG_PT
REQUEST HB_CODEPAGE_PTISO
REQUEST HB_GT_WVG_DEFAULT

REQUEST DBFNTX  // 1 DBFNTX DBF INDEX=NTX
REQUEST DBFCDX  // 2 DBFCDX DBF INDEX=CDX
REQUEST ADSCDX  // 3 &ADSCDX DBF INDEX=CDX  SET FILETYPE TO ADT CDX NTX  ADS ADSADT ADSNTX ADSCDX ADSVFP
REQUEST ADSNTX  // 4 ADSNTX DBF INDEX=NTX
REQUEST ADSVFP  // 5 ADSVFP TABLE=VFP
REQUEST ADSADT  // 6 ADSADT TABLE=ADS
REQUEST DBTCDX  // 7 DBTCDX DBF CDX MEMO=DBT
REQUEST FPTCDX  // 8 SMTCDX DBF CDX MEMO=SMT
REQUEST SMTCDX  // 9 FPTCDX DBF CDX MEMO=FPT
REQUEST SIXCDX  //10 SIXCDX DBF CDX           SIXCDX SISNTX SISNSX SuccessWare Index Driver (SIx Driver) replaces the default NTX/DBT index and memo driver with an NSX/SMT  single-file index https://www.apollodb.com/sixrdd.asp
REQUEST DBFNSX  //11 DBFNSX DBF NSX
REQUEST DBFBLOB   //12 It operates on memo files only (.dbv) without tables (.dbf)r
REQUEST HSCDX   //13-HSCDX  DBFCDX/HSCDX
REQUEST RLCDX   //-14-RLCDX  DBFCDX/RLCDX
REQUEST VFPCDX  //-15-VFPCDX DBFCDX/DBFFPT/VFPCDX

REQUEST BMDBFCDX  //-16 BMDBFCDX DBFCDX
REQUEST BMDBFNSX  //-17 BMDBFNSX DBFNSX
REQUEST BMDBFNTX  //-18 BMDBFNTX DBFNTX
REQUEST DBFCDXEX  //-19 CRYPTO   DBFCDXEX

#ifdef USE_PXRDD
    REQUEST PXRDD   //-20 Carrega a RDD do Paradox criada acima
#endif


//Microsoft FoxPro create an IDX index file similar ntx
//REQUEST DBFNDX nao tem mais a rdd removido tipos dbulib.prg A dBASE III standard index file (.NDX)
//REQUEST DBFMDX nao tem mais a rdd removido tipos dbulib.prg dBASE IV  mdx index files can contain up to 47 individual index files in a single mdx file



*+--------------------------------------------------------------------
*+
*+
*+
*+    Function MAIN()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
FUNCTION MAIN()



netregosok()

HB_IDLESTATE()
Set(_SET_CODEPAGE,"PTISO")
HB_LANGSELECT('PT')
rddsetdefault("DBFCDX")
Set(_SET_OPTIMIZE,.t.)
Set(_SET_DELETED,.t.)
Set(_SET_SOFTSEEK,.t.)
__SetCentury(.t.)
Set(_SET_EPOCH,year(date()) - 60)
Set(_SET_DATEFORMAT,"dd/mm/yyyy")
SetCursor(.t.)
Set(_SET_SCOREBOARD,.f.)


public n_files
public keystroke
public lkey
public frame
public sframe
public cur_dir
public more_up
public more_down
public kf1
public kf2
public kf3
public kf4
public kf5
public kf6
public need_field
public need_ntx
public need_relat
public need_filtr
public help_code
public view_err
public cur_area
public cur_dbf
public cur_ntx
public cur_fields
public error_on
public exit_str
public page
public sysfunc
public func_sel
public cur_func
public local_func
public local_sel
public box_open
public color1
public color2
public color3
public color4
public color5
public color6
public color7
public color8
public color9
public color10
public color11
public color12
public com_line
public curs_on
public ld_cha     := "-"
public zDELIMITE  := ","
public zSEPLOGIC  := "1   "
public zEXPOREXT  := "DLM"
public zDECSIM    := "."
public zANOTAM    := "2"
public zANOFOR    := "DMA"+SPACE(7)
public zANOSEP    := "/"
public zCNVCHAR   := "N"
public zusovia    := "DBFCDX"
public zREGSEP    := " "
public ABERTURA := .T.
public TIPODBF  := 2        //dbfcdx
public TABLEEXT := "DBF"   //hb_rddInfo(RDDI_TABLEEXT)
public MEMOEXT  := "FPT"    //hb_rddInfo(RDDI_MEMOEXT)
public INDIEXT  := "CDX"   //hb_rddInfo(RDDI_ORDBAGEXT)
public cTIPOSQL := ""
PUBLIC cTIPOMIX := ""
PUBLIC cTIPODBC := ""
PUBLIC cRDDSQL  :=""  //Separado de zusovia aqui somente as que precisam rddsetdefault SQLMIX SQLRDD SQLEX LETO
PUBLIC zSENHACDX := ""

clear

//hb_keyput(K_ALT_ENTER)
MVINFOConfTela("DBU "+str(hb_Version(HB_VERSION_BITWIDTH)))

//Variaves Userededbu
ZUSER := ""
ZDIRE := HB_CWD()

//mdt(str(hb_Version( HB_VERSION_BITWIDTH )))

//Inicializa o Mouse
set(_SET_EVENTMASK,HB_INKEY_ALL)
lMOUSE       := .T.
MOUSE_X      := 0
MOUSE_Y      := 0
MOUSE_B      := 0
aMENUPROMPTS := {}

func_title := {"Ajuda","Abrir","Criar","Salvar","Editar","Apoio","Mover","Setar","Util"}

//Variavel Usado na prg dbuedit
public mGetVar

PATHX := HB_CWD()   // VARIAVEIS DE TRABALHO
Set(_SET_PATH,PATHX)

HELPARQ  := "DBUHELP"
READVAR  := ""
ABERTURA := .T.
TIPODBF  := 2   //dbfcdx
TABLEEXT := "DBF"

aPARAM := HB_aParams()
FOR iLOOP := 1 TO LEN(aPARAM)
   aPARAM[ iLOOP ] := UPPER(aPARAM[iLOOP])
   DO CASE
   case AT("/FOXPRO",aPARAM[iLOOP]) > 0 .or. AT("/DBFCDX",aPARAM[iLOOP]) > 0
      TIPODBF         := 2
      aPARAM[ iLOOP ] := ""
   case AT("/DBFNTX",aPARAM[iLOOP]) > 0
      TIPODBF         := 1
      aPARAM[ iLOOP ] := ""
   case AT("/DBFNDX",aPARAM[iLOOP]) > 0
      TIPODBF         := 3
      aPARAM[ iLOOP ] := ""
   case AT("/DBFMDX",aPARAM[iLOOP]) > 0
      TIPODBF         := 4
      aPARAM[ iLOOP ] := ""
   case AT("/ADSCDX",aPARAM[iLOOP]) > 0
      TIPODBF         := 5
      aPARAM[ iLOOP ] := ""
   OTHERWISE
      tipodbfesc()
   ENDCASE
NEXT iLOOP



//colorido
color1  := "W+/B,N/W,B"
color2  := "B/W"
color3  := "W+/R"
color4  := "W+/B,B/W,,,W+/B"
color5  := "B/BG,B/W,,,W/BG"
color6  := "W+/BG"
color7  := "B/BG,B/W"
color8  := "B/W,B/BG,,,B/W"
color9  := "W+/B,N/BG"
color10 := "B/BG"
color11 := "W+/BG"
color12 := "W+/B"

param1 := ""
param2 := ""
param3 := ""

FOR iLOOP := 1 TO LEN(aPARAM)
   IF AT("/MONO",aPARAM[iLOOP]) > 0   //monocromatico
      color1          := "W/N,N/W"
      color2          := "N/W"
      color3          := "W+/N"
      color4          := "W/N,N/W,,,W/N"
      color5          := "W+/N,N/W,,,W/N"
      color6          := "W/N"
      color7          := "W/N,N/W"
      color8          := "W/N,N/W,,,W/N"
      color9          := "N/W,N/W"
      color10         := "N/W"
      color11         := "N/W"
      color12         := "W+/N"
      aPARAM[ iLOOP ] := ""
   ENDIF
   do case
   case iloop = 1
      param1 := aPARAM[1]
   case iloop = 2
      param2 := aPARAM[2]
   case iloop = 3
      param3 := aPARAM[3]
   endcase
NEXT iLOOP


//Recebe um arquivo para abrir
com_line := param1

ACENTUA := .T.
SetKey(39,{|| AC_AGUDO()})
SetKey(94,{|| AC_CIRC()})
SetKey(96,{|| AC_CRASE()})
SetKey(126,{|| AC_TIL()})
SetKey(K_ALT_S,{|| ACENTUA := !ACENTUA,ALERTX("Acentuacao: "+if(acentua,"ligada","desligada"))})  //usar {|| ACENTUA := ! ACENTUA, mds(if(acentua,"ligado","desligado")) }
SetKey(K_F12,{|| __SetCentury(!__SetCentury()),alertX("Seculos em Datas: "+if(__SetCentury(),"ligado","desligado"))})   //usar {|| __SetCentury( ! __SetCentury() ) , mds(if(__SetCentury(),"ligado","desligado")) }


lVERTXT := .T.
lEDITXT := .T.

//Teclas Especiais set pois no dbu usa o read padrao nao o modificado readcur que seta esta configuracao
SetKey(K_ALT_V,{|| hb_gtInfo(HB_GTI_CLIPBOARDPASTE,.T.)})
SetKey(K_ALT_O,{|| XPOSESQ()})
SetKey(K_ALT_P,{|| XPOSDIR()})
SetKey(K_ALT_F,{|| XGRATXT()})
SetKey(K_ALT_G,{|| XCENTER()})
SetKey(K_ALT_H,{|| xcaptxt()})
SetKey(K_ALT_J,{|| xediwor()})
SetKey(K_ALT_K,{|| xtirace()})
SetKey(K_ALT_L,{|| XEXPAND()})
SetKey(K_ALT_B,{|| XCAPFIRS()})
SetKey(K_ALT_N,{|| XCONVMIN()})
SetKey(K_ALT_M,{|| XCONVMAI()})
SetKey(K_ALT_INS,{|| XALTINS()})
SetKey(K_CTRL_DEL,{|| XCTRLDEL()})
SetKey(K_CTRL_INS,{|| XCTRLINS()})


if empty(param1)
   param1 := "*.dbf"
endif

FOR iLOOP := 1 TO LEN(aPARAM)
   do case
   case AT("/XMLA",aPARAM[iLOOP]) > 0
      multidocs(1,"*."+TABLEEXT)
      //           FAZERDBF( {|| dbf2xml() }, .F. ,,,param1)

   case AT("/TEC",aPARAM[iLOOP]) > 0
      IF MDG("Gerar Observacoes")
         multidocs(2,param1)  //.tam
      ELSE
         multidocs(3,param1)  //.tec
      ENDIF
   case AT("/TAM",aPARAM[iLOOP]) > 0
      multidocs(2,param1)
   case AT("/DBE",aPARAM[iLOOP]) > 0
      multidocs(4,param1)
   case AT("/DLM",aPARAM[iLOOP]) > 0
      pegparexp()
      multidocs(5,param1)
   case AT("/SDF",aPARAM[iLOOP]) > 0
      multidocs(6,param1)
   case AT("/XML",aPARAM[iLOOP]) > 0
      multidocs(7,param1)
   case AT("/JSON",aPARAM[iLOOP]) > 0
      multidocs(8,param1)
    case AT("/MD",aPARAM[iLOOP]) > 0
      multidocs(14,param1)  
   case AT("/FIX",aPARAM[iLOOP]) > 0
      if mdg("Fixar? "+zdire) = "S"
         FAZERDBF({|| dbupack()},.t.,{|| copybkdbf(ARQUIVO)},{|| memopack(arquivo,.t.,.t.,RDDNOME(TIPODBF))},param1)
      endif
   case AT("/ZER",aPARAM[iLOOP]) > 0
      if mdg("Zerar? "+zdire)
         if md("Realmente Zerar?"+zdire)
            FAZERDBF({|| dbuzap()},.t.,{|| copybkdbf(ARQUIVO)},{|| memopack(arquivo,.t.,.t.,RDDNOME(TIPODBF))},param1)
         endif
      endif
   case AT("/AJU",aPARAM[iLOOP]) > 0
      if mdg("Ajustar? "+zdire)
         dbetodbf(param1,.F.)
      endif
   case AT("/COR",aPARAM[iLOOP]) > 0
      if mdg("Corrigir? "+zdire)
         DBETODBF(param1,,.T.)
      endif
   endcase
next Iloop


setcolor(color1)
clear

more_up   := chr(24)
more_down := chr(25)
frame     := "---|---|"
lframe    := "---|---|"
mframe    := "---|+-+|"
sframe    := "+-+|+-+|"

need_field := need_ntx := need_relat := need_filtr := box_open := .F.
//kf1        := kf2 := kf3 := kf4 := kf5 := kf6 := ""
kf1        := kf2 := kf3 := kf4 := kf5 := kf6 := ""
help_code  := 0
curs_on    := .F.
cur_dir    := ""
cur_dbf    := ""
cur_ntx    := ""
cur_fields := ""
cur_area   := 0
page       := 1
n_files    := 0
view_file  := ""
view_err   := ""
dbf        := array(6)

ntx1 := array(7)
ntx2 := array(7)
ntx3 := array(7)
ntx4 := array(7)
ntx5 := array(7)
ntx6 := array(7)

DECLARE s_relate[15]
DECLARE k_relate[15]
DECLARE t_relate[15]

DECLARE field_n1[128]
DECLARE field_n2[128]
DECLARE field_n3[128]
DECLARE field_n4[128]
DECLARE field_n5[128]
DECLARE field_n6[128]

DECLARE field_list[128]

DECLARE row_a[3]
DECLARE row_x[3]

row_a[1] = 6
row_x[1] = 6
row_a[2] = 10
row_x[2] = 12
row_a[3] = 16
row_x[3] = 22

DECLARE column[6]

DECLARE cr1[3]
DECLARE cr2[3]
DECLARE cr3[3]
DECLARE cr4[3]
DECLARE cr5[3]
DECLARE cr6[3]

DECLARE el1[3]
DECLARE el2[3]
DECLARE el3[3]
DECLARE el4[3]
DECLARE el5[3]
DECLARE el6[3]

help_title := array(22)

afill(dbf,"")

afill(ntx1,"")
afill(ntx2,"")
afill(ntx3,"")
afill(ntx4,"")
afill(ntx5,"")
afill(ntx6,"")

afill(field_n1,"")
afill(field_n2,"")
afill(field_n3,"")
afill(field_n4,"")
afill(field_n5,"")
afill(field_n6,"")

afill(s_relate,"")
afill(k_relate,"")
afill(t_relate,"")

afill(field_list,"")

menu_deflt := array(9)
afill(menu_deflt,1)

LAYOUT()

//Menus que Saem
exit_str := "3569"

ajuda_m := {"Ajuda"}
ajuda_b := {.T.}

abrir_m := {"Database","Indice","Visao","POSTGRESQL",;
 "SQLITE","MARIADB","MYSQL","MDB ACCESS","ACCDB ACCESS","MSSQL","ORACLE","LETODB","FIREBIRD","PARADOX","DUCKDB","DBFCRYPTO"}
abrir_b := array(16)
abrir_b[1] = "sysfunc = 0 .AND. .NOT. box_open"
abrir_b[2] = "sysfunc = 0 .AND. .NOT. box_open .AND. .NOT. EMPTY(cur_dbf)"
abrir_b[3] = "sysfunc = 0 .AND. .NOT. box_open"
abrir_b[4] = "sysfunc = 0 .AND. .NOT. box_open"
abrir_b[5] = "sysfunc = 0 .AND. .NOT. box_open"
abrir_b[6] = "sysfunc = 0 .AND. .NOT. box_open"
abrir_b[7] = "sysfunc = 0 .AND. .NOT. box_open"
abrir_b[8] = "sysfunc = 0 .AND. .NOT. box_open"
abrir_b[9] = "sysfunc = 0 .AND. .NOT. box_open"
abrir_b[10] = "sysfunc = 0 .AND. .NOT. box_open"
abrir_b[11] = "sysfunc = 0 .AND. .NOT. box_open"
abrir_b[12] = "sysfunc = 0 .AND. .NOT. box_open"
abrir_b[13] = "sysfunc = 0 .AND. .NOT. box_open"
abrir_b[14] = "sysfunc = 0 .AND. .NOT. box_open"
abrir_b[15] = "sysfunc = 0 .AND. .NOT. box_open"
abrir_b[16] = "sysfunc = 0 .AND. .NOT. box_open"


DECLARE criar_b[11]
criar_m := {"Database","Indice","DBF->EXP","Sem  uso","sem  uso","sem  uso",;
 "sem  uso","sem  uso","Sem  uso","Sem  uso","Sem  uso"}
//criar_m[5]:=ZEXPOREXT   //agora usa geradoc 0 que pergunta o tipo  de exportacao

criar_b[1] = "sysfunc = 0"
FOR X := 2 TO 8
   criar_b[X] = "sysfunc = 0 .AND. .NOT. EMPTY(cur_dbf)"
next x
FOR X := 9 TO 11
   criar_b[X] = "sysfunc = 0.AND. EMPTY(cur_dbf)"
next x

salvar_m := {"Visao","Estrutura"}
salvar_b := array(2)
salvar_b[1] = "sysfunc = 0 .AND. .NOT. box_open"
salvar_b[2] = "sysfunc = 3 .AND. func_sel = 1 .AND. .NOT. box_open"


editar_m := {"Database","Visao"}
editar_b := ARRAY(2)
editar_b[1] = "sysfunc = 0 .AND. .NOT. EMPTY(cur_dbf)"
editar_b[2] = "sysfunc = 0 .AND. .NOT. EMPTY(dbf[1])"


apoio_m := {"Copia","Anexar","Repor","Fixar","Zerar","Del ALL FOR","Dos","Diret"}
apoio_b := array(8)
afill(apoio_b,"sysfunc = 0 .AND. .NOT. EMPTY(cur_dbf)",1,5)
apoio_b[6] = "sysfunc = 0 .AND. .NOT. EMPTY(dbf[1])"
apoio_b[7] = "sysfunc = 0"
apoio_b[8] = "sysfunc = 0"


mover_m := {"Busca","Para","Achar","Pular"}
mover_b := array(4)
afill(mover_b,"sysfunc = 5 .AND. .NOT. box_open")
mover_b[1] = mover_b[1]+" .AND. .NOT. EMPTY(cur_ntx)"


setar_m := {"Relacao","Filtro","Campos","Abertura","Apagados","Tipo DBF","EXPORTACAO"}
setar_b := ARRAY(7)
setar_b[1] = "sysfunc = 0 .AND. .NOT. box_open .AND. .NOT. EMPTY(dbf[2])"
setar_b[2] = "sysfunc = 0 .AND. .NOT. box_open .AND. .NOT. EMPTY(cur_dbf)"
setar_b[3] = "sysfunc = 0 .AND. .NOT. box_open .AND. .NOT. EMPTY(cur_dbf)"
setar_b[4] = "sysfunc = 0"
setar_b[5] = "sysfunc = 0"
setar_b[6] = "sysfunc = 0"
setar_b[7] = "sysfunc = 0"

util_m := {"Rem Reg Dup","Exportar","Sort DBF",;
 "FixarTodos","ZeraTodos","DBEs->DBF","Recriar","CNV Memos","Sinc DBFs","Converter",;
 "Format->DBF","SQL e DBML","sem uso","sem uso","sem uso","sem uso","sem uso"}
util_b := {.T.,.T.,.T.,.T.,.T.,.T.,.T.,.T.,.T.,.T.,.T.,.T.,.T.,.T.,.T.,.T.,.T.}
//FOR X=5 TO 16
//     util_b[x]:="EMPTY(cur_dbf)"
//next x

DECLARE dbf_list[adir("*."+TABLEEXT)+20]
DECLARE ntx_list[adir("*"+XEXT())+20]
DECLARE vew_list[adir("*.vew")+20]

array_dir("*."+TABLEEXT,dbf_list)
array_dir("*"+XEXT(),ntx_list)
array_dir("*.vew",vew_list)

local_func := 0
local_sel  := 1
keystroke  := 0
lkey       := 0
sysfunc    := 0
func_sel   := 1

com_line := ltrim(trim(upper(com_line)))

if .not. empty(com_line)
   do case
   case rat(".",com_line) > rat(hb_ps(),com_line)
      if .not. HB_FILEEXISTS(com_line)
         com_line := ""
      endif
   case file(com_line+".vew")
      com_line += ".vew"
   case file(com_line+"."+TABLEEXT)
      com_line += "."+TABLEEXT
   otherwise
      com_line := ""
   endcase

   if .not. empty(com_line)
      if rat(".vew",lower(com_line)) = len(com_line) - 3
         view_file := com_line
         set_from(.F.)
         keyboard chr(- 4)+chr(24)+chr(13)
      else
         dbf[1] = com_line
         DBUREDE(com_line,,ABERTURA)
         all_fields(1,M->field_n1)
         keyboard chr(- 4)+chr(13)
      endif
      if .not. empty(dbf[1])
         view_err := ""
      endif
   endif
endif

do while .T.
   cur_func := M->sysfunc
   do case
   case M->sysfunc = 2 .and. M->func_sel > 3  //abir outros databases
      do case
      case M->func_sel = 4
         MENUSQL("PGSQL")
      case M->func_sel = 5
         MENUSQL("SQLITE")
      case M->func_sel = 6
         MENUSQL("MARIADB")
      case M->func_sel = 7
         MENUSQL("MYSQL")
      case M->func_sel = 8
         MENUSQL("MDB")
      case M->func_sel = 9
         MENUSQL("ACCDB")
      case M->func_sel = 10
         MENUSQL("MSSQL")
      case M->func_sel = 11
         MENUSQL("ORACLE")
      case M->func_sel = 12
         letomenu()
      case M->func_sel = 13
         MENUSQL("FIREBIRD")  
       case M->func_sel = 14
         MENUSQL("PARADOX")  
      case M->func_sel = 15
         MENUSQL("DUCKDB")
      case M->func_sel = 16
         DBFcryptomenu()
      endcase
      sysfunc := 0  //setar para nao retornar ficar em loop
   case M->sysfunc = 9  //utilitarios F9
      do case
      case M->func_sel = 1
         if rsvp("Limpar Registros Duplicados") = "S"
            limparegdupdbf()
         ENDIF
      case M->func_sel = 2
         IF MDG("Todos(SIM) Escolher (NAO)")
            multidocs(0)  //passa 0 par a perguntar o formato
         ELSE
            copiardbfpara(1)
         ENDIF

      case M->func_sel = 3
         sortdbf()


      case M->func_sel = 4
         if rsvp("Fixar Todos ? (S/N)") = "S"
            FAZERDBF({|| dbupack()},.t.,{|| copybkdbf(ARQUIVO)},{|| memopack(arquivo,.t.,.t.,RDDNOME(TIPODBF))})
            stat_msg("Fixar Todos Concluido")
         endif
      case M->func_sel = 5
         if rsvp("Zerar Todos ? (S/N)") = "S"
            if mdg("Realmente Zerar Todos ? (S/N)")
               FAZERDBF({|| dbuzap()},.t.,{|| copybkdbf(ARQUIVO)},{|| memopack(arquivo,.t.,.t.,RDDNOME(TIPODBF))})
               stat_msg("Zerar Todos Concluido")
            endif
         endif
      case M->func_sel = 6
         IF MDG("Criar Inexistentes")
            DBETODBF("*.DBE")
         ELSE
            DBETODBF()
         ENDIF
         stat_msg("DBEs->DBF Concluido")
      case M->func_sel = 7
         if rsvp("Corrigir Todos ? (S/N)") = "S"
            if mdg("Corrigir Todos ? (S/N)")
               multidocs(4)
               DBETODBF(,,.T.)
            endif
         endif
      case M->func_sel = 8
         if rsvp("Converter memos entre formatos") = "S"
            convertmemo()
         ENDIF
      case M->func_sel = 9  // podera ser usado para outro menu pois agora a funcao e unica
         if rsvp("Sincronizar Tabelas") = "S"
            dBUsincdbf()
         ENDIF
      case M->func_sel = 10
         if rsvp("Converter  entre formatos") = "S"
            converttipo()
         ENDIF

      case M->func_sel = 11
         copiardbfpara(2)   //append formatos para dbf
      case M->func_sel = 12
          cPASTA:=SelectFolder()
          mdltodos(cPASTA)
          Sqltodos("SQLITE",cPASTA)
          Sqltodos("MSSQL",cPASTA)
          Sqltodos("MYSQL",cPASTA)
          Sqltodos("POSTGRESQL",cPASTA)
          Sqltodos("ACCESS",cPASTA)
          Sqltodos("ORACLE",cPASTA)
          sqltodos("FIREBIRD",cPASTA)
          sqltodos("DUCKDB",cPASTA)
          //sqltodos("PARADOX") //nao implemntado odbc nao gerando
          //alert("multi")
          multidocs(4, cPASTA+"\*."+TABLEEXT)  //4- dbe
      
      
      case M->func_sel = 13
      case M->func_sel = 14
      case M->func_sel = 15
      case M->func_sel = 16
      case M->func_sel = 17


      endcase
      sysfunc := 0
   case M->sysfunc = 5  //F5 edicao
      if .not. empty(dbf[1])
         setup()
         if empty(M->view_err)
            cur_fields := "field_n"+substr("123456",M->cur_area,1)
            do case
            case M->func_sel = 1 .and. empty(M->cur_dbf)
               view_err := "Nao data arquivo na corrente area selecionada"
            case M->func_sel = 1 .and. empty(&cur_fields[1])
               view_err := "Nao ativo campo lista na corrente area selecionada"
            case empty(field_list[1])
               view_err := "Nao ativo campo lista"
            otherwise
               if M->func_sel = 1
                  hi_cur()
               endif
               help_code := 3
               browse()
               dehi_cur()
            endcase
         endif
      else
         view_err := "Nao database em uso"
      endif
      sysfunc := 0
   case M->sysfunc = 3  //f3 criar
      do case
      case M->func_sel = 1
         hi_cur()
         help_code := 4
         modi_stru()
         dehi_cur()
         if empty(M->cur_dbf)
            cur_area := 0
         endif
      case M->func_sel = 9
         // GERADBF( 7 )
      case M->func_sel = 10
         // GERADBF( 8 )
      case M->func_sel = 11
         // GERADBF( 9 )
      otherwise
         if empty(M->cur_dbf)
            view_err := "Nao ha arquivo de dados na corrente area selecionada"
         else
            do case
            case M->func_sel = 2
               help_code := 5
               make_ntx()
            case M->func_sel = 3
               geradoc(0)
               //  GERADOC( 3 )
            case M->func_sel = 4
               //  GERADOC( 4 )
               alertx("funcao nao disponivel")
            case M->func_sel = 5
               //  GERADOC( 5 )
               alertx("funcao nao disponivel")
            case M->func_sel = 6
               //  GERADOC( 6 )
               alertx("funcao nao disponivel")
            case M->func_sel = 7
               // Dbf2Xml()
               alertx("funcao nao disponivel")
            case M->func_sel = 8
               // GERADOC( 7 )
               alertx("funcao nao disponivel")
            endcase
         endif
      endcase
      sysfunc := 0
   case M->sysfunc = 6 .and. M->func_sel < 7  //f6 apoio
      if empty(M->cur_dbf)
         view_err := "Nao ha arquivo de dados na corrente area selecionada"
         sysfunc  := 0
         loop
      endif
      if .not. empty(dbf[1])
         setup()
      endif
      if .not. empty(M->view_err)
         sysfunc := 0
         loop
      endif
      hi_cur()
      do case
      case M->func_sel < 4
         capprep()
      case M->func_sel = 4
         if rsvp("Fixar "+M->cur_dbf+"? (S/N)") = "S"
            stat_msg("Fixando "+M->cur_dbf)
            copybkdbf(M->cur_dbf)
            select (M->cur_area)
            if flock()
               pack
               //               dbreindex()
               stat_msg(M->cur_dbf+" Fixado")
            else
               stat_msg("Esta operacao requer Uso Exclusivo")
            endif
         endif

      case M->func_sel = 5
         if rsvp("Zerar "+M->cur_dbf+"? (S/N)") = "S"
            copybkdbf(M->cur_dbf)
            select (M->cur_area)
            stat_msg("Zerando "+M->cur_dbf)
            if flock()
               zap
               stat_msg(M->cur_dbf+" Zerado")
            else
               stat_msg("Esta operacao requer Uso Exclusivo")
            endif
         endif
      case M->func_sel = 6
         dbudelfor()
      endcase
      dehi_cur()
      sysfunc := 0

   case M->sysfunc = 6 .and. (M->func_sel = 7 .or. M->func_sel = 8)   //f6 apoio intem 7 e 8
      LAYOUT()
      if .not. empty(dbf[1])
         setup()
      endif
      if .not. empty(M->view_err)
         error_msg(M->view_err,24,7)
         view_err := ""
      endif
      run_com   := ""
      com_line  := ""
      help_code := 18
      if M->func_sel = 7
         do while .not. q_check()
            LAYOUT()
            @  2,0 say replicate("-",80)           
            @ 24,0 say "DOS -"+chr(16)+" "         
            run_com := enter_rc(M->com_line,24,7,127,"@KS73",M->color1)
            if .not. empty(M->run_com) .and. M->keystroke = 13
               com_line := M->run_com
               @ 24,0
               SetCursor(.t.)
               hb_run(run_com)
               SetCursor(.f.)
            endif
         enddo
      endif
      if M->func_sel = 8
         DBUDIR()
      endif
      LAYOUT()
      DECLARE dbf_list[adir("*."+TABLEEXT)+20]
      DECLARE ntx_list[adir("*"+XEXT())+20]
      DECLARE vew_list[adir("*.vew")+20]
      array_dir("*."+TABLEEXT,dbf_list)
      array_dir("*"+XEXT(),ntx_list)
      array_dir("*.vew",vew_list)
      cur_area := 0
      sysfunc  := 0

   otherwise
      help_code := 1
      set_view()
      if M->keystroke = 27
         Set(_SET_TYPEAHEAD,0)
         dbcloseall()
         __XRestScreen()
         SetCursor(.t.)
         SetColor("")
         quit
      endif
   endcase
enddo
RETU


*+--------------------------------------------------------------------
*+
*+
*+
*+    Function HELP()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
Function HELP()

return .t.


/*
*+||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
*+
*+
*+
*+    Function HELP()
*+
*+
*+
*+    Called from ( dbuutil.prg  )   1 - function menu_key()
*+
*+
*+
*+||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
*+
*+
*+
func HELP( programa, linha, variavel )                   //F1- AJUDA AO USUARIO

if PROGRAMA = "HELP"
   retu .T.
endif
POP_ROW  := row()
POP_COL  := col()
HEL_SCR  := savescreen( 00, 00, 24, 79 )
POP_COR  := setcolor()
HEL_DBF  := alias()
HLP_DESC := ""
HLP_DADO := ""
do case
case HELP_CODE = 1
   HLP_DADO := "Informacoes Gerais"
case HELP_CODE = 2
   HLP_DADO := "Box de Campos"
case HELP_CODE = 3
   HLP_DADO := "Exibindo Registros"
case HELP_CODE = 4
   HLP_DADO := "Mudando Estrutura"
case HELP_CODE = 5
   HLP_DADO := "Criando Arquivo de Indice"
case HELP_CODE = 6
   HLP_DADO := "Abrindo Arquivo de Dados"
case HELP_CODE = 7
   HLP_DADO := "Filtro"
case HELP_CODE = 8
   HLP_DADO := "Abrindo Arquivo de Indice"
case HELP_CODE = 9
   HLP_DADO := "Editando Relacao"
case HELP_CODE = 10
   HLP_DADO := "Expressao de Busca"
case HELP_CODE = 11
   HLP_DADO := "Arquivo delimitado por espacos ou Virgulas"
case HELP_CODE = 12
   HLP_DADO := "Copia de Arquivo"
case HELP_CODE = 13
   HLP_DADO := "Espressao de Busca"
case HELP_CODE = 14
   HLP_DADO := "Movimentando-se Para um registro"
case HELP_CODE = 15
   HLP_DADO := "Anexando"
case HELP_CODE = 16
   HLP_DADO := "Condicoes de Permanencia"
case HELP_CODE = 17
   HLP_DADO := "Condicao de Escopo"
case HELP_CODE = 18
   HLP_DADO := "Executar um Programa de DOS"
case HELP_CODE = 19
   HLP_DADO := "Editando Campos Memos"
case HELP_CODE = 20
   HLP_DADO := "Saltando n Registros"
case HELP_CODE = 21
   HLP_DADO := "Salvando Tela de Visao"
case HELP_CODE = 22
   HLP_DADO := "Repondo Dados"
case HELP_CODE = 23
   HLP_DADO := "Criando Documentacao Estrutura  - TEC"
case HELP_CODE = 24
   HLP_DADO := "Criando Arquivo de Reconstrucao - DBE"
case HELP_CODE = 25
   HLP_DADO := "Criando Arquivo de Construcao   - DLM"
case HELP_CODE = 26
   HLP_DADO := "Criando Arquivo de Construcao   - SDF"
endcase
cls
setcolor( "N/W" )
@ 00, 00 clear to 00, 79
@ 24, 00 clear to 24, 79
@ 00, 00 say " Linha:" + spac( 6 ) + "Coluna:    || Mover: " + chr( 24 ) + " " + chr( 25 ) + " PGUP PGDN ^PGDN ^PGUP         | Sair: ESC "
@ 24, 00 say '[Local : ' + HLP_DADO + ']'
setcolor( "W/R" )
setcursor( 1 )
NOBREAK()
HLP_BAR := ScrollBarNew( 00, 79, 24,, 1 )
HLP_FIM := mlcount( HLP_DESC )
ScrollBarDisplay( HLP_BAR )
memoedit( HLP_DESC, 01, 00, 23, 79, .F., "HELPDISP", 80 )
NOBREAK()
if !empty( HEL_DBF )
   sele &HEL_DBF
endif
setcursor( 0 )
setcolor( POP_COR )
restscreen( 00, 00, 24, 79, HEL_SCR )
setpos( POP_ROW, POP_COL )
retu .T.
*/



*+--------------------------------------------------------------------
*+
*+
*+
*+    Function DBUDIR()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
function DBUDIR


local cDIR := space(80)
@ 24,00 say "Ir para"                    
@ 24,10 get cDIR      pict "@S50"        
if !READDBU()
   retu .F.
endif
if !empty(cDIR)
   HB_CWD(cDIR)
endif


*+--------------------------------------------------------------------
*+
*+
*+
*+    Function DBUDELFOR()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
function DBUDELFOR

local cDIR     := space(80)
local nLASTREC
@ 24,00 say "Apagar"                    
@ 24,10 get cDIR     pict "@S50"        
if !READDBU()
   retu .F.
endi
Cdir := alltrim(cDIR)
if !empty(cDIR)
   if rsvp("Apagar "+cdir+"? (S/N)") = "S"
      nLASTREC := LASTREC()
      zei_fort(nLASTREC,,,0)
      DBEVAL({|| netrecdel()},{|| &cDIR.},{|| zei_fort(nLASTREC,,,1)})
      stat_msg(cDIR+" Apagado")
   endif
endif



*+--------------------------------------------------------------------
*+
*+
*+
*+    Function DBUREDE()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
function DBUREDE(cARQ,cIND,lMODO)


local cEXT := XEXT()
if valtype(lMODO) # "L"
   lMODO := .T.
endif
if valtype(cARQ) # "C"
   ALERTX("Funcao DBUREDE, Nome do Arquivo nao e Caracter")
   retu .F.
endif
if (!HB_FILEEXISTS(cARQ)) .and. (!HB_FILEEXISTS(cARQ+"."+TABLEEXT))
   ALERTX("Arquivo de Dados Nao Encontado")
   retu .F.
endif
USOVIA := RDDNOME(TIPODBF)
while .T.
   //dbusearea( .T., USOVIA, cARQ,, !lMODO )
  // DBUseArea( <lNewArea> , <cDriver> , <cName>, <xcAlias> , <lShared> , <lReadOnly>,<cCodePage>,<nConnection> ) -> lSuccess
   IF lMODO
      dbUseArea( .T., USOVIA, (cARQ),, .F. , .F. )
   ELSE
      dbUseArea( .T., USOVIA, (cARQ),, .T. , .F. )
   ENDIF
   if !neterr()
      exit
   endif
   KEY := inkey(.5)
   if KEY = K_ESC
      dbclosearea()
      retu .F.
   endif
   MDS("Nao Estou Conseguindo Abrir aquivo "+cARQ)
enddo
if valtype(cIND) = "C"
   if file(cIND) .or. HB_FILEEXISTS(cIND+cEXT)
      ordlistadd(cIND)
      //      DBSETINDEX(cIND)
   else
      ALERTX("Arquivo de Indices Nao Encontrado ")
   endif
endif
return .T.




*+--------------------------------------------------------------------
*+
*+
*+
*+    Function READDBU()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
function READDBU


setcursor(if(readinsert(),1,2))
read
setcursor(0)
if lastkey() == K_ESC
   retu .F.
endif
return .T.



*+--------------------------------------------------------------------
*+
*+
*+
*+    Function LNKFUN()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
FUNCTION LNKFUN()

DECODE()
ENCODE()
DESCEND()
HB_DATETIME()
HB_CTOD()
HB_DTOC()
HB_NTOT()
HB_TTON()
HB_TTOC()
HB_CTOT()
HB_TTOS()
HB_STOT()
HB_TSTOSTR()
HB_STRTOTS()
HB_HOUR()
HB_MINUTE()
HB_SEC()
RETURN .T.


*+--------------------------------------------------------------------
*+
*+
*+
*+    Function errindex()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
function errindex()

return .t.


*+--------------------------------------------------------------------
*+
*+
*+
*+    Function errprinter()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
function errprinter()

return .t.


*+ EOF: dbu.prg
*+
