package com.duckolly.dvizh
import kotlin.math.atan2
import kotlin.math.hypot
object SkyCompassMath {
    fun horizontal(x: Double,y: Double,z: Double): Boolean {
        if(!x.isFinite() || !y.isFinite() || !z.isFinite())return false
        val norm=kotlin.math.sqrt(x*x+y*y+z*z)
        return norm in 6.0..15.0 && kotlin.math.abs(z)/norm>=.7
    }
    fun normalize(degrees: Double): Double { require(degrees.isFinite()); return ((degrees % 360) + 360) % 360 }
    fun heading(east: Double, north: Double): Double? = if (!east.isFinite() || !north.isFinite() || hypot(east,north) < .15) null else normalize(Math.toDegrees(atan2(east,north)))
    fun smooth(previous: Double?, next: Double): Double {
        val target=normalize(next)
        if (previous==null) return target
        val from=normalize(previous)
        return normalize(from+.3*(normalize(target-from+180)-180))
    }
}
