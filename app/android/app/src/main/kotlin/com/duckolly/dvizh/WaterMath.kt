package com.duckolly.dvizh

object WaterMath {
    const val GLASS_ML = 200L
    fun adjust(glasses: Long, delta: Int): Long {
        require(glasses >= 0 && (delta == 1 || delta == -1))
        val next = Math.addExact(glasses, delta.toLong()).coerceAtLeast(0)
        Math.multiplyExact(next, GLASS_ML)
        return next
    }
    fun millilitres(glasses: Long): Long = Math.multiplyExact(glasses, GLASS_ML)
}
