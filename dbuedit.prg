*+--------------------------------------------------------------------
*+
*+
*+
*+    Programa  : dbuedit.prg
*+
*+
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
*+
*+
*+
*+    Documentado em 15-Out-2026 as  2:12 pm
*+
*+
*+
*+--------------------------------------------------------------------
*+

#include "BOX.CH"
#include "inkey.ch"
#include "memoedit.ch"



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function browse()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION browse


LOCAL i
LOCAL j
LOCAL nHelpSave
LOCAL cNtx
LOCAL cFieldArray
LOCAL cFieldName
LOCAL nWa
LOCAL cMemo
LOCAL oB
LOCAL nRec
LOCAL cBrowseBuf
LOCAL nPrimeArea
LOCAL nHsepRow
LOCAL cEditField
LOCAL bAlias
LOCAL cAlias
LOCAL nCType
LOCAL cHead
LOCAL lMore
LOCAL lCanAppend
LOCAL cMemoBuff
LOCAL aMoveExp
LOCAL cPrimeDbf
LOCAL nColorSave
LOCAL lAppend
LOCAL lGotKey
LOCAL lKillAppend
LOCAL bColBlock
MEMVAR keystroke
MEMVAR help_code
MEMVAR func_sel
MEMVAR cur_area
MEMVAR cur_dbf
MEMVAR field_list
MEMVAR frame
MEMVAR curs_on
MEMVAR cur_ntx
MEMVAR ntx1
MEMVAR dbf
MEMVAR local_func
MEMVAR box_open
MEMVAR color1
MEMVAR color7
MEMVAR color8
MEMVAR color9

nCType  := SetCursor(0)
curs_on := .F.

nHelpSave := help_code

cBrowseBuf := SaveScreen(8,0,MaxRow() - 1,MaxCol())

aMoveExp := Array(4)
AFill(aMoveExp,"")

nHsepRow := 11

IF (func_sel == 1)
   nPrimeArea  := cur_area
   cFieldArray := "field_n"+SubStr("123456",cur_area,1)
   cNtx        := "ntx"+SubStr("123456",cur_area,1)
   cur_ntx     := &cNtx[1]
   cPrimeDbf   := SubStr(cur_dbf,RAt(hb_ps(),cur_dbf)+1)
   lCanAppend  := .T.
ELSE
   nPrimeArea  := 1
   cFieldArray := "field_list"
   cur_ntx     := ntx1[1]
   cPrimeDbf   := SubStr(dbf[1],RAt(hb_ps(),dbf[1])+1)
   lCanAppend  := .F.

   IF ("->" $ field_list[afull(field_list)])
      nHsepRow := 12
   END
END

bAlias := &("{|i| if('->' $"+cFieldArray+"[i], Substr("+;
 cFieldArray+"[i], 1, At('->',"+cFieldArray+;
 "[i]) - 1), '')}")

SELECT (nPrimeArea)
IF (Eof())
   GO TOP
END

lAppend := .F.
nRec    := 0

nColorSave := SetColor(color7)
oB         := TBrowseDB(10,1,MaxRow() - 1,MaxCol() - 1)

oB:headSep   := "-Ñ-"
oB:colSep    := " Ý "
oB:footSep   := "-Ï-"
oB:skipBlock := {| x | Skipped(x,lAppend)}

j := Len(&cFieldArray)
FOR i := 1 TO j
   IF (Empty(&cFieldArray[i]))
      EXIT
   END

   cEditField := &cFieldArray[i]
   IF ("->" $ cEditField)
      cAlias     := SubStr(cEditField,1,At("->",cEditField)+1)
      cFieldName := SubStr(cEditField,At("->",cEditField)+2)
      cHead      := cAlias+";"+cFieldName
      nWa        := SELECT (cAlias)
   ELSE
      cAlias     := ""
      cFieldName := cHead := cEditField
      nWa        := SELECT ()
   END

   IF (ValType(&cEditField) == "M")
      bColBlock := &("{|| '  <Memo>  '}")
   ELSE
      bColBlock := FieldWBlock(cFieldName,nWa)
   END

   oB:addColumn(TBColumnNew(cHead,bColBlock))
NEXT

