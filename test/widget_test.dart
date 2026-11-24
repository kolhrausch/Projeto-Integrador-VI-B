// Testes unitários das regras de negócio e formatações (não dependem de banco
// nem de emulador). O nome widget_test.dart evita que o `flutter create`
// recrie o teste de exemplo do contador.
import 'package:flutter_test/flutter_test.dart';
import 'package:vitrine/core/format.dart';
import 'package:vitrine/core/rules.dart';

void main() {
  group('formatMoney', () {
    test('formata centavos em reais com separadores', () {
      expect(formatMoney(123456), 'R\$ 1.234,56');
      expect(formatMoney(5), 'R\$ 0,05');
      expect(formatMoney(1000000), 'R\$ 10.000,00');
      expect(formatMoney(-1050), '-R\$ 10,50');
    });
  });

  group('parseMoneyToCents', () {
    test('converte texto digitado em centavos', () {
      expect(parseMoneyToCents('12,50'), 1250);
      expect(parseMoneyToCents('1.234,56'), 123456);
      expect(parseMoneyToCents('R\$ 8'), 800);
      expect(parseMoneyToCents('12.5'), 1250);
    });

    test('rejeita valores inválidos', () {
      expect(parseMoneyToCents(''), isNull);
      expect(parseMoneyToCents('abc'), isNull);
      expect(parseMoneyToCents('-5'), isNull);
    });
  });

  group('datas', () {
    test('isoDateTime e formatDate', () {
      final d = DateTime(2026, 10, 20, 9, 5, 3);
      expect(isoDateTime(d), '2026-10-20T09:05:03');
      expect(isoDate(d), '2026-10-20');
      expect(formatDate('2026-10-20T09:05:03'), '20/10/2026');
      expect(formatDateTime('2026-10-20T09:05:03'), '20/10/2026 09:05');
    });

    test('diasEntre ignora a hora', () {
      expect(diasEntre(DateTime(2026, 11, 1, 23), DateTime(2026, 11, 22, 1)), 21);
    });
  });

  group('classificarCliente (RN07)', () {
    final hoje = DateTime(2026, 11, 22);

    test('novo: primeira compra há 30 dias ou menos', () {
      final perfil = classificarCliente(
        hoje: hoje,
        criadoEm: DateTime(2026, 11, 1),
        totalPedidos: 1,
        pedidos90Dias: 1,
        primeiraCompra: DateTime(2026, 11, 12),
        ultimaCompra: DateTime(2026, 11, 12),
      );
      expect(perfil, PerfilCliente.novo);
    });

    test('fiel: 3 ou mais pedidos nos últimos 90 dias', () {
      final perfil = classificarCliente(
        hoje: hoje,
        criadoEm: DateTime(2026, 1, 1),
        totalPedidos: 5,
        pedidos90Dias: 3,
        primeiraCompra: DateTime(2026, 7, 1),
        ultimaCompra: DateTime(2026, 11, 10),
      );
      expect(perfil, PerfilCliente.fiel);
    });

    test('em risco: última compra entre 60 e 120 dias', () {
      final perfil = classificarCliente(
        hoje: hoje,
        criadoEm: DateTime(2026, 1, 1),
        totalPedidos: 2,
        pedidos90Dias: 0,
        primeiraCompra: DateTime(2026, 5, 1),
        ultimaCompra: DateTime(2026, 9, 1),
      );
      expect(perfil, PerfilCliente.emRisco);
    });

    test('inativo: última compra há mais de 120 dias', () {
      final perfil = classificarCliente(
        hoje: hoje,
        criadoEm: DateTime(2026, 1, 1),
        totalPedidos: 1,
        pedidos90Dias: 0,
        primeiraCompra: DateTime(2026, 5, 1),
        ultimaCompra: DateTime(2026, 5, 1),
      );
      expect(perfil, PerfilCliente.inativo);
    });

    test('regular: demais casos', () {
      final perfil = classificarCliente(
        hoje: hoje,
        criadoEm: DateTime(2026, 1, 1),
        totalPedidos: 3,
        pedidos90Dias: 2,
        primeiraCompra: DateTime(2026, 6, 1),
        ultimaCompra: DateTime(2026, 11, 1),
      );
      expect(perfil, PerfilCliente.regular);
    });

    test('sem compras: novo se cadastro recente, inativo se antigo', () {
      expect(
        classificarCliente(
          hoje: hoje,
          criadoEm: DateTime(2026, 11, 15),
          totalPedidos: 0,
          pedidos90Dias: 0,
        ),
        PerfilCliente.novo,
      );
      expect(
        classificarCliente(
          hoje: hoje,
          criadoEm: DateTime(2026, 1, 1),
          totalPedidos: 0,
          pedidos90Dias: 0,
        ),
        PerfilCliente.inativo,
      );
    });
  });

  group('curva ABC', () {
    test('classifica por receita acumulada', () {
      final abc = calcularCurvaAbc([
        const MapEntry('Produto A', 800),
        const MapEntry('Produto B', 150),
        const MapEntry('Produto C', 50),
      ]);
      expect(abc.map((i) => i.classe).toList(), ['A', 'B', 'C']);
      expect(abc.first.percentual, closeTo(80, 0.001));
      expect(abc.last.percentualAcumulado, closeTo(100, 0.001));
    });

    test('lista vazia ou sem receita', () {
      expect(calcularCurvaAbc([]), isEmpty);
      expect(calcularCurvaAbc([const MapEntry('X', 0)]), isEmpty);
    });
  });

  group('variacaoTendencia', () {
    test('compara os 7 últimos dias com os 7 anteriores', () {
      final serie = [...List.filled(7, 100), ...List.filled(7, 150)];
      expect(variacaoTendencia(serie), closeTo(50, 0.001));
    });

    test('retorna null sem base de comparação', () {
      expect(variacaoTendencia(List.filled(10, 100)), isNull);
      expect(variacaoTendencia([...List.filled(7, 0), ...List.filled(7, 100)]), isNull);
    });
  });
}
