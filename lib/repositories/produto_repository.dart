import 'package:sqflite/sqflite.dart';

import '../core/exceptions.dart';
import '../database/database_helper.dart';
import '../database/queries.dart';
import '../models/categoria.dart';
import '../models/produto.dart';

/// Operações de produtos e categorias (tabelas `produto` e `categoria`).
class ProdutoRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<List<Produto>> listar({int? categoriaId, String busca = ''}) async {
    final db = await _helper.database;
    final termo = '%${busca.trim()}%';
    final linhas = categoriaId == null
        ? await db.rawQuery(Queries.produtosBusca, [termo])
        : await db.rawQuery(Queries.produtosBuscaCategoria, [categoriaId, termo]);
    return linhas.map(Produto.fromMap).toList();
  }

  /// Produtos ativos, agrupáveis por categoria (usado no catálogo compartilhado).
  Future<List<Produto>> catalogo() async {
    final db = await _helper.database;
    final linhas = await db.rawQuery(Queries.produtosCatalogo);
    return linhas.map(Produto.fromMap).toList();
  }

  /// Produtos ativos com estoque (escolha de itens ao criar um pedido).
  Future<List<Produto>> paraVenda() async {
    final db = await _helper.database;
    final linhas = await db.rawQuery(Queries.produtosParaVenda);
    return linhas.map(Produto.fromMap).toList();
  }

  Future<int> inserir(Produto produto) async {
    final db = await _helper.database;
    return db.insert('produto', produto.toMap());
  }

  Future<void> atualizar(Produto produto) async {
    final db = await _helper.database;
    await db.update(
      'produto',
      produto.toMap(),
      where: 'id = ?',
      whereArgs: [produto.id],
    );
  }

  /// RN06: produto com vendas não pode ser excluído, apenas desativado.
  Future<void> excluir(int id) async {
    final db = await _helper.database;
    final linhas = await db.rawQuery(Queries.contarItensDoProduto, [id]);
    final vendas = (linhas.first['n'] as num).toInt();
    if (vendas > 0) {
      throw const RegraNegocioException(
          'Este produto já tem vendas e não pode ser excluído. Desative-o para tirá-lo do catálogo.');
    }
    await db.delete('produto', where: 'id = ?', whereArgs: [id]);
  }

  // -------------------------------------------------------------- categorias

  Future<List<Categoria>> categorias() async {
    final db = await _helper.database;
    final linhas = await db.rawQuery(Queries.categoriasAtivas);
    return linhas.map(Categoria.fromMap).toList();
  }

  Future<int> inserirCategoria(String nome) async {
    final limpo = nome.trim();
    if (limpo.isEmpty) {
      throw const RegraNegocioException('Informe o nome da categoria.');
    }
    final db = await _helper.database;
    final existentes = await db.rawQuery(Queries.categoriaPorNome, [limpo]);
    if (existentes.isNotEmpty) {
      throw const RegraNegocioException('Já existe uma categoria com esse nome.');
    }
    return db.insert('categoria', Categoria(nome: limpo).toMap());
  }

  Future<int> contarProdutos() async {
    final db = await _helper.database;
    final total = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM produto'));
    return total ?? 0;
  }
}