stat_msg("")
Scroll(8,0,MaxRow() - 1,MaxCol(),0)
hb_DispBox(8,0,MaxRow() - 1,MaxCol(),frame)
@ nHsepRow,0  SAY "Æ"         
@ nHsepRow,79 SAY "µ"         

cAlias      := ""
lKillAppend := .F.
IF ((LastRec() == 0) .AND. lCanAppend)
   keystroke := K_DOWN
   lGotKey   := .T.
ELSE
   lGotKey := .F.
END

lMore := .T.
WHILE (lMore)
   IF (!lGotKey)
      WHILE (!oB:stabilize())
         IF ((keystroke := Inkey()) != 0)
            lGotKey := .T.
            EXIT
         END
      END
   END

   IF (!lGotKey)
      IF (oB:hitBottom .AND. lCanAppend)
         IF (!lAppend .OR. RecNo() != LastRec()+1)
            IF (lAppend)
               oB:refreshCurrent()
               WHILE (!oB:stabilize())
               END
               GO BOTTOM
            ELSE
               lAppend := .T.
               SetCursor(1)
               curs_on := .T.
            END

            oB:down()
            WHILE (!oB:stabilize())
            END
            oB:colorRect({oB:rowPos,1,oB:rowPos,oB:colCount},{2,2})
         END
      END

      cAlias := Eval(bAlias,oB:colPos)
      statline(oB,lAppend,cAlias)

      WHILE (!oB:stabilize())
      END

      keystroke := Inkey(0)
   ELSE
      lGotKey := .F.
   END

   DO CASE
   CASE keystroke == K_DOWN
      IF (lAppend)
         oB:hitBottom := .T.
      ELSE
         oB:down()
      END

   CASE keystroke == K_UP
      IF (lAppend)
         lKillAppend := .T.
      ELSE
         oB:up()
      END

   CASE keystroke == K_PGDN
      IF (lAppend)
         oB:hitBottom := .T.
      ELSE
         oB:pageDown()
      END

   CASE keystroke == K_PGUP
      IF (lAppend)
         lKillAppend := .T.
      ELSE
         oB:pageUp()
      END

   CASE keystroke == K_CTRL_PGUP
      IF (lAppend)
         lKillAppend := .T.
      ELSE
         oB:goTop()
      END

   CASE keystroke == K_CTRL_PGDN
      IF (lAppend)
         lKillAppend := .T.
      ELSE
         oB:goBottom()
      END

   CASE keystroke == K_RIGHT
      oB:Right()

   CASE keystroke == K_LEFT
      oB:Left()

   CASE keystroke == K_HOME
      oB:home()

   CASE keystroke == K_END
      oB:end()

   CASE keystroke == K_CTRL_LEFT
      oB:panLeft()

   CASE keystroke == K_CTRL_RIGHT
      oB:panRight()

   CASE keystroke == K_CTRL_HOME
      oB:panHome()

   CASE keystroke == K_CTRL_END
      oB:panEnd()

   CASE keystroke == K_DEL
      WHILE (!oB:stabilize())
      END
      cAlias := Eval(bAlias,oB:colPos)
      IF (!Empty(cAlias))
         SELECT (cAlias)
      END

      IF (RecNo() != LastRec()+1)
         IF Deleted()
            RECALL
         ELSE
            netrecdel()
         END
      END

      SELECT (nPrimeArea)

   CASE keystroke == K_INS
      tog_insert()

   CASE keystroke == K_ENTER .OR. ;
       keystroke == K_ALT_INS .OR. ;
       keystroke == K_ALT_O .OR. ;
       keystroke == K_ALT_P .OR. ;
       keystroke == K_ALT_G .OR. ;
       keystroke == K_ALT_K .OR. ;
       keystroke == K_ALT_L .OR. ;
       keystroke == K_ALT_B .OR. ;
       keystroke == K_ALT_N .OR. ;
       keystroke == K_ALT_M

      WHILE (!oB:stabilize())
      END
      cAlias := Eval(bAlias,oB:colPos)

      IF (!Empty(cAlias))
         SELECT (cAlias)
      END

      IF (!lAppend .AND. (RecNo() == LastRec()+1))
         SELECT (nPrimeArea)
         LOOP
      END

      SELECT (nPrimeArea)

      oB:hitTop := .F.
      Statline(oB,lAppend,cAlias)
      WHILE (!oB:stabilize())
      END

      cEditField := &cFieldArray[oB:colPos]

      SetCursor(1)
      curs_on := .T.

      IF keystroke == K_ALT_INS
         XALTINS()
      ENDIF

      IF (Type(cEditField) == "M")
         help_code := 19
         box_open  := .T.

         cMemoBuff := SaveScreen(08,00,MaxRow(),MaxCol() - 1)

         SetColor(color8)
         Scroll(08,00,MaxRow(),MaxCol() - 1,0)
         hb_DispBox(8,0,MaxRow() - 1,MaxCol(),frame)
         @ 24,01 SAY 'Linha:'+spac(5)+'Coluna:'               
         @ 24,40 SAY 'Ctrl+W -> Grava, ESC -> Anula '         

         SetColor(color9)
         @ 08,((76 - Len(cEditField)) / 2) SAY "  "+cEditField+"  "         

         SetColor(color8)
         // cMemo := memoedit( &cEditField, 09, 01, 22, 78, .T., "xmemo" )
         cMemo := MemoEdit(&cEditField,11,11,MaxRow() - 3,68,.T.,"xmemo")

         IF LastKey() == K_CTRL_END

            IF (lAppend .AND. Eof())
               netrecapp()
            END

            netreclock()
            field->&cEditField := cMemo
            dbUnlock()

            oB:refreshCurrent()

            keystroke := K_RIGHT
            lGotKey   := .T.
         ELSE
            keystroke := 0
         END


         RestScreen(08,00,MaxRow(),MaxCol() - 1,cMemoBuff)

         box_open := .F.
      ELSE
         SetColor(color1)
         keystroke := DoGet(oB,lAppend,cAlias)
         lGotKey   := (keystroke != 0)
      END

      IF (!lAppend)
         SetCursor(0)
         curs_on := .F.
      END

      help_code := nHelpSave
      SetColor(color7)

      // Control+Ins - Capturando
   CASE keystroke == K_CTRL_INS
      WHILE (!oB:stabilize())
      END
      cAlias := Eval(bAlias,oB:colPos)
      IF (!Empty(cAlias))
         SELECT (cAlias)
      END
      IF (!lAppend .AND. (RecNo() == LastRec()+1))
         SELECT (nPrimeArea)
         LOOP
      END
      SELECT (nPrimeArea)
      oB:hitTop := .F.
      Statline(oB,lAppend,cAlias)
      WHILE (!oB:stabilize())
      END
      cEditField := &cFieldArray[oB:colPos]
      READVAR    := &cEditField
   OTHERWISE
      IF (isdata(keystroke))
         KEYBOARD Chr(K_ENTER)+Chr(keystroke)
      ELSE
         // Chama Leityra da Tecla
         sysmenu()

         DO CASE
         CASE q_check()
            lMore := .F.

         CASE local_func == 7
            nRec := RecNo()
            move_ptr(aMoveExp,cPrimeDbf)

            IF (nRec != RecNo())
               IF (lAppend)
                  lKillAppend := .T.
               ELSE
                  FreshOrder(oB)
               END
            END
         END
      END
   END

   IF (lKillAppend)
      lKillAppend := .F.
      lAppend     := .F.

      FreshOrder(oB)
      SetCursor(0)
      curs_on := .F.
   END
