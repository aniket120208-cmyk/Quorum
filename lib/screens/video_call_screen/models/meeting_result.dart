class MeetingResult {
  final String code;
  final String title;
  final bool joined;
  final DateTime? joinedAt;
  final int durationSeconds;

  const MeetingResult({
    required this.code,
    required this.title,
    required this.joined,
    required this.joinedAt,
    required this.durationSeconds,
  });

  String get formattedDuration => formatMeetingDuration(durationSeconds);
}

String formatMeetingDuration(int totalSeconds) {
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
  return '${m}m ${s.toString().padLeft(2, '0')}s';
}