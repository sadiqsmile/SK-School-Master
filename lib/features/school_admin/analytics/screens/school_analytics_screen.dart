import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/features/school_admin/analytics/providers/student_risk_providers.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SchoolAnalyticsScreen extends ConsumerWidget {
  const SchoolAnalyticsScreen({super.key});

  int _readInt(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  /// ✅ PDF FUNCTION (FIXED POSITION)
  Future<void> generatePdfReport({
    required double percent,
    required int present,
    required int absent,
    required int holiday,
    required String month,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Attendance Report",
                  style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 20),
              pw.Text("Month: $month"),
              pw.Text("Attendance: ${percent.toStringAsFixed(1)}%"),
              pw.Text("Present: $present"),
              pw.Text("Absent: $absent"),
              pw.Text("Holidays: $holiday"),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(riskSummaryProvider);

    return AdminLayout(
      title: 'School Analytics',
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (doc) {
          final data = doc.data() as Map<String, dynamic>;

          final present = _readInt(data, 'present');
          final absent = _readInt(data, 'absent');
          final holiday = _readInt(data, 'holiday');

          final total = present + absent;
          final percent = total == 0 ? 0 : (present / total) * 100;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              /// 🔥 HEADER CARD
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      "${percent.toStringAsFixed(1)}%",
                      style: const TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text("Overall Attendance",
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 🔥 STATS
              _card("Present", present.toString(), Colors.green),
              _card("Absent", absent.toString(), Colors.red),
              _card("Holiday", holiday.toString(), Colors.orange),

              const SizedBox(height: 20),

              /// 🔥 PDF BUTTON
              ElevatedButton.icon(
                onPressed: () {
                  generatePdfReport(
                    percent: percent.toDouble(),
                    present: present,
                    absent: absent,
                    holiday: holiday,
                    month: "Current Month",
                  );
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Download Report"),
              ),

              const SizedBox(height: 20),

              /// 🔥 NAVIGATION (OPTIONAL)
              ListTile(
                title: const Text("View Risk Students"),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () =>
                    context.push('/school-admin/analytics/highRisk'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 🔥 CARD UI
  Widget _card(String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}