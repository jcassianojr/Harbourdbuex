// +--------------------------------------------------------------------
// +
// +
// +
// +    Programa  : dbuutil.prg
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



#include "INKEY.CH"
#include "BOX.CH"



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function setup()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION setup

   PRIVATE k
   PRIVATE t
   PRIVATE n
   PRIVATE i
   PRIVATE j
   PRIVATE field_n
   PRIVATE s_alias
   PRIVATE k_filter
   PRIVATE ntx
   PRIVATE file_name
   PRIVATE k_1
   PRIVATE k_2
   PRIVATE k_3
   PRIVATE k_4
   PRIVATE k_5
   PRIVATE k_6
   PRIVATE k_7

   stat_msg( "Preparando para ver" )

   IF M->need_field
      need_field := .F.

      k := afull( M->field_list )

      n := 1
      i := 1

      DO WHILE M->n <= 6 .AND. M->i <= Len( M->field_list )

         IF Empty( dbf[ M->n ] )
            EXIT

         ENDIF

         field_n := "field_n" + SubStr( "123456", M->n, 1 )

         IF ! Empty( &field_n[ 1 ] )
            s_alias := if( M->n > 1, name( dbf[ M->n ] ) + "->", "" )
            AFill( M->field_list, M->s_alias, M->i, afull( &field_n ) )

            j := 1

            DO WHILE M->j <= Len( &field_n ) .AND. M->i <= Len( M->field_list )

               IF Empty( &field_n[ M->j ] )
                  EXIT

               ENDIF

               field_list[ M->i ] = field_list[ M->i ] + &field_n[ M->j ]

               i := M->i + 1
               j := M->j + 1

            ENDDO
         ENDIF

         n := M->n + 1

      ENDDO

      IF M->i <= M->k
         AFill( M->field_list, "", M->i )

      ENDIF
   ENDIF

   IF M->need_ntx
      need_ntx := .F.

      n := 1

      DO WHILE M->n <= 6

         IF Empty( dbf[ M->n ] )
            EXIT

         ENDIF

         ntx := "ntx" + SubStr( "123456", M->n, 1 )

         IF ! Empty( &ntx[ 1 ] )
            k_1 := k_2 := k_3 := k_4 := k_5 := k_6 := k_7 := ""

            SELECT ( M->n )

            i := 1

            DO WHILE M->i <= 7 .AND. Empty( M->view_err )

               IF Empty( &ntx[ M->i ] )
                  EXIT

               ENDIF

               file_name := &ntx[ M->i ]

               IF File( M->file_name )
                  k  := "k_" + SubStr( "1234567", M->i, 1 )
                  &k := M->file_name
                  i  := M->i + 1

               ELSE
                  view_err := "N„o Pode-se abrir arquivo de indice " + M->file_name

               ENDIF
            ENDDO

            IF Empty( M->view_err )
               SET INDEX TO &k_1, &k_2, &k_3, &k_4, &k_5, &k_6, &k_7

            ELSE
               need_ntx := .T.
               RETURN 0

            ENDIF
         ENDIF

         n := M->n + 1

      ENDDO
   ENDIF

   IF M->need_relat
      need_relat := .F.

      FOR j := 1 TO 5
         SELECT ( M->j )
         SET RELATION TO

      NEXT

      j := 1

      DO WHILE M->j <= Len( M->k_relate )

         IF Empty( k_relate[ M->j ] )
            EXIT

         ENDIF

         n := Asc( s_relate[ M->j ] ) - Asc( "A" ) + 1
         SELECT ( M->n )

         k := k_relate[ M->j ]
         t := SubStr( t_relate[ M->j ], 2 )

         SET RELATION ADDITIVE TO &k INTO &t

         j := M->j + 1

      ENDDO

      SELECT 1
      GO TOP

   ENDIF

   IF M->need_filtr
      need_filtr := .F.

      n := 1

      DO WHILE M->n <= 6

         IF Empty( dbf[ M->n ] )
            EXIT

         ENDIF

         k_filter := "kf" + SubStr( "123456", M->n, 1 )

         IF ! Empty( &k_filter )
            SELECT ( M->n )

            DO CASE

            CASE M->n = 1
               SET FILTER TO &kf1

            CASE M->n = 2
               SET FILTER TO &kf2

            CASE M->n = 3
               SET FILTER TO &kf3

            CASE M->n = 4
               SET FILTER TO &kf4

            CASE M->n = 5
               SET FILTER TO &kf5

            CASE M->n = 6
               SET FILTER TO &kf6

            ENDCASE

            GO TOP

         ENDIF

         n := M->n + 1

      ENDDO
   ENDIF

   stat_msg( "" )

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function multibox()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION multibox

   PARAMETERS wt, wl, wh, beg_c, boxarray
   LOCAL saveColor
   PRIVATE sysparam
   PRIVATE STATE
   PRIVATE CURSOR
   PRIVATE funcn
   PRIVATE winbuff
   PRIVATE save_help
   PRIVATE prime_help
   PRIVATE x
   PRIVATE colorNorm
   PRIVATE colorHilite

   colorNorm   := color8
   colorHilite := color10

   box_open := .T.

   save_help  := M->help_code
   prime_help := M->help_code

   DECLARE box_row[ Len( M->boxarray ) ]
   DECLARE box_col[ Len( M->boxarray ) ]

   winbuff := SaveScreen( M->wt, M->wl, M->wt + M->wh + 1, M->wl + 45 )

   saveColor := SetColor( M->colorNorm )
   Scroll( M->wt, M->wl, M->wt + M->wh + 1, M->wl + 45, 0 )
   hb_DispBox( M->wt, M->wl, M->wt + M->wh + 1, 79, frame )

