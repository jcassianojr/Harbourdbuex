// +--------------------------------------------------------------------
// +
// +
// +
// +    Programa  : dbuindx.prg
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
// +    Function make_ntx()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION make_ntx

   LOCAL saveColor
   PRIVATE filename
   PRIVATE files
   PRIVATE fi_disp
   PRIVATE okee_dokee
   PRIVATE cur_el
   PRIVATE rel_row
   PRIVATE def_ext
   PRIVATE bcur
   PRIVATE fi_done
   PRIVATE el
   PRIVATE cr
   PRIVATE ntx
   PRIVATE k_exp
   PRIVATE k_tag

   cr  := "cr" + SubStr( "123456", M->cur_area, 1 )
   el  := "el" + SubStr( "123456", M->cur_area, 1 )
   ntx := "ntx" + SubStr( "123456", M->cur_area, 1 )

   filename := &ntx[ &el[ 2 ] ]

   saveColor := SetColor( M->color2 )
   @ &cr[ 2 ], column[ M->cur_area ] + 2 SAY Pad( name( M->filename ), 8 )

   SELECT ( M->cur_area )
   SET FILTER TO
   CLOSE INDEX
   need_filtr := .T.
   need_ntx   := .T.
   not_target( Select(), .F. )
   SELECT ( M->cur_area )

   cur_el  := 1
   rel_row := 0
   files   := "ntx_list"
   def_ext := XEXT()

   IF ! Empty( M->filename )
      k_exp := ntx_key( M->filename )
      bcur  := 4
   ELSE
      k_exp := ""
      bcur  := 2
   ENDIF
   k_tag := Space( 40 )

   boxarray := {}

   AAdd( boxarray, "ntx_title(sysparam)" )
   AAdd( boxarray, "ntx_getfil(sysparam)" )
   AAdd( boxarray, "ntx_exp(sysparam)" )
   IF tipodbf = 2 .OR. tipodbf = 4   // .or. tipodbf = 6
      AAdd( boxarray, "ntx_tag(sysparam)" )
   ENDIF
   AAdd( boxarray, "ok_button(sysparam)" )
   AAdd( boxarray, "can_button(sysparam)" )
   AAdd( boxarray, "filelist(sysparam)" )

   fi_disp    := "ntx_exist()"
   fi_done    := "ntx_done()"
   okee_dokee := "do_index()"

   IF multibox( 13, 17, 9, M->bcur, M->boxarray ) <> 0 .AND. ;
         aseek( &ntx, M->filename ) = 0

      IF M->n_files < 14 .OR. ! Empty( &ntx[ &el[ 2 ] ] )

         IF Empty( &ntx[ &el[ 2 ] ] )
            n_files := M->n_files + 1

         ENDIF

         &ntx[ &el[ 2 ] ] = M->filename

      ENDIF
   ENDIF

   saveColor := SetColor( M->color1 )
   @ &cr[ 2 ], column[ M->cur_area ] + 2 SAY Pad( name( &ntx[ &el[ 2 ] ] ), 8 )

   SetColor( saveColor )

   RETURN


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function ntx_title()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION ntx_title

   PARAMETERS sysparam

   RETURN box_title( M->sysparam, "Indice " + ;
      SubStr( M->cur_dbf, RAt( hb_ps(), M->cur_dbf ) + 1 ) + ;
      " para..." )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function ntx_getfil()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION ntx_getfil

   PARAMETERS sysparam

   RETURN getfile( M->sysparam, 4 )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function ntx_done()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION ntx_done

   PRIVATE done_ok

   done_ok := ! Empty( M->filename )

   IF M->done_ok

      IF File( M->filename ) .AND. Empty( M->k_exp )
         k_exp := ntx_key( M->filename )
         ntx_exp( 3 )

      ENDIF

      IF Empty( M->k_exp )
         KEYBOARD Chr( 24 )

      ELSE
         to_ok()

      ENDIF
   ENDIF

   RETURN M->done_ok


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function ntx_exp()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION ntx_exp

   PARAMETERS sysparam

   RETURN get_exp( M->sysparam, "CHAVE  ", 5, "k_exp" )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function ntx_tag()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION ntx_tag

   PARAMETERS sysparam

   RETURN get_exp( M->sysparam, "TAG    ", 6, "k_tag" )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function ntx_exist()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION ntx_exist

   IF Empty( M->k_exp )
      k_exp := ntx_key( M->filename )

   ENDIF

   ntx_getfil( 3 )
   ntx_exp( 3 )

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function do_index()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION do_index

   PRIVATE done
   PRIVATE n_dup
   PRIVATE new_el
   PRIVATE add_name

   n_dup := dup_ntx( M->filename )

   DO CASE

   CASE Empty( M->filename )
      error_msg( "Arquivo de indice n„o selecionado" )
      done := .F.

   CASE M->n_dup > 0 .AND. M->n_dup <> SELECT ()
      error_msg( "Indice em uso em outro arquivo" )
      done := .F.

   CASE Empty( M->k_exp )
      error_msg( "Chave de para indexa‡„o n„o fornecida" )
      done := .F.
   CASE ( TIPODBF = 2 .OR. TIPODBF = 4 ) .AND. Empty( M->K_TAG )   // OR TIPODBF=6
      error_msg( "Nome da TAG indexa‡„o n„o fornecida" )
      done := .F.

   CASE ! Type( M->k_exp ) $ "CND"
      error_msg( "Express„o chave n„o e v lida" )
      done := .F.

   OTHERWISE
      stat_msg( "Criando Arquivo de Indice" )
      mds( "" )
      add_name := ! hb_FileExists( name( M->filename ) + XEXT() )

      nLASTREC := LastRec()
      zei_fort( nLASTREC,,, 0 )
      IF .NOT. EINDEXCOMPOUND() // < descendente
         IF Left( K_EXP, 1 ) # "<"
            //INDEX ON &k_exp TO &filename eval zei_fort( nLASTREC,,, 1 )
            ordCondSet(,,,, {|| zei_fort( nLASTREC,,, 1 )},, RecNo(),,,,,,,,,,,,, ) ; ordCreate( filename,, k_exp, {|| &k_exp}, )
         ELSE
            K_EXP := SubStr( K_EXP, 2 )
            //INDEX ON &k_exp TO &filename eval zei_fort( nLASTREC,,, 1 )
            ordCondSet(,,,, {|| zei_fort( nLASTREC,,, 1 )},, RecNo(),,,,,,,,,,,,, ) ; ordCreate( filename,, k_exp, {|| &k_exp}, )
         ENDIF
      ELSE
         IF Left( K_EXP, 1 ) # "<"
            //INDEX ON &k_exp TAG &K_TAG TO &filename eval zei_fort( nLASTREC,,, 1 )
            ordCondSet(,,,, {|| zei_fort( nLASTREC,,, 1 )},, RecNo(),,,,,,,,,,,,, ) ; ordCreate( filename, K_TAG, k_exp, {|| &k_exp}, )
         ELSE
            K_EXP := SubStr( K_EXP, 2 )
            //INDEX ON &k_exp TAG &K_TAG TO &filename eval zei_fort( nLASTREC,,, 1 )
            ordCondSet(,,,, {|| zei_fort( nLASTREC,,, 1 )},, RecNo(),,,,,,,,,,,,, ) ; ordCreate( filename, K_TAG, k_exp, {|| &k_exp}, )
         ENDIF
      ENDIF
      CLOSE INDEX

      IF At( Lower( XEXT() ), Lower( M->filename ) ) = Len( M->filename ) - 3 .AND. ;
            hb_FileExists( name( M->filename ) + XEXT() ) .AND. M->add_name

         new_el := afull( M->ntx_list ) + 1

         IF M->new_el <= Len( M->ntx_list )
            ntx_list[ M->new_el ] = M->filename
            array_sort( M->ntx_list )

         ENDIF
      ENDIF

      stat_msg( "Arquivo Indexado" )
      done := .T.

   ENDCASE

   RETURN M->done




// + EOF: dbuindx.prg
// +
