package com.example.new_sms_app

import android.app.PendingIntent
import android.app.role.RoleManager
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Telephony
import android.telephony.SmsManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.util.Log


class MainActivity : FlutterActivity() {

    private val CHANNEL = "samples.flutter.dev/sms"
    private val EVENT_CHANNEL = "samples.flutter.dev/smsStream"
    private val TAG = "SMS_APP"
    // Log.d(TAG, "Requesting default SMS role")


    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // METHOD CHANNEL
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sendSms" -> sendSms(call, result)
                    "requestDefaultSms" -> requestDefaultSmsRole(result)
                    "isDefaultSmsApp" -> result.success(isDefaultSmsApp())
                    "fetchSystemSms" -> result.success(getSystemSms())
                    else -> result.notImplemented()
                }
            }

        // EVENT CHANNEL (incoming SMS / status updates)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(SmsStreamHandler(this))
    }

    // ================= FETCH SYSTEM SMS =================
    private fun getSystemSms(): List<Map<String, Any?>> {
        val smsList = mutableListOf<Map<String, Any?>>()

        val cursor = contentResolver.query(
            Telephony.Sms.CONTENT_URI,
            arrayOf(
                Telephony.Sms.ADDRESS,
                Telephony.Sms.BODY,
                Telephony.Sms.DATE,
                Telephony.Sms.TYPE,
                Telephony.Sms.READ
            ),
            null,
            null,
            "date DESC"
        )

        cursor?.use {
            while (it.moveToNext()) {
                smsList.add(
                    mapOf(
                        "address" to it.getString(0),
                        "body" to it.getString(1),
                        "date" to it.getLong(2),
                        "is_mine" to if (it.getInt(3) == Telephony.Sms.MESSAGE_TYPE_SENT) 1 else 0,
                        "is_read" to it.getInt(4)
                    )
                )
            }
        }
        return smsList
    }

    // ================= DEFAULT SMS APP CHECK =================
    private fun isDefaultSmsApp(): Boolean {
        return Telephony.Sms.getDefaultSmsPackage(this) == packageName
    }

    // ================= REQUEST DEFAULT SMS ROLE =================
    private fun requestDefaultSmsRole(result: MethodChannel.Result) {

        if (isDefaultSmsApp()) {
            result.success(true)
            return
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val roleManager = getSystemService(RoleManager::class.java)

                if (roleManager.isRoleAvailable(RoleManager.ROLE_SMS)) {
                    val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_SMS)
                    startActivityForResult(intent, 1001)
                }
            } else {
                val intent = Intent(Telephony.Sms.Intents.ACTION_CHANGE_DEFAULT).apply {
                    putExtra(
                        Telephony.Sms.Intents.EXTRA_PACKAGE_NAME,
                        packageName
                    )
                }
                startActivityForResult(intent, 1001)
            }

            result.success(true)

        } catch (e: Exception) {
            Log.e(TAG, "Default SMS request failed", e)
            result.success(false)
        }
    }


    // ================= SEND SMS =================
    private fun sendSms(call: MethodCall, result: MethodChannel.Result) {
    val to = call.argument<String>("to")
    val message = call.argument<String>("message")
    val timestamp = call.argument<Long>("timestamp") ?: System.currentTimeMillis()

    if (to.isNullOrEmpty() || message.isNullOrEmpty()) {
        result.error("INVALID_ARGS", "Phone number or message missing", null)
        return
    }

    try {
        // SEND SMS (no status receivers)
        SmsManager.getDefault()
            .sendTextMessage(to, null, message, null, null)

        // INSERT INTO SYSTEM DB (default SMS app only)
        val values = ContentValues().apply {
            put(Telephony.Sms.ADDRESS, to)
            put(Telephony.Sms.BODY, message)
            put(Telephony.Sms.DATE, timestamp)
            put(Telephony.Sms.TYPE, Telephony.Sms.MESSAGE_TYPE_SENT)
            put(Telephony.Sms.READ, 1)
        }

        contentResolver.insert(Telephony.Sms.Sent.CONTENT_URI, values)

        result.success(true)

    } catch (e: Exception) {
        result.error("SMS_FAILED", e.localizedMessage, null)
    }
}
}
