class School {
  const School({
    required this.id,
    required this.name,
    required this.schoolId,
    this.subscriptionPlan = '',
    this.themeColor = '#1565C0',
  });

  final String id;
  final String name;
  final String schoolId;
  final String subscriptionPlan;
  final String themeColor;

  factory School.fromMap(String id, Map<String, dynamic> map) {
    return School(
      id: id,
      name: (map['name'] ?? map['schoolName'] ?? 'School').toString(),
      schoolId: (map['schoolId'] ?? id).toString(),
      subscriptionPlan: (map['subscriptionPlan'] ?? '').toString(),
      themeColor: (map['themeColor'] ?? '#1565C0').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'schoolId': schoolId,
      'subscriptionPlan': subscriptionPlan,
      'themeColor': themeColor,
    };
  }
}
