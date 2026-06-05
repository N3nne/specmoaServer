class StudySessionSummary {
  const StudySessionSummary({
    required this.todaySeconds,
    required this.totalSeconds,
    required this.recent,
  });

  final int todaySeconds;
  final int totalSeconds;
  final List<StudySessionRecord> recent;

  factory StudySessionSummary.fromJson(Map<String, dynamic> json) {
    return StudySessionSummary(
      todaySeconds: json['todaySeconds'] as int? ?? 0,
      totalSeconds: json['totalSeconds'] as int? ?? 0,
      recent: _list(json['recent']).map(StudySessionRecord.fromJson).toList(),
    );
  }
}

class StudySessionRecord {
  const StudySessionRecord({
    required this.id,
    required this.startedAt,
    required this.durationSeconds,
    this.endedAt,
    this.note,
    this.certification,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final String? note;
  final StudySessionCertification? certification;

  factory StudySessionRecord.fromJson(Map<String, dynamic> json) {
    final certification =
        (json['certification'] as Map?)?.cast<String, dynamic>();

    return StudySessionRecord(
      id: json['id'] as String? ?? '',
      startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? '') ??
          DateTime.now(),
      endedAt: DateTime.tryParse(json['endedAt']?.toString() ?? ''),
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      note: json['note'] as String?,
      certification: certification == null
          ? null
          : StudySessionCertification.fromJson(certification),
    );
  }
}

class StudySessionCertification {
  const StudySessionCertification({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory StudySessionCertification.fromJson(Map<String, dynamic> json) {
    return StudySessionCertification(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '자격증',
    );
  }
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
