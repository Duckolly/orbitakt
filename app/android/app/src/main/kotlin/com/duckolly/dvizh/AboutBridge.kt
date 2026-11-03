package com.duckolly.dvizh

import android.content.Intent
import androidx.core.net.toUri
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Public contact opened by an explicit tap only; no network permission or embedded browser. */
class AboutBridge(private val activity: MainActivity, engine: FlutterEngine) {
    private val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "dvizh/about")
    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "info" -> {
                    try {
                        @Suppress("DEPRECATION")
                        val info = activity.packageManager.getPackageInfo(activity.packageName, 0)
                        @Suppress("DEPRECATION")
                        val code = if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()
                        result.success(mapOf("version" to info.versionName, "build" to code))
                    } catch (_: RuntimeException) {
                        result.error("info_unavailable", "Версия недоступна", null)
                    } catch (_: android.content.pm.PackageManager.NameNotFoundException) {
                        result.error("info_unavailable", "Версия недоступна", null)
                    }
                }
                "openTelegram", "openWebsite" -> {
                    val url = if (call.method == "openWebsite")
                        "https://duckolly.github.io/testofsilence/" else "https://t.me/dvizhoffline"
                    val opened = try {
                        activity.startActivity(Intent(Intent.ACTION_VIEW, url.toUri()))
                        true
                    } catch (_: RuntimeException) { false }
                    result.success(opened)
                }
                else -> result.notImplemented()
            }
        }
    }
    fun close() { channel.setMethodCallHandler(null) }
}
