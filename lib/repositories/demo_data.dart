import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../core/format.dart';
import '../database/database_helper.dart';

/// Dados de demonstração para testar o app (gráficos e relatórios).
/// Os valores são fictícios e gerados de forma determinística.
class DemoData {
  DemoData._();

  static Future<void> limparTudo() async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction<void>((txn) async {
      await txn.delete('item_pedido');
      await txn.delete('pedido');
      await txn.delete('produto');
      await txn.delete('categoria');
      await txn.delete('cliente');
      await txn.delete('divulgacao');
    });
  }

  static Future<void> carregar() async {
    await limparTudo();
    final db = await DatabaseHelper.instance.database;
    final agora = DateTime.now();
    final aleatorio = Random(7);

    await db.transaction<void>((txn) async {
      await txn.update(
        'empresa',
        <String, Object?>{
          'nome': 'Doces da Marina',
          'slogan': 'Feito à mão, com carinho',
          'whatsapp': '(54) 99999-0000',
          'instagram': '@docesdamarina',
          'horario_atendimento': 'Seg a Sáb, 9h às 18h',
        },
        where: 'id = 1',
      );

      // ------------------------------------------------------- categorias
      final nomesCategorias = ['Doces', 'Salgados', 'Bebidas', 'Presentes'];
      final categorias = <int>[];
      for (final nome in nomesCategorias) {
        categorias.add(await txn.insert('categoria', <String, Object?>{'nome': nome}));
      }

      // --------------------------------------------------------- produtos
      // categoria, nome, descrição, preço (centavos), estoque
      final catalogo = <List<Object>>[
        [0, 'Brigadeiro gourmet', 'Caixa com 6 unidades', 2400, 45],
        [0, 'Bolo de pote', 'Chocolate com morango', 1200, 30],
        [0, 'Torta de limão', 'Fatia generosa', 1500, 18],
        [0, 'Cookie recheado', 'Unidade', 900, 4],
        [1, 'Empada de frango', 'Unidade', 700, 60],
        [1, 'Coxinha', 'Unidade', 600, 80],
        [2, 'Suco natural', 'Garrafa 500 ml', 1000, 25],
        [2, 'Café coado', 'Copo 200 ml', 500, 3],
        [3, 'Cesta de café da manhã', 'Montada sob encomenda', 8900, 8],
        [3, 'Caixa presente', 'Doces sortidos', 4500, 12],
      ];
      final produtoIds = <int>[];
      final produtoPrecos = <int>[];
      for (final item in catalogo) {
        final id = await txn.insert('produto', <String, Object?>{
          'categoria_id': categorias[item[0] as int],
          'nome': item[1],
          'descricao': item[2],
          'preco_centavos': item[3],
          'estoque': item[4],
          'ativo': 1,
          'criado_em': isoDateTime(agora.subtract(const Duration(days: 150))),
        });
        produtoIds.add(id);
        produtoPrecos.add(item[3] as int);
      }

      // ---------------------------------------------------------- clientes
      // nome, telefone, dias desde a primeira compra, dias desde a última compra
      // (-1 = nunca comprou). Combinações pensadas para gerar todos os perfis.
      final clientes = <List<Object>>[
        ['Joana Souza', '(54) 99111-0001', 140, 130],
        ['Rafael Lima', '(54) 99111-0002', 120, 100],
        ['Camila Rocha', '(54) 99111-0003', 100, 70],
        ['Bruno Alves', '(54) 99111-0004', 90, 2],
        ['Letícia Prado', '(54) 99111-0005', 80, 1],
        ['Marcos Dias', '(54) 99111-0006', 60, 3],
        ['Patrícia Nunes', '(54) 99111-0007', 45, 5],
        ['Diego Ferraz', '(54) 99111-0008', 25, 0],
        ['Sofia Martins', '(54) 99111-0009', 20, 1],
        ['Tiago Barros', '(54) 99111-0010', 12, 12],
        ['Helena Costa', '(54) 99111-0011', 75, 20],
        ['Lucas Pereira', '(54) 99111-0012', -1, -1],
      ];
      final clienteIds = <int>[];
      for (final c in clientes) {
        final primeira = c[2] as int;
        final diasCadastro = primeira < 0 ? 10 : primeira + 5;
        final id = await txn.insert('cliente', <String, Object?>{
          'nome': c[0],
          'telefone': c[1],
          'criado_em': isoDateTime(agora.subtract(Duration(days: diasCadastro))),
        });
        clienteIds.add(id);
      }

      // ----------------------------------------------------------- pedidos
      for (var diasAtras = 150; diasAtras >= 0; diasAtras--) {
        final pedidosDoDia = aleatorio.nextInt(3); // 0, 1 ou 2
        for (var n = 0; n < pedidosDoDia; n++) {
          final elegiveis = <int>[];
          for (var i = 0; i < clientes.length; i++) {
            final primeira = clientes[i][2] as int;
            final ultima = clientes[i][3] as int;
            if (primeira >= 0 && diasAtras <= primeira && diasAtras >= ultima) {
              elegiveis.add(clienteIds[i]);
            }
          }
          int? clienteId;
          if (elegiveis.isNotEmpty && aleatorio.nextInt(100) < 75) {
            clienteId = elegiveis[aleatorio.nextInt(elegiveis.length)];
          }

          final sorteio = aleatorio.nextInt(100);
          String status = 'PAGO';
          if (sorteio < 7) {
            status = 'CANCELADO';
          } else if (sorteio < 15 && diasAtras <= 5) {
            status = 'ABERTO';
          }

          // 1 a 3 produtos distintos, 1 a 4 unidades de cada
          final quantidadeDeProdutos = 1 + aleatorio.nextInt(3);
          final escolhidos = <int>{};
          while (escolhidos.length < quantidadeDeProdutos) {
            escolhidos.add(aleatorio.nextInt(produtoIds.length));
          }
          var total = 0;
          final itens = <Map<String, Object?>>[];
          for (final indice in escolhidos) {
            final quantidade = 1 + aleatorio.nextInt(4);
            total += quantidade * produtoPrecos[indice];
            itens.add(<String, Object?>{
              'produto_id': produtoIds[indice],
              'quantidade': quantidade,
              'preco_unit_centavos': produtoPrecos[indice],
            });
          }

          final base = agora.subtract(Duration(days: diasAtras));
          final quando = DateTime(
            base.year,
            base.month,
            base.day,
            9 + aleatorio.nextInt(10),
            aleatorio.nextInt(60),
          );
          final formas = ['PIX', 'DINHEIRO', 'CARTAO'];
          final pedidoId = await txn.insert('pedido', <String, Object?>{
            'cliente_id': clienteId,
            'data_pedido': isoDateTime(quando),
            'status': status,
            'forma_pagamento': formas[aleatorio.nextInt(formas.length)],
            'desconto_centavos': 0,
            'total_centavos': total,
          });
          for (final item in itens) {
            item['pedido_id'] = pedidoId;
            await txn.insert('item_pedido', item);
          }
        }
      }

      // ------------------------------------------------------ divulgações
      for (final dias in [28, 21, 14, 7, 2]) {
        await txn.insert('divulgacao', <String, Object?>{
          'canal': dias.isEven ? 'WHATSAPP' : 'INSTAGRAM',
          'data_envio': isoDateTime(agora.subtract(Duration(days: dias))),
          'qtd_produtos': produtoIds.length,
        });
      }
    });
  }

  static Future<int> contarPedidos() async {
    final db = await DatabaseHelper.instance.database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pedido')) ?? 0;
  }
}
