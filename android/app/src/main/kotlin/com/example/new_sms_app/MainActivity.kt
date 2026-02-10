package com.example.new_sms_app

import android.app.role.RoleManager
import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Telephony
import android.telephony.SmsManager
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.example.new_sms_app.utils.PhoneUtils

class MainActivity : FlutterActivity() {

    private val CHANNEL = "samples.flutter.dev/sms"
    private val EVENT_CHANNEL = "samples.flutter.dev/smsStream"
    private val NAV_CHANNEL = "sms_navigation"
    private val TAG = "SMS_APP"
    private var pendingResult: MethodChannel.Result? = null
    private val REQ_DEFAULT_SMS = 1001

    // ================= ACTIVITY =================

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        intent ?: return

        if (intent.getBooleanExtra("openConversation", false)) {
            val data = mapOf(
                "address" to intent.getStringExtra("address"),
                "threadId" to intent.getLongExtra("threadId", -1)
            )

            flutterEngine?.dartExecutor?.binaryMessenger?.let {
                MethodChannel(it, NAV_CHANNEL)
                    .invokeMethod("openConversation", data)
            }
        }
    }

    // ================= FLUTTER ENGINE =================

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(SmsStreamHandler())
    }

    // ================= SYSTEM SMS (SOURCE OF TRUTH) =================

    private fun getSystemSms(): List<Map<String, Any?>> {
        val list = mutableListOf<Map<String, Any?>>()

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

                val rawAddress = it.getString(0)

                // ✅ NORMALIZE HERE (CRITICAL)
                val address = PhoneUtils.normalize(
                    rawAddress,
                    source = "SystemSms"
                )

                list.add(
                    mapOf(
                        "address" to address,
                        "body" to it.getString(1),
                        "date" to it.getLong(2),
                        "is_mine" to if (it.getInt(3) == Telephony.Sms.MESSAGE_TYPE_SENT) 1 else 0,
                        "is_read" to it.getInt(4)
                    )
                )
            }
        }
        return list
    }

    // ================= DEFAULT SMS =================

    private fun isDefaultSmsApp(): Boolean {
        return Telephony.Sms.getDefaultSmsPackage(this) == packageName
    }

    private fun requestDefaultSmsRole(result: MethodChannel.Result) {

        if (isDefaultSmsApp()) {
            result.success(true)
            return
        }

        pendingResult = result

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val roleManager = getSystemService(RoleManager::class.java)
                startActivityForResult(
                    roleManager.createRequestRoleIntent(RoleManager.ROLE_SMS),
                    REQ_DEFAULT_SMS
                )
            } else {
                val intent = Intent(Telephony.Sms.Intents.ACTION_CHANGE_DEFAULT).apply {
                    putExtra(
                        Telephony.Sms.Intents.EXTRA_PACKAGE_NAME,
                        packageName
                    )
                }
                startActivityForResult(intent, REQ_DEFAULT_SMS)
            }
        } catch (e: Exception) {
            pendingResult?.success(false)
            pendingResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQ_DEFAULT_SMS) {
            pendingResult?.success(isDefaultSmsApp())
            pendingResult = null
        }
    }

    // ================= SEND SMS =================

    private fun sendSms(call: MethodCall, result: MethodChannel.Result) {

        val rawTo = call.argument<String>("to")
        val message = call.argument<String>("message")

        if (rawTo.isNullOrEmpty() || message.isNullOrEmpty()) {
            result.error("INVALID_ARGS", "Missing args", null)
            return
        }

        // ✅ NORMALIZE BEFORE SENDING
        val to = PhoneUtils.normalize(
            rawTo,
            source = "SendSms"
        )

        try {
            SmsManager.getDefault()
                .sendTextMessage(to, null, message, null, null)

            val values = ContentValues().apply {
                put(Telephony.Sms.ADDRESS, to)
                put(Telephony.Sms.BODY, message)
                put(Telephony.Sms.DATE, System.currentTimeMillis())
                put(Telephony.Sms.TYPE, Telephony.Sms.MESSAGE_TYPE_SENT)
                put(Telephony.Sms.READ, 1)
            }

            contentResolver.insert(Telephony.Sms.Sent.CONTENT_URI, values)
            result.success(true)

        } catch (e: Exception) {
            result.error("SMS_FAILED", e.message, null)
        }
    }
}
