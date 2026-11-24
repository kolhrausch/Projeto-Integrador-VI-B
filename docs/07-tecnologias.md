# 9. Tecnologias, bibliotecas e linguagens

Lista final do que foi **efetivamente usado** no projeto.

## Linguagens e framework

| Item | Uso | Link |
|---|---|---|
| Dart 3.5 | Linguagem do aplicativo | https://dart.dev |
| Flutter 3.24.5 | Framework do aplicativo móvel (interface Material 3) | https://flutter.dev |
| SQL (dialeto SQLite) | Criação das tabelas e consultas de análise | https://www.sqlite.org/lang.html |
| Python 3 | Script de validação do SQL (`tool/validar_sql.py`) | https://www.python.org |

## Banco de dados local

| Item | Uso | Link |
|---|---|---|
| SQLite | Banco de dados local, offline | https://www.sqlite.org |
| sqflite | Acesso ao SQLite no Flutter | https://pub.dev/packages/sqflite |
| path | Montagem do caminho do arquivo do banco | https://pub.dev/packages/path |
| path_provider | Pastas privadas do app (fotos e arquivos temporários) | https://pub.dev/packages/path_provider |

## Bibliotecas do aplicativo

| Biblioteca | Uso | Link |
|---|---|---|
| provider | Gerenciamento de estado (aviso de que os dados mudaram) | https://pub.dev/packages/provider |
| image_picker | Foto do produto e logotipo (galeria ou câmera) | https://pub.dev/packages/image_picker |
| share_plus | Compartilhar catálogo, CSV e backup | https://pub.dev/packages/share_plus |

Os gráficos (barras e linha) são desenhados com widgets e `CustomPainter` do próprio Flutter; a formatação de moeda e datas e a exportação CSV foram implementadas no código do projeto (`lib/core/format.dart`, `relatorios_screen.dart`), sem bibliotecas adicionais.

## Qualidade e testes

| Item | Uso | Link |
|---|---|---|
| flutter_test | Testes unitários das regras de negócio (`test/widget_test.dart`) | https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html |
| flutter_lints | Regras de análise estática | https://pub.dev/packages/flutter_lints |

## Ferramentas de desenvolvimento e entrega

| Ferramenta | Uso | Link |
|---|---|---|
| Android Studio | IDE, emulador e Android SDK | https://developer.android.com/studio |
| Visual Studio Code | Editor de código | https://code.visualstudio.com |
| Git | Controle de versão | https://git-scm.com |
| GitHub | Repositório e documentação | https://github.com |
| GitHub Actions | Compilação automática do APK | https://docs.github.com/actions |
| flutter-action | Instala o Flutter no GitHub Actions | https://github.com/subosito/flutter-action |
| Eclipse Temurin (JDK 17) | Java usado na compilação Android | https://adoptium.net |
| Mermaid | Diagramas na documentação em Markdown | https://mermaid.js.org |
| DB Browser for SQLite | Inspeção do arquivo do banco durante os testes | https://sqlitebrowser.org |

## Plataforma alvo

| Item | Detalhe | Link |
|---|---|---|
| Android | 5.0 (API 21) ou superior | https://developer.android.com |
