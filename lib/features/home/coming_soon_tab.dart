import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state.dart';

/// TEMPORARY placeholder for tabs we haven't built yet.
class ComingSoonTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const ComingSoonTab({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: EmptyState(icon: icon, title: title, message: message),
    );
  }
}
