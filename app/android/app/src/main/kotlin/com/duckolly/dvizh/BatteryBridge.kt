package com.duckolly.dvizh
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.os.SystemClock
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** On-demand snapshots only. No receiver retained, timer, service or privileged access. */
class BatteryBridge(private val activity: MainActivity,engine: FlutterEngine) {
    private val channel=MethodChannel(engine.dartExecutor.binaryMessenger,"dvizh/battery")
    init {
        channel.setMethodCallHandler { call,result ->
            try {
                when(call.method) {
                    "snapshot"->result.success(snapshot())
                    "appSettings"->result.success(open(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.fromParts("package",activity.packageName,null))))
                    "powerSettings"->result.success(open(Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS)))
                    else->result.notImplemented()
                }
            } catch(_:RuntimeException) { result.error("battery_unavailable","Не удалось получить данные батареи",null) }
        }
    }
    fun close(){channel.setMethodCallHandler(null)}
    private fun open(intent: Intent): Boolean = try { activity.startActivity(intent);true } catch(_:RuntimeException){false}
    private fun snapshot(): Map<String,Any?> {
        val filter=IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val battery=if(Build.VERSION.SDK_INT>=33)activity.registerReceiver(null,filter,Context.RECEIVER_NOT_EXPORTED)
            else activity.registerReceiver(null,filter)
        val level=battery?.getIntExtra(BatteryManager.EXTRA_LEVEL,-1)?:-1
        val scale=battery?.getIntExtra(BatteryManager.EXTRA_SCALE,-1)?:-1
        val percent=if(scale>0 && level in 0..scale)level*100.0/scale else null
        val temp=battery?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE,Int.MIN_VALUE)?:Int.MIN_VALUE
        val temperature=if(temp in -400..1200)temp/10.0 else null
        val plugged=battery?.getIntExtra(BatteryManager.EXTRA_PLUGGED,-1)?:-1
        val power=activity.getSystemService(PowerManager::class.java)
        val thermal=if(Build.VERSION.SDK_INT>=29)runCatching { power.currentThermalStatus }.getOrNull()?.takeIf { it in 0..6 } else null
        val boot=runCatching { Settings.Global.getInt(activity.contentResolver,Settings.Global.BOOT_COUNT,-1) }.getOrNull()?.takeIf{it>=0}
        return mapOf("wallMs" to System.currentTimeMillis(),"elapsedMs" to SystemClock.elapsedRealtime(),
            "cpuMs" to Process.getElapsedCpuTime(),"processToken" to EnergyRuntime.processToken,
            "bootCount" to boot,"percent" to percent,"temperature" to temperature,
            "plugged" to if(plugged>=0)(plugged>0) else null,"powerSave" to power.isPowerSaveMode,
            "thermal" to thermal,"usage" to EnergyRuntime.usage.snapshot(),"active" to EnergyRuntime.usage.activeNames(),
            "model" to (Build.MANUFACTURER+" "+Build.MODEL),"android" to Build.VERSION.RELEASE)
    }
}
