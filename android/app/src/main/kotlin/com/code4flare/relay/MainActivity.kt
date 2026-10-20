package com.code4flare.relay

import android.content.Intent
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        const val SCREEN_SHARE_CHANNEL = "com.code4flare.relay/screen_share"
        var screenShareChannel: MethodChannel? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_SHARE_CHANNEL)
        screenShareChannel = channel
        ScreenShareService.onChannelReady(channel)

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val peer = call.argument<String>("peer")
                    val intent = Intent(this, ScreenShareService::class.java).apply {
                        action = ScreenShareService.ACTION_START
                        putExtra(ScreenShareService.EXTRA_PEER, peer)
                    }
                    ContextCompat.startForegroundService(this, intent)
                    result.success(true)
                }
                "stopService" -> {
                    val intent = Intent(this, ScreenShareService::class.java).apply {
                        action = ScreenShareService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        screenShareChannel?.let { ScreenShareService.onChannelReady(it) }
    }

    override fun onDestroy() {
        if (screenShareChannel != null) {
            screenShareChannel = null
        }
        super.onDestroy()
    }
}
