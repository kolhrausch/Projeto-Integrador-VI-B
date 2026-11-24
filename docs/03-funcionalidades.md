# 4. Características do aplicativo

> **Situação final (Etapa 2).** Este documento descreve o que foi **efetivamente implementado**. Onde a implementação difere do planejado na Etapa 1, a diferença está indicada em *itálico*.

## Requisitos funcionais

### Módulo Catálogo (presença digital)
| Código | Funcionalidade | Tela / arquivo |
|---|---|---|
| RF01 | Cadastrar, editar, ativar/desativar e excluir produtos (nome, descrição, preço, estoque, foto, categoria) | `produto_form_screen.dart` |
| RF02 | Cadastrar categorias de produtos (pela própria tela do produto) | `produto_form_screen.dart` — *a edição/exclusão de categorias não foi implementada* |
| RF03 | Buscar produtos por nome e filtrar por categoria | `catalogo_screen.dart` |
| RF04 | Compartilhar o catálogo (texto formatado) por WhatsApp, Instagram e outros apps instalados | `catalogo_service.dart` — *compartilha texto; o envio de imagens não foi implementado* |
| RF05 | Registrar cada compartilhamento (canal e data) para análise de divulgação | tabela `divulgacao` — *o canal é informado pelo usuário antes de compartilhar* |
| RF06 | Configurar a "Minha vitrine": nome, slogan, logotipo, WhatsApp, Instagram e horário | `vitrine_screen.dart` |

### Módulo Clientes e Pedidos
| Código | Funcionalidade | Tela / arquivo |
|---|---|---|
| RF07 | Cadastrar, editar e excluir clientes (nome, telefone, e-mail opcional, observações) | `cliente_form_screen.dart` |
| RF08 | Registrar pedido com cliente, itens, quantidades, desconto e forma de pagamento | `pedido_form_screen.dart` |
| RF09 | Calcular automaticamente subtotal e total do pedido | `pedido_form_screen.dart`, `pedido_repository.dart` |
| RF10 | Baixar o estoque ao registrar o pedido e devolvê-lo ao cancelar | `pedido_repository.dart` (transações) |
| RF11 | Listar pedidos com filtro por status (aberto, pago, cancelado) | `pedidos_screen.dart` — *o filtro por período não foi implementado* |
| RF12 | Consultar o histórico de compras de cada cliente | `cliente_form_screen.dart` |

### Módulo Análise de Dados
| Código | Funcionalidade | Tela / arquivo |
|---|---|---|
| RF13 | Painel inicial: faturamento do mês, pedidos, ticket médio e novos clientes | `dashboard_screen.dart` |
| RF14 | Gráfico de vendas por dia (7, 30 ou 90 dias) | `relatorios_screen.dart` — *planejado "dia, semana ou mês"; implementado por dia com 3 períodos* |
| RF15 | Ranking de produtos mais vendidos e **curva ABC** | `dashboard_screen.dart`, `relatorios_screen.dart` |
| RF16 | Classificação de clientes por recência e frequência | `clientes_screen.dart`, `relatorios_screen.dart` |
| RF17 | Indicador de tendência: faturamento dos 7 últimos dias contra os 7 anteriores | `relatorios_screen.dart` — *planejado como média móvel; implementado como variação semanal* |
| RF18 | Relatório de produtos com estoque baixo (5 unidades ou menos) | `relatorios_screen.dart` |
| RF19 | Exportar resumo dos relatórios em arquivo CSV | `relatorios_screen.dart`, `export_service.dart` |
| RF22 | Medir o efeito da divulgação nos pedidos *(novo)* | `relatorios_screen.dart` |

### Módulo Geral
| Código | Funcionalidade | Tela / arquivo |
|---|---|---|
| RF20 | Tela "Sobre o app" com o nome completo de todos os integrantes | `sobre_screen.dart` |
| RF21 | Backup do arquivo do banco de dados (compartilhar `vitrine.db`) | `mais_screen.dart`, `export_service.dart` — *a restauração não foi implementada* |
| RF23 | Carregar dados de demonstração e apagar todos os dados *(novo)* | `mais_screen.dart`, `demo_data.dart` |

