// +--------------------------------------------------------------------
// +
// +    Programa  : dbusincdbf.prg
// +
// +     Sistema:
// +
// +     Linguagem: Harbour
// +
// +     Autor: jcassiano
// +
// +     Copyright (c) 2024,  jcassiano
// +
// +    Documentado em 28-Dez-2024 as 10:07 am
// +
// +--------------------------------------------------------------------
// +

#include "dbinfo.ch"


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function dBUsincdbf()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION dBUsincdbf()

   aAMBIENTE := SALVAA()
   nOLDTIPO  := TIPODBF

   alertX( "escolha origem" )
   tipodbfesc()
   nORITIPO   := TIPODBF
   cORIDRIVER := RDDNOME( TIPODBF )
   cARQORI    := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*."+TABLEEXT, 1 )

   alertX( "escolha destino" )
   tipodbfesc()
   nDESTIPO   := TIPODBF
   cDESDRIVER := RDDNOME( TIPODBF )
   cARQDES    := win_GetOpenFileName(, "Arquivos de Destino", hb_cwd(), "Arquivos de Destino", "*."+TABLEEXT, 1 )
   lAPAGA     := MDG( "Apagar Dados do Arquivo de Destino" )
   lREPL      := .F.
   IF lAPAGA
      IF !MDG( "Deseja Realmente apagar dados da destino" )
         lAPAGA := .F.
      ENDIF
   ENDIF
   IF !lAPAGA
      lREPL := MDG( "Complentar campos em Branco" )
   ENDIF

   MDT( "Fazendo copia de reserva: " + "old_" + cARQDES )
   filecopy( cARQDES, trocaext( cARQDES, "_old."+TABLEEXT ) )

   MDT( "abrindo arquivo de origen: " + cARQORI )
   //USE ( cARQORI ) ALIAS ORIGEM SHARED NEW VIA ( cORIDRIVER )
   dbUseArea( .T., ( cORIDRIVER ), ( cARQORI ), "ORIGEM", .T. , .F. )

   MDT( "abrindo arquivo de destino: " + cARQDES )
   //USE ( cARQDES ) ALIAS DESTINO EXCLUSIVE NEW VIA ( cDESDRIVER )
   dbUseArea( .T., ( cDESDRIVER ), ( cARQDES ), "DESTINO", .F. , .F. )

   MDT( "Importando registros para: " + cARQDES )
   dbSelectAr( "ORIGEM" )
   INITVARS()
   CLRVARS()

   dbSelectAr( "DESTINO" )
   INITVARS()
   CLRVARS()
   IF lAPAGA
      ZAP
   ENDIF
   IF OrdCount() == 0
      dbcloseall()
      RDDNOME( nOLDTIPO )   // retorna tipo anterior
      RESTAA( aAMBIENTE )
      alertX("Erro: O destino precisa de um índice para sincronizar!")
      RETURN
   ENDIF
   
   dbSetOrder( 1 )
   cCHAVE := IndexKey()

   dbSelectAr( "ORIGEM" )
   nLASTREC := LastRec()
   zei_fort( nLASTREC,,, 0 )
   dbGoTop()
   WHILE !Eof()
      EQUVARS()
      xBUSCA := &CCHAVE.
      dbSelectAr( "DESTINO" )
      dbGoTop()
      IF ! dbSeek( xBUSCA )
         dbAppend()
         REPLVARS( .T., .T. )
      ELSE
         IF lREPL
            REPLVARS( .T., .T. )
         ENDIF
      ENDIF
      dbSelectAr( "ORIGEM" )
      dbSkip()
      ZEI_FORT( nLASTREC,,, 1 )
   ENDDO
   FREEVARS()
   dbCloseAll()

   RDDNOME( nOLDTIPO )   // retorna tipo anterior
   RESTAA( aAMBIENTE )
   alertX( "sincronizado" )



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function sortdbf()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +

