// +--------------------------------------------------------------------
// +   git\core\contrib\hbmysql\
// +   git\xharbour\contrib\mysql\mysqlrdd.prg
// +
// +
// +--------------------------------------------------------------------
// +

// +--------------------------------------------------------------------
// +
// +
// +
// +    Programa  : dbumyexp.prg
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

REQUEST MYSQLRDD


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function myexpformat()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION myexpformat()

   MYSELECTTABLE()
   LCOPIANAT := .F.  // MDG("Copia Nativa(SIM) Interna(NAO)") //copy to nao implemntado mysqlrddd
   tDOC      := pegtipodoc()   // .t. Inclui dbf se for nativa
   pegparexp()
   lDOCCAB   := .F.
   lDOCDAD   := .F.
   lDOCRECNO := .F.
   cSUBTIPO  := " "

   PegcsUB( tDOC )   // pegar o subtipo conforme tipo

   cDESTINO := cTABELAX + "_mysql." + zEXPOREXT
   MDT( cDESTINO )

   MDT( "abrindo arquivo de origem: " + cTABELAX )

   nConn := dbmysqlconnection( cSERVERX + ";" + CdatabaseX + ";" + CuserX + ";" + CpassX + ";3306" )
   dbUseArea( .T., "MYSQLRDD", "SELECT * FROM " + cTABELAX, cTABELAX )

   nLASTREC := LastRec()
   zei_fort( nLASTREC,,, 0 )

   aSTRU := mystrudbf()

   multidocg( lDOCCAB, lDOCDAD, lDOCRECNO, cSUBTIPO, TIRAEXT( cDESTINO ), aSTRU )

   dbCloseAll()
   dbmysqlclearconnection( nConn )

   RETURN NIL



// + EOF: dbumyexp.prg
// +
