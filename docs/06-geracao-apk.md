# 8. Geração do arquivo APK

O aplicativo é desenvolvido em **Flutter**, que compila o código Dart para código nativo Android e empacota o resultado em um arquivo **APK** (*Android Package*).

O APK pronto fica em [`apk/vitrine.apk`](../apk/vitrine.apk). Existem duas formas de gerá-lo: **automática** (GitHub Actions) e **manual** (na sua máquina).

## Versões usadas

| Item | Versão |
|---|---|
| Flutter | 3.24.5 (canal *stable*, Dart 3.5) |
| Java (JDK) | 17 |
| Android SDK | instalado pelo Android Studio (ou pela ação do GitHub) |

## Forma 1 — Automática (GitHub Actions)

O workflow [`.github/workflows/build-apk.yml`](../.github/workflows/build-apk.yml) roda a cada `push` na branch `main`:

1. instala Java 17 e Flutter 3.24.5;
2. gera a pasta `android/` (se ainda não existir) com `scripts/bootstrap.sh`;
3. `flutter pub get` → `flutter analyze` → `flutter test` → `python3 tool/validar_sql.py`;
4. `flutter build apk --release`;
5. copia o resultado para `apk/vitrine.apk` e faz um *commit* automático com o APK e a pasta `android/`.

Para baixar o APK: abra o repositório → pasta `apk/` → `vitrine.apk` → **Download**. Também fica em **Actions → (execução) → Artifacts → vitrine-apk**.

## Forma 2 — Manual

### Pré-requisitos
1. [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.24.5 no `PATH`
2. [Android Studio](https://developer.android.com/studio) com o **Android SDK** e as *command-line tools*
3. Aceitar as licenças: `flutter doctor --android-licenses`
4. Conferir o ambiente: `flutter doctor`

### Passo a passo

**1. Gerar a pasta `android/`** (necessário só se ela ainda não existir no repositório)
```bash
bash scripts/bootstrap.sh           # Linux / macOS / Git Bash
powershell -File scripts\bootstrap.ps1   # Windows (PowerShell)
```
O script executa `flutter create --platforms=android --org br.edu.vitrine --project-name vitrine .`, **preserva o código do projeto** (`lib/`, `test/`, `pubspec.yaml`) e define o nome do app como *Vitrine*.

**2. Baixar as dependências**
```bash
flutter pub get
```

**3. Testar em modo de desenvolvimento** (emulador Android ou celular com depuração USB)
```bash
flutter run
```

**4. Gerar o APK de produção**
```bash
flutter build apk --release
```
Arquivo gerado em:
```
build/app/outputs/flutter-apk/app-release.apk
```
Copie-o para `apk/vitrine.apk` para versioná-lo junto com o código.

*(Opcional)* APKs menores, um por arquitetura de processador:
```bash
flutter build apk --release --split-per-abi
```

**5. Instalar no celular**
- Copie o `.apk` para o aparelho, abra o arquivo e permita "instalar apps de fontes desconhecidas"; ou
- Com o celular conectado por USB: `adb install -r apk/vitrine.apk`

## Assinatura do APK

O APK de *release* gerado pelo modelo padrão do Flutter é assinado com a **chave de depuração**, o que basta para instalar e demonstrar o app. Para publicar na Google Play seria necessário criar uma chave própria (`keytool -genkey ...`) e configurá-la em `android/key.properties` (arquivo que **não** deve ser versionado — já está no `.gitignore`).

Referência oficial: [Build and release an Android app](https://docs.flutter.dev/deployment/android).
