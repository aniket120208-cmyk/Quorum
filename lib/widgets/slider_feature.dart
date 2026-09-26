import 'dart:async';
import 'package:flutter/material.dart';

class FeatureSlider extends StatefulWidget {
  const FeatureSlider({super.key});

  @override
  State<FeatureSlider> createState() => _FeatureSliderState();
}

class _FeatureSliderState extends State<FeatureSlider> {
  final PageController _pageController = PageController(
    initialPage: 100000,
    viewportFraction: 0.72,
  );

  Timer? _timer;

  final List<Map<String, dynamic>> features = [
    {
      'title': 'File Sharing',
      'subtitle': 'Access, share, collaboration',
      'icon': Icons.folder_outlined,
    },
    {
      'title': 'Team Chat',
      'subtitle': 'Stay connected',
      'icon': Icons.chat_bubble_outline,
    },
    {
      'title': 'Video Meetings',
      'subtitle': 'Turn ideas into action',
      'icon': Icons.videocam_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        if (!_pageController.hasClients) return;

        final currentPage = _pageController.page?.round() ?? 100000;

        _pageController.animateToPage(
          currentPage + 1,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      child: PageView.builder(
        controller: _pageController,
        itemBuilder: (context, index) {
          final feature = features[index % features.length];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xff151721),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xff292b38),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  feature['icon'],
                  size: 24,
                  color: const Color(0xff7065ff),
                ),
                const SizedBox(width: 15),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      feature['subtitle'],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}