END

RestScreen(8,0,MaxRow() - 1,MaxCol(),cBrowseBuf)
SetColor(nColorSave)
SetCursor(nCType)
curs_on := (nCType != 0)
stat_msg("")

RETURN


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function xmemo()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNC xmemo(mmode,line,col)


LOCAL nRet
MEMVAR keystroke
MEMVAR local_func

SetColor(color9)
@ 24,07 SAY line PICT '####'        
@ 24,19 SAY col  PICT '####'        
SetColor(color8)

nRet := 0

IF mmode <> ME_IDLE
   keystroke := LastKey()
   sysmenu()

   DO CASE
   CASE keystroke == K_ALT_INS
      XALTINS()
   CASE keystroke == K_INS
      tog_insert()
      nRet := ME_IGNORE

   CASE keystroke == K_ESC
      IF mmode == ME_UNKEYX
         IF rsvp("Ok. Abandonar Mudan‡as? (S/N)") <> "S"
            nRet := ME_IGNORE
         END
      END
   END
END

RETURN (nRet)


// +--------------------------------------------------------------------
// +
// +
// +
// +    Static Function tog_insert()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
STATIC FUNC tog_insert


LOCAL nCType

ReadInsert(!ReadInsert())
nCType := SetCursor(0)
show_insert()
SetCursor(nCType)

