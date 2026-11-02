package com.duckolly.dvizh

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.provider.Settings
import androidx.core.database.sqlite.transaction
import java.time.Instant
import java.time.ZoneId
import java.time.LocalDate

/** Accessed only by DailyRuntime's single worker; Flutter never writes daily totals. */
class DailyStore(context: Context) : SQLiteOpenHelper(context.applicationContext, "daily_steps.db", null, 1) {
    private val resolver = context.applicationContext.contentResolver
    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("CREATE TABLE days(day TEXT PRIMARY KEY, steps INTEGER NOT NULL, estimated INTEGER NOT NULL DEFAULT 0)")
        db.execSQL("CREATE TABLE state(id INTEGER PRIMARY KEY CHECK(id=1), enabled INTEGER NOT NULL, raw INTEGER NOT NULL, boot INTEGER NOT NULL, day TEXT NOT NULL, total INTEGER NOT NULL, gaps INTEGER NOT NULL, zone TEXT NOT NULL)")
        db.execSQL("INSERT INTO state VALUES(1,0,-1,-1,'',0,0,'')")
    }
    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) = Unit
    data class State(val enabled: Boolean, val raw: Long, val boot: Int, val day: String, val total: Long, val gaps: Int, val zone: String)
    fun state(): State = readableDatabase.rawQuery("SELECT enabled,raw,boot,day,total,gaps,zone FROM state WHERE id=1", null).use {
        check(it.moveToFirst()); State(it.getInt(0)!=0,it.getLong(1),it.getInt(2),it.getString(3),it.getLong(4),it.getInt(5),it.getString(6))
    }
    fun boot(): Int = Settings.Global.getInt(resolver, Settings.Global.BOOT_COUNT, -1)
    fun enable() { writableDatabase.execSQL("UPDATE state SET enabled=1,raw=-1 WHERE id=1") }
    fun disable() { writableDatabase.execSQL("UPDATE state SET enabled=0,raw=-1 WHERE id=1") }
    fun interrupted() { writableDatabase.execSQL("UPDATE state SET gaps=gaps+1 WHERE id=1 AND enabled=1 AND raw>=0") }
    fun sample(raw: Long, timestampMillis: Long) {
        val s = state(); if (!s.enabled || raw < 0) return
        val zone = ZoneId.systemDefault()
        val day = Instant.ofEpochMilli(timestampMillis).atZone(zone).toLocalDate().toString()
        val currentBoot = boot()
        val change = CounterMath.change(s.raw,s.boot,s.day,raw,currentBoot,day)
        val estimated = change.boundary || (s.zone.isNotEmpty() && s.zone!=zone.id)
        val db = writableDatabase
        db.transaction {
            if (change.delta > 0) {
                db.execSQL("INSERT OR IGNORE INTO days VALUES(?,0,0)", arrayOf(day))
                db.execSQL("UPDATE days SET steps=steps+?,estimated=MAX(estimated,?) WHERE day=?", arrayOf<Any>(change.delta,if(estimated)1 else 0,day))
            }
            val gap = if(s.raw>=0 && change.reset)1 else 0
            db.execSQL("UPDATE state SET raw=?,boot=?,day=?,total=?,gaps=gaps+?,zone=? WHERE id=1",arrayOf<Any>(raw,currentBoot,day,Math.addExact(s.total,change.delta),gap,zone.id))
        }
    }
    fun clear() {
        val db = writableDatabase
        db.transaction {
            db.delete("days",null,null)
            db.execSQL("UPDATE state SET enabled=0,raw=-1,boot=-1,day='',total=0,gaps=0,zone='' WHERE id=1")
        }
    }
    fun snapshot(): Map<String, Any> {
        val s = state()
        val history = readableDatabase.rawQuery("SELECT day,steps,estimated FROM days ORDER BY day DESC LIMIT 90",null).use { c ->
            buildList { while(c.moveToNext()) add(mapOf("day" to c.getString(0),"steps" to c.getLong(1),"estimated" to (c.getInt(2)!=0))) }
        }
        val today = LocalDate.now().toString()
        val todaySteps=readableDatabase.rawQuery("SELECT steps FROM days WHERE day=?",arrayOf(today)).use { if(it.moveToFirst())it.getLong(0) else 0L }
        return mapOf("enabled" to s.enabled,"totalRecorded" to s.total,"gaps" to s.gaps,"today" to today,"todaySteps" to todaySteps,"history" to history,"rebooted" to (s.raw>=0 && s.boot!=boot()))
    }
}
