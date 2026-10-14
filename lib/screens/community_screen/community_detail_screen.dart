import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/community_detail_bloc.dart';
import 'bloc/feed_bloc.dart';
import 'bloc/members_bloc.dart';
import 'community_config.dart';
import 'data/models.dart';
import 'tabs/about_tab.dart';
import 'tabs/feed_tab.dart';
import 'tabs/members_tab.dart';
import 'widgets/common_widgets.dart';
import 'widgets/community_colors.dart';
import 'widgets/form_sheets.dart';
import 'widgets/invite_sheet.dart';
import 'widgets/utils.dart';

class CommunityDetailScreen extends StatelessWidget {
  const CommunityDetailScreen({super.key, required this.community});
  final Community community;
  @override
  Widget build(BuildContext context) {
    final repo = CommunityConfig.repository;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CommunityDetailBloc(repo, community.id)
            ..add(const DetailRequested()),
        ),
        BlocProvider(
          create: (_) => FeedBloc(repo, community.id)..add(const FeedRequested()),
        ),
        BlocProvider(
          create: (_) =>
              MembersBloc(repo, community.id)..add(const MembersRequested()),
        ),
      ],
      child: _DetailView(community: community),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.community});
  final Community community;
  Future<void> _onMenu(
    BuildContext context,
    String action,
    CommunityDetail? detail,
  ) async {
    final bloc = context.read<CommunityDetailBloc>();
    switch (action) {
      case 'invite':
        await showAppSheet<void>(
          context,
          (_) => BlocProvider.value(value: bloc, child: const InviteSheet()),
        );
        break;
      case 'edit':
        await showAppSheet<void>(
          context,
          (_) => CommunityFormSheet(
            title: 'Edit community',
            submitLabel: 'Save changes',
            initialName: detail?.name ?? community.name,
            initialDescription: detail?.description ?? community.description,
            onSubmit: (name, description) {
              final completer = Completer<bool>();
              bloc.add(
                DetailUpdateSubmitted(name, description, completer: completer),
              );
              return completer.future;
            },
          ),
        );
        break;
      case 'leave':
        final leave = await confirmAction(
          context,
          title: 'Leave community?',
          message: 'You will need a new invite link to join again.',
          confirmLabel: 'Leave',
        );
        if (leave) bloc.add(const DetailLeaveRequested());
        break;
      case 'delete':
        final delete = await confirmAction(
          context,
          title: 'Delete community?',
          message:
              'All posts, comments and memberships will be removed permanently.',
          confirmLabel: 'Delete',
        );
        if (delete) bloc.add(const DetailDeleteRequested());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CommunityDetailBloc, CommunityDetailState>(
      listenWhen: (p, c) => p.notice != c.notice || p.exited != c.exited,
      listener: (context, state) {
        if (state.notice != null) showNotice(context, state.notice!);
        if (state.exited) Navigator.of(context).pop(true);
      },
      builder: (context, state) {
        final detail = state.detail;
        final role = detail?.currentUserRole ?? community.role;
        final name = detail?.name ?? community.name;
        final members = detail?.memberCount ?? community.memberCount;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: CommunityColors.background,
            appBar: AppBar(
              backgroundColor: CommunityColors.background,
              elevation: 0,
              titleSpacing: 0,
              title: Row(
                children: [
                  CommunityAvatar(name: name, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          memberLabel(members),
                          style: const TextStyle(
                            fontSize: 11,
                            color: CommunityColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                if (state.busy)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  PopupMenuButton<String>(
                    color: CommunityColors.surfaceAlt,
                    onSelected: (v) => _onMenu(context, v, detail),
                    itemBuilder: (_) => [
                      if (role.canModerate)
                        const PopupMenuItem(
                          value: 'invite',
                          child: Text('Invite people'),
                        ),
                      if (role.canModerate)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit details'),
                        ),
                      const PopupMenuItem(
                        value: 'leave',
                        child: Text('Leave community'),
                      ),
                      if (role == CommunityRole.owner)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete community',
                            style: TextStyle(color: CommunityColors.danger),
                          ),
                        ),
                    ],
                  ),
              ],
              bottom: const TabBar(
                indicatorColor: CommunityColors.primary,
                labelColor: CommunityColors.textPrimary,
                unselectedLabelColor: CommunityColors.textSecondary,
                tabs: [
                  Tab(text: 'Feed'),
                  Tab(text: 'Members'),
                  Tab(text: 'About'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                FeedTab(role: role),
                MembersTab(role: role),
                AboutTab(community: community),
              ],
            ),
          ),
        );
      },
    );
  }
}