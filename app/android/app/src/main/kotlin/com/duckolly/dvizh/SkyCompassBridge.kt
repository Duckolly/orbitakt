package com.duckolly.dvizh
import android.hardware.GeomagneticField
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

/** Approximate true-north heading for a horizontal sky chart; no location API or service. */
class SkyCompassBridge(private val activity: MainActivity, engine: FlutterEngine): SensorEventListener {
    private val manager=activity.getSystemService(SensorManager::class.java)
    private val acceleration=manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private val magnetic=manager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
    private val handler=Handler(Looper.getMainLooper())
    private val methods=MethodChannel(engine.dartExecutor.binaryMessenger,"dvizh/sky")
    private val events=EventChannel(engine.dartExecutor.binaryMessenger,"dvizh/sky/events")
    private var sink: EventChannel.EventSink?=null
    private var visible=false
    private var registered=false
    private var closed=false
    private var after=Long.MAX_VALUE
    private var accAt=0L
    private var magAt=0L
    private var lastSent=0L
    private var accuracy=SensorManager.SENSOR_STATUS_UNRELIABLE
    private var declination=0.0
    private var filtered: Double?=null
    private var lastRotation=-1
    private val gravity=FloatArray(3)
    private val field=FloatArray(3)
    private val matrix=FloatArray(9)
    private val screen=FloatArray(9)
    init {
        methods.setMethodCallHandler { call,result ->
            if(call.method=="status")result.success(mapOf("supported" to (magnetic!=null && acceleration!=null)))
            else result.notImplemented()
        }
        events.setStreamHandler(object: EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, target: EventChannel.EventSink) {
                stop();sink=target
                val args=arguments as? Map<*,*>
                val lat=(args?.get("latitude") as? Number)?.toDouble()
                val lon=(args?.get("longitude") as? Number)?.toDouble()
                val time=(args?.get("timeMillis") as? Number)?.toLong()
                if(lat==null || lon==null || time==null || !lat.isFinite() || !lon.isFinite() || lat !in -90.0..90.0 || lon !in -180.0..180.0 || time !in 1577836800000L..1924991999999L) { emit("error");return }
                declination=GeomagneticField(lat.toFloat(),lon.toFloat(),0f,time).declination.toDouble()
                if(!declination.isFinite()){emit("error");return}
                start()
            }
            override fun onCancel(arguments: Any?) { stop();sink=null }
        })
    }
    fun setVisible(value: Boolean) { visible=value;if(!value){stop();emit("paused")} }
    fun close(){closed=true;stop();sink=null;events.setStreamHandler(null);methods.setMethodCallHandler(null)}
    private fun start(){
        if(closed || sink==null)return
        if(!visible){emit("paused");return}
        if(magnetic==null || acceleration==null){emit("unavailable");return}
        after=SystemClock.elapsedRealtimeNanos();accAt=0;magAt=0;lastSent=0;filtered=null;lastRotation=-1
        accuracy=SensorManager.SENSOR_STATUS_UNRELIABLE
        try{
            val a=manager.registerListener(this,acceleration,200_000,handler)
            val m=manager.registerListener(this,magnetic,200_000,handler)
            registered=a && m
            if(!registered){stop();emit("error")}else { EnergyRuntime.usage.begin("compass",this); emit("waiting") }
        }catch(_:RuntimeException){stop();emit("error")}
    }
    private fun stop(){EnergyRuntime.usage.end("compass",this);manager.unregisterListener(this);registered=false;after=Long.MAX_VALUE;accAt=0;magAt=0;filtered=null}
    override fun onSensorChanged(event: SensorEvent){
        if(!registered || !visible || closed || sink==null || event.timestamp<after)return
        if(event.values.size<3 || (0..2).any{!event.values[it].isFinite()})return
        val now=SystemClock.elapsedRealtimeNanos()
        if(event.timestamp>now+100_000_000L || now-event.timestamp>1_500_000_000L)return
        when(event.sensor.type){
            Sensor.TYPE_ACCELEROMETER->{if(event.timestamp<accAt)return
                for(i in 0..2)gravity[i]=if(accAt==0L)event.values[i] else gravity[i]+.25f*(event.values[i]-gravity[i])
                accAt=event.timestamp}
            Sensor.TYPE_MAGNETIC_FIELD->{if(event.timestamp<magAt)return
                for(i in 0..2)field[i]=event.values[i]
                magAt=event.timestamp;accuracy=event.accuracy}
            else->return
        }
        val ms=SystemClock.elapsedRealtime();if(ms-lastSent<200)return;lastSent=ms
        if(accAt==0L || magAt==0L || now-accAt>1_500_000_000L || now-magAt>1_500_000_000L){filtered=null;emit("waiting");return}
        if(accuracy==SensorManager.SENSOR_STATUS_UNRELIABLE){filtered=null;emit("calibration");return}
        if(!SkyCompassMath.horizontal(gravity[0].toDouble(),gravity[1].toDouble(),gravity[2].toDouble())){filtered=null;emit("tilted");return}
        if(!SensorManager.getRotationMatrix(matrix,null,gravity,field)){filtered=null;emit("waiting");return}
        @Suppress("DEPRECATION")
        val rotation=if(Build.VERSION.SDK_INT>=30)activity.display?.rotation?:Surface.ROTATION_0 else activity.windowManager.defaultDisplay.rotation
        val axes=when(rotation){
            Surface.ROTATION_90->SensorManager.AXIS_Y to SensorManager.AXIS_MINUS_X
            Surface.ROTATION_180->SensorManager.AXIS_MINUS_X to SensorManager.AXIS_MINUS_Y
            Surface.ROTATION_270->SensorManager.AXIS_MINUS_Y to SensorManager.AXIS_X
            else->SensorManager.AXIS_X to SensorManager.AXIS_Y
        }
        if(rotation!=lastRotation){filtered=null;lastRotation=rotation}
        if(!SensorManager.remapCoordinateSystem(matrix,axes.first,axes.second,screen)){emit("waiting");return}
        val raw=SkyCompassMath.heading(screen[1].toDouble(),screen[4].toDouble())
        if(raw==null){filtered=null;emit("tilted");return}
        filtered=SkyCompassMath.smooth(filtered,raw+declination);emit("reading",filtered)
    }
    override fun onAccuracyChanged(sensor: Sensor,value: Int){
        if(sensor.type==Sensor.TYPE_MAGNETIC_FIELD){accuracy=value;if(registered && value==SensorManager.SENSOR_STATUS_UNRELIABLE){filtered=null;emit("calibration")}}
    }
    private fun emit(state: String,heading: Double?=null){
        runCatching{sink?.success(mapOf("state" to state,"heading" to heading,"accuracy" to accuracy))}
            .onFailure{stop();sink=null}
    }
}
