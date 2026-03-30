import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/features/school_admin/fees/screens/add_fee_screen.dart';

class FeeListScreen extends ConsumerWidget {
  final String studentId;

  const FeeListScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolAsync = ref.watch(currentSchoolProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Student Fees')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddFeeScreen(studentId: studentId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: schoolAsync.when(
        data: (school) {
          final stream = FirebaseFirestore.instance
              .collection('schools')
              .doc(school.id)
              .collection('students')
              .doc(studentId)
              .collection('fees')
              .orderBy('createdAt', descending: true)
              .snapshots();

          return StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(child: Text('No fees added'));
              }

              double total = 0;
              double paid = 0;
              double pending = 0;

              for (var doc in docs) {
                final amount = (doc['amount'] ?? 0).toDouble();
                final status = doc['status'];

                total += amount;

                if (status == 'paid') {
                  paid += amount;
                } else {
                  pending += amount;
                }
              }

              return Column(
                children: [
                  // 💰 UPGRADED HEADER
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.blue.shade50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Total'),
                            Text('₹$total', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Paid'),
                            Text('₹$paid', style: const TextStyle(color: Colors.green)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Pending'),
                            Text('₹$pending', style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final data = docs[i];
                        final amount = data['amount'];
                        final desc = data['description'] ?? '';
                        final status = data['status'];

                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            title: Text('₹$amount'),
                            subtitle: Text(desc),
                            trailing: TextButton(
                              child: Text(
                                status == 'paid' ? 'Paid' : 'Mark Paid',
                                style: TextStyle(
                                  color: status == 'paid'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              onPressed: () {
                                if (status != 'paid') {
                                  _markAsPaid(context, ref, docs[i].id);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _markAsPaid(
      BuildContext context,
      WidgetRef ref,
      String feeId,
      ) async {
    final school = await ref.read(currentSchoolProvider.future);

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(school.id)
        .collection('students')
        .doc(studentId)
        .collection('fees')
        .doc(feeId)
        .update({
      'status': 'paid',
    });
  }
}
