package com.example.new_sms_app

import android.app.role.RoleManager
import android.content.Intent
import android.os.Build
import android.provider.Telephony
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log


class MainActivity : FlutterActivity() {

    private val CHANNEL = "samples.flutter.dev/sms"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestDefaultSms" -> requestDefaultSmsRole(result)
                    "isDefaultSmsApp" -> result.success(isDefaultSmsApp())
                    "fetchSystemSms" -> result.success(getSystemSms())
                    else -> result.notImplemented()
                }
            }
    }

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
                        "is_mine" to if (it.getInt(3) ==
                            Telephony.Sms.MESSAGE_TYPE_SENT) 1 else 0,
                        "is_read" to it.getInt(4)
                    )
                )
            }
        }
        return smsList
    }

    private fun isDefaultSmsApp(): Boolean {
        return Telephony.Sms.getDefaultSmsPackage(this) == packageName
    }

    private fun requestDefaultSmsRole(result: MethodChannel.Result) {
        Log.e("SMS_ROLE", "Requesting default SMS role")
        if (isDefaultSmsApp()) {
            result.success("Already Default")
            return
        }

        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(RoleManager::class.java)
            roleManager.createRequestRoleIntent(RoleManager.ROLE_SMS)
        } else {
            Intent(Telephony.Sms.Intents.ACTION_CHANGE_DEFAULT).apply {
                putExtra(
                    Telephony.Sms.Intents.EXTRA_PACKAGE_NAME,
                    packageName
                )
            }
        }

        // 🔥 MUST use startActivityForResult
        startActivityForResult(intent, 101)
        result.success(true)
    }

}
