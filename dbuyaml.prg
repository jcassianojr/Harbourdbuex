// +--------------------------------------------------------------------
// +
// +   Função baseada em xlsxclass e hbxlsxml para gerar YAML
// +
// +--------------------------------------------------------------------

PROCEDURE FazerYAML()
    LOCAL cFileName := Alias() + ".yaml"
    LOCAL nHandle
    LOCAL aStru   := DBStruct()
    LOCAL nFields := Len( aStru )
    LOCAL i, xValor
    LOCAL cTexto  := ""
    LOCAL cAlias  := Alias()
    LOCAL cEOL    := hb_osNewLine()

    // Validação de arquivo existente
    IF File( cFileName )
        IF FErase( cFileName ) == -1
            Alert( "Erro: Nao foi possivel apagar o arquivo YAML anterior." )
            RETURN
        ENDIF
    ENDIF

    nHandle := FCreate( cFileName )
    IF nHandle == -1
        Alert( "Erro ao criar o arquivo YAML" )
        RETURN
    ENDIF

    // --- CABEÇALHO / ESTRUTURA ---
    // Verifica a flag global/private lDOCCAB
    IF Type("lDOCCAB") == "L" .AND. lDOCCAB
        cTexto += "metadata:" + cEOL
        cTexto += "  tabela: " + '"' + cAlias + '"' + cEOL
        cTexto += "  campos:" + cEOL
        
        FOR i := 1 TO nFields
            cTexto += "    - nome: " + '"' + aStru[i][1] + '"' + cEOL
            cTexto += "      tipo: " + '"' + aStru[i][2] + '"' + cEOL
            cTexto += "      tamanho: " + AllTrim(Str(aStru[i][3])) + cEOL
            cTexto += "      decimal: " + AllTrim(Str(aStru[i][4])) + cEOL
        NEXT
        
        FWrite( nHandle, cTexto )
        cTexto := "" // Limpa buffer
    ENDIF

    // --- DADOS ---
    // Verifica a flag global/private lDOCDAD
    IF Type("lDOCDAD") == "L" .AND. lDOCDAD
        cTexto += "dados:" + cEOL
        FWrite( nHandle, cTexto )
        cTexto := ""

        DbGoTop()
        DO WHILE .NOT. Eof()
            cTexto += "  -" + cEOL
            
            FOR i := 1 TO nFields
                xValor := hb_FieldGet(i)
                
                // Formata a chave (nome do campo)
                cTexto += "    " + aStru[i][1] + ": "
                
                // Formata o valor dependendo do tipo do campo
                SWITCH aStru[i][2]
                CASE "C"
                CASE "M"
                    // Limpeza de caracteres usando a função vista na source xlsxclass
                    xValor := FixSRTExtendido( xValor , .T. , .T. , .T. , .T. , .T. )
                    // Trata aspas duplas no meio da string para não quebrar o YAML
                    xValor := StrTran( xValor, '"', '\"' )
                    cTexto += '"' + AllTrim(xValor) + '"' + cEOL
                    EXIT
                CASE "N"
                    cTexto += AllTrim(Str(xValor)) + cEOL
                    EXIT
                CASE "D"
                    IF Empty(xValor)
                        cTexto += "null" + cEOL
                    ELSE
                        // Usando DToS para gerar padrão YYYYMMDD, ideal para serializações,
                        // ou mantendo DToC(xValor) se quiser a formatação local
                        cTexto += '"' + DToC(xValor) + '"' + cEOL
                    ENDIF
                    EXIT
                CASE "L"
                    // Booleano sem aspas no YAML
                    cTexto += If(xValor, "true", "false") + cEOL
                    EXIT
                OTHERWISE
                    // Fallback para outros tipos (Timestamps, etc)
                    cTexto += '"' + hb_ValToStr(xValor) + '"' + cEOL
                END
            NEXT
            
            FWrite( nHandle, cTexto )
            cTexto := ""
            
            // Atualiza barra de progresso, compatível com a chamada de xlsxclass e hbxlsxml
            IF Type("nLASTREC") == "N"
                ZEI_FORT( nLASTREC,,, 1 )
            ENDIF
            
            DbSkip()
        ENDDO
    ENDIF

    FClose( nHandle )
RETURN