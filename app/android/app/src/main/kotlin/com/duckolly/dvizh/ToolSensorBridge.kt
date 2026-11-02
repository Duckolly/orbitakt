package com.duckolly.dvizh

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.Surface
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/** One foreground-only sensor lease. No service, permission or persisted samples. */
class ToolSensorBridge(private val activity: MainActivity, engine: FlutterEngine,
    private val mode: String) : SensorEventListener {
    private val manager = activity.getSystemService(SensorManager::class.java)
    private val sensor = manager.getDefaultSensor(if (mode == "tilt") Sensor.TYPE_ACCELEROMETER else Sensor.TYPE_PRESSURE)
    private val main = Handler(Looper.getMainLooper())
    private val methods = MethodChannel(engine.dartExecutor.binaryMessenger, "dvizh/$mode")
    private val events = EventChannel(engine.dartExecutor.binaryMessenger, "dvizh/$mode/events")
    private var sink: EventChannel.EventSink? = null
    private var visible = false
    private var registered = false
    private var closed = false
    private var enabledAfter = Long.MAX_VALUE
    private var lastSent = 0L
    init {
        methods.setMethodCallHandler { call, result ->
            if (call.method == "status") result.success(mapOf("supported" to (sensor != null)))
            else result.notImplemented()
        }
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, target: EventChannel.EventSink) { stop(); sink = target; start() }
            override fun onCancel(arguments: Any?) { stop(); sink = null }
        })
    }
    fun setVisible(value: Boolean) {
        visible = value
        if (!value) { stop(); emit(mapOf("state" to "paused")) }
        // Resumption requires a new explicit Flutter subscription.
    }
    fun close() { closed = true; stop(); sink = null; events.setStreamHandler(null); methods.setMethodCallHandler(null) }
    private fun start() {
        if (closed || sink == null) return
        if (!visible) { emit(mapOf("state" to "paused")); return }
        if (sensor == null) { emit(mapOf("state" to "unavailable")); return }
        enabledAfter = SystemClock.elapsedRealtimeNanos(); lastSent = 0
        try {
            registered = manager.registerListener(this, sensor, if (mode == "tilt") 50_000 else 200_000, main)
            if (!registered) { stop(); emit(mapOf("state" to "error")) }
            else EnergyRuntime.usage.begin(mode,this)
        } catch (_: RuntimeException) { stop(); emit(mapOf("state" to "error")) }
    }
    private fun stop() { EnergyRuntime.usage.end(mode,this); manager.unregisterListener(this); registered = false; enabledAfter = Long.MAX_VALUE }
    override fun onSensorChanged(event: SensorEvent) {
        if (!registered || !visible || closed || sink == null || event.timestamp < enabledAfter) return
        val now = SystemClock.elapsedRealtimeNanos()
        if (now - event.timestamp > 1_500_000_000L || event.timestamp > now + 100_000_000L) return
        val millis = SystemClock.elapsedRealtime()
        if (millis - lastSent < if (mode == "tilt") 50 else 200) return
        val values: Map<String, Any>
        if (mode == "tilt") {
            if (event.values.size < 3 || (0..2).any { !event.values[it].isFinite() }) return
            @Suppress("DEPRECATION")
            val rotation = if (Build.VERSION.SDK_INT >= 30) activity.display?.rotation ?: Surface.ROTATION_0 else activity.windowManager.defaultDisplay.rotation
            val xy = ToolSensorMath.screenGravity(event.values[0].toDouble(), event.values[1].toDouble(), rotation)
            values = mapOf("state" to "reading", "x" to xy.first, "y" to xy.second, "z" to event.values[2].toDouble(), "rotation" to rotation)
        } else {
            if (event.values.isEmpty() || !event.values[0].isFinite() || event.values[0] <= 0f) return
            values = mapOf("state" to "reading", "pressure" to event.values[0].toDouble())
        }
        lastSent = millis; emit(values)
    }
    override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) { }
    private fun emit(data: Map<String, Any>) {
        runCatching { sink?.success(data) }.onFailure { stop(); sink = null }
    }
}
