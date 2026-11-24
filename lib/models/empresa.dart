class Empresa {
  const Empresa({
    required this.nome,
    this.slogan,
    this.whatsapp,
    this.instagram,
    this.horarioAtendimento,
    this.logoPath,
  });

  final String nome;
  final String? slogan;
  final String? whatsapp;
  final String? instagram;
  final String? horarioAtendimento;
  final String? logoPath;

  factory Empresa.fromMap(Map<String, Object?> map) {
    return Empresa(
      nome: map['nome'] as String,
      slogan: map['slogan'] as String?,
      whatsapp: map['whatsapp'] as String?,
      instagram: map['instagram'] as String?,
      horarioAtendimento: map['horario_atendimento'] as String?,
      logoPath: map['logo_path'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': 1,
      'nome': nome,
      'slogan': slogan,
      'whatsapp': whatsapp,
      'instagram': instagram,
      'horario_atendimento': horarioAtendimento,
      'logo_path': logoPath,
    };
  }
}
