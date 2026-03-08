import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/school_admin/fees/services/fee_type_service.dart';
import 'package:school_app/providers/current_school_provider.dart';

final feeTypeServiceProvider = Provider.autoDispose<FeeTypeService>((ref) {
  return FeeTypeService();
});

/// Streams fee types for the current school.
///
/// Firestore structure:
/// schools/{schoolId}/feeTypes/{feeTypeId}
final feeTypesProvider = StreamProvider.autoDispose<
    QuerySnapshot<Map<String, dynamic>>>(
  (ref) {
    final schoolAsync = ref.watch(currentSchoolProvider);

    return schoolAsync.when(
      data: (schoolDoc) {
        return FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolDoc.id)
            .collection('feeTypes')
            .orderBy('nameLower')
            .snapshots();
      },
      loading: () => const Stream.empty(),
      error: (_, _) => const Stream.empty(),
    );
  },
);
