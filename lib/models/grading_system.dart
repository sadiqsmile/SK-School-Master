import 'package:cloud_firestore/cloud_firestore.dart';

class GradingBand {
  const GradingBand({
    required this.grade,
    required this.minPercent,
    this.remark,
  });

  final String grade;
  final double minPercent;
  final String? remark;

  Map<String, dynamic> toMap() {
    return {
      'grade': grade,
      'minPercent': minPercent,
      if (remark != null) 'remark': remark,
    };
  }

  static GradingBand? fromMap(Object? raw) {
    if (raw is! Map) return null;

    final grade = (raw['grade'] ?? '').toString().trim();
    if (grade.isEmpty) return null;

    final mpRaw = raw['minPercent'];
    double minPercent;
    if (mpRaw is num) {
      minPercent = mpRaw.toDouble();
    } else if (mpRaw is String) {
      minPercent = double.tryParse(mpRaw) ?? 0;
    } else {
      minPercent = 0;
    }

    final remark = (raw['remark'] ?? '').toString().trim();

    return GradingBand(
      grade: grade,
      minPercent: minPercent,
      remark: remark.isEmpty ? null : remark,
    );
  }
}

class GradingSystem {
  const GradingSystem({
    required this.id,
    required this.name,
    required this.bands,
    required this.passPercent,
    this.updatedAt,
  });

  final String id;
  final String name;
  final List<GradingBand> bands;

  /// Used by reports (pass/fail). Grade logic uses [bands].
  final double passPercent;

  final DateTime? updatedAt;

  static GradingSystem? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists) return null;
    final data = doc.data() ?? const <String, dynamic>{};

    final name = (data['name'] ?? 'Grading System').toString();

    final passRaw = data['passPercent'];
    final passPercent = passRaw is num
        ? passRaw.toDouble()
        : (passRaw is String ? (double.tryParse(passRaw) ?? 33.0) : 33.0);

    final bandsRaw = data['bands'];
    final bands = <GradingBand>[];
    if (bandsRaw is List) {
      for (final b in bandsRaw) {
        final parsed = GradingBand.fromMap(b);
        if (parsed != null) bands.add(parsed);
      }
    }

    DateTime? updatedAt;
    final rawUpdated = data['updatedAt'];
    if (rawUpdated is Timestamp) updatedAt = rawUpdated.toDate();

    // Ensure highest minPercent first.
    bands.sort((a, b) => b.minPercent.compareTo(a.minPercent));

    return GradingSystem(
      id: doc.id,
      name: name,
      bands: bands,
      passPercent: passPercent,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'passPercent': passPercent,
      'bands': bands.map((b) => b.toMap()).toList(growable: false),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// App-level default when the school hasn't configured one yet.
  static GradingSystem defaults() {
    return const GradingSystem(
      id: 'default',
      name: 'Default',
      passPercent: 33.0,
      bands: [
        GradingBand(grade: 'A+', minPercent: 90),
        GradingBand(grade: 'A', minPercent: 80),
        GradingBand(grade: 'B', minPercent: 70),
        GradingBand(grade: 'C', minPercent: 60),
        GradingBand(grade: 'D', minPercent: 50),
        GradingBand(grade: 'F', minPercent: 0),
      ],
    );
  }
}
