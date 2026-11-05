package com.duckolly.dvizh

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private var aboutBridge: AboutBridge? = null
    private var batteryBridge: BatteryBridge? = null
    private var skyCompass: SkyCompassBridge? = null
    private val toolSensors = mutableListOf<ToolSensorBridge>()
    private var visible=false
    private val eventToken=Any()
    private val serviceIntent by lazy { Intent(applicationContext,DailyStepService::class.java) }
    override fun onDestroy() { aboutBridge?.close(); aboutBridge=null; batteryBridge?.close(); batteryBridge=null; skyCompass?.close(); skyCompass=null; toolSensors.forEach { it.close() }; toolSensors.clear(); DailyRuntime.bind(applicationContext,eventToken,null); super.onDestroy() }
    override fun onResume() { super.onResume(); visible=true; EnergyRuntime.usage.begin("foreground",this); skyCompass?.setVisible(true); toolSensors.forEach { it.setVisible(true) }; DailyRuntime.worker.post { DailyRuntime.uiVisible=true; DailyRuntime.owner?.setInteractive(true); runCatching { ProgressWidget.refresh(applicationContext,true) } } }
    override fun onPause() { visible=false; EnergyRuntime.usage.end("foreground",this); skyCompass?.setVisible(false); toolSensors.forEach { it.setVisible(false) }; DailyRuntime.worker.post { DailyRuntime.uiVisible=false; DailyRuntime.owner?.setInteractive(DailyRuntime.interactive) }; super.onPause() }
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        ReportBridge.install(this, engine)
        WaterBridge.install(this,engine) { visible }
        DeviceBridge.install(applicationContext,engine)
        batteryBridge?.close(); batteryBridge=BatteryBridge(this,engine)
        aboutBridge?.close(); aboutBridge=AboutBridge(this,engine)
        skyCompass?.close(); skyCompass=SkyCompassBridge(this,engine).also { it.setVisible(visible) }
        toolSensors.forEach { it.close() }; toolSensors.clear()
        listOf("tilt", "pressure").forEach { mode -> toolSensors.add(ToolSensorBridge(this,engine,mode).also { it.setVisible(visible) }) }
        val context=applicationContext
        MethodChannel(engine.dartExecutor.binaryMessenger,"dvizh/daily").setMethodCallHandler { call,result ->
            if(call.method !in listOf("status","enable","disable","clear")) { result.notImplemented(); return@setMethodCallHandler }
            if(call.method=="enable" && !visible) { result.error("not_visible","Откройте приложение для запуска",null); return@setMethodCallHandler }
            DailyRuntime.worker.post {
                try {
                    val store=DailyRuntime.store(context)
                    when(call.method) {
                        "enable" -> {
                            check(DailyRuntime.supported(context)) { "На телефоне нет системного счётчика шагов" }
                            check(DailyRuntime.permission(context)) { "Нет разрешения на распознавание активности" }
                            if(!DailyRuntime.running || !store.state().enabled || DailyRuntime.suppressed) {
                                store.enable(); DailyRuntime.enabledAfterNanos=android.os.SystemClock.elapsedRealtimeNanos()
                            }
                            DailyRuntime.suppressed=false
                            DailyRuntime.issue=""
                        }
                        "disable" -> { DailyRuntime.stopNow(); store.disable(); DailyRuntime.issue="" }
                        "clear" -> { DailyRuntime.stopNow(); store.clear(); DailyRuntime.issue="" }
                    }
                    if(call.method!="status") runCatching { ProgressWidget.refresh(context,true) }
                    val state=DailyRuntime.snapshot(context)
                    DailyRuntime.main.post {
                        try {
                            if(call.method=="enable") {
                                val intent=serviceIntent
                                if(Build.VERSION.SDK_INT>=26) context.startForegroundService(intent) else context.startService(intent)
                            } else if(call.method=="disable" || call.method=="clear") context.stopService(serviceIntent)
                            result.success(state)
                        } catch(_:RuntimeException) {
                            DailyRuntime.worker.post {
                                DailyRuntime.stopNow(); runCatching { store.disable() }; DailyRuntime.issue="start_failed"
                                DailyRuntime.main.post { context.stopService(serviceIntent); result.error("start_failed","Не удалось запустить фоновый подсчёт",null) }
                            }
                        }
                    }
                } catch(_:RuntimeException) {
                    if(call.method=="disable" || call.method=="clear") DailyRuntime.main.post { context.stopService(serviceIntent) }
                    DailyRuntime.main.post { result.error("daily_error","Не удалось выполнить операцию шагомера",null) }
                }
            }
        }
        EventChannel(engine.dartExecutor.binaryMessenger,"dvizh/daily/events").setStreamHandler(object:EventChannel.StreamHandler {

            override fun onListen(arguments:Any?,events:EventChannel.EventSink) { DailyRuntime.bind(context,eventToken,events) }
            override fun onCancel(arguments:Any?) { DailyRuntime.bind(context,eventToken,null) }
        })
    }
}
