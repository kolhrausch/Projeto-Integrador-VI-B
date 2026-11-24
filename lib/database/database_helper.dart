import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'schema.dart';

/// Acesso único (singleton) ao banco SQLite local `vitrine.db`.
///
/// O arquivo fica no armazenamento privado do aplicativo, dentro do celular,
/// e funciona sem internet.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String nomeArquivo = 'vitrine.db';
  static const int versao = 1;

  Future<Database>? _abertura;

  /// Abre o banco na primeira chamada e reaproveita nas seguintes.
  Future<Database> get database => _abertura ??= _abrir();

  Future<Database> _abrir() async {
    final pasta = await getDatabasesPath();
    final caminho = p.join(pasta, nomeArquivo);
    return openDatabase(
      caminho,
      version: versao,
      onConfigure: (db) async {
        // Ativa as chaves estrangeiras a cada abertura (o SQLite as desliga por padrão).
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, versaoCriada) async {
        final batch = db.batch();
        for (final instrucao in Schema.statements) {
          batch.execute(instrucao);
        }
        await batch.commit(noResult: true);
      },
    );
  }
}
