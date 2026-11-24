import '../core/format.dart';
import '../database/database_helper.dart';
import '../database/queries.dart';
import '../models/divulgacao.dart';
import '../models/empresa.dart';

/// Dados da vitrine digital (tabela `empresa`, linha única) e registro dos
/// compartilhamentos do catálogo (tabela `divulgacao`).
class EmpresaRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<Empresa> obter() async {
    final db = await _helper.database;
    final linhas = await db.query('empresa', where: 'id = 1');
    if (linhas.isEmpty) {
      return const Empresa(nome: 'Meu Negócio');
    }
    return Empresa.fromMap(linhas.first);
  }

  Future<void> salvar(Empresa empresa) async {
    final db = await _helper.database;
    final alteradas = await db.update('empresa', empresa.toMap(), where: 'id = 1');
    if (alteradas == 0) {
      await db.insert('empresa', empresa.toMap());
    }
  }

  Future<void> registrarDivulgacao({
    required String canal,
    required int qtdProdutos,
  }) async {
    final db = await _helper.database;
    final divulgacao = Divulgacao(
      canal: canal,
      dataEnvio: isoNow(),
      qtdProdutos: qtdProdutos,
    );
    await db.insert('divulgacao', divulgacao.toMap());
  }

  Future<int> divulgacoesNoMes() async {
    final db = await _helper.database;
    final linhas = await db.rawQuery(Queries.divulgacoesNoMes);
    return (linhas.first['n'] as num).toInt();
  }
}
