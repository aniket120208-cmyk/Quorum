import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/home_cubit.dart';
import 'home_tab.dart';
import 'package:quorum/main.dart';
import 'package:quorum/screens/ai_assistant_screen/ai_assistant_screen.dart';
import 'package:quorum/screens/chat_screen/chat_screen.dart';
import 'package:quorum/screens/community_screen/community_screen.dart';
import 'package:quorum/screens/video_call_screen/video_call_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  static const _tabs = <Widget>[
    HomeTab(),
    ChatScreen(),
    VideoCallScreen(),
    CommunityScreen(),
    AiAssistantScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, s) {
        return Scaffold(
          body: IndexedStack(
            index: s.tabIndex,
            children: _tabs,
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: s.tabIndex,
            onTap: (i) => context.read<HomeCubit>().selectTab(i),
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.primaryLight,
            unselectedItemColor: AppColors.textSecondary,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.videocam_outlined),
                activeIcon: Icon(Icons.videocam),
                label: 'Video Call',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.groups_outlined),
                activeIcon: Icon(Icons.groups),
                label: 'Community',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome_outlined),
                activeIcon: Icon(Icons.auto_awesome),
                label: 'AI Assistant',
              ),
            ],
          ),
        );
      },
    );
  }
}