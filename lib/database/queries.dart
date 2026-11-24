/// Consultas SQL usadas pelo aplicativo (telas, relatórios e ciência de dados).
///
/// Todas usam `?` como parâmetro. Datas ficam gravadas em texto ISO 8601 no
/// horário local; por isso as funções de data usam o modificador 'localtime'.
/// Este arquivo é lido por `tool/validar_sql.py`, que executa cada consulta
/// em um SQLite real com dados de exemplo.
abstract final class Queries {
  // ---------------------------------------------------------------- produtos
  static const String produtosBusca = '''
SELECT p.*, c.nome AS categoria_nome
FROM produto p
LEFT JOIN categoria c ON c.id = p.categoria_id
WHERE p.nome LIKE ?
ORDER BY p.nome COLLATE NOCASE
''';

  static const String produtosBuscaCategoria = '''
SELECT p.*, c.nome AS categoria_nome
FROM produto p
LEFT JOIN categoria c ON c.id = p.categoria_id
WHERE p.categoria_id = ? AND p.nome LIKE ?
ORDER BY p.nome COLLATE NOCASE
''';

  static const String produtoPorId = '''
SELECT p.*, c.nome AS categoria_nome
FROM produto p
LEFT JOIN categoria c ON c.id = p.categoria_id
WHERE p.id = ?
''';

  static const String produtosCatalogo = '''
SELECT p.*, c.nome AS categoria_nome
FROM produto p
LEFT JOIN categoria c ON c.id = p.categoria_id
WHERE p.ativo = 1
ORDER BY c.nome COLLATE NOCASE, p.nome COLLATE NOCASE
''';

  static const String produtosParaVenda = '''
SELECT p.*, c.nome AS categoria_nome
FROM produto p
LEFT JOIN categoria c ON c.id = p.categoria_id
WHERE p.ativo = 1 AND p.estoque > 0
ORDER BY p.nome COLLATE NOCASE
''';

  static const String contarItensDoProduto = '''
SELECT COUNT(*) AS n FROM item_pedido WHERE produto_id = ?
''';

  static const String estoqueBaixo = '''
SELECT id, nome, estoque
FROM produto
WHERE ativo = 1 AND estoque <= ?
ORDER BY estoque, nome COLLATE NOCASE
''';

  static const String categoriasAtivas = '''
SELECT * FROM categoria WHERE ativa = 1 ORDER BY nome COLLATE NOCASE
''';

  static const String categoriaPorNome = '''
SELECT id FROM categoria WHERE nome = ? COLLATE NOCASE
''';

  // ------------------------------------------------------------------ pedidos
  static const String pedidosLista = '''
SELECT d.id, d.cliente_id, d.data_pedido, d.status, d.forma_pagamento,
       d.desconto_centavos, d.total_centavos, c.nome AS cliente_nome
FROM pedido d
LEFT JOIN cliente c ON c.id = d.cliente_id
ORDER BY d.data_pedido DESC, d.id DESC
''';

  static const String pedidoPorId = '''
SELECT d.id, d.cliente_id, d.data_pedido, d.status, d.forma_pagamento,
       d.desconto_centavos, d.total_centavos, c.nome AS cliente_nome
FROM pedido d
LEFT JOIN cliente c ON c.id = d.cliente_id
WHERE d.id = ?
''';

  static const String pedidosDoCliente = '''
SELECT d.id, d.cliente_id, d.data_pedido, d.status, d.forma_pagamento,
       d.desconto_centavos, d.total_centavos, c.nome AS cliente_nome
FROM pedido d
LEFT JOIN cliente c ON c.id = d.cliente_id
WHERE d.cliente_id = ?
ORDER BY d.data_pedido DESC, d.id DESC
''';

  static const String itensDoPedido = '''
SELECT i.id, i.pedido_id, i.produto_id, i.quantidade, i.preco_unit_centavos,
       p.nome AS produto_nome
FROM item_pedido i
JOIN produto p ON p.id = i.produto_id
WHERE i.pedido_id = ?
ORDER BY i.id
''';

  // ------------------------------------------------------- ciência de dados
  /// Faturamento e nº de pedidos pagos no mês corrente.
  static const String resumoMes = '''
SELECT COALESCE(SUM(total_centavos), 0) AS faturamento,
       COUNT(*) AS pedidos
FROM pedido
WHERE status = 'PAGO'
  AND strftime('%Y-%m', data_pedido) = strftime('%Y-%m', 'now', 'localtime')
''';

  static const String novosClientesMes = '''
SELECT COUNT(*) AS n
FROM cliente
WHERE strftime('%Y-%m', criado_em) = strftime('%Y-%m', 'now', 'localtime')
''';

  /// Parâmetro: modificador de data, ex.: '-6 day' (últimos 7 dias).
  static const String vendasPorDia = '''
SELECT date(data_pedido) AS dia,
       SUM(total_centavos) AS total,
       COUNT(*) AS qtd
FROM pedido
WHERE status = 'PAGO'
  AND date(data_pedido) >= date('now', 'localtime', ?)
GROUP BY date(data_pedido)
ORDER BY dia
''';

  /// Ranking de produtos por receita no período (base da curva ABC).
  /// Parâmetro: modificador de data, ex.: '-29 day'.
  static const String rankingProdutos = '''
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
''';

  /// Base da classificação de clientes por recência e frequência (RN07).
  static const String clientesPerfil = '''
SELECT c.id, c.nome, c.telefone, c.criado_em,
       COUNT(d.id) AS total_pedidos,
       MIN(date(d.data_pedido)) AS primeira_compra,
       MAX(date(d.data_pedido)) AS ultima_compra,
       COALESCE(SUM(CASE WHEN date(d.data_pedido) >= date('now', 'localtime', '-90 day')
                         THEN 1 ELSE 0 END), 0) AS pedidos_90d
FROM cliente c
LEFT JOIN pedido d ON d.cliente_id = c.id AND d.status = 'PAGO'
GROUP BY c.id
ORDER BY c.nome COLLATE NOCASE
''';

  /// Para cada compartilhamento: pedidos pagos no dia e nos 3 dias seguintes.
  static const String divulgacoesEfeito = '''
SELECT v.id, v.canal, v.data_envio,
       (SELECT COUNT(*)
          FROM pedido d
         WHERE d.status = 'PAGO'
           AND date(d.data_pedido) BETWEEN date(v.data_envio)
                                       AND date(v.data_envio, '+3 day')) AS pedidos_janela
FROM divulgacao v
WHERE date(v.data_envio) >= date('now', 'localtime', '-60 day')
ORDER BY v.data_envio DESC
''';

  static const String pedidosPagosPeriodo = '''
SELECT COUNT(*) AS n
FROM pedido
WHERE status = 'PAGO'
  AND date(data_pedido) >= date('now', 'localtime', ?)
''';

  static const String divulgacoesNoMes = '''
SELECT COUNT(*) AS n
FROM divulgacao
WHERE strftime('%Y-%m', data_envio) = strftime('%Y-%m', 'now', 'localtime')
''';
}
