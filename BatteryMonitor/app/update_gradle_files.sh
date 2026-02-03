#!/bin/bash
# Script para atualizar arquivos Gradle do projeto BatteryMonitor

echo "🚀 Atualizando arquivos Gradle..."

# Atualizar settings.gradle
cat > settings.gradle << 'EOF'
include ':app'
EOF
echo "✅ settings.gradle atualizado."

# Atualizar build.gradle (raiz)
cat > build.gradle << 'EOF'
plugins {
    id 'com.android.application' version '8.1.1' apply false
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
EOF
echo "✅ build.gradle (raiz) atualizado."

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

dependencies {
    implementation fileTree(dir: "libs", include: ["*.jar"])
}
EOF
echo "✅ app/build.gradle atualizado."

echo "⚙️ Limpando cache do Gradle..."
rm -rf ~/.gradle/caches ~/.gradle/daemon

echo "📦 Rodando build..."
gradle build --info
