class ItemPedido {
  const ItemPedido({
    this.id,
    this.pedidoId,
    required this.produtoId,
    required this.quantidade,
    required this.precoUnitCentavos,
    this.produtoNome,
  });

  final int? id;
  final int? pedidoId;
  final int produtoId;
  final int quantidade;

  /// Preço copiado do produto no momento da venda (RN03).
  final int precoUnitCentavos;

  /// Preenchido apenas em consultas com JOIN.
  final String? produtoNome;

  int get subtotalCentavos => quantidade * precoUnitCentavos;

  factory ItemPedido.fromMap(Map<String, Object?> map) {
    return ItemPedido(
      id: map['id'] as int?,
      pedidoId: map['pedido_id'] as int?,
      produtoId: map['produto_id'] as int,
      quantidade: map['quantidade'] as int,
      precoUnitCentavos: map['preco_unit_centavos'] as int,
      produtoNome: map['produto_nome'] as String?,
    );
  }

  ItemPedido comQuantidade(int novaQuantidade) {
    return ItemPedido(
      id: id,
      pedidoId: pedidoId,
      produtoId: produtoId,
      quantidade: novaQuantidade,
      precoUnitCentavos: precoUnitCentavos,
      produtoNome: produtoNome,
    );
  }
}
