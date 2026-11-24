import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/exceptions.dart';
import '../providers/app_state.dart';
import '../repositories/demo_data.dart';
import '../services/export_service.dart';
import '../widgets/common.dart';
import 'relatorios_screen.dart';
import 'sobre_screen.dart';
import 'vitrine_screen.dart';

/// Aba "Mais": relatórios, vitrine, sobre e ferramentas de dados.
class MaisScreen extends StatelessWidget {
  const MaisScreen({super.key});

  void _abrir(BuildContext context, Widget tela) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => tela));
  }

  Future<void> _carregarDemo(BuildContext context) async {
    final estado = context.read<AppState>();
    final ok = await confirmar(
      context,
      titulo: 'Carregar dados de demonstração',
      mensagem:
          'Isso substitui os produtos, clientes e pedidos atuais por dados fictícios para testar o app. Continuar?',
      textoConfirmar: 'Carregar',
    );
    if (!ok || !context.mounted) {
      return;
    }
    try {
      await DemoData.carregar();
      estado.dadosAlterados();
      if (context.mounted) {
        mostrarMensagem(context, 'Dados de demonstração carregados.');
      }
    } catch (e) {
      if (context.mounted) {
        mostrarMensagem(context, mensagemErro(e));
      }
    }
  }

  Future<void> _limpar(BuildContext context) async {
    final estado = context.read<AppState>();
    final ok = await confirmar(
      context,
      titulo: 'Apagar todos os dados',
      mensagem: 'Produtos, clientes, pedidos e divulgações serão apagados. Esta ação não pode ser desfeita.',
      textoConfirmar: 'Apagar tudo',
    );
    if (!ok || !context.mounted) {
      return;
    }
    try {
      await DemoData.limparTudo();
      estado.dadosAlterados();
      if (context.mounted) {
        mostrarMensagem(context, 'Dados apagados.');
      }
    } catch (e) {
      if (context.mounted) {
        mostrarMensagem(context, mensagemErro(e));
      }
    }
  }

  Future<void> _backup(BuildContext context) async {
    try {
      await ExportService.compartilharBanco();
    } catch (e) {
      if (context.mounted) {
        mostrarMensagem(context, mensagemErro(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mais')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Relatórios'),
            subtitle: const Text('Vendas, curva ABC, clientes e divulgação'),
            onTap: () => _abrir(context, const RelatoriosScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Minha vitrine digital'),
            subtitle: const Text('Dados do negócio e compartilhamento'),
            onTap: () => _abrir(context, const VitrineScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Sobre o app'),
            subtitle: const Text('Integrantes do grupo'),
            onTap: () => _abrir(context, const SobreScreen()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.science_outlined),
            title: const Text('Carregar dados de demonstração'),
            subtitle: const Text('Preenche o app com dados fictícios'),
            onTap: () => _carregarDemo(context),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Backup do banco de dados'),
            subtitle: const Text('Compartilha o arquivo vitrine.db'),
            onTap: () => _backup(context),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: Colors.red.shade700),
            title: Text('Apagar todos os dados', style: TextStyle(color: Colors.red.shade700)),
            onTap: () => _limpar(context),
          ),
        ],
      ),
    );
  }
}
