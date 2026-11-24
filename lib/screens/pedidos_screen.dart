import 'package:flutter/material.dart';

import '../core/exceptions.dart';
import '../core/format.dart';
import '../models/pedido.dart';
import '../repositories/pedido_repository.dart';
import '../widgets/common.dart';
import 'pedido_detalhe_screen.dart';
import 'pedido_form_screen.dart';

/// Histórico de pedidos com filtro por status (RF11).
class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen>
    with DataReloadMixin<PedidosScreen> {
  static const List<String> _opcoes = ['Todos', 'Abertos', 'Pagos', 'Cancelados'];
  static const List<String?> _statusPorFiltro = [
    null,
    StatusPedido.aberto,
    StatusPedido.pago,
    StatusPedido.cancelado,
  ];

  final PedidoRepository _repo = PedidoRepository();

  List<Pedido> _pedidos = [];
  int _filtro = 0;
  bool _carregando = true;
  String? _erro;

  @override
  Future<void> carregar() async {
    try {
      final pedidos = await _repo.listar();
      if (!mounted) {
        return;
      }
      setState(() {
        _pedidos = pedidos;
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

  List<Pedido> get _filtrados {
    final status = _statusPorFiltro[_filtro];
    if (status == null) {
      return _pedidos;
    }
    return _pedidos.where((p) => p.status == status).toList();
  }

  void _novoPedido() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const PedidoFormScreen()),
    );
  }

  void _abrirDetalhe(Pedido pedido) {
    final id = pedido.id;
    if (id == null) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => PedidoDetalheScreen(pedidoId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo pedido',
        onPressed: _novoPedido,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          FiltroChips(
            opcoes: _opcoes,
            selecionado: _filtro,
            aoSelecionar: (indice) => setState(() => _filtro = indice),
          ),
          const SizedBox(height: 8),
          Expanded(child: _corpo()),
        ],
      ),
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
    final lista = _filtrados;
    if (lista.isEmpty) {
      return const EstadoVazio(
        icone: Icons.receipt_long_outlined,
        mensagem: 'Nenhum pedido por aqui.\nToque em + para registrar uma venda.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      itemCount: lista.length,
      itemBuilder: (context, indice) {
        final pedido = lista[indice];
        final numero = (pedido.id ?? 0).toString().padLeft(4, '0');
        return Card(
          child: ListTile(
            onTap: () => _abrirDetalhe(pedido),
            title: Text(
              '#$numero  ${pedido.clienteNome ?? 'Sem cadastro'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${formatDateTime(pedido.dataPedido)} - ${FormaPagamento.rotulo(pedido.formaPagamento)}',
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatMoney(pedido.totalCentavos),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Etiqueta(StatusPedido.rotulo(pedido.status)),
              ],
            ),
          ),
        );
      },
    );
  }
}
