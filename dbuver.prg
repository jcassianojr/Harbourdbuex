// +--------------------------------------------------------------------
// +
// +
// +
// +    Programa  : dbuver.prg
// +
// +
// +
// +     Sistema:
// +
// +     Linguagem: Harbour
// +
// +     Autor: jcassiano
// +
// +     Copyright (c) 2024,  jcassiano
// +
// +
// +
// +
// +
// +    Documentado em 28-Dez-2024 as 10:07 am
// +
// +
// +
// +--------------------------------------------------------------------
// +




// +--------------------------------------------------------------------
// +
// +
// +
// +    Function VERTXT()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNC VERTXT

   IF !lVERTXT
      ALERTX( 'J  esta sendo exibido um texto' )
      RETU
   ENDIF
   VER_ROW := Row()
   VER_COL := Col()
   VER_SCR := SaveScreen( 00, 00, 24, 79 )
   VER_COR := SetColor()
   @ 24, 00 clear
   PRIV GETLIST := {}
   PRIV DADO    := Space( 80 )
   MDS( "Digite o nome do Arquivo" )
   @ 24, 40 GET DADO PICT "@S40"
   READDBU()
   DADO := AllTrim( DADO )
   IF !hb_FileExists( DADO )
      ALERTX( 'N„o Encontrei Este Arquivo' )
      SetColor( VER_COR )
      RestScreen( 00, 00, 24, 79, VER_SCR )
      SetPos( VER_ROW, VER_COL )
      RETU .F.
   ENDIF
   lVERTXT := .F.
   CLEA
   SetColor( "N/W" )
   @ 00, 00 CLEAR TO 00, 79
   @ 24, 00 CLEAR TO 24, 79
   @ 24, 00 SAY '[Arq.:' + DADO + ']'
   @ 00, 00 SAY "       " + spac( 6 ) + "           ÝÝ Mover: " + Chr( 24 ) + " " + Chr( 25 ) + " PGUP PGDN  HOME  END          Ý Sair: ESC "
   SetColor( "W/R" )
// READTEXT( DADO, 01, 00, 23, 79 )
   vertxt( dado )
   SetColor( VER_COR )
   RestScreen( 00, 00, 24, 79, VER_SCR )
   SetPos( VER_ROW, VER_COL )
   lVERTXT := .T.
   RETU


// + EOF: dbuver.prg
// +
