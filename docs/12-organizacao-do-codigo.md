# Organização do código-fonte

## Estrutura de pastas

```
vitrine/
├── pubspec.yaml                  dependências do app
├── analysis_options.yaml         regras de análise estática
├── lib/
│   ├── main.dart                 ponto de entrada (liga o AppState e abre o app)
│   ├── app.dart                  MaterialApp e tema (Material 3)
│   ├── core/                     regras e utilitários sem dependência do Flutter
│   │   ├── exceptions.dart       RegraNegocioException e mensagens de erro
│   │   ├── format.dart           moeda, datas, conversões
│   │   └── rules.dart            perfil do cliente (RN07), curva ABC, tendência
│   ├── models/                   classes de dados (toMap / fromMap)
│   │   └── produto, categoria, cliente, pedido, item_pedido, empresa, divulgacao
│   ├── database/
│   │   ├── database_helper.dart  abre o SQLite, ativa FKs, executa o onCreate
│   │   ├── schema.dart           script de criação (7 tabelas, índices)
│   │   └── queries.dart          todas as consultas SQL
│   ├── repositories/             acesso ao banco, transações e regras de integridade
│   │   ├── produto_repository.dart   produtos + categorias
│   │   ├── cliente_repository.dart
│   │   ├── pedido_repository.dart    criar / pagar / cancelar pedido
│   │   ├── empresa_repository.dart   vitrine + registro de divulgações
│   │   ├── relatorio_repository.dart consultas analíticas
│   │   └── demo_data.dart            dados de demonstração
│   ├── services/                 integrações com o aparelho
│   │   ├── catalogo_service.dart     monta e compartilha o catálogo
│   │   ├── foto_service.dart         galeria/câmera
│   │   └── export_service.dart       CSV e backup do banco
│   ├── providers/app_state.dart  avisa as telas quando os dados mudam
│   ├── widgets/                  componentes reutilizáveis
│   │   ├── common.dart               cartões, chips, diálogos, DataReloadMixin
│   │   └── charts.dart               gráfico de barras e de linha
│   └── screens/                  telas do app
├── test/widget_test.dart         testes unitários (formatação e regras)
├── tool/validar_sql.py           valida o SQL do app em um SQLite real
├── scripts/bootstrap.sh|.ps1     gera a pasta android/ sem tocar no código
├── .github/workflows/build-apk.yml  CI: testes + APK
├── android/                      projeto Android nativo (gerado pelo Flutter)
├── apk/vitrine.apk               APK gerado
├── docs/                         documentação (este conjunto de arquivos)
└── wireframes/                   wireframes (PNG e SVG)
```

## Fluxo de dados

```
Tela (screens/)  ──chama──▶  Repositório  ──SQL──▶  SQLite (vitrine.db)
   ▲                              │
   │                              └─ valida regras de negócio e usa transações
   └── recarrega quando o AppState avisa (DataReloadMixin)
```

1. A tela pede dados ao **repositório** (`carregar()`).
2. O repositório executa a consulta SQL de `queries.dart` e devolve objetos de `models/`.
3. Ao gravar algo, a tela chama `AppState.dadosAlterados()`; todas as telas abertas que usam `DataReloadMixin` recarregam sozinhas (por exemplo, registrar um pedido atualiza painel, lista de pedidos, estoque do catálogo e relatórios).

## Telas

| Tela | Arquivo | Wireframe |
|---|---|---|
| Início (painel) | `dashboard_screen.dart` | 1 |
| Catálogo | `catalogo_screen.dart` | 2 |
| Novo / editar produto | `produto_form_screen.dart` | 3 |
| Novo pedido | `pedido_form_screen.dart` | 4 |
| Pedidos | `pedidos_screen.dart` (+ `pedido_detalhe_screen.dart`) | 5 |
| Clientes | `clientes_screen.dart` (+ `cliente_form_screen.dart`) | 6 |
| Relatórios | `relatorios_screen.dart` | 7 |
| Minha vitrine digital | `vitrine_screen.dart` | 8 |
| Sobre o app (integrantes) | `sobre_screen.dart` | 9 |
| Aba "Mais" e barra de navegação | `mais_screen.dart`, `home_shell.dart` | — |

## Decisões de projeto

- **Sem bibliotecas de gráfico:** os gráficos são desenhados com `CustomPainter` para reduzir dependências.
- **Regras puras em `core/`:** perfil de cliente, curva ABC e tendência são funções sem acesso a banco, o que permite testá-las com `flutter test`.
- **SQL em um só lugar:** `queries.dart` e `schema.dart` são lidos pelo script de validação, que testa exatamente o SQL que o app usa.
- **Dinheiro em centavos** (inteiros) em todo o código e no banco.
- **Estado simples:** `provider` apenas para avisar mudanças; cada tela busca seus dados direto do repositório.

## Testes

| O que | Como executar |
|---|---|
| Regras e formatação (Dart) | `flutter test` |
| SQL, restrições e chaves estrangeiras | `python3 tool/validar_sql.py` |
| Análise estática | `flutter analyze` |
