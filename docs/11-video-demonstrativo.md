# Vídeo demonstrativo

> **Link do vídeo (YouTube, não listado):** _colar aqui o link depois de publicar_

## Requisitos da entrega

- Duração máxima: **2 minutos**.
- Gravar a **tela inteira do computador** (não apenas a janela do emulador ou do editor).
- Mostrar e explicar o **código-fonte** e a **organização** das pastas.
- Mostrar as **etapas e componentes** usados na construção (dependências, banco, geração do APK).
- Mostrar o **app funcionando no emulador**.
- Publicar no YouTube como **não listado** e colocar o link acima (e no `README.md`).

## Roteiro sugerido (2 minutos)

Preparação antes de gravar: abra o VS Code com o projeto, o emulador Android já rodando com o app instalado e o repositório no GitHub em uma aba do navegador. Feche notificações. Grave com a tela inteira (OBS Studio, Xbox Game Bar `Win+Alt+R`, ou o gravador do Windows/macOS).

| Tempo | Na tela | O que falar (sugestão) |
|---|---|---|
| 0:00 – 0:10 | Repositório no GitHub (README com integrantes) | "Somos Erick Alves Kolhrausch e Natanael Almeida de Jesus. Este é o **Vitrine**, app Android para pequenos negócios divulgarem o catálogo e analisarem as vendas, com banco SQLite local que funciona offline." |
| 0:10 – 0:35 | VS Code: árvore da pasta `lib/` | "O código é em Flutter e está em camadas: `core` com regras e formatação, `models`, `database` com o esquema e as consultas, `repositories` que acessam o banco, `services`, `providers`, `widgets` e `screens` com as telas." |
| 0:35 – 0:55 | `schema.dart` e `queries.dart` | "O banco tem 7 tabelas, com chaves estrangeiras e restrições. Criamos tudo no `onCreate` do `DatabaseHelper`. As consultas de análise, como a curva ABC, ficam no `queries.dart`." |
| 0:55 – 1:05 | `pubspec.yaml` e `.github/workflows/build-apk.yml` | "Usamos sqflite, provider, image_picker e share_plus. O APK é gerado com `flutter build apk --release`, automatizado no GitHub Actions." |
| 1:05 – 1:50 | Emulador (ao lado do VS Code ou em tela cheia): *Mais → Dados de demonstração* → **Início** → **Catálogo** (novo produto, foto, compartilhar) → **Pedidos** (novo pedido, ver o estoque baixar) → **Clientes** (perfis) → **Relatórios** (curva ABC, tendência, divulgação) → **Mais → Sobre** | "No emulador: carrego dados de demonstração, o painel mostra o mês; cadastro um produto com foto e compartilho o catálogo; registro um pedido e o estoque é baixado; os clientes são classificados em novo, fiel, em risco e inativo; e os relatórios mostram curva ABC e efeito da divulgação. Na tela Sobre estão os nomes do grupo." |
| 1:50 – 2:00 | Emulador com **modo avião** ativado, app ainda funcionando | "Mesmo em modo avião o app funciona, porque o banco é local. Obrigado!" |

**Dicas:** ensaie uma vez com cronômetro; se passar de 2 minutos, corte a fala do `pubspec.yaml` ou acelere a demonstração do emulador. Fale em ritmo constante, sem ler o código linha por linha.

## Como publicar no YouTube como "não listado"

1. Acesse o [YouTube Studio](https://studio.youtube.com) → **Criar → Enviar vídeos**.
2. Selecione o arquivo gravado e dê um título (ex.: *Projeto Integrador VI-B — Vitrine*).
3. Em **Visibilidade**, escolha **Não listado** e clique em **Salvar/Publicar**.
4. Copie o link, cole no topo deste arquivo e no capítulo "Vídeo demonstrativo" do [README](../README.md), e faça o *commit*.
