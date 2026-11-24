import 'package:flutter/material.dart';

import '../core/exceptions.dart';
import '../core/format.dart';
import '../core/rules.dart';
import '../repositories/relatorio_repository.dart';
import '../services/export_service.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

/// Relatórios e análise de dados (RF13 a RF19), calculados no SQLite local.
class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen>
    with DataReloadMixin<RelatoriosScreen> {
  static const List<int> _periodos = [7, 30, 90];

  final RelatorioRepository _repo = RelatorioRepository();

  int _indicePeriodo = 1;
  bool _carregando = true;
  String? _erro;

  List<VendaDia> _serie = [];
  double? _tendencia;
  List<ItemAbc> _abc = [];
  List<ClientePerfil> _clientes = [];
  List<ProdutoEstoque> _estoque = [];
  EfeitoDivulgacao? _efeito;

  int get _dias => _periodos[_indicePeriodo];

  @override
  Future<void> carregar() async {
    try {
      final dias = _dias;
      // Busca ao menos 14 dias para calcular a tendência (7 dias x 7 anteriores).
      final base = await _repo.vendasPorDia(dias < 14 ? 14 : dias);
      final tendencia = variacaoTendencia(base.map((v) => v.totalCentavos).toList());
      final serie = base.sublist(base.length - dias);
      final abc = await _repo.curvaAbc(dias);
      final clientes = await _repo.perfilClientes();
      final estoque = await _repo.estoqueBaixo();
      final efeito = await _repo.efeitoDivulgacao();
      if (!mounted) {
        return;
      }
      setState(() {
        _serie = serie;
        _tendencia = tendencia;
        _abc = abc;
        _clientes = clientes;
        _estoque = estoque;
        _efeito = efeito;
        _erro = null;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _erro = mensagemErro(e);
        _carregando = false;
      });
    }
  }

  int get _faturamentoPeriodo =>
      _serie.fold<int>(0, (soma, v) => soma + v.totalCentavos);

  int get _pedidosPeriodo => _serie.fold<int>(0, (soma, v) => soma + v.qtd);

  String _aspas(String texto) {
    final escapado = texto.replaceAll('"', '""');
    return '"$escapado"';
  }

  String _montarCsv() {
    final linhas = StringBuffer();
    final ticket = _pedidosPeriodo == 0 ? 0 : (_faturamentoPeriodo / _pedidosPeriodo).round();
    linhas.writeln('Resumo - ultimos $_dias dias');
    linhas.writeln('Faturamento (R\$);${_aspas(formatMoney(_faturamentoPeriodo))}');
    linhas.writeln('Pedidos pagos;$_pedidosPeriodo');
    linhas.writeln('Ticket medio (R\$);${_aspas(formatMoney(ticket))}');
    linhas.writeln();
    linhas.writeln('Curva ABC;Receita (R\$);Percentual;Classe');
    for (final item in _abc) {
      linhas.writeln(
        '${_aspas(item.nome)};${_aspas(formatMoney(item.receitaCentavos))};'
        '${_aspas(formatPercent(item.percentual))};${item.classe}',
      );
    }
    linhas.writeln();
    linhas.writeln('Dia;Vendas (R\$);Pedidos');
    for (final venda in _serie) {
      linhas.writeln(
        '${formatDate(venda.dia)};${_aspas(formatMoney(venda.totalCentavos))};${venda.qtd}',
      );
    }
    return linhas.toString();
  }

  Future<void> _exportar() async {
    try {
      await ExportService.compartilharCsv('vitrine_relatorio_${_dias}d.csv', _montarCsv());
    } catch (e) {
      if (mounted) {
        mostrarMensagem(context, mensagemErro(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: _corpo(),
    );
  }

  Widget _corpo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    final erro = _erro;
    if (erro != null) {
      return EstadoVazio(icone: Icons.error_outline, mensagem: erro);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      children: [
        FiltroChips(
          opcoes: [for (final d in _periodos) '$d dias'],
          selecionado: _indicePeriodo,
          aoSelecionar: (indice) {
            setState(() => _indicePeriodo = indice);
            carregar();
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Vendas por dia'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${formatMoney(_faturamentoPeriodo)} em $_pedidosPeriodo pedido(s)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      GraficoLinha(valores: _serie.map((v) => v.totalCentavos).toList()),
                      const SizedBox(height: 8),
                      Text(_textoTendencia(), style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ),
                ),
              ),
              const SectionTitle('Curva ABC de produtos'),
              _blocoAbc(),
              const SectionTitle('Clientes por perfil'),
              _blocoPerfis(),
              const SectionTitle('Estoque baixo'),
              _blocoEstoque(),
              const SectionTitle('Efeito da divulgação'),
              _blocoDivulgacao(),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _exportar,
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('Exportar resumo (CSV)'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _textoTendencia() {
    final t = _tendencia;
    if (t == null) {
      return 'Tendência: sem base de comparação (precisa de vendas na semana anterior).';
    }
    final sinal = t >= 0 ? '+' : '';
    final direcao = t >= 0 ? 'alta' : 'queda';
    return 'Tendência: $direcao de $sinal${formatPercent(t)} (7 dias vs. 7 dias anteriores).';
  }

  Widget _blocoAbc() {
    if (_abc.isEmpty) {
      return const Text('Sem vendas pagas no período.');
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (final item in _abc)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Etiqueta(item.classe),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Text(formatMoney(item.receitaCentavos)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: item.percentual / 100),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _blocoPerfis() {
    final contagem = <PerfilCliente, int>{};
    for (final c in _clientes) {
      contagem[c.perfil] = (contagem[c.perfil] ?? 0) + 1;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 20,
          runSpacing: 12,
          children: [
            for (final perfil in PerfilCliente.values)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${contagem[perfil] ?? 0}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(perfil.rotulo, style: const TextStyle(fontSize: 11)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _blocoEstoque() {
    if (_estoque.isEmpty) {
      return const Text('Nenhum produto com estoque baixo (5 unidades ou menos).');
    }
    return Card(
      child: Column(
        children: [
          for (final produto in _estoque)
            ListTile(
              dense: true,
              title: Text(produto.nome),
              trailing: Text(
                '${produto.estoque} un.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: produto.estoque == 0 ? Colors.red.shade700 : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _blocoDivulgacao() {
    final efeito = _efeito;
    if (efeito == null) {
      return const Text(
        'Compartilhe o catálogo para medir o efeito da divulgação nos pedidos.',
      );
    }
    final apos = efeito.mediaPedidosAposCompartilhar;
    final geral = efeito.mediaPedidosJanelaGeral;
    final melhor = apos >= geral;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${efeito.compartilhamentos} compartilhamento(s) nos últimos 60 dias.'),
            const SizedBox(height: 6),
            Text('Pedidos em 4 dias após compartilhar: ${apos.toStringAsFixed(1).replaceAll('.', ',')} (média)'),
            Text('Pedidos em 4 dias quaisquer: ${geral.toStringAsFixed(1).replaceAll('.', ',')} (média)'),
            const SizedBox(height: 6),
            Text(
              melhor
                  ? 'Os dias após divulgar vendem acima da média.'
                  : 'Os dias após divulgar ainda não superam a média.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
