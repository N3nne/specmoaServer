class SuccessStoryPage {
  const SuccessStoryPage({
    required this.totalCount,
    required this.items,
  });

  final int totalCount;
  final List<SuccessStoryItem> items;

  factory SuccessStoryPage.fromJson(Map<String, dynamic> json) {
    return SuccessStoryPage(
      totalCount: json['totalCount'] as int? ?? 0,
      items: _list(json['items']).map(SuccessStoryItem.fromJson).toList(),
    );
  }
}

class SuccessStoryItem {
  const SuccessStoryItem({
    required this.id,
    required this.title,
    required this.body,
    required this.subtitle,
    required this.authorName,
    required this.certificationName,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
    required this.studyPeriodDays,
    required this.studyMethod,
    required this.score,
    required this.examAttempt,
    required this.dummy,
  });

  final String id;
  final String title;
  final String body;
  final String subtitle;
  final String authorName;
  final String certificationName;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final int studyPeriodDays;
  final String studyMethod;
  final String score;
  final String examAttempt;
  final bool dummy;

  factory SuccessStoryItem.fromJson(Map<String, dynamic> json) {
    final author = (json['author'] as Map?)?.cast<String, dynamic>() ?? {};
    final certification =
        (json['certification'] as Map?)?.cast<String, dynamic>() ?? {};

    return SuccessStoryItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      authorName: author['displayName'] as String? ?? '익명',
      certificationName: certification['name'] as String? ?? '자격증',
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0,
      studyPeriodDays: json['studyPeriodDays'] as int? ?? 21,
      studyMethod: json['studyMethod'] as String? ?? '',
      score: json['score'] as String? ?? '',
      examAttempt: json['examAttempt'] as String? ?? '초시',
      dummy: json['dummy'] as bool? ?? false,
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
