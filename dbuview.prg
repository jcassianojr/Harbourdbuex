// +--------------------------------------------------------------------
// +
// +
// +
// +    Programa  : dbuview.prg
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


#include "BOX.CH"


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function SET_VIEW()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION SET_VIEW

   LOCAL saveColor
   PRIVATE bar_line
   PRIVATE empty_line
   PRIVATE ntx
   PRIVATE field_n
   PRIVATE el
   PRIVATE cur_row
   PRIVATE t_row
   PRIVATE ch_draw
   PRIVATE strn
   PRIVATE is_redraw
   PRIVATE is_insert
   PRIVATE horiz_keys
   PRIVATE prev_area
   PRIVATE i

   saveColor := SetColor( M->color1 )

   DECLARE d_array[ Len( M->ntx1 ) ]

   horiz_keys := Chr( 4 ) + Chr( 19 ) + Chr( 1 ) + Chr( 6 )
   bar_line   := ""
   empty_line := ""
   prev_area  := 0
   ch_draw    := .F.

   help_code := 1

   keystroke := 0

   set_deflt()

   IF ! Empty( M->view_err )
      error_msg( M->view_err )
      view_err := ""

   ENDIF

   DO WHILE ! q_check()

      DO CASE

      CASE M->cur_area = 0
         cur_area := aseek( M->dbf, M->cur_dbf )

         IF M->cur_area = 0

            FOR i := 1 TO 3
               STORE row_a[ M->i ] TO cr1[ M->i ], cr2[ M->i ], cr3[ M->i ], ;
                  cr4[ M->i ], cr5[ M->i ], cr6[ M->i ]
               STORE 1 TO el1[ M->i ], el2[ M->i ], el3[ M->i ], el4[ M->i ], ;
                  el5[ M->i ], el6[ M->i ]

            NEXT

            cur_dbf  := dbf[ 1 ]
            cur_area := page := 1

            set_deflt()

         ENDIF

         draw_view( 0 )

      CASE M->cur_area <> M->prev_area
         cur_dbf := dbf[ M->cur_area ]

         strn := SubStr( "123456", M->cur_area, 1 )

         ntx     := "ntx" + strn
         field_n := "field_n" + strn
         el      := "el" + strn

         t_row := "cr" + strn

         IF M->page > 1 .AND. M->prev_area <> 0
            &el[ M->page ] = &el[ M->page ] + ;
               &cur_row[ M->page ] - &t_row[ M->page ]

            &t_row[ M->page ] = &cur_row[ M->page ]

         ENDIF

         cur_row := M->t_row

         prev_area := M->cur_area

      CASE M->keystroke = 19

         IF M->cur_area > 1
            cur_area := M->cur_area - 1

         ENDIF

         keystroke := 0

      CASE M->keystroke = 1
         cur_area  := 1
         keystroke := 0

      CASE M->keystroke = 4

         IF M->cur_area < 6 .AND. ! Empty( M->cur_dbf )
            cur_area := M->cur_area + 1

            IF Empty( dbf[ M->cur_area ] )
               page := 1
               set_deflt()

            ENDIF
         ENDIF

         keystroke := 0

      CASE M->keystroke = 6

         IF M->cur_area < 6 .AND. ! Empty( M->cur_dbf )
            i := afull( M->dbf )

            IF M->i < 6 .AND. ( M->page = 1 .OR. M->cur_area = M->i )
               cur_area := M->i + 1

               page := 1
               set_deflt()

            ELSE
               cur_area := M->i

            ENDIF

         ENDIF

         keystroke := 0

      CASE M->keystroke = 18 .OR. M->keystroke = 5

         IF M->page > 1
            page := M->page - 1
            set_deflt()

         ENDIF

         keystroke := 0

      CASE M->keystroke = 3 .OR. M->keystroke = 24

         IF M->page < 3 .AND. ! Empty( M->cur_dbf )
            page := M->page + 1
            set_deflt()

            &el[ M->page ] = &el[ M->page ] - ;
               ( &cur_row[ M->page ] - row_a[ M->page ] )
            &cur_row[ M->page ] = row_a[ M->page ]

         ENDIF

         keystroke := 0

      CASE M->keystroke = 22 .OR. M->keystroke = 13 .OR. ;
            isdata( M->keystroke ) .OR. ( M->local_func = 2 .AND. ;
            ( M->local_sel = 1 .OR. M->local_sel = 2 ) ) .OR. ;
            ( M->local_func = 8 .AND. M->local_sel = 3 )

         IF M->local_func <> 0
            page := M->local_sel
            set_deflt()

            keystroke := 22

         ENDIF

         IF M->page = 1 .AND. M->n_files < 14
            is_redraw := M->cur_area < 6 .AND. ( M->keystroke = 22 .OR. ;
               Empty( M->cur_dbf ) )

            is_insert := ( M->keystroke = 22 .AND. ;
               ! Empty( M->cur_dbf ) .AND. M->cur_area < 6 )

            IF M->is_redraw
               draw_view( M->cur_area )

               SetColor( M->color2 )
               @ row_a[ 1 ], column[ M->cur_area ] + 2 SAY Space( 8 )
               SetColor( M->color1 )

            ELSE
               hi_cur()

            ENDIF

            ch_draw := open_dbf( M->is_insert, .F. )

            IF M->ch_draw
               channel( &ntx, &field_n, &el, &cur_row, ;
                  M->cur_area, M->cur_area )

               cur_dbf := dbf[ M->cur_area ]

            ELSE

               IF M->is_redraw
                  draw_view( 0 )

               ELSE
                  dehi_cur()

               ENDIF
            ENDIF

         ELSE

            IF M->page > 1
               channel( &ntx, &field_n, &el, &cur_row, ;
                  M->cur_area, M->cur_area )

            ELSE
               error_msg( "Muitos Arquivos j  abertos" )

            ENDIF
         ENDIF

         keystroke := 0

      CASE M->keystroke = 7

         IF M->page = 1 .AND. ! Empty( M->cur_dbf )
            stat_msg( "Fechando o Arquivo" )
            clear_dbf( M->cur_area, 2 )

            IF M->cur_area = 6
               ch_draw := .T.
               channel( &ntx, &field_n, &el, &cur_row, ;
                  M->cur_area, M->cur_area )

            ELSE
               draw_view( 0 )

            ENDIF

            cur_dbf := dbf[ M->cur_area ]

            stat_msg( "" )

         ELSE

            IF M->page > 1
               channel( &ntx, &field_n, &el, &cur_row, ;
                  M->cur_area, M->cur_area )

            ENDIF
         ENDIF

         keystroke := 0

      CASE M->local_func = 8 .AND. M->local_sel = 1
         set_relation()
         keystroke := 0

      CASE M->local_func = 8 .AND. M->local_sel = 2
         get_filter()
         keystroke := 0

      CASE M->local_func = 8 .AND. M->local_sel = 4
         ABERTURA     := if( rsvp( "Deseja Abertura Exclusiva S/N " ) = "S", .T., .F. )
         keystroke    := 0
         m->local_sel := 0

      CASE M->local_func = 8 .AND. M->local_sel = 5
         IF rsvp( "Deseja Vizualizar Registros Apagados S/N " ) = "S"
            SET DELE OFF
         ELSE
            SET DELE ON
         ENDIF
         keystroke    := 0
         m->local_sel := 0

      CASE M->local_func = 8 .AND. M->local_sel = 6
         tipodbfesc()

         keystroke    := 0
         m->local_sel := 0

      CASE M->local_func = 8 .AND. M->local_sel = 7

         pegparexp()

         keystroke    := 0
         m->local_sel := 0

      CASE M->local_func = 2 .AND. M->local_sel = 3
         set_from( .T. )

         IF ! Empty( M->view_file ) .AND. M->keystroke = 13
            cur_area := 0
            cur_dbf  := ""

         ENDIF

         keystroke := 0

      CASE M->local_func = 4
         save_view()
         keystroke := 0

      OTHERWISE

         DO CASE

         CASE M->page = 1

            IF ! key_ready()
               hi_cur()

               read_key()

               dehi_cur()

            ENDIF

         CASE M->page = 2
            d_copy( &ntx )

            bar_menu( column[ M->cur_area ] + 2, ;
               column[ M->cur_area ] + 9, M->d_array )

         CASE M->page = 3
            bar_menu( column[ M->cur_area ] + 1, ;
               column[ M->cur_area ] + 10, &field_n )

         ENDCASE

         IF M->keystroke = 27

            IF rsvp( "Sair para o DOS? (S/N)" ) <> "S"
               keystroke := 0
            ENDIF
         ENDIF
      ENDCASE
   ENDDO

   IF M->sysfunc = 3 .AND. M->func_sel = 1 .AND. Empty( M->cur_dbf )
      draw_view( M->cur_area )

   ENDIF

   RETURN


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function channel()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION channel

   PARAMETERS ch_ntx, ch_field_n, ch_el, ch_cur_row, n, dbf_num
   LOCAL saveColor
   PRIVATE f_n
   PRIVATE is_ins
   PRIVATE temp_buff
   PRIVATE d_item

   saveColor := SetColor( M->color1 )

   DO CASE

   CASE M->ch_draw
      Scroll( row_a[ 2 ], column[ M->n ], row_x[ 2 ], column[ M->n ] + 11, 0 )
      Scroll( row_a[ 3 ], column[ M->n ], row_x[ 3 ], column[ M->n ] + 11, 0 )

      @ row_a[ 1 ], column[ M->n ] + 2 SAY Pad( name( dbf[ M->dbf_num ] ), 8 )

      IF ! Empty( ch_ntx[ 1 ] )
         d_copy( M->ch_ntx )
         list_array( row_a[ 2 ], column[ M->n ] + 2, row_x[ 2 ], column[ M->n ] + 9, ;
            M->d_array, ch_el[ 2 ] - ( ch_cur_row[ 2 ] - row_a[ 2 ] ) )

      ENDIF

      list_array( row_a[ 3 ], column[ M->n ] + 1, row_x[ 3 ], column[ M->n ] + 10, ;
         M->ch_field_n, ch_el[ 3 ] - ( ch_cur_row[ 3 ] - row_a[ 3 ] ) )

      ch_draw := .F.

   CASE M->keystroke = 22 .OR. M->keystroke = 13 .OR. isdata( M->keystroke )

      IF isdata( M->keystroke )
         KEYBOARD Chr( M->keystroke )

      ENDIF

      is_ins := ( M->keystroke = 22 )

      DO CASE

      CASE M->page = 2 .AND. ( M->n_files < 14 .OR. ( M->keystroke <> 22 ;
            .AND. ! Empty( ch_ntx[ ch_el[ 2 ] ] ) ) )
         temp_buff := SaveScreen( row_a[ 2 ], column[ M->n ] + 1, ;
            row_x[ 2 ], column[ M->n ] + 11 )

         IF M->is_ins

            IF ch_el[ 2 ] + row_x[ 2 ] - ch_cur_row[ 2 ] = afull( M->ch_ntx )
               @ row_x[ 2 ], column[ M->n ] + 11 SAY M->more_down

            ENDIF

            IF ch_cur_row[ 2 ] < row_x[ 2 ]
               Scroll( ch_cur_row[ 2 ], column[ M->n ] + 1, ;
                  row_x[ 2 ], column[ M->n ] + 10, - 1 )

            ENDIF

            d_item := Space( 8 )

         ELSE
            d_item := Pad( name( ch_ntx[ ch_el[ 2 ] ] ), 8 )

         ENDIF

         SetColor( M->color2 )
         @ ch_cur_row[ 2 ], column[ M->n ] + 2 SAY M->d_item
         SetColor( M->color1 )

         f_n := get_ntx( ch_cur_row[ 2 ], column[ M->n ] + 2, ;
            ch_ntx[ ch_el[ 2 ] ], M->is_ins )

         IF ! M->f_n == ch_ntx[ ch_el[ 2 ] ] .AND. ! Empty( M->f_n )
            need_ntx := .T.

            IF M->is_ins
               array_ins( M->ch_ntx, ch_el[ 2 ] )

            ENDIF

            ch_ntx[ ch_el[ 2 ] ] = M->f_n

            IF ch_el[ 2 ] = 1
               not_target( M->n, .T. )

            ENDIF

            @ ch_cur_row[ 2 ], column[ M->n ] + 2 ;
               SAY Pad( name( ch_ntx[ ch_el[ 2 ] ] ), 8 )

         ELSE
            RestScreen( row_a[ 2 ], column[ M->n ] + 1, ;
               row_x[ 2 ], column[ M->n ] + 11, M->temp_buff )

         ENDIF

      CASE M->page = 3
         temp_buff := SaveScreen( row_a[ 3 ], column[ M->n ] + 1, ;
            row_x[ 3 ], column[ M->n ] + 11 )

         IF M->is_ins

            IF ch_el[ 3 ] + row_x[ 3 ] - ch_cur_row[ 3 ] = afull( M->ch_field_n )
               @ row_x[ 3 ], column[ M->n ] + 11 SAY M->more_down

            ENDIF

            IF ch_cur_row[ 3 ] < row_x[ 3 ]
               Scroll( ch_cur_row[ 3 ], column[ M->n ] + 1, ;
                  row_x[ 3 ], column[ M->n ] + 10, - 1 )

            ENDIF

            d_item := Space( 10 )

         ELSE
            d_item := Pad( ch_field_n[ ch_el[ 3 ] ], 10 )

         ENDIF

         SetColor( M->color2 )
         @ ch_cur_row[ 3 ], column[ M->n ] + 1 SAY M->d_item
         SetColor( M->color1 )

         f_n := get_field( ch_cur_row[ 3 ], column[ M->n ] + 1, M->n, ;
            ch_field_n[ ch_el[ 3 ] ] )

         IF ( M->is_ins .OR. ! M->f_n == ch_field_n[ ch_el[ 3 ] ] ) ;
               .AND. ! Empty( M->f_n )
            need_field := .T.

            IF M->is_ins
               array_ins( M->ch_field_n, ch_el[ 3 ] )

            ENDIF

            ch_field_n[ ch_el[ 3 ] ] = M->f_n

            @ ch_cur_row[ 3 ], column[ M->n ] + 1 ;
               SAY Pad( ch_field_n[ ch_el[ 3 ] ], 10 )

         ELSE
            RestScreen( row_a[ 3 ], column[ M->n ] + 1, ;
               row_x[ 3 ], column[ M->n ] + 11, M->temp_buff )

         ENDIF
      ENDCASE

   CASE M->keystroke = 7

      DO CASE

      CASE M->page = 2 .AND. ! Empty( ch_ntx[ ch_el[ 2 ] ] )
         need_ntx := .T.

         IF ch_el[ 2 ] = 1
            not_target( M->n, .T. )

         ENDIF

         SELECT ( M->n )

         CLOSE INDEX

         array_del( M->ch_ntx, ch_el[ 2 ] )

         n_files := M->n_files - 1

         IF ch_cur_row[ 2 ] < row_x[ 2 ]
            Scroll( ch_cur_row[ 2 ], column[ M->n ] + 1, ;
               row_x[ 2 ], column[ M->n ] + 9, 1 )

         ENDIF

         @ row_x[ 2 ], column[ M->n ] + 2 ;
            SAY Pad( name( ch_ntx[ ch_el[ 2 ] + row_x[ 2 ] - ch_cur_row[ 2 ] ] ), 8 )

         IF afull( M->ch_ntx ) - ch_el[ 2 ] = row_x[ 2 ] - ch_cur_row[ 2 ]
            @ row_x[ 2 ], column[ M->n ] + 11 SAY " "

         ENDIF

      CASE M->page = 3 .AND. ! Empty( ch_field_n[ ch_el[ 3 ] ] )
         need_field := .T.

         array_del( M->ch_field_n, ch_el[ 3 ] )

         IF ch_cur_row[ 3 ] < row_x[ 3 ]
            Scroll( ch_cur_row[ 3 ], column[ M->n ] + 1, ;
               row_x[ 3 ], column[ M->n ] + 10, 1 )

         ENDIF

         @ row_x[ 3 ], column[ M->n ] + 1 ;
            SAY Pad( ch_field_n[ ch_el[ 3 ] + row_x[ 3 ] - ch_cur_row[ 3 ] ], 10 )

         IF afull( M->ch_field_n ) - ch_el[ 3 ] = row_x[ 3 ] - ch_cur_row[ 3 ]
            @ row_x[ 3 ], column[ M->n ] + 11 SAY " "

         ENDIF
      ENDCASE
   ENDCASE

   SetColor( saveColor )

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function bar_menu()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION bar_menu

   PARAMETERS l, r, array
   LOCAL saveColor
   PRIVATE num_d
   PRIVATE num_full
   PRIVATE cur_el
   PRIVATE rel_row
   PRIVATE x
   PRIVATE t
   PRIVATE b

   keystroke := NextKey()

   IF Chr( M->keystroke ) $ M->horiz_keys
      Inkey()
      RETURN 0

   ENDIF

   t := row_a[ M->page ]
   b := row_x[ M->page ]

   num_full := afull( M->array )

   num_d := M->num_full

   IF M->num_d < Len( M->array )
      num_d := M->num_d + 1

      array[ M->num_d ] = " "

   ENDIF

   x := if( M->r - M->l > 7, 1, 2 )

   rel_row := &cur_row[ M->page ] - M->t

   saveColor := SetColor( M->color4 )
   AChoice( M->t, M->l, M->b, M->r, M->array, .T., ;
      "bar_func", &el[ M->page ], M->rel_row )
   SetColor( saveColor )

   &cur_row[ M->page ] = M->rel_row + M->t

   IF array[ M->num_d ] == " "
      array[ M->num_d ] = ""

   ENDIF

   sysmenu()

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function bar_func()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION bar_func

   PARAMETERS mode, bar_el, row
   PRIVATE ret_code

   keystroke := LastKey()

   ret_code := 2

   &el[ M->page ] = M->bar_el
   rel_row := M->row

   IF M->error_on
      error_off()

   ENDIF

   DO CASE

   CASE M->mode = 0
      @ M->t, M->r + M->x SAY if( M->bar_el > M->row + 1, M->more_up, " " )
      @ M->b, M->r + M->x SAY if( M->num_full > ;
         ( M->bar_el + M->b - M->t - M->row ), ;
         M->more_down, " " )

   CASE M->mode = 1 .OR. M->mode = 2
      ret_code := 0

   CASE M->mode = 3

      DO CASE

      CASE Chr( M->keystroke ) $ M->horiz_keys
         ret_code := 0

      CASE M->keystroke = 27
         ret_code := 0

      CASE M->keystroke = 13
         ret_code := 1

      CASE isdata( M->keystroke )
         ret_code := 1

      CASE M->keystroke = 22 .OR. M->keystroke = 7
         ret_code := 1

      CASE menu_key() <> 0
         ret_code := 0

      ENDCASE

   CASE M->mode = 4
      ret_code := 0

   ENDCASE

   RETURN M->ret_code


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function list_array()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION list_array

   PARAMETERS t, l, b, r, array, top_el
   LOCAL saveColor
   PRIVATE bottom_el
   PRIVATE num_full
   PRIVATE x

   saveColor := SetColor( M->color4 )
   IF ! Empty( array[ M->top_el ] )
      bottom_el := M->top_el + M->b - M->t

      num_full := afull( M->array )

      x := if( M->r - M->l > 7, 1, 2 )

      IF M->top_el > 1 .AND. M->bottom_el = M->num_full + 1
         array[ M->bottom_el ] = " "

      ENDIF

      AChoice( M->t, M->l, M->b, M->r, M->array, .F., "", M->top_el )
      SetColor( M->color1 )

      @ M->t, M->r + M->x SAY if( M->top_el > 1, M->more_up, " " )
      @ M->b, M->r + M->x SAY if( M->bottom_el < M->num_full, M->more_down, " " )

      IF array[ M->bottom_el ] == " "
         array[ M->bottom_el ] = ""

      ENDIF
   ENDIF

   SetColor( saveColor )

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function set_deflt()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION set_deflt

   IF M->page = 2
      menu_deflt[ 2 ] := menu_deflt[ 3 ] := 2

   ELSE
      menu_deflt[ 2 ] := menu_deflt[ 3 ] := 1

   ENDIF

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function bline()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION bline

   PARAMETERS num_slots
   PRIVATE i
   PRIVATE k

   IF num_slots < 6
      num_slots++

   ENDIF

   bar_line   := "------------"
   empty_line := ""

   k := 1

   DO WHILE M->k < M->num_slots
      bar_line   := M->bar_line + "Ñ------------"
      empty_line := M->empty_line + Space( 12 ) + "Ý"

      k := M->k + 1

   ENDDO

   i := Int( ( 80 - Len( M->bar_line ) ) / 2 )

   FOR k := 1 TO M->num_slots
      column[ M->k ] = M->i + ( 13 * ( M->k - 1 ) )

   NEXT

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function draw_view()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION draw_view

   PARAMETERS blank_area
   PRIVATE i
   PRIVATE j
   PRIVATE ntx
   PRIVATE field_n
   PRIVATE el
   PRIVATE cur_row
   PRIVATE strnum

   i := afull( M->dbf )

   IF M->i < 6 .AND. blank_area <> 0
      i := M->i + 1

   ENDIF

   bline( M->i )
   LAYOUT()

   @ row_a[ 1 ] - 2, 36        SAY "Arquivos"
   @ row_a[ 1 ] - 1, column[ 1 ] SAY M->bar_line
   @ row_a[ 1 ], column[ 1 ]     SAY M->empty_line

   @ row_a[ 2 ] - 2, 36        SAY "Indices"
   @ row_a[ 2 ] - 1, column[ 1 ] SAY M->bar_line
   @ row_a[ 2 ], column[ 1 ]     SAY M->empty_line
   @ row_a[ 2 ] + 1, column[ 1 ]   SAY M->empty_line
   @ row_a[ 2 ] + 2, column[ 1 ]   SAY M->empty_line

   @ row_a[ 3 ] - 2, 36        SAY "Campos"
   @ row_a[ 3 ] - 1, column[ 1 ] SAY M->bar_line

   FOR i := row_a[ 3 ] TO row_x[ 3 ]
      @ M->i, column[ 1 ] SAY M->empty_line

   NEXT

   i := 1
   j := 1

   DO WHILE M->j <= 6

      IF Empty( dbf[ M->i ] )
         EXIT

      ENDIF

      IF M->j <> M->blank_area
         strnum := SubStr( "123456", M->i, 1 )

         ntx     := "ntx" + strnum
         field_n := "field_n" + strnum
         el      := "el" + strnum
         cur_row := "cr" + strnum

         ch_draw := .T.
         channel( &ntx, &field_n, &el, &cur_row, M->j, M->i )

         i := M->i + 1

      ENDIF

      j := M->j + 1

   ENDDO

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function d_copy()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION d_copy

   PARAMETERS array
   PRIVATE i

   AFill( M->d_array, "" )

   i := 1

   DO WHILE M->i <= Len( M->array )

      IF Empty( array[ M->i ] )
         EXIT

      ENDIF

      d_array[ M->i ] = name( array[ M->i ] )

      i := M->i + 1

   ENDDO

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function open_dbf()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION open_dbf

   PARAMETERS is_insert, not_view
   PRIVATE shift
   PRIVATE filename
   PRIVATE a_temp
   PRIVATE f_row
   PRIVATE d_col
   PRIVATE ret_val
   PRIVATE old_help

   IF M->n_files >= 14
      error_msg( "Muitos arquivos j  abertos" )
      RETURN .F.

   ENDIF

   old_help  := M->help_code
   help_code := 6

   filename := ""

   f_row := cr1[ 1 ]
   d_col := column[ M->cur_area ] + 2

   shift := if( M->is_insert, 1, 0 )

   SELECT ( M->cur_area )

   IF M->not_view
      filename := M->cur_dbf
      ret_val  := do_opendbf()

   ELSE
      ret_val := .F.

      IF isdata( M->keystroke )
         KEYBOARD Chr( M->keystroke )

         filename := enter_rc( dbf[ M->cur_area ], M->f_row, M->d_col, 64, "@KS8", ;
            M->color1 )

         IF ! Empty( M->filename )

            IF !( RAt( ".", M->filename ) > RAt( hb_ps(), M->filename ) )
               filename := M->filename + "."+TABLEEXT

            ENDIF

            ret_val := do_opendbf()

            IF ! M->ret_val
               @ M->f_row, M->d_col SAY Pad( name( M->cur_dbf ), 8 )

            ENDIF

         ELSE
            @ M->f_row, M->d_col SAY Pad( name( M->cur_dbf ), 8 )

         ENDIF

         IF menu_key() <> 0
            KEYBOARD Chr( M->keystroke )

         ELSE
            keystroke := 0

         ENDIF

      ELSE
         ret_val := filebox( "."+TABLEEXT, "dbf_list", "dopen_titl", ;
            "do_opendbf", .F., 8 ) <> 0

      ENDIF
   ENDIF

   IF M->ret_val
      a_temp := "field_n" + SubStr( "123456", M->cur_area, 1 )
      all_fields( M->cur_area, &a_temp )

      a_temp := "cr" + SubStr( "123456", M->cur_area, 1 )
      &a_temp[ 2 ] = row_a[ 2 ]
      &a_temp[ 3 ] = row_a[ 3 ]

      a_temp := "el" + SubStr( "123456", M->cur_area, 1 )
      AFill( &a_temp, 1 )

   ENDIF

   help_code := M->old_help

   RETURN M->ret_val


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function dopen_titl()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION dopen_titl

   PARAMETERS sysparam

   RETURN box_title( M->sysparam, "Abrindo arquivo de Dados..." )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function do_opendbf()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION do_opendbf

   PRIVATE done

   DO CASE

   CASE Empty( M->filename )
      error_msg( "Arquivo de dados n„o Selecionado" )
      done := .F.

   CASE ! hb_FileExists( M->filename )
      error_msg( "N„o pode ser aberto " + M->filename )
      done := .F.

   CASE aseek( M->dbf, M->filename ) > 0 .AND. ;
         !( dbf[ M->cur_area ] == M->filename .AND. M->shift = 0 )
      error_msg( "Arquivo de Dados est  aberto em duas areas" )
      done := .F.

   OTHERWISE
      stat_msg( "Abrindo o arquivo" )

      IF ! Empty( dbf[ M->cur_area ] )
         clear_dbf( M->cur_area, M->shift )

      ENDIF

      n_files := M->n_files + 1

      dbf[ M->cur_area ] = M->filename

      SELECT ( M->cur_area )
      DBUREDE( filename,, ABERTURA )
      aINDICES := FILENAMES( tiraext( filename ) + "*" + XEXT() )
      IF Len( aINDICES ) > 0
         cNtx := "ntx" + SubStr( "123456", M->cur_area, 1 )
         AFill( &cNTX., "" )
         FOR X := 1 TO Len( aINDICES )
            IF X < 8
               &cNTX.[ X ] := aINDICES[ X ]
            ENDIF
         NEXT X
         IF TIPODBF = 2 .OR. TIPODBF = 4 .OR. TIPODBF = 6  // CDX MDX
            ordSetFocus( 1 )
            dbGoTop()
         ENDIF
      ENDIF

      stat_msg( "" )

      done := .T.

   ENDCASE

   RETURN M->done


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function get_ntx()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION get_ntx

   PARAMETERS d_row, d_col, org_file, is_ins
   PRIVATE filename
   PRIVATE old_help

   IF M->n_files >= 14
      error_msg( "Muitos arquivos j  abertos" )
      RETURN ""

   ENDIF

   old_help  := M->help_code
   help_code := 8

   filename := ""

   IF isdata( M->keystroke )
      KEYBOARD Chr( M->keystroke )

      filename := enter_rc( M->org_file, M->d_row, M->d_col, 64, "@KS8", M->color1 )

      IF ! Empty( M->filename )

         IF !( RAt( ".", M->filename ) > RAt( hb_ps(), M->filename ) )
            filename += XEXT()

         ENDIF

         IF ! do_openntx()
            filename := ""

         ENDIF
      ENDIF

      IF menu_key() <> 0
         KEYBOARD Chr( M->keystroke )

      ELSE
         keystroke := 0

      ENDIF

   ELSE

      IF filebox( XEXT(), "ntx_list", "xopen_titl", "do_openntx", .F., 13 ) = 0
         filename := ""

      ENDIF
   ENDIF

   help_code := M->old_help

   RETURN M->filename


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function xopen_titl()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION xopen_titl

   PARAMETERS sysparam

   RETURN box_title( M->sysparam, "Abrindo Arquivo de Indice..." )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function do_openntx()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION do_openntx

   PRIVATE done

   DO CASE

   CASE Empty( M->filename )
      error_msg( "Arquivo de indice n„o selecionado" )
      done := .F.

   CASE ! hb_FileExists( M->filename )
      error_msg( "N„o pode ser aberto " + M->filename )
      done := .F.

   CASE dup_ntx( M->filename ) <> 0 .AND. ;
         ( M->is_ins .OR. ! M->filename == M->org_file )
      error_msg( "Arquivo de indice j  est  aberto" )
      done := .F.

   OTHERWISE

      IF Empty( M->org_file ) .OR. M->is_ins
         n_files := M->n_files + 1

      ENDIF

      done := .T.

   ENDCASE

   RETURN M->done


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function get_field()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION get_field

   PARAMETERS f_row, d_col, work_area, org_field
   PRIVATE field_mvar
   PRIVATE rel_row
   PRIVATE cur_el
   PRIVATE okee_dokee
   PRIVATE fi_disp
   PRIVATE old_help

   old_help  := M->help_code
   help_code := 2

   field_mvar := ""

   SELECT ( M->work_area )

   DECLARE field_m[ FCount() ]
   all_fields( M->work_area, M->field_m )

   IF isdata( M->keystroke )
      KEYBOARD Chr( M->keystroke )

      field_mvar := enter_rc( M->org_field, M->f_row, M->d_col, 10, "@K!", M->color1 )

      IF ! Empty( M->field_mvar )

         IF ! do_fsel()
            field_mvar := ""

         ENDIF

      ENDIF

      IF menu_key() <> 0
         KEYBOARD Chr( M->keystroke )

      ELSE
         keystroke := 0

      ENDIF

   ELSE
      DECLARE boxarray[ 5 ]

      boxarray[ 1 ] = "fsel_title(sysparam)"
      boxarray[ 2 ] = "getfield(sysparam)"
      boxarray[ 3 ] = "ok_button(sysparam)"
      boxarray[ 4 ] = "can_button(sysparam)"
      boxarray[ 5 ] = "fieldlist(sysparam)"

      cur_el  := 1
      rel_row := 0

      okee_dokee := "do_fsel()"
      fi_disp    := "getfield(3)"

      IF multibox( 7, 17, 5, 5, M->boxarray ) = 0
         field_mvar := ""

      ENDIF
   ENDIF

   help_code := M->old_help

   RETURN M->field_mvar


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function getfield()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION getfield

   PARAMETERS sysparam

   RETURN genfield( M->sysparam, .F. )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function fsel_title()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION fsel_title

   PARAMETERS sysparam

   RETURN box_title( M->sysparam, "Arquivo Selecionado..." )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function do_fsel()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION do_fsel

   PRIVATE done

   DO CASE

   CASE Empty( M->field_mvar )
      error_msg( "Nome de campo n„o selecionado" )
      done := .F.

   CASE aseek( M->field_m, M->field_mvar ) = 0
      error_msg( M->field_mvar + " n„o existe" )
      done := .F.

   OTHERWISE
      done := .T.

   ENDCASE

   RETURN M->done


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function set_relation()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION set_relation

   LOCAL saveColor
   PRIVATE c_row
   PRIVATE c_el
   PRIVATE rel_buff
   PRIVATE pos_r
   PRIVATE width
   PRIVATE old_help
   PRIVATE k
   PRIVATE n_area
   PRIVATE ls
   PRIVATE lk
   PRIVATE lt
   PRIVATE cNorm
   PRIVATE cHilite

   cNorm     := color7
   cHilite   := color2
   saveColor := SetColor( M->cNorm )

   old_help  := M->help_code
   help_code := 9

   box_open := .T.

   IF Empty( M->bar_line )
      bline( afull( M->dbf ) )

   ENDIF

   width := Len( M->bar_line ) - 1

   pos_r := column[ 1 ] + M->width

   rel_buff := SaveScreen( 8, column[ 1 ] - 1, 23, M->pos_r + 1 )

   Scroll( 8, column[ 1 ] - 1, 23, M->pos_r + 1, 0 )
   @  8, column[ 1 ] - 1, 23, M->pos_r + 1 BOX M->frame

   @  9, 35        SAY "Rela‡”es"
   @ 10, column[ 1 ] SAY M->bar_line

   c_row := 11
   c_el  := 1

   draw_relat( 1 )

   keystroke := 0

   DO WHILE ! q_check()

      DO CASE

      CASE M->keystroke = 18

         IF M->c_el > ( ( M->c_row - 11 ) / 2 ) + 1
            c_el := M->c_el - 5

            IF M->c_el < ( ( M->c_row - 11 ) / 2 ) + 1
               c_el := ( ( M->c_row - 11 ) / 2 ) + 1

            ENDIF

            draw_relat( M->c_el - ( ( M->c_row - 11 ) / 2 ) )

         ELSE

            IF M->c_el > 1
               c_el  := 1
               c_row := 11

            ENDIF
         ENDIF

         keystroke := 0

      CASE M->keystroke = 3
         k := afull( M->k_relate )

         IF M->k < Len( M->k_relate )
            k := M->k + 1

         ENDIF

         IF M->c_el < M->k - ( ( 21 - M->c_row ) / 2 )
            c_el := M->c_el + 5

            IF M->c_el > M->k - ( ( 21 - M->c_row ) / 2 )
               c_el := M->k - ( ( 21 - M->c_row ) / 2 )

            ENDIF

            draw_relat( M->c_el - ( ( M->c_row - 11 ) / 2 ) )

         ELSE

            IF M->c_el < M->k
               c_row := M->c_row + ( ( M->k - M->c_el ) * 2 )
               c_el  := M->k

            ENDIF
         ENDIF

         keystroke := 0

      CASE M->keystroke = 22 .OR. isdata( M->keystroke )

         k := M->c_el + ( ( 21 - M->c_row ) / 2 ) + 1

         ls := s_relate[ Len( M->s_relate ) ]
         lk := k_relate[ Len( M->k_relate ) ]
         lt := t_relate[ Len( M->t_relate ) ]

         array_ins( M->s_relate, M->c_el )
         array_ins( M->k_relate, M->c_el )
         array_ins( M->t_relate, M->c_el )

         IF M->c_row < 21
            Scroll( M->c_row, column[ 1 ], 22, M->pos_r - 1, - 2 )

         ELSE
            @ M->c_row + 1, column[ 1 ] SAY Space( M->width )

         ENDIF

         IF M->k <= Len( M->k_relate )

            IF ! Empty( k_relate[ M->k ] )
               @ 22, M->pos_r SAY M->more_down

            ENDIF
         ENDIF

         get_relation( M->c_row, M->c_el )

         IF ! Empty( k_relate[ M->c_el ] )
            disp_relation( M->c_row, M->c_el, color7 )

         ELSE
            STORE "x" TO s_relate[ M->c_el ], ;
               k_relate[ M->c_el ], t_relate[ M->c_el ]

            array_del( M->s_relate, M->c_el )
            array_del( M->k_relate, M->c_el )
            array_del( M->t_relate, M->c_el )

            s_relate[ Len( M->s_relate ) ] = M->ls
            k_relate[ Len( M->k_relate ) ] = M->lk
            t_relate[ Len( M->t_relate ) ] = M->lt

            IF M->c_row < 21
               Scroll( M->c_row, column[ 1 ], 22, M->pos_r - 1, 2 )

            ELSE
               @ 21, column[ 1 ] SAY Space( M->width )
               @ 22, column[ 1 ] SAY Space( M->width )

            ENDIF

            disp_relation( 21, M->c_el + ( ( 21 - M->c_row ) / 2 ), color7 )

         ENDIF

         IF M->k <= Len( M->k_relate )

            IF Empty( k_relate[ M->k ] )
               @ 22, M->pos_r SAY " "

            ENDIF
         ENDIF

         keystroke := 0

      CASE M->keystroke = 13
         get_relation( M->c_row, M->c_el )

         disp_relation( M->c_row, M->c_el, color7 )

         keystroke := 0

      CASE M->keystroke = 7 .AND. ! Empty( k_relate[ M->c_el ] )
         need_relat := .T.

         n_area := Asc( s_relate[ M->c_el ] ) - Asc( "A" ) + 1
         SELECT ( M->n_area )

         SET RELATION TO

         array_del( M->s_relate, M->c_el )
         array_del( M->k_relate, M->c_el )
         array_del( M->t_relate, M->c_el )

         IF M->c_row < 21
            Scroll( M->c_row, column[ 1 ], 22, M->pos_r - 1, 2 )

         ELSE
            @ 21, column[ 1 ] SAY Space( M->width )
            @ 22, column[ 1 ] SAY Space( M->width )

         ENDIF

         disp_relation( 21, M->c_el + ( ( 21 - M->c_row ) / 2 ), color7 )

         IF M->c_el < Len( M->k_relate ) - ( ( 21 - M->c_row ) / 2 )

            IF Empty( k_relate[ M->c_el + ( ( 21 - M->c_row ) / 2 ) + 1 ] )
               @ 22, M->pos_r SAY " "

            ENDIF
         ENDIF

         keystroke := 0

      CASE M->keystroke = 5 .AND. M->c_el > 1
         c_el := M->c_el - 1

         IF M->c_row > 11
            c_row := M->c_row - 2

         ELSE
            Scroll( 11, column[ 1 ], 22, M->pos_r - 1, - 2 )

            disp_relation( 11, M->c_el, color7 )

            IF M->c_el <= Len( M->k_relate ) - 6

               IF ! Empty( k_relate[ M->c_el + 6 ] )
                  @ 22, M->pos_r SAY M->more_down

               ENDIF
            ENDIF

            IF M->c_el = 1
               @ 11, M->pos_r SAY " "

            ENDIF
         ENDIF

         keystroke := 0

      CASE M->keystroke = 24 .AND. ! ;
            ( Empty( k_relate[ M->c_el ] ) .OR. M->c_el = Len( M->k_relate ) )
         c_el := M->c_el + 1

         IF c_row < 22 - 2
            c_row := M->c_row + 2

         ELSE
            Scroll( 11, column[ 1 ], 22, M->pos_r - 1, 2 )

            @ 11, M->pos_r SAY M->more_up

            IF ! Empty( k_relate[ M->c_el ] )
               disp_relation( 21, M->c_el, color7 )

            ENDIF

            IF M->c_el < Len( M->k_relate )

               IF Empty( k_relate[ M->c_el + 1 ] )
                  @ 22, M->pos_r SAY " "

               ENDIF

            ELSE
               @ 22, M->pos_r SAY " "

            ENDIF
         ENDIF

         keystroke := 0

      OTHERWISE

         IF ! key_ready()
            disp_relation( M->c_row, M->c_el, cHilite )

            SetColor( M->cHilite )
            @ M->c_row, column[ 1 ] + 2 ;
               SAY if( Empty( k_relate[ M->c_el ] ), " ", "" )
            SetColor( M->cNorm )

            read_key()

            disp_relation( M->c_row, M->c_el, cNorm )

            @ M->c_row, column[ 1 ] + 2 SAY ""

         ENDIF
      ENDCASE
   ENDDO

   RestScreen( 8, column[ 1 ] - 1, 23, M->pos_r + 1, M->rel_buff )

   help_code := M->old_help

   box_open := .F.

   keystroke := 0
   SetColor( saveColor )

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function draw_relat()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION draw_relat

   PARAMETERS start_el
   PRIVATE i

   Scroll( 11, column[ 1 ], 22, M->pos_r, 0 )

   i := 0

   DO WHILE M->i < 6 .AND. M->start_el + M->i <= Len( M->k_relate )

      IF Empty( k_relate[ M->start_el + M->i ] )
         EXIT

      ENDIF

      disp_relation( 11 + ( 2 * M->i ), M->start_el + M->i, color7 )

      i := M->i + 1

   ENDDO

   IF M->start_el > 1
      @ 11, M->pos_r SAY M->more_up

   ENDIF

   IF M->start_el + M->i <= Len( M->k_relate )

      IF ! Empty( k_relate[ M->start_el + M->i ] )
         @ 22, M->pos_r SAY M->more_down

      ENDIF
   ENDIF

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function get_relation()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION get_relation

   PARAMETERS row_n, element

   PRIVATE stroke
   PRIVATE k_input
   PRIVATE k_trim
   PRIVATE s_alias
   PRIVATE t_alias
   PRIVATE i
   PRIVATE j
   PRIVATE q
   PRIVATE pos_c
   PRIVATE ntx_expr
   PRIVATE k_type
   PRIVATE ok

   IF isdata( M->keystroke )
      i := c_search( Upper( Chr( M->keystroke ) ), M->dbf, 0, afull( M->dbf ) )

      IF SubStr( dbf[ M->i ], 1, 1 ) = Upper( Chr( M->keystroke ) )
         KEYBOARD Chr( 13 )

      ENDIF

   ELSE

      IF Empty( k_relate[ M->element ] )
         i := 1

      ELSE
         i := Asc( s_relate[ M->element ] ) - Asc( "A" ) + 1

      ENDIF
   ENDIF

   j      := 0
   stroke := 0

   DO WHILE !( M->j > 0 .AND. M->stroke = 13 )

      DO CASE

      CASE M->stroke = 13

         IF M->i < 6

            IF ! Empty( dbf[ M->i + 1 ] )

               IF ! Empty( k_relate[ M->element ] )
                  j := Asc( t_relate[ M->element ] ) - Asc( "A" ) + 1

               ENDIF

               IF M->j <= M->i
                  j := M->i + 1

               ENDIF
            ENDIF
         ENDIF

         stroke := 0

      CASE M->stroke = 4

         IF M->j = 0 .AND. M->i < 6

            IF ! Empty( dbf[ M->i + 1 ] )
               i := M->i + 1

            ENDIF

         ELSE

            IF M->j > 0 .AND. M->j < 6

               IF ! Empty( dbf[ M->j + 1 ] )
                  j := M->j + 1

               ENDIF
            ENDIF
         ENDIF

         stroke := 0

      CASE M->stroke = 19

         IF M->j = 0 .AND. M->i > 1
            i := M->i - 1

         ELSE

            IF M->j > 0
               j := M->j - 1

               IF M->j = M->i
                  j := 0

               ENDIF
            ENDIF
         ENDIF

         stroke := 0

      CASE isdata( M->stroke )
         q := c_search( Upper( Chr( M->stroke ) ), M->dbf, M->i, afull( M->dbf ) )

         IF SubStr( dbf[ M->q ], 1, 1 ) = Upper( Chr( M->stroke ) )

            IF M->j = 0
               i := M->q
               KEYBOARD Chr( 13 )

            ELSE

               IF M->q > M->i
                  j := M->q
                  KEYBOARD Chr( 13 )

               ELSE
                  j := 0
                  i := M->q

               ENDIF
            ENDIF
         ENDIF

         stroke := 0

      CASE M->stroke = 27
         @ M->row_n, column[ 1 ] SAY Space( M->width )
         RETURN 0

      OTHERWISE

         IF M->j = 0
            @ M->row_n, column[ 1 ] SAY Space( M->width )

            s_alias := name( dbf[ M->i ] )

            SetColor( M->color12 )
            @ M->row_n, column[ M->i ] + 2 SAY M->s_alias
            SetColor( M->cNorm )

         ELSE
            t_alias := name( dbf[ M->j ] )

            pos_c := column[ M->i ] + 2 + Len( M->s_alias )

            @ M->row_n, M->pos_c SAY Space( M->pos_r - M->pos_c )

            @ M->row_n, M->pos_c ;
               SAY Replicate( "-", column[ M->j ] - M->pos_c + 1 ) + Chr( 16 )

            SetColor( M->color12 )
            ?? t_alias
            SetColor( M->cNorm )

         ENDIF

         stroke := raw_key()

      ENDCASE
   ENDDO

   SetColor( M->cHilite )
   @ M->row_n, column[ M->i ] + 2 SAY M->s_alias
   @ M->row_n, column[ M->j ] + 2 SAY M->t_alias
   SetColor( M->cNorm )

   SELECT ( M->j )
   ntx_expr := ctrl_key()

   IF Empty( M->ntx_expr )
      k_type := "N"

   ELSE
      k_type := Type( M->ntx_expr )

   ENDIF

   SELECT ( M->i )

   k_trim := k_relate[ M->element ]
   ok     := .F.

   DO WHILE ! M->ok
      k_trim := enter_rc( M->k_trim, M->row_n + 1, column[ M->i ] + 2, ;
         127, "@KS" + LTrim( Str( M->pos_r - column[ M->i ] - 2 ) ), ;
         M->color1 )

      ok := Empty( M->k_trim ) .OR. Type( M->k_trim ) = M->k_type

      IF ! M->ok
         error_msg( "Express„o Invalida" )

      ENDIF
   ENDDO

   @ M->row_n + 1, column[ 1 ] SAY Space( M->width )

   IF Empty( M->k_trim )
      RETURN 0

   ENDIF

   need_relat := .T.

   k_relate[ M->element ] = M->k_trim
   s_relate[ M->element ] = Chr( M->i + Asc( "A" ) - 1 ) + M->s_alias
   t_relate[ M->element ] = Chr( M->j + Asc( "A" ) - 1 ) + M->t_alias

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function disp_relation()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION disp_relation

   PARAMETERS disp_row, element, cSpecial
   PRIVATE j
   PRIVATE k

   IF Empty( k_relate[ M->element ] )
      @ M->disp_row, column[ 1 ]   SAY Space( M->width )
      @ M->disp_row + 1, column[ 1 ] SAY Space( M->width )
      RETURN 0

   ENDIF

   j := Asc( s_relate[ M->element ] ) - Asc( "A" ) + 1
   k := Asc( t_relate[ M->element ] ) - Asc( "A" ) + 1

   SetColor( M->cSpecial )
   @ M->disp_row, column[ M->j ] + 2 SAY SubStr( s_relate[ M->element ], 2 )
   SetColor( M->cNorm )

   ?? Replicate( "-", column[ M->k ] - Col() + 1 ) + Chr( 16 )

   SetColor( M->cSpecial )
   ?? SubStr( t_relate[ M->element ], 2 )
   SetColor( M->cNorm )

   @ M->disp_row + 1, column[ M->j ] + 2 ;
      SAY Pad( k_relate[ M->element ], M->pos_r - column[ M->j ] - 2 )

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function c_search()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION c_search

   PARAMETERS c, array, cur_el, num_d
   PRIVATE chr_el

   chr_el := M->cur_el + 1

   DO WHILE M->chr_el <= M->num_d

      IF Upper( SubStr( array[ M->chr_el ], 1, 1 ) ) = Upper( M->c )
         EXIT

      ENDIF

      chr_el := M->chr_el + 1

   ENDDO

   IF M->chr_el > M->num_d
      chr_el := 1

      DO WHILE M->chr_el < M->cur_el .AND. ;
            Upper( SubStr( array[ M->chr_el ], 1, 1 ) ) <> Upper( M->c )

         chr_el := M->chr_el + 1

      ENDDO
   ENDIF

   RETURN M->chr_el


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function ctrl_key()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION ctrl_key

   PRIVATE KEY
   PRIVATE ntx

   IF M->need_ntx
      ntx := "ntx" + LTrim( Str( Select() ) )

      KEY := ntx_key( &ntx[ 1 ] )

   ELSE
      KEY := IndexKey( 0 )

   ENDIF

   RETURN M->key


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function get_filter()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION get_filter

   PRIVATE k_filter
   PRIVATE k_trim
   PRIVATE old_help

   old_help  := M->help_code
   help_code := 7

   k_filter := "kf" + SubStr( "123456", M->cur_area, 1 )
   k_trim   := &k_filter

   SELECT ( M->cur_area )

   hi_cur()

   DECLARE boxarray[ 4 ]

   boxarray[ 1 ] = "fltr_title(sysparam)"
   boxarray[ 2 ] = "getfilter(sysparam)"
   boxarray[ 3 ] = "ok_button(sysparam)"
   boxarray[ 4 ] = "can_button(sysparam)"

   okee_dokee := "do_filter()"

   multibox( 7, 17, 5, 2, M->boxarray )

   help_code := M->old_help

   dehi_cur()

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function fltr_title()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION fltr_title

   PARAMETERS sysparam

   RETURN box_title( M->sysparam, "Setar filtro para " + ;
      SubStr( M->cur_dbf, RAt( hb_ps(), M->cur_dbf ) + 1 ) + ;
      " para..." )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function getfilter()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION getfilter

   PARAMETERS sysparam

   RETURN get_k_trim( M->sysparam, "Condi‡„o" )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function do_filter()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION do_filter

   PRIVATE done
   PRIVATE k_sample

   IF Empty( M->k_trim )
      done := .T.

      IF ! Empty( &k_filter )
         SET FILTER TO

         &k_filter := ""

      ENDIF

   ELSE

      IF Type( M->k_trim ) = "L"
         done := .T.

         IF !( &k_filter == M->k_trim )
            need_filtr := .T.
            &k_filter  := M->k_trim

         ENDIF

      ELSE
         done := .F.
         error_msg( "Filtro precisa ser uma express„o l¢gica" )

      ENDIF
   ENDIF

   RETURN M->done


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function clear_dbf()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION clear_dbf

   PARAMETERS work_area, shift
   PRIVATE s_alias
   PRIVATE c_area
   PRIVATE TEMP
   PRIVATE xtemp
   PRIVATE i
   PRIVATE file_name
   PRIVATE alias_6
   PRIVATE n_active

   n_active := afull( M->dbf )

   s_alias := name( dbf[ M->work_area ] )

   alias_6 := ""

   TEMP := "ntx" + SubStr( "123456", M->work_area, 1 )

   DO CASE

   CASE M->shift = 0
      dbf[ M->work_area ] = ""

      n_files := M->n_files - afull( &temp ) - 1

   CASE M->shift = 1

      IF ! Empty( dbf[ 6 ] )
         alias_6 := name( dbf[ 6 ] )

         n_files := M->n_files - afull( M->ntx6 ) - 1

      ENDIF

      shift := if( Empty( dbf[ M->work_area ] ) .OR. M->work_area = 6, 0, 1 )

      array_ins( M->dbf, M->work_area )

   CASE M->shift = 2
      array_del( M->dbf, M->work_area )

      shift := if( Empty( dbf[ M->work_area ] ), 0, 2 )

      n_files := M->n_files - afull( &temp ) - 1

   ENDCASE

   i := 1

   DO WHILE M->i <= M->n_active
      c_area := Chr( M->i + Asc( "A" ) - 1 )
      SELECT ( M->i )

      IF M->i = M->work_area .OR. ( M->i > M->work_area .AND. M->shift <> 0 )
         dbCloseArea()

      ENDIF

      TEMP := "kf" + SubStr( "123456", M->i, 1 )

      IF ( ( ( M->s_alias + "->" $ Upper( &temp ) ) .OR. ;
            ( M->i = M->work_area .AND. ! Empty( &temp ) ) ) ;
            .AND. M->shift <> 1 ) .OR. ( ! Empty( M->alias_6 ) .AND. ;
            M->alias_6 + "->" $ Upper( &temp ) .AND. M->shift = 1 )

         SET FILTER TO

         need_filtr := .T.

         &TEMP := ""

      ENDIF

      i := M->i + 1

   ENDDO

   DO CASE

   CASE M->shift = 0
      TEMP := "ntx" + SubStr( "123456", M->work_area, 1 )
      AFill( &temp, "" )

      TEMP := "field_n" + SubStr( "123456", M->work_area, 1 )
      AFill( &temp, "" )

      TEMP  := "kf" + SubStr( "123456", M->work_area, 1 )
      &TEMP := ""

   CASE M->shift = 1
      need_filtr := .T.
      need_ntx   := .T.

      i := 6

      DO WHILE Empty( dbf[ M->i ] )
         i := M->i - 1

      ENDDO

      DO WHILE M->i > M->work_area
         TEMP  := "ntx" + SubStr( "123456", M->i, 1 )
         xtemp := "ntx" + SubStr( "123456", M->i - 1, 1 )
         ACopy( &xtemp, &temp )

         TEMP  := "field_n" + SubStr( "123456", M->i, 1 )
         xtemp := "field_n" + SubStr( "123456", M->i - 1, 1 )
         ACopy( &xtemp, &temp )

         TEMP  := "cr" + SubStr( "123456", M->i, 1 )
         xtemp := "cr" + SubStr( "123456", M->i - 1, 1 )
         ACopy( &xtemp, &temp )

         TEMP  := "el" + SubStr( "123456", M->i, 1 )
         xtemp := "el" + SubStr( "123456", M->i - 1, 1 )
         ACopy( &xtemp, &temp )

         TEMP  := "kf" + SubStr( "123456", M->i, 1 )
         xtemp := "kf" + SubStr( "123456", M->i - 1, 1 )
         &TEMP := &xtemp

         i := M->i - 1

      ENDDO

      xtemp := SubStr( "123456", M->i, 1 )

      TEMP := "ntx" + xtemp
      AFill( &temp, "" )

      TEMP := "field_n" + xtemp
      AFill( &temp, "" )

      TEMP  := "kf" + xtemp
      &TEMP := ""

      TEMP := "cr" + xtemp
      &TEMP[ 2 ] = row_a[ 2 ]
      &TEMP[ 3 ] = row_a[ 3 ]

      TEMP := "el" + xtemp
      AFill( &temp, 1 )

   CASE M->shift = 2
      need_filtr := .T.
      need_ntx   := .T.

      i := M->work_area

      DO WHILE M->i < 6 .AND. ! Empty( dbf[ M->i ] )
         TEMP  := "ntx" + SubStr( "123456", M->i, 1 )
         xtemp := "ntx" + SubStr( "123456", M->i + 1, 1 )
         ACopy( &xtemp, &temp )

         TEMP  := "field_n" + SubStr( "123456", M->i, 1 )
         xtemp := "field_n" + SubStr( "123456", M->i + 1, 1 )
         ACopy( &xtemp, &temp )

         TEMP  := "cr" + SubStr( "123456", M->i, 1 )
         xtemp := "cr" + SubStr( "123456", M->i + 1, 1 )
         ACopy( &xtemp, &temp )

         TEMP  := "el" + SubStr( "123456", M->i, 1 )
         xtemp := "el" + SubStr( "123456", M->i + 1, 1 )
         ACopy( &xtemp, &temp )

         TEMP  := "kf" + SubStr( "123456", M->i, 1 )
         xtemp := "kf" + SubStr( "123456", M->i + 1, 1 )
         &TEMP := &xtemp

         i := M->i + 1

      ENDDO

      xtemp := SubStr( "123456", M->i, 1 )

      TEMP := "ntx" + M->xtemp
      AFill( &temp, "" )

      TEMP := "field_n" + M->xtemp
      AFill( &temp, "" )

      TEMP  := "kf" + M->xtemp
      &TEMP := ""

      TEMP := "cr" + M->xtemp
      &TEMP[ 2 ] = row_a[ 2 ]
      &TEMP[ 3 ] = row_a[ 3 ]

      TEMP := "el" + M->xtemp
      AFill( &temp, 1 )

   ENDCASE

   need_field := .T.

   c_area := Chr( M->work_area + Asc( "A" ) - 1 )

   i := 1

   DO WHILE M->i <= Len( M->k_relate )

      IF Empty( k_relate[ M->i ] )
         EXIT

      ENDIF

      IF ( ( SubStr( s_relate[ M->i ], 1, 1 ) = M->c_area .OR. ;
            SubStr( t_relate[ M->i ], 1, 1 ) = M->c_area ) .AND. M->shift <> 1 ) .OR. ;
            ( M->shift = 1 .AND. SubStr( t_relate[ M->i ], 1, 1 ) = "F" )

         array_del( M->s_relate, M->i )
         array_del( M->k_relate, M->i )
         array_del( M->t_relate, M->i )
         need_relat := .T.

      ELSE

         IF ( M->shift = 2 .AND. SubStr( s_relate[ M->i ], 1, 1 ) > M->c_area ) .OR. ;
               ( M->shift = 1 .AND. SubStr( s_relate[ M->i ], 1, 1 ) >= M->c_area )

            s_relate[ M->i ] = Chr( Asc( SubStr( s_relate[ M->i ], 1, 1 ) ) + ;
               IF ( M->shift = 1, 1, - 1 ) ) + ;
               SubStr( s_relate[ M->i ], 2 )
            need_relat := .T.

         ENDIF

         IF ( M->shift = 2 .AND. SubStr( t_relate[ M->i ], 1, 1 ) > M->c_area ) .OR. ;
               ( M->shift = 1 .AND. SubStr( t_relate[ M->i ], 1, 1 ) >= M->c_area )

            t_relate[ M->i ] = Chr( Asc( SubStr( t_relate[ M->i ], 1, 1 ) ) + ;
               IF ( M->shift = 1, 1, - 1 ) ) + ;
               SubStr( t_relate[ M->i ], 2 )
            need_relat := .T.

         ENDIF

         i := M->i + 1

      ENDIF
   ENDDO

   IF M->shift <> 0
      i := 6

      DO WHILE M->i >= M->work_area

         IF ! Empty( dbf[ M->i ] )
            c_area := Chr( M->i + Asc( "A" ) - 1 )
            SELECT ( M->i )
            file_name := dbf[ M->i ]
            DBUREDE( file_name,, ABERTURA )

         ENDIF

         i := M->i - 1

      ENDDO
   ENDIF

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function save_view()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION save_view

   PRIVATE filename
   PRIVATE old_help

   old_help  := M->help_code
   help_code := 21

   IF Empty( M->view_file ) .AND. ! Empty( dbf[ 1 ] )
      filename := name( dbf[ 1 ] ) + ".vew"

   ELSE
      filename := M->view_file

   ENDIF

   filebox( ".vew", "vew_list", "vcrea_titl", "do_creavew", .T., 8 )

   help_code := M->old_help

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function vcrea_titl()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION vcrea_titl

   PARAMETERS sysparam

   RETURN box_title( M->sysparam, "Salvando Vis„o como..." )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function do_creavew()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION do_creavew

   PRIVATE i
   PRIVATE j
   PRIVATE k
   PRIVATE m_name
   PRIVATE l_name
   PRIVATE add_name

   IF Empty( M->filename )
      error_msg( "Arquivo de vis„o n„o selecionado" )
      RETURN .F.

   ENDIF

   SELECT 10

   stat_msg( "Criando arquivo de Vis„o" )

   add_name := ! hb_FileExists( name( filename ) + ".vew" )

   CREATE ddbbuuuu

   netrecapp()
   field->field_name := "ITEM_NAME"
   field->field_type := "C"
   field->field_len  := 10
   dbUnlock()

   netrecapp()
   field->field_name := "CONTENTS"
   field->field_type := "C"
   field->field_len  := 10
   dbUnlock()

   dbCloseArea()
   CREATE &filename FROM ddbbuuuu

   view_file := M->filename

   DBUREDE( view_file, "ddbbuuuu", ABERTURA )

   FErase( "ddbbuuuu."+TABLEEXT )

   netrecapp()
   field->item_name := "cur_dir"
   dbUnlock()
   put_line( cur_dir )

   netrecapp()
   field->item_name := "n_files"
   dbUnlock()
   put_line( LTrim( Str( n_files ) ) )

   i := 1

   DO WHILE i <= 6

      IF Empty( dbf[ i ] )
         EXIT

      ENDIF

      m_name := "kf" + SubStr( "123456", i, 1 )

      IF ! Empty( &m_name )
         netrecapp()
         field->item_name := m_name
         dbUnlock()
         put_line( &m_name )

      ENDIF

      i++

   ENDDO

   i := 1

   DO WHILE i <= 6

      IF Empty( dbf[ i ] )
         EXIT

      ENDIF

      netrecapp()
      field->item_name := "dbf"
      dbUnlock()
      put_line( dbf[ i ] )

      i++

   ENDDO

   l_name := "ntx"

   FOR k := 1 TO 2
      i := 1

      DO WHILE i <= 6

         IF Empty( dbf[ i ] )
            EXIT

         ENDIF

         m_name := l_name + SubStr( "123456", i, 1 )

         j := 1

         DO WHILE j <= Len( &m_name )

            IF Empty( &m_name[ j ] )
               EXIT

            ENDIF


            netrecapp()
            field->item_name := m_name
            dbUnlock()
            put_line( &m_name[ j ] )

            j++

         ENDDO

         i++

      ENDDO

      l_name := "field_n"

   NEXT

   i := 1

   DO WHILE i <= 3
      m_name := SubStr( "skt", i, 1 ) + "_relate"
      j      := 1

      DO WHILE j <= Len( &m_name )

         IF Empty( &m_name[ j ] )
            EXIT

         ENDIF

         netrecapp()
         field->item_name := m_name
         dbUnlock()
         put_line( &m_name[ j ] )

         j++

      ENDDO

      i++

   ENDDO

   dbCloseArea()

   IF At( ".vew", filename ) = Len( filename ) - 3 .AND. ;
         hb_FileExists( name( filename ) + ".vew" ) .AND. add_name

      i := afull( vew_list ) + 1

      IF i <= Len( vew_list )
         vew_list[ i ] = filename

         array_sort( vew_list )

      ENDIF
   ENDIF

   stat_msg( "" )

   RETURN .T.


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function put_line()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION put_line

   PARAMETERS line
   PRIVATE pos

   netreclock()
   field->contents := line
   dbUnlock()

   pos := Len( contents ) + 1

   DO WHILE pos <= Len( line )
      netrecapp()
      field->contents := SubStr( line, pos )
      dbUnlock()

      pos += Len( contents )

   ENDDO

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function set_from()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION set_from

   PARAMETERS from_view
   PRIVATE filename
   PRIVATE old_help

   old_help  := M->help_code
   help_code := 21

   filename := M->view_file

   IF M->from_view

      IF filebox( ".vew", "vew_list", "vopen_titl", "do_openvew", .F., 8 ) <> 0
         keystroke := 13

      ENDIF

   ELSE
      do_openvew()

   ENDIF

   help_code := M->old_help

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function vopen_titl()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION vopen_titl

   PARAMETERS sysparam

   RETURN box_title( M->sysparam, "Relendo Vis„o de..." )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function do_openvew()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION do_openvew

   PRIVATE m_name
   PRIVATE i
   PRIVATE done

   DO CASE

   CASE Empty( M->filename )
      error_msg( "Vis„o n„o selecionado" )
      done := .F.

   CASE ! hb_FileExists( M->filename )
      error_msg( "N„o Pude Abrir " + M->filename )
      done := .F.

   OTHERWISE
      SELECT 10

      DBUREDE( filename, "ddbbuuuu", ABERTURA )

      IF !( Type( "item_name" ) = "C" .AND. Type( "contents" ) = "C" )
         dbCloseArea()
         error_msg( "Invalido arquivo de vis„o" )
         RETURN .F.

      ENDIF

      view_file := M->filename

      need_field := need_ntx := need_relat := need_filtr := .T.
      stat_msg( "Restaurando Vis„o" )

      i := 6

      DO WHILE M->i > 0

         IF ! Empty( dbf[ M->i ] )
            clear_dbf( M->i, 0 )

         ENDIF

         i := M->i - 1

      ENDDO

      SELECT 10

      cur_dir := get_line()
      n_files := Val( get_line() )

      IF Trim( item_name ) == "k_filter"
         netreclock()
         field->item_name := "kf1"
         dbUnlock()
         kf1 := get_line()

      ELSE

         DO WHILE SubStr( item_name, 1, 2 ) == "kf"
            m_name := Trim( item_name )

            &m_name := get_line()

         ENDDO
      ENDIF

      DO WHILE ! Eof()
         m_name := Trim( item_name )
         i      := 1

         DO WHILE Trim( item_name ) == m_name
            &m_name[ i ] = get_line()

            i++

         ENDDO
      ENDDO

      dbCloseArea()

      i := 1

      DO WHILE M->i <= 6

         IF Empty( dbf[ M->i ] )
            EXIT

         ENDIF

         SELECT ( M->i )

         filename := dbf[ M->i ]
         DBUREDE( filename,, ABERTURA )

         i := M->i + 1

      ENDDO

      stat_msg( "" )
      done := .T.

   ENDCASE

   RETURN M->done


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function get_line()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION get_line

   PRIVATE line

   line := Trim( contents )
   SKIP

   DO WHILE Len( Trim( item_name ) ) = 0 .AND. ! Eof()
      line += Trim( contents )
      SKIP

   ENDDO

   RETURN line




// + EOF: dbuview.prg
// +
