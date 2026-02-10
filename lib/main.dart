import 'package:flutter/material.dart';
import 'package:new_sms_app/app_constants.dart';
import 'package:new_sms_app/provider/inbox_provider.dart';
import 'package:new_sms_app/screens/inbox_screen.dart';
import 'package:new_sms_app/screens/permission_intro_screen.dart';
import 'package:new_sms_app/services/sms_navigation_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoading = true;
  bool accessGranted = false;
  bool isDefaultApp = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    SmsNavigationService.init(context);
    final prefs = await SharedPreferences.getInstance();
    accessGranted = prefs.getBool(AppConstants.accessGranted) ?? false;
    isDefaultApp = prefs.getBool(AppConstants.isDefaultApp) ?? false;

    isLoading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(color: Colors.white),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => InboxProvider())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), useMaterial3: true),
        home: (accessGranted && isDefaultApp) ? const InboxScreen() : const PermissionIntroScreen(),
      ),
    );
  }
}
