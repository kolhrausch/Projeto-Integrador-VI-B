import 'package:sqflite/sqflite.dart';

import '../core/exceptions.dart';
import '../database/database_helper.dart';
import '../models/cliente.dart';

/// Operações da tabela `cliente`.
class ClienteRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<List<Cliente>> listar() async {
    final db = await _helper.database;
    final linhas = await db.query('cliente', orderBy: 'nome COLLATE NOCASE');
    return linhas.map(Cliente.fromMap).toList();
  }

  Future<Cliente?> obter(int id) async {
    final db = await _helper.database;
    final linhas = await db.query('cliente', where: 'id = ?', whereArgs: [id]);
    if (linhas.isEmpty) {
      return null;
    }
    return Cliente.fromMap(linhas.first);
  }

  Future<int> inserir(Cliente cliente) async {
    final db = await _helper.database;
    try {
      return await db.insert('cliente', cliente.toMap());
    } on DatabaseException catch (e) {
      throw _traduzir(e);
    }
  }

  Future<void> atualizar(Cliente cliente) async {
    final db = await _helper.database;
    try {
      await db.update(
        'cliente',
        cliente.toMap(),
        where: 'id = ?',
        whereArgs: [cliente.id],
      );
    } on DatabaseException catch (e) {
      throw _traduzir(e);
    }
  }

  /// Os pedidos do cliente são preservados (cliente_id vira NULL).
  Future<void> excluir(int id) async {
    final db = await _helper.database;
    await db.delete('cliente', where: 'id = ?', whereArgs: [id]);
  }

  Object _traduzir(DatabaseException erro) {
    if (erro.toString().contains('UNIQUE')) {
      return const RegraNegocioException('Já existe um cliente com este telefone.');
    }
    return erro;
  }
}