// @ M->wt, M->wl, M->wt + M->wh + 1, M->wl + 45 box frame

   sysparam := 1

   FOR CURSOR := 1 TO Len( M->boxarray )
      funcn := boxarray[ M->cursor ]
      x     := &funcn
      box_row[ M->cursor ] = Row()
      box_col[ M->cursor ] = Col()

   NEXT

   CURSOR := M->beg_c
   STATE  := 2

   DO WHILE M->STATE <> 0 .AND. M->STATE <> 4
      funcn := boxarray[ M->cursor ]

      DO CASE

      CASE M->STATE = 2

         IF ! key_ready()
            sysparam := 2
            x        := &funcn

            read_key()

         ENDIF

         DO CASE

         CASE M->keystroke = 13 .OR. isdata( M->keystroke )
            STATE := 3

         CASE q_check()
            STATE := 0

         OTHERWISE
            sysparam := 3
            x        := &funcn

            CURSOR := matrix( M->cursor, M->keystroke )

         ENDCASE

      CASE M->STATE = 3
         sysparam := 4

         STATE := &funcn

      ENDCASE
   ENDDO

   RestScreen( M->wt, M->wl, M->wt + M->wh + 1, M->wl + 45, M->winbuff )
   SetColor( saveColor )

   keystroke := 0
   box_open  := .F.
   help_code := M->save_help

   RETURN M->state


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function matrix()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION matrix

   PARAMETERS old_curs, k
   PRIVATE old_row
   PRIVATE old_col
   PRIVATE test_curs
   PRIVATE new_curs

   old_row := Row()
   old_col := box_col[ M->old_curs ]

   new_curs := M->old_curs

   test_curs := M->old_curs

   DO CASE

   CASE M->k = 19 .OR. M->k = 219

      DO WHILE M->test_curs > 2
         test_curs := M->test_curs - 1

         IF box_col[ M->test_curs ] < M->old_col .AND. ;
               box_row[ M->test_curs ] >= M->old_row

            IF box_row[ M->test_curs ] < box_row[ M->new_curs ] ;
                  .OR. M->new_curs = M->old_curs
               new_curs := M->test_curs

            ENDIF
         ENDIF
      ENDDO

   CASE M->k = 4

      DO WHILE M->test_curs < Len( M->box_col )
         test_curs := M->test_curs + 1

         IF box_col[ M->test_curs ] > M->old_col .AND. ;
               box_row[ M->test_curs ] <= M->old_row

            IF box_row[ M->test_curs ] > box_row[ M->new_curs ] ;
                  .OR. M->new_curs = M->old_curs
               new_curs := M->test_curs

            ENDIF
         ENDIF
      ENDDO

   CASE M->k = 5

      DO WHILE M->test_curs > 2
         test_curs := M->test_curs - 1

         IF box_row[ M->test_curs ] < M->old_row .AND. ;
               box_col[ M->test_curs ] <= M->old_col

            IF box_col[ M->test_curs ] > box_col[ M->new_curs ] ;
                  .OR. M->new_curs = M->old_curs
               new_curs := M->test_curs

            ENDIF
         ENDIF
      ENDDO

   CASE M->k = 24

      DO WHILE M->test_curs < Len( M->box_row )
         test_curs := M->test_curs + 1

         IF box_row[ M->test_curs ] > M->old_row .AND. ;
               box_col[ M->test_curs ] >= M->old_col

            IF box_col[ M->test_curs ] < box_col[ M->new_curs ] ;
                  .OR. M->new_curs = M->old_curs
               new_curs := M->test_curs

            ENDIF
         ENDIF
      ENDDO
   ENDCASE

   RETURN M->new_curs


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function to_ok()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION to_ok

   CURSOR := AScan( M->boxarray, "ok_button(sysparam)" ) - 1

   KEYBOARD Chr( 24 )

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function to_can()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION to_can

   CURSOR := AScan( M->boxarray, "can_button(sysparam)" )

   KEYBOARD Chr( 24 )

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function ok_button()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION ok_button

   PARAMETERS sysparam
   LOCAL saveColor
   PRIVATE ok
   PRIVATE reply

   help_code := M->prime_help

   ok        := " Ok "
   reply     := 2
   saveColor := SetColor( M->colorNorm )

   DO CASE

   CASE M->sysparam = 1 .OR. M->sysparam = 3
      @ M->wt + M->wh, M->wl + 8 SAY M->ok

      IF M->sysparam = 1
         @ M->wt + M->wh, M->wl + 9 SAY ""

      ENDIF

   CASE M->sysparam = 2
      SetColor( M->colorHilite )
      @ M->wt + M->wh, M->wl + 8 SAY M->ok

   CASE M->sysparam = 4 .AND. M->keystroke = 13

      IF &okee_dokee
         reply := 4

      ENDIF
   ENDCASE

   SetColor( saveColor )

   RETURN M->reply


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function can_button()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION can_button

   PARAMETERS sysparam
   LOCAL saveColor
   PRIVATE can
   PRIVATE reply

   help_code := M->prime_help

   can       := " Cancele "
   reply     := 2
   saveColor := SetColor( M->colorNorm )

   DO CASE

   CASE M->sysparam = 1 .OR. M->sysparam = 3
      @ M->wt + M->wh, M->wl + 17 SAY M->can

      IF M->sysparam = 1
         @ M->wt + M->wh, M->wl + 17 SAY ""

      ENDIF

   CASE M->sysparam = 2
      saveColor := SetColor( M->colorHilite )
      @ M->wt + M->wh, M->wl + 17 SAY M->can

   CASE M->sysparam = 4 .AND. M->keystroke = 13
      reply := 0

   ENDCASE

   SetColor( saveColor )

   RETURN M->reply


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function filelist()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION filelist

   PARAMETERS sysparam

   RETURN itemlist( M->sysparam, 32, "filename", M->files, "*" + M->def_ext, .T. )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function fieldlist()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION fieldlist

   PARAMETERS sysparam

   RETURN itemlist( M->sysparam, 34, "field_mvar", "field_m", "Fields", .F. )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function itemlist()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION itemlist

   PARAMETERS sysparam, l_rel, mvar, items, i_title, go_ok
   LOCAL saveColor
   PRIVATE n
   PRIVATE x
   PRIVATE i_full

   help_code := M->prime_help
   saveColor := SetColor( colorNorm )

   i_full := afull( &items )

   DO CASE

   CASE M->sysparam = 1
      Scroll( M->wt + 1, M->wl + M->l_rel - 1, M->wt + M->wh, M->wl + 44, 0 )
      hb_DispBox( M->wt, M->wl + M->l_rel - 2, M->wt + M->wh + 1, M->wl + 45, M->lframe )
      // @ M->wt, M->wl + M->l_rel - 2, M->wt + M->wh + 1, M->wl + 45 ;
      // box M->lframe

      i_title := Replicate( "-", ( ( 46 - M->l_rel - Len( M->i_title ) ) / 2 ) - 1 ) ;
         +" " + M->i_title + " "
      i_title := M->i_title + Replicate( "-", ( 46 - M->l_rel - Len( M->i_title ) ) )

      @ M->wt + 1, M->wl + M->l_rel - 1 SAY M->i_title

      IF ! Empty( &items[ 1 ] )
         AChoice( M->wt + 2, M->wl + M->l_rel, M->wt + M->wh, M->wl + 43, ;
            &items, .F., "i_func", M->cur_el, M->rel_row )

      ENDIF

      @ M->wt + 2, M->wl + M->l_rel SAY ""

   CASE M->sysparam = 2

      IF Empty( &items[ 1 ] )
         KEYBOARD ( Chr( 219 ) )

      ELSE
         cur_el  := M->cur_el - M->rel_row + Row() - M->wt - 2
         rel_row := Row() - M->wt - 2

         n := AChoice( M->wt + 2, M->wl + M->l_rel, M->wt + M->wh, ;
            M->wl + 43, &items, .T., "i_func", M->cur_el, ;
            M->rel_row )

         sysmenu()

         DO CASE

         CASE M->keystroke = 13
            &mvar := &items[ M->n ]

            x := &fi_disp

            IF M->go_ok
               to_ok()

            ELSE
               KEYBOARD Chr( 219 ) + Chr( 24 )

            ENDIF

         CASE M->keystroke = 19
            KEYBOARD Chr( 219 )

         CASE M->keystroke = 0

            KEYBOARD Chr( 11 )

         OTHERWISE
            KEYBOARD Chr( M->keystroke )

         ENDCASE
      ENDIF
   ENDCASE

   SetColor( saveColor )

   RETURN 2


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function i_func()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION i_func

   PARAMETERS amod, sel, rel
   PRIVATE r
   PRIVATE srow
   PRIVATE scol

   srow := Row()
   scol := Col()

   IF M->error_on
      error_off()

   ENDIF

   IF M->amod = 4
      r := 0

   ELSE
      cur_el  := M->sel
      rel_row := M->rel

      r := 2

      keystroke := LastKey()

   ENDIF

   IF M->cur_el > M->rel_row + 1
      @ M->wt + 2, M->wl + 44 SAY M->more_up

   ELSE
      @ M->wt + 2, M->wl + 44 SAY " "

   ENDIF

   IF M->i_full - M->cur_el > M->wh - 2 - M->rel_row
      @ M->wt + M->wh, M->wl + 44 SAY M->more_down

   ELSE
      @ M->wt + M->wh, M->wl + 44 SAY " "

   ENDIF

   IF M->amod = 3

      DO CASE

      CASE M->keystroke = 27
         r := 0

      CASE M->keystroke = 13 .OR. M->keystroke = 19 .OR. M->keystroke = 219
         r := 1

      CASE M->keystroke = 1
         KEYBOARD Chr( 31 )

      CASE M->keystroke = 6
         KEYBOARD Chr( 30 )

      CASE isdata( M->keystroke )
         r := 3

      CASE menu_key() <> 0
         r := 0

      ENDCASE
   ENDIF

   @ M->srow, M->scol SAY ""

   RETURN M->r


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function getfile()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION getfile

   PARAMETERS sysparam, row_off
   LOCAL saveColor
   PRIVATE irow
   PRIVATE name_temp

   help_code := M->prime_help

   irow      := M->wt + M->row_off
   saveColor := SetColor( M->colorNorm )

   DO CASE

   CASE M->sysparam = 1 .OR. M->sysparam = 3
      @ M->irow, M->wl + 2 SAY "Arquivo " + Pad( M->filename, 20 )

      IF M->sysparam = 1
         @ M->irow, M->wl + 9 SAY ""

      ENDIF

   CASE M->sysparam = 2
      SetColor( M->colorHilite )
      @ M->irow, M->wl + 9 SAY Pad( M->filename, 20 )

   CASE M->sysparam = 4

      IF M->keystroke <> 13

         KEYBOARD Chr( M->keystroke )

      ENDIF

      SET KEY 24 TO clear_gets

      name_temp := enter_rc( M->filename, M->irow, M->wl + 9, 64, "@KS20", M->color9 )

      SET KEY 24 to

      IF ! Empty( M->name_temp )

         IF !( RAt( ".", M->name_temp ) > RAt( hb_ps(), M->name_temp ) )
            name_temp := M->name_temp + M->def_ext

         ENDIF

         filename := M->name_temp

      ELSE

         IF M->keystroke = 13 .OR. M->keystroke = 24
            M->filename := ""

         ENDIF
      ENDIF

      IF M->keystroke = 13

         IF &fi_done
            @ M->irow, M->wl + 9 SAY Pad( M->filename, 20 )

         ENDIF

      ELSE

         IF M->keystroke <> 27 .AND. ! isdata( M->keystroke )
            KEYBOARD Chr( M->keystroke )

         ENDIF
      ENDIF
   ENDCASE

   SetColor( saveColor )

   RETURN 2


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function g_getfile()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION g_getfile

   PARAMETERS sysparam

   RETURN getfile( M->sysparam, 4 )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function genfield()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION genfield

   PARAMETERS sysparam, is_replace

   DO CASE

   CASE M->sysparam = 1 .OR. M->sysparam = 3
      @ M->wt + 3, M->wl + 2 SAY "Arquivo" + Pad( M->field_mvar, 20 )

      IF M->sysparam = 1
         @ M->wt + 3, M->wl + 9 SAY ""

      ENDIF

   CASE M->sysparam = 2 .OR. M->sysparam = 4

      IF M->lkey = 5
         KEYBOARD Chr( 4 )

      ELSE

         IF M->is_replace
            KEYBOARD Chr( 24 )

         ELSE

            IF Empty( M->field_mvar )
               to_can()

            ELSE
               to_ok()

            ENDIF
         ENDIF
      ENDIF
   ENDCASE

   RETURN 2


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function get_exp()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION get_exp

   PARAMETERS sysparam, xlable, row_off, mvar
   LOCAL saveColor
   PRIVATE erow
   PRIVATE k_input

   erow      := M->wt + M->row_off
   saveColor := SetColor( M->colorNorm )

   DO CASE

   CASE M->sysparam = 1 .OR. M->sysparam = 3
      @ M->erow, M->wl + 2 SAY M->xlable + Pad( &mvar, 20 )

      IF M->sysparam = 1
         @ M->erow, M->wl + 9 SAY ""

      ENDIF

   CASE M->sysparam = 2
      SetColor( M->colorHilite )
      @ M->erow, M->wl + 9 SAY Pad( &mvar, 20 )

   CASE M->sysparam = 4

      IF M->keystroke <> 13
         KEYBOARD Chr( M->keystroke )

      ENDIF

      SET KEY 5 TO clear_gets
      SET KEY 24 TO clear_gets

      k_input := enter_rc( &mvar, M->erow, M->wl + 9, 127, "@KS20", M->color9 )

      SET KEY 5 to
      SET KEY 24 to

      IF ! Empty( M->k_input )
         &mvar := M->k_input

         IF M->keystroke <> 5 .AND. ! isdata( M->keystroke )
            keystroke := 24

         ENDIF

      ELSE

         IF M->keystroke = 13 .OR. M->keystroke = 5 .OR. M->keystroke = 24
            &mvar := ""

         ENDIF
      ENDIF

      IF M->keystroke <> 13 .AND. M->keystroke <> 27 .AND. ;
            ! isdata( M->keystroke )
         KEYBOARD Chr( M->keystroke )

      ENDIF
   ENDCASE

   SetColor( saveColor )

   RETURN 2


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function not_empty()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION not_empty

   PARAMETERS mvar
   PRIVATE done_ok

   done_ok := ! Empty( &mvar )

   IF M->done_ok
      to_ok()

   ENDIF

   RETURN M->done_ok


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function filebox()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION filebox

   PARAMETERS def_ext, files, titl_func, do_func, creat_flag, box_top
   PRIVATE rel_row
   PRIVATE cur_el
   PRIVATE fi_disp
   PRIVATE okee_dokee
   PRIVATE fi_done
   PRIVATE bcur

   DECLARE boxarray[ 5 ]

   boxarray[ 1 ] = M->titl_func + "(sysparam)"
   boxarray[ 2 ] = "g_getfile(sysparam)"
   boxarray[ 3 ] = "ok_button(sysparam)"
   boxarray[ 4 ] = "can_button(sysparam)"
   boxarray[ 5 ] = "filelist(sysparam)"

   cur_el     := 1
   rel_row    := 0
   fi_disp    := "g_getfile(3)"
   fi_done    := "not_empty('filename')"
   okee_dokee := M->do_func + "()"

   IF M->creat_flag

      IF Empty( filename )
         bcur := 2

      ELSE
         bcur := 3

      ENDIF

   ELSE
      bcur := 5

   ENDIF

   RETURN multibox( M->box_top, 17, 7, M->bcur, M->boxarray )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function box_title()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION box_title

   PARAMETERS sysparam, boxtitle

   IF M->sysparam = 1
      @ M->wt + 1, M->wl + 2 SAY M->boxtitle
      @ M->wt + 1, M->wl + 2 SAY ""

   ENDIF

   RETURN 2


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function get_k_trim()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION get_k_trim

   PARAMETERS sysparam, k_label
   LOCAL saveColor
   PRIVATE k_input

   saveColor := SetColor( M->colorNorm )

   DO CASE

   CASE M->sysparam = 1 .OR. M->sysparam = 3
      @ M->wt + 3, M->wl + 2 SAY Pad( M->k_label, 12 ) + Pad( M->k_trim, 30 )

      IF M->sysparam = 1
         @ M->wt + 3, M->wl + 9 SAY ""

      ENDIF

   CASE M->sysparam = 2
      SetColor( M->colorHilite )
      @ M->wt + 3, M->wl + 14 SAY Pad( M->k_trim, 30 )

   CASE M->sysparam = 4

      IF M->keystroke <> 13
         KEYBOARD Chr( M->keystroke )

      ENDIF

      SET KEY 24 TO clear_gets

      k_input := enter_rc( M->k_trim, M->wt + 3, M->wl + 14, 127, "@KS30", ;
         M->color9 )

      SET KEY 24 to

      IF ! Empty( M->k_input )
         k_trim := M->k_input

         keystroke := 24

      ELSE

         IF M->keystroke = 13 .OR. M->keystroke = 24
            k_trim := ""

            keystroke := 24

         ENDIF
      ENDIF

      IF M->keystroke <> 13 .AND. M->keystroke <> 27 .AND. ;
            ! isdata( M->keystroke )
         KEYBOARD Chr( M->keystroke )

      ENDIF
   ENDCASE

   SetColor( saveColor )

   RETURN 2


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function sysmenu()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION sysmenu

   LOCAL saveColor
   PRIVATE menu_func
   PRIVATE menu_sel
   PRIVATE menu_buf
   PRIVATE a
   PRIVATE ml
   PRIVATE mr
   PRIVATE mb
   PRIVATE prev_func
   PRIVATE sav_row
   PRIVATE sav_col
   PRIVATE x

   IF M->keystroke = 0
      RETURN .F.
   ENDIF
   menu_func  := menu_key()
   local_func := 0
   IF M->menu_func = 0
      RETURN .T.
   ENDIF
   sav_row := Row()
   sav_col := Col()
   IF M->error_on
      error_off()
   ENDIF
   menu_sel  := 0
   prev_func := 0
   x         := M->menu_func
   saveColor := SetColor()
   WHILE M->menu_func > 0 .AND. M->menu_sel = 0
      IF M->menu_func <> M->prev_func  // Trocou Menu
         lite_fkey( M->menu_func )
         prev_func := M->menu_func
         a         := func_title[ M->menu_func ]
         M->ml     := ( 9 * M->menu_func ) - 17
         M->mr     := ( ( 9 * M->menu_func ) - 6 )
         M->mb     := ( 2 + Len( &a._m ) )   // Pega a array das Funcoes
         menu_buf  := SaveScreen( 2, M->ml - 1, M->mb + 1, M->mr + 1 )
         SetColor( M->color6 )
         hb_DispBox( 2, M->ml - 1, M->mb + 1, M->mr + 1, mframe )
         // @  2, M->ml - 1, M->mb + 1, M->mr + 1 box mframe
      ENDIF
      SetColor( M->color5 )
      menu_sel := AChoice( 3, M->ml, M->mb, M->mr, &a._m, &a._b, "mu_func", ;
         menu_deflt[ M->menu_func ], menu_deflt[ M->menu_func ] - 1 )


      DO CASE

      CASE M->keystroke = 27
         menu_func := 0

      CASE M->keystroke = 4
         menu_func := if( M->menu_func < 9, M->menu_func + 1, 2 )

      CASE M->keystroke = 19
         menu_func := if( M->menu_func > 2, M->menu_func - 1, 9 )

      CASE M->x <> 0
         menu_func := M->x

      ENDCASE

      IF M->menu_func <> M->prev_func .OR. M->menu_sel <> 0
         dim_fkey( M->prev_func )
         RestScreen( 2, M->ml - 1, M->mb + 1, M->mr + 1, M->menu_buf )

      ENDIF
   ENDDO

   IF M->menu_func <> 0
      menu_deflt[ M->menu_func ] = M->menu_sel

   ENDIF


