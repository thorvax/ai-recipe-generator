/// "just now", "5m ago", "3h ago", "2d ago", or a date for older items.
String timeAgo(DateTime? time) {
  if (time == null) return 'just now'; // server timestamp not set yet
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${time.day}/${time.month}/${time.year}';
}
