package com.duckolly.dvizh

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object WaterBridge {
    fun install(activity: MainActivity, engine: FlutterEngine, visible: () -> Boolean) {
        val context=activity.applicationContext
        MethodChannel(engine.dartExecutor.binaryMessenger,"dvizh/water").setMethodCallHandler { call,result ->
            if(call.method=="pinWidget") {
                if(!visible()) { result.error("not_visible","Откройте приложение",null); return@setMethodCallHandler }
                try {
                    val manager=AppWidgetManager.getInstance(context)
                    result.success(Build.VERSION.SDK_INT>=26 && manager.isRequestPinAppWidgetSupported && manager.requestPinAppWidget(ComponentName(context,ProgressWidget::class.java),null,null))
                } catch(_:RuntimeException) { result.error("widget_error","Не удалось запросить виджет",null) }
                return@setMethodCallHandler
            }
            if(call.method !in listOf("status","change","clear")) { result.notImplemented(); return@setMethodCallHandler }
            val delta=call.argument<Int>("delta")
            if(call.method=="change" && delta!=1 && delta != -1) { result.error("invalid_delta","Допустим один стакан",null); return@setMethodCallHandler }
            DailyRuntime.worker.post {
                try {
                    val water=DailyRuntime.water(context)
                    when(call.method) { "change" -> water.change(delta!!); "clear" -> water.clear() }
                    val snapshot=water.snapshot()
                    if(call.method!="status") runCatching { ProgressWidget.refresh(context,true) }
                    DailyRuntime.main.post { result.success(snapshot) }
                } catch(_:RuntimeException) { DailyRuntime.main.post { result.error("water_error","Не удалось сохранить или прочитать воду",null) } }
            }
        }
    }
}
