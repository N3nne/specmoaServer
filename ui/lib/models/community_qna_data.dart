class CommunityQnaPage {
  const CommunityQnaPage({
    required this.totalCount,
    required this.items,
  });

  final int totalCount;
  final List<CommunityQnaItem> items;

  factory CommunityQnaPage.fromJson(Map<String, dynamic> json) {
    return CommunityQnaPage(
      totalCount: json['totalCount'] as int? ?? 0,
      items: _list(json['items']).map(CommunityQnaItem.fromJson).toList(),
    );
  }
}

class CommunityQnaItem {
  const CommunityQnaItem({
    required this.id,
    required this.title,
    required this.body,
    required this.authorName,
    required this.certificationName,
    required this.likeCount,
    required this.answerCount,
    required this.viewCount,
    required this.acceptedAnswer,
    required this.dummy,
  });

  final String id;
  final String title;
  final String body;
  final String authorName;
  final String certificationName;
  final int likeCount;
  final int answerCount;
  final int viewCount;
  final CommunityQnaAnswer? acceptedAnswer;
  final bool dummy;

  factory CommunityQnaItem.fromJson(Map<String, dynamic> json) {
    final author = (json['author'] as Map?)?.cast<String, dynamic>() ?? {};
    final certification =
        (json['certification'] as Map?)?.cast<String, dynamic>() ?? {};

    return CommunityQnaItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      authorName: author['displayName'] as String? ?? '익명',
      certificationName: certification['name'] as String? ?? '자격증',
      likeCount: json['likeCount'] as int? ?? 0,
      answerCount: json['answerCount'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0,
      acceptedAnswer: json['acceptedAnswer'] == null
          ? null
          : CommunityQnaAnswer.fromJson(
              (json['acceptedAnswer'] as Map).cast<String, dynamic>(),
            ),
      dummy: json['dummy'] as bool? ?? false,
    );
  }
}

class CommunityQnaAnswerPage {
  const CommunityQnaAnswerPage({required this.items});

  final List<CommunityQnaAnswer> items;

  factory CommunityQnaAnswerPage.fromJson(Map<String, dynamic> json) {
    return CommunityQnaAnswerPage(
      items: _list(json['items']).map(CommunityQnaAnswer.fromJson).toList(),
    );
  }
}

class CommunityQnaAnswer {
  const CommunityQnaAnswer({
    required this.id,
    required this.body,
    required this.authorId,
    required this.authorName,
    required this.authorCertified,
    required this.likeCount,
    required this.accepted,
    required this.dummy,
  });

  final String id;
  final String body;
  final String authorId;
  final String authorName;
  final bool authorCertified;
  final int likeCount;
  final bool accepted;
  final bool dummy;

  factory CommunityQnaAnswer.fromJson(Map<String, dynamic> json) {
    final author = (json['author'] as Map?)?.cast<String, dynamic>() ?? {};

    return CommunityQnaAnswer(
      id: json['id'] as String? ?? '',
      body: json['body'] as String? ?? '',
      authorId: author['id'] as String? ?? '',
      authorName: author['displayName'] as String? ?? '익명',
      authorCertified: json['authorCertified'] as bool? ?? false,
      likeCount: json['likeCount'] as int? ?? 0,
      accepted: json['accepted'] as bool? ?? false,
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
