#!/usr/bin/env bash
# Gera a pasta android/ (projeto Android nativo exigido para compilar o APK)
# SEM sobrescrever o código-fonte do app (lib/, test/, pubspec.yaml).
#
# Uso (na raiz do repositório, com o Flutter instalado):  bash scripts/bootstrap.sh
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -d android ]; then
  echo "A pasta android/ já existe - nada a fazer."
  exit 0
fi

backup="$(mktemp -d)"
cp -r lib test "$backup"/
cp pubspec.yaml analysis_options.yaml "$backup"/

flutter create --platforms=android --org br.edu.vitrine --project-name vitrine --no-pub .

# Garante que o código do projeto continua sendo o nosso, não o do modelo do Flutter.
rm -rf lib test
cp -r "$backup/lib" "$backup/test" .
cp "$backup/pubspec.yaml" "$backup/analysis_options.yaml" .
rm -rf "$backup"

# Nome exibido sob o ícone do app.
manifest="android/app/src/main/AndroidManifest.xml"
sed -i 's/android:label="vitrine"/android:label="Vitrine"/' "$manifest"

echo "Projeto Android gerado em android/ (nome do app: Vitrine)."
