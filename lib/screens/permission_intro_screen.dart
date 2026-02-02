import 'package:flutter/material.dart';
import 'package:new_sms_app/app_constants.dart';
import 'package:new_sms_app/screens/inbox_screen.dart';
import 'package:new_sms_app/services/sms_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionIntroScreen extends StatefulWidget {
  const PermissionIntroScreen({super.key});

  @override
  State<PermissionIntroScreen> createState() => _PermissionIntroScreenState();
}

class _PermissionIntroScreenState extends State<PermissionIntroScreen> {
  bool agreed = false;
  SharedPreferences? prefs;

  bool isDefaultApp = false;

  @override
  void initState() {
    _init1();
    _init2();
    super.initState();
  }

  _init2() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> _init1() async {
    isDefaultApp = await SmsManager().checkIsDefault();
    final prefs = await SharedPreferences.getInstance();
    bool accessGranted = prefs.getBool(AppConstants.accessGranted) ?? false;
    prefs.setBool(AppConstants.isDefaultApp, isDefaultApp);
    setState(() {});
    if (accessGranted && isDefaultApp) {
      // ignore: use_build_context_synchronously
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => InboxScreen()), (route) => false);
    } else {
      await SmsManager().requestDefaultSmsApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 40),

              /// APP ICON
              Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(24)),
                child: const Icon(Icons.message, color: Colors.white, size: 42),
              ),

              const SizedBox(height: 20),

              /// TITLE
              const Text("Messages", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),

              const SizedBox(height: 6),

              const Text("Your World, One Message Away", style: TextStyle(color: Colors.black54)),

              const SizedBox(height: 30),

              /// INFO TEXT
              const Text(
                "It is important that you understand what information the app collects and uses.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),

              const SizedBox(height: 25),

              /// BULLET POINTS
              _bulletItem("Phone Number", "Messages uses your phone number to send SMS messages."),

              _bulletItem("SMS", "Messages collects SMS to store and organize your incoming text messages."),

              _bulletItem(
                "Data Security and Privacy",
                "We do not share your data with third parties. Your privacy and security are our top priorities.",
              ),

              const Spacer(),

              /// AGREEMENT CHECKBOX
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(value: agreed, activeColor: Colors.indigo, onChanged: (v) => setState(() => agreed = v!)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(text: 'Click "Agree" means that you read & agreed to the '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600),
                            ),
                            TextSpan(text: ' & '),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// AGREE BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: agreed
                      ? () async {
                          await _requestPermissions();
                          // ignore: use_build_context_synchronously
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => InboxScreen()));
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    "Agree & Continue",
                    style: TextStyle(fontSize: 16, color: agreed ? Colors.white : Colors.black),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestPermissions() async {
    try {
      await [Permission.phone, Permission.sms, Permission.contacts].request();
      prefs?.setBool(AppConstants.accessGranted, true);
    } catch (e) {
      prefs?.setBool(AppConstants.accessGranted, false);
    }
  }

  Widget _bulletItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.star, color: Colors.indigo, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
