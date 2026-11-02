package com.duckolly.dvizh

import org.junit.Assert.*
import org.junit.Test

class CounterMathTest {
    @Test fun staleBatchBeforeEnableIsRejected() { assertFalse(CounterMath.accepts(99,100)) }
    @Test fun firstFreshEventCanEstablishBaseline() { assertTrue(CounterMath.accepts(100,100)) }
    @Test fun explicitStopRejectsQueuedEvents() { assertFalse(CounterMath.accepts(1_000_000,Long.MAX_VALUE)) }
    @Test fun firstReadingDoesNotImportEarlierSteps() { assertEquals(0L,CounterMath.change(-1,1,"",5000,1,"2026-10-31").delta) }
    @Test fun repeatDoesNotDoubleCount() { assertEquals(0L,CounterMath.change(5000,1,"2026-10-31",5000,1,"2026-10-31").delta) }
    @Test fun ordinaryDelta() { assertEquals(8L,CounterMath.change(5000,1,"2026-10-31",5008,1,"2026-10-31").delta) }
    @Test fun rebootEvenWithHigherCounterResetsBaseline() { val c=CounterMath.change(50,1,"2026-10-31",100,2,"2026-10-31"); assertTrue(c.reset); assertEquals(0L,c.delta) }
    @Test fun sensorResetDoesNotSubtract() { assertEquals(0L,CounterMath.change(5000,1,"2026-10-31",2,1,"2026-10-31").delta) }
    @Test fun midnightIsFlaggedInsteadOfInventedSplit() { val c=CounterMath.change(100,1,"2026-10-30",110,1,"2026-10-31"); assertEquals(10L,c.delta); assertTrue(c.boundary) }
    @Test fun noStepsAcrossMidnightIsNotApproximate() { assertFalse(CounterMath.change(100,1,"2026-10-30",100,1,"2026-10-31").boundary) }
    @Test fun negativeReadingCannotAddSteps() { assertEquals(0L,CounterMath.change(100,1,"2026-10-31",-1,1,"2026-10-31").delta) }
    @Test fun countersLargerThanIntDoNotWrap() { assertEquals(4_000_000_000L,CounterMath.change(0,1,"2026-10-31",4_000_000_000L,1,"2026-10-31").delta) }
}
