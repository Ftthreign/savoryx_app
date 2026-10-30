import 'package:flutter/material.dart';
import 'core/di/injection_container.dart';
import 'core/utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const SavoryxApp());
}

class SavoryxApp extends StatelessWidget {
  const SavoryxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFE8ECF2),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8DB355),
          primary: const Color(0xFF8DB355),
          error: const Color(0xFFD90000),
          background: const Color(0xFFE8ECF2),
        ),
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'Savoryx Clean Architecture Initialized',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E222B),
            ),
          ),
        ),
      ),
    );
  }
}
