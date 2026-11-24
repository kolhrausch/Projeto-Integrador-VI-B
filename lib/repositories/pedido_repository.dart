import '../core/exceptions.dart';
import '../core/format.dart';
import '../database/database_helper.dart';
import '../database/queries.dart';
import '../models/item_pedido.dart';
import '../models/pedido.dart';

/// Operações de pedidos e itens (tabelas `pedido` e `item_pedido`).
class PedidoRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<List<Pedido>> listar() async {
    final db = await _helper.database;
    final linhas = await db.rawQuery(Queries.pedidosLista);
    return linhas.map(Pedido.fromMap).toList();
  }

  Future<Pedido?> obter(int id) async {
    final db = await _helper.database;
    final linhas = await db.rawQuery(Queries.pedidoPorId, [id]);
    if (linhas.isEmpty) {
      return null;
    }
    return Pedido.fromMap(linhas.first);
  }

  Future<List<Pedido>> porCliente(int clienteId) async {
    final db = await _helper.database;
    final linhas = await db.rawQuery(Queries.pedidosDoCliente, [clienteId]);
    return linhas.map(Pedido.fromMap).toList();
  }

  Future<List<ItemPedido>> itens(int pedidoId) async {
    final db = await _helper.database;
    final linhas = await db.rawQuery(Queries.itensDoPedido, [pedidoId]);
    return linhas.map(ItemPedido.fromMap).toList();
  }

  /// Cria o pedido, grava os itens e baixa o estoque em uma única transação:
  /// ou tudo é salvo, ou nada é salvo (RN01, RN02, RN04, RF09, RF10).
  Future<int> criar({
    int? clienteId,
    required List<ItemPedido> itens,
    required int descontoCentavos,
    String? formaPagamento,
    required bool pago,
  }) async {
    if (itens.isEmpty) {
      throw const RegraNegocioException('Adicione ao menos um item ao pedido.');
    }
    final produtosDistintos = itens.map((i) => i.produtoId).toSet();
    if (produtosDistintos.length != itens.length) {
      throw const RegraNegocioException('Há produtos repetidos no pedido.');
    }
    final subtotal = itens.fold<int>(0, (soma, i) => soma + i.subtotalCentavos);
    if (descontoCentavos < 0 || descontoCentavos > subtotal) {
      throw const RegraNegocioException(
          'O desconto não pode ser maior que o total dos itens.');
    }

    final db = await _helper.database;
    return db.transaction<int>((txn) async {
      for (final item in itens) {
        if (item.quantidade <= 0) {
          throw const RegraNegocioException('A quantidade deve ser maior que zero.');
        }
        final produto = await txn.query(
          'produto',
          columns: ['nome', 'estoque'],
          where: 'id = ?',
          whereArgs: [item.produtoId],
        );
        if (produto.isEmpty) {
          throw const RegraNegocioException('Produto não encontrado.');
        }
        final nome = produto.first['nome'] as String;
        final estoque = produto.first['estoque'] as int;
        if (item.quantidade > estoque) {
          throw RegraNegocioException(
              'Estoque insuficiente de "$nome" (disponível: $estoque).');
        }
      }

      final pedido = Pedido(
        clienteId: clienteId,
        dataPedido: isoNow(),
        status: pago ? StatusPedido.pago : StatusPedido.aberto,
        formaPagamento: formaPagamento,
        descontoCentavos: descontoCentavos,
        totalCentavos: subtotal - descontoCentavos,
      );
      final pedidoId = await txn.insert('pedido', pedido.toMap());

      for (final item in itens) {
        await txn.insert('item_pedido', <String, Object?>{
          'pedido_id': pedidoId,
          'produto_id': item.produtoId,
          'quantidade': item.quantidade,
          'preco_unit_centavos': item.precoUnitCentavos,
        });
        await txn.rawUpdate(
          'UPDATE produto SET estoque = estoque - ? WHERE id = ?',
          [item.quantidade, item.produtoId],
        );
      }
      return pedidoId;
    });
  }

  Future<void> marcarComoPago(int pedidoId) async {
    final db = await _helper.database;
    await db.update(
      'pedido',
      <String, Object?>{'status': StatusPedido.pago},
      where: 'id = ? AND status = ?',
      whereArgs: [pedidoId, StatusPedido.aberto],
    );
  }

  /// RN05: cancelar devolve ao estoque as quantidades dos itens.
  Future<void> cancelar(int pedidoId) async {
    final db = await _helper.database;
    await db.transaction<void>((txn) async {
      final pedido = await txn.query(
        'pedido',
        columns: ['status'],
        where: 'id = ?',
        whereArgs: [pedidoId],
      );
      if (pedido.isEmpty) {
        throw const RegraNegocioException('Pedido não encontrado.');
      }
      if (pedido.first['status'] == StatusPedido.cancelado) {
        return;
      }
      final itens = await txn.query(
        'item_pedido',
        columns: ['produto_id', 'quantidade'],
        where: 'pedido_id = ?',
        whereArgs: [pedidoId],
      );
      for (final item in itens) {
        await txn.rawUpdate(
          'UPDATE produto SET estoque = estoque + ? WHERE id = ?',
          [item['quantidade'], item['produto_id']],
        );
      }
      await txn.update(
        'pedido',
        <String, Object?>{'status': StatusPedido.cancelado},
        where: 'id = ?',
        whereArgs: [pedidoId],
      );
    });
  }
}
