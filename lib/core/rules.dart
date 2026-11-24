/// Regras de negócio e cálculos de ciência de dados (funções puras, testáveis).

enum PerfilCliente { novo, fiel, emRisco, inativo, regular }

extension PerfilClienteRotulo on PerfilCliente {
  String get rotulo => switch (this) {
        PerfilCliente.novo => 'Novo',
        PerfilCliente.fiel => 'Fiel',
        PerfilCliente.emRisco => 'Em risco',
        PerfilCliente.inativo => 'Inativo',
        PerfilCliente.regular => 'Regular',
      };
}

/// Diferença em dias de calendário entre duas datas (ignora a hora).
int diasEntre(DateTime anterior, DateTime posterior) {
  final a = DateTime.utc(anterior.year, anterior.month, anterior.day);
  final b = DateTime.utc(posterior.year, posterior.month, posterior.day);
  return b.difference(a).inDays;
}

/// RN07 - classificação do cliente por recência e frequência.
///
/// Ordem de precedência:
/// 1. Novo: primeira compra há 30 dias ou menos (ou cadastro recente sem compras);
/// 2. Fiel: 3 ou mais pedidos pagos nos últimos 90 dias;
/// 3. Inativo: última compra há mais de 120 dias (ou nenhuma compra);
/// 4. Em risco: última compra entre 60 e 120 dias;
/// 5. Regular: demais casos.
PerfilCliente classificarCliente({
  required DateTime hoje,
  required DateTime criadoEm,
  required int totalPedidos,
  required int pedidos90Dias,
  DateTime? primeiraCompra,
  DateTime? ultimaCompra,
}) {
  if (totalPedidos == 0 || primeiraCompra == null || ultimaCompra == null) {
    return diasEntre(criadoEm, hoje) <= 30
        ? PerfilCliente.novo
        : PerfilCliente.inativo;
  }
  if (diasEntre(primeiraCompra, hoje) <= 30) {
    return PerfilCliente.novo;
  }
  if (pedidos90Dias >= 3) {
    return PerfilCliente.fiel;
  }
  final diasSemComprar = diasEntre(ultimaCompra, hoje);
  if (diasSemComprar > 120) {
    return PerfilCliente.inativo;
  }
  if (diasSemComprar >= 60) {
    return PerfilCliente.emRisco;
  }
  return PerfilCliente.regular;
}

class ItemAbc {
  const ItemAbc({
    required this.nome,
    required this.receitaCentavos,
    required this.percentual,
    required this.percentualAcumulado,
    required this.classe,
  });

  final String nome;
  final int receitaCentavos;
  final double percentual;
  final double percentualAcumulado;
  final String classe;
}

/// Curva ABC. A lista de entrada deve estar ordenada por receita (maior primeiro).
/// Classe A: receita acumulada antes do item < 80%; B: < 95%; C: restante.
List<ItemAbc> calcularCurvaAbc(List<MapEntry<String, int>> itensOrdenados) {
  final total = itensOrdenados.fold<int>(0, (soma, e) => soma + e.value);
  if (total <= 0) {
    return <ItemAbc>[];
  }
  var acumulado = 0.0;
  final resultado = <ItemAbc>[];
  for (final item in itensOrdenados) {
    final percentual = item.value * 100 / total;
    final classe = acumulado < 80 ? 'A' : (acumulado < 95 ? 'B' : 'C');
    acumulado += percentual;
    resultado.add(ItemAbc(
      nome: item.key,
      receitaCentavos: item.value,
      percentual: percentual,
      percentualAcumulado: acumulado,
      classe: classe,
    ));
  }
  return resultado;
}

/// Tendência: variação percentual do faturamento dos 7 últimos dias contra os
/// 7 dias anteriores. Recebe a série diária (mínimo 14 dias, do mais antigo
/// para o mais recente). Retorna null se não houver base de comparação.
double? variacaoTendencia(List<int> faturamentoDiario) {
  if (faturamentoDiario.length < 14) {
    return null;
  }
  final n = faturamentoDiario.length;
  final recentes =
      faturamentoDiario.sublist(n - 7).fold<int>(0, (a, b) => a + b);
  final anteriores =
      faturamentoDiario.sublist(n - 14, n - 7).fold<int>(0, (a, b) => a + b);
  if (anteriores == 0) {
    return null;
  }
  return (recentes - anteriores) * 100 / anteriores;
}
