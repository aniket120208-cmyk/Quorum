import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/api/chat_socket_service.dart';
import 'package:quorum/repositories/auth_repository.dart';
import 'package:quorum/screens/sign_in_screen/sign_in_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});
  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    context.read<ChatSocketService>().disconnect();
    await context.read<AuthRepository>().logout();
    if (!context.mounted) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SigninScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthRepository>().currentUser;
    final userName = user?.name ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFF0F1017),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFFFD8D3),
                    child: Text(
                      userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1B26),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Core Team',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 20),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
                        onPressed: () {},
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: circleBadge,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '${_getTimeGreeting()}, $userName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Here is what is happening across\nyour teams today.',
                style: TextStyle(
                  color: Color(0xFF9EA3AE),
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF43495D),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.white70, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search messages, meetings or ask',
                          hintStyle: TextStyle(color: Colors.white70, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF352B6A), Color(0xFF1E3258)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Build, collaborate, make it\nhappen.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Plan, create, collaborate and turn\nyour vision into reality.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Quick actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildQuickAction('Files'),
                  const SizedBox(width: 10),
                  _buildQuickAction('Tasks\nassigned'),
                  const SizedBox(width: 10),
                  _buildQuickAction('Organization'),
                  const SizedBox(width: 10),
                  _buildQuickAction('Saved'),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scheduled Meetings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Row(
                      children: [
                        Text(
                          'View agenda',
                          style: TextStyle(
                            color: Color(0xFF887BF4),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right, color: Color(0xFF887BF4), size: 18),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF384052),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Color(0xFF4A44D1), width: 5),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8C8C2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'In 20 mins',
                                style: TextStyle(
                                  color: Color(0xFF9E4436),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Text(
                              '10:30 - 11:15 AM',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Design System Review',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            SizedBox(
                              width: 90,
                              height: 32,
                              child: Stack(
                                children: [
                                  _buildAvatar(0, Colors.teal),
                                  _buildAvatar(18, Colors.amber),
                                  _buildAvatar(36, Colors.brown),
                                  Positioned(
                                    left: 54,
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: const Color(0xFF7A869A),
                                      child: const Text(
                                        '+4',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF33338B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: const Icon(Icons.videocam, color: Colors.white, size: 18),
                              label: const Text(
                                'Join Room',
                                style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static const BoxShape circleBadge = BoxShape.circle;

  Widget _buildQuickAction(String title) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF358C96), Color(0xFF1E6370)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(double left, Color color) {
    return Positioned(
      left: left,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF384052), width: 1.5),
        ),
        child: CircleAvatar(
          radius: 15,
          backgroundColor: color,
        ),
      ),
    );
  }
}