import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quorum/utils/validators.dart';
import 'modules_launch_screen.dart';
import 'org_shared.dart';

const _roles = ['Head', 'Member', 'Guest'];

class InviteTeamScreen extends StatefulWidget {
  const InviteTeamScreen({super.key, required this.profile});
  final OrganizationProfile profile;
  @override
  State<InviteTeamScreen> createState() => _InviteTeamScreenState();
}

class _InviteTeamScreenState extends State<InviteTeamScreen> {
  final _emailCtrl = TextEditingController();
  final _invites = <OrgInvitation>[];
  String _role = 'Member';
  String? _error;

  final _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  String get _link => 'https://app.quorum.io/join/${orgSlug(widget.profile.name)}';

  bool get _canContinue => _invites.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(() {
      if (_error != null) setState(() => _error = null);
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _link));
    _toast('Invite link copied');
  }

  void _add() {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    if (_invites.any((i) => i.email == email)) {
      setState(() => _error = 'Already added');
      return;
    }
    setState(() {
      _invites.add(OrgInvitation(email: email, role: _role));
      _emailCtrl.clear();
      _error = null;
    });
  }

  void _remove(OrgInvitation inv) => setState(() => _invites.remove(inv));
  void _cycleRole(int index) {
    final inv = _invites[index];
    final next = _roles[(_roles.indexOf(inv.role) + 1) % _roles.length];
    setState(() => _invites[index] = OrgInvitation(email: inv.email, role: next));
  }

  Future<void> _next({required bool skip}) async {
    if (!skip && !_canContinue) return;
    FocusScope.of(context).unfocus();
    final profile = widget.profile.copyWith(invitations: skip ? const [] : List.of(_invites));
    final result = await Navigator.of(context).push<OrganizationProfile>(
      MaterialPageRoute(builder: (_) => ModulesLaunchScreen(profile: profile)),
    );
    if (result != null && mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: orgBg,
      body: SafeArea(
        child: Column(
          children: [
            OrgHeader(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(context).unfocus(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    const OrgStepBar(step: 2),
                    const SizedBox(height: 18),
                    const Text(
                      'Invite Your Team',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Bring teammates into your workspace now, or do it later.',
                      style:
                          TextStyle(color: orgMuted, fontSize: 12.5, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    _linkCard(),
                    const SizedBox(height: 22),
                    _label('Invite by Email'),
                    const SizedBox(height: 8),
                    _emailField(),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(_error!,
                            style: const TextStyle(
                                color: Color(0xFFFF7A8A), fontSize: 11.5)),
                      ),
                    const SizedBox(height: 10),
                    _roleAndAddRow(),
                    if (_invites.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _stagedHeader(),
                      const SizedBox(height: 10),
                      for (var i = 0; i < _invites.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _inviteTile(i),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: orgBg,
        border: Border(top: BorderSide(color: orgCardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IgnorePointer(
            ignoring: !_canContinue,
            child: Opacity(
              opacity: _canContinue ? 1.0 : 0.4,
              child: OrgPrimaryButton(
                label: 'Continue to Modules',
                onTap: () => _next(skip: false),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: () => _next(skip: true),
              child: const Text('Skip for now, invite later',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mark_email_read_outlined,
                  size: 13, color: orgTeal),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Invitations will be sent automatically when workspace is launched',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: orgMuted, fontSize: 10.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _linkCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF3A2D6B), Color(0xFF1E2A4A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.link_rounded, size: 16, color: orgTeal),
              SizedBox(width: 8),
              Text('Direct Invite Link',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            decoration: BoxDecoration(
              color: orgBg.withOpacity(0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: orgCardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _link.replaceFirst('https://', ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _copyLink,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Copy',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.schedule_rounded, size: 13, color: orgMuted),
              SizedBox(width: 6),
              Expanded(
                child: Text('Anyone with link can join as Member • Expires in 7 days',
                    style: TextStyle(color: orgMuted, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c),
      );

  Widget _emailField() {
    return TextField(
      controller: _emailCtrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')),
      ],
      onSubmitted: (_) => _add(),
      decoration: InputDecoration(
        hintText: 'colleague@company.com',
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18, color: orgMuted),
        filled: true,
        fillColor: orgChipBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: _border(_error != null ? const Color(0xFFFF7A8A) : orgCardBorder),
        enabledBorder: _border(_error != null ? const Color(0xFFFF7A8A) : orgCardBorder),
        focusedBorder: _border(orgTeal),
      ),
    );
  }

  Widget _roleAndAddRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: orgChipBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: orgCardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _role,
                isExpanded: true,
                dropdownColor: orgChipBg,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: orgMuted),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: [
                  for (final r in _roles)
                    DropdownMenuItem(value: r, child: Text('Role: $r')),
                ],
                onChanged: (v) => setState(() => _role = v ?? _role),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _add,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: orgTealFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: orgTeal),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add_alt_1_rounded, size: 16, color: orgTeal),
                SizedBox(width: 6),
                Text('Add',
                    style: TextStyle(
                        color: orgTeal,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stagedHeader() {
    return Row(
      children: [
        _label('Staged Invitations'),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('${_invites.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => setState(_invites.clear),
          child: const Text('Clear all',
              style: TextStyle(color: orgMuted, fontSize: 11.5)),
        ),
      ],
    );
  }

  Widget _inviteTile(int i) {
    final inv = _invites[i];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: orgChipBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: orgCardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: orgAvatarColor(i),
            child: Text(orgInitialsFromEmail(inv.email),
                style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(inv.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _cycleRole(i),
            child: _roleBadge(inv.role),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => _remove(inv),
            icon: const Icon(Icons.close_rounded, size: 18, color: orgMuted),
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(String role) {
    final isMember = role == 'Member';
    final isAdmin = role == 'Admin';
    final fg = isMember
        ? orgTeal
        : isAdmin
            ? orgPurpleSoft
            : Colors.white70;
    final bg = isMember
        ? orgTealFill
        : isAdmin
            ? orgPurpleDeep.withOpacity(0.6)
            : Colors.white12;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(role,
          style:
              TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}