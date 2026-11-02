package com.duckolly.dvizh
/** Durations of this app's leases, never energy estimates. Owners protect overlapping lifecycles. */
class UsageClock(private val now: () -> Long) {
    private data class Lease(val owner: Any, val since: Long)
    private val totals=mutableMapOf<String,Long>()
    private val active=mutableMapOf<String,Lease>()
    @Synchronized fun begin(name: String,owner: Any) {
        if(active[name]?.owner===owner)return
        val time=now();active.remove(name)?.let { totals[name]=(totals[name]?:0)+maxOf(0,time-it.since) }
        active[name]=Lease(owner,time)
    }
    @Synchronized fun end(name: String,owner: Any) {
        val lease=active[name]?:return
        if(lease.owner!==owner)return
        totals[name]=(totals[name]?:0)+maxOf(0,now()-lease.since);active.remove(name)
    }
    @Synchronized fun snapshot(): Map<String,Long> {
        val time=now();val result=totals.toMutableMap()
        active.forEach { (name,lease)->result[name]=(result[name]?:0)+maxOf(0,time-lease.since) }
        return result
    }
    @Synchronized fun activeNames(): List<String> = active.keys.sorted()
}
