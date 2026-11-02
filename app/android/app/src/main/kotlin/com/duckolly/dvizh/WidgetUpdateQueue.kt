package com.duckolly.dvizh

/** Worker-confined leading + trailing coalescing. No polling, wake-up alarm or lost final event. */
class WidgetUpdateQueue(
    private val now: () -> Long,
    private val schedule: (Runnable, Long) -> Unit,
    private val cancel: (Runnable) -> Unit,
    private val publish: () -> Unit,
    private val onError: (RuntimeException) -> Unit = {}
) {
    private var lastPublished: Long? = null
    private var due: Long? = null
    private var dirty = false
    private val trailing = Runnable { due = null; if (dirty) publishNow() }
    fun request(force: Boolean, minIntervalMs: Long) {
        require(minIntervalMs > 0)
        dirty = true
        val time = now()
        val last = lastPublished
        if (force || last == null || time < last || time - last >= minIntervalMs) {
            publishNow()
            return
        }
        val target = last + minIntervalMs
        val old = due
        // Never move a pending publication later when new events keep arriving.
        if (old == null || target < old) {
            cancel(trailing)
            due = target
            schedule(trailing, (target - time).coerceAtLeast(1))
        }
    }
    fun clear() {
        cancel(trailing); due = null; dirty = false; lastPublished = null
    }
    private fun publishNow() {
        cancel(trailing); due = null; dirty = false
        try {
            publish()
            lastPublished = now() // Only a successful publication consumes the interval.
        } catch (error: RuntimeException) {
            onError(error) // A later data event can retry; do not create an endless retry timer.
        }
    }
}
