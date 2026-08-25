Com base na análise do código fonte fornecido (`dbudoc.prg`, `xlsxclass.prg` e a biblioteca/classe pura Harbour para XLSX), podemos identificar quais opções geram arquivos `.xls` (ou arquivos baseados em planilhas Excel) e quais são as técnicas utilizadas em cada uma delas.

---

### Opções do `dbudoc` que geram formatos de Planilha (`.xls` / `.xlsx`)

No código do sistema, o tipo principal `tDOC = 1` refere-se a relatórios/arquivos no formato Excel, mas ele possui subtipos (`cSUBTIPO`) e funções dedicadas que alternam o comportamento e a tecnologia de geração:

1. **`tDOC = 1` com subtipo `"TAB"` (Delimitado por TAB)**
* **O que faz:** O `GERADOC` trata a exportação alterando temporariamente para o tipo delimitado (`tDOC = 5`) usando o caractere de tabulação (`TAB`) como separador. Embora tenha a extensão genérica ou delimitada, é frequentemente usado para abertura direta em editores de planilha.


2. **`tDOC = 1` com subtipo `"TRH"` (HTML / Tabela HTML)**
* **O que faz:** Gera uma estrutura em formato HTML (`<table>`, `<tr>`, `<th>`, `<td>`), que o Excel reconhece nativamente ao ser aberto (frequentemente utilizado para planilhas simples baseadas em marcação web).


3. **`tDOC = 1` com subtipo `"TDB"` (Classe XLSX Nativa - `Fazerxlsclass`)**
* **O que faz:** Aciona diretamente a função `Fazerxlsclass()`, gerando um arquivo `.xlsx` estruturado de forma moderna por código puro.




4. **Subtipo `"XLSXLM"` (Gerenciamento via classe avançada / rotinas específicas)**
* **O que faz:** Aciona a rotina `Fazerxlsxlm()`, voltada para a criação e manipulação avançada de planilhas Excel estruturadas.





---

### Técnicas Utilizadas na Geração

O código emprega diferentes técnicas dependendo da opção escolhida pelo usuário:

#### 1. Técnica Baseada em HTML Tables (`TRH`)

* **Descrição:** Manipulação de strings em Harbour (`cTEXTO += "<table>"`, `<tr>`, `<td>`).


* **Funcionamento:** O arquivo é salvo com tags HTML estruturadas. Aplicativos de planilha como o Microsoft Excel ou LibreOffice Calc conseguem interpretar essa marcação e renderizar as células, linhas e colunas sem precisar de automação COM/OLE (ActiveX).

#### 2. Técnica Baseada em Arquivos Delimitados por Tabulação (`TAB`)

* **Descrição:** Exportação baseada em texto plano com separadores de campo (`ZDELIMITE` com tabulação).


* **Funcionamento:** Os dados são gravados sequencialmente linha por linha, separando as colunas por tabulação (`TAB`), o que permite que o Excel importe o arquivo nativamente ao ser acionado.

#### 3. Técnica de Manipulação Direta de `.xlsx` em Harbour Puro (`xlsxclass.prg`)

* **Descrição:** Uso de classes orientadas a objetos em Harbour puro (sem dependência de OLE/Excel instalado na máquina) criadas por *Srdan Dragojlovic* (`WorkBook`, `WorkSheet`, `DrawingML`).


* **Funcionamento:**
* Cria uma estrutura padrão de diretórios temporários compatível com o formato OpenXML (`xl/worksheets/`, `xl/styles.xml`, `xl/sharedStrings.xml`, etc.).


* Utiliza manipulação de XML e arquivos compactados (`hbmzip` / `hb_zipOpen`) para gerar o arquivo `.xlsx` final compactado em formato ZIP padronizado pelo Excel moderno.


* Suporta formatação avançada de células, fontes personalizadas (`NewFont`), padrões de preenchimento (`NewFillPattern`), bordas (`NewBorder`), larguras de colunas (`ColumnsWidth`) e metadados da planilha.