// Menus que Saem do loop (sem necessidade de checar dbf_aberto) f2=2 f3=3 ...
// exit_str definida no dbu.prg
   IF LTrim( Str( M->menu_func ) ) $ M->exit_str .OR. ( M->menu_func = 2 .AND. M->menu_sel > 3 )   // menus que saem do loop exit_str ou //abir outros databases
      sysfunc  := M->menu_func
      func_sel := M->menu_sel
   ELSE
      local_func := M->menu_func
      local_sel  := M->menu_sel
   ENDIF

   @ M->sav_row, M->sav_col SAY ""

   keystroke := 0
   SetColor( saveColor )

   RETURN menu_func <> 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function menu_key()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION menu_key

   PRIVATE num

   num := 0
   DO CASE
   CASE M->keystroke = 28
      HELP()
   CASE M->keystroke = K_ALT_H
      XCAPTXT()
   CASE M->keystroke = K_ALT_J
      XEDIWOR()
   CASE M->keystroke = K_ALT_F
      XGRATXT()
   CASE M->keystroke < 0 .AND. M->keystroke > -9
      num := 1 - M->keystroke
   CASE M->keystroke >= 249 .AND. M->keystroke < 256
      num := 257 - M->keystroke
   ENDCASE
   RETU M->num


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function mu_func()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +

