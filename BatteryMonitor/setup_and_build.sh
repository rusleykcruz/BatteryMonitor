#!/bin/bash
# Script para instalar Android SDK, configurar projeto e instalar APK

echo "🚀 Preparando ambiente..."

SDK_PATH="/root/android-sdk"
mkdir -p $SDK_PATH

# Baixar e instalar Command Line Tools
cd /tmp
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdtools.zip
unzip -o cmdtools.zip -d $SDK_PATH/cmdline-tools
mv $SDK_PATH/cmdline-tools/cmdline-tools $SDK_PATH/cmdline-tools/latest

# Configurar variáveis de ambiente
export ANDROID_HOME=$SDK_PATH
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH

echo "✅ SDK Manager instalado em $SDK_PATH"

# Aceitar licenças e instalar pacotes básicos
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

echo "✅ SDK básico instalado (platform-tools, build-tools, Android 34)"

# Atualizar local.properties
cd /root/BatteryMonitor
cat > local.properties << EOF
sdk.dir=$SDK_PATH
EOF
echo "✅ local.properties atualizado para $SDK_PATH"

# Atualizar settings.gradle
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

# Atualizar build.gradle (raiz)
cat > build.gradle << 'EOF'
plugins {
    id 'com.android.application' version '8.1.1' apply false
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
EOF

# Atualizar app/build.gradle
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

echo "⚙️ Limpando cache do Gradle..."
rm -rf ~/.gradle/caches ~/.gradle/daemon

echo "📦 Rodando build..."
gradle assembleDebug --no-daemon --info

APK_PATH="app/build/outputs/apk/debug/app-debug.apk"

if [ -f "$APK_PATH" ]; then
    echo "✅ Build concluído. Instalando APK no dispositivo..."
    adb install -r "$APK_PATH"
    echo "🎉 APK instalado com sucesso!"
else
    echo "❌ APK não encontrado. Verifique se o build gerou o arquivo em $APK_PATH"
fi
