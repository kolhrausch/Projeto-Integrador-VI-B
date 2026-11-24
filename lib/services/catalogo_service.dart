import 'package:share_plus/share_plus.dart';

import '../core/exceptions.dart';
import '../core/format.dart';
import '../repositories/empresa_repository.dart';
import '../repositories/produto_repository.dart';

/// Monta o texto do catálogo e o compartilha pelos apps instalados no aparelho.
class CatalogoService {
  CatalogoService._();

  static final ProdutoRepository _produtos = ProdutoRepository();
  static final EmpresaRepository _empresas = EmpresaRepository();

  static Future<String> montarTexto() async {
    final empresa = await _empresas.obter();
    final produtos = await _produtos.catalogo();
    if (produtos.isEmpty) {
      throw const RegraNegocioException(
          'Cadastre ao menos um produto ativo antes de compartilhar o catálogo.');
    }

    final texto = StringBuffer();
    texto.writeln('*${empresa.nome}*');
    final slogan = empresa.slogan;
    if (temTexto(slogan)) {
      texto.writeln(slogan);
    }
    texto.writeln();

    String? categoriaAtual;
    for (final produto in produtos) {
      final categoria = produto.categoriaNome ?? 'Outros';
      if (categoria != categoriaAtual) {
        categoriaAtual = categoria;
        texto.writeln('--- ${categoria.toUpperCase()} ---');
      }
      texto.write('• ${produto.nome} - ${formatMoney(produto.precoCentavos)}');
      if (produto.estoque <= 0) {
        texto.write(' (indisponível)');
      }
      texto.writeln();
      final descricao = produto.descricao;
      if (temTexto(descricao)) {
        texto.writeln('  $descricao');
      }
    }

    texto.writeln();
    final whatsapp = empresa.whatsapp;
    if (temTexto(whatsapp)) {
      texto.writeln('WhatsApp: $whatsapp');
    }
    final instagram = empresa.instagram;
    if (temTexto(instagram)) {
      texto.writeln('Instagram: $instagram');
    }
    final horario = empresa.horarioAtendimento;
    if (temTexto(horario)) {
      texto.writeln('Atendimento: $horario');
    }
    return texto.toString().trim();
  }

  /// Compartilha o catálogo e registra o compartilhamento (tabela divulgacao).
  static Future<void> compartilhar(String canal) async {
    final texto = await montarTexto();
    final produtos = await _produtos.catalogo();
    await Share.share(texto);
    await _empresas.registrarDivulgacao(canal: canal, qtdProdutos: produtos.length);
  }
}