FUNCTION mu_func

   PARAMETERS amod, sel, rel
   PRIVATE r

   IF M->amod = 4
      keystroke := Inkey( 0 )

      r := 0

   ELSE
      keystroke := LastKey()

      r := 2

   ENDIF

   x := menu_key()

   IF M->amod = 3

      DO CASE

      CASE M->keystroke = 13 .OR. M->x = M->menu_func
         r := 1

      CASE M->keystroke = 27 .OR. M->keystroke = 19 .OR. ;
            M->keystroke = 4 .OR. M->x <> 0
         r := 0

      CASE M->keystroke = 1
         KEYBOARD Chr( 31 )

      CASE M->keystroke = 6
         KEYBOARD Chr( 30 )

      CASE isdata( M->keystroke )
         r := 3

      ENDCASE
   ENDIF

   RETURN M->r


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function xkey_clear()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION xkey_clear

   PRIVATE i

   FOR i := 1 TO 7
      SET KEY - ( M->i ) TO clear_gets

   NEXT

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function xkey_norm()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION xkey_norm

   PRIVATE i

   FOR i := 1 TO 7
      SET KEY - ( M->i ) to

   NEXT

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function lite_fkey()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNC lite_fkey( k_num )

   LOCAL saveColor
   MEMVAR color6

   saveColor := SetColor( M->color11 )
   @  1, ( 9 * k_num ) - 18 SAY PadC( func_title[ k_num ], 9 )
   SetColor( saveColor )

   RETURN ( 0 )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function dim_fkey()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNC dim_fkey( k_num )

   LOCAL saveColor
   MEMVAR color1

   saveColor := SetColor( M->color1 )
   @  1, ( 9 * k_num ) - 18 SAY PadC( func_title[ k_num ], 9 )
   SetColor( saveColor )

   RETURN ( 0 )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function key_ready()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION key_ready

   lkey := M->keystroke

   keystroke := Inkey()

   RETURN ( sysmenu() .OR. M->keystroke <> 0 )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function read_key()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION read_key

   DO WHILE ! key_ready()

   ENDDO

   IF M->error_on
      error_off()

   ENDIF

   RETURN M->keystroke


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function raw_key()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION raw_key

   PRIVATE k

   k := Inkey( 0 )

   IF M->error_on
      error_off()

   ENDIF

   RETURN k


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function q_check()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION q_check


   RETURN ( M->cur_func <> M->sysfunc .OR. M->keystroke = 27 )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function clear_gets()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION clear_gets

   PARAMETERS dummy1, dummy2, dummy3

   CLEAR gets

   RETURN


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function all_fields()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION all_fields

   PARAMETERS work_area, field_a

   stat_msg( "Lendo Estrutura do Arquivo" )

   need_field := .T.

   SELECT ( M->work_area )

   AFill( M->field_a, "", AFields( M->field_a ) + 1 )

   stat_msg( "" )

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function not_target()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION not_target

   PARAMETERS n, do_del
   PRIVATE i

   i := 1

   DO WHILE M->i <= Len( M->k_relate )

      IF Empty( k_relate[ M->i ] )
         EXIT

      ENDIF

      IF t_relate[ M->i ] == Chr( M->n + Asc( "A" ) - 1 ) + name( dbf[ M->n ] )
         need_relat := .T.

         SELECT ( M->n )

         SET RELATION TO

         IF M->do_del
            array_del( M->s_relate, M->i )
            array_del( M->k_relate, M->i )
            array_del( M->t_relate, M->i )

         ELSE
            i := M->i + 1

         ENDIF

      ELSE
         i := M->i + 1

      ENDIF
   ENDDO

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function dup_ntx()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION dup_ntx

   PARAMETERS ntx_file
   PRIVATE ntx
   PRIVATE i

   i := 1

   DO WHILE M->i <= 6

      IF Empty( dbf[ M->i ] )
         EXIT

      ENDIF

      ntx := "ntx" + SubStr( "123456", M->i, 1 )

      IF aseek( &ntx, M->ntx_file ) > 0
         RETURN M->i

      ENDIF

      i := M->i + 1

   ENDDO

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function stat_msg()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNC stat_msg( string )

   LOCAL saveColor

   saveColor := SetColor( M->color1 )
   @  3, 0 SAY Pad( string, 80 )
   SetColor( saveColor )

   RETURN ( 0 )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function error_msg()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNC error_msg( string )

   LOCAL saveColor

   saveColor := SetColor( M->color3 )
   @  3, 0 SAY string

   SetColor( M->color1 )
   @ Row(), Col()

   error_on := .T.
   SetColor( saveColor )

   RETURN ( 0 )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function error_off()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNC error_off

   LOCAL saveColor

   error_on := .F.

   saveColor := SetColor( M->color1 )
   @  3, 0
   SetColor( saveColor )

   RETURN ( 0 )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function rsvp()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION rsvp( cMES )

   RETURN IF( MsgYesNo( cMES ), "S", "N" )

