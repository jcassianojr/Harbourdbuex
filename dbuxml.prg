// +--------------------------------------------------------------------
// +
// +   
// +
// +
// +--------------------------------------------------------------------
// +


// +--------------------------------------------------------------------
// +
// +
// +
// +    Programa  : dbuxml.prg
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

#include "DBINFO.CH"
#include "Dbstruct.ch"


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function Dbf2Xml()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION Dbf2Xml()  // Requer Area Aberta

   LOCAL sRet           := ""
   LOCAL hXML
   LOCAL sXML
   LOCAL sAlias
   LOCAL s
   LOCAL sType
   LOCAL sData
   LOCAL dwBytesWritten
   LOCAL i

   sAlias := Upper( Alias() )
   sXML   := sAlias + ".xml"

   hXML := FCreate( sXML, 0 )
   IF hXML == -1
      ALERTX( "Erro Criando XML" )
      RETU
   ENDIF

   s := '<?xml version="1.0" encoding="windows-1252"?>' + hb_osNewLine()
   FWrite( hXML, s )
   s := '<' + sAlias + 's>' + hb_osNewLine()
   FWrite( hXML, s )

   s := '<xsd:schema id="' + sAlias + 's"' + ;
      ' xmlns="" ' + ;
      'xmlns:xsd="http://www.w3.org/2001/XMLSchema" ' + ;
      'xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">' + hb_osNewLine()
   FWrite( hXML, s )

   s := '  <xsd:element name="' + sAlias + 's" msdata:IsDataSet="true" msdata:Locale="en-US">' + hb_osNewLine()
   FWrite( hXML, s )

   s := '    <xsd:complexType>' + hb_osNewLine()
   FWrite( hXML, s )
   s := '      <xsd:choice maxOccurs="unbounded">' + hb_osNewLine()
   FWrite( hXML, s )
   s := '        <xsd:element name="' + sAlias + '">' + hb_osNewLine()
   FWrite( hXML, s )
   s := '          <xsd:complexType>' + hb_osNewLine()
   FWrite( hXML, s )
   s := '            <xsd:sequence>' + hb_osNewLine()
   FWrite( hXML, s )
   FOR i := 1 TO FCount()
      IF dbFieldInfo( DBS_TYPE, i ) == "L"
         sType := "boolean"
      ELSEIF dbFieldInfo( DBS_TYPE, i ) == "N"
         IF dbFieldInfo( DBS_DEC, i ) == 2
            sType := "decimal"
         ELSEIF dbFieldInfo( DBS_DEC, i ) == 0
            sType := "integer"
         ELSE
            sType := "double"
         ENDIF
      ELSEIF dbFieldInfo( DBS_TYPE, i ) == "D"
         sType := "date"   // date correlates to CLR DateTime which can't be null
      ELSE
         sType := "string"
      ENDIF
      s := '              <xsd:element name="' + Upper( FieldName( i ) ) + '"  type="xsd:' + sType + '" minOccurs="0"/>' + hb_osNewLine()
      FWrite( hXML, s )
   NEXT
   s := '            </xsd:sequence>' + hb_osNewLine()
   FWrite( hXML, s )
   s := '          </xsd:complexType>' + hb_osNewLine()
   FWrite( hXML, s )
   s := '        </xsd:element>' + hb_osNewLine()
   FWrite( hXML, s )
   s := '      </xsd:choice>' + hb_osNewLine()
   FWrite( hXML, s )
   s := '    </xsd:complexType>' + hb_osNewLine()
   FWrite( hXML, s )
   s := '  </xsd:element>' + hb_osNewLine()
   FWrite( hXML, s )
   s := '</xsd:schema>' + hb_osNewLine()
   FWrite( hXML, s )

// Write XML data -----------------------------------------------------------------------
   dbGoTop()
   WHILE !Eof()
      s := '  <' + sAlias + '>' + hb_osNewLine()
      FWrite( hXML, s )
      FOR i := 1 TO FCount()
         sData := GetXMLString( hb_FieldGet( i ) )
         s     := '    <' + Upper( FieldName( i ) ) + '>' + sData + '</' + Upper( FieldName( i ) ) + '>' + hb_osNewLine()
         FWrite( hXML, s )
      NEXT
      s := '  </' + sAlias + '>' + hb_osNewLine()
      FWrite( hXML, s )
      dbSkip( 1 )
   END
   s := '</' + sAlias + 's>' + hb_osNewLine()
   FWrite( hXML, s )
   FClose( hXML )
// dbclosearea()

   RETURN sRet



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function GetXMLString()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION GetXMLString( x )

   LOCAL d
   LOCAL sRet

   IF ValType( x ) == "L"
      sRet := logic2str( x, 0, 0, zSEPLOGIC )   // iif( x, "1", "0" )
   ELSEIF ValType( x ) == "D"
      d := x
      IF Empty( d )
         sRet := DATA2STR( CToD( "01/01/0001" ), ZANOFOR, ZANOSEP, ZANOTAM )  // "0001-01-01"
      ELSE
         sRet := DATA2STR( d, ZANOFOR, ZANOSEP, ZANOTAM )   // substr( dtos( d ), 1, 4 ) + "-" + substr( dtos( d ), 5, 2 ) + "-" + substr( dtos( d ), 7, 2 )
      ENDIF
   ELSEIF ValType( x ) == "C"
      sRet := str2html( x )
   ELSE
      sRet := StrVAL( x )
   ENDIF

   RETURN sRet


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


/*
XML Schema :
<DataRoot>
   <Estrutura>
      <Campo>
        <Nome></Nome>
        <Tipo></Tipo>
        <Tamanho></Tamanho>
        <Decimal></Decimal>
      </Campo>
   </Estrutura>
   <Indice>
      <Chave></Chave>
   </Indice>
   <Dados>
      <Registro>
        <#Nome do campo#></#Nome do campo#>
      </Registro>
   </Dados>
</DataRoot>
*/

// + EOF: dbuxml.prg
// +
