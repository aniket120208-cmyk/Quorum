import 'package:flutter/material.dart';
import 'package:quorum/main.dart';

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.name,
    this.isGroup = false,
    this.radius = 24,
  });

  final String name;
  final bool isGroup;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.25),
      child: isGroup ? Icon(Icons.groups, color: AppColors.primaryLight, size: radius) : Text(
              initial,
              style: TextStyle(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w600,
                fontSize: radius * 0.8,
              ),
            ),
    );
  }
}

String formatClock(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
}

bool sameDay(DateTime a, DateTime b) =>  a.year == b.year && a.month == b.month && a.day == b.day;

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatDayLabel(DateTime t) {
  final now = DateTime.now();
  if (sameDay(t, now)) return 'Today';
  if (sameDay(t, now.subtract(const Duration(days: 1)))) return 'Yesterday';
  return '${t.day} ${_months[t.month - 1]} ${t.year}';
}

String formatListTime(DateTime t) {
  if (t.millisecondsSinceEpoch == 0) return '';
  final now = DateTime.now();
  if (sameDay(t, now)) return formatClock(t);
  if (sameDay(t, now.subtract(const Duration(days: 1)))) return 'Yesterday';
  return '${t.day} ${_months[t.month - 1]}';
}

String formatLastSeen(DateTime t) {
  final now = DateTime.now();
  if (sameDay(t, now)) return 'today at ${formatClock(t)}';
  if (sameDay(t, now.subtract(const Duration(days: 1)))) {
    return 'yesterday at ${formatClock(t)}';
  }
  return '${t.day} ${_months[t.month - 1]} ${t.year}';
}

void showErrorSnack(BuildContext context, Object error) {
  final text = error.toString().replaceFirst('ApiException: ', '');
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}