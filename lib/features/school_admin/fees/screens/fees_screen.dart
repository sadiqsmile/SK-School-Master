// features/school_admin/fees/screens/fees_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/providers/school_admin_provider.dart';

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const lightBg = Color(0xFFF1FCFB);
    const accent = Color(0xFF14B8A6);
    final feesAsync = ref.watch(feesProvider);

    return AdminLayout(
      title: 'Fees',
      body: _FeesBody(lightBg: lightBg, accent: accent, feesAsync: feesAsync),
    );
  }
}

class _FeesBody extends StatelessWidget {
  const _FeesBody({
    required this.lightBg,
    required this.accent,
    required this.feesAsync,
  });

  final Color lightBg;
  final Color accent;
  final AsyncValue feesAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: lightBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: accent.withOpacity(0.16),
                    child: Icon(Icons.payments_rounded, color: accent),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Fees overview with pending dues and collection insights.',
                      style: TextStyle(height: 1.4, color: Color(0xFF374151)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            feesAsync.when(
              data: (snapshot) {
                final fees = snapshot.docs;
                final totalCount = fees.length;
                final pendingCount = fees
                    .where((doc) => doc.data()['status'] == 'pending')
                    .length;
                final recentFees = fees.take(3).toList();

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            'Total Records',
                            '$totalCount',
                            Icons.account_balance_wallet_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            'Pending',
                            '$pendingCount',
                            Icons.hourglass_top_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recent Payment Events',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (recentFees.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'No fee records yet.',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            )
                          else
                            ...recentFees.map((doc) {
                              final data = doc.data();
                              final title =
                                  data['title'] ?? data['type'] ?? 'Fee Record';
                              final info =
                                  data['description'] ??
                                  data['info'] ??
                                  'Payment record';
                              return _listRow(
                                title,
                                info,
                                Icons.check_circle_rounded,
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
                ),
              ),
              error: (e, _) => Center(child: Text('Error loading fees: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _listRow(String name, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
