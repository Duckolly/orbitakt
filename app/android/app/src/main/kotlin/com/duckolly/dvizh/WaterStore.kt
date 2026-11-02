package com.duckolly.dvizh

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import androidx.core.database.sqlite.transaction
import java.time.LocalDate

/** All reads/writes are serialized on DailyRuntime.worker, including widget actions. */
class WaterStore(context: Context) : SQLiteOpenHelper(context.applicationContext, "water.db", null, 1) {
    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("CREATE TABLE water(day TEXT PRIMARY KEY, glasses INTEGER NOT NULL CHECK(glasses>=0))")
    }
    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) = Unit
    private fun count(day: String): Long = readableDatabase.rawQuery("SELECT glasses FROM water WHERE day=?", arrayOf(day)).use { if(it.moveToFirst()) it.getLong(0) else 0L }
    fun change(delta: Int) {
        val day=LocalDate.now().toString()
        writableDatabase.transaction {
            val next=WaterMath.adjust(count(day),delta)
            if(next==0L) delete("water","day=?",arrayOf(day))
            else execSQL("INSERT OR REPLACE INTO water VALUES(?,?)", arrayOf<Any>(day,next))
        }
    }
    fun clear() { writableDatabase.delete("water",null,null) }
    fun snapshot(): Map<String,Any> {
        val day=LocalDate.now().toString()
        val n=count(day)
        val history=readableDatabase.rawQuery("SELECT day,glasses FROM water ORDER BY day DESC LIMIT 90",null).use { c ->
            buildList { while(c.moveToNext()) add(mapOf("day" to c.getString(0),"glasses" to c.getLong(1),"millilitres" to WaterMath.millilitres(c.getLong(1)))) }
        }
        return mapOf("today" to day,"glasses" to n,"millilitres" to WaterMath.millilitres(n),"history" to history)
    }
}
