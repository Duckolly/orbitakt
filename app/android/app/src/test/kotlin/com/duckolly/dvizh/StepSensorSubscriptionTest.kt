package com.duckolly.dvizh

import org.junit.Assert.*
import org.junit.Test

class StepSensorSubscriptionTest {
    private class Queue {
        var active = false
        var rejectedLatency: Int? = null
        var throwLatency: Int? = null
        var denyPermission = false
        var rejectAll = false
        val calls = mutableListOf<String>()
        fun register(latency: Int): Boolean {
            calls.add("register:$latency")
            if (denyPermission) throw SecurityException("revoked")
            if (throwLatency == latency) throw IllegalStateException("transient sensor failure")
            if (active || rejectAll || rejectedLatency == latency) return false
            active = true
            return true
        }
        fun unregister() { calls.add("unregister"); active = false }
        fun subscription() = StepSensorSubscription(::register, ::unregister)
    }

    @Test fun reproducesRejectedDuplicateButRetuneKeepsTheCounterRunning() {
        val q = Queue(); val subscription = q.subscription()
        assertTrue(subscription.start(0))
        // Old service called register again and treated this false as fatal.
        assertFalse(q.register(60_000_000))
        assertTrue(q.active)
        q.calls.clear()
        assertEquals(StepSensorSubscription.Change.UPDATED, subscription.change(60_000_000))
        assertEquals(listOf("unregister", "register:60000000"), q.calls)
        assertTrue(q.active)
    }
    @Test fun screenOffOnAndWorkoutTransitionsPreserveCumulativeSteps() {
        val q = Queue(); val subscription = q.subscription()
        assertTrue(subscription.start(0))
        var previous = 1000L; var steps = 0L
        for ((i, latency) in listOf(60_000_000, 0, 0, 60_000_000, 0).withIndex()) {
            subscription.change(latency)
            val raw = 1000L + (i + 1) * 13
            steps += CounterMath.change(previous, 1, "2026-11-02", raw, 1, "2026-11-02").delta
            previous = raw
            assertTrue(q.active)
        }
        assertEquals(65L, steps)
        assertEquals(0, subscription.latencyUs)
    }
    @Test fun sameModeAndRepeatedStartDoNotTouchAnActiveListener() {
        val q = Queue(); val s = q.subscription()
        s.start(0); q.calls.clear()
        assertTrue(s.start(0))
        assertEquals(StepSensorSubscription.Change.UNCHANGED, s.change(0))
        assertTrue(q.calls.isEmpty())
    }
    @Test fun rejectedNewModeRestoresPreviousWorkingMode() {
        val q = Queue(); val s = q.subscription(); s.start(0)
        q.rejectedLatency = 60_000_000
        assertEquals(StepSensorSubscription.Change.RESTORED, s.change(60_000_000))
        assertTrue(q.active); assertEquals(0, s.latencyUs)
    }
    @Test fun transientExceptionAlsoRestoresPreviousMode() {
        val q = Queue(); val s = q.subscription(); s.start(0)
        q.throwLatency = 60_000_000
        assertEquals(StepSensorSubscription.Change.RESTORED, s.change(60_000_000))
        assertTrue(q.active); assertEquals(0, s.latencyUs)
    }
    @Test fun bothRegistrationsFailWithoutClaimingActiveState() {
        val q = Queue(); val s = q.subscription(); s.start(0); q.rejectAll = true
        assertEquals(StepSensorSubscription.Change.FAILED, s.change(60_000_000))
        assertFalse(q.active); assertNull(s.latencyUs)
    }
    @Test fun revokedPermissionIsNotHiddenByFallback() {
        val q = Queue(); val s = q.subscription(); s.start(0); q.denyPermission = true
        try { s.change(60_000_000); fail("permission failure expected") }
        catch (_: SecurityException) { assertNull(s.latencyUs); assertFalse(q.active) }
    }
    @Test fun stopDoesNotLetLaterScreenEventsRestartTracking() {
        val q = Queue(); val s = q.subscription(); s.start(0); s.stop(); q.calls.clear()
        assertEquals(StepSensorSubscription.Change.NOT_RUNNING, s.change(60_000_000))
        s.stop(); assertTrue(q.calls.isEmpty()); assertFalse(q.active)
    }
    @Test fun initialFailureDoesNotClaimAWorkingSubscription() {
        val q = Queue(); q.rejectAll = true; val s = q.subscription()
        assertFalse(s.start(0)); assertNull(s.latencyUs); s.stop(); assertFalse(q.active)
    }
}
