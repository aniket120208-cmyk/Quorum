import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/main.dart';
import 'bloc/bloc_common.dart';
import 'bloc/community_list_bloc.dart';
import 'community_config.dart';
import 'community_detail_screen.dart';
import 'data/models.dart';
import 'join_community_screen.dart';
import 'widgets/common_widgets.dart';
import 'widgets/community_colors.dart';
import 'widgets/form_sheets.dart';
import 'widgets/utils.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CommunityListBloc(CommunityConfig.repository)
        ..add(const CommunityListRequested()),
      child: const _CommunityView(),
    );
  }
}

class _CommunityView extends StatefulWidget {
  const _CommunityView();
  @override
  State<_CommunityView> createState() => _CommunityViewState();
}

class _CommunityViewState extends State<_CommunityView> {
  final _search = TextEditingController();
  String _query = '';
  CommunityRole? _filter;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Community> _visible(List<Community> all) {
    final q = _query.trim().toLowerCase();
    return all.where((c) {
      if (_filter != null && c.role != _filter) return false;
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _refresh() {
    final completer = Completer<void>();
    context
        .read<CommunityListBloc>()
        .add(CommunityListRequested(silent: true, completer: completer));
    return completer.future;
  }

  void _create() {
    final bloc = context.read<CommunityListBloc>();
    showAppSheet<void>(
      context,
      (_) => CommunityFormSheet(
        title: 'Create community',
        submitLabel: 'Create community',
        onSubmit: (name, description) {
          final completer = Completer<bool>();
          bloc.add(
            CommunityCreateSubmitted(name, description, completer: completer),
          );
          return completer.future;
        },
      ),
    );
  }

  Future<void> _join() async {
    final bloc = context.read<CommunityListBloc>();
    final joined = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const JoinCommunityScreen()),
    );
    if (joined == true) bloc.add(const CommunityListRequested(silent: true));
  }

  Future<void> _open(Community community) async {
    final bloc = context.read<CommunityListBloc>();
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CommunityDetailScreen(community: community),
      ),
    );
    bloc.add(const CommunityListRequested(silent: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CommunityColors.background,
      body: SafeArea(
        child: BlocConsumer<CommunityListBloc, CommunityListState>(
          listenWhen: (p, c) => p.notice != c.notice && c.notice != null,
          listener: (context, state) => showNotice(context, state.notice!),
          builder: (context, state) {
            if (state.status == LoadStatus.initial ||
                state.status == LoadStatus.loading) {
              return Column(
                children: [
                  _header(),
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }
            if (state.status == LoadStatus.failure) {
              return Column(
                children: [
                  _header(),
                  Expanded(
                    child: ErrorView(
                      message: state.error ?? 'Unable to load communities',
                      onRetry: () => context
                          .read<CommunityListBloc>()
                          .add(const CommunityListRequested()),
                    ),
                  ),
                ],
              );
            }
            final visible = _visible(state.communities);
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  _header(),
                  SizedBox(height: 4,),
                  _banner(),
                  if (state.communities.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: EmptyView(
                        icon: Icons.groups_2_outlined,
                        title: 'No communities yet',
                        subtitle: 'Create your own circle or join one with an invite link.',
                        action: OutlinedButton.icon(
                          onPressed: _join,
                          icon: const Icon(Icons.link_rounded, size: 18),
                          label: const Text('Join with invite'),
                        ),
                      ),
                    )
                  else ...[
                    _filters(),
                    _circlesHeader(state.communities.length),
                    _circlesRow(state.communities),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 4),
                      child: Text(
                        'Your communities',
                        style: TextStyle(
                          color: CommunityColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Text(
                        'Private hubs you own or belong to',
                        style: TextStyle(
                          color: CommunityColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (visible.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No communities match your search',
                            style: TextStyle(color: CommunityColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      for (final c in visible) _communityCard(c),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: CommunityColors.primaryGradient,
            ),
            child: const Icon(Icons.groups_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community',
                  style: TextStyle(
                    color: CommunityColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Explore & connect',
                  style: TextStyle(
                    color: CommunityColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Join with invite link',
            onPressed: _join,
            icon: const Icon(Icons.link_rounded),
            color: AppColors.primary,
          ),
          GradientButton(
            label: 'Create',
            icon: Icons.add_rounded,
            compact: true,
            onPressed: _create,
          ),
        ],
      ),
    );
  }

  Widget _banner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: CommunityColors.bannerGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CommunityColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                const Text(
                  'Build your circle • Start a community',
                  style: TextStyle(
                    color: CommunityColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Host dedicated sessions, collaborate with peers.',
                  style: TextStyle(
                    color: CommunityColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                GradientButton(
                  label: 'Create Community',
                  icon: Icons.add_rounded,
                  compact: true,
                  onPressed: _create,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: CommunityColors.primaryMuted,
            ),
            child: const Icon(
              Icons.groups_2_rounded,
              color: CommunityColors.primarySoft,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    final options = <MapEntry<String, CommunityRole?>>[
      const MapEntry('All', null),
      const MapEntry('Owned', CommunityRole.owner),
      const MapEntry('Admin', CommunityRole.admin),
      const MapEntry('Member', CommunityRole.member),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final option = options[i];
          final selected = _filter == option.value;
          return ChoiceChip(
            label: Text(option.key),
            selected: selected,
            showCheckmark: false,
            selectedColor: CommunityColors.primary,
            backgroundColor: CommunityColors.surface,
            side: const BorderSide(color: CommunityColors.border),
            labelStyle: TextStyle(
              color: selected
                  ? CommunityColors.textPrimary
                  : CommunityColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            onSelected: (_) => setState(() => _filter = option.value),
          );
        },
      ),
    );
  }

  Widget _circlesHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          const Icon(Icons.hub_outlined, color: CommunityColors.accent, size: 20),
          const SizedBox(width: 8),
          const Text(
            'My Circles',
            style: TextStyle(
              color: CommunityColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: CommunityColors.tealMuted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count Active',
              style: const TextStyle(
                color: CommunityColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circlesRow(List<Community> communities) {
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: communities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final c = communities[i];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _open(c),
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  CommunityAvatar(name: c.name, size: 60),
                  const SizedBox(height: 8),
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CommunityColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _communityCard(Community c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: CommunityColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _open(c),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: CommunityColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommunityAvatar(
                  name: c.name,
                  size: 52,
                  gradient: CommunityColors.primaryGradient,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: CommunityColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          RoleBadge(role: c.role),
                        ],
                      ),
                      if (c.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          c.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: CommunityColors.textSecondary,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.groups_2_outlined,
                            size: 15,
                            color: CommunityColors.primarySoft,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            memberLabel(c.memberCount),
                            style: const TextStyle(
                              color: CommunityColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 14,
                            color: CommunityColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Private',
                            style: TextStyle(
                              color: CommunityColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}