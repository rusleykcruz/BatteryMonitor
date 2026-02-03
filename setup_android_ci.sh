#!/bin/bash
# Script completo para configurar Git, Android SDK e CI com GitHub Actions

echo "🚀 Preparando ambiente Android + Git + CI..."

# === CONFIGURAÇÃO DO GIT ===
echo "⚙️ Configurando Git..."
git init
git branch -M main
git remote add origin https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git
git config --global user.name "Seu Nome"
git config --global user.email "seuemail@example.com"
echo "✅ Git configurado."

# === INSTALAÇÃO DO ANDROID SDK LOCAL (opcional para testes) ===
SDK_PATH="/root/android-sdk"
mkdir -p $SDK_PATH
cd /tmp
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdtools.zip
unzip -o cmdtools.zip -d $SDK_PATH/cmdline-tools
mv $SDK_PATH/cmdline-tools/cmdline-tools $SDK_PATH/cmdline-tools/latest

export ANDROID_HOME=$SDK_PATH
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH

yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
echo "✅ SDK instalado em $SDK_PATH"

# === CONFIGURAÇÃO DO PROJETO GRADLE ===
cd /root/BatteryMonitor

cat > settings.gradle << 'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
include ':app'
EOF

cat > build.gradle << 'EOF'
plugins {
    id 'com.android.application' version '8.1.1' apply false
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
EOF

cat > app/build.gradle << 'EOF'
plugins {
    id 'com.android.application'
}

android {
    namespace "com.example.batterymonitor"
    compileSdk 34

    defaultConfig {
        applicationId "com.example.batterymonitor"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            minifyEnabled false
        }
    }
}

repositories {
    google()
    mavenCentral()
}

dependencies {
    implementation fileTree(dir: "libs", include: ["*.jar"])
}
EOF

cat > local.properties << EOF
sdk.dir=$SDK_PATH
EOF

echo "✅ Projeto configurado."

# === CONFIGURAÇÃO DO WORKFLOW GITHUB ACTIONS ===
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
git add .
git commit -m "Configuração inicial do projeto Android + CI"
git push -u origin main

echo "🎉 Projeto pronto! O workflow será executado no GitHub Actions e o APK ficará disponível em Artifacts."
