package com.sycodes.xbeat3
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.audiofx.Equalizer
import android.os.Build
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private var equalizer: Equalizer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createQuietChannel()

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.sycodes.xbeat3/equalizer"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setEQ" -> {
                    val sessionId = (call.argument<Int>("sessionId") ?: 0)
                    val gains     = call.argument<Map<String, Double>>("gains")  ?: emptyMap()
                    val qs        = call.argument<Map<String, Double>>("qs")     ?: emptyMap()
                    initAndApplyEQ(sessionId, gains, qs)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

    }

    private fun initAndApplyEQ(
        sessionId: Int,
        gains: Map<String, Double>,
        qs:    Map<String, Double>
    ) {
        if (equalizer == null) {
            equalizer = Equalizer(0, sessionId).apply { enabled = true }
        }
        val eq = equalizer!!

        // Apply gains exactly as before
        val bandCount = eq.numberOfBands.toInt()
        for (i in 0 until bandCount) {
            val bandIndex   = i.toShort()
            val centerHzKey = (eq.getCenterFreq(bandIndex)/1000).toInt().toString()
            gains[centerHzKey]?.let { gainDb ->
                val levelMb = (gainDb * 100).toInt().toShort()
                eq.setBandLevel(bandIndex, levelMb)
            }
        }
    }

    private fun createQuietChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "com.sycodes.xbeat3.audio"
            val channelName = "Audio Playback"
            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                setSound(null, null)
                enableVibration(false)
                // Use Notification.VISIBILITY_PUBLIC, not NotificationManager
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setShowBadge(false)
            }

            val manager = getSystemService(NotificationManager::class.java)!!
            manager.deleteNotificationChannel(channelId)
            manager.createNotificationChannel(channel)
        }
    }
}