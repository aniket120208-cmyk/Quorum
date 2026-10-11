import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/api/chat_socket_service.dart';
import 'package:quorum/repositories/auth_repository.dart';
import 'package:quorum/screens/sign_in_screen/sign_in_screen.dart';

const _bg = Color(0xFF0B0C14);
const _card = Color(0xFF14151F);
const _cardBorder = Color(0x1AFFFFFF);
const _teal = Color(0xFF3DDCC4);
const _muted = Color(0xFF9EA3AE);

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _selectedOrganization = 'No Organization';
  final List<String> _organizations = [
    'No Organization',
  ];

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    return 'Good evening';
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthRepository>().currentUser;
    final userName = user?.name ?? 'User';
    final initials = _initials(userName);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, initials),
              const SizedBox(height: 22),
              Text(
                '${_getTimeGreeting()}, $userName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Here is what is happening across your teams today.',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 18),
              _buildHero(),
              const SizedBox(height: 22),
              _buildWorkspaceActions(),
              const SizedBox(height: 12),
              _buildFreelanceCard(),
              const SizedBox(height: 16),
              const _CalendarCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String initials) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFFFD8D3),
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        PopupMenuButton<String>(
          color: _card,
          elevation: 8,
          offset: const Offset(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _cardBorder),
          ),
          onSelected: (String value) {
            setState(() {
              _selectedOrganization = value;
            });
          },
          itemBuilder: (BuildContext context) {
            return _organizations.map((String org) {
              final isSelected = org == _selectedOrganization;
              return PopupMenuItem<String>(
                value: org,
                child: Row(
                  children: [
                    Icon(
                      org == 'No Organization'
                          ? Icons.block_rounded
                          : Icons.apartment_rounded,
                      color: isSelected ? _teal : Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        org,
                        style: TextStyle(
                          color: isSelected ? _teal : Colors.white,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_rounded, color: _teal, size: 16),
                  ],
                ),
              );
            }).toList();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.apartment_rounded, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Text(
                    _selectedOrganization,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 18),
              ],
            ),
          ),
        ),
        const Spacer(),
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
              onPressed: () {},
            ),
            Positioned(
              right: 11,
              top: 11,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
          onPressed: () => _logout(context),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3A2D6B), Color(0xFF1E2A4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -10,
              child: Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C4BE0), Color(0xFF3B2A93)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 70,
              top: 28,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(color: Color(0xFFF5B83D), shape: BoxShape.circle),
              ),
            ),
            Positioned(
              right: -30,
              bottom: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(color: Color(0xFF1F7F86), shape: BoxShape.circle),
              ),
            ),
            Positioned(
              right: 40,
              bottom: 18,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(color: Color(0xFF3DB6A8), shape: BoxShape.circle),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Build, collaborate, make\nit happen.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Plan, create, collaborate and turn\nyour vision into reality.',
                    style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspaceActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Workspace Actions',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF12241F),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x4D3DDCC4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BlinkingDot(),
                  SizedBox(width: 6),
                  Text(
                    'Get Started',
                    style: TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _actionCard(
                  icon: Icons.add_business_outlined,
                  title: 'Create\nOrganization',
                  subtitle: 'Start your company or department hub',
                  cta: 'Build now',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionCard(
                  icon: Icons.group_add_outlined,
                  title: 'Join\nOrganization',
                  subtitle: 'Connect via direct invite links or id/QR code',
                  cta: 'Enter code',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String cta,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(icon),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11, height: 1.35)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cta,
                  style: const TextStyle(
                    color: _teal,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    decorationColor: _teal,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, color: _teal, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreelanceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(Icons.work_outline_rounded),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Freelance & Contractor',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Join client workspaces with guest permissions',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(color: _cardBorder),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('No organisation account needed', style: TextStyle(color: _muted, fontSize: 11)),
              GestureDetector(
                onTap: () {},
                child: const Row(
                  children: [
                    Text(
                      'Join Workspace',
                      style: TextStyle(
                        color: _teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        decorationColor: _teal,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, color: _teal, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      );

  Widget _iconBox(IconData icon, {double size = 40}) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF16302F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: _teal, size: size * 0.5),
      );
}

class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat(reverse: true);
    _opacityAnim = Tween<double>(begin: 0.15, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnim,
      child: const Icon(Icons.circle, color: Color(0xFF34D399), size: 7),
    );
  }
}

class _CalendarCard extends StatefulWidget {
  const _CalendarCard();

  @override
  State<_CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<_CalendarCard> {
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  late DateTime _visibleMonth;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _resetToToday();
  }

  void _resetToToday() {
    final now = DateTime.now();
    setState(() {
      _visibleMonth = DateTime(now.year, now.month);
      _selected = DateTime(now.year, now.month, now.day);
    });
  }

  bool _isTodaySelected() {
    final now = DateTime.now();
    return _selected.year == now.year &&
        _selected.month == now.month &&
        _selected.day == now.day;
  }

  void _changeMonth(int delta) {
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta));
  }

  Future<void> _pickMonth() async {
    int year = _visibleMonth.year;
    bool isPickingYear = false;

    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _navButton(Icons.chevron_left, () {
                          setSheet(() => year--);
                        }),
                        GestureDetector(
                          onTap: () {
                            setSheet(() => isPickingYear = !isPickingYear);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPickingYear ? const Color(0xFF16302F) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isPickingYear ? _teal : Colors.white24,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$year',
                                  style: TextStyle(
                                    color: isPickingYear ? _teal : Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  isPickingYear ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                  color: isPickingYear ? _teal : Colors.white70,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        _navButton(Icons.chevron_right, () {
                          setSheet(() => year++);
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isPickingYear)
                      SizedBox(
                        height: 190,
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.9,
                          ),
                          itemCount: 51,
                          itemBuilder: (context, idx) {
                            final itemYear = 2000 + idx;
                            final isCurrent = itemYear == year;
                            return GestureDetector(
                              onTap: () {
                                setSheet(() {
                                  year = itemYear;
                                  isPickingYear = false;
                                });
                              },
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isCurrent ? const Color(0xFF3FA79A) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isCurrent ? _teal : _cardBorder),
                                ),
                                child: Text(
                                  '$itemYear',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.9,
                        children: List.generate(12, (i) {
                          final isCurrent = year == _visibleMonth.year && i + 1 == _visibleMonth.month;
                          return GestureDetector(
                            onTap: () => Navigator.pop(ctx, DateTime(year, i + 1)),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isCurrent ? const Color(0xFF3FA79A) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isCurrent ? _teal : _cardBorder),
                              ),
                              child: Text(
                                _months[i].substring(0, 3),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _visibleMonth = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offset = DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday % 7;
    final isToday = _isTodaySelected();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Calendar',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _pickMonth,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_months[_visibleMonth.month - 1].substring(0, 3)} ${_visibleMonth.year}',
                        style: const TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.keyboard_arrow_down, color: _teal, size: 16),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _resetToToday,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isToday ? const Color(0xFF16302F) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isToday ? _teal : Colors.white24,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Today',
                    style: TextStyle(
                      color: isToday ? _teal : _muted.withAlpha(140),
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _navButton(Icons.chevron_left, () => _changeMonth(-1)),
              const SizedBox(width: 6),
              _navButton(Icons.chevron_right, () => _changeMonth(1)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: _weekdays
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d, style: const TextStyle(color: _muted, fontSize: 11)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: List.generate(42, (i) {
              final date = DateTime(_visibleMonth.year, _visibleMonth.month, 1 - offset + i);
              final inMonth = date.month == _visibleMonth.month;
              final isSelected = date.year == _selected.year &&
                  date.month == _selected.month &&
                  date.day == _selected.day;

              return GestureDetector(
                onTap: () => setState(() => _selected = date),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF3FA79A) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: _teal, width: 1.5) : null,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : inMonth
                              ? Colors.white
                              : Colors.white24,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: Colors.white70, size: 18),
        ),
      );
}