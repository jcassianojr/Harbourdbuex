// +--------------------------------------------------------------------
// +
// +
// +
// +    Programa  : dbustru.prg
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
// +    Function modi_stru()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION modi_stru

   LOCAL saveColor
   PRIVATE filename
   PRIVATE fill_row
   PRIVATE cur_row
   PRIVATE rec1
   PRIVATE m_item
   PRIVATE i
   PRIVATE n
   PRIVATE f_name
   PRIVATE f_type
   PRIVATE f_len
   PRIVATE f_dec
   PRIVATE prev_rec
   PRIVATE field_id
   PRIVATE stru_ok
   PRIVATE is_insert
   PRIVATE is_append
   PRIVATE altered
   PRIVATE type_n
   PRIVATE empty_row
   PRIVATE not_empty
   PRIVATE old_help
   PRIVATE chg_name
   PRIVATE len_temp
   PRIVATE stru_name
   PRIVATE wstru_buff
   PRIVATE temparq

   old_help  := help_code
   saveColor := SetColor( M->color7 )

   wstru_buff := SaveScreen( 8, 20, 23, 59 )

   DECLARE ffield[ 4 ]
   DECLARE field_col[ 4 ]
   DECLARE data_type[ 23 ]
   DECLARE l_usr[ 23 ]



   ffield[ 1 ] = "field_name"
   ffield[ 2 ] = "field_type"
   ffield[ 3 ] = "field_len"
   ffield[ 4 ] = "field_dec"

   field_col[ 1 ] = 22
   field_col[ 2 ] = 35
   field_col[ 3 ] = 48
   field_col[ 4 ] = 55



