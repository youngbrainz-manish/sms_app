package com.example.new_sms_app

import android.app.ActivityManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log
import io.flutter.plugin.common.EventChannel

class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            val smsDataList = mutableListOf<Map<String, Any?>>()
            for (sms in messages) {
                val data = mapOf(
                    "address" to sms.originatingAddress,
                    "body" to sms.messageBody,
                    "date" to System.currentTimeMillis(),
                    "is_mine" to 0,
                    "is_read" to 0
                )
                // Log.d("TAG", "Requesting default SMS role $data")
                smsDataList.add(data)
                // send to Flutter via EventChannel
                SmsStreamHandler.eventSink?.success(data)
            }

            // show notification only if app in background
            
                for (sms in messages) {
                    NotificationUtil.show(
                        context,
                        sms.originatingAddress ?: "Unknown",
                        sms.messageBody ?: ""
                    )
                }
            
        }
    }

    private fun isAppInForeground(context: Context): Boolean {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        for (process in am.runningAppProcesses) {
            if (process.processName == context.packageName &&
                process.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
            ) return true
        }
        return false
    }
}

// --- EventChannel Handler ---
class SmsStreamHandler(private val context: Context) : EventChannel.StreamHandler {

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
