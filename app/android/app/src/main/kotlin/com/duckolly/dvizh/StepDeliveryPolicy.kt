package com.duckolly.dvizh

/** Sensor batching policy; affects delivery latency, never the step recognition algorithm. */
object StepDeliveryPolicy {
    fun maxLatencyUs(uiOrWorkout: Boolean, deviceInteractive: Boolean): Int =
        if (uiOrWorkout || deviceInteractive) 0 else 60_000_000
}
