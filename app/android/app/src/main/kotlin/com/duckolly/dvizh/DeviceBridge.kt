package com.duckolly.dvizh

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorManager
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Read-only inventory; does not register listeners or request activity permission. */
object DeviceBridge {
    fun install(context: Context, engine: FlutterEngine) {
        val app = context.applicationContext
        MethodChannel(engine.dartExecutor.binaryMessenger, "dvizh/device").setMethodCallHandler { call, result ->
            if (call.method != "listSensors") { result.notImplemented(); return@setMethodCallHandler }
            DailyRuntime.worker.post {
                try {
                    val manager = app.getSystemService(SensorManager::class.java)
                    val sensors = manager.getSensorList(Sensor.TYPE_ALL).sortedWith(compareBy({ it.type }, { it.name })).map { sensor ->
                        mapOf("type" to sensor.type, "name" to sensor.name, "vendor" to sensor.vendor,
                            "label" to label(sensor.type), "power" to sensor.power.toDouble(),
                            "resolution" to sensor.resolution.toDouble(), "maxRange" to sensor.maximumRange.toDouble(),
                            "minDelay" to sensor.minDelay, "wakeUp" to sensor.isWakeUpSensor)
                    }
                    val inventory = mapOf("manufacturer" to Build.MANUFACTURER, "model" to Build.MODEL,
                        "release" to Build.VERSION.RELEASE, "sdk" to Build.VERSION.SDK_INT, "sensors" to sensors)
                    DailyRuntime.main.post { result.success(inventory) }
                } catch (_: RuntimeException) {
                    DailyRuntime.main.post { result.error("sensor_inventory", "Не удалось получить датчики", null) }
                }
            }
        }
    }
    private fun label(type: Int): String = when (type) {
        Sensor.TYPE_ACCELEROMETER -> "Акселерометр"
        Sensor.TYPE_MAGNETIC_FIELD -> "Магнитометр"
        Sensor.TYPE_GYROSCOPE -> "Гироскоп"
        Sensor.TYPE_LIGHT -> "Освещённость"
        Sensor.TYPE_PRESSURE -> "Атмосферное давление"
        Sensor.TYPE_PROXIMITY -> "Приближение"
        Sensor.TYPE_GRAVITY -> "Гравитация"
        Sensor.TYPE_LINEAR_ACCELERATION -> "Линейное ускорение"
        Sensor.TYPE_ROTATION_VECTOR -> "Вектор вращения"
        Sensor.TYPE_RELATIVE_HUMIDITY -> "Относительная влажность"
        Sensor.TYPE_AMBIENT_TEMPERATURE -> "Температура окружающей среды"
        Sensor.TYPE_STEP_DETECTOR -> "События шагов"
        Sensor.TYPE_STEP_COUNTER -> "Системный счётчик шагов"
        Sensor.TYPE_HEART_RATE -> "Частота сердечных сокращений"
        else -> "Датчик Android (тип $type)"
    }
}
