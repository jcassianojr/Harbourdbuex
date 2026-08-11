// +--------------------------------------------------------------------
// +
// +   git\core\contrib\hbpgsql\
// +   git\xharbour\contrib\pgsql\pgrdd\pgrdd.prg
// +
// +
// +--------------------------------------------------------------------
// +

// +--------------------------------------------------------------------
// +
// +
// +
// +    Programa  : dbupgexp.prg
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

REQUEST PGRDD

// +--------------------------------------------------------------------
// +
// +
// +
// +    Function PGexpformat()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION PGexpformat()

   PGSELECTTABLE()
   LCOPIANAT := .F.  // MDG("Copia Nativa(SIM) Interna(NAO)") //copy to nao implemntado PGsqlrddd
   tDOC      := pegtipodoc()   // .t. Inclui dbf se for nativa
   pegparexp()
   lDOCCAB   := .F.
   lDOCDAD   := .F.
   lDOCRECNO := .F.
   cSUBTIPO  := " "

   PegcsUB( tDOC )   // pegar o subtipo conforme tipo

   cDESTINO := cTABELAX + "_PGsql." + zEXPOREXT
   MDT( cDESTINO )

   MDT( "abrindo arquivo de origem: " + cTABELAX )

   nConn := dbPGconnection( cSERVERX + ";" + CdatabaseX + ";" + CuserX + ";" + CpassX + ";5432;public" )
   dbUseArea( .T., "PGRDD", "SELECT * FROM " + Chr( 34 ) + cTABELAX + Chr( 34 ), cTABELAX )
   nLASTREC := LastRec()
   zei_fort( nLASTREC,,, 0 )
   aSTRU := PGstrudbf()
   multidocg( lDOCCAB, lDOCDAD, lDOCRECNO, cSUBTIPO, TIRAEXT( cDESTINO ), aSTRU )
   dbCloseAll()
   dbpgclearconnection( nConn )

   RETURN NIL



// + EOF: dbupgexp.prg
// +
