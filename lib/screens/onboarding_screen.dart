import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:quorum/main.dart';
import 'package:quorum/screens/sign_in_screen/sign_in_screen.dart';
import 'package:quorum/widgets/slider_feature.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;

    final headingSize = (width * 0.075).clamp(26.0, 32.0);
    final quorumSize = (width * 0.095).clamp(32.0, 40.0);
    final imageSize = (width * 0.78).clamp(260.0, 350.0);
    final horizontalPadding = width * 0.08;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                ),
                child: Column(
                  children: [
                    SizedBox(height: height * 0.035),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Work better\ntogether with',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: headingSize,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                              colors: [
                                Color(0xFF5548E5),
                                Color(0xFF8057DA),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(bounds),
                            child: Text(
                              'Quorum',
                              style: TextStyle(
                                fontSize: quorumSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: height * 0.025),

                    Image.asset(
                      'lib/assets/q.png',
                      height: imageSize,
                      width: imageSize,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),

              SizedBox(height: height * 0.01),

              const FeatureSlider(),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                ),
                child: Column(
                  children: [
                    SizedBox(height: height * 0.035),

                    SizedBox(
                      width: width * 0.78,
                      height: 50,
                      child: CupertinoButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SigninScreen(),
                            ),
                          );
                        },
                        color: const Color.fromARGB(221, 46, 86, 217),
                        padding: EdgeInsets.zero,
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: height * 0.025),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}