import 'package:flutter/material.dart';
import 'package:quorum/main.dart';
import 'package:quorum/widgets/slider_feature.dart';

class OnboardingScreen extends StatelessWidget{
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Column(
            children: [
              Column(
                  children: [
                    Padding(
                    padding: EdgeInsetsGeometry.only(right: 130,top: 30),                    
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                      'Work better\ntogether with',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'Quorum',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 43,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    ]),
                    ),
                    FeatureSlider(),
                  ],
                ),
            ],
          ),
        ),
    );
  }
}