import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'invite_team_screen.dart';
import 'org_shared.dart';
export 'org_shared.dart' show OrganizationProfile, OrgInvitation;

const _bg = Color(0xFF0B0C14);
const _cardBorder = Color(0x1AFFFFFF);
const _teal = Color(0xFF3DDCC4);
const _muted = Color(0xFF9EA3AE);
const _purple = Color(0xFF6C4BE0);
const _purpleDeep = Color(0xFF3B2A93);
const _purpleSoft = Color(0xFF8B7DFA);
const _chipBg = Color(0xFF14151F);
const _tealFill = Color(0xFF16302F);

class _Domain {
  const _Domain(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _TeamSize {
  const _TeamSize(this.range, this.caption);
  final String range;
  final String caption;
}

const _domains = [
  _Domain('Design & Creative', Icons.palette_outlined),
  _Domain('Engineering & Tech', Icons.laptop_mac_rounded),
  _Domain('Marketing & Sales', Icons.campaign_outlined),
  _Domain('Agency & Studio', Icons.layers_outlined),
  _Domain('Product & SaaS', Icons.account_tree_outlined),
  _Domain('Finance & Fintech', Icons.account_balance_wallet_outlined),
  _Domain('Education & EdTech', Icons.school_outlined),
  _Domain('Healthcare & Health', Icons.health_and_safety_outlined),
];

const _teamSizes = [
  _TeamSize('1-10', 'Seed'),
  _TeamSize('11-50', 'Growth'),
  _TeamSize('51-200', 'Scale'),
  _TeamSize('200+', 'Org'),
];

class CreateOrganizationScreen extends StatefulWidget {
  const CreateOrganizationScreen({super.key, this.onContinue});
  final ValueChanged<OrganizationProfile>? onContinue;
  @override
  State<CreateOrganizationScreen> createState() =>
      _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState extends State<CreateOrganizationScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _customCtrl = TextEditingController();
  final _picker = ImagePicker();
  String? _domain;
  bool _customDomain = false;
  int _sizeIndex = 1;
  File? _logo;

  static const int _maxNameLength = 30;
  final _nameRegex = RegExp(r'^[a-zA-Z\s]+$');
  final _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(() => setState(() {}));
    _emailCtrl.addListener(() => setState(() {}));
    _customCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  String get _initials {
    final words = _nameCtrl.text
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

  String? get _resolvedDomain {
    if (_customDomain) {
      final v = _customCtrl.text.trim();
      return v.isEmpty ? null : v;
    }
    return _domain;
  }

  bool get _isNameValid =>
      _nameCtrl.text.trim().isNotEmpty &&
      _nameCtrl.text.length <= _maxNameLength &&
      _nameRegex.hasMatch(_nameCtrl.text.trim());

  bool get _isEmailValid => _emailRegex.hasMatch(_emailCtrl.text.trim());

  bool get _valid =>
      _isNameValid &&
      _isEmailValid &&
      _resolvedDomain != null;

  Future<void> _pickLogo() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file != null && mounted) setState(() => _logo = File(file.path));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Could not open gallery')));
    }
  }

