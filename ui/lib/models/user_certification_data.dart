class UserCertificationPage {
  const UserCertificationPage({
    required this.totalCount,
    required this.items,
  });

  final int totalCount;
  final List<UserCertificationItem> items;

  factory UserCertificationPage.fromJson(Map<String, dynamic> json) {
    return UserCertificationPage(
      totalCount: json['totalCount'] as int? ?? 0,
      items: _list(json['items']).map(UserCertificationItem.fromJson).toList(),
    );
  }
}

class UserCertificationItem {
  const UserCertificationItem({
    required this.id,
    required this.status,
    required this.progress,
    required this.targetExamDate,
    required this.certifiedOn,
    required this.certificateNumber,
    required this.preparationCategory,
    required this.notes,
    required this.certification,
  });

  final String id;
  final String status;
  final int progress;
  final String? targetExamDate;
  final String? certifiedOn;
  final String? certificateNumber;
  final String? preparationCategory;
  final String? notes;
  final UserCertificationSummary certification;

  bool get certified => status == 'certified';

  factory UserCertificationItem.fromJson(Map<String, dynamic> json) {
    return UserCertificationItem(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'planned',
      progress: json['progress'] as int? ?? 0,
      targetExamDate: json['targetExamDate'] as String?,
      certifiedOn: json['certifiedOn'] as String?,
      certificateNumber: json['certificateNumber'] as String?,
      preparationCategory: json['preparationCategory'] as String?,
      notes: json['notes'] as String?,
      certification: UserCertificationSummary.fromJson(
        (json['certification'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
    );
  }
}

class UserCertificationSummary {
  const UserCertificationSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.organization,
  });

  final String id;
  final String name;
  final String category;
  final String organization;

  factory UserCertificationSummary.fromJson(Map<String, dynamic> json) {
    return UserCertificationSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      organization: json['organization'] as String? ?? '',
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
