import 'package:flutter/material.dart';
import 'package:quorum/screens/onBoarding_screen.dart';

void main(){
  runApp(const Quorum());
}

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0A12);
  static const Color surface = Color(0xFF15151F);
  static const Color surfaceBorder = Color(0xFF2A2A38);

  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF9C9CAD);

  static const Color primary = Color(0xFF6F5EF6);
  static const Color primaryLight = Color(0xFF8B7DFA);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );

  static const RadialGradient backgroundGlow = RadialGradient(
    center: Alignment(0, -0.35),
    radius: 1.2,
    colors: [Color(0xFF241E42), background],
  );
}

class Quorum extends StatelessWidget{
  const Quorum({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: OnboardingScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
      )
    );
  }
}