## Requisitos não funcionais

| Código | Requisito | Situação |
|---|---|---|
| RNF01 | Funcionar **100% offline**, com banco de dados SQLite local | Atendido: o app não usa internet |
| RNF02 | Rodar em Android 5.0 (API 21) ou superior | Mínimo definido pelo Flutter 3.24 |
| RNF03 | Interface simples, com navegação por barra inferior | Atendido (Material 3, 5 abas) |
| RNF04 | Consultas do painel em menos de 2 s para até 5.000 pedidos | Índices em `pedido(data_pedido)`, `pedido(cliente_id)` e `item_pedido(produto_id)` |
| RNF05 | Dados somente no aparelho, sem envio a servidores | Atendido (compartilhamento só ocorre por ação do usuário) |
| RNF06 | Valores monetários em centavos (inteiros) | Atendido |

## Regras de negócio

| Código | Regra | Onde é aplicada |
|---|---|---|
| RN01 | Um pedido só pode ser finalizado com pelo menos um item | `PedidoRepository.criar` e botão desabilitado na tela |
| RN02 | Quantidade maior que zero e não superior ao estoque | `PedidoRepository.criar` (valida dentro da transação) |
| RN03 | O preço do item é copiado do produto no momento da venda | `item_pedido.preco_unit_centavos` |
| RN04 | Total = soma dos itens − desconto; desconto não pode superar a soma dos itens | `PedidoRepository.criar` |
| RN05 | Cancelar um pedido devolve o estoque | `PedidoRepository.cancelar` |
| RN06 | Produto com vendas não é excluído, apenas desativado | `ProdutoRepository.excluir` + `ON DELETE RESTRICT` |
| RN07 | Classificação de clientes (abaixo) | `classificarCliente` em `core/rules.dart` |

**RN07 — perfil do cliente** (data de referência = hoje; vale a primeira regra que se aplicar):

1. **Novo:** primeira compra há 30 dias ou menos (ou cadastro recente, ainda sem compras);
2. **Fiel:** 3 ou mais pedidos pagos nos últimos 90 dias;
3. **Inativo:** última compra há mais de 120 dias (ou nenhuma compra e cadastro antigo);
4. **Em risco:** última compra entre 60 e 120 dias;
5. **Regular:** demais casos *(categoria acrescentada na implementação)*.

## Indicadores de Ciência de Dados

Calculados por consultas SQL no banco local (`lib/database/queries.dart`) e por funções puras e testadas (`lib/core/rules.dart`).

| Indicador | Definição |
|---|---|
| Faturamento | Soma de `pedido.total_centavos` dos pedidos **pagos** no período |
| Ticket médio | Faturamento ÷ quantidade de pedidos pagos |
| Curva ABC | Produtos ordenados por receita. Um produto é **A** enquanto a receita acumulada *antes* dele for menor que 80%; **B** até 95%; **C** no restante |
| Recência/Frequência | Dias desde a última compra e nº de pedidos pagos nos últimos 90 dias (base do perfil do cliente) |
| Tendência | Variação % do faturamento dos 7 últimos dias contra os 7 dias anteriores |
| Efeito da divulgação | Média de pedidos pagos no dia do compartilhamento e nos 3 dias seguintes, comparada à média de qualquer janela de 4 dias nos últimos 30 dias |

Exemplo — ranking de produtos que alimenta a curva ABC (`Queries.rankingProdutos`):

```sql
SELECT p.id, p.nome,
       SUM(i.quantidade) AS unidades,
       SUM(i.quantidade * i.preco_unit_centavos) AS receita
FROM item_pedido i
JOIN pedido d ON d.id = i.pedido_id
JOIN produto p ON p.id = i.produto_id
WHERE d.status = 'PAGO'
  AND date(d.data_pedido) >= date('now', 'localtime', ?)
GROUP BY p.id
ORDER BY receita DESC, p.nome
```
