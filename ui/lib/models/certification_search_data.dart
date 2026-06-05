class CertificationSearchTag {
  const CertificationSearchTag({
    required this.id,
    required this.name,
    required this.type,
    required this.certificationCount,
  });

  final String id;
  final String name;
  final String type;
  final int certificationCount;

  factory CertificationSearchTag.fromJson(Map<String, dynamic> json) {
    return CertificationSearchTag(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      certificationCount: json['certificationCount'] as int? ?? 0,
    );
  }
}

class CertificationSearchResult {
  const CertificationSearchResult({
    required this.id,
    required this.name,
    required this.category,
    required this.examineeCount,
    required this.acquiredCount,
    required this.tags,
    this.organization,
  });

  final String id;
  final String name;
  final String category;
  final String? organization;
  final int examineeCount;
  final int acquiredCount;
  final List<CertificationSearchTag> tags;

  factory CertificationSearchResult.fromJson(Map<String, dynamic> json) {
    return CertificationSearchResult(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      organization: json['organization'] as String?,
      examineeCount: json['examineeCount'] as int? ?? 0,
      acquiredCount: json['acquiredCount'] as int? ?? 0,
      tags: _list(json['tags']).map(CertificationSearchTag.fromJson).toList(),
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
