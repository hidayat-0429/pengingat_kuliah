import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'utils/constants.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pengingat Kuliah',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: AppColors.primary,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgPrimary,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
