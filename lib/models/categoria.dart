class Categoria {
  const Categoria({
    this.id,
    required this.nome,
    this.descricao,
    this.ativa = true,
  });

  final int? id;
  final String nome;
  final String? descricao;
  final bool ativa;

  factory Categoria.fromMap(Map<String, Object?> map) {
    return Categoria(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      descricao: map['descricao'] as String?,
      ativa: ((map['ativa'] as int?) ?? 1) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'nome': nome,
      'descricao': descricao,
      'ativa': ativa ? 1 : 0,
    };
  }
}
