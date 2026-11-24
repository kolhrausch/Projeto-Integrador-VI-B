import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/exceptions.dart';
import '../core/format.dart';
import '../models/item_pedido.dart';
import '../models/pedido.dart';
import '../providers/app_state.dart';
import '../repositories/pedido_repository.dart';
import '../widgets/common.dart';

/// Detalhes de um pedido: itens, totais e ações (marcar como pago / cancelar).
class PedidoDetalheScreen extends StatefulWidget {
  const PedidoDetalheScreen({super.key, required this.pedidoId});

  final int pedidoId;

  @override
  State<PedidoDetalheScreen> createState() => _PedidoDetalheScreenState();
}

class _PedidoDetalheScreenState extends State<PedidoDetalheScreen>
    with DataReloadMixin<PedidoDetalheScreen> {
  final PedidoRepository _repo = PedidoRepository();

  Pedido? _pedido;
  List<ItemPedido> _itens = [];
  bool _carregando = true;
  String? _erro;

  @override
  Future<void> carregar() async {
    try {
      final pedido = await _repo.obter(widget.pedidoId);
      final itens = await _repo.itens(widget.pedidoId);
      if (!mounted) {
        return;
      }
      setState(() {
        _pedido = pedido;
        _itens = itens;
        _erro = pedido == null ? 'Pedido não encontrado.' : null;
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

  Future<void> _marcarComoPago() async {
    try {
      await _repo.marcarComoPago(widget.pedidoId);
      if (!mounted) {
        return;
      }
      context.read<AppState>().dadosAlterados();
      mostrarMensagem(context, 'Pedido marcado como pago.');
    } catch (e) {
      if (mounted) {
        mostrarMensagem(context, mensagemErro(e));
      }
    }
  }

  Future<void> _cancelar() async {
    final ok = await confirmar(
      context,
      titulo: 'Cancelar pedido',
      mensagem: 'O pedido será cancelado e os itens voltarão ao estoque.',
      textoConfirmar: 'Cancelar pedido',
    );
    if (!ok || !mounted) {
      return;
    }
    try {
      await _repo.cancelar(widget.pedidoId);
      if (!mounted) {
        return;
      }
      context.read<AppState>().dadosAlterados();
      mostrarMensagem(context, 'Pedido cancelado.');
    } catch (e) {
      if (mounted) {
        mostrarMensagem(context, mensagemErro(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final numero = widget.pedidoId.toString().padLeft(4, '0');
    return Scaffold(
      appBar: AppBar(title: Text('Pedido #$numero')),
      body: _corpo(),
    );
  }

  Widget _corpo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    final erro = _erro;
    final pedido = _pedido;
    if (erro != null || pedido == null) {
      return EstadoVazio(
        icone: Icons.error_outline,
        mensagem: erro ?? 'Pedido não encontrado.',
      );
    }
    final subtotal = pedido.totalCentavos + pedido.descontoCentavos;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pedido.clienteNome ?? 'Venda sem cadastro',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Etiqueta(StatusPedido.rotulo(pedido.status)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Data: ${formatDateTime(pedido.dataPedido)}'),
                Text('Pagamento: ${FormaPagamento.rotulo(pedido.formaPagamento)}'),
              ],
            ),
          ),
        ),
        const SectionTitle('Itens'),
        for (final item in _itens)
          Card(
            child: ListTile(
              title: Text(item.produtoNome ?? 'Produto'),
              subtitle: Text('${item.quantidade} x ${formatMoney(item.precoUnitCentavos)}'),
              trailing: Text(
                formatMoney(item.subtotalCentavos),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        const SizedBox(height: 8),
        _linhaTotal('Subtotal', formatMoney(subtotal)),
        _linhaTotal('Desconto', '- ${formatMoney(pedido.descontoCentavos)}'),
        _linhaTotal('Total', formatMoney(pedido.totalCentavos), destaque: true),
        const SizedBox(height: 16),
        if (pedido.status == StatusPedido.aberto)
          FilledButton.icon(
            onPressed: _marcarComoPago,
            icon: const Icon(Icons.check),
            label: const Text('Marcar como pago'),
          ),
        if (pedido.status != StatusPedido.cancelado) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _cancelar,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancelar pedido'),
          ),
        ],
      ],
    );
  }

  Widget _linhaTotal(String rotulo, String valor, {bool destaque = false}) {
    final estilo = TextStyle(
      fontSize: destaque ? 18 : 14,
      fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(rotulo, style: estilo), Text(valor, style: estilo)],
      ),
    );
  }
}
