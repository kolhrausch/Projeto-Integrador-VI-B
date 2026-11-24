import '../core/format.dart';
import '../core/rules.dart';
import '../database/database_helper.dart';
import '../database/queries.dart';

class ResumoMes {
  const ResumoMes({
    required this.faturamentoCentavos,
    required this.pedidos,
    required this.novosClientes,
  });

  final int faturamentoCentavos;
  final int pedidos;
  final int novosClientes;

  int get ticketMedioCentavos =>
      pedidos == 0 ? 0 : (faturamentoCentavos / pedidos).round();
}

class VendaDia {
  const VendaDia({required this.dia, required this.totalCentavos, required this.qtd});

  /// Data no formato yyyy-MM-dd.
  final String dia;
  final int totalCentavos;
  final int qtd;
}

class ProdutoRanking {
  const ProdutoRanking({
    required this.id,
    required this.nome,
    required this.unidades,
    required this.receitaCentavos,
  });

  final int id;
  final String nome;
  final int unidades;
  final int receitaCentavos;
}

class ClientePerfil {
  const ClientePerfil({
    required this.id,
    required this.nome,
    this.telefone,
    required this.totalPedidos,
    required this.perfil,
  });

  final int id;
  final String nome;
  final String? telefone;
  final int totalPedidos;
  final PerfilCliente perfil;
}

class ProdutoEstoque {
  const ProdutoEstoque({required this.id, required this.nome, required this.estoque});

  final int id;
  final String nome;
  final int estoque;
}

class EfeitoDivulgacao {
  const EfeitoDivulgacao({
    required this.compartilhamentos,
    required this.mediaPedidosAposCompartilhar,
    required this.mediaPedidosJanelaGeral,
  });

  final int compartilhamentos;

  /// Média de pedidos pagos no dia do compartilhamento e nos 3 dias seguintes.
  final double mediaPedidosAposCompartilhar;

  /// Média de pedidos pagos em qualquer janela de 4 dias (últimos 30 dias).
  final double mediaPedidosJanelaGeral;
}

/// Consultas analíticas (ciência de dados) executadas localmente no SQLite.
class RelatorioRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<ResumoMes> resumoMes() async {
    final db = await _helper.database;
    final resumo = (await db.rawQuery(Queries.resumoMes)).first;
    final novos = (await db.rawQuery(Queries.novosClientesMes)).first;
    return ResumoMes(
      faturamentoCentavos: (resumo['faturamento'] as num).toInt(),
      pedidos: (resumo['pedidos'] as num).toInt(),
      novosClientes: (novos['n'] as num).toInt(),
    );
  }

  /// Série diária dos últimos [dias] dias (dias sem venda aparecem com zero),
  /// do mais antigo para o mais recente.
  Future<List<VendaDia>> vendasPorDia(int dias) async {
    final db = await _helper.database;
    final linhas = await db.rawQuery(Queries.vendasPorDia, ['-${dias - 1} day']);
    final porDia = <String, VendaDia>{};
    for (final linha in linhas) {
      final dia = linha['dia'] as String;
      porDia[dia] = VendaDia(
        dia: dia,
        totalCentavos: (linha['total'] as num).toInt(),
        qtd: (linha['qtd'] as num).toInt(),
      );
    }
    final hoje = DateTime.now();
    final serie = <VendaDia>[];
    for (var i = dias - 1; i >= 0; i--) {
      final data = DateTime(hoje.year, hoje.month, hoje.day - i);
      final chave = isoDate(data);
      serie.add(porDia[chave] ?? VendaDia(dia: chave, totalCentavos: 0, qtd: 0));
    }
    return serie;
  }

  /// Produtos por receita no período (maior primeiro).
  Future<List<ProdutoRanking>> rankingProdutos(int dias) async {
    final db = await _helper.database;
    final linhas = await db.rawQuery(Queries.rankingProdutos, ['-${dias - 1} day']);
    return linhas
        .map((l) => ProdutoRanking(
              id: l['id'] as int,
              nome: l['nome'] as String,
              unidades: (l['unidades'] as num).toInt(),
              receitaCentavos: (l['receita'] as num).toInt(),
            ))
        .toList();
  }

  Future<List<ItemAbc>> curvaAbc(int dias) async {
    final ranking = await rankingProdutos(dias);
    return calcularCurvaAbc(
      ranking.map((r) => MapEntry<String, int>(r.nome, r.receitaCentavos)).toList(),
    );
  }

  /// Todos os clientes com o perfil calculado pela regra RN07.
  Future<List<ClientePerfil>> perfilClientes() async {
    final db = await _helper.database;
    final linhas = await db.rawQuery(Queries.clientesPerfil);
    final hoje = DateTime.now();
    return linhas.map((l) {
      final primeira = l['primeira_compra'] as String?;
      final ultima = l['ultima_compra'] as String?;
      final total = (l['total_pedidos'] as num).toInt();
      final perfil = classificarCliente(
        hoje: hoje,
        criadoEm: DateTime.parse(l['criado_em'] as String),
        totalPedidos: total,
        pedidos90Dias: (l['pedidos_90d'] as num).toInt(),
        primeiraCompra: primeira == null ? null : DateTime.parse(primeira),
        ultimaCompra: ultima == null ? null : DateTime.parse(ultima),
      );
      return ClientePerfil(
        id: l['id'] as int,
        nome: l['nome'] as String,
        telefone: l['telefone'] as String?,
        totalPedidos: total,
        perfil: perfil,
      );
    }).toList();
  }

  Future<List<ProdutoEstoque>> estoqueBaixo({int limite = 5}) async {
    final db = await _helper.database;
    final linhas = await db.rawQuery(Queries.estoqueBaixo, [limite]);
    return linhas
        .map((l) => ProdutoEstoque(
              id: l['id'] as int,
              nome: l['nome'] as String,
              estoque: l['estoque'] as int,
            ))
        .toList();
  }

  /// Compara os pedidos logo após cada compartilhamento do catálogo com a
  /// média geral. Retorna null se não houve compartilhamentos nos últimos 60 dias.
  Future<EfeitoDivulgacao?> efeitoDivulgacao() async {
    final db = await _helper.database;
    final linhas = await db.rawQuery(Queries.divulgacoesEfeito);
    if (linhas.isEmpty) {
      return null;
    }
    var soma = 0;
    for (final linha in linhas) {
      soma += (linha['pedidos_janela'] as num).toInt();
    }
    final pedidos30 = (await db.rawQuery(Queries.pedidosPagosPeriodo, ['-29 day']))
        .first['n'] as num;
    return EfeitoDivulgacao(
      compartilhamentos: linhas.length,
      mediaPedidosAposCompartilhar: soma / linhas.length,
      mediaPedidosJanelaGeral: pedidos30.toInt() / 30 * 4,
    );
  }
}
