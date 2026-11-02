package com.duckolly.dvizh
import org.junit.Assert.assertEquals
import org.junit.Test
class WaterMathTest {
 @Test fun glassIs200ml() { assertEquals(600L,WaterMath.millilitres(WaterMath.adjust(2,1))) }
 @Test fun undoNeverNegative() { assertEquals(0L,WaterMath.adjust(0,-1)); assertEquals(0L,WaterMath.adjust(1,-1)) }
 @Test(expected=IllegalArgumentException::class) fun invalidDeltaRejected() { WaterMath.adjust(0,2) }
 @Test(expected=ArithmeticException::class) fun overflowingVolumeRejected() { WaterMath.adjust(Long.MAX_VALUE/200,1) }
}
