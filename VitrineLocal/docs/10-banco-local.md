# 10. Banco de dados local

## Escolha: SQLite

O aplicativo usa o **[SQLite](https://www.sqlite.org)**, um banco relacional embutido que armazena todos os dados em **um único arquivo** (`vitrine.db`) dentro do armazenamento privado do aplicativo no próprio celular. Não há servidor, nem configuração, nem necessidade de internet, o que atende ao requisito de funcionamento offline.

Motivos da escolha:
- Funciona localmente, sem conexão
- Suporte a SQL, chaves estrangeiras e funções de agregação, necessárias para os relatórios de ciência de dados
- Já incluído no Android
- Leve e adequado ao volume de dados de um pequeno negócio

## Como será implementado

A integração é feita com o pacote [`sqflite`](https://pub.dev/packages/sqflite), com o caminho do arquivo obtido por [`path`](https://pub.dev/packages/path) e [`path_provider`](https://pub.dev/packages/path_provider).

### Arquitetura em camadas

```
Telas (Widgets)  →  Providers (estado)  →  Repositórios (DAO)  →  DatabaseHelper  →  SQLite (vitrine.db)
```

| Camada | Responsabilidade |
|---|---|
| `DatabaseHelper` | Abre o banco (padrão *singleton*), ativa as chaves estrangeiras, cria as tabelas e controla as versões |
| Repositórios (`ProdutoRepository`, `ClienteRepository`, `PedidoRepository`, `RelatorioRepository`...) | Operações de inserir, atualizar, excluir e consultar de cada tabela |
| Models (`Produto`, `Cliente`, `Pedido`...) | Classes Dart com conversão `toMap()` / `fromMap()` |
| Providers | Mantêm o estado e notificam as telas |

### Estrutura de pastas prevista

```
lib/
├── main.dart
├── database/
│   ├── database_helper.dart
│   └── migrations.dart
├── models/
├── repositories/
├── providers/
├── screens/
└── widgets/
```

### Abertura do banco e criação das tabelas

```dart
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();
  static Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = join(dir, 'vitrine360.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        // executa o script DDL descrito em docs/04-modelo-er.md
      },
    );
  }
}
```

### Pontos importantes

- **Criação:** o script DDL de [04-modelo-er.md](04-modelo-er.md) é executado no `onCreate`, na primeira abertura do app.
- **Evolução do esquema:** mudanças futuras serão tratadas com `onUpgrade` e o número de `version`.
- **Transações:** a finalização de um pedido (gravar pedido, gravar itens e baixar o estoque) usa `db.transaction`, garantindo que tudo seja salvo ou nada seja salvo.
- **Consultas analíticas:** os relatórios usam SQL com `JOIN`, `GROUP BY`, `SUM`, `COUNT` e funções de data do SQLite, executados localmente.
- **Dados de exemplo:** na primeira execução, o app oferece carregar produtos e clientes de demonstração para facilitar os testes.
- **Imagens:** as fotos são copiadas para a pasta do app e apenas o **caminho** é gravado no banco (`foto_path`, `logo_path`).
- **Privacidade e backup:** os dados ficam somente no aparelho; o arquivo `.db` pode ser copiado para backup (RF21).
