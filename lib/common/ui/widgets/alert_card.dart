import 'package:flutter/material.dart';

import '../utils/build_context_ext.dart';

enum AlertType { danger, note }

class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
  });

  final AlertType type;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final (icon, color, containerColor) = switch (type) {
      AlertType.danger => (
        Icons.warning_amber_rounded,
        colorScheme.error,
        colorScheme.errorContainer,
      ),
      AlertType.note => (
        Icons.note,
        colorScheme.primary,
        colorScheme.primaryContainer,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: containerColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24.0),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  subtitle,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
