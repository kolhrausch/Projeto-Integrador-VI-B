# 10. Banco de dados local

## Escolha: SQLite

O aplicativo usa o **[SQLite](https://www.sqlite.org)**, um banco relacional embutido que guarda todos os dados em **um único arquivo** (`vitrine.db`) no armazenamento privado do aplicativo, dentro do próprio celular. Não há servidor, configuração nem necessidade de internet — o banco funciona normalmente com o aparelho em modo avião.

Motivos da escolha:
- funciona localmente, sem conexão;
- suporta SQL, chaves estrangeiras e funções de agregação, necessárias para os relatórios de ciência de dados;
- já vem incluído no Android;
- leve e adequado ao volume de dados de um pequeno negócio.

## Como foi implementado

A integração usa o pacote [`sqflite`](https://pub.dev/packages/sqflite); o caminho do arquivo é montado com [`path`](https://pub.dev/packages/path).

### Arquitetura em camadas

```
Telas (screens/)  →  Repositórios (repositories/)  →  DatabaseHelper  →  SQLite (vitrine.db)
        ↑                      ↑
   AppState (provider)    Models (models/) e regras (core/)
```

| Camada | Arquivos | Responsabilidade |
|---|---|---|
| Banco | `database/database_helper.dart`, `schema.dart`, `queries.dart` | Abre o banco (*singleton*), ativa as chaves estrangeiras, cria as tabelas e guarda todas as consultas SQL |
| Repositórios | `repositories/*.dart` | Inserir, atualizar, excluir e consultar cada tabela; transações; regras de integridade |
| Modelos | `models/*.dart` | Classes Dart com conversão `toMap()` / `fromMap()` |
| Regras | `core/rules.dart`, `core/format.dart` | Cálculos de negócio e formatação (funções puras, testadas) |
| Estado | `providers/app_state.dart` | Avisa as telas para recarregar quando os dados mudam |

### Abertura do banco e criação das tabelas

Código real de `lib/database/database_helper.dart`:

```dart
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String nomeArquivo = 'vitrine.db';
  static const int versao = 1;

  Future<Database>? _abertura;
  Future<Database> get database => _abertura ??= _abrir();

  Future<Database> _abrir() async {
    final pasta = await getDatabasesPath();
    final caminho = p.join(pasta, nomeArquivo);
    return openDatabase(
      caminho,
      version: versao,
      onConfigure: (db) async {
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
```

O detalhamento completo da construção (tabelas, colunas, restrições, índices, transações e validação) está em [09-construcao-do-banco.md](09-construcao-do-banco.md).

### Pontos importantes

- **Criação:** o script DDL (`schema.dart`) é executado no `onCreate`, na primeira abertura do app.
- **Chaves estrangeiras:** ativadas a cada abertura com `PRAGMA foreign_keys = ON`.
- **Evolução do esquema:** mudanças futuras usam o número de `versao` e o callback `onUpgrade`.
- **Transações:** registrar e cancelar pedidos usam `db.transaction`, garantindo que tudo seja salvo ou nada seja salvo.
- **Consultas analíticas:** relatórios usam `JOIN`, `GROUP BY`, `SUM`, `COUNT` e funções de data do SQLite, todos executados localmente.
- **Dados de exemplo:** *Mais → Carregar dados de demonstração* preenche o banco com dados fictícios para testes.
- **Imagens:** as fotos são copiadas para a pasta do app e apenas o **caminho** é gravado (`foto_path`, `logo_path`).
- **Privacidade e backup:** os dados ficam somente no aparelho; *Mais → Backup* compartilha uma cópia do arquivo `.db`.
