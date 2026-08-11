// +--------------------------------------------------------------------
// +
// +
// +
// +    Programa  : dbucopy.prg
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
// +    Documentado em 28-Dez-2024 as 10:06 am
// +
// +
// +
// +--------------------------------------------------------------------
// +


#include "BOX.CH"

// +--------------------------------------------------------------------
// +
// +
// +
// +    Function capprep()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION capprep

   PRIVATE filename
   PRIVATE files
   PRIVATE fi_disp
   PRIVATE okee_dokee
   PRIVATE cur_el
   PRIVATE rel_row
   PRIVATE def_ext
   PRIVATE mode
   PRIVATE fi_done
   PRIVATE for_cond
   PRIVATE while_cond
   PRIVATE how_many
   PRIVATE bcur
   PRIVATE for_row
   PRIVATE height
   PRIVATE field_mvar
   PRIVATE with_what

   IF M->func_sel = 3
      help_code := 22

      SELECT ( M->cur_area )

      field_mvar := ""
      with_what  := ""

      DECLARE field_m[ FCount() ]
      all_fields( M->cur_area, M->field_m )

      DECLARE boxarray[ 9 ]
      boxarray[ 1 ] = "repl_title(sysparam)"
      boxarray[ 2 ] = "repl_field(sysparam)"
      boxarray[ 3 ] = "with_exp(sysparam)"
      boxarray[ 4 ] = "for_exp(sysparam)"
      boxarray[ 5 ] = "while_exp(sysparam)"
      boxarray[ 6 ] = "scope_num(sysparam)"
      boxarray[ 7 ] = "ok_button(sysparam)"
      boxarray[ 8 ] = "can_button(sysparam)"
      boxarray[ 9 ] = "fieldlist(sysparam)"

      bcur       := 9
      for_row    := 6
      height     := 10
      okee_dokee := "do_replace()"
      fi_disp    := "repl_field(3)"

   ELSE
      filename := ""

      DECLARE txt_list[ ADir( "*." + zEXPOREXT ) + 20 ]
      array_dir( "*." + zEXPOREXT, txt_list )

      DECLARE boxarray[ 10 ]

      IF M->func_sel = 1
         pegparexp()
         help_code := 12
         bcur      := 2
         boxarray[ 1 ] = "copy_title(sysparam)"
         boxarray[ 2 ] = "trg_getfil(sysparam)"
         fi_disp    := "trg_getfil(3)"
         okee_dokee := "do_copy()"

      ELSE
         pegparexp()
         help_code := 15
         bcur      := 10
         boxarray[ 1 ] = "appe_title(sysparam)"
         boxarray[ 2 ] = "src_getfil(sysparam)"
         fi_disp    := "src_getfil(3)"
         okee_dokee := "do_append()"

      ENDIF

      boxarray[ 3 ] = "for_exp(sysparam)"
      boxarray[ 4 ] = "while_exp(sysparam)"
      boxarray[ 5 ] = "scope_num(sysparam)"
      boxarray[ 6 ] = "tog_sdf(sysparam)"
      boxarray[ 7 ] = "ok_button(sysparam)"
      boxarray[ 8 ] = "tog_delim(sysparam)"
      boxarray[ 9 ] = "can_button(sysparam)"
      boxarray[ 10 ] = "filelist(sysparam)"

      for_row := 5
      height  := 11

      files   := "dbf_list"
      def_ext := "."+TABLEEXT

      fi_done := "not_empty('filename')"

   ENDIF

   for_cond := while_cond := ""

   mode     := cur_el := 1
   rel_row  := 0
   how_many := 0

   multibox( 8, 17, M->height, M->bcur, M->boxarray )

   RETURN


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function copy_title()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION copy_title

   PARAMETERS sysparam

   RETURN box_title( M->sysparam, "Copiar " + ;
      SubStr( M->cur_dbf, RAt( hb_ps(), M->cur_dbf ) + 1 ) + ;
      " para " )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function trg_getfil()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION trg_getfil

   PARAMETERS sysparam

   help_code := M->prime_help

   RETURN getfile( M->sysparam, 3 )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function do_copy()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION do_copy

   PRIVATE done
   PRIVATE add_name
   PRIVATE new_el

   done := .F.

   DO CASE

   CASE Empty( M->filename )
      error_msg( "Destino nao selecionado" )

   CASE M->filename == M->cur_dbf
      error_msg( "Arquivo nao pode ser copiado para se mesmo" )

   CASE ! Empty( M->for_cond ) .AND. Type( M->for_cond ) <> "L"
      error_msg( "PARA condiaao nao a uma expressao lagica" )

   CASE ! Empty( M->while_cond ) .AND. Type( M->while_cond ) <> "L"
      error_msg( "ENQUANTO condiaao nao a uma expressao lagica" )

   OTHERWISE
      IF File( M->filename )
         IF rsvp( "Arquivo Destino " + if( aseek( M->dbf, M->filename ) > 0, ;
               "Esta aberto", "Existe" ) + "...Sobreponha? (S/N)" ) <> "S"
            RETURN .F.
         ENDIF
      ENDIF

      stat_msg( "Copiando" )

      IF aseek( M->dbf, M->filename ) > 0
         SELECT ( aseek( M->dbf, M->filename ) )
         dbCloseArea()
         need_field := need_ntx := need_relat := need_filtr := .T.
      ENDIF

      SELECT ( M->cur_area )

      IF RAt( Lower( M->def_ext ), Lower( M->filename ) ) = Len( M->filename ) - 3
         add_name := ! hb_FileExists( name( M->filename ) + M->def_ext )
      ELSE
         add_name := .F.
      ENDIF

      IF Empty( M->for_cond )
         for_cond := ".T."
      ENDIF

      IF Empty( M->while_cond )
         while_cond := ".T."

         IF M->how_many = 0
            GO TOP

         ENDIF
      ENDIF


      nLASTREC := LastRec()
      zei_fort( nLASTREC,,, 0 )

      DO CASE

      CASE M->mode = 1 .AND. M->how_many = 0
         COPY TO &filename WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond

      CASE M->mode = 1 .AND. M->how_many > 0
         COPY TO &filename NEXT M->how_many WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond

      CASE M->mode = 2 .AND. M->how_many = 0
         COPY TO &filename WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond SDF

      CASE M->mode = 2 .AND. M->how_many > 0
         COPY TO &filename NEXT M->how_many WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond SDF

      CASE M->mode = 3 .AND. M->how_many = 0


         DO CASE
         CASE zREGSEP = Chr( 34 ) .OR. zREGSEP = Chr( 39 )
            COPY TO &filename WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond DELIMITED WITH ( { zDELIMITE, zREGSE } )
         CASE zDELIMITE = ","
            COPY TO &filename WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond DELIMITED
         CASE zDELIMITE = "9"
            COPY TO &filename WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond DELIMITED WITH TAB
         CASE zDELIMITE = "|"
            COPY TO &filename WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond DELIMITED WITH PIPE
         OTHERWISE
            COPY TO &filename WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond DELIMITED WITH &zDELIMITE
         ENDCASE

         // COPY to &filename while &while_cond..and.zei_fort(nLASTREC,,,1) for &for_cond  DELIMITED

      CASE M->mode = 3 .AND. M->how_many > 0

         DO CASE
         CASE zREGSEP = Chr( 34 ) .OR. zREGSEP = Chr( 39 )
            COPY TO &filename NEXT M->how_many WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond DELIMITED WITH ( { zDELIMITE, zREGSE } )
         CASE zDELIMITE = ","
            COPY TO &filename NEXT M->how_many WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond DELIMITED
         CASE zDELIMITE = "9"
            COPY TO &filename NEXT M->how_many WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond DELIMITED WITH TAB
         CASE zDELIMITE = "|"
            COPY TO &filename NEXT M->how_many WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond DELIMITED WITH PIPE
         OTHERWISE
            COPY TO &filename NEXT M->how_many WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond DELIMITED WITH &zDELIMITE
         ENDCASE


         // COPY to &filename next M->how_many while &while_cond..and.zei_fort(nLASTREC,,,1)  for &for_cond DELIMITED

      ENDCASE

      IF aseek( M->dbf, M->filename ) > 0
         SELECT ( aseek( M->dbf, M->filename ) )
         DBUREDE( filename,, ABERTURA )
      ENDIF

      IF File( name( M->filename ) + M->def_ext ) .AND. M->add_name
         new_el := afull( &files ) + 1

         IF M->new_el <= Len( &files )
            &files[ M->new_el ] = M->filename
            array_sort( &files )

         ENDIF
      ENDIF

      stat_msg( "Arquivo Copiado" )
      done := .T.

   ENDCASE

   RETURN M->done


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function appe_title()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION appe_title

   PARAMETERS sysparam

   RETURN box_title( M->sysparam, "Anexar para " + ;
      SubStr( M->cur_dbf, RAt( hb_ps(), M->cur_dbf ) + 1 ) + ;
      " de" )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function src_getfil()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION src_getfil

   PARAMETERS sysparam

   help_code := M->prime_help

   RETURN getfile( M->sysparam, 3 )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function do_append()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION do_append

   PRIVATE done

   done := .F.

   DO CASE

   CASE Empty( M->filename )
      error_msg( "Fonte nao Selecionada" )

   CASE M->filename == M->cur_dbf
      error_msg( "Arquivo nao pode ser anexado a si praprio" )

   CASE ! hb_FileExists( M->filename )
      error_msg( "Nao Pode-se abrir " + M->filename )

   CASE ! Empty( M->for_cond ) .AND. Type( M->for_cond ) <> "L"
      error_msg( "PARA condiaao nao a uma expressao lagica" )

   CASE ! Empty( M->while_cond ) .AND. Type( M->while_cond ) <> "L"
      error_msg( "ENQUANTO condiaao nao a uma expressao lagica" )

   OTHERWISE

      IF aseek( M->dbf, M->filename ) > 0
         SELECT ( aseek( M->dbf, M->filename ) )
         dbCloseAre()
         need_field := need_ntx := need_relat := need_filtr := .T.

      ENDIF

      stat_msg( "Anexando" )
      SELECT ( M->cur_area )

      IF Empty( M->for_cond )
         for_cond := ".T."
      ENDIF

      IF Empty( M->while_cond )
         while_cond := ".T."
      ENDIF


      DO CASE
      CASE M->mode = 1 .AND. M->how_many = 0
         nLASTREC := NetRegCount( filename )
         zei_fort( nLASTREC,,, 0 )
         APPEND FROM &filename WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond

      CASE M->mode = 1 .AND. M->how_many > 0
         nLASTREC := NetRegCount( filename )
         zei_fort( nLASTREC,,, 0 )
         APPEND FROM &filename NEXT M->how_many WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond

      CASE M->mode = 2 .AND. M->how_many = 0
         nLASTREC := FLINECOUNT( filename )
         zei_fort( nLASTREC,,, 0 )
         APPEND FROM &filename WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond SDF

      CASE M->mode = 2 .AND. M->how_many > 0
         nLASTREC := FLINECOUNT( filename )
         zei_fort( nLASTREC,,, 0 )
         APPEND FROM &filename NEXT M->how_many WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond SDF

      CASE M->mode = 3 .AND. M->how_many = 0
         nLASTREC := FLINECOUNT( filename )
         zei_fort( nLASTREC,,, 0 )
         DO CASE
         CASE zREGSEP = Chr( 34 ) .OR. zREGSEP = Chr( 39 )
            APPEND FROM &filename WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond DELIMITED WITH ( { zDELIMITE, zREGSE } )
         CASE zDELIMITE = ","
            APPEND FROM &filename WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond DELIMITED
         CASE zDELIMITE = "9"
            APPEND FROM &filename WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond DELIMITED WITH TAB
         CASE zDELIMITE = "|"
            APPEND FROM &filename WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond DELIMITED WITH PIPE
         OTHERWISE
            APPEND FROM &filename WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond DELIMITED WITH &zDELIMITE
         ENDCASE
      CASE M->mode = 3 .AND. M->how_many > 0
         nLASTREC := FLINECOUNT( filename )
         zei_fort( nLASTREC,,, 0 )
         DO CASE
         CASE zREGSEP = Chr( 34 ) .OR. zREGSEP = Chr( 39 )
            APPEND FROM &filename NEXT M->how_many WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond DELIMITED WITH ( { zDELIMITE, zREGSE } )
         CASE zDELIMITE = ","
            APPEND FROM &filename NEXT M->how_many WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond DELIMITED
         CASE zDELIMITE = "9"
            APPEND FROM &filename NEXT M->how_many WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond DELIMITED WITH TAB
         CASE zDELIMITE = "|"
            APPEND FROM &filename NEXT M->how_many WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond DELIMITED WITH PIPE
         OTHERWISE
            APPEND FROM &filename NEXT M->how_many WHILE &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) FOR &for_cond DELIMITED WITH &zDELIMITE
         ENDCASE



         // append from &filename next M->how_many while  &while_cond. .and. zei_fort(nLASTREC,,,1) for &for_cond DELIMITED

      ENDCASE

      IF aseek( M->dbf, M->filename ) > 0
         SELECT ( aseek( M->dbf, M->filename ) )
         DBUREDE( filename,, ABERTURA )
      ENDIF

      stat_msg( "Anexar completado" )
      done := .T.

   ENDCASE

   RETURN M->done


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function repl_title()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION repl_title

   PARAMETERS sysparam

   RETURN box_title( M->sysparam, "Repor em " + ;
      SubStr( M->cur_dbf, RAt( hb_ps(), M->cur_dbf ) + 1 ) + ;
      "..." )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function repl_field()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION repl_field

   PARAMETERS sysparam

   help_code := M->prime_help

   RETURN genfield( M->sysparam, .T. )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function with_exp()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION with_exp

   PARAMETERS sysparam
   PRIVATE rval

   help_code := M->prime_help
   rval      := get_exp( M->sysparam, "COM    ", 4, "with_what" )

   IF M->sysparam = 4 .AND. LastKey() = 13 .AND. ! Empty( M->with_what )
      get_exp( 3, "COM    ", 4, "with_what" )
      to_ok()

   ENDIF

   RETURN M->rval


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function do_replace()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION do_replace

   PRIVATE done

   M->done := .F.
   DO CASE
   CASE Empty( M->field_mvar )
      error_msg( "Campo nao selecionado" )
   CASE Empty( M->with_what )
      error_msg( "Reposicao expressao nao selecionada" )
   CASE Type( M->with_what ) <> Type( M->field_mvar ) .AND. ;
         !( Type( M->field_mvar ) == "M" ) .AND. ;
         !( Type( M->with_what ) == "UI" )
      error_msg( "Expressao de reposicao e campos sao de tipos diferentes" )
   CASE ! Empty( M->for_cond ) .AND. Type( M->for_cond ) <> "L"
      error_msg( "PARA condicao nao a uma expressao logica" )
   CASE ! Empty( M->while_cond ) .AND. Type( M->while_cond ) <> "L"
      error_msg( "ENQUANTO condicao nao a uma expressao lagica" )
   OTHERWISE
      stat_msg( "Repondo Arquivo" )
      dbSetOrder( 0 )
      IF Empty( M->for_cond )
         for_cond := ".T."
      ENDIF
      IF Empty( M->while_cond )
         while_cond := ".T."
         IF M->how_many = 0
            dbGoTop()
         ENDIF
      ENDIF
      nLASTREC := LastRec()
      zei_fort( nLASTREC,,, 0 )
      IF M->how_many = 0
         WHILE &while_cond. .AND. !Eof()
            IF &for_cond
               netreclock()
               field->&field_mvar := &with_what
               dbUnlock()
            ENDIF
            zei_fort( nLASTREC,,, 1 )
            dbSkip()
         ENDDO
      ELSE
         dbEval( {|| netgrvcam( "field_mvar", &with_what ) }, {|| &for_cond }, {|| &while_cond. .AND. zei_fort( nLASTREC,,, 1 ) }, M->how_many,, .F. )
      ENDIF
      stat_msg( "Reposicao completa" )
      dbSetOrder( 1 )
      done := .T.
   ENDCASE

   RETURN M->done


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function for_exp()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION for_exp

   PARAMETERS sysparam

   help_code := 16

   RETURN get_exp( M->sysparam, "PARA   ", M->for_row, "for_cond" )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function while_exp()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION while_exp

   PARAMETERS sysparam

   help_code := 16

   RETURN get_exp( M->sysparam, "ENQUANTO", M->for_row + 1, "while_cond" )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function scope_num()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION scope_num

   PARAMETERS sysparam
   LOCAL saveColor
   PRIVATE old_scope

   help_code := 17
   saveColor := SetColor( M->colorNorm )

   DO CASE

   CASE M->sysparam = 1 .OR. M->sysparam = 3
      @ M->wt + M->for_row + 2, M->wl + 2 ;
         SAY "LIMITE " + Pad( if( M->how_many = 0, "TUDO", ;
         "OUTRO" + LTrim( Str( M->how_many ) ) ), 20 )

      IF M->sysparam = 1
         @ M->wt + M->for_row + 2, M->wl + 9 SAY ""

      ENDIF

   CASE M->sysparam = 2
      SetColor( M->colorHilite )
      @ M->wt + M->for_row + 2, M->wl + 9 ;
         SAY Pad( if( M->how_many = 0, ;
         "TUDO", "OUTRO" + LTrim( Str( M->how_many ) ) ), 20 )

   CASE M->sysparam = 4

      IF Chr( M->keystroke ) $ "0123456789" + Chr( 13 )

         IF M->keystroke <> 13
            KEYBOARD Chr( M->keystroke )

         ENDIF

         old_scope := M->how_many

         SET KEY 5 TO clear_gets
         SET KEY 24 TO clear_gets
         xkey_clear()

         SetColor( M->colorHilite )
         @ M->wt + M->for_row + 2, M->wl + 9 SAY Pad( "OUTRO", 20 )

         SetColor( M->colorNorm )
         @ M->wt + M->for_row + 2, M->wl + 14 ;
            GET M->how_many PICTURE "99999999"
         READDBU()

         keystroke := LastKey()

         SET KEY 5 to
         SET KEY 24 to
         xkey_norm()

         IF M->keystroke = 13
            to_ok()
            @ M->wt + M->for_row + 2, M->wl + 9 ;
               SAY Pad( if( M->how_many = 0, "TUDO", "OUTRO " + ;
               LTrim( Str( M->how_many ) ) ), 20 )

         ELSE

            IF menu_key() <> 0
               how_many := M->old_scope

            ENDIF

            IF M->keystroke <> 27 .AND. ! isdata( M->keystroke )
               KEYBOARD Chr( M->keystroke )

            ENDIF
         ENDIF

      ELSE
         how_many := 0

      ENDIF
   ENDCASE

   SetColor( saveColor )

   RETURN 2


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function tog_sdf()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION tog_sdf

   PARAMETERS sysparam
   LOCAL saveColor

   help_code := 11
   saveColor := SetColor( M->colorNorm )

   DO CASE

   CASE M->sysparam = 1 .OR. M->sysparam = 3
      @ M->wt + 9, M->wl + 8 SAY " SDF "

      IF M->mode = 2
         hb_DispBox( M->wt + 8, M->wl + 7, M->wt + 10, M->wl + 13, sframe )
         // @ M->wt + 8, M->wl + 7, M->wt + 10, M->wl + 13 box sframe

      ENDIF

      IF M->sysparam = 1
         @ M->wt + 9, M->wl + 9 SAY ""

      ENDIF

   CASE M->sysparam = 2
      SetColor( M->colorHilite )
      @ M->wt + 9, M->wl + 8 SAY " SDF "

   CASE M->sysparam = 4 .AND. M->keystroke = 13

      IF M->mode = 2
         hb_Scroll( M->wt + 8, M->wl + 7, M->wt + 10, M->wl + 13 )
         // @ M->wt + 8, M->wl + 7, M->wt + 10, M->wl + 13 box "        "
         mode := 1

         cur_el  := 1
         rel_row := 0
         files   := "dbf_list"
         def_ext := "."+TABLEEXT
         filelist( 1 )

      ELSE

         IF M->mode = 3
            hb_Scroll( M->wt + 8, M->wl + 16, M->wt + 10, M->wl + 28 )

         ELSE
            cur_el  := 1
            rel_row := 0
            files   := "txt_list"
            def_ext := ".txt"
            filelist( 1 )

         ENDIF
         hb_DispBox( M->wt + 8, M->wl + 7, M->wt + 10, M->wl + 13, sframe )
         // @ M->wt + 8, M->wl + 7, M->wt + 10, M->wl + 13 box sframe
         mode := 2

      ENDIF
   ENDCASE

   SetColor( saveColor )

   RETURN 2


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function tog_delim()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION tog_delim

   PARAMETERS sysparam
   LOCAL saveColor

   help_code := 11
   saveColor := SetColor( M->colorNorm )
   DO CASE

   CASE M->sysparam = 1 .OR. M->sysparam = 3
      @ M->wt + 9, M->wl + 17 SAY " DELIMITADO "

      IF M->mode = 3
         hb_DispBox( M->wt + 8, M->wl + 16, M->wt + 10, M->wl + 28, sframe )
         // @ M->wt + 8, M->wl + 16, M->wt + 10, M->wl + 28 box sframe

      ENDIF

      IF M->sysparam = 1
         @ M->wt + 9, M->wl + 17 SAY ""

      ENDIF

   CASE M->sysparam = 2
      SetColor( M->colorHilite )
      @ M->wt + 9, M->wl + 17 SAY " DELIMITADO "

   CASE M->sysparam = 4 .AND. M->keystroke = 13

      IF M->mode = 3
         hb_Scroll( M->wt + 8, M->wl + 16, M->wt + 10, M->wl + 28 )
         mode := 1

         cur_el  := 1
         rel_row := 0
         files   := "dbf_list"
         def_ext := "."+TABLEEXT
         filelist( 1 )

      ELSE

         IF M->mode = 2
            hb_Scroll( M->wt + 8, M->wl + 7, M->wt + 10, M->wl + 13 )

         ELSE
            cur_el  := 1
            rel_row := 0
            files   := "txt_list"
            def_ext := ".txt"
            filelist( 1 )

         ENDIF
         hb_DispBox( M->wt + 8, M->wl + 16, M->wt + 10, M->wl + 28, sframe )
         // @ M->wt + 8, M->wl + 16, M->wt + 10, M->wl + 28 box sframe
         mode := 3

      ENDIF
   ENDCASE

   SetColor( saveColor )

   RETURN 2


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function copybkdbf()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION copybkdbf( cFILE )

   LOCAL aARQ
   LOCAL XY
   LOCAL cORI
   LOCAL cBAK

   aARQ := Directory( tiraext( cFILE ) + ".*" )  // pega todas dados.dbf dados.cdx dados.fpt .... --> dados.*
   FOR XY := 1 TO Len( aARQ )
      cORI := Lower( aARQ[ XY, 1 ] )
      cBAK := "copia_" + cORI
      IF File( cBAK )
         stat_msg( "Apagando Backup Anterior " + cBAK )
         DELETEFILE( cBAK )
      ENDIF
      stat_msg( "Criando Backup " + cORI )
      IF File( cORI )
         filecopy( cORI, cBAK )
      ENDIF
   NEXT XY

   RETURN



// + EOF: dbucopy.prg
// +
