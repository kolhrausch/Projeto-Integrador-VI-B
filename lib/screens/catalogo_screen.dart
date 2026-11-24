import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/exceptions.dart';
import '../core/format.dart';
import '../models/categoria.dart';
import '../models/produto.dart';
import '../providers/app_state.dart';
import '../repositories/produto_repository.dart';
import '../services/catalogo_service.dart';
import '../widgets/common.dart';
import 'produto_form_screen.dart';

/// Catálogo digital: busca, filtro por categoria e compartilhamento.
class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen>
    with DataReloadMixin<CatalogoScreen> {
  final ProdutoRepository _repo = ProdutoRepository();
  final TextEditingController _buscaController = TextEditingController();

  List<Produto> _produtos = [];
  List<Categoria> _categorias = [];
  int? _categoriaId;
  bool _carregando = true;
  String? _erro;

  @override
  Future<void> carregar() async {
    try {
      final categorias = await _repo.categorias();
      final produtos = await _repo.listar(
        categoriaId: _categoriaId,
        busca: _buscaController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _categorias = categorias;
        _produtos = produtos;
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

  Future<void> _abrirFormulario([Produto? produto]) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => ProdutoFormScreen(produto: produto)),
    );
  }

  Future<void> _compartilhar() async {
    final canal = await escolherCanal(context);
    if (canal == null || !mounted) {
      return;
    }
    try {
      await CatalogoService.compartilhar(canal);
      if (!mounted) {
        return;
      }
      context.read<AppState>().dadosAlterados();
    } catch (e) {
      if (!mounted) {
        return;
      }
      mostrarMensagem(context, mensagemErro(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          IconButton(
            tooltip: 'Compartilhar catálogo',
            icon: const Icon(Icons.share),
            onPressed: _compartilhar,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo produto',
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _buscaController,
              decoration: const InputDecoration(
                hintText: 'Buscar produto...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (_) => carregar(),
            ),
          ),
          FiltroChips(
            opcoes: ['Todos', ..._categorias.map((c) => c.nome)],
            selecionado: _indiceSelecionado(),
            aoSelecionar: (indice) {
              setState(() {
                _categoriaId = indice == 0 ? null : _categorias[indice - 1].id;
              });
              carregar();
            },
          ),
          const SizedBox(height: 8),
          Expanded(child: _corpo()),
        ],
      ),
    );
  }

  int _indiceSelecionado() {
    if (_categoriaId == null) {
      return 0;
    }
    final posicao = _categorias.indexWhere((c) => c.id == _categoriaId);
    return posicao < 0 ? 0 : posicao + 1;
  }

  Widget _corpo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    final erro = _erro;
    if (erro != null) {
      return EstadoVazio(icone: Icons.error_outline, mensagem: erro);
    }
    if (_produtos.isEmpty) {
      return const EstadoVazio(
        icone: Icons.storefront_outlined,
        mensagem: 'Nenhum produto encontrado.\nToque em + para cadastrar o primeiro.',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _produtos.length,
      itemBuilder: (context, indice) => _cartao(_produtos[indice]),
    );
  }

  Widget _cartao(Produto produto) {
    final foto = produto.fotoPath;
    final semFoto = Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, size: 40, color: Colors.grey.shade500),
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirFormulario(produto),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: foto == null
                    ? semFoto
                    : Image.file(
                        File(foto),
                        fit: BoxFit.cover,
                        errorBuilder: (context, erro, pilha) => semFoto,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produto.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(formatMoney(produto.precoCentavos)),
                  const SizedBox(height: 2),
                  Text(
                    produto.ativo ? 'Estoque: ${produto.estoque}' : 'Inativo',
                    style: TextStyle(
                      fontSize: 11,
                      color: produto.ativo && produto.estoque > 0
                          ? Colors.grey.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
