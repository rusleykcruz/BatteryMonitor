#!/bin/bash
# Script inicial para configurar projeto Git + GitHub Actions

# === CONFIGURAÇÕES ===
GITHUB_USER="rusleykcruz"              # seu usuário GitHub
REPO_NAME="BatteryMonitor"             # nome do repositório
EMAIL="ruslwypb@gmail.com"           # seu e-mail do GitHub

echo "⚙️ Configurando Git..."
git init
git branch -M main
git config --global user.name "$GITHUB_USER"
git config --global user.email "$EMAIL"

# === CONFIGURAR REMOTE ===
echo "🔗 Configurando remote..."
git remote remove origin 2>/dev/null
git remote add origin https://github.com/$GITHUB_USER/$REPO_NAME.git

echo "✅ Remote configurado para https://github.com/$GITHUB_USER/$REPO_NAME.git"

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

echo "✅ Workflow GitHub Actions criado."

# === PRIMEIRO COMMIT ===
echo "📂 Adicionando arquivos..."
git add .
echo "📝 Criando commit inicial..."
git commit -m "Configuração inicial do projeto Android + CI"

# === PUSH (vai pedir token uma vez) ===
echo "🚀 Fazendo push para GitHub..."
echo "👉 Quando pedir 'Username', digite: $GITHUB_USER"
echo "👉 Quando pedir 'Password', cole seu Personal Access Token (PAT)"
git push -u origin main

echo "🎉 Projeto inicial enviado para GitHub! O workflow será executado e o APK ficará disponível em Artifacts."
