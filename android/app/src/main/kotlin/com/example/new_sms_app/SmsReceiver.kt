package com.example.new_sms_app

import android.app.ActivityManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import io.flutter.plugin.common.EventChannel
import com.example.new_sms_app.utils.PhoneUtils

class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isEmpty()) return

        // ✅ SAME ADDRESS FOR ALL PARTS
        val rawAddress = messages[0].originatingAddress ?: return
        val address = PhoneUtils.normalize(
            rawAddress,
            source = "SmsReceiver"
        )

        // ✅ MERGE MULTI-PART SMS
        val bodyBuilder = StringBuilder()
        for (sms in messages) {
            bodyBuilder.append(sms.messageBody ?: "")
        }

        // ✅ REAL SMS TIME (VERY IMPORTANT)
        val timestamp = messages[0].timestampMillis

        // ✅ SAVE TO ANDROID LOCAL DB (CRITICAL FIX)
        SmsLocalStore.insert(
            context = context,
            address = address,
            body = bodyBuilder.toString(),
            date = timestamp
        )

        // 🔹 OPTIONAL: notify Flutter IF app is alive
        SmsStreamHandler.eventSink?.success(
            mapOf(
                "address" to address,
                "body" to bodyBuilder.toString(),
                "date" to timestamp,
                "is_mine" to 0,
                "is_read" to 0
            )
        )

        // 🔔 Notification when app is background/killed
        if (!isAppInForeground(context)) {
            NotificationUtil.show(
                context = context,
                title = address,
                body = bodyBuilder.toString(),
                address = address,
                threadId = timestamp
            )
        }
    }

    private fun isAppInForeground(context: Context): Boolean {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val processes = am.runningAppProcesses ?: return false

        return processes.any {
            it.processName == context.packageName &&
            it.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
        }
    }
}

/* ---------------- EventChannel (OPTIONAL) ---------------- */

class SmsStreamHandler : EventChannel.StreamHandler {

    companion object {
        var eventSink: EventChannel.EventSink? = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
