package com.duckolly.dvizh
import android.os.SystemClock
import java.util.UUID
object EnergyRuntime {
    val processToken: String=UUID.randomUUID().toString()
    val usage=UsageClock { SystemClock.elapsedRealtime() }
}
