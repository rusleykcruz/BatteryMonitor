#!/bin/bash
# Script para configurar GitHub com Personal Access Token (PAT) de forma segura

# === CONFIGURAÇÕES ===
GITHUB_USER="rusleykcruz"              # seu usuário GitHub
REPO_NAME="BatteryMonitor"             # nome do repositório
EMAIL="rusleylb@gmail.com"           # seu e-mail do GitHub

echo "⚙️ Configurando Git..."
git init
git branch -M main
git config --global user.name "$GITHUB_USER"
git config --global user.email "$EMAIL"

# === CONFIGURAR HELPER DE CREDENCIAIS ===
echo "🔐 Configurando Git para armazenar credenciais..."
git config --global credential.helper store

# === CONFIGURAR REMOTE ===
echo "🔗 Configurando remote..."
git remote remove origin 2>/dev/null
git remote add origin https://github.com/$GITHUB_USER/$REPO_NAME.git

echo "✅ Remote configurado para https://github.com/$GITHUB_USER/$REPO_NAME.git"

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

echo "🎉 Push concluído! O token foi armazenado em ~/.git-credentials e não será mais necessário digitar."
