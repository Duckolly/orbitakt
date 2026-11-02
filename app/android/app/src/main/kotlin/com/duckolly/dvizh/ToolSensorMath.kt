package com.duckolly.dvizh
object ToolSensorMath {
    /** Gravity projected to screen-right and screen-down, in m/s². Rotation values 0..3. */
    fun screenGravity(x: Double, y: Double, rotation: Int): Pair<Double, Double> = when (rotation) {
        1 -> y to x
        2 -> -x to y
        3 -> -y to -x
        else -> x to -y
    }
}
