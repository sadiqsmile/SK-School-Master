import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/fee_service.dart';

class FeeManagementScreen extends StatefulWidget {
  final String schoolId;

  const FeeManagementScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<FeeManagementScreen> createState() => _FeeManagementScreenState();
}

class _FeeManagementScreenState extends State<FeeManagementScreen> {
  final FeeService _service = const FeeService();

  // ── Add fee bottom sheet ──────────────────────────────────────────────────
  void _showAddFeeSheet() {
    final feeTypeController = TextEditingController();
    final amountController = TextEditingController();
    final paidController = TextEditingController();
    final dueDateController = TextEditingController();
    QueryDocumentSnapshot? selectedStudent;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        height: 5,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Assign Fee",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff111827),
                      ),
                    ),
                    const SizedBox(height: 28),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('schools')
                          .doc(widget.schoolId)
                          .collection('students')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final docs = snapshot.data!.docs;
                        return DropdownButtonFormField<QueryDocumentSnapshot>(
                          value: selectedStudent,
                          decoration: _inputDecoration("Select Student"),
                          items: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: doc,
                              child: Text(
                                  "${data['name']} \u2022 ${data['className']}"),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setSheetState(() => selectedStudent = v);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: feeTypeController,
                      decoration: _inputDecoration("Fee Type"),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Total Amount"),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: paidController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Paid Amount"),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: dueDateController,
                      readOnly: true,
                      decoration: _inputDecoration("Due Date").copyWith(
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          initialDate: DateTime.now(),
                        );
                        if (picked != null) {
                          dueDateController.text =
                              "${picked.day}/${picked.month}/${picked.year}";
                        }
                      },
                    ),
                    const SizedBox(height: 34),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff5B5FEF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          if (selectedStudent == null) return;
                          final studentData = selectedStudent!.data()
                              as Map<String, dynamic>;
                          final total =
                              double.tryParse(amountController.text) ?? 0;
                          final paid =
                              double.tryParse(paidController.text) ?? 0;
                          final balance = total - paid;
                          String status = "Pending";
                          if (paid > 0 && paid < total) status = "Partial";
                          if (paid >= total) status = "Paid";
                          await _service.addFee(
                            schoolId: widget.schoolId,
                            data: {
                              "studentId": selectedStudent!.id,
                              "studentName": studentData['name'],
                              "classId": studentData['classId'],
                              "className": studentData['className'],
                              "feeType": feeTypeController.text.trim(),
                              "amount": total,
                              "paidAmount": paid,
                              "balanceAmount": balance,
                              "status": status,
                              "dueDate": dueDateController.text,
                            },
                          );
                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Assign Fee",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text("Fee Management"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xff5B5FEF),
        onPressed: _showAddFeeSheet,
        icon: const Icon(Icons.add),
        label: const Text("Add Fee"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getFees(widget.schoolId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return _emptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'];

              Color statusColor = const Color(0xffDCFCE7);

              if (status == "Pending") {
                statusColor = const Color(0xffFEE2E2);
              }

              if (status == "Partial") {
                statusColor = const Color(0xffFEF3C7);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['studentName'] ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                data['feeType'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            status ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _amountCard(
                            title: "Total",
                            amount: (data['amount'] ?? 0).toString(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _amountCard(
                            title: "Paid",
                            amount: (data['paidAmount'] ?? 0).toString(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _amountCard(
                            title: "Balance",
                            amount: (data['balanceAmount'] ?? 0).toString(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _amountCard({required String title, required String amount}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            "\u20b9$amount",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(title),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xffF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 90,
            width: 90,
            decoration: const BoxDecoration(
              color: Color(0xffEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 42,
              color: Color(0xff5B5FEF),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Fee Records",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xff374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Assigned fee records\nwill appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
