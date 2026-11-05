package com.duckolly.dvizh

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Reads existing databases on their serialized worker. No new history format. */
object ReportBridge {
    fun install(activity: MainActivity, engine: FlutterEngine) {
        val context = activity.applicationContext
        MethodChannel(engine.dartExecutor.binaryMessenger, "dvizh/reports").setMethodCallHandler { call, result ->
            if (call.method != "load") { result.notImplemented(); return@setMethodCallHandler }
            DailyRuntime.worker.post {
                try {
                    val steps = DailyRuntime.store(context).readableDatabase.rawQuery(
                        "SELECT day,steps,estimated FROM days ORDER BY day", null).use { c ->
                        buildList { while (c.moveToNext()) add(mapOf("day" to c.getString(0),
                            "steps" to c.getLong(1), "estimated" to (c.getInt(2) != 0))) }
                    }
                    val water = DailyRuntime.water(context).readableDatabase.rawQuery(
                        "SELECT day,glasses FROM water ORDER BY day", null).use { c ->
                        buildList { while (c.moveToNext()) add(mapOf("day" to c.getString(0), "glasses" to c.getLong(1))) }
                    }
                    DailyRuntime.main.post { result.success(mapOf("steps" to steps, "water" to water)) }
                } catch (_: RuntimeException) {
                    DailyRuntime.main.post { result.error("report_error", "Не удалось прочитать историю", null) }
                }
            }
        }
    }
}
