package com.duckolly.dvizh
import org.junit.Assert.*
import org.junit.Test
class SkyCompassMathTest {
    @Test fun horizontalChartAcceptsBothViewingSidesAndRejectsVertical(){
        assertTrue(SkyCompassMath.horizontal(0.0,0.0,9.8))
        assertTrue(SkyCompassMath.horizontal(0.0,0.0,-9.8))
        assertFalse(SkyCompassMath.horizontal(0.0,9.8,0.0))
        assertFalse(SkyCompassMath.horizontal(0.0,0.0,30.0))
        assertFalse(SkyCompassMath.horizontal(Double.NaN,0.0,9.8))
    }
    @Test fun cardinalHeadingAndVerticalRejection(){
        assertEquals(0.0,SkyCompassMath.heading(0.0,1.0)!!,.0001)
        assertEquals(90.0,SkyCompassMath.heading(1.0,0.0)!!,.0001)
        assertEquals(180.0,SkyCompassMath.heading(0.0,-1.0)!!,.0001)
        assertEquals(270.0,SkyCompassMath.heading(-1.0,0.0)!!,.0001)
        assertNull(SkyCompassMath.heading(0.0,0.0))
        assertNull(SkyCompassMath.heading(Double.NaN,1.0))
    }
    @Test fun smoothAcrossNorthBothWays(){
        assertEquals(359.6,SkyCompassMath.smooth(359.0,1.0),.0001)
        assertEquals(.4,SkyCompassMath.smooth(1.0,359.0),.0001)
    }
    @Test fun trueNorthCorrectionWraps(){
        assertEquals(5.0,SkyCompassMath.smooth(null,355.0+10.0),.0001)
        assertEquals(350.0,SkyCompassMath.normalize(-10.0),.0001)
    }
}
