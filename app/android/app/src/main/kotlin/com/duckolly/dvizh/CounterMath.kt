package com.duckolly.dvizh

/** Pure counter transition. Only the native daily store may add these deltas. */
object CounterMath {
    fun accepts(timestampNanos: Long, enabledAfterNanos: Long): Boolean = timestampNanos >= enabledAfterNanos
    data class Change(val delta: Long, val reset: Boolean, val boundary: Boolean)
    fun change(previous: Long, boot: Int, day: String, current: Long, currentBoot: Int, currentDay: String): Change {
        if (current < 0) return Change(0, true, false)
        if (previous < 0 || boot != currentBoot || current < previous) return Change(0, true, false)
        val delta = current - previous
        return Change(delta, false, delta > 0 && day != currentDay)
    }
}
