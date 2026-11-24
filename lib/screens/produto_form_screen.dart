import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/exceptions.dart';
import '../core/format.dart';
import '../models/categoria.dart';
import '../models/produto.dart';
import '../providers/app_state.dart';
import '../repositories/produto_repository.dart';
import '../services/foto_service.dart';
import '../widgets/common.dart';

/// Cadastro e edição de produto (RF01).
class ProdutoFormScreen extends StatefulWidget {
  const ProdutoFormScreen({super.key, this.produto});

  /// Produto a editar; null para cadastrar um novo.
  final Produto? produto;

  @override
  State<ProdutoFormScreen> createState() => _ProdutoFormScreenState();
}

class _ProdutoFormScreenState extends State<ProdutoFormScreen> {
  final ProdutoRepository _repo = ProdutoRepository();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nome;
  late final TextEditingController _descricao;
  late final TextEditingController _preco;
  late final TextEditingController _estoque;

  List<Categoria> _categorias = [];
  int? _categoriaId;
  bool _ativo = true;
  String? _fotoPath;
  bool _salvando = false;

  bool get _editando => widget.produto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.produto;
    _nome = TextEditingController(text: p?.nome ?? '');
    _descricao = TextEditingController(text: p?.descricao ?? '');
    _preco = TextEditingController(
      text: p == null ? '' : formatMoney(p.precoCentavos).replaceFirst('R\$ ', ''),
    );
    _estoque = TextEditingController(text: p == null ? '' : '${p.estoque}');
    _categoriaId = p?.categoriaId;
    _ativo = p?.ativo ?? true;
    _fotoPath = p?.fotoPath;
    _carregarCategorias();
  }

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    _preco.dispose();
    _estoque.dispose();
    super.dispose();
  }

  Future<void> _carregarCategorias() async {
    final categorias = await _repo.categorias();
    if (!mounted) {
      return;
    }
    setState(() => _categorias = categorias);
  }

  Future<void> _escolherFoto() async {
    final origem = await escolherOrigemFoto(context);
    if (origem == null) {
      return;
    }
    try {
      final caminho = await FotoService.escolher(origem);
      if (caminho != null && mounted) {
        setState(() => _fotoPath = caminho);
      }
    } catch (e) {
      if (mounted) {
        mostrarMensagem(context, 'Não foi possível obter a foto: ${mensagemErro(e)}');
      }
    }
  }

  Future<void> _novaCategoria() async {
    final controller = TextEditingController();
    final nome = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova categoria'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome da categoria'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (nome == null || !mounted) {
      return;
    }
    try {
      final id = await _repo.inserirCategoria(nome);
      final categorias = await _repo.categorias();
      if (!mounted) {
        return;
      }
      setState(() {
        _categorias = categorias;
        _categoriaId = id;
      });
    } catch (e) {
      if (mounted) {
        mostrarMensagem(context, mensagemErro(e));
      }
    }
  }

  Future<void> _salvar() async {
    final formulario = _formKey.currentState;
    if (formulario == null || !formulario.validate()) {
      return;
    }
    final preco = parseMoneyToCents(_preco.text);
    final estoque = int.tryParse(_estoque.text.trim());
    if (preco == null || estoque == null) {
      return;
    }
    setState(() => _salvando = true);
    try {
      final existente = widget.produto;
      final produto = Produto(
        id: existente?.id,
        categoriaId: _categoriaId,
        nome: _nome.text.trim(),
        descricao: textoOuNulo(_descricao.text),
        precoCentavos: preco,
        estoque: estoque,
        fotoPath: _fotoPath,
        ativo: _ativo,
        criadoEm: existente?.criadoEm ?? isoNow(),
      );
      if (existente == null) {
        await _repo.inserir(produto);
      } else {
        await _repo.atualizar(produto);
      }
      if (!mounted) {
        return;
      }
      context.read<AppState>().dadosAlterados();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _salvando = false);
      mostrarMensagem(context, mensagemErro(e));
    }
  }

  Future<void> _excluir() async {
    final id = widget.produto?.id;
    if (id == null) {
      return;
    }
    final ok = await confirmar(
      context,
      titulo: 'Excluir produto',
      mensagem: 'Deseja excluir "${widget.produto?.nome}"?',
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
    final foto = _fotoPath;
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar produto' : 'Novo produto'),
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
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 96,
                    height: 96,
                    color: Colors.grey.shade200,
                    child: foto == null
                        ? Icon(Icons.image_outlined, size: 36, color: Colors.grey.shade500)
                        : Image.file(
                            File(foto),
                            fit: BoxFit.cover,
                            errorBuilder: (context, erro, pilha) =>
                                const Icon(Icons.broken_image_outlined),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Foto do produto',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _escolherFoto,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Escolher foto'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nome,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nome *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o nome do produto' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descricao,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _preco,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Preço (R\$) *',
                      hintText: '0,00',
                    ),
                    validator: (v) =>
                        parseMoneyToCents(v ?? '') == null ? 'Preço inválido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _estoque,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Estoque *'),
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      return (n == null || n < 0) ? 'Estoque inválido' : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _categoriaId,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Sem categoria'),
                      ),
                      for (final c in _categorias)
                        DropdownMenuItem<int?>(value: c.id, child: Text(c.nome)),
                    ],
                    onChanged: (valor) => setState(() => _categoriaId = valor),
                  ),
                ),
                IconButton(
                  tooltip: 'Nova categoria',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _novaCategoria,
                ),
              ],
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visível no catálogo'),
              value: _ativo,
              onChanged: (valor) => setState(() => _ativo = valor),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _salvando ? null : _salvar,
              child: Text(_salvando ? 'Salvando...' : 'Salvar produto'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