RETURN (0)


// +--------------------------------------------------------------------
// +
// +
// +
// +    Static Function show_insert()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
STATIC FUNC show_insert


LOCAL nColorSave

nColorSave := SetColor(color7)
@  9,4 SAY if(ReadInsert(),"<Inserindo>","           ")         
SetColor(nColorSave)

RETURN (0)


// +--------------------------------------------------------------------
// +
// +
// +
// +    Static Function statline()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
STATIC FUNC statline(oB,lAppend,cAlias)


LOCAL cColorSave
LOCAL cCurrAlias
LOCAL lNoFilter
LOCAL nWaSave
LOCAL nCType

nCType := SetCursor(0)

nWaSave := SELECT ()
IF (!Empty(cAlias))
   SELECT (cAlias)
END

cColorSave := SetColor(color7)

show_insert()

lNoFilter := Empty(&("kf"+SubStr("123456",Select(),1)))
@  9,16 SAY if(lNoFilter,"        ","<Filtro>")         

@  9,41 SAY if(Empty(cAlias),Space(10),Lpad(cAlias+"->",10)) ;         
 +"Reg :"

IF (EmptyFile() .AND. !lAppend)
   @  9,57 SAY "<nada>              "         
ELSEIF (Eof())
   @  9,28 SAY "         "                                         
   @  9,57 SAY "            "+if(lAppend,"<novo>","<fim>")         
ELSE
   @  9,28 SAY if(Deleted(),"<Apagado>","         ")                           
   @  9,57 SAY Pad(LTrim(Str(RecNo()))+"/"+LTrim(Str(LastRec())),15)+;         
    IF (oB:hitTop," <Ini>",if(oB:hitBottom," <fim>","      "))
END

SetColor(cColorSave)
SELECT (nWaSave)
SetCursor(nCType)

RETURN (0)


// +--------------------------------------------------------------------
// +
// +
// +
// +    Static Function move_ptr()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
STATIC FUNC move_ptr(aMoveExp,cPrimeDbf)


LOCAL nHelpSave
LOCAL aBox
MEMVAR okee_dokee
MEMVAR k_trim
MEMVAR movp_sel
MEMVAR titl_str
MEMVAR exp_label
MEMVAR help_code
MEMVAR local_sel
MEMVAR ntx_expr
PRIVATE okee_dokee
PRIVATE k_trim
PRIVATE movp_sel
PRIVATE titl_str
PRIVATE exp_label
PRIVATE ntx_expr

nHelpSave := help_code

movp_sel := local_sel

k_trim := aMoveExp[movp_sel]

aBox := Array(4)

aBox[ 1 ] := "movp_title(sysparam)"
aBox[ 2 ] := "movp_exp(sysparam)"
aBox[ 3 ] := "ok_button(sysparam)"
aBox[ 4 ] := "can_button(sysparam)"

DO CASE
CASE movp_sel == 1
   okee_dokee := "do_seek()"
   titl_str   := "Busca no Arquivo "+cPrimeDbf+"..."
   exp_label  := "Express„o"
   ntx_expr   := IndexKey(0)
   help_code  := 13

CASE movp_sel == 2
   okee_dokee := "do_goto()"
   titl_str   := "Mover pontos no arquivo "+cPrimeDbf+" para..."
   exp_label  := "Registro#"
   help_code  := 14

CASE movp_sel == 3
   okee_dokee := "do_locate()"
   titl_str   := "Localizando no arquivo "+cPrimeDbf+"..."
   exp_label  := "Express„o"
   help_code  := 10

CASE movp_sel == 4
   okee_dokee := "do_skip()"
   titl_str   := "Pulando registro no arquivo "+cPrimeDbf+"..."
   exp_label  := "N£mero"
   help_code  := 20
END

SET KEY K_INS TO tog_insert
multibox(14,17,5,2,aBox)
SET KEY K_INS TO

aMoveExp[ movp_sel ] := k_trim

