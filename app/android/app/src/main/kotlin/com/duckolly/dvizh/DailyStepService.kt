package com.duckolly.dvizh

import android.app.*
import android.content.Intent
import android.content.IntentFilter
import android.content.BroadcastReceiver
import android.content.Context
import android.content.pm.ServiceInfo
import android.hardware.*
import android.database.sqlite.SQLiteException
import android.os.*

class DailyStepService : Service(), SensorEventListener {
    private lateinit var sensors: SensorManager
    private var pending: Pair<Long,Long>? = null
    private var persistScheduled = false
    private var baselineReady = false
    private var lastEventNanos = 0L
    private val persist = Runnable { runCatching { flushPending() }.onFailure { fail(reasonFor(it)) } }
    private lateinit var subscription: StepSensorSubscription
    private var screenReceiverRegistered = false
    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            DailyRuntime.worker.post {
                if (DailyRuntime.owner !== this@DailyStepService || !DailyRuntime.running) return@post
                setInteractive(DailyRuntime.uiVisible || DailyRuntime.interactive)
                if (intent.action != Intent.ACTION_SCREEN_OFF) {
                    runCatching { flushPending(); sensors.flush(this@DailyStepService) }
                    runCatching { ProgressWidget.refresh(applicationContext, true) }
                }
            }
        }
    }
    private fun deliveryLatency(uiOrWorkout: Boolean): Int = StepDeliveryPolicy.maxLatencyUs(
        uiOrWorkout, getSystemService(PowerManager::class.java).isInteractive)
    override fun onCreate() {
        super.onCreate(); sensors=getSystemService(SensorManager::class.java)
        subscription = StepSensorSubscription(
            register = { latency ->
                val sensor = sensors.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
                sensor != null && sensors.registerListener(this, sensor,
                    SensorManager.SENSOR_DELAY_NORMAL, latency, DailyRuntime.worker)
            },
            unregister = { sensors.unregisterListener(this) }
        )
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON); addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT); addAction(Intent.ACTION_DATE_CHANGED)
            addAction(Intent.ACTION_TIME_CHANGED); addAction(Intent.ACTION_TIMEZONE_CHANGED)
        }
        // Registered only for the lifetime of the existing step service; never starts it.
        if (Build.VERSION.SDK_INT >= 33) registerReceiver(screenReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        else registerReceiver(screenReceiver, filter)
        screenReceiverRegistered = true
    }
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if(intent?.action=="STOP") {
            DailyRuntime.worker.post {
                DailyRuntime.stopNow()
                runCatching { DailyRuntime.store(this).disable() }
                if(DailyRuntime.owner===this) { haltSensor(); DailyRuntime.running=false }
                DailyRuntime.issue=""; runCatching { DailyRuntime.emit(this, true) }
                DailyRuntime.main.post { stopSelf() }
            }
            return START_NOT_STICKY
        }
        if(!DailyRuntime.permission(this) || !DailyRuntime.supported(this)) {
            DailyRuntime.worker.post {
                DailyRuntime.issue=if(!DailyRuntime.permission(this))"permission" else "no_sensor"
                DailyRuntime.stopNow(); runCatching { DailyRuntime.store(this).disable(); DailyRuntime.emit(this, true) }
            }
            stopSelf(); return START_NOT_STICKY
        }
        val manager=getSystemService(NotificationManager::class.java)
        if(Build.VERSION.SDK_INT>=26) manager.createNotificationChannel(NotificationChannel("daily_steps","Дневной шагомер",NotificationManager.IMPORTANCE_LOW))
        val open=PendingIntent.getActivity(this,0,Intent(this,MainActivity::class.java),PendingIntent.FLAG_IMMUTABLE)
        val stop=PendingIntent.getService(this,1,Intent(this,DailyStepService::class.java).setAction("STOP"),PendingIntent.FLAG_IMMUTABLE)
        val builder=if(Build.VERSION.SDK_INT>=26) Notification.Builder(this,"daily_steps") else Notification.Builder(this)
        val notification=builder.setSmallIcon(com.duckolly.dvizh.R.drawable.ic_stat_activity)
            .setContentTitle("ОРБИТАКТ · дневной шагомер включён").setContentText("Шаги сохраняются только на телефоне")
            .setVisibility(Notification.VISIBILITY_PRIVATE).setContentIntent(open).setOngoing(true)
            .addAction(Notification.Action.Builder(null,"Остановить",stop).build()).build()
        try {
            if(Build.VERSION.SDK_INT>=34) startForeground(2001,notification,ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH)
            else startForeground(2001,notification)
        } catch (error: RuntimeException) {
            val reason = if (error is SecurityException) "permission" else "start_failed"
            DailyRuntime.worker.post { DailyRuntime.stopNow(); DailyRuntime.issue=reason; runCatching { DailyRuntime.store(this).disable(); DailyRuntime.emit(this, true) } }
            stopSelf(); return START_NOT_STICKY
        }
        DailyRuntime.worker.post {
            var phase = "internal_error"
            try {
                if(DailyRuntime.suppressed || !DailyRuntime.store(this).state().enabled) { DailyRuntime.main.post { stopSelf() }; return@post }
                if(DailyRuntime.owner===this && DailyRuntime.running) return@post
                DailyRuntime.store(this).interrupted()
                DailyRuntime.owner=this
                baselineReady=DailyRuntime.store(this).state().raw>=0
                val latency = deliveryLatency(DailyRuntime.uiVisible || DailyRuntime.interactive)
                phase = "registration_failed"
                val ok = subscription.start(latency)
                DailyRuntime.running=ok; if(ok) EnergyRuntime.usage.begin("step",this) else EnergyRuntime.usage.end("step",this); DailyRuntime.issue=if(ok)"" else "registration_failed"
                if(!ok) { DailyRuntime.store(this).disable(); DailyRuntime.main.post { stopSelf() } }
                phase = "internal_error"
                DailyRuntime.emit(this, true)
            } catch (_: SecurityException) { fail("permission") }
              catch (_: SQLiteException) { fail("storage_error") }
              catch (_: RuntimeException) { fail(phase) }
        }
        // System may recreate an interrupted service; user STOP disables the stored intent.
        return START_STICKY
    }
    override fun onSensorChanged(event: SensorEvent) {
        if(DailyRuntime.owner!==this || !DailyRuntime.running || DailyRuntime.suppressed) return
        if(!CounterMath.accepts(event.timestamp,DailyRuntime.enabledAfterNanos) || event.timestamp<lastEventNanos) return
        lastEventNanos=event.timestamp
        val value=event.values.firstOrNull() ?: return
        if(!value.isFinite() || value<0 || value>9e15f) return
        try {
            val age=((SystemClock.elapsedRealtimeNanos()-event.timestamp)/1_000_000L).coerceAtLeast(0)
            pending=value.toLong() to (System.currentTimeMillis()-age)
            if(!baselineReady || DailyRuntime.interactive || DailyRuntime.uiVisible) flushPending()
            else if(!persistScheduled) {
                // Fixed maximum coalescing delay: sustained walking cannot postpone it.
                persistScheduled=true
                DailyRuntime.worker.postDelayed(persist,500)
            }
        } catch (error: RuntimeException) { fail(reasonFor(error)) }
    }
    fun flushPending() {
        DailyRuntime.worker.removeCallbacks(persist)
        persistScheduled=false
        val value=pending ?: return
        pending=null
        if(DailyRuntime.owner!==this || !DailyRuntime.running || DailyRuntime.suppressed) return
        DailyRuntime.store(this).sample(value.first,value.second)
        baselineReady=true
        DailyRuntime.workoutSyncPending=false
        DailyRuntime.emit(this)
    }
    fun haltSensor() {
        try { subscription.stop() } finally {
            EnergyRuntime.usage.end("step",this)
            DailyRuntime.worker.removeCallbacks(persist)
            persistScheduled=false
            pending=null
        }
    }
    fun setInteractive(interactive: Boolean) {
        if(DailyRuntime.owner!==this || !DailyRuntime.running) return
        val latency = deliveryLatency(interactive)
        if (subscription.latencyUs == latency) return
        // Commit the last received cumulative sample before changing queues.
        // Do not call enable()/disable(): they would reset the raw baseline.
        try { flushPending() } catch (error: RuntimeException) { fail(reasonFor(error)); return }
        try {
            if (!DailyRuntime.permission(this)) { fail("permission"); return }
            val result = subscription.change(latency)
            if (result == StepSensorSubscription.Change.FAILED ||
                result == StepSensorSubscription.Change.NOT_RUNNING) fail("registration_failed")
        } catch (_: SecurityException) { fail("permission") }
          catch (_: RuntimeException) { fail("registration_failed") }
    }
    private fun reasonFor(error: Throwable): String = when (error) {
        is SecurityException -> "permission"
        is SQLiteException -> "storage_error"
        else -> "internal_error"
    }
    private fun fail(reason: String) {
        // Cleanup failures must not prevent the stopped status reaching the UI.
        runCatching { haltSensor() }
        DailyRuntime.suppressed=true; DailyRuntime.running=false; DailyRuntime.issue=reason
        runCatching { DailyRuntime.store(this).disable() }
        runCatching { DailyRuntime.emit(this, true) }
        DailyRuntime.main.post { stopSelf() }
    }
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int)=Unit
    override fun onDestroy() {
        if (screenReceiverRegistered) { unregisterReceiver(screenReceiver); screenReceiverRegistered = false }
        DailyRuntime.worker.post {
            if(DailyRuntime.owner===this) runCatching { flushPending() }
            runCatching { subscription.stop() }; EnergyRuntime.usage.end("step",this)
            DailyRuntime.worker.removeCallbacks(persist); persistScheduled=false; pending=null
            if(DailyRuntime.owner===this) { DailyRuntime.running=false; DailyRuntime.owner=null; runCatching { DailyRuntime.emit(this, true) } }
        }
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }
}
