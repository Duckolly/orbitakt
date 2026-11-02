package com.duckolly.dvizh

import org.junit.Assert.*
import org.junit.Test

class WidgetUpdateQueueTest {
    private class Clock {
        var time=0L
        var value=0
        val published=mutableListOf<Int>()
        val pending=mutableMapOf<Runnable,Long>()
        var fail=false
        var errors=0
        val queue=WidgetUpdateQueue(
            now={time}, schedule={task,delay->pending[task]=time+delay},
            cancel={task->pending.remove(task);Unit},
            publish={if(fail) throw IllegalStateException("host unavailable");published.add(value);Unit},
            onError={errors++}
        )
        fun advance(to: Long) {
            time=to
            val due=pending.filterValues{it<=time}.keys.toList()
            due.forEach { pending.remove(it);it.run() }
        }
    }
    @Test fun firstPublicationIsImmediateAndIdleDoesNotPoll() {
        val c=Clock();c.queue.request(false,5000)
        assertEquals(listOf(0),c.published);assertTrue(c.pending.isEmpty())
        c.advance(100000);assertEquals(1,c.published.size)
    }
    @Test fun finalShortWalkUpdateIsNotLostOrPostponedByBurst() {
        val c=Clock();c.queue.request(false,5000)
        c.time=100;c.value=1;c.queue.request(false,5000)
        c.time=4900;c.value=42;c.queue.request(false,5000)
        assertEquals(listOf(5000L),c.pending.values.toList())
        c.advance(4999);assertEquals(listOf(0),c.published)
        c.advance(5000);assertEquals(listOf(0,42),c.published)
        assertTrue(c.pending.isEmpty()) // No more sensor events are needed.
    }
    @Test fun forcedWaterOrResetPublicationCancelsStaleTrailingWork() {
        val c=Clock();c.queue.request(false,5000)
        c.time=100;c.value=9;c.queue.request(false,5000)
        c.time=200;c.value=0;c.queue.request(true,5000)
        c.advance(5000)
        assertEquals(listOf(0,0),c.published);assertTrue(c.pending.isEmpty())
    }
    @Test fun removingWidgetsClearsPendingAndNextWidgetPublishesImmediately() {
        val c=Clock();c.queue.request(false,5000)
        c.time=100;c.value=2;c.queue.request(false,5000);c.queue.clear()
        c.advance(9000);assertEquals(listOf(0),c.published)
        c.queue.request(false,5000);assertEquals(listOf(0,2),c.published)
    }
    @Test fun publicationFailureDoesNotConsumeIntervalOrCreateRetryLoop() {
        val c=Clock();c.fail=true;c.queue.request(false,5000)
        assertEquals(1,c.errors);assertTrue(c.pending.isEmpty())
        c.fail=false;c.time=1;c.value=7;c.queue.request(false,5000)
        assertEquals(listOf(7),c.published)
    }
    @Test fun interactiveModeCanBringPendingPublicationForward() {
        val c=Clock();c.queue.request(false,60000)
        c.time=100;c.value=1;c.queue.request(false,60000)
        assertEquals(listOf(60000L),c.pending.values.toList())
        c.time=200;c.value=3;c.queue.request(false,5000)
        assertEquals(listOf(5000L),c.pending.values.toList())
        c.advance(5000);assertEquals(listOf(0,3),c.published)
    }
    @Test fun backwardsClockDoesNotSuppressUpdatesIndefinitely() {
        val c=Clock();c.time=100;c.queue.request(false,5000)
        c.time=50;c.value=1;c.queue.request(false,5000)
        assertEquals(listOf(0,1),c.published)
    }
    @Test fun launcherInteractiveDoesNotBatchEvenWithoutFlutterUi() {
        assertEquals(0,StepDeliveryPolicy.maxLatencyUs(false,true))
        assertEquals(0,StepDeliveryPolicy.maxLatencyUs(true,false))
        assertEquals(0,StepDeliveryPolicy.maxLatencyUs(true,true))
    }
    @Test fun screenOffAndNoWorkoutRetainsEnergySavingBatch() {
        assertEquals(60_000_000,StepDeliveryPolicy.maxLatencyUs(false,false))
    }
}
