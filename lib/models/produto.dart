class Produto {
  const Produto({
    this.id,
    this.categoriaId,
    required this.nome,
    this.descricao,
    required this.precoCentavos,
    required this.estoque,
    this.fotoPath,
    this.ativo = true,
    required this.criadoEm,
    this.categoriaNome,
  });

  final int? id;
  final int? categoriaId;
  final String nome;
  final String? descricao;
  final int precoCentavos;
  final int estoque;
  final String? fotoPath;
  final bool ativo;
  final String criadoEm;

  /// Preenchido apenas em consultas com JOIN (não é coluna da tabela produto).
  final String? categoriaNome;

  factory Produto.fromMap(Map<String, Object?> map) {
    return Produto(
      id: map['id'] as int?,
      categoriaId: map['categoria_id'] as int?,
      nome: map['nome'] as String,
      descricao: map['descricao'] as String?,
      precoCentavos: map['preco_centavos'] as int,
      estoque: map['estoque'] as int,
      fotoPath: map['foto_path'] as String?,
      ativo: ((map['ativo'] as int?) ?? 1) == 1,
      criadoEm: map['criado_em'] as String,
      categoriaNome: map['categoria_nome'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'categoria_id': categoriaId,
      'nome': nome,
      'descricao': descricao,
      'preco_centavos': precoCentavos,
      'estoque': estoque,
      'foto_path': fotoPath,
      'ativo': ativo ? 1 : 0,
      'criado_em': criadoEm,
    };
  }
}
