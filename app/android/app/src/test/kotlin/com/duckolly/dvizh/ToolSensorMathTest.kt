package com.duckolly.dvizh
import org.junit.Assert.assertEquals
import org.junit.Test
class ToolSensorMathTest {
    @Test fun screenGravityAllDisplayRotations() {
        assertEquals(2.0 to -3.0, ToolSensorMath.screenGravity(2.0, 3.0, 0))
        assertEquals(3.0 to 2.0, ToolSensorMath.screenGravity(2.0, 3.0, 1))
        assertEquals(-2.0 to 3.0, ToolSensorMath.screenGravity(2.0, 3.0, 2))
        assertEquals(-3.0 to -2.0, ToolSensorMath.screenGravity(2.0, 3.0, 3))
    }
}
