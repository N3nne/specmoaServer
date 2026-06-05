class CertificationRankingItem {
  const CertificationRankingItem({
    required this.rank,
    required this.id,
    required this.name,
    required this.category,
    required this.primaryCount,
    required this.passCount,
    this.organization,
    this.passRate,
    this.metaLabel,
  });

  final int rank;
  final String id;
  final String name;
  final String category;
  final String? organization;
  final int primaryCount;
  final int passCount;
  final double? passRate;
  final String? metaLabel;

  bool get opensDetail => id.isNotEmpty;

  factory CertificationRankingItem.fromJson(Map<String, dynamic> json) {
    return CertificationRankingItem(
      rank: json['rank'] as int? ?? 0,
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      organization: json['organization'] as String?,
      primaryCount: json['primaryCount'] as int? ?? 0,
      passCount: json['passCount'] as int? ?? 0,
      passRate: _toDouble(json['passRate']),
      metaLabel: json['metaLabel'] as String?,
    );
  }
}

double? _toDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}
