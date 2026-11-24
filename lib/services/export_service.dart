import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../core/exceptions.dart';
import '../database/database_helper.dart';

/// Exportações: relatório em CSV e backup do arquivo do banco de dados.
class ExportService {
  ExportService._();

  /// Grava o CSV (UTF-8 com BOM, separador ";" para abrir direto no Excel
  /// em português) e abre a janela de compartilhamento.
  static Future<void> compartilharCsv(String nomeArquivo, String conteudo) async {
    final temporaria = await getTemporaryDirectory();
    final arquivo = File(p.join(temporaria.path, nomeArquivo));
    await arquivo.writeAsString('﻿$conteudo');
    await Share.shareXFiles(
      [XFile(arquivo.path, mimeType: 'text/csv')],
      text: 'Resumo de relatórios - Vitrine',
    );
  }

  /// Compartilha uma cópia do arquivo vitrine.db (backup).
  static Future<void> compartilharBanco() async {
    final pasta = await getDatabasesPath();
    final origem = File(p.join(pasta, DatabaseHelper.nomeArquivo));
    if (!await origem.exists()) {
      throw const RegraNegocioException('Arquivo do banco de dados não encontrado.');
    }
    final temporaria = await getTemporaryDirectory();
    final copia = await origem.copy(p.join(temporaria.path, 'vitrine_backup.db'));
    await Share.shareXFiles(
      [XFile(copia.path)],
      text: 'Backup do banco de dados do Vitrine',
    );
  }
}
