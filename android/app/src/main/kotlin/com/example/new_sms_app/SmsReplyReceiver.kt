package com.example.new_sms_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.SmsManager
import androidx.core.app.RemoteInput

class SmsReplyReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {

        val replyText = RemoteInput.getResultsFromIntent(intent)
            ?.getCharSequence("key_text_reply")
            ?.toString()
            ?: return

        val address = intent.getStringExtra("address") ?: return

        val smsManager = SmsManager.getDefault()

        smsManager.sendTextMessage(
            address,
            null,
            replyText,
            null,
            null
        )
    }
}
