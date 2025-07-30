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

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createQuietChannel()
    }

    private fun createQuietChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId   = "com.sycodes.xbeat3.audio"
            val channelName = "Audio Playback"

            // IMPORTANCE_LOW = no sound, no vibration, but icon stays in status bar
            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                // explicitly disable any sound or vibration
                setSound(null, null)
                enableVibration(false)
                // keep it visible on lock screen if you like
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                // optional: disable badge
                setShowBadge(false)
            }

            val manager = getSystemService(NotificationManager::class.java)!!
            // Delete the old one so your new settings actually apply
            manager.deleteNotificationChannel(channelId)
            manager.createNotificationChannel(channel)
        }
    }
}
