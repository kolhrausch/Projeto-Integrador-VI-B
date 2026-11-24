import 'package:flutter/material.dart';

import '../core/exceptions.dart';
import '../core/format.dart';
import '../core/rules.dart';
import '../repositories/cliente_repository.dart';
import '../repositories/relatorio_repository.dart';
import '../widgets/common.dart';
import 'cliente_form_screen.dart';

/// Lista de clientes com busca e etiqueta de perfil (RF07, RF16).
class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen>
    with DataReloadMixin<ClientesScreen> {
  final RelatorioRepository _relatorios = RelatorioRepository();
  final ClienteRepository _clientes = ClienteRepository();
  final TextEditingController _buscaController = TextEditingController();

  List<ClientePerfil> _todos = [];
  bool _carregando = true;
  String? _erro;

  @override
  Future<void> carregar() async {
    try {
      final lista = await _relatorios.perfilClientes();
      if (!mounted) {
        return;
      }
      setState(() {
        _todos = lista;
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

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  List<ClientePerfil> get _filtrados {
    final termo = _buscaController.text.trim().toLowerCase();
    if (termo.isEmpty) {
      return _todos;
    }
    return _todos.where((c) {
      final telefone = c.telefone ?? '';
      return c.nome.toLowerCase().contains(termo) || telefone.contains(termo);
    }).toList();
  }

  Future<void> _abrir([int? clienteId]) async {
    final cliente = clienteId == null ? null : await _clientes.obter(clienteId);
    if (!mounted) {
      return;
    }
    await Navigator.push<int>(
      context,
      MaterialPageRoute<int>(builder: (_) => ClienteFormScreen(cliente: cliente)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo cliente',
        onPressed: () => _abrir(),
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _buscaController,
              decoration: const InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
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
        icone: Icons.people_outline,
        mensagem: 'Nenhum cliente encontrado.\nToque no botão para cadastrar.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      itemCount: lista.length,
      itemBuilder: (context, indice) {
        final cliente = lista[indice];
        final telefone = cliente.telefone;
        return Card(
          child: ListTile(
            onTap: () => _abrir(cliente.id),
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: Text(
                cliente.nome.isEmpty ? '?' : cliente.nome.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: kCorPrincipal),
              ),
            ),
            title: Text(cliente.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${temTexto(telefone) ? telefone : 'Sem telefone'} - ${cliente.totalPedidos} pedido(s)',
            ),
            trailing: Etiqueta(cliente.perfil.rotulo),
          ),
        );
      },
    );
  }
}
