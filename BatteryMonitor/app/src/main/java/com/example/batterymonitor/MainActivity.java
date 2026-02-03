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
