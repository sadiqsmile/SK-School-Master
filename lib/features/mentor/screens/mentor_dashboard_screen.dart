import 'package:flutter/material.dart';

class MentorDashboardScreen extends StatelessWidget {
  const MentorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mentor Dashboard"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          _menuCard(
            context,
            "Students",
            Icons.groups,
          ),

          _menuCard(
            context,
            "Teachers",
            Icons.school,
          ),

          _menuCard(
            context,
            "Attendance",
            Icons.fact_check,
          ),

          _menuCard(
            context,
            "Exam Marks",
            Icons.assignment,
          ),

          _menuCard(
            context,
            "Fees",
            Icons.payments,
          ),

          _menuCard(
            context,
            "Messages",
            Icons.message,
          ),
        ],
      ),
    );
  }

  Widget _menuCard(BuildContext context, String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {},
      ),
    );
  }
}