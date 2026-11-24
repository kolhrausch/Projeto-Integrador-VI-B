class Cliente {
  const Cliente({
    this.id,
    required this.nome,
    this.telefone,
    this.email,
    this.observacoes,
    required this.criadoEm,
  });

  final int? id;
  final String nome;
  final String? telefone;
  final String? email;
  final String? observacoes;
  final String criadoEm;

  factory Cliente.fromMap(Map<String, Object?> map) {
    return Cliente(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      telefone: map['telefone'] as String?,
      email: map['email'] as String?,
      observacoes: map['observacoes'] as String?,
      criadoEm: map['criado_em'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'nome': nome,
      'telefone': telefone,
      'email': email,
      'observacoes': observacoes,
      'criado_em': criadoEm,
    };
  }
}
