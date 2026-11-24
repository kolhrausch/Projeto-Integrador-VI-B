import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/exceptions.dart';
import '../core/format.dart';
import '../models/empresa.dart';
import '../providers/app_state.dart';
import '../repositories/empresa_repository.dart';
import '../services/catalogo_service.dart';
import '../services/foto_service.dart';
import '../widgets/common.dart';

/// "Minha vitrine digital": dados públicos do negócio e atalhos de divulgação (RF04 a RF06).
class VitrineScreen extends StatefulWidget {
  const VitrineScreen({super.key});

  @override
  State<VitrineScreen> createState() => _VitrineScreenState();
}

class _VitrineScreenState extends State<VitrineScreen> {
  final EmpresaRepository _repo = EmpresaRepository();

  final TextEditingController _nome = TextEditingController();
  final TextEditingController _slogan = TextEditingController();
  final TextEditingController _whatsapp = TextEditingController();
  final TextEditingController _instagram = TextEditingController();
  final TextEditingController _horario = TextEditingController();

  String? _logoPath;
  int _compartilhamentosNoMes = 0;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _nome.dispose();
    _slogan.dispose();
    _whatsapp.dispose();
    _instagram.dispose();
    _horario.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final empresa = await _repo.obter();
    final total = await _repo.divulgacoesNoMes();
    if (!mounted) {
      return;
    }
    setState(() {
      _nome.text = empresa.nome;
      _slogan.text = empresa.slogan ?? '';
      _whatsapp.text = empresa.whatsapp ?? '';
      _instagram.text = empresa.instagram ?? '';
      _horario.text = empresa.horarioAtendimento ?? '';
      _logoPath = empresa.logoPath;
      _compartilhamentosNoMes = total;
      _carregando = false;
    });
  }

  Future<void> _escolherLogo() async {
    final origem = await escolherOrigemFoto(context);
    if (origem == null) {
      return;
    }
    try {
      final caminho = await FotoService.escolher(origem);
      if (caminho != null && mounted) {
        setState(() => _logoPath = caminho);
      }
    } catch (e) {
      if (mounted) {
        mostrarMensagem(context, mensagemErro(e));
      }
    }
  }

  Future<void> _salvar() async {
    final nome = _nome.text.trim();
    if (nome.isEmpty) {
      mostrarMensagem(context, 'Informe o nome do negócio.');
      return;
    }
    try {
      await _repo.salvar(Empresa(
        nome: nome,
        slogan: textoOuNulo(_slogan.text),
        whatsapp: textoOuNulo(_whatsapp.text),
        instagram: textoOuNulo(_instagram.text),
        horarioAtendimento: textoOuNulo(_horario.text),
        logoPath: _logoPath,
      ));
      if (!mounted) {
        return;
      }
      context.read<AppState>().dadosAlterados();
      mostrarMensagem(context, 'Dados da vitrine salvos.');
    } catch (e) {
      if (mounted) {
        mostrarMensagem(context, mensagemErro(e));
      }
    }
  }

  Future<void> _compartilhar(String canal) async {
    try {
      await _salvarSilencioso();
      await CatalogoService.compartilhar(canal);
      final total = await _repo.divulgacoesNoMes();
      if (!mounted) {
        return;
      }
      setState(() => _compartilhamentosNoMes = total);
      context.read<AppState>().dadosAlterados();
    } catch (e) {
      if (mounted) {
        mostrarMensagem(context, mensagemErro(e));
      }
    }
  }

  /// Garante que o texto compartilhado use os dados que estão na tela.
  Future<void> _salvarSilencioso() async {
    final nome = _nome.text.trim();
    if (nome.isEmpty) {
      return;
    }
    await _repo.salvar(Empresa(
      nome: nome,
      slogan: textoOuNulo(_slogan.text),
      whatsapp: textoOuNulo(_whatsapp.text),
      instagram: textoOuNulo(_instagram.text),
      horarioAtendimento: textoOuNulo(_horario.text),
      logoPath: _logoPath,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final logo = _logoPath;
    return Scaffold(
      appBar: AppBar(title: const Text('Minha vitrine digital')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _escolherLogo,
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: logo == null ? null : FileImage(File(logo)),
                      child: logo == null
                          ? Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade600)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Toque para escolher o logotipo',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nome,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nome do negócio *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _slogan,
                  decoration: const InputDecoration(labelText: 'Slogan'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _whatsapp,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'WhatsApp'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _instagram,
                  decoration: const InputDecoration(labelText: 'Instagram'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _horario,
                  decoration: const InputDecoration(labelText: 'Horário de atendimento'),
                ),
                const SectionTitle('Compartilhar catálogo via'),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _compartilhar('WHATSAPP'),
                        child: const Text('WhatsApp'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _compartilhar('INSTAGRAM'),
                        child: const Text('Instagram'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _compartilhar('OUTRO'),
                        child: const Text('Outros'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Compartilhamentos registrados este mês: $_compartilhamentosNoMes',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _salvar,
                  child: const Text('Salvar alterações'),
                ),
              ],
            ),
    );
  }
}
