package com.example.new_sms_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log

class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_DELIVER_ACTION ||
            intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {

            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)

            for (sms in messages) {
                val body = sms.messageBody ?: ""
                val address = sms.originatingAddress ?: "Unknown"

                Log.d("SMS_RECEIVER", "SMS from $address: $body")

                // Only show notification (NO DB access here)
                NotificationUtil.createChannel(context)
                NotificationUtil.showNotification(context, address, body)
            }
        }
    }
}
