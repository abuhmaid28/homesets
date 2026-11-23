package com.abuhmaid.homesets

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

class HomesetsReminderReceiver : BroadcastReceiver() {
    companion object {
        const val REMINDER_NOTIFICATION_ID = 1001
        const val ACTION_DAILY_REMINDER = "com.abuhmaid.homesets.ACTION_DAILY_REMINDER"
    }

    override fun onReceive(context: Context, intent: Intent) {
        // 1. Enforce fail-closed in-app consent invariant (P6-NOTIFY-07, P6-NOTIFY-08)
        val prefs = context.getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE)
        val hasConsent = prefs.getBoolean(MainActivity.KEY_REMINDER_CONSENT, false)
        if (!hasConsent) {
            // App consent is OFF, revoked, or pending reconciliation: suppress delivery and cancel stray alarm
            cancelAlarmSilently(context)
            return
        }

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

        // 2. Verify system-level notification permission (P6-NOTIFY-08)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            if (!notificationManager.areNotificationsEnabled()) {
                // OS permission was revoked while app was stopped: revoke consent fail-closed and cancel alarm
                prefs.edit().putBoolean(MainActivity.KEY_REMINDER_CONSENT, false).commit()
                cancelAlarmSilently(context)
                return
            }
        }

        // 3. Verify notification channel importance on Android 8+ (API 26+) (P6-NOTIFY-09)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = notificationManager.getNotificationChannel(MainActivity.REMINDER_CHANNEL_ID)
            if (channel != null && channel.importance == NotificationManager.IMPORTANCE_NONE) {
                // Channel is blocked by user in system settings: suppress delivery
                return
            }
        }

        val title = intent.getStringExtra("title") ?: "HOMESETS"
        val body = intent.getStringExtra("body") ?: "Ready for your workout?"

        val tapIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val tapPendingIntent = PendingIntent.getActivity(
            context,
            0,
            tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val notification = NotificationCompat.Builder(context, MainActivity.REMINDER_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_popup_reminder)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setContentIntent(tapPendingIntent)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        try {
            notificationManager.notify(REMINDER_NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {
            // Handled when POST_NOTIFICATIONS is not yet granted on Android 13+
        }
    }

    private fun cancelAlarmSilently(context: Context) {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val intent = Intent(context, HomesetsReminderReceiver::class.java).apply {
                action = ACTION_DAILY_REMINDER
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                MainActivity.REMINDER_REQUEST_CODE,
                intent,
                PendingIntent.FLAG_NO_CREATE or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )
            if (pendingIntent != null) {
                alarmManager.cancel(pendingIntent)
                pendingIntent.cancel()
            }
        } catch (_: Exception) {
            // Best-effort cleanup
        }
    }
}
