package com.duckolly.dvizh

import android.Manifest
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/** One serialized actor for checkpoint, samples, toggle and delete; no background timer. */
object DailyRuntime {
    private val thread = HandlerThread("daily-step-store").apply { start() }
    val worker = Handler(thread.looper)
    val main = Handler(Looper.getMainLooper())
    private var database: DailyStore? = null
    private var waterDatabase: WaterStore? = null
    fun water(context: Context): WaterStore = waterDatabase ?: WaterStore(context.applicationContext).also { waterDatabase=it }
    var owner: DailyStepService? = null // worker thread only
    var running = false // worker thread only
    var enabledAfterNanos = 0L
    fun stopNow() { runCatching { owner?.flushPending() }; suppressed=true; enabledAfterNanos=Long.MAX_VALUE; running=false; owner?.haltSensor() }
    var suppressed = false // user stop has priority even if storage fails
    var uiVisible = false
    var interactive = false
    var workoutSyncPending = false
    var issue = ""
    @Volatile private var sink: EventChannel.EventSink? = null
    private var sinkOwner: Any? = null
    fun store(context: Context): DailyStore = database ?: DailyStore(context.applicationContext).also { database=it }
    fun supported(context: Context): Boolean = context.getSystemService(SensorManager::class.java).getDefaultSensor(Sensor.TYPE_STEP_COUNTER)!=null
    fun permission(context: Context): Boolean = Build.VERSION.SDK_INT<29 || context.checkSelfPermission(Manifest.permission.ACTIVITY_RECOGNITION)==PackageManager.PERMISSION_GRANTED
    fun snapshot(context: Context): Map<String,Any> = store(context).snapshot() + mapOf("enabled" to (store(context).state().enabled && !suppressed),"syncPending" to workoutSyncPending,"supported" to supported(context),"running" to running,"permissionGranted" to permission(context),"notificationsAllowed" to context.getSystemService(NotificationManager::class.java).areNotificationsEnabled(),"issue" to issue)
    fun emit(context: Context, forceWidget: Boolean = false) {
        runCatching { ProgressWidget.refresh(context, forceWidget) }
        val target = sink ?: return
        val s=store(context).state()
        val snapshot=mapOf("enabled" to (s.enabled && !suppressed),"running" to running,"totalRecorded" to s.total,"syncPending" to workoutSyncPending)
        main.post { if(sink===target) try { target.success(snapshot) } catch(_:RuntimeException) { sink=null; worker.post { interactive=false; owner?.setInteractive(uiVisible) } } }
    }
    fun bind(context: Context, token: Any, events: EventChannel.EventSink?) {
        worker.post { if(events!=null) { sinkOwner=token; sink=events; interactive=true; workoutSyncPending=true; owner?.setInteractive(true); runCatching { emit(context) }.onFailure { main.post { runCatching { events.error("storage_error","Не удалось прочитать счётчик",null) } } } } else if(sinkOwner===token) { sink=null; sinkOwner=null; interactive=false; workoutSyncPending=false; owner?.setInteractive(uiVisible) } }
    }
}