help_code := nHelpSave

RETURN (0)


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function movp_title()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNC movp_title(sysparam)


MEMVAR titl_str

RETURN (box_title(sysparam,titl_str))


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function movp_exp()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNC movp_exp(sysparam)


MEMVAR exp_label

RETURN (get_k_trim(sysparam,exp_label))


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function do_seek()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNC do_seek


LOCAL lDone
LOCAL nRec
LOCAL cSeekType
MEMVAR k_trim
MEMVAR ntx_expr

lDone := .F.

IF Empty(k_trim)
   error_msg("Express„o n„o entrada")
ELSE
   stat_msg("Procurando..")

   nRec := RecNo()

   cSeekType := Type(ntx_expr)

   DO CASE
   CASE cSeekType == "C"
      SEEK k_trim

   CASE cSeekType == "N"
      SEEK Val(k_trim)

   CASE cSeekType == "D"
      SEEK CToD(k_trim)
   END

   IF Found()
      stat_msg("Encontrado")
      lDone := .T.
   ELSE
      error_msg("N„o Encontrado")
      GOTO nRec
   END
END

RETURN (lDone)


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function do_goto()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNC do_goto


LOCAL lDone
LOCAL nWhich
MEMVAR k_trim

lDone  := .F.
nWhich := Val(k_trim)

DO CASE
CASE Empty(k_trim)
   error_msg("N£mero de Registro n„o fornecido")

CASE !SubStr(LTrim(k_trim),1,1) $ "-+1234567890"
   error_msg("N£mero de Registro n„o ‚ num‚rico")

CASE nWhich <= 0 .OR. nWhich > LastRec()
   error_msg("Registro fora de faixa")

OTHERWISE
   GOTO nWhich
   lDone := .T.

END

RETURN (lDone)


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function do_locate()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNC do_locate


LOCAL lDone
LOCAL nRec
MEMVAR k_trim

lDone := .F.

DO CASE
CASE Empty(k_trim)
   error_msg("Express„o n„o forencida")

CASE Type(k_trim) <> "L"
   error_msg("Express„o tipo deve ser L¢gica")

OTHERWISE
   nRec := RecNo()
   stat_msg("Procurando..")

   IF &k_trim
      SKIP
   END

   LOCATE FOR &k_trim WHILE .T.

   IF Found()
      stat_msg("Achado")
      lDone := .T.

   ELSE
      error_msg("N„o Achado")
      GOTO nRec
   END
END

RETURN (lDone)


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function do_skip()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNC do_skip


LOCAL lDone
LOCAL nSkip
MEMVAR k_trim

lDone := .F.
nSkip := Val(k_trim)

DO CASE
CASE Empty(k_trim)
   error_msg("Forne‡a o n£mero de saltos")

CASE !SubStr(LTrim(k_trim),1,1) $ "-+1234567890"
   error_msg("Saltos n„o ‚ um valor n£merico")

CASE nSkip == 0
   error_msg("Salto com valor zero")

OTHERWISE
   lDone := .T.

   SKIP nSkip

   IF Eof()
      GO BOTTOM
   END

   IF Bof()
      GO TOP
   END
END

RETURN (lDone)


// +--------------------------------------------------------------------
// +
// +
// +
// +    Static Function EmptyFile()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
STATIC FUNC EmptyFile()


IF (LastRec() == 0)
   RETURN (.T.)
END

IF ((Eof() .OR. RecNo() == LastRec()+1) .AND. Bof())
   RETURN (.T.)
END

RETURN (.F.)


// +--------------------------------------------------------------------
// +
// +
// +
// +    Static Function DoGet()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
STATIC FUNC DoGet(oB,lAppend,cAlias)


LOCAL lExitSave
LOCAL oCol
LOCAL oGet
LOCAL nKey
LOCAL cExpr
LOCAL xEval
LOCAL lFresh
LOCAL nWaSave

lExitSave := Set(_SET_EXIT,.T.)
nWaSave   := SELECT ()
IF (!Empty(cAlias))
   SELECT (cAlias)
END

SET KEY K_INS TO tog_insert
xkey_clear()

cExpr := IndexKey(0)
IF (!Empty(cExpr))
   xEval := &cExpr
END

oCol := oB:getColumn(oB:colPos)

