# DBU

DBU é uma ferramenta de gestão e manipulação de arquivos DBF escrita em Harbour, voltada para ambientes que trabalham com bases dBase/Clipper/Harbour e integração com bancos SQL.

O projeto reúne utilitários para abrir, editar, criar, exportar, importar e manter tabelas em diversos formatos, além de oferecer suporte a múltiplos RDDs e drivers de acesso.

## Visão geral

O DBU foi pensado para facilitar o trabalho com arquivos `.dbf` e estruturas relacionadas, como índices, memos, exportações e conversões entre formatos. Ele inclui módulos para:

- manipulação de arquivos DBF e índices
- geração e manutenção de estruturas de banco
- edição e consulta de registros
- exportação para planilhas e formatos de dados
- integração com bancos SQL e fontes ODBC
- suporte a múltiplas tecnologias do ecossistema Harbour

## Principais recursos

- suporte a RDDs como DBFCDX, DBFNTX, DBFNSX, ADS, Paradox, CSV e JSON
- compatibilidade com SQLite, MySQL, PostgreSQL, Firebird, DuckDB, ODBC e SQLRDD
- utilitários para edição, visualização, cópia, compactação e reorganização de arquivos
- suporte a arquivos XLS/XLSX e geração de relatórios/planilhas
- estrutura modular em vários arquivos `.prg`

## Estrutura do repositório

- `dbu.prg` — programa principal
- `dbuutil.prg` — utilitários gerais
- `dbuedit.prg` — edição de registros e estrutura
- `dbuview.prg` — visualização de dados
- `dbudoc.prg` — múltiplas operações de documentação/exportação
- `dbusqlite.prg`, `dbumixsql.prg`, `dbusqlrdd.prg` — integração SQL
- `dbuodbc.prg`, `dbuadox.prg` — acesso via ODBC/ADO
- `dbuduck.prg` — suporte a DuckDB
- `dbu32/` e `dbu64/` — scripts e arquivos de compilação para 32 e 64 bits
- `dbu.md` — descrição resumida do projeto
- `dbudocxls.md` e `dbudocxlm.md` — documentação de exportação para Excel

## Requisitos

- Harbour
- hbmk2 (ou ferramenta equivalente de build da distribuição Harbour usada)
- ambiente de compilação compatível com Windows (o projeto inclui scripts para compilação em 32/64 bits)

## Compilação

Os scripts de build já estão incluídos nas pastas `dbu32` e `dbu64`.

Exemplo para 32 bits:

```bat
cd dbu32
compdbu32.bat
```

Exemplo para 64 bits:

```bat
cd dbu64
compdbu64.bat
```

Os scripts usam `hbmk2.exe` e também carregam os ambientes Harbour do sistema.

## Execução

Após compilar, você pode executar o binário gerado, por exemplo:

```bat
dbu32.exe
```

ou

```bat
dbu64.exe
```

## Observações

Este repositório contém uma coleção de módulos e utilitários para o ecossistema Harbour e não se limita a um único executável. A documentação principal do projeto está concentrada nos arquivos `.md` e nos comentários dos módulos `.prg`.

## Licença

Este projeto não informa uma licença explícita no arquivo atual do repositório. Verifique os arquivos do projeto e a origem dos componentes antes de redistribuir em ambientes comerciais ou públicos.

## Agradecimentos

O projeto faz uso de tecnologias e bibliotecas do ecossistema Harbour, além de integrações com bancos e formatos diversos, como SQLite, PostgreSQL, Firebird, DuckDB, ODBC e XLSX.
