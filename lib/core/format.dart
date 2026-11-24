/// Funções utilitárias de formatação e conversão (sem dependência do Flutter).

const List<String> kDiasSemanaCurto = [
  'Seg',
  'Ter',
  'Qua',
  'Qui',
  'Sex',
  'Sáb',
  'Dom',
];

const List<String> kMeses = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

bool temTexto(String? valor) => valor != null && valor.trim().isNotEmpty;

/// Texto digitado -> valor para o banco (vazio vira null).
String? textoOuNulo(String valor) {
  final limpo = valor.trim();
  return limpo.isEmpty ? null : limpo;
}

String doisDigitos(int n) => n.toString().padLeft(2, '0');

/// Formata centavos como moeda brasileira: 123456 -> "R$ 1.234,56".
String formatMoney(int centavos) {
  final sinal = centavos < 0 ? '-' : '';
  final absoluto = centavos.abs();
  final reais = absoluto ~/ 100;
  final resto = absoluto % 100;
  return '${sinal}R\$ ${_milhares(reais)},${doisDigitos(resto)}';
}

String _milhares(int n) {
  final s = n.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final restantes = s.length - i;
    buffer.write(s[i]);
    if (restantes > 1 && restantes % 3 == 1) {
      buffer.write('.');
    }
  }
  return buffer.toString();
}

/// Converte o texto digitado ("12,50", "R$ 1.234,56", "12.5") em centavos.
/// Retorna null se o texto não for um valor válido.
int? parseMoneyToCents(String entrada) {
  var s = entrada.trim().replaceAll('R\$', '').replaceAll(' ', '');
  if (s.isEmpty) {
    return null;
  }
  if (s.contains(',')) {
    s = s.replaceAll('.', '').replaceAll(',', '.');
  }
  final valor = double.tryParse(s);
  if (valor == null || valor < 0) {
    return null;
  }
  return (valor * 100).round();
}

/// "yyyy-MM-ddTHH:mm:ss" (formato ISO 8601 usado no banco).
String isoDateTime(DateTime d) {
  final ano = d.year.toString().padLeft(4, '0');
  return '$ano-${doisDigitos(d.month)}-${doisDigitos(d.day)}'
      'T${doisDigitos(d.hour)}:${doisDigitos(d.minute)}:${doisDigitos(d.second)}';
}

/// "yyyy-MM-dd".
String isoDate(DateTime d) {
  final ano = d.year.toString().padLeft(4, '0');
  return '$ano-${doisDigitos(d.month)}-${doisDigitos(d.day)}';
}

String isoNow() => isoDateTime(DateTime.now());

/// "2026-10-20T12:30:00" -> "20/10/2026".
String formatDate(String iso) {
  final d = DateTime.parse(iso);
  return '${doisDigitos(d.day)}/${doisDigitos(d.month)}/${d.year}';
}

/// "2026-10-20T12:30:00" -> "20/10/2026 12:30".
String formatDateTime(String iso) {
  final d = DateTime.parse(iso);
  return '${formatDate(iso)} ${doisDigitos(d.hour)}:${doisDigitos(d.minute)}';
}

String formatPercent(double valor) => '${valor.toStringAsFixed(1).replaceAll('.', ',')}%';

/// Abreviação do dia da semana ("Seg", "Ter"...) para uma data ISO.
String diaSemanaCurto(String isoData) {
  final d = DateTime.parse(isoData);
  return kDiasSemanaCurto[d.weekday - 1];
}
