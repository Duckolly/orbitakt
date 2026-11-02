package com.duckolly.dvizh

/** Worker-thread-only subscription. Never register an already active listener.
 * Retuning does not touch the step store or its cumulative baseline.
 */
class StepSensorSubscription(
    private val register: (Int) -> Boolean,
    private val unregister: () -> Unit
) {
    enum class Change { UNCHANGED, UPDATED, RESTORED, NOT_RUNNING, FAILED }
    var latencyUs: Int? = null
        private set

    fun start(requestedLatencyUs: Int): Boolean {
        if (latencyUs != null) return true
        return connect(requestedLatencyUs)
    }

    fun change(requestedLatencyUs: Int): Change {
        val previous = latencyUs ?: return Change.NOT_RUNNING
        if (previous == requestedLatencyUs) return Change.UNCHANGED
        // Android's sensor queue can return false for duplicate registration.
        // Unsubscribe first, retain the persisted counter baseline in the caller.
        unregister()
        latencyUs = null
        if (attempt(requestedLatencyUs)) return Change.UPDATED
        // An optional latency adjustment must not disable the user's step mode
        // when the previous delivery mode can still be restored.
        if (attempt(previous)) return Change.RESTORED
        return Change.FAILED
    }

    private fun attempt(latency: Int): Boolean = try {
        connect(latency)
    } catch (error: SecurityException) {
        throw error // Revoked permission must not be hidden by a retry.
    } catch (_: RuntimeException) {
        false
    }

    private fun connect(latency: Int): Boolean {
        if (!register(latency)) return false
        latencyUs = latency
        return true
    }

    fun stop() {
        if (latencyUs == null) return
        try { unregister() } finally { latencyUs = null }
    }
}
