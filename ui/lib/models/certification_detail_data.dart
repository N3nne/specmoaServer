class CertificationDetailData {
  const CertificationDetailData({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.schedules,
    this.eligibility,
    this.examSubjects,
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final List<CertificationScheduleData> schedules;
  final String? eligibility;
  final String? examSubjects;

  factory CertificationDetailData.fromJson(Map<String, dynamic> json) {
    return CertificationDetailData(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      schedules: _list(json['schedules'])
          .map(CertificationScheduleData.fromJson)
          .toList(),
      eligibility: json['eligibility'] as String?,
      examSubjects: json['examSubjects'] as String?,
    );
  }
}

class CertificationScheduleData {
  const CertificationScheduleData({
    required this.id,
    required this.type,
    required this.title,
    required this.startsOn,
    this.endsOn,
    this.source,
  });

  final String id;
  final String type;
  final String title;
  final String startsOn;
  final String? endsOn;
  final String? source;

  factory CertificationScheduleData.fromJson(Map<String, dynamic> json) {
    return CertificationScheduleData(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'custom',
      title: json['title'] as String? ?? '',
      startsOn: json['startsOn'] as String? ?? '',
      endsOn: json['endsOn'] as String?,
      source: json['source'] as String?,
    );
  }

  DateTime? get startDate => _parseDate(startsOn);
  DateTime? get endDate => _parseDate(endsOn);
}

List<Map<String, dynamic>> _list(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList();
}

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}
