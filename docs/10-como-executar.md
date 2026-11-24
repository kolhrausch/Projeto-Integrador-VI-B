# Como executar o projeto em outro ambiente

Passo a passo para quem baixar o repositório (professor, colega ou outro computador) rodar o app **ou apenas instalar o APK**.

## Opção A — Só instalar o APK (mais rápido)

1. No celular Android, baixe [`apk/vitrine.apk`](../apk/vitrine.apk) (botão **Download** no GitHub).
2. Abra o arquivo e permita a instalação de apps de fontes desconhecidas.
3. Abra o **Vitrine**. Para ver o app com dados, vá em **Mais → Carregar dados de demonstração**.

Também funciona em emulador Android: arraste o `.apk` para a janela do emulador.

## Opção B — Rodar o código-fonte

### Requisitos
- [Flutter SDK 3.24.5](https://docs.flutter.dev/release/archive) (ou compatível) — Dart já vem junto
- [Android Studio](https://developer.android.com/studio) com Android SDK e um **emulador** (AVD) criado — ou um celular com depuração USB
- Git

### Passos

```bash
# 1. Clonar o repositório
git clone https://github.com/SEU-USUARIO/vitrine.git
cd vitrine

# 2. Conferir o ambiente (todos os itens de Android devem estar OK)
flutter doctor

# 3. (Só se a pasta android/ não existir no repositório) gerar o projeto Android
bash scripts/bootstrap.sh            # Windows: powershell -File scripts\bootstrap.ps1

# 4. Baixar as dependências
flutter pub get

# 5. Rodar os testes (opcional)
flutter test
python3 tool/validar_sql.py          # valida o SQL do banco (precisa só do Python 3)

# 6. Executar no emulador ou celular conectado
flutter run

# 7. Gerar o APK
flutter build apk --release
#    -> build/app/outputs/flutter-apk/app-release.apk
```

### Abrir no Android Studio / VS Code
- **Android Studio:** *File → Open* na pasta do projeto, escolher o emulador na barra superior e clicar em ▶ *Run*.
- **VS Code:** instalar as extensões *Flutter* e *Dart*, abrir a pasta, escolher o dispositivo no canto inferior direito e pressionar **F5**.

## Primeiros passos dentro do app

1. **Mais → Carregar dados de demonstração** — cria categorias, 10 produtos, 12 clientes, ~150 dias de pedidos e compartilhamentos fictícios.
2. **Início** — painel do mês (vendas, pedidos, ticket médio, novos clientes) e vendas dos últimos 7 dias.
3. **Catálogo** — buscar, filtrar por categoria, cadastrar produto (com foto) e compartilhar o catálogo.
4. **Pedidos** — registrar um pedido; o estoque é baixado; abrir um pedido para marcar como pago ou cancelar.
5. **Clientes** — lista com o perfil de cada cliente (novo, fiel, em risco, inativo, regular) e histórico de compras.
6. **Mais → Relatórios** — vendas por dia, curva ABC, perfil de clientes, estoque baixo, efeito da divulgação e exportação em CSV.
7. **Mais → Sobre o app** — nomes completos dos integrantes.

Para testar o modo offline, ative o **modo avião** no emulador/celular: todo o app continua funcionando.

## Problemas comuns

| Sintoma | O que fazer |
|---|---|
| `flutter doctor` reclama das licenças do Android | `flutter doctor --android-licenses` e aceitar todas |
| `No Android SDK found` | Instalar o SDK pelo Android Studio e `flutter config --android-sdk <caminho>` |
| Erro de versão do Gradle/Java | Usar o JDK 17 (`flutter config --jdk-dir <caminho do JDK 17>`) |
| `android/` não existe | Rodar `scripts/bootstrap.sh` (ou `.ps1`) |
| Erro de dependências | `flutter clean` e depois `flutter pub get` |
| Dados antigos atrapalhando os testes | **Mais → Apagar todos os dados**, ou desinstalar o app do emulador |
