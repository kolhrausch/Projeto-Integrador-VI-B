# Detalhamento da construção do banco de dados local (Etapa 2, item 2)

Este documento explica **como o banco de dados local do Vitrine é construído**, desde a modelagem até a validação. O diagrama entidade-relacionamento e o dicionário de dados completos estão em [04-modelo-er.md](04-modelo-er.md).

## 1. Visão geral

| Característica | Valor |
|---|---|
| SGBD | SQLite (embutido no Android) |
| Biblioteca | `sqflite` |
| Arquivo | `vitrine.db`, na pasta privada de bancos do app |
| Tabelas | **7** (exigência: mínimo 4) |
| Colunas por tabela | de 4 a 9 (exigência: mínimo 3) |
| Relacionamentos | **4** chaves estrangeiras (exigência: ao menos 1 relação entre 2 tabelas) |
| Índices | 4 |
| Funciona sem internet | Sim |

## 2. Tabelas, colunas e relacionamentos

| Tabela | Colunas | Finalidade | Chaves estrangeiras |
|---|---|---|---|
| `empresa` | 7 (`id`, `nome`, `slogan`, `whatsapp`, `instagram`, `horario_atendimento`, `logo_path`) | Dados da vitrine digital; **uma única linha** (`id = 1`) | — |
| `categoria` | 4 (`id`, `nome`, `descricao`, `ativa`) | Categorias de produtos | — |
| `produto` | 9 (`id`, `categoria_id`, `nome`, `descricao`, `preco_centavos`, `estoque`, `foto_path`, `ativo`, `criado_em`) | Catálogo e estoque | `categoria_id` → `categoria.id` |
| `cliente` | 6 (`id`, `nome`, `telefone`, `email`, `observacoes`, `criado_em`) | Cadastro de clientes | — |
| `pedido` | 7 (`id`, `cliente_id`, `data_pedido`, `status`, `forma_pagamento`, `desconto_centavos`, `total_centavos`) | Cabeçalho das vendas | `cliente_id` → `cliente.id` |
| `item_pedido` | 5 (`id`, `pedido_id`, `produto_id`, `quantidade`, `preco_unit_centavos`) | Itens de cada venda (tabela associativa N:N entre pedido e produto) | `pedido_id` → `pedido.id`; `produto_id` → `produto.id` |
| `divulgacao` | 5 (`id`, `canal`, `data_envio`, `qtd_produtos`, `observacao`) | Registro de cada compartilhamento do catálogo | — (cruzada por **data** com `pedido` nas análises) |

### Relacionamentos e regras de exclusão

| Relação | Cardinalidade | Ao excluir o registro "pai" |
|---|---|---|
| `categoria` → `produto` | 1 : N | `SET NULL` — o produto fica sem categoria |
| `cliente` → `pedido` | 1 : N | `SET NULL` — os pedidos são preservados (histórico de vendas) |
| `pedido` → `item_pedido` | 1 : N | `CASCADE` — os itens do pedido são removidos junto |
| `produto` → `item_pedido` | 1 : N | `RESTRICT` — produto já vendido não pode ser excluído (só desativado) |

### Restrições (integridade)

| Tipo | Onde |
|---|---|
| `PRIMARY KEY AUTOINCREMENT` | `id` de todas as tabelas (exceto `empresa`) |
| `NOT NULL` | nomes, preços, estoque, datas, status, quantidade |
| `UNIQUE` | `categoria.nome`; `cliente.telefone`; `(item_pedido.pedido_id, item_pedido.produto_id)` |
| `CHECK` | `empresa.id = 1`; flags `ativa`/`ativo` em (0,1); preço, estoque e desconto ≥ 0; quantidade > 0; `pedido.status` em (`ABERTO`,`PAGO`,`CANCELADO`); forma de pagamento em (`PIX`,`DINHEIRO`,`CARTAO`,`OUTRO`); canal em (`WHATSAPP`,`INSTAGRAM`,`OUTRO`) |
| `FOREIGN KEY` | as quatro relações acima |

### Índices

`idx_produto_categoria`, `idx_pedido_data`, `idx_pedido_cliente` e `idx_item_produto` aceleram a listagem por categoria, os filtros por período e os `JOIN`s dos relatórios.

### Convenções

- **Dinheiro** em centavos (`INTEGER`): R$ 12,50 → `1250`, sem erros de arredondamento.
- **Datas** em texto ISO 8601 no horário local (`2026-10-20T12:30:00`), compatível com `date()` e `strftime()` do SQLite.
- **Booleanos** como `INTEGER` 0/1 (o SQLite não tem tipo booleano).
- **Telefone vazio** é gravado como `NULL` (e não `''`), para a restrição `UNIQUE` não bloquear clientes sem telefone.

