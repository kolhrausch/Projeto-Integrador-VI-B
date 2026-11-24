abstract final class StatusPedido {
  static const String aberto = 'ABERTO';
  static const String pago = 'PAGO';
  static const String cancelado = 'CANCELADO';

  static const List<String> todos = [aberto, pago, cancelado];

  static String rotulo(String status) => switch (status) {
        'ABERTO' => 'Aberto',
        'PAGO' => 'Pago',
        'CANCELADO' => 'Cancelado',
        _ => status,
      };
}

abstract final class FormaPagamento {
  static const List<String> todas = ['PIX', 'DINHEIRO', 'CARTAO', 'OUTRO'];

  static String rotulo(String? forma) => switch (forma) {
        'PIX' => 'Pix',
        'DINHEIRO' => 'Dinheiro',
        'CARTAO' => 'Cartão',
        'OUTRO' => 'Outro',
        _ => '—',
      };
}

class Pedido {
  const Pedido({
    this.id,
    this.clienteId,
    required this.dataPedido,
    required this.status,
    this.formaPagamento,
    this.descontoCentavos = 0,
    required this.totalCentavos,
    this.clienteNome,
  });

  final int? id;
  final int? clienteId;
  final String dataPedido;
  final String status;
  final String? formaPagamento;
  final int descontoCentavos;
  final int totalCentavos;

  /// Preenchido apenas em consultas com JOIN.
  final String? clienteNome;

  factory Pedido.fromMap(Map<String, Object?> map) {
    return Pedido(
      id: map['id'] as int?,
      clienteId: map['cliente_id'] as int?,
      dataPedido: map['data_pedido'] as String,
      status: map['status'] as String,
      formaPagamento: map['forma_pagamento'] as String?,
      descontoCentavos: (map['desconto_centavos'] as int?) ?? 0,
      totalCentavos: map['total_centavos'] as int,
      clienteNome: map['cliente_nome'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'cliente_id': clienteId,
      'data_pedido': dataPedido,
      'status': status,
      'forma_pagamento': formaPagamento,
      'desconto_centavos': descontoCentavos,
      'total_centavos': totalCentavos,
    };
  }
}
