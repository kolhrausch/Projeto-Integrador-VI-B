import 'package:flutter/material.dart';

import '../core/exceptions.dart';
import '../core/format.dart';
import '../models/empresa.dart';
import '../repositories/empresa_repository.dart';
import '../repositories/relatorio_repository.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import 'pedido_form_screen.dart';
import 'relatorios_screen.dart';

/// Tela inicial: resumo do mês, vendas dos últimos 7 dias e produtos mais vendidos.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with DataReloadMixin<DashboardScreen> {
  final EmpresaRepository _empresas = EmpresaRepository();
  final RelatorioRepository _relatorios = RelatorioRepository();

  bool _carregando = true;
  String? _erro;
  Empresa? _empresa;
  ResumoMes? _resumo;
  List<VendaDia> _dias = [];
  List<ProdutoRanking> _top = [];

  @override
  Future<void> carregar() async {
    try {
      final empresa = await _empresas.obter();
      final resumo = await _relatorios.resumoMes();
      final dias = await _relatorios.vendasPorDia(7);
      final ranking = await _relatorios.rankingProdutos(7);
      ranking.sort((a, b) => b.unidades.compareTo(a.unidades));
      if (!mounted) {
        return;
      }
      setState(() {
        _empresa = empresa;
        _resumo = resumo;
        _dias = dias;
        _top = ranking.take(3).toList();
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

  void _novoPedido() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const PedidoFormScreen()),
    );
  }

  void _abrirRelatorios() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const RelatoriosScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vitrine')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo pedido',
        onPressed: _novoPedido,
        child: const Icon(Icons.add),
      ),
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
    final resumo = _resumo;
    final empresa = _empresa;
    if (resumo == null || empresa == null) {
      return const SizedBox.shrink();
    }
    final agora = DateTime.now();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        Text(
          'Olá, ${empresa.nome}!',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          'Resumo de ${kMeses[agora.month - 1]}/${agora.year}',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.7,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            StatCard(rotulo: 'Vendas no mês', valor: formatMoney(resumo.faturamentoCentavos)),
            StatCard(rotulo: 'Pedidos pagos', valor: '${resumo.pedidos}'),
            StatCard(rotulo: 'Ticket médio', valor: formatMoney(resumo.ticketMedioCentavos)),
            StatCard(rotulo: 'Novos clientes', valor: '${resumo.novosClientes}'),
          ],
        ),
        const SectionTitle('Vendas dos últimos 7 dias'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: GraficoBarras(
              valores: _dias.map((d) => d.totalCentavos).toList(),
              rotulos: _dias.map((d) => diaSemanaCurto(d.dia)).toList(),
            ),
          ),
        ),
        const SectionTitle('Top 3 produtos (7 dias)'),
        if (_top.isEmpty)
          Text(
            'Ainda não há vendas pagas neste período.',
            style: TextStyle(color: Colors.grey.shade700),
          )
        else
          for (var i = 0; i < _top.length; i++)
            Card(
              child: ListTile(
                dense: true,
                title: Text('${i + 1}. ${_top[i].nome}'),
                trailing: Text('${_top[i].unidades} un.'),
              ),
            ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _abrirRelatorios,
          child: const Text('Ver relatórios completos'),
        ),
      ],
    );
  }
}
