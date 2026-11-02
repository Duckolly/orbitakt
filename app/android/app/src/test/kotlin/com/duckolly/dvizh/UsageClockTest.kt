package com.duckolly.dvizh
import org.junit.Assert.*
import org.junit.Test
class UsageClockTest {
    @Test fun repeatedLeaseAndSnapshotsDoNotResetClock() {
        var time=10L;val clock=UsageClock{time};val owner=Any()
        clock.begin("step",owner);time=20;clock.begin("step",owner)
        assertEquals(10L,clock.snapshot()["step"])
        assertEquals(10L,clock.snapshot()["step"])
        time=40;clock.end("step",owner);time=90
        assertEquals(30L,clock.snapshot()["step"]);assertTrue(clock.activeNames().isEmpty())
    }
    @Test fun replacementRejectsOldOwnerAndAllowsOverlappingModules() {
        var time=0L;val clock=UsageClock{time};val old=Any();val fresh=Any()
        clock.begin("step",old);clock.begin("pressure",old);time=20
        clock.begin("step",fresh);time=30;clock.end("step",old)
        assertEquals(listOf("pressure","step"),clock.activeNames())
        time=50;clock.end("step",fresh)
        assertEquals(50L,clock.snapshot()["step"]);assertEquals(50L,clock.snapshot()["pressure"])
    }
}
