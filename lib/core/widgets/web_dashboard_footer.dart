// core/widgets/web_dashboard_footer.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WebDashboardFooter extends StatelessWidget {
  const WebDashboardFooter({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: Text(
          'Copyright © 2026 SK School Master. All rights reserved.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
