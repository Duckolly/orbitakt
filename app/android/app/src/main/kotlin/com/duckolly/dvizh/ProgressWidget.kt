package com.duckolly.dvizh

import android.app.PendingIntent
import android.app.Application
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.os.PowerManager
import android.widget.RemoteViews
import java.text.NumberFormat
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.Locale

/** Compact read-only home widget. No Flutter engine, bitmaps, timers or sensor subscriptions. */
class ProgressWidget : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action !in setOf(AppWidgetManager.ACTION_APPWIDGET_UPDATE,
                AppWidgetManager.ACTION_APPWIDGET_OPTIONS_CHANGED, Intent.ACTION_MY_PACKAGE_REPLACED)) {
            // Old water-action PendingIntents are deliberately not processed after this upgrade.
            super.onReceive(context, intent)
            return
        }
        val pending = goAsync()
        DailyRuntime.worker.post {
            try { refresh(context, true) }
            catch (_: RuntimeException) { runCatching { showError(context) } }
            finally { pending.finish() }
        }
    }

    companion object {
        private var widgetContext: Application? = null // application context, worker thread only
        private val updates = WidgetUpdateQueue(
            now = { SystemClock.elapsedRealtime() },
            schedule = { task, delay -> DailyRuntime.worker.postDelayed(task, delay); Unit },
            cancel = { task -> DailyRuntime.worker.removeCallbacks(task) },
            publish = { widgetContext?.let { publish(it) } },
            onError = { widgetContext?.let { context -> runCatching { showError(context) } }; Unit }
        )
        private fun ids(context: Context) = AppWidgetManager.getInstance(context)
            .getAppWidgetIds(ComponentName(context, ProgressWidget::class.java))

        private fun views(context: Context): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.progress_widget)
            val open = PendingIntent.getActivity(context, 300, Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_root, open)
            return views
        }

        fun refresh(context: Context, force: Boolean) {
            widgetContext = context.applicationContext as? Application ?: return
            if (ids(context).isEmpty()) { updates.clear(); return }
            val interactive = runCatching { context.getSystemService(PowerManager::class.java).isInteractive }.getOrDefault(true)
            updates.request(force, if (interactive) 5_000L else 60_000L)
        }

        private fun publish(context: Context) {
            val targets = ids(context)
            if (targets.isEmpty()) return
            val daily = DailyRuntime.snapshot(context)
            val water = DailyRuntime.water(context).snapshot()
            val steps = daily["todaySteps"] as Long
            val glasses = water["glasses"] as Long
            val count = NumberFormat.getIntegerInstance(Locale.forLanguageTag("ru-RU"))
            val views = views(context)
            views.setTextViewText(R.id.widget_steps, count.format(steps))
            views.setTextViewText(R.id.widget_water, "${count.format(glasses)} ст.")
            // Timestamp remains available to TalkBack without cluttering the visual layout.
            val time = LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd.MM.yyyy HH:mm"))
            views.setContentDescription(R.id.widget_root,
                "Шаги за ${daily["today"]}: $steps. Вода: $glasses стаканов, ${water["millilitres"]} мл. " +
                    "Данные на $time. Нажмите, чтобы открыть Орбитакт.")
            AppWidgetManager.getInstance(context).updateAppWidget(targets, views)
        }

        private fun showError(context: Context) {
            val views = views(context)
            views.setTextViewText(R.id.widget_steps, "—")
            views.setTextViewText(R.id.widget_water, "—")
            views.setContentDescription(R.id.widget_root, "Не удалось обновить итоги. Нажмите, чтобы открыть Орбитакт.")
            AppWidgetManager.getInstance(context).updateAppWidget(ids(context), views)
        }
    }
}
