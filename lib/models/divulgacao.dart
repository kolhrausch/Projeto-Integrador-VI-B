abstract final class Canal {
  static const String whatsapp = 'WHATSAPP';
  static const String instagram = 'INSTAGRAM';
  static const String outro = 'OUTRO';

  static String rotulo(String canal) => switch (canal) {
        'WHATSAPP' => 'WhatsApp',
        'INSTAGRAM' => 'Instagram',
        _ => 'Outros',
      };
}

class Divulgacao {
  const Divulgacao({
    this.id,
    required this.canal,
    required this.dataEnvio,
    required this.qtdProdutos,
    this.observacao,
  });

  final int? id;
  final String canal;
  final String dataEnvio;
  final int qtdProdutos;
  final String? observacao;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'canal': canal,
      'data_envio': dataEnvio,
      'qtd_produtos': qtdProdutos,
      'observacao': observacao,
    };
  }
}
