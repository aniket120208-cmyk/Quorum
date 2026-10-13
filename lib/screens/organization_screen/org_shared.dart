import 'package:flutter/material.dart';

const orgBg = Color(0xFF0B0C14);
const orgCardBorder = Color(0x1AFFFFFF);
const orgTeal = Color(0xFF3DDCC4);
const orgMuted = Color(0xFF9EA3AE);
const orgPurple = Color(0xFF6C4BE0);
const orgPurpleDeep = Color(0xFF3B2A93);
const orgPurpleSoft = Color(0xFF8B7DFA);
const orgChipBg = Color(0xFF14151F);
const orgTealFill = Color(0xFF16302F);

class OrgInvitation {
  const OrgInvitation({required this.email, required this.role});
  final String email;
  final String role;
}

class OrganizationProfile {
  const OrganizationProfile({
    required this.name,
    required this.email,
    required this.domain,
    required this.teamSize,
    this.logoPath,
    this.invitations = const [],
  });
  final String name;
  final String email;
  final String domain;
  final String teamSize;
  final String? logoPath;
  final List<OrgInvitation> invitations;

  OrganizationProfile copyWith({List<OrgInvitation>? invitations}) =>
      OrganizationProfile(
        name: name,
        email: email,
        domain: domain,
        teamSize: teamSize,
        logoPath: logoPath,
        invitations: invitations ?? this.invitations,
      );
}

String orgSlug(String name) {
  final s = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return s.isEmpty ? 'my-workspace' : s;
}

String orgInitialsFromEmail(String email) {
  final local = email.split('@').first;
  final parts = local.split(RegExp(r'[._\-+]')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final p = parts.first;
    return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
  }
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

const _avatarColors = [
  Color(0xFF8B7DFA),
  Color(0xFF3DDCC4),
  Color(0xFF5A6070),
  Color(0xFFFFB86B),
  Color(0xFFFF7A9A),
];
Color orgAvatarColor(int i) => _avatarColors[i % _avatarColors.length];

class OrgHeader extends StatelessWidget {
  const OrgHeader({super.key, required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: orgMuted),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Create Organization',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFFFD8D3),
            child: Icon(Icons.person_rounded, size: 18, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class OrgStepBar extends StatelessWidget {
  const OrgStepBar({super.key, required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'STEP $step OF 3',
            style: const TextStyle(
              color: orgMuted,
              fontSize: 10.5,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 1; i <= 3; i++) ...[
              if (i > 1) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: i < step
                        ? orgPurpleSoft
                        : i == step
                            ? orgTeal
                            : Colors.white12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class OrgPrimaryButton extends StatelessWidget {
  const OrgPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.arrow_forward_rounded,
    this.colors = const [orgPurple, orgPurpleDeep],
    this.enabled = true,
  });
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final List<Color> colors;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: enabled ? onTap : null,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(colors: colors),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}