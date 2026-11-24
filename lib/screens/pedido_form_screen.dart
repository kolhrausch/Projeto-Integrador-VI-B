import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/exceptions.dart';
import '../core/format.dart';
import '../models/cliente.dart';
import '../models/item_pedido.dart';
import '../models/pedido.dart';
import '../models/produto.dart';
import '../providers/app_state.dart';
import '../repositories/cliente_repository.dart';
import '../repositories/pedido_repository.dart';
import '../repositories/produto_repository.dart';
import '../widgets/common.dart';
import 'cliente_form_screen.dart';

class _LinhaPedido {
  _LinhaPedido(this.produto, this.quantidade);

  final Produto produto;
  int quantidade;

  int get subtotalCentavos => quantidade * produto.precoCentavos;
}

/// Registro de um novo pedido (RF08, RF09, RF10).
class PedidoFormScreen extends StatefulWidget {
  const PedidoFormScreen({super.key});

  @override
  State<PedidoFormScreen> createState() => _PedidoFormScreenState();
}

class _PedidoFormScreenState extends State<PedidoFormScreen> {
  final PedidoRepository _pedidos = PedidoRepository();
  final ClienteRepository _clientesRepo = ClienteRepository();
  final ProdutoRepository _produtosRepo = ProdutoRepository();
  final TextEditingController _descontoController = TextEditingController();

  List<Cliente> _clientes = [];
  List<Produto> _disponiveis = [];
  final List<_LinhaPedido> _linhas = [];
  int? _clienteId;
  String _pagamento = 'PIX';
  bool _pago = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _descontoController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    final clientes = await _clientesRepo.listar();
    final produtos = await _produtosRepo.paraVenda();
    if (!mounted) {
      return;
    }
    setState(() {
      _clientes = clientes;
      _disponiveis = produtos;
    });
  }

  int get _subtotal => _linhas.fold<int>(0, (soma, l) => soma + l.subtotalCentavos);

  int get _desconto => parseMoneyToCents(_descontoController.text) ?? 0;

  int get _total {
    final valor = _subtotal - _desconto;
    return valor < 0 ? 0 : valor;
  }

  Future<void> _adicionarItem() async {
    if (_disponiveis.isEmpty) {
      mostrarMensagem(context, 'Nenhum produto ativo com estoque disponível.');
      return;
    }
    final escolhido = await showModalBottomSheet<Produto>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text('Escolha o produto',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final produto in _disponiveis)
              ListTile(
                title: Text(produto.nome),
                subtitle: Text('Estoque: ${produto.estoque}'),
                trailing: Text(formatMoney(produto.precoCentavos)),
                onTap: () => Navigator.pop(ctx, produto),
              ),
          ],
        ),
      ),
    );
    if (escolhido == null || !mounted) {
      return;
    }
    final posicao = _linhas.indexWhere((l) => l.produto.id == escolhido.id);
    setState(() {
      if (posicao < 0) {
        _linhas.add(_LinhaPedido(escolhido, 1));
      } else if (_linhas[posicao].quantidade < escolhido.estoque) {
        _linhas[posicao].quantidade += 1;
      } else {
        mostrarMensagem(context, 'Estoque máximo atingido (${escolhido.estoque}).');
      }
    });
  }

  void _aumentar(_LinhaPedido linha) {
    if (linha.quantidade >= linha.produto.estoque) {
      mostrarMensagem(context, 'Estoque máximo atingido (${linha.produto.estoque}).');
      return;
    }
    setState(() => linha.quantidade += 1);
  }

  void _diminuir(_LinhaPedido linha) {
    setState(() {
      if (linha.quantidade <= 1) {
        _linhas.remove(linha);
      } else {
        linha.quantidade -= 1;
      }
    });
  }

  Future<void> _novoCliente() async {
    final novoId = await Navigator.push<int>(
      context,
      MaterialPageRoute<int>(builder: (_) => const ClienteFormScreen()),
    );
    if (!mounted) {
      return;
    }
    final clientes = await _clientesRepo.listar();
    if (!mounted) {
      return;
    }
    setState(() {
      _clientes = clientes;
      if (novoId != null) {
        _clienteId = novoId;
      }
    });
  }

  Future<void> _finalizar() async {
    final texto = _descontoController.text.trim();
    final desconto = texto.isEmpty ? 0 : parseMoneyToCents(texto);
    if (desconto == null) {
      mostrarMensagem(context, 'Desconto inválido.');
      return;
    }
    final itens = _linhas
        .map((l) => ItemPedido(
              produtoId: l.produto.id ?? 0,
              quantidade: l.quantidade,
              precoUnitCentavos: l.produto.precoCentavos,
            ))
        .toList();
    setState(() => _salvando = true);
    try {
      await _pedidos.criar(
        clienteId: _clienteId,
        itens: itens,
        descontoCentavos: desconto,
        formaPagamento: _pagamento,
        pago: _pago,
      );
      if (!mounted) {
        return;
      }
      context.read<AppState>().dadosAlterados();
      final mensagens = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      mensagens.showSnackBar(
        const SnackBar(content: Text('Pedido registrado com sucesso.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _salvando = false);
      mostrarMensagem(context, mensagemErro(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo pedido')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _clienteId,
                  decoration: const InputDecoration(labelText: 'Cliente'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Venda sem cadastro'),
                    ),
                    for (final c in _clientes)
                      DropdownMenuItem<int?>(value: c.id, child: Text(c.nome)),
                  ],
                  onChanged: (valor) => setState(() => _clienteId = valor),
                ),
              ),
              IconButton(
                tooltip: 'Novo cliente',
                icon: const Icon(Icons.person_add_alt_1_outlined),
                onPressed: _novoCliente,
              ),
            ],
          ),
          const SectionTitle('Itens do pedido'),
          if (_linhas.isEmpty)
            Text(
              'Nenhum item adicionado.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          for (final linha in _linhas)
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            linha.produto.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            formatMoney(linha.produto.precoCentavos),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Diminuir',
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => _diminuir(linha),
                    ),
                    Text('${linha.quantidade}'),
                    IconButton(
                      tooltip: 'Aumentar',
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => _aumentar(linha),
                    ),
                    Text(
                      formatMoney(linha.subtotalCentavos),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _adicionarItem,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar item'),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _descontoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Desconto (R\$)',
                    hintText: '0,00',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _pagamento,
                  decoration: const InputDecoration(labelText: 'Pagamento'),
                  items: [
                    for (final forma in FormaPagamento.todas)
                      DropdownMenuItem<String>(
                        value: forma,
                        child: Text(FormaPagamento.rotulo(forma)),
                      ),
                  ],
                  onChanged: (valor) {
                    if (valor != null) {
                      setState(() => _pagamento = valor);
                    }
                  },
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pedido já pago'),
            subtitle: const Text('Desligue para deixar o pedido em aberto'),
            value: _pago,
            onChanged: (valor) => setState(() => _pago = valor),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                formatMoney(_total),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (_salvando || _linhas.isEmpty) ? null : _finalizar,
            child: Text(_salvando ? 'Salvando...' : 'Finalizar pedido'),
          ),
        ],
      ),
    );
  }
}
