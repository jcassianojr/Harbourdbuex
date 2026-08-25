// +--------------------------------------------------------------------
// +
// +   git\core\extras\hbxlsxml\
// +
// +
// +--------------------------------------------------------------------
// +


#require "hbxlsxml"
PROCEDURE FazerxlsXML()
    LOCAL oXml, oSheet
    LOCAL aStru    := DBStruct()
    LOCAL nFields  := Len( aStru )
    LOCAL nPos     := 1
    LOCAL i, xValor, cAlias := Alias()
    LOCAL cFileName := cAlias + "_xls.xml"

    // Validação de arquivo existente
    IF File( cFileName )
        IF FErase( cFileName ) == -1
            Alert( "Erro: Nao foi possivel apagar o arquivo anterior. Verifique se esta aberto." )
            RETURN
        ENDIF
    ENDIF

    oXml   := ExcelWriterXML():New( cFileName )
    oSheet := oXml:addSheet( cAlias )

    // --- CABEÇALHO ---
    // Usando variáveis locais para evitar checagem de lDOCCAB repetida
    IF Type("lDOCCAB") == "L" .AND. lDOCCAB
        FOR i := 1 TO nFields
            // Simplificação da montagem da string de estrutura
            xValor := aStru[i][1] + "," + aStru[i][2]
            IF aStru[i][2] $ "CN"
                xValor += "," + AllTrim(Str(aStru[i][3]))
            ENDIF  
            IF aStru[i][2] == "N" 
                xValor += "," + AllTrim(Str(aStru[i][4]))
            ENDIF   
            oSheet:writeString( nPos, i, xValor )
        NEXT
        nPos++
    ENDIF

    // --- DADOS ---
    IF Type("lDOCDAD") == "L" .AND. lDOCDAD
        DbGoTop()
        DO WHILE .NOT. Eof()
            FOR i := 1 TO nFields
                xValor := hb_FieldGet(i)
                
                // Ignora campos vazios para reduzir tamanho do XML
                IF Empty(xValor) ; LOOP ; ENDIF

                SWITCH ValType(xValor)
                CASE "C"
                    oSheet:writeString( nPos, i, xValor )
                    EXIT
                CASE "N"
                    oSheet:writeNumber( nPos, i, xValor )
                    EXIT
                CASE "D"
                    // Mantido String conforme sua necessidade original
                    oSheet:writeString( nPos, i, DToC(xValor) )
                    EXIT
                CASE "L"
                    oSheet:writeString( nPos, i, If(xValor, "TRUE", "FALSE") )
                    EXIT
                END
            NEXT
            
            nPos++
            
            // Indicador de progresso (se existir a função)
            IF Type("nLASTREC") == "N"
                ZEI_FORT( nLASTREC,,, 1 )
            ENDIF
            
            DbSkip()
        ENDDO
    ENDIF

    oXml:writeData() // hbxlsxml geralmente já sabe o nome do arquivo pelo New()

    RETURN
    
    
// +--------------------------------------------------------------------
// +
// +
// +
// +    Function TIPOXML()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION TIPOXML( cTIPO, nTAM, nDEC )

   LOCAL cRETU := ""

   DO CASE
   CASE cTIPO = 'C'
      cRETU := 'string'
   CASE cTIPO = 'N'
      IF nDEC = 0
         cRETU := 'i4'   // +alltrim(str(ntam))
      ELSE
         cRETU := 'r8'   // 'float'
      ENDIF
   CASE cTIPO = 'L'
      cRETU := 'boolean'
   CASE cTIPO = 'D'
      cRETU := 'date'  // datetime
   CASE cTIPO = 'M'
      cRETU := 'string'
   ENDCASE

   RETURN cRETU
