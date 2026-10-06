import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/api/api_exception.dart';
import 'package:quorum/repositories/auth_repository.dart';
import 'package:quorum/screens/home_screen/home_screen.dart';
import 'package:quorum/screens/widgets/corner_background_orb.dart';

class QuorumColors {
  static const bg = Color(0xFF0B0B14);
  static const card = Color(0xFF14141F);
  static const cardBorder = Color(0xFF1C1C2C);
  static const row = Color(0xFF1A1A27);
  static const rowBorder = Color(0xFF23233A);
  static const rowActiveBg = Color(0xFF1D1B3F);
  static const rowActiveBorder = Color(0xFF4B45E0);
  static const accent = Color(0xFF4F46F0);
  static const accentDisabled = Color(0xFF1F1D44);
  static const text = Colors.white;
  static const textRow = Color(0xFFD5D5E4);
  static const textMuted = Color(0xFF9A9AB0);
  static const textDisabled = Color(0xFF5A5A78);
  static const link = Color(0xFF6C63FF);
  static const checkBorder = Color(0xFF3A3A55);
}

class UseOption {
  final String id;
  final String label;
  const UseOption(this.id, this.label);
}

const _options = [
  UseOption('ORGANIZATION', 'Work at an Organization'),
  UseOption('FREELANCE', 'Freelance'),
  UseOption('HIRE_COLLABORATE', 'Hire & Collaborate'),
  UseOption('COMMUNITY', 'Communities'),
];

class UseQuorumScreen extends StatefulWidget {
  const UseQuorumScreen({super.key});

  @override
  State<UseQuorumScreen> createState() => _UseQuorumScreenState();
}

class _UseQuorumScreenState extends State<UseQuorumScreen> {
  final Set<String> _selected = {};
  bool _busy = false;

  bool get _hasSelection => _selected.isNotEmpty;

  Future<void> _finish(List<String> useCases) async {
    if (_busy) return;
    setState(() => _busy = true);

    final repository = context.read<AuthRepository>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await repository.saveOnboarding(useCases);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(messageFromError(e))));
      return;
    }

    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final s = (size.width.clamp(0, 480) / 375).clamp(0.85, 1.25).toDouble();
    final v = (size.height / 812).clamp(0.8, 1.2).toDouble();

    final textScaler = MediaQuery.textScalerOf(context)
        .clamp(minScaleFactor: 0.9, maxScaleFactor: 1.3);

    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: QuorumColors.bg,
      body: Stack(
        children: [
          const CornerBackgroundOrb.topRight(backgroundColor: QuorumColors.bg),
          const CornerBackgroundOrb.bottomLeft(backgroundColor: QuorumColors.bg),
          SafeArea(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                              20 * s, 28 * v, 20 * s, 16 * v),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _header(s, v),
                              SizedBox(height: 20 * v),
                              _optionsCard(s),
                              const Spacer(),
                              SizedBox(height: 40 * v),
                              _continueButton(s),
                              SizedBox(height: 14 * v),
                              Center(child: _skipButton(s)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _header(double s, double v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How do you want\nto use Quorum?',
          style: TextStyle(
            color: QuorumColors.text,
            fontSize: 26 * s,
            height: 1.3,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: 8 * v),
        Text(
          'Select all that apply.',
          style: TextStyle(
            color: QuorumColors.textMuted,
            fontSize: 12 * s,
          ),
        ),
      ],
    );
  }

  Widget _optionsCard(double s) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10 * s),
      decoration: BoxDecoration(
        color: QuorumColors.card,
        borderRadius: BorderRadius.circular(16 * s),
        border: Border.all(color: QuorumColors.cardBorder),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _options.length; i++) ...[
            _optionRow(_options[i], s),
            if (i != _options.length - 1) SizedBox(height: 8 * s),
          ],
        ],
      ),
    );
  }

  Widget _optionRow(UseOption opt, double s) {
    final active = _selected.contains(opt.id);

    return Semantics(
      checked: active,
      inMutuallyExclusiveGroup: false,
      label: opt.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _toggle(opt.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: double.infinity,
          constraints: BoxConstraints(minHeight: (46 * s).clamp(44, 70)),
          padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 10 * s),
          decoration: BoxDecoration(
            color: active ? QuorumColors.rowActiveBg : QuorumColors.row,
            borderRadius: BorderRadius.circular(12 * s),
            border: Border.all(
              color:
                  active ? QuorumColors.rowActiveBorder : QuorumColors.rowBorder,
            ),
          ),
          child: Row(
            children: [
              _checkbox(active, s),
              SizedBox(width: 12 * s),
              Expanded(
                child: Text(
                  opt.label,
                  style: TextStyle(
                    color: active ? QuorumColors.text : QuorumColors.textRow,
                    fontSize: 13 * s,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _checkbox(bool active, double s) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 18 * s,
      height: 18 * s,
      decoration: BoxDecoration(
        color: active ? QuorumColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(5 * s),
        border: Border.all(
          color: active ? QuorumColors.accent : QuorumColors.checkBorder,
          width: 1.5,
        ),
      ),
      child: active
          ? Icon(Icons.check_rounded, size: 13 * s, color: Colors.white)
          : null,
    );
  }

  Widget _continueButton(double s) {
    final enabled = _hasSelection;

    return SizedBox(
      width: double.infinity,
      height: (46 * s).clamp(44, 64),
      child: ElevatedButton(
        onPressed:
            enabled && !_busy ? () => _finish(_selected.toList()) : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: QuorumColors.accent,
          disabledBackgroundColor: QuorumColors.accentDisabled,
          foregroundColor: Colors.white,
          disabledForegroundColor: QuorumColors.textDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * s),
          ),
        ),
        child: _busy
            ? SizedBox(
                width: 18 * s,
                height: 18 * s,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                'Continue',
                style: TextStyle(fontSize: 14 * s, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _skipButton(double s) {
    return TextButton(
      onPressed: _busy ? null : () => _finish(const []),
      style: TextButton.styleFrom(
        foregroundColor: QuorumColors.link,
        padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: Text(
        'Skip for now',
        style: TextStyle(fontSize: 12 * s, fontWeight: FontWeight.w500),
      ),
    );
  }
}