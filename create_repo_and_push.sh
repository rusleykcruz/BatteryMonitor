#!/bin/bash
# Script para criar repositório no GitHub via API, configurar Git e enviar projeto

# === CONFIGURAÇÕES ===
GITHUB_USER="rusleykcruz"              # seu usuário GitHub
REPO_NAME="BatteryMonitor"             # nome do repositório desejado
TOKEN="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"                 # cole aqui seu PAT gerado no GitHub

# === CRIAR REPOSITÓRIO NO GITHUB ===
echo "🚀 Criando repositório $REPO_NAME no GitHub..."
curl -H "Authorization: token $TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     https://api.github.com/user/repos \
     -d "{\"name\":\"$REPO_NAME\",\"private\":false}"

# === CONFIGURAR GIT LOCAL ===
echo "⚙️ Configurando Git local..."
git init
git branch -M main
git remote add origin https://$GITHUB_USER:$TOKEN@github.com/$GITHUB_USER/$REPO_NAME.git
git config --global user.name "$GITHUB_USER"
git config --global user.email "seuemail@example.com"

# === CRIAR WORKFLOW GITHUB ACTIONS ===
mkdir -p .github/workflows
cat > .github/workflows/android-build.yml << 'EOF'
name: Android Build

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout código
        uses: actions/checkout@v3

      - name: Configurar JDK 21
        uses: actions/setup-java@v3
        with:
          java-version: '21'
          distribution: 'temurin'

      - name: Instalar Android SDK
        run: |
          sudo mkdir -p /usr/local/android-sdk
          sudo chown $USER:$USER /usr/local/android-sdk
          wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdtools.zip
          unzip cmdtools.zip -d /usr/local/android-sdk/cmdline-tools
          mv /usr/local/android-sdk/cmdline-tools/cmdline-tools /usr/local/android-sdk/cmdline-tools/latest
          export ANDROID_HOME=/usr/local/android-sdk
          export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH
          yes | sdkmanager --licenses
          sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

      - name: Build APK
        run: ./gradlew assembleDebug

      - name: Upload APK como artefato
        uses: actions/upload-artifact@v3
        with:
          name: app-debug
          path: app/build/outputs/apk/debug/app-debug.apk
EOF

# === COMMIT E PUSH ===
echo "📂 Adicionando arquivos..."
git add .
echo "📝 Criando commit inicial..."
git commit -m "Configuração inicial do projeto Android + CI"
echo "🚀 Enviando para GitHub..."
git push -u origin main

echo "🎉 Projeto pronto! O workflow será executado no GitHub Actions e o APK ficará disponível em Artifacts."
