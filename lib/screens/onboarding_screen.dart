import 'package:flutter/cupertino.dart';
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
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                      Color(0xFF5548E5),
                      Color(0xFF8057DA),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      ).createShader(bounds),
                      child: const Text(
                        'Quorum',
                        style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        ),
                      ),
                    )
                    ]),
                    ),
                    Image.asset('lib/assets/q.png', height: 350, width: 350,),
                    SizedBox(height: 5,),
                    FeatureSlider(),
                    SizedBox(height: 28,),
                    CupertinoButton(
                      onPressed: (){},
                      minimumSize: const Size(230, 50),
                      color: const Color.fromARGB(221, 46, 86, 217) ,
                      child: Text('Get Started', 
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),),)
                  ],
                ),
            ],
          ),
        ),
    );
  }
}