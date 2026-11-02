package com.duckolly.dvizh

import android.app.*
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.*
import android.os.*

class DailyStepService : Service(), SensorEventListener {
    private lateinit var sensors: SensorManager
    private var pending: Pair<Long,Long>? = null
    private var persistScheduled = false
    private var baselineReady = false
    private var lastEventNanos = 0L
    private val persist = Runnable { runCatching { flushPending() }.onFailure { fail() } }
    override fun onCreate() { super.onCreate(); sensors=getSystemService(SensorManager::class.java) }
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if(intent?.action=="STOP") {
            DailyRuntime.worker.post {
                DailyRuntime.stopNow()
                runCatching { DailyRuntime.store(this).disable() }
                if(DailyRuntime.owner===this) { sensors.unregisterListener(this); EnergyRuntime.usage.end("step",this); DailyRuntime.running=false }
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
            .setContentTitle("ДВИЖ · дневной шагомер включён").setContentText("Шаги сохраняются только на телефоне")
            .setVisibility(Notification.VISIBILITY_PRIVATE).setContentIntent(open).setOngoing(true)
            .addAction(Notification.Action.Builder(null,"Остановить",stop).build()).build()
        try {
            if(Build.VERSION.SDK_INT>=34) startForeground(2001,notification,ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH)
            else startForeground(2001,notification)
        } catch(_:RuntimeException) {
            DailyRuntime.worker.post { DailyRuntime.stopNow(); DailyRuntime.issue="permission"; runCatching { DailyRuntime.store(this).disable(); DailyRuntime.emit(this, true) } }
            stopSelf(); return START_NOT_STICKY
        }
        DailyRuntime.worker.post {
            try {
                if(DailyRuntime.suppressed || !DailyRuntime.store(this).state().enabled) { DailyRuntime.main.post { stopSelf() }; return@post }
                if(DailyRuntime.owner===this && DailyRuntime.running) return@post
                DailyRuntime.store(this).interrupted()
                DailyRuntime.owner=this
                baselineReady=DailyRuntime.store(this).state().raw>=0
                val sensor=sensors.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
                val ok=sensor!=null && sensors.registerListener(this,sensor,SensorManager.SENSOR_DELAY_NORMAL,if(DailyRuntime.uiVisible || DailyRuntime.interactive)0 else 60_000_000,DailyRuntime.worker)
                DailyRuntime.running=ok; if(ok) EnergyRuntime.usage.begin("step",this) else EnergyRuntime.usage.end("step",this); DailyRuntime.issue=if(ok)"" else "registration_failed"
                if(!ok) { DailyRuntime.store(this).disable(); DailyRuntime.main.post { stopSelf() } }
                DailyRuntime.emit(this, true)
            } catch(_:RuntimeException) { fail() }
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
        } catch(_:RuntimeException) { fail() }
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
    fun haltSensor() { sensors.unregisterListener(this); EnergyRuntime.usage.end("step",this); DailyRuntime.worker.removeCallbacks(persist); persistScheduled=false; pending=null }
    fun setInteractive(interactive: Boolean) {
        if(DailyRuntime.owner!==this || !DailyRuntime.running) return
        val sensor=sensors.getDefaultSensor(Sensor.TYPE_STEP_COUNTER) ?: return
        runCatching { sensors.registerListener(this,sensor,SensorManager.SENSOR_DELAY_NORMAL,if(interactive)0 else 60_000_000,DailyRuntime.worker) }.onFailure { fail() }
    }
    private fun fail() {
        haltSensor(); DailyRuntime.suppressed=true; DailyRuntime.running=false; DailyRuntime.issue="storage_error"
        runCatching { DailyRuntime.store(this).disable(); DailyRuntime.emit(this, true) }
        DailyRuntime.main.post { stopSelf() }
    }
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int)=Unit
    override fun onDestroy() {
        DailyRuntime.worker.post {
            sensors.unregisterListener(this); EnergyRuntime.usage.end("step",this)
            if(DailyRuntime.owner===this) runCatching { flushPending() }
            DailyRuntime.worker.removeCallbacks(persist); persistScheduled=false; pending=null
            if(DailyRuntime.owner===this) { DailyRuntime.running=false; DailyRuntime.owner=null; runCatching { DailyRuntime.emit(this, true) } }
        }
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }
}
