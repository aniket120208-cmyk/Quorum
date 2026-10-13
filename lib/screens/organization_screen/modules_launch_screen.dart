import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'org_shared.dart';

class ModulesLaunchScreen extends StatefulWidget {
  const ModulesLaunchScreen({super.key, required this.profile});
  final OrganizationProfile profile;
  @override
  State<ModulesLaunchScreen> createState() => _ModulesLaunchScreenState();
}

class _ModulesLaunchScreenState extends State<ModulesLaunchScreen> {
  String get _initials {
    final words = widget.profile.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'SI';
    if (words.length == 1) {
      final w = words.first;
      return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  String get _plan {
    const captions = {
      '1-10': 'Seed',
      '11-50': 'Growth',
      '51-200': 'Scale',
      '200+': 'Org',
    };
    final c = captions[widget.profile.teamSize];
    return c == null ? widget.profile.teamSize : '${widget.profile.teamSize} ($c)';
  }

  String get _workspaceUrl => 'https://app.quorum.io/join/${orgSlug(widget.profile.name)}';

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _workspaceUrl));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Workspace link copied')));
  }

  @override
  Widget build(BuildContext context) {
    final invites = widget.profile.invitations;
    return Scaffold(
      backgroundColor: orgBg,
      body: SafeArea(
        child: Column(
          children: [
            OrgHeader(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  const OrgStepBar(step: 3),
                  const SizedBox(height: 18),
                  _headerRow(),
                  const SizedBox(height: 6),
                  const Text(
                    'Review your final details before creating the workspace.',
                    style: TextStyle(
                      color: orgMuted,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _overviewCard(context),
                  const SizedBox(height: 14),
                  _linkCard(context),
                  const SizedBox(height: 20),
                  _sectionHeader(
                    title: 'Team Invitations',
                    badge: '${invites.length} Staged',
                  ),
                  const SizedBox(height: 10),
                  if (invites.isEmpty)
                    _emptyInvitesCard()
                  else
                    _invitesRoster(invites),
                ],
              ),
            ),
            _bottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _headerRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Text(
            'Confirm &\nLaunch',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: orgTealFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: orgTeal.withOpacity(0.5)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 13, color: orgTeal),
              SizedBox(width: 5),
              Text(
                'Final Step',
                style: TextStyle(
                  color: orgTeal,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _overviewCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF281F54), Color(0xFF141A33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: orgCardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [orgPurple, orgPurpleDeep],
                  ),
                ),
                child: widget.profile.logoPath != null
                    ? Image.file(File(widget.profile.logoPath!), fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.profile.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: orgMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).maybePop();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _dataTile(
                  icon: Icons.pie_chart_outline_rounded,
                  label: 'Team Size',
                  value: _plan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dataTile(
                  icon: Icons.domain_rounded,
                  label: 'Industry',
                  value: widget.profile.domain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dataTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: orgBg.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: orgCardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: orgTeal),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: orgMuted, fontSize: 10)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: orgChipBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: orgCardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, size: 18, color: orgTeal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Workspace URL',
                  style: TextStyle(color: orgMuted, fontSize: 10.5),
                ),
                const SizedBox(height: 2),
                Text(
                  _workspaceUrl.replaceFirst('https://', ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => _copyLink(context),
            icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({required String title, required String badge}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          badge,
          style: const TextStyle(
            color: orgTeal,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _emptyInvitesCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: orgChipBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: orgCardBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.person_add_disabled_outlined, size: 20, color: orgMuted),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No invitations queued yet. You can invite teammates directly from workspace settings after setup.',
              style: TextStyle(color: orgMuted, fontSize: 11.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _invitesRoster(List<OrgInvitation> invites) {
    return Container(
      decoration: BoxDecoration(
        color: orgChipBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: orgCardBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < invites.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: Color(0x14FFFFFF), indent: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: orgAvatarColor(i),
                    child: Text(
                      orgInitialsFromEmail(invites[i].email),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      invites[i].email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: invites[i].role == 'Head'
                          ? orgPurpleDeep.withOpacity(0.6)
                          : orgTealFill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      invites[i].role,
                      style: TextStyle(
                        color: invites[i].role == 'Head'
                            ? orgPurpleSoft
                            : orgTeal,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: orgBg,
        border: Border(top: BorderSide(color: orgCardBorder)),
      ),
      child: OrgPrimaryButton(
        label: 'Create Workspace',
        icon: Icons.arrow_forward_rounded,
        colors: const [orgPurple, orgPurpleDeep],
        onTap: () => Navigator.of(context).pop(widget.profile),
      ),
    );
  }
}