import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:planandbill/services/auth_service.dart';
import 'package:planandbill/screens/splash_screen.dart';
import 'package:planandbill/theme/app_theme.dart';
import 'package:planandbill/services/appointment_service.dart';
import 'package:planandbill/services/client_service.dart';
import 'package:planandbill/services/invoice_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialisation de Firebase
  await Firebase.initializeApp();

  // ✅ Activation de AppCheck (après)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity, // ou .debug pour tests
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AppointmentService()),
        ChangeNotifierProvider(create: (_) => ClientService()),
        ChangeNotifierProvider(create: (_) => InvoiceService()),
      ],
      child: MaterialApp(
        title: 'PlanAndBill',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
      ),
    );
  }
}
