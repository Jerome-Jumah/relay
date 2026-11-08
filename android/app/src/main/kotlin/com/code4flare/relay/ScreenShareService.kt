package com.code4flare.relay

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.drawable.Icon
import android.os.Build
import android.os.IBinder
import android.util.Log
import io.flutter.plugin.common.MethodChannel

class ScreenShareService : Service() {
    companion object {
        const val TAG = "RelayShareNative"
        const val CHANNEL_ID = "relay_screen_share_channel"
        const val NOTIFICATION_ID = 4040
        const val ACTION_START = "com.code4flare.relay.action.START_SCREEN_SHARE"
        const val ACTION_STOP = "com.code4flare.relay.action.STOP_SCREEN_SHARE"
        const val ACTION_STOP_REQUESTED = "com.code4flare.relay.action.STOP_SHARING_ACTION"
        const val EXTRA_PEER = "com.code4flare.relay.extra.PEER"

        @Volatile
        var pendingStopRequest = false

        fun onChannelReady(channel: MethodChannel) {
            if (pendingStopRequest) {
                Log.i(TAG, "[RelayShareNative] MethodChannel ready; delivering deferred stop request")
                pendingStopRequest = false
                channel.invokeMethod("onStopScreenShareRequested", null)
            }
        }
    }

    private var currentPeer: String? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "[RelayShareNative] service onCreate")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            pendingStopRequest = false
            stopForegroundService()
            return START_NOT_STICKY
        }

        if (intent?.action == ACTION_STOP_REQUESTED) {
            Log.i(TAG, "[RelayShareNative] Stop sharing requested from notification action")
            val channel = MainActivity.screenShareChannel
            if (channel != null) {
                channel.invokeMethod("onStopScreenShareRequested", null)
            } else {
                Log.i(TAG, "[RelayShareNative] Flutter channel unavailable; deferring stop request and bringing MainActivity to foreground")
                pendingStopRequest = true
                val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                    this.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                if (launchIntent != null) {
                    startActivity(launchIntent)
                }
            }
            return START_NOT_STICKY
        }

        val peerArg = intent?.getStringExtra(EXTRA_PEER)
        if (!peerArg.isNullOrEmpty()) {
            currentPeer = peerArg
        }

        val notification = createNotification(currentPeer)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        Log.i(TAG, "[RelayShareNative] startForeground complete")

        return START_STICKY
    }

    private fun removeForegroundNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    private fun stopForegroundService() {
        removeForegroundNotification()
        stopSelf()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Screen Sharing",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notification displayed while Relay screen sharing is active"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(peer: String?): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            this.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentPendingIntent = if (launchIntent != null) {
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            PendingIntent.getActivity(this, 0, launchIntent, flags)
        } else null

        val stopIntent = Intent(this, ScreenShareService::class.java).apply {
            action = ACTION_STOP_REQUESTED
        }
        val stopFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val stopPendingIntent = PendingIntent.getService(this, 1, stopIntent, stopFlags)

        val bodyText = if (!peer.isNullOrBlank()) {
            "Sharing your screen in call with $peer"
        } else {
            "Sharing your screen in call"
        }

        builder
            .setContentTitle("Relay — Sharing screen")
            .setContentText(bodyText)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)

        if (contentPendingIntent != null) {
            builder.setContentIntent(contentPendingIntent)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val stopAction = Notification.Action.Builder(
                Icon.createWithResource(this, android.R.drawable.ic_menu_close_clear_cancel),
                "Stop sharing",
                stopPendingIntent
            ).build()
            builder.addAction(stopAction)
        } else {
            @Suppress("DEPRECATION")
            builder.addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Stop sharing",
                stopPendingIntent
            )
        }

        return builder.build()
    }

    override fun onDestroy() {
        Log.i(TAG, "[RelayShareNative] service onDestroy")
        removeForegroundNotification()
        super.onDestroy()
    }
}
