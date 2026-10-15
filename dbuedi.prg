*+--------------------------------------------------------------------
*+
*+
*+
*+    Programa  : dbuedi.prg
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


*+--------------------------------------------------------------------
*+
*+
*+
*+    Function EDITXT()
*+
*+
*+
*+--------------------------------------------------------------------
*+
*+
*+
FUNCTION EDITXT


LOCAL NOMEARQ

IF !lEDITXT
   ALERTX('Ja esta sendo editado um texto')
   RETURN .F.
ENDIF
nomearq := win_GetOpenFileName(,"Ler conteudo",hb_cwd(),"txt","*.txt",1)
IF !hb_FileExists(nomearq)
   ALERTX('Nao Encontrei Este Arquivo')
   RETURN .F.
ENDIF
lEDITXT := .F.
EDItarq(nomearq)
lEDITXT := .T.

RETURN .T.


*+ EOF: dbuedi.prg
*+