mGetVar := Eval(oCol:block)

IF Type("mGetVar") = "C"
   DO CASE
   CASE keystroke == K_ALT_O
      XPOSESQ("",0,"mGetVar")
   CASE keystroke == K_ALT_P
      XPOSDIR("",0,"mGetVar")
   CASE keystroke == K_ALT_G
      XCENTER("",0,"mGetVar")
   CASE keystroke == K_ALT_K
      TIRACE(mGetVar)
   CASE keystroke == K_ALT_L
      XEXPAND("",0,"mGetVar")
   CASE keystroke == K_ALT_B
      XCAPFIRS("",0,"mGetVar")
   CASE keystroke == K_ALT_N
      CONVMINI(mGetVar)
   CASE keystroke == K_ALT_M
      CONVMAIS(mGetVar)
   ENDCASE
ENDIF

// Verifica se mGetVar e caracter e com string maior 78 da um pict @S
IF Type("mGetVar") = "C" .AND. Len(mGetVar) > MaxCol() - 1
   oGet := GetNew(Row(),Col(),;
    {| x | if(PCount() == 0,mGetVar,mGetVar := x)},;
    "mGetVar","@S"+hb_ntos(MaxCol() - 1))
ELSE
   oGet := GetNew(Row(),Col(),;
    {| x | if(PCount() == 0,mGetVar,mGetVar := x)},;
    "mGetVar")
ENDIF
lFresh := .F.

IF (ReadModal({oGet}))
   IF (lAppend .AND. RecNo() == LastRec()+1)
      netrecapp()
   END

   Eval(oCol:block,mGetVar)

   IF (!Empty(cExpr) .AND. !lAppend)
      IF (xEval != &cExpr)
         lFresh := .T.
      END
   END
END

SELECT (nWaSave)
IF (lFresh)
   FreshOrder(oB)

   nKey := 0
ELSE
   oB:refreshCurrent()

   nKey := ExitKey(lAppend)
END

IF (lAppend)
   oB:colorRect({oB:rowPos,1,oB:rowPos,oB:colCount},{2,2})
END

Set(_SET_EXIT,lExitSave)
SET KEY K_INS TO
xkey_norm()

RETURN (nKey)


// +--------------------------------------------------------------------
// +
// +
// +
// +    Static Function ExitKey()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
STATIC FUNC ExitKey(lAppend)


MEMVAR keystroke

keystroke := LastKey()
IF (keystroke == K_PGDN)
   IF (lAppend)
      keystroke := 0
   ELSE
      keystroke := K_DOWN
   END

ELSEIF (keystroke == K_PGUP)
   IF (lAppend)
      keystroke := 0
   ELSE
      keystroke := K_UP
   END

ELSEIF (keystroke == K_ENTER .OR. isdata(keystroke))
   keystroke := K_RIGHT

ELSEIF (keystroke != K_UP .AND. keystroke != K_DOWN .AND. menu_key() == 0)
   keystroke := 0
END

RETURN (keystroke)


// +--------------------------------------------------------------------
// +
// +
// +
// +    Static Function FreshOrder()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
STATIC FUNC FreshOrder(oB)


LOCAL nRec

nRec := RecNo()
oB:refreshAll()

WHILE (!oB:stabilize())
END

IF (nRec != LastRec()+1)
   WHILE (RecNo() != nRec)
      oB:up()
      WHILE (!oB:stabilize())
      END
   END
END

RETURN (NIL)


// +--------------------------------------------------------------------
// +
// +
// +
// +    Static Function Skipped()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
STATIC FUNC Skipped(nRequest,lAppend)


LOCAL nCount

nCount := 0
IF (LastRec() != 0)
   IF (nRequest == 0)
      SKIP 0

   ELSEIF (nRequest > 0 .AND. RecNo() != LastRec()+1)
      WHILE (nCount < nRequest)
         SKIP 1
         IF (Eof())
            IF (lAppend)
               nCount ++
            ELSE
               SKIP - 1
            END

            EXIT
         END

         nCount ++
      END

   ELSEIF (nRequest < 0)
      WHILE (nCount > nRequest)
         SKIP - 1
         IF (Bof())
            EXIT
         END

         nCount --
      END
   END
END

RETURN (nCount) 



*+ EOF: dbuedit.prg
*+
