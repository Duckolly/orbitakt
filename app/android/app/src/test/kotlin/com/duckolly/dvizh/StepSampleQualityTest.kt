package com.duckolly.dvizh

import org.junit.Assert.*
import org.junit.Test

class StepSampleQualityTest {
    @Test fun delayedBatchesDoNotUsePresentProximity() {
        assertTrue(StepSampleQuality.isFresh(0))
        assertTrue(StepSampleQuality.isFresh(2000))
        assertFalse(StepSampleQuality.isFresh(2001))
        assertFalse(StepSampleQuality.isFresh(-1))
        assertFalse(StepSampleQuality.isFresh(Long.MAX_VALUE))
    }
    @Test fun proximityOnlyMarksLargeBatchesAsUncertain() {
        assertFalse(StepSampleQuality.proximityUncertain(false, 10000))
        assertFalse(StepSampleQuality.proximityUncertain(true, 0))
        assertFalse(StepSampleQuality.proximityUncertain(true, 20))
        assertTrue(StepSampleQuality.proximityUncertain(true, 21))
        assertTrue(StepSampleQuality.proximityUncertain(true, Long.MAX_VALUE))
    }
}