// define HB_FT_NONE            0
   data_type[ 1 ] = "Caracter "  // HB_FT_STRING           1      "C"  //
   data_type[ 2 ] = "Numerico "  // HB_FT_LONG             4      "N"   //
   data_type[ 3 ] = "Data     "  // HB_FT_DATE             3      "D"   //
   data_type[ 4 ] = "Logico   "  // HB_FT_LOGICAL          2      "L"  //
   data_type[ 5 ] = "Memoria  "  // HB_FT_MEMO            16      "M"  //
   data_type[ 6 ] = "BLOB     "  // HB_FT_BLOB            19      "W"
   data_type[ 7 ] = "Image    "  // HB_FT_IMAGE           18      "P"
   data_type[ 8 ] = "OLE      "  // HB_FT_OLE             20      "G"
   data_type[ 9 ] = "VarLength"  // HB_FT_VARLENGTH       15      "Q"
   data_type[ 10 ] = "Any      "   // HB_FT_ANY             17      "V"
   data_type[ 11 ] = "Float    "   // HB_FT_FLOAT            5      "F"
   data_type[ 12 ] = "Double   "   // 8
   data_type[ 13 ] = "Double   "   // B  HB_FT_DOUBLE        7      "B"
   data_type[ 14 ] = "CurDouble"   // HB_FT_CURDOUBLE       14      "Z"  //
   data_type[ 15 ] = "Currency "   // HB_FT_CURRENCY        13      "Y"   //
   data_type[ 16 ] = "Integer  "   // HB_FT_INTEGER  VV      6      "I"
   data_type[ 17 ] = "Integer  "   // 2 INT2
   data_type[ 18 ] = "Integer  "   // 4  INT4
   data_type[ 19 ] = "Autoinc  "   // HB_FT_AUTOINC         12      "+"
   data_type[ 20 ] = "Modtime  "   // HB_FT_MODTIME         10      "="
   data_type[ 21 ] = "Rowver   "   // HB_FT_ROWVER          11      "^"
   data_type[ 22 ] = "Timestamp"   // HB_FT_TIMESTAMP        9      "@"
   data_type[ 23 ] = "Time/stmp"   // HB_FT_TIME             8      "T"


   l_usr[ 1 ] = 3  // C character - variable len
   l_usr[ 2 ] = 4  // N numeric - variable len and dec
   l_usr[ 3 ] = 3  // D Date - fixed len - 3, 4 or 8
   l_usr[ 4 ] = 2  // L logical - fixed len - 1
   l_usr[ 5 ] = 3  // M memo - fixed len - 10 or 4
   l_usr[ 6 ] = 3  // "W" - fixed len - 10 or 4
   l_usr[ 7 ] = 3  // "P" - fixed len - 10 or 4
   l_usr[ 8 ] = 3  // "G" - fixed len - 10 or 4
   l_usr[ 9 ] = 3  // "Q" - variable len
   l_usr[ 10 ] = 3   // "V" len 4 or 6 or above dec 0
   l_usr[ 11 ] = 4   // "F" like "N"
   l_usr[ 12 ] = 4   // "8" len 8
   l_usr[ 13 ] = 4   // "B" len 8
   l_usr[ 14 ] = 4   // "Z" len 8
   l_usr[ 15 ] = 2   // "Y" len 8, dec 4
   l_usr[ 16 ] = 4   // "I" len 1-4 or 8, default 4
   l_usr[ 17 ] = 2   // "2" len 2 dec 0
   l_usr[ 18 ] = 2   // "4" len 4 dec 0
   l_usr[ 19 ] = 2   // "+" len 4 dec 0
   l_usr[ 20 ] = 2   // "=" len 8 dec 0
   l_usr[ 21 ] = 2   // "^" len 8 dec 0
   l_usr[ 22 ] = 2   // "@" len 8 dec 0
   l_usr[ 23 ] = 3   // "T" len 4 or 8 dec 0



   type_n    := 1
   altered   := .F.
   chg_name  := .T.
   prev_rec  := 0
   n         := 1
   i         := 0
   cur_row   := 13
   is_insert := .F.
   keystroke := 999
   filename  := ""

   empty_row := "           |           |       |    "
   not_empty := "           | Caracter  |    10 |    "

   IF ! Empty( M->cur_dbf )

      stat_msg( "Lendo Estrutura do Arquivo" )
      stru_name := M->cur_dbf
      temparq   := trocaext( stru_name, "_stru."+TABLEEXT )

      SELECT ( M->cur_area )

      __dbCopyXStruct( temparq )   // COPY to &temparq STRUCTURE EXTENDED

      SELECT 10
      DBUREDE( temparq )
      stru_ok   := .T.
      is_append := .F.

      stat_msg( "" )

   ELSE


      stru_name := WIN_GETSAVEFILENAME(, "Novo Arquivo", hb_cwd(), "dbf", "*.txt", 1,, "novoarquivo."+TABLEEXT )
      temparq   := trocaext( stru_name, "_stru."+TABLEEXT )

      SELECT 10
      // __dbCreate( temparq,,, .F., ) //CREATE &temparq
      dbCreate( temparq )

      netrecapp()
      field->field_type := "C"
      field->field_len  := 10
      field->field_dec  := 0

      stru_ok   := .F.
      is_append := .T.
      // stru_name := "" zera para pegar abaixo o novo no nome mas feito aqui pelo win_getsavefilename

   ENDIF

   Scroll( 8, 20, 23, 59, 0 )
   hb_DispBox( 8, 20, 23, 59, M->frame )

   @  9, field_col[ 1 ] ;
      SAY "Estrutura de " + Pad( if( Empty( stru_name ), "<novo arquivo>", ;
      SubStr( stru_name, RAt( hb_ps(), stru_name ) + 1 ) ), 13 )

   @ 11, 20 SAY " Nome Campo   Tipo        Tamanho  Dec"
   @ 12, 20 SAY "|------------|-----------|-------|-----|"
   @ 23, 33 SAY "|-----------|-------|"

   DO WHILE ! q_check()

      DO CASE

      CASE keystroke = 999
         Scroll( 13, 21, 22, 58, 0 )
         rec1     := RecNo()
         fill_row := 13

         DO WHILE ! Eof() .AND. fill_row <= 22
            stru_row( fill_row )

            SKIP
            fill_row++

         ENDDO

         DO WHILE fill_row <= 22
            @ fill_row, field_col[ 1 ] SAY empty_row
            fill_row++

         ENDDO

         GOTO rec1
         fill_row := 13

         DO WHILE fill_row < cur_row
            SKIP

            IF Eof()
               cur_row := fill_row
               GO BOTTOM
               EXIT

            ENDIF

            fill_row++

         ENDDO

         keystroke := 0

      CASE keystroke = 13 .OR. isdata( keystroke )

         IF n = 2
            type_n := At( Left( field_type, 1 ), "CNDLMWPGQVF8BZYI24+=^@T" )
            // type_n := at( field_type, "CNDLM" )

         ELSE
            SET CURSOR ON

            IF keystroke <> 13
               KEYBOARD Chr( keystroke )

            ENDIF
         ENDIF

         field_id := ffield[ n ]

         m_item := &field_id

         SET KEY 5 TO clear_gets
         SET KEY 24 TO clear_gets
         xkey_clear()

         DO CASE

         CASE n = 1
            SetColor( M->color1 )
            @ cur_row, field_col[ 1 ] GET field_name PICTURE "@!K"
            READDBU()
            SetColor( M->color7 )
            keystroke := LastKey()

         CASE n = 2

            DO CASE

            CASE Upper( Chr( keystroke ) ) $ "CNDLMWPGQVF8BZYI24+=^@T"
               // case upper( chr( keystroke ) ) $ "CNDLM"
               // type_n    := at( upper( chr( keystroke ) ), "CNDLM" )
               type_n    := At( Upper( Chr( keystroke ) ), "CNDLMWPGQVF8BZYI24+=^@T" )
               keystroke := 13

            CASE keystroke = 32
               type_n := if( type_n = 5, 1, type_n + 1 )

            CASE keystroke <> 13
               keystroke := 0

            ENDCASE

            IF m_item <> SubStr( "CNDLMWPGQVF8BZYI24+=^@T", type_n, 1 )
               // if m_item <> substr( "CNDLM", type_n, 1 )
               // REPLACE field_type WITH SUBSTR("CNDLMWPGQVF8BZYI24+=^@T", type_n, 1)
               field->field_type := SubStr( "CNDLMWPGQVF8BZYI24+=^@T", type_n, 1 )
               // field->field_type := substr( "CNDLM", type_n, 1 )

               DO CASE

               CASE field_type = "C"
                  field->field_dec := 0

               CASE field_type = "Q"
                  IF field_len > 255
                     field->field_len := 255
                  ELSEIF field_len = 0
                     field->field_len := 1
                  ENDIF
                  REPLACE field_dec WITH 0

               CASE field_type = "V"
                  IF field_len <> 4 .AND. field_len < 6
                     field->field_len := 6
                  ENDIF
                  field->field_dec := 0


               CASE field_type $ "NF"
                  // numeric
                  IF m_item = "C" .AND. ( field_dec <> 0 .OR. field_len > 19 )
                     field->field_len := 10
                     field->field_dec := 0
                  ENDIF

               CASE field_type = "I"
                  IF field_len = 0 .OR. ( field_len > 4 .AND. field_len <> 8 )
                     field->field_len := 4
                  ENDIF

               CASE field_type = "Y"
                  field->field_len := 8
                  field->field_dec := 4



               CASE field_type $ "8BZ"
                  IF field_len <> 8
                     field->field_len := 8

                  ENDIF

               CASE field_type = "2"

                  field->field_len := 2
                  field->field_dec := 0



               CASE field_type = "4"
                  field->field_len := 4
                  field->field_dec := 0



               CASE field_type = "T"
                  IF field_len <> 4 .AND. field_len <> 8
                     field->field_len := 8
                  ENDIF
                  field->field_dec := 0


               CASE field_type = "@"
                  field->field_len := 8
                  field->field_dec := 0



               CASE field_type = "D"
                  IF field_len <> 3 .AND. field_len <> 4 .AND. field_len <> 8
                     field->field_len := 8
                  ENDIF
                  field->field_dec := 0


               CASE field_type = "L"
                  field->field_len := 1
                  field->field_dec := 0

               CASE field_type $ "MVWPG"
                  IF field_len <> 10 .AND. field_len <> 4
                     field->field_len := 10

                  ENDIF
                  field->field_dec := 0


               CASE field_type = "+"
                  field->field_len := 4
                  field->field_dec := 0

               CASE field_type $ "=^"
                  field->field_len := 8
                  field->field_dec := 0


               ENDCASE

               @ cur_row, field_col[ 3 ] SAY Str( field_len, 4 )

               IF field_type $ "NFYI8BZ"   // if field_type = "N"
                  @ cur_row, field_col[ 4 ] SAY field_dec

               ELSE
                  @ cur_row, field_col[ 4 ] SAY "   "

               ENDIF
            ENDIF NEW TYPE

         CASE n = 3

            IF field_type = "C"
               len_temp := ( 256 * field_dec ) + field_len

            ELSE
               len_temp := field_len

            ENDIF

            SetColor( M->color1 )
            @ cur_row, field_col[ n ] GET len_temp PICTURE "9999"
            READDBU()
            SetColor( M->color7 )
            keystroke := LastKey()

            IF menu_key() = 0

               IF field_type = "C"
                  field->field_len := ( len_temp % 256 )
                  field->field_dec := Int( len_temp / 256 )

               ELSE

                  IF len_temp < 256
                     field->field_len := len_temp

                  ELSE
                     keystroke := 0

                  ENDIF
               ENDIF
            ENDIF

         CASE n = 4
            SetColor( M->color1 )
            @ cur_row, field_col[ n ] GET field_dec
            READDBU()
            SetColor( M->color7 )
            keystroke := LastKey()

         ENDCASE

         SET KEY 5 to
         SET KEY 24 to
         xkey_norm()
         SET CURSOR OFF

         IF menu_key() <> 0
            field->&field_id := m_item
            KEYBOARD Chr( keystroke )

         ENDIF

         IF m_item <> &field_id
            stru_ok := .F.
            altered := .T.

            IF n > 1
               chg_name := .F.

            ENDIF
         ENDIF

         DO CASE

         CASE keystroke = 18 .OR. keystroke = 5
            keystroke := 5

         CASE keystroke = 3 .OR. keystroke = 24
            keystroke := 24

         CASE keystroke = 13 .OR. ;
               ( isdata( keystroke ) .AND. keystroke <> 32 )
            keystroke := 4

         OTHERWISE
            keystroke := 0

         ENDCASE

         stru_item()

      CASE keystroke = 5 .AND. RecNo() > 1

         IF is_append

            IF ! stru_ck( .F. )
               no_append()

            ENDIF
         ENDIF

         IF stru_ck( .T. )
            SKIP - 1

            IF cur_row = 13
               Scroll( 13, 21, 22, 58, - 1 )

               stru_row( 13 )

            ELSE
               cur_row--

            ENDIF

            is_append := .F.
            is_insert := .F.

         ELSE
            n := i

         ENDIF

         keystroke := 0

      CASE keystroke = 24

         IF stru_ck( RecNo() < LastRec() )
            SKIP

            IF Eof()
               netrecapp()
               field->field_type := "C"
               field->field_len  := 10
               field->field_dec  := 0
               is_append         := .T.
               stru_ok           := .F.
               n                 := 1

               IF cur_row < 22
                  @ cur_row + 1, field_col[ 1 ] SAY not_empty

               ENDIF

            ELSE
               is_insert := .F.

            ENDIF

            IF cur_row = 22
               Scroll( 13, 21, 22, 58, 1 )

               stru_row( 22 )

            ELSE
               cur_row++

            ENDIF

         ELSE
            n := i

         ENDIF

         keystroke := 0

      CASE keystroke = 4

         IF n < l_usr[ At( Left( field_type, 1 ), "CNDLMWPGQVF8BZYI24+=^@T" ) ]  // if n < l_usr[ at( field_type, "CNDLM" ) ]
            n++

         ENDIF

         keystroke := 0

      CASE keystroke = 19

         IF n > 1
            n--

         ENDIF

         keystroke := 0

      CASE keystroke = 18
         keystroke := 0

         IF RecNo() = 1
            LOOP

         ENDIF

         IF is_append

            IF ! stru_ck( .F. )
               no_append()

            ENDIF
         ENDIF

         IF stru_ck( .T. )
            is_append := .F.
            is_insert := .F.

            IF RecNo() = cur_row - 12
               GO TOP
               cur_row := 13

            ELSE
               SKIP - ( 9 + cur_row - 13 )
               keystroke := 999

            ENDIF

         ELSE
            n := i

         ENDIF

      CASE keystroke = 3
         keystroke := 0

         IF is_append
            LOOP

         ENDIF

         IF stru_ck( .T. )
            is_insert := .F.

            IF LastRec() - RecNo() <= 22 - cur_row
               cur_row += LastRec() - RecNo()
               GO BOTTOM

            ELSE
               keystroke := 999
               SKIP 9 - ( cur_row - 13 )

               IF Eof()
                  GO BOTTOM

               ENDIF
            ENDIF

         ELSE
            n := i

         ENDIF

      CASE keystroke = 31
         keystroke := 0

         IF RecNo() = 1
            LOOP

         ENDIF

         IF is_append

            IF ! stru_ck( .F. )
               no_append()

            ENDIF
         ENDIF

         IF stru_ck( .T. )
            is_append := .F.
            is_insert := .F.

            IF RecNo() > cur_row - 12
               keystroke := 999

            ENDIF

            GO TOP
            cur_row := 13

         ELSE
            n := i

         ENDIF

      CASE keystroke = 30
         keystroke := 0

         IF is_append
            LOOP

         ENDIF

         IF stru_ck( .T. )
            is_insert := .F.

            IF LastRec() - RecNo() <= 22 - cur_row
               cur_row += LastRec() - RecNo()
               GO BOTTOM

            ELSE
               keystroke := 999
               GO BOTTOM
               SKIP - 9
               cur_row := 22

            ENDIF

         ELSE
            n := i

         ENDIF

      CASE keystroke = 6 .OR. keystroke = 23
         keystroke := 0
         n         := l_usr[ At( Left( field_type, 1 ), "CNDLMWPGQVF8BZYI24+=^@T" ) ]
         // n         := l_usr[ at( field_type, "CNDLM" ) ]

      CASE keystroke = 1 .OR. keystroke = 29
         // update field/record number on screen
         // @ 9,field_col[1] + 26 SAY "Field " + pad(LTRIM(STR(RECNO())), 5)
         IF n > l_usr[ At( Left( field_type, 1 ), "CNDLMWPGQVF8BZYI24+=^@T" ) ]
            // check for n out of range
            n := l_usr[ At( Left( field_type, 1 ), "CNDLMWPGQVF8BZYI24+=^@T" ) ]
         ENDIF
         keystroke := 0
         // n         := 1

      CASE keystroke = 22

         IF stru_ck( .T. )
            n         := 1
            stru_ok   := .F.
            is_append := .F.
            is_insert := .T.
            rec1      := RecNo()

            netrecapp()

            DO WHILE rec1 < RecNo()
               SKIP - 1

               f_name := field_name
               f_type := field_type
               f_len  := field_len
               f_dec  := field_dec

               SKIP
               field->field_name := f_name
               field->field_type := f_type
               field->field_len  := f_len
               field->field_dec  := f_dec

               SKIP - 1

            ENDDO

            field->field_name := Space( 10 )
            field->field_type := "C"
            field->field_len  := 10
            field->field_dec  := 0

            IF cur_row < 22
               Scroll( ( cur_row ), 21, 22, 58, - 1 )

            ENDIF

            @ cur_row, field_col[ 1 ] SAY not_empty

         ELSE
            n := i

         ENDIF

         keystroke := 0

      CASE keystroke = 7 .AND. LastRec() > 1
         rec1 := RecNo()
         netrecdel()
         PACK

         IF rec1 > LastRec()
            GO BOTTOM

            IF cur_row = 13
               stru_row( 13 )

            ELSE
               @ cur_row, field_col[ 1 ] SAY empty_row
               cur_row--

            ENDIF

         ELSE

            IF cur_row < 22
               Scroll( ( cur_row ), 21, 22, 58, 1 )

            ENDIF

            GOTO rec1
            SKIP 22 - cur_row

            IF ! Eof()
               stru_row( 22 )

            ELSE
               @ 22, field_col[ 1 ] SAY empty_row

            ENDIF

            GOTO rec1

            prev_rec := 0

         ENDIF

         IF ! is_append .AND. ! is_insert
            altered  := .T.
            chg_name := .F.

         ENDIF

         is_append := .F.
         is_insert := .F.
         stru_ok   := .T.
         keystroke := 0

      CASE prev_rec <> RecNo()
         prev_rec := RecNo()

         @  9, field_col[ 1 ] + 26 SAY "Campo " + Pad( LTrim( Str( RecNo() ) ), 5 )


         IF n > l_usr[ At( Left( field_type, 1 ), "CNDLMWPGQVF8BZYI24+=^@T" ) ]
            // check for n out of range
            n := l_usr[ At( Left( field_type, 1 ), "CNDLMWPGQVF8BZYI24+=^@T" ) ]
         ENDIF


         // if n > l_usr[ at( field_type, "CNDLM" ) ]
         // n := l_usr[ at( field_type, "CNDLM" ) ]
         //
         // endif

      CASE local_func = 4
         local_func := 0

         IF ! stru_ck( .T. )
            n := i
            LOOP

         ENDIF

         is_append := .F.
         is_insert := .F.
         filename  := stru_name

         IF filebox( "."+TABLEEXT, "dbf_list", "stru_title", ;
               "do_modstru", .T., 13 ) <> 0
            stru_name := filename

            @  9, field_col[ 1 ] + 13 ;
               SAY Pad( if( Empty( stru_name ), "<novo arquivo>", ;
               SubStr( stru_name, RAt( hb_ps(), stru_name ) + 1 ) ), 13 )

            IF aseek( dbf, filename ) = 0
               cur_dbf := filename

               open_dbf( .F., .T. )

               SELECT 10

            ENDIF

            keystroke := 27
            cur_area  := 0

         ENDIF

         stat_msg( "" )

      OTHERWISE

         IF ! key_ready()
            SetColor( M->color2 )
            stru_item()
            SetColor( M->color7 )

            read_key()

            IF !( keystroke = 13 .OR. isdata( keystroke ) )
               stru_item()

            ENDIF
         ENDIF

         IF keystroke = 27 .AND. altered

            IF rsvp( "Ok Abondonar Mudanc‡as? (S/N)" ) <> "S"
               keystroke := 0

            ENDIF
         ENDIF
      ENDCASE
   ENDDO CREATE / modify structure
   IF SELECT ( TEMPARQ ) # 0
      dbSelectAr( TEMPARQ )
   ENDIF
   dbCloseArea()
   FErase( temparq )
   stat_msg( "" )

   RestScreen( 8, 20, 23, 59, M->wstru_buff )

   SetColor( saveColor )

   RETURN


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function stru_row()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION stru_row

   PARAMETERS fill_row

   @ fill_row, field_col[ 1 ] ;
      SAY field_name + " | " + data_type[ At( Left( field_type, 1 ), "CNDLMWPGQVF8BZYI24+=^@T" ) ] + " | "


   IF field_type = "C"
      @ fill_row, field_col[ 3 ] SAY Str( ( ( 256 * field_dec ) + field_len ), 4 ) + ;
         " Ý    "

   ELSE
      @ fill_row, field_col[ 3 ] SAY Str( field_len, 4 ) + " Ý    "

      IF field_type $ "NFYI8BZ"  // if field_type = "N"
         @ fill_row, field_col[ 4 ] SAY field_dec

      ENDIF
   ENDIF

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function stru_item()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION stru_item

   DO CASE

   CASE n = 1
      @ cur_row, field_col[ 1 ] SAY field_name

   CASE n = 2
      @ cur_row, field_col[ 2 ] SAY data_type[ At( Left( field_type, 1 ), "CNDLMWPGQVF8BZYI24+=^@T" ) ]
      // @ cur_row, field_col[ 2 ] say data_type[ at( field_type, "CNDLM" ) ]

   CASE n = 3

      IF field_type = "C"
         @ cur_row, field_col[ n ] SAY Str( ( ( 256 * field_dec ) + ;
            field_len ), 4 )

      ELSE
         @ cur_row, field_col[ n ] SAY Str( field_len, 4 )

      ENDIF

   CASE n = 4
      @ cur_row, field_col[ 4 ] SAY field_dec

   ENDCASE

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function no_append()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION no_append

   netrecdel()
   PACK
   dbGoBottom()
   dbSkip()

   IF ( RecNo() = cur_row - 12 ) .OR. keystroke = 5
      @ cur_row, field_col[ 1 ] SAY empty_row

   ENDIF

   stru_ok := .T.

   RETURN 0


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function stru_ck()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION stru_ck

   PARAMETERS disp_err

   IF ! stru_ok
      i       := field_check( disp_err )
      stru_ok := ( i = 0 )

   ENDIF

   RETURN stru_ok


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function field_check()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION field_check

   PARAMETERS disp_err
   PRIVATE pos
   PRIVATE test_num
   PRIVATE test_name
   PRIVATE STATUS
   PRIVATE err_msg

   STATUS  := 0
   err_msg := ""

   pos := Len( Trim( field_name ) )

   IF pos = 0
      STATUS  := 1
      err_msg := "Campo sem nome"

   ENDIF
   
   IF STATUS = 0
      IF ! IsAlpha( Left(cFieldName, 1) )
         nStatus := 1
         cErrMsg := "Nome deve começar com letra"
	 ENDIF 
   ENDIF

   IF STATUS = 0

    
      IF pos > 0 .OR. SubStr( field_name, 1, 1 ) $ "0123456789_"
         STATUS  := 1
         err_msg := "Nome ilegal de Campo"

         IF keystroke = 24
            disp_err := .T.

         ENDIF
      ENDIF
   ENDIF

   IF STATUS = 0
      test_num  := RecNo()
      test_name := field_name
      LOCATE FOR field_name = test_name .AND. RecNo() <> test_num

      IF Found()
         STATUS  := 1
         err_msg := "Nome de campos duplicados"

         IF keystroke = 24
            disp_err := .T.

         ENDIF
      ENDIF

      GOTO test_num

   ENDIF

   IF STATUS = 0

      IF field_type = "C"
         test_num := ( 256 * field_dec ) + field_len

         IF test_num <= 0 .OR. test_num > 1024
            STATUS  := 3
            err_msg := "Tamanho de Campo invalido"

            IF keystroke = 24
               disp_err := .T.

            ENDIF
         ENDIF

      ELSE

         IF field_len <= 0 .OR. field_len > 19
            STATUS  := 3
            err_msg := "Tamanho de Campo invalido"

            IF keystroke = 24
               disp_err := .T.

            ENDIF
         ENDIF
      ENDIF
   ENDIF

   IF field_type $ "NFYI8BZ" .AND. STATUS = 0
      // if field_type = "N" .and. status = 0

      IF field_dec > if( field_len < 3, 0, if( field_len > 17, 15, field_len - 2 ) )
         STATUS  := 4
         err_msg := "Tamanho de decimais invalido"

         IF keystroke = 24
            disp_err := .T.

         ENDIF
      ENDIF
   ENDIF

   IF STATUS > 0 .AND. disp_err
      error_msg( err_msg )

   ENDIF

   RETURN STATUS


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function stru_title()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION stru_title

   PARAMETERS sysparam

   RETURN box_title( M->sysparam, "Salvando estrutura para..." )


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function do_modstru()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION do_modstru

   PRIVATE stru_done
   PRIVATE i
   PRIVATE is_open
   PRIVATE new_name
   PRIVATE name_temp
   PRIVATE add_name
   PRIVATE dbt_spec
   PRIVATE dbt_temp
   PRIVATE rec1

   DO CASE

   CASE Empty( filename )
      error_msg( "Nome de Arquivo nao fornecido" )
      stru_done := .F.

   OTHERWISE
      i       := aseek( dbf, filename )
      is_open := ( i > 0 )

      IF File( filename ) .AND. !( filename == cur_dbf )

         IF rsvp( filename + if( is_open, " J  est  aberto", ;
               " ou j  existe" ) + ;
               "...Sobreponha? (S/N)" ) <> "S"
            RETURN .F.

         ENDIF
      ENDIF

      IF is_open
         name_temp := "ntx" + SubStr( "123456", i, 1 )
         need_ntx  := need_ntx .OR. ! Empty( &name_temp[ 1 ] )

         not_target( i, .F. )

         SELECT ( M->i )
         dbCloseArea()

         name_temp := "kf" + SubStr( "123456", i, 1 )

         IF ! Empty( &name_temp )
            need_filtr := .T.

         ENDIF

         SELECT 10

      ENDIF

      rec1 := RecNo()
      dbCloseArea()

      add_name := ! hb_FileExists( name( filename ) + "."+TABLEEXT )

      IF File( filename )
         new_name := " "

         IF chg_name .AND. altered
            new_name := rsvp( "Trocar nome(s) de Campos? (S/N)" )

            IF ! new_name $ "SN"
               DBUREDE( temparq )
               GOTO rec1
               RETURN .F.

            ENDIF
         ENDIF


         name_bak  := trocaext( filename, "_temp."+TABLEEXT )   // substr( filename, 1, rat( hb_ps(), filename ) ) +  substr( FILENAME, 1, at( ".", FILENAME ) - 1 ) + ".bak"
         name_temp := trocaext( temparq, "_temp."+TABLEEXT )  // substr( filename, 1, rat( hb_ps(), filename ) ) +  temparq + ".bak"

         cORIMEMO := hb_rddInfo( RDDI_MEMOEXT )

         cFILEMEMO := TROCAEXT( filename, cORIMEMO )
         IF File( cFILEMEMO )
            dbt_spec := cFILEMEMO  // substr( filename, 1, rat( ".", filename ) )  +   "DBT"
            dbt_temp := trocaext( cFILEMEMO, "_TEMP" + _cORIMEMO )  // substr( name_temp, 1, rat( ".", name_temp ) ) +  "DBT"
         ENDIF

         // IF FILE(substr( filename, 1, rat( ".", filename ) )  +   "DBT")
         // dbt_spec := substr( filename, 1, rat( ".", filename ) )  +   "DBT"
         // dbt_temp := substr( name_temp, 1, rat( ".", name_temp ) ) +  "DBT"
         // endif

         // IF FILE(substr( filename, 1, rat( ".", filename ) )  +   "FPT")
         // dbt_spec := substr( filename, 1, rat( ".", filename ) )  +   "FPT"
         // dbt_temp := substr( name_temp, 1, rat( ".", name_temp ) ) +  "FPT"
         // endif

         // IF FILE(substr( filename, 1, rat( ".", filename ) )  +   "SMT")
         // dbt_spec := substr( filename, 1, rat( ".", filename ) )  +   "SMT"
         // dbt_temp := substr( name_temp, 1, rat( ".", name_temp ) ) +  "SMT"
         // endif

         IF File( dbt_spec )

            IF new_name = "S"
               new_name := rsvp( "Atencao: Memos serao perdidos ...Continue? (S/N)" )

               IF new_name <> "S"
                  DBUREDE( temparq )
                  GOTO rec1
                  RETURN .F.

               ENDIF
            ENDIF

            IF File( DBT_TEMP )
               FErase( DBT_TEMP )
            ENDIF

            FRename( dbt_spec, dbt_temp )   // rename &dbt_spec to &dbt_temp

         ENDIF

         stat_msg( if( new_name <> "S", "Alterando estrutura do Arquivo", "Alternado nome(s) de campo" ) )

         IF File( NAME_BAK )
            FErase( NAME_BAK )
         ENDIF

         FRename( filename, name_bak )

         aSTRU := {}
         dbSelectAr( TEMPARQ )
         nLASTREC := LastRec()
         zei_fort( nLASTREC,,, 0 )
         dbEval( {|| AAdd( aSTRU, { FIELD_NAME, FIELD_TYPE, FIELD_LEN, FIELD_DEC } ) }, {|| zei_fort( nLASTREC,,, 1 ) } )
         dbCreate( FILENAME, aSTRU )
         DBUREDE( FILENAME )
         dbSelectAr( SubStr( FILENAME, 1, At( ".", FILENAME ) - 1 ) )

         IF new_name = "S"
            dbSelectAr( SubStr( FILENAME, 1, At( ".", FILENAME ) - 1 ) )
            dbCloseArea()
            temparq2 := trocaext( temparq, ".txt" )
            DBUREDE( name_bak )
            nLASTREC := LastRec()
            zei_fort( nLASTREC,,, 0 )

            COPY TO &temparq2 SDF WHILE zei_fort( nLASTREC,,, 1 )
            dbCloseArea()
            DBUREDE( filename )

            nLASTREC := flinecount( temparq2 )
            zei_fort( nLASTREC,,, 0 )
            APPEND FROM &temparq2 SDF WHILE zei_fort( nLASTREC,,, 1 )
            FErase( temparq2 )

         ELSE

            nLASTREC := NetRegCount( name_bak )
            zei_fort( nLASTREC,,, 0 )
            APPEND FROM &name_bak WHILE zei_fort( nLASTREC,,, 1 )

         ENDIF

         IF File( name_temp )
            FErase( name_temp )  // erase &name_temp
         ENDIF
         IF File( dbt_temp )
            FErase( dbt_temp )   // erase &dbt_temp
         ENDIF

         IF is_open
            dbCloseArea()
            SELECT ( M->i )
            DBUREDE( filename )
            name_temp := "field_n" + SubStr( "123456", M->i, 1 )
            all_fields( M->i, &name_temp )
            SELECT 10
         ENDIF

      ELSE
         stat_msg( "Criando um novo arquivo" )
         CREATE &filename FROM &temparq
         dbCloseArea()

         IF At( "."+TABLEEXT, Lower( filename ) ) = Len( filename ) - 3 .AND. hb_FileExists( name( filename ) + "."+TABLEEXT ) .AND. add_name
            i := afull( dbf_list ) + 1

            IF i <= Len( dbf_list )
               dbf_list[ i ] = filename
               array_sort( dbf_list )

            ENDIF
         ENDIF
      ENDIF

      dbCloseArea()
      stru_done := .T.

   ENDCASE

   RETURN stru_done


// + EOF: dbustru.prg
// +
