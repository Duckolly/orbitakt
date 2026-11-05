package com.duckolly.dvizh

/** Uncertainty metadata only: never subtract, reject, or rewrite sensor steps.
 * Proximity does not detect calls; a pocket or cover can also activate it.
 * Delayed cumulative batches cannot be attributed to current proximity.
 */
object StepSampleQuality {
    fun isFresh(ageMillis: Long): Boolean = ageMillis in 0L..2_000L
    fun proximityUncertain(near: Boolean, delta: Long): Boolean = near && delta > 20L
}
