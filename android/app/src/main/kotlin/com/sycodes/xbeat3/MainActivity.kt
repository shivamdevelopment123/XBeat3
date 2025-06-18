package com.sycodes.xbeat3

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.plugins.flutter_plugin_android_lifecycle.FlutterAndroidLifecyclePlugin
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity()
{
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Create a high-importance notification channel for media playback
        createHighImportanceChannel()
    }

    private fun createHighImportanceChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "com.sycodes.xbeat3.audio",   // Channel ID
                "Audio Playback",             // Channel Name
                NotificationManager.IMPORTANCE_HIGH
            )

            channel.lockscreenVisibility = Notification.VISIBILITY_PUBLIC // ✅ FIXED

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}
