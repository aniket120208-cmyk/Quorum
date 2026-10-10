import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quorum/main.dart';
import 'package:quorum/models/chat_models.dart';
import 'package:quorum/repositories/chat_repository.dart';
import 'widgets/chat_widgets.dart';

class ChatSearchScreen extends StatefulWidget {
  const ChatSearchScreen({
    super.key,
    required this.conversationId,
    required this.title,
    required this.repo,
  });

  final String conversationId;
  final String title;
  final ChatRepository repo;
  @override
  State<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends State<ChatSearchScreen> {
  final _queryCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;
  String _query = '';
  List<ChatMessage> _results = const [];
  String? _cursor;
  bool _hasMore = false;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.extentAfter < 200) _loadMore();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.isEmpty) {
      setState(() {
        _query = '';
        _results = const [];
        _cursor = null;
        _hasMore = false;
        _loading = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() {
      _query = q;
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.repo.searchMessages(widget.conversationId, q);
      if (!mounted || _query != q) return;
      setState(() {
        _results = page.messages;
        _cursor = page.nextCursor;
        _hasMore = page.hasNextPage;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || _query != q) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    final cursor = _cursor;
    if (_loadingMore || !_hasMore || cursor == null || _query.isEmpty) return;
    final q = _query;
    setState(() => _loadingMore = true);
    try {
      final page = await widget.repo.searchMessages(
        widget.conversationId,
        q,
        cursor: cursor,
      );
      if (!mounted || _query != q) return;
      setState(() {
        _results = [..._results, ...page.messages];
        _cursor = page.nextCursor;
        _hasMore = page.hasNextPage;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _queryCtrl,
          autofocus: true,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search in ${widget.title}',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    if (_query.isEmpty) {
      return const Center(
        child: Text(
          'Type to search messages',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'No messages found',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      controller: _scrollCtrl,
      itemCount: _results.length + (_loadingMore ? 1 : 0),
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.surfaceBorder),
      itemBuilder: (context, i) {
        if (i == _results.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final m = _results[i];
        return ListTile(
          title: Text(
            m.previewText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          subtitle: Text(
            '${m.senderName.isEmpty ? '' : '${m.senderName} · '}'
            '${formatDayLabel(m.createdAt)}, ${formatClock(m.createdAt)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }
}