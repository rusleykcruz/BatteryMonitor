#!/bin/bash
# Script para configurar, compilar e instalar o app BatteryMonitor dentro do Ubuntu (proot-distro no Termux)
# Compatível com Java 21 + Gradle 8.4 + Android Gradle Plugin 8.1.1

echo "🚀 Iniciando configuração do ambiente..."

# Atualizar pacotes
apt update -y && apt upgrade -y

# Instalar dependências
apt install -y openjdk-21 wget unzip git nano

echo "✅ Dependências instaladas."

# Baixar Gradle 8.4
echo "⬇️ Baixando Gradle..."
wget https://services.gradle.org/distributions/gradle-8.4-bin.zip -O gradle-8.4-bin.zip
unzip gradle-8.4-bin.zip -d /opt
export PATH=/opt/gradle-8.4/bin:$PATH
echo "✅ Gradle configurado."

# Baixar Android SDK Command Line Tools
echo "⬇️ Baixando Android SDK..."
mkdir -p $HOME/android-sdk/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline-tools.zip
unzip cmdline-tools.zip -d $HOME/android-sdk/cmdline-tools
mv $HOME/android-sdk/cmdline-tools/cmdline-tools $HOME/android-sdk/cmdline-tools/latest

# Configurar variáveis de ambiente
export ANDROID_HOME=$HOME/android-sdk
export ANDROID_SDK_ROOT=$HOME/android-sdk
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH

echo "✅ SDK configurado."

# Aceitar licenças e instalar SDK básico
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

echo "✅ SDK instalado."

# Criar estrutura do projeto
mkdir -p BatteryMonitor/app/src/main/java/com/example/batterymonitor
cd BatteryMonitor

# settings.gradle
cat > settings.gradle << 'EOF'
include ':app'
EOF

# build.gradle (raiz) - usando AGP 8.1.1
cat > build.gradle << 'EOF'
plugins {
    id 'com.android.application' version '8.1.1' apply false
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
EOF

# build.gradle (app) - sintaxe moderna
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

# AndroidManifest.xml corrigido
cat > app/src/main/AndroidManifest.xml << 'EOF'
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.batterymonitor">

    <application
        android:allowBackup="true"
        android:label="Battery Monitor"
        android:supportsRtl="true"
        android:theme="@android:style/Theme.Material.Light">
        
        <activity 
            android:name=".MainActivity"
            android:exported="true">
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>

</manifest>
EOF

# MainActivity.java
cat > app/src/main/java/com/example/batterymonitor/MainActivity.java << 'EOF'
package com.example.batterymonitor;

import android.app.Activity;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.BatteryManager;
import android.os.Bundle;
import android.os.Handler;
import android.widget.TextView;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;

public class MainActivity extends Activity {

    private TextView tv;
    private Handler handler = new Handler();

    private String readSysFile(String path) {
        try {
            BufferedReader br = new BufferedReader(new FileReader(path));
            String line = br.readLine();
            br.close();
            return line;
        } catch (IOException e) {
            return null;
        }
    }

    private void updateBatteryInfo() {
        IntentFilter ifilter = new IntentFilter(Intent.ACTION_BATTERY_CHANGED);
        Intent batteryStatus = registerReceiver(null, ifilter);

        int level = batteryStatus.getIntExtra(BatteryManager.EXTRA_LEVEL, -1);
        int scale = batteryStatus.getIntExtra(BatteryManager.EXTRA_SCALE, -1);
        int status = batteryStatus.getIntExtra(BatteryManager.EXTRA_STATUS, -1);
        int plugged = batteryStatus.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1);

        float batteryPct = level * 100 / (float)scale;

        String statusText;
        if (status == BatteryManager.BATTERY_STATUS_CHARGING) {
            statusText = "Carregando";
        } else if (status == BatteryManager.BATTERY_STATUS_FULL) {
            statusText = "Bateria cheia";
        } else {
            statusText = "Não está carregando";
        }

        String plugText;
        if (plugged == BatteryManager.BATTERY_PLUGGED_USB) {
            plugText = "USB";
        } else if (plugged == BatteryManager.BATTERY_PLUGGED_AC) {
            plugText = "Tomada";
        } else if (plugged == BatteryManager.BATTERY_PLUGGED_WIRELESS) {
            plugText = "Sem fio";
        } else {
            plugText = "Nenhum";
        }

        String currentNow = readSysFile("/sys/class/power_supply/battery/current_now");
        String voltageNow = readSysFile("/sys/class/power_supply/battery/voltage_now");

        String displayText;

        if (currentNow != null && voltageNow != null) {
            try {
                float currentMa = Integer.parseInt(currentNow) / 1000f;
                float voltageV = Integer.parseInt(voltageNow) / 1000000f;

                displayText = "Bateria: " + batteryPct + "%\n" +
                              "Status: " + statusText + "\n" +
                              "Fonte: " + plugText + "\n" +
                              "Corrente: " + currentMa + " mA\n" +
                              "Voltagem: " + voltageV + " V";

                if (currentMa < 200 && status == BatteryManager.BATTERY_STATUS_CHARGING) {
                    displayText += "\n⚠️ Corrente baixa: bateria quase cheia!";
                }

            } catch (NumberFormatException e) {
                displayText = "Erro ao converter valores.\nBateria: " + batteryPct + "%";
            }
        } else {
            displayText = "Corrente/voltagem não disponíveis.\n" +
                          "Bateria: " + batteryPct + "%\nStatus: " + statusText + "\nFonte: " + plugText;
        }

        tv.setText(displayText);
        handler.postDelayed(this::updateBatteryInfo, 2000);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        tv = new TextView(this);
        tv.setTextSize(20);
        setContentView(tv);

        updateBatteryInfo();
    }
}
EOF

# local.properties
cat > local.properties << EOF
sdk.dir=$HOME/android-sdk
EOF

echo "⚙️ Compilando APK..."
gradle build

APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
if [ -f "$APK_PATH" ]; then
    echo "✅ APK gerado em $APK_PATH"
    echo "Para instalar no Android (fora do Ubuntu), rode:"
    echo "pm install $APK_PATH"
else
    echo "❌ Falha: APK não encontrado."
fi