## 3. Como o banco é construído (passo a passo)

1. **Modelagem** — o modelo ER da Etapa 1 foi refinado para 7 tabelas ([04-modelo-er.md](04-modelo-er.md)).
2. **Script de criação (DDL)** — `lib/database/schema.dart` guarda uma lista de instruções SQL (`CREATE TABLE`, `CREATE INDEX` e a linha inicial de `empresa`).
3. **Abertura e criação** — na primeira vez que o app acessa o banco, `DatabaseHelper` chama `openDatabase(...)`. Como o arquivo ainda não existe, o `sqflite` cria o arquivo e executa o `onCreate`, que roda as instruções do `schema.dart` em um *batch*. Nas próximas aberturas o `onCreate` não roda de novo.
4. **Configuração a cada abertura** — `onConfigure` executa `PRAGMA foreign_keys = ON`, pois o SQLite não verifica chaves estrangeiras por padrão.
5. **Acesso aos dados** — as telas nunca falam com o banco diretamente: usam os **repositórios** (`ProdutoRepository`, `ClienteRepository`, `PedidoRepository`, `EmpresaRepository`, `RelatorioRepository`), que convertem linhas em objetos (`models/`).
6. **Consultas SQL centralizadas** — todas ficam em `lib/database/queries.dart`, com parâmetros `?` (sem concatenar texto do usuário no SQL).
7. **Transações** — operações com mais de um passo são atômicas:
   - *registrar pedido*: valida estoque → grava `pedido` → grava `item_pedido` → baixa o estoque de cada produto;
   - *cancelar pedido*: devolve o estoque dos itens → muda o status para `CANCELADO`;
   - *limpar/carregar dados de demonstração*.
8. **Evolução** — o número de `versao` do banco e o callback `onUpgrade` permitem migrar o esquema em atualizações futuras do app.

### Fluxo de um pedido (exemplo de escrita)

```
Tela "Novo pedido"  →  PedidoRepository.criar()
   BEGIN TRANSACTION
     SELECT estoque FROM produto WHERE id = ?          (para cada item; falha se faltar estoque)
     INSERT INTO pedido (...)
     INSERT INTO item_pedido (...)                      (para cada item)
     UPDATE produto SET estoque = estoque - ? WHERE id = ?
   COMMIT                                               (qualquer erro desfaz tudo: ROLLBACK)
   AppState.dadosAlterados()  →  painel, listas e relatórios se atualizam
```

## 4. Consultas de ciência de dados

| Consulta (`Queries.`) | Para que serve |
|---|---|
| `resumoMes`, `novosClientesMes` | Faturamento, pedidos pagos e novos clientes do mês (painel) |
| `vendasPorDia` | Série diária de vendas (gráficos e tendência) |
| `rankingProdutos` | Receita e unidades por produto (top 3 e curva ABC) |
| `clientesPerfil` | Nº de pedidos, primeira/última compra e pedidos em 90 dias (perfil RFM simplificado) |
| `divulgacoesEfeito`, `pedidosPagosPeriodo` | Efeito dos compartilhamentos do catálogo sobre os pedidos |
| `estoqueBaixo` | Produtos com 5 unidades ou menos |
| `pedidosLista`, `itensDoPedido`, `pedidosDoCliente` | Listagens com `JOIN` |

Só pedidos com status `PAGO` entram nos indicadores; pedidos abertos e cancelados são ignorados.

## 5. Validação

O script [`tool/validar_sql.py`](../tool/validar_sql.py) lê **o mesmo SQL que está no código do app** (`schema.dart` e `queries.dart`), cria o banco em um SQLite real, popula com dados de exemplo e confere:

- criação das 7 tabelas e de cada coluna (mínimo 3 por tabela);
- as restrições `CHECK` e `UNIQUE` rejeitam dados inválidos (preço negativo, estoque negativo, status inválido, quantidade zero, telefone duplicado, produto repetido no pedido);
- as chaves estrangeiras: pedido com cliente inexistente é rejeitado; excluir cliente preserva os pedidos; excluir pedido remove os itens; excluir produto vendido é bloqueado; excluir categoria deixa o produto sem categoria;
- o resultado das consultas de relatório (faturamento, ranking, perfil de clientes, efeito da divulgação, estoque baixo).

Resultado: **47 verificações aprovadas** (`python3 tool/validar_sql.py`). O mesmo script roda no GitHub Actions a cada *push*.

Para inspecionar o banco real do emulador/celular, use o *Device File Explorer* do Android Studio (`/data/data/br.edu.vitrine.vitrine/databases/vitrine.db`) ou o botão **Mais → Backup** do app, e abra o arquivo no [DB Browser for SQLite](https://sqlitebrowser.org).
