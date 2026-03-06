import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_app/providers/current_school_provider.dart';

import '../services/class_service.dart';

class AddClassScreen extends ConsumerStatefulWidget {
  const AddClassScreen({super.key});

  @override
  ConsumerState<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends ConsumerState<AddClassScreen> {
  final Map<String, List<String>> sectionClasses = {
    "Primary Section": ["LKG", "UKG", "1", "2", "3", "4", "5"],
    "Middle School": ["6", "7", "8"],
    "High School": ["9", "10"],
  };

  String selectedSection = "Primary Section";
  String selectedClass = "LKG";

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final classes = sectionClasses[selectedSection]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Class"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedSection,
              items: sectionClasses.keys.map((section) {
                return DropdownMenuItem(
                  value: section,
                  child: Text(section),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedSection = value;
                  selectedClass = sectionClasses[value]!.first;
                });
              },
              decoration: const InputDecoration(
                labelText: "Select Section",
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedClass,
              items: classes.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text("Class $c"),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedClass = value;
                });
              },
              decoration: const InputDecoration(
                labelText: "Select Class",
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      try {
                        final school = await ref.read(
                          currentSchoolProvider.future,
                        );
                        final schoolId = school.id;

                        final service = ClassService();
                        await service.createClass(
                          schoolId: schoolId,
                          className: selectedClass,
                          sectionType: selectedSection,
                        );

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Class created!')),
                        );

                        Navigator.pop(context);
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to create class: $e')),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => _isSaving = false);
                        }
                      }
                    },
              child: const Text("Create Class"),
            ),
          ],
        ),
      ),
    );
  }
}
