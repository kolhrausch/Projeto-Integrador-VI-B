# Vitrine

> Aplicativo móvel (Android) para pequenos negócios melhorarem a presença digital e tomarem decisões com base em dados — tudo funcionando **offline**, com banco de dados SQLite local no próprio celular.

**Projeto Integrador VI-B** · Análise e Desenvolvimento de Sistemas (ADS)
Disciplinas integradas: Ciência dos Dados e Programação para Dispositivos Móveis II
**Etapa 2 — Implementação do aplicativo** (documentação revisada com a situação final do projeto)

---

## Integrantes do grupo

| # | Nome completo |
|---|---------------|
| 1 | Erick Alves Kolhrausch |
| 2 | Natanael Almeida de Jesus |

---

## Resumo

O **Vitrine** reúne em um só app três necessidades de um pequeno comerciante: **(1)** um catálogo digital de produtos que pode ser compartilhado com clientes por WhatsApp e redes sociais, **(2)** o registro simples de clientes e pedidos e **(3)** painéis e relatórios que transformam esses registros em informação para decidir (produtos mais vendidos, ticket médio, curva ABC, clientes por perfil, efeito da divulgação).

Questão norteadora do projeto: *"Qual aplicativo de celular pode auxiliar no crescimento e inovação dos negócios?"*

## Entregas da Etapa 2

| Item da Etapa 2 | Onde está |
|---|---|
| 1.1 Código-fonte do aplicativo | Pasta [`lib/`](lib/) (organização em [docs/12-organizacao-do-codigo.md](docs/12-organizacao-do-codigo.md)), com `pubspec.yaml`, `android/` e `test/` |
| 1.2 Arquivo APK gerado | [`apk/vitrine.apk`](apk/vitrine.apk) — como foi gerado em [docs/06-geracao-apk.md](docs/06-geracao-apk.md) |
| 1 (execução em outro ambiente) | [docs/10-como-executar.md](docs/10-como-executar.md) |
| 2. Detalhamento da construção do banco de dados local | [docs/09-construcao-do-banco.md](docs/09-construcao-do-banco.md) |
| 4. Repositório da Etapa 1 revisado | Todos os documentos abaixo foram atualizados para a situação final |

## Vídeo demonstrativo

**Link (YouTube, não listado):https://youtu.be/dQvvvpWoFd4?si=GIER0atDwhOsgMdZ



## Índice da documentação

| Item | Documento |
|---|---|
| 1. Nome do projeto | Este arquivo (`README.md`) |
| 2. Problema que resolve | [docs/01-problema.md](docs/01-problema.md) |
| 3. Público-alvo | [docs/02-publico-alvo.md](docs/02-publico-alvo.md) |
| 4. Características do aplicativo (situação final) | [docs/03-funcionalidades.md](docs/03-funcionalidades.md) |
| 5. Modelo ER do banco de dados local | [docs/04-modelo-er.md](docs/04-modelo-er.md) |
| 6. Wireframes em alta definição e telas implementadas | [docs/05-wireframes.md](docs/05-wireframes.md) |
| 7. Tela com o nome dos integrantes | [docs/05-wireframes.md](docs/05-wireframes.md#tela-9--sobre-o-app-integrantes) · implementada em `lib/screens/sobre_screen.dart` |
| 8. Geração do arquivo APK | [docs/06-geracao-apk.md](docs/06-geracao-apk.md) |
| 9. Tecnologias, bibliotecas e linguagens | [docs/07-tecnologias.md](docs/07-tecnologias.md) |
| 10. Banco de dados local | [docs/08-banco-local.md](docs/08-banco-local.md) |
| Construção do banco de dados (Etapa 2) | [docs/09-construcao-do-banco.md](docs/09-construcao-do-banco.md) |
| Como executar em outro ambiente | [docs/10-como-executar.md](docs/10-como-executar.md) |
| Vídeo demonstrativo | [docs/11-video-demonstrativo.md](docs/11-video-demonstrativo.md) |
| Organização do código-fonte | [docs/12-organizacao-do-codigo.md](docs/12-organizacao-do-codigo.md) |

## Como executar (resumo)

```bash
git clone https://github.com/SEU-USUARIO/vitrine.git && cd vitrine
bash scripts/bootstrap.sh     # só se a pasta android/ não existir
flutter pub get
flutter run                   # emulador ou celular Android
flutter build apk --release   # gera build/app/outputs/flutter-apk/app-release.apk
```

Ou apenas instale o [`apk/vitrine.apk`](apk/vitrine.apk) em um celular Android. Detalhes em [docs/10-como-executar.md](docs/10-como-executar.md).

## Estrutura do repositório

```
vitrine/
├── README.md
├── pubspec.yaml · analysis_options.yaml
├── lib/                      código-fonte do app (Dart / Flutter)
├── test/                     testes unitários
├── android/                  projeto Android nativo
├── apk/vitrine.apk           APK gerado
├── tool/validar_sql.py       validação do SQL do banco
├── scripts/                  bootstrap.sh / bootstrap.ps1
├── .github/workflows/        build automático do APK
├── docs/                     documentação (01 a 12)
└── wireframes/               wireframes (PNG e SVG)
```