FUNCTION sortdbf()

   LOCAL aCAMPOS

   aAMBIENTE := SALVAA()
   nOLDTIPO  := TIPODBF
   cSORTED   := Space( 60 )

   alertX( "escolha origem" )
   tipodbfesc()
   nORITIPO   := TIPODBF
   cORIDRIVER := RDDNOME( TIPODBF )
   cARQORI    := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*."+TABLEEXT, 1 )

   alertX( "escolha destino" )
   tipodbfesc()
   nDESTIPO   := TIPODBF
   cDESDRIVER := RDDNOME( TIPODBF )
   cARQDES    := trocaext( cARQORI, "_sorted."+TABLEEXT )

   @ MaxRow()-1, 0      SAY "Digite os Campos separados por virgula  (,)"
   @ MaxRow(), 1 GET cSORTED
   READ
   

   MDT( "Fazendo copia de destino: " + "sortet_" + cARQORI )
   filecopy( cARQORI, cARQDES )

   MDT( "abrindo arquivo de origem: " + cARQORI )
   //USE ( cARQORI ) ALIAS ORIGEM EXCLUSIVE NEW VIA ( cORIDRIVER )
   dbUseArea( .T., ( cORIDRIVER ), ( cARQORI ), "ORIGEM", .F. , .F. )
   
   IF !ValidarCampos( cSORTED )
      // Se for invalido, interrompe a execucao
      dbcloseall()
      RDDNOME( nOLDTIPO )
      RESTAA( aAMBIENTE )
      RETURN NIL
   ENDIF
   aCAMPOS := hb_ATokens( cSORTED, "," )
   

   mdt( "Ordenando por: " + cSORTED )
// __dbSort( cToFileName, aFields, bFor, bWhile, nNext, nRecord, lRest, cRDD     , nConnection, cCodePage )
   __dbSort( cARQDES, aCAMPOS,,,,,, cDESDRIVER,, )

   dbcloseall()
   RDDNOME( nOLDTIPO )   // retorna tipo anterior
   RESTAA( aAMBIENTE )
   alertX( "sincronizado" )

// +--------------------------------------------------------------------
// + Funcao para validar se os nomes de campos em uma string (separados por virgula)
// + existem no alias atual.
// +--------------------------------------------------------------------
STATIC FUNCTION ValidarCampos( cCampos )
   LOCAL aCampos  := hb_ATokens( cCampos, "," )
   LOCAL cCampo   := ""
   LOCAL lValido  := .T.
   LOCAL nPos     := 0

   IF Empty( cCampos )
      alertX( "Nenhum campo informado!" )
      RETURN .F.
   ENDIF

   FOR EACH cCampo IN aCampos
      cCampo := AllTrim( cCampo )
      
      // Verifica se o campo existe na estrutura do DBF atual
      IF FieldPos( cCampo ) == 0
         alertX( "Campo invalido: " + cCampo )
         lValido := .F.
         EXIT
      ENDIF
   NEXT

RETURN lValido


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function limparegdupdbf()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +

FUNCTION limparegdupdbf()

   aAMBIENTE := SALVAA()
   nOLDTIPO  := TIPODBF

   alertX( "escolha origem" )
   tipodbfesc()
   nORITIPO   := TIPODBF
   cORIDRIVER := RDDNOME( TIPODBF )
   cARQORI    := win_GetOpenFileName(, "Arquivos de Origem", hb_cwd(), "Arquivos de Origem", "*."+TABLEEXT, 1 )

   lPACK := MDG( "Fazer pack(remove registros marcados para apagar) apos a checagem" )

   MDT( "Fazendo copia de reserva: " + "old_" + cARQORI )
   filecopy( cARQORI, trocaext( cARQORI, "_old."+TABLEEXT ) )

   MDT( "abrindo arquivo de origem: " + cARQORI )
   //USE ( cARQORI ) ALIAS ORIGEM EXCLUSIVE NEW VIA ( cORIDRIVER )
   dbUseArea( .T., ( cORIDRIVER ), ( cARQORI ), "ORIGEM", .F., .F. )

   MDT( "Limpando Registro Duplicados: " )
   dbSelectArEA( "ORIGEM" )
   dbSetOrder( 1 )
   cCHAVE   := IndexKey()
   nLASTREC := LastRec()
   zei_fort( nLASTREC,,, 0 )
   dbGoTop()
   WHILE !Eof()
      xCHAVEANTERIOR := &CCHAVE.
      dbSkip()
      ZEI_FORT( nLASTREC,,, 1 )
      IF !Eof()
         xCHAVEATUAL := &CCHAVE.
         IF xCHAVEANTERIOR == xCHAVEATUAL
            dbDelete()
         ENDIF
      ENDIF
   ENDDO
   MDT( "Fazendo pack(removendo registros marcados para apagar)" )
   IF lPACK
      PACK
   ENDIF
   dbCloseAll()

   RDDNOME( nOLDTIPO )   // retorna tipo anterior
   RESTAA( aAMBIENTE )
   alertX( "chaves duplicadas removidas" )

// + EOF: dbusincdbf.prg
// +
