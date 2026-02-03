#!/bin/bash
# Script inicial para configurar projeto Android no GitHub com CI/CD
# Remove arquivos grandes do histórico e cria workflow básico

# === CONFIGURAÇÕES ===
GITHUB_USER="rusleykcruz"              # seu usuário GitHub
REPO_NAME="BatteryMonitor"             # nome do repositório
EMAIL="seuemail@example.com"           # seu e-mail do GitHub

echo "⚙️ Configurando Git..."
git init
git branch -M main
git config --global user.name "$GITHUB_USER"
git config --global user.email "$EMAIL"

# === LIMPAR ARQUIVOS GRANDES DO HISTÓRICO ===
echo "🧹 Removendo arquivos grandes do histórico..."
if ! command -v git-filter-repo &> /dev/null
then
    echo "📦 Instalando git-filter-repo..."
    pip install git-filter-repo
fi

git filter-repo --path cmdline-tools.zip --path gradle-8.4-bin.zip --invert-paths

# === AJUSTAR .gitignore ===
echo "📝 Criando .gitignore..."
cat > .gitignore <<EOF
# Ignorar arquivos grandes e temporários
cmdline-tools.zip
gradle-*.zip
android-sdk/
.gradle/
build/
EOF

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

      - name: Cache Gradle
        uses: actions/cache@v3
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
          restore-keys: |
            ${{ runner.os }}-gradle-

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

# === CONFIGURAR REMOTE ===
echo "🔗 Configurando remote..."
git remote remove origin 2>/dev/null
git remote add origin https://github.com/$GITHUB_USER/$REPO_NAME.git

# === PUSH (vai pedir token uma vez) ===
echo "🚀 Fazendo push para GitHub..."
echo "👉 Quando pedir 'Username', digite: $GITHUB_USER"
echo "👉 Quando pedir 'Password', cole seu Personal Access Token (PAT)"
git push --force -u origin main

echo "🎉 Projeto inicial enviado para GitHub! O workflow será executado e o APK ficará disponível em Artifacts."
