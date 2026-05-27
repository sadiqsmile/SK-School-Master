class StudentHelper {

  static Map<String, dynamic>
    _map(dynamic student) {

  if (student == null) {
    return {};
  }

  if (student
      is Map<String, dynamic>) {

    return student;
  }

  try {

    return Map<String, dynamic>
        .from(
      student.data(),
    );

  } catch (e) {

    return {};
  }
}

  static String name(
      dynamic student) {

    final data =
        _map(student);

    final value =
        data['name'];

    if (value == null) {
      return 'Student';
    }

    return value
        .toString()
        .trim();
  }

  static String initial(
      dynamic student) {

    final clean =
        name(student);

    if (clean.isEmpty) {
      return 'S';
    }

    return clean[0]
        .toUpperCase();
  }

  static String photo(
      dynamic student) {

    final data =
        _map(student);

    final value =
        data['photoUrl'];

    if (value == null) {
      return '';
    }

    return value
        .toString()
        .trim();
  }

  static bool hasPhoto(
      dynamic student) {

    final url =
        photo(student);

    return url.isNotEmpty &&
        url.startsWith(
            'http');
  }

  static String admissionNo(
      dynamic student) {

    final data =
        _map(student);

    final value =
        data['admissionNo'];

    if (value == null) {
      return '';
    }

    return value
        .toString()
        .trim();
  }
}