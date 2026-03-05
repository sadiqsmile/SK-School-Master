import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/school_provider.dart';

class SchoolAdminDashboard extends ConsumerWidget {
	const SchoolAdminDashboard({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('School Admin Dashboard'),
			),
			body: ref.watch(schoolProvider).when(
				data: (doc) {
					final school = doc.data() as Map<String, dynamic>;

					return Center(
						child: Column(
							mainAxisAlignment: MainAxisAlignment.center,
							children: [
								Text(
									school['name'],
									style: const TextStyle(fontSize: 26),
								),
								const SizedBox(height: 10),
								Text("School ID: ${school['schoolId']}"),
								const SizedBox(height: 20),
								Text("Plan: ${school['subscriptionPlan']}"),
							],
						),
					);
				},
				loading: () => const CircularProgressIndicator(),
				error: (e, _) => Text("Error: $e"),
			),
		);
	}
}
