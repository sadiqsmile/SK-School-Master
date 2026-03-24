import 'package:flutter/material.dart';
import 'package:school_app/features/data_center/screens/excel_import_screen.dart';

class DataCenterScreen extends StatelessWidget {
  const DataCenterScreen({super.key});

  void _handleTap(BuildContext context, String title) {
    if (title == 'Excel Import') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ExcelImportScreen(),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'title': 'Excel Import',
        'subtitle': 'Import from Excel',
        'icon': Icons.upload_file_rounded,
        'colors': [const Color(0xFF10B981), const Color(0xFF059669)],
      },
      {
        'title': 'Excel Export',
        'subtitle': 'Export to Excel',
        'icon': Icons.download_rounded,
        'colors': [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
      },
      {
        'title': 'PDF Export',
        'subtitle': 'Export to PDF',
        'icon': Icons.picture_as_pdf_rounded,
        'colors': [const Color(0xFFEF4444), const Color(0xFFDC2626)],
      },
      {
        'title': 'Google Sheets Sync',
        'subtitle': 'Sync Sheets',
        'icon': Icons.sync_rounded,
        'colors': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Center'),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          int crossAxisCount = 4;
          double childAspectRatio = 2.2;

          if (width < 600) {
            crossAxisCount = 2;
            childAspectRatio = 1.35;
          } else if (width < 900) {
            crossAxisCount = 2;
            childAspectRatio = 1.7;
          } else if (width < 1200) {
            crossAxisCount = 3;
            childAspectRatio = 1.9;
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              final colors = item['colors'] as List<Color>;

              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _handleTap(context, item['title'] as String),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: width < 600 ? 12 : 14,
                      vertical: width < 600 ? 12 : 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: width < 600
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: colors),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  item['icon'] as IconData,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item['title'] as String,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['subtitle'] as String,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: colors),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  item['icon'] as IconData,
                                  color: Colors.white,
                                  size: 21,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] as String,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['subtitle'] as String,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}