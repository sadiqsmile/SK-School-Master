import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SchoolBrandBanner extends StatelessWidget {
  const SchoolBrandBanner({
    super.key,
    required this.schoolName,
    required this.subtitle,
    required this.primary,
    required this.secondary,
    this.logoUrl,
  });

  final String schoolName;
  final String subtitle;
  final Color primary;
  final Color secondary;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final url = (logoUrl ?? '').trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, secondary],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(23),
            ),
            clipBehavior: Clip.antiAlias,
            child: url.isEmpty
                ? const Icon(Icons.school_rounded, color: Color(0xFF0F172A))
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      if (kDebugMode) {
                        debugPrint('LOGO LOAD ERROR: $error');
                      }
                      return const Icon(Icons.image_not_supported_rounded);
                    },
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schoolName.trim().isEmpty ? 'School' : schoolName.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.trim().isEmpty ? 'Welcome' : subtitle.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
