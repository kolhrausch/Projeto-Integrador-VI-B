import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/exceptions.dart';
import '../core/format.dart';
import '../models/cliente.dart';
import '../models/pedido.dart';
import '../providers/app_state.dart';
import '../repositories/cliente_repository.dart';
import '../repositories/pedido_repository.dart';
import '../widgets/common.dart';

/// Cadastro/edição de cliente, com o histórico de compras (RF07, RF12).
/// Ao salvar, devolve o id do cliente para quem abriu a tela.
class ClienteFormScreen extends StatefulWidget {
  const ClienteFormScreen({super.key, this.cliente});

  final Cliente? cliente;

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final ClienteRepository _repo = ClienteRepository();
  final PedidoRepository _pedidosRepo = PedidoRepository();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nome;
  late final TextEditingController _telefone;
  late final TextEditingController _email;
  late final TextEditingController _observacoes;

  List<Pedido> _historico = [];
  bool _salvando = false;

  bool get _editando => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    _nome = TextEditingController(text: c?.nome ?? '');
    _telefone = TextEditingController(text: c?.telefone ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _observacoes = TextEditingController(text: c?.observacoes ?? '');
    _carregarHistorico();
  }

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _email.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  Future<void> _carregarHistorico() async {
    final id = widget.cliente?.id;
    if (id == null) {
      return;
    }
    final pedidos = await _pedidosRepo.porCliente(id);
    if (!mounted) {
      return;
    }
    setState(() => _historico = pedidos);
  }

  Future<void> _salvar() async {
    final formulario = _formKey.currentState;
    if (formulario == null || !formulario.validate()) {
      return;
    }
    setState(() => _salvando = true);
    try {
      final existente = widget.cliente;
      final cliente = Cliente(
        id: existente?.id,
        nome: _nome.text.trim(),
        telefone: textoOuNulo(_telefone.text),
        email: textoOuNulo(_email.text),
        observacoes: textoOuNulo(_observacoes.text),
        criadoEm: existente?.criadoEm ?? isoNow(),
      );
      int id;
      if (existente == null) {
        id = await _repo.inserir(cliente);
      } else {
        await _repo.atualizar(cliente);
        id = existente.id ?? 0;
      }
      if (!mounted) {
        return;
      }
      context.read<AppState>().dadosAlterados();
      Navigator.pop(context, id);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _salvando = false);
      mostrarMensagem(context, mensagemErro(e));
    }
  }

  Future<void> _excluir() async {
    final id = widget.cliente?.id;
    if (id == null) {
      return;
    }
    final ok = await confirmar(
      context,
      titulo: 'Excluir cliente',
      mensagem: 'Os pedidos deste cliente serão mantidos, mas ficarão sem cadastro. Continuar?',
      textoConfirmar: 'Excluir',
    );
    if (!ok || !mounted) {
      return;
    }
    try {
      await _repo.excluir(id);
      if (!mounted) {
        return;
      }
      context.read<AppState>().dadosAlterados();
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        mostrarMensagem(context, mensagemErro(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar cliente' : 'Novo cliente'),
        actions: [
          if (_editando)
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline),
              onPressed: _excluir,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o nome do cliente' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefone'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail (opcional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observacoes,
              decoration: const InputDecoration(labelText: 'Observações'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _salvando ? null : _salvar,
              child: Text(_salvando ? 'Salvando...' : 'Salvar cliente'),
            ),
            if (_editando) ...[
              const SectionTitle('Histórico de compras'),
              if (_historico.isEmpty)
                Text(
                  'Este cliente ainda não tem pedidos.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              for (final pedido in _historico)
                Card(
                  child: ListTile(
                    dense: true,
                    title: Text(
                      '#${(pedido.id ?? 0).toString().padLeft(4, '0')} - ${formatDate(pedido.dataPedido)}',
                    ),
                    subtitle: Text(StatusPedido.rotulo(pedido.status)),
                    trailing: Text(
                      formatMoney(pedido.totalCentavos),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