  Future<void> _continue() async {
    if (!_valid) return;
    FocusScope.of(context).unfocus();
    final profile = OrganizationProfile(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      domain: _resolvedDomain!,
      teamSize: _teamSizes[_sizeIndex].range,
      logoPath: _logo?.path,
    );
    final result = await Navigator.of(context).push<OrganizationProfile>(
      MaterialPageRoute(builder: (_) => InviteTeamScreen(profile: profile)),
    );
    if (result == null || !mounted) return;
    if (widget.onContinue != null) {
      widget.onContinue!(result);
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(context).unfocus(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    _stepBar(),
                    const SizedBox(height: 18),
                    _titleRow(),
                    const SizedBox(height: 6),
                    const Text(
                      'Establish your core workspace and configure team permissions.',
                      style: TextStyle(color: _muted, fontSize: 12.5, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    _logoCard(),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        _label('Organization Name', required: true),
                        const Spacer(),
                        Text(
                          '${_nameCtrl.text.length}/$_maxNameLength',
                          style: TextStyle(
                            color: _nameCtrl.text.length == _maxNameLength
                                ? _teal
                                : _muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _nameField(),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        _label('Organization Email', required: true),
                        const Spacer(),
                        if (_emailCtrl.text.isNotEmpty && !_isEmailValid)
                          Text(
                            'Invalid email format',
                            style: TextStyle(
                              color: Colors.redAccent.shade100,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _emailField(),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        _label('Industry Domain', required: true),
                        const Spacer(),
                        const Text('Select 1',
                            style: TextStyle(color: _muted, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _domainGrid(),
                    const SizedBox(height: 8),
                    _otherChip(),
                    if (_customDomain) ...[
                      const SizedBox(height: 10),
                      _customField(),
                    ],
                    const SizedBox(height: 22),
                    _label('Team Size', required: true),
                    const SizedBox(height: 10),
                    _sizeRow(),
                    const SizedBox(height: 26),
                    _continueButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: _muted),
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

  Widget _stepBar() {
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('STEP 1 OF 3',
              style: TextStyle(
                  color: _muted,
                  fontSize: 10.5,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: i == 0 ? _teal : Colors.white12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _titleRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Text(
            'Organization Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Icon(Icons.bolt_rounded, size: 14, color: _teal),
        const SizedBox(width: 2),
        const Text('Quick Setup',
            style: TextStyle(
                color: _teal, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _logoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF3A2D6B), Color(0xFF1E2A4A)],
        ),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 74,
                height: 74,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_purple, _purpleDeep],
                  ),
                ),
                child: _logo != null
                    ? Image.file(_logo!, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
              ),
              Positioned(
                right: -6,
                bottom: -6,
                child: GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _teal,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF3A2D6B), width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 13, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text.rich(
                  TextSpan(
                    text: 'Add Organization Logo',
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Upload a custom emblem or icon for your team',
                  style: TextStyle(color: _muted, fontSize: 11.5, height: 1.35),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _pickLogo,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.file_upload_outlined,
                                size: 14, color: Colors.white70),
                            SizedBox(width: 6),
                            Text('Upload',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: _logo == null
                          ? null
                          : () => setState(() => _logo = null),
                      child: Text(
                        'Remove',
                        style: TextStyle(
                          color: _logo == null ? Colors.white30 : Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Text.rich(
      TextSpan(
        text: text,
        children: required
            ? const [TextSpan(text: ' *', style: TextStyle(color: _teal))]
            : null,
      ),
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _nameField() {
    final hasText = _nameCtrl.text.isNotEmpty;
    final isInvalid = hasText && !_isNameValid;
    return TextField(
      controller: _nameCtrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      maxLength: _maxNameLength,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
      ],
      decoration: InputDecoration(
        counterText: '',
        hintText: 'e.g. Software Incubator',
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon:
            const Icon(Icons.business_rounded, size: 18, color: _muted),
        suffixIcon: hasText
            ? IconButton(
                icon: const Icon(Icons.cancel_outlined,
                    size: 18, color: Colors.white30),
                onPressed: _nameCtrl.clear,
              )
            : null,
        filled: true,
        fillColor: _chipBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: _border(isInvalid ? Colors.redAccent : _cardBorder),
        enabledBorder: _border(isInvalid ? Colors.redAccent.withOpacity(0.6) : _cardBorder),
        focusedBorder: _border(isInvalid ? Colors.redAccent : _teal),
      ),
    );
  }

  Widget _emailField() {
    final hasText = _emailCtrl.text.isNotEmpty;
    final isInvalid = hasText && !_isEmailValid;

    return TextField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      maxLength: 80,
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')),
      ],
      decoration: InputDecoration(
        counterText: '',
        hintText: 'e.g. contact@domain.com',
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18, color: _muted),
        suffixIcon: hasText
            ? IconButton(
                icon: const Icon(Icons.cancel_outlined,
                    size: 18, color: Colors.white30),
                onPressed: _emailCtrl.clear,
              )
            : null,
        filled: true,
        fillColor: _chipBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: _border(isInvalid ? Colors.redAccent : _cardBorder),
        enabledBorder: _border(isInvalid ? Colors.redAccent.withOpacity(0.6) : _cardBorder),
        focusedBorder: _border(isInvalid ? Colors.redAccent : _teal),
      ),
    );
  }

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c),
      );

  Widget _domainGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in _domains)
              SizedBox(
                width: w,
                child: _chip(
                  label: d.label,
                  icon: d.icon,
                  selected: !_customDomain && _domain == d.label,
                  onTap: () => setState(() {
                    _customDomain = false;
                    _domain = d.label;
                  }),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _otherChip() {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => setState(() {
        _customDomain = !_customDomain;
        if (_customDomain) _domain = null;
      }),
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: _customDomain ? _tealFill : Colors.transparent,
          border: Border.all(
            color: _customDomain ? _teal : Colors.white24,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 16, color: _teal),
            SizedBox(width: 6),
            Text('Other / Custom Domain',
                style: TextStyle(
                    color: _teal, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _customField() {
    return TextField(
      controller: _customCtrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      textCapitalization: TextCapitalization.words,
      maxLength: 40,
      decoration: InputDecoration(
        counterText: '',
        hintText: 'Enter your industry domain',
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: _chipBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: _border(_cardBorder),
        enabledBorder: _border(_cardBorder),
        focusedBorder: _border(_teal),
      ),
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: selected
              ? const LinearGradient(colors: [_purple, _purpleDeep])
              : null,
          color: selected ? null : _chipBg,
          border: Border.all(color: selected ? _purpleSoft : _cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: selected ? Colors.white : _muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sizeRow() {
    return Row(
      children: [
        for (var i = 0; i < _teamSizes.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _sizeIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 78,
                decoration: BoxDecoration(
                  color: _sizeIndex == i ? _tealFill : _chipBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _sizeIndex == i ? _teal : _cardBorder,
                    width: _sizeIndex == i ? 1.4 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _teamSizes[i].range,
                      style: TextStyle(
                        color: _sizeIndex == i ? _teal : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _teamSizes[i].caption,
                      style: const TextStyle(color: _muted, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ],
        ],
    );
  }

  Widget _continueButton() {
    return Opacity(
      opacity: _valid ? 1 : 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: _valid ? _continue : null,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(colors: [_purple, _purpleDeep]),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue to Team Setup',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}