/*
parameters string
private c

c := " "

do while .not. ( M->c $ "SN" + chr( 27 ) )
   error_msg( M->string + "  " )

   @  3, len( M->string ) + 1 say ""

   set cursor on

   c := upper( chr( raw_key() ) )

   if .not. M->curs_on
      set cursor OFF

   endif
enddo

return M->c
*/


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function name()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION name

   PARAMETERS spec
   PRIVATE p

   p := SubStr( M->spec, RAt( hb_ps(), M->spec ) + 1 )

   IF "." $ M->p
      p := SubStr( M->p, 1, At( ".", M->p ) - 1 )

   ENDIF

   RETURN M->p


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function pad()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION pad

   PARAMETERS s, n

   RETURN SubStr( M->s + Space( M->n ), 1, M->n )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function aseek()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION aseek

   PARAMETERS array, exp
   PRIVATE pos
   PRIVATE num_el

   num_el := afull( M->array )

   IF M->num_el = 0
      RETURN 0

   ENDIF

   SET EXACT ON

   pos := AScan( M->array, M->exp, 1, M->num_el )

   SET EXACT OFF

   RETURN M->pos


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function array_ins()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION array_ins

   PARAMETERS array, pos

   AIns( M->array, M->pos )

   array[ M->pos ] = ""

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function array_del()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION array_del

   PARAMETERS array, pos

   ADel( M->array, M->pos )

   array[ Len( M->array ) ] = ""

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function afull()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION afull

   PARAMETERS array
   PRIVATE i

   SET EXACT ON

   i := AScan( M->array, "" )

   SET EXACT OFF

   IF M->i = 0
      i := Len( M->array )

   ELSE
      i := M->i - 1

   ENDIF

   RETURN M->i


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function array_sort()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION array_sort

   PARAMETERS array

   ASort( M->array, 1, afull( M->array ) )

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function array_dir()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION array_dir

   PARAMETERS skeleton, array

   AFill( M->array, "" )

   ADir( M->skeleton, M->array )

   array_sort( M->array )

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function ntx_key()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION ntx_key

   PARAMETERS filename
   PRIVATE k
   PRIVATE buffer
   PRIVATE handle
   PRIVATE k_pos

   k := ""

   IF File( M->filename )

      IF .not. EINDEXCOMPOUND() //Lower( XEXT() ) = ".ntx" .or. ndx idx
         k_pos := 23

      ELSE
         k_pos := 25

      ENDIF

      handle := hb_fopen( M->filename )

      IF FError() = 0
         buffer := Space( 512 )

         FRead( M->handle, @buffer, 512 )

         k := hb_BSubStr( M->buffer, M->k_pos )

         k := Trim( hb_BSubStr( M->k, 1, At( Chr( 0 ), M->k ) - 1 ) )

      ENDIF

      FClose( M->handle )

   ENDIF

   RETURN M->k


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function isdata()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION isdata

   PARAMETERS k

   RETURN ( M->k >= 32 .AND. M->k < 249 .AND. M->k <> 219 .AND. Chr( M->k ) <> ";" )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function lpad()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION lpad

   PARAMETERS string, n

   RETURN ( Space( M->n - Len( M->string ) ) + M->string )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function hi_cur()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION hi_cur

   LOCAL saveColor

   IF M->cur_area > 0
      saveColor := SetColor( M->color2 )
      @ row_a[ 1 ], column[ M->cur_area ] + 2 SAY Pad( name( M->cur_dbf ), 8 )
      SetColor( saveColor )

   ENDIF

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function dehi_cur()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION dehi_cur

   LOCAL saveColor

   IF M->cur_area > 0
      saveColor := SetColor( M->color1 )
      @ row_a[ 1 ], column[ M->cur_area ] + 2 SAY Pad( name( M->cur_dbf ), 8 )
      SetColor( saveColor )

   ENDIF

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function enter_rc()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION enter_rc

   PARAMETERS org_str, r, c, max_len, pfunc, cString
   LOCAL saveColor
   PRIVATE wk_str

   xkey_clear()
   wk_str    := Pad( M->org_str, M->max_len )
   saveColor := SetColor( M->cString )
   IF !Empty( M->pfunc )
      @ r, c GET M->wk_str PICTURE M->pfunc
   ELSE
      @ r, c GET M->wk_str
   ENDIF
   READDBU()

   keystroke := LastKey()

   xkey_norm()

   IF M->error_on
      error_off()
   ENDIF

   IF M->keystroke = 27 .OR. menu_key() <> 0
      wk_str := ""

   ENDIF

   SetColor( saveColor )

   RETURN Trim( M->wk_str )



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function OBTER()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION OBTER( XARQ, XINX, XSEE, XCAM )   // SEEK MAIS RETORNO CAMPO

   DBF_USO := Alias()
   //USE &XARQ INDEX &XINX NEW SHARED
   dbUseArea( .T.,, XARQ,, .T. , .F. ) 
   dbSetIndex( XINX )
   WHILE NetErr()
   ENDDO
   dbGoTop()
   dbSeek( XSEE )
   OBTIDO := if( Found(), &XCAM, MAKE_EMPTY( XCAM ) )
   dbCloseArea()
   IF !Empty( DBF_USO )
      SELE &DBF_USO
   ENDIF

   RETURN OBTIDO




// + EOF: dbuutil.prg